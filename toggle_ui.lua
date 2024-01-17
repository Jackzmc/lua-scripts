-- Test - 1.0
-- Created By Jackz

util.require_natives(1660775568)

local radarEnabled = true
menu.toggle(menu.my_root(), "Toggle Radar", {"toggleradar"}, "", function(on)
    HUD.DISPLAY_RADAR(on)
end, true)

util.keep_running()