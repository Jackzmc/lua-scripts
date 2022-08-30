-- Stand Chat
-- Created By Jackz
local SCRIPT = "jackz_chat"
local VERSION = "1.2.22"
local LANG_TARGET_VERSION = "1.3.3" -- Target version of translations.lua lib

--#P:DEBUG_ONLY
-- Still needed for local dev
function show_busyspinner(text) HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING");HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text);HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2) end
function get_version_info(version) local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)") return { major = tonumber(major),minor = tonumber(minor),patch = tonumber(patch) } end
function compare_version(a, b) return 0 end
--#P:END

--#P:TEMPLATE("_SOURCE")
--#P:TEMPLATE("common")

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
_lang.set_autodownload_uri("jackz.me", "/stand/translations/")
_lang.load_translation_file(SCRIPT)
if wasUpdated then
  _lang.update_translation_file(SCRIPT)
end

-- begin actual plugin code
local lastTimestamp = os.unixseconds() - 10000 -- Get last 10 seconds
local messages = {}
local user = SOCIALCLUB._SC_GET_NICKNAME() -- don't be annoying.
local waiting = false
local showExampleMessage = false
local sendChannel = "default"
local recvChannel = sendChannel
local devToken = nil -- don't waste your time. you're not a dev.
local textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
local bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.3 }
local chatPos = { x = 0.0, y = 0.4 }
local textOffsetSize = 0.02
local textSize = 0.5
local textTime = 40000 -- 40 seconds
local keyhash = menu.get_activation_key_hash()

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
local channelList = menu.list(menu.my_root(), _lang.format("CHANNELS_NAME"), {}, _lang.format("CHANNELS_DESC") .. "\n\n" .. _lang.format("CHANNELS_ACTIVE", "default"))
function switchChannel(channel)
  sendChannel = channel
  recvChannel = sendChannel
  menu.set_help_text(channelList, _lang.format("CHANNELS_DESC") .. "\n\n" .. _lang.format("CHANNELS_ACTIVE", channel))
  _lang.toast("CHANNELS_SWITCHED", channel)
end

async_http.init("jackz.me", "/stand/chat/info", function(body)
  if body:sub(1, 1) == "{" then
    local data = json.decode(body)
    for _, _lang in ipairs(data.publicChannels) do
      menu.action(channelList, _lang, {"chat_lang" .. _lang}, _lang.format("CHANNELS_SWITCH_TO", _lang), function(_)
        switchChannel(_lang)
      end)
    end
  else
    util.toast("Jackz Chat server returned an error (invalid json)")
  end
end, function() util.toast("Could not fetch public channels") end)
async_http.dispatch()

menu.action(channelList, _lang.format("CHANNELS_SPECIFIC_NAME"), { "chatchannel" } , _lang.format("DESC"), function(_)
  menu.show_command_box("chatchannel ")
end, function(args)
  args = args:gsub('%W','')
  if string.len(args) == 0 or args == "_all" or args == "system" then
    -- Before you try to bypass this, it's handled on the server side.
    _lang.toast("CHANNELS_SPECIFIC_INVALID")
  else
    switchChannel(string.lower(args))
  end
end)

menu.toggle(menu.my_root(), _lang.format("RECV_ALL_PUBLIC_NAME"), {"chatglobal"}, _lang.format("RECV_ALL_PUBLIC_DESC"), function(on)
  if on then
    recvChannel = "_all"
  else
    recvChannel = sendChannel
  end
end, false)

menu.text_input(menu.my_root(), _lang.format("SEND_MSG_NAME"), { "chat", "c" }, _lang.format("SEND_MSG_DESC") .. "\n\n" .. _lang.format("SEND_CHAT_AS", user), function(args, clickType)
  show_busyspinner("Sending messsage")
  async_http.init("jackz.me", "/stand/chat/channels/" .. sendChannel .. "?v=" .. VERSION, function(result)
    if result == "OK" or result == "Bad Request" then
      table.insert(messages, {
        u = user,
        c = args:sub(1,100),
        t = os.unixseconds() * 1000,
        l = sendChannel
      })
    elseif result == "MAINTENANCE" then
      _lang.toast("SEND_MAINTENANCE")
    else
      _lang.toast("SEND_ERR", result)
    end
    HUD.BUSYSPINNER_OFF()
  end)
  async_http.set_post("application/json", json.encode({
    user = user,
    content = args,
    hash = keyhash,
    rid = players.get_rockstar_id(players.user())
  }))
  async_http.dispatch()
end)


util.create_tick_handler(function(_)
  waiting = true
  async_http.init("jackz.me", "/stand/chat/channels/" .. recvChannel .. "/" .. lastTimestamp, function(body)
    -- check if response is validish json (incase ratelimitted)
    if body:sub(1, 1) == "{" then
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
    directx.draw_text(chatPos.x, chatPos.y - textOffsetSize, _lang.format("EXAMPLE_1"), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_text(chatPos.x, chatPos.y - (textOffsetSize * 2), _lang.format("EXAMPLE_2"), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_rect(chatPos.x, chatPos.y - (textOffsetSize * 2) - (textOffsetSize / 2), 0.3 + 0.2 * textSize, textOffsetSize * 2, bgColor)
  end
	util.yield()
end