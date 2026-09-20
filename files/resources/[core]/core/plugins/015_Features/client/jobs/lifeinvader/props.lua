---@meta _
---@diagnostic disable: duplicate-doc-field

local LI_LOGO <const> = VFW.CDN.Get("job/lifeinvader/logo_li.png")

local isHoldingMic = false
local isHoldingBmic = false
local isHoldingCam = false
local micNetwork
local bigMicroNetwork
local camNetwork

local isInCameraFov = false
local cameraActive = false
local isBroadcastingLive = false
local cameraHandle = nil

local micAnimLib = "anim@heists@humane_labs@finale@keycards"
local micAnimName = "ped_a_enter_loop"
local micExtendAnimLib = "missmic4premiere"
local micExtendAnimName = "interview_short_lazlow"
local micModel = "p_mic_lifeinvader_01"
local micBoneNormal = 4154
local micBoneExtend = 28422
local micPlacementNormal = { -0.00, -0.02, 0.11, 0.0, 0.0, 60.0 }
local micPlacementExtend = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }

local function loadModel(model)
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 5000 do Wait(10) t = t + 10 end
    return HasModelLoaded(model)
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 5000 do Wait(10) t = t + 10 end
    return HasAnimDictLoaded(dict)
end

--- Cancel any currently held prop (mic, boom, camera)
local function CancelCurrentProp(except)
    local ped = VFW.PlayerData.ped

    if except ~= "mic" and isHoldingMic then
        ClearPedSecondaryTask(ped)
        if micNetwork then
            TriggerServerEvent("lifeinvader:unregisterProp", micNetwork)
            DeleteEntity(NetToObj(micNetwork))
            micNetwork = nil
        end
        isHoldingMic = false
    end

    if except ~= "bmic" and isHoldingBmic then
        ClearPedSecondaryTask(ped)
        if bigMicroNetwork then
            TriggerServerEvent("lifeinvader:unregisterProp", bigMicroNetwork)
            DeleteEntity(NetToObj(bigMicroNetwork))
            bigMicroNetwork = nil
        end
        isHoldingBmic = false
    end

    if except ~= "cam" and isHoldingCam then
        if cameraActive then
            cameraActive = false
            if DoesCamExist(cameraHandle) then
                DestroyCam(cameraHandle, false)
                RenderScriptCams(false, false, 0, true, true)
                cameraHandle = nil
                ClearTimecycleModifier()
                isInCameraFov = false
            end
        end
        if isBroadcastingLive then
            isBroadcastingLive = false
            HideLifeInvaderOverlay()
            TriggerServerEvent("lifeinvader-app:cameraStop")
        end
        ClearPedSecondaryTask(ped)
        if camNetwork then
            TriggerServerEvent("lifeinvader:unregisterProp", camNetwork)
            DeleteEntity(NetToObj(camNetwork))
            camNetwork = nil
        end
        isHoldingCam = false
        SetPedMaxMoveBlendRatio(ped, 3.0)
        TriggerEvent("pma-voice:toggleUi", true)
    end
end

--- ToggleMicrophoneLifeInvader
function ToggleMicrophoneLifeInvader()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Accès refusé", image = LI_LOGO, content = "Vous devez être en service pour accéder à cette fonctionnalité." })
        return
    end

    CancelCurrentProp("mic")

    if isHoldingMic then
        ClearPedSecondaryTask(VFW.PlayerData.ped)
        SetModelAsNoLongerNeeded(micModel)
        if micNetwork then
            TriggerServerEvent("lifeinvader:unregisterProp", micNetwork)
            DeleteEntity(NetToObj(micNetwork))
            micNetwork = nil
        end
        isHoldingMic = false
        return
    end

    local ped = VFW.PlayerData.ped
    if not loadModel(micModel) then return end
    if not loadAnimDict(micAnimLib) then return end

    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -5.0)
    local mic = VFW.OneSync.CreateObject(micModel, coords)
    Wait(1000)
    local networkId = ObjToNet(mic)
    SetNetworkIdExistsOnAllMachines(networkId, true)
    NetworkSetNetworkIdDynamic(networkId, true)
    SetNetworkIdCanMigrate(networkId, false)

    local p = micPlacementNormal
    AttachEntityToEntity(mic, ped, GetPedBoneIndex(ped, micBoneNormal), p[1], p[2], p[3], p[4], p[5], p[6], 1, 1, 0, 1, 0, 1)
    TaskPlayAnim(ped, micAnimLib, micAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)

    micNetwork = networkId
    isHoldingMic = true
    TriggerServerEvent("lifeinvader:registerProp", networkId)

    CreateThread(function()
        local isMicExtended = false

        while isHoldingMic do
            local myPed = VFW.PlayerData.ped

            DisablePlayerFiring(myPed, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 38, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            -- Toggle E pour tendre/replier le micro
            if IsDisabledControlJustPressed(0, 38) and micNetwork then
                local m = NetToObj(micNetwork)
                if DoesEntityExist(m) and DoesEntityExist(myPed) then
                    if not isMicExtended then
                        isMicExtended = true
                        ClearPedSecondaryTask(myPed)
                        local pe = micPlacementExtend
                        AttachEntityToEntity(m, myPed, GetPedBoneIndex(myPed, micBoneExtend), pe[1], pe[2], pe[3], pe[4], pe[5], pe[6], 1, 1, 0, 1, 0, 1)
                        if loadAnimDict(micExtendAnimLib) then
                            TaskPlayAnim(myPed, micExtendAnimLib, micExtendAnimName, 4.0, -4.0, -1, 49, 0, false, false, false)
                        end
                    else
                        isMicExtended = false
                        ClearPedSecondaryTask(myPed)
                        local pn = micPlacementNormal
                        AttachEntityToEntity(m, myPed, GetPedBoneIndex(myPed, micBoneNormal), pn[1], pn[2], pn[3], pn[4], pn[5], pn[6], 1, 1, 0, 1, 0, 1)
                        if HasAnimDictLoaded(micAnimLib) then
                            TaskPlayAnim(myPed, micAnimLib, micAnimName, 4.0, -4.0, -1, 49, 0, false, false, false)
                        end
                    end
                end
            end

            VFW.ShowHelpNotification(isMicExtended and "~INPUT_PICKUP~ Replier le micro\n~INPUT_VEH_DUCK~ Ranger le micro" or "~INPUT_PICKUP~ Tendre le micro\n~INPUT_VEH_DUCK~ Ranger le micro")

            if IsControlJustPressed(0, 73) then
                ClearPedSecondaryTask(myPed)
                if micNetwork then
                    TriggerServerEvent("lifeinvader:unregisterProp", micNetwork)
                    DeleteEntity(NetToObj(micNetwork))
                    micNetwork = nil
                end
                isHoldingMic = false
                break
            end

            Wait(0)
        end
    end)
end

--- ToggleBigMicroLifeInvader
function ToggleBigMicroLifeInvader()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Accès refusé", image = LI_LOGO, content = "Vous devez être en service pour accéder à cette fonctionnalité." })
        return
    end

    CancelCurrentProp("bmic")

    if isHoldingBmic then
        ClearPedSecondaryTask(VFW.PlayerData.ped)
        if bigMicroNetwork then
            TriggerServerEvent("lifeinvader:unregisterProp", bigMicroNetwork)
            DeleteEntity(NetToObj(bigMicroNetwork))
            bigMicroNetwork = nil
        end
        isHoldingBmic = false
        return
    end

    local model = "prop_v_bmike_01"
    local anim, lib = "mcs2_crew_idle_m_boom", "missfra1"

    if not loadModel(model) then return end
    if not loadAnimDict(lib) then return end

    local coords = GetOffsetFromEntityInWorldCoords(VFW.PlayerData.ped, 0.0, 0.0, -5.0)
    local bigCam = VFW.OneSync.CreateObject(model, coords)
    Wait(1000)
    local networkId = ObjToNet(bigCam)
    SetNetworkIdExistsOnAllMachines(networkId, true)
    NetworkSetNetworkIdDynamic(networkId, true)
    SetNetworkIdCanMigrate(networkId, false)
    AttachEntityToEntity(bigCam, VFW.PlayerData.ped, GetPedBoneIndex(VFW.PlayerData.ped, 28422), -0.08, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
    TaskPlayAnim(VFW.PlayerData.ped, lib, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
    bigMicroNetwork = networkId
    isHoldingBmic = true
    TriggerServerEvent("lifeinvader:registerProp", networkId)

    CreateThread(function()
        while isHoldingBmic do
            DisablePlayerFiring(VFW.PlayerData.ped, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            VFW.ShowHelpNotification("~INPUT_VEH_DUCK~ Ranger la perche")

            if IsControlJustPressed(0, 73) then
                ClearPedSecondaryTask(VFW.PlayerData.ped)
                if bigMicroNetwork then
                    TriggerServerEvent("lifeinvader:unregisterProp", bigMicroNetwork)
                    DeleteEntity(NetToObj(bigMicroNetwork))
                    bigMicroNetwork = nil
                end
                isHoldingBmic = false
                break
            end

            Wait(0)
        end
    end)
end

local liveConfirmPending = false
local liveConfirmTime = 0
local hideHud = false
local fov = 50.0
local fov_min = 1.0
local fov_max = 100.0

local camAnimLib = "missfinale_c2mcs_1"
local camAnimName = "fin_c2_mcs_1_camman"

--- Replay camera holding animation (anti-bug: relance si interrompue)
local function ReplayCamAnim()
    local ped = VFW.PlayerData.ped
    if IsEntityPlayingAnim(ped, camAnimLib, camAnimName, 3) then return end
    if not loadAnimDict(camAnimLib) then return end

    if camNetwork then
        local cam = NetToObj(camNetwork)
        if DoesEntityExist(cam) then
            AttachEntityToEntity(cam, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        end
    end

    TaskPlayAnim(ped, camAnimLib, camAnimName, 2.0, -2.0, -1, 50, 0, 0, 0, 0)
end

--- ToggleCamLifeInvader
function ToggleCamLifeInvader()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Accès refusé", image = LI_LOGO, content = "Vous devez être en service pour accéder à cette fonctionnalité." })
        return
    end

    CancelCurrentProp("cam")

    if isHoldingCam then
        ClearPedSecondaryTask(VFW.PlayerData.ped)
        if camNetwork then
            TriggerServerEvent("lifeinvader:unregisterProp", camNetwork)
            DeleteEntity(NetToObj(camNetwork))
            camNetwork = nil
        end
        isHoldingCam = false

        if cameraActive then
            cameraActive = false
            if DoesCamExist(cameraHandle) then
                DestroyCam(cameraHandle, false)
                RenderScriptCams(false, false, 0, true, true)
                cameraHandle = nil
                ClearTimecycleModifier()
                isInCameraFov = false
            end
            if isBroadcastingLive then
                isBroadcastingLive = false
                HideLifeInvaderOverlay()
                TriggerServerEvent("lifeinvader-app:cameraStop")
            end
        end

        SetPedMaxMoveBlendRatio(VFW.PlayerData.ped, 3.0)
        TriggerEvent("pma-voice:toggleUi", true)
        return
    end

    local model = "prop_v_cam_01"
    if not loadModel(model) then return end
    if not loadAnimDict(camAnimLib) then return end

    local coords = GetOffsetFromEntityInWorldCoords(VFW.PlayerData.ped, 0.0, 0.0, -5.0)
    local cam = VFW.OneSync.CreateObject(model, coords)
    Wait(1000)
    local networkId = ObjToNet(cam)
    SetNetworkIdExistsOnAllMachines(networkId, true)
    NetworkSetNetworkIdDynamic(networkId, true)
    SetNetworkIdCanMigrate(networkId, false)
    AttachEntityToEntity(cam, VFW.PlayerData.ped, GetPedBoneIndex(VFW.PlayerData.ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
    TaskPlayAnim(VFW.PlayerData.ped, camAnimLib, camAnimName, 1.0, -1, -1, 50, 0, 0, 0, 0)
    camNetwork = networkId
    isHoldingCam = true
    TriggerServerEvent("lifeinvader:registerProp", networkId)

    CreateThread(function()
        local ped = VFW.PlayerData.ped

        SetPedMaxMoveBlendRatio(ped, 1.0)
        TriggerEvent("pma-voice:toggleUi", false)

        while isHoldingCam do
            ped = VFW.PlayerData.ped

            DisablePlayerFiring(ped, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(1, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            SetCurrentPedWeapon(ped, joaat("WEAPON_UNARMED"), true)

            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 26, true)
            DisableControlAction(0, 29, true)
            DisableControlAction(0, 58, true)
            DisableControlAction(0, 0, true)
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 245, true)
            DisableControlAction(0, 249, true)

            SetPedMaxMoveBlendRatio(ped, 1.0)

            if not isInCameraFov then
                VFW.ShowHelpNotification("~INPUT_CONTEXT~ Activer la caméra\n~INPUT_VEH_DUCK~ Ranger la caméra")
                ReplayCamAnim()
            elseif isBroadcastingLive then
                VFW.ShowHelpNotification("~INPUT_DETONATE~ Arrêter le direct")
            else
                VFW.ShowHelpNotification("~INPUT_DETONATE~ Lancer le direct\n~INPUT_CONTEXT~ Ranger la caméra")
            end

            if not isInCameraFov and IsControlJustPressed(0, 73) then
                PutAwayCamLifeInvader()
                break
            end

            if VFW.Interact.JustPressed(0, 38) then
                if not cameraActive then
                    cameraActive = true
                    isInCameraFov = true

                    local playerPed = PlayerPedId()
                    cameraHandle = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
                    AttachCamToEntity(cameraHandle, playerPed, 0.0, 0.0, 1.0, true)
                    SetCamRot(cameraHandle, GetEntityRotation(playerPed, 2), 2)
                    SetCamFov(cameraHandle, fov)
                    SetCamActive(cameraHandle, true)
                    RenderScriptCams(true, false, 0, true, true)
                    SetTimecycleModifier("default")
                    SetTimecycleModifierStrength(0.3)
                elseif not isBroadcastingLive then
                    PutAwayCamLifeInvader()
                    break
                end
            end

            if cameraActive and IsControlJustPressed(0, 47) then
                if not isBroadcastingLive then
                    if liveConfirmPending and (GetGameTimer() - liveConfirmTime) < 3000 then
                        liveConfirmPending = false
                        local playerName = (VFW.PlayerData.firstName and VFW.PlayerData.lastName)
                            and (VFW.PlayerData.firstName .. " " .. VFW.PlayerData.lastName)
                            or "Journaliste"
                        local result = TriggerServerCallback("lifeinvader-app:tryStartCamera", { name = playerName })

                        if not result or not result.ok then
                            if result and result.reason == "not_allowed" then
                                VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Accès refusé", image = LI_LOGO, content = "Votre grade ne vous permet pas de lancer un direct." })
                            else
                                VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Information", image = LI_LOGO, content = "Un direct est déjà en cours." })
                            end
                        else
                            isBroadcastingLive = true
                            ShowLifeInvaderOverlay()

                            CreateThread(function()
                                while isBroadcastingLive and cameraActive and isHoldingCam do
                                    if DoesCamExist(cameraHandle) then
                                        local camCoords = GetCamCoord(cameraHandle)
                                        local camRot = GetCamRot(cameraHandle, 2)
                                        TriggerServerEvent("lifeinvader-app:cameraState", {
                                            coords = { x = camCoords.x, y = camCoords.y, z = camCoords.z },
                                            rotation = { x = camRot.x, y = camRot.y, z = camRot.z },
                                            fov = GetCamFov(cameraHandle)
                                        })
                                    end
                                    Wait(200)
                                end
                            end)

                            VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Direct", image = LI_LOGO, content = "Direct lancé !" })
                        end
                    else
                        liveConfirmPending = true
                        liveConfirmTime = GetGameTimer()
                        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Informations Direct", image = LI_LOGO, content = "Appuyez à nouveau sur G pour lancer le direct.", duration = 3 })
                    end
                else
                    if liveConfirmPending and (GetGameTimer() - liveConfirmTime) < 3000 then
                        liveConfirmPending = false
                        isBroadcastingLive = false
                        HideLifeInvaderOverlay()
                        TriggerServerEvent("lifeinvader-app:cameraStop")

                        if DoesCamExist(cameraHandle) then
                            DestroyCam(cameraHandle, false)
                            RenderScriptCams(false, false, 0, true, true)
                            cameraHandle = nil
                            ClearTimecycleModifier()
                            isInCameraFov = false
                        end
                        cameraActive = false
                        ReplayCamAnim()

                        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Direct", image = LI_LOGO, content = "Direct terminé." })
                    else
                        liveConfirmPending = true
                        liveConfirmTime = GetGameTimer()
                        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Informations Direct", image = LI_LOGO, content = "Appuyez à nouveau sur G pour arrêter le direct.", duration = 3 })
                    end
                end
            end

            if cameraActive then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)

                if isBroadcastingLive then
                    ReplayCamAnim()
                end

                if IsControlPressed(0, 241) then
                    fov = math.max(fov_min, fov - 1.0)
                elseif IsControlPressed(0, 242) then
                    fov = math.min(fov_max, fov + 1.0)
                end

                if IsControlJustPressed(0, 101) then
                    hideHud = not hideHud
                    if hideHud then
                        VFW.Nui.HudVisible(true)
                        DisplayRadar(true)
                    else
                        VFW.Nui.HudVisible(false)
                        DisplayRadar(false)
                    end
                end

                if IsControlJustPressed(0, 245) then
                    local input = VFW.Nui.KeyboardInput(true, "Texte du scaleform ?", nil)
                    if not input then
                        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Erreur", image = LI_LOGO, content = "Vous devez entrer un texte valide." })
                    end
                end

                if DoesCamExist(cameraHandle) then
                    SetCamFov(cameraHandle, fov)
                end

                local zoomFactor = fov / fov_max
                local sensitivity = 2.0 + (zoomFactor * 3.0)

                local xMagnitude = GetDisabledControlNormal(0, 1)
                local yMagnitude = GetDisabledControlNormal(0, 2)
                local camRot = GetCamRot(cameraHandle, 2)

                local newPitch = math.max(-30.0, math.min(30.0, camRot.x - yMagnitude * sensitivity))
                camRot = vector3(newPitch, 0.0, camRot.z - xMagnitude * sensitivity)
                SetCamRot(cameraHandle, camRot, 2)

                if IsControlJustPressed(0, 177) then
                    cameraActive = false
                    DestroyCam(cameraHandle, false)
                    RenderScriptCams(false, false, 0, true, true)
                    cameraHandle = nil
                    ClearTimecycleModifier()
                    isInCameraFov = false
                    if isBroadcastingLive then
                        isBroadcastingLive = false
                        HideLifeInvaderOverlay()
                        TriggerServerEvent("lifeinvader-app:cameraStop")
                    end
                    ReplayCamAnim()
                end
            end

            Wait(0)
        end

        SetPedMaxMoveBlendRatio(VFW.PlayerData.ped, 3.0)
        TriggerEvent("pma-voice:toggleUi", true)
    end)
end

--- PutAwayCamLifeInvader
function PutAwayCamLifeInvader()
    if not isHoldingCam then
        VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Erreur", image = LI_LOGO, content = "Vous ne tenez pas de caméra." })
        return
    end

    if cameraActive then
        cameraActive = false
        if DoesCamExist(cameraHandle) then
            DestroyCam(cameraHandle, false)
            RenderScriptCams(false, false, 0, true, true)
            cameraHandle = nil
            ClearTimecycleModifier()
            isInCameraFov = false
        end
    end

    if isBroadcastingLive then
        isBroadcastingLive = false
        HideLifeInvaderOverlay()
        TriggerServerEvent("lifeinvader-app:cameraStop")
    end

    local ped = VFW.PlayerData.ped
    StopAnimTask(ped, camAnimLib, camAnimName, -2.0)
    Wait(1500)

    ClearPedSecondaryTask(ped)
    if camNetwork then
        TriggerServerEvent("lifeinvader:unregisterProp", camNetwork)
        DeleteEntity(NetToObj(camNetwork))
        camNetwork = nil
    end
    isHoldingCam = false

    SetPedMaxMoveBlendRatio(ped, 3.0)
    TriggerEvent("pma-voice:toggleUi", true)

    VFW.ShowNotification({ type = "JOB", title = "LifeInvader", subtitle = "Information", image = LI_LOGO, content = "Caméra rangée." })
end
