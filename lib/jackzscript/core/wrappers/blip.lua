local Blip = {
    isOutlined = false
}
function Blip:FromEntity(entity)
    return Blip:FromId(HUD.GET_BLIP_FROM_ENTITY(entity))
end
function Blip:FromId(handle)
    if HUD.DOES_BLIP_EXIST(handle) then
        local this = {}
        this.blip = handle
        setmetatable(this, Blip)
        Blip.__index = Blip
        return this
    else
        error("Blip handle is invalid")
    end
end
function Blip:CreateBlipForArea(x, y, z, width, height)
    if not x or not y or not z then
        return error("One or more coordinates are invalid")
    end
    if not width then width = 1 end
    if not height then height = 1 end
    local blip = HUD._ADD_BLIP_FOR_AREA(x, y, z, width, height)
    return Blip.FromId(blip)
end
function Blip:CreateBlipForCoords(x, y, z)
    if not x or not y or not z then
        return error("One or more coordinates are invalid")
    end
    local blip = HUD.ADD_BLIP_FOR_COORD(x, y, z)
    return Blip:FromId(blip)
end
function Blip:CreateBlipForEntity(entity)
    if entity == nil or entity == 0 or not ENTITY.DOES_ENTITY_EXIST(entity) then
        return error("Entity provided is invalid")
    end
    local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
    return Blip:FromId(blip)
end
function Blip:CreateBlipForPickup(pickup)
    if pickup == nil or pickup == 0 then
        return error("Pickup provided is invalid")
    end
    local blip = HUD.ADD_BLIP_FOR_PICKUP(pickup)
    return Blip:FromId(blip)
end
function Blip:CreateBlipCircle(x, y, z, radius)
    if not x or not y or not z then
        return error("One or more coordinates are invalid")
    end
    if not radius then radius = 1.0 end
    local blip = HUD.ADD_BLIP_FOR_RADIUS(x, y, z, radius)
    return Blip:FromId(blip)
end
function Blip:CreateBlipRaceGallery(x, y, z)
    if not x or not y or not z then
        return error("One or more coordinates are invalid")
    end
    local blip = HUD._RACE_GALLERY_ADD_BLIP(x, y, z)
    return Blip:FromId(blip)
end

function Blip:SetAlpha(alphaLevel)
    HUD.SET_BLIP_ALPHA(self.blip, alphaLevel)
    return self
end
function Blip:SetScale(scale)
    HUD.SET_BLIP_SCALE(self.blip, scale)
    return self
end
function Blip:StartFlashing(interval, duration)
    HUD.SET_BLIP_FLASHES(self.blip, true)
    self:SetFlashingInterval(interval)
    if duration then
        self:SetFlashingDuration(duration)
    end
    return self
end
-- Interval is in ms
function Blip:SetFlashingInterval(interval)
    HUD.SET_BLIP_FLASH_INTERVAL(self.blip, interval)
    return self
end
function Blip:SetFlashingDuration(duration)
    HUD.SET_BLIP_FLASH_TIMER(self.blip, duration)
    return self
end
function Blip:StartFlashing2(interval, timeout)
    self:StartFlashing(interval, timeout)
    HUD.SET_BLIP_FLASHES_ALTERNATIVE(self.blip, true)
    return self
end
function Blip:StopFlashing()
    HUD.SET_BLIP_FLASHES(self.blip, false)
end
function Blip:IsFlashing()
    return HUD.IS_BLIP_FLASHING(self.blip)
end

function Blip:SetLabel(text)
    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_SET_BLIP_NAME(self.blip)
    return self
end

function Blip:SetSprite(sprite)
    HUD.SET_BLIP_SPRITE(self.blip, sprite)
    return self
end

function Blip:SetColour(colourId)
    HUD.SET_BLIP_COLOUR(self.blip, colourId)
    return self
end
function Blip:SetColourSecondary(r, g, b)
    HUD.SET_BLIP_SECONDARY_COLOUR(self.blip, r, g, b)
    return self
end
function Blip:SetCoords(x, y, z)
    HUD.SET_BLIP_COORDS(self.blip, x, y, z)
    return self
end
function Blip:SetShortRanged(value)
    HUD.SET_BLIP_AS_SHORT_RANGE(self.blip, value)
    return self
end
function Blip:IsShortRanged()
    return HUD.IS_BLIP_SHORT_RANGE(self.blip)
end

function Blip:Pulse()
    HUD.PULSE_BLIP(self.blip)
end

function Blip:SetRotation(rotation)
    HUD.SET_BLIP_ROTATION(self.blip, math.ceil(rotation))
    return self
end

function Blip:SetAsFriendly(value)
    if value == nil then value = true end
    HUD.SET_BLIP_AS_FRIENDLY(value)
    return self
end
function Blip:SetAsEnemy(value)
    if value == nil then value = true end
    HUD.SET_BLIP_AS_FRIENDLY(not value)
    return self
end

function Blip:SetPriority(priority)
    HUD.SET_BLIP_PRIORITY(self.blip, priority)
    return self
end

function Blip:SetOutlined(value)
    self.isOutlined = value
    HUD.SET_RADIUS_BLIP_EDGE(value)
    return self
end

function Blip:IsOutlined()
    return self.isOutlined
end

function Blip:Delete()
    util.remove_blip(self.blip)
    self = nil
end
return Blip