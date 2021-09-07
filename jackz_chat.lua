-- Stand Chat 
-- Created By Jackz
local SCRIPT = "jackz_chat"
local VERSION = "1.2.1"
local CHANGELOG_PATH = filesystem.stand_dir() .. "/Cache/changelog_" .. SCRIPT .. ".txt"
-- Check for updates & auto-update:
-- Remove these lines if you want to disable update-checks & auto-updates: (7-54)
async_http.init("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        -- Remove this block (lines 15-31) to disable auto updates
        async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT .. "&since=" .. VERSION, function(result)
            local file = io.open(CHANGELOG_PATH, "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            io.close(file)
        end)
        async_http.dispatch()
        async_http.init("jackz.me", "/stand/lua/" .. SCRIPT .. ".lua", function(result)
            local file = io.open(filesystem.scripts_dir() .. "/" .. SCRIPT .. ".lua", "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n") -- have to strip out \r for some reason, or it makes two lines. ty windows
            io.close(file)
            util.toast(SCRIPT .. " was automatically updated to V" .. chunks[2] .. "\nRestart script to load new update.", TOAST_ALL)
        end, function(e)
            util.toast(SCRIPT .. ": Failed to automatically update to V" .. chunks[2] .. ".\nPlease download latest update manually.\nhttps://jackz.me/stand/get-latest-zip", 2)
            util.stop_script()
        end)
        async_http.dispatch()
    end
end)
async_http.dispatch()
function try_load_lib(lib, globalName)
    local status, f = pcall(require, string.sub(lib, 0, #lib - 4))
    if not status then
        local downloading = true
        async_http.init("jackz.me", "/stand/libs/" .. lib, function(result)
            local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
            io.output(file)
            io.write(result:gsub("\r", "") .. "\n")
            io.flush() -- redudant, probably?
            io.close(file)
            util.toast(SCRIPT .. ": Automatically downloaded missing lib '" .. lib .. "'")
            if globalName then
                _G[globalName] = require(string.sub(lib, 0, #lib - 4))
            end
            downloading = false
        end, function(e)
            util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
            util.stop_script()
        end)
        async_http.dispatch()
        while downloading do
            util.yield()
        end
    elseif globalName then
        _G[globalName] = f
    end
end
try_load_lib("natives-1627063482.lua")
try_load_lib("json.lua", "json")
try_load_lib("translations.lua", "lang")
lang.set_autodownload_uri("jackz.me", "/stand/translations/")
lang.load_translation_file(SCRIPT)
lang.add_language_selector_to_menu(menu.my_root())
-- Check if there is any changelogs (just auto-updated)
if filesystem.exists(CHANGELOG_PATH) then
    local file = io.open(CHANGELOG_PATH, "r")
    io.input(file)
    local text = io.read("*all")
    util.toast("Changelog for " .. SCRIPT .. ": \n" .. text)
    io.close(file)
    os.remove(CHANGELOG_PATH)
    -- Update translations
    lang.update_translation_file(SCRIPT)
end
-- Check if there is any changelogs (just auto-updated)
if filesystem.exists(CHANGELOG_PATH) then
    local file = io.open(CHANGELOG_PATH, "r")
    io.input(file)
    local text = io.read("*all")
    util.toast("Changelog for " .. SCRIPT .. ": \n" .. text)
    io.close(file)
    os.remove(CHANGELOG_PATH)
end
-- begin actual plugin code
local lastTimestamp = util.current_unix_time_millis() * 1000 - 10000
local messages = {}
local user = SOCIALCLUB._SC_GET_NICKNAME() -- don't be annoying.
local waiting = false
local showExampleMessage = false
local sendChannel = "default"
local recvChannel = sendChannel
local devToken = nil
local textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
local bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.3 }
local chatPos = { x = 0.0, y = 0.4 }
local textOffsetSize = 0.02
local textSize = 0.5
local textTime = 40000
local keyhash = menu.get_activation_key_hash()

local optionsMenu = menu.list(menu.my_root(), lang.format("DESIGN_NAME"), {}, lang.format("DESIGN_TEXT"))
menu.on_blur(optionsMenu, function(_)
  showExampleMessage = false
end)
local submenus = { optionsMenu }
table.insert(submenus, menu.colour(optionsMenu, lang.format("DESIGN_CHAT_COLOR_NAME"), {"standchatcolor"}, lang.format("DESIGN_CHAT_COLOR_DESC"), textColor, false, function(color)
  textColor = color
end))
table.insert(submenus, menu.colour(optionsMenu, lang.format("DESIGN_BACKGROUND_COLOR_NAME"), {"standchatbgcolor"}, lang.format("DESIGN_BACKGROUND_COLOR_DESC"), bgColor, true, function(color)
  bgColor = color
end))
table.insert(submenus, menu.slider(optionsMenu, lang.format("DESIGN_POS_NAME", "X"), {"standx"}, lang.format("DEISGN_POS_DESC", "X"), -32768, 32767, chatPos.x * 100, 1, function(x)
  chatPos.x = x / 100
end))
table.insert(submenus, menu.slider(optionsMenu, lang.format("DESIGN_POS_NAME", "Y"), {"standy"}, lang.format("DESIGN_POS_DESC", "Y"), -32768, 32767, chatPos.y * 100, 1, function(y)
  chatPos.y = y / 100
end))
table.insert(submenus, menu.slider(optionsMenu, lang.format("DESIGN_TEXT_SIZE_NAME"), {"standchatsize"}, lang.format("DESIGN_TEXT_SIZE_DESC"), 20, 100, textSize * 100, 1, function(size)
  textSize = size / 100
  local _, height = directx.get_text_size("Example", textSize)
  textOffsetSize = height
end))
table.insert(submenus, menu.slider(optionsMenu, lang.format("DESIGN_MESSAGE_DURATION_NAME"), {"standchatmsgtime"}, lang.format("DESIGN_MESSAGE_DURATION_DESC"), 15, 120, textTime / 1000, 1, function(time)
  textTime = time * 1000
end))
for _, submenu in ipairs(submenus) do
  menu.on_focus(submenu, function(_)
    showExampleMessage = true
  end)
end
local channelList = menu.list(menu.my_root(), lang.format("CHANNELS_NAME"), {}, lang.format("CHANNELS_DESC") .. "\n\n" .. lang.format("CHANNELS_ACTIVE", "default"))
function switchChannel(channel)
  sendChannel = channel
  recvChannel = sendChannel
  menu.set_help_text(channelList, lang.format("CHANNELS_DESC") .. "\n\n" .. lang.format("CHANNELS_ACTIVE", channel))
  lang.toast("CHANNELS_SWITCHED", channel)
end

async_http.init("stand-chat.jackz.me", "/info", function(body)
  if body:sub(1, 1) == "{" then
    local data = json.decode(body)
    for _, lang in ipairs(data.publicChannels) do
      menu.action(channelList, lang, {"chatlang" .. lang}, lang.format("CHANNELS_SWITCH_TO", lang), function(_)
        switchChannel(lang)
      end)
    end
  end
end, function(err) util.toast("Could not fetch public channels: " .. err) end)
async_http.dispatch()

menu.action(channelList, lang.format("CHANNELS_SPECIFIC_NAME"), { "chatchannel" } , lang.format("DESC"), function(_)
  menu.show_command_box("chatchannel ")
end, function(args)
  args = args:gsub('%W','')
  if string.len(args) == 0 or args == "_all" or args == "system" then
    -- Before you try to bypass this, it's handled on the server side.
    lang.toast("CHANNELS_SPECIFIC_INVALID")
  else
    switchChannel(string.lower(args))
  end
end)

menu.toggle(menu.my_root(), lang.format("RECV_ALL_PUBLIC_NAME"), {"chatglobal"}, lang.format("RECV_ALL_PUBLIC_DESC"), function(on)
  if on then
    recvChannel = "_all"
  else
    recvChannel = sendChannel
  end
end, false)


menu.action(menu.my_root(), lang.format("SEND_MSG_NAME"), { "chat", "c" }, lang.format("SEND_MSG_DESC") .. "\n\n" .. lang.format("SEND_CHAT_AS", user), function(_)
  menu.show_command_box("chat ")
end, function(args)
  async_http.init("stand-chat.jackz.me", "/channels/" .. sendChannel .. "?v=" .. VERSION, function(result)
    if result == "OK" or result == "Bad Request" then
      table.insert(messages, {
        u = user,
        c = args:sub(1,100),
        t = util.current_unix_time_millis() * 1000,
        l = sendChannel
      })
    elseif result == "MAINTENANCE" then
      lang.toast("SEND_MAINTENANCE")
    else
      lang.toast("SEND_ERR", result)
    end
  end)
  async_http.set_post("application/json", json.encode({
    user = user,
    content = args,
    hash = keyhash
  }))
  async_http.dispatch()
end)


util.create_tick_handler(function(_)
  waiting = true
  async_http.init("stand-chat.jackz.me", "/channels/" .. recvChannel .. "/" .. lastTimestamp, function(body)
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
  local now = util.current_unix_time_millis() * 1000
  local width = 0.0
  for a, msg in ipairs(messages) do
    if now - msg.t > textTime then
      table.remove(messages, a)
    else
      local content
      if msg.ip then
        content = msg.l and string.format("[%s] [%s] %s: %s", msg.ip, msg.l, msg.u, msg.c) or string.format("[%s] %s: %s", msg.ip, msg.u, msg.c)
      else
        content = msg.l and string.format("[%s] %s: %s", msg.l, msg.u, msg.c) or (msg.u .. ": " .. msg.c)
      end
      -- compute largest width of chat box
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
    directx.draw_text(chatPos.x, chatPos.y - textOffsetSize, lang.format("EXAMPLE_1"), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_text(chatPos.x, chatPos.y - (textOffsetSize * 2), lang.format("EXAMPLE_2"), ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_rect(chatPos.x, chatPos.y - (textOffsetSize * 2) - (textOffsetSize / 2), 0.3 + 0.2 * textSize, textOffsetSize * 2, bgColor)
  end
	util.yield()
end