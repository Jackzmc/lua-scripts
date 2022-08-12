-- Actions
-- Created By Jackz
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "actions"
local VERSION = "1.10.3"
local ANIMATIONS_DATA_FILE = filesystem.resources_dir() .. "/jackz_actions/animations.txt"
local ANIMATIONS_DATA_FILE_VERSION = "1.0"
local SPECIAL_ANIMATIONS_DATA_FILE_VERSION = "1.0.0" -- target version of actions_data

--#P:MANUAL_ONLY
-- Check for updates & auto-update:
-- Remove these lines if you want to disable update-checks & auto-updates: (7-54)
async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        -- Remove this block (lines 15-32) to disable auto updates
        async_http.init("jackz.me", "/stand/get-lua.php?script=" .. SCRIPT .. "&source=manual", function(result)
            local file = io.open(filesystem.scripts_dir() .. "/" .. SCRIPT_RELPATH, "w")
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
--#P:END

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
local wasUpdated = false
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
        async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT .. "&since=" .. VERSION, function(result)
            util.toast("Changelog for " .. SCRIPT .. " version " .. VERSION .. ":\n" .. result)
        end, function() util.log(SCRIPT ..": Could not get changelog") end)
        async_http.dispatch()
        wasUpdated = true
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

function show_busyspinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end

util.require_natives(1627063482)

local metaList = menu.list(menu.my_root(), "Script Meta")
menu.divider(metaList, SCRIPT .. " V" .. VERSION)
menu.hyperlink(metaList, "View guilded post", "https://www.guilded.gg/stand/groups/x3ZgB10D/channels/7430c963-e9ee-40e3-ab20-190b8e4a4752/docs/265763")
menu.hyperlink(metaList, "View full changelog", "https://jackz.me/stand/changelog?html=1&script=" .. SCRIPT)
menu.hyperlink(metaList, "Jackz's Guilded", "https://www.guilded.gg/i/k8bMDR7E?cid=918b2f61-989c-41c4-ba35-8fd0e289c35d&intent=chat", "Get help or suggest additions to my scripts")
menu.divider(metaList, "-- Credits --")
menu.hyperlink(metaList, "dpemotes", "https://github.com/andristum/dpemotes/", "For the special animations section, code was modified from repository")

-- Iterates in consistent order a Key/Value
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
require('resources/jackz_actions/actions_data')
if ANIMATION_DATA_VERSION ~= SPECIAL_ANIMATIONS_DATA_FILE_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
        download_resources_update("jackz_actions/actions_data.min.lua", "jackz_actions/actions_data.lua")
        util.toast("Restart script to use updated resource file")
    else
        util.toast("jackz_actions: Warn: Outdated or missing actions_data. Version: " .. (ANIMATION_DATA_VERSION or "<missing>"))
        util.stop_script()
    end
end

-- Messy Globals
local scenarioCount = 0

local clearActionImmediately = true
local favorites = {}
local favoritesActions = {}
local recents = {}
local animFlags = AnimationFlags.ANIM_FLAG_REPEAT | AnimationFlags.ANIM_FLAG_ENABLE_PLAYER_CONTROL
local allowControl = true
local affectType = 0
-----------------------
-- SCENARIOS
----------------------

menu.action(menu.my_root(), "Stop All Actions", {"stopself"}, "Stops the current scenario or animation", function(v)
    clear_anim_props()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    if clearActionImmediately then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    else
        TASK.CLEAR_PED_TASKS(ped)
    end
    if affectType > 0 then
        local peds = entities.get_all_peds_as_handles()
        for _, npc in ipairs(peds) do
            if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(npc)
                if clearActionImmediately then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                else
                    TASK.CLEAR_PED_TASKS(npc)
                end
            end
        end
    end
end)
menu.toggle(menu.my_root(), "Clear Action Immediately", {"clearimmediately"}, "If enabled, will immediately stop the animation / scenario that is playing when activating a new one. If false, you will transition smoothly to the next action.", function(on)
    lclearActionImmediately = on
end, clearActionImmediately)
menu.list_select(menu.my_root(), "Action Targets", {"actiontarget"}, "The entities that will play this action.\n0 = Only yourself\n1 = Only NPCs\n2 = Both you and NPCS", { { "Only yourself" }, { "Only NPCs" }, {"Both"} }, 1, function(index)
    affectType = index - 1
end)
function onControllablePress(value)
    if value then
        animFlags = AnimationFlags.ANIM_FLAG_REPEAT | AnimationFlags.ANIM_FLAG_ENABLE_PLAYER_CONTROL
    else
        animFlags = AnimationFlags.ANIM_FLAG_REPEAT
    end
end
function generateAnimationAction(key, data)
    return function()
        util.toast("Playing anim: " .. data[3] or key)
        util.log(string.format("dict=%s anim=%s name=%s", data[1], data[2], data[3]))
        play_animation(data[1], data[2], false, data)
    end
end

menu.divider(menu.my_root(), "Stuff")
local specialAnimationsMenu = menu.list(menu.my_root(), "Special Animations", {}, "Special animations that can use props")
menu.toggle(specialAnimationsMenu, "Controllable", {"animationcontrollable"}, "Should the animation allow player control?", onControllablePress, allowControl)
local animationsMenu = menu.list(menu.my_root(), "Animations", {}, "List of animations you can play")
menu.toggle(animationsMenu, "Controllable", {"animationcontrollable"}, "Should the animation allow player control?", onControllablePress, allowControl)


for category, rows in pairsByKeys(SPECIAL_ANIMATIONS) do
    local catmenu = menu.list(specialAnimationsMenu, category, {})
    for key, data in pairsByKeys(rows) do
        menu.action(
            catmenu,
            data[3] or key,
            {"playanim"..key},
            string.format("%s %s\nPlay this animation\nAnimation Id: %s", data[1], data[2], key),
            generateAnimationAction(key, data)
        )
    end
end


-----------------------
-- ANIMATIONS
----------------------
local animLoaded = false
local animAttachments = {}
function clear_anim_props()
    for ent, shouldDelete in pairs(animAttachments) do
        if shouldDelete then
            entities.delete(ent)
        else
            ENTITY.DETACH_ENTITY(ent, false)
        end
    end
end
function delete_anim_props()
    for ent, _ in pairs(animAttachments) do
        entities.delete(ent)
    end
end

local animMenuData = {}
local resultMenus = {}
local cloudFavoritesMenu = menu.list(animationsMenu, "Cloud Favorites", {}, "View categorized saved favorites from other users, or store your own.")
local favoritesMenu = menu.list(animationsMenu, "Favorites", {}, "List of all your favorited animations. Hold SHIFT to add or remove from favorites.")
local cloudFavoritesUploadMenu = menu.list(cloudFavoritesMenu, "Upload", {}, "Add your own cloud animation favorites. BETA.")
    local cloudUploadFromFavorites = menu.list(cloudFavoritesUploadMenu, "From Favorites", {}, "Browse your favorite played animations to upload them", function() populate_cloud_list(true) end)
    local cloudUploadFromRecent = menu.list(cloudFavoritesUploadMenu, "From Recent", {}, "Browse your recently played animations to upload them",  function() populate_cloud_list(false) end)
local cloudFavoritesBrowseMenu = menu.list(cloudFavoritesMenu, "Browse", {}, "Browse all uploaded cloud animation favorites")

local cloudUsers = {} -- Record<user, { menu, categories = Record<dictionary, { menu, animations = {} }>}
local cloud_loading = false
function cloudvehicle_fetch_error(code)
    return function()
        cloud_loading = false
        util.toast("An error occurred fetching cloud data. Code: " .. code, TOAST_ALL)
        HUD.BUSYSPINNER_OFF()
    end
end
local cloud_list = {}
function upload_animation(group, animation, alias)
    show_busyspinner("Uploading animation")
    async_http.init('jackz.me',
        string.format(
            '/stand/cloud/actions/manage?scname=%s&hash=%d&alias=%s&dict=%s&anim=%s',
            SOCIALCLUB._SC_GET_NICKNAME(),
            menu.get_activation_key_hash(),
            alias or '',
            group,
            animation
        ),
        function(body)
            if body == "OK" then
                util.toast("Upload successful for " .. group .. "/" .. animation)
            elseif body == "Conflict" then
                util.toast("Animation already uploaded")
            else
                util.toast("Upload failed for " .. group .. "/" .. animation .. ": " .. body)
            end
            HUD.BUSYSPINNER_OFF()
        end
    )
    async_http.set_post('text/plain', '')
    async_http.dispatch()
end
function populate_cloud_list(useFavorites)
    local listMenu = useFavorites and cloudUploadFromFavorites or cloudUploadFromRecent
    local tuple = useFavorites and favorites or recents
    for _, m in ipairs(cloud_list) do
        menu.delete(m)
    end
    cloud_list = {}
    for _, favorite in ipairs(tuple) do
        local name = favorite[2]
        -- if favorite[3] then
        --     name = favorite[3] .. " (" .. favorite[2] .. ")"
        -- end
        local action = menu.action(listMenu, name, {}, "Upload the " .. favorite[2] .. " from group " .. favorite[1] .. " to the cloud", function(v)
            upload_animation(favorite[1], favorite[2], nil)
        end)
        table.insert(cloud_list, action)
    end
end
function populate_user_dict(user, dictionary)
    show_busyspinner("Fetching animations for " .. dictionary)
    while cloud_loading do
        util.yield()
    end
    cloud_loading = true
    async_http.init('jackz.me', '/stand/cloud/actions/list?method=actions&scname=' .. user .. "&dict=" .. dictionary, function(body)
        cloud_loading = false
        if body:sub(1, 1) == "<" then
            util.toast("Ratelimited, try again in a few seconds.")
            menu.divider(cloudUsers[user].categories[dictionary].menu, "Ratelimited, try again in a few seconds")
            return
        end
        for _, animation in ipairs(cloudUsers[user].categories[dictionary].animations) do
            pcall(menu.delete, animation)
        end
        cloudUsers[user].categories[dictionary].animations = {}
        local count = 0
        for animation in string.gmatch(body, "[^\r\n]+") do
            count = count + 1
            local action = menu.action(cloudUsers[user].categories[dictionary].menu, animation, {}, dictionary .. " " .. animation, function(_)
                play_animation(dictionary, animation)
            end)
            table.insert(cloudUsers[user].categories[dictionary].animations, action)
        end
        menu.set_menu_name(cloudUsers[user].categories[dictionary].menu, dictionary .. " (" .. count .. ")")
        HUD.BUSYSPINNER_OFF()
    end, cloudvehicle_fetch_error("FETCH_USER_ANIMS"))
    async_http.dispatch()
end
menu.on_focus(cloudFavoritesBrowseMenu, function()
    show_busyspinner("Fetching users")
    while cloud_loading do
        util.yield()
    end
    cloud_loading = true
    async_http.init('jackz.me', '/stand/cloud/actions/list?method=users', function(body)
        cloud_loading = false
        if body:sub(1, 1) == "<" then
            cloudvehicle_fetch_error("RATELIMITED")
            return
        end
        for user, udata in pairs(cloudUsers) do
            pcall(menu.delete, udata.menu)
            for dictionary, cdata in pairs(udata.categories) do
                pcall(menu.delete, cdata.menu)
                for i, animation in ipairs(cdata.animations) do
                    pcall(menu.delete, animation)
                    cdata.animations[i] = nil
                end
                udata.categories[dictionary] = nil
            end
            cloudUsers.menu[user] = nil
        end
        for user in string.gmatch(body, "[^\r\n]+") do
            local userMenu = menu.list(cloudFavoritesBrowseMenu, user, {}, "All action categories favorited by " .. user)
            cloudUsers[user] = {
                menu = userMenu,
                categories = {}
            }
            -- TODO: Move from on_focus to on click
            menu.on_focus(userMenu, function(_)
                show_busyspinner("Fetching dictionaries for " .. user)
                while cloud_loading do
                    util.yield()
                end
                cloud_loading = true
                async_http.init('jackz.me', '/stand/actions/list?method=dicts&scname=' .. user, function(body)
                    cloud_loading = false
                    if body:sub(1, 1) == "<" then
                        cloudvehicle_fetch_error("RATELIMITED")
                        return
                    end
                    for dictionary, cdata in pairs(cloudUsers[user].categories) do
                        pcall(menu.delete, cdata.menu)
                        for animation in ipairs(cdata.animations) do
                            pcall(menu.delete, animation)
                        end
                    end
                    cloudUsers[user].categories = {}
                    local count = 0
                    for dictionary in string.gmatch(body, "[^\r\n]+") do
                        count = count + 1
                        local dictMenu = menu.list(userMenu, dictionary, {}, "All actions in " .. dictionary .. " favorited by " .. user, function() populate_user_dict(user, dictionary) end)
                        cloudUsers[user].categories[dictionary] = {
                            menu = dictMenu,
                            animations = {}
                        }
                    end
                    menu.set_menu_name(userMenu, user .. " (" .. count .. ")")
                    HUD.BUSYSPINNER_OFF()
                end, cloudvehicle_fetch_error("FETCH_USER_CATEGORIES"))
                async_http.dispatch()
            end)
        end
        HUD.BUSYSPINNER_OFF()
    end, cloudvehicle_fetch_error("FETCH_USERS"))
    async_http.dispatch()
end)
local recentsMenu = menu.list(animationsMenu, "Recents", {}, "List of all your recently played animations")
menu.divider(animationsMenu, "Raw Animations")
local searchMenu = menu.list(animationsMenu, "Search", {}, "Search for animation groups")
menu.action(searchMenu, "Search Animation Groups", {"searchanim"}, "Searches all animation groups for the inputted text", function()
    menu.show_command_box("searchanim ")
end, function(args)
    -- Delete existing results
    for _, m in ipairs(resultMenus) do
        pcall(menu.delete, m)
    end
    resultMenus = {}
    -- Find all possible groups
    local results = {}
    -- loop ANIMATIONS by heading then subheading then insert based on result
    if not filesystem.exists(ANIMATIONS_DATA_FILE) then
        download_animation_data()
    end
    -- Parse the file
    local isHeaderRead = false
    -- Possibly recurse down categories splitting on _ and @
    for line in io.lines(ANIMATIONS_DATA_FILE) do
        if isHeaderRead then
            
            local i, j = line:find(args)
            if i then
                chunks = {} -- [ category, anim ]
                for substring in string.gmatch(line, "%S+") do
                    table.insert(chunks, substring)
                end
                -- Add the distance:
                chunks[3] = j - i
                table.insert(results, chunks)
            end
            -- TODO: Add back organization to list
        else
            local version = line:sub(2)
            if version ~= ANIMATIONS_DATA_FILE_VERSION then
                if SCRIPT_SOURCE == "MANUAL" then
                    util.toast("Animation data out of date, updating...")
                    download_animation_data()
                else
                    util.toast("animations.txt out of date. Please report this.")
                end
            end
            isHeaderRead = true
        end
    end
    -- Sort by distance
    table.sort(results, function(a, b) return a[3] > b[3] end)
    -- Messy, but no way to call a list group, so recreate all animations in a sublist:
    for i = 1, 201 do
        if results[i] then
            -- local m = menu.list(searchMenu, group, {}, "All animations for " .. group)
           local m = menu.action(searchMenu, results[i][2], {"animate" .. results[i][1] .. " " .. results[i][2]}, "Plays the " .. results[i][2] .. " animation from group " .. results[i][1], function(v)
                play_animation(results[i][1], results[i][2], false)
            end)
            table.insert(resultMenus, m)
        end
    end
end)
local browseMenu = menu.list(animationsMenu, "Browse Animations", {}, "WARNING: Will cause a freeze when exiting, stand does not like unloading 15,000 animations. Use search if your pc cannot handle.", function() setup_animation_list() end)
menu.on_focus(browseMenu, function()
    if animLoaded then
        util.toast("WARN: Unloading animation browse list, prepare for lag.")
        util.yield(100)
        destroy_animations_data()
    end
end)
show_busyspinner("Loading Menus...")


local scenariosMenu = menu.list(menu.my_root(), "Scenarios", {}, "List of scenarios you can play\nSome scenarios only work on certain genders, example AA Coffee only works on male peds.")
for group, scenarios in pairs(SCENARIOS) do
    local submenu = menu.list(scenariosMenu, group, {}, "All " .. group .. " scenarios")
    for _, scenario in ipairs(scenarios) do
        scenarioCount = scenarioCount + 1
        menu.action(submenu, scenario[2], {"scenario"}, "Plays the " .. scenario[2] .. " scenario", function(v)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            
            -- Play scenario on all npcs if enabled:
            if affectType > 0 then
                local peds = entities.get_all_peds_as_handles()
                for _, npc in ipairs(peds) do
                    if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(npc)
                        if clearActionImmediately then
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                        end
                        TASK.TASK_START_SCENARIO_IN_PLACE(npc, scenario[1], 0, true);
                    end
                end
            end
            -- Play scenario on self if enabled:
            if affectType == 0 or affectType == 2 then
                if clearActionImmediately then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                end
                TASK.TASK_START_SCENARIO_IN_PLACE(ped, scenario[1], 0, true);
            end
        end)
    end
end
HUD.BUSYSPINNER_OFF()

local selfSpeechPed = {
    entity = 0,
    lastUsed = os.millis(),
    model = util.joaat("a_f_m_bevhills_01")
}
-- Messy globals again
local speechParam = "Speech_Params_Force"
local activeSpeech = "GENERIC_HI"
local ambientSpeechDuration = 1
local speechDelay = 1000
local repeatEnabled = false
local ambientSpeechMenu = menu.list(menu.my_root(), "Ambient Speech", {}, "Allow you to play ambient speeches on yourself or other peds")
local speechMenu = menu.list(ambientSpeechMenu, "Speech Lines", {"speechlines"}, "List of Speeches peds can say.\nSome lines may not work on some NPCs")
for _, pair in ipairs(SPEECHES) do
    local desc = pair[2]
    if pair[3] then
        desc = desc .. "\n" .. pair[3]
    end
    menu.action(speechMenu, pair[1], {"speak" .. string.lower(pair[1])}, desc, function(a)
        -- Play single duration for peds
        if affectType > 0 then
            if ambientSpeechDuration > 0 then
                for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                    if not PED.IS_PED_A_PLAYER(ped) then
                        if ambientSpeechDuration > 1 then
                            util.create_thread(function()
                                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                                for x = 1,ambientSpeechDuration do
                                    AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, pair[2], speechParam)
                                    util.yield(speechDelay)
                                end
                            end)
                        else
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, pair[2], speechParam)
                        end
                    end
                end
            else
                
            end
        end
        -- Play single duration for self
        if affectType == 0 or affectType == 2 then
            if selfSpeechPed.entity == 0 then
                create_self_speech_ped()
            end
            util.create_thread(function()
                for _ = 1,ambientSpeechDuration do
                    AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(selfSpeechPed.entity, pair[2], speechParam)
                    util.yield(speechDelay)
                end
            end)
            selfSpeechPed.lastUsed = os.millis()
            --TODO: implement
        end
        -- Play repeated for self or peds
        if ambientSpeechDuration == 0 then
            activeSpeech = pair[2]
            if not repeatEnabled then
                repeatEnabled = true
                if selfSpeechPed.entity == 0 and affectType ~= 1 then
                    create_self_speech_ped()
                end
                util.create_tick_handler(function(a)
                    if affectType > 0 then
                        for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, activeSpeech, speechParam)
                        end
                    end
                    if selfSpeechPed.entity > 0 and affectType == 0 or affectType == 2 then
                        AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(selfSpeechPed.entity, activeSpeech, speechParam)
                        selfSpeechPed.lastUsed = os.millis()
                    end
                    util.yield(speechDelay)
                    return repeatEnabled
                end)
            end
        end
    end)
end
local speechType = menu.list(ambientSpeechMenu, "Speech Method", {"speechmethods", "How is the line said"})
for _, pair in ipairs(SPEECH_PARAMS) do
    menu.action(speechType, pair[1], {}, pair[2], function(a)
        speechParam = pair[2]
    end)
end
local selfModelVoice = menu.list(ambientSpeechMenu, "Self Model Voice", {"selfvoice", "What model to use when playing a self-ambient speech\nOnly used if your current model is MP (Fe)male"})
menu.divider(selfModelVoice, "Female Peds")
for _, model in ipairs(VOICE_MODELS.FEMALE) do
    menu.action(selfModelVoice, model, {"voice" .. model}, "Uses \"" .. model .. "\" model as your ambient speech voice", function(a)
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            entities.delete(selfSpeechPed.entity)
            selfSpeechPed.entity = 0
        end
        selfSpeechPed.model = util.joaat(model)
    end)
end
menu.divider(selfModelVoice, "Male Peds")
for _, model in ipairs(VOICE_MODELS.MALE) do
    menu.action(selfModelVoice, model, {"voice" .. model}, "Uses \"" .. model .. "\" model as your ambient speech voice", function(a)
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            entities.delete(selfSpeechPed.entity)
            selfSpeechPed.entity = 0
        end
        selfSpeechPed.model = util.joaat(model)
    end)
end

menu.slider(ambientSpeechMenu, "Duration", {"speechduration"}, "How many times should the speech be played?\n 0 to play forever, use 'Stop Active Speech' to end.", 0, 100, ambientSpeechDuration, 1, function(value)
    ambientSpeechDuration = value
end)
menu.slider(ambientSpeechMenu, "Speech Interval", {"speechinterval"}, "How many milliseconds per repeat of line?", 100, 30000, speechDelay, 100, function(value)
    speechDelay = value
end)
menu.action(ambientSpeechMenu, "Stop Active Speech", {"stopspeeches"}, "Stops any active ambient speeches", function(a)
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        AUDIO.STOP_CURRENT_PLAYING_AMBIENT_SPEECH(ped)
    end
    -- reuse code cause why not its 11:57 pm I don't care now
    if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
        entities.delete(selfSpeechPed.entity)
    end
    selfSpeechPed.entity = 0
    repeatEnabled = false
end)

function create_self_speech_ped()
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local model = ENTITY.GET_ENTITY_MODEL(my_ped)
    -- Freemode models cant do ambient speeches, so we need to change the model to something else:
    if model == util.joaat("mp_f_freemode_01") or model == util.joaat("mp_m_freemode_01") then
        model = selfSpeechPed.model
    end
    -- Load model in
    STREAMING.REQUEST_MODEL(model)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
    -- Finally, spawn it & attach
    local pos = ENTITY.GET_ENTITY_COORDS(my_ped)
    local ped = entities.create_ped(1, model, pos, 0)
    ENTITY._ATTACH_ENTITY_BONE_TO_ENTITY_BONE(ped, my_ped, 0, 0, 0, 0)
    ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
    NETWORK._NETWORK_SET_ENTITY_INVISIBLE_TO_NETWORK(ped, true)
    selfSpeechPed.entity = ped
    selfSpeechPed.lastUsed = os.millis()
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
end
-----------------------
-- Animation Functions
----------------------
-- Maybe smart deletion but eh
function populate_favorites()
    for _, action in ipairs(favoritesActions) do
        menu.delete(action)
    end
    favoritesActions = {}
    for _, favorite in ipairs(favorites) do
        local name = favorite[2]
        if favorite[3] then
            name = favorite[3] .. " (" .. favorite[2] .. ")"
        end
        local a = menu.action(favoritesMenu, name, {}, "Plays " .. favorite[2] .. " from group " .. favorite[1], function(v)
            play_animation(favorite[1], favorite[2], false)
        end)
        table.insert(favoritesActions, a)
    end
end

function is_anim_in_recent(group, anim)
    for _, recent in ipairs(recents) do
        if recent[1] == group and recent[2] == anim then
            return true
        end
    end
    return false
end

function add_anim_to_recent(group, anim)
    if #recents >= 20 then
        menu.delete(recents[1][3])
        table.remove(recents, 1)
    end
    local action = menu.action(recentsMenu, anim, {"animate" .. group .. " " .. anim}, "Plays the " .. anim .. " animation from group " .. group, function(v)
        play_animation(group, anim, true)
    end)
    table.insert(recents, { group, anim, action })
end
function download_animation_data()
    local loading = true
    show_busyspinner("Downloading animation data")
    async_http.init("jackz.me", "/stand/resources/jackz_actions/animations.txt", function(result)
        local file = io.open(ANIMATIONS_DATA_FILE, "w")
        file:write(result:gsub("\r", ""))
        file:close()
        util.log(SCRIPT .. ": Downloaded resource file successfully")
        HUD.BUSYSPINNER_OFF()
        loading = false
    end, function()
        util.toast(SCRIPT .. ": Failed to automatically download animations data file. Please download latest file manually.")
        util.stop_script()
        loading = false
    end)
    async_http.dispatch()
    while loading do
        util.yield()
    end
    HUD.BUSYSPINNER_OFF()
end
function destroy_animations_data()
    for category, data in pairs(animMenuData) do
        pcall(menu.delete, data.list)
    end
    animMenuData = {}
    animLoaded = false
end
function setup_category_animations(category)
    animMenuData[category].menus = {}
    for _, animation in ipairs(animMenuData[category].animations) do
        local action = menu.action(animMenuData[category].list, animation, {"animate" .. category .. " " .. animation}, "Plays the " .. animation .. " animation from group " .. category, function(v)
            play_animation(category, animation, false)
        end)
        table.insert(animMenuData[category].menus, action)
    end
end
function setup_animation_list()
    if animLoaded then
        return
    end
    -- Download animation file if does not exist
    if not filesystem.exists(ANIMATIONS_DATA_FILE) then
        download_animation_data()
    end
    -- Parse the file
    local isHeaderRead = false
    -- Possibly recurse down categories splitting on _ and @
    for line in io.lines(ANIMATIONS_DATA_FILE) do
        if isHeaderRead then
            chunks = {} -- [ category, anim ]
            for substring in string.gmatch(line, "%S+") do
                table.insert(chunks, substring)
            end
            if #chunks == 2 then
                local category = chunks[1]
                if animMenuData[category] == nil then
                    animMenuData[category] = {
                        animations = {},
                    }
                    local list = menu.list(browseMenu, category, {}, "", function() setup_category_animations(category) end
                    , function()
                        if animMenuData[category].menus then
                            for _, m in ipairs(animMenuData[category].menus) do
                                pcall(menu.delete, m)
                            end
                            animMenuData[category].menus = nil
                        end
                    end)
                    animMenuData[category].list = list
                end
                table.insert(animMenuData[chunks[1]].animations, chunks[2])
            end
        else
            local version = line:sub(2)
            if version ~= ANIMATIONS_DATA_FILE_VERSION then
                util.toast("Animation data out of date, updating...")
                download_animation_data()
            end
            isHeaderRead = true
        end
    end
    animLoaded = true
end

function play_animation(group, anim, doNotAddRecent, data)
    local flags = animFlags -- Keep legacy animation flags
    local duration = -1
    if data ~= nil then
        flags = 0
        if data.AnimationOptions ~= nil then
            if data.AnimationOptions.Loop then
                flags = flags | AnimationFlags.ANIM_FLAG_REPEAT
            end
            if data.AnimationOptions.Controllable then
                flags = flags | AnimationFlags.ANIM_FLAG_ENABLE_PLAYER_CONTROL
            end
            if data.AnimationOptions.EmoteDuration then
                duration = data.AnimationOptions.EmoteDuration
            end
        end
    end
    if PAD.IS_CONTROL_PRESSED(2, 209) then
        for i, favorite in ipairs(favorites) do
            if favorite[1] == group and favorite[2] == anim then
                table.remove(favorites, i)
                populate_favorites()
                save_favorites()
                util.toast("Removed " .. group .. "\n" .. anim .. " from favorites")
                return
            end
        end
        table.insert(favorites, { group, anim })
        populate_favorites()
        save_favorites()
        util.toast("Added " .. group .. "\n" .. anim .. " to favorites")
    else
        local props = nil
        if data.AnimationOptions.Props then
            props = data.AnimationOptions.Props
        end

        clear_anim_props()
        STREAMING.REQUEST_ANIM_DICT(group)
        while not STREAMING.HAS_ANIM_DICT_LOADED(group) do
            util.yield(100)
        end
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        

        if not is_anim_in_recent(group, anim) and not doNotAddRecent then
            add_anim_to_recent(group, anim)
        end

        -- Play animation on all npcs if enabled:
        if affectType > 0 then
            local peds = entities.get_all_peds_as_handles()
            for _, npc in ipairs(peds) do
                if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                    _play_animation(npc, group, anim, flags, duration, props)
                end
            end
        end
        -- Play animation on self if enabled:
        if affectType == 0 or affectType == 2 then
            _play_animation(ped, group, anim, flags, duration, props)
        end
        STREAMING.REMOVE_ANIM_DICT(group)
    end
end

function _play_animation(ped, group, animation, flags, duration, props)
    if clearActionImmediately then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    end
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    if props ~= nil then
        for _, propData in ipairs(props) do
            local boneIndex = PED.GET_PED_BONE_INDEX(ped, propData.Bone)
            local hash = util.joaat(propData.Prop)
            STREAMING.REQUEST_MODEL(hash)
            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end
            local object = entities.create_object(hash, pos)
            animAttachments[object] = propData.DeleteOnEnd ~= nil
            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                object, ped, boneIndex,
                propData.Placement[1] or 0.0,
                propData.Placement[2] or 0.0,
                propData.Placement[3] or 0.0,
                propData.Placement[4] or 0.0,
                propData.Placement[5] or 0.0,
                propData.Placement[6] or 0.0,
                false,
                true,
                false,
                true,
                1,
                true
            )
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        end
    end
    TASK.TASK_PLAY_ANIM(ped, group, animation, 8.0, 8.0, duration, flags, 0.0, false, false, false)
end

------------------------------
-- Loading & Saving Favorites
--------------------------------
local path = filesystem.stand_dir() .. "/Favorite Animations.txt"
if filesystem.exists(path) then
    local headerRead = false
    for line in io.lines(path) do
        if headerRead then
            chunks = {}
            for substring in string.gmatch(line, "%S+") do
                table.insert(chunks, substring)
            end
            if #chunks == 2 or #chunks == 3 then
                table.insert(favorites, chunks)
            end
        else
            headerRead = true
        end
    end
    populate_favorites()
end
function save_favorites()
    local file = io.open(path, "w")
    file:write("category\t\tanimation name\t\talias (no spaces)\n")
    for _, favorite in ipairs(favorites) do
        if favorite[3] then
            file:write(string.format("%s %s %s\n", favorite[1], favorite[2], favorite[3]))
        else
            file:write(string.format("%s %s\n", favorite[1], favorite[2]))
        end
    end
    file:close()
end
-----------------------
util.toast("Hold LEFT SHIFT on an animation to add or remove it from your favorites.", 2)
util.toast(string.format("Ped Actions Script %s by Jackz.", VERSION), 2)

util.on_stop(function(_)
    if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
        entities.delete(selfSpeechPed.entity)
    end
    ANIMATIONS = {}
    if animLoaded then
        util.toast("WARN: Unloading animation browse list, prepare for lag.")
        destroy_animations_data()
    end
    delete_anim_props()
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    -- TODO: Check if playing animation from this script 
    if not PED.IS_PED_IN_ANY_VEHICLE(my_ped) then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(my_ped)
    end
end)

while true do
    if selfSpeechPed.entity > 0 and os.millis() - selfSpeechPed.lastUsed > 20 then
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            entities.delete(selfSpeechPed.entity)
        end
        selfSpeechPed.entity = 0
    end
	util.yield()
end