---@meta _
---@diagnostic disable: duplicate-doc-field

-- Emotes you add in the file will automatically be added to AnimationList.lua
-- If you have multiple custom list files they MUST be added between AnimationList.lua and Emote.lua in fxmanifest.lua!
-- Don't change 'CustomDP' it is local to this file!
local CustomDP = {}

CustomDP.Expressions = {}
CustomDP.Walks = {}
CustomDP.Shared = {
    ["pcarrya1"] = {
        "pcarrya1@animations",
        "pcarrya1clip",
        "Porter 1 Épaule Couvrant les Yeux",
        "pcarrya2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarrya2"] = {
        "pcarrya2@animations",
        "pcarrya2clip",
        "Porter 2 Épaule Couvrant les Yeux",
        "pcarrya1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.000,
            yPos = 0.000,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryb1"] = {
        "pcarryb1@animations",
        "pcarryb1clip",
        "Porter 1 Débattre Derrière",
        "pcarryb2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryb2"] = {
        "pcarryb2@animations",
        "pcarryb2clip",
        "Porter 2 Débattre Derrière",
        "pcarryb1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.000,
            yPos = 0.000,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryc1"] = {
        "pcarryc1@animations",
        "pcarryc1clip",
        "Porter 1 Mort Derrière",
        "pcarryc2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryc2"] = {
        "pcarryc2@animations",
        "pcarryc2clip",
        "Porter 2 Mort Derrière",
        "pcarryc1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.360,
            yPos = 0.000,
            zPos = -0.020,
            xRot = 0.0,
            yRot = 0.0,
            zRot = -10.0
        }
    },
    ["pcarryd1"] = {
        "pcarryd1@animations",
        "pcarryd1clip",
        "Porter 1 Pompier Épaule",
        "pcarryd2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryd2"] = {
        "pcarryd2@animations",
        "pcarryd2clip",
        "Porter 2 Pompier Épaule",
        "pcarryd1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.120,
            yPos = -0.150,
            zPos = -0.050,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -3.000
        }
    },
    ["pcarrye1"] = {
        "pcarrye1@animations",
        "pcarrye1clip",
        "Porter 1 Épaule Debout",
        "pcarrye2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarrye2"] = {
        "pcarrye2@animations",
        "pcarrye2clip",
        "Porter 2 Épaule Debout",
        "pcarrye1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.230,
            yPos = 0.020,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryf1"] = {
        "pcarryf1@animations",
        "pcarryf1clip",
        "Porter 1 Méditation Pieds sur la Tête",
        "pcarryf2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryf2"] = {
        "pcarryf2@animations",
        "pcarryf2clip",
        "Porter 2 Méditation Pieds sur la Tête",
        "pcarryf1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.230,
            yPos = 0.020,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryg1"] = {
        "pcarryg1@animations",
        "pcarryg1clip",
        "Porter 1 Superman",
        "pcarryg2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryg2"] = {
        "pcarryg2@animations",
        "pcarryg2clip",
        "Porter 2 Superman",
        "pcarryg1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.850,
            yPos = -0.120,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryh1"] = {
        "pcarryh1@animations",
        "pcarryh1clip",
        "Porter 1 Mignon Épaule Dos",
        "pcarryh2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryh2"] = {
        "pcarryh2@animations",
        "pcarryh2clip",
        "Porter 2 Mignon Épaule Dos",
        "pcarryh1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.130,
            yPos = -0.130,
            zPos = -0.050,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryi1"] = {
        "pcarryi1@animations",
        "pcarryi1clip",
        "Porter 1 Oiseau",
        "pcarryi2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryi2"] = {
        "pcarryi2@animations",
        "pcarryi2clip",
        "Porter 2 Oiseau",
        "pcarryi1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.700,
            yPos = -0.330,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -15.000
        }
    },
    ["pcarryj1"] = {
        "pcarryj1@animations",
        "pcarryj1clip",
        "Porter 1 Woohoo",
        "pcarryj2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryj2"] = {
        "pcarryj2@animations",
        "pcarryj2clip",
        "Porter 2 Woohoo",
        "pcarryj1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.350,
            yPos = -0.490,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -30.000
        }
    },
    ["pcarryk1"] = {
        "pcarryk1@animations",
        "pcarryk1clip",
        "Porter 1 Triste Recroquevillé",
        "pcarryk2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryk2"] = {
        "pcarryk2@animations",
        "pcarryk2clip",
        "Porter 2 Triste Recroquevillé",
        "pcarryk1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.060,
            yPos = 0.100,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryl1"] = {
        "pcarryl1@animations",
        "pcarryl1clip",
        "Porter 1 Triste Devant",
        "pcarryl2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryl2"] = {
        "pcarryl2@animations",
        "pcarryl2clip",
        "Porter 2 Triste Devant",
        "pcarryl1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.050,
            yPos = 0.070,
            zPos = 0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarrym1"] = {
        "pcarrym1@animations",
        "pcarrym1clip",
        "Porter 1 Debout À l'Envers",
        "pcarrym2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarrym2"] = {
        "pcarrym2@animations",
        "pcarrym2clip",
        "Porter 2 Debout À l'Envers",
        "pcarrym1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.820,
            yPos = 0.150,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 5.000
        }
    },
    ["pcarryn1"] = {
        "pcarryn1@animations",
        "pcarryn1clip",
        "Porter 1 Salut",
        "pcarryn2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryn2"] = {
        "pcarryn2@animations",
        "pcarryn2clip",
        "Porter 2 Salut",
        "pcarryn1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.230,
            yPos = 0.020,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryo1"] = {
        "pcarryo1@animations",
        "pcarryo1clip",
        "Porter 1 Arrogant",
        "pcarryo2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryo2"] = {
        "pcarryo2@animations",
        "pcarryo2clip",
        "Porter 2 Arrogant",
        "pcarryo1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.550,
            yPos = 0.010,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryp1"] = {
        "pcarryp1@animations",
        "pcarryp1clip",
        "Porter 1 Dab",
        "pcarryp2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryp2"] = {
        "pcarryp2@animations",
        "pcarryp2clip",
        "Porter 2 Dab",
        "pcarryp1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.550,
            yPos = 0.010,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryq1"] = {
        "pcarryq1@animations",
        "pcarryq1clip",
        "Porter 1 Méditation Taureau",
        "pcarryq2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryq2"] = {
        "pcarryq2@animations",
        "pcarryq2clip",
        "Porter 2 Méditation Taureau",
        "pcarryq1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.200,
            yPos = -0.500,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -80.000
        }
    },
    ["pcarryr1"] = {
        "pcarryr1@animations",
        "pcarryr1clip",
        "Porter 1 Mignon Timide Épaule",
        "pcarryr2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryr2"] = {
        "pcarryr2@animations",
        "pcarryr2clip",
        "Porter 2 Mignon Timide Épaule",
        "pcarryr1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.070,
            yPos = -0.100,
            zPos = -0.280,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarrys1"] = {
        "pcarrys1@animations",
        "pcarrys1clip",
        "Porter 2 Dormir Au-Dessus Tête",
        "pcarrys2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarrys2"] = {
        "pcarrys2@animations",
        "pcarrys2clip",
        "Porter 2 Dormir Au-Dessus Tête",
        "pcarrys1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.880,
            yPos = 0.000,
            zPos = -0.080,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryt1"] = {
        "pcarryt1@animations",
        "pcarryt1clip",
        "Porter 1 Conduite Moto",
        "pcarryt2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryt2"] = {
        "pcarryt2@animations",
        "pcarryt2clip",
        "Porter 2 Conduite Moto",
        "pcarryt1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.520,
            yPos = 0.030,
            zPos = -0.010,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryu1"] = {
        "pcarryu1@animations",
        "pcarryu1clip",
        "Porter 1 Mignon Assis Épaule",
        "pcarryu2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryu2"] = {
        "pcarryu2@animations",
        "pcarryu2clip",
        "Porter 2 Mignon Assis Épaule",
        "pcarryu1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.290,
            yPos = 0.040,
            zPos = -0.220,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryv1"] = {
        "pcarryv1@animations",
        "pcarryv1clip",
        "Porter 1 Tirer Tête Arrière",
        "pcarryv2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryv2"] = {
        "pcarryv2@animations",
        "pcarryv2clip",
        "Porter 2 Tirer Tête Arrière",
        "pcarryv1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.340,
            yPos = -0.180,
            zPos = 0.150,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 50.000
        }
    },
    ["pcarryw1"] = {
        "pcarryw1@animations",
        "pcarryw1clip",
        "Porter 1 Dégoûtant",
        "pcarryw2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryw2"] = {
        "pcarryw2@animations",
        "pcarryw2clip",
        "Porter 2 Dégoûtant",
        "pcarryw1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 28422,
            xPos = 0.000,
            yPos = -0.140,
            zPos = -0.410,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryx1"] = {
        "pcarryx1@animations",
        "pcarryx1clip",
        "Porter 1 Attrapé",
        "pcarryx2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryx2"] = {
        "pcarryx2@animations",
        "pcarryx2clip",
        "Porter 2 Attrapé",
        "pcarryx1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 28422,
            xPos = 0.250,
            yPos = -0.200,
            zPos = 0.130,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryy1"] = {
        "pcarryy1@animations",
        "pcarryy1clip",
        "Porter 1 Torture",
        "pcarryy2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryy2"] = {
        "pcarryy2@animations",
        "pcarryy2clip",
        "Porter 2 Torture",
        "pcarryy1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 28422,
            xPos = 0.240,
            yPos = -0.560,
            zPos = 0.750,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -160.000
        }
    },
    ["pcarryz1"] = {
        "pcarryz1@animations",
        "pcarryz1clip",
        "Porter 1 Bazooka",
        "pcarryz2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryz2"] = {
        "pcarryz2@animations",
        "pcarryz2clip",
        "Porter 2 Bazooka",
        "pcarryz1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 57005,
            xPos = 0.020,
            yPos = 0.190,
            zPos = -0.220,
            xRot = 0.0,
            yRot = 0.0,
            zRot = -79.999
        }
    },
    ["pcarryza1"] = {
        "pcarryza1@animations",
        "pcarryza1clip",
        "Porter 1 Bourré Derrière",
        "pcarryza2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryza2"] = {
        "pcarryza2@animations",
        "pcarryza2clip",
        "Porter 2 Bourré Derrière",
        "pcarryza1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.560,
            yPos = 0.030,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzb1"] = {
        "pcarryzb1@animations",
        "pcarryzb1clip",
        "Porter 1 Regarder Haut",
        "pcarryzb2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzb2"] = {
        "pcarryzb2@animations",
        "pcarryzb2clip",
        "Porter 2 Regarder Haut",
        "pcarryzb1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.943,
            yPos = -0.010,
            zPos = -0.024,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzc1"] = {
        "pcarryzc1@animations",
        "pcarryzc1clip",
        "Porter 1 Maître Méditation",
        "pcarryzc2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzc2"] = {
        "pcarryzc2@animations",
        "pcarryzc2clip",
        "Porter 2 Maître Méditation",
        "pcarryzc1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.160,
            yPos = 0.020,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzd1"] = {
        "pcarryzd1@animations",
        "pcarryzd1clip",
        "Porter 1 Homme Fort",
        "pcarryzd2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzd2"] = {
        "pcarryzd2@animations",
        "pcarryzd2clip",
        "Porter 2 Homme Fort",
        "pcarryzd1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.590,
            yPos = 0.010,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryze1"] = {
        "pcarryze1@animations",
        "pcarryze1clip",
        "Porter 1 Mignon Sur le Dos",
        "pcarryze2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryze2"] = {
        "pcarryze2@animations",
        "pcarryze2clip",
        "Porter 2 Mignon Sur le Dos",
        "pcarryze1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.180,
            yPos = -0.020,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -10.000
        }
    },
    ["pcarryzf1"] = {
        "pcarryzf1@animations",
        "pcarryzf1clip",
        "Porter 1 Course Sur le Dos",
        "pcarryzf2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzf2"] = {
        "pcarryzf2@animations",
        "pcarryzf2clip",
        "Porter 2 Course Sur le Dos",
        "pcarryzf1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.210,
            yPos = -0.270,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -90.000
        }
    },
    ["pcarryzg1"] = {
        "pcarryzg1@animations",
        "pcarryzg1clip",
        "Porter 1 Tirer Mains Arrière",
        "pcarryzg2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzg2"] = {
        "pcarryzg2@animations",
        "pcarryzg2clip",
        "Porter 2 Tirer Mains Arrière",
        "pcarryzg1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.150,
            yPos = -0.670,
            zPos = -0.010,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -80.000
        }
    },
    ["pcarryzh1"] = {
        "pcarryzh1@animations",
        "pcarryzh1clip",
        "Porter 1 Poteau",
        "pcarryzh2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzh2"] = {
        "pcarryzh2@animations",
        "pcarryzh2clip",
        "Porter 2 Poteau",
        "pcarryzh1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.110,
            yPos = 0.120,
            zPos = -0.270,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -10.000
        }
    },
    ["pcarryzi1"] = {
        "pcarryzi1@animations",
        "pcarryzi1clip",
        "Porter 1 Mignon Devant",
        "pcarryzi2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzi2"] = {
        "pcarryzi2@animations",
        "pcarryzi2clip",
        "Porter 2 Mignon Devant",
        "pcarryzi1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.100,
            yPos = 0.250,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzj1"] = {
        "pcarryzj1@animations",
        "pcarryzj1clip",
        "Porter 1 Caresser Tête",
        "pcarryzj2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzj2"] = {
        "pcarryzj2@animations",
        "pcarryzj2clip",
        "Porter 2 Caresser Tête",
        "pcarryzj1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.270,
            yPos = 0.010,
            zPos = -0.060,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzk1"] = {
        "pcarryzk1@animations",
        "pcarryzk1clip",
        "Porter 1 Mignon Effrayé",
        "pcarryzk2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzk2"] = {
        "pcarryzk2@animations",
        "pcarryzk2clip",
        "Porter 2 Mignon Effrayé",
        "pcarryzk1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.200,
            yPos = 0.010,
            zPos = 0.100,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzl1"] = {
        "pcarryzl1@animations",
        "pcarryzl1clip",
        "Porter 1 Sac",
        "pcarryzl2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzl2"] = {
        "pcarryzl2@animations",
        "pcarryzl2clip",
        "Porter 2 Sac",
        "pcarryzl1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.040,
            yPos = 0.060,
            zPos = -0.030,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzm1"] = {
        "pcarryzm1@animations",
        "pcarryzm1clip",
        "Porter 1 Sac Retourné",
        "pcarryzm2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzm2"] = {
        "pcarryzm2@animations",
        "pcarryzm2clip",
        "Porter 2 Sac Retourné",
        "pcarryzm1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.120,
            yPos = 0.050,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -15.000
        }
    },
    ["pcarryzn1"] = {
        "pcarryzn1@animations",
        "pcarryzn1clip",
        "Porter 1 Câlin Dos Retourné",
        "pcarryzn2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzn2"] = {
        "pcarryzn2@animations",
        "pcarryzn2clip",
        "Porter 2 Câlin Dos Retourné",
        "pcarryzn1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.210,
            yPos = 0.050,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -15.000
        }
    },
    ["pcarryzo1"] = {
        "pcarryzo1@animations",
        "pcarryzo1clip",
        "Porter 1 Assis 'PCarry 1 Sit & Wave Over Head', Salue Au-Dessus Tête",
        "pcarryzo2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzo2"] = {
        "pcarryzo2@animations",
        "pcarryzo2clip",
        "Porter 2 Assis 'PCarry 2 Sit & Wave Over Head', Salue Au-Dessus Tête",
        "pcarryzo1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.190,
            yPos = -0.020,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzp1"] = {
        "pcarryzp1@animations",
        "pcarryzp1clip",
        "Porter 1 Mignon Coup de Poing Tête",
        "pcarryzp2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzp2"] = {
        "pcarryzp2@animations",
        "pcarryzp2clip",
        "Porter 2 Mignon Coup de Poing Tête",
        "pcarryzp1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.450,
            yPos = -0.160,
            zPos = -0.030,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzq1"] = {
        "pcarryzq1@animations",
        "pcarryzq1clip",
        "Porter 1 Super-Héros",
        "pcarryzq2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzq2"] = {
        "pcarryzq2@animations",
        "pcarryzq2clip",
        "Porter 2 Super-Héros",
        "pcarryzq1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.270,
            yPos = 0.540,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzr1"] = {
        "pcarryzr1@animations",
        "pcarryzr1clip",
        "Porter 1 Épaule Jambes Croisées Tête",
        "pcarryzr2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzr2"] = {
        "pcarryzr2@animations",
        "pcarryzr2clip",
        "Porter 2 Épaule Jambes Croisées Tête",
        "pcarryzr1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.600,
            yPos = -0.090,
            zPos = 0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzs1"] = {
        "pcarryzs1@animations",
        "pcarryzs1clip",
        "Porter 1 Ne Peut Pas Respirer",
        "pcarryzs2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzs2"] = {
        "pcarryzs2@animations",
        "pcarryzs2clip",
        "Porter 2 Ne Peut Pas Respirer",
        "pcarryzs1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.030,
            yPos = -0.180,
            zPos = 0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzt1"] = {
        "pcarryzt1@animations",
        "pcarryzt1clip",
        "Porter 1 Pompier Dos",
        "pcarryzt2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzt2"] = {
        "pcarryzt2@animations",
        "pcarryzt2clip",
        "Porter 2 Pompier Dos",
        "pcarryzt1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.330,
            yPos = 0.000,
            zPos = -0.040,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -80.000
        }
    },
    ["pcarryzu1"] = {
        "pcarryzu1@animations",
        "pcarryzu1clip",
        "Porter 1 Heureux Derrière",
        "pcarryzu2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzu2"] = {
        "pcarryzu2@animations",
        "pcarryzu2clip",
        "Porter 2 Heureux Derrière",
        "pcarryzu1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.290,
            yPos = -0.300,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -80.000
        }
    },
    ["pcarryzv1"] = {
        "pcarryzv1@animations",
        "pcarryzv1clip",
        "Porter 1 Heureux Balancement",
        "pcarryzv2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzv2"] = {
        "pcarryzv2@animations",
        "pcarryzv2clip",
        "Porter 2 Heureux Balancement",
        "pcarryzv1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = -0.040,
            yPos = -0.720,
            zPos = -0.600,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    ["pcarryzw1"] = {
        "pcarryzw1@animations",
        "pcarryzw1clip",
        "Porter 1 Sur le Dos Tête",
        "pcarryzw2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzw2"] = {
        "pcarryzw2@animations",
        "pcarryzw2clip",
        "Porter 2 Sur le Dos Tête",
        "pcarryzw1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.320,
            yPos = -0.220,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -80.000
        }
    },
    ["pcarryzx1"] = {
        "pcarryzx1@animations",
        "pcarryzx1clip",
        "Porter 1 Pose Au-Dessus Tête",
        "pcarryzx2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzx2"] = {
        "pcarryzx2@animations",
        "pcarryzx2clip",
        "Porter 2 Pose Au-Dessus Tête",
        "pcarryzx1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.430,
            yPos = -0.860,
            zPos = 0.000,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -80.000
        }
    },
    ["pcarryzy1"] = {
        "pcarryzy1@animations",
        "pcarryzy1clip",
        "Porter 1 Sur le Dos Tenir Tête",
        "pcarryzy2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzy2"] = {
        "pcarryzy2@animations",
        "pcarryzy2clip",
        "Porter 2 Sur le Dos Tenir Tête",
        "pcarryzy1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 0.060,
            yPos = -0.070,
            zPos = -0.020,
            xRot = 0.000,
            yRot = 0.000,
            zRot = -20.000
        }
    },
    ["pcarryzz1"] = {
        "pcarryzz1@animations",
        "pcarryzz1clip",
        "Porter 1 Pouvoir du Cœur",
        "pcarryzz2",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcarryzz2"] = {
        "pcarryzz2@animations",
        "pcarryzz2clip",
        "Porter 2 Pouvoir du Cœur",
        "pcarryzz1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 24818,
            xPos = 1.110,
            yPos = 0.210,
            zPos = -0.780,
            xRot = 0.000,
            yRot = 0.000,
            zRot = 0.000
        }
    },
    --NEW SHARED ANIMATIONS LEO

    ["gnomeboys1"] = {
        "gnomeboys@Animation",
        "gnomeboys1_clip",
        "Quelqu'un à Aimer 1",
        "gnomeboys2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,

        }
    },
    ["gnomeboys2"] = {
        "gnomeboys@Animation",
        "gnomeboys2_clip",
        "Quelqu'un à Aimer 2",
        "gnomeboys1",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,

        }
    },
    ["lovewallpaper1"] = {"lovewallpaper-1@kyunnies", "lovewallpaper-1_clip", "Fond d'Écran Amour 1", "lovewallpaper2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,

    }},
    ["lovewallpaper2"] = {"lovewallpaper-2@kyunnies", "lovewallpaper-2_clip", "Fond d'Écran Amour 2", "lovewallpaper1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Attachto = true,
        xPos = 0.450,
        yPos = 1.3000,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = -11.9900,
    }
    },
    ["marikitdance"] = {"marikitdance@anim", "marikitdance_anim", "Danse Marikit", "marikitkiss", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,

    }},
    ["marikitkiss"] = {"marikitkisscheek@anim", "marikitkisscheek_anim", "Bisou Marikit", "marikitdance", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Attachto = true,
        xPos = -0.660,
        yPos = 0.1200,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 171.100,

    }
    },
    ["jleaningwallback"] = {
        "anim@amb@casino@peds@",
        "amb_world_human_leaning_male_wall_back_mobile_idle_a",
        "Adossé au Mur · Homme",
        AnimationOptions =
        {
            Prop = "scrlt_iphone14max_03",
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["kyunnies_na_spotdance1"] = {"spotdance_1@kyunnies", "spot_clip", "Danse Spot - Homme", "kyunnies_na_spotdance2", AnimationOptions =  ---- Custom Emotes by Kyunnies - Nada Aurea
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }
    },
    ["kyunnies_na_spotdance2"] = {"spotdance_2@kyunnies", "spot2_clip", "Danse Spot - Femme", "kyunnies_na_spotdance1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Attachto = true,
        xPos = -0.0130,
        yPos = -0.5364,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = -1.000,
    }},
    ["kyunnies_na_memory_couple-1"] = {"memory_couple-1@kyunnies", "pose1_clip", "Couple Souvenir 1", "kyunnies_na_memory_couple-2", AnimationOptions =  ---- Custom Emotes by Kyunnies - Nada Aurea
    {
        EmoteLoop = true,
        EmoteMoving = false,

    }},
    ["kyunnies_na_memory_couple-2"] = {"memory_couple-2@kyunnies", "pose2_clip", "Couple Souvenir 2", "kyunnies_na_memory_couple-1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Attachto = true,
        xPos = 0.590,
        yPos = 0.0400,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 7.0,
    }},

    ["kyunnies_na_lookatme_couple-1"] = {"lookatme_couple-1@kyunnies", "pose1_clip", "Regarde-Moi 1", "kyunnies_na_lookatme_couple-2", AnimationOptions =  ---- Custom Emotes by Kyunnies - Nada Aurea
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["kyunnies_na_lookatme_couple-2"] = {"lookatme_couple-2@kyunnies", "pose2_clip", "Regarde-Moi 2", "kyunnies_na_lookatme_couple-1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Attachto = true,
        xPos = -0.430,
        yPos = 0.050,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = -1.000,
        Prop = 'scrlt_iphone14max_06',
        PropBone = 60309,
        PropPlacement =
        0.090,
        0.020,
        0.020,
        -105.883,
        -21.637,
        -6.978
    }},
    ["maleperfect"] = {
        "maleperfect@animation",
        "malep_clip",
        "Parfait Homme",
        "femaleperfect",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }},
    ["femaleperfect"] = {
        "femaleperfect@animation",
        "femalep_clip",
        "Parfaite Femme",
        "maleperfect",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }},
    ["000000000glap-hskt-2"] = {"glap@hskt-r", "hskt-r", "HSKT Droite Nouveau", "000000000glap-hskt-1", AnimationOptions = {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        bone = 9816,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0
    }},
    ["000000000glap-hskt-1"] = {"glap@hskt-l", "hskt-l", "HSKT Gauche Nouveau", "000000000glap-hskt-2", AnimationOptions = {
        EmoteMoving = false,
        EmoteLoop = true
    }},
    ["firstsnowcouple_male"] = {
        "jarp_firstsnow_couple_male",
        "jarp_firstsnow_couple_male_clip",
        "Danse de Couple Première Neige Droite",
        "firstsnowcouple_female",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            SyncOffsetFront = 1.2,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }
    },
    ["firstsnowcouple_female"] = {
        "jarp_firstsnow_couple_female",
        "jarp_firstsnow_couple_female_clip",
        "Danse de Couple Première Neige Gauche",
        "firstsnowcouple_male",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            SyncOffsetFront = 1.2,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }
    },
    ["hsktf"] = {
        "hsktf@animation",
        "hsktf_clip",
        "HSKT Femme",
        "hsktm",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }
    },
    ["hsktm"] = {
        "hsktm@animation",
        "hsktm_clip",
        "HSKT Homme",
        "hsktf",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["0000oudhskt_rs"] = {
        "oudoud@hskt_share",
        "oudoud_hskt_share_right",
        "HSKT Lee Hi Droite",
        "0000oudhskt_ls",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["0000oudhskt_ls"] = {
        "oudoud@hskt_share",
        "oudoud_hskt_share_left",
        "HSKT Lee Hi Gauche",
        "0000oudhskt_rs",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["igotafeelingm"] = {
        "igotafeelingm@animation",
        "igotafeelingm_clip",
        "J'ai un Pressentiment 1",
        "igotafeelingf",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["igotafeelingf"] = {
        "igotafeelingf@animation",
        "igotafeelingf_clip",
        "J'ai un Pressentiment 2",
        "igotafeelingm",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["levitatingm"] = {
        "levitatingm@animation",
        "levitatingm_clip",
        "Lévitation Homme",
        "levitatingf",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["levitatingf"] = {
        "levitatingf@animation",
        "levitatingf_clip",
        "Lévitation Femme",
        "levitatingm",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            SyncOffsetFront = 0.6,
            SyncOffsetSide = 0.0,
            SyncOffsetHeight = 0.0,
            SyncOffsetHeading = 180.0,
        }},
    ["aptshare01"] = {"oudoud@apt_rose_share", "oudoud_apt_rose_share_right", "APT Partage Droite", "aptshare02", AnimationOptions =
    {
        EmoteLoop = true,
        SyncOffsetFront = 0.6,
    }},

    ["aptshare02"] = {"oudoud@apt_rose_share", "oudoud_apt_rose_share_left", "APT Partage Gauche", "aptshare01", AnimationOptions =
    {
        EmoteLoop = true,
        SyncOffsetFront = 0.6,
    }},
    ["sweetlovef1"] = {"sweetlove_f1@animations", "sweetlove_f1_clip", "Amour Doux Femme 1", "sweetlovem1", AnimationOptions = {
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    }},
    ["sweetlovem1"] = {"sweetlove_m1@animations", "sweetlove_m1_clip", "Amour Doux Homme 1", "sweetlovef1", AnimationOptions = {
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        }
    }},
    ["sweetlovef2"] = {"sweetlove_f2@animations", "sweetlove_f2_clip", "Amour Doux Femme 2", "sweetlovem2", AnimationOptions = {
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    }},
    ["sweetlovem2"] = {"sweetlove_m2@animations", "sweetlove_m2_clip", "Amour Doux Homme 2", "sweetlovef2", AnimationOptions = {
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        }
    }},
    ["sweetlovef3"] = {"sweetlove_f3@animations", "sweetlove_f3_clip", "Amour Doux Femme 3", "sweetlovem3", AnimationOptions = {
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    }},
    ["sweetlovem3"] = {"sweetlove_m3@animations", "sweetlove_m3_clip", "Amour Doux Homme 3", "sweetlovef3", AnimationOptions = {
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        }
    }},
    ["couplelover"] = {"glap@lover-couple-trend", "lover-couple-trend-main", "Tendance qui Tombe 1", "couplelover2", AnimationOptions = {
        EmoteMoving = false,
        EmoteLoop = true,
        Prop = "scrlt_iphone14max_01",
        PropBone = 4170,
        PropPlacement = {-0.03, -0.05, 0.01, -79.64, 5.0, -78.84}
    }},
    ["couplelover2"] = {"glap@lover-couple-trend", "lover-couple-trend-second", "Tendance qui Tombe 2", "couplelover", AnimationOptions = {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        bone = 9816,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0
    }},
    ["assposem"] = {
        "ass@animation",
        "ass_clip",
        "Pose Fesses Femme NOUVEAU",
        "assposef",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["assposef"] = {
        "ass1@animation",
        "ass1_clip",
        "Pose Fesses Homme NOUVEAU",
        "assposem",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.5,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["cuddlelay"] = {
        "tigerle@custom@couple@cuddle@no2a",
        "tigerle_couple_cuddleno2a",
        "Câlin Allongé",
        "cuddlelay2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["cuddlelay2"] = {
        "tigerle@custom@couple@cuddle@no2b",
        "tigerle_couple_cuddleno2b",
        "Câlin Allongé 2",
        "cuddlelay",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["footloveposem"] = {
        "chocoholic@couple63",
        "couple63_clip",
        "Pose d'Amour Sur Le Pied 1 Homme",
        "footloveposef",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["footloveposef"] = {
        "chocoholic@couple64",
        "couple64_clip",
        "Pose d'Amour Sur Le Pied 1 Femme",
        "footloveposem",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.09,
            zPos = 0.48,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["hotsitm"] = {
        "mx@couple1_a",
        "mx@couple1_a_clip",
        "Pose d'Amour Assise Chaude",
        "hotsitf",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["hotsitf"] = {
        "mx@couple1_b",
        "mx@couple1_b_clip",
        "Pose d'Amour Assise Chaude",
        "hotsitm",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.55,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["hotsitm2"] = {
        "mx@couple2_a",
        "mx@couple2_a_clip",
        "Sit Hot Love Pose1",
        "hotsitf2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["hotsitf2"] = {
        "mx@couple2_b",
        "mx@couple2_b_clip",
        "Sit Hot Love Pose2",
        "hotsitm2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.55,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovecrrym"] = {
        "mx@couple4_a",
        "mx@couple4_a_clip",
        "Pose d'Amour Porté 1",
        "lovecrryf",
        AnimationOptions = {
            EmoteMoving = true,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovecrryf"] = {
        "mx@couple4_b",
        "mx@couple4_b_clip",
        "Pose d'Amour Porté 1",
        "lovecrrym",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["kissinglv2m"] = {
        "chocoholic@couple54",
        "couple54_clip",
        "Pose d'Amour Bisou 2 Homme",
        "kissinglv2f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["kissinglv2f"] = {
        "chocoholic@couple53",
        "couple53_clip",
        "Pose d'Amour Bisou 2 Femme",
        "kissinglv2m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.28,
            zPos = -0.08,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 50.0,
        },
        gender = "male"
    },
    ["kissinglvpose4m"] = {
        "chocoholic@couple55",
        "couple55_clip",
        "Pose d'Amour Bisou 4 Homme",
        "kissinglvpose4f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["kissinglvpose4f"] = {
        "chocoholic@couple56",
        "couple56_clip",
        "Pose d'Amour Bisou 4 Femme",
        "kissinglvpose4m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.32,
            zPos = -0.05,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["kissinglvpose2m"] = {
        "wand_pose_01@sharror",
        "wand_pose_01_clip",
        "Bisou Mur Amour 2 Homme",
        "kissinglvpose2f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["kissinglvpose2f"] = {
        "wand_pose_02@sharror",
        "wand_pose_02_clip",
        "Bisou Mur Amour 2 Femme",
        "kissinglvpose2m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.14,
            yPos = -0.2,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["kisslovpose1m"] = {
        "chocoholic@couple51",
        "couple51_clip",
        "Bisou Amour 1 Homme",
        "kisslovpose1f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["kisslovpose1f"] = {
        "chocoholic@couple52",
        "couple52_clip",
        "Bisou Amour 1 Femme",
        "kisslovpose1m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.30,
            zPos = -0.1,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["lovepose4m"] = {
        "anim@male_couple_02",
        "m_couple_02_clip",
        "Pose d'Amour 4 NOUVEAU",
        "lovepose4f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose4f"] = {
        "anim@female_couple_02",
        "f_couple_02_clip",
        "Pose d'Amour 4 NOUVEAU",
        "lovepose4m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.5,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovepose9m"] = {
        "anim@male_couple_04",
        "m_couple_04_clip",
        "Pose d'Amour 9 NOUVEAU",
        "lovepose9f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose9f"] = {
        "anim@female_couple_04",
        "f_couple_04_clip",
        "Pose d'Amour 9 NOUVEAU",
        "lovepose9m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.26,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
            Prop = 'scrlt_iphone14max_07',
            PropBone = 28422,
            PropPlacement = {
                0.1,
                0.03,
                0.0,
                70.0,
                20.0,
                -180.0,
            },
        },
        gender = "male"
    },
    ["lovepose10m"] = {
        "anim@male_couple_05",
        "m_couple_05_clip",
        "Pose d'Amour 10 Homme",
        "lovepose10f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'scrlt_iphone14max_05',
            PropBone = 60309,
            PropPlacement = {
                0.14,
                0.04,
                0.01,
                10.0,
                112.0,
                -180.0,
            },
        },
        gender = "female"
    },
    ["lovepose10f"] = {
        "anim@female_couple_05",
        "f_couple_05_clip",
        "Pose d'Amour 10 Femme",
        "lovepose10m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.9,
            zPos = -0.3,
            xRot = -90.0,
            yRot = 0.0,
            zRot = 0.0,
            Prop = 'scrlt_iphone14max_01',
            PropBone = 60309,
            PropPlacement = {
                0.08,
                0.019,
                0.03,
                30.0,
                98.0,
                -160.0,
            },
        },
        gender = "male"
    },
    ["lovepose11m"] = {
        "anim@male_couple_06",
        "m_couple_06_clip",
        "Pose d'Amour 11 Homme",
        "lovepose11f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose11f"] = {
        "anim@female_couple_06",
        "f_couple_06_clip",
        "Pose d'Amour 11 Femme",
        "lovepose11m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.62,
            zPos = -0.14,
            xRot = -50.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovepose12m"] = {
        "anim@male_couple_07",
        "m_couple_07_clip",
        "Pose d'Amour 12 Homme",
        "lovepose12f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose12f"] = {
        "anim@female_couple_07",
        "f_couple_07_clip",
        "Pose d'Amour 12 Femme",
        "lovepose12m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.72,
            zPos = 0.1,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
            Prop = 'scrlt_iphone14max_07',
            PropBone = 6286,
            PropPlacement = {
                0.12,
                0.016,
                -0.034,
                0.0,
                90.0,
                -180.0,
            },
        },
        gender = "male"
    },
    ["lovepose13m"] = {
        "myu@fm_couple2_2",
        "fm_couple2_m_clip",
        "Pose d'Amour 13 Homme",
        "lovepose13f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose13f"] = {
        "myu@fm_couple2_1",
        "fm_couple2_f_clip",
        "Pose d'Amour 13 Femme",
        "lovepose13m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.56,
            yPos = 0.1,
            zPos = -0.15,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 95.0,
        },
        gender = "male"
    },
    ["lovepose14m"] = {
        "m_engagement@d3vilros3",
        "m_engagement_clip",
        "Pose d'Amour 14 Homme",
        "lovepose14f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose14f"] = {
        "f_engagement@d3vilros3",
        "f_engagement_clip",
        "Pose d'Amour 14 Femme",
        "lovepose14m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.1,
            yPos = 0.32,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 189.0,
        },
        gender = "male"
    },
    ["lovepose15m"] = {
        "mx@couple6_2_a",
        "mx@couple6_2_a_clip",
        "Pose d'Amour 15 Homme",
        "lovepose15f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose15f"] = {
        "mx@couple6_2_b",
        "mx@couple6_2_b_clip",
        "Pose d'Amour 15 Femme",
        "lovepose15m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.12,
            yPos = 0.3,
            zPos = -0.1,
            xRot = 28.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovepose16m"] = {
        "mx@couple6_3_a",
        "mx@couple6_3_a_clip",
        "Pose d'Amour 16 Homme",
        "lovepose16f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose16f"] = {
        "mx@couple6_3_b",
        "mx@couple6_3_b_clip",
        "Pose d'Amour 16 Femme",
        "lovepose16m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.52,
            yPos = 0.25,
            zPos = 0.05,
            xRot = 13.5,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovepose17m"] = {
        "mx@pack4.1_a",
        "mx@pack4.1_a_clip",
        "Pose d'Amour 17 Homme",
        "lovepose17f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose17f"] = {
        "mx@pack4.1_b",
        "mx@pack4.1_b_clip",
        "Pose d'Amour 17 Femme",
        "lovepose17m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.52,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovepose18m"] = {
        "mx@couple4.2_a",
        "mx@couple4.2_a_clip",
        "Pose d'Amour 18 Homme",
        "lovepose18f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose18f"] = {
        "mx@couple4.2_b",
        "mx@couple4.2_b_clip",
        "Pose d'Amour 18 Femme",
        "lovepose18m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.31,
            zPos = -0.02,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["lovepose19m"] = {
        "mx@couple4.3_a",
        "mx@couple4.3_a_clip",
        "Pose d'Amour 19 Homme",
        "lovepose19f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose19f"] = {
        "mx@couple4.3_b",
        "mx@couple4.3_b_clip",
        "Pose d'Amour 19 Femme",
        "lovepose19m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.48,
            yPos = 0.02,
            zPos = -0.02,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 152.0,
        },
        gender = "male"
    },
    ["lovepose20m"] = {
        "mx@couple4.4_a",
        "mx@couple4.4_a_clip",
        "Pose d'Amour 20 Homme",
        "lovepose20f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose20f"] = {
        "mx@couple4.4_b",
        "mx@couple4.4_b_clip",
        "Pose d'Amour 20 Femme",
        "lovepose20m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 1.47,
            zPos = 0.7,
            xRot = 0.1,
            yRot = 0.5,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["lovepose21m"] = {
        "mx@couple4.5_a",
        "mx@couple4.5_a_clip",
        "Pose d'Amour 21 Homme",
        "lovepose21f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose21f"] = {
        "mx@couple4.5_b",
        "mx@couple4.5_b_clip",
        "Pose d'Amour 21 Femme",
        "lovepose21m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.3,
            zPos = 0.16,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["lovepose22m"] = {
        "couplemale_leancar@joker",
        "couplemale_leancar_clip",
        "Pose d'Amour 21 Homme",
        "lovepose22f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["lovepose22f"] = {
        "couplefemale_leancar@joker",
        "couplefemale_leancar_clip",
        "Pose d'Amour 21 Femme",
        "lovepose22m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.2,
            yPos = 0.32,
            zPos = 0.1,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 180.0,
        },
        gender = "male"
    },
    ["sidebysm"] = {
        "banner_01@sharror",
        "banner_01_clip",
        "Pose Côte à Côte Homme",
        "sidebysf",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sidebysf"] = {
        "banner_02@sharror",
        "banner_02_clip",
        "Pose Côte à Côte Femme",
        "sidebysm",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.48,
            yPos = -0.1,
            zPos = 0.0,
            xRot = 2.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitchrlv2m"] = {
        "benchm@spider",
        "benchm_clip",
        "Assis Chaise Amour 2 Homme",
        "sitchrlv2f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sitchrlv2f"] = {
        "benchf@spider",
        "benchf_clip",
        "Assis Chaise Amour 2 Femme",
        "sitchrlv2m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.39,
            zPos = 0.36,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitchairlove3m"] = {
        "chocoholic@couple47_v3",
        "couple47_v3_clip",
        "Assis Chaise Amour 3 Homme",
        "sitchairlove3f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sitchairlove3f"] = {
        "chocoholic@couple48_v3",
        "couple48_v3_clip",
        "Assis Chaise Amour 3 Femme",
        "sitchairlove3m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.85,
            zPos = 0.3,
            xRot = -5.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitlovepose6m"] = {
        "schoko7@sharror",
        "schoko7_clip",
        "Pose d'Amour Assise 6 Homme",
        "sitlovepose6f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sitlovepose6f"] = {
        "schoko8@sharror",
        "schoko8_clip",
        "Pose d'Amour Assise 6 Femme",
        "sitlovepose6m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.0,
            zPos = 0.7,
            xRot = -7.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitlovepose7m"] = {
        "couplem4@spider",
        "couplem4_clip",
        "Pose d'Amour Assise 7 Homme",
        "sitlovepose7f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            bone = 0,
            zPos = -5.0,
        },
        gender = "female"
    },
    ["sitlovepose7f"] = {
        "couple4@spider",
        "couple4_clip",
        "Pose d'Amour Assise 7 Femme",
        "sitlovepose7m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.55,
            zPos = 0.38,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitlovepose8m"] = {
        "couplebench_m@gengaranimation",
        "couplebench_m_clip",
        "Pose d'Amour Assise 8 Homme",
        "sitlovepose8f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sitlovepose8f"] = {
        "couplebench_f@gengaranimation",
        "couplebench_f_clip",
        "Pose d'Amour Assise 8 Femme",
        "sitlovepose8m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -1.45,
            yPos = 0.81,
            zPos = 0.35,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitlovepose9m"] = {
        "anim@male_couple_01",
        "m_couple_01_clip",
        "Pose d'Amour Assise 9 Homme",
        "sitlovepose9f",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sitlovepose9f"] = {
        "anim@female_couple_01",
        "f_couple_01_clip",
        "Pose d'Amour Assise 9 Femme",
        "sitlovepose9m",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = 0.0,
            yPos = 0.47,
            zPos = 0.8,
            xRot = -15.0,
            yRot = 0.0,
            zRot = 0.0,
        },
        gender = "male"
    },
    ["sitposem"] = {
        "coupleshoulderm@sarahdiehexe",
        "coupleshoulderm_clip NEW",
        "Pose Assise Homme",
        "sitposef",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
        },
        gender = "female"
    },
    ["sitposef"] = {
        "coupleshoulderf@sarahdiehexe",
        "coupleshoulderf_clip",
        "Pose Assise Femme",
        "sitposem",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            Attachto = true,
            bone = 0,
            xPos = -0.6,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0
        },
        gender = "male"
    },
    ["nsex"] = {
        "zmdev@erotica_missionarym",
        "missionarym",
        "Missionnaire Homme",
        "nsex2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            bone = 0,
            xPos = 0.08,
            yPos = 0.02,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,

        }
    },
    ["nsex2"] = {
        "zmdev@erotica_missionaryf",
        "missionaryf",
        "Missionnaire Femme",
        "nsex",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex3"] = {
        "zmdev@erotica_missionary2m",
        "missionary2m",
        "Missionnaire Homme 2",
        "nsex4",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = 0.09,
            yPos = 0.02,
            zPos = 0.02,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,

        }
    },
    ["nsex4"] = {
        "zmdev@erotica_missionary2f",
        "missionary2f",
        "Missionnaire Femme 2",
        "nsex3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex5"] = {
        "zmdev@erotica_doggystylem",
        "doggystylem",
        "Levrette Homme",
        "nsex6",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = -0.35,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["nsex6"] = {
        "zmdev@erotica_doggystylef",
        "doggystylef",
        "Levrette Femme",
        "nsex5",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex7"] = {
        "zmdev@erotica_doggystyle2m",
        "doggystyle2m",
        "Levrette Homme 2",
        "nsex8",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = -0.39,
            yPos = 0.0,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,

        }
    },
    ["nsex8"] = {
        "zmdev@erotica_doggystyle2f",
        "doggystyle2f",
        "Levrette Femme 2",
        "nsex7",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex9"] = {
        "zmdev@erotica_cowgirlm",
        "cowgirlm",
        "Cavalière Homme",
        "nsex10",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = 0.0,
            yPos = 0.05,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["nsex10"] = {
        "zmdev@erotica_cowgirlf",
        "cowgirlf",
        "Cavalière Femme",
        "nsex9",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex11"] = {
        "zmdev@erotica_spooningm",
        "spooningm",
        "Cuillère Homme",
        "nsex12",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = -0.09,
            yPos = -0.20,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,

        }
    },
    ["nsex12"] = {
        "zmdev@erotica_spooningf",
        "spooningf",
        "Cuillère Femme",
        "nsex11",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex13"] = {
        "zmdev@erotica_standingcowgirlm",
        "standingcowgirlm",
        "Cavalière Debout Homme",
        "nsex14",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = -0.30,
            yPos = 0.0,
            zPos = 0.05,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }
    },
    ["nsex14"] = {
        "zmdev@erotica_standingcowgirlf",
        "standingcowgirlf",
        "Cavalière Debout Femme",
        "nsex13",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }
    },
    ["nsex15"] = {
        "zmdev@erotica_standingm",
        "standingm",
        "Sur Le Mur Homme",
        "nsex16",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true,
            Attachto = true,
            --bone = 0,
            xPos = -0.35,
            yPos = 0.02,
            zPos = 0.0,
            xRot = 0.0,
            yRot = 0.0,
            zRot = 0.0,
        }},
    ["nsex16"] = {
        "zmdev@erotica_standingf",
        "standingf",
        "Sur Le Mur Femme",
        "nsex15",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        }},
    ["followa"] = { -- Custom Ped In Front Emote By Dollie Mods
        "dollie_mods@follow_me_001",
        "follow_me_001",
        "Suivre A (Devant)",
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
        "Suivre B (Derrière)",
        "followa",
        AnimationOptions = {
            EmoteLoop = true,
            Attachto = true,
            xPos = 0.078,
            yPos = 0.018,
            zPos = 0.00,
            xRot = 0.00,
            yRot = 0.00,
            zRot = 0.00,
        }
    },
    ["propose001a"] = { -- Custom Emote By Dollie Mods
        "dollie_mods@propose_001a",
        "propose_001a",
        "Demande en Mariage A1",
        "propose001b",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["propose001b"] = { -- Custom Emote By Dollie Mods
        "dollie_mods@propose_001b",
        "propose_001b",
        "Demande en Mariage A2",
        "propose001a",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["propose002a"] = { -- Custom Emote By Dollie Mods
        "dollie_mods@propose_002a",
        "propose_002a",
        "Demande en Mariage B1",
        "propose002b",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["propose002b"] = { -- Custom Emote By Dollie Mods
        "dollie_mods@propose_002b",
        "propose_002b",
        "Demande en Mariage B2",
        "propose002a",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["propose003a"] = { -- Custom Emote By Dollie Mods
        "dollie_mods@propose_003b",
        "propose_003b",
        "Demande en Mariage Couple (Homme)",
        "propose003b",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["propose003b"] = { -- Custom Emote By Dollie Mods
        "dollie_mods@propose_003a",
        "propose_003a",
        "Demande en Mariage Couple (Femme)",
        "propose003a",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["drhug3"] = {"misscarsteal2chad_goodbye", "chad_idle_chad", "Câlin Romantique 3", "hr4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        SyncOffsetFront = 0.70,
        SyncOffsetX = -0.15
    }},
    ["drhug4"] = {"misscarsteal2chad_goodbye", "chad_idle_girl", "Câlin Romantique 4", "hr3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        SyncOffsetFront = 0.70,
        SyncOffsetX = -0.15
    }},
    ["couple"] = {"LLShop@couple_1", "llshop_clip", "Couple", "couple2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = 1.1,  --Links Rechts
        yPos = 0.0,  --- Vorne Hinten
        zPos = 0.0,   -- Höhe
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["couple2"] = {"LLShop@couple_2", "llshop_clip", "Couple 2", "couple", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = -1.1,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["cuddle"] = {"tigerle@custom@couple@cuddle1a", "tigerle_couple_cuddle1a", "Câlin", "cuddle2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["cuddle2"] = {"tigerle@custom@couple@cuddle1b", "tigerle_couple_cuddle1b", "Câlin 2", "cuddle", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        bone = 0,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["cuddlenew1"] = {"cuddlepartner1@pawuk", "cuddlepartner1_clip", "Câlin Nouveau 1", "cuddlenew2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["cuddlenew2"] = {"cuddlepartner2@pawuk", "cuddlepartner2_clip", "Câlin Nouveau 2", "cuddlenew1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Attachto = true,
        bone = 0,
        xPos = 0.0,
        yPos = 0.33,
        zPos = 0.0,
        xRot = 180.0,
        yRot = 0.0,
        zRot = 180.0,
    }},
    ["kissing"] = {"tigerle@custom@couple@kissing1a", "tigerle_couple_kissing1a", "Bisou", "kissing2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        -- Attachto = true,
        -- xPos = 0.0,
        -- yPos = 0.0,
        -- zPos = 0.0,
        -- xRot = 0.0,
        -- yRot = 0.0,
        -- zRot = 0.0,
    }},
    ["kissing2"] = {"tigerle@custom@couple@kissing1b", "tigerle_couple_kissing1b", "Bisou 2", "kissing", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        bone = 0,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["kissing3"] = {"tigerle@custom@couple@kissing2a", "tigerle_couple_kissing2a", "Bisou 3", "kissing4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["kissing4"] = {"tigerle@custom@couple@kissing2b", "tigerle_couple_kissing2b", "Bisou 4", "kissing3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0,
    }},
    ["laying"] = {"tigerle@custom@couple@laying1a", "tigerle_couple_laying1a", "Allongé", "laying2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        SyncOffsetFront = 0.5,
        SyncOffsetSide = 0.0,
        SyncOffsetHeight = 0.0,
        SyncOffsetHeading = 0.0,
    }},
    ["laying2"] = {"tigerle@custom@couple@laying1b", "tigerle_couple_laying1b", "Allongé 2", "laying", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        SyncOffsetFront = 0.5,
        SyncOffsetSide = 0.0,
        SyncOffsetHeight = 0.0,
        SyncOffsetHeading = 0.0,
    }},
    ["standingcuddle"] = {"tigerle@custom@couple@standcuddle_a", "tigerle_couple_standcuddle_a", "Câlin Debout", "standingcuddle2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = 0.0,
        yPos = 0.35,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 180.0,
    }},
    ["standingcuddle2"] = {"tigerle@custom@couple@standcuddle_b", "tigerle_couple_standcuddle_b", "Câlin Debout 2", "standingcuddle", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        xPos = 0.0,
        yPos = 0.35,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 180.0,
    }},
    ["gsoyou1"] = {"glap@some-soyou-junggigo", "some-soyou-junggigo-left", "Some - Soyou 'Some - Soyou & Junggigo Left', Junggigo Gauche", "gsoyou2", AnimationOptions = {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gsoyou2"] = {"glap@some-soyou-junggigo", "some-soyou-junggigo-right", "Some - Soyou 'Some - Soyou & Junggigo Right', Junggigo Droite", "gsoyou1", AnimationOptions = {
        EmoteMoving = false,
        EmoteLoop = true,
        Attachto = true,
        bone = 9816,
        xPos = 0.0,
        yPos = 0.0,
        zPos = 0.0,
        xRot = 0.0,
        yRot = 0.0,
        zRot = 0.0
    }},
}
CustomDP.Dances = {
    ["armswirl"] = {
        "custom@armswirl",
        "armswirl",
        "Tourbillon de bras",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["armwave"] = {
        "custom@armwave",
        "armwave",
        "Vague des bras",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["bellydance"] = {
        "custom@bellydance",
        "bellydance",
        "Danse du ventre",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["electroshuffle"] = {
        "custom@electroshuffle",
        "electroshuffle",
        "Dance LMFAO",
        AnimationOptions = { EmoteLoop = true }
    },
    ["floss"] = {
        "custom@floss",
        "floss",
        "Dance Floss",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hiphopslide"] = {
        "custom@hiphop_slide",
        "hiphop_slide",
        "Slide HipHop",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["hiphop1"] = {
        "custom@hiphop1",
        "hiphop1",
        "HipHop 1",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["hiphop2"] = {
        "custom@hiphop2",
        "hiphop2",
        "HipHop 2",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["hiphop3"] = {
        "custom@hiphop3",
        "hiphop3",
        "HipHop 3",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = false }
    },
    ["hiphopold"] = {
        "custom@hiphop90s",
        "hiphop90s",
        "HipHop Vieux",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["woowalk"] = {
        "div@woowalk@test",
        "woowalk",
        "Marche à pied Woo",
        AnimationOptions = { EmoteLoop = true }
    },
    ["drilldance"] = {
        "div@woowalk@test",
        "drilldance",
        "Dance Drill 1",
        AnimationOptions = { EmoteLoop = true }
    },
    ["cripwalk2"] = {
        "div@woowalk@test",
        "cripwalk2",
        "Marche de Crip",
        AnimationOptions = { EmoteLoop = true }
    },
    ["sturdy2"] = {
        "div@woowalk@test",
        "sturdy2",
        "Devenez robuste",
        AnimationOptions = { EmoteLoop = true }
    },
    ["bloodwalk2"] = {
        "div@woowalk@test",
        "bloodwalk2",
        "Faire des claquettes",
        AnimationOptions = { EmoteLoop = true }
    },
    ["blixkytwirl2"] = {
        "div@woowalk@test",
        "blixkytwirl2",
        "Tourbillon Blixky",
        AnimationOptions = { EmoteLoop = true }
    },

    -- Custom Dances: Ultra
    ["breakdance"] = {
        "export@breakdance",
        "breakdance",
        "Faire le robot",
        AnimationOptions = { EmoteLoop = true }
    },
    ["gangnamstyle"] = {
        "custom@gangnamstyle",
        "gangnamstyle",
        "Gangnam Style",
        AnimationOptions = { EmoteLoop = true }
    },
    ["macarena"] = {
        "custom@makarena",
        "makarena",
        "Macarena",
        AnimationOptions = { EmoteLoop = true }
    },
    ["maraschino"] = {
        "custom@maraschino",
        "maraschino",
        "Maraschino",
        AnimationOptions = { EmoteLoop = true }
    },
    ["salsa1"] = {
        "custom@salsa",
        "salsa",
        "Salsa",
        AnimationOptions = { EmoteLoop = true }
    },

    -- Custom Dances: Divine
    ["ddance1"] = {
        "divined@dances@new",
        "ddance1",
        "La danse divine D 1",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance2"] = {
        "divined@dances@new",
        "ddance2",
        "La danse divine D 6",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance3"] = {
        "divined@dances@new",
        "ddance3",
        "La danse divine D 7",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance4"] = {
        "divined@dances@new",
        "ddance4",
        "La danse divine D 8",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance5"] = {
        "divined@dances@new",
        "ddance5",
        "La danse divine D 9",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance6"] = {
        "divined@dances@new",
        "ddance6",
        "La danse divine D 10",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance7"] = {
        "divined@dances@new",
        "ddance7",
        "La danse divine D 11",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance8"] = {
        "divined@dances@new",
        "ddance8",
        "La danse divine D 12",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance9"] = {
        "divined@dances@new",
        "ddance9",
        "La danse divine D 13",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance10"] = {
        "divined@dances@new",
        "ddance10",
        "La danse divine D 2",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance11"] = {
        "divined@dances@new",
        "ddance11",
        "La danse divine D 3",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance12"] = {
        "divined@dances@new",
        "ddance12",
        "La danse divine D 4",
        AnimationOptions = { EmoteLoop = true }
    },
    ["ddance13"] = {
        "divined@dances@new",
        "ddance13",
        "La danse divine D 5",
        AnimationOptions = { EmoteLoop = true }
    },

    -- Version Two
    ["divdance1"] = {
        "divined@dancesv2@new",
        "divdance1",
        "Dance Custom 1",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance2"] = {
        "divined@dancesv2@new",
        "divdance2",
        "Dance Custom 7",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance3"] = {
        "divined@dancesv2@new",
        "divdance3",
        "Dance Custom 8",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance4"] = {
        "divined@dancesv2@new",
        "divdance4",
        "Dance Custom 9",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance5"] = {
        "divined@dancesv2@new",
        "divdance5",
        "Dance Custom 10",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance6"] = {
        "divined@dancesv2@new",
        "divdance6",
        "Dance Custom 11",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance7"] = {
        "divined@dancesv2@new",
        "divdance7",
        "Dance Custom 12",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance8"] = {
        "divined@dancesv2@new",
        "divdance8",
        "Dance Custom 13",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance9"] = {
        "divined@dancesv2@new",
        "divdance9",
        "Dance Custom 14",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance10"] = {
        "divined@dancesv2@new",
        "divdance10",
        "Dance Custom 2",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance11"] = {
        "divined@dancesv2@new",
        "divdance11",
        "Dance Custom 3",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance12"] = {
        "divined@dancesv2@new",
        "divdance12",
        "Dance Custom 4",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance13"] = {
        "divined@dancesv2@new",
        "divdance13",
        "Dance Custom 5",
        AnimationOptions = { EmoteLoop = true }
    },
    ["divdance14"] = {
        "divined@dancesv2@new",
        "divdance14",
        "Dance Custom 6",
        AnimationOptions = { EmoteLoop = true }
    },
    -- Divine Breakdance
    ["divbdance1"] = {
        "divined@breakdances@new",
        "divbdance1",
        "Break Dance divisée 1",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance2"] = {
        "divined@breakdances@new",
        "divbdance2",
        "Break Dance divisée 8",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance3"] = {
        "divined@breakdances@new",
        "divbdance3",
        "Break Dance divisée 9",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance4"] = {
        "divined@breakdances@new",
        "divbdance4",
        "Break Dance divisée 10",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance5"] = {
        "divined@breakdances@new",
        "divbdance5",
        "Break Dance divisée 11",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance6"] = {
        "divined@breakdances@new",
        "divbdance6",
        "Break Dance divisée 12",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance7"] = {
        "divined@breakdances@new",
        "divbdance7",
        "Break Dance divisée 13",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance8"] = {
        "divined@breakdances@new",
        "divbdance8",
        "Break Dance divisée 14",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance9"] = {
        "divined@breakdances@new",
        "divbdance9",
        "Break Dance divisée 15",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance10"] = {
        "divined@breakdances@new",
        "divbdance10",
        "Break Dance divisée 2",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance11"] = {
        "divined@breakdances@new",
        "divbdance11",
        "Break Dance divisée 3",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance12"] = {
        "divined@breakdances@new",
        "divbdance12",
        "Break Dance divisée 4",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance13"] = {
        "divined@breakdances@new",
        "divbdance13",
        "Break Dance divisée 5",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance14"] = {
        "divined@breakdances@new",
        "divbdance14",
        "Break Dance divisée 6",
        AnimationOptions = { EmoteLoop = false }
    },
    ["divbdance15"] = {
        "divined@breakdances@new",
        "divbdance14",
        "Break Dance divisée 7",
        AnimationOptions = { EmoteLoop = false }
    },
    ["sturdy"] = {
        "nito_sturdy18@animation",
        "nito_sturdy18_clip",
        "Danse vigoureuse",
        AnimationOptions = { EmoteLoop = true }
    },

    -- Divine Breakdance v3
    ["dbrdance1"] = {
        "divined@brdancesv2@new",
        "dbrdance1",
        "La danse divine 1",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance2"] = {
        "divined@brdancesv2@new",
        "dbrdance2",
        "La danse divine 5",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance3"] = {
        "divined@brdancesv2@new",
        "dbrdance3",
        "La danse divine 6",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance4"] = {
        "divined@brdancesv2@new",
        "dbrdance4",
        "La danse divine 7",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance5"] = {
        "divined@brdancesv2@new",
        "dbrdance5",
        "La danse divine 8",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance6"] = {
        "divined@brdancesv2@new",
        "dbrdance6",
        "La danse divine 9",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance7"] = {
        "divined@brdancesv2@new",
        "dbrdance7",
        "La danse divine 10",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance8"] = {
        "divined@brdancesv2@new",
        "dbrdance8",
        "La danse divine 11",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance9"] = {
        "divined@brdancesv2@new",
        "dbrdance9",
        "La danse divine 12",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance10"] = {
        "divined@brdancesv2@new",
        "dbrdance10",
        "La danse divine 2",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance11"] = {
        "divined@brdancesv2@new",
        "dbrdance11",
        "La danse divine 3",
        AnimationOptions = { EmoteLoop = false }
    },
    ["dbrdance12"] = {
        "divined@brdancesv2@new",
        "dbrdance12",
        "La danse divine 4",
        AnimationOptions = { EmoteLoop = false }
    },

    -- Divine: Trendy
    ["banddance"] = {
        "divined@tdances@new",
        "dtdance1",
        "Danse de groupe",
        AnimationOptions = { EmoteLoop = true }
    },
    ["bopdance"] = {
        "divined@tdances@new",
        "dtdance2",
        "Bop",
        AnimationOptions = { EmoteLoop = true }
    },
    ["bboydance"] = {
        "divined@tdances@new",
        "dtdance3",
        "Faire du breakdance",
        AnimationOptions = { EmoteLoop = true }
    },
    ["capoeiramove"] = {
        "divined@tdances@new",
        "dtdance4",
        "Mouvement de Capoeira",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hiphopdance"] = {
        "divined@tdances@new",
        "dtdance5",
        "Danse hip-hop",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hipsterdance"] = {
        "divined@tdances@new",
        "dtdance6",
        "Danse hipster",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hippiedance"] = {
        "divined@tdances@new",
        "dtdance7",
        "Danse hippie",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hiphoptaunt"] = {
        "divined@tdances@new",
        "dtdance8",
        "Taunt Hip Hop",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hilowave"] = {
        "divined@tdances@new",
        "dtdance9",
        "Vague Hi Lo",
        AnimationOptions = { EmoteLoop = true }
    },
    ["squaredance"] = {
        "divined@tdances@new",
        "dtdance10",
        "Danse carrée",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hotdance"] = {
        "divined@tdances@new",
        "dtdance11",
        "Danse chaude",
        AnimationOptions = { EmoteLoop = true }
    },
    ["hulahula"] = {
        "divined@tdances@new",
        "dtdance12",
        "Hula-Hula",
        AnimationOptions = { EmoteLoop = true }
    },
    ["dabloop"] = {
        "divined@tdances@new",
        "dtdance13",
        "Faire le dab infini",
        AnimationOptions = { EmoteLoop = true }
    },
    ["kingdance"] = {
        "divined@tdances@new",
        "dtdance14",
        "La danse du roi",
        AnimationOptions = { EmoteLoop = true }
    },
    ["linedance"] = {
        "divined@tdances@new",
        "dtdance15",
        "Ligne de danse",
        AnimationOptions = { EmoteLoop = true }
    },
    ["magicman"] = {
        "divined@tdances@new",
        "dtdance16",
        "L'homme magique",
        AnimationOptions = { EmoteLoop = true }
    },
    ["marat"] = {
        "divined@tdances@new",
        "dtdance17",
        "Marat",
        AnimationOptions = { EmoteLoop = true }
    },
    ["maskoff"] = {
        "divined@tdances@new",
        "dtdance18",
        "Mask Off",
        AnimationOptions = { EmoteLoop = true }
    },
    ["mellow"] = {
        "divined@tdances@new",
        "dtdance19",
        "Mellow",
        AnimationOptions = { EmoteLoop = true }
    },
    ["showroomdance"] = {
        "divined@tdances@new",
        "dtdance20",
        "Danse de salon",
        AnimationOptions = { EmoteLoop = true }
    },
    ["windmillfloss"] = {
        "divined@tdances@new",
        "dtdance21",
        "Fil à vent",
        AnimationOptions = { EmoteLoop = true }
    },
    ["woahdance"] = {
        "divined@tdances@new",
        "dtdance22",
        "Woah",
        AnimationOptions = { EmoteLoop = true }
    },
    --NEW DANCES ADDED LEO - DANCE

    ["kkchima"] = {
        "kkchimadance@animation",
        "kkchima_clip",
        "Danse Kkchima",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["pakudahlupa"] = {
        "pazeee@akudahlupa@animations",
        "pazeee@akudahlupa@clip",
        "Danse Aku Dah Lupa",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pvelocitya"] = {
        "pazeee@velocity@a@animations",
        "pazeee@velocity@a@clip",
        "Danse Velocity A",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pvelocityb"] = {
        "pazeee@velocity@b@animations",
        "pazeee@velocity@b@clip",
        "Danse Velocity B",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pvelocityc"] = {
        "pazeee@velocity@c@animations",
        "pazeee@velocity@c@clip",
        "Danse Velocity C",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["kendricklamarwalk"] = {
        "kendricklamarwalk@animation",
        "kendricklamarwalk_clip",
        "Marche Kendrick Lamar Not Like Us",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["jaden"] = {
        "jadendance@animation",
        "jaden_clip",
        "Danse Jaden",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["pfstarlit"] = {
        "pazeeefortnitestarlit@animations",
        "pazeeefortnitestarlitclip",
        "Starlit",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfboneybounce"] = {
        "pazeeefortniteboneybounce@animations",
        "pazeeefortniteboneybounceclip",
        "Rebond Osseux",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfevilplan"] = {
        "pazeeefortniteevilplan@animations",
        "pazeeefortniteevilplanclip",
        "Plan Diabolique",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfdancindomino"] = {
        "pazeeefortnitedancindomino@animations",
        "pazeeefortnitedancindominoclip",
        "Domino Dansant",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfpointandstrut"] = {
        "pazeeefortnitepointandstrut@animations",
        "pazeeefortnitepointandstrutclip",
        "Pointer et Se Pavaner",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfthedancelaroi"] = {
        "pazeeefortnitethedancelaroi@animations",
        "pazeeefortnitethedancelaroiclip",
        "La Danse Laroi",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfcopines"] = {
        "pazeeefortnitecopines@animations",
        "pazeeefortnitecopinesclip",
        "Copines",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfmikubeam"] = {
        "pazeeefortnitemikubeam@animations",
        "pazeeefortnitemikubeamclip",
        "Rayon Miku Miku",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfitstrue"] = {
        "pazeeefortniteitstrue@animations",
        "pazeeefortniteitstrueclip",
        "C'est Vrai",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfimout"] = {
        "pazeeefortniteimout@animations",
        "pazeeefortniteimoutclip",
        "Je Sors",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfscenario"] = {
        "pazeeefortnitescenario@animations",
        "pazeeefortnitescenarioclip",
        "Scenario",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfjabbaswitchway"] = {
        "pazeeefortnitejabbaswitchway@animations",
        "pazeeefortnitejabbaswitchwayclip",
        "Jabba Chemin Alternatif",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfgomufasa"] = {
        "pazeeefortnitegomufasa@animations",
        "pazeeefortnitegomufasaclip",
        "Go Mufasa",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfgomufasamove"] = {
        "pazeeefortnitegomufasamove@animations",
        "pazeeefortnitegomufasamoveclip",
        "Mouvement Go Mufasa",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfeverybodylovesme"] = {
        "pazeeefortniteeverybodylovesme@animations",
        "pazeeefortniteeverybodylovesmeclip",
        "Tout Le Monde M'Aime",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfgetgriddy"] = {
        "pazeeefortnitegetgriddy@animations",
        "pazeeefortnitegetgriddyclip",
        "Devenir Griddy",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfgetgriddymove"] = {
        "pazeeefortnitegetgriddymove@animations",
        "pazeeefortnitegetgriddymoveclip",
        "Mouvement Griddy",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pflofiheadbang"] = {
        "pazeeefortnitelofiheadbang@animations",
        "pazeeefortnitelofiheadbangclip",
        "Headbang Lo-Fi",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfrebellious"] = {
        "pazeeefortniterebellious@animations",
        "pazeeefortniterebelliousclip",
        "Rebellious",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfbackon74"] = {
        "pazeeefortnitebackon74@animations",
        "pazeeefortnitebackon74clip",
        "Retour Sur 74",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pfbackon74move"] = {
        "pazeeefortnitebackon74move@animations",
        "pazeeefortnitebackon74moveclip",
        "Mouvement Retour Sur 74",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["zerotwo"] = {
        "puthon@santorostore",
        "puthon_santorostore",
        "Zero Two",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["pparjamban1"] = {
        "pazeeeparjamban1@animations",
        "pazeeeparjamban1clip",
        "Émote Parjamban",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pparjamban2"] = {
        "pazeeeparjamban2@animations",
        "pazeeeparjamban2clip",
        "Danse Parjamban",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["flytotokyo"] = {"pfflytotokyo@animations", "pfflytotokyoclip", "Voler Vers Tokyo", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["attraction"] = {"pfattraction@animations", "pfattractionclip", "Attraction", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["luciddreams"] = {"pfluciddreams@animations", "pfluciddreamsclip", "Rêves Lucides", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["skeledance"] = {"pfskeledance@animations", "pfskeledanceclip", "Danse Squelette", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["theviper"] = {"pftheviper@animations", "pftheviperclip", "La Vipère", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["gethot"] = {"pfgethot@animations", "pfgethotclip", "Devenir Chaud", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emptyoutyourpockets"] = {"pfemptyoutyourpockets@animations", "pfemptyoutyourpocketsclip", "Vider Vos Poches", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["rapmonster"] = {"pfrapmonster@animations", "pfrapmonsterclip", "Rap Monster", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["nuthinbutagthang"] = {"pfnuthinbutagthang@animations", "pfnuthinbutagthangclip", "Rien Qu'un Truc de G", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["coffin"] = {"pfcoffin@animations", "pfcoffinclip", "Coffin", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["coffinmove"] = {"pfcoffinmove@animations", "pfcoffinmoveclip", "Mouvement Cercueil", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["californialove"] = {"pfcalifornialove@animations", "pfcalifornialoveclip", "Amour de Californie", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["byebyebye"] = {"pfbyebyebye@animations", "pfbyebyebyeclip", "Au Revoir Au Revoir Au Revoir", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["soarabove"] = {"pfsoarabove@animations", "pfsoaraboveclip", "S'Élever Au-Dessus", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["alliwantforchristmas"] = {"pfalliwantforchristmas@animations", "pfalliwantforchristmasclip", "Tout Ce Que Je Veux Pour Noël", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["riches"] = {"pfriches@animations", "pfrichesclip", "Riches", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["desirable"] = {"pfdesirable@animations", "pfdesirableclip", "Desirable", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["takeitslow"] = {"pftakeitslow@animations", "pftakeitslowclip", "Prendre Son Temps", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["thedog"] = {"pfthedog@animations", "pfthedogclip", "Le Chien", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["snoopswalk"] = {"pfsnoopswalk@animations", "pfsnoopswalkclip", "Marche de Snoop", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["rhythmofchaos"] = {"pfrhythmofchaos@animations", "pfrhythmofchaosclip", "Rythme du Chaos", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["moongazer"] = {"pfmoongazer@animations", "pfmoongazerclip", "Moongazer", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["caffeinated"] = {"pfcaffeinated@animations", "pfcaffeinatedclip", "Caffeinated", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["caffeinatedold"] = {"pfcaffeinatedold@animations", "pfcaffeinatedoldclip", "Caféiné Ancien", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["committed"] = {"pfcommitted@animations", "pfcommittedclip", "Committed", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["dimensional"] = {"pfdimensional@animations", "pfdimensionalclip", "Dimensional", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["kdapopstars"] = {"pkdapopstars@animations", "pkdapopstarsclip", "Danse KDA Pop Stars LOL", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["waitudance"] = {"waitdance@animations", "waitdanceclip", "Danse d'Attente", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["ishowspeedcrispeyspraydance"] = {"ishowspeedcrispeyspraydance@animations", "ishowspeedcrispeyspraydanceclip", "Danse Spray Speed", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["sadbordance2"] = {"psadbor2@animations", "psadbor2clip", "Danse SadBor 2", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["sadbordance"] = {"psadbor1@animations", "psadbor1clip", "Danse SadBor", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["njddance"] = {"njditto@animations", "njdittoclip", "Danse New Jeans Ditto", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["sagedance"] = {"segadance@animations", "segadance_clip", "Danse Sage", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["donaldtrump2"] = {"ptrumpsup@animations", "ptrumpsupclip", "Danse Donald Trump 2", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["donaldtrump1"] = {"ptrump@animations", "ptrumpclip", "Danse Donald Trump", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["cr7siu"] = {"cr7siu@animations", "cr7siu_clip", "CR7 SIU", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["moodengcrazytwerk"] = {"glap@moodeng-crazy-twerk", "moodeng-crazy-twerk", "Twerk Fou Moodeng", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["underthesea"] = {"glap@under-the-sea", "under-the-sea", "Sous La Mer", AnimationOptions =
    {
        Prop = "p_cs_scissors_s",
        PropBone = 18905,
        PropPlacement = {0.08, 0.0, 0.01, 0.0, 0.14, -59.34},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["spd888pushup"] = {"glap@spd888-push-up", "spd888-push-up", "Pompes SPD", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["grakuten"] = {"glap@rakuten-point", "rakuten-point-clip", "Kameru Lala Mignon", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["pubgitsmylife"] = {"danceitsmylife@animations", "danceitsmylife_clip", "PUBG C'est Ma Vie", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["pubgnastygirl"] = {"nastygirl@animations", "nastygirlclip", "PUBG Fille Méchante", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["jkt1"] = {"jktdance@animations", "jktdance_clip", "Jurus Rahasia JKT", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["jkt2"] = {"jktdance2@animations", "jktdance2_clip", "Rotation Lourde JKT", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["jkt3"] = {"jktdance3@animations", "jktdance3_clip", "Biscuits de Fortune JKT", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["slickback"] = {"glap@slick-back", "slick-back", "Slick Back", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["jarpchirstmas01"] = {"jarp_chirstmas_01", "jarp_clip", "Jingle Bell", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["ifyoudance1"] = {"ifyoudancep1@animations", "ifyoudancep1_clip", "If You Dance 1", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["ifyoudance2"] = {"ifyoudancep2@animations", "ifyoudancep2_clip", "If You Dance 2", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["terbayangkamu"] = {"pubghaidilaodance@animations", "pubghaidilaodance_clip", "Terbayang bayang kamu", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["bigdawgs"] = {"bigdawgs@animations", "bigdawgsclip", "Big Dawg", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["lolidanceslow"] = {"lolidanceslow@animations", "lolidanceslow", "Loli Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["lolidancefast"] = {"lolidancefast@animations", "lolidancefast", "Loli Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["justwannadancenormal"] = {"glap@i-just-wanna-dance", "i-just-wanna-dance-normal", "I Just Wanna Dance Normal", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["justwannadancecrazy"] = {"glap@i-just-wanna-dance", "i-just-wanna-dance-crazy", "I Just Wanna Dance Crazy", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["sickoflove"] = {"glap@sickoflove", "sickoflove_clip", "Sick of Love", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = true,
    }},
    ["terminator"] = {"terminatordance@animations", "terminatordanceclip", "Terminator Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["leconstudios"] = {"glap@lecon-studios", "lecon-studios", "Lecon Studios", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["donkeyleft"] = {"zep_donkey", "donkey_left", "Donkey Challenge Left", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["donkeyright"] = {"zep_donkey", "donkey_right", "Donkey Challenge Right", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["pokedance"] = {"zep_pokedance", "pokodance", "Pokedance Challenge", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["tellurgf"] = {"oudoud@tellurgf", "oudoud_tellurgf", "Tell Ur Girlfriend", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["sheesh"] = {"oudoud@sheesh", "oudoud_sheesh", "Sheesh BabyMonster", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["mamushi"] = {"oudoud@mamushi", "oudoud_mamushi", "Mamushi Dance", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["tanghulu"] = {"oudoud@malatanghulu", "oudoud_malatanghulu", "Tang Tang Hulu Hulu", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["maboyleft"] = {"oudoud@maboy_left", "oudoud_maboy_left", "Maboy Left", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["maboyright"] = {"oudoud@maboy_right", "oudoud_maboy_right", "Maboy Right", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["badgirlslikeyouleft"] = {"oudoud@badgirlslikeyou", "oudoud_badgirllikeyou_left", "Bad Girls Like You Left", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["badgirlslikeyoumid"] = {"oudoud@badgirlslikeyou", "oudoud_badgirllikeyou_mid", "Bad Girls Like You Middle", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["badgirlslikeyouright"] = {"oudoud@badgirlslikeyou", "oudoud_badgirllikeyou_right", "Bad Girls Like You Right", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sheesh2"] = {"glap@sheesh-babymonster", "sheesh-babymonster", "Sheesh BABYMONSTER", animationoptions =
    {
        emoteloop = true,
        emotemoving = false
    }},
    ["squidgame"] = {"glap@squid-dance", "squid-dance", "Squid Dance", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["noppo"] = {"glap@noppo-mum-mum", "noppo-mum-mum", "Noppo Mum Mum", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["memhon"] = {"glap@me-mhon-non-nae", "me-mhon-non-nae", "Me Mhon Non Nae", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["byebyeservice"] = {"glap@bye-bye-bye-service", "bye-bye-bye-service", "Deadpool Service", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["byebyegl"] = {"glap@bye-bye-bye-nsync", "bye-bye-bye-nsync", "Deadpool Bye Bye Bye", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["semenea"] = {"glap@se-menea", "se-menea", "Se Menea", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["mine1"] = {"you'remine1@kyunnies", "you'remine1_clip", "You're Mine 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["mine2"] = {"you'remine2@kyunnies", "you'remine2_clip", "You're Mine 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["gpunder"] = {"glap@under-under", "under-under", "Under Under", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["gptwerk"] = {"glap@twerk-v1", "twerk-v1", "Twerk Glap Version", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["mybfsit"] = {"glap@have-you-seen-my-bf-sit", "have-you-seen-my-bf-sit", "Have You Seen My BF", AnimationOptions =
    {
        Prop = "glap-pom-pillow",
        PropBone = 57005,
        PropPlacement = {0.05, 0.03, -0.1, -84.15, 12.35, 0.0},
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["buckleup"] = {"glap@buckle-up-meme", "buckle-up-meme", "Buckle up", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["bigbone"] = {"glap@bigbone", "bigbone_clip", "Big Bone", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["supernova2"] = {"glap@aespa-supernova-v2", "aespa-supernova-v2", "Supernova V2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["supernova1"] = {"glap@aespa-supernova-v1", "aespa-supernova-v1", "Supernova V1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["khaikatark"] = {"glap@khaikatark", "khaikatark", "Khaikatark", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["cnsale"] = {"glap@cn-sale", "cn-sale_clip", "Chinese Sale", AnimationOptions =
    {
        Prop = "prop_microphone_02",
        PropBone = 57005,
        PropPlacement = {0.10, 0.05, 0.01, -64.0, 0.0, -20.0},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["matsuri"] = {"glap@matsuri", "matsuri_clip", "Matsuri", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["ciscisdance"] = {"cisciscis@anim", "cis_clip", "Cis Cis Cis", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["apt"] = {"glap@rose-apt", "rose-apt", "APT ROSE 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["apt1"] = {"oudoud@apt_rose", "oudoud_apt_left", "APT ROSE KIRI", AnimationOptions =
    {
        EmoteLoop = true
    }},

    ["apt2"] = {"oudoud@apt_rose", "oudoud_apt_right", "APT ROSE KANAN", AnimationOptions =
    {
        EmoteLoop = true
    }},

    ["apt3"] = {"oudoud@apt_rose_solo", "oudoud_apt_rose", "APT Rose SOLO", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["iribilboss"] = {"plumbairibilangbos@animations", "plumbairibilangbosclip", "Goyang Lumba Iri Bilang Bos", AnimationOptions =
    {
        EmoteLoop = true,
    }},

    ["lumbajoget"] = {"plumbalumbajoget@animations", "plumbalumbajogetclip", "Goyang Lumba Lumba Joget", AnimationOptions =
    {
        EmoteLoop = true,
    }},

    ["robloxardance"] = {"robloxardance@animations", "robloxardanceclip", "Roblox Ar Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["rsk"] = {"glap@rot-sue-kaeng", "rot-sue-kaeng", "Rot Sue Kaeng", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["crazyfrog"] = {"glap@crazy-frog", "crazy-frog", "Crazy Frog Down", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["crazyfrogup"] = {"glap@crazy-frog-up", "crazy-frog-up", "Crazy Frog Up", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["pokedance2"] = {"ppokedance@animations", "ppokedanceclip", "Poke Dance 2", AnimationOptions =
    {
        EmoteLnewoop = true

    }},
    ["toothlessdance"] = {"toothless@dance", "toothless-dance", "Toothless Dance", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["stefan"] = {"glap@stefan-shake", "stefan-shake", "Stefan Shake", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["magnetic"] = {"zepeto@magnetic", "magnetic-zepeto", "Magnetic", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["zepsmart"] = {"zepeto@smart-le_sserafim", "smart-le_sserafim-zepeto", "Smart LE SSERAFIM", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["hitit"] = {"custom@hitit", "hitit", "Hit It", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["bopdance"] = {"divined@tdances@new", "dtdance2", "Bop", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hipsterdance"] = {"divined@tdances@new", "dtdance6", "Hipster Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hippiedance"] = {"divined@tdances@new", "dtdance7", "Hippie Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["squaredance"] = {"divined@tdances@new", "dtdance10", "Square Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hotdance"] = {"divined@tdances@new", "dtdance11", "Hot Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hulahula"] = {"divined@tdances@new", "dtdance12", "Hula-Hula", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["kingdance"] = {"divined@tdances@new", "dtdance14", "The King's Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["linedance"] = {"divined@tdances@new", "dtdance15", "Dance Line", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["magicman"] = {"divined@tdances@new", "dtdance16", "Magic Man", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["marat"] = {"divined@tdances@new", "dtdance17", "Marat", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["maskoff"] = {"divined@tdances@new", "dtdance18", "Mask Off", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["mellow"] = {"divined@tdances@new", "dtdance19", "Mellow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["showroomdance"] = {"divined@tdances@new", "dtdance20", "Showroom Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["windmillfloss"] = {"divined@tdances@new", "dtdance21", "Windmill Floss", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["woahdance"] = {"divined@tdances@new", "dtdance22", "Woah", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hiphop1"] = {"custom@hiphop1", "hiphop1", "Hip Hop 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["hiphop2"] = {"custom@hiphop2", "hiphop2", "Hip Hop 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["hiphop3"] = {"custom@hiphop3", "hiphop3", "Hip Hop 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = false,
    }},
    ["hiphop4"] = {"custom@hiphop_slide", "hiphop_slide", "Hip Hop 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["hiphop5"] = {"custom@hiphop90s", "hiphop90s", "Hip Hop 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["hiphop6"] = {"divined@tdances@new", "dtdance5", "Hip Hop 6", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hiphop7"] = {"divined@tdances@new", "dtdance8", "Hip Hop 7", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["hilowave"] = {"divined@tdances@new", "dtdance9", "Hi Lo Wave", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["woowalkinx"] = {"divined@drpack@new", "woowalkinx", "Woo Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["bloodwalk"] = {"divined@drpack@new", "bloodwalk", "Blood Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["cripwalk3"] = {"divined@drpack@new", "cripwalk3", "Crip Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["shootit"] = {"divined@drpack@new", "shootit", "Shoot Dance", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["millyrocks"] = {"divined@drpack@new", "millyrocks", "Milly Rock", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["shmoney"] = {"divined@drpack@new", "shmoney", "Shmoney Dance", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dougie"] = {"divined@drpack@new", "dougie", "Dougie", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["haiphuthon"] = {"divined@drpack@new", "haiphuthon", "Haiphuthon", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["curvette"] = {"divined@drpack@new", "curvette", "Curvette", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["tokyochall"] = {"divined@drpack@new", "tokyochall", "Tokyo Challenge", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["thotiana"] = {"divined@drpack@new", "thotiana", "Thotiana", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["moodswings"] = {"divined@drpack@new", "moodswings", "Moodswings Dance", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["whatyouknowboutlove"] = {"divined@drpack@new", "whatyouknowboutlove", "Pop Love", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["gangnamstyle"] = {"custom@gangnamstyle", "gangnamstyle", "Gangnamstyle", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["electroshuffle"] = {"custom@electroshuffle_original", "electroshuffle_original", "Electro Shuffle", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["electroshuffle2"] = {"custom@electroshuffle", "electroshuffle", "Electro Shuffle 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["defaultdance"] = {"custom@dancemoves", "dancemoves", "Move Dance", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["discodance"] = {"custom@disco_dance", "disco_dance", "Disco Dance", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["capoeiramove"] = {"divined@tdances@new", "dtdance4", "Capoeira Move", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["blixkytwirl2"] = {"div@woowalk@test", "blixkytwirl2", "Blixky Twirl", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["armswirl"] = {"custom@armswirl", "armswirl", "Arm Swirl", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["armwave"] = {"custom@armwave", "armwave", "Arm Wave", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["banddance"] = {"divined@tdances@new", "dtdance1", "Band Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["bboydance"] = {"divined@tdances@new", "dtdance3", "BBoy Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["bellydance"] = {"custom@bellydance", "bellydance", "Belly Dance", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ddance1"] = {"divined@dances@new", "ddance1", "Divined Dance 1", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance2"] = {"divined@dances@new", "ddance2", "Divined Dance 2", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance3"] = {"divined@dances@new", "ddance3", "Divined Dance 3", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance4"] = {"divined@dances@new", "ddance4", "Divined Dance 4", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance5"] = {"divined@dances@new", "ddance5", "Divined Dance 5", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance6"] = {"divined@dances@new", "ddance6", "Divined Dance 6", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance7"] = {"divined@dances@new", "ddance7", "Divined Dance 7", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance8"] = {"divined@dances@new", "ddance8", "Divined Dance 8", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddance9"] = {"divined@dances@new", "ddance9", "Divined Dance 9", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddances10"] = {"divined@dances@new", "ddance10", "Divined Dance 10", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddances11"] = {"divined@dances@new", "ddance11", "Divined Dance 11", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddances12"] = {"divined@dances@new", "ddance12", "Divined Dance 12", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["ddances13"] = {"divined@dances@new", "ddance13", "Divined Dance 13", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance1"] = {"divined@dancesv2@new", "divdance1", "Divined Dance 1 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance2"] = {"divined@dancesv2@new", "divdance2", "Divined Dance 2 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance3"] = {"divined@dancesv2@new", "divdance3", "Divined Dance 3 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance4"] = {"divined@dancesv2@new", "divdance4", "Divined Dance 4 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance5"] = {"divined@dancesv2@new", "divdance5", "Divined Dance 5 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance6"] = {"divined@dancesv2@new", "divdance6", "Divined Dance 6 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance7"] = {"divined@dancesv2@new", "divdance7", "Divined Dance 7 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance8"] = {"divined@dancesv2@new", "divdance8", "Divined Dance 8 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance9"] = {"divined@dancesv2@new", "divdance9", "Divined Dance 9 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance10"] = {"divined@dancesv2@new", "divdance10", "Divined Dance 10 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance11"] = {"divined@dancesv2@new", "divdance11", "Divined Dance 11 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance12"] = {"divined@dancesv2@new", "divdance12", "Divined Dance 12 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance13"] = {"divined@dancesv2@new", "divdance13", "Divined Dance 13 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["divdance14"] = {"divined@dancesv2@new", "divdance14", "Divined Dance 14 (v2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance1"] = {"divined@breakdances@new", "divbdance1", "Divined Break Dance 1", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance2"] = {"divined@breakdances@new", "divbdance2", "Divined Break Dance 2", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance3"] = {"divined@breakdances@new", "divbdance3", "Divined Break Dance 3", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance4"] = {"divined@breakdances@new", "divbdance4", "Divined Break Dance 4", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance5"] = {"divined@breakdances@new", "divbdance5", "Divined Break Dance 5", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance6"] = {"divined@breakdances@new", "divbdance6", "Divined Break Dance 6", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance7"] = {"divined@breakdances@new", "divbdance7", "Divined Break Dance 7", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance8"] = {"divined@breakdances@new", "divbdance8", "Divined Break Dance 8", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdance9"] = {"divined@breakdances@new", "divbdance9", "Divined Break Dance 9", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdances10"] = {"divined@breakdances@new", "divbdance10", "Divined Break Dance 10", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdances11"] = {"divined@breakdances@new", "divbdance11", "Divined Break Dance 11", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdances12"] = {"divined@breakdances@new", "divbdance12", "Divined Break Dance 12", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdances13"] = {"divined@breakdances@new", "divbdance13", "Divined Break Dance 13", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dcvbdances14"] = {"divined@breakdances@new", "divbdance14", "Divined Break Dance 14", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance1"] = {"divined@brdancesv2@new", "dbrdance1", "Divined Break Dance 1 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance2"] = {"divined@brdancesv2@new", "dbrdance2", "Divined Break Dance 2 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance3"] = {"divined@brdancesv2@new", "dbrdance3", "Divined Break Dance 3 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance4"] = {"divined@brdancesv2@new", "dbrdance4", "Divined Break Dance 4 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance5"] = {"divined@brdancesv2@new", "dbrdance5", "Divined Break Dance 5 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance6"] = {"divined@brdancesv2@new", "dbrdance6", "Divined Break Dance 6 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance7"] = {"divined@brdancesv2@new", "dbrdance7", "Divined Break Dance 7 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance8"] = {"divined@brdancesv2@new", "dbrdance8", "Divined Break Dance 8 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance9"] = {"divined@brdancesv2@new", "dbrdance9", "Divined Break Dance 9 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance10"] = {"divined@brdancesv2@new", "dbrdance10", "Divined Break Dance 10 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance11"] = {"divined@brdancesv2@new", "dbrdance11", "Divined Break Dance 11 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dbrdance12"] = {"divined@brdancesv2@new", "dbrdance12", "Divined Break Dance 12 (V2)", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["macarena"] = {"custom@makarena", "makarena", "Macarena", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["maraschino"] = {"custom@maraschino", "maraschino", "Maraschino", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["salsa2"] = {"custom@salsa", "salsa", "Salsa", AnimationOptions =
    {
        EmoteLoop = true,

    }},
    ["renegade"] = {"custom@renegade", "renegade", "Renegade", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["savage"] = {"custom@savage", "savage", "Savage", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["sayso"] = {"custom@sayso", "sayso", "Say So", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["orangejustice"] = {"custom@orangejustice", "orangejustice", "Orange Justice", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["takel"] = {"custom@take_l", "take_l", "Take the L", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["hitemwithdat"] = {"divined@drillb2@new", "hitemwithdat", "Hit 'Em With Dat", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["slutmeout"] = {"divined@drillb2@new", "slutmeout", "Slut Me Out", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy"] = {"div@woowalk@test", "sturdy2", "Get Sturdy 1", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy2"] = {"divined@drpackv3@new", "kaisturdy", "Get Sturdy 2 Kai", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdys2"] = {"divined@drillb2@new", "sturdy", "Get Sturdy 2", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdys3"] = {"divined@drillb2@new", "sturdyground", "Get Sturdy 3", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy3"] = {"divined@drpack@new", "cripwalk3", "Get Sturdy 3 Crip Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdys4"] = {"nito_sturdy18@animation", "nito_sturdy18_clip", "Get Sturdy 4", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy4"] = {"divined@drpack@new", "bloodwalk", "Get Sturdy 4 Blood Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdys5"] = {"div@woowalk@test", "woowalk", "Get Sturdy 5 V2 Woo Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy5"] = {"divined@drpack@new", "woowalkinx", "Get Sturdy 5 Woo Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy95"] = {"nito_sturdy_dance1@animation", "nito_sturdy_dance1_clip", "Get Sturdy 14", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy96"] = {"nito_sturdy20@animation", "nito_sturdy20_clip", "Get Sturdy 15", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy97"] = {"nito_sturdy5@animation", "nito_sturdy5_clip", "Get Sturdy 16", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy98"] = {"nito_sturdy2_freethehometeam@animation", "nito_sturdy2_freethehometeam_clip", "Get Sturdy 17", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy99"] = {"nito_sturdy7@animation", "nito_sturdy7_clip", "Get Sturdy 18", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy991"] = {"nito_sturdy8@animation", "nito_sturdy8_clip", "Get Sturdy 19", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy992"] = {"nito_sturdy11@animation", "nito_sturdy11_clip", "Get Sturdy 20", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy993"] = {"nito_sturdy3_freethehometeam@animation", "nito_sturdy3_freethehometeam_clip", "Get Sturdy 21", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy994"] = {"nito_sturdy_mightyz@animation", "nito_sturdy_mightyz_clip", "Get Sturdy 22", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy995"] = {"nito_sturdy1@animation", "nito_sturdy1_clip", "Get Sturdy 23", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sturdy996"] = {"divined@drpack@new", "cripwalk3", "Get Sturdy 24 Crip Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy997"] = {"divined@drpack@new", "bloodwalk", "Get Sturdy 25 Blood Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["sturdy998"] = {"divined@drpack@new", "woowalkinx", "Get Sturdy 26 Woo Walk", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["walknstep"] = {"divined@drillb2@new", "walknstep", "Walk N Step", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["toomanyglockies"] = {"divined@drillb2@new", "toomanyglockies", "Too Many Glockies", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["toosieslide"] = {"divined@drillb2@new", "toosieslide", "Toosie Slide", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["twerking"] = {"divined@drillb2@new", "twerking", "Twerking 1", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["twerking2"] = {"divined@drillb2@new", "splitstwerk2", "Twerking 2", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["twerking3"] = {"divined@drillb2@new", "twerkmocap2", "Twerking 3", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["dancesolo"] = {"anim@amb@nightclub@dancers@crowddance_facedj_transitions@", "trans_dance_facedj_hi_to_mi_09_v1_male^4", "Dance Solo", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dancesolo3"] = {"special_ped@mountain_dancer@base", "base", "Dance Solo 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dancesolo4"] = {"anim@mp_player_intcelebrationfemale@raise_the_roof", "raise_the_roof", "Dance Solo 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dancepartyf"] = {"anim@amb@nightclub@dancers@crowddance_groups@", "hi_dance_crowd_09_v1_female^1", "Dance Party Female", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dancepartyf2"] = {"anim@amb@nightclub@dancers@crowddance_groups@", "hi_dance_crowd_09_v1_female^6", "Dance Party Female 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["danceparty3"] = {"anim@mp_player_intcelebrationfemale@heart_pumping", "heart_pumping", "Dance Party 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dancedisco"] = {"anim@mp_player_intcelebrationfemale@uncle_disco", "uncle_disco", "Dance Disco", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["dabloop"] = {"divined@tdances@new", "dtdance13", "Dab Loop", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["jiso"] = { "flowersantorostore", "flower_santoro", "Jisoo Dance", AnimationOptions =
    {
        Prop = 'prop_mawar_bayu',
        PropBone = 57005,
        PropPlacement = {
            -0.04,
            0.05,
            0.01,
            -110.0,
            0.0,
            -108.25
        },

        SecondProp = 'prop_mawar_bayu',
        SecondPropBone = 18905,
        SecondPropPlacement = {
            -0.04,
            -0.01,
            0.07,
            -99.6,
            0.0,
            -79.44
        },

        EmoteLoop = true,
        EmoteMoving = true
    }},
    ["timtan"] = {"pimpimpom@santorostore", "pompo_santoro", "Tim Tim Tan Tan", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["timtan2"] = {"dreamscometrue@santorostore", "cometrue_santoro", "Tim Tim Tan Tan 2", AnimationOptions =
    {
        EmoteLoop = true
    }},

    ["venom"] = {"pinkvenom@santorostore", "venom_santoro", "Pink Venom Dance", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["dtydance"] = { "jumpinglow@danceanimation", "jumpinglow_clip", "Dty Dance", AnimationOptions = {
        EmoteLoop = true,
    }},

    ["dtydance2"] = { "behere@danceanimation", "behere_clip", "Dty Dance 2", AnimationOptions = {
        EmoteLoop = true,
    }},

    ["dtydance3"] = { "comrade@danceanimation", "comrade_clip", "Comrade Russia Dance", AnimationOptions = {
        EmoteLoop = true,
    }},

    ["dtydance4"] = { "dancecustom1@danceanimation", "dancecustom1_clip", "Dty Dance 4", AnimationOptions = {
        EmoteLoop = true,
    }},

    ["dtydance5"] = { "dancecustom2@danceanimation", "dancecustom2_clip", "Dty Dance 5", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance4"] = { "dancecustom1@danceanimation", "dancecustom1_clip", "EMOTES Dance 4", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance5"] = { "dancecustom2@danceanimation", "dancecustom2_clip", "EMOTES Dance 5", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance6"] = { "dancecustom3@danceanimation", "dancecustom3_clip", "EMOTES Dance 6", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance7"] = { "controllercrew@dance", "controllercrew_clip", "Control Crew Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance8"] = { "layers@danceanimation", "layers_clip", "EMOTES Dance 8", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance9"] = { "ondaonda@danceanimation", "onda_clip", "EMOTES Dance 9", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance10"] = { "tonal@danceanimation", "tonal_clip", "EMOTES Dance 10", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance11"] = { "dinamites@dance", "dinamites_clip", "Boy With Love Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance12"] = { "dynamite@dance", "dynamite_clip", "Dynamite Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance13"] = { "gomufasa@dance", "gomufasa_clip", "Gomufasa Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance14"] = { "stuckdance@animation", "stuckdance_clip", "EMOTES Dance 14", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance15"] = { "indigo@dance", "indigo_clip", "Indigo Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance16"] = { "kpop@dance", "kpop_clip", "KPOP Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance17"] = { "outwest@dance", "outwest_clip", "EMOTES Dance 17", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance18"] = { "pullup@dance", "pullup_clip", "EMOTES Dance 18", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance19"] = { "springy@dance", "springy_clip", "EMOTES Dance 19", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["emoodance20"] = { "tally@danceanimation", "tally_clip", "Tally Dance", AnimationOptions = {
        EmoteLoop = true,
    }},
    ["lisarockstar"] = {"jarp_rockstar", "jarp_rockstar_clip", "Lisa Rockstar", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["lisa"] = {"glap@lisa-pose", "lisa-pose_clip", "Lisa Pose", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["fanchan"] = {"oudoud@fanchan", "oudoud_fanchan", "Fanchan", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["tidjong"] = {"jarp_tidjong", "jarp_tidjong_clip", "TidJong", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["anranaeng"] = {"jarp_andranaeng", "jarp_andranaeng_clip", "An Ranaeng Alie 1", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["anranaengv2"] = {"glap@an-ranaeng-v2", "an-ranaeng-v2", "An Ranaeng Alie 2", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["swagmiyauchi"] = {"oudoud@swag", "oudoud_swag", "Swag Miyauchi", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["theoneandonly"] = {"jarp_missgrand", "jarp_missgrand_clip", "Grand The Only One", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["tellurgirlfriend"] = {"glap@tell-ur-gf", "tell-ur-gf", "Tell Ur Girlfirend", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["hot2hot"] = {"glap@hot2hot", "hot2hot", "Hot Two Hot 1", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["hot2hot2"] = {"oudoud@hot2hot", "oudoud_hot2hot", "Hot Two Hot 2 ", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["enoughleft"] = {"oudoud@enough", "oudoud_enough_left", "Enough Left", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["enoughright"] = {"oudoud@enough", "oudoud_enough_right", "Enough Right", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["pakdeemissgrand2loop"] = {"oudoud@pakdeemissgrand", "oudoud_pakdeemissgrand_loop", "Pak Dee Miss Grand Loop", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["pakdeemissgrand"] = {"glap@pak-dee-miss-grand", "pak-dee-miss-grand", "Pak Dee Miss Grand", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["pakdeemissgrand2"] = {"oudoud@pakdeemissgrand", "oudoud_pakdeemissgrand", "Pak Dee Miss Grand 2", AnimationOptions =
    {
        Emoteloop = true
    }},
    ["woahwouhwork"] = {"glap@work-work-work", "work-work-work", "Woah Work Work", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["pacujalurpaddle"] = {"glap@pacu-jalur--paddle", "paddle", "Pacu Jalur Paddle", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["pacujalurpaddlemove"] = {"glap@pacu-jalur--paddle", "paddle-move", "Pacu Jalur Moving",AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["pacujalurdance"] = {"glap@pacu-jalur--dance", "pacu-jalur--dance", "Pacu Jalur Dance", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["talay"] = {"glap@talay", "talay", "Talay", AnimationOptions =
    {
        Emoteloop = true,
        Emotemoving = false
    }},
    ["doladola"] = {
        "pbdola@animation",
        "pbdola_clip",
        "Dola Dola Dance",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }},
    ["bumblebee"] = {
        "bumblebees@animation",
        "bumblebees_clip",
        "Bumblebee",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }},
    ["psquidgameround"] = {
        "psquidgameround@animations",
        "psquidgameroundclip",
        "Squid Game Round and Round",
        AnimationOptions = {
            EmoteLoop = true
        }},
    ["pmeninadojob"] = {
        "pmeninadojob@animations",
        "pmeninadojobclip",
        "PUBG Menina Do Job Dance",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["mylipslikesugar"] = {
        "oudoud@my_lips_like_sugar_thai_remix",
        "oudoud_my_lips_like_sugar_thai_remix",
        "My Lips Like Sugar Thai Remix",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["muayneekah"] = {
        "jarp_muayneekah",
        "jarp_muayneekah_clip",
        "Muay Nee Kah",
        AnimationOptions = {
            EmoteLoop = true,

        }
    },
    ["sayyesalone"] = {
        "jarp_sayyes_alone",
        "jarp_sayyes_alone_clip",
        "Say Yes Alone",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sayyesleft"] = {
        "jarp_sayyes_alone_left",
        "jarp_sayyes_alone_left_clip",
        "Say Yes Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["sayyesright"] = {
        "jarp_sayyes_alone_right",
        "jarp_sayyes_alone_right_clip",
        "Say Yes Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["discopled1"] = {
        "discopled1@animation",
        "discopled1_clip",
        "Discopled 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["discopled2"] = {
        "discopled2@animation",
        "discopled2_clip",
        "Discopled 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["discopled3"] = {
        "discopled3@animation",
        "discopled3_clip",
        "Discopled 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["pcatui"] = {
        "pcatui@animations",
        "pcatuiclip",
        "Meme Cat UI Dance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pcatuai1"] = {
        "pcatuai1@animations",
        "pcatuai1clip",
        "Meme Cat UAI Dance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pcatuai2"] = {
        "pcatuai2@animations",
        "pcatuai2clip",
        "Meme Cat UAI Dance Fast",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["myhumps"] = {
        "oudoud@myhumps",
        "oudoud_myhumps",
        "My Humps Remix",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["nolabounce"] = {
        "oudoud@badparents_x_nolabounce",
        "oudoud_badparents_x_nolabounce",
        "Bad Parents x Nola Bounce",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["area51"] = {
        "jarp_area51",
        "jarp_area51_clip",
        "Area 51 / Velocity",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["fireball1"] = {
        "fireball1@animation",
        "fireball1_clip",
        "Fireball 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["fireball2"] = {
        "fireball2@animation",
        "fireball2_clip",
        "Fireball 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["fireball3"] = {
        "fireball3@animation",
        "fireball3_clip",
        "Fireball 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["elpasodelleft"] = {
        "oudoud@el_paso_del_canguro",
        "oudoud_el_paso_del_canguro_left",
        "El Paso Del Canguro Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["elpasodelright"] = {
        "oudoud@el_paso_del_canguro",
        "oudoud_el_paso_del_canguro_right",
        "El Paso Del Canguro Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["kwenchanaback"] = {
        "kwenchanaback@animation",
        "kwenchanaback_clip",
        "Gwenchana Trend",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["kwenchanafront"] = {
        "kwenchanafront@animation",
        "kwenchanafront_clip",
        "Gwenchana Trend 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["brunao"] = {
        "oudoud@bonde_do_brunao",
        "oudoud_bonde_do_brunao_bruno_mars",
        "Bonde do Brunao Bruno Mars",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["asifitsyourlast1"] = {
        "asifitsyourlast1@animation",
        "asifitsyourlast1_clip",
        "As If Its Your Last 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["asifitsyourlast2"] = {
        "asifitsyourlast2@animation",
        "asifitsyourlast2_clip",
        "As If Its Your Last 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["pkawaikutegomen"] = {
        "pkawaikutegomen@animations",
        "pkawaikutegomenclip",
        "Kawaikute Gomen Dance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["vaqueroremix"] = {
        "oudoud@vaquero_remix",
        "oudoud_vaquero",
        "Vaquero Remix",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["beautifulgirl"] = {
        "oudoud@beautiful_girl_laos_remix",
        "oudoud_beautiful_girl_laos_remix",
        "Beautiful Girl Laos Remix",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["humble"] = {
        "nikitransition@animation",
        "niki_clip",
        "ENHYPE-HUMBLE",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["kamerulala"] = {
        "kamerulala@animation",
        "kamerulala_clip",
        "Kamerulala RakutenPoint!",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["seventeenmaes"] = {
        "maestro@animation",
        "maestro_clip",
        "MAES SEVENTEEN",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["tiktoktrend"] = {
        "tiktoktrend@animation",
        "tiktok_clip",
        "TikTok Dance",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["vemvem"] = {
        "vemvem@animation",
        "vemvem_clip",
        "Vem Vem",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["oudhsktl"] = {
        "oudoud@hskt",
        "oudoud_hskt_left",
        "HSKT Lee Hi Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["oudhsktr"] = {
        "oudoud@hskt",
        "oudoud_hskt_right",
        "HSKT Lee Hi Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["oudhskts"] = {
        "oudoud@hskt",
        "oudoud_hskt_solo",
        "HSKT Lee Hi Solo",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["tokyo"] = {
        "glap@leateq-tokyo",
        "leateq-tokyo",
        "Tokyo Eric",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["badgirlslikeyou"] = {
        "glap@bad-girls-like-u",
        "bad-girls-like-u",
        "Bad Girls Like You Tobii",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["mantra"] = {
        "glap@jennie-mantra",
        "jennie-mantra",
        "Mantra Jennie",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["badboythairemix"] = {
        "oudoud@badboy_thairemix",
        "oudoud_badboy_thairemix",
        "Bad Boy Thai Remix",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },

    ["leftcheek"] = {
        "oudoud@leftcheek",
        "oudoud_leftcheek",
        "Left Cheek (Doo Doo Blick) Lay Bankz",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["touchkatseye"] = {
        "glap@touch-katseye",
        "touch-katseye",
        "Touch KATSEYE",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["rockstarlisa1"] = {
        "glap@lisa-rockstar-part-1",
        "lisa-rockstar-part-1",
        "Rockstar LISA",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["fish1"] = {
        "jarp_fish_1",
        "jarp_fish_1_clip",
        "Fish Dance Right",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["fish2"] = {
        "jarp_fish_2_alone",
        "jarp_fish_2_alone_clip",
        "Fish Dance Left",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["fish3"] = {
        "jarp_fish_3",
        "jarp_fish_3_clip",
        "Fish Dance Triple",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["forte1"] = {
        "glap@battle-forte",
        "battle-forte",
        "Battle Forte 1 Lollipop",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["forte2"] = {
        "glap@battle-forte",
        "battle-forte",
        "Battle Forte 2 Lollipop",
        AnimationOptions = {
            Prop = "prop_kino_light_02",
            PropBone = 1,
            PropPlacement = {0.0, -2.65, 0.0, 0.0, 0.0, 180.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["forte3"] = {
        "glap@battle-forte",
        "battle-forte",
        "Battle Forte 3 Lollipop",
        AnimationOptions = {
            Prop = "prop_kino_light_02",
            PropBone = 1,
            PropPlacement = {0.0, 4.8, 0.0, 0.0, 0.0, 0.0},
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["stride"] = {
        "export@jarp_stride",
        "jarp_stride",
        "Stride Dance",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["doodle1"] = {
        "doodle-1@kyunnies",
        "doodle-1_clip",
        "Doodle Dance 1",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["doodle2"] = {
        "doodle-2@kyunnies",
        "doodle-2_clip",
        "Doodle Dance 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["flowerdance"] = {
        "flower_dance@anim",
        "flower_clip",
        "Flower Dance Anims",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["nastygirldance"] = {
        "nastygirl_dance@kyunnies",
        "nastydance_clip",
        "Nasty Dance",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["pocketlocket"] = {
        "pocketlocket@kyunnies",
        "pocketlocket_clip",
        "Pocket Locket",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["tellembrazil"] = {
        "glap@cochise-tellem-x-brazil",
        "cochise-tellem-x-brazil",
        "Tellem X Brazil Cochise",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["tiramisucakev2"] = {
        "tiramisucake_dance@kyunnies",
        "tiramisucake_clip",
        "Tiramisu Cake",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["mikulive"] = {
        "pfmikulive@animations",
        "pfmikuliveclip",
        "Miku Live",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["feelit"] = {
        "pffeelit@animations",
        "pffeelitclip",
        "Feel It",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["startingprance"] = {
        "pfstartingprance@animations",
        "pfstartingpranceclip",
        "Starting Prance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["skyward"] = {
        "pfskyward@animations",
        "pfskywardclip",
        "Skyward",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["smoothoperator"] = {
        "pfsmoothoperator@animations",
        "pfsmoothoperatorclip",
        "Smooth Operator",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["bratty"] = {
        "pfbratty@animations",
        "pfbrattyclip",
        "Bratty",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["inhamood"] = {
        "pfinhamood@animations",
        "pfinhamoodclip",
        "In Ha Mood",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["spicystart"] = {
        "pfspicystart@animations",
        "pfspicystartclip",
        "Spicy Start",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["deepexplorer"] = {
        "pfdeepexplorer@animations",
        "pfdeepexplorerclip",
        "Deep Explorer",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["whatyouwant"] = {
        "pfwhatyouwant@animations",
        "pfwhatyouwantclip",
        "What You Want",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["inedancin"] = {
        "pflinedancin@animations",
        "pflinedancinclip",
        "Line Dancin",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["independence"] = {
        "pfindependence@animations",
        "pfindependenceclip",
        "Independence",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["cairo"] = {
        "pfcairo@animations",
        "pfcairoclip",
        "Cairo",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["okidoki"] = {
        "pfokidoki@animations",
        "pfokidokiclip",
        "Oki Doki",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["outlaw"] = {
        "pfoutlaw@animations",
        "pfoutlawclip",
        "Outlaw",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["notears"] = {
        "pfnotears@animations",
        "pfnotearsclip",
        "No Tears",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["minefort"] = {
        "pfmine@animations",
        "pfmineclip",
        "Mine",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["lookinggood"] = {
        "pflookinggood@animations",
        "pflookinggoodclip",
        "Looking Good",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["heelclickbreakdown"] = {
        "pfheelclickbreakdown@animations",
        "pfheelclickbreakdownclip",
        "Heel Click Breakdown",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["entranced"] = {
        "pfentranced@animations",
        "pfentrancedclip",
        "Entranced",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["feelitfly"] = {
        "pffeelitfly@animations",
        "pffeelitflyclip",
        "Feel It Fly",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["slaywalk"] = {
        "slaywalk@animation",
        "slaywalk_clip",
        "Slay WalkILLIT",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["firstsnowmale"] = {
        "jarp_firstsnow_male",
        "jarp_firstsnow_male_clip",
        "The First Snow Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["firstsnowfemale"] = {
        "jarp_firstsnow_female",
        "jarp_firstsnow_female_clip",
        "The First Snow Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["yobunny"] = {
        "oudoud@yobunny",
        "oudoud_yobunny",
        "Yo Bunny",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["moonlitfloor"] = {
        "oudoud@moonlit_floor_lisa",
        "oudoud_moonlit_floor_lisa",
        "Moonlit Floor LISA",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["conteo"] = {
        "glap@don-omar_conteo",
        "don-omar_conteo",
        "Conteo Don Omar",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["teedeetada"] = {
        "jarp_teedeetada",
        "jarp_teedeetada_clip",
        "Teedee Tada",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["xmasloveleft"] = {
        "jarp_xmaslove_left",
        "jarp_xmaslove_left_clip",
        "X'mas Love Left",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["plingaguliguli"] = {
        "plingaguliguli@animations",
        "plingaguliguliclip",
        "Linga Guli Guli Dance Doodle",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["pratdance"] = {
        "pratdance@animations",
        "pratdanceclip",
        "Rat Dance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["ponthefloordance"] = {
        "ponthefloordance@animations",
        "ponthefloordanceclip",
        "PUBG On The Floor Dance",
        animationOptions = {
            emoteLoop = true
        }
    },
    ["reallylikeyou"] = {
        "jarp_reallylikeyou",
        "jarp_reallylikeyou_clip",
        "Really Like you",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["xmasloveright"] = {
        "jarp_xmaslove_right",
        "jarp_xmaslove_right_clip",
        "X'mas Love Right",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["lifeboy"] = {
        "jarp_lifeboy",
        "jarp_lifeboy_clip",
        "lifeboy",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["jliar"] = {
        "jarp_liar",
        "jarp_liar_clip",
        "Liar",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["jgee"] = {
        "jarp_gee",
        "jarp_gee_clip",
        "Gee Girl Gen",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["kamariidance"] = {
        "kamariidance@animation",
        "kamariidance_clip",
        "Kamarii Dance PUBG",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["lalala"] = {
        "glap@moai-la-la-la",
        "moai-la-la-la",
        "La La La Moai",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["power"] = {
        "gdragonpower@animation",
        "power_clip",
        "POWER G Dragon",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["cuteloopydance"] = {
        "cuteloopydance@anim",
        "cuteloopydance_clip",
        "Cute Loopy Dance PUBG",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["pgaramdanmadu"] = {
        "pgaramdanmadu@animations",
        "pgaramdanmaduclip",
        "Garam Dan Madu Dance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["byebyebyev3"] = {
        "jarp_byebyebye",
        "jarp_byebyebye_clip",
        "Byebyebye Deadpool V3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["doitlikejk"] = {"doitlike_jk@kyunnies", "doitlike_clip", "Do It Like", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["blablabla"] = {"glap@bla-bla-bla", "bla-bla-bla", "Glap Bla-Bla-Bla Speed Dance", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["afrojazz"] = {"glap@afro-jazz", "afro-jazz", "Afro Jazz", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["tellmewonderg"] = {"glap@tellme-wonder-girls", "tellme-wonder-girls-all", "Tell me Main Wonder Girls", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["tellmewonderg1"] = {"glap@tellme-wonder-girls", "tellme-wonder-girls-01", "Tell me 1 Wonder Girls", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["tellmewonderg2"] = {"glap@tellme-wonder-girls", "tellme-wonder-girls-02", "Tell me 2 Wonder Girls", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["tellmewonderg3"] = {"glap@tellme-wonder-girls", "tellme-wonder-girls-03", "Tell me 3 Wonder Girls", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["tellmewonderg4"] = {"glap@tellme-wonder-girls", "tellme-wonder-girls-04", "Tell me 4 Wonder Girls", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["tellmewonderg5"] = {"glap@tellme-wonder-girls", "tellme-wonder-girls-05", "Tell me 5 Wonder Girls", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["pocketlocketv2"] = {"glap@pocket-locket", "pocket-locket-main", "Pocket Locket Alaina Castillo V2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["adswagjp"] = {"ad-swagjp@kyunnies_anim", "swagjp_clip", "Swag JP", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["myhumpsv2"] = {"myhumps@animation", "myhumps_clip", "MY HUMPS REMIX DANCE V2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["seriousside"] = {"glap@serious-sideways", "serious-sideways", "Serious sideways Saitama", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["yailaem"] = {"glap@yailaem", "yailaem", "Yailaem", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["fromtheisland"] = {"fromtheisland2@animation", "fromtheisland2_clip", "From The Island 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["fallflat"] = {"mixamo@fall-flat", "fall-flat", "Fall Flat", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["khadalemale"] = {"khadalem@animation", "khadalem_clip", "KHADALE TREND Male", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["khadalefemale"] = {"khadalef@animation", "khadalef_clip", "KHADALE TREND Female", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["loumpad"] = {"glap@loumpadteung", "loum_clip", "LoumPadTeung", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["ohotherwan"] = {"glap@oho-ther-waan-jiab", "oho-ther-waan-jiab_anim", "Oho ther waan jiab Animation", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["ohotherpose"] = {"glap@oho-ther-waan-jiab", "oho-ther-waan-jiab_pose", "Oho ther waan jiab Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["theflash"] = {"glap@the-flash", "the-flash", "The Flash Fun", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["theghost"] = {"glap@the-ghost", "the-ghost", "The Ghost", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gingerdance"] = {"glap@ginger", "ginger_dance_clip", "Ginger Dance", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gingerwalk"] = {"glap@ginger", "ginger_walk_clip", "Ginger Walk", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["menbeaw"] = {"glap@menbeaw", "menbeaw_clip", "Menbeaw", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["wedhott"] = {"glap@wednesday_free", "wednesday_free_clip", "Wednesday Hot", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["slidez"] = {"glap@slide", "slide_clip", "Slide Short", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["slidelong"] = {"glap@slide-long", "slide_long_clip", "Slide Long", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["omg"] = {"sadg@omg_newjeans_by_renji", "omg_newjeans_clip", "OMG - Newjeans", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["kiddeema"] = {"jarp_kiddeemaidailoey", "jarp_kiddeemaidailoey_clip",  "Jarp Kid Dee Mai Dai Loey", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["nipose"] = {"nicoact@01forfree", "actfree1", "Nico Pose ACT1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["nipose2"] = {"nicoact@02forfree", "actfree2", "Nico Pose ACT2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["nipose3"] = {"nicoact@03forfree", "actfree3", "Nico Pose ACT3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["nipose4"] = {"nicoact@04forfree", "actfree4", "Nico Pose ACT4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["armageddon"] = {"glap@aespa-armageddon", "aespa-armageddon", "Armageddon", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["wop"] = {"jarp_wop", "jarp_wop_clip", "Nali", AnimationOptions =
    {
        EmoteLoop = true
    }},
    ["crossbounce"] = {"custom@crossbounce", "crossbounce", "Cross bounce", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dontstart"] = {"custom@dont_start", "dont_start", "Dont Start", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["rickroll"] = {"custom@rickroll", "rickroll", "Rick Roll", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["aroundtheclock"] = {"custom@around_the_clock", "around_the_clock", "Around the clock", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["fresh"] = {"custom@fresh_fortnite", "fresh_fortnite", "Fresh", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gylphic"] = {"custom@gylphic", "gylphic", "Glyphic", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["inparty"] = {"custom@in_da_party", "in_da_party", "In Da Party", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["robotdance"] = {"custom@robotdance_fortnite", "robotdance_fortnite", "Robot Dance", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["frightfunk"] = {"custom@frightfunk", "frightfunk", "Fright Funk", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gloss"] = {"custom@gloss", "gloss", "Gloss", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lastforever"] = {"custom@last_forever", "last_forever", "Last Forever", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["smoothmoves"] = {"custom@smooth_moves", "smooth_moves", "Smooth moves", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["introducing"] = {"custom@introducing", "introducing", "Introducing...", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["bellydance2"] = {"custom@bellydance2", "bellydance2", "Belly Dance 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["footwork"] = {"custom@footwork", "footwork", "Footwork", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["headspin"] = {"custom@headspin", "headspin", "Headspin", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = false,
    }},

    ["pumpup"] = {"custom@hiphop_pumpup", "hiphop_pumpup", "Hiphop Pumpup", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["hiphopyeah"] = {"custom@hiphop_yeah", "hiphop_yeah", "Hiphop Yeah", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = false,
    }},
    ["salsatime"] = {"custom@salsatime", "salsatime", "Salsa Time", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["samba"] = {"custom@samba", "samba", "·Samba", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["shockdance"] = {"custom@shockdance", "shockdance", "Shock Dance", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["specialdance"] = {"custom@specialdance", "specialdance", "Special Dance", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["toetwist"] = {"custom@toetwist", "toetwist", "Toe twist", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["whatislove"] = {"jarp_whatislove", "jarp_whatislove_clip",  "What is Love", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["trompetraka"] = {"ptrompetraka@animations", "ptrompetrakaclip", "PUBG 146 Trompet Raka Dance", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["plangit"] = {
        "pazeeetembaklangit@animations",
        "pazeeetembaklangitclip",
        "Tembak Langit Dance",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
}
CustomDP.AnimalEmotes = {
    ["chatsursaute"] = {
        "creatures@cat@amb@world_cat_sleeping_ground@exit",
        "exit_panic",
        "Chat - Sursauter de peur",
        AnimationOptions = { EmoteLoop = false }
    },
    ["chatallonger"] = {
        "creatures@cat@amb@world_cat_sleeping_ground@base",
        "base",
        "Chat - Allonger",
        AnimationOptions = { EmoteLoop = true }
    },
    ["chatettirement"] = {
        "creatures@cat@amb@peyote@enter",
        "enter",
        "Chat - Etirement",
        AnimationOptions = { EmoteLoop = false }
    }
}
CustomDP.Exits = {}
CustomDP.Emotes = {

    -- Emote pour l'item "bread" (utilisée par vfw:eat pour avoir un placement
    -- correct du prop pain). Placement basé sur l'emote "hotdog" qui utilise
    -- la même anim et un bone bouche similaire.
    ["bread"] = {
        "mp_player_inteat@burger",
        "mp_player_int_eat_burger",
        "Pain",
        AnimationOptions = {
            Prop = "prop_sandwich_01",
            PropBone = 60309,
            PropPlacement = {
                -0.03, 0.01, -0.01,
                95.1071, 94.7001, -66.9179
            },
            EmoteMoving = true,
            EmoteLoop = false
        }
    },

    ["newme1"] = {
        "lunyx@newme@p1",
        "newme@p1",
        "Girl Me Pose 1",
        AnimationOptions = {
            EmoteLoop = true
        }
    },

    ["newme2"] = {
        "lunyx@newme@p2",
        "newme@p2",
        "Girl Me Pose 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },

    ["newme3"] = {
        "lunyx@newme@p3",
        "newme@p3",
        "Girl Me Pose 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },

    ["newme4"] = {
        "lunyx@newme@p4",
        "newme@p4",
        "Girl Me Pose 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },

    ["newme5"] = {
        "lunyx@newme@p5",
        "newme@p5",
        "Girl Me Pose 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },

    ["eta1"] = {
        "lunyx@eta@p1",
        "eta@p1",
        "Girl Cute Peace Pose 1",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["eta2"] = {
        "lunyx@eta@p2",
        "eta@p2",
        "Girl Cute Peace Pose 2",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["eta3"] = {
        "lunyx@eta@p3",
        "eta@p3",
        "Girl Cute Peace Pose 3",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["eta4"] = {
        "lunyx@eta@p4",
        "eta@p4",
        "=Girl Cute Peace Pose 4",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["eta5"] = {
        "lunyx@eta@p5",
        "eta@p5",
        "Girl Cute Peace Pose 5",
        AnimationOptions = {
            EmoteLoop = true
        }
    },
    ["beagirlpo1"] = {"lunyx@iambeauty@p1", "iambeauty@p1", "Beauty Girl Pose 01", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo2"] = {"lunyx@iambeauty@p2", "iambeauty@p2", "Beauty Girl Pose 02", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo3"] = {"lunyx@iambeauty@p3", "iambeauty@p3", "Beauty Girl Pose 03", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo4"] = {"lunyx@iambeauty@p4", "iambeauty@p4", "Beauty Girl Pose 04", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo5"] = {"lunyx@iambeauty@p5", "iambeauty@p5", "Beauty Girl Pose 05", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo6"] = {"lunyx@iambeauty@p6", "iambeauty@p6", "Beauty Girl Pose 06", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo7"] = {"lunyx@iambeauty@p7", "iambeauty@p7", "Beauty Girl Pose 07", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo8"] = {"lunyx@iambeauty@p8", "iambeauty@p8", "Beauty Girl Pose 08", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["beagirlpo9"] = {"lunyx@iambeauty@p9", "iambeauty@p9", "Beauty Girl Pose 09", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["lnxpose1"] = {"lunyx@minipack@v1@pose001", "minipack@v1@pose001", "Girl Mini Pose 01", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["lnxpose2"] = {"lunyx@minipack@v1@pose002", "minipack@v1@pose002", "Girl Mini Pose 02", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["lnxpose3"] = {"lunyx@minipack@v1@pose003", "minipack@v1@pose003", "Girl Mini Pose 03", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["lnxpose4"] = {"lunyx@minipack@v1@pose004", "minipack@v1@pose004", "Girl Mini Pose 04", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["lnxpose5"] = {"lunyx@minipack@v1@pose005", "minipack@v1@pose005", "Girl Mini Pose 05", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["ceevon1"] = {"ceevon1@animation", "ceevon1_clip", "CeeVon", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["ceepappy1"] = {"ceepappy1@animation", "ceepappy1_clip", "CeePappy", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["ceeherbo1"] = {"ceeherbo1@animation", "ceeherbo1_clip", "CeeHerbo New", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["femltion"] = {
        "female_attention01@darksm",
        "female_attention01_clip",
        "Female Attention",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion1"] = {
        "female_attention02@darksm",
        "female_attention02_clip",
        "Female Attention 1",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion2"] = {
        "female_attention03@darksm",
        "female_attention03_clip",
        "Female Attention 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion3"] = {
        "female_attention04@darksm",
        "female_attention04_clip",
        "Female Attention 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion4"] = {
        "female_attention05@darksm",
        "female_attention05_clip",
        "Female Attention 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion5"] = {
        "female_attention06@darksm",
        "female_attention06_clip",
        "Female Attention 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion6"] = {
        "female_attention07@darksm",
        "female_attention07_clip",
        "Female Attention 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion7"] = {
        "female_attention08@darksm",
        "female_attention08_clip",
        "Female Attention 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion8"] = {
        "female_attention09@darksm",
        "female_attention09_clip",
        "Female Attention 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion9"] = {
        "female_attention10@darksm",
        "female_attention10_clip",
        "Female Attention 9",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion91"] = {
        "west_stand@darksj",
        "west_stand_clip",
        "Female Attention 10",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["femltion93"] = {
        "lean_mid@darksj",
        "lean_mid_clip",
        "Female Attention 12",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose31"] = {
        "glap@custom-pose-3",
        "custom-pose-3-1_clip",
        "Girl G Pose 3.1",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose32"] = {
        "glap@custom-pose-3",
        "custom-pose-3-2_clip",
        "Girl G Pose 3.2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose33"] = {
        "glap@custom-pose-3",
        "custom-pose-3-3_clip",
        "Girl G Pose 3.3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose34"] = {
        "glap@custom-pose-3",
        "custom-pose-3-4_clip",
        "Girl G Pose 3.4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose35"] = {
        "glap@custom-pose-3",
        "custom-pose-3-5_clip",
        "Girl G Pose 3.5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose36"] = {
        "glap@custom-pose-3",
        "custom-pose-3-6_clip",
        "Girl G Pose 3.6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose51"] = {
        "glap@custom-pose-5",
        "custom-pose-5-1-1_clip",
        "Girl G Pose 5.1.1",
        AnimationOptions =
        {
            Prop = "prop_chair_03",
            PropBone = 11816,
            PropPlacement = { 0.55, -0.18, 0.0, 25.19, -87.99, -535.36 },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose512"] = {
        "glap@custom-pose-5",
        "custom-pose-5-1-2_clip",
        "Girl G Pose 5.1.2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose52"] = {
        "glap@custom-pose-5",
        "custom-pose-5-2-1_clip",
        "Girl G Pose 5.2.1",
        AnimationOptions =
        {
            Prop = "prop_chair_03",
            PropBone = 11816,
            PropPlacement = { 0.55, -0.18, 0.0, 25.19, -87.99, -535.36 },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose522"] = {
        "glap@custom-pose-5",
        "custom-pose-5-2-2_clip",
        "Girl G Pose 5.2.2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose532"] = {
        "glap@custom-pose-5",
        "custom-pose-5-3-2_clip",
        "Girl G Pose 5.3.2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose54"] = {
        "glap@custom-pose-5",
        "custom-pose-5-4_clip",
        "Girl G Pose 5.4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["gcuspose55"] = {
        "glap@custom-pose-5",
        "custom-pose-5-5_clip",
        "Girl G Pose 5.5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["zlaying"] = {
        "timetable@ron@ig_3_couch",
        "laying",
        "Allongé",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["zcrouch"] = {
        "combat@chg_stance",
        "crouch",
        "Crouch Aim",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["zcarsleep"] = {
        "mp_cp_stolen_tut",
        "dazed",
        "Slep In Car",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["zhandsup2"] = {
        "mp_defend_base",
        "guard_handsup_loop",
        "Hands Up 2",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["sawatdee"] = {
        "fam_4_int_alt1-17",
        "cs_amandatownley_dual-17",
        "Sawadee Kha",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = true,
        }
    },
    ["sawatdee2"] = {
        "fos_ep_1_p1-26",
        "csb_imran_dual-26",
        "Sawadee Kha 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["ballerin"] = {
        "perlenfuchs@ballerina_1",
        "ballerina_1_clip",
        "Ballerin",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bball1"] = {
        "anim@male_basketball_01",
        "m_basketball_01_clip",
        "Basket Ball Pose 1",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bball2"] = {
        "anim@male_basketball_02",
        "m_basketball_02_clip",
        "Basket Ball Pose 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bball4"] = {
        "anim@male_basketball_04",
        "m_basketball_04_clip",
        "Basket Ball Pose 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bball5"] = {
        "anim@male_basketball_05",
        "m_basketball_05_clip",
        "Basket Ball Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bball6"] = {
        "anim@male_basketball_06",
        "m_basketball_06_clip",
        "Basket Ball Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bewithme"] = {
        "dollie_mods@follow_me_002",
        "follow_me_002",
        "Be With Me",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["bewithme2"] = {
        "tattooshowinn@animation",
        "tattooshowinn_clip",
        "Be With Me 2",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["bike"] = {
        "bike3@animation",
        "bike3_clip",
        "Bike",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["callme"] = {
        "divined@rpack@new",
        "callme",
        "Call Me",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["cantseeyou"] = {
        "perlenfuchs@cant_see_you_male",
        "cant_see_you_male_clip",
        "Can't See You",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["cantseeyou2"] = {
        "leangunanimation",
        "leangun_clip",
        "Can't See You 2",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["cantseeyou3"] = {
        "leanwoface@animation",
        "lean_clip",
        "Can't See You 3",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["cantseeyou5"] = {
        "pastelpistol@animation",
        "pastelpistol_clip",
        "Can't See You 5",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["carpose"] = {
        "anim@car_sitting_fuckyou",
        "sitting_fuckyou_clip",
        "Car Pose",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose2"] = {
        "anim@car_sitting_cute",
        "sitting_cute_clip",
        "Car Pose 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose3"] = {
        "anim@sit_cute_window",
        "cute_window_clip",
        "Car Pose 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose4"] = {
        "anim@female_selfie_1st_01",
        "f_selfie_1st_01_clip",
        "Car Pose 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose5"] = {
        "lunyx@random@v3@pose015",
        "random@v3@pose015",
        "Car Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose6"] = {
        "lunyx@random@v3@pose016",
        "random@v3@pose016",
        "Car Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose7"] = {
        "lunyx@random@v3@pose020",
        "random@v3@pose020",
        "Car Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carpose8"] = {
        "selfie@anim",
        "selfie_clip",
        "Car Pose 8",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["cloudgaze"] = {
        "switch@trevor@annoys_sunbathers",
        "trev_annoys_sunbathers_loop_girl",
        "Cloudgaze",
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
        "Cloudgaze 2",
        AnimationOptions = {
            EmoteLoop = true,
            StartDelay = 700,
            ExitEmote = "getup",
            ExitEmoteType = "Exits"
        }
    },
    ["cutepose4"] = {
        "mggymirror3@animation",
        "mggymirror3_clip",
        "Cute Pose 4",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerpose2"] = {
        "cripsgangsign@animation",
        "cripsgangsign_clip",
        "Finger Pose 2",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerpose3"] = {
        "ceek2animation",
        "ceek2_clip",
        "Finger Pose 3",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerpose6"] = {
        "posing3@animation",
        "posing3_clip",
        "Finger Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerpose9"] = {
        "rollz@leanmiddle",
        "leanmiddle_clip",
        "Finger Pose 9",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["fingerposes11"] = {
        "drillz@femalefuckoff_anim",
        "fuckoff_clip",
        "Finger Pose 11",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["fingerposes12"] = {
        "drillz@thebirdfemale_anim",
        "thebird_clip",
        "Finger Pose 12",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["fingerposes15"] = {
        "cast@sign1@animation",
        "cast@sign1_clip",
        "Finger Pose 15",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerposes16"] = {
        "bffcasualpose1@animation",
        "bffcasualpose1_clip",
        "Finger Pose 16",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerposes19"] = {
        "pose2@nyck",
        "pose2_clip",
        "Finger Pose 19",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fingerposess20"] = {
        "krank@animation",
        "krank_clip",
        "Finger Pose 20",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["floss"] = {
        "custom@floss",
        "floss",
        "Floss",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["freestyle"] = {
        "custom@freestyle_lxcky",
        "freestyle_clip",
        "Freestyle",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fsign"] = {
        "custom@fsign_1",
        "fsign_1",
        "Female Sign",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["fspose"] = {
        "missfam5_yoga",
        "c2_pose",
        "Female S Pose",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        },
    },
    ["fspose2"] = {
        "missfam5_yoga",
        "c6_pose",
        "Female S Pose 2",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        },
    },
    ["fspose3"] = {
        "anim@amb@carmeet@checkout_car@",
        "female_c_idle_d",
        "Female S Pose 3",
        AnimationOptions = {
            EmoteMoving = false,
            EmoteLoop = true,
            AdultAnimation = true
        },
    },
    ["fuchs"] = {
        "perlenfuchs@fxckyou",
        "fxckyou_clip",
        "Fuck 1",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fuchs2"] = {
        "perlenfuchs@fxckyou2",
        "fxckyou2_clip",
        "Fuck 2",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fuchs3"] = {
        "perlenfuchs@male_fxckyou",
        "male_fxckyou_clip",
        "Fuck 3",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["fuchs4"] = {
        "fuckpose@queensister",
        "fuckpose_clip",
        "Fuck 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["heart"] = {
        "heart@animation",
        "heart_clip",
        "Gang Heart",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["gymposes"] = {
        "divined@rpack@new",
        "burpee",
        "Gym 1",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["hd"] = {
        "hatsdown@animation",
        "hatsdown_clip",
        "Hats Down",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["heartpose1"] = {
        "syx@cute02",
        "cute02",
        "Heart Pose 1",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["heartpose2"] = {
        "syx@cute03",
        "cute03",
        "Heart Pose 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["heartpose3"] = {
        "syx@cute04",
        "cute04",
        "Heart Pose 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["heartpose4"] = {
        "lunyx@random@v3@pose010",
        "random@v3@pose010",
        "Heart Pose 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["heartpose5"] = {
        "lunyx@random@v3@pose011",
        "random@v3@pose011",
        "Heart Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["heartpose6"] = {
        "lunyx@random@v3@pose012",
        "random@v3@pose012",
        "Heart Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["heartpose7"] = {
        "chouko@freeheart",
        "freeheart",
        "Heart Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["jcarlowrider"] = {
        "anim@veh@lowrider@low@front_ds@arm@base",
        "sit",
        "Lowrider Style · Car",
        AnimationOptions =
        {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["jcarlowrider2"] = {
        "anim@veh@lowrider@std@ds@arm@music@mexicanidle_a",
        "idle",
        "Lowrider Style 2 · Car",
        AnimationOptions =
        {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["nekonew2"] = {
        "fos_ep_1_p1-0",
        "cs_lazlow_dual-0",
        "Neko New 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },

    ["nekonew3"] = {
        "fos_ep_1_p1-0",
        "csb_imran_dual-0",
        "Neko New 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },

    ["nekonew4"] = {
        "fos_ep_1_p1-1",
        "cs_lazlow_dual-1",
        "Neko New 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },

    ["nekonew5"] = {
        "fos_ep_1_p1-1",
        "csb_anita_dual-1",
        "Neko New 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },

    ["nekonew6"] = {
        "fos_ep_1_p1-1",
        "csb_imran_dual-1",
        "Neko New 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },

    ["nekonew7"] = {
        "fos_ep_1_p5-2",
        "csb_william_dual-2",
        "Neko New 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["nekonew8"] = {
        "timetable@trevor@ig_1",
        "ig_1_therearejustsomemoments_patricia",
        "Neko New 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["nekonew9"] = {
        "impexp_int_l1-11",
        "mp_m_waremech_01_dual-11",
        "Neko New 9",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["nekonew10"] = {
        "amb@prop_human_seat_computer@male@react_shock",
        "forward",
        "Neko New 10",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekonew11"] = {
        "amb@prop_human_seat_bar@male@elbows_on_bar@idle_b",
        "idle_d",
        "Neko New 11",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekonew12"] = {
        "amb@incar@male@security@idle_a",
        "idle_a",
        "Neko New 12",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekohelp"] = {
        "missheist_agency3aig_19",
        "ground_call_help",
        "Neko Help",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep3"] = {
        "missheist_agency3amcs_4b",
        "crew_dead_crew2",
        "Neko Sleep 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep4"] = {
        "missheist_jewel",
        "gassed_npc_customer1",
        "Neko Sleep 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep5"] = {
        "missheist_jewel",
        "gassed_npc_customer2",
        "Neko Sleep 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep6"] = {
        "missheist_jewel",
        "gassed_npc_customer3",
        "Neko Sleep 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep7"] = {
        "missheist_jewel",
        "gassed_npc_customer4",
        "Neko Sleep 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep8"] = {
        "missprologueig_6",
        "lying_dead_brad",
        "Neko Sleep 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekosleep9"] = {
        "missprologueig_6",
        "lying_dead_player0",
        "Neko Sleep 9",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekositpost8"] = {
        "missheistdockssetup1ig_10@base",
        "talk_pipe_base_worker1",
        "Neko Sit Post 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekositchair7"] = {
        "anim@amb@nightclub@smoking@",
        "blunt_idle_a",
        "Neko Sit Chair 7",
        AnimationOptions =
        {
            Prop = 'p_cs_joint_02',
            PropBone = 28422,
            PropPlacement = { 0.0800003, -0.004999998, -0.035, 175.5002, 311.0003, 232.0 },
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositchair8"] = {
        "anim@amb@nightclub@smoking@",
        "blunt_idle_b",
        "Neko Sit Chair 8",
        AnimationOptions =
        {
            Prop = 'p_cs_joint_02',
            PropBone = 28422,
            PropPlacement = { 0.0800003, -0.004999998, -0.035, 175.5002, 311.0003, 232.0 },
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["call"] = {
        "missheistdockssetup1ig_14",
        "floyd_ok_now_grab_the_container",
        "Neko Call",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekodrunk4"] = {
        "missheistpaletopinned",
        "pinned_against_wall_pro_loop_buddy",
        "Neko Drunk 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekoyoga6"] = {
        "misslamar1leadinout",
        "yoga_02_idle_b",
        "Neko Yoga 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekolieabout"] = {
        "missmic2ig_11",
        "mic_2_ig_11_a_p_one",
        "Neko Lie About",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekobundle"] = {
        "missprologueig_2",
        "idle_on_floor_gaurd",
        "Neko Bundle",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekobundle2"] = {
        "missprologueig_2",
        "idle_outside_cuboard_gaurd",
        "Neko Bundle 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["nekorod"] = {
        "misstrevor1ig_3",
        "action_b",
        "Neko Rod",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekocheck2"] = {
        "misstrevor3",
        "bike_chat_b_loop_1",
        "Neko Check 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekocheck3"] = {
        "misstvrram_5",
        "marines_idle_b",
        "Neko Check 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekonumb"] = {
        "mp_arrest_paired",
        "crook_p1_idle",
        "Neko Numb",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekonumb2"] = {
        "mp_cop_miss",
        "dazed",
        "Neko Numb 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["nekogivebirth"] = {
        "mini@cpr@char_a@cpr_str",
        "cpr_kol",
        "Neko Give Birth",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekotiedup"] = {
        "random@burial",
        "b_burial",
        "Neko Tied up",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["drink2"] = {
        "friends@frl@ig_1",
        "drink_lamar",
        "Neko Drink 2",
        AnimationOptions =
        {
            Prop = 'prop_beer_patriot',
            PropBone = 60309,
            PropPlacement = { -0.03499999, -0.165, -0.015, 436.7987, 412.3998, 177.4 },
            EmoteLoop = false,
            EmoteMoving = true,

        }
    },

    ["nekomc"] = {
        "anim@amb@nightclub@lazlow@ig1_vip@",
        "clubvip_dlg_tonymctony_laz",
        "Neko MC",
        AnimationOptions =
        {
            Prop = 'p_ing_microphonel_01',
            PropBone = 57005,
            PropPlacement = { 0.1249999, 0.03, -0.005000002, 87.10002, 149.8, 200.8 },
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekojump1"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "jump_d_player_a",
        "Neko Jump 1",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = false,

        }
    },

    ["nekojump2"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "jump_c_player_a",
        "Neko Jump 2",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = false,

        }
    },

    ["nekojump3"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "jump_b_player_a",
        "Neko Jump 3",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = false,

        }
    },

    ["nekojump4"] = {
        "anim@arena@celeb@flat@solo@no_props@",
        "jump_a_player_a",
        "Neko Jump 4",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = false,

        }
    },
    ["nekositmafia2"] = {
        "mini@strip_club@wade@",
        "leadin_loop_idle_a_wade",
        "Neko Sit Mafia 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["cheer2"] = {
        "mini@triathlon",
        "male_one_handed_a",
        "Neko Cheer 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["cheer3"] = {
        "mini@triathlon",
        "male_two_handed_a",
        "Neko Cheer 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekolean6"] = {
        "missarmenian1leadinoutarm_1_ig_14_leadinout",
        "leadin_loop",
        "Neko Lean 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoleanbar7"] = {
        "switch@michael@pier",
        "pier_lean_smoke_idle",
        "Neko Lean Bar 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },

    ["nekositmafia"] = {
        "safe@michael@ig_3",
        "cigar_idle_b_michael",
        "Neko Sit Mafia",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["smell2"] = {
        "safe@trevor@ig_8",
        "ig_8_huff_gas_player",
        "Neko Smell 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekofear"] = {
        "anim@heists@ornate_bank@hostages@cashier_b@",
        "flinch_loop_underfire",
        "Neko Fear",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekowipe"] = {
        "switch@franklin@cleaning_car",
        "001946_01_gc_fras_v2_ig_5_base",
        "Neko Wipe",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },

    ["nekositchair9"] = {
        "mini@strip_club@wade@",
        "leadin_loop_idle_a_stripper_a",
        "Neko Sit Chair 9",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["nekolean7"] = {
        "misscarsteal1car_1_ext_leadin",
        "base_driver1",
        "Neko Lean 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["dapap"] = {
        "misscarstealfinalecar_5_ig_3",
        "leanleft_loop",
        "Dapap",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["cool"] = {
        "misschinese1leadinoutchi_1_mcs_4",
        "chi_1_mcs_4_tao_idle_2",
        "Neko Cool",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekolean8"] = {
        "missclothing",
        "idle_a",
        "Neko Lean 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekolean9"] = {
        "missclothing",
        "idle_b",
        "Neko Lean 9",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekolean10"] = {
        "missclothing",
        "idle_c",
        "Neko Lean 10",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekosadly"] = {
        "missfam4leadinoutmcs2",
        "tracy_loop",
        "Neko Sadly",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoyoga2"] = {
        "missfam5_yoga",
        "c5_pose",
        "Neko Yoga 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoyoga3"] = {
        "missfam5_yoga",
        "c6_pose",
        "Neko Yoga 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoyoga4"] = {
        "missfam5_yoga",
        "c7_pose",
        "Neko Yoga 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekopost"] = {
        "missfbi4leadinoutfbi_4_int",
        "agents_idle_a_andreas",
        "Neko Post",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekomonkey"] = {
        "missfbi5ig_30monkeys",
        "monkey_a_freakout_loop",
        "Neko Monkey",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekomonkey2"] = {
        "missfbi5ig_30monkeys",
        "monkey_c_freakout_loop",
        "Neko Monkey 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekocry"] = {
        "missfinale_a_ig_2",
        "trevor_death_reaction_pt",
        "Neko Cry",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoreverence"] = {
        "missfra2",
        "lamar_base_idle",
        "Neko Reverence",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekopost2"] = {
        "misshair_shop@barbers",
        "keeper_base",
        "Neko Post 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekopost3"] = {
        "misshair_shop@hair_dressers",
        "keeper_idle_a",
        "Neko Post 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["clamber"] = {
        "missheist_agency3aig_19",
        "ground_call_help",
        "Neko Clamber",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekosleep2"] = {
        "missheist_jewel",
        "cop_on_floor",
        "Neko Sleep 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoyoga5"] = {
        "misslamar1leadinout",
        "yoga_01_idle",
        "Neko Yoga 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositchair10"] = {
        "misslester1aig_3main",
        "air_guitar_01_b",
        "Neko Sit Chair 10",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositchair11"] = {
        "misslester1aig_5intro",
        "boardroom_intro_f_b",
        "Neko Sit Chair 11",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositchair12"] = {
        "misslester1aig_5intro",
        "boardroom_intro_f_c",
        "Neko Sit Chair 12",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["dig2"] = {
        "missmic1leadinoutmic_1_mcs_2",
        "_leadin_trevor",
        "Neko Dig 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekowashface"] = {
        "missmic2_washing_face",
        "michael_washing_face",
        "Neko Wash Face",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekorepent"] = {
        "misstrevor1",
        "threaten_ortega_endloop_ort",
        "Neko Repent",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositchair13"] = {
        "misstrevor3",
        "bike_chat_a_1",
        "Neko Sit Chair 13",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekocheck"] = {
        "misstvrram_5",
        "marines_idle_b",
        "Neko Check",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekowash"] = {
        "timetable@floyd@clean_kitchen@idle_a",
        "idle_a",
        "Neko Wash",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },

    ["nekowash2"] = {
        "timetable@floyd@clean_kitchen@base",
        "base",
        "Neko Wash 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost"] = {
        "switch@michael@smoking2",
        "loop",
        "Neko Sit Post",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost2"] = {
        "switch@trevor@pushes_bodybuilder",
        "001426_03_trvs_5_pushes_bodybuilder_idle_bb2",
        "Neko Sit Post 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost3"] = {
        "timetable@reunited@ig_10",
        "base_jimmy",
        "Neko Sit Post 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost4"] = {
        "anim@heists@fleeca_bank@hostages@intro",
        "intro_loop_ped_a",
        "Neko Sit Post 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost5"] = {
        "anim@amb@office@pa@male@",
        "greetng_b_intro",
        "Neko Sit Post 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositmafia3"] = {
        "anim@amb@office@boss@female@",
        "idle_d",
        "Neko Sit Mafia 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost6"] = {
        "timetable@ron@ig_3_p3",
        "ig_3_p3_base",
        "Neko Sit Post 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositpost7"] = {
        "timetable@trevor@smoking_meth@idle_a",
        "idle_a",
        "Neko Sit Post 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekodrunk2"] = {
        "timetable@tracy@ig_7@base",
        "base",
        "Neko Drunk 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoverydrunk"] = {
        "timetable@tracy@ig_7@idle_a",
        "idle_a",
        "Neko Very Drunk",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekodrunk3"] = {
        "timetable@tracy@ig_7@idle_a",
        "idle_b",
        "Neko Drunk 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoparody"] = {
        "anim@mp_player_intupperthumb_on_ears",
        "idle_a",
        "Neko Parody",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekoparody2"] = {
        "anim@mp_player_intincarthumb_on_earsstd@ps@",
        "idle_a",
        "Neko Parody 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekoparody3"] = {
        "anim@mp_player_intincarfreakoutstd@rps@",
        "idle_a",
        "Neko Parody 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekoparody4"] = {
        "anim@mp_player_intcelebrationmale@thumb_on_ears",
        "thumb_on_ears",
        "Neko Parody 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekoparody5"] = {
        "anim@mp_player_intcelebrationfemale@thumb_on_ears",
        "thumb_on_ears",
        "Neko Parody 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekoshow"] = {
        "missfbi_s4mop",
        "lobby_security_fp_player",
        "Neko Show",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = true,

        }
    },
    ["nekopicksnot"] = {
        "anim@mp_player_intincarnose_pickstd@ps@",
        "exit",
        "Neko Pick Snot",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = true,

        }
    },
    ["nekoparody6"] = {
        "anim@mp_player_intincardockbodhi@rds@",
        "idle_a_fp",
        "Neko Parody 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekofear2"] = {
        "anim@heists@prison_heistunfinished_biz@popov_react",
        "popov_flinch_a",
        "Neko Fear 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekofear3"] = {
        "anim@heists@prison_heistunfinished_biz@popov_react",
        "popov_flinch_b",
        "Neko Fear 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoheartbroken"] = {
        "anim@heists@prison_heistig_5_p1_rashkovsky_idle",
        "idle",
        "Neko Heart Broken",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekofear4"] = {
        "anim@heists@ornate_bank@hostages@hit",
        "hit_loop_ped_c",
        "Neko Fear 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekofear5"] = {
        "anim@heists@ornate_bank@hostages@hit",
        "hit_loop_ped_d",
        "Neko Fear 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoincite"] = {
        "fos_ep_1_p5-1",
        "csb_anita_dual-1",
        "Neko Incite",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,

        }
    },
    ["nekomasturbate"] = {
        "switch@trevor@jerking_off",
        "trev_jerking_off_exit",
        "Neko Masturbate",
        AnimationOptions =
        {
            EmoteLoop = false,
            EmoteMoving = false,

        }
    },
    ["nekomasturbate2"] = {
        "switch@trevor@jerking_off",
        "trev_jerking_off_loop",
        "Neko Masturbate 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekositmassage"] = {
        "missheistdocks2aleadinoutlsdh_2a_int",
        "massage_loop_2_floyd",
        "Neko Sit Massage",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekomassage"] = {
        "missheistdocks2aleadinoutlsdh_2a_int",
        "massage_loop_2_trevor",
        "Neko Massage",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekomassage2"] = {
        "missheistdocks2aleadinoutlsdh_2a_int",
        "massage_loop_floyd",
        "Neko Massage 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekomassage3"] = {
        "missheistdocks2bleadinoutlsdh_2b_int",
        "leg_massage_b_floyd",
        "Neko Massage 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekomassage4"] = {
        "missheistdocks2bleadinoutlsdh_2b_int",
        "leg_massage_floyd",
        "Neko Massage 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["scrolling"] = {
        "scrollingpose@queensisters",
        "scrolling_clip",
        "Scrolling",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["selfiekylie"] = {
        "selfiekilye@queensisters",
        "kilye_clip",
        "Selfie Kylie",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sitkylie"] = {
        "sitkylie@queensisters",
        "kylie_clip",
        "Sit Kylie",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sitpose"] = {
        "perlenfuchs@sit_pose_peace1",
        "sit_pose_peace1_clip",
        "Sit Pose",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standbag"] = {
        "standbag1@blackqueen",
        "standbag1_clip",
        "Stand Bag",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standing"] = {
        "perlenfuchs@standing_wall2",
        "standing_wall2_clip",
        "Standing",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sport"] = {
        "perlenfuchs@sport_2",
        "sport_2_clip",
        "Sport",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["od"] = {
        "offthat@animation",
        "offthat_clip",
        "Off That",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["spider"] = {
        "spider42@animation",
        "spider42_clip",
        "Spider",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sexywall"] = {
        "perlenfuchs@sexy_wall",
        "sexy_wall_clip",
        "Sexywall",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["holdcap"] = {
        "perlenfuchs@hold_cap",
        "hold_cap_clip",
        "Holdcap",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["noface"] = {
        "noface2@spider",
        "noface2_clip",
        "No Face",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["posefuchs"] = {
        "perlenfuchs@pose3",
        "pose3_clip",
        "Posefuchs",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["malegun"] = {
        "perlenfuchs@male_gun",
        "male_gun_clip",
        "Malegun",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["lamp"] = {
        "perlenfuchs@lamp",
        "lamp_clip",
        "Lamp",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose6"] = {
        "pastelblood@animation",
        "pastelblood_clip",
        "Stand Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose146"] = {
        "banks@juiceplug",
        "banks2",
        "Stand Pose 146",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose147"] = {
        "banks@animation",
        "banks1",
        "Stand Pose 147",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose76"] = {
        "nocap5@animation",
        "nocap5_clip",
        "Random Pose 76",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sunbathe5"] = {
        "nocap7@animation",
        "nocap7_clip",
        "SunBathe 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose77"] = {
        "duoanim2@animation",
        "duoanim2_clip",
        "Random Pose 77",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose7"] = {
        "mvpsign3@animacion",
        "mvpsign3_clip",
        "Stand Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose15"] = {
        "69nine@animation",
        "69nine_clip",
        "Stand Pose 15",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose19"] = {
        "chillpose@animation",
        "chillpose_clip",
        "Stand Pose 19",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose58"] = {
        "couple1@animation",
        "couple1_clip",
        "Stand Pose 58",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose140"] = {
        "couple2@animation",
        "couple2_clip",
        "Random Pose 14",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose61"] = {
        "maosnobolso@animation",
        "maosnobolso_clip",
        "Stand Pose 61",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["standpose62"] = {
        "paspose@animation",
        "paspose_clip",
        "Stand Pose 62",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["metal5"] = {
        "gangpose@animation",
        "gangpose_clip",
        "Metal 5",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose127"] = {
        "ohgeesy@animation",
        "ohgeesy_clip",
        "Stand Pose 127",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose130"] = {
        "pasteldedos2@animation",
        "pasteldedos2_clip",
        "Stand Pose 130",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose29"] = {
        "lukitophoto2@animation",
        "lukitophoto2_clip",
        "Random Pose 29",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose132"] = {
        "wristcheck@animation",
        "wristcheck_clip",
        "Stand Pose 132",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose133"] = {
        "crossfinger@animation",
        "crossfinger_clip",
        "Stand Pose 133",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose30"] = {
        "seat1@animation",
        "seat1_clip",
        "Random Pose 30",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose136"] = {
        "pose@nyck",
        "pose_clip",
        "Stand Pose 136",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose137"] = {
        "pose3@nyck",
        "pose3_clip",
        "Stand Pose 137",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose14"] = {
        "bkcr@animation",
        "bkcr_clip",
        "Sit Pose 14",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose141"] = {
        "bangin@casual",
        "girl_clip",
        "Stand Pose 141",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose142"] = {
        "bangin@casual",
        "man_clip",
        "Stand Pose 142",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose31"] = {
        "hood@casual",
        "girl_clip",
        "Random Pose 31",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose143"] = {
        "hood@casual",
        "male_clip",
        "Stand Pose 14",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose34"] = {
        "fuckb@animation",
        "fuckb_clip",
        "Random Pose 34",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose35"] = {
        "grabber@animation",
        "grabber_clip",
        "Random Pose 35",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose36"] = {
        "mfnapk@animation",
        "mfnapk_clip",
        "Random Pose 36",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose37"] = {
        "neighbour@animation",
        "neighbour_clip",
        "Random Pose 37",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose38"] = {
        "nonapps@animation",
        "nonapps_clip",
        "Random Pose 38",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose40"] = {
        "holdhip@animation",
        "holdhip_clip",
        "Hold Hips Pose",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose41"] = {
        "holdhipb@animation",
        "holdhipb_clip",
        "Standing Elegant Pose",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose42"] = {
        "holdass@animation",
        "holdass_clip",
        "Random Pose 42",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose43"] = {
        "holdassb@animation",
        "holdassb_clip",
        "Random Pose 43",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose15"] = {
        "coupleseat1@animation",
        "coupleseat1_clip",
        "Sti Pose 15",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose16"] = {
        "mymsign30@animacion",
        "mymsign30_clip",
        "Sit Pose 16",
        AnimationOptions =
        {
            EmoteLoop = false,
        }
    },
    ["randompose44"] = {
        "coupleseat1b@animation",
        "coupleseat1b_clip",
        "Random Pose 44",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose46"] = {
        "crshx2@fix",
        "fix",
        "Random Pose 46",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose47"] = {
        "mymsign1@animacion",
        "mymsign1_clip",
        "Random Pose 47",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose48"] = {
        "mymsign20@animacion",
        "mymsign20_clip",
        "Random Pose 48",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose51"] = {
        "duoanim1@animation",
        "duoanim1_clip",
        "Random Pose 51",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose53"] = {
        "bloodkiller@marisfreegpack",
        "bloodkiller",
        "Random Pose 53",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["randompose54"] = {
        "mafiacrip@marisfreegsignpack",
        "mafiacrip",
        "Random Pose 54",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["randompose55"] = {
        "cripkiller@marisgfreepack",
        "cripkiller",
        "Random Pose 55",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose59"] = {
        "43_gangster@crip",
        "43_gangster",
        "Random Pose 59",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose60"] = {
        "cripkiler@marisfreegsigns",
        "cripkiler",
        "Random Pose 60",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose64"] = {
        "anim@nayba",
        "nayba_clip",
        "Random Pose 64",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose67"] = {
        "sensual1@casual",
        "girl_clip",
        "Random Pose 67",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose68"] = {
        "sensual1@casual",
        "man_clip",
        "Random Pose 68",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose70"] = {
        "downfingers@dreamdel",
        "dreamdel_clip",
        "Random Pose 70",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose71"] = {
        "woopose@custom_anim",
        "woo_clip",
        "Random Pose 71",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose72"] = {
        "sekposev3@animation",
        "v3",
        "Random Pose 72",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose73"] = {
        "sekpose2v3@animation",
        "v3",
        "Random Pose 73",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose74"] = {
        "sekpose2@animation",
        "clip",
        "Random Pose 74",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose75"] = {
        "doubleo@animation",
        "doubleo_clip",
        "Random Pose 75",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose9"] = {
        "whiskaspose2@stand",
        "whiskaspose2_makebywhiskas",
        "Stand Pose 9",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose11"] = {
        "holdracks@animation",
        "rackz_clip",
        "Stand Pose 11",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose12"] = {
        "customdeneme@anim",
        "customdeneme_clip",
        "Stand Pose 12",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose13"] = {
        "nhoneanimation",
        "nhone_clip",
        "Stand Pose 13",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose14"] = {
        "drillz@headtilt_anim",
        "headtilt_clip",
        "Stand Pose 14",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose5"] = {
        "drillz@laydown_anim",
        "laydown_clip",
        "Random Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["stoppose1"] = {
        "drillz@selfiewall_anim",
        "selfiewall_clip",
        "Stop Pose 1",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose5"] = {
        "drillz@leanfemalesit_anim",
        "leanfemalesit_clip",
        "Sit Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["stoppose2"] = {
        "drillz@ruby_anim",
        "ruby_clip",
        "Stop Pose 2",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose"] = {"posing1@animation", "posing1_clip", "Custom120", AnimationOptions =
    {
        EmoteLoop = true,
    }
    },
    ["standpose16"] = {
        "posing2@animation",
        "posing2_clip",
        "Stand Pose 16",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose17"] = {
        "ney3@animation",
        "ney_clip",
        "Stand Pose 17",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["peacepose4"] = {
        "rollz@walkpeace",
        "walkpeace_clip",
        "Peace Pose 4",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose18"] = {
        "ney@animation",
        "ney_clip",
        "Stand Pose 18",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose20"] = {
        "esse@drakowall",
        "drakowall_clip",
        "Stand Pose 20",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose21"] = {
        "nbn@animation",
        "nbn_clip",
        "Stand Pose 21",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose22"] = {
        "wrldmods@trippieredd",
        "trippieredd",
        "Stand Pose 22",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose6"] = {
        "lunyx@random001",
        "random001",
        "Random Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose23"] = {
        "lunyx@random002",
        "random002",
        "Stand Pose 23",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose24"] = {
        "lunyx@random003",
        "random003",
        "Stand Pose 24",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose7"] = {
        "leanganglit@animation",
        "leanganglit_clip",
        "Random Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose26"] = {
        "doublec@animation",
        "doublec_clip",
        "Stand Pose 26",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose27"] = {
        "handsup@animation",
        "handsup_clip",
        "Stand Pose 27",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose9"] = {
        "syx@kiss02a",
        "kiss02a",
        "Random Pose 9",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose10"] = {
        "syx@kiss02b",
        "kiss02b",
        "Random Pose 10",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["peacepose5"] = {
        "syx@cute01",
        "cute01",
        "Peace Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["peacepose6"] = {
        "syx@cute05",
        "cute05",
        "Peace Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose30"] = {
        "moneyspread1@animation",
        "moneyspread1_clip",
        "Stand Pose 30",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["randompose11"] = {
        "divined@rpack@new",
        "alchemy",
        "Random Pose 11",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["huh"] = {
        "divined@rpack@new",
        "badmood",
        "Huh Pose",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["rabbitpose"] = {
        "divined@rpack@new",
        "bunnyhop",
        "Rabbit Pose 1",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["giveme"] = {
        "divined@rpack@new",
        "coronet",
        "Give Me 1",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["cryinghard"] = {
        "divined@rpack@new",
        "dcry",
        "Cry So Hard",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["stoppose3"] = {
        "divined@rpack@new",
        "hailcab",
        "Stop Pose 3",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["maung"] = {
        "divined@rpack@new",
        "kepler",
        "Maung",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["magic"] = {
        "divined@rpack@new",
        "mindblown",
        "Magic Pose 1",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["fightme"] = {
        "divined@rpack@new",
        "uproar",
        "Fight Me 1",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["standpose31"] = {
        "rollz@twofingers",
        "twofingers_clip",
        "Stand Pose 31",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["standpose32"] = {
        "nhcanimation",
        "nhc_clip",
        "Stand Pose 32",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["standpose35"] = {
        "drillz@fucktheopps_anim",
        "fucktheopps_clip",
        "Stand Pose 35",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["sitpose6"] = {
        "drillz@fuckyou_anim",
        "fuckyou_clip",
        "Sit Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["standpose085"] = {
        "drillz@oneleg_anim",
        "oneleg_clip",
        "Stand Pose",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["standpose37"] = {
        "cosmocrippah",
        "crippah_clip",
        "Stand Pose 37",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["standpose40"] = {
        "anim@fog_rifle_relaxed",
        "rifle_relaxed_clip",
        "Stand Pose 40",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose41"] = {
        "anim@stack_pointman",
        "pointman_clip",
        "Stand Pose 41",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose42"] = {
        "anim@stack_two_man",
        "two_man_clip",
        "Stand Pose 42",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose43"] = {
        "anim@stack_three_man",
        "three_man_clip",
        "Stand Pose 43",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sexyposex1"] = {
        "anim@model_car_fancy",
        "car_fancy_clip",
        "Sexy Pose X 1",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sexyposex2"] = {
        "anim@model_stretched_leg",
        "stretched_leg_clip",
        "Sexy Pose X 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose47"] = {
        "anim@model_bike",
        "bike_clip",
        "Stand Pose 47",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["randompose12"] = {
        "anim@model_bike_two",
        "bike_two_clip",
        "Random Pose 12",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["peacepose7"] = {
        "anim@peace_selfie",
        "peace_clip",
        "Peace Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["peacepose8"] = {
        "anim@stance_folded_arms",
        "folded_arms_clip",
        "Peace Pose 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sexyposex3"] = {
        "anim@stance_kneeling_cute",
        "kneeling_cute_clip",
        "Sexy Pose X 3",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sitpose7"] = {
        "anim@car_cute_sit",
        "cute_sit_clip",
        "Sit Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose48"] = {
        "anim@female_smoke_01",
        "f_smoke_01_clip",
        "Stand Pose 48",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sitpose8"] = {
        "anim@selfie_knees_cute",
        "knees_cute_clip",
        "Sit Pose 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["leanx6"] = {
        "anim@sw_sit_chill",
        "sit_chill_clip",
        "Lean X 6",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose52"] = {
        "anim@sw_chill_pose",
        "chill_pose_clip",
        "Stand Pose 52",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sexyposex4"] = {
        "thot_pose",
        "thot_clip",
        "Sexy Pose X 4",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose53"] = {
        "lunyx@random@v3@pose001",
        "random@v3@pose001",
        "Stand Pose 53",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["standpose54"] = {
        "lunyx@random@v3@pose002",
        "random@v3@pose002",
        "Stand Pose 54",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["standpose55"] = {
        "lunyx@random@v3@pose003",
        "random@v3@pose003",
        "Girly Stand Pose 7",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose56"] = {
        "lunyx@random@v3@pose004",
        "random@v3@pose004",
        "Girly Stand Pose 8",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["sexyposex5"] = {
        "lunyx@random@v3@pose005",
        "random@v3@pose005",
        "Sexy Pose X 5",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["standpose57"] = {
        "lunyx@random@v3@pose006",
        "random@v3@pose006",
        "Stand Pose 57",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["peacepose9"] = {
        "lunyx@random@v3@pose007",
        "random@v3@pose007",
        "Peace Pose 9",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },

    ["peacepose10"] = {
        "lunyx@random@v3@pose008",
        "random@v3@pose008",
        "Peace Pose 10",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["metal2"] = {
        "lunyx@random@v3@pose009",
        "random@v3@pose009",
        "Metal 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["metal3"] = {
        "nhyza1@animation",
        "nhyza1_clip",
        "Metal 3",
        AnimationOptions =
        {
            EmoteLoop = false,
        }
    },
    ["peacepose11"] = {
        "lunyx@random@v3@pose013",
        "random@v3@pose013",
        "Peace Pose 11",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["peacepose12"] = {
        "lunyx@random@v3@pose014",
        "random@v3@pose014",
        "Peace Pose 12",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["standpose64"] = {
        "lunyx@random@v3@pose017",
        "random@v3@pose017",
        "Stand Pose 64",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["randompose14"] = {
        "lunyx@random@v3@pose018",
        "random@v3@pose018",
        "Random Pose 14",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["standpose65"] = {
        "lunyx@random@v3@pose019",
        "random@v3@pose019",
        "Stand Pose 65",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["standpose66"] = {
        "testanim@alina",
        "testanim_clip",
        "Girly Stand Pose 6",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose9"] = {
        "hoe@anim",
        "hoe_clip",
        "Sit Pose 9",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose10"] = {
        "hoe2@anim",
        "hoe2_clip",
        "Sit Pose 10",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sexyposex6"] = {
        "expertmode@anim",
        "expertmode_clip",
        "Sexy Pose X 6",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose67"] = {
        "pose1@anim",
        "pose1_clip",
        "Girly Stand Pose 9",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose68"] = {
        "1foot@anim",
        "1foot_clip",
        "Stand Pose 68",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose16"] = {
        "car1@anim",
        "car1_clip",
        "Random Pose 16",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose69"] = {
        "selfie2@anim",
        "selfie2_clip",
        "Stand Pose 69",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose70"] = {
        "randompose1@anim",
        "randompose1_clip",
        "Stand Pose 70",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose71"] = {
        "randompose2@anim",
        "randompose2_clip",
        "Stand Pose 71",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose18"] = {
        "stripper1@anim",
        "stripper1_clip",
        "Random Pose 18",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sexyposex7"] = {
        "strip2@anim",
        "strip2_clip",
        "Sexy Pose X 7",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose72"] = {
        "pose5@anim",
        "pose5_clip",
        "Girly Stand Pose 10",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think6"] = {
        "slavepose@anim",
        "slavepose_clip",
        "Think 6",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose74"] = {
        "stanleylebougla@animation",
        "stanleylebougla_clip",
        "Stand Pose 74",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["pointpose"] = {
        "217aim2xanimation",
        "aim2x_clip",
        "Point Pose",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose75"] = {
        "dollie_mods@follow_me_001",
        "follow_me_001",
        "Stand Pose 75",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["think7"] = {
        "amb@world_human_hang_out_street@male_a@base",
        "base",
        "Think 7",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think8"] = {
        "amb@world_human_hang_out_street@male_a@enter",
        "enter",
        "Think 8",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think9"] = {
        "amb@world_human_hang_out_street@male_a@exit",
        "exit",
        "Think 9",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think10"] = {
        "amb@world_human_hang_out_street@male_a@idle_a",
        "idle_a",
        "Think 10",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think11"] = {
        "amb@world_human_hang_out_street@male_a@idle_a",
        "idle_b",
        "Think 11",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think12"] = {
        "amb@world_human_hang_out_street@male_a@idle_a",
        "idle_c",
        "Think 12",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["think13"] = {
        "amb@world_human_hang_out_street@male_a@idle_a",
        "idle_d",
        "Think 13",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose76"] = {
        "amb@world_human_hang_out_street@male_b@base",
        "base",
        "Stand Pose 76",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose77"] = {
        "amb@world_human_hang_out_street@male_b@enter",
        "enter",
        "Stand Pose 77",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose78"] = {
        "amb@world_human_hang_out_street@male_b@exit",
        "exit",
        "Stand Pose 78",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose79"] = {
        "amb@world_human_hang_out_street@male_b@idle_a",
        "idle_a",
        "Stand Pose 79",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose80"] = {
        "amb@world_human_hang_out_street@male_b@idle_a",
        "idle_b",
        "Stand Pose 80",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles12"] = {
        "amb@world_human_hang_out_street@male_b@idle_a",
        "idle_c",
        "Idle 12",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles13"] = {
        "amb@world_human_hang_out_street@male_b@idle_a",
        "idle_d",
        "Idle 13",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles14"] = {
        "amb@world_human_hang_out_street@male_c@base",
        "base",
        "Idle 14",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles15"] = {
        "amb@world_human_hang_out_street@male_c@enter",
        "enter",
        "Idle 15",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles16"] = {
        "amb@world_human_hang_out_street@male_c@exit",
        "exit",
        "Idle 16",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles17"] = {
        "amb@world_human_hang_out_street@male_c@idle_a",
        "idle_a",
        "Idle 17",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles18"] = {
        "amb@world_human_hang_out_street@male_c@idle_a",
        "idle_b",
        "Idle 18",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles19"] = {
        "amb@world_human_hang_out_street@male_c@idle_a",
        "idle_c",
        "Idle 19",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles20"] = {
        "amb@world_human_hang_out_street@male_c@idle_a",
        "idle_d",
        "Idle 20",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles21"] = {
        "amb@world_human_hang_out_street@female_arm_side@base",
        "base",
        "Idle 21",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles24"] = {
        "amb@world_human_hang_out_street@female_arm_side@idle_a",
        "idle_a",
        "Idle 24",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles25"] = {
        "amb@world_human_hang_out_street@female_arm_side@idle_a",
        "idle_b",
        "Idle 25",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles26"] = {
        "amb@world_human_hang_out_street@female_arm_side@idle_a",
        "idle_c",
        "Idle 26",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles27"] = {
        "amb@world_human_hang_out_street@female_arm_side@idle_a",
        "idle_d",
        "Idle 27",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles28"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@base",
        "base",
        "Idle 28",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles29"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@enter",
        "enter",
        "Idle 29",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles30"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@exit",
        "exit",
        "Idle 30",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles31"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
        "idle_a",
        "Idle 31",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles32"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
        "idle_b",
        "Idle 32",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles33"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
        "idle_c",
        "Idle 33",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles34"] = {
        "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
        "idle_d",
        "Idle 34",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles35"] = {
        "amb@world_human_hang_out_street@female_hold_arm@base",
        "base",
        "Idle 35",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles36"] = {
        "amb@world_human_hang_out_street@female_hold_arm@enter",
        "enter",
        "Idle 36",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles37"] = {
        "amb@world_human_hang_out_street@female_hold_arm@exit",
        "exit",
        "Idle 37",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles38"] = {
        "amb@world_human_hang_out_street@female_hold_arm@idle_a",
        "idle_a",
        "Idle 38",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles39"] = {
        "amb@world_human_hang_out_street@female_hold_arm@idle_a",
        "idle_b",
        "Idle 39",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles40"] = {
        "amb@world_human_hang_out_street@female_hold_arm@idle_a",
        "idle_c",
        "Idle 40",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["idles41"] = {
        "amb@world_human_hang_out_street@female_hold_arm@idle_a",
        "idle_d",
        "Idle 41",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose81"] = {
        "chouko@nailpose",
        "nailpose",
        "Stand Pose 81",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["naruto"] = {
        "chid@nyck",
        "chid_clip",
        "Naruto",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose85"] = {
        "qpacc@gangsign5",
        "gangsign5_clip",
        "Stand Pose 85",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose88"] = {
        "qpacc@gangsign8",
        "gangsign8_clip",
        "Stand Pose 88",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose90"] = {
        "mymsign67@animacion",
        "mymsign67_clip",
        "Stand Pose 90",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose20"] = {
        "bendover@sign@animation",
        "bendover@sign_clip",
        "Random Pose 20",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose94"] = {
        "standhand2animation",
        "standhand2_clip",
        "Stand Pose 94",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose96"] = {
        "tidselfie01@animation",
        "tidselfie01_clip",
        "Stand Pose 96",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["peacepose13"] = {
        "mggyhang1@animation",
        "mggyhang1_clip",
        "Peace Pose 13",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose11"] = {
        "mggyhang2@animation",
        "mggyhang2_clip",
        "Sit Pose 11",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose97"] = {
        "mggyhang3@animation",
        "mggyhang3_clip",
        "Stand Pose 97",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose98"] = {
        "mggypiggypair1@animation",
        "mggypiggypair1_clip",
        "Stand Pose 98",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose21"] = {
        "mggypiggypair2@animation",
        "mggypiggypair2_clip",
        "Random Pose 21",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose99"] = {
        "mggyselfie1@animation",
        "mggyselfie1_clip",
        "Stand Pose 99",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose100"] = {
        "mggyselfie2@animation",
        "mggyselfie2_clip",
        "Stand Pose 100",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose22"] = {
        "custom@animation",
        "sitting_clip",
        "Random Pose 22",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sunbathe4"] = {
        "slave@mchmnk",
        "slave_clip",
        "Sunbathe 4",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose23"] = {
        "coupleero01fr@mchmnk",
        "coupleero01fr_clip",
        "Random Pose 23",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose24"] = {
        "coupleero01tw@mchmnk",
        "coupleero01tw_clip",
        "Random Pose 24",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sexyposex8"] = {
        "waitingfordaddy@mchmnk",
        "waitingfordaddy_clip",
        "Sexy Pose X 8",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose12"] = {
        "tidsitting07@animation",
        "tidsitting07_clip",
        "Sit Pose 12",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose102"] = {
        "tidstanding11@animation",
        "tidstanding11_clip",
        "Girly Stand Pose 5",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose103"] = {
        "tidstanding14@animation",
        "tidstanding14_clip",
        "Girly Stand Pose 4",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose104"] = {
        "tidstanding15@animation",
        "tidstanding15_clip",
        "Girly Stand Pose 3",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose105"] = {
        "tidstandingselfie11@animation",
        "tidstandingselfie11_clip",
        "Girly Stand Pose 2",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose106"] = {
        "tidstandingselfie12@animation",
        "tidstandingselfie12_clip",
        "Girly Stand Pose",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose108"] = {
        "cas2animation",
        "cas2_clip",
        "Stand Pose 108",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose109"] = {
        "salutepose@animation",
        "salutepose_clip",
        "Stand Pose 109",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose111"] = {
        "femalepose6@animation",
        "femalepose6_clip",
        "Stand Pose 111",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose112"] = {
        "femalepose5@animation",
        "femalepose5_clip",
        "Stand Pose 112 Female",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose113"] = {
        "freeanim1animation",
        "freeanim1_clip",
        "Stand Pose 113",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose25"] = {
        "crouchinganimation",
        "crouching_clip",
        "Random Pose 25",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose26"] = {
        "mggycas2@animation",
        "mggycas2_clip",
        "Random Pose 26",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose115"] = {
        "mggycas1@animation",
        "mggycas1_clip",
        "Stand Pose 115",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["sitpose13"] = {
        "mggymirror4@animation",
        "mggymirror4_clip",
        "Sit Pose 13",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["peacepose14"] = {
        "mggymirror2@animation",
        "mggymirror2_clip",
        "Peace Pose 14",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose116"] = {
        "mggymirror1@animation",
        "mggymirror1_clip",
        "Stand Pose 116",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose117"] = {
        "bfflookback1@animation",
        "bfflookback1_clip",
        "Stand Pose 117",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose118"] = {
        "bfflookback2@animation",
        "bfflookback2_clip",
        "Stand Pose 118",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },

    ["standpose119"] = {
        "bffcasualpose2@animation",
        "bffcasualpose2_clip",
        "Stand Pose 119",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["randompose28"] = {
        "bfffun2@animation",
        "bfffun2_clip",
        "Random Pose 28",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["peacepose15"] = {
        "bffhandhold1@animation",
        "bffhandhold1_clip",
        "Peace Pose 15",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["peacepose16"] = {
        "bffhandhold2@animation",
        "bffhandhold2_clip",
        "Peace Pose 16",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["standpose120"] = {
        "mggycouplehug1@animation",
        "mggycouplehug1_clip",
        "Stand Pose 120",
        AnimationOptions =
        {
            EmoteLoop = true,
        }
    },
    ["jpbox"] = {
        "mp_am_hold_up",
        "purchase_beerbox_shopkeeper",
        "Purchase Box",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jch"] = {
        "amb@code_human_police_investigate@idle_b",
        "idle_f",
        "Cop Search",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 7000,
        }
    },
    ["jcheckwatch"] = {
        "amb@code_human_wander_idles_fat@male@idle_a",
        "idle_a_wristwatch",
        "Check Watch · Male",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jgangaim"] = {
        "combat@aim_variations@1h@gang",
        "aim_variation_b",
        "Gang Aim",
        AnimationOptions =
        {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["jcleanleg"] = {
        "mini@strip_club@backroom@",
        "stripper_c_leadin_backroom_idle_a",
        "Clean Legs",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 6000,
        }
    },
    ["jkhaby"] = {
        "missarmenian3@simeon_tauntsidle_b",
        "areyounotman",
        "Khaby · Special",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jdepressed"] = {
        "oddjobs@bailbond_hobodepressed",
        "base",
        "Depressed",
        AnimationOptions =
        {
            EmoteMoving = true,
        }
    },
    ["jreactiona"] = {
        "random@shop_robbery_reactions@",
        "absolutely",
        "Reaction Absolutely",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactanger"] = {
        "random@shop_robbery_reactions@",
        "anger_a",
        "Reaction Anger",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactwhy"] = {
        "random@shop_robbery_reactions@",
        "is_this_it",
        "Reaction Why",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactscrew"] = {
        "random@shop_robbery_reactions@",
        "screw_you",
        "Reaction Screw You",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactshock"] = {
        "random@shop_robbery_reactions@",
        "shock",
        "Reaction Shock",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactgoodc"] = {
        "missclothing",
        "good_choice_storeclerk",
        "Reaction Good Choice",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreacteasy"] = {
        "gestures@m@car@std@casual@ds",
        "gesture_easy_now",
        "Reaction Easy Now",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactıwill"] = {
        "gestures@m@car@std@casual@ds",
        "gesture_i_will",
        "Reaction I Will",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactnoway"] = {
        "gestures@m@car@std@casual@ds",
        "gesture_no_way",
        "Reaction No Way",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactbye"] = {
        "gestures@f@standing@casual",
        "gesture_bye_hard",
        "Reaction Bye Hard",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jlookatplayer"] = {
        "friends@frl@ig_1",
        "look_lamar",
        "Look At Player",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jreactgreat"] = {
        "mp_cp_welcome_tutgreet",
        "greet",
        "Great",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jtryshirtn"] = {
        "clothingshirt",
        "try_shirt_negative_a",
        "Try Shirt Negative",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jtryshirtp"] = {
        "clothingshirt",
        "try_shirt_positive_a",
        "Try Shirt Positive",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jtryshoes"] = {
        "clothingshoes",
        "try_shoes_positive_d",
        "Try Shoes",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jtryshoes2"] = {
        "clothingshoes",
        "try_shoes_positive_c",
        "Try Shoes 2",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jwashingface"] = {
        "missmic2_washing_face",
        "michael_washing_face",
        "Washing Face",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jlastday"] = {
        "misstrevor1",
        "ortega_outro_loop_ort",
        "Last Day",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jtryg"] = {
        "mp_clothing@female@glasses",
        "try_glasses_positive_a",
        "Try Glasses · Female",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jpickup"] = {
        "pickup_object",
        "pickup_low",
        "Pick Up",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jstretchl"] = {
        "switch@franklin@bed",
        "stretch_long",
        "Stretch Long",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jhos"] = {
        "amb@world_human_hang_out_street@male_a@idle_a",
        "idle_a",
        "Hang Out Street · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jhos2"] = {
        "amb@world_human_hang_out_street@male_c@base",
        "base",
        "Hang Out Street 2 · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jguardaim"] = {
        "guard_reactions",
        "1hand_aiming_cycle",
        "Guard Aim",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jgready"] = {
        "switch@franklin@getting_ready",
        "002334_02_fras_v2_11_getting_dressed_exit",
        "Getting Ready",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jlao"] = {
        "move_clown@p_m_two_idles@",
        "fidget_look_at_outfit",
        "Look At Outfits",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 6000,
        }
    },
    ["jtoilet"] = {
        "switch@trevor@on_toilet",
        "trev_on_toilet_loop",
        "Have A Shit",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jtoilet2"] = {
        "timetable@trevor@on_the_toilet",
        "trevonlav_struggleloop",
        "Have A Shit 2",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jcovermale2"] = {
        "amb@code_human_cower@male@base",
        "base",
        "Cover · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jsunbathem"] = {
        "amb@world_human_sunbathe@male@back@idle_a",
        "idle_c",
        "Sunbathe · Male",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["jsunbathem2"] = {
        "amb@world_human_sunbathe@male@front@base",
        "base",
        "Sunbathe 2 · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jleancar"] = {
        "anim@scripted@carmeet@tun_meet_ig2_race@",
        "base",
        "Lean Car",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["jcheckout3"] = {
        "anim@amb@carmeet@checkout_car@female_d@base",
        "base",
        "Check Out 3 · Female",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jlistenmusic"] = {
        "anim@amb@carmeet@listen_music@male_a@trans",
        "a_trans_d",
        "Listen Music",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jogger"] = {
        "move_f@jogger",
        "idle",
        "Jogger · Female",
        AnimationOptions =
        {
            EmoteDuration = 2500,
            EmoteMoving = true,
        }
    },
    ["jogger2"] = {
        "move_m@jogger",
        "idle",
        "Jogger · Male",
        AnimationOptions =
        {
            EmoteDuration = 2500,
            EmoteMoving = true,
        }
    },
    ["jwtf"] = {
        "mini@triathlon",
        "wot_the_fuck",
        "Wot The Fuck",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jucdt"] = {
        "mini@triathlon",
        "u_cant_do_that",
        "U Cant Do That",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jwarmup"] = {
        "mini@triathlon",
        "ig_2_gen_warmup_01",
        "Warmup",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jwarmup2"] = {
        "mini@triathlon",
        "ig_2_gen_warmup_02",
        "Warmup 2",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jwarmup3"] = {
        "mini@triathlon",
        "jog_idle_f",
        "Warmup 3",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jwarmup4"] = {
        "mini@triathlon",
        "jog_idle_e",
        "Warmup 4",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jpassout"] = {
        "missheistfbi3b_ig8_2",
        "cower_loop_victim",
        "Pass Out",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jddealer"] = {
        "amb@world_human_drug_dealer_hard@male@base",
        "base",
        "Drug Dealer · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jcheckw"] = {
        "amb@world_human_bum_wash@male@high@base",
        "base",
        "Check Water",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jnoway"] = {
        "oddjobs@towingpleadingbase",
        "base",
        "No Way",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jtsomething"] = {
        "oddjobs@bailbond_hobohang_out_street_c",
        "idle_c",
        "Tell Something",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 2500,
        }
    },
    ["jlfh"] = {
        "oddjobs@assassinate@old_lady",
        "looking_for_help",
        "Looking For Help",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jlmic"] = {
        "anim@veh@lowrider@std@ds@arm@music@hiphopidle_a",
        "idle",
        "Listen Music In Car",
        AnimationOptions =
        {
            EmoteMoving = true,
            EmoteDuration = 2500,
        }
    },
    ["jgotc"] = {
        "random@getawaydriver@thugs",
        "base_a",
        "Get Off The Car",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["jweeding"] = {
        "anim@amb@drug_field_workers@weeding@male_a@base",
        "base",
        "Weeding · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jlookplan"] = {
        "missheist_agency2aig_4",
        "look_plan_c_worker2",
        "Look Plan",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteDuration = 5000,
        }
    },
    ["jthanks"] = {
        "random@arrests",
        "thanks_male_05",
        "Thanks",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jsitchair8"] = {
        "timetable@michael@on_sofabase",
        "sit_sofa_base",
        "Sit Chair 8",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jsitchair9"] = {
        "timetable@trevor@smoking_meth@base",
        "base",
        "Sit Chair 9",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jsitchair10"] = {
        "timetable@tracy@ig_7@base",
        "base",
        "Sit Chair 10",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jstandingt"] = {
        "amb@world_human_bum_standing@twitchy@base",
        "base",
        "Standing Twitchy",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jstandingfit"] = {
        "amb@world_human_jog_standing@male@fitbase",
        "base",
        "Standing Fit",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jstandingm"] = {
        "anim@amb@casino@hangout@ped_male@stand@03b@base",
        "base",
        "Standing · Male",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jstandingf"] = {
        "anim@amb@casino@hangout@ped_female@stand@02a@base",
        "base",
        "Standing · Female",
        AnimationOptions =
        {
            EmoteLoop = true
        }
    },
    ["jgabgtaunt"] = {
        "switch@franklin@gang_taunt_p1",
        "gang_taunt_loop_lamar",
        "Gang Taunt",
        AnimationOptions =
        {
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["hide1"] = {
        "hidef@animations",
        "hidefclip",
        "HIDE 1",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide2"] = {
        "hideb@animations",
        "hidebclip",
        "HIDE 2",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide4"] = {
        "hidel@animations",
        "hidelclip",
        "HIDE 4",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide5"] = {
        "hidecarf@animations",
        "hidecarfclip",
        "HIDE 5",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide6"] = {
        "hidecarb@animations",
        "hidecarbclip",
        "HIDE 6",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide7"] = {
        "hidecarr@animations",
        "hidecarrclip",
        "HIDE 7",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide8"] = {
        "hidecarl@animations",
        "hidecarlclip",
        "HIDE 8",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["hide9"] = {
        "hidepole@animations",
        "hidepoleclip",
        "HIDE 9",
        AnimationOptions = {
            EmoteLoop = true,
        }
    },
    ["pavehcar1l"] = {"pavehcar1l@animations", "pavehcar1lclip", "Veh Sit-Up Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar1r"] = {"pavehcar1r@animations", "pavehcar1rclip", "Veh Sit-Up Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar2r"] = {"pavehcar2r@animations", "pavehcar2rclip", "Veh Hold On Tight Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar2l"] = {"pavehcar2l@animations", "pavehcar2lclip", "Veh Hold On Tight Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar3r"] = {"pavehcar3r@animations", "pavehcar3rclip", "Veh Sit Relaxs Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar3l"] = {"pavehcar3l@animations", "pavehcar3lclip", "Veh Sit Relaxs Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar4r"] = {"pavehcar4r@animations", "pavehcar4rclip", "Veh Sit and Wave Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar4l"] = {"pavehcar4l@animations", "pavehcar4lclip", "Veh Sit Cool Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar5r"] = {"pavehcar5r@animations", "pavehcar5rclip", "Veh Rock And Roll Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar5l"] = {"pavehcar5l@animations", "pavehcar5lclip", "Veh Rock And Roll Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar6r"] = {"pavehcar6r@animations", "pavehcar6rclip", "Veh Sit Relaxs Roof Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar6l"] = {"pavehcar6l@animations", "pavehcar6lclip", "Veh Sit Relaxs Roof Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar7r"] = {"pavehcar7r@animations", "pavehcar7rclip", "Veh Sit Happy Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false,
    }},
    ["pavehcar7l"] = {"pavehcar7l@animations", "pavehcar7lclip", "Veh Sit Happy Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pavehcar8r"] = {"pavehcar8r@animations", "pavehcar8rclip", "Veh Sleep Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pavehcar8l"] = {"pavehcar8l@animations", "pavehcar8lclip", "Veh Sleep Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pavehcar9r"] = {"pavehcar9r@animations", "pavehcar9rclip", "Veh Take Video Right", AnimationOptions =
    {
        Prop = "scrlt_iphone14max_04",
        PropBone = 28422,
        PropPlacement = {0.05, 0.0100, 0.060, -174.961, 149.618, 8.649},
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pavehcar9l"] = {"pavehcar9l@animations", "pavehcar9lclip", "Veh Take Video Left", AnimationOptions =
    {
        Prop = "scrlt_iphone14max_03",
        PropBone = 58866,
        PropPlacement = {0.07, -0.0500, 0.010, -105.33, -168.30, 48.97},
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pavehcar10"] = {"pavehcar10@animations", "pavehcar10clip", "Veh Sit Enjoy Lucia", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar1"] = {"pbvehcar1@animations", "pbvehcar1clip", "Veh Sit Here I Am", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar2"] = {"pbvehcar2@animations", "pbvehcar2clip", "Veh Sit Enjoy The Wind", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar3r"] = {"pbvehcar3r@animations", "pbvehcar3rclip", "Veh Sit Enjoy The Ride Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar3l"] = {"pbvehcar3l@animations", "pbvehcar3lclip", "Veh Sit Enjoy The Ride Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar4r"] = {"pbvehcar4r@animations", "pbvehcar4rclip", "Veh Sit Enjoy The Ride 2 Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar4l"] = {"pbvehcar4l@animations", "pbvehcar4lclip", "Veh Sit Enjoy The Ride 2 Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar5r"] = {"pbvehcar5r@animations", "pbvehcar5rclip", "Veh Sit Looking The View Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar5l"] = {"pbvehcar5l@animations", "pbvehcar5lclip", "Veh Sit Looking The View Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar6r"] = {"pbvehcar6r@animations", "pbvehcar6rclip", "Veh Twerk Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar6l"] = {"pbvehcar6l@animations", "pbvehcar6lclip", "Veh Twerk Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar7l"] = {"pbvehcar7l@animations", "pbvehcar7lclip", "Veh Standing At The Driver Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar8"] = {"pbvehcar8@animations", "pbvehcar8clip", "Veh Sleep On The Roof", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar9"] = {"pbvehcar9@animations", "pbvehcar9clip", "Veh Sit Relaxs On The Roof", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pbvehcar10"] = {"pbvehcar10@animations", "pbvehcar10clip", "Veh Relaxs On The Roof", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar1"] = {"pcvehcar1@animations", "pcvehcar1clip", "Veh Sit Enjoy On The Roof", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar2r"] = {"pcvehcar2r@animations", "pcvehcar2rclip", "Veh Sit Trunk Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar2l"] = {"pcvehcar2l@animations", "pcvehcar2lclip", "Veh Sit Trunk Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar3r"] = {"pcvehcar3r@animations", "pcvehcar3rclip", "Veh Sit Trunk Lower Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar3l"] = {"pcvehcar3l@animations", "pcvehcar3lclip", "Veh Sit Trunk Lower Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar4r"] = {"pcvehcar4r@animations", "pcvehcar4rclip", "Veh Fly Right", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar4l"] = {"pcvehcar4l@animations", "pcvehcar4lclip", "Veh Fly Left", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar5"] = {"pcvehcar5@animations", "pcvehcar5clip", "Veh Fly Random", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar6"] = {"pcvehcar6@animations", "pcvehcar6clip", "Veh Fly Higher", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar7"] = {"pcvehcar7@animations", "pcvehcar7clip", "Veh Motorcycle Hold On Tight", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["bgsign20"] = {"custom@gsign_27", "gsign_27", "Gang Sign 20", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign21"] = {"custom@gsign_28", "gsign_28", "Gang Sign 21", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign22"] = {"custom@gsign_29", "gsign_29", "Gang Sign 22", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign23"] = {"custom@gsign_30", "gsign_30", "Gang Sign 23", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign24"] = {"custom@gsign_31", "gsign_31", "Gang Sign 24", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign25"] = {"custom@gsign_32", "gsign_32", "Gang Sign 25", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign26"] = {"custom@gsign_33", "gsign_33", "Gang Sign 26", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign27"] = {"custom@gsign_34", "gsign_34", "Gang Sign 27", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign28"] = {"custom@gsign_35", "gsign_35", "Gang Sign 28", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign29"] = {"custom@gsign_36", "gsign_36", "Gang Sign 29", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign30"] = {"custom@gsign_37", "gsign_37", "Gang Sign 30", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign32"] = {"mikey@gangsigns@new", "mgangsign_1", "Gang Sign 32", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign33"] = {"mikey@gangsigns@new", "mgangsign_2", "Gang Sign 33", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign34"] = {"mikey@gangsigns@new", "mgangsign_3", "Gang Sign 34", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign35"] = {"mikey@gangsigns@new", "mgangsign_4", "Gang Sign 35", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign36"] = {"mikey@gangsigns@new", "mgangsign_5", "Gang Sign 36", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign37"] = {"mikey@gangsigns@new", "mgangsign_6", "Gang Sign 37", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign38"] = {"mikey@gangsigns@new", "mgangsign_7", "Gang Sign 38", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign39"] = {"mikey@gangsigns@new", "mgangsign_8", "Gang Sign 39", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign40"] = {"mikey@gangsigns@new", "mgangsign_9", "Gang Sign 40", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign41"] = {"mikey@gangsigns@new", "mgangsign_10", "Gang Sign 41", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign42"] = {"mikey@gangsigns@new", "mgangsign_11", "Gang Sign 42", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign48"] = {"deadly@animation@asset@uppr_000_r", "uppr_000_r", "Gang Sign 48", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["bgsign49"] = {"deadly@anims@anim3@deadly4", "deadly4", "Hand In Pocket 2", AnimationOptions =
    {
        EmoteMoving = true,
        EmoteLoop = true,
    }},
    ["bgsign50"] = {"deadly@anims@anim3@deadly3", "deadly3", "Gang Sign 50", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["bgsign51"] = {"deadly@anims@anim3@deadly6", "deadly6", "Gang Sign 51", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["bgsign56"] = {"glizzy@updated@anims@deadlyfacehiddingidle", "deadlyfacehiddingidle", "Gang Sign 56", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign57"] = {"darkcustoma@animation", "darkcustoma_clip", "Gang Sign 57", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign60"] = {"ganga@cubandark", "ganga_clip", "Gang Sign 60", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign61"] = {"gangb@cubandark", "gangb_clip", "Gang Sign 61", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign62"] = {"thewoo@cubandark", "thewoo_clip", "Gang Sign 62", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign65"] = {"animanuel@bry", "animanuel_clip", "Gang Sign 65", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign67"] = {"customc@cubandark", "customc_clip", "Gang Sign 67", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign69"] = {"handsign@cubandark", "handsign_clip", "Gang Sign 69", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign70"] = {"custom1@cubandark", "custom1_clip", "Gang Sign 70", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign71"] = {"custom2@cubandark", "custom2_clip", "Gang Sign 71", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["bgsign72"] = {"sets3letra@sets", "sets3letra_clip", "Gang Sign 72", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign74"] = {"setsmanos@sets", "setsmanos_clip", "Gang Sign 74", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign75"] = { "qpacc@gangsign1", "gangsign1_clip", "Gang Sign 75", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["bgsign98"] = { "pose3@nyck", "pose3_clip", "Gang Sign 98", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cgsign108"] = { "cardo@crip_sign_1", "crip_sign_1", "Gang Sign 108", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cgsign109"] = { "cardo@crip_sign_2", "crip_sign_2", "Gang Sign 109", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cgsign110"] = { "cardo@crip_sign_3", "crip_sign_3", "Gang Sign 110", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cgsign111"] = { "cardo@crip_sign_4", "crip_sign_4", "Gang Sign 111", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cgsign112"] = { "cardo@crip_sign_5", "crip_sign_5", "Gang Sign 112", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gsign033"] = {"qpacc@nygang29", "nygang29_clip", "NY Gang 29 4z", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign034"] = {"qpacc@nygang30", "nygang30_clip", "NY Gang 30 5zK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign035"] = {"qpacc@nygang31", "nygang31_clip", "NY Gang 31 HoundK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign039"] = {"qpacc@regularstance2", "regularstance2_clip", "Regular Stance 2 Gun Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign041"] = {"qpacc@regularstance4", "regularstance4_clip", "Regular Stance 4 ~bhuut!", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign042"] = {"qpacc@regularstance5", "regularstance5_clip", "Regular Stance 5 Gun Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign043"] = {"qpacc@regularstance6", "regularstance6_clip", "Regular Stance 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign045"] = {"qpacc@regularstance8", "regularstance8_clip", "Regular Stance 8 ~brossarms", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign048"] = {"qpacc@regularstance11", "regularstance11_clip", "Regular Stance 11", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign049"] = {"qpacc@regularstance12", "regularstance12_clip", "Regular Stance 12 Watch", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign050"] = {"qpacc@regularstance13", "regularstance13_clip", "Regular Stance 13 ~brossarms ", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign052"] = {"qpacc@regularstance15", "regularstance15_clip", "Regular Stance 15 ", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign053"] = {"qpacc@regularstance16", "regularstance16_clip", "Regular Stance 16", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign054"] = {"qpacc@regularstance17", "regularstance17_clip", "Regular Stance 17", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign055"] = {"qpacc@regularstance18", "regularstance18_clip", "Regular Stance 18", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign056"] = {"qpacc@regularstance19", "regularstance19_clip", "Regular Stance 19", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign0052"] = {"qpacc@regularstance21", "regularstance21_clip", "Regular Stance 21 WOO", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign0053"] = {"qpacc@regularstance22", "regularstance22_clip", "Regular Stance 22", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign0054"] = {"qpacc@regularstance23", "regularstance23_clip", "Regular Stance 23", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign0056"] = {"qpacc@regularstance25", "regularstance25_clip", "Regular Stance 25", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign0057"] = {"qpacc@regularstance26", "regularstance26_clip", "Regular Stance 26", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign058"] = {"qpacc@regularstance27", "regularstance27_clip", "Regular Stance 27", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign059"] = {"qpacc@regularstance28", "regularstance28_clip", "Regular Stance 28", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign060"] = {"qpacc@regularstance29", "regularstance29_clip", "Regular Stance 29", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign061"] = {"qpacc@regularstance30", "regularstance30_clip", "Regular Stance 30 Double Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign062"] = {"qpacc@regularstance31", "regularstance31_clip", "Regular Stance 31", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign063"] = {"qpacc@regularstance32", "regularstance32_clip", "Regular Stance 32", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign066"] = {"qpacc@regularstance36", "regularstance36_clip", "Regular Stance 36 Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign067"] = {"qpacc@regularstance37", "regularstance37_clip", "Regular Stance 37 Facepalm", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign069"] = {"qpacc@regularstance39", "regularstance39_clip", "Regular Stance 39", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign070"] = {"qpacc@regularstance40", "regularstance40_clip", "Regular Stance 40", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign071"] = {"qpacc@regularstance41", "regularstance41_clip", "Regular Stance 41", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign072"] = {"qpacc@regularstance42", "regularstance42_clip", "Regular Stance 42", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign075"] = {"qpacc@regularstance45", "regularstance45_clip", "Regular Stance 45", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign076"] = {"qpacc@regularstance46", "regularstance46_clip", "Regular Stance 46", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign079"] = {"qpacc@regularstance49", "regularstance49_clip", "Regular Stance 49", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign080"] = {"qpacc@regularstance50", "regularstance50_clip", "Regular Stance 50", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign081"] = {"qpacc@regularstance51", "regularstance51_clip", "Regular Stance 51", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign083"] = {"qpacc@regularstance53", "regularstance53_clip", "Regular Stance 53", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign091"] = {"qpacc@regularstance60", "regularstance60_clip", "Regular Stance 60 Hound", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign092"] = {"qpacc@regularstance61", "regularstance61_clip", "Regular Stance 61", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign197"] = {"94glockychoowook@animation", "choowook_clip", "Gang Sign 197 ~bHOO/WOOK ", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign198"] = {"94glockypocket@animation", "pocket_clip", "Handspocket 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign199"] = {"94glockycrips3@animation", "crips3_clip", "Gang Sign 199 NLE Choppa", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign202"] = {"pose2@94glocky", "94glockypose2_clip", "Gang Sign 202 Simple Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign204"] = {"pose3@94glocky", "94glockypose3_clip", "Gang Sign 204 Pose KayKay", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign206"] = {"pose4@94glocky", "94glockypose4_clip", "Gang Sign 206 Watch", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign207"] = {"handspocket3@94glocky", "handspocket3_clip", "Handspocket", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign208"] = {"gunpose1@94glocky", "gunpose1_clip", "Gang Sign 208 Gun Pose 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign209"] = {"2fuck@94glocky", "2fuck_clip", "Gang Sign 209 Double Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign210"] = {"pose8@94glocky", "94glockypose8_clip", "Gang Sign 210 Fuck & Smoke Props", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64097,
        PropPlacement = {0.0130, 0.0120, -0.0080, 27.3209, -45.5643, 30.4325},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign212"] = {"wook2@94glocky", "wook2_clip", "Gang Sign 212 WOOK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign217"] = {"ogzk@94glocky", "ogzk_clip", "Gang Sign 217 OYK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign218"] = {"gunpose2@94glocky", "gunpose2_clip", "Gang Sign 218 Gun Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign220"] = {"nottiboppin@94glocky", "nottiboppin_clip", "Gang Sign 220 Notti Boppin", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign221"] = {"pose10@94glocky", "pose10_clip", "Gang Sign 221 Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign224"] = {"mbk@94glocky", "mbk_clip", "Gang Sign 224 MBFK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign226"] = {"movink@94glocky", "movink_clip", "Gang Sign 226 MovinK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign227"] = {"doak@94glocky", "doak_clip", "Gang Sign 227 DOAK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign228"] = {"ygzkdoa@94glocky", "ygzkdoa_clip", "Gang Sign 228 DOA/YGK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign231"] = {"gunpose8kf@94glocky", "gunpose8kf_clip", "Gang Sign 231 Gun Pose KayKay", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign233"] = {"kflockpose@94glocky", "kflockpose_clip", "Gang Sign 233 KayKay Slime Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign235"] = {"r30k@94glocky", "r30k_clip", "Gang Sign 235 R30K", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign236"] = {"gunpose9@94glocky", "gunpose9_clip", "Gang Sign 236 Gun Pose 9", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign238"] = {"nhck@94glocky", "nhck_clip", "Gang Sign 238 NHC K", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign239"] = {"ygz@1@94glocky", "ygz1_clip", "Gang Sign 239 YGz", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign240"] = {"gdk@1@94glocky", "gdk1_clip", "Gang Sign 240 GDK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign243"] = {"smm@1@94glocky", "smm1_clip", "Gang Sign 243 SMM", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign245"] = {"pose@kr41@94glocky", "pose41kr_clip", "Gang Sign 245 Pose Kyle Rich", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign246"] = {"pose@kayflock1@94glocky", "posekf1_clip", "Gang Sign 246 KayKay Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign247"] = {"pose@drilly@94glocky", "posedrilly1_clip", "Gang Sign 247 Hound 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign249"] = {"slime@gunpose@94glocky", "slimegp1_clip", "Gang Sign 249 Slime Gun Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign250"] = {"ok@2@94glocky", "ok2_clip", "Gang Sign O's K", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign253"] = {"smelly@1@94glocky", "smelly1_clip", "Gang Sign 253 Smelly 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign254"] = {"smelly@2@94glocky", "smelly2_clip", "Gang Sign 254 Movin 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign256"] = {"gunpose@rifle@94glocky", "gunposerifle_clip", "Gang Sign 256 Gun Pose & Rifle", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign265"] = {"pose@hands@94glocky", "posehands1_clip", "Gang Sign 265 Pose Simple", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign270"] = {"mbk@2@94glocky", "mbk2_clip", "Gang Sign 270 MBF K", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign271"] = {"slatteryboyz@1@94glocky", "sb1_clip", "Gang Sign 271 Smelly 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign273"] = {"slime@kf@94glocky", "slimekf_clip", "Gang Sign 273 Slime", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign276"] = {"doak@2@94glocky", "doak2_clip", "Gang Sign 276 DOAK 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign279"] = {"gsb@1@94glocky", "gsb1_clip", "Gang Sign 279 Gorilla Stones Bloods", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign280"] = {"slime@kf2@from94", "slimekf2_clip", "Gang Sign 280 Slime KayKay", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign281"] = {"smmmbfk@from94", "smmmbfk_clip", "Gang Sign 281 MBF SMM K", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign282"] = {"slime@oyk@from94", "slimeoyk_clip", "Gang Sign 282 Slime OYK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign284"] = {"o@from94", "ofrom94_clip", "Gang Sign 284 O's", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign285"] = {"gunpose4@94glocky", "gunpose4_clip", "Gang Sign 285 Gun Pose 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign286"] = {"gunpose5@94glocky", "gunpose5_clip", "Gang Sign 286 Gun Pose 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign291"] = {"bigdoa@from94", "bigdoa_clip", "Gang Sign 291 DOA 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign296"] = {"ygz@from94", "ygzfrom94_clip", "Gang Sign 296 YGz", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign299"] = {"gunpose@slime@from94", "gunposeslime_clip", "Gang Sign 299 Gun Pose & Slime 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign307"] = {"nhc@from94", "nhcfrom94_clip", "Gang Sign 306 NHC", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign317"] = {"bhb@from94", "bhb_clip", "Gang Sign 316 Hound", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign323"] = {"dababy@from94", "dababy_clip", "Gang Sign 322 Dababy Pose", AnimationOptions =
    {

        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign330"] = {"smm2@from94", "smm2_clip", "Gang Sign 329 SMM 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign337"] = {"houndk@from94", "houndk_clip", "Gang Sign 333 Hound K 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign363"] = {"ck@from94", "ck_clip", "Gang Sign 357", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign389"] = {"jayhound@from94", "jayhound_clip", "Gang Sign 378 Hound (Jay Hound)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign390"] = {"jaydohitz@from94", "jaydohitz_clip", "Gang Sign 379 DoH!tz (Jay Hound)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign417"] = {"femalepose@from94", "femalepose_clip", "Gang Sign 391 Female Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign419"] = {"pologpose@from94", "pologpose_clip", "Gang Sign 392 Polo G Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign420"] = {"posesit@from94", "posesit_clip", "Gang Sign 393 Pose Sit", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign423"] = {"femalepose2@from94", "femalepose2_clip", "Gang Sign 396 Pose Female 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign438"] = {"onehands@from94", "onehands_clip", "Gang Sign 398 One Hands Pocket", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign439"] = {"justslime@from94", "justslime_clip", "Gang Sign 399 Slime", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign441"] = {"nbafuck@from94", "nbafuck_clip", "Gang Sign 401 Youngboy Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign450"] = {"oyoy@from94", "oyoy_clip", "Gang Sign 409 OY", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign454"] = {"grizzlybdk@from94", "grizzlybdk_clip", "Stacking 1 BDK", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign455"] = {"gunaim@from94", "gunaim_clip", "Stacking 2 Gun Aim", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign456"] = {"graaaa@from94", "graaaa_clip", "Stacking 3 Hxxva", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign457"] = {"984msc@from94", "984msc_clip", "Stacking 4 MainStreet", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign458"] = {"107hxxva@from94", "107hxxva_clip", "Stacking 5 107 Hoover", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign459"] = {"rollin60@from94", "rollin60_clip", "Stacking 6 Rollin 60", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign460"] = {"gunaim2@from94", "gunaim2_clip", "Stacking 7 Gun Aim 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign461"] = {"chiraqselfie1@from94", "chiraqselfie1_clip", "Stacking 8 Seflie Chiraq", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign462"] = {"ws99mc@from94", "ws99_clip", "Stacking 9 99 Mafia Crips", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign463"] = {"chiraqstacking1@from94", "chiraqstacking1_clip", "Stacking 10 GD's", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign464"] = {"makkstakking@from94", "makkstakking_clip", "Stacking 11 Makk Balla", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign465"] = {"62brimstacking@from94", "62brimstacking_clip", "Stacking 12 62 Brim", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign466"] = {"rundownstacking@from94", "rundownstacking_clip", "Stacking 13 Rundown", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign467"] = {"sdotgopose@from94", "sdot_clip", "Gang Sign 380 Pose SDot Go", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["freposegl"] = {"glap@free-poses-v12", "free-poses-v12", "Pose V12", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg2"] = {"glap@free-poses-v11", "free-poses-v11_clip", "Pose V11", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg5"] = {"glap@free-poses-v6", "free-poses-v6_clip", "Pose V6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["sorakit"] = {"glap@free-poses-v2", "free-poses-v2_clip", "Sorakit Pose V2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg6"] = {"glap@free-poses-v1", "free-poses-v1_clip", "Poses-V1 Free-V1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg7"] = {"glap@free-poses-v4", "free-poses-v4-1_clip", "Pose V42", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg8"] = {"glap@free-poses-v4", "free-poses-v4-2_clip", "Pose V41", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg9"] = {"glap@free-poses-v3", "free-poses-v3_clip", "Pose V32", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["p1"] = {"penguin@head", "penguinhead", "Penguin Head", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["p2"] = {"penguin@love", "penguinlove", "Penguin Love", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["p3"] = {"penguin@standpickpocket", "penguin_standpickpocket", "Penguin Pick Pocket", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["p4"] = {"penguin@2fingers_up", "penguin_2_fingers_up", "Penguin Fingers Up", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["p5"] = {"penguin@pokcheek", "penguin_pok_cheek", "Penguin Pok Cheek", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["p6"] = {"penguin@hold_the_cheek", "penguin_hold_the_cheek", "Penguin Hold Cheek", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["p7"] = {"penguin@pose", "penguin_pose", "Penguin Pose 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["p8"] = {"penguin@pose2", "penguin_pose2", "Penguin Pose 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["p9"] = {"penguin@pose3", "penguin_pose3", "Penguin Pose 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["q1"] = {"penguin@pose4", "penguin_pose4", "Penguin Pose 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["q2"] = {"penguin@pose5", "penguin_pose5", "Penguin Pose 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["q3"] = {"penguin@pose6", "penguin_pose6", "Penguin Pose 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["q4"] = {"penguin@pose7", "penguin_pose7", "Penguin Pose 7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["q6"] = {"penguin@pose8", "penguin_pose8", "Penguin Pose 8", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["q7"] = {"penguin@pose9", "penguin_pose9", "Penguin Pose 9", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["q8"] = {"penguin@pose10", "penguin_pose10", "Penguin Pose 10", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["q9"] = {"penguin@dab", "penguin_dab", "Penguin Dab 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["z1"] = {"penguin@dab1", "penguin_dab1", "Penguin Dab 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["asutynew15"] = {
        "suty@sitpose5",
        "suty_sitclip5",
        "Suty Pose",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["asutynew16"] = {
        "suty@sitpose6",
        "suty_sitclip6",
        "Fingers Pointing Head",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
        }
    },
    ["posenew"] = {
        "kdesinganim@animation",
        "kdesinganim_clip",
        "Pose New Gang",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["posenew2"] = {
        "kdesinganim2@animation",
        "kdesinganim2_clip",
        "Pose New Gang 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = true,
        }
    },
    ["snow1"] = {"psnow1@animations", "psnow1clip", "Angels 1 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow2"] = {"psnow2@animations", "psnow2clip", "Angels 2 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow3"] = {"psnow3@animations", "psnow3clip", "Angels 3 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow4"] = {"psnow4@animations", "psnow4clip", "Crawl 1 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow5"] = {"psnow5@animations", "psnow5clip", "Crawl 2 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow6"] = {"psnow6@animations", "psnow6clip", "Feel Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow7"] = {"psnow7@animations", "psnow7clip", "Buried 1 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow8"] = {"psnow8@animations", "psnow8clip", "Buried 2 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow9"] = {"psnow9@animations", "psnow9clip", "Buried 3 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow10"] = {"psnow10@animations", "psnow10clip", "Buried 4 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["psnow11"] = {"psnow11@animations", "psnow11clip", "Sliding 1 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow12"] = {"psnow12@animations", "psnow12clip", "Sliding 2 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow13"] = {"psnow13@animations", "psnow13clip", "Sliding 3 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow14"] = {"psnow14@animations", "psnow14clip", "Sliding 4 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["snow15"] = {"psnow15@animations", "psnow15clip", "Sliding 5 Snow", AnimationOptions =
    {
        EmoteLoop = true,
    }},
    ["catwalk"] = {"glap@catwalk", "catwalk_clip", "Catwalk Walk", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["standingp"] = {"standingposeanim@animation", "standingposeanim_clip", "Standing Pose Female", AnimationOptions =
    {
        EmoteMoving = false, -- or true if you want to walk
        EmoteLoop = true,
    }},
    ["rabbitanim"] = {"rabbitanim@animation", "rabbitanim_clip", "Rabbit Anim", AnimationOptions =
    {
        EmoteMoving = false, -- or true if you want to walk
        EmoteLoop = true,
    }},
    ["corkscrew"] = {"mikey@acrobatics@new", "corkscrew", "Corkscrew", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["corkscrew2"] = {"mikey@acrobatics@new", "corkscrew2", "Corkscrew 2", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["prop_flip"] = {"mikey@acrobatics@new", "prop_flip", "Prop Flip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["runfrontflip"] = {"mikey@acrobatics@new", "runfrontflip", "Run Front Flip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["runwallbackflip"] = {"mikey@acrobatics@new", "runwallbackflip", "Run Wall Back Flip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["spin_kickflip"] = {"mikey@acrobatics@new", "spin_kick_flip", "Spin Kick Flip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["standingbackflip"] = {"mikey@acrobatics@new", "standingbackflip", "Standing Back Flip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["steeze_backflip"] = {"mikey@acrobatics@new", "steeze_backflip", "Steeze Back Flip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["twistflip"] = {"mikey@acrobatics@new", "twistflip", "Twistflip", AnimationOptions =
    {
        EmoteLoop = false
    }},
    ["waiter"] = {"custom@waiter", "waiter", "Waiter", AnimationOptions =
    {
        EmoteMoving = true,
        EmoteLoop = true,
    }},
    ["sheesh"] = {"custom@sheeeeesh", "sheeeeesh", "Sheeeeesh", AnimationOptions =
    {
        EmoteMoving = true,
        EmoteLoop = true,
    }},
    ["pluck"] = {"custom@pluck_fruits", "pluck_fruits", "Pluck Fruits", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["narutorun"] = {"custom@narutorun", "narutorun", "Naruto Run", AnimationOptions =
    {
        EmoteMoving = true,
        EmoteLoop = true,
    }},
    ["jumpingjack"] = {"custom@jumpingjack", "jumpingjack", "Jumping Jack", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["clock"] = {"custom@around_the_clock", "around_the_clock", "Around the clock", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["backflip"] = {"custom@backflip", "backflip", "Backflip", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ncnpose1"] = {"custom@female_pose_1", "female_pose_1", "Female New N Pose 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ncnpose2"] = {"custom@female_pose_2", "female_pose_2", "Female New N Pose 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ncnpose3"] = {"custom@female_pose_3", "female_pose_3", "Female New N Pose 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ncnpose4"] = {"custom@male_pose_1", "male_pose_1", "Male New N Pose 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ncnpose5"] = {"custom@male_pose_2", "male_pose_2", "Male New N Pose 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ncnpose6"] = {"custom@male_pose_3", "male_pose_3", "Male New N Pose 6", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["dragonballz"] = {"custom@dragonballz", "dragonballz", "Dragonball Z", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = false,
    }},
    ["cantsee"] = { "custom@cant_see", "cant_see", "Can't See", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["convulsion"] = {"custom@convulsion", "convulsion", "Convulsion", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    -- Little Spoon New
    ["friend1"] = {"littlespoon@friendship001", "friendship001", "LS Friend Pose Female 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend2"] = {"littlespoon@friendship002", "friendship002", "LS Friend Pose Male 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend3"] = {"littlespoon@friendship003", "friendship003", "LS Friend Pose Female 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend4"] = {"littlespoon@friendship004", "friendship004", "LS Friend Pose Male 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend5"] = {"littlespoon@friendship005", "friendship005", "LS Friend Pose Female 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend6"] = {"littlespoon@friendship006", "friendship006", "LS Friend Pose Male 6", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend7"] = {"littlespoon@friendship009", "friendship009", "LS Friend Pose Female 7", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend8"] = {"littlespoon@friendship010", "friendship010", "LS Friend Pose Male 8", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend9"] = {"littlespoon@friendship011", "friendship011", "LS Friend Pose Male Female", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["friend10"] = {"littlespoon@friendship012", "friendship012", "LS Friend Pose Male 10", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose1"] = {"littlespoon@desire001", "desire001", "LS Sex Pose 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose2"] = {"littlespoon@desire002", "desire002", "LS Sex Pose 2 ", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose3"] = {"littlespoon@desire003", "desire003", "LS Sex Pose 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose4"] = {"littlespoon@desire004", "desire004", "LS Sex Pose 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose5"] = {"littlespoon@desire005", "desire005", "LS Sex Pose 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose6"] = {"littlespoon@desire006", "desire006", "LS Sex Pose 6", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose7"] = {"littlespoon@desire007", "desire007", "LS Sex Pose 7", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose8"] = {"littlespoon@desire008", "desire008", "LS Sex Pose 8", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose9"] = {"littlespoon@desire009", "desire009", "LS Sex Pose 9", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose_10"] = {"littlespoon@desire010", "desire010", "LS Sex Pose 10", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose_11"] = {"littlespoon@desire011", "desire011", "LS Sex Pose 11", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexpose_12"] = {"littlespoon@desire012", "desire012", "LS Sex Pose 12", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy1"] = {"littlespoon@intimacy001", "intimacy001", "LS Sex Animation 1 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy2"] = {"littlespoon@intimacy002", "intimacy002", "LS Sex Animation 2 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy3"] = {"littlespoon@intimacy003", "intimacy003", "LS Sex Animation 3 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy4"] = {"littlespoon@intimacy004", "intimacy004", "LS Sex Animation 4 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy5"] = {"littlespoon@intimacy005", "intimacy005", "LS Sex Animation 5 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy6"] = {"littlespoon@intimacy006", "intimacy006", "LS Sex Animation 6 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexy7"] = {"littlespoon@intimacy007", "intimacy007", "LS Sex Animation 7 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexyp1"] = {"littlespoon@sexy001", "sexy001", "LS Sexy Pose 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexyp2"] = {"littlespoon@sexy002", "sexy002", "LS Sexy Pose 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexyp3"] = {"littlespoon@sexy007", "sexy007", "LS Sexy Pose 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexyp4"] = {"littlespoon@sexy008", "sexy008", "LS Sexy Pose 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexyp5"] = {"littlespoon@sexy010", "sexy010", "LS Sexy Pose 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["lssexyp6"] = {"littlespoon@sexy011", "sexy011", "LS Sexy Pose 6", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga"] = {"littlespoon@yoga001", "yoga001", "LS Yoga Pose", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga2"] = {"littlespoon@yoga002", "yoga002", "LS Yoga Pose 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga3"] = {"littlespoon@yoga003", "yoga003", "LS Yoga Pose 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga4"] = {"littlespoon@yoga004", "yoga004", "LS Yoga Pose 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga5"] = {"littlespoon@yoga005", "yoga005", "LS Yoga Pose 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga6"] = {"littlespoon@yoga006", "yoga006", "LS Yoga Pose 6", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga7"] = {"littlespoon@yoga007", "yoga007", "LS Yoga Pose 7", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga8"] = {"littlespoon@yoga008", "yoga008", "LS Yoga Pose 8", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["nyoga9"] = {"littlespoon@yoga009", "yoga009", "LS Yoga Pose 9", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["sensual1"] = {"littlespoon@sensual001", "sensual001", "LS Sensual Pose 1 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual2"] = {"littlespoon@sensual002", "sensual002", "LS Sensual Pose 2 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual3"] = {"littlespoon@sensual003", "sensual003", "LS Sensual Pose 3 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual4"] = {"littlespoon@sensual004", "sensual004", "LS Sensual Pose 4 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual5"] = {"littlespoon@sensual005", "sensual005", "LS Sensual Pose 5 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual6"] = {"littlespoon@sensual006", "sensual006", "LS Sensual Pose 6 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual7"] = {"littlespoon@sensual007", "sensual007", "LS Sensual Pose 7 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual8"] = {"littlespoon@sensual008", "sensual008", "LS Sensual Pose 8 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual9"] = {"littlespoon@sensual009", "sensual009", "LS Sensual Pose 9 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["sensual_10"] = {"littlespoon@sensual010", "sensual010", "LS Sensual Pose 10 Explicit", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cardofemalepose1"] = { "cardo@beach_model_1", "beach_model_1", "Cardo Female Pose 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cardofemalepose2"] = { "cardo@beach_model_2", "beach_model_2", "Cardo Female Pose 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cardofemalepose3"] = { "cardo@beach_model_3", "beach_model_3", "Cardo Female Pose 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cardofemalepose4"] = { "cardo@beach_model_4", "beach_model_4", "Cardo Female Pose 4", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["cardofemalepose5"] = { "cardo@beach_model_5", "beach_model_5", "Cardo Female Pose 5", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["mstance1"] = {"anim@male_casual_stance", "casual_stance", "Casual Male Stance (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose"] = {"sexpose3@seimen", "sexpose3_clip", "Sexy Pose", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose1"] = {"sexpose4@seimen", "sexpose4_clip", "Sexy Pose 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose2"] = {"sexpose5@seimen", "sexpose5_clip", "Sexy Pose 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose3"] = {"sexpose6@seimen", "sexpose6_clip", "Sexy Pose 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose4"] = {"sexpose7@seimen", "sexpose7_clip", "Sexy Pose 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose5"] = {"sexpose8@seimen", "sexpose8_clip", "Sexy Pose 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose6"] = {"sexpose9@seimen", "sexpose9_clip", "Sexy Pose 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose7"] = {"sexpose10@seimen", "sexpose10_clip", "Sexy Pose 7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose8"] = {"sexpose11@seimen", "sexpose11_clip", "Sexy Pose 8", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose9"] = {"sexpose12@seimen", "sexpose12_clip", "Sexy Pose 9", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose10"] = {"sexpose13@seimen", "sexpose13_clip", "Sexy Pose 10", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose11"] = {"sexpose14@seimen", "sexpose14_clip", "Sexy Pose 11", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose12"] = {"sexpose15@seimen", "sexpose15_clip", "Sexy Pose 12", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose13"] = {"sexpose16@seimen", "sexpose16_clip", "Sexy Pose 13", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose14"] = {"sexpose17@seimen", "sexpose17_clip", "Sexy Pose 14", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose15"] = {"sexpose18@seimen", "sexpose18_clip", "Sexy Pose 15", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose16"] = {"sexpose19@seimen", "sexpose19_clip", "Sexy Pose 16", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose17"] = {"sexpose20@seimen", "sexpose20_clip", "Sexy Pose 17", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose18"] = {"sexpose21@seimen", "sexpose21_clip", "Sexy Pose 18", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose19"] = {"sexpose22@seimen", "sexpose22_clip", "Sexy Pose 19", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["seyspose20"] = {"sexpose23@seimen", "sexpose23_clip", "Sexy Pose 20", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["randmpse1"] = {"lunyx@rgmp01", "rgmp01", "Random Pose 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse2"] = {"lunyx@rgmp02", "rgmp02", "Random Pose 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse3"] = {"lunyx@rgmp03", "rgmp03", "Random Pose 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse4"] = {"lunyx@rgmp04", "rgmp04", "Random Pose 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse5"] = {"lunyx@rgmp05", "rgmp05", "Random Pose 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse6"] = {"lunyx@rgmp06", "rgmp06", "Random Pose 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse7"] = {"lunyx@rgmp07", "rgmp07", "Random Pose 7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["randmpse11"] = {"lunyx@random@v3@pose004", "random@v3@pose004", "Random Pose 11", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["piggy"] = {"fos_ep_1_p1-9", "csb_imran_dual-9", "piggy", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},

    ["speech"] = {"fos_ep_1_p0-0", "cs_lazlow_dual-0", "Speech", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["new6"] = {"timetable@trevor@ig_1", "ig_1_therearejustsomemoments_patricia", "New Emotes 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["foldarms4"] = {"impexp_int_l1-11", "mp_m_waremech_01_dual-11", "Fold Arms 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["sitbar1"] = {"amb@prop_human_seat_computer@male@react_shock", "forward", "Sit Bar", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sitbar2"] = {"amb@prop_human_seat_bar@male@elbows_on_bar@idle_b", "idle_d", "Sit Bar 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sitbar3"] = {"amb@incar@male@security@idle_a", "idle_a", "Sit Bar 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["post4"] = {"mpcas_int-2", "s_m_y_casino_01^1_dual-2", "Post 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["help"] = {"missheist_agency3aig_19", "ground_call_help", "help", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep3"] = {"missheist_agency3amcs_4b", "crew_dead_crew2", "Sleep 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep4"] = {"missheist_jewel", "gassed_npc_customer1", "Sleep 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep5"] = {"missheist_jewel", "gassed_npc_customer2", "Sleep 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep6"] = {"missheist_jewel", "gassed_npc_customer3", "Sleep 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep7"] = {"missheist_jewel", "gassed_npc_customer4", "Sleep 7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep8"] = {"missprologueig_6", "lying_dead_brad", "Sleep 8", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sleep9"] = {"missprologueig_6", "lying_dead_player0", "Sleep 9", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps"] = {"chxnchxo@stand_anim", "chxnchxostand_clip", "Stand Pose Style", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps1"] = {"chxnchxo@stand1_anim", "chxnchxostand1_clip", "Stand Pose Style 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps2"] = {"chxnchxo@stand2_anim", "chxnchxostand2_clip", "Stand Pose Style 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps3"] = {"chxnchxo@stand3_anim", "chxnchxostand3_clip", "Stand Pose Style 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps4"] = {"chxnchxo@stand4_anim", "chxnchxostand4_clip", "Stand Pose Style 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps5"] = {"chxnchxo@stand5_anim", "chxnchxostand5_clip", "Stand Pose Style 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps6"] = {"chxnchxo@stand6_anim", "chxnchxostand6_clip", "Stand Pose Style 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps7"] = {"chxnchxo@stand7_anim", "chxnchxostand7_clip", "Stand Pose Style 7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps8"] = {"chxnchxo@stand8_anim", "chxnchxostand8_clip", "Stand Pose Style 8", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sps9"] = {"chxnchxo@stand9_anim", "chxnchxostand9_clip", "Stand Pose Style 9", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["boygroup1"] = {"lunyx@boygroup@p1", "boygroup@p1", "Boy Group Pose 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["boygroup2"] = {"lunyx@boygroup@p2", "boygroup@p2", "Boy Group Pose 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["boygroup3"] = {"lunyx@boygroup@p3", "boygroup@p3", "Boy Group Pose 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["boygroup4"] = {"lunyx@boygroup@p4", "boygroup@p4", "Boy Group Pose 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["boygroup5"] = {"lunyx@boygroup@p5", "boygroup@p5", "Boy Group Pose 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["boygroup6"] = {"lunyx@boygroup@p6", "boygroup@p6", "Boy Group Pose 6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["boygroup7"] = {"lunyx@boygroup@p7", "boygroup@p7", "Boy Group Pose 7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["attention1"] = {"lunyx@attention@001", "attention@001", "Got Me Looking for Attention Pose 1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["attention2"] = {"lunyx@attention@002", "attention@002", "Got Me Looking for Attention Pose 2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["attention3"] = {"lunyx@attention@003", "attention@003", "Got Me Looking for Attention Pose 3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["attention4"] = {"lunyx@attention@004", "attention@004", "Got Me Looking for Attention Pose 4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["attention5"] = {"lunyx@attention@005", "attention@005", "Got Me Looking for Attention Pose 5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["fmodel1"] = {"anim@female_model_01", "f_model_01_clip", "Female Model Pose 1 (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["fmodel2"] = {"anim@female_model_02", "f_model_02_clip", "Female Model Pose 2 (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},

    ["fmodel3"] = {"anim@female_model_03", "f_model_03_clip", "Female Model Pose 3 (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["flean1"] = {"anim@female_lean_01", "f_smoke_01_clip", "Female Smoking Pose 1 (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["sittingbored"] = {"pineapple@sittingbored", "sittingbored", "Sitting Bored", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["hidemytiddies"] = {"murda@tiddies", "tiddies", "Hide My Tiddies", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["mop1"] = {"mopose1@animation", "mopose1_clip", "Chill Pose 1. MODON", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["mop2"] = {"mopose2@animation", "mopose2_clip", "Chill Pose 2. MODON", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["mop3"] = {"mopose3@animation", "mopose3_anim", "Chill Pose 3. MODON", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["mop4"] = {"mopose4@animation", "mopose4_clip", "Chill Pose 4. MODON", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["mop5"] = {"mopose5@animation", "mopose5_clip", "Chill Pose 5. MODON", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["ganggroup3"] = {"karxem@group", "group_3", "Gang Group 3", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gangdpcross"] = {"drillpack@karxem", "crossfinger", "Gang Drill Pose Pour", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gangdpnope"] = {"drillpack@karxem", "nope", "Gang Drill Pose Nope", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},

    ["ganggroup1"] = {"karxem@group", "group_1", "Gang Group 1", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["gangdphand"] = {"drillpack@karxem", "handsup", "Gang Drill Pose Handsup", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["ganganimaill"] = {"jxmill2anims@animation", "jxmill2anims_clip", "Gang Anim A Ill", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["ganganima9"] = {"jxs9anims@animation", "jxs9anims_clip", "Gang Anim A9", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["ganganima10"] = {"jxs10anims@animation", "jxs10anims_clip", "Gang Anim A10", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["ganganimafck"] = {"jxfxck1anims@animation", "jxfxck1anims_clip", "Gang Anim A Fingger", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["ganganima1"] = {"jxs1anims@animation", "jxs1anims_clip", "Gang Anim A1", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["ganganima2"] = {"jxs2anims@animation", "jxs2anims_clip", "Gang Anim A2", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["ganganima3"] = {"jxs3anims@animation", "jxs3anims_clip", "Gang Anim A3", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["gsign30"] = {"custom@gsign_37", "gsign_37", "Gang Sign A30", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign20"] = {"custom@gsign_27", "gsign_27", "Gang Sign A20", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign21"] = {"custom@gsign_28", "gsign_28", "Gang Sign A21", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign22"] = {"custom@gsign_29", "gsign_29", "Gang Sign A22", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign23"] = {"custom@gsign_30", "gsign_30", "Gang Sign A23", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign24"] = {"custom@gsign_31", "gsign_31", "Gang Sign A24", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign25"] = {"custom@gsign_32", "gsign_32", "Gang Sign A25", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign26"] = {"custom@gsign_33", "gsign_33", "Gang Sign A26", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign27"] = {"custom@gsign_34", "gsign_34", "Gang Sign A27", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign28"] = {"custom@gsign_35", "gsign_35", "Gang Sign A28", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign29"] = {"custom@gsign_36", "gsign_36", "Gang Sign A29", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsignwrld"] = {"wrldmods@trippieredd", "trippieredd", "Gang Sign World", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
    }},
    ["agsign1"] = {"custom@gsign_01", "gsign_01", "Gang Sign A1", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign2"] = {"custom@gsign_02", "gsign_02", "Gang Sign A2", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign3"] = {"custom@gsign_03", "gsign_03", "Gang Sign A3", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign4"] = {"custom@gsign_04", "gsign_04", "Gang Sign A4", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign5"] = {"custom@gsign_05", "gsign_05", "Gang Sign A5", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign6"] = {"custom@gsign_06", "gsign_06", "Gang Sign A6", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign7"] = {"custom@gsign_07", "gsign_07", "Gang Sign A7", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign8"] = {"custom@gsign_08", "gsign_08", "Gang Sign A8", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["agsign9"] = {"custom@gsign_09", "gsign_09", "Gang Sign A9", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign10"] = {"custom@gsign_10", "gsign_10", "Gang Sign A10", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign11"] = {"custom@gsign_11", "gsign_11", "Gang Sign A11", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign12"] = {"custom@gsign_12", "gsign_12", "Gang Sign A12", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign13"] = {"custom@gsign_13", "gsign_13", "Gang Sign A13", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign14"] = {"custom@gsign_14", "gsign_14", "Gang Sign A14", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign16"] = {"custom@mgsign_02", "mgsign_02", "Gang Sign A16", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["bgsign19"] = {"custom@gsign_26", "gsign_26", "Gang Sign A19", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["pickfromground"] = {"custom@pickfromground", "pickfromground", "Pick From Ground New", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = false
    }},
    ["whatidk"] = {"custom@what_idk", "what_idk", "What New", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = false
    }},

    ["carfemalechill"] = {"car_chill@vansen", "car_chill_clip", "Female Car Chill", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["carfemalepew"] = {"car_pew@vansen", "car_pew_clip", "Female Car Pew", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["carfemalecute"] = {"cute_car_sit@vansen", "cute_car_sit_clip", "Female Car Cute", AnimationOptions =
    {
        EmoteMoving = false,
    }},
    ["scenario1"] = {"missheistdockssetup1showoffcar@idle_a", "idle_a_2", "Scenario 1", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario2"] = {"missheistdockssetup1showoffcar@idle_a", "idle_a_3", "Scenario 2", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario3"] = {"missheistdockssetup1showoffcar@idle_a", "idle_a_4", "Scenario 3", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario4"] = {"missheistdockssetup1showoffcar@idle_a", "idle_a_5", "Scenario 4", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario5"] = {"missheistdockssetup1showoffcar@idle_a", "idle_b_1", "Scenario 5", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario6"] = {"missheistdockssetup1showoffcar@idle_a", "idle_b_2", "Scenario 6", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario7"] = {"missheistdockssetup1showoffcar@idle_a", "idle_b_3", "Scenario 7", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario8"] = {"missheistdockssetup1showoffcar@idle_a", "idle_b_4", "Scenario 8", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenario9"] = {"missheistdockssetup1showoffcar@idle_a", "idle_b_5", "Scenario 9", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenarioa"] = {"missheistdockssetup1showoffcar@idle_a", "idle_c_1", "Scenario A", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenariob"] = {"missheistdockssetup1showoffcar@idle_a", "idle_c_2", "Scenario B", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenarioc"] = {"missheistdockssetup1showoffcar@idle_a", "idle_c_3", "Scenario C", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenariod"] = {"missheistdockssetup1showoffcar@idle_a", "idle_c_4", "Scenario D", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenarioe"] = {"missheistdockssetup1showoffcar@idle_a", "idle_c_5", "Scenario E", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenariof"] = {"missheistdockssetup1showoffcar@idle_b", "idle_d_1", "Scenario F", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenariog"] = {"missheistdockssetup1showoffcar@idle_b", "idle_d_2", "Scenario G", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenarioh"] = {"missheistdockssetup1showoffcar@idle_b", "idle_d_3", "Scenario H", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["scenarioi"] = {"missheistdockssetup1showoffcar@idle_b", "idle_d_4", "Scenario I", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["mamamia"] = {"anim@mp_player_intupperfinger_kiss", "idle_a", "Mamamia", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = true,
    }},
    ["mamamia2"] = {"anim@mp_player_intcelebrationmale@finger_kiss", "finger_kiss", "Mamamia 2", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["mamamia3"] = {"anim@mp_player_intcelebrationfemale@finger_kiss", "finger_kiss", "Mamamia 2 (FEMALE)", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = false,
    }},
    ["oops"] = {"anim@mp_player_intincarblow_kissbodhi@ds@", "idle_a", "Oops", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = true,
    }},
    ["oops2"] = {"anim@mp_player_intselfieblow_kiss", "idle_a", "Oops 2", AnimationOptions =
    {
        EmoteLoop = false,
        EmoteMoving = true,
    }},
}
CustomDP.GestesEmotes = {

    ["armsback"] = {
        "anim@miss@low@fin@vagos@",
        "idle_ped06",
        "Mains dans le dos",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["analyse"] = {
        "analyse@animation",
        "analyse_clip",
        "Analyse",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["cantsee"] = {
        "custom@cant_see",
        "cant_see",
        "Je ne vois pas",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["dab"] = {
        "custom@dab",
        "dab",
        "Faire un dab",
        AnimationOptions = { EmoteLoop = true }
    },
    ["sheesh"] = {
        "custom@sheeeeesh",
        "sheeeeesh",
        "Sheesh",
        AnimationOptions = { EmoteMoving = true, EmoteDuration = 8000 }
    },
    ["secretservice"] = {
        "anim@secret_service",
        "open_door",
        "Ouvrir la porte (USSS)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["secretservice2"] = {
        "wristmic@animation",
        "wristmic4_clip",
        "Parler a sa radio (USSS)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["riflerelax"] = {
        "anim@fog_rifle_relaxed",
        "rifle_relaxed_clip",
        "Relaxed With Rifle (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["stack1"] = {
        "anim@stack_pointman",
        "pointman_clip",
        "Stack Formation Pointman (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["stack2"] = {
        "anim@stack_two_man",
        "two_man_clip",
        "Stack Formation 2nd Man (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["stack3"] = {
        "anim@stack_three_man",
        "three_man_clip",
        "Stack Formation Door (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["highlow1"] = {
        "anim@highlow_low_lean",
        "low_lean_clip",
        "High-Low Low Stance (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["highlow2"] = {
        "anim@highlow_high_lean",
        "high_lean_clip",
        "High-Low High Stance (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["highlow3"] = {
        "anim@tactical_highlow_high_leftlean",
        "high_leftlean_clip",
        "Highlow Left Lean High (Smos)",
        AnimationOptions = { EmoteLoop = false, EmoteMoving = false }
    },
    ["highlow4"] = {
        "anim@tactical_highlow_low_leftlean",
        "low_leftlean_clip",
        "Highlow Left Lean Low (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["kneeltalkie"] = {
        "anim@tactical_kneel_walkie",
        "kneel_walkie_clip",
        "Communication Relaxed Rifle (Smos)",
        AnimationOptions = { EmoteLoop = false, EmoteMoving = false }
    },
    ["aimkneel"] = {
        "anim@tactical_kneel_aiming",
        "kneel_aiming_clip",
        "Kneeling and Aiming Rifle (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["riflerelax1"] = {
        "anim@male_tactical_collapsed_lowready",
        "collapsed_lowready_clip",
        "Collapsed Lowready Relaxed Rifle (Smos)",
        AnimationOptions = { EmoteLoop = false, EmoteMoving = false }
    },
    ["riflerelax2"] = {
        "anim@male_tactical_highready_relaxed",
        "highready_relaxed_clip",
        "Highready Relaxed Rifle (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["holdingweapon2"] = {
        "anim@male@holding_weapon_2",
        "holding_weapon_2_clip",
        "Holding Weapon 2 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["holdingweapon4"] = {
        "anim@male@holding_weapon_4",
        "holding_weapon_4_clip",
        "Holding Weapon 4 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["holdweapkneel"] = {
        "anim@male@holding_weapon_kneel",
        "anim@male@holding_weapon_kneel_clip",
        "Holding Weapon Kneel (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["holdweapnvg1"] = {
        "anim@male@holding_weapon_nvg",
        "holding_weapon_nvg_clip",
        "Holding Weapon NVG (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["holdweapnvg2"] = {
        "anim@male@holding_weapon_nvg_2",
        "holding_weapon_nvg_2_clip",
        "Holding Weapon NVG (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["hugweapon1"] = {
        "anim@male@hug_weapon",
        "hug_weapon_clip",
        "Hug Weapon (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["hugweapon2"] = {
        "anim@male@hug_weapon_2",
        "hug_weapon_2_clip",
        "Hug Weapon 2 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["poseweapon1"] = {
        "anim@male@pose_weapon",
        "pose_weapon_clip",
        "Pose Weapon 1 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["poseweapon2"] = {
        "anim@male@pose_weapon_2",
        "pose_weapon_2_clip",
        "Pose Weapon 2 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["poseweapon3"] = {
        "anim@male@pose_weapon_3",
        "pose_weapon_3_clip",
        "Pose Weapon 3 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["aimweapon"] = {
        "anim@male@aim_weapon",
        "aim_weapon_clip",
        "Aim Weapon (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["preaimweap"] = {
        "anim@male@preaim_weapon",
        "preaim_weapon_clip",
        "Pre-Aim Weapon (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["runweapon"] = {
        "anim@male@run_weapon",
        "run_weapon_clip",
        "Run Weapon (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["tacticalkneel"] = {
        "anim@male@tactical_kneel",
        "tactical_kneel_clip",
        "Tactical Kneel (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["holdingvest1"] = {
        "anim@male@holding_vest",
        "holding_vest_clip",
        "Holding Vest (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["holdingvest2"] = {
        "anim@male@holding_vest_2",
        "holding_vest_2_clip",
        "Holding Vest 2 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["holdingsidevest"] = {
        "anim@holding_side_vest",
        "holding_side_vest_clip",
        "Holding Side Vest (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["holdsiegevest"] = {
        "anim@male@holding_vest_siege",
        "holding_vest_siege_clip",
        "Holding Siege Vest (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["holdsiegevest2"] = {
        "anim@male@holding_vest_siege_2",
        "holding_vest_siege_2_clip",
        "Holding Siege Vest 2 (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["holdsiegesidevest"] = {
        "anim@holding_siege_vest_side",
        "holding_siege_vest_side_clip",
        "Holding Siege Side Vest (Smos)",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
}
CustomDP.PositionsEmotes = {
    ["pose1"] = {
        "custom@female_pose_1",
        "female_pose_1",
        "Pose 1",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["pose2"] = {
        "custom@female_pose_2",
        "female_pose_2",
        "Pose 2",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["pose3"] = {
        "custom@female_pose_3",
        "female_pose_3",
        "Pose 3",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["pose4"] = {
        "custom@male_pose_1",
        "male_pose_1",
        "Pose 4",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["pose5"] = {
        "custom@male_pose_2",
        "male_pose_2",
        "Pose 5",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["pose6"] = {
        "custom@male_pose_3",
        "male_pose_3",
        "Pose 6",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["sus"] = {
        "custom@suspect",
        "suspect",
        "Suspect",
        AnimationOptions = { EmoteMoving = false }
    },
    ["jsitchair1"] = {
        "timetable@trevor@smoking_meth@base",
        "base",
        "Assis de manière posé",
        AnimationOptions = { EmoteLoop = true }
    },
    ["suit"] = {
        "anim@suit",
        "holding_suit",
        "Tenir son costume",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["pockets"] = {
        "bzzz@animations@hands",
        "bz_hands",
        "Main dans les poches",
        AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
    },
    ["watch"] = {
        "anim@random@shop_clothes@watches",
        "idle_a",
        "Montrer sa montre 1",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["watch2"] = {
        "anim@random@shop_clothes@watches",
        "idle_b",
        "Montrer sa montre 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["watch3"] = {
        "anim@random@shop_clothes@watches",
        "idle_c",
        "Montrer sa montre 3",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["watch4"] = {
        "anim@random@shop_clothes@watches",
        "idle_d",
        "Montrer sa montre 4",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["watch5"] = {
        "anim@random@shop_clothes@watches",
        "idle_e",
        "Montrer sa montre 5",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["saccouder2"] = {
        "missheistdockssetup1ig_12@base",
        "talk_gantry_idle_base_worker4",
        "Accouder flow 02",
        AnimationOptions = { EmoteLoop = true }
    },
    ["saccouder"] = {
        "missheistdockssetup1ig_12@base",
        "talk_gantry_idle_base_worker2",
        "Accouder flow 01",
        AnimationOptions = { EmoteLoop = true }
    }
}
CustomDP.AutresEmotes = {
    ["dig"] = {
        "custom@dig",
        "dig",
        "Creuser",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["copsearch"] = {
        "custom@police",
        "police",
        "Recherche de flics",
        AnimationOptions = { EmoteMoving = false, EmoteDuration = 8000 }
    },
    ["whatidk"] = {
        "custom@what_idk",
        "what_idk",
        "Quoi ? Je ne sais pas",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["jkhaby"] = {
        "missarmenian3@simeon_tauntsidle_b",
        "areyounotman",
        "C'est pas compliqué",
        AnimationOptions = { EmoteMoving = false, EmoteDuration = 2500 }
    },
    ["jdepressed"] = {
        "oddjobs@bailbond_hobodepressed",
        "base",
        "Etre dépressif",
        AnimationOptions = { EmoteMoving = true }
    },
    ["jcarlowrider"] = {
        "anim@veh@lowrider@low@front_ds@arm@base",
        "sit",
        "Pose Lowrider",
        AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
    },
    ["jselfie5"] = {
        "cellphone@self",
        "selfie",
        "Se filmer avec son téléphone",
        AnimationOptions = {
            EmoteMoving = false,
            Prop = "prop_npc_phone_02",
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteLoop = true
        }
    },
    ["jgangaim"] = {
        "combat@aim_variations@1h@gang",
        "aim_variation_b",
        "Braquer quelqu'un",
        AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
    },
    ["jpbox"] = {
        "mp_am_hold_up",
        "purchase_beerbox_shopkeeper",
        "Donner un carton",
        AnimationOptions = { EmoteMoving = false, EmoteDuration = 2500 }
    },
    ["jch"] = {
        "amb@code_human_police_investigate@idle_b",
        "idle_f",
        "Enquêter",
        AnimationOptions = { EmoteMoving = false, EmoteDuration = 7000 }
    },
    ["pavehcar1l"] = {
        "pavehcar1l@animations",
        "pavehcar1lclip",
        "Veh Sit-Up Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar1r"] = {
        "pavehcar1r@animations",
        "pavehcar1rclip",
        "Veh Sit-Up Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar2r"] = {
        "pavehcar2r@animations",
        "pavehcar2rclip",
        "Veh Hold On Tight Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar2l"] = {
        "pavehcar2l@animations",
        "pavehcar2lclip",
        "Veh Hold On Tight Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar3r"] = {
        "pavehcar3r@animations",
        "pavehcar3rclip",
        "Veh Sit Relaxs Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar3l"] = {
        "pavehcar3l@animations",
        "pavehcar3lclip",
        "Veh Sit Relaxs Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar4r"] = {
        "pavehcar4r@animations",
        "pavehcar4rclip",
        "Veh Sit and Wave Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar4l"] = {
        "pavehcar4l@animations",
        "pavehcar4lclip",
        "Veh Sit Cool Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar5r"] = {
        "pavehcar5r@animations",
        "pavehcar5rclip",
        "Veh Rock And Roll Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar5l"] = {
        "pavehcar5l@animations",
        "pavehcar5lclip",
        "Veh Rock And Roll Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar6r"] = {
        "pavehcar6r@animations",
        "pavehcar6rclip",
        "Veh Sit Relaxs Roof Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar6l"] = {
        "pavehcar6l@animations",
        "pavehcar6lclip",
        "Veh Sit Relaxs Roof Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar7r"] = {
        "pavehcar7r@animations",
        "pavehcar7rclip",
        "Veh Sit Happy Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar7l"] = {
        "pavehcar7l@animations",
        "pavehcar7lclip",
        "Veh Sit Happy Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar8r"] = {
        "pavehcar8r@animations",
        "pavehcar8rclip",
        "Veh Sleep Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar8l"] = {
        "pavehcar8l@animations",
        "pavehcar8lclip",
        "Veh Sleep Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar9r"] = {
        "pavehcar9r@animations",
        "pavehcar9rclip",
        "Veh Take Video Right",
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
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar9l"] = {
        "pavehcar9l@animations",
        "pavehcar9lclip",
        "Veh Take Video Left",
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
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pavehcar10"] = {
        "pavehcar10@animations",
        "pavehcar10clip",
        "Veh Sit Enjoy Lucia",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar1"] = {
        "pbvehcar1@animations",
        "pbvehcar1clip",
        "Veh Sit Here I Am",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar2"] = {
        "pbvehcar2@animations",
        "pbvehcar2clip",
        "Veh Sit Enjoy The Wind",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar3r"] = {
        "pbvehcar3r@animations",
        "pbvehcar3rclip",
        "Veh Sit Enjoy The Ride Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar3l"] = {
        "pbvehcar3l@animations",
        "pbvehcar3lclip",
        "Veh Sit Enjoy The Ride Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar4r"] = {
        "pbvehcar4r@animations",
        "pbvehcar4rclip",
        "Veh Sit Enjoy The Ride 2 Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar4l"] = {
        "pbvehcar4l@animations",
        "pbvehcar4lclip",
        "Veh Sit Enjoy The Ride 2 Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar5r"] = {
        "pbvehcar5r@animations",
        "pbvehcar5rclip",
        "Veh Sit Looking The View Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar5l"] = {
        "pbvehcar5l@animations",
        "pbvehcar5lclip",
        "Veh Sit Looking The View Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar6r"] = {
        "pbvehcar6r@animations",
        "pbvehcar6rclip",
        "Veh Twerk Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar6l"] = {
        "pbvehcar6l@animations",
        "pbvehcar6lclip",
        "Veh Twerk Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar7l"] = {
        "pbvehcar7l@animations",
        "pbvehcar7lclip",
        "Veh Standing At The Driver Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar8"] = {
        "pbvehcar8@animations",
        "pbvehcar8clip",
        "Veh Sleep On The Roof",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar9"] = {
        "pbvehcar9@animations",
        "pbvehcar9clip",
        "Veh Sit Relaxs On The Roof",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pbvehcar10"] = {
        "pbvehcar10@animations",
        "pbvehcar10clip",
        "Veh Relaxs On The Roof",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar1"] = {
        "pcvehcar1@animations",
        "pcvehcar1clip",
        "Veh Sit Enjoy On The Roof",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar2r"] = {
        "pcvehcar2r@animations",
        "pcvehcar2rclip",
        "Veh Sit Trunk Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar2l"] = {
        "pcvehcar2l@animations",
        "pcvehcar2lclip",
        "Veh Sit Trunk Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar3r"] = {
        "pcvehcar3r@animations",
        "pcvehcar3rclip",
        "Veh Sit Trunk Lower Right",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar3l"] = {
        "pcvehcar3l@animations",
        "pcvehcar3lclip",
        "Veh Sit Trunk Lower Left",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    -- ["pcvehcar4r"] = {
    --     "pcvehcar4r@animations",
    --     "pcvehcar4rclip",
    --     "Veh Fly Right",
    --     AnimationOptions = {
    --         EmoteLoop = true,
    --         EmoteMoving = true,
    --         FullBody = true
    --     }
    -- },
    -- ["pcvehcar4l"] = {
    --     "pcvehcar4l@animations",
    --     "pcvehcar4lclip",
    --     "Veh Fly Left",
    --     AnimationOptions = {
    --         EmoteLoop = true,
    --         EmoteMoving = true,
    --         FullBody = true
    --     }
    -- },
    -- ["pcvehcar5"] = {
    --     "pcvehcar5@animations",
    --     "pcvehcar5clip",
    --     "Veh Fly Random",
    --     AnimationOptions = {
    --         EmoteLoop = true,
    --         EmoteMoving = true,
    --         FullBody = true
    --     }
    -- },
    -- ["pcvehcar6"] = {
    --     "pcvehcar6@animations",
    --     "pcvehcar6clip",
    --     "Veh Fly Higher",
    --     AnimationOptions = {
    --         EmoteLoop = true,
    --         EmoteMoving = true,
    --         FullBody = true
    --     }
    -- },
    ["pcvehcar7"] = {
        "pcvehcar7@animations",
        "pcvehcar7clip",
        "Veh Motorcycle Hold On Tight",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar8"] = {
        "pcvehcar8@animations",
        "pcvehcar8clip",
        "Veh Motorcycle Two Gun",
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
            EmoteMoving = true,
            FullBody = true
        }
    },
    ["pcvehcar9"] = {
        "pcvehcar9@animations",
        "pcvehcar9clip",
        "Veh Motorcycle Sit Facing Back",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = true,
            FullBody = true
        }
    },
    ----------------------------------
    ----------------------------------
    ["aimweapon3"] = {
        "anim@male@aim_weapon_3",
        "aim_weapon_3_clip",
        "Aim Weapon 3",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimweaponsit"] = {
        "anim@male@aim_weapon_sit",
        "aim_weapon_sit_clip",
        "Aim Weapon Sit",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["handgunpose"] = {
        "anim@male@handgun_pose",
        "handgun_pose_clip",
        "Handgun Pose",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["handgunpose2"] = {
        "anim@male@handgun_pose_2",
        "handgun_pose_2_clip",
        "Handgun Pose 2",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["holdingweapon7"] = {
        "anim@male@holding_weapon_7",
        "holding_weapon_7_clip",
        "Holding Weapon 7",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimweapon6"] = {
        "anim@male@aim_weapon_6",
        "aim_weapon_6_clip",
        "Aim Weapon 6",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimweapon6kneel"] = {
        "anim@male@aim_weapon_6_kneel",
        "aim_weapon_6_kneel_clip",
        "Aim Weapon 6 Kneel",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimweapon6walk"] = {
        "anim@male@aim_weapon_6_walk",
        "aim_weapon_6_walk_clip",
        "Aim Weapon 6 Walk",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimweapon6ak"] = {
        "anim@male@aim_weapon_6_ak",
        "aim_weapon_6_ak_clip",
        "Aim Weapon 6 AK",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimweapon6akkneel"] = {
        "anim@male@aim_weapon_6_ak_kneel",
        "aim_weapon_6_ak_kneel_clip",
        "Aim Weapon 6 AK Kneel",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimcar"] = {
        "anim@aim_car",
        "aim_car_clip",
        "Aim Car",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["stackpistol"] = {
        "anim@stack_pistol",
        "stack_pistol_clip",
        "Stack Pistol",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["aimup"] = {
        "anim@aim_up",
        "aim_up_clip",
        "Aim Up",
        AnimationOptions = {
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
}
CustomDP.ActivitesEmotes = {
    ["parcours01"] = {
        "parkour@anims",
        "big_jump_01",
        "Faire du parcours - 1",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours02"] = {
        "parkour@anims",
        "front_twist_flip",
        "Faire du parcours - 2",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours03"] = {
        "parkour@anims",
        "jump_over_01",
        "Faire du parcours - 3",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours04"] = {
        "parkour@anims",
        "jump_over_02",
        "Faire du parcours - 4",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours05"] = {
        "parkour@anims",
        "slide_kip_up",
        "Faire du parcours - 5",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours06"] = {
        "parkour@anims",
        "jump_over_03",
        "Faire du parcours - 6",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours07"] = {
        "parkour@anims",
        "slide_backside",
        "Faire du parcours - 7",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours08"] = {
        "parkour@anims",
        "slide",
        "Faire du parcours - 8",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours09"] = {
        "parkour@anims",
        "swing_jump",
        "Faire du parcours - 9",
        AnimationOptions = { EmoteLoop = false }
    },
    ["parcours10"] = {
        "parkour@anims",
        "wall_flip",
        "Faire du parcours - 10",
        AnimationOptions = { EmoteLoop = false }
    },
    ["pickfromground"] = {
        "custom@pickfromground",
        "pickfromground",
        "Choisir dans le sol",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["pluck"] = {
        "custom@pluck_fruits",
        "pluck_fruits",
        "Cueillir des fruits",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    },
    ["waiter"] = {
        "custom@waiter",
        "waiter",
        "Serveur",
        AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
    }
}
CustomDP.GangEmotes = {
    ["anim60s"] = {
        "60anim@animation",
        "60anim_clip",
        "Signe 60 Block",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["bal1"] = {
        "bal1@animation",
        "bal1_clip",
        "Ballas 1",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["bal2"] = {
        "bal2@animation",
        "bal2_clip",
        "Ballas 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["fam1"] = {
        "fam1@animation",
        "fam1_clip",
        "Families 1",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["fam2"] = {
        "fam2@animation",
        "fam2_clip",
        "Families 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["vag1"] = {
        "vag1@animation",
        "vag1_clip",
        "Vagos 1",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["vag2"] = {
        "vag2@animation",
        "vag2_clip",
        "Vagos 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["pipougang"] = {
        "custom@mgsign_01",
        "mgsign_01",
        "Pipou gang",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["gchoowook"] = {
        "94glockychoowook@animation",
        "choowook_clip",
        "Gang Sign CHOO/WOOK",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gdoaogzk"] = {
        "94glockydoaogzk@animation",
        "doaogzk_clip",
        "Gang Sign DOA/OGzK",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gmovin"] = {
        "94glockymovin@animation",
        "movin_clip",
        "Gang Sign M8v3N",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gmakk"] = {
        "94glockymakk@animation",
        "makkballa_clip",
        "Gang Sign Makk Balla",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["goyogzk"] = {
        "oyogzk@94glocky",
        "94glockyoyogzk_clip",
        "Gang Sign OYOGzK",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["anim60s2"] = {
        "anim@60sv2",
        "60sv2_clip",
        "Signe 60 Block 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsixfinger"] = {
        "anim@sixfingers",
        "six_clip",
        "Signe Six Finger",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gnhtnh"] = {
        "anim@nhtnh",
        "nhtnh_clip",
        "Signe NHTNH",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gnayba"] = {
        "anim@nayba",
        "nayba_clip",
        "Signe Nayba",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gfcktrays"] = {
        "anim@fcktrays",
        "fcktrays_clip",
        "Signe Fuck Trays",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["dhandsup"] = {
        "drillpack@karxem",
        "handsup",
        "Drill Hands Up",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["dpour"] = {
        "drillpack@karxem",
        "pour",
        "Drill Pour",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["dcrossfinger"] = {
        "drillpack@karxem",
        "crossfinger",
        "Drill Crossfinger",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["dnope"] = {
        "drillpack@karxem",
        "nope",
        "Drill Nope",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gplayboy"] = {
        "anim@playboyig",
        "playboy_clip",
        "Signe Playboy",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsureno"] = {
        "anim@sureno",
        "sureno_clip",
        "Signe Sureno",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsureno2"] = {
        "sureno@thrtn",
        "thrtn_clip",
        "Signe Sureno 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["grabbit1"] = {
        "sureno@rabbit1",
        "rabbit_clip",
        "Signe Rabbit",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["anim30s"] = {
        "sign@ninety",
        "ninety_clip",
        "Signe 30s",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["anim30s2"] = {
        "sign@ninety2",
        "ninety2_clip",
        "Signe 30s 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["anim90s"] = {
        "signs@30s",
        "thirty_clip",
        "Signe 90s",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["anim90s2"] = {
        "signs@30s2",
        "thirty2_clip",
        "Signe 90s 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign01"] = {
        "custom@gsign_05",
        "gsign_05",
        "Signe Gang 1",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["gsign02"] = {
        "custom@gsign_33",
        "gsign_33",
        "Signe Gang 2",
        AnimationOptions = { EmoteLoop = false }
    },
    ["gsign03"] = {
        "grapes@sign",
        "grapes",
        "Signe Gang 3",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign04"] = {
        "grapes@sign2",
        "grapes",
        "Signe Gang 4",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign05"] = {
        "grapes@sign3",
        "sign",
        "Signe Gang 5",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign06"] = {
        "grapes@sign4",
        "sign",
        "Signe Gang 6",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign07"] = {
        "anim@guttagang",
        "gutta_clip",
        "Signe Gang 7",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign08"] = {
        "byrd@sign",
        "sign",
        "Signe Gang 8",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign09"] = {
        "byrd@sign2",
        "sign",
        "Signe Gang 9",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign10"] = {
        "byrd@sign3",
        "sign",
        "Signe Gang 10",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign11"] = {
        "byrd@sign4",
        "sign",
        "Signe Gang 11",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign12"] = {
        "byrd@sign5",
        "sign",
        "Signe Gang 12",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign13"] = {
        "byrd@sign6",
        "sign",
        "Signe Gang 13",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign14"] = {
        "fucknapps@animation",
        "fucknapps_clip",
        "Signe Gang 14",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign15"] = {
        "hooversit@animation",
        "hooversit_clip",
        "Signe Gang 15",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign16"] = {
        "pistolstand@animation",
        "pistolstand_clip",
        "Signe Gang 16",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign17"] = {
        "hooverlean@animation",
        "hooverlean_clip",
        "Signe Gang 17",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign18"] = {
        "b_k@sharror",
        "b_k_clip_ierrorr",
        "Signe Gang 18",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign19"] = {
        "victory@sharror",
        "victory_clip_ierrorr",
        "Signe Gang 19",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign20"] = {
        "blood@sharror",
        "blood_clip_ierrorr",
        "Signe Gang 20",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign21"] = {
        "compton_crip@sharror",
        "compton_crip_clip_ierrorr",
        "Signe Gang 21",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign22"] = {
        "crip@sharror",
        "crip_clip_ierrorr",
        "Signe Gang 22",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign23"] = {
        "eastside@sharror",
        "eastside_clip_ierrorr",
        "Signe Gang 23",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign24"] = {
        "hoover_crip_gun@sharror",
        "hoover_crip_gun_clip_ierrorr",
        "Signe Gang 24",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign25"] = {
        "killa_gun@sharror",
        "killa_gun_clip_ierrorr",
        "Signe Gang 25",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign26"] = {
        "latin_kings@sharror",
        "latin_kings_clip_ierrorr",
        "Signe Gang 26",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign27"] = {
        "mafia_crips@sharror",
        "mafia_crips_clip_ierrorr",
        "Signe Gang 27",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign28"] = {
        "piru@sharror",
        "piru_clip_ierrorr",
        "Signe Gang 28",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign29"] = {
        "underground_crips@sharror",
        "underground_crips_clip_ierrorr",
        "Signe Gang 29",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign30"] = {
        "westcoast@sharror",
        "westcoast_clip_ierrorr",
        "Signe Gang 30",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    },
    ["gsign31"] = {
        "westside_westcoast@sharror",
        "westside_westcoast_clip_ierrorr",
        "Signe Gang 31",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = false }
    }
}
CustomDP.SportEmotes = {
    ["circle_crunch"] = {
        "custom@circle_crunch",
        "circle_crunch",
        "Tourner ses mains en rond",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    }
}
CustomDP.SanteEmotes = {
    ["convulsion"] = {
        "custom@convulsion",
        "convulsion",
        "Convulsion",
        AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
    }
}
CustomDP.PropEmotes = {
    ["ptrashcana"] = {
        "ptrashcana@animations",
        "ptrashcanaclip",
        "Trash Can Hide A Loop",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanb"] = {
        "ptrashcanb@animations",
        "ptrashcanbclip",
        "Trash Can Hide A Look & Peek",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.06,
                -0.1170,
                -0.090,
                -90,
                0,
                18.00,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanc"] = {
        "ptrashcanc@animations",
        "ptrashcancclip",
        "Trash Can Hide A Peek",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcand"] = {
        "ptrashcand@animations",
        "ptrashcandclip",
        "Trash Can Stuck Struggle",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                -0.02,
                -0.5900,
                0.030,
                -88.000,
                0,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcane"] = {
        "ptrashcane@animations",
        "ptrashcaneclip",
        "Trash Can Stuck Upside Down",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 39317,
            PropPlacement = {
                0,
                -0.100,
                0.0,
                -90.000,
                0,
                -20,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanf"] = {
        "ptrashcanf@animations",
        "ptrashcanfclip",
        "Trash Can Stuck Flip",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 18905,
            PropPlacement = {
                0.15,
                0.100,
                0.050,
                -9.400,
                -160.280,
                -3.40,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcang"] = {
        "ptrashcang@animations",
        "ptrashcangclip",
        "Trash Can Full Stuck Upside Down",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.1100,
                0.050,
                -9.51,
                -162.25,
                -3.0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanh"] = {
        "ptrashcanh@animations",
        "ptrashcanhclip",
        "Trash Can Hide B Loop",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.100,
                0.725,
                0.000,
                180,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcani"] = {
        "ptrashcani@animations",
        "ptrashcaniclip",
        "Trash Can Hide B Sneaky",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.100,
                0.80,
                0.000,
                180,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanj"] = {
        "ptrashcanj@animations",
        "ptrashcanjclip",
        "Trash Can Hide B Walk",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.005,
                0.125,
                0.780,
                0.000,
                180,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcank"] = {
        "ptrashcank@animations",
        "ptrashcankclip",
        "Trash Can Hide B Panic",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.005,
                0.125,
                0.780,
                0.000,
                180,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanl"] = {
        "ptrashcanl@animations",
        "ptrashcanlclip",
        "Trash Can Hide B Run For Your Lifeee",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.580,
                0.1500,
                0,
                10.000,
                -90,
                0,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanm"] = {
        "ptrashcanm@animations",
        "ptrashcanmclip",
        "Trash Can Dance Happy 1",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.70,
                0.175,
                0,
                10.000,
                -90,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcann"] = {
        "ptrashcann@animations",
        "ptrashcannclip",
        "Trash Can Dance Happy 2",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.70,
                0.175,
                0,
                10.000,
                -90,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcano"] = {
        "ptrashcano@animations",
        "ptrashcanoclip",
        "Trash Can Dance Happy 3",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.70,
                0.175,
                0,
                10.000,
                -90,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanp"] = {
        "ptrashcanp@animations",
        "ptrashcanpclip",
        "Trash Can Cool Lean",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanq"] = {
        "ptrashcanq@animations",
        "ptrashcanqclip",
        "Trash Can Jump Slow",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanr"] = {
        "ptrashcanr@animations",
        "ptrashcanrclip",
        "Trash Can Jump Fast",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcans"] = {
        "ptrashcans@animations",
        "ptrashcansclip",
        "Trash Can Jump Long",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcant"] = {
        "ptrashcant@animations",
        "ptrashcantclip",
        "Trash Can Turtle Stuck",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.4100,
                -0.340,
                -40,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanu"] = {
        "ptrashcanu@animations",
        "ptrashcanuclip",
        "Trash Can Turtle Enjoy",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.4100,
                -0.340,
                -40,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanv"] = {
        "ptrashcanv@animations",
        "ptrashcanvclip",
        "Trash Can Turtle Walk Struggle",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.470,
                -0.390,
                -40,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanw"] = {
        "ptrashcanw@animations",
        "ptrashcanwclip",
        "Trash Can Turtle Walk Normal",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.400,
                -0.440,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanx"] = {
        "ptrashcanx@animations",
        "ptrashcanxclip",
        "Trash Can Turtle Walk Panic",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.400,
                -0.440,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcany"] = {
        "ptrashcany@animations",
        "ptrashcanyclip",
        "Trash Can Hide C Look Around",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanz"] = {
        "ptrashcanz@animations",
        "ptrashcanzclip",
        "Trash Can Hide C Loop",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.03,
                -0.1300,
                0.02,
                -98,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanza"] = {
        "ptrashcanza@animations",
        "ptrashcanzaclip",
        "Trash Can Spin",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.03,
                -0.1300,
                0.02,
                -98,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzb"] = {
        "ptrashcanzb@animations",
        "ptrashcanzbclip",
        "Trash Can Spin Fast",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.03,
                -0.1300,
                0.02,
                -98,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzc"] = {
        "ptrashcanzc@animations",
        "ptrashcanzcclip",
        "Trash Can Roll Slow",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzd"] = {
        "ptrashcanzd@animations",
        "ptrashcanzdclip",
        "Trash Can Roll Fast",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanze"] = {
        "ptrashcanze@animations",
        "ptrashcanzeclip",
        "Trash Can Roll Out Of Control",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzf"] = {
        "ptrashcanzf@animations",
        "ptrashcanzfclip",
        "Trash Can Cool Sit 1",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.10,
                -0.150,
                164.9,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzg"] = {
        "ptrashcanzg@animations",
        "ptrashcanzgclip",
        "Trash Can Cool Sit 2",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.10,
                -0.150,
                169.9,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzh"] = {
        "ptrashcanzh@animations",
        "ptrashcanzhclip",
        "Trash Can Impossible Pose 1",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.120,
                -0.980,
                00,
                -90,
                0,
                -20.000,
            },
            SecondProp = 'prop_recyclebin_03_a',
            SecondPropBone = 64097,
            SecondPropPlacement = {
                0.20,
                -0.20,
                0.000,
                -38.255,
                74.42,
                12.700,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzi"] = {
        "ptrashcanzi@animations",
        "ptrashcanziclip",
        "Trash Can Impossible Pose 2",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 14201,
            PropPlacement = {
                0.10,
                -0.050,
                0.0,
                90,
                0,
                20,
            },
            SecondProp = 'prop_recyclebin_03_a',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.140,
                0.10,
                0.000,
                -90,
                0,
                -40,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzj"] = {
        "ptrashcanzj@animations",
        "ptrashcanzjclip",
        "Trash Can Impossible Pose 3",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.110,
                -0.050,
                -0.150,
                90,
                0,
                20.000,
            },
            SecondProp = 'prop_recyclebin_03_a',
            SecondPropBone = 24817,
            SecondPropPlacement = {
                0.09,
                -0.10,
                0.000,
                90,
                0,
                5.0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzk"] = {
        "ptrashcanzk@animations",
        "ptrashcanzkclip",
        "Trash Can Carry 1",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 57005,
            PropPlacement = {
                0.090,
                -0.640,
                -0.37,
                -85.076,
                -0.867,
                -0.037,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanzl"] = {
        "ptrashcanzl@animations",
        "ptrashcanzlclip",
        "Trash Can Carry 2",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 57005,
            PropPlacement = {
                -0.17,
                -0.370,
                -0.370,
                -79.372,
                3.616,
                -19.683,
            },
            SecondProp = 'prop_bin_07d',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                -0.15,
                -0.34,
                0.370,
                -100.62,
                -3.616,
                -19.683,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanzm"] = {
        "ptrashcanzm@animations",
        "ptrashcanzmclip",
        "Trash Can Carry Overhead",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 57005,
            PropPlacement = {
                -0.090,
                0.060,
                -0.31,
                0,
                79.999,
                0,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanzn"] = {
        "ptrashcanzn@animations",
        "ptrashcanznclip",
        "Trash Can I Can't See",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 24818,
            PropPlacement = {
                1.04,
                0.10,
                0.0,
                0,
                -90,
                -10,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["card"] = {
        "card@animation",
        "card_clip",
        "Montrer sa carte d'identité",
        AnimationOptions = {
            Prop = "p_ld_id_card_01",
            PropBone = 60309,
            PropPlacement = { 0.129, 0.035, 0.068, -80.0, 140.0, 0.0 },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["copradio"] = {
        "copradio@animation",
        "copradio_clip",
        "Radio de Police",
        AnimationOptions = {
            Prop = "prop_cs_walkie_talkie",
            PropBone = 28422,
            PropPlacement = { 0.1, 0.07, 0.0, 40.0, 40.0, 170.0 },
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["radio1"] = {
        "anim@radio_left",
        "radio_left_clip",
        "Parler a sa radio 1",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["radio2"] = {
        "anim@male@holding_radio",
        "holding_radio_clip",
        "Parler a sa radio 2",
        AnimationOptions = { EmoteLoop = true, EmoteMoving = true }
    },
    ["pallet1"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot 1",
        AnimationOptions = {
            Prop = "prop_pallettruck_01",
            PropBone = -1,
            PropPlacement = { 0.0, 1.6, -1.15, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pallet2"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot 2",
        AnimationOptions = {
            Prop = "prop_pallettruck_02",
            PropBone = -1,
            PropPlacement = { 0.0, 1.6, -1.15, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pallet3"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_one",
        "Charriot 3",
        AnimationOptions = {
            Prop = "prop_sacktruck_02b",
            PropBone = -1,
            PropPlacement = { 0.0, 1.45, -0.8, -30.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pallet4"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot 4",
        AnimationOptions = {
            Prop = "prop_flattruck_01c",
            PropBone = -1,
            PropPlacement = { 0.0, 1.3, -0.97, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pallet5"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot 5",
        AnimationOptions = {
            Prop = "prop_flattruck_01d",
            PropBone = -1,
            PropPlacement = { 0.0, 1.3, -0.97, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pallet6"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot 6",
        AnimationOptions = {
            Prop = "prop_flattruck_01a",
            PropBone = -1,
            PropPlacement = { 0.0, 1.3, -0.97, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["pallet7"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot 7",
        AnimationOptions = {
            Prop = "prop_rub_trolley01a",
            PropBone = -1,
            PropPlacement = { 0.0, 1.1, -0.4, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["palletc2"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot avec poids 1",
        AnimationOptions = {
            Prop = "prop_pallettruck_01",
            PropBone = -1,
            PropPlacement = { 0.0, 1.6, -1.15, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            SecondProp = 'ex_prop_crate_jewels_racks_sc',
            SecondPropBone = -1,
            SecondPropPlacement = { 0.0, 2.0, -1.0, 0.0, 0.0, 180.0 },
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    ["palletc3"] = {
        "anim@mp_ferris_wheel",
        "idle_a_player_two",
        "Charriot avec poids 2",
        AnimationOptions = {
            Prop = "prop_pallettruck_01",
            PropBone = -1,
            PropPlacement = { 0.0, 1.6, -1.15, 0.0, 0.0, 180.0 },
            WeightCapacitor = 'pallet',
            --
            SecondProp = 'ex_prop_crate_money_sc',
            SecondPropBone = -1,
            SecondPropPlacement = { 0.0, 2.0, -1.0, 0.0, 0.0, 180.0 },
            --
            EmoteLoop = true,
            EmoteMoving = true
        }
    },
    --New Animtations Props Leo

    ["gcuspose53"] = {
        "glap@custom-pose-5",
        "custom-pose-5-3-1_clip",
        "Girl G Pose 5.3.1",
        AnimationOptions =
        {
            Prop = "prop_chair_03",
            PropBone = 11816,
            PropPlacement = { 0.55, -0.18, 0.0, 25.19, -87.99, -535.36 },
            EmoteLoop = true,
            EmoteMoving = false
        }
    },
    ["nekoleanbar5"] = {
        "switch@michael@pier",
        "pier_lean_smoke_idle",
        "Neko Lean Bar 5",
        AnimationOptions =
        {
            Prop = 'prop_cs_ciggy_01',
            PropBone = 58867,
            PropPlacement = { 0.0599999, 0.005, -0.015, 40.29999, 78.3, 124.1 },
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekoleanbar6"] = {
        "switch@michael@pier",
        "pier_lean_smoke_idle",
        "Neko Lean Bar 6",
        AnimationOptions =
        {
            Prop = 'p_cs_joint_02',
            PropBone = 58867,
            PropPlacement = { 0.0599999, 0.005, -0.015, 40.29999, 78.3, 124.1 },
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["nekodrunk"] = {
        "missbigscore1leadinoutbs_1_int",
        "leadin_loop_c_trevor",
        "Neko Drunk",
        AnimationOptions =
        {
            Prop = 'prop_wine_rose',
            PropBone = 58867,
            PropPlacement = { 0.02499996, -0.009999998, -0.3599998, 172.9002, 183.6, 155.3 },
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["fselfie5"] = {
        "mggyselfie4@animation",
        "mggyselfie4_clip",
        "Female Selfie 5",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = "scrlt_iphone14max_06",
            PropBone = 36029,
            PropPlacement = { 0.0900, 0.0100, 0.0300, -96.0709109, 5.2148816, -64.121046 },
        }
    },
    ["jreadmessages"] = {
        "anim@amb@carmeet@take_photos@male_a@base",
        "base",
        "Read Messages · Male",
        AnimationOptions =
        {
            Prop = "scrlt_iphone14max_02",
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["jreadmessages2"] = {
        "anim@amb@carmeet@take_photos@female_b@base",
        "base",
        "Read Messages 2 · Female",
        AnimationOptions =
        {
            Prop = "scrlt_iphone14max_01",
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["jgangdrink"] = {
        "amb@world_human_drinking_fat@beer@male@base",
        "base",
        "Gang Drink",
        AnimationOptions =
        {
            Prop = 'prop_cs_beer_bot_40oz_03',
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["jgangdrink2"] = {
        "amb@world_human_drinking_fat@beer@male@idle_a",
        "idle_b",
        "Gang Drink 2",
        AnimationOptions =
        {
            Prop = 'prop_cs_beer_bot_40oz_03',
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["jtextingmale"] = {
        "amb@world_human_stand_mobile_fat@male@text@base",
        "base",
        "Texting · Male",
        AnimationOptions =
        {
            Prop = "scrlt_iphone14max_05",
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["pcvehcar8"] = {"pcvehcar8@animations", "pcvehcar8clip", "Veh Motorcycle Two Gun", AnimationOptions =
    {
        Prop = 'w_pi_pistol',
        PropBone = 26611,
        PropPlacement = {0.07, -.01, 0.01, -29.999, 0.0, 10.000},
        SecondProp = 'w_pi_pistol',
        SecondPropBone = 58867,
        SecondPropPlacement = {0.07, 0.01, 0.01, 29.999, 0.0, -10.000 },
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["pcvehcar9"] = {"pcvehcar9@animations", "pcvehcar9clip", "Veh Motorcycle Sit Facing Back", AnimationOptions =
    {
        EmoteLoop = true,
        FullBody =true,
        EmoteMoving = false
    }},
    ["gsign064"] = {"qpacc@regularstance33", "regularstance33_clip", "Regular Stance 33 Money Pose", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 64096,
        PropPlacement = {0.0900, 0.0160, -0.0300, 0.2461856, 0.7872477, 0.0023882 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign074"] = {"qpacc@regularstance44", "regularstance44_clip", "Regular Stance 44 Money Pose", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 4090,
        PropPlacement = {0.0000, -0.0390, -0.0290, 2.2304, 58.3771, 31.8549},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign078"] = {"qpacc@regularstance48", "regularstance48_clip", "Regular Stance 48 Money Pose", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 64017,
        PropPlacement = {0.0110, -0.0450, -0.0040, 7.4405, -67.5842, -2.3618},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign085"] = {"qpacc@regularstance55", "regularstance55_clip", "Regular Stance 55 Smoke Pose", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4090,
        PropPlacement = {0.0280, -0.0020, 0.0150, -7.0345092, 67.9037057, -17.6946468 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign086"] = {"qpacc@regularstance56", "regularstance56_clip", "Regular Stance 56 Double Fuck", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign087"] = {"qpacc@regularstance57", "regularstance57_clip", "Regular Stance 57 Phone Pose", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_03',
        PropBone = 26611,
        PropPlacement = {0.0450, -0.0280, 0.0010, -3.3698368, 30.0689668, 3.8289125 },
        SecondProp = 'scrlt_iphone14max_05',
        SecondPropBone = 64017,
        SecondPropPlacement = {0.0350, -0.0320, 0.0040, 8.0000, 0.0000, 0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign089"] = {"qpacc@regularstance58", "regularstance58_clip", "Regular Stance 58 Gun Pose & Cup", AnimationOptions =
    {
        Prop = 'prop_plastic_cup_02',
        PropBone = 4089,
        PropPlacement = {0.0410, -0.0120, -0.0150, -170.0000008, 0.00000, -30.000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign097"] = {"qpacc@regularstance66", "regularstance66_clip", "Regular Stance 66 Money Pose", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 4089,
        PropPlacement = {0.0480, 0.0580, -0.0150, -4.5620378, 8.0600729, -42.7619593},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign098"] = {"qpacc@regularstance67", "regularstance67_clip", "Regular Stance 67", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign099"] = {"qpacc@regularstance68", "regularstance68_clip", "Regular Stance 68 Money Pose", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 64097,
        PropPlacement = {0.0100, 0.0150, -0.0260, 11.8467003, 96.6172508, 15.8535182},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0720,-0.0390,-0.0270,0.0000,-100.0000,0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign213"] = {"pose9@94glocky", "94glockypose9_clip", "Gang Sign 213 Lean Cup Props", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 4170,
        PropPlacement = {0.0170,-0.0590,0.0100,0.0000,0.0000,0.0000},
        SecondProp = 'p_watch_04',
        SecondPropBone = 35502,
        SecondPropPlacement = {-0.1800,-0.0010,0.0300,0.0000,0.0000,0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign232"] = {"makkballa@94glocky@kenzoballa", "makkballakenzo_clip", "Gang Sign 232 MBF Kenzo Balla Props", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 64080,
        PropPlacement = {0.0330,0.0430,0.0400,-80.4744,-71.9308, 7.1861},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign237"] = {"crips@pose1@94glocky", "crips194glocky_clip", "Gang Sign 237 Pose C & Smoke", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4169,
        PropPlacement = {0.0410, -0.0320, 0.0010, 0.0000, -99.0, -11.0},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign244"] = {"slime@kr@94glocky", "slimekylerich_clip", "Gang Sign 244 Slime Kyle Rich Pose", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 4169,
        PropPlacement = {0.0980,0.0290,-0.0240,-163.6197,-153.2180,40.0483},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign248"] = {"smokecup@pose@94glocky", "smokecup1_clip", "Gang Sign 248 Smoke Cup", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0450,0.0030,0.0000,61.9707,-67.7540,-1.0330},
        SecondProp = 'p_amb_coffeecup_01',
        SecondPropBone = 4185,
        SecondPropPlacement = {0.0220,-0.0600,0.0000,0.0000,0.0000,0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign252"] = {"posesmoke@1@94glocky", "posesmoke1_clip", "Gang Sign 252 Pose Smoke Duo", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0370, -0.0090, 0.0000, 0.0000, 315.0, 0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign262"] = {"props@pose@1@94glocky", "pp194_clip", "Gang Sign 262 Cyan Flag & Smoke Props", AnimationOptions =
    {
        Prop = 'vw_prop_casino_art_bottle_01a',
        PropBone = 58868,
        PropPlacement = {0.1400,0.2600,0.0400,0.0000,0.0000,0.0000},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0350,-0.0120,0.0000,76.0858,101.2346,30.4004},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign2621"] = {"props@pose@1@94glocky", "pp194_clip", "Gang Sign 262 Red Flag & Smoke Props", AnimationOptions =
    {
        Prop = 'ex_office_swag_jewelwatch',
        PropBone = 58868,
        PropPlacement = {0.1400,0.2600,0.0400,0.0000,0.0000,0.0000},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0350,-0.0120,0.0000,76.0858,101.2346,30.4004},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign2622"] = {"props@pose@1@94glocky", "pp194_clip", "Gang Sign 262 Blue Flag & Smoke Props", AnimationOptions =
    {
        Prop = 'ng_proc_sodacup_03c',
        PropBone = 58868,
        PropPlacement = {0.1400,0.2600,0.0400,0.0000,0.0000,0.0000},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0350,-0.0120,0.0000,76.0858,101.2346,30.4004},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign263"] = {"pose@smokecup@94glocky", "posesmokecup_clip", "Gang Sign 263 Smoke Cup 2 Props", AnimationOptions =
    {
        Prop = 'prop_energy_drink',
        PropBone = 4186,
        PropPlacement = {0.0210,-0.0510,0.0790,0.0000,0.0000,0.0000},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 64017,
        SecondPropPlacement = {0.0360,-0.0120,0.0090,32.7324,-57.2675,24.4044},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign264"] = {"props@blunt@1@94glocky", "pb194_clip", "Gang Sign 264 Smoke Blunt Props (Move)", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0310,-0.0100,0.0200,0.0000,-100.0000, 0.0000},
        SecondProp = 'p_cs_lighter_01',
        SecondPropBone = 4186,
        SecondPropPlacement = {0.0300,-0.0170,0.0190,168.3079,164.6601, 48.9735391 },
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gsign2641"] = {"props@blunt@1@94glocky", "pb194_clip", "Gang Sign 264 Smoke Blunt Props (Fix)", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0310,-0.0100,0.0200,0.0000,-100.0000, 0.0000},
        SecondProp = 'p_cs_lighter_01',
        SecondPropBone = 4186,
        SecondPropPlacement = {0.0300,-0.0170,0.0190,168.3079,164.6601, 48.9735391 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign266"] = {"oyk@tata@94glocky", "tataoyk_clip", "Gang Sign 266 Tata Pose OYK", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 58867,
        PropPlacement = {-0.0010,0.0570,-0.0010,-1.3643,-51.0451, -14.0412},
        SecondProp = 'bkr_prop_money_wrapped_01',
        SecondPropBone = 58867,
        SecondPropPlacement = {0.0260,0.0600,-0.0410,-0.7251,-51.0595,-14.8071},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign268"] = {"gunpose@blunt@94glocky", "gunposeblunt_clip", "Gang Sign 268 Gun Blunt Props", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4090,
        PropPlacement = {0.0340, -0.0040, -0.0210, 180.0000, 90.0000, 40.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign283"] = {"gunpose@from94", "gunposefrom94_clip", "Gang Sign 283 Gun Pose 4 Props", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_06',
        PropBone = 26611,
        PropPlacement = {0.0510, -0.0330, 0.0000, 0.0000, 0.0000, 0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign301"] = {"dthanggz@from94", "dthanggz_clip", "Gang Sign 301 Dthang Gz", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_03',
        PropBone = 26612,
        PropPlacement = {0.0520, -0.0360, -0.0060, -19.9999, 0.0000, -11.9999},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign308"] = {"gunclip@from94", "gunclip94_clip", "Gang Sign 307 Gun Pose 9", AnimationOptions =
    {
        Prop = 'w_pi_appistol',
        PropBone = 64097,
        PropPlacement = {0.0100, 0.0280, -0.0200, 3.6164416, 10.6275841, -19.6834981},
        SecondProp = 'w_pi_appistol_mag2',
        SecondPropBone = 64096,
        SecondPropPlacement = {-0.0300, 0.0400, -0.0020, 4.9728141, -7.2560318, 15.5126862 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign309"] = {"pillspose@from94", "pillspose_clip", "Gang Sign 308 Pills Pose Props", AnimationOptions =
    {
        Prop = 'ba_prop_club_water_bottle',
        PropBone = 4170,
        PropPlacement = {0.0176, -0.0400, -0.0080, -180.0000, -180.0000, 10.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign311"] = {"cuppose@from94", "cuppose_clip", "Gang Sign 310 Cup Pose Props", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 64097,
        PropPlacement = {0.0390, 0.0550, 0.0250, 6.4836, -1.1054, 25.8912},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign312"] = {"settybpose@from94", "settybpose_clip", "Gang Sign 311 Smoke Bottle Props", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64064,
        PropPlacement = {0.0051,-0.0380,0.0481,0.0000,0.0000, 0.0000},
        SecondProp = 'prop_energy_drink',
        SecondPropBone = 58867,
        SecondPropPlacement = {-0.0080,0.0570,-0.0210,17.4952,28.4812,9.8465},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign314"] = {"gunpose@5@from94", "gunpose5_clip", "Gang Sign 313 Gun Pose 10 Props", AnimationOptions =
    {
        Prop = 'w_pi_appistol',
        PropBone = 64096,
        PropPlacement = {0.0321, 0.0100, 0.0030, -4.6293, -11.0096, -24.5947},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign315"] = {"ygz@smoke@from94", "ygzsmoke_clip", "Gang Sign 314 YGz Smoke Props", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4170,
        PropPlacement = {0.0270, -0.0050, 0.0210, -45.6102, -111.1178, 23.2374},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign316"] = {"dthanggz@2@from94", "dthanggz2_clip", "Gang Sign 315 YGz DThang Props", AnimationOptions =
    {
        Prop = 'ba_prop_battle_whiskey_bottle_2_s',
        PropBone = 64081,
        PropPlacement = {-0.0520, 0.0380,-0.0200, -8.8909, -8.8909, 1.4022},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0450,-0.0310,0.0190,136.7808,-133.2191,62.0091},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign324"] = {"smokefuck@from94", "smokefuck_clip", "Gang Sign 323 Smoke Fuck Props", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0330,-0.0100,0.0080, -9.4921, -72.3347, 34.9029},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign325"] = {"syrupcup@from94", "syrupcup_clip", "Gang Sign 324 Syrup Cup Props", AnimationOptions =
    {
        Prop = 'prop_beer_bottle',
        PropBone = 64016,
        PropPlacement = {0.0240, -0.1270,-0.0460, -3.0970, -10.2106, -11.6415},
        SecondProp = 'p_amb_coffeecup_01',
        SecondPropBone = 26611,
        SecondPropPlacement = {0.0240,-0.0620,-0.0070,-19.7197,9.4080,-3.4048},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign326"] = {"hound@from94", "hound_clip", "Gang Sign 325 Hound 2", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_05',
        PropBone = 4169,
        PropPlacement = {0.0240,-0.0220,-0.0020, -26.9999, 0.0000, 0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign328"] = {"graaa@from94", "graaa_clip", "Gang Sign 327 Hound 3 & Props", AnimationOptions =
    {
        Prop = 'prop_energy_drink',
        PropBone = 26613,
        PropPlacement = {0.0270, -0.0490,0.0000, -31.6844, -20.8117, -26.0134},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4186,
        SecondPropPlacement = {0.0130,-0.0090,0.0150,0.0000,0.0000,-79.9999},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign329"] = {"notti@from94", "notti_clip", "Gang Sign 328 Notti Pose Props", AnimationOptions =
    {
        Prop = 'prop_cs_cashenvelope',
        PropBone = 26612,
        PropPlacement = {0.0180, -0.0630,0.0020, 21.0587, -79.8030, 26.2084},
        SecondProp = 'prop_cs_cashenvelope',
        SecondPropBone = 26612,
        SecondPropPlacement = {-0.0300,-0.1100,0.0100,9.9731,-76.8506,26.6466},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign331"] = {"ygzgunpose@from94", "ygzgunpose@clip", "Gang Sign YGz Gun Pose 2", AnimationOptions =
    {
        Prop = 'w_pi_appistol',
        PropBone = 4169,
        PropPlacement = {0.0270, -0.0640,0.0140, -7.6768, 2.9894, -6.4092},
        SecondProp = 'w_pi_combatpistol',
        SecondPropBone = 4169,
        SecondPropPlacement = {-0.0130,-0.0270,0.0140,-7.9468,0.9917,-3.1387},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign334"] = {"makkballa@from94", "makkballa_clip", "Gang Sign 330 MBF 2", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_03',
        PropBone = 4169,
        PropPlacement = {0.0310,-0.0070,0.0260, -29.9999, 0.0000, 10.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign335"] = {"trendy@from94", "trendy_clip", "Gang Sign 331 SMM 3", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4170,
        PropPlacement = {0.0330,-0.0130,0.0150, -28.6668, -93.8271, 13.5870},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign336"] = {"hound2@from94", "hound2_clip", "Gang Sign 332 Hound 4", AnimationOptions =
    {
        Prop = 'prop_beer_bottle',
        PropBone = 26611,
        PropPlacement = {0.0420,-0.0920,-0.1200, -118.0253, 112.2639, 68.3662},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign338"] = {"houndk2@from94", "houndk2_clip", "Gang Sign 334 Hound K 3", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_02',
        PropBone = 4169,
        PropPlacement = {0.0310,-0.0070,0.0260, -29.9999, 0.0000, 10.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign339"] = {"custompose@from94", "custompose_clip", "Gang Sign 335 Drink Pose Props", AnimationOptions =
    {
        Prop = 'prop_energy_drink',
        PropBone = 4138,
        PropPlacement = {0.0200,-0.0480,0.0110, -3.0000, 0.0000, 0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign340"] = {"bandomoney@from94", "bandomoney_clip", "Gang Sign 336 Bando Money Pose", AnimationOptions =
    {
        Prop = 'prop_anim_cash_note_b',
        PropBone = 18905,
        PropPlacement = {0.1320,0.0590,0.0310, -21.4501, -64.0298, -27.4011},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign341"] = {"dthangmoney@from94", "dthangmoney_clip", "Gang Sign 337 DThang Money Pose", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 4186,
        PropPlacement = {0.0310,-0.0470,-0.0020, -69.5285, -85.1123, 15.6198},
        SecondProp = 'bkr_prop_money_unsorted_01',
        SecondPropBone = 64113,
        SecondPropPlacement = {0.0220,0.0520,-0.0010,107.9773,80.5700,6.4065},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign348"] = {"duopose12@nicocsanim", "duopose12_clip", "Gang Sign 344 Smoke", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64016,
        PropPlacement = {0.0960,-0.0750,0.0000, -6.9325499, 83.0674501, 21.2145097  },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign349"] = {"showdat@bhary", "showdat_clip", "Gang Sign 345 Show That", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4090,
        PropPlacement = {0.0390,0.0190,-0.0220, -7.3327677, -158.4091822, 13.2704441 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign350"] = {"facepalm@bhary", "facepalm_clip", "Gang Sign 346 Facepalm", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4089,
        PropPlacement = {0.0690,-0.0180,-0.0050, 100.1510818, -178.2462165, -9.8465523 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign351"] = {"couch@bhary", "couch_clip", "Gang Sign 347 Sit W Gun", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_03',
        PropBone = 64096,
        PropPlacement = {-0.0020,0.0270,-0.0050, -177.7501419, -158.6730351, 22.1605531 },
        SecondProp = 'w_pi_sns_pistol',
        SecondPropBone = 4169,
        SecondPropPlacement = {0.0390, -0.0340, 0.0010, -21.9353525, -7.4185966, 1.9968561 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign352"] = {"drankface@bhary", "drankface_clip", "Gang Sign 348 Drank Face", AnimationOptions =
    {
        Prop = 'prop_beer_bottle',
        PropBone = 4090,
        PropPlacement = {-0.0100, 0.0270, 0.2100, 37.4313292, -150.361315, -54.6694121},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0200, 0.0000, -0.0200, 30.0000001, 180.0000, -40.0000019 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign353"] = {"rollin@from94", "rollin_clip", "Gang Sign 349 Rollin", AnimationOptions =
    {
        Prop = 'vw_prop_vw_backpack_01a',
        PropBone = 4090,
        PropPlacement = {0.5270, -0.1050, 0.0130, -17.0459, -106.5831, -62.8211},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign355"] = {"dthanggz@4@from94", "dthanggz4_clip", "Gang Sign 350 Dthang Money", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 64016,
        PropPlacement = {0.0700, -0.0530, 0.0470, 106.4081246, -86.9139257, 14.4164295},
        SecondProp = 'bkr_prop_money_unsorted_01',
        SecondPropBone = 64016,
        SecondPropPlacement = {0.0380, -0.0220, 0.0000, 67.3136993, 87.4270622, -14.0831107 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign356"] = {"dthanggz@5@from94", "dthanggz5_clip", "Gang Sign 350 Dthang Money", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 64016,
        PropPlacement = {0.0570, -0.0590, 0.0410, 106.4081246, -86.9139257, 14.4164295},
        SecondProp = 'bkr_prop_money_unsorted_01',
        SecondPropBone = 64016,
        SecondPropPlacement = {0.0250, -0.0200, 0.0130, 67.3136993, 87.4270622, -14.0831107 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign357"] = {"nasgpgfuck@from94", "nasgpg_clip", "Gang Sign 351 Fuck Pose", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0400, -0.0500, 0.0400, 17.4952407, 118.4812386, 9.8465523 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign358"] = {"smokestance@from94", "smokestance_clip", "Gang Sign 352 Smoke Pose", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 64017,
        PropPlacement = {0.0380, 0.0280, 0.0310, 4.110867, -147.9458892, 56.0750666},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign359"] = {"dthanggz6@from94", "dthanggz6_clip", "Gang Sign 353 DThang Money 3", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 4090,
        PropPlacement = {0.0000, -0.0380, -0.0170, -104.385204, -96.3561214,-45.7930341},
        SecondProp = 'bkr_prop_money_unsorted_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0000, -0.0900, -0.0400, -109.6567906, -108.0964678, -39.960719},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign360"] = {"ot9@from94", "ot9_clip", "Gang Sign 354 OT9 Alliance", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4090,
        PropPlacement = {0.0280, 0.0040, -0.0170, 105.3398139, 78.3079235, 48.9735391 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign362"] = {"sitwith2gun@from94", "sitwith2gun_clip", "Gang Sign 356 Sit With 2 Gun Pose", AnimationOptions =
    {
        Prop = 'w_pi_pistol',
        PropBone = 26611,
        PropPlacement = {0.0700,-0.0200, 0.0100, -0.7168147, 0.0000,3.0000},
        SecondProp = 'w_pi_pistol',
        SecondPropBone = 58869,
        SecondPropPlacement = {0.0800, 0.0160, 0.0700, -0.9226431, -4.1048612, -12.9677798},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign101"] = {"qpacc@regularstance93", "regularstance93_clip", "Regular Stance 70 Money", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 4090,
        PropPlacement = {-0.0040, -0.0380, 0.0380, -6.2056164, -96.2056164, 14.8687239 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign102"] = {"qpacc@regularstance94", "regularstance94_clip", "Regular Stance 71 Rifle Pose", AnimationOptions =
    {
        Prop = 'w_ar_carbinerifle',
        PropBone = 58867,
        PropPlacement = {-0.0580, 0.1580, -0.2370, -19.295343, -70.704657, -30.4319789},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0710, -0.0370, -0.0310, 3.4511785, -110.2835598, 9.3912858 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign103"] = {"qpacc@regularstance95", "regularstance95_clip", "Regular Stance 72 Rifle Cup", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 64017,
        PropPlacement = {-0.0020, -0.0470, -0.0650, 3.9611968, 7.9807643, 0.556249 },
        SecondProp = 'w_ar_carbinerifle',
        SecondPropBone = 26614,
        SecondPropPlacement = {0.0300, -0.0180, 0.1680, -9.723207, -39.7754439, -2.2968618 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign104"] = {"qpacc@regularstance96", "regularstance96_clip", "Regular Stances 73 Rifle Cup 2", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 64016,
        PropPlacement = {0.0010, -0.0060, -0.0960, 24.3248861,36.3937686,-57.0011521},
        SecondProp = 'w_ar_carbinerifle',
        SecondPropBone = 4186,
        SecondPropPlacement = {-0.0100, -0.0300, 0.0600, -10.0000001, 0.0000, 11.9999997},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign391"] = {"ygzcupsmoke@from94", "ygzcupsmoke_clip", "Gang Sign 380 YGz Cup Smoke", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 64065,
        PropPlacement = {-0.0200, -0.0300, 0.0500, 0.0000 , 0.0000, 0.0000},
        SecondProp = 'prop_beer_bottle',
        SecondPropBone = 64016,
        SecondPropPlacement = {0.0470, -0.0570, -0.0770, -8.3550282, 8.2786576, 15.9986359},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign392"] = {"mbmb@from94", "mbmb_clip", "Gang Sign 381 Makk Balla Cup", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 26611,
        PropPlacement = {0.0320, -0.0560, 0.0700, 0.0000 , -10.0000003, 0.0000},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign415"] = {"rundown@from94", "rundown_clip", "Gang Sign 389 Rundown Pose", AnimationOptions =
    {
        Prop = 'w_ar_assaultrifle',
        PropBone = 64096,
        PropPlacement = {0.0100, 0.0300, 0.0000, 1.7537835, 10.1510818, -9.8465523},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0400, -0.0100, 0.0000, -11.8371427, 160.9765143, -37.4361423},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign416"] = {"fuckcupsmoke@from94", "fuckcupsmoke_clip", "Gang Sign 390 Fuck Cup Smoke", AnimationOptions =
    {
        Prop = 'p_amb_coffeecup_01',
        PropBone = 26613,
        PropPlacement = {0.0890, -0.1510, -0.0210,-47.4053252,-77.2705853, -14.2237612},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4170,
        SecondPropPlacement = {0.0100, -0.0040, -0.0100, -71.0000004, 0.0000,-79.9999923},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign421"] = {"spotemmoneypose@from94", "spotemmoneypose_clip", "Gang Sign 394 Spotem Money Pose", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 4138,
        PropPlacement = {0.0520, -0.0690, 0.0100, 110.2835598, -86.5488215, -9.3912858},
        SecondProp = 'bkr_prop_money_unsorted_01',
        SecondPropBone = 4138,
        SecondPropPlacement = {0.0430, -0.0440, 0.0210, -69.3531027, -84.7638107, -14.0760953},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign422"] = {"fucksmokecup@from94", "fsc_clip", "Gang Sign 395 Pose Smoke Fuck", AnimationOptions =
    {
        Prop = 'prop_cs_ciggy_01',
        PropBone = 4169,
        PropPlacement = {0.0400, -0.0100, -0.0100, -18.747238, -7.0959699, -68.8271678},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign434"] = {"poohpose@dd", "poohpose_clip", "Gang Sign 397 Pooh Shiesty Pose", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 58869,
        PropPlacement = {0.1380, 0.0550, 0.0130, 12.8959689, -15.9443881, 8.8034293},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign442"] = {"cupandbottle@from94", "cupandbottle_clip", "Gang Sign 402 Cup & Bottle", AnimationOptions =
    {
        Prop = 'prop_beer_bottle',
        PropBone = 4090,
        PropPlacement = {0.0300, -0.0700, -0.2500, -168.8430382, 166.4708958, 48.0412793},
        SecondProp = 'prop_plastic_cup_02',
        SecondPropBone = 4090,
        SecondPropPlacement = {0.0400, -0.0230, 0.0950, -8.9958125, 27.0857648, 6.6471686 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign444"] = {"moneyspread@from94", "moneyspread_clip", "Gang Sign 403 Money Spread", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 4090,
        PropPlacement = {-0.1830, 0.0980, -0.2070, 54.8383608, -107.1371147, 8.85103 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign445"] = {"moneyspread2@from94", "moneyspread2_clip", "Gang Sign 404 Money Spread 2", AnimationOptions =
    {
        Prop = 'hei_prop_heist_cash_pile',
        PropBone = 26611,
        PropPlacement = {-0.0050, 0.1600, -0.1740, 41.4285761, -179.1342383, -29.3411091 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign447"] = {"drakopose@from94", "drakopose_clip", "Gang Sign 406 Drako Pose", AnimationOptions =
    {
        Prop = 'w_ar_assaultrifle_mag2',
        PropBone = 26611,
        PropPlacement = {-0.0280, -0.0380, -0.0060, -24.0000006, 0.0000, 0.0000},
        SecondProp = 'w_ar_assaultrifle',
        SecondPropBone = 26613,
        SecondPropPlacement = {-0.0250, -0.0730, -0.0900, 25.6621914, -45.7382796, 26.180082  },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign448"] = {"pose94@from94", "pose94_clip", "Gang Sign 407 From94 Pose", AnimationOptions =
    {
        Prop = 'bkr_prop_money_unsorted_01',
        PropBone = 4186,
        PropPlacement = {0.0100, -0.0600, 0.0100, -61.1245223, -74.4640596, 13.3562105 },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign449"] = {"backmoney@from94", "backmoney_clip", "Gang Sign 408 Back Pose Mone", AnimationOptions =
    {
        Prop = 'prop_anim_cash_note_b',
        PropBone = 64017,
        PropPlacement = {0.0310, -0.0010, 0.0410, 59.6237443, 45.9202947, -4.1967536  },
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign451"] = {"drinksmoke@from94", "drinksmoke_clip", "Gang Sign 410 Drink Smoke", AnimationOptions =
    {
        Prop = 'prop_beer_pissh',
        PropBone = 58870,
        PropPlacement = {0.0360, 0.0620, 0.0800, 8.9663098, -4.938748, -0.7812041},
        SecondProp = 'prop_cs_ciggy_01',
        SecondPropBone = 4170,
        SecondPropPlacement = {0.0200, -0.0200, 0.0100, -5.1608082, -100.364092, -29.5935632},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gsign452"] = {"houndkphone@from94", "houndkphone_clip", "Gang Sign 411 Hound K & Phone", AnimationOptions =
    {
        Prop = 'scrlt_iphone14max_02',
        PropBone = 26611,
        PropPlacement = {0.0400, -0.0450, -0.0020, 1.4205163, 23.9960445, 1.7269448},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["freposeg3"] = {"glap@free-poses-v10", "free-poses-v10_clip", "Pose V10", AnimationOptions =
    {
        Prop = "ch_prop_casino_stool_02a",
        PropBone = 1,
        PropPlacement = {0.0, 0.05, -0.99, 0.0, 0.0, 0.0},
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["freposeg4"] = {"glap@free-poses-v9", "free-poses-v9_clip", "Pose V9", AnimationOptions =
    {
        Prop = "ch_prop_casino_stool_02a",
        PropBone = 1,
        PropPlacement = {0.0, 0.05, -0.99, 0.0, 0.0, 0.0},
        SecondProp = 'prop_wine_glass',
        SecondPropBone = 1,
        SecondPropPlacement = {0.13, 0.33, 0.32, 0.0, 0.0, 0.0},
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["yorvoger"] = {"glap@free-poses-v5", "free-poses-v5_clip", "Yor Forger", AnimationOptions =
    {
        Prop = "w_me_knife_01",
        PropBone = 57005, -- Right
        PropPlacement = {0.090, 0.000, -0.020, -77.084, 0.000, -20.000},
        SecondProp = 'w_me_knife_01',
        SecondPropBone = 18905,-- Left
        SecondPropPlacement = {0.08, -0.02, 0.015, -90.0, 0.0, 0.0},
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["bangtrend"] = {
        "bangtrend@animation",
        "bangtrend_clip",
        "Bang TikTok Trend",
        AnimationOptions = {
            Prop = 'scrlt_iphone14max_03',
            PropBone = 60309,
            PropPlacement = {
                0.11,
                0.03,
                0.01,
                100.0,
                -4.0,
                108.0
            },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["unityscape"] = {
        "jarp_sign",
        "jarp_sign_clip",
        "Unityscape Promote Prop",
        AnimationOptions = {
            Prop = 'unityscape_logo', --- Custom prop by ultrahacx
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
    ["jarpfino"] = {
        "jarp_scooter_root",
        "jarp_scooter_root_clip",
        "Jarp Fino ~Prop",
        AnimationOptions = {
            Prop = 'jarp_scooter_prop', --- Custom prop by ultrahacx
            PropBone = 28422,
            PropPlacement = {
                0.0,
                0.0,
                0.03,
                0.0,
                0.0,
                0.0
            },
            EmoteLoop = true
        }},
    ["asutynew1"] = {
        "suty@pose",
        "suty_clip",
        "Standing Holding Lean & Cigar",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "prop_cigar_02",
            PropBone = 4154,
            PropPlacement = { -0.0400, -0.0300, 0.0900, 83.8384317, 97.3282027, 10.1808259 },
            SecondProp = "ng_proc_sodabot_01a",
            SecondPropBone = 6286,
            SecondPropPlacement = { 0.1000, -0.0900, -0.2200, -59.7712571, -66.6567642, -55.4559913 },
        }
    },
    ["asutynew2"] = {
        "suty@pose2",
        "suty_clip2",
        "Holding Draco & Glock",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "w_pi_combatpistol",
            PropBone = 36029,
            PropPlacement = { 0.12, 0.04, 0.04, -132.0000, -21.0000, 7.0000 },
            SecondProp = "w_ar_assaultrifle_smg",
            SecondPropBone = 6286,
            SecondPropPlacement = { 0.11, 0.03, 0.01, -79.0000, -11.0000, -1.0000 },
            ThirdProp = "w_ar_assaultrifle_smg_mag1",
            ThirdPropBone = 6286,
            ThirdPropPlacement = { 0.23, 0.08, 0.05, -78.0000, -10.0000, -6.0000 },
        }
    },
    ["asutynew3"] = {
        "suty@pose3",
        "suty_pose3clip",
        "Holding 2 Glocks",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "w_pi_combatpistol",
            PropBone = 6286,
            PropPlacement = { 0.12, 0.03, -0.03, -67.0000, 9.0000, -2.0000 },
            SecondProp = "w_pi_combatpistol_mag2",
            SecondPropBone = 6286,
            SecondPropPlacement = { 0.06, 0.05, -0.01, -65.0000, 6.0000, 4.0000 },
            ThirdProp = "w_pi_combatpistol",
            ThirdPropBone = 36029,
            ThirdPropPlacement = { 0.12, 0.02, 0.02, -110.0000, 1.0000, -6.0000 },
            FourthProp = "w_pi_combatpistol_mag2",
            FourthPropBone = 36029,
            FourthPropPlacement = { 0.07, 0.05, 0.01, -112.0000, 4.0000, -2.0000 },
        }
    },
    ["asutynew5"] = {
        "suty@pose4",
        "suty_pose4clip",
        "Holding Money",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'hei_prop_heist_cash_pile',
            PropBone = 0,
            PropPlacement = { 0.02, 0.28, 0.37, -13.0000, 14.0000, -8.0000 },
        }
    },
    ["asutynew7"] = {
        "suty@pose5",
        "suty_poseclip5",
        "Holding Gun 1",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "w_pi_combatpistol",
            PropBone = 36029,
            PropPlacement = { 0.10, 0.02, -0.03, -77.0000, 56.0000, 7.0000 },
            SecondProp = "w_pi_combatpistol_mag2",
            SecondPropBone = 36029,
            SecondPropPlacement = { 0.08, 0.05, 0.02, -75.0000, 55.0000, 2.0000 },
        }
    },
    ["asutynew8"] = {
        "suty@pose6",
        "suty_clip6",
        "Holding Gun 2",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "w_pi_combatpistol",
            PropBone = 36029,
            PropPlacement = { 0.11, 0.03, 0.02, -97.0000, 0.0000, 0.0000 },
        }
    },
    ["asutynew9"] = {
        "suty@pose7",
        "suty_clip7",
        "Holding Rifle",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "w_ar_carbineriflemk2",
            PropBone = 0,
            PropPlacement = { -0.03, 0.22, 0.17, 0.0000, -27.0000, 1.0000 },
            SecondProp = "w_ar_carbineriflemk2_mag1",
            SecondPropBone = 0,
            SecondPropPlacement = { 0.00, 0.22, 0.19, 0.0000, -25.0000, 0.0000 },
        }
    },
    ["asutynew10"] = {
        "suty@sitpose1",
        "suty_sitclip",
        "Seated With 2 Guns",
        AnimationOptions =
        {
            EmoteLoop = true,
            EmoteMoving = false,
            Prop = "w_pi_combatpistol",
            PropBone = 57005,
            PropPlacement = { 0.18, 0.03, -0.01, -59.0000, 9.0000, -13.0000 },
            SecondProp = "w_pi_combatpistol_mag2",
            SecondPropBone = 64081,
            SecondPropPlacement = { 0.00, -0.01, 0.10, -11.0000, -1.0000, -159.0000 },
            ThirdProp = "w_sb_compactsmg",
            ThirdPropBone = 46078,
            ThirdPropPlacement = { -0.16, 0.11, 0.02, -170.0000, 7.0000, -7.0000 },
            FourthProp = "w_sb_compactsmg_mag1",
            FourthPropBone = 46078,
            FourthPropPlacement = { -0.12, 0.11, -0.01, -172.0000, 7.0000, -7.0000 },
        }
    },
    ["asutynew11"] = {
        "suty@sitpose2",
        "suty_sitposeclip2",
        "Seated In Hoop",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'prop_bskball_01',
            PropBone = 6286,
            PropPlacement = { 0.04, -0.01, -0.11, -13.0000, -100.0000, -176.0000 },
        }
    },
    ["asutynew12"] = {
        "suty@sitpose3",
        "suty_sitposeclip3",
        "Seated Selfie",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'scrlt_iphone14max_07',
            PropBone = 36029,
            PropPlacement = { 0.12, 0.03, 0.01, -114.0000, -25.0000, -37.0000 },
        }
    },
    ["asutynew14"] = {
        "suty@sitpose4",
        "suty_sitposeclip4",
        "Seated Holding Money",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'hei_prop_heist_cash_pile',
            PropBone = 0,
            PropPlacement = { 0.10, 0.47, 0.14, 67.0000, 0.0000, -198.0000 },
        }
    },
    ["leancookiebag"] = {
        "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a",
        "idle_a",
        "Lean Cookie Bag",
        AnimationOptions =
        {
            Prop = 'bkr_prop_meth_bigbag_01a',
            PropBone = 0,
            PropPlacement = { 0.470, 0.000, -0.935, 0.612, 0.000, 176.950 },
            EmoteLoop = true,
            EmoteMoving = false,

        }
    },
    ["standingwithmoney"] = {
        "custom@gsign_26",
        "gsign_26",
        "Standing with Money",
        AnimationOptions =
        {
            Prop = "xs_prop_arena_cash_pile_m",
            PropBone = 28422,
            PropPlacement = { 0.070, 0.000, -0.015, 36.774, 0.000, 104.057 },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },

    ["supremepack"] = {
        "syx@cute05",
        "cute05",
        "Supreme Pack Pose",
        AnimationOptions =
        {
            Prop = "prop_suitcase_02",
            PropBone = 24806,
            PropPlacement = { -0.425, 0.000, 0.405, 0.000, 0.000, 0.000 },
            SecondProp = "prop_tool_nailgun",
            SecondPropBone = 36029,
            SecondPropPlacement = { 0.11, 0.01, 0.001, -120.0, 0.0, 0.0 },
            ThirdProp = "prop_boxing_glove_01",
            ThirdPropBone = 24806,
            ThirdPropPlacement = { -0.390, 0.095, 0.855, 0.000, 0.000, 0.000, },
            FourthProp = 'v_res_skateboard',
            FourthPropBone = 24806,
            FourthPropPlacement = { -0.780, 0.060, 0.585, -2.300, -70.800, 19.800 },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["zl1"] = {
        "missbigscore2aig_3",
        "wait_for_van_c",
        "ZL Prop Emote 1",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'prop_anim_cash_pile_02',
            PropBone = 18905,
            PropPlacement = { 0.0700, 0.0700, 0.0, 50.0, 100.0, 0.0 },
            SecondProp = 'ng_proc_sodabot_01a',
            SecondPropBone = 18905,
            SecondPropPlacement = { 0.40, -0.14, 0.0256, 690.0, 999.0, 10.0 },
            ThirdProp = 'p_amb_coffeecup_01',
            ThirdPropBone = 52301,
            ThirdPropPlacement = { 0.2, 0.04, -0.2, -110.0, 100.0, 0.0 },
        }
    },

    ["zl2"] = {
        "amb@world_human_stupor@male@idle_a",
        "idle_a",
        "ZL Prop Emote ",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'bkr_prop_bkr_cashpile_07',
            PropBone = 18905,
            PropPlacement = { -0.5, 0.00, 0.1, -162.0, 22.0, -60.0 },
            SecondProp = "w_pi_appistol",
            SecondPropBone = 57005,
            SecondPropPlacement = { 0.1750, 0.0381, -0.0083, -78.0000, 2.0000, -2.0200 },
            ThirdProp = 'p_amb_coffeecup_01',
            ThirdPropBone = 18905,
            ThirdPropPlacement = { 0.187, 0.41, -0.0050, -162.0, 22.0, -60.0 },
        }
    },
    ["zl3"] = {
        "timetable@ron@ig_3_couch",
        "base",
        "ZL Prop Emote 3",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'ex_prop_exec_cashpile',
            PropBone = 0,
            PropPlacement = { 0.0000, 0.0000, -0.4600, -5.0000, 0.0000, 0.0000 },
            SecondProp = "ex_prop_exec_cashpile",
            SecondPropBone = 0,
            SecondPropPlacement = { 0.0000, 0.0300, -0.2700, -6.0000, 0.0000, 0.0000 },
            ThirdProp = 'p_amb_coffeecup_01',
            ThirdPropBone = 0,
            ThirdPropPlacement = { -0.1100, 0.4900, -0.5700, -7.000, -1.0000, 0.0000 },
            FourthProp = 'ng_proc_sodabot_01a',
            FourthPropBone = 0,
            FourthPropPlacement = { 0.04, 0.3500, -0.6400, -7.000, -1.0000, 0.0000 },
            FifthProp = "w_pi_appistol",
            FifthPropBone = 57005,
            FifthPropPlacement = { 0.1750, 0.0381, -0.0083, -78.0000, 2.0000, -2.0200 },
        }
    },
    ["zl4"] = {
        "timetable@jimmy@mics3_ig_15@",
        "mics3_15_base_jimmy",
        "ZL Prop Emote 4",
        AnimationOptions =
        {
            EmoteMoving = false,
            EmoteLoop = true,
            Prop = 'ex_cash_pile_8',
            PropBone = 0,
            PropPlacement = { 0.0000, -0.4300, 0.2900, 235.0000, 180.0000, 0.0000 },
            SecondProp = "ex_cash_pile_07",
            SecondPropBone = 0,
            SecondPropPlacement = { 0.0000, 0.0000, -0.2400, -55.0000, 0.0000, 0.0000 },
            ThirdProp = "w_pi_appistol",
            ThirdPropBone = 57005,
            ThirdPropPlacement = { 0.1750, 0.0381, -0.0083, -78.0000, 2.0000, -2.0200 },
            FourthProp = "ng_proc_sodabot_01a",
            FourthPropBone = 18905,
            FourthPropPlacement = { 0.0800, -0.2100, 0.0300, -85.000, 30.000, -9.0000 },
            FifthProp = "w_ar_assaultrifle",
            FifthPropBone = 0,
            FifthPropPlacement = { -0.3500, 0.1900, -0.4000, 30.0000, -90.0000, -30.000 },
            SixthProp = "p_amb_coffeecup_01",
            SixthPropBone = 51826,
            SixthPropPlacement = { 0.2600, -0.0800, -0.2100, -119.0000, -10.0000, 0.0000 },
            SeventhProp = "prop_bottle_cognac",
            SeventhPropBone = 0,
            SeventhPropPlacement = { 0.4100, -0.1700, 0.0200, -55.0000, 1.0000, 0.0000 },
        }
    },
    ["zl5"] = {
        "mikey@gangsigns@new",
        "mgangsign_5",
        "ZL Prop Emote 5",
        AnimationOptions =
        {
            Prop = 'prop_cash_pile_01',
            PropBone = 18905, --lefthand
            PropPlacement = { 0.1299, 0.0050, 0.0279, -74.5674, 12 / 4571, 11.3780 },
            SecondProp = "w_pi_appistol",
            SecondPropBone = 57005,
            SecondPropPlacement = { 0.1750, 0.0381, -0.0083, -78.0000, 2.0000, -2.0200 },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["zl6"] = {
        "amb@world_human_tourist_map@male@base",
        "base",
        "ZL Prop Emote 6",
        AnimationOptions =
        {
            Prop = 'prop_tourist_map_01',
            PropBone = 28422,
            PropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            SecondProp = 'ng_proc_sodabot_01a',
            SecondPropBone = 18905,
            SecondPropPlacement = { 0.10, -0.19, 0.19, -130.0, 0.0, -10.0 },
            EmoteMoving = false,
            EmoteLoop = true
        }
    },
    ["zl7"] = {
        "combat@aim_variations@1h@gang",
        "aim_variation_a",
        "ZL Prop Emote 7",
        AnimationOptions =
        {
            Prop = 'ng_proc_sodabot_01a',
            PropBone = 18905,
            PropPlacement = { 0.08, -0.08, 0.29, -160.0, 0.0, -10.0 },
            SecondProp = 'w_pi_appistol',
            SecondPropBone = 57005, --righthand
            SecondPropPlacement = { 0.15, 0.021, -0.004, -70.0, -5.0, -21.0 },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["zl8"] = {
        "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a",
        "idle_a",
        "ZL Prop Emote 8",
        AnimationOptions =
        {
            Prop = "w_pi_appistol",
            PropBone = 57005,
            PropPlacement = { 0.1750, 0.0381, -0.0083, -78.0000, 2.0000, -2.0200 },
            SecondProp = 'p_amb_coffeecup_01',
            SecondPropBone = 63931,
            SecondPropPlacement = { 0.5421, 0.1414, 0.2841, 8.3638, -70.2173, -20.4633 },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["zl9"] = {
        "mikey@gangsigns@new",
        "mgangsign_11",
        "ZL Prop Emote 9",
        AnimationOptions =
        {
            Prop = "w_pi_appistol",
            PropBone = 57005,
            PropPlacement = { 0.1750, 0.0381, -0.0083, -78.0000, 2.0000, -2.0200 },
            SecondProp = "prop_whiskey_bottle",
            SecondPropBone = 35502,
            SecondPropPlacement = { 0.2000, -0.1100, -0.0100, -1.2000, -0.5100, 38.4900 },
            EmoteLoop = true,
            EmoteMoving = false,
        }
    },
    ["carryengine"] = {"anim@heists@box_carry@", "idle", "Carry Engine", AnimationOptions =
    {
        Prop = "prop_car_engine_01",
        PropBone = 60309,
        PropPlacement = {0.025, 0.08, 0.255, -65.0, 300.0, 0.0},
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["carryenginehoist"] = {"anim@heists@box_carry@", "idle", "Carry Engine Hoist", AnimationOptions =
    {
        Prop = "prop_engine_hoist",
        PropBone = 56604,
        PropPlacement = {0.1, 1.0, -0.75, 0.0, -0.5, 180.0},
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["carrybonnet"] = {"anim@heists@box_carry@", "idle", "Carry Bonnet", AnimationOptions =
    {
        Prop = "prop_car_bonnet_02",
        PropBone = 56604,
        PropPlacement = {0.0, 1.75, 0.45, -105.0, 0.0, 180.0},
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["carrytrunk"] = {"anim@heists@box_carry@", "idle", "Carry Trunk", AnimationOptions =
    {
        Prop = "imp_prop_impexp_trunk_01a",
        PropBone = 56604,
        PropPlacement = {0.0, 0.40, 0.1, 0.0, 0.0, 180.0},
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["carrydoor"] = {"anim@heists@box_carry@", "idle", "Carry Door", AnimationOptions =
    {
        Prop = "prop_car_door_01",
        PropBone = 56604,
        PropPlacement = {0.1, 0.40, -0.65, 0.0, 0.0, 180.0},
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["carrywheel"] = {"anim@heists@box_carry@", "idle", "Carry Wheel", AnimationOptions =
    {
        Prop = "prop_wheel_01",
        PropBone = 56604,
        PropPlacement = {-0.08, 0.30, 0.37, 0.0, 0.0, 180.0},
        EmoteLoop = true,
        EmoteMoving = true,
    }},
    ["gtono"] = {"glap@tono", "tono_clip", "Tono Start Animation", AnimationOptions =
    {
        Prop = "prop_microphone_02",
        PropBone = 18905,
        PropPlacement = {0.10, -0.07, 0.01, -80.0, 0.0, -20.0},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["gtonokra"] = {"glap@kradaoloum", "kradao_clip", "Tono Kradaoloum Animation", AnimationOptions =
    {
        Prop = "prop_microphone_02",
        PropBone = 18905,
        PropPlacement = {0.10, -0.07, 0.01, -80.0, 0.0, -20.0},
        EmoteLoop = true,
        EmoteMoving = false,
    }},
    ["coupleloversingle"] = {"glap@lover-couple-trend", "lover-couple-trend-single", "Lover Trend Single", AnimationOptions =
    {
        Prop = "scrlt_iphone14max_01",
        PropBone = 4170,
        PropPlacement = {-0.03, -0.05, 0.01, -79.64, 5.0, -78.84},
        EmoteLoop = true,
        EmoteMoving = false
    }},
    ["shakasitting"] = {"anim@shaka_sit", "shaka_clip", "Kicked Back Shaka (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Prop = "bkr_prop_clubhouse_chair_03",
        PropBone = 0,
        PropPlacement = {
            0.0000,
            0.0000,
            -0.5800,
            0,
            0,
            168.999
        },
    }},
    ["mselfie1"] = {"anim@male_insta_selfie", "insta_selfie_clip", "Male Selfie 1 (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Prop = "patoche_props_phone2",
        PropBone = 61163,
        PropPlacement = {
            0.3800,
            -0.0100,
            0.0500,
            119.2548,
            158.4273,
            17.4377
        },
    }},
    ["bskball1"] = {"anim@male_bskball_dunk", "bskball_dunk_clip", "Basketball Dunk (Smos)", AnimationOptions =
    {
        EmoteLoop = true,
        EmoteMoving = false,
        Prop = "prop_bskball_01",
        PropBone = 28252,
        PropPlacement = {
            0.3300,
            0.1700,
            -0.0400,
            0,
            0,
            0
        },
    }},
    ["ganggroup2"] = {"karxem@group", "group_2", "Gang Group 2", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Prop = 'xm3_prop_xm3_pistol_xm3',
        PropBone = 61163,
        PropPlacement = {
            0.3800,
            0.1000,
            0.1000,
            0,
            -114.0000,
            0
        },
    }},
    ["gangdppour"] = {"drillpack@karxem", "pour", "Gang Drill Pose Pour", AnimationOptions =
    {
        EmoteMoving = false,
        EmoteLoop = true,
        Prop = 'prop_wine_red',
        PropBone = 40269,
        PropPlacement = {
            0.5500,
            0.0600,
            0.1700,
            -6.3335,
            174.3160,
            29.6728
        },
    }},
    ["ganganimamoney"] = {"jx2moneyanims@animation", "jx2moneyanims_clip", "Gang Anim A Money", AnimationOptions =
    {
        EmoteMoving = false,
        Prop = "xs_prop_arena_cash_pile_m",
        PropBone = 28252,
        PropPlacement = {
            0.4500,
            -0.0200,
            -0.0200,
            26.9999,
            0,
            1
        },
    }},
    ["ganganima5"] = {"jxs5anims@animation", "jxs5anims_clip", "Gang Anim A5", AnimationOptions =
    {
        EmoteMoving = false,
        Prop = "ex_cash_pile_005",
        PropBone = 0,
        PropPlacement = {
            -0.1200,
            -0.3200,
            -0.3900,
            -11.0000,
            0,
            0
        },
        SecondProp = 'xs_prop_arena_cash_pile_s',
        SecondPropBone = 28252,
        SecondPropPlacement = {
            0.4100,
            0.0900,
            0.0300,
            50.3772,
            76.9061,
            -23.1558
        },
    }},
    ["ptrashcana"] = {
        "ptrashcana@animations",
        "ptrashcanaclip",
        "Trash Can Hide A Loop",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanb"] = {
        "ptrashcanb@animations",
        "ptrashcanbclip",
        "Trash Can Hide A Look & Peek",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.06,
                -0.1170,
                -0.090,
                -90,
                0,
                18.00,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanc"] = {
        "ptrashcanc@animations",
        "ptrashcancclip",
        "Trash Can Hide A Peek",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcand"] = {
        "ptrashcand@animations",
        "ptrashcandclip",
        "Trash Can Stuck Struggle",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                -0.02,
                -0.5900,
                0.030,
                -88.000,
                0,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcane"] = {
        "ptrashcane@animations",
        "ptrashcaneclip",
        "Trash Can Stuck Upside Down",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 39317,
            PropPlacement = {
                0,
                -0.100,
                0.0,
                -90.000,
                0,
                -20,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanf"] = {
        "ptrashcanf@animations",
        "ptrashcanfclip",
        "Trash Can Stuck Flip",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 18905,
            PropPlacement = {
                0.15,
                0.100,
                0.050,
                -9.400,
                -160.280,
                -3.40,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcang"] = {
        "ptrashcang@animations",
        "ptrashcangclip",
        "Trash Can Full Stuck Upside Down",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 18905,
            PropPlacement = {
                0.13,
                0.1100,
                0.050,
                -9.51,
                -162.25,
                -3.0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanh"] = {
        "ptrashcanh@animations",
        "ptrashcanhclip",
        "Trash Can Hide B Loop",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.100,
                0.725,
                0.000,
                180,
                0,
            },
            EmoteLoop = true

        }
    },
    ["ptrashcani"] = {
        "ptrashcani@animations",
        "ptrashcaniclip",
        "Trash Can Hide B Sneaky",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.100,
                0.80,
                0.000,
                180,
                0,
            },
            PlayerControl = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanj"] = {
        "ptrashcanj@animations",
        "ptrashcanjclip",
        "Trash Can Hide B Walk",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.005,
                0.125,
                0.780,
                0.000,
                180,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcank"] = {
        "ptrashcank@animations",
        "ptrashcankclip",
        "Trash Can Hide B Panic",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.005,
                0.125,
                0.780,
                0.000,
                180,
                0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanl"] = {
        "ptrashcanl@animations",
        "ptrashcanlclip",
        "Trash Can Hide B Run For Your Lifeee",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.580,
                0.1500,
                0,
                10.000,
                -90,
                0,
            },
            EmoteMoving = true,
            EmoteLoop = true

        }
    },
    ["ptrashcanm"] = {
        "ptrashcanm@animations",
        "ptrashcanmclip",
        "Trash Can Dance Happy 1",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.70,
                0.175,
                0,
                10.000,
                -90,
                0,
            },
            EmoteLoop = true

        }
    },
    ["ptrashcann"] = {
        "ptrashcann@animations",
        "ptrashcannclip",
        "Trash Can Dance Happy 2",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.70,
                0.175,
                0,
                10.000,
                -90,
                0,
            },
            EmoteLoop = true

        }
    },
    ["ptrashcano"] = {
        "ptrashcano@animations",
        "ptrashcanoclip",
        "Trash Can Dance Happy 3",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 24817,
            PropPlacement = {
                0.70,
                0.175,
                0,
                10.000,
                -90,
                0,
            },
            EmoteLoop = true

        }
    },
    ["ptrashcanp"] = {
        "ptrashcanp@animations",
        "ptrashcanpclip",
        "Trash Can Cool Lean",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanq"] = {
        "ptrashcanq@animations",
        "ptrashcanqclip",
        "Trash Can Jump Slow",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanr"] = {
        "ptrashcanr@animations",
        "ptrashcanrclip",
        "Trash Can Jump Fast",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcans"] = {
        "ptrashcans@animations",
        "ptrashcansclip",
        "Trash Can Jump Long",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.08,
                -0.0900,
                -0.10,
                -90,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcant"] = {
        "ptrashcant@animations",
        "ptrashcantclip",
        "Trash Can Turtle Stuck",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.4100,
                -0.340,
                -40,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanu"] = {
        "ptrashcanu@animations",
        "ptrashcanuclip",
        "Trash Can Turtle Enjoy",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.4100,
                -0.340,
                -40,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanv"] = {
        "ptrashcanv@animations",
        "ptrashcanvclip",
        "Trash Can Turtle Walk Struggle",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.470,
                -0.390,
                -40,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanw"] = {
        "ptrashcanw@animations",
        "ptrashcanwclip",
        "Trash Can Turtle Walk Normal",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.400,
                -0.440,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanx"] = {
        "ptrashcanx@animations",
        "ptrashcanxclip",
        "Trash Can Turtle Walk Panic",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.400,
                -0.440,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcany"] = {
        "ptrashcany@animations",
        "ptrashcanyclip",
        "Trash Can Hide C Look Around",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanz"] = {
        "ptrashcanz@animations",
        "ptrashcanzclip",
        "Trash Can Hide C Loop",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.03,
                -0.1300,
                0.02,
                -98,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanza"] = {
        "ptrashcanza@animations",
        "ptrashcanzaclip",
        "Trash Can Spin",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.03,
                -0.1300,
                0.02,
                -98,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzb"] = {
        "ptrashcanzb@animations",
        "ptrashcanzbclip",
        "Trash Can Spin Fast",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.03,
                -0.1300,
                0.02,
                -98,
                0,
                20.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzc"] = {
        "ptrashcanzc@animations",
        "ptrashcanzcclip",
        "Trash Can Roll Slow",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzd"] = {
        "ptrashcanzd@animations",
        "ptrashcanzdclip",
        "Trash Can Roll Fast",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanze"] = {
        "ptrashcanze@animations",
        "ptrashcanzeclip",
        "Trash Can Roll Out Of Control",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                -0.0600,
                -0.230,
                -35,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzf"] = {
        "ptrashcanzf@animations",
        "ptrashcanzfclip",
        "Trash Can Cool Sit 1",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.10,
                -0.150,
                164.9,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzg"] = {
        "ptrashcanzg@animations",
        "ptrashcanzgclip",
        "Trash Can Cool Sit 2",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 0,
            PropPlacement = {
                0.0,
                0.10,
                -0.150,
                169.9,
                0,
                0.000,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzh"] = {
        "ptrashcanzh@animations",
        "ptrashcanzhclip",
        "Trash Can Impossible Pose 1",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.120,
                -0.980,
                00,
                -90,
                0,
                -20.000,
            },
            SecondProp = 'prop_recyclebin_03_a',
            SecondPropBone = 64097,
            SecondPropPlacement = {
                0.20,
                -0.20,
                0.000,
                -38.255,
                74.42,
                12.700,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzi"] = {
        "ptrashcanzi@animations",
        "ptrashcanziclip",
        "Trash Can Impossible Pose 2",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 14201,
            PropPlacement = {
                0.10,
                -0.050,
                0.0,
                90,
                0,
                20,
            },
            SecondProp = 'prop_recyclebin_03_a',
            SecondPropBone = 31086,
            SecondPropPlacement = {
                0.140,
                0.10,
                0.000,
                -90,
                0,
                -40,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzj"] = {
        "ptrashcanzj@animations",
        "ptrashcanzjclip",
        "Trash Can Impossible Pose 3",
        AnimationOptions = {
            Prop = "prop_recyclebin_03_a",
            PropBone = 52301,
            PropPlacement = {
                0.110,
                -0.050,
                -0.150,
                90,
                0,
                20.000,
            },
            SecondProp = 'prop_recyclebin_03_a',
            SecondPropBone = 24817,
            SecondPropPlacement = {
                0.09,
                -0.10,
                0.000,
                90,
                0,
                5.0,
            },
            EmoteLoop = true
        }
    },
    ["ptrashcanzk"] = {
        "ptrashcanzk@animations",
        "ptrashcanzkclip",
        "Trash Can Carry 1",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 57005,
            PropPlacement = {
                0.090,
                -0.640,
                -0.37,
                -85.076,
                -0.867,
                -0.037,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanzl"] = {
        "ptrashcanzl@animations",
        "ptrashcanzlclip",
        "Trash Can Carry 2",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 57005,
            PropPlacement = {
                -0.17,
                -0.370,
                -0.370,
                -79.372,
                3.616,
                -19.683,
            },
            SecondProp = 'prop_bin_07d',
            SecondPropBone = 18905,
            SecondPropPlacement = {
                -0.15,
                -0.34,
                0.370,
                -100.62,
                -3.616,
                -19.683,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanzm"] = {
        "ptrashcanzm@animations",
        "ptrashcanzmclip",
        "Trash Can Carry Overhead",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 57005,
            PropPlacement = {
                -0.090,
                0.060,
                -0.31,
                0,
                79.999,
                0,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["ptrashcanzn"] = {
        "ptrashcanzn@animations",
        "ptrashcanznclip",
        "Trash Can I Can't See",
        AnimationOptions = {
            Prop = "prop_bin_07d",
            PropBone = 24818,
            PropPlacement = {
                1.04,
                0.10,
                0.0,
                0,
                -90,
                -10,
            },
            EmoteMoving = true,
            EmoteLoop = true
        }
    },
    ["trophyrun"] = {"ptrophyrun@animations", "ptrophyrunclip", "Hold Trophy Run", AnimationOptions =
    {
        Prop = "xs_prop_trophy_cup_01a",
        PropBone = 57005,
        PropPlacement = {0.010, -0.080, -0.1, -43.583, 54.555, 15.5168},
        EmoteLoop = true,
        EmoteMoving = true
    }},
    ["trophy"] = {"ptrophy@animations", "ptrophyclip", "Hold Trophy", AnimationOptions =
    {
        Prop = "xs_prop_trophy_cup_01a",
        PropBone = 57005,
        PropPlacement = {0.010, -0.080, -0.1, -43.583, 54.555, 15.5168},
        EmoteLoop = true,
    }}
}

-----------------------------------------------------------------------------------------
-- | I don't think you should change the code below unless you know what you are doing |--
-----------------------------------------------------------------------------------------

-- Add the custom emotes to RPEmotes main array
for arrayName, array in pairs(CustomDP) do
    if RP[arrayName] then
        for emoteName, emoteData in pairs(array) do
            RP[arrayName][emoteName] = emoteData
        end
    end

    -- Free memory
    CustomDP[arrayName] = nil
end

-- Free memory
CustomDP = nil
