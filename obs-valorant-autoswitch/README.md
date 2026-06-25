# OBS Valorant Auto Scene Switcher

Lua-Skript fuer OBS Studio, das automatisch die Szene wechselt, sobald Valorant
gestartet bzw. beendet wird. Erkennung erfolgt ueber den Windows-Prozessnamen
`VALORANT-Win64-Shipping.exe` (laeuft nur unter Windows, da Valorant kein
Linux/macOS unterstuetzt).

## Installation

1. OBS Studio oeffnen.
2. **Tools > Skripte** (Tools > Scripts).
3. Auf das **+** klicken und `valorant_scene_switcher.lua` auswaehlen.
4. Im Skript-Panel rechts:
   - **Szene wenn Valorant laeuft**: die Szene, in die beim Spielstart gewechselt werden soll.
   - **Szene wenn Valorant nicht laeuft**: die Szene, in die nach Spielende gewechselt werden soll.
   - **Pruefintervall (Sekunden)**: wie oft der Prozess geprueft wird (Standard 5s).

## Funktionsweise (Code-Erklaerung)

Das Skript nutzt die in OBS eingebaute Lua-API `obslua` und besteht aus
mehreren Funktionen, die OBS an bestimmten Punkten automatisch aufruft.

### 1. Prozesserkennung: `is_valorant_running()`

```lua
local function is_valorant_running()
	local handle = io.popen('tasklist /FI "IMAGENAME eq ' .. PROCESS_NAME .. '"')
	...
	return result ~= nil and result:find(PROCESS_NAME, 1, true) ~= nil
end
```

- `io.popen(...)` fuehrt den Windows-Befehl `tasklist` aus und filtert
  (`/FI "IMAGENAME eq ..."`) direkt nach dem Prozessnamen
  `VALORANT-Win64-Shipping.exe`. Das spart Parsing-Aufwand, weil `tasklist`
  selbst nur passende Zeilen zurueckgibt.
- `handle:read("*a")` liest die komplette Ausgabe des Befehls als String.
- Laeuft der Prozess, taucht der Name in der Ausgabe auf; laeuft er nicht,
  gibt `tasklist` stattdessen eine "Es wurde kein Task gefunden"-Meldung
  zurueck, die den Namen nicht enthaelt. `result:find(...)` prueft das.
- `handle:close()` schliesst den Prozess-Handle wieder, damit kein
  Datei-/Prozess-Handle offen bleibt.

### 2. Szenenwechsel: `switch_to_scene(scene_name)`

```lua
local source = obs.obs_get_source_by_name(scene_name)
obs.obs_frontend_set_current_scene(source)
obs.obs_source_release(source)
```

- OBS verwaltet Szenen intern als "Sources". `obs_get_source_by_name` holt
  eine Referenz auf die Szene mit dem konfigurierten Namen.
- `obs_frontend_set_current_scene` macht diese Szene zur aktiven OBS-Szene
  (entspricht einem manuellen Klick auf die Szene im Szenen-Panel).
- `obs_source_release` gibt die Referenz wieder frei. OBS-Lua-Objekte sind
  Referenz-gezaehlt; ohne `release` wuerde die Referenz "haengen bleiben"
  und nie wirklich freigegeben werden (Memory-Leak innerhalb der OBS-Session).

### 3. Polling-Logik: `poll_valorant()`

```lua
local function poll_valorant()
	local running = is_valorant_running()
	if running and not game_running then
		switch_to_scene(game_scene_name)
	elseif not running and game_running then
		switch_to_scene(idle_scene_name)
	end
	game_running = running
end
```

Das ist die zentrale Zustandsmaschine:

- `game_running` speichert den zuletzt bekannten Zustand (laeuft Valorant
  oder nicht).
- Es wird nur beim **Uebergang** umgeschaltet (`running` und `not game_running`
  bzw. umgekehrt), nicht bei jedem Poll. Dadurch wechselt das Skript die
  Szene nur genau einmal beim Start und einmal beim Beenden von Valorant –
  manuelle Szenenwechsel waehrend des Spiels (z.B. zu einer BRB-Szene)
  werden also nicht durch den naechsten Poll wieder ueberschrieben.

Diese Funktion wird per `obs.timer_add(poll_valorant, poll_interval_sec * 1000)`
alle X Sekunden von OBS selbst aufgerufen (OBS-eigener Timer-Mechanismus,
laeuft im OBS-Hauptthread).

### 4. UI: `script_properties()`

```lua
local game_scene_prop = obs.obs_properties_add_list(
	props, "game_scene", "Szene wenn Valorant laeuft",
	obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
add_scene_names(game_scene_prop)
```

- Baut die Eingabefelder, die im Skript-Panel von OBS angezeigt werden
  (Dropdown fuer Game-Szene, Dropdown fuer Idle-Szene, Slider fuer das
  Pruefintervall).
- `add_scene_names()` fuellt die Dropdowns dynamisch mit allen aktuell
  existierenden Szenennamen (`obs.obs_frontend_get_scene_names()`), damit
  man nichts manuell eintippen muss.

### 5. Lebenszyklus-Hooks

OBS ruft bei einem geladenen Skript automatisch bestimmte Funktionsnamen auf,
wenn sie existieren:

| Funktion | Wird aufgerufen, wenn ... |
|---|---|
| `script_description()` | OBS den Beschreibungstext im Skript-Panel anzeigen will |
| `script_properties()` | OBS die Einstellungs-UI aufbaut |
| `script_update(settings)` | Einstellungen geaendert/gespeichert werden (auch direkt nach dem Laden) |
| `script_load(settings)` | das Skript geladen wird |
| `script_unload()` | das Skript entladen/OBS geschlossen wird |

`script_update` liest die aktuellen Einstellungen aus `settings`
(`obs_data_get_string` / `obs_data_get_int`) in die lokalen Variablen und
setzt den Timer neu (`timer_remove` + `timer_add`), damit ein geaendertes
Pruefintervall sofort greift. `script_load` ermittelt einmalig den
Ausgangszustand, damit beim allerersten Poll kein unnoetiger Szenenwechsel
ausgeloest wird, falls Valorant beim OBS-Start bereits laeuft.
`script_unload` raeumt den Timer auf, damit nach Entladen des Skripts kein
toter Callback mehr existiert.

## Voraussetzungen

- Windows (Valorant/Vanguard unterstuetzen kein Linux/macOS).
- OBS Studio mit aktivierter Lua-Skripting-Unterstuetzung (Standard seit OBS 21+).
- Die Ziel-Szenen muessen bereits in OBS existieren, bevor sie in den
  Dropdowns ausgewaehlt werden koennen.

## Troubleshooting

- **Dropdowns sind leer**: Skript-Panel schliessen und neu oeffnen, nachdem
  Szenen angelegt wurden – die Liste wird beim Erstellen der UI einmalig befuellt.
- **Kein Szenenwechsel**: pruefen, ob der Prozessname exakt
  `VALORANT-Win64-Shipping.exe` lautet (z.B. im Task-Manager), falls Riot den
  Namen in einer zukuenftigen Version aendert.
- **Vanguard/Anti-Cheat**: das Skript greift nicht in den Spielprozess ein,
  sondern liest nur die oeffentliche Prozessliste via `tasklist` – das ist
  das gleiche, was z.B. der Task-Manager macht.
