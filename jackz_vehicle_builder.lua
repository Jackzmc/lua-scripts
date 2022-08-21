-- Jackz Vehicle Builder
-- [ Boiler Plate ]--
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "jackz_vehicle_builder"
local VERSION = "1.17.0"
local LANG_TARGET_VERSION = "1.3.3" -- Target version of translations.lua lib
local VEHICLELIB_TARGET_VERSION = "1.1.4"
---@alias Handle number
---@alias MenuHandle number

-- Still needed for local dev
--#P:DEBUG_ONLY
function show_busyspinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end
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
--#P:END

--#P:TEMPLATE("_SOURCE")
--#P:TEMPLATE("common")

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


-- [ Begin actual script ]--
local AUTOSAVE_INTERVAL_SEC = 60 * 3
local MAX_AUTOSAVES = 4
local autosaveNextTime = 0
local autosaveIndex = 1
local BUILDER_VERSION = "1.3.0" -- For version diff warnings
local FORMAT_VERSION = "Jackz Custom Vehicle " .. BUILDER_VERSION
local builder = nil
local editorActive = false
local pedAnimCache = {}
local pedAnimThread
local hud_coords = {x = memory.alloc(8), y = memory.alloc(8), z = memory.alloc(8) }

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
        prop_list_active = false,
        blip_icon = 225
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
local preview = { -- Handles preview tracking and clearing
    entity = 0,
    id = nil,
    thread = nil,
    range = -1,
    rendercb = nil, -- Function to render a text preview 
    renderdata = nil
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

local BLIP_ICONS = {
    { 64, "Helicopter (Black)" },
    { 56, "Police Car" },
    { 58, "Star " },
    { 67, "Van " },
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
    { 533, "Vehicle 6"},
    { 534, "Vehicle 7"},
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
    peds = {}
}
local FAVORITES_PATH = os.fil

function save_favorites_list()

end

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
local AUTOSAVE_DIRECTORY = join_path(SAVE_DIRECTORY, "autosaves")
local DOWNLOADS_DIRECTORY = join_path(SAVE_DIRECTORY, "downloads")
if not filesystem.exists(PROPS_PATH) then
    util.toast("jackz_vehicle_builder: objects.txt in resources folder does not exist. Please properly install this script.", TOAST_ALL)
    util.log("Resources directory: ".. PROPS_PATH)
    util.stop_script()
end
if not filesystem.exists(PEDS_PATH) then
    util.log(SCRIPT_NAME .. ": Downloading resource update for peds.txt")
    download_resources_update("peds.txt")
end
if not filesystem.exists(AUTOSAVE_DIRECTORY) then
    io.makedir(AUTOSAVE_DIRECTORY)
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
                pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0, preview.range or 5.0, 0.3)
                ENTITY.SET_ENTITY_COORDS(preview.entity, pos.x, pos.y, pos.z, true, true, false, false)
                ENTITY.SET_ENTITY_HEADING(preview.entity, heading)

                if preview.rendercb then
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
local utilsMenu = menu.list(menu.my_root(), "Utilities", {"builderutils"}, "Some utilities such as clearing entities")
menu.action(utilsMenu, "Delete Preview", {"jvbstoppreview"}, "Removes currently active preview.", function()
    if preview.entity == 0 then
        util.toast("No preview is active")
    end
    remove_preview_custom()
end)
menu.click_slider(utilsMenu, "Clear Nearby Vehicles", {"jvbclearvehs"}, "Clears all nearby vehicles within defined range", 500, 100000, 500, 6000, function(range)
    local vehicles = entities.get_all_vehicles_as_handles()
    local count = _clear_ents(vehicles, range)
    util.toast("Deleted " .. count .. " vehicles")
end)
menu.click_slider(utilsMenu, "Clear Nearby Objects", {"jvbclearobjs"}, "Clears all nearby objects within defined range", 500, 100000, 500, 6000, function(range)
    local vehicles = entities.get_all_objects_as_handles()
    local count = _clear_ents(vehicles, range)
    util.toast("Deleted " .. count .. " objects")
end)

menu.click_slider(utilsMenu, "Clear Nearby Peds", {"jvbclearpeds"}, "Clears all nearby peds within defined range", 500, 100000, 500, 6000, function(range)
    local vehicles = entities.get_all_peds_as_handles()
    local count = _clear_ents(vehicles, range)
    util.toast("Deleted " .. count .. " peds")
end)

function _clear_ents(list, range)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local count = 0
    for _, entity in ipairs(list) do
        local pos2 = ENTITY.GET_ENTITY_COORDS(entity, 1)
        local dist = SYSTEM.VDIST(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
        if dist <= range then
            util.draw_debug_text(string.format("deleted entity %d - %f m away", entity, dist))
            entities.delete_by_handle(entity)
            count = count + 1
        end
    end
    return count
end
--[[
    SETTINGS
]]--
local scriptSettings = {
    autosaveEnabled = true,
    showOverlay = true
}
local settingsList = menu.list(menu.my_root(), "Settings", {"jvbcfg"}, "Change settings of script")
menu.toggle(settingsList, "Autosave Active", {"jvbautosave"}, "Autosaves happen every 4 minutes, disable to turn off autosaving\nExisting autosaves will not be deleted.", function(value)
    scriptSettings.autosaveEnabled = value
end, scriptSettings.autosaveEnabled)
menu.toggle(settingsList, "Show Overlay", {"jvboverlay"}, "Shows an overlay on the currently entity you are editing. Only shown when menu is open", function(value)
    scriptSettings.showOverlay = value
end, scriptSettings.showOverlay)

menu.divider(menu.my_root(), "")

--[[
    CLOUD DATA
]]--
local cloudData = {}
local cloudRootMenuList = menu.list(menu.my_root(), "Cloud Vehicles", {}, "Browse & upload custom built vehicles", function() _fetch_cloud_users() end, function() 
    for _, data in pairs(cloudData) do
        menu.delete(data.parentList)
    end
    cloudData = {}
end)
local cloudSearchList = menu.list(cloudRootMenuList, "Search Vehicles", {}, "Search all uploaded custom vehicles")
local cloudSearchResults = {}
menu.text_input(cloudSearchList, "Search", {"customvehiclesearch"}, "Enter a search query", function(query)
    if query == "" then return end
    show_busyspinner("Searching vehicles...")
    for _, data in pairs(cloudSearchResults) do
        menu.delete(data.list)
    end
    cloudSearchResults = {}
    async_http.init("jackz.me", "/stand/cloud/custom-vehicles.php?q=" .. query, function(body)
        HUD.BUSYSPINNER_OFF()
        if body[1] == "{" then
            local results = json.decode(body).results
            for _, vehicle in ipairs(results) do
                
                local description = _format_vehicle_info(vehicle.format, vehicle.uploaded, vehicle.uploader, vehicle.rating)
                cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name] = {
                    list = nil,
                    data = nil
                }
                local vehicleList = menu.list(cloudSearchList, string.format("%s/%s", vehicle.uploader, vehicle.name), {}, description or "<invalid metadata>", function()
                    _setup_cloud_vehicle_menu(cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name].list, vehicle.uploader, vehicle.name, cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name])
                end)
                cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name].list = vehicleList
                menu.on_focus(vehicleList, function()
                    _fetch_vehicle_data(cloudSearchResults[vehicle.uploader .. "/" .. vehicle.name], vehicle.uploader, vehicle.name)
                end)
            end
        else
            log("invalid server response : " .. body, "_fetch_cloud_users")
            util.toast("Server returned invalid response")
        end
    end)
    async_http.dispatch()
end)
menu.divider(cloudRootMenuList, "Users")
function _fetch_cloud_users()
    show_busyspinner("Fetching cloud data...")
    async_http.init("jackz.me", "/stand/cloud/custom-vehicles.php", function(body)
        HUD.BUSYSPINNER_OFF()
        if body[1] == "{" then
            cloudData = json.decode(body).users
            for user, vehicles in pairsByKeys(cloudData) do
                local userList = menu.list(cloudRootMenuList, string.format("%s (%d)", user, #vehicles), {}, string.format("%d vehicles", #vehicles), function()
                    _load_cloud_vehicles(user)
                end, function()
                    cloudData[user].vehicleData = {}
                end)
                menu.on_focus(userList, remove_preview_custom)
                cloudData[user] = {
                    vehicles = vehicles,
                    vehicleData = {},
                    parentList = userList,
                    vehicleMenuIds = {}
                }
            end
        else
            log("invalid server response : " .. body, "_fetch_cloud_users")
            util.toast("Server returned invalid response")
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
            vehicleMenuRoot = menu.list(cloudData[user].parentList, vehicle.name, {}, description or "<invalid vehicle metadata>", function()
                _setup_cloud_vehicle_menu(vehicleMenuRoot, user, vehicle.name, cloudData[user].vehicles[vehicle.name])
            end)
            menu.on_focus(vehicleMenuRoot, function()
                _fetch_vehicle_data(cloudData[user].vehicles[vehicle.name], user, vehicle.name)
            end)

            table.insert(cloudData[user].vehicleMenuIds, vehicleMenuRoot)

        end
    end
end
function _fetch_vehicle_data(tableref, user, vehicleName)
    show_busyspinner("Fetching vehicle info...")
    async_http.init("jackz.me", string.format("/stand/cloud/custom-vehicles.php?scname=%s&vehicle=%s", user, vehicleName), function(body)
        HUD.BUSYSPINNER_OFF()
        if body[1] == "{" then
            remove_preview_custom()
            local data = json.decode(body)
            if not data.vehicle then
                log(body, "_fetch_vehicle_data")
                util.toast("Invalid vehicle data was fetched")
                return
            end
            tableref['vehicle'] = data.vehicle
            if not data.vehicle.name then
                data.vehicle.name = vehicleName
            end
            data.uploader = user
            spawn_custom_vehicle(tableref['vehicle'], true, _render_cloud_vehicle_overlay, data)
        else
            log("invalid server response : " .. body, "_fetch_cloud_users")
            util.toast("Server returned an invalid response. Possibly ratelimited or server under maintenance")
        end
    end)
    async_http.dispatch()
end
function _setup_cloud_vehicle_menu(rootList, user, vehicleName, vehicleData)
    local tries = 0
    while not vehicleData['vehicle'] and tries < 10 do
        util.yield(500)
        tries = tries + 1
    end
    if tries > 10 then
        util.toast("Vehicle data timed out")
        return
    end
    while not vehicleData and tries < 30 do
        util.yield(500)
        tries = tries + 1
    end
    if tries == 30 then return end
    menu.action(rootList, "Spawn", {}, "", function()
        remove_preview_custom()
        spawn_custom_vehicle(vehicleData['vehicle'], false)
    end)

    menu.action(rootList, "Edit", {}, "", function()
        import_vehicle_to_builder(vehicleData['vehicle'], vehicleName)
        menu.focus(builder.entitiesMenuList)
    end)
    menu.text_input(rootList, "Download", {"download"..user.."."..vehicleName}, "", function(filename)
        if filename == "" then return end
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

    menu.click_slider(rootList, "Rate", {"rate"..user.."."..vehicleName}, "Rate the uploaded vehicle with 1-5 stars", 1, 5, 5, 1, function(rating)
        rate_vehicle(user, vehicleName, rating)
    end)
end
function rate_vehicle(user, vehicleName, rating)
    if not user or not vehicleName or rating < 0 or rating > 5 then
        log("Invalid rate params. " .. user .. "|" .. vehicleName .. "|" .. rating, "_setup_cloud_vehicle_menu/rate")
        return false
    end
    -- SOCIALCLUB._SC_GET_NICKNAME(), name, menu.get_activation_key_hash()
    async_http.init("jackz.me", 
        string.format("/stand/cloud/custom-vehicles2.php?scname=%s&vehicle=%s&hashkey=%s&rater=%s&rating=%d",
            user, vehicleName, menu.get_activation_key_hash(), SOCIALCLUB._SC_GET_NICKNAME(), rating
        ),
    function(body)
        local data = json.decode(body)
        if data.success then
            util.toast("Rating submitted")
        else
            log(body)
            util.toast("Failed to submit rating, see logs")
        end

    end, function()
        util.toast("Failed to submit rating")
    end)
    async_http.set_post("application/json", "")
    async_http.dispatch()
    return true
end
--[ SAVED VEHICLES LIST ]
local savedVehicleList = menu.list(menu.my_root(), "Saved Custom Vehicles", {}, "",
    function() _load_saved_list() end,
    function() _destroy_saved_list() end
)
local folderLists = {}
local xmlMenusHandles = {}
local spawnInVehicle = true
menu.toggle(savedVehicleList, "Spawn In Vehicle", {}, "Force yourself to spawn in the base vehicle", function(on)
    spawnInVehicle = on
end, spawnInVehicle)
local xmlList = menu.list(savedVehicleList, "Convert XML Vehicles", {}, "Convert XML vehicle (including menyoo) to a compatible format")
menu.divider(savedVehicleList, "Folders")
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
    table.insert(folderLists, menu.divider(parentList, "Vehicles"))
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
            versionText = string.format("%s (Unsupported Version, latest %s)", fileVersion, BUILDER_VERSION)
        else
            versionText = string.format("%s (Latest)", fileVersion, BUILDER_VERSION)
        end

        local createdText = timestamp and (os.date("%Y-%m-%d at %X", timestamp) .. " UTC") or "-unknown-"
        local authorText = author and (string.format("Vehicle Author: %s\n", author)) or ""
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
    local status, data = pcall(get_vehicle_data_from_file, filepath)
    if status and data ~= nil then
        if not data.base or not data.objects then
            log("Skipping invalid vehicle: " .. filepath)
            return
        end
        
        local description = _format_vehicle_info(data.version, data.created, data.author)

        optionParentMenus[filepath] = menu.list(parentList, filename, {}, description or "<INVALID METADATA>",
            function()
                clear_menu_table(optionsMenuHandles)
                local m = menu.action(optionParentMenus[filepath], "Spawn", {}, "", function()
                    lastAutosave = os.seconds()
                    autosaveNextTime = lastAutosave + AUTOSAVE_INTERVAL_SEC
                    remove_preview_custom()
                    spawn_custom_vehicle(data, false)
                end)
                table.insert(optionsMenuHandles, m)
    
                m = menu.action(optionParentMenus[filepath], "Edit", {}, "", function()
                    lastAutosave = os.seconds()
                    autosaveNextTime = lastAutosave + AUTOSAVE_INTERVAL_SEC
                    import_vehicle_to_builder(data, filename:sub(1, -6))
                    menu.focus(builder.entitiesMenuList)
                end)
                table.insert(optionsMenuHandles, m)

                m = menu.action(optionParentMenus[filepath], "Upload", {}, "", function()
                    upload_vehicle(filename:sub(1, -6), json.encode(data))
                end)
                table.insert(optionsMenuHandles, m)
            end,
            function() _destroy_options_menu() end
        )
        
        -- Spawn custom vehicle handler
        menu.on_focus(optionParentMenus[filepath], function()
            if preview.id ~= filename then
                data.filename = filename
                spawn_custom_vehicle(data, true, _render_saved_vehicle_overlay, data)
            end
        end)
    else
        log(string.format("Skipping vehicle \"%s\" due to error: (%s)", filepath, (data or "<EMPTY FILE>")))
    end
end
function _render_saved_vehicle_overlay(pos, data)
    local hudPos = get_screen_coords(pos)
    directx.draw_rect(hudPos.x, hudPos.y, 0.25, 0.105, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
    local authorText = data.author and ("Created by " .. data.author) or "Unknown creator"

    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, data.name or data.filename, ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, data.version, ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.075, string.format("%d vehicles, %d objects, %d peds", data.vehicles and #data.vehicles or 0, data.objects and #data.objects or 0, data.peds and #data.peds or 0), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
end
function _render_cloud_vehicle_overlay(pos, data)
    local hudPos = get_screen_coords(pos)
    directx.draw_rect(hudPos.x, hudPos.y, 0.25, 0.12, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
    local authorText = data.vehicle.author and ("Created by " .. data.vehicle.author) or "Unknown creator"

    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, data.vehicle.name, ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.025, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.042, "Uploaded by " .. data.uploader, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.065, data.vehicle.version, ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.08, string.format("%d vehicles, %d objects, %d peds", data.vehicle.vehicles and #data.vehicle.vehicles or 0, data.vehicle.objects and #data.vehicle.objects or 0, data.vehicle.peds and #data.vehicle.peds or 0), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.095, string.format("%d star rating", data.rating), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
end
function _load_saved_list()
    remove_preview_custom()
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
            set_builder_vehicle(vehicle)
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
    mainMenu = menu.list(menu.my_root(), "Custom Vehicle Builder", {}, "", function() 
        editorActive = true
    end, function()
        editorActive = false
        _destroy_prop_previewer()
    end)
    menu.text_input(mainMenu, "Save", {"savecustomvehicle"}, "Enter the name to save the vehicle as\nSupports relative paths such as myfoldername\\myvehiclename", function(name)
        if name == "" then return end
        set_builder_name(name)
        if save_vehicle(name) then
            util.toast("Saved vehicle as " .. name .. ".json to %appdata%\\Stand\\Vehicles\\Custom")
        end
    end, name or "")
    local uploadMenu
    uploadMenu = menu.text_input(mainMenu, "Upload", {"uploadcustomvehicle"}, "Enter the name to upload the vehicle as", function(name)
        if name == "" then return end
        set_builder_name(name)
        if not builder.author then
            menu.show_warning(uploadMenu, CLICK_MENU, "You are uploading a vehicle without an author set. An author is not required, but the author will be tied to the vehicle itself.", function()
                upload_vehicle(name, builder_to_json())
            end)
        else
            upload_vehicle(name, builder_to_json())
        end
    end, name or "")
    menu.text_input(mainMenu, "Author", {"customvehicleauthor"}, "Set the author of the vehicle. None is set by default.", function(input)
        builder.author = input
        util.toast("Set the vehicle's author to: " .. input)
    end, builder.author or "")

    builder.entitiesMenuList = menu.list(mainMenu, "Entities", {}, "", function() highlightedHandle = nil end)
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
        menu.on_focus(settingsList, function()
            highlightedHandle = builder.base.handle
        end)
        menu.action(baseList, "Teleport Into", {}, "Teleport into the base vehicle", function()
            local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, builder.base.handle, -1)
        end)
        menu.action(baseList, "Delete All Entities", {}, "Removes all entities attached to vehicle, including pre-existing entities.", function()
            remove_all_attachments(builder.base.handle)
            for handle, data in pairs(builder.entities) do
                if handle ~= builder.base.handle then
                    menu.delete(data.list)
                    builder.entities[handle] = nil
                end
            end
            if highlightedHandle ~= builder.base.handle then
                highlightedHandle = nil
            end
        end)
        menu.action(baseList, "Set current vehicle as new base", {}, "Re-assigns the entities to a new base vehicle", function()
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
            if vehicle > 0 then
                if vehicle == builder.base.handle then
                    util.toast("This vehicle is already the base vehicle.")
                else
                    log("Reassigned base " .. builder.base.handle .. " -> " .. vehicle)
                    builder.entities[vehicle] = builder.entities[builder.base.handle]
                    builder.entities[builder.base.handle] = nil
                    builder.entities[vehicle].model = ENTITY.GET_ENTITY_MODEL(vehicle)
                    set_builder_vehicle(vehicle)
                    for handle, data in pairs(builder.entities) do
                        attach_entity(vehicle, handle, data.pos, data.rot)
                    end
                end
            else
                util.toast("You are not in a vehicle.")
            end
        end)
        local deleteMenu
        deleteMenu = menu.action(baseList, "Delete Custom Vehicle", {}, "Deletes the active builder with all settings and entities cleared", function()
            menu.show_warning(deleteMenu, CLICK_COMMAND, "Are you sure you want to delete your custom vehicle? All settings and entities will be wiped.", function()
                remove_all_attachments(builder.base.handle)
                builder = nil
            end)
            if HUD.DOES_BLIP_EXIST(builder.blip) then
                util.remove_blip(builder.blip)
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
        local blipList = menu.list(settingsList, "Blip Icon", {"jvbicon"}, "Changes the blip icon for this custom vehicle.")
        for _, icon in ipairs(BLIP_ICONS) do
            menu.action(blipList, icon[2], {"jvbicon" .. icon[1]}, "Blip ID: " .. icon[1], function()
                builder.blip_icon = icon[1]
                if HUD.DOES_BLIP_EXIST(builder.blip) then
                    HUD.SET_BLIP_SPRITE(builder.blip, icon[1])
                end
            end)
        end
        create_entity_section(builder.entities[builder.base.handle], builder.base.handle, { noRename = true } )
end

function set_builder_vehicle(handle)
    builder.base.handle = handle
    if HUD.DOES_BLIP_EXIST(builder.blip) then
        util.remove_blip(builder.blip)
    end
    builder.blip = create_blip_for_entity(handle, builder.blip_icon, builder.name or "Custom Vehicle")
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

    file = io.open(RECENTS_DIR .. "peds.txt", "w+")
    for id, data in pairs(builder.pedSpawner.recents.items) do
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
            set_preview(entity, propName)
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
        -- TODO: Spawn ped somewhere else and teleport to correct location
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        ENTITY.FREEZE_ENTITY_POSITION(entity)
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
            local entity = PED.CREATE_PED(0, hash, 0, 0, 0, 0, false, false);
            ENTITY.SET_ENTITY_COORDS(entity, pos.x, pos.y, pos.z)
            ENTITY.FREEZE_ENTITY_POSITION(entity)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
            if entity == 0 then
                log("Could not create preview for " .. pedName .. "(" .. hash .. ")")
                return
            end
            set_preview(entity, pedName)
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
            set_preview(entity, vehicleID)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        end
    end)
    return menuHandle
end
--[ Previewer Stuff ]--

function set_preview(entity, id, range, renderfunc, renderdata)
    remove_preview_custom()
    preview.entity = entity
    preview.id = id
    preview.range = range or -1
    preview.rendercb = renderfunc
    preview.renderdata = renderdata
    create_preview_handler_if_not_exists()
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
function remove_all_attachments(handle)
    for _, entity in ipairs(entities.get_all_objects_as_handles()) do
        if entity ~= handle and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(handle, entity) then
            entities.delete_by_handle(entity)
        end
    end
    for _, entity in ipairs(entities.get_all_vehicles_as_handles()) do
        if entity ~= handle and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(handle, entity) then
            entities.delete_by_handle(entity)
        end
    end
    for _, entity in ipairs(entities.get_all_peds_as_handles()) do
        if entity ~= handle and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(handle, entity) then
            entities.delete_by_handle(entity)
        end
    end
end
function remove_preview_custom()
    local old_entity = preview.entity
    preview.entity = 0
    preview.id = nil
    if old_entity ~= 0 and ENTITY.DOES_ENTITY_EXIST(old_entity) then
        remove_all_attachments(old_entity)
        entities.delete_by_handle(old_entity)
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
        memory.free(p_bool)
        memory.free(p_endPos)
        memory.free(p_surfaceNormal)
        memory.free(p_entityHit)
        callback(did_hit, entity, endCoords, surfaceNormal)
    end)
end

-- [ ENTITY EDITING HANDLING ]
function add_entity_to_list(list, handle, name, pos, rot)
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
    builder.entities[handle] = {
        name = name or "(no name)",
        type = type,
        model = model,
        list = nil,
        listMenus = {},
        pos = pos or { x = 0.0, y = 0.0, z = 0.0 },
        rot = rot or { x = 0.0, y = 0.0, z = 0.0 },
        visible = true,
        godmode = (type ~= "OBJECT") and true or nil
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
    -- create_entity_section(builder.entities[handle], handle)
    return builder.entities[handle]
end

function clone_entity(handle, name, mirror_axis)
    local model = ENTITY.GET_ENTITY_MODEL(handle)
    local entity
    local pos
    if mirror_axis then
        if not builder.entities[handle] then
            log("clone_entity with mirror_axis set on non-builder entity", "clone_entity")
            return false
        end
        pos = builder.entities[handle].pos
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
    add_entity_to_list(builder.entitiesMenuList, entity, name, pos)
    highlightedHandle = entity
    return entity
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
    local cloneList = menu.list(entityroot, "Clone", {}, "Clone the entity")
    table.insert(tableref.listMenus, cloneList)
        menu.action(cloneList, "Clone In-place", {}, "Clones the entity where it is", function()
            clone_entity(handle, tableref.name, 0)
        end)
        menu.action(cloneList, "Mirror (X-Axis)", {}, "Clones the entity, mirrored on the x-axis", function()
            clone_entity(handle, tableref.name, 1)
        end)
        menu.action(cloneList, "Mirror (Y-Axis)", {}, "Clones the entity, mirrored on the y-axis", function()
            clone_entity(handle, tableref.name, 2)
        end)
        menu.action(cloneList, "Mirror (Y-Axis)", {}, "Clones the entity, mirrored on the y-axis", function()
            clone_entity(handle, tableref.name, 3)
        end)
    table.insert(tableref.listMenus, menu.action(entityroot, "Delete", {}, "Delete the entity", function()
        if highlightedHandle == handle then
            highlightedHandle = nil
        end
        menu.delete(entityroot)
        tableref = nil
        -- Fix deleting not working
        if builder.entities[handle] then
            builder.entities[handle] = nil
        end
        entities.delete_by_handle(handle)
    end))
end

--[ Save Data ]
function save_vehicle(saveName, folder)
    if not folder then
        folder = SAVE_DIRECTORY
    end
    filesystem.mkdirs(folder)
    local file = io.open(folder .. "/" .. saveName .. ".json", "w")
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
function upload_vehicle(name, data)
    show_busyspinner("Uploading vehicle")
    async_http.init("jackz.me", 
        string.format("/stand/cloud/custom-vehicles.php?scname=%s&vehicle=%s&hashkey=%s&v=%s",
        SOCIALCLUB._SC_GET_NICKNAME(), name, menu.get_activation_key_hash(), VERSION
    ), function(body)
        local response = json.decode(body)
        if response.error then
            log(string.format("name:%s, vehicle: %s failed to upload: %s", SOCIALCLUB._SC_GET_NICKNAME(), name, response.message))
            util.toast("Upload error: " .. response.message)
        elseif response.status then
            if response.status == "updated" then
                util.toast("Successfully updated vehicle")
            else
                util.toast("Successfully uploaded vehicle")
            end
        else
            util.toast("Server sent invalid response")
        end
        HUD.BUSYSPINNER_OFF()
    end, function()
        util.toast("Failed to upload your vehicle (" .. name .. ")")
    end)
    async_http.set_post("application/json", data)
    async_http.dispatch()
end
function get_vehicle_data_from_file(filepath)
    local file = io.open(filepath, "r")
    if file then
        local data = json.decode(file:read("*a"))
        if data.Format then
            log("Ignoring jackz_vehicles vehicle \"" .. filepath .. "\": Use jackz_vehicles to spawn", "load_vehicle_from_file")
            return nil
        elseif not data.version then
            log("Ignoring invalid vehicle (no version meta) \"" .. filepath .. "\"", "load_vehicle_from_file")
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
function autosave(onDemand)
    if not scriptSettings.autosaveEnabled then return end
    if onDemand then
        if lastAutosave - os.seconds() < 5 then
            return
        end
        lastAutosave = os.seconds()
    end
    local name = string.format("_autosave%d", autosaveIndex)
    local success = save_vehicle(name, AUTOSAVE_DIRECTORY)
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
        elseif ENTITY.IS_ENTITY_A_PED(handle) then
            serialized.animdata = data.animdata
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

    if baseSerialized then
        baseSerialized.offset = nil
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
        blip_icon = builder.blip_icon,
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
    remove_preview_custom()
    local baseHandle = spawn_vehicle(data.base)
    if baseHandle then
        builder = new_builder(baseHandle)
        builder.name = name
        builder.author = data.author
        builder.base.data = data.base.data
        builder.blip_icon = data.blip_icon
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        TASK.TASK_WARP_PED_INTO_VEHICLE(my_ped, baseHandle, -1)
        setup_builder_menus(name)
        set_builder_vehicle(baseHandle)
        add_attachments(baseHandle, data, true, false)
    else
        util.toast("Cannot create base vehicle, editing not possible.")
    end
end
function spawn_vehicle(vehicleData, isPreview)
    if not STREAMING.IS_MODEL_VALID(vehicleData.model) then
        log(string.format("invalid vehicle model (name:%s) (model:%s)", vehicleData.name, vehicleData.model))
        util.toast(string.format("Failing to spawn vehicle (%s) due to invalid model.", vehicleData.name or "<no name>"))
        return
    end
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
        -- set_preview(handle)
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

function spawn_custom_vehicle(data, isPreview, previewFunc, previewData)
    -- TODO: Implement all base data
    remove_preview_custom()
    local baseHandle, pos = spawn_vehicle(data.base, isPreview)
    if baseHandle then
        if isPreview then
            set_preview(baseHandle, "_base", 100.0, previewFunc, previewData)
        else
            create_blip_for_entity(baseHandle, data.blip_icon, data.name or "Custom Vehicle")
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
    else
        util.toast("Could not spawn base vehicle")
    end
end

function add_attachments(baseHandle, data, addToBuilder, isPreview)
    local pos = ENTITY.GET_ENTITY_COORDS(baseHandle)
    local handles = {}
    if data.objects then
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
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)

                
                if pedData.visible == false then
                    ENTITY.SET_ENTITY_ALPHA(handle, 0, false)
                end
                if not pedData.godmode then
                    pedData.godmode = true
                end
                ENTITY.SET_ENTITY_INVINCIBLE(handle, pedData.godmode)

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
                        local datatable = add_entity_to_list(builder.entitiesMenuList, handle, pedData.name, pedData.offset, pedData.rotation)
                        datatable.animdata = pedData.animdata
                    else
                        attach_entity(baseHandle, handle, pedData.offset, pedData.rotation)
                    end
                end

                if pedData.animdata then
                    STREAMING.REQUEST_ANIM_DICT(pedData.animdata[1])
                    while not STREAMING.HAS_ANIM_DICT_LOADED(pedData.animdata[1]) do
                        util.yield()
                    end
                    TASK.TASK_PLAY_ANIM(handle, pedData.animdata[1], pedData.animdata[2], 8.0, 8.0, -1, 1, 1.0, false, false, false)
                    table.insert(pedAnimCache, { handle = handle, animdata = pedData.animdata })
                    if not pedAnimThread then
                        pedAnimThread = util.create_thread(function()
                            while #pedAnimCache > 0 do
                                for _, entry in ipairs(pedAnimCache) do
                                    if not ENTITY.IS_ENTITY_PLAYING_ANIM(entry.handle, entry.animdata[1], entry.animdata[2], 3) then
                                        TASK.TASK_PLAY_ANIM(entry.handle, entry.animdata[1], entry.animdata[2], 8.0, 8.0, -1, 1, 1.0, false, false, false)
                                    end
                                    if builder and builder.entities[entry.handle] then
                                        attach_entity(builder.base.handle, entry.handle, builder.entities[entry.handle].pos, builder.entities[entry.handle].rot)
                                    end
                                end
                                util.yield(4000)
                            end
                        end)
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
            if not vehData.godmode then
                vehData.godmode = true
            end
            ENTITY.SET_ENTITY_INVINCIBLE(handle, vehData.godmode)
            for _, handle2 in ipairs(handles) do
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(handle, handle2)
            end
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(baseHandle, handle)
            ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
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
    if builder and builder.blip and HUD.DOES_BLIP_EXIST(builder.blip) then
        util.remove_blip(builder.blip)
    end
    for k in pairs(hud_coords) do
        memory.free(hud_coords[k])
    end
    remove_preview_custom()
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
add_text(builder.name or "Unnamed custom vehicle", 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
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


while true do
    local seconds = os.seconds()
    
    if builder ~= nil then
        if scriptSettings.autosaveEnabled and menu.is_open() and seconds >= autosaveNextTime then
            autosaveNextTime = seconds + AUTOSAVE_INTERVAL_SEC
            autosave()
        end
        get_entity_lookat(40.0, 5.0, nil, function(did_hit, entity, pos)
            if did_hit and entity and builder.entities[entity] == nil and NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(entity) then
                local hudPos = get_screen_coords(pos)
                local type = "OBJECT"
                if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
                    type = "VEHICLE"
                elseif ENTITY.IS_ENTITY_A_PED(entity) then
                    type = "PED"
                end
                directx.draw_rect(hudPos.x, hudPos.y, 0.2, 0.1, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})
                directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, type, ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, "Press 'J' to add to builder", ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                if util.is_key_down(0x4A) then
                    add_entity_to_list(builder.entitiesMenuList, entity, "Pre-existing Vehicle")
                end
            end
        end)
        if highlightedHandle ~= nil then
            if scriptSettings.showOverlay and menu.is_open() or FREE_EDIT then
                local pos = ENTITY.GET_ENTITY_COORDS(highlightedHandle)
                local hudPos = get_screen_coords(pos)

                local entData = builder.entities[highlightedHandle]

                local is_base = builder.base.handle == highlightedHandle
                directx.draw_rect(hudPos.x, hudPos.y, 0.2, 0.1, { r = 0.0, g = 0.0, b = 0.0, a = 0.3})


                if is_base then
                    local vehicleCount, objectCount, pedCount = compute_builder_stats()
                    local authorText = builder.author and ("Created by " .. builder.author) or "Unknown creator"
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, builder.name or "Unnamed Custom Vehicle", ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, authorText, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, string.format("%d vehicles, %d objects, %d peds attached", vehicleCount, objectCount, pedCount), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                else
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.01, (entData.name or "Unnamed entity") .. " (" .. entData.model .. ")", ALIGN_TOP_LEFT, 0.6, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.03, entData.type, ALIGN_TOP_LEFT, 0.5, { r = 0.9, g = 0.9, b = 0.9, a = 1.0})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.06, string.format("Offset   %6.1f  %6.1f  %6.1f", entData.pos.x, entData.pos.y, entData.pos.z), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                    directx.draw_text(hudPos.x + 0.01, hudPos.y + 0.075, string.format("Angles  %6.1f  %6.1f  %6.1f", entData.rot.x, entData.rot.y, entData.rot.z), ALIGN_TOP_LEFT, 0.45, { r = 0.9, g = 0.9, b = 0.9, a = 0.8})
                end
            end

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
        end
    end

    util.yield()
end