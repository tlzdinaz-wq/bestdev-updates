---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Factions = {
    ["crew"] = {
        Hierarchies = {
            "Indépendant",
            "Gang de rue",
            "Club de motards",
            "Organisation criminelle",
            "Mafia",
        },
        menuColor = 'rgba(209,156,5,0.3)',
        Colors = {
            "#A439A2",
            "#198D31",
            "#10561F",
            "#186E94",
            "#091B51",
            "#722E21",
            "#452019",
            "#DF6F21",
            "#44C9E5",
            "#FFFFFF",
            "#A9D4AE",
            "#ECCA32",
            "#AA1E1E",
            "#151515",
            "#149690",
            "#BA7F22",
            "#6399E0",
            "#B34141",
            "#12583A",
            "#717171",
            "#C5C5C5",
            "#32A933",
            "#A9C5A9",
            "#C22525",
            "#3DA0D0",
            "#9A9A9A",
            "#ECBAE8",
            "#000000",
            "#3198AE",
            "#10407A",
            "#EBBB52",
            "#D7D7D7",
            "#FFFFFF",
        },
        TypesFromHierarchy = {
            ["Indépendant"] = "normal",
            ["Gang de rue"] = "gang",
            ["Club de motards"] = "mc",
            ["Organisation criminelle"] = "orga",
            ["Mafia"] = "mafia"
        },
        Types = {
            normal = {
                label = "Indépendant",
                hierarchy = 1
            },
            gang = {
                label = "Gang de rue",
                hierarchy = 2
            },
            mc = {
                label = "Club de motards",
                hierarchy = 3
            },
            orga = {
                label = "Organisation criminelle",
                hierarchy = 4
            },
            mafia = {
                label = "Mafia",
                hierarchy = 5
            }
        }
    },
    ["company"] = {
        menuColor = 'linear-gradient(to top, rgba(224, 31, 31, .4), rgba(255, 0, 0, 0.2))',
        Hierarchies = {
            "Bar",
            "Restaurant",
            "Garage",
            "Club de nuit",
            "Épicerie",
        },
        Colors = {
            "#198D31",
            "#10561F",
            "#186E94",
            "#091B51",
            "#722E21",
            "#452019",
            "#DF6F21",
            "#44C9E5",
            "#FFFFFF",
            "#A9D4AE",
            "#ECCA32",
            "#AA1E1E",
            "#151515",
            "#149690",
            "#BA7F22",
            "#6399E0",
            "#B34141",
            "#12583A",
            "#717171",
            "#C5C5C5",
            "#32A933",
            "#A9C5A9",
            "#C22525",
            "#3DA0D0",
            "#9A9A9A",
            "#ECBAE8",
            "#000000",
            "#3198AE",
            "#10407A",
            "#EBBB52",
            "#D7D7D7",
            "#FFFFFF",
        },
        Types = {
            bar = {
                label = "Bar",
                hierarchy = 1
            },
            resto = {
                label = "Restaurant",
                hierarchy = 2
            },
            garage = {
                label = "Garage",
                hierarchy = 3
            },
            club = {
                label = "Club de nuit",
                hierarchy = 4
            },
            epicerie = {
                label = "Épicerie",
                hierarchy = 5
            }
        }
    },
    ["faction"] = {
        menuColor =
        'linear-gradient(to top, rgba(94, 108, 182, 0.5) 0%, rgba(94, 108, 182, 0.31) 33%, rgba(94, 108, 182, 0.31) 100%)',
        Hierarchies = {
            "Police",
            "Médecin",
            "Pompier",
            "Fédéral",
            "Militaire",
        },
        Colors = {
            "#198D31",
            "#10561F",
            "#186E94",
            "#091B51",
            "#722E21",
            "#452019",
            "#DF6F21",
            "#44C9E5",
            "#FFFFFF",
            "#A9D4AE",
            "#ECCA32",
            "#AA1E1E",
            "#151515",
            "#149690",
            "#BA7F22",
            "#6399E0",
            "#B34141",
            "#12583A",
            "#717171",
            "#C5C5C5",
            "#32A933",
            "#A9C5A9",
            "#C22525",
            "#3DA0D0",
            "#9A9A9A",
            "#ECBAE8",
            "#000000",
            "#3198AE",
            "#10407A",
            "#EBBB52",
            "#D7D7D7",
            "#FFFFFF",
        },
        Grades = {
            { grade = 0, name = "cadet",      label = "Cadet" },
            { grade = 1, name = "rookie",     label = "Rookie" },
            { grade = 2, name = "officier",   label = "Officier" },
            { grade = 3, name = "sergent",    label = "Sergent" },
            { grade = 4, name = "lieutenant", label = "Lieutenant" },
            { grade = 5, name = "capitaine",  label = "Capitaine" }
        },
        Types = {
            police = {
                label = "Police",
                hierarchy = 1
            },
            medecin = {
                label = "Médecin",
                hierarchy = 2
            },
            pompier = {
                label = "Pompier",
                hierarchy = 3
            },
            federal = {
                label = "Fédéral",
                hierarchy = 4
            },
            militaire = {
                label = "Militaire",
                hierarchy = 5
            }
        }
    },

    Placement = {
        "Blaine County",
        "Los Santos",
        "Cayo Perico",
    },
    CrewCreationCam = {
        ['crew'] = {
            CamCoords = {
                x = 1117.7567138671876,
                y = -3196.823974609375,
                z = -39.8289909362793
            },
            CamRot = {
                x = -1.91581499576568,
                y = -5.336084996088175e-8,
                z = -69.80274963378906
            },
            Dof = true,
            COH = {
                x = 1119.00927734375,
                y = -3196.4560546875,
                z = -40.39839935302734,
                w = 107.89002990722656
            },
            Animation = {
                dict = "94glockymakk@animation",
                anim = "makkballa_clip"
            },
            DofStrength = 1.0,
            Freeze = true,
            Fov = 31.0
        },
        ['company'] = {
            CamCoords = {
                x = -68.97504425048828,
                y = -805.3873291015625,
                z = 243.92337036132813
            },
            CamRot = {
                x = -0.58160853385925,
                y = 1.3340214266577277e-8,
                z = 67.77142333984375
            },
            Dof = true,
            COH = {
                x = -69.6558609008789,
                y = -805.0010375976563,
                z = 243.40077209472657,
                w = 236.03646850585938
            },
            Animation = {
                dict = "anim@amb@casino@hangout@ped_male@stand@02b@idles",
                anim = "idle_a"
            },
            DofStrength = 0.9,
            Freeze = true,
            Fov = 51.0
        },
        ['faction'] = {
            CamCoords = {
                x = 1156.62109375,
                y = -3197.052978515625,
                z = -38.51105117797851
            },
            CamRot = {
                x = -2.85999488830566,
                y = 2.6680424980440877e-8,
                z = -85.39962005615235
            },
            Dof = true,
            COH = {
                x = 1157.85400390625,
                y = -3197.056640625,
                z = -39.00798034667969,
                w = 87.26671600341797
            },
            Animation = {
                dict = "anim@mp_corona_idles@male_c@idle_a",
                anim = "idle_a"
            },
            DofStrength = 1.0,
            Freeze = true,
            Fov = 41.0
        }
    },
    CrewPlayerGestionCam = {
        ["gang"] = {
            CamCoords = {
                x = 1034.2872314453126,
                y = -3206.282470703125,
                z = -37.65494155883789
            },
            CamRot = {
                x = -0.31828781962394,
                y = 0.0,
                z = -86.00285339355469
            },
            Dof = true,
            COH = {
                x = 1035.7740478515626,
                y = -3206.201904296875,
                z = -38.17393493652344,
                w = 72.52796173095703
            },
            Animation = {
                dict = "grapes@sign2",
                anim = "grapes"
            },
            DofStrength = 1.0,
            Freeze = true,
            Fov = 31.0
        },
        ["mc"] = {
            CamCoords = {
                x = 1104.585693359375,
                y = -3159.079345703125,
                z = -37.0238151550293
            },
            CamRot = {
                x = -4.4126009941101,
                y = 3.201650997652905e-7,
                z = -26.46825408935547
            },
            Dof = true,
            COH = {
                x = 1105.33251953125,
                y = -3157.891845703125,
                z = -37.51856994628906,
                w = 150.31964111328126
            },
            Animation = {
                dict = "anim@amb@nightclub@peds@",
                anim = "rcmme_amanda1_stand_loop_cop"
            },
            DofStrength = 0.9,
            Freeze = false,
            Fov = 40.1
        },
        ["mafia"] = {
            CamCoords = {
                x = 1121.7113037109376,
                y = -3196.6728515625,
                z = -39.9363784790039
            },
            CamRot = {
                x = -4.10858249664306,
                y = -0.0,
                z = -55.29290771484375
            },
            Dof = true,
            COH = {
                x = 1123.006103515625,
                y = -3195.923583984375,
                z = -40.40032577514648,
                w = 119.48811340332031
            },
            Animation = {
                dict = "hoodie_hands@dad",
                anim = "hoodie_hands_clip"
            },
            DofStrength = 0.9,
            Freeze = false,
            Fov = 40.1
        },
        ["orga"] = {
            CamCoords = {
                x = 516.7645263671875,
                y = -2619.726806640625,
                z = -48.47815322875976
            },
            CamRot = {
                x = -4.59502935409545,
                y = -5.3360842855454396e-8,
                z = 6.97366046905517
            },
            Dof = true,
            COH = {
                x = 516.7144165039063,
                y = -2618.314453125,
                z = -48.99990844726562,
                w = 180.0
            },
            Animation = {
                dict = "bzzz@animation@army2",
                anim = "bz_army2"
            },
            DofStrength = 0.9,
            Freeze = false,
            Fov = 40.1,
        },
    },
    CrewPedsGestionCam = {
        ["gang"] = {
            {
                CamCoords = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                CamRot = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                Dof = false,
                COH = {
                    x = 1036.3067626953126,
                    y = -3205.6630859375,
                    z = -38.17291641235351,
                    w = 98.98674774169922
                },
                Animation = {
                    dict = "anim@amb@casino@hangout@ped_male@stand@02b@idles",
                    anim = "idle_a"
                },
                DofStrength = 0.0,
                Freeze = false,
                Fov = 45.0
            },
            {
                CamCoords = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                CamRot = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                Dof = false,
                COH = {
                    x = 1036.4075927734376,
                    y = -3206.6591796875,
                    z = -38.17236709594726,
                    w = 96.34954071044922
                },
                Animation = {
                    dict = "byrd@sign6",
                    anim = "sign"
                },
                DofStrength = 0.0,
                Freeze = false,
                Fov = 45.0
            }
        },
        ["mc"] = {
            {
                CamCoords = {
                    x = 1104.16259765625,
                    y = -3159.47021484375,
                    z = -36.2558708190918
                },
                CamRot = {
                    x = -12.77590274810791,
                    y = -0.0,
                    z = -54.65699005126953
                },
                Dof = true,
                COH = {
                    x = 1105.9752197265626,
                    y = -3157.6943359375,
                    z = -37.51857757568359,
                    w = 138.0083465576172
                },
                Animation = {
                    dict = "anim@mp_corona_idles@male_d@idle_a",
                    anim = "idle_a"
                },
                DofStrength = 0.9,
                Freeze = false,
                Fov = 40.1,
            },
            {
                CamCoords = {
                    x = 1105.55517578125,
                    y = -3153.8994140625,
                    z = -35.96773910522461
                },
                CamRot = {
                    x = -18.79449653625488,
                    y = -0.0,
                    z = 167.30813598632813
                },
                Dof = true,
                COH = {
                    x = 1105.2523193359376,
                    y = -3157.06494140625,
                    z = -37.51863861083984,
                    w = 154.91261291503907
                },
                Animation = {
                    dict = "anim@miss@low@fin@vagos@",
                    anim = "idle_ped06"
                },
                DofStrength = 0.9,
                Freeze = false,
                Fov = 30.1,
            }
        },
        ["mafia"] = {
            {
                CamCoords = {
                    x = 1123.6820068359376,
                    y = -3196.19677734375,
                    z = -40.39934921264648
                },
                CamRot = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                Dof = false,
                COH = {
                    x = 1123.6820068359376,
                    y = -3196.19677734375,
                    z = -40.39934921264648,
                    w = 118.86349487304688
                },
                Animation = {
                    dict = "94glockymovin@animation",
                    anim = "movin_clip"
                },
                DofStrength = 0.0,
                Freeze = false,
                Fov = 1.1
            },
            {
                CamCoords = {
                    x = 1120.44189453125,
                    y = -3197.5771484375,
                    z = -39.74517440795898
                },
                CamRot = {
                    x = 0.46186834573745,
                    y = -0.0,
                    z = -57.72587966918945
                },
                Dof = true,
                COH = {
                    x = 1123.30712890625,
                    y = -3195.29443359375,
                    z = -40.40265274047851,
                    w = 132.34991455078126
                },
                Animation = {
                    dict = "rcmnigel1cnmt_1c",
                    anim = "base"
                },
                DofStrength = 0.9,
                Freeze = false,
                Fov = 40.1
            }
        },
        ["orga"] = {
            {
                CamCoords = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                CamRot = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                Dof = false,
                COH = {
                    x = 517.0970458984375,
                    y = -2617.633056640625,
                    z = -48.99990844726562,
                    w = 170.800048828125
                },
                Animation = {
                    dict = "anim@amb@casino@hangout@ped_male@stand@02b@idles",
                    anim = "idle_a"
                },
                DofStrength = 0.0,
                Freeze = false,
                Fov = 45.0
            },
            {
                CamCoords = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                CamRot = {
                    x = 0.0,
                    y = 0.0,
                    z = 0.0
                },
                Dof = false,
                COH = {
                    x = 516.1759643554688,
                    y = -2617.5087890625,
                    z = -48.99990844726562,
                    w = 200.64930725097657
                },
                Animation = {
                    dict = "missclothing",
                    anim = "idle_storeclerk"
                },
                DofStrength = 0.0,
                Freeze = false,
                Fov = 45.0
            }
        },
    },
    RandomPeds = {
        `g_m_importexport_01`,
        `g_m_y_armgoon_02`,
        `g_m_y_korean_02`,
        `g_m_y_salvaboss_01`,
        `g_f_y_vagos_01`,
    },
    ---@class Cache
    Cache = {},
    ---@class Peds
    Peds = {}
}

---Create Ped
---@param hash any
---@param x any
---@param y any
---@param z any
---@param h any
---@return number|table|boolean Created object or success status
local function createPed(hash, x, y, z, h)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(0)
        end
    end

    local ped = CreatePed(4, hash, x, y, z, heading)
    SetModelAsNoLongerNeeded(hash)
    return ped
end

---Delete VFW.Factions.Cams
---@param name string
function VFW.Factions.DeleteCams(name)
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    VFW.Cam:Destroy(name)
    DeleteEntity(VFW.Factions.Ped)
    if VFW.Factions.Peds and next(VFW.Factions.Peds) then
        for i = 1, #VFW.Factions.Peds do
            DeleteEntity(VFW.Factions.Peds[i])
        end
    end

    ClearFocus()
    DoScreenFadeIn(1000)
end

---Create VFW.Factions.Camera
---@param factionTable any
---@param multipleTable any
---@param data table
---@return any
function VFW.Factions.CreateCamera(factionTable, multipleTable, data)
    local ped
    local clonePlayer1, tattooPlayer1, clonePlayer2, tattooPlayer2 = TriggerServerCallback("core:faction:getClonePed",
        VFW.PlayerData.faction.name)

    if (not data) then
        VFW.Factions.Ped = ClonePed(VFW.PlayerData.ped, false, false)
        VFW.Cam:Create("crewCreation", factionTable, VFW.Factions.Ped)
        ped = VFW.Factions.Ped
    elseif data and data.ped == "random" then
        math.randomseed(GetGameTimer())
        local randomizedPed = VFW.Factions.RandomPeds[math.random(1, #VFW.Factions.RandomPeds)]
        VFW.Factions.Peds[#VFW.Factions.Peds + 1] = createPed(randomizedPed, factionTable.COH.x, factionTable.COH.y,
            factionTable.COH.z, factionTable.COH.w)
        SetModelAsNoLongerNeeded(randomizedPed)
        VFW.Cam:UpdateAnim(nil, factionTable.Animation, VFW.Factions.Peds[#VFW.Factions.Peds])
        ped = VFW.Factions.Peds[#VFW.Factions.Peds]
    elseif data and data.ped == "player1" then
        if clonePlayer1 then
            VFW.Factions.Peds[#VFW.Factions.Peds + 1] = VFW.CreatePlayerClone(clonePlayer1, tattooPlayer1,
                vector3(factionTable.COH.x, factionTable.COH.y, factionTable.COH.z), factionTable.COH.w)
            VFW.Cam:UpdateAnim(nil, factionTable.Animation, VFW.Factions.Peds[#VFW.Factions.Peds])
            ped = VFW.Factions.Peds[#VFW.Factions.Peds]
        else
            return VFW.Factions.CreateCamera(factionTable, multipleTable, { ped = "random" })
        end
    elseif data and data.ped == "player2" then
        if clonePlayer2 then
            VFW.Factions.Peds[#VFW.Factions.Peds + 1] = VFW.CreatePlayerClone(clonePlayer2, tattooPlayer2,
                vector3(factionTable.COH.x, factionTable.COH.y, factionTable.COH.z), factionTable.COH.w)
            VFW.Cam:UpdateAnim(nil, factionTable.Animation, VFW.Factions.Peds[#VFW.Factions.Peds])
            ped = VFW.Factions.Peds[#VFW.Factions.Peds]
        else
            return VFW.Factions.CreateCamera(factionTable, multipleTable, { ped = "random" })
        end
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityVisible(ped, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetFocusPosAndVel(factionTable.COH.x, factionTable.COH.y, factionTable.COH.z - 1.0)
    SetEntityCoords(ped, factionTable.COH.x, factionTable.COH.y, factionTable.COH.z)
    Wait(100)
    SetEntityVisible(ped, true, false)
    SetEntityHeading(ped, factionTable.COH.w)
    SetEntityCoords(ped, factionTable.COH.x, factionTable.COH.y, factionTable.COH.z - 1.0)

    if not clonePlayer1 then
        if multipleTable then
            for i = 1, #multipleTable do
                VFW.Factions.CreateCamera(multipleTable[i], nil, { ped = "random" })
            end
        end
    else
        if multipleTable then
            for i = 1, #multipleTable do
                if i == 1 then
                    VFW.Factions.CreateCamera(multipleTable[i], nil, { ped = "player1" })
                else
                    if clonePlayer2 then
                        VFW.Factions.CreateCamera(multipleTable[i], nil, { ped = "player2" })
                    else
                        VFW.Factions.CreateCamera(multipleTable[i], nil, { ped = "random" })
                    end
                end
            end
        end
    end

    DoScreenFadeIn(1000)
end

--- .Factions.OpenCreation
---@param type any
function VFW.Factions.OpenCreation(type)
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    VFW.Nui.FactionCreation(true, {
        type = type
    })
    VFW.Factions.CreateCamera(VFW.Factions.CrewCreationCam[type])
end

local ORGANIZATION_TYPE = {
    ["crew"] = 1,
    ["faction"] = 2,
    ["company"] = 3
}

RegisterNUICallback("nui:activity-creation:submit", function(data)
    console.debug("nui:activity-creation:submit")
    console.debug(json.encode(data))
    if (not data.type == "crew") then
        return
    end

    local name = data.name
    local hierarchie = VFW.Factions[data.type].Hierarchies[VFW.Factions[data.type].Types[data.activity].hierarchy]
    local crewBdd = data.activity
    local devise = data.motto
    local placement = data.place
    if name and hierarchie and devise and placement then
        TriggerServerEvent("core:factions:askCreationCrew", name, hierarchie, crewBdd, devise, placement)
        VFW.Nui.FactionCreation(false)
        VFW.Factions.DeleteCams("crewCreation")
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Il manque des informations pour créer votre crew."
        })
    end
end)

RegisterNUICallback("nui:activity-creation:close", function()
    VFW.Nui.FactionCreation(false)
    VFW.Factions.DeleteCams("crewCreation")
end)

-- RegisterCommand("createCrew", function()
--     local hasPermission = TriggerServerCallback('core:factions:canCreateCrew')

--     if not hasPermission then
--         VFW.ShowNotification({
--             type = 'ROUGE',
--             content = 'La création de gangs est actuellement désactivée.'
--         })
--         return
--     end

--     VFW.Factions.OpenCreation('crew')
-- end)
