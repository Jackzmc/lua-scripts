-- Scaleforms Lua Lib
-- Created by Jackz
-- Requires natives file to be loaded before required
--
-- TODO: Possibly methodmap?

-- List of scaleforms
local activeMethod = {
    handle = nil,
    type = nil
}
local displayTickThreadActive = false
local displayedScaleforms = {} -- List of scaleform handles to display
local SCALEFORM_TYPES = { -- List of valid scaleform movie types
    ""
}

function show_busyspinner(text)
    HUD.
end

function hide_busyspinner()
    HUD.BUSYSPINNER_OFF()
end

-- Creates a new scaleform and returns its handle
function create_new_scaleform(sfType)
    for _, sfType2 in ipairs(SCALEFORM_TYPES) do
        if sfType2 == sfType then
            local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE(sfType)
            while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
                util.yield()
            end
            return handle
        end
    end
    return error("Invalid scaleform type")
end

-- Sets active method to text
function set_method_to_text(--[[ scaleformHandle --]] scaleform)
    --SET_TEXT method
    if activeMethod then error("Call finish-method before starting new method") end
    activeMethod = {
        type = "SET_TEXT",
        handle = scaleform
    }
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, activeMethod.type)
end

-- Adds text
function add_text(str)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(str)
end
function add_bool(bool)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(bool)
end
function add_int(int)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(int)
end
function add_float(float)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(float)
end

function finish_method()
    activeMethod = nil
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

--Destroys scaleform, and removes from memory
function destroy()
    -- TODO: Get *ptr for SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED
end

-- Will internally call .display_fullscreen(), call deactivate() or destroy() to stop
function activate(--[[ scaleformHandle --]] scaleform)
    table.insert(displayedScaleforms, scaleform)
    if not displayTickThreadActive then
        displayTickThreadActive = true
        util.create_tick_handler(function(_)
            for _, handle in ipairs(displayedScaleforms) do
                display_fullscreen(handle)
            end
            return displayTickThreadActive
        end)
    end
end

function deactivate(--[[ scaleformHandle --]] scaleform)
    local isAnyOtherScaleform = false
    for i, handle in ipairs(displayedScaleforms) do
        if handle == scaleform then
            table.remove(displayedScaleforms, i)
            return true
        else
            isAnyOtherScaleform = true
        end
    end
    if not isAnyOtherScaleform then
        displayTickThreadActive = false -- Kill tick handler
    end
    return false
end
function clear_all_displayed()
    displayedScaleforms = {}
    displayTickThreadActive = false -- Kill tick handler
end

-- 0: Normal, 1: Interactive, 2: Fullscreen
-- Possibly use this to specify type for .activate() ?
function set_display_mode(mode) error("Not Implemented") end


-- Needs to be called everyframe
function display(--[[ scaleformHandle --]] scaleform, pos, size, color)
    GRAPHICS.DRAW_SCALEFORM_MOVIE(scaleform, pos.x, pos.y, size.w, size.h, color.r, color.g, color.b, color.a)
end

function display_3D(--[[ scaleformHandle --]] scaleform)
    error("Not implemented")
end

function display_fullscreen(--[[ scaleformHandle --]] scaleform, --[[ Color --]] color)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, color.r, color.g, color.b, color.a)
end

return {
    show_busyspinner = show_busyspinner,
    hide_busyspinner = hide_busyspinner,
    create_new_scaleform = create_new_scaleform,
    destroy = destroy,
    set_method_to_text = set_method_to_text,
    add_text = add_text,
    add_bool = add_bool,
    add_float = add_float,
    add_int = add_int,
    finish_method = finish_method,
    activate = activate,
    deactivate = deactivate,
    clear_all_displayed = clear_all_displayed,
    display = display,
    display_fullscreen = display_fullscreen,
    -- TODO: Add pub methods
}
