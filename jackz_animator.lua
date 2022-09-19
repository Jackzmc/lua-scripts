-- Jackz Vehicle Builder
-- SOURCE CODE: https://github.com/Jackzmc/lua-scripts
local SCRIPT = "jackz_animator"
VERSION = "0.1.0"
local ANIMATOR_LIB_TARGET = "1.3.1"

--#P:DEBUG_ONLY
require('templates/log')
require('templates/common')
--#P:END

--#P:TEMPLATE("log")
--#P:TEMPLATE("_SOURCE")
--#P:TEMPLATE("common")

util.require_natives(1660775568)

local json = require("json")
try_require("jackzanimatorlib")

if ANIMATOR_LIB_VERSION ~= ANIMATOR_LIB_TARGET then
    if SCRIPT_SOURCE == "MANUAL" then
        Log.log("animatorlib current: " .. ANIMATOR_LIB_VERSION, ", target version: " .. ANIMATOR_LIB_TARGET)
        util.toast("Outdated animator library, downloading update...")
        download_lib_update("jackzanimatorlib.lua")
        require("jackzanimatorlib")
        
    else
        util.toast("Outdated lib: 'jackzanimatorlib'")
    end
end

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

    local parent, filename = string.match(filepath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    table.insert(recordingListSubmenus, menu.text_input(list, "Rename", {}, "Rename this recording", function(newName)
        os.rename(filepath, parent .. "/" .. newName)
        util.toast("Renamed recording")
    end, filename))

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

STREAMING.REQUEST_ANIM_DICT("anim@move_f@grooving@")
STREAMING.REQUEST_ANIM_SET("walk")

while true do
    util.yield()
end