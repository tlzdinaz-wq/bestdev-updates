-- ═══════════════════════════════════════════════════════════════
-- Outfit Screener — green-screen capture of clothing pieces
-- Mirrors the vehicle screener (image_manager.lua) but for ped clothing.
-- Strategy: spawn a freemode ped at high altitude, set the target
-- component (drawable/texture), hide other components by setting them
-- to "naked" drawable variants, frame the camera on the relevant body
-- region, then capture against a green sphere for transparency.
-- ═══════════════════════════════════════════════════════════════

local outfitCaptureActive = false
local outfitCapturePed = nil
local outfitCapturePedModel = nil
local outfitCaptureCam = nil
local outfitGreenActive = false
local outfitGreenColor = { r = 0, g = 0, b = 0 }
local outfitCaptureRestore = nil
local outfitCaptureNuiFocused = false
local outfitOrbitCenter = nil
local outfitOrbitYaw = 180.0
local outfitOrbitPitch = 0.0
local outfitOrbitDistance = 1.5
local outfitOrbitZOffset = 0.0  -- z delta from ped origin (mirrored in outfitOrbitCenter.z)
local outfitCurrent = nil   -- { id, label, category, component, drawable, texture, propIndex }
local outfitBatch = nil     -- { items = {...}, index = 1, awaitingPreview = false }

-- Persistent per-category camera presets (KVP)
local CAM_KVP_PREFIX = "outfit_screener:cam:"

local function loadCamPreset(category)
    if not category then return nil end
    local raw = GetResourceKvpString(CAM_KVP_PREFIX .. category)
    if not raw or raw == "" then return nil end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

local function saveCamPreset(category, preset)
    if not category or type(preset) ~= "table" then return end
    SetResourceKvp(CAM_KVP_PREFIX .. category, json.encode(preset))
end

local OUTFIT_CAPTURE_POS = vector3(0.0, 0.0, 305.0)
local OUTFIT_GREEN_RADIUS = 6.0
local ORBIT_SENSITIVITY = 1.5
local ZOOM_SENSITIVITY = 0.15
local MIN_PITCH = -35.0
local MAX_PITCH = 35.0
local MIN_DISTANCE = 0.4
local MAX_DISTANCE = 4.0

-- Per-category framing & component layout
local CATEGORIES = {
    top = {
        label = "Haut", component = 11,
        zOffset = 0.20, distance = 0.95, pitch = 5.0,
    },
    undershirt = {
        label = "T-shirt", component = 8,
        zOffset = 0.18, distance = 0.90, pitch = 4.0,
    },
    torso = {
        label = "Bras", component = 3,
        zOffset = 0.10, distance = 1.10, pitch = 0.0,
    },
    pants = {
        label = "Pantalon", component = 4,
        zOffset = -0.40, distance = 1.05, pitch = -10.0,
    },
    shoes = {
        label = "Chaussures", component = 6,
        zOffset = -0.85, distance = 0.55, pitch = -30.0,
    },
    bag = {
        label = "Sac", component = 5,
        zOffset = 0.12, distance = 1.20, pitch = 0.0,
    },
    armor = {
        label = "Gilet", component = 9,
        zOffset = 0.18, distance = 0.95, pitch = 3.0,
    },
    decals = {
        label = "Plaque", component = 10,
        zOffset = 0.22, distance = 0.80, pitch = 5.0,
    },
    mask = {
        label = "Masque", component = 1,
        zOffset = 0.62, distance = 0.55, pitch = 0.0,
    },
    accessory = {
        label = "Accessoire", component = 7,
        zOffset = 0.30, distance = 0.75, pitch = 0.0,
    },
    glasses = {
        label = "Lunettes", prop = 1,
        zOffset = 0.62, distance = 0.50, pitch = 0.0,
    },
    hat = {
        label = "Chapeau", prop = 0,
        zOffset = 0.70, distance = 0.55, pitch = 5.0,
    },
    watch = {
        label = "Montre", prop = 6,
        zOffset = -0.12, distance = 0.48, pitch = -8.0,
    },
    ear = {
        label = "Oreilles", prop = 2,
        zOffset = 0.62, distance = 0.42, pitch = 0.0,
    },
    bracelet = {
        label = "Bracelet", prop = 7,
        zOffset = -0.14, distance = 0.48, pitch = -8.0,
    },
    outfit = {
        label = "Tenue", component = -1,
        fullBody = true,
        zOffset = 0.0, distance = 2.4, pitch = -8.0,
    },
}

local function getCategoryConfig(cat)
    return CATEGORIES[cat] or CATEGORIES.outfit
end

local function startGreenScreen(pos)
    if outfitGreenActive then return end
    outfitGreenActive = true
    CreateThread(function()
        while outfitGreenActive do
            SetWeatherTypeOvertimePersist('EXTRASUNNY', 0.0)
            NetworkOverrideClockTime(14, 0, 0)
            DrawGlowSphere(pos.x, pos.y, pos.z, OUTFIT_GREEN_RADIUS,
                outfitGreenColor.r, outfitGreenColor.g, outfitGreenColor.b,
                1.0, false, true)
            Wait(0)
        end
    end)
end

local function stopGreenScreen()
    outfitGreenActive = false
end

local function setGreenColor(r, g, b)
    outfitGreenColor.r = r
    outfitGreenColor.g = g
    outfitGreenColor.b = b
end

-- Direct port of Bentix-cs/fivem-greenscreener ResetPedComponents().
-- Establishes a consistent baseline appearance before applying the
-- target piece.
local function resetPedComponents(ped)
    SetPedDefaultComponentVariation(ped)
    Wait(150)
    SetPedComponentVariation(ped, 1, 0, 0, 0)   -- Mask
    SetPedComponentVariation(ped, 2, -1, 0, 0)  -- Hair
    SetPedComponentVariation(ped, 7, 0, 0, 0)   -- Accessories
    SetPedComponentVariation(ped, 5, 0, 0, 0)   -- Bags
    SetPedComponentVariation(ped, 6, -1, 0, 0)  -- Shoes
    SetPedComponentVariation(ped, 9, 0, 0, 0)   -- Armor
    SetPedComponentVariation(ped, 3, -1, 0, 0)  -- Torso
    SetPedComponentVariation(ped, 8, -1, 0, 0)  -- Undershirt
    SetPedComponentVariation(ped, 4, -1, 0, 0)  -- Legs
    SetPedComponentVariation(ped, 11, -1, 0, 0) -- Top
    SetPedHairColor(ped, 45, 15)
    ClearPedProp(ped, 0)
    ClearPedProp(ped, 1)
    ClearPedProp(ped, 2)
    ClearPedProp(ped, 6)
    ClearPedProp(ped, 7)
end

local function applyOutfitToPed(ped, item)
    if not ped or not DoesEntityExist(ped) then return end
    local cat = getCategoryConfig(item.category)

    resetPedComponents(ped)

    -- Apply the target piece
    if cat.prop ~= nil then
        local drawable = tonumber(item.drawable) or 0
        local texture = tonumber(item.texture) or 0
        SetPedPropIndex(ped, cat.prop, drawable, texture, true)
    elseif cat.component and cat.component >= 0 then
        local drawable = tonumber(item.drawable) or 0
        local texture = tonumber(item.texture) or 0
        SetPedComponentVariation(ped, cat.component, drawable, texture, 0)
    elseif cat.fullBody and type(item.components) == "table" then
        -- Full outfit: array of { component = x, drawable = y, texture = z }
        for _, c in ipairs(item.components) do
            SetPedComponentVariation(ped, tonumber(c.component) or 0,
                tonumber(c.drawable) or 0, tonumber(c.texture) or 0, 0)
        end
        if type(item.props) == "table" then
            for _, p in ipairs(item.props) do
                SetPedPropIndex(ped, tonumber(p.prop) or 0,
                    tonumber(p.drawable) or 0, tonumber(p.texture) or 0, true)
            end
        end
    end
end

local function spawnAndShowOutfit(item)
    local cat = getCategoryConfig(item.category)
    local pedModelName = item.pedModel or "mp_m_freemode_01"
  local hash = joaat(pedModelName)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return false end

    local pos = OUTFIT_CAPTURE_POS
    outfitCapturePed = CreatePed(4, hash, pos.x, pos.y, pos.z, 180.0, false, false)
    outfitCapturePedModel = pedModelName
    SetModelAsNoLongerNeeded(hash)

    SetEntityInvincible(outfitCapturePed, true)
    SetBlockingOfNonTemporaryEvents(outfitCapturePed, true)
    FreezeEntityPosition(outfitCapturePed, true)
    SetEntityCollision(outfitCapturePed, false, false)
    SetPedCanRagdoll(outfitCapturePed, false)
    SetPedDefaultComponentVariation(outfitCapturePed)
    SetEntityHeading(outfitCapturePed, 180.0)

    applyOutfitToPed(outfitCapturePed, item)

    local pedCoords = GetEntityCoords(outfitCapturePed)
    local preset = loadCamPreset(item.category)
    local zOffset = preset and preset.zOffset or cat.zOffset or 0.0
    outfitOrbitCenter = vector3(pedCoords.x, pedCoords.y, pedCoords.z + zOffset)
    outfitOrbitZOffset = zOffset
    outfitOrbitYaw = preset and preset.yaw or 180.0
    outfitOrbitPitch = preset and preset.pitch or cat.pitch or 0.0
    outfitOrbitDistance = preset and preset.distance or cat.distance or 1.5

    startGreenScreen(pedCoords)

    local rad = math.rad
    local oc = outfitOrbitCenter
    local camX = oc.x + outfitOrbitDistance * math.cos(rad(outfitOrbitPitch)) * math.sin(rad(outfitOrbitYaw))
    local camY = oc.y + outfitOrbitDistance * math.cos(rad(outfitOrbitPitch)) * math.cos(rad(outfitOrbitYaw))
    local camZ = oc.z + outfitOrbitDistance * math.sin(rad(outfitOrbitPitch))

    outfitCaptureCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(outfitCaptureCam, camX, camY, camZ)
    PointCamAtCoord(outfitCaptureCam, oc.x, oc.y, oc.z)
    SetCamActive(outfitCaptureCam, true)
    RenderScriptCams(true, false, 0, true, true)

    outfitCurrent = item

    local payload = {
        item = {
            id = item.id,
            label = item.label or item.name or "Vêtement",
            category = item.category,
            categoryLabel = cat.label,
            component = cat.component,
            prop = cat.prop,
            drawable = item.drawable,
            texture = item.texture,
            pedModel = pedModelName,
            sex = pedModelName == "mp_f_freemode_01" and "female" or "male",
        },
    }
    if outfitBatch then
        payload.batch = { current = outfitBatch.index, total = #outfitBatch.items }
    end
    SendNUIMessage({ action = "outfitScreener:open", data = payload })
    VFW.Nui.Focus(true, true)
    outfitCaptureNuiFocused = true
    return true
end

local function startOrbitThread()
    local rad = math.rad
    CreateThread(function()
        while outfitCaptureActive do
            DisableAllControlActions(0)
            SetNuiFocusKeepInput(not outfitCaptureNuiFocused)

            if not outfitCaptureNuiFocused then
                local mouseX = GetDisabledControlNormal(0, 1) * ORBIT_SENSITIVITY
                local mouseY = GetDisabledControlNormal(0, 2) * ORBIT_SENSITIVITY
                outfitOrbitYaw = outfitOrbitYaw - mouseX
                outfitOrbitPitch = math.max(MIN_PITCH, math.min(MAX_PITCH, outfitOrbitPitch + mouseY))

                if IsDisabledControlJustPressed(0, 25) then
                    outfitCaptureNuiFocused = true
                    SetNuiFocusKeepInput(false)
                    VFW.Nui.Focus(true, true)
                    SendNUIMessage({ action = "outfitScreener:freecamState", data = { freecam = false } })
                end
            end

            if GetDisabledControlNormal(0, 241) > 0.0 then
                outfitOrbitDistance = math.max(MIN_DISTANCE, outfitOrbitDistance - ZOOM_SENSITIVITY)
            end
            if GetDisabledControlNormal(0, 242) > 0.0 then
                outfitOrbitDistance = math.min(MAX_DISTANCE, outfitOrbitDistance + ZOOM_SENSITIVITY)
            end

            local oc = outfitOrbitCenter
            if oc and outfitCaptureCam then
                local cx = oc.x + outfitOrbitDistance * math.cos(rad(outfitOrbitPitch)) * math.sin(rad(outfitOrbitYaw))
                local cy = oc.y + outfitOrbitDistance * math.cos(rad(outfitOrbitPitch)) * math.cos(rad(outfitOrbitYaw))
                local cz = oc.z + outfitOrbitDistance * math.sin(rad(outfitOrbitPitch))
                SetCamCoord(outfitCaptureCam, cx, cy, cz)
                PointCamAtCoord(outfitCaptureCam, oc.x, oc.y, oc.z)
            end

            Wait(0)
        end
    end)
end

local function setupPlayerForOutfitCapture()
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

    local hiddenPos = vector3(OUTFIT_CAPTURE_POS.x + 100.0, OUTFIT_CAPTURE_POS.y + 100.0, OUTFIT_CAPTURE_POS.z - 50.0)
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

local function cleanupCurrentPedOnly()
    if outfitCapturePed and DoesEntityExist(outfitCapturePed) then
        DeleteEntity(outfitCapturePed)
    end
    outfitCapturePed = nil
    outfitOrbitCenter = nil

    if outfitCaptureCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(outfitCaptureCam, false)
        outfitCaptureCam = nil
    end

    stopGreenScreen()
    setGreenColor(0, 0, 0)
end

local function cleanupOutfitCapture()
    cleanupCurrentPedOnly()

    SendNUIMessage({ action = "outfitScreener:close" })
    SetNuiFocusKeepInput(false)
    VFW.Nui.Focus(false, false)
    outfitCaptureNuiFocused = false
    outfitCurrent = nil

    DisplayRadar(true)
    DisplayHud(true)
    VFW.Nui.HudVisible(true)

    outfitCaptureActive = false
end

local function restorePlayerAfterCapture()
    local restore = outfitCaptureRestore
    outfitCaptureRestore = nil
    if not restore then return end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCoords(ped, restore.origCoords.x, restore.origCoords.y, restore.origCoords.z, false, false, false, false)
    SetEntityHeading(ped, restore.origHeading)
    NetworkOverrideClockTime(restore.savedHour, restore.savedMinute, 0)
    SetWeatherTypeOvertimePersist(restore.savedWeather, 0.0)
    TriggerServerEvent("core:server:instanceCreator", false)
end

-- ═══════════════════════════════════════════════════════════════
-- Entry points
-- ═══════════════════════════════════════════════════════════════

local function isOutfitCaptureBusy()
    if (outfitCaptureActive or outfitBatch) and (not outfitCapturePed or not DoesEntityExist(outfitCapturePed)) then
        console.warn("[OutfitScreener] stuck capture state detected, force-reset")
        outfitCaptureActive = false
        outfitBatch = nil
        return false
    end
    return outfitCaptureActive or outfitBatch ~= nil
end

local function validateItem(item)
    if type(item) ~= "table" then return nil end
    local cat = item.category
    if type(cat) ~= "string" or not CATEGORIES[cat] then return nil end
    if not item.id then item.id = tostring(GetGameTimer()) end
    return item
end

RegisterNUICallback("imageManager:captureOutfit", function(data, cb)
    if isOutfitCaptureBusy() then
        cb({ ok = false, error = "Capture déjà en cours (terminez-la d'abord)." })
        return
    end

    local item = validateItem(data and data.item)
    if not item then
        cb({ ok = false, error = "Ces données du vêtement ne sont pas valides." })
        return
    end

    cb({ ok = true })

    outfitCaptureActive = true
    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = "imageManager:close" })
    Wait(300)

    outfitCaptureRestore = setupPlayerForOutfitCapture()

    if not spawnAndShowOutfit(item) then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Images',
            message = "Impossible de charger le ped freemode."
      })
        cleanupOutfitCapture()
        restorePlayerAfterCapture()
        DoScreenFadeIn(500)
        return
    end

    Wait(200)
    DoScreenFadeIn(500)
    Wait(500)

    startOrbitThread()
end)

RegisterNUICallback("imageManager:captureOutfitsBatch", function(data, cb)
    if isOutfitCaptureBusy() then
        cb({ ok = false, error = "Capture déjà en cours (terminez-la d'abord)." })
        return
    end

    local items = data and data.items
    if type(items) ~= "table" or #items == 0 then
        cb({ ok = false, error = "Aucun vêtement sélectionné." })
        return
    end

    local valid = {}
    for _, it in ipairs(items) do
        local v = validateItem(it)
        if v then valid[#valid + 1] = v end
    end
    if #valid == 0 then
        cb({ ok = false, error = "Aucun vêtement valide." })
        return
    end

    cb({ ok = true, total = #valid })

    outfitBatch = { items = valid, index = 1, awaitingPreview = false }
    outfitCaptureActive = true
    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = "imageManager:close" })
    Wait(300)

    outfitCaptureRestore = setupPlayerForOutfitCapture()
    spawnAndShowOutfit(valid[1])

    Wait(200)
    DoScreenFadeIn(500)
    Wait(500)

    startOrbitThread()
end)

-- ═══════════════════════════════════════════════════════════════
-- Outfit Screener NUI Callbacks
-- ═══════════════════════════════════════════════════════════════

RegisterNUICallback("outfitScreener:setHeight", function(data, cb)
    cb({ ok = true })
    if not outfitOrbitCenter then return end
    local step = (data.direction == "down") and -0.05 or 0.05
    outfitOrbitCenter = vector3(outfitOrbitCenter.x, outfitOrbitCenter.y, outfitOrbitCenter.z + step)
    outfitOrbitZOffset = (outfitOrbitZOffset or 0.0) + step
end)

RegisterNUICallback("outfitScreener:saveDefaultCam", function(_, cb)
    if not outfitCurrent or not outfitCurrent.category then
        cb({ ok = false, error = "Aucune catégorie active." })
        return
    end
    saveCamPreset(outfitCurrent.category, {
        yaw      = outfitOrbitYaw,
        pitch    = outfitOrbitPitch,
        distance = outfitOrbitDistance,
        zOffset  = outfitOrbitZOffset or 0.0,
    })
    cb({ ok = true })
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Images',
        message = string.format("Cam par défaut enregistrée pour '%s'.", outfitCurrent.categoryLabel or outfitCurrent.category),
    })
end)

RegisterNUICallback("outfitScreener:capture", function(_, cb)
    cb({ ok = true })
    if not outfitCaptureActive or not outfitCapturePed then return end

    local item = outfitCurrent
    outfitCaptureActive = false

    VFW.Nui.Focus(false, false)
    outfitCaptureNuiFocused = false
    SendNUIMessage({ action = "outfitScreener:close" })
    Wait(100)

    setGreenColor(0, 255, 0)
    Wait(500)

    exports['screenshot-basic']:requestScreenshot(function(screenshotData)
        setGreenColor(0, 0, 0)

        local current, total = 1, 1
        if outfitBatch then
            outfitBatch.awaitingPreview = true
            current = outfitBatch.index
            total = #outfitBatch.items
        end
        SendNUIMessage({
            action = "outfitScreener:showPreview",
            data = {
                base64 = screenshotData,
                item = item,
                current = current,
                total = total,
            }
        })
        VFW.Nui.Focus(true, true)
    end)
end)

RegisterNUICallback("outfitScreener:retryBatch", function(_, cb)
    cb({ ok = true })
    if not outfitCapturePed then return end

    if outfitBatch then outfitBatch.awaitingPreview = false end
    outfitCaptureActive = true
    VFW.Nui.Focus(true, true)
    outfitCaptureNuiFocused = true
    SendNUIMessage({ action = "outfitScreener:hidePreview" })
    SendNUIMessage({
        action = "outfitScreener:open",
        data = {
            item = {
                id = outfitCurrent and outfitCurrent.id,
                label = outfitCurrent and (outfitCurrent.label or outfitCurrent.name) or "Vêtement",
                category = outfitCurrent and outfitCurrent.category,
                categoryLabel = (getCategoryConfig(outfitCurrent and outfitCurrent.category)).label,
                drawable = outfitCurrent and outfitCurrent.drawable,
                texture = outfitCurrent and outfitCurrent.texture,
            },
            batch = outfitBatch and { current = outfitBatch.index, total = #outfitBatch.items } or nil,
        }
    })
    startOrbitThread()
end)

RegisterNUICallback("outfitScreener:nextBatch", function(data, cb)
    cb({ ok = true })

    local doneLabel = (outfitCurrent and (outfitCurrent.label or outfitCurrent.name)) or "?"
  if data and data.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Images',
            message = string.format("Photo de '%s' uploadée.", doneLabel)
        })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Images',
            message = string.format("Échec upload pour '%s'.", doneLabel)
        })
    end

    if not outfitBatch then
        DoScreenFadeOut(500)
        Wait(600)
        cleanupOutfitCapture()
        restorePlayerAfterCapture()
        DoScreenFadeIn(500)
        Wait(500)
        if StaffMenu and StaffMenu.OpenImageManager then
            StaffMenu.OpenImageManager("vetements")
        end
        return
    end

    outfitBatch.awaitingPreview = false
    outfitBatch.index = outfitBatch.index + 1

    if outfitBatch.index <= #outfitBatch.items then
        cleanupCurrentPedOnly()
        Wait(150)
        outfitCaptureActive = true
        spawnAndShowOutfit(outfitBatch.items[outfitBatch.index])
        startOrbitThread()
    else
        DoScreenFadeOut(500)
        Wait(600)
        cleanupOutfitCapture()
        outfitBatch = nil
        restorePlayerAfterCapture()
        DoScreenFadeIn(500)
        Wait(500)
        if StaffMenu and StaffMenu.OpenImageManager then
            StaffMenu.OpenImageManager("vetements")
        end
    end
end)

RegisterNUICallback("outfitScreener:finish", function(_, cb)
    cb({ ok = true })
    if not outfitCaptureActive and not outfitBatch then return end

    outfitCaptureActive = false
    outfitBatch = nil

    DoScreenFadeOut(500)
    Wait(600)
    cleanupOutfitCapture()
    restorePlayerAfterCapture()
    DoScreenFadeIn(500)
    Wait(500)

    if StaffMenu and StaffMenu.OpenImageManager then
        StaffMenu.OpenImageManager("vetements")
    end
end)

RegisterNUICallback("outfitScreener:toggleFreecam", function(_, cb)
    cb({ ok = true })
    if not outfitCaptureActive then return end
    outfitCaptureNuiFocused = false
    SetNuiFocusKeepInput(true)
    VFW.Nui.Focus(true, false)
    SendNUIMessage({ action = "outfitScreener:freecamState", data = { freecam = true } })
end)

-- ═══════════════════════════════════════════════════════════════
-- Outfit Manifest — list every clothing/prop drawable available in-game
-- (vanilla + DLC + streamed addons) and tag those that already have a
-- photo on the CDN. Spawns hidden m+f freemode peds, enumerates the
-- native drawable counts, then diffs against the manifest returned
-- by vfw:server:getOutfitsManifest.
-- ═══════════════════════════════════════════════════════════════

-- ClothingCategory (NUI) -> { kind = "clothing"|"props", folder, comp_or_prop, label }
local OUTFIT_UI_CATEGORIES = {
    top        = { kind = "clothing", folder = "torso2",    component = 11, label = "Hauts" },
    undershirt = { kind = "clothing", folder = "undershirt", component = 8,  label = "T-shirts" },
    torso      = { kind = "clothing", folder = "torso",     component = 3,  label = "Bras" },
    pants      = { kind = "clothing", folder = "leg",       component = 4,  label = "Pantalons" },
    shoes      = { kind = "clothing", folder = "shoes",     component = 6,  label = "Chaussures" },
    bag        = { kind = "clothing", folder = "bags",      component = 5,  label = "Sacs" },
    armor      = { kind = "clothing", folder = "armor",     component = 9,  label = "Gilets" },
    decals     = { kind = "clothing", folder = "decals",    component = 10, label = "Plaques" },
    mask       = { kind = "clothing", folder = "mask",      component = 1,  label = "Masques" },
    accessory  = { kind = "clothing", folder = "accessory", component = 7,  label = "Accessoires" },
    hat        = { kind = "props",    folder = "hat",       prop      = 0,  label = "Chapeaux" },
    glasses    = { kind = "props",    folder = "glasses",   prop      = 1,  label = "Lunettes" },
    watch      = { kind = "props",    folder = "watch",     prop      = 6,  label = "Montres" },
    ear        = { kind = "props",    folder = "ear",       prop      = 2,  label = "Oreilles" },
    bracelet   = { kind = "props",    folder = "bracelet",  prop      = 7,  label = "Bracelets" },
}

local OUTFIT_SEX_TO_MODEL = {
    male   = "mp_m_freemode_01",
    female = "mp_f_freemode_01",
}

local CDN_OUTFIT_BASE = "https://cfx-nui-core/interface/brand/outfits_greenscreener"

-- Build a nested lookup idx[drawable][texture] = url from the manifest of one folder.
-- Accepts a map { ["<d>.webp"] = url, ["<d>_<t>.webp"] = url } (FiveManage, current
-- format) or a plain list of filenames (legacy local files → url built from folderUrl).
-- "<d>.<ext>" is texture 0, "<d>_<t>.<ext>" is drawable d / texture t; anything else is ignored.
local function indexFilesByDrawableTexture(files, folderUrl)
    local idx = {}
    if type(files) ~= "table" then return idx end
    local function put(fn, url)
        if type(fn) ~= "string" then return end
        local lower = fn:lower()
        local validExt = lower:sub(-5) == ".webp" or lower:sub(-4) == ".png"
          or lower:sub(-4) == ".jpg" or lower:sub(-5) == ".jpeg"
        if not validExt then return end
        if type(url) ~= "string" or not url:match("^https?://") then
            url = (folderUrl or "") .. fn
        end
        local d, t = fn:match("^(%d+)_(%d+)%.")
        if d and t then
            local nd, nt = tonumber(d), tonumber(t)
            if nd and nt then
                idx[nd] = idx[nd] or {}
                idx[nd][nt] = url
            end
        else
            local d2 = fn:match("^(%d+)%.")
            if d2 then
                local nd = tonumber(d2)
                if nd then
                    idx[nd] = idx[nd] or {}
                    if not idx[nd][0] then idx[nd][0] = url end
                end
            end
        end
    end
    if #files > 0 then
        for _, fn in ipairs(files) do put(fn, nil) end
    else
        for fn, url in pairs(files) do put(fn, url) end
    end
    return idx
end

-- Spawn a hidden ped of the given sex, run the enumerator, then delete.
-- Les packs addon (collections) ne s'attachent PAS à un ped créé à 7000 / -250 :
-- on réutilise le ped joueur s'il a le bon modèle, sinon on spawn à côté.
local function collectionCount(ped)
    if not ped or not DoesEntityExist(ped) or not GetPedCollectionsCount then return 0 end
    local ok, n = pcall(GetPedCollectionsCount, ped)
    if ok and type(n) == "number" and n > 0 then return n end
    return 0
end

local function waitPedCollections(ped, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 2500)
    local last = collectionCount(ped)
    while GetGameTimer() < deadline do
        last = collectionCount(ped)
        -- Un freemode avec DLC vanilla a déjà plusieurs collections.
        -- Les packs addon s'ajoutent ensuite : on attend qu'au moins les DLC soient là.
        if last >= 8 then return last end
        Wait(50)
    end
    return last
end

--- Nombre global de drawables (vanilla + DLC + packs addon).
local function getGlobalDrawableCount(ped, conf)
    local kind = conf.kind == "props" and "props" or "clothing"
    local index = kind == "props" and conf.prop or conf.component
    if VFW.PedDrawableCount then
        return VFW.PedDrawableCount(ped, kind, index)
    end
    if kind == "clothing" then
        return GetNumberOfPedDrawableVariations(ped, index) or 0
    end
    return GetNumberOfPedPropDrawableVariations(ped, index) or 0
end

local function getTextureCount(ped, conf, drawable)
    local kind = conf.kind == "props" and "props" or "clothing"
    local index = kind == "props" and conf.prop or conf.component
    if VFW.PedTextureCount then
        return VFW.PedTextureCount(ped, kind, index, drawable)
    end
    local numTex
    if kind == "clothing" then
        numTex = GetNumberOfPedTextureVariations(ped, index, drawable)
    else
        numTex = GetNumberOfPedPropTextureVariations(ped, index, drawable)
    end
    return (numTex and numTex > 0) and numTex or 1
end

local function withHiddenFreemodePed(sex, fn)
    local model = OUTFIT_SEX_TO_MODEL[sex]
    if not model then return end
    local hash = joaat(model)
    local playerPed = PlayerPedId()

    -- Même modèle que le joueur : collections addon déjà streamées.
    if DoesEntityExist(playerPed) and GetEntityModel(playerPed) == hash then
        local ok, err = pcall(fn, playerPed)
        if not ok then console.error("[OutfitManifest] enumerator error: " .. tostring(err)) end
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then
        console.warn("[OutfitManifest] failed to load " .. model)
        return
    end

    local spawnPos
    if DoesEntityExist(playerPed) then
        local c = GetEntityCoords(playerPed)
        spawnPos = vector3(c.x, c.y, c.z + 1.0)
    else
        spawnPos = vector3(0.0, 0.0, 80.0)
    end
    RequestCollisionAtCoord(spawnPos.x, spawnPos.y, spawnPos.z)

    local ped = CreatePed(4, hash, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, false, false)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDefaultComponentVariation(ped)
    waitPedCollections(ped, 2500)

    local ok, err = pcall(fn, ped)
    if not ok then console.error("[OutfitManifest] enumerator error: " .. tostring(err)) end

    if DoesEntityExist(ped) then DeleteEntity(ped) end
    SetModelAsNoLongerNeeded(hash)
end

local function enumerateForSex(sex, manifest, out)
    withHiddenFreemodePed(sex, function(ped)
        for catId, conf in pairs(OUTFIT_UI_CATEGORIES) do
            local folderUrl = CDN_OUTFIT_BASE .. "/" .. sex .. "/" .. conf.kind .. "/" .. conf.folder .. "/"
            local files = (manifest and manifest[sex] and manifest[sex][conf.kind] and manifest[sex][conf.kind][conf.folder]) or {}
            local idx = indexFilesByDrawableTexture(files, folderUrl)

            local drawableCount = getGlobalDrawableCount(ped, conf)

            if drawableCount and drawableCount > 0 then
                for d = 0, drawableCount - 1 do
                    local numTex = getTextureCount(ped, conf, d)

                    local missing = {}
                    local previewUrl = nil
                    local variantUrls = {}
                    for t = 0, numTex - 1 do
                        local url = idx[d] and idx[d][t]
                        if url then
                            previewUrl = previewUrl or url
                            variantUrls[tostring(t)] = url
                        else
                            missing[#missing + 1] = t
                        end
                    end

                    local hasPhoto = #missing == 0
                    if not previewUrl and idx[d] then
                        for _, url in pairs(idx[d]) do previewUrl = url break end
                    end

                    out[#out + 1] = {
                        id              = sex .. "_" .. catId .. "_" .. d,
                        category        = catId,
                        label           = string.format("%s #%d", conf.label or catId, d),
                        sex             = sex,
                        drawable        = d,
                        totalTextures   = numTex,
                        missingTextures = missing,
                        hasPhoto        = hasPhoto,
                        imageUrl        = previewUrl or "",
                        variantUrls     = variantUrls,
                    }
                end
            end
        end
    end)
end

-- Public client API: synchronous, returns full enumerated list (~1-3k entries).
-- Sorted: missing photos first (so staff can spot what to capture), then by sex/category/drawable.
function VFW.Staff_BuildOutfitsList(manifest)
    local out = {}
    enumerateForSex("male", manifest, out)
    enumerateForSex("female", manifest, out)

    table.sort(out, function(a, b)
        if a.hasPhoto ~= b.hasPhoto then return not a.hasPhoto end
        if a.sex ~= b.sex then return a.sex < b.sex end
        if a.category ~= b.category then return a.category < b.category end
        return a.drawable < b.drawable
    end)

    return out
end

RegisterNUICallback("imageManager:outfitPhotoDone", function(data, cb)
    cb({ ok = true })

    Wait(600)
    cleanupOutfitCapture()
    restorePlayerAfterCapture()
    DoScreenFadeIn(500)
    Wait(500)

    local label = (data and data.item and (data.item.label or data.item.name)) or "?"
  if data and data.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Images',
            message = string.format("Photo du vêtement '%s' uploadée !", label)
        })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Images',
            message = string.format("Échec upload pour '%s'.", label)
        })
    end
end)


-- ═══════════════════════════════════════════════════════════════
-- Capture automatique par lot — hub Gestion → Images → Vêtements →
-- « Générer les images ». Le staff choisit un sexe et une catégorie
-- (haut, bas, chaussures…) : chaque drawable/texture est habillé sur
-- un ped freemode devant la sphère verte, photographié, détouré par la
-- page NUI (fond vert → transparent, recadrage) puis uploadé par le
-- serveur sur FiveManage (URL mémorisée dans manifest.json).
-- Aucune interaction : Retour (Backspace) interrompt le lot.
-- ═══════════════════════════════════════════════════════════════

local autoJob = nil          -- { sex, category, conf, items = {{d,t}}, index, ok, fail, stop, drawing }
local autoSaveWaiters = {}   -- id -> promise (réponse serveur)

local function autoGuard()
    if not (StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["dev"] == true or perms["gestion_items"] == true or perms["staff"] == true or perms["server_management"] == true
end

local function autoNotify(variant, message)
    VFW.ShowNotification({ type = 'STAFF', variant = variant, subtitle = 'Images', message = message })
end

local function autoSend(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- Précharge le drawable (vêtements addon streamés) avant de l'appliquer.
local function autoDress(ped, conf, d, t)
    resetPedComponents(ped)
    if conf.kind == "props" then
        SetPedPreloadPropData(ped, conf.prop, d, t)
        local deadline = GetGameTimer() + 2000
        while not HasPedPreloadPropDataFinished(ped) and GetGameTimer() < deadline do Wait(0) end
        ReleasePedPreloadPropData(ped)
        SetPedPropIndex(ped, conf.prop, d, t, true)
    else
        SetPedPreloadVariationData(ped, conf.component, d, t)
        local deadline = GetGameTimer() + 2000
        while not HasPedPreloadVariationDataFinished(ped) and GetGameTimer() < deadline do Wait(0) end
        ReleasePedPreloadVariationData(ped)
        SetPedComponentVariation(ped, conf.component, d, t, 0)
    end
end

local function autoPlaceCam(category, pedCoords)
    local cat = getCategoryConfig(category)
    local preset = loadCamPreset(category)
    local zOffset = preset and preset.zOffset or cat.zOffset or 0.0
    local yaw = preset and preset.yaw or 180.0
    local pitch = preset and preset.pitch or cat.pitch or 0.0
    local dist = preset and preset.distance or cat.distance or 1.5
    local center = vector3(pedCoords.x, pedCoords.y, pedCoords.z + zOffset)
    local rad = math.rad
    local camX = center.x + dist * math.cos(rad(pitch)) * math.sin(rad(yaw))
    local camY = center.y + dist * math.cos(rad(pitch)) * math.cos(rad(yaw))
    local camZ = center.z + dist * math.sin(rad(pitch))
    outfitCaptureCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(outfitCaptureCam, camX, camY, camZ)
    PointCamAtCoord(outfitCaptureCam, center.x, center.y, center.z)
    SetCamActive(outfitCaptureCam, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function autoScreenshot()
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

-- Attend le retour de la page NUI (détourage) puis du serveur (écriture).
local function autoAwaitSave(id, timeoutMs)
    local p = promise.new()
    autoSaveWaiters[id] = p
    SetTimeout(timeoutMs or 30000, function()
        if autoSaveWaiters[id] == p then
            autoSaveWaiters[id] = nil
            p:resolve({ ok = false, error = "Délai dépassé (détourage / enregistrement)." })
        end
    end)
    return Citizen.Await(p)
end

local function autoResolve(id, result)
    local p = autoSaveWaiters[id]
    if not p then return end
    autoSaveWaiters[id] = nil
    p:resolve(result)
end

-- Texte de progression hors des frames photographiées (drawing = false autour de la capture).
local function autoHudThread(job)
    CreateThread(function()
        while autoJob == job do
            DisableControlAction(0, 200, true) -- Échap : pas de menu pause pendant le lot
            if IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
                job.stop = true
            end
            if job.drawing then
                local label = string.format("%s %s  —  %d / %d   (Retour : arrêter)",
                    job.conf.label, job.sex == "female" and "femme" or "homme", job.index or 0, #job.items)
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

local function autoFinish(job)
    job.drawing = false
    cleanupCurrentPedOnly()
    SetNuiFocusKeepInput(false)
    outfitCurrent = nil
    DisplayRadar(true)
    DisplayHud(true)
    VFW.Nui.HudVisible(true)
    outfitCaptureActive = false
    autoJob = nil

    DoScreenFadeOut(300)
    Wait(350)
    restorePlayerAfterCapture()
    DoScreenFadeIn(400)
    Wait(300)

    autoSend("gestion:images:generateDone", {
        ok = job.ok, fail = job.fail, total = #job.items,
        stopped = job.stop == true, sex = job.sex, category = job.category,
    })
    if StaffMenu and StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
    if StaffMenu and StaffMenu.OpenImageManager then StaffMenu.OpenImageManager("vetements") end

    if job.stop then
        autoNotify('INFO', string.format("Capture interrompue : %d image(s) enregistrée(s), %d échec(s).", job.ok, job.fail))
    else
        autoNotify(job.fail > 0 and 'ERROR' or 'SUCCESS',
            string.format("%d image(s) envoyée(s) sur FiveManage, %d échec(s).", job.ok, job.fail))
    end
end

local function autoRun(job)
    local conf = job.conf
    local hash = joaat(OUTFIT_SEX_TO_MODEL[job.sex])
    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(hash) then
        autoJob = nil
        outfitCaptureActive = false
        autoNotify('ERROR', "Impossible de charger le ped freemode.")
        if StaffMenu and StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
        return
    end

    if StaffMenu and StaffMenu.CoverGestionHub then StaffMenu.CoverGestionHub() end
    VFW.Nui.Focus(false, false)
    Wait(200)
    outfitCaptureRestore = setupPlayerForOutfitCapture()

    local pos = OUTFIT_CAPTURE_POS
    outfitCapturePed = CreatePed(4, hash, pos.x, pos.y, pos.z, 180.0, false, false)
    outfitCapturePedModel = OUTFIT_SEX_TO_MODEL[job.sex]
    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(outfitCapturePed, true)
    SetBlockingOfNonTemporaryEvents(outfitCapturePed, true)
    FreezeEntityPosition(outfitCapturePed, true)
    SetEntityCollision(outfitCapturePed, false, false)
    SetPedCanRagdoll(outfitCapturePed, false)
    SetPedDefaultComponentVariation(outfitCapturePed)
    SetEntityHeading(outfitCapturePed, 180.0)
    Wait(100)

    local pedCoords = GetEntityCoords(outfitCapturePed)
    startGreenScreen(pedCoords)
    setGreenColor(0, 255, 0)
    autoPlaceCam(job.category, pedCoords)
    Wait(300)
    DoScreenFadeIn(300)
    Wait(400)

    job.drawing = true
    autoHudThread(job)

    for i = 1, #job.items do
        if job.stop then break end
        local it = job.items[i]
        job.index = i
        autoDress(outfitCapturePed, conf, it.d, it.t)
        Wait(400)

        job.drawing = false
        Wait(60)
        local shot = autoScreenshot()
        job.drawing = true

        local id = string.format("%s_%s_%d_%d_%d", job.sex, job.category, it.d, it.t, GetGameTimer())
        if not shot then
            job.fail = job.fail + 1
        else
            autoSend("gestion:images:capture", {
                id = id, sex = job.sex, kind = conf.kind, folder = conf.folder,
                category = job.category, drawable = it.d, texture = it.t,
                index = i, total = #job.items, base64 = shot,
            })
            local res = autoAwaitSave(id, 30000)
            if res and res.ok then
                job.ok = job.ok + 1
                autoSend("gestion:images:progress", {
                    index = i, total = #job.items, sex = job.sex, category = job.category,
                    drawable = it.d, texture = it.t, url = res.url, ok = true,
                })
            else
                job.fail = job.fail + 1
                autoSend("gestion:images:progress", {
                    index = i, total = #job.items, sex = job.sex, category = job.category,
                    drawable = it.d, texture = it.t, ok = false, error = res and res.error,
                })
            end
        end
    end

    autoFinish(job)
end

RegisterNUICallback("gestion:images:generateOutfits", function(data, cb)
    if not autoGuard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les images." })
        return
    end
    if autoJob or isOutfitCaptureBusy() then
        cb({ ok = false, error = "Une capture est déjà en cours." })
        return
    end
    local sex = (data and data.sex == "female") and "female" or "male"
    local category = data and data.category
    local conf = category and OUTFIT_UI_CATEGORIES[category]
    if not conf then
        cb({ ok = false, error = "Catégorie inconnue." })
        return
    end
    local onlyMissing = not (data and data.onlyMissing == false)

    cb({ ok = true })

    CreateThread(function()
        -- Liste des drawables / textures à photographier
        local idx = {}
        if onlyMissing then
            local manifest = TriggerServerCallback("vfw:server:getOutfitsManifest") or {}
            local files = (manifest[sex] and manifest[sex][conf.kind] and manifest[sex][conf.kind][conf.folder]) or {}
            idx = indexFilesByDrawableTexture(files, CDN_OUTFIT_BASE .. "/" .. sex .. "/" .. conf.kind .. "/" .. conf.folder .. "/")
        end
        local items = {}
        withHiddenFreemodePed(sex, function(ped)
            local count = getGlobalDrawableCount(ped, conf)
            for d = 0, (count or 0) - 1 do
                local numTex = getTextureCount(ped, conf, d)
                for t = 0, numTex - 1 do
                    if not (idx[d] and idx[d][t]) then
                        items[#items + 1] = { d = d, t = t }
                    end
                end
            end
        end)

        if #items == 0 then
            autoNotify('INFO', "Rien à capturer : toutes les images existent déjà.")
            autoSend("gestion:images:generateDone", { ok = 0, fail = 0, total = 0, sex = sex, category = category })
            return
        end

        autoJob = { sex = sex, category = category, conf = conf, items = items, index = 0, ok = 0, fail = 0, stop = false, drawing = false }
        outfitCaptureActive = true
        autoRun(autoJob)
    end)
end)

RegisterNUICallback("gestion:images:generateStop", function(_, cb)
    cb({ ok = true })
    if autoJob then autoJob.stop = true end
end)

-- Retour de la page NUI : image détourée (webp base64) → serveur.
RegisterNUICallback("gestion:images:captureProcessed", function(data, cb)
    cb({ ok = true })
    if not autoJob or type(data) ~= "table" or type(data.id) ~= "string" then return end
    if not data.ok or type(data.base64) ~= "string" or data.base64 == "" then
        autoResolve(data.id, { ok = false, error = data.error or "Détourage impossible." })
        return
    end
    TriggerServerEvent("core:outfits:saveCapture", {
        id = data.id, sex = autoJob.sex, kind = autoJob.conf.kind, folder = autoJob.conf.folder,
        drawable = tonumber(data.drawable), texture = tonumber(data.texture), base64 = data.base64,
    })
end)

RegisterNetEvent("core:outfits:saveResult", function(result)
    if type(result) ~= "table" or type(result.id) ~= "string" then return end
    autoResolve(result.id, result)
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() or not autoJob then return end
    autoJob.stop = true
    cleanupCurrentPedOnly()
    restorePlayerAfterCapture()
    DisplayRadar(true)
    DisplayHud(true)
end)
