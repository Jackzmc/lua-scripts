-- Actions
-- Created By Jackz
local SCRIPT = "actions"
local VERSION = "1.7.2"
-- Remove these lines if you want to disable update-checks: (6-11)
util.async_http_get("jackz.me", "/stand/updatecheck.php?ucv=2&script=" .. SCRIPT .. "&v=" .. VERSION, function(result)
    chunks = {}
    for substring in string.gmatch(result, "%S+") do
        table.insert(chunks, substring)
    end
    if chunks[1] == "OUTDATED" then
        util.toast(SCRIPT .. " has a new version available.\n" .. VERSION .. " -> " .. chunks[2] .. "\nDownload the latest version from https://jackz.me/sz")
    end
end)
-- Start Library Requirements
local status, json = pcall(require, "json")
if not status then
    WaitingLibsDownload = true
    util.async_http_get("jackz.me", "/stand/libs/json.lua", function(result)
        local file = io.open(filesystem.scripts_dir() .. "/lib/json.lua", "w")
        io.output(file)
        io.write(result)
        io.close(file)
        WaitingLibsDownload = false
        util.toast(SCRIPT .. ": Automatically downloaded missing lib 'json'")
        json = require(file)
    end, function(e)
        util.toast(SCRIPT .. " cannot load: Library files are missing. (json)", 10)
        util.stop_script()
    end)
end
local WaitingLibsDownload = false
function try_load_lib(lib)
    local status = pcall(require, lib)
    if not status then
        WaitingLibsDownload = true
        util.async_http_get("jackz.me", "/stand/libs/" .. lib .. ".lua", function(result)
            local file = io.open(filesystem.scripts_dir() .. "/lib/" .. lib .. ".lua", "w")
            io.output(file)
            io.write(result)
            io.close(file)
            WaitingLibsDownload = false
            util.toast(SCRIPT .. ": Automatically downloaded missing lib '" .. lib .. ".lua'")
            require(lib)
        end, function(e)
            util.toast(SCRIPT .. " cannot load: Library files are missing. (" .. lib .. ")", 10)
            util.stop_script()
        end)
    end
end
try_load_lib("natives-1627063482")
try_load_lib("animations")

while WaitingLibsDownload do
    util.yield()
end
-- Check if animations library is incorrect
if ANIMATIONS_INDEX_VERSION ~= "3.0" then
    util.toast(SCRIPT .. " cannot load: Library file 'animations.lua' is out of date. Please update the file!", 2)
    util.stop_script()
end
-- START Scenario Data
local SCENARIOS = {
    HUMAN = {
        { "WORLD_HUMAN_AA_COFFEE", "AA Coffee" },
        { "WORLD_HUMAN_AA_SMOKE", "AA Smoking" },
        { "WORLD_HUMAN_BINOCULARS", "Binoculars" },
        { "WORLD_HUMAN_BUM_FREEWAY", "Bum Freeway" },
        { "WORLD_HUMAN_BUM_SLUMPED", "Bum Slumped" },
        { "WORLD_HUMAN_BUM_STANDING", "Bum Standing" },
        { "WORLD_HUMAN_BUM_WASH", "Bum Wash" },
        { "WORLD_HUMAN_CAR_PARK_ATTENDANT", "Car Park Attendant" },
        { "WORLD_HUMAN_CHEERING", "Cheering" },
        { "WORLD_HUMAN_CLIPBOARD", "Clipboard" },
        { "WORLD_HUMAN_CONST_DRILL", "Drill" },
        { "WORLD_HUMAN_COP_IDLES", "Cop Idle" },
        { "WORLD_HUMAN_DRINKING", "Drinking" },
        { "WORLD_HUMAN_DRUG_DEALER", "Drug Dealer" },
        { "WORLD_HUMAN_DRUG_DEALER_HARD", "Drug Dealer Hard" },
        { "WORLD_HUMAN_MOBILE_FILM_SHOCKING", "Phone Filming" },
        { "WORLD_HUMAN_GARDENER_LEAF_BLOWER", "Leaf Blower" },
        { "WORLD_HUMAN_GARDENER_PLANT", "Gardener" },
        { "WORLD_HUMAN_GOLF_PLAYER", "Golfing" },
        { "WORLD_HUMAN_GUARD_PATROL", "Guard Patrol" },
        { "WORLD_HUMAN_GUARD_STAND", "Guard Stand" },
        { "WORLD_HUMAN_GUARD_STAND_ARMY", "Guard Stand (Army)" },
        { "WORLD_HUMAN_HAMMERING", "Hammering" },
        { "WORLD_HUMAN_HANG_OUT_STREET", "Hanging Out" },
        { "WORLD_HUMAN_HIKER_STANDING", "Hiker Standing" },
        { "WORLD_HUMAN_HUMAN_STATUE", "Human Statue" },
        { "WORLD_HUMAN_JANITOR", "Janitor" },
        { "WORLD_HUMAN_JOG_STANDING", "Jog in place" },
        { "WORLD_HUMAN_LEANING", "Leaning" },
        { "WORLD_HUMAN_MAID_CLEAN", "Cleaning" },
        { "WORLD_HUMAN_MUSCLE_FLEX", "Muscle Flex" },
        { "WORLD_HUMAN_MUSCLE_FREE_WEIGHTS", "Weights" },
        { "WORLD_HUMAN_MUSICIAN", "Musician" },
        { "WORLD_HUMAN_PAPARAZZI", "Paparazzi" },
        { "WORLD_HUMAN_PARTYING", "Partying" },
        { "WORLD_HUMAN_PICNIC", "Picnic" },
        { "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS", "Prositute (High Class)" },
        { "WORLD_HUMAN_PROSTITUTE_LOW_CLASS", "Prostitute (Low Class)" },
        { "WORLD_HUMAN_PUSH_UPS", "Push Ups" },
        { "WORLD_HUMAN_SEAT_LEDGE", "Ledge Sit" },
        { "WORLD_HUMAN_SEAT_LEDGE_EATING", "Ledge Eating" },
        { "WORLD_HUMAN_SEAT_STEPS", "Sit on Steps" },
        { "WORLD_HUMAN_SEAT_WALL", "Sit on Wall" },
        { "WORLD_HUMAN_SEAT_WALL_EATING", "Eat on Wall" },
        { "WORLD_HUMAN_SEAT_WALL_TABLET", "Tablet on Wall" },
        { "WORLD_HUMAN_SECURITY_SHINE_TORCH", "Shine Torch" },
        { "WORLD_HUMAN_SIT_UPS", "Situps" },
        { "WORLD_HUMAN_SMOKING", "Smoking" },
        { "WORLD_HUMAN_SMOKING_POT", "Smoking Pot" },
        { "WORLD_HUMAN_STAND_FIRE", "Campfire" },
        { "WORLD_HUMAN_STAND_FISHING", "Fishing" },
        { "WORLD_HUMAN_STAND_IMPATIENT", "Impatient" },
        { "WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT", "Impatient Upright" },
        { "WORLD_HUMAN_STAND_MOBILE", "Phone" },
        { "WORLD_HUMAN_STAND_MOBILE_UPRIGHT", "Phone Upright" },
        { "WORLD_HUMAN_STRIP_WATCH_STAND", "Watch Stand" },
        { "WORLD_HUMAN_STUPOR", "Stupor" },
        { "WORLD_HUMAN_SUNBATHE", "Sunbathe" },
        { "WORLD_HUMAN_SUNBATHE_BACK", "Sunbathe Back" },
        { "WORLD_HUMAN_SUPERHERO", "Superhero" },
        { "WORLD_HUMAN_SWIMMING", "Swimming" },
        { "WORLD_HUMAN_TENNIS_PLAYER", "Tennis Player" },
        { "WORLD_HUMAN_TOURIST_MAP", "Tourist Map" },
        { "WORLD_HUMAN_TOURIST_MOBILE", "Tourist Phone" },
        { "WORLD_HUMAN_VEHICLE_MECHANIC", "Mechanic" },
        { "WORLD_HUMAN_WELDING", "Welding" },
        { "WORLD_HUMAN_WINDOW_SHOP_BROWSE", "Window Browsing" },
        { "WORLD_HUMAN_YOGA", "Yoga" }
    },
    HUMAN2 = {
        { "PROP_HUMAN_ATM", "ATM" },
        { "PROP_HUMAN_BBQ", "BBQ" },
        { "PROP_HUMAN_BUM_BIN", "Bum Bin" },
        { "PROP_HUMAN_BUM_SHOPPING_CART", "BUM Shopping Cart" },
        { "PROP_HUMAN_MUSCLE_CHIN_UPS", "Muscle Chinups" },
        { "PROP_HUMAN_MUSCLE_CHIN_UPS_ARMY", "Muscle Chinups (Army)" },
        { "PROP_HUMAN_MUSCLE_CHIN_UPS_PRISON", "Muscle Chinups (Prison)" },
        { "PROP_HUMAN_PARKING_METER", "Parking Meter" },
        { "PROP_HUMAN_SEAT_ARMCHAIR", "Sit (Armchair)" },
        { "PROP_HUMAN_SEAT_BAR", "Sit (Bar)" },
        { "PROP_HUMAN_SEAT_BENCH", "Sit (Bench)" },
        { "PROP_HUMAN_SEAT_BENCH_DRINK", "Sit & Drink (Bench)" },
        { "PROP_HUMAN_SEAT_BENCH_DRINK_BEER", "Sit & Drink Beer (Bench)" },
        { "PROP_HUMAN_SEAT_BENCH_FOOD", "Sit & Eat (Bench)" },
        { "PROP_HUMAN_SEAT_BUS_STOP_WAIT", "Bus Stop Wait" },
        { "PROP_HUMAN_SEAT_CHAIR", "Sit (Chair)" },
        { "PROP_HUMAN_SEAT_CHAIR_DRINK", "Sit & Drink (Chair)" },
        { "PROP_HUMAN_SEAT_CHAIR_DRINK_BEER", "Sit & Drink Beer (Chair)" },
        { "PROP_HUMAN_SEAT_CHAIR_FOOD", "Sit & Eat (Chair)" },
        { "PROP_HUMAN_SEAT_CHAIR_UPRIGHT", "Sit Upright (Chair)" },
        { "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", "Sit MP Player" },
        { "PROP_HUMAN_SEAT_COMPUTER", "Sit (Computer)" },
        { "PROP_HUMAN_SEAT_DECKCHAIR", "Sit (Deckchair)" },
        { "PROP_HUMAN_SEAT_DECKCHAIR_DRINK", "Sit & Drink (Deckchair)" },
        { "PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS", "Bench Press" },
        { "PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS_PRISON", "Bench Press (Prison)" },
        { "PROP_HUMAN_SEAT_SEWING", "Sit (Sewing)" },
        { "PROP_HUMAN_SEAT_STRIP_WATCH", "Sit (Stripclub)" },
        { "PROP_HUMAN_SEAT_SUNLOUNGER", "Sit (Sunlounger)" },
        { "PROP_HUMAN_STAND_IMPATIENT", "Impatient" },
        { "CODE_HUMAN_COWER", "Cower" },
        { "CODE_HUMAN_CROSS_ROAD_WAIT", "Cross road wait" },
        { "CODE_HUMAN_PARK_CAR", "Park Car" },
        { "PROP_HUMAN_MOVIE_BULB", "Movie Bulb" },
        { "PROP_HUMAN_MOVIE_STUDIO_LIGHT", "Movie Studio Light" },
        { "CODE_HUMAN_MEDIC_KNEEL", "Medic Kneel" },
        { "CODE_HUMAN_MEDIC_TEND_TO_DEAD", "Medic Tend" },
        { "CODE_HUMAN_MEDIC_TIME_OF_DEATH", "Medic Time of Death" },
        { "CODE_HUMAN_POLICE_CROWD_CONTROL", "Police Crowd Control" },
        { "CODE_HUMAN_POLICE_INVESTIGATE", "Police Investigate" },
        { "CODE_HUMAN_STAND_COWER", "Cower (Standing)" },
        { "EAR_TO_TEXT", "Ear to Text" },
        { "EAR_TO_TEXT_FAT", "Ear to Text (Fat)" },
    },
    ANIMALS = {
        { "WORLD_BOAR_GRAZING", "Boar Grazing" },
        { "WORLD_CAT_SLEEPING_GROUND", "Cat Sleeping (Ground)"},
        { "WORLD_CAT_SLEEPING_LEDGE", "Cat Sleeping (Ledge)" },
        { "WORLD_COW_GRAZING", "Cow Grazing" },
        { "WORLD_COYOTE_HOWL", "Coyote Howl" },
        { "WORLD_COYOTE_REST", "Coyote Rest" },
        { "WORLD_COYOTE_WANDER", "Coyte Wander" },
        { "WORLD_CHICKENHAWK_FEEDING", "Chicken Hawk Feeding" },
        { "WORLD_CHICKENHAWK_STANDING", "Chicken Hawk Standing" },
        { "WORLD_CORMORANT_STANDING", "Cormorant Standing" },
        { "WORLD_CROW_FEEDING", "Crow Feeding" },
        { "WORLD_CROW_STANDING", "Crow Standing" },
        { "WORLD_DEER_GRAZING", "Deer Grazing" },
        { "WORLD_DOG_BARKING_ROTTWEILER", "Dog Barking (Rottweiler)" },
        { "WORLD_DOG_BARKING_RETRIEVER", "Dog Barking (Retriever)" },
        { "WORLD_DOG_BARKING_SHEPHERD", "Dog Barking (Shepherd)" },
        { "WORLD_DOG_SITTING_ROTTWEILER", "Dog Sitting (Rottweiler)" },
        { "WORLD_DOG_SITTING_RETRIEVER", "Dog Sitting (Retriever)" },
        { "WORLD_DOG_SITTING_SHEPHERD", "Dog Sitting (Shepherd)" },
        { "WORLD_DOG_BARKING_SMALL", "Dog Barking (Small)" },
        { "WORLD_DOG_SITTING_SMALL", "Dog Sitting (Small)" },
        { "WORLD_FISH_IDLE", "Fish Idle" },
        { "WORLD_GULL_FEEDING", "Gull Feeding" },
        { "WORLD_GULL_STANDING", "Gull Standing" },
        { "WORLD_HEN_PECKING", "Hen Pecking" },
        { "WORLD_HEN_STANDING", "Hen Standing" },
        { "WORLD_MOUNTAIN_LION_REST", "Mountain Lion Rest" },
        { "WORLD_MOUNTAIN_LION_WANDER", "Mountain Lion Wander" },
        { "WORLD_PIG_GRAZING", "Pig Grazing" },
        { "WORLD_PIGEON_FEEDING", "Pigeon Feeding" },
        { "WORLD_PIGEON_STANDING", "Pigeon Standing" },
        { "WORLD_RABBIT_EATING", "Rabbit Eating" },
        { "WORLD_RATS_EATING", "Rats Eating" },
        { "WORLD_SHARK_SWIM", "Shark Swimming" },
        { "PROP_BIRD_IN_TREE", "Bird in Tree" },
        { "PROP_BIRD_TELEGRAPH_POLE", "Bird on pole" },
    }
}
-- Messy Globals
local scenarioCount = 0
local animationCount = 0

local clearActionImmediately = true
local favorites = {}
local favoritesActions = {}
local recents = {}
local flags = 1
local allowControl = true
local affectType = 0
-----------------------
-- SCENARIOS
----------------------

menu.action(menu.my_root(), "Stop All Actions", {"stopself"}, "Stops the current scenario or animation", function(v)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    if affectType > 0 then
        local peds = util.get_all_peds()
        for _, npc in ipairs(peds) do
            if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(npc)
                if clearActionImmediately then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                end
            end
        end
    end
end)
menu.toggle(menu.my_root(), "Clear Action Immediately", {"clearimmediately"}, "If enabled, will immediately stop the animation / scenario that is playing when activating a new one. If false, you will transition smoothly to the next action.", function(on)
    lclearActionImmediately = on
end, clearActionImmediately)
local affectMenu = menu.slider(menu.my_root(), "Action Targets", {"actiontarget"}, "The entities that will play this action.\n0 = Only yourself\n1 = Only NPCs\n2 = Both you and NPCS", 0, 2, affectType, 1, function(value)
    affectType = value
end)

local animationsMenu = menu.list(menu.my_root(), "Animations", {}, "List of animations you can play")
menu.toggle(animationsMenu, "Controllable", {"animationcontrollable"}, "Should the animation allow player control?", function(on)
    if on then
        flags = 1 | 32
    else
        flags = 1
    end
end, allowControl)

-----------------------
-- ANIMATIONS
----------------------
local resultMenus = {}
local favoritesMenu = menu.list(animationsMenu, "Favorites", {}, "List of all your favorited animations. Hold SHIFT to add or remove from favorites.")
local recentsMenu = menu.list(animationsMenu, "Recents", {}, "List of all your recently played animations")
local searchMenu = menu.list(animationsMenu, "Search", {}, "Search for animation groups")
menu.action(searchMenu, "Search Animation Groups", {"searchanim"}, "Searches all animation groups for the inputted text", function()
    menu.show_command_box("searchanim ")
end, function(args)
    -- Delete existing results
    for _, m in ipairs(resultMenus) do
        menu.delete(m)
    end
    resultMenus = {}
    -- Find all possible groups
    local results = {}
    -- loop ANIMATIONS by heading then subheading then insert based on result
    for _, result in ipairs(ANIMATIONS) do
        local res = string.find(result[1], args)
        if res then
            table.insert(results, {
                result[1], result[2]
            })
        end
    end
    for _, header in ipairs(ANIMATIONS_HEADINGS) do
        for _, subheader in pairs(ANIMATIONS_SUBHEADINGS[header]) do
            for _, section in ipairs(ANIMATIONS[header][subheader]) do
                local res = string.find(section[1], args)
                if res then
                    table.insert(results, {
                        section[1], section[2]
                    })
                end
            end
        end
    end
    -- Sort by ascending start Index
    table.sort(results, function(a, b) return a[2] < b[2] end)
    -- Messy, but no way to call a list group, so recreate all animations in a sublist:
    for i = 1, 101 do
        if results[i] then
            -- local m = menu.list(searchMenu, group, {}, "All animations for " .. group)
           local m = menu.action(searchMenu, results[i][2], {"animate" .. results[i][1] .. " " .. results[i][2]}, "Plays the " .. results[i][2] .. " animation from group " .. results[i][1], function(v)
                play_animation(results[i][1], results[i][2], false)
            end)
            table.insert(resultMenus, m)
        end
    end
end)
local menus = {
    headers = {},
    subheaders = {}
}
for _, header in ipairs(ANIMATIONS_HEADINGS) do
    if not menus[header] then
        menus.headers[header] = menu.list(animationsMenu, header)
    end
    for _, subheader in pairs(ANIMATIONS_SUBHEADINGS[header]) do
        if not menus.subheaders[header .. subheader] then
            menus.subheaders[header .. subheader] = menu.list(menus.headers[header], subheader, {}, "")
        end
        for _, section in ipairs(ANIMATIONS[header][subheader]) do
            animationCount = animationCount + 1
            menu.action(menus.subheaders[header .. subheader], section[2], {"animate" .. section[1] .. " " .. section[2]}, "Plays the " .. section[2] .. " animation from group " .. section[1], function(v)
                play_animation(section[1], section[2], false)
            end)
        end
    end
end

local scenariosMenu = menu.list(menu.my_root(), "Scenarios", {}, "List of scenarios you can play\nSome scenarios only work on certain genders, example AA Coffee only works on male peds.")
for group, scenarios in pairs(SCENARIOS) do
    local submenu = menu.list(scenariosMenu, group, {}, "All " .. group .. " scenarios")
    for _, scenario in ipairs(scenarios) do
        scenarioCount = scenarioCount + 1
        menu.action(submenu, scenario[2], {"scenario"}, "Plays the " .. scenario[2] .. " scenario", function(v)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            
            -- Play scenario on all npcs if enabled:
            if affectType > 0 then
                local peds = util.get_all_peds()
                for _, npc in ipairs(peds) do
                    if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(npc)
                        if clearActionImmediately then
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                        end
                        TASK.TASK_START_SCENARIO_IN_PLACE(npc, scenario[1], 0, true);
                    end
                end
            end
            -- Play scenario on self if enabled:
            if affectType == 0 or affectType == 2 then
                if clearActionImmediately then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                end
                TASK.TASK_START_SCENARIO_IN_PLACE(ped, scenario[1], 0, true);
            end
        end)
    end
end
-----------------------
-- Speeches
----------------------
-- START Speech Data
local SPEECH_PARAMS = {
    { "Normal", "Speech_Params_Force" },
    { "In Your Head", "Speech_Params_Force_Frontend", "Plays the voice as if nearby npcs are inside you" },
    { "Beat", "SPEECH_PARAMS_BEAT" },
    { "Megaphone", "Speech_Params_Force_Megaphone" },
    { "Helicopter", "Speech_Params_Force_Heli" },
    { "Shouted", "Speech_Params_Force_Shouted" },
    { "Shouted (Critical)", "Speech_Params_Force_Shouted_Critical" },
}
local SPEECHES = {
    { "Greeting", "GENERIC_HI" },
    { "Farewell", "GENERIC_BYE" },
    { "Bumped Into", "BUMP" },
    { "Chat", "CHAT_RESP" },
    { "Death Moan", "DYING_MOAN" },
    { "Apology", "APOLOGY_NO_TROUBLE" },
    { "Thanks", "GENERIC_THANKS" },
    { "Fuck You", "GENERIC_FUCK_YOU" },
    { "War Cry", "GENERIC_WAR_CRY" },
    { "Fallback", "FALL_BACK" },
    { "Cover Me", "COVER_ME" },
    { "Swear", "GENERIC_CURSE_HIGH" },
    { "Insult", "GENERIC_INSULT_HIGH" },
    { "Shocked", "GENERIC_SHOCKED_HIGH" },
    { "Frightened", "GENERIC_FRIGHTENED_HIGH" },
    { "Kiflom", "KIFFLOM_GREET", "Works best with epsilon voice models" },
}
local VOICE_MODELS = {
    FEMALE = {
        "a_f_m_bevhills_01",
        "a_f_y_vinewood_01",
        "a_f_y_hipster_02",
        "a_f_y_femaleagent",
        "a_f_y_bevhills_01",
        "a_f_m_tramp_01",
        "a_f_m_soucentmc_01",
        "a_f_m_fatwhite_01",
        "a_f_y_tourist_01",
        "a_f_y_gencaspat_01",
        "a_f_y_smartcaspat_01",
        "a_f_y_epsilon_01",
        "a_f_o_salton_01",
        "a_f_m_beach_01"
    },
    MALE = {
        "a_m_m_beach_01",
        "a_m_m_hasjew_01",
        "a_m_m_hillbilly_01",
        "a_m_m_golfer_01",
        "a_m_m_genfat_01",
        "a_m_m_salton_02",
        "a_m_m_tourist_01",
        "a_m_m_soucent_01",
        "a_m_o_tramp_01",
        "a_m_y_beachvesp_01",
        "a_m_y_epsilon_01",
        "a_m_y_epsilon_02",
        "a_m_y_jetski_01",
        "a_m_y_vinewood_03",
        "a_m_m_acult_01",
        "u_m_m_jesus_01",
        "s_m_y_sheriff_01_white_full_01"
    }
}
local selfSpeechPed = {
    entity = 0,
    lastUsed = util.current_unix_time_millis(),
    model = util.joaat("a_f_m_bevhills_01")
}
-- Messy globals again
local speechParam = "Speech_Params_Force"
local activeSpeech = "GENERIC_HI"
local duration = 1
local speechDelay = 1000
local repeatEnabled = false
local ambientSpeechMenu = menu.list(menu.my_root(), "Ambient Speech", {}, "Allow you to play ambient speeches on yourself or other peds")
local speechMenu = menu.list(ambientSpeechMenu, "Speech Lines", {"speechlines"}, "List of Speeches peds can say.\nSome lines may not work on some NPCs")
for _, pair in ipairs(SPEECHES) do
    local desc = pair[2]
    if pair[3] then
        desc = desc .. "\n" .. pair[3]
    end
    menu.action(speechMenu, pair[1], {"speak" .. string.lower(pair[1])}, desc, function(a)
        -- Play single duration for peds
        if affectType > 0 then
            if duration > 0 then
                for _, ped in ipairs(util.get_all_peds()) do
                    if not PED.IS_PED_A_PLAYER(ped) then
                        if duration > 1 then
                            util.create_thread(function()
                                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                                for x = 1,duration do
                                    AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, pair[2], speechParam)
                                    util.yield(speechDelay)
                                end
                            end)
                        else
                            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, pair[2], speechParam)
                        end
                    end
                end
            else
                
            end
        end
        -- Play single duration for self
        if affectType == 0 or affectType == 2 then
            if selfSpeechPed.entity == 0 then
                create_self_speech_ped()
            end
            util.create_thread(function()
                local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                for x = 1,duration do
                    AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(selfSpeechPed.entity, pair[2], speechParam)
                    util.yield(speechDelay)
                end
            end)
            selfSpeechPed.lastUsed = util.current_unix_time_millis()
            --TODO: implement
        end
        -- Play repeated for self or peds
        if duration == 0 then
            activeSpeech = pair[2]
            if not repeatEnabled then
                repeatEnabled = true
                if selfSpeechPed.entity == 0 and affectType ~= 1 then
                    create_self_speech_ped()
                end
                util.create_tick_handler(function(a)
                    if affectType > 0 then
                        for _, ped in ipairs(util.get_all_peds()) do
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, activeSpeech, speechParam)
                        end
                    end
                    if selfSpeechPed.entity > 0 and affectType == 0 or affectType == 2 then
                        AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(selfSpeechPed.entity, activeSpeech, speechParam)
                        selfSpeechPed.lastUsed = util.current_unix_time_millis()
                    end
                    util.yield(speechDelay)
                    return repeatEnabled
                end)
            end
        end
    end)
end
local speechType = menu.list(ambientSpeechMenu, "Speech Method", {"speechmethods", "How is the line said"})
for _, pair in ipairs(SPEECH_PARAMS) do
    menu.action(speechType, pair[1], {}, pair[2], function(a)
        speechParam = pair[2]
    end)
end
local selfModelVoice = menu.list(ambientSpeechMenu, "Self Model Voice", {"selfvoice", "What model to use when playing a self-ambient speech\nOnly used if your current model is MP (Fe)male"})
menu.divider(selfModelVoice, "Female Peds")
for _, model in ipairs(VOICE_MODELS.FEMALE) do
    menu.action(selfModelVoice, model, {"voice" .. model}, "Uses \"" .. model .. "\" model as your ambient speech voice", function(a)
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            util.delete_entity(selfSpeechPed.entity)
            selfSpeechPed.entity = 0
        end
        selfSpeechPed.model = util.joaat(model)
    end)
end
menu.divider(selfModelVoice, "Male Peds")
for _, model in ipairs(VOICE_MODELS.MALE) do
    menu.action(selfModelVoice, model, {"voice" .. model}, "Uses \"" .. model .. "\" model as your ambient speech voice", function(a)
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            util.delete_entity(selfSpeechPed.entity)
            selfSpeechPed.entity = 0
        end
        selfSpeechPed.model = util.joaat(model)
    end)
end

menu.slider(ambientSpeechMenu, "Duration", {"speechduration"}, "How many times should the speech be played?\n 0 to play forever, use 'Stop Active Speech' to end.", 0, 100, duration, 1, function(value)
    duration = value
end)
menu.slider(ambientSpeechMenu, "Speech Interval", {"speechinterval"}, "How many milliseconds per repeat of line?", 100, 30000, speechDelay, 100, function(value)
    speechDelay = value
end)
menu.action(ambientSpeechMenu, "Stop Active Speech", {"stopspeeches"}, "Stops any active ambient speeches", function(a)
    for _, ped in ipairs(util.get_all_peds()) do
        AUDIO.STOP_CURRENT_PLAYING_AMBIENT_SPEECH(ped)
    end
    -- reuse code cause why not its 11:57 pm I don't care now
    if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
        util.delete_entity(selfSpeechPed.entity)
    end
    selfSpeechPed.entity = 0
    repeatEnabled = false
end)

function create_self_speech_ped()
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local model = ENTITY.GET_ENTITY_MODEL(my_ped)
    -- Freemode models cant do ambient speeches, so we need to change the model to something else:
    if model == util.joaat("mp_f_freemode_01") or model == util.joaat("mp_m_freemode_01") then
        model = selfSpeechPed.model
    end
    -- Load model in
    STREAMING.REQUEST_MODEL(model)
    while not STREAMING.HAS_MODEL_LOADED(model) do
        util.yield()
    end
    -- Finally, spawn it & attach
    local pos = ENTITY.GET_ENTITY_COORDS(my_ped)
    local ped = util.create_ped(1, model, pos, 0)
    ENTITY._ATTACH_ENTITY_BONE_TO_ENTITY_BONE(ped, my_ped, 0, 0, 0, 0)
    ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
    NETWORK._NETWORK_SET_ENTITY_INVISIBLE_TO_NETWORK(ped, true)
    selfSpeechPed.entity = ped
    selfSpeechPed.lastUsed = util.current_unix_time_millis()
end
-----------------------
-- Animation Functions
----------------------
-- Maybe smart deletion but eh
function populate_favorites()
    for _, action in ipairs(favoritesActions) do
        menu.delete(action)
    end
    favoritesActions = {}
    for _, favorite in ipairs(favorites) do
        local name = favorite[2]
        if favorite[3] then
            name = favorite[3] .. " (" .. favorite[2] .. ")"
        end
        local a = menu.action(favoritesMenu, name, {}, "Plays " .. favorite[2] .. " from group " .. favorite[1], function(v)
            play_animation(favorite[1], favorite[2], false)
        end)
        table.insert(favoritesActions, a)
    end
end

function is_anim_in_recent(group, anim)
    for _, recent in ipairs(recents) do
        if recent[1] == group and recent[2] == anim then
            return true
        end
    end
    return false
end

function add_anim_to_recent(group, anim)
    if #recents >= 20 then
        menu.delete(recents[1][3])
        table.remove(recents, 1)
    end
    local action = menu.action(recentsMenu, anim, {"animate" .. group .. " " .. anim}, "Plays the " .. anim .. " animation from group " .. group, function(v)
        play_animation(group, anim, true)
    end)
    table.insert(recents, { group, anim, action })
end

function play_animation(group, anim, ignore)
    if PAD.IS_CONTROL_PRESSED(2, 209) then
        for i, favorite in ipairs(favorites) do
            if favorite[1] == group and favorite[2] == anim then
                table.remove(favorites, i)
                populate_favorites()
                save_favorites()
                util.toast("Removed " .. group .. "\n" .. anim .. " from favorites")
                return
            end
        end
        table.insert(favorites, { group, anim })
        populate_favorites()
        save_favorites()
        util.toast("Added " .. group .. "\n" .. anim .. " to favorites")
    else
        STREAMING.REQUEST_ANIM_DICT(group)
        while not STREAMING.HAS_ANIM_DICT_LOADED(group) do
            util.yield(100)
        end
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        

        if not is_anim_in_recent(group, anim) and not ignore then
            add_anim_to_recent(group, anim)
        end

        -- Play animation on all npcs if enabled:
        if affectType > 0 then
            local peds = util.get_all_peds()
            for _, npc in ipairs(peds) do
                if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                    if clearActionImmediately then
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                    end
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(npc)
                    TASK.TASK_PLAY_ANIM(npc, group, anim, 8.0, 8.0, -1, flags, 1.0, false, false, false)
                end
            end
        end
        -- Play animation on self if enabled:
        if affectType == 0 or affectType == 2 then
            if clearActionImmediately then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            end
            TASK.TASK_PLAY_ANIM(ped, group, anim, 8.0, 8.0, -1, flags, 1.0, false, false, false)
        end
    end
end

------------------------------
-- Loading & Saving Favorites
--------------------------------
local path = filesystem.stand_dir() .. "/Favorite Animations.txt"
if filesystem.exists(path) then
    local headerRead = false
    for line in io.lines(path) do 
        if headerRead then
            chunks = {}
            for substring in string.gmatch(line, "%S+") do
                table.insert(chunks, substring)
            end
            if #chunks == 2 or #chunks == 3 then
                table.insert(favorites, chunks)
            end
        else
            headerRead = true
        end
    end
    populate_favorites()
end
function save_favorites()
    local file = io.open(path, "w")
    io.output(file)
    io.write("category\t\tanimation name\t\talias (no spaces)\n")
    for _, favorite in ipairs(favorites) do
        if favorite[3] then
            io.write(string.format("%s %s %s\n", favorite[1], favorite[2], favorite[3]))
        else
            io.write(string.format("%s %s\n", favorite[1], favorite[2]))
        end
    end
    io.close(file)
end
-----------------------
util.toast("Hold LEFT SHIFT on an animation to add or remove it from your favorites.", 2)
util.toast(string.format("Ped Actions Script %s by Jackz. Loaded %d scenarios, %d animations, and %d favories", VERSION, scenarioCount, animationCount, #favorites), 2)

util.on_stop(function(a)
    if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
        util.delete_entity(selfSpeechPed.entity)
    end
end)

while true do
    if selfSpeechPed.entity > 0 and util.current_unix_time_millis() - selfSpeechPed.lastUsed > 20 then
        if ENTITY.DOES_ENTITY_EXIST(selfSpeechPed.entity) then
            util.delete_entity(selfSpeechPed.entity)
        end
        selfSpeechPed.entity = 0
    end
	util.yield()
end