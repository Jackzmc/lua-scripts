----------------------------------------------------------------
-- Version Check
function get_version_info(version)
    local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
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
    if versionFile then
        versionFile:close()
    end
end
local versionFile = io.open(VERSION_FILE_PATH, "r+")
if versionFile then
    local versions = {}
    for line in versionFile:lines("l") do
        local script, version = line:match("(%g+): (%g+)")
        if script then
            versions[script] = version
        end
    end
    if versions[SCRIPT_NAME] == nil or compare_version(VERSION, versions[SCRIPT_NAME]) == 1 then
        if versions[SCRIPT_NAME] ~= nil then
            async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT_NAME .. "&since=" .. versions[SCRIPT_NAME] .. "&branch=" .. (SCRIPT_BRANCH or "master"), function(result)
                util.toast("Changelog for " .. SCRIPT_NAME .. " version " .. VERSION .. ":\n" .. result)
            end, function() util.log(SCRIPT_NAME ..": Could not get changelog") end)
            async_http.dispatch()
        end
        versions[SCRIPT_NAME] = VERSION
        versionFile:seek("set", 0)
        versionFile:write("# DO NOT EDIT ! File is used for changelogs\n")
        for script, version in pairs(versions) do
            versionFile:write(script .. ": " .. version .. "\n")
        end
    end
    versionFile:close()
else
    util.log(SCRIPT_NAME .. ": Failed to access to version file")
end
-- END Version Check
------------------------------------------------------------------
function show_busyspinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end

SCRIPT_META_LIST = menu.list(menu.my_root(), "Script Meta")
menu.divider(SCRIPT_META_LIST, SCRIPT_NAME .. " V" .. VERSION)
menu.hyperlink(SCRIPT_META_LIST, "View full changelog", "https://jackz.me/stand/changelog?html=1&script=" .. SCRIPT_NAME)
menu.hyperlink(SCRIPT_META_LIST, "Jackz's Guilded", "https://www.guilded.gg/i/k8bMDR7E?cid=918b2f61-989c-41c4-ba35-8fd0e289c35d&intent=chat", "Get help, submit suggestions, report bugs, or be with other users of my scripts")
menu.hyperlink(SCRIPT_META_LIST, "Github Source", "https://github.com/Jackzmc/lua-scripts", "View all my lua scripts on github")
if SCRIPT_SOURCE == "MANUAL" then
    menu.list_select(SCRIPT_META_LIST, "Release Channel", {SCRIPT_NAME.."channel"}, "Sets the release channel for updates for this script.\nChanging the channel from release may result in bugs.", SCRIPT_BRANCH_NAMES, 1, function(index, name)
        show_busyspinner("Downloading update...")
        download_script_update(SCRIPT_BRANCH_IDS[index], function()
            HUD.BUSYSPINNER_OFF()
            util.log(SCRIPT_NAME .. ": Released channel changed to " .. SCRIPT_BRANCH_IDS[index])
            util.toast("Release channel changed to " .. name .. " (" .. SCRIPT_BRANCH_IDS[index] .. ")\nReload to apply changes")
        end, function()
            util.toast("Failed to download latest version for release channel.")
        end)
    end)
else
    menu.readonly(SCRIPT_META_LIST, "Release Channel", "Use the manual version from https://jackz.me/stand/get-latest-zip to change the release channel.")
end
if _lang ~= nil then
    menu.hyperlink(SCRIPT_META_LIST, "Help Translate", "https://jackz.me/stand/translate/?script=" .. SCRIPT, "If you wish to help translate, this script has default translations fed via google translate, but you can edit them here:\nOnce you make changes, top right includes a save button to get a -CHANGES.json file, send that my way.")
    _lang.add_language_selector_to_menu(SCRIPT_META_LIST)
end
menu.readonly(SCRIPT_META_LIST, "Build Commit", BRANCH_LAST_COMMIT and BRANCH_LAST_COMMIT:sub(1,10) or "Dev Build")
menu.action(SCRIPT_META_LIST, "Upload Logs", {}, "Uploads the ~20 lines of your stand log (%appdata%\\Stand\\Log.txt) to hastebin.com.\nHastebin posts expire in upto 7 days.", function()
    local logs = io.open(filesystem.stand_dir() .. "Log.txt", "r")
    if logs then
        show_busyspinner("Uploading logs....")
        async_http.init("hastebin.com", "/documents", function(body)
            HUD.BUSYSPINNER_OFF()
            local url = "https://hastebin.com/" .. body:sub(9, -3)
            util.toast("Uploaded: " .. url)
            menu.hyperlink(SCRIPT_META_LIST, "Open Uploaded Log", url)
        end, function()
            util.toast("Failed to submit logs, network error")
            HUD.BUSYSPINNER_OFF() 
        end)
        logs:seek("end", -2048)
        local content = logs:read("*a")
        async_http.set_post("text/plain",
            string.format("Script: %s\nSource: %s\nVersion: %s\nCommit: %s\n%s", SCRIPT_NAME, SCRIPT_SOURCE or "UNK", VERSION or "UNK", BRANCH_LAST_COMMIT or "DEV BUILD", content)
        )
        async_http.dispatch()
        logs:close()
    else
        util.toast("Could not read your stand log file")
    end
end)


