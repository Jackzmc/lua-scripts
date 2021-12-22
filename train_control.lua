-- Train Control
-- Created By Jackz
local SCRIPT = "train_control"
local VERSION = "1.1.5"
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
function show_busyspinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end
local WaitingLibsDownload = false
function try_load_lib(lib)
    local status = pcall(require, lib)
    if not status then
        WaitingLibsDownload = true
        async_http.init("jackz.me", "/stand/libs/" .. lib .. ".lua", function(result)
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
        async_http.dispatch()
    end
end
try_load_lib("natives-1639742232")

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

-- Models[1] && Models[2] are engines
local models = {
    util.joaat("metrotrain"), util.joaat("freight"), util.joaat("freightcar"), util.joaat("freightcar2"), util.joaat("freightcont1"), util.joaat("freightcont2"), util.joaat("freightgrain"), util.joaat("tankercar")
}
local last_train = 0
local last_metro_f = 0
local last_metro_b = 0
local last_train_menu = 0
local globalTrainSpeed = 15
local globalTrainSpeedControlEnabled = false

show_busyspinner("Loading Train Models")
for _, model in ipairs(models) do
    STREAMING.REQUEST_MODEL(model)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
end
HUD.BUSYSPINNER_OFF()

local spawnedMenu = menu.list(menu.my_root(), "Spawned Train Management", {}, "")
local function spawn_train(variation, pos, direction) 
    local train = VEHICLE.CREATE_MISSION_TRAIN(variation, pos.x, pos.y, pos.z, direction or false)
    local carts = {}
    for i = 0, 100 do
        local cart = VEHICLE.GET_TRAIN_CARRIAGE(train, i)
        if cart == 0 then
            break
        end
        table.insert(carts, cart)
    end
    last_train = train
    
    local posTrain = ENTITY.GET_ENTITY_COORDS(last_train)
    local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(train)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netid)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, false)
    -- Setup menu actions (set speed, delete, etc)
    local submenu = menu.list(spawnedMenu, "Train " .. last_train, {"train" .. last_train}, "") 
    menu.slider(submenu, "Set Speed", {"setspeedtrain" .. last_train}, "Sets this spawned train's speed. Values over +/- 80 will result in players sliding backwards. Reversing trains will look desynced to other players.", -250, 250, 10, 5, function(value, prev)
        VEHICLE.SET_TRAIN_CRUISE_SPEED(train, value)
        VEHICLE.SET_TRAIN_SPEED(train, value)
    end)

    menu.toggle(submenu, "Derail", {"derailtrain" .. last_train}, "Visually derails the train", function(on)
        VEHICLE.SET_RENDER_TRAIN_AS_DERAILED(train, on)
    end, false)

    menu.action(submenu, "Delete Engine", {"deleteengine" .. last_train}, "Deletes the spawned train's engine", function(v)
        entities.delete(train)
    end)

    menu.action(submenu, "Delete", {"deletetrain" .. last_train}, "Deletes the spawned train", function(v)
        for _, cart in ipairs(carts) do
            entities.delete(cart)
        end
        menu.delete(submenu)
    end)

    util.toast(string.format("Train spawned at (%.1f, %.1f, %.1f) variant %d", posTrain.x, posTrain.y, posTrain.z, variation))
    last_train_menu = submenu
    return train
end

-- MENU SETUP


menu.divider(menu.my_root(), "Train Spawning")

menu.click_slider(menu.my_root(), "Spawn Train", {"spawntrain"}, "Spawns a train with a certain variation\n22 = Metro\n23 = Long Train", 1, 25, 1, 1, function(variation)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    spawn_train(variation - 1, pos)
end)

menu.action(menu.my_root(), "Spawn Metro Train", {"spawnmetro"}, "Spawn a metro train", function()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    local metroFront = VEHICLE.CREATE_MISSION_TRAIN(21, pos.x, pos.y, pos.z, false)
    local metroBack = VEHICLE.CREATE_MISSION_TRAIN(21, pos.x, pos.y, pos.z, true)
    VEHICLE.SET_TRAIN_CRUISE_SPEED(metroFront, 15)
    util.yield(155)
    VEHICLE.SET_TRAIN_CRUISE_SPEED(metroBack, -15)
    VEHICLE.SET_TRAIN_SPEED(metroBack, -15)
    last_metro_f = metroFront
    last_metro_b = metroBack
    last_train = last_metro_f
end)

menu.slider(menu.my_root(), "Set Spawned Train Speed", {"setspawnedspeed"}, "Sets last spawned train's speed. Values over +/- 80 will result in players sliding backwards. Reversing trains will look desynced to other players.", -250, 250, 10, 5, function(value)
    VEHICLE.SET_TRAIN_CRUISE_SPEED(last_train, value)
    VEHICLE.SET_TRAIN_SPEED(last_train, value)
    if last_train == last_metro_f then
        VEHICLE.SET_TRAIN_CRUISE_SPEED(last_metro_b, -value)
        VEHICLE.SET_TRAIN_SPEED(last_metro_b, -value)
    end
end)

menu.action(menu.my_root(), "Delete Last Spawned Train", {"delltrain"}, "Deletes the last spawned train", function(v)
    if last_train > 0 then
        if last_train == last_metro_f then
            if last_metro_f > 0 then
                entities.delete(last_metro_f)
                last_metro_f = 0
            end
            if last_metro_b > 0 then
                entities.delete(last_metro_b)
                last_metro_b = 0
            end
            return
        end
        if not ENTITY.DOES_ENTITY_EXIST(last_train) then
            menu.delete(last_train_menu)
            last_train = 0
            last_train_menu = 0
            return
        end
        local carts = {}
        for i = 0, 100 do
            local cart = VEHICLE.GET_TRAIN_CARRIAGE(last_train, i)
            if cart == 0 then
                break
            end
            table.insert(carts, cart)
        end
        entities.delete(last_train)
        for _, cart in ipairs(carts) do
            entities.delete(cart)
        end
        menu.delete(last_train_menu)
        last_train = 0
        last_train_menu = 0
    end
end)

menu.divider(menu.my_root(), "Global")

menu.toggle(menu.my_root(), "Global Speed Enabled", {"enableglobalspeed", "trainspeed"}, "Should script control all trains? (Speed set below)", function(on)
    -- Should _probably_ check if the model is a ya know train but ehh
    globalTrainSpeedControlEnabled = on
end, globalTrainSpeedControlEnabled)

menu.slider(menu.my_root(), "Global Train Speed", {"settrainspeed", "trainspeed"}, "Sets all nearby train's speed. Values over +/- 80 will result in players sliding backwards. Reversing trains will look desynced to other players.", -250, 250, globalTrainSpeed, 5, function(value)
    globalTrainSpeed = value
end)

menu.action(menu.my_root(), "Delete All Trains", {"delalltrains"}, "Deletes all trains in the game", function(v)
    local vehicles = util.get_all_vehicles_as_handles()
    local count = 0
    for _, vehicle in pairs(vehicles) do
        local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
        for _, model in ipairs(models) do
            -- Check if the vehicle is a train
            if model == vehicleModel then
                count = count + 1
                entities.delete(vehicle)
                break
            end
        end
    end
    util.toast("Deleted " .. count .. " trains")
end)

menu.toggle(menu.my_root(), "Derail Trains", {"setderailed"}, "Makes all trains render as derailed", function(on)
    local vehicles = util.get_all_vehicles_as_handles()
    for _, vehicle in pairs(vehicles) do 
        local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
        for _, model in ipairs(models) do
            -- Check if the vehicle is a train
            if model == vehicleModel then
                VEHICLE.SET_RENDER_TRAIN_AS_DERAILED(vehicle, on)
            end
        end
    end
end, false)

util.on_stop(function(_)
    for _, model in ipairs(models) do
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    end
end)


local crazyTrains = false
menu.toggle(menu.my_root(), "Broken Trains", {}, "", function(on)
    crazyTrains = on
end, crazyTrains)


local textc = {
    r = 255,
    g = 255,
    b = 255,
    a = 0
}
local speed = 0.0
local tick = 0
local increment = 5.0
while true do
    if crazyTrains then
        directx.draw_text(0.2, 0.5, string.format("speed %3.0f %s", speed, (increment > 0.0 and " forward" or " backwards")), 1, 0.5, textc, false)
        tick = tick + 1
        if tick > 20 then
            speed = speed + increment
            if speed == 0.0 then
                speed = increment
            elseif speed >= 80.0 or speed <= -80.0 then
                increment = -increment
            end
            local vehicles = util.get_all_vehicles_as_handles()
            for k, vehicle in pairs(vehicles) do
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vehicle, speed)
                VEHICLE.SET_TRAIN_SPEED(vehicle, speed)
            end
            tick = 0
        end
    elseif globalTrainSpeedControlEnabled then
        for _, vehicle in pairs(util.get_all_vehicles_as_handles()) do
            local model = ENTITY.GET_ENTITY_MODEL(vehicle)
            if model == models[1] or model == models[2] then --Only need to set speed for engine
                local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
                NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netid)
                
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vehicle, globalTrainSpeed)
                VEHICLE.SET_TRAIN_SPEED(vehicle, globalTrainSpeed)
            end
        end
    end
    util.yield()
end