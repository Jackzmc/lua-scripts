--[[ By default the following libs are loaded globally:
    1. json.lua as 'json'
    2. natives (version defined by NATIVES_VERSION)
    3. translations as 'lang'
--]]

--[[
AVAILABLE GLOBALS:
Log: debug, log, toast, warn, error, severe methods
json (json.lua library)
JUtil: Some utility functions
l18n: (translations library)
Any natives of version CONFIG.NATIVES_VERSION
MODULE_FILENAME - The name of the actual module's filename, without ext
MODULE_FILENAME_EXT - Same as above, but with the .lua extension
]]

local Module = {
    Name = "Example Script",
    Version = "0.1.0",
    Description = "My example module",
    Author = "Author Here",
    Url = "",
    -- Dependencies have two types: Libraries/Submodules (lua files) and Resources (any other type of file, txt, images, etc).
    -- Both can have shared versions, and both will be automatically downloaded from SourceUrl if provided and non-existent.
    -- Add a _shared suffix to the name to automatically use a shared copy instead of a duplicated local copy.
    -- If the version changes since it was last downloaded (tracked automatically), then a new update will be fetched.

    --[[ Supported parameters for all urls:
        %version%: The version of the lib
        %module% for module name
        %moduleid% will be the value of Module.Id or if does not exist, automatically created based of Module.Name ("My Script" -> my_script)
        %branch% for module branch's
        %filename% for the module's filename
    ]]--
    Dependencies = {
        Libs = {
            jackzvehiclelib = {
                SourceUrl = "https://jackz.me/stand/libs/jackzvehiclelib.lua",
                Version = "0.1.0",
                UpdateCheckUrl = nil -- Optional. If provided will call Module:OnUpdateCheck("jackzvehiclelib", statusCode, body) with results of url
            }
        },
        Resources = {
            vehicles = {
                SourceUrl = "https://jackz.me/stand/resources/vehicles.txt",
                Version = "0.1.0"
            }
        }
    },
    Config = {
        NativesVersion = nil,
        Autoupdater = {
            SourceUrl = "https://raw.githubusercontent.com/Jackzmc/lua-scripts/%branch%/my_example_module.lua",
            UpdateCheckUrl = "https://jackz.me/stand/script/updatecheck.php?module=%moduleid%&branch=%branch%&version=%version%"
        }
    }
    --[[ Internally loaded variables ---
    - Access these via self. (ex self.root or self.log)
    root -- Populated with the Lua Scripts -> jackzscript menu root
    onlineVersion -- Will be populated on preload,
    autoLoaded - True if module was automatically loaded
    ]]--
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
function Module:OnModuleStart(root)
    self.moduleCount = 0
    menu.action(root, "test", {}, "" .. Module.name, function()
        -- Log.log("test")
        Log.toast("hey!")
    end)
end

--- Called if Module.Config.Autoupdater.UpdateCheckUrl is set, returns the raw response body of the url
--- Will not be called if url returns a network error
--- Return nil for no update or return a string of the new version. This will then download from Config.UpdateCheck.SourceUrl
--- @param source string The source of update check, "module" for a module update, or if a dependency, it's provided name.
function Module:OnUpdateCheck(source, statusCode, body)
    if JUtil.CompareSemver(self.Version, body) == 1 then
        -- TODO: Print a changelog!
        return body
    else
        return nil
    end
end

--- Called when a player joins a session
--- @param pid number The player ID of the session
--- @param root number The player's stand menu section handle
function Module:OnPlayerJoin(pid, root)
    local myPlayerMenu = menu.action(root, "Get Player ID", {}, "", function()
        Log.toast("Player's ID: " .. pid)
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