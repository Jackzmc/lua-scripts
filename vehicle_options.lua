-- Vehicle Options - 1.4
-- Created By Jackz

-- V1.2
-- Fixed bugs, added 'Set License Plate'

-- V1.3
-- Fix teleport far not returning self to vehicle
-- (Untested) Support spectating other players. Should work with Teleport Vehicle

-- V1.4
-- Added door controls
-- Rearranged menu options

require("natives-1627063482")

-- If set to true, acts on their last vehicle
local tp_last_option = {}
local is_tping = false

local DOOR_NAMES = {
    "Front Left",
    "Front Right",
    "Back Left",
    "Back Right",
    "Engine",
    "Trunk",
    "Back",
    "Back 2",
}

-- Gets the player's vehicle, attempts to request control. Returns 0 if unable to get control
-- TODO: Check if player already has control, return early
function get_player_vehicle_in_control(pid)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()) -- Needed to turn off spectating while getting control
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, tp_last_option[pid])
    local was_spectating = NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() -- Needed to toggle it back on if currently spectating
    
    if vehicle > 0 then
        -- Loop until we get control
        -- TODO: Check if spectating undo for a sec
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
        local has_control_ent = false
        local has_control_net = false
        local loops = 0
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(false,my_ped)
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)

        -- Attempts 15 times, with 8ms per attempt
        while not has_control_ent and not has_control_net do
            has_control_ent = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            has_control_net = NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netid)
            loops = loops + 1
            -- wait for control
            util.yield(15)
            if loops >= 15 then
                if was_spectating then
                    NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, my_ped)
                end
                return 0
            end
        end

        if was_spectating then
            NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, my_ped)
        end

        return vehicle
    else
        return 0
    end
end



function setup_action_for(pid) 
    local submenu = menu.list(menu.player_root(pid), "Vehicle Options", {}, "List of vehicle options")


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

    menu.action(submenu, "Teleport Vehicle to Me (Far Distance)", {"tpvehmefar"}, "Teleports their vehicle to your location by teleporting to them", function(on_click)
        -- Ignore spamming of action
        if not is_tping then
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local my_pos = ENTITY.GET_ENTITY_COORDS(my_ped, 1)
            local target_pos = ENTITY.GET_ENTITY_COORDS(target_ped, 1)
            local isWasVisible = ENTITY.IS_ENTITY_VISIBLE(my_ped)
            local myVehicle = PED.GET_VEHICLE_PED_IS_IN(my_ped, false)
            
            -- Set self to invisible if not already
            if isWasVisible then
                ENTITY.SET_ENTITY_VISIBLE(my_ped, false)
            end
            ENTITY.FREEZE_ENTITY_POSITION(my_ped, true)
            -- Teleport self to them and wait ~ 300ms
            is_tping = true
            util.toast("Teleporting to their location to acquire vehicle...")
            ENTITY.SET_ENTITY_COORDS(my_ped, target_pos.x + 30.0, target_pos.y, target_pos.z - 100.0, 1, 1, 0, 0)
            local loops = 0
            local vehicle = 0
            while vehicle == 0 and loops <= 20 do
                util.yield(200)
                vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, false)
                loops = loops + 1
            end
            if vehicle then
                vehicle = get_player_vehicle_in_control(pid, 1)
                -- Then teleport both vehicle and self back to original point
                ENTITY.SET_ENTITY_COORDS(vehicle, my_pos.x, my_pos.y, my_pos.z, 0, 0, 0, 0)
            else
                util.toast("Failed to find a vehicle after " .. loops .. " attempts")
            end
            is_tping = false
            if isWasVisible then
                ENTITY.SET_ENTITY_VISIBLE(my_ped, true)
            end
            ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
            if myVehicle > 0 then
                PED.SET_PED_INTO_VEHICLE(my_ped, myVehicle, -1)
            end
            ENTITY.SET_ENTITY_COORDS(my_ped, my_pos.x, my_pos.y, my_pos.z , 0, 0, 0, 0)
            util.yield(100)
            ENTITY.SET_ENTITY_VELOCITY(my_ped, 0, 0, 0)
        end
    end)
    ----------------------------------------------------------------
    -- Movement Section
    ----------------------------------------------------------------
    local movementMenu = menu.list(submenu, "Movement", {}, "List of vehicle movement options.\nBoost, Launch, Slingshot, Stop")

    menu.click_slider(movementMenu, "Boost", {"boost"}, "Boost the player's vehicle forwards at a given speed (mph)", -200, 200, 200, 10, function(mph)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

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
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100.0)
            local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z + 100.0)
            VEHICLE.RESET_VEHICLE_WHEELS(vehicle)
        end
    end)

    menu.click_slider(movementMenu, "Launch", {"launch"}, "Boost the player's vehicle upwards", -200, 200, 200, 10, function(mph)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local speed = mph / 0.44704

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            ENTITY.SET_ENTITY_VELOCITY(vehicle, 0.0, 0.0, speed)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(movementMenu, "Stop", {"stopvehicle"}, "Stops the player's engine", function(on_click)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
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
    ----------------------------------------------------------------
    -- END Door Section
    ----------------------------------------------------------------

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

    menu.action(submenu, "Flip Upright", {"flipveh"}, "Flips the player's vehicle upwards", function(on_click)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, rot.y, 0)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.toggle(submenu, "Engine On", {"setenginestate"}, "", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(vehicle) then
                VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, false, true, false)
            else
                VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, false)
            end
        else
            util.toast("Player is not in a car or out of range")
        end
    end, true)

    menu.action(submenu, "Kill Engine", {"killengine"}, "Kills the player's vehicle engine", function(on_click)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Repair Vehicle", {"repairvehicle"}, "Repairs the player's vehicle", function(on_click)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_FIXED(vehicle)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.toggle(submenu, "Toggle Godmode", {"setvehgod"}, "Toggles their vehicle invincibility", function(on)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
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
        tp_last_option[pid] = on
    end, false)
end

local cur_players = players.list(true, true, true)
for k,pid in pairs(cur_players) do
    tp_last_option[pid] = false
    setup_action_for(pid)
end

players.on_join(function(pid)
    tp_last_option[pid] = false
    setup_action_for(pid)
end)

while true do
    util.yield()
end