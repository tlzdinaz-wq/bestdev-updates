-- Génération automatique des images de véhicules : Gestion > Images > Véhicules > « Générer les images ».
-- Même chaîne que les vêtements (outfit_screener.lua) : chaque modèle est posé devant une sphère verte, photographié
-- (screenshot-basic), détouré par la page NUI (gestion:images:capture → gestion:images:captureProcessed), puis envoyé par le
-- serveur sur FiveManage (staff/322_vehicle_images.lua). Retour ou Échap interrompt le lot.

local CAPTURE_POS = vector3(-300.0, -300.0, 650.0)
local MODEL_TIMEOUT_MS = 10000

local job = nil        -- { items = {{model,name}}, index, ok, fail, stop, drawing, cam, vehicle, restore }
local waiters = {}     -- id -> promise
local greenOn = false
local greenRadius = 15.0

local function guard()
    if not (StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["dev"] == true or perms["gestion_items"] == true or perms["staff"] == true or perms["server_management"] == true
end

local function notify(variant, message)
    VFW.ShowNotification({ type = 'STAFF', variant = variant, subtitle = 'Images', message = message })
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function startGreen()
    if greenOn then return end
    greenOn = true
    CreateThread(function()
        while greenOn do
            SetWeatherTypeOvertimePersist('EXTRASUNNY', 0.0)
            NetworkOverrideClockTime(14, 0, 0)
            DrawGlowSphere(CAPTURE_POS.x, CAPTURE_POS.y, CAPTURE_POS.z, greenRadius, 0, 255, 0, 1.0, false, true)
            Wait(0)
        end
    end)
end

local function await(id, timeoutMs)
    local p = promise.new()
    waiters[id] = p
    SetTimeout(timeoutMs or 30000, function()
        if waiters[id] == p then
            waiters[id] = nil
            p:resolve({ ok = false, error = "Délai dépassé (détourage / enregistrement)." })
        end
    end)
    return Citizen.Await(p)
end

local function resolve(id, result)
    local p = waiters[id]
    if not p then return end
    waiters[id] = nil
    p:resolve(result)
end

local function screenshot()
    local p = promise.new()
    local done = false
    exports['screenshot-basic']:requestScreenshot({ encoding = 'png' }, function(data)
        if done then return end
        done = true
        p:resolve(data)
    end)
    SetTimeout(10000, function()
        if done then return end
        done = true
        p:resolve(nil)
    end)
    return Citizen.Await(p)
end

local function clearVehicle()
    if job and job.vehicle and DoesEntityExist(job.vehicle) then
        SetEntityAsMissionEntity(job.vehicle, true, true)
        DeleteEntity(job.vehicle)
    end
    if job then job.vehicle = nil end
end

local function clearCam()
    if job and job.cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(job.cam, false)
        job.cam = nil
    end
    ClearFocus()
end

--- Pose le modèle devant la sphère verte et cadre la caméra en trois-quarts avant. Renvoie true ou false, raison.
local function stage(model)
    local hash = joaat(model)
    if not (IsModelInCdimage(hash) or IsModelValid(hash)) or not IsModelAVehicle(hash) then
        return false, "modèle introuvable"
    end
    RequestModel(hash)
    local deadline = GetGameTimer() + MODEL_TIMEOUT_MS
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(hash) then return false, "chargement trop long" end

    local vehicle = CreateVehicle(hash, CAPTURE_POS.x, CAPTURE_POS.y, CAPTURE_POS.z, 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false, "création impossible" end
    job.vehicle = vehicle
    SetEntityAsMissionEntity(vehicle, true, true)
    FreezeEntityPosition(vehicle, true)
    SetEntityCollision(vehicle, false, false)
    SetEntityInvincible(vehicle, true)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleLights(vehicle, 1)
    SetEntityCoordsNoOffset(vehicle, CAPTURE_POS.x, CAPTURE_POS.y, CAPTURE_POS.z, false, false, false)
    SetEntityHeading(vehicle, 0.0)

    local minDim, maxDim = GetModelDimensions(hash)
    local length, width, height = 4.8, 2.1, 1.6
    local midY, midZ = 0.0, 0.5
    if minDim and maxDim then
        length = math.max(1.5, maxDim.y - minDim.y)
        width = math.max(1.0, maxDim.x - minDim.x)
        height = math.max(1.0, maxDim.z - minDim.z)
        midY, midZ = (minDim.y + maxDim.y) / 2, (minDim.z + maxDim.z) / 2
    end
    local center = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, midY, midZ)
    local reach = math.max(length, width * 1.6, height * 1.4)
    local distance = reach * 1.25 + 1.5
    -- trois-quarts avant gauche, légèrement au-dessus
    local camPos = vector3(
        center.x - distance * 0.62,
        center.y + distance * 0.78,
        center.z + math.max(height * 0.45, 0.8)
    )
    greenRadius = math.max(15.0, distance * 2.6)

    clearCam()
    job.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(job.cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(job.cam, center.x, center.y, center.z)
    SetCamFov(job.cam, 40.0)
    SetCamActive(job.cam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetFocusPosAndVel(center.x, center.y, center.z, 0.0, 0.0, 0.0)
    Wait(700) -- textures haute définition de l'add-on
    return true
end

local function hudThread(current)
    CreateThread(function()
        while job == current do
            DisableControlAction(0, 200, true) -- Échap : pas de menu pause pendant le lot
            if IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
                current.stop = true
            end
            HideHudAndRadarThisFrame()
            if current.drawing then
                local it = current.items[current.index or 1]
                local label = string.format("Véhicules  —  %d / %d  %s   (Retour : arrêter)",
                    current.index or 0, #current.items, it and it.name or "")
                SetTextFont(4)
                SetTextScale(0.38, 0.38)
                SetTextColour(255, 255, 255, 220)
                SetTextDropShadow()
                SetTextCentre(true)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(label)
                EndTextCommandDisplayText(0.5, 0.93)
            end
            Wait(0)
        end
    end)
end

local function setupPlayer()
    TriggerServerEvent("core:server:instanceCreator", true)
    local ped = PlayerPedId()
    local restore = {
        coords = GetEntityCoords(ped),
        heading = GetEntityHeading(ped),
        hour = VFW.currentHour or 12,
        minute = VFW.currentMinute or 0,
        weather = GlobalState.EnvironmentWeather or VFW.currentWeather or "EXTRASUNNY",
    }
    DoScreenFadeOut(500)
    Wait(600)
    DisplayRadar(false)
    DisplayHud(false)
    VFW.Nui.HudVisible(false)
    local hidden = vector3(CAPTURE_POS.x + 150.0, CAPTURE_POS.y + 150.0, CAPTURE_POS.z - 60.0)
    RequestCollisionAtCoord(hidden.x, hidden.y, hidden.z)
    SetEntityCoords(ped, hidden.x, hidden.y, hidden.z, false, false, false, false)
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    return restore
end

local function restorePlayer(restore)
    if not restore then return end
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCoords(ped, restore.coords.x, restore.coords.y, restore.coords.z, false, false, false, false)
    SetEntityHeading(ped, restore.heading)
    NetworkOverrideClockTime(restore.hour, restore.minute, 0)
    SetWeatherTypeOvertimePersist(restore.weather, 0.0)
    TriggerServerEvent("core:server:instanceCreator", false)
end

local function finish(current)
    current.drawing = false
    clearVehicle()
    clearCam()
    greenOn = false
    job = nil
    DoScreenFadeOut(300)
    Wait(350)
    restorePlayer(current.restore)
    DisplayRadar(true)
    DisplayHud(true)
    VFW.Nui.HudVisible(true)
    DoScreenFadeIn(400)
    Wait(300)

    send("gestion:images:generateDone", { kind = "vehicle", ok = current.ok, fail = current.fail, total = #current.items, stopped = current.stop == true })
    if StaffMenu and StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
    if StaffMenu and StaffMenu.OpenImageManager then StaffMenu.OpenImageManager("vehicules") end

    if current.stop then
        notify('INFO', string.format("Capture interrompue : %d image(s) enregistrée(s), %d échec(s).", current.ok, current.fail))
    else
        notify(current.fail > 0 and 'ERROR' or 'SUCCESS', string.format("%d image(s) de véhicules envoyée(s) sur FiveManage, %d échec(s).", current.ok, current.fail))
    end
end

local function run(current)
    if StaffMenu and StaffMenu.CoverGestionHub then StaffMenu.CoverGestionHub() end
    VFW.Nui.Focus(false, false)
    Wait(200)
    current.restore = setupPlayer()
    RequestCollisionAtCoord(CAPTURE_POS.x, CAPTURE_POS.y, CAPTURE_POS.z)
    startGreen()
    DoScreenFadeIn(300)
    current.drawing = true
    hudThread(current)

    for i = 1, #current.items do
        if current.stop then break end
        local it = current.items[i]
        current.index = i
        clearVehicle()
        local staged, why = stage(it.model)
        local result
        if not staged then
            result = { ok = false, error = why }
        else
            current.drawing = false
            Wait(60)
            local shot = screenshot()
            current.drawing = true
            if not shot then
                result = { ok = false, error = "capture d'écran impossible" }
            else
                local id = string.format("veh_%s_%d", it.model, GetGameTimer())
                send("gestion:images:capture", { id = id, kind = "vehicle", model = it.model, index = i, total = #current.items, base64 = shot })
                result = await(id, 30000)
            end
        end
        if result and result.ok then current.ok = current.ok + 1 else current.fail = current.fail + 1 end
        send("gestion:images:progress", {
            kind = "vehicle", index = i, total = #current.items, model = it.model,
            ok = result and result.ok == true, url = result and result.url, error = result and result.error,
        })
    end

    finish(current)
end

--- Liste à photographier : add-ons ou véhicules GTA, sans image seulement (par défaut) ou tous.
local function buildItems(set, onlyMissing)
    if not (StaffMenu and StaffMenu.GetImageVehicleLists) then return {} end
    local withImage, vanilla, addons = StaffMenu.GetImageVehicleLists()
    local has = {}
    for _, v in ipairs(withImage or {}) do if v.model then has[tostring(v.model):lower()] = v end end

    local items, seen = {}, {}
    local function add(model, name)
        model = tostring(model or ""):lower()
        if model == "" or seen[model] then return end
        if onlyMissing and has[model] then return end
        seen[model] = true
        items[#items + 1] = { model = model, name = name or model }
    end

    if set == "vanilla" then
        for _, v in ipairs(vanilla or {}) do add(v.model, v.name) end
    else
        for _, v in ipairs(addons or {}) do add(v.model, v.name) end
        if not onlyMissing then
            -- les add-ons déjà photographiés ne sont plus dans la liste des add-ons : on les reprend
            local vanillaSet = {}
            for _, v in ipairs(vanilla or {}) do vanillaSet[tostring(v.model):lower()] = true end
            for model, v in pairs(has) do
                if not vanillaSet[model] and IsModelValid(joaat(model)) then add(model, v.name) end
            end
        end
    end
    return items
end

RegisterNUICallback("gestion:images:generateVehicles", function(data, cb)
    if not guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les images." })
        return
    end
    if job or (VFW.OutfitCaptureBusy and VFW.OutfitCaptureBusy()) then
        cb({ ok = false, error = "Une capture est déjà en cours." })
        return
    end
    local set = (data and data.set == "vanilla") and "vanilla" or "addon"
    local onlyMissing = not (data and data.onlyMissing == false)
    cb({ ok = true })

    CreateThread(function()
        local items = buildItems(set, onlyMissing)
        if #items == 0 then
            notify('INFO', "Rien à photographier : tous ces véhicules ont déjà une image.")
            send("gestion:images:generateDone", { kind = "vehicle", ok = 0, fail = 0, total = 0 })
            return
        end
        job = { items = items, index = 0, ok = 0, fail = 0, stop = false, drawing = false }
        run(job)
    end)
end)

--- Appelés par outfit_screener.lua, qui possède les rappels NUI communs (arrêt du lot, image détourée).
function VFW.VehicleImageCaptureBusy()
    return job ~= nil
end

function VFW.VehicleImageCaptureStop()
    if job then job.stop = true end
end

function VFW.VehicleImageProcessed(data)
    if not job or type(data) ~= "table" or type(data.id) ~= "string" then return end
    if not data.ok or type(data.base64) ~= "string" or data.base64 == "" then
        resolve(data.id, { ok = false, error = data.error or "Détourage impossible." })
        return
    end
    local model = data.id:match("^veh_(.+)_%d+$")
    TriggerServerEvent("core:vehicleImages:saveCapture", { id = data.id, model = model, base64 = data.base64 })
end

RegisterNetEvent("core:vehicleImages:saveResult", function(result)
    if type(result) ~= "table" or type(result.id) ~= "string" then return end
    resolve(result.id, result)
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() or not job then return end
    local current = job
    current.stop = true
    clearVehicle()
    clearCam()
    greenOn = false
    restorePlayer(current.restore)
    DisplayRadar(true)
    DisplayHud(true)
end)
