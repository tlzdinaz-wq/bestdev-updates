---@meta _
---@diagnostic disable: duplicate-doc-field

-- Gestion des images staff (mugshots)
-- Ouvre une NUI pour visualiser et refaire les mugshots en masse

local imageManagerProcessing = false

local VANILLA_VEHICLE_CATEGORIES = {
    ["Compactes"] = true, ["Berlines"] = true, ["SUV"] = true, ["Coupes"] = true,
    ["Muscles"] = true, ["Sport Classique"] = true, ["Sport"] = true, ["Super"] = true,
    ["Motos"] = true, ["Tout-Terrain"] = true, ["Quads"] = true, ["Vans"] = true,
    ["Industriel"] = true, ["Utilitaires"] = true, ["Commercial"] = true,
    ["Velos"] = true, ["Bateaux"] = true, ["Helicopteres"] = true, ["Avions"] = true,
    ["Militaire"] = true, ["Urgences (Vanilla)"] = true, ["Service"] = true,
}

-- Build vanilla/addon split from the local carlist + CDN already-photographed set.
local function buildVehicleLists(cdnVehicles)
    local vanillaVehicles, addonVehicles = {}, {}
    local seenVanilla, seenAddon = {}, {}

    local cdnSet = {}
    if cdnVehicles then
        for _, v in ipairs(cdnVehicles) do
            if v and v.name then cdnSet[v.name] = true end
        end
    end

    local cat = VFW.Staff and VFW.Staff.Carlist
    if cat then
        for catName, vehs in pairs(cat) do
            local isVanilla = VANILLA_VEHICLE_CATEGORIES[catName] == true
            for _, vd in ipairs(vehs) do
                if isVanilla then
                    if not seenVanilla[vd.model] then
                        seenVanilla[vd.model] = true
                        vanillaVehicles[#vanillaVehicles + 1] = {
                            name = vd.label or vd.model,
                            model = vd.model,
                            imageUrl = "https://docs.fivem.net/vehicles/" .. vd.model .. ".webp",
                            category = catName,
                        }
                    end
                else
                    if not seenAddon[vd.model] and not cdnSet[vd.model] then
                        seenAddon[vd.model] = true
                        addonVehicles[#addonVehicles + 1] = {
                            name = vd.label or vd.model,
                            model = vd.model,
                            category = catName,
                        }
                    end
                end
            end
        end
    end
    table.sort(vanillaVehicles, function(a, b) return a.name < b.name end)
    table.sort(addonVehicles, function(a, b) return a.name < b.name end)
    return vanillaVehicles, addonVehicles
end

-- Open the menu shell immediately, then stream sections in parallel via
-- imageManager:patch as each server callback / native enumeration completes.
function StaffMenu.GetImageVehicleLists()
    local vehicles = TriggerServerCallback("vfw:server:getCdnVehicles") or {}
    local vanillaVehicles, addonVehicles = buildVehicleLists(vehicles)
    return vehicles, vanillaVehicles, addonVehicles
end

function StaffMenu.OpenImageManager(defaultTab)
    -- Depuis le hub Gestion, on reste dans le panneau natif (pas l'overlay NUI).
    if StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        if StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
        SendNUIMessage({
            action = "gestion:images:sync",
            data = { tab = defaultTab or "mugshots" },
        })
        return
    end

    exports['VUI']:CloseAll()
    Wait(200)

    VFW.Nui.Focus(true, false)
    SendNUIMessage({
        action = "imageManager:open",
        data = {
            mugshots = {}, vehicles = {}, vanillaVehicles = {}, addonVehicles = {},
            items = {}, societies = {}, factions = {},
            bannersMetier = {}, bannersFaction = {}, outfits = {},
            defaultTab = defaultTab or "mugshots",
            loading = {
                mugshots = true, vehicles = true, items = true,
                societies = true, factions = true, banners = true, outfits = true,
            },
        }
    })

    local function patch(section, payload)
        SendNUIMessage({ action = "imageManager:patch", data = { section = section, payload = payload } })
    end

    CreateThread(function()
        local mugshots = TriggerServerCallback("vfw:server:getMugshotsWithInfo") or {}
        patch("mugshots", mugshots)
    end)

    CreateThread(function()
        local vehicles = TriggerServerCallback("vfw:server:getCdnVehicles") or {}
        local vanillaVehicles, addonVehicles = buildVehicleLists(vehicles)
        patch("vehicles", {
            vehicles = vehicles,
            vanillaVehicles = vanillaVehicles,
            addonVehicles = addonVehicles,
        })
    end)

    CreateThread(function()
        local items = TriggerServerCallback("vfw:server:getCdnItems") or {}
        patch("items", items)
    end)

    CreateThread(function()
        local societies = TriggerServerCallback("vfw:server:getCdnSocieties") or {}
        patch("societies", societies)
    end)

    CreateThread(function()
        local factions = TriggerServerCallback("vfw:server:getCdnFactions") or {}
        patch("factions", factions)
    end)

    CreateThread(function()
        local bannersMetier = TriggerServerCallback("vfw:server:getBannerTemplates", "metier") or {}
        local bannersFaction = TriggerServerCallback("vfw:server:getBannerTemplates", "faction") or {}
        patch("banners", { metier = bannersMetier, faction = bannersFaction })
    end)

    CreateThread(function()
        if not VFW.Staff_BuildOutfitsList then
            patch("outfits", {})
            return
        end
        local manifest = TriggerServerCallback("vfw:server:getOutfitsManifest") or {}
        local outfits = VFW.Staff_BuildOutfitsList(manifest) or {}
        patch("outfits", outfits)
    end)
end

RegisterNUICallback("imageManager:close", function(_, cb)
    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        StaffMenu.UncoverGestionHub()
    else
        VFW.Nui.Focus(false, false)
    end
    cb({ ok = true })
end)

RegisterNUICallback("imageManager:deleteVehicle", function(data, cb)
    local name = data.name
    if not name or name == "" then
        cb({ ok = false, error = "Nom vide" })
        return
    end
    local success = TriggerServerCallback("vfw:server:deleteVehicleImage", name)
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:deleteMugshot", function(data, cb)
    local charId = data.charId
    if not charId then
        cb({ ok = false })
        return
    end
    local success = TriggerServerCallback("vfw:server:deleteMugshot", charId)
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:updateSocietyImage", function(data, cb)
    local name = data.name
    local url = data.url
    if not name or name == "" then
        cb({ ok = false, error = "Nom vide" })
        return
    end
    local success = TriggerServerCallback("vfw:server:updateSocietyImage", name, url or "")
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:updateFactionImage", function(data, cb)
    local name = data.name
    local url = data.url
    if not name or name == "" then
        cb({ ok = false, error = "Nom vide" })
        return
    end
    local success = TriggerServerCallback("vfw:server:updateFactionImage", name, url or "")
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:deleteFaction", function(data, cb)
    local name = data.name
    if not name or name == "" then
        cb({ ok = false })
        return
    end
    local success = TriggerServerCallback("vfw:server:deleteFactionImage", name)
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:deleteSociety", function(data, cb)
    local name = data.name
    if not name or name == "" then
        cb({ ok = false })
        return
    end
    local success = TriggerServerCallback("vfw:server:deleteSocietyImage", name)
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:addBannerTemplate", function(data, cb)
    local bannerType = data.bannerType
    local name = data.name
    local url = data.url
    if not bannerType or not name or name == "" or not url or url == "" then
        cb({ ok = false, error = "Données manquantes" })
        return
    end
    local success = TriggerServerCallback("vfw:server:addBannerTemplate", bannerType, name, url)
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:deleteBannerTemplate", function(data, cb)
    local id = data.id
    if not id then
        cb({ ok = false })
        return
    end
    local success = TriggerServerCallback("vfw:server:deleteBannerTemplate", id)
    cb({ ok = success == true })
end)

RegisterNUICallback("imageManager:deleteItem", function(data, cb)
    local name = data.name
    if not name or name == "" then
        cb({ ok = false })
        return
    end
    local success = TriggerServerCallback("vfw:server:deleteItemImage", name)
    cb({ ok = success == true })
end)

function StaffMenu.RedoMugshotsForChars(charIds)
    if imageManagerProcessing then return false end
    if type(charIds) ~= "table" then
        local singleId = tonumber(charIds)
        if not singleId then return false end
        charIds = { singleId }
    end

    local ids = {}
    for i = 1, #charIds do
        local id = tonumber(charIds[i])
        if id then ids[#ids + 1] = id end
    end
    if #ids == 0 then return false end

    imageManagerProcessing = true
    CreateThread(function()
        local ok, err = pcall(function()
        local fromHub = StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()
        if fromHub then
            if StaffMenu.CoverGestionHub then StaffMenu.CoverGestionHub() end
            VFW.Nui.Focus(false)
        else
            VFW.Nui.Focus(false, false)
            SendNUIMessage({ action = "imageManager:close" })
        end

        Wait(300)

        TriggerServerEvent("core:server:instanceCreator", true)

        local hadStaffClothes = staffClothesColor ~= nil
        if hadStaffClothes then
            TriggerEvent("vfw:staff:setStaffClothes", false)
            Wait(300)
        end

        local playerPed = PlayerPedId()
        local origCoords = GetEntityCoords(playerPed)
        local origHeading = GetEntityHeading(playerPed)
        local origSkin = nil

        TriggerEvent("skinchanger:getSkin", function(skin)
            origSkin = skin
        end)

        local total = #ids
        local doneCount = 0

        for i, charId in ipairs(ids) do
            VFW.ShowNotification({
                type = "STAFF", variant = "INFO", subtitle = "Images",
                message = string.format("Mugshot %d/%d — chargement du perso...", i, total)
            })

            local skin, tattoos = TriggerServerCallback("vfw:server:getSkinByCharId", charId)

            if skin then
                TriggerEvent("skinchanger:loadSkin", skin)

                playerPed = PlayerPedId()
                ClearPedDecorations(playerPed)

                if tattoos and type(tattoos) == "table" then
                    for _, tat in ipairs(tattoos) do
                        if tat and tat.Collection and tat.HashName then
                            ApplyPedOverlay(playerPed, joaat(tat.Collection), joaat(tat.HashName))
                        end
                    end
                end

                Wait(800)

                local mugshotDone = false
                local startedAt = GetGameTimer()
                CaptureFastMugshotWithCallback(function(success, url)
                    if success and url and url ~= "" then
                        TriggerServerEvent("vfw:server:setMugshotForChar", charId, url)
                        doneCount = doneCount + 1
                    end
                    mugshotDone = true
                end, false)

                while not mugshotDone and GetGameTimer() - startedAt < 30000 do
                    Wait(100)
                end

                if not mugshotDone then
                    VFW.ShowNotification({
                        type = "STAFF", variant = "ERROR", subtitle = "Images",
                        message = string.format("Capture mugshot ID %d expirée.", charId)
                    })
                end

                Wait(500)
            else
                VFW.ShowNotification({
                    type = "STAFF", variant = "ERROR", subtitle = "Images",
                    message = string.format("Personnage ID %d introuvable.", charId)
                })
            end
        end

        if origSkin then
            TriggerEvent("skinchanger:loadSkin", origSkin)
        end

        if hadStaffClothes then
            Wait(300)
            TriggerEvent("vfw:staff:setStaffClothes", true)
        end

        playerPed = PlayerPedId()
        SetEntityCoords(playerPed, origCoords.x, origCoords.y, origCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, origHeading)

        TriggerServerEvent("core:server:instanceCreator", false)

        if fromHub then
            if StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
            SendNUIMessage({ action = "gestion:images:sync", data = { tab = "mugshots" } })
        end

        VFW.ShowNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "Images",
            message = string.format("%d mugshot%s refait%s et envoyé%s sur FiveManage.", doneCount, doneCount > 1 and "s" or "", doneCount > 1 and "s" or "", doneCount > 1 and "s" or "")
        })
        end)

        imageManagerProcessing = false
        if not ok then
            console.error("[Images] Redo mugshots: " .. tostring(err))
            if StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
                if StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
                SendNUIMessage({ action = "gestion:images:sync", data = { tab = "mugshots" } })
            end
            VFW.ShowNotification({
                type = "STAFF", variant = "ERROR", subtitle = "Images",
                message = "La recapture des mugshots a échoué."
            })
        end
    end)

    return true
end

RegisterNUICallback("imageManager:redoMugshots", function(data, cb)
    local ok = StaffMenu.RedoMugshotsForChars(data and (data.charIds or data.charId or data.id))
    cb({ ok = ok == true })
end)

-- ═══════════════════════════════════════════════════════════════
-- Vehicle photo capture (green screen + orbit camera)
-- ═══════════════════════════════════════════════════════════════

local vehicleCaptureActive = false
local vehicleCaptureEntity = nil
local vehicleCaptureCam = nil
local vehicleCaptureGreenActive = false
local vehicleCaptureGreenColor = { r = 0, g = 0, b = 0 }
local vehicleCaptureRestore = nil
local vehicleCaptureInstrId = nil
local vehicleCaptureNuiFocused = false
local vehicleCaptureModel = nil
local vehicleCaptureOrbitCenter = nil
local vehicleOrbitYaw = 180.0
local vehicleOrbitPitch = 15.0
local vehicleOrbitDistance = 4.0
local vehicleBatch = nil   -- { models = {...}, index = 1, awaitingPreview = false } in batch mode

local VEHICLE_CAPTURE_POS = vector3(0.0, 0.0, 300.0) -- High altitude, no surrounding geometry
local VEHICLE_GREEN_RADIUS = 15.0
local ORBIT_SENSITIVITY = 2.0
local ZOOM_SENSITIVITY = 0.5
local MIN_PITCH = -10.0
local MAX_PITCH = 80.0
local MIN_DISTANCE = 2.0
local MAX_DISTANCE = 8.0

local function startVehicleGreenScreen(pos)
    if vehicleCaptureGreenActive then return end
    vehicleCaptureGreenActive = true

    CreateThread(function()
        while vehicleCaptureGreenActive do
            SetWeatherTypeOvertimePersist('EXTRASUNNY', 0.0)
            NetworkOverrideClockTime(14, 0, 0)
            DrawGlowSphere(pos.x, pos.y, pos.z, VEHICLE_GREEN_RADIUS,
                vehicleCaptureGreenColor.r, vehicleCaptureGreenColor.g, vehicleCaptureGreenColor.b,
                1.0, false, true)
            Wait(0)
        end
    end)
end

local function stopVehicleGreenScreen()
    vehicleCaptureGreenActive = false
end

local function setVehicleGreenColor(r, g, b)
    vehicleCaptureGreenColor.r = r
    vehicleCaptureGreenColor.g = g
    vehicleCaptureGreenColor.b = b
end

local function cleanupVehicleCapture()
    if vehicleCaptureEntity and DoesEntityExist(vehicleCaptureEntity) then
        DeleteEntity(vehicleCaptureEntity)
        vehicleCaptureEntity = nil
    end
    vehicleCaptureOrbitCenter = nil

    if vehicleCaptureCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(vehicleCaptureCam, false)
        vehicleCaptureCam = nil
    end

    stopVehicleGreenScreen()
    vehicleCaptureGreenColor = { r = 0, g = 0, b = 0 }

    if vehicleCaptureInstrId then
        VFW.RemoveInstructionalButtons(vehicleCaptureInstrId)
        vehicleCaptureInstrId = nil
    end

    -- Close NUI panel
    SendNUIMessage({ action = "vehicleScreener:close" })
    SetNuiFocusKeepInput(false)
    VFW.Nui.Focus(false, false)
    vehicleCaptureNuiFocused = false
    vehicleCaptureModel = nil

    DisplayRadar(true)
    DisplayHud(true)
    VFW.Nui.HudVisible(true)

    vehicleCaptureActive = false
end

-- Spawn a vehicle, build cam, send the screener panel data to NUI.
-- Player teleport / fade / instance setup must already be done by the caller.
local function spawnAndShowVehicle(model)
    local hash = joaat(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local spawnPos = VEHICLE_CAPTURE_POS + vector3(0.0, 5.0, 0.0)
    vehicleCaptureEntity = CreateVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, false, false)
    FreezeEntityPosition(vehicleCaptureEntity, true)
    SetEntityInvincible(vehicleCaptureEntity, true)
    SetModelAsNoLongerNeeded(hash)

    vehicleCaptureModel = model

    local vehMin, vehMax = GetModelDimensions(hash)
    local vehCoords = GetEntityCoords(vehicleCaptureEntity)
    vehicleCaptureOrbitCenter = vector3(vehCoords.x, vehCoords.y, vehCoords.z + (vehMax.z - vehMin.z) * 0.4)

    vehicleOrbitYaw = 180.0
    vehicleOrbitPitch = 15.0
    local vehLength = vehMax.y - vehMin.y
    vehicleOrbitDistance = math.max(3.5, vehLength * 1.0)

    startVehicleGreenScreen(vehCoords)

    local liveryCount = GetVehicleLiveryCount(vehicleCaptureEntity)
    local liveries = {}
    if liveryCount > 0 then
        for i = 0, liveryCount - 1 do
            local livName = GetLiveryName(vehicleCaptureEntity, i)
            if livName and livName ~= "NULL" then
                liveries[#liveries + 1] = { index = i, name = livName }
            else
                liveries[#liveries + 1] = { index = i, name = "Livery " .. (i + 1) }
            end
        end
    end

    local colorZones = {}
    local priR, priG, priB = 0, 0, 0
    if GetIsVehiclePrimaryColourCustom(vehicleCaptureEntity) then
        priR, priG, priB = GetVehicleCustomPrimaryColour(vehicleCaptureEntity)
    end
    colorZones[#colorZones + 1] = { id = "primary", label = "Couleur primaire", r = priR, g = priG, b = priB }

    local secR, secG, secB = 0, 0, 0
    if GetIsVehicleSecondaryColourCustom(vehicleCaptureEntity) then
        secR, secG, secB = GetVehicleCustomSecondaryColour(vehicleCaptureEntity)
    end
    colorZones[#colorZones + 1] = { id = "secondary", label = "Couleur secondaire", r = secR, g = secG, b = secB }

    local rad = math.rad
    local oc = vehicleCaptureOrbitCenter
    local camX = oc.x + vehicleOrbitDistance * math.cos(rad(vehicleOrbitPitch)) * math.sin(rad(vehicleOrbitYaw))
    local camY = oc.y + vehicleOrbitDistance * math.cos(rad(vehicleOrbitPitch)) * math.cos(rad(vehicleOrbitYaw))
    local camZ = oc.z + vehicleOrbitDistance * math.sin(rad(vehicleOrbitPitch))

    vehicleCaptureCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(vehicleCaptureCam, camX, camY, camZ)
    PointCamAtCoord(vehicleCaptureCam, oc.x, oc.y, oc.z)
    SetCamActive(vehicleCaptureCam, true)
    RenderScriptCams(true, false, 0, true, true)

    local payload = {
        model = model,
        liveryCount = liveryCount,
        liveries = liveries,
        colorZones = colorZones,
    }
    if vehicleBatch then
        payload.batch = { current = vehicleBatch.index, total = #vehicleBatch.models }
    end
    SendNUIMessage({ action = "vehicleScreener:open", data = payload })
    VFW.Nui.Focus(true, true)
    vehicleCaptureNuiFocused = true

    if not vehicleCaptureInstrId then
        vehicleCaptureInstrId = VFW.AddInstructionalButtons({
            { label = "Tourner",      control = 1   },
            { label = "Zoom",         control = 241 },
            { label = "Retour panel", control = 25  },
        })
    end
end

local function startVehicleOrbitThread()
    local rad = math.rad
    CreateThread(function()
        while vehicleCaptureActive do
            DisableAllControlActions(0)
            SetNuiFocusKeepInput(not vehicleCaptureNuiFocused)

            if not vehicleCaptureNuiFocused then
                local mouseX = GetDisabledControlNormal(0, 1) * ORBIT_SENSITIVITY
                local mouseY = GetDisabledControlNormal(0, 2) * ORBIT_SENSITIVITY
                vehicleOrbitYaw = vehicleOrbitYaw - mouseX
                vehicleOrbitPitch = math.max(MIN_PITCH, math.min(MAX_PITCH, vehicleOrbitPitch + mouseY))

                if IsDisabledControlJustPressed(0, 25) then
                    vehicleCaptureNuiFocused = true
                    SetNuiFocusKeepInput(false)
                    VFW.Nui.Focus(true, true)
                    SendNUIMessage({ action = "vehicleScreener:freecamState", data = { freecam = false } })
                end
            end

            if GetDisabledControlNormal(0, 241) > 0.0 then
                vehicleOrbitDistance = math.max(MIN_DISTANCE, vehicleOrbitDistance - ZOOM_SENSITIVITY)
            end
            if GetDisabledControlNormal(0, 242) > 0.0 then
                vehicleOrbitDistance = math.min(MAX_DISTANCE, vehicleOrbitDistance + ZOOM_SENSITIVITY)
            end

            local oc = vehicleCaptureOrbitCenter
            if oc and vehicleCaptureCam then
                local cx = oc.x + vehicleOrbitDistance * math.cos(rad(vehicleOrbitPitch)) * math.sin(rad(vehicleOrbitYaw))
                local cy = oc.y + vehicleOrbitDistance * math.cos(rad(vehicleOrbitPitch)) * math.cos(rad(vehicleOrbitYaw))
                local cz = oc.z + vehicleOrbitDistance * math.sin(rad(vehicleOrbitPitch))
                SetCamCoord(vehicleCaptureCam, cx, cy, cz)
                PointCamAtCoord(vehicleCaptureCam, oc.x, oc.y, oc.z)
            end

            Wait(0)
        end
    end)
end

-- Common pre-capture setup: instance, fade, hide HUD, teleport player.
-- Returns the restore data table that must be saved for later cleanup.
local function setupPlayerForCapture()
    TriggerServerEvent("core:server:instanceCreator", true)

    local playerPed = PlayerPedId()
    local origCoords = GetEntityCoords(playerPed)
    local origHeading = GetEntityHeading(playerPed)
    local savedHour = VFW.currentHour or 12
    local savedMinute = VFW.currentMinute or 0
    local savedWeather = GlobalState.EnvironmentWeather or VFW.currentWeather or "EXTRASUNNY"

  DoScreenFadeOut(500)
    Wait(600)

    DisplayRadar(false)
    DisplayHud(false)
    VFW.Nui.HudVisible(false)

    local hiddenPos = vector3(VEHICLE_CAPTURE_POS.x + 100.0, VEHICLE_CAPTURE_POS.y + 100.0, VEHICLE_CAPTURE_POS.z - 50.0)
    RequestCollisionAtCoord(hiddenPos.x, hiddenPos.y, hiddenPos.z)
    SetEntityCoords(playerPed, hiddenPos.x, hiddenPos.y, hiddenPos.z, false, false, false, false)
    SetEntityVisible(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)

    return {
        origCoords = origCoords,
        origHeading = origHeading,
        savedHour = savedHour,
        savedMinute = savedMinute,
        savedWeather = savedWeather,
    }
end

-- Cleanup just the current vehicle entity + cam (keeps player hidden, HUD off).
-- Used between vehicles in batch mode.
local function cleanupCurrentVehicleOnly()
    if vehicleCaptureEntity and DoesEntityExist(vehicleCaptureEntity) then
        DeleteEntity(vehicleCaptureEntity)
    end
    vehicleCaptureEntity = nil
    vehicleCaptureOrbitCenter = nil

    if vehicleCaptureCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(vehicleCaptureCam, false)
        vehicleCaptureCam = nil
    end

    stopVehicleGreenScreen()
    vehicleCaptureGreenColor = { r = 0, g = 0, b = 0 }
end

RegisterNUICallback("imageManager:captureVehicle", function(data, cb)
    -- Defensive reset: if no entity exists, prior state is stale
    if (vehicleCaptureActive or vehicleBatch) and (not vehicleCaptureEntity or not DoesEntityExist(vehicleCaptureEntity)) then
        console.warn("[ImageManager] stuck capture state detected, force-reset")
        vehicleCaptureActive = false
        vehicleBatch = nil
    end

    if vehicleCaptureActive or vehicleBatch then
        cb({ ok = false, error = "Capture déjà en cours (terminez-la d'abord)." })
        return
    end

    local model = data.model
    if not model or model == "" then
        cb({ ok = false, error = "Nom du modèle requis." })
        return
    end

    local hash = joaat(model)
    if not IsModelInCdimage(hash) then
        cb({ ok = false, error = "Modèle '" .. model .. "' introuvable." })
        return
    end

    if not IsModelAVehicle(hash) then
        cb({ ok = false, error = "'" .. model .. "' n'est pas un véhicule." })
        return
    end

    cb({ ok = true })

    vehicleCaptureActive = true

    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = "imageManager:close" })
    Wait(300)

    vehicleCaptureRestore = setupPlayerForCapture()

    spawnAndShowVehicle(model)

    Wait(200)
    DoScreenFadeIn(500)
    Wait(500)

    startVehicleOrbitThread()
end)

RegisterNUICallback("imageManager:captureVehiclesBatch", function(data, cb)
    local modelsCount = (type(data.models) == "table") and #data.models or 0
    console.debug(string.format("[ImageManager] batch request: %d models, active=%s, batch=%s",
        modelsCount, tostring(vehicleCaptureActive), tostring(vehicleBatch ~= nil)))

    -- Defensive reset: if no entity exists, prior state is stale
    if (vehicleCaptureActive or vehicleBatch) and (not vehicleCaptureEntity or not DoesEntityExist(vehicleCaptureEntity)) then
        console.warn("[ImageManager] stuck capture state detected, force-reset")
        vehicleCaptureActive = false
        vehicleBatch = nil
    end

    if vehicleCaptureActive or vehicleBatch then
        cb({ ok = false, error = "Capture déjà en cours (terminez-la d'abord)." })
        return
    end

    local models = data.models
    if type(models) ~= "table" or #models == 0 then
        cb({ ok = false, error = "Aucun véhicule sélectionné." })
        return
    end

    -- Filter invalid models, collecting names of dropped ones for feedback
    local valid = {}
    local invalid = {}
    for _, m in ipairs(models) do
        if type(m) == "string" and m ~= "" then
            local h = joaat(m)
            if (IsModelInCdimage(h) or IsModelValid(h)) and IsModelAVehicle(h) then
                valid[#valid + 1] = m
            else
                invalid[#invalid + 1] = m
            end
        end
    end
    if #valid == 0 then
        cb({ ok = false, error = "Aucun modèle valide ne peut être chargé (" .. #invalid .. " ignorés)." })
        return
    end

    if #invalid > 0 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'WARNING', subtitle = 'Images',
            message = string.format("%d véhicule(s) ignoré(s) (modèle non chargé) sur %d.", #invalid, #models)
        })
    end

    cb({ ok = true, total = #valid, skipped = #invalid })

    vehicleBatch = { models = valid, index = 1, awaitingPreview = false }
    vehicleCaptureActive = true

    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = "imageManager:close" })
    Wait(300)

    vehicleCaptureRestore = setupPlayerForCapture()

    spawnAndShowVehicle(valid[1])

    Wait(200)
    DoScreenFadeIn(500)
    Wait(500)

    startVehicleOrbitThread()
end)

-- ═══════════════════════════════════════════════════════════════
-- Vehicle Screener NUI Callbacks
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback("vehicleScreener:setHeight", function(data, cb)
    cb({ ok = true })
    if not vehicleCaptureEntity or not DoesEntityExist(vehicleCaptureEntity) then return end

    local coords = GetEntityCoords(vehicleCaptureEntity)
    local step = 0.05
    if data.direction == "down" then step = -0.05 end
    SetEntityCoords(vehicleCaptureEntity, coords.x, coords.y, coords.z + step, false, false, false, false)

    -- Update orbit center so camera follows the vehicle
    if vehicleCaptureOrbitCenter then
        vehicleCaptureOrbitCenter = vector3(vehicleCaptureOrbitCenter.x, vehicleCaptureOrbitCenter.y, vehicleCaptureOrbitCenter.z + step)
    end
end)

RegisterNUICallback("vehicleScreener:setColor", function(data, cb)
    cb({ ok = true })
    if not vehicleCaptureEntity or not DoesEntityExist(vehicleCaptureEntity) then return end

    local zone = data.zone
    local r = data.r or 0
    local g = data.g or 0
    local b = data.b or 0

    if zone == "primary" then
        SetVehicleCustomPrimaryColour(vehicleCaptureEntity, r, g, b)
    elseif zone == "secondary" then
        SetVehicleCustomSecondaryColour(vehicleCaptureEntity, r, g, b)
    end
end)

RegisterNUICallback("vehicleScreener:setLivery", function(data, cb)
    cb({ ok = true })
    if not vehicleCaptureEntity or not DoesEntityExist(vehicleCaptureEntity) then return end

    local index = data.index
    if index == -1 then
        -- Reset livery
        SetVehicleLivery(vehicleCaptureEntity, -1)
    else
        SetVehicleLivery(vehicleCaptureEntity, index)
    end
end)

RegisterNUICallback("vehicleScreener:capture", function(data, cb)
    cb({ ok = true })
    if not vehicleCaptureActive or not vehicleCaptureEntity then return end

    local model = vehicleCaptureModel
    local isBatch = vehicleBatch ~= nil
    vehicleCaptureActive = false

    -- Hide cursor for clean screenshot
    VFW.Nui.Focus(false, false)
    vehicleCaptureNuiFocused = false
    SendNUIMessage({ action = "vehicleScreener:close" })
    Wait(100)

    setVehicleGreenColor(0, 255, 0)
    Wait(500)

    exports['screenshot-basic']:requestScreenshot(function(screenshotData)
        setVehicleGreenColor(0, 0, 0)

        if isBatch then
            -- Batch mode: keep vehicle/cam alive, show preview in NUI
            vehicleBatch.awaitingPreview = true
            SendNUIMessage({
                action = "vehicleScreener:showPreview",
                data = {
                    base64 = screenshotData,
                    model = model,
                    current = vehicleBatch.index,
                    total = #vehicleBatch.models,
                }
            })
            VFW.Nui.Focus(true, true)
        else
            DoScreenFadeOut(500)
            SendNUIMessage({
                action = "nui:uploadVehiclePhoto",
                data = {
                    base64 = screenshotData,
                    model = model,
                }
            })
        end
    end)
end)

RegisterNUICallback("vehicleScreener:retryBatch", function(_, cb)
    cb({ ok = true })
    if not vehicleBatch or not vehicleBatch.awaitingPreview then return end

    vehicleBatch.awaitingPreview = false
    vehicleCaptureActive = true
    VFW.Nui.Focus(true, true)
    vehicleCaptureNuiFocused = true

    -- Re-send open with current vehicle data so panel state restores
    -- (front-end already keeps the data; just hide preview overlay)
    SendNUIMessage({ action = "vehicleScreener:hidePreview" })

    startVehicleOrbitThread()
end)

RegisterNUICallback("vehicleScreener:nextBatch", function(data, cb)
    cb({ ok = true })
    if not vehicleBatch then return end

    local uploadedModel = data and data.model or vehicleCaptureModel
    if data and data.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Images',
            message = string.format("Photo de '%s' uploadée.", uploadedModel or "?")
        })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Images',
            message = string.format("Échec upload pour '%s'.", uploadedModel or "?")
        })
    end

    vehicleBatch.awaitingPreview = false
    vehicleBatch.index = vehicleBatch.index + 1

    if vehicleBatch.index <= #vehicleBatch.models then
        -- Next vehicle: tear down current entity/cam, spawn next, restart orbit
        cleanupCurrentVehicleOnly()
        Wait(150)

        vehicleCaptureActive = true
        spawnAndShowVehicle(vehicleBatch.models[vehicleBatch.index])
        startVehicleOrbitThread()
    else
        -- Batch finished: full cleanup + restore + reopen image manager
        DoScreenFadeOut(500)
        Wait(600)

        cleanupVehicleCapture()
        local restore = vehicleCaptureRestore
        vehicleCaptureRestore = nil
        vehicleBatch = nil

        if restore then
            local ped = PlayerPedId()
            SetEntityVisible(ped, true, false)
            FreezeEntityPosition(ped, false)
            SetEntityCoords(ped, restore.origCoords.x, restore.origCoords.y, restore.origCoords.z, false, false, false, false)
            SetEntityHeading(ped, restore.origHeading)
            NetworkOverrideClockTime(restore.savedHour, restore.savedMinute, 0)
            SetWeatherTypeOvertimePersist(restore.savedWeather, 0.0)
            TriggerServerEvent("core:server:instanceCreator", false)
        end

        DoScreenFadeIn(500)
        Wait(500)

        StaffMenu.OpenImageManager("vehicules")
    end
end)

RegisterNUICallback("vehicleScreener:finish", function(data, cb)
    cb({ ok = true })
    if not vehicleCaptureActive and not vehicleBatch then return end

    vehicleCaptureActive = false
    vehicleBatch = nil

    DoScreenFadeOut(500)
    Wait(600)

    cleanupVehicleCapture()

    local restore = vehicleCaptureRestore
    vehicleCaptureRestore = nil

    if restore then
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityCoords(ped, restore.origCoords.x, restore.origCoords.y, restore.origCoords.z, false, false, false, false)
        SetEntityHeading(ped, restore.origHeading)

        NetworkOverrideClockTime(restore.savedHour, restore.savedMinute, 0)
        SetWeatherTypeOvertimePersist(restore.savedWeather, 0.0)

        TriggerServerEvent("core:server:instanceCreator", false)
    end

    DoScreenFadeIn(500)
    Wait(500)

    StaffMenu.OpenImageManager("vehicules")
end)

RegisterNUICallback("vehicleScreener:toggleFreecam", function(data, cb)
    cb({ ok = true })
    if not vehicleCaptureActive then return end

    -- Panel → Freecam : focus reste ON mais sans curseur (bloque toutes les touches)
    vehicleCaptureNuiFocused = false
    SetNuiFocusKeepInput(true)
    VFW.Nui.Focus(true, false)
    SendNUIMessage({ action = "vehicleScreener:freecamState", data = { freecam = true } })
end)

RegisterNUICallback("imageManager:vehiclePhotoDone", function(data, cb)
    cb({ ok = true })

    local restore = vehicleCaptureRestore
    vehicleCaptureRestore = nil

    Wait(600) -- Ensure fade out is complete

    cleanupVehicleCapture()

    if restore then
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityCoords(ped, restore.origCoords.x, restore.origCoords.y, restore.origCoords.z, false, false, false, false)
        SetEntityHeading(ped, restore.origHeading)

        NetworkOverrideClockTime(restore.savedHour, restore.savedMinute, 0)
        SetWeatherTypeOvertimePersist(restore.savedWeather, 0.0)

        TriggerServerEvent("core:server:instanceCreator", false)
    end

    DoScreenFadeIn(500)
    Wait(500)

    if data.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Images',
            message = string.format("Photo du véhicule '%s' uploadée !", data.model or "?")
        })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Images',
            message = "Erreur lors de l'upload de la photo."
      })
    end

    StaffMenu.OpenImageManager("vehicules")
end)
