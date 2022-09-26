-- No Police Helicopters - 1.0
-- Removes all active police helicopters and their peds
-- Created By Jackz

--[[ By default the following libs are loaded globally:
    1. json.lua as 'json'
    2. natives (version defined by NATIVES_VERSION)
    3. translations as 'lang'
--]]

local Module = {
    version = "1.0.0",
    --[[ Internally loaded variables ---
    - Access these via self. (ex self.root or self.log)
    root -- Populated with the Lua Scripts -> jackzscript root
    name -- Name of the file without the .lua extension
    onlineVersion -- Will be populated on preload,

    log(...) -- Logs to file with prefix [jackzscript] [Module.name] <any>, auto calls tostring() on all vars
    toast(...) -- Toasts to stand with prefix [Module.name] <any>, auto calls tostring() on all vars

    --- Optional, config variables ---
    --- Note: All ___Url variables have the following placeholders:
    --- %name% -> example, %filename% -> example.lua
    webUrl = nil, -- Optional URL such as guilded where users can get more information
    sharedLibs = { 
        mylib = { -- Key is the global name of the lib
            sourceUrl = "", -- URL of file, where to download from
            targetVersion = "" -- Target version of lib, must expose either VERSION or LIB_VERSION
        }
    }
    --]]
}

--- An example internal function that checks for an update, returns a result. Result isn't actually used. 
function Module:isModuleOutdated()
    local result = nil
    async_http.init("jackz.me", "/stand/updatecheck.php?ucv=3&module=no%20police%20helicopters", function(latest)
        if jutil.CompareSemver(self.version, latest) == -1 then
            ModuleManager:DownloadSingle(self.name, "https://jackz.me/stand/modules/" .. self.name .. ".lua")
            result = true
        else
            result = false
        end
    end)
    async_http.dispatch()
    while result == nil do
        util.yield()
    end
    return result
end

--- [REQUIRED] Checks if this module should be loaded, incase you want to do any startup checks.
--- @param isManual boolean True if module was loaded manually, false if automatically loaded
--- @param wasUpdated boolean Has script been updated (see self.previousVersion to get old version)
--- @return boolean TRUE if module should be loaded, false if not
function Module:OnModulePreload(isManual, wasUpdated)
    if MODULE_SOURCE and MODULE_SOURCE == "MANUAL" then
        util.create_thread(function() self:isModuleOutdated() end)
    end
    self.heliHash = util.joaat("polmav")
    self.seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(self.heliHash)
    self.noHelis = true
    return true
end

--- Called once every module has been loaded.
--- @param root MenuHandle A handle to the stand menu list (Lua Scripts -> jackzscript -> Module.name)
function Module:OnReady(root)
    menu.toggle(root, "Delete Helicopters", {"antipoliceheli", "noheli"}, "Enables or disables removal of all active police helicopters", function(on)
        self.noHelis = on
    end, self.noHelis)
end

function Module:OnTick()
    if self.noHelis then
        local vehicles = entities.get_all_vehicles_as_handles()
        -- Loop all vehicles, and then get its passengers
        for _, vehicle in ipairs(vehicles) do
            if VEHICLE.IS_VEHICLE_MODEL(vehicle, self.heliHash) then
                local isSafeToDelete = false
                -- Get all the vehicle's passenger peds
                for k = -1, self.seats do
                    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, k)
                    if ped > 0 then
                        -- Vehicle has a player in it, ignore vehicle entirely
                        if PED.IS_PED_A_PLAYER(ped) then
                            isSafeToDelete = false
                            break
                        end
                        -- Vehicle has a ped, allow deletion
                        isSafeToDelete = true
                        entities.delete(ped)
                    end
                end
                -- Vehicle has no players and has at least one ped, delete
                if isSafeToDelete then
                    entities.delete(vehicle)
                end
            end
        end
    end
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
