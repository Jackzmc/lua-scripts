-- Check for updates & auto-update:
function check_for_update(branch)
    async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION  .. "&branch=" .. (branch or "master") .. "&commit=" .. (BRANCH_LAST_COMMIT or ""), function(result)
        local chunks = {}
        for substring in string.gmatch(result, "%S+") do
            table.insert(chunks, substring)
        end
        if chunks[1] == "OUTDATED" then
            download_script_update(branch, function()
                util.toast(SCRIPT .. " was automatically updated to V" .. chunks[2] .. "\nRestart script to load new update.", TOAST_ALL)
            end, function()
                util.toast(SCRIPT .. ": Failed to automatically update to V" .. chunks[2] .. ".\nPlease download latest update manually.\nhttps://jackz.me/stand/get-latest-zip", 2)
                util.stop_script()
            end)
        end
    end)
    async_http.dispatch()
end
function download_script_update(branch, on_success, on_err)
    async_http.init("jackz.me", "/stand/get-lua.php?script=" .. SCRIPT .. "&source=manual&branch=" .. (branch or "master"), function(result)
        local file = io.open(filesystem.scripts_dir()  .. SCRIPT_RELPATH, "w")
        file:write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
        file:close()
        if on_success then on_success() end
    end, on_err)
    async_http.dispatch()
end
check_for_update(SCRIPT_BRANCH)

function download_lib_update(lib)
    local lockPath = filesystem.scripts_dir() .. "/lib/" .. lib .. ".lock"
    if filesystem.exists(lockPath) then
        util.log(SCRIPT_NAME .. ": Skipping lib update \" .. lib .. \", found update lockfile")
    end
    local lock = io.open(lockPath, "w")
    if lock == nil then
        util.toast(SCRIPT_NAME .. ": Could not create lockfile, skipping update", TOAST_ALL)
        return
    end
    lock:close()
    async_http.init("jackz.me", "/stand/get-lua.php?script=lib/" .. lib .. "&branch=" .. (SCRIPT_BRANCH or "master"), function(result)
        os.remove(lockPath)
        if result:startswith("<") then
            util.toast("Lib returned invalid response for \"" .. lib .. "\"\nSee logs for details")
            util.log(string.format("%s: Lib \"%s\" returned: %s", SCRIPT_NAME, lib, result))
            return
        end
        local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
        if file == nil then
            util.toast("Could not write lib file for: " .. lib .. "\nSee logs for details")
            util.log(string.format("%s: Resource \"%s\" file could not be created.", SCRIPT_NAME, lib))
            return
        end
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        util.toast(SCRIPT .. ": Automatically updated lib '" .. lib .. "'")
    end, function(e)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
        os.remove(lockPath)
        util.stop_script()
    end)
    async_http.dispatch()
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
    async_http.init("jackz.me", "/stand/get-lua.php?script=resources/" .. filepath .. "&branch=" .. (SCRIPT_BRANCH or "master"), function(result)
        os.remove(lockPath)
        if result:startswith("<") then
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
        util.toast(SCRIPT .. ": Automatically updated resource '" .. filepath .. "'")
    end, function(e)
        os.remove(lockPath)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. filepath .. ")", 10)
        util.stop_script()
    end)
    async_http.dispatch()
end
