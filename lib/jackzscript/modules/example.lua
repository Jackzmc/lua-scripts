--[[ By default the following libs are loaded globally:
    1. json.lua as 'json'
    2. natives (version defined by NATIVES_VERSION)
    3. translations as 'lang'
--]]

local Module = {
    VERSION = "0.1.0",
    DESCRIPTION = "My example module description",
    AUTHOR = "Jackz",
    INFO_URL = nil, -- Optional url, such as guilded, where users can get info
    --[[ Internally loaded variables ---
    - Access these via self. (ex self.root or self.log)
    root -- Populated with the Lua Scripts -> jackzscript root
    name -- Name of the file without the .lua extension
    onlineVersion -- Will be populated on preload,

    log(...) -- Logs to file with prefix [jackzscript] [Module.name] <any>, auto calls tostring() on all vars
    toast(...) -- Toasts to stand with prefix [Module.name] <any>, auto calls tostring() on all vars
    require(file) -- Requires a lib file, and will automatically delete it on module unload, removing its cache

    --- Optional, config variables ---
    --- Note: All ___Url variables have the following placeholders:
    --- %name% -> example, %filename% -> example.lua
    libs = { 
        -- Note: Current implementation, all modules share the libraries, such that if one targets a newer version, the newest will always be downloaded
        mylib = { -- Key is the global name of the lib
            sourceUrl = "", -- URL of file, where to download from
            targetVersion = "" -- Target version of lib, must expose either VERSION or LIB_VERSION
        }
    }
    --]]
    sharedLibs = {
        -- jackzvehiclelib = {
        --     url = "jackz.me/stand/libs/jackzvehiclelib.lua",
        --     targetVersion = "1.1.0",
        -- }
    }
}

--- [REQUIRED] Checks if this module should be loaded, incase you want to do any startup checks.
--- @param isManual boolean True if module was loaded manually, false if automatically loaded
--- @param wasUpdated boolean Has script been updated (see self.previousVersion to get old version)
--- @return boolean TRUE if module should be loaded, false if not
function Module:OnModulePreload(isManual, wasUpdated)
    return true
end

--- Called once every module has been loaded.
--- @param root MenuHandle A handle to the stand menu list (Lua Scripts -> jackzscript -> Module.name)
function Module:OnReady(root)
    self.moduleCount = 0
    menu.action(root, "test", {}, "" .. Module.name, function()
        -- Log.log("test")
        Log.toast("hey!")
    end)
end


--- Called every frame, no need to yield
--- @param tick number Every increasing number, which represents the current frame
function Module:OnTick(tick)
    if math.fmod(tick, 100) == 0 then
        self.moduleCount = ModuleManager:Count()
        util.draw_debug_text("U")
    end
    util.draw_debug_text(self.moduleCount .. " modules running. " .. tick)
end

--- Called when module is exiting
--- @param isReload boolean If true, script is being reloaded manually. False if exiting normally
function Module:OnExit(isReload)
    if not isReload then
        self.toast("This script is going away!" )
    end
end
-- This is required, you need to return the module functions
return Module