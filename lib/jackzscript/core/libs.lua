local REQUIRED_LIBS = {
    lang = {
        url = "https://jackz.me/stand/libs/translations.lua",
        targetVersion = "1.3.1",
        core = true
    },
    json = {
        url = "https://jackz.me/stand/libs/json.lua",
        core = true
    },
}
Libs = {}
function Libs:Download(uri, filename)
    local domain, path = uri:match("([a-zA-Z.]+)(/.*)")
    if not domain then
        error("Invalid URI provided: " .. uri)
    end
    self.downloading = true
    async_http.init(domain, path, function(result)
        local file = io.open(filesystem.scripts_dir() .. "/lib/" .. filename, "w")
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        util.toast(SCRIPT_NAME .. ": Automatically updated lib '" .. filename .. "'")
        self.downloading = false
    end, function(e)
        util.toast(SCRIPT_NAME .. " cannot load: Library files are missing. (" .. filename .. ")", TOAST_ALL)
        util.stop_script()
    end)
    async_http.dispatch()
    -- Wait for download to complete
    while self.downloading do
        util.yield()
    end
end

function Libs:Load(libid, data, retry)
    local status, lib = pcall(require, libid)
    if status then
        local libVersion = lib.VERSION or lib.LIB_VERSION
        -- If version comparison setup, check outdated
        if retry and data.targetVersion ~= nil and data.targetVersion ~= libVersion then
            if data.url then
                util.log(string.format("jackzscript: Library '%s' version out of date, auto updating (current: %s, latest: %s)", libid, libVersion, data.targetVersion))
                self:Download(data.url, libid .. ".lua")
                return Libs:Load(lib, data, false)
            else
                util.log(string.format("jackzscript: Library '%s' version out of date. No auto-update url provided. (current: %s, latest: %s)", libid, libVersion, data.targetVersion))
            end
        end

        if not data.core then
            Libs[libid] = {
                requiredByModules = {}
            }
        end

        _G[libid] = lib
        return lib
    elseif retry and data.url then
        util.log(string.format("jackzscript: Missing library '%s', attempting download...", libid))
        self:Download(data.url, libid .. ".lua")
        return Libs:Load(libid, data, false)
    else
        util.log(string.format("jackzscript: Missing library '%s', failed to download.", libid))
        return nil
    end
end

util.create_thread(function()
    for libid, data in pairs(REQUIRED_LIBS) do
        Libs:Load(libid, data, true)
    end
    Libs.loadComplete = true
end)


--- Will unload lib once determined no other module is using it
function Libs:DiscardLib(libid)
    jutil.CreateTimeout(30000, function()
        -- After this timeout, if this lib is still not used, delete it
        if Libs[libid] and #Libs[libid].requiredByModules == 0 then
            Libs[libid] = nil
            _G[libid] = nil
        end
    end)
end

return Libs