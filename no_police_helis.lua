-- No Police Helicopters - 1.3
-- Removes all active police helicopters and their peds
-- Created By Jackz

util.require_natives(1660775568)


local mode = 2
local hasStarted = false

menu.my_root():list_select("Mode", {}, "Delete Helicopters: Delete all helicopters\nUnarmed Helicopters: Removes weapons from helicopter passengers, no shooting", {
    {1, "Disabled"},
    {2, "Delete Helicopters"},
    {3, "Unarmed Helicopters"},
}, mode, function(value, menu_name, prev_value, click_type)
    mode = value
    -- Don't .toast on first load if SCRIPT_SILENT_START
    if SCRIPT_SILENT_START and hasStarted == false then
        hasStarted = true
        return
    end
    util.toast("Changed mode to " .. menu_name)
end)

local heliHash = util.joaat("polmav")
local uheliHash = util.ujoaat("polmav")
local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(heliHash)

while true do
    if mode ~= 1 then
        local pVehicles = entities.get_all_vehicles_as_pointers()
        -- Loop all vehicles, and then get its passengers
        for _, pVehicle in ipairs(pVehicles) do
            local model = entities.get_model_hash(pVehicle)
            if model == heliHash or model == uheliHash then
                local isSafeToDelete = false
                -- Get all the vehicle's passenger peds
                local vehicle = entities.pointer_to_handle(pVehicle)
                for k = -1,seats do
                    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, k)
                    if ped > 0 then
                        -- Vehicle has a player in it, ignore vehicle entirely
                        if PED.IS_PED_A_PLAYER(ped) then
                            isSafeToDelete = false
                            break
                        end
                        if mode == 2 then
                            -- Vehicle has a ped, allow deletion
                            isSafeToDelete = true
                            entities.delete(ped)
                        elseif mode == 3 then
                            WEAPON.REMOVE_ALL_PED_WEAPONS(ped, true)
                        end
                    end
                end
                -- Vehicle has no players and has at least one ped, delete
                if isSafeToDelete and mode == 2 then
                    entities.delete(vehicle)
                end
            end
        end
    end
    util.yield(3000)
end