-- Jackz Vehicles
-- Created By Jackz
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "jackz_vehicles"
VERSION = "3.10.3"
local LANG_TARGET_VERSION = "1.4.0" -- Target version of translations.lua lib
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
    menu.divider(SCRIPT_META_LIST, "hiers - Translator")
    menu.divider(SCRIPT_META_LIST, "voyager - Translator")
    menu.divider(SCRIPT_META_LIST, "Icedoomfist - Translator")
end


local json = require("json")
local i18n = require("translations")
local vehiclelib = require("jackzvehiclelib")

if vehiclelib == nil then
    util.toast("["..SCRIPT.."] " .. "CRITICAL: Library 'jackzvehiclelib' was not loaded, cannot continue. Exiting.", TOAST_ALL)
    util.stop_script()
    return
elseif vehiclelib == true then
    util.toast("Fatal error: Failed to download 'jackzvehiclelib' and file is corrupted. Please reinstall library and report this issue")
    util.stop_script()
elseif i18n == nil then
    util.toast("["..SCRIPT.."] " .. "CRITICAL: Library 'translations' was not loaded, cannot continue. Exiting.", TOAST_ALL)
    util.stop_script()
    return
end
if vehiclelib.LIB_VERSION ~= VEHICLELIB_TARGET_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
        util.log("jackzvehiclelib current: " .. vehiclelib.LIB_VERSION, ", target version: " .. VEHICLELIB_TARGET_VERSION)
        util.toast("Outdated vehiclelib library, downloading update...")
        download_lib_update("jackzvehiclelib.lua")
        vehiclelib = require("jackzvehiclelib")
    else
        util.toast("Outdated lib: 'jackzvehiclelib'")
    end
end
if i18n.VERSION ~= LANG_TARGET_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
        util.toast("Outdated translations library, attempting update...")
        package.loaded["translations"] = nil
        _G["translations"] = nil
        download_lib_update("translations.lua")
        lang = require("translations")
    end
end
i18n.set_autodownload_uri("jackz.me", "/stand/translations/")
i18n.load_translation_file(SCRIPT)

-- CONSTANTS
local DOOR_NAMES = table.freeze({
    "Front Left", "Front Right",
    "Back Left", "Back Right",
    "Engine", "Trunk",
    "Back", "Back 2",
})
local NEON_INDICES = table.freeze({ "Left", "Right", "Front", "Back"})
local MAX_WINDOW_TINTS = 6
local MAX_WHEEL_TYPES = 11

local VEHICLE_DIR = filesystem.stand_dir() .. "Vehicles" .. package.config:sub(1,1)
if not filesystem.exists(VEHICLE_DIR) then
    filesystem.mkdir(VEHICLE_DIR)
end

-- UTIL FUNCTIONS
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
-- Gets the player's vehicle, attempts to request control. Returns 0 if unable to get control
function get_player_vehicle_in_control(pid, opts)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()) -- Needed to turn off spectating while getting control
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)

    -- Calculate how far away from target
    local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped)
    local pos2 = ENTITY.GET_ENTITY_COORDS(my_ped)
    local dist = SYSTEM.VDIST2(pos1.x, pos1.y, 0, pos2.x, pos2.y, 0)

    local was_spectating = NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() -- Needed to toggle it back on if currently spectating
    -- If they out of range (value may need tweaking), auto spectate.
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
    if opts and opts.near_only and vehicle == 0 then
        return 0
    end
    if vehicle == 0 and target_ped ~= my_ped and dist > 340000 and not was_spectating then
        i18n.toast("AUTO_SPECTATE")
        show_busyspinner(i18n.format("AUTO_SPECTATE"))
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
        -- To prevent a hard 3s loop, we keep waiting upto 3s or until vehicle is acquired
        local loop = (opts and opts.loops ~= nil) and opts.loops or 30 -- 3000 / 100
        while vehicle == 0 and loop > 0 do
            util.yield(100)
            vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
            loop = loop - 1
        end
        HUD.BUSYSPINNER_OFF()
    end

    if vehicle > 0 then
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            return vehicle
        end
        -- Loop until we get control
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
        local has_control_ent = false
        local loops = 15
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)

        -- Attempts 15 times, with 8ms per attempt
        while not has_control_ent do
            has_control_ent = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            loops = loops - 1
            -- wait for control
            util.yield(15)
            if loops <= 0 then
                break
            end
        end
    end
    if not was_spectating then
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(false, target_ped)
    end
    return vehicle
end
-- Helper functions
function control_vehicle(pid, callback, opts)
    local vehicle = get_player_vehicle_in_control(pid, opts)
    if vehicle > 0 then
        callback(vehicle)
    elseif opts == nil or opts.silent ~= true then
        i18n.toast("PLAYER_OUT_OF_RANGE")
    end
end

function get_waypoint_pos(callback, silent)
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
        if callback then
            callback(waypoint_pos)
        end
        return waypoint_pos
    elseif not silent then
        i18n.toast("NO_WAYPOINT_SET")
        return nil
    end
end

function load_hash(hash)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        util.yield()
    end
end
-- Vehicle spawn functions
local CAB_MODEL = util.joaat("phantom")
local TRAILER_MODEL = util.joaat("tr2")
function spawn_cab_and_trailer_for_vehicle(vehicle, rampDown)
    load_hash(CAB_MODEL)
    load_hash(TRAILER_MODEL)
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    local cabPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -5.0, 10, 0.0)
    local trailerPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -5.0, 0, 0.0)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)

    local cab = entities.create_vehicle(CAB_MODEL, cabPos, heading)
    local trailer = entities.create_vehicle(TRAILER_MODEL, trailerPos, heading)
    add_vehicle_to_list(cab)
    add_vehicle_to_list(trailer)
    if rampDown then
        VEHICLE.SET_VEHICLE_DOOR_OPEN(trailer, 5, 0, 0)
    end
    VEHICLE.ATTACH_VEHICLE_TO_TRAILER(cab, trailer, 5)
    VEHICLE.ATTACH_VEHICLE_ON_TO_TRAILER(vehicle, trailer, 0, 0, -2.0, 0, 0, 0.0, 0, 0, 0, 0.0)
    ENTITY.DETACH_ENTITY(vehicle)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(cab, true)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(CAB_MODEL)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(TRAILER_MODEL)
    return cab, driver
end

local CARGOBOB_MODEL = util.joaat("cargobob")
function spawn_cargobob_for_vehicle(vehicle, useMagnet)
    load_hash(CARGOBOB_MODEL)
    local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
    ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0, 8.0)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 10)
    local cargobob = entities.create_vehicle(CARGOBOB_MODEL, pos, heading)
    add_vehicle_to_list(cargobob)
    VEHICLE.SET_CARGOBOB_FORCE_DONT_DETACH_VEHICLE(cargobob, true)
    VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(cargobob)
    VEHICLE.CREATE_PICK_UP_ROPE_FOR_CARGOBOB(cargobob, useMagnet and 1 or 0)
    if useMagnet then
        VEHICLE.SET_CARGOBOB_PICKUP_MAGNET_EFFECT_RADIUS(cargobob, 30.0)
        VEHICLE.SET_CARGOBOB_PICKUP_MAGNET_PULL_STRENGTH(cargobob, 1000.0)
        VEHICLE.SET_CARGOBOB_PICKUP_MAGNET_STRENGTH(cargobob, 1000.0)
    end
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(cargobob)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(cargobob, true)
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    ENTITY.SET_ENTITY_VELOCITY(cargobob, 0, 0, 0)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
    local tries = 0
    while not VEHICLE.IS_VEHICLE_ATTACHED_TO_CARGOBOB(cargobob, vehicle) and tries <= 20 do
        VEHICLE.ATTACH_VEHICLE_TO_CARGOBOB(cargobob, vehicle, -2, 0, 0, 0)
        ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
        tries = tries + 1
        util.yield(100)
    end
    util.create_thread(function(_)
        util.yield(4000)
        if not VEHICLE.IS_VEHICLE_ATTACHED_TO_CARGOBOB(cargobob, vehicle) then
            if ENTITY.DOES_ENTITY_EXIST(cargobob) then
                entities.delete_by_handle(cargobob)
            end
            if ENTITY.DOES_ENTITY_EXIST(driver) then
                entities.delete_by_handle(driver)
            end
        end
    end)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
    return cargobob, driver
end

local TITAN_MODEL = util.joaat("titan")
function spawn_titan_for_vehicle(vehicle)
    load_hash(TITAN_MODEL)
    local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
    ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 5.0, 1000.0)
    local pos_veh = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0.0, 1001.3) -- offset by 1.3

    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 5000)
    local titan = entities.create_vehicle(TITAN_MODEL, pos, heading)
    add_vehicle_to_list(titan)
    VEHICLE.SET_VEHICLE_ENGINE_ON(titan, true, true, false)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(titan)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(titan, true)
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    ENTITY.SET_ENTITY_VELOCITY(titan, 0, 0, 0)
    ENTITY.FREEZE_ENTITY_POSITION(titan, true)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
    ENTITY.SET_ENTITY_COORDS(vehicle, pos_veh.x, pos_veh.y, pos_veh.z)
    util.yield(1000)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
    ENTITY.FREEZE_ENTITY_POSITION(titan, false)
    return titan, driver
end

local TOW_TRUCK_MODEL_1 = util.joaat("towtruck")
local TOW_TRUCK_MODEL_2 = util.joaat("towtruck2")
function spawn_tow_for_vehicle(vehicle)
    local pz = memory.alloc(8)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 8, 0.1)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pz, true)
    pos.z = memory.read_float(pz)
    local model = math.random(2) == 2 and TOW_TRUCK_MODEL_1 or TOW_TRUCK_MODEL_2
    load_hash(model)
    local tow = entities.create_vehicle(model, pos, heading)
    add_vehicle_to_list(tow)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)

    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 5)
    VEHICLE.ATTACH_VEHICLE_TO_TOW_TRUCK(tow, vehicle, false, 0, 0, 0)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(tow, true)
    
    return tow, driver, model
end

function setup_choose_player_menu(rootMenu, menuList, callback, pid)
    menu.on_focus(rootMenu, function(_)
        for _, m in ipairs(menuList) do
            menu.delete(m)
        end
        menuList = {}
        local cur_players = players.list(true, true, true)
        local my_pid = players.user()
        for _, target_pid in ipairs(cur_players) do
            local name = PLAYER.GET_PLAYER_NAME(target_pid)
            if pid ~= nil and target_pid == pid then
                name = name .. " (" .. i18n.format("THEM") .. ")"
            elseif target_pid == my_pid then
                name = name .. " (" .. i18n.format("ME") .. ")"
            end
            local m = callback(target_pid, name)
            table.insert(menuList, m)
        end
    end)
end

-- Data

local driveClone = {
    vehicle = 0,
    target = 0
}
local spawnInVehicle = false
local smartAutodrive = false

-- Per-player options
local playerOptions = {}

function setup_player_menu(pid)
    menu.divider(menu.player_root(pid), "Jackz Vehicles")
    local submenu = i18n.menus.list(menu.player_root(pid), "VEHICLE_OPTIONS", { "vehicle"} )
    -- Set default player settings
    playerOptions[pid] = {
        teleport_last = false,
        paint_color_primary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        paint_color_secondary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        neon_color = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        trailer_gate = true,
        cargo_magnet = false
    }

    i18n.menus.action(submenu, "TP_VEH_TO_ME", { "tpvehme" }, function(_)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        control_vehicle(pid, function(vehicle)
            ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z + 3.0, 0, 0, 0, 0)
        end)
    end)

    i18n.menus.action(submenu, "TP_VEH_TO_WAYPOINT", { "tpvehwaypoint" }, function(_)
        get_waypoint_pos(function(pos)
            STREAMING.LOAD_SCENE(pos.x, pos.y, pos.z)
            control_vehicle(pid, function(vehicle)
                ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z + 3.0, 0, 0, 0, 0)
            end)
        end)
    end)

    ----------------------------------------------------------------
    -- Attachments Section
    ----------------------------------------------------------------
    local attachmentsList = i18n.menus.list(submenu, "ATTACHMENTS", {"attachments"})
        i18n.menus.divider(attachmentsList, "TOW_TRUCKS")
            i18n.menus.action(attachmentsList, "TOW_DRIVE", {"tow"}, function()
                control_vehicle(pid, function(vehicle)
                    local tow, driver = spawn_tow_for_vehicle(vehicle)
                    util.yield(1500)
                    if ENTITY.DOES_ENTITY_EXIST(tow) then
                        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                        entities.delete_by_handle(driver)
                        TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, tow, -1)
                    end
                end)
            end)
            i18n.menus.action(attachmentsList, "TOW_TRUCKS_WANDER", {"towwander"}, function(_)
                control_vehicle(pid, function(vehicle)
                    local tow, driver = spawn_tow_for_vehicle(vehicle)
                    TASK.TASK_VEHICLE_DRIVE_WANDER(driver, tow, 30.0, 6)
                end)
            end)
            menu.action(attachmentsList, i18n.format("TOW_TO_WAYPOINT_NAME"), {"towwaypoint"}, i18n.format("TOW_TO_WAYPOINT_DESC"), function(_)
                get_waypoint_pos(function(waypoint_pos)
                    control_vehicle(pid, function(vehicle)
                        local tow, driver, model = spawn_tow_for_vehicle(vehicle)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, tow, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, model, 6, 5.0, 1.0)
                    end)
                end)
            end)
            local towPlayerMenu = menu.list(attachmentsList, i18n.format("TOW_TO_PLAYER_DIVIDER"), {"towtoplayer"})
            local towPlayerMenus = {}
            menu.on_focus(towPlayerMenu, function(_)
                for _, m in ipairs(towPlayerMenus) do
                    menu.delete(m)
                end
                towPlayerMenus = {}
                local cur_players = players.list(true, true, true)
                local my_pid = players.user()
                for _, pid2 in ipairs(cur_players) do
                    local name = PLAYER.GET_PLAYER_NAME(pid2) 
                    if pid == pid2 then
                        name = name .. " (" .. i18n.format("THEM") .. ")"
                    elseif pid2 == my_pid then
                        name = name .. " (" .. i18n.format("ME") .. ")"
                    end
                    local m = menu.action(towPlayerMenu, name, {}, i18n.format("TOW_TO_PLAYER_INDV_DESC"), function(_)
                        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid2)
                        control_vehicle(pid, function(vehicle)
                            local tow, driver = spawn_tow_for_vehicle(vehicle)
                            local hash = ENTITY.GET_ENTITY_MODEL(vehicle)
                            util.create_tick_handler(function(_)
                                local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
                                TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, tow, target_pos.x, target_pos.y, target_pos.z, 100, 5, hash, 6, 1.0, 1.0)
                                util.yield(5000)
                                return ENTITY.DOES_ENTITY_EXIST(target_ped) and ENTITY.DOES_ENTITY_EXIST(driver) and TASK.GET_SCRIPT_TASK_STATUS(driver, 0x93A5526E) < 7
                            end)
                        end)
                    end)
                    table.insert(towPlayerMenus, m)
                end
            end)

            menu.action(attachmentsList, i18n.format("DETACH_TOW_NAME"), {"detachtow"},  i18n.format("DETACH_TOW_DESC"), function(_)
                control_vehicle(pid, function(vehicle)
                    VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(vehicle)
                end)
            end)

        menu.divider(attachmentsList, "Cargobob")

            menu.toggle(attachmentsList, i18n.format("USE_MAGNET_NAME"), {"cargomagnet"}, i18n.format("USE_MAGNET_DESC"), function(on)
                playerOptions[pid].cargo_magnet = on
            end, playerOptions[pid].cargo_magnet)

            menu.action(attachmentsList, i18n.format("CARGOBOB_FLY_NAME"), {"cargobofly"}, i18n.format("CARGOBOB_FLY_DESC"), function()
                control_vehicle(pid, function(vehicle)
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, playerOptions[pid].cargo_magnet)
                    util.yield(1500)
                    if ENTITY.DOES_ENTITY_EXIST(cargobob) then
                        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                        entities.delete_by_handle(driver)
                        TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, cargobob, -1)
                    end
                end)
            end)

            menu.action(attachmentsList, i18n.format("CARGOBOB_MT_CHILIAD_NAME"), {"cargobobmt"}, i18n.format("CARGOBOB_MT_CHILIAD_DESC"), function()
                control_vehicle(pid, function(vehicle)
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, playerOptions[pid].cargo_magnet)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, 450.718 , 5566.614, 806.183, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
                end)
            end)

            menu.action(attachmentsList, i18n.format("CARGOBOB_OCEAN_NAME"), {"cargobobocean"}, i18n.format("CARGOBOB_OCEAN_DESC"), function()
                control_vehicle(pid, function(vehicle)
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, playerOptions[pid].cargo_magnet)
                    local pos = ENTITY.GET_ENTITY_COORDS(cargobob)
                    local vec = memory.alloc(24)
                    local dest = { x = 0, y = 0, z = -5.0}
                    if PATHFIND.GET_NTH_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, 15, vec, 3, 3.0, 0) then
                    dest = memory.read_vector3(vec)
                        dest.z = -5.0
                    else
                        dest.x = -2156
                        dest.y = -1311
                    end
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, dest.x, dest.y, dest.z, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
                end)
            end)
            
            local cargoPlayerMenu = menu.list(attachmentsList, i18n.format("CARGOBOB_TO_PLAYER_NAME"), {"cargobobtoplayer"})
            local cargoPlayerMenus = {}
            setup_choose_player_menu(cargoPlayerMenu, cargoPlayerMenus, function(target_pid, name)
                return menu.action(cargoPlayerMenu, name, {}, i18n.format("CARGOBOB_TO_PLAYER_INDV_DESC"), function()
                    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target_pid)
                    control_vehicle(pid, function(vehicle)
                        local _, driver = spawn_cargobob_for_vehicle(vehicle, playerOptions[pid].cargo_magnet)
                        TASK.TASK_HELI_CHASE(driver, target_ped, 0, 0, 80.0)
                    end)
                end)
            end, pid)

            menu.action(attachmentsList, i18n.format("CARGOBOB_TO_WAYPOINT_NAME"), {"cargobobwaypoint"}, i18n.format("CARGOBOB_TO_WAYPOINT_DESC"), function(_)
                get_waypoint_pos(function(waypoint_pos)
                    control_vehicle(pid, function(vehicle)
                        local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, playerOptions[pid].cargo_magnet)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
                    end)
                end)
            end)

            menu.action(attachmentsList, i18n.format("DETACH_CARGOBOB_NAME"), {"detachcargo"}, i18n.format("DETACH_CARGOBOB_DESC"), function(_)
                control_vehicle(pid, function(vehicle)
                    VEHICLE.DETACH_VEHICLE_FROM_ANY_CARGOBOB(vehicle)
                    local hasPlayer = false
                    for seat = 1, 6 do
                        local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat)
                        if PED.IS_PED_A_PLAYER(ped) then
                            hasPlayer = true
                            break
                        end
                    end
                    if not hasPlayer then
                        local pointer = entities.handle_to_pointer(vehicle)
                        ENTITY.SET_VEHICLE_AS_NO_LONGER_NEEDED(pointer)
                    end
                end)
            end)

        menu.divider(attachmentsList, i18n.format("TRAILERS_DIVIDER"))

            menu.action(attachmentsList, i18n.format("TRAILER_DRIVE_WANDER_NAME"), {"trailerwander"}, i18n.format("TRAILER_DRIVE_WANDER_DESC"), function(_)
                control_vehicle(pid, function(vehicle)
                    local cab, driver = spawn_cab_and_trailer_for_vehicle(vehicle, playerOptions[pid].trailer_gate)
                    TASK.TASK_VEHICLE_DRIVE_WANDER(driver, cab, 30.0, 786603)
                    TASK.SET_PED_KEEP_TASK(driver, true)
                end)
            end)

            menu.action(attachmentsList, i18n.format("TRAILER_TO_WAYPOINT_NAME"), {"trailerwaypoint"}, i18n.format("TRAILER_TO_WAYPOINT_DESC"), function(_)
                get_waypoint_pos(function(waypoint_pos)
                    control_vehicle(pid, function(vehicle)
                        local cab, driver = spawn_cab_and_trailer_for_vehicle(vehicle, playerOptions[pid].trailer_gate)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cab, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, CAB_MODEL, 786603, 5.0, 1.0)
                    end)
                end)
            end)

            menu.toggle(attachmentsList, i18n.format("TRAILER_GATE_DOWN_OPT_NAME"), {"trailergate"}, i18n.format("TRAILER_GATE_DOWN_OPT_DESC"), function(on)
                playerOptions[pid].trailer_gate = on
            end, playerOptions[pid].trailer_gate)

        menu.divider(attachmentsList, "Titan")
            menu.action(attachmentsList, i18n.format("TITAN_FLY_TO_MT_CHILIAD_NAME"), {"titanmtchiliad"}, i18n.format("TITAN_FLY_TO_MT_CHILIAD_DESC"), function(_)
                control_vehicle(pid, function(vehicle)
                    local titan, driver = spawn_titan_for_vehicle(vehicle)
                    --TASK.TASK_PLANE_CHASE(driver, target_ped, 0, 0, 80.0)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, titan, 450.718 , 5566.614, 806.183, 100.0, 1.0, TITAN_MODEL, 786603, 5.0, 1.0)
                end)
            end)
            local titanPlayerMenu = menu.list(attachmentsList, i18n.format("TITAN_FLY_TO_PLAYER_NAME"), {"titantoplayer"})
            local titanPlayerMenus = {}
            setup_choose_player_menu(titanPlayerMenu, titanPlayerMenus, function(target_pid, name)
                return menu.action(titanPlayerMenu, name, {}, i18n.format("TITAN_FLY_TO_PLAYER_INDV_DESC"), function(_)
                    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target_pid)
                    control_vehicle(pid, function(vehicle)
                        local _, driver = spawn_titan_for_vehicle(vehicle)
                        TASK.TASK_HELI_CHASE(driver, target_ped, 0, 0, 80.0)
                    end)
                end)
            end, pid)
            menu.action(attachmentsList, i18n.format("TITAN_FLY_TO_WAYPOINT_NAME"), {"flywaypoint"}, i18n.format("TITAN_FLY_TO_WAYPOINT_DESC"), function(_)
                get_waypoint_pos(function(waypoint_pos)
                    control_vehicle(pid, function(vehicle)
                        local titan, driver = spawn_titan_for_vehicle(vehicle)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, titan, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, TITAN_MODEL, 786603, 5.0, 1.0)
                    end)
                end)
            end)

        menu.divider(attachmentsList, "Misc")

            menu.action(attachmentsList, i18n.format("ATTACH_FREE_VEHICLE_NAME"), {"freevehicle"}, i18n.format("ATTACH_FREE_VEHICLE_DESC"), function(_)
                control_vehicle(pid, function(vehicle)
                    local pos = ENTITY.GET_ENTITY_COORDS(vehicle)
                    ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z + 5.0)
                end)
            end)

            menu.action(attachmentsList, i18n.format("ATTACH_DETACH_ALL_NAME"), {"detachall"}, i18n.format("ATTACH_DETACH_ALL_DESC"), function(_)
                control_vehicle(pid, function(vehicle)
                    ENTITY.DETACH_ENTITY(vehicle, true, 0)
                end)
            end)
            i18n.menus.toggle(attachmentsList, "VEH_DRIVE", {"clonevehicle"}, function(on)
                if on then
                    control_vehicle(pid, function(vehicle)
                        local saveData = vehiclelib.Serialize(vehicle)
                        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 5.0, 0.5)
                        local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
                        local cvehicle = entities.create_vehicle(saveData.Model, pos, heading)
                        add_vehicle_to_list(cvehicle)
                        driveClone.vehicle = cvehicle
                        driveClone.target = vehicle
                        vehiclelib.ApplyToVehicle(cvehicle, saveData)
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle, cvehicle, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, false, true, false, false, 2, true)
                        for _ = 1, 5 do
                            TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, cvehicle, -1)
                            util.yield(10)
                        end
                    end)
                elseif driveClone.vehicle > 0 and ENTITY.DOES_ENTITY_EXIST(driveClone.vehicle) then
                    ENTITY.SET_ENTITY_VISIBLE(driveClone.target, true)
                    entities.delete_by_handle(driveClone.vehicle)
                    driveClone.vehicle = 0
                    driveClone.target = 0
                end
            end)
    -- END ATTACHMENTS
    ----------------------------------------------------------------
    -- Movement Section
    ----------------------------------------------------------------
    local movementMenu = menu.list(submenu, i18n.format("MOVEMENT_NAME"), {}, i18n.format("MOVEMENT_DESC"))

        menu.click_slider(movementMenu, i18n.format("MOVEMENT_BOOST_NAME"), {"boost"}, i18n.format("MOVEMENT_BOOST_DESC"), -200, 200, 200, 10, function(mph)
            local speed = mph / 0.44704
            control_vehicle(pid, function(vehicle)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, speed)
                local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
                ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z + 2.0)
                VEHICLE.RESET_VEHICLE_WHEELS(vehicle)
            end)
        end)

        menu.action(movementMenu, i18n.format("MOVEMENT_SLINGSHOT_NAME"), {"slingshot"}, i18n.format("MOVEMENT_SLINGSHOT_DESC"), function(_)
            control_vehicle(pid, function(vehicle)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100.0)
                local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
                ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z + 100.0)
                VEHICLE.RESET_VEHICLE_WHEELS(vehicle)
            end)
        end)

        menu.click_slider(movementMenu, i18n.format("MOVEMENT_LAUNCH_NAME"), {"launch"}, i18n.format("MOVEMENT_LAUNCH_DESC"), -200, 200, 200, 10, function(mph)
            local speed = mph / 0.44704
            control_vehicle(pid, function(vehicle)
                ENTITY.SET_ENTITY_VELOCITY(vehicle, 0.0, 0.0, speed)
            end)
        end)

        menu.action(movementMenu, i18n.format("MOVEMENT_STOP_NAME"), {"stopvehicle"}, i18n.format("MOVEMENT_STOP_DESC"), function(_)
            control_vehicle(pid, function(vehicle)
                VEHICLE._STOP_BRING_VEHICLE_TO_HALT(vehicle)
                ENTITY.SET_ENTITY_VELOCITY(vehicle, 0.0, 0.0, 0.0)
            end)
        end)

    -- END Movement Section
    ----------------------------------------------------------------
    -- Door Section
    ----------------------------------------------------------------
    local door_submenu = menu.list(submenu, i18n.format("DOORS_NAME"), {}, i18n.format("DOORS_DESC"))
    menu.slider(door_submenu, i18n.format("DOORS_LOCK_STATUS_NAME"), {"lockstatus"}, i18n.format("DOORS_LOCK_STATUS_DESC"), 0, 2, 0, 1, function(state)
        control_vehicle(pid, function(vehicle)
            if state == 0 then
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
            elseif state == 1 then
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 4)
            else
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2)
            end
        end)
    end)

    local open_doors = true
    menu.toggle(door_submenu, i18n.format("DOORS_OPEN_NAME"), {}, i18n.format("DOORS_OPEN_DESC"), function(on)
        open_doors = on
    end, open_doors)

    menu.action(door_submenu, i18n.format("DOORS_ALL_DOORS_NAME"), {}, i18n.format("DOORS_ALL_DOORS_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            if open_doors then
                for door = 0,7 do
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, door, false, false)
                end
            else
                VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle, false)
            end
        end)
    end)
    

    for i, name in pairs(DOOR_NAMES) do
        menu.action(door_submenu, name, {}, i18n.format("DOORS_INDV_DESC", name), function(_)
            control_vehicle(pid, function(vehicle)
                if open_doors then
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, i - 1, false, false)
                else
                    VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, i - 1, false)
                end
            end)
        end)
    end
    menu.toggle(door_submenu, i18n.format("DOORS_LANDING_GEAR_NAME"), {}, i18n.format("DOORS_LANDING_GEAR_DESC"), function(on)
        control_vehicle(pid, function(vehicle)
            VEHICLE.CONTROL_LANDING_GEAR(vehicle, on and 0 or 3)
        end)
    end)
    -- END Door Section
    ----------------------------------------------------------------
    -- LSC Section
    ----------------------------------------------------------------
    local lsc = menu.list(submenu, "Los Santos Customs", {"lcs"}, i18n.format("LSC_DESC"))
    menu.slider(lsc, i18n.format("LSC_XENON_TYPE_NAME"), {"xenoncolor"}, i18n.format("LSC_XENON_TYPE_DESC"), -1, 12, 0, 1, function(paint)
        control_vehicle(pid, function(vehicle)
            VEHICLE._SET_VEHICLE_XENON_LIGHTS_COLOR(vehicle, paint)
        end)
    end)
    local extrasMenus = {}
    local extrasList = i18n.menus.list(lsc, "LSC_EXTRAS", {})
    menu.on_focus(extrasList, function(_)
        for _, m in ipairs(extrasMenus) do
            menu.delete(m)
        end
        extrasMenus = {}
        control_vehicle(pid, function(vehicle)
            for x = 0, vehiclelib.MAX_EXTRAS do
                if VEHICLE.DOES_EXTRA_EXIST(vehicle, x) then
                    local active = VEHICLE.IS_VEHICLE_EXTRA_TURNED_ON(vehicle, x)
                    local m = menu.toggle(extrasList, "Extra " .. x, {}, i18n.format("EXTRA_INDV_DESC"), function(on)
                        VEHICLE.SET_VEHICLE_EXTRA(vehicle, x, not on)
                    end, active)
                    table.insert(extrasMenus, m)
                end
            end
        end, { silent = true })
    end)
    --
    -- NEON SECTION
    --
    local neon = menu.list(lsc, i18n.format("LSC_NEON_LIGHTS_NAME"), {}, "")
    local neon_menus = {}
        menu.action(neon, i18n.format("LSC_NEON_APPLY_NAME"), {"paintneon"}, i18n.format("LSC_NEON_APPLY_DESC"), function(_)
            control_vehicle(pid, function(vehicle)
                local r = math.floor(playerOptions[pid].neon_color.r * 255)
                local g = math.floor(playerOptions[pid].neon_color.g * 255)
                local b = math.floor(playerOptions[pid].neon_color.b * 255)
                VEHICLE._SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, r, g, b)
            end)
        end)

        menu.colour(neon, i18n.format("LSC_NEON_COLOR_NAME"), {"neoncolor"}, i18n.format("LSC_NEON_COLOR_DESC"), playerOptions[pid].neon_color, false, function(color)
            playerOptions[pid].neon_color = color
        end)
        menu.on_focus(neon, function()
            for i, m in ipairs(neon_menus) do
                menu.delete(m)
                table.remove(neon_menus, i)
            end
            for x = 0,3 do
                local enabled = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x)
                local m = menu.toggle(neon, NEON_INDICES[x+1], {}, "", function(_)
                    control_vehicle(pid, function(vehicle)
                        enabled = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x)
                        VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x, not enabled)
                    end, { silent = true })
                end, enabled)
                table.insert(neon_menus, m)
            end
        end)
    --END NEON--
    -- PAINT
    menu.action(lsc, i18n.format("LSC_PAINT_NAME"), {"paint"}, i18n.format("LSC_PAINT_DESC"), function(on_click)
        control_vehicle(pid, function(vehicle)
            local r = math.floor(playerOptions[pid].paint_color_primary.r * 255)
            local g = math.floor(playerOptions[pid].paint_color_primary.g * 255)
            local b = math.floor(playerOptions[pid].paint_color_primary.b * 255)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, r, g, b)
            r = math.floor(playerOptions[pid].paint_color_secondary.r * 255)
            g = math.floor(playerOptions[pid].paint_color_secondary.g * 255)
            b = math.floor(playerOptions[pid].paint_color_secondary.b * 255)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, r, g, b)
        end)
    end)

    menu.colour(lsc, i18n.format("LSC_PAINT_PRIMARY_NAME"), {"paintcolorprimary"}, i18n.format("LSC_PAINT_PRIMARY_DESC"), playerOptions[pid].paint_color_primary, false, function(color)
        playerOptions[pid].paint_color_primary = color
    end)

    menu.colour(lsc, i18n.format("LSC_PAINT_SECONDARY_NAME"), {"paintcolorsecondary"}, i18n.format("LSC_PAINT_SECONDARY_DESC"), playerOptions[pid].paint_color_secondary, false, function(color)
        playerOptions[pid].paint_color_secondary = color
    end)
    -- END PAINT

    -- VEHICLE MODS
    local subMenus = {}
    local modMenu = menu.list(lsc, i18n.format("LSC_VEHICLE_MODS_NAME"), {}, i18n.format("LSC_VEHICLE_MODS_DESC"))
    menu.on_focus(modMenu, function(_)
        for _, m in ipairs(subMenus) do
            menu.delete(m)
        end
        subMenus = {}
        control_vehicle(pid, function(vehicle)
            for i, mod in pairs(vehiclelib.MOD_NAMES) do
                local default_val = VEHICLE.GET_VEHICLE_MOD(vehicle, i -1)
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i - 1)
                local m = menu.slider(modMenu, mod, {"set" .. mod}, i18n.format("LSC_MOD_NORMAL_DESC", max, mod), -1, max, default_val, 1, function(index)
                    control_vehicle(pid, function(vehicle)
                        VEHICLE.SET_VEHICLE_MOD(vehicle, i - 1, index)
                    end)
                end)
                table.insert(subMenus, m)
            end
            for i, mod in pairs(vehiclelib.TOGGLEABLE_MOD_NAMES) do
                local default_val = VEHICLE.IS_TOGGLE_MOD_ON(vehicle, i-1)
                local m = menu.toggle(modMenu, mod, {"toggle" .. mod}, i18n.format("LSC_MOD_TOGGLE_DESC", mod), function(on)
                    control_vehicle(pid, function(vehicle)
                        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, i-1, on)
                    end)
                end, default_val)
                table.insert(subMenus, m)
            end
        end, { silent = true})
    end)
    -- END VEHICLE MODS
    -- MISC ACTIONS:
    menu.click_slider(modMenu, i18n.format("LSC_WHEEL_TYPE_NAME"), {"wheeltype"}, i18n.format("LSC_WHEEL_TYPE_DESC"), 0, MAX_WHEEL_TYPES, 0, 1, function(wheelType)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_WHEEL_TYPE(vehicle, wheelType)
        end)
    end)

    menu.click_slider(modMenu, i18n.format("LSC_WINDOW_TINT_NAME"), {"windowtint"}, i18n.format("LSC_WINDOW_TINT_DESC"), 0, MAX_WINDOW_TINTS, 0, 1, function(value)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, value)
        end)
    end)

    menu.action(lsc, i18n.format("LSC_UPGRADE_NAME"), {"upgradevehicle"}, i18n.format("LSC_UPGRADE_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            for x = 0, 49 do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.SET_VEHICLE_MOD(vehicle, 15, 45) -- re-set horn 
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 5)
            for x = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, true)
            end
        end)
    end)

    i18n.menus.action(lsc, "LSC_UPGRADE_RANDOM", {"upgradevehiclerandom"}, function(_)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            for x = 0, 49 do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, math.random(-1, max))
            end
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(-1,5))
            for x = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, math.random() > 0.5)
            end
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
        end)
    end)

    menu.action(lsc, i18n.format("LSC_PERFORMANCE_UPGRADE_NAME"), {"performanceupgradevehicle"}, i18n.format("LSC_PERFORMANCE_UPGRADE_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            local mods = { 11, 12, 13, 16 }
            for x in ipairs(mods) do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
        end)
    end)

    menu.action(lsc, i18n.format("VEH_LICENSE_NAME"), {"jvlicense"}, i18n.format("VEH_LICENSE_DESC"), function(on)
        local name = PLAYER.GET_PLAYER_NAME(pid)
        menu.show_command_box("jvlicense" .. name .. " ")
    end, function(args)
        control_vehicle(pid, function(vehicle)
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, args)
        end)
    end, false)

    -- END LSC
    ----------------------------------------------------------------
    -- MISC OPTIONS FOR VEHICLE OPTIONS ROOT
    ----------------------------------------------------------------
    menu.action(submenu, i18n.format("VEH_CLONE_NAME"), {"clonevehicle"}, i18n.format("VEH_CLONE_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            local saveData = vehiclelib.Serialize(vehicle)
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            local vehicle = entities.create_vehicle(saveData.Model, pos, heading)
            add_vehicle_to_list(vehicle)
            if spawnInVehicle then
                PED.SET_PED_INTO_VEHICLE(my_ped, vehicle, -1)
            end
            vehiclelib.ApplyToVehicle(vehicle, saveData)
        end)
    end)

    menu.action(submenu, i18n.format("VEH_SAVE_NAME"), {"saveplayervehicle"}, i18n.format("VEH_SAVE_DESC"), function(_)
        i18n.toast("VEH_SAVE_HINT")
        menu.show_command_box("saveplayervehicle ")
    end, function(args)
        control_vehicle(pid, function(vehicle)
            local saveData = vehiclelib.Serialize(vehicle)

            local file = io.open( VEHICLE_DIR .. args .. ".json", "w")
            file:write(json.encode(saveData))
            file:close()
            i18n.toast("FILE_SAVED", "%appdata%\\Stand\\Vehicles\\" .. args .. ".json")
        end)
    end)
    menu.action(submenu, i18n.format("VEH_SPAWN_VEHICLE_NAME"), {"spawnfor"}, i18n.format("VEH_SPAWN_VEHICLE_DESC"), function(_)
        local name = PLAYER.GET_PLAYER_NAME(pid)
        menu.show_command_box("spawnfor" .. name .. " ")
    end, function(args)
        local model = util.joaat(args)
        if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_A_VEHICLE(model) then
            load_hash(model)
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
            local vehicle = entities.create_vehicle(model, pos, heading)
            add_vehicle_to_list(vehicle)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
        else
            i18n.toast("VEH_SPAWN_NOT_FOUND")
        end
    end, false)

    menu.action(submenu, i18n.format("VEH_FLIP_UPRIGHT_NAME"), {"flipveh"}, i18n.format("VEH_FLIP_UPRIGHT_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, rot.y, rot.z)
        end)
    end)


    menu.action(submenu, i18n.format("VEH_FLIP_180_NAME"), {"flipv"}, i18n.format("VEH_FLIP_180_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
        end)
    end)

    menu.action(submenu, i18n.format("VEH_HONK_NAME"), {"honk"}, i18n.format("VEH_HONK_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_ALARM(vehicle, true)
            VEHICLE.START_VEHICLE_ALARM(vehicle)
            VEHICLE.START_VEHICLE_HORN(vehicle, 50000, 0)
        end)
    end)

    menu.click_slider(submenu, i18n.format("VEH_HIJACK_WANDER_NAME"), {"hijack"}, i18n.format("VEH_HIJACK_WANDER_DESC"), 0, 1, 0, 1, function(hijackLevel)
        control_vehicle(pid, function(vehicle)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 0.0, 0.1)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
            local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
            TASK.TASK_ENTER_VEHICLE(ped, vehicle, -1, -1, 1.0, 24)
            if hijackLevel == 1 then
                util.yield(20)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
            end
            for _ = 1, 20 do
                TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
                util.yield(50)
            end
        end)
    end)

    local hijackToMenu = menu.list(submenu, i18n.format("VEH_HIJACK_TO_PLAYER_NAME"), {"hijacktoplayer"})
    local hijackToMenus = {}
    setup_choose_player_menu(hijackToMenu, hijackToMenus, function(target_pid, name)
        return menu.action(hijackToMenu, name, {}, i18n.format("VEH_HIJACK_TO_PLAYER_INDV_DESC"), function(_)
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target_pid)
            control_vehicle(pid, function(vehicle)
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 1.0, 0.1)
                ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
                local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
                TASK.TASK_ENTER_VEHICLE(ped, vehicle, -1, -1, 1.0, 24)

                local model = ENTITY.GET_ENTITY_MODEL(vehicle)
                --TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
                local loops = 10
                while not PED.IS_PED_IN_VEHICLE(ped, vehicle, false) do
                    local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, target_pos.x, target_pos.y, target_pos.z, 100, 5, model, 6, 1.0, 1.0)
                    util.yield(1000)
                    loops = loops - 1
                    if loops == 0 then
                        i18n.toast("VEH_HIJACK_FAILED_ACQUIRE")
                        return false
                    end
                end
                VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
                local hash = ENTITY.GET_ENTITY_MODEL(vehicle)
                util.create_tick_handler(function(_)
                    local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, target_pos.x, target_pos.y, target_pos.z, 100, 5, hash, 6, 1.0, 1.0)
                    util.yield(5000)
                    return ENTITY.DOES_ENTITY_EXIST(target_ped) and ENTITY.DOES_ENTITY_EXIST(ped) and TASK.GET_SCRIPT_TASK_STATUS(ped, 0x93A5526E) < 7
                end)
            end)
        end)
    end, pid)

    menu.action(submenu, i18n.format("VEH_BURST_TIRES_NAME"), {"bursttires", "bursttyres"}, i18n.format("VEH_BURST_TIRES_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            local burstable = VEHICLE.GET_VEHICLE_TYRES_CAN_BURST(vehicle)
            VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)
            for wheel = 0,7 do
                VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, wheel, true, 1000.0)
                
            end
            if not burstable then
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
            end
        end)
    end)

    menu.action(submenu, i18n.format("VEH_DELETE_NAME"), {"deletevehicle"}, i18n.format("VEH_DELETE_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            entities.delete_by_handle(vehicle)
        end)
    end)

    menu.action(submenu, i18n.format("VEH_EXPLODE_NAME"), {"explodevehicle"}, i18n.format("VEH_EXPLODE_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            local pos = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
            FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z + 1.0, 26, 60, true, true, 0.0)
        end)
    end)

    menu.action(submenu, i18n.format("VEH_KILL_ENGINE_NAME"), {"killengine"}, i18n.format("VEH_KILL_ENGINE_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
        end)
    end)

    menu.action(submenu, i18n.format("VEH_CLEAN_NAME"), {"cleanvehicle"}, i18n.format("VEH_CLEAN_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            GRAPHICS.REMOVE_DECALS_FROM_VEHICLE(vehicle)
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
        end)
    end)

    menu.action(submenu, i18n.format("VEH_REPAIR_NAME"), {"repairvehicle"}, i18n.format("VEH_REPAIR_DESC"), function(_)
        control_vehicle(pid, function(vehicle)
            VEHICLE.SET_VEHICLE_FIXED(vehicle)
        end)
    end)

    menu.toggle(submenu, i18n.format("VEH_TOGGLE_GODMODE_NAME"), {"setvehgod"}, i18n.format("VEH_TOGGLE_GODMODE_DESC"), function(on)
        control_vehicle(pid, function(vehicle)
            ENTITY.SET_ENTITY_INVINCIBLE(vehicle, on)
        end)
    end, false)
end
----------------------------
-- CLOUD VEHICLES SECTION
----------------------------
local nearbyMenu = menu.list(menu.my_root(), i18n.format("NEARBY_VEHICLES_NAME"), {"nearbyvehicles"}, i18n.format("NEARBY_VEHICLES_DESC"))
local allPlayersMenu = menu.list(menu.my_root(), i18n.format("ALL_NAME"), {"vehicleall"}, i18n.format("ALL_DESC"))
local autodriveMenu = menu.list(menu.my_root(), i18n.format("AUTODRIVE_NAME"), {"autodrive"}, i18n.format("AUTODRIVE_DESC"))
menu.divider(menu.my_root(), "Vehicle Spawning")

local cloudSortListMenus = {}
local cloudRootList = i18n.menus.list(menu.my_root(), "CLOUD", {"jvcloud"})
local cloudUsersMenu = i18n.menus.list(cloudRootList, "BROWSE_BY_USERS", {"jvcloudusers"}, _load_cloud_user_vehs)
local cloudVehiclesMenu = i18n.menus.list(cloudRootList, "BROWSE_BY_VEHICLES", {"jvcloudvehicles"}, function() _load_cloud_vehicles() end, function() clear_menu_array(cloudSortListMenus) end)
local sortId = { "rating", "name", "author", "author", "uploaded"}
local cloudUserVehicleSaveDataCache = {}
local cloudSettings = {
    sort = {
        type = "rating",
        ascending = false,
    },
    limit = 30,
    page = 1,
    maxPages = 2
}
menu.divider(cloudRootList, "")
menu.list_select(cloudRootList, "Sort by", {}, "Change the sorting criteria", { { "Rating" }, { "Build Name" }, { "Author Name" }, { "Upload Date" }, { "Uploader Name "} }, 1, function(index)
    cloudSettings.sort.type = sortId[index]
end)
menu.toggle(cloudRootList, "Sort Ascending", {}, "Should the list be sorted from lowest to biggest (A-Z, 0->9)", function(value)
    cloudSettings.sort.ascending = value
end, cloudSettings.sort.ascending)
menu.slider(cloudRootList, "Builds Per Page", {"jvbclimit"}, "Set the amount of builds shown in the browse builds list", 10, 100, cloudSettings.limit, 1, function(value) cloudSettings.limit = value end)
local paginatorMenu = menu.slider(cloudRootList, "Page", {"jvbcpage"}, "Set the page for the browse builds list", 1, cloudSettings.maxPages, cloudSettings.page, 1, function(value) cloudSettings.page = value end)

function _add_pagination()
    if cloudSettings.page > 1 then
        table.insert(cloudSortListMenus, menu.action(cloudVehiclesMenu, "View previous page", {}, "", function()
            cloudSettings.page = cloudSettings.page - 1
            _fetch_cloud_sorts()
        end))
    end
    if cloudSettings.page < cloudSettings.maxPages then
        table.insert(cloudSortListMenus, menu.action(cloudVehiclesMenu, "View next page", {}, "", function()
            cloudSettings.page = cloudSettings.page + 1
            _fetch_cloud_sorts()
        end))
    end
end
function _load_cloud_vehicles()
    clear_menu_array(cloudSortListMenus)
    show_busyspinner("Searching cloud vehicles...")
    async_http.init("jackz.me",
        string.format("/stand/cloud/vehicles.php?list2&page=%d&limit=%d&sort=%s&asc=%d",
            cloudSettings.page, cloudSettings.limit, cloudSettings.sort.type, cloudSettings.sort.ascending and 1 or 0
        ),
        function(body, res_headers, status_code)
            if status_code == 200 and body:sub(1, 1) == "{" then
                HUD.BUSYSPINNER_OFF()
                local data = json.decode(body)
                cloudSettings.maxPages = data.pages or 1
                menu.set_max_value(paginatorMenu, cloudSettings.maxPages)
                -- FIXME: Causes stand exceptions when viewing next page?
                -- _add_pagination()
                table.insert(cloudSortListMenus, menu.divider(cloudVehiclesMenu, ""))
                for _, vehicle in ipairs(data.vehicles) do
                    local vehicleEntryList
                    vehicleEntryList = menu.list(cloudVehiclesMenu, vehicle.uploader .. " / " .. vehicle.name, {}, _generate_cloud_info(vehicle), function()
                        if not cloudUserVehicleSaveDataCache[vehicle.uploader] then
                            cloudUserVehicleSaveDataCache[vehicle.uploader] = {}
                        end
                        setup_cloud_vehicle_submenu(vehicleEntryList, vehicle.uploader, vehicle.name)
                    end)
                    table.insert(cloudSortListMenus, vehicleEntryList)
                end
                table.insert(cloudSortListMenus, menu.divider(cloudVehiclesMenu, ""))
                _add_pagination()
            else
                Log.log("bad server response (_fetch_cloud_sorts): " .. status_code .. "\n" .. body)
                util.toast("Server returned error " .. status_code)
            end
        end,
        function()
            util.toast("Failed to fetch cloud data: Network error")
        end)
    async_http.dispatch()

end

local cloudSearchMenu = menu.list(cloudUsersMenu, i18n.format("CLOUD_SEARCH_NAME"), {"searchvehicles"}, i18n.format("CLOUD_SEARCH_DESC"))
local cloudSearchMenus = {}
local previewVehicle = 0
function spawn_preview_vehicle(saveData)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        entities.delete_by_handle(previewVehicle)
    end
    load_hash(saveData.Model)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 6.5, 0.0)
    local veh = VEHICLE.CREATE_VEHICLE(saveData.Model, pos.x, pos.y, pos.z, 0, false, false)
    previewVehicle = veh
    vehiclelib.ApplyToVehicle(previewVehicle, saveData)
    local heading = 0
    ENTITY.SET_ENTITY_ALPHA(previewVehicle, 150)
    VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(previewVehicle)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(previewVehicle, false, false)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(saveData.Model)
    util.create_tick_handler(function()
        heading = heading + 7
        if heading == 360 then
            heading = 0
        end
        pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 5, 0.3)
        ENTITY.SET_ENTITY_COORDS(previewVehicle, pos.x, pos.y, pos.z, true, true, false, false)
        ENTITY.SET_ENTITY_HEADING(previewVehicle, heading)
        util.yield(15)
        return previewVehicle == veh and menu.is_open()
    end)
end
function setup_cloud_vehicle_submenu(m, user, vehicleName)
    local saveData = cloudUserVehicleSaveDataCache[user][vehicleName]
    if not saveData then
        do_cloud_request("/stand/cloud/vehicles?scname=" .. user .. "&vehicle=" .. vehicleName, function(data)
            cloudUserVehicleSaveDataCache[user][vehicleName] = data.vehicle
            spawn_preview_vehicle(cloudUserVehicleSaveDataCache[user][vehicleName])
            i18n.menus.action(m, "CLOUD_SPAWN", {}, function()
                while not cloudUserVehicleSaveDataCache[user][vehicleName] do
                    util.yield()
                end
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 6.5, 0.0)
                local heading = ENTITY.GET_ENTITY_HEADING(my_ped)
                vehicle = entities.create_vehicle(cloudUserVehicleSaveDataCache[user][vehicleName].Model, pos, heading)
                add_vehicle_to_list(vehicle)
                vehiclelib.ApplyToVehicle(vehicle, cloudUserVehicleSaveDataCache[user][vehicleName])
                if spawnInVehicle then
                    PED.SET_PED_INTO_VEHICLE(my_ped, vehicle, -1)
                end
                i18n.toast("VEHICLE_SPAWNED", user .. "/" .. vehicleName)
                if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                    entities.delete_by_handle(previewVehicle)
                end
            end)
            i18n.menus.action(m, "CLOUD_DOWNLOAD", {}, function()
                while not cloudUserVehicleSaveDataCache[user][vehicleName] do
                    util.yield()
                end
                local file = io.open( VEHICLE_DIR .. user .. "_" .. vehicleName, "w")
                file:write(json.encode(cloudUserVehicleSaveDataCache[user][vehicleName]))
                file:close()
                i18n.toast("FILE_SAVED", "%appdata%\\Stand\\Vehicles\\" .. user .. "_" .. vehicleName)
            end)
            if user ~= SOCIALCLUB._SC_GET_NICKNAME() then
                menu.click_slider(m, "Rate", {"rate"..user.."."..vehicleName}, "Rate the uploaded vehicle with 1-5 stars", 1, 5, 5, 1, function(rating)
                    rate_vehicle(user, vehicleName, rating)
                end)
            end
        end)
    end
end
----------------------------
-- CLOUD SEARCH
----------------------------
menu.action(cloudSearchMenu, "> " .. i18n.format("CLOUD_SEARCH_NEW_NAME"), {"jvcsearch"}, "", function(_)
    menu.show_command_box("jvcsearch ")
end, function(query)
    show_busyspinner("Searching " .. query)
    async_http.init("jackz.me", "/stand/vehicles/list2?q=" .. query, function(result)
        for _, m in ipairs(cloudSearchMenus) do
            pcall(menu.delete, m)
        end
        cloudSearchMenus = {}
        local status, data = pcall(json.decode, result)
        if status then
            if data.error then
                util.toast(data.message)
            else
                if #data.results == 0 then
                    i18n.toast("CLOUD_SEARCH_NO_RESULTS", query)
                    return
                end
        
                for _, vehicle in ipairs(data.results) do
                    local m
                    m = menu.list(
                        cloudSearchMenu, 
                        vehicle.creator .. "/" .. vehicle.name,
                        {},
                        _generate_cloud_info(vehicle)
                    )
                    menu.on_focus(m, function() setup_cloud_vehicle_submenu(m, vehicle.creator, vehicle.name) end)
                    table.insert(cloudSearchMenus, m)
                end
            end
        else
            util.toast("Server returned an error fetching cloud data")
        end
        HUD.BUSYSPINNER_OFF()
    end)
    async_http.dispatch()
end)
----------------------------
-- CLOUD UPLOAD
----------------------------
menu.on_focus(cloudSearchMenu, function(_)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        entities.delete_by_handle(previewVehicle)
    end
    for _, m in ipairs(cloudSearchMenus) do
        menu.delete(m)
    end
    cloudSearchMenus = {}
end)
local cloudUploadMenu = menu.list(cloudUsersMenu, i18n.format("CLOUD_UPLOAD"), {"uploadcloud"}, i18n.format("CLOUD_UPLOAD_DESC"))
local cloudUploadMenus = {}
menu.on_focus(cloudUploadMenu, function(_)
    for _, m in ipairs(cloudUploadMenus) do
        menu.delete(m)
    end
    cloudUploadMenus = {}
    load_vehicles_in_dir(VEHICLE_DIR, cloudUploadMenu, function(parent, name, saveData)
        local manuf = saveData.Manufacturer and saveData.Manufacturer .. " " or ""
        local desc = i18n.format("VEHICLE_SAVE_DATA", manuf, saveData.Name, saveData.Type, saveData.Format, vehiclelib.FORMAT_VERSION)
        local displayName = string.sub(name, 0, -6)
        return menu.action(parent, displayName, {}, i18n.format("CLOUD_UPLOAD_VEHICLE") .."\n\n" .. desc .. "\n\n" .. i18n.format("CLOUD_UPLOAD_VEHICLE_NOTICE"), function(_)
            if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                entities.delete_by_handle(previewVehicle)
                previewVehicle = 0
            end
            local scName = SOCIALCLUB._SC_GET_NICKNAME()
            show_busyspinner("Uploading vehicle...")
            async_http.init("jackz.me", "/stand/cloud/vehicles?scname=" .. scName .. "&vehicle=" .. name:sub(0,-6) .. "&hashkey=" .. menu.get_activation_key_hash(), function(result)
                local status, data = pcall(json.decode, result)
                if status then
                    if data.error then
                        i18n.toast("CLOUD_UPLOAD_ERROR", data.message)
                        util.log("jackz_vehicles: Failed to upload: " .. data.message)
                    else
                        i18n.toast("CLOUD_UPLOAD_SUCCESS")
                    end
                else
                    util.toast("Server returned an error fetching cloud data")
                end
                HUD.BUSYSPINNER_OFF()
            end)
            async_http.set_post("Content-Type: application/json", json.encode(saveData))
            async_http.dispatch()
        end)
    end, false)
end)
function rate_vehicle(user, vehicleName, rating)
    if not user or not vehicleName or rating < 0 or rating > 5 then
        Log.log("Invalid rate params. " .. user .. "|" .. vehicleName .. "|" .. rating)
        return false
    end
    async_http.init("jackz.me",
        string.format("/stand/cloud/vehicles.php?scname=%s&vehicle=%s&hashkey=%s&rater=%s&rating=%d",
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
----------------------------
-- CLOUD VEHICLES BROWSE
----------------------------
local cloudUserMenus = {}
local cloudUserVehicleMenus = {}
local waitForFetch = false
menu.divider(cloudUsersMenu, i18n.format("CLOUD_BROWSE_DIVIDER"))
function do_cloud_request(uri, onSuccessCallback)
    if waitForFetch then
        util.yield()
    end
    show_busyspinner("Loading cloud data...")
    waitForFetch = true
    async_http.init("jackz.me", uri, function(result)
        local status, data = pcall(json.decode, result)
        if status then
            if data.error then
                util.toast(data.message)
            else
                onSuccessCallback(data)
            end
        else
            util.toast("Server returned an error fetching cloud data")
        end
        HUD.BUSYSPINNER_OFF()
        waitForFetch = false
    end, function() util.toast("Could not fetch cloud vehicles at this time") end)
    async_http.dispatch()
end
function _load_cloud_user_vehs()
    if waitForFetch then
        util.yield()
    end
    show_busyspinner("Loading cloud data...")
    waitForFetch = true
    for _, m in pairs(cloudUserMenus) do
        pcall(menu.delete, m)
    end
    cloudUserMenus = {}
    do_cloud_request("/stand/cloud/vehicles?list", function(data)
        for _, user in ipairs(data.users) do
            cloudUserMenus[user] = menu.list(cloudUsersMenu, user, {}, i18n.format("CLOUD_BROWSE_VEHICLES_DESC") .. "\n" .. user)
            menu.on_focus(cloudUserMenus[user], function() _load_user_vehicle_list(user) end)
            cloudUserVehicleSaveDataCache[user] = {}
        end
    end)
end
function dump_table(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump_table(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
 
function _load_user_vehicle_list(creator)
    for _, m in ipairs(cloudUserVehicleMenus) do
        pcall(menu.delete, m)
    end
    cloudUserVehicleMenus = {}
    do_cloud_request("/stand/cloud/vehicles?scname=" .. creator, function(data)
        if cloudUserMenus[creator] == nil then return end -- Discard request
        menu.set_menu_name(cloudUserMenus[creator], creator .. " (" .. #data.vehicles .. ")")
        for _, vehicle in ipairs(data.vehicles) do
            local vehicleMenuList
            vehicleMenuList = menu.list(
                cloudUserMenus[creator],
                vehicle.name,
                {},
                _generate_cloud_info(vehicle),
                function() setup_cloud_vehicle_submenu(vehicleMenuList, creator, vehicle.name) end
            )
            table.insert(cloudUserVehicleMenus, vehicleMenuList)
        end
    end)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        entities.delete_by_handle(previewVehicle)
    end
end
function _generate_cloud_info(vehicle)
    return "Version: " .. vehicle.Format .. "\nCreated: " .. vehicle.created .. (vehicle.info and ("\n" .. vehicle.info) or "")
end
----------------------------
-- Spawn Saved Vehicles
----------------------------
local savedVehicleMenus = {}
local savedVehiclesList = menu.list(menu.my_root(), i18n.format("SAVED_NAME"), {"jvsaved"}, i18n.format("SAVED_DESC") .. " %appdata%\\Stand\\Vehicles", function() load_saved_vehicles_list() end)
menu.on_focus(savedVehiclesList, function() clear_menu_table(savedVehicleMenus) end)
local xmlMenusHandles = {}
local xmlList = menu.list(savedVehiclesList, "Convert XML Vehicles", {}, "Vehicles (*.xml), typically from menyoo. Able to convert them through this menu.")
local applySaved = false
i18n.menus.action(menu.my_root(), "VEH_SAVE_CURRENT", {"jvsave"}, function(_)
    menu.show_command_box("jvsave ")
    i18n.toast("VEH_SAVE_CURRENT_HINT")
end, function(args)
    local vehicle = entities.get_user_vehicle_as_handle()
    local saveData = vehiclelib.Serialize(vehicle)
    local file = io.open( VEHICLE_DIR .. args .. ".json", "w")
    file:write(json.encode(saveData))
    file:close()
    i18n.toast("FILE_SAVED", args .. ".json")
end, "jvsave name")
i18n.menus.toggle(menu.my_root(), "SPAWN_IN_VEHICLE", {}, function(on)
    spawnInVehicle = on
end, spawnInVehicle)
menu.toggle(menu.my_root(), i18n.format("SAVED_APPLY_CURRENT_NAME"), {}, i18n.format("SAVED_APPLY_CURRENT_DESC"), function(on)
    applySaved = on
end, applySaved)

local loadedVehicleMenus = {}
function load_vehicles_in_dir(dir, parentMenu, menuSetupFn, xmlSupported)
    for _, path in ipairs(filesystem.list_files(dir)) do
        if filesystem.is_dir(path) then
            local folder = path:match(".*[/\\](.*)")
            if folder ~= "Custom" and folder ~= "custom" then
                local list
                list = menu.list(parentMenu, folder, {}, "View all vehicles in nested folder", function()
                    -- Only load once
                    if list ~= nil then
                        load_vehicles_in_dir(path, list, menuSetupFn, xmlSupported)
                        list = nil
                    end
                end)
                table.insert(loadedVehicleMenus, list)
            end
        else
            local _, filename, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
            if ext == "json" then
                local file = io.open(path, "r")
                local saveData = json.decode(file:read("*a"))
                file:close()
                -- Apply any migrations to disk
                if vehiclelib.MigrateVehicle(saveData) then
                    local status, data = pcall(json.encode, saveData)
                    if status then
                        local file = io.open(path, "w")
                        file:write(data)
                        file:close()
                    else
                        util.log("jackz_vehicles: Failed to save migration, json error for " .. path .. ": " .. data)
                    end
                end

                if saveData.Model and saveData.Mods then
                    local m = menuSetupFn(parentMenu, filename, saveData)
                    menu.on_focus(m, function(_)
                        spawn_preview_vehicle(saveData)
                    end)
                    menu.on_blur(m, function(_)
                        if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                            entities.delete_by_handle(previewVehicle)
                        end
                        previewVehicle = 0
                        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(saveData.Model)
                    end)
                    table.insert(loadedVehicleMenus, m)
                end
            elseif xmlSupported and ext == "xml" then
                local name = filename:sub(1, -5)
                local newPath = VEHICLE_DIR .. "/" .. name .. ".json"
                xmlMenusHandles[filename] = menu.action(xmlList, name, {}, "Click to convert to a compatible format.", function()
                    if filesystem.exists(newPath) then
                        menu.show_warning(VEHICLE_DIR[name], CLICK_COMMAND, "This file already exists, do you want to overwrite " .. filename .. ".json?", function() 
                            convert_file(path, name, newPath)
                        end)
                        return
                    end
                    convert_file(path, name, newPath)
                end)
            end
        end
    end
end

function load_saved_vehicles_list()
    clear_menu_table(xmlMenusHandles)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        entities.delete_by_handle(previewVehicle)
    end
    clear_menu_table(loadedVehicleMenus)
    load_vehicles_in_dir(VEHICLE_DIR, savedVehiclesList, function(parent, filename, saveData)
        local manuf = saveData.Manufacturer and saveData.Manufacturer .. " " or ""
        local desc = i18n.format("VEHICLE_SAVE_DATA", manuf, saveData.Name, saveData.Type, saveData.Format, vehiclelib.FORMAT_VERSION)
        local name = string.sub(filename, 0, -6)
        return menu.action(parent, name, {"spawnvehicle" .. name}, i18n.format("SAVED_VEHICLE_DESC") .. "\n" .. desc, function()
            if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                entities.delete_by_handle(previewVehicle)
                previewVehicle = 0
            end
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 6.5, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(my_ped)
            local vehicle = 0
            if applySaved then
                vehicle = entities.get_user_vehicle_as_handle()
                if vehicle == 0 then
                    i18n.toast("SAVED_MUST_BE_IN_VEHICLE")
                    return
                end
                i18n.toast("SAVED_SUCCESS_CURRENT", filename)
            else
                load_hash(saveData.Model)
                vehicle = entities.create_vehicle(saveData.Model, pos, heading)
                add_vehicle_to_list(vehicle)
                if spawnInVehicle then
                    PED.SET_PED_INTO_VEHICLE(my_ped, vehicle, -1)
                end
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(saveData.Model)
                i18n.toast("VEHICLE_SPAWNED", filename)
            end

            if vehicle > 0 then
                vehiclelib.ApplyToVehicle(vehicle, saveData)
            end
        end)
    end, true)
end
function convert_file(path, name, newPath)
    local file = io.open(path, "r")
    show_busyspinner("Converting " .. name)
    local res = vehiclelib.ConvertXML(file:read("*a"))
    HUD.BUSYSPINNER_OFF()
    file:close()
    if res.error then
        util.toast("Could not convert: " .. res.error)
    else
        util.toast("Successfully converted " .. res.data.type .. " vehicle\nView in your saved vehicle list")
        file = io.open(newPath, "w")
        res.data.vehicle.convertedFrom = res.data.type
        file:write(json.encode(res.data.vehicle))
        file:close()
    end
end
----------------------------------
-- CURRENT VEHICLE MODIFIERS SEC
----------------------------------
local CVModifiers = {
    ACTIVE = false,
    Lights = 1.0,
    Torque = 1.0,
    Traction = 1,
    KeepUpright = false
}
local currentModifiersMenu = i18n.menus.list(menu.my_root(), "CVM", {})

i18n.menus.toggle(currentModifiersMenu, "CVM_KEEP_UPRIGHT", {}, function(on)
    CVModifiers.KeepUpright = on
end, CVModifiers.KeepUpright)
i18n.menus.divider(currentModifiersMenu, "CVM_ACTIVE_MODS")
i18n.menus.toggle(currentModifiersMenu, "CVM_ACTIVE", {}, function(on)
    CVModifiers.ACTIVE = on
    if not on then
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local my_vehicle = PED.GET_VEHICLE_PED_IS_IN(my_ped, false)
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(my_vehicle, true)
    end
end, CVModifiers.ACTIVE)
i18n.menus.slider(currentModifiersMenu, "CVM_TRACTION", {"vtraction"}, 0, 500, CVModifiers.Traction, 1, function(value)
    CVModifiers.Traction = value
end)
i18n.menus.slider(currentModifiersMenu, "CVM_LIGHTS", {"vlights"}, 0, 10000, CVModifiers.Lights * 100, 100, function(value)
    CVModifiers.Lights = value / 100
end)
i18n.menus.slider(currentModifiersMenu, "CVM_TORQUE", {"vtorque"}, -1000, 10000, CVModifiers.Torque * 100, 1, function(value)
    CVModifiers.Torque = value / 100
end)
i18n.menus.slider(currentModifiersMenu, "CVM_TRACTION", {"vtraction"}, 0, 500, CVModifiers.Traction, 1, function(value)
    CVModifiers.Traction = value
end)
----------------------------
-- NEARBY VEHICLES SECTION
----------------------------
local spawned_tows = {}
    -- NEARBY VEHICLES LIST SECTION
    local nearbyListMenu = i18n.menus.list(nearbyMenu, "NEARBY_VEHICLES_LIST", {})
    local refreshIntervalMs = 1000
    local nearbyViewVehicle = 0
    local nearbyListRefreshSelect = menu.slider_float(nearbyListMenu, "Refresh Interval (seconds)", {}, "How quickly to update list of vehicles? In seconds", 000, 1000, 100, 20, function(value)
        refreshIntervalMs = value * 100
    end)
    local SEATS = {
        [-2] = "Any Available Seat",
        [-1] = "Driver Seat",
        [0] = "Right Front Seat",
        [1] = "Left Rear Seat",
        [2] = "Right Rear Seat"
    }
    local nearbyVehicleMenus = {}
    local function _check_exists(vehicle)
        if not ENTITY.DOES_ENTITY_EXIST(vehicle) then
            menu.delete(nearbyVehicleMenus[vehicle].menu)
            nearbyVehicleMenus[vehicle] = nil
            return false
        end
        return true
    end
    function add_vehicle_to_list(vehicle)
        if nearbyVehicleMenus[vehicle] then return false end
        -- Ignore destroyed vehicles
        if ENTITY.GET_ENTITY_HEALTH(vehicle) == 0 then return false end
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
        -- Ignore moving driving ambient vehicles
        if driver > 0 and not PED.IS_PED_A_PLAYER(driver) and ENTITY.GET_ENTITY_SPEED(vehicle) > 0 then
            return
        end

        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        local name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
        local manu = VEHICLE._GET_MAKE_NAME_FROM_VEHICLE_MODEL(model)
        local prefix = (manu ~= "") and (manu .. " " .. name) or name

        local vehMenu = menu.list(nearbyListMenu, prefix, {}, "")
        local seatList = i18n.menus.list(vehMenu, "VEHLIST_SEATS", {})
        for x = -2, VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(model) - 2 do
            local text = SEATS[x] or ("Extra Seat" .. (x-2))
            menu.action(seatList, text, {}, "", function(_)
                if not _check_exists(vehicle) then
                    return
                end
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, x)
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                if PED.IS_PED_A_PLAYER(ped) then
                    i18n.toast("VEHLIST_SEAT_OCCUPIED")
                else
                    if ped > 0 then --Shove the ped driver to a different seat
                        PED.SET_PED_INTO_VEHICLE(ped, vehicle, -2)
                    end
                    -- Enter
                    PED.SET_PED_INTO_VEHICLE(my_ped, vehicle, x)
                end
            end)
        end
        nearbyVehicleMenus[vehicle] = { menu = vehMenu, prefix = prefix }
        return true
    end
    function humanReadableNumber(num)
        return tostring(math.floor(num)):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
    end

    -- Constantly update and re-populate nearby vehicle list:
    local lastTime = 0
    function refresh_nearby_list()
        if not menu.is_open() then
            return
        end
        local time = util.current_time_millis()
        if refreshIntervalMs > 0 and time - lastTime >= refreshIntervalMs then
            lastTime = time
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            local my_pos = ENTITY.GET_ENTITY_COORDS(my_ped, true)
            local nearbyVehicles = entities.get_all_vehicles_as_handles()
            --[[for vehicle, info in pairs(nearbyVehicleMenus) do
                if _check_exists(vehicle) then
                    local pos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
                    local dist = SYSTEM.VDIST(my_pos.x, my_pos.y, my_pos.z, pos.x, pos.y, pos.z)
                    -- TODO: Figure out why veh.menu is wrong?
                    menu.set_menu_name(info.menu, string.format("%s - %s meters", info.prefix, humanReadableNumber(dist)))
                end
            end--]]
            for _, m in pairs(nearbyVehicleMenus) do
                menu.delete(m.menu)
            end
            nearbyVehicleMenus = {}
            table.sort(nearbyVehicles, function(a,b)
                local pos_a = ENTITY.GET_ENTITY_COORDS(a, true)
                local pos_b = ENTITY.GET_ENTITY_COORDS(b, true)
                return SYSTEM.VDIST2(my_pos.x, my_pos.y, my_pos.z, pos_b.x, pos_b.y, pos_b.z) > SYSTEM.VDIST2(my_pos.x, my_pos.y, my_pos.z, pos_a.x, pos_a.y, pos_a.z)
            end)

            for _, vehicle in ipairs(nearbyVehicles) do
                if add_vehicle_to_list(vehicle) then
                    menu.on_tick_in_viewport(nearbyVehicleMenus[vehicle].menu, refresh_nearby_list)
                    menu.on_focus(nearbyVehicleMenus[vehicle].menu, function()
                        nearbyViewVehicle = vehicle
                    end)
                    local pos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
                    local dist = SYSTEM.VDIST(my_pos.x, my_pos.y, my_pos.z, pos.x, pos.y, pos.z)
                    -- TODO: Figure out why veh.menu is wrong?
                    menu.set_menu_name(nearbyVehicleMenus[vehicle].menu, string.format("%s - %s meters", nearbyVehicleMenus[vehicle].prefix, humanReadableNumber(dist)))
                    -- Reselect focused
                    if nearbyViewVehicle == vehicle then
                        menu.focus(nearbyVehicleMenus[vehicle].menu)
                    end
                end
            end
        end
    end
    menu.on_tick_in_viewport(nearbyListMenu, refresh_nearby_list)
    menu.on_tick_in_viewport(nearbyListRefreshSelect, refresh_nearby_list)
    -- On hover, cleanup:
    menu.on_focus(nearbyListMenu, function(_)
        for _, m in pairs(nearbyVehicleMenus) do
            menu.delete(m.menu)
        end
        nearbyVehicleMenus = {}
    end)
    -- END NEARBY VEHICLES LIST SECTION

menu.action(nearbyMenu, i18n.format("NEARBY_TOW_ALL_NAME"), {}, i18n.format("NEARBY_TOW_ALL_DESC", 30), function(sdfa)
    local pz = memory.alloc(8)
    load_hash(TOW_TRUCK_MODEL_1)
    load_hash(TOW_TRUCK_MODEL_2)
    for _, ent in ipairs(spawned_tows) do
        entities.delete_by_handle(ent)
    end
    spawned_tows = {}
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_pos = ENTITY.GET_ENTITY_COORDS(my_ped)
    local nearby_vehicles = {}
    for _, pVehicle in ipairs(entities.get_all_vehicles_as_pointers()) do
        local model = entities.get_model_hash(pVehicle)
        if model ~= TOW_TRUCK_MODEL_1 and model ~= TOW_TRUCK_MODEL_2 then
            local vehicle = entities.pointer_to_handle(pVehicle)
            if VEHICLE.IS_THIS_MODEL_A_CAR(model) then
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 8, 0.1)
                MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pz, true)
                pos.z = memory.read_float(pz)
                local dist = SYSTEM.VDIST2(my_pos.x, my_pos.y, my_pos.z, pos.x, pos.y, pos.z)
                table.insert(nearby_vehicles, { vehicle, dist, pos, model })
            end
        end
    end
    table.sort(nearby_vehicles, function(a, b) return b[2] > a[2] end)
    for i = 1,30 do
        if nearby_vehicles[i] then
            local vehicle = nearby_vehicles[i][1]
            local pos = nearby_vehicles[i][3]
            local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            
            math.randomseed(nearby_vehicles[i][4])
            local tow = entities.create_vehicle(math.random(2) == 2 and TOW_TRUCK_MODEL_1 or TOW_TRUCK_MODEL_2, pos, heading)
            add_vehicle_to_list(tow)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
            VEHICLE.ATTACH_VEHICLE_TO_TOW_TRUCK(tow, vehicle, false, 0, 0, 0)
            local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(tow, true)
            util.yield(1)
            TASK.TASK_VEHICLE_DRIVE_WANDER(driver, tow, 30.0, 786603)
            table.insert(spawned_tows, tow)
            table.insert(spawned_tows, driver)
        end
    end
end)
menu.action(nearbyMenu, i18n.format("NEARBY_TOW_CLEAR_NAME"), {}, "", function(_)
    for _, pVehicle in ipairs(entities.get_all_vehicles_as_pointers()) do
        local model = entities.get_model_hash(pVehicle)
        if model ~= TOW_TRUCK_MODEL_1 and model ~= TOW_TRUCK_MODEL_2 then
            local vehicle = entities.pointer_to_handle(pVehicle)
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver > 0 and not PED.IS_PED_A_PLAYER(driver) then
                entities.delete_by_handle(driver)
            end
            entities.delete_by_handle(vehicle)
        end
    end
end)
menu.action(nearbyMenu, i18n.format("NEARBY_CARGOBOB_ALL_NAME"), {}, i18n.format("NEARBY_CARGOBOB_ALL_DESC"), function(_)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local cargobobs = {}
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if VEHICLE.IS_THIS_MODEL_A_CAR(model) and not ENTITY.IS_ENTITY_ATTACHED_TO_ANY_VEHICLE(vehicle) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver == 0 or not PED.IS_PED_A_PLAYER(driver) then
                local pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
                local dist = SYSTEM.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 10000.0 then
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, false)
                    VEHICLE.SET_CARGOBOB_FORCE_DONT_DETACH_VEHICLE(cargobob, false)
                    VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(cargobob)
                    ENTITY.SET_ENTITY_COLLISION(cargobob, false, false)
                    ENTITY.SET_ENTITY_INVINCIBLE(cargobob, true)
                    table.insert(cargobobs, cargobob)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, 450.718 , 5566.614, 806.183, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
                    util.yield(100)
                end
            end
        end
    end
    util.yield(1000)
    util.create_tick_handler(function(_)
        local iterations = 0
        while true do
            for i, cargo in ipairs(cargobobs) do
                local v = VEHICLE.GET_VEHICLE_ATTACHED_TO_CARGOBOB(cargo)
                if v == 0 or VEHICLE.GET_HELI_MAIN_ROTOR_HEALTH(cargo) <= 0 or VEHICLE.GET_HELI_TAIL_ROTOR_HEALTH(cargo) < 0 or VEHICLE.GET_VEHICLE_ENGINE_HEALTH(cargo) <= 0 then
                    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(cargo, -1)
                    ENTITY.DETACH_ENTITY(cargo)
                    entities.delete_by_handle(driver)
                    entities.delete_by_handle(cargo)
                    table.remove(cargobobs, i)
                end
                util.yield(5000)
                iterations = iterations + 1
                if iterations >= 6 then
                    break
                end
            end
        end
        util.yield(3000)
        for _, cargo in ipairs(cargobobs) do
            ENTITY.SET_ENTITY_INVINCIBLE(cargo, false)
            VEHICLE.SET_CARGOBOB_FORCE_DONT_DETACH_VEHICLE(cargo, true)
        end
        return false
    end)
end)
-- dry violation but I really don't care about refactoring this
menu.action(nearbyMenu, i18n.format("NEARBY_CARGOBOB_ALL_MAGNET_NAME"), {}, i18n.format("NEARBY_CARGOBOB_ALL_DESC") .. "\n" .. i18n.format("NEARBY_CARGOBOB_ALL_MAGNET_EXTRA"), function(_)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local cargobobs = {}
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if VEHICLE.IS_THIS_MODEL_A_CAR(model) and not ENTITY.IS_ENTITY_ATTACHED_TO_ANY_VEHICLE(vehicle) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver == 0 or not PED.IS_PED_A_PLAYER(driver) then
                local pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
                local dist = SYSTEM.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 10000.0 then
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, true)
                    VEHICLE.SET_CARGOBOB_FORCE_DONT_DETACH_VEHICLE(cargobob, false)
                    VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(cargobob)
                    ENTITY.SET_ENTITY_COLLISION(cargobob, false, false)
                    ENTITY.SET_ENTITY_INVINCIBLE(cargobob, true)
                    table.insert(cargobobs, cargobob)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, 450.718 , 5566.614, 806.183, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
                    util.yield(100)
                end
            end
        end
    end
    util.yield(1000)
    util.create_tick_handler(function(_)
        local iterations = 0
        while true do
            for i, cargo in ipairs(cargobobs) do
                local v = VEHICLE.GET_VEHICLE_ATTACHED_TO_CARGOBOB(cargo)
                if v == 0 or VEHICLE.GET_HELI_MAIN_ROTOR_HEALTH(cargo) <= 0 or VEHICLE.GET_HELI_TAIL_ROTOR_HEALTH(cargo) < 0 or VEHICLE.GET_VEHICLE_ENGINE_HEALTH(cargo) <= 0 then
                    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(cargo, -1)
                    ENTITY.DETACH_ENTITY(cargo)
                    entities.delete_by_handle(driver)
                    entities.delete_by_handle(cargo)
                    table.remove(cargobobs, i)
                end
                util.yield(5000)
                iterations = iterations + 1
                if iterations >= 6 then
                    break
                end
            end
        end
        util.yield(3000)
        for _, cargo in ipairs(cargobobs) do
            ENTITY.SET_ENTITY_INVINCIBLE(cargo, false)
            VEHICLE.SET_CARGOBOB_FORCE_DONT_DETACH_VEHICLE(cargo, true)
        end
        return false
    end)
end)
menu.action(nearbyMenu, i18n.format("NEARBY_CARGOBOB_CLEAR_NAME"), {}, "", function(sdfa)
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if model == CARGOBOB_MODEL then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver > 0 and not PED.IS_PED_A_PLAYER(driver) then
                entities.delete_by_handle(driver)
            end
            entities.delete_by_handle(vehicle)
        end
    end
end)
menu.click_slider(nearbyMenu, i18n.format("NEARBY_ALL_CLEAR_NAME"), {"clearvehicles"}, i18n.format("NEARBY_ALL_CLEAR_DESC"), 50, 2000, 100, 100, function(range)
    range = range * range
    local vehicles = entities.get_all_vehicles_as_handles()
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(my_ped, 1)

    local count = 0
    for _, vehicle in ipairs(vehicles) do
        local pos2 = ENTITY.GET_ENTITY_COORDS(vehicles, 1)
        local dist = SYSTEM.VDIST(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
        if dist <= range then
            local has_control = false
            local loops = 5
            while not has_control do
                has_control = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
                loops = loops - 1
                -- wait for control
                util.yield(15)
                if loops <= 0 then
                    break
                end
            end
            entities.delete_by_handle(vehicle)
            count = count + 1
        end
    end
    i18n.toast("NEARBY_ALL_CLEAR_SUCCESS", count)
end)
menu.action(nearbyMenu, i18n.format("NEARBY_EXPLODE_RANDOM_NAME"), {}, i18n.format("NEARBY_EXPLODE_RANDOM_DESC"), function(_)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(my_ped, 1)
    local vehs = {}
    for _, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if VEHICLE.IS_THIS_MODEL_A_CAR(model) and not ENTITY.IS_ENTITY_ATTACHED_TO_ANY_VEHICLE(vehicle) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(vehicle) > 0 then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver == 0 or not PED.IS_PED_A_PLAYER(driver) then
                local pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
                local dist = SYSTEM.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 5000.0 then
                    table.insert(vehs, { vehicle, dist })
                end
            end
        end
    end
    if #vehs > 0 then
        table.sort(vehs, function(a, b) return b[2] > a[2] end)
        local vehicle = vehs[1][1]
        util.create_thread(function(_)
            VEHICLE.SET_VEHICLE_ALARM(vehicle, true)
            VEHICLE.START_VEHICLE_ALARM(vehicle)
            util.yield(5000)
            pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
            FIRE.ADD_EXPLOSION(pos2.x, pos2.y, pos2.z + 1.0, 26, 60, true, true, 0.0)
        end)
    end
end)
menu.action(nearbyMenu, i18n.format("NEARBY_HIJACK_ALL_NAME"), {"hijackall"}, i18n.format("NEARBY_HIJACK_ALL_DESC"), function(_)
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        local has_control = false
        local loops = 5
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, false, true)
        while not has_control do
            has_control = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            loops = loops - 1
            -- wait for control
            util.yield(15)
            if loops <= 0 then
                break
            end
        end
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 0.0, 0.1)
        ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
        local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
        PED.SET_PED_AS_ENEMY(ped, true)
        TASK.TASK_ENTER_VEHICLE(ped, vehicle, -1, -1, 1.0, 24)
        TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
        PED.SET_PED_KEEP_TASK(ped, true)
    end
end)
menu.action(nearbyMenu, i18n.format("NEARBY_HONK_NAME"), {"honkall"}, i18n.format("NEARBY_HONK_DESC"), function(_)
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        local has_control = false
        local loops = 5
        while not has_control do
            has_control = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            loops = loops - 1
            -- wait for control
            util.yield(15)
            if loops <= 0 then
                break
            end
        end
        VEHICLE.SET_VEHICLE_ALARM(vehicle, true)
        VEHICLE.START_VEHICLE_ALARM(vehicle)
        VEHICLE.START_VEHICLE_HORN(vehicle, 50000, 0)
    end
end)
local spinningCars = false
local spinningSpeed = 5.0
menu.toggle(nearbyMenu, i18n.format("SPINNING_CARS_NAME"), {}, i18n.format("SPINNING_CARS_DESC"), function(on)
    spinningCars = on
end, spinningCars)
menu.slider(nearbyMenu, "Spinning Cars Speed", {"spinningspeed"}, "", 0, 300.0, spinningSpeed * 10, 10, function(value)
    if value == 0 then
        spinningSpeed = 0.1
    else
        spinningSpeed = value / 10
    end
end)

----------------------------
-- ALL PLAYERS SECTION
----------------------------

local allNearOnly = true
menu.toggle(allPlayersMenu, i18n.format("ALL_NEAR_ONLY_NAME"), {"allnearby"}, i18n.format("ALL_NEAR_ONLY_DESC"), function(on)
    allNearOnly = on
end, allNearOnly)

function control_all_vehicles(callback)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        control_vehicle(pid, function(vehicle)
            callback(pid, vehicle)
        end, { near_only = allNearOnly, loops = 10, silent = true })
    end
end

menu.action(allPlayersMenu, i18n.format("VEH_SPAWN_VEHICLE_NAME"), {"jvspawnall"}, i18n.format("ALL_SPAWN_DESC"), function(_)
    menu.show_command_box("jvspawnall ")
end, function(args)
    local model = util.joaat(args)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_A_VEHICLE(model) then
        load_hash(model)
        local cur_players = players.list(true, true, true)
        for _, pid in pairs(cur_players) do
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
            local vehicle = entities.create_vehicle(model, pos, heading)
            add_vehicle_to_list(vehicle)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    else
        util.toast("Could not find that vehicle.")
    end
end)

menu.action(allPlayersMenu, i18n.format("LSC_UPGRADE_NAME"), {"upgradevehicle"}, i18n.format("LSC_UPGRADE_DESC"), function(_)
    control_all_vehicles(function(pid, vehicle)
        VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            for x = 0, 49 do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.SET_VEHICLE_MOD(vehicle, 15, 45) -- re-set horn
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 5)
            for x = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, true)
            end
    end)
end)

menu.action(allPlayersMenu, i18n.format("LSC_PERFORMANCE_UPGRADE_NAME"), {"performanceupgradevehicle"}, i18n.format("LSC_PERFORMANCE_UPGRADE_DESC"), function(_)
    control_all_vehicles(function(pid, vehicle)
        local mods = { 11, 12, 13, 16 }
        for x in ipairs(mods) do
            local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
            VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
        end
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
    end)
end)
menu.action(allPlayersMenu, i18n.format("VEH_CLEAN_NAME"), {"cleanall"}, i18n.format("ALL_CLEAN_DESC"), function(_)
    control_all_vehicles(function(pid, vehicle)
        GRAPHICS.REMOVE_DECALS_FROM_VEHICLE(vehicle)
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
    end)
end)

menu.action(allPlayersMenu, i18n.format("VEH_REPAIR_NAME"), {"repairall"}, i18n.format("ALL_REPAIR_DESC"), function(_)
    control_all_vehicles(function(pid, vehicle)
        VEHICLE.SET_VEHICLE_FIXED(vehicle)
    end)
end)

menu.toggle(allPlayersMenu, i18n.format("VEH_TOGGLE_GODMODE_NAME"), {"vehgodall"}, i18n.format("VEH_TOGGLE_GODMODE_DESC"), function(on)
    control_all_vehicles(function(pid, vehicle)
        ENTITY.SET_ENTITY_INVINCIBLE(vehicle, on)
    end)
end, false)

menu.action(allPlayersMenu, i18n.format("VEH_LICENSE_NAME"), {"setlicenseplateall"}, i18n.format("VEH_LICENSE_DESC"), function(_)
    menu.show_command_box("setlicenseplateall ")
end, function(args)
    control_all_vehicles(function(pid, vehicle)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, args)
    end)
end, false)

----------------------------
-- AUTODRIVE SECTION
----------------------------

local drive_speed = 50.0
local drive_style = 0
local is_driving = false

local DRIVING_STYLES = { -- flags, style name, style description 
    { 786603,       i18n.format("AUTODRIVE_STYLE_NORMAL") },
    { 6,            i18n.format("AUTODRIVE_STYLE_AVOID_EXTREMELY") },
    { 5,            i18n.format("AUTODRIVE_STYLE_OVERTAKE") },
    { 1074528293,   i18n.format("AUTODRIVE_STYLE_RUSHED") },
    { 2883621,      i18n.format("AUTODRIVE_STYLE_IGNORE") },
    { 786468,       i18n.format("AUTODRIVE_STYLE_AVOID") },
    { 1076,         i18n.format("AUTODRIVE_STYLE_REVERSED") },
    { 8388614,      i18n.format("AUTODRIVE_STYLE_GOOD") },
    { 16777216,     i18n.format("AUTODRIVE_STYLE_MOST_EFFICIENT"), i18n.format("AUTODRIVE_STYLE_MOST_EFFICIENT_DESC") },
    { 787260,       i18n.format("AUTODRIVE_STYLE_QUICK"), i18n.format("AUTODRIVE_STYLE_QUICK_DESC") },
    { 536871299,    i18n.format("AUTODRIVE_STYLE_NERVOUS"), i18n.format("AUTODRIVE_STYLE_NERVOUS_DESC") },
    { 2147483647,   "Untested, Everything", "All options turned on. Probably awful" },
    { 0,            "Untested, Nothing", "All options turned off. Also probably awful"},
    { 7791,         "Untested. Meh", "Meh. Just used in rockstar scripts. unknown."}
}

-- Grabs the driver, first checks attachments (tow, cargo, etc) then driver seat
function get_my_driver()
    local vehicle = entities.get_user_vehicle_as_handle()
    local entity = ENTITY.GET_ENTITY_ATTACHED_TO(vehicle)
    if entity > 0 and ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(entity, -1)
        if driver > 0 then
            return driver, entity
        end
    end

    return VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1), vehicle
end
local chauffeurMenu = menu.list(autodriveMenu, i18n.format("AUTODRIVE_CHAUFFEUR_NAME"), {"chauffeur"}, i18n.format("AUTODRIVE_CHAUFFEUR_DESC"))
local styleMenu = menu.list(autodriveMenu, i18n.format("AUTODRIVE_STYLE_NAME"), {}, i18n.format("AUTODRIVE_STYLE_DESC"))

for _, style in pairs(DRIVING_STYLES) do
    local desc = i18n.format("AUTODRIVE_STYLE_INDV_DESC") .. " " .. style[2]
    if style[3] then
        desc = desc .. "\n" .. style[3]
    end
    menu.action(styleMenu, style[2], { }, desc, function(_)
        driving_mode = style[1]
        if is_driving then
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.SET_DRIVE_TASK_DRIVING_STYLE(ped, style[1])
            PED.SET_DRIVER_ABILITY(ped, 1.0)
            PED.SET_DRIVER_AGGRESSIVENESS(ped, 0.6)
        end
        i18n.toast("AUTODRIVE_STYLE_INDV_SUCCESS", style[2])
    end)
end

menu.slider(autodriveMenu, i18n.format("AUTODRIVE_SPEED_NAME"), {"setaispeed"}, "", 0, 200, drive_speed, 5.0, function(speed, prev)
    drive_speed = speed
end)


i18n.menus.toggle(autodriveMenu, "AUTODRIVE_SMART", {"smartdrive"}, function(on)
    smartAutodrive = on
    if not on then
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        TASK.CLEAR_PED_TASKS(my_ped)
    end
end, smartAutodrive)

menu.divider(autodriveMenu, i18n.format("AUTODRIVE_ACTIONS_DIVIDER"))

menu.action(autodriveMenu, i18n.format("AUTODRIVE_DRIVE_WAYPOINT_NAME"), {"aiwaypoint"}, "", function(v)
    local ped, vehicle = get_my_driver()
    is_driving = true

    local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
    get_waypoint_pos(function(pos)
        TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, pos.x, pos.y, pos.z, drive_speed, 1.0, vehicleModel, drive_style, 5.0, 1.0)
        PED.SET_DRIVER_ABILITY(ped, 1.0)
        PED.SET_DRIVER_AGGRESSIVENESS(ped, 0.6)
    end)
end)

local drivetoPlayerMenu = menu.list(autodriveMenu, i18n.format("AUTODRIVE_DRIVE_TO_PLAYER_NAME"), {"drivetoplayer"})
local drivetoPlayers = {}
setup_choose_player_menu(drivetoPlayerMenu, drivetoPlayers, function(target_pid, name)
    return menu.action(drivetoPlayerMenu, name, {"driveto"}, i18n.format("AUTODRIVE_DRIVE_TO_PLAYER_INDV_DESC"), function(_)
        local ped, vehicle = get_my_driver()
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target_pid)
        local hash = ENTITY.GET_ENTITY_MODEL(vehicle)
        util.create_tick_handler(function(_)
            local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
            TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, target_pos.x, target_pos.y, target_pos.z, 100, 5, hash, 6, 1.0, 1.0)
            util.yield(5000)
            return ENTITY.DOES_ENTITY_EXIST(target_ped) and ENTITY.DOES_ENTITY_EXIST(ped) and TASK.GET_SCRIPT_TASK_STATUS(ped, 0x93A5526E) < 7
        end)
    end)
end)

menu.action(autodriveMenu, i18n.format("AUTODRIVE_WANDER_HOVER_NAME"), {"aiwander"}, i18n.format("AUTODRIVE_WANDER_HOVER_DESC"), function(v)
    local ped, vehicle = get_my_driver()
    is_driving = true

    TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, drive_speed, drive_style)
    PED.SET_DRIVER_ABILITY(ped, 1.0)
    PED.SET_DRIVER_AGGRESSIVENESS(ped, 0.6)
end)

menu.action(autodriveMenu, i18n.format("AUTODRIVE_STOP_NAME"), {"aistop"}, "", function(v)
    local ped = get_my_driver()
    is_driving = false

    TASK.CLEAR_PED_TASKS(ped)
end)

--------------------------------
-- AUTODRIVE SECTION: Chauffeur
---------------------------------

local autodriveDriver = 0
local autodriveVehicle = 0
local autodriveOnlyWhenOntop = false
menu.toggle(chauffeurMenu, i18n.format("AUTODRIVE_CHAUFFEUR_STOP_WHEN_FALLEN_NAME"), {}, i18n.format("AUTODRIVE_CHAUFFEUR_STOP_WHEN_FALLEN_DESC"), function(on)
    autodriveOnlyWhenOntop = on
end, autodriveOnlyWhenOntop)
menu.action(chauffeurMenu, i18n.format("AUTODRIVE_CHAUFFEUR_SPAWN_DRIVER_NAME"), {}, i18n.format("AUTODRIVE_CHAUFFEUR_SPAWN_DRIVER_DESC"), function(_)
    local vehicle = get_player_vehicle_in_control(players.user())
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    if vehicle > 0 then
        if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
            entities.delete_by_handle(autodriveDriver)
        end
        ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
        if driver == 0 then
            -- teleport them in if free spot
            util.toast("New driver spawned, ready")
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -5.0, 0.0, 0.6)
            driver = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
            for _ = 1, 5 do
                TASK.TASK_WARP_PED_INTO_VEHICLE(driver, vehicle, -1)
                util.yield(100)
            end
        elseif PED.IS_PED_A_PLAYER(driver) then
            -- hijack if its a player
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 0.0, 0.1)
            if driver == my_ped then
                TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, vehicle, -2)
                driver = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
                VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
                TASK.TASK_VEHICLE_DRIVE_WANDER(driver, vehicle, 100.0, 2883621)
                PED.SET_PED_FLEE_ATTRIBUTES(driver, 46, true)
                for _ = 1, 5 do
                    TASK.TASK_WARP_PED_INTO_VEHICLE(driver, vehicle, -1)
                    util.yield(100)
                end
                util.toast("Driver ready.")
            else
                local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
                TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
                PED.SET_PED_FLEE_ATTRIBUTES(ped, 46, true)
                local tries = 25
                vehicle = 0
                while tries > 0 and vehicle == 0 do
                    vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    util.yield(1000)
                    tries = tries - 1
                end
                if vehicle == 0 then
                    entities.delete_by_handle(ped)
                    util.toast("Driver failed to acquire driver seat in time.")
                    return
                end
                PED.SET_PED_AS_ENEMY(ped, false)
                driver = ped
                util.toast("New driver spawned & ready")
            end
        else
            -- use the existing driver
            util.toast("Using existing vehicle driver, ready")
        end

        if vehicle > 0 then
            autodriveDriver = driver
            autodriveVehicle = vehicle
            TASK.TASK_VEHICLE_TEMP_ACTION(autodriveDriver, vehicle, 1, 10000)
        elseif ENTITY.DOES_ENTITY_EXIST(driver) then
            entities.delete_by_handle(driver)
        end
    else
        i18n.toast("PLAYER_OUT_OF_RANGE")
    end
end)
menu.action(chauffeurMenu, "Delete Driver", {}, "", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        entities.delete_by_handle(autodriveDriver)
    else
        i18n.toast("AUTODRIVE_CHAUFFEUR_NO_DRIVER")
    end
    autodriveDriver = 0
end)
menu.action(chauffeurMenu, i18n.format("AUTODRIVE_STOP_NAME"), {}, "Makes the driver stop the vehicle", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(autodriveDriver, true)
        if vehicle == 0 then
            i18n.toast("AUTODRIVE_DRIVER_UNAVAILABLE")
        else
            TASK.TASK_VEHICLE_TEMP_ACTION(autodriveDriver, vehicle, 1, 100000)
        end
    else
        autodriveDriver = 0
        i18n.toast("AUTODRIVE_DRIVER_NONE")
    end
end)
menu.divider(chauffeurMenu, "Destinations")
menu.action(chauffeurMenu, i18n.format("AUTODRIVE_DRIVE_WAYPOINT_NAME"), {}, "", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        get_waypoint_pos(function(waypoint_pos)
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(autodriveDriver, true)
            if vehicle == 0 then
                i18n.toast("AUTODRIVE_DRIVER_UNAVAILABLE")
            else
                local model = ENTITY.GET_ENTITY_MODEL(vehicle)
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(autodriveDriver, vehicle, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, model, 6, 5.0, 1.0)
            end
        end)
    else
        autodriveDriver = 0
        i18n.toast("AUTODRIVE_RIVER_NONE")
    end
end)
menu.action(chauffeurMenu, "Wander", {}, "", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(autodriveDriver, true)
        if vehicle == 0 then
            i18n.toast("AUTODRIVE_DRIVER_UNAVAILABLE")
        else
            TASK.TASK_VEHICLE_DRIVE_WANDER(autodriveDriver, vehicle, 40.0, 6)
        end
    else
        autodriveDriver = 0
        i18n.toast("AUTODRIVE_RIVER_NONE")
    end
end)

----------------------------
-- Root Menu Continue
----------------------------

local cruiseControl = {
    enabled = false,
    currentVel = -1
}
i18n.menus.toggle(menu.my_root(), "CRUISE_CONTROL", {"cruisecontrol"}, function(on)
    cruiseControl.enabled = on
    cruiseControl.currentVel = -1
end, cruiseControl.enabled)

local DRIVE_ON_WATER_MODEL = util.joaat("prop_lev_des_barge_02")
local driveOnWaterEntity = nil
local driveOnWaterNoWaterTicks = 0

-- Cleanup all actions
util.on_stop(function()
    local ped, vehicle = get_my_driver()

    TASK.CLEAR_PED_TASKS(ped)
    TASK._CLEAR_VEHICLE_TASKS(vehicle)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        entities.delete_by_handle(previewVehicle)
    end
    if ENTITY.DOES_ENTITY_EXIST(driveClone.vehicle) then
        entities.delete_by_handle(driveClone.vehicle)
    end
    if driveOnWaterEntity then
        entities.delete_by_handle(driveOnWaterEntity)
    end
end)

-- Setup player menus:
-- Grab all existing players in session
for _, pid in pairs(players.list(true, true, true)) do
    setup_player_menu(pid)
end
-- Add all new players
players.on_join(function(pid) setup_player_menu(pid) end)

-- Used for smart autodrive to know when to stop autodriving
local MOVEMENT_CONTROLS = table.freeze({
    59, 60, 61, 62, 63, 64, 71, 72, 75, 76, 87, 88, 89, 90, 102, 106, 107, 108, 109, 110, 111, 112, 113, 122, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139
})

local spinHeading = 0 -- For all vehicles: spin
local smartAutoDriveData = {
    paused = false,
    lastSetTask = 0,
    lastWaypoint = nil
}


local fHeight = memory.alloc(4)
menu.toggle_loop(menu.my_root(), "Drive on Water", {}, "Allow your vehicle to drive on top of water", function()
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_vehicle = PED.GET_VEHICLE_PED_IS_IN(my_ped, false)
    if my_vehicle then
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_vehicle, 0, 5.0, -1.0)
        if WATER.GET_WATER_HEIGHT(pos.x, pos.y, pos.z, fHeight) then
            if not driveOnWaterEntity then
                driveOnWaterEntity = entities.create_object(DRIVE_ON_WATER_MODEL, { x = 0, y = 0, z = 0})
                ENTITY.FREEZE_ENTITY_POSITION(driveOnWaterEntity, true)
                ENTITY.SET_ENTITY_COLLISION(driveOnWaterEntity, true, false)
                ENTITY.SET_ENTITY_VISIBLE(driveOnWaterEntity, false)
                NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.OBJ_TO_NET(driveOnWaterEntity), false)
            end
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(driveOnWaterEntity) then
		        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(driveOnWaterEntity)
            end
            local heading = ENTITY.GET_ENTITY_HEADING(my_vehicle)
            local height = memory.read_float(fHeight) - 1.25
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(driveOnWaterEntity, pos.x, pos.y, height)
            ENTITY.SET_ENTITY_HEADING(driveOnWaterEntity, heading)
            driveOnWaterNoWaterTicks = 0
        elseif driveOnWaterEntity then
            if driveOnWaterNoWaterTicks > 100 then
                entities.delete_by_handle(driveOnWaterEntity)
                driveOnWaterEntity = nil
            else
                driveOnWaterNoWaterTicks = driveOnWaterNoWaterTicks + 1
            end
        end
    end
end, function()
    if driveOnWaterEntity then
        entities.delete_by_handle(driveOnWaterEntity)
    end
    driveOnWaterEntity = nil
end)

while true do
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_vehicle = PED.GET_VEHICLE_PED_IS_IN(my_ped, false)

    -- if driveOnWaterEntity and my_vehicle then
    --     local pos = ENTITY.GET_ENTITY_COORDS(my_vehicle)
    --     local heading = ENTITY.GET_ENTITY_HEADING(my_vehicle)
    --     local status, z = util.get_ground_z(pos.x, pos.y, pos.z + 20)
    --     if status then
    --         ENTITY.SET_ENTITY_COORDS_NO_OFFSET(driveOnWaterEntity, pos.x, pos.y, z)
    --     end
    --     ENTITY.SET_ENTITY_HEADING(driveOnWaterEntity, heading)
    -- end
    
    if my_vehicle > 0 then
        if CVModifiers.KeepUpright and ENTITY.GET_ENTITY_UPRIGHT_VALUE(my_vehicle) < .3 then
            local rot = ENTITY.GET_ENTITY_ROTATION(my_vehicle)
            ENTITY.SET_ENTITY_ROTATION(my_vehicle, 0, rot.y, rot.z)
        end
        if CVModifiers.ACTIVE then
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(my_vehicle, CVModifiers.Torque)
            VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(my_vehicle, CVModifiers.Lights)
            -- VEHICLE._SET_TYRE_TRACTION_LOSS_MULTIPLIER(my_vehicle, CVModifiers.Traction)
            if CVModifiers.Traction ~= 1.0 then
                VEHICLE.SET_VEHICLE_REDUCE_GRIP(my_vehicle, true)
            else
                VEHICLE.SET_VEHICLE_REDUCE_GRIP(my_vehicle, false)
            end
            VEHICLE._SET_VEHICLE_REDUCE_TRACTION(my_vehicle, CVModifiers.Traction)
        end
    end
    if smartAutodrive and my_vehicle > 0 then
        if smartAutoDriveData.paused then
            if ENTITY.GET_ENTITY_SPEED(my_vehicle) <= 15 then
                smartAutoDriveData.paused = false
            end
        else
            for _, control in ipairs(MOVEMENT_CONTROLS) do
                if PAD.IS_CONTROL_PRESSED(2, control) then
                    TASK.CLEAR_PED_TASKS(my_ped)
                    smartAutoDriveData.paused = true
                    break
                end
            end
            if not smartAutoDriveData.paused then
                local waypoint = get_waypoint_pos(nil, true)
                if waypoint then
                    lastWaypoint = waypoint
                    local model = ENTITY.GET_ENTITY_MODEL(my_vehicle)
                    local now = MISC.GET_GAME_TIMER()
                    if now - smartAutoDriveData.lastSetTask > 5000 then
                        PED.SET_DRIVER_ABILITY(my_ped, 1.0)
                        PED.SET_DRIVER_AGGRESSIVENESS(my_ped, 0.6)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD(my_ped, my_vehicle, waypoint.x, waypoint.y, waypoint.z, 100, 5, model, 787004, 15.0, 1.0)
                        smartAutoDriveData.lastSetTask = now
                    end
                elseif smartAutoDriveData.lastWaypoint then
                    if ENTITY.IS_ENTITY_AT_COORD(my_vehicle, smartAutoDriveData.lastWaypoint.x, smartAutoDriveData.lastWaypoint.y, smartAutoDriveData.lastWaypoint.z, 10.0, 10.0, 10.0, 0, 1, 0) then
                        smartAutoDriveData.lastWaypoint = nil
                        smartAutoDriveData.paused = true
                        VEHICLE.BRING_VEHICLE_TO_HALT(my_vehicle, 5.0, 1)
                        TASK.CLEAR_PED_TASKS(my_ped)
                    end
                end
            end
        end
    elseif autodriveDriver > 0 and autodriveOnlyWhenOntop then
        local selfOntop = PED.IS_PED_ON_VEHICLE(my_ped)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(autodriveVehicle)
        -- If player is not on top of the vehicle and they aren't in the autodriven vehicle, stop it
        if not selfOntop and my_vehicle ~= autodriveVehicle then
            -- VEHICLE.BRING_VEHICLE_TO_HALT(autodriveVehicle, 2.0, 20, false)
            ENTITY.SET_ENTITY_VELOCITY(autodriveVehicle, 0.0, 0.0, 0.0)
        end
    elseif cruiseControl.enabled then
        -- Taken from gtav chaos mod (https://github.com/gta-chaos-mod/ChaosModV/blob/b6422130c4dc27496d5711a5880b783649384950/ChaosMod/Effects/db/Vehs/VehsCruiseControl.cpp)
        if my_vehicle > 0 then 
            if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(my_vehicle) then
                local speed = ENTITY.GET_ENTITY_SPEED(my_vehicle)
                if speed > cruiseControl.currentVel or speed < cruiseControl.currentVel / 2 or speed < 1 then
                    cruiseControl.currentVel = speed
                elseif speed < cruiseControl.currentVel then
                    local isReversing = ENTITY.GET_ENTITY_SPEED_VECTOR(my_vehicle, true).y < 0
                    VEHICLE.SET_VEHICLE_FORWARD_SPEED(my_vehicle, isReversing and -cruiseControl.currentVel or cruiseControl.currentVel);
                end
            end
        else
            cruiseControl.currentVel = -1
        end
    end

    if spinningCars then
        spinHeading = spinHeading + spinningSpeed
        if spinHeading > 360 then spinHeading = 0.0 end
        for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
            ENTITY.SET_ENTITY_HEADING(vehicle, spinHeading)
        end
    end

    util.yield()
end
