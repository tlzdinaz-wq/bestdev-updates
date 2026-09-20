---@meta _
---@diagnostic disable: duplicate-doc-field

-- Available camera prop models
local CAMERA_MODELS = {
    { model = "prop_cctv_cam_01a", label = "CCTV Standard",      desc = "Caméra extérieure classique" },
    { model = "prop_cctv_cam_02a", label = "CCTV Dôme",          desc = "Caméra dôme murale" },
    { model = "prop_cs_cctv",      label = "CCTV Intérieure",    desc = "Caméra intérieure compacte" },
    { model = "prop_cctv_02_sm",   label = "CCTV Mini",          desc = "Petite caméra discrète" },
    { model = "hei_prop_bank_cctv_01", label = "Banque CCTV",    desc = "Caméra sécurité bancaire" },
    { model = "hei_prop_bank_cctv_02", label = "Banque CCTV v2", desc = "Caméra bancaire variante" },
}

-- State for editing
StaffMenu._editingCamera = nil

-- Helper to find model display label
local function getModelLabel(model)
    for _, m in ipairs(CAMERA_MODELS) do
        if m.model == model then return m.label end
    end
    return model
end

-- ============================================================
-- Main Camera Builder Menu
-- ============================================================

function StaffMenu.BuildCamerasMenu()
    StaffMenu.builderCameras.ClearItems()

    StaffMenu.builderCameras.Separator("POSER UNE CAMÉRA")

    for _, cam in ipairs(CAMERA_MODELS) do
        StaffMenu.builderCameras.Button(
            cam.label,
            cam.desc .. " (" .. cam.model .. ")",
            nil, "chevron", false,
            function()
                StaffMenu.builderCameras.close()
                CreateThread(function()
                    Wait(150)
                    PlacePoliceCameraAction(cam.model)
                end)
            end
        )
    end

    StaffMenu.builderCameras.Separator("GÉRER LES CAMÉRAS")

    -- Fetch cameras from local data via global API
    local camData = PoliceCameras.data
    local cameras = {}
    for _, cam in pairs(camData) do
        PoliceCameras.cacheStreet(cam)
        table.insert(cameras, cam)
    end
    table.sort(cameras, function(a, b) return a.id > b.id end)

    if #cameras == 0 then
        StaffMenu.builderCameras.Button("Aucune caméra", "Aucune caméra posée actuellement", nil, nil, true, function() end)
    else
        StaffMenu.builderCameras.Button(
            #cameras .. " caméra" .. (#cameras > 1 and "s" or "") .. " posée" .. (#cameras > 1 and "s" or ""),
            "Limite : " .. PoliceCameras.MAX,
            nil, nil, true,
            function() end
        )

        for _, cam in ipairs(cameras) do
            local street = cam.street or "Inconnu"
          local modelLabel = getModelLabel(cam.prop_model or "prop_cctv_cam_01a")
            local displayName = (cam.name and cam.name ~= "") and cam.name or street

            StaffMenu.builderCameras.Button(
                "#" .. cam.id .. " - " .. displayName,
                modelLabel .. " | " .. street,
                nil, "chevron", false,
                function()
                    StaffMenu._editingCamera = cam
                end,
                StaffMenu.builderCamerasEdit
            )
        end
    end
end

-- ============================================================
-- Camera Edit Submenu
-- ============================================================

function StaffMenu.BuildCamerasEditMenu()
    StaffMenu.builderCamerasEdit.ClearItems()

    local cam = StaffMenu._editingCamera
    if not cam then
        StaffMenu.builderCamerasEdit.Button("Erreur", "Aucune caméra sélectionnée", nil, nil, true, function() end)
        return
    end

    local street = cam.street or "Inconnu"
  local model  = cam.prop_model or "prop_cctv_cam_01a"
  local modelLabel = getModelLabel(model)

    StaffMenu.builderCamerasEdit.Separator("CAMÉRA #" .. cam.id)

    local displayName = (cam.name and cam.name ~= "") and cam.name or "Sans nom"
  StaffMenu.builderCamerasEdit.Button(
        "Nom de la caméra : " .. displayName,
        "Défini lors de la pose",
        nil, nil, true, function() end
    )

    StaffMenu.builderCamerasEdit.Button(
        "Date de pose : " .. (cam.created_at or "Inconnue"),
        "Posée par " .. (cam.placed_by or "Inconnu"),
        nil, nil, true, function() end
    )

    StaffMenu.builderCamerasEdit.Button(
        "Localisation : " .. street,
        string.format("%.1f, %.1f, %.1f", cam.x, cam.y, cam.z),
        nil, nil, true, function() end
    )

    StaffMenu.builderCamerasEdit.Button(
        "Modèle : " .. modelLabel,
        model,
        nil, nil, true, function() end
    )

    StaffMenu.builderCamerasEdit.Separator("ACTIONS")

    -- Teleport to camera
    StaffMenu.builderCamerasEdit.Button(
        "Se téléporter",
        "Se rendre à la position de la caméra",
        nil, "chevron", false,
        function()
            SetEntityCoords(PlayerPedId(), cam.x, cam.y, cam.z - 1.0, false, false, false, false)
            PoliceCameras.policeNotif("Caméras", "Téléporté à la caméra #" .. cam.id)
        end
    )

    -- Watch camera
    StaffMenu.builderCamerasEdit.Button(
        "Voir la caméra",
        "Regarder le flux vidéo de la caméra",
        nil, "chevron", false,
        function()
            StaffMenu.builderCamerasEdit.close()
            CreateThread(function()
                Wait(150)
                PoliceCameras.watch(cam)
                -- Retour à la liste après la vue
                Wait(100)
                StaffMenu.builderCameras.open()
            end)
        end
    )

    -- Change prop model
    StaffMenu.builderCamerasEdit.Separator("CHANGER LE MODÈLE")
    for _, m in ipairs(CAMERA_MODELS) do
        local isCurrent = m.model == model
        StaffMenu.builderCamerasEdit.Button(
            m.label .. (isCurrent and " (actuel)" or ""),
            m.desc,
            isCurrent and "check" or nil,
            isCurrent and nil or "chevron",
            isCurrent,
            function()
                local result = TriggerServerCallback("police:updateCameraModel", {
                    id = cam.id,
                    prop_model = m.model,
                })
                if result and result.success then
                    -- Update local data
                    cam.prop_model = m.model
                    -- Respawn entity with new model
                    PoliceCameras.remove(cam.id)
                    PoliceCameras.data[cam.id] = cam
                    CreateThread(function() PoliceCameras.spawn(cam) end)
                    PoliceCameras.policeNotif("Caméras", "Modèle changé en " .. m.label)
                    StaffMenu.builderCamerasEdit.refresh()
                else
                    PoliceCameras.policeNotif("Caméras", result and result.message or "Erreur")
                end
            end
        )
    end

    -- Delete camera
    StaffMenu.builderCamerasEdit.Separator("DANGER")
    StaffMenu.builderCamerasEdit.Button(
        "Supprimer la caméra",
        "Supprimer définitivement la caméra #" .. cam.id,
        nil, "chevron", false,
        function()
            local camId = cam.id
            local result = TriggerServerCallback("police:deleteCamera", { id = camId })
            if result and result.success then
                -- Local removal immédiat : le broadcast police:cameras:remove est async
                -- et n'a pas forcément été traité quand on rouvre la liste juste après.
                PoliceCameras.remove(camId)
                PoliceCameras.policeNotif("Caméras", "Caméra #" .. camId .. " supprimée")
                StaffMenu._editingCamera = nil
                -- Go back to camera list
                StaffMenu.builderCamerasEdit.close()
                SetTimeout(50, function()
                    StaffMenu.builderCameras.open()
                end)
            else
                PoliceCameras.policeNotif("Caméras", result and result.message or "Erreur lors de la suppression")
            end
        end
    )
end

-- ============================================================
-- Preview live lors du survol des modèles de caméra
-- ============================================================

local camPreviewObj = nil
local camPreviewToken = 0

local function DeleteCameraPreview()
    camPreviewToken = camPreviewToken + 1
    if camPreviewObj and DoesEntityExist(camPreviewObj) then
        DeleteEntity(camPreviewObj)
    end
    camPreviewObj = nil
end

local function SpawnCameraPreview(model)
    DeleteCameraPreview()
    local token = camPreviewToken
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
    VFW.Game.SpawnLocalObject(model, vector3(pos.x, pos.y, pos.z + 1.5), function(obj)
        if obj and DoesEntityExist(obj) then
            if token ~= camPreviewToken then
                DeleteEntity(obj)
                return
            end
            camPreviewObj = obj
            SetEntityAlpha(obj, 150, false)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, true)
        end
    end)
end

-- Index 1 = separator "POSER UNE CAMÉRA", donc les modèles commencent à l'index 2
StaffMenu.builderCameras.OnIndexChange(function(index)
    local camIndex = index - 1
    if camIndex >= 1 and camIndex <= #CAMERA_MODELS then
        CreateThread(function()
            SpawnCameraPreview(CAMERA_MODELS[camIndex].model)
        end)
    else
        DeleteCameraPreview()
    end
end)

StaffMenu.builderCameras.OnClose(function()
    DeleteCameraPreview()
end)
