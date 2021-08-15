-- Vehicle Options - 1.5.2
-- Created By Jackz
-- See changelog in changelog.txt

require("natives-1627063482")

local options = {}

local DOOR_NAMES = {
    "Front Left", "Front Right",
    "Back Left", "Back Right",
    "Engine", "Trunk",
    "Back", "Back 2",
}
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
    if dist > 340000 and not was_spectating then
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


function setup_action_for(pid) 
    local submenu = menu.list(menu.player_root(pid), "Vehicle Options", {}, "List of vehicle options")
    options[pid] = {
        teleport_last = false,
        paint_color_primary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        paint_color_secondary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        neon_color = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
    }

    menu.action(menu.my_root(), "get modkit", {}, "", function(a)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())

        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle then
            local numb = VEHICLE.GET_NUM_MOD_KITS(vehicle)
            local modkit = VEHICLE.GET_VEHICLE_MOD_KIT(vehicle)
            util.toast(numb .. " " .. modkit)
        else
            util.toast("Player is not in a car or out of range. Try spectating them")
        end
    end)
    menu.click_slider(menu.my_root(), "set modkit", {"setmodkit"}, "", 0, 10, 1, 1, function(value)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, value)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

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
    local lsc = menu.list(submenu, "Customize", {}, "Customize the players vehicle options\nSet headlights\nSet Paint Color")
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

    -- TODO: Customize lights (head, rear, neon, etc, toggle)
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
    ----------------------------------------------------------------
    -- END LSC
    ----------------------------------------------------------------

    menu.action(submenu, "Flip Upright", {"flipveh"}, "Flips the player's vehicle upwards", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
            ENTITY.SET_ENTITY_ROTATION(vehicle, 0, rot.y, rot.z)
        else
            util.toast("Player is not in a car or out of range")
        end
    end)

    menu.action(submenu, "Spawn", {"spawnfor"}, "Spawns the vehicle name for the player", function(on)
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

    menu.action(submenu, "Kill Engine", {"killengine"}, "Kills the player's vehicle engine", function(on_click)
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
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