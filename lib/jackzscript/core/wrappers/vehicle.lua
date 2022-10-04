local Vehicle = {
    Health =
}

function Vehicle.FromHandle(handle)
    if ENTITY.DOES_ENTITY_EXIST(handle) then
        local this = {}
        this.handle = handle
        setmetatable(this, Vehicle)
        return this
    else
        return nil
    end
end
-- Creates a new scaleform, waits for it to load and returns its instance
function Vehicle.SpawnByName(name, pos, heading)
    if not name then
        return error("Vehicle name is required")
    end
    local model = util.joaat(name)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
    return Vehicle.Spawn(model, pos, heading)
end
-- Returns nil on invalid model
function Vehicle.Spawn(model, pos, heading)
    if not model then
        return error("Vehicle model is required")
    end
    if not pos then pos = { x = 0, y = 0, z = 0} end
    if not heading then heading = 0 end
    if not STREAMING.IS_MODDEL_VALID(model) then
        return nil
    end
    JUtil.LoadModel(model)
    local handle = util.create_vehicle(model, pos, heading)
    return Vehicle.FromHandle(handle)
end

function Vehicle:Exists()
    return ENTITY.DOES_ENTITY_EXIST(self.handle)
end

function Vehicle:Health() 
    return self.health
end

function Vehicle:Teleport(x, y, z)
    if not x or not y or not z then error("1 or more coordinates are nil") end
    ENTITY.SET_ENTITY_COORDS(self.handle, x, y, z)
end

function Vehicle:TeleportTo(targetHandle)
    if not targetHandle then error("Target handle parameter is nil") end
    local pos = ENTITY.GET_ENTITY_COORDS(targetHandle)
    ENTITY.SET_ENTITY_COORDS(self.handle, pos.x, pos.y, pos.z)
end

function Vehicle:Delete()
    entities.delete_by_handle(self.handle)
    self = nil
end

function Vehicle:Model()
    return ENTITY.GET_ENTITY_MODEL(self.handle)
end