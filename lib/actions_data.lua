-- Taken & Modified from FiveM dpemotes https://github.com/andristum/dpemotes/blob/master/Client/AnimationList.lua
AnimationFlags = {
    ANIM_FLAG_NORMAL = 0,
    ANIM_FLAG_REPEAT = 1,
    ANIM_FLAG_STOP_LAST_FRAME = 2,
    ANIM_FLAG_UPPERBODY = 16,
    ANIM_FLAG_ENABLE_PLAYER_CONTROL = 32,
    ANIM_FLAG_CANCELABLE = 120,
}
SPECIAL_ANIMATIONS = {
 Interaction = {
    ["handshake"] = {
       "mp_ped_interaction",
       "handshake_guy_a",
       "Handshake",
       AnimationOptions = {
          TargetAnimation = "handshake2",
          Controllable = true,
          EmoteDuration = 3000,
          SyncOffsetFront = 0.9
       }
    },
    ["handshake2"] = {
       "mp_ped_interaction",
       "handshake_guy_b",
       "Handshake 2",
       AnimationOptions = {
          TargetAnimation = "handshake",
          Controllable = true,
          EmoteDuration = 3000
       }
    },
    ["hug"] = {
       "mp_ped_interaction",
       "kisses_guy_a",
       "Hug",
       AnimationOptions = {
          TargetAnimation = "hug2",
          Controllable = false,
          EmoteDuration = 5000,
          SyncOffsetFront = 1.05
       }
    },
    ["hug2"] = {
       "mp_ped_interaction",
       "kisses_guy_b",
       "Hug 2",
       AnimationOptions = {
          TargetAnimation = "hug",
          Controllable = false,
          EmoteDuration = 5000,
          SyncOffsetFront = 1.13
       }
    }
 },
 Misc = {
    ["mindblown"] = {
       "anim@mp_player_intcelebrationmale@mind_blown",
       "mind_blown",
       "Mind Blown",
       AnimationOptions = {
          Controllable = true,
          EmoteDuration = 4000
       }
    },
    ["mindblown2"] = {
       "anim@mp_player_intcelebrationfemale@mind_blown",
       "mind_blown",
       "Mind Blown 2",
       AnimationOptions = {
          Controllable = true,
          EmoteDuration = 4000
       }
    },
    ["boxing"] = {
       "anim@mp_player_intcelebrationmale@shadow_boxing",
       "shadow_boxing",
       "Boxing",
       AnimationOptions = {
          Controllable = true,
          EmoteDuration = 4000
       }
    },
    ["boxing2"] = {
       "anim@mp_player_intcelebrationfemale@shadow_boxing",
       "shadow_boxing",
       "Boxing 2",
       AnimationOptions = {
          Controllable = true,
          EmoteDuration = 4000
       }
    },
    ["stink"] = {
       "anim@mp_player_intcelebrationfemale@stinker",
       "stinker",
       "Stink",
       AnimationOptions = {
          Controllable = true,
          Loop = true
       }
    },
    ["think4"] = {
       "anim@amb@casino@hangout@ped_male@stand@02b@idles",
       "idle_a",
       "Think 4",
       AnimationOptions = {
          Loop = true,
          Controllable = true
       }
    },
    ["adjusttie"] = {
       "clothingtie",
       "try_tie_positive_a",
       "Adjust Tie",
       AnimationOptions = {
          Controllable = true,
          EmoteDuration = 5000
       }
    }
 },
 Props = {
    ["notepad"] = {
       "missheistdockssetup1clipboard@base",
       "base",
       "Notepad",
       AnimationOptions = {
          Props = {
             {
                Prop = "prop_notepad_01",
                Bone = 18905,
                Placement = {0.1, 0.02, 0.05, 10.0, 0.0, 0.0}
             },
             {
                Prop = "prop_pencil_01",
                Bone = 58866,
                Placement = {0.11, -0.02, 0.001, -120.0, 0.0, 0.0}
             }
          },
          Loop = true,
          Controllable = true
       }
    },
    ["box"] = {
       "anim@heists@box_carry@",
       "idle",
       "Box",
       AnimationOptions = {
          Props = {
             {
                Prop = "hei_prop_heist_box",
                Bone = 60309,
                Placement = {0.025, 0.08, 0.255, -145.0, 290.0, 0.0}
             }
          },
          Loop = true,
          Controllable = true
       }
    },
    ["guitar"] = {
       "amb@world_human_musician@guitar@male@idle_a",
       "idle_b",
       "Guitar",
       AnimationOptions = {
          Props = {
             {
                Prop = "prop_acc_guitar_01",
                Bone = 24818,
                Placement = {-0.1, 0.31, 0.1, 0.0, 20.0, 150.0}
             }
          },
          Controllable = true,
          Loop = true
       }
    }
 },
 Dances = {
    ["dancef"] = {
       "anim@amb@nightclub@dancers@solomun_entourage@",
       "mi_dance_facedj_17_v1_female^1",
       "Dance F",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancef2"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
       "high_center",
       "Dance F2",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancef3"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
       "high_center_up",
       "Dance F3",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancef4"] = {
       "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity",
       "hi_dance_facedj_09_v2_female^1",
       "Dance F4",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancef5"] = {
       "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity",
       "hi_dance_facedj_09_v2_female^3",
       "Dance F5",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancef6"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
       "high_center_up",
       "Dance F6",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceslow2"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
       "low_center",
       "Dance Slow 2",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceslow3"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
       "low_center_down",
       "Dance Slow 3",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceslow4"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
       "low_center",
       "Dance Slow 4",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance"] = {
       "anim@amb@nightclub@dancers@podium_dancers@",
       "hi_dance_facedj_17_v2_male^5",
       "Dance",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance2"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
       "high_center_down",
       "Dance 2",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance3"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@",
       "high_center",
       "Dance 3",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance4"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
       "high_center_up",
       "Dance 4",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceupper"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
       "high_center",
       "Dance Upper",
       AnimationOptions = {
          Loop = true,
          Controllable = true
       }
    },
    ["danceupper2"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
       "high_center_up",
       "Dance Upper 2",
       AnimationOptions = {
          Loop = true,
          Controllable = true
       }
    },
    ["danceshy"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@",
       "low_center",
       "Dance Shy",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceshy2"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
       "low_center_down",
       "Dance Shy 2",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceslow"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
       "low_center",
       "Dance Slow",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly9"] = {
       "rcmnigel1bnmt_1b",
       "dance_loop_tyler",
       "Dance Silly 9",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance6"] = {
       "misschinese2_crystalmazemcs1_cs",
       "dance_loop_tao",
       "Dance 6",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance7"] = {
       "misschinese2_crystalmazemcs1_ig",
       "dance_loop_tao",
       "Dance 7",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance8"] = {
       "missfbi3_sniping",
       "dance_m_default",
       "Dance 8",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly"] = {
       "special_ped@mountain_dancer@monologue_3@monologue_3a",
       "mnt_dnc_buttwag",
       "Dance Silly",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly2"] = {
       "move_clown@p_m_zero_idles@",
       "fidget_short_dance",
       "Dance Silly 2",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly3"] = {
       "move_clown@p_m_two_idles@",
       "fidget_short_dance",
       "Dance Silly 3",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly4"] = {
       "anim@amb@nightclub@lazlow@hi_podium@",
       "danceidle_hi_11_buttwiggle_b_laz",
       "Dance Silly 4",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly5"] = {
       "timetable@tracy@ig_5@idle_a",
       "idle_a",
       "Dance Silly 5",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly6"] = {
       "timetable@tracy@ig_8@idle_b",
       "idle_d",
       "Dance Silly 6",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance9"] = {
       "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
       "med_center_up",
       "Dance 9",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly8"] = {
       "anim@mp_player_intcelebrationfemale@the_woogie",
       "the_woogie",
       "Dance Silly 8",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dancesilly7"] = {
       "anim@amb@casino@mini@dance@dance_solo@female@var_b@",
       "high_center",
       "Dance Silly 7",
       AnimationOptions = {
          Loop = true
       }
    },
    ["dance5"] = {
       "anim@amb@casino@mini@dance@dance_solo@female@var_a@",
       "med_center",
       "Dance 5",
       AnimationOptions = {
          Loop = true
       }
    },
    ["danceglowstick"] = {
       "anim@amb@nightclub@lazlow@hi_railing@",
       "ambclub_13_mi_hi_sexualgriding_laz",
       "Dance Glowsticks",
       AnimationOptions = {
          Props = {
             {
                Prop = "ba_prop_battle_glowstick_01",
                Bone = 28422,
                Placement = {0.0700, 0.1400, 0.0, -80.0, 20.0}
             },
             {
                Prop = "ba_prop_battle_glowstick_01",
                Bone = 60309,
                Placement = {0.0700, 0.0900, 0.0, -120.0, -20.0}
             }
          },
          Loop = true,
          Controllable = true
       }
    },
    ["danceglowstick2"] = {
       "anim@amb@nightclub@lazlow@hi_railing@",
       "ambclub_12_mi_hi_bootyshake_laz",
       "Dance Glowsticks 2",
       AnimationOptions = {
          Props = {
             {
                Prop = "ba_prop_battle_glowstick_01",
                Bone = 28422,
                Placement = {0.0700, 0.1400, 0.0, -80.0, 20.0}
             },
             {
                Prop = "ba_prop_battle_glowstick_01",
                Bone = 60309,
                Placement = {0.0700, 0.0900, 0.0, -120.0, -20.0}
             }
          },
          Loop = true
       }
    },
    ["danceglowstick3"] = {
       "anim@amb@nightclub@lazlow@hi_railing@",
       "ambclub_09_mi_hi_bellydancer_laz",
       "Dance Glowsticks 3",
       AnimationOptions = {
          Props = {
             {
                Prop = "ba_prop_battle_glowstick_01",
                Bone = 28422,
                Placement = {0.0700, 0.1400, 0.0, -80.0, 20.0}
             },
             {
                Prop = "ba_prop_battle_glowstick_01",
                Bone = 60309,
                Placement = {0.0700, 0.0900, 0.0, -120.0, -20.0}
             },
             Loop = true
          }
       },
       ["dancehorse"] = {
          "anim@amb@nightclub@lazlow@hi_dancefloor@",
          "dancecrowd_li_15_handup_laz",
          "Dance Horse",
          AnimationOptions = {
             Props = {
                {
                   Prop = "ba_prop_battle_hobby_horse",
                   Bone = 28422,
                   Placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
                }
             },
             Loop = true,
             Controllable = true
          }
       },
       ["dancehorse2"] = {
          "anim@amb@nightclub@lazlow@hi_dancefloor@",
          "crowddance_hi_11_handup_laz",
          "Dance Horse 2",
          AnimationOptions = {
             Props = {
                {
                   Prop = "ba_prop_battle_hobby_horse",
                   Bone = 28422,
                   Placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
                }
             },
             Loop = true
          }
       },
       ["dancehorse3"] = {
          "anim@amb@nightclub@lazlow@hi_dancefloor@",
          "dancecrowd_li_11_hu_shimmy_laz",
          "Dance Horse 3",
          AnimationOptions = {
             Props = {
                {
                   Prop = "ba_prop_battle_hobby_horse",
                   Bone = 28422,
                   Placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
                }
             },
             Loop = true
          }
       }
    }
 }
 }
 
 SCENARIOS = {
 HUMAN = {
    {"WORLD_HUMAN_AA_COFFEE", "AA Coffee"},
    {"WORLD_HUMAN_AA_SMOKE", "AA Smoking"},
    {"WORLD_HUMAN_BINOCULARS", "Binoculars"},
    {"WORLD_HUMAN_BUM_FREEWAY", "Bum Freeway"},
    {"WORLD_HUMAN_BUM_SLUMPED", "Bum Slumped"},
    {"WORLD_HUMAN_BUM_STANDING", "Bum Standing"},
    {"WORLD_HUMAN_BUM_WASH", "Bum Wash"},
    {"WORLD_HUMAN_CAR_PARK_ATTENDANT", "Car Park Attendant"},
    {"WORLD_HUMAN_CHEERING", "Cheering"},
    {"WORLD_HUMAN_CLIPBOARD", "Clipboard"},
    {"WORLD_HUMAN_CONST_DRILL", "Drill"},
    {"WORLD_HUMAN_COP_IDLES", "Cop Idle"},
    {"WORLD_HUMAN_DRINKING", "Drinking"},
    {"WORLD_HUMAN_DRUG_DEALER", "Drug Dealer"},
    {"WORLD_HUMAN_DRUG_DEALER_HARD", "Drug Dealer Hard"},
    {"WORLD_HUMAN_MOBILE_FILM_SHOCKING", "Phone Filming"},
    {"WORLD_HUMAN_GARDENER_LEAF_BLOWER", "Leaf Blower"},
    {"WORLD_HUMAN_GARDENER_PLANT", "Gardener"},
    {"WORLD_HUMAN_GOLF_PLAYER", "Golfing"},
    {"WORLD_HUMAN_GUARD_PATROL", "Guard Patrol"},
    {"WORLD_HUMAN_GUARD_STAND", "Guard Stand"},
    {"WORLD_HUMAN_GUARD_STAND_ARMY", "Guard Stand (Army)"},
    {"WORLD_HUMAN_HAMMERING", "Hammering"},
    {"WORLD_HUMAN_HANG_OUT_STREET", "Hanging Out"},
    {"WORLD_HUMAN_HIKER_STANDING", "Hiker Standing"},
    {"WORLD_HUMAN_HUMAN_STATUE", "Human Statue"},
    {"WORLD_HUMAN_JANITOR", "Janitor"},
    {"WORLD_HUMAN_JOG_STANDING", "Jog in place"},
    {"WORLD_HUMAN_LEANING", "Leaning"},
    {"WORLD_HUMAN_MAID_CLEAN", "Cleaning"},
    {"WORLD_HUMAN_MUSCLE_FLEX", "Muscle Flex"},
    {"WORLD_HUMAN_MUSCLE_FREE_WEIGHTS", "Weights"},
    {"WORLD_HUMAN_MUSICIAN", "Musician"},
    {"WORLD_HUMAN_PAPARAZZI", "Paparazzi"},
    {"WORLD_HUMAN_PARTYING", "Partying"},
    {"WORLD_HUMAN_PICNIC", "Picnic"},
    {"WORLD_HUMAN_PROSTITUTE_HIGH_CLASS", "Prositute (High Class)"},
    {"WORLD_HUMAN_PROSTITUTE_LOW_CLASS", "Prostitute (Low Class)"},
    {"WORLD_HUMAN_PUSH_UPS", "Push Ups"},
    {"WORLD_HUMAN_SEAT_LEDGE", "Ledge Sit"},
    {"WORLD_HUMAN_SEAT_LEDGE_EATING", "Ledge Eating"},
    {"WORLD_HUMAN_SEAT_STEPS", "Sit on Steps"},
    {"WORLD_HUMAN_SEAT_WALL", "Sit on Wall"},
    {"WORLD_HUMAN_SEAT_WALL_EATING", "Eat on Wall"},
    {"WORLD_HUMAN_SEAT_WALL_TABLET", "Tablet on Wall"},
    {"WORLD_HUMAN_SECURITY_SHINE_TORCH", "Shine Torch"},
    {"WORLD_HUMAN_SIT_UPS", "Situps"},
    {"WORLD_HUMAN_SMOKING", "Smoking"},
    {"WORLD_HUMAN_SMOKING_POT", "Smoking Pot"},
    {"WORLD_HUMAN_STAND_FIRE", "Campfire"},
    {"WORLD_HUMAN_STAND_FISHING", "Fishing"},
    {"WORLD_HUMAN_STAND_IMPATIENT", "Impatient"},
    {"WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT", "Impatient Upright"},
    {"WORLD_HUMAN_STAND_MOBILE", "Phone"},
    {"WORLD_HUMAN_STAND_MOBILE_UPRIGHT", "Phone Upright"},
    {"WORLD_HUMAN_STRIP_WATCH_STAND", "Watch Stand"},
    {"WORLD_HUMAN_STUPOR", "Stupor"},
    {"WORLD_HUMAN_SUNBATHE", "Sunbathe"},
    {"WORLD_HUMAN_SUNBATHE_BACK", "Sunbathe Back"},
    {"WORLD_HUMAN_SUPERHERO", "Superhero"},
    {"WORLD_HUMAN_SWIMMING", "Swimming"},
    {"WORLD_HUMAN_TENNIS_PLAYER", "Tennis Player"},
    {"WORLD_HUMAN_TOURIST_MAP", "Tourist Map"},
    {"WORLD_HUMAN_TOURIST_MOBILE", "Tourist Phone"},
    {"WORLD_HUMAN_VEHICLE_MECHANIC", "Mechanic"},
    {"WORLD_HUMAN_WELDING", "Welding"},
    {"WORLD_HUMAN_WINDOW_SHOP_BROWSE", "Window Browsing"},
    {"WORLD_HUMAN_YOGA", "Yoga"}
 },
 HUMAN2 = {
    {"PROP_HUMAN_ATM", "ATM"},
    {"PROP_HUMAN_BBQ", "BBQ"},
    {"PROP_HUMAN_BUM_BIN", "Bum Bin"},
    {"PROP_HUMAN_BUM_SHOPPING_CART", "BUM Shopping Cart"},
    {"PROP_HUMAN_MUSCLE_CHIN_UPS", "Muscle Chinups"},
    {"PROP_HUMAN_MUSCLE_CHIN_UPS_ARMY", "Muscle Chinups (Army)"},
    {"PROP_HUMAN_MUSCLE_CHIN_UPS_PRISON", "Muscle Chinups (Prison)"},
    {"PROP_HUMAN_PARKING_METER", "Parking Meter"},
    {"PROP_HUMAN_SEAT_ARMCHAIR", "Sit (Armchair)"},
    {"PROP_HUMAN_SEAT_BAR", "Sit (Bar)"},
    {"PROP_HUMAN_SEAT_BENCH", "Sit (Bench)"},
    {"PROP_HUMAN_SEAT_BENCH_DRINK", "Sit & Drink (Bench)"},
    {"PROP_HUMAN_SEAT_BENCH_DRINK_BEER", "Sit & Drink Beer (Bench)"},
    {"PROP_HUMAN_SEAT_BENCH_FOOD", "Sit & Eat (Bench)"},
    {"PROP_HUMAN_SEAT_BUS_STOP_WAIT", "Bus Stop Wait"},
    {"PROP_HUMAN_SEAT_CHAIR", "Sit (Chair)"},
    {"PROP_HUMAN_SEAT_CHAIR_DRINK", "Sit & Drink (Chair)"},
    {"PROP_HUMAN_SEAT_CHAIR_DRINK_BEER", "Sit & Drink Beer (Chair)"},
    {"PROP_HUMAN_SEAT_CHAIR_FOOD", "Sit & Eat (Chair)"},
    {"PROP_HUMAN_SEAT_CHAIR_UPRIGHT", "Sit Upright (Chair)"},
    {"PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", "Sit MP Player"},
    {"PROP_HUMAN_SEAT_COMPUTER", "Sit (Computer)"},
    {"PROP_HUMAN_SEAT_DECKCHAIR", "Sit (Deckchair)"},
    {"PROP_HUMAN_SEAT_DECKCHAIR_DRINK", "Sit & Drink (Deckchair)"},
    {"PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS", "Bench Press"},
    {"PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS_PRISON", "Bench Press (Prison)"},
    {"PROP_HUMAN_SEAT_SEWING", "Sit (Sewing)"},
    {"PROP_HUMAN_SEAT_STRIP_WATCH", "Sit (Stripclub)"},
    {"PROP_HUMAN_SEAT_SUNLOUNGER", "Sit (Sunlounger)"},
    {"PROP_HUMAN_STAND_IMPATIENT", "Impatient"},
    {"CODE_HUMAN_COWER", "Cower"},
    {"CODE_HUMAN_CROSS_ROAD_WAIT", "Cross road wait"},
    {"CODE_HUMAN_PARK_CAR", "Park Car"},
    {"PROP_HUMAN_MOVIE_BULB", "Movie Bulb"},
    {"PROP_HUMAN_MOVIE_STUDIO_LIGHT", "Movie Studio Light"},
    {"CODE_HUMAN_MEDIC_KNEEL", "Medic Kneel"},
    {"CODE_HUMAN_MEDIC_TEND_TO_DEAD", "Medic Tend"},
    {"CODE_HUMAN_MEDIC_TIME_OF_DEATH", "Medic Time of Death"},
    {"CODE_HUMAN_POLICE_CROWD_CONTROL", "Police Crowd Control"},
    {"CODE_HUMAN_POLICE_INVESTIGATE", "Police Investigate"},
    {"CODE_HUMAN_STAND_COWER", "Cower (Standing)"},
    {"EAR_TO_TEXT", "Ear to Text"},
    {"EAR_TO_TEXT_FAT", "Ear to Text (Fat)"}
 },
 ANIMALS = {
    {"WORLD_BOAR_GRAZING", "Boar Grazing"},
    {"WORLD_CAT_SLEEPING_GROUND", "Cat Sleeping (Ground)"},
    {"WORLD_CAT_SLEEPING_LEDGE", "Cat Sleeping (Ledge)"},
    {"WORLD_COW_GRAZING", "Cow Grazing"},
    {"WORLD_COYOTE_HOWL", "Coyote Howl"},
    {"WORLD_COYOTE_REST", "Coyote Rest"},
    {"WORLD_COYOTE_WANDER", "Coyte Wander"},
    {"WORLD_CHICKENHAWK_FEEDING", "Chicken Hawk Feeding"},
    {"WORLD_CHICKENHAWK_STANDING", "Chicken Hawk Standing"},
    {"WORLD_CORMORANT_STANDING", "Cormorant Standing"},
    {"WORLD_CROW_FEEDING", "Crow Feeding"},
    {"WORLD_CROW_STANDING", "Crow Standing"},
    {"WORLD_DEER_GRAZING", "Deer Grazing"},
    {"WORLD_DOG_BARKING_ROTTWEILER", "Dog Barking (Rottweiler)"},
    {"WORLD_DOG_BARKING_RETRIEVER", "Dog Barking (Retriever)"},
    {"WORLD_DOG_BARKING_SHEPHERD", "Dog Barking (Shepherd)"},
    {"WORLD_DOG_SITTING_ROTTWEILER", "Dog Sitting (Rottweiler)"},
    {"WORLD_DOG_SITTING_RETRIEVER", "Dog Sitting (Retriever)"},
    {"WORLD_DOG_SITTING_SHEPHERD", "Dog Sitting (Shepherd)"},
    {"WORLD_DOG_BARKING_SMALL", "Dog Barking (Small)"},
    {"WORLD_DOG_SITTING_SMALL", "Dog Sitting (Small)"},
    {"WORLD_FISH_IDLE", "Fish Idle"},
    {"WORLD_GULL_FEEDING", "Gull Feeding"},
    {"WORLD_GULL_STANDING", "Gull Standing"},
    {"WORLD_HEN_PECKING", "Hen Pecking"},
    {"WORLD_HEN_STANDING", "Hen Standing"},
    {"WORLD_MOUNTAIN_LION_REST", "Mountain Lion Rest"},
    {"WORLD_MOUNTAIN_LION_WANDER", "Mountain Lion Wander"},
    {"WORLD_PIG_GRAZING", "Pig Grazing"},
    {"WORLD_PIGEON_FEEDING", "Pigeon Feeding"},
    {"WORLD_PIGEON_STANDING", "Pigeon Standing"},
    {"WORLD_RABBIT_EATING", "Rabbit Eating"},
    {"WORLD_RATS_EATING", "Rats Eating"},
    {"WORLD_SHARK_SWIM", "Shark Swimming"},
    {"PROP_BIRD_IN_TREE", "Bird in Tree"},
    {"PROP_BIRD_TELEGRAPH_POLE", "Bird on pole"}
 }
 }
 
 SPEECH_PARAMS = {
 {"Normal", "Speech_Params_Force"},
 {"In Your Head", "Speech_Params_Force_Frontend", "Plays the voice as if nearby npcs are inside you"},
 {"Beat", "SPEECH_PARAMS_BEAT"},
 {"Megaphone", "Speech_Params_Force_Megaphone"},
 {"Helicopter", "Speech_Params_Force_Heli"},
 {"Shouted", "Speech_Params_Force_Shouted"},
 {"Shouted (Critical)", "Speech_Params_Force_Shouted_Critical"}
 }
 SPEECHES = {
 {"Greeting", "GENERIC_HI"},
 {"Farewell", "GENERIC_BYE"},
 {"Bumped Into", "BUMP"},
 {"Chat", "CHAT_RESP"},
 {"Death Moan", "DYING_MOAN"},
 {"Apology", "APOLOGY_NO_TROUBLE"},
 {"Thanks", "GENERIC_THANKS"},
 {"Fuck You", "GENERIC_FUCK_YOU"},
 {"War Cry", "GENERIC_WAR_CRY"},
 {"Fallback", "FALL_BACK"},
 {"Cover Me", "COVER_ME"},
 {"Swear", "GENERIC_CURSE_HIGH"},
 {"Insult", "GENERIC_INSULT_HIGH"},
 {"Shocked", "GENERIC_SHOCKED_HIGH"},
 {"Frightened", "GENERIC_FRIGHTENED_HIGH"},
 {"Kiflom", "KIFFLOM_GREET", "Works best with epsilon voice models"}
 }
 VOICE_MODELS = {
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