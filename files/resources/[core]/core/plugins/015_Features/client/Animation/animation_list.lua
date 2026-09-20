-- ALL custon animations added to this repository were added with express permission from the creators and does not contain any paid content --
-- If an emote does not work, you may be on an older gamebuild. --
-- To get a higher gamebuild, see ReadMe on github repository --
RP = {}

-- EXPRESSIONS --

RP.Expressions = {
                   label = "Expressions",
                   icon = "🎭",
                   type = "expresion",
                   ["Aiming"] = {
                       "mood_aiming_1",
                       "Viser"
                   },
                   ["Angry"] = {
                       "mood_angry_1",
                       "En colère"
                   },
                   ["Crying"] = {
                       "console_wasnt_fun_end_loop_floyd_facial",
                       "Pleurer"
                   },
                   ["Drunk"] = {
                       "mood_drunk_1",
                       "Bourré"
                   },
                   ["Dumb"] = {
                       "pose_injured_1",
                       "Idiot"
                   },
                   ["Excited"] = {
                       "mood_excited_1",
                       "Excité"
                   },
                   ["Frustrated"] = {
                       "mood_frustrated_1",
                       "Frustré"
                   },
                   ["Grumpy"] = {
                       "effort_1",
                       "Grincheux"
                   },
                   ["Grumpy2"] = {
                       "mood_drivefast_1",
                       "Grincheux 2"
                   },
                   ["Grumpy3"] = {
                       "pose_angry_1",
                       "Grincheux 3"
                   },
                   ["Happy"] = {
                       "mood_happy_1",
                       "Heureux"
                   },
                   ["Injured"] = {
                       "mood_injured_1",
                       "Blessé"
                   },
                   ["Mouthbreather"] = {
                       "smoking_hold_1",
                       "Respiration Buccale"
                   },
                   ["Mouthbreather2"] = {
                       "smoking_inhale_1",
                       "Respiration Buccale 2"
                   },
                   ["Neverblink"] = {
                       "pose_normal_1",
                       "Ne Jamais Cligner"
                   },
                   ["Oneeye"] = {
                       "pose_aiming_1",
                       "Un Œil"
                   },
                   ["Shocked"] = {
                       "shocked_1",
                       "Choqué"
                   },
                   ["Shocked2"] = {
                       "shocked_2",
                       "Choqué 2"
                   },
                   ["Sleeping"] = {
                       "mood_sleeping_1",
                       "Dormir"
                   },
                   ["Sleeping2"] = {
                       "dead_1",
                       "Dormir 2"
                   },
                   ["Smug"] = {
                       "mood_smug_1",
                       "Suffisant"
                   },
                   ["Speculative"] = {
                       "mood_aiming_1",
                       "Spéculatif"
                   },
                   ["Stressed"] = {
                       "mood_stressed_1",
                       "Stressé"
                   },
                   ["Sulking"] = {
                       "mood_sulk_1",
                       "Bouder"
                   },
                   ["Weird"] = {
                       "effort_2",
                       "Bizarre"
                   },
                   ["Weird2"] = {
                       "effort_3",
                       "Bizarre 2"
                   },
                   ["Scared"] = {
                       "random@domestic",
                       "f_distressed_loop",
                       "Avoir peur"
                   },
                   ["Scared2"] = {
                       "random@homelandsecurity",
                       "knees_loop_girl",
                       "Avoir peur 2"
                   },
                   ["Think"] = {
                       "misscarsteal4@aliens",
                       "rehearsal_base_idle_director",
                       "Penser"
                   },
                   ["Think2"] = {
                       "missheist_jewelleadinout",
                       "jh_int_outro_loop_a",
                       "Penser 2"
                   },
                   ["Nervous"] = {
                       "amb@world_human_bum_standing@twitchy@idle_a",
                       "idle_c",
                       "Nerveux"
                   },
                   ["Nervous2"] = {
                       "mp_missheist_countrybank@nervous",
                       "nervous_idle",
                       "Nerveux 2"
                   },
                   ["Joyful"] = {
                       "mood_dancing_low_1",
                       "Joyeux"
                   },
                   ["Joyful2"] = {
                       "mood_dancing_low_2",
                       "Joyeux 2"
                   },
                   ["Scheme"] = {
                       "mood_dancing_high_2",
                       "Complot"
                   },
                   ["Burning"] = {
                       "burning_1",
                       "Brûler"
                   },
                   ["Electrocuted"] = {
                       "electrocuted_1",
                       "Électrocuté"
                   },
                   ["Dead"] = {
                       "dead_1",
                       "Mort"
                   },
                   ["Sleeping3"] = {
                       "dead_2",
                       "Dormir 3"
                   },
                   ["Weird3"] = {
                       "melee_effort_1",
                       "Bizarre 3"
                   },
}

--- WALKSTYLES ---

RP.Walks = {
    label = "Marches",
    -- The key shouldn't have any other uppercase letter than the first one!
    -- The first letter HAS to be uppercase!
    -- First element of array is the walk animation
    -- Second element is the label, this is optional
    icon = "🚶",
    type = "walk",
    ["Alien"] = {"move_m@alien", "Alien"},
    ["Armored"] = {"anim_group_move_ballistic", "Blindé"},
    ["Arrogant"] = {"move_f@arrogant@a", "Arrogant"},
    --["Bigfoot"] = {"move_characters@orleans@core@"},
    ["Butch"] = {"move_m@hurry_butch@a", "Pressé"},
    ["Butch2"] = {"move_m@hurry_butch@b", "Pressé 2"},
    ["Butch3"] = {"move_m@hurry_butch@c", "Pressé 3"},
    ["Buzzed"] = {"move_m@buzzed", "Clochard"},
    ["Brave"] = {"move_m@brave", "Brave 1"},
    ["Brave2"] = {"move_m@brave@a", "Brave 2"},
    ["Casey"] = {"move_casey", "Casey"},
    ["Casual"] = {"move_m@casual@a", "Casual 1"},
    ["Casual2"] = {"move_m@casual@b", "Casual 2"},
    ["Casual3"] = {"move_m@casual@c", "Casual 3"},
    ["Casual4"] = {"move_m@casual@d", "Casual 4"},
    ["Casual5"] = {"move_m@casual@e", "Casual 5"},
    ["Casual6"] = {"move_m@casual@f", "Casual 6"},
    ["Chichi"] = {"move_f@chichi", "Chichi"},
    ["Confident"] = {"move_m@confident", "Confiant"},
    ["Cop"] = {"move_m@business@a", "Policier 1"},
    ["Cop2"] = {"move_m@business@b", "Policier 2"},
    ["Cop3"] = {"move_m@business@c", "Policier 3"},
    ["Coward"] = {"move_m@coward", "Lâche"},
    ["Chubbymale"] = {"move_chubby", "Homme enrobé"},
    ["Chubbyfemale"] = {"move_f@chubby@a", "Femme enrobé"},
    ["Dave"] = {"move_characters@dave_n", "Dave"},
    ["Defaultfemale"] = {"move_f@multiplayer", "Basique (Femme)"},
    ["Defaultmale"] = {"move_m@multiplayer", "Basique (Homme)"},
    ["Depressed"] = {"move_m@depressed@a", "Déprimé 1"},
    ["Depressed2"] = {"move_m@depressed@b", "Déprimé 2"},
    ["Depressed3"] = {"move_f@depressed@a", "Déprimé 3"},
    ["Depressed4"] = {"move_f@depressed@c", "Déprimé 4"},
    ["Dreyfuss"] = {"move_dreyfuss", "Dreyfuss"},
    ["Drunk"] = {"move_m@drunk@a", "Bourré 1"},
    ["Drunk2"] = {"move_m@buzzed", "Bourré 2"},
    ["Drunk3"] = {"move_m@drunk@moderatedrunk", "Bourré 3 - Modéré"},
    ["Drunk4"] = {"move_m@drunk@moderatedrunk_head_up", "Bourré 4 - Modéré 2"},
    ["Drunk5"] = {"move_m@drunk@slightlydrunk", "Bourré 5 - Léger"},
    ["Drunk6"] = {"move_m@drunk@verydrunk", "Bourré 6 - Epave"},
    ["Fat"] = {"move_m@fat@a", "Homme gros"},
    ["Fat2"] = {"move_f@fat@a", "Femme grosse"},
    ["Fat3"] = {"move_m@fat@bulky", "Gros & Volumineux"},
    ["Fat4"] = {"move_f@fat@a_no_add", "Femme grosse 2"},
    ["Femme"] = {"move_f@femme@", "Féminin"},
    ["Femme2"] = {"move_m@femme@", "Femme 2"},
    ["Franklin2"] = {"move_characters@franklin@fire", "Franklin 2"},
    ["Mickael2"] = {"move_characters@michael@fire", "Mickael 2"},
    ["Trevor2"] = {"move_m@fire", "Trevor"},
    ["Floyd"] = {"move_characters@floyd", "Floyd"},
    ["Franklin"] = {"move_p_m_one", "Franklin"},
    ["Gangster"] = {"move_m@gangster@generic", "Gangster 1"},
    ["Gangsterb"] = {"move_gangster", "Gangster 2"},
    ["Gangsterc"] = {"move_m@gangster@ng", "Gangster 3"},
    --["Gangsterd"] = {"move_m@gangster@var_a", "Gangster 4"},
    ["Gangstere"] = {"move_m@gangster@var_b", "Gangster 4"},
    ["Gangsterf"] = {"move_m@gangster@var_c", "Gangster 5"},
    ["Gangsterg"] = {"move_m@gangster@var_d", "Gangster 6"},
    ["Gangsterh"] = {"move_m@gangster@var_e", "Gangster 7"},
    ["Gangsteri"] = {"move_m@gangster@var_f", "Gangster 8"},
    ["Gangsterj"] = {"move_m@gangster@var_g", "Gangster 9"},
    ["Gangsterk"] = {"move_m@gangster@var_h", "Gangster 10"},
    ["Gangsterl"] = {"move_m@gangster@var_i", "Gangster 11"},
    ["Gangsterm"] = {"move_m@gangster@var_j", "Gangster 12"},
    ["Gangstern"] = {"move_m@gangster@var_k", "Gangster 13"},
    ["Genenric"] = {"move_m@generic", "Générique (homme)"},
    ["Genenric2"] = {"move_f@generic", "Générique (femme)"},
    ["Guard"] = {"move_m@prison_gaurd", "Garde de Prison"},
    ["Handcuffs"] = {"move_m@prisoner_cuffed", "Menotté"},
    ["Heels"] = {"move_f@heels@c", "Talons 1"},
    ["Heels2"] = {"move_f@heels@d", "Talons 2"},
    ["Hiking"] = {"move_m@hiking", "Randonné 1"},
    ["Hiking2"] = {"move_f@hiking", "Randonné 2"},
    ["Hipster"] = {"move_m@hipster@a", "Hipster"},
    ["Hobo"] = {"move_m@hobo@a", "Clochard 2"},
    ["Hobo2"] = {"move_m@hobo@b", "Clochard 3"},
    ["Hurry"] = {"move_m@hurry@a", "Pressé (homme)"},
    ["Hurry2"] = {"move_f@hurry@a", "Pressé F1"},
    ["Hurry3"] = {"move_f@hurry@b", "Pressé F2"},
    ["Injured2"] = {"move_f@injured", "Blessé 2 - Femme"},
    ["Intimidation"] = {"move_m@intimidation@1h", "Intimidé 1"},
    ["Intimidation2"] = {"move_m@intimidation@cop@unarmed", "Intimidé 2"},
    ["Intimidation3"] = {"move_m@intimidation@unarmed", "Intimidé 3"},
    ["Janitor"] = {"move_p_m_zero_janitor", "Concierge 1"},
    ["Janitor2"] = {"move_p_m_zero_slow", "Concierge 2"},
    ["Jimmy"] = {"move_characters@jimmy", "Jimmy"},
    ["Nervous"] = {"move_characters@jimmy@nervous@", "Nerveux"},
    ["Lamar"] = {"move_characters@lamar", "Lamar"},
    ["Lamar2"] = {"anim_group_move_lemar_alley", "Lamar 2"},
    ["Lester"] = {"move_heist_lester", "Lester"},
    ["Lester2"] = {"move_lester_caneup", "Lester 2"},
    ["Maneater"] = {"move_f@maneater", "Mangeur d'hommes"},
    ["Michael"] = {"move_ped_bucket", "Michael"},
    ["Money"] = {"move_m@money", "Riche"},
    ["Muscle"] = {"move_m@muscle@a", "Musclé"},
    ["Patricia"] = {"move_characters@patricia", "Patricia"},
    ["Paramedic"] = {"move_paramedic", "Medecin"},
    ["Posh"] = {"move_m@posh@", "Hautain 1"},
    ["Posh2"] = {"move_f@posh@", "Hautain 2"},
    ["Quick"] = {"move_m@quick", "Coincé"},
    ["Ron"] = {"move_characters@ron", "Ron"},
    ["Sad"] = {"move_m@sad@a", "Triste 1 - Homme"},
    ["Sad2"] = {"move_m@sad@b", "Triste 2 - Homme"},
    ["Sad3"] = {"move_m@sad@c", "Triste 3 - Homme"},
    ["Sad4"] = {"move_f@sad@a", "Triste 1 - Femme"},
    ["Sad5"] = {"move_f@sad@b", "Triste 2 - Femme"},
    ["Sassy"] = {"move_m@sassy", "Efféminé - Homme"},
    ["Sassy2"] = {"move_f@sassy", "Efféminé - Femme"},
    ["Scared"] = {"move_f@scared", "Appeuré"},
    ["Sexy"] = {"move_f@sexy@a", "Sexy"},
    ["Shady"] = {"move_m@shadyped@a", "Louche"},
    ["Slow"] = {"move_characters@jimmy@slow@", "Jimmy 2"},
    ["Stripper"] = {"move_f@stripper@a", "Stripteaseuse"},
    ["Swagger"] = {"move_m@swagger", "Swag 1"},
    ["Swagger2"] = {"move_m@swagger@b", "Swag 2"},
    ["Tough"] = {"move_m@tough_guy@", "Brute 1"},
    ["Tough2"] = {"move_f@tough_guy@", "Brute 2"},
    ["Toolbelt"] = {"move_m@tool_belt@a", "Ceinture Outil - Homme"},
    ["Toolbelt2"] = {"move_f@tool_belt@a", "Ceinture Outil - Femme"},
    ["Tracey"] = {"move_characters@tracey", "Tracey"},
    ["Trevor"] = {"move_p_m_two", "Trevor"},
    ["Veryslow"] = {"move_m@leaf_blower", "Très Lent"},
    ["Wide"] = {"move_m@bag", "Large"},
    ["Grooving"] = {"anim@move_m@grooving@", "Grooving H1"},
    ["Grooving2"] = {"anim@move_f@grooving@", "Grooving F1"},
    ["Flee"] = {"move_f@flee@a", "Fuir 1 (femme)"},
    ["Flee2"] = {"move_f@flee@c", "Fuir 2 (femme)"},
    ["Flee3"] = {"move_m@flee@a", "Fuir 1 (homme)"},
    ["Flee4"] = {"move_m@flee@b", "Fuir 2 (homme)"},
    ["Flee5"] = {"move_m@flee@c", "Fuir 3 (homme)"},
    ["Trash"] = {"clipset@move@trash_fast_turn", "Poubelle"},
    ["Trash2"] = {"missfbi4prepp1_garbageman", "Poubelle 2"},
    ["Jog"] = {"move_m@jog@", "Jogging"},
    ["Runner"] = {"female_fast_runner", "Coureuse"},
}

--- SHARED EMOTES ---

RP.Shared = {

    --[emotename] = {dictionary, animation, displayname, targetemotename, additionalanimationoptions} --
    -- You don't have to specify targetemotename; If you don't, it will just play the same animation on both.--
    -- targetemote is used for animations that have a corresponding animation to the other player, ie Carry and Be Carried --
    -- Emotes will work with either SyncOffset or Attachto. We can attach players either in front of us, to a specific bone, or either side of us. --
    label = "Partagé",
    icon = "🤝",
    ["handshake"] = {
        "mp_ped_interaction",
        "handshake_guy_a",
        "Poignée de main",
        "handshake2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3000,
            SyncOffsetFront = 0.9
        }
    },
    ["handshake2"] = {
        "mp_ped_interaction",
        "handshake_guy_b",
        "Poignée de main 2",
        "handshake",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3000
        }
    },
    ["hug"] = {
        "mp_ped_interaction",
        "kisses_guy_a",
        "Câlin",
        "hug2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 5000,
            SyncOffsetFront = 1.05
        }
    },
    ["hug2"] = {
        "mp_ped_interaction",
        "kisses_guy_b",
        "Câlin 2",
        "hug",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 5000,
            SyncOffsetFront = 1.18
        }
    },
    ["hugr"] = {
        "misscarsteal2chad_goodbye",
        "chad_armsaround_chad",
        "Câlin Romantique 1",
        "hugr2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetSide = -0.05,
            SyncOffsetFront = 0.52
        }
    },
    ["hugr2"] = {
        "misscarsteal2chad_goodbye",
        "chad_armsaround_girl",
        "Câlin Romantique 2",
        "hugr",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetSide = -0.05,
            SyncOffsetFront = 0.52
        }
    },
    ["bro"] = {
        "mp_ped_interaction",
        "hugs_guy_a",
        "Salut Poto",
        "bro2",
        AnimationOptions = {
            SyncOffsetFront = 1.14
        }
    },
    ["bro2"] = {
        "mp_ped_interaction",
        "hugs_guy_b",
        "Salut Poto 2",
        "bro",
        AnimationOptions = {
            SyncOffsetFront = 1.14
        }
    },
    ["give"] = {
        "mp_common",
        "givetake1_a",
        "Donne quelque chose",
        "give2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["give2"] = {
        "mp_common",
        "givetake1_b",
        "Donne quelque chose 2",
        "give",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["baseball"] = {
        "anim@arena@celeb@flat@paired@no_props@",
        "baseball_a_player_a",
        "Joue au baseball",
        "baseballthrow"
    },
    ["baseballthrow"] = {
        "anim@arena@celeb@flat@paired@no_props@",
        "baseball_a_player_b",
        "Lance une balle de baseball",
        "baseball"
    },
    ["stickup"] = {
        "random@countryside_gang_fight",
        "biker_02_stickup_loop",
        "Braquer",
        "stickupscared",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stickupscared"] = {
        "missminuteman_1ig_2",
        "handsup_base",
        "Se faire braquer",
        "stickup",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["punch"] = {
        "melee@unarmed@streamed_variations",
        "plyr_takedown_rear_lefthook",
        "Donne un coup de poing ",
        "punched"
    },
    ["punched"] = {
        "melee@unarmed@streamed_variations",
        "victim_takedown_front_cross_r",
        "Prendre un coup de poing",
        "punch"
    },
    ["headbutt"] = {
        "melee@unarmed@streamed_variations",
        "plyr_takedown_front_headbutt",
        "Coup de tête",
        "headbutted"
    },
    ["headbutted"] = {
        "melee@unarmed@streamed_variations",
        "victim_takedown_front_headbutt",
        "Se prendre coup de tête",
        "headbutt"
    },
    ["slap"] = {
        "melee@unarmed@streamed_variations",
        "plyr_takedown_front_slap",
        "Gifler",
        "slapped",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["slap2"] = {
        "melee@unarmed@streamed_variations",
        "plyr_takedown_front_backslap",
        "Gifler 2",
        "slapped2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["slapped"] = {
        "melee@unarmed@streamed_variations",
        "victim_takedown_front_slap",
        "Se faire gifler",
        "slap"
    },
    ["slapped2"] = {
        "melee@unarmed@streamed_variations",
        "victim_takedown_front_backslap",
        "Se faire gifler 2",
        "slap2"
    },
    ["carry"] = {
        "missfinale_c2mcs_1",
        "fin_c2_mcs_1_camman",
        "Porter",
        "carry2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["carry2"] = {
        "nm",
        "firemans_carry",
        "Se faire porter",
        "carry2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 40269,
            xPos = -0.14,
            yPos = 0.15,
            zPos = 0.14,
            xRot = 0.0,
            yRot = -59.0,
            zRot = -4.5
        }
    },
    ["carry3"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter 2",
        "carry4",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["carry4"] = {
        "amb@code_human_in_car_idles@generic@ps@base",
        "base",
        "Se faire porter 2",
        "carry3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 28252,
            xPos = 0.350,
            yPos = 0.15,
            zPos = -0.15,
            xRot = -42.50,
            yRot = -22.50,
            zRot = 22.50
        }
    },
    ["carrymecute"] = { -- Male Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_mal_002",
        "Porter mignon",
        "carrymecute2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["carrymecute2"] = { -- Female Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_fem_002",
        "Porter mignon 2",
        "carrymecute",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0000,
            yPos = 0.0000,
            zPos = 0.0000,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 0.0000
        }
    },
    ["carrycmg"] = { -- Male Custom emote by CMG Mods
        "couplepose1cmg@animation",
        "couplepose1cmg_clip",
        "Porter mignon 3",
        "carrycmg2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["carrycmg2"] = { -- Female Custom emote by CMG Mods
        "couplepose2cmg@animation",
        "couplepose2cmg_clip",
        "Porter mignon 4",
        "carrycmg",
        AnimationOptions = {
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0100,
            yPos = 0.3440,
            zPos = -0.0100,
            xRot = 180.0000,
            yRot = 180.0000,
            zRot = -1.9999
        }
    },
    ["bestfriends"] = { -- Female Custom emote by MrWitt
        "mrwitt@casual_composure_female01",
        "mrwitt",
        "Meilleur ami 1",
        "bestfriends2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["bestfriends2"] = { -- Female Custom emote by MrWitt
        "mrwitt@casual_composure_female02",
        "mrwitt",
        "Meilleur ami 2",
        "bestfriends",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.2500,
            yPos = 0.1400,
            zPos = 0.0200,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = -0.0000
        },
    },
    ["bff"] = {
        "anim@male_couple_03_b",
        "m_couple_03_b_clip",
        "Pose BFF",
        "bffb",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        },
    },
    ["bffb"] = {
        "anim@female_couple_03_b",
        "f_couple_03_b_clip",
        "Pose BFF 2",
        "bff",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0100,
            yPos = 0.1300,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 76.0000
        },
    },
    ["sitwithmepose"] = { -- Male Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_mal_003",
        "S'assoier avec moi",
        "sitwithmepose2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["sitwithmepose2"] = { -- Female Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_fem_003",
        "Assis toi avec moi?",
        "sitwithmepose",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.3540,
            yPos = 0.5110,
            zPos = 0.8310,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = -2.8000
        }
    },
    ["hugpose"] = { -- Male Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_mal_001",
        "Pose mignonne",
        "hugpose2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["hugpose2"] = { -- Female Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_fem_001",
        "Pose mignonne avec moi?",
        "hugpose",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.1400,
            yPos = 0.2500,
            zPos = 0.0000,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 0.0000
        }
    },
    ["hugtip"] = { -- Male Custom emote by Little Spoon
        "littlespoon@friendship007",
        "friendship007",
        "Pose pointe de pied",
        "hugtip2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["hugtip2"] = { -- Female Custom emote by Little Spoon
        "littlespoon@friendship008",
        "friendship008",
        "Pose pointe de pied 2",
        "hugtip",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0100,
            yPos = 0.2700,
            zPos = 0.0,
            xRot = -180.0000,
            yRot = -180.0000,
            zRot = 10.0000
        }
    },
    ["cutepicpose"] = { -- Male Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_mal_004",
        "Pose photo mignonne",
        "cutepicpose2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["cutepicpose2"] = { -- Female Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_fem_004",
        "Pose photo mignonne 2",
        "cutepicpose",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.2700,
            yPos = 0.1200,
            zPos = 0.0000,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 0.0000
        }
    },
    ["couplehhands"] = { -- Male Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_mal_005",
        "Couple coeur main",
        "couplehhands2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["couplehhands2"] = { -- Female Custom emote by Amnilka
        "amnilka@photopose@couple@couplefirst",
        "amnilka_couple_fem_005",
        "Couple coeur main 2",
        "couplehhands",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.1230,
            yPos = 0.4740,
            zPos = 0.0000,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 94.0000
        }
    },
    ["couplewed1a"] = { -- Male Custom emote by EnchantedBrwny
        "EnchantedBrwny@wedding1a",
        "wedding1a",
        "Pose mariage 1A",
        "couplewed1b",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["couplewed1b"] = { -- Female Custom emote by EnchantedBrwny
        "EnchantedBrwny@wedding1b",
        "wedding1b",
        "Pose mariage 1B",
        "couplewed1a",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0300,
            yPos = 1.0000,
            zPos = 0.0200,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 130.0000
        }
    },
    ["couplewed2a"] = { -- Male Custom emote by EnchantedBrwny
        "EnchantedBrwny@wedding2b",
        "wedding2b",
        "Pose mariage 2A",
        "couplewed2b",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["couplewed2b"] = { -- Female Custom emote by EnchantedBrwny
        "EnchantedBrwny@wedding2a",
        "wedding2a",
        "Pose mariage 2B",
        "couplewed2a",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0100,
            yPos = 0.2500,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = -88.9000
        }
    },
    ["liftme"] = { -- Male Custom emote by -Moses-
        "couplepose1pack1anim2@animation",
        "couplepose1pack1anim2_clip",
        "Soulève moi",
        "liftme2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["liftme2"] = { -- Female Custom emote by -Moses-
        "couplepose1pack1anim1@animation",
        "couplepose1pack1anim1_clip",
        "Soulève moi 2",
        "liftme",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0020,
            yPos = 0.2870,
            zPos = 0.2500,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 180.0000
        }
    },
    ["liftme3"] = { -- Male Custom emote by -Moses-
        "couplepose2pack1anim2@animation",
        "couplepose2pack1anim2_clip",
        "Soulève moi 3",
        "liftme4",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["liftme4"] = { -- Female Custom emote by -Moses-
        "couplepose2pack1anim1@animation",
        "couplepose2pack1anim1_clip",
        "Soulève moi 4",
        "liftme3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0100,
            yPos = 0.4800,
            zPos = 0.5300,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 180.0000
        }
    },
    ["liftme5"] = { -- Male Custom emote by -Moses-
        "couplepose3pack1anim2@animation",
        "couplepose3pack1anim2_clip",
        "Soulève moi 5",
        "liftme6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["liftme6"] = { -- Female Custom emote by -Moses-
        "couplepose3pack1anim1@animation",
        "couplepose3pack1anim1_clip",
        "Soulève moi 6",
        "liftme5",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.2120,
            yPos = -0.5400,
            zPos = -0.1000,
            xRot = 0.0000,
            yRot = 0.0000,
            zRot = 0.0000
        }
    },
    ["csdog"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Petit Chien",
        "csdog2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AnimalEmote = true
    },
    ["csdog2"] = { -- Emote by MissSnowie
        "misssnowie@little_doggy_lying_down",
        "base",
        "Petit Chien porté",
        "csdog",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = -0.040,
            yPos = 0.330,
            zPos = 0.280,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 80.0,
        },
        AnimalEmote = true
    },
    ["csdog3"] = { -- Custom Emote by MissSnowie
        "hooman@hugging_little_doggy",
        "base",
        "Porter Petit Chien 2",
        "csdog4",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AnimalEmote = true
    },
    ["csdog4"] = { -- Custom Emote by MissSnowie
        "little_doggy@hugging_hooman",
        "base",
        "Petit Chien porté 2",
        "csdog3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.95,
            yPos = 0.16,
            zPos = -0.15,
            xRot = 3.70,
            yRot = 75.00,
            zRot = -161.90,
        },
        AnimalEmote = true
    },
    ["cbdog"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter gros chien",
        "cbdog2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AnimalEmote = true
    },
    ["cbdog2"] = {
        "creatures@rottweiler@amb@sleep_in_kennel@",
        "sleep_in_kennel",
        "Gros chien porté",
        "cbdog",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = -0.100,
            yPos = 0.650,
            zPos = 0.430,
            xRot = 0.0,
            yRot = 0.0,
            zRot = -100.00,
        },
        AnimalEmote = true
    },
    ["pback"] = { -- Custom Animation By SapphireMods
        "mx@piggypack_a",
        "mxclip_a",
        "Porter sur le dos",
        "pback2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pback2"] = { -- Custom Animation By SapphireMods
        "mx@piggypack_b",
        "mxanim_b",
        "Se faire porter sur le dos",
        "pback",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0200,
            yPos = -0.4399,
            zPos = 0.4200,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        }
    },
    ["cprs"] = {
        "mini@cpr@char_a@cpr_str",
        "cpr_pumpchest",
        "Faire un CPR",
        "cprs2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 250
        }
    },
    ["cprs2"] = {
        "mini@cpr@char_b@cpr_str",
        "cpr_pumpchest",
        "Subir une CPR",
        "cprs",
        AnimationOptions = {
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.35,
            yPos = 0.8,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 270.0
        }
    },
    ["cprs3"] = {
        "missheistfbi3b_ig8_2",
        "cpr_loop_paramedic",
        "Donner CPR 2",
        "cprs4",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 250
        }
    },
    ["cprs4"] = {
        "missheistfbi3b_ig8_2",
        "cpr_loop_victim",
        "Subir un CPR 2",
        "cprs3",
        AnimationOptions = {
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.35,
            yPos = 0.65,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 270.0
        }
    },
    ["hostage"] = {
        "anim@gangops@hostage@",
        "perp_idle",
        "Prendre en otage",
        "hostage2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["hostage2"] = {
        "anim@gangops@hostage@",
        "victim_idle",
        "Se faire prendre en otage",
        "hostage",
        AnimationOptions = {
            EmoteLoop = true,
            Attachto = true,
            xPos = -0.3,
            yPos = 0.1,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        }
    },
    ["search"] = { -- Custom Emote By ultrahacx
        "custom@police",
        "police",
        "Fouille",
        "search2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = false,
            -- EmoteDuration = 9700
        }
    },
    ["search2"] = {
        "missfam5_yoga",
        "a2_pose",
        "Se faire fouiller",
        "search",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = false,
            -- EmoteDuration = 9700,
            Attachto = true,
            xPos = 0.0,
            yPos = 0.5,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        }
    },
    ["followa"] = { -- Custom Ped In Front Emote By Dollie Mods
        "dollie_mods@follow_me_001",
        "follow_me_001",
        "Suivre devant ",
        "followb",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            -- We can set this to true for lols, however it messes up if you walk through doors. Either player can press X to cancel the shared emotes
        }
    },
    ["followb"] = { -- Custom Ped At Back Emote by Dollie Mods
        "dollie_mods@follow_me_002",
        "follow_me_002",
        "Suivre derrière",
        "followa",
        AnimationOptions = {
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.078,
            yPos = 0.018,
            zPos = 0.00,
            xRot = 0.00,
            yRot = 0.00,
            zRot = 0.00
        }
    },
    ["kiss"] = {
        "hs3_ext-20",
        "cs_lestercrest_3_dual-20",
        "Bisou",
        "kiss2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 10000,
            SyncOffsetFront = 0.08
        }
    },
    ["kiss2"] = {
        "hs3_ext-20",
        "csb_georginacheng_dual-20",
        "Bisou 2",
        "kiss",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 10000,
            SyncOffsetFront = 0.08
        }
    },
    ["kiss3"] = {
        "hs3_ext-19",
        "cs_lestercrest_3_dual-19",
        "Bisou 3",
        "kiss4",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 10000,
            SyncOffsetFront = 0.08
        }
    },
    ["kiss4"] = {
        "hs3_ext-19",
        "csb_georginacheng_dual-19",
        "Bisou 4",
        "kiss3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 10000,
            SyncOffsetFront = 0.08
        }
    },
    ["kisscuteneck"] = {
        "genesismods_kissme@kissmale8",
        "kissmale8",
        "Bisou mignon – Cou (Homme)",
        "kisscuteneck2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            --SyncOffsetFront = 0.05,
            --bone = 0,
            xPos = -0.56,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["kisscuteneck2"] = {
        "genesismods_kissme@kissfemale8",
        "kissfemale8",
        "Bisou mignon – Cou (Femme)",
        "kisscuteneck",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            --SyncOffsetFront = 0.05,
        }
    },
    ["kisscutecheek"] = {
        "genesismods_kissme@kissmale9",
        "kissmale9",
        "Bisou mignon – Joue (Homme)",
        "kisscutecheek2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            --SyncOffsetFront = 0.05,
            --bone = 0,
            xPos = 0.35,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["kisscutecheek2"] = {
        "genesismods_kissme@kissfemale9",
        "kissfemale9",
        "Bisou mignon – Joue (Femme)",
        "kisscutecheek",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            --SyncOffsetFront = 0.05,
        }
    },
    ["kisscutefh"] = {
        "genesismods_kissme@kissmale10",
        "kissmale10",
        "Bisou front (Homme)",
        "kisscutefh2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            --SyncOffsetFront = 0.05,
            --bone = 0,
            xPos = 0.38,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["kisslips"] = {
        "chocoholic@couple13",
        "couple13_clip",
        "Bisou front (Femme)",
        "kisslips2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.1600,
            yPos = 0.2700,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 130.0,
        }
    },
    ["kisslips2"] = {
        "chocoholic@couple14",
        "couple14_clip",
        "Bisou mignon – Lèvres (Homme)",
        "kisslips",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["kisscutefh2"] = {
        "genesismods_kissme@kissfemale10",
        "kissfemale10",
        "Bisou mignon – Lèvres (Femme)",
        "kisscutefh",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            --SyncOffsetFront = 0.05,
        }
    },
    ["coupleanim"] = {
        "anim@scripted@robbery@tun_prep_uni_ig1_couple@",
        "action_var_01_bank_manager",
        "Couple qui boit (Verre de vin)",
        "coupleanim2",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 60309,
            PropPlacement = {
                -0.0500,
                -0.0100,
                -0.1700,
                0.0,
                0.0,
                0.0,
            },
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["coupleanim2"] = {
        "anim@scripted@robbery@tun_prep_uni_ig1_couple@",
        "action_var_01_female",
        "Couple qui boit F (Verre de vin)",
        "coupleanim",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
            },
            SyncOffsetSide = -0.04125,
            SyncOffsetFront = 0.11,
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["holdme"] = { -- Custom Animation By SapphireMods
        "mx_couple5_1_a",
        "mx_couple5_1_a_clip",
        "Prendre dans les bras",
        "holdmeb",
        AnimationOptions = {
            EmoteLoop = true
        },
    },
    ["holdmeb"] = { -- Custom Animation By SapphireMods
        "mx_couple5_1_b",
        "mx_couple5_1_b_clip",
        "Se faire prendre dans les bras",
        "holdme",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.0200,
            yPos =  0.2400,
            zPos = -0.0100,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        },
    },
    ["holdmec"] = { -- Custom Animation By SapphireMods
        "mx_couple5_2_a",
        "mx_couple5_2_a_clip",
        "Prendre dans les bras 2",
        "holdmed",
        AnimationOptions = {
            EmoteLoop = true
        },
    },
    ["holdmed"] = { -- Custom Animation By SapphireMods
        "mx_couple5_2_b",
        "mx_couple5_2_b_clip",
        "Se faire prendre dans les bras 2",
        "holdmec",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.1200,
            yPos =  0.3600,
            zPos = -0.0100,
            xRot = 0.0,
            yRot = 0.0,
            zRot = -180.0
        },
    },
    ["holdmee"] = { -- Custom Animation By SapphireMods
        "mx_couple5_3_a",
        "mx_couple5_3_a_clip",
        "Prendre dans les bras 3",
        "holdmef",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["holdmef"] = { -- Custom Animation By SapphireMods
        "mx_couple5_3_b",
        "mx_couple5_3_b_clip",
        "Se faire prendre dans les bras 3",
        "holdmee",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos =  0.0400,
            yPos =  0.2100,
            zPos = -0.0300,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        },
    }
}

--- DANCING EMOTES, SOME WITH PROPS ---

RP.Dances = {
    label = "Danses",
    icon = "💃",
    ["dance"] = {
        "anim@amb@nightclub@dancers@podium_dancers@",
        "hi_dance_facedj_17_v2_male^5",
        "Danse",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
        "high_center_down",
        "Danse 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance3"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@",
        "high_center",
        "Danse 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance4"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
        "high_center_up",
        "Danse 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance5"] = {
        "anim@amb@casino@mini@dance@dance_solo@female@var_a@",
        "med_center",
        "Danse 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance6"] = {
        "misschinese2_crystalmazemcs1_cs",
        "dance_loop_tao",
        "Danse 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance7"] = {
        "misschinese2_crystalmazemcs1_ig",
        "dance_loop_tao",
        "Danse 7",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance8"] = {
        "missfbi3_sniping",
        "dance_m_default",
        "Danse 8",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dance9"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "med_center_up",
        "Danse 9",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancef"] = {
        "anim@amb@nightclub@dancers@solomun_entourage@",
        "mi_dance_facedj_17_v1_female^1",
        "Danse F",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancef2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "high_center",
        "Danse F2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancef3"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "high_center_up",
        "Danse F3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancef4"] = {
        "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity",
        "hi_dance_facedj_09_v2_female^1",
        "Danse F4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancef5"] = {
        "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity",
        "hi_dance_facedj_09_v2_female^3",
        "Danse F5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancef6"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "high_center_up",
        "Danse F6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclub"] = {
        "anim@amb@nightclub_island@dancers@beachdance@",
        "hi_idle_a_m03",
        "Danse Club",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubb"] = {
        "anim@amb@nightclub_island@dancers@beachdance@",
        "hi_idle_a_m05",
        "Danse Club 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubc"] = {
        "anim@amb@nightclub_island@dancers@beachdance@",
        "hi_idle_a_m02",
        "Danse Club 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubd"] = {
        "anim@amb@nightclub_island@dancers@beachdance@",
        "hi_idle_b_f01",
        "Danse Club 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclube"] = {
        "anim@amb@nightclub_island@dancers@club@",
        "hi_idle_a_f02",
        "Danse Club 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubf"] = {
        "anim@amb@nightclub_island@dancers@club@",
        "hi_idle_b_m03",
        "Danse Club 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubg"] = {
        "anim@amb@nightclub_island@dancers@club@",
        "hi_idle_d_f01",
        "Danse Club 7",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubh"] = {
        "anim@amb@nightclub_island@dancers@crowddance_facedj@",
        "mi_dance_facedj_17_v2_male^4",
        "Danse Club 8 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubi"] = {
        "anim@amb@nightclub_island@dancers@crowddance_single_props@",
        "mi_dance_prop_13_v1_male^3",
        "Danse Club 9 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubj"] = {
        "anim@amb@nightclub_island@dancers@crowddance_groups@groupd@",
        "mi_dance_crowd_13_v2_male^1",
        "Danse Club 10 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubk"] = {
        "anim@amb@nightclub_island@dancers@crowddance_facedj@",
        "mi_dance_facedj_15_v2_male^4",
        "Danse Club 11 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubl"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "high_center_up",
        "Danse Club 12",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubm"] = {
        "anim@amb@nightclub_island@dancers@crowddance_facedj@",
        "hi_dance_facedj_hu_15_v2_male^5",
        "Danse Club 13 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubn"] = {
        "anim@amb@nightclub_island@dancers@crowddance_facedj@",
        "hi_dance_facedj_hu_17_male^5",
        "Danse Club 14 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubo"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@shuffle@",
        "high_center",
        "Danse Club 15 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceclubp"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@shuffle@",
        "high_left_down",
        "Danse Club 16 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancedrink"] = {
        "anim@amb@nightclub_island@dancers@beachdanceprop@",
        "mi_idle_c_m01",
        "Danse en buvant (Bière)",
        AnimationOptions = {
            Prop = 'prop_beer_amopen',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.00,
                0.0,
                0.0,
                0.0,
                20.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink2"] = {
        "anim@amb@nightclub_island@dancers@beachdanceprop@",
        "mi_loop_f1",
        "Danse en buvant 2 (Vin)",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0900,
                0.0,
                0.0,
                0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink3"] = {
        "anim@amb@nightclub_island@dancers@beachdanceprop@",
        "mi_loop_m04",
        "Danse en buvant 3 (Whisky)",
        AnimationOptions = {
            Prop = 'ba_prop_battle_whiskey_opaque_s',
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.00,
                0.0,
                0.0,
                0.0,
                10.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink4"] = {
        "anim@amb@nightclub_island@dancers@beachdanceprops@male@",
        "mi_idle_b_m04",
        "Danse en buvant 4 (Whisky)",
        AnimationOptions = {
            Prop = 'ba_prop_battle_whiskey_opaque_s',
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.00,
                0.0,
                0.0,
                0.0,
                10.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink5"] = {
        "anim@amb@nightclub_island@dancers@crowddance_single_props@",
        "hi_dance_prop_09_v1_female^3",
        "Danse en buvant 5 (Vin)",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0900,
                0.0,
                0.0,
                0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink6"] = {
        "anim@amb@nightclub_island@dancers@crowddance_single_props@",
        "hi_dance_prop_09_v1_male^3",
        "Danse en buvant 6 (Bière)",
        AnimationOptions = {
            Prop = 'prop_beer_logopen',
            PropBone = 28422,
            PropPlacement = {
                0.0090,
                0.0010,
                -0.0310,
                180.0,
                180.0,
                -69.99
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink7"] = {
        "anim@amb@nightclub_island@dancers@crowddance_single_props@",
        "hi_dance_prop_11_v1_female^3",
        "Danse en buvant 7 (Vin)",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0900,
                0.0,
                0.0,
                0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancedrink8"] = {
        "anim@amb@nightclub_island@dancers@crowddance_single_props@",
        "hi_dance_prop_11_v1_female^1",
        "Danse en buvant 8 (Vin)",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0900,
                0.0,
                0.0,
                0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["danceslow2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "low_center",
        "Danse doucement 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceslow3"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        "low_center_down",
        "Danse doucement 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceslow4"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
        "low_center",
        "Danse doucement 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceupper"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
        "high_center",
        "Danse main levé",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["danceupper2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
        "high_center_up",
        "Danse main levé 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["danceshy"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@",
        "low_center",
        "Danse timide",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceshy2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@",
        "low_center_down",
        "Danse timide 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceslow"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
        "low_center",
        "Danse doucement",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly1"] = {
        "rcmnigel1bnmt_1b",
        "dance_loop_tyler",
        "Danse ridicule 1",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly"] = {
        "special_ped@mountain_dancer@monologue_3@monologue_3a",
        "mnt_dnc_buttwag",
        "Danse ridicule",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly2"] = {
        "move_clown@p_m_zero_idles@",
        "fidget_short_dance",
        "Danse ridicule 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly3"] = {
        "move_clown@p_m_two_idles@",
        "fidget_short_dance",
        "Danse ridicule 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly4"] = {
        "anim@amb@nightclub@lazlow@hi_podium@",
        "danceidle_hi_11_buttwiggle_b_laz",
        "Danse ridicule 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly5"] = {
        "timetable@tracy@ig_5@idle_a",
        "idle_a",
        "Danse ridicule 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly6"] = {
        "timetable@tracy@ig_8@idle_b",
        "idle_d",
        "Danse ridicule 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly7"] = {
        "anim@amb@casino@mini@dance@dance_solo@female@var_b@",
        "med_center",
        "Danse ridicule 7",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly8"] = {
        "anim@amb@casino@mini@dance@dance_solo@female@var_b@",
        "high_center",
        "Danse ridicule 8",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancesilly9"] = {
        "anim@mp_player_intcelebrationfemale@the_woogie",
        "the_woogie",
        "Danse ridicule 9",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["danceold"] = {
        "anim@mp_player_intupperuncle_disco",
        "idle_a",
        "Danse vieux",
        AnimationOptions = {
            EmoteLoop = true,
            --			EmoteMoving = true,-- Removing the comment will allow for you to mix and match dance emotes, ie /e danceold and /e dance to control the bottom half of the body.
        }
    },
    ["danceglowstick"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_13_mi_hi_sexualgriding_laz",
        "Danse Bâtons lumineux",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                0.1400,
                0.0,
                -80.0,
                20.0
            },
            SecondProp = 'ba_prop_battle_glowstick_01',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0700,
                0.0900,
                0.0,
                -120.0,
                -20.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["danceglowstick2"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_12_mi_hi_bootyshake_laz",
        "Danse Bâtons lumineux 2",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                0.1400,
                0.0,
                -80.0,
                20.0
            },
            SecondProp = 'ba_prop_battle_glowstick_01',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0700,
                0.0900,
                0.0,
                -120.0,
                -20.0
            },
            EmoteLoop = true
        }
    },
    ["danceglowstick3"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Bâtons lumineux 3",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                0.1400,
                0.0,
                -80.0,
                20.0
            },
            SecondProp = 'ba_prop_battle_glowstick_01',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0700,
                0.0900,
                0.0,
                -120.0,
                -20.0
            },
            EmoteLoop = true
        }
    },
    ["dancehorse"] = {
        "anim@amb@nightclub@lazlow@hi_dancefloor@",
        "dancecrowd_li_15_handup_laz",
        "Danse cheval",
        AnimationOptions = {
            Prop = "ba_prop_battle_hobby_horse",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dancehorse2"] = {
        "anim@amb@nightclub@lazlow@hi_dancefloor@",
        "crowddance_hi_11_handup_laz",
        "Danse cheval 2",
        AnimationOptions = {
            Prop = "ba_prop_battle_hobby_horse",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }
    },
    ["dancehorse3"] = {
        "anim@amb@nightclub@lazlow@hi_dancefloor@",
        "dancecrowd_li_11_hu_shimmy_laz",
        "Danse cheval 3",
        AnimationOptions = {
            Prop = "ba_prop_battle_hobby_horse",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }
    },
    ["dancewave"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "wave_dance_1",
        "Vague bras",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave02"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "wave_dance_2",
        "Vague bras 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave03"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "wave_dance_3",
        "Vague bras 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave04"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "wave_dance_4",
        "Vague bras 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave05"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "tutankhamun_dance_1",
        "Vague bras 5 - Tutankhamen",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave06"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "tutankhamun_dance_2",
        "Vague bras 6 - Tutankhamen 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave07"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "snake_dance_1",
        "Serpert",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave08"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "slide_dance",
        "Glissade",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave09"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "slide_dance_2",
        "Glissade 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave10"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "robot_dance",
        "Danse Robot",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave11"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "locking_dance",
        "Danse à bloc",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancewave12"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "headspin",
        "Tourbion tête",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["dancewave13"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "flaire_dance",
        "Danse flamboyante ",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["dancewave14"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "crowd_girl_dance",
        "Danse collective féminine",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["dancewave15"] = { -- Custom Emote By BoringNeptune
        "dancing_wave_part_one@anim",
        "uprock_dance_1",
        "Danse Rock",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancethriller"] = { -- Custom Emote By BoringNeptune
        "mj_thriller",
        "mj_thriller_dance",
        "MJ Thriller",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dj"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_dance_cntr_open_dix",
        "DJ",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dj2"] = {
        "anim@amb@nightclub@djs@solomun@",
        "sol_idle_ctr_mid_a_sol",
        "DJ 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj3"] = {
        "anim@amb@nightclub@djs@solomun@",
        "sol_dance_l_sol",
        "DJ 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj4"] = {
        "anim@amb@nightclub@djs@black_madonna@",
        "dance_b_idle_a_blamadon",
        "DJ 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj1"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_end_dix",
        "DJ 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj5"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_idle_cntr_a_dix",
        "DJ 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj6"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_idle_cntr_b_dix",
        "DJ 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj7"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_idle_cntr_g_dix",
        "DJ 7",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj8"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_idle_cntr_gb_dix",
        "DJ 8",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dj9"] = {
        "anim@amb@nightclub@djs@dixon@",
        "dixn_sync_cntr_j_dix",
        "DJ 9",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["twerk"] = {
        "switch@trevor@mocks_lapdance",
        "001443_01_trvs_28_idle_stripper",
        "Twerk",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdance"] = {
        "mp_safehouse",
        "lap_dance_girl",
        "Lapdance"
    },
    ["lapdance2"] = {
        "mini@strip_club@private_dance@idle",
        "priv_dance_idle",
        "Lapdance 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdance3"] = {
        "mini@strip_club@private_dance@part1",
        "priv_dance_p1",
        "Lapdance 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdance4"] = {
        "mini@strip_club@private_dance@part2",
        "priv_dance_p2",
        "Lapdance 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdance5"] = {
        "mini@strip_club@private_dance@part3",
        "priv_dance_p3",
        "Lapdance 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdance6"] = {
        "oddjobs@assassinate@multi@yachttarget@lapdance",
        "yacht_ld_f",
        "Lapdance 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdancewith"] = {
        "mini@strip_club@lap_dance_2g@ld_2g_p3",
        "ld_2g_p3_s2",
        "Lapdance Avec",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdancewith2"] = {
        "mini@strip_club@lap_dance_2g@ld_2g_p2",
        "ld_2g_p2_s2",
        "Lapdance Avec2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapdancewith3"] = {
        "mini@strip_club@lap_dance_2g@ld_2g_p1",
        "ld_2g_p1_s2",
        "Lapdance Avec3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapchair"] = {
        "mini@strip_club@lap_dance@ld_girl_a_song_a_p1",
        "ld_girl_a_song_a_p1_f",
        "Lap Chaise",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapchair2"] = {
        "mini@strip_club@lap_dance@ld_girl_a_song_a_p2",
        "ld_girl_a_song_a_p2_f",
        "Lap Chaise2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lapchair3"] = {
        "mini@strip_club@lap_dance@ld_girl_a_song_a_p3",
        "ld_girl_a_song_a_p3_f",
        "Lap Chaise3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["salsa"] = {
        "anim@mp_player_intuppersalsa_roll",
        "idle_a",
        "Tourbillon Salso",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancecrankdat"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@shuffle@",
        "high_right_up",
        "Crank Dat",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancecrankdat2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@shuffle@",
        "high_right_down",
        "Crank Dat 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancemonkey"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@techno_monkey@",
        "high_center",
        "Danse singe",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancemonkey2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@techno_monkey@",
        "high_center_down",
        "Danse singe 2  ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancemonkey3"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@techno_monkey@",
        "med_center_down",
        "Danse singe 3  ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["boxdance"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@beach_boxing@",
        "med_right_down",
        "Danse boxe Seul",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancehiphop"] = {
        "anim@amb@nightclub@mini@dance@dance_paired@dance_d@",
        "ped_a_dance_idle",
        "Danse Hip Hop",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancehiphop2"] = {
        "anim@amb@nightclub@mini@dance@dance_paired@dance_b@",
        "ped_a_dance_idle",
        "Danse Hip Hop 2 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancehiphop3"] = {
        "anim@amb@nightclub@mini@dance@dance_paired@dance_a@",
        "ped_a_dance_idle",
        "Danse Hip Hop 3 ",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dancepride"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride A",
        AnimationOptions = {
            Prop = 'lilprideflag1', --- Rainbow
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag1',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["danceprideb"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride B - LGBTQIA",
        AnimationOptions = {
            Prop = 'lilprideflag2', -- LGBTQIA
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag2',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancepridea"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride A - Bisexuel",
        AnimationOptions = {
            Prop = 'lilprideflag3', -- Bisexual
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag3',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancepridec"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride C - Lesbienne",
        AnimationOptions = {
            Prop = 'lilprideflag4', -- Lesbian
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag4',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["danceprided"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride D - Pansexuel",
        AnimationOptions = {
            Prop = 'lilprideflag5', -- Pansexual
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag5',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancepridee"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride E - Transgendre ",
        AnimationOptions = {
            Prop = 'lilprideflag6', -- Transgender
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag6',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dancepridef"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride F - Non Binaire",
        AnimationOptions = {
            Prop = 'lilprideflag7', -- Lesbian
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag7',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["danceprideg"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride G - Asexuel",
        AnimationOptions = {
            Prop = 'lilprideflag8', -- Asexual
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag8',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["danceprideh"] = {
        "anim@amb@nightclub@lazlow@hi_railing@",
        "ambclub_09_mi_hi_bellydancer_laz",
        "Danse Pride H - hétérosexuel",
        AnimationOptions = {
            Prop = 'lilprideflag9', -- Straight Ally
            PropBone = 18905,
            PropPlacement = {
                0.0900,
                0.0000,
                0.0300,
                -39.911,
                93.9166,
                -5.8062
            },
            SecondProp = 'lilprideflag9',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.0900,
                -0.0200,
                -0.0300,
                -90.2454,
                5.7068,
                -28.7797
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
}

---- ANIMAL EMOTES ----
----    gros chien    ----

RP.AnimalEmotes = {
    label = "Animal",
    icon = "🐾",
    ["bdogbark"] = {
        "creatures@rottweiler@amb@world_dog_barking@idle_a",
        "idle_a",
        "Aboiement - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdogindicateahead"] = {
        "creatures@rottweiler@indication@",
        "indicate_ahead",
        "Indiquer la direction à suivre - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdogindicatehigh"] = {
        "creatures@rottweiler@indication@",
        "indicate_high",
        "Aboyez derrière un grillage 1 - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdogindicatelow"] = {
        "creatures@rottweiler@indication@",
        "indicate_low",
        "Aboyez derrière un grillage 2 - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdogbeg"] = {
        "creatures@rottweiler@tricks@",
        "beg_loop",
        "Réclamer - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdogbeg2"] = {
        "creatures@rottweiler@tricks@",
        "paw_right_loop",
        "Réclamer 2 - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdoglayright"] = {
        "creatures@rottweiler@move",
        "dead_right",
        "Faire le mort à droite - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdoglayleft"] = {
        "creatures@rottweiler@move",
        "dead_left",
        "Faire le mort à gauche - Gros chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["bdogsitcar"] = {
        "creatures@rottweiler@incar@",
        "sit",
        "S'asseoir en voiture - Gros Chien",
        AnimationOptions = {EmoteLoop = true}
    },
    --[[     ["bdogfhump"] = {
            "creatures@rottweiler@amb@",
            "hump_loop_ladydog",
            "Female Hump (gros chien)",
            AnimationOptions = {EmoteLoop = true},
            AdultAnimation = true,
            AnimalEmote = true
        },
        ["bdogmhump"] = {
            "creatures@rottweiler@amb@",
            "hump_loop_chop",
            "Male Hump (gros chien)",
            AnimationOptions = {EmoteLoop = true},
            AdultAnimation = true,
            AnimalEmote = true
        }, ]]
    ["bdogshit"] = {
        "creatures@rottweiler@move",
        "dump_loop",
        "Faire caca - Gros Chien",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_poo",
            PtfxNoProp = true,
            PtfxPlacement = {
                0.10,
                -0.08,
                0.0,
                0.0,
                90.0,
                180.0,
                1.0
            },
            PtfxInfo = Animations.Languages['poop'],
            PtfxWait = 200,
            PtfxCanHold = true
        }
    },
    ["bdogitch"] = {
        "creatures@rottweiler@amb@world_dog_sitting@idle_a",
        "idle_a",
        "Se gratter - Gros chien",
        AnimationOptions = {EmoteDuration = 2000}
    },
    ["bdogsleep"] = {
        "creatures@rottweiler@amb@sleep_in_kennel@",
        "sleep_in_kennel",
        "Dormir - Gros chien",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "bdogupk",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogsit"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "Assis - Gros chien",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogpee"] = {
        "creatures@rottweiler@move",
        "pee_left_idle",
        "Faire pipi à gauche - Gros chien",
        AnimationOptions = {
            EmoteLoop = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {
                -0.15,
                -0.35,
                0.0,
                0.0,
                90.0,
                180.0,
                1.0
            },
            PtfxInfo = Animations.Languages['pee'],
            PtfxWait = 3000,
            PtfxCanHold = true
        }
    },
    ["bdogpee2"] = {
        "creatures@rottweiler@move",
        "pee_right_idle",
        "Faire pipi à droite - Gros chien",
        AnimationOptions = {
            EmoteLoop = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {
                0.15,
                -0.35,
                0.0,
                0.0,
                90.0,
                0.0,
                1.0
            },
            PtfxInfo = Animations.Languages['pee'],
            PtfxWait = 3000,
            PtfxCanHold = true
        }
    },
    ["bdogglowa"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "nill",
        "Baton lumineux - Gros chien",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 31086,
            PropPlacement = {
                0.2000,
                0.000,
                -0.0600,
                90.00,
                0.00,
                0.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bdogglowb"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "Baton lumineux assis - Gros chien",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 31086,
            PropPlacement = {
                0.2000,
                0.000,
                -0.0600,
                90.00,
                0.00,
                0.00
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogpridea"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride A (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag1', -- Rainbow
            PropBone = 31086,
            PropPlacement = {
                0.1900,
                0.0000,
                -0.0500,
                100.0000,
                90.0000,
                0.0000
            },
            SecondProp = 'lilprideflag1',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940,
                0.020,
                -0.0500,
                -90.0000,
                -90.0000,
                0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogprideb"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride B - LGBTQIA (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag2', -- LGBTQIA
            PropBone = 31086,
            PropPlacement = {
                0.1900,
                0.0000,
                -0.0500,
                100.0000,
                90.0000,
                0.0000
            },
            SecondProp = 'lilprideflag2',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940,
                0.020,
                -0.0500,
                -90.0000,
                -90.0000,
                0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogpridec"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride C - Bisexuel (big dog)",
        AnimationOptions = {
            Prop = 'lilprideflag3', -- Bisexual
            PropBone = 31086,
            PropPlacement = {
                0.1900,
                0.0000,
                -0.0500,
                100.0000,
                90.0000,
                0.0000
            },
            SecondProp = 'lilprideflag3',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940,
                0.020,
                -0.0500,
                -90.0000,
                -90.0000,
                0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogprided"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride D - Lesbien (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag4', -- Lesbian
            PropBone = 31086,
            PropPlacement = {
                0.1900,
                0.0000,
                -0.0500,
                100.0000,
                90.0000,
                0.0000
            },
            SecondProp = 'lilprideflag4',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940,
                0.020,
                -0.0500,
                -90.0000,
                -90.0000,
                0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogpridee"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride E - Pansexuel (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag5', -- Pansexual
            PropBone = 31086,
            PropPlacement = {
                0.1900,
                0.0000,
                -0.0500,
                100.0000,
                90.0000,
                0.0000
            },
            SecondProp = 'lilprideflag5',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940,
                0.020,
                -0.0500,
                -90.0000,
                -90.0000,
                0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogpridef"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride F - Transgendre  (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag6', -- Transgender
            PropBone = 31086,
            PropPlacement = {0.1900, 0.0000, -0.0500, 100.0000, 90.0000, 0.0000},
            SecondProp = 'lilprideflag6',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940, 0.020, -0.0500, -90.0000, -90.0000, 0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogprideg"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride G - Non Binaire (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag7', -- Non Binary
            PropBone = 31086,
            PropPlacement = {0.1900, 0.0000, -0.0500, 100.0000, 90.0000, 0.0000},
            SecondProp = 'lilprideflag7',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940, 0.020, -0.0500, -90.0000, -90.0000, 0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogprideh"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride H - Asexuel (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag8', -- Asexual
            PropBone = 31086,
            PropPlacement = {0.1900, 0.0000, -0.0500, 100.0000, 90.0000, 0.0000},
            SecondProp = 'lilprideflag8',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940, 0.020, -0.0500, -90.0000, -90.0000, 0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogpridei"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "base",
        "S'assoier Pride I - Hétero (gros chien)",
        AnimationOptions = {
            Prop = 'lilprideflag9', -- Straight Ally
            PropBone = 31086,
            PropPlacement = {0.1900, 0.0000, -0.0500, 100.0000, 90.0000, 0.0000},
            SecondProp = 'lilprideflag9',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.1940, 0.020, -0.0500, -90.0000, -90.0000, 0.0000
            },
            EmoteLoop = true,
            ExitEmote = "bdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["bdogfw"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "nill",
        "Feu d'artifice - Gros Chien",
        AnimationOptions = {
            Prop = 'ind_prop_firework_01', --- blue, green, red, purple pink, cyan, yellow, white
            PtfxColor = {
                {R = 255, G = 0, B = 0, A = 1.0},
                {R = 0, G = 255, B = 0, A = 1.0},
                {R = 0, G = 0, B = 255, A = 1.0},
                {R = 177, G = 5, B = 245, A = 1.0},
                {R = 251, G = 3, B = 255, A = 1.0},
                {R = 2, G = 238, B = 250, A = 1.0},
                {R = 252, G = 248, B = 0, A = 1.0},
                {R = 245, G = 245, B = 245, A = 1.0}
            },
            PropBone = 31086,
            PropPlacement = {
                0.1400, 0.3300, -0.0800, -85.6060, -176.7400, -9.8767
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_indep_fireworks",
            PtfxName = "scr_indep_firework_trail_spawn",
            PtfxPlacement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6},
            PtfxInfo = Animations.Languages['firework'],
            PtfxWait = 200
        }
    },
    ["bdogfris"] = {
        "creatures@rottweiler@amb@world_dog_sitting@base",
        "nill",
        "Frisbee (gros chien)",
        AnimationOptions = {
            Prop = 'p_ld_frisbee_01',
            PropBone = 31086,
            PropPlacement = {
                0.2600,
                0.0200,
                -0.0600,
                -173.7526,
                -169.4149,
                21.4173
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    ---- ANIMAL EMOTES ----
    ----   Petit Chien   ----

    ["sdogbark"] = {
        "creatures@pug@amb@world_dog_barking@idle_a",
        "idle_a",
        "Aboiement - Petit Chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["sdogitch"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_a",
        "Se gratter - Petit Chien",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogsit"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Assis - Petit Chien",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogld"] = {
        "misssnowie@little_doggy_lying_down",
        "base",
        "Allongez - Petit Chien",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogshake"] = {
        "creatures@pug@amb@world_dog_barking@idle_a",
        "idle_c",
        "Se secouer - Petit Chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["sdogdance"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse 1 - Petit Chien",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0300, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdance2"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse 2 - Petit Chien",
        AnimationOptions = {
            Prop = 'ba_prop_battle_glowstick_01',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0300, 0.0, 0.0, 0.0},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdancepridea"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride A (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag1',
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdanceprideb"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride B - LGBTQIA (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag2', -- LGBTQIA
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdancepridec"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride C - Bisexuel (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag3', -- Bisexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdanceprided"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride D - Lesbienne (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag4', -- Lesbian
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdancepridee"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride E - Pansexuel (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag5', -- Pansexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdancepridef"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride F - Transgendre  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag6', -- Transgender
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdanceprideg"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride G - Non Binaire (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag7', -- Non Binary
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdanceprideh"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride H - Asexuel (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag8', -- Asexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdancepridei"] = {
        "creatures@pug@move",
        "idle_turn_0",
        "Danse Pride I - Hétéro (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag9', -- Straight Ally
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            SecondProp = 'prop_cs_sol_glasses',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogbb"] = {
        "creatures@pug@move",
        "nill",
        "Tenir une balle - Petit Chien",
        AnimationOptions = {
            Prop = 'w_am_baseball',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0500, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogburger"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un burger - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_burger_01',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0400, 0.0000, -90.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogcontroller"] = {
        "creatures@pug@move",
        "nill",
        "Tenir une manette - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_controller_01',
            PropBone = 31086,
            PropPlacement = {0.1800, -0.0300, 0.0000, -180.000, 90.0000, 0.0000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdolla"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un billet - Petit Chien",
        AnimationOptions = {
            Prop = 'p_banknote_onedollar_s',
            PropBone = 31086,
            PropPlacement = {0.1700, -0.0100, 0.0000, 90.0000, 0.0000, 0.000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdolla2"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un billet froissé - Petit Chien",
        AnimationOptions = {
            Prop = 'bkr_prop_scrunched_moneypage',
            PropBone = 31086,
            PropPlacement = {0.1700, 0.000, 0.0000, 90.0000, 00.0000, 00.0000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdolla3"] = {
        "creatures@pug@move",
        "nill",
        "Tenir une pile de billet - Petit Chien",
        AnimationOptions = {
            Prop = 'bkr_prop_money_wrapped_01',
            PropBone = 31086,
            PropPlacement = {0.1700, -0.0100, 0.0000, 90.0000, 0.0000, 0.000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogdolla4"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un sac - Petit Chien",
        AnimationOptions = {
            Prop = 'ch_prop_ch_moneybag_01a',
            PropBone = 31086,
            PropPlacement = {
                0.1200, -0.2000, 0.0000, -79.9999997, 90.00, 0.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogmic"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un micro - Petit Chien",
        AnimationOptions = {
            Prop = 'p_ing_microphonel_01',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0170, 0.0300, 0.000, 0.0000, 0.0000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogteddy"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un nounours 1 - Petit Chien",
        AnimationOptions = {
            Prop = 'v_ilev_mr_rasberryclean',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.1100, -0.23, 0.000, 0.0000, 0.0000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogteddy2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Tenir un nounours 2 - Petit Chien",
        AnimationOptions = {
            Prop = 'v_ilev_mr_rasberryclean',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.1100, -0.23, 0.000, 0.0000, 0.0000},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogtennis"] = {
        "creatures@pug@move",
        "nill",
        "Tenir une balle de tennis - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_tennis_ball',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0600, 0.0, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogtennisr"] = {
        "creatures@pug@move",
        "nill",
        "Tenir une raquette - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_tennis_rack_01',
            PropBone = 31086,
            PropPlacement = {0.1500, -0.0200, 0.00, 0.000, 0.0000, -28.0000},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogrose"] = {
        "creatures@pug@move",
        "nill",
        "Tenir une rose - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_single_rose',
            PropBone = 12844,
            PropPlacement = {0.1090, -0.0140, 0.0500, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogrose2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Tenir une rose assis - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_single_rose',
            PropBone = 12844,
            PropPlacement = {0.1090, -0.0140, 0.0500, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogggun"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un pistolet en or - Petit Chien",
        AnimationOptions = {
            Prop = 'w_pi_pistol_luxe',
            PropBone = 12844,
            PropPlacement = {0.2010, -0.0080, 0.0, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoggun2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Tenir un pistolet assis - Petit Chien",
        AnimationOptions = {
            Prop = 'w_pi_pistol_luxe',
            PropBone = 12844,
            PropPlacement = {0.2010, -0.0080, 0.0, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogstun"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un taser - Petit Chien",
        AnimationOptions = {
            Prop = 'w_pi_stungun',
            PropBone = 12844,
            PropPlacement = {0.1400, -0.0100, 0.0, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "core",
            PtfxName = "blood_stungun",
            PtfxPlacement = {0.208, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0},
            PtfxInfo = Animations.Languages['stun'],
            PtfxWait = 200
        }
    },
    ["sdoggl1"] = {
        "creatures@pug@move",
        "nill",
        "Porter des lunettes - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_aviators_01',
            PropBone = 31086,
            PropPlacement = {0.0500, 0.0400, 0.000, -90.00, 90.00, 0.00},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoggl2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Porter des lunettes assis - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_aviators_01',
            PropBone = 31086,
            PropPlacement = {0.0500, 0.0400, 0.000, -90.00, 90.00, 0.00},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdoggl3"] = {
        "creatures@pug@move",
        "nill",
        "Porter des lunettes 2 - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_sol_glasses',
            PropBone = 31086,
            PropPlacement = {0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoggl4"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Porter des lunettes assis 2 - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_sol_glasses',
            PropBone = 31086,
            PropPlacement = {0.0500, 0.0300, 0.000, -100.0000003, 90.00, 0.00},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdoghd1"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un hotdog - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_hotdog_01',
            PropBone = 31086,
            PropPlacement = {
                0.1300, -0.0250, 0.000, -88.272053, -9.8465858, -0.1488562
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoghd2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Tenir un hotdog assis - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_hotdog_01',
            PropBone = 31086,
            PropPlacement = {
                0.1300, -0.0250, 0.000, -88.272053, -9.8465858, -0.1488562
            },
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdoghlmt1"] = {
        "creatures@pug@move",
        "nill",
        "Porter un casque de moto - Petit Chien",
        AnimationOptions = {
            Prop = 'ba_prop_battle_sports_helmet',
            PropBone = 31086,
            PropPlacement = {0.00, -0.0200, 0.000, -90.00, 90.00, 0.00},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoghlmt2"] = {
        "creatures@pug@move",
        "nill",
        "Porter un casque de chantier - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_hard_hat_01',
            PropBone = 31086,
            PropPlacement = {0.00, 0.1300, 0.000, -90.00, 90.00, 0.00},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoghat"] = {
        "creatures@pug@move",
        "nill",
        "Porter un chapeau - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_proxy_hat_01',
            PropBone = 31086,
            PropPlacement = {
                0.0, 0.1200, 0.000, -99.8510766, 80.1489234, 1.7279411
            },
            SecondProp = 'prop_aviators_01',
            SecondPropBone = 31086,
            SecondPropPlacement = {0.0500, 0.0400, 0.000, -90.00, 90.00, 0.00},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdoghat2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Porter un chapeau assis - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_proxy_hat_01',
            PropBone = 31086,
            PropPlacement = {
                0.0, 0.1200, 0.000, -99.8510766, 80.1489234, 1.7279411
            },
            SecondProp = 'prop_aviators_01',
            SecondPropBone = 31086,
            SecondPropPlacement = {0.0500, 0.0400, 0.000, -90.00, 90.00, 0.00},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogsteak"] = {
        "creatures@pug@move",
        "nill",
        "Tenir un steak - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_steak',
            PropBone = 31086,
            PropPlacement = {0.1800, -0.0200, 0.000, 90.00, 0.00, 0.00},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogsteak2"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_c",
        "Tenir un steak assis - Petit Chien",
        AnimationOptions = {
            Prop = 'prop_cs_steak',
            PropBone = 31086,
            PropPlacement = {0.1800, -0.0200, 0.000, 90.00, 0.00, 0.00},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridea"] = {
        "creatures@pug@move",
        "nill",
        "Pride A (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag1',
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogprideb"] = {
        "creatures@pug@move",
        "nill",
        "Pride B - LGBTQIA (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag2', -- LGBTQIA
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogpridec"] = {
        "creatures@pug@move",
        "nill",
        "Pride C - Bisexuel (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag3', -- Bisexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogprided"] = {
        "creatures@pug@move",
        "nill",
        "Pride D - Lesbien (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag4', -- Lesbian
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogpridee"] = {
        "creatures@pug@move",
        "nill",
        "Pride E - Pansexuel (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag5', -- Pansexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogpridef"] = {
        "creatures@pug@move",
        "nill",
        "Pride F - Transgendre  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag6', -- Transgender
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogprideg"] = {
        "creatures@pug@move",
        "nill",
        "Pride G - Non Binaire (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag6', -- Non Binary
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogprideh"] = {
        "creatures@pug@move",
        "nill",
        "Pride H - Non Binaire (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag7', -- Non Binary
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogpridei"] = {
        "creatures@pug@move",
        "nill",
        "Pride I - Asexuel (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag8', -- Asexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sdogpridesita"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride A Assis (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag1',
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesitb"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride B Assis LGBTQIA  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag2', -- LGBTQIA
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesitc"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride C Assis Bisexuel  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag3', -- Bisexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesitd"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride D Assis Lesbienne (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag4', -- Lesbian
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesite"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride E Assis Pansexuel  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag5', -- Pansexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesitf"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride F Assis Transgendre   (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag6', -- Transgender
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesitg"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride G Assis Non Binaire (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag7', -- Non Binary
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesith"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride H Assis Asexuel  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag8',
            -- Asexual
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpridesiti"] = {
        "creatures@pug@amb@world_dog_sitting@idle_a",
        "idle_b",
        "Pride I Assis Hétéro  (Petit Chien)",
        AnimationOptions = {
            Prop = 'lilprideflag9', -- Straight Ally
            PropBone = 31086,
            PropPlacement = {0.1240, -0.0080, 0.000, 0.0, 0.0, -74.6999},
            EmoteLoop = true,
            ExitEmote = "sdogup",
            ExitEmoteType = "Exits"
        }
    },
    ["sdogpee"] = {
        "creatures@pug@move",
        "nill",
        "Faire pipi - Petit Chien",
        AnimationOptions = {
            EmoteLoop = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {-0.01, -0.17, 0.09, 0.0, 90.0, 140.0, 1.0},
            PtfxInfo = Animations.Languages['pee'],
            PtfxWait = 3000,
            PtfxCanHold = true
        }
    },
    ["sdogshit"] = {
        "creatures@pug@move",
        "nill",
        "Faire caca - Petit Chien",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_poo",
            PtfxNoProp = true,
            PtfxBone = 11816,
            PtfxPlacement = {-0.0330, 0.0210, -0.0040, 0.0, 0.0, 0.0, 0.4},
            PtfxInfo = Animations.Languages['poop'],
            PtfxWait = 2000,
            PtfxCanHold = true
        }
    },
    ["sdogfw"] = {
        "creatures@pug@move",
        "nill",
        "Feu d'artifice - Petit Chien",
        AnimationOptions = {
            Prop = 'ind_prop_firework_01', --- blue, green, red, purple pink, cyan, yellow, white
            PtfxColor = {{R = 255, G = 0, B = 0, A = 1.0}, {R = 0, G = 255, B = 0, A = 1.0}, {R = 0, G = 0, B = 255, A = 1.0}, {R = 177, G = 5, B = 245, A = 1.0}, {R = 251, G = 3, B = 255, A = 1.0}, {R = 2, G = 238, B = 250, A = 1.0}, {R = 252, G = 248, B = 0, A = 1.0}, {R = 245, G = 245, B = 245, A = 1.0}},
            PropBone = 31086,
            PropPlacement = {
                0.1330,
                -0.0210,
                -0.2760,
                0.0,
                -180.0,
                44.0000
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_indep_fireworks",
            PtfxName = "scr_indep_firework_trail_spawn",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.6
            },
            PtfxInfo = Animations.Languages['firework'],
            PtfxWait = 200
        }
    },
    ["sdogfris"] = {
        "creatures@pug@move",
        "nill",
        "Frisbee (Petit Chien)",
        AnimationOptions = {
            Prop = 'p_ld_frisbee_01',
            PropBone = 31086,
            PropPlacement = {
                0.1900,
                -0.0150,
                0.0000,
                -90.0000,
                120.0000,
                0.000,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["calldog"] = {
        "switch@franklin@plays_w_dog",
        "001916_01_fras_v2_9_plays_w_dog_idle",
        "Appeler son chien",
        AnimationOptions = {EmoteLoop = true}
    },
    ["calldogr"] = {
        "missfra0_chop_find",
        "call_chop_r",
        "Appeler son chien - Droite",
        AnimationOptions = {EmoteLoop = false}
    },
    ["calldogl"] = {
        "missfra0_chop_find",
        "call_chop_l",
        "Appeler son chien - Gauche",
        AnimationOptions = {EmoteLoop = false}
    },
}

--- EXIT EMOTES ---

RP.Exits = {
    label = "Sorties",
    icon = "🚪",

    ------ HUMAN EXIT EMOTES  ------

    ["getup"] = {
        "get_up@sat_on_floor@to_stand",
        "getup_0",
        "Se lever",
        AnimationOptions = {
            EmoteDuration = 2000,
            StartDelay = 600
        }
    },
    ["getup2"] = {
        "anim@scripted@aoa@ship_climb@male@",
        "getup_a",
        "Se lever 2",
        AnimationOptions = {
            StartDelay = 600
        }
    },
    ["meditateup"] = {
        "rcmcollect_paperleadinout@",
        "meditate_getup",
        "Se lever méditation",
        AnimationOptions = {
            EmoteDuration = 2000
        }
    },
    ["standup"] = {
        "get_up@directional@movement@from_knees@injured",
        "getup_l_0",
        "Se lever",
        AnimationOptions = {
            EmoteDuration = 2000,
            StartDelay = 600
        }
    },
    ["surrender_exit"] = {
        "random@arrests",
        "kneeling_arrest_get_up",
        "Se lever Genou",
        AnimationOptions = {
            EmoteDuration = 2200
        }
    },
    ["offchair"] = {
        "switch@michael@sitting",
        "exit_forward",
        "Se lever Chaise",
        AnimationOptions = {
            EmoteDuration = 1000
        }
    },
    ["phoneaway"] = {
        "amb@world_human_stand_mobile@male@text@exit",
        "exit",
        "Sortir",
        AnimationOptions = {
            EmoteDuration = 1780,
            StartDelay = 1150,
            EmoteMoving = true
        }
    },
    ------ ANIMAL EXIT EMOTES  ------
    ["sdogup"] = {
        "creatures@pug@amb@world_dog_sitting@exit",
        "exit",
        "Petit Chien Se lever",
        AnimationOptions = {
            EmoteDuration = 1000
        }
    },
    ["bdogup"] = {
        "creatures@rottweiler@amb@world_dog_sitting@exit",
        "exit",
        "gros chien Se lever",
        AnimationOptions = {
            EmoteDuration = 1000
        }
    },
    ["bdogupk"] = {
        "creatures@rottweiler@amb@sleep_in_kennel@",
        "exit_kennel",
        "gros chien Se lever V2",
        AnimationOptions = {
            EmoteDuration = 5000
        }
    }
}

--- EMOTES NO PROPS ---

RP.Emotes = {
    label = "Emotes",
    icon = "😄",
    -----------------------------------------------------------------------------------------------------------
    ------ The male and female 'interaction menu' emotes from GTA Online can be found under the following animation directories:
    ------
    ------ Male: anim@mp_player_intcelebrationmale
    ------
    ------ Female: anim@mp_player_intcelebrationfemale

    -----------------------------------------------------------------------------------------------------------
    ------ THESE ARE SCENARIOS, SOME OF THESE DON'T WORK ON WOMEN AND SOME OTHER ISSUES, BUT STILL GOOD TO HAVE    ------
    -----------------------------------------------------------------------------------------------------------
    ["atm"] = {
        "Scenario",
        "PROP_HUMAN_ATM",
        "ATM"
    },
    ["bbq"] = {
        "MaleScenario",
        "PROP_HUMAN_BBQ",
        "BBQ"
    },
    ["bumbin"] = {
        "Scenario",
        "PROP_HUMAN_BUM_BIN",
        "Poubelle à flèche"
    },
    ["cop"] = {
        "Scenario",
        "WORLD_HUMAN_COP_IDLES",
        "Policier"
    },
    ["flex"] = {
        "Scenario",
        "WORLD_HUMAN_MUSCLE_FLEX",
        "Flex"
    },
    ["guard"] = {
        "Scenario",
        "WORLD_HUMAN_GUARD_STAND",
        "Garde"
    },
    ["hangout"] = {
        "Scenario",
        "WORLD_HUMAN_HANG_OUT_STREET",
        "Traîner"
    },
    ["impatient"] = {
        "Scenario",
        "WORLD_HUMAN_STAND_IMPATIENT",
        "Impatient"
    },
    ["janitor"] = {
        "Scenario",
        "WORLD_HUMAN_JANITOR",
        "Concierge"
    },
    ["jog"] = {
        "Scenario",
        "WORLD_HUMAN_JOG_STANDING",
        "Jogging"
    },
    ["kneel"] = {
        "Scenario",
        "CODE_HUMAN_MEDIC_KNEEL",
        "S'agenouiller"
    },
    ["lean"] = {
        "Scenario",
        "WORLD_HUMAN_LEANING",
        "Pencher"
    },
    ["leanbar"] = {
        "Scenario",
        "PROP_HUMAN_BUM_SHOPPING_CART",
        "Pencher Bar"
    },
    ["lookout"] = {
        "Scenario",
        "CODE_HUMAN_CROSS_ROAD_WAIT",
        "Surveiller"
    },
    ["maid"] = {
        "Scenario",
        "WORLD_HUMAN_MAID_CLEAN",
        "Femme de ménage"
    },
    ["musician"] = {
        "MaleScenario",
        "WORLD_HUMAN_MUSICIAN",
        "Musicien"
    },
    -- Ambient Music Doesn't Seem To Work For Female, Hence It's Male Only
    ["notepad2"] = {
        "Scenario",
        "CODE_HUMAN_MEDIC_TIME_OF_DEATH",
        "Bloc-note 2"
    },
    ["parkingmeter"] = {
        "Scenario",
        "PROP_HUMAN_PARKING_METER",
        "Parcmètre"
    },
    ["party"] = {
        "Scenario",
        "WORLD_HUMAN_PARTYING",
        "Fête"
    },
    ["texting"] = {
        "Scenario",
        "WORLD_HUMAN_STAND_MOBILE",
        "Envoyer Message"
    },
    ["prosthigh"] = {
        "Scenario",
        "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS",
        "Prostituer Classe"
    },
    ["prostlow"] = {
        "Scenario",
        "WORLD_HUMAN_PROSTITUTE_LOW_CLASS",
        "Prostituer Bas de Gamme"
    },
    ["puddle"] = {
        "Scenario",
        "WORLD_HUMAN_BUM_WASH",
        "Flaque d'eau"
    },
    ["record"] = {
        "Scenario",
        "WORLD_HUMAN_MOBILE_FILM_SHOCKING",
        "Enregistrer"
    },
    ["smoke"] = {
        "Scenario",
        "WORLD_HUMAN_SMOKING",
        "Fumer"
    },
    ["smokeweed"] = {
        "MaleScenario",
        "WORLD_HUMAN_DRUG_DEALER",
        "Fumer Weed (Homme)"
    },
    -- Female
    ["smokeweed2"] = {
        "Scenario",
        "WORLD_HUMAN_SMOKING_POT",
        "Fumer Weed (Femme)"
    },
    -- Female
    ["statue"] = {
        "Scenario",
        "WORLD_HUMAN_HUMAN_STATUE",
        "Statue"
    },

    ---------- END OF SCENARIOS --------------

    ["annoyed"] = {
        "missdocksshowoffcar@idle_a",
        "idle_b_5",
        "Mécontent",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["dispenser"] = {
        "mini@sprunk",
        "plyr_buy_drink_pt1",
        "Distributeur",
        AnimationOptions =
        {
            EmoteLoop = false
        }
    },
    ["cuffedfront"] = {
        "anim@move_m@prisoner_cuffed",
        "idle",
        "Menotté - Devant",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            ExitEmote = "breakfreefont",
            ExitEmoteType = "Exits"
        }
    },
    ["cuffedback"] = {
        "mp_arresting",
        "idle",
        "Menotté - Dos",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            ExitEmote = "breakfreeback",
            ExitEmoteType = "Exits"
        }
    },
    ["dazzle1"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose1_clip",
        "Pose Fascinante 1",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dazzle2"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose2_clip",
        "Pose Fascinante 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dazzle3"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose3_clip",
        "Pose Fascinante 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dazzle4"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose4_clip",
        "Pose Fascinante 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dazzle5"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose5_clip",
        "Pose Fascinante 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dazzle6"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose6_clip",
        "Pose Fascinante 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dazzle7"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@dazzleme",
        "pose7_clip",
        "Pose Fascinante 7",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["dead2"] = {
        "anim@scripted@data_leak@fixf_fin_ig2_johnnyguns_wounded@",
        "enter",
        "Juer le mort",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["femalestandcute"] = {
        "stand_cute_6@dark",
        "stand_cute_6_clip",
        "Pose mignonne Femme debout",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femalestandcute1"] = {
        "stand_fem_1@darksj",
        "stand_fem_1_clip",
        "Pose mignonne Femme debout 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femalestandcute2"] = {
        "feet_stand_w@darksj",
        "feet_stand_w_clip",
        "Pose mignonne Femme debout 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femalestandcute3"] = {
        "anim@female_model_14",
        "f_model_14_clip",
        "Pose mignonne Femme debout 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femalestandcutefinger"] = {
        "anim@female_model_15",
        "f_model_15_clip",
        "Pose mignonne Femme debout Doigt",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femalestandcute4"] = {
        "anim@female_model_17",
        "f_model_17_clip",
        "Pose mignonne Femme debout 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["malestandpose"] = {
        "anim@male_model_11",
        "m_model_11_clip",
        "Pose debout Homme",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femalesitcute"] = {
        "sit_cute_1@dark",
        "sit_cute_1_clip",
        "Femme assis mignonne",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["femalesitcute1"] = {
        "mrwitt@chin_support_on_floor",
        "mrwitt",
        "Femme assis mignonne 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["femalesitcute2"] = {
        "beach_1@janina234",
        "beach_1_clip",
        "Femme assis mignonne 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["femaleonknees"] = {
        "beach_4@janina234",
        "beach_4_clip",
        "Pose Femme à genoux",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["femaleonknees1"] = {
        "on_the_knees@darksj",
        "on_the_knees_clip",
        "Pose Femme à genoux 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["femaleonknees2"] = {
        "anim@female_model_21",
        "f_model_21_clip",
        "Pose Femme à genoux 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["fashionpose1"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "chic",
        "Pose Fashion 1",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose2"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "deathdrop",
        "Pose Fashion 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["fashionpose3"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "magica",
        "Pose Fashion 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose4"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "pose5",
        "Pose Fashion 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose5"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "pose8",
        "Pose Fashion 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose6"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "pose20",
        "Pose Fashion 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose7"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "pose28",
        "Pose Fashion 7",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose8"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "runoutofposes",
        "Pose Fashion 8",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["fashionpose9"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyxco@dresstoimpress",
        "split",
        "Pose Fashion 9",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["beast"] = {
        "anim@mp_fm_event@intro",
        "beast_transform",
        "Bête",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 5000
        }
    },
    ["chill"] = {
        "switch@trevor@scares_tramp",
        "trev_scares_tramp_idle_tramp",
        "Tranquille",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 200,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["cloudgaze"] = {
        "switch@trevor@annoys_sunbathers",
        "trev_annoys_sunbathers_loop_girl",
        "Allongé Regard Nuage",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["cloudgaze2"] = {
        "switch@trevor@annoys_sunbathers",
        "trev_annoys_sunbathers_loop_guy",
        "Allongé Regard Nuage 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["crouchreach"] = {
        "anim@veh@van@mule5@rds",
        "lean_back_idle",
        "Accroupir et tendre la main",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
        }
    },
    ["crouchreach2"] = {
        "anim@scripted@npc@mission@pln_ig4_cargo@",
        "line_5_dax",
        "Accroupir et tendre la main 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
        }
    },
    ["daydream"] = { -- Custom Emote By Darks Animations
        "girl_groupe_d@darksj",
        "girl_groupe_d_clip",
        "Rêverie dans les nuages",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["khands"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_heart000",
        "ebrwny_hrt000",
        "Coeur Main Coréen 🇰🇷",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["uwu2"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_pack000",
        "ebrwny_shy",
        "UwU 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["rawr"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_pack000",
        "ebrwny_rawr",
        "Brut",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stop"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_pack000",
        "ebrwny_stop",
        "Stop",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sassy"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_pack000",
        "ebrwny_sass",
        "Insolent",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sitsad3"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_pack000",
        "ebrwny_sitf000",
        "Assis Triste 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitsad4"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_pack000",
        "ebrwny_sitf001",
        "Assis Triste 4",
        AnimationOptions = {
            StartDelay = 600,
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["bend"] = {
        "ebrwny_pack000",
        "ebrwny_bend",
        "Se pencher",
        AnimationOptions = {
            StartDelay = 600,
            EmoteLoop = true,
            EmoteMoving = true,
            NotInVehicle = true
        }
    },
    ["prone"] = {
        "missfbi3_sniping",
        "prone_dave",
        "A plat ventre",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["pullover"] = {
        "misscarsteal3pullover",
        "pull_over_right",
        "Arrêtez-vous",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1300
        }
    },
    ["idle12"] = {
        "mp_corona_idles@female_b@base",
        "base",
        "Au repos 12",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle13"] = {
        "mp_corona_idles@female_c@base",
        "base",
        "Au repos 13",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle14"] = {
        "random@countrysiderobbery",
        "idle_a",
        "Au repos 14",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle15"] = {
        "anim_heist@arcade_combined@",
        "female_hold_arm@_base_base",
        "Au repos 15",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle16"] = {
        "anim_heist@arcade_combined@",
        "ped_female@_stand@_02a@_base_base",
        "Au repos 16",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle17"] = {
        "anim_heist@arcade_combined@",
        "amb_world_human_hang_out_street_female_hold_arm_idle_b",
        "Au repos 17",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle18"] = {
        "mp_move@prostitute@m@hooker",
        "idle",
        "Au repos 18",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["idle19"] = {
        "missdocksshowoffcar@base",
        "base_4",
        "Au repos 19",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["impatient2"] = {
        "oddjobs@taxi@gyn@cc@intro",
        "f_impatient_b",
        "Impatient 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["airguitar"] = {
        "anim@mp_player_intcelebrationfemale@air_guitar",
        "air_guitar",
        "Guitare imaginaire"
    },
    ["airsynth"] = {
        "anim@mp_player_intcelebrationfemale@air_synth",
        "air_synth",
        "Air Synthé"
    },
    ["argue"] = {
        "misscarsteal4@actor",
        "actor_berating_loop",
        "Argumenter",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["argue2"] = {
        "oddjobs@assassinate@vice@hooker",
        "argue_a",
        "Argumenter 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["argue3"] = {
        "missheistdockssetup1leadinoutig_1",
        "lsdh_ig_1_argue_wade",
        "Argumenter 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["argue4"] = {
        "car_2_mcs_1-6",
        "cs_devin_dual-6",
        "Argumenter 4",
        AnimationOptions = {
            EmoteDuration = 6000,
            EmoteMoving = true
        }
    },
    ["argue5"] = {
        "anim@amb@casino@brawl@fights@argue@",
        "arguement_loop_mp_m_brawler_01",
        "Argumenter Angry 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["argue6"] = {
        "anim@amb@casino@brawl@fights@argue@",
        "arguement_loop_mp_m_brawler_02",
        "Argumenter Angry 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bartender"] = {
        "anim@amb@clubhouse@bar@drink@idle_a",
        "idle_a_bartender",
        "Barman",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["blowkiss"] = {
        "anim@mp_player_intcelebrationfemale@blow_kiss",
        "blow_kiss",
        "Souffler un baiser"
    },
    ["blowkiss2"] = {
        "anim@mp_player_intselfieblow_kiss",
        "exit",
        "Souffler un baiser 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["curtsy"] = {
        "anim@mp_player_intcelebrationpaired@f_f_sarcastic",
        "sarcastic_left",
        "Respect"
    },
    ["bringiton"] = {
        "misscommon@response",
        "bring_it_on",
        "Confiance",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3000
        }
    },
    ["comeatmebro"] = {
        "mini@triathlon",
        "want_some_of_this",
        "Viens ici frérot",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["cop2"] = {
        "anim@amb@nightclub@peds@",
        "rcmme_amanda1_stand_loop_cop",
        "Flic 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["cop3"] = {
        "amb@code_human_police_investigate@idle_a",
        "idle_b",
        "Flic 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["crossarms"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
        "idle_a",
        "Bras Croisés",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms2"] = {
        "amb@world_human_hang_out_street@male_c@idle_a",
        "idle_b",
        "Bras Croisés 2",
        AnimationOptions = {
            EmoteMoving = true
        }
    },
    ["crossarms3"] = {
        "anim@heists@heist_corona@single_team",
        "single_team_loop_boss",
        "Bras Croisés 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms4"] = {
        "random@street_race",
        "_car_b_lookout",
        "Bras Croisés 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms5"] = {
        "anim@amb@nightclub@peds@",
        "rcmme_amanda1_stand_loop_cop",
        "Bras Croisés 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms6"] = {
        "random@shop_gunstore",
        "_idle",
        "Bras Croisés 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms7"] = {
        "anim_heist@arcade_combined@",
        "female_arms_crossed@_base_base",
        "Bras Croisés 7",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms8"] = {
        "anim_heist@arcade_combined@",
        "ped_female@_stand@_03b@_base_base",
        "Bras Croisés 8",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarms9"] = {
        "fix_trip3_ext-4",
        "a_f_y_vinewood_02_dual-4",
        "Bras Croisés 9",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["foldarms"] = {
        "anim@amb@business@bgen@bgen_no_work@",
        "stand_phone_phoneputdown_idle_nowork",
        "Croiser les bras",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foldarms2"] = {
        "anim@amb@nightclub@peds@",
        "rcmme_amanda1_stand_loop_cop",
        "Croiser les bras 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarmsside"] = {
        "rcmnigel1a_band_groupies",
        "base_m2",
        "Croiser les bras Côté",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["crossarmsside2"] = {
        "amb@world_human_hang_out_street@female_hold_arm@base",
        "base",
        "Croiser les bras Côté",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["damn"] = {
        "gestures@m@standing@casual",
        "gesture_damn",
        "Frustré",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["damn2"] = {
        "anim@am_hold_up@male",
        "shoplift_mid",
        "Frustré 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["pointdown"] = {
        "gestures@f@standing@casual",
        "gesture_hand_down",
        "Diriger son doigt",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["pointpose"] = {
        "tun_meet_int-47",
        "a_m_y_carclub_01^3_dual-47",
        "Diriger son doigt 2",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["surrender3"] = {
        "mp_bank_heist_1",
        "m_cower_01",
        "Se rendre 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender4"] = {
        "mp_bank_heist_1",
        "m_cower_02",
        "Se rendre 4",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender5"] = {
        "random@arrests",
        "kneeling_arrest_idle",
        "Se rendre 5",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "surrender_exit",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender6"] = {
        "rcmbarry",
        "m_cower_01",
        "Se rendre 6",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender7"] = {
        "anim@scripted@bty4@ig2_bounty_kneel@male@",
        "on_knee_idle_a",
        "Se rendre 7",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["facepalm3"] = {
        "missminuteman_1ig_2",
        "tasered_2",
        "Main sur le visage 3",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 8000
        }
    },
    ["facepalm4"] = {
        "anim@mp_player_intupperface_palm",
        "idle_a",
        "Main sur le visage 4",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["fallover2"] = {
        "mp_suicide",
        "pistol",
        "Suicide Pistolet 2"
    },
    ["fallover3"] = {
        "mp_suicide",
        "pill",
        "Suicide Pillule 3"
    },
    ["fallover4"] = {
        "friends@frf@ig_2",
        "knockout_plyr",
        "Tomber 4"
    },
    ["fallover5"] = {
        "anim@gangops@hostage@",
        "victim_fail",
        "Tomber 5"
    },
    ["fallasleep2"] = {
        "mp_sleep",
        "sleep_loopfemale",
        "S'endormir 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["fightme"] = {
        "anim@deathmatch_intros@unarmed",
        "intro_male_unarmed_c",
        "Viens te battre"
    },
    ["fightme2"] = {
        "anim@deathmatch_intros@unarmed",
        "intro_male_unarmed_e",
        "Viens te battre 2"
    },
    ["finger"] = {
        "anim@mp_player_intselfiethe_bird",
        "idle_a",
        "Doigts d'honneur",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["finger2"] = {
        "anim@mp_player_intupperfinger",
        "idle_a_fp",
        "Doigts d'honneur 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wait9"] = {
        "rcmjosh2",
        "josh_2_intp1_base",
        "Attente 9",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wallet"] = {
        "cop_badge_1@dad",
        "cop_badge_1_clip",
        "Montrer le portefeuille",
        AnimationOptions = {
            Prop = 'prop_ld_wallet_01',
            PropBone = 28422,
            PropPlacement = {0.15, 0.02, -0.02, -90.0, 0.0, 0.0},
            EmoteLoop = false,
            EmoteMoving = false
        }
    },
    ["hiking"] = {
        "move_m@hiking",
        "idle",
        "Randonnée",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["hugme"] = {
        "mp_ped_interaction",
        "kisses_guy_a",
        "Prends-moi dans tes bras"
    },
    ["hugme2"] = {
        "mp_ped_interaction",
        "kisses_guy_b",
        "Prends-moi dans tes bras 2"
    },
    ["inspect"] = {
        "random@train_tracks",
        "idle_e",
        "Inspecter"
    },
    ["inspect2"] = {
        "anim@amb@carmeet@checkout_engine@",
        "female_c_idle_d",
        "Inspecter 2"
    },
    ["inspect3"] = {
        "anim@amb@carmeet@checkout_car@",
        "female_b_idle_d",
        "Inspecter 3"
    },
    ["jazzhands"] = {
        "anim@mp_player_intcelebrationfemale@jazz_hands",
        "jazz_hands",
        "Ouvrir les bras",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 6000
        }
    },
    ["jog2"] = {
        "amb@world_human_jog_standing@male@idle_a",
        "idle_a",
        "Jogging 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["jog3"] = {
        "amb@world_human_jog_standing@female@idle_a",
        "idle_a",
        "Jogging 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["jog4"] = {
        "amb@world_human_power_walker@female@idle_a",
        "idle_a",
        "Jogging 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["jog5"] = {
        "move_m@joy@a",
        "walk",
        "Jogging 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["jumpingjacks"] = {
        "timetable@reunited@ig_2",
        "jimmy_getknocked",
        "Jumping Jacks",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kneel4"] = {
        "anim@scripted@cbr5@ig3_drill_box@pattern_03@lockbox_03@male@",
        "rest",
        "A genoux 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kneel5"] = {
        "anim@scripted@cbr5@ig3_drill_box@pattern_01@lockbox_02@male@",
        "rest",
        "A genoux 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kneelhide"] = {
        "anim@scripted@bty2@ig1_hiding_target@male@",
        "hiding_kneel",
        "A genoux Dissimulé",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kneelthot"] = {
        "anim@model_kylie_insta",
        "kylie_insta_clip",
        "A genoux Instapic",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 200,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["kneelbored"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@duo17",
        "duo17_clip",
        "Pose de l'ennui à genoux",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 200,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["kneelpeace"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@duo18",
        "duo18_clip",
        "Pose signe de la paix à genoux",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 200,
            ExitEmote = "standup",
            ExitEmoteType = "Exits"
        }
    },
    ["shoepose"] = { -- Custom Emote By Darks Animations
        "male_duo_a@darksj",
        "male_duo_a_clip",
        "Pose coup de pied",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 240
        }
    },
    ["rap"] = { -- Custom Emote By Darks Animations
        "couple_singing_m@darks37",
        "couple_singing_m_clip",
        "Rap / Chanter",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["squatgunpose"] = { -- Custom Emote By Darks Animations
        "ganggirls_pose1@darks37",
        "ganggirls_pose1_clip",
        "Squat Pose pistolet - Gauche",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["squatgunpose3"] = { -- Custom Emote By Darks Animations
        "gun_prime_2@darksj",
        "gun_prime_2_clip",
        "Squat Pose pistolet 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["knock"] = {
        "timetable@jimmy@doorknock@",
        "knockdoor_idle",
        "Toquer",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["knock2"] = {
        "missheistfbi3b_ig7",
        "lift_fibagent_loop",
        "Toquer 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["knucklecrunch"] = {
        "anim@mp_player_intcelebrationfemale@knuckle_crunch",
        "knuckle_crunch",
        "Craquer les doigts",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lean4"] = {
        "amb@world_human_leaning@male@wall@back@foot_up@idle_a",
        "idle_a",
        "Penché 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lean5"] = {
        "amb@world_human_leaning@male@wall@back@hands_together@idle_b",
        "idle_e",
        "Penché 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lean6"] = {
        "anim@scripted@freemode_npc@fix_agy_ig4_lamar@",
        "lean_wall_idle_03_lamar",
        "Penché 6",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["leanflirt"] = {
        "random@street_race",
        "_car_a_flirt_girl",
        "Penché Flirt",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["leanbar2"] = {
        "amb@prop_human_bum_shopping_cart@male@idle_a",
        "idle_c",
        "Penché Bar 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["leanbar3"] = {
        "anim@amb@nightclub@lazlow@ig1_vip@",
        "clubvip_base_laz",
        "Penché Bar 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["leanbar4"] = {
        "anim@heists@prison_heist",
        "ped_b_loop_a",
        "Penché Bar 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["leanhigh"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_one",
        "Penché haut",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leanhigh2"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Penché haut 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leanside"] = {
        "timetable@mime@01_gc",
        "idle_a",
        "Penché sur le côté",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leanside2"] = {
        "misscarstealfinale",
        "packer_idle_1_trevor",
        "Penché sur le côté 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leanside3"] = {
        "misscarstealfinalecar_5_ig_1",
        "waitloop_lamar",
        "Penché sur le côté 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leanside4"] = {
        "misscarstealfinalecar_5_ig_1",
        "waitloop_lamar",
        "Penché sur le côté 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["leanside5"] = {
        "rcmjosh2",
        "josh_2_intp1_base",
        "Penché sur le côté 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["leanplan"] = {
        "anim@amb@board_room@diagram_blueprints@",
        "idle_01_amy_skater_01",
        "Penché sur la table",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 200,
            ExitEmote = "offtable",
            ExitEmoteType = "Exits"
        }
    },
    ["me"] = {
        "gestures@f@standing@casual",
        "gesture_me_hard",
        "Moi",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["mechanic"] = {
        "mini@repair",
        "fixing_a_ped",
        "Mechanique",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["mechanic2"] = {
        "mini@repair",
        "fixing_a_player",
        "Mechanique 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["mechanic3"] = {
        "amb@world_human_vehicle_mechanic@male@base",
        "base",
        "Mechanique 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["mechanic4"] = {
        "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        "machinic_loop_mechandplayer",
        "Mechanique 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["mechanic5"] = {
        "amb@prop_human_movie_bulb@idle_a",
        "idle_b",
        "Mechanique 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["meditate"] = {
        "rcmcollect_paperleadinout@",
        "meditiate_idle",
        "Mediter",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 300,
            ExitEmote = "meditateup",
            ExitEmoteType = "Exits"
        }
    },
    ["meditate2"] = {
        "rcmepsilonism3",
        "ep_3_rcm_marnie_meditating",
        "Mediter 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 300,
            ExitEmote = "meditateup",
            ExitEmoteType = "Exits"
        }
    },
    ["meditate3"] = {
        "rcmepsilonism3",
        "base_loop",
        "Mediter 3",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 300,
            ExitEmote = "meditateup",
            ExitEmoteType = "Exits"
        }
    },
    ["metal"] = {
        "anim@mp_player_intincarrockstd@ps@",
        "idle_a",
        "Métal",
        AnimationOptions = {
            -- CHANGE ME
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["no"] = {
        "anim@heists@ornate_bank@chat_manager",
        "fail",
        "Non",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 4000
        }
    },
    ["no2"] = {
        "mp_player_int_upper_nod",
        "mp_player_int_nod_no",
        "Non 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["nosepick"] = {
        "anim@mp_player_intcelebrationfemale@nose_pick",
        "nose_pick",
        "Curer le nez",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["noway"] = {
        "gestures@m@standing@casual",
        "gesture_no_way",
        "Impossible!",
        AnimationOptions = {
            EmoteDuration = 1500,
            EmoteMoving = true
        }
    },
    ["ok"] = {
        "anim@mp_player_intselfiedock",
        "idle_a",
        "OK",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dock"] = {
        "anim@mp_player_intincardockstd@rds@",
        "idle_a",
        "Dock",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["outofbreath"] = {
        "re@construction",
        "out_of_breath",
        "Plus d'air",
    },
    ["push"] = {
        "missfinale_c2ig_11",
        "pushcar_offcliff_f",
        "Pousser",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["push2"] = {
        "missfinale_c2ig_11",
        "pushcar_offcliff_m",
        "Pousser 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["countdown"] = {
        "random@street_race",
        "grid_girl_race_start",
        "Compter",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pointright"] = {
        "mp_gun_shop_tut",
        "indicate_right",
        "Montrer une direction",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["scared3"] = {
        "xm3_drg2_cook_int-5",
        "csb_labrat_dual-5",
        "Avoir peur 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["screwyou"] = {
        "misscommon@response",
        "screw_you",
        "En colère",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shakeoff"] = {
        "move_m@_idles@shake_off",
        "shakeoff_1",
        "Secouer",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3500
        }
    },
    ["shot"] = {
        "random@dealgonewrong",
        "idle_a",
        "Tirer",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit10"] = {
        "anim@scripted@bty2@ig1_hiding_target@male@",
        "hiding_sit",
        "S'assoier 10",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitfu"] = {
        "chocoholic@single80",
        "single80_clip",
        "S'assoier Doigt d'honneur",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["welcomeback"] = {
        "anim@scripted@island@special_peds@dave@hs4_dave_stage2_ig6",
        "you're_back",
        "Bienvenue",
        AnimationOptions = {
            EmoteLoop = false,
        }
    },
    ["wallpose"] = { -- Credit to LadyyShamrockk for this custom emote
        "shamrock@wallpose1",
        "pose",
        "Pose Mur",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["wallpose2"] = { -- Credit to LadyyShamrockk for this custom emote
        "shamrock@wallpose2",
        "pose",
        "Pose Mur 2",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["wallpose3"] = { -- Credit to LadyyShamrockk for this custom emote
        "shamrock@wallpose3",
        "pose",
        "Pose Mur 3",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["wallpose4"] = { -- Credit to LadyyShamrockk for this custom emote
        "shamrock@wallpose4",
        "pose",
        "Pose Mur 4",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["wallpose5"] = { -- Credit to LadyyShamrockk for this custom emote
        "shamrock@wallpose5",
        "pose",
        "Pose Mur 5",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["elbow"] = {
        "anim@veh@lowrider@std@ds@arm@base",
        "sit_low_lowdoor",
        "Bras fenêtre",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["elbow2"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@single47",
        "single47_clip",
        "Bras fenêtre 2",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteLoop = true
        }
    },
    ["sitlean"] = {
        "timetable@tracy@ig_14@",
        "ig_14_base_tracy",
        "S'assoier penché",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitlean2"] = {
        "anim@scripted@player@fix_astu_ig8_weed_smoke_v1@male@",
        "male_pos_a_p2_base",
        "S'assoier penché 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitlean3"] = {
        "anim@scripted@freemode@ig7_office_cell_floor@heeled@",
        "base_pose_01",
        "S'assoier penché 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitsad"] = {
        "anim@amb@business@bgen@bgen_no_work@",
        "sit_phone_phoneputdown_sleeping-noworkfemale",
        "S'assoier triste",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitsad2"] = {
        "anim@female_sit_01",
        "f_sit_01_clip",
        "S'assoier triste 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitscared"] = {
        "anim@heists@ornate_bank@hostages@hit",
        "hit_loop_ped_b",
        "S'assoier Peur",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            NotInVehicle = true
        }
    },
    ["sitscared2"] = {
        "anim@heists@ornate_bank@hostages@ped_c@",
        "flinch_loop",
        "S'assoier Peur 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            NotInVehicle = true
        }
    },
    ["sitscared3"] = {
        "anim@heists@ornate_bank@hostages@ped_e@",
        "flinch_loop",
        "S'assoier Peur 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            NotInVehicle = true
        }
    },
    ["sitdrunk"] = {
        "timetable@amanda@drunk@base",
        "base",
        "S'assoier Bourré",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair"] = {
        "timetable@ron@ig_3_couch",
        "base",
        "S'assoier chaise",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair2"] = {
        "timetable@ron@ig_5_p3",
        "ig_5_p3_base",
        "S'assoier chaise 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair3"] = {
        "timetable@reunited@ig_10",
        "base_amanda",
        "S'assoier chaise 3 (Female)",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair4"] = {
        "timetable@ron@ron_ig_2_alt1",
        "ig_2_alt1_base",
        "S'assoier chaise 4 - Côté",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair5"] = {
        "timetable@jimmy@mics3_ig_15@",
        "mics3_15_base_tracy",
        "S'assoier Chaise Jambes Croisées",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair6"] = {
        "timetable@maid@couch@",
        "base",
        "S'assoier Chaise Penché Arrière",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair7"] = {
        "anim@scripted@freemode_npc@fix_astu_ig3_pooh_jimmy@jimmy@",
        "sit_base_jimmy",
        "S'assoier Chaise Attentif",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair8"] = {
        "anim@scripted@freemode_npc@fix_dre_studio_entourage@",
        "lonely_ballas",
        "S'assoier Chaise Chaise",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sittoilet"] = {
        "anim@scripted@freemode@ig5_office_cell_seat@heeled@",
        "base_pose_01",
        "S'assoier Toilette",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sittoilet2"] = {
        "anim@scripted@cbr5@ig3_drill_box@pattern_01@lockbox_04@male@",
        "idle",
        "S'assoier Toilette 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitcute"] = { -- Custom Emote By QueenSistersAnimations
        "sitkylie@queensisters",
        "kylie_clip",
        "Assis mignon",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["smokengun"] = {
        "smokingweapon@animation",
        "smokingweapon_clip",
        "S'assoier - Fumer & Pistolet",
        AnimationOptions = {
            Prop = "ng_proc_cigarette01a",
            PropBone = 4185,
            PropPlacement = {
                0.0300,
                0.0000,
                0.0200,
                1.7096,
                -43.1362,
                -27.9428
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ['smokendrink'] = { -- Custom Emote By Darks Animations
        "drx@male_smoke",
        "male_smoke",
        "Fumer & Whisky",
        AnimationOptions = {
            Prop = 'prop_drink_whisky',
            PropBone = 26612,
            PropPlacement = {
                0.0500,
                -0.0700,
                -0.0500,
                0.0,
                0.0,
                0.0
            },
            SecondProp = 'ng_proc_cigarette01a',
            SecondPropBone = 64113,
            SecondPropPlacement = {
                0.0270,
                0.0080,
                0.0050,
                -11.6920,
                -78.3079,
                7.9470
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["clapangry"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "angry_clap_a_player_a",
        "Applaudir Enervé",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["slowclap3"] = {
        "anim@mp_player_intupperslow_clap",
        "idle_a",
        "Applaudir Doucement 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["clap"] = {
        "amb@world_human_cheering@male_a",
        "base",
        "Applaudir",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["slowclap"] = {
        "anim@mp_player_intcelebrationfemale@slow_clap",
        "slow_clap",
        "Applaudir Doucement",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["slowclap2"] = {
        "anim@mp_player_intcelebrationmale@slow_clap",
        "slow_clap",
        "Applaudir Doucement 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["smell"] = {
        "move_p_m_two_idles@generic",
        "fidget_sniff_fingers",
        "Sentir",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stickup"] = {
        "random@countryside_gang_fight",
        "biker_02_stickup_loop",
        "Voler",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stumble"] = {
        "misscarsteal4@actor",
        "stumble",
        "Trébucher",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["stunned"] = {
        "stungun@standing",
        "damage",
        "Étourdi",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["sunbathe"] = {
        "amb@world_human_sunbathe@male@back@base",
        "base",
        "Bain de soleil - Main sur la tête",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sunbathe2"] = {
        "amb@world_human_sunbathe@female@back@base",
        "base",
        "Bain de soleil 2- Main sur la tête",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sunbathe3"] = {
        "amb@world_human_sunbathe@female@front@base",
        "base",
        "Bain de soleil 3- Main sur le ventre",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["tpose"] = {
        "missfam5_yoga",
        "a2_pose",
        "T Pose",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tpose2"] = {
        "mp_sleep",
        "bind_pose_180",
        "T Pose 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["think5"] = {
        "mp_cp_welcome_tutthink",
        "b_think",
        "Penser 5",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["think3"] = {
        "timetable@tracy@ig_8@base",
        "base",
        "Penser 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["thumbsup3"] = {
        "anim@mp_player_intincarthumbs_uplow@ds@",
        "enter",
        "Féliciter 3",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3000
        }
    },
    ["type"] = {
        "anim@heists@prison_heiststation@cop_reactions",
        "cop_b_idle",
        "Tapotter Clavier",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["type2"] = {
        "anim@heists@prison_heistig1_p1_guard_checks_bus",
        "loop",
        "Tapotter Clavier 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["type3"] = {
        "mp_prison_break",
        "hack_loop",
        "Tapotter Clavier 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["type4"] = {
        "mp_fbi_heist",
        "loop",
        "Tapotter Clavier 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["type5"] = {
        "anim@scripted@freemode@ig12_use_computer@male@",
        "loop",
        "Tapotter Clavier 5 - Regard",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["wave5"] = {
        "friends@frj@ig_1",
        "wave_b",
        "Signe main 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wave6"] = {
        "friends@frj@ig_1",
        "wave_c",
        "Signe main 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wave7"] = {
        "friends@frj@ig_1",
        "wave_d",
        "Signe main 7",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wave8"] = {
        "friends@frj@ig_1",
        "wave_e",
        "Signe main 8",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wave9"] = {
        "gestures@m@standing@casual",
        "gesture_hello",
        "Signe main 9",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["whistle"] = {
        "taxi_hail",
        "hail_taxi",
        "Siffler",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1300
        }
    },
    ["whistle2"] = {
        "rcmnigel1c",
        "hailing_whistle_waive_a",
        "Siffler 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["yeah"] = {
        "anim@mp_player_intupperair_shagging",
        "idle_a",
        "Oue",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["yeah2"] = {
        "sum24_office_int-37",
        "csb_jenettee_dual-37",
        "Oue Oue",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = false
        }
    },
    ["lift"] = {
        "random@hitch_lift",
        "idle_f",
        "Ascenseur",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lol"] = {
        "anim@arena@celeb@flat@paired@no_props@",
        "laugh_a_player_b",
        "MDR",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lol2"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "giggle_a_player_b",
        "MDR 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lostconfused"] = {
        "anim@scripted@island@special_peds@dave@hs4_dave_stage2_ig6",
        "i_lost_it",
        "Perdu & Confondu",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["gangsign"] = {
        "mp_player_int_uppergang_sign_a",
        "mp_player_int_gang_sign_a",
        "Signe de Gang",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gangsign2"] = {
        "mp_player_int_uppergang_sign_b",
        "mp_player_int_gang_sign_b",
        "Signe de Gang 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gangsign3"] = {
        "amb@code_human_in_car_mp_actions@gang_sign_b@low@ps@base",
        "idle_a",
        "Signe de Gang 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gangsign4"] = {
        "amb@code_human_in_car_mp_actions@v_sign@std@rds@base",
        "idle_a",
        "Signe de Gang 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["passout7"] = {
        "anim@scripted@data_leak@fix_bil_ig2_chopper_crawl@",
        "fix_bil_ig2_chopper_crawl_dead_loop_ped",
        "Inconsient 7",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout8"] = {
        "anim@scripted@data_leak@fix_bil_ig2_chopper_crawl@",
        "fix_bil_ig2_chopper_crawl_dead_loop_ped",
        "Inconsient 8",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["petting"] = {
        "creatures@rottweiler@tricks@",
        "petting_franklin",
        "Caresse",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["flip2"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "cap_a_player_a",
        "Retourner 2"
    },
    ["flip"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "flip_a_player_a",
        "Retourner"
    },
    ["slide"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "slide_a_player_a",
        "Glisser"
    },
    ["slide2"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "slide_b_player_a",
        "Glisser 2"
    },
    ["slide3"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "slide_c_player_a",
        "Glisser 3"
    },
    ["slugger"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "slugger_a_player_a",
        "Cogneur"
    },
    ["flipoff"] = {
        "anim@arena@celeb@podium@no_prop@",
        "flip_off_a_1st",
        "Désactiver",
        AnimationOptions = {
            EmoteMoving = true
        }
    },
    ["flipoff2"] = {
        "anim@arena@celeb@podium@no_prop@",
        "flip_off_c_1st",
        "Désactiver 2",
        AnimationOptions = {
            EmoteMoving = true
        }
    },
    ["keyfob"] = {
        "anim@mp_player_intmenu@key_fob@",
        "fob_click",
        "Porte-clés",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["holster"] = {
        "move_m@intimidation@cop@unarmed",
        "idle",
        "Étui",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["holster2"] = { -- Custom Emote Provided To RpEmotes By Mads
        "mads@police_reaching_holster",
        "idle",
        "Étui 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["holster3"] = {
        "anim@hlstr_7360_walk",
        "holster_walk",
        "Étui 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["holster4"] = {
        "anim@hlstr_7360_hold",
        "holster_stop",
        "Étui 4 - Stop",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["holster5"] = {
        "anim@holster_hold_there",
        "holster_hold",
        "Étui 5 - Stop 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["slap"] = {
        "melee@unarmed@streamed_variations",
        "plyr_takedown_front_slap",
        "Gifler",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    ["fishdance"] = {
        "anim@mp_player_intupperfind_the_fish",
        "idle_a",
        "Danse du poisson",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace"] = {
        "mp_player_int_upperpeace_sign",
        "mp_player_int_peace_sign",
        "Signe de paix",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace2"] = {
        "anim@mp_player_intupperpeace",
        "idle_a",
        "Signe de paix 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace3"] = {
        "anim@mp_player_intupperpeace",
        "idle_a_fp",
        "Signe de paix 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace4"] = {
        "anim@mp_player_intincarpeacestd@ds@",
        "idle_a",
        "Signe de paix 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace5"] = {
        "anim@mp_player_intincarpeacestd@ds@",
        "idle_a_fp",
        "Signe de paix 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace6"] = {
        "anim@mp_player_intincarpeacebodhi@ds@",
        "idle_a",
        "Signe de paix 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peace7"] = {
        "anim@mp_player_intincarpeacebodhi@ds@",
        "idle_a_fp",
        "Signe de paix 7",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peacef"] = {
        "anim@mp_player_intcelebrationfemale@peace",
        "peace",
        "Signe de paix Femme",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ledge"] = {
        "missfbi1",
        "ledge_loop",
        "Rebord",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["airplane"] = {
        "missfbi1",
        "ledge_loop",
        "Avion",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["peek"] = {
        "random@paparazzi@peek",
        "left_peek_a",
        "Observer discrètement",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["stretch4"] = {
        "rcmfanatic1maryann_stretchidle_b",
        "idle_e",
        "S'ettirer 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["celebrate"] = {
        "rcmfanatic1celebrate",
        "celebrate",
        "Celebrer",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["punching"] = {
        "rcmextreme2",
        "loop_punching",
        "Coup de poings",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["punching2"] = {
        "anim@scripted@bty2@ig2_beat_target@male@",
        "standing_punch_v1_golfer",
        "Coup de poings 2",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = false
        }
    },
    ["superhero"] = {
        "rcmbarry",
        "base",
        "Super-héros",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["superhero2"] = {
        "rcmbarry",
        "base",
        "Super-héros 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mindcontrol"] = {
        "rcmbarry",
        "mind_control_b_loop",
        "Sang Froid",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["mindcontrol2"] = {
        "rcmbarry",
        "bar_1_attack_idle_aln",
        "Sang Froid 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["clown"] = {
        "rcm_barry2",
        "clown_idle_0",
        "Clown (Pitre)",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["clown2"] = {
        "rcm_barry2",
        "clown_idle_1",
        "Clown (Pitre) 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["clown3"] = {
        "rcm_barry2",
        "clown_idle_2",
        "Clown (Pitre) 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["clown4"] = {
        "rcm_barry2",
        "clown_idle_3",
        "Clown (Pitre) 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["clown5"] = {
        "rcm_barry2",
        "clown_idle_6",
        "Clown (Pitre) 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["tryclothes"] = {
        "mp_clothing@female@trousers",
        "try_trousers_neutral_a",
        "Essayer Vetements",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["tryclothes2"] = {
        "mp_clothing@female@shirt",
        "try_shirt_positive_a",
        "Essayer Vetements 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["tryclothes3"] = {
        "mp_clothing@female@shoes",
        "try_shoes_positive_a",
        "Essayer Vetements 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["tryclothes4"] = {
        "anim@scripted@ulp_missions@change_clothes@female@",
        "change_highroller",
        "Essayer Vetements 4",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["tryclothes5"] = {
        "anim@scripted@ulp_missions@change_clothes@",
        "change_highroller_male",
        "Essayer Vetements 5",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["nervous3"] = {
        "rcmme_tracey1",
        "nervous_loop",
        "Nerveux 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["nervous4"] = {
        "fix_trip3_mcs1-9",
        "cs_marnie_dual-9",
        "Nerveux 4",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = false
        }
    },
    ["namaste"] = {
        "timetable@amanda@ig_4",
        "ig_4_base",
        "Namasté",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["threaten"] = {
        "random@atmrobberygen",
        "b_atm_mugging",
        "Menacer",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["radio"] = {
        "random@arrests",
        "generic_radio_chatter",
        "Talkie-walkie",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pull"] = {
        "random@mugging4",
        "struggle_loop_b_thief",
        "Tirer",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bird"] = {
        "random@peyote@bird",
        "wakeup",
        "Faire l'oiseau"
    },
    ["chicken"] = {
        "random@peyote@chicken",
        "wakeup",
        "Faire la poule",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bark"] = {
        "random@peyote@dog",
        "wakeup",
        "Abboier"
    },
    ["rabbit"] = {
        "random@peyote@rabbit",
        "wakeup",
        "Lapin"
    },
    ["spiderman"] = {
        "missexile3",
        "ex03_train_roof_idle",
        "Homme-Araignée",
        AnimationOptions = {
            EmoteLoop = true,
            NotInVehicle = true
        }
    },
    ["boi"] = {
        "special_ped@jane@monologue_5@monologue_5c",
        "brotheradrianhasshown_2",
        "Gars",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3000
        }
    },
    ["adjust"] = {
        "missmic4",
        "michael_tux_fidget",
        "Ajuster",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 4000
        }
    },
    ["addict"] = {
        "anim@scripted@island@special_peds@dave@hs4_dave_stage3_ig7",
        "base",
        "Accro",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ['handsup4'] = {
        'anim@scripted@bty2@ig2_beat_target@male@',
        'leaning_idle_bounty',
        'Lever les mains 4',
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ['handsup5'] = {
        'anim@scripted@bty2@ig2_beat_target@male@',
        'standing_idle_bounty',
        'Lever les mains 5',
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["tighten"] = {
        "timetable@denice@ig_1",
        "idle_b",
        "Renforcer (Yoga)",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["fspose"] = {
        "missfam5_yoga",
        "c2_pose",
        "Pose Sexy F",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["fspose2"] = {
        "missfam5_yoga",
        "c6_pose",
        "Pose Sexy F 2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            NotInVehicle = true
        },
        AdultAnimation = true
    },
    ["fspose3"] = {
        "anim@amb@carmeet@checkout_car@",
        "female_c_idle_d",
        "Pose Sexy F 3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["showerf"] = {
        "mp_safehouseshower@female@",
        "shower_enter_into_idle",
        "Douche Entrer Femme",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["showerf2"] = {
        "mp_safehouseshower@female@",
        "shower_idle_a",
        "Douche Femme",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["showerf3"] = {
        "mp_safehouseshower@female@",
        "shower_idle_b",
        "Douche Femme 2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["showerm"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_a",
        "Entrer Douche Homme",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["showerm2"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_b",
        "Douche Homme 2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["showerm3"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_c",
        "Douche Homme 3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["showerm4"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_d",
        "Douche Homme 4",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["cleanhands"] = {
        "missheist_agency3aig_23",
        "urinal_sink_loop",
        "Se laver les mains",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["cleanface"] = {
        "switch@michael@wash_face",
        "loop_michael",
        "Se laver le visage",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["buzz"] = {
        "anim@apt_trans@buzzer",
        "buzz_reg",
        "Sonner a la porte",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = false
        }
    },
    ["grieve"] = {
        "anim@miss@low@fin@vagos@",
        "idle_ped05",
        "Pleurer les morts",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["respect"] = {
        "anim@mp_player_intcelebrationmale@respect",
        "respect",
        "Respect Homme",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = false
        }
    },
    ["respectf"] = {
        "anim@mp_player_intcelebrationfemale@respect",
        "respect",
        "Respect Femme",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = false
        }
    },
    ["bang"] = {
        "anim@mp_player_intcelebrationfemale@bang_bang",
        "bang_bang",
        "Bang Bang",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 2500
        }
    },
    ["checkcar"] = {
        "anim@amb@carmeet@checkout_car@male_a@idles",
        "idle_b",
        "Regarder avec Intérêt · Femmme",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["checkcar2"] = {
        "anim@amb@carmeet@checkout_car@male_c@idles",
        "idle_a",
        "Regarder avec Intérêt 2 · Homme",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["showboobs"] = {
        "mini@strip_club@backroom@",
        "stripper_b_backroom_idle_b",
        "Montrer ses seins",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 6000,
        },
        AdultAnimation = true
    },
    ["showboobs2"] = {
        "mini@strip_club@idles@stripper",
        "stripper_idle_05",
        "Montrer ses seins 2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 6000,
        },
        AdultAnimation = true
    },
    ["watchstripper"] = {
        "amb@world_human_strip_watch_stand@male_c@idle_a",
        "idle_b",
        "Regarder Stripteaseuse",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 6000,
        },
        AdultAnimation = true
    },
    ["hhands"] = {
        "misssnowie@hearthands",
        "base",
        "Coeur Main",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pockets"] = { -- Custom Emote By Dark Animations
        "hoodie_hands@dad",
        "hoodie_hands_clip",
        "Main dans les poches (Sweat)",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["posecutef"] = { -- Custom Emote By Pupppy
        "pupppy@freepose01",
        "freepose01",
        "Pose mignonne Femme",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["posecutef2"] = { -- Custom Emote By Pupppy
        "pupppy@freepose03",
        "freepose03",
        "Pose mignonne Femme 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["posecutef3"] = { -- Custom Emote By Pupppy
        "pupppy@freepose04",
        "freepose04",
        "Pose mignonne Femme 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["posecutef4"] = { -- Custom Emote By QueenSistersAnimations
        "handkylie@queensisters",
        "kylie_clip",
        "Pose mignonne Femme 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["posecutem"] = { -- Custom Emote By Pupppy
        "pupppy@freepose02",
        "freepose02",
        "Pose mignonne Male",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["checkwatch"] = { -- Custom Emote By MissSnowie
        "watch@looking_at",
        "base",
        "Impatient",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pee"] = {
        "misscarsteal2peeing",
        "peeing_loop",
        "Pisser (Homme)",
        AnimationOptions = {
            EmoteStuck = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {
                -0.05,
                0.3,
                0.0,
                0.0,
                90.0,
                90.0,
                1.0
            },
            PtfxInfo = ('pee'),
            PtfxWait = 0,
            PtfxCanHold = true,
        },
        AdultAnimation = true
    },
    ["pee2"] = {
        "missbigscore1switch_trevor_piss",
        "piss_loop",
        "Pisser 2 (Homme)",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {
                0.0130,
                0.1030,
                0.0,
                0.0,
                90.0,
                90.0,
                1.0
            },
            PtfxInfo = ('pee'),
            PtfxWait = 0,
            PtfxCanHold = true,
        },
        AdultAnimation = true
    },
    ["pee3"] = {
        "missbigscore1switch_trevor_piss",
        "piss_loop",
        "Pisser 3 Statique (Homme)",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {
                0.0130,
                0.1030,
                0.0,
                0.0,
                90.0,
                90.0,
                1.0
            },
            PtfxInfo = ('pee'),
            PtfxWait = 0,
            PtfxCanHold = true,
        },
        AdultAnimation = true
    },
    ["hump"] = {
        "timetable@trevor@skull_loving_bear",
        "skull_loving_bear",
        "Baiser",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["wank"] = {
        "anim@mp_player_intselfiewank",
        "idle_a",
        "Branler",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["wank2"] = {
        "anim@mp_player_intupperwank",
        "idle_a",
        "Branler 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["wank3"] = {
        "mp_player_int_upperwank",
        "mp_player_int_wank_02",
        "Branler 3",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["wank4"] = {
        "mp_player_int_upperwank",
        "mp_player_int_wank_02_fp",
        "Branler 4",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["wank5"] = {
        "mp_player_intwank",
        "mp_player_int_wank",
        "Branler 5",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = false
        },
        AdultAnimation = true
    },
    ["calldog"] = {
        "switch@franklin@plays_w_dog",
        "001916_01_fras_v2_9_plays_w_dog_idle",
        "Appeler Chien",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["calldogr"] = {
        "missfra0_chop_find",
        "call_chop_r",
        "Appeler Chien - Droit",
        AnimationOptions = {
            EmoteLoop = false,
        }
    },
    ["calldogl"] = {
        "missfra0_chop_find",
        "call_chop_l",
        "Appeler Chien - gauche",
        AnimationOptions = {
            EmoteLoop = false,
        }
    },
    ["block"] = {
        "missheist_agency3ashield_face",
        "idle",
        "Moment de gêne",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["snot"] = {
        "move_p_m_two_idles@generic",
        "fidget_blow_snot",
        "Jeter Morve",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 4500
        }
    },
    ["scratch"] = {
        "move_p_m_two_idles@generic",
        "fidget_scratch_balls",
        "Se gratter les couilles",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteDuration = 4000
        },
        AdultAnimation = true
    },
    ["cartaunt"] = {
        "missarmenian1driving_taunts@lamar_1",
        "cmonfrank",
        "Provoquer véhicule",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartauntb"] = {
        "missarmenian1driving_taunts@lamar_1",
        "cmonmynigga",
        "Provoquer véhicule 2",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartauntc"] = {
        "missarmenian1driving_taunts@lamar_1",
        "hahahakeepup",
        "Provoquer véhicule 3",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartauntd"] = {
        "missarmenian1driving_taunts@lamar_1",
        "manthisismeanttobe",
        "Provoquer véhicule 4",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartaunte"] = {
        "missarmenian1driving_taunts@lamar_1",
        "rememberthis",
        "Provoquer véhicule 5",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 3000
        }
    },
    ["cartauntf"] = {
        "missarmenian1driving_taunts@lamar_1",
        "skoolinyoass",
        "Provoquer véhicule 6",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 3000
        }
    },
    ["cartauntg"] = {
        "missarmenian1driving_taunts@lamar_1",
        "youaintfuckin",
        "Provoquer véhicule 7",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartaunth"] = {
        "missarmenian1driving_taunts@franklin",
        "heyidontneedanybody",
        "Provoquer véhicule 8",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartaunti"] = {
        "missarmenian1driving_taunts@franklin",
        "heymotherfuckayoudriveslowasfuck",
        "Provoquer véhicule 9",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 3000
        }
    },
    ["cartauntj"] = {
        "missarmenian1driving_taunts@franklin",
        "kids_on_bicycles",
        "Provoquer véhicule 10",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartauntk"] = {
        "missarmenian1driving_taunts@franklin",
        "learnhowtouseastick",
        "Provoquer véhicule 11",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartauntl"] = {
        "missarmenian1driving_taunts@franklin",
        "slowassshit",
        "Provoquer véhicule 12",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 2000
        }
    },
    ["cartauntm"] = {
        "mp_intro_seq@mcs_7_race_taunt",
        "mcs_7_taunt_female",
        "Provoquer véhicule 13",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 5000
        }
    },
    ["cartauntn"] = {
        "mp_intro_seq@mcs_7_race_taunt",
        "mcs_7_taunt_male",
        "Provoquer véhicule 14",
        AnimationOptions = {
            onlyInVehicle = true,
            EmoteMoving = false,
            EmoteDuration = 5000
        }
    },
    ["flex2"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_002",
        "Flexion 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true -- Allows us to flex while performing another animation
        }
    },
    ["gym"] = { -- Custom Female Emote By Souris
        "mouse@air_squat",
        "air_squat_clip",
        "Gym - Squats",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["gym2"] = { -- Custom Female Emote By Souris
        "mouse@byc_crunch",
        "byc_crunch_clip",
        "Gym - Crunches",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 400,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["gym3"] = { -- Custom Female Emote By Souris
        "mouse@jump_exc",
        "jump_exc_clip",
        "Gym - Sauter",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["gym4"] = { -- Custom Female Emote By Souris
        "mouse@jump_jack",
        "jump_jack_clip",
        "Gym - Sauts étoile",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["gym5"] = { -- Custom Female Emote By Souris
        "mouse@situp",
        "situp_clip",
        "Gym - S'assoier",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 550,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["gympose"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_001",
        "Pose Gym",
        AnimationOptions = {
            EmoteLoop = true,
            NotInVehicle = true
        }
    },
    ["gympose2"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_005",
        "Pose Gym 2 - Pompe à une main",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 550,
            ExitEmote = "standup",
            ExitEmoteType = "Exits",
            NotInVehicle = true
        }
    },
    ["gympose3"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_004",
        "Pose Gym 3 - Gainage",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 550,
            ExitEmote = "standup",
            ExitEmoteType = "Exits",
            NotInVehicle = true
        }
    },
    ["gympose4"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_005",
        "Pose Gym 4 - Abdos",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 510,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            NotInVehicle = true
        }
    },

    -- CASINO DLC EMOTES (Requires gamebuild 2060 or higher)

    ["cutthroat"] = {
        "anim@mp_player_intcelebrationmale@cut_throat",
        "cut_throat",
        "Couper la gorge"
    },
    ["cutthroat2"] = {
        "anim@mp_player_intcelebrationfemale@cut_throat",
        "cut_throat",
        "Couper la gorge 2"
    },
    ["mindblown"] = {
        "anim@mp_player_intcelebrationmale@mind_blown",
        "mind_blown",
        "Époustouflé",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 4000
        }
    },
    ["mindblown2"] = {
        "anim@mp_player_intcelebrationfemale@mind_blown",
        "mind_blown",
        "Époustouflé 2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 4000
        }
    },
    ["capoeira"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@techno_karate@",
        "med_right",
        "Capoeira",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["capoeira2"] = {
        "anim@amb@nightclub@mini@dance@dance_solo@techno_karate@",
        "high_right_down",
        "Capoeira 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["stink"] = {
        "anim@mp_player_intcelebrationfemale@stinker",
        "stinker",
        "Puant",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["taichi"] = {
        "anim@veh@van@mule5@rps",
        "lean_forward_idle",
        "Tai chi",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["taichi2"] = {
        "switch@trevor@rand_temple",
        "tai_chi_trevor",
        "Tai chi - Maladroit",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = false
        }
    },
    ["think4"] = {
        "anim@amb@casino@hangout@ped_male@stand@02b@idles",
        "idle_a",
        "Penser 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["adjusttie"] = {
        "clothingtie",
        "try_tie_positive_a",
        "Ajuster la cravate",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 5000
        }
    },
    ["shaka"] = {
        "sign@hang_loose",
        "base",
        "Attitude décontractée'",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shaka2"] = {
        "sign@hang_loose_casual",
        "base",
        "Attitude décontractée Normal'",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["relax"] = {
        "lying@on_grass",
        "base",
        "Détente",
        AnimationOptions = {
            EmoteLoop = true,
            NotInVehicle = true,
            StartDelay = 800,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["relax2"] = {
        "lying@on_couch_legs_crossed",
        "base",
        "Détente 2",
        AnimationOptions = {
            EmoteLoop = true,
            NotInVehicle = true,
            StartDelay = 800,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["uwu"] = {
        "uwu@egirl",
        "base",
        "UwU",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dab"] = {
        "stand_dab@dark",
        "stand_dab_clip",
        "Dab",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sexypose"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy003",
        "sexy003",
        "Pose Sexy",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sexypose2"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy004",
        "sexy004",
        "Pose Sexy 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sexypose3"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy005",
        "sexy005",
        "Pose Sexy 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sexypose4"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy006",
        "sexy006",
        "Pose Sexy 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sexypose5"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy009",
        "sexy009",
        "Pose Sexy 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sexypose6"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy012",
        "sexy012",
        "Pose Sexy 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sexypose7"] = { -- Custom Emote By Darks Animations
        "bad_girls_pose3@darks37",
        "bad_girls_pose3_clip",
        "Pose Sexy 7",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["laydownsexy"] = { -- Custom emote by Struggleville
        "anim@female_laying_sexy",
        "laying_sexy_clip",
        "Couché sexy",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["model"] = { -- Custom emote by Struggleville
        "anim@female_model_showoff",
        "model_showoff_clip",
        "Modele Pose Sexy",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["model2"] = { -- Custom Emote By QueenSistersAnimations
        "sitdownonknees@queensisters",
        "sitdown_clip",
        "Modele Pose 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["model3"] = { -- Custom emote by Struggleville
        "anim@female_model_photo_cute",
        "photo_cute_clip",
        "Modele Pose 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["layncry"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_fuckedup_laz",
        "Coucher et pleurer",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry2"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_base_laz",
        "Coucher et pleurer 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry3"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_notagain_laz",
        "Coucher et pleurer 3",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry4"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_notagain_laz",
        "Coucher et pleurer 4",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry5"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_shit2strong_laz",
        "Coucher et pleurer 5",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry6"] = {
        "misschinese2_crystalmaze",
        "2int_loop_a_taocheng",
        "Coucher et pleurer 6",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry7"] = {
        "anim@scripted@data_leak@fixf_fin_ig2_johnnyguns_wounded@",
        "base",
        "Coucher et pleurer 7",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry8"] = {
        "anim@scripted@data_leak@fix_golf_ig2_golfclub_intimidation@",
        "stage_3_base_golfer",
        "Coucher et pleurer 8",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["army1"] = {
        "bzzz@animation@army1", -- Custom Emote By BzZz
        "bz_army1",
        "Militaire 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["army1l"] = {
        "bzzz@animation@army1_left", -- Custom Emote By BzZz
        "bz_army1_left",
        "Militaire 1 Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["army1p"] = {
        "bzzz@animation@army1_right", -- Custom Emote By BzZz
        "bz_army1_right",
        "Militaire 1 Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["army2"] = {
        "bzzz@animation@army2", -- Custom Emote By BzZz
        "bz_army2",
        "Militaire 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["army2l"] = {
        "bzzz@animation@army2_left", -- Custom Emote By BzZz
        "bz_army2_left",
        "Militaire 2 Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["army2p"] = {
        "bzzz@animation@army2_right", -- Custom Emote By BzZz
        "bz_army2_right",
        "Militaire 2 Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["airforce01"] = { -- MissSnowie
        "airforce@at_ease",
        "base",
        "Airforce - À l'aise", -- MissSnowie
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["airforce02"] = { -- MissSnowie
        "airforce@attention",
        "base",
        "Airforce - Attention",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["airforce03"] = { -- MissSnowie
        "airforce@parade_rest",
        "base",
        "Airforce - Au repos",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["airforce04"] = {
        "airforce@salute",
        "base",
        "Airforce - Salut",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["zombiewalk"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "zombi_walk_01",
        "Marchie Zombie",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false -- true looks weird but the option is here
        }
    },
    ["zombiewalk2"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "zombi_walk_02",
        "Marchie Zombie 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["zombiewalk3"] = {
        "anim@ingame@move_m@zombie@core",
        "walk_up",
        "Marchie Zombie 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["zombiewalk4"] = {
        "anim@ingame@move_m@zombie@core",
        "run_turn_r3",
        "Marchie Zombie - Cercle",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["zombieagony"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "agony",
        "Zombie Agonie",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["zombiescream"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "scream",
        "Zombie Crie",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["zombiecrawl"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "crawl_01",
        "Zombie Ramper",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "meditateup",
            ExitEmoteType = "Exits"
        }
    },
    ["zombieswipe"] = {
        "anim@ingame@melee@unarmed@streamed_core_zombie",
        "short_-180_punch",
        "Zombie Glisser",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["zombieswipe2"] = {
        "anim@ingame@melee@unarmed@streamed_variations_zombie",
        "heavy_punch_b_var_2",
        "Zombie Glisser 2",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["zombieswipe3"] = {
        "anim@ingame@melee@unarmed@streamed_core_zombie",
        "short_90_punch",
        "Zombie Glisser 3",
        AnimationOptions = {
            EmoteLoop = false
        }
    },
    ["laysexy"] = { -- Custom Emote By Amnilka
        "amnilka@photopose@female@homepack001",
        "amnilka_femalehome_photopose_004",
        "Poser sexy",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["gungirl1"] = { -- Custom Emote By Struggleville
        "anim@female_gunbunny_rifle_photo",
        "rifle_photo_clip",
        "Pose Fusil d'Asault",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["vest"] = {
        "anim@male@holding_vest",
        "holding_vest_clip",
        "Tenir Gilet",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["vest2"] = {
        "anim@holding_side_vest",
        "holding_side_vest_clip",
        "Tenir Gilet 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["vest3"] = {
        "anim@holding_siege_vest_side",
        "holding_siege_vest_side_clip",
        "Tenir Gilet 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["vest4"] = {
        "anim@male@holding_vest_2",
        "holding_vest_2_clip",
        "Tenir Gilet 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["vest5"] = {
        "anim@male@holding_vest_siege",
        "holding_vest_siege_clip",
        "Tenir Gilet 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["vest6"] = {
        "anim@male@holding_vest_siege_2",
        "holding_vest_siege_2_clip",
        "Tenir Gilet 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["kick"] = {
        "missheistdockssetup1ig_13@kick_idle",
        "guard_beatup_kickidle_guard1",
        "Coup de pied",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kick2"] = {
        "missheistdockssetup1ig_13@kick_idle",
        "guard_beatup_kickidle_guard2",
        "Coup de pied 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kick3"] = {
        "melee@unarmed@streamed_core",
        "kick_close_a",
        "Coup de pied 3",
        AnimationOptions = {
            EmoteDuration = 1750
        }
    },
    ["crosshands"] = {
        "anim@amb@carmeet@checkout_car@",
        "male_e_base",
        "Bras Croisé",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["aslyes"] = {
        "ebrwny_sign",
        "ebrwny_yes",
        "ASL Oui 🇺🇸",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1030
        }
    },
    ["aslno"] = {
        "ebrwny_sign",
        "ebrwny_no",
        "ASL Non 🇺🇸",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 2080
        }
    },
    ["aslimgood"] = {
        "ebrwny_sign",
        "ebrwny_imgood",
        "ASL Tout va bien 🇺🇸",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 3940
        }
    },
    ["aslcya"] = {
        "ebrwny_sign",
        "ebrwny_seeya",
        "ASL A Bientot 🇺🇸",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1200
        }
    },
    ["aslwhat"] = {
        "ebrwny_sign",
        "ebrwny_what",
        "ASL Quoi 🇺🇸",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 1480
        }
    },
    ["hidegun"] = { -- Credit to Darks Animations for this exclusive rpemotes animation
        "pistol_b_b@dark",
        "pistol_b_b_clip",
        "Cacher Pistolet",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["femaleposea"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_10",
        "mrwitt",
        "pose Femme A",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleadorable1"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@adorable_style",
        "mrwitt",
        "Femme Adorable 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleadorable2"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@adorable",
        "mrwitt",
        "Femme Adorable 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposeb"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@characterful_poses",
        "mrwitt",
        "Femme Pose B",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposec"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@elegant_floor_hock",
        "mrwitt",
        "Femme Pose C",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposed"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_03",
        "mrwitt",
        "Femme Pose D",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposee"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_04",
        "mrwitt",
        "Femme Pose E",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposef"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_05",
        "mrwitt",
        "Femme Pose F",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposeg"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_06",
        "mrwitt",
        "Femme Pose G",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposeh"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_07",
        "mrwitt",
        "Femme Pose H",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposei"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_09",
        "mrwitt",
        "Femme Pose I",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposej"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_10",
        "mrwitt",
        "Femme Pose J",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposek"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@femalepose_11",
        "mrwitt",
        "Femme Pose K",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposel"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@finger_gun_pose",
        "mrwitt",
        "Femme Pose L",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposem"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@models_in_action",
        "mrwitt",
        "Femme Pose M",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposen"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@photo_session_posing",
        "mrwitt",
        "Femme Pose N",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposeo"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@school_uniform_expression",
        "mrwitt",
        "Femme Pose O",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposep"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@urban_posing",
        "mrwitt",
        "Femme Pose P",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["femaleposeq"] = { -- Custom Emote By DRX Animations
        "drx@femalestand13",
        "xrd",
        "Femme Pose Q",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposer"] = { -- Custom Emote By DRX Animations
        "drx@femalestand14",
        "xrd",
        "Femme Pose R",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposes"] = { -- Custom Emote By DRX Animations
        "drx@femalestand15",
        "xrd",
        "Femme Pose S",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposet"] = { -- Custom Emote By DRX Animations
        "drx@femalestand16",
        "xrd",
        "Femme Pose T",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposeu"] = { -- Custom Emote By DRX Animations
        "drx@f_sitcool",
        "drx",
        "Femme Pose U",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["femaleposev"] = { -- Custom Emote By DRX Animations
        "drx@f_standcasual1",
        "drx",
        "Femme Pose V",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposew"] = { -- Custom Emote By DRX Animations
        "drx@f_standcasual2",
        "drx",
        "Femme Pose W",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposex"] = { -- Custom Emote By DRX Animations
        "drx@femalestand7",
        "xrd",
        "Femme Pose X",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposey"] = { -- Custom Emote By DRX Animations
        "drx@femalestand8",
        "xrd",
        "Femme Pose Y",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femaleposez"] = { -- Custom Emote By DRX Animations
        "drx@femalestand9",
        "xrd",
        "Femme Pose Z",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposea"] = { -- Custom Emote By DRX Animations
        "drx@singlemale1",
        "drx",
        "Homme Pose A",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposeb"] = { -- Custom Emote By DRX Animations
        "drx@singlemale2",
        "drx",
        "Homme Pose B",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposec"] = { -- Custom Emote By DRX Animations
        "drx@singlemalestand1",
        "drx",
        "Homme Pose C",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposed"] = { -- Custom Emote By DRX Animations
        "drx@singlemalestand2",
        "drx",
        "Homme Pose D",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposee"] = { -- Custom Emote By DRX Animations
        "drx@m_doublehands",
        "drx",
        "Homme Pose E",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposef"] = { -- Custom Emote By DRX Animations
        "drx@m_standhide",
        "drx",
        "Homme Pose F",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposee1"] = { -- Custom Emote By DRX Animations
        "drx@malestand2",
        "xrd",
        "Homme Pose E1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposef1"] = { -- Custom Emote By DRX Animations
        "drx@malestand3c",
        "xrd",
        "Homme Pose F1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposeg"] = { -- Custom Emote By DRX Animations
        "drx@pose_male",
        "pose_male",
        "Homme Pose G",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposeh"] = { -- Custom Emote By MrWitt
        "mrwitt@gentleman_style_male",
        "mrwitt",
        "Homme Pose H",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposei"] = { -- Custom Emote By MrWitt
        "mrwitt@thoughtful_man_m",
        "mrwitt",
        "Homme Pose I",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["maleposetie"] = { -- Custom Emotes By MrWhitt Provided To RPEmotes 01/08/2023
        "mrwitt@tie_perfection_in_suit_male",
        "mrwitt",
        "Homme Pose Cravate",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malecrossarms"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "cross_arms@dark",
        "cross_arms_clip",
        "Homme Bras Croisé",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malemiddlefinger"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "stand_middlefinger@dark",
        "stand_middlefinger_clip",
        "Homme Doigt d'honneur",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malefistface"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "fist_face@darksj",
        "fist_face_clip",
        "Homme Coup de poing Visage",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malepose4"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "fuckm@nxsty",
        "fuckm_clip",
        "Homme Pose 4",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malegunpose1"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "gun_ink@darksj",
        "gun_ink_clip",
        "Homme Pose Arme 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malepose5"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "koko_male@darksj",
        "koko_male_clip",
        "Homme Pose 5",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malepose3"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "male_solo_1@darksj",
        "male_solo_1_clip",
        "Homme Pose 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malepose2"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "male_solo_3@darksj",
        "male_solo_3_clip",
        "Homme Pose 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malepose1"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "male_solo_4@darksj",
        "male_solo_4_clip",
        "Homme Pose 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["maleshoecheck"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "side_shoe_check@darksj",
        "side_shoe_check_clip",
        "Homme Admirer Chaussure",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["malegangpose"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "westside_cap@darksj",
        "westside_cap_clip",
        "Homme Pose Gang",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["illuminati"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_illum",
        "ebrwny_illum003",
        "Signe Main Illuminati",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["illuminati2"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_illum",
        "ebrwny_illum001",
        "Signe Main Illuminati 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["illuminati3"] = { -- Custom Emote By EnchantedBrwny
        "ebrwny_illum",
        "ebrwny_illum002",
        "Signe Main Illuminati 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["gunpoint"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "male_gun@vanessssi",
        "male_gun_clip",
        "Pointer Arme - Braquage",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["baddiepeace"] = { -- Custom Emote provided by 41anims
        "41animpeacebaddie@animation",
        "41animpeacebaddie_clip",
        "Femme Pose Détendu",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["baddiebendova"] = { -- Custom Emote provided by 41anims
        "bendova@animation",
        "bendova_clip",
        "Femme Pose Bendova",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["baddienailpose"] = { -- Custom Emote provided by 41anims
        "nailpose@animation",
        "nailpose_clip",
        "Femme Pose Ongles",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aphroditepose"] = { -- Custom Emote provided by corbs
        "aphrodite1@corbs",
        "aphrodite1_clip",
        "Pose Aphrodite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aphroditepose2"] = { -- Custom Emote provided by corbs
        "aphrodite2@corbs",
        "aphrodite2_clip",
        "Pose Aphrodite 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aphroditepose3"] = { -- Custom Emote provided by corbs
        "aphrodite3@corbs",
        "aphrodite3_clip",
        "Pose Aphrodite 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
}

--- EMOTES WITH 1 OR 2 PROPS ---
RP.PropEmotes = {
    label = "Props",
    icon = "📦",
    ["spoonbowlcereal"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de céréales",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_cereal1',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["spoonbowlyogurt"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de yaourt",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_bowliogurte',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowlstew"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de ragoût",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_campersstew',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowlchilli"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de chili",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_chillibowl',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowlbeans"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de haricots",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_feijoada',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowlparfait"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de parfait",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_parfait',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowlramen"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de ramen",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_ramen',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowloats"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol d'avoine",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_oats',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["spoonbowlgranola"] = {
        "rick3d@foodsdrinks",
        "bowl_clip",
        "Bol de granola",
        AnimationOptions = {
            Prop = 'rick3d_foods_cerealspoon',
            PropBone = 58869,
            PropPlacement = {
                0.1,
                -0.07,
                0.02,
                0.0,
                25.0,
                -90.0
            },
            SecondProp = 'rick3d_foods_granola',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.02,
                -0.02,
                75.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    -- 1 HAND FOOD --
    ["1handchocolate1"] = {
        "rick3d@foodsdrinks",
        "chocolatebar_clip",
        "Chocolat blanc",
        AnimationOptions = {
            Prop = 'rick3d_foods_whitechocolatebar',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.05,
                0.06,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handchocolate2"] = {
        "rick3d@foodsdrinks",
        "chocolatebar_clip",
        "Barre de chocolat",
        AnimationOptions = {
            Prop = 'rick3d_foods_chocolatebar',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.05,
                0.06,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handbaconsandwich"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Sandwich au bacon",
        AnimationOptions = {
            Prop = 'rick3d_foods_baconsandwich',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handwaffles"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Gaufres",
        AnimationOptions = {
            Prop = 'rick3d_foods_waffles',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handdonut"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Beignet 1",
        AnimationOptions = {
            Prop = 'rick3d_foods_donut',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handpeeledpotatoes"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Pommes de terre épluchées",
        AnimationOptions = {
            Prop = 'rick3d_foods_peeledpotatoes',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handcroissant"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Croissant",
        AnimationOptions = {
            Prop = 'rick3d_foods_croissant',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                122.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handrawfishfillet"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Filet de poisson cru",
        AnimationOptions = {
            Prop = 'rick3d_foods_rawfishfillet',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handlobster1"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Homard 1",
        AnimationOptions = {
            Prop = 'rick3d_foods_lobster_a',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handlobster2"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Homard 2",
        AnimationOptions = {
            Prop = 'rick3d_foods_lobster_b',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handbegel"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Bagel",
        AnimationOptions = {
            Prop = 'rick3d_foods_begel',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handsweetbanana"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Banane sucrée",
        AnimationOptions = {
            Prop = 'rick3d_foods_sweetbanana',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.13,
                -0.1,
                15.0,
                0.0,
                -25.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handapple1"] = {
        "rick3d@foodsdrinks",
        "1handeat2_clip",
        "Pomme",
        AnimationOptions = {
            Prop = 'rick3d_foods_apple1',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                -0.02,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handquesadilla"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Quesadilla",
        AnimationOptions = {
            Prop = 'rick3d_foods_quesadilla',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handrawsalmon"] = {
        "rick3d@foodsdrinks",
        "1handeat_clip",
        "Saumon cru",
        AnimationOptions = {
            Prop = 'rick3d_foods_rawsalmon',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handcandyapple"] = {
        "rick3d@foodsdrinks",
        "1handeat3_clip",
        "Pomme d'amour",
        AnimationOptions = {
            Prop = 'rick3d_foods_candyapple',
            PropBone = 58869,
            PropPlacement = {
                0.0,
                0.05,
                -0.03,
                20.0,
                25.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["1handbigsausage"] = {
        "rick3d@foodsdrinks",
        "1handeat3_clip",
        "Grosse saucisse",
        AnimationOptions = {
            Prop = 'rick3d_foods_bigsausage',
            PropBone = 58869,
            PropPlacement = {
                0.01,
                -0.0,
                0.2,
                0.0,
                85.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    -- 2 HANDS FOOD --
    ["2handpizza"] = {
        "rick3d@foodsdrinks",
        "2handeat2_clip",
        "Pizza",
        AnimationOptions = {
            Prop = 'rick3d_foods_pizza',
            PropBone = 26612,
            PropPlacement = {
                0.07,
                -0.12,
                -0.012,
                0.0,
                0.0,
                170.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handsausageroll"] = {
        "rick3d@foodsdrinks",
        "2handeat_clip",
        "Friand",
        AnimationOptions = {
            Prop = 'rick3d_foods_sausageroll',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.09,
                -0.02,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handhamburguer"] = {
        "rick3d@foodsdrinks",
        "2handeat_clip",
        "Hamburger",
        AnimationOptions = {
            Prop = 'rick3d_foods_hamburguer',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.1,
                0.05,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handbeignet"] = {
        "rick3d@foodsdrinks",
        "2handeat_clip",
        "Beignet",
        AnimationOptions = {
            Prop = 'rick3d_foods_beignet',
            PropBone = 58869,
            PropPlacement = {
                0.0,
                0.15,
                0.1,
                50.0,
                100.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handtaco"] = {
        "rick3d@foodsdrinks",
        "2handeat3_clip",
        "Taco",
        AnimationOptions = {
            Prop = 'rick3d_foods_taco',
            PropBone = 26613,
            PropPlacement = {
                -0.03,
                -0.01,
                -0.08,
                80.0,
                25.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handhotdog"] = {
        "rick3d@foodsdrinks",
        "2handeat3_clip",
        "Hot-dog",
        AnimationOptions = {
            Prop = 'rick3d_foods_hotdog',
            PropBone = 26613,
            PropPlacement = {
                -0.02,
                -0.03,
                -0.03,
                80.0,
                120.0,
                -15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handcheesesandwich"] = {
        "rick3d@foodsdrinks",
        "2handeat_clip",
        "Sandwich au fromage",
        AnimationOptions = {
            Prop = 'rick3d_foods_queijosanduba',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.07,
                0.07,
                70.0,
                145.0,
                -35.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handsweetpotato"] = {
        "rick3d@foodsdrinks",
        "2handeat_clip",
        "Patate douce",
        AnimationOptions = {
            Prop = 'rick3d_foods_sweetpotato',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.07,
                0.0,
                55.0,
                90.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["2handcottoncandy"] = {
        "rick3d@foodsdrinks",
        "2handeatcottoncandy_clip",
        "Barbe à papa",
        AnimationOptions = {
            Prop = 'rick3d_foods_cottoncandy',
            PropBone = 26613,
            PropPlacement = {
                0.03,
                -0.03,
                -0.2,
                -15.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    -- ICE CREAM --
    ["icecreamspoon1"] = {
        "rick3d@foodsdrinks",
        "icecream1_clip",
        "Glace cuillère 1",
        AnimationOptions = {
            Prop = 'rick3d_spoonwicecream_d',
            PropBone = 58869,
            PropPlacement = {
                0.07,
                0.01,
                0.02,
                0.0,
                25.0,
                -45.0
            },
            SecondProp = 'rick3d_foods_icecream3',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.03,
                -0.01,
                55.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["icecreamspoon2"] = {
        "rick3d@foodsdrinks",
        "icecream2_clip",
        "Glace cuillère 2",
        AnimationOptions = {
            Prop = 'rick3d_spoonwicecream_b',
            PropBone = 58869,
            PropPlacement = {
                0.07,
                0.01,
                0.03,
                0.0,
                25.0,
                -65.0
            },
            SecondProp = 'rick3d_foods_icecream1',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.03,
                -0.03,
                -5.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["icecreamspoon3"] = {
        "rick3d@foodsdrinks",
        "icecream2_clip",
        "Glace cuillère 3",
        AnimationOptions = {
            Prop = 'rick3d_spoonwicecream_b',
            PropBone = 58869,
            PropPlacement = {
                0.07,
                0.01,
                0.03,
                0.0,
                25.0,
                -65.0
            },
            SecondProp = 'rick3d_foods_icecream2',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.03,
                -0.04,
                -5.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    -- HAND HOLD --
    ["handholdtoeatpopcorn"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat1_clip",
        "Popcorn",
        AnimationOptions = {
            Prop = 'rick3d_foods_popcorn1',
            PropBone = 26613,
            PropPlacement = {
                0.06,
                -0.08,
                -0.06,
                0.0,
                0.0,
                50.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdfries"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat1_clip",
        "Frites",
        AnimationOptions = {
            Prop = 'rick3d_foods_frenchfries_only',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.05,
                0.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_frenchfries',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.07,
                -0.07,
                0.0,
                -10.0,
                -10.0,
                -15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdheartnuggets"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Nuggets coeur",
        AnimationOptions = {
            Prop = 'rick3d_foods_nuggets_b',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.05,
                0.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_heartnuggets',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.02,
                -0.035,
                0.02,
                90.0,
                0.0,
                15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdblueberry"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Myrtilles",
        AnimationOptions = {
            Prop = 'rick3d_foods_blueberries',
            PropBone = 26612,
            PropPlacement = {
                0.04,
                -0.03,
                0.02,
                90.0,
                -5.0,
                10.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdfishnchips"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Poisson-frites",
        AnimationOptions = {
            Prop = 'rick3d_foods_fishnchips',
            PropBone = 26612,
            PropPlacement = {
                -0.01,
                -0.04,
                0.04,
                75.0,
                25.0,
                20.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdnuggets"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Nuggets de poulet",
        AnimationOptions = {
            Prop = 'rick3d_foods_nuggets_b',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.05,
                0.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_nuggets',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.01,
                -0.025,
                0.0,
                90.0,
                0.0,
                15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdsteamedbuns"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Brioches vapeur",
        AnimationOptions = {
            Prop = 'rick3d_foods_nuggets_b',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.05,
                0.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_steamedbuns',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.01,
                -0.025,
                0.0,
                90.0,
                0.0,
                15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdsushiprato"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Sushi",
        AnimationOptions = {
            Prop = 'rick3d_foods_nuggets_b',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.05,
                0.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_sushi',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.01,
                -0.025,
                0.0,
                90.0,
                0.0,
                15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdbreadn"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Pain",
        AnimationOptions = {
            Prop = 'rick3d_foods_breadn',
            PropBone = 58869,
            PropPlacement = {
                0.04,
                0.04,
                0.08,
                90.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_breadnspread',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.01,
                -0.025,
                0.0,
                90.0,
                0.0,
                15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handholdtakoyaki"] = {
        "rick3d@foodsdrinks",
        "handholdtoeat2_clip",
        "Takoyaki",
        AnimationOptions = {
            Prop = 'rick3d_foods_nuggets_b',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.05,
                0.0,
                90.0,
                0.0
            },
            SecondProp = 'rick3d_foods_takoyaki',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.01,
                -0.025,
                0.0,
                90.0,
                0.0,
                15.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    -- DRINKS --
    ["drink1"] = {
        "rick3d@foodsdrinks",
        "drinks1_clip",
        "Boisson 1",
        AnimationOptions = {
            Prop = 'rick3d_foods_drink2',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                0.01,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drink3"] = {
        "rick3d@foodsdrinks",
        "drinks2_clip",
        "Boisson 3",
        AnimationOptions = {
            Prop = 'rick3d_foods_drink3',
            PropBone = 58869,
            PropPlacement = {
                0.03,
                0.03,
                0.01,
                0.0,
                -5.0,
                120.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drink4"] = {
        "rick3d@foodsdrinks",
        "drinks2_clip",
        "Boisson 4",
        AnimationOptions = {
            Prop = 'rick3d_foods_drink4',
            PropBone = 58869,
            PropPlacement = {
                0.03,
                0.03,
                0.01,
                0.0,
                -5.0,
                120.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drink5"] = {
        "rick3d@foodsdrinks",
        "drinks3_clip",
        "Boisson 5",
        AnimationOptions = {
            Prop = 'rick3d_foods_drink5',
            PropBone = 58869,
            PropPlacement = {
                0.03,
                0.05,
                -0.04,
                0.0,
                -5.0,
                120.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drink6"] = {
        "rick3d@foodsdrinks",
        "drinks4_clip",
        "Boisson 6",
        AnimationOptions = {
            Prop = 'rick3d_foods_drink6',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.04,
                0.01,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinkmojito"] = {
        "rick3d@foodsdrinks",
        "drinks5_clip",
        "Mojito",
        AnimationOptions = {
            Prop = 'rick3d_foods_mojito',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.06,
                -0.03,
                0.0,
                0.0,
                -75.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drink7"] = {
        "rick3d@foodsdrinks",
        "drinks6_clip",
        "Boisson 7",
        AnimationOptions = {
            Prop = 'rick3d_foods_drink7',
            PropBone = 64097,
            PropPlacement = {
                -0.01,
                -0.05,
                -0.07,
                0.0,
                0.0,
                90.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinktaca8"] = {
        "rick3d@foodsdrinks",
        "drinks7_clip",
        "Chocolat chaud",
        AnimationOptions = {
            Prop = 'rick3d_foods_hotchocolate',
            PropBone = 64097,
            PropPlacement = {
                -0.01,
                -0.03,
                -0.15,
                15.0,
                -15.0,
                45.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinktaca9"] = {
        "rick3d@foodsdrinks",
        "drinks8_clip",
        "Milkshake",
        AnimationOptions = {
            Prop = 'rick3d_foods_milkshake_a',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                -0.045,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinktaca10"] = {
        "rick3d@foodsdrinks",
        "drinks8_clip",
        "Milkshake 2",
        AnimationOptions = {
            Prop = 'rick3d_foods_milkshake_b',
            PropBone = 58869,
            PropPlacement = {
                0.02,
                0.05,
                -0.045,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinkglass1"] = {
        "rick3d@foodsdrinks",
        "drinks1_clip",
        "Verre 1",
        AnimationOptions = {
            Prop = 'rick3d_foods_glassdrink_a',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.05,
                -0.01,
                5.0,
                -10.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinkglass2"] = {
        "rick3d@foodsdrinks",
        "drinks1_clip",
        "Verre 2",
        AnimationOptions = {
            Prop = 'rick3d_foods_glassdrink_b',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.05,
                -0.01,
                5.0,
                -10.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["drinkglass3"] = {
        "rick3d@foodsdrinks",
        "drinks1_clip",
        "Verre 3",
        AnimationOptions = {
            Prop = 'rick3d_foods_glassdrink_c',
            PropBone = 58869,
            PropPlacement = {
                0.05,
                0.05,
                -0.01,
                5.0,
                -10.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },

    -- FORK AND PLATE --
    ["forkplatepotatopancake"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Beignet d'épinard",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_spinachfritter',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatebakedpotato"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Pomme de terre au four",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_bakedpotato',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatecrab"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Galette de crabe",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_crabcake',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatefishnchips2"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Poisson-frites 2",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_fishnchips2',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatefriedeggs"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Œufs au plat",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_friedeggs',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatekebab"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Brochette de fruits",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_kebabfruit',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplateomelet"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Omelette",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_omelet',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatescrambledeggs"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Œufs brouillés et bacon",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_scrambledeggsnbacon',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplategrilledfish"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Poisson grillé",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_grilledfish',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplateseabass"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Bar grillé",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_grilledseabass',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatetilapia"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Tilapia",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_friedtilapia',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatefruitcake"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Gâteau aux fruits",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_fruitcake',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatefruitcake2"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Gâteau aux fruits 2",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_fruitcake2',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatemontecristo"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Monte-Cristo",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_montecristo',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplateeggsntoast"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Œufs et toast",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_eggsntoast',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatescrambledeggs2"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Œufs brouillés",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_scrambledeggs',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["forkplatefrenchtoast"] = {
        "rick3d@foodsdrinks",
        "plate_clip",
        "Pain perdu",
        AnimationOptions = {
            Prop = 'rick3d_foods_fork',
            PropBone = 58869,
            PropPlacement = {
                0.09,
                0.05,
                0.02,
                0.0,
                25.0,
                -40.0
            },
            SecondProp = 'rick3d_foods_frenchtoast',
            SecondPropBone = 26612,
            SecondPropPlacement = {
                0.03,
                -0.04,
                0.0,
                70.0,
                70.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            NoAttachWait = true
        }
    },
    ["umbrella"] = {
        "amb@world_human_drinking@coffee@male@base",
        "base",
        "Parapluie - Milieu",
        AnimationOptions = {
            Prop = "p_amb_brolly_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0200,
                -0.0360,
                0.0,
                10.0,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = true,
            ExitEmote = "shakeitoffhuman",
            ExitEmoteType = "Exits"
        }
    },
    ['umbrella2'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Parapluie 2 - Epaule Droit',
        AnimationOptions = {
            Prop = 'p_amb_brolly_01',
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                0.0100,
                0.1100,
                2.3402393,
                -150.9605721,
                57.3374916
            },
            EmoteLoop = true,
            EmoteMoving = true,
            ExitEmote = "shakeitoffhuman",
            ExitEmoteType = "Exits"
        }
    },
    ['umbrella3'] = { -- Custom Emote Provided To RPEmotes By Mr Witt
        'mrwitt@rain_dreamy_pose',
        'mrwitt',
        'Parapluie 3 - Regarder la Pluie',
        AnimationOptions = {
            Prop = 'p_amb_brolly_01',
            PropBone = 58867,
            PropPlacement = {
                0.0150,
                0.0340,
                -0.0340,
                16.0040,
                -6.7284,
                -0.9319
            },
            EmoteLoop = true,
            EmoteMoving = true,
            ExitEmote = "shakeitoffhuman",
            ExitEmoteType = "Exits"
        }
    },
    ['umbrella4'] = { -- Custom Emote  By Mr ultrahacx
        'custom@hold_umbrella',
        'hold_left',
        'Parapluie 4 - Tenir a Gauche',
        AnimationOptions = {
            Prop = 'p_amb_brolly_01',
            PropBone = 60309,
            PropPlacement = {
                0.0600,
                -0.0100,
                0.0200,
                -94.3996,
                -1.7343,
                9.9656
            },
            EmoteLoop = true,
            EmoteMoving = true,
            ExitEmote = "shakeitoffhuman",
            ExitEmoteType = "Exits"
        }
    },
    -----------------------------------------------------------------------------------------------------
    ------ This is an example of an emote with 2 props, pretty simple! ----------------------------------
    -----------------------------------------------------------------------------------------------------
    ["notepad"] = {
        "missheistdockssetup1clipboard@base",
        "base",
        "Bloc-Note",
        AnimationOptions = {
            Prop = 'prop_notepad_01',
            PropBone = 18905,
            PropPlacement = {
                0.1,
                0.02,
                0.05,
                10.0,
                0.0,
                0.0
            },
            SecondProp = 'prop_pencil_01',
            SecondPropBone = 58866,
            SecondPropPlacement = {
                0.11,
                -0.02,
                0.001,
                -120.0,
                0.0,
                0.0
            },
            -- EmoteLoop is used for emotes that should loop, its as simple as that.
            -- Then EmoteMoving is used for emotes that should only play on the upperbody.
            -- The code then checks both values and sets the MovementType to the correct one
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["box"] = {
        "anim@heists@box_carry@",
        "idle",
        "Boite",
        AnimationOptions = {
            Prop = "hei_prop_heist_box",
            PropBone = 60309,
            PropPlacement = {
                0.025,
                0.08,
                0.255,
                -145.0,
                290.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gift"] = {
        "hold_flowers@dad", -- Custom Animation By Darks Animations
        "hold_flowers_clip",
        "Cadeau",
        AnimationOptions = {
            Prop = 'bzzz_prop_gift_orange',
            PropBone = 60309,
            PropPlacement = {
                0.0180,
                0.0390,
                0.1160,
                -82.4097,
                -157.5768,
                -27.6738
            },
            EmoteMoving = true
        }
    },
    ["gift2"] = {
        "hold_flowers@dad", -- Custom Animation By Darks Animations
        "hold_flowers_clip",
        "Cadeau 2",
        AnimationOptions = {
            Prop = 'bzzz_prop_gift_purple',
            PropBone = 60309,
            PropPlacement = {
                0.0180,
                0.0390,
                0.1160,
                -82.4097,
                -157.5768,
                -27.6738
            },
            EmoteMoving = true
        }
    },
    ["k12saw"] = {
        "anim@heists@fleeca_bank@drilling",
        "drill_straight_end",
        "Pompier K12 Scie",
        AnimationOptions = {
            Prop = "prop_tool_consaw",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0900,
                0.0500,
                -70.3009797,
                71.0092017,
                83.759421
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_paletoscore",
            PtfxName = "scr_paleto_box_sparks",
            PtfxNoProp = true,
            PtfxPlacement = {
                0.20,
                0.88,
                0.25,
                0.0,
                90.0,
                180.0,
                1.1
            },
            PtfxInfo = ('cut'),
            PtfxWait = 0.8,
            PtfxCanHold = false -- we set this to false, but yet it allows us to hold
        }
    },
    ["carryextinguisher"] = {
        "amb@lo_res_idles@",
        "world_human_musician_bongos_lo_res_base",
        "Pompier Extincteur",
        AnimationOptions = {
            Prop = "prop_fire_exting_1a",
            PropBone = 28422,
            PropPlacement = {
                0.1500,
                0.1400,
                -0.5200,
                179.7874004,
                -178.5954846,
                4.5961806
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["cake"] = { -- Custom Prop & Emote By BzZz
        "anim@heists@box_carry@",
        "idle",
        "Gateau Anniversaire",
        AnimationOptions = {
            Prop = 'bzzz_prop_cake_birthday_001',
            PropBone = 18905,
            PropPlacement = {
                0.33,
                0.09,
                0.2,
                -128.0,
                -245.0,
                2.0
            },
            EmoteMoving = true
        }
    },
    ["cake2"] = { -- Custom Prop & Emote By BzZz
        "anim@heists@box_carry@",
        "idle",
        "Petit Gateau",
        AnimationOptions = {
            Prop = 'bzzz_prop_cake_baby_001',
            PropBone = 18905,
            PropPlacement = {
                0.33,
                0.09,
                0.2,
                -94.0,
                -162.0,
                -44.0
            },
            EmoteMoving = true
        }
    },
    ["cake3"] = { -- Custom Prop & Emote By BzZz
        "anim@heists@box_carry@",
        "idle",
        "Gateau Casino",
        AnimationOptions = {
            Prop = 'bzzz_prop_cake_casino001',
            PropBone = 18905,
            PropPlacement = {
                0.33,
                0.09,
                0.2,
                -54.0,
                -72.0,
                -6.0
            },
            EmoteMoving = true
        }
    },
    ["cake4"] = { -- Custom Prop & Emote By BzZz
        "anim@heists@box_carry@",
        "idle",
        "Gateau Amour",
        AnimationOptions = {
            Prop = 'bzzz_prop_cake_love_001',
            PropBone = 18905,
            PropPlacement = {
                0.28,
                0.06,
                0.2,
                -54.0,
                -72.0,
                -6.0
            },
            EmoteMoving = true
        }
    },
    ["cake5"] = {
        "anim@heists@box_carry@",
        "idle",
        "Gateau Unicorn",
        AnimationOptions = { -- Custom Prop By PataMods
            Prop = 'pata_cake',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0700,
                -0.0400,
                10.0000,
                0.0000,
                0.0000
            },
            EmoteMoving = true
        }
    },
    ["cake6"] = {
        "anim@heists@box_carry@",
        "idle",
        "Gateau Pride",
        AnimationOptions = { -- Custom Prop By PataMods
            Prop = 'pata_cake2',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0700,
                -0.0400,
                10.0000,
                0.0000,
                0.0000
            },
            EmoteMoving = true
        }
    },
    ["cake7"] = { -- Custom Prop By PataMods
        "anim@heists@box_carry@",
        "idle",
        "Gateau Chocolat",
        AnimationOptions = {
            Prop = 'pata_cake3',
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                -0.0390,
                -0.0800,
                10.0000,
                0.0000,
                0.0000
            },
            EmoteMoving = true
        }
    },
    ["cakew"] = {
        "anim@move_f@waitress",
        "idle",
        "Célébration d'anniversaire",
        AnimationOptions = {
            Prop = "bzzz_prop_cake_birthday_001",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0100,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cakew2"] = { -- Custom Prop & Emote By BzZz
        "anim@move_f@waitress",
        "idle",
        "Célebration - Bébé",
        AnimationOptions = {
            Prop = "bzzz_prop_cake_baby_001",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0100,
                0.0,
                0.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cakew3"] = { -- Custom Prop & Emote By BzZz
        "anim@move_f@waitress",
        "idle",
        "Célebration - Casino",
        AnimationOptions = {
            Prop = "bzzz_prop_cake_casino001",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0100,
                0.0,
                0.0,
                -160.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cakew4"] = { -- Custom Prop & Emote By BzZz
        "anim@move_f@waitress",
        "idle",
        "Célebration - Amour",
        AnimationOptions = {
            Prop = "bzzz_prop_cake_love_001",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0100,
                0.0,
                0.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cakew5"] = {
        "anim@move_f@waitress",
        "idle",
        "Célebration - Unicorn",
        AnimationOptions = {
            Prop = "pata_cake",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.1100,
                0.0,
                0.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cakew6"] = {
        "anim@move_f@waitress",
        "idle",
        "Célebration - Pride",
        AnimationOptions = {
            Prop = "pata_cake2",
            PropBone = 28422,
            PropPlacement = {
                0.0000,
                0.0000,
                0.1100,
                0.0,
                0.0,
                20.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cakew7"] = { -- Custom Prop & Emote By BzZz
        "anim@move_f@waitress",
        "idle",
        "Célebration - Gateau Chocolat",
        AnimationOptions = {
            Prop = "pata_cake3",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.1100,
                0.0,
                0.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["rose"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Rose",
        AnimationOptions = {
            Prop = "prop_single_rose",
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.15,
                0.0,
                -100.0,
                0.0,
                -20.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dollar"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Dollar",
        AnimationOptions = {
            Prop = "p_banknote_onedollar_s",
            PropBone = 60309,
            PropPlacement = {
                -0.0020,
                -0.0030,
                0.0320,
                82.2434,
                -106.9746,
                1.3733
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["balloon"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Ballon",
        AnimationOptions = {
            Prop = "heart_balloon",
            PropBone = 60309,
            PropPlacement = {
                0.25,
                -0.84,
                0.53,
                -157.2041,
                -101.1702,
                28.0243
            },
            EmoteStuck = true,
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["balloon2"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Ballon 2 - Pride",
        AnimationOptions = {
            Prop = "pride_heart_balloon",
            PropBone = 60309,
            PropPlacement = {
                1.0600,
                0.4900,
                0.0140,
                73.5103,
                -30.9638,
                19.3946
            },
            EmoteStuck = true,
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["smoke2"] = {
        "amb@world_human_aa_smoke@male@idle_a",
        "idle_c",
        "Fumer 2",
        AnimationOptions = {
            Prop = 'ng_proc_cigarette01a',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["smoke3"] = {
        "amb@world_human_aa_smoke@male@idle_a",
        "idle_b",
        "Fumer 3",
        AnimationOptions = {
            Prop = 'ng_proc_cigarette01a',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["smoke4"] = {
        "amb@world_human_smoking@female@idle_a",
        "idle_b",
        "Fumer 4",
        AnimationOptions = {
            Prop = 'ng_proc_cigarette01a',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["smoke5"] = { -- Custom Emote Provided To RPEmotes By Mr Witt
        "mrwitt@composed_photo_moments",
        "mrwitt",
        "Fumer 5",
        AnimationOptions = {
            Prop = 'ng_proc_cigarette01a',
            PropBone = 64097,
            PropPlacement = {
                0.0020,
                0.0010,
                -0.0090,
                0.0,
                0.0,
                50.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["smoke6"] = {
        "anim@amb@carmeet@checkout_car@",
        "smoke_male_a_idle_b",
        "Fumer 6",
        AnimationOptions = {
            Prop = 'ng_proc_cigarette01a',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["vape"] = {
        "amb@world_human_smoking@male@male_b@base",
        "base",
        "Vapoter",
        AnimationOptions = {
            Prop = 'ba_prop_battle_vape_01',
            PropBone = 28422,
            PropPlacement = {
                -0.0290,
                0.0070,
                -0.0050,
                91.0,
                270.0,
                -360.0
            },
            EmoteMoving = true,
            EmoteLoop = true,
            PtfxAsset = "scr_agencyheistb",
            PtfxName = "scr_agency3b_elec_box",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.170,
                0.0,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('vape'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["vape2"] = {
        "amb@world_human_smoking@male@male_b@base",
        "base",
        "Vapoter 2",
        AnimationOptions = {
            Prop = 'xm3_prop_xm3_vape_01a',
            PropBone = 28422,
            PropPlacement = {
                -0.02,
                -0.02,
                0.02,
                58.0,
                110.0,
                10.0
            },
            EmoteMoving = true,
            EmoteLoop = true,
            PtfxAsset = "scr_agencyheistb",
            PtfxName = "scr_agency3b_elec_box",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.170,
                0.0,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('vape'),
            PtfxWait = 1.8,
            PtfxCanHold = true
        }
    },
    ["bong"] = {
        "anim@safehouse@bong",
        "bong_stage3",
        "Fumer Bong",
        AnimationOptions = {
            Prop = 'prop_bong_01',
            PropBone = 18905,
            PropPlacement = {
                0.10,
                -0.25,
                0.0,
                95.0,
                190.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_agencyheistb",
            PtfxName = "scr_agency3b_elec_box",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.170,
                0.0,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('vape'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["bong2"] = {
        "anim@safehouse@bong",
        "bong_stage3",
        "Fumer Bong 2",
        AnimationOptions = {
            Prop = 'xm3_prop_xm3_bong_01a',
            PropBone = 18905,
            PropPlacement = {
                0.10,
                -0.25,
                0.0,
                95.0,
                190.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_agencyheistb",
            PtfxName = "scr_agency3b_elec_box",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.170,
                0.0,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('vape'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["bong3"] = {
        "sit_bong@dark",
        "sit_bong_clip",
        "Fumer Bong 3 - Assis & Fumer",
        AnimationOptions = {
            Prop = 'prop_bong_01',
            PropBone = 60309,
            PropPlacement = {
                0.0490,
                -0.2000,
                0.0800,
                -85.0199,
                102.3320,
                -15.0085
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_agencyheistb",
            PtfxName = "scr_agency3b_elec_box",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.170,
                0.0,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('vape'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["bong4"] = {
        "sit_bong@dark",
        "sit_bong_clip",
        "Fumer Bong 4 - Assis & Fumer Violet",
        AnimationOptions = {
            Prop = 'xm3_prop_xm3_bong_01a',
            PropBone = 60309,
            PropPlacement = {
                0.0490,
                -0.2000,
                0.0800,
                -85.0199,
                102.3320,
                -15.0085
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_agencyheistb",
            PtfxName = "scr_agency3b_elec_box",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.170,
                0.0,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('vape'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["joint2"] = { -- Custom Emote Provided To RPEmotes By Sel of Darks Animations
        "smoke_m@sel",
        "smoke_m_clip",
        "Passer le Joint",
        AnimationOptions = {
            Prop = 'p_cs_joint_01',
            PropBone = 26612,
            PropPlacement = {
                0.0540,
                -0.0120,
                0.0480,
                172.3040,
                -131.4506,
                45.1778
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.5,
            PtfxCanHold = true
        }
    },
    ["fishing1"] = {
        "amb@world_human_stand_fishing@idle_a",
        "idle_a",
        "Pêcher 1",
        AnimationOptions = {
            Prop = 'prop_fishing_rod_01',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["fishing2"] = {
        "amb@world_human_stand_fishing@idle_a",
        "idle_b",
        "Pêcher 2",
        AnimationOptions = {
            Prop = 'prop_fishing_rod_01',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["fishing3"] = {
        "amb@world_human_stand_fishing@idle_a",
        "idle_c",
        "Pêcher 3",
        AnimationOptions = {
            Prop = 'prop_fishing_rod_01',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["icefishing"] = { -- Custom Emote By EP
        "timetable@ron@ig_3_couch",
        "base",
        "Pêche sur Glace",
        AnimationOptions = {
            Prop = 'pprp_icefishing_box_02',
            PropBone = 0,
            PropPlacement = {
                -0.05,
                0.0,
                -0.63,
                7.0,
                0.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["icefishing2"] = { -- Custom Emote By EP
        "move_weapon@jerrycan@generic",
        "idle",
        "Pêche sur Glace 2",
        AnimationOptions = {
            Prop = 'pprp_icefishing_box_01',
            PropBone = 28422,
            PropPlacement = {
                0.8,
                0.03,
                0.04,
                0.0,
                -90.0,
                100.0
            },
            SecondProp = 'pprp_icefishing_augur',
            SecondPropBone = 24818,
            SecondPropPlacement = {
                -0.8,
                -0.2,
                0.0,
                0.0,
                90.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["suitcase"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Malette",
        AnimationOptions = {
            Prop = "prop_ld_suitcase_01",
            PropBone = 57005,
            PropPlacement = {
                0.35,
                0.0,
                0.0,
                0.0,
                266.0,
                90.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["suitcase2"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Malette 2",
        AnimationOptions = {
            Prop = "prop_security_case_01",
            PropBone = 57005,
            PropPlacement = {
                0.13,
                0.0,
                -0.01,
                0.0,
                280.0,
                90.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["boombox"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boombox",
        AnimationOptions = {
            Prop = "prop_ghettoblast_02",
            PropBone = 57005,
            PropPlacement = {
                0.27,
                0.0,
                0.0,
                0.0,
                263.0,
                58.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["boombox2"] = {
        "molly@boombox1",
        "boombox1_clip",
        "Boombox 2",
        AnimationOptions = {
            Prop = "prop_cs_sol_glasses",
            PropBone = 31086,
            PropPlacement = {
                0.0440,
                0.0740,
                0.0000,
                -160.9843,
                -88.7288,
                -0.6197
            },
            SecondProp = 'prop_ghettoblast_02',
            SecondPropBone = 10706,
            SecondPropPlacement = {
                -0.2310,
                -0.0770,
                0.2410,
                -179.7256,
                176.7406,
                23.0190
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["toolbox"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boite a Outil",
        AnimationOptions = {
            Prop = "prop_tool_box_04",
            PropBone = 28422,
            PropPlacement = {
                0.3960,
                0.0410,
                -0.0030,
                -90.00,
                0.0,
                90.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["toolbox2"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boite a Outil 2",
        AnimationOptions = {
            Prop = "imp_prop_tool_box_01a",
            PropBone = 28422,
            PropPlacement = {
                0.3700,
                0.0200,
                0.0,
                90.00,
                0.0,
                -90.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["toolbox3"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boite a Outil 3",
        AnimationOptions = {
            Prop = "xm3_prop_xm3_tool_box_01a",
            PropBone = 28422,
            PropPlacement = {
                0.3700,
                0.0200,
                0.0,
                90.00,
                0.0,
                -90.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["toolbox4"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boite a Outil 4",
        AnimationOptions = {
            Prop = "xm3_prop_xm3_tool_box_02a",
            PropBone = 28422,
            PropPlacement = {
                0.3700,
                0.0200,
                0.0,
                90.00,
                0.0,
                -90.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cashbox"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boite Argent",
        AnimationOptions = {
            Prop = "m23_1_prop_m31_cashbox_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0550,
                0.0090,
                -0.0100,
                90.00,
                0.0,
                -81.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gbag"] = {
        "missfbi4prepp1",
        "_idle_garbage_man",
        "Sac de Poubelle",
        AnimationOptions = {
            Prop = "prop_cs_street_binbag_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0400,
                -0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beerbox"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Pack Bière 1",
        AnimationOptions = {
            Prop = "v_ret_ml_beerdus",
            PropBone = 57005,
            PropPlacement = {
                0.22,
                0.0,
                0.0,
                0.0,
                266.0,
                48.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beerbox2"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Pack Bière 2",
        AnimationOptions = {
            Prop = "v_ret_ml_beeram",
            PropBone = 57005,
            PropPlacement = {
                0.22,
                0.0,
                0.0,
                0.0,
                266.0,
                48.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beerbox3"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Pack Bière 3",
        AnimationOptions = {
            Prop = "v_ret_ml_beerpride",
            PropBone = 57005,
            PropPlacement = {
                0.22,
                0.0,
                0.0,
                0.0,
                266.0,
                48.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beerbox4"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Pack Bière 4",
        AnimationOptions = {
            Prop = "v_ret_ml_beerbar",
            PropBone = 57005,
            PropPlacement = {
                0.22,
                0.0,
                0.0,
                0.0,
                266.0,
                60.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mugshot"] = {
        "mp_character_creation@customise@male_a",
        "loop",
        "Photo d'identité",
        AnimationOptions = {
            Prop = 'prop_police_id_board',
            PropBone = 58868,
            PropPlacement = {
                0.12,
                0.24,
                0.0,
                5.0,
                0.0,
                70.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["coffee"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Café",
        AnimationOptions = {
            Prop = 'p_amb_coffeecup_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["coffeecall"] = {
        "switch@michael@coffee_w_dave",
        "002291_02_fbi_3_coffee_w_dave_idle_dave",
        "Appel & Téléphone",
        AnimationOptions = {
            Prop = 'p_ing_coffeecup_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0140,
                0.0,
                0.0,
                90.0
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7},
            },
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["whiskey"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Whisky",
        AnimationOptions = {
            Prop = 'prop_drink_whisky',
            PropBone = 28422,
            PropPlacement = {
                0.01,
                -0.01,
                -0.06,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["whiskeyb"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_a",
        "Bouteille Whisky",
        AnimationOptions = {
            Prop = 'ba_prop_battle_whiskey_bottle_2_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.05,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beer"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_c",
        "Bière",
        AnimationOptions = {
            Prop = 'prop_amb_beer_bottle',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.06,
                0.0,
                15.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beer2"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_c",
        "Bière 2",
        AnimationOptions = {
            Prop = 'prop_amb_beer_bottle',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.06,
                0.0,
                15.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beer3"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_a",
        "Bière 3",
        AnimationOptions = {
            Prop = 'p_cs_bottle_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beer4"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_b",
        "Bière 4 - Une pour nos gars",
        AnimationOptions = {
            Prop = 'p_cs_bottle_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["beer5"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_c",
        "Bière 5",
        AnimationOptions = {
            Prop = 'p_cs_bottle_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["whiskeyb2"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_a",
        "Bouteille Whisky 2",
        AnimationOptions = {
            Prop = 'ba_prop_battle_whiskey_bottle_2_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.05,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["whiskeyb3"] = {
        "amb@world_human_drinking@beer@male@idle_a",
        "idle_a",
        "Bouteille Whisky 3",
        AnimationOptions = {
            Prop = 'ba_prop_battle_whiskey_bottle_2_s',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.05,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["beerf"] = {
        "amb@world_human_drinking@beer@female@idle_a",
        "idle_a",
        "Bière Femme",
        AnimationOptions = {
            Prop = 'prop_amb_beer_bottle',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0,
                0.05,
                15.0,
                15.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beercan"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Canette de Bière",
        AnimationOptions = {
            Prop = 'v_res_tt_can01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beercan2"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Canette de Bière 2",
        AnimationOptions = {
            Prop = 'v_res_tt_can02',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                -150.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beercan3"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Canette de Bière 3",
        AnimationOptions = {
            Prop = 'h4_prop_h4_can_beer_01a',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0700,
                0.0,
                0.0,
                90.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wine2"] = {
        "amb@world_human_drinking@beer@female@idle_a",
        "idle_e",
        "Vin 2 - Bouteille",
        AnimationOptions = {
            Prop = 'prop_wine_rose',
            PropBone = 28422,
            PropPlacement = {
                -0.0,
                0.04,
                -0.19,
                10.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            --       PropPlacement = {-0.0, 0.03, -0.20, 5.0, 0.0, 0.0},
            --     F&B   L&R   U&D  R.F&B
        }
    },
    ["beerf3"] = {
        "amb@world_human_drinking@beer@female@idle_a",
        "idle_a",
        "Bière Femme 3",
        AnimationOptions = {
            Prop = 'prop_amb_beer_bottle',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0,
                0.05,
                15.0,
                15.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["beerf4"] = {
        "fix_stu_ext-1",
        "a_f_y_studioparty_01^1_dual-1",
        "Bière Femme 4",
        AnimationOptions = {
            Prop = 'prop_amb_beer_bottle',
            PropBone = 28422,
            PropPlacement = {
                0.08,
                0.11,
                0.0,
                -74.0,
                0.0,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["beerf5"] = {
        "anim@scripted@freemode_npc@fix_dre_studio_entourage_b@",
        "stand_drink_cup_female_a_base",
        "Bière Femme 5",
        AnimationOptions = {
            Prop = 'prop_amb_beer_bottle',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0,
                0.05,
                15.0,
                15.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["wine3"] = {
        "amb@world_human_drinking@beer@female@idle_a",
        "idle_e",
        "Vin 3 - Bouteille",
        AnimationOptions = {
            Prop = 'prop_wine_rose',
            PropBone = 28422,
            PropPlacement = {
                -0.0,
                0.04,
                -0.19,
                10.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["cup"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Gobelet",
        AnimationOptions = {
            Prop = 'prop_plastic_cup_02',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["apple"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Pomme",
        AnimationOptions = {
            Prop = 'sf_prop_sf_apple_01b',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0150,
                -0.0200,
                -124.6964,
                -166.5760,
                8.4572
            },
            EmoteMoving = true
        }
    },
    ["taco"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Tacos",
        AnimationOptions = {
            Prop = 'prop_taco_01',
            PropBone = 60309,
            PropPlacement = {
                -0.0170,
                0.0070,
                -0.0210,
                107.9846,
                -105.0251,
                55.7779
            },
            EmoteMoving = true
        }
    },
    ["hotdog"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Hotdog",
        AnimationOptions = {
            Prop = 'prop_cs_hotdog_02',
            PropBone = 60309,
            PropPlacement = {
                -0.0300,
                0.0100,
                -0.0100,
                95.1071,
                94.7001,
                -66.9179
            },
            EmoteMoving = true
        }
    },
    ["bagel"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Bagel",
        AnimationOptions = {
            Prop = 'p_ing_bagel_01',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.05,
                0.03,
                145.3975,
                -53.8984,
                4.8412
            },
            EmoteMoving = true
        }
    },
    ["donut"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Donut",
        AnimationOptions = {
            Prop = 'prop_amb_donut',
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.05,
                0.02,
                -50.0,
                16.0,
                60.0
            },
            EmoteMoving = true
        }
    },
    ["donut2"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Donut Chocolat",
        AnimationOptions = {
            Prop = 'bzzz_foodpack_donut002',
            PropBone = 60309,
            PropPlacement = {
                0.0000,
                -0.0300,
                -0.0100,
                10.0000,
                0.0000,
                -1.0000
            },
            EmoteMoving = true
        }
    },
    ["donut3"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Donut Framboise",
        AnimationOptions = {
            Prop = 'bzzz_foodpack_donut001',
            PropBone = 60309,
            PropPlacement = {
                0.0000,
                -0.0300,
                -0.0100,
                10.0000,
                0.0000,
                -1.0000
            },
            EmoteMoving = true
        }
    },
    ["desert"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Manger Dessert",
        AnimationOptions = {
            Prop = 'bzzz_food_dessert_a',
            PropBone = 18905,
            PropPlacement = {
                0.15,
                0.03,
                0.03,
                -42.0,
                -36.0,
                0.0
            },
            EmoteMoving = true
        }
    },
    ["croissant"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Croissant",
        AnimationOptions = {
            Prop = 'bzzz_foodpack_croissant001',
            PropBone = 60309,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.0100,
                0.0000,
                0.0000,
                90.0000
            },
            EmoteMoving = true
        }
    },
    ["gingerbread"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Pain d'épice",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_gingerbread_a',
            PropBone = 18905,
            PropPlacement = {
                0.16,
                0.04,
                0.03,
                18.0,
                164.0,
                -5.0
            },
            EmoteMoving = true
        }
    },
    ["candycane"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Canne en bonbon - Rouge",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_lollipop_a',
            PropBone = 18905,
            PropPlacement = {
                0.16,
                0.02,
                0.03,
                -73.0,
                146.0,
                -5.0
            },
            EmoteMoving = true
        }
    },
    ["candycaneb"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Canne en bonbon - Vert",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_lollipop_b',
            PropBone = 18905,
            PropPlacement = {
                0.16,
                0.02,
                0.03,
                -73.0,
                146.0,
                -5.0
            },
            EmoteMoving = true
        }
    },
    ["candycanec"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Canne en bonbon - Violet",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_lollipop_c',
            PropBone = 18905,
            PropPlacement = {
                0.16,
                0.02,
                0.03,
                -73.0,
                146.0,
                -5.0
            },
            EmoteMoving = true
        }
    },
    ["candycaned"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Canne en bonbon - Jaune",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_lollipop_d',
            PropBone = 18905,
            PropPlacement = {
                0.16,
                0.02,
                0.03,
                -73.0,
                146.0,
                -5.0
            },
            EmoteMoving = true
        }
    },
    ["candycanee"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Canne en bonbon - Bleu",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_lollipop_e',
            PropBone = 18905,
            PropPlacement = {
                0.16,
                0.02,
                0.03,
                -73.0,
                146.0,
                -5.0
            },
            EmoteMoving = true
        }
    },
    ["meat"] = {
        "move_crouch_proto",
        "idle",
        "Viande sur un bâton",
        AnimationOptions = {
            Prop = 'bzzz_camp_stick_kebab',
            PropBone = 64080,
            PropPlacement = {
                0.0600,
                0.0500,
                -0.1600,
                17.0651,
                -30.9089,
                60.0374
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["meat2"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Viande sur un fourchette",
        AnimationOptions = {
            Prop = 'bzzz_camp_food_kebab',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.02,
                0.01,
                -24.0,
                -80.0,
                9.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mallow"] = {
        "move_crouch_proto",
        "idle",
        "Bâton Marshmallow - Blanc",
        AnimationOptions = {
            Prop = 'bzzz_camp_stick_marshmallow',
            PropBone = 64080,
            PropPlacement = {
                0.0600,
                0.0500,
                -0.1600,
                17.0651,
                -30.9089,
                60.0374
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mallow2"] = {
        "move_crouch_proto",
        "idle",
        "Bâton Marshmallow - Rose",
        AnimationOptions = {
            Prop = 'bzzz_camp_stick_mellopink',
            PropBone = 64080,
            PropPlacement = {
                0.0600,
                0.0500,
                -0.1600,
                17.0651,
                -30.9089,
                60.0374
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mallow3"] = {
        "move_crouch_proto",
        "idle",
        "Bâton Marshmallow - Brulé",
        AnimationOptions = {
            Prop = 'bzzz_camp_stick_melloburnt',
            PropBone = 64080,
            PropPlacement = {
                0.0600,
                0.0500,
                -0.1600,
                17.0651,
                -30.9089,
                60.0374
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mallow4"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Fourchette Marshmallow - Blanc",
        AnimationOptions = {
            Prop = 'bzzz_camp_food_marshmallow',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.02,
                0.01,
                -24.0,
                -80.0,
                9.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mallow5"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Fourchette Marshmallow - Rose",
        AnimationOptions = {
            Prop = 'bzzz_camp_food_mellopink',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.02,
                0.01,
                -24.0,
                -80.0,
                9.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mallow6"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Fourchette Marshmallow - Brulé",
        AnimationOptions = {
            Prop = 'bzzz_camp_food_melloburnt',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.02,
                0.01,
                -24.0,
                -80.0,
                9.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["macaroon"] = { -- Custom Prop by BzZz
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Macaron",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_macaroon_a',
            PropBone = 18905,
            PropPlacement = {
                0.15,
                0.07,
                0.00,
                38.0,
                7.0,
                7.0
            },
            EmoteMoving = true
        }
    },
    ["xmasmug"] = { -- Custom Prop by BzZz
        "mp_player_intdrink",
        "loop_bottle",
        "Xmas Tasse - Thé",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_mug_a',
            PropBone = 18905,
            PropPlacement = {
                0.09,
                -0.01,
                0.08,
                -44.0,
                137.0,
                9.0
            },
            EmoteMoving = true
        }
    },
    ["xmasmug2"] = { -- Custom Prop by BzZz
        "mp_player_intdrink",
        "loop_bottle",
        "Xmas Tasse - Café",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_mug_b',
            PropBone = 18905,
            PropPlacement = {
                0.09,
                -0.01,
                0.08,
                -44.0,
                137.0,
                9.0
            },
            EmoteMoving = true
        }
    },
    ["xmaswine"] = { -- Custom Prop by BzZz
        "mp_player_intdrink",
        "loop_bottle",
        "Xmas Vin Chaud",
        AnimationOptions = {
            Prop = 'bzzz_food_xmas_mulled_wine_a',
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.03,
                0.05,
                -110.0,
                -47.0,
                7.0
            },
            EmoteMoving = true
        }
    },
    ["cocoa"] = {
        "amb@world_human_aa_coffee@base",
        "base",
        "Xmas Chocolat",
        AnimationOptions = {
            Prop = 'pata_christmasfood1',
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.1100,
                -0.1300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["xmassf"] = { -- Custom Prop by PataMods
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Cookie Neige",
        AnimationOptions = {
            Prop = 'pata_christmasfood2',
            PropBone = 60309,
            PropPlacement = {
                0.0200,
                -0.0500,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteMoving = true
        }
    },
    ["xmascc"] = { -- Custom Prop by PataMods
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Cupcake",
        AnimationOptions = {
            Prop = 'pata_christmasfood6',
            PropBone = 60309,
            PropPlacement = {
                0.0100,
                0.0200,
                -0.0100,
                -170.1788,
                87.6716,
                30.0540
            },
            EmoteMoving = true
        }
    },
    ["xmascc2"] = { -- Custom Prop by PataMods
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Xmas Cupcake 2",
        AnimationOptions = {
            Prop = 'pata_christmasfood8',
            PropBone = 60309,
            PropPlacement = {
                0.0200,
                0.0,
                -0.0100,
                9.3608,
                -90.1809,
                66.3689
            },
            EmoteMoving = true
        }
    },
    ["xmasic"] = {
        "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1",
        "base_idle",
        "Xmas Glâce",
        AnimationOptions = {
            Prop = "pata_christmasfood7",
            PropBone = 60309,
            PropPlacement = {
                -0.0460,
                0.0000,
                -0.0300,
                0.0,
                0.0,
                -50.0000
            },
            SecondProp = 'h4_prop_h4_coke_spoon_01',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                20.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pizzaslice"] = { -- Custom Prop by knjgh
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Part Pizza - Jalapenos & Pepperoni",
        AnimationOptions = {
            Prop = 'knjgh_pizzaslice1',
            PropBone = 60309,
            PropPlacement = {
                0.0500,
                -0.0200,
                -0.0200,
                73.6928,
                -66.7427,
                68.3677
            },
            EmoteMoving = true
        }
    },
    ["pizzas"] = { -- Custom Prop by knjgh
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Part Pizza - Jalapeño & Peperoni",
        AnimationOptions = {
            Prop = 'knjgh_pizzaslice1',
            PropBone = 60309,
            PropPlacement = {
                0.0500,
                -0.0200,
                -0.0200,
                73.6928,
                -66.7427,
                68.3677
            },
            EmoteMoving = true
        }
    },
    ["pizzas2"] = { -- Custom Prop by knjgh
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Part Pizza - Tomatz & Pesto",
        AnimationOptions = {
            Prop = 'knjgh_pizzaslice2',
            PropBone = 60309,
            PropPlacement = {
                0.0500,
                -0.0200,
                -0.0200,
                73.6928,
                -66.7427,
                68.3677
            },
            EmoteMoving = true
        }
    },
    ["pizzas3"] = { -- Custom Prop by knjgh
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Part Pizza - Champignon",
        AnimationOptions = {
            Prop = 'knjgh_pizzaslice3',
            PropBone = 60309,
            PropPlacement = {
                0.0500,
                -0.0200,
                -0.0200,
                73.6928,
                -66.7427,
                68.3677
            },
            EmoteMoving = true
        }
    },
    ["pizzas4"] = { -- Custom Prop by knjgh
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Part Pizza - Margherita",
        AnimationOptions = {
            Prop = 'knjgh_pizzaslice4',
            PropBone = 60309,
            PropPlacement = {
                0.0500,
                -0.0200,
                -0.0200,
                73.6928,
                -66.7427,
                68.3677
            },
            EmoteMoving = true
        }
    },
    ["pizzas5"] = { -- Custom Prop by knjgh
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Part Pizza - Double Peperoni",
        AnimationOptions = {
            Prop = 'knjgh_pizzaslice5',
            PropBone = 60309,
            PropPlacement = {
                0.0500,
                -0.0200,
                -0.0200,
                73.6928,
                -66.7427,
                68.3677
            },
            EmoteMoving = true
        }
    },
    ["eat"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Manger",
        AnimationOptions = {
            Prop = 'prop_cs_burger_01',
            PropBone = 60309,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.0200,
                30.0000,
                0.0000,
                0.0000,
            },
            EmoteMoving = true
        }
    },
    ["burger"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Burger",
        AnimationOptions = {
            Prop = 'prop_cs_burger_01',
            PropBone = 60309,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.0200,
                30.0000,
                0.0000,
                0.0000,
            },
            EmoteMoving = true
        }
    },
    ["burgerpose"] = { -- Custom Emote By Dark Animations exclusive to RPEmotes exclusive to RPEmotes
        "brugershot_dark_fixed@dark",
        "brugershot_dark_fixed_clip",
        "Burger - Pose",
        AnimationOptions = {
            Prop = 'prop_cs_burger_01',
            PropBone = 60309,
            PropPlacement = {
                0.0460,
                0.0140,
                0.0460,
                3.4346,
                20.1823,
                -10.000
            },
            SecondProp = 'ba_prop_battle_sports_helmet',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0400,
                -0.0100,
                -0.2000,
                176.3835,
                -169.3724,
                19.6834
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sandwich"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sandwich",
        AnimationOptions = {
            Prop = 'prop_sandwich_01',
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.05,
                0.02,
                -50.0,
                16.0,
                60.0
            },
            EmoteMoving = true
        }
    },
    ["soda"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Soda - Canette eCola",
        AnimationOptions = {
            Prop = 'prop_ecola_can',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                130.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda2"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Soda 2 - Canette Sprunk",
        AnimationOptions = {
            Prop = 'ng_proc_sodacan_01b',
            PropBone = 28422,
            PropPlacement = {
                0.0050,
                -0.0010,
                -0.0800,
                0.0,
                0.0,
                160.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda3"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda 3 - Gobelet P's & Q's",
        AnimationOptions = {
            Prop = 'v_ret_fh_bscup',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0400,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda4"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda 4 - Gobelet Burger Shot",
        AnimationOptions = {
            Prop = 'prop_cs_bs_cup',
            PropBone = 28422,
            PropPlacement = {
                0.0060,
                0.0010,
                0.0,
                0.0,
                0.0,
                -150.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda5"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda 5 - Gobelet Hercules Power Fuel",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda03',
            PropBone = 28422,
            PropPlacement = {
                0.0060,
                0.0010,
                0.0,
                0.0,
                0.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda6"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda 6 - Gobelet Orang-O-Tang",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda04',
            PropBone = 28422,
            PropPlacement = {
                0.0060,
                0.0010,
                0.0,
                0.0,
                0.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda7"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda 7- Gobelet Junk",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda01',
            PropBone = 28422,
            PropPlacement = {
                0.0060,
                0.0010,
                0.0,
                0.0,
                0.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda8"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda 8 - Gobelet Junk",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda02',
            PropBone = 28422,
            PropPlacement = {
                0.0060,
                0.0010,
                0.0,
                0.0,
                0.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["soda9"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Soda 9 - Canette Jus D'orange",
        AnimationOptions = {
            Prop = 'prop_orang_can_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                130.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["boba"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Thé à bulles",
        AnimationOptions = {
            Prop = 'scully_boba',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["boba2"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Thé à bulles 2",
        AnimationOptions = {
            Prop = 'scully_boba2',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["boba3"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Thé à bulles 3",
        AnimationOptions = {
            Prop = 'scully_boba3',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipsoda"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Canette Soda - Junk",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda01',
            PropBone = 28422,
            PropPlacement = {
                0.0470,
                0.0040,
                -0.0600,
                -88.0263,
                -25.0367,
                -27.3898
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipsodab"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Canette Soda - Sprunk",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda02',
            PropBone = 28422,
            PropPlacement = {
                0.0470,
                0.0040,
                -0.0600,
                -88.0263,
                -25.0367,
                -27.3898
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipsodac"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Canette Soda - Hercules Power Fuel",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda03',
            PropBone = 28422,
            PropPlacement = {
                0.0470,
                0.0040,
                -0.0600,
                -88.0263,
                -25.0367,
                -27.3898
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipsodad"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Canette Soda - Orang-O-Tang",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda04',
            PropBone = 28422,
            PropPlacement = {
                0.0470,
                0.0040,
                -0.0600,
                -88.0263,
                -25.0367,
                -27.3898
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipsodae"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Canette Soda - eCola",
        AnimationOptions = {
            Prop = 'rpemotesreborn_soda05',
            PropBone = 28422,
            PropPlacement = {
                0.0470,
                0.0040,
                -0.0600,
                -88.0263,
                -25.0367,
                -27.3898
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dbsoda"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Soda - Dumb Bitch",
        AnimationOptions = {
            Prop = 'dumbbitchjuice',
            PropBone = 28422,
            PropPlacement = {
                0.0060,
                -0.0020,
                -0.0700,
                180.0000,
                180.0000,
                -10.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mojito"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Mojito",
        AnimationOptions = {
            Prop = 'prop_mojito',
            PropBone = 28422,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.0900,
                0.0000,
                0.0000,
                130.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["frappe"] = {
        "amb@code_human_wander_drinking@male@base",
        "static",
        "Frappé",
        AnimationOptions = {
            Prop = 'brum_heartfrappe',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0150,
                -0.0100,
                0.0,
                -3.9999,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["frappe2"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Frappé 2",
        AnimationOptions = {
            Prop = 'beanmachine_cup',
            PropBone = 28422,
            PropPlacement = {
                0.0110,
                0.0,
                0.0300,
                0.0,
                0.0,
                -140.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["frappe3"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Frappé 3",
        AnimationOptions = {
            Prop = 'beanmachine_cup2',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0600,
                0.0,
                0.0,
                -178.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["frappe4"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Frappé 4",
        AnimationOptions = {
            Prop = 'beanmachine_cup3',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0600,
                0.0,
                0.0,
                -178.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["edrink"] = {
        "mp_player_intdrink",
        "loop_bottle",
        "Boisson Energisante - Bouteille",
        AnimationOptions =
        {
            Prop = "prop_energy_drink",
            PropBone = 60309,
            PropPlacement = {
                0.0080,
                0.0010,
                0.0160,
                3.5690,
                4.6611,
                -49.9065
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["edrink2"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Boisson Energisante - Canette",
        AnimationOptions =
        {
            Prop = "sf_prop_sf_can_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                -110.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["edrink3"] = {
        "amb@world_human_drinking@coffee@male@idle_a",
        "idle_c",
        "Boisson Energisante - Canette XXL",
        AnimationOptions =
        {
            Prop = "sf_p_sf_grass_gls_s_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.1400,
                0.0000,
                0.0000,
                9.0000
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["mshake"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Bubblegum",
        AnimationOptions = {
            Prop = 'brum_cherryshake_bubblegum',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakeb"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Cerise",
        AnimationOptions = {
            Prop = 'brum_cherryshake_cherry',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakec"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Chocolat",
        AnimationOptions = {
            Prop = 'brum_cherryshake_chocolate',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshaked"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Café",
        AnimationOptions = {
            Prop = 'brum_cherryshake_coffee',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakee"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Double Chocolat",
        AnimationOptions = {
            Prop = 'brum_cherryshake_doublechocolate',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakef"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Frappé",
        AnimationOptions = {
            Prop = 'brum_cherryshake_frappe',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakeg"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Citron",
        AnimationOptions = {
            Prop = 'brum_cherryshake_lemon',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakeh"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Menthe",
        AnimationOptions = {
            Prop = 'brum_cherryshake_mint',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakei"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Fraise",
        AnimationOptions = {
            Prop = 'brum_cherryshake_strawberry',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakej"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Framboise",
        AnimationOptions = {
            Prop = 'brum_cherryshake_raspberry',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakek"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Salé",
        AnimationOptions = {
            Prop = 'brum_cherryshake_salted',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mshakel"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Milkshake - Vanille",
        AnimationOptions = {
            Prop = 'brum_cherryshake_vanilla',
            PropBone = 28422,
            PropPlacement = {
                0.0030,
                0.0280,
                0.0800,
                -180.0,
                -180.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshake"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Bubblegum",
        AnimationOptions = {
            Prop = 'brum_cherryshake_raspberry',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakeb"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Cerise",
        AnimationOptions = {
            Prop = 'brum_cherryshake_cherry',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakec"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Chocolat",
        AnimationOptions = {
            Prop = 'brum_cherryshake_chocolate',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshaked"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Café",
        AnimationOptions = {
            Prop = 'brum_cherryshake_coffee',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakee"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Double Chocolat",
        AnimationOptions = {
            Prop = 'brum_cherryshake_doublechocolate',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakef"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Frappé",
        AnimationOptions = {
            Prop = 'brum_cherryshake_frappe',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakeg"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Citron",
        AnimationOptions = {
            Prop = 'brum_cherryshake_lemon',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakeh"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Menthe",
        AnimationOptions = {
            Prop = 'brum_cherryshake_mint',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakei"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Fraise",
        AnimationOptions = {
            Prop = 'brum_cherryshake_strawberry',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakej"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Framboise",
        AnimationOptions = {
            Prop = 'brum_cherryshake_raspberry',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakek"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Salé",
        AnimationOptions = {
            Prop = 'brum_cherryshake_salted',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sipshakel"] = {
        "smo@milkshake_idle",
        "milkshake_idle_clip",
        "Sirotter Milkshake - Vanille",
        AnimationOptions = {
            Prop = 'brum_cherryshake_vanilla',
            PropBone = 28422,
            PropPlacement = {
                0.0850,
                0.0670,
                -0.0350,
                -115.0862,
                -165.7841,
                24.1318
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sodafu"] = {
        "anim@male_drinking_01",
        "m_drinking_01_clip",
        "Soda Doigt D'honneur eCola",
        AnimationOptions = {
            Prop = 'prop_ecola_can',
            PropBone = 26613,
            PropPlacement = {
                0.0400,
                -0.0500,
                0.0390,
                0.0000,
                0.000,
                -69.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sodafu2"] = {
        "anim@male_drinking_01",
        "m_drinking_01_clip",
        "Soda Doigt D'honneur Sprunk",
        AnimationOptions = {
            Prop = 'ng_proc_sodacan_01b',
            PropBone = 26613,
            PropPlacement = {
                0.0300,
                -0.0600,
                -0.0700,
                0.0000,
                0.000,
                0.000,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["water"] = {
        "mp_player_intdrink",
        "loop_bottle",
        "Bouteille d'Eau",
        AnimationOptions =
        {
            Prop = "vw_prop_casino_water_bottle_01a",
            PropBone = 60309,
            PropPlacement = {
                0.012,
                0.028,
                -0.077,
                4.438,
                0.194,
                -0.878
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["egobar"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Barre Ego",
        AnimationOptions = {
            Prop = 'prop_choc_ego',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteMoving = true
        }
    },
    ["lollipop1"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sucette Rouge",
        AnimationOptions = {
            Prop = 'natty_lollipop_spiral01',
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                -0.0100,
                -175.1935,
                97.6975,
                20.9598
            },
            EmoteMoving = true
        }
    },
    ["lollipop1b"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sucette Rose",
        AnimationOptions = {
            Prop = 'natty_lollipop_spiral02',
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                -0.0100,
                -175.1935,
                97.6975,
                20.9598
            },
            EmoteMoving = true
        }
    },
    ["lollipop1c"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sucette Vert",
        AnimationOptions = {
            Prop = 'natty_lollipop_spiral03',
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                -0.0100,
                -175.1935,
                97.6975,
                20.9598
            },
            EmoteMoving = true
        }
    },
    ["lollipop1d"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sucette Bleu",
        AnimationOptions = {
            Prop = 'natty_lollipop_spiral04',
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                -0.0100,
                -175.1935,
                97.6975,
                20.9598
            },
            EmoteMoving = true
        }
    },
    ["lollipop1e"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sucette Jaune",
        AnimationOptions = {
            Prop = 'natty_lollipop_spiral05',
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                -0.0100,
                -175.1935,
                97.6975,
                20.9598
            },
            EmoteMoving = true
        }
    },
    ["lollipop1f"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Sucette Violet",
        AnimationOptions = {
            Prop = 'natty_lollipop_spiral06',
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                -0.0100,
                -175.1935,
                97.6975,
                20.9598
            },
            EmoteMoving = true
        }
    },
    ["lollipop2a"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Sucette Rouge",
        AnimationOptions = {
            Prop = "natty_lollipop_spin01",
            PropBone = 60309,
            PropPlacement = {
                -0.0300,
                -0.0500,
                0.0500,
                112.4227,
                -128.8559,
                15.6107
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lollipop2b"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Sucette Jaune & Rose",
        AnimationOptions = {
            Prop = "natty_lollipop_spin02",
            PropBone = 60309,
            PropPlacement = {
                -0.0300,
                -0.0500,
                0.0500,
                112.4227,
                -128.8559,
                15.6107
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lollipop2c"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Sucette Jaune & Vert",
        AnimationOptions = {
            Prop = "natty_lollipop_spin03",
            PropBone = 60309,
            PropPlacement = {
                -0.0300,
                -0.0500,
                0.0500,
                112.4227,
                -128.8559,
                15.6107
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lollipop2d"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Sucette Jaune & Blanc",
        AnimationOptions = {
            Prop = "natty_lollipop_spin04",
            PropBone = 60309,
            PropPlacement = {
                -0.0300,
                -0.0500,
                0.0500,
                112.4227,
                -128.8559,
                15.6107
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lollipop2e"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Sucette Rose & Blanc",
        AnimationOptions = {
            Prop = "natty_lollipop_spin05",
            PropBone = 60309,
            PropPlacement = {
                -0.0300,
                -0.0500,
                0.0500,
                112.4227,
                -128.8559,
                15.6107
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lollipop3a"] = {
        "amb@world_human_smoking@male@male_a@enter",
        "enter",
        "Sucer Sucette",
        AnimationOptions = {
            Prop = 'natty_lollipop01',
            PropBone = 47419,
            PropPlacement = {
                0.0100,
                0.0300,
                0.0100,
                -90.0000,
                10.0000,
                -10.0000
            },
            EmoteMoving = true,
            EmoteDuration = 2600
        }
    },
    ["icecreama"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Cerise",
        AnimationOptions = {
            Prop = 'bzzz_icecream_cherry',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreamb"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Chocolat",
        AnimationOptions = {
            Prop = 'bzzz_icecream_chocolate',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreamc"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Citron",
        AnimationOptions = {
            Prop = 'bzzz_icecream_lemon',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreamd"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Pistache",
        AnimationOptions = {
            Prop = 'bzzz_icecream_pistachio',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreame"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Framboise",
        AnimationOptions = {
            Prop = 'bzzz_icecream_raspberry',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreamf"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Stracciatella",
        AnimationOptions = {
            Prop = 'bzzz_icecream_stracciatella',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreamg"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Fraise",
        AnimationOptions = {
            Prop = 'bzzz_icecream_strawberry',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["icecreamh"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Glâce Noisette",
        AnimationOptions = {
            Prop = 'bzzz_icecream_walnut',
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.03,
                0.01,
                85.0,
                70.0,
                -203.0
            },
            EmoteMoving = true
        }
    },
    ["wine"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Vin",
        AnimationOptions = {
            Prop = 'prop_drink_redwine',
            PropBone = 18905,
            PropPlacement = {
                0.10,
                -0.03,
                0.03,
                -100.0,
                0.0,
                -10.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["flute"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Flute",
        AnimationOptions = {
            Prop = 'prop_champ_flute',
            PropBone = 18905,
            PropPlacement = {
                0.10,
                -0.03,
                0.03,
                -100.0,
                0.0,
                -10.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["champagne"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Champagne",
        AnimationOptions = {
            Prop = 'prop_drink_champ',
            PropBone = 18905,
            PropPlacement = {
                0.10,
                -0.03,
                0.03,
                -100.0,
                0.0,
                -10.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["cigar"] = {
        "amb@world_human_smoking@male@male_a@enter",
        "enter",
        "Cigare",
        AnimationOptions = {
            Prop = 'prop_cigar_02',
            PropBone = 47419,
            PropPlacement = {
                0.010,
                0.0,
                0.0,
                50.0,
                0.0,
                -80.0
            },
            EmoteDuration = 2600,
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                0.0750,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.3
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["cigar2"] = {
        "amb@world_human_smoking@male@male_a@enter",
        "enter",
        "Cigare 2",
        AnimationOptions = {
            Prop = 'prop_cigar_01',
            PropBone = 47419,
            PropPlacement = {
                0.010,
                0.0,
                0.0,
                50.0,
                0.0,
                -80.0
            },
            EmoteDuration = 2600,
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                0.06,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.5
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["guitar"] = {
        "amb@world_human_musician@guitar@male@idle_a",
        "idle_b",
        "Guitare",
        AnimationOptions = {
            Prop = 'prop_acc_guitar_01',
            PropBone = 24818,
            PropPlacement = {
                -0.073,
                0.312,
                0.066,
                9.739,
                -14.132,
                146.068
            },
            RotOrder = 0,
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitar2"] = {
        "switch@trevor@guitar_beatdown",
        "001370_02_trvs_8_guitar_beatdown_idle_busker",
        "Guitare 2",
        AnimationOptions = {
            Prop = 'prop_acc_guitar_01',
            PropBone = 24818,
            PropPlacement = {
                -0.073,
                0.312,
                0.066,
                9.739,
                -14.132,
                146.068
            },
            RotOrder = 0,
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitar3"] = {
        "amb@world_human_musician@guitar@male@idle_a",
        "idle_b",
        "Guitare 3 - Rose",
        AnimationOptions = {
            Prop = 'prop_rpemotesreborn_guitar_001',
            PropBone = 24818,
            PropPlacement = {
                -0.1,
                0.31,
                0.1,
                0.0,
                20.0,
                150.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitar4"] = {
        "switch@trevor@guitar_beatdown",
        "001370_02_trvs_8_guitar_beatdown_idle_busker",
        "Guitare 4 - Rose",
        AnimationOptions = {
            Prop = 'prop_rpemotesreborn_guitar_001',
            PropBone = 24818,
            PropPlacement = {
                -0.05,
                0.31,
                0.1,
                0.0,
                20.0,
                150.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitar5"] = {
        "amb@world_human_musician@guitar@male@idle_a",
        "idle_b",
        "Guitare - Pride",
        AnimationOptions = {
            Prop = 'prop_rpemotesreborn_guitar_002',
            PropBone = 24818,
            PropPlacement = {
                -0.1,
                0.31,
                0.1,
                0.0,
                20.0,
                150.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitar6"] = {
        "switch@trevor@guitar_beatdown",
        "001370_02_trvs_8_guitar_beatdown_idle_busker",
        "Guitare - Pride 2",
        AnimationOptions = {
            Prop = 'prop_rpemotesreborn_guitar_002',
            PropBone = 24818,
            PropPlacement = {
                -0.05,
                0.31,
                0.1,
                0.0,
                20.0,
                150.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitarelectric"] = {
        "amb@world_human_musician@guitar@male@idle_a",
        "idle_b",
        "Guitare Electrique",
        AnimationOptions = {
            Prop = 'prop_el_guitar_01',
            PropBone = 24818,
            PropPlacement = {
                -0.1,
                0.31,
                0.1,
                0.0,
                20.0,
                150.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitarelectric2"] = {
        "amb@world_human_musician@guitar@male@idle_a",
        "idle_b",
        "Guitare Electrique 2",
        AnimationOptions = {
            Prop = 'prop_el_guitar_03',
            PropBone = 24818,
            PropPlacement = {
                -0.1,
                0.31,
                0.1,
                0.0,
                20.0,
                150.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guitarcarry"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare",
        AnimationOptions = {
            Prop = "sf_prop_sf_guitar_case_01a",
            PropBone = 28422,
            PropPlacement = {
                0.2800,
                -0.2000,
                -0.0600,
                0.0,
                0.0,
                15.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry2"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Accoustique",
        AnimationOptions = {
            Prop = "prop_acc_guitar_01",
            PropBone = 28422,
            PropPlacement = {
                0.1500,
                -0.1400,
                -0.0200,
                -101.5083,
                5.7251,
                29.4987
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry3"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Accoustique - Rose",
        AnimationOptions = {
            Prop = "prop_rpemotesreborn_guitar_001",
            PropBone = 28422,
            PropPlacement = {
                0.1500,
                -0.1400,
                -0.0200,
                -101.5083,
                5.7251,
                29.4987
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry4"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Accoustique - Pride",
        AnimationOptions = {
            Prop = "prop_rpemotesreborn_guitar_002",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.1200,
                -0.0500,
                -80.0000,
                0.0,
                21.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry5"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Electrique",
        AnimationOptions = {
            Prop = "prop_el_guitar_01",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.1200,
                -0.0500,
                -80.0000,
                0.0,
                21.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry6"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Electrique 2",
        AnimationOptions = {
            Prop = "prop_el_guitar_02",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.1200,
                -0.0500,
                -80.0000,
                0.0,
                21.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry7"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Electrique 3",
        AnimationOptions = {
            Prop = "prop_el_guitar_03",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.1200,
                -0.0500,
                -80.0000,
                0.0,
                21.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry8"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Electrique 4",
        AnimationOptions = {
            Prop = "vw_prop_casino_art_guitar_01a",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.1200,
                -0.0500,
                -80.0000,
                0.0,
                21.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarcarry9"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Boite Guitare Electrique 5",
        AnimationOptions = {
            Prop = "sf_prop_sf_el_guitar_02a",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.1200,
                -0.0500,
                -80.0000,
                0.0,
                21.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["guitarsit"] = {
        "misssnowie@gatlax",
        "base",
        "Guitare - Assis & Jouer",
        AnimationOptions = {
            Prop = "prop_acc_guitar_01",
            PropBone = 24818,
            PropPlacement = {
                -0.0510,
                0.2770,
                -0.0299,
                -140.3349,
                166.3300,
                29.7590
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["guitarsit2"] = {
        "misssnowie@gatlax",
        "base",
        "Guitare - Assis & Jouer 2 - Rose",
        AnimationOptions = {
            Prop = "prop_rpemotesreborn_guitar_001",
            PropBone = 24818,
            PropPlacement = {
                -0.0510,
                0.2770,
                -0.0299,
                -140.3349,
                166.3300,
                29.7590
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["guitarsit3"] = {
        "misssnowie@gatlax",
        "base",
        "Guitare - Assis & Jouer 2 - Pride",
        AnimationOptions = {
            Prop = "prop_rpemotesreborn_guitar_002",
            PropBone = 24818,
            PropPlacement = {
                -0.0510,
                0.2770,
                -0.0299,
                -140.3349,
                166.3300,
                29.7590
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["book"] = {
        "cellphone@",
        "cellphone_text_read_base",
        "Livre",
        AnimationOptions = {
            Prop = 'prop_novel_01',
            PropBone = 6286,
            PropPlacement = {
                0.15,
                0.03,
                -0.065,
                0.0,
                180.0,
                90.0
            },
            -- This positioning isnt too great, was to much of a hassle
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["bookb"] = {
        "holding_book_1@dark",
        "holding_book_1_clip",
        "Livre 2",
        AnimationOptions = {
            Prop = 'prop_cs_book_01',
            PropBone = 57005,
            PropPlacement = {
                0.0900,
                0.0900,
                -0.0400,
                80.1585,
                158.5623,
                24.7080,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bookc"] = {
        "holding_book_2@dark",
        "holding_book_2_clip",
        "Livre 3",
        AnimationOptions = {
            Prop = "prop_michael_backpack",
            PropBone = 40269,
            PropPlacement = {
                0.0300,
                -0.1600,
                -0.0900,
                -170.7740,
                112.8415,
                -20.0836
            },
            SecondProp = 'prop_cs_book_01',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                0.0400,
                0.0400,
                0.0300,
                -69.0815,
                176.3905,
                19.3724
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bookd"] = {
        "holding_book_3@dark",
        "holding_book_3_clip",
        "Livre 4",
        AnimationOptions = {
            Prop = 'prop_cs_stock_book',
            PropBone = 18905,
            PropPlacement = {
                0.0700,
                0.0400,
                0.0700,
                0.0000,
                0.0000,
                -15.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["booke"] = {
        "holding_book_4@dark",
        "holding_book_4_clip",
        "Livre 5",
        AnimationOptions = {
            Prop = 'prop_cs_stock_book',
            PropBone = 57005,
            PropPlacement = {
                0.0100,
                0.0100,
                -0.0600,
                15.1511,
                3.1232,
                -21.2448
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bookf"] = {
        "holding_book_5@dark",
        "holding_book_5_clip",
        "Livre 6",
        AnimationOptions = {
            Prop = 'v_ilev_mp_bedsidebook',
            PropBone = 18905,
            PropPlacement = {
                0.2100,
                0.0600,
                0.0400,
                170.6161,
                -14.2960,
                28.8727
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["bouquet"] = {
        "hold_flowers@dad", -- Custom Animation By Darks Animations
        "hold_flowers_clip",
        "Bouquet",
        AnimationOptions = {
            Prop = 'prop_snow_flower_02',
            PropBone = 60309,
            PropPlacement = {
                0.1100,
                -0.1300,
                0.1200,
                -18.7186,
                121.0529,
                -11.7724
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["bouquet2"] = {
        "hold_flowers@dad", -- Custom Animation By Darks Animations
        "hold_flowers_clip",
        "Bouquet 2",
        AnimationOptions = {
            Prop = 'pata_freevalentinesday3',
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.0300,
                -0.1700,
                -6.0697,
                60.1852,
                3.4934
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["teddy"] = {
        "impexp_int-0",
        "mp_m_waremech_01_dual-0",
        "Teddy",
        AnimationOptions = {
            Prop = 'v_ilev_mr_rasberryclean',
            PropBone = 24817,
            PropPlacement = {
                -0.20,
                0.46,
                -0.016,
                -180.0,
                -90.0,
                0.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["backpack"] = {
        "move_p_m_zero_rucksack",
        "nill",
        "Sac a Dos",
        AnimationOptions = {
            Prop = 'p_michael_backpack_s',
            PropBone = 24818,
            PropPlacement = {
                0.07,
                -0.11,
                -0.05,
                0.0,
                90.0,
                175.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["clipboard"] = {
        "missfam4",
        "base",
        "Presse-papiers",
        AnimationOptions = {
            Prop = 'p_amb_clipboard_01',
            PropBone = 36029,
            PropPlacement = {
                0.16,
                0.08,
                0.1,
                -130.0,
                -50.0,
                0.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["map"] = {
        "amb@world_human_tourist_map@male@base",
        "base",
        "Carte",
        AnimationOptions = {
            Prop = 'prop_tourist_map_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["map2"] = {
        "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a",
        "idle_a",
        "Carte 2",
        AnimationOptions = {
            Prop = "prop_tourist_map_01",
            PropBone = 28422,
            PropPlacement = {
                -0.05,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beg"] = {
        "amb@world_human_bum_freeway@male@base",
        "base",
        "Mendier",
        AnimationOptions = {
            Prop = 'prop_beggers_sign_03',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beg2"] = {
        "amb@world_human_bum_freeway@male@base",
        "base",
        "Mendier 2",
        AnimationOptions = {
            Prop = 'prop_beggers_sign_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beg3"] = {
        "amb@world_human_bum_freeway@male@base",
        "base",
        "Mendier 3",
        AnimationOptions = {
            Prop = 'prop_beggers_sign_02',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0800,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beg4"] = {
        "amb@world_human_bum_freeway@male@base",
        "base",
        "Mendier 4",
        AnimationOptions = {
            Prop = 'prop_beggers_sign_04',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0800,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["newspaper"] = {
        "amb@world_human_clipboard@male@idle_a",
        "idle_a",
        "Journal",
        AnimationOptions = {
            Prop = 'prop_cliff_paper',
            PropBone = 60309,
            PropPlacement = {
                0.0970,
                -0.0280,
                -0.0170,
                107.4008,
                3.2712,
                -10.5080
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["newspaper2"] = {
        "amb@world_human_clipboard@male@idle_a",
        "idle_a",
        "Journal 2",
        AnimationOptions = {
            Prop = 'ng_proc_paper_news_quik',
            PropBone = 60309,
            PropPlacement = {
                0.1590,
                0.0290,
                -0.0100,
                90.9998,
                0.0087,
                0.5000
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["newspaper3"] = {
        "amb@world_human_clipboard@male@idle_a",
        "idle_a",
        "Journal 3",
        AnimationOptions = {
            Prop = 'ng_proc_paper_news_rag',
            PropBone = 60309,
            PropPlacement = {
                0.1760,
                -0.00070,
                0.0200,
                99.8306,
                3.2841,
                -4.7185
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pornmag"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn",
        AnimationOptions = {
            Prop = 'prop_porn_mag_02',
            PropBone = 60309,
            PropPlacement = {
                0.1000,
                -0.0360,
                -0.0300,
                -86.9096,
                179.2527,
                13.8804
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["pornmag2"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn 2",
        AnimationOptions = {
            Prop = 'prop_cs_magazine',
            PropBone = 60309,
            PropPlacement = {
                0.0800,
                -0.0490,
                -0.0500,
                87.9369,
                -0.4292,
                -14.3925
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["pornmag3"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn 3",
        AnimationOptions = {
            Prop = 'prop_porn_mag_03',
            PropBone = 60309,
            PropPlacement = {
                0.1000,
                -0.0700,
                -0.0200,
                -90.0000,
                -180.0000,
                22.7007
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["pornmag4"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn 4",
        AnimationOptions = {
            Prop = 'v_res_tt_pornmag01',
            PropBone = 60309,
            PropPlacement = {
                -0.0200,
                -0.0300,
                0.0000,
                88.9862,
                0.2032,
                -20.0016
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["pornmag5"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn 5",
        AnimationOptions = {
            Prop = 'v_res_tt_pornmag02',
            PropBone = 60309,
            PropPlacement = {
                -0.0200,
                -0.0300,
                0.0000,
                88.9862,
                0.2032,
                -20.0016
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["pornmag6"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn 6",
        AnimationOptions = {
            Prop = 'v_res_tt_pornmag03',
            PropBone = 60309,
            PropPlacement = {
                -0.0200,
                -0.0300,
                0.0000,
                88.9862,
                0.2032,
                -20.0016
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["pornmag7"] = {
        "amb@world_human_clipboard@male@base",
        "base",
        "Magazine Porn 7",
        AnimationOptions = {
            Prop = 'v_res_tt_pornmag04',
            PropBone = 60309,
            PropPlacement = {
                -0.0200,
                -0.0300,
                0.0000,
                88.9862,
                0.2032,
                -20.0016
            },
            EmoteMoving = true,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["makeitrain"] = {
        "anim@mp_player_intupperraining_cash",
        "idle_a",
        "Distribuent de l'argent",
        AnimationOptions = {
            Prop = 'prop_anim_cash_pile_01',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                180.0,
                0.0,
                70.0
            },
            EmoteMoving = true,
            EmoteLoop = true,
            PtfxAsset = "scr_xs_celebration",
            PtfxName = "scr_xs_money_rain",
            PtfxPlacement = {
                0.0,
                0.0,
                -0.09,
                -80.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('makeitrain'),
            PtfxWait = 500,
            PtfxCanHold = true
        }
    },
    ["camera"] = {
        "stand_camera_1@dad",
        "stand_camera_1_clip",
        "Camera",
        AnimationOptions = {
            Prop = 'prop_pap_camera_01',
            PropBone = 57005,
            PropPlacement = {
                0.1040,
                -0.0060,
                -0.0600,
                -2.7280,
                33.0998,
                4.1917
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_bike_business",
            PtfxName = "scr_bike_cfid_camera_flash",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["camera2"] = {
        "amb@world_human_paparazzi@male@base",
        "base",
        "Camera 2",
        AnimationOptions = {
            Prop = 'prop_pap_camera_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_bike_business",
            PtfxName = "scr_bike_cfid_camera_flash",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["camera3"] = {
        "cellphone@female",
        "cellphone_text_read_base_cover_low",
        "Camera 3",
        AnimationOptions = {
            Prop = "prop_ing_camera_01",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.0300,
                0.0520,
                -172.0487,
                -163.9389,
                -29.0221
            },
            EmoteLoop = false,
            EmoteMoving = true,
            PtfxAsset = "scr_bike_business",
            PtfxName = "scr_bike_cfid_camera_flash",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["camera4"] = {
        "chocoholic@single110a",
        "single110a_clip",
        "Camera 4",
        AnimationOptions = {
            Prop = "prop_ing_camera_01",
            PropBone = 28422,
            PropPlacement = {
                0.0710,
                0.0150,
                -0.0420,
                -68.3220,
                99.6144,
                2.9027
            },
            EmoteLoop = false,
            EmoteMoving = true,
            PtfxAsset = "scr_bike_business",
            PtfxName = "scr_bike_cfid_camera_flash",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["camera5"] = {
        "chocoholic@single110b",
        "single110b_clip",
        "Camera 5",
        AnimationOptions = {
            Prop = "prop_ing_camera_01",
            PropBone = 60309,
            PropPlacement = {
                0.0980,
                0.0560,
                0.1330,
                -15.8221,
                107.0825,
                -16.0159
            },
            EmoteLoop = false,
            EmoteMoving = true,
            PtfxAsset = "scr_bike_business",
            PtfxName = "scr_bike_cfid_camera_flash",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["camera6"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Camera 6 - Porter Camera JT",
        AnimationOptions = {
            Prop = "prop_v_cam_01",
            PropBone = 28422,
            PropPlacement = {
                0.2100,
                0.0300,
                -0.0100,
                90.0000,
                176.0000,
                79.9999
            },
            EmoteLoop = false,
            EmoteMoving = true,
        }
    },
    ["champagnespray"] = {
        "anim@mp_player_intupperspray_champagne",
        "idle_a",
        "Secouer Champagne",
        AnimationOptions = {
            Prop = 'ba_prop_battle_champ_open',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteMoving = true,
            EmoteLoop = true,
            PtfxAsset = "scr_ba_club",
            PtfxName = "scr_ba_club_champagne_spray",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            PtfxInfo = ('spraychamp'),
            PtfxWait = 500,
            PtfxCanHold = true
        }
    },
    ["joint"] = {
        "amb@world_human_smoking@male@male_a@enter",
        "enter",
        "Joint",
        AnimationOptions = {
            Prop = 'p_cs_joint_01',
            PropBone = 47419,
            PropPlacement = {
                0.015,
                -0.009,
                0.003,
                55.0,
                0.0,
                110.0
            },
            EmoteMoving = true,
            EmoteDuration = 2600,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.097,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.3
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["cig"] = {
        "amb@world_human_smoking@male@male_a@enter",
        "enter",
        "Cigarette",
        AnimationOptions = {
            Prop = 'ng_proc_cigarette01a',
            PropBone = 47419,
            PropPlacement = {
                0.015,
                -0.009,
                0.003,
                55.0,
                0.0,
                110.0
            },
            EmoteDuration = 2600,
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                -0.07,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["brief"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Mallette ",
        AnimationOptions = {
            Prop = "prop_ld_case_01",
            PropBone = 57005,
            PropPlacement = {
                0.12,
                0.0,
                0.0,
                0.0,
                255.0,
                80.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["brief2"] = { -- Added for compatibility
        "missheistdocksprep1hold_cellphone",
        "static",
        "Mallette 2",
        AnimationOptions =
        {
            Prop = "prop_ld_case_01",
            PropBone = 57005,
            PropPlacement = {
                0.10,
                0.0,
                0.0,
                0.0,
                280.0,
                53.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["brushteeth"] = {
        "mp_player_inteat@pnq",
        "loop_fp",
        "Brosse a Dents",
        AnimationOptions =
        {
            Prop = "prop_toothbrush_01",
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.04,
                -0.02,
                -93.0,
                -159.0,
                26.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["guncase"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boite Arme",
        AnimationOptions =
        {
            Prop = "prop_gun_case_01",
            PropBone = 57005,
            PropPlacement = {
                0.10,
                0.02,
                -0.02,
                40.0,
                145.0,
                115.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tablet"] = {
        "amb@world_human_tourist_map@male@base",
        "base",
        "Tablette",
        AnimationOptions = {
            Prop = "prop_cs_tablet",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.03,
                0.0,
                20.0,
                -90.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tablet2"] = {
        "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a",
        "idle_a",
        "Tablette 2",
        AnimationOptions = {
            Prop = "prop_cs_tablet",
            PropBone = 28422,
            PropPlacement = {
                -0.05,
                0.0,
                0.0,
                0.0,
                -90.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["phonecall"] = {
        "cellphone@",
        "cellphone_call_listen_base",
        "Appel Téléphone",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7},
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["phonecall2"] = {
        "random@kidnap_girl",
        "ig_1_girl_on_phone_loop",
        "Appel Téléphone 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7},
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wt"] = {
        "cellphone@",
        "cellphone_text_read_base",
        "Talkie-walkie",
        AnimationOptions = {
            Prop = "prop_cs_hand_radio",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wt2"] = {
        "anim@radio_pose_3",
        "radio_holding_gun",
        "Radio 2",
        AnimationOptions = {
            Prop = "prop_cs_hand_radio",
            PropBone = 60309,
            PropPlacement = {
                0.0750,
                0.0470,
                0.0110,
                -97.9442,
                3.7058,
                -23.2367
            },
            EmoteLoop = true,
        }
    },
    ["wt3"] = {
        "anim@radio_left",
        "radio_left_clip",
        "Radio 3 Gauche",
        AnimationOptions = {
            Prop = "prop_cs_hand_radio",
            PropBone = 60309,
            PropPlacement = {
                0.0750,
                0.0470,
                0.0110,
                -97.9442,
                3.7058,
                -23.2367
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wt4"] = {
        "anim@male@holding_radio",
        "holding_radio_clip",
        "Radio 4",
        AnimationOptions = {
            Prop = "prop_cs_hand_radio",
            PropBone = 28422,
            PropPlacement = {
                0.0750,
                0.0230,
                -0.0230,
                -90.0000,
                0.0,
                -59.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["clean"] = {
        "timetable@floyd@clean_kitchen@base",
        "base",
        "Nettoyer",
        AnimationOptions = {
            Prop = "prop_sponge_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.01,
                90.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["clean2"] = {
        "amb@world_human_maid_clean@",
        "base",
        "Nettoyer 2",
        AnimationOptions = {
            Prop = "prop_sponge_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.01,
                90.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["protest"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Protester",
        AnimationOptions = {
            Prop = "prop_cs_protest_sign_01",
            PropBone = 57005,
            PropPlacement = {
                0.1820,
                0.2400,
                0.0600,
                -69.3774235,
                5.9142048,
                -13.9572354
            },
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["protest2"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Protester 2 - Pride",
        AnimationOptions = {
            Prop = "pride_sign_01",
            PropBone = 57005,
            PropPlacement = {
                0.1820,
                0.2400,
                0.0600,
                -69.3774235,
                5.9142048,
                -13.9572354
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["protest3"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Protester 3 - BLM",
        AnimationOptions = {
            Prop = "scully_blm",
            PropBone = 57005,
            PropPlacement = {
                0.1820,
                0.2400,
                0.0600,
                -69.3774235,
                5.914205,
                -13.957235
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["binoculars"] = {
        "amb@world_human_binoculars@male@idle_b",
        "idle_f",
        "Lunettes",
        AnimationOptions = {
            Prop = "prop_binoc_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["binoculars2"] = {
        "amb@world_human_binoculars@male@idle_a",
        "idle_c",
        "Lunettes 2",
        AnimationOptions = {
            Prop = "prop_binoc_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tennisplay"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Jouer au Tennis",
        AnimationOptions = {
            Prop = "prop_tennis_bag_01",
            PropBone = 57005,
            PropPlacement = {
                0.27,
                0.0,
                0.0,
                91.0,
                0.0,
                -82.9999951
            },
            SecondProp = 'prop_tennis_rack_01',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0800,
                0.0300,
                0.0,
                -130.2907295,
                3.8782324,
                6.588224
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["weights"] = {
        "amb@world_human_muscle_free_weights@male@barbell@base",
        "base",
        "Haltère",
        AnimationOptions = {
            Prop = "prop_curl_bar_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["weights2"] = {
        "amb@world_human_muscle_free_weights@male@barbell@idle_a",
        "idle_d",
        "Haltère 2",
        AnimationOptions = {
            Prop = "prop_curl_bar_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["weights3"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_004",
        "Haltère 3 - Pose",
        AnimationOptions = {
            Prop = 'prop_barbell_01',
            PropBone = 28422,
            PropPlacement = {
                0.0660,
                0.0100,
                -0.0300,
                90.0000,
                90.0000,
                -79.9999
            },
            EmoteLoop = true,
        }
    },
    ["weights4"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_003",
        "Haltère 4 - Pose",
        AnimationOptions = {
            Prop = 'prop_barbell_01', -- Left Wrist
            PropBone = 60309,
            PropPlacement = {
                0.0520,
                -0.0010,
                0.0131,
                21.5428,
                70.2098,
                74.5019
            },
            SecondProp = 'prop_barbell_01', -- Right Wrist
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0660,
                0.0100,
                -0.0300,
                90.0000,
                90.0000,
                -79.9999
            },
            EmoteLoop = true,
        }
    },
    ["weights5"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_001",
        "Haltère 5 - Femme Pose",
        AnimationOptions = {
            Prop = 'v_res_tre_weight',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.0580,
                -0.0060,
                0.0300,
                -11.8498,
                170.2644,
                7.8352
            },
            SecondProp = 'v_res_tre_weight',
            SecondPropBone = 60309, -- Left Wrist
            SecondPropPlacement = {
                0.0880,
                0.0000,
                0.0590,
                -29.1132,
                -128.5627,
                13.7517
            },
            EmoteLoop = true,
        }
    },
    ["weights6"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_002",
        "Haltère 6 - Female Pose 2",
        AnimationOptions = {
            Prop = 'v_res_tre_weight',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.0700,
                0.0400,
                -0.0600,
                24.5966,
                6.4814,
                -13.9845
            },
            SecondProp = 'v_res_tre_weight',
            SecondPropBone = 60309, -- Left Wrist
            SecondPropPlacement = {
                0.0550,
                -0.0070,
                -0.0309,
                -20.5854,
                -15.0123,
                0.5710
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["weights7"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_003",
        "Haltère 7 - Female Pose 3",
        AnimationOptions = {
            Prop = 'prop_freeweight_01',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.0500,
                0.0100,
                -0.0200,
                88.6283,
                -51.8805,
                54.3903
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["fuel"] = {
        "weapons@misc@jerrycan@",
        "fire",
        "Essence",
        AnimationOptions = {
            Prop = "w_am_jerrycan",
            PropBone = 57005,
            PropPlacement = {
                0.1800,
                0.1300,
                -0.2400,
                -165.8693883,
                -11.2122753,
                -32.9453021
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["fuel2"] = {
        "weapons@misc@jerrycan@franklin",
        "idle",
        "Essence 2 (Porter)",
        AnimationOptions = {
            Prop = "w_am_jerrycan",
            PropBone = 28422,
            PropPlacement = {
                0.26,
                0.050,
                0.0300,
                80.00,
                180.000,
                79.99
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["hitchhike"] = {
        "random@hitch_lift",
        "idle_f",
        "Faire du Stop",
        AnimationOptions = {
            Prop = "w_am_jerrycan",
            PropBone = 18905,
            PropPlacement = {
                0.32,
                -0.0100,
                0.0,
                -162.423,
                74.83,
                58.79
            },
            SecondProp = 'prop_michael_backpack',
            SecondPropBone = 40269,
            SecondPropPlacement = {
                -0.07,
                -0.21,
                -0.11,
                -144.93,
                117.358,
                -6.16
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Stop",
        AnimationOptions = {
            Prop = "prop_sign_road_01a",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign2"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Ceder le Passage",
        AnimationOptions = {
            Prop = "prop_sign_road_02a",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign3"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Hôpital",
        AnimationOptions = {
            Prop = "prop_sign_road_03d",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign4"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Parking",
        AnimationOptions = {
            Prop = "prop_sign_road_04a",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign5"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Parking 2",
        AnimationOptions = {
            Prop = "prop_sign_road_04w",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign6"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Piéton",
        AnimationOptions = {
            Prop = "prop_sign_road_05a",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign7"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Rue",
        AnimationOptions = {
            Prop = "prop_sign_road_05t",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign8"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Autoroute",
        AnimationOptions = {
            Prop = "prop_sign_freewayentrance",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["ssign9"] = {
        "rcmnigel1d",
        "base_club_shoulder",
        "Panneau Stop Neige",
        AnimationOptions = {
            Prop = "prop_snow_sign_road_01a",
            PropBone = 60309,
            PropPlacement = {
                -0.1390,
                -0.9870,
                0.4300,
                -67.3315314,
                145.0627869,
                -4.4318885
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stire"] = {
        "anim@heists@box_carry@",
        "idle",
        "Voler Pneu 1",
        AnimationOptions = {
            Prop = "prop_wheel_01",
            PropBone = 18905,
            PropPlacement = {
                0.02,
                0.2,
                0.31,
                130.0,
                -80.0,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stire2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Voler Pneu 2",
        AnimationOptions = {
            Prop = "prop_wheel_02",
            PropBone = 18905,
            PropPlacement = {
                0.02,
                0.2,
                0.31,
                130.0,
                -80.0,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["conehead"] = {
        "move_m@drunk@verydrunk_idles@",
        "fidget_07",
        "Cône tête",
        AnimationOptions = {
            Prop = "prop_roadcone02b",
            PropBone = 31086,
            PropPlacement = {
                0.0500,
                0.0200,
                -0.000,
                30.0000004,
                90.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtraya"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture ",
        AnimationOptions = {
            Prop = "prop_food_bs_tray_03",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.0400,
                -0.1390,
                20.0000007,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayb"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture B",
        AnimationOptions = {
            Prop = "prop_food_bs_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.0400,
                -0.1390,
                20.0000007,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayc"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture C",
        AnimationOptions = {
            Prop = "prop_food_cb_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.0400,
                -0.1390,
                20.0000007,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayd"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture D",
        AnimationOptions = {
            Prop = "prop_food_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.0400,
                -0.1390,
                20.0000007,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtraye"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture E",
        AnimationOptions = {
            Prop = "prop_food_tray_03",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.0400,
                -0.1390,
                20.0000007,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayf"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture F",
        AnimationOptions = {
            Prop = "prop_food_bs_tray_02",
            PropBone = 57005,
            PropPlacement = {
                0.2500,
                0.1000,
                0.0700,
                -110.5483936,
                73.3529273,
                -16.338362
            },
            SecondProp = 'prop_food_bs_tray_03',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                0.2200,
                0.1300,
                -0.1000,
                -127.7725487,
                110.2074758,
                -3.5886263
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayg"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture G",
        AnimationOptions = {
            Prop = "prop_food_cb_tray_02",
            PropBone = 57005,
            PropPlacement = {
                0.2500,
                0.1000,
                0.0700,
                -110.5483936,
                73.3529273,
                -16.338362
            },
            SecondProp = 'prop_food_cb_tray_02',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                0.2200,
                0.1300,
                -0.1000,
                -127.7725487,
                110.2074758,
                -3.5886263
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayh"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture H",
        AnimationOptions = {
            Prop = "prop_food_tray_02",
            PropBone = 57005,
            PropPlacement = {
                0.2500,
                0.1000,
                0.0700,
                -110.5483936,
                73.3529273,
                -16.338362
            },
            SecondProp = 'prop_food_tray_03',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                0.2200,
                0.1300,
                -0.1000,
                -127.7725487,
                110.2074758,
                -3.5886263
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayi"] = {
        "anim@heists@box_carry@",
        "idle",
        "Plateau Nouritture I",
        AnimationOptions = {
            Prop = "prop_food_tray_02",
            PropBone = 57005,
            PropPlacement = {
                0.2500,
                0.1000,
                0.0700,
                -110.5483936,
                73.3529273,
                -16.338362
            },
            SecondProp = 'prop_food_tray_02',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                0.2200,
                0.1300,
                -0.1000,
                -127.7725487,
                110.2074758,
                -3.5886263
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayj"] = {
        "anim@move_f@waitress",
        "idle",
        "Plateau Nouritture J",
        AnimationOptions = {
            Prop = "prop_food_bs_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayk"] = {
        "anim@move_f@waitress",
        "idle",
        "Plateau repas K",
        AnimationOptions = {
            Prop = "prop_food_bs_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayl"] = {
        "anim@move_f@waitress",
        "idle",
        "Plateau Nouritture L",
        AnimationOptions = {
            Prop = "prop_food_bs_tray_03",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtraym"] = {
        "anim@move_f@waitress",
        "idle",
        "Plateau Nouritture M",
        AnimationOptions = {
            Prop = "prop_food_cb_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayn"] = {
        "anim@move_f@waitress",
        "idle",
        "Plateau Nouritture N",
        AnimationOptions = {
            Prop = "prop_food_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["foodtrayo"] = {
        "anim@move_f@waitress",
        "idle",
        "Plateau Nouritture O",
        AnimationOptions = {
            Prop = "prop_food_tray_02",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mnc"] = {
        "anim@heists@box_carry@",
        "idle",
        "Cookie & Lait",
        AnimationOptions = {
            Prop = "m23_2_prop_m32_milkncookies_01a",
            PropBone = 57005, -- Right Wrist
            PropPlacement = {
                0.2150,
                0.1140,
                0.0240,
                -81.9185,
                -176.2526,
                -28.4674
            },
            SecondProp = 'm23_2_prop_m32_milkncookies_01a',
            SecondPropBone = 18905, -- Left Wrist
            SecondPropPlacement = {
                0.2150,
                0.1140,
                0.0240,
                -95.9185,
                -176.2526,
                -28.4674
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["carrypizza"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Boite Pizza",
        AnimationOptions = {
            Prop = "prop_pizza_box_02",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.1000,
                -0.1590,
                20.0000007,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["carryfoodbag"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Sac Nourriture",
        AnimationOptions = {
            Prop = "prop_food_bs_bag_01",
            PropBone = 57005,
            PropPlacement = {
                0.3300,
                0.0,
                -0.0300,
                0.0017365,
                -79.9999997,
                110.0651988
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["carryfoodbag2"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Sac Nourriture 2",
        AnimationOptions = {
            Prop = "prop_food_cb_bag_01",
            PropBone = 57005,
            PropPlacement = {
                0.3800,
                0.0,
                -0.0300,
                0.0017365,
                -79.9999997,
                110.0651988
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["carryfoodbag3"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Porter Sac Nourriture 3",
        AnimationOptions = {
            Prop = "prop_food_bag1",
            PropBone = 57005,
            PropPlacement = {
                0.3800,
                0.0,
                -0.0300,
                0.0017365,
                -79.9999997,
                110.0651988
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag"] = {
        "anim@scripted@freemode@postertag@graffiti_spray@male@",
        "shake_can_male",
        "Graffiti Homme",
        AnimationOptions = {
            Prop = "prop_cs_spray_can",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag2"] = {
        "anim@scripted@freemode@postertag@graffiti_spray@heeled@",
        "shake_can_female",
        "Graffiti Femme",
        AnimationOptions = {
            Prop = "prop_cs_spray_can",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag3"] = {
        "anim@scripted@freemode@postertag@graffiti_spray@male@",
        "spray_can_var_01_male",
        "Tager Homme 1",
        AnimationOptions = {
            Prop = "prop_cs_spray_can",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag4"] = {
        "anim@scripted@freemode@postertag@graffiti_spray@male@",
        "spray_can_var_02_male",
        "Tager Homme 2",
        AnimationOptions = {
            Prop = "prop_cs_spray_can",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag5"] = {
        "anim@scripted@freemode@postertag@graffiti_spray@heeled@",
        "spray_can_var_01_female",
        "Tager Femme 1",
        AnimationOptions = {
            Prop = "prop_cs_spray_can",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag6"] = {
        "anim@scripted@freemode@postertag@graffiti_spray@heeled@",
        "spray_can_var_02_female",
        "Tager Femme 2",
        AnimationOptions = {
            Prop = "prop_cs_spray_can",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["tag7"] = {
        "anim@scripted@freemode@tagcoll_ig_postertag@heeled@",
        "postertag",
        "Tager 7",
        AnimationOptions = {
            Prop = "m24_1_prop_m41_spraycan_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0700,
                0.0017365,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beans"] = {
        "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1",
        "base_idle",
        "Pois",
        AnimationOptions = {
            Prop = "h4_prop_h4_caviar_tin_01a",
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0300,
                0.0100,
                0.0,
                0.0,
                0.0
            },
            SecondProp = 'h4_prop_h4_caviar_spoon_01a',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pho"] = {
        "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1",
        "base_idle",
        "Pho",
        AnimationOptions = {
            Prop = "scully_pho",
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0300,
                0.0100,
                0.0,
                0.0,
                0.0
            },
            SecondProp = 'scully_spoon_pho',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dinner"] = {
        "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1",
        "base_idle",
        "Diner",
        AnimationOptions = {
            Prop = "prop_cs_plate_01",
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            SecondProp = 'h4_prop_h4_caviar_spoon_01a',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["newscam"] = {
        "missfinale_c2mcs_1",
        "fin_c2_mcs_1_camman",
        "Camera JT",
        AnimationOptions = {
            Prop = "prop_v_cam_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0300,
                0.0100,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["newsmic"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Microphone JT",
        AnimationOptions = {
            Prop = "p_ing_microphonel_01",
            PropBone = 4154,
            PropPlacement = {
                -0.00,
                -0.0200,
                0.1100,
                0.00,
                0.0,
                60.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["newsbmic"] = {
        "missfra1",
        "mcs2_crew_idle_m_boom",
        "Gros Microphone JT",
        AnimationOptions = {
            Prop = "prop_v_bmike_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microck"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p1",
        "mic@p1",
        "Microphone Rock",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0300,
                0.0200,
                -0.0300,
                162.9608,
                -91.1712,
                -3.8249
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckb"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p2",
        "mic@p2",
        "Microphone Rock 2",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 60309, -- Left Wrist
            PropPlacement = {
                0.0350,
                0.0180,
                0.0290,
                -180.0000,
                -13.0000,
                0.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckc"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p3",
        "mic@p3",
        "Microphone Rock 3",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0300,
                0.0200,
                -0.0300,
                162.9608,
                -91.1712,
                -3.8249
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckd"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p4",
        "mic@p4",
        "Microphone Rock 4",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0300,
                0.0200,
                -0.0300,
                162.9608,
                -91.1712,
                -3.8249
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microcke"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p5",
        "mic@p5",
        "Microphone Rock 5",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 60309,
            PropPlacement = {
                0.0370,
                0.0130,
                0.0150,
                -173.6259,
                -93.5253,
                4.6450
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckf"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p6",
        "mic@p6",
        "Microphone Rock 6",
        AnimationOptions = {
            Prop = "v_ilev_fos_mic",
            PropBone = 28422,
            PropPlacement = {
                -0.4410,
                -1.0600,
                -0.4800,
                -57.7266,
                51.8164,
                3.0976
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckg"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p7",
        "mic@p7",
        "Microphone Rock 7",
        AnimationOptions = {
            Prop = "v_ilev_fos_mic",
            PropBone = 28422,
            PropPlacement = {
                -0.8210,
                -0.0900,
                -1.1900,
                -2.5478,
                36.3684,
                -11.7503
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckh"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p8",
        "mic@p8",
        "Microphone Rock 8",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 60309,
            PropPlacement = {
                0.0370,
                0.0130,
                0.0150,
                -173.6259,
                -93.5253,
                4.6450
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microcki"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p9",
        "mic@p9",
        "Microphone Rock 9",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0300,
                0.0200,
                -0.0300,
                162.9608,
                -91.1712,
                -3.8249
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["microckj"] = { -- Custom Emote Provided To RpEmotes By Prue颜
        "lunyx@mic@p10",
        "mic@p10",
        "Microphone Rock 10",
        AnimationOptions = {
            Prop = "sf_prop_sf_mic_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0300,
                0.0200,
                -0.0300,
                162.9608,
                -91.1712,
                -3.8249
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leafblower"] = {
        "amb@world_human_gardener_leaf_blower@base",
        "base",
        "Souffler Feuille",
        AnimationOptions = {
            Prop = "prop_leaf_blower_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_armenian3",
            PtfxName = "ent_anim_leaf_blower",
            PtfxPlacement = {
                1.0,
                0.0,
                -0.25,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('useleafblower'),
            PtfxWait = 2000,
            PtfxCanHold = true
        }
    },
    ["bbqf"] = {
        "amb@prop_human_bbq@male@idle_a",
        "idle_b",
        "BBQ (Femme)",
        AnimationOptions = {
            Prop = "prop_fish_slice_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pump"] = {
        "missfbi4prepp1",
        "idle",
        "Citrouile",
        AnimationOptions = {
            Prop = "prop_veg_crop_03_pump",
            PropBone = 28422,
            PropPlacement = {
                0.0200,
                0.0600,
                -0.1200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pump2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Citrouile 2",
        AnimationOptions = {
            Prop = "prop_veg_crop_03_pump",
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                -0.16000,
                -0.2100,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pump3"] = {
        "missfbi4prepp1",
        "idle",
        "Citrouile 3",
        AnimationOptions = {
            Prop = "reh_prop_reh_lantern_pk_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0010,
                0.0660,
                -0.0120,
                171.9169,
                179.8707,
                -39.9860
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pump4"] = {
        "missfbi4prepp1",
        "idle",
        "Citrouile 4",
        AnimationOptions = {
            Prop = "reh_prop_reh_lantern_pk_01b",
            PropBone = 28422,
            PropPlacement = {
                0.0010,
                0.0660,
                -0.0120,
                171.9169,
                179.8707,
                -39.9860
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pump5"] = {
        "missfbi4prepp1",
        "idle",
        "Citrouile 5",
        AnimationOptions = {
            Prop = "reh_prop_reh_lantern_pk_01c",
            PropBone = 28422,
            PropPlacement = {
                0.0010,
                0.0660,
                -0.0120,
                171.9169,
                179.8707,
                -39.9860
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mop"] = {
        "missfbi4prepp1",
        "idle",
        "Serpillière",
        AnimationOptions = {
            Prop = "prop_cs_mop_s",
            PropBone = 28422,
            PropPlacement = {
                -0.0200,
                -0.0600,
                -0.2000,
                -13.377,
                10.3568,
                17.9681
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mop2"] = {
        "move_mop",
        "idle_scrub_small_player",
        "Serpillière 2",
        AnimationOptions = {
            Prop = "prop_cs_mop_s",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.1200,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["jerkf"] = {
        "switch@trevor@jerking_off",
        "trev_jerking_off_loop",
        "Masturber Femme",
        AnimationOptions = {
            Prop = 'prop_cs_dildo_01',
            PropBone = 28422,
            PropPlacement = {
                0.09,
                0.05,
                -0.03,
                90.0,
                80.0,
                30.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        },
        AdultAnimation = true
    },
    ["rake"] = {
        "anim@amb@drug_field_workers@rake@male_a@base",
        "base",
        "Râteau",
        AnimationOptions = {
            Prop = "prop_tool_rake",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }
    },
    ["rake2"] = {
        "anim@amb@drug_field_workers@rake@male_a@idles",
        "idle_b",
        "Râteau 2",
        AnimationOptions = {
            Prop = "prop_tool_rake",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }
    },
    ["rake3"] = {
        "anim@amb@drug_field_workers@rake@male_b@base",
        "base",
        "Râteau 3",
        AnimationOptions = {
            Prop = "prop_tool_rake",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }
    },
    ["rake4"] = {
        "anim@amb@drug_field_workers@rake@male_b@idles",
        "idle_d",
        "Râteau 4",
        AnimationOptions = {
            Prop = "prop_tool_rake",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }
    },
    ["broom"] = {
        "anim@amb@drug_field_workers@rake@male_a@base",
        "base",
        "Balai",
        AnimationOptions = {
            Prop = "prop_tool_broom",
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.0400,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["broom2"] = {
        "anim@amb@drug_field_workers@rake@male_a@idles",
        "idle_b",
        "Balai 2",
        AnimationOptions = {
            Prop = "prop_tool_broom",
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.0400,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["broom3"] = {
        "anim@amb@drug_field_workers@rake@male_b@base",
        "base",
        "Balai 3",
        AnimationOptions = {
            Prop = "prop_tool_broom",
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.0400,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["broom4"] = {
        "anim@amb@drug_field_workers@rake@male_b@idles",
        "idle_d",
        "Balai 4",
        AnimationOptions = {
            Prop = "prop_tool_broom",
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                0.0400,
                -0.0300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["champw"] = {
        "anim@move_f@waitress",
        "idle",
        "Sommelier à Champagne",
        AnimationOptions = {
            Prop = "vw_prop_vw_tray_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0100,
                0.0,
                0.0,
                0.0
            },
            SecondProp = 'prop_champ_cool',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.010,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shit"] = {
        "missfbi3ig_0",
        "shit_loop_trev",
        "Chier",
        AnimationOptions = {
            Prop = "prop_toilet_roll_01",
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                -0.02000,
                -0.2100,
                0,
                0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_poo",
            PtfxNoProp = true,
            PtfxBone = 11816,
            PtfxPlacement = {
                0.0,
                0.0,
                -0.1,
                0.0,
                0.0,
                0.0,
                1.3
            },
            PtfxInfo = ('poop'),
            PtfxWait = 0,
            PtfxCanHold = true
        }
    },
    ["shit2"] = {
        "missfbi3ig_0",
        "nill",
        "Chier en Marchant",
        AnimationOptions = {
            Prop = "prop_toilet_roll_01",
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                -0.02000,
                -0.2100,
                0,
                0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_poo",
            PtfxNoProp = true,
            PtfxBone = 11816,
            PtfxPlacement = {
                0.0,
                0.0,
                -0.1,
                0.0,
                0.0,
                0.0,
                1.4
            },
            PtfxInfo = ('poop'),
            PtfxWait = 0,
            PtfxCanHold = true
        }
    },
    ["selfie"] = {
        "anim@mp_player_intuppertake_selfie",
        "idle_a",
        "Selfie",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie2"] = {
        "cellphone@self@franklin@",
        "peace",
        "Selfie 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie3"] = {
        "cellphone@self@franklin@",
        "west_coast",
        "Selfie 3 - West Side",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie4"] = {
        "cellphone@self@trevor@",
        "aggressive_finger",
        "Selfie 4 - Doigt d'Honneur",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie5"] = {
        "cellphone@self@trevor@",
        "proud_finger",
        "Selfie 5 - Doigt d'Honneur 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7},
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie6"] = {
        "cellphone@self@trevor@",
        "throat_slit",
        "Selfie 6 - Gorge tranchée",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie7"] = {
        "cellphone@self@franklin@",
        "chest_bump",
        "Selfie 7 - Taper Torse",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie8"] = {
        "anim@amb@carmeet@take_photos@",
        "female_b_idle_d",
        "Selfie 8 - Photos de pare-chocs",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfie9"] = {
        "anim@amb@carmeet@take_photos@",
        "female_b_idle_b",
        "Selfie 9 - Selfie Ceck",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiehigh"] = { -- Custom Emote By Darks Animations
        "girl_groupe_b@darksj",
        "girl_groupe_b_clip",
        "Selfie Haut",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 26611,
            PropPlacement = {
                0.0620,
                -0.0400,
                0.0080,
                -17.1672,
                9.8904,
                -18.1951
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiepeace"] = { -- MissSnowie Custom Emote
        "mirror_selfie@peace_sign",
        "base",
        "Selfie Peace",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 57005,
            PropPlacement = {
                0.1700,
                0.0299,
                -0.0159,
                -126.2687,
                -139.9058,
                35.6203
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecrouch"] = { -- MissSnowie Custom Emote
        "crouching@taking_selfie",
        "base",
        "Selfie Ramper",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 18905,
            PropPlacement = {
                0.1580,
                0.0180,
                0.0300,
                -150.4798,
                -67.8240,
                -46.0417
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecrouch2"] = { -- Wolf's Square Custom Emote
        "eagle@girlphonepose13",
        "girl",
        "Selfie Ramper 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 60309,
            PropPlacement = {
                0.0670,
                0.0300,
                0.0300,
                -90.0000,
                0.0000,
                -25.9000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecrouch3"] = { -- Custom Emote By Struggleville
        "anim@male_insta_selfie",
        "insta_selfie_clip",
        "Selfie Ramper 3",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 60309,
            PropPlacement = {
                0.0700,
                0.0100,
                0.0690,
                0.0,
                0.0,
                -150.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecrouch4"] = { -- Custom emote by Struggleville
        "anim@female_selfie_risque",
        "selfie_risque_clip",
        "Selfie Ramper 4",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 18905,
            PropPlacement = {
                0.1580,
                0.0180,
                0.0300,
                -150.4798,
                -67.8240,
                -46.0417
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfieegirl"] = { -- Custom emote by Struggleville
        "anim@female_egirl_cute_selfie",
        "cute_selfie_clip",
        "Selfie E Girl",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 26613, -- Left Finger 30
            PropPlacement = {
                0.0760,
                -0.0220,
                0.0350,
                -22.0968,
                30.4351,
                -7.9339
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfieslut"] = { -- Custom Emote By Struggleville
        "anim@female_floor_slutarch_selfie",
        "slutarch_selfie_clip",
        "Selfie Pose Stripteaseuse",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 58868, -- Right Finger 20
            PropPlacement = {
                0.0350,
                0.0140,
                0.0290,
                167.9999,
                180.0000,
                -8.8999
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        },
        AdultAnimation = true
    },
    ["selfiesit"] = { -- Emote by WhiskerValeMod. Need to configure camera flash and texture variants
        "mouse@female_sitting_selfie",
        "female_sitting_selfie_clip",
        "Selfie Assis",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropBone = 57005,
            PropPlacement = {
                0.1380,
                0.0300,
                -0.0430,
                -111.0946,
                -117.8069,
                11.7386
            },
            SecondProp = 'apa_mp_h_stn_chairarm_23',
            SecondPropBone = 0,
            SecondPropPlacement = {
                -0.0100,
                -0.0800,
                -0.6800,
                -180.0000,
                -180.0000,
                10.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["selfiesit2"] = { -- Emote by WolfSquareEmotes
        "eagle@boypose05",
        "boy",
        "Selfie Assis 2",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4090, -- Left Finger 2
            PropPlacement = {
                0.0130,
                0.0120,
                -0.0070,
                -103.6673,
                -11.0026,
                18.2605
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesit3"] = { -- Emote by Chocoholic Animations
        "chocoholic@single77",
        "single77_clip",
        "Selfie Assis 3",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4185,
            PropPlacement = {
                0.0130,
                -0.0190,
                0.0320,
                0.0,
                0.0000,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesit4"] = { -- Emote by Chocoholic Animations
        "chocoholic@single89",
        "single89_clip",
        "Selfie Assis 4",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169, -- Left Finger 11
            PropPlacement = {
                0.0100,
                -0.0330,
                0.000,
                -19.7197,
                9.4080,
                -3.4048
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesit5"] = { -- Emote by Chocoholic Animations
        "chocoholic@single83",
        "single83_clip",
        "Selfie Assis 5",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64016,
            PropPlacement = {
                0.1080,
                -0.0160,
                0.0300,
                -171.4163,
                -117.2863,
                17.0148
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiefu"] = { -- Struggleville
        "anim@fuck_you_selfie",
        "fuck_you_selfie_clip",
        "Selfie Doigt D'honneur",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.1200,
                0.0220,
                -0.0210,
                98.6822,
                -4.9809,
                109.6216
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiethot"] = { -- Struggleville
        "anim@sitting_thot",
        "sitting_thot_clip",
        "Selfie Folle InstaPic",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.1030,
                0.0440,
                -0.0270,
                -160.2802,
                -99.4080,
                -3.4048
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiefloor"] = { -- Custom Emote By Struggleville
        "anim@selfie_floor_cute",
        "floor_cute_clip",
        "Selfie Sol InstaPic",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 60309,
            PropPlacement = {
                0.0930,
                0.0230,
                0.0260,
                -158.8271,
                -82.9040,
                -18.7472
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiefloor2"] = { -- Custom Emote By Struggleville
        "anim@female_selfie_04",
        "f_selfie_04_clip",
        "Selfie Sol 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4185,
            PropPlacement = {
                0.0170,
                -0.0100,
                0.0200,
                -27.3580,
                54.9374,
                -6.1611
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiefloor3"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@single90",
        "single90_clip",
        "Selfie & Vin",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0800,
                0.0170,
                0.0810,
                -174.2748,
                -11.5083,
                29.4987
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                { Name = "<font color=\"#00A0F4\">Blue", Value = 0 },
                { Name = "<font color=\"#1AA20E\">Green", Value = 1 },
                { Name = "<font color=\"#800B0B\">Dark Red", Value = 2 },
                { Name = "<font color=\"#FF7B00\">Orange", Value = 3 },
                { Name = "<font color=\"#5F5F5F\">Grey", Value = 4 },
                { Name = "<font color=\"#a356fa\">Purple", Value = 5 },
                { Name = "<font color=\"#FF0099\">Pink", Value = 6 },
                { Name = "Black", Value = 7 },
            },
            SecondPropBone = 4186, -- Left Finger 22
            SecondPropPlacement = {
                -0.0100,
                0.0000,
                0.0200,
                -80.0000,
                0.0000,
                -20.0000
            },
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200,
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["selfiesexy"] = { -- Custom Emote By Little Spoon, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "littlespoon@selfie001",
        "selfie001",
        "Selfie Sexy",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 58870, -- Right Finger 40 Bone
            PropPlacement = {
                0.0150,
                0.0230,
                0.0700,
                0.0,
                0.0,
                170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesexy2"] = { -- Custom Emote By Little Spoon, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "littlespoon@selfie002",
        "selfie002",
        "Selfie Sexy 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64064, -- Right Finger 31 Bone
            PropPlacement = {
                0.0290,
                0.0140,
                0.0490,
                174.9616,
                -149.6187,
                8.6491
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesexy3"] = { -- Custom Emote By Little Spoon, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "littlespoon@selfie003",
        "selfie003",
        "Selfie Sexy 3 - Squat",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64064, -- Right Finger 31 Bone
            PropPlacement = {
                0.0290,
                0.0140,
                0.0490,
                174.9616,
                -149.6187,
                8.6491
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesexy4"] = { -- Custom Emote By Little Spoon, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "littlespoon@selfie004",
        "selfie004",
        "Selfie Sexy 4",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64064, -- Right Finger 31 Bone
            PropPlacement = {
                0.0290,
                0.0140,
                0.0490,
                174.9616,
                -149.6187,
                8.6491
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiesexy5"] = { -- Custom Emote By Little Spoon, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "littlespoon@selfie005",
        "selfie005",
        "Selfie Sexy 5",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64064, -- Right Finger 31 Bone
            PropPlacement = {
                0.0290,
                0.0140,
                0.0490,
                174.9616,
                -149.6187,
                8.6491
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecute"] = { -- Custom Emote By Puppy, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "pupppy@freeselfie01",
        "freeselfie01",
        "Selfie Cute",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 26613, -- Left Finger 30 Bone
            PropPlacement = {
                0.0380,
                -0.0310,
                0.0590,
                0.0000,
                0.0000,
                10.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecute2"] = { -- Custom Emote By Puppy, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "pupppy@freeselfie02",
        "freeselfie02",
        "Selfie Cute 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 60309, -- Left Wrist, worked better.
            PropPlacement = {
                0.0960,
                0.0160,
                0.0420,
                -155.3515,
                -84.4828,
                4.7551
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecute3"] = { -- Custom Emote By Puppy, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "pupppy@freeselfie03",
        "freeselfie03",
        "Selfie Cute 3",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 26614, -- Left Finger 40, worked better.
            PropPlacement = {
                0.0310,
                -0.0430,
                0.0720,
                0.0000,
                3.9999,
                0.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecute4"] = { -- Custom Emote By Struggleville, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "anim@egirl_1foot_selfie",
        "1foot_selfie_clip",
        "Selfie Cute 4",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4185, -- Left Finger 21
            PropPlacement = {
                0.0290,
                -0.0230,
                0.0190,
                -14.7860,
                67.8030,
                6.1827
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiecute5"] = { -- Custom Emote By Wolf's Square
        "eagle@girlphonepose21",
        "girl",
        "Selfie Cute 5",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4185,
            PropPlacement = {
                0.0210,
                -0.0150,
                0.0110,
                -45.8936,
                41.8372,
                -26.6415
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiebbum"] = { -- Custom Emote By Struggleville, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "anim@female_beach_booty_selfie",
        "booty_selfie_clip",
        "Selfie Plage",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 26613, -- Left Finger 30
            PropPlacement = {
                0.0680,
                -0.0250,
                0.0340,
                -13.4299,
                47.2288,
                -14.9588
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ['selfiehb'] = { -- Custom prop by crowded1337
        'anim@female_selfie_cute',
        'selfie_cute_clip',
        'Selfie Sac à Main',
        AnimationOptions = {
            Prop = 'prop_amb_handbag_01',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.1700,
                0.0020,
                -0.1000,
                105.4525,
                -178.3549,
                69.1794
            },
            SecondProp = 'prop_phone_ing',-- Cell Phone Left Finger 21
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            SecondPropBone = 4185,
            SecondPropPlacement = {
                0.0200,
                -0.0250,
                0.0000,
                -8.5947,
                30.6141,
                -5.1311
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiehhands"] = { -- Custom Emote By QueenSistersAnimations, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "heartselfiemirror@queensisters",
        "heartselfie_clip",
        "Selfie Coeur main",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64096, -- Right Finger 11
            PropPlacement = {
                0.0390,
                0.0200,
                0.0330,
                90.0000,
                180.0000,
                13.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiefu2"] = { -- Custom Emote By QueenSistersAnimations, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "fuckyouselfie@queensisters",
        "mirrorselfie_clip",
        "Selfie Doigt D'honneur 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 64097, -- Right Finger 12
            PropPlacement = {
                -0.0210,
                0.0300,
                -0.0030,
                -180.0000,
                -180.0000,
                0.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiefu3"] = { -- Custom Emote By QueenSistersAnimations, designed for a custom iFruit phone model, however I am sticking with default game props for now
        "selfiekilye@queensisters",
        "kilye_clip",
        "Selfie Doigt D'honneur Femme",
        AnimationOptions = {
            Prop = 'prop_cs_dildo_01',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.0450,
                0.0050,
                -0.0150,
                92.0810,
                1.3049,
                -2.8863
            },
            SecondProp = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            SecondPropBone = 26613, -- Left Finger 30
            SecondPropPlacement = {
                0.0650,
                -0.0280,
                0.0440,
                10.6808,
                13.7526,
                2.6457
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200,
        },
        AdultAnimation = true
    },
    ["selfiemale"] = { -- Custom Emote By Wolf's Square
        "eagle@boypose04",
        "boy",
        "Selfie Homme Pose",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 60309,
            PropPlacement = {
                0.0730,
                0.0220,
                0.0460,
                -142.1374,
                -92.4142,
                33.1691
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiemeh"] = { -- Custom Animation By Chocoholic Animations
        "chocoholic@single81",
        "single81_clip",
        "Selfie Meh",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 58868,
            PropPlacement = {
                0.0450,
                0.0310,
                0.0280,
                165.3005,
                -174.8342,
                -8.4770
            },
            EmoteLoop = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["selfiewine"] = { -- Custom Emote By Wolf's Square
        "holding_wine@taking_selfie",
        "base",
        "Selfie Vin",
        AnimationOptions = {
            Prop = 'p_wine_glass_s',
            PropBone = 28422,
            PropPlacement = {
                0.0420,
                -0.0700,
                -0.0440,
                -82.6657,
                1.2898,
                -19.9222
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                { Name = "<font color=\"#00A0F4\">Blue", Value = 0 },
                { Name = "<font color=\"#1AA20E\">Green", Value = 1 },
                { Name = "<font color=\"#800B0B\">Dark Red", Value = 2 },
                { Name = "<font color=\"#FF7B00\">Orange", Value = 3 },
                { Name = "<font color=\"#5F5F5F\">Grey", Value = 4 },
                { Name = "<font color=\"#a356fa\">Purple", Value = 5 },
                { Name = "<font color=\"#FF0099\">Pink", Value = 6 },
                { Name = "Black", Value = 7 },
            },
            SecondPropBone = 4090,
            SecondPropPlacement = {
                0.0250,
                -0.0080,
                -0.0050,
                -140.5541,
                -24.7476,
                13.7795
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["femalemirrorselfie"] = {
        "mirror_selfie_1@janina234",
        "mirror_selfie_1_clip",
        "Femme Miroir Selfie",
        AnimationOptions = { -- Custom emote by Janina234
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4089,
            PropPlacement = {
                0.0890,
                -0.0350,
                0.0200,
                -161.7778308,
                -54.5014945,
                -12.0985177
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["femalemirrorselfie1"] = {
        "mirror_selfie_8@daj",
        "mirror_selfie_8_clip",
        "Femme Miroir Selfie 1",
        AnimationOptions = { -- Custom emote by Dark
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4153,
            PropPlacement = {
                0.0400,
                0.00000,
                0.0500,
                -37.4803963,
                33.2648588,
                18.6732448
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["cameraphotography"] = { -- Custom emote by MrWitt
        "mrwitt@photographic_journey_f",
        "mrwitt",
        "Camera Photographe",
        AnimationOptions = {
            Prop = 'prop_pap_camera_01',
            PropBone = 26613,
            PropPlacement = {
                0.0280,
                -0.1350,
                0.1120,
                -86.9428843,
                157.9882355,
                80.8053557
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_bike_business",
            PtfxName = "scr_bike_cfid_camera_flash",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["malemirrorselfie"] = { -- Custom emote by Struggleville
        "anim@male_model_08",
        "m_model_08_clip",
        "Homme Mirroir Selfie",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169,
            PropPlacement = {
                0.0300,
                -0.0200,
                0.0200,
                -64.2080926,
                3.367247,
                0.0711684
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["malemirrorselfie1"] = { -- Custom emote by Struggleville
        "anim@male_selfie_08",
        "m_selfie_08_clip",
        "Homme Mirroir Selfie 1",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169,
            PropPlacement = {
                0.0100,
                -0.0400,
                0.0000,
                -32.8072134,
                11.7427793,
                32.5772863
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["malemirrorselfie2"] = { -- Custom emote by Struggleville
        "anim@male_selfie_06",
        "m_selfie_06_clip",
        "Homme Mirroir Selfie 2",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169,
            PropPlacement = {
                0.0200,
                -0.0200,
                0.0100,
                -69.7707963,
                3.10072,
                -8.4531301
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["malemirrorselfie4"] = { -- Custom emote by Struggleville
        "anim@male_model_03",
        "m_model_03_clip",
        "Homme Mirroir Selfie 4",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169,
            PropPlacement = {
                0.0100,
                -0.0600,
                -0.0100,
                -23.7215768,
                66.9464998,
                -62.7303262
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["malemirrorselfie3"] = { -- Custom emote by Struggleville
        "anim@male_selfie_09",
        "m_selfie_09_clip",
        "Homme Mirroir Selfie 3",
        AnimationOptions = {
            Prop = 'prop_phone_ing',
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169,
            PropPlacement = {
                0.0400,
                -0.0300,
                0.0000,
                -46.0563529,
                -0.6965831,
                -4.2803096
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["sittv"] = {
        "anim@heists@heist_safehouse_intro@variations@male@tv",
        "tv_part_one_loop",
        "Assis TV",
        AnimationOptions = {
            Prop = "v_res_tre_remote",
            PropBone = 57005,
            PropPlacement = {
                0.0990,
                0.0170,
                -0.0300,
                -64.760,
                -109.544,
                18.717
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf"] = { -- Emote by WhiskerValeMods
        "mouse@femalearmchair",
        "female_armchair_clip_01",
        "Assis Chaise - Fauteuil",
        AnimationOptions = {
            Prop = "p_armchair_01_s",
            PropBone = 11816,
            PropPlacement = {
                0.5320,
                -0.3310,
                0.2000,
                -90.0000,
                -180.0000,
                -40.9999
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf2"] = { -- Custom Emote by WhiskerValeMods
        "mouse@female_sitting_folded",
        "female_sitting_folded_clip",
        "Assis Chaise - Bras Croisée",
        AnimationOptions = {
            Prop = "ba_prop_battle_club_chair_03",
            PropBone = 0,
            PropPlacement = { 0.0,
                              0.0,
                              0.0,
                              0.0,
                              0.0,
                              -170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf3"] = { -- Custom Emote by WhiskerValeMods
        "mouse@female_sitting_forward",
        "female_sitting_forward_clip",
        "Assis Chaise - Penché en Avant",
        AnimationOptions = {
            Prop = "ba_prop_battle_club_chair_03",
            PropBone = 0,
            PropPlacement = { 0.0,
                              0.0,
                              0.0,
                              0.0,
                              0.0,
                              -170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf4"] = { -- Custom Emote by WhiskerValeMods
        "mouse@female_smart_sitting",
        "female_smart_sitting_clip",
        "Assis Chaise - Malin",
        AnimationOptions = {
            Prop = "ba_prop_battle_club_chair_03",
            PropBone = 0,
            PropPlacement = { 0.0,
                              0.0,
                              0.0,
                              0.0,
                              0.0,
                              -170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf5"] = { -- Custom Emote By WhiskerValeMods
        "mouse@female_smart_sitting_crossed",
        "female_smart_sitting_crossed_clip",
        "Assis Chaise - Jambe Croisé",
        AnimationOptions = {
            Prop = "ba_prop_battle_club_chair_03",
            PropBone = 0,
            PropPlacement = { 0.0,
                              0.0,
                              0.0,
                              0.0,
                              0.0,
                              -170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf6"] = { -- Custom Emote By WhiskerValeMods
        "mouse@female_sitting_laptop",
        "female_sitting_laptop_clip",
        "Assis Chaise - Laptop",
        AnimationOptions = {
            Prop = 'ba_prop_club_laptop_dj_02',
            PropBone = 57005,
            PropPlacement = {
                0.0860,
                -0.1370,
                -0.1750,
                -79.9999,
                -90.0000,
                0.0000
            },
            SecondProp = 'ba_prop_battle_club_chair_02',
            SecondPropBone = 0,
            SecondPropPlacement = {
                -0.0400,
                -0.1900,
                0.0000,
                -180.0000,
                -180.0000,
                9.0999
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf7"] = { -- Custom Emote By Emote by WhiskerValeMods
        "mouse@female_sitting_tablet",
        "female_sitting_tablet_clip",
        "Assis Chaise - Tablette",
        AnimationOptions = {
            Prop = 'hei_prop_dlc_tablet',
            PropBone = 28422,
            PropPlacement = {
                0.0870,
                0.1030,
                -0.1240,
                144.3540,
                157.8527,
                -4.6318
            },
            SecondProp = 'ba_prop_battle_club_chair_02',
            SecondPropBone = 0,
            SecondPropPlacement = {
                0.0100,
                -0.0800,
                0.0200,
                150.0000,
                -180.0000,
                10.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sitchairf8"] = { -- Custom Emote By Emote by WhiskerValeMods
        "mouse@female_sitting_tablet",
        "female_sitting_tablet_clip",
        "Assis Chaise - Livre",
        AnimationOptions = {
            Prop = 'v_ilev_mp_bedsidebook',
            PropBone = 28422,
            PropPlacement = {
                0.1300,
                0.1100,
                -0.1200,
                120.3356,
                -15.9891,
                26.1497
            },
            SecondProp = 'ba_prop_battle_club_chair_02',
            SecondPropBone = 0,
            SecondPropPlacement = {
                0.0100,
                -0.0800,
                0.0200,
                150.0000,
                -180.0000,
                10.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["dig"] = {
        "random@burial",
        "a_burial",
        "Creuser",
        AnimationOptions = {
            Prop = "prop_tool_shovel",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.24,
                0,
                0,
                0.0,
                0.0
            },
            SecondProp = 'prop_ld_shovel_dirt',
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.0,
                0.0,
                0.24,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ['axe'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Hache',
        AnimationOptions = {
            Prop = 'prop_tool_fireaxe',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["axe2"] = {
        "melee@large_wpn@streamed_core",
        "ground_attack_on_spot",
        "hache - Taper au Sol",
        AnimationOptions = {
            Prop = "prop_tool_fireaxe",
            PropBone = 57005,
            PropPlacement = {
                0.0160,
                -0.3140,
                -0.0860,
                -97.1455,
                165.0749,
                13.9114,
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ['axe3'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Hache - Pioche',
        AnimationOptions = {
            Prop = 'prop_tool_pickaxe',
            PropBone = 57005,
            PropPlacement = {
                0.0400,
                -0.2550,
                -0.1380,
                -109.0238,
                163.6144,
                20.6091
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["axe4"] = {
        "melee@large_wpn@streamed_core",
        "ground_attack_on_spot",
        "Hache - Pioche Tape au Sol",
        AnimationOptions = {
            Prop = "prop_tool_pickaxe",
            PropBone = 57005,
            PropPlacement = {
                0.08,
                -0.1,
                -0.04,
                78.0,
                -20.0,
                175.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["bongos"] = {
        "amb@world_human_musician@bongos@male@base",
        "base",
        "Tambours Bongo",
        AnimationOptions = {
            Prop = "prop_bongos_01",
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["medbag"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Sac Médical",
        AnimationOptions = {
            Prop = "xm_prop_x17_bag_med_01a",
            PropBone = 57005,
            PropPlacement = {
                0.3900,
                -0.0600,
                -0.0600,
                -100.00,
                -180.00,
                -78.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["medbox"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Boîte Médicale",
        AnimationOptions = {
            Prop = "xm_prop_smug_crate_s_medical",
            PropBone = 28422,
            PropPlacement = {
                0.2500,
                0.0200,
                -0.0100,
                90.0000,
                0.0000,
                -81.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["dufbag"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Sac de sport",
        AnimationOptions = {
            Prop = "bkr_prop_duffel_bag_01a",
            PropBone = 28422,
            PropPlacement = {
                0.2600,
                0.0400,
                0.00,
                90.00,
                0.00,
                -78.99
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shopbag"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Sac de courses",
        AnimationOptions = {
            Prop = "vw_prop_casino_shopping_bag_01a",
            PropBone = 28422,
            PropPlacement = {
                0.24,
                0.03,
                -0.04,
                0.00,
                -90.00,
                10.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shopbag2"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Shopping Sac 2",
        AnimationOptions = {
            Prop = "prop_shopping_bags02",
            PropBone = 28422,
            PropPlacement = {
                0.05,
                0.02,
                0.00,
                178.80,
                91.19,
                9.97
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shopbag3"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Shopping Sac 3",
        AnimationOptions = {
            Prop = "prop_cs_shopping_bag",
            PropBone = 28422,
            PropPlacement = {
                0.24,
                0.03,
                -0.04,
                0.00,
                -90.00,
                10.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['shopbag4'] = {
        'chocoholic@single54',
        'single54_clip',
        'Shopping Sac 4',
        AnimationOptions = {
            Prop = 'prop_carrier_bag_01',
            PropBone = 28422,
            PropPlacement = {
                0.2280,
                0.0070,
                -0.1230,
                1.2556,
                -53.8020,
                -34.4621
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                { Name = "<font color=\"#00A0F4\">Blue", Value = 0 },
                { Name = "<font color=\"#1AA20E\">Green", Value = 1 },
                { Name = "<font color=\"#800B0B\">Dark Red", Value = 2 },
                { Name = "<font color=\"#FF7B00\">Orange", Value = 3 },
                { Name = "<font color=\"#5F5F5F\">Grey", Value = 4 },
                { Name = "<font color=\"#a356fa\">Purple", Value = 5 },
                { Name = "<font color=\"#FF0099\">Pink", Value = 6 },
                { Name = "Black", Value = 7 }
            },
            SecondPropBone = 60309, -- Left Wrist
            SecondPropPlacement = {
                0.0910,
                0.0410,
                -0.0040,
                -129.2433,
                -18.1966,
                -41.2633
            },
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200,
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["handbag"] = { -- Custom prop by crowded1337
        "move_weapon@jerrycan@generic",
        "idle",
        "Sac a Main",
        AnimationOptions = {
            Prop = 'prop_amb_handbag_01',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.2000,
                0.0300,
                -0.0200,
                90.4294,
                -177.4267,
                83.0011
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["idcard"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 1",
        AnimationOptions = {
            Prop = "prop_franklin_dl",
            PropBone = 28422,
            PropPlacement = {
                0.040,
                -0.039,
                -0.039,
                73.800,
                -11.557,
                103.616
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcardb"] = {
        "paper_1_rcm_alt1-8",
        "player_one_dual-8",
        "Carte D'identité 2 - FIB",
        AnimationOptions = {
            Prop = "prop_fib_badge",
            PropBone = 28422,
            PropPlacement = {
                0.0600,
                0.0210,
                -0.0400,
                -90.00,
                -180.00,
                78.999
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcardc"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 3",
        AnimationOptions = {
            Prop = "prop_michael_sec_id",
            PropBone = 28422,
            PropPlacement = {
                0.0840,
                0.0200,
                -0.0260,
                -173.8514,
                -88.0171,
                63.0612
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcardd"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 4",
        AnimationOptions = {
            Prop = "prop_trev_sec_id",
            PropBone = 28422,
            PropPlacement = {
                0.0840,
                0.0200,
                -0.0260,
                -173.8514,
                -88.0171,
                63.0612
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcarde"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 5",
        AnimationOptions = {
            Prop = "prop_casey_sec_id",
            PropBone = 28422,
            PropPlacement = {
                0.0840,
                0.0200,
                -0.0260,
                -173.8514,
                -88.0171,
                63.0612
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcardf"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 6",
        AnimationOptions = {
            Prop = "prop_cs_r_business_card",
            PropBone = 28422,
            PropPlacement = {
                0.0840,
                0.0200,
                -0.0260,
                -173.8514,
                -88.0171,
                63.0612
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcardg"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 7",
        AnimationOptions = {
            Prop = "p_ld_id_card_002",
            PropBone = 28422,
            PropPlacement = {
                0.0840,
                0.0200,
                -0.0260,
                -173.8514,
                -88.0171,
                63.0612
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["idcardh"] = {
        "cop_badge_1@dad", -- Custom Animation by Darks Animations
        "cop_badge_1_clip",
        "Carte D'identité 8 - Badge Flic",
        AnimationOptions = {
            Prop = "prop_cop_badge",
            PropBone = 28422,
            PropPlacement = {
                0.0390,
                -0.0100,
                -0.0590,
                -103.1785,
                -176.6694,
                74.9000
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true,
        }
    },
    ["idcardi"] = {
        "paper_1_rcm_alt1-8",
        "player_one_dual-8",
        "Carte D'identité 9 - Permis",
        AnimationOptions = {
            Prop = "bkr_prop_fakeid_singledriverl",
            PropBone = 28422,
            PropPlacement = {
                0.0700,
                0.0260,
                -0.0320,
                -10.8683,
                -177.8499,
                23.6377
            },
            EmoteStuck = true,
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["phone"] = {
        "cellphone@",
        "cellphone_text_read_base",
        "Téléphone",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sms"] = {
        "cellphone@",
        "cellphone_text_read_base",
        "SMS",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = false,
            EmoteMoving = true,
            ExitEmote = "phoneaway",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["sms2"] = {
        "cellphone@female",
        "cellphone_text_read_base",
        "SMS 2",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.00,
                0.00,
                0.0301,
                0.000,
                00.00,
                00.00
            },
            EmoteLoop = false,
            EmoteMoving = true,
            ExitEmote = "phoneaway",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["sms3"] = {
        "cellphone@female",
        "cellphone_email_read_base",
        "SMS 3",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                -0.0190,
                -0.0240,
                0.0300,
                18.99,
                -72.07,
                6.39
            },
            EmoteLoop = false,
            EmoteMoving = true,
            ExitEmote = "phoneaway",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["sms4"] = {
        "cellphone@female",
        "cellphone_text_read_base_cover_low",
        "SMS 4",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                -0.0190,
                -0.0250,
                0.0400,
                19.17,
                -78.50,
                14.97
            },
            EmoteLoop = false,
            EmoteMoving = true,
            ExitEmote = "phoneaway",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["sms5"] = {
        "amb@code_human_wander_texting_fat@male@base",
        "static",
        "SMS 5",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                -0.0200,
                -0.0100,
                0.00,
                2.309,
                88.845,
                29.979
            },
            EmoteLoop = false,
            EmoteMoving = true,
            ExitEmote = "phoneaway",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["smssit"] = { -- Custom Emote Provided To RPEmotes By Mr. Witt
        "mrwitt@phone_time_on_floor",
        "mrwitt",
        "SMS Assis",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 26611,
            PropPlacement = {
                0.0560,
                -0.0270,
                0.0170,
                -19.9298,
                -4.6998,
                1.7081
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["tire"] = {
        "anim@heists@box_carry@",
        "idle",
        "Pneu",
        AnimationOptions = {
            Prop = "prop_wheel_tyre",
            PropBone = 60309,
            PropPlacement = {
                -0.05,
                0.16,
                0.32,
                -130.0,
                -55.0,
                150.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["golfswing"] = {
        "rcmnigel1d",
        "swing_a_mark",
        "Swing de Golf",
        AnimationOptions = {
            EmoteLoop = true,
            Prop = "prop_golf_wood_01",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            }
        }
    },
    ["register"] = {
        "anim@heists@box_carry@",
        "idle",
        "Caisse enregistreuse",
        AnimationOptions = {
            Prop = "v_ret_gc_cashreg",
            PropBone = 60309,
            PropPlacement = {
                0.138,
                0.2,
                0.2,
                -50.0,
                290.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["weedbrick"] = {
        "impexp_int-0",
        "mp_m_waremech_01_dual-0",
        "Brique Weed",
        AnimationOptions = {
            Prop = "prop_weed_block_01",
            PropBone = 60309,
            PropPlacement = {
                0.1,
                0.1,
                0.05,
                0.0,
                -90.0,
                90.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["weedbrick2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Grosse Brique Weed",
        AnimationOptions = {
            Prop = "bkr_prop_weed_bigbag_01a",
            PropBone = 60309,
            PropPlacement = {
                0.158,
                -0.05,
                0.23,
                -50.0,
                290.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["potplant"] = {
        "anim@heists@box_carry@",
        "idle",
        "Pot (Petit)",
        AnimationOptions = {
            Prop = "bkr_prop_weed_01_small_01c",
            PropBone = 60309,
            PropPlacement = {
                0.138,
                -0.05,
                0.23,
                -50.0,
                290.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["potplant2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Pot (Moyen)",
        AnimationOptions = {
            Prop = "bkr_prop_weed_01_small_01b",
            PropBone = 60309,
            PropPlacement = {
                0.138,
                -0.05,
                0.23,
                -50.0,
                290.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["potplant3"] = {
        "anim@heists@box_carry@",
        "idle",
        "Pot (Gros)",
        AnimationOptions = {
            Prop = "bkr_prop_weed_lrg_01b",
            PropBone = 60309,
            PropPlacement = {
                0.138,
                -0.05,
                0.23,
                -50.0,
                290.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["weedbucket"] = {
        "anim@heists@box_carry@",
        "idle",
        "Seau Weed",
        AnimationOptions = {
            Prop = "bkr_prop_weed_bucket_open_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.1000,
                -0.1800,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["lawnchair"] = {
        "timetable@ron@ig_5_p3",
        "ig_5_p3_base",
        "Chaise de Camping",
        AnimationOptions = {
            Prop = "prop_skid_chair_02",
            PropBone = 0,
            PropPlacement = {
                0.025,
                -0.2,
                -0.1,
                45.0,
                -5.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["lawnchair2"] = {
        "timetable@reunited@ig_10",
        "base_amanda",
        "Chaise de Camping 2",
        AnimationOptions = {
            Prop = "prop_skid_chair_02",
            PropBone = 0,
            PropPlacement = {
                0.025,
                -0.15,
                -0.1,
                45.0,
                5.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["lawnchair3"] = {
        "timetable@ron@ig_3_couch",
        "base",
        "Chaise de Camping 3",
        AnimationOptions = {
            Prop = "prop_skid_chair_02",
            PropBone = 0,
            PropPlacement = {
                -0.05,
                0.0,
                -0.2,
                5.0,
                0.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["rose2"] = {
        "missheistdocksprep1hold_cellphone",
        "static",
        "Rose 2 (Homme)",
        AnimationOptions = {
            Prop = "prop_single_rose",
            PropBone = 31086,
            PropPlacement = {
                -0.0140,
                0.1030,
                0.0620,
                -2.932,
                4.564,
                39.910
            },
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["rose3"] = {
        "missheistdocksprep1hold_cellphone",
        "static",
        "Rose 3 (Femme)",
        AnimationOptions = {
            Prop = "prop_single_rose",
            PropBone = 31086,
            PropPlacement = {
                -0.0140,
                0.1070,
                0.0720,
                0.00,
                0.00,
                2.99
            },
            EmoteLoop = false,
            EmoteMoving = true
        }
    },
    ["cbbox"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Pack Bière",
        AnimationOptions = {
            Prop = "v_ret_ml_beerben1",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cbbox2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Pack Bière 2",
        AnimationOptions = {
            Prop = "v_ret_ml_beerbla1",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cbbox3"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Pack Bière 3",
        AnimationOptions = {
            Prop = "v_ret_ml_beerjak1",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cbbox4"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Pack Bière 4",
        AnimationOptions = {
            Prop = "v_ret_ml_beerlog1",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cbbox5"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Pack Bière 5",
        AnimationOptions = {
            Prop = "v_ret_ml_beerpis1",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cbbox6"] = {
        "anim@heists@box_carry@",
        "idle",
        "Porter Pack Bière 6",
        AnimationOptions = {
            Prop = "prop_beer_box_01",
            PropBone = 28422,
            PropPlacement = {
                0.0200,
                -0.0600,
                -0.1200,
                -180.00,
                -180.00,
                1.99
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gbin"] = {
        "anim@heists@box_carry@",
        "idle",
        "Poubelle",
        AnimationOptions = {
            Prop = "prop_bin_08open",
            PropBone = 28422,
            PropPlacement = {
                0.00,
                -0.420,
                -1.290,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gbin2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Poubelle 2",
        AnimationOptions = {
            Prop = "prop_cs_bin_01",
            PropBone = 28422,
            PropPlacement = {
                0.00,
                -0.420,
                -1.290,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gbin3"] = {
        "anim@heists@box_carry@",
        "idle",
        "Poubelle 3",
        AnimationOptions = {
            Prop = "prop_cs_bin_03",
            PropBone = 28422,
            PropPlacement = {
                0.00,
                -0.420,
                -1.290,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gbin4"] = {
        "anim@heists@box_carry@",
        "idle",
        "Poubelle 4",
        AnimationOptions = {
            Prop = "prop_bin_08a",
            PropBone = 28422,
            PropPlacement = {
                0.00,
                -0.420,
                -1.290,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["gbin5"] = {
        "anim@heists@box_carry@",
        "idle",
        "Poubelle 5",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 28422,
            PropPlacement = {
                -0.0100,
                -0.2200,
                -0.8600,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride - Arc-En-Ciel',
        AnimationOptions = {
            Prop = 'prideflag1',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag2'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 2 - LGBTQ',
        AnimationOptions = {
            Prop = 'prideflag2',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag3'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 3 - Bisexual ',
        AnimationOptions = {
            Prop = 'prideflag3',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag4'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 4 - Lesbian ',
        AnimationOptions = {
            Prop = 'prideflag4',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag5'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 5 - Pansexual ',
        AnimationOptions = {
            Prop = 'prideflag5',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag6'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 6 - Transgender  ',
        AnimationOptions = {
            Prop = 'prideflag6',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag7'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 7 - Non Binaire ',
        AnimationOptions = {
            Prop = 'prideflag7',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag8'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 8 - Asexual ',
        AnimationOptions = {
            Prop = 'prideflag8',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['pflag9'] = {
        'rcmnigel1d',
        'base_club_shoulder',
        'Drapeau Pride 9 - Hétéro ',
        AnimationOptions = {
            Prop = 'prideflag9',
            PropBone = 18905,
            PropPlacement = {
                0.0800,
                -0.2090,
                0.0900,
                -82.6677,
                -141.2988,
                12.3308
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['old'] = {
        'missbigscore2aleadinout@bs_2a_2b_int',
        'lester_base_idle',
        'Canne Vieux',
        AnimationOptions = {
            Prop = 'prop_cs_walking_stick',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                { Name = "<font color=\"#00A0F4\">Blue", Value = 0 },
                { Name = "<font color=\"#1AA20E\">Green", Value = 1 },
                { Name = "<font color=\"#800B0B\">Dark Red", Value = 2 },
                { Name = "<font color=\"#FF7B00\">Orange", Value = 3 },
                { Name = "<font color=\"#5F5F5F\">Grey", Value = 4 },
                { Name = "<font color=\"#a356fa\">Purple", Value = 5 },
                { Name = "<font color=\"#FF0099\">Pink", Value = 6 },
                { Name = "Black", Value = 7 },
            },
            SecondPropBone = 60309, -- Left Wrist
            SecondPropPlacement = {
                0.0740,
                0.0410,
                0.0090,
                -127.9136,
                -10.6186,
                4.7536
            },
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200,
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['old2'] = { -- Custom Animation By Darks Animations
        'zimmerframe_walk@dark',
        'zimmerframe_walk_clip',
        'Vieux Zimmerframe',
        AnimationOptions = {
            Prop = 'v_res_d_zimmerframe',
            PropBone = 28252,
            PropPlacement = {
                0.9500,
                -0.6640,
                -0.5470,
                -122.4053,
                85.0955,
                23.1787,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['lighter'] = {
        'ebrwny_pack000',
        'ebrwny_spark',
        'Allumer - Cigare',
        AnimationOptions = {
            Prop = 'lux_prop_lighter_luxe',
            PropBone = 26612,
            PropPlacement = {
                0.0300,
                -0.0360,
                0.0270,
                -168.0000,
                -180.0000,
                8.0000
            },
            SecondProp = 'prop_cigar_01',
            SecondPropBone = 17188,
            SecondPropPlacement = {
                0.0450,
                0.0130,
                0.0170,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                0.0615,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.5
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ['lighter2'] = {
        'ebrwny_pack000',
        'ebrwny_spark',
        'Allumer - Cigare Assis',
        AnimationOptions = {
            Prop = 'lux_prop_lighter_luxe',
            PropBone = 26612,
            PropPlacement = {
                0.0300,
                -0.0360,
                0.0270,
                -168.0000,
                -180.0000,
                8.0000
            },
            SecondProp = 'prop_cigar_01',
            SecondPropBone = 17188,
            SecondPropPlacement = {
                0.0450,
                0.0130,
                0.0170,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits",
            PtfxPlacement = {
                0.0615,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.5
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["party_lighter"] = { -- Custom Prop & Emote By BzZz
        "samnick@lighter@wave",
        "waving_lighter",
        "Feu Fête",
        AnimationOptions = {
            Prop = 'samnick_prop_lighter01',
            PropBone = 18905,
            PropPlacement = {
                0.11,
                0.01,
                0.02,
                -85.0,
                188.0,
                10.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['digiscan'] = {
        'weapons@misc@digi_scanner',
        'aim_med_loop',
        'Digiscan 1 ',
        AnimationOptions = {
            Prop = 'w_am_digiscanner',
            PropBone = 28422,
            PropPlacement = {
                0.0480,
                0.0780,
                0.0040,
                -81.6893,
                2.5616,
                -15.7909
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['digiscan2'] = {
        'weapons@misc@digi_scanner',
        'aim_low_loop',
        'Digiscan 2 ',
        AnimationOptions = {
            Prop = 'w_am_digiscanner',
            PropBone = 28422,
            PropPlacement = {
                0.0480,
                0.0780,
                0.0040,
                -81.6893,
                2.5616,
                -15.7909
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['digiscan3'] = {
        'weapons@misc@digi_scanner',
        'aim_high_loop',
        'Digiscan 3 ',
        AnimationOptions = {
            Prop = 'w_am_digiscanner',
            PropBone = 28422,
            PropPlacement = {
                0.0480,
                0.0780,
                0.0040,
                -81.6893,
                2.5616,
                -15.7909
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cop4"] = {
        "amb@world_human_car_park_attendant@male@base",
        "base",
        "Flic 4",
        AnimationOptions = {
            Prop = "prop_parking_wand_01",
            PropBone = 57005,
            PropPlacement = {
                0.12,
                0.05,
                0.0,
                80.0,
                -20.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["copbeacon"] = { -- Added for compatibility
        "amb@world_human_car_park_attendant@male@base",
        "base",
        "Flic Balise",
        AnimationOptions = {
            Prop = "prop_parking_wand_01",
            PropBone = 57005,
            PropPlacement = {
                0.12,
                0.05,
                0.0,
                80.0,
                -20.0,
                180.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["leanphone"] = {
        "amb@world_human_leaning@male@wall@back@mobile@base",
        "base",
        "Penché avec le téléphone",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            }
        }
    },
    ["hump2"] = {
        "timetable@trevor@skull_loving_bear",
        "skull_loving_bear",
        "Baiser (Ours)",
        AnimationOptions = {
            Prop = 'prop_mr_raspberry_01',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteMoving = false,
            EmoteLoop = true
        },
        AdultAnimation = true
    },
    ["drink"] = {
        "mp_player_intdrink",
        "loop_bottle",
        "Boire",
        AnimationOptions =
        {
            Prop = "prop_ld_flow_bottle",
            PropBone = 18905,
            PropPlacement = {
                0.12,
                0.008,
                0.03,
                240.0,
                -60.0
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["surfboard"] = { -- Emote by Molly
        "beachanims@molly",
        "beachanim_surf_clip",
        "Planche à Surf",
        AnimationOptions =
        {
            Prop = "prop_surf_board_ldn_02",
            PropBone = 28252,
            PropPlacement = {
                0.1020,
                -0.1460,
                -0.1160,
                -85.5416,
                176.1446,
                -2.1500
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["stealtv"] = { -- Emote by Molly
        "beachanims@molly",
        "beachanim_surf_clip",
        "Vol TV",
        AnimationOptions =
        {
            Prop = "xs_prop_arena_screen_tv_01",
            PropBone = 28252,
            PropPlacement = {
                0.2600,
                0.1100,
                -0.1400,
                96.1620,
                168.9069,
                84.2402
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["beachring"] = { -- Emote by Molly
        "beachanims@free",
        "beachanim_clip",
        "Bouée de plage",
        AnimationOptions = {

            Prop = "prop_beach_ring_01",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.0,
                0.0100,
                -12.0,
                0.0,
                -2.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cashcase"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Malette Argent",
        AnimationOptions = {
            Prop = "bkr_prop_biker_case_shut",
            PropBone = 28422,
            PropPlacement = {
                0.1000,
                0.0100,
                0.0040,
                0.0,
                0.0,
                -90.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cashcase2"] = {
        "anim@heists@box_carry@",
        "idle",
        "Malette Argent 2",
        AnimationOptions = {
            Prop = "prop_cash_case_01",
            PropBone = 28422,
            PropPlacement = {
                -0.0050,
                -0.1870,
                -0.1400,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cashcase3"] = {
        "anim@heists@box_carry@",
        "idle",
        "Malette Argent 3",
        AnimationOptions = {
            Prop = "prop_cash_case_02",
            PropBone = 28422,
            PropPlacement = {
                0.0050,
                -0.1170,
                -0.1400,
                14.000,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cashcase4"] = {
        "anim@heists@box_carry@",
        "idle",
        "Malette Argent 4 - Diamands",
        AnimationOptions = {
            Prop = "ch_prop_ch_security_case_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0900,
                -0.1800,
                14.4000,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["airportbag"] = {
        "anim@heists@narcotics@trash",
        "idle",
        "Sac Aéroport",
        AnimationOptions = {
            Prop = "prop_suitcase_01c",
            PropBone = 28422,
            PropPlacement = {
                0.1100,
                -0.2100,
                -0.4300,
                -11.8999,
                0.0,
                30.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["airportbag2"] = { -- Custom Emote By Dark Animations exclusive to RPEmotes
        "suitcase_phone@dark",
        "suitcase_phone_clip",
        "Sac Aéroport 2 - Téléphone",
        AnimationOptions = {
            Prop = 'prop_suitcase_03',
            PropBone = 60309,
            PropPlacement = {
                0.4700,
                -0.0400,
                -0.3500,
                -120.0000,
                -180.0000,
                -79.9999
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                { Name = "<font color=\"#00A0F4\">Blue", Value = 0 },
                { Name = "<font color=\"#1AA20E\">Green", Value = 1 },
                { Name = "<font color=\"#800B0B\">Dark Red", Value = 2 },
                { Name = "<font color=\"#FF7B00\">Orange", Value = 3 },
                { Name = "<font color=\"#5F5F5F\">Grey", Value = 4 },
                { Name = "<font color=\"#a356fa\">Purple", Value = 5 },
                { Name = "<font color=\"#FF0099\">Pink", Value = 6 },
                { Name = "Black", Value = 7 },
            },
            SecondPropBone = 28422,
            SecondPropPlacement = {
                0.1040,
                0.0320,
                -0.0200,
                -108.6997,
                -150.5805,
                46.7080
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200
        }
    },
    ["airportbag3"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@single63",
        "single63_clip",
        "Sac Aéroport 3 - Pose",
        AnimationOptions = {
            Prop = "prop_suitcase_03",
            PropBone = 58869,
            PropPlacement = {
                0.2100,
                0.4100,
                -0.3600,
                56.9074,
                -6.1917,
                -24.3334
            },
            EmoteLoop = true,
        }
    },
    ["megaphone"] = { -- Custom Emote By MollyEmotes
        "molly@megaphone",
        "megaphone_clip",
        "Megaphone",
        AnimationOptions = {
            Prop = "prop_megaphone_01",
            PropBone = 28422,
            PropPlacement = {
                0.0500,
                0.0540,
                -0.0060,
                -71.8855,
                -13.0889,
                -16.0242
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["megaphone2"] = { -- Custom Emote By MollyEmotes
        "molly@megaphone2",
        "megaphone_clip",
        "Megaphone 2",
        AnimationOptions = {
            Prop = "prop_megaphone_01",
            PropBone = 28422,
            PropPlacement = {
                0.0500,
                0.0540,
                -0.0060,
                -71.8855,
                -13.0889,
                -16.0242
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["megaphone3"] = {
        "anim@rifle_megaphone",
        "rifle_holding_megaphone",
        "Megaphone 3",
        AnimationOptions = {
            Prop = "prop_megaphone_01",
            PropBone = 60309,
            PropPlacement = {
                0.0480,
                0.0190,
                0.0160,
                -94.8944,
                -2.3093,
                -10.9030
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["easter"] = {
        "anim@heists@narcotics@trash",
        "idle",
        "Panier Paques",
        AnimationOptions = {
            Prop = "bzzz_event_easter_basket_b",
            PropBone = 28422,
            PropPlacement = {
                0.0040,
                0.0400,
                -0.2420,
                19.9999,
                0.0,
                -10.0000
            },
            SecondProp = 'bzzz_event_easter_egg_d',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0790,
                0.0090,
                0.0190,
                -120.0000,
                0.0,
                0.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["easter2"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Lapin de Paques",
        AnimationOptions = {
            Prop = "bzzz_event_easter_bunny_a",
            PropBone = 60309,
            PropPlacement = {
                -0.0270,
                -0.0200,
                0.0100,
                62.9161,
                0.4622,
                10.8906
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bball"] = { -- Custom Emote By Struggleville
        "anim@male_bskball_hold",
        "bskball_hold_clip",
        "Tenir Ballon Basket",
        AnimationOptions = {
            Prop = "prop_bskball_01",
            PropBone = 28422,
            PropPlacement = {
                0.0600,
                0.0400,
                -0.1200,
                0.0,
                0.0,
                40.00
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bball2"] = { -- Custom Emote By Struggleville
        "anim@male_bskball_photo_pose",
        "photo_pose_clip",
        "Tenir Ballon Basket Pose",
        AnimationOptions = {
            Prop = "prop_bskball_01",
            PropBone = 60309,
            PropPlacement = {
                -0.0100,
                0.0200,
                0.1300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bball3"] = { -- Custom Emote By Struggleville
        "anim@male_basketball_03",
        "m_basketball_03_clip",
        "Tenir Ballon Basket 2",
        AnimationOptions = {
            Prop = "prop_bskball_01",
            PropBone = 28422,
            PropPlacement = {
                0.0400,
                0.0200,
                -0.1400,
                90.0000,
                -99.9999,
                79.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["bball4"] = { -- Custom Emote By SapphireMods
        "mx@pose2",
        "mx_clippose2",
        "Tenir Ballon Basket 3",
        AnimationOptions = {
            Prop = "prop_bskball_01",
            PropBone = 28422,
            PropPlacement = {
                0.0400,
                0.0200,
                -0.1400,
                90.0000,
                -99.9999,
                79.9999
            },
            EmoteLoop = true
        }
    },
    ["bball5"] = {
        "cover@weapon@grenade",
        "hi_r_cook",
        "Tenir Ballon Basket Pose 4",
        AnimationOptions = {
            Prop = "prop_bskball_01",
            PropBone = 28422,
            PropPlacement = {
                0.0400,
                0.0200,
                -0.1400,
                90.0000,
                -99.9999,
                79.9999
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["ftorch"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Torche enflammée",
        AnimationOptions = {
            Prop = "bzzz_prop_torch_fire001", -- Custom Prop by BzZz Used With Permission
            PropBone = 18905,
            PropPlacement = {
                0.14,
                0.21,
                -0.08,
                -110.0,
                -1.0,
                -10.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['ftorch2'] = {
        'special_ped@griff@base',
        'base',
        'Torche 2',
        AnimationOptions = {
            Prop = "bzzz_prop_torch_fire001", -- Custom Prop by BzZz Used With Permission
            PropBone = 28422,
            PropPlacement = {
                0.0100,
                0.0300,
                0.0500,
                0.0000,
                0.0000,
                0.0000,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ['candle'] = {
        'special_ped@griff@base',
        'base',
        'Bougie',
        AnimationOptions = {
            Prop = "v_res_fa_candle04",
            PropBone = 28422,
            PropPlacement = {
                0.0200,
                0.0100,
                0.0100,
                0.0000,
                10.0000,
                0.0000,
            },
            EmoteMoving = true,
            EmoteLoop = true,
            PtfxAsset = "core",
            PtfxName = "ent_amb_candle_flame",
            PtfxNoProp = true,
            PtfxBone = 28422,
            PtfxPlacement = {
                0.0200,
                0.0100,
                0.0600,
                0.0000,
                10.0000,
                0.0000,
            },
            PtfxInfo = ('candle'),
            PtfxWait = 30000, -- ptfxwait is in ms, so 30000 = 30 seconds. This allows the effect to linger for 30 seconds.
            PtfxCanHold = true
        }
    },
    ["watchstripper2"] = {
        "amb@world_human_strip_watch_stand@male_c@base",
        "base",
        "Regarder Stripteaseuse 2",
        AnimationOptions = {
            Prop = "prop_beer_am",
            PropBone = 60309,
            PropPlacement = {
                0.0880,
                -0.1360,
                0.1450,
                -102.9624,
                81.7098,
                -39.2734
            },
            EmoteLoop = true,
            EmoteMoving = true
        },
        AdultAnimation = true
    },
    ["candyapple"] = { -- Custom Prop by hollywoodiownu
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Bonbon Pomme",
        AnimationOptions = {
            Prop = "apple_1",
            PropBone = 18905,
            PropPlacement = {
                0.12,
                0.15,
                0.0,
                -100.0,
                0.0,
                -12.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
        },
    },
    ["gamer"] = { -- Custom Emote By MissSnowie
        "playing@with_controller",
        "base",
        "Manette",
        AnimationOptions = {
            Prop = 'prop_controller_01',
            PropBone = 18905,
            PropPlacement = {
                0.1450,
                0.0590,
                0.0850,
                -164.4546,
                -62.9570,
                17.5872
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["gamer2"] = { -- Custom Emote By Dark Animations exclusive to RPEmotes
        "lay_controller@dark",
        "lay_controller_clip",
        "Manette Posé sur le Ventre",
        AnimationOptions = {
            Prop = 'prop_controller_01',
            PropBone = 18905,
            PropPlacement = {
                0.1350,
                0.0360,
                0.0950,
                -180.0000,
                -72.9699,
                0.0000
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["study"] = { -- Custom Emote By Dark Animations exclusive to RPEmotes
        "study_pc_finally_fixed@dark",
        "study_pc_finally_fixed_clip",
        "Étude",
        AnimationOptions = {
            Prop = 'xm_prop_x17_laptop_lester_01',
            PropBone = 28422,
            PropPlacement = {
                0.1650,
                0.1010,
                -0.1470,
                -159.2533,
                -145.7418,
                -79.5760,
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["crackhead"] = {
        "special_ped@zombie@base",
        "base",
        "Drogué",
        AnimationOptions = {
            Prop = 'prop_cs_bowie_knife', -- Knife
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                -0.1280,
                -0.0220,
                0.0210,
                -150.0005,
                179.9989,
                -30.0105
            },
            SecondProp = 'ng_proc_cigpak01a',
            SecondPropBone = 26614,
            SecondPropPlacement = {
                0.010,
                -0.0190,
                0.0920,
                -82.4073,
                178.6009,
                29.9195
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["propose"] = { -- Custom Emote By ultrahacx
        "ultra@propose",
        "propose",
        "Proposer",
        AnimationOptions = {
            Prop = 'ultra_ringcase', -- Custom prop by ultrahacx
            PropBone = 28422,
            PropPlacement = {
                0.0980,
                0.0200,
                -0.0540,
                -138.6571,
                4.4141,
                -79.3552
            },
            EmoteLoop = true
        }
    },
    ["propose2"] = { -- Custom Emote By ultrahacx
        "ultra@propose",
        "propose",
        "Proposer 2 - Saint Valentin",
        AnimationOptions = {
            Prop = 'pata_freevalentinesday', -- Custom prop by PataMods
            PropBone = 64064,
            PropPlacement = {
                0.0190,
                0.0480,
                0.0110,
                -9.0350,
                88.4373,
                -9.8783
            },
            EmoteLoop = true
        }
    },
    ["propose3"] = { -- Custom Emote By ultrahacx
        "ultra@propose",
        "propose",
        "Proposer 3",
        AnimationOptions = {
            Prop = 'pata_freevalentinesday2', -- Custom prop by PataMods
            PropBone = 64064,
            PropPlacement = {
                0.0190,
                0.0480,
                0.0110,
                -9.0350,
                88.4373,
                -9.8783
            },
            EmoteLoop = true
        }
    },
    ["holdfw"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Tenir Feu D'artifice",
        AnimationOptions = {
            Prop = 'ind_prop_firework_01', -- blue, green, red, purple pink, cyan, yellow, white
            PtfxColor = {{R = 255, G = 0, B = 0, A = 1.0}, {R = 0, G = 255, B = 0, A = 1.0}, {R = 0, G = 0, B = 255, A = 1.0}, {R = 177, G = 5, B = 245, A = 1.0}, {R = 251, G = 3, B = 255, A = 1.0}, {R = 2, G = 238, B = 250, A = 1.0}, {R = 252, G = 248, B = 0, A = 1.0}, {R = 245, G = 245, B = 245, A = 1.0}},
            PropBone = 18905,
            PropPlacement = {
                0.1100,
                0.3200,
                -0.2400,
                -130.0688,
                -2.5736,
                -3.0631
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_indep_fireworks",
            PtfxName = "scr_indep_firework_trail_spawn",
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.6
            },
            PtfxInfo = ('firework'),
            PtfxWait = 200
        }
    },
    ["chillteq"] = { -- Custom Emote By Amnilka
        "amnilka@photopose@female@homepack001",
        "amnilka_femalehome_photopose_003",
        "Détente Tequila",
        AnimationOptions = {
            Prop = 'prop_tequila',
            PropBone = 60309,
            PropPlacement = {
                0.0810,
                -0.0460,
                0.0430,
                -110.1784,
                2.9283,
                -12.5092
            },
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["patrolf1"] = {
        "amb@world_human_security_shine_torch@male@base",
        "base",
        "Patrouille a Pied",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                80.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["patrolf2"] = {
        "amb@world_human_security_shine_torch@male@idle_b",
        "idle_e",
        "Patrouille - A Pied 2",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                80.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["patrolf3"] = {
        "amb@world_human_security_shine_torch@male@idle_a",
        "idle_a",
        "Patrouille - A Pied 3",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 60309,
            PropPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                80.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["patrolf4"] = { -- Huge thanks to MadsLeander on GitHub
        "amb@incar@male@patrol@torch@base",
        "base",
        "Patrouille - A Pied 4 Au Dessus Epaules",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 28422, -- Right Wrist
            PropPlacement = {
                0.0,
                -0.00100,
                0.0,
                0.0,
                0.0,
                90.0
            },
            SecondProp = 'prop_cs_hand_radio',
            SecondPropBone = 60309, -- Left Wrist
            SecondPropPlacement = {
                0.0560,
                0.0470,
                0.0110,
                -43.82733,
                164.6747,
                -7.5569
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pineapple"] = { -- Custom Prop by hollywoodiownu
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Ananas",
        AnimationOptions = {
            Prop = "xm3_prop_xm3_pineapple_01a",
            PropBone = 18905,
            PropPlacement = {
                0.1,
                -0.11,
                0.05,
                -100.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
        },
    },
    ["present"] = {
        "anim@heists@box_carry@",
        "idle",
        "Cadeau",
        AnimationOptions = {
            Prop = "xm3_prop_xm3_present_01a",
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.18,
                -0.16,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["papers"] = {
        "missheistdocksprep1hold_cellphone",
        "static",
        "Papiers",
        AnimationOptions = {
            Prop = "xm3_prop_xm3_papers_01a",
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.0,
                0.04,
                -110.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["vlog"] = {
        "amb@world_human_mobile_film_shocking@male@base",
        "base",
        "Vlog",
        AnimationOptions = {
            Prop = 'prop_ing_camera_01',
            PropBone = 28422,
            PropPlacement = {
                -0.07,
                -0.01,
                0.0,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["vlog2"] = {
        "anim@heists@humane_labs@finale@keycards",
        "ped_a_enter_loop",
        "Vlog 2",
        AnimationOptions = {
            Prop = 'prop_ing_camera_01',
            PropBone = 18905,
            PropPlacement = {
                0.15,
                0.03,
                0.1,
                280.0,
                110.0,
                -11.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["skatesit"] = { -- Custom Emote By CMG Mods
        "skateboardposecmganimation",
        "skateboardposecmg_clip",
        "Skateboard - Assis",
        AnimationOptions = {
            Prop = 'rpemotesreborn_skateboard01',
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.0400,
                -0.2300,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
        }
    },
    ["skatesit2"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@skate2",
        "skate2_clip",
        "Skateboard - Assis 2",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard02",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0200,
                -0.2900,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["skatekneel"] = { -- Custom Emote By DRX Animations
        "drx@skateboard3",
        "drx",
        "Skateboard A Genoux - Homme",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard02",
            PropBone = 64064,
            PropPlacement = {
                0.2000,
                -0.0600,
                0.0,
                -61.0100,
                4.4024,
                -16.913
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["skatekneel2"] = { -- Custom Emote By DRX Animations
        "drx@skateboard3",
        "drx",
        "Skateboard A Genoux 2 - Femme",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard01",
            PropBone = 64064,
            PropPlacement = {
                0.2000,
                -0.0600,
                0.0,
                -61.0100,
                4.4024,
                -16.913
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["skatehold"] = {
        "molly@boombox1",
        "boombox1_clip",
        "Skateboard - Tenir Femme",
        AnimationOptions = {
            Prop = "prop_cs_sol_glasses",
            PropBone = 31086,
            PropPlacement = {
                0.0440,
                0.0740,
                0.0000,
                -160.9843,
                -88.7288,
                -0.6197
            },
            SecondProp = 'rpemotesreborn_skateboard01',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                -0.0050,
                0.0320,
                0.1640,
                44.6076,
                -112.2983,
                -86.1199
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["skatehold2"] = { -- Emote by Molly
        "beachanims@molly",
        "beachanim_surf_clip",
        "Skateboard - Tenir Femme 2",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard01",
            PropBone = 28422,
            PropPlacement = {
                -0.1020,
                0.2240,
                0.0840,
                5.6655,
                175.3526,
                49.7964
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["skatehold3"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@skate4",
        "skate4_clip",
        "Skateboard - Tenir Femme 3",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard01",
            PropBone = 28422,
            PropPlacement = {
                0.2780,
                -0.0200,
                -0.0700,
                -180.0000,
                28.0000,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["skatehold4"] = {
        "molly@boombox1",
        "boombox1_clip",
        "Skateboard - Tenir Homme",
        AnimationOptions = {
            Prop = "prop_cs_sol_glasses",
            PropBone = 31086,
            PropPlacement = {
                0.0440,
                0.0740,
                0.0000,
                -160.9843,
                -88.7288,
                -0.6197
            },
            SecondProp = 'rpemotesreborn_skateboard02',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                -0.0050,
                0.0320,
                0.1640,
                44.6076,
                -112.2983,
                -86.1199
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["skatehold5"] = { -- Emote by Molly
        "beachanims@molly",
        "beachanim_surf_clip",
        "Skateboard - Tenir Homme 2",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard02",
            PropBone = 28422,
            PropPlacement = {
                -0.1020,
                0.2240,
                0.0840,
                5.6655,
                175.3526,
                49.7964
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["skatehold6"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@skate4",
        "skate4_clip",
        "Skateboard - Tenir Homme 3",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard02",
            PropBone = 28422,
            PropPlacement = {
                0.2780,
                -0.0200,
                -0.0700,
                -180.0000,
                28.0000,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["skatehold7"] = { -- Custom Emote By DRX Animations
        "drx@skateboard2",
        "drx",
        "Skateboard - Tenir Homme DRX",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard02",
            PropBone = 64080,
            PropPlacement = {
                0.2670,
                -0.0060,
                0.0560,
                -0.2472,
                -13.1506,
                -33.6511
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["skatehold8"] = { -- Custom Emote By DRX Animations
        "drx@skateboard2",
        "drx",
        "Skateboard - Tenir Femme DRX",
        AnimationOptions = {
            Prop = "rpemotesreborn_skateboard01",
            PropBone = 64080,
            PropPlacement = {
                0.2670,
                -0.0060,
                0.0560,
                -0.2472,
                -13.1506,
                -33.6511
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["mafia"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@single12",
        "single12_clip",
        "Mafia Boss - Pointé Arme",
        AnimationOptions = {
            Prop = "w_pi_revolver_b",
            PropBone = 28422,
            PropPlacement = {
                0.1150,
                0.0590,
                -0.0100,
                -69.7101,
                1.4074,
                -13.7554
            },
            SecondProp = 'prop_cigar_01',
            SecondPropBone = 17188,
            SecondPropPlacement = {
                0.0450,
                0.0130,
                0.0170,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_mp_cig",
            PtfxName = "ent_anim_cig_smoke",
            PtfxNoProp = false,
            PtfxPlacement = {
                0.0615,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.5
            },
            PtfxInfo = ('smoke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        }
    },
    ["shield"] = {
        "beachanims@molly",
        "beachanim_surf_clip",
        "Bouclier",
        AnimationOptions = {
            Prop = "prop_riot_shield",
            PropBone = 18905,
            PropPlacement = {
                -0.04,
                -0.06,
                0.0,
                4.04,
                108.17,
                -17.48
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["shield2"] = {
        "beachanims@molly",
        "beachanim_surf_clip",
        "Bouclier 2",
        AnimationOptions = {
            Prop = "prop_ballistic_shield",
            PropBone = 18905,
            PropPlacement = {
                0.01,
                -0.1,
                -0.07,
                1.83,
                105.38,
                -10.14
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["cofpose"] = {
        "chocoholic@single23",
        "single23_clip",
        "Café & Burger Pose",
        AnimationOptions = {
            Prop = "prop_fib_coffee",
            PropBone = 28422,
            PropPlacement = {
                0.0720,
                0.0390,
                -0.0230,
                -125.8797,
                -168.4347,
                17.4518
            },
            SecondProp = 'prop_cs_burger_01',
            SecondPropBone = 60309,
            SecondPropPlacement = {
                0.0860,
                0.0030,
                0.0570,
                106.1459,
                8.0371,
                17.0945
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["holster6"] = {
        "anim@hlstr_7360_torch",
        "flsh_ps",
        "Holster 6 - Lampe Torche",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 60309,
            PropPlacement = {
                0.0550,
                -0.0200,
                0.0370,
                -29.6216,
                -8.6822,
                4.9809
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["holster8"] = {
        "anim@holster_walk_torch",
        "flash_ps",
        "Holster 8 Lampe Torche 2",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 60309,
            PropPlacement = {
                0.0600,
                -0.0100,
                0.0200,
                -20.0000,
                0.0000,
                3.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["heartprop"] = {
        "anim@heists@box_carry@",
        "idle",
        "Accessoire coeur",
        AnimationOptions = {
            Prop = 'brum_heart',
            PropBone = 28422,
            PropPlacement = {
                -0.5600,
                0.0240,
                -0.3690,
                -10.0000,
                0.0000,
                -0.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["popcorn"] = {
        "amb@code_human_wander_drinking@female@base",
        "static",
        "Popcorn",
        AnimationOptions = {
            Prop = 'xs_prop_trinket_cup_01a',
            PropBone = 28422,
            PropPlacement = {
                -0.0200,
                -0.0100,
                -0.0700,
                -179.3626,
                176.9331,
                11.9833
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sax"] = {
        "play_saxophone@dark",
        "play_saxophone_clip",
        "Saxophone 1",
        AnimationOptions = {
            Prop = 'p_ld_sax',
            PropBone = 57005,
            PropPlacement = {
                0.0700,
                0.0400,
                0.0300,
                -71.2242,
                29.3364,
                5.9514
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["poolcue"] = {
        "pool_pack_1@dark",
        "pool_pack_1_clip",
        "Jouer au billard",
        AnimationOptions = {
            Prop = 'prop_pool_cue',
            PropBone = 57005,
            PropPlacement = {
                0.0900,
                0.2000,
                0.0800,
                -61.4338,
                -7.2194,
                3.1642
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["poolcue2"] = {
        "pool_pack_2@dark",
        "pool_pack_2_clip",
        "Jouer au billard 2 (Pose)",
        AnimationOptions = {
            Prop = 'prop_pool_cue',
            PropBone = 57005,
            PropPlacement = {
                0.1200,
                -0.5200,
                -0.1200,
                -78.0400,
                -1.4526,
                1.8479
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["poolcue3"] = {
        "pool_pack_3@dark",
        "pool_pack_3_clip",
        "Jouer au billard 3 (Pose)",
        AnimationOptions = {
            Prop = 'prop_pool_cue',
            PropBone = 57005,
            PropPlacement = {
                0.1200,
                -0.3500,
                -0.0200,
                -90.0000,
                0.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["poolcue4"] = {
        "pool_pack_4@dark",
        "pool_pack_4_clip",
        "Jouer au billard 4 (Pose)",
        AnimationOptions = {
            Prop = 'prop_pool_cue',
            PropBone = 61163,
            PropPlacement = {
                0.2600,
                -0.1600,
                -0.3100,
                -31.8144,
                14.4214,
                -13.2854
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["poolcue5"] = {
        "pool_pack_5@dark",
        "pool_pack_5_clip",
        "Jouer au billard 5",
        AnimationOptions = {
            Prop = 'prop_pool_cue',
            PropBone = 57005,
            PropPlacement = {
                0.0700,
                0.5500,
                0.1000,
                -76.6157,
                -9.5838,
                2.9748,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["basket"] = {
        "missfbi4prepp1",
        "idle",
        "Basket",
        AnimationOptions = {
            Prop = 'bzzz_prop_shop_basket_a',
            PropBone = 57005,
            PropPlacement = {
                0.34,
                -0.25,
                -0.24,
                -146.0,
                115.0,
                19.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["basket2"] = {
        "missfbi4prepp1",
        "idle",
        "Basket 2",
        AnimationOptions = {
            Prop = 'bzzz_prop_shop_basket_b',
            PropBone = 57005,
            PropPlacement = {
                0.34,
                -0.25,
                -0.24,
                -146.0,
                115.0,
                19.0,
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["power"] = {
        "move_weapon@jerrycan@generic",
        "idle",
        "Centrale électrique",
        AnimationOptions = {
            Prop = 'prop_bzzz_elektro_powerhouse001',
            PropBone = 57005,
            PropPlacement = {
                0.11,
                0.06,
                0.0,
                98.0,
                12.0,
                -99.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["wlight"] = {
        "missfbi4prepp1",
        "idle",
        "Lumière Weed",
        AnimationOptions = {
            Prop = 'prop_bzzz_drugs_light001',
            PropBone = 57005,
            PropPlacement = {
                0.08,
                0.18,
                -0.02,
                -130.0,
                0.0,
                -90.0
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["businessbag"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@dark_appearance_with_bag_male",
        "mrwitt",
        "Sac Business",
        AnimationOptions = {
            Prop = 'prop_med_bag_01b',
            PropBone = 60309,
            PropPlacement = {
                0.3050,
                0.0200,
                0.0790,
                43.8282,
                -54.1834,
                -88.4424
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["businessbag2"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@dark_appearance_with_bag_male",
        "mrwitt",
        "Sac Business - Pose",
        AnimationOptions = {
            Prop = 'prop_med_bag_01b',
            PropBone = 60309,
            PropPlacement = {
                0.3050,
                0.0200,
                0.0790,
                43.8282,
                -54.1834,
                -88.4424
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["squatcash"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@checked_shirt_squat_male",
        "mrwitt",
        "Squat Cash - Pose",
        AnimationOptions = {
            Prop = 'prop_cash_pile_02',
            PropBone = 28422,
            PropPlacement = {
                0.0880,
                0.0440,
                0.0030,
                149.6422,
                -164.7312,
                25.2203
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["squatmask"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@selfie02_male",
        "mrwitt",
        "Squat Masque Rouge - Pose",
        AnimationOptions = {
            Prop = 'scarymask1',
            PropBone = 64065,
            PropPlacement = {
                0.0200,
                0.1700,
                -0.0210,
                0.0000,
                0.0000,
                0.0000,
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["squatmask1"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@selfie02_male",
        "mrwitt",
        "Squat Masque Blanc - Pose",
        AnimationOptions = {
            Prop = 'scarymask2',
            PropBone = 64065,
            PropPlacement = {
                0.0200,
                0.1700,
                -0.0210,
                0.0000,
                0.0000,
                0.0000,
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["squatmask2"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@selfie02_male",
        "mrwitt",
        "Squat Masque Noir - Pose",
        AnimationOptions = {
            Prop = 'scarymask3',
            PropBone = 64065,
            PropPlacement = {
                0.0200,
                0.1700,
                -0.0210,
                0.0000,
                0.0000,
                0.0000,
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["selfiesquat"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Mr Witt
        "mrwitt@selfie02_male",
        "mrwitt",
        "Selfie Squat Homme",
        AnimationOptions = {
            Prop = 'prop_cash_pile_02',
            PropBone = 26614,
            PropPlacement = {
                0.0300,
                -0.0300,
                0.0700,
                -90.0000,
                -180.0000,
                6.9999
            },
            SecondProp = 'prop_phone_ing',
            PropTextureVariations = {
                { Name = "<font color=\"#00A0F4\">Blue", Value = 0 },
                { Name = "<font color=\"#1AA20E\">Green", Value = 1 },
                { Name = "<font color=\"#800B0B\">Dark Red", Value = 2 },
                { Name = "<font color=\"#FF7B00\">Orange", Value = 3 },
                { Name = "<font color=\"#5F5F5F\">Grey", Value = 4 },
                { Name = "<font color=\"#a356fa\">Purple", Value = 5 },
                { Name = "<font color=\"#FF0099\">Pink", Value = 6 },
                { Name = "Black", Value = 7 },
            },
            SecondPropBone = 64112,
            SecondPropPlacement = {
                0.0180,
                0.0380,
                0.0260,
                179.6474,
                -177.9691,
                9.9938
            },
            PtfxAsset = "scr_tn_meet",
            PtfxName = "scr_tn_meet_phone_camera_flash",
            PtfxPlacement = {
                -0.015,
                0.0,
                0.041,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('camera'),
            PtfxWait = 200,
            EmoteLoop = true,
        }
    },
    ["femscaremask"] = { -- Animation by MrWitt
        "mrwitt@helloween4_f",
        "mrwitt",
        "Femme Masque Horreur - Pose",
        AnimationOptions = {
            Prop = 'scarymask1', -- Prop by Vedere
            PropBone = 64064,
            PropPlacement = {
                -0.0460,
                0.1170,
                0.0850,
                21.9542799,
                -81.9467213,
                9.0687101
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["femscaremask2"] = { -- Animation by MrWitt
        "mrwitt@helloween4_f",
        "mrwitt",
        "Femme Masque Horreur Noir - Pose",
        AnimationOptions = {
            Prop = 'scarymask2', -- Prop by Vedere
            PropBone = 64064,
            PropPlacement = {
                -0.0460,
                0.1170,
                0.0850,
                21.9542799,
                -81.9467213,
                9.0687101
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["femscaremask3"] = { -- Animation by MrWitt
        "mrwitt@helloween4_f",
        "mrwitt",
        "Femme Masque Horreur Blanc - Pose",
        AnimationOptions = {
            Prop = 'scarymask3', -- Prop by Vedere
            PropBone = 64064,
            PropPlacement = {
                -0.0460,
                0.1170,
                0.0850,
                21.9542799,
                -81.9467213,
                9.0687101
            },
            EmoteLoop = true,
            EmoteMoving = true
        },
    },
    ["raiseglass"] = { -- Custom Animation by Chocoholic Animations
        "chocoholic@duo32",
        "duo32_clip",
        "Lever son verre",
        AnimationOptions = {
            Prop = 'p_champ_flute_s',
            PropBone = 64065,
            PropPlacement = {
                0.0140,
                0.0310,
                -0.0990,
                0.0000,
                0.0000,
                0.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        },
    },
    ["raiseglass2"] = { -- Custom Animation by Chocoholic Animations
        "chocoholic@duo34",
        "duo34_clip",
        "Lever son verre 2",
        AnimationOptions = {
            Prop = 'p_champ_flute_s',
            PropBone = 64065,
            PropPlacement = {
                0.0260,
                0.0190,
                -0.1280,
                -14.9999,
                0.0000,
                -2.9999
            },
            EmoteLoop = true,
            EmoteMoving = true
        },
    },
    ["squatgunpose2"] = { -- Custom Emote By Darks Animations
        "ganggirls_pose2@darks37",
        "ganggirls_pose2_clip",
        "Squat Pistolet Pose 2 - Droit",
        AnimationOptions = {
            Prop = 'w_pi_pistolsmg_m31',
            PropBone = 26614,
            PropPlacement = {
                0.0260,
                -0.0280,
                0.0980,
                -4.8222,
                -6.9836,
                23.6186
            },
            EmoteLoop = true,
        },
    },
    ["rap2"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "mic_pose_1@darksj",
        "mic_pose_1_clip",
        "Rap / Chant 2 - Microphone",
        AnimationOptions = {
            Prop = 'sf_prop_sf_mic_01a',
            PropBone = 28422,
            PropPlacement = {
                0.0680,
                0.0190,
                -0.0220,
                0.0000,
                0.0000,
                170.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["rap3"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "mic_pose_2@darksj",
        "mic_pose_2_clip",
        "Rap / Chant 3 - Microphone Signe Rock ",
        AnimationOptions = {
            Prop = 'sf_prop_sf_mic_01a',
            PropBone = 28422,
            PropPlacement = {
                0.0680,
                0.0190,
                -0.0220,
                0.0000,
                0.0000,
                170.0000
            },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["rap4"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "mic_pose_3@darksj",
        "mic_pose_3_clip",
        "Rap / Chant 4 - Porter Microphone à Pied",
        AnimationOptions = {
            Prop = 'sf_prop_sf_mic_01a',
            PropBone = 28422,
            PropPlacement = {
                0.0680,
                0.0190,
                -0.0220,
                0.0000,
                0.0000,
                170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["rap5"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "mic_pose_4@darksj",
        "mic_pose_4_clip",
        "Rap / Chant 5 - Microphone à Genoux",
        AnimationOptions = {
            Prop = 'sf_prop_sf_mic_01a',
            PropBone = 28422,
            PropPlacement = {
                0.0680,
                0.0190,
                -0.0220,
                0.0000,
                0.0000,
                170.0000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["rap6"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "mic_pose_5_a@darksj",
        "mic_pose_5_a_clip",
        "Rap / Chant 6 - Microphone",
        AnimationOptions = {
            Prop = 'sf_prop_sf_mic_01a',
            PropBone = 28422,
            PropPlacement = {
                0.0680,
                0.0190,
                -0.0220,
                0.0000,
                0.0000,
                170.0000
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["bbat"] = { -- Custom Emote Provided To RPEmotes Courtesy Of Darks Animations
        "bat@sel",
        "bat_clip",
        "Pose Batte Baseball ",
        AnimationOptions = {
            Prop = 'p_cs_bbbat_01',
            PropBone = 28422,
            PropPlacement = {
                0.0600,
                0.0700,
                0.0100,
                -73.8317,
                0.8479,
                -12.8826
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["stopsign"] = { -- Custom Prop By PNWParksFan
        "amb@world_human_janitor@male@base",
        "base",
        "Panneau Stop ",
        AnimationOptions = {
            Prop = 'prop_flagger_sign_01',
            PropBone = 28422,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.6800,
                0.0000,
                0.0000,
                -50.0000
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["stopsign2"] = { -- Custom Prop By PNWParksFan
        "amb@world_human_janitor@male@base",
        "base",
        "Panneau Stop 2 - Doucement",
        AnimationOptions = {
            Prop = 'prop_flagger_sign_01',
            PropBone = 28422,
            PropPlacement = {
                0.0000,
                0.0000,
                -0.6800,
                0.0000,
                0.0000,
                120.0000
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["stopsign3"] = { -- Custom Prop By PNWParksFan
        "special_ped@griff@base",
        "base",
        "Panneau Stop 3 - Stop",
        AnimationOptions = {
            Prop = 'prop_flagger_sign_02',
            PropBone = 28422,
            PropPlacement = {
                0.0200,
                0.0200,
                -0.2600,
                169.9999,
                -180.0000,
                59.9999
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["stopsign4"] = { -- Custom Prop By PNWParksFan
        "special_ped@griff@base",
        "base",
        "Panneau Stop 4 - Doucement",
        AnimationOptions = {
            Prop = 'prop_flagger_sign_02',
            PropBone = 28422,
            PropPlacement = {
                0.0200,
                0.0200,
                -0.2600,
                10.0000,
                0.0000,
                -59.9999
            },
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["stonerbabepose"] = { -- Custom Emote provided by 41anims
        "stonerbabe@animation",
        "stonerbabe_clip",
        "Fumer un joint",
        AnimationOptions = {
            Prop = 'p_cs_joint_01',
            PropBone = 57005,
            PropPlacement = {
                0.15,
                0.03,
                -0.04,
                -1.0,
                170.0,
                0.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["baddiegyat"] = { -- Custom Emote provided by 41anims
        "baddiegyat",
        "baddiegyat_clip",
        "Baddie Gyat Selfie",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropTextureVariations = {
                {Name = "<font color=\"#00A0F4\">Blue", Value = 0},
                {Name = "<font color=\"#1AA20E\">Green", Value = 1},
                {Name = "<font color=\"#800B0B\">Dark Red", Value = 2},
                {Name = "<font color=\"#FF7B00\">Orange", Value = 3},
                {Name = "<font color=\"#5F5F5F\">Grey", Value = 4},
                {Name = "<font color=\"#a356fa\">Purple", Value = 5},
                {Name = "<font color=\"#FF0099\">Pink", Value = 6},
                {Name = "Black", Value = 7}
            },
            PropBone = 4169,
            PropPlacement = {
                0.0300,
                -0.0200,
                0.0200,
                -5.0,
                3.367247,
                0.0711684
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["murder1"] = {
        "dead",
        "dead_e",
        "Hache Meurtier",
        AnimationOptions = {
            Prop = "bzzz_murder_axe001",
            PropBone = 18905,
            PropPlacement = {
                -0.22,
                0.34,
                -0.3,
                -56.0,
                98.0,
                34.0
            },
            SecondProp = 'p_bloodsplat_s',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                0.28,
                0.17,
                -0.12,
                -98.0,
                -51.0,
                237.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["murder2"] = {
        "dead",
        "dead_a",
        "Meurtier Pistolet",
        AnimationOptions = {
            Prop = "w_pi_heavypistol",
            PropBone = 18905,
            PropPlacement = {
                0.27,
                0.35,
                0.05,
                -98.0,
                2.0,
                183.0
            },
            SecondProp = 'p_bloodsplat_s',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                -0.8,
                0.41,
                0.0,
                -98.0,
                -7.0,
                237.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["murder3"] = {
        "dead",
        "dead_b",
        "Meurtier Machette",
        AnimationOptions = {
            Prop = "bzzz_murder_machete001",
            PropBone = 18905,
            PropPlacement = {
                -0.22,
                0.18,
                -0.67,
                196.0,
                157.0,
                -35.0
            },
            SecondProp = 'p_bloodsplat_s',
            SecondPropBone = 57005,
            SecondPropPlacement = {
                -0.28,
                -0.15,
                0.00,
                266.2,
                182.3,
                -10.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
}

RP.GestesEmotes = {
    label = "Gestes",
    icon = "👐",
    ["checkwatch"] = { -- Custom Emote By MissSnowie
        "watch@looking_at",
        "base",
        "Regarder sa montre",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    --[[     ["scratch"] = {
            "move_p_m_two_idles@generic",
            "fidget_scratch_balls",
            "Scratch Balls",
            AnimationOptions = {EmoteMoving = false, EmoteDuration = 4000},
            AdultAnimation = true
        }, ]]
    ["cleanhands"] = {
        "missheist_agency3aig_23",
        "urinal_sink_loop",
        "Se nettoyer les mains",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["cleanface"] = {
        "switch@michael@wash_face",
        "loop_michael",
        "Se nettoyer le visage",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["block"] = {
        "missheist_agency3ashield_face",
        "idle",
        "Proteger son visage",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },

    ["snot"] = {
        "move_p_m_two_idles@generic",
        "fidget_blow_snot",
        "S'essuyer les yeux",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 4500}
    },
    ["respect"] = {
        "anim@mp_player_intcelebrationmale@respect",
        "respect",
        "Respect - Homme",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = false}
    },
    ["respectf"] = {
        "anim@mp_player_intcelebrationfemale@respect",
        "respect",
        "Respect - Femme",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = false}
    },
    ["bang"] = {
        "anim@mp_player_intcelebrationfemale@bang_bang",
        "bang_bang",
        "Bang Bang ",
        AnimationOptions = {EmoteMoving = false, EmoteDuration = 2500}
    },
    ["adjusttie"] = {
        "clothingtie",
        "try_tie_positive_a",
        "Se ré-habiller correctement",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 5000}
    },
    ["adjust"] = {
        "missmic4",
        "michael_tux_fidget",
        "Ajuster sa chemise",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 4000}
    },
    ["airforce01"] = { -- MissSnowie
        "airforce@at_ease",
        "base",
        "Airforce - Au repos", -- MissSnowie
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["airforce02"] = { -- MissSnowie
        "airforce@attention",
        "base",
        "Airforce - Attention",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["airforce03"] = { -- MissSnowie
        "airforce@parade_rest",
        "base",
        "Airforce - Au repos (parade)",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["airforce04"] = {
        "airforce@salute",
        "base",
        "Airforce - Saluer",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["argue"] = {
        "misscarsteal4@actor",
        "actor_berating_loop",
        "Disputer",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["argue2"] = {
        "oddjobs@assassinate@vice@hooker",
        "argue_a",
        "Toi là ! Je vais t'éclater !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["argue3"] = {
        "missheistdockssetup1leadinoutig_1",
        "lsdh_ig_1_argue_wade",
        "Disputer 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["argue4"] = {
        "car_2_mcs_1-6",
        "cs_devin_dual-6",
        "Disputer 4",
        AnimationOptions = {EmoteDuration = 6000, EmoteMoving = true}
    },
    ["argue5"] = {
        "anim@amb@casino@brawl@fights@argue@",
        "arguement_loop_mp_m_brawler_01",
        "Disputer 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["argue6"] = {
        "anim@amb@casino@brawl@fights@argue@",
        "arguement_loop_mp_m_brawler_02",
        "Disputer 6",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["bartender"] = {
        "anim@amb@clubhouse@bar@drink@idle_a",
        "idle_a_bartender",
        "Mains sur le comptoir",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["blowkiss"] = {
        "anim@mp_player_intcelebrationfemale@blow_kiss", "blow_kiss",
        "Plein de bisous"
    },
    ["blowkiss2"] = {
        "anim@mp_player_intselfieblow_kiss",
        "exit",
        "Plein de bisous 2",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 2000}
    },
    ["boi"] = {
        "special_ped@jane@monologue_5@monologue_5c",
        "brotheradrianhasshown_2",
        "Gars",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3000}
    },
    ["comeatmebro"] = {
        "mini@triathlon",
        "want_some_of_this",
        "C'est mon frère sa !",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 2000}
    },
    ["countdown"] = {
        "random@street_race",
        "grid_girl_race_start",
        "Applaudissement",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["cutthroat"] = {
        "anim@mp_player_intcelebrationmale@cut_throat", "cut_throat",
        "Toi là ! Je vais te crever !"
    },
    ["cutthroat2"] = {
        "anim@mp_player_intcelebrationfemale@cut_throat", "cut_throat",
        "Je vais te trancher la gorge"
    },
    ["damn"] = {
        "gestures@m@standing@casual",
        "gesture_damn",
        "Ah merde !",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1000}
    },
    ["damn2"] = {
        "anim@am_hold_up@male",
        "shoplift_mid",
        "Put*** !",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1000}
    },
    ["dock"] = {
        "anim@mp_player_intincardockstd@rds@",
        "idle_a",
        "Dock",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["facepalm2"] = {
        "anim@mp_player_intcelebrationfemale@face_palm",
        "face_palm",
        "Hein ? Pas possible..",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 8000}
    },
    ["facepalm"] = {
        "random@car_thief@agitated@idle_a",
        "agitated_idle_a",
        "Oh lala..",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 8000}
    },
    ["facepalm3"] = {
        "missminuteman_1ig_2",
        "tasered_2",
        "Quel malheur..",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 8000}
    },
    ["facepalm4"] = {
        "anim@mp_player_intupperface_palm",
        "idle_a",
        "Quel malheur..",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["finger"] = {
        "anim@mp_player_intselfiethe_bird",
        "idle_a",
        "Faire un fuck",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["finger2"] = {
        "anim@mp_player_intupperfinger",
        "idle_a_fp",
        "Faire un fuck 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["handshake"] = {
        "mp_ped_interaction",
        "handshake_guy_a",
        "Poignée de main",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3000}
    },
    ["handshake2"] = {
        "mp_ped_interaction",
        "handshake_guy_b",
        "Poignée de main 2",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3000}
    },
    ["handsup"] = {
        "missminuteman_1ig_2",
        "handsup_base",
        "Lever les mains en l'air",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["handsup2"] = {
        "anim@mp_player_intuppersurrender",
        "idle_a_fp",
        "Lever les mains en l'air 2",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    -- ['handsup3'] = {
    --     'anim@mp_rollarcoaster',
    --     'hands_up_idle_a_player_one',
    --     "Lever les mains en l'air 3",
    --     AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    -- },
    ["hugme"] = {"mp_ped_interaction", "kisses_guy_a", "Câlin"},
    ["hugme2"] = {"mp_ped_interaction", "kisses_guy_b", "Câlin 2"},
    ["jazzhands"] = {
        "anim@mp_player_intcelebrationfemale@jazz_hands",
        "jazz_hands",
        "Clown (Pitre)",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 6000}
    },
    ["knock"] = {
        "timetable@jimmy@doorknock@",
        "knockdoor_idle",
        "Toquer à une porte",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["knock2"] = {
        "missheistfbi3b_ig7",
        "lift_fibagent_loop",
        "Toquer à une porte 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["knucklecrunch"] = {
        "anim@mp_player_intcelebrationfemale@knuckle_crunch",
        "knuckle_crunch",
        "Se craquer les doigts",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["lift"] = {
        "random@hitch_lift",
        "idle_f",
        "Faire du stop",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["me"] = {
        "gestures@f@standing@casual",
        "gesture_me_hard",
        "Moi ?",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1000}
    },
    ["mindblown"] = {
        "anim@mp_player_intcelebrationmale@mind_blown",
        "mind_blown",
        "Ravi de te voir !",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 4000}
    },
    ["mindblown2"] = {
        "anim@mp_player_intcelebrationfemale@mind_blown",
        "mind_blown",
        "Damn",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 4000}
    },
    ["metal"] = {
        "anim@mp_player_intincarrockstd@ps@",
        "idle_a",
        "Signe métal",
        AnimationOptions = {
            -- CHANGE ME
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["no"] = {
        "anim@heists@ornate_bank@chat_manager",
        "fail",
        "Non pas du tout !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["no2"] = {
        "mp_player_int_upper_nod",
        "mp_player_int_nod_no",
        "Non de la tête",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["nosepick"] = {
        "anim@mp_player_intcelebrationfemale@nose_pick",
        "nose_pick",
        "Se décrotter le nez",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["noway"] = {
        "gestures@m@standing@casual",
        "gesture_no_way",
        "Absolument pas",
        AnimationOptions = {EmoteDuration = 1500, EmoteMoving = true}
    },
    ["ok"] = {
        "anim@mp_player_intselfiedock",
        "idle_a",
        "OK",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["pointdown"] = {
        "gestures@f@standing@casual",
        "gesture_hand_down",
        "Tu restes ici",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1000}
    },
    ["point"] = {
        "gestures@f@standing@casual",
        "gesture_point",
        "Hé toi là !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["pointright"] = {
        "mp_gun_shop_tut",
        "indicate_right",
        "Pointe vers la droite",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["pullover"] = {
        "misscarsteal3pullover",
        "pull_over_right",
        "Hé toi !",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1300}
    },
    ["peace"] = {
        "mp_player_int_upperpeace_sign",
        "mp_player_int_peace_sign",
        "Peace",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peace2"] = {
        "anim@mp_player_intupperpeace",
        "idle_a",
        "Peace 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peace3"] = {
        "anim@mp_player_intupperpeace",
        "idle_a_fp",
        "Peace 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peace4"] = {
        "anim@mp_player_intincarpeacestd@ds@",
        "idle_a",
        "Peace 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peace5"] = {
        "anim@mp_player_intincarpeacestd@ds@",
        "idle_a_fp",
        "Peace 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peace6"] = {
        "anim@mp_player_intincarpeacebodhi@ds@",
        "idle_a",
        "Peace 6",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peace7"] = {
        "anim@mp_player_intincarpeacebodhi@ds@",
        "idle_a_fp",
        "Peace 7",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["peacef"] = {
        "anim@mp_player_intcelebrationfemale@peace",
        "peace",
        "Peace - Femme",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["clapangry"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "angry_clap_a_player_a",
        "Applaudir comme un débile",
        AnimationOptions = {EmoteLoop = true}
    },
    ["slowclap3"] = {
        "anim@mp_player_intupperslow_clap",
        "idle_a",
        "Applaudir au ralenti",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["clap"] = {
        "amb@world_human_cheering@male_a",
        "base",
        "Applaudir joyeusement",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["slowclap"] = {
        "anim@mp_player_intcelebrationfemale@slow_clap",
        "slow_clap",
        "Applaudir doucement",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["slowclap2"] = {
        "anim@mp_player_intcelebrationmale@slow_clap",
        "slow_clap",
        "Applaudir doucement 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["smell"] = {
        "move_p_m_two_idles@generic",
        "fidget_sniff_fingers",
        "Se sentir la main",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["stickup"] = {
        "random@countryside_gang_fight",
        "biker_02_stickup_loop",
        "Pointer avec son arme",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think4"] = {
        "anim@amb@casino@hangout@ped_male@stand@02b@idles",
        "idle_a",
        "Croiser les bras en ce tenant le menton",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["salute"] = {
        "anim@mp_player_intincarsalutestd@ds@",
        "idle_a",
        "Salut de l'armée",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["salute2"] = {
        "anim@mp_player_intincarsalutestd@ps@",
        "idle_a",
        "Salut de l'armée 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["salute3"] = {
        "anim@mp_player_intuppersalute",
        "idle_a",
        "Salut de l'armée 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["screwyou"] = {
        "misscommon@response",
        "screw_you",
        "Bras d'honneur",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["shakeoff"] = {
        "move_m@_idles@shake_off",
        "shakeoff_1",
        "Enlever la poussière au sol",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3500}
    },
    ["shaka"] = {
        "sign@hang_loose",
        "base",
        "Shaka 'Hang Loose'",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["shaka2"] = {
        "sign@hang_loose_casual",
        "base",
        "Shaka 'Hang Loose Casual'",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["shrug"] = {
        "gestures@f@standing@casual",
        "gesture_shrug_hard",
        "Hein ?",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1000}
    },
    ["shrug2"] = {
        "gestures@m@standing@casual",
        "gesture_shrug_hard",
        "Quoi ?",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1000}
    },
    ["stink"] = {
        "anim@mp_player_intcelebrationfemale@stinker",
        "stinker",
        "Sa pue",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["uwu"] = {
        "uwu@egirl",
        "base",
        "UwU",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["thumbsup3"] = {
        "anim@mp_player_intincarthumbs_uplow@ds@",
        "enter",
        "Pouce en l'air",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3000}
    },
    ["thumbsup2"] = {
        "anim@mp_player_intselfiethumbs_up",
        "idle_a",
        "Pouce en l'air en souriant",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["thumbsup"] = {
        "anim@mp_player_intupperthumbs_up",
        "idle_a",
        "Double pouce en l'air",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave4"] = {
        "random@mugging5",
        "001445_01_gangintimidation_1_female_idle_b",
        "Salut avec les bras en l'air",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3000}
    },
    ["wave2"] = {
        "anim@mp_player_intcelebrationfemale@wave",
        "wave",
        "Salut de reine",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave3"] = {
        "friends@fra@ig_1",
        "over_here_idle_a",
        "Lever un bras comme une star",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave"] = {
        "friends@frj@ig_1",
        "wave_a",
        "Coucou !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave5"] = {
        "friends@frj@ig_1",
        "wave_b",
        "Hé c'est moi !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave6"] = {
        "friends@frj@ig_1",
        "wave_c",
        "Je suis là",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave7"] = {
        "friends@frj@ig_1",
        "wave_d",
        "Hé oh",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave8"] = {
        "friends@frj@ig_1",
        "wave_e",
        "Salut !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wave9"] = {
        "gestures@m@standing@casual",
        "gesture_hello",
        "Hey !",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["whistle"] = {
        "taxi_hail",
        "hail_taxi",
        "Sifflé",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 1300}
    },
    ["whistle2"] = {
        "rcmnigel1c",
        "hailing_whistle_waive_a",
        "Sifflé 2",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 2000}
    },
    ["yeah"] = {
        "anim@mp_player_intupperair_shagging",
        "idle_a",
        "Yeah",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["flipoff"] = {
        "anim@arena@celeb@podium@no_prop@",
        "flip_off_a_1st",
        "Faire un fuck à l'horizon",
        AnimationOptions = {EmoteMoving = true}
    },
    ["flipoff2"] = {
        "anim@arena@celeb@podium@no_prop@",
        "flip_off_c_1st",
        "Faire un double fuck à l'horizon",
        AnimationOptions = {EmoteMoving = true}
    },
    ["keyfob"] = {
        "anim@mp_player_intmenu@key_fob@",
        "fob_click",
        "Utiliser une clée",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = true,
            EmoteDuration = 1000
        }
    },
    ["holster"] = {
        "move_m@intimidation@cop@unarmed",
        "idle",
        "Holster",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["holster2"] = { --- Custom Emote Provided To RpEmotes By Mads
                     "mads@police_reaching_holster",
                     "idle",
                     "Holster 2",
                     AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["holster3"] = {
        "anim@hlstr_7360_walk",
        "holster_walk",
        "Holster 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["holster4"] = {
        "anim@hlstr_7360_hold",
        "holster_stop",
        "Holster 4 - Stop",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["holster5"] = {
        "anim@holster_hold_there",
        "holster_hold",
        "Holster 5 - Stop 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["slap"] = {
        "melee@unarmed@streamed_variations",
        "plyr_takedown_front_slap",
        "Giffler",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            EmoteDuration = 2000
        }
    },
    --[[     ["hump"] = {
            "timetable@trevor@skull_loving_bear",
            "skull_loving_bear",
            "Hump",
            AnimationOptions = {EmoteMoving = false, EmoteLoop = true},
            AdultAnimation = true
        },
        ["wank"] = {
            "anim@mp_player_intselfiewank",
            "idle_a",
            "Wank",
            AnimationOptions = {EmoteMoving = true, EmoteLoop = true},
            AdultAnimation = true
        },
        ["wank2"] = {
            "anim@mp_player_intupperwank",
            "idle_a",
            "Wank 2",
            AnimationOptions = {EmoteMoving = true, EmoteLoop = true},
            AdultAnimation = true
        },
        ["wank3"] = {
            "mp_player_int_upperwank",
            "mp_player_int_wank_02",
            "Wank 3",
            AnimationOptions = {EmoteMoving = true, EmoteLoop = true},
            AdultAnimation = true
        },
        ["wank4"] = {
            "mp_player_int_upperwank",
            "mp_player_int_wank_02_fp",
            "Wank 4",
            AnimationOptions = {EmoteMoving = true, EmoteLoop = true},
            AdultAnimation = true
        },
        ["wank5"] = {
            "mp_player_intwank",
            "mp_player_int_wank",
            "Wank 5",
            AnimationOptions = {EmoteMoving = false, EmoteLoop = false},
            AdultAnimation = true
        }, ]]
    ["crosshands"] = {
        "anim@amb@carmeet@checkout_car@",
        "male_e_base",
        "Mains croisées",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["dab"] = {
        "stand_dab@dark",
        "stand_dab_clip",
        "Dab",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["offtable"] = {
        "anim@amb@board_room@diagram_blueprints@",
        "look_around_01_amy_skater_01",
        "Se lever Table",
        AnimationOptions = {
            EmoteDuration = 5700
        }
    },
    ["shakeitoffhuman"] = {
        "move_m@_idles@shake_off",
        "shakeoff_1",
        "Secouez la pluie",
        AnimationOptions = {
            EmoteDuration = 2899,
            StartDelay = 850,
            EmoteMoving = true
        }
    },
    ["hhands"] = {
        "misssnowie@hearthands",
        "base",
        "Faire un coeur avec ses mains",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think"] = {
        "misscarsteal4@aliens",
        "rehearsal_base_idle_director",
        "Réflechir",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think2"] = {
        "missheist_jewelleadinout",
        "jh_int_outro_loop_a",
        "Réflechir 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think3"] = {
        "timetable@tracy@ig_8@base",
        "base",
        "Réflechir 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think5"] = {
        "mp_cp_welcome_tutthink",
        "b_think",
        "Réflechir 5",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 2000}
    },
    ["bow"] = {
        "anim@arena@celeb@podium@no_prop@",
        "regal_c_1st",
        "Révérence",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["bow2"] = {
        "anim@arena@celeb@podium@no_prop@",
        "regal_a_1st",
        "Révérence 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    }
}

RP.PositionsEmotes = {
    label = "Positions",
    icon = "🧍",
    ["bumsleep"] = {
        "amb@world_human_bum_slumped@male@laying_on_left_side@idle_a",
        "idle_b",
        "Grosse Sieste",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["chill"] = {
        "switch@trevor@scares_tramp",
        "trev_scares_tramp_idle_tramp",
        "Allongé relax",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 200,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["cloudgaze"] = {
        "switch@trevor@annoys_sunbathers",
        "trev_annoys_sunbathers_loop_girl",
        "Allongé dos au sol",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["cloudgaze2"] = {
        "switch@trevor@annoys_sunbathers",
        "trev_annoys_sunbathers_loop_guy",
        "Allongé dos au sol détendu",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["crossarms"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
        "idle_a",
        "Croiser les bras",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["crossarms2"] = {
        "amb@world_human_hang_out_street@male_c@idle_a",
        "idle_b",
        "Croiser les bras 2",
        AnimationOptions = {EmoteMoving = true}
    },
    ["crossarms3"] = {
        "anim@heists@heist_corona@single_team",
        "single_team_loop_boss",
        "Croiser les bras 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["crossarms4"] = {
        "random@street_race",
        "_car_b_lookout",
        "Croiser les bras 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["crossarms5"] = {
        "anim@amb@nightclub@peds@",
        "rcmme_amanda1_stand_loop_cop",
        "Croiser les bras 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["crossarms6"] = {
        "random@shop_gunstore",
        "_idle",
        "Croiser les bras 6",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["elbow"] = {
        "anim@veh@lowrider@std@ds@arm@base",
        "sit_low_lowdoor",
        "Bras a la fenetre",
        AnimationOptions = {EmoteLoop = true}
    },
    ["elbow2"] = { -- Custom Emote By Chocoholic Animations
        "chocoholic@single47",
        "single47_clip",
        "Bras a la fenetre 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["foldarms2"] = {
        "anim@amb@nightclub@peds@",
        "rcmme_amanda1_stand_loop_cop",
        "Bras croisé 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["foldarms"] = {
        "anim@amb@business@bgen@bgen_no_work@",
        "stand_phone_phoneputdown_idle_nowork",
        "Bras croisé",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["crossarmsside"] = {
        "rcmnigel1a_band_groupies",
        "base_m2",
        "Croiser les bras avec la tête sur le côté",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["idledrunk"] = {
        "random@drunk_driver_1",
        "drunk_driver_stand_loop_dd1",
        "Bourré sur place",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idledrunk2"] = {
        "random@drunk_driver_1",
        "drunk_driver_stand_loop_dd2",
        "Bourré sur place 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idledrunk3"] = {
        "missarmenian2",
        "standing_idle_loop_drunk",
        "Bourré sur place 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["kneel2"] = {
        "rcmextreme3",
        "idle",
        "S'agenouiller 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["kneel3"] = {
        "amb@world_human_bum_wash@male@low@idle_a",
        "idle_a",
        "S'agenouiller 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["kneelthot"] = {
        "anim@model_kylie_insta",
        "kylie_insta_clip",
        "S'agenouiller 4 - Insta",
        AnimationOptions = {EmoteLoop = true}
    },
    ["lean2"] = {
        "amb@world_human_leaning@female@wall@back@hand_up@idle_a",
        "idle_a",
        "Poser sur le mur",
        AnimationOptions = {EmoteLoop = true}
    },
    ["lean3"] = {
        "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a",
        "idle_a",
        "Poser sur le mur détendu",
        AnimationOptions = {EmoteLoop = true}
    },
    ["lean4"] = {
        "amb@world_human_leaning@male@wall@back@foot_up@idle_a",
        "idle_a",
        "Poser sur le mur mains croisés",
        AnimationOptions = {EmoteLoop = true}
    },
    ["lean5"] = {
        "amb@world_human_leaning@male@wall@back@hands_together@idle_b",
        "idle_b",
        "S'appuyer 5",
        AnimationOptions = {EmoteLoop = true}
    },
    ["leanflirt"] = {
        "random@street_race",
        "_car_a_flirt_girl",
        "Tenir ses genoux",
        AnimationOptions = {EmoteLoop = true}
    },
    ["leanbar2"] = {
        "amb@prop_human_bum_shopping_cart@male@idle_a",
        "idle_c",
        "S'appuyer sur un bar 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["leanbar3"] = {
        "anim@amb@nightclub@lazlow@ig1_vip@",
        "clubvip_base_laz",
        "S'appuyer sur un bar 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["leanbar4"] = {
        "anim@heists@prison_heist",
        "ped_b_loop_a",
        "S'appuyer sur un bar 4",
        AnimationOptions = {EmoteLoop = true}
    },
    ["leanhigh"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_one",
        "Pousser un caddie",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["leanhigh2"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Pousser un caddie 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["leanside"] = {
        "timetable@mime@01_gc",
        "idle_a",
        "S'accrocher sur le côté",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["leanside2"] = {
        "misscarstealfinale",
        "packer_idle_1_trevor",
        "S'accrocher sur le côté 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["leanside3"] = {
        "misscarstealfinalecar_5_ig_1",
        "waitloop_lamar",
        "S'accrocher sur le côté 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["leanside4"] = {
        "misscarstealfinalecar_5_ig_1",
        "waitloop_lamar",
        "S'accrocher sur le côté 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    --["leanside5"] = {
    --    "rcmjosh2",
    --    "josh_2_intp1_base",
    --    "S'accrocher sur le côté 5",
    --    AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    --},
    ["prone"] = {
        "missfbi3_sniping",
        "prone_dave",
        "S'allonger à plat ventre",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["relax"] = {
        "lying@on_grass",
        "base",
        "Allonger de manière relax - 1",
        AnimationOptions = {
            EmoteLoop = true,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["relax2"] = {
        "lying@on_couch_legs_crossed",
        "base",
        "Allonger de manière relax - 2",
        AnimationOptions = {
            EmoteLoop = true,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sunbathe"] = {
        "amb@world_human_sunbathe@male@back@base",
        "base",
        "Bronzer sur le dos",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sunbathe2"] = {
        "amb@world_human_sunbathe@female@back@base",
        "base",
        "Bronzer sur le dos 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sexypose"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy003",
        "sexy003",
        "Pose Sexy",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["sexypose2"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy004",
        "sexy004",
        "Pose Sexy 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["sexypose3"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy005",
        "sexy005",
        "Pose Sexy 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["sexypose4"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy006",
        "sexy006",
        "Pose Sexy 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["sexypose5"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy009",
        "sexy009",
        "Pose Sexy 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["sexypose6"] = { -- Custom Emote By Little Spoon
        "littlespoon@sexy012",
        "sexy012",
        "Pose Sexy 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["surrender"] = {
        "random@arrests@busted",
        "idle_a",
        "Se rendre",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "surrender_exit",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender2"] = {
        "mp_bank_heist_1",
        "f_cower_02",
        "Se rendre 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender3"] = {
        "mp_bank_heist_1",
        "m_cower_01",
        "Se rendre 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender4"] = {
        "mp_bank_heist_1",
        "m_cower_02",
        "Se rendre 4",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender5"] = {
        "random@arrests",
        "kneeling_arrest_idle",
        "Se rendre 5",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "surrender_exit",
            ExitEmoteType = "Exits"
        }
    },
    ["surrender6"] = {
        "rcmbarry",
        "m_cower_01",
        "Se rendre 6",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sleep"] = {
        "timetable@tracy@sleep@",
        "idle_c",
        "Dormir",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit"] = {
        "anim@amb@business@bgen@bgen_no_work@",
        "sit_phone_phoneputdown_idle_nowork",
        "S'asseoir",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit2"] = {
        "rcm_barry3",
        "barry_3_sit_loop",
        "S'asseoir 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit3"] = {
        "amb@world_human_picnic@male@idle_a",
        "idle_a",
        "S'asseoir 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit4"] = {
        "amb@world_human_picnic@female@idle_a",
        "idle_a",
        "S'asseoir 4",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit5"] = {
        "anim@heists@fleeca_bank@ig_7_jetski_owner",
        "owner_idle",
        "S'asseoir 5",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit6"] = {
        "timetable@jimmy@mics3_ig_15@",
        "idle_a_jimmy",
        "S'asseoir 6",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit7"] = {
        "anim@amb@nightclub@lazlow@lo_alone@",
        "lowalone_base_laz",
        "S'asseoir 7",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit8"] = {
        "timetable@jimmy@mics3_ig_15@",
        "mics3_15_base_jimmy",
        "S'asseoir 8",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sit9"] = {
        "amb@world_human_stupor@male@idle_a",
        "idle_a",
        "S'asseoir 9",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitlean"] = {
        "timetable@tracy@ig_14@",
        "ig_14_base_tracy",
        "S'asseoir Timidement",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitsad"] = {
        "anim@amb@business@bgen@bgen_no_work@",
        "sit_phone_phoneputdown_sleeping-noworkfemale",
        "S'asseoir Tristement",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitscared"] = {
        "anim@heists@ornate_bank@hostages@hit",
        "hit_loop_ped_b",
        "S'asseoir effrayé",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitscared2"] = {
        "anim@heists@ornate_bank@hostages@ped_c@",
        "flinch_loop",
        "S'asseoir effrayé 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitscared3"] = {
        "anim@heists@ornate_bank@hostages@ped_e@",
        "flinch_loop",
        "S'asseoir effrayé 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sitdrunk"] = {
        "timetable@amanda@drunk@base",
        "base",
        "S'asseoir bourré",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    -- Sitchair is a litte special, since you want the player to be seated correctly.
    -- So we set it as "ScenarioObject" and do TaskStartScenarioAtPosition() instead of "AtPlace"
    ["sitchair"] = {
        "ScenarioObject", "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER",
        "S'asseoir sur une chaise"
    },
    ["sitchair2"] = {
        "timetable@ron@ig_5_p3",
        "ig_5_p3_base",
        "S'asseoir sur une chaise 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair3"] = {
        "timetable@reunited@ig_10",
        "base_amanda",
        "S'asseoir sur une chaise 3 (Femme)",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair4"] = {
        "timetable@ron@ig_3_couch",
        "base",
        "S'asseoir sur une chaise 4",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair5"] = {
        "timetable@jimmy@mics3_ig_15@",
        "mics3_15_base_tracy",
        "S'asseoir sur une chaise 5",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchair6"] = {
        "timetable@maid@couch@",
        "base",
        "S'asseoir sur une chaise 6",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitchairside"] = {
        "timetable@ron@ron_ig_2_alt1",
        "ig_2_alt1_base",
        "S'asseoir sur une chaise de côté",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["sitcute"] = { -- Custom Emote By QueenSistersAnimations
        "sitkylie@queensisters",
        "kylie_clip",
        "S'asseoir de manière cute",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            ExitEmote = "offchair",
            ExitEmoteType = "Exits"
        }
    },
    ["tpose"] = {
        "missfam5_yoga",
        "a2_pose",
        "T Pose",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["tpose2"] = {
        "mp_sleep",
        "bind_pose_180",
        "T Pose 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["think5"] = {
        "mp_cp_welcome_tutthink",
        "b_think",
        "Réflechir 5",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 2000}
    },
    ["think"] = {
        "misscarsteal4@aliens",
        "rehearsal_base_idle_director",
        "Réflechir",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think3"] = {
        "timetable@tracy@ig_8@base",
        "base",
        "Réflechir 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["think2"] = {
        "missheist_jewelleadinout",
        "jh_int_outro_loop_a",
        "Réflechir 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["laydownsexy"] = { -- Custom emote by Struggleville
        "anim@female_laying_sexy",
        "laying_sexy_clip",
        "Couché Sexy",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["model"] = { -- Custom emote by Struggleville
        "anim@female_model_showoff",
        "model_showoff_clip",
        "Modele Pose Sexy",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["model2"] = { -- Custom Emote By QueenSistersAnimations
        "sitdownonknees@queensisters",
        "sitdown_clip",
        "Modele Pose 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["model3"] = { -- Custom emote by Struggleville
        "anim@female_model_photo_cute",
        "photo_cute_clip",
        "Modele Pose 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["layncry"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_fuckedup_laz",
        "Coucher en pleurs",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry2"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_base_laz",
        "Coucher en pleurs 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry3"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_notagain_laz",
        "Coucher en pleurs 3",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry4"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_notagain_laz",
        "Coucher en pleurs 4",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry5"] = {
        "anim@amb@nightclub@lazlow@lo_sofa@",
        "lowsofa_dlg_shit2strong_laz",
        "Coucher en pleurs 5",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["layncry6"] = {
        "misschinese2_crystalmaze",
        "2int_loop_a_taocheng",
        "Coucher en pleurs 6",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["laysexy"] = { -- Custom Emote By Amnilka
        "amnilka@photopose@female@homepack001",
        "amnilka_femalehome_photopose_004",
        "Coucher Sexy",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["gungirl1"] = { -- Custom Emote By Struggleville
        "anim@female_gunbunny_rifle_photo",
        "rifle_photo_clip",
        "Pose avec arme (femme)",
        AnimationOptions = {EmoteLoop = true}
    },
    ["vest"] = {
        "anim@male@holding_vest",
        "holding_vest_clip",
        "Attendre en tenant son GPB",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["vest2"] = {
        "anim@holding_side_vest",
        "holding_side_vest_clip",
        "Attendre en tenant son GPB 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["vest3"] = {
        "anim@holding_siege_vest_side",
        "holding_siege_vest_side_clip",
        "Attendre en tenant son GPB 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["vest4"] = {
        "anim@male@holding_vest_2",
        "holding_vest_2_clip",
        "Attendre en tenant son GPB 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["vest5"] = {
        "anim@male@holding_vest_siege",
        "holding_vest_siege_clip",
        "Attendre en tenant son GPB 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["vest6"] = {
        "anim@male@holding_vest_siege_2",
        "holding_vest_siege_2_clip",
        "Attendre en tenant son GPB 6",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait"] = {
        "random@shop_tattoo",
        "_idle_a",
        "Attendre",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait2"] = {
        "missbigscore2aig_3",
        "wait_for_van_c",
        "Attendre 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait3"] = {
        "amb@world_human_hang_out_street@female_hold_arm@idle_a",
        "idle_a",
        "Attendre 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait4"] = {
        "amb@world_human_hang_out_street@Female_arm_side@idle_a",
        "idle_a",
        "Attendre 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait5"] = {
        "missclothing",
        "idle_storeclerk",
        "Attendre 5",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait6"] = {
        "timetable@amanda@ig_2",
        "ig_2_base_amanda",
        "Attendre 6",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait7"] = {
        "rcmnigel1cnmt_1c",
        "base",
        "Attendre 7",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait8"] = {
        "rcmjosh1",
        "idle",
        "Attendre 8",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    --["wait9"] = {
    --    "rcmjosh2",
    --    "josh_2_intp1_base",
    --    "Attendre 9",
    --    AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    --},
    ["wait10"] = {
        "timetable@amanda@ig_3",
        "ig_3_base_tracy",
        "Attendre 10",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait11"] = {
        "misshair_shop@hair_dressers",
        "keeper_base",
        "Attendre 11",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait12"] = {
        "rcmjosh1",
        "keeper_base",
        "Attendre 12",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["wait13"] = {
        "rcmnigel1a",
        "base",
        "Attendre 13",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["statue2"] = {
        "fra_0_int-1",
        "cs_lamardavis_dual-1",
        "Statue 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["statue3"] = {
        "club_intro2-0",
        "csb_englishdave_dual-0",
        "Statue 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["valet"] = {
        "anim@amb@casino@valet_scenario@pose_a@",
        "base_a_m_y_vinewood_01",
        "Valet",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["valet2"] = {
        "anim@amb@casino@valet_scenario@pose_b@",
        "base_a_m_y_vinewood_01",
        "Valet 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["valet3"] = {
        "anim@amb@casino@valet_scenario@pose_d@",
        "base_a_m_y_vinewood_01",
        "Valet 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    --[[     ["fspose"] = {
            "missfam5_yoga",
            "c2_pose",
            "Pose Sexy F",
            AnimationOptions = {EmoteMoving = false, EmoteLoop = true},
            AdultAnimation = true
        },
        ["fspose2"] = {
            "missfam5_yoga",
            "c6_pose",
            "Pose Sexy F 2",
            AnimationOptions = {EmoteMoving = false, EmoteLoop = true},
            AdultAnimation = true
        },
        ["fspose3"] = {
            "anim@amb@carmeet@checkout_car@",
            "female_c_idle_d",
            "Pose Sexy F 3",
            AnimationOptions = {EmoteMoving = false, EmoteLoop = true},
            AdultAnimation = true
        }, ]]
    ["showerf"] = {
        "mp_safehouseshower@female@",
        "shower_enter_into_idle",
        "Entrer Douche - Femme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["showerf2"] = {
        "mp_safehouseshower@female@",
        "shower_idle_a",
        "Douche - Femme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["showerf3"] = {
        "mp_safehouseshower@female@",
        "shower_idle_b",
        "Douche 2 - Femme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["showerm"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_a",
        "Entrer Douche - Homme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["showerm2"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_b",
        "Douche 2 - Homme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["showerm3"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_c",
        "Douche 3 - Homme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["showerm4"] = {
        "mp_safehouseshower@male@",
        "male_shower_idle_d",
        "Douche 4 - Homme",
        AnimationOptions = {EmoteMoving = false, EmoteLoop = true}
    },
    ["policecrowd"] = {
        "amb@code_human_police_crowd_control@idle_a",
        "idle_a",
        "Contrôle de la foule",
        AnimationOptions = {EmoteLoop = true}
    },
    ["policecrowd2"] = {
        "amb@code_human_police_crowd_control@idle_b",
        "idle_d",
        "Contrôle de la foule 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["k9pose"] = {
        "anim@k9_pose",
        "hug_dog",
        "Faire un câlin a son chien",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["sunbathe3"] = {
        "amb@world_human_sunbathe@female@front@base",
        "base",
        "Bronzer sur le ventre",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["sunbatheback"] = {
        "Scenario", "WORLD_HUMAN_SUNBATHE_BACK", "Prendre un bain de soleil"
    }
}

RP.AutresEmotes = {
    label = "Autres Emotes",
    icon = "✨",
    ["checkcar"] = {
        "anim@amb@carmeet@checkout_car@male_a@idles",
        "idle_b",
        "Regarder la voiture - Femme",
        AnimationOptions = {EmoteLoop = true}
    },
    ["checkcar2"] = {
        "anim@amb@carmeet@checkout_car@male_c@idles",
        "idle_a",
        "Regarder la voiture - Homme",
        AnimationOptions = {EmoteLoop = true}
    },
    ["showboobs"] = {
        "mini@strip_club@backroom@",
        "stripper_b_backroom_idle_b",
        "Montrer poitrine",
        AnimationOptions = {EmoteMoving = false, EmoteDuration = 6000},
    },
    ["showboobs2"] = {
        "mini@strip_club@idles@stripper",
        "stripper_idle_05",
        "Montrer poitrine 2",
        AnimationOptions = {EmoteMoving = false, EmoteDuration = 6000},
    },
    ["watchstripper"] = {
        "amb@world_human_strip_watch_stand@male_c@idle_a",
        "idle_b",
        "Regarder stripteaseuse",
        AnimationOptions = {EmoteMoving = false, EmoteDuration = 6000},
    },
    ["posecutef"] = { -- Custom Emote By Pupppy
        "pupppy@freepose01",
        "freepose01",
        "Pose Mignonne Femme",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["posecutef2"] = { -- Custom Emote By Pupppy
        "pupppy@freepose03",
        "freepose03",
        "Pose Mignonne Femme 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["posecutef3"] = { -- Custom Emote By Pupppy
        "pupppy@freepose04",
        "freepose04",
        "Pose Mignonne Femme 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["posecutef4"] = { -- Custom Emote By QueenSistersAnimations
        "handkylie@queensisters",
        "kylie_clip",
        "Pose Mignonne Femme 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["posecutem"] = { -- Custom Emote By Pupppy
        "pupppy@freepose02",
        "freepose02",
        "Pose Mignonne Homme",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = false}
    },
    ["cop2"] = {
        "anim@amb@nightclub@peds@",
        "rcmme_amanda1_stand_loop_cop",
        "Flic bras croisé",
        AnimationOptions = {EmoteLoop = true}
    },
    ["cop3"] = {
        "amb@code_human_police_investigate@idle_a",
        "idle_b",
        "Flic appel radio",
        AnimationOptions = {EmoteLoop = true}
    },
    ["maskup"] = {
        "anim@mp_helmets@on_foot",
        "visor_up",
        "Pompier Démasquer",
        AnimationOptions = {
            EmoteDuration = 800, -- Even with EmoteLoop = false, this emote still loops, so we add a duration to force it to stop after a set amount of milliseconds.
            EmoteMoving = true,
        }
    },
    ["maskdown"] = {
        "anim@mp_helmets@on_foot",
        "visor_down",
        "Pomier Mettre Masque",
        AnimationOptions = {
            EmoteDuration = 800, -- Even with EmoteLoop = false, this emote still loops, so we add a duration to force it to stop after a set amount of milliseconds.
            EmoteMoving = true,
        }
    },
    ["masktakeoff"] = {
        "anim@scripted@bty5@ig1_intimidate_actor@female_heeled@",
        "mask_action_b",
        "Retirer Masque",
        AnimationOptions = {
            EmoteMoving = true,
        }
    },
    ["adjustbag"] = {
        "amb@world_human_hiker_standing@male@idle_a",
        "idle_b",
        "Pompier Ajuster Sac",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteDuration = 9500
        }
    },
    ["adjustpanel"] = {
        "anim@scripted@heist@ig9_control_tower@male@",
        "loop",
        "Pompier Pompe PSI",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["puke"] = { -- Custom Emotes By Darks Animations Provided To RPEmotes 01/08/2023
        "cross_arms@dark",
        "cross_arms_clip",
        "Vomir",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            PtfxAsset = "scr_paletoscore",
            PtfxName = "scr_trev_puke",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('puke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        },
    },
    ["puke2"] = {
        "missheistpaletoscore1leadinout",
        "trv_puking_leadout",
        "Vomir 2",
        AnimationOptions = {
            EmoteLoop = false,
            EmoteMoving = true,
            PtfxAsset = "scr_paletoscore",
            PtfxName = "scr_trev_puke",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('puke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        },
    },
    ["puke3"] = {
        "anim@scripted@ulp_missions@injured_agent@",
        "idle",
        "Vomir 3",
        AnimationOptions = {
            EmoteLoop = true,
            PtfxAsset = "scr_paletoscore",
            PtfxName = "scr_trev_puke",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('puke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        },
    },
    ["puke4"] = {
        "anim@scripted@freemode@throw_up_toilet@male@",
        "idle",
        "Vomir 4",
        AnimationOptions = {
            EmoteLoop = true,
            PtfxAsset = "scr_paletoscore",
            PtfxName = "scr_trev_puke",
            PtfxNoProp = true,
            PtfxBone = 31086,
            PtfxPlacement = {
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0
            },
            PtfxInfo = ('puke'),
            PtfxWait = 0.8,
            PtfxCanHold = true
        },
    },
    ["dispenser"] = {
        "mini@sprunk",
        "plyr_buy_drink_pt1",
        "Distributeur",
        AnimationOptions = {EmoteLoop = false}
    },
    ["clipboard2"] = {"MaleScenario", "WORLD_HUMAN_CLIPBOARD", "Clipboard 2"},
    ["cop"] = {"Scenario", "WORLD_HUMAN_COP_IDLES", "Mains sur la ceinture"},
    ["guard"] = {"Scenario", "WORLD_HUMAN_GUARD_STAND", "Garde"},
    ["hangout"] = {
        "Scenario", "WORLD_HUMAN_HANG_OUT_STREET", "Ecouter une discussion"
    },
    ["leotest"] = {"anim@amb@business@cfid@cfid_desk_no_work_bgen_chair_no_work@", "transition_wakeup_lazyworker", "leotest"},
    ["leotest1"] = {"Scenario", "PROP_HUMAN_SEAT_BENCH", "leotest1"},
    ["leotest2"] = {"Scenario", "PROP_HUMAN_SEAT_DECKCHAIR", "leotest2"},
    ["leotest3"] = {"Scenario", "PROP_HUMAN_SEAT_STRIP_WATCH", "leotest3"},
    ["leotest4"] = {"Scenario", "PROP_HUMAN_SEAT_ARMCHAIR", "leotest4"},
    ["leotest5"] = {"Scenario", "PROP_HUMAN_SEAT_CHAIR", "leotest5"},
    ["leotest6"] = {"Scenario", "PROP_HUMAN_SEAT_CHAIR_UPRIGHT", "leotest6"},
    ["leotest7"] = {"Scenario", "WORLD_HUMAN_SEAT_LEDGE", "leotest7"},
    ["leotest8"] = {"Scenario", "WORLD_HUMAN_SEAT_LEDGE_EATING", "leotest8"},
    ["leotest9"] = {"Scenario", "WORLD_HUMAN_LEANING", "leotest9"},
    ["leotest10"] = {"Scenario", "PROP_HUMAN_SEAT_SUNLOUNGER", "leotest10"},
    ["leotest11"] = {"Scenario", "PROP_HUMAN_SEAT_BUS_STOP_WAIT", "leotest11"},
    ["leotest12"] = {"Scenario", "PROP_HUMAN_SEAT_BENCH_FOOD_FACILITY", "leotest12"},
    ["leotest13"] = {"Scenario", "PROP_HUMAN_SEAT_BAR", "leotest13"},


    ["janitor"] = {"Scenario", "WORLD_HUMAN_JANITOR", "Tenir un balai"},
    ["jog"] = {
        "Scenario", "WORLD_HUMAN_JOG_STANDING", "S'échauffer pour son jogging"
    },
    ["kneel"] = {"Scenario", "CODE_HUMAN_MEDIC_KNEEL", "Jetez un coup d'oeil"},
    ["lean"] = {
        "Scenario", "WORLD_HUMAN_LEANING", "Attendre posé contre un mur"
    },
    ["leanbar"] = {
        "Scenario", "PROP_HUMAN_BUM_SHOPPING_CART", "Attendre posé sur un bar"
    },
    ["lookout"] = {"Scenario", "CODE_HUMAN_CROSS_ROAD_WAIT", "Attention"},
    ["maid"] = {"Scenario", "WORLD_HUMAN_MAID_CLEAN", "Essuyer une vitre"},
    ["musician"] = {
        "MaleScenario", "WORLD_HUMAN_MUSICIAN", "Jouer un instrument musical"
    },
    -- Ambient Music Doesn't Seem To Work For Female, Hence It's Male Only
    ["notepad2"] = {
        "Scenario", "CODE_HUMAN_MEDIC_TIME_OF_DEATH", "Sortir son notepad"
    },
    ["parkingmeter"] = {
        "Scenario", "PROP_HUMAN_PARKING_METER", "Payer à la borne du parking"
    },
    ["party"] = {
        "Scenario", "WORLD_HUMAN_PARTYING", "Boire une bière en dansant"
    },
    ["texting"] = {"Scenario", "WORLD_HUMAN_STAND_MOBILE", "Envoyer un message"},
    ["prosthigh"] = {
        "Scenario", "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS", "Faire le trottoir 1"
    },
    ["prostlow"] = {
        "Scenario", "WORLD_HUMAN_PROSTITUTE_LOW_CLASS", "Faire le trottoir 2"
    },
    ["puddle"] = {
        "Scenario", "WORLD_HUMAN_BUM_WASH", "Se nettoyer avec de l'eau"
    },
    ["record"] = {
        "Scenario", "WORLD_HUMAN_MOBILE_FILM_SHOCKING", "Filmer une scène"
    },
    ["atm"] = {"Scenario", "PROP_HUMAN_ATM", "ATM"},
    ["bbq"] = {"MaleScenario", "PROP_HUMAN_BBQ", "BBQ"},
    ["bumbin"] = {"Scenario", "PROP_HUMAN_BUM_BIN", "Fouiller une poubelle"},
    ["pee"] = {
        "misscarsteal2peeing",
        "peeing_loop",
        "Pisser - Homme",
        AnimationOptions = {
            EmoteStuck = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {-0.05, 0.3, 0.0, 0.0, 90.0, 90.0, 1.0},
            PtfxInfo = Animations.Languages['pee'],
            PtfxWait = 3000,
            PtfxCanHold = true
        },
        AdultAnimation = false
    },
    ["pee2"] = {
        "missbigscore1switch_trevor_piss",
        "piss_loop",
        "Pisser 2 - Homme",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            PtfxAsset = "scr_amb_chop",
            PtfxName = "ent_anim_dog_peeing",
            PtfxNoProp = true,
            PtfxPlacement = {0.0130, 0.1030, 0.0, 0.0, 90.0, 90.0, 1.0},
            PtfxInfo = Animations.Languages['pee'],
            PtfxWait = 3000,
            PtfxCanHold = true
        },
        AdultAnimation = false
    },
    ["grieve"] = {
        "anim@miss@low@fin@vagos@",
        "idle_ped05",
        "Etre triste",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["buzz"] = {
        "anim@apt_trans@buzzer",
        "buzz_reg",
        "Sonner à la porte",
        AnimationOptions = {EmoteLoop = false, EmoteMoving = false}
    },
    ["beast"] = {
        "anim@mp_fm_event@intro",
        "beast_transform",
        "Fou",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 5000}
    },
    ["bringiton"] = {
        "misscommon@response",
        "bring_it_on",
        "Qu'est-ce qu'y a",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 3000}
    },
    ["celebrate"] = {
        "rcmfanatic1celebrate",
        "celebrate",
        "Célébrer",
        AnimationOptions = {EmoteLoop = true}
    },
    ["curtsy"] = {
        "anim@mp_player_intcelebrationpaired@f_f_sarcastic", "sarcastic_left",
        "Danseuse étoile"
    },
    ["airplane"] = {
        "missfbi1",
        "ledge_loop",
        "Se prendre pour un avion",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["nervous2"] = {
        "mp_missheist_countrybank@nervous",
        "nervous_idle",
        "Méfiant 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["nervous"] = {
        "amb@world_human_bum_standing@twitchy@idle_a",
        "idle_c",
        "Méfiant",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["nervous3"] = {
        "rcmme_tracey1",
        "nervous_loop",
        "Méfiant 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["zombiewalk"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "zombi_walk_01",
        "Marcher comme un zombie",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false -- true looks weird but the option is here
        }
    },
    ["zombiewalk2"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "zombi_walk_02",
        "Marcher comme un zombie 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["zombieagony"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "agony",
        "Agoniser comme un zombie",
        AnimationOptions = {EmoteLoop = true}
    },
    ["zombiescream"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "scream",
        "Crier comme un zombie",
        AnimationOptions = {EmoteLoop = true}
    },
    ["zombiecrawl"] = { -- Custom Emote By BoringNeptune
        "zombies_animations",
        "crawl_01",
        "Ramper comme un zombie",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "meditateup",
            ExitEmoteType = "Exits"
        }
    },
    ["peek"] = {
        "random@paparazzi@peek",
        "left_peek_a",
        "Espionner",
        AnimationOptions = {EmoteLoop = true}
    },
    ["push"] = {
        "missfinale_c2ig_11",
        "pushcar_offcliff_f",
        "Pousser",
        AnimationOptions = {EmoteLoop = true}
    },
    ["push2"] = {
        "missfinale_c2ig_11",
        "pushcar_offcliff_m",
        "Pousser 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["stumble"] = {
        "misscarsteal4@actor",
        "stumble",
        "Trébucher",
        AnimationOptions = {EmoteLoop = true}
    },
    ["stunned"] = {
        "stungun@standing",
        "damage",
        "Électrocuté",
        AnimationOptions = {EmoteLoop = true}
    },
    ["lol"] = {
        "anim@arena@celeb@flat@paired@no_props@",
        "laugh_a_player_b",
        "MDR",
        AnimationOptions = {EmoteLoop = true}
    },
    ["lol2"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "giggle_a_player_b",
        "MDR 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["fishdance"] = {
        "anim@mp_player_intupperfind_the_fish",
        "idle_a",
        "Danse du poisson",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["ledge"] = {
        "missfbi1",
        "ledge_loop",
        "Superman",
        AnimationOptions = {EmoteLoop = true}
    },
    ["superhero"] = {
        "rcmbarry",
        "base",
        "Super-héros",
        AnimationOptions = {EmoteLoop = true}
    },
    ["superhero2"] = {
        "rcmbarry",
        "base",
        "Super-héros 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["mindcontrol"] = {
        "rcmbarry",
        "mind_control_b_loop",
        "Contrôle de la pensée",
        AnimationOptions = {EmoteLoop = true}
    },
    ["mindcontrol2"] = {
        "rcmbarry",
        "bar_1_attack_idle_aln",
        "Contrôle de la pensée 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["clown"] = {
        "rcm_barry2",
        "clown_idle_0",
        "Clown (Pitre)",
        AnimationOptions = {EmoteLoop = true}
    },
    ["clown2"] = {
        "rcm_barry2",
        "clown_idle_1",
        "Clown (Pitre) 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["clown3"] = {
        "rcm_barry2",
        "clown_idle_2",
        "Clown (Pitre) 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["clown4"] = {
        "rcm_barry2",
        "clown_idle_3",
        "Clown (Pitre) 4",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    --[[ ["clown5"] = {
        "rcm_barry2",
        "clown_idle_6",
        "Clown (Pitre) 5",
        AnimationOptions = {EmoteLoop = true}
    }, ]]
    ["tryclothes"] = {
        "mp_clothing@female@trousers",
        "try_trousers_neutral_a",
        "Se regarder dans le miroir",
        AnimationOptions = {EmoteLoop = true}
    },
    ["tryclothes2"] = {
        "mp_clothing@female@shirt",
        "try_shirt_positive_a",
        "Se regarder dans le miroir 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["tryclothes3"] = {
        "mp_clothing@female@shoes",
        "try_shoes_positive_a",
        "Se regarder dans le miroir 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["uncuff"] = {
        "mp_arresting",
        "a_uncuff",
        "Démenotter",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["namaste"] = {
        "timetable@amanda@ig_4",
        "ig_4_base",
        "Namasté",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["threaten"] = {
        "random@atmrobberygen",
        "b_atm_mugging",
        "Pointé une arme comme un gangster",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["radio"] = {
        "random@arrests",
        "generic_radio_chatter",
        "Talkie-walkie",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["pull"] = {
        "random@mugging4",
        "struggle_loop_b_thief",
        "Tirer le maillot de quelqu'un",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["spiderman"] = {
        "missexile3",
        "ex03_train_roof_idle",
        "Homme-Araignée",
        AnimationOptions = {EmoteLoop = true, NotInVehicle = true}
    },
    --[[ ["smoke"] = {"Scenario", "WORLD_HUMAN_SMOKING", "Fumer une cigarette"},
    ["smokeweed"] = {
        "MaleScenario", "WORLD_HUMAN_DRUG_DEALER", "Fumer un joint (Homme)"
    },
    -- Male
    ["smokepot"] = {
        "Scenario", "WORLD_HUMAN_SMOKING_POT", "Fumer un joint (Femme)"
    }, ]]
    -- Female
    ["sax"] = {
        "play_saxophone@dark",
        "play_saxophone_clip",
        "Saxophone 1",
        AnimationOptions = {
            Prop = 'rpemotes_prop_saxophone01',
            PropBone = 57005,
            PropPlacement = {0.0700, 0.0400, 0.0300, -71.2242, 29.3364, 5.9514},
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["sax2"] = {
        "play_saxophone@dark",
        "play_saxophone_clip",
        "Saxophone 2",
        AnimationOptions = {
            Prop = 'rpemotes_prop_saxophone02',
            PropBone = 57005,
            PropPlacement = {0.0700, 0.0400, 0.0300, -71.2242, 29.3364, 5.9514},
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["breakfreefont"] = {
        "mp_arresting",
        "a_uncuff",
        "Défaire les menottes - Devant",
        AnimationOptions = {
            EmoteDuration = 6099,
            StartDelay = 450,
            EmoteMoving = true
        }
    },
    ["breakfreeback"] = {
        "mp_arresting",
        "b_uncuff",
        "Défaire les menottes - Derrière",
        AnimationOptions = {
            EmoteDuration = 6099,
            StartDelay = 450,
            EmoteMoving = true
        }
    },
    ["cheer"] = {"Scenario", "WORLD_HUMAN_CHEERING", "Célébrer"},
    ["cough"] = {
        "timetable@gardener@smoking_joint",
        "idle_cough",
        "Tousser",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["picklock"] = {
        "missheistfbisetup1",
        "hassle_intro_loop_f",
        "Crocheter",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    },
    ["headbutt"] = {
        "melee@unarmed@streamed_variations", "plyr_takedown_front_headbutt",
        "Mettre un coup de boule 1"
    },
    ["scared"] = {
        "random@domestic",
        "f_distressed_loop",
        "Avoir peur",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["scared2"] = {
        "random@homelandsecurity",
        "knees_loop_girl",
        "Avoir peur 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["warmth"] = {
        "amb@world_human_stand_fire@male@idle_a",
        "idle_a",
        "Se chauffer les mains autour du feu",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["pickup"] = {"random@domestic", "pickup_low", "Ramasser"},
    ["fallasleep"] = {
        "mp_sleep",
        "sleep_loop",
        "Dormir debout",
        AnimationOptions = {EmoteMoving = true, EmoteLoop = true}
    }
}

RP.ActivitesEmotes = {
    label = "Activités",
    icon = "🎨",
    ["airguitar"] = {
        "anim@mp_player_intcelebrationfemale@air_guitar", "air_guitar",
        "Guitare imaginaire"
    },
    ["airsynth"] = {
        "anim@mp_player_intcelebrationfemale@air_synth", "air_synth",
        "Piano imaginaire"
    },
    ["garden"] = {"Scenario", "WORLD_HUMAN_GARDENER_PLANT", "Jardinage"},
    ["hammer"] = {"Scenario", "WORLD_HUMAN_HAMMERING", "Taper au marteau"},
    ["drill"] = {"Scenario", "WORLD_HUMAN_CONST_DRILL", "Marteau piqueur"},
    ["filmshocking"] = {
        "Scenario", "WORLD_HUMAN_MOBILE_FILM_SHOCKING",
        "Filmer avec son téléphone"
    },
    ["bow"] = {
        "anim@arena@celeb@podium@no_prop@",
        "regal_c_1st",
        "Merci de fin de spectacle",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["bow2"] = {
        "anim@arena@celeb@podium@no_prop@",
        "regal_a_1st",
        "Merci de fin de spectacle 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["fallover"] = {
        "random@drunk_driver_1", "drunk_fall_over", "Ivre à en tomber"
    },
    ["hiking"] = {
        "move_m@hiking",
        "idle",
        "Tenir son sac",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["inspect"] = {"random@train_tracks", "idle_e", "Inspecter"},
    ["mechanic"] = {
        "mini@repair",
        "fixing_a_ped",
        "Réparer un moteur",
        AnimationOptions = {EmoteLoop = true}
    },
    ["mechanic2"] = {
        "mini@repair",
        "fixing_a_player",
        "Réparer un moteur 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["mechanic3"] = {
        "amb@world_human_vehicle_mechanic@male@base",
        "base",
        "Réparer l'avant du véhicule",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["mechanic4"] = {
        "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        "machinic_loop_mechandplayer",
        "Réparer un moteur 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["mechanic5"] = {
        "amb@prop_human_movie_bulb@idle_a",
        "idle_b",
        "Réparer un moteur 4",
        AnimationOptions = {EmoteLoop = true}
    },
    ["meditate"] = {
        "rcmcollect_paperleadinout@",
        "meditiate_idle",
        "Méditer",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["meditate2"] = {
        "rcmepsilonism3",
        "ep_3_rcm_marnie_meditating",
        "Méditer 2",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["meditate3"] = {
        "rcmepsilonism3",
        "base_loop",
        "Méditer 3",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["type"] = {
        "anim@heists@prison_heiststation@cop_reactions",
        "cop_b_idle",
        "Taper sur un clavier",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["type2"] = {
        "anim@heists@prison_heistig1_p1_guard_checks_bus",
        "loop",
        "Taper sur un clavier 2",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["type3"] = {
        "mp_prison_break",
        "hack_loop",
        "Taper sur un clavier 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["type4"] = {
        "mp_fbi_heist",
        "loop",
        "Taper sur un clavier 4",
        AnimationOptions = {EmoteLoop = true}
    },
    ["petting"] = {
        "creatures@rottweiler@tricks@",
        "petting_franklin",
        "Caresser",
        AnimationOptions = {EmoteLoop = true}
    },
    ["weld"] = {"Scenario", "WORLD_HUMAN_WELDING", "Outil de soudure"},
    ["windowshop"] = {
        "Scenario", "WORLD_HUMAN_WINDOW_SHOP_BROWSE",
        "Regarder un article à la vitrine"
    }
}

RP.GangEmotes = {
    label = "Gangs",
    icon = "🧢",
    ["mara"] = {
        "mp_player_int_uppergang_sign_a",
        "mp_player_int_gang_sign_a",
        "Marabunta",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["bal3"] = {
        "mp_player_int_uppergang_sign_b",
        "mp_player_int_gang_sign_b",
        "Ballas 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["fam3"] = {
        "amb@code_human_in_car_mp_actions@gang_sign_b@low@ps@base",
        "idle_a",
        "Families 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["vag3"] = {
        "amb@code_human_in_car_mp_actions@v_sign@std@rds@base",
        "idle_a",
        "Vagos 3",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    }
}

RP.SportEmotes = {
    label = "Sports",
    icon = "🏅",
    ["boxing"] = {
        "anim@mp_player_intcelebrationmale@shadow_boxing",
        "shadow_boxing",
        "Entraînement de boxe",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 4000}
    },
    ["boxing2"] = {
        "anim@mp_player_intcelebrationfemale@shadow_boxing",
        "shadow_boxing",
        "Entraînement de boxe 2",
        AnimationOptions = {EmoteMoving = true, EmoteDuration = 4000}
    },
    ["boxing3"] = {
        "melee@unarmed@streamed_core_fps",
        "idle",
        "Boxe 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["chinup"] = {
        "Scenario", "PROP_HUMAN_MUSCLE_CHIN_UPS", "Faire des tractions"
    },
    ["fightme"] = {
        "anim@deathmatch_intros@unarmed", "intro_male_unarmed_c",
        "Se mettre en position de combat"
    },
    ["fightme2"] = {
        "anim@deathmatch_intros@unarmed", "intro_male_unarmed_e",
        "S'étirer avant un combat"
    },
    ["jog2"] = {
        "amb@world_human_jog_standing@male@idle_a",
        "idle_a",
        "Faire son jogging",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["jog3"] = {
        "amb@world_human_jog_standing@female@idle_a",
        "idle_a",
        "Jogging heureux",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["jog4"] = {
        "amb@world_human_power_walker@female@idle_a",
        "idle_a",
        "Jogging avec les bras tendu",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["jog5"] = {
        "move_m@joy@a",
        "walk",
        "Jogging comme un robot",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["jumpingjacks"] = {
        "timetable@reunited@ig_2",
        "jimmy_getknocked",
        "Faire des Jumping Jacks",
        AnimationOptions = {EmoteLoop = true}
    },
    ["karate"] = {
        "anim@mp_player_intcelebrationfemale@karate_chops", "karate_chops",
        "Karaté"
    },
    ["karate2"] = {
        "anim@mp_player_intcelebrationmale@karate_chops", "karate_chops",
        "Karaté 2"
    },
    ["outofbreath"] = {
        "re@construction",
        "out_of_breath",
        "A bout de souffle",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["pushup"] = {
        "amb@world_human_push_ups@male@idle_a",
        "idle_d",
        "Faire des pompes",
        AnimationOptions = {EmoteLoop = true}
    },
    ["situp"] = {
        "amb@world_human_sit_ups@male@idle_a",
        "idle_a",
        "Faire des abdos",
        AnimationOptions = {EmoteLoop = true}
    },
    ["punching"] = {
        "rcmextreme2",
        "loop_punching",
        "Taper dans le ventre",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["yoga"] = {"Scenario", "WORLD_HUMAN_YOGA", "Yoga"},
    ["yoga2"] = {
        "timetable@amanda@ig_4",
        "ig_4_idle",
        "Yoga 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["flip2"] = {
        "anim@arena@celeb@flat@solo@no_props@", "cap_a_player_a", "Demi salto"
    },
    ["flip"] = {
        "anim@arena@celeb@flat@solo@no_props@", "flip_a_player_a", "Salto"
    },
    ["slide"] = {
        "anim@arena@celeb@flat@solo@no_props@", "slide_a_player_a",
        "Glissade sur les genoux"
    },
    ["slide2"] = {
        "anim@arena@celeb@flat@solo@no_props@", "slide_b_player_a",
        "Glissade sur les genoux 2"
    },
    ["slide3"] = {
        "anim@arena@celeb@flat@solo@no_props@", "slide_c_player_a",
        "Glissade sur les genoux 3"
    },
    ["slugger"] = {
        "anim@arena@celeb@flat@solo@no_props@", "slugger_a_player_a", "Cogneur"
    },
    ["stretch"] = {
        "mini@triathlon",
        "idle_e",
        "S'échauffer en s'étirant",
        AnimationOptions = {EmoteLoop = true}
    },
    ["stretch2"] = {
        "mini@triathlon",
        "idle_f",
        "S'échauffer en s'étirant 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["stretch3"] = {
        "mini@triathlon",
        "idle_d",
        "S'échauffer en s'étirant 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["stretch4"] = {
        "rcmfanatic1maryann_stretchidle_b",
        "idle_e",
        "S'échauffer en s'étirant 4",
        AnimationOptions = {EmoteLoop = true}
    },
    ["tighten"] = {
        "timetable@denice@ig_1",
        "idle_b",
        "Faire des étirements (Yoga)",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },

    ["flex2"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_002",
        "Flexion",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true --- Allows us to flex while performing another animation
        }
    },
    ["gympose"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_001",
        "Pose Gym",
        AnimationOptions = {EmoteLoop = true}
    },
    ["gympose2"] = { -- Custom Emote By Amnilka
        "frabi@malepose@solo@firstsport",
        "pose_sport_005",
        "Gym Pose 2 - Pompe a une main",
        AnimationOptions = {EmoteLoop = true}
    },
    ["gympose3"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_004",
        "Gym Pose 3 - Planche",
        AnimationOptions = {EmoteLoop = true}
    },
    ["gympose4"] = { -- Custom Female Emote By Frabi
        "frabi@femalepose@solo@firstsport",
        "fem_pose_sport_005",
        "Gym Pose 4 - Abdos",
        AnimationOptions = {EmoteLoop = true}
    },
    ["kick"] = {
        "missheistdockssetup1ig_13@kick_idle",
        "guard_beatup_kickidle_guard1",
        "Coup de pied",
        AnimationOptions = {EmoteLoop = true}
    },
    ["kick2"] = {
        "missheistdockssetup1ig_13@kick_idle",
        "guard_beatup_kickidle_guard2",
        "Coup de pied 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["kick3"] = {
        "melee@unarmed@streamed_core",
        "kick_close_a",
        "Coup de pied 3",
        AnimationOptions = {EmoteDuration = 1750}
    },
    ["idle"] = {
        "anim@heists@heist_corona@team_idles@male_a",
        "idle",
        "Patienter",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle2"] = {
        "anim@heists@heist_corona@team_idles@female_a",
        "idle",
        "Patienter 2",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle3"] = {
        "anim@heists@humane_labs@finale@strip_club",
        "ped_b_celebrate_loop",
        "Patienter 3",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle4"] = {
        "anim@mp_celebration@idles@female",
        "celebration_idle_f_a",
        "Patienter 4",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle5"] = {
        "anim@mp_corona_idles@female_b@idle_a",
        "idle_a",
        "Patienter 5",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle6"] = {
        "anim@mp_corona_idles@male_c@idle_a",
        "idle_a",
        "Patienter 6",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle7"] = {
        "anim@mp_corona_idles@male_d@idle_a",
        "idle_a",
        "Patienter 7",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle8"] = {
        "amb@world_human_hang_out_street@male_b@idle_a", "idle_b", "Patienter 8"
    },
    ["idle9"] = {
        "friends@fra@ig_1",
        "base_idle",
        "Patienter 9",
        AnimationOptions = {EmoteLoop = true}
    },
    ["idle10"] = {
        "mp_move@prostitute@m@french",
        "idle",
        "Patienter 10",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["idle11"] = {
        "random@countrysiderobbery",
        "idle_a",
        "Patienter 11",
        AnimationOptions = {EmoteLoop = true}
    }
}

RP.SanteEmotes = {
    label = "Médecine",
    icon = "🩺",
    ["cpr"] = {
        "mini@cpr@char_a@cpr_str",
        "cpr_pumpchest",
        "Massage cardiaque au sol",
        AnimationOptions = {EmoteLoop = true}
    },
    ["cpr2"] = {
        "mini@cpr@char_a@cpr_str",
        "cpr_pumpchest",
        "Massage cardiaque sur une table",
        AnimationOptions = {EmoteLoop = true, EmoteMoving = true}
    },
    ["medic"] = {
        "Scenario", "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
        "Médecin inspectant une personne"
    },
    ["medic2"] = {
        "amb@medic@standing@tendtodead@base",
        "base",
        "Médecin inspectant un blessé",
        AnimationOptions = {EmoteLoop = true}
    },
    ["shot"] = {
        "random@dealgonewrong",
        "idle_a",
        "Blesser par balle au sol",
        AnimationOptions = {
            EmoteLoop = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout"] = {
        "missarmenian2",
        "drunk_loop",
        "Perdre connaissance",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout2"] = {
        "missarmenian2",
        "corpse_search_exit_ped",
        "Perdre connaissance 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout3"] = {
        "anim@gangops@morgue@table@",
        "body_search",
        "Perdre connaissance 3",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout4"] = {
        "mini@cpr@char_b@cpr_def",
        "cpr_pumpchest_idle",
        "Perdre connaissance 4",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout5"] = {
        "random@mugging4",
        "flee_backward_loop_shopkeeper",
        "Perdre connaissance 5",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["passout6"] = {
        "anim@scripted@data_leak@fix_bil_ig2_chopper_crawl@",
        "fix_bil_ig2_chopper_crawl_loop_ped",
        "Perdre connaissance 6",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 900,
            NotInVehicle = true,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["crawl"] = {
        "move_injured_ground",
        "front_loop",
        "Ramper",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "meditateup",
            ExitEmoteType = "Exits"
        }
    },
    ["fallover2"] = {"mp_suicide", "pistol", "Se tirer une balle dans la tête"},
    ["fallover3"] = {"mp_suicide", "pill", "Prendre du poison"},
    ["fallover4"] = {
        "friends@frf@ig_2", "knockout_plyr",
        "Se prendre une balle en pleine tête"
    },
    ["fallover5"] = {
        "anim@gangops@hostage@", "victim_fail", "Se prendre une droite"
    }
}

RP.Vehicules = {
    label = "Voitures",
    icon = "🚗",
    ["patrolcar"] = {
        "amb@incar@male@patrol@torch@base",
        "base",
        "Voiture Patrouille - Devant",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0100,
                -0.0100,
                0.0,
                0.0,
                100.0000
            },
            EmoteLoop = true
        }
    },
    ["patrolcarl"] = {
        "amb@incar@male@patrol@torch@idle_b",
        "idle_d",
        "Voiture Patrouille - Gauche",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0100,
                -0.0100,
                0.0,
                0.0,
                100.0000
            },
            EmoteLoop = true
        }
    },
    ["patrolcarr"] = {
        "amb@incar@male@patrol@torch@idle_a",
        "idle_a",
        "Voiture Patrouille - Droite",
        AnimationOptions = {
            Prop = 'prop_cs_police_torch_02',
            PropBone = 28422,
            PropPlacement = {
                0.0,
                -0.0100,
                -0.0100,
                0.0,
                0.0,
                100.0000
            },
            EmoteLoop = true
        }
    },
    ["pavehcar1l"] = {
        "pavehcar1l@animations",
        "pavehcar1lclip",
        "Veh Assis Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar1r"] = {
        "pavehcar1r@animations",
        "pavehcar1rclip",
        "Veh Assis Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar2r"] = {
        "pavehcar2r@animations",
        "pavehcar2rclip",
        "Veh Tenir A Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar2l"] = {
        "pavehcar2l@animations",
        "pavehcar2lclip",
        "Veh Tenir A gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar3r"] = {
        "pavehcar3r@animations",
        "pavehcar3rclip",
        "Veh Assis Relax Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar3l"] = {
        "pavehcar3l@animations",
        "pavehcar3lclip",
        "Veh Assis Relax Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar4r"] = {
        "pavehcar4r@animations",
        "pavehcar4rclip",
        "Veh Assis et Saluer Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar4l"] = {
        "pavehcar4l@animations",
        "pavehcar4lclip",
        "Veh Assis Cool Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar5r"] = {
        "pavehcar5r@animations",
        "pavehcar5rclip",
        "Veh Rock And Roll Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar5l"] = {
        "pavehcar5l@animations",
        "pavehcar5lclip",
        "Veh Rock And Roll Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar6r"] = {
        "pavehcar6r@animations",
        "pavehcar6rclip",
        "Veh Assis Relax Toit Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar6l"] = {
        "pavehcar6l@animations",
        "pavehcar6lclip",
        "Veh Assis Relax Toit Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar7r"] = {
        "pavehcar7r@animations",
        "pavehcar7rclip",
        "Veh Assis Heureux Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar7l"] = {
        "pavehcar7l@animations",
        "pavehcar7lclip",
        "Veh Assis Heureux Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar8r"] = {
        "pavehcar8r@animations",
        "pavehcar8rclip",
        "Veh Dormir Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar8l"] = {
        "pavehcar8l@animations",
        "pavehcar8lclip",
        "Veh Dormir Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar9r"] = {
        "pavehcar9r@animations",
        "pavehcar9rclip",
        "Veh Prendre Video Droite",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropBone = 28422,
            PropPlacement = {
                0.05,
                0.0100,
                0.060,
                -174.961,
                149.618,
                8.649,
            },
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar9l"] = {
        "pavehcar9l@animations",
        "pavehcar9lclip",
        "Veh Prendre Video Gauche",
        AnimationOptions = {
            Prop = "prop_phone_ing",
            PropBone = 58866,
            PropPlacement = {
                0.07,
                -0.0500,
                0.010,
                -105.33,
                -168.30,
                48.97,
            },
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pavehcar10"] = {
        "pavehcar10@animations",
        "pavehcar10clip",
        "Veh Assis Joyeux Lucia",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar1"] = {
        "pbvehcar1@animations",
        "pbvehcar1clip",
        "Veh Assis Ou Je Suis",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar2"] = {
        "pbvehcar2@animations",
        "pbvehcar2clip",
        "Veh Assis Aimer le Vent",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar3r"] = {
        "pbvehcar3r@animations",
        "pbvehcar3rclip",
        "Veh Assis Aimer la Balade Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar3l"] = {
        "pbvehcar3l@animations",
        "pbvehcar3lclip",
        "Veh Assis Aimer la Balade Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar4r"] = {
        "pbvehcar4r@animations",
        "pbvehcar4rclip",
        "Veh Assis Aimer la Balade 2 Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar4l"] = {
        "pbvehcar4l@animations",
        "pbvehcar4lclip",
        "Veh Assis Aimer la Balade 2 Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar5r"] = {
        "pbvehcar5r@animations",
        "pbvehcar5rclip",
        "Veh Assis Regarder la Vue Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar5l"] = {
        "pbvehcar5l@animations",
        "pbvehcar5lclip",
        "Veh Assis Regarder la Vue Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar6r"] = {
        "pbvehcar6r@animations",
        "pbvehcar6rclip",
        "Veh Twerk Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar6l"] = {
        "pbvehcar6l@animations",
        "pbvehcar6lclip",
        "Veh Twerk Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar7l"] = {
        "pbvehcar7l@animations",
        "pbvehcar7lclip",
        "Veh Se tenir debout côté conducteur Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar8"] = {
        "pbvehcar8@animations",
        "pbvehcar8clip",
        "Veh Dormir Sur le Toit",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar9"] = {
        "pbvehcar9@animations",
        "pbvehcar9clip",
        "Veh Assis sur le Toit",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pbvehcar10"] = {
        "pbvehcar10@animations",
        "pbvehcar10clip",
        "Veh Assis sur le Toit",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar1"] = {
        "pcvehcar1@animations",
        "pcvehcar1clip",
        "Veh Assis Aime la Balade",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar2r"] = {
        "pcvehcar2r@animations",
        "pcvehcar2rclip",
        "Veh Assis Coffre Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar2l"] = {
        "pcvehcar2l@animations",
        "pcvehcar2lclip",
        "Veh Assis Coffre Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar3r"] = {
        "pcvehcar3r@animations",
        "pcvehcar3rclip",
        "Veh Assis Coffre Ouvert Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar3l"] = {
        "pcvehcar3l@animations",
        "pcvehcar3lclip",
        "Veh Assis Coffre Ouvert Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar4r"] = {
        "pcvehcar4r@animations",
        "pcvehcar4rclip",
        "Veh Voler Droite",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar4l"] = {
        "pcvehcar4l@animations",
        "pcvehcar4lclip",
        "Veh Voler Gauche",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar5"] = {
        "pcvehcar5@animations",
        "pcvehcar5clip",
        "Veh Voler Aléatoire",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar6"] = {
        "pcvehcar6@animations",
        "pcvehcar6clip",
        "Veh Vole Plus Haut",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar7"] = {
        "pcvehcar7@animations",
        "pcvehcar7clip",
        "Veh Passager Moto",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar8"] = {
        "pcvehcar8@animations",
        "pcvehcar8clip",
        "Veh Moto Deux Pistolet",
        AnimationOptions = {
            Prop = 'w_pi_pistol',
            PropBone = 26611,
            PropPlacement = {
                0.07,
                -.01,
                0.01,
                -29.999,
                0.0,
                10.000
            },
            SecondProp = 'w_pi_pistol',
            SecondPropBone = 58867,
            SecondPropPlacement = {
                0.07,
                0.01,
                0.01,
                29.999,
                0.0,
                -10.000
            },
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
    ["pcvehcar9"] = {
        "pcvehcar9@animations",
        "pcvehcar9clip",
        "Veh Moto Assis à L’envers",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            FullBody = true
        }
    },
}
