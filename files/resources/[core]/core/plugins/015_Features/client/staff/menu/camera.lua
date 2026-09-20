---@meta _
---@diagnostic disable: duplicate-doc-field

--- RotationToDirection
---@param rotation any
---@return any
local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }

    return direction
end

---Get CameraDestination
---@param cam any
---@return table
local function GetCameraDestination(cam)
    local cameraRotation = GetCamRot(cam)
    local cameraCoord = GetCamCoord(cam)
    local direction = RotationToDirection(cameraRotation)

    return {
        x = cameraCoord.x + direction.x * 5.0,
        y = cameraCoord.y + direction.y * 5.0,
        z = cameraCoord.z + direction.z * 5.0
    }
end

CameraSettingsCopy = {
    camera = nil,
    Fov = 45.0,
    Dof = false,
    Freeze = false,
    DofStrength = 0.0
}
local cameraSettingsTemp = {
    freeze = false,
    insideCam = false
}
local list = {
    indexFlou = 1,
    indexTransition = 1,
    indexEffet = 1,
    indexAmplitude = 1,
    indexFOV = 1,
    indexCamEffet = 1,
    valueFlou = {"0.0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"},
    valueTransition = {"0.0", "0.5", "1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0", "4.5", "5.0", "10.0", "15.0", "20.0", "30.0", "40.0", "50.0", "60.0"},
    valueEffet = {"Aucun", "DEATH_FAIL_IN_EFFECT_SHAKE", "DRUNK_SHAKE", "FAMILY5_DRUG_TRIP_SHAKE", "HAND_SHAKE", "JOLT_SHAKE", "LARGE_EXPLOSION_SHAKE", "MEDIUM_EXPLOSION_SHAKE", "SMALL_EXPLOSION_SHAKE", "ROAD_VIBRATION_SHAKE", "SKY_DIVING_SHAKE", "VIBRATE_SHAKE"},
    valueamPlitude = {"0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"},
    valueFov = {"1","2","3","4","5","6","7","8", "9", "10", "20", "30", "40", "50", "60", "70", "80", "90"},
    valueCamEffet = {"0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"},
}

--- .BuildCameraMenu
function StaffMenu.BuildCameraMenu()
    StaffMenu.camera.Button(":report: COLLER UNE CONFIGURATION CAMÉRA", "Coller une configuration JSON copiée pour restaurer une vue caméra", nil, "chevron", false, function()
        local copy = VFW.Nui.KeyboardInput(true,"Copier la configuration de la caméra")

        if copy and copy:len() > 0 then
            local data = json.decode(copy)

            CameraSettingsCopy = data

            local pedCoords = GetEntityCoords(VFW.PlayerData.ped)
            local camRot = CameraSettingsCopy.CamRot
            local camCoord = CameraSettingsCopy.CamCoords
            local coh = CameraSettingsCopy.COH
            local fov = CameraSettingsCopy.Fov
            local dof = CameraSettingsCopy.Dof
            local transition = CameraSettingsCopy.Transition
            local dofStrength = CameraSettingsCopy.DofStrength or 1.0

            SetEntityVisible(VFW.PlayerData.ped, CameraSettingsCopy.Invisible == false and false or true)
            SetEntityCoords(VFW.PlayerData.ped, coh.x, coh.y, coh.z - 0.9)
            SetEntityHeading(VFW.PlayerData.ped, coh.w)

            if CameraSettingsCopy.Animation then
                RequestAnimDict(CameraSettingsCopy.Animation.dict)
                local timer = 1

                while (not HasAnimDictLoaded(CameraSettingsCopy.Animation.dict)) and timer < 200 do
                    Wait(0)
                    timer += 1
                end

                TaskPlayAnim(VFW.PlayerData.ped, CameraSettingsCopy.Animation.dict, CameraSettingsCopy.Animation.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
                RemoveAnimDict(CameraSettingsCopy.Animation.dict)
            end

            local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camCoord.x, camCoord.y, camCoord.z, camRot.x, camRot.y, camRot.z, fov, true, 0)

            SetCamActive(cam, true)
            SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
            SetCamFov(cam, fov)
            SetCamUseShallowDofMode(cam, true) -- Sets the camera to use shallow dof mode
            SetCamNearDof(cam, 0.6) -- Sets the camera's near dof to the value set in the config file
            SetCamFarDof(cam, 4.0) -- Sets the camera's far dof to the value set in the config file
            SetCamDofStrength(cam, dofStrength)

            CreateThread(function()
                while DoesCamExist(cam) do
                    Wait(0)

                    if IsControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 194) then
                        SetCamActive(cam, false)
                        ClearPedTasks(VFW.PlayerData.ped)
                        DestroyCam(cam)
                        RenderScriptCams(false, false, 0, true, true)
                    end

                    SetUseHiDof()
                end
            end)

            RenderScriptCams(true, (transition and true or false), math.floor((transition and transition*1000 or 0)))
        end
    end)

    StaffMenu.camera.Separator("CRÉATION DE CAMÉRA")

    StaffMenu.camera.Checkbox("PERSONNAGE INVISIBLE", "Rendre votre personnage invisible pour une prise de vue propre", false, CameraSettingsCopy.Invisible, function(_checked)
        CameraSettingsCopy.Invisible = _checked
        SetEntityVisible(VFW.PlayerData.ped, not _checked)
    end)

    StaffMenu.camera.Checkbox("ACTIVER LE FLOU", "Activer l'effet de profondeur de champ (DoF) sur la caméra", false, CameraSettingsCopy.Dof, function(_checked)
        CameraSettingsCopy.Dof = _checked
    end)

    StaffMenu.camera.Checkbox("FREEZE LA CAMÉRA", "Figer la caméra à sa position actuelle pour une prise de vue fixe", false, cameraSettingsTemp.freeze, function(_checked)
        cameraSettingsTemp.freeze = _checked
        AdminFreecam.SetFreecamFrozen(_checked)
    end)

    StaffMenu.camera.List("INTENSITÉ DE FLOU", "Régler la force de l'effet de profondeur de champ (0.0 = désactivé)", false, list.valueFlou, list.indexFlou, function(index, item)
        list.indexFlou = index
        if tonumber(list.valueFlou[list.indexFlou]) ~= 0 then
            SetCamUseShallowDofMode(AdminFreecam._internal_camera, true) -- Sets the camera to use shallow dof mode
            SetCamNearDof(AdminFreecam._internal_camera, 0.6) -- Sets the camera's near dof to the value set in the config file
            SetCamFarDof(AdminFreecam._internal_camera, 4.0) -- Sets the camera's far dof to the value set in the config file
            SetCamDofStrength(AdminFreecam._internal_camera, (tonumber(list.valueFlou[list.indexFlou])))
            CameraSettingsCopy.DofStrength = (tonumber(list.valueFlou[list.indexFlou]))
        else
            SetCamUseShallowDofMode(AdminFreecam._internal_camera, false)
        end
    end)

    StaffMenu.camera.List("TRANSITION EN SECONDES", "Durée de la transition lors de l'activation de la caméra (0 = instantané)", false, list.valueTransition, list.indexTransition, function(index, item)
        list.indexTransition = index
        CameraSettingsCopy.Transition = (tonumber(list.valueTransition[list.indexTransition]))
    end)

    StaffMenu.camera.List("EFFETS CAMÉRA", "Appliquer un effet de tremblement ou de vibration à la caméra", false, list.valueEffet, list.indexEffet, function(index, item)
        list.indexEffet = index
        if list.indexEffet == 1 then
            ShakeCam(AdminFreecam._internal_camera, "DRUNK_SHAKE", 0.0)
            CameraSettingsCopy.CamEffects = nil
        else
            ShakeCam(AdminFreecam._internal_camera, list.valueEffet[list.indexEffet], CameraSettingsCopy.CamEffectsAmplitude or 0.5)
            CameraSettingsCopy.CamEffects = list.valueEffet[list.indexEffet]
        end
    end)

    StaffMenu.camera.List("AMPLITUDE DES EFFETS", "Régler l'intensité de l'effet de tremblement sélectionné", false, list.valueCamEffet, list.indexCamEffet, function(index, item)
        list.indexCamEffet = index
        if CameraSettingsCopy.CamEffects then
            ShakeCam(AdminFreecam._internal_camera, CameraSettingsCopy.CamEffects, tonumber(list.valueCamEffet[list.indexCamEffet]))
        end

        CameraSettingsCopy.CamEffectsAmplitude = tonumber(list.valueCamEffet[list.indexCamEffet])
    end)

    StaffMenu.camera.List("FOV", "Régler le champ de vision de la caméra (plus petit = plus zoomé)", false, list.valueFov, list.indexFOV, function(index, item)
        list.indexFOV = index
        SetCamFov(AdminFreecam._internal_camera, tonumber(list.valueFov[list.indexFOV] + 0.1))
        CameraSettingsCopy.Fov = tonumber(list.valueFov[list.indexFOV] + 0.1)
    end)

    StaffMenu.camera.Checkbox("PRÉVISUALISATION LA CAMÉRA", "Activer la freecam pour prévisualiser le rendu de la configuration", false, cameraSettingsTemp.insideCam, function(_checked)
        cameraSettingsTemp.insideCam = _checked
        AdminFreecam.SetFreecamActive(cameraSettingsTemp.insideCam)
    end)

    StaffMenu.camera.Button(":report: COPIER LA CONFIGURATION CAMÉRA", "Copier la configuration actuelle de la caméra dans le presse-papier", nil, "chevron", false, function()
        local pedCoords = GetEntityCoords(VFW.PlayerData.ped)

        CameraSettingsCopy.CamRot = GetCamRot(AdminFreecam._internal_camera)
        CameraSettingsCopy.CamCoords = GetCamCoord(AdminFreecam._internal_camera)
        CameraSettingsCopy.OffsetPlayer = GetOffsetFromEntityGivenWorldCoords(VFW.PlayerData.ped, CameraSettingsCopy.CamCoords.x, CameraSettingsCopy.CamCoords.y, CameraSettingsCopy.CamCoords.z)

        local destination = GetCameraDestination(AdminFreecam._internal_camera)

        CameraSettingsCopy.OffsetLook = GetOffsetFromEntityGivenWorldCoords(VFW.PlayerData.ped, destination.x, destination.y, destination.z)
        CameraSettingsCopy.COH = vector4(pedCoords.x, pedCoords.y, pedCoords.z, GetEntityHeading(VFW.PlayerData.ped))

        if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
            local coords = GetEntityCoords(GetVehiclePedIsIn(VFW.PlayerData.ped, false))

            CameraSettingsCopy.COH = vector4(coords.x, coords.y, coords.z, GetEntityHeading(GetVehiclePedIsIn(VFW.PlayerData.ped, false)))
            CameraSettingsCopy.Vehicle = GetEntityModel(GetVehiclePedIsIn(VFW.PlayerData.ped, false))
        end

        local animationData = VFW.GetPedAnimationIsPlaying()

        if animationData then
            CameraSettingsCopy.Animation = { anim = animationData[2], dict = animationData[1] }
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode Caméra',
            message = "Configuration de la camera copiee dans votre presse-papier."
      })

        VFW.Clipboard(json.encode(CameraSettingsCopy))
    end)
end
