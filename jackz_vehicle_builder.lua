-- Jackz Vehicle Builder
-- [ Boiler Plate ]--
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "jackz_vehicle_builder"
local VERSION = "1.13.1"
local LANG_TARGET_VERSION = "1.3.3" -- Target version of translations.lua lib
local VEHICLELIB_TARGET_VERSION = "1.1.4"
---@alias Handle number
---@alias MenuHandle number

--#P:MANUAL_ONLY
-- Check for updates & auto-update:
-- Remove these lines if you want to disable update-checks & auto-updates: (7-54)
async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    local chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        -- Remove this block (lines 15-32) to disable auto updates
        async_http.init("jackz.me", "/stand/get-lua.php?script=" .. SCRIPT .. "&source=manual", function(result)
            local file = io.open(filesystem.scripts_dir()  .. SCRIPT_RELPATH, "w")
            file:write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            file:close()
            util.toast(SCRIPT .. " was automatically updated to V" .. chunks[2] .. "\nRestart script to load new update.", TOAST_ALL)
        end, function()
            util.toast(SCRIPT .. ": Failed to automatically update to V" .. chunks[2] .. ".\nPlease download latest update manually.\nhttps://jackz.me/stand/get-latest-zip", 2)
            util.stop_script()
        end)
        async_http.dispatch()
    end
end)
async_http.dispatch()

function download_lib_update(lib)
    async_http.init("jackz.me", "/stand/libs/" .. lib, function(result)
        local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        util.toast(SCRIPT .. ": Automatically updated lib '" .. lib .. "'")
    end, function(e)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
        util.stop_script()
    end)
    async_http.dispatch()
end
--#P:END
function download_resources_update(filepath, destOverwritePath)
    util.toast("/stand/resources/" .. filepath)
    async_http.init("jackz.me", "/stand/resources/" .. filepath, function(result)
        if result:startswith("<") then
            util.toast("Resource returned invalid response for \"" .. filepath .. "\"\nSee logs for details")
            util.log(string.format("%s: Resource \"%s\" returned: %s", SCRIPT_NAME, filepath, result))
            return
        end
        local file = io.open(filesystem.resources_dir() .. destOverwritePath or filepath, "w")
        if file == nil then
            util.toast("Could not write resource file for: " .. filepath .. "\nSee logs for details")
            util.log(string.format("%s: Resource \"%s\" file could not be created.", SCRIPT_NAME, filepath))
            return
        end
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        util.toast(SCRIPT .. ": Automatically updated resource '" .. filepath .. "'")
    end, function(e)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. filepath .. ")", 10)
        util.stop_script()
    end)
    async_http.dispatch()
end

----------------------------------------------------------------
-- Version Check
function get_version_info(version)
    local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch)
    }
end
function compare_version(a, b)
    local av = get_version_info(a)
    local bv = get_version_info(b)
    if av.major > bv.major then return 1
    elseif av.major < bv.major then return -1
    elseif av.minor > bv.minor then return 1
    elseif av.minor < bv.minor then return -1
    elseif av.patch > bv.patch then return 1
    elseif av.patch < bv.patch then return -1
    else return 0 end
end
local VERSION_FILE_PATH = filesystem.store_dir() .. "jackz_versions.txt"
if not filesystem.exists(VERSION_FILE_PATH) then
    local versionFile = io.open(VERSION_FILE_PATH, "w")
    versionFile:close()
end
local versionFile = io.open(VERSION_FILE_PATH, "r+")
local versions = {}
for line in versionFile:lines("l") do
    local script, version = line:match("(%g+): (%g+)")
    if script then
        versions[script] = version
    end
end
if versions[SCRIPT] == nil or compare_version(VERSION, versions[SCRIPT]) == 1 then
    if versions[SCRIPT] ~= nil then
        async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT .. "&since=" .. versions[SCRIPT], function(result)
            util.toast("Changelog for " .. SCRIPT .. " version " .. VERSION .. ":\n" .. result)
        end, function() util.log(SCRIPT ..": Could not get changelog") end)
        async_http.dispatch()
    end
    versions[SCRIPT] = VERSION
    versionFile:seek("set", 0)
    versionFile:write("# DO NOT EDIT ! File is used for changelogs\n")
    for script, version in pairs(versions) do
        versionFile:write(script .. ": " .. version .. "\n")
    end
end
versionFile:close()
-- END Version Check
------------------------------------------------------------------
util.require_natives(1627063482)
local json = require("json")
local vehiclelib = require("jackzvehiclelib")

if vehiclelib.LIB_VERSION ~= VEHICLELIB_TARGET_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
        util.toast("Outdated vehiclelib library, downloading update...")
        download_lib_update("jackzvehiclelib.lua")
        vehiclelib = require("jackzvehiclelib")
    else
        util.toast("Outdated lib: 'jackzvehiclelib'")
    end
end


local metaList = menu.list(menu.my_root(), "Script Meta")
menu.divider(metaList, SCRIPT .. " V" .. VERSION)
menu.hyperlink(metaList, "View guilded post", "https://www.guilded.gg/stand/groups/x3ZgB10D/channels/7430c963-e9ee-40e3-ab20-190b8e4a4752/docs/294853")
menu.hyperlink(metaList, "View full changelog", "https://jackz.me/stand/changelog?html=1&script=" .. SCRIPT)
menu.hyperlink(metaList, "Jackz's Guilded", "https://www.guilded.gg/i/k8bMDR7E?cid=918b2f61-989c-41c4-ba35-8fd0e289c35d&intent=chat", "Get help or suggest additions to my scripts")
if _lang ~= nil then
    menu.hyperlink(metaList, "Help Translate", "https://jackz.me/stand/translate/?script=" .. SCRIPT, "If you wish to help translate, this script has default translations fed via google translate, but you can edit them here:\nOnce you make changes, top right includes a save button to get a -CHANGES.json file, send that my way.")
    _lang.add_language_selector_to_menu(metaList)
end

-- [ Begin actual script ]--
local AUTOSAVE_INTERVAL_SEC = 60 * 5 -- 10 minutes 
local MAX_AUTOSAVES = 4
local autosaveNextTime = 0
local autosaveIndex = 1
local BUILDER_VERSION = "1.2.0" -- For version diff warnings
local FORMAT_VERSION = "Jackz Custom Vehicle " .. BUILDER_VERSION
local builder = nil

---@param baseHandle Handle
-- Returns a new builder instance
function new_builder(baseHandle)
    autosaveNextTime = os.seconds() + AUTOSAVE_INTERVAL_SEC
    return { -- All data needed for builder
        name = nil,
        author = nil,
        base = {
            handle = baseHandle,
            visible = true,
            -- other metadta
        },
        ---@type table<Handle, table<string, any>>
        entities = {},
        entitiesMenuList = nil,
        propSpawner = {
            root = nil,
            ---@type MenuHandle[]
            menus = {},
            loadState = 0, --0: not, 1: loading, 2: done
            recents = {
                list = nil,
                ---@type table<Handle, number>
                items = {}
            }
        },
        vehSpawner = {
            root = nil,
            ---@type MenuHandle[]
            menus = {},
            loadState = 0, --0: not, 1: loading, 2: done
            recents = {
                list = nil,
                ---@type table<Handle, number>
                items = {}
            }
        },
        pedSpawner = {
            root = nil,
            menus = {},
            loadState = 0,
            recents = {
                list = nil,
                items = {}
            }
        },
        prop_list_active = false
    }
end
local preview = { -- Handles preview tracking and clearing
    entity = 0,
    id = nil,
    thread = nil
}
local highlightedHandle = nil -- Will highlight the handle with this ID
local mainMenu -- TODO: Rename to better name

local POS_SENSITIVITY = 10
local ROT_SENSITIVITY = 5
local FREE_EDIT = false
local isInEntityMenu = false

local CURATED_PROPS = {
    "prop_logpile_06b",
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
    "prop_prlg_snowpile"
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
    { "cerberus2", "Future Shock Cerberus" }
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
    { "ig_agatha", "Agtha" }
}

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
local SAVE_DIRECTORY = join_path(filesystem.stand_dir(), "Vehicles/Custom")
if not filesystem.exists(PROPS_PATH) then
    util.toast("jackz_vehicle_builder: objects.txt in resources folder does not exist. Please properly install this script.", TOAST_ALL)
    util.log("Resources directory: ".. PROPS_PATH)
    util.stop_script()
end
if not filesystem.exists(PEDS_PATH) then
    util.log(SCRIPT_NAME .. ": Downloading resource update for peds.txt")
    download_resources_update("peds.txt")
end

function create_preview_handler_if_not_exists()
    if preview.thread == nil then
        preview.thread = util.create_thread(function()
            local heading = 0
            while preview.entity ~= 0 do
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                heading = heading + 2
                if heading == 360 then
                    heading = 0
                end
                util.draw_debug_text("dist: " .. preview.isCustomVehicle and 40 or 5)
                pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, 5, 0.3)
                ENTITY.SET_ENTITY_COORDS(preview.entity, pos.x, pos.y, pos.z, true, true, false, false)
                ENTITY.SET_ENTITY_HEADING(preview.entity, heading)
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(preview.entity, true, false)
                CAM._DISABLE_CAM_COLLISION_FOR_ENTITY(preview.entity)

                util.yield(15)
            end
        end)
    end
end
function clear_menu_table(t)
    for k, h in pairs(t) do
        pcall(menu.delete, h)
        t[k] = nil
    end
end
--[ SAVED VEHICLES LIST ]
local savedVehicleList = menu.list(menu.my_root(), "Saved Custom Vehicles", {}, "",
    function() _load_saved_list() end,
    function() _destroy_saved_list() end
)
local xmlMenusHandles = {}
local spawnInVehicle = true
menu.toggle(savedVehicleList, "Spawn In Vehicle", {}, "Force yourself to spawn in the base vehicle", function(on)
    spawnInVehicle = on
end, spawnInVehicle)
local xmlList = menu.list(savedVehicleList, "Convert XML Vehicles", {}, "Convert XML vehicle (including menyoo) to a compatible format")
menu.divider(savedVehicleList, "Vehicles")
local optionsMenuHandles = {}
local optionParentMenus = {}
function _load_saved_list()
    remove_preview_custom()
    clear_menu_table(optionParentMenus)
    clear_menu_table(xmlMenusHandles)
    for _, path in ipairs(filesystem.list_files(SAVE_DIRECTORY)) do
        local _, name, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if ext == "json" then
            local status, data = pcall(load_vehicle_from_file, name)
            if status and data ~= nil then
                local versionText = "(UNKNOWN VERSION, UNSUPPORTED OR INVALID VEHICLE)"
                if data.version then
                    local m = {}
                    for match in data.version:gmatch("([^%s]+)") do
                        table.insert(m, match)
                    end
                    local fileVersion = m[#m]
                    local versionDiff = compare_version(BUILDER_VERSION, fileVersion)
                    if versionDiff == 1 then
                        versionText = string.format("%s (Older version, latest %s)", fileVersion, BUILDER_VERSION)
                    elseif versionDiff == -1 then
                        versionText = string.format("%s (Unsupported Version, latest %s)", fileVersion, BUILDER_VERSION)
                    else
                        versionText = string.format("%s (Latest)", fileVersion, BUILDER_VERSION)
                    end
                else
                    log("Vehicle has no version" .. name)
                end
                if not data.base or not data.objects then
                    log("Skipping invalid vehicle: " .. name)
                    return
                end

                local createdText = data.created and (os.date("%Y-%m-%d at %X", data.created) .. " UTC") or "-unknown-"
                local authorText = data.author and (string.format("Vehicle Author: %s\n", data.author)) or ""
                optionParentMenus[name] = menu.list(savedVehicleList, name, {}, string.format("Format Version: %s\nCreated: %s\n%s", versionText, createdText, authorText),
                    function()
                        clear_menu_table(optionsMenuHandles)
                        local m = menu.action(optionParentMenus[name], "Spawn", {}, "", function()
                            lastAutosave = os.seconds()
                            autosaveNextTime = seconds + AUTOSAVE_INTERVAL_SEC
                            remove_preview_custom()
                            spawn_custom_vehicle(data, false)
                        end)
                        table.insert(optionsMenuHandles, m)
            
                        m = menu.action(optionParentMenus[name], "Edit", {}, "", function()
                            lastAutosave = os.seconds()
                            autosaveNextTime = seconds + AUTOSAVE_INTERVAL_SEC
                            import_vehicle_to_builder(data, name:sub(1, -6))
                            menu.focus(builder.entitiesMenuList)
                        end)
                        table.insert(optionsMenuHandles, m)
                    end,
                    function() _destroy_options_menu() end
                )
                
                -- Spawn custom vehicle handler
                menu.on_focus(optionParentMenus[name], function()
                    if preview.id ~= name then
                        remove_preview_custom()
                        preview.id = name
                        spawn_custom_vehicle(data, true)
                        create_preview_handler_if_not_exists()
                    end
                end)
            else
                util.log("Ignoring invalid vehicle '" .. name .. "': " .. (data or "<EMPTY FILE>"), TOAST_ALL)
            end
        elseif ext == "xml" then
            local filename = name:sub(1, -5)
            local newPath = SAVE_DIRECTORY .. "/" .. filename .. ".json"
            xmlMenusHandles[name] = menu.action(xmlList, name, {}, "Click to convert to a compatible format.", function()
                if filesystem.exists(newPath) then
                    menu.show_warning(xmlMenusHandles[name], CLICK_COMMAND, "This file already exists, do you want to overwrite " .. filename .. ".json?", function() 
                        convert_file(path, filename, newPath)
                    end)
                    return
                end
                convert_file(path, filename, newPath)
            end)
        end
    end
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
function _destroy_saved_list()
end
    --[ SUB: Destroy custom vehicle context menu ]--
    function _destroy_options_menu()
        clear_menu_table(optionsMenuHandles)
    end
menu.on_focus(savedVehicleList, function() remove_preview_custom() end)

--[ Setup menus, depending on base exists ]--
function setup_pre_menu()
    if mainMenu then
        menu.delete(mainMenu)
        mainMenu = nil
    end
    -- mainMenu = menu.list(menu.my_root(), "Create New Vehicle")
    mainMenu = menu.action(menu.my_root(), "Set current vehicle as base", {}, "", function()
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        if vehicle > 0 then
            builder = new_builder(vehicle)
            load_recents()
            setup_builder_menus()
        else
            util.toast("You are not in a vehicle.")
        end
    end)
end

function setup_builder_menus(name)
    menu.delete(mainMenu)
    if not builder.base.handle or builder.prop_list_active then
        return
    end
    mainMenu = menu.list(menu.my_root(), "Custom Vehicle Builder", {}, "", function() end, _destroy_prop_previewer)
    menu.text_input(mainMenu, "Save", {"savecustomvehicle"}, "Enter the name to save the vehicle as", function(name)
        builder.name = name
        if save_vehicle(name) then
            util.toast("Saved vehicle as " .. name .. ".json to %appdata%\\Stand\\Vehicles\\Custom")
        end
    end, name or "")
    menu.text_input(mainMenu, "Author", {"customvehicleauthor"}, "Set the author of the vehicle. None is set by default.", function(input)
        builder.author = input
        util.toast("Set the vehicle's author to: " .. input)
    end, builder.author or "")

    builder.entitiesMenuList = menu.list(mainMenu, "Entities", {}, "")
    menu.on_focus(builder.entitiesMenuList, function() highlightedHandle = nil end)
    menu.slider(builder.entitiesMenuList, "Coordinate Sensitivity", {"offsetsensitivity"}, "Sets the sensitivity of changing the offset coordinates of an entity", 1, 20, POS_SENSITIVITY, 1, function(value)
        POS_SENSITIVITY = value
        if not value then
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, false)
            ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
        end
    end)
    menu.toggle(builder.entitiesMenuList, "Free Edit", {"free-edit"}, "Allows you to move entities by holding the following keys:\nWASD -> Normal\nSHIFT/CTRL - Up and down\nNumpad 8/5 - Pitch\nNumpad 4/6 - Roll\nNumpad 7/9 - Rotation\n\nWill only work when hovering over an entity or stand is closed, disabled in entity list.", function(value)
        FREE_EDIT = value
    end, FREE_EDIT)
    menu.divider(builder.entitiesMenuList, "Entities")
    builder.propSpawner.root = menu.list(mainMenu, "Spawn Props", {"builderprops"}, "Browse props to spawn to attach to add to your custom vehicle")
    menu.on_focus(builder.propSpawner.root, function() _destroy_browse_menu("propSpawner") end)
    builder.vehSpawner.root = menu.list(mainMenu, "Spawn Vehicles", {"buildervehicles"}, "Browse vehicles to spawn to add to your custom vehicle")
    menu.on_focus(builder.vehSpawner.root, function() _destroy_browse_menu("vehSpawner") end)
    builder.pedSpawner.root = menu.list(mainMenu, "Spawn Peds", {"builderpeds"}, "Browse peds to spawn to add to your custom vehicle")
    menu.on_focus(builder.pedSpawner.root, function() _destroy_browse_menu("pedSpawner") end)
    create_object_spawner_list(builder.propSpawner.root)
    create_vehicle_spawner_list(builder.vehSpawner.root)
    create_ped_spawner_list(builder.pedSpawner.root)
    builder.prop_list_active = true

    local baseList = menu.list(mainMenu, "Base Vehicle", {}, "")
        local settingsList = menu.list(baseList, "Settings", {}, "")
        menu.action(baseList, "Teleport Into", {}, "Teleport into the base vehicle", function()
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, builder.base.handle, -1)
        end)
        menu.action(baseList, "Delete All Entities", {}, "Removes all entities attached to vehicle, including pre-existing entities.", function()
            for handle, data in pairs(builder.entities) do
                menu.delete(data.list)
                entities.delete_by_handle(handle)
            end
            builder.entities = {}
            for _, entity in ipairs(entities.get_all_objects_as_handles()) do
                if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(builder.base.handle, entity) then
                    entities.delete_by_handle(entity)
                end
            end
            for _, entity in ipairs(entities.get_all_vehicles_as_handles()) do
                if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(builder.base.handle, entity) then
                    entities.delete_by_handle(entity)
                end
            end
            highlightedHandle = nil
        end)
        menu.action(baseList, "Set current vehicle as new base", {}, "Re-assigns the entities to a new base vehicle", function()
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
            if vehicle > 0 then
                if vehicle == builder.base.handle then
                    util.toast("This vehicle is already the base vehicle.")
                else
                    log("Reassigned base " .. builder.base.handle .. " -> " .. vehicle)
                    builder.base.handle = vehicle
                    for handle, data in pairs(builder.entities) do
                        attach_entity(vehicle, handle, data.pos, data.rot)
                    end
                end
            else
                util.toast("You are not in a vehicle.")
            end
        end)

        builder.entities[builder.base.handle] = {
            list = settingsList,
            type = "VEHICLE",
            model = ENTITY.GET_ENTITY_MODEL(builder.base.handle),
            listMenus = {},
            pos = { x = 0.0, y = 0.0, z = 0.0 },
            rot = { x = 0.0, y = 0.0, z = 0.0 },
            visible = true,
            godmode = true
        }
        create_entity_section(builder.entities[builder.base.handle], builder.base.handle, { noRename = true } )
end

function create_object_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "Contains a list of props that work well with custom vehicles", function() end, remove_preview_custom)
    for _, prop in ipairs(CURATED_PROPS) do
        add_prop_menu(curatedList, prop)
    end
    local searchList = menu.list(root, "Search Props", {}, "Search for a prop by name")
    menu.text_input(searchList, "Search", {"searchprops"}, "Enter a prop name to search for", function(query)
        create_prop_search_results(searchList, query, 20)
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
    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all the props in the game.", function()
        _load_prop_browse_menus(browseList)
    end)
end

function create_ped_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "Contains a list of peds that work well with custom vehicles", function() end, remove_preview_custom)
    for _, ped in ipairs(CURATED_PEDS) do
        add_ped_menu(curatedList, ped[1], ped[2])
    end
    local searchList = menu.list(root, "Search Peds", {}, "Search for a ped by name")
    menu.text_input(searchList, "Search", {"builderquerypeds"}, "Enter a ped name to search for", function(query)
        create_ped_search_results(searchList, query, 20)
    end)
    menu.text_input(root, "Manual Input", {"customped"}, "Enter the ped name to spawn", function(query)
        local hash = util.joaat(query)
        if STREAMING.IS_MODEL_VALID(hash) and not STREAMING.IS_MODEL_A_PED(hash) then
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
            local entity = entities.create_ped(0, hash, pos)
            add_entity_to_list(builder.entitiesMenuList, entity, query)
            highlightedHandle = entity
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        else
            util.toast("Ped entered does not exist")
        end
    end)
    builder.pedSpawner.recents.list = menu.list(root, "Recent Peds", {}, "Your most recently spawned peds", _load_ped_recent_menu, _destroy_recent_menus)
    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all the peds in the game.", function()
        _load_ped_browse_menus(browseList)
    end)
end

function create_vehicle_spawner_list(root)
    local curatedList = menu.list(root, "Curated", {}, "Contains a list of props that work well with custom vehicles")
    for _, data in ipairs(CURATED_VEHICLES) do
        add_vehicle_menu(curatedList, data[1], data[2])
    end
    local searchList = menu.list(root, "Search Vehicles")
    menu.text_input(searchList, "Search", {"searchvehicles"}, "Enter a vehicle name to search for", function(query)
        create_vehicle_search_results(searchList, query, 20)
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
    local browseList
    browseList = menu.list(root, "Browse", {}, "Browse all vehicles", function()
        _load_vehicle_browse_menus(browseList)
    end)
    menu.action(root, "Clone Current Vehicle", {}, "Adds your current vehicle as part of your custom vehicle", function()
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


function _destroy_recent_menus()
    clear_menu_table(recentMenus)

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
                prop = ped,
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
    show_busyspinner("Searching vehicles...")
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
        async_http.init("jackz.me", "/stand/resources/vehicles.txt", function(body)
            for line in string.gmatch(body, "[^\r\n]+") do
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
            HUD.BUSYSPINNER_OFF()
        end)
        async_http.dispatch()
    end
end
function _destroy_browse_menu(key)
    _destroy_recent_menus()
    show_busyspinner("Clearing browse menu... May lag")
    util.create_thread(function()
        clear_menu_table(builder[key].menus)
    end)
    builder[key].loadState = 0
    builder[key].menus = {}
    remove_preview_custom()
    save_recents()
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
        file:write(id .. "," .. data.name .. "," .. (data.dlc or "") .. "," .. data.count .. "\n")
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
end

--[ PROP/VEHICLE MENU & PREVIEWS ]--
function add_prop_menu(parent, propName)
    local menuHandle = menu.action(parent, propName, {}, "", function()
        remove_preview_custom()
        -- Increment recent usage
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
            remove_preview_custom()
            local hash = util.joaat(propName)
            preview.id = propName
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            if preview.id ~= propName then return end
            local entity = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, false, false, 0);
            if entity == 0 then
                log("Could not create preview for " .. propName .. "(" .. hash .. ")")
                return
            end
            preview.entity = entity
            ENTITY.SET_ENTITY_ALPHA(entity, 150)
            ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(entity, false, false)
            create_preview_handler_if_not_exists()
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        end
    end)
    return menuHandle
end

function add_ped_menu(parent, pedName, displayName)
    local menuHandle = menu.action(parent, displayName or pedName, {}, pedName, function()
        remove_preview_custom()
        -- Increment recent usage
        if builder.pedSpawner.recents.items[pedName] ~= nil then
            builder.pedSpawner.recents.items[pedName] = builder.pedSpawner.recents.items[pedName] + 1
        else builder.pedSpawner.recents.items[pedName] = 0 end

        local hash = util.joaat(pedName)
        local pos = ENTITY.GET_ENTITY_COORDS(builder.base.handle)
        local entity = entities.create_ped(0, hash, pos, 0)
        add_entity_to_list(builder.entitiesMenuList, entity, pedName)
        highlightedHandle = entity
    end)
    menu.on_focus(menuHandle, function()
        if preview.id == nil or preview.id ~= pedName then -- Focus seems to be re-called everytime an menu item is added
            remove_preview_custom()
            local hash = util.joaat(pedName)
            preview.id = pedName
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            if preview.id ~= pedName then return end
            local entity = PED.CREATE_PED(0, hash, pos.x, pos.y, pos.z, 0, false, false);
            if entity == 0 then
                log("Could not create preview for " .. pedName .. "(" .. hash .. ")")
                return
            end
            preview.entity = entity
            ENTITY.SET_ENTITY_ALPHA(entity, 150)
            ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(entity, false, false)
            create_preview_handler_if_not_exists()
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        end
    end)
    return menuHandle
end

function add_vehicle_menu(parent, vehicleID, displayName, dlc)
    local menuHandle = menu.action(parent, displayName, {}, dlc and ("DLC: " .. dlc) or "", function()
        remove_preview_custom()
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
            remove_preview_custom()
            local hash = util.joaat(vehicleID)
            preview.id = vehicleID
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(builder.base.handle, 0, 7.5, 1.0)
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            if preview.id ~= vehicleID then return end
            local entity = VEHICLE.CREATE_VEHICLE(hash, pos.x, pos.y, pos.z, 0, false, false)
            if entity == 0 then
                return log("Could not create preview for " .. vehicleID .. "(" .. hash .. ")")
            end
            preview.entity = entity
            create_preview_handler_if_not_exists()
            ENTITY.SET_ENTITY_ALPHA(entity, 150)
            ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(entity, false, false)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        end
    end)
    return menuHandle
end
--[ Previewer Stuff ]--

function remove_preview_custom()
    if preview.entity ~= 0 and ENTITY.DOES_ENTITY_EXIST(preview.entity) then
        for _, entity in ipairs(entities.get_all_objects_as_handles()) do
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(preview.entity, entity) then
                entities.delete_by_handle(entity)
            end
        end
        for _, entity in ipairs(entities.get_all_vehicles_as_handles()) do
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(preview.entity, entity) then
                entities.delete_by_handle(entity)
            end
        end
        for _, entity in ipairs(entities.get_all_peds_as_handles()) do
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(preview.entity, entity) then
                entities.delete_by_handle(entity)
            end
        end
        entities.delete_by_handle(preview.entity)
        preview.entity = 0
        preview.id = nil
    end
end

function _destroy_prop_previewer()
    show_busyspinner("Unloading prop previewer...")
    clear_menu_table(builder.propSpawner.menus)
    if preview.entity > 0 and ENTITY.DOES_ENTITY_EXIST(preview.entity) then
        entities.delete_by_handle(preview.entity)
        preview.entity = 0
        preview.id = nil
    end
    HUD.BUSYSPINNER_OFF()
    builder.prop_list_active = false
end

-- [ ENTITY EDITING HANDLING ]
function add_entity_to_list(list, handle, name, pos, rot)
    autosave(true)
    -- ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, builder.base.handle)
    local model = ENTITY.GET_ENTITY_MODEL(handle)
    local type = "OBJECT"
    if STREAMING.IS_MODEL_A_VEHICLE(model) then
        type = "VEHICLE"
    elseif STREAMING.IS_MODEL_A_PED(model) then
        type = "PED"
    end
    builder.entities[handle] = {
        name = name or "(no name)",
        type,
        model = model,
        list = nil,
        listMenus = {},
        pos = pos or { x = 0.0, y = 0.0, z = 0.0 },
        rot = rot or { x = 0.0, y = 0.0, z = 0.0 },
        visible = true,
        godmode = STREAMING.IS_MODEL_A_VEHICLE(model) and true or nil
    }
    attach_entity(builder.base.handle, handle, builder.entities[handle].pos, builder.entities[handle].rot)
    builder.entities[handle].list = menu.list(
        list, builder.entities[handle].name, {}, string.format("Edit entity #%d\nModel name: %s\nHash: %s", handle, name, model),
        function() create_entity_section(builder.entities[handle], handle) end,
        function() 
            isInEntityMenu = false
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            ENTITY.FREEZE_ENTITY_POSITION(builder.base.handle, false)
            ENTITY.FREEZE_ENTITY_POSITION(my_ped, false)
        end
    )
    menu.focus(builder.entities[handle].list)
    create_entity_section(builder.entities[handle], handle)
end

function clone_entity(handle, name)
    local model = ENTITY.GET_ENTITY_MODEL(handle)
    local entity
    local pos = ENTITY.GET_ENTITY_COORDS(handle)
    if ENTITY.IS_ENTITY_A_PED(handle) then
        entity = entities.create_ped(0, model, pos, 0)
    elseif ENTITY.IS_ENTITY_A_VEHICLE(handle) then
        entity = entities.create_vehicle(model, pos, 0)
    else
        entity = entities.create_object(model, pos)
    end
    add_entity_to_list(builder.entitiesMenuList, entity, name)
    highlightedHandle = entity
end

function create_entity_section(tableref, handle, options)
    if options == nil then options = {} end
    local entityroot = tableref.list
    if not ENTITY.DOES_ENTITY_EXIST(handle) then
        log("Entity (" .. handle .. ") vanished, deleting", "create_entity_section")
        if entityroot then
            menu.delete(tableref.list)
        end
        tableref = nil
        return
    end
    local pos = tableref.pos
    local rot = tableref.rot
    highlightedHandle = handle
    isInEntityMenu = true
    
    --[ POSITION ]--
    clear_menu_table(tableref.listMenus)
    if handle ~= builder.base.handle then
        table.insert(tableref.listMenus, menu.divider(entityroot, "Position"))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Left / Right", {"pos" .. handle .. "x"}, "Set the X offset from the base entity", -1000000, 1000000, math.floor(pos.x * 100), POS_SENSITIVITY, function (x)
            pos.x = x / 100
            attach_entity(builder.base.handle, handle, pos, rot)
            -- ENTITY.SET_ENTITY_COORDS(handle, pos.x, pos.y, pos.z)
        end))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Front / Back", {"pos" .. handle .. "y"}, "Set the Y offset from the base entity", -1000000, 1000000, math.floor(pos.y * 100), POS_SENSITIVITY, function (y)
            pos.y = y / 100
            attach_entity(builder.base.handle, handle, pos, rot)
        end))
        table.insert(tableref.listMenus, menu.slider_float(entityroot, "Up / Down", {"pos" .. handle .. "z"}, "Set the Z offset from the base entity", -1000000, 1000000, math.floor(pos.z * 100), POS_SENSITIVITY, function (z)
            pos.z = z / 100
            attach_entity(builder.base.handle, handle, pos, rot)
        end))
    end

    --[ ROTATION ]--
    table.insert(tableref.listMenus, menu.divider(entityroot, "Rotation"))
    if not ENTITY.IS_ENTITY_A_PED(handle) then
        table.insert(tableref.listMenus, menu.slider(entityroot, "Pitch", {"rot" .. handle .. "x"}, "Set the X-axis rotation", -175, 180, math.floor(rot.x), ROT_SENSITIVITY, function (x)
            rot.x = x
            attach_entity(builder.base.handle, handle, pos, rot)
        end))
        table.insert(tableref.listMenus, menu.slider(entityroot, "Roll", {"rot" .. handle .. "y"}, "Set the Y-axis rotation", -175, 180, math.floor(rot.y), ROT_SENSITIVITY, function (y)
            rot.y = y
            attach_entity(builder.base.handle, handle, pos, rot)
        end))
    end
    table.insert(tableref.listMenus, menu.slider(entityroot, "Yaw", {"rot" .. handle .. "z"}, "Set the Z-axis rotation", -175, 180, math.floor(rot.z), ROT_SENSITIVITY, function (z)
        rot.z = z
        attach_entity(builder.base.handle, handle, pos, rot)
    end))

    --[ MISC ]--
    table.insert(tableref.listMenus, menu.divider(entityroot, "Misc"))
    if not options.noRename then
        table.insert(tableref.listMenus, menu.text_input(entityroot, "Rename", {"renameent" .. handle}, "Changes the name of this entity", function(name)
            menu.set_menu_name(tableref.list, name)
            tableref.name = name
        end, tableref.name))
    end
    table.insert(tableref.listMenus, menu.toggle(entityroot, "Visible", {"visibility" .. handle}, "Make the prop invisible", function(value)
        tableref.visible = value
        ENTITY.SET_ENTITY_ALPHA(handle, value and 255 or 0)
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
    table.insert(tableref.listMenus, menu.action(entityroot, "Clone", {}, "Clone the entity", function()
        clone_entity(handle, tableref.name)
    end))
    table.insert(tableref.listMenus, menu.action(entityroot, "Delete", {}, "Delete the entity", function()
        if highlightedHandle == handle then
            highlightedHandle = nil
        end
        menu.delete(entityroot)
        tableref = nil
        entities.delete_by_handle(handle)
    end))
end

--[ Save Data ]
function save_vehicle(saveName)
    filesystem.mkdirs(SAVE_DIRECTORY)
    local file = io.open(SAVE_DIRECTORY .. "/" .. saveName .. ".json", "w")
    if file then
        local data = builder_to_json()
        if data then
            file:write(data)
            file:close()
            return true
        else
            file:close()
            return false
        end
    else
        error("Could not create file ' " .. saveName .. ".json'")
    end
end
function load_vehicle_from_file(filename)
    local file = io.open(SAVE_DIRECTORY .. "/" .. filename, "r")
    if file then
        local data = json.decode(file:read("*a"))
        if data.Format then
            log("Ignoring jackz_vehicles vehicle \"" .. filename .. "\": Use jackz_vehicles to spawn", "load_vehicle_from_file")
            return nil
        elseif not data.version then
            log("Ignoring invalid vehicle (no version meta) \"" .. filename .. "\"", "load_vehicle_from_file")
            return nil
        else
            if data.base.visible == nil then
                data.base.visible = true
            end
        end
        
        file:close()
        return data
    else
        error("Could not read file '" .. SAVE_DIRECTORY .. "/" .. filename .. "'")
    end
end

local lastAutosave
function autosave(onDemand)
    if onDemand then
        if lastAutosave - os.seconds() < 5 then
            return
        end
        lastAutosave = os.seconds()
    end
    local name = string.format("_autosave%d", autosaveIndex)
    local success = save_vehicle(name)
    if success then
        util.draw_debug_text("Auto saved " .. name)
    else
        util.toast("Auto save has failed")
    end
    autosaveIndex = autosaveIndex + 1
    if autosaveIndex > MAX_AUTOSAVES then
        autosaveIndex = 0
    end
end
function builder_to_json()
    local objects = {}
    local vehicles = {}
    local peds = {}
    local baseSerialized
    for handle, data in pairs(builder.entities) do
        local serialized = {
            name = data.name,
            model = data.model,
            offset = data.pos,
            rotation = data.rot,
            visible = data.visible,
            type = data.type
        }
        if ENTITY.IS_ENTITY_A_VEHICLE(handle) then
            if data.godmode == nil then
                serialized.godmode = true
                data.godmode = true
            else
                serialized.godmode = data.godmode
            end
        end

        if handle == builder.base.handle then
            baseSerialized = serialized
        elseif data.type == "VEHICLE" then
            if ENTITY.DOES_ENTITY_EXIST(handle) then
                serialized.savedata = vehiclelib.Serialize(handle)
            else
                log("Could not fetch vehicle savedata for deleted vehicle", "builder_to_json")
            end
            table.insert(vehicles, serialized)
        elseif data.type == "PED" then
            table.insert(peds, serialized)
        else
            table.insert(objects, serialized)
        end
    end

    local serialized = {
        name = builder.name,
        author = builder.author,
        created = os.unixseconds(),
        version = FORMAT_VERSION,
        base = {
            model = ENTITY.GET_ENTITY_MODEL(builder.base.handle),
            data = baseSerialized,
            savedata = vehiclelib.Serialize(builder.base.handle)
        },
        objects = objects,
        vehicles = vehicles,
        peds = peds
    }
    
    local status, result = pcall(json.encode, serialized)
    if not status then
        util.toast("WARNING: Could not save your vehicle. Please send Jackz your logs.")
        log("Could not stringify: (" .. result ..") " .. dump_table(serialized))
        return nil
    else
        return result
    end
end

--[ Savedata Options ]--
function import_vehicle_to_builder(data, name)
    local baseHandle = spawn_vehicle(data.base)
    builder = new_builder(baseHandle)
    builder.name = name
    builder.author = data.author
    builder.base.data = data.base.data
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
    setup_builder_menus(name)
    add_attachments(baseHandle, data, true, false)
end
function spawn_vehicle(vehicleData, isPreview)
    STREAMING.REQUEST_MODEL(vehicleData.model)
    while not STREAMING.HAS_MODEL_LOADED(vehicleData.model) do
        util.yield()
    end
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, isPreview and 20.0 or 7.5, 1.0)
    local heading = ENTITY.GET_ENTITY_HEADING(my_ped)

    local handle
    if isPreview then
        handle = VEHICLE.CREATE_VEHICLE(vehicleData.model, pos.x, pos.y, pos.z, heading, false, false)
        ENTITY.SET_ENTITY_ALPHA(handle, 150)
        ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
        VEHICLE._DISABLE_VEHICLE_WORLD_COLLISION(handle)
        VEHICLE.SET_VEHICLE_GRAVITY(handle, false)
        ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(handle, false, false)
        create_preview_handler_if_not_exists()
    else
        handle = entities.create_vehicle(vehicleData.model, pos, heading)
        if vehicleData.visible == false then
            ENTITY.SET_ENTITY_ALPHA(handle, 0)
        end
        if vehicleData.godmode or vehicleData.godmode == nil then
            ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
        end
    end

    if vehicleData.savedata then
        vehiclelib.ApplyToVehicle(handle, vehicleData.savedata)
    end
    return handle, pos
end

function spawn_custom_vehicle(data, isPreview)
    -- TODO: Implement all base data
    remove_preview_custom()
    local baseHandle, pos = spawn_vehicle(data.base, isPreview)
    if isPreview then
        preview.entity = baseHandle
    end
    if data.base.visible and data.base.visible == false or (data.base.data and data.base.data.visible == false) then
        ENTITY.SET_ENTITY_ALPHA(baseHandle, 0, 0)
    end
    ENTITY.SET_ENTITY_INVINCIBLE(baseHandle, true)
    add_attachments(baseHandle, data, false, isPreview)
    if spawnInVehicle and not isPreview then
        util.yield()
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
    end
    return baseHandle
end

function add_attachments(baseHandle, data, addToBuilder, isPreview)
    local pos = ENTITY.GET_ENTITY_COORDS(baseHandle)
    local handles = {}
    for _, entityData in ipairs(data.objects) do
        local name = entityData.name or "<nil>"
        if not STREAMING.IS_MODEL_VALID(entityData.model) then
            util.toast("Object has invalid model: " .. name .. " model " .. entityData.model, TOAST_DEFAULT | TOAST_LOGGER)
        else
            STREAMING.REQUEST_MODEL(entityData.model)
            while not STREAMING.HAS_MODEL_LOADED(entityData.model) do
                util.yield()
            end
            local handle = isPreview
                and OBJECT.CREATE_OBJECT(entityData.model, pos.x, pos.y, pos.z, false, false, 0)
                or entities.create_object(entityData.model, pos)

            if handle == 0 then
                util.toast("Object failed to spawn: " .. name .. " model " .. entityData.model, TOAST_DEFAULT | TOAST_LOGGER)
            else
                if entityData.visible == false then
                    ENTITY.SET_ENTITY_ALPHA(handle, 0, false)
                end
                for _, handle2 in ipairs(handles) do
                    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, handle2)
                end
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(baseHandle, handle)
                table.insert(handles, handle)

                if addToBuilder then
                    add_entity_to_list(builder.entitiesMenuList, handle, entityData.name, entityData.offset, entityData.rotation)
                else
                    attach_entity(baseHandle, handle, entityData.offset, entityData.rotation)
                end
            end
        end
    end
    -- bad dupe code but im sick i dont care
    if data.peds then
        for _, pedData in ipairs(data.peds) do
            local name = pedData.name or "<nil>"
            if not STREAMING.IS_MODEL_VALID(pedData.model) then
                util.toast("Ped has invalid model: " .. name .. " model " .. pedData.model, TOAST_DEFAULT | TOAST_LOGGER)
            else
                STREAMING.REQUEST_MODEL(pedData.model)
                while not STREAMING.HAS_MODEL_LOADED(pedData.model) do
                    util.yield()
                end
                local handle = isPreview
                    and PED.CREATE_PED(0, pedData.model, pos.x, pos.y, pos.z, 0, false, false)
                    or entities.create_ped(0, pedData.model, pos, 0)

                if handle == 0 then
                    util.toast("Ped failed to spawn: " .. name .. " model " .. pedData.model, TOAST_DEFAULT | TOAST_LOGGER)
                else
                    if pedData.visible == false then
                        ENTITY.SET_ENTITY_ALPHA(handle, 0, false)
                    end
                    for _, handle2 in ipairs(handles) do
                        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, handle2)
                    end
                    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(baseHandle, handle)
                    table.insert(handles, handle)

                    if addToBuilder then
                        add_entity_to_list(builder.entitiesMenuList, handle, pedData.name, pedData.offset, pedData.rotation)
                    else
                        attach_entity(baseHandle, handle, pedData.offset, pedData.rotation)
                    end
                end
            end
        end
    end
    if data.vehicles then
        for _, vehData in ipairs(data.vehicles) do
            local handle = spawn_vehicle(vehData, isPreview)
    
            if vehData.visible == false then
                ENTITY.SET_ENTITY_ALPHA(handle, 0, false)
            end
            ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
            for _, handle2 in ipairs(handles) do
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, handle2)
            end
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(baseHandle, handle)
            table.insert(handles, handle)

            if addToBuilder then
                add_entity_to_list(builder.entitiesMenuList, handle, vehData.name, vehData.offset, vehData.rotation)
            else
                attach_entity(baseHandle, handle, vehData.offset, vehData.rotation)
            end
        end
    end
end


-- [ UTILS ]--
function log(str, mod)
    if mod then
        util.log("jackz_vehicle_builder[" .. (SCRIPT_SOURCE or "DEV") .. "]/" .. mod .. ": " .. str)
    else
        util.log("jackz_vehicle_builder[" .. (SCRIPT_SOURCE or "DEV") .. "]: " .. str)
    end
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
 

function attach_entity(parent, handle, pos, rot)
    if pos == nil or rot == nil then
        log("null pos or rot" .. debug.traceback(), "attach_entity")
        return
    end
    if parent == handle then
        ENTITY.SET_ENTITY_ROTATION(handle, rot.x or 0, rot.y or 0, rot.z or 0)
    else
        ENTITY.ATTACH_ENTITY_TO_ENTITY(handle, parent, 0,
            pos.x or 0, pos.y or 0, pos.z or 0,
            rot.x or 0, rot.y or 0, rot.z or 0,
            false, true, true, false, 2, true
        )
    end

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

util.on_stop(function()
    remove_preview_custom()
end)

while true do
    local seconds = os.seconds()
    if builder ~= nil and seconds >= autosaveNextTime then
        autosaveNextTime = seconds + AUTOSAVE_INTERVAL_SEC
        autosave()
    end
    if highlightedHandle ~= nil then
        highlight_object(highlightedHandle)
        show_marker(highlightedHandle, 0)
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
                attach_entity(builder.base.handle, highlightedHandle, pos, rot)
            end
        end
        util.draw_debug_text(string.format("%d pos(%.1f, %.1f, %.1f) rot(%.0f, %.0f, %.0f)", highlightedHandle, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z))
    end
    util.yield()
end