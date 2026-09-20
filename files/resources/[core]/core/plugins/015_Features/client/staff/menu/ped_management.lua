---@meta _
---@diagnostic disable: duplicate-doc-field

local function GetStaffTitle()
    return StaffMenu.menuContext == 'animator' and VFW.AnimatorTitle() or VFW.StaffTitle()
end

local pedData = {
    selectedCategory = 1,
    selectedPed = 1,
    searchText = "",
    customModel = ""
}

-- PED Persistence state
local savedPersistState = GetResourceKvpString("staff_persist_ped")
local isPedPersistenceEnabled = savedPersistState == "true"

local pedCategories = {
    {
        name = "Personnages Principaux",
        peds = {
            {name = "Michael", model = "player_zero"},
            {name = "Franklin", model = "player_one"},
            {name = "Trevor", model = "player_two"},
            {name = "MP Male", model = "mp_m_freemode_01"},
            {name = "MP Female", model = "mp_f_freemode_01"}
        }
    },
    {
        name = "Animaux",
        peds = {
            {name = "Chien Berger", model = "a_c_shepherd"},
            {name = "Chat", model = "a_c_cat_01"},
            {name = "Chien Husky", model = "a_c_husky"},
            {name = "Chien Retriever", model = "a_c_retriever"},
            {name = "Rottweiler", model = "a_c_rottweiler"},
            {name = "Carlin", model = "a_c_pug"},
            {name = "Cochon", model = "a_c_pig"},
            {name = "Sanglier", model = "a_c_boar"},
            {name = "Poulet", model = "a_c_hen"},
            {name = "Chimpanzé", model = "a_c_chimp"},
            {name = "Cow", model = "a_c_cow"},
            {name = "Coyote", model = "a_c_coyote"},
            {name = "Cerf", model = "a_c_deer"},
            {name = "Poisson", model = "a_c_fish"},
            {name = "Aigle", model = "a_c_chickenhawk"},
            {name = "Corbeau", model = "a_c_crow"},
            {name = "Dauphin", model = "a_c_dolphin"},
            {name = "Mouette", model = "a_c_seagull"},
            {name = "Requin", model = "a_c_sharktiger"},
            {name = "Lapin", model = "a_c_rabbit_01"}
        }
    },
    {
        name = "Services d'urgence",
        peds = {
            {name = "Policier", model = "s_m_y_cop_01"},
            {name = "Policière", model = "s_f_y_cop_01"},
            {name = "Sheriff", model = "s_m_y_sheriff_01"},
            {name = "Sheriff Femme", model = "s_f_y_sheriff_01"},
            {name = "SWAT", model = "s_m_y_swat_01"},
            {name = "Pompier", model = "s_m_y_fireman_01"},
            {name = "Paramédic", model = "s_m_m_paramedic_01"},
            {name = "Médecin", model = "s_m_m_doctor_01"},
            {name = "Marine", model = "s_m_m_marine_01"},
            {name = "Marine 02", model = "s_m_m_marine_02"},
            {name = "Ranger", model = "s_m_y_ranger_01"},
            {name = "Prisonnier", model = "s_m_y_prisoner_01"},
            {name = "Prisonnier 02", model = "s_m_y_prismuscl_01"},
            {name = "Garde", model = "s_m_m_prisguard_01"},
            {name = "Sécurité", model = "s_m_m_security_01"},
            {name = "Armée", model = "s_m_y_blackops_01"},
            {name = "Armée 02", model = "s_m_y_blackops_02"},
            {name = "Armée 03", model = "s_m_y_blackops_03"}
        }
    },
    {
        name = "Gangs",
        peds = {
            {name = "Ballas 01", model = "g_m_y_ballaorig_01"},
            {name = "Ballas 02", model = "g_m_y_ballaeast_01"},
            {name = "Ballas 03", model = "g_m_y_ballasout_01"},
            {name = "Families 01", model = "g_m_y_famca_01"},
            {name = "Families 02", model = "g_m_y_famdnf_01"},
            {name = "Families 03", model = "g_m_y_famfor_01"},
            {name = "Vagos 01", model = "g_m_y_mexgang_01"},
            {name = "Vagos 02", model = "g_m_y_mexgoon_01"},
            {name = "Vagos 03", model = "g_m_y_mexgoon_02"},
            {name = "Lost MC 01", model = "g_m_y_lost_01"},
            {name = "Lost MC 02", model = "g_m_y_lost_02"},
            {name = "Lost MC 03", model = "g_m_y_lost_03"},
            {name = "Korean 01", model = "g_m_y_korean_01"},
            {name = "Korean 02", model = "g_m_y_korean_02"},
            {name = "Korean Boss", model = "g_m_y_korlieut_01"},
            {name = "Aztecas", model = "g_m_y_azteca_01"},
            {name = "Marabunta", model = "g_m_y_salvagoon_01"}
        }
    },
    {
        name = "Civils",
        peds = {
            {name = "Hipster Male", model = "a_m_y_hipster_01"},
            {name = "Hipster Female", model = "a_f_y_hipster_01"},
            {name = "Business Male", model = "a_m_y_business_01"},
            {name = "Business Female", model = "a_f_y_business_01"},
            {name = "Beach Male", model = "a_m_y_beach_01"},
            {name = "Beach Female", model = "a_f_y_beach_01"},
            {name = "Fat Male", model = "a_m_m_fatlatin_01"},
            {name = "Fat Female", model = "a_f_m_fatwhite_01"},
            {name = "Bodybuilder", model = "a_m_y_musclbeac_01"},
            {name = "Jogger Male", model = "a_m_y_runner_01"},
            {name = "Jogger Female", model = "a_f_y_runner_01"},
            {name = "Skater", model = "a_m_y_skater_01"},
            {name = "Golfer", model = "a_m_y_golfer_01"},
            {name = "Hiker", model = "a_m_y_hiker_01"},
            {name = "Biker", model = "a_m_y_motox_01"},
            {name = "Roadcyc", model = "a_m_y_roadcyc_01"}
        }
    },
    {
        name = "Spéciaux",
        peds = {
            {name = "Zombie", model = "u_m_y_zombie_01"},
            {name = "Jesus", model = "u_m_m_jesus_01"},
            {name = "Clown", model = "s_m_y_clown_01"},
            {name = "Mime", model = "s_m_y_mime"},
            {name = "Astronaute", model = "s_m_m_movspace_01"},
            {name = "Alien", model = "s_m_m_movalien_01"},
            {name = "Bigfoot", model = "ig_orleans"},
            {name = "Stripper 01", model = "s_f_y_stripper_01"},
            {name = "Stripper 02", model = "s_f_y_stripper_02"},
            {name = "Bartender", model = "s_f_y_bartender_01"},
            {name = "Hooker 01", model = "s_f_y_hooker_01"},
            {name = "Hooker 02", model = "s_f_y_hooker_02"},
            {name = "Hooker 03", model = "s_f_y_hooker_03"}
        }
    }
}

-- Build Ped Management Menu
function StaffMenu.BuildPedManagementMenu()
    StaffMenu.pedManagement.Separator("GESTION DES PEDS")
    
    -- Custom model input
    StaffMenu.pedManagement.Button("MODÈLE PERSONNALISÉ", pedData.customModel ~= "" and pedData.customModel or "Cliquez pour entrer", nil, "chevron", false, function()
        local model = VFW.Nui.KeyboardInput(true, "Nom du modèle de ped", pedData.customModel)
        
        if model and model ~= "" then
            pedData.customModel = model
            StaffMenu.ChangePed(model)
        end
    end)
    
    -- Reset to default ped
    StaffMenu.pedManagement.Button("RÉINITIALISER LE PED", "Restaurer votre apparence de personnage RP par défaut", nil, "chevron", false, function()
        StaffMenu.ResetPed()
    end)

    -- Checkbox persistance PED (cachée si pas de permission)
    if VFW.PlayerGlobalData.permissions["persist_staff_ped"] then
        StaffMenu.pedManagement.Checkbox("MAINTENIR LE PED À LA RECONNEXION",
            "Le PED sera restauré automatiquement lors de la prochaine connexion",
            false,
            isPedPersistenceEnabled,
            function(_checked)
                isPedPersistenceEnabled = _checked
                SetResourceKvp("staff_persist_ped", _checked and "true" or "false")

                if _checked then
                    local currentPedModel = GetEntityModel(PlayerPedId())
                    TriggerServerEvent("vfw:staff:setStaffPed", currentPedModel)
                    VFW.ShowNotification({type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Menu Peds Staff', message = "Persistance du PED activée."})
                else
                    TriggerServerEvent("vfw:staff:clearStaffPed")
                    VFW.ShowNotification({type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Menu Peds Staff', message = "Persistance du PED désactivée."})
                end
            end)
    end

    -- Random ped
    StaffMenu.pedManagement.Button("PED ALÉATOIRE", "Choisir un modèle de ped aléatoire parmi toutes les catégories", nil, "chevron", false, function()
        local randomCategory = pedCategories[math.random(1, #pedCategories)]
        local randomPed = randomCategory.peds[math.random(1, #randomCategory.peds)]
        StaffMenu.ChangePed(randomPed.model)
    end)
    
    StaffMenu.pedManagement.Separator("CATÉGORIES")
    
    -- Ped categories
    for i, category in ipairs(pedCategories) do
        StaffMenu.pedManagement.Button(":user: " .. category.name, string.format("%d peds", #category.peds), nil, "chevron", false, function()
            pedData.selectedCategory = i
        end, StaffMenu.pedList)
    end
    
    StaffMenu.pedManagement.Separator(":palette: OPTIONS D'APPARENCE")

    -- Clean ped
    StaffMenu.pedManagement.Button(":trash: NETTOYER LE PED", "Supprimer le sang, la saleté et les dommages visuels du personnage", nil, "chevron", false, function()
        local playerPed = PlayerPedId()
        ClearPedBloodDamage(playerPed)
        ClearPedWetness(playerPed)
        ClearPedEnvDirt(playerPed)
        ResetPedVisibleDamage(playerPed)
        VFW.ShowNotification({
            type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Menu Peds Staff',
            message = "PED nettoyé."
      })
    end)
end

-- Build Ped List Menu
function StaffMenu.BuildPedListMenu()
    local category = pedCategories[pedData.selectedCategory]
    
    if not category then return end
    
    StaffMenu.pedList.Separator(category.name:upper())
    
    for _, ped in ipairs(category.peds) do
        StaffMenu.pedList.Button(":user: " .. ped.name, ped.model, nil, "chevron", false, function()
            StaffMenu.ChangePed(ped.model)
        end)
    end
end

-- Change ped function
function StaffMenu.ChangePed(modelName)
    local model = GetHashKey(modelName)
    
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        VFW.ShowNotification({
            type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Menu Peds Staff',
            message = "Ce modèle n'est pas valide : " .. modelName .. "."
      })
        return
    end
    
    RequestModel(model)
    local loadWait = 0
    while not HasModelLoaded(model) and loadWait < 5000 do
        Wait(50)
        loadWait = loadWait + 50
    end
    if not HasModelLoaded(model) then
        SetModelAsNoLongerNeeded(model)
        VFW.ShowNotification({
            type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Menu Peds Staff',
            message = "Le modèle n'a pas pu être chargé à temps : " .. modelName .. "."
      })
        return
    end

    -- Freeze + invincibilité pendant le model swap : SetPlayerModel détruit le
    -- net object puis en recrée un autre. Si le staff bouge pendant la fenêtre
    -- (noclip ou même juste un input), les clients voisins reçoivent un update
    -- de position sur un net object en cours de cleanup → crash GTA5+1691021
    -- (september-ceiling-network).
    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), model)

    -- SetPlayerModel respawn le ped en async côté streaming. Attendre que le
    -- nouveau PlayerPedId() soit valide évite des appels sur un handle stale.
    local newPed = PlayerPedId()
    local timeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and timeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        timeout = timeout + 1
    end

    -- SetPedDefaultComponentVariation assume un ped humanoïde (slots de
    -- components 0-11). Sur un ped animal (a_c_*) ou spécial, la native peut
    -- crash le renderer ou corrompre l'état du ped.
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(model)

    -- Stabilisation : laisser le net object se sync chez les voisins avant de
    -- libérer la position. 500ms est largement suffisant pour la propagation
    -- (latence typique <100ms) tout en restant invisible pour le staff.
    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
    end

    -- Restore health and armor
    SetEntityHealth(newPed, GetEntityMaxHealth(newPed))
    
    VFW.ShowNotification({
        type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Menu Peds Staff',
        message = "PED changé : " .. modelName .. "."
  })

    -- Save ped if persistence is enabled
    if isPedPersistenceEnabled and VFW.PlayerGlobalData.permissions["persist_staff_ped"] then
        TriggerServerEvent("vfw:staff:setStaffPed", modelName)
    end
end

-- Reset ped to default
function StaffMenu.ResetPed()
    -- Clear persistence if enabled
    if isPedPersistenceEnabled then
        isPedPersistenceEnabled = false
        SetResourceKvp("staff_persist_ped", "false")
        TriggerServerEvent("vfw:staff:clearStaffPed")
    end

    -- This should restore the player's original character model
    TriggerServerEvent("vfw:staff:resetPed")

    VFW.ShowNotification({
        type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Menu Peds Staff',
        message = "Personnage réinitialisé."
  })
end

-- Outfit management
function StaffMenu.SaveOutfit(name)
    local playerPed = PlayerPedId()
    local outfit = {
        model = GetEntityModel(playerPed),
        components = {},
        props = {}
    }
    
    -- Save components
    for i = 0, 11 do
        outfit.components[i] = {
            drawable = GetPedDrawableVariation(playerPed, i),
            texture = GetPedTextureVariation(playerPed, i),
            palette = GetPedPaletteVariation(playerPed, i)
        }
    end
    
    -- Save props
    for i = 0, 7 do
        outfit.props[i] = {
            drawable = GetPedPropIndex(playerPed, i),
            texture = GetPedPropTextureIndex(playerPed, i)
        }
    end
    
    TriggerServerEvent("vfw:staff:saveOutfit", name, outfit)
    
    VFW.ShowNotification({
        type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Gestion Peds',
        message = "Tenue sauvegardée : " .. name .. "."
  })
end

function StaffMenu.LoadOutfit(outfit)
    local playerPed = PlayerPedId()
    
    -- Apply components
    for i, component in pairs(outfit.components or {}) do
        SetPedComponentVariation(playerPed, i, component.drawable, component.texture, component.palette)
    end
    
    -- Apply props
    for i, prop in pairs(outfit.props or {}) do
        if prop.drawable == -1 then
            ClearPedProp(playerPed, i)
        else
            SetPedPropIndex(playerPed, i, prop.drawable, prop.texture, true)
        end
    end
    
    VFW.ShowNotification({
        type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Gestion Peds',
        message = "Tenue chargée."
  })
end