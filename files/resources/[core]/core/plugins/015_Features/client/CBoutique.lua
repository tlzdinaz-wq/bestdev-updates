function string:split(sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)

    for match in self:gmatch(pattern) do
        table.insert(result, match)
    end

    return result
end

--- showText
---@param args table Arguments
local function showText(args)
    args.shadow = args.shadow or true
    args.font = args.font or 6
    args.size = args.size or 0.50
    args.posx = args.posx or 0.5
    args.posy = args.posy or 0.4
    args.msg = args.msg or ""

    SetTextFont(args.font)
    SetTextProportional(0)

    SetTextScale(args.size, args.size)
    if args.shadow == true then
        SetTextDropShadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
    end

    SetTextEntry("STRING")
    AddTextComponentString(args.msg)
    DrawText(args.posx, args.posy)
end

--- formatTime
---@param timeMs any
---@return any
local function formatTime(timeMs)
    local totalSeconds = math.floor(timeMs / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

--- DrawSpecialText
---@param title any
---@param barPosition vector3|table Position
---@param addLeft any
local function DrawSpecialText(title, barPosition, addLeft)
    if not addLeft then
        addLeft = 0
    end

    RequestStreamedTextureDict("timerbars")
    if not HasStreamedTextureDictLoaded("timerbars") then
        return
    end

    local x = 1.0 - (1.0 - GetSafeZoneSize()) * 0.5 - 0.180 / 2
    local y = 1.0 - (1.0 - GetSafeZoneSize()) * 0.5 - 0.045 / 2 - (barPosition - 1) * (0.045 + 0)

    DrawSprite("timerbars", "all_black_bg", x, y, 0.180, 0.045, 0.0, 255, 255, 255, 160)

    showText({ msg = title, font = 0, size = 0.36, posx = 0.840, posy = y / 1.014, shadow = false })
end

---Set reWeaponCam
---@return table
local function resetWeaponCam()
    return {
        Fov = 30.1,
        CamCoords = { x = 15.59020614624023, y = -1111.080810546875, z = 30.62255096435547 },
        Freeze = false,
        Dof = true,
        Vehicle = -1842748181,
        COH = { x = 8.58437442779541, y = -1108.829833984375, z = 29.7972183227539, w = 48.11109924316406 },
        Invisible = true,
        CamRot = { x = -0.69101148843765, y = -0.0, z = -20.52164840698242 },
        DofStrength = 1.0,
    }
end

---Create CBoutique
---@return number|table|boolean Created object or success status
local function CreateCBoutique()
    local self = {}

    self.currentCamType = nil
    self.currentPerf = 0
    self.isPreviewLoading = false
    self.camWeaponInstanceCreated = false
    self.camWeapon = resetWeaponCam()
    self.entityPackPreview = {}
    self.camPackInstanceCreated = false
    self.initCoins = false
    self.packCam = {
        ["food"] = {
            Fov = 50.1,
            CamCoords = {
                ["x"] = 1185.0650634765625,
                ["y"] = -3251.33935546875,
                ["z"] = -49.65160369873047
            },
            Freeze = false,
            Dof = true,
            COH = {
                ["x"] = 1193.4500732421875,
                ["y"] = -3253.961669921875,
                ["z"] = -48.99774932861328,
                ["w"] = 77.62293243408203
            },
            Invisible = true,
            CamRot = {
                ["x"] = 0.8390040397644,
                ["y"] = -0.0,
                ["z"] = 103.7992172241211
            },
            DofStrength = 1.0,
            props = {
                {
                    model = "prop_ld_flow_bottle",
                    hash = 746336278,
                    coords = vector4(1183.25, -3252.42, -49.87, 88.93)
                },
                {
                    model = "prop_ld_flow_bottle",
                    hash = 746336278,
                    coords = vector4(1183.15, -3252.3, -49.87, 69.37)
                },
                {
                    model = "v_ret_247_bread1",
                    hash = 1485704474,
                    coords = vector4(1183.34, -3252.07, -49.92, 94.64)
                },
                {
                    model = "v_ret_247_bread1",
                    hash = 1485704474,
                    coords = vector4(1183.04, -3251.92, -49.92, 134.05)
                },
                {
                    model = "xm_prop_x17_bag_med_01a",
                    hash = -502202673,
                    coords = vector4(1183.29, -3251.42, -49.99, 128.94)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(1182.73, -3251.39, -49.99, 91.61)
                }
            },
            perso = false
        },
        ["Starter Pack"] = {
            Fov = 50.1,
            CamCoords = {
                ["x"] = 1185.0650634765625,
                ["y"] = -3251.33935546875,
                ["z"] = -49.65160369873047
            },
            Freeze = false,
            Dof = true,
            COH = {
                ["x"] = 1193.4500732421875,
                ["y"] = -3253.961669921875,
                ["z"] = -48.99774932861328,
                ["w"] = 77.62293243408203
            },
            vehicle = {
                {
                    model = "faggio",
                    coh = vector4(1182.478515625, -3251.9833984375, -49.52280807495117, 228.489013671875),
                }
            },
            Invisible = true,
            CamRot = {
                ["x"] = 0.8390040397644,
                ["y"] = -0.0,
                ["z"] = 103.7992172241211
            },
            DofStrength = 1.0,
            props = {
                {
                    model = "prop_ld_flow_bottle",
                    hash = 746336278,
                    coords = vector4(1183.25, -3252.42, -49.87, 88.93)
                },
                {
                    model = "prop_ld_flow_bottle",
                    hash = 746336278,
                    coords = vector4(1183.15, -3252.3, -49.87, 69.37)
                },
                {
                    model = "v_ret_247_bread1",
                    hash = 1485704474,
                    coords = vector4(1183.34, -3252.07, -49.92, 94.64)
                },
                {
                    model = "v_ret_247_bread1",
                    hash = 1485704474,
                    coords = vector4(1183.04, -3251.92, -49.92, 134.05)
                },
                {
                    model = "xm_prop_x17_bag_med_01a",
                    hash = -502202673,
                    coords = vector4(1183.29, -3251.42, -49.99, 128.94)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(1182.73, -3251.39, -49.99, 91.61)
                }
            },
            perso = false
        },
        ["illegal"] = {
            props = {
                {
                    model = "ex_prop_crate_ammo_sc",
                    hash = 2055492359,
                    coords = vector4(568.81, -408.38, -70.52, 180.58)
                },
                {
                    model = "xm3_prop_xm3_drug_stack_01a",
                    hash = 1529019361,
                    coords = vector4(565.51, -406.0, -70.65, 114.16)
                },
                {
                    model = "bkr_prop_weed_table_01b",
                    hash = 304964818,
                    coords = vector4(565.32, -406.62, -70.65, 138.4)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(565.2, -406.36, -69.8, 124.81)
                },
                {
                    model = "bkr_prop_weed_lrg_01b",
                    hash = 716763602,
                    coords = vector4(565.32, -406.62, -70.65, 138.4)
                }
            },
            CamRot = {
                ["x"] = -4.27397966384887,
                ["y"] = 1.067216999217635E-7,
                ["z"] = 156.14892578125
            },
            Dof = true,
            Fov = 60.1,
            Animation = {
                dict = "94glockymakk@animation",
                anim = "makkballa_clip"
            },
            Freeze = false,
            COH = {
                ["x"] = 568.5604858398438,
                ["y"] = -403.9638671875,
                ["z"] = -69.64707946777344,
                ["w"] = 339.00372314453125
            },
            DofStrength = 0.9,
            CamCoords = {
                ["x"] = 568.965576171875,
                ["y"] = -403.2243957519531,
                ["z"] = -69.10992431640625
            },
            perso = {
                weapon = "weapon_battleaxe"
            }
        },
        ["Premium Pack"] = {
            props = {
                {
                    model = "gr_prop_gr_bench_04b",
                    hash = 765424411,
                    coords = vector4(1179.53, -3256.67, -50.0, 117.32)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(1183.98, -3254.18, -49.99, 123.97)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(1183.84, -3253.27, -49.99, 131.47)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(1183.94, -3252.07, -49.99, 84.47)
                },
                {
                    model = "v_ind_cs_toolbox4",
                    hash = -738161850,
                    coords = vector4(1183.49, -3252.6, -49.83, 161.42)
                },
                {
                    model = "v_ind_cs_toolbox4",
                    hash = -738161850,
                    coords = vector4(1183.88, -3251.26, -49.83, 200.97)
                }
            },
            CamRot = {
                ["x"] = -2.16955280303955,
                ["y"] = -0.0,
                ["z"] = 118.70527648925781
            },
            CamCoords = {
                ["x"] = 1185.6983642578125,
                ["y"] = -3250.9091796875,
                ["z"] = -49.11160278320312
            },
            Dof = true,
            DofStrength = 0.9,
            Fov = 60.1,
            Freeze = false,
            COH = {
                ["x"] = 1195.6463623046875,
                ["y"] = -3251.04736328125,
                ["z"] = -48.99770736694336,
                ["w"] = 269.8842468261719
            },
            perso = false,
            vehicle = {
                {
                    model = "gblod4",
                    coh = vector4(1181.2220458984376, -3250.646484375, -49.23396682739258, 242.07977294921876)
                },
                {
                    model = "gbargento7f",
                    coh = vector4(1181.1385498046876, -3254.139892578125, -49.28732681274414, 284.9878845214844)
                }
            }
        },
        ["Farm"] = {
            Fov = 60.1,
            COH = { x = 1002.06103515625, y = -3152.705322265625, z = -38.90743637084961, w = 185.97085571289063 },
            DofStrength = 0.9,
            Dof = true,
            Freeze = false,
            Invisible = true,
            CamRot = { x = -1.32262122631073, y = 6.670106245110219e-9, z = 177.29635620117188 },
            CamCoords = { x = 1003.352294921875, y = -3158.475830078125, z = -39.05907440185547 },
            perso = false,
            props = {
                {
                    model = "prop_vend_soda_02",
                    hash = 1114264700,
                    coords = vector4(1005.27, -3162.58, -38.96, 207.13)
                },
                {
                    model = "v_ind_cs_toolbox4",
                    hash = -738161850,
                    coords = vector4(1004.0, -3160.52, -39.74, 209.84)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(1002.61, -3160.65, -39.9, 206.45)
                },
                {
                    model = "prop_burgerstand_01",
                    hash = 1129053052,
                    coords = vector4(1000.58, -3161.74, -39.91, 170.75)
                }
            },
            vehicle = {
                {
                    model = "imperial",
                    coh = vector4(1002.4771728515625, -3163.51416015625, -39.13710784912109, 328.49945068359377)
                }
            }
        },
        ["sport"] = {
            CamRot = { x = -1.59739601612091, y = -0.0, z = -79.4830322265625 },
            CamCoords = { x = 726.5206909179688, y = -2991.762939453125, z = -39.27159118652344 },
            Freeze = false,
            Dof = true,
            DofStrength = 0.9,
            COH = { x = 719.1404418945313, y = -2992.344482421875, z = -38.9998664855957, w = 276.4543762207031 },
            Fov = 50.1,
            vehicle = {
                {
                    model = "tailgater2",
                    coh = vector4(732.0445556640625, -2992.89013671875, -39.63713836669922, 67.27214050292969),
                },
                {
                    model = "gbargento7f",
                    coh = vector4(731.9281616210938, -2990.2490234375, -39.28944396972656, 74.38739013671875),
                },
            },
            props = {
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(729.09, -2990.84, -39.99, 316.7)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(728.89, -2991.84, -39.99, 250.69)
                }
            }
        },
        ["sedans"] = {
            CamRot = { x = -0.85679560899734, y = -2.6680424980440877e-8, z = 15.95766162872314 },
            CamCoords = { x = 991.779541015625, y = -3011.176513671875, z = -39.90138626098633 },
            Freeze = false,
            Dof = true,
            DofStrength = 0.9,
            COH = { x = 982.7623901367188, y = -3016.44677734375, z = -39.64694213867187, w = 45.24867248535156 },
            Fov = 50.1,
            vehicle = {
                {
                    model = "primo2",
                    coh = vector4(986.1761474609375, -3016.9921875, -40.01278686523437, 226.06605529785156),
                },
                {
                    model = "scharmann",
                    coh = vector4(986.0597534179688, -3014.35107421875, -39.66509246826172, 233.18130493164062),
                },
            },
            props = {
                {
                    model = "sf_prop_car_jack_01a",
                    hash = -168951421,
                    coords = vector4(993.12, -3006.61, -40.66, 276.74)
                },
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(992.15, -3008.59, -40.64, 1.62)
                },
                {
                    model = "v_ind_cs_jerrycan01",
                    hash = -288941741,
                    coords = vector4(990.71, -3008.49, -40.41, 32.86)
                }
            }
        },
        ["suv"] = {
            CamRot = { x = -2.70870184898376, y = -0.0, z = -67.68095397949219 },
            CamCoords = { x = -1072.3123779296876, y = -75.87254333496094, z = -94.58956146240235 },
            Freeze = false,
            Dof = true,
            DofStrength = 0.9,
            COH = { x = -1079.1617431640626, y = -78.67507934570313, z = -94.59972381591797, w = 302.2745056152344 },
            Fov = 50.1,
            vehicle = {
                {
                    model = "astron",
                    coh = vector4(-1067.4232177734376, -75.60696411132813, -95.21334075927735, 79.08980560302735),
                },
                {
                    model = "gresleyh",
                    coh = vector4(-1066.882568359375, -73.2091064453125, -94.69022369384766, 81.7056884765625),
                },
            },
            props = {
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = -197122485,
                    coords = vector4(-1069.0, -74.54, -95.59, 320.59)
                },
                {
                    model = "xm_prop_x17_bag_01d",
                    hash = 618291518,
                    coords = vector4(-1069.01, -75.86, -95.59, 73.94)
                },
                {
                    model = "sf_prop_car_jack_01a",
                    hash = -168951421,
                    coords = vector4(-1067.51, -76.97, -95.62, 268.19)
                }
            }
        },
        ["utilitaires"] = {
            CamRot = { x = -1.20916974544525, y = 2.6680428533154555e-8, z = -72.16767883300781 },
            CamCoords = { x = 1222.3375244140626, y = -2281.0400390625, z = -48.89433288574219 },
            Freeze = false,
            Dof = true,
            DofStrength = 0.7,
            COH = { x = 1210.75732421875, y = -2279.697021484375, z = -48.99983215332031, w = 198.43214416503907 },
            Fov = 70.1,
            vehicle = {
                {
                    model = "gbesperta",
                    coh = vector4(1227.691650390625, -2278.602294921875, -48.8346061706543, 63.30389022827148),
                },
                {
                    model = "gburrito2",
                    coh = vector4(1227.2835693359376, -2281.463623046875, -49.18980026245117, 61.17158889770508),
                },
            },
            props = {
                {
                    model = "v_ind_cf_chckbox1",
                    hash = 1959542339,
                    coords = vector4(1224.8, -2279.23, -50.0, 290.0)
                },
                {
                    model = "v_ind_meatboxsml_02",
                    hash = 2142821084,
                    coords = vector4(1224.14, -2281.09, -50.0, 293.3)
                },
                {
                    model = "prop_rub_boxpile_04",
                    hash = -1712220001,
                    coords = vector4(1226.56, -2283.25, -49.88, 353.8)
                }
            }
        },
        ["moto"] = {
            Invisible = true,
            CamRot = {
                x = -1.73490738868713,
                y = -5.336084996088175E-8,
                z = 21.63160514831543
            },
            CamCoords = { x = 1102.6290283203125,
                          y = -3150.043701171875,
                          z = -37.86220932006836
            },
            Freeze = false,
            Dof = true,
            DofStrength = 0.9,
            COH = {
                x = 1104.482666015625,
                y = -3154.475341796875,
                z = -37.51857757568359,
                w = 20.9243221282959
            },
            Fov = 60.1,
            vehicle = {
                {
                    model = "gargoyle",
                    coh = vector4(1102.3248291015626, -3146.798095703125, -38.04351425170898, 159.71939086914063),
                },
                {
                    model = "templar",
                    coh = vector4(1100.9248046875, -3146.908447265625, -38.04974365234375, 156.3654022216797),
                }
            },
            props = {
                {
                    model = "bkr_prop_bkr_cashpile_04",
                    hash = 746336278,
                    coords = vector4(1101.27, -3148.1, -38.51, 35.19)
                },
                {
                    model = "v_ind_cs_toolbox4",
                    hash = 746336278,
                    coords = vector4(1103.07, -3147.15, -38.35, 14.37)
                },
                {
                    model = "prop_toolchest_05",
                    hash = 1485704474,
                    coords = vector4(1102.55, -3144.84, -38.52, 19.38)
                },
                {
                    model = "ch_chint03_tool_box_01a",
                    hash = 1485704474,
                    coords = vector4(1099.21, -3143.7, -37.41, 314.84)
                },
            }
        }
    }

    self.boutiqueShop = {
        ["vehicules"] = {
            COH = { x = -1335.26025390625, y = 151.4392852783203, z = -99.54377746582031, w = 44.23064422607422 },
            Vehicle = 1980574343,
            Dof = true,
            CamCoords = { x = -1340.7919921875, y = 154.05433654785157, z = -99.48793029785156 },
            Freeze = false,
            Fov = 40.1,
            CamRot = { x = -1.21643042564392, y = -2.6680428533154555e-8, z = -110.23473358154297 },
            DofStrength = 0.9,
            Invisible = true
        },
        ["nautic"] = {
            Vehicle = 231083307,
            Fov = 40.1,
            Freeze = false,
            COH = {
                x = -952.1898193359375,
                y = -1359.2880859375,
                z = 0.08281177282333,
                w = 109.16173553466797
            },
            CamRot = {
                x = 0.44395446777343,
                y = -0.0,
                z = -47.36090087890625
            },
            CamCoords = {
                x = -959.217529296875,
                y = -1364.0142822265626,
                z = 0.66475808620452
            },
            Dof = true,
            DofStrength = 0.7,
            Invisible = true
        },
        ["air"] = {
            Invisible = true,
            COH = {
                x = -1266.588623046875,
                y = -3011.117919921875,
                z = -47.3206672668457,
                w = 170.31231689453126
            },
            Freeze = false,
            Dof = true,
            Vehicle = 165154707,
            Fov = 60.1,
            CamCoords = {
                x = -1264.7135009765626,
                y = -3028.3818359375,
                z = -47.55343627929687
            },
            DofStrength = 0.6,
            CamRot = {
                x = 0.89464956521987,
                y = -0.0,
                z = 16.93718338012695
            }
        }
    }
    self.tryPos = {
        ["vehicules"] = vector4(-2690.18, 8282.38, 40.48, 177.46),
        ["nautic"] = vector4(-713.15710449219, -1341.4193115234, -1.284569144249, 139.61473083496),
        ["air"] = vector4(-1382.1882324219, -2289.2595214844, 13.587691307068, 150.27235412598)
    }
    self.camCreated = false
    self.currentVehiclePreview = nil
    self.posBeforeTry = vector3(0, 0, 0)
    self.lastModelWeapon = nil
    self.weaponsShop = {}
    self.appliedWeaponComponent = {}
    self.appliedWeaponTint = nil
    self.clonePed = nil
    self.currentVehiclePack = {}

    local PREVIEW_CONFIG = {
        DISTANCE_FROM_CAM = 0.8,
        VERTICAL_OFFSET = 0.0,
        ROTATION_OFFSET = 90.0,
        DYNAMIC_DISTANCE_FACTOR = 1.5,
        ASSET_TIMEOUT = 50,
        WAIT_TIME = 100,
        CENTERING = {
            ENABLE_AUTO_CENTER = true,
            HORIZONTAL_OFFSET = 0.0,
            DEPTH_OFFSET = 0.0
        }
    }

    local weaponHashCache = {}

--- calculateCenteredWeaponPosition
---@param camCoords vector3|table Coordinates
---@param camRot any
---@param distance any
---@return any
    local function calculateCenteredWeaponPosition(camCoords, camRot, distance)
        local rotX = math.rad(camRot.x)
        local rotZ = math.rad(camRot.z)
        local forwardX = -math.sin(rotZ) * math.cos(rotX)
        local forwardY = math.cos(rotZ) * math.cos(rotX)
        local forwardZ = math.sin(rotX)
        local rightX = math.cos(rotZ)
        local rightY = math.sin(rotZ)
        local basePos = vector3(
                camCoords.x + (forwardX * distance),
                camCoords.y + (forwardY * distance),
                camCoords.z + (forwardZ * distance)
        )
        local centeredPos = vector3(
                basePos.x + (rightX * PREVIEW_CONFIG.CENTERING.HORIZONTAL_OFFSET),
                basePos.y + (rightY * PREVIEW_CONFIG.CENTERING.HORIZONTAL_OFFSET),
                basePos.z + PREVIEW_CONFIG.VERTICAL_OFFSET
        )

        return centeredPos, { x = forwardX, y = forwardY, z = forwardZ }
    end

---Set loadWeaponAs
---@param weaponHash string Weapon name
---@param weaponName string
    local function loadWeaponAsset(weaponHash, weaponName)
        if not weaponHashCache[weaponName] then
            RequestWeaponAsset(weaponHash, 31, 0)

            local timeout = 0

            while not HasWeaponAssetLoaded(weaponHash) and timeout < PREVIEW_CONFIG.ASSET_TIMEOUT do
                Wait(PREVIEW_CONFIG.WAIT_TIME)
                timeout = timeout + 1
            end

            if not HasWeaponAssetLoaded(weaponHash) then
                console.debug("Erreur: Impossible de charger le modèle:", weaponName)
                return false
            end

            weaponHashCache[weaponName] = true
        end

        return true
    end

--- configureWeaponEntity
---@param weaponObj string Weapon name
---@param weaponPos string Weapon name
---@param camRot any
---@return any
    local function configureWeaponEntity(weaponObj, weaponPos, camRot)
        SetEntityCollision(weaponObj, false, false)
        FreezeEntityPosition(weaponObj, true)
        SetEntityInvincible(weaponObj, true)
        SetEntityVisible(weaponObj, true, false)
        SetEntityAlpha(weaponObj, 255, false)

        local min, max = GetModelDimensions(GetEntityModel(weaponObj))
        local centerOffset = vector3(
                -(min.x + max.x) / 2,
                -(min.y + max.y) / 2,
                -(min.z + max.z) / 2
        )
        local optimalHeading = camRot.z + 180.0

        SetEntityHeading(weaponObj, optimalHeading)

        local finalPos = vector3(
                weaponPos.x + centerOffset.x,
                weaponPos.y + centerOffset.y,
                weaponPos.z + centerOffset.z
        )

        SetEntityCoords(weaponObj, finalPos.x, finalPos.y, finalPos.z)
        SetEntityRotation(weaponObj, 0.0, 0.0, optimalHeading, 2, false)

        return centerOffset
    end

--- adjustCameraForWeapon
---@param self any
---@param weaponObj string Weapon name
---@param weaponPos string Weapon name
---@param forwardVector any
    local function adjustCameraForWeapon(self, weaponObj, weaponPos, forwardVector)
        local min, max = GetModelDimensions(GetEntityModel(weaponObj))
        local sizeX, sizeY, sizeZ = max.x - min.x, max.y - min.y, max.z - min.z

        console.debug(("Dimensions de l'arme: x=%.2f, y=%.2f, z=%.2f"):format(sizeX, sizeY, sizeZ))

        local maxSize = math.max(sizeX, sizeY, sizeZ)
        local dynamicDistance = math.max(maxSize * PREVIEW_CONFIG.DYNAMIC_DISTANCE_FACTOR, 1.0)

        local optimalCamPos = vector3(
                weaponPos.x - (forwardVector.x * dynamicDistance),
                weaponPos.y - (forwardVector.y * dynamicDistance),
                weaponPos.z - (forwardVector.z * dynamicDistance)
        )

        self.camWeapon.CamCoords = {
            x = optimalCamPos.x,
            y = optimalCamPos.y,
            z = optimalCamPos.z
        }

        VFW.Cam:Update("weaponshopcam", self.camWeapon)

        console.debug(("Caméra ajustée: distance=%.2f, pos=(%.2f, %.2f, %.2f)"):format(
                dynamicDistance, optimalCamPos.x, optimalCamPos.y, optimalCamPos.z
        ))
    end

--- .previewWeapon
---@param weaponName string
---@param cam any
---@return boolean
    function self.previewWeapon(weaponName, cam)
        cam = resetWeaponCam()

        if not weaponName or weaponName == "" then
            console.debug("Erreur: Nom de l'arme invalide")
            return false
        end

        if not cam or not cam.CamCoords or not cam.CamRot then
            console.debug("Erreur: Données de caméra invalides")
            return false
        end

        if self.lastModelWeapon == weaponName then
            console.debug("Aucune modification de l'arme, pas besoin de recréer.")
            return true
        end

        if self.weaponObject and DoesEntityExist(self.weaponObject) then
            DeleteEntity(self.weaponObject)
            self.weaponObject = nil
        end

        local weaponHash = joaat(weaponName)
        if weaponHash == 0 then
            console.debug("Erreur: Hash de l'arme invalide pour:", weaponName)
            return false
        end

        if not loadWeaponAsset(weaponHash, weaponName) then
            return false
        end

        local camCoords = vector3(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z)
        local camRot = vector3(cam.CamRot.x, cam.CamRot.y, cam.CamRot.z)
        local weaponPos, forwardVector = calculateCenteredWeaponPosition(
                camCoords,
                camRot,
                PREVIEW_CONFIG.DISTANCE_FROM_CAM
        )

        local weaponObj = CreateWeaponObject(weaponHash, 0, weaponPos.x, weaponPos.y, weaponPos.z, true, 0.15, 0)
        if not DoesEntityExist(weaponObj) then
            console.debug("Erreur: Échec de la création de l'objet arme")
            return false
        end

        local centerOffset = configureWeaponEntity(weaponObj, weaponPos, camRot)
        local finalWeaponPos = vector3(
                weaponPos.x + centerOffset.x,
                weaponPos.y + centerOffset.y,
                weaponPos.z + centerOffset.z
        )

        adjustCameraForWeapon(self, weaponObj, finalWeaponPos, forwardVector)

        self.weaponObject = weaponObj
        self.lastModelWeapon = weaponName

        console.debug(string.format("Arme créée et centrée avec succès à: %.3f, %.3f, %.3f", finalWeaponPos.x, finalWeaponPos.y, finalWeaponPos.z))
        return true
    end

--- .clearWeaponCache
    function self.clearWeaponCache()
---@class weaponHashCache
        weaponHashCache = {}
        console.debug("Cache des armes nettoyé")
    end

---Get self.WeaponComponentsByName
---@param weaponName string
    function self.getWeaponComponentsByName(weaponName)
        local components = {}

        for k, v in ipairs(Config.Weapons) do
            if v.name == weaponName:upper() then
                for i, component in ipairs(v.components or {}) do
                    if component.name ~= "clip_default" and component.name ~= "luxary_finish" and component.name ~= "clip_drum" then
                        table.insert(components, component)
                    end
                end
            end
        end

        return components
    end

---Get self.WeaponStatsByName
---@param weaponName string
---@return table
    function self.getWeaponStatsByName(weaponName)
        local weaponHash = joaat(weaponName)
        local damage = GetWeaponDamage(weaponHash, 0)
        local timeBetweenShots = GetWeaponTimeBetweenShots(weaponHash)
        local fireRate = (1.0 / timeBetweenShots)
        local recoil = GetWeaponRecoilShakeAmplitude(weaponHash)

        return {
            damage = math.round(damage),
            fireRate = math.round(fireRate),
            recoil = math.round(recoil)
        }
    end

---Register self.Events
    function self.registerEvents()
---Get CoordsInFront
---@param coords vector3|table Coordinates
---@param rot any
---@param distance any
---@return vector3|table
        function GetCoordsInFront(coords, rot, distance)
            local rad = math.rad(rot.z)
            local x = coords.x + distance * math.cos(rad)
            local y = coords.y + distance * math.sin(rad)
            local z = coords.z
            return vector3(x, y, z)
        end

        RegisterNuiCallback("boutique:updateweaponrot", function(data, cb)
            local lastEntity = self.weaponObject

            if not DoesEntityExist(lastEntity) then
                return
            end

            SetEntityHeading(lastEntity, GetEntityHeading(lastEntity) + (0.5 * data.x))
        end)

---Load RequestWaitAndModel
---@param model any
---@return any
        function RequestWaitAndLoadModel(model)
            if not IsModelValid(model) then
                console.debug("^1[ERROR]^0 Invalid model hash: " .. model)
                return
            end

            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end
        end

        RegisterNuiCallback("boutique:pack:buy", function(data, cb)
            local packName = data.packName
            local colors = data.colors
            local buying = TriggerServerCallback("boutique:trybuypack", packName, colors)

            if buying.success then
                VFW.CloseEscapeMenu()
                self.DeleteCam()
            end

            cb({
                success = buying.success,
                message = buying.message,
                balance = buying.balance or 0
            })
        end)

        RegisterNuiCallback("nui:escapeMenu:select:components", function(data, cb)
            local components = data.components

            if not self.weaponObject or not DoesEntityExist(self.weaponObject) then
                console.debug("^1[ERROR]^0 weaponObject is nil or does not exist")
                if cb then
                    cb({ status = "error", message = "weaponObject invalid" })
                end

                return
            end

            for _, v in ipairs(self.appliedWeaponComponent or {}) do
                console.debug("Removing component", v.hash)
                RemoveWeaponComponentFromWeaponObject(self.weaponObject, v.hash)
            end

            self.appliedWeaponComponent = {}

            for _, newComponent in ipairs(components) do
                local hash = joaat(newComponent.hash)
                local componentModel = GetWeaponComponentTypeModel(hash)

                RequestWaitAndLoadModel(componentModel)

                table.insert(self.appliedWeaponComponent, { hash = hash, name = newComponent.hash })

                console.debug("new component", json.encode(newComponent))

                GiveWeaponComponentToWeaponObject(self.weaponObject, hash)
                SetModelAsNoLongerNeeded(componentModel)
            end

            local statsModified = {
                damage = 0,
                fireRate = 0,
                recoil = 0
            }

            for k, v in pairs(self.appliedWeaponComponent) do
                statsModified.damage = statsModified.damage + GetWeaponComponentDamageModifier(v.hash)
            end

            cb(statsModified)
        end)

        RegisterNuiCallback("nui:escapeMenu:get:weapons", function(data, cb)

            Wait(250)

            local cam = self.camWeapon
            local weaponsShop = TriggerServerCallback("boutique:get:weapons")

            self.weaponsShop = {}

            -- Toutes les factions ont accès aux armes de type "inde" et "gang"
            for _, v in pairs(weaponsShop) do
                if v.type == "inde" or v.type == "gang" then
                    table.insert(self.weaponsShop, v)
                end
            end

            if not cam then
                console.debug("Erreur: camWeapon n'est pas défini")
                return
            end

            VFW.Cam:Create("weaponshopcam", cam)

            self.camWeaponInstanceCreated = true

            if not cam.CamCoords then
                console.debug("Erreur: CamCoords n'est pas défini dans cam")
                return
            end

            SetFocusArea(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z, 0.0, 0.0, 0.0)
            PinInteriorInMemory(GetInteriorAtCoords(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z))

            TriggerScreenblurFadeOut(0)

            for k, v in ipairs(self.weaponsShop) do
                v.components = self.getWeaponComponentsByName(v.weaponName)
                v.stats = self.getWeaponStatsByName(v.weaponName)
            end

            cb(self.weaponsShop)

            local myVcoins = TriggerServerCallback("boutique:getMyVcoins")

            SendNUIMessage({
                action = "nui:boutique:sendCoins",
                data = myVcoins and myVcoins.vcoins or 0
            })
        end)

---Get WeaponByName
---@param weaponName string
---@return string
        function getWeaponByName(weaponName)
            for _, weapon in ipairs(self.weaponsShop) do
                if weapon.weaponName:upper() == weaponName:upper() then
                    return weapon
                end
            end

            return nil
        end

        RegisterNuiCallback("nui:escapeMenu:select:weapon", function(data, cb)
            console.debug("Preview weapon:", data.weaponName:upper())

            self.previewWeapon(data.weaponName:upper(), self.camWeapon)

            cb(getWeaponByName(data.weaponName))
        end)

        RegisterNuiCallback("nui:aaaaa:close", function(data, cb)
            self.DeleteCam()
        end)

        RegisterNuiCallback("boutiqueVehSelect", function(data, cb)
            self.previewVehicle(data.name, data.colors, data.performance, data.type)
        end)

        RegisterNuiCallback("boutiqueVehTry", function(data, cb)
            local playerPed = PlayerPedId()
            local model = joaat(data.name)

            TriggerServerCallback("boutique:try:vehicle")

            VFW.ShowNotification({
                type = "VERT",
                content = "Vous avez 2 minutes pour essayer le véhicule.",
            })

            self.posBeforeTry = GetEntityCoords(playerPed)

            if self.currentVehiclePreview ~= nil then
                DeleteEntity(self.currentVehiclePreview)
                self.currentVehiclePreview = nil
            end

            local color = { r = tonumber(data.color.r), g = tonumber(data.color.g), b = tonumber(data.color.b) }

            VFW.CloseEscapeMenu()

            self.DeleteCam()

            VFW.Streaming.RequestModel(model)

            local posTry = self.tryPos[data.type]

            console.debug("Spawned vehicle at position:", posTry)

            local vehicle = CreateVehicle(model, posTry, false, true)

            console.debug("Vehicle created:", vehicle)

            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

            SetVehicleCustomPrimaryColour(vehicle, color.r, color.g, color.b)

            local duration = 2 * 60 * 1000
            local timeRemaining = duration
            local start = GetGameTimer()
            local ped = playerPed

            VFW.ShowNotification({
                type = "VERT",
                content = "Appuyer sur E a tout moment pour quitter l'essai.",
            })

            CreateThread(function()
                while timeRemaining > 0 do
                    DrawSpecialText("Temps restant: " .. formatTime(timeRemaining), 2)

                    if VFW.Interact.JustPressed(0, 38) then
                        VFW.ShowNotification({
                            type = "JAUNE",
                            content = "Vous avez quitté l'essai du véhicule.",
                        })

                        timeRemaining = 0

                        break
                    end

                    Wait(0)

                    timeRemaining = duration - (GetGameTimer() - start)
                end

                if vehicle and DoesEntityExist(vehicle) then
                    DeleteEntity(vehicle)
                end

                if self.currentVehiclePreview ~= nil then
                    DeleteEntity(self.currentVehiclePreview)
                    self.currentVehiclePreview = nil
                end

                SetEntityCoords(ped, self.posBeforeTry.x, self.posBeforeTry.y, self.posBeforeTry.z)

                Wait(3000)

                TriggerServerCallback("boutique:stop:vehicle")
            end)
        end)

        RegisterNuiCallback("boutique:plate", function(data, cb)
            local plate = data.plate

            if self.currentVehiclePreview ~= nil and data.plate ~= "" and plate ~= "PREVIEW" then
                SetVehicleNumberPlateText(self.currentVehiclePreview, plate)
            end

            cb({ success = true })
        end)

        RegisterNuiCallback("boutiqueVehColor", function(data, cb)
            local r, g, b = tonumber(data.r), tonumber(data.g), tonumber(data.b)

            SetVehicleCustomPrimaryColour(self.currentVehiclePreview, r, g, b)
        end)

        RegisterNuiCallback("boutique:UpdateVehiculeRot", function(data, cb)
            local lastEntity = self.currentVehiclePreview

            if not DoesEntityExist(lastEntity) then
                return
            end

            SetEntityHeading(lastEntity, GetEntityHeading(lastEntity) + (0.5 * data.x))
        end)

        RegisterNuiCallback("boutique:pack:get", function(data, cb)
            local packs = TriggerServerCallback("boutique:pack:get")

            cb(packs)
        end)

        RegisterNuiCallback("boutiqueVehPerf", function(data, cb)
            SetVehicleMod(self.currentVehiclePreview, 11, tonumber(data) > 3 and 3 or tonumber(data), false)
            SetVehicleMod(self.currentVehiclePreview, 12, tonumber(data) > 2 and 2 or tonumber(data), false)
            SetVehicleMod(self.currentVehiclePreview, 13, tonumber(data) > 2 and 2 or tonumber(data), false)

            self.currentPerf = tonumber(data)

            if tonumber(data) == 5 then
                SetVehicleMod(self.currentVehiclePreview, 18, tonumber(data) > 2 and 2 or tonumber(data), false)
            end
        end)

        RegisterNuiCallback("boutique:trybuyweapon", function(data, cb)
            local weaponName = data.weaponName
            local components = self.appliedWeaponComponent
            local weaponTint = self.appliedWeaponTint or 0

            local buying = TriggerServerCallback("boutique:trybuyweapon", weaponName, components, weaponTint)

            if buying.success then
                VFW.CloseEscapeMenu()
                self.DeleteCam()
            end

            cb({
                success = buying.success,
                message = buying.message,
                balance = buying.balance or 0
            })
        end)

        RegisterNuiCallback("boutique:pack:preview", function(data, cb)
            if not self.initCoins then
                local myVcoins = TriggerServerCallback("boutique:getMyVcoins")

                SendNUIMessage({
                    action = "nui:boutique:sendCoins",
                    data = myVcoins and myVcoins.vcoins or 0
                })
                self.initCoins = true
            end

            console.debug("data ", data.packName)

            local cam = self.packCam[data.packName]

            if cam then

                Wait(250)

                if VFW.Cam:Get("campackshop") then
                    VFW.Cam:Destroy("campackshop")
                end

                VFW.Cam:Create("campackshop", cam)

                self.camPackInstanceCreated = true

                SetFocusArea(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z, 0.0, 0.0, 0.0)
                PinInteriorInMemory(GetInteriorAtCoords(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z))
                TriggerScreenblurFadeOut(0)

                if self.entityPackPreview then
                    for _, entity in ipairs(self.entityPackPreview) do
                        if DoesEntityExist(entity) then
                            DeleteEntity(entity)
                        end
                    end
                end

                self.entityPackPreview = {}

                if cam.props then
                    for _, prop in ipairs(cam.props) do
                        VFW.Streaming.RequestModel(prop.model)

                        local obj = CreateObject(
                                joaat(prop.model),
                                prop.coords.x,
                                prop.coords.y,
                                prop.coords.z,
                                false, -- networked
                                false  -- dynamic
                        )

                        table.insert(self.entityPackPreview, obj)
                        SetModelAsNoLongerNeeded(joaat(prop.model))
                    end
                end

                if self.clonePed then
                    if DoesEntityExist(self.clonePed) then
                        DeleteEntity(self.clonePed)
                    end

                    self.clonePed = nil
                end

                if cam.perso then
                    self.clonePed = ClonePed(VFW.PlayerData.ped, false, false)
                    SetEntityAsMissionEntity(self.clonePed, true, true)
                    SetEntityVisible(self.clonePed, false, false)
                    SetBlockingOfNonTemporaryEvents(self.clonePed, true)
                    SetFocusPosAndVel(cam.COH.x, cam.COH.y, cam.COH.z - 1.0)
                    SetEntityCoords(self.clonePed, cam.COH.x, cam.COH.y, cam.COH.z)
                    Wait(100)
                    SetEntityVisible(self.clonePed, true, false)
                    SetEntityHeading(self.clonePed, cam.COH.w)
                    SetEntityCoords(self.clonePed, cam.COH.x, cam.COH.y, cam.COH.z - 1.0)
                    GiveWeaponToPed(self.clonePed, joaat(cam.perso.weapon), 250, false, true)
                    SetCurrentPedWeapon(self.clonePed, joaat(cam.perso.weapon), true)
                    VFW.Cam:UpdateAnim("campackshop", cam.Animation, self.clonePed)
                end

                if self.currentVehiclePreview then
                    if DoesEntityExist(self.currentVehiclePreview) then
                        DeleteEntity(self.currentVehiclePreview)
                        self.currentVehiclePreview = nil
                    end
                end

                if self.currentVehiclePack then
                    for _, vehicle in ipairs(self.currentVehiclePack) do
                        if DoesEntityExist(vehicle) then
                            DeleteEntity(vehicle)
                        end
                    end

                    self.currentVehiclePack = {}
                end

                if cam.vehicle then
                    if type(cam.vehicle) ~= "table" then
                        local vehicleModel = joaat(cam.vehicle.model)
                        VFW.Streaming.RequestModel(vehicleModel)

                        local vehicle = CreateVehicle(vehicleModel, cam.vehicle.coh.x, cam.vehicle.coh.y, cam.vehicle.coh.z, cam.vehicle.coh.w, false, false)
                        SetEntityAsMissionEntity(vehicle, true, true)
                        SetVehicleOnGroundProperly(vehicle)
                        FreezeEntityPosition(vehicle, true)
                        SetVehicleDoorsLocked(vehicle, 4)

                        self.currentVehiclePreview = vehicle
                    else
                        for _, vehicule in ipairs(cam.vehicle) do
                            console.debug("current model ", vehicule.model)
                            local model = joaat(vehicule.model)
                            RequestModel(model);
                            while (not HasModelLoaded(model)) do
                                Wait(0);
                            end

                            local pos = vector3(vehicule.coh.x, vehicule.coh.y, vehicule.coh.z)
                            local vehicle = CreateVehicle(model, pos, vehicule.coh.w, false, false)
                            SetModelAsNoLongerNeeded(model)
                            SetEntityAsMissionEntity(vehicle, true, true)
                            SetVehicleOnGroundProperly(vehicle)
                            FreezeEntityPosition(vehicle, true)
                            SetVehicleDoorsLocked(vehicle, 4)

                            table.insert(self.currentVehiclePack, vehicle)
                        end
                    end
                end
            end
        end)

        RegisterNuiCallback("boutique:weapon:color", function(data, cb)
            local color = data.skinId

            if not self.weaponObject or not DoesEntityExist(self.weaponObject) then
                console.debug("^1[ERROR]^0 weaponObject is nil or does not exist")
                if cb then
                    cb({ status = "error", message = "weaponObject invalid" })
                end

                return
            end

            if self.appliedWeaponTint then
                console.debug("Removing previous tint", self.appliedWeaponTint)
                SetWeaponObjectTintIndex(self.weaponObject, self.appliedWeaponTint)
            end

            self.appliedWeaponTint = nil

            if color then
                local tintIndex = tonumber(color)

                if tintIndex then
                    SetWeaponObjectTintIndex(self.weaponObject, tintIndex)
                    self.appliedWeaponTint = tintIndex
                else
                    console.debug("^1[ERROR]^0 Invalid tint index:", color)
                end
            end
        end)

        RegisterNuiCallback("boutique:vehivule:buy", function(data, cb)
            local playerPed = PlayerPedId()

            if not self.currentVehiclePreview then
                cb({
                    success = false,
                    message = "Aucun véhicule en prévisualisation."
                })
                return
            end

            local buying = TriggerServerCallback("boutique:buyVehicle", data.name, data.color, data.type, VFW.Game.GetVehicleProperties(self.currentVehiclePreview), GetMakeNameFromVehicleModel(data.name), self.currentPerf)

            if buying.success then
                if self.currentVehiclePreview ~= nil then
                    DeleteEntity(self.currentVehiclePreview)
                    self.currentVehiclePreview = nil
                end

                VFW.ShowNotification({
                    type = "VERT",
                    content = "Achat réussi !",
                })

                VFW.CloseEscapeMenu()
                self.DeleteCam()

                SetEntityCoords(playerPed, buying.pos.x, buying.pos.y, buying.pos.z)
                local boughtVeh = NetworkGetEntityFromNetworkId(buying.vehicle)
                if boughtVeh and boughtVeh ~= 0 and DoesEntityExist(boughtVeh) then
                    TaskWarpPedIntoVehicle(playerPed, boughtVeh, -1)
                end
            end

            cb({
                success = buying.success,
                message = buying.message,
                balance = buying.balance or 0
            })
        end)
    end

    self.prevVehicles = {}

--- .previewVehicle
---@param model any
---@param colors any
---@param performance any
---@param type any
    function self.previewVehicle(model, colors, performance, type)
        if self.currentVehiclePreview and DoesEntityExist(self.currentVehiclePreview) then
            DeleteEntity(self.currentVehiclePreview)

            self.currentVehiclePreview = nil
            Wait(200)
        end

        if #self.prevVehicles > 0 then
            for _, vehicle in ipairs(self.prevVehicles) do
                DeleteEntity(vehicle)
            end

            self.prevVehicles = {}
        end

        model = string.lower(model)

        local cam = self.boutiqueShop[type]
        if not cam then
            console.debug("[Preview] Coordonnées caméra introuvables pour le type:", type)
            return
        end

        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end

        local pos = vector3(cam.COH.x, cam.COH.y, cam.COH.z)
        local heading = cam.COH.w or 0.0
        local vehicle = CreateVehicle(model, pos, heading, false, false)

        table.insert(self.prevVehicles, vehicle)

        if not DoesEntityExist(vehicle) then
            console.debug("[Preview] Impossible de créer le véhicule:", model)
            return
        end

        self.currentVehiclePreview = vehicle

        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleModKit(vehicle, 0)
        FreezeEntityPosition(vehicle, true)
        SetVehicleDoorsLocked(vehicle, 4)
        SetVehicleEngineOn(vehicle, true, true, false)

        if performance and #performance > 0 then
            for i, mod in ipairs(performance) do
                SetVehicleMod(vehicle, i - 1, mod, false)
            end
        end

        SetModelAsNoLongerNeeded(model)
    end

---Create self.Cam
---@param type any
    function self.CreateCam(type)
        if not self.camCreated or self.currentCamType ~= type then

            Wait(250)

            self.currentCamType = type

            if self.camCreated then
                self.DeleteCam()
            end

            local cam = self.boutiqueShop[type]
            VFW.Cam:Create("requestBoutiqueCam", cam)
            SetFocusArea(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z, 0.0, 0.0, 0.0)

            PinInteriorInMemory(GetInteriorAtCoords(cam.CamCoords.x, cam.CamCoords.y, cam.CamCoords.z))

            TriggerScreenblurFadeOut(0)
            self.camCreated = true
        end
    end

---Delete self.Cam
    function self.DeleteCam()
        if self.camCreated then
            VFW.Cam:Destroy("requestBoutiqueCam")

            self.camCreatedcamCreated = false
            self.camCreated = nil

            if self.currentVehiclePreview ~= nil then
                DeleteEntity(self.currentVehiclePreview)
                self.currentVehiclePreview = nil
            end

            ClearFocus()
        end

        if self.camWeaponInstanceCreated then
            VFW.Cam:Destroy("weaponshopcam")

            self.lastModelWeapon = nil
            self.camWeaponInstance = false

            ClearFocus()

            if self.weaponObject and DoesEntityExist(self.weaponObject) then
                DeleteEntity(self.weaponObject)
                self.weaponObject = nil
            end
        end

        if self.camPackInstanceCreated then
            self.camPackInstanceCreated = false

            VFW.Cam:Destroy("campackshop")

            for _, v in ipairs(self.entityPackPreview) do
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end

            self.entityPackPreview = {}

            if self.clonePed and DoesEntityExist(self.clonePed) then
                DeleteEntity(self.clonePed)
                self.clonePed = nil
            end

            if self.currentVehiclePack then
                for _, vehicle in ipairs(self.currentVehiclePack) do
                    if DoesEntityExist(vehicle) then
                        DeleteEntity(vehicle)
                    end
                end

                self.currentVehiclePack = {}
            end

            if self.currentVehiclePreview then
                DeleteEntity(self.currentVehiclePreview)
                self.currentVehiclePreview = nil
            end

            ClearFocus()

            Wait(250)

        end

        self.initCoins = false
    end

    return self
end

local CBoutique = CreateCBoutique()

CBoutique.registerEvents()

VFW.GetCBoutique = function()
    while CBoutique == nil do

        Wait(0)
    end

    return CBoutique
end
