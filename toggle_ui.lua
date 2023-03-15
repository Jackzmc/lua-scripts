-- Test - 1.0
-- Created By Jackz

require("natives-1627063482")

local radarEnabled = true
menu.toggle(menu.my_root(), "Toggle Radar", {"toggleradar"}, "", function(on)
    HUD.DISPLAY_RADAR(on)
end, true)

util.keep_running()