-- Stand Chat 
-- Created By Jackz
local SCRIPT = "jackz_chat"
local VERSION = "1.0.0"
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
-- TODO: use oracle cloud for chat

local lastTimestamp = util.current_unix_time_millis() * 1000
local messages = {}
local user = SOCIALCLUB._SC_GET_NICKNAME()
local waiting = false 
local showExampleMessage = false

local textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
local bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.3 }
local chatPos = { x = 0.0, y = 0.4 }
local textOffsetSize = 0.02
local textSize = 0.5

local optionsMenu = menu.list(menu.my_root(), "Options")
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
for _, submenu in ipairs(submenus) do
  menu.on_focus(submenu, function(_)
    showExampleMessage = true
  end)
end


menu.action(menu.my_root(), "Send Message", {"chat"}, "", function(_)
  menu.show_command_box("chat ")
end, function(args)
  async_http.init("stand-chat.jackz.me", "/chat", function(result)
    if result == "OK" then 
      table.insert(messages, {
        user = user,
        content = args,
        timestamp = util.current_unix_time_millis() * 1000
      })
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
  async_http.init("stand-chat.jackz.me", "/messages/" .. lastTimestamp, function(body)
    if body[1] == "{" then
      local data = json.decode(body)
      for _, message in ipairs(data.messages) do
        if message.user ~= user then
          table.insert(messages, message)
        end
      end
      lastTimestamp = data.timestamp
      waiting = false
    end
  end, function(err) util.toast("err" .. err) end)
  async_http.dispatch()
  while waiting do
    util.yield()
  end
  util.yield(5000)
  return true
end)

while true do
  local i = 0
  local now = util.current_unix_time_millis() * 1000
  local width = 0.0
  for a, msg in ipairs(messages) do
    if now - msg.timestamp > 15000 then
      table.remove(messages, a)
    else
      local content = msg.user .. ": " .. msg.content
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
    directx.draw_text(chatPos.x, chatPos.y - (textOffsetSize * 2), "Example: Welcome to Stand Chat.", ALIGN_CENTRE_LEFT, textSize, textColor, true)
    directx.draw_rect(chatPos.x, chatPos.y - (textOffsetSize * 2) - (textOffsetSize / 2), 0.1 + 0.2 * textSize, textOffsetSize * 2, bgColor)
  end
  -- util.create_thread(function()
  --   util.toast(luahttp.request("POST", "mc.jackz.me", "/chat", string.format("{\"sender_id\":\"%s\",\"message\":\"%s\"}", sender_player_name, message), "", 8080, "application/json", "LuaChat/V" .. v))
  -- end)
	util.yield()
end