-- Check for updates & auto-update:
function check_for_update(branch)
    async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION  .. "&branch=" .. (branch or "master") .. "&commit=" .. (BRANCH_LAST_COMMIT or ""), function(body, res_headaers, status_code)
        if status_code == 200 then
            local chunks = {}
            for substring in string.gmatch(body, "%S+") do
                table.insert(chunks, substring)
            end
            if chunks[1] == "OUTDATED" then
                SCRIPT_UPDATE_NEW_VERSION = chunks[3]
                util.toast(SCRIPT_NAME .. ": An update is available (V" .. chunks[3] .. ")")
                SCRIPT_META_UPDATE_ACTION.menu_name = "Update (V" .. chunks[3] .. ")"
                SCRIPT_META_UPDATE_ACTION.help_text = "Update from v" .. VERSION .. " to v" .. chunks[3] .. "\nCommit: " .. chunks[2]:sub(1, 11)
                SCRIPT_META_UPDATE_ACTION.visible = true
            end
        else
            util.toast(SCRIPT .. ": Could not auto update due to server error (HTTP " .. status_code .. ")\nPlease download latest update manually.\nhttps://jackz.me/stand/get-latest-zip", 2)
        end
    end)
    async_http.dispatch()
end
function check_for_old_version()
    local file = io.open(SCRIPT_BACKUP_PATH, "r")
    if file then
        local chunks = {}
        for substring in io.lines("SCRIPT_OLD_VERSION_PATH") do
            table.insert(chunks, substring)
        end
        SCRIPT_META_REVERT_ACTION.set_menu_name("Revert to v" .. chunks[1])
        SCRIPT_META_REVERT_ACTION.help_text = "Revert to old v" .. chunks[1] .. "\nBranch: " .. chunks[2] .. "\nCommit: " .. chunks[3]

        file:close()
        SCRIPT_META_REVERT_ACTION.visible = false
    end
end
function download_script_update(branch, on_success, on_err)
    if not branch then branch = "release" end
    local success, err = io.copyto(filesystem.scripts_dir()  .. SCRIPT_RELPATH, SCRIPT_BACKUP_PATH)
    if not success then
        Log.error("Could not backup script: ", err)
        util.toast("Could not download update: " .. (err or "nil"))
        return
    end
    local vFile = io.open(SCRIPT_BACKUP_PATH .. ".meta", "w")
    if not vFile then
        Log.error("script update failed: couldnt open file")
        if on_err then on_err(0, "couldnt open file") end
        return
    end
    vFile:write("V" .. VERSION .. "\n" .. SCRIPT_BRANCH .. "\n" .. BRANCH_LAST_COMMIT)
    vFile:close()

    async_http.init("jackz.me", "/stand/get-lua.php?script=" .. SCRIPT .. "&source=manual&branch=" .. branch, function(body, res_headers, status_code)
        if status_code == 200 then
            local file = io.open(filesystem.scripts_dir()  .. SCRIPT_RELPATH, "w")
            if file then
                file:write(body:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
                file:close()
                Log.log("Updated ", SCRIPT_NAME, "to branch", branch)
                if on_success then on_success() end
            else
                util.toast("Error updating script")
                Log.error("script update failed: couldnt open file")
                if on_err then on_err(0, "couldnt open file") end
            end
        else
            Log.error("script update failed due to server error: " .. status_code .. "\n" .. body)
            if on_err then on_err(status_code, body) end
        end
    end, on_err)
    async_http.dispatch()
end
check_for_update(SCRIPT_BRANCH)

function download_lib_update(lib, on_success, on_error)
    local lockPath = filesystem.scripts_dir() .. "/lib/" .. lib .. ".lock"
    if filesystem.exists(lockPath) then
        if on_error then on_error() end
        util.log(SCRIPT_NAME .. ": Skipping lib update \" .. lib .. \", found update lockfile")
    end
    local lock = io.open(lockPath, "w")
    if lock == nil then
        util.toast(SCRIPT_NAME .. ": Could not create lockfile, skipping update", TOAST_ALL)
        if on_error then on_error() end
        return
    end
    lock:close()
    async_http.init("jackz.me", "/stand/get-lua.php?script=lib/" .. lib .. "&source=" .. SCRIPT_SOURCE .. "&branch=" .. (SCRIPT_BRANCH or "master"), function(result, res_headers, status_code)
        os.remove(lockPath)
        if status_code ~= 200 or result:startswith("<") or result == "" then
            util.toast("Lib returned invalid response for \"" .. lib .. "\"\nSee logs for details")
            util.log(string.format("%s: Lib \"%s\" returned: %s", SCRIPT_NAME, lib, result))
            if on_error then on_error() end
            return
        end
        local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
        if file == nil then
            util.toast("Could not write lib file for: " .. lib .. "\nSee logs for details")
            util.log(string.format("%s: Resource \"%s\" file could not be created.", SCRIPT_NAME, lib))
            if on_error then on_error() end
            return
        end
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        Log.log("Updated lib ", lib, "for", SCRIPT_NAME, "to branch", SCRIPT_BRANCH or "master")
        util.toast(SCRIPT .. ": Automatically updated lib '" .. lib .. "'")
        if on_success then on_success() end
    end, function(e)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
        os.remove(lockPath)
        if on_error then on_error() end
        util.stop_script()
    end)
    async_http.dispatch()
    return lockPath
end
function download_resources_update(filepath, destOverwritePath)
    local lockPath = filesystem.scripts_dir() .. "/lib/" .. filepath .. ".lock"
    if filesystem.exists(lockPath) then
        util.log(SCRIPT_NAME .. ": Skipping resource update \" .. lib .. \", found update lockfile")
    end
    local lock = io.open(lockPath, "w")
    if lock == nil then
        util.toast(SCRIPT_NAME .. ": Could not create lockfile, skipping update", TOAST_ALL)
        return
    end
    lock:close()
    async_http.init("jackz.me", "/stand/get-lua.php?script=resources/" .. filepath .. "&source=" .. SCRIPT_SOURCE .. "&branch=" .. (SCRIPT_BRANCH or "master"), function(result, res_headers, status_code)
        os.remove(lockPath)
        if status_code ~= 200 or result:startswith("<") then
            util.toast("Resource returned invalid response for \"" .. filepath .. "\"\nSee logs for details")
            util.log(string.format("%s: Resource \"%s\" returned: %s", SCRIPT_NAME, filepath, result))
            return
        end
        local file = io.open(filesystem.resources_dir() .. (destOverwritePath or filepath), "w")
        if file == nil then
            util.toast("Could not write resource file for: " .. filepath .. "\nSee logs for details")
            util.log(string.format("%s: Resource \"%s\" file could not be created.", SCRIPT_NAME, filepath))
            return
        end
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        Log.log("Updated resource ", filepath, "for", SCRIPT_NAME, "to branch", SCRIPT_BRANCH or "master")
        util.toast(SCRIPT .. ": Automatically updated resource '" .. filepath .. "'")
    end, function(e)
        os.remove(lockPath)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. filepath .. ")", 10)
        util.stop_script()
    end)
    async_http.dispatch()
end
