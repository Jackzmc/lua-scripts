local RESOURCES_DIR = filesystem.resources_dir() .. "/jackz_animator"
if not filesystem.exists(RESOURCES_DIR) then
    error("Missing jackz_animator resources folder")
end
local PLAY_2X_ICON = directx.create_texture(RESOURCES_DIR .. "/forward.png")
local PLAY_3X_ICON = directx.create_texture(RESOURCES_DIR .. "/forward-fast.png")
local PLAY_ICON =  directx.create_texture(RESOURCES_DIR .. "/play.png")
local RECORD_ICON = directx.create_texture(RESOURCES_DIR .. "/record.png")
-- https://www.flaticon.com/free-icons/rec Rec icons created by kliwir art - Flaticon
local ICON_SIZE = 0.0070

RECORDING_FORMAT_VERSION = 1

RecordingController = {
    active = false,
    positions = {},
    positionsCount = 0,
    interval = 750,
    prevData = {
        weaponModel = nil
    }
}

-- Starts a recording at the specified interval
function RecordingController.StartRecording(self, recordingInterval)
    if not recordingInterval then recordingInterval = 750 end
    self.active = true
    self.positions = {}
    self.positionsCount = 0
    self.interval = recordingInterval
    util.create_tick_handler(function() 
        self:_renderUI()
        self:_recordFrame()
    end)
end

function RecordingController.PauseRecording(self)
    self.active = false
end

function RecordingController.ResumeRecording(self)
    self.active = true
end

-- Stops a recording and returns the positions and interval of the recording
function RecordingController.StopRecording(self)
    self.active = false
    return self.positions, self.interval
end

function RecordingController._renderUI(self)
    directx.draw_rect(0.93, 0.00, 0.25, 0.03, { r = 0.0, g = 0.0, b = 0.0, a = 0.3 })
    directx.draw_texture_client(RECORD_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.94, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
    directx.draw_text_client(0.999, 0.0132, "Frame " .. self.positionsCount, ALIGN_CENTRE_RIGHT, 0.65, { r = 1.0, g = 1.0, b = 1.0, a = 1.0})
    return self.active
end

function RecordingController._recordFrame(self)
    local myPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local weaponIndex = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(myPed)
    local pos = ENTITY.GET_ENTITY_COORDS(myPed)
    local ang = ENTITY.GET_ENTITY_ROTATION(myPed)
    
    local weaponModel = ENTITY.GET_ENTITY_MODEL(weaponIndex)
    if self.prevData.weaponModel == weaponModel then
        weaponModel = 0
    else
        self.prevData.weaponModel = weaponModel
    end
    self.positionsCount = self.positionsCount + 1
    self.positions[self.positionsCount ] = {
        pos.x, pos.y, pos.z,
        ang.x, ang.y, ang.z,
        weaponModel
    }
    util.yield(self.interval)
    return self.active
end


PlaybackController = {
    animations = {}, activePlayer = nil
}

--[[ 
Value is the defaults,     
Options: {
    speed = 1.0, -- Starting speed
    startFrame = 1,
    endFrame = #positions,
    debug = false,
    repeat = false,
    onFinish = function(endingFrame, time)
    onFrame = function(frame, time)
}]]
function PlaybackController.StartPlayback(self, entity, positions, recordInterval, options)
    if not entity or not positions or not recordInterval then return error("Missing a required parameter", 2) end
    if not options then options = {} end
    if #positions == 0 then
        return
    end
    if not options.startFrame then options.startFrame = 1 end
    local entityType = 0
    if ENTITY.IS_ENTITY_A_PED(entity) then
        entityType = 1
    end
    self.animations[entity] = {
        active = true,
        entity = entity,
        entityType = entityType,
        positions = shallowCopyArray(positions),
        time = recordInterval * (options.startFrame - 1),
        prevTime = os.clock() * 1000,
        speed = options.speed or 1.0,
        frame = options.startFrame,
        endFrame = options.endFrame or #positions - 1,
        interval = recordInterval,
        animTick = 0.0,
        debug = options.debug,
        ["repeat"] = options["repeat"],
        onFinish = options.onFinish,
        onFrame = options.onFrame
    }
end
function PlaybackController.IsInPlayback(self, entity)
    if entity == nil then return false end
    return self.animations[entity] ~= nil
end
function PlaybackController.ShowPlayerUI(self, entity)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        self.activePlayer = entity
    end
end
function PlaybackController.SetSpeed(self, entity, speed)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        self.animations[entity].speed = speed
    end
end
-- Returns the current frame and the ending frame
function PlaybackController.GetFrame(self, entity)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        return self.animations[entity].frame, self.animations[entity].endFrame
    end
end

function PlaybackController.SetFrame(self, entity, frame)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    elseif frame <= 0 then
        error("Frame is out of range. Minimum of 1")
    elseif frame > self.animations[entity].endFrame then
        error("Frame is out of range. Range must be between 1 and " .. self.animations[entity].endFrame)
        self.animations[entity].frame = frame
        self.animations[entity].time = self.animations[entity].interval * (frame - 1)
    end
end

function PlaybackController.Pause(self, entity)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        self.animations[entity].active = false
    end
end
function PlaybackController.Resume(self, entity)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        self.animations[entity].active = true
    end
end
function PlaybackController.SetPaused(self, entity, value)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        self.animations[entity].active = value or false
    end
end
function PlaybackController.IsPaused(self, entity)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        return not self.animations[entity].active
    end
end

function PlaybackController.Stop(self, entity)
    if not self.animations[entity] then
        error("No running playback for specified entity")
    else
        self:_stop(entity)
    end
end
function PlaybackController.StopAll(self)
    for entity, _ in pairs(self.animations) do
        self:_stop(entity)
    end
end
function PlaybackController._stop(self, entity)
    TASK.CLEAR_PED_TASKS(entity)
    if self.activePlayer == entity then
        self.activePlayer = nil
    end
    util.toast(entity .. ": End of animation on frame " .. self.animations[entity].frame .. " time " .. self.animations[entity].time)
    if self.animations[entity].onFinish then
        self.animations[entity].onFinish(self.animations[entity].frame, self.animations[entity].time)
    end
    self.animations[entity] = nil
end
function PlaybackController._DisplayPlayerInfo(self, entity, offset)
    directx.draw_rect(0.93, 0.00, 0.25, 0.03, { r = 0.0, g = 0.0, b = 0.0, a = 0.3 })
    local animation = self.animations[entity]
    if animation.speed > 2.0 then
        directx.draw_texture_client(PLAY_3X_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.90, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
    elseif animation.speed > 1.0 then
        directx.draw_texture_client(PLAY_2X_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.90, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
    end
    directx.draw_texture_client(PLAY_ICON, ICON_SIZE, ICON_SIZE, 0, 0, 0.90, 0.0, 0, 1.0, 1.0, 1.0, 1.0)
    directx.draw_text_client(0.999, 0.0132, "Frame " .. animation.frame .. "/" .. #animation.positions, ALIGN_CENTRE_RIGHT, 0.65, { r = 1.0, g = 1.0, b = 1.0, a = 1.0}, true)
end
function PlaybackController._ProcessFrame(self)
    local now = os.clock() * 1000
    if self.activePlayer then
        self:_DisplayPlayerInfo(self.activePlayer)
    end
    for entity, animation in pairs(self.animations) do
        animation.frame = math.floor(animation.time / animation.interval) + 1
        local a = animation.positions[animation.frame]
        local b = animation.positions[animation.frame + 1]
        if animation.frame <= animation.endFrame and b then
            local timeDelta = animation.time % animation.interval / animation.interval
            local pX, pY, pZ = computeInterpVec(a, b, 1, timeDelta)
            local rX, rY, rZ = computeInterpVec(a, b, 4, timeDelta)
            local frameTime = now - animation.prevTime

            if animation.debug then
                util.draw_debug_text(" ")
                util.draw_debug_text("process " .. entity)
                util.draw_debug_text("time: " .. animation.time)
                util.draw_debug_text("interval: " .. animation.interval)
                util.draw_debug_text("delta: " .. timeDelta)
                util.draw_debug_text("frame time: " .. frameTime)
            end

            if animation.entityType == 0 then
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(animation.entity, pX, pY, pZ)
                ENTITY.SET_ENTITY_ROTATION(animation.entity, rX, rY, rZ)
            elseif animation.entityType == 1 then
                animation.animTick = animation.animTick + 0.005
                if animation.animTick > 1.0 then animation.animTick = 0.0 end
                TASK.TASK_PLAY_ANIM_ADVANCED(animation.entity, "anim@move_f@grooving@", "walk", pX, pY, pZ, rX, rY, rZ, 1.0, 1.0, frameTime , 5, animation.animTick)
            end
            if animation.onFrame then
                animation.onFrame(animation.frame, animation.time)
            end
            animation.time = animation.time + (animation.speed * frameTime)
            animation.prevTime = now
        else
            if animation["repeat"] then
                animation.time = 0
                animation.prevTime = now
                animation.frame = 1
            else
                self:_stop(entity)
            end
        end
    end
end

function computeInterp(a, b, timeDelta)
    return a + (b - a) * timeDelta
end
function computeInterpVec(a, b, startIndex, timeDelta)
    local x = a[startIndex] + (b[startIndex] - a[startIndex]) * timeDelta
    startIndex = startIndex + 1
    local y = a[startIndex] + (b[startIndex] - a[startIndex]) * timeDelta
    startIndex = startIndex + 1
    local z = a[startIndex] + (b[startIndex] - a[startIndex]) * timeDelta

    return x, y, z
end


while true do
    PlaybackController:_ProcessFrame()
    util.yield()
end