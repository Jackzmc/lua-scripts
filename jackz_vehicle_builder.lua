-- Jackz Vehicle Builder
-- [ Boiler Plate ]--
local SCRIPT = "jackz_vehicle_builder"
local VERSION = "0.1.0"
local LANG_TARGET_VERSION = "1.2.2" -- Target version of translations.lua lib
local VEHICLELIB_TARGET_VERSION = "1.0.0"
local CHANGELOG_PATH = filesystem.stand_dir() .. "/Cache/changelog_" .. SCRIPT .. ".txt"
-- Check for updates & auto-update:
-- Remove these lines if you want to disable update-checks & auto-updates: (7-54)
async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        -- Remove this block (lines 15-32) to disable auto updates
        async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT .. "&since=" .. VERSION, function(result)
            local file = io.open(CHANGELOG_PATH, "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            io.close(file)
        end)
        async_http.dispatch()
        async_http.init("jackz.me", "/stand/lua/" .. SCRIPT .. ".lua", function(result)
            local file = io.open(filesystem.scripts_dir() .. "/" .. SCRIPT_FILENAME .. ".lua", "w")
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
function try_load_lib(lib, globalName)
    local status, f = pcall(require, string.sub(lib, 0, #lib - 4))
    if not status then
        local downloading = true
        async_http.init("jackz.me", "/stand/libs/" .. lib, function(result)
            local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n")
            io.flush() -- redudant, probably?
            io.close(file)
            util.toast(SCRIPT .. ": Automatically downloaded missing lib '" .. lib .. "'")
            if globalName then
                _G[globalName] = require(string.sub(lib, 0, #lib - 4))
            end
            downloading = false
        end, function(e)
            util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
            util.stop_script()
        end)
        async_http.dispatch()
        while downloading do
            util.yield()
        end
    elseif globalName then
        _G[globalName] = f
    end
end
try_load_lib("natives-1639742232.lua")
try_load_lib("json.lua", "json")
_G['vehiclelib'] = nil
try_load_lib("jackzvehiclelib.lua", "vehiclelib")
if vehiclelib.LIB_VERSION ~= VEHICLELIB_TARGET_VERSION then
    util.toast("Outdated vehiclelib library, downloading update...")
    os.remove(filesystem.scripts_dir() .. "/lib/vehiclelib.lua")
    package.loaded["translations"] = nil
    _G["translations"] = nil
    try_load_lib("jackzvehiclelib.lua", "vehiclelib")
end

if filesystem.exists(CHANGELOG_PATH) then
    local file = io.open(CHANGELOG_PATH, "r")
    io.input(file)
    local text = io.read("*all")
    util.toast("Changelog for " .. SCRIPT .. ": \n" .. text)
    io.close(file)
    os.remove(CHANGELOG_PATH)
    -- Update translations
    lang.update_translation_file(SCRIPT)
end

-- [ Begin actual script ]--
local BUILDER_VERSION = "Jackz Custom Vehicle 1.0.0" -- For version diff warnings
local builder = { -- All data needed for builder
    base = {
        handle = nil,
        invisible = false
        -- other metadta
    },
    entities = {},
    entitiesMenuList = nil,
    propSpawner = {
        root = nil,
        menus = {}
    }
}
local preview = { -- Handles preview tracking and clearing
    entity = 0,
    id = nil
}
local highlightedHandle = nil -- Will highlight the handle with this ID
local mainMenu -- TODO: Rename to better name

local POS_CHANGE_AMOUNT = 1 -- TODO: Change to menu slider
local ROT_CHANGE_AMOUNT = 5 -- TODO: Change to menu slider

local PROPS_PATH = filesystem.resources_dir() .. "/objects.txt"
local SAVE_DIRECTORY = filesystem.stand_dir() .. "/Vehicles/Custom"
if not filesystem.exists(PROPS_PATH) then
    util.toast("objects.txt does not exist. Please properly install this script.", TOAST_ALL)
    util.stop_script()
end

--[[ TODO: 
    * Menu sliders for (dec)inc for pos/rot [REQUIRES SETTINGS, PIA]
    * Edit feature
    * Vehicle Attachments
        * Attach current (~= base) to base
    * Search props
]]--

--[ SAVED VEHICLES LIST ]
local savedVehicleList
local optionsMenuHandles = {}
local optionParentMenus = {}
function _load_saved_list()
    for path, m in pairs(optionParentMenus) do
        menu.delete(m)
    end
    optionParentMenus = {}
    for _, path in ipairs(filesystem.list_files(SAVE_DIRECTORY)) do
        local _, name, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if ext == "json" then
            optionParentMenus[name] = menu.list(savedVehicleList, name, {}, "Load this custom vehicle",
                function() _create_options_menu(optionParentMenus[name], name) end,
                function() _destroy_options_menu() end
            )
        end
    end
end
function _destroy_saved_list()

end
    --[ SUB: Create custom vehicle context menu ]--
    function _create_options_menu(parentList, filename)
        local status, data = pcall(load_vehicle_from_file, filename)
        if status then
            if data.version ~= BUILDER_VERSION then
                util.toast("Warn: Vehicle data is version: " .. data.version .. "\ncurrent verison: " .. BUILDER_VERSION .. "\nVehicle may spawn incorrectly or fail")
            end
            local m = menu.action(parentList, "Spawn", {}, "", function()
                util.toast("Spawning:")
                spawn_vehicle(data)
            end)
            table.insert(optionsMenuHandles, m)

            m = menu.action(parentList, "Edit", {}, "", function()
                import_vehicle_to_builder(data)
            end)
            table.insert(optionsMenuHandles, m)
        else
            util.toast("Could not load vehicle:\n" .. data, TOAST_ALL)
        end
    end
    function _destroy_options_menu()
        for _, m in ipairs(optionsMenuHandles) do
            pcall(menu.delete, m)
        end
        optionsMenuHandles = {}
    end
savedVehicleList = menu.list(menu.my_root(), "Saved Custom Vehicles", {}, "", _load_saved_list, _destroy_saved_list)

--[ Setup menus, depending on base exists ]--
function setup_pre_menu()
    if mainMenu then
        menu.delete(mainMenu)
    end
    mainMenu = menu.action(menu.my_root(), "Set current vehicle as base", {}, "", function()
        local vehicle = util.get_vehicle()
        if vehicle > 0 then
            builder.base.handle = vehicle
            setup_builder_menus()
        else
            util.toast("You are not in a vehicle.")
        end
    end)
end

function setup_builder_menus()
    menu.delete(mainMenu)
    mainMenu = menu.list(menu.my_root(), "Custom Vehicle Builder", {}, "", function() end, _destroy_prop_previewer)
    menu.text_input(mainMenu, "Save", {"savevehiclename" .. builder.base.handle}, "Save the custom vehicle to disk", function(name)
        save_vehicle(name)
        util.toast("Saved vehicle as " .. name .. ".json to %appdata%\\Stand\\Vehicles\\Custom")
    end)
    builder.entitiesMenuList = menu.list(mainMenu, "Entities", {}, "")
    builder.propSpawner.root = menu.list(mainMenu, "Spawn Props", {"spawnprops"}, "Browse props to spawn to attach to a vehicle",
        _load_prop_previewer
    )
    menu.action(mainMenu, "Delete All Entities", {}, "Removes all entities attached to vehicle, including pre-existing entities.", function()
        for handle, data in pairs(builder.entities) do
            menu.delete(data.list)
            entities.delete(handle)
        end
        builder.entities = {}
        for _, entity in ipairs(entities.get_all_objects_as_handles()) do
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(builder.base.handle, entity) then
                entities.delete(entity)
            end
        end
        for _, entity in ipairs(entities.get_all_vehicles_as_handles()) do
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(builder.base.handle, entity) then
                entities.delete(entity)
            end
        end
    end)
end

-- [ "Spawn Props" Menu Logic ]
function _load_prop_previewer()
    if not builder.base.handle then
        return
    end
    show_busyspinner("Loading props...")
    local searchList = menu.list(builder.propSpawner.root, "Search Props")
    local curatedList = menu.list(builder.propSpawner.root, "Curated", {}, "Contains a list of props that work well with custom vehicles")
    menu.divider(builder.propSpawner.root, "Props")
    for prop in io.lines(PROPS_PATH) do
        local menuHandle = menu.action(builder.propSpawner.root, prop, {}, "", function()
            if preview.entity > 0 and ENTITY.DOES_ENTITY_EXIST(preview.entity) then
                entities.delete(preview.entity)
                preview.entity = 0
                preview.id = nil
            end
            local hash = util.joaat(prop)
            local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
            local entity = entities.create_object(hash, pos)
            add_entity_to_list(builder.entitiesMenuList, entity, prop)
            highlightedHandle = entity
        end)
        menu.on_focus(menuHandle, function()
            if preview.id == nil or preview.id ~= prop then -- Focus seems to be called for every menu item added
                if preview.entity > 0 and ENTITY.DOES_ENTITY_EXIST(preview.entity) then
                    entities.delete(preview.entity)
                end
                local hash = util.joaat(prop)
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
                preview.entity = entities.create_object(hash, pos)
                preview.id = prop
                ENTITY.SET_ENTITY_ALPHA(preview.entity, 150)
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(preview.entity, false, false)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
            end
        end)
        table.insert(builder.propSpawner.menus, menuHandle)
    end
    HUD.BUSYSPINNER_OFF()
end

function _destroy_prop_previewer()
    show_busyspinner("Unloading prop previewer...")
    for _, m in ipairs(builder.propSpawner.menus) do
        menu.delete(m)
    end
    if preview.entity > 0 and ENTITY.DOES_ENTITY_EXIST(preview.entity) then
        entities.delete(preview.entity)
        preview.entity = 0
        preview.id = nil
    end
    builder.propSpawner.menus = {}
    HUD.BUSYSPINNER_OFF()
end

-- [ ENTITY EDITING HANDLING ]
function add_entity_to_list(list, handle, name)
    ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, builder.base.handle)

    
    builder.entities[handle] = {
        name = name or "(no name)",
        model = ENTITY.GET_ENTITY_MODEL(handle),
        list = nil,
        pos = { x = 0.0, y = 0.0, z = 0.0 },
        rot = { x = 0.0, y = 0.0, z = 0.0 },
    }
    attach_entity(builder.base.handle, handle, builder.entities[handle].pos, builder.entities[handle].rot)
    builder.entities[handle].list = create_entity_section(list, handle)
end

function create_entity_section(parent, handle)
    if not ENTITY.DOES_ENTITY_EXIST(handle) then
        util.log("create_entity_section: Entity (" .. handle .. ") vanished, deleting")
        menu.delete(builder.entities[handle])
        builder.entities[handle] = nil
        return
    end
    local pos = builder.entities[handle].pos
    local rot = builder.entities[handle].rot

    local entityroot = menu.list(parent, builder.entities[handle].name, {}, "Edit entity #" .. handle,
        function() highlightedHandle = handle end,
        function() highlightedHandle = nil end
    )

    --[ POSITION ]--
    menu.divider(entityroot, "Position")
    menu.slider(entityroot, "X", {"pos" .. handle .. "x"}, "Set the X offset from the base entity", -1000000, 1000000, math.floor(pos.x), POS_CHANGE_AMOUNT, function (x)
        pos.x = x / 100
        attach_entity(builder.base.handle, handle, pos, rot)
        -- ENTITY.SET_ENTITY_COORDS(handle, pos.x, pos.y, pos.z)
    end)
    menu.slider(entityroot, "Y", {"pos" .. handle .. "y"}, "Set the Y offset from the base entity", -1000000, 1000000, math.floor(pos.y), POS_CHANGE_AMOUNT, function (y)
        pos.y = y / 100
        attach_entity(builder.base.handle, handle, pos, rot)
    end)
    menu.slider(entityroot, "Z", {"pos" .. handle .. "z"}, "Set the Z offset from the base entity", -1000000, 1000000, math.floor(pos.z), POS_CHANGE_AMOUNT, function (z)
        pos.z = z / 100
        attach_entity(builder.base.handle, handle, pos, rot)
    end)

    --[ ROTATION ]--
    menu.divider(entityroot, "Rotation")
    menu.slider(entityroot, "X", {"rot" .. handle .. "x"}, "Set the X-axis rotation", -175, 180, math.floor(rot.x), ROT_CHANGE_AMOUNT, function (x)
        rot.x = x
        attach_entity(builder.base.handle, handle, pos, rot)
    end)
    menu.slider(entityroot, "Y", {"rot" .. handle .. "y"}, "Set the Y-axis rotation", -175, 180, math.floor(rot.y), ROT_CHANGE_AMOUNT, function (y)
        rot.y = y
        attach_entity(builder.base.handle, handle, pos, rot)
    end)
    menu.slider(entityroot, "Z", {"rot" .. handle .. "z"}, "Set the Z-axis rotation", -175, 180, math.floor(rot.z), ROT_CHANGE_AMOUNT, function (z)
        rot.z = z
        attach_entity(builder.base.handle, handle, pos, rot)
    end)

    --[ MISC ]--
    menu.divider(entityroot, "Misc")
    menu.text_input(entityroot, "Rename", {"renameent" .. handle}, "Changes the name of this entity", function(name)
        menu.set_menu_name(builder.entities[handle].list, name)
        builder.entities[handle].name = name
    end, builder.entities[handle].name)
    menu.action(entityroot, "Delete", {}, "Delete the entity", function()
        entities.delete(handle)
        menu.delete(entityroot)
        builder.entities[handle] = nil
    end)

    return entityroot
end

--[ Save Data ]
function save_vehicle(name)
    -- TODO: Check for valid filename
    filesystem.mkdirs(SAVE_DIRECTORY)
    local file = io.open(SAVE_DIRECTORY .. "/" .. name .. ".json", "w")
    if file then
        file:write(builder_to_json())
        file:close()
    else
        error("Could not create file ' " .. name .. ".json'")
    end
end
function load_vehicle_from_file(filename)
    local file = io.open(SAVE_DIRECTORY .. "/" .. filename, "r")
    if file then
        local data = json.decode(file:read("*a"))
        file:close()
        return data
    else 
        error("Could not read file '" .. SAVE_DIRECTORY .. "/" .. filename .. "'")
    end
end
function builder_to_json()
    local objects = {}
    for handle, data in pairs(builder.entities) do
        if ENTITY.IS_ENTITY_A_VEHICLE(handle) then
            -- table.insert(objects, {
            --     name = data.name,
            --     model = data.model,
            --     offset = data.pos,
            --     rotation = data.rot
            -- })
        else
            table.insert(objects, {
                name = data.name,
                model = data.model,
                offset = data.pos,
                rotation = data.rot
            })
        end
    end
    return json.encode({
        version = BUILDER_VERSION,
        base = {
            model = ENTITY.GET_ENTITY_MODEL(builder.base.handle),
            -- TODO: Merge other base options
            invisible = builder.base.invisible,
            savedata = vehiclelib.Serialize(builder.base.handle)
        },
        objects = objects
    })
end

--[ Savedata Options ]--
function import_vehicle_to_builder(data)
    util.toast("Feature not implemented")
    -- TODO: Stub
end

function spawn_vehicle(data)
    STREAMING.REQUEST_MODEL(data.base.model)
    while not STREAMING.HAS_MODEL_LOADED(data.base.model) do
        util.yield()
    end
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 7.5, 1.0)
    local heading = ENTITY.GET_ENTITY_HEADING(my_ped)
    local baseHandle = entities.create_vehicle(data.base.model, pos, heading)
    TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
    for _, entityData in ipairs(data.objects) do
        local handle = entities.create_object(entityData.model, pos)
        attach_entity(baseHandle, handle, entityData.offset, entityData.rotation)
    end
    vehiclelib.ApplyToVehicle(baseHandle, data.base.savedata)
end

-- [ UTILS ]--
function attach_entity(parent, handle, pos, rot)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(handle, parent, 0,
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        false, true, false, false, 2, true
    )
end
function show_busyspinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end
-- Modified from https://forum.cfx.re/t/how-to-supas-helper-scripts/41100
function highlight_object(handle)
    local pos = ENTITY.GET_ENTITY_COORDS(handle)
    GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
    GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("helicopterhud", false)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -0.01, -0.01, 0.006, 0.006, 0.0, 255, 0, 0, 200)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", 0.01, -0.01, 0.006, 0.006, 90.0, 255, 0, 0, 200)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -0.01, 0.01, 0.006, 0.006, 270.0, 255, 0, 0, 200)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", 0.01, 0.01, 0.006, 0.006, 180.0, 255, 0, 0, 200)
    GRAPHICS.CLEAR_DRAW_ORIGIN()
end
function show_marker(handle, markerType, ang)
    local pos = ENTITY.GET_ENTITY_COORDS(handle)
    if ang == nil then ang = {} end
    GRAPHICS.DRAW_MARKER(markerType or 0, pos.x, pos.y, pos.z + 4.0, 0.0, 0.0, 0.0, ang.x or 0, ang.y or 0, ang.z or 0, 1, 1, 1, 255, 255, 255, 100, false, true, 2, false, 0, 0, false)
end
setup_pre_menu()

while true do
    if highlightedHandle ~= nil then
        highlight_object(highlightedHandle)
        show_marker(highlightedHandle, 0)
    end
    util.yield()
end