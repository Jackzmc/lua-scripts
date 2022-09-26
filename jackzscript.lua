-- Created By Jackz
SCRIPT_NAME = "jackzscript"
VERSION = "0.1.0"
NATIVES_VERSION = 1627063482

--#P:MANUAL_ONLY
async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT_NAME .. "&v=" .. VERSION, function(result)
    local chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        -- Remove this block (lines 15-32) to disable auto updates
        async_http.init("jackz.me", "/stand/get-lua.php?script=" .. SCRIPT_NAME .. "&source=manual", function(result)
            local file = io.open(filesystem.scripts_dir()  .. SCRIPT_RELPATH, "w")
            file:write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            file:close()
            util.toast(SCRIPT_NAME .. " was automatically updated to V" .. chunks[2], TOAST_ALL)
            util.stop_script()
        end, function()
            util.toast(SCRIPT_NAME .. ": Failed to automatically update to V" .. chunks[2] .. ".\nPlease download latest update manually.\nhttps://jackz.me/stand/get-latest-zip", 2)
            util.stop_script()
        end)
        async_http.dispatch()
    end
end)
async_http.dispatch()
--#P:END

-- Loads into global scope
jutil = require('jackzscript\\core\\util')
Versions = require('jackzscript\\core\\version')
Libs = require('jackzscript\\core\\libs')
while not Libs.loadComplete do
    util.yield()
end
Versions:Load()

local STATE_FILE_PATH = filesystem.store_dir() .. "jackzscript.state.txt"
jutil.TouchFile(STATE_FILE_PATH)
stateFile = io.open(STATE_FILE_PATH, "r+")

util.require_natives(NATIVES_VERSION)
lang.add_language_selector_to_menu(menu.my_root())

enabledModules = jutil.ReadKV(stateFile)

local ModuleManager = require('jackzscript\\core\\modules') --requires natives

if filesystem.exists(ModuleManager.DIRECTORY) and filesystem.is_dir(ModuleManager.DIRECTORY) then
    ModuleManager:init()
    ModuleManager:ReloadAllModules()
else
    util.toast(SCRIPT_NAME .. ": No modules have been installed.\nInstall modules at \nhttps://jackz.me/stand/jackzscript/help#modules. Goodbye.")
    menu.hyperlink(menu.my_root(), "Install Modules (You have none)", "https://jackz.me/stand/jackzscript/help#modules")
end

util.on_stop(function()
    -- util.write_colons_file(filesystem.store_dir() .. "jackzscript.state.txt", enabledModules)
    ModuleManager:Shutdown()
    Versions:Save()
    Versions.file:close()
    stateFile:close()
end)

local tick = 0
while true do
    for _, mod in ipairs(ModuleManager.Modules) do
        mod:OnTick(tick)
    end
    tick = tick + 1
    util.yield()
end