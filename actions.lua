-- Actions
-- Created By Jackz
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "actions"
VERSION = "1.11.8"
local ANIMATIONS_DATA_FILE = filesystem.resources_dir() .. "/jackz_actions/animations.txt"
local ANIMATIONS_DATA_FILE_VERSION = "1.0"
local SPECIAL_ANIMATIONS_DATA_FILE_VERSION = "1.1.0" -- target version of actions_data
local LANG_TARGET_VERSION = "1.4.3" -- Target version of translations.lua lib

--#P:DEBUG_ONLY
require('templates/log')
require('templates/common')
--#P:END

--#P:TEMPLATE("log")
--#P:TEMPLATE("_SOURCE")
--#P:TEMPLATE("common")


util.require_natives(1627063482)

local _lang = try_require("translations")
local updateTranslations = false
if _lang == nil or _lang.menus.list_select == nil or _lang.VERSION ~= LANG_TARGET_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
      util.toast("Outdated translations library, downloading update...")
      os.remove(filesystem.scripts_dir() .. "/lib/translations.lua")
      local updating = true
      package.loaded["translations"] = nil
      _G["translations"] = nil
      show_busyspinner("Updating translations library")
      local function stop_update()
        updating = false
        HUD.BUSYSPINNER_OFF()
      end
      download_lib_update("translations.lua", stop_update, stop_update)
      while updating do
        util.yield(10)
      end
      _lang = require("translations")
    else
      util.toast("Outdated lib: 'translations', please notify jackz to update the repo")
    end
    updateTranslations = true
end
_lang.set_autodownload_uri("jackz.me", "/stand/git/" .. (SCRIPT_BRANCH or "release")  .. "/resources/Translations/")
_lang.load_translation_file(SCRIPT)
if updateTranslations then
    _lang.update_translation_file(SCRIPT)
end

if SCRIPT_META_LIST then
    menu.divider(SCRIPT_META_LIST, "-- Credits --")
    menu.hyperlink(SCRIPT_META_LIST, "dpemotes", "https://github.com/andristum/dpemotes/", "For the special animations section, code was modified from repository")
    menu.divider(SCRIPT_META_LIST, "Zero - Chinese Translation")
end

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
 local hasSpecialAnimations, err = pcall(require, 'resources/jackz_actions/actions_data')
 if not hasSpecialAnimations then
    util.log("Failed to read actions_data:\n" .. err)
    hasSpecialAnimations = pcall(require, 'jackz_actions/actions_data')
    if not hasSpecialAnimations then
        util.log("Failed to read actions_data(2):\n" .. err)
    end
 end
 if ANIMATION_DATA_VERSION == nil or ANIMATION_DATA_VERSION ~= SPECIAL_ANIMATIONS_DATA_FILE_VERSION then
    if SCRIPT_SOURCE == "MANUAL" then
        download_resources_update("jackz_actions/actions_data.min.lua", "jackz_actions/actions_data.lua")
        util.toast("Restart script to use updated resource file")
    else
        util.log("jackz_actions: Warn: Outdated or missing optional actions_data. Version: " .. (ANIMATION_DATA_VERSION or "<missing>"))
    end
end

if AnimationFlags == nil then
    AnimationFlags = {
        ANIM_FLAG_NORMAL = 0,
        ANIM_FLAG_REPEAT = 1,
        ANIM_FLAG_STOP_LAST_FRAME = 2,
        ANIM_FLAG_UPPERBODY = 16,
        ANIM_FLAG_ENABLE_PLAYER_CONTROL = 32,
        ANIM_FLAG_CANCELABLE = 120
    }
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
local animLoaded = false
local animAttachments = {}
function is_anim_in_recent(group, anim)
    for _, recent in ipairs(recents) do
        if recent[1] == group and recent[2] == anim then
            return true
        end
    end
    return false
end

local recentsMenu
function add_anim_to_recent(group, anim)
    if #recents >= 20 then
        menu.delete(recents[1][3])
        table.remove(recents, 1)
    end
    local action = menu.action(recentsMenu, anim, {"animate" .. group .. " " .. anim}, _lang.format("PLAY_ANIM_DESC", anim, group), function(v)
        play_animation(group, anim, true)
    end)
    table.insert(recents, { group, anim, action })
end
function download_animation_data()
    local loading = true
    show_busyspinner(_lang.format("ANIM_DATA_DOWNLOADING"))
    async_http.init("jackz.me", "/stand/resources/jackz_actions/animations.txt", function(result)
        local file = io.open(ANIMATIONS_DATA_FILE, "w")
        file:write(result:gsub("\r", ""))
        file:close()
        util.log(SCRIPT .. ": " .. _lang.format("ANIM_DATA_SUCCESS"))
        HUD.BUSYSPINNER_OFF()
        loading = false
    end, function()
        util.log(SCRIPT .. ": " .. _lang.format("ANIM_DATA_ERROR"))
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
    menu.collect_garbage()
end
function setup_category_animations(category)
    animMenuData[category].menus = {}
    for _, animation in ipairs(animMenuData[category].animations) do
        local action = menu.action(animMenuData[category].list, animation, {"animate" .. category .. " " .. animation}, _lang.format("PLAY_ANIM_DESC", animation, category), function()
            play_animation(category, animation, false)
        end)
        table.insert(animMenuData[category].menus, action)
    end
end

function play_animation(group, anim, doNotAddRecent, data, remove)
    local flags = animFlags -- Keep legacy animation flags
    local duration = -1
    local props
    if data ~= nil then
        flags = AnimationFlags.ANIM_FLAG_NORMAL
        if data.AnimationOptions ~= nil then
            if data.AnimationOptions.Loop then
                flags = flags | AnimationFlags.ANIM_FLAG_REPEAT
            end
            if data.AnimationOptions.Controllable then
                flags = flags | AnimationFlags.ANIM_FLAG_ENABLE_PLAYER_CONTROL | AnimationFlags.ANIM_FLAG_UPPERBODY
            end
            if data.AnimationOptions.EmoteDuration then
                duration = data.AnimationOptions.EmoteDuration
            end
        end
        if data.AnimationOptions and data.AnimationOptions.Props then
            props = data.AnimationOptions.Props
        end
    end
    if remove then
        for i, favorite in ipairs(favorites) do
            if favorite[1] == group and favorite[2] == anim then
                table.remove(favorites, i)
                populate_favorites()
                save_favorites()
                util.toast("Removed " .. group .. "\n" .. anim .. " from favorites")
                return
            end
        end
    end
    if PAD.IS_CONTROL_PRESSED(2, 209) then
        table.insert(favorites, { group, anim })
        populate_favorites()
        save_favorites()
        util.toast("Added " .. group .. "\n" .. anim .. " to favorites")
    else
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
    if props ~= nil then
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
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

-----------------------
-- SCENARIOS
----------------------

_lang.menus.action(menu.my_root(), "STOP_ALL_ACTIONS", {"stopself"}, function()
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
_lang.menus.toggle(menu.my_root(), "CLEAR_ACTION_IMMEDIATELY", {"clearimmediately"}, function(on)
    lclearActionImmediately = on
end, clearActionImmediately)
_lang.menus.list_select(menu.my_root(), "ACTION_TARGETS", {"actiontarget"}, { { _lang.format("ACTION_TARGETS_OPTION1") }, { _lang.format("ACTION_TARGETS_OPTION2") }, { _lang.format("ACTION_TARGETS_OPTION3")} }, 1, function(index)
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
        _lang.toast("PLAYING_ANIM", data[3] or key)
        util.log(string.format("dict=%s anim=%s name=%s", data[1], data[2], data[3]))
        play_animation(data[1], data[2], false, data)
    end
end

menu.divider(menu.my_root(), "")
local specialAnimationsMenu = _lang.menus.list(menu.my_root(), "SPECIAL_ANIMATIONS", {})
_lang.menus.toggle(specialAnimationsMenu, "CONTROLLABLE", {"animationcontrollable"}, onControllablePress, allowControl)
local animationsMenu = _lang.menus.list(menu.my_root(), "ANIMATIONS", {})
_lang.menus.toggle(animationsMenu, "CONTROLLABLE", {"animationcontrollable"}, onControllablePress, allowControl)

if hasSpecialAnimations then
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

else
    if SCRIPT_SOURCE == "REPO" then
        menu.readonly(specialAnimationsMenu, "Repo Unsupported", "The repository version lacks a required file for special animations. Please use the manual install from https://jackz.me/stand/get-latest-zip to use special animations, make sure to uncheck repo version.")
    end
    menu.readonly(specialAnimationsMenu, "Error", "Could not read file resources/jackz_actions/actions_data.lua, so this feature is unavailable.")
end

-----------------------
-- ANIMATIONS
----------------------

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
local cloudFavoritesMenu = _lang.menus.list(animationsMenu, "CLOUD_FAVORITES", {})
local favoritesMenu = _lang.menus.list(animationsMenu, "FAVORITES", {})
local cloudFavoritesUploadMenu = _lang.menus.list(cloudFavoritesMenu, "UPLOAD", {})
    local cloudUploadFromFavorites = _lang.menus.list(cloudFavoritesUploadMenu, "FROM_FAVORITES", {}, function() populate_cloud_list(true) end)
    local cloudUploadFromRecent = _lang.menus.list(cloudFavoritesUploadMenu, "FROM_RECENT", {}, function() populate_cloud_list(false) end)
local cloudFavoritesBrowseMenu = _lang.menus.list(cloudFavoritesMenu, "BROWSE", {})

local cloudUsers = {} -- Record<user, { menu, categories = Record<dictionary, { menu, animations = {} }>}
local cloud_loading = false
function cloudvehicle_fetch_error(code)
    return function()
        cloud_loading = false
        _lang.toast("CLOUD_ERROR", code)
        Log.error("cloud fetch error", code)
        HUD.BUSYSPINNER_OFF()
    end
end
local cloud_list = {}
function upload_animation(group, animation, alias)
    show_busyspinner(_lang.format("UPLOADING_ANIM"))
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
                _lang.toast("UPLOAD_SUCCESS", group, animation)
            elseif body == "Conflict" then
                _lang.toast("UPLOAD_CONFLICT", group, animation)
            else
                _lang.toast("UPLOAD_FAILED", group, animation, body)
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
        local action = menu.action(listMenu, name, {}, _lang.format("UPLOAD_FAVORITE_DESC", favorite[1], favorite[2]), function(v)
            upload_animation(favorite[1], favorite[2], nil)
        end)
        table.insert(cloud_list, action)
    end
end
function populate_user_dict(user, dictionary)
    show_busyspinner(_lang.format("FETCHING_ANIM", dictionary))
    while cloud_loading do
        util.yield()
    end
    cloud_loading = true
    async_http.init('jackz.me', '/stand/cloud/actions/list?method=actions&scname=' .. user .. "&dict=" .. dictionary, function(body)
        cloud_loading = false
        if body:sub(1, 1) == "<" then
            local msg = _lang.format("RATELIMIT")
            util.toast(msg)
            menu.divider(cloudUsers[user].categories[dictionary].menu, msg)
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
    show_busyspinner(_lang.format("FETCHING_USERS"))
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
            cloudUsers[user].menu = nil
        end
        for user in string.gmatch(body, "[^\r\n]+") do
            local userMenu = menu.list(cloudFavoritesBrowseMenu, user, {}, _lang.format("CLOUD_USER_FAVORITES_DESC", user))
            cloudUsers[user] = {
                menu = userMenu,
                categories = {}
            }
            -- TODO: Move from on_focus to on click
            menu.on_focus(userMenu, function(_)
                show_busyspinner(_lang.format("CLOUD_FETCHING_DICTS", user))
                while cloud_loading do
                    util.yield()
                end
                cloud_loading = true
                async_http.init('jackz.me', '/stand/cloud/actions/list?method=dicts&scname=' .. user, function(body)
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
                        local dictMenu = menu.list(userMenu, dictionary, {}, _lang.format("CLOUD_USER_FAVORITES_ANIM_DESC", dictionary, user), function() populate_user_dict(user, dictionary) end)
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
recentsMenu = _lang.menus.list(animationsMenu, "RECENTS", {})
_lang.menus.divider(animationsMenu, "RAW_ANIMATIONS")
local searchMenu = _lang.menus.list(animationsMenu, "SEARCH", {})
_lang.menus.action(searchMenu, "SEARCH_ANIM_GROUPS", {"searchanim"}, function()
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
                _lang.toast("ANIM_DATA_OUTDATED")
                download_animation_data()
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
           local m = menu.action(searchMenu, results[i][2], {"animate" .. results[i][1] .. " " .. results[i][2]}, _lang.format("PLAY_ANIM_DESC", results[i][2], results[i][1]), function(v)
                play_animation(results[i][1], results[i][2], false)
            end)
            table.insert(resultMenus, m)
        end
    end
end)
local browseMenu = _lang.menus.list(animationsMenu, "BROWSE_ANIMS", {}, function() setup_animation_list() end)
menu.on_focus(browseMenu, function()
    if animLoaded then
        _lang.toast("BROWSE_UNLOAD_WARN")
        util.yield(100)
        destroy_animations_data()
    end
end)
show_busyspinner(_lang.format("LOADING_MENUS"))


local scenariosMenu = _lang.menus.list(menu.my_root(), "SCENARIOS", {})
for group, scenarios in pairs(SCENARIOS) do
    local submenu = menu.list(scenariosMenu, group, {}, _lang.format("SCENARIO_GROUP_DESC", group))
    for _, scenario in ipairs(scenarios) do
        scenarioCount = scenarioCount + 1
        menu.action(submenu, scenario[2], {"scenario"}, _lang.format("SCENARIO_PLAY_DESC", scenario[2]), function(v)
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
local ambientSpeechMenu = _lang.menus.list(menu.my_root(), "AMBIENT_SPEECH", {})
local speechMenu = _lang.menus.list(ambientSpeechMenu, "SPEECH_LINES", {"speechlines"})
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
local selfModelVoice = _lang.menus.list(ambientSpeechMenu, "SELF_MODEL_VOICE", {"selfvoice"})
_lang.menus.divider(selfModelVoice, "FEMALE_PEDS")
for _, model in ipairs(VOICE_MODELS.FEMALE) do
    menu.action(selfModelVoice, model, {"voice" .. model}, _lang.format("SELF_VOICE_DESC", model), function(a)
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            entities.delete(selfSpeechPed.entity)
            selfSpeechPed.entity = 0
        end
        selfSpeechPed.model = util.joaat(model)
    end)
end
_lang.menus.divider(selfModelVoice, "MALE_PEDS")
for _, model in ipairs(VOICE_MODELS.MALE) do
    menu.action(selfModelVoice, model, {"voice" .. model}, _lang.format("SELF_VOICE_DESC", model), function(a)
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            entities.delete(selfSpeechPed.entity)
            selfSpeechPed.entity = 0
        end
        selfSpeechPed.model = util.joaat(model)
    end)
end

_lang.menus.slider(ambientSpeechMenu, "SPEECH_DURATION", {"speechduration"}, 0, 100, ambientSpeechDuration, 1, function(value)
    ambientSpeechDuration = value
end)
_lang.menus.slider(ambientSpeechMenu, "SPEECH_INTERVAL", {"speechinterval"}, 100, 30000, speechDelay, 100, function(value)
    speechDelay = value
end)
_lang.menus.action(ambientSpeechMenu, "SPEECH_STOP", {"stopspeeches"}, function()
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
        local a
        a = menu.action(favoritesMenu, name, {}, "Plays " .. favorite[2] .. " from group " .. favorite[1], function(v)
            if PAD.IS_CONTROL_PRESSED(2, 209) then
                menu.show_warning(a, 2, _lang.format("DELETE_FAVORITE_WARN"), function()
                    play_animation(favorite[1], favorite[2], false, nil, true)
                end)
            else
                play_animation(favorite[1], favorite[2], false)
            end
        end)
        table.insert(favoritesActions, a)
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
                _lang.toast("ANIM_DATA_OUTDATED")
                download_animation_data()
            end
            isHeaderRead = true
        end
    end
    animLoaded = true
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
_lang.toast("HINT_SET_FAVORITES")
util.toast(string.format("Ped Actions Script %s by Jackz.", VERSION), 2)

util.on_stop(function(_)
    if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
        entities.delete(selfSpeechPed.entity)
    end
    ANIMATIONS = {}
    if animLoaded then
        _lang.toast("BROWSE_UNLOAD_WARN")
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
