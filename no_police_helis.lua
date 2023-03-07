-- No Police Helicopters - 1.0
-- Removes all active police helicopters and their peds
-- Created By Jackz

require("natives-1627063482")

local noHelis = false
local noAttackers = false
local noHelisMenu, noHelisAttackersMenu
noHelisMenu = menu.toggle(menu.my_root(), "Delete Helicopters", {"antipoliceheli", "noheli"}, "Enables or disables removal of all active police helicopters", function(on)
    noHelis = on
    if on then
        menu.set_value(noHelisAttackersMenu, false)
    end
end, noHelis)
noHelisAttackersMenu = menu.toggle(menu.my_root(), "No Attackers", {"antipoliceheliattackers", "noheliattack"}, "Enables or disables the removal of any police having weapons on the heli", function(on)
    noAttackers = on
    if on then
        menu.set_value(noHelisMenu, false)
    end
end, noAttackers)

local heli_hash = util.joaat("polmav")
local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(heli_hash)

while true do
    if noHelis or noAttackers then
        local vehicles = entities.get_all_vehicles_as_handles()
        -- Loop all vehicles, and then get its passengers
        for _, vehicle in ipairs(vehicles) do
            if VEHICLE.IS_VEHICLE_MODEL(vehicle, heli_hash) then
                local isSafeToDelete = false
                -- Get all the vehicle's passenger peds
                for k = -1,seats do
                    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, k)
                    if ped > 0 then
                        -- Vehicle has a player in it, ignore vehicle entirely
                        if PED.IS_PED_A_PLAYER(ped) then
                            isSafeToDelete = false
                            break
                        end
                        if noHelis then
                            -- Vehicle has a ped, allow deletion
                            isSafeToDelete = true
                            entities.delete(ped)
                        elseif noAttackers then
                            WEAPON.REMOVE_ALL_PED_WEAPONS(ped, true)
                        end
                    end
                end
                -- Vehicle has no players and has at least one ped, delete
                if isSafeToDelete and noHelis then
                    entities.delete(vehicle)
                end
            end
        end
    end
    util.yield(3500)
end