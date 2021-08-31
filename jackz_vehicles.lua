-- Vehicle Options
-- Created By Jackz
local SCRIPT = "jackz_vehicles"
local VERSION = "2.3.4"
local CHANGELOG_PATH = filesystem.stand_dir() .. "/Cache/changelog_" .. SCRIPT .. ".txt"
-- Check for updates & auto-update:
-- Remove these lines if you want to disable update-checks & auto-updates: (7-54)
async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        -- Remove this block (lines 15-31) to disable auto updates
        async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT .. "&since=" .. VERSION, function(result)
            local file = io.open(CHANGELOG_PATH, "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            io.close(file)
        end)
        async_http.dispatch()
        async_http.init("jackz.me", "/stand/lua/" .. SCRIPT .. ".lua", function(result)
            local file = io.open(filesystem.scripts_dir() .. "/" .. SCRIPT .. ".lua", "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            io.close(file)

            util.toast(SCRIPT .. " was automatically updated to V" .. chunks[2] .. "\nRestart script to load new update.", TOAST_ALL)
        end, function(e)
            util.toast(SCRIPT .. ": Failed to automatically update to V" .. chunks[2] .. ".\nPlease download latest update manually.\nhttps://jackz.me/stand/get-latest-zip", 2)
            util.stop_script()
        end)
        async_http.dispatch()
    end
end)
async_http.dispatch()
local WaitingLibsDownload = false
function try_load_lib(lib, globalName)
    local status, f = pcall(require, string.sub(lib, 0, #lib - 4))
    if not status then
        WaitingLibsDownload = true
        async_http.init("jackz.me", "/stand/libs/" .. lib, function(result)
            -- FIXME: somehow only writing 1 KB file
            local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
            io.output(file)
            io.write(result)
            io.flush() -- redudant, probably?
            io.close(file)
            util.toast(SCRIPT .. ": Automatically downloaded missing lib '" .. lib .. "'")
            if globalName then
                _G[globalName] = require(string.sub(lib, 0, #lib - 4))
            end
            WaitingLibsDownload = false
        end, function(e)
            util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
            util.stop_script()
        end)
        async_http.dispatch()
    elseif globalName then
        _G[globalName] = f
    end
end
try_load_lib("natives-1627063482.lua")
try_load_lib("json.lua", "json")
-- If script is actively downloading new update, wait:
while WaitingLibsDownload do
    util.yield()
end
-- Check if there is any changelogs (just auto-updated)
if filesystem.exists(CHANGELOG_PATH) then
    local file = io.open(CHANGELOG_PATH, "r")
    io.input(file)
    local text = io.read("*all")
    util.toast("Changelog for " .. SCRIPT .. ": \n" .. text)
    io.close(file)
    os.remove(CHANGELOG_PATH)
end
os.remove(filesystem.scripts_dir() .. "/vehicle_options.lua")
-- Per-player options
local options = {}

local DOOR_NAMES = {
    "Front Left", "Front Right",
    "Back Left", "Back Right",
    "Engine", "Trunk",
    "Back", "Back 2",
}
-- Subtract index by 1 to get modType (ty lua)
local MOD_TYPES = {
    [1] = "Spoilers",
    [2] = "Front Bumper",
    [3] = "Rear Bumper",
    [4] = "Side Skirt",
    [5] = "Exhaust",
    [6] = "Frame",
    [7] = "Grille",
    [8] = "Hood",
    [9] = "Fender",
    [10] = "Right Fender",
    [11] = "Roof",
    [12] = "Engine",
    [13] = "Brakes",
    [14] = "Transmission",
    [15] = "Horns",
    [16] = "Suspension",
    [17] = "Armor",
    [24] = "Wheels Design",
    [25] = "Motorcycle Back Wheel Design",
    [26] = "Plate Holders",
    [28] = "Trim Design",
    [29] = "Ornaments",
    [31] = "Dial Design",
    [34] = "Steering Wheel",
    [35] = "Shifter Leavers",
    [36] = "Plaques",
    [39] = "Hydraulics",
    [49] = "Livery"
}
-- Subtract index by 1 to get modType (ty lua)
local TOGGLE_MOD_TYPES = {
    [18] = "UNK17",
    [19] = "Turbo Turning",
    [20] = "UNK19",
    [21] = "Tire Smoke",
    [22] = "UNK21",
    [23] = "Xenon Headlights"
}
local VEHICLE_TYPES = {
    "Compacts",  
	"Sedans",
	"SUVs",
	"Coupes",
	"Muscle",
	"Sports Classics",
	"Sports",
	"Super",
	"Motorcycles",
	"Off-road",
	"Industrial",
	"Utility",
	"Vans",
	"Cycles",
	"Boats",
	"Helicopters",
	"Planes",
	"Service",
	"Emergency",
	"Military",
	"Commercial",
	"Trains"
}
local vehicleDir = filesystem.stand_dir() .. "/Vehicles/"
if not filesystem.exists(vehicleDir) then
    filesystem.mkdir(vehicleDir)
end
local VEHICLE_SAVEDATA_FORMAT_VERSION = "JSTAND 1.1"
local TOW_TRUCK_MODEL_1 = util.joaat("towtruck")
local TOW_TRUCK_MODEL_2 = util.joaat("towtruck2")
local NEON_INDICES = { "Left", "Right", "Front", "Back"}

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
        util.toast("Player is too far, auto-spectating for upto 3s.")
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
        -- To prevent a hard 3s loop, we keep waiting upto 3s or until vehicle is acquired
        local loop = (opts and opts.loops ~= nil) and opts.loops or 30 -- 3000 / 100
        while vehicle == 0 and loop > 0 do
            util.yield(100)
            vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
            loop = loop - 1
        end
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

local CAB_MODEL = util.joaat("phantom")
local TRAILER_MODEL = util.joaat("tr2")
function spawn_cab_and_trailer_for_vehicle(vehicle, rampDown)
    STREAMING.REQUEST_MODEL(CAB_MODEL)
    STREAMING.REQUEST_MODEL(TRAILER_MODEL)
    while not STREAMING.HAS_MODEL_LOADED(TRAILER_MODEL) do
        util.yield()
    end
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    local cabPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -5.0, 10, 0.0)
    local trailerPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -5.0, 0, 0.0)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)

    local cab = util.create_vehicle(CAB_MODEL, cabPos, heading)
    local trailer = util.create_vehicle(TRAILER_MODEL, trailerPos, heading)
    if rampDown then
        VEHICLE.SET_VEHICLE_DOOR_OPEN(trailer, 5, 0, 0)
    end
    VEHICLE.ATTACH_VEHICLE_TO_TRAILER(cab, trailer, 5)
    util.yield(2)
    VEHICLE.ATTACH_VEHICLE_ON_TO_TRAILER(vehicle, trailer, 0, 0, -2.0, 0, 0, 0.0, 0, 0, 0, 0.0)
    ENTITY.DETACH_ENTITY(vehicle)
    util.yield(1)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(cab, true)
    util.yield(1)
    return cab, driver
end

local CARGOBOB_MODEL = util.joaat("cargobob")
function spawn_cargobob_for_vehicle(vehicle, useMagnet)
    STREAMING.REQUEST_MODEL(CARGOBOB_MODEL)
    while not STREAMING.HAS_MODEL_LOADED(CARGOBOB_MODEL) do
        util.yield()
    end
    local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
    ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0, 8.0)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 10)
    local cargobob = util.create_vehicle(CARGOBOB_MODEL, pos, heading)
    VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargobob, true)
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
                util.delete_entity(cargobob)
            end
            if ENTITY.DOES_ENTITY_EXIST(driver) then
                util.delete_entity(driver)
            end
        end
    end)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
    util.yield(1)
    return cargobob, driver
end

local TITAN_MODEL = util.joaat("titan")
function spawn_titan_for_vehicle(vehicle)
    STREAMING.REQUEST_MODEL(TITAN_MODEL)
    while not STREAMING.HAS_MODEL_LOADED(TITAN_MODEL) do
        util.yield()
    end
    local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
    ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 5.0, 1000.0)
    local pos_veh = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0.0, 1001.3) -- offset by 1.3

    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 5000)
    local titan = util.create_vehicle(TITAN_MODEL, pos, heading)
    VEHICLE.SET_VEHICLE_ENGINE_ON(titan, true, true, false)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(titan, true)
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

function spawn_tow_for_vehicle(vehicle)
    local pz = memory.alloc(8)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 8, 0.1)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pz, true)
    pos.z = memory.read_float(pz)
    memory.free(pz)
    local model = math.random(2) == 2 and TOW_TRUCK_MODEL_1 or TOW_TRUCK_MODEL_2
    STREAMING.REQUEST_MODEL(model)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
    local tow = util.create_vehicle(model, pos, heading)
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 5)
    VEHICLE.ATTACH_VEHICLE_TO_TOW_TRUCK(tow, vehicle, false, 0, 0, 0)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(tow, true)
    util.yield(1)
    return tow, driver, model
end


function setup_action_for(pid) 
    local submenu = menu.list(menu.player_root(pid), "Vehicle Options", {"vehicle"}, "List of vehicle options")
    options[pid] = {
        teleport_last = false,
        paint_color_primary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        paint_color_secondary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        neon_color = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        trailer_gate = true,
        cargo_magnet = false
    }

    menu.action(submenu, "Teleport Vehicle to Me", {"tpvehme"}, "Teleports their vehicle to your location", function(_)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle then
            ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z + 3.0, 0, 0, 0, 0)
        else
            util.toast("Player is not in a car or out of range. Try spectating them")
        end
    end)

    ----------------------------------------------------------------
    -- Movement & Attachment Section
    ----------------------------------------------------------------
    local towMenu = menu.list(submenu, "Attachments", {"attachments"}, "Attach their vehicle to:\nCargobobs\nTow Trucks")

    -- TOW 
        menu.divider(towMenu, "Tow Trucks")
        menu.action(towMenu, "Tow (Wander)", {"towwander"}, "Will make a random tow truck tow the player's vehicle randomly around", function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local tow, driver = spawn_tow_for_vehicle(vehicle)
                TASK.TASK_VEHICLE_DRIVE_WANDER(driver, tow, 30.0, 6)
            end
        end)

        menu.action(towMenu, "Tow To Waypoint", {"towwaypoint"}, "Will make a random tow truck tow the player's vehicle to your waypoint", function(_)
            if HUD.IS_WAYPOINT_ACTIVE() then
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                local vehicle = get_player_vehicle_in_control(pid)
                if vehicle == 0 then
                    util.toast("Player is not in a car or out of range")
                else
                    local tow, driver, model = spawn_tow_for_vehicle(vehicle)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, tow, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, model, 6, 5.0, 1.0)
                end
            else
                util.toast("You have no waypoint to drive to")
            end
        end)
        local towPlayerMenu = menu.list(towMenu, "Tow To Player", {"towtoplayer"})
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
                    name = name .. " (Them)"
                elseif pid2 == my_pid then
                    name = name .. " (Me)"
                end
                local m = menu.action(towPlayerMenu, name, {}, "Will make a random tow truck tow the player's vehicle to them", function(_)
                    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid2)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle == 0 then
                        util.toast("Player is not in a car or out of range")
                    else
                        local tow, driver = spawn_tow_for_vehicle(vehicle)
                        local hash = ENTITY.GET_ENTITY_MODEL(vehicle)
                        util.create_tick_handler(function(_)
                            local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
                            TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, tow, target_pos.x, target_pos.y, target_pos.z, 100, 5, hash, 6, 1.0, 1.0)
                            util.yield(5000)
                            return ENTITY.DOES_ENTITY_EXIST(target_ped) and ENTITY.DOES_ENTITY_EXIST(driver) and TASK.GET_SCRIPT_TASK_STATUS(driver, 0x93A5526E) < 7
                        end)
                    end
                end)
                table.insert(towPlayerMenus, m)
            end
        end)

        menu.action(towMenu, "Detach Tow", {"detachtow"}, "Will detach from any tow truck", function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle > 0 then
                VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(vehicle)
            else
                util.toast("Player is not in a car or out of range")
            end
        end)

        menu.divider(towMenu, "Cargobob")

        menu.toggle(towMenu, "Use Magnet", {"cargomagnet"}, "If enabled, will use a magnet instead of a rope. May work better in some situtations", function(on)
            options[pid].cargo_magnet = on
        end, options[pid].cargo_magnet)

        menu.action(towMenu, "Cargobob To Mt. Chiliad", {"cargobobmt"}, "Will make a random cargobob take the player's vehicle to mount chiliad", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, options[pid].cargo_magnet)
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, 450.718 , 5566.614, 806.183, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
            end
        end)

        menu.action(towMenu, "Cargobob To Ocean", {"cargobobocean"}, "Will make a random cargobob take the player's vehicle to the ocean", function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, options[pid].cargo_magnet)
                local pos = ENTITY.GET_ENTITY_COORDS(cargobob)
                local vec = memory.alloc(24)
                local dest = { x = 0, y = 0, z = -5.0}
                if PATHFIND.GET_NTH_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, 15, vec, 3, 3.0, 0) then
                   dest = memory.read_vector3(vec)
                   memory.free(vec)
                    dest.z = -5.0
                else
                    dest.x = -2156
                    dest.y = -1311
                end
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, dest.x, dest.y, dest.z, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
            end
        end)
        local cargoPlayerMenu = menu.list(towMenu, "Cargobob To Player", {"cargobobtoplayer"})
        local cargoPlayerMenus = {}
        menu.on_focus(cargoPlayerMenu, function(_)
            for _, m in ipairs(cargoPlayerMenus) do
                menu.delete(m)
            end
            cargoPlayerMenus = {}
            local cur_players = players.list(true, true, true)
            local my_pid = players.user()
            for _, pid_target in ipairs(cur_players) do
                local name = PLAYER.GET_PLAYER_NAME(pid_target)
                if pid_target == pid then
                    name = name .. " (Them)"
                elseif pid_target == my_pid then
                    name = name .. " (Me)"
                end
                local m = menu.action(cargoPlayerMenu, name, {}, "Will make a random cargobob take the player's vehicle to them", function(_)
                    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid_target)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle == 0 then
                        util.toast("Player is not in a car or out of range")
                    else
                        local _, driver = spawn_cargobob_for_vehicle(vehicle, options[pid].cargo_magnet)
                        TASK.TASK_HELI_CHASE(driver, target_ped, 0, 0, 80.0)
                    end
                end)
                table.insert(cargoPlayerMenus, m)
            end
        end)

        menu.action(towMenu, "Cargobob To Waypoint", {"cargobobwaypoint"}, "Will make a random cargobob take the player's vehicle to your waypoint", function(_)
            if HUD.IS_WAYPOINT_ACTIVE() then
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                local vehicle = get_player_vehicle_in_control(pid)
                if vehicle == 0 then
                    util.toast("Player is not in a car or out of range")
                else
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, options[pid].cargo_magnet)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
                end
            else
                util.toast("You have no waypoint to drive to")
            end
        end)

        menu.action(towMenu, "Detach Cargobob", {"detachcargo"}, "Will detach cargobob from vehicle", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle > 0 then
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
                    local pointer = util.get_entity_address(vehicle)
                    ENTITY.SET_VEHICLE_AS_NO_LONGER_NEEDED(pointer)
                end
            else
                util.toast("Player is not in a car or out of range")
            end
        end)

        menu.divider(towMenu, "Trailers")

        menu.action(towMenu, "Drive Around", {"trailerwander"}, "Will make a random cab & trailer take the player's vehicle randomly around", function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local cab, driver = spawn_cab_and_trailer_for_vehicle(vehicle, options[pid].trailer_gate)
                TASK.TASK_VEHICLE_DRIVE_WANDER(driver, cab, 30.0, 786603)
            end
        end)

        menu.action(towMenu, "Take To Waypoint", {"trailerwaypoint"}, "Will make a random cab & trailer take the player's vehicle to your waypoint", function(_)
            if HUD.IS_WAYPOINT_ACTIVE() then
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                local vehicle = get_player_vehicle_in_control(pid)
                if vehicle == 0 then
                    util.toast("Player is not in a car or out of range")
                else
                    local cab, driver = spawn_cab_and_trailer_for_vehicle(vehicle, options[pid].trailer_gate)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cab, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, CAB_MODEL, 786603, 5.0, 1.0)
                end
            else
                util.toast("You have no waypoint to drive to")
            end
        end)

        menu.toggle(towMenu, "Spawn Trailer With Gate Down", {"trailergate"}, "Should spawned trailers spawn with gate down?", function(on)
            options[pid].trailer_gate = on
        end, options[pid].trailer_gate)

        menu.divider(towMenu, "Titan")
        menu.action(towMenu, "Fly to Mt. Chiliad", {"titanmtchiliad"}, "Spawns a titan, puts their vehicle in it and flys to mt. chiliad", function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local titan, driver = spawn_titan_for_vehicle(vehicle, true)
                --TASK.TASK_PLANE_CHASE(driver, target_ped, 0, 0, 80.0)
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, titan, 450.718 , 5566.614, 806.183, 100.0, 1.0, TITAN_MODEL, 786603, 5.0, 1.0)
            end
        end)
        local titanPlayerMenu = menu.list(towMenu, "Fly To Player", {"titantoplayer"})
        local titanPlayerMenus = {}
        menu.on_focus(titanPlayerMenu, function(_)
            for _, m in ipairs(titanPlayerMenus) do
                menu.delete(m)
            end
            titanPlayerMenus = {}
            local cur_players = players.list(true, true, true)
            local my_pid = players.user()
            for k,pid_target in ipairs(cur_players) do
                local name = PLAYER.GET_PLAYER_NAME(pid_target) 
                if pid_target == pid then
                    name = name .. " (Them)"
                elseif pid_target == my_pid then
                    name = name .. " (Me)"
                end
                local m = menu.action(titanPlayerMenu, name, {}, "Will make a random titan take the player's vehicle to them", function(_)
                    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid_target)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle == 0 then
                        util.toast("Player is not in a car or out of range")
                    else
                        local titan, driver = spawn_titan_for_vehicle(vehicle, true)
                        TASK.TASK_HELI_CHASE(driver, target_ped, 0, 0, 80.0)
                    end
                end)
                table.insert(titanPlayerMenus, m)
            end
        end)
        menu.action(towMenu, "Fly To Waypoint", {"flywaypoint"}, "Spawns a titan, puts their vehicle in it and flys to your waypoint", function(_)
            if HUD.IS_WAYPOINT_ACTIVE() then
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                local vehicle = get_player_vehicle_in_control(pid)
                if vehicle == 0 then
                    util.toast("Player is not in a car or out of range")
                else
                    local titan, driver = spawn_titan_for_vehicle(vehicle, true)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, titan, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, TITAN_MODEL, 786603, 5.0, 1.0)
                end
            else
                util.toast("You have no waypoint to drive to")
            end
        end)

        menu.divider(towMenu, "Misc")

        menu.action(towMenu, "Free Vehicle", {"freevehicle"}, "Teleports the vehicle upwards to escape trailers or other objects", function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local pos = ENTITY.GET_ENTITY_COORDS(vehicle)
                ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z + 5.0)
            end
        end)

        menu.action(towMenu, "Detach All", {"detachall"}, "Will detach vehicle from anything", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle > 0 then
                ENTITY.DETACH_ENTITY(vehicle, true, 0)
            else
                util.toast("Player is not in a car or out of range")
            end
        end)

    -- END TOW
    local movementMenu = menu.list(submenu, "Movement", {}, "List of vehicle movement options.\nBoost, Launch, Slingshot, Stop")
    menu.click_slider(movementMenu, "Boost", {"boost"}, "Boost the player's vehicle forwards at a given speed (mph)", -200, 200, 200, 10, function(mph)
        local speed = mph / 0.44704
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, speed)
            local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z + 2.0)
            VEHICLE.RESET_VEHICLE_WHEELS(vehicle)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(movementMenu, "Slingshot", {"slingshot"}, "Boost the player's vehicle forward at a given speed (mph) & upwards", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100.0)
            local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z + 100.0)
            VEHICLE.RESET_VEHICLE_WHEELS(vehicle)
        end
    end)

    menu.click_slider(movementMenu, "Launch", {"launch"}, "Boost the player's vehicle upwards", -200, 200, 200, 10, function(mph)
        local speed = mph / 0.44704
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0.0, 0.0, speed)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(movementMenu, "Stop", {"stopvehicle"}, "Stops the player's engine", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE._STOP_BRING_VEHICLE_TO_HALT(vehicle)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0.0, 0.0, 0.0)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    ----------------------------------------------------------------
    -- END Movement Section
    ----------------------------------------------------------------
    ----------------------------------------------------------------
    -- Door Section
    ----------------------------------------------------------------
    local door_submenu = menu.list(submenu, "Doors", {}, "Open and close the player's vehicle doors")
    menu.slider(door_submenu, "Lock Status", {"lockstatus"}, "Changes the lock state of the value\n0 = Unlocked\n1 = Locked for passengers\n2 = Locked for all", 0, 2, 0, 1, function(state)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            if state == 0 then
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
            elseif state == 1 then
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 4)
            else
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2)
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    local open_doors = true
    menu.toggle(door_submenu, "Open", {}, "Will open the doors if enabled\nWill close if disabled", function(on)
        open_doors = on
    end, open_doors)

    menu.action(door_submenu, "All Doors", {}, "", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            if open_doors then
                for door = 0,7 do
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, door, false, false)
                end
            else
                VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle, false)
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end)
    

    for i, name in pairs(DOOR_NAMES) do
        menu.action(door_submenu, name, {}, "Opens or closes " .. name, function(_)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle > 0 then
                if open_doors then
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, i - 1, false, false)
                else
                    VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, i - 1, false)
                end
            else
                util.toast("Player is not in a car or out of range")
            end
        end)
    end
    menu.toggle(door_submenu, "Landing Gear Down", {}, "Changes the landing gear state (Untested)", function(on)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.CONTROL_LANDING_GEAR(vehicle, on and 0 or 3)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)
    ----------------------------------------------------------------
    -- END Door Section
    ----------------------------------------------------------------
    ----------------------------------------------------------------
    -- LSC Section
    ----------------------------------------------------------------
    local lsc = menu.list(submenu, "Los Santos Customs", {"lcs"}, "Customize the players vehicle options\nSet headlights\nSet Paint Color")
    menu.slider(lsc, "Xenon Headlights Paint Type", {"xenoncolor"}, "The paint to use for xenon lights\nDefault = -1\nWhite = 0\nBlue = 1\nElectric Blue = 2\nMint Green = 3\nLime Green = 4\nYellow = 5\nGolden Shower = 6\nOrange = 7\nRed = 8\nPony Pink = 9\nHot Pink = 10\nPurple = 11\nBlacklight = 12", -1, 12, 0, 1, function(paint)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE._SET_VEHICLE_XENON_LIGHTS_COLOR(vehicle, paint)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)
    -- 
    -- NEON SECTION
    --
    local neon = menu.list(lsc, "Neon Lights", {}, "")
    local neon_menus = {}
    menu.action(neon, "Apply Neon Color", {"paintneon"}, "Applies neon colors with the color selected below", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local r = math.floor(options[pid].neon_color.r * 255)
            local g = math.floor(options[pid].neon_color.g * 255)
            local b = math.floor(options[pid].neon_color.b * 255)
            VEHICLE._SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, r, g, b)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.colour(neon, "Neon Color", {"neoncolor"}, "The color to use for neon lights", options[pid].neon_color, false, function(color)
        options[pid].neon_color = color
    end)
    menu.on_focus(neon, function()
        for i, m in ipairs(neon_menus) do
            menu.delete(m)
            table.remove(neon_menus, i)
        end
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            for x = 0,3 do
                local enabled = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x)
                local m = menu.toggle(neon, NEON_INDICES[x+1], {}, "Turns on the player's neon lights", function(_)
                    vehicle = get_player_vehicle_in_control(pid)
                    if vehicle > 0 then
                        enabled = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x)
                        VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x, not enabled)
                    else
                        util.toast("Player is not in a car or out of range")
                    end
                end, enabled)
                table.insert(neon_menus, m)
            end
        end
    end)
    --END NEON--

    menu.action(lsc, "Paint", {"paint"}, "Paints the car with the selected colors below", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local r = math.floor(options[pid].paint_color_primary.r * 255)
            local g = math.floor(options[pid].paint_color_primary.g * 255)
            local b = math.floor(options[pid].paint_color_primary.b * 255)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, r, g, b)
            r = math.floor(options[pid].paint_color_secondary.r * 255)
            g = math.floor(options[pid].paint_color_secondary.g * 255)
            b = math.floor(options[pid].paint_color_secondary.b * 255)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, r, g, b)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.colour(lsc, "Paint Color (Primary)", {"paintcolorprimary"}, "The primary color to paint the car", options[pid].paint_color_primary, false, function(color)
        options[pid].paint_color_primary = color
    end)

    menu.colour(lsc, "Paint Color (Secondary)", {"paintcolorsecondary"}, "The secondary color to paint the car", options[pid].paint_color_secondary, false, function(color)
        options[pid].paint_color_secondary = color
    end)

    local subMenus = {}
    local modMenu = menu.list(lsc, "Vehicle Mods", {}, "")
    menu.on_focus(modMenu, function(_)
        for _, m in ipairs(subMenus) do
            menu.delete(m)
        end
        subMenus = {}
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            for i, mod in pairs(MOD_TYPES) do
                local default = VEHICLE.GET_VEHICLE_MOD(vehicle, i -1)
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i - 1)
                local m = menu.slider(modMenu, mod, {"set" .. mod}, string.format("Apply upto %d variations of %s\n-1 is Stock", max, mod), -1, max, default, 1, function(index)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle > 0 then
                       VEHICLE.SET_VEHICLE_MOD(vehicle, i - 1, index)
                    else
                        util.toast("Player is not in a car or out of range")
                    end
                end)
                table.insert(subMenus, m)
            end
            for i, mod in pairs(TOGGLE_MOD_TYPES) do
                local default = VEHICLE.IS_TOGGLE_MOD_ON(vehicle, i-1)
                local m = menu.toggle(modMenu, mod, {"toggle" .. mod}, "Toggle " .. mod .. " on or off", function(on)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle > 0 then
                       VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, i-1, on)
                    else
                        util.toast("Player is not in a car or out of range")
                    end
                end, default)
                table.insert(subMenus, m)
            end
        end
    end)

    menu.click_slider(modMenu, "Wheel Type", {"wheeltype"}, "Sets the vehicle's wheel types\nSport = 0\nMuscle = 1\nLowrider = 2\nSUV = 3\nOffroad = 4\nTuner = 5\nBike Wheels = 6\nHigh End = 7\nClick to apply.", 0, 7, 0, 1, function(type)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
           VEHICLE.SET_VEHICLE_WHEEL_TYPE(vehicle, type)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.click_slider(modMenu, "Window Tint", {"windowtint"}, "Set the window tint.\n0 = None\n1 = Pure Black\n2 = Dark Smoke\n3 = Light Smoke\n4 = Stock\n5 = Limo\n6 = Green\nClick to apply.", 0, 6, 0, 1, function(value)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, value)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(lsc, "Upgrade", {"upgradevehicle"}, "Upgrades the vehicle to the highest upgrades", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            for x = 0, 49 do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                util.toast("max for x" .. x .. " is " .. max)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.SET_VEHICLE_MOD(vehicle, 15, 45) -- re-set horn 
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 5)
            for x = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, true)
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(lsc, "Performance Upgrade", {"performanceupgradevehicle"}, "Upgrades the following vehicle parts:\nEngine\nTransmission\nBrakes\nArmour\nTurbo", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local mods = { 11, 12, 13, 16 }
            for x in ipairs(mods) do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    ----------------------------------------------------------------
    -- END LSC
    ----------------------------------------------------------------

    menu.action(submenu, "Clone Vehicle", {"clonevehicle"}, "Clones the player's vehicle", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local saveData = get_vehicle_save_data(vehicle)
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            local vehicle = util.create_vehicle(saveData.Model, pos, heading)
            apply_vehicle_save_data(vehicle, saveData)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Save Vehicle", {"saveplayervehicle"}, "Saves the player's vehicle to disk", function(_)
        util.toast("Enter a name to save the vehicle as")
        menu.show_command_box("savevehicle ")
    end, function(args)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local saveData = get_vehicle_save_data(vehicle)

            local file = io.open( vehicleDir .. args .. ".json", "w")
            io.output(file)
            io.write(json.encode(saveData))
            io.close(file)
            util.toast("Saved to %appdata%\\Stand\\Vehicles\\" .. args .. ".json")
        else
            util.toast("Player is not in a car or out of range")
        end
    end)
    menu.action(submenu, "Spawn Vehicle", {"spawnfor"}, "Spawns the vehicle name for the player", function(_)
        local name = PLAYER.GET_PLAYER_NAME(pid)
        menu.show_command_box("spawnfor" .. name .. " ")
    end, function(args)
        local model = util.joaat(args)
        if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_A_VEHICLE(model) then
            STREAMING.REQUEST_MODEL(model)
            while not STREAMING.HAS_MODEL_LOADED(model) do
                util.yield()
            end
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
            local veh = util.create_vehicle(model, pos, heading)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
        else
            util.toast("Could not find that vehicle.")
        end
    end, false)

    menu.action(submenu, "Flip Upright", {"flipveh"}, "Flips the player's vehicle upwards", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, rot.y, rot.z)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)


    menu.action(submenu, "Flip Vehicle 180", {"flipv"}, "Flips the player's vehicle around", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Honk", {"honk"}, "Makes their car honk. Works best if no player in vehicle", function(_)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_ALARM(vehicle, true)
            VEHICLE.START_VEHICLE_ALARM(vehicle)
            VEHICLE.START_VEHICLE_HORN(vehicle, 50000, 0)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.click_slider(submenu, "Hijack Vehicle (Wander)", {"hijack"}, "Makes a random NPC hijack their vehicle\n 0 = Doors Unlocked\n 1 = Doors Locked", 0, 1, 0, 1, function(hijackLevel)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 0.0, 0.1)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
            local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
            PED.SET_PED_AS_ENEMY(ped, true)
            if hijackLevel == 1 then
                util.yield(20)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
            end
            for _ = 1, 20 do
                TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
                util.yield(50)
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end)
    local hijackToMenu = menu.list(submenu, "Hijack & Drive to Player", {"hijacktoplayer"})
    local hijackToMenus = {}
    menu.on_focus(hijackToMenu, function(_)
        for _, m in ipairs(hijackToMenus) do
            menu.delete(m)
        end
        hijackToMenus = {}
        local cur_players = players.list(true, true, true)
        local my_pid = players.user()
        for k,pid_target in ipairs(cur_players) do
            local name = PLAYER.GET_PLAYER_NAME(pid_target) 
            if pid_target == pid then
                name = name .. " (Them)"
            elseif pid_target == my_pid then
                name = name .. " (Me)"
            end
            local m = menu.action(hijackToMenu, name, {}, "Will make a random ped drive the player's vehicle to them", function(on_click)
                local vehicle = get_player_vehicle_in_control(pid)
                local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid_target)
                if vehicle > 0 then
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 1.0, 0.1)
                    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
                    local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
                    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                    VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
                    PED.SET_PED_AS_ENEMY(ped, true)
                    --TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
                    local loops = 10
                    while not PED.IS_PED_IN_VEHICLE(ped, vehicle, false) do
                        local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, target_pos.x, target_pos.y, target_pos.z, 100, 5, hash, 6, 1.0, 1.0)
                        util.yield(1000)
                        loops = loops - 1
                        if loops == 0 then
                            util.toast("Hijacker failed to enter vehicle in time.")
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
                else
                    util.toast("Player is not in a car or out of range")
                end
            end)
            table.insert(hijackToMenus, m)
        end
    end)

    menu.action(submenu, "Burst Tires", {"bursttires", "bursttyres"}, "Bursts the player's vehicle tires", function(on_click)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            for wheel = 0,7 do
                local burstable = VEHICLE.GET_VEHICLE_TYRES_CAN_BURST(vehicle, wheel)
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, wheel, true)
                VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, wheel, true, 1000.0)
                if not burstable then
                    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, wheel, false)
                end
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Delete Vehicle", {"deletevehicle"}, "Removes the player's vehicle", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            util.delete_entity(vehicle)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Explode Vehicle", {"explodevehicle"}, "Kills the player's vehicle engine with style.", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local pos = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
            FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z + 1.0, 26, 60, true, true, 0.0)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Kill Engine", {"killengine"}, "Kills the player's vehicle engine", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Clean Vehicle", {"cleanvehicle"}, "Cleans the player's vehicle", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            GRAPHICS.REMOVE_DECALS_FROM_VEHICLE(vehicle)
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Repair Vehicle", {"repairvehicle"}, "Repairs the player's vehicle", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_FIXED(vehicle)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.toggle(submenu, "Toggle Godmode", {"setvehgod"}, "Toggles their vehicle invincibility", function(on)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            -- TODO: TEST SET_VEHICLE_HAS_UNBREAKABLE_LIGHTS
            ENTITY.SET_ENTITY_INVINCIBLE(vehicle, on)
        else
            util.toast("Player is not in a car or out of range")
        end
    end, false)

    menu.action(submenu, "Set License Plate", {"setlicenseplate"}, "Sets their vehicles license plate", function(on)
        local name = PLAYER.GET_PLAYER_NAME(pid)
        menu.show_command_box("setlicenseplate" .. name .. " ")
    end, function(args)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, args)
        else
            util.toast("Player is not in a car or out of range")
        end
    end, false)

end

function get_vehicle_save_data(vehicle)
    local model = ENTITY.GET_ENTITY_MODEL(vehicle)
    local Primary = {
        Custom = VEHICLE.GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(vehicle),
    }
    local Secondary = {
        Custom = VEHICLE.GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(vehicle),
    }
    -- Declare pointers
    local Color = {
        r = memory.alloc(8),
        g = memory.alloc(8),
        b = memory.alloc(8),
    }

    if Primary.Custom then
        VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, Color.r, Color.g, Color.b)
        Primary["Custom Color"] = {
            r = memory.read_int(Color.r),
            b = memory.read_int(Color.g),
            g = memory.read_int(Color.b)
        }
    else
        VEHICLE.GET_VEHICLE_MOD_COLOR_1(vehicle, Color.r, Color.b, Color.g)
        Primary["Paint Type"] = memory.read_int(Color.r)
        Primary["Color"] = memory.read_int(Color.g)
        Primary["Pearlescent Color"] = memory.read_int(Color.b)
    end
    if Secondary.Custom then
        VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, Color.r, Color.g, Color.b)
        Secondary["Custom Color"] = {
            r = memory.read_int(Color.r),
            b = memory.read_int(Color.g),
            g = memory.read_int(Color.b)
        }
    else
        VEHICLE.GET_VEHICLE_MOD_COLOR_1(vehicle, Color.r, Color.b, Color.g)
        Secondary["Paint Type"] = memory.read_int(Color.r)
        Secondary["Color"] = memory.read_int(Color.g)
        Secondary["Pearlescent Color"] = memory.read_int(Color.b)
    end
    VEHICLE.GET_VEHICLE_EXTRA_COLOURS(vehicle, Color.r, Color.g, Color.b)
    local Extras = {
        r = memory.read_int(Color.r),
        g = memory.read_int(Color.g),
        b = memory.read_int(Color.b),
    }

    VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, Color.r, Color.g, Color.b)
    local TireSmoke = {
        r = memory.read_int(Color.r),
        g = memory.read_int(Color.g),
        b = memory.read_int(Color.b),
    }

    VEHICLE._GET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, Color.r, Color.g, Color.b)
    local Neon = {
        Color = {
            r = memory.read_int(Color.r),
            g = memory.read_int(Color.g),
            b = memory.read_int(Color.b),
        },
        Left = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 0),
        Right = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 1),
        Front = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 2),
        Back = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 3),
    }
    Color.r = memory.alloc(8)
    Color.b = memory.alloc(8)
    VEHICLE._GET_VEHICLE_DASHBOARD_COLOR(vehicle, Color.r)
    VEHICLE._GET_VEHICLE_INTERIOR_COLOR(vehicle, Color.b)
    local DashboardColor = memory.read_int(Color.r)
    local InteriorColor = memory.read_int(Color.b)
    VEHICLE.GET_VEHICLE_COLOR(vehicle, Color.r, Color.g, Color.b)
    local Vehicle = {
        r = memory.read_int(Color.r),
        g = memory.read_int(Color.g),
        b = memory.read_int(Color.b),
    }
    VEHICLE.GET_VEHICLE_COLOURS(vehicle, Color.r, Color.g)
    Vehicle["Primary"] = memory.read_int(Color.r)
    Vehicle["Secondary"] = memory.read_int(Color.g)
    memory.free(Color.r)
    memory.free(Color.g)
    memory.free(Color.b)

    local mods = { Toggles = {} }
    for i, modName in pairs(MOD_TYPES) do
        mods[modName] = VEHICLE.GET_VEHICLE_MOD(vehicle, i - 1)
    end
    for i, mod in pairs(TOGGLE_MOD_TYPES) do
        mods.Toggles[mod] = VEHICLE.IS_TOGGLE_MOD_ON(vehicle, i-1)
    end
    local saveData = {
        Format = VEHICLE_SAVEDATA_FORMAT_VERSION,
        Model = model,
        Name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model),
        Manufacturer = VEHICLE._GET_MAKE_NAME_FROM_VEHICLE_MODEL(model),
        Type = VEHICLE_TYPES[VEHICLE.GET_VEHICLE_CLASS(vehicle)],
        ["Tire Smoke"] = TireSmoke,
        Livery = {
            Style = VEHICLE.GET_VEHICLE_LIVERY(vehicle),
            Count = VEHICLE.GET_VEHICLE_LIVERY_COUNT(vehicle)
        },
        ["License Plate"] = {
            Text = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle),
            Type = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle)
        },
        ["Window Tint"] = VEHICLE.GET_VEHICLE_WINDOW_TINT(vehicle),
        Colors = {
            Primary = Primary,
            Secondary = Secondary,
            ["Color Combo"] = VEHICLE.GET_VEHICLE_COLOUR_COMBINATION(vehicle),
            ["Paint Fade"] = VEHICLE.GET_VEHICLE_ENVEFF_SCALE(vehicle),
            Vehicle = Vehicle,
            Extras = Extras
        },
        Lights = {
            ["Xenon Color"] = VEHICLE._GET_VEHICLE_XENON_LIGHTS_COLOR(vehicle),
            Neon = Neon
        },
        ["Engine Running"] = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(vehicle),
        ["Dashboard Color"] = DashboardColor,
        ["Interior Color"] = InteriorColor,
        ["Dirt Level"] = VEHICLE.GET_VEHICLE_DIRT_LEVEL(vehicle),
        ["Bulletproof Tires"] = VEHICLE.GET_VEHICLE_TYRES_CAN_BURST(vehicle),
        Mods = mods
    }

    return saveData
end
function apply_vehicle_save_data(vehicle, saveData)
    -- Vehicle Paint Colors. Not sure if all these are needed but well I store them
    VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
    VEHICLE.SET_VEHICLE_COLOUR_COMBINATION(vehicle, saveData.Colors["Color Combo"] or -1)
    if saveData.Colors.Extra then
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, saveData.Colors.Extras.r, saveData.Colors.Extras.g, saveData.Colors.Extras.b)
    end
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, saveData.Colors.Vehicle.r, saveData.Colors.Vehicle.g, saveData.Colors.Vehicle.b)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, saveData.Colors.Vehicle.r, saveData.Colors.Vehicle.g, saveData.Colors.Vehicle.b)
    VEHICLE.SET_VEHICLE_COLOURS(vehicle, saveData.Colors.Vehicle.Primary or 0, saveData.Colors.Vehicle.Secondary or 0)
    if saveData.Colors.Primary.Custom and saveData.Colors.Primary["Custom Color"] then
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, saveData.Colors.Primary["Custom Color"].r, saveData.Colors.Primary["Custom Color"].b, saveData.Colors.Primary["Custom Color"].g)
    else
        VEHICLE.SET_VEHICLE_MOD_COLOR_1(vehicle, saveData.Colors.Primary["Paint Type"], saveData.Colors.Primary.Color, saveData.Colors.Primary["Pearlescent Color"])
    end
    if saveData.Colors.Secondary.Custom and saveData.Colors.Secondary["Custom Color"] then
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, saveData.Colors.Secondary["Custom Color"].r,  saveData.Colors.Secondary["Custom Color"].b, saveData.Colors.Secondary["Custom Color"].g)
    else
        VEHICLE.SET_VEHICLE_MOD_COLOR_2(vehicle, saveData.Colors.Secondary["Paint Type"], saveData.Colors.Secondary.Color, saveData.Colors.Secondary["Pearlescent Color"])
    end
    VEHICLE.SET_VEHICLE_ENVEFF_SCALE(vehicle, saveData["Colors"]["Paint Fade"] or 0)
    -- Misc Colors / Looks
    if saveData["Tire Smoke"] then
        VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, saveData["Tire Smoke"].r or 255, saveData["Tire Smoke"].g or 255, saveData["Tire Smoke"].b or 255)
    end
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, saveData["Bulletproof Tires"] or false)
    VEHICLE._SET_VEHICLE_DASHBOARD_COLOR(vehicle, saveData["Dashboard Color"] or -1)
    VEHICLE._SET_VEHICLE_INTERIOR_COLOR(vehicle, saveData["Interior Color"] or -1)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, saveData["Dirt Level"] or 0.0)

    -- Lights
    VEHICLE._SET_VEHICLE_XENON_LIGHTS_COLOR(vehicle, saveData["Lights"]["Xenon Color"] or 255)
    VEHICLE._SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, saveData.Lights.Neon.Color.r or 255, saveData.Lights.Neon.Color.g or 255, saveData.Lights.Neon.Color.b or 255)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 0, saveData.Lights.Neon.Left or false)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 1, saveData.Lights.Neon.Right or false)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 2, saveData.Lights.Neon.Front or false)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 3, saveData.Lights.Neon.Back or false)

    if saveData["Engine Running"] then
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, false)
    end

    for i, modName in pairs(MOD_TYPES) do
        if saveData.Mods[modName] then
            VEHICLE.SET_VEHICLE_MOD(vehicle, i - 1, saveData.Mods[modName])
        end
    end
    if saveData.Mods.Toggles then
        for i, mod in pairs(TOGGLE_MOD_TYPES) do
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, i - 1, saveData.Mods.Toggles[mod])
        end
    end

    -- Misc
    VEHICLE.SET_VEHICLE_LIVERY(vehicle, saveData.Livery.style or -1)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, saveData["Window Tint"] or 0)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, saveData["License Plate"].Text or saveData["License Plate"] or "")
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle, saveData["License Plate"].Type or 0)

end

menu.action(menu.my_root(), "Save Current Vehicle", {"savevehicle"}, "Saves your current vehicle with all customizations", function(_)
    util.toast("Enter a name to save the vehicle as")
    menu.show_command_box("savevehicle ")
end, function(args)
    local vehicle = util.get_vehicle()
    local saveData = get_vehicle_save_data(vehicle)

    local file = io.open( vehicleDir .. args .. ".json", "w")
    io.output(file)
    io.write(json.encode(saveData))
    io.close(file)
    util.toast("Saved to %appdata%\\Stand\\Vehicles\\" .. args .. ".json")
end)

local cloudVehicles = menu.list(menu.my_root(), "Cloud Vehicles (BETA)", {}, "Ooooh mysterious cloud, what mysteries do you have?")
local cloudSearchMenu = menu.list(cloudVehicles, "Search", {"searchvehicles"}, "Search the cloud for vehicles")
local cloudSearchMenus = {}
local cloudUserVehicleSaveDataCache = {}
local previewVehicle = 0
function spawn_preview_vehicle(saveData)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        util.delete_entity(previewVehicle)
    end
    -- Too lazy to figure out way to refactor this into not being reused code:
    STREAMING.REQUEST_MODEL(saveData.Model)
    while not STREAMING.HAS_MODEL_LOADED(saveData.Model) do
        util.yield()
    end
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 6.5, 0.0)
    local veh = VEHICLE.CREATE_VEHICLE(saveData.Model, pos.x, pos.y, pos.z, 0, false, false)
    previewVehicle = veh
    apply_vehicle_save_data(previewVehicle, saveData)
    local heading = 0
    ENTITY.SET_ENTITY_ALPHA(previewVehicle, 150)
    VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(previewVehicle)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(previewVehicle, false, false)
    util.create_tick_handler(function(_)
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
function setup_vehicle_submenu(m, user, vehicleName)
    local saveData = cloudUserVehicleSaveDataCache[user][vehicleName]
    if not saveData then
        HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("MP_SPINLOADING")
        HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(3)
        async_http.init("jackz.me", "/stand/vehicles/" .. user .. "/" .. vehicleName, function(result)
            HUD.BUSYSPINNER_OFF()
            saveData = json.decode(result)
            cloudUserVehicleSaveDataCache[user][vehicleName] = saveData
            local manuf = saveData.Manufacturer and saveData.Manufacturer .. " " or ""
            local desc = string.format("Vehicle: %s%s (%s)\nFormat Version: %s (Current: %s)", manuf, saveData.Name, saveData.Type, saveData.Format, VEHICLE_SAVEDATA_FORMAT_VERSION)
            menu.action(m, "Spawn", {}, desc, function(_)
                while not cloudUserVehicleSaveDataCache[user][vehicleName] do
                    util.yield()
                end
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 6.5, 0.0)
                local heading = ENTITY.GET_ENTITY_HEADING(my_ped)
                vehicle = util.create_vehicle(cloudUserVehicleSaveDataCache[user][vehicleName].Model, pos, heading)
                apply_vehicle_save_data(vehicle, cloudUserVehicleSaveDataCache[user][vehicleName])
                util.toast("Spawned " .. user .. "/" .. vehicleName)
                if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                    util.delete_entity(previewVehicle)
                end
            end)
            menu.action(m, "Download", {}, desc, function(_)
                while not cloudUserVehicleSaveDataCache[user][vehicleName] do
                    util.yield()
                end
                local file = io.open( vehicleDir .. user .. "_" .. vehicleName, "w")
                io.output(file)
                io.write(json.encode(cloudUserVehicleSaveDataCache[user][vehicleName]))
                io.close(file)
                util.toast("Saved to %appdata%\\Stand\\Vehicles\\" ..  user .. "_" .. vehicleName)
            end)
        end)
        async_http.dispatch()
        -- do we need this yield?
        while saveData == nil do
            util.yield()
        end
    end
    spawn_preview_vehicle(saveData)
end

menu.action(cloudSearchMenu, "> Search New", {"searchcloud"}, "", function(_)
    menu.show_command_box("searchcloud ")
end, function(args)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("MP_SPINLOADING")
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(3)
    async_http.init("jackz.me", "/stand/vehicles/list?q=" .. args, function(result)
        HUD.BUSYSPINNER_OFF()
        for _, m in ipairs(cloudSearchMenus) do
            menu.delete(m)
        end
        cloudSearchMenus = {}
        local foundOne = false
        for result in string.gmatch(result, "[^\r\n]+") do
            foundOne = true
            local chunks = {} -- { user, vehicleName }
            for substring in string.gmatch(result, "%S+") do
                table.insert(chunks, substring)
            end
            local vehicleName = chunks[2]
            if #chunks > 2 then
                for i = 3, #chunks do
                    vehicleName = vehicleName .. " " .. chunks[i]
                end
            end
            
            local m = menu.list(cloudSearchMenu, chunks[1] .. "/" .. vehicleName, {})
            menu.on_focus(m, function(_)
                setup_vehicle_submenu(m, chunks[1], vehicleName)
            end)
            table.insert(cloudSearchMenus, m)
        end
        if not foundOne then
            util.toast("No search results found for " .. args)
        end
    end)
    async_http.dispatch()
end)
menu.on_focus(cloudSearchMenu, function(_)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        util.delete_entity(previewVehicle)
    end
    for _, m in ipairs(cloudSearchMenus) do
        menu.delete(m)
    end
    cloudSearchMenus = {}
end)
local cloudUploadMenu = menu.list(cloudVehicles, "Upload", {"uploadcloud"}, "Browse your saved vehicles to upload to the cloud")
local cloudUploadMenus = {}
local cloudID
if filesystem.exists(vehicleDir .. "/cloud.id") then
    local file = io.open(vehicleDir .. "/cloud.id")
    io.input(file)
    cloudID = io.read("*a")
    io.close(file)
else
    math.randomseed(os.time())
    local file = io.open(vehicleDir .. "/cloud.id", "w")
    cloudID = math.random(1, 10000000)
    io.output(file)
    io.write(cloudID)
    io.close(file)
end
menu.on_focus(cloudUploadMenu, function(_)
    for _, m in ipairs(cloudUploadMenus) do
        menu.delete(m)
    end
    cloudUploadMenus = {}
    for _, file in ipairs(filesystem.list_files(vehicleDir)) do
        local _, name, ext = string.match(file, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if ext == "json" then
            file = io.open(vehicleDir .. name, "r")
            io.input(file)
            local saveData = json.decode(io.read("*a"))
            io.close(file)
            if saveData.Model and saveData.Mods then
                local manuf = saveData.Manufacturer and saveData.Manufacturer .. " " or ""
                local desc = string.format("Vehicle: %s%s (%s)\nFormat Version: %s (Current: %s)", manuf, saveData.Name, saveData.Type, saveData.Format, VEHICLE_SAVEDATA_FORMAT_VERSION)
                local displayName = string.sub(name, 0, -6)
                local previewVehicle = 0
                local m = menu.action(cloudUploadMenu, displayName, {}, "Click to upload this vehicle\n\n" .. desc .. "\n\nWill overwrite existing versions in the cloud.", function(_)
                    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                        util.delete_entity(previewVehicle)
                        previewVehicle = 0
                    end
                    if not cloudID then
                        util.toast("You do not have a cloudID, contact jackz for help.")
                    end
                    local scName = SOCIALCLUB._SC_GET_NICKNAME()
                    async_http.init("jackz.me", "/stand/vehicles/upload?user=" .. scName .. "&name=" .. name, function(result)
                        if result == "SUCCESS" then
                            util.toast("Vehicle uploaded to cloud successfully.")
                        else
                            util.toast("Failed to upload to cloud: " .. result)
                        end
                    end)
                    async_http.add_header("X-Cloud-ID", cloudID)
                    async_http.set_post("Content-Type: application/json", json.encode(saveData))
                    async_http.dispatch()
                end)
                menu.on_focus(m, function(_)
                    spawn_preview_vehicle(saveData)
                end)
                menu.on_blur(m, function(_)
                    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                        util.delete_entity(previewVehicle)
                    end
                    previewVehicle = 0
                    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(saveData.Model)
                end)
                table.insert(cloudUploadMenus, m)
            end
        end
    end
end)

local cloudUserMenus = {}
local cloudUserVehicleMenus = {}
local isFetchingCloudUserVehicles = {}
local isFetchingCloudUser = {}
local isFetchingUsers = false
menu.divider(cloudVehicles, "Browse User Vehicles")
menu.on_focus(cloudVehicles, function(_)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("MP_SPINLOADING")
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(3)
    if isFetchingUsers then
        return
    end
    isFetchingUsers = true
    async_http.init("jackz.me", "/stand/vehicles/list", function(result)
        for _, m in ipairs(cloudUserMenus) do
            pcall(menu.delete, m)
        end
        cloudUserMenus = {}
        HUD.BUSYSPINNER_OFF()
        for user in string.gmatch(result, "[^\r\n]+") do
            local userMenu = menu.list(cloudVehicles, user, {}, "Browse all uploaded vehicles by\n" .. user)
            cloudUserVehicleSaveDataCache[user] = {}
            menu.on_focus(userMenu, function(_)
                if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                    util.delete_entity(previewVehicle)
                end
                if isFetchingCloudUserVehicles[user] then
                    return
                end
                isFetchingCloudUserVehicles[user] = true
                HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("MP_SPINLOADING")
                HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(3)
                async_http.init("jackz.me", "/stand/vehicles/list?user=" .. user, function(result)
                    for _, m in ipairs(cloudUserVehicleMenus) do
                        pcall(menu.delete, m)
                    end
                    cloudUserVehicleMenus = {}
                    HUD.BUSYSPINNER_OFF()
                    for vehicleName in string.gmatch(result, "[^\r\n]+") do
                        local vehicleMenuList = menu.list(userMenu, vehicleName, {}, "")
                        menu.on_focus(vehicleMenuList, function(_)
                            setup_vehicle_submenu(vehicleMenuList, user, vehicleName)
                        end)
                        table.insert(cloudUserVehicleMenus, vehicleMenuList)
                    end
                    isFetchingCloudUserVehicles[user] = false
                end, function(_err) util.toast("Could not fetch user's vehicles at this time") end)
                async_http.dispatch()
            end)
            table.insert(cloudUserMenus, userMenu)
        end
        isFetchingUsers = false
    end, function(_err) util.toast("Could not fetch cloud vehicles at this time") end)
    async_http.dispatch()
end)

local savedVehiclesList = menu.list(menu.my_root(), "Spawn Saved Vehicles", {}, "List of spawnable saved vehicles.\nStored in %appdata%\\Stand\\Vehicles")
local savedVehicleMenus = {}
local applySaved = false
menu.toggle(menu.my_root(), "Apply Saved Vehicle to Current Vehicle", {}, "Instead of spawning a new saved vehicle, it will instead apply its settings to your current vehicle.", function(on)
    applySaved = on
end, applySaved)
menu.on_focus(savedVehiclesList, function()
    for _, m in pairs(savedVehicleMenus) do
        menu.delete(m)
    end
    savedVehicleMenus = {}
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        util.delete_entity(previewVehicle)
    end
    for _, file in ipairs(filesystem.list_files(vehicleDir)) do
        local _, name, ext = string.match(file, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if ext == "json" then
            file = io.open(vehicleDir .. name, "r")
            io.input(file)
            local saveData = json.decode(io.read("*a"))
            io.close(file)
            if saveData.Model and saveData.Mods then
                local manuf = saveData.Manufacturer and saveData.Manufacturer .. " " or ""
                local desc = string.format("Vehicle: %s%s (%s)\nFormat Version: %s (Current: %s)", manuf, saveData.Name, saveData.Type, saveData.Format, VEHICLE_SAVEDATA_FORMAT_VERSION)
                local displayName = string.sub(name, 0, -6)
                local m = menu.action(savedVehiclesList, displayName, {"spawnvehicle" .. displayName}, "Spawns a saved custom vehicle\n" .. desc, function(_)
                    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                        util.delete_entity(previewVehicle)
                        previewVehicle = 0
                    end
                    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 6.5, 0.5)
                    local heading = ENTITY.GET_ENTITY_HEADING(my_ped)
                    local vehicle = 0
                    if applySaved then
                        vehicle = util.get_vehicle()
                        if vehicle == 0 then
                            util.toast("You must be in a vehicle to apply")
                        end
                        util.toast("Applied " .. name .. " to your current vehicle")
                    else
                        STREAMING.REQUEST_MODEL(saveData.Model)
                        while not STREAMING.HAS_MODEL_LOADED(saveData.Model) do
                            util.yield()
                        end
                        vehicle = util.create_vehicle(saveData.Model, pos, heading)
                        util.toast("Spawned " .. name)
                    end

                    if vehicle > 0 then
                        apply_vehicle_save_data(vehicle, saveData)
                    end
                end)
                menu.on_focus(m, function(_)
                    spawn_preview_vehicle(saveData)
                end)
                menu.on_blur(m, function(_)
                    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
                        util.delete_entity(previewVehicle)
                    end
                    previewVehicle = 0
                    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(saveData.Model)
                end)
                table.insert(savedVehicleMenus, m)
            end
        end
    end
end)
local spawned_tows = {}
local nearbyMenu = menu.list(menu.my_root(), "Nearby Vehicles", {"nearbyvehicles"}, "Actions to do on nearby vehicles")
menu.action(nearbyMenu, "Tow All Nearby Vehicles", {}, "WARNING: This can make your FPS drop or even crash your game!\nLimited to 30 tow trucks to prevent crashes.", function(sdfa)
    local pz = memory.alloc(8)
    STREAMING.REQUEST_MODEL(TOW_TRUCK_MODEL_1)
    STREAMING.REQUEST_MODEL(TOW_TRUCK_MODEL_2)
    while not STREAMING.HAS_MODEL_LOADED(TOW_TRUCK_MODEL_2) do
        util.yield()
    end
    for _, ent in ipairs(spawned_tows) do
        util.delete_entity(ent)
    end
    spawned_tows = {}
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_pos = ENTITY.GET_ENTITY_COORDS(my_ped)
    local nearby_vehicles = {}
    for _, vehicle in ipairs(util.get_all_vehicles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if model ~= TOW_TRUCK_MODEL_1 and model ~= TOW_TRUCK_MODEL_2 and VEHICLE.IS_THIS_MODEL_A_CAR(model) then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 8, 0.1)
            MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pz, true)
            pos.z = memory.read_float(pz)
            local dist = SYSTEM.VDIST2(my_pos.x, my_pos.y, my_pos.z, pos.x, pos.y, pos.z)
            table.insert(nearby_vehicles, { vehicle, dist, pos, model })
        end
    end
    memory.free(pz)
    table.sort(nearby_vehicles, function(a, b) return b[2] > a[2] end)
    for i = 1,30 do
        if nearby_vehicles[i] then
            local vehicle = nearby_vehicles[i][1]
            local pos = nearby_vehicles[i][3]
            local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            
            math.randomseed(nearby_vehicles[i][4])
            local tow = util.create_vehicle(math.random(2) == 2 and TOW_TRUCK_MODEL_1 or TOW_TRUCK_MODEL_2, pos, heading)
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
menu.action(nearbyMenu, "Clear All Nearby Tows", {}, "", function(_)
    local vehicles = util.get_all_vehicles()
    for _, vehicle in ipairs(vehicles) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if model == TOW_TRUCK_MODEL_1 or model == TOW_TRUCK_MODEL_2 then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver > 0 and not PED.IS_PED_A_PLAYER(driver) then
                util.delete_entity(driver)
            end
            util.delete_entity(vehicle)
        end
    end
end)
menu.action(nearbyMenu, "Cargobob Nearby Cars", {}, "Ignores players, so they can watch :)\nMay have a small chance of crashing, don't spam it too quickly.", function(_)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local cargobobs = {}
    for _, vehicle in ipairs(util.get_all_vehicles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if VEHICLE.IS_THIS_MODEL_A_CAR(model) and not ENTITY.IS_ENTITY_ATTACHED_TO_ANY_VEHICLE(vehicle) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver == 0 or not PED.IS_PED_A_PLAYER(driver) then
                local pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
                local dist = SYSTEM.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 10000.0 then
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, false)
                    VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargobob, false)
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
                    util.delete_entity(driver)
                    util.delete_entity(cargo)
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
            VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargo, true)
        end
        return false
    end)
end)
-- dry violation but fuck you
menu.action(nearbyMenu, "Cargobob Nearby Cars (Magnet)", {}, "Ignores players, so they can watch :)\nMay have a small chance of crashing, don't spam it too quickly.\nUses magnet", function(_)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local cargobobs = {}
    for _, vehicle in ipairs(util.get_all_vehicles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if VEHICLE.IS_THIS_MODEL_A_CAR(model) and not ENTITY.IS_ENTITY_ATTACHED_TO_ANY_VEHICLE(vehicle) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver == 0 or not PED.IS_PED_A_PLAYER(driver) then
                local pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
                local dist = SYSTEM.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 10000.0 then
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle, true)
                    VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargobob, false)
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
                    util.delete_entity(driver)
                    util.delete_entity(cargo)
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
            VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargo, true)
        end
        return false
    end)
end)
menu.action(nearbyMenu, "Clear All Nearby Cargobobs", {}, "", function(sdfa)
    for _, vehicle in ipairs(util.get_all_vehicles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if model == CARGOBOB_MODEL then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver > 0 and not PED.IS_PED_A_PLAYER(driver) then
                util.delete_entity(driver)
            end
            util.delete_entity(vehicle)
        end
    end
end)
menu.click_slider(nearbyMenu, "Clear All Nearby Vehicles", {"clearvehicles"}, "Clears all nearby vehicles in a range.", 50, 2000, 100, 100, function(range)
    range = range * range
    local vehicles = util.get_all_vehicles()
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
            util.delete_entity(vehicle)
            count = count + 1
        end
    end
    util.toast("Deleted " .. count .. " vehicles")
end)
menu.action(nearbyMenu, "Hijack All Nearby", {"hijackall"}, "Makes npcs hijack all nearby vehicles", function(_)
    for _, vehicle in ipairs(util.get_all_vehicles()) do
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
        TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
    end
end)
menu.action(nearbyMenu, "honk", {"honkall"}, "Makes all nearby vehicles alarms go off", function(_)
    for _, vehicle in ipairs(util.get_all_vehicles()) do
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

local allPlayersMenu = menu.list(menu.my_root(), "All Players", {"vehicleall"}, "Lists of actions activated on all players.")
local allNearOnly = true
menu.toggle(allPlayersMenu, "Near Only", {"allnearby"}, "Should the script work only on nearby vehicles or should it work on all vehicles.\nNote: If enabled for ALL vehicles, menu will auto-spectate each player individually one by one.", function(on)
    allNearOnly = on
end, allNearOnly)

menu.action(allPlayersMenu, "Spawn Vehicle", {"spawnall"}, "Spawns the vehicle name for all players", function(_)
    menu.show_command_box("spawnall ")
end, function(args)
    local model = util.joaat(args)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_A_VEHICLE(model) then
        STREAMING.REQUEST_MODEL(model)
        while not STREAMING.HAS_MODEL_LOADED(model) do
            util.yield()
        end
        local cur_players = players.list(true, true, true)
        for _,pid in pairs(cur_players) do
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
            util.create_vehicle(model, pos, heading)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    else
        util.toast("Could not find that vehicle.")
    end
end)

menu.action(allPlayersMenu, "Upgrade", {"upgradevehicle"}, "Upgrades the vehicle to the highest upgrades", function(_)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        local vehicle = get_player_vehicle_in_control(pid, { near_only = allNearOnly, loops = 10 })
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            for x = 0, 49 do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                util.toast("max for x" .. x .. " is " .. max)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.SET_VEHICLE_MOD(vehicle, 15, 45) -- re-set horn 
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 5)
            for x = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, true)
            end
        end
    end
end)

menu.action(allPlayersMenu, "Performance Upgrade", {"performanceupgradevehicle"}, "Upgrades the following vehicle parts:\nEngine\nTransmission\nBrakes\nArmour\nTurbo", function(_)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        local vehicle = get_player_vehicle_in_control(pid, { near_only = allNearOnly, loops = 10 })
        if vehicle > 0 then
            local mods = { 11, 12, 13, 16 }
            for x in ipairs(mods) do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
        end
    end
end)
menu.action(allPlayersMenu, "Clean Vehicle", {"cleanall"}, "Cleans all players' vehicles", function(_)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        local vehicle = get_player_vehicle_in_control(pid, { near_only = allNearOnly, loops = 10 })
        if vehicle > 0 then
            GRAPHICS.REMOVE_DECALS_FROM_VEHICLE(vehicle)
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
        end
    end
end)

menu.action(allPlayersMenu, "Repair Vehicle", {"repairall"}, "Repair all player's vehicles", function(_)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        local vehicle = get_player_vehicle_in_control(pid, { near_only = allNearOnly, loops = 10 })
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_FIXED(vehicle)
        end
    end
end)

menu.toggle(allPlayersMenu, "Toggle Godmode", {"vehgodall"}, "Toggles all players' vehicles invincibility", function(on)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        local vehicle = get_player_vehicle_in_control(pid, { near_only = allNearOnly, loops = 10 })
        if vehicle > 0 then
            ENTITY.SET_ENTITY_INVINCIBLE(vehicle, on)
        end
    end
end, false)

menu.action(allPlayersMenu, "Set License Plate", {"setlicenseplateall"}, "Sets their vehicles license plate", function(on)
    menu.show_command_box("setlicenseplateall ")
end, function(args)
    local cur_players = players.list(true, true, true)
    for _, pid in pairs(cur_players) do
        local vehicle = get_player_vehicle_in_control(pid, { near_only = allNearOnly, loops = 10 })
        if vehicle > 0 then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, args)
        end
    end
end, false)


local autodriveMenu = menu.list(menu.my_root(), "Autodrive", {"autodrive"}, "Autodrive options")
local drive_speed = 50.0
local drive_style = 0
local is_driving = false

local DRIVING_STYLES = {
    { 786603,       "Normal" },
    { 6,            "Avoid Extremely" },
    { 5,            "Sometimes Overtake" },
    { 1074528293,   "Rushed" },
    { 2883621,      "Ignore Lights" },
    { 786468,       "Avoid Traffic" },
    { 1076,         "Reversed" },
    { 8388614,      "Supposedly Good Driving" },
    { 16777216,     "The Most Efficient", "Goes A to B, not good for vehicles." },
    { 787260,       "Quick & Smart", "Avoids all entities, takes shortest path.\nMost importantly: Uses blinkers!" },
    { 536871299,    "Nervous Driver", "Stops at EVERYTHING. Waits patiently. Avoids highways." },
    { 2147483647,   "Untested, Everything", "All options turned on. Probably awful" },
    { 0,            "Untested, Nothing", "All options turned off. Also probably awful"},
    { 7791,         "Untested. Meh", "Meh. Just used in rockstar scripts. unknown."}
}

-- Grabs the driver, first checks attachments (tow, cargo, etc) then driver seat
function get_my_driver()
    local vehicle = util.get_vehicle()
    local entity = ENTITY.GET_ENTITY_ATTACHED_TO(vehicle)
    if entity > 0 and ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(entity, -1)
        if driver > 0 then
            return driver, entity
        end
        goto continue
    end

    ::continue::
    return VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1), vehicle
end
local chauffeurMenu = menu.list(autodriveMenu, "Chauffeur", {"chauffeur"}, "Make another NPC drive for you.")
local styleMenu = menu.list(autodriveMenu, "Driving Style", {}, "Sets how the ai will drive")

for _, style in pairs(DRIVING_STYLES) do
    local desc = "Sets driving style to " .. style[2]
    if style[3] then
        desc = desc .. "\n" .. style[3]
    end
    menu.action(styleMenu, style[2], { }, desc, function(_)
        driving_mode = style[1]
        if is_driving then
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.SET_DRIVE_TASK_DRIVING_STYLE(ped, style[1])
        end
        util.toast("Set driving style to " .. style[2])
    end)
end

menu.slider(autodriveMenu, "Driving Speed", {"setaispeed"}, "", 0, 200, drive_speed, 5.0, function(speed, prev)
    drive_speed = speed
end)

menu.divider(autodriveMenu, "Drive Actions")

menu.action(autodriveMenu, "Drive to Waypoint", {"aiwaypoint"}, "", function(v)
    local ped, vehicle = get_my_driver()
    is_driving = true

    local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        local pos = HUD.GET_BLIP_COORDS(blip)
        TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, pos.x, pos.y, pos.z, drive_speed, 1.0, vehicleModel, drive_style, 5.0, 1.0)
    else
        util.toast("You have no waypoint to drive to")
    end
end)

local drivetoPlayerMenu = menu.list(autodriveMenu, "Drive To Player", {"drivetoplayer"})
local drivetoPlayers = {}
menu.on_focus(drivetoPlayerMenu, function(_)
    for _, m in ipairs(drivetoPlayers) do
        menu.delete(m)
    end
    drivetoPlayers = {}
    local cur_players = players.list(true, true, true)
    local my_pid = players.user()
    local ped, vehicle = get_my_driver()
    for _ ,pid in ipairs(cur_players) do
        local name = PLAYER.GET_PLAYER_NAME(pid)
        if pid == my_pid then
            name = name .. " (Me)"
        end
        local m = menu.action(drivetoPlayerMenu, name, {"driveto"}, "Drive to the selected player", function(on_click)
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local hash = ENTITY.GET_ENTITY_MODEL(vehicle)
            util.create_tick_handler(function(_)
                local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped)
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, target_pos.x, target_pos.y, target_pos.z, 100, 5, hash, 6, 1.0, 1.0)
                util.yield(5000)
                return ENTITY.DOES_ENTITY_EXIST(target_ped) and ENTITY.DOES_ENTITY_EXIST(ped) and TASK.GET_SCRIPT_TASK_STATUS(ped, 0x93A5526E) < 7
            end)
        end)
        table.insert(drivetoPlayers, m)
    end
end)
menu.action(autodriveMenu, "Drive to Waypoint", {"aiwaypoint"}, "", function(v)
    local ped, vehicle = get_my_driver()
    is_driving = true

    local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        local pos = HUD.GET_BLIP_COORDS(blip)
        TASK.TASK_VEHICLE_DRIVE_TO_COORD(ped, vehicle, pos.x, pos.y, pos.z, drive_speed, 1.0, vehicleModel, drive_style, 5.0, 1.0)
    else
        util.toast("You have no waypoint to drive to")
    end
end)

menu.action(autodriveMenu, "Wander / Hover", {"aiwander"}, "Helicopters will hover instead. Planes idk probably crash", function(v)
    local ped, vehicle = get_my_driver()
    is_driving = true

    TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, drive_speed, drive_style)
end)

menu.action(autodriveMenu, "Stop Driving", {"aistop"}, "", function(v)
    local ped = get_my_driver()
    is_driving = false

    TASK.CLEAR_PED_TASKS(ped)
end)

local autodriveDriver = 0
local autodriveVehicle = 0
local autodriveOnlyWhenOntop = false
menu.toggle(chauffeurMenu, "Stop Driving When Not In/On", {}, "Should the driver stop when you either exit the vehicle or fallen off on top?", function(on)
    autodriveOnlyWhenOntop = on
end, autodriveOnlyWhenOntop)
menu.action(chauffeurMenu, "Spawn Driver", {}, "Will acquire a driver into your last/active vehicle to drive for you. It will automatically hijack any player drivers.\nOnce the ready signal is given, choose a destination.", function(_)
    local vehicle = get_player_vehicle_in_control(players.user())
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    if vehicle > 0 then
        if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
            util.delete_entity(autodriveDriver)
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
                -- PED.SET_PED_AS_ENEMY(ped, true)
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
                -- PED.SET_PED_AS_ENEMY(ped, true)
                TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
                PED.SET_PED_FLEE_ATTRIBUTES(ped, 46, true)
                local tries = 25
                local vehicle = 0
                while tries > 0 and vehicle == 0 do
                    vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    util.yield(1000)
                    tries = tries - 1
                end
                if vehicle == 0 then
                    util.delete_entity(ped)
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
            util.delete_entity(driver)
        end
    else
        util.toast("Player is not in a car or out of range")
    end
end)
menu.action(chauffeurMenu, "Delete Driver", {}, "", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        util.delete_entity(autodriveDriver)
    else
        util.toast("No driver to delete.")
    end
    autodriveDriver = 0
end)
menu.action(chauffeurMenu, "Stop Driving", {}, "Makes the driver stop the vehicle", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(autodriveDriver, true)
        if vehicle == 0 then
            util.toast("Driver is not in a car or out of range")
        else
            TASK.TASK_VEHICLE_TEMP_ACTION(autodriveDriver, vehicle, 1, 100000)
        end
    else
        autodriveDriver = 0
        util.toast("No driver to control, spawn a new driver.")
    end
end)
menu.divider(chauffeurMenu, "Destinations")
menu.action(chauffeurMenu, "Drive to Waypoint", {}, "", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        if HUD.IS_WAYPOINT_ACTIVE() then
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(autodriveDriver, true)
            if vehicle == 0 then
                util.toast("Driver is not in a car or out of range")
            else
                local model = ENTITY.GET_ENTITY_MODEL(vehicle)
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(autodriveDriver, vehicle, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, model, 6, 5.0, 1.0)
            end
        else
            util.toast("You have no waypoint to drive to")
        end
    else
        autodriveDriver = 0
        util.toast("No driver to control, spawn a new driver.")
    end
end)
menu.action(chauffeurMenu, "Wander", {}, "", function(_)
    if autodriveDriver > 0 and ENTITY.DOES_ENTITY_EXIST(autodriveDriver) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(autodriveDriver, true)
        if vehicle == 0 then
            util.toast("Driver is not in a car or out of range")
        else
            TASK.TASK_VEHICLE_DRIVE_WANDER(autodriveDriver, vehicle, 40.0, 6)
        end
    else
        autodriveDriver = 0
        util.toast("No driver to control, spawn a new driver.")
    end
end)

local spinningCars = false
local spinningSpeed = 5.0
menu.toggle(menu.my_root(), "Spinning Cars", {}, "Turn it on and see", function(on)
    spinningCars = on
end, spinningCars)
menu.slider(menu.my_root(), "Spinning Cars Speed", {"spinningspeed"}, "", 0, 300.0, spinningSpeed * 10, 10, function(value)
    if value == 0 then
        spinningSpeed = 0.1
    else
        spinningSpeed = value / 10
    end
end)

util.on_stop(function()
    local ped, vehicle = get_my_driver()

    TASK.CLEAR_PED_TASKS(ped)
    TASK._CLEAR_VEHICLE_TASKS(vehicle)
    if ENTITY.DOES_ENTITY_EXIST(previewVehicle) then
        util.delete_entity(previewVehicle)
    end
end)

for _, pid in pairs(players.list(true, true, true)) do
    setup_action_for(pid)
end

players.on_join(function(pid) setup_action_for(pid) end)
local spinHeading = 0
while true do
    if autodriveDriver > 0 and autodriveOnlyWhenOntop then
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local selfOntop = PED.IS_PED_ON_VEHICLE(my_ped)
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(my_ped, false)
        if not selfOntop and vehicle ~= autodriveVehicle then
            -- VEHICLE.BRING_VEHICLE_TO_HALT(autodriveVehicle, 2.0, 20, false)
            ENTITY.SET_ENTITY_VELOCITY(autodriveVehicle, 0.0, 0.0, 0.0)
        end
    end
    if spinningCars then
        spinHeading = spinHeading + spinningSpeed
        if spinHeading > 360 then
            spinHeading = 0.0
        end
        for _, vehicle in ipairs(util.get_all_vehicles()) do
            -- heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            ENTITY.SET_ENTITY_HEADING(vehicle, spinHeading)
        end
    end
    util.yield()
end