local Vehicle = {}

-- Creates a new scaleform, waits for it to load and returns its instance
function Vehicle:spawnByName(name, pos, heading)
    if not name then
        return error("Scaleform name is required")
    end
    if not pos then pos = { x = 0, y = 0, z = 0} end
    if not heading then heading = 0 end
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE(sfName)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
    local this = {}
    this.handle = handle
    this.name = sfName
    setmetatable(this, Scaleform)
    return this
end
function Vehicle:spawn(model, pos, heading)
    if not model then
        return error("Scaleform name is required")
    end
    if not pos then pos = { x = 0, y = 0, z = 0} end
    if not heading then heading = 0 end
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE(sfName)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
    local this = {}
    this.handle = handle
    this.name = sfName
    setmetatable(this, Scaleform)
    return this
end