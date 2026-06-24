obs = obslua

local game_scene_name = ""
local idle_scene_name = ""
local poll_interval_sec = 5
local game_running = false

local PROCESS_NAME = "VALORANT-Win64-Shipping.exe"

local function is_valorant_running()
	local handle = io.popen('tasklist /FI "IMAGENAME eq ' .. PROCESS_NAME .. '"')
	if not handle then
		return false
	end
	local result = handle:read("*a")
	handle:close()
	return result ~= nil and result:find(PROCESS_NAME, 1, true) ~= nil
end

local function switch_to_scene(scene_name)
	if scene_name == "" then
		return
	end
	local source = obs.obs_get_source_by_name(scene_name)
	if source then
		obs.obs_frontend_set_current_scene(source)
		obs.obs_source_release(source)
	end
end

local function poll_valorant()
	local running = is_valorant_running()

	if running and not game_running then
		switch_to_scene(game_scene_name)
	elseif not running and game_running then
		switch_to_scene(idle_scene_name)
	end

	game_running = running
end

local function add_scene_names(prop)
	local scenes = obs.obs_frontend_get_scene_names()
	for _, name in ipairs(scenes) do
		obs.obs_property_list_add_string(prop, name, name)
	end
end

function script_description()
	return "Schaltet automatisch in eine Szene, sobald Valorant gestartet wird, " ..
		"und zurueck in eine andere Szene, sobald Valorant beendet wird."
end

function script_properties()
	local props = obs.obs_properties_create()

	local game_scene_prop = obs.obs_properties_add_list(
		props, "game_scene", "Szene wenn Valorant laeuft",
		obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	add_scene_names(game_scene_prop)

	local idle_scene_prop = obs.obs_properties_add_list(
		props, "idle_scene", "Szene wenn Valorant nicht laeuft",
		obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	add_scene_names(idle_scene_prop)

	obs.obs_properties_add_int_slider(
		props, "poll_interval", "Pruefintervall (Sekunden)", 1, 60, 1)

	return props
end

function script_update(settings)
	game_scene_name = obs.obs_data_get_string(settings, "game_scene")
	idle_scene_name = obs.obs_data_get_string(settings, "idle_scene")
	poll_interval_sec = obs.obs_data_get_int(settings, "poll_interval")
	if poll_interval_sec < 1 then
		poll_interval_sec = 5
	end

	obs.timer_remove(poll_valorant)
	obs.timer_add(poll_valorant, poll_interval_sec * 1000)
end

function script_load(settings)
	game_running = is_valorant_running()
end

function script_unload()
	obs.timer_remove(poll_valorant)
end
