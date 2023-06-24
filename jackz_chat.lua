-- Stand Chat
-- Created By Jackz
local SCRIPT = "jackz_chat"
VERSION = "1.3.1"
local LANG_TARGET_VERSION = "1.4.3" -- Target version of translations.lua lib

--#P:DEBUG_ONLY
require('templates/log')
require('templates/common')
--#P:END

--#P:TEMPLATE("log")
--#P:TEMPLATE("common")
--#P:TEMPLATE("_SOURCE")


util.require_natives(1627063482)

local json = require("json")
local _lang = require("translations")
if _lang.menus == nil or _lang.VERSION == nil or _lang.VERSION ~= LANG_TARGET_VERSION then
  if SCRIPT_SOURCE == "MANUAL" then
    util.toast("Outdated translations library, downloading update...")
    os.remove(filesystem.scripts_dir() .. "/lib/translations.lua")
    package.loaded["translations"] = nil
    _G["translations"] = nil
    download_lib_update("translations.lua")
    _lang = require("translations")
  else
    util.toast("Outdated lib: 'translations'")
  end
end
_lang.set_autodownload_uri("jackz.me", "/stand/git/" .. (SCRIPT_BRANCH or "master")  .. "/resources/Translations/")
_lang.load_translation_file(SCRIPT)

local SETTINGS_PATH = filesystem.store_dir() .. "/jackz_chat.json"

-- begin actual plugin code
local lastTimestamp = os.unixseconds() - 10000 -- Get last 10 seconds
local messages = {}
local user = SOCIALCLUB._SC_GET_NICKNAME() -- don't be annoying.
local waiting = false
local showExampleMessage = false
local sendChannel = "default"
local devToken = nil -- don't waste your time. you're not a dev.
local textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
local bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.3 }
local chatPos = { x = 0.0, y = 0.4 }
local textOffsetSize = 0.02
local textSize = 0.5
local textTime = 40000 -- 40 seconds
local keyhash = menu.get_activation_key_hash()
local subscribedChannels = { 
  system = true,
  default = true,
  discord = true
}
local sendChatMenu

local SAVE_PATH = filesystem.store_dir() .. "/jackz_chat.json"
local file = io.open(SAVE_PATH, "r")
if file then
  local status, data = pcall(json.decode, file:read("*all"))
  file:close()
  if data then
    if data.subscriptions then
      subscribedChannels = data.subscriptions
    end
  else
    Log.warn("Failed to decode jackz_chat.json: " .. tostring(data))
    Log.toast("Error parsing saved jackz_chat settings, see logs for details")
  end
end

function save_subs()
  local file = io.open(SAVE_PATH, "w")
  file:write(json.encode({ 
    subscriptions = subscribedChannels
  }))
  file:close()
end

--[[
local autoTranslate = {
  incoming_lang = "en",
  outgoing_lang = "en",
  loaded = false,
  active = false
}
local translateMenu
translateMenu = _lang.menus.list(menu.my_root(), "AUTO_TRANSLATE_LIST", {}, function()
  if autoTranslate.loaded then return end
  autoTranslate.loaded = true
  _lang.menus.toggle(menu.my_root(), "AUTO_TRANSLATE_TOGGLE", {"autotranslate"}, function(value)
    autoTranslate.active = value
  end, autoTranslate.active)
  local incoming_langList = menu.list(menu.my_root(), "AUTO_TRANSLATE_INCOMING")
  local outgoing_langList = menu.list(menu.my_root(), "AUTO_TRANSLATE_OUTGOING")
  async_http.init("fuck-python.jackz.me", "/_languages", function(response)
    local json = json.decode(response)
    for _, node in ipairs(json) do
      menu.action(incoming_langList, node.name .. " (" .. node.code .. ")", {"incomingchat" .. node.code}, "Set all incoming chat messages to be translated to this _language", function()
        autoTranslate.incoming_lang = node.code
      end)
      menu.action(outgoing_langList, node.name .. " (" .. node.code .. ")", {"outgoingchat" .. node.code}, "Set all your outgoing messages to be translated to this _language", function()
        autoTranslate.outgoing_lang = node.code
      end)
    end
  end)
end)

chat.on_message(function(senderId, senderName, message, isTeamChat)
  if autoTranslate.active and senderId ~= PLAYER.user() then
    util.toast(translate_text('es', 'en', message))
  end
end)

function translate_text(source_lang, target_lang, text)
  local output
  async_http.init("fuck-python.jackz.me", "/translate?q=" .. text .. "&source=" .. source_lang .. "&target=" .. target_lang, function(body)
    local json = json.decode(body)
    output = json.translatedText
  end)
  while output == nil do
    util.yield()
  end
  return output
end
--]]


local optionsMenu = menu.list(menu.my_root(), _lang.format("DESIGN_NAME"), {}, _lang.format("DESIGN_TEXT"))
menu.divider(menu.my_root(), "")
menu.on_blur(optionsMenu, function(_)
  showExampleMessage = false
end)
local submenus = { optionsMenu }
table.insert(submenus, menu.colour(optionsMenu, _lang.format("DESIGN_CHAT_COLOR_NAME"), {"standchatcolor"}, _lang.format("DESIGN_CHAT_COLOR_DESC"), textColor, false, function(color)
  textColor = color
end))
table.insert(submenus, menu.colour(optionsMenu, _lang.format("DESIGN_BACKGROUND_COLOR_NAME"), {"standchatbgcolor"}, _lang.format("DESIGN_BACKGROUND_COLOR_DESC"), bgColor, true, function(color)
  bgColor = color
end))
table.insert(submenus, menu.slider(optionsMenu, _lang.format("DESIGN_POS_NAME", "X"), {"standx"}, _lang.format("DESIGN_POS_DESC", "X"), -32768, 32767, chatPos.x * 100, 1, function(x)
  chatPos.x = x / 100
end))
table.insert(submenus, menu.slider(optionsMenu, _lang.format("DESIGN_POS_NAME", "Y"), {"standy"}, _lang.format("DESIGN_POS_DESC", "Y"), -32768, 32767, chatPos.y * 100, 1, function(y)
  chatPos.y = y / 100
end))
table.insert(submenus, menu.slider(optionsMenu, _lang.format("DESIGN_TEXT_SIZE_NAME"), {"standchatsize"}, _lang.format("DESIGN_TEXT_SIZE_DESC"), 20, 100, textSize * 100, 1, function(size)
  textSize = size / 100
  local _, height = directx.get_text_size("Example", textSize)
  textOffsetSize = height
end))
table.insert(submenus, menu.slider(optionsMenu, _lang.format("DESIGN_MESSAGE_DURATION_NAME"), {"standchatmsgtime"}, _lang.format("DESIGN_MESSAGE_DURATION_DESC"), 15, 240, textTime / 1000, 1, function(time)
  textTime = time * 1000 -- convert seconds to ms
end))
for _, submenu in ipairs(submenus) do
  menu.on_focus(submenu, function(_)
    showExampleMessage = true
  end)
end
local subscribedChannelsList = _lang.list(menu.my_root(), "SUBSCRIBED_CHANNELS", {})
_lang.divider(subscribedChannelsList, "PUBLIC_CHANNELS")
function add_subscribe_entry(channel, description, defaultOn, isCustom)
  local id = channel:lower()
  if defaultOn then
    subscribedChannels[id] = true
    save_subs()
  end
  local entry
  if isCustom then
    description = description .. "\n\n" .. _lang.format("CHANNEL_SUB_DELETE_HINT")
  end
  entry = menu.toggle(subscribedChannelsList, channel, {"chatsub" .. id}, description, function(on)
    if PAD.IS_CONTROL_PRESSED(2, 209) then
      subscribedChannels[id] = nil
      _lang.toast("CHANNEL_SUB_DELETED", channel)
      menu.delete(entry)
    else
      subscribedChannels[id] = on
      if on then
        _lang.toast("CHANNEL_SUB_ENABLE", channel)
      else
        _lang.toast("CHANNEL_SUB_DISABLE", channel)
      end
    end
    save_subs()
  end, subscribedChannels[id])
end
add_subscribe_entry("System", _lang.format("CHANNEL_SUB_SYSTEM"))


local channelList = menu.list(menu.my_root(), _lang.format("CHANNELS_NAME"), {}, _lang.format("CHANNELS_DESC") .. "\n\n" .. _lang.format("CHANNELS_ACTIVE", "default"))
function switchChannel(channel)
  sendChannel = channel
  channelList.menu_name = _lang.format("CHANNELS_DESC") .. "\n\n" .. _lang.format("CHANNELS_ACTIVE", channel)
  sendChatMenu.menu_name = _lang.format("SEND_MSG_NAME", sendChannel)
  sendChatMenu.menu_name = _lang.format("SEND_MSG_DESC") .. "\n\n" .. _lang.format("SEND_CHAT_AS", user, sendChannel)
  _lang.toast("CHANNELS_SWITCHED", channel)
end

async_http.init("jackz.me", "/stand/chat/info", function(body)
  if body:sub(1, 1) == "{" then
    local data = json.decode(body)

    for _, channel in ipairs(data.publicChannels) do
      menu.action(channelList, channel, {"chat_lang" .. channel}, _lang.format("CHANNELS_SWITCH_TO", channel), function(_)
        switchChannel(channel)
      end)
      local desc = _lang.get_raw_string("CHANNEL_SUB_" .. channel) or _lang.format("CHANNEL_SUB_PUBLIC")
      add_subscribe_entry(channel, desc, subscribedChannels[channel] or false)
    end

    -- Add custom subscription input
    _lang.divider(subscribedChannelsList, "CUSTOM_CHANNELS")
    _lang.text_input(subscribedChannelsList, "CHANNEL_SUB_ADDCUSTOM", {"chatsubaddcustom"}, function(value)
      if value == "" then end
      add_subscribe_entry(value, _lang.format("CHANNEL_SUB_CUSTOM"), true)
    end, "")

    -- Load custom subscription inputs
    for channel, value in pairs(subscribedChannels) do
      -- Don't show system (not listed as public channel), default to false unless system
      local isPublicChannel = channel == "system"
      if not isPublicChannel then
        -- Check if channel is also public channel, thus public, not custom
        for _, publicChannel in ipairs(data.publicChannels) do
          if channel == publicChannel then
            isPublicChannel = true
            break
          end
        end
      end
      -- If custom
      if not isPublicChannel then
        add_subscribe_entry(channel, _lang.format("CHANNEL_SUB_CUSTOM"), value, true)
      end
    end
  else
    util.toast("Jackz Chat server returned an error, see logs")
    Log.warn(body)
  end
end, function() util.toast("Could not fetch public channels") end)
async_http.dispatch()



menu.text_input(channelList, _lang.format("CHANNELS_SPECIFIC_NAME"), { "chatchannel" } , _lang.format("CHANNELS_SPECIFIC_DESC"), function(args)
  if args == "" then return end
  args = args:gsub('%W','')
  if string.len(args) == 0 or args == "_all" or args == "system" then
    -- Before you try to bypass this, it's handled on the server side.
    _lang.toast("CHANNELS_SPECIFIC_INVALID")
  else
    switchChannel(string.lower(args))
  end
end)

sendChatMenu = menu.text_input(menu.my_root(), _lang.format("SEND_MSG_NAME", sendChannel), { "chat", "c" }, _lang.format("SEND_MSG_DESC") .. "\n\n" .. _lang.format("SEND_CHAT_AS", user, sendChannel), function(args, clickType)
  if args == "" then return end
  show_busyspinner("Sending messsage")
  async_http.init("jackz.me", "/stand/chat/channels/" .. sendChannel .. "?v=" .. VERSION, function(result, headers, status_code)
    if status_code == 204 or result == "OK" or result == "Bad Request" then
      table.insert(messages, {
        u = user,
        c = args:sub(1,100),
        t = os.unixseconds() * 1000,
        l = sendChannel
      })
    elseif result == "MAINTENANCE" then
      _lang.toast("SEND_MAINTENANCE")
    elseif result == "RATELIMITED" then
      _lang.toast("SEND_RATELIMITED")
    else
      _lang.toast("SEND_ERR", result)
    end
    HUD.BUSYSPINNER_OFF()
  end, function() HUD.BUSYSPINNER_OFF() end)
  async_http.set_post("application/json", json.encode({
    user = user,
    content = args,
    hash = keyhash,
    rid = players.get_rockstar_id(players.user())
  }))
  Log.log("value", json.encode({
    user = user,
    content = args,
    hash = keyhash,
    rid = players.get_rockstar_id(players.user())
  }))
  async_http.dispatch()
  sendChatMenu:applyDefaultState()
end)


util.create_tick_handler(function(_)
  waiting = true
  local subList = {}
  for k, v in subscribedChannels do
    if v then
      table.insert(subList, k)
    end
  end
  async_http.init("jackz.me", 
    "/stand/chat/channels/" .. sendChannel .. "/" .. lastTimestamp .. "?channels=" .. table.concat(subList, ","),
    function(body, res_headers, status_code)
    -- check if response is validish json (incase ratelimitted)
    -- Also ignore all errors, and 204 no content
    if status_code == 200 and body:sub(1, 1) == "{" then
      local data = json.decode(body)
      for _, message in ipairs(data.m) do
        if message.u ~= user then
          table.insert(messages, message)
        end
        -- max 20 messages
        if #messages > 20 then
          table.remove(messages, 1)
        end
      end
      lastTimestamp = data.t
    else
      -- Log.debug("fetch_error", status_code, body)
    end
    waiting = false
  end)
  if devToken then -- don't even try, you arent finding the token
    async_http.add_header("x-dev-token", devToken)
  end
  async_http.dispatch()
  while waiting do --wait until last fetch finishes
    util.yield()
  end
  util.yield(7000)
  return true
end)

while true do
  local i = 0
  local now = os.unixseconds() * 1000
  local width = 0.0
  for a, msg in ipairs(messages) do
    if now - msg.t > textTime then
      table.remove(messages, a)
    else
      local content
      if msg.ip then -- Only for jackz :)
        content = msg.l and string.format("[%s] [%s] %s: %s", msg.ip, msg.l, msg.u, msg.c) or string.format("[%s] %s: %s", msg.ip, msg.u, msg.c)
      else
        content = msg.l and string.format("[%s] %s: %s", msg.l, msg.u, msg.c) or (msg.u .. ": " .. msg.c)
      end
      -- compute largest width of text, to set chatbot width
      local w = directx.get_text_size(content, textSize)
      if w > width then
        width = w
      end
      directx.draw_text(chatPos.x, chatPos.y + (textOffsetSize * i), content, ALIGN_CENTRE_LEFT, textSize, textColor, true)
      i = i + 1
    end
  end
  directx.draw_rect(chatPos.x, chatPos.y - (textOffsetSize / 2), width + 0.005, textOffsetSize * i, bgColor)
  if showExampleMessage then
    directx.draw_text(chatPos.x, chatPos.y - textOffsetSize, _lang.format("EXAMPLE_1", VERSION), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_text(chatPos.x, chatPos.y - (textOffsetSize * 2), _lang.format("EXAMPLE_2"), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_text(chatPos.x, chatPos.y - (textOffsetSize * 3), _lang.format("EXAMPLE_3"), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_rect(chatPos.x, chatPos.y - (textOffsetSize * 3) - (textOffsetSize / 2), 0.3 + 0.2 * textSize, textOffsetSize * 3, bgColor)
  end
	util.yield()
end