-- --#P:DEBUG_ONLY
-- require('templates/log')
-- require('templates/common')
-- --#P:END

util.require_natives(1660775568)

local json = require("json")
require("lib/jackzanimatorlib")

local STORE_DIRECTORY = filesystem.store_dir() .. "jackz_animator"
local RECORDINGS_DIR = STORE_DIRECTORY .. "/recordings"
filesystem.mkdirs(RECORDINGS_DIR)

function clearMenuTable(t)
    for k, h in pairs(t) do
        pcall(menu.delete, h)
        t[k] = nil
    end
end
function clearMenuArray(t)
    for _, h in ipairs(t) do
        pcall(menu.delete, h)
    end
    t = {}
end

local Player = {
    menuId = nil,
    pauseControl = nil,
    activeEntityId = nil,
    frameControl = nil
}

local recordingListSubmenus = {}
function loadRecordings(list)
    for _, path in ipairs(filesystem.list_files(RECORDINGS_DIR)) do
        local _, filename = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if not filesystem.is_dir(path) then
            local recordingList
            recordingList = menu.list(list, filename, {}, "", function()
                loadRecordingList(recordingList, path)
            end, function() 
                clearMenuArray(recordingListSubmenus)
            end)
        end
    end
end

function playRecording(entity, data, onFinish)
    PlaybackController.Stop(Player.activeEntityId)
    Player.activeEntityId = entity
    menu.set_value(Player.pauseControl, false)
    menu.set_value(Player.speedControl, 100)

    menu.set_max_value(Player.frameControl, #data.points)
    menu.set_max_value(Player.startFrameControl, #data.points)
    menu.set_max_value(Player.endFrameControl, #data.points)
    menu.set_value(Player.frameControl, 1)
    menu.set_value(Player.startFrameControl, 1)
    menu.set_value(Player.endFrameControl, 1)

    PlaybackController:StartPlayback(entity, data.points, data.interval, {
        speed = 1.0,
        debug = true,
        onFinish = onFinish,
        onFrame = function(frame, time)
            menu.set_value(Player.frameControl, frame)
        end
    })

    PlaybackController:ShowPlayerUI(entity)
    menu.focus(Player.menuId)
end

function loadRecording(filepath)
    local file = io.open(filepath, "r")
    if file then
        local status, data = pcall(json.decode, filepath)
        if status then
            return data
        else
            error("Invalid JSON reading file: " .. data)
        end
    else
        error("Could not read file")
    end
end

function loadRecordingList(list, filepath)
    clearMenuArray(recordingListSubmenus)

    local status, data = loadRecording(filepath)
    if not status or not data then
        util.toast("Could not load recordings: " .. data)
        return
    end

    table.insert(recordingListSubmenus, menu.action(list, "Play (my ped)", {}, "Play the specified animation with your ped", function()
        local myPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        playRecording(myPed, data)
    end))

    table.insert(recordingListSubmenus, menu.action(list, "Play", {}, "Play the specified animation with a cone model", function()
        local hash = util.joaat("prop_roadcone02a")
        local handle = entities.create_object(hash, { x = 0, y = 0, z = 0})
        playRecording(handle, data, function(endingFrame, onTime)
            entities.delete_by_handle(handle)
        end)
    end))

    table.insert(recordingListSubmenus, menu.action(list, "Delete", {}, "Delete this recording", function()
        os.remove(filepath)
        util.toast("Deleted recording")
        clearMenuArray(recordingListSubmenus)
        menu.delete(list)
    end))
end

function menu.list_adv(root, name, command, description, onView, onBack)
    local m
    m = menu.list(root, name, command, description, function()
        onView(m)
    end, onBack)
    return m
end
menu.list_adv(menu.my_root(), "Recordings", {}, "View all your recorded animations", loadRecordings)
local startRecordingMenu
local endRecordingMenu
startRecordingMenu = menu.click_slider(menu.my_root(), "Start new recording", {}, "Starts recording a new recording", 100, 5000, 750, 100, function(interval)
    menu.set_visible(startRecordingMenu, false)
    menu.set_visible(endRecordingMenu, true)
    RecordingController:StartRecording(interval)
end)
endRecordingMenu = menu.action(menu.my_root(), "Stop recording", {}, "Stops the current recording", function()
    menu.set_visible(startRecordingMenu, true)
    menu.set_visible(endRecordingMenu, false)
    local positions, interval = RecordingController:StopRecording()
    local file = io.open(RECORDINGS_DIR .. "/recording-" .. os.clock() * 1000 .. ".json", "w")
    if file then
        file:write(json.encode({
            interval = interval,
            points = positions,
            version = RECORDING_FORMAT_VERSION
        }))
        file:close()
        util.toast("Saved")
    else
        util.toast("Could not save recording to file")
    end
end)
menu.set_visible(endRecordingMenu, false)
Player.menuId = menu.divider(menu.my_root(), "Playback Controls", {}, "")
Player.pauseControl = menu.toggle(menu.my_root(), "Pause", {}, "", function(value)
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:SetPaused(Player.activeEntityId, value)
    else
        util.toast("No playback is active")
    end
end, false)

menu.action(menu.my_root(), "Stop", {}, "Stops the current playback", function()
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:Stop(Player.activeEntityId)
    else
        util.toast("No playback is active")
    end
end)

Player.speedControl = menu.slider(menu.my_root(), "Speed", {}, "", 1, 1, 1, 1, function(frame)
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:SetFrame(Player.activeEntityId, frame)
    else
        menu.set_value(frame, 1)
    end
end)

Player.speedControl = menu.slider_float(menu.my_root(), "Speed", {}, "", 10, 500, 100, 10, function(value)
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:SetSpeed(Player.activeEntityId, value / 100)
    else
        menu.set_value(Player.speedControl, 1)
    end
end)

Player.frameControl = menu.slider(menu.my_root(), "Frame", {}, "", 1, 1, 1, 1, function(frame)
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:SetFrame(Player.activeEntityId, frame)
    else
        menu.set_value(Player.frameControl, 1)
    end
end)

Player.startFrameControl = menu.slider(menu.my_root(), "Start Frame", {}, "The frame the animation will start as (used for repeating)", 1, 1, 1, 1, function(frame)
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:SetFrame(Player.activeEntityId, nil, frame, nil)
    else
        menu.set_value(Player.startFrameControl, 1)
    end
end)

Player.endFrameControl = menu.slider(menu.my_root(), "End Frame", {}, "The frame the animation will start as (used for repeating)", 1, 1, 1, 1, function(frame)
    if PlaybackController:IsInPlayback(Player.activeEntityId) then
        PlaybackController:SetFrame(Player.activeEntityId, nil, nil, frame)
    else
        menu.set_value(Player.endFrameControl , 1)
    end
end)


function shallowCopyArray(t)
    local t2 = {}
    for k, v in ipairs(t) do
      t2[k] = v
    end
    return t2
end
  

local recordInfo = {
    active = false,
    interval = 200,
    data = {},
    entriesCount = 0,
    prevData = {
        weaponModel = nil
    }
}

local playbackInfo = {
    entity = nil,
    active = false,
    speed = 1,
    data = {},
    time = 0,
    prevTime = 0,
    frame = 1,
    interval = 200
}

local SAVE_PATH = filesystem.store_dir() .. "animate_test.json"
menu.action(menu.my_root(), "Save", {}, "", function()
    local file = io.open(SAVE_PATH, "w")
    file:write(json.encode({
        interval = recordInfo.interval,
        points = playbackInfo.data,
        version = RECORDING_FORMAT_VERSION
    }))
    file:close()
    util.toast("Saved")
end)
menu.action(menu.my_root(), "Load", {}, "", function()
    local file = io.open(SAVE_PATH, "r")
    local data = json.decode(file:read("*a"))
    playbackInfo.data = data.points
    playbackInfo.interval = data.interval
    file:close()
    util.toast("Loaded")
end)

menu.slider(menu.my_root(), "Record Interval", {}, "", 1, 10000, recordInfo.interval, 10, function(value)
    recordInfo.interval = value
end)

menu.toggle(menu.my_root(), "Record", {}, "", function(value)
    recordInfo.active = value
    if value then
        recordInfo.data = {}
        recordInfo.entriesCount = 0
        RecordingController:StartRecording()
    else
        local positions, interval = RecordingController:StopRecording()
        playbackInfo.data = positions
        playbackInfo.interval = interval
        util.toast("Stopped recording, " .. #positions .. " frames recorded")
    end
end)

local playToggle = menu.action(menu.my_root(), "Play", {}, "", function(value)
    playbackInfo.active = value
    if value then
        local hash = util.joaat("prop_roadcone02a")
        local handle = entities.create_object(hash, { x = 0, y = 0, z = 0})

        PlaybackController:StartPlayback(handle, playbackInfo.data, playbackInfo.interval, { 
            ["repeat"] = true,
            speed = playbackInfo.speed or 1.0,
            debug = true
        })

        PlaybackController:ShowPlayerUI(handle)

        -- playbackInfo.prevTime = os.clock() * 1000
        -- playbackInfo.time = 0
        -- playbackInfo.frame = 0

        

        -- playbackInfo.entity = handle
        -- util.create_tick_handler(renderUI)
        -- util.create_tick_handler(renderAnimation)
        util.toast("Start of playback")
    else
        PlaybackController:StopAll()
    end
end)

menu.slider_float(menu.my_root(), "Playback Speed", {}, "", 10, 500, 100, 10, function(value)
    playbackInfo.speed = value / 100
end)

-- function _record_frame()
--     local myPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
--     local weaponIndex = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(myPed)
--     local pos = ENTITY.GET_ENTITY_COORDS(myPed)
--     local ang = ENTITY.GET_ENTITY_ROTATION(myPed)
    
--     local weaponModel = ENTITY.GET_ENTITY_MODEL(weaponIndex)
--     if recordInfo.prevData.weaponModel == weaponModel then
--         weaponModel = 0
--     else
--         recordInfo.prevData.weaponModel = weaponModel
--     end
--     recordInfo.entriesCount = recordInfo.entriesCount + 1
--     recordInfo.data[recordInfo.entriesCount] = {
--         pos.x, pos.y, pos.z,
--         ang.x, ang.y, ang.z,
--         weaponModel
--     }
--     util.yield(recordInfo.interval)
--     return recordInfo.active
-- end

-- function stopPlayback()
--     playbackInfo.active = false
--     util.toast("End of recording playback (time = " .. playbackInfo.time .. ", frame = " .. playbackInfo.frame .. ")")
--     playbackInfo.frame = 1
--     playbackInfo.time = 0
--     local myPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
--     TASK.CLEAR_PED_TASKS(myPed)
-- end

-- function renderUI()
--     if playbackInfo.active then
--         directx.draw_rect(0.93, 0.00, 0.25, 0.03, { r = 0.0, g = 0.0, b = 0.0, a = 0.3 })
--         if playbackInfo.speed > 2.0 then
--             directx.draw_texture_client(PLAY_3X_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.90, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
--         elseif playbackInfo.speed > 1.0 then
--             directx.draw_texture_client(PLAY_2X_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.90, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
--         end
--         directx.draw_texture_client(PLAY_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.90, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
--         directx.draw_text_client(0.999, 0.0132, "Frame " .. playbackInfo.frame .. "/" .. #playbackInfo.data, ALIGN_CENTRE_RIGHT, 0.65, { r = 1.0, g = 1.0, b = 1.0, a = 1.0}, true)
--         return true
--     elseif recordInfo.active then
--         directx.draw_rect(0.93, 0.00, 0.25, 0.03, { r = 0.0, g = 0.0, b = 0.0, a = 0.3 })
--         directx.draw_texture_client(RECORD_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.94, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
--         directx.draw_text_client(0.999, 0.0132, "Frame " .. recordInfo.entriesCount, ALIGN_CENTRE_RIGHT, 0.65, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
--         return true
--     end
--     return false
-- end

STREAMING.REQUEST_ANIM_DICT("anim@move_f@grooving@")
STREAMING.REQUEST_ANIM_SET("walk")

-- -- TODO: MOVE TO PLAYBACK CONTROL:
-- local animTick = 0.0
-- function renderAnimation()
--     playbackInfo.frame = math.floor(playbackInfo.time / playbackInfo.interval) + 1
--     local a = playbackInfo.data[playbackInfo.frame]
--     local b = playbackInfo.data[playbackInfo.frame + 1]
--     if not a or not b then
--         menu.set_value(playToggle, false)
--         return false
--     end
--     util.draw_debug_text(" ")
--     util.draw_debug_text("time: " .. playbackInfo.time)
--     util.draw_debug_text("interval: " .. playbackInfo.interval)
--     local timeDelta = playbackInfo.time % playbackInfo.interval / playbackInfo.interval
--     util.draw_debug_text("delta: " .. timeDelta)

--     -- local vec = { x = 0, y = 0, z = 0 }
--     local pX, pY, pZ = _compute_interp_vec(a, b, 1, timeDelta)
--     local rX, rY, rZ = _compute_interp_vec(a, b, 4, timeDelta)
--     -- vec.x = _compute_interp(a[1], b[1], timeDelta)
--     -- vec.y = _compute_interp(a[2], b[2], timeDelta)
--     -- vec.z = _compute_interp(a[3], b[3], timeDelta)
--     -- ENTITY.SET_ENTITY_COORDS_NO_OFFSET(myPed, vec.x, vec.y, vec.z)
--     -- vec.x = _compute_interp(a[4], b[4], timeDelta)
--     -- vec.y = _compute_interp(a[5], b[5], timeDelta)
--     -- vec.z = _compute_interp(a[6], b[6], timeDelta)
--     -- ENTITY.SET_ENTITY_ROTATION(myPed, vec.x, vec.y, vec.z)
--     local now = os.clock() * 1000
--     local frameTime = now - playbackInfo.prevTime

--     -- TODO: use max time for duration
--     ENTITY.SET_ENTITY_COORDS_NO_OFFSET(playbackInfo.entity, pX, pY, pZ)
--     ENTITY.SET_ENTITY_ROTATION(playbackInfo.entity, rX, rY, rZ)
--     -- TASK.TASK_PLAY_ANIM_ADVANCED(playbackInfo.entity, "anim@move_f@grooving@", "walk", pX, pY, pZ, rX, rY, rZ, 1.0, 1.0, frameTime , 5, animTick)
--     animTick = animTick + 0.005
--     if animTick > 1.0 then animTick = 0.0 end
--     util.draw_debug_text("anim tick: " .. animTick)
--     util.draw_debug_text("frame time: " .. frameTime)
--     playbackInfo.time = playbackInfo.time + (playbackInfo.speed * frameTime)
    
--     playbackInfo.prevTime = now
--     return playbackInfo.active
-- end

while true do
    util.yield()
end