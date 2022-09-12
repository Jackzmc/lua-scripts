-- Jackz Vehicle Builder
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "jackz_vehicle_builder"
VERSION = "1.23.0"
local LANG_TARGET_VERSION = "1.3.3" -- Target version of translations.lua lib
local VEHICLELIB_TARGET_VERSION = "1.3.1"

--#P:DEBUG_ONLY
require('templates/log')
require('templates/common')
--#P:END

--#P:TEMPLATE("log")
--#P:TEMPLATE("_SOURCE")
--#P:TEMPLATE("common")

util.require_natives(1660775568)
if SCRIPT_META_LIST then
    menu.divider(SCRIPT_META_LIST, "-- Credits --")
    menu.divider(SCRIPT_META_LIST, "hexarobi - Testing, Suggestions & Fixees")
end

local json = try_require("json")
local vehiclelib = try_require("jackzvehiclelib")
if vehiclelib == true then
    if SCRIPT_SOURCE == "REPO" then
        util.toast("Fatal error: Lib 'jackzvehiclelib' file is corrupted. Please report this issue.\n(REPO - V" .. VERSION .. ")")
    else
        util.toast("Fatal error: Lib 'jackzvehiclelib' file is corrupted. Please reinstall library and report this issue (MANUAL - V" .. VERSION .. ")")
    end
    util.stop_script()
end

if vehiclelib.LIB_VERSION ~= VEHICLELIB_TARGET_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
        Log.log("jackzvehiclelib current: " .. vehiclelib.LIB_VERSION, ", target version: " .. VEHICLELIB_TARGET_VERSION)
        util.toast("Outdated vehiclelib library, downloading update...")
        download_lib_update("jackzvehiclelib.lua")
        vehiclelib = require("jackzvehiclelib")
        
    else
        util.toast("Outdated lib: 'jackzvehiclelib'")
    end
end


-- [ Begin actual script ]--
-- Autosave state
local AUTOSAVE_INTERVAL_SEC = 60 * 3
local MAX_AUTOSAVES = 5 
local autosaveNextTime = 0
local autosaveIndex = 1

local BUILDER_VERSION = "1.6.0" -- For version diff warnings
local FORMAT_VERSION = "Jackz Builder " .. BUILDER_VERSION
local builder = nil
local editorActive = false
local scriptEnding = false
local pedAnimCache = {} -- Used to reset spawned peds with animdata
local pedAnimThread
local hud_coords = { x = memory.alloc(8), y = memory.alloc(8), z = memory.alloc(8) }

-- Returns a new builder instance
function new_builder()
    autosaveNextTime = os.seconds() + AUTOSAVE_INTERVAL_SEC
    
    return { -- All data needed for builder
        _index = 1, -- Starting entity index
        name = nil,
        author = nil,
        base = {
            handle = nil,
            data = nil
        },
        entities = {}, -- KV<Handle, Table>
        entitiesMenuList = nil,
        propSpawner = {
            root = nil,
            menus = {},
            loadState = 0, --0: not, 1: loading, 2: done
            recents = {
                list = nil,
                items = {}
            },
            favorites = {
                list = nil
            }
        },
        vehSpawner = {
            root = nil,
            menus = {},
            loadState = 0, --0: not, 1: loading, 2: done
            recents = {
                list = nil,
                items = {}
            },
            favorites = {
                list = nil
            }
        },
        pedSpawner = {
            root = nil,
            menus = {},
            loadState = 0,
            recents = {
                list = nil,
                items = {}
            },
            favorites = {
                list = nil
            }
        },
        particlesSpawner = {
            root = nil,
            menus = {},
            loadState = 0,
            recents = {
                list = nil,
                items = {}
            },
            favorites = {
                list = nil
            }
        },
        ent_spawner_active = false,
        blip_icon = 225, -- Saved as blipIcon
        spawnLocation = nil,
        spawnInBase = false
    }
end
function create_blip_for_entity(entity, type, name)
    local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
    if type then
       HUD.SET_BLIP_SPRITE(blip, type)
    end
    if name then
        HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
        HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
    end
    return blip
end
local scriptSettings = {
    spawnInVehicle = true,
    autosaveEnabled = true,
    showOverlay = true,
    showAddOverlay = true
}
local preview = { -- Handles preview tracking and clearing
    entity = 0,
    id = nil,
    thread = nil,
    range = -1,
    rangeZ = 0.3,
    rendercb = nil, -- Function to render a text preview 
    renderdata = nil
}
local highlightedHandle = nil -- Will highlight the handle with this ID
local setupMenus = {}

local POS_SENSITIVITY = 10
local ROT_SENSITIVITY = 5
local FREE_EDIT = false
local isInEntityMenu = false

local CURATED_PROPS = {
    "prop_barriercrash_04",
    "prop_barier_conc_01a",
    "prop_barier_conc_01b",
    "prop_barier_conc_03a",
    "prop_barier_conc_02c",
    "prop_mc_conc_barrier_01",
    "prop_barier_conc_05b",
    "prop_metal_plates01",
    "prop_metal_plates02",
    "prop_woodpile_01a",
    "prop_weed_pallet",
    "prop_cs_dildo_01",
    "prop_water_ramp_03",
    "prop_water_ramp_02",
    "prop_mp_ramp_02",
    "prop_mp_ramp_01_tu",
    "prop_roadcone02a",
    "prop_beer_neon_01",
    "prop_sign_road_03b",
    "prop_prlg_snowpile",
    "prop_logpile_06b",
    "prop_windmill_01",
    "prop_cactus_01e",
    "prop_minigun_01",
    "v_ilev_gold",
    "bkr_prop_bkr_cashpile_07",
    "ex_cash_pile_07",
    "prop_cs_dildo_01",
    "prop_ld_bomb_01"
}
local CURATED_VEHICLES = {
    { "t20", "T20" },
    { "vigilante", "Vigilante" },
    { "oppressor", "Oppressor" },
    { "frogger", "Frogger" },
    { "airbus", "Airport Bus" },
    { "pbus2", "Festival Bus" },
    { "hydra", "Hydra" },
    { "blimp", "Blimp" },
    { "rhino", "Rhino Tank" },
    { "cerberus2", "Future Shock Cerberus" },
    { "mule", "Mule"},
    { "bmx", "BMX" },
    { "ambulance", "Ambulance" },
    { "police3", "Police Crusier 3"},
    { "predator", "Police Boat" },
    { "polmav", "Police Maverick Helicopter" },
    { "bati", "Bati"},
    { "airtug", "Airtug" },
    { "armytrailer", "Army Trailer (Flatbed)"},
    { "armytanker", "Army Tanker" },
    { "freightcont2", "Train Freight Car"}
}

local CURATED_PEDS = {
    { "player_one", "Franklin" },
    { "player_two", "Trevor" },
    { "player_zero", "Michael" },
    { "hc_driver" },
    { "hc_gunman" },
    { "hc_hacker" },
    { "ig_agent" },
    { "ig_amanda_townley", "Amanda" },
    { "ig_andreas" },
    { "ig_ashley" },
    { "ig_avon", "Avon" },
    { "ig_brad", "Brad" },
    { "ig_chef", "Chef" },
    { "ig_devin", "Devin" },
    { "ig_tomcasino", "Tom" },
    { "ig_agatha", "Agtha" },
    { "s_f_y_cop_01", "Female Cop" },
    { "s_m_m_fibsec_01", "Fib Agent (M)"},
    { "s_m_m_movspace_01", "Spacesuit Ped"},
    { "s_m_m_scientist_01", "Scientist" },
    { "s_m_y_clown_01", "Clown" },
    { "ig_nervousron", "Nervous Ron" },
    { "ig_wade", "Wade" },
    { "u_f_y_corpse_01", "Corpse" },
    { "u_m_m_jesus_01", "Jesus" },
    { "u_m_m_streetart_01", "Monkey Mask" },
    { "u_m_y_rsranger_01", "Space Ranger" },
    { "a_c_deer", "Deer" },
    { "s_m_y_prisoner_01", "Prisoner" },
    { "s_m_y_sheriff_01", "Sherrif" },
    { "s_m_y_fireman_01", "Fireman" }
}

-- https://vespura.com/fivem/particle-list/
local CURATED_PARTICLE_FX = {
    { "scr_indep_fireworks", "scr_indep_firework_shotburst"},
    { "core", "fire_wrecked_plane_cockpit" },
    { "wpn_flare", "proj_heist_flare_trail" },
    { "weap_xs_vehicle_weapons", "muz_xs_turret_flamethrower_looping"},
    { "weap_xs_vehicle_weapons", "muz_xs_turret_flamethrower_looping_sf"},
    { "weap_sm_tula", "veh_tula_turbulance_water" },
    { "veh_khanjali", "muz_xm_khanjali_railgun_charge" },
    { "scr_xs_props", "scr_xs_oil_jack_fire" },
    { "scr_xs_pits", "scr_xs_sf_pit" },
    { "scr_xs_pits", "scr_xs_fire_pit" },
    { "scr_xs_pits", "scr_xs_sf_pit_long" },
    { "scr_xs_pits", "scr_xs_fire_pit_long" },
    { "xcr_xs_celebration", "scr_xs_money_rain" },
    { "xcr_xs_celebration", "scr_xs_money_rain_celeb" },
    { "xcr_xs_celebration", "scr_xs_champagne_spray" },
    { "xcr_xm_submarine", "scr_xm_stromberg_scanner" },
    { "xcr_xm_spybomb", "scr_xm_spybomb_plane_smoke_trail" },
    { "scr_xm_ht", "scr_xm_ht_package_flare" },
    { "scr_xm_farm", "scr_xm_dst_elec_cracke" },
    { "scr_xm_heat", "scr_xm_heat_camo" },
    { "scr_xm_aq", "scr_xm_aq_final_kill_thruster" },
    { "scr_sr_adversary", "scr_sr_lg_weapon_highlight" },
    { "scr_recrash_rescue", "scr_recrash_rescue" },
    { "scr_reconstructionaccident", "scr_sparking_generator" },
    { "scr_rcnigel2", "scr_rcn2_debris_trail" },
    { "scr_rcbarry1", "scr_alien_charging" },
    { "scr_rcbarry1", "scr_alien_impact" },
    { "scr_jewelheist", "scr_jewel_fog_volume" },
    { "scr_carwash", "ent_amb_car_wash_jet" },
    { "scr_as_trans", "scr_as_trans_smoke" },
    { "cut_amb_tv", "cs_amb_tv_sauna_steam" },
    { "scr_trevor2", "scr_trev2_heli_wreck" },
    { "scr_stunts", "scr_stunts_fire_ring" }
}

local BLIP_ICONS = {
    { 64, "Helicopter (Black)" },
    { 56, "Police Car" },
    { 58, "Star" },
    { 67, "Van" },
    { 85, "Truck" },
    { 90, "Plane (Black)" },
    { 198, "Taxi "},
    { 225, "Car" },
    { 318, "Garbage" },
    { 404, "Dinghy" },
    { 410, "Boat", },
    { 421, "Tank" },
    { 422, "Helicopter (White)"},
    { 423, "Plane (White)"},
    { 424, "Jet" },
    { 426, "Gun Vehicle"},
    { 427, "Player Boat"},
    { 455, "Yacht" },
    { 477, "Truck" },
    { 481, "Cargobob" },
    { 479, "Trailer" },
    { 512, "Quad"},
    { 513, "Bus"},
    { 522, "Deadline Bike"},
    { 531, "Racecar"},
    { 523, "Sports Car"},
    { 533, "Industrial Vehicle"},
    { 533, "Rocket Voltic"},
    { 534, "Space Docker"},
    { 401, "Blimp" },
    { 824, "Champion" },
    { 818, "Patriot" },
    { 820, "Jubilee"},
    { 821, "Granger"},
    { 799, "Slamvan"},
    { 750, "Military Truck"},
    { 735, "Buggy" },
    { 724, "Limo" },
    { 748, "Gokart" }

}

local FAVORITES = {
    objects = {},
    vehicles = {},
    peds = {},
    particles = {}
}
local FAVORITES_PATH = filesystem.store_dir() .. "jackz_vehicle_builder\\favorites.json"

function save_favorites_list()
    local file = io.open(FAVORITES_PATH, "w")
    if file then
        file:write(json.encode(FAVORITES))
        file:flush()
        file:close()
    end
end

function load_favorites_list()
    local file = io.open(FAVORITES_PATH, "r")
    if file then
        local status, data = pcall(json.decode, file:read("*a"))
        if status then
            FAVORITES = data
        else
            Log.error("Corrupted favorites list: " .. data)
            util.toast(SCRIPT_NAME .. ": Favorites list is corrupted or invalid, see logs for details")
        end
        file:close()
    end
end

load_favorites_list()

function join_path(parent, child)
    local sub = parent:sub(-1)
    if sub == "/" or sub == "\\" then
        return parent .. child
    else
        return parent .. "/" .. child
    end
end
local PROPS_PATH = join_path(filesystem.resources_dir(), "objects.txt")
local PEDS_PATH = join_path(filesystem.resources_dir(), "peds.txt")
local VEHICLES_PATH = join_path(filesystem.resources_dir(), "vehicles.txt")
local PARTICLES_PATH = join_path(filesystem.resources_dir(), "particles.txt")

local SAVE_DIRECTORY = join_path(filesystem.stand_dir(), "Builds")
local LEGACY_SAVE_DIRECTORY = join_path(filesystem.stand_dir(), "Vehicles/Custom")
local AUTOSAVE_DIRECTORY = join_path(SAVE_DIRECTORY, "autosaves")
local DOWNLOADS_DIRECTORY = join_path(SAVE_DIRECTORY, "downloads")
if not filesystem.exists(PROPS_PATH) then
    if SCRIPT_SOURCE == "MANUAL" then
        util.log(SCRIPT_NAME .. ": Downloading missing resource objects.txt")
        download_resources_update("objects.txt")
    else
        util.toast(SCRIPT_NAME .. ": objects.txt in resources folder does not exist. Please properly install this script.", TOAST_ALL)
        util.log("Resources directory: ".. PROPS_PATH)
        util.stop_script()
    end
end
if not filesystem.exists(PEDS_PATH) then
    util.log(SCRIPT_NAME .. ": Downloading resource update for peds.txt")
    download_resources_update("peds.txt")
end
if not filesystem.exists(VEHICLES_PATH) then
    util.log(SCRIPT_NAME .. ": Downloading resource update for vehicles.txt")
    download_resources_update("vehicles.txt")
end
if not filesystem.exists(SAVE_DIRECTORY) then
    filesystem.mkdir(SAVE_DIRECTORY)
end
if not filesystem.exists(AUTOSAVE_DIRECTORY) then
    filesystem.mkdir(AUTOSAVE_DIRECTORY)
end


function move_folder_recursive(dir, dest)
    for _, path in filesystem.list_files(dir) do
        local _, filename = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if filesystem.is_dir(path) then
            filesystem.mkdir(dest .. "/" .. filename)
            move_folder_recursive(path, dest .. "/" .. filename)
        else
            Log.debug(path, "-->", dest .. "/" .. filename)
            os.rename(path, dest .. "/" .. filename)
        end
    end
end
if filesystem.exists(LEGACY_SAVE_DIRECTORY) then
    Log.log("Found old save directory, migrating files")
    move_folder_recursive(LEGACY_SAVE_DIRECTORY, SAVE_DIRECTORY)
    util.toast(SCRIPT_NAME .. ": Your builds have moved from Stand\\Vehicles\\Custom to %appdata%\\Stand\\Builds", TOAST_ALL)
    local tmpDir = os.tmpname()
    Log.log("Moved legacy fodler to temp dir:", tmpDir)
    os.rename(LEGACY_SAVE_DIRECTORY, tmpDir)
end

function create_preview_handler_if_not_exists()
    if preview.thread == nil then
        preview.thread = util.create_thread(function()
            local heading = 0
            while preview.entity ~= 0 and not preview.isParticle do
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                heading = heading + 2
                if heading == 360 then
                    heading = 0
                end
                pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, preview.range or 7.5, preview.rangeZ or 0.3)
                ENTITY.SET_ENTITY_COORDS(preview.entity, pos.x, pos.y, pos.z, true, true, false, false)
                ENTITY.SET_ENTITY_HEADING(preview.entity, heading)

                if scriptSettings.showOverlay and preview.rendercb then
                    preview.rendercb(pos, preview.renderdata)
                end

                util.yield(12)
            end
            preview.thread = nil
        end)
    end
end
function clear_menu_table(t)
    for k, h in pairs(t) do
        pcall(menu.delete, h)
        t[k] = nil
    end
end
function clear_menu_array(t)
    for _, h in ipairs(t) do
        pcall(menu.delete, h)
    end
    t = {}
end
function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
       table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end
--[[
    UTILS
]]--
local utilsMenu = menu.list(menu.my_root(), "Utilities", {"jvbutils"}, "Some utilities such as clearing entities")
menu.action(utilsMenu, "Delete Preview", {"jvbstoppreview"}, "Removes currently active preview.", function()
    if preview.entity == 0 then
        util.toast("No preview is active")
    end
    clear_build_preview()
end)
menu.click_slider(utilsMenu, "Clear Nearby Vehicles", {"clearnearbyvehs"}, "Clears all nearby vehicles within defined range", 500, 100000, 500, 6000, function(range)
    local vehicles = entities.get_all_vehicles_as_handles()
    local count = _clear_ents(vehicles, range)
    util.toast("Deleted " .. count .. " vehicles")
end)
menu.click_slider(utilsMenu, "Clear Nearby Objects", {"clearnearbyobjs"}, "Clears all nearby objects within defined range", 500, 100000, 500, 6000, function(range)
    local vehicles = entities.get_all_objects_as_handles()
    local count = _clear_ents(vehicles, range)
    util.toast("Deleted " .. count .. " objects")
end)

menu.click_slider(utilsMenu, "Clear Nearby Peds", {"clearnearbypeds"}, "Clears all nearby peds within defined range", 500, 100000, 500, 6000, function(range)
    local vehicles = entities.get_all_peds_as_handles()
    local count = _clear_ents(vehicles, range)
    util.toast("Deleted " .. count .. " peds")
end)

function _clear_ents(list, range, dryRun)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local count = 0
    for _, entity in ipairs(list) do
        local pos2 = ENTITY.GET_ENTITY_COORDS(entity, 1)
        local dist = SYSTEM.VDIST(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
        if dist <= range then
            util.draw_debug_text(string.format("deleted entity %d - %f m away", entity, dist))
            if not dryRun then
                entities.delete_by_handle(entity)
            end
            count = count + 1
        end
    end
    return count
end
--[[
    SETTINGS
]]--

local settingsList = menu.list(menu.my_root(), "Settings", {"jvbcfg"}, "Change settings of script")
menu.toggle(settingsList, "Debug Mode", {"jvbdebug"}, "Enables debugs log to help with issues", function(value)
    SCRIPT_DEBUG = value
end, SCRIPT_DEBUG)
menu.toggle(settingsList, "Autosave Active", {"jvbautosave"}, "Autosaves happen every 4 minutes, disable to turn off autosaving\nExisting autosaves will not be deleted.", function(value)
    scriptSettings.autosaveEnabled = value
end, scriptSettings.autosaveEnabled)
menu.toggle(settingsList, "Show Active Entity Overlay", {"jvboverlay"}, "Shows an overlay on entity you are currently editing. Only shown when menu is open", function(value)
    scriptSettings.showOverlay = value
end, scriptSettings.showOverlay)

menu.toggle(settingsList, "Show Add Entity Overlay", {"jvboverlayadd"}, "Shows an overlay when the menu is open on nearby entities, allowign you to add them to your custom build", function(value)
    scriptSettings.showAddOverlay = value
end, scriptSettings.showAddOverlay)

menu.divider(menu.my_root(), "")

--[[
    CLOUD DATA
]]--
local cloudData = {}
local cloudRootMenuList = menu.list(menu.my_root(), "Cloud Builds", {}, "Browse & upload custom builds", function() _fetch_cloud_users() end, function() 
    for _, data in pairs(cloudData) do
        menu.delete(data.parentList)
    end
    cloudData = {}
end)
local cloudSearchList = menu.list(cloudRootMenuList, "Search Builds", {}, "Search all uploaded custom builds by name")
local cloudSearchResults = {}
menu.text_input(cloudSearchList, "Search", {"cbuildsearch"}, "Enter a search query", function(query)
    if query == "" or scriptEnding then return end
    show_busyspinner("Searching builds...")
    for _, data in pairs(cloudSearchResults) do
        menu.delete(data.list)
    end
    cloudSearchResults = {}
    async_http.init("jackz.me", "/stand/cloud/custom-vehicles.php?q=" .. query, function(body, res_headers, status_code)
        HUD.BUSYSPINNER_OFF()
        if status_code == 200 then
            if body[1] == "{" then
                local results = json.decode(body).results
                if #results == 0 then
                    util.toast("No builds found")
                    return
                end
                for _, vehicle in ipairs(results) do
                    
                    local description = _format_vehicle_info(vehicle.format, vehicle.uploaded, vehicle.uploader, vehicle.rating)
                    cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name] = {
                        list = nil,
                        data = nil
                    }
                    local vehicleList = menu.list(cloudSearchList, string.format("%s/%s", vehicle.uploader, vehicle.name), {}, description or "<invalid metadata>", function()
                        _setup_cloud_build_menu(cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name].list, vehicle.uploader, vehicle.name, cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name])
                    end)
                    cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name].list = vehicleList
                    menu.on_focus(vehicleList, function()
                        _fetch_vehicle_data(cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name], vehicle.uploader, vehicle.name)
                    end)
                end
            else
                Log.log("invalid server response : " .. body, "_fetch_cloud_users")
                util.toast("Server returned invalid response")
            end
        else
            Log.log("bad server response : " .. status_code .. "\n" .. body, "_fetch_cloud_users")
            util.toast("Server returned error " .. status_code)
        end
    end)
    async_http.dispatch()
end)
menu.divider(cloudRootMenuList, "Users")
function _fetch_cloud_users()
    show_busyspinner("Fetching cloud data...")
    async_http.init("jackz.me", "/stand/cloud/custom-vehicles.php", function(body, res_headers, status_code)
        -- Server returns an array of key values, key is uploader name, value is metadata
        if status_code == 200 then
            HUD.BUSYSPINNER_OFF()
            if body[1] == "{" then
                cloudData = json.decode(body).users
                for user, vehicles in pairsByKeys(cloudData) do
                    local userList = menu.list(cloudRootMenuList, string.format("%s (%d)", user, #vehicles), {}, string.format("%d builds", #vehicles), function()
                        _load_cloud_vehicles(user)
                    end, function()
                        cloudData[user].vehicleData = {}
                    end)
                    menu.on_focus(userList, clear_build_preview)
                    cloudData[user] = {
                        vehicles = vehicles,
                        vehicleData = {},
                        parentList = userList,
                        vehicleMenuIds = {}
                    }
                end
            else
                Log.log("invalid server response : " .. body, "_fetch_cloud_users")
                util.toast("Server returned invalid response")
            end
        else
            Log.log("bad server response : " .. status_code .. "\n" .. body, "_fetch_cloud_users")
            util.toast("Server returned error " .. status_code)
        end
    end)
    async_http.dispatch()
end
function _load_cloud_vehicles(user) 
    if not cloudData[user] then
        util.toast("Error: Missing cloud data for user " .. user)
    else
        clear_menu_array(cloudData[user].vehicleMenuIds)
        for _, vehicle in ipairs(cloudData[user].vehicles) do
            local description = _format_vehicle_info(vehicle.format, vehicle.uploaded, vehicle.author, vehicle.rating)
            local vehicleMenuRoot
            cloudData[user].vehicles[vehicle.name] = {}
            vehicleMenuRoot = menu.list(cloudData[user].parentList, vehicle.name, {}, description or "<invalid build metadata>", function()
                _setup_cloud_build_menu(vehicleMenuRoot, user, vehicle.name, cloudData[user].vehicles[vehicle.name])
            end)
            menu.on_focus(vehicleMenuRoot, function()
                _fetch_vehicle_data(cloudData[user].vehicles[vehicle.name], user, vehicle.name)
            end)

            table.insert(cloudData[user].vehicleMenuIds, vehicleMenuRoot)

        end
    end
end
function _fetch_vehicle_data(tableref, user, vehicleName)
    show_busyspinner("Fetching build info...")
    async_http.init("jackz.me", string.format("/stand/cloud/custom-vehicles.php?scname=%s&vehicle=%s", user, vehicleName), function(body, res_headers, status_code)
        HUD.BUSYSPINNER_OFF()
        clear_build_preview()
        if status_code == 200 then
            if body[1] == "{" then
                local data = json.decode(body)
                if not data.vehicle then
                    Log.log(body, "_fetch_vehicle_data")
                    util.toast("Invalid build data was fetched")
                    return
                end
                tableref['vehicle'] = data.vehicle
                if not data.vehicle.name then
                    data.vehicle.name = vehicleName
                end
                data.uploader = user
                spawn_build(tableref['vehicle'], true, _render_cloud_build_overlay, data)
            else
                local isRatelimited = body:find("503 Service Temporarily Unavailable")
                if isRatelimited then
                    util.toast("Rate limited, please wait")
                else
                    Log.log("invalid server response : " .. body, "_fetch_cloud_users")
                    util.toast("Server returned an invalid response. Server may be under maintenance or experiencing problems")
                end
            end
        else
            Log.log("bad server response : " .. status_code .. "\n" .. body, "_fetch_cloud_users")
            util.toast("Server returned error " .. status_code)
        end
    end)
    async_http.dispatch()
end
function _setup_cloud_build_menu(rootList, user, vehicleName, vehicleData)
    local tries = 0
    while not vehicleData['vehicle'] and tries < 10 do
        util.yield(500)
        tries = tries + 1
    end
    if tries > 10 then
        util.toast("Timed out acquiring build data")
        return
    end
    while not vehicleData and tries < 30 do
        util.yield(500)
        tries = tries + 1
    end
    if tries == 30 then return end
    menu.action(rootList, "Spawn", {}, "", function()
        clear_build_preview()
        local baseHandle = spawn_build(vehicleData['vehicle'], false)
        if (vehicleData['vehicle'].type or "VEHICLE") == "VEHICLE" and scriptSettings.spawnInVehicle then
            util.yield()
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
        end
    end)

    menu.action(rootList, "Edit", {}, "", function()
        if import_build_to_builder(vehicleData['vehicle'], vehicleName) then
            menu.focus(builder.entitiesMenuList)
        else
            util.toast("Could not spawn build's base entity; cannot spawn build.")
        end
    end)
    menu.text_input(rootList, "Download", {"download"..user.."."..vehicleName}, "", function(filename)
        if filename == "" or scriptEnding then return end
        if not filesystem.exists(DOWNLOADS_DIRECTORY) then
            filesystem.mkdir(DOWNLOADS_DIRECTORY)
        end
        local file = io.open(join_path(DOWNLOADS_DIRECTORY, filename), "w")
        if file then
            file:write(json.encode(vehicleData['vehicle']))
            file:flush()
            file:close()
            util.toast(string.format("Downloaded %s to downloads directory", vehicleName))
        else
            util.toast("Could download file")
        end
    end, vehicleName .. ".json")

    menu.click_slider(rootList, "Rate", {"rate"..user.."."..vehicleName}, "Rate the uploaded build with 1-5 stars", 1, 5, 5, 1, function(rating)
        rate_build(user, vehicleName, rating)
    end)
end
function rate_build(user, vehicleName, rating)
    if not user or not vehicleName or rating < 0 or rating > 5 then
        Log.log("Invalid rate params. " .. user .. "|" .. vehicleName .. "|" .. rating, "rate_build")
        return false
    end
    async_http.init("jackz.me", 
        string.format("/stand/cloud/custom-vehicles.php?scname=%s&vehicle=%s&hashkey=%s&rater=%s&rating=%d",
            user, vehicleName, menu.get_activation_key_hash(), SOCIALCLUB._SC_GET_NICKNAME(), rating
        ),
    function(body, res_header, status_code)
        if status_code == 200 then
            if body:sub(1, 1) == "{" then
                local data = json.decode(body)
                if data.success then
                    util.toast("Rating submitted")
                else
                    Log.log(body)
                    util.toast("Failed to submit rating, see logs for info")
                end
            else
                util.toast("Failed to submit rating, server sent invalid response")
            end
        else
            Log.log("bad server response : " .. status_code .. "\n" .. body, "_fetch_cloud_users")
            util.toast("Server returned error " .. status_code)
        end

    end, function()
        util.toast("Failed to submit rating due to an unknown error")
    end)
    async_http.set_post("application/json", "")
    async_http.dispatch()
    return true
end
--[ SAVED VEHICLES LIST ]
local savedVehicleList = menu.list(menu.my_root(), "Saved Builds", {}, "",
    function() _load_saved_list() end,
    function() _destroy_saved_list() end
)
local folderLists = {}
local xmlMenusHandles = {}
menu.hyperlink(savedVehicleList, "Open Folder", "file://" .. SAVE_DIRECTORY, "Open the save directory in your file explorer")
menu.toggle(savedVehicleList, "Spawn In Vehicle", {}, "Force yourself to spawn in the base vehicle, if applicable", function(on)
    scriptSettings.spawnInVehicle = on
end, scriptSettings.spawnInVehicle)
local xmlList = menu.list(savedVehicleList, "Convert Builds", {}, "Convert builds and vehicles from certain supported sources.\nVery buggy and unsupported right now. Limited support for:\nNullify\nMenyoo\nSome ini vehicles")
local savedVehicleListInner = menu.divider(savedVehicleList, "Folders")
local optionsMenuHandles = {}
local optionParentMenus = {}

function _load_vehicles_from_dir(parentList, directory)
    local queue = {} -- Queue non-folders so folders show first
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        local _, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if filesystem.is_dir(filepath) then
            local folderList = menu.list(parentList, filename, {}, "")
            _load_vehicles_from_dir(folderList, filepath)
            table.insert(folderLists, folderList)
        else
            if ext == "json" then
                table.insert(queue, function() _setup_spawn_list_entry(parentList, filepath) end)
            elseif ext == "xml" then
                filename = filename:sub(1, -5)
                local newPath = SAVE_DIRECTORY .. "/" .. filename .. ".json"
                xmlMenusHandles[filename] = menu.action(xmlList, filename, {}, "Click to convert to a compatible format.", function()
                    if filesystem.exists(newPath) then
                        menu.show_warning(xmlMenusHandles[filename], CLICK_COMMAND, "This file already exists, do you want to overwrite " .. filename .. ".json?", function() 
                            convert_file(filename, filename, newPath)
                        end)
                        return
                    end
                    convert_file(filename, filename, newPath)
                end)
            end
        end
    end
    table.insert(folderLists, menu.divider(parentList, "Builds"))
    for _, queueFunc in ipairs(queue) do
        queueFunc()
    end
end
function _format_vehicle_info(version, timestamp, author, rating)
    local versionText
    if version then
        local m = {}
        for match in version:gmatch("([^%s]+)") do
            table.insert(m, match)
        end
        local fileVersion = m[#m]
        local versionDiff = compare_version(BUILDER_VERSION, fileVersion)
        if versionDiff == 1 then
            versionText = string.format("%s (Older version, latest %s)", fileVersion, BUILDER_VERSION)
        elseif versionDiff == -1 then
            versionText = string.format("%s (Unsupported version, latest %s)", fileVersion, BUILDER_VERSION)
        else
            versionText = string.format("%s (Latest)", fileVersion, BUILDER_VERSION)
        end

        local createdText = timestamp and (os.date("%Y-%m-%d at %X", timestamp) .. " UTC") or "-unknown-"
        local authorText = author and (string.format("Build Author: %s\n", author)) or ""
        local ratingText = rating and (
            rating ~= "0.0" and (string.format("\nRating: %s / 5 stars ", rating))
                or "No user ratings"
        ) or ""

        return string.format("Format Version: %s\nCreated: %s\n%s\n%s", versionText, createdText, authorText, ratingText)
    else
        return nil
    end
end
function _setup_spawn_list_entry(parentList, filepath)
    local _, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    local status, data = pcall(get_build_data_from_file, filepath)
    if status and data ~= nil then
        if not data.base or not data.version then
            Log.log("Skipping invalid build: " .. filepath)
            return
        end
        
        local description = _format_vehicle_info(data.version, data.created, data.author)

        optionParentMenus[filepath] = menu.list(parentList, filename, {}, description or "<INVALID METADATA>",
            function()
                clear_menu_array(optionsMenuHandles)
                table.insert(optionsMenuHandles, menu.action(optionParentMenus[filepath], "Spawn", {}, "", function()
                    lastAutosave = os.seconds()
                    autosaveNextTime = lastAutosave + AUTOSAVE_INTERVAL_SEC
                    clear_build_preview()
                    local baseHandle = spawn_build(data, false)
                    if (data.type or "VEHICLE") == "VEHICLE" and scriptSettings.spawnInVehicle then
                        util.yield()
                        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                        TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
                    end
                end))
    
                table.insert(optionsMenuHandles, menu.action(optionParentMenus[filepath], "Edit", {}, "", function()
                    lastAutosave = os.seconds()
                    autosaveNextTime = lastAutosave + AUTOSAVE_INTERVAL_SEC
                    import_build_to_builder(data, filename:sub(1, -6))
                    menu.focus(builder.entitiesMenuList)
                end))

                table.insert(optionsMenuHandles, menu.action(optionParentMenus[filepath], "Upload", {}, "", function()
                    upload_build(filename:sub(1, -6), json.encode(data))
                end))

                table.insert(optionsMenuHandles, menu.action(optionParentMenus[filepath], "Add to Build", {}, "Adds the build as it's own entity, attached to your current build. You will be unable to edit its entities.", function()
                    local subbaseHandle = spawn_build(data, false)
                    add_build_to_list(builder.entitiesMenuList, subbaseHandle, data, data.name or data.filename)
                    util.toast("Added build to your current build")
                end))
            end,
            function() _destroy_options_menu() end
        )
        
        -- Spawn build preview handler
        menu.on_focus(optionParentMenus[filepath], function()
            if preview.id ~= filename then
                data.filename = filename
                spawn_build(data, true, _render_saved_build_overlay, data)
            end
        end)
    else
        Log.log(string.format("Skipping build \"%s\" due to error: (%s)", filepath, (data or "<EMPTY FILE>")))
    end
end
function _render_saved_build_overlay(pos, data)
    local hudPos = get_screen_coords(pos)
    directx.draw_rect(hudPos.x, hudPos.y, 0.25, 0.105, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
    local authorText = data.author and ("Created by " .. data.author) or "Unknown creator"

    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, data.name or data.filename, ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, data.version, ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.075, string.format("%d vehicles, %d objects, %d peds", data.vehicles and #data.vehicles or 0, data.objects and #data.objects or 0, data.peds and #data.peds or 0), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
end
function _render_cloud_build_overlay(pos, data)
    local hudPos = get_screen_coords(pos)
    directx.draw_rect(hudPos.x, hudPos.y, 0.25, 0.12, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
    local authorText = data.vehicle.author and ("Created by " .. data.vehicle.author) or "Unknown creator"

    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, data.vehicle.name, ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.025, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.042, "Uploaded by " .. data.uploader, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.065, data.vehicle.version, ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.08, string.format("%d vehicles, %d objects, %d peds", data.vehicle.vehicles and #data.vehicle.vehicles or 0, data.vehicle.objects and #data.vehicle.objects or 0, data.vehicle.peds and #data.vehicle.peds or 0), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    if data.rating == "0.0" then
        directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.095, "No ratings", ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    else
        directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.095, string.format("%.1f/5.0 rating", data.rating), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    end

end
function _load_saved_list()
    clear_build_preview()
    clear_menu_table(optionParentMenus)
    clear_menu_table(xmlMenusHandles)
    clear_menu_table(folderLists)
    _load_vehicles_from_dir(savedVehicleList, SAVE_DIRECTORY)
end
function convert_file(path, name, newPath)
    local file = io.open(path, "r")
    show_busyspinner("Converting " .. name)
    local res = vehiclelib.ConvertXML(file:read("*a"))
    HUD.BUSYSPINNER_OFF()
    if res.error then
        util.toast("Could not convert: " .. res.error, TOAST_ALL)
        util.toast("Try the online converter: jackz.me/stand/vehicle-converter")
        file:close()
    else
        util.toast("Successfully converted " .. res.data.type .. " build\nView it in your saved vehicle list")
        file = io.open(newPath, "w")
        res.data.vehicle.convertedFrom = res.data.type
        file:write(json.encode(res.data.vehicle))
        file:close()
    end
end
function _destroy_saved_list()
end
    --[ SUB: Destroy builder context menu ]--
    function _destroy_options_menu()
        clear_menu_table(optionsMenuHandles)
    end
menu.on_focus(savedVehicleList, function() clear_build_preview() end)

local STRUCTURE_OBJECT_MODEL = util.joaat("prop_roadcone02a")

--[ Setup menus, depending on base exists ]--
function setup_pre_menu()
    clear_menu_array(setupMenus)
    table.insert(setupMenus, menu.action(menu.my_root(), "Set current vehicle as base", {}, "Creates a new custom vehicle with your current vehicle as the base", function()
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        if vehicle > 0 then
            builder = new_builder()
            load_recents()
            set_builder_base(vehicle)
            setup_builder_menus()
        else
            util.toast("You are not in a vehicle.")
        end
    end))

    table.insert(setupMenus, menu.action(menu.my_root(), "Create new structure", {"jvbstruct"}, "Creates a new structure, instead of a custom vehicle", function()
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 7.5, 0.0)
        local new_z = get_ground_z(pos.x, pos.y, pos.z)
        if new_z then pos.z = new_z end
        local base = spawn_object({
            model = STRUCTURE_OBJECT_MODEL
        }, false, pos)
        builder = new_builder()
        ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(base, true, false)
        ENTITY.FREEZE_ENTITY_POSITION(base, true)
        set_builder_base(base)
        setup_builder_menus()
    end))

    table.insert(setupMenus, menu.action(menu.my_root(), "Create manual base", {"jvbmanual"}, "Spawns a ped, vehicle, or object by its exact name", function()
        menu.show_command_box("jvbmanual ")
    end, function(query)
        local hash = util.joaat(query)
        if STREAMING.IS_MODEL_VALID(hash) then
            local type = "OBJECT"
            -- TODO: Verify STREAMING is working
            if STREAMING.IS_MODEL_A_VEHICLE(hash) then
                type = "VEHICLE"
            elseif STREAMING.IS_MODEL_A_PED(hash) then
                type = "PED"
            end
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 7.5, 0.2)
                local base = spawn_entity({
                    model = hash
                }, type, false, pos)
                if base then
                    builder = new_builder()
                    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(base, true, false)
                    ENTITY.FREEZE_ENTITY_POSITION(base, true)
                    set_builder_base(base)
                    setup_builder_menus()
                else
                    util.toast("Entity failed to spawn")
                end
        else
            util.toast("Model is invalid")
        end
    end))
end

function get_ground_z(x, y, z, tries, ignoreWater)
    if not ignoreWater then ignoreWater = false end
    local pZ = memory.alloc_int()
    if not tries then tries = 1 end
    local new_z = nil
    while tries > 0 do
        if MISC.GET_GROUND_Z_FOR_3D_COORD(x, y, z, pZ, ignoreWater) then
            new_z = memory.read_float(pZ)
            break
        end
        tries = tries - 1
    end
    return new_z
end

function setup_builder_menus(name)
    clear_menu_array(setupMenus)
    if not builder.base.handle or builder.ent_spawner_active then
        return
    end
    local baseType = "OBJECT"
    if ENTITY.IS_ENTITY_A_PED(builder.base.handle) then
        baseType = "PED"
    elseif ENTITY.IS_ENTITY_A_VEHICLE(builder.base.handle) then
        baseType = "VEHICLE"
    end

    local newBuildMenu
    newBuildMenu = menu.action(menu.my_root(), "Start a new build", {}, "Delete the current build and start a new", function() 
        menu.show_warning(newBuildMenu, CLICK_COMMAND, "Starting a new build will delete your current build. All data and entities will be wiped. Are you sure you want to continue?", function()
            menu.trigger_command(builder.deleteMenu)
        end)
    end)

    mainMenu = menu.list(menu.my_root(), "Current Build", {}, "", function() 
        editorActive = true
    end, function()
        editorActive = false
        _destroy_prop_previewer()
    end)

    table.insert(setupMenus, newBuildMenu)
    local buildList = menu.list(mainMenu, "Build", {}, "Save, upload, change the build's author, and clear the active build.")
        menu.text_input(buildList, "Save", {"savebuild"}, "Enter a name to save the build as\nSupports relative paths such as foldername\\buildname\n\nSaved to %appdata%\\Stand\\Builds", function(name)
            if name == "" or scriptEnding then return end
            set_builder_name(name)
            if save_vehicle(name) then
                util.toast("Saved build as " .. name .. ".json to %appdata%\\Stand\\Builds")
            end
        end, name or "")
        local uploadMenu
        uploadMenu = menu.text_input(buildList, "Upload", {"uploadbuild"}, "Enter the name to upload the build as\nUploading as " .. SOCIALCLUB._SC_GET_NICKNAME(), function(name)
            if name == "" or scriptEnding then return end
            set_builder_name(name)
            local data = builder_to_json()
            if not data then
                util.toast("Error serializing build, cannot upload")
                return
            end
            if not builder.author then
                menu.show_warning(uploadMenu, CLICK_MENU, "You are uploading a build without an author set. An author is not required, but the author will be tied to the build itself.", function()
                    upload_build(name, data)
                end)
            else
                upload_build(name, data)
            end
        end, name or "")
        menu.text_input(buildList, "Author", {"buildauthor"}, "Set the author of the build, none is set by default. This is used to distinquish between build uploaders and the original creator", function(input)
            builder.author = input
            util.toast("Set the builds's author to: " .. input)
        end, builder.author or "")
        local spawnLocationList = menu.list(buildList, "Spawn Location", {}, "Specifies the location where the build will spawn")
            local spawnX, spawnY, spawnZ
            menu.toggle(spawnLocationList, "Spawn at specific coordinates", {}, "If checked, the build's base entity will spawn at this position. If not, it will spawn in front of you", function(value)
                if value then
                    local spawnLocation = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
                    menu.set_value(spawnX, math.floor(spawnLocation.x * 100))
                    menu.set_visible(spawnX, true)
                    menu.set_value(spawnY, math.floor(spawnLocation.y * 100))
                    menu.set_visible(spawnY, true)
                    menu.set_value(spawnZ, math.floor(spawnLocation.z * 100))
                    menu.set_visible(spawnZ, true)
                    builder.spawnLocation = { x = spawnLocation.x, y = spawnLocation.y, z = spawnLocation.z }
                else
                    builder.spawnLocation = nil
                    menu.set_value(spawnX, 0)
                    menu.set_visible(spawnX, false)
                    menu.set_value(spawnY, 0)
                    menu.set_visible(spawnY, false)
                    menu.set_value(spawnZ, 0)
                    menu.set_visible(spawnZ, false)

                end
            end)
            spawnX = menu.slider_float(spawnLocationList, "X", {}, "", -1000000, 1000000, 0, 1, function(value)
                if builder.spawnLocation then
                    builder.spawnLocation.x = value / 100
                    ENTITY.SET_ENTITY_COORDS(builder.base.handle, builder.spawnLocation.x, builder.spawnLocation.y, builder.spawnLocation.z)
                end
            end)
            menu.set_visible(spawnX, false)
            spawnY = menu.slider_float(spawnLocationList, "Y", {}, "", -1000000, 1000000, 0, 1, function(value)
                if builder.spawnLocation then
                    builder.spawnLocation.y = value / 100
                    ENTITY.SET_ENTITY_COORDS(builder.base.handle, builder.spawnLocation.x, builder.spawnLocation.y, builder.spawnLocation.z)
                end
            end)
            menu.set_visible(spawnY, false)
            spawnZ = menu.slider_float(spawnLocationList, "Z", {}, "", -1000000, 1000000, 0, 1, function(value)
                if builder.spawnLocation then
                    builder.spawnLocation.z = value / 100
                    ENTITY.SET_ENTITY_COORDS(builder.base.handle, builder.spawnLocation.x, builder.spawnLocation.y, builder.spawnLocation.z)
                end
            end)
            menu.set_visible(spawnZ, false)

        builder.deleteMenu = menu.action(buildList, "Clear Build", {"clearbuild"}, "Deletes the active builder with all settings and entities cleared. This will delete all attachments", function()
            menu.show_warning(builder.deleteMenu, CLICK_COMMAND, "Are you sure you want to delete your custom build? All data and entities will be wiped.", function()
                builder.deleteMenu = nil
                remove_all_attachments(builder.base.handle)
                if HUD.DOES_BLIP_EXIST(builder.blip) then
                    util.remove_blip(builder.blip)
                end
                builder = nil
                if mainMenu then
                    menu.delete(mainMenu)
                    mainMenu = nil
                end
                setup_pre_menu()
            end)
        end)

    menu.focus(buildList)
    editorActive = true
    
    builder.entitiesMenuList = menu.list(mainMenu, "Entities", {}, "Manage all attached entities", function() highlightedHandle = nil end)
        menu.slider(builder.entitiesMenuList, "Coordinate Sensitivity", {"offsetsensitivity"}, "Sets the sensitivity of changing the offset coordinates of an entity", 1, 20, POS_SENSITIVITY, 1, function(value)
            POS_SENSITIVITY = value
            if not value then
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, false)
                ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
            end
        end)
        menu.toggle(builder.entitiesMenuList, "Free Edit", {"jvbfreeedit"}, "Allows you to move entities by holding the following keys:\nWASD -> Normal\nSHIFT/CTRL - Up and down\nNumpad 8/5 - Pitch\nNumpad 4/6 - Roll\nNumpad 7/9 - Rotation\n\nWill only work when hovering over an entity or stand is closed, disabled in entity list.", function(value)
            FREE_EDIT = value
        end, FREE_EDIT)
        menu.divider(builder.entitiesMenuList, "Entities")
    local baseList = menu.list(mainMenu, "Base Entity", {}, "")
        local settingsList = menu.list(baseList, "Settings", {}, "")
        menu.on_focus(settingsList, function()
            highlightedHandle = builder.base.handle
        end)
        menu.action(baseList, "Teleport Into", {}, "Teleport into the base entity, if applicable", function()
            if ENTITY.IS_ENTITY_A_VEHICLE(builder.base.handle) then
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, builder.base.handle, -1)
            else
                util.toast("Base entity is not a vehicle")
            end
        end)
        local deleteAttachmentsMenu
        deleteAttachmentsMenu = menu.action(baseList, "Clear All Attachments", {}, "Deletes all entities attached to build's base entity, including untracked, but attached entities.", function()
            menu.show_warning(deleteAttachmentsMenu, CLICK_COMMAND, "This will delete all attached entities from the world and from the builder. Are you sure?", function()
                remove_all_attachments(builder.base.handle)
                for handle, data in pairs(builder.entities) do
                    if handle ~= builder.base.handle then
                        menu.delete(data.list)
                        builder.entities[handle] = nil
                    end
                end
                highlightedHandle = nil
            end)
        end)
        menu.action(baseList, "Set current vehicle as new base", {}, "Re-assigns all entities to a new base vehicle", function()
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
            if vehicle > 0 then
                if vehicle == builder.base.handle then
                    util.toast("This vehicle is already the base vehicle.")
                else
                    set_builder_base(vehicle)
                end
            else
                util.toast("You are not in a vehicle.")
            end
        end)

        builder.entities[builder.base.handle] = {
            list = settingsList,
            type = baseType,
            model = ENTITY.GET_ENTITY_MODEL(builder.base.handle),
            listMenus = {},
            pos = { x = 0.0, y = 0.0, z = 0.0 },
            rot = { x = 0.0, y = 0.0, z = 0.0 },
            visible = true,
            godmode = true
        }
        local blipList = menu.list(settingsList, "Blip Icon", {"jvbicon"}, "Changes the blip icon for this build.")
        for _, icon in ipairs(BLIP_ICONS) do
            menu.action(blipList, icon[2], {"jvbicon" .. icon[1]}, "Blip ID: " .. icon[1], function()
                builder.blip_icon = icon[1]
                if HUD.DOES_BLIP_EXIST(builder.blip) then
                    HUD.SET_BLIP_SPRITE(builder.blip, icon[1])
                end
                util.toast("Blip changed to: " .. icon[2])
            end)
        end
        create_entity_section(builder.entities[builder.base.handle], builder.base.handle, { noRename = true } )
       
    menu.divider(mainMenu, "")

    builder.propSpawner.root = menu.list(mainMenu, "Add Props", {"builderprops"}, "Browse props to spawn to add to your build")
    menu.on_focus(builder.propSpawner.root, function() _destroy_browse_menu("propSpawner") end)
    builder.vehSpawner.root = menu.list(mainMenu, "Add Vehicles", {"buildervehicles"}, "Browse vehicles to spawn to add to your build")
    menu.on_focus(builder.vehSpawner.root, function() _destroy_browse_menu("vehSpawner") end)
    builder.pedSpawner.root = menu.list(mainMenu, "Add Peds", {"builderpeds"}, "Browse peds to spawn to add to your build")
    menu.on_focus(builder.pedSpawner.root, function() _destroy_browse_menu("pedSpawner") end)
    builder.particlesSpawner.root = menu.list(mainMenu, "Add Particles", {"builderparticles"}, "Browse particles to spawn to add to your build\nNote: Particles will be spawned as looped but some particles do not support being looped.")
    menu.on_focus(builder.particlesSpawner.root, function() _destroy_browse_menu("particlesSpawner") end)
    menu.action(mainMenu, "Add Builds", {}, "You can add builds directly from the \"Saved Builds\" menu -> \"Add to build\".\nClick to jump to the saved builds menu", function()
        _load_saved_list()
        menu.focus(savedVehicleListInner)
    end)
    create_object_spawner_list(builder.propSpawner.root)
    create_vehicle_spawner_list(builder.vehSpawner.root)
    create_ped_spawner_list(builder.pedSpawner.root)
    create_particles_fx_spawner_list(builder.particlesSpawner.root)
    builder.ent_spawner_active = true
end

function set_builder_base(handle, preserveExisting)
    builder.base.type = "OBJECT"
    if ENTITY.IS_ENTITY_A_VEHICLE(handle) then
        builder.base.type  = "VEHICLE"
    elseif ENTITY.IS_ENTITY_A_PED(handle) then
        builder.base.type  = "PED"
    end

    local oldHandle = builder.base.handle
    builder.base.handle = handle

    if builder.entities[oldHandle] then
        builder.entities[handle] = builder.entities[oldHandle]
        builder.entities[oldHandle] = nil
    else
        builder.entities[builder.base.handle] = {
            list = settingsList,
            type = builder.base.type,
            model = ENTITY.GET_ENTITY_MODEL(builder.base.handle),
            listMenus = {},
            pos = { x = 0.0, y = 0.0, z = 0.0 },
            rot = { x = 0.0, y = 0.0, z = 0.0 },
            visible = true,
            godmode = true
        }
    end


    if HUD.DOES_BLIP_EXIST(builder.blip) then
        util.remove_blip(builder.blip)
    end
    builder.blip = create_blip_for_entity(handle, builder.blip_icon, builder.name or "Custom Build")
    if highlightedHandle == builder.base.handle then
        highlightedHandle = nil
    end
    Log.log("Reassigned base " .. (oldHandle or "-none-") .. " -> " .. handle)
    for subhandle, data in pairs(builder.entities) do
        -- Ignore entity if parent is not builder, as it's parent should be re-attached
        if not data.parent then
            attach_entity(handle, subhandle, data.pos, data.rot, data.boneIndex)
        end
    end
end

function set_builder_name(name)
    builder.name = name
    if HUD.DOES_BLIP_EXIST(builder.blip) then
        HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
        HUD.END_TEXT_COMMAND_SET_BLIP_NAME(builder.blip)
    end
end

function create_object_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "", function() end, clear_build_preview)
    for _, prop in ipairs(CURATED_PROPS) do
        add_prop_menu(curatedList, prop)
    end
    local searchList = menu.list(root, "Search Props", {}, "Search for a prop by name")
    menu.text_input(searchList, "Search", {"searchprops"}, "Enter a prop name to search for", function(query)
        create_prop_search_results(searchList, query, 30)
    end)
    menu.text_input(root, "Manual Input", {"customprop"}, "Enter the prop name to spawn", function(query)
        local hash = util.joaat(query)
        if STREAMING.IS_MODEL_VALID(hash) and not STREAMING.IS_MODEL_A_VEHICLE(hash) then
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
            local entity = entities.create_object(hash, pos)
            add_entity_to_list(builder.entitiesMenuList, entity, query)
            highlightedHandle = entity
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        else
            util.toast("Object entered does not exist")
        end
    end)
    builder.propSpawner.recents.list = menu.list(root, "Recent Props", {}, "Your most recently spawned props", _load_prop_recent_menu, _destroy_recent_menus)
    builder.propSpawner.favorites.list = menu.list(root, "Favorite Props", {}, "Your favorited spawned props\nPress SHIFT + ENTER to remove items from favorites", _load_prop_favorites_menu, _destroy_favorites_menus)
    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all the props in the game.", function()
        _load_prop_browse_menus(browseList)
    end)
end

function create_ped_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "", function() end, clear_build_preview)
    for _, ped in ipairs(CURATED_PEDS) do
        add_ped_menu(curatedList, ped[1], ped[2])
    end
    local searchList = menu.list(root, "Search Peds", {}, "Search for a ped by name")
    menu.text_input(searchList, "Search", {"builderquerypeds"}, "Enter a ped name to search for", function(query)
        create_ped_search_results(searchList, query, 30)
    end)
    menu.text_input(root, "Manual Input", {"customped"}, "Enter the ped name to spawn", function(query)
        local hash = util.joaat(query)
        if STREAMING.IS_MODEL_VALID(hash) and not STREAMING.IS_MODEL_A_PED(hash) then
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
            local entity = entities.create_ped(0, hash, { x = 0, y = 0, z = 0})
            ENTITY.SET_ENTITY_COORDS(entity, pos.x, pos.y, pos.z)
            add_entity_to_list(builder.entitiesMenuList, entity, query)
            highlightedHandle = entity
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        else
            util.toast("Ped entered does not exist")
        end
    end)
    builder.pedSpawner.recents.list = menu.list(root, "Recent Peds", {}, "Your most recently spawned peds", _load_ped_recent_menu, _destroy_recent_menus)
    builder.pedSpawner.favorites.list = menu.list(root, "Favorite Peds", {}, "Your favorited spawned peds\nPress SHIFT + ENTER to remove items from favorites", _load_ped_favorites_menu, _destroy_favorites_menus)
    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all the peds in the game.", function()
        _load_ped_browse_menus(browseList)
    end)
end

function create_vehicle_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "")
    for _, data in ipairs(CURATED_VEHICLES) do
        add_vehicle_menu(curatedList, data[1], data[2])
    end
    local searchList = menu.list(root, "Search Vehicles")
    menu.text_input(searchList, "Search", {"searchvehicles"}, "Enter a vehicle name to search for", function(query)
        create_vehicle_search_results(searchList, query, 30)
    end)
    menu.text_input(root, "Manual Input", {"customveh"}, "Enter the vehicle name to spawn", function(query)
        local hash = util.joaat(query)
        if STREAMING.IS_MODEL_VALID(hash) and STREAMING.IS_MODEL_A_VEHICLE(hash) then
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            local vehicle = spawn_vehicle({
                model = hash
            })
            add_entity_to_list(builder.entitiesMenuList, vehicle, query)
        else
            util.toast("Vehicle inputted does not exist")
        end
    end)
    builder.vehSpawner.recents.list = menu.list(root, "Recent Vehicles", {}, "Browse your most recently used vehicles", _load_vehicle_recent_menu)
    builder.vehSpawner.favorites.list = menu.list(root, "Favorite Vehicles", {}, "Your favorited spawned vehicles\nPress SHIFT + ENTER to remove items from favorites", _load_vehicle_favorites_menu, _destroy_favorites_menus)

    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all vehicles", function()
        _load_vehicle_browse_menus(browseList)
    end)
    menu.action(root, "Clone Current Vehicle", {}, "Adds your current vehicle as part of your custom build", function()
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        if vehicle > 0 then
            local savedata = vehiclelib.Serialize(vehicle)
            vehicle = spawn_vehicle({
                model = savedata.Model,
                savedata = savedata
            }, false)
            local manufacturer = VEHICLE._GET_MAKE_NAME_FROM_VEHICLE_MODEL(savedata.Model)
            local name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(savedata.Model)
            add_entity_to_list(builder.entitiesMenuList, vehicle, manufacturer .. " " .. name)
        else
            util.toast("You are not in a vehicle.")
        end
    end)
end

function create_particles_fx_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "")
    for _, particle in ipairs(CURATED_PARTICLE_FX) do
        add_particles_menu(curatedList, particle[1], particle[2])
    end
    local searchList = menu.list(root, "Search Particles")
    menu.text_input(searchList, "Search", {"searchparticles"}, "Enter a particle name to search for", function(query)
        create_vehicle_search_results(searchList, query, 30)
    end)
    builder.particlesSpawner.recents.list = menu.list(root, "Recent Particles", {}, "Browse your most recently used particles", _load_particles_recent_menu)
    builder.particlesSpawner.favorites.list = menu.list(root, "Favorite Particles", {}, "Your favorited spawned particles\nPress SHIFT + ENTER to remove items from favorites", _load_particles_favorites_menu, _destroy_favorites_menus)

    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all particles", function()
        _load_particles_browse_menus(browseList)
    end)
end

-- [ RECENTS MENU LOAD LOGIC ]--
local recentMenus = {}
function _load_prop_recent_menu()
    _destroy_recent_menus()
    local sorted = {}
    for propName, count in pairs(builder.propSpawner.recents.items) do
        table.insert(sorted, { propName = propName, count = count })
    end
    table.sort(sorted, function(a, b) return a.count < b.count end)
    for _, data in ipairs(sorted) do
        table.insert(recentMenus, add_prop_menu(builder.propSpawner.recents.list, data.propName))
    end
end
function _load_ped_recent_menu()
    _destroy_recent_menus()
    local sorted = {}
    for pedName, count in pairs(builder.pedSpawner.recents.items) do
        table.insert(sorted, { pedName = pedName, count = count })
    end
    table.sort(sorted, function(a, b) return a.count < b.count end)
    for _, data in ipairs(sorted) do
        table.insert(recentMenus, add_ped_menu(builder.pedSpawaner.recents.list, data.pedName))
    end
end
function _load_vehicle_recent_menu() 
    _destroy_recent_menus()
    local sorted = {}
    for vehicleID, data in pairs(builder.vehSpawner.recents.items) do
        table.insert(sorted, { 
            id = vehicleID,
            dlc = data.dlc,
            name = data.name,
            count = data.count
        })
    end
    table.sort(sorted, function(a, b) return a.count < b.count end)
    for _, data in ipairs(sorted) do
        table.insert(recentMenus, add_vehicle_menu(builder.vehSpawner.recents.list, data.id, data.name, data.dlc))
    end
end
function _load_particles_recent_menu() 
    _destroy_recent_menus()
    local sorted = {}
    for dict, data in pairs(builder.particlesSpawner.recents.items) do
        table.insert(sorted, { 
            dict = dict,
            name = data.name,
            count = data.count
        })
    end
    table.sort(sorted, function(a, b) return a.count < b.count end)
    for _, data in ipairs(sorted) do
        table.insert(recentMenus, add_particles_menu(builder.particlesSpawner.recents.list, data.id, data.name))
    end
end
function _destroy_recent_menus()
    clear_menu_table(recentMenus)
end
-- [ END Recents ]--

-- [ RECENTS MENU LOAD LOGIC ]--
local favoriteMenus = {}
function _load_prop_favorites_menu()
    _destroy_favorites_menus()
    for _, data in ipairs(FAVORITES.objects) do
        table.insert(recentMenus, add_prop_menu(builder.propSpawner.favorites.list, data.prop, true))
    end
end
function _load_ped_favorites_menu()
    _destroy_favorites_menus()
    for _, data in ipairs(FAVORITES.peds) do
        table.insert(recentMenus, add_ped_menu(builder.pedSpawaner.favorites.list, data.ped, data.display, true))
    end
end
function _load_vehicle_favorites_menu() 
    _destroy_favorites_menus()
    for _, data in ipairs(FAVORITES.vehicles) do
        table.insert(recentMenus, add_vehicle_menu(builder.vehSpawner.favorites.list, data.vehicle, data.name, data.dlc, true))
    end
end
function _load_particles_favorites_menu()
    _destroy_favorites_menus()
    for _, data in ipairs(FAVORITES.particlesFx) do
        table.insert(recentMenus, add_particles_menu(builder.particlesSpawner.favorites.list, data.vehicle, data.name))
    end
end
function _destroy_favorites_menus()
    clear_menu_table(favoriteMenus)
end
-- [ END Recents ]--

local searchResults = {}
-- [ "Spawn Props" Menu Logic ]
-- Search: via table
function create_prop_search_results(parent, query, max)
    clear_menu_table(searchResults)

    local results = {}
    for prop in io.lines(PROPS_PATH) do
        local i, j = prop:find(query)
        if i then
            -- Add the distance:
            table.insert(results, {
                prop = prop,
                distance = j - i
            })
        end
    end
    table.sort(results, function(a, b) return a.distance > b.distance end)
    for i = 1, max do
        if results[i] then
            table.insert(searchResults, add_prop_menu(parent, results[i].prop))
        end
    end
end

function create_ped_search_results(parent, query, max)
    clear_menu_table(searchResults)

    local results = {}
    for ped in io.lines(PEDS_PATH) do
        local i, j = ped:find(query)
        if i then
            -- Add the distance:
            table.insert(results, {
                ped = ped,
                distance = j - i
            })
        end
    end
    table.sort(results, function(a, b) return a.distance > b.distance end)
    for i = 1, max do
        if results[i] then
            table.insert(searchResults, add_ped_menu(parent, results[i].ped))
        end
    end
end
-- Search: via URL
local requestActive = false

function create_vehicle_search_results(searchList, query, max)
    clear_menu_table(searchResults)
    if requestActive then return end
    show_busyspinner("Searching builds...")
    requestActive = true
    async_http.init("jackz.me", "/stand/search-vehicle-db.php?q=" .. query .. "&max=" .. max, function(body)
        for line in string.gmatch(body, "[^\r\n]+") do
            local id, name, hash, dlc = line:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            table.insert(searchResults, add_vehicle_menu(searchList, id, name, dlc))
        end
        requestActive = false
        HUD.BUSYSPINNER_OFF()
    end)
    async_http.dispatch()
end

function _load_prop_browse_menus(parent)
    if builder.propSpawner.loadState == 0 then
        show_busyspinner("Loading browse menu...")
        for prop in io.lines(PROPS_PATH) do
            table.insert(builder.propSpawner.menus, add_prop_menu(parent, prop))
        end
        builder.propSpawner.loadState = 2
        HUD.BUSYSPINNER_OFF()
    end
end
function _load_ped_browse_menus(parent)
    if builder.pedSpawner.loadState == 0 then
        show_busyspinner("Loading browse menu...")
        for prop in io.lines(PEDS_PATH) do
            table.insert(builder.pedSpawner.menus, add_prop_menu(parent, prop))
        end
        builder.pedSpawner.loadState = 2
        HUD.BUSYSPINNER_OFF()
    end
end
function _load_vehicle_browse_menus(parent)
    if builder.vehSpawner.loadState == 0 then
        show_busyspinner("Loading browse menu...")
        builder.vehSpawner.loadState = 1
        local currentClass = nil
        for line in io.lines(VEHICLES_PATH) do
            local class = line:match("CLASS (%g+)")
            if class then
                currentClass = menu.list(parent, class:gsub("_+", " "), {}, "")
                table.insert(builder.vehSpawner.menus, currentClass)
            else
                local id, name, hash, dlc = line:match("([^,]+),([^,]+),([^,]+),([^,]+)")
                if id then
                    add_vehicle_menu(currentClass, id, name, dlc)
                end
            end
        end
        builder.vehSpawner.loadState = 2
    end
end
function _load_particles_browse_menus(parent)
    if builder.particlesSpawner.loadState == 0 then
        show_busyspinner("Loading browse menu...")
        builder.vehSpawner.loadState = 1
        local currentDict = nil
        local currentDictMenu = nil
        for line in io.lines(PARTICLES_PATH) do
            local dict = line:match("^%[(%g+)%]")
            if dict then
                currentDict = dict
                currentDictMenu = menu.list(parent, dict, {}, "")
                table.insert(builder.particlesSpawner.menus, currentDictMenu)
            elseif currentDict then
                line = line:gsub("%s+", "")
                -- Ignore '#' comments and empty erlines
                if line ~= "" and line:sub(1, 1) ~= "#" then
                    add_particles_menu(currentDictMenu, currentDict, line)
                end
            end
        end
        builder.particlesSpawner.loadState = 2
        HUD.BUSYSPINNER_OFF()
    end
end
function _destroy_browse_menu(key)
    _destroy_recent_menus()
    show_busyspinner("Clearing browse menu... Lag may occur")
    util.create_thread(function()
        clear_menu_table(builder[key].menus)
    end)
    builder[key].loadState = 0
    builder[key].menus = {}
    clear_build_preview()
    save_recents()
    save_favorites_list()
    HUD.BUSYSPINNER_OFF()
end

-- [ RECENTS: SAVE/LOAD ]
local RECENTS_DIR = filesystem.store_dir() .. "jackz_vehicle_builder\\"
function save_recents()
    filesystem.mkdir(RECENTS_DIR)
    local file = io.open(RECENTS_DIR .. "props.txt", "w+")
    for id, count in pairs(builder.propSpawner.recents.items) do
        file:write(id .. " " .. count .. "\n")
    end
    file:close()

    file = io.open(RECENTS_DIR .. "vehicles.txt", "w+")
    for id, data in pairs(builder.vehSpawner.recents.items) do
        file:write(id .. "," .. (data.name or "") .. "," .. (data.dlc or "") .. "," .. data.count .. "\n")
    end
    file:close()

    file = io.open(RECENTS_DIR .. "peds.txt", "w+")
    for id, data in pairs(builder.pedSpawner.recents.items) do
        file:write(id .. "," .. data.name .. "," .. data.count .. "\n")
    end

    file = io.open(RECENTS_DIR .. "particles.txt", "w+")
    for id, data in pairs(builder.particlesSpawner.recents.items) do
        file:write(id .. "," .. data.name .. "," .. data.count .. "\n")
    end
    file:close()
end

function load_recents()
    if not filesystem.exists(RECENTS_DIR) then
        return
    end
    local file = io.open(RECENTS_DIR .. "props.txt", "r+")
    if file then
        for line in file:lines("l") do
            local id, count = line:match("(%g+) (%d+)")
            if id then
                builder.propSpawner.recents.items[id] = count
            end
        end
        file:close()
    end

    file = io.open(RECENTS_DIR .. "vehicles.txt", "r+")
    if file then
        for line in file:lines("l") do
            local id, name, dlc, count = line:match("(%g+),([%g%s]*),(%g*),(%d*)")
            if id then
                builder.vehSpawner.recents.items[id] = {
                    count = count,
                    name = name,
                    dlc = dlc or ""
                }
            end
        end
        file:close()
    end

    file = io.open(RECENTS_DIR .. "peds.txt", "r+")
    if file then
        for line in file:lines("l") do
            local id, name, count = line:match("(%g+),([%g%s]*),(%g*),")
            if id then
                builder.vehSpawner.recents.items[id] = {
                    count = count,
                    name = name
                }
            end
        end
        file:close()
    end

    file = io.open(RECENTS_DIR .. "particles.txt", "r+")
    if file then
        for line in file:lines("l") do
            local id, name, count = line:match("(%g+),([%g%s]*),(%g*),")
            if id then
                builder.particlesSpawner.recents.items[id] = {
                    count = count,
                    name = name
                }
            end
        end
        file:close()
    end
end

--[ PROP/VEHICLE MENU & PREVIEWS ]--
function add_prop_menu(parent, propName, isFavoritesEntry)
    local helper = isFavoritesEntry and ("Hold SHIFT when pressing to remove from favorites") or ("Hold SHIFT when pressing to add to favorites")
    local menuHandle
    menuHandle = menu.action(parent, propName, {}, helper, function()
        clear_build_preview()
        -- Increment recent usage
        if PAD.IS_CONTROL_PRESSED(2, 209) then
            if isFavoritesEntry then
                for i, entry in ipairs(FAVORITES.objects) do
                    if entry.prop == propName then
                        table.remove(FAVORITES.objects, i)
                    end
                end
                util.toast("Removed prop from your favorites")
                menu.delete(menuHandle)
            else
                table.insert(FAVORITES.objects, { prop = propName})
                util.toast("Added prop to your favorites")
            end
            return
        end
        if builder.propSpawner.recents.items[propName] ~= nil then
            builder.propSpawner.recents.items[propName] = builder.propSpawner.recents.items[propName] + 1
        else builder.propSpawner.recents.items[propName] = 0 end

        local hash = util.joaat(propName)
        local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
        local entity = entities.create_object(hash, pos)
        add_entity_to_list(builder.entitiesMenuList, entity, propName)
        highlightedHandle = entity
    end)
    menu.on_focus(menuHandle, function()
        if preview.id == nil or preview.id ~= propName then -- Focus seems to be re-called everytime an menu item is added
            clear_build_preview()
            local hash = util.joaat(propName)
            preview.id = propName
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
            if STREAMING.IS_MODEL_VALID(hash) then
                STREAMING.REQUEST_MODEL(hash)
                while not STREAMING.HAS_MODEL_LOADED(hash) do
                    util.yield()
                end
                if preview.id ~= propName then return end
                local entity = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, false, false, 0);
                if entity == 0 then
                    Log.log("Could not create preview for " .. propName .. "(" .. hash .. ")")
                    return
                end
                set_preview(entity, propName)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
            else
                Log.log("invalid model for preview. " .. propName, "add_prop_menu")
                util.toast("Cannot spawn preview: Invalid model")
            end
        end
    end)
    return menuHandle
end

function add_ped_menu(parent, pedName, displayName, isFavoritesEntry)
    local helper = isFavoritesEntry and ("Hold SHIFT when pressing to remove from favorites") or ("Hold SHIFT when pressing to add to favorites")
    local menuHandle
    menuHandle = menu.action(parent, displayName or pedName, {}, pedName .. "\n" .. helper, function()
        clear_build_preview()
        if PAD.IS_CONTROL_PRESSED(2, 209) then
            if isFavoritesEntry then
                for i, entry in ipairs(FAVORITES.peds) do
                    if entry.ped == pedName then
                        table.remove(FAVORITES.peds, i)
                    end
                end
                util.toast("Removed ped from your favorites")
                menu.delete(menuHandle)
            else
                table.insert(FAVORITES.peds, { ped = pedName, display = displayName })
                util.toast("Added ped to your favorites")
            end
            return
        end
        -- Increment recent usage
        if builder.pedSpawner.recents.items[pedName] ~= nil then
            builder.pedSpawner.recents.items[pedName].count = builder.pedSpawner.recents.items[pedName].count + 1
        else
            builder.pedSpawner.recents.items[pedName] = {
                name = displayName,
                count = 0
            }
        end

       

        local hash = util.joaat(pedName)
        local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
        local entity = entities.create_ped(0, hash, {x = 0, y = 0, z = 0}, 0)
        ENTITY.SET_ENTITY_COORDS(entity, pos.x, pos.y, pos.z)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        ENTITY.FREEZE_ENTITY_POSITION(entity)
        add_entity_to_list(builder.entitiesMenuList, entity, pedName)
        highlightedHandle = entity
    end)
    menu.on_focus(menuHandle, function()
        if preview.id == nil or preview.id ~= pedName then -- Focus seems to be re-called everytime an menu item is added
            clear_build_preview()
            local hash = util.joaat(pedName)
            if STREAMING.IS_MODEL_VALID(hash) then
                preview.id = pedName

                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
                STREAMING.REQUEST_MODEL(hash)
                while not STREAMING.HAS_MODEL_LOADED(hash) do
                    util.yield()
                end
                if preview.id ~= pedName then return end
                local entity = PED.CREATE_PED(0, hash, 0, 0, 0, 0, false, false);
                ENTITY.SET_ENTITY_COORDS(entity, pos.x, pos.y, pos.z)
                ENTITY.FREEZE_ENTITY_POSITION(entity)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
                if entity == 0 then
                    Log.log("Could not create preview for " .. pedName .. "(" .. hash .. ")")
                    return
                end
                set_preview(entity, pedName)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
            else
                Log.log("invalid model for preview. " .. pedName, "add_ped_menu")
                util.toast("Cannot spawn preview: Invalid model")
            end
        end
    end)
    return menuHandle
end

function add_vehicle_menu(parent, vehicleID, displayName, dlc, isFavoritesEntry)
    local helper = isFavoritesEntry and ("Hold SHIFT when pressing to remove from favorites") or ("Hold SHIFT when pressing to add to favorites")
    local menuHandle
    menuHandle = menu.action(parent, displayName, {}, (dlc and ("DLC: " .. dlc) or "") .. "\n" .. helper, function()
        clear_build_preview()
        if PAD.IS_CONTROL_PRESSED(2, 209) then
            if isFavoritesEntry then
                for i, entry in ipairs(FAVORITES.vehicles) do
                    if entry.vehicle == vehicleID then
                        table.remove(FAVORITES.vehicles, i)
                    end
                end
                menu.delete(menuHandle)
                util.toast("Removed vehicle from your favorites")
            else
                table.insert(FAVORITES.vehicles, { vehicle = vehicleID, display = displayName, dlc = dlc })
                util.toast("Added vehicle to your favorites")
            end
            return
        end
        -- Increment recent usage
        if builder.vehSpawner.recents.items[vehicleID] ~= nil then
            builder.vehSpawner.recents.items[vehicleID].count = builder.vehSpawner.recents.items[vehicleID].count + 1
        else
            builder.vehSpawner.recents.items[vehicleID] = {
                name = displayName,
                dlc = dlc,
                count = 0
            }
        end

        local hash = util.joaat(vehicleID)
        local entity = spawn_vehicle({model = hash}, false)
        add_entity_to_list(builder.entitiesMenuList, entity, displayName)
        highlightedHandle = entity
    end)
    menu.on_focus(menuHandle, function()
        if preview.id == nil or preview.id ~= vehicleID then -- Focus seems to be re-called everytime an menu item is added
            clear_build_preview()
            local hash = util.joaat(vehicleID)
            if STREAMING.IS_MODEL_VALID(hash) then
                preview.id = vehicleID
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
                STREAMING.REQUEST_MODEL(hash)
                while not STREAMING.HAS_MODEL_LOADED(hash) do
                    util.yield()
                end
                if preview.id ~= vehicleID then return end
                local entity = VEHICLE.CREATE_VEHICLE(hash, pos.x, pos.y, pos.z, 0, false, false)
                if entity == 0 then
                    return Log.log("Could not create preview for " .. vehicleID .. "(" .. hash .. ")")
                end
                set_preview(entity, vehicleID)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
            else
                Log.log("invalid model for preview. " .. vehicleID, "add_vehicle_menu")
                util.toast("Cannot spawn preview: Invalid model")
            end
        end
    end)
    return menuHandle
end
function add_particles_menu(parent, dict, name, isFavoritesEntry)
    local helper = isFavoritesEntry and ("Hold SHIFT when pressing to remove from favorites") or ("Hold SHIFT when pressing to add to favorites")
    local menuHandle
    local data = {
        particle = { dict, name },
        pos = { x = 0, y = 0, z = 0},
        rot = { x = 0, y = 0, z = 0}
    }
    menuHandle = menu.action(parent, name, {}, "Dictionary: " .. dict .. "\n" .. helper, function()
        clear_build_preview()
        if PAD.IS_CONTROL_PRESSED(2, 209) then
            if isFavoritesEntry then
                for i, entry in ipairs(FAVORITES.particlesFx) do
                    if entry.dict == dict and entry.name == name then
                        table.remove(FAVORITES.particlesFx, i)
                    end
                end
                menu.delete(menuHandle)
                util.toast("Removed particle from your favorites")
            else
                table.insert(FAVORITES.particlesFx, { dict = dict, display = name })
                util.toast("Added particle to your favorites")
            end
            return
        end
        -- Increment recent usage
        local key = dict .. "/" .. name
        if builder.particlesSpawner.recents.items[key] ~= nil then
            builder.particlesSpawner.recents.items[key].count = builder.particlesSpawner.recents.items[key].count + 1
        else
            builder.particlesSpawner.recents.items[key] = {
                name = name,
                dict = dict,
                count = 0
            }
        end

        local handle = spawn_particle(data, builder.base.handle)
        add_particle_to_list(builder.entitiesMenuList, handle, data)
    end)
    menu.on_focus(menuHandle, function()
        local key = dict .. "/" .. name
        if preview.id == nil or preview.id ~= key then -- Focus seems to be re-called everytime an menu item is added
            clear_build_preview()
            local handle = spawn_particle(data, builder.base.handle, true)
            set_particle_preview(handle, key)
        end
    end)
    return menuHandle
end
--[ Previewer Stuff ]--
function setup_entity_preview(entity)
    ENTITY.SET_ENTITY_ALPHA(entity, 150)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(entity, false, false)
    ENTITY.SET_ENTITY_INVINCIBLE(entity, true)
    ENTITY.SET_ENTITY_ALPHA(entity, 150)
    ENTITY.SET_ENTITY_HAS_GRAVITY(entity, false)
    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(entity)
        VEHICLE.SET_VEHICLE_GRAVITY(entity, false)
    end
end
function set_particle_preview(particleHandle, id)
    clear_build_preview()
    preview.entity = particleHandle
    preview.id = id
    preview.isParticle = true
    -- Don't create handler
end
function set_preview(entity, id, range, renderfunc, renderdata, rangeZ)
    clear_build_preview()
    preview.entity = entity
    preview.isParticle = false
    preview.id = id
    preview.range = range or nil
    preview.rangeZ = rangeZ or 0.3
    preview.rendercb = renderfunc
    preview.renderdata = renderdata
    create_preview_handler_if_not_exists()
    setup_entity_preview(entity)
end
-- Handle typically base vehicle
function _recurse_remove_attachments(handle, table)
    for _, entity in ipairs(table) do
        if entity ~= handle then
            -- Remove all second level attachments
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, handle) then
                for _, subEntity in ipairs(table) do
                    if subEntity ~= entity and subEntity ~= handle and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(subEntity, entity) then
                        entities.delete_by_handle(subEntity)
                    end
                end
                entities.delete_by_handle(entity)
            end
        end
    end
end
function remove_all_attachments(handle)
    Log.debug("removing attachments from " .. handle)
    _recurse_remove_attachments(handle, entities.get_all_objects_as_handles())
    _recurse_remove_attachments(handle, entities.get_all_vehicles_as_handles())
    _recurse_remove_attachments(handle, entities.get_all_peds_as_handles())
end
function clear_build_preview()
    local oldEntity = preview.entity
    preview.entity = 0
    preview.id = nil
    if preview.isParticle then
        Log.debug("removed particles fx")
        if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(oldEntity) then
            GRAPHICS.REMOVE_PARTICLE_FX(oldEntity, true)
        end
    elseif oldEntity ~= 0 and ENTITY.DOES_ENTITY_EXIST(oldEntity) then
        Log.debug("removed build preview")
        remove_all_attachments(oldEntity)
        entities.delete_by_handle(oldEntity)
    end
end

function _destroy_prop_previewer()
    show_busyspinner("Unloading prop previewer...")
    clear_menu_table(builder.propSpawner.menus)
    if preview.entity > 0 and ENTITY.DOES_ENTITY_EXIST(preview.entity) then
        Log.debug("removing prop previewer")
        entities.delete_by_handle(preview.entity)
        preview.entity = 0
        preview.id = nil
    end
    HUD.BUSYSPINNER_OFF()
    builder.ent_spawner_active = false
end

-- Gets entity player is look at.
--[[
-- distance: # of units infront of player to trace to
-- radius: The radius of the trace capsule
-- flags: The trace flags, default is for objects, vehicles and peds only
-- callback: Called with the result of trace (did_hit, entity, pos, surfaceNormal). All parameters can be nil if did_hit is false
-- 
-- Recommend radius of 10, any smaller and it starts to not be reliable
--]]
function get_entity_lookat(distance, radius, flags, callback)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(my_ped)
    local dest = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, distance, 1.0)
    local p_bool = memory.alloc(8)
    local p_endPos = memory.alloc(24)
    local p_surfaceNormal = memory.alloc(24)
    local p_entityHit = memory.alloc(8)
    if not flags then
        flags = 2 | 8 | 16
    end
    local handle = SHAPETEST.START_SHAPE_TEST_CAPSULE(pos.x, pos.y, pos.z, dest.x, dest.y, dest.z, radius, flags, my_ped, 7)
    util.create_thread(function()
        while SHAPETEST.GET_SHAPE_TEST_RESULT(handle, p_bool, p_endPos, p_surfaceNormal, p_entityHit) == 1 do
            util.yield()
        end
        local did_hit = memory.read_byte(p_bool)
        local entity = nil
        local endCoords = nil
        local surfaceNormal = nil
        if did_hit == 1 then
            entity = memory.read_int(p_entityHit)
            endCoords = memory.read_vector3(p_endPos)
            surfaceNormal = memory.read_vector3(p_surfaceNormal)
        end
        callback(did_hit, entity, endCoords, surfaceNormal)
    end)
end

-- [ ENTITY EDITING HANDLING ]
function add_particle_to_list(list, particleHandle, particleData)
    builder.entities[particleHandle] = {
        id = particleData.id or builder._index,
        name = particleData.name or particleData.particle[2],
        particle = particleData.particle,
        list = nil,
        listMenus = {},
        pos = particleData.offset or { x = 0.0, y = 0.0, z = 0.0 },
        rot = particleData.rotation or { x = 0.0, y = 0.0, z = 0.0 },
        boneIndex = particleData.boneIndex or 0,
        scale = particleData.scale or 1.0,
        color = particleData.color or nil,
        parent = particleData.parent
    }
    builder.entities[particleHandle].list = menu.list(
        list, builder.entities[particleHandle].name, {}, string.format("Edit this particle\nDictionary: %s\nName: %s", particleData.particle[1], particleData.particle[2]),
        function() create_entity_section(builder.entities[particleHandle], particleHandle, { type = "PARTICLE" }) end,
        function()
            isInEntityMenu = false
        end
    )
    menu.focus(builder.entities[particleHandle].list)
    return builder.entities[particleHandle]
end
function add_build_to_list(list, subbaseHandle, buildData, name)
    autosave(true)
    builder.entities[subbaseHandle] = {
        id = buildData.id or builder._index,
        name = name or ("Unknown build"),
        type = buildData.base.type,
        build = buildData,
        list = nil,
        listMenus = {},
        pos = buildData.offset or { x = 0.0, y = 0.0, z = 0.0 },
        rot = buildData.rotation or { x = 0.0, y = 0.0, z = 0.0 },
        boneIndex = buildData.boneIndex or 0,

    }
    if not buildData.id then
        builder._index = builder._index + 1
    end
    attach_entity(builder.base.handle, subbaseHandle, builder.entities[subbaseHandle].pos, builder.entities[subbaseHandle].rot, builder.entities[subbaseHandle].boneIndex)
    builder.entities[subbaseHandle].list = menu.list(
        list, builder.entities[subbaseHandle].name, {}, string.format("Edit nested build"),
        function() create_entity_section(builder.entities[subbaseHandle], subbaseHandle, { type = "BUILD" }) end,
        function()
            isInEntityMenu = false
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, false)
            ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
        end
    )
    menu.focus(builder.entities[subbaseHandle].list)
    return builder.entities[subbaseHandle]

end
function add_entity_to_list(list, handle, name, data)
    if not data then data = {} end
    if not list then
        return error("Missing menu handle", 2)
    elseif not handle then
        return error("Missing entity handle", 2)
    end
    autosave(true)
    -- ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, builder.base.handle)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(handle)
    ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(handle, false)
    local model = ENTITY.GET_ENTITY_MODEL(handle)
    local type = "OBJECT"
    if ENTITY.IS_ENTITY_A_VEHICLE(handle) then
        type = "VEHICLE"
    elseif ENTITY.IS_ENTITY_A_PED(handle) then
        type = "PED"
    end
    if data.visible == nil then data.visible = true end
    builder.entities[handle] = {
        id = data.id or builder._index,
        name = name or "(no name)",
        type = type,
        model = model,
        list = nil,
        listMenus = {},
        pos = data.offset or { x = 0.0, y = 0.0, z = 0.0 },
        rot = data.rotation or { x = 0.0, y = 0.0, z = 0.0 },
        boneIndex = data.boneIndex or 0,
        visible = data.visible,
        parent = data.parent,
        godmode = data.godmode or (type ~= "OBJECT") and true or nil
    }
    if not data.id then
        builder._index = builder._index + 1
    end
    local parent = get_entity_by_id(data.parent) or builder.base.handle
    attach_entity(parent, handle, builder.entities[handle].pos, builder.entities[handle].rot, builder.entities[handle].boneIndex)
    builder.entities[handle].list = menu.list(
        list, builder.entities[handle].name, {}, string.format("Edit entity #%d\nHash: %s\nModel Name: %s", handle, model, builder.entities[handle].name),
        function() create_entity_section(builder.entities[handle], handle) end,
        function()
            isInEntityMenu = false
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, false)
            ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
        end
    )
    menu.focus(builder.entities[handle].list)
    -- create_entity_section(builder.entities[handle], handle)
    return builder.entities[handle]
end

function clone_entity(handle, name, mirror_axis)
    local model = ENTITY.GET_ENTITY_MODEL(handle)
    local entity
    local pos
    if mirror_axis then
        if not builder.entities[handle] then
            Log.log("clone_entity with mirror_axis set on non-builder entity")
            return nil
        end
        pos = {
            x = builder.entities[handle].pos.x,
            y = builder.entities[handle].pos.y,
            z = builder.entities[handle].pos.z
        }
        if mirror_axis == 1 then
            pos.x = -pos.x
        elseif mirror_axis == 2 then
            pos.y = -pos.y
        elseif mirror_axis == 3 then
            pos.z = -pos.z
        end
    else
        pos = ENTITY.GET_ENTITY_COORDS(handle)
    end
    if ENTITY.IS_ENTITY_A_PED(handle) then
        entity = entities.create_ped(0, model, {x = 0, y = 0, z = 0}, 0)
        ENTITY.SET_ENTITY_COORDS(entity, pos.x, pos.y, pos.z)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        ENTITY.FREEZE_ENTITY_POSITION(entity)
    elseif ENTITY.IS_ENTITY_A_VEHICLE(handle) then
        entity = entities.create_vehicle(model, pos, 0)
    else
        entity = entities.create_object(model, pos)
    end
    add_entity_to_list(builder.entitiesMenuList, entity, name, { offset = pos })
    highlightedHandle = entity
    return entity
end

function create_entity_section(tableref, handle, options)
    if options == nil then options = {} end
    if not options.type then options.type = "ENTITY" end
    local entityroot = tableref.list
    if tableref.particle then
        if not GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(handle) then
            Log.warn(string.format("Particle %d (%s) vanished, deleting entity section", handle, tableref.name or "-unnamed-"), "create_entity_section")
            if entityroot then
                menu.delete(tableref.list)
            end
            builder.entities[handle] = nil
            return
        end
    elseif not ENTITY.DOES_ENTITY_EXIST(handle) then
        Log.warn(string.format("Entity %d (%s) vanished, deleting entity section", handle, tableref.name or "-unnamed-"), "create_entity_section")
        if entityroot then
            menu.delete(tableref.list)
        end
        builder.entities[handle] = nil
        return
    end

    local pos = tableref.pos
    local rot = tableref.rot
    highlightedHandle = handle
    isInEntityMenu = true

    local parent = get_entity_by_id(tableref.parent) or builder.base.handle
    
    --[ POSITION ]--
    clear_menu_table(tableref.listMenus)
    if handle ~= builder.base.handle then
        table.insert(tableref.listMenus, menu.divider(entityroot, "Position"))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Left / Right", {"pos" .. handle .. "x"}, "Set the X offset from the base entity", -1000000, 1000000, math.floor(pos.x * 100), POS_SENSITIVITY, function (x)
            pos.x = x / 100
            attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
        end))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Front / Back", {"pos" .. handle .. "y"}, "Set the Y offset from the base entity", -1000000, 1000000, math.floor(pos.y * 100), POS_SENSITIVITY, function (y)
            pos.y = y / 100
            attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
        end))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Up / Down", {"pos" .. handle .. "z"}, "Set the Z offset from the base entity", -1000000, 1000000, math.floor(pos.z * 100), POS_SENSITIVITY, function (z)
            pos.z = z / 100
            attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
        end))
    end

    --[ ROTATION ]--
    table.insert(tableref.listMenus, menu.divider(entityroot, "Rotation"))
    if not ENTITY.IS_ENTITY_A_PED(handle) then
        table.insert(tableref.listMenus, menu.slider(entityroot, "Pitch", {"rot" .. handle .. "x"}, "Set the X-axis rotation", -175, 180, math.floor(rot.x), ROT_SENSITIVITY, function (x)
            rot.x = x
            attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)

        end))
        table.insert(tableref.listMenus, menu.slider(entityroot, "Roll", {"rot" .. handle .. "y"}, "Set the Y-axis rotation", -175, 180, math.floor(rot.y), ROT_SENSITIVITY, function (y)
            rot.y = y
            attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
        end))
    end
    table.insert(tableref.listMenus, menu.slider(entityroot, "Yaw", {"rot" .. handle .. "z"}, "Set the Z-axis rotation", -175, 180, math.floor(rot.z), ROT_SENSITIVITY, function (z)
        rot.z = z
        attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
    end))

    --[ MISC ]--
    table.insert(tableref.listMenus, menu.divider(entityroot, "Misc"))
    if handle ~= builder.base.handle then
        -- Changing bone index requires recreating the particle entirely, so for now, don't support it.
        -- TODO: Support it
        if options.type ~= "PARTICLE" then
            table.insert(tableref.listMenus, menu.slider(entityroot, "Attachment Position", {"bone"..handle}, "Changes the bone index the entity is attached to. 0 for automatic, default.\50 is typically vehicle roof, normal index end around 100.", 0, 500, tableref.boneIndex, 1, function(index)
                tableref.boneIndex = index
                attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
            end))
        end
        if options.type == "ENTITY" or options.type == "PARTICLE" then
            local attachEntList
            local attachName = tableref.parent and ("#" .. tableref.parent) or "Base"
            attachEntList = menu.list(entityroot, "Attach to: " .. attachName, {"jvbattachto"..tableref.id}, "Attach to another build entity.",
                function() _load_attach_list(attachEntList, handle) end,
                _unload_attach_list
            )
            table.insert(tableref.listMenus, attachEntList)
        end
    end
    if not options.noRename then
        table.insert(tableref.listMenus, menu.text_input(entityroot, "Rename", {"renameent" .. handle}, "Changes the display name of this entity", function(name)
            menu.set_menu_name(tableref.list, name)
            tableref.name = name
        end, tableref.name))
    end
    if handle ~= builder.base.handle and options.type ~= "PARTICLE" then
        table.insert(tableref.listMenus, menu.toggle(entityroot, "Collision", {"collision" .. handle}, "Toggles if this entity will have collision, default is enabled", function(value)
            tableref.collision = value
            attach_entity(parent, handle, pos, rot, tableref.boneIndex, tableref.collision)
        end, tableref.collision))
    end
    if options.type == "ENTITY" then
        table.insert(tableref.listMenus, menu.toggle(entityroot, "Visible", {"visibility" .. handle}, "Toggles the visibility of this entity", function(value)
            tableref.visible = value
            ENTITY.SET_ENTITY_VISIBLE(handle, value, 0)
        end, tableref.visible))
        if ENTITY.IS_ENTITY_A_VEHICLE(handle) then
            table.insert(tableref.listMenus, menu.toggle(entityroot, "Godmode", {"buildergod" .. handle}, "Make the vehicle invincible", function(value)
                tableref.godmode = value
                ENTITY.SET_ENTITY_INVINCIBLE(handle, value and 255 or 0)
            end, tableref.godmode))
            table.insert(tableref.listMenus, menu.action(entityroot, "Enter Vehicle", {"builderenter" .. handle}, "Enter vehicle seat", function(value)
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, handle, -1)
            end))
        elseif ENTITY.IS_ENTITY_A_PED(handle) then
            table.insert(tableref.listMenus, menu.toggle(entityroot, "Godmode", {"buildergod" .. handle}, "Make the ped invincible", function(value)
                tableref.godmode = value
                ENTITY.SET_ENTITY_INVINCIBLE(handle, value and 255 or 0)
            end, tableref.godmode))
        end

        local cloneList = menu.list(entityroot, "Clone", {}, "Clone the entity")
        table.insert(tableref.listMenus, cloneList)
        menu.action(cloneList, "Clone In-place", {}, "Clones the entity where it is", function()
            clone_entity(handle, tableref.name, 0)
        end)
        menu.action(cloneList, "Mirror (X, Left/Right)", {}, "Clones the entity, mirrored on the x-axis", function()
            clone_entity(handle, tableref.name, 1)
        end)
        menu.action(cloneList, "Mirror (Y, Forward/Back)", {}, "Clones the entity, mirrored on the y-axis", function()
            clone_entity(handle, tableref.name, 2)
        end)
        menu.action(cloneList, "Mirror (Z, Up/Down)", {}, "Clones the entity, mirrored on the y-axis", function()
            clone_entity(handle, tableref.name, 3)
        end)
    elseif options.type == "PARTICLE" then
        table.insert(tableref.listMenus, menu.colour(entityroot, "Color", {"jv" .. handle .. "color"}, "Changes the color and transparency of a particle effect.\nNot all particles are supported", 1, 1, 1, 1, true, function(color)
            tableref.color = { r = color.r * 255, g = color.g * 255, b = color.b * 255, a = color.a * 255}
            GRAPHICS.SET_PARTICLE_FX_LOOPED_ALPHA(handle, tableref.color.a)
            GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(handle, tableref.color.r, tableref.color.g, tableref.color.b, 0)
        end))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Scale", {"jv" .. handle .. "scale"}, "Changes the scale of the particle fx.\nNot all particles are supported", 1, 10000, 100, 10, function(scale)
            tableref.scale = scale / 100
            GRAPHICS.SET_PARTICLE_FX_LOOPED_SCALE(handle, tableref.scale)
        end))
    end
    if handle ~= builder.base.handle then
        -- menu.action(entityroot, "Assign as base entity", {} , "Makes this entity the new base entity", function()
        --     set_builder_base(handle, true)
        --     util.toast("Set entity as build's new base")
        -- end)
        local deleteMenu
        deleteMenu = menu.action(entityroot, "Delete", {}, "Delete the entity", function()
            menu.show_warning(deleteMenu, CLICK_COMMAND, "Are you sure you want to delete this entity? This will also delete it from the world.", function() 
                if options.type == "ENTITY" then
                    if highlightedHandle == handle then
                        highlightedHandle = nil
                    end
                    if options.type == "BUILD" then
                        remove_all_attachments(handle)
                    end
                    for _, data in pairs(builder.entities) do
                        if data.parent == tableref.id then
                            util.toast("Parent was removed for entity #" .. data.id)
                            data.parent = nil
                        end
                    end
                end
                menu.delete(entityroot)
                -- Fix deleting not working
                if builder.entities[handle] then
                    builder.entities[handle] = nil
                end
                Log.debug("Deleting entity " .. handle)
                if tableref.particle then
                    GRAPHICS.REMOVE_PARTICLE_FX(handle, true)
                else
                 entities.delete_by_handle(handle)
                end
            end)
            
        end)
        table.insert(tableref.listMenus, deleteMenu)
    end
end

local attachEntSubmenus = {}

function _load_attach_list(list, child)
    -- Only show attach to base if it's NOT attached to the base
    if builder.entities[child].parent ~= nil then
        local base = menu.action(list, "Base", {}, "Restore entity parent's to the original base entity", function()
            builder.entities[child].parent = nil
            attach_entity(builder.base.handle, child, builder.entities[child].pos, builder.entities[child].rot, builder.entities[child].boneIndex, builder.entities[child].collision)
            util.toast("Entity's parent restored to base entity")
            menu.set_menu_name(list, "Attach to: Base")
            menu.focus(list)
        end)
        table.insert(attachEntSubmenus, base)
    end
    for handle, data in pairs(builder.entities) do
        -- Prevent listing recursive parents, or an already set parent
        if handle ~= child and handle ~= builder.base.handle and builder.entities[handle].parent ~= builder.entities[child].id and builder.entities[child].parent ~= data.id then
            table.insert(attachEntSubmenus, menu.action(list, data.name or ("Unnamed " .. data.type), {}, string.format("Handle: %s\nType: %s", handle, data.type), function()
                builder.entities[child].parent = builder.entities[handle].id
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, child)
                attach_entity(handle, child, builder.entities[child].pos, builder.entities[child].rot, builder.entities[child].boneIndex, builder.entities[child].collision)
                util.toast("Entity's parent changed")
                menu.set_menu_name(list, "Attach to: #" .. builder.entities[child].id)
                menu.focus(list)
            end))
        end
    end
end
function _unload_attach_list()
    clear_menu_array(attachEntSubmenus)
end

--[ Save Data ]
function save_vehicle(saveName, folder, is_autosave)
    if not folder then
        folder = SAVE_DIRECTORY
    end
    filesystem.mkdirs(folder)
    local data = builder_to_json(is_autosave)
    if data then
        local file = io.open(folder .. "/" .. saveName .. ".json", "w")
        if file then
            file:write(data)
            file:close()
            return true
        else
            return error("Could not create file ' " .. saveName .. ".json'")
        end
    else
        Log.log("Ignoring call to save, no data")
        return nil
    end

end
function upload_build(name, data)
    show_busyspinner("Uploading build...")
    async_http.init("jackz.me", 
        string.format("/stand/cloud/custom-vehicles.php?scname=%s&vehicle=%s&hashkey=%s&v=%s",
        SOCIALCLUB._SC_GET_NICKNAME(), name, menu.get_activation_key_hash(), VERSION
    ), function(body, res_headers, status_code)
        if status_code == 200 then
            if body:sub(1, 1) == "{" then
                local response = json.decode(body)
                if response.error then
                    Log.log(string.format("name:%s, name: %s failed to upload: %s", SOCIALCLUB._SC_GET_NICKNAME(), name, response.message))
                    util.toast("Upload error: " .. response.message)
                elseif response.status then
                    if response.status == "updated" then
                        util.toast("Successfully updated build")
                    else
                        util.toast("Successfully uploaded build")
                    end
                else
                    util.toast("Server sent invalid response")
                end
            else
                util.toast("Server sent invalid response")
            end
        else
            Log.log("bad server response : " .. status_code .. "\n" .. body, "_fetch_cloud_users")
            util.toast("Server returned error " .. status_code)
        end
        HUD.BUSYSPINNER_OFF()
    end, function()
        util.toast("Failed to upload your build (" .. name .. ")")
    end)
    async_http.set_post("application/json", data)
    async_http.dispatch()
end
function get_build_data_from_file(filepath)
    local file = io.open(filepath, "r")
    if file then
        local status, data = pcall(json.decode, file:read("*a"))
        if not status then
            Log.log("Skipping file \"" .. filepath .. "\" due to json errors: " .. data)
            return nil
        elseif data.Format then
            Log.log("Ignoring jackz_vehicles vehicle\"" .. filepath .. "\": Use jackz_vehicles to spawn", "load_build_from_file")
            return nil
        elseif not data.version then
            Log.log("Ignoring invalid build (no version meta) \"" .. filepath .. "\"", "load_build_from_file")
            return nil
        else
            if data.base.visible == nil then
                data.base.visible = true
            end
        end
        
        file:close()
        return data
    else
        error("Could not read file '" .. filepath .. "'")
    end
end

local lastAutosave = os.seconds()
function autosave(onDemand, name)
    if not scriptSettings.autosaveEnabled then return end
    if onDemand then
        if lastAutosave - os.seconds() < 5 then
            return
        end
        lastAutosave = os.seconds()
    end
    if not name then
        name = string.format("_autosave%d", autosaveIndex)
        autosaveIndex = autosaveIndex + 1
        if autosaveIndex > MAX_AUTOSAVES then
            autosaveIndex = 0
        end
    end
    local success = save_vehicle(name, AUTOSAVE_DIRECTORY)
    if success then
        Log.debug("Autosaved " .. name)
        util.draw_debug_text("Auto saved " .. name)
    else
        util.toast("Auto save (\"" .. name .. "\") has failed")
    end
    
    save_favorites_list()
    save_recents()
end

function _serialize_entity(handle, data)
    local serialized = {
        id = data.id,
        name = data.name,
        model = data.model,
        offset = data.pos,
        rotation = data.rot,
        visible = data.visible,
        boneIndex = data.boneIndex,
        parent = data.parent,
        collision = data.collision or true
    }
    if ENTITY.IS_ENTITY_A_VEHICLE(handle) then
        if data.godmode == nil then data.godmode = true end
        serialized.savedata = vehiclelib.Serialize(handle)
        serialized.godmode = data.godmode
    elseif ENTITY.IS_ENTITY_A_PED(handle) then
        serialized.animdata = data.animdata
        if data.godmode == nil then data.godmode = true end
        serialized.godmode = data.godmode
    end

    return serialized
end
function _serialize_build(build)
    return {
        id = build.id,
        name = build.name,
        offset = build.pos,
        rotation = build.rot,
        boneIndex = build.boneIndex,
        build = build.build
    }
end
function _serialize_particle(data)
    return {
        id = data.id,
        parent = data.parent,
        name = data.name,
        offset = data.pos,
        rotation = data.rot,
        boneIndex = data.boneIndex,
        particle = data.particle,
        scale = data.scale,
        color = data.color or {r = 0, g = 0, b = 0, a = 255 }
    }
end

function builder_to_json(is_autosave)
    local objects = {}
    local vehicles = {}
    local peds = {}
    local builds = {}
    local particles = {}
    local buildData
    for handle, data in pairs(builder.entities) do
        if data.build then
            table.insert(builds, _serialize_build(data))
        elseif data.particle then
            table.insert(particles, _serialize_particle(data))
        else
            local entityData = _serialize_entity(handle, data)
            if handle == builder.base.handle then
                entityData.offset = nil
                buildData = entityData
                buildData.type = data.type
                -- Move savedata out of 'base.data' to 'base'
                buildData.savedata = entityData.savedata
                entityData.savedata = nil
            elseif data.type == "VEHICLE" then
                table.insert(vehicles, entityData)
            elseif data.type == "PED" then
                table.insert(peds, entityData)
            else
                table.insert(objects, entityData)
            end
        end
    end

    local serialized = {
        name = builder.name,
        author = builder.author,
        created = os.unixseconds(),
        version = FORMAT_VERSION,
        base = {
            model = ENTITY.GET_ENTITY_MODEL(builder.base.handle),
            data = buildData,
            savedata = nil
        },
        blipIcon = builder.blip_icon,
        objects = objects,
        vehicles = vehicles,
        builds = builds,
        peds = peds,
        particles = particles,
        spawnLocation = builder.spawnLocation
    }

    -- Only calculate save data for vehicle-based custom builds
    if ENTITY.IS_ENTITY_A_VEHICLE(builder.base.handle) then
        serialized.base.savedata = vehiclelib.Serialize(builder.base.handle)
    end
    
    
    local status, result = pcall(json.encode, serialized)
    if not status then
        Log.log("Could not encode: (" .. result ..") " .. dump_table(serialized), "builder_to_json")
        if scriptSettings.autosaveEnabled then
            local recoveryFilename = string.format("recovered_%s.json",builder.name or "unnamed_build")
            copy_file(string.format("%s/_autosave%d.json", AUTOSAVE_DIRECTORY, autosaveIndex), string.format("%s/%s", AUTOSAVE_DIRECTORY, recoveryFilename))
            util.toast("WARNING: Could not save your build. Last autosave has automatically been saved as " .. recoveryFilename)
            Log.log("Recovery autosave: " .. recoveryFilename, "builder_to_json")
        end
        return nil
    else
        return result
    end
end

function copy_file(source, dest)
    local file = io.open(source, "r")
    if not file then
        return error("Could not open source", 2)
    end
    local destFile = io.open(dest, "w")
    if not destFile then
        return error("Could not create destination file", 2)
    end
    for line in file:lines("L") do
        destFile:write(line)
    end
    file:close()
    destFile:close()
end


function spawn_entity(data, type, isPreview, pos, heading)
    if not data.model then
        return error("No entity model provided")
    end

    local handle
    if type == "VEHICLE" then
        handle = spawn_vehicle(data, isPreview, pos, heading)
    elseif type == "PED" then
        handle = spawn_ped(data, isPreview, pos)
    elseif type == "OBJECT" then
        handle = spawn_object(data, isPreview, pos)
    else
        error("Invalid entity type \"" .. type .. "\"", 2)
    end
    Log.debug(string.format("spawned %s handle %d model %s", type, handle, data.model))
    return handle
end

function spawn_particle(data, entity, isPreview)
    if not data.particle or type(data.particle) ~= "table" or #data.particle < 2 then
        error("Particle key is missing or invalid")
    end
    if not data.scale then data.scale = 1 end

    local particle
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(data.particle[1]) do
        STREAMING.REQUEST_NAMED_PTFX_ASSET(data.particle[1])
        util.yield()
    end
    GRAPHICS.USE_PARTICLE_FX_ASSET(data.particle[1])
    if isPreview then
        -- Push off the ground
        data.pos.z = data.pos.z + 0.5
        if data.boneIndex then
            particle = GRAPHICS.START_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(data.particle[2], entity, data.pos.x, data.pos.y, data.pos.z, data.rot.x, data.rot.y, data.rot.z, data.boneIndex, data.scale, false, false, false)
        else
            particle = GRAPHICS.START_PARTICLE_FX_LOOPED_ON_ENTITY(data.particle[2], entity, data.pos.x, data.pos.y, data.pos.z, data.rot.x, data.rot.y, data.rot.z, data.scale, false, false, false)
        end
    elseif data.boneIndex then
        particle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(data.particle[2], entity, data.pos.x, data.pos.y, data.pos.z, data.rot.x, data.rot.y, data.rot.z, data.boneIndex, data.scale, false, false, false)
    else
        particle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(data.particle[2], entity, data.pos.x, data.pos.y, data.pos.z, data.rot.x, data.rot.y, data.rot.z, data.scale, false, false, false)
    end
    if data.scale then
        GRAPHICS.SET_PARTICLE_FX_LOOPED_SCALE(particle, data.scale)
    end
    if data.color then
        GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(particle, data.color.r, data.color.g, data.color.b, 0)
        GRAPHICS.SET_PARTICLE_FX_LOOPED_ALPHA(particle, data.color.a)
    end
    Log.debug(string.format("spawned particle fx (%s/%s) %d attached to %d", data.particle[1], data.particle[2], particle, entity))
    return particle
end

function spawn_vehicle(vehicleData, isPreview, pos, heading)
    if not STREAMING.IS_MODEL_VALID(vehicleData.model) then
        Log.log(string.format("invalid vehicle model (name:%s) (model:%s)", vehicleData.name, vehicleData.model))
        util.toast(string.format("Failing to spawn vehicle (%s) due to invalid model.", vehicleData.name or "<no name>"))
        return
    end
    STREAMING.REQUEST_MODEL(vehicleData.model)
    while not STREAMING.HAS_MODEL_LOADED(vehicleData.model) do
        util.yield()
    end
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    if not pos then
        pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, isPreview and 20.0 or 7.5, 1.0)
    end
    if not heading then
        heading = ENTITY.GET_ENTITY_HEADING(my_ped)
    end

    local handle
    if isPreview then
        handle = VEHICLE.CREATE_VEHICLE(vehicleData.model, pos.x, pos.y, pos.z, heading, false, false)
        setup_entity_preview(handle)
    else
        if vehicleData.visible == nil then
            vehicleData.visible = true
        end
        handle = entities.create_vehicle(vehicleData.model, pos, heading)
        ENTITY.SET_ENTITY_VISIBLE(handle, vehicleData.visible, 0)
        if vehicleData.godmode or vehicleData.godmode == nil then
            ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
        end
    end

    if vehicleData.savedata then
        vehiclelib.ApplyToVehicle(handle, vehicleData.savedata)
    end
    return handle, pos
end

function spawn_ped(data, isPreview, pos)
    if not STREAMING.IS_MODEL_VALID(data.model) then
        Log.log(string.format("invalid ped model (name:%s) (model:%s)", data.name or "<none>", data.model))
        util.toast(string.format("Failing to spawn ped (%s) due to invalid model.", data.name or "<no name>"))
        return
    end
    STREAMING.REQUEST_MODEL(data.model)
    while not STREAMING.HAS_MODEL_LOADED(data.model) do
        util.yield()
    end
    if not pos then pos = { x = 0, y = 0, z = 0} end
    local handle
    if isPreview then
        handle = PED.CREATE_PED(0, data.model, pos.x, pos.y, pos.z, 0, false, false)
        setup_entity_preview(handle)
    else
        handle = entities.create_ped(0, data.model, pos, 0)
    end
    if handle == 0 then
        util.toast("Ped failed to spawn: " .. (data.name or "<nil>") .. " model " .. data.model, TOAST_DEFAULT | TOAST_LOGGER)
        return nil
    else
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
        if data.visible == nil then
            data.visible = true
        end
        ENTITY.SET_ENTITY_VISIBLE(handle, data.visible, 0)
        if not data.godmode then
            data.godmode = true
        end
        ENTITY.SET_ENTITY_INVINCIBLE(handle, data.godmode)

        if data.animdata then
            if type(data.animdata) ~= "table" or #data.animdata < 2 then
                error("Ped animdata is invalid. Requires dictionary and animation set")
                return handle
            end
            STREAMING.REQUEST_ANIM_DICT(data.animdata[1])
            while not STREAMING.HAS_ANIM_DICT_LOADED(data.animdata[1]) do
                util.yield()
            end
            TASK.TASK_PLAY_ANIM(handle, data.animdata[1], data.animdata[2], 8.0, 8.0, -1, 1, 1.0, false, false, false)
        end
        return handle
    end
end

function spawn_object(data, isPreview, pos)
    if not STREAMING.IS_MODEL_VALID(data.model) then
        Log.log(string.format("invalid object model (name:%s) (model:%s)", data.name or "<none>", data.model))
        util.toast(string.format("Failing to spawn object (%s) due to invalid model.", data.name or "<no name>"))
        return
    end
    STREAMING.REQUEST_MODEL(data.model)
    while not STREAMING.HAS_MODEL_LOADED(data.model) do
        util.yield()
    end
    if not pos then pos = { x = 0, y = 0, z = 0} end
    local object
    if isPreview then
        object = OBJECT.CREATE_OBJECT(data.model, pos.x, pos.y, pos.z, false, false, 0)
        setup_entity_preview(object)
    else
        object = entities.create_object(data.model, pos)
    end
    if object == 0 then
        util.toast("Object failed to spawn: " .. (data.name or "<nil>") .. " model " .. data.model, TOAST_DEFAULT | TOAST_LOGGER)
        return nil
    else
        if data.visible == nil then
            data.visible = true
        end
        ENTITY.SET_ENTITY_VISIBLE(object, data.visible, 0)
        return object
    end
end

--[ Savedata Options ]--
function import_build_to_builder(build, name)
    -- Wipe old build:
    if builder then
        remove_all_attachments(builder.base.handle)
        if HUD.DOES_BLIP_EXIST(builder.blip) then
            util.remove_blip(builder.blip)
        end
    end

    clear_build_preview()
    if not build.base.data then build.base.data = {} end
    if not build.base.data.model then build.base.data.model = build.base.model end
    local baseHandle = spawn_entity(build.base.data, build.base.data.type or "VEHICLE")
    if baseHandle then
        builder = new_builder()
        builder.name = name
        builder.author = build.author
        builder.base.data = build.base.data
        builder.blip_icon = build.blipIcon or build.blip_icon
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
        set_builder_base(baseHandle)
        setup_builder_menus(name)
        add_attachments(baseHandle, build, true, false)
        return true
    else
        Log.log("Base entity failed to spawn. Name: " .. name .. " Model: " .. build.base.model, "import_build_to_builder")
        return false
    end
end

function calculate_model_size(model, minVec, maxVec)
    MISC.GET_MODEL_DIMENSIONS(model, minVec, maxVec)
    return (maxVec:getX() - minVec:getX()), (maxVec:getY() - minVec:getY()), (maxVec:getZ() - minVec:getZ())
end

function _compute_build_size(build)
    local r_size = 0.0
    local h_size = 0.0
    local minVec = v3.new()
    local maxVec = v3.new()
    function _compute_size(entity)
        local l, w, h = calculate_model_size(entity.model, minVec, maxVec)
        l = l + entity.offset.x
        w = w + entity.offset.y
        if entity.offset.z < 0 then
            h = h + math.abs(entity.offset.z)
        else
            h = 0
        end

        if l > r_size then
            r_size = l
        end
        if w > h_size then
            r_size = w
        end
        if h > h_size then
            h_size = h
        end
    end
    if build.vehicles then
        for _, entity in ipairs(build.vehicles) do
            _compute_size(entity)
        end
    end
    if build.peds then
        for _, entity in ipairs(build.peds) do
            _compute_size(entity)

        end
    end
    if build.objects then
        for _, entity in ipairs(build.objects) do
            _compute_size(entity)
        end
    end
    return (r_size + 7.5), h_size
end

-- Spawns a custom build, requires build.base to be set, others optional
function spawn_build(build, isPreview, previewFunc, previewData)
    if not build then
        error("No build data provided", 2)
    elseif not build.base then
        error("No base entity data provided", 2)
    end
    clear_build_preview()
    if not build.base.data then build.base.data = {} end
    if not build.base.data.model then
        build.base.data.model = build.base.model
    end

    local wSize, hSize = _compute_build_size(build)
    local pos
    if build.spawnLocation then
        pos = build.spawnLocation
    else
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, wSize, 0)
    end

    -- Pass save data to spawn_entity -> spawn_vehicle
    build.base.data.savedata = build.base.savedata
    local baseType = build.base.data.type or "VEHICLE"
    local baseHandle = spawn_entity(build.base.data, baseType, isPreview, pos)
    if baseHandle then
        Log.log("spawned base " .. baseHandle .. " preview: " .. (isPreview and "yes" or "no"))
        if isPreview then
            set_preview(baseHandle, "_base", wSize, previewFunc, previewData, hSize)
        else
            create_blip_for_entity(baseHandle, build.blip_icon, build.name or "Unnamed Build")
        end
        if build.base.visible == false or (build.base.data and build.base.data.visible == false) then
            ENTITY.SET_ENTITY_VISIBLE(baseHandle, false, 0)
        else
            ENTITY.SET_ENTITY_VISIBLE(baseHandle, true, 0)
        end
        ENTITY.SET_ENTITY_INVINCIBLE(baseHandle, true)
        local attachments = add_attachments(baseHandle, build, false, isPreview)
        return baseHandle, attachments
    else
        util.toast("Could not spawn build's base entity")
    end
end

-- This code is awfully made and a bad copy paste... but oh well
-- Also addToBuilder and isPreview shouldn't be both true
function add_attachments(baseHandle, build, addToBuilder, isPreview)
    local handles = {
        baseHandle
    }
    local idMap = {} -- KV<id, handle>
    local parentQueue = {} -- Any entities who need to be parented
    if build.objects then
        for _, entityData in ipairs(build.objects) do
            local name = entityData.name or "<nil>"
            if not STREAMING.IS_MODEL_VALID(entityData.model) then
                util.toast("Object has invalid model: " .. name .. " model " .. entityData.model, TOAST_DEFAULT | TOAST_LOGGER)
            else
                local object = spawn_object(entityData, isPreview)
                if object then
                    ENTITY.SET_ENTITY_VISIBLE(object, entityData.visible, 0)
                    for _, handle2 in ipairs(handles) do
                        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(object, handle2)
                    end
                    table.insert(handles, object)

                    if entityData.id then idMap[tostring(entityData.id)] = object end

                    if addToBuilder then
                        add_entity_to_list(builder.entitiesMenuList, object, entityData.name or "unknown object", entityData)
                    elseif entityData.parent then
                        if entityData.parent ~= entityData.id then
                            table.insert(parentQueue, { handle = object, data = entityData })
                        else
                            util.toast("Object parented to itself: #" .. entityData.id .. ". See logs for details")
                            Log.log(string.format("Object %d ID#%d parented to self. Name: %s, Model: %s", object, entityData.id, entityData.name or "-none-", entityData.model))
                        end
                    else
                        attach_entity(baseHandle, object, entityData.offset, entityData.rotation, entityData.boneIndex, entityData.collision)
                    end
                end
            end
        end
    end
    if build.peds then
        for _, pedData in ipairs(build.peds) do
            local name = pedData.name or "<nil>"
            if not STREAMING.IS_MODEL_VALID(pedData.model) then
                util.toast("Ped has invalid model: " .. name .. " model " .. pedData.model, TOAST_DEFAULT | TOAST_LOGGER)
            else
                local ped = spawn_ped(pedData, isPreview)
                if ped then
                    for _, handle2 in ipairs(handles) do
                        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(ped, handle2)
                    end
                    table.insert(handles, ped)

                    if pedData.id then idMap[tostring(pedData.id)] = ped end

                    if addToBuilder then
                        local datatable = add_entity_to_list(builder.entitiesMenuList, ped, pedData.name or "unknown ped", pedData)
                        datatable.animdata = pedData.animdata
                    elseif pedData.parent then
                        if pedData.parent ~= pedData.id then
                            table.insert(parentQueue, { handle = ped, data = pedData })
                        else
                            util.toast("Ped parented to itself: #" .. pedData.id .. ". See logs for details")
                            Log.log(string.format("Ped %d ID#%d parented to self. Name: %s, Model: %s", ped, pedData.id, pedData.name or "-none-", pedData.model))
                        end
                    else
                        attach_entity(baseHandle, ped, pedData.offset, pedData.rotation, pedData.boneIndex, pedData.collision)
                    end
                end
            end
        end
    end

    if not pedAnimThread then
        pedAnimThread = util.create_thread(function()
            while #pedAnimCache > 0 do
                for _, entry in ipairs(pedAnimCache) do
                    if not ENTITY.IS_ENTITY_PLAYING_ANIM(entry.handle, entry.animdata[1], entry.animdata[2], 3) then
                        TASK.TASK_PLAY_ANIM(entry.handle, entry.animdata[1], entry.animdata[2], 8.0, 8.0, -1, 1, 1.0, false, false, false)
                    end
                    if builder and builder.entities[entry.handle] then
                        attach_entity(builder.base.handle, entry.handle, builder.entities[entry.handle].pos, builder.entities[entry.handle].rot, builder.entities[entry.handle].boneIndex)
                    end
                end
                util.yield(4000)
            end
        end)
    end

    if build.vehicles then
        for _, vehData in ipairs(build.vehicles) do
            local handle = spawn_vehicle(vehData, isPreview)
            ENTITY.SET_ENTITY_VISIBLE(handle, vehData.visible, 0)
            if not vehData.godmode then
                vehData.godmode = true
            end
            ENTITY.SET_ENTITY_INVINCIBLE(handle, vehData.godmode)
            for _, handle2 in ipairs(handles) do
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, handle2)
            end
            ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
            table.insert(handles, handle)

            if vehData.id then idMap[tostring(vehData.id)] = handle end

            if addToBuilder then
                add_entity_to_list(builder.entitiesMenuList, handle, vehData.name or "unknown vehicle", vehData)
            elseif vehData.parent then
                if vehData.parent ~= vehData.id then
                    table.insert(parentQueue, { handle = handle, data = vehData })
                else
                    util.toast("Vehicle parented to itself: #" .. vehData.id .. ". See logs for details")
                    Log.log(string.format("Vehicle %d ID#%d parented to self. Name: %s, Model: %s", handle, vehData.id, vehData.name or "-none-", vehData.model))
                end
                table.insert(parentQueue, { handle = handle, data = vehData })
            else
                attach_entity(baseHandle, handle, vehData.offset, vehData.rotation, vehData.boneIndex, vehData.collision)
            end
        end
    end

    if build.builds then
        for _, entry in ipairs(build.builds) do
            local handle, attachments = spawn_build(entry.build, isPreview)
            for _, attachment in ipairs(attachments) do
                for _, handle2 in ipairs(handles) do
                    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(attachment, handle2)
                end
            end
            if entry.id then idMap[tostring(entry.id)] = handle end

            if addToBuilder then
                add_build_to_list(builder.entitiesMenuList, handle, entry, entry.name)
            else
                attach_entity(baseHandle, handle, entry.offset, entry.rotation, entry.boneIndex, entry.collision)
            end
        end
    end

    -- Process parenting, ensuring they are spawned in
    for _, entry in ipairs(parentQueue) do
        local targetHandle = idMap[tostring(entry.data.parent)]
        if not targetHandle then
            Log.log("Invalid parent handle: " .. entry.data.parent .. " for id " .. entry.id, "add_attachments")
        else
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(entry.handle, targetHandle)
            attach_entity(targetHandle, entry.handle, entry.data.offset, entry.data.rotation, entry.data.boneIndex)
        end
    end

    for _, particle in ipairs(build.particles) do
        local entity = builder.base.handle
        if particle.parent then
            entity = idMap[particle.parent]
        end

        local handle = spawn_particle(particle, entity, isPreview)
        if addToBuilder then
           add_particle_to_list(builder.entitiesMenuList, handle, particle) 
        end
    end

    return handles
end

function dump_table(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump_table(v) .. ','
       end
       return s .. '} '
    elseif type(o) == "string" then
        return '"' .. o .. "'"
    else
       return tostring(o)
    end
end

function get_entity_by_id(id)
    if not id or not builder then return nil end
    for handle, data in pairs(builder.entities) do
        if data.id == id then
            return handle, data
        end
    end
    return nil
end

function attach_entity(parent, handle, offset, rot, index, collision)
    if offset == nil or rot == nil then
        Log.log("null offset or rot" .. debug.traceback(), "attach_entity")
        return
    end
    if parent == handle then
        ENTITY.SET_ENTITY_ROTATION(handle, rot.x or 0, rot.y or 0, rot.z or 0)
    elseif GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(handle) then
        GRAPHICS.SET_PARTICLE_FX_LOOPED_OFFSETS(handle,
            offset.x or 0, offset.y or 0, offset.z or 0,
            rot.x or 0, rot.y or 0, rot.z or 0
        )
    else
        if collision == nil then
            collision = true
        end
        ENTITY.ATTACH_ENTITY_TO_ENTITY(handle, parent, index or 0,
            offset.x or 0, offset.y or 0, offset.z or 0,
            rot.x or 0, rot.y or 0, rot.z or 0,
            false, false, collision, false, 2, true
        )
    end

end
-- Modified from https://forum.cfx.re/t/how-to-supas-helper-scripts/41100
function highlight_object_at_pos(pos, size, color)
    if not size then size = 0.01 end
    if not color then color = { r = 255, g = 0, b = 0, a = 200 } end
    GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
    GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("helicopterhud", false)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -size, -size, 0.006, 0.006, 0.0, color.r, color.g, color.b, color.a)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", size, -size, 0.006, 0.006, 90.0, color.r, color.g, color.b, color.a)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -size, size, 0.006, 0.006, 270.0, color.r, color.g, color.b, color.a)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", size, size, 0.006, 0.006, 180.0, color.r, color.g, color.b, color.a)
    GRAPHICS.CLEAR_DRAW_ORIGIN()
end
function show_marker_at_pos(pos, ang, markerType)
    if ang == nil then ang = {} end
    GRAPHICS.DRAW_MARKER(markerType or 0, pos.x, pos.y, pos.z + 4.0, 0.0, 0.0, 0.0, ang.x or 0, ang.y or 0, ang.z or 0, 1, 1, 1, 255, 255, 255, 100, false, true, 2, false, 0, 0, false)
end
menu.divider(menu.my_root(), "Setup new build")
setup_pre_menu()

util.on_stop(function()
    scriptEnding = true
    if builder and builder.blip and HUD.DOES_BLIP_EXIST(builder.blip) then
        util.remove_blip(builder.blip)
    end
    clear_build_preview()
end)

function compute_builder_stats()
    local peds = 0
    local objects = 0
    local vehicles = 0
    for handle, data in pairs(builder.entities) do
        if handle ~= builder.base.handle then
            if data.type == "PED" then
                peds = peds + 1
            elseif data.type == "VEHICLE" then
                vehicles = vehicles + 1
            else
                objects = objects + 1
            end
        end
    end
    return vehicles, objects, peds
end

--[[
local hudbox = {}

function set_origin(x, y, padding)
    hudbox = {
        origin = { x = x, y = y },
        offset = { x = 0, y = 0 },
        padding = padding or 0.1,
        width = 0.0,
        height = 0.0
    }
end
function add_text(content, size, color, align)
    local w, h = directx.get_text_size(content, size)
    hudbox.offset.y = hudbox.offset.y + h
    if w > hudbox.width then
        hudbox.width = w + hudbox.padding
    end
    if h > hudbox.height then
        hudbox.height = h + hudbox.padding
    end
    directx.draw_text(hudbox.origin.x + hudbox.offset.x, hudbox.origin.y + hudbox.offset.y , content, align or ALIGN_TOP_LEFT, size, color or { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
end

function add_vertical_space(height)
    hudbox.offset.y = hudbox.offset.y + height
end

function draw_background(min_width, min_height, color)
    local width = hudbox.width
    local height = hudbox.height
    if min_width and width < min_width then width = min_width end
    if min_height and height < min_height then height = min_height end
    directx.draw_rect(hudbox.origin.x - 0.01, hudbox.origin.y, width, height, color or { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
end

set_origin(hudPos.x, hudPos.y)
add_text(builder.name or "Unnamed Build", 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
add_text(authorText, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
add_vertical_space(0.01)
add_text(string.format("%d vehicles, %d objects, %d peds attached", vehicleCount, objectCount, pedCount), 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
draw_background()
]]--

function get_screen_coords(worldPos)
    GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(worldPos.x, worldPos.y, worldPos.z, hud_coords.x, hud_coords.y, hud_coords.z)
    local hudPos = {}
    for k in pairs(hud_coords) do
        hudPos[k] = memory.read_float(hud_coords[k])
    end
    return hudPos
end

local lastAddKeyPress = 0
while true do
    local seconds = os.seconds()
    if builder ~= nil then
        if menu.is_open() and editorActive then
            if scriptSettings.autosaveEnabled and seconds >= autosaveNextTime then
                autosaveNextTime = seconds + AUTOSAVE_INTERVAL_SEC
                autosave()
            end
            if scriptSettings.showAddOverlay then
                get_entity_lookat(40.0, 5.0, nil, function(did_hit, entity, pos)
                    if did_hit and entity and builder.entities[entity] == nil and NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(entity) then
                        local hudPos = get_screen_coords(pos)
                        local height = 0.055
                        local name = "Pre-existing object"
                        if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
                            local hash = ENTITY.GET_ENTITY_MODEL(entity)
                            local manufacturer = VEHICLE._GET_MAKE_NAME_FROM_VEHICLE_MODEL(hash)
                            local vehName = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
                            name = manufacturer .. " " .. vehName
                        elseif ENTITY.IS_ENTITY_A_PED(entity) then
                            name = "Pre-existing ped"
                        end
                        directx.draw_rect(hudPos.x, hudPos.y, 0.2, height, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
                        directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, name, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                        directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, "Press 'J' to add to build", ALIGN_TOP_LEFT, 0.5, { r = 0.8, g = 0.8, b = 0.8, a = 0.8})
                        
                        if util.is_key_down(0x4A) then
                            if seconds - lastAddKeyPress > 1 then
                                lastAddKeyPress = seconds
                                add_entity_to_list(builder.entitiesMenuList, entity, name)
                            end
                        end
                    end
                end)
            end
        end
        if editorActive and highlightedHandle ~= nil and builder.entities[highlightedHandle] then
            local pos
            if builder.entities[highlightedHandle] and builder.entities[highlightedHandle].particle then
                local parent = get_entity_by_id(builder.entities[highlightedHandle].parent) or builder.base.handle
                pos = ENTITY.GET_ENTITY_COORDS(parent)
                pos.x = pos.x + builder.entities[highlightedHandle].pos.x
                pos.y = pos.y + builder.entities[highlightedHandle].pos.y
                pos.z = pos.z + builder.entities[highlightedHandle].pos.z
            else
                pos = ENTITY.GET_ENTITY_COORDS(highlightedHandle)
            end
            if scriptSettings.showOverlay and menu.is_open() or FREE_EDIT then
                local entData = builder.entities[highlightedHandle]
                local hudPos = get_screen_coords(pos)
                local isParticle = entData.particle ~= nil
                local height = 0.1
                if isParticle then height = height + 0.03 end
                directx.draw_rect(hudPos.x, hudPos.y, 0.2, height, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})


                if builder.base.handle == highlightedHandle then
                    local vehicleCount, objectCount, pedCount = compute_builder_stats()
                    local authorText = builder.author and ("Created by " .. builder.author) or "Unknown creator"
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, builder.name or "Unnamed Build", ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, string.format("%d vehicles, %d objects, %d peds attached", vehicleCount, objectCount, pedCount), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                elseif entData.build then
                    local authorText = entData.build.author and ("Created by " .. entData.build.author) or "Unknown creator"
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, entData.build.name or "Unnamed Build", ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                elseif isParticle then
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, (entData.name or "Unnamed particle"), ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, entData.particle[1] .. " " .. entData.particle[2], ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, string.format("Offset   %6.1f  %6.1f  %6.1f", entData.pos.x, entData.pos.y, entData.pos.z), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.075, string.format("Angles  %6.1f  %6.1f  %6.1f", entData.rot.x, entData.rot.y, entData.rot.z), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                    if entData.color then
                        directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.09, string.format("Color   %6.0f  %6.0f  %6.0f  %6.0f", entData.color.r, entData.color.g, entData.color.b, entData.color.a), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                    end
                    if entData.scale then
                        directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.105, string.format("Scale  %6.1f", entData.scale), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                    end
                else
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, (entData.name or "Unnamed entity") .. " (" .. entData.model .. ")", ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, entData.type, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, string.format("Offset   %6.1f  %6.1f  %6.1f", entData.pos.x, entData.pos.y, entData.pos.z), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.075, string.format("Angles  %6.1f  %6.1f  %6.1f", entData.rot.x, entData.rot.y, entData.rot.z), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                end
            end

            highlight_object_at_pos(pos)
            show_marker_at_pos(pos, nil, 0)
            local pos = builder.entities[highlightedHandle].pos
            local rot = builder.entities[highlightedHandle].rot
            if FREE_EDIT and (not isInEntityMenu or not menu.is_open()) then
                local posSensitivity = POS_SENSITIVITY / 100
                local update = false
                -- POS
                if PAD.IS_CONTROL_PRESSED(2, 32) then --W
                    pos.y = pos.y + posSensitivity
                    update = true
                elseif PAD.IS_CONTROL_PRESSED(2, 33) then --S
                    pos.y = pos.y - posSensitivity
                    update = true
                end
                if PAD.IS_CONTROL_PRESSED(2, 34) then --A
                    pos.x = pos.x - posSensitivity
                    update = true
                elseif PAD.IS_CONTROL_PRESSED(2, 35) then --D
                    pos.x = pos.x + posSensitivity
                    update = true
                end
                if PAD.IS_CONTROL_PRESSED(2, 61) and not PAD.IS_CONTROL_PRESSED(2, 111) then --SHIFT
                    pos.z = pos.z + posSensitivity
                    update = true
                elseif PAD.IS_CONTROL_PRESSED(2, 62) and not PAD.IS_CONTROL_PRESSED(2, 112)  then--CTRL
                    pos.z = pos.z - posSensitivity
                    update = true
                end
                -- ROT
                if PAD.IS_CONTROL_PRESSED(2, 111) then --NUM 8
                    rot.y = rot.y - ROT_SENSITIVITY
                    update = true
                elseif PAD.IS_CONTROL_PRESSED(2, 112) then --NUM 5
                    rot.y = rot.y + ROT_SENSITIVITY
                    update = true
                end
                if PAD.IS_CONTROL_PRESSED(2, 108) then --NUM 4
                    rot.x = rot.x + ROT_SENSITIVITY
                    update = true
                elseif PAD.IS_CONTROL_PRESSED(2, 109) then -- NUM 6
                    rot.x = rot.x - ROT_SENSITIVITY
                    update = true
                end
                if PAD.IS_CONTROL_PRESSED(2, 117) then --NUM 7
                    rot.z = rot.z - ROT_SENSITIVITY
                    update = true
                elseif PAD.IS_CONTROL_PRESSED(2, 119) then --NUM 9
                    rot.z = rot.z + ROT_SENSITIVITY
                    update = true
                end

                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                if not update then
                    ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, false)
                    ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
                end
                if update then
                    ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, true)
                    ENTITY.FREEZE_ENTITY_POSITION(my_ped, true)
                    local parent = get_entity_by_id(builder.entities[highlightedHandle].parent) or builder.base.handle
                    attach_entity(parent, highlightedHandle, pos, rot, builder.entities[highlightedHandle].boneIndex)
                end
            end
        end
    end

    util.yield()
end
