---@meta _
---@diagnostic disable: duplicate-doc-field

-- Configuration (matching original Earthquake resource values for stronger effect)
local Config = {
    camShakeType = "ROAD_VIBRATION_SHAKE",  -- Using the same as original
    camShakeIntensity = 2.5,  -- Stronger shake from original config
    playerRagdollChance = 0.02,  -- Higher chance from original
    playerRagdollTime = 1500,  -- Longer ragdoll from original
    playerRagdollRecoveryTime = 500,  -- Longer recovery from original
    pedRagdollChance = 0.05,  -- Much higher chance from original
    pedRagdollTime = 2000,  -- Longer ped ragdoll from original
    pedRagdollRecoveryTime = 500,  -- Longer recovery from original
    defaultDuration = 30000,
    defaultForce = 1000.0,
    defaultFrequency = 3.0
}

local math_random = math.random
local earthquakeActive = false
local forceValue = 1000.0
local previousWeather = nil

-- Start the earthquake
local function StartEarthquake(force, frequency, direction, seed, duration, weatherType)
    if earthquakeActive then return end

    earthquakeActive = true
    forceValue = force or Config.defaultForce
    local earthquakeDuration = duration or Config.defaultDuration
    previousWeather = weatherType

    math.randomseed(seed or os.time())

    local inverseDirection = 1.0 - (direction or math.random())
    local flip = -1

    SetWeatherTypeNowPersist("FOGGY")
    SetWind(0.8)
    SetWindSpeed(5.0)

    -- Play siren sound
    PlaySoundFrontend(-1, "Air_Defences_Activated", "DLC_sum20_Business_Battle_AC_Sounds", true)

    -- Main earthquake thread with fade in/out effects
    CreateThread(function()
        local ped = PlayerPedId()
        local isInAirOrWater = IsEntityInAir(ped) or IsEntityInWater(ped) or
                               IsEntityInAir(GetVehiclePedIsIn(ped)) or
                               IsEntityInWater(GetVehiclePedIsIn(ped))

        local startTime = GetGameTimer()
        local fadeInDuration = 2000  -- 2 seconds fade in
        local fadeOutDuration = 3000  -- 3 seconds fade out
        local fadeOutStart = earthquakeDuration - fadeOutDuration

        while earthquakeActive and (GetGameTimer() - startTime) < earthquakeDuration do
            ped = PlayerPedId()
            local elapsedTime = GetGameTimer() - startTime
            local currentIntensity = Config.camShakeIntensity

            -- Calculate intensity with fade in/out
            if elapsedTime < fadeInDuration then
                -- Fade in
                currentIntensity = Config.camShakeIntensity * (elapsedTime / fadeInDuration)
            elseif elapsedTime > fadeOutStart then
                -- Fade out
                local fadeOutProgress = (elapsedTime - fadeOutStart) / fadeOutDuration
                currentIntensity = Config.camShakeIntensity * (1.0 - fadeOutProgress)
            end

            -- Camera shake management with dynamic intensity
            local isPlayerInAir = IsEntityInAir(ped) or IsEntityInWater(ped) or
                                  IsEntityInAir(GetVehiclePedIsIn(ped)) or
                                  IsEntityInWater(GetVehiclePedIsIn(ped))

            if not isInAirOrWater and isPlayerInAir then
                isInAirOrWater = true
                StopGameplayCamShaking(false)  -- Smooth stop
            elseif isInAirOrWater and not isPlayerInAir then
                isInAirOrWater = false
                ShakeGameplayCam(Config.camShakeType, currentIntensity)
            end

            if not isPlayerInAir and not isInAirOrWater then
                -- Always update shake with current intensity for smooth transitions
                StopGameplayCamShaking(false)
                Wait(0)
                ShakeGameplayCam(Config.camShakeType, currentIntensity)
            end

            -- Process entities with reduced force during fade in/out
            local forceMultiplier = currentIntensity / Config.camShakeIntensity
            flip = -flip
            ProcessEntitiesWithMultiplier(ped, direction or 0.5, inverseDirection, flip, forceMultiplier)

            Wait(1000 / (frequency or Config.defaultFrequency))

            flip = -flip
            ProcessEntitiesWithMultiplier(ped, direction or 0.5, inverseDirection, flip, forceMultiplier)

            Wait(1000 / (frequency or Config.defaultFrequency))
        end

        -- Smooth fade out before stopping
        StopGameplayCamShaking(false)
        Wait(500)
        StopEarthquake()
    end)

    -- Environmental effects
    CreateThread(function()
        local startTime = GetGameTimer()

        while earthquakeActive and (GetGameTimer() - startTime) < earthquakeDuration do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local progress = (GetGameTimer() - startTime) / earthquakeDuration

            -- Dust effects during main phase
            if progress > 0.2 and progress < 0.7 then
                if not HasNamedPtfxAssetLoaded("core") then
                    RequestNamedPtfxAsset("core")
                    while not HasNamedPtfxAssetLoaded("core") do
                        Wait(0)
                    end
                end

                UseParticleFxAssetNextCall("core")
                StartParticleFxNonLoopedAtCoord(
                    "ent_dst_dust",
                    playerCoords.x + math.random(-8, 8),
                    playerCoords.y + math.random(-8, 8),
                    playerCoords.z,
                    0.0, 0.0, 0.0,
                    math.random(2, 4) * 1.0,
                    false, false, false
                )
            end

            -- Light flickering
            if progress > 0.2 and progress < 0.7 then
                SetArtificialLightsState(math.random(1, 3) == 1)
            end

            Wait(math.random(1000, 3000))
        end

        SetArtificialLightsState(false)
    end)

    -- Vehicle alarm effects
    CreateThread(function()
        local startTime = GetGameTimer()

        while earthquakeActive and (GetGameTimer() - startTime) < earthquakeDuration do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehicles = GetGamePool('CVehicle')

            for _, vehicle in ipairs(vehicles) do
                local vehicleCoords = GetEntityCoords(vehicle)
                local distance = #(playerCoords - vehicleCoords)

                if distance < 50.0 and math.random(1, 30) == 1 then
                    SetVehicleAlarm(vehicle, true)
                    StartVehicleAlarm(vehicle)
                end
            end

            Wait(math.random(3000, 6000))
        end
    end)

    TriggerEvent("vfw:seisme:announcement", "ALERTE SÉISME", "Un séisme est en cours a San Andreas. Mettez vous en sécurité. !", 12)
end

-- Stop the earthquake with smooth transition
function StopEarthquake()
    earthquakeActive = false

    -- Smooth camera shake stop
    StopGameplayCamShaking(false)  -- false for smooth stop
    Wait(100)
    StopGameplayCamShaking(true)  -- Ensure it's fully stopped

    -- Restore weather
    if previousWeather then
        SetWeatherTypeNowPersist(previousWeather)
    else
        ClearWeatherTypePersist()
    end
    SetWind(0.0)
    SetWindSpeed(0.0)



    -- Clear effects
    SetArtificialLightsState(false)
    ClearTimecycleModifier()

    TriggerEvent("vfw:seisme:announcement:end", "FIN DE SÉISME",
        "Le séisme est terminé. Vous pouvez sortir de votre abri en toute sécurité.", 8)
end

-- Apply forces and ragdolls to vehicles/objects/peds with intensity multiplier
function ProcessEntitiesWithMultiplier(ped, direction, inverseDirection, flip, multiplier)
    -- Move vehicles
    local vehicles = GetVehicles()
    for i = 1, #vehicles do
        local appliedForce = GetRandomForceValue() * multiplier
        local class = GetVehicleClass(vehicles[i])
        if class == 8 or class == 13 then
            -- Move bikes less
            ApplyForceToEntity(vehicles[i], 3,
                flip * 0.2 * appliedForce * direction,
                flip * 0.2 * appliedForce * inverseDirection,
                0.0, 0.0, 0.0, GetEntityHeight(vehicles[i]),
                0, false, true, false, false, true)
        else
            ApplyForceToEntity(vehicles[i], 3,
                flip * appliedForce * direction,
                flip * appliedForce * inverseDirection,
                0.0, 0.0, 0.0, GetEntityHeight(vehicles[i]),
                0, false, true, false, false, true)
        end
    end

    -- Move objects
    local objects = GetObjects()
    for i = 1, #objects do
        local appliedForce = GetRandomForceValue() * multiplier
        ApplyForceToEntity(objects[i], 3,
            flip * appliedForce * direction * 0.001,
            flip * appliedForce * inverseDirection * 0.001,
            0.0, 0.0, 0.0, GetEntityHeight(objects[i]),
            0, false, true, true, false, true)
    end

    -- Ragdoll peds (scaled probability during fade)
    local peds = GetPeds()
    for i = 1, #peds do
        if math_random() < (Config.pedRagdollChance * multiplier) then
            local pos = flip * GetEntityForwardVector(peds[i])
            SetPedToRagdollWithFall(peds[i], Config.pedRagdollTime, Config.pedRagdollRecoveryTime,
                1, pos.x, pos.y, pos.z, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        end
    end

    -- Ragdoll player (scaled probability during fade)
    if math_random() < (Config.playerRagdollChance * multiplier) and not IsPedInAnyVehicle(ped) then
        local pos = flip * GetEntityForwardVector(ped)
        SetPedToRagdollWithFall(ped, Config.playerRagdollTime, Config.playerRagdollRecoveryTime,
            1, pos.x, pos.y, pos.z, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    end
end

-- Apply forces and ragdolls to vehicles/objects/peds (original function for backwards compatibility)
function ProcessEntities(ped, direction, inverseDirection, flip)
    ProcessEntitiesWithMultiplier(ped, direction, inverseDirection, flip, 1.0)
end

-- Get eligible vehicles
function GetVehicles()
    local vehicles = {}
    local loadedVehicles = GetGamePool("CVehicle")

    for i = 1, #loadedVehicles do
        if DoesEntityExist(loadedVehicles[i]) and
           NetworkHasControlOfEntity(loadedVehicles[i]) and
           not IsEntityInAir(loadedVehicles[i]) and
           not IsEntityInWater(loadedVehicles[i]) then
            vehicles[#vehicles + 1] = loadedVehicles[i]
        end
    end

    return vehicles
end

-- Get eligible objects
function GetObjects()
    local objects = {}
    local position = GetFinalRenderedCamCoord()
    local loadedObjects = GetGamePool("CObject")

    for i = 1, #loadedObjects do
        if DoesEntityExist(loadedObjects[i]) and
           (GetEntityShortestSideLength(loadedObjects[i]) < 1.0 or not IsEntityStatic(loadedObjects[i])) and
           #(position - GetEntityCoords(loadedObjects[i])) < 50.0 and
           not NetworkGetEntityIsNetworked(loadedObjects[i]) and
           not IsEntityInAir(loadedObjects[i]) then
            objects[#objects + 1] = loadedObjects[i]
        end
    end

    return objects
end

-- Get eligible peds
function GetPeds()
    local peds = {}
    local position = GetFinalRenderedCamCoord()
    local playerPed = PlayerPedId()
    local loadedPeds = GetGamePool("CPed")

    for i = 1, #loadedPeds do
        if playerPed ~= loadedPeds[i] and
           DoesEntityExist(loadedPeds[i]) and
           NetworkHasControlOfEntity(loadedPeds[i]) and
           #(position - GetEntityCoords(loadedPeds[i])) < 100.0 and
           not IsEntityInAir(loadedPeds[i]) then
            peds[#peds + 1] = loadedPeds[i]
        end
    end

    return peds
end

-- Get entity height
function GetEntityHeight(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    return (max.z - min.z) * 0.5
end

-- Get shortest side length
function GetEntityShortestSideLength(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local sizeX, sizeY, sizeZ = max.x - min.x, max.y - min.y, max.z - min.z

    if sizeX < sizeY and sizeX < sizeZ then
        return sizeX
    elseif sizeY < sizeZ then
        return sizeY
    end

    return sizeZ
end

-- Randomize force value
function GetRandomForceValue()
    return forceValue * (1.5 - math_random())
end

-- Event handlers
RegisterNetEvent('vfw:earthquake:start', function(force, frequency, direction, seed, duration, weatherType)
    StartEarthquake(force, frequency, direction, seed, duration, weatherType)
end)

RegisterNetEvent('vfw:earthquake:stop', function()
    StopEarthquake()
end)

-- State bag handler for synchronization
AddStateBagChangeHandler("earthquake", nil, function(bagName, key, value, _unused, replicated)
    if value then
        StartEarthquake(value.force, value.frequency, value.direction, value.seed, value.duration, value.weather)
    else
        StopEarthquake()
    end
end)

-- Start earthquake on player that connected while it was already running
CreateThread(function()
    Wait(1000) -- Wait a bit to ensure server has cleared any stale state
    local earthquake = GlobalState.earthquake
    if earthquake and earthquake.startTime then
        -- Only start if the earthquake has a valid start time (meaning it's currently active)
        local elapsed = GetGameTimer() - (earthquake.startTime or 0)
        if elapsed < (earthquake.duration or 0) then
            StartEarthquake(earthquake.force, earthquake.frequency, earthquake.direction,
                           earthquake.seed, earthquake.duration, earthquake.weather)
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if earthquakeActive then
            StopEarthquake()
        end
    end
end)