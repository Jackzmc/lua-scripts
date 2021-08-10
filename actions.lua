-- Actions - 1.0
-- Created By Jackz

local v = "1.0"

require("natives-1627063482")
require("animations")

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
local animationGroupCount = 0
local animationCount = 0



-- TASK_START_SCENARIO_IN_PLACE(Ped ped, char* scenarioName, int unkDelay, BOOL playEnterAnim);
menu.action(menu.my_root(), "Stop All", {"stopself"}, "Stops the current scenario or animation", function(v)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
end)

local flags = 1
local allowControl = true
local animationsMenu = menu.list(menu.my_root(), "Animations", {}, "List of animations you can play")
menu.toggle(animationsMenu, "Controllable", {"animationcontrollable"}, "Should the animation allow player control?", function(on)
    if on then
        flags = 1 | 32
    else
        flags = 1
    end
end, allowControl)
local resultMenus = {}
local searchMenu = menu.list(animationsMenu, "Search", {}, "Search for animation groups")
menu.action(searchMenu, "Search Animation Groups", {"searchanim"}, "Searches all animation groups for the inputted text", function()
    menu.show_command_box("searchanim ")
end, function(args)
    -- Delete existing results
    for _, m in ipairs(resultMenus) do
        menu.delete(m)
    end
    -- Find all possible groups
    local results = {}
    for group, _ in pairs(ANIMATIONS) do
        local res = string.find(group, args)
        if res then
            table.insert(results, {
                group, res
            })
        end
    end
    -- Sort by ascending start Index
    table.sort(results, function(a, b) return a[2] < b[2] end)
    -- Messy, but no way to call a list group, so recreate all animations in a sublist:
    for i = 1, 21 do
        local group = results[i][1]
        local m = menu.list(searchMenu, group, {}, "All animations for " .. group)
        for _, anim in ipairs(ANIMATIONS[group]) do
            menu.action(m, anim, {"animate" .. group .. " " .. anim}, "Plays the " .. anim .. " animation", function(v)
                STREAMING.REQUEST_ANIM_DICT(group)
                while not STREAMING.HAS_ANIM_DICT_LOADED(group) do
                    util.yield(100)
                end
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                TASK.TASK_PLAY_ANIM(ped, group, anim, 8.0, 8.0, -1, flags, 1.0, false, false, false);
            end)
        end
        table.insert(resultMenus, m)
    end
end)
for group, animations in pairs(ANIMATIONS) do
    animationGroupCount = animationGroupCount + 1
    local submenu = menu.list(animationsMenu, group, {}, "All animations for " .. group)
    for _, anim in ipairs(animations) do
        animationCount = animationCount + 1
        menu.action(submenu, anim, {"animate" .. group .. " " .. anim}, "Plays the " .. anim .. " animation", function(v)
            STREAMING.REQUEST_ANIM_DICT(group)
            while not STREAMING.HAS_ANIM_DICT_LOADED(group) do
                util.yield(100)
            end
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.TASK_PLAY_ANIM(ped, group, anim, 8.0, 8.0, -1, flags, 1.0, false, false, false);
        end)
    end
end

local scenariosMenu = menu.list(menu.my_root(), "Scenarios", {}, "List of scenarios you can play")
for group, scenarios in pairs(SCENARIOS) do
    local submenu = menu.list(scenariosMenu, group, {}, "All " .. group .. " scenarios")
    for _, scenario in ipairs(scenarios) do
        scenarioCount = scenarioCount + 1
        menu.action(submenu, scenario[2], {"scenario"}, "Plays the " .. scenario[2] .. " scenario", function(v)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            TASK.TASK_START_SCENARIO_IN_PLACE(ped, scenario[1], 0, true);
        end)
    end
end

util.toast(string.format("Ped Actions Script %s by Jackz. Loaded %d scenarios, %d animation groups and %d animations", v, scenarioCount, animationGroupCount, animationCount))

while true do
	util.yield()
end