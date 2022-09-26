ModuleManager = {
    hToggleList = nil,
    tToggleHandles = {},
    DIRECTORY = filesystem.scripts_dir() .. "lib\\jackzscript\\modules\\",
    loadData = nil,
    initLoadComplete = false,
    Modules = {},
    tShareData = {},
    debugMode = false
}

--[[
TODO:
1. Load module metadata, store for list [done]
2. Set "Reload Module" for dev-mode
--]]

local onlineVersion = NETWORK._GET_ONLINE_VERSION()
local scRoot = menu.my_root()

function ModuleManager:init()
    self.hModulesList = menu.list(scRoot, "Modules", {}, "Enable or disable modules")
        menu.action(self.hModulesList, "Reload All Modules", {"jreloadall"}, "Will read all modules from disk again, exiting all active and starting up any enabled modules", function()
            ModuleManager:ReloadAllModules()
        end)
        menu.divider(self.hModulesList, "Modules")
    menu.divider(scRoot, "Active Modules")
end

function ModuleManager:_start(mod)
    Versions:Set(mod.name, mod.VERSION)
    mod.root = menu.list(scRoot, mod.name, {"jmod" .. mod.name}, "")
    local reloadIndex = menu.action(mod.root, "Stop Module", {"jstop" .. mod.name}, "Unloads this module", function()
        self:UnloadModule(mod.name)
    end)
    menu.action(mod.root, "Reload Module", {"jreload" .. mod.name}, "Reloads this module", function()
        self:ReloadModule(mod.name)
    end)
    menu.divider(mod.root, "")
    if mod.OnReady ~= nil then
        mod:OnReady(mod.root)
    end
    mod._reloadIndex = reloadIndex
end

--- Reloads a module, name excluding .lua (just 'example')
--- @param name string Module name
function ModuleManager:ReloadModule(name)
    self:UnloadModule(name, true)
    local index = self:LoadModule(name)
    menu.focus(self.Modules[index]._reloadIndex)
    util.toast("Module \"" .. name .. "\" has been reloaded")
end

local function _gen_log_module_func(name, isDebug)
    return function(...)
        if isDebug and not ModuleManager.debugMode then return end
        local output = "[" .. SCRIPT_NAME .. "] [" .. name .. "] "
        local args = table.pack(...)
        for i = 1, args.n do
            output = output .. tostring(args[i]) .. " "
        end
        util.log(output)
    end
end

local function _gen_toast_module_func(name)
    return function(...)
        local output = "[" .. name .. "] "
        local args = table.pack(...)
        for i = 1, args.n do
            output = output .. tostring(args[i]) .. " "
        end
        util.toast(output)
    end
end

local function _gen_require_lib_func(mod, name)
    return function(lib)
        local path = name .. "/" .. lib
        package.loaded[path] = nil
        local r = require(path)
        table.insert(mod._local_libs, path)
        return r
    end
end

require('jackzscript\\core\\log')

function ModuleManager:_initVariables(mod, name)
    mod.onlineVersion = onlineVersion
    mod.sharedData = self.tShareData
    mod._local_libs = {}
    if mod.OnTick == nil then mod.OnTick = function() end end
    if mod.Version == nil then mod.Version = "0.1.0" end
    mod.require = _gen_require_lib_func(mod, name)
    menu.my_root = nil
end

--- Load a module, name excluding .lua (just 'example')
--- @param name string Module name
--- @return number internal modid
function ModuleManager:LoadModule(name)
    if self:GetModuleIndex(name) ~= nil then
        return error(SCRIPT_NAME .. ": Attempted to load module that is already loaded (" .. name .. ")")
    end
    -- Pull module from modulename\\module.lua or just modulename.lua
    -- local requirePath = (filesystem.is_dir(self.DIRECTORY .. name))
    --     and "jackzscript\\modules\\" .. name .. "\\module"
    --     or "jackzscript\\modules\\" .. name
    local requirePath = "jackzscript\\modules\\" .. name .. "\\module"
    if not filesystem.exists(requirePath) then
        requirePath = "jackzscript\\modules\\" .. name .. "\\" .. name
    end

    local status, mod = pcall(require, requirePath)
    if status then
        if mod ~= nil and mod.OnModulePreload then
            self:_initVariables(mod, name)
            local wasUpdated = (jutil.ParseSemver(mod.VERSION) ~= nil and Versions:Get(name) ~= nil and Versions:Compare(name, mod.VERSION) == 1)
            if wasUpdated then mod.previousVersion = Versions:Get(name) end
            if mod:OnModulePreload(false, wasUpdated) then
                if mod.sharedLibs then
                    for libid, data in pairs(mod.sharedLibs) do
                        Libs:Load(libid, data, true)
                        table.insert(Libs[libid].requiredByModules, name)
                    end
                end
                table.insert(self.Modules, mod)
                if self.initLoadComplete then
                    self:_start(mod)
                    Versions:Save()
                end
                return #self.Modules
            end
        else
            error(SCRIPT_NAME .. ": Invalid module \"" .. name .. "\", missing preload function")
            util.log(SCRIPT_NAME .. ": Invalid module \"" .. name .. "\", missing load function")
        end
    else
        error(SCRIPT_NAME .. ": Could not load module \"" .. name .. "\": " .. mod)
    end
end

function ModuleManager:_fetchModuleMeta(name)
    local requirePath = "jackzscript\\modules\\" .. name .. "\\module"
    if not filesystem.exists(requirePath) then
        requirePath = "jackzscript\\modules\\" .. name .. "\\" .. name
    end
    local status, mod = pcall(require, requirePath)
    if status then
        return {
            version = mod.VERSION or "-none-",
            author = mod.AUTHOR or "Unknown",
            description = mod.DESCRIPTION,
            url = mod.INFO_URL
        }
    else
        return nil
    end
end


--- Gets a module internal index
--- @param name string Module name
function ModuleManager:GetModuleIndex(name)
    for i, mod in ipairs(self.Modules) do
        if mod.Name == name then
            return i
        end
    end
    return nil
end

--- Unload a module, name excluding .lua (just 'example')
--- @param name string Module name
function ModuleManager:UnloadModule(name, isReload)
    local i = self:GetModuleIndex(name)
    if i ~= nil then
        -- Remove all locally loaded libs using self.require
        if self.Modules[i]._loaded_libs then
            for _, path in ipairs(self.Modules[i]._loaded_libs) do
                package.loaded[path] = nil
            end
        end
        -- Remove module from lib cache, so it can be possibly purged
        if self.Modules[i].libs then
            for libid, data in pairs(self.Modules[i].libs) do
                for j, modName in ipairs(Libs[libid].requiredByModules) do
                    if modName == name then
                        table.remove(Libs[libid].requiredByModules, j)
                        if #Libs[libid].requiredByModules == 0 then
                            Libs:DiscardLib(libid)
                        end
                    end
                end
            end
        end
        local requirePath = (filesystem.is_dir(self.DIRECTORY .. name))
            and "jackzscript\\modules\\" .. name .. "\\module"
            or "jackzscript\\modules\\" .. name
        package.loaded[requirePath] = nil
        self.Modules[i]:OnExit(isReload or false)
        pcall(menu.delete, self.Modules[i].root)
        -- menu.set_menu_name(self.Modules[i].root, self.Modules[i].name)

        table.remove(self.Modules, i)
        return true
    end
    error("Attempted to unload an unloaded module '" .. name .. "'")
end

function ModuleManager:_setupModuleConfig(name, meta)
    local description = string.format("%s\n\nAuthor: %s\nVersion: %s",
        meta.description or "(No description provided)",
        meta.author,
        meta.version
    )
    local m = menu.list(self.hModulesList, name, {}, description)
    menu.toggle(m, "Enabled", {}, "Will automatically load this module when " .. SCRIPT_NAME .. " is started up or reloaded.", function(on)
        if on then
            enabledModules[name] = "true"
            local status, err = pcall(self.LoadModule, self, name)
            if status then
                if self.Modules[err]._reloadIndex then
                    menu.focus(self.Modules[err]._reloadIndex)
                else
                    util.log(SCRIPT_NAME .. ": _reloadIndex for " .. name .. " nil, did module not load?")
                end
            else
                util.toast("Could not load " .. name .. ": " .. err, TOAST_ALL)
            end
        else
            enabledModules[name] = nil
            self:UnloadModule(name)
        end
        jutil.WriteKV(stateFile, enabledModules)
    end, enabledModules[name])
    if meta.url then
        menu.hyperlink(m, "View webpage", meta.url)
    end
    self.tToggleHandles[name] = m
end


-- Reloads all modules fresh from file.
function ModuleManager:_load(name)
    local meta = self:_fetchModuleMeta(name)
    if not meta then
        util.log("jackzscript: Failed to load meta from " .. name)
    else
        self:_setupModuleConfig(name, meta)
        if enabledModules[name] then
            local status, err = pcall(self.LoadModule, self, name)
            if status then
                self.loadCount.loaded = self.loadCount.loaded + 1
            else
                util.toast("Could not load module \"" .. name .. "\": "  .. err)
                self.loadCount.errored = self.loadCount.errored + 1
            end
        end
    end
end
function ModuleManager:ReloadAllModules()
    self.initLoadComplete = false
    self.loadCount = { loaded = 0, errored = 0 }
    for name, hMenu in pairs(self.tToggleHandles) do
        pcall(menu.delete, hMenu)
        self.tToggleHandles[name] = nil
    end
    for _, mod in ipairs(self.Modules) do
        self:UnloadModule(mod.name)
    end
    -- Attempt to load every lua file in modules folder
    for _, path in ipairs(filesystem.list_files(self.DIRECTORY)) do
        if filesystem.is_dir(path) then
            local folder = path:match(".*[/\\](.*)")
            if filesystem.exists(path .. "\\module.lua") then
                self:_load(folder)
            end
        else
            local name, ext = path:match(".*[/\\](.*)%.(.*)")
            if ext == "lua" then
                self:_load(name)
            end
        end
    end

    if self.loadCount.errored > 0 then
        util.toast(SCRIPT_NAME .. ": Some modules failed to load, check your stand log for more information.")
    end

    -- Finally, tell all modules they are ready to start
    for _, mod in ipairs(self.Modules) do
        self:_start(mod)
    end
    Versions:Save()

    self.initLoadComplete = true
    util.toast(SCRIPT_NAME .. ": Loaded " .. self.loadCount.loaded .. " modules")
end


function ModuleManager:Shutdown()
    for _, mod in ipairs(self.Modules) do
        if mod.OnExit then
            mod:OnExit(false)
        end
    end
end

--- Will download a single module file and place in lib/jackzscript/modules/.
--- Does not support folder-modules
--- @param name string Name of the module, .lua will be appended
--- @param uri string The URI to fetch the file from
--- @see ModuleManager:DownloadFull(name, uri)
function ModuleManager:DownloadSingle(name, uri)
    local domain, path = uri:match("([a-zA-Z.]+)(/.*)")
    if not domain then
        error("Invalid URI provided: " .. uri)
    end
    self.downloading = true
    util.log(SCRIPT_NAME .. ": Downloading singlefile update for module '" .. name .. "'")
    async_http.init(domain, path, function(result)
        local file = io.open(self.DIRECTORY .. name .. ".lua", "w")
        file:write(result:gsub("\r", "") .. "\n")
        file:close()
        util.toast(SCRIPT_NAME .. ": Downloaded an update for module '" .. name .. "'")
        self.downloading = false
    end, function()
        util.log(SCRIPT_NAME .. " Could not download an update for module '" .. name .. ")", TOAST_ALL)
    end)
    async_http.dispatch()
    -- Wait for download to complete
    while self.downloading do
        util.yield()
    end
end

function ModuleManager:Count()
    return #self.Modules
end

return ModuleManager