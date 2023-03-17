-- People keep trying to run stuff on non-stand
if not filesystem.stand_dir then
    print("Unsupported. Only stand is supported")
    return
end
----------------------------------------------------------------
-- Version Check
function get_version_info(version)
    if not version then error("Missing version", 2) end
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
    if not av or not bv then error("Missing versions to compare") end
    if av.major > bv.major then return 1
    elseif av.major < bv.major then return -1
    elseif av.minor > bv.minor then return 1
    elseif av.minor < bv.minor then return -1
    elseif av.patch > bv.patch then return 1
    elseif av.patch < bv.patch then return -1
    else return 0 end
end
if SCRIPT_BRANCH and SCRIPT_BRANCH == "release" then
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
menu.hyperlink(SCRIPT_META_LIST, "View full changelog", "https://jackz.me/stand/changelog?html=1&reverse=1&script=" .. SCRIPT_NAME)
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
menu.action(SCRIPT_META_LIST, "Upload Logs", {}, "Uploads the last ~20 lines of your stand log (%appdata%\\Stand\\Log.txt) to hastebin.com.\nHastebin posts expire in upto 7 days.\n\nUploaded log can be accessed from \"Open Uploaded Log\" button below once pressed", function()
    local logs = io.open(filesystem.stand_dir() .. "Log.txt", "r")
    if logs then
        show_busyspinner("Uploading logs....")
        async_http.init("paste.jackz.me", "/paste?textOnly=1&expires=604800", function(body)
            HUD.BUSYSPINNER_OFF()
            local lines = {}
            for s in body:gmatch("[^\r\n]+") do
                table.insert(lines, s)
            end
            local url = lines[3] or ("https://paste.jackz.me/" .. lines[1])
            util.copy_to_clipboard(url, true)
            util.toast("Uploaded: " .. url .. "\nCopied to clipboard", 2)
            menu.hyperlink(SCRIPT_META_LIST, "Open Uploaded Log", url)
                :setTemporary()
        end, function()
            util.toast("Failed to submit logs, network error")
            HUD.BUSYSPINNER_OFF()
        end)
        logs:seek("end", -3072)
        local content = logs:read("*a")
        local standVersion = menu.get_version().full
        async_http.set_post("text/plain",
            string.format("Script: %s\nSource: %s\nBranch: %s\nVersion: %s\nStand Version: %s\nCommit: %s\n\n%s", SCRIPT_NAME, SCRIPT_SOURCE or "UNK", SCRIPT_BRANCH or "UNK", VERSION or "UNK", standVersion, BRANCH_LAST_COMMIT or "DEV BUILD", content)
        )
        async_http.dispatch()
        logs:close()
    else
        util.toast("Could not read your stand log file")
    end
end)

SCRIPT_DEBUG = SCRIPT_SOURCE == nil

function try_require(name, isOptional)
    local status, data = pcall(require, name)
    if status then
        return data
    else
        if data then
            util.toast(name .. ": " .. data, TOAST_ALL)
        end
        if SCRIPT_SOURCE == "REPO" then
            if isOptional then
                Log.debug("Missing optional dependency: " .. name)
            else
                util.toast("Missing a required depencency (\"" .. name .. "\"). Please install this from the repo > dependencies list")
                Log.severe("Missing required dependency:", name)
            end
        elseif download_lib_update then
            local lockPath = download_lib_update(name, function()
                Log.log("Downloaded ", isOptional and "optional" or "required", "library:", name)
            end)
            while filesystem.exists(lockPath) do
                util.yield(500)
            end
            return require(name)
        end
        return nil
    end
end