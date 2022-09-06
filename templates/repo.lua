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
    async_http.init("jackz.me", "/stand/get-lua.php?script=resources/" .. filepath .. "&source=" .. SCRIPT_SOURCE .. "&branch=" .. (SCRIPT_BRANCH or "master"), function(result)
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