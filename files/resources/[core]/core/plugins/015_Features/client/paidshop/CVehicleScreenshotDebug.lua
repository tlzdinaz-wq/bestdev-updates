-- Debug command: spawn every paid shop vehicle and save a client screenshot.

local CAPTURE_COORDS = vector4(-1639.0, -3091.0, 13.94, 330.0)
local MODEL_LOAD_TIMEOUT_MS = 15000
local SCREENSHOT_TIMEOUT_MS = 90000
local SCREENSHOT_UPLOAD_BPS = 2500000

local captureRunning = false
local captureAbortRequested = false
local captureResultWaiter = nil
local activeVehicle = nil
local activeCam = nil
local restoreState = nil
local suppressHud = false

local function debugLog(message)
    print(("[PaidShopVehicleShots] %s"):format(tostring(message)))
end

local function hideShopUi()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "paidshop:hide" })
    DisplayHud(false)
    DisplayRadar(false)

    if VFW and VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(false)
    end
end

local function restoreShopUi()
    DisplayHud(true)
    DisplayRadar(true)

    if VFW and VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(true)
    end
end

local function deleteActiveVehicle()
    if activeVehicle and DoesEntityExist(activeVehicle) then
        SetEntityAsMissionEntity(activeVehicle, true, true)
        DeleteEntity(activeVehicle)
    end
    activeVehicle = nil
end

local function destroyActiveCam()
    if activeCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(activeCam, false)
        activeCam = nil
    end
    ClearFocus()
end

local function cleanupCaptureState()
    suppressHud = false
    deleteActiveVehicle()
    destroyActiveCam()

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    restoreShopUi()

    if restoreState and restoreState.coords then
        SetEntityCoordsNoOffset(
            ped,
            restoreState.coords.x,
            restoreState.coords.y,
            restoreState.coords.z,
            false,
            false,
            false
        )
        SetEntityHeading(ped, restoreState.heading or GetEntityHeading(ped))
    end

    restoreState = nil
end

CreateThread(function()
    while true do
        if suppressHud then
            HideHudAndRadarThisFrame()
            HideHudComponentThisFrame(1)
            HideHudComponentThisFrame(2)
            HideHudComponentThisFrame(3)
            HideHudComponentThisFrame(4)
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(8)
            HideHudComponentThisFrame(9)
            HideHudComponentThisFrame(13)
            HideHudComponentThisFrame(17)
            HideHudComponentThisFrame(19)
            HideHudComponentThisFrame(20)

            if IsControlJustPressed(0, 73) then
                captureAbortRequested = true
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function prepareCaptureState()
    local ped = PlayerPedId()

    restoreState = {
        coords = GetEntityCoords(ped),
        heading = GetEntityHeading(ped),
    }

    hideShopUi()

    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveAnyVehicle(ped, 0, 0)
        local deadline = GetGameTimer() + 4000
        while IsPedInAnyVehicle(ped, false) and GetGameTimer() < deadline do
            Wait(50)
        end
    end

    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, CAPTURE_COORDS.x, CAPTURE_COORDS.y, CAPTURE_COORDS.z, false, false, false)
    SetEntityHeading(ped, CAPTURE_COORDS.w)

    RequestCollisionAtCoord(CAPTURE_COORDS.x, CAPTURE_COORDS.y, CAPTURE_COORDS.z)
    local deadline = GetGameTimer() + 6000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        Wait(50)
    end

    suppressHud = true
    Wait(1000)
end

local function loadVehicleModel(spawnName)
    local modelHash = GetHashKey(spawnName)

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        return nil, "modele vehicule introuvable"
    end

    RequestModel(modelHash)

    local deadline = GetGameTimer() + MODEL_LOAD_TIMEOUT_MS
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do
        Wait(0)
    end

    if not HasModelLoaded(modelHash) then
        return nil, "timeout chargement modele"
    end

    return modelHash
end

local function spawnVehicleForCapture(spawnName)
    local modelHash, loadError = loadVehicleModel(spawnName)
    if not modelHash then
        return nil, loadError
    end

    ClearAreaOfVehicles(CAPTURE_COORDS.x, CAPTURE_COORDS.y, CAPTURE_COORDS.z, 35.0, false, false, false, false, false)
    ClearAreaOfPeds(CAPTURE_COORDS.x, CAPTURE_COORDS.y, CAPTURE_COORDS.z, 35.0, 1)

    local vehicle = CreateVehicle(
        modelHash,
        CAPTURE_COORDS.x,
        CAPTURE_COORDS.y,
        CAPTURE_COORDS.z,
        CAPTURE_COORDS.w,
        false,
        false
    )

    SetModelAsNoLongerNeeded(modelHash)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil, "creation vehicule echouee"
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetEntityHeading(vehicle, CAPTURE_COORDS.w)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleNumberPlateText(vehicle, "SHOP")
    SetEntityInvincible(vehicle, true)
    FreezeEntityPosition(vehicle, true)

    activeVehicle = vehicle
    return vehicle, modelHash
end

local function setupVehicleCamera(vehicle, modelHash)
    destroyActiveCam()

    local minDim, maxDim = GetModelDimensions(modelHash)
    local length = 4.8
    local width = 2.1
    local height = 1.6

    if minDim and maxDim then
        length = math.max(2.0, maxDim.y - minDim.y)
        width = math.max(1.4, maxDim.x - minDim.x)
        height = math.max(1.2, maxDim.z - minDim.z)
    end

    local camPos = GetOffsetFromEntityInWorldCoords(
        vehicle,
        -math.max(width * 0.85, 1.5),
        math.max(length * 1.35, 5.2),
        math.max(height * 0.95 + 0.7, 1.8)
    )
    local lookAt = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, math.max(height * 0.42, 0.75))

    activeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(activeCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(activeCam, lookAt.x, lookAt.y, lookAt.z)
    SetCamFov(activeCam, length > 7.0 and 46.0 or 42.0)
    SetCamActive(activeCam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetFocusEntity(vehicle)
end

local function requestVehicleScreenshot(spawnName, index)
    captureResultWaiter = {
        index = index,
        spawnName = spawnName,
        result = nil,
    }

    local requestOk, requestError = pcall(function()
        exports["screenshot-basic"]:requestScreenshot({
            encoding = "jpg",
            quality = 0.96,
        }, function(data)
            if not captureResultWaiter or tonumber(captureResultWaiter.index) ~= tonumber(index) then
                return
            end

            if type(data) ~= "string" or data == "" then
                captureResultWaiter.result = {
                    success = false,
                    error = "capture screenshot-basic vide",
                }
                return
            end

            TriggerLatentServerEvent(
                "paidshop:debug:saveVehicleScreenshot",
                SCREENSHOT_UPLOAD_BPS,
                spawnName,
                index,
                data
            )
        end)
    end)

    if not requestOk then
        captureResultWaiter.result = {
            success = false,
            error = tostring(requestError),
        }
    end

    local deadline = GetGameTimer() + SCREENSHOT_TIMEOUT_MS
    while not captureAbortRequested
        and captureResultWaiter
        and not captureResultWaiter.result
        and GetGameTimer() < deadline do
        Wait(100)
    end

    local result = captureResultWaiter and captureResultWaiter.result or nil
    captureResultWaiter = nil

    if captureAbortRequested then
        return { success = false, error = "capture interrompue" }
    end

    if not result then
        return { success = false, error = "timeout screenshot-basic" }
    end

    return result
end

RegisterNetEvent("paidshop:debug:vehicleScreenshotResult", function(result)
    if not captureResultWaiter or type(result) ~= "table" then return end
    if tonumber(result.index) ~= tonumber(captureResultWaiter.index) then return end

    captureResultWaiter.result = result
end)

local function runVehicleScreenshotJob(startIndex)
    local response = TriggerServerCallback("paidshop:debug:getVehicleScreenshotList")
    if not response or not response.success then
        debugLog(response and response.error or "impossible de recuperer la liste des vehicules")
        return
    end

    local vehicles = response.vehicles or {}
    startIndex = math.max(1, math.floor(tonumber(startIndex) or 1))

    if startIndex > #vehicles then
        debugLog(("index de depart invalide: %d / %d"):format(startIndex, #vehicles))
        TriggerServerEvent("paidshop:debug:finishVehicleScreenshotJob", {
            saved = 0,
            failed = 0,
        })
        return
    end

    debugLog(("demarrage: %d vehicules, dossier %s"):format(#vehicles - startIndex + 1, response.outputFolder))
    debugLog("appuie sur X pour demander l'arret apres la capture courante")

    prepareCaptureState()

    local saved = 0
    local failed = 0

    for index = startIndex, #vehicles do
        if captureAbortRequested then
            break
        end

        deleteActiveVehicle()

        local entry = vehicles[index]
        local spawnName = entry.spawnName
        debugLog(("%03d/%03d chargement %s"):format(index, #vehicles, spawnName))

        local vehicle, modelOrError = spawnVehicleForCapture(spawnName)
        if not vehicle then
            failed = failed + 1
            debugLog(("%s ignore: %s"):format(spawnName, tostring(modelOrError)))
        else
            setupVehicleCamera(vehicle, modelOrError)
            Wait(1200)

            local result = requestVehicleScreenshot(spawnName, index)
            if result and result.success then
                saved = saved + 1
                debugLog(("%s sauvegarde: %s"):format(spawnName, tostring(result.fileName)))
            else
                failed = failed + 1
                debugLog(("%s echec: %s"):format(spawnName, tostring(result and result.error or "erreur inconnue")))
            end
        end

        Wait(250)
    end

    cleanupCaptureState()
    TriggerServerEvent("paidshop:debug:finishVehicleScreenshotJob", {
        saved = saved,
        failed = failed,
    })

    if captureAbortRequested then
        debugLog(("arrete: %d sauvegardes, %d echecs, dossier %s"):format(saved, failed, response.outputFolder))
    else
        debugLog(("termine: %d sauvegardes, %d echecs, dossier %s"):format(saved, failed, response.outputFolder))
    end
end

RegisterCommand("paidshop_vehshots", function(_, args)
    if captureRunning then
        debugLog("un job de capture est deja en cours")
        return
    end

    captureRunning = true
    captureAbortRequested = false

    local startIndex = args and args[1] or nil

    CreateThread(function()
        local ok, err = pcall(runVehicleScreenshotJob, startIndex)
        if not ok then
            debugLog(("erreur fatale: %s"):format(tostring(err)))
            cleanupCaptureState()
            TriggerServerEvent("paidshop:debug:finishVehicleScreenshotJob", {
                saved = 0,
                failed = 0,
            })
        end

        captureResultWaiter = nil
        captureRunning = false
        captureAbortRequested = false
    end)
end, false)

RegisterCommand("paidshop_vehshots_stop", function()
    if not captureRunning then
        debugLog("aucun job de capture en cours")
        return
    end

    captureAbortRequested = true
    debugLog("arret demande")
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    captureAbortRequested = true
    cleanupCaptureState()
end)
