--[[ By default the following libs are loaded globally:
    1. json.lua as 'json'
    2. natives (version defined by NATIVES_VERSION)
    3. translations as 'lang'
--]]

local Module = {
    VERSION = "1.0.0",
    DESCRIPTION = "Chat globally with all online stand users.\nComes with support of channels, so you can separate your messages, or chat in private rooms with your friends.",
    AUTHOR = "Jackz",
    INFO_URL = nil, -- Optional url, such as guilded, where users can get info
    --[[ Internally loaded variables ---
    - Access these via self. (ex self.root or self.log)
    root -- Populated with the Lua Scripts -> jackzscript root
    name -- Name of the file without the .lua extension
    onlineVersion -- Will be populated on preload,

    log(...) -- Logs to file with prefix [jackzscript] [Module.name] <any>, auto calls tostring() on all vars
    toast(...) -- Toasts to stand with prefix [Module.name] <any>, auto calls tostring() on all vars
    require(file) -- Requires a lib file, and will automatically delete it on module unload, removing its cache

    --- Optional, config variables ---
    --- Note: All ___Url variables have the following placeholders:
    --- %name% -> example, %filename% -> example.lua
    libs = { 
        -- Note: Current implementation, all modules share the libraries, such that if one targets a newer version, the newest will always be downloaded
        mylib = { -- Key is the global name of the lib
            sourceUrl = "", -- URL of file, where to download from
            targetVersion = "" -- Target version of lib, must expose either VERSION or LIB_VERSION
        }
    }
    --]]
    sharedLibs = {
        -- jackzvehiclelib = {
        --     url = "jackz.me/stand/libs/jackzvehiclelib.lua",
        --     targetVersion = "1.1.0",
        -- }
    },
    lastTimestamp = util.current_unix_time_millis() * 1000 - 10000,
    messages = {},
    user = nil, -- don't be annoying.
    waiting = false,
    showExampleMessage = false,
    sendChannel = "default",
    recvChannel = "default",
    devToken = nil, -- don't waste your time. you're not a dev.
    textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.3 },
    chatPos = { x = 0.0, y = 0.4 },
    textOffsetSize = 0.02,
    textSize = 0.5,
    textTime = 40000,
    keyhash = nil,
}

--- [REQUIRED] Checks if this module should be loaded, incase you want to do any startup checks.
--- @param isManual boolean True if module was loaded manually, false if automatically loaded
--- @param wasUpdated boolean Has script been updated (see self.previousVersion to get old version)
--- @return boolean TRUE if module should be loaded, false if not
function Module:OnModulePreload(isManual, wasUpdated)
    lang.set_autodownload_uri("jackz.me", "/stand/translations/")
    if wasUpdated then
        lang.update_translation_file("jackz_chat")
    end
    lang.load_translation_file("jackz_chat")
    return true
end

--- Called once every module has been loaded.
--- @param root number A handle to the stand menu list (Lua Scripts -> jackzscript -> Module.name)
function Module:OnReady(root)
    local metaList = menu.list(root, "Script Meta")
    menu.divider(metaList, self.name .. " V" .. self.VERSION)
    menu.hyperlink(metaList, "View guilded post", "https://www.guilded.gg/stand/groups/x3ZgB10D/channels/7430c963-e9ee-40e3-ab20-190b8e4a4752/docs/271932")
    menu.hyperlink(metaList, "View full changelog", "https://jackz.me/stand/changelog?html=1&script=" .. self.name)
    menu.hyperlink(metaList, "Help Translate", "https://jackz.me/stand/translate/?script=" .. self.name, "If you wish to help translate, this script has default translations fed via google translate, but you can edit them here:\nOnce you make changes, top right includes a save button to get a -CHANGES.json file, send that my way.")

    self.user = SOCIALCLUB._SC_GET_NICKNAME() -- don't be annoying.
    self.keyhash = menu.get_activation_key_hash()
    self.rid = players.get_rockstar_id(players.user())

    Module:setupOptionsMenu(root)
    Module:setupChannelList(root)

    JUtil.CreateTimer(7000, function()
        Module:fetchMessages()
    end)

    menu.text_input(root, lang.format("SEND_MSG_NAME"), { "chat", "c" }, lang.format("SEND_MSG_DESC") .. "\n\n" .. lang.format("SEND_CHAT_AS", self.user), function(content)
        self:sendMessage(content)
    end)
end

function Module:switchChannel(channel)
    self.sendChannel = channel
    self.recvChannel = self.sendChannel
    menu.set_help_text(self.channelList, lang.format("CHANNELS_DESC") .. "\n\n" .. lang.format("CHANNELS_ACTIVE", channel))
    lang.toast("CHANNELS_SWITCHED", channel)
end

function Module:fetchMessages()
    local headers = self.devToken and { ["x-dev-token"] = self.devToken } or nil
    JUtil.GetJson("https://jackz.me/stand/chat/channels/" .. self.recvChannel .. "/" .. self.lastTimestamp, headers, function(statusCode, resHeaders, data)
        if data then
            for _, message in ipairs(data.m) do
                if message.u ~= self.user then
                  table.insert(self.messages, message)
                end
                -- max 20 messages
                if #self.messages > 20 then
                  table.remove(self.messages, 1)
                end
            end
            self.lastTimestamp = data.t
        end
    end)
    
end

function Module:sendMessage(content)
    JUtil.ShowBusySpinner("Sending message...")
    JUtil.PostJson(
        "https://stand-chat.jackz.me/channels/" .. self.sendChannel .. "?v=" .. self.VERSION,
        {
            user = self.user,
            content = content,
            hash = self.keyhash,
            rid = self.rid
        },
        function(statusCode, resHeaders, result)
            HUD.BUSYSPINNER_OFF()
            if result == "OK" or result == "Bad Request" then
                table.insert(self.messages, {
                u = self.user,
                c = content:sub(1,100),
                t = util.current_unix_time_millis() * 1000,
                l = self.sendChannel
                })
            elseif result == "MAINTENANCE" then
                lang.toast("SEND_MAINTENANCE")
            else
                lang.toast("SEND_ERR", result)
            end
        end
    )
end

function Module:setupOptionsMenu(root)
    local optionsMenu = menu.list(root, "DESIGN", {}, "DESIGN_TEXT")
    menu.on_blur(optionsMenu, function(_) self.showExample = false end)
    local submenus = { self.optionsMenu }
    table.insert(submenus, lang.menus.colour(optionsMenu, "DESIGN_CHAT_COLOR", {"standchatcolor"}, self.textColor, false, function(color)
        self.textColor = color
    end))
    table.insert(submenus, lang.menus.colour(optionsMenu, "DESIGN_BACKGROUND_COLOR", {"standchatbgcolor"}, self.bgColor, false, function(color)
        self.bgColor = color
    end))
    table.insert(submenus, menu.slider(optionsMenu, lang.format("DESIGN_POS_NAME", "X"), {"standchatx"}, lang.format("DESIGN_POS_DESC", "X"), -32768, 32767, self.chatPos.x * 100, 1, function(x)
        self.chatPos.x = x / 100
    end))
    table.insert(submenus, menu.slider(optionsMenu, lang.format("DESIGN_POS_NAME", "Y"), {"standchaty"}, lang.format("DESIGN_POS_DESC", "Y"), -32768, 32767, self.chatPos.y * 100, 1, function(y)
        self.chatPos.y = y / 100
    end))
    table.insert(submenus, lang.menus.slider(optionsMenu, "DESIGN_TEXT_SIZE", {"standchatsize"}, 20, 100, self.textSize * 100, 1, function(size)
        self.textSize = size / 100
        local _, height = directx.get_text_size("Example", self.textSize)
        self.textOffsetSize = height
    end))
    table.insert(submenus, lang.menus.slider(optionsMenu, "DESIGN_MESSAGE_DURATION", {"standchatmsgtime"}, 15, 120, self.textTime / 1000, 1, function(time)
        self.textTime = time * 1000
    end))
    for _, submenu in ipairs(submenus) do
        menu.on_focus(submenu, function(_)
            self.showExample = true
        end)
    end
end


function Module:setupChannelList(root)
    local channelList = menu.list(root, lang.format("CHANNELS_NAME"), {}, lang.format("CHANNELS_DESC") .. "\n\n" .. lang.format("CHANNELS_ACTIVE", "default"))

    JUtil.GetJson("https://jackz.me/stand/chat/info", {}, function(succesCode, resHeaders, info)
        for _, channel in ipairs(info.publicChannels) do
            menu.action(channelList, channel, {"chatchannel" .. channel}, lang.format("CHANNELS_SWITCH_TO", channel), function(_)
                self:switchChannel(channel)
            end)
        end
    end, function(statusCode, error)
        util.toast("Failed to acquire chat information")
        Log.error(string.format("Could not fetch public channels list (code=%d): %s", statusCode, error))
    end)

    -- lang.menus.text_input(channelList, "CHANNELS_SPECIFIC", { "chatchannel" }, function(args)
    --     args = args:gsub('%W','')
    --     if string.len(args) == 0 or args == "_all" or args == "system" then
    --       -- Before you try to bypass this, it's handled on the server side.
    --       lang.toast("CHANNELS_SPECIFIC_INVALID")
    --     else
    --       self:switchChannel(string.lower(args))
    --     end
    -- end)

    lang.menus.toggle(root, "RECV_ALL_PUBLIC", {"chatglobal"}, function(on)
        if on then
          self.recvChannel = "_all"
        else
          self.recvChannel = self.sendChannel
        end
    end, false)
end

--- Called every frame, no need to yield
--- @param tick number Every increasing number, which represents the current frame
function Module:OnTick(tick)
    local i = 0
    local now = util.current_unix_time_millis() * 1000
    local width = 0.0
    for a, msg in ipairs(self.messages) do
        if now - msg.t > self.textTime then
        table.remove(self.messages, a)
        else
        local content
        if msg.ip then -- Only for jackz :)
            content = msg.l and string.format("[%s] [%s] %s: %s", msg.ip, msg.l, msg.u, msg.c) or string.format("[%s] %s: %s", msg.ip, msg.u, msg.c)
        else
            content = msg.l and string.format("[%s] %s: %s", msg.l, msg.u, msg.c) or (msg.u .. ": " .. msg.c)
        end
        -- compute largest width of text, to set chatbot width
        local w = directx.get_text_size(content, self.textSize)
        if w > width then
            width = w
        end
        directx.draw_text(self.chatPos.x, self.chatPos.y + (self.textOffsetSize * i), content, ALIGN_CENTRE_LEFT, self.textSize, self.textColor, true)
        i = i + 1
        end
    end
    directx.draw_rect(self.chatPos.x, self.chatPos.y - (self.textOffsetSize / 2), width + 0.005, self.textOffsetSize * i, self.bgColor)
    if self.showExample then
        directx.draw_text(self.chatPos.x, self.chatPos.y - self.textOffsetSize, lang.format("EXAMPLE_1"), ALIGN_CENTRE_LEFT, self.textSize, self.textColor, true)
        directx.draw_text(self.chatPos.x, self.chatPos.y - (self.textOffsetSize * 2), lang.format("EXAMPLE_2"), ALIGN_CENTRE_LEFT, self.textSize, self.textColor, true)
        directx.draw_rect(self.chatPos.x, self.chatPos.y - (self.textOffsetSize * 2) - (self.textOffsetSize / 2), 0.3 + 0.2 * self.textSize, self.textOffsetSize * 2, self.bgColor)
    end
end

--- Called when module is exiting
--- @param isReload boolean If true, script is being reloaded manually. False if exiting normally
function Module:OnExit(isReload)
    if not isReload then
        self.toast("This script is going away!" )
    end
end
-- This is required, you need to return the module functions
return Module