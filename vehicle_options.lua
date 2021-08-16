-- Vehicle Options
-- Created By Jackz
-- See changelog in changelog.md
local SCRIPT = "vehicle_options"
local VERSION = "1.8.2"
luahttp = require("luahttp")
local result = luahttp.request("GET", "jackz.me", "/stand/updatecheck.php?script=" .. SCRIPT .. "&v=" .. VERSION)
if result == "OUTDATED" then
    util.toast("A new version of " .. SCRIPT .. " is available")
end

-- TODO: Clone Vehicle
-- TODO: Save / Spawn Saved Per-Player

require("natives-1627063482")
json = require('json')

-- Per-player options
local options = {}

local DOOR_NAMES = {
    "Front Left", "Front Right",
    "Back Left", "Back Right",
    "Engine", "Trunk",
    "Back", "Back 2",
}
-- Subtract index by 1 to get modIndex (ty lua)
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
    [19] = "Turbo Turning",
    [21] = "Tire Smoke",
    [22] = "Xenon Headlights",
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


function setup_action_for(pid) 
    local submenu = menu.list(menu.player_root(pid), "Vehicle Options", {"vehicle"}, "List of vehicle options")
    options[pid] = {
        teleport_last = false,
        paint_color_primary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        paint_color_secondary = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
        neon_color = { r = 1.0, g = 0.412, b = 0.706, a = 1 },
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

    local subMenus = {}
    local modMenu = menu.list(lsc, "Vehicle Mods", {}, "")
    menu.on_focus(modMenu, function()
        for _, m in ipairs(subMenus) do
            menu.delete(m)
        end
        subMenus = {}
        local vehicle = get_player_vehicle_in_control(pid)
        if vehicle > 0 then
            -- TODO: Make default value be current value?
            for i, mod in pairs(MOD_TYPES) do
                local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i - 1)
                local m = menu.slider(modMenu, mod, {"set" .. mod}, string.format("Apply upto %d variations of %s", max, mod), 0, max, 0, 1, function(index)
                    local vehicle = get_player_vehicle_in_control(pid)
                    if vehicle > 0 then
                       VEHICLE.SET_VEHICLE_MOD(vehicle, i - 1, index)
                    else
                        util.toast("Player is not in a car or out of range")
                    end
                end)
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

    local mods = {}
    for i, modName in pairs(MOD_TYPES) do
        mods[modName] = VEHICLE.GET_VEHICLE_MOD(vehicle, i - 1)
    end

    local saveData = {
        Format = "JSTAND 1.0",
        Model = model,
        Name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model) ,
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
        ["Dashboard Color"] = DashboardColor,
        ["Interior Color"] = InteriorColor,
        ["Dirt Level"] = VEHICLE.GET_VEHICLE_DIRT_LEVEL(vehicle),
        ["Bulletproof Tires"] = VEHICLE.GET_VEHICLE_TYRES_CAN_BURST(vehicle),
        Mods = mods
    }

    return saveData
end
function apply_vehicle_save_data(vehicle, saveData) 
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
    VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, saveData["Tire Smoke"].r, saveData["Tire Smoke"].g, saveData["Tire Smoke"].b)
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, saveData["Bulletproof Tires"])
    VEHICLE._SET_VEHICLE_DASHBOARD_COLOR(vehicle, saveData["Dashboard Color"])
    VEHICLE._SET_VEHICLE_INTERIOR_COLOR(vehicle, saveData["Interior Color"])
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, saveData["Dirt Level"])
    VEHICLE.SET_VEHICLE_ENVEFF_SCALE(vehicle, saveData["Colors"]["Paint Fade"])

    for i, modName in pairs(MOD_TYPES) do
        if saveData.Mods[modName] then
            VEHICLE.SET_VEHICLE_MOD(vehicle, i - 1, saveData.Mods[modName])
        end
    end

    VEHICLE._SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, saveData.Lights.Neon.Color.r, saveData.Lights.Neon.Color.g, saveData.Lights.Neon.Color.b)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 0, saveData.Lights.Neon.Left)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 1, saveData.Lights.Neon.Right)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 2, saveData.Lights.Neon.Front)
    VEHICLE._SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, 3, saveData.Lights.Neon.Back)

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
            local m = menu.action(savedVehiclesList, name, {"spawnvehicle" .. name}, "Spawns a saved custom vehicle", function(on_click)
                local file = io.open(vehicleDir .. name, "r")
                io.input(file)
                local saveData = json.decode(io.read("*a"))
                io.close(file)
                if saveData['Model'] ~= nil then
                    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 5.0, 0.5)
                    local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
                    local vehicle
                    if applySaved then
                        local v = util.get_vehicle()
                        if v == 0 then
                            util.toast("You must be in a vehicle to apply")
                        else
                            vehicle = v
                        end
                        util.toast("Applied " .. name .. " to your current vehicle")
                    else
                        util.create_vehicle(saveData.Model, pos, heading)
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