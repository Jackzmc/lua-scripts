-- Actions - 1.4
-- Created By Jackz

local v = "1.4"

require("natives-1627063482")
require("animations")

if ANIMATIONS_INDEX_VERSION ~= "3.0" then
    util.toast("Actions cannot load: Library file 'animations.lua' is out of date. Please update the file!", 2)
    util.stop_script()
end

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
local affectMenu = menu.slider(menu.my_root(), "Action Targets", {"actiontarget"}, "The entities that will play this action.\n0 = Self\n1 = NPCs\n2 = Both you and NPCS", 0, 2, affectType, 1, function(value)
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
-- local searchMenu = menu.list(animationsMenu, "Search", {}, "Search for animation groups")
-- menu.action(searchMenu, "Search Animation Groups", {"searchanim"}, "Searches all animation groups for the inputted text", function()
--     menu.show_command_box("searchanim ")
-- end, function(args)
--     -- Delete existing results
--     for _, m in ipairs(resultMenus) do
--         menu.delete(m)
--     end
--     -- Find all possible groups
--     local results = {}
--     for _, result in ipairs(ANIMATIONS) do
--         local res = string.find(result[1], args)
--         if res then
--             table.insert(results, {
--                 result[1], result[2]
--             })
--         end
--     end
--     -- Sort by ascending start Index
--     table.sort(results, function(a, b) return a[2] < b[2] end)
--     -- Messy, but no way to call a list group, so recreate all animations in a sublist:
--     for i = 1, 21 do
--         if results[i] then
--             -- local m = menu.list(searchMenu, group, {}, "All animations for " .. group)
--            local m = menu.action(searchMenu, results[i][2], {"animate" .. results[i][1] .. " " .. results[i][2]}, "Plays the " .. results[i][2] .. " animation from group " .. group, function(v)
--                 play_animation(results[i][1], results[i][2], false)
--             end)
--             table.insert(resultMenus, m)
--         end
--     end
-- end)
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

local scenariosMenu = menu.list(menu.my_root(), "Scenarios", {}, "List of scenarios you can play")
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
util.toast(string.format("Ped Actions Script %s by Jackz. Loaded %d scenarios, %d animations, and %d favories", v, scenarioCount, animationCount, #favorites), 2)

while true do
	util.yield()
end