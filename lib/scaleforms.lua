-- Scaleforms Lua Lib
-- created by Jackz
-- Requires natives file to be loaded before required
-- Supposedly finds an existing instance and returns its handle
local Scaleform = {
    LIB_VERSION = "1.0.0",

    displayTickThreadActive = false,
    displayedInstances = {}
}
Scaleform.__index = Scaleform

function Scaleform.libVersion()
    return Scaleform.LIB_VERSION
end

function Scaleform.ShowLoadingIndicator(text, type)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(type or 2)
end

function Scaleform.EndLoadingIndicator()
    HUD.BUSYSPINNER_OFF()
end

function Scaleform:findInstance(sfName)
    if not sfName then
        return error("Scaleform name is required")
    end
    sfName = string.upper(sfName)
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE_INSTANCE(sfName)
    local this = {}
    this.handle = handle
    this.name = sfName
    setmetatable(this, Scaleform)
    return this
end

function Scaleform:create(sfName)
    if not sfName then
        return error("Scaleform name is required")
    end
    sfName = string.upper(sfName)
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE(sfName)
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
        util.yield()
    end
    local this = {}
    this.handle = handle
    this.name = sfName
    setmetatable(this, Scaleform)
    return this
end

function Scaleform:createFrontend(sfName)
    if not sfName then
        return error("Scaleform name is required")
    end
    sfName = string.upper(sfName)
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE_ON_FRONTEND(sfName)
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
        util.yield()
    end
    local this = {}
    this.handle = handle
    this.name = sfName
    setmetatable(this, Scaleform)
    return this
end

function Scaleform:createFrontendHeader(sfName)
    if not sfName then
        return error("Scaleform name is required")
    end
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE_ON_FRONTEND_HEADER(sfName)
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
        util.yield()
    end
    local this = {}
    this.handle = handle
    this.name = sfName
    setmetatable(this, Scaleform)
    return this
end

function Scaleform:run(methodName, ...)
    startMethod(self.handle, methodName)
    for i, param in ipairs({...}) do
        if type(param) == "string" then
            addString(param)
        elseif type(param) == "boolean" then
            addBool(param)
        elseif type(param) == "number" then
            addInt(param)
        else
            endMethod()
            return error("Invalid parameter type (" .. type(param) .. ") for arg #" .. i + 2)
        end
    end
    endMethod()
end

function Scaleform:displayFullscreen()
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.handle, 255, 255, 255, 255)
end
function Scaleform:display(x, y, width, height, color)
    GRAPHICS.DRAW_SCALEFORM_MOVIE(self.handle, x, y, width ,height, color.r, color.g, color.b, color.a)
end

function Scaleform:display3D(pos, rot, scale, sharpness)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_3D(self.handle, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 0.0, sharpness or 1.0, 0.0, scale.x or 1.0, scale.y or 1.0, scale.z or 1.0, 0)
end
function Scaleform:display3DSolid(pos, rot, scale, sharpness)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_3D_SOLID(self.handle, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 0.0, sharpness or 1.0, 0.0, scale.x or 1.0, scale.y or 1.0, scale.z or 1.0, 0)
end

function Scaleform:displayFullscreenMasked(--[[ scaleformHandle --]] scaleform2, r, g, b, a)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.handle, scaleform2, r or 0, g or 0, b or 0, a or 255)
end

function Scaleform.startMethod(sf, methodName)
    if Scaleform.activeMethod then error("Call Scaleform.endMethod before starting new method") end
    Scaleform.activeMethod = {
        type = methodName,
        handle = sf.handle
    }
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(sf.handle, Scaleform.activeMethod.type)
end

function Scaleform.addString(str)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(str)
end
function Scaleform.addBool(bool)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(bool)
end
function Scaleform.addInt(int)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(int)
end
function Scaleform.addFloat(float)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(float)
end
-- Ends the method building and fires the method
function Scaleform.endMethod()
    Scaleform.activeMethod = nil
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

-- Will internally call .display_fullscreen(), until duration runs out.
-- If duration is nil, will run forever. Call deactivate(scaleform) to stop
function Scaleform:activate(ms)
    self.duration = ms or -1
    self.active = true
    table.insert(Scaleform.displayedInstances, self)
    -- create new tick handler if not already created
    if not Scaleform.displayTickThreadActive then
        Scaleform.displayTickThreadActive = true
        util.create_tick_handler(function(_)
            local len = 0
            for i, sfInstance in ipairs(Scaleform.displayedInstances) do
                sfInstance:displayFullscreen()
                len = len + 1
                if sfInstance.duration ~= -1 then
                    sfInstance.duration = sfInstance.duration - 10
                    util.draw_debug_text(sfInstance.name .. ": " .. sfInstance.duration)
                    if sfInstance.duration <= 0 then
                        sfInstance.active = false
                        table.remove(Scaleform.displayedInstances, i)
                    end
                end
            end
            -- If no more left to display, end this tick handler
            if len == 0 then
                Scaleform.displayTickThreadActive = false
            end
            return Scaleform.displayTickThreadActive
        end)
    end
end

function Scaleform:isActive()
    return self.isActive
end

function Scaleform:deactivate()
    self.isActive = false
    for i, sfInstance in ipairs(Scaleform.displayedInstances) do
        if sfInstance == self then
            table.remove(Scaleform.displayedInstances, i)
            break
        end
    end
end

function Scaleform.clearAllDisplayed()
    Scaleform.displayedInstances = {}
    Scaleform.displayTickThreadActive = false -- Kill tick handler
end

-- creates a new scaleform and returns its handle
-- See list of scaleforms (left nav bar) here: https://vespura.com/fivem/scaleform/
function create(sfName)
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE(sfName)
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
        util.yield()
    end
    return handle
end

-- creates a new scaleform on the frontend and returns its handle
-- See list of scaleforms (left nav bar) here: https://vespura.com/fivem/scaleform/
function createFrontend(sfName)
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE_ON_FRONTEND(sfName)
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
        util.yield()
    end
    return handle
end

function createFrontendHeader(sfName)
    local handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE_ON_FRONTEND_HEADER(sfName)
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(handle) do
        util.yield()
    end
    return handle
end

function startMethod(--[[ scaleformHandle --]] scaleform, methodName)
    if activeMethod then error("Call endMethod before starting new method") end
    activeMethod = {
        type = methodName,
        handle = scaleform
    }
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, activeMethod.type)
end

-- Will run in one line, StartMethod, parameters, EndMethod
function runMethod(--[[ scaleformHandle --]] scaleform, methodName, ...)
    startMethod(scaleform, methodName)
    local params = {...}
    for i, param in ipairs(params) do
        if type(param) == "string" then
            addString(param)
        elseif type(param) == "boolean" then
            addBool(param)
        elseif type(param) == "number" then
            addInt(param)
        else
            endMethod()
            return error("Invalid parameter type (" .. type(param) .. ") for arg #" .. i + 2)
        end
    end
    endMethod()
end

-- Adds text
function addString(str)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(str)
end
function addBool(bool)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(bool)
end
function addInt(int)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(int)
end
function addFloat(float)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(float)
end
-- Ends the method building and fires the method
function endMethod()
    activeMethod = nil
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

local function _get_return()
    activeMethod = nil
    local returnHandle = GRAPHICS.END_SCALEFORM_MOVIE_METHOD_RETURN_VALUE()
    while not GRAPHICS.IS_SCALEFORM_MOVIE_METHOD_RETURN_VALUE_READY(returnHandle) do
        util.yield()
    end
    return returnHandle
end
-- Same as endMethod but gets the return value if its an int
function endMethodGetInt()
    return GRAPHICS.GET_SCALEFORM_MOVIE_METHOD_RETURN_VALUE_INT(_get_return())
end
-- Same as endMethod but gets the return value if its an bool
function endMethodGetBool()
    return GRAPHICS.END_SCALEFORM_MOVIE_METHOD_RETURN_VALUE_BOOL(_get_return())
end
-- Same as endMethod but gets the return value if its an string
function endMethodGetString()
    return GRAPHICS.END_SCALEFORM_MOVIE_METHOD_RETURN_VALUE_STRING(_get_return())
end

-- CALL SECTIONS
-- I have no clue what's the purpose of CALL_ natives as they don't seem to work - use startMethod or runMethod

-- Calls a scaleform function with no arguments
function call_method(--[[ scaleformHandle --]] scaleform, methodName)
    GRAPHICS.CALL_SCALEFORM_MOVIE_METHOD(scaleform, methodName)
end
-- Calls a scaleform function with any given length of numbers
function call_method_with_numbers(--[[ scaleformHandle --]] scaleform, methodName, ...)
    local args = { ... }
    table.insert(args, -1.0)
    native_invoker.begin_call()
    native_invoker.push_arg_int(scaleform)
    for _, num in ipairs({ ... }) do
        native_invoker.push_arg_float(num)
    end
    native_invoker.push_arg_float(-1.0)
    native_invoker.end_call("D0837058AE2E4BEE")
end
-- Calls a scaleform function with strings and numbers. 
-- numbers & strings must be a TABLE ARRAY
function call_method_with_mixed(--[[ scaleformHandle --]] scaleform, methodName, numbers, strings)
    native_invoker.begin_call()
    native_invoker.push_arg_int(scaleform)
    native_invoker.push_arg_string(methodName)
    for _, num in ipairs(numbers) do
        native_invoker.push_arg_float(num)
    end
    native_invoker.push_arg_float(-1.0)
    for _, str in ipairs(strings) do
        native_invoker.push_arg_string(str)
    end
    native_invoker.push_arg_int(0)
    native_invoker.end_call("EF662D8D57E290B1")
end

-- Calls a scaleform function with any given length of strings
function call_method_with_strings(--[[ scaleformHandle --]] scaleform, methodName, ...)
    native_invoker.begin_call()
    native_invoker.push_arg_int(scaleform)
    native_invoker.push_arg_string(methodName)
    for _, str in ipairs({ ... }) do
        native_invoker.push_arg_string(str)
    end
    native_invoker.push_arg_int(0)
    native_invoker.end_call("51BC1ED3CC44E8F7")
end

function _create_displayer()
    if not displayTickThreadActive then
        displayTickThreadActive = true
        util.create_tick_handler(function(_)
            for handle, msLeft in pairs(displayedSFDurationLeft) do
                displayFullscreen(handle)
                -- If there is a duration attached, tick it downwards:
                if msLeft ~= -1 then
                    displayedSFDurationLeft[handle] = msLeft - 10
                    if displayedSFDurationLeft[handle] <= 0 then --Call deactivate, will destroy this tick handler if empty
                        deactivate(handle)
                    end
                end
            end
            return displayTickThreadActive
        end)
    end
end

-- Will internally call .display_fullscreen(), until duration runs out.
-- If duration is nil, will run forever. Call deactivate(scaleform) to stop
function activate(--[[ scaleformHandle --]] scaleform, ms)
    displayedSFDurationLeft[scaleform] = ms or -1
    _create_displayer()
end

function isActive(--[[ scaleformHandle --]] scaleform)
    return displayedSFDurationLeft[scaleform] ~= nil
end

function deactivate(--[[ scaleformHandle --]] scaleform)
    displayedSFDurationLeft[scaleform] = nil
    local len = #displayedSFDurationLeft
    if len == 0 then
        displayTickThreadActive = false
    end
end

function clearAllDisplayed()
    displayedScaleforms = {}
    displayTickThreadActive = false -- Kill tick handler
end

-- 0: Normal, 1: Interactive, 2: Fullscreen
-- Possibly use this to specify type for .activate() ?
function set_display_mode(mode) error("Not Implemented") end


-- Needs to be called everyframe
function display(--[[ scaleformHandle --]] scaleform, x, y, width, height, color)
    GRAPHICS.DRAW_SCALEFORM_MOVIE(scaleform, x, y, width ,height, color.r, color.g, color.b, color.a)
end

function display3D(--[[ scaleformHandle --]] scaleform, pos, rot, scale, sharpness)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_3D(scaleform, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 0.0, sharpness or 1.0, 0.0, scale.x or 1.0, scale.y or 1.0, scale.z or 1.0, 0)
end
function display3DSolid(--[[ scaleformHandle --]] scaleform, pos, rot, scale, sharpness)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_3D_SOLID(scaleform, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 0.0, sharpness or 1.0, 0.0, scale.x or 1.0, scale.y or 1.0, scale.z or 1.0, 0)
end

function displayFullscreen(--[[ scaleformHandle --]] scaleform, r, g, b, a)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, r or 255, g or 255, b or 255, a or 255)
end
function displayFullscreenMasked(--[[ scaleformHandle --]] scaleform, --[[ scaleformHandle --]] scaleform2, r, g, b, a)
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, scaleform2, r or 0, g or 0, b or 0, a or 255)
end
-- Specific scaleforms (borrowed from https://github.com/unknowndeira/es_extended/blob/master/client/modules/scaleform.lua)

-- Shows a freemode banner on top of screen (ex: Business Battles / Yacht Defense)
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
local builtin = {}
function builtin.showFreemodeMessageTop(title, msg, ms)
    local sf = Scaleform:create('MP_BIG_MESSAGE_FREEMODE')
    sf:run("RESET_MOVIE")
    sf:run('SHOW_SHARD_CENTERED_TOP_MP_MESSAGE', title, msg)
    sf:activate(ms)
    return sf
end

-- Shows a freemode banner in middle of screen (ex: WASTED)
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
function builtin.showFreemodeDeathMessage(title, msg, ms)
    local sf = Scaleform:create('MP_BIG_MESSAGE_FREEMODE')
    sf:run('SHOW_SHARD_WASTED_MP_MESSAGE', title, msg)

    sf:activate(ms)
    return sf
end

-- Shows a weazel news breaking news banner
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
function builtin.showBreakingNews(title, msg, bottom, ms)
    local sf = Scaleform:create('BREAKING_NEWS')
    sf:run('SET_TEXT', msg, bottom)
    sf:run('SET_SCROLL_TEXT', 0, 0, title)
    sf:run('DISPLAY_SCROLL_TEXT', 0, 0)

    sf:activate(ms)
    return sf
end

-- Creates a breaking news text that can scroll between lines
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
-- scrollSpeedMs(optional): How many seconds per switching to the next line
function builtin.showBreakingNewsScrolling(title, topLines, bottomLines, ms, scrollSpeedMs)
    local sf = Scaleform:create('BREAKING_NEWS')
    sf:run('SET_TEXT', title, "")
    for i, line in ipairs(topLines) do
        sf:run('SET_SCROLL_TEXT', 0, i-1, line)
    end
    for i, line in ipairs(bottomLines) do
        sf:run('SET_SCROLL_TEXT', 1, i-1, line)
    end
    sf:run('DISPLAY_SCROLL_TEXT', 0, 0)
    sf:run('DISPLAY_SCROLL_TEXT', 1, 0)
    if scrollSpeedMs then
        local topIndex = 0
        local btmIndex = 0
        local topMax = #topLines
        local btmMax = #bottomLines
        util.create_tick_handler(function()
            util.yield(scrollSpeedMs)
            topIndex = topIndex + 1
            btmIndex = btmIndex + 1
            if topIndex == topMax then
                topIndex = 0
            end
            if btmIndex == btmMax then
                btmIndex = 0
            end
            sf:run('DISPLAY_SCROLL_TEXT', 0, topIndex)
            sf:run('DISPLAY_SCROLL_TEXT', 1, btmIndex)
            return sf:isActive()
        end)
    end

    sf:activate(ms)
    return sf
end

-- Shows a hacking message (lester hack screen)
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
-- r,g,b: 0-255 RGB value, optional, defaults to 255
function builtin.showHackingMessage(title, msg, ms, r, g, b)
    local sf = Scaleform:create('HACKING_MESSAGE')
    sf:run("SET_DISPLAY", 3, title, msg, r or 255, g or 255, b or 255, true)

    sf:activate(ms)
    return sf
end
local function _disable_fallthrough(key)
    PAD.DISABLE_CONTROL_ACTION(2, key)
    util.yield()
    PAD.ENABLE_CONTROL_ACTION(2, key)
end
local CONTROLS={[44]="q",[32]="w",[206]="e",[45]="r",[47]="g",[72]="s",[48]="z",[49]="f",[59]="d",[73]="x",[79]="c",[101]="h",[182]="l",[245]="t",[249]="n",[301]="m",[311]="k",[305]="b",[320]="v",[338]="a"}

local function _get_input()
    if PAD.IS_CONTROL_PRESSED(2, 191) then return -2 -- ENTER key
    elseif PAD.IS_CONTROL_PRESSED(2, 322) then return -3
    elseif PAD.IS_CONTROL_PRESSED(2, 22) then return " " end
    local isShiftPressed = PAD.IS_CONTROL_PRESSED(2, 61)
    -- TODO: Prevent key presses from activating game controls
    for key, char in pairs(CONTROLS) do
        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, key) then
            _disable_fallthrough(key)
            if isShiftPressed then return char:upper()
            else return char end
        end
    end
    return -1
end

-- Shows a textbox, and will return text the player inputs.
-- Warning: Shitty, 'J' doesn't work, expects default keybinds, and will activate anything else that the key does
-- Returns: string (the text they entered), bool (true if input timed out)
-- String will be nil if text box was cancelled
function builtin.showTextPrompt(prompt, prefill, multiline, ms)
    local sf = Scaleform:create('TEXT_INPUT_BOX')
    sf:run("CLEANUP")
    sf:run("SET_MULTI_LINE", multiline or false)
    sf:run("SET_TEXT_BOX", 0, prompt, prefill or "")

    local text = ""
    local pointer = 0

    sf:activate(ms)

    while sf:isActive() do
        local char = _get_input()
        if char == -3 then -- ESC was pressed, return nil
            sf:deactivate()
            return nil, false
        elseif char == -2 then -- Enter was pressed, send text
            sf:deactivate()
            return text, false
        elseif char ~= -1 then
            text = text .. char
            pointer = pointer + 1
            sf:run("UPDATE_INPUT", text, pointer)
        end
        util.yield()
    end
    return text, true
end

-- Shows a popup warning
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
function builtin.showPopupWarning(title, msg, bottom, ms, altText, hideBg)
    local sf = Scaleform:create('POPUP_WARNING')
    sf:run("SHOW_POPUP_WARNING", ms, title, msg, bottom, not hideBg, 0, altText)

    sf:activate(ms)
    return sf
end

function builtin.showFullscreenPopup(title, msg, bottom, ms, altText, hideBg)
    local sf = Scaleform:create('POPUP_WARNING')
    sf:run("SHOW_POPUP_WARNING", ms, title, msg, bottom, not hideBg, 1, altText)

    sf:activate(ms)
    return sf
end

function builtin.clearAlerts()
    local sf = Scaleform:findInstance("CELLPHONE_ALERT_POPUP")
    sf:run("CLEAR_ALL")
end

-- Shows an message with an icon
-- x,y: position of icon, no clue what units, ~200 seems max. Default to 0 if nil
-- Icons: Email=1, Clock=3, @=4, Empty=5, AddFriend=11, Checkbox=12, Phone=26, EmailSwap=31, Poop=32, Radar=55, RadarFlash=60, PhoneWifi=53, PhoneReply=52
function builtin.showAlert(type, content, ms, x, y)
    local sf = Scaleform:create("CELLPHONE_ALERT_POPUP")
    sf:run("CREATE_ALERT", type, x or 0, y or 0, content)
    sf:activate(ms)
    return sf
end

-- Shows the los santos traffic UI from singleplayer
-- ms: Amount of milliseconds to display or nil for forever (call Deactivate(returnValue) to stop)
function builtin.showTrafficMovie(ms)
    local sf = Scaleform:create('TRAFFIC_CAM')
    sf:run("PLAY_CAM_MOVIE")
    sf:activate(ms)
    return sf
end

-- Shows a countdown indicator used in racing, stating directions
-- Symbols:
-- 1=Forward, 2=Left, 3=Right, 4=U-Turn, 5=Up, 6=Down, 7=Stop
function builtin.showDirection(direction, r, g, b, ms)
    local sf = Scaleform:create("COUNTDOWN")
    sf:run("SET_DIRECTION", direction, r, g, b)
    sf:activate(ms)
end

function show5SecondCountdown()
    local sf = Scaleform:create("COUNTDOWN")
    sf:activate(5000)
    -- runMethod(sc, "OVERRIDE_FADE_DURATION", 0)
    for x = 5, 0, -1 do
        sf:run("SET_COUNTDOWN_LIGHTS", x)
        util.yield(1000)
    end
    sf:run("SET_MESSAGE", "STOP!", 255, 0, 255, true)
end

builtin.phoneInstance = Scaleform.findInstance("CELLPHONE_IFRUIT")
-- Built in methods to change a user's phone. These methods should be called every frame, or a user's phone will update and wipe them
builtin.phone = {
    getInstance = function() return builtin.phoneInstance end,
    -- Sets the header bar under the time's text (shows current selected app)
    setHeader = function(text)
        builtin.phoneInstance:run("SET_HEADER", text)
    end,
    -- Sets the color theme of the phone.
    -- 1=Blue, 2=Dark Green, 3=Red, 4=Orange, 5=Dark Gray, 6=Purple, 7=Pink, 8=Pink
    setTheme = function(themeIndex)
        builtin.phoneInstance:run("SET_THEME", themeIndex)
    end,
    -- Toggles sleep mode off the phone. Needs to be turned off if rendering brand new phone, or phone needs to be activated
    setSleepmode = function(on)
        builtin.phoneInstance:run("SET_SLEEPMODE", on)
    end,
    -- Sets the current time and displayed day. Day is a string
    setTime = function(hour, min, dayStr)
        builtin.phoneInstance:run("SET_TITLEBAR_TIME", hour, min, dayStr)
    end,
    -- Sets the background.
    setBackgroundIndex = function(imageIndex)
        builtin.phoneInstance:run("SET_BACKGROUND_IMAGE", imageIndex)
    end,
    -- signal: Value of 1 to 4. Any higher will just display as max
    -- provider(optional): Either 0 or 1 (default)
    setSignal = function(signal, provider)
        if provider then
            builtin.phoneInstance:run("SET_PROVIDER_ICON", provider, signal)
        else
            builtin.phoneInstance:run("SET_SIGNAL_STRENGTH", signal)
        end
    end,
    -- Wipes the phone to a blank screen
    clear = function(_)
        builtin.phoneInstance:run("SHUTDOWN_MOVIE")
    end,
    -- Gets the current selected item entry.
    -- On homepage: 0=Emaill, 1=Texts, 2=Contacts, 3=Quick Job, 4=Job List, 5=Settings, 6=Snapmatic, 7=Browser, 8=SecuroServ
    -- Contacts: Lester=12, Mechanic=12, MerryWeather=17, MorsMutual=18, Pegasus=22, Cab=6, 911=7, Lamar=10
    getCurrentSelection = function(_)
        builtin.phoneInstance:run("GET_CURRENT_SELECTION")
        return endMethodGetInt()
    end,
    up = function(_) builtin.phoneInstance:run("SET_INPUT_EVENT", 1) end,
    left = function(_) builtin.phoneInstance:run("SET_INPUT_EVENT", 4) end,
    right = function(_) builtin.phoneInstance:run("SET_INPUT_EVENT", 2) end,
    down = function(_) builtin.phoneInstance:run("SET_INPUT_EVENT", 3) end,
    press = function(_) builtin.phoneInstance:run("SET_INPUT_EVENT", 1) end,
    -- Enters a raw input. Directional inputs are: .up(), .down(), .left(), .right()
    rawInput = function(input) builtin.phoneInstance:run("SET_INPUT_EVENT", input) end
}

return {
    LIB_VERSION = LIB_VERSION,
    Scaleform = Scaleform,
    showBusySpinner = show_busyspinner,
    hideBusySpinner = hide_busyspinner,
    findInstance = findInstance,
    create = create,
    createFrontend = createFrontend,
    createFrontendHeader = createFrontendHeader,
    runMethod = runMethod,
    startMethod = startMethod,
    addString = addString,
    addInt = addInt,
    addFloat = addFloat,
    addBool = addBool,
    endMethod = endMethod,
    endMethodGetInt = endMethodGetInt,
    endMethodGetBool = endMethodGetBool,
    endMethodGetString = endMethodGetString,
    call_method = call_method,
    call_method_with_numbers = call_method_with_numbers,
    call_method_with_mixed = call_method_with_mixed,
    call_method_with_strings = call_method_with_strings,
    activate = activate,
    isActive = isActive,
    deactivate = deactivate,
    clearAllDisplayed = clearAllDisplayed,
    display = display,
    display3D = display3D,
    display3DSolid = display3DSolid,
    displayFullscreen = displayFullscreen,
    builtin
}
