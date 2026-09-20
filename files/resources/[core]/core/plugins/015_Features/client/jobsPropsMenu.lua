---@meta _
---@diagnostic disable: duplicate-doc-field

local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/metier.png")
local propsMenu = VUI:CreateMenu("Objets Métier", defaultBanner, true)

local trackedProps = {} -- { [netId] = { job, model } } synced from server
local pendingPlacements = 0 -- count des placements en attente de syncAdd
local StartGizmoPlacement
local menuPreviewObj = nil
local menuPreviewSerial = 0

local function DeleteMenuPreview()
    menuPreviewSerial = menuPreviewSerial + 1
    if menuPreviewObj and DoesEntityExist(menuPreviewObj) then
        DeleteEntity(menuPreviewObj)
    end
    menuPreviewObj = nil
end

local function SpawnMenuPreview(model)
    DeleteMenuPreview()
    local serial = menuPreviewSerial
    local modelHash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(modelHash) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnPos = coords + forward * 2.5

    VFW.Game.SpawnLocalObject(model, spawnPos, function(obj)
        if obj and DoesEntityExist(obj) then
            if serial ~= menuPreviewSerial then
                DeleteEntity(obj)
                return
            end
            menuPreviewObj = obj
            PlaceObjectOnGroundProperly(obj)
            SetEntityAlpha(obj, 150, false)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, true)
        end
    end)
end

-- ============================================
-- HELPERS - Props & Permissions
-- ============================================

local function GetPropsForJob(jobName)
    local custom = Society.data and Society.data.custom
    if custom and custom.props and #custom.props > 0 then
        return custom.props
    end
    return VFW.JobsPropsMenu.registered[jobName] or {}
end

local function CanPlaceProps()
    local job = VFW.PlayerData.job
    local custom = Society.data and Society.data.custom
    local minGrade = custom and custom.propsMinGradePlace or 0
    return job.grade >= minGrade
end

local function CanRemoveProps()
    local job = VFW.PlayerData.job
    local custom = Society.data and Society.data.custom
    local minGrade = custom and custom.propsMinGradeRemove or 0
    return job.grade >= minGrade
end

-- ============================================
-- SYNC EVENTS
-- ============================================

RegisterNetEvent('jobsPropsMenu:syncAll', function(allProps)
    trackedProps = allProps or {}
end)

RegisterNetEvent('jobsPropsMenu:syncAdd', function(netId, data)
    trackedProps[netId] = data
    if data.owner == GetPlayerServerId(PlayerId()) then
        pendingPlacements = math.max(0, pendingPlacements - 1)
    end
end)

RegisterNetEvent('jobsPropsMenu:syncRemove', function(netId)
    trackedProps[netId] = nil

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end)

RegisterNetEvent('jobsPropsMenu:syncMove', function(netId, newCoords, newRot)
    if trackedProps[netId] then
        trackedProps[netId].coords = newCoords
        trackedProps[netId].rot = newRot
    end
end)

RegisterNetEvent('jobsPropsMenu:limitReached', function(max)
    pendingPlacements = math.max(0, pendingPlacements - 1)
    VFW.ShowNotification({ type = 'ROUGE', content = "Limite atteinte (" .. max .. " objets max)" })
end)

-- ============================================
-- VUI MENU - Sélection de props
-- ============================================

local function OpenPropsMenu()
    local jobName = VFW.PlayerData.job.name
    local propsList = GetPropsForJob(jobName)

    if not propsList or #propsList == 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun objet disponible pour votre métier" })
        return
    end

    if not CanPlaceProps() then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas le grade requis pour poser des objets" })
        return
    end

    propsMenu.open()
end

local currentPropsList = nil

propsMenu.OnOpen(function()
    -- Utiliser la bannière custom de la société si elle existe
    if Society.data and Society.data.banner and Society.data.banner ~= "" then
        propsMenu.ChangeBanner(Society.data.banner)
    else
        propsMenu.ChangeBanner(defaultBanner)
    end
    local jobName = VFW.PlayerData.job.name
    local propsList = GetPropsForJob(jobName)

    if not propsList or #propsList == 0 then return end

    currentPropsList = propsList

    -- Preview du premier prop dès l'ouverture (dans un thread car SpawnObject utilise Wait)
    CreateThread(function()
        SpawnMenuPreview(propsList[1].model)
    end)

    for _, propData in ipairs(propsList) do
        propsMenu.Button(propData.name, propData.desc or nil, nil, "chevron", false, function()
            DeleteMenuPreview()
            propsMenu.close()
            -- StartGizmoPlacement uses Wait() internally → must run in its own thread
            -- so the NUI callback returns immediately and the UI isn't frozen
            local model = propData.model
            CreateThread(function()
                Wait(150)
                StartGizmoPlacement(model, jobName)
            end)
        end)
    end
end)

propsMenu.OnIndexChange(function(index)
    if not currentPropsList or not currentPropsList[index] then return end
    local model = currentPropsList[index].model
    CreateThread(function()
        SpawnMenuPreview(model)
    end)
end)

propsMenu.OnClose(function()
    currentPropsList = nil
    DeleteMenuPreview()
end)

-- ============================================
-- GIZMO PLACEMENT
-- ============================================

local function SpawnPreviewObject(model, position)
    local modelHash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(modelHash) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Ce modèle n'est pas valide : " .. tostring(model) })
        return nil
    end

    local obj = nil
    VFW.Game.SpawnLocalObject(model, position, function(props)
        obj = props
    end)

    if not obj or not DoesEntityExist(obj) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Échec du spawn de l'objet" })
        return nil
    end

    SetEntityAlpha(obj, 150, false)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, true)

    return obj
end

local MAX_PROPS_PER_PLAYER = 15

local function GetMaxProps()
    local custom = Society.data and Society.data.custom
    return (custom and custom.propsMaxPlayer) or MAX_PROPS_PER_PLAYER
end

local function GetMyPropCount()
    local myId = GetPlayerServerId(PlayerId())
    local count = 0
    for _, data in pairs(trackedProps) do
        if data.owner == myId then
            count = count + 1
        end
    end
    return count + pendingPlacements
end

local function FinalizePropsPlacement(model, pos, rot, jobName)
    VFW.Game.SpawnObject(model, pos, function(obj)
        if not obj or not DoesEntityExist(obj) then return end

        SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true)
        SetEntityCollision(obj, true, true)
        PlaceObjectOnGroundProperly(obj)
        -- Dynamique désactivé : l'objet tient en place par lui-même sans être freezé,
        -- les véhicules peuvent le déplacer au lieu de se bloquer net.
        SetEntityDynamic(obj, false)

        local netId = ObjToNet(obj)
        SetNetworkIdExistsOnAllMachines(netId, true)
        SetNetworkIdCanMigrate(netId, true)

        Entity(obj).state:set("jobProp", jobName, true)

        pendingPlacements = pendingPlacements + 1

        local objCoords = GetEntityCoords(obj)
        TriggerServerEvent('jobsPropsMenu:place', netId, jobName, model, { x = objCoords.x, y = objCoords.y, z = objCoords.z })

        VFW.ShowNotification({ type = 'VERT', content = "Objet placé" })
    end)
end

StartGizmoPlacement = function(model, jobName)
    local maxProps = GetMaxProps()
    if GetMyPropCount() >= maxProps then
        VFW.ShowNotification({ type = 'ROUGE', content = "Limite atteinte (" .. maxProps .. " objets max)" })
        return
    end

    local playerPed = VFW.PlayerData.ped
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnPos = coords + forward * 2.5

    local previewObj = SpawnPreviewObject(model, spawnPos)
    if not previewObj then return end

    PlaceObjectOnGroundProperly(previewObj)

    local buttonsId = VFW.AddInstructionalButtons({
        { label = "Poser l'objet", control = 38 },
        { label = "Tourner", control = 15, control2 = 16 },
        { label = "Mode avancé", control = 47 },
        { label = "Terminer", control = 177 },
    })

    local currentHeading = GetEntityHeading(playerPed)
    local placing = true
    local useGizmo = false

    while placing do
        Wait(0)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)
        local targetPos = pCoords + fwd * 2.5

        SetEntityCoords(previewObj, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(previewObj)
        SetEntityHeading(previewObj, currentHeading)

        -- Molette pour tourner
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 16, true)
        if IsDisabledControlJustPressed(0, 15) then
            currentHeading = currentHeading + 15.0
        end
        if IsDisabledControlJustPressed(0, 16) then
            currentHeading = currentHeading - 15.0
        end

        -- Disable attaque
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(ped, true)

        -- E = poser
        if VFW.Interact.JustPressed(0, 38) then
            placing = false
        end

        -- G = mode avancé
        if IsControlJustPressed(0, 47) then
            placing = false
            useGizmo = true
        end

        -- Escape ou Suppr = annuler et retour au menu
        if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
            placing = false
            if DoesEntityExist(previewObj) then DeleteEntity(previewObj) end
            VFW.RemoveInstructionalButtons(buttonsId)
            OpenPropsMenu()
            return
        end
    end

    VFW.RemoveInstructionalButtons(buttonsId)

    if useGizmo then
        local data = exports["core"]:useGizmo(previewObj)
        if data and data.switchedBack then
            -- Suppr : retour au mode normal de placement
            if DoesEntityExist(previewObj) then DeleteEntity(previewObj) end
            StartGizmoPlacement(model, jobName)
        elseif data and data.handle and DoesEntityExist(data.handle) then
            -- Validé : placer et enchaîner sur un nouveau placement
            DeleteEntity(previewObj)
            FinalizePropsPlacement(model, data.position, data.rotation, jobName)
            StartGizmoPlacement(model, jobName)
        else
            -- Annulé (Escape) : retour au menu
            if DoesEntityExist(previewObj) then DeleteEntity(previewObj) end
            OpenPropsMenu()
        end
    else
        local finalPos = GetEntityCoords(previewObj)
        local finalRot = GetEntityRotation(previewObj)
        DeleteEntity(previewObj)
        FinalizePropsPlacement(model, finalPos, finalRot, jobName)
        StartGizmoPlacement(model, jobName)
    end
end

-- ============================================
-- CONTEXT BUTTON - Ramasser
-- ============================================

local PICKUP_ANIM = { dict = "anim@move_m@trash", name = "pickup" }

VFW.ContextAddButton("object", ":box: Ramasser l'objet", function(object)
    if not object or not DoesEntityExist(object) then return false end

    local jobProp = Entity(object).state.jobProp
    if not jobProp then return false end

    local playerJob = VFW.PlayerData.job
    if not playerJob or not playerJob.onDuty then return false end
    if playerJob.name ~= jobProp then return false end
    if not CanRemoveProps() then return false end

    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75
end, function(object)
    CreateThread(function()
        local playerPed = PlayerPedId()

        -- Positionner le joueur devant le props si nécessaire
        local objCoords = GetEntityCoords(object)
        local objHeading = GetEntityHeading(object)
        local pedCoords = GetEntityCoords(playerPed)
        local dist = #(pedCoords - objCoords)

        if dist > 1.5 then
            local rad = math.rad(objHeading)
            local standX = objCoords.x + math.sin(rad) * 1.0
            local standY = objCoords.y - math.cos(rad) * 1.0
            SetEntityCoords(playerPed, standX, standY, objCoords.z, false, false, false, false)
            SetEntityHeading(playerPed, objHeading % 360.0)
        else
            local pedHeading = GetEntityHeading(playerPed)
            local headingDiff = math.abs(pedHeading - (objHeading % 360.0))
            if headingDiff > 30.0 and headingDiff < 330.0 then
                SetEntityHeading(playerPed, objHeading % 360.0)
            end
        end

        FreezeEntityPosition(playerPed, true)

        RequestAnimDict(PICKUP_ANIM.dict)
        while not HasAnimDictLoaded(PICKUP_ANIM.dict) do Wait(10) end

        TaskPlayAnim(playerPed, PICKUP_ANIM.dict, PICKUP_ANIM.name, 8.0, -8.0, 1500, 49, 0, false, false, false)
        Wait(1200)

        FreezeEntityPosition(playerPed, false)

        local netId = ObjToNet(object)
        local success = TriggerServerCallback('jobsPropsMenu:remove', netId)

        if success then
            if DoesEntityExist(object) then DeleteEntity(object) end
            VFW.ShowNotification({ type = 'VERT', content = "Objet ramassé" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de ramasser cet objet" })
        end

        ClearPedTasks(playerPed)
        RemoveAnimDict(PICKUP_ANIM.dict)
    end)
end)

-- ============================================
-- CONTEXT BUTTON - Déplacer (gizmo)
-- ============================================

VFW.ContextAddButton("object", ":wrench: Déplacer l'objet", function(object)
    if not object or not DoesEntityExist(object) then return false end

    local jobProp = Entity(object).state.jobProp
    if not jobProp then return false end

    local playerJob = VFW.PlayerData.job
    if not playerJob or not playerJob.onDuty then return false end
    if playerJob.name ~= jobProp then return false end
    if not CanPlaceProps() then return false end

    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75
end, function(object)
    CreateThread(function()
        local netId = ObjToNet(object)

        NetworkRequestControlOfEntity(object)
        FreezeEntityPosition(object, false)
        SetEntityCollision(object, false, true)

        local data = exports["core"]:useGizmo(object)

        SetEntityCollision(object, true, true)
        SetEntityDynamic(object, false)

        if data and data.handle and DoesEntityExist(data.handle) then
            local pos = GetEntityCoords(object)
            local rot = GetEntityRotation(object)
            TriggerServerEvent('jobsPropsMenu:move', netId,
                { x = pos.x, y = pos.y, z = pos.z },
                { x = rot.x, y = rot.y, z = rot.z }
            )
            VFW.ShowNotification({ type = 'VERT', content = "Objet déplacé" })
        else
            -- Annulé : remettre la position d'origine
            local propData = trackedProps[netId]
            if propData and propData.coords then
                SetEntityCoords(object, propData.coords.x, propData.coords.y, propData.coords.z, false, false, false, false)
                if propData.rot then
                    SetEntityRotation(object, propData.rot.x, propData.rot.y, propData.rot.z, 2, true)
                end
            end
        end
    end)
end)

-- ============================================
-- CONTEXT BUTTONS - Lits hôpital
-- ============================================

local BED_MODEL_01 = GetHashKey("v_diables_hopital_bed01")
local BED_MODEL_02 = GetHashKey("v_diables_hopital_bed02")

local bedModels = {
    [BED_MODEL_01] = true,
    [BED_MODEL_02] = true,
}

local isPushingBed = false

local LIE_ANIM = { dict = "anim@gangops@morgue@table@", name = "body_search" }
local isLying = false

VFW.ContextAddButton("object", ":home: S'allonger", function(object)
    if not object or not DoesEntityExist(object) then return false end
    if not bedModels[GetEntityModel(object)] then return false end
    if isPushingBed or isLying then return false end
    return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(object)) <= 2.5
end, function(object)
    local playerPed = PlayerPedId()
    isLying = true

    RequestAnimDict(LIE_ANIM.dict)
    while not HasAnimDictLoaded(LIE_ANIM.dict) do Wait(10) end

    AttachEntityToEntity(playerPed, object, 0, 0.0, 0.0, 1.5, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
    TaskPlayAnim(playerPed, LIE_ANIM.dict, LIE_ANIM.name, 8.0, 8.0, -1, 69, 1, false, false, false)

    CreateThread(function()
        while isLying do
            Wait(5)

            if IsPedDeadOrDying(playerPed) then
                isLying = false
                break
            end

            VFW.ShowHelpNotification("Appuyez sur ~INPUT_VEH_DUCK~ pour se lever")
            if IsControlJustPressed(0, 73) then -- X
                isLying = false
                break
            end
        end

        DetachEntity(playerPed, true, true)
        ClearPedTasks(playerPed)
        RemoveAnimDict(LIE_ANIM.dict)
    end)
end)

local PUSH_BED_ANIM = { dict = "anim@heists@box_carry@", name = "idle" }

VFW.ContextAddButton("object", ":car: Pousser le lit", function(object)
    if not object or not DoesEntityExist(object) then return false end
    if not bedModels[GetEntityModel(object)] then return false end
    if isPushingBed then return false end
    return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(object)) <= 2.5
end, function(object)
    isPushingBed = true
    local playerPed = PlayerPedId()

    NetworkRequestControlOfEntity(object)
    RequestAnimDict(PUSH_BED_ANIM.dict)
    while not HasAnimDictLoaded(PUSH_BED_ANIM.dict) do Wait(10) end

    -- Positionner le joueur derrière le lit
    FreezeEntityPosition(playerPed, true)
    local bedCoords = GetEntityCoords(object)
    local bedHeading = GetEntityHeading(object)
    local rad = math.rad(bedHeading)
    local behindX = bedCoords.x - math.sin(rad) * 1.8
    local behindY = bedCoords.y + math.cos(rad) * 1.8
    local _, groundZ = GetGroundZFor_3dCoord(behindX, behindY, bedCoords.z + 2.0, false)
    SetEntityCoords(playerPed, behindX, behindY, groundZ, false, false, false, false)
    SetEntityHeading(playerPed, bedHeading + 180.0)
    Wait(100)

    TaskPlayAnim(playerPed, PUSH_BED_ANIM.dict, PUSH_BED_ANIM.name, 2.0, 2.0, -1, 50, 0, false, false, false)
    Wait(300)

    FreezeEntityPosition(object, false)
    AttachEntityToEntity(object, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, -1.1, -0.9, 195.0, 180.0, 180.0, false, false, true, false, 2, true)
    FreezeEntityPosition(playerPed, false)

    while isPushingBed and IsEntityAttachedToEntity(object, playerPed) do
        Wait(5)
        DisableControlAction(0, 22, true)  -- jump
        DisableControlAction(0, 24, true)  -- attack
        DisableControlAction(0, 25, true)  -- aim
        DisableControlAction(0, 140, true) -- melee light
        DisableControlAction(0, 141, true) -- melee heavy

        if not IsEntityPlayingAnim(playerPed, PUSH_BED_ANIM.dict, PUSH_BED_ANIM.name, 3) then
            TaskPlayAnim(playerPed, PUSH_BED_ANIM.dict, PUSH_BED_ANIM.name, 2.0, 2.0, -1, 50, 0, false, false, false)
        end

        if IsPedDeadOrDying(playerPed) then
            DetachEntity(object, true, true)
        end

        VFW.ShowHelpNotification("Appuyez sur ~INPUT_VEH_DUCK~ pour poser le lit")
        if IsControlJustPressed(0, 73) then -- X
            DetachEntity(object, true, true)
        end
    end

    isPushingBed = false
    StopAnimTask(playerPed, PUSH_BED_ANIM.dict, PUSH_BED_ANIM.name, 1.0)
    ClearPedTasks(playerPed)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
end)

-- ============================================
-- COMMAND FOR CROSS-RESOURCE ACCESS
-- ============================================

RegisterCommand("openJobPropsMenu", function()
    OpenPropsMenu()
end, false)

-- ============================================
-- REGISTER IN JOB MENU (Society menu / F6)
-- ============================================

local propsMenuRegisteredJobs = {}

-- Les jobs police ont déjà un bouton Objets dans leur sous-menu Outils (police/menu.lua)
local POLICE_JOBS = PoliceJobsList

local function RegisterPropsMenuForJob(jobName)
    if propsMenuRegisteredJobs[jobName] then return end
    if POLICE_JOBS[jobName] then return end
    propsMenuRegisteredJobs[jobName] = true

    local registry = exports["core"]:getJobMenuRegistry()
    if not registry then return end

    registry.register(jobName, function(menu)
        local propsList = GetPropsForJob(jobName)
        if not propsList or #propsList == 0 then return end

        local custom = Society.data and Society.data.custom
        local desc = (custom and custom.propsMenuDesc and custom.propsMenuDesc ~= "") and custom.propsMenuDesc or "Placer ou gérer les objets métier"

       menu.Button("Objets", desc, nil, "chevron", false, function()
            menu.close()
            OpenPropsMenu()
        end)
    end)
end

CreateThread(function()
    Wait(500)

    for jobName, _ in pairs(VFW.JobsPropsMenu.registered) do
        RegisterPropsMenuForJob(jobName)
    end
end)

-- Enregistrer dynamiquement quand la société a des props custom
RegisterNetEvent("core:retrieve:societyData", function(data)
    if not data or not data.custom then return end
    if data.custom.props and #data.custom.props > 0 then
        RegisterPropsMenuForJob(data.name)
    end
end)
