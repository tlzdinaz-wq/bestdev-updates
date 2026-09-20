---@meta _
---@diagnostic disable: duplicate-doc-field

-- State variables
local saveVeh = nil
local lastJob = "bennys"
local vehicleInDB = false
local isCustomsOpen = false
local currentSocietyImage = nil
local isFreeCustomsMode = false

local neon = {
    left = false,
    right = false,
    front = false,
    back = false
}

local xenon = false
local turbo = false
local tireSmoke = false
local interiorIndex = 1
local dashbordColorIndex = 1

-- Camera system
local customsCam = nil
local camAngle = 0.0
local camHeight = 0.5
local camRadius = 4.0
local targetCamAngle = 0.0
local targetCamHeight = 0.5
local camZoomLevel = 0.7 -- Current zoom
local targetZoomLevel = 0.7 -- Target zoom for smooth interpolation
local cameraLocked = false -- G key: lock/unlock camera rotation
local doorsOpen = false -- Y key: toggle all doors

-- Custom Prices System (percentage-based with overrides)
local CustomPricesCache = {
    basePrices = {},
    categoryModifiers = {},
    categoryOverrides = {},
    modelModifiers = {},
    modelOverrides = {}
}

local currentVehicleModel = ""
local currentVehicleCategory = "" -- concess category name
local pendingModifications = {} -- Track modifications made during session
local totalModificationCost = 0

-- Receive price sync from server
RegisterNetEvent('customPrices:syncConfig')
AddEventHandler('customPrices:syncConfig', function(data)
    CustomPricesCache = data or {
        basePrices = {},
        categoryModifiers = {},
        categoryOverrides = {},
        modelModifiers = {},
        modelOverrides = {}
    }
end)

--- Get price for a modification
--- Formula: base × (1 + category%) × (1 + model%)
--- Overrides per mod type take priority over global percentages
---@param modType string The modification type
---@param level number Optional level for performance mods
---@return number price The calculated price
local function GetModPrice(modType, level)
    level = level or 0
    local modelLower = currentVehicleModel and string.lower(currentVehicleModel) or ""
    local categoryName = currentVehicleCategory or ""

    -- Get base price
    local baseConfig = CustomPricesCache.basePrices[modType]
    local basePrice = 1000 -- Fallback
    if baseConfig then
        basePrice = baseConfig.base_price + (baseConfig.price_per_level * level)
    end

    -- Get category modifier: override per mod type > global percentage
    local categoryModifier = 0
    if CustomPricesCache.categoryOverrides[categoryName] and CustomPricesCache.categoryOverrides[categoryName][modType] then
        categoryModifier = CustomPricesCache.categoryOverrides[categoryName][modType]
    elseif CustomPricesCache.categoryModifiers[categoryName] then
        categoryModifier = CustomPricesCache.categoryModifiers[categoryName]
    end

    -- Get model modifier: override per mod type > global percentage
    local modelModifier = 0
    if CustomPricesCache.modelOverrides[modelLower] and CustomPricesCache.modelOverrides[modelLower][modType] then
        modelModifier = CustomPricesCache.modelOverrides[modelLower][modType]
    elseif CustomPricesCache.modelModifiers[modelLower] then
        modelModifier = CustomPricesCache.modelModifiers[modelLower]
    end

    -- Calculate final price: base × (1 + category%) × (1 + model%)
    local finalPrice = basePrice * (1 + categoryModifier / 100) * (1 + modelModifier / 100)

    return math.floor(finalPrice)
end

--- Get all prices for sending to NUI
local function GetAllPrices()
    local prices = {}
    local modelLower = currentVehicleModel and string.lower(currentVehicleModel) or ""
    local categoryName = currentVehicleCategory or ""

    -- Get global modifiers
    local globalCategoryModifier = CustomPricesCache.categoryModifiers[categoryName] or 0
    local globalModelModifier = CustomPricesCache.modelModifiers[modelLower] or 0
    local categoryOverrides = CustomPricesCache.categoryOverrides[categoryName] or {}
    local modelOverrides = CustomPricesCache.modelOverrides[modelLower] or {}

    local modTypes = {
        "engine", "brakes", "transmission", "suspension", "turbo",
        "spoiler", "front_bumper", "rear_bumper", "side_skirts", "exhaust",
        "grille", "hood", "fender", "roof",
        "primary_color", "secondary_color", "pearlescent",
        "wheel_type", "wheel_model", "wheel_color", "tire_smoke",
        "xenon", "xenon_color", "neon", "neon_color",
        "window_tint", "interior_color", "dashboard_color",
        "plate_style", "livery", "horn"
    }

    for _, modType in ipairs(modTypes) do
        local baseConfig = CustomPricesCache.basePrices[modType]
        local basePrice = baseConfig and baseConfig.base_price or 1000
        local pricePerLevel = baseConfig and baseConfig.price_per_level or 0

        -- Get modifier for this specific mod type (override > global)
        local categoryModifier = categoryOverrides[modType] or globalCategoryModifier
        local modelModifier = modelOverrides[modType] or globalModelModifier
        local multiplier = (1 + categoryModifier / 100) * (1 + modelModifier / 100)

        prices[modType] = {
            base = math.floor(basePrice * multiplier),
            perLevel = math.floor(pricePerLevel * multiplier)
        }
    end

    return prices
end

--- Reset pending modifications
local function ResetPendingModifications()
    pendingModifications = {}
    totalModificationCost = 0
end

--- Add a pending modification
local function AddPendingModification(modType, price, description)
    -- Check if modification already exists, update it
    for i, mod in ipairs(pendingModifications) do
        if mod.type == modType then
            totalModificationCost = totalModificationCost - mod.price + price
            pendingModifications[i] = { type = modType, price = price, description = description }
            return
        end
    end
    -- Add new modification
    pendingModifications[#pendingModifications + 1] = { type = modType, price = price, description = description }
    totalModificationCost = totalModificationCost + price
end

--- Send updated cost to NUI
local function SendCostUpdate()
    SendNUIMessage({
        action = "nui:vehicleCustoms:updateCost",
        data = {
            totalCost = totalModificationCost,
            modifications = pendingModifications
        }
    })
end

--- Remove a pending modification by type
local function RemovePendingModification(modType)
    for i, mod in ipairs(pendingModifications) do
        if mod.type == modType then
            totalModificationCost = totalModificationCost - mod.price
            table.remove(pendingModifications, i)
            return true
        end
    end
    return false
end

-- Color data for headlights
local headlightColors = {
    { name = "Origine", id = -1 },
    { name = "Blanc", id = 0 },
    { name = "Bleu", id = 1 },
    { name = "Bleu électrique", id = 2 },
    { name = "Vert menthe", id = 3 },
    { name = "Vert citron", id = 4 },
    { name = "Jaune", id = 5 },
    { name = "Or jaune", id = 6 },
    { name = "Orange", id = 7 },
    { name = "Rouge", id = 8 },
    { name = "Rose poney", id = 9 },
    { name = "Rose vif", id = 10 },
    { name = "Violet", id = 11 },
    { name = "Lumière noire", id = 12 }
}

--- all_trim
---@param s any
---@return any
local function all_trim(s)
    return s:match("^%s*(.-)%s*$")
end

--- ResetVehicleToStock
---@param vehicle number
local function ResetVehicleToStock(vehicle)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleModKit(vehicle, 0)

    for i = 0, 49 do
        SetVehicleMod(vehicle, i, -1, false)
    end

    ToggleVehicleMod(vehicle, 18, false)
    ToggleVehicleMod(vehicle, 20, false)
    ToggleVehicleMod(vehicle, 22, false)

    SetVehicleColours(vehicle, 0, 0)
    ClearVehicleCustomPrimaryColour(vehicle)
    ClearVehicleCustomSecondaryColour(vehicle)
    SetVehicleExtraColours(vehicle, 0, 0)

    SetVehicleInteriorColor(vehicle, 0)
    SetVehicleDashboardColor(vehicle, 0)

    for i = 0, 3 do
        SetVehicleNeonLightEnabled(vehicle, i, false)
    end

    SetVehicleWindowTint(vehicle, 0)
    SetVehicleWheelType(vehicle, 0)
    SetVehicleXenonLightsColor(vehicle, -1)

    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            SetVehicleExtra(vehicle, i, true)
        end
    end
end

--- Get vehicle extras
---@param vehicle number
---@return table
local function GetVehicleExtras(vehicle)
    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            table.insert(extras, {
                id = i,
                enabled = IsVehicleExtraTurnedOn(vehicle, i)
            })
        end
    end
    return extras
end

--- Get vehicle liveries
---@param vehicle number
---@return table
local function GetVehicleLiveries(vehicle)
    local liveries = {}
    local count = GetVehicleLiveryCount(vehicle)

    if count > 0 then
        for i = 0, count - 1 do
            local name = GetLabelText(GetLiveryName(vehicle, i))
            if name == "NULL" then
                name = "Motif " .. (i + 1)
            end
            table.insert(liveries, {
                id = i,
                name = name
            })
        end
    end

    -- Also check mod liveries (index 48)
    local modCount = GetNumVehicleMods(vehicle, 48)
    if modCount > 0 then
        for i = 0, modCount - 1 do
            local name = GetLabelText(GetModTextLabel(vehicle, 48, i))
            if name == "NULL" then
                name = "Motif " .. (i + 1)
            end
            table.insert(liveries, {
                id = i,
                name = name,
                isMod = true
            })
        end
    end

    return liveries
end

--- Get aesthetic mods
---@param vehicle number
---@return table
local function GetAestheticMods(vehicle)
    local mods = {}
    local aestheticIndices = {
        { index = 0, name = "Spoiler" },
        { index = 1, name = "Pare-chocs avant" },
        { index = 2, name = "Pare-chocs arrière" },
        { index = 3, name = "Jupes latérales" },
        { index = 4, name = "Échappement" },
        { index = 5, name = "Arceau" },
        { index = 6, name = "Grille" },
        { index = 7, name = "Capot" },
        { index = 8, name = "Aile gauche" },
        { index = 9, name = "Aile droite" },
        { index = 10, name = "Toit" },
        { index = 25, name = "Plaque avant" },
        { index = 27, name = "Garniture" },
        { index = 28, name = "Ornements" },
        { index = 29, name = "Tableau de bord" },
        { index = 30, name = "Cadran" },
        { index = 31, name = "Porte" },
        { index = 32, name = "Sièges" },
        { index = 33, name = "Volant" },
        { index = 34, name = "Levier de vitesse" },
        { index = 35, name = "Plaques" },
        { index = 36, name = "Haut-parleurs" },
        { index = 37, name = "Coffre" },
        { index = 38, name = "Hydrauliques" },
        { index = 39, name = "Bloc moteur" },
        { index = 40, name = "Filtre à air" },
        { index = 41, name = "Entretoises" },
        { index = 42, name = "Cache-soupapes" },
        { index = 43, name = "Arceau" },
        { index = 44, name = "Antenne" },
        { index = 45, name = "Garniture ext." },
        { index = 46, name = "Réservoir" },
        { index = 47, name = "Porte gauche" },
    }

    for _, mod in ipairs(aestheticIndices) do
        local numMods = GetNumVehicleMods(vehicle, mod.index)
        if numMods > 0 then
            local currentMod = GetVehicleMod(vehicle, mod.index)
            local currentName = "Stock"
            if currentMod >= 0 then
                currentName = GetLabelText(GetModTextLabel(vehicle, mod.index, currentMod))
                if currentName == "NULL" then
                    currentName = "Mod " .. (currentMod + 1)
                end
            end
            table.insert(mods, {
                type = mod.index,
                name = mod.name,
                currentValue = currentName,
                currentIndex = currentMod,
                count = numMods
            })
        end
    end

    return mods
end

--- Get interior mods
---@param vehicle number
---@return table
local function GetInteriorMods(vehicle)
    local mods = {}
    local interiorIndices = {
        { index = 29, name = "Tableau de bord" },
        { index = 30, name = "Cadran" },
        { index = 31, name = "Porte" },
        { index = 32, name = "Sièges" },
        { index = 33, name = "Volant" },
        { index = 34, name = "Levier de vitesse" },
    }

    for _, mod in ipairs(interiorIndices) do
        local numMods = GetNumVehicleMods(vehicle, mod.index)
        if numMods > 0 then
            local currentMod = GetVehicleMod(vehicle, mod.index)
            local currentName = "Stock"
            if currentMod >= 0 then
                currentName = GetLabelText(GetModTextLabel(vehicle, mod.index, currentMod))
                if currentName == "NULL" then
                    currentName = "Mod " .. (currentMod + 1)
                end
            end
            table.insert(mods, {
                type = mod.index,
                name = mod.name,
                currentValue = currentName,
                currentIndex = currentMod,
                count = numMods
            })
        end
    end

    return mods
end

--- Get wheel models for current wheel type
---@param vehicle number
---@return table
local function GetWheelModels(vehicle)
    local models = {}
    local numMods = GetNumVehicleMods(vehicle, 23)

    for i = 0, numMods - 1 do
        local name = GetLabelText(GetModTextLabel(vehicle, 23, i))
        if name == "NULL" then
            name = "Jante " .. (i + 1)
        end
        table.insert(models, {
            id = i,
            name = name
        })
    end

    return models
end

-- ============================================
-- CAMERA SYSTEM
-- ============================================

--- Create and start the customs camera
local function StartCustomsCamera(vehicle)
    if customsCam then
        DestroyCam(customsCam, false)
    end

    -- Get vehicle dimensions for optimal camera positioning
    local model = GetEntityModel(vehicle)
    local min, max = GetModelDimensions(model)
    local vehicleLength = max.y - min.y
    local vehicleHeight = max.z - min.z
    local vehicleWidth = max.x - min.x

    -- Calculate optimal camera distance based on vehicle size (closer)
    local maxDimension = math.max(vehicleLength, vehicleWidth)
    camRadius = maxDimension * 1.2 + 1.5
    camHeight = vehicleHeight * 0.5 + 0.6
    camAngle = 145.0 -- Start at front-left angle (3/4 view)
    targetCamAngle = camAngle
    targetCamHeight = camHeight
    camZoomLevel = 0.75 -- Closer
    targetZoomLevel = 0.75

    -- Create the camera
    customsCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    -- Position camera initially
    local vehCoords = GetEntityCoords(vehicle)
    local camX = vehCoords.x + (camRadius * math.cos(math.rad(camAngle)))
    local camY = vehCoords.y + (camRadius * math.sin(math.rad(camAngle)))
    local camZ = vehCoords.z + camHeight

    SetCamCoord(customsCam, camX, camY, camZ)
    PointCamAtCoord(customsCam, vehCoords.x, vehCoords.y, vehCoords.z + vehicleHeight * 0.3)
    SetCamFov(customsCam, 50.0)

    -- Smooth transition from gameplay camera
    SetCamActive(customsCam, true)
    RenderScriptCams(true, true, 1000, true, false)

    -- Start camera update thread
    CreateThread(function()
        while isCustomsOpen and customsCam do
            local vehicle = VFW.PlayerData.vehicle
            if not DoesEntityExist(vehicle) then break end

            local vehCoords = GetEntityCoords(vehicle)
            local vehModel = GetEntityModel(vehicle)
            local minDim, maxDim = GetModelDimensions(vehModel)
            local vehHeight = maxDim.z - minDim.z

            -- Smooth interpolation to target angle
            local angleDiff = targetCamAngle - camAngle
            if angleDiff > 180 then angleDiff = angleDiff - 360 end
            if angleDiff < -180 then angleDiff = angleDiff + 360 end
            camAngle = camAngle + angleDiff * 0.08

            -- Smooth height interpolation
            camHeight = camHeight + (targetCamHeight - camHeight) * 0.08

            -- Smooth zoom interpolation
            camZoomLevel = camZoomLevel + (targetZoomLevel - camZoomLevel) * 0.08

            -- Calculate camera position with zoom
            local effectiveRadius = camRadius * camZoomLevel
            local camX = vehCoords.x + (effectiveRadius * math.cos(math.rad(camAngle)))
            local camY = vehCoords.y + (effectiveRadius * math.sin(math.rad(camAngle)))
            local camZ = vehCoords.z + camHeight

            -- Update camera position and look at vehicle center
            SetCamCoord(customsCam, camX, camY, camZ)
            PointCamAtCoord(customsCam, vehCoords.x, vehCoords.y, vehCoords.z + vehHeight * 0.3)

            Wait(0)
        end
    end)
end

-- Track if doors are open for interior view
local interiorDoorsOpen = false

--- Stop and destroy the customs camera
local function StopCustomsCamera()
    -- Close doors if they were opened for interior view
    local vehicle = VFW.PlayerData.vehicle
    if vehicle and DoesEntityExist(vehicle) and interiorDoorsOpen then
        SetVehicleDoorShut(vehicle, 0, false)
        interiorDoorsOpen = false
    end

    if customsCam then
        -- Smooth transition back to gameplay camera
        RenderScriptCams(false, true, 500, true, false)
        Wait(500)
        DestroyCam(customsCam, false)
        customsCam = nil
    end
    camAngle = 0.0
end

--- Set camera to a specific preset angle
---@param preset string "front", "back", "left", "right", "front_left", "front_right", "top", "wheel_front", "wheel_back", "interior"
local function SetCameraPreset(preset)
    local presets = {
        front = { angle = 180.0, height = 0.6, zoom = 0.7 },
        back = { angle = 0.0, height = 0.6, zoom = 0.7 },
        left = { angle = 90.0, height = 0.5, zoom = 0.65 },
        right = { angle = 270.0, height = 0.5, zoom = 0.65 },
        front_left = { angle = 145.0, height = 0.7, zoom = 0.75 },
        front_right = { angle = 215.0, height = 0.7, zoom = 0.75 },
        back_left = { angle = 35.0, height = 0.6, zoom = 0.75 },
        back_right = { angle = 325.0, height = 0.6, zoom = 0.75 },
        top = { angle = camAngle, height = 2.0, zoom = 0.9 },
        wheel_front = { angle = 155.0, height = 0.0, zoom = 0.35 },
        wheel_back = { angle = 25.0, height = 0.0, zoom = 0.35 },
        interior = { angle = 70.0, height = 0.8, zoom = 0.28 }
    }

    local p = presets[preset]
    if p then
        targetCamAngle = p.angle
        targetCamHeight = camHeight * 0.3 + p.height * 2
        targetZoomLevel = p.zoom
    end

    -- Handle doors for interior view
    local vehicle = VFW.PlayerData.vehicle
    if vehicle and DoesEntityExist(vehicle) then
        if preset == "interior" then
            -- Open driver door for interior view
            if not interiorDoorsOpen then
                SetVehicleDoorOpen(vehicle, 0, false, false) -- Driver door
                interiorDoorsOpen = true
            end
        else
            -- Close doors when leaving interior view
            if interiorDoorsOpen then
                SetVehicleDoorShut(vehicle, 0, false) -- Driver door
                interiorDoorsOpen = false
            end
        end
    end
end


--- Open the customs NUI
local function OpenCustomsNUI()
    local vehicle = VFW.PlayerData.vehicle
    if not DoesEntityExist(vehicle) then return end

    local image = TriggerServerCallback("core:get:societyImage")
    currentSocietyImage = image

    isCustomsOpen = true

    -- Reset pending modifications
    ResetPendingModifications()

    -- Get vehicle info for price calculation
    local vehicleModel = GetEntityModel(vehicle)
    currentVehicleModel = GetDisplayNameFromVehicleModel(vehicleModel)
    currentVehicleCategory = TriggerServerCallback('customPrices:getVehicleCategory', currentVehicleModel) or ""

    -- Get current vehicle state
    neon = {
        left = IsVehicleNeonLightEnabled(vehicle, 0),
        right = IsVehicleNeonLightEnabled(vehicle, 1),
        front = IsVehicleNeonLightEnabled(vehicle, 2),
        back = IsVehicleNeonLightEnabled(vehicle, 3)
    }
    xenon = IsToggleModOn(vehicle, 22)
    turbo = IsToggleModOn(vehicle, 18)
    tireSmoke = IsToggleModOn(vehicle, 20)
    interiorIndex = GetVehicleInteriorColor(vehicle) or 0
    dashbordColorIndex = GetVehicleDashboardColor(vehicle) or 0

    -- Get performance levels
    local perfLevels = {
        engine = GetVehicleMod(vehicle, 11),
        brakes = GetVehicleMod(vehicle, 12),
        transmission = GetVehicleMod(vehicle, 13),
        suspension = GetVehicleMod(vehicle, 15)
    }

    SetVehicleModKit(vehicle, 0)
    FreezeEntityPosition(vehicle, true)

    -- Force headlights on for better visibility
    SetVehicleLights(vehicle, 2)

    -- Start cinematic camera
    StartCustomsCamera(vehicle)

    -- Reset keybind states
    cameraLocked = false
    doorsOpen = false

    -- Get all prices for this vehicle
    local prices = GetAllPrices()

    -- Send open event to NUI
    SendNUIMessage({
        action = "nui:vehicleCustoms:open",
        data = {
            societyImage = image,
            vehicle = {
                name = GetLabelText(currentVehicleModel),
                model = currentVehicleModel,
                className = currentVehicleCategory or "unknown",
                plate = all_trim(GetVehicleNumberPlateText(vehicle))
            },
            turbo = turbo,
            xenon = xenon,
            tireSmoke = tireSmoke,
            neon = neon,
            perfLevels = perfLevels,
            interiorColor = interiorIndex,
            dashboardColor = dashbordColorIndex,
            windowTint = GetVehicleWindowTint(vehicle) or 0,
            prices = prices,
            totalCost = 0
        }
    })

    -- Send extras
    SendNUIMessage({
        action = "nui:vehicleCustoms:setExtras",
        data = GetVehicleExtras(vehicle)
    })

    -- Send liveries
    SendNUIMessage({
        action = "nui:vehicleCustoms:setLiveries",
        data = GetVehicleLiveries(vehicle)
    })

    -- Send aesthetic mods
    SendNUIMessage({
        action = "nui:vehicleCustoms:setAestheticMods",
        data = GetAestheticMods(vehicle)
    })

    -- Send interior mods
    SendNUIMessage({
        action = "nui:vehicleCustoms:setInteriorMods",
        data = GetInteriorMods(vehicle)
    })

    -- Send wheel models
    SendNUIMessage({
        action = "nui:vehicleCustoms:setWheelModels",
        data = GetWheelModels(vehicle)
    })

    -- Send horn data
    local numHorns = GetNumVehicleMods(vehicle, 14)
    if numHorns > 0 then
        local horns = {}
        for i = 0, numHorns - 1 do
            local label = GetLabelText(GetModTextLabel(vehicle, 14, i))
            if label == "NULL" or label == "" then
                label = "Klaxon " .. (i + 1)
            end
            horns[#horns + 1] = { id = i, name = label }
        end
        SendNUIMessage({
            action = "nui:vehicleCustoms:setHornData",
            data = {
                currentHorn = GetVehicleMod(vehicle, 14),
                horns = horns
            }
        })
    end

    VFW.Nui.HudVisible(false)
    VFW.Nui.Focus(true, false)
    TriggerEvent("pma-voice:toggleUi", false)
end

--- Close the customs NUI
local function CloseCustomsNUI(revert)
    if not isCustomsOpen then return end

    isCustomsOpen = false
    cameraLocked = false
    isFreeCustomsMode = false

    -- Close doors if they were opened via Y key
    if doorsOpen then
        local vehicle = VFW.PlayerData.vehicle
        if vehicle and DoesEntityExist(vehicle) then
            SetVehicleDoorsShut(vehicle, false)
        end
        doorsOpen = false
    end

    -- Stop cinematic camera first
    StopCustomsCamera()

    SendNUIMessage({
        action = "nui:vehicleCustoms:close",
        data = {}
    })

    VFW.Nui.Focus(false, false)
    VFW.Nui.HudVisible(true)
    TriggerEvent("pma-voice:toggleUi", true)

    if VFW.PlayerData.vehicle and DoesEntityExist(VFW.PlayerData.vehicle) then
        FreezeEntityPosition(VFW.PlayerData.vehicle, false)

        -- Restore headlights to normal mode
        SetVehicleLights(VFW.PlayerData.vehicle, 0)

        if revert and saveVeh then
            local veh = VFW.PlayerData.vehicle
            ClearVehicleCustomPrimaryColour(veh)
            ClearVehicleCustomSecondaryColour(veh)
            VFW.Game.SetVehicleProperties(veh, saveVeh)

            SetVehicleModKit(veh, 0)

            local tint = saveVeh.windowTint
            if tint == nil or tint == -1 then tint = 0 end
            SetVehicleWindowTint(veh, tint)

            if saveVeh.extras then
                for extraId = 0, 20 do
                    if DoesExtraExist(veh, extraId) then
                        local wasOn = saveVeh.extras[tostring(extraId)]
                        if wasOn ~= nil then
                            SetVehicleExtra(veh, extraId, wasOn and 0 or 1)
                        end
                    end
                end
            end

            ToggleVehicleMod(veh, 18, saveVeh.modTurbo and true or false)
            ToggleVehicleMod(veh, 20, saveVeh.modSmokeEnabled and true or false)
            ToggleVehicleMod(veh, 22, saveVeh.modXenon and true or false)

            if saveVeh.neonEnabled then
                for i = 0, 3 do
                    SetVehicleNeonLightEnabled(veh, i, saveVeh.neonEnabled[i + 1] and true or false)
                end
            end
        end
    end
end

-- ============================================
-- CUSTOMS KEYBINDS (G = lock cam, Y = toggle doors)
-- ============================================

local function ToggleCameraLock()
    if not isCustomsOpen then return end
    cameraLocked = not cameraLocked
end

local function ToggleVehicleDoors()
    if not isCustomsOpen then return end
    local veh = VFW.PlayerData.vehicle
    if not veh or not DoesEntityExist(veh) then return end

    doorsOpen = not doorsOpen
    if doorsOpen then
        local numDoors = GetNumberOfVehicleDoors(veh)
        for i = 0, numDoors - 1 do
            SetVehicleDoorOpen(veh, i, false, false)
        end
        SetVehicleDoorOpen(veh, 4, false, false) -- hood
        SetVehicleDoorOpen(veh, 5, false, false) -- trunk
    else
        SetVehicleDoorsShut(veh, false)
    end
end

RegisterCommand('customs_lockcam', function()
    ToggleCameraLock()
end, false)
RegisterKeyMapping('customs_lockcam', 'Customs: Verrouiller la caméra', 'keyboard', 'g')

RegisterCommand('customs_toggledoors', function()
    ToggleVehicleDoors()
end, false)
RegisterKeyMapping('customs_toggledoors', 'Customs: Ouvrir/Fermer les portes', 'keyboard', 'y')

-- ============================================
-- NUI CALLBACKS
-- ============================================

-- Camera lock & doors NUI callbacks (for React buttons if needed)
RegisterNuiCallback("nui:vehicleCustoms:toggleCameraLock", function(_, cb)
    ToggleCameraLock()
    cb({ locked = cameraLocked })
end)

RegisterNuiCallback("nui:vehicleCustoms:toggleDoors", function(_, cb)
    ToggleVehicleDoors()
    cb({ doorsOpen = doorsOpen })
end)

-- Camera control callbacks
RegisterNuiCallback("nui:vehicleCustoms:setCameraPreset", function(data, cb)
    if data.preset then
        SetCameraPreset(data.preset)
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setCameraZoom", function(data, cb)
    if data.zoom and not cameraLocked then
        targetZoomLevel = math.max(0.3, math.min(1.5, data.zoom))
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:rotateCamera", function(data, cb)
    if data.delta and not cameraLocked then
        targetCamAngle = targetCamAngle + data.delta
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:cancel", function(_, cb)
    CloseCustomsNUI(true)
    cb("ok")
end)

-- Cart: Remove a single modification
RegisterNuiCallback("nui:vehicleCustoms:removeModification", function(data, cb)
    if data.modType then
        local removed = RemovePendingModification(data.modType)
        if removed then
            SendCostUpdate()
        end
    end
    cb("ok")
end)

-- Cart: Clear all modifications
RegisterNuiCallback("nui:vehicleCustoms:clearAllModifications", function(_, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) and saveVeh then
        -- Clear custom RGB overrides before reverting
        ClearVehicleCustomPrimaryColour(vehicle)
        ClearVehicleCustomSecondaryColour(vehicle)
        VFW.Game.SetVehicleProperties(vehicle, saveVeh)
    end
    ResetPendingModifications()
    SendCostUpdate()
    cb("ok")
end)

-- Pending customs data waiting for invoice payment
local pendingCustomsInvoice = nil

RegisterNuiCallback("nui:vehicleCustoms:validate", function(_, cb)
    local vehicle = VFW.PlayerData.vehicle

    if isFreeCustomsMode then
        if DoesEntityExist(vehicle) and saveVeh then
            local plate <const> = all_trim(GetVehicleNumberPlateText(vehicle))
            TriggerServerEvent("vehicleTuningBuilder:server:setTempProps", plate, saveVeh)
        end
        ResetPendingModifications()
        CloseCustomsNUI(false)
        cb("ok")
        return
    end

    if lastJob == "staff" and VFW.IsStaffCustomMode and VFW.IsStaffCustomMode() then
        local isPermanent = VFW.IsStaffCustomPermanent and VFW.IsStaffCustomPermanent() or false
        if VFW.ApplyStaffCustom then
            VFW.ApplyStaffCustom(isPermanent)
        end
        if VFW.ResetStaffCustomState then
            VFW.ResetStaffCustomState()
        end
        CloseCustomsNUI(false)
        cb("ok")
        return
    end

    -- Block validation if cart is empty
    if totalModificationCost == 0 and #pendingModifications == 0 then
        VFW.ShowNotification({
            type = 'JOB',
            title = VFW.PlayerData.job.label,
            subtitle = "Erreur",
            subtitleColor = "RED",
            image = currentSocietyImage,
            content = "Aucune modification à valider."
        })
        CloseCustomsNUI(true)
        cb("ok")
        return
    end

    -- Store all data needed for later validation (after client pays)
    local vehiclePlate = all_trim(GetVehicleNumberPlateText(vehicle))
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))

    pendingCustomsInvoice = {
        totalCost = totalModificationCost,
        modifications = {},
        invoiceItems = {},
        vehiclePlate = vehiclePlate,
        vehicleName = vehicleName,
        vehicleProps = VFW.Game.GetVehicleProperties(vehicle),
        originalProps = saveVeh,
        job = lastJob,
    }

    for _, mod in ipairs(pendingModifications) do
        pendingCustomsInvoice.modifications[#pendingCustomsInvoice.modifications + 1] = {
            type = mod.type, price = mod.price, description = mod.description
        }
        pendingCustomsInvoice.invoiceItems[#pendingCustomsInvoice.invoiceItems + 1] = {
            name = mod.description, price = mod.price, quantity = 1
        }
    end

    -- Get nearby players for invoice target selection
    local nearbyPlayers = VFW.Screen.GetNearbyPlayers()
    local nearbyIds = {}
    local distanceById = {}
    for _, p in ipairs(nearbyPlayers) do
        nearbyIds[#nearbyIds + 1] = p.serverId
        distanceById[p.serverId] = math.floor(p.distance * 10) / 10
    end

    local rpPlayers = TriggerServerCallback("society:customs:getNearbyPlayersNames", nearbyIds) or {}
    local playersList = {}
    for _, p in ipairs(rpPlayers) do
        playersList[#playersList + 1] = {
            id = p.id,
            name = p.name,
            distance = distanceById[p.id] or 0
        }
    end

    SendNUIMessage({
        action = "nui:vehicleCustoms:showInvoicePicker",
        data = playersList
    })

    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:sendInvoice", function(data, cb)
    local targetServerId = data.targetId
    local discountPercent = data.discountPercent or 0

    if targetServerId and pendingCustomsInvoice then
        pendingCustomsInvoice.discountPercent = discountPercent
        -- Send everything to server — server creates invoice, waits for payment, then validates
        TriggerServerEvent("customs:createInvoice", targetServerId, pendingCustomsInvoice)
    end

    pendingCustomsInvoice = nil
    CloseCustomsNUI(false)
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:skipInvoice", function(_, cb)
    pendingCustomsInvoice = nil
    CloseCustomsNUI(true)
    cb("ok")
end)

-- Server tells us the invoice was paid — now apply the customs
RegisterNetEvent("customs:invoicePaid", function()
    VFW.ShowNotification({
        type = 'JOB',
        title = VFW.PlayerData.job.label,
        subtitle = "Paiement reçu",
        subtitleColor = "GREEN",
        image = currentSocietyImage,
        content = "Le client a payé la facture, commande validée."
    })
end)

-- Server tells us the invoice was rejected — revert the vehicle
RegisterNetEvent("customs:invoiceRejected", function(plate, originalProps)
    VFW.ShowNotification({
        type = 'JOB',
        title = VFW.PlayerData.job.label,
        subtitle = "Facture refusée",
        subtitleColor = "RED",
        image = currentSocietyImage,
        content = "Le client n'a pas pu payer. Les modifications ont été annulées."
    })

    -- Try to find the vehicle by plate and revert its properties
    if plate and originalProps then
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            local vehPlate = all_trim(GetVehicleNumberPlateText(veh))
            if vehPlate == plate then
                ClearVehicleCustomPrimaryColour(veh)
                ClearVehicleCustomSecondaryColour(veh)
                VFW.Game.SetVehicleProperties(veh, originalProps)
                break
            end
        end
    end
end)

RegisterNuiCallback("nui:vehicleCustoms:reset", function(_, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        ResetVehicleToStock(vehicle)

        -- Reset pending modifications
        ResetPendingModifications()
        SendCostUpdate()

        VFW.ShowNotification({
            type = 'JOB',
            title = VFW.PlayerData.job.label,
            subtitle = "Réinitialisation",
            subtitleColor = "GREEN",
            image = currentSocietyImage,
            content = "Véhicule remis à l'état d'usine."
        })

        -- Refresh UI data
        SendNUIMessage({
            action = "nui:vehicleCustoms:setExtras",
            data = GetVehicleExtras(vehicle)
        })
        SendNUIMessage({
            action = "nui:vehicleCustoms:setAestheticMods",
            data = GetAestheticMods(vehicle)
        })
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:categoryChange", function(data, cb)
    cb("ok")
end)

-- Performance callbacks
RegisterNuiCallback("nui:vehicleCustoms:setTurbo", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        turbo = data.enabled
        ToggleVehicleMod(vehicle, 18, data.enabled)

        -- Track modification cost
        if data.enabled then
            local price = GetModPrice("turbo", 0)
            AddPendingModification("turbo", price, "Turbo")
            SendCostUpdate()
        end
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setModLevel", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if not DoesEntityExist(vehicle) then cb("ok") return end

    local modIndexMap = {
        engine = 11,
        brakes = 12,
        transmission = 13,
        suspension = 15
    }

    local modIndex = modIndexMap[data.mod]
    if modIndex then
        SetVehicleMod(vehicle, modIndex, data.level, false)

        -- Track modification cost
        local price = GetModPrice(data.mod, data.level)
        local modLabels = {
            engine = "Moteur",
            brakes = "Freins",
            transmission = "Transmission",
            suspension = "Suspension"
        }
        AddPendingModification(data.mod, price, modLabels[data.mod] or data.mod)
        SendCostUpdate()
    end
    cb("ok")
end)

-- Paint callbacks
-- Using custom RGB colors for more reliable results
RegisterNuiCallback("nui:vehicleCustoms:setPrimaryColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        if data.r and data.g and data.b then
            -- Use custom RGB color
            SetVehicleCustomPrimaryColour(vehicle, data.r, data.g, data.b)
        else
            -- Fallback to color ID
            local _, secondary = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, data.colorId, secondary)
        end

        -- Track modification cost
        local price = GetModPrice("primary_color", 0)
        AddPendingModification("primary_color", price, "Couleur primaire")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setSecondaryColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        if data.r and data.g and data.b then
            -- Use custom RGB color
            SetVehicleCustomSecondaryColour(vehicle, data.r, data.g, data.b)
        else
            -- Fallback to color ID
            local primary, _ = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, primary, data.colorId)
        end

        -- Track modification cost
        local price = GetModPrice("secondary_color", 0)
        AddPendingModification("secondary_color", price, "Couleur secondaire")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setPearlescent", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        local _, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, data.colorId, wheelColor)

        -- Track modification cost
        local price = GetModPrice("pearlescent", 0)
        AddPendingModification("pearlescent", price, "Nacré")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setWindowTint", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        local level = tonumber(data.level)
        if level and level >= 0 and level <= 6 then
            SetVehicleWindowTint(vehicle, level)
            local price = GetModPrice("window_tint", 0)
            AddPendingModification("window_tint", price, "Vitres teintées")
            SendCostUpdate()
        end
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setLivery", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        local liveryId = tonumber(data.liveryId)

        if liveryId == -1 then
            -- Reset : retire à la fois la livrée native et la livrée mod
            SetVehicleMod(vehicle, 48, -1, false)
            SetVehicleLivery(vehicle, -1)
            RemovePendingModification("livery")
            SendCostUpdate()
        else
            if data.isMod then
                SetVehicleMod(vehicle, 48, liveryId, false)
            else
                SetVehicleLivery(vehicle, liveryId)
            end

            local price = GetModPrice("livery", 0)
            AddPendingModification("livery", price, "Livrée")
            SendCostUpdate()
        end
    end
    cb("ok")
end)

-- Lights callbacks
RegisterNuiCallback("nui:vehicleCustoms:setXenon", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        xenon = data.enabled
        ToggleVehicleMod(vehicle, 22, data.enabled)

        -- Track modification cost
        if data.enabled then
            local price = GetModPrice("xenon", 0)
            AddPendingModification("xenon", price, "Xénon")
            SendCostUpdate()
        end
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setXenonColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleXenonLightsColor(vehicle, data.colorId)

        -- Track modification cost
        local price = GetModPrice("xenon_color", 0)
        AddPendingModification("xenon_color", price, "Couleur Xénon")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setNeon", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        local positionMap = {
            left = 0,
            right = 1,
            front = 2,
            back = 3
        }
        local index = positionMap[data.position]
        if index ~= nil then
            neon[data.position] = data.enabled
            SetVehicleNeonLightEnabled(vehicle, index, data.enabled)

            -- Track modification cost (only when enabling)
            if data.enabled then
                local price = GetModPrice("neon", 0)
                AddPendingModification("neon_" .. data.position, price, "Néon " .. data.position)
                SendCostUpdate()
            end
        end
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setNeonColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleNeonLightsColour(vehicle, data.r, data.g, data.b)

        -- Track modification cost
        local price = GetModPrice("neon_color", 0)
        AddPendingModification("neon_color", price, "Couleur Néon")
        SendCostUpdate()
    end
    cb("ok")
end)

-- Wheels callbacks
RegisterNuiCallback("nui:vehicleCustoms:setWheelType", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleWheelType(vehicle, data.wheelType)

        -- Send updated wheel models
        SendNUIMessage({
            action = "nui:vehicleCustoms:setWheelModels",
            data = GetWheelModels(vehicle)
        })

        -- Track modification cost
        local price = GetModPrice("wheel_type", 0)
        AddPendingModification("wheel_type", price, "Type de roues")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setWheelModel", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleMod(vehicle, 23, data.modelId, false)

        -- Track modification cost
        local price = GetModPrice("wheel_model", 0)
        AddPendingModification("wheel_model", price, "Modèle de roues")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setWheelColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        local pearlescent, _ = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, pearlescent, data.colorId)

        -- Track modification cost
        local price = GetModPrice("wheel_color", 0)
        AddPendingModification("wheel_color", price, "Couleur de roues")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setTireSmoke", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        tireSmoke = data.enabled
        ToggleVehicleMod(vehicle, 20, data.enabled)

        -- Track modification cost
        if data.enabled then
            local price = GetModPrice("tire_smoke", 0)
            AddPendingModification("tire_smoke", price, "Fumée de pneus")
            SendCostUpdate()
        end
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setSmokeColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleTyreSmokeColor(vehicle, data.r, data.g, data.b)

        -- Track modification cost (included in tire_smoke)
    end
    cb("ok")
end)

-- Interior callbacks
RegisterNuiCallback("nui:vehicleCustoms:setInteriorColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        interiorIndex = data.colorIndex
        SetVehicleInteriorColor(vehicle, data.colorIndex)

        -- Track modification cost
        local price = GetModPrice("interior_color", 0)
        AddPendingModification("interior_color", price, "Couleur intérieur")
        SendCostUpdate()
    end
    cb("ok")
end)

RegisterNuiCallback("nui:vehicleCustoms:setDashboardColor", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        dashbordColorIndex = data.colorIndex
        SetVehicleDashboardColor(vehicle, data.colorIndex)

        -- Track modification cost
        local price = GetModPrice("dashboard_color", 0)
        AddPendingModification("dashboard_color", price, "Couleur tableau de bord")
        SendCostUpdate()
    end
    cb("ok")
end)

-- Horn callback
RegisterNuiCallback("nui:vehicleCustoms:setHorn", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleMod(vehicle, 14, data.hornId, false)

        -- Preview horn sound (synced)
        TriggerServerEvent("core:vehicleCustoms:honkHorn", VehToNet(vehicle))

        local price = GetModPrice("horn", 0)
        AddPendingModification("horn", price, "Klaxon")
        SendCostUpdate()
    end
    cb("ok")
end)

-- Honk horn preview (E key)
RegisterNuiCallback("nui:vehicleCustoms:honkHorn", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        TriggerServerEvent("core:vehicleCustoms:honkHorn", VehToNet(vehicle))
    end
    cb("ok")
end)

-- Receive synced horn from server
RegisterNetEvent("core:vehicleCustoms:honkHornSync", function(netId)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        StartVehicleHorn(vehicle, 800, GetHashKey("NORMAL"), false)
    end
end)

-- Plate callback
RegisterNuiCallback("nui:vehicleCustoms:setPlateStyle", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleNumberPlateTextIndex(vehicle, data.style)

        -- Track modification cost
        local price = GetModPrice("plate_style", 0)
        AddPendingModification("plate_style", price, "Style de plaque")
        SendCostUpdate()
    end
    cb("ok")
end)

-- Extra callback
RegisterNuiCallback("nui:vehicleCustoms:setExtra", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleExtra(vehicle, data.extraId, not data.enabled)
        -- Extras are free - no cost tracking
    end
    cb("ok")
end)

-- Set individual mod callback (aesthetic mods)
RegisterNuiCallback("nui:vehicleCustoms:setMod", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleMod(vehicle, data.modType, data.value, false)

        -- Update the mods list
        SendNUIMessage({
            action = "nui:vehicleCustoms:setAestheticMods",
            data = GetAestheticMods(vehicle)
        })
        SendNUIMessage({
            action = "nui:vehicleCustoms:setInteriorMods",
            data = GetInteriorMods(vehicle)
        })

        -- Track modification cost based on mod type
        local modTypeMap = {
            [0] = "spoiler",
            [1] = "front_bumper",
            [2] = "rear_bumper",
            [3] = "side_skirts",
            [4] = "exhaust",
            [6] = "grille",
            [7] = "hood",
            [8] = "fender",
            [9] = "fender",
            [10] = "roof"
        }
        local modName = modTypeMap[data.modType]
        if modName then
            local price = GetModPrice(modName, 0)
            local modLabels = {
                spoiler = "Aileron",
                front_bumper = "Pare-chocs avant",
                rear_bumper = "Pare-chocs arrière",
                side_skirts = "Bas de caisse",
                exhaust = "Échappement",
                grille = "Grille",
                hood = "Capot",
                fender = "Ailes",
                roof = "Toit"
            }
            AddPendingModification(modName .. "_" .. data.modType, price, modLabels[modName] or modName)
            SendCostUpdate()
        end
    end
    cb("ok")
end)

-- Get current vehicle properties for saving
RegisterNuiCallback("nui:vehicleCustoms:getPropsForSave", function(_, cb)
    local vehicle = VFW.PlayerData.vehicle
    if not DoesEntityExist(vehicle) then
        cb({ success = false })
        return
    end

    local props = VFW.Game.GetVehicleProperties(vehicle)
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    local plate = all_trim(GetVehicleNumberPlateText(vehicle))

    cb({
        success = true,
        props = props,
        vehicleName = vehicleName,
        plate = plate
    })
end)

-- Apply a saved custom configuration
RegisterNuiCallback("nui:vehicleCustoms:applyCustom", function(data, cb)
    local vehicle = VFW.PlayerData.vehicle
    if not DoesEntityExist(vehicle) then
        cb("ok")
        return
    end

    if data.props then
        VFW.Game.SetVehicleProperties(vehicle, data.props)

        -- Fill cart by comparing fresh vehicle state with initial state (saveVeh)
        ResetPendingModifications()

        if saveVeh then
            local newProps = VFW.Game.GetVehicleProperties(vehicle)

            local propsToMod = {
                modEngine       = { mod = "engine",          label = "Moteur",                level = true },
                modBrakes       = { mod = "brakes",          label = "Freins",                level = true },
                modTransmission = { mod = "transmission",    label = "Transmission",          level = true },
                modSuspension   = { mod = "suspension",      label = "Suspension",            level = true },
                modTurbo        = { mod = "turbo",           label = "Turbo" },
                modSpoilers     = { mod = "spoiler",         label = "Aileron" },
                modFrontBumper  = { mod = "front_bumper",    label = "Pare-chocs avant" },
                modRearBumper   = { mod = "rear_bumper",     label = "Pare-chocs arrière" },
                modSideSkirt    = { mod = "side_skirts",     label = "Bas de caisse" },
                modExhaust      = { mod = "exhaust",         label = "Échappement" },
                modGrille       = { mod = "grille",          label = "Grille" },
                modHood         = { mod = "hood",            label = "Capot" },
                modFender       = { mod = "fender",          label = "Ailes" },
                modRightFender  = { mod = "fender",          label = "Ailes (droite)" },
                modRoof         = { mod = "roof",            label = "Toit" },
                modXenon        = { mod = "xenon",           label = "Xénon" },
                xenonColor      = { mod = "xenon_color",     label = "Couleur Xénon" },
                modFrontWheels  = { mod = "wheel_model",     label = "Modèle de roues" },
                wheels          = { mod = "wheel_type",      label = "Type de roues" },
                wheelColor      = { mod = "wheel_color",     label = "Couleur de roues" },
                modSmokeEnabled = { mod = "tire_smoke",      label = "Fumée de pneus" },
                windowTint      = { mod = "window_tint",     label = "Vitres teintées" },
                plateIndex      = { mod = "plate_style",     label = "Style de plaque" },
                modHorns        = { mod = "horn",            label = "Klaxon" },
                modLivery       = { mod = "livery",          label = "Livrée" },
                interiorColor   = { mod = "interior_color",  label = "Couleur intérieur" },
                dashboardColor  = { mod = "dashboard_color", label = "Couleur tableau de bord" },
            }

            for propName, info in pairs(propsToMod) do
                local oldVal = saveVeh[propName]
                local newVal = newProps[propName]
                if newVal ~= nil and oldVal ~= newVal then
                    local level = 0
                    if info.level and type(newVal) == "number" and newVal >= 0 then
                        level = newVal
                    end
                    AddPendingModification(info.mod, GetModPrice(info.mod, level), info.label)
                end
            end

            -- Colors (tables, need element-wise comparison)
            local function rgbChanged(a, b)
                if a and not b then return true end
                if b and not a then return true end
                if not a and not b then return false end
                return a[1] ~= b[1] or a[2] ~= b[2] or a[3] ~= b[3]
            end

            if rgbChanged(newProps.customPrimaryColor, saveVeh.customPrimaryColor)
                or (not newProps.customPrimaryColor and not saveVeh.customPrimaryColor and (newProps.color1 or 0) ~= (saveVeh.color1 or 0)) then
                AddPendingModification("primary_color", GetModPrice("primary_color", 0), "Couleur primaire")
            end

            if rgbChanged(newProps.customSecondaryColor, saveVeh.customSecondaryColor)
                or (not newProps.customSecondaryColor and not saveVeh.customSecondaryColor and (newProps.color2 or 0) ~= (saveVeh.color2 or 0)) then
                AddPendingModification("secondary_color", GetModPrice("secondary_color", 0), "Couleur secondaire")
            end

            if (newProps.pearlescentColor or 0) ~= (saveVeh.pearlescentColor or 0) then
                AddPendingModification("pearlescent", GetModPrice("pearlescent", 0), "Nacré")
            end

            if (newProps.livery or -1) ~= (saveVeh.livery or -1) then
                AddPendingModification("livery", GetModPrice("livery", 0), "Livrée")
            end

            if newProps.neonEnabled and saveVeh.neonEnabled then
                local positions = { "left", "right", "front", "back" }
                for i = 1, 4 do
                    if newProps.neonEnabled[i] ~= saveVeh.neonEnabled[i] and newProps.neonEnabled[i] then
                        AddPendingModification("neon_" .. positions[i], GetModPrice("neon", 0), "Néon " .. positions[i])
                    end
                end
            end

            if rgbChanged(newProps.neonColor, saveVeh.neonColor) then
                AddPendingModification("neon_color", GetModPrice("neon_color", 0), "Couleur Néon")
            end
        end

        SendCostUpdate()

        VFW.ShowNotification({
            type = 'JOB',
            title = VFW.PlayerData.job.label,
            subtitle = "Configuration",
            subtitleColor = "GREEN",
            image = currentSocietyImage,
            content = "Configuration appliquée."
        })

        -- Refresh all NUI data
        SendNUIMessage({
            action = "nui:vehicleCustoms:setExtras",
            data = GetVehicleExtras(vehicle)
        })
        SendNUIMessage({
            action = "nui:vehicleCustoms:setAestheticMods",
            data = GetAestheticMods(vehicle)
        })
        SendNUIMessage({
            action = "nui:vehicleCustoms:setInteriorMods",
            data = GetInteriorMods(vehicle)
        })
    end

    cb("ok")
end)

-- ============================================
-- MAIN FUNCTIONS (kept for compatibility)
-- ============================================

local function OpenCustomMenu()
    local vehicle = VFW.PlayerData.vehicle

    if not DoesEntityExist(vehicle) then
        local societyImage = TriggerServerCallback("core:get:societyImage")
        VFW.ShowNotification({
            type = 'JOB',
            title = VFW.PlayerData.job.label,
            subtitle = "Erreur",
            subtitleColor = "RED",
            image = societyImage,
            content = "Aucun véhicule détecté."
        })
        return
    end

    saveVeh = VFW.Game.GetVehicleProperties(vehicle)
    OpenCustomsNUI()
end

function Society.OpenFreeCustomsMenu()
    local ped <const> = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        VFW.ShowNotification({ type = "ROUGE", content = "Vous devez être dans un véhicule." })
        return
    end

    local vehicle <const> = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        VFW.ShowNotification({ type = "ROUGE", content = "Vous devez être au volant." })
        return
    end

    VFW.PlayerData.vehicle = vehicle
    saveVeh = VFW.Game.GetVehicleProperties(vehicle)
    lastJob = (VFW.PlayerData.job and VFW.PlayerData.job.name) or "bennys"
    isFreeCustomsMode = true

    OpenCustomsNUI()
end

-- ============================================
-- COMMAND MENU (for applying saved commands)
-- ============================================

local currentCommand = nil
local selected_command = nil
local selected_key = nil
local lastVeh = nil

local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/default.png")

local currentCustom_main = VUI:CreateMenu("ACTION DISPONIBLE", defaultBanner, true)
local currentCustom_category = VUI:CreateSubMenu(currentCustom_main, "ACTION DISPONIBLE", defaultBanner, true)
local submodifCustom = VUI:CreateSubMenu(currentCustom_main, "ACTION DISPONIBLE", defaultBanner, true)
local NewCustom = {}

local function BuildCustomModifMenu()
    for _, value in pairs(NewCustom) do
        submodifCustom.Separator(value.props)
    end
end

local function BuildCustomCategoryMenu()
    currentCustom_category.Button("Modification", "du véhicule", nil, "chevron", false, function() end, submodifCustom)

    currentCustom_category.Button("Appliquer", "les customs", nil, "chevron", false, function()
        if all_trim(GetVehicleNumberPlateText(lastVeh)) == selected_command.plate then
            VFW.Game.SetVehicleProperties(lastVeh, selected_command.props)
            TriggerServerEvent("core:removeCommandeMecano", selected_key, lastJob)
            TriggerServerEvent("core:SetPropsVeh", all_trim(GetVehicleNumberPlateText(lastVeh)),
                VFW.Game.GetVehicleProperties(lastVeh))
            currentCustom_category.close()
        end
    end)

    currentCustom_category.Button("Supprimer", "la commande", nil, "chevron", false, function()
        TriggerServerEvent("core:removeCommandeMecano", selected_key, lastJob)
        currentCustom_category.close()
    end)
end

local function BuildCustomMenu()
    currentCommand = TriggerServerCallback("core:GetCommandeMecanoCb", lastJob)

    for k, v in pairs(currentCommand) do
        if v.name ~= nil then
            currentCustom_main.Button((v.plate or "?"), v.name, nil, "chevron", false, function()
                selected_command = v
                selected_key = k
                NewCustom = {}

                for key, value in pairs(selected_command.props) do
                    for _, vv in pairs(VFW.Game.GetVehicleProperties(lastVeh)) do
                        if key == _ then
                            if value ~= vv then
                                table.insert(NewCustom, { props = key, value = value })
                            end
                        end
                    end
                end
            end, currentCustom_category)
        else
            currentCustom_main.Separator("Aucune commande en cours")
        end
    end
end

currentCustom_main.OnOpen(function()
    -- Utiliser la bannière custom de la société si elle existe
    if Society.data and Society.data.banner and Society.data.banner ~= "" then
        currentCustom_main.ChangeBanner(Society.data.banner)
        currentCustom_category.ChangeBanner(Society.data.banner)
        submodifCustom.ChangeBanner(Society.data.banner)
    end
    BuildCustomMenu()
end)

currentCustom_category.OnOpen(function()
    BuildCustomCategoryMenu()
end)

submodifCustom.OnOpen(function()
    BuildCustomModifMenu()
end)

local function SetMenuBanners(menu)
    if lastJob == "autoexotic" then
        menu.ChangeBanner("header_autoexotic")
    elseif lastJob == "beekers" then
        menu.ChangeBanner("header_beekers")
    elseif lastJob == "bennys" then
        menu.ChangeBanner("header_bennys")
    elseif lastJob == "getaweigh" then
        menu.ChangeBanner("header_getaweigh")
    elseif lastJob == "harmony" then
        menu.ChangeBanner("header_harmony")
    elseif lastJob == "hayes" then
        menu.ChangeBanner("header_hayes")
    elseif lastJob == "staff" then
        menu.ChangeBanner("administration")
    end
end

function OpenCurrentCustom(currentVeh)
    lastVeh = currentVeh

    SetMenuBanners(currentCustom_main)
    SetMenuBanners(currentCustom_category)
    SetMenuBanners(submodifCustom)

    currentCustom_main.toggle()
end

---@param data table
RegisterNetEvent("core:GetCommandeMecano", function(data)
    currentCommand = data
end)

-- ============================================
-- SOCIETY INTEGRATION
-- ============================================

local currentCustoms = {}
local societyCustomsInit = false
local societyCustomsGeneration = 0
local customsFloatingShown = false
local customsFloatingId = nil

local jobHasAccessToCustom = {
    ["mecano"] = true,
}

local function ShowCustomsFloating(key, worldPos)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.5)
    if not onScreen then
        if customsFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            customsFloatingShown = false
            customsFloatingId = nil
        end
        return
    end

    local data = {
        id = "customs_" .. tostring(key),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Menu mécano", key = "E", icon = "car" }
        }
    }

    if customsFloatingShown and customsFloatingId == key then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        customsFloatingShown = true
        customsFloatingId = key
    end
end

local function HideCustomsFloating()
    if customsFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        customsFloatingShown = false
        customsFloatingId = nil
    end
end

function Society.initCustoms()
    if societyCustomsInit then
        return
    end

    societyCustomsInit = true
    societyCustomsGeneration = societyCustomsGeneration + 1
    local myGeneration = societyCustomsGeneration

    CreateThread(function()
        local interval = 500

        while societyCustomsInit and societyCustomsGeneration == myGeneration do
            if isCustomsOpen or IsNuiFocused() then
                HideCustomsFloating()
                interval = 500
                Wait(interval)
            elseif (Society.data and Society.data.custom and Society.data.custom.customs) then
                local player = PlayerPedId()
                local customPoints = Society.data.custom.customs
                local playerCoords = GetEntityCoords(player)
                local found = false

                for key, position in ipairs(customPoints) do
                    local dist = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(position.x, position.y, position.z))
                    if dist < 2.0 then
                        found = true
                        interval = 0
                        ShowCustomsFloating(key, vector3(position.x, position.y, position.z))

                        if VFW.Interact.JustPressed(0, 38) then
                            if (GetVehiclePedIsIn(player, false) ~= 0 and VFW.PlayerData.job.onDuty) then
                                lastJob = VFW.PlayerData.job.name
                                saveVeh = VFW.Game.GetVehicleProperties(VFW.PlayerData.vehicle)
                                HideCustomsFloating()
                                OpenCustomMenu()
                            else
                                local societyImage = TriggerServerCallback("core:get:societyImage")
                                VFW.ShowNotification({
                                    type = 'JOB',
                                    title = VFW.PlayerData.job.label,
                                    subtitle = "Modification impossible",
                                    subtitleColor = "RED",
                                    image = societyImage,
                                    content = "Vous devez être en service et dans un véhicule pour ouvrir le menu."
                                })
                            end
                        end
                        break
                    end
                end

                if not found then
                    HideCustomsFloating()
                    interval = 500
                end

                Wait(interval)
            else
                Wait(interval)
            end
        end
    end)

    return true
end

function Society.unloadCustoms()
    currentCustoms = {}
    societyCustomsInit = false
    societyCustomsGeneration = societyCustomsGeneration + 1
    HideCustomsFloating()
end

function VFW.MenuCustom()
    saveVeh = VFW.Game.GetVehicleProperties(VFW.PlayerData.vehicle)
    OpenCustomMenu()
end

function VFW.MenuCustomSave()
    saveVeh = VFW.Game.GetVehicleProperties(VFW.PlayerData.vehicle)
    OpenCurrentCustom(VFW.PlayerData.vehicle)
end
