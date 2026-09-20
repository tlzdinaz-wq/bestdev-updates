---
--- Bar Menu System - Client
--- Affiche la carte des bars (via item)
---

local function ShowJobNotification(content, isError)
    local societyImage = TriggerServerCallback("core:get:societyImage")
    local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or "Information"
    local notifType = isError and 'ROUGE' or 'JOB'
    VFW.ShowNotification({
        type = notifType,
        image = societyImage,
        title = jobLabel,
        subtitle = "Information",
        content = content
    })
end

local menuOpen = false
local isPreviewMode = false  -- Mode prévisualisation depuis le bossPanel
local menuProp = nil  -- Prop de carte pour l'animation
local isAnimating = false  -- Animation en cours

-- Démarrer l'animation de consultation de carte (même emote que "Carte" du menu K)
local function StartMenuAnimation()
    local ped = PlayerPedId()
    local dict = "amb@world_human_tourist_map@male@base"
    local animName = "base"

    -- Charger le dictionnaire d'animation
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasAnimDictLoaded(dict) then return end

    -- Créer le prop de carte touristique (même que emote "Carte")
    local propModel = GetHashKey("prop_tourist_map_01")
    RequestModel(propModel)
    timeout = GetGameTimer() + 5000
    while not HasModelLoaded(propModel) and GetGameTimer() < timeout do
        Wait(10)
    end

    if HasModelLoaded(propModel) then
        local boneIndex = GetPedBoneIndex(ped, 28422) -- IK_R_Hand
        menuProp = CreateObject(propModel, 0.0, 0.0, 0.0, false, true, false)
        AttachEntityToEntity(menuProp, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(propModel)
    end

    -- Jouer l'animation en boucle
    TaskPlayAnim(ped, dict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    isAnimating = true
end

-- Arrêter l'animation de consultation
local function StopMenuAnimation()
    if not isAnimating then return end

    local ped = PlayerPedId()
    ClearPedTasks(ped)

    if menuProp and DoesEntityExist(menuProp) then
        DeleteEntity(menuProp)
        menuProp = nil
    end

    isAnimating = false
end

-- Ouvrir le menu
local function OpenMenu(jobName)
    if menuOpen then return end
    menuOpen = true

    local items = TriggerServerCallback("bar:menu:getItems", jobName)
    if not items then
        ShowJobNotification("Erreur lors du chargement de la carte.", false)
        menuOpen = false
        return
    end

    SendNUIMessage({
        action = "openBarMenu",
        data = items
    })
    VFW.Nui.Focus(true)
end

-- Fermer le menu
local function CloseMenu()
    if not menuOpen then return end
    menuOpen = false
    SendNUIMessage({ action = "closeBarMenu" })

    -- En mode prévisualisation, garder le focus actif pour le bossPanel
    if isPreviewMode then
        isPreviewMode = false
        VFW.Nui.Focus(true)
    else
        VFW.Nui.Focus(false)
        StopMenuAnimation()  -- Arrêter l'animation seulement si pas en preview
    end
end

-- Event: Ouvrir le menu depuis un item
RegisterNetEvent("bar:menu:openFromItem", function(jobName)
    VFW.CloseInventory()
    Wait(100)
    StartMenuAnimation()
    Wait(200)  -- Petit délai pour que l'animation démarre
    OpenMenu(jobName)
end)

-- Callback NUI: fermeture
RegisterNUICallback("closeMenu", function(_, cb)
    CloseMenu()
    cb("ok")
end)

-- Callback NUI: sélection d'item (informatif)
RegisterNUICallback("selectItem", function(data, cb)
    if data.item then
        ShowJobNotification(string.format("%s - %s", data.item.label, VFW.Math.FormatMoney(data.item.price or 0)), false)
    end
    cb("ok")
end)

-- Callbacks NUI pour le panel boss
RegisterNUICallback("bar:menu:getConfig", function(data, cb)
    local result, error = TriggerServerCallback("bar:menu:getConfig")
    cb({result, error})
end)

RegisterNUICallback("bar:menu:saveConfig", function(data, cb)
    local success, message = TriggerServerCallback("bar:menu:saveConfig", data)
    cb({success, message})
end)

-- Callback NUI: prévisualisation de la carte depuis le panel boss
RegisterNUICallback("bar:menu:preview", function(data, cb)
    -- Si des sections sont fournies (nouveau format avec categories)
    if data and data.sections and #data.sections > 0 then
        local previewData = {
            barName = data.barName or "Carte du Bar",
            jobName = data.jobName,
            sections = data.sections
        }

        isPreviewMode = true
        SendNUIMessage({
            action = "openBarMenu",
            data = previewData
        })
        menuOpen = true
    else
        -- Fallback: récupérer les items sauvegardés du serveur avec le bon jobName
        local jobName = data and data.jobName or nil
        local items = TriggerServerCallback("bar:menu:getItems", jobName)
        if items then
            isPreviewMode = true
            SendNUIMessage({
                action = "openBarMenu",
                data = items
            })
            menuOpen = true
        end
    end
    cb("ok")
end)

-- Thread ESC pour fermer + désactiver les contrôles de caméra
Citizen.CreateThread(function()
    while true do
        if menuOpen then
            Citizen.Wait(0)

            -- Désactiver les contrôles de caméra/souris
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride

            -- Désactiver les contrôles d'attaque (évite les coups de poing en cliquant)
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 140, true) -- MeleeAttackLight
            DisableControlAction(0, 141, true) -- MeleeAttackHeavy
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 257, true) -- Attack2

            -- ESC pour fermer
            if IsControlJustReleased(0, 322) then
                CloseMenu()
            end

            -- TAB pour fermer (évite conflit avec inventaire)
            if IsControlJustReleased(0, 37) then
                CloseMenu()
            end
        else
            Citizen.Wait(500)
        end
    end
end)
