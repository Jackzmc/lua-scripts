local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local ____exports = {}
____exports.default = __TS__Class()
local ModuleManager = ____exports.default
ModuleManager.name = "ModuleManager"
function ModuleManager.prototype.____constructor(self)
    self.versions = {}
    self.allLoaded = false
    self.modules = {}
    self.enabledModules = {}
    self.moduleData = {}
    self.tick = 0
    self.root = menu.my_root()
    self.modulesList = menu.list(self.root, "Modules", {}, "Enable or disable modules")
    self.modulesList:action(
        "Reload All Modules",
        {"jreloadall"},
        "Will read all modules from disk again, exiting all active and starting up any enabled modules",
        function() return self:ReloadAllModules() end
    )
    menu.divider(self.modulesList, "Modules")
    menu.divider(self.root, "Active Modules")
    util.create_tick_handler(function() return self:_ticker() end)
    self:_loadData()
end
function ModuleManager.prototype._loadData(self)
    local file = io.open(____exports.default.METADATA_PATH, "r")
    if file ~= nil then
        local status, data = pcall(
            json.decode,
            file:read("a")
        )
        if status then
            if data.modules then
                for name, module in pairs(data.modules) do
                    self.moduleData[name] = module
                end
            end
        else
            Log.error("Failed to load data save data: " .. data)
        end
        file:close()
    end
end
function ModuleManager.prototype._saveData(self)
    local file = io.open(____exports.default.METADATA_PATH, "w")
    if file ~= nil then
        file:write(json:encode(self.moduleData))
        file:close()
    end
end
function ModuleManager.prototype.ReloadAllModules(self)
    local count = 0
    Log.debug("Reload: Unloading all previously loaded modules")
    for name, module in pairs(self.modules) do
        self:UnloadModule(name)
    end
    Log.debug("Reload: Scanning for modules")
    for ____, filepath in ipairs(filesystem.list_files(____exports.default.DIRECTORY)) do
        if filesystem.is_dir(filepath) then
            local folder = string.match(filepath, ".*[/\\](.*)")
            Log.debug(("Attempting to load module folder \"" .. folder) .. "\"")
            local status, module, requirePath = self:_getModule(folder)
            if status then
                count = count + 1
                self:_preloadModule(module, requirePath)
            else
                Log.warn((((("Failed to load module \"" .. folder) .. "\":\n\t") .. tostring(module)) .. "\n\tPath: ") .. requirePath)
            end
        end
    end
    Log.debug("Reload: Starting modules for some reason?")
    for name, module in pairs(self.modules) do
        self:_startModule(name)
    end
    self.allLoaded = true
    Log.debug("Reload: Done")
    return count
end
function ModuleManager.prototype._getModule(self, name)
    local path = ("jackzscript\\modules\\" .. name) .. "\\module"
    local status, result = pcall(require, path)
    Log.debug("Error: ", result)
    if not status then
        path = (("jackzscript\\modules\\" .. name) .. "\\") .. name
        local status, result = pcall(require, path)
        if not status then
            Log.debug("Error: ", result)
            return false, "Invalid module: could not find a module.lua or <modulename>.lua file in module folder", path
        end
    end
    Log.debug(("Attempting to load module file at \"" .. path) .. "\"")
    return true, result, path
end
function ModuleManager.prototype._preloadModule(self, moduleFile, requirePath)
    local started = self:_loadModule(moduleFile, requirePath)
    if not started then
        moduleFile.default = nil
        self:_unloadModule(requirePath)
    end
end
function ModuleManager.prototype._loadModule(self, moduleFile, requirePath)
    if not moduleFile.ModuleInfo then
        Log.error("Module is missing an exported \"ModuleInfo\" constant that is required")
        return nil
    elseif not moduleFile.default then
        Log.error("Module is missing a required default exported class")
        return nil
    end
    local ____moduleFile_ModuleInfo_0 = moduleFile.ModuleInfo
    local Name = ____moduleFile_ModuleInfo_0.Name
    self.modules[Name] = moduleFile
    if requirePath then
        self:_setupModule(Name, requirePath)
    end
    local module = moduleFile
    Log.debug("Loaded module " .. Name)
    if self.enabledModules[Name] ~= nil then
        self:_startModule(Name)
        return true
    end
    return false
end
function ModuleManager.prototype._unloadModule(self, requirePath)
    package.loaded[requirePath] = nil
end
function ModuleManager.prototype._setupModule(self, name, requirePath)
    local moduleFile = self.modules[name]
    if not moduleFile then
        error("_setupModuleConfig called for non-existent module", 0)
    end
    local description = string.format("%s\n\nAuthor: %s\nVersion: %s", moduleFile.ModuleInfo.Description or "(No description provided)", moduleFile.ModuleInfo.Author, moduleFile.ModuleInfo.Version)
    moduleFile.requirePath = requirePath
    local configMenu = self.modulesList:list(moduleFile.ModuleInfo.Name, {}, description)
    configMenu:toggle(
        "Enabled",
        {},
        ("Will automatically load this module when " .. SCRIPT_NAME) .. " is started",
        function(____, value)
            if value then
                local status, err = pcall(self.LoadModule, self, moduleFile.ModuleInfo.Name)
                if status then
                    self.enabledModules[moduleFile.ModuleInfo.Name] = true
                    self:_startModule(moduleFile.ModuleInfo.Name)
                else
                    Log.error((("Failed to load module \"" .. moduleFile.ModuleInfo.Name) .. "\":\n") .. err)
                    Log.toast((("Could not load module \"" .. moduleFile.ModuleInfo.Name) .. "\":\n") .. err)
                end
            else
                self.enabledModules[moduleFile.ModuleInfo.Name] = nil
            end
        end,
        self.enabledModules[moduleFile.ModuleInfo.Name] ~= nil
    )
    moduleFile.toggleMenu = configMenu
    if moduleFile.ModuleInfo.Url then
        configMenu:hyperlink("View website", moduleFile.ModuleInfo.Url, "")
    end
    if not moduleFile.default.OnTick then
        moduleFile.default.OnTick = function()
        end
    end
    self.modules[name] = moduleFile
end
function ModuleManager.prototype._startModule(self, name)
    local module = self.modules[name]
    Log.debug("Loading module " .. name)
    if not module then
        error("_startModule called on non-existent module", 0)
    end
    local ____self_versions_1 = self.versions
    local ____ = module.ModuleInfo.Name
    local ____ = ____self_versions_1[module.ModuleInfo.Version or "0.1.0"]
    module.root = menu.list(self.root, module.ModuleInfo.Name, {"jmod" .. module.ModuleInfo.Name}, "")
    module.reloadMenu = module.root:action(
        "Stop Module",
        {"jstop" .. module.ModuleInfo.Name},
        "Unloads this module",
        function()
            self:UnloadModule(module.ModuleInfo.Name)
        end
    )
    module.root:action(
        "Reload Module",
        {"jreload" .. module.ModuleInfo.Name},
        "Reloads this module",
        function()
            self:ReloadModule(module.ModuleInfo.Name)
        end
    )
    module.root:divider("")
    if module.default.OnStart ~= nil then
        module.default:OnStart(module.root)
    end
    menu.set_menu_name(module.toggleMenu, name .. " (Active)")
    Log.debug("Loaded module " .. name)
end
function ModuleManager.prototype.LoadModule(self, name)
    local module = self.modules[name]
    if module then
        self:_loadModule(module)
    else
        error(("LoadModule: Module " .. name) .. " not found", 0)
    end
end
function ModuleManager.prototype.UnloadModule(self, name)
    local module = self.modules[name]
    if module then
        if module.toggleMenu then
            menu.set_menu_name(module.toggleMenu, name)
        end
        if module.root then
            module.root:delete()
        end
        if module.default.OnExit ~= nil then
            pcall(module.default.OnExit, module.default, false)
        end
        if module.requirePath then
            package.loaded[module.requirePath] = nil
        end
        self.modules[name] = nil
    else
        error(("UnloadModule: Module " .. name) .. " was never loaded", 0)
    end
end
function ModuleManager.prototype.ReloadModule(self, name)
    self:UnloadModule(name)
    self:LoadModule(name)
end
function ModuleManager.prototype.Shutdown(self)
    self:_saveData()
    for name, module in pairs(self.modules) do
        self:UnloadModule(name)
    end
end
function ModuleManager.prototype._ticker(self)
    self.tick = 0
    for name in pairs(self.enabledModules) do
        local module = self.modules[name]
        module.default:OnTick(self.tick)
    end
    return true
end
ModuleManager.DIRECTORY = filesystem.scripts_dir() .. "lib\\jackzscript\\modules\\"
ModuleManager.METADATA_PATH = filesystem.resources_dir() .. "jackzscript\\meta.json"
____exports.default = ModuleManager
return ____exports
