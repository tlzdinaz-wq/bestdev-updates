---@meta _
---@diagnostic disable: duplicate-doc-field

local open = false
local objetSpawn = {}
local objetsData = {}
local decoExtData = {
    Tables = {
        ["prop_table_03"] = "Table blanche",
        ["bkr_prop_weed_table_01b"] = "Table",
        ["prop_table_01"] = "Petite table",
        ["prop_proxy_chateau_table"] = "Table ronde",
    },
    Sport = {
        ["gr_prop_gr_target_05a"] = "Cible noir",
        ["gr_prop_gr_target_05b"] = "Cible blanc",
        ["prop_big_bag_01"] = "Sac de sport",
        ["p_ld_am_ball_01"] = "Balle football",
        ["p_ld_soc_ball_01"] = "Balle soccer",
        ["prop_bskball_01"] = "Balle basket",
        ["vw_prop_casino_art_basketball_02a"] = "Balle basket noir",
        ["vw_prop_casino_art_basketball_01a"] = "Balle basket blanc",
        ["prop_acc_guitar_01"] = "Guitare",
    },
    Outils = {
        ["prop_mp_cone_02"] = "Cone",
        ["prop_air_conelight"] = "Cone aéroport",
        ["prop_mp_barrier_02b"] = "Barrière",
        ["prop_barrier_work05"] = "Barrière LSPD",
        ["prop_barrier_work06a"] = "Petite barrière",
        ["ba_prop_battle_barrier_02a"] = "Barrière en fer",
        ["v_ind_cs_toolbox4"] = "Caisse à outils",
        ["prop_coffin_01"] = "Cercueil 1",
        ["prop_coffin_02b"] = "Cercueil 2",
        ["prop_pap_camera_01"] = "Appareil photo",
        ["xm_prop_x17_bag_med_01a"] = "Sac médical",
    },
    Nourriture = {
        ["ba_prop_club_water_bottle"] = "Bouteille d'eau",
        ["prop_cardbordbox_03a"] = "Carton 1",
        ["ng_proc_box_01a"] = "Carton 2",
        ["prop_pizza_box_02"] = "Pizza 1",
        ["prop_pizza_box_03"] = "Pizza 2",
        ["prop_food_bs_bag_04"] = "Sac en carton",
        ["prop_food_bs_bag_01"] = "Sac en carton BS",
        ["prop_food_bs_burg3"] = "Boite en carton",
        ["prop_food_bs_chips"] = "Frites",
        ["prop_food_bs_juice01"] = "Pillave",
        ["prop_food_bs_coffee"] = "Café",
        ["prop_food_bs_tray_02"] = "Menu BS",
        ["prop_food_cb_bag_02"] = "Sac en carton CB",
        ["prop_food_cb_burg02"] = "Boite en carton",
        ["prop_food_cb_chips"] = "Frites",
        ["prop_food_cb_nugets"] = "Nuggets",
        ["prop_food_cb_juice01"] = "Pillave",
        ["prop_food_cb_coffee"] = "Café",
        ["prop_food_cb_tray_02"] = "Menu CB",
        ["prop_fib_coffee"] = "Café BM",
        ["vw_prop_casino_wine_glass_01b"] = "Verre de vin",
        ["prop_drink_whtwine"] = "Vin blanc",
        ["prop_drink_whisky"] = "Whisky",
        ["prop_bottle_brandy"] = "Eau de vie",
        ["prop_bottle_cognac"] = "Cognac",
        ["prop_rum_bottle"] = "Rum",
        ["prop_tequila_bottle"] = "Tequila",
        ["prop_vodka_bottle"] = "Vodka",
        ["apa_mp_h_acc_bottle_01"] = "Bouteille 1",
        ["h4_prop_h4_t_bottle_01a"] = "Bouteille 2",
        ["h4_prop_h4_t_bottle_02a"] = "Bouteille 3",
        ["h4_prop_h4_t_bottle_02b"] = "Bouteille 4",
        ["prop_whiskey_bottle"] = "Bouteille whiskey 1",
        ["p_whiskey_bottle_s"] = "Bouteille whiskey 2",
        ["ba_prop_battle_whiskey_bottle_s"] = "Bouteille whiskey 3",
        ["ba_prop_battle_whiskey_bottle_2_s"] = "Bouteille whiskey 4",
        ["ba_prop_battle_champ_closed_03"] = "Bouteille champagne",
        ["prop_champ_jer_01a"] = "Bouteille champagne 2",
        ["h4_p_h4_champ_flute_s"] = "Flute champagne",
        ["v_62_ecolacup003"] = "Coca",
        ["prop_pinacolada"] = "Piña colada",
    },
    Light = {
        ["xm_prop_base_tripod_lampa"] = "Lampe 1",
        ["xm_prop_base_tripod_lampb"] = "Lampe 2",
        ["xm_prop_base_tripod_lampc"] = "Lampe 3",
        ["prop_studio_light_01"] = "Projecteur 1",
        ["prop_studio_light_02"] = "Projecteur 2",
        ["prop_studio_light_03"] = "Projecteur 3",
        ["prop_worklight_03b"] = "Projecteur 4",
        ["prop_worklight_02a"] = "Projecteur 5",
        ["xm_prop_base_tower_lampa"] = "Projecteur 6",
    },
    Illegal = {
        ["prop_anim_cash_note"] = "Billet",
        ["prop_anim_cash_pile_01"] = "Liasse",
        ["prop_anim_cash_pile_02"] = "Grosse liasse",
        ["prop_cash_case_01"] = "Malette de billets 1",
        ["prop_cash_case_02"] = "Malette de billets 2",
        ["ex_office_swag_drugbag2"] = "Sac de drogue 1",
        ["ex_office_swag_drugbags"] = "Sac de drogue 2",
        ["bkr_prop_weed_smallbag_01a"] = "Pochon weed",
        ["prop_gun_case_01"] = "Malette noire",
        ["prop_box_guncase_01a"] = "Malette blanche",
        ["prop_idol_case_02"] = "Grosse malette",
        ["prop_ld_ammo_pack_01"] = "Boite munitions 1",
        ["prop_ld_ammo_pack_02"] = "Boite munitions 2",
        ["prop_ld_ammo_pack_03"] = "Boite munitions 3",
        ["bkr_prop_meth_smallbag_01a"] = "Pochon meth",
    },
    Exterieur = {
        ["prop_beach_fire"] = "Bois cramé",
        ["prop_forsale_dyn_01"] = "Pancarte Dynasty 1",
        ["prop_forsale_dyn_02"] = "Pancarte Dynasty 2",
        ["prop_barbell_01"] = "Haltère",
        ["prop_gazebo_01"] = "Barnum vert",
        ["prop_gazebo_02"] = "Barnum bleu",
        ["prop_gazebo_03"] = "Barnum blanc",
        ["prop_bbq_5"] = "Barbecue noir",
        ["prop_bbq_1"] = "Barbecue blanc",
    },
    Electronique = {
        ["v_ilev_fos_mic"] = "Micro 1",
        ["v_club_roc_micstd"] = "Micro 2",
        ["sf_prop_sf_mic_rec_01a"] = "Micro 3",
        ["sf_prop_sf_mic_rec_01b"] = "Micro 4",
        ["v_62_boom_mic"] = "Micro 5",
        ["xm_prop_x17_laptop_mrsr"] = "Ordinateur 1",
        ["ba_prop_battle_laptop_dj"] = "Ordinateur 2",
    },
    Decoration = {
        ["prop_cs_rolled_paper"] = "Microphone",
        ["v_ret_box"] = "Boite",
        ["v_ret_ps_box_01"] = "Boîte cadeau",
        ["vw_prop_casino_shopping_bag_01a"] = "Sac casino",
        ["v_ret_ps_bag_02"] = "Sac casino",
        ["prop_beach_lilo_01"] = "Lit gonflable",
        ["hei_heist_copfile01"] = "Fichier 1",
        ["hei_heist_copfile02"] = "Fichier 2",
        ["prop_cs_documents_01"] = "Documents",
        ["prop_xmas_tree_int"] = "Sapin de nöel",
        ["ex_prop_adv_case_sm_02"] = "Caisse noir",
        ["prop_wine_bot_01"] = "Bouteille de vin 1",
        ["prop_wine_bot_02"] = "Bouteille de vin 2",
        ["prop_wine_red"] = "Bouteille vin rouge",
        ["prop_wine_rose"] = "Bouteille vin rosé",
        ["prop_wine_white"] = "Bouteille vin blanc",
        ["ch_prop_ch_security_case_01a"] = "Malette de bijoux",
        ["hei_heist_acc_artgolddisc_03"] = "Disque d'or",
        ["v_res_fh_tableplace"] = "Table",
    },
    Chaise = {
        ["prop_table_03_chr"] = "Chaise en plastique",
        ["prop_table_01_chr_b"] = "Chaise en bois",
    }
}
local defaultCategory = "Tables"
local lastCategory = "Tables"
local premium = "vip_bronze"

---Get ObjetsCategory
---@param category any
local function getObjetsCategory(category)
    objetsData[category] = {}

    if decoExtData[category] then
        for prop, label in pairs(decoExtData[category]) do
            local item = {
                label = label,
                model = prop,
                image = "assets/catalogues/props/premium/" .. prop .. ".webp",
                style = "normal"
            }
            table.insert(objetsData[category], item)
        end
    end

    return objetsData[category]
end

---Get ObjetsData
---@param category any
---@return any
local function getObjetsData(category)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = VFW.CDN.Get("banners/default.png"),
            buyTextType = false,
            buyText = "Récupérer",
        },
        eventName = "objet_premium",
        category = { show = false },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = {
            show = true,
            items = {{ label = category, id = nil }}
        },
        showStats = { show = false },
        mouseEvents = false,
        color = { show = false },
        items = getObjetsCategory(category)
    }

    return data
end

--- menuObjetsData
---@return any
local function menuObjetsData()
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 2,
            buyType = 0,
            bannerImg = VFW.CDN.Get("banners/default.png"),
            buyTextType = false,
            buyText = "Sélectionner",
        },
        eventName = "objetMain_premium",
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        nameContainer = { show = false },
        headCategory = {
            show = true,
            items = {{ label = "Objets", id = nil }}
        },
        category = { show = false },
        cameras = { show = false },
        items = {
            {
                label = 'Tables',
                model = 'Tables',
                image = "assets/catalogues/props/cones.png",
                style = "normal",
            },
            {
                label = 'Sport',
                model = 'Sport',
                image = "assets/catalogues/props/panneaux.png",
                style = "normal",
            },
            {
                label = 'Outils',
                model = 'Outils',
                image = "assets/catalogues/props/barriere.png",
                style = "normal",
            },
            {
                label = 'Nourriture',
                model = 'Nourriture',
                image = "assets/catalogues/props/lumiere.png",
                style = "normal",
            },
            {
                label = 'Light',
                model = 'Light',
                image = "assets/catalogues/props/table.png",
                style = "normal",
            },
            {
                label = 'Illegal',
                model = 'Illegal',
                image = "assets/catalogues/props/drogues.png",
                style = "normal",
            },
            {
                label = 'Exterieur',
                model = 'Exterieur',
                image = "assets/catalogues/props/divers.png",
                style = "normal",
            },
            {
                label = 'Electronique',
                model = 'Electronique',
                image = "assets/catalogues/props/cible.png",
                style = "normal",
            },
            {
                label = 'Decoration',
                model = 'Decoration',
                image = "assets/catalogues/props/sacs_24.png",
                style = "normal",
            },
            {
                label = 'Chaise',
                model = 'Chaise',
                image = "assets/catalogues/props/sacs_24.png",
                style = "normal",
            },
        }
    }

    return data
end

--- .MenuPremiumObjet
---@param category any
function VFW.MenuPremiumObjet(category)
    open = true

    -- Reset to default and check permission to prevent flash
    premium = "vip_bronze"
    if VFW.PlayerGlobalData.permissions["vip_gold"] then
        premium = "vip_gold"
    elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
        premium = "vip_silver"
    end

    if category == nil then
        VFW.Nui.BigMenu(true, menuObjetsData())
    else
        VFW.Nui.BigMenu(true, getObjetsData(category))
    end

    SetNuiFocusKeepInput(true)

    CreateThread(function()
        while open do
            Wait(0)
            DisableControlAction(0, 24, true) -- disable attack
            DisableControlAction(0, 25, true) -- disable aim
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, open)
            DisableControlAction(0, 18, open)
            DisableControlAction(0, 322, open)
            DisableControlAction(0, 106, open)
            DisableControlAction(0, 263, true) -- disable melee
            DisableControlAction(0, 264, true) -- disable melee
            DisableControlAction(0, 257, true) -- disable melee
            DisableControlAction(0, 140, true) -- disable melee
            DisableControlAction(0, 141, true) -- disable melee
            DisableControlAction(0, 142, true) -- disable melee
            DisableControlAction(0, 143, true) -- disable melee
        end
    end)
end

--- closeUI
local function closeUI()
    open = false
    VFW.Nui.BigMenu(false)
    SetNuiFocusKeepInput(false)
end

--- SpawnProps
---@param category any
---@param obj any
local function SpawnProps(category, obj)
    local playerPed = VFW.PlayerData.ped
    local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
    local objCoords = coords + forward * 2.5
    local heading = GetEntityHeading(playerPed)
    local placed = false
    local objS = VFW.OneSync.CreateObject(obj, objCoords, heading)

    SetEntityHeading(objS, heading)
    PlaceObjectOnGroundProperly(objS)
    SetEntityAlpha(objS, 170, false)
    SetEntityCollision(objS, false, true)

    while not placed do
        coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        objCoords = coords + forward * 2.5
        SetEntityCoords(objS, objCoords.x, objCoords.y, objCoords.z, false, false, false, true)
        PlaceObjectOnGroundProperly(objS)

        if IsControlPressed(0, 190) then
            heading = heading + 0.5
        elseif IsControlPressed(0, 189) then
            heading = heading - 0.5
        end

        SetEntityHeading(objS, heading)

        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour placer l'objet\n~INPUT_FRONTEND_LEFT~ ou ~INPUT_FRONTEND_RIGHT~ Pour faire pivoter l'objet")

        if VFW.Interact.JustPressed(0, 38) then
            placed = true
        end

        DisableControlAction(0, 22, true)

        Wait(0)
    end

    ResetEntityAlpha(objS)
    SetEntityCollision(objS, true, true)
    FreezeEntityPosition(objS, true)
    if NetworkGetEntityIsNetworked(objS) then
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(objS), true)
    end
    table.insert(objetSpawn, objS)
    VFW.MenuPremiumObjet(category)
end

RegisterNuiCallback("nui:newgrandcatalogue:objetMain_premium:selectGridType2", function(data)
    lastCategory = data
    Wait(50)
    VFW.Nui.UpdateBigMenu(getObjetsData(lastCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:objet_premium:selectGridType", function(data)
    closeUI()
    Wait(50)
    for prop, _ in pairs(decoExtData[lastCategory]) do
        if prop == data then
            SpawnProps(lastCategory, data)
            break
        end
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:objet_premium:backspace", function()
    lastCategory = defaultCategory
    VFW.Nui.UpdateBigMenu(menuObjetsData())
end)

RegisterNuiCallback("nui:newgrandcatalogue:objetMain_premium:close", function()
    closeUI()
end)

RegisterNuiCallback("nui:newgrandcatalogue:objet_premium:close", function()
    closeUI()
end)

VFW.ContextAddButton("object", "Ramasser", function(object)
    for _, ent in pairs(objetSpawn) do
        if ent and DoesEntityExist(ent) then
            local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(ent))
            if distance < 2.75 then
                return true
            end
        end
    end

    return false
end, function(object)
    for i = #objetSpawn, 1, -1 do
        if objetSpawn[i] and DoesEntityExist(objetSpawn[i]) and objetSpawn[i] == object then
            DeleteEntity(objetSpawn[i])
            table.remove(objetSpawn, i)
        end
    end
end)
