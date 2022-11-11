-- Created By Jackz
SCRIPT_NAME = "jackzscript"
VERSION = "0.1.0"
NATIVES_VERSION = 1627063482

--#P:DEBUG_ONLY
require('templates/log')
require('templates/common')
--#P:END

--#P:TEMPLATE("log")
--#P:TEMPLATE("_SOURCE")
--#P:TEMPLATE("common")

-- Loads into global scope
JUtil = require('jackzscript\\core\\util')
Versions = require('jackzscript\\core\\version')
Libs = require('jackzscript\\core\\libs')
while not Libs.loadComplete do
    util.yield()
end
Versions:Load()

local STATE_FILE_PATH = filesystem.store_dir() .. "jackzscript.state.txt"
JUtil.TouchFile(STATE_FILE_PATH)
stateFile = io.open(STATE_FILE_PATH, "r+")

util.require_natives(NATIVES_VERSION)
lang.add_language_selector_to_menu(menu.my_root())

enabledModules = JUtil.ReadKV(stateFile)

local inspect = require('inspect')
local ____lualib = require("jackzscript/lualib_bundle")
local __TS__New = ____lualib.__TS__New
local ModuleManager = require('jackzscript\\core\\ModuleManager').default --requires natives
local modules
local modulesCount = 0

if filesystem.exists(ModuleManager.DIRECTORY) and filesystem.is_dir(ModuleManager.DIRECTORY) then
    modules = __TS__New(ModuleManager)
    modulesCount = modules:ReloadAllModules()
end
if modulesCount == 0 then
    util.toast(SCRIPT_NAME .. ": No modules have been installed.\nInstall modules at \nhttps://jackz.me/stand/jackzscript/help#modules.")
    menu.hyperlink(menu.my_root(), "No Modules Installed: Install Modules", "https://jackz.me/stand/jackzscript/help#modules", "Get modules here")
end

util.on_stop(function()
    -- util.write_colons_file(filesystem.store_dir() .. "jackzscript.state.txt", enabledModules)
    modules:Shutdown()
    Versions:Save()
    Versions.file:close()
    stateFile:close()
end)

local tick = 0
while true do
    tick = tick + 1
    util.yield()
end