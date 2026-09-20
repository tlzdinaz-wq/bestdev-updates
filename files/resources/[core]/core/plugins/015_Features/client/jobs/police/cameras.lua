---@meta _
---@diagnostic disable: duplicate-doc-field

local DEFAULT_CAMERA_PROP = "prop_cctv_cam_01a"
local MAX_CAMERAS = 15

local function getPlayerZone()
    local job = VFW.PlayerData and VFW.PlayerData.job
    if not job then return nil end
    if job.name == "cayomilice" then return "cayo" end
    return nil
end

local function camMatchesPlayerZone(cam)
    local camZone = cam.zone
    if camZone == "" then camZone = nil end
    return camZone == getPlayerZone()
end

local localCamerasData    = {}  -- [id] = { id, placed_by, job, x, y, z, rx, ry, rz, created_at, street, zone }
local localCameraEntities = {}  -- [id] = entityHandle
local cameraViewActive    = false

-- Cooldown pour éviter le spam sur getCameras
local lastCamerasRefresh  = 0
local CAMERAS_COOLDOWN    = 1000 -- ms

-- ID unique pour les instructionalButtons
local cameraButtonId = generateUniqueID(8)

-- ============================================================
-- Helpers
-- ============================================================

local function decodeData(data)
    if type(data) == "string" and (string.sub(data, 1, 1) == "{" or string.sub(data, 1, 1) == "[") then
        local ok, decoded = pcall(json.decode, data)
        if ok then return decoded end
    end
    return data
end

local function getPoliceImg()
    return VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png")
end

local function policeNotif(subtitle, message)
    VFW.ShowNotification({
        type    = "JOB",
        title   = VFW.PlayerData.job.label or "SASP",
        subtitle = subtitle,
        image   = getPoliceImg(),
        content = message
    })
end

-- Calcule et met en cache la rue d'une caméra (appelé une seule fois par caméra)
local function cacheStreet(cam)
    if cam.street then return end
    local streetHash = GetStreetNameAtCoord(cam.x, cam.y, cam.z)
    cam.street = GetStreetNameFromHashKey(streetHash) or "Inconnu"
end

-- ============================================================
-- Spawn / Delete d'entités locales
-- ============================================================

local function SpawnCameraEntity(cam)
    -- Supprimer l'ancienne entité si elle existe déjà
    if localCameraEntities[cam.id] and DoesEntityExist(localCameraEntities[cam.id]) then
        DeleteEntity(localCameraEntities[cam.id])
        localCameraEntities[cam.id] = nil
    end

    local propModel = cam.prop_model or DEFAULT_CAMERA_PROP
    local modelHash = GetHashKey(propModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 150 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    -- Guard : la caméra a peut-être été supprimée pendant le chargement du modèle
    if not localCamerasData[cam.id] then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local entity = CreateObject(modelHash, cam.x, cam.y, cam.z, false, false, false)
    SetEntityRotation(entity, cam.rx, cam.ry, cam.rz, 2, false)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    localCameraEntities[cam.id] = entity

    -- Calculer la rue maintenant que l'entité est là (appel natif pas cher à ce stade)
    cacheStreet(localCamerasData[cam.id])
end

local function RemoveCameraEntity(camId)
    if localCameraEntities[camId] and DoesEntityExist(localCameraEntities[camId]) then
        DeleteEntity(localCameraEntities[camId])
    end
    localCameraEntities[camId] = nil
    localCamerasData[camId]    = nil
end

-- ============================================================
-- Chargement initial
-- ============================================================

AddEventHandler("onClientResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(3000, function()
        local cameras = TriggerServerCallback("police:getAllCameras")
        for _, cam in ipairs(cameras or {}) do
            localCamerasData[cam.id] = cam
            CreateThread(function() SpawnCameraEntity(cam) end)
        end
    end)
end)

-- ============================================================
-- Events serveur → client
-- ============================================================

RegisterNetEvent("police:cameras:spawn")
AddEventHandler("police:cameras:spawn", function(cam)
    localCamerasData[cam.id] = cam
    CreateThread(function() SpawnCameraEntity(cam) end)
end)

RegisterNetEvent("police:cameras:remove")
AddEventHandler("police:cameras:remove", function(camId)
    RemoveCameraEntity(camId)
end)

-- ============================================================
-- Placement de caméra (depuis menu Outils)
-- ============================================================

function PlacePoliceCameraAction(propModel)
    propModel = propModel or DEFAULT_CAMERA_PROP

    CreateThread(function()
        -- Vérification limite côté serveur
        local count = TriggerServerCallback("police:getCameraCount")
        if count >= MAX_CAMERAS then
            policeNotif("Caméras", "Limite de " .. MAX_CAMERAS .. " caméras atteinte")
            return
        end

        -- Chargement du modèle
        local modelHash = GetHashKey(propModel)
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 150 do
            Wait(10)
            timeout = timeout + 1
        end
        if not HasModelLoaded(modelHash) then
            policeNotif("Caméras", "Impossible de charger le modèle")
            return
        end

        local ped     = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local prop    = VFW.OneSync.CreateObject(modelHash, vector3(pCoords.x, pCoords.y, pCoords.z + 1.5))
        SetModelAsNoLongerNeeded(modelHash)

        FreezeEntityPosition(prop, true)
        SetEntityCollision(prop, false, true)
        SetEntityAlpha(prop, 150, false)

        local currentHeading = 0.0
        local confirmed = false

        while true do
            -- Mode placement normal
            local placing = true
            local useGizmo = false

            instructionalButtons[cameraButtonId] = {
                { label = "Poser la caméra", control = 38 },
                { label = "Tourner",         control = 241 },
                { label = "Mode Gizmo",      control = 47 },
                { label = "Annuler",         control = 200 },
            }

            while placing do
                Wait(10)

                if not DoesEntityExist(prop) then
                    instructionalButtons[cameraButtonId] = nil
                    return
                end

                local fwd       = GetEntityForwardVector(ped)
                local targetPos = GetEntityCoords(ped) + fwd * 2.0
                SetEntityCoords(prop, targetPos.x, targetPos.y, targetPos.z + 1.5, false, false, false, false)
                SetEntityHeading(prop, currentHeading)

                DisableControlAction(0, 15, true)
                DisableControlAction(0, 16, true)
                if IsDisabledControlJustPressed(0, 15) then currentHeading = currentHeading + 15.0 end
                if IsDisabledControlJustPressed(0, 16) then currentHeading = currentHeading - 15.0 end

                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisablePlayerFiring(ped, true)

                if VFW.Interact.JustPressed(0, 38) then      -- E = poser
                    placing = false
                    confirmed = true
                elseif IsControlJustPressed(0, 47) then  -- G = gizmo
                    placing  = false
                    useGizmo = true
                elseif IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then -- Echap / Suppr
                    instructionalButtons[cameraButtonId] = nil
                    if DoesEntityExist(prop) then DeleteEntity(prop) end
                    return
                end
            end

            instructionalButtons[cameraButtonId] = nil

            if confirmed then
                break
            end

            if useGizmo then
                local ok, gizmoData = pcall(function() return exports["core"]:useGizmo(prop) end)
                if not ok or not gizmoData or not gizmoData.handle or not DoesEntityExist(gizmoData.handle) then
                    if DoesEntityExist(prop) then DeleteEntity(prop) end
                    policeNotif("Caméras", "Placement annulé.")
                    return
                end
                -- Backspace = retour au mode placement
                if gizmoData.switchedBack then
                    -- Continue la boucle → retour au mode placement
                else
                    -- Entrée dans le gizmo = validé
                    confirmed = true
                    break
                end
            end
        end

        -- Vérifier que le prop existe encore avant de lire ses coords
        if not DoesEntityExist(prop) then
            policeNotif("Caméras", "Placement annulé")
            return
        end

        local pos = GetEntityCoords(prop)
        local rot = GetEntityRotation(prop, 2)

        local camName = VFW.Nui.KeyboardInput(true, "Nom de la caméra (ex: Parking Sud)") or ""

        local zoneChoice = VFW.Nui.ChoiceInput("Zone de la caméra", "Sélectionnez la zone", {
            { label = "Los Santos", value = "" },
            { label = "Cayo Perico", value = "cayo" },
        })
        local camZone = zoneChoice or ""

        local result = TriggerServerCallback("police:placeCamera", {
            x  = pos.x, y  = pos.y, z  = pos.z,
            rx = rot.x, ry = rot.y, rz = rot.z,
            prop_model = propModel,
            name       = camName,
            zone       = camZone,
        })

        if DoesEntityExist(prop) then DeleteEntity(prop) end

        if result and result.success then
            policeNotif("Caméras", "Caméra posée")
        else
            policeNotif("Caméras", result and result.message or "Erreur lors du placement")
        end
    end)
end

-- ============================================================
-- Vue caméra (appelée depuis NUI watchCamera)
-- ============================================================

local function WatchPoliceCamera(cam)
    if cameraViewActive then return end
    cameraViewActive = true

    local ped  = PlayerPedId()
    local cam3d = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    -- Cleanup garanti même en cas d'erreur dans la boucle
    local hiddenProp = nil

    local function cleanup()
        cameraViewActive = false
        FreezeEntityPosition(ped, false)
        RenderScriptCams(false, false, 0, true, true)
        if DoesCamExist(cam3d) then DestroyCam(cam3d, false) end
        instructionalButtons[cameraButtonId] = nil
        -- Restaurer la visibilité du prop
        if hiddenProp and hiddenProp ~= 0 and DoesEntityExist(hiddenProp) then
            ResetEntityAlpha(hiddenProp)
        end
        -- Restaurer le focus sur le joueur
        ClearFocus()
        -- Restaurer le HUD, la minimap et le HUD voix
        SendNUIMessage({ action = 'nui:StatusHUD:visible', data = true })
        SendNUIMessage({ action = 'nui:hud:visible', data = true })
        DisplayRadar(true)
        TriggerEvent("pma-voice:toggleUi", true)
    end

    -- Cacher le HUD, la minimap et le HUD voix pendant la vue caméra
    SendNUIMessage({ action = 'nui:StatusHUD:visible', data = false })
    SendNUIMessage({ action = 'nui:hud:visible', data = false })
    DisplayRadar(false)
    TriggerEvent("pma-voice:toggleUi", false)
    instructionalButtons[cameraButtonId] = {
        { label = "Orienter", control = 1 },
        { label = "Zoom",     control = 241 },
        { label = "Quitter",  control = 38 },
    }

    -- Décaler la caméra vers l'objectif pour sortir du corps du prop
    local LENS = 1.0
    local rx_r = math.rad(cam.rx)
    local rz_r = math.rad(cam.rz)
    local lensX = cam.x + (-math.sin(rz_r) * math.cos(rx_r)) * LENS
    local lensY = cam.y + ( math.cos(rz_r) * math.cos(rx_r)) * LENS
    local lensZ = cam.z + ( math.sin(rx_r))                   * LENS

    -- Forcer le chargement du monde autour de la camera distante
    SetFocusPosAndVel(lensX, lensY, lensZ, 0.0, 0.0, 0.0)

    -- Attendre que la scene soit chargee
    NewLoadSceneStart(lensX, lensY, lensZ, lensX, lensY, lensZ, 200.0, 0)
    local loadTimeout = 0
    while not IsNewLoadSceneLoaded() and loadTimeout < 200 do
        RequestCollisionAtCoord(lensX, lensY, lensZ)
        Wait(10)
        loadTimeout = loadTimeout + 1
    end
    NewLoadSceneStop()

    SetCamCoord(cam3d, lensX, lensY, lensZ)
    SetCamFov(cam3d, 65.0)
    SetCamNearClip(cam3d, 0.5)
    RenderScriptCams(true, false, 0, true, true)
    FreezeEntityPosition(ped, true)

    -- Cacher le prop de la caméra pendant la vue
    local camProp = GetClosestObjectOfType(cam.x, cam.y, cam.z, 1.5, GetHashKey(cam.prop_model or "prop_cctv_cam_01a"), false, false, false)
    if camProp and camProp ~= 0 then
        SetEntityAlpha(camProp, 0, false)
        hiddenProp = camProp
    end

    local currentPitch = cam.rx
    local currentYaw   = cam.rz
    local currentFov   = 65.0

    SetCamRot(cam3d, currentPitch, 0.0, currentYaw, 2)

    local ok = pcall(function()
        while cameraViewActive do
            Wait(5) -- 200fps max, largement suffisant pour la souris

            -- Bloquer tous les contrôles du joueur
            DisableAllControlActions(0)

            local mouseX = GetDisabledControlNormal(0, 1)  -- LOOK_LR
            local mouseY = GetDisabledControlNormal(0, 2)  -- LOOK_UD

            currentYaw   = currentYaw   - mouseX * 30.0
            currentPitch = currentPitch + mouseY * 15.0

            if currentPitch >  80.0 then currentPitch =  80.0 end
            if currentPitch < -80.0 then currentPitch = -80.0 end

            -- Zoom molette (FOV 20° → 90°)
            if IsDisabledControlJustPressed(0, 15) then
                currentFov = math.max(20.0, currentFov - 5.0)
                SetCamFov(cam3d, currentFov)
            end
            if IsDisabledControlJustPressed(0, 16) then
                currentFov = math.min(90.0, currentFov + 5.0)
                SetCamFov(cam3d, currentFov)
            end

            SetCamRot(cam3d, currentPitch, 0.0, currentYaw, 2)

            if IsDisabledControlJustPressed(0, 38) then -- E = quitter
                cameraViewActive = false
            end
        end
    end)

    cleanup()

    if not ok then
        -- Erreur silencieuse : le cleanup a quand même été exécuté
    end
end

-- ============================================================
-- NUI Callbacks
-- ============================================================

RegisterNuiCallback("police:getCameras", function(_, cb)
    local now = GetGameTimer()
    if now - lastCamerasRefresh < CAMERAS_COOLDOWN then
        local cached = {}
        for _, cam in pairs(localCamerasData) do
            if camMatchesPlayerZone(cam) then
                table.insert(cached, {
                    id         = cam.id,
                    name       = cam.name,
                    street     = cam.street or "Inconnu",
                    placed_by  = cam.placed_by,
                    job        = cam.job,
                    zone       = cam.zone,
                    created_at = cam.created_at,
                    prop_model = cam.prop_model or DEFAULT_CAMERA_PROP,
                    x = cam.x, y = cam.y, z = cam.z,
                })
            end
        end
        table.sort(cached, function(a, b) return a.id > b.id end)
        cb(cached)
        return
    end
    lastCamerasRefresh = now

    pcall(function()
        local list = {}
        for _, cam in pairs(localCamerasData) do
            if camMatchesPlayerZone(cam) then
                cacheStreet(cam)
                table.insert(list, {
                    id         = cam.id,
                    name       = cam.name,
                    street     = cam.street,
                    placed_by  = cam.placed_by,
                    job        = cam.job,
                    zone       = cam.zone,
                    created_at = cam.created_at,
                    prop_model = cam.prop_model or DEFAULT_CAMERA_PROP,
                    x = cam.x, y = cam.y, z = cam.z,
                })
            end
        end
        table.sort(list, function(a, b) return a.id > b.id end)
        cb(list)
    end)
end)

RegisterNuiCallback("police:deleteCamera", function(data, cb)
    local ok, response = pcall(function()
        data = decodeData(data)
        return TriggerServerCallback("police:deleteCamera", data)
    end)
    if ok then
        cb(response or { success = false })
    else
        cb({ success = false, message = "Erreur interne" })
    end
end)

RegisterNuiCallback("police:watchCamera", function(data, cb)
    data = decodeData(data)
    local camId = data and data.id
    local cam   = camId and localCamerasData[camId]

    if not cam then
        cb({ success = false, message = "Caméra introuvable" })
        return
    end

    if not camMatchesPlayerZone(cam) then
        cb({ success = false, message = "Caméra hors de votre juridiction" })
        return
    end

    VFW.Nui.Focus(false)
    SendNUIMessage({ action = "nui:PolicePanel:minimized", data = {} })
    SendNUIMessage({ action = "nui:PolicePanel:cameraOverlay", data = {
        id     = cam.id,
        street = cam.street or "Inconnu",
        job    = cam.job or "lspd",
    }})

    cb({ success = true })

    CreateThread(function()
        Wait(150)
        WatchPoliceCamera(cam)

        Wait(100)
        SendNUIMessage({ action = "nui:PolicePanel:cameraOverlay" })
        VFW.Nui.Focus(true)
        SendNUIMessage({ action = "nui:PolicePanel:restore", data = {} })
    end)
end)

-- ============================================================
-- Nettoyage à l'arrêt de la resource
-- ============================================================

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Forcer la sortie de la vue caméra si active
    if cameraViewActive then
        cameraViewActive = false
        FreezeEntityPosition(PlayerPedId(), false)
        RenderScriptCams(false, false, 0, true, true)
        ClearFocus()
        instructionalButtons[cameraButtonId] = nil
        SendNUIMessage({ action = 'nui:StatusHUD:visible', data = true })
        SendNUIMessage({ action = 'nui:hud:visible', data = true })
        DisplayRadar(true)
        TriggerEvent("pma-voice:toggleUi", true)
        SendNUIMessage({ action = "nui:PolicePanel:cameraOverlay" })
        SendNUIMessage({ action = "nui:PolicePanel:restore", data = {} })
    end

    -- Supprimer les entités de caméras placées
    for id, entity in pairs(localCameraEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    localCameraEntities = {}
end)

-- ============================================================
-- API globale pour le builder VUI (cameras_builder.lua)
-- ============================================================

PoliceCameras = {
    data          = localCamerasData,
    entities      = localCameraEntities,
    MAX           = MAX_CAMERAS,
    cacheStreet   = cacheStreet,
    policeNotif   = policeNotif,
    spawn         = SpawnCameraEntity,
    remove        = RemoveCameraEntity,
    watch         = WatchPoliceCamera,
}
