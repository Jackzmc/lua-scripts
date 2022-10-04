-- Test - 1.0
-- Created By Jackz

require("natives-1627063482")
local Scaleforms = require("scaleforms")

local objs = {}
local model = util.joaat("u_m_m_jesus_01")
STREAMING.REQUEST_MODEL(model)
while not STREAMING.HAS_MODEL_LOADED(model) do
    util.yield()
end
function load_model(model)
    local hash = util.joaat(model)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        util.yield()
    end
    return hash
end
local textc_w = { r = 1, g = 1, b = 1, a = 1 }
local textc_b = { r = 8 / 255, g = 159 / 255, b = 246, a = 1}
local textc_g = { r = 0.7, g = 1, b = 0.7, a = 1 }
local textc_r = { r = 1, g = 0.6, b = 0.6, a = 1 }
function draw_text(x, y, text, opts)
    local lines = {}
    for line in string.gmatch(text, "[^\n]+") do
        table.insert(lines, line)
    end
    local align = opts.align or ALIGN_CENTRE_LEFT
    local textSize = opts.textSize or 0.5
    local color = opts.color or { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
    local forceInView = opts.forceView ~= nil and opts.forceView or true
    for i, line in pairs(chunks) do
        directx.draw_text(x, y + (0.02*i), line, align, textSize, color, forceInView)
    end
    --   directx.draw_text(chatPos.x, chatPos.y + (textOffsetSize * i), content, ALIGN_CENTRE_LEFT, textSize, textColor, true)
end
local drunk = false
menu.toggle(menu.my_root(), "drunk", {}, "", function(on)
    local my_ped = PLAYER.PLAYER_PED_ID()
    drunk = on
    if on then
        if not STREAMING.HAS_ANIM_SET_LOADED("move_m@drunk@moderatedrunk") then
            STREAMING.REQUEST_ANIM_SET("move_m@drunk@moderatedrunk")
        end
        PED._SET_FACIAL_CLIPSET_OVERRIDE(my_ped, "facials@gen_female@base")
        PED.SET_PED_MOVEMENT_CLIPSET(my_ped, "move_m@drunk@moderatedrunk", 1.0)
        -- CAM.SET_GAMEPLAY_CAM_SHAKE_AMPLITUDE(155.0)
        CAM.SHAKE_GAMEPLAY_CAM("DRUNK_SHAKE", 5.0)
        util.create_tick_handler(function(_)
            local my_ped = PLAYER.PLAYER_PED_ID()
            AUDIO.SET_PED_IS_DRUNK(my_ped, on)
            PED.SET_PED_MOVE_RATE_OVERRIDE(my_ped, 0.75)
            return drunk
        end)
    else
        AUDIO.SET_PED_IS_DRUNK(my_ped, false)
        PED.RESET_PED_MOVEMENT_CLIPSET(my_ped, 12.0)
    end
end, false)
menu.action(menu.my_root(), "reproession", {}, "", function(_)
    local simeonModel = load_model("ig_siemonyetarian")
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local vehicle = entities.get_user_vehicle_as_handle()()
    local relationshipGroup = memory.alloc(8)
    PED.ADD_RELATIONSHIP_GROUP("_WHEEL_FRANKLIN", relationshipGroup);
    local group = memory.read_int(relationshipGroup)
    memory.free(relationshipGroup)
    PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, group, util.joaat("PLAYER"))

    PED.SET_PED_INTO_VEHICLE(my_ped, vehicle, -2)

    local pos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
    local simeon = entities.create_ped(0, simeonModel, pos, 0)
    PED.SET_PED_INTO_VEHICLE(simeon, vehicle, -1)
    PED.SET_PED_RELATIONSHIP_GROUP_HASH(simeon, group)

    ENTITY.SET_ENTITY_PROOFS(simeon, true, false, false, false, false, false, false, false)
    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(simeon, vehicle, -52, -1106.88, 26, 9999., 262668, 0.)

	PED.SET_PED_KEEP_TASK(simeon, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(simeon, true)
end)
local scaleform = 0
local HACK_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%&()*+-,./\\:;<=>?^[]{}"
local HACK_CHARS_LEN = #HACK_CHARS
function generate_hack_string(len)
    local output = ""
    for _ = 1, len do
        local rand = math.random(HACK_CHARS_LEN)
        output = output .. string.sub(HACK_CHARS, rand, rand)
    end
    return output
end
menu.action(menu.my_root(), "heist.exe", {}, "", function(_)
    local sf = Scaleforms:create("HEIST_MP")
    sf:run("CLEAR_VIEW")
    sf:run("ADD_CREW_MEMBER", 0, "Jackz", 1000, "Hacker", 1, 0, "Ready", 0, 10000000, 100, 0, "?", "Pro", 4)
    sf:run("ADD_CREW_MEMBER", 1, "Heavenira", 101, 2, "Gunner", 0, "Ready", 0, 1000, -10, 0, "?", "Ugly", 4)
    sf:run("ADD_CREW_MEMBER", 2, "Ezra", 101, 3, 1, 0, "Canadian", 0, 1000, 0, 0, "?", "Ugly", 4)
    sf:run("BLANK_CREW_MEMBER", 3)
    sf:run("SET_HEIST_NAME", "Hacking Rockstar")
    sf:run("SET_LEADER_COST", "$1,000,000")
    -- ADD_CREW_MEMBER(_playerSlot, _playerName, _rank, _portrait, _role, _roleIcon, _status, _statusIcon, _cutCash, _cutPercentage, _gangIconEnum, _codename, _outfit, _numPlayers)

    sf:run("INITIALISE_HEISTBOARD")
    sf:run("SHOW_HEISTBOARD")
    sf:run("ADD_LAUNCH_BUTTON")
    sf:activate(3500)
end)
-- function get_business_stat(business, offset)
--     local global = memory.script_global()
--     local c = 0
--     for fudge_x = fudges[1].original - fudges[1].range, fudges[1].original + fudges[1].range do -- 876
--         for fudge_y = fudges[2].original - fudges[2].range, fudges[2].original + fudges[2].range do -- 274
--             for fudge_z = fudges[3].original - fudges[3].range, fudges[3].original + fudges[3].range do -- 183
--                 local out = memory.read_int(memory.script_global(1590908+1+(players.user()*fudge_x)+fudge_y+fudge_z+1+(business*12)+offset))
--                 if out > 1 and out ~= 255 and out ~= 16777215 and out ~= 65535 and out ~= 256 and out <= 200 then
--                     c = c + 1
--                     util.toast(string.format("%d from (%d, %d, %d)", out, fudge_x, fudge_y, fudge_z), 2)
--                 end
--             end
--         end
--     end
--     util.toast("found: " .. c)
-- end
local pending_delete = {}
function find_offset(struct, expected, start)
    local offset = start or 0
    local value = 0
    while value ~= expected do
        offset = offset + 1
        value = memory.read_int(struct + offset)
        if offset > 4096 then
            util.toast("no offset found", 2)
        end
    end
    util.toast("offset: " .. offset, 2)
end

local FIB_MODEL = load_model("mp_m_fibsec_01")
local fibs = {}
local running = false
function GetCoordAround(entity, angle, radius, zOffset, relative)
    if relative then
        local offset = {
            x = -radius * math.sin(angle + 90),
            y = radius * math.cos(angle),
            z = zOffset
        }
        return ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, offset.x, offset.y, offset.z);
    else
        local entityPosition = ENTITY.GET_ENTITY_COORDS(entity, false)
        return {
            x = entityPosition.x - radius * math.sin(angle + 90),
            y = entityPosition.y + radius * math.cos(angle),
            z = entityPosition.z + zOffset
        }
    end
end
local min = memory.alloc(24)
local max = memory.alloc(24)
menu.action(menu.my_root(), "witness protection", {}, "", function(_)
    for _, e in ipairs(fibs) do
        entities.delete(e)
    end
    fibs = {}
    running = false
    local count = 5
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_pos = ENTITY.GET_ENTITY_COORDS(my_ped, true)
    for i = 0, 20 do
        local fib = entities.create_ped(0, FIB_MODEL, my_pos, 0)
        PED.SET_PED_GRAVITY(fib, false)
        PED.SET_PED_CAN_RAGDOLL(fib, false)
        ENTITY.SET_ENTITY_COLLISION(fib, false, true)
        PED.SET_PED_CAN_BE_TARGETTED_BY_PLAYER(fib, players.user(), false)
        local offset = (360 / 20) * i
        table.insert(fibs, { fib, offset })
        count = count - 1
        if count == 0 then
            util.yield()
            count = 5
        end
    end
    
    running = true
    util.create_tick_handler(function(_)
        MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(my_ped), min, max)
        local height = memory.read_vector3(max).z - memory.read_vector3(min).z
        local zCorrection = (-height / 2) + 0.3
        local heading = ENTITY.GET_ENTITY_HEADING(my_ped)
        for _, pair in ipairs(fibs) do
            local coord = GetCoordAround(my_ped, heading - pair[2], 3, zCorrection, true)
            ENTITY.SET_ENTITY_COORDS(pair[1], coord.x, coord.y, coord.z , false, false, false, false)
            ENTITY.SET_ENTITY_HEADING(pair[1], pair[2] + 90)
            TASK.TASK_STAND_STILL(pair[1], 5000)
        end
        util.yield()
        return running
    end)
end)
menu.action(menu.my_root(), "clear witness protection", {}, "", function(_)
    memory.free(min)
    memory.free(max)
    for _, e in ipairs(fibs) do
        entities.delete(e[1])
    end
    fibs = {}
    running = false
end)
local stopVehicles = false
menu.toggle(menu.my_root(), "stop vehicles", {}, "", function(on)
    stopVehicles = on
end, stopVehicles)

menu.action(menu.my_root(), "spawn upside down world", {}, "", function(a)
    
    STREAMING.REQUEST_MODEL(util.joaat("dt1_lod_f1_slod3"))
    STREAMING.REQUEST_MODEL(util.joaat("sp1_lod_slod4"))        
    STREAMING.REQUEST_MODEL(util.joaat("sm_lod_slod3"))        
    STREAMING.REQUEST_MODEL(util.joaat("bh1_lod_slod3"))        
    STREAMING.REQUEST_MODEL(util.joaat("hw1_lod_slod4"))        
    STREAMING.REQUEST_MODEL(util.joaat("id1_lod_slod4"))        
    STREAMING.REQUEST_MODEL(util.joaat("sc1_lod_slod4"))
    while not STREAMING.HAS_MODEL_LOADED(util.joaat("sc1_lod_slod4")) do
        util.yield()
    end
    local z_off = 100.0
    
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("dt1_lod_f1_slod3"), -354.7541 , -800.4896 , 34.08098+z_off, true, false, false))
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("sp1_lod_slod4"), -485.3276 , -1798.339 , 25.84158+z_off, true, false, false))
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("sm_lod_slod3"), -1578.947 , -735.1406 , 61.62763+z_off, true, false, false))
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("bh1_lod_slod3"), -1118.937 , -113.1685 , 91.35326+z_off, true, false, false))
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("hw1_lod_slod4"), 563.4141 , 20.12157 , 91.64003+z_off, true, false, false))
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("id1_lod_slod4"), 1000.994 , -1980.2 , 44.45824+z_off, true, false, false))
    table.insert(objs, OBJECT.CREATE_OBJECT_NO_OFFSET(util.joaat("sc1_lod_slod4"), 224.4198 , -1454.648 , 44.3315+z_off, true, false, false))
    for _, struct in ipairs(objs) do
        ENTITY.SET_ENTITY_ROTATION(struct, 0.0, -180.0, 0.0, 0, true)
    end
end)
util.on_stop(function()
    for _, struct in pairs(objs) do
        entities.delete(struct)
    end
    for _, e in ipairs(pending_delete) do
        entities.delete(e)
    end
    if scaleform > 0 then
        GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(scaleform)
    end
end)

menu.action(menu.my_root(), "Clear Nearby Peds", {}, "", function(on_click)
    local peds = entities.get_all_peds_as_handles()
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(my_ped, 1)

    local count = 0
    for _, ped in ipairs(peds) do
        if not PED.IS_PED_A_PLAYER(ped) then
            local pos2 = ENTITY.GET_ENTITY_COORDS(ped, 1)
            local dist = SYSTEM.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
            if dist <= 10000.0 then
                entities.delete_by_handle(ped)
                count = count + 1
            end
        end
    end
    util.toast("Deleted " .. count .. " peds")
end)

menu.action(menu.my_root(), "Clear Nearby Vehicles", {}, "", function(on_click)
    local vehicles = entities.get_all_vehicles_as_handles()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local count = 0
    for _, vehicle in ipairs(vehicles) do
        local pos2 = ENTITY.GET_ENTITY_COORDS(vehicles, 1)
        local dist = SYSTEM.VDIST(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
        if dist <= 6000.0 then
            util.toast(vehicle .. " " .. dist)
            entities.delete_by_handle(vehicle)
            count = count + 1
        end
    end
    util.toast("Deleted " .. count .. " vehicles")
end)

menu.action(menu.my_root(), "Clear All Objects", {}, "", function(on_click)
    local p = entities.get_all_objects_as_handles()
    for _, object in ipairs(p) do
        entities.delete_by_handle(object)
    end
    util.toast("Deleted " .. #p .. " objects")
end)

menu.action(menu.my_root(), "stop veh", {}, "", function(on_click)
    local peds = entities.get_all_peds_as_handles()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)

    local vehicle = entities.get_user_vehicle_as_handle()()
    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
end)

local src = {
    x = -1179,
    y = -2973, 
    z = 13.9
}
local dest = {
    x = -1519,
    y = -3213,
    z =  21
}
-- table must have:
    -- from: Vector3
    -- to: Vector3
    -- launchVelocity: float
    -- boostVelocity: float
    -- gravity: float

local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
local veh_model = util.joaat("vigilante")
STREAMING.REQUEST_MODEL(veh_model)
while not STREAMING.HAS_MODEL_LOADED(veh_model) do
    util.yield()
end

local active_target = 0
local iAngle = 45
local iVel = 500
local delay = 1000
local ticks = 0
local launchFromSrc = true
menu.toggle(menu.my_root(), "Start", {"yeettest"}, "", function(on)
    local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(target, false)
    if vehicle > 0 then
        target = vehicle
    end
    if on then
        local x = math.cos(iAngle * math.pi/180.0) * iVel
        local z = math.sin(iAngle * math.pi/180.0) * iVel
        started = os.time() 
        active_target = target
        if launchFromSrc then
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(target, src.x, src.y, src.z)
        end
        ENTITY.SET_ENTITY_ROTATION(target, 0, 0, 0)
        ENTITY.SET_ENTITY_VELOCITY(target, x, 0.0, z)
        util.log(string.format("started logging at %f %f delay %f", iAngle, iVel, delay))
        ticks = 0
    else
        local model = ENTITY.GET_ENTITY_MODEL(target)
        local name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
        active_target = 0
        local time = os.time() - started
        util.log(string.format("stopped logging at %f %f delay %f took %f - %s", iAngle, iVel, delay, ticks * delay, name))
        if launchFromSrc then
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(target, src.x, src.y, src.z)
        end
        ENTITY.SET_ENTITY_ROTATION(target, 0, 0, 0)
    end
end)

menu.slider(menu.my_root(), "Angle", {"jangle"}, "", 0, 90, iAngle, 5, function(v)
    iAngle = v
end)

menu.slider(menu.my_root(), "Veloc", {"jvelocity"}, "", 0, 5000, iVel, 1, function(v)
    iVel = v
end)

menu.slider(menu.my_root(), "delay", {"jdelay"}, "", 0, 50000, delay, 50, function(v)
    delay = v
end)

local function launch_entity(entity, destVector)

end

local function get_velocity_to_vector(table) 
    if not table.launchVelocity then
        table.launchVelocity = 50.0
    end
    if not table.boostVelocity then
        table.boostVelocity = 60.0
    end
    if not table.gravity then
        table.gravity = 9.81
    end
    local d = math.sqrt((table.to.x - table.from.x)^2 + (table.to.y - table.from.y)^2) 
    local t = (table.launchVelocity)^2 + 2*table.gravity * (-table.gravity/2*(d/(table.boostVelocity))^2 + table.from.z - table.to.z)
    local W = 1000*(table.launchVelocity - math.sqrt(t))/table.gravity
    util.toast(W)
    util.yield(W)


    return {
        x = (table.to.x - table.from.x) / d,
        y = (table.to.y - table.from.y) / d,
        z = 10
    }
end


menu.action(menu.my_root(), "fuck", {}, "", function(on_click)
    local jesus = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    ENTITY.SET_ENTITY_COORDS(jesus, src.x, src.y, src.z)
    ENTITY.SET_ENTITY_VELOCITY(jesus, 0.0, 0.0, 100.0)
    local v = get_velocity_to_vector({
        from = launchFromSrc and src or my_pos,
        to = dest,
        launchVelocity = 100.0,
        gravity = 6.7
    })
    util.toast(string.format("%.1f %.1f %.1f", v.x, v.y, v.z))
    ENTITY.SET_ENTITY_VELOCITY(jesus, v.x, v.y, v.z)

end)

menu.action(menu.my_root(), "set source pos", {}, "", function(on_click)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    util.toast(string.format("source set to (%.1f, %.1f, %.1f", pos.x, pos.y, pos.z))
    src = pos
end)

menu.action(menu.my_root(), "set dest pos", {}, "", function(on_click)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    util.toast(string.format("dest set to (%.1f, %.1f, %.1f", pos.x, pos.y, pos.z))
    dest = pos
end)

menu.divider(menu.my_root(), "yeet methods")

menu.toggle(menu.my_root(), "on: self | off: src", {}, "", function(on)
    launchFromSrc = not on
end, false)

menu.action(menu.my_root(), "yeet new car", {}, "", function(on_click)
    local my_pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    local jesus = entities.create_vehicle(veh_model, launchFromSrc and src or my_pos, 0)

    ENTITY.SET_ENTITY_VELOCITY(jesus, 0.0, 0.0, 200.0)
    local v = get_velocity_to_vector({
        from = launchFromSrc and src or my_pos,
        to = dest,
        launchVelocity = 200.0,
        gravity = 9.8
    })
    util.toast(string.format("%.1f %.1f %.1f", v.x, v.y, v.z))
    ENTITY.SET_ENTITY_VELOCITY(jesus, v.x, v.y, v.z)

    -- VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 30.0)
end)


menu.action(menu.my_root(), "yeet my car", {}, "", function(on_click)
    local my_pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    local jesus = entities.get_user_vehicle_as_handle()()
    ENTITY.SET_ENTITY_COORDS(jesus, src.x, src.y, src.z)
    -- local jesus = entities.create_ped(1, model, pos, 0)

    -- local pos = ENTITY.GET_ENTITY_COORDS(jesus, 1)
    ENTITY.SET_ENTITY_VELOCITY(jesus, 0.0, 0.0, 200.0)
    local v = get_velocity_to_vector({
        from = launchFromSrc and src or my_pos,
        to = dest,
        launchVelocity = 200.0,
        gravity = 9.8,
        boostVelocity = 100.0
    })
    ENTITY.SET_ENTITY_VELOCITY(jesus, v.x, v.y, v.z)

    -- VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 30.0)
end)


menu.action(menu.my_root(), "yeet jesus", {}, "", function(on_click)
    local my_pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    local jesus = entities.create_ped(1, model, launchFromSrc and src or my_pos, 0)

    ENTITY.SET_ENTITY_VELOCITY(jesus, 0.0, 0.0, 100.0)
    local v = get_velocity_to_vector({
        from = launchFromSrc and src or my_pos,
        to = dest,
        launchVelocity = 100.0,
        gravity = 6.7,
        jesus = jesus
    })
    util.toast(string.format("%.1f %.1f %.1f", v.x, v.y, v.z))
    ENTITY.SET_ENTITY_VELOCITY(jesus, v.x, v.y, v.z)

    -- VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 30.0)
end)

menu.action(menu.my_root(), "yeet myself", {}, "", function(on_click)
    local jesus = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local my_pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
    ENTITY.SET_ENTITY_COORDS(jesus, src.x, src.y, src.z)
    ENTITY.SET_ENTITY_VELOCITY(jesus, 0.0, 0.0, 100.0)
    local v = get_velocity_to_vector({
        from = launchFromSrc and src or my_pos,
        to = dest,
        launchVelocity = 100.0,
        gravity = 6.7
    })
    util.toast(string.format("%.1f %.1f %.1f", v.x, v.y, v.z))
    ENTITY.SET_ENTITY_VELOCITY(jesus, v.x, v.y, v.z)

    -- VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 30.0)
end)




local redbox = {
    r = 1,
    g = 0,
    b = 0,
    a = 1
}

local flash = 0
local last_vehicle = 0
local is_last_valid = false
-- util.trigger_script_event(int session_player_bitflags, table<any, int> data)
local tick = 0
while true do
    if active_target > 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(active_target, 1)
        local vel = ENTITY.GET_ENTITY_VELOCITY(active_target)
        util.log(string.format("%.3f %.3f %.3f %.3f %.3f %.3f", pos.x - src.x, pos.y - src.y, pos.z - src.z, vel.x, vel.y, vel.z))
        ticks = ticks + 1
        util.yield(delay)
    elseif stopVehicles then
        if tick >= 1 then
            VEHICLE.SET_VEHICLE_DENSITY_MULTIPLIER_THIS_FRAME(1)
            local me = PLAYER.PLAYER_PED_ID()
            local my_pos = ENTITY.GET_ENTITY_COORDS(me)
            local my_heading = ENTITY.GET_ENTITY_HEADING(entities.get_user_vehicle_as_handle())
            local peds = entities.get_all_peds_as_handles()
            local dists = {}
            local min = my_heading - 15.0
            local max = my_heading + 15.0
            for a, ped in ipairs(peds) do
                if not PED.IS_PED_A_PLAYER(ped) then
                    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if vehicle > 0 then
                        local pos = ENTITY.GET_ENTITY_COORDS(ped, 1)
                        local offset = ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(ped, my_pos.x, my_pos.y, my_pos.z)
                        local safe_spot_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 3, 0, 0)
                        local has_safe_spot = PATHFIND.IS_POINT_ON_ROAD(safe_spot_pos.x, safe_spot_pos.y, safe_spot_pos.z, 0)
                        local dist = SYSTEM.VDIST2(my_pos.x, my_pos.y, my_pos.z, pos.x, pos.y, pos.z)
                        local status = TASK.GET_SCRIPT_TASK_STATUS(ped, 0x81B4D53A)
                        local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
                        local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
                        local zdiff = 0
                        -- Find safe spot:
                        for x = 1.0, 5.0 do
                            local p = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, x, 0, 0)
                            success, z = util.get_ground_z(p.x, p.y, p.z + 5.0)
                            if success then
                                local diff = z - p.z
                                if zdiff < diff then
                                    zdiff = diff
                                end
                            end
                        
                        end
                        if dist <= 100000 and heading > min and heading < max then
                            table.insert(dists, {
                                a = a, 
                                ped = ped,
                                dist = dist,
                                status = status,
                                heading = heading,
                                vehicle = vehicle,
                                vel = vel,
                                offset = offset,
                                has_safe_spot = has_safe_spot,
                                zdiff = zdiff
                            })
                        end
                    end
                end
            end
            table.sort(dists, function(a, b) return a.dist < b.dist end)
            for i, pair in ipairs(dists) do
                if pair.dist < 100 or pair.offset.y < 5 and pair.offset.y > -60.0 and math.abs(pair.offset.z) <= 20 and math.abs(pair.offset.x) <= 4 and (pair.vel.x ~= 0.0 or pair.vel.y ~= 0.0) then
                    
                    if pair.status > 1 then
                        directx.draw_text(0.3, 0.7 + (0.02*i), string.format("ped %2d - %8.0f m^2 - %2d     %2.1f OFFSET %2.1f %2.1f %2.1f zdiff %2.1f [active]", pair.a, pair.dist, pair.status, pair.heading, pair.offset.x, pair.offset.y, pair.offset.z, pair.zdiff), 0, 0.5, textc_g, false)
                        util.create_thread(function() 
                            if pair.has_safe_spot then
                                TASK.TASK_VEHICLE_TEMP_ACTION(pair.ped, pair.vehicle, 26, 400)
                                util.yield(400)
                            end
                            TASK.TASK_VEHICLE_TEMP_ACTION(pair.ped, pair.vehicle, 6, 4000)

                        end)
                        
                    elseif pair.has_safe_spot then
                        directx.draw_text(0.3, 0.7 + (0.02*i), string.format("ped %2d - %8.0f m^2 - %2d     %2.1f OFFSET %2.1f %2.1f %2.1f zdiff %2.1f [safe spot]", pair.a, pair.dist, pair.status, pair.heading, pair.offset.x, pair.offset.y, pair.offset.z, pair.zdiff), 0, 0.5, textc_g, false)
                    else
                        directx.draw_text(0.3, 0.7 + (0.02*i), string.format("ped %2d - %8.0f m^2 - %2d     %2.1f OFFSET %2.1f %2.1f %2.1f zdiff %2.1f", pair.a, pair.dist, pair.status, pair.heading, pair.offset.x, pair.offset.y, pair.offset.z, pair.zdiff), 0, 0.5, textc_g, false)
                    end
                elseif pair.dist <= 10000 then
                    if pair.vel.x == 0 and pair.vel.y == 0 then
                        directx.draw_text(0.3, 0.7 + (0.02*i), string.format("ped %2d - %8.0f m^2 - %2d    %2.1f OFFSET %2.1f %2.1f %2.1f zdiff %2.1f [stopped]", pair.a, pair.dist, pair.status, pair.heading, pair.offset.x, pair.offset.y, pair.offset.z, pair.zdiff), 0, 0.5, textc_r, false)
                    else
                        directx.draw_text(0.3, 0.7 + (0.02*i), string.format("ped %2d - %8.0f m^2 - %2d    %2.1f OFFSET %2.1f %2.1f %2.1f zdiff %2.1f", pair.a, pair.dist, pair.status, pair.heading, pair.offset.x, pair.offset.y, pair.offset.z, pair.zdiff), 0, 0.5, textc_r, false)
                    end
                end
            end
            tick = 0
        end
        tick = tick + 1
        -- directx.draw_text(0.93, 0.85, string.format("src (%.1f, %.1f, %.1f)\ndest (%.1f, %.1f, %.1f)", src.x, src.y, src.z, dest.x, dest.y, dest.z), 1, 0.5, textc_w, false)
    end
    util.yield()
    local player = players.user()
    if PAD.IS_CONTROL_JUST_PRESSED(2, 24) then
        local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
        local pos = ENTITY.GET_ENTITY_COORDS(my_ped, 1)
        local pos2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(my_ped, 0.0, 200.0, 0)
        local ray = SHAPETEST.START_SHAPE_TEST_LOS_PROBE(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z, 2, 0, 4)
        -- local ray = SHAPETEST.START_SHAPE_TEST_CAPSULE(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z, 20.0, 10, 0, 7)
        local p_bool = memory.alloc(8)
        local p_endPos = memory.alloc(24)
        local p_surfaceNormal = memory.alloc(24)
        local p_entityHit = memory.alloc(8)

        while SHAPETEST.GET_SHAPE_TEST_RESULT(ray, p_bool, p_endPos, p_surfaceNormal, p_entityHit) == 1 do
            util.yield()
        end
        local hit = memory.read_byte(p_bool)
        if hit == 1 then
            util.toast("hit")
            local ent = memory.read_int(p_entityHit)
            util.toast(ent)
            local endVec = memory.read_vector3(p_endPos)
            if ENTITY.DOES_ENTITY_EXIST(ent) then
                VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(ent, 255, 105, 180)
                VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(ent, 255, 105, 180)
                util.toast("ded")
                -- FIRE.ADD_EXPLOSION(endVec.x, endVec.y, endVec.z + 1.0, 26, 60, true, true, 0.0)
            end
        end
        memory.free(p_bool)
        memory.free(p_endPos)
        memory.free(p_surfaceNormal)
        memory.free(p_entityHit)
    end
    -- if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
    --     PAD._SET_CONTROL_NORMAL(2, 176, 1.0)
    --     util.yield(100)
    --     PAD._SET_CONTROL_NORMAL(2, 177, 1.0)
    -- end
    --

    --GRAPHICS.DRAW_MARKER(21, src.x, src.y, src.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 200, true, true, 2, true, "NULL", "NULL", true)
    -- local vehicle = entities.get_user_vehicle_as_handle()()
    -- if last_vehicle == vehicle then
    --     if is_last_valid then
    --         local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
    --         local pos = ENTITY.GET_ENTITY_COORDS(vehicle)
    --         local hasGround, groundZ = util.get_ground_z(pos.x, pos.y, pos.z)
    --         if not hasGround then
    --             groundZ = -1.0
    --         end
    --         local clearance = hasGround and pos.z - groundZ or -1
    --         local landing_state = VEHICLE.GET_LANDING_GEAR_STATE(vehicle)
    --         if hasGround and flash <= 20 then
    --             if landing_state > 2 and clearance < 70.0 then
    --                 directx.draw_rect(0.18, 0.045, 0.042, 0.03, redbox)
    --                 directx.draw_text(0.2, 0.05, "TERRAIN", 1, 0.5, textc, false)
    --             end
    --         end
    --         flash = flash + 1
    --         if flash > 40 then
    --             flash = 0
    --         end
    --         local rot = ENTITY.GET_ENTITY_ROTATION(vehicle)
    --         util.draw_debug_text(string.format("veh (%.1f, %.1f, %.1f) ground %.1f clearance %.1f\nheading %f rot(%.1f, %.1f, %.1f)", pos.x, pos.y, pos.z, groundZ, clearance, heading, rot.x, rot.y, rot.z))
    --     end
    -- elseif vehicle > 0 then
    --     is_last_valid = true --VEHICLE.IS_THIS_MODEL_A_PLANE(ENTITY.GET_ENTITY_MODEL(vehicle))
    --     last_vehicle = vehicle
    -- end

	-- local argStruct = 0
	-- local size = 0
    -- local events = SCRIPT.GET_NUMBER_OF_EVENTS(0)
    -- if events > 0 then
    --     for x = 0,events do
	-- 	    directx.draw_text(0.2, 0.31 + (0.02 * x), string.format("Event %d / %d", x, events), 1, 0.5, textc, false)
    --         local event = SCRIPT.GET_EVENT_AT_INDEX(0, x)
	--         if SCRIPT.GET_EVENT_DATA(0, event, argStruct, 1) then
	-- 	        directx.draw_text(0.2, 0.5 + (0.2*x), string.format("Event %d [%d] - %d", x, event, PLAYER.GET_PLAYER_NAME(argStruct[1])), 1, 0.5, textc, false)
    --             for i = 0,5 do
	-- 		        directx.draw_text(0.2, 0.8, string.format("Args[%i]: %i", i, argStruct[i]), 1, 0.5, textc, false)
	-- 	        end
    --         else 
    --             directx.draw_text(0.2, 0.5 + (0.2*x), string.format("Event %d [%d] - %s", x, event, "NONE"), 1, 0.5, textc, false)
    --         end
    --     end
    -- end
end