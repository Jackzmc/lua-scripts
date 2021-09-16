-- Scaleforms Lua Lib
-- Created by Jackz
-- Requires natives file to be loaded before required
--
-- TODO: Possibly methodmap?

-- List of scaleforms
local scaleforms = {}
local displayedScaleforms = {}
local displayThreadHandle

-- Creates a new scaleform and returns its handle
function create_new_scaleform()
    
end

-- Sets active method to text
function set_method_to_text([[ scaleformHandle ]] scaleform)
    --SET_TEXT method
end

-- Adds text
function add_text([[ scaleformHandle  ]] scaleform, str)

end

-- Finally creates scaleform, ready to display
function create()
    
end

--Destroys scaleform, and removes from memory
function destroy()

end

-- Will internally call .display_fullscreen(), call deactivate() or destroy() to stop
function activate(scaleform)
    table.insert(displayedScaleforms, scaleform)
    if not displayThreadHandle then
        displayThreadHandle = util.create_tick_handler(function(_)
            for _, handle in ipairs(displayedScaleforms) do
                display_fullscreen(handle)
            end
            return true 
        end)
    end
end

function deactivate(scaleform)
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
        -- TODO: delete thread
    end
    return false
end
function clear_all(scaleform)
    displayedScaleforms = {}
    -- TODO: delete thread
end

-- 0: Normal, 1: Interactive, 2: Fullscreen
function set_display_mode(mode) end


-- Needs to be called everyframe
function display(scaleform, mode)

end

function display_interactive(scaleform)

end

function display_fullscreen(scaleform)

end

return {
    -- TODO: Add pub methods
}
