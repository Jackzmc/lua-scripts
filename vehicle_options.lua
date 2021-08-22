-- Vehicle Options
-- Created By Jackz
-- See changelog in changelog.md
local SCRIPT = "vehicle_options"
local VERSION = "1.12.0"
-- Remove these lines if you want to disable update-checks: (6-15)
util.async_http_get("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        util.toast(SCRIPT .. " has a new version available.\n" .. VERSION .. " -> " .. chunks[2] .. "\nDownload the latest version from https://jackz.me/sz")
    end
end)
local WaitingLibsDownload = false
function try_load_lib(lib)
    local status = pcall(require, lib)
    if not status then
        WaitingLibsDownload = true
        util.async_http_get("jackz.me", "/stand/libs/" .. lib .. ".lua", function(result)
            local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib .. ".lua", "w")
            io.output(file)
            io.write(result)
            io.close(file)
            WaitingLibsDownload = false
            util.toast(SCRIPT .. ": Automatically downloaded missing lib '" .. lib .. ".lua'")
            require(lib)
        end, function(e)
            util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
            util.stop_script()
        end)
    end
end
try_load_lib("natives-1627063482")
try_load_lib("json")

while WaitingLibsDownload do
    util.yield()
end

--TODO: Idea: Cloud vehicles. Submenu:
-- "Spawn" "Spawn Inside" "Uplaod to Cloud Vehicles"
-- Download from Cloud Vehicles

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
local VEHICLE_SAVEDATA_FORMAT_VERSION = "JSTAND 1.1"
local TOW_TRUCK_MODEL_1 = util.joaat("towtruck")
local TOW_TRUCK_MODEL_2 = util.joaat("towtruck2")
local NEON_INDICES = { "Left", "Right", "Front", "Back"}

-- Gets the player's vehicle, attempts to request control. Returns 0 if unable to get control
function get_player_vehicle_in_control(pid)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()) -- Needed to turn off spectating while getting control
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)

    -- Calculate how far away from target
    local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped)
    local pos2 = ENTITY.GET_ENTITY_COORDS(my_ped)
    local dist = SYSTEM.VDIST2(pos1.x, pos1.y, 0, pos2.x, pos2.y, 0)

    local was_spectating = NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() -- Needed to toggle it back on if currently spectating
    -- If they out of range (value may need tweaking), auto spectate.
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, options[pid].teleport_last)
    if target_ped ~= my_ped and dist > 340000 and not was_spectating then
        util.toast("Player is too far, auto-spectating for upto 3s.")
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
        -- To prevent a hard 3s loop, we keep waiting upto 3s or until vehicle is acquired
        local loop = 30 -- 3000 / 100
        while vehicle == 0 and loop > 0 do
            util.yield(100)
            vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, options[pid].teleport_last)
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
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(false, target_ped)
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
        if was_spectating then
            NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
        else
            NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(false, target_ped)
        end
    end
    if was_spectating then
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
    else
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
    local pos = ENTITY.GET_ENTITY_COORDS(vehicle)
    VEHICLE.ATTACH_VEHICLE_ON_TO_TRAILER(vehicle, trailer, 0, 0, -2.0, 0, 0, 0.0, 0, 0, 0, 0.0)
    ENTITY.DETACH_ENTITY(vehicle)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(cab, true)
    util.yield(1)
    return cab, driver
end

local CARGOBOB_MODEL = util.joaat("cargobob")
function spawn_cargobob_for_vehicle(vehicle) 
    STREAMING.REQUEST_MODEL(CARGOBOB_MODEL)
    while not STREAMING.HAS_MODEL_LOADED(CARGOBOB_MODEL) do
        util.yield()
    end
    local vehPos = ENTITY.GET_ENTITY_COORDS(vehicle)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0, 8.0)
    local z = memory.alloc(8)
    if(MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, z, false)) then
        pos.z = memory.read_float(z) + 10.0
    end
    memory.free(z)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 10)
    local cargobob = util.create_vehicle(CARGOBOB_MODEL, pos, heading)
    VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargobob, true)
    VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(cargobob)
    VEHICLE.CREATE_PICK_UP_ROPE_FOR_CARGOBOB(cargobob, 0)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(cargobob)
    local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(cargobob, true)
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
    ENTITY.SET_ENTITY_VELOCITY(cargobob, 0, 0, 0)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
    local tries = 0
    while not VEHICLE.IS_VEHICLE_ATTACHED_TO_CARGOBOB(cargobob, vehicle) and tries < 20 do
        VEHICLE.ATTACH_VEHICLE_TO_CARGOBOB(cargobob, vehicle, -2, 0, 0, 0)
        tries = tries + 1
        util.yield(50)
    end
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
    util.yield(1)
    return cargobob, driver
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
        trailer_gate = true
    }

    menu.action(submenu, "Teleport Vehicle to Me", {"tpvehme"}, "Teleports their vehicle to your location", function(on_click)
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
    -- Movement Section
    ----------------------------------------------------------------
    local movementMenu = menu.list(submenu, "Movement", {}, "List of vehicle movement options.\nBoost, Launch, Slingshot, Stop")

    local towMenu = menu.list(movementMenu, "Attachments", {"attachments"}, "Attach their vehicle to:\nCargobobs\nTow Trucks")
    -- TOW 
        menu.divider(towMenu, "Tow Trucks")
        menu.action(towMenu, "Tow (Wander)", {"towwander"}, "Will make a random tow truck tow the player's vehicle randomly around", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local tow, driver = spawn_tow_for_vehicle(vehicle)
                TASK.TASK_VEHICLE_DRIVE_WANDER(driver, tow, 30.0, 786603)
            end
        end)

        menu.action(towMenu, "Tow To Waypoint", {"towwaypoint"}, "Will make a random tow truck tow the player's vehicle to your waypoint", function(on_click)
            local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
            if HUD.IS_WAYPOINT_ACTIVE() then
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                local vehicle = get_player_vehicle_in_control(pid)
                if vehicle == 0 then
                    util.toast("Player is not in a car or out of range")
                else
                    local tow, driver, model = spawn_tow_for_vehicle(vehicle)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, tow, waypoint_pos.x, waypoint_pos.y, waypoint_pos.z, 35.0, 1.0, model, 786603, 5.0, 1.0)
                end
            else
                util.toast("You have no waypoint to drive to")
            end
        end)
        
        menu.action(towMenu, "Detach Tow", {"detachtow"}, "Will detach from any tow truck", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle > 0 then
                VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(vehicle)
            else
                util.toast("Player is not in a car or out of range")
            end
        end)

        menu.divider(towMenu, "Cargobob")

        menu.action(towMenu, "Cargobob To Mt. Chiliad", {"cargobobmt"}, "Will make a random cargobob take the player's vehicle to mount chiliad", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local cargobob, driver = spawn_cargobob_for_vehicle(vehicle)
                TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, cargobob, 450.718 , 5566.614, 806.183, 100.0, 1.0, CARGOBOB_MODEL, 786603, 5.0, 1.0)
            end
        end)

        menu.action(towMenu, "Cargobob To Ocean", {"cargobobocean"}, "Will make a random cargobob take the player's vehicle to the ocean", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local cargobob, driver = spawn_cargobob_for_vehicle(vehicle)
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

        menu.action(towMenu, "Cargobob To Waypoint", {"cargobobwaypoint"}, "Will make a random cargobob take the player's vehicle to your waypoint", function(on_click)
            local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
            if HUD.IS_WAYPOINT_ACTIVE() then
                local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
                local vehicle = get_player_vehicle_in_control(pid)
                if vehicle == 0 then
                    util.toast("Player is not in a car or out of range")
                else
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle)
                    
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
            else
                util.toast("Player is not in a car or out of range")
            end
        end)

        menu.divider(towMenu, "Trailers")

        menu.action(towMenu, "Drive Around", {"trailerwander"}, "Will make a random cab & trailer take the player's vehicle randomly around", function(on_click)
            local vehicle = get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                util.toast("Player is not in a car or out of range")
            else
                local cab, driver = spawn_cab_and_trailer_for_vehicle(vehicle, options[pid].trailer_gate)
                TASK.TASK_VEHICLE_DRIVE_WANDER(driver, cab, 30.0, 786603)
            end
        end)

        menu.action(towMenu, "Take To Waypoint", {"trailerwaypoint"}, "Will make a random cab & trailer take the player's vehicle to your waypoint", function(on_click)
            local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
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

        menu.divider(towMenu, "Misc")

        menu.action(towMenu, "Free Vehicle", {"freevehicle"}, "Teleports the vehicle upwards to escape trailers or other objects", function(on_click)
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

    menu.action(movementMenu, "Slingshot", {"slingshot"}, "Boost the player's vehicle forward at a given speed (mph) & upwards", function(on_click)
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

    menu.action(movementMenu, "Stop", {"stopvehicle"}, "Stops the player's engine", function(on_click)
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

    menu.action(door_submenu, "All Doors", {}, "", function()
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
        menu.action(door_submenu, name, {}, "Opens or closes " .. name, function()
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
    menu.on_focus(lsc, function()

    end)
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
    local neon_states = {}
    local neon_menus = {}
    menu.action(neon, "Apply Neon Color", {"paintneon"}, "Applies neon colors with the color selected below", function(on_click)
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
                local m = menu.toggle(neon, NEON_INDICES[x+1], {}, "Turns on the player's neon lights", function(on_click)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle > 0 then
                        local enabled = VEHICLE._IS_VEHICLE_NEON_LIGHT_ENABLED(vehicle, x)
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
            local r = math.floor(options[pid].paint_color_secondary.r * 255)
            local g = math.floor(options[pid].paint_color_secondary.g * 255)
            local b = math.floor(options[pid].paint_color_secondary.b * 255)
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
    menu.on_focus(modMenu, function()
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

    menu.action(lsc, "Upgrade", {"upgradevehicle"}, "Upgrades the vehicle to the highest upgrades", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            for x = 0, 16 do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
                VEHICLE.SET_VEHICLE_MOD(vehicle, x, max)
            end
            VEHICLE.SET_VEHICLE_MOD(vehicle, x, 45)
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 5)
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(lsc, "Performance Upgrade", {"performanceupgradevehicle"}, "Upgrades the following vehicle parts:\nEngine\nTransmission\nBrakes\nArmour\nTurbo", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            for x = 11, 13 do
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

    menu.action(submenu, "Clone Vehicle", {"clonevehicle"}, "Clones the player's vehicle", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local saveData = get_vehicle_save_data(vehicle)
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 5.0, 0.5)
            local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
            local vehicle = util.create_vehicle(saveData.Model, pos, heading)
            apply_vehicle_save_data(vehicle, saveData)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Save Vehicle", {"saveplayervehicle"}, "Saves the player's vehicle to disk", function(on_click)
        util.toast("Enter a name to save the vehicle as")
        menu.show_command_box("savevehicle ")
    end, function(args)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local saveData = get_vehicle_save_data(vehicle)

            filesystem.mkdirs(vehicleDir)
            local file = io.open( vehicleDir .. args .. ".json", "w")
            io.output(file)
            io.write(json.encode(saveData))
            io.close(file)
            util.toast("Saved to %appdata%\\Stand\\Vehicles\\" .. args .. ".json")
        else
            util.toast("Player is not in a car or out of range")
        end
    end)
    menu.action(submenu, "Flip Upright", {"flipveh"}, "Flips the player's vehicle upwards", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, rot.y, rot.z)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Spawn Vehicle", {"spawnfor"}, "Spawns the vehicle name for the player", function(on)
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
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        else
            util.toast("Could not find that vehicle.")
        end

    end, false)

    menu.action(submenu, "Flip Vehicle 180", {"flipv"}, "Flips the player's vehicle around", function(v)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, -rot.z)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.click_slider(submenu, "Hijack Vehicle", {"hijack"}, "Makes a random NPC hijack their vehicle\n 0 = Doors Unlocked\n 1 = Doors Locked", 0, 1, 0, 1, function(hijackLevel)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -2.0, 0.0, 0.1)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
            local ped = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true)
            TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100.0, 2883621)
            if hijackLevel == 1 then
                util.yield(20)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Burst Tires", {"bursttires", "bursttyres"}, "Bursts the player's vehicle tires", function(on_click)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

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
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, args)
        else
            util.toast("Player is not in a car or out of range")
        end
    end, false)

    menu.toggle(submenu, "Activate on Last Vehicle", {}, "Will activate on the player's last vehicle, if they arent in a vehicle", function(on)
        options[pid].teleport_last = on
    end, false)
end
local vehicleDir = filesystem.stand_dir() .. "/Vehicles/"
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
    VEHICLE.SET_VEHICLE_COLOUR_COMBINATION(vehicle, saveData.Colors["Color Combo"])
    VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, saveData.Colors.Extras.r, saveData.Colors.Extras.g, saveData.Colors.Extras.b)
    VEHICLE.SET_VEHICLE_COLOURS(vehicle, saveData.Colors.Vehicle.Primary, saveData.Colors.Vehicle.Secondary)
    if saveData.Colors.Primary.Custom then
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, saveData.Colors.Primary["Custom Color"].r, saveData.Colors.Primary["Custom Color"].b, saveData.Colors.Primary["Custom Color"].g)
    else
        VEHICLE.SET_VEHICLE_MOD_COLOR_1(vehicle, saveData.Colors.Primary["Paint Type"], saveData.Colors.Primary.Color, saveData.Colors.Primary["Pearlescent Color"])
    end
    if saveData.Colors.Secondary.Custom then
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, saveData.Colors.Secondary["Custom Color"].r,  saveData.Colors.Secondary["Custom Color"].b, saveData.Colors.Secondary["Custom Color"].g)
    else
        VEHICLE.SET_VEHICLE_MOD_COLOR_2(vehicle, saveData.Colors.Secondary["Paint Type"], saveData.Colors.Secondary.Color, saveData.Colors.Secondary["Pearlescent Color"])
    end
    VEHICLE.SET_VEHICLE_ENVEFF_SCALE(vehicle, saveData["Colors"]["Paint Fade"])
    -- Misc Colors / Looks
    VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, saveData["Tire Smoke"].r, saveData["Tire Smoke"].g, saveData["Tire Smoke"].b)
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, saveData["Bulletproof Tires"])
    VEHICLE._SET_VEHICLE_DASHBOARD_COLOR(vehicle, saveData["Dashboard Color"])
    VEHICLE._SET_VEHICLE_INTERIOR_COLOR(vehicle, saveData["Interior Color"])
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, saveData["Dirt Level"])

    -- Lights
    VEHICLE._SET_VEHICLE_XENON_LIGHTS_COLOR(vehicle, saveData["Lights"]["Xenon Color"])
    VEHICLE._SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, saveData.Lights.Neon.Color.r, saveData.Lights.Neon.Color.g, saveData.Lights.Neon.Color.b)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 0, saveData.Lights.Neon.Left)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 1, saveData.Lights.Neon.Right)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 2, saveData.Lights.Neon.Front)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 3, saveData.Lights.Neon.Back)

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
    VEHICLE.SET_VEHICLE_LIVERY(vehicle, saveData.Livery.style)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, saveData["Window Tint"])
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, saveData["License Plate"].Text)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle, saveData["License Plate"].Type)

end
menu.action(menu.my_root(), "Save Current Vehicle", {"savevehicle"}, "Saves your current vehicle with all customizations", function(on_click)
    util.toast("Enter a name to save the vehicle as")
    menu.show_command_box("savevehicle ")
end, function(args)
    local vehicle = util.get_vehicle()
    local saveData = get_vehicle_save_data(vehicle)

    filesystem.mkdirs(vehicleDir)
    local file = io.open( vehicleDir .. args .. ".json", "w")
    io.output(file)
    io.write(json.encode(saveData))
    io.close(file)
    util.toast("Saved to %appdata%\\Stand\\Vehicles\\" .. args .. ".json")
end)
local savedVehiclesList = menu.list(menu.my_root(), "Spawn Saved Vehicles", {}, "List of spawnable saved vehicles.\nStored in %appdata%\\Stand\\Vehicles")
local savedVehicleMenus = {}
local applySaved = false
menu.toggle(menu.my_root(), "Apply Saved to Current Vehicle", {}, "Instead of spawning a new saved vehicle, it will instead apply it to your current vehicle.", function(on)
    applySaved = on
end, applySaved)
menu.on_focus(savedVehiclesList, function()
    for _, m in pairs(savedVehicleMenus) do
        menu.delete(m)
    end
    savedVehicleMenus = {}
    for _, file in ipairs(filesystem.list_files(vehicleDir)) do
        local _, name, ext = string.match(file, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if ext == "json" then
            local file = io.open(vehicleDir .. name, "r")
            io.input(file)
            local saveData = json.decode(io.read("*a"))
            io.close(file)
            local manuf = saveData.Manufacturer and saveData.Manufacturer .. " " or ""
            local desc = string.format("Vehicle: %s%s (%s)\nFormat Version: %s", manuf, saveData.Name, saveData.Type, saveData.Format)
            local displayName = string.sub(name, 0, -6)
            local m = menu.action(savedVehiclesList, "Spawn", {"spawnvehicle" .. displayName}, "Spawns a saved custom vehicle\n" .. desc, function(on_click)
                if saveData['Model'] ~= nil then
                    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 5.0, 0.5)
                    local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
                    local vehicle = 0
                    if applySaved then
                        local v = util.get_vehicle()
                        if v == 0 then
                            util.toast("You must be in a vehicle to apply")
                        else
                            vehicle = v
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
                else
                    util.toast("JSON Vehicle is invalid, missing 'Model' parameter.")
                end
            end)
            table.insert(savedVehicleMenus, m)
        end
    end
end)
local spawned_tows = {}
menu.action(menu.my_root(), "Tow All Nearby Vehicles", {}, "WARNING: This can make your FPS drop or even crash your game!\nLimited to 30 tow trucks to prevent crashes.", function(sdfa)
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
        if model ~= towtruck_1 and model ~= towtruck_2 and VEHICLE.IS_THIS_MODEL_A_CAR(model) then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 8, 0.1)
            MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pz, true)
            pos.z = memory.read_float(pz)
            local dist = SYSTEM.VDIST2(my_pos.x, my_pos.y, my_pos.z, pos.x, pos.y, pos.z)
            table.insert(nearby_vehicles, { vehicle, dist, pos, model })
        end
    end
    memory.free(pz)
    table.sort(nearby_vehicles, function(a, b) return a[2] > b[2] end)
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
menu.action(menu.my_root(), "Clear All Nearby Tows", {}, "", function(sdfa)
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
menu.action(menu.my_root(), "Cargobob Nearby Cars", {}, "Ignores players, so they can watch :)\nMay have a small chance of crashing, don't spam it too quickly.", function(a)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local cargobobs = {}
    for _, vehicle in ipairs(util.get_all_vehicles()) do
        local model = ENTITY.GET_ENTITY_MODEL(vehicle)
        if VEHICLE.IS_THIS_MODEL_A_CAR(model) and not ENTITY.IS_ENTITY_ATTACHED_TO_ANY_VEHICLE(vehicle) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver == 0 or not PED.IS_PED_A_PLAYER(driver) then
                local pos2 = ENTITY.GET_ENTITY_COORDS(vehicle, 1)
                local dist = SYSTEM.VDIST(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 100.0 then
                    local cargobob, driver = spawn_cargobob_for_vehicle(vehicle)
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
    util.create_tick_handler(function(a)
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
                util.yield(2000)
                iterations = iterations + 1
                if iterations >= 15 then
                    break
                end
            end
        end
        util.yield(3000)
        for _, cargo in ipairs(cargobobs) do
            ENTITY.SET_ENTITY_INVINCIBLE(cargo, false)
            VEHICLE._SET_CARGOBOB_HOOK_CAN_DETACH(cargobob, true)
        end
        return false
    end)
end)
menu.action(menu.my_root(), "Clear All Nearby Cargobobs", {}, "", function(sdfa)
    local vehicles = util.get_all_vehicles()
    for _, vehicle in ipairs(vehicles) do
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

local cur_players = players.list(true, true, true)
for k,pid in pairs(cur_players) do
    setup_action_for(pid)
end

players.on_join(function(pid)
    setup_action_for(pid)
end)

while true do
    util.yield()
end