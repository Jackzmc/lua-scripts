-- Chat Commands Extended - 1.0
-- Created By Jackz

util.require_natives(1660775568)

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

local model_alias = {
    lester = util.joaat("cs_lestercrest"), -- removed cause we have chat command if 'lester' is said anywhere in msg
    simeon = util.joaat("ig_siemonyetarian"),
    jesus = util.joaat("u_m_m_jesus_01"),
    tom = util.joaat("ig_tomcasino"),
    liveinvader = util.joaat("cs_lifeinvad_01")
}


-- TODO: Convert to actual menu.action 

local function spawn_ped_on_player(model, player)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
    if ped > 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(ped, true)

        STREAMING.REQUEST_MODEL(model)
        while not STREAMING.HAS_MODEL_LOADED(model) do
            util.yield()
        end
        entities.create_ped(1, model, pos, 0)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    end
end

chat.on_message(function(sender_player_id, sender_player_name, message, is_team_chat)
    if string.find(string.lower(message), "lester") then
        util.toast(string.format("%s spawned lester", PLAYER.GET_PLAYER_NAME(sender_player_id)))
        spawn_ped_on_player(model_alias['lester'], sender_player_id)
    elseif string.starts(message, "simeon") then
        util.toast(string.format("%s spawned simeon", PLAYER.GET_PLAYER_NAME(sender_player_id)))
        spawn_ped_on_player(model_alias['simeon'], sender_player_id)
    elseif string.starts(message, "jesus") then
        util.toast(string.format("%s spawned jesus", PLAYER.GET_PLAYER_NAME(sender_player_id)))
        spawn_ped_on_player(model_alias['jesus'], sender_player_id)
    elseif string.starts(message, "ped ") then
        -- cs_lifeinvad_01
        -- ig_tomcasino
        local name = message:lower():sub(5)
        local model = model_alias[name]
        if model == nil then
            model = util.joaat(name)
        end
        if STREAMING.IS_MODEL_VALID(model) then
            spawn_ped_on_player(model, sender_player_id)
            util.toast(string.format("%s spawned %s", PLAYER.GET_PLAYER_NAME(sender_player_id), name, model))
        else
            chat.send_targeted_message(sender_player_id, players.user(), "That is not a valid model", is_team_chat)
        end
    end
end)

while true do
    util.yield()
end