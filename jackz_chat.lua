-- Stand Chat 
-- Created By Jackz
local SCRIPT = "jackz_chat"
local VERSION = "1.0.2"
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
local WaitingLibsDownload = false
function try_load_lib(lib, globalName)
    local status, f = pcall(require, string.sub(lib, 0, #lib - 4))
    if not status then
        WaitingLibsDownload = true
        async_http.init("jackz.me", "/stand/libs/" .. lib, function(result)
            -- FIXME: somehow only writing 1 KB file
            local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib, "w")
            io.output(file)
            io.write(result)
            io.flush() -- redudant, probably?
            io.close(file)
            util.toast(SCRIPT .. ": Automatically downloaded missing lib '" .. lib .. "'")
            if globalName then
                _G[globalName] = require(string.sub(lib, 0, #lib - 4))
            end
            WaitingLibsDownload = false
        end, function(e)
            util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
            util.stop_script()
        end)
        async_http.dispatch()
    elseif globalName then
        _G[globalName] = f
    end
end
try_load_lib("natives-1627063482.lua")
try_load_lib("json.lua", "json")
-- If script is actively downloading new update, wait:
while WaitingLibsDownload do
    util.yield()
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
local textTime = 30000

local optionsMenu = menu.list(menu.my_root(), "Chat Box Design", {}, "Change how the chatbox looks")
menu.on_blur(optionsMenu, function(_)
  showExampleMessage = false
end)
local submenus = { optionsMenu }
table.insert(submenus, menu.colour(optionsMenu, "Chat Color", {"standchatcolor"}, "Sets the color the stand chat will use", textColor, false, function(color)
  textColor = color
end))
table.insert(submenus, menu.colour(optionsMenu, "Background Color", {"standchatbgcolor"}, "Sets the background color the stand chat will use", bgColor, true, function(color)
  bgColor = color
end))
table.insert(submenus, menu.slider(optionsMenu, "X Position", {"standx"}, "Sets the X position the chat appears", -32768, 32767, chatPos.x * 100, 1, function(x)
  chatPos.x = x / 100
end))
table.insert(submenus, menu.slider(optionsMenu, "Y Position", {"standy"}, "Sets the Y position the chat appears", -32768, 32767, chatPos.y * 100, 1, function(y)
  chatPos.y = y / 100
end))
table.insert(submenus, menu.slider(optionsMenu, "Text Size", {"standchatsize"}, "Sets the text size the chat uses", 20, 100, textSize * 100, 1, function(size)
  textSize = size / 100
  local _, height = directx.get_text_size("Example", textSize)
  textOffsetSize = height
end))
table.insert(submenus, menu.slider(optionsMenu, "Message Duration", {"standchatmsgtime"}, "How long until a message disappears in seconds?", 15, 120, 30, 1, function(time)
  textTime = time * 1000
end))
for _, submenu in ipairs(submenus) do
  menu.on_focus(submenu, function(_)
    showExampleMessage = true
  end)
end

local channelList = menu.list(menu.my_root(), "Channels", {}, "Switch to other channels if one is too active or you wish to chat privately")
local channels = { "default", "english" }
for _, lang in ipairs(channels) do
  menu.action(channelList, lang, {"chatlang" .. lang}, "Chat in the " .. lang .. " channel", function(_)
    sendChannel = lang
    recvChannel = sendChannel
    util.toast("Switched chat channel to " .. lang)
  end)
end
menu.action(channelList, "Enter a specific channel", { "chatchannel" } , "Chat & receive messages from a specific channel. Useful to message any of your friends privately.\nChannel ID must be an alphanumeric id (letters and numbers only)", function(_)
  menu.show_command_box("chatchannel ")
end, function(args)
  args = args:gsub('%W','')
  if string.len(args) == 0 or args == "_all" or args == "system" then
    -- Before you try to bypass this, it's handled on the server side. 
    util.toast("Invalid channel entered")
  else
    sendChannel = string.lower(args)
    recvChannel = sendChannel
    util.toast("Switched chat channel to " .. sendChannel)
  end
end)

menu.toggle(menu.my_root(), "Receive messages from all channels", {"chatglobal"}, "Enabled, you will receive messages from all channels\nDisabled, you will only receive messages from your active channel", function(on)
  if on then
    recvChannel = "_all"
  else
    recvChannel = sendChannel
  end
end, false)

menu.action(menu.my_root(), "Send Message", {"chat"}, "Sends a chat message to all online stand users.\n\nNote: Racism, spamming, or any form of harassment is not tolerated and will result in your account being banned from chatting. Don't be a dick.", function(_)
  menu.show_command_box("chat ")
end, function(args)
  async_http.init("stand-chat.jackz.me", "/" .. sendChannel .. "?v=" .. VERSION, function(result)
    if result == "OK" or result == "Bad Request" then
      table.insert(messages, {
        u = user,
        c = args:sub(1,100),
        t = util.current_unix_time_millis() * 1000,
        l = sendChannel
      })
    elseif result == "MAINTENANCE" then
      util.toast("Chat server is in maintenance mode, cannot send.")
    else
      util.toast("Chat server returned " .. result)
    end
  end)
  async_http.set_post("application/json", json.encode({
    user = user,
    content = args
  }))
  async_http.dispatch()
end)


util.create_tick_handler(function(_)
  waiting = true
  async_http.init("stand-chat.jackz.me", "/" .. recvChannel .. "/" .. lastTimestamp, function(body)
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
  if devToken then
    async_http.add_header("x-dev-token", devToken)
  end
  async_http.dispatch()
  while waiting do
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
    directx.draw_text(chatPos.x, chatPos.y - textOffsetSize, "Example: Welcome to Stand Chat.", ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_text(chatPos.x, chatPos.y - (textOffsetSize * 2), "Example: This is some example text. Have you tried jackz_vehicles? I heard it's a great script.", ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_rect(chatPos.x, chatPos.y - (textOffsetSize * 2) - (textOffsetSize / 2), 0.3 + 0.2 * textSize, textOffsetSize * 2, bgColor)
  end
	util.yield()
end