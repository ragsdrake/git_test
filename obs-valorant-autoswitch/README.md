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

## Funktionsweise

- Alle X Sekunden wird per `tasklist` geprueft, ob `VALORANT-Win64-Shipping.exe` laeuft.
- Startet das Spiel und die aktuelle Szene ist nicht bereits die Game-Szene, wird automatisch gewechselt.
- Beendet sich das Spiel, wird automatisch zurueck in die Idle-Szene gewechselt.
- Manuelle Szenenwechsel waehrend des Spiels werden nicht ueberschrieben, solange Valorant laeuft.

## Hinweise

- Nur unter Windows nutzbar.
- Vanguard (Valorants Anti-Cheat) kann den Start von OBS beeinflussen, falls
  OBS vor Vanguard gestartet wird; das Skript selbst nutzt nur `tasklist`
  (Standard-Windows-Tool) und greift nicht in den Spielprozess ein.
