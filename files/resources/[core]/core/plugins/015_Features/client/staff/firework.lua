local FIREWORK_PARTICLE_LIFETIME <const> = 4000
local isFireworkActive = false
VFW.isFireworkActive = function() return isFireworkActive end
local FIREWORK_DURATION <const> = 120000 -- 2 minutes
local currentMusicId = nil
local activeFireworks = {}

local FIREWORK_BUDGET <const> = {
    SMALL = 1,
    MEDIUM = 2,
    LARGE = 3
}

local FIREWORK_MAX_COUNT_BY_BUDGET <const> = {
    [FIREWORK_BUDGET.SMALL] = 8,
    [FIREWORK_BUDGET.MEDIUM] = 16,
    [FIREWORK_BUDGET.LARGE] = 24
}

local FIREWORK_CLIP_DIST_BY_BUDGET <const> = {
    [FIREWORK_BUDGET.SMALL] = 1000.0,
    [FIREWORK_BUDGET.MEDIUM] = 2000.0,
    [FIREWORK_BUDGET.LARGE] = 4000.0
}

-- Firework spawn locations will be generated relative to player position
local function generateFireworkCoords(centerPos)
    local coords = {}
    for i = 1, 12 do  -- Increased from 8 to 12 spawn points
        -- Create spawn points in a circle around the player, high in the sky
        local angle = (i - 1) * (math.pi * 2 / 12)
        local x = centerPos.x + math.cos(angle) * 200.0  -- Increased radius to 200m
        local y = centerPos.y + math.sin(angle) * 200.0  -- Increased radius to 200m
        local z = centerPos.z + 60.0 + (i % 3) * 25.0 -- Varied height between 60-110m
        coords[i] = vector3(x, y, z)
    end
    -- Add some inner circle spawn points for depth
    for i = 1, 6 do
        local angle = (i - 1) * (math.pi * 2 / 6) + (math.pi / 6) -- Offset angle
        local x = centerPos.x + math.cos(angle) * 100.0  -- Inner circle at 100m
        local y = centerPos.y + math.sin(angle) * 100.0
        local z = centerPos.z + 75.0 + (i % 2) * 20.0 -- Height 75-95m
        coords[#coords + 1] = vector3(x, y, z)
    end
    return coords
end

local fireworkSpawners = {}

local lastFireworkSpawnersRefresh = 0

local fireworkPresets = {
    { 'scr_indep_fireworks', 'scr_indep_firework_starburst' },
    { 'scr_indep_fireworks', 'scr_indep_firework_trailburst' },
    { 'proj_indep_firework', 'scr_indep_firework_grd_burst' },
    { 'proj_indep_firework', 'scr_indep_firework_air_burst' },
    { 'proj_indep_firework_v2', 'scr_firework_indep_burst_rwb' },
    { 'proj_indep_firework_v2', 'scr_firework_indep_spiral_burst_rwb' },
    { 'proj_indep_firework_v2', 'scr_firework_indep_repeat_burst_rwb' },
    { 'proj_xmas_firework', 'scr_firework_xmas_ring_burst_rgw' },
}

local minMs, maxMs = 2000, 3500  -- Slower spawn rate for more dramatic effect

local function getFireworkBudget()
    local frameTime = GetFrameTime()

    if frameTime >= (1 / 30) then
        return FIREWORK_BUDGET.SMALL
    elseif frameTime >= (1 / 60) then
        return FIREWORK_BUDGET.MEDIUM
    end

    return FIREWORK_BUDGET.LARGE
end

local function getRandomCoords(coords)
    local randomX = coords.x + math.random(-50, 50)  -- Increased horizontal spread
    local randomY = coords.y + math.random(-50, 50)  -- Increased horizontal spread
    local randomZ = coords.z + math.random(-20, 40)  -- More vertical variation

    return vec3(randomX, randomY, randomZ)
end

local function refreshFireworkSpawners(fromCoords)
    local timeNow = GetGameTimer()
    if timeNow > lastFireworkSpawnersRefresh + 2000 then
        lastFireworkSpawnersRefresh = timeNow
        table.sort(fireworkSpawners, function(a, b)
            return #(fromCoords - a.coords) < #(fromCoords - b.coords)
        end)
    end
end

local function getRandomPreset()
    return fireworkPresets[math.random(1, #fireworkPresets)]
end

local function loadParticleDicts()
    local dicts = {
        'scr_indep_fireworks',
        'proj_indep_firework',
        'proj_indep_firework_v2',
        'proj_xmas_firework'
    }

    for _, dict in ipairs(dicts) do
        if not HasNamedPtfxAssetLoaded(dict) then
            RequestNamedPtfxAsset(dict)
            local attempts = 0
            while not HasNamedPtfxAssetLoaded(dict) do
                attempts = attempts + 1
                if attempts > 100 then
                    break
                end
                Wait(10)
            end
        end
    end
end

local isFireworkLauncher = false

local function startFirework(duration, musicUrl, volume, centerCoords, launcher)

    if isFireworkActive then
        if launcher then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Feux Artifice',
                message = 'Un feu d\'artifice est déjà en cours.'
            })
        end
        return
    end

    activeFireworks = {}
    isFireworkActive = true
    isFireworkLauncher = launcher == true

    local centerPos = centerCoords or vector3(0.0, 0.0, 100.0)

    local FireworkCoords = generateFireworkCoords(centerPos)
    fireworkSpawners = {}
    for i = 1, #FireworkCoords do
        fireworkSpawners[i] = { coords = FireworkCoords[i], nextSpawn = 0 }
    end

    loadParticleDicts()

    local fireworkDuration = GetGameTimer() + (duration or FIREWORK_DURATION)

    if musicUrl and musicUrl ~= "" then
        currentMusicId = "firework_music_" .. tostring(GetGameTimer())

        if exports and exports.xsound then
            local musicVolume = volume or 0.5
            exports.xsound:PlayUrl(currentMusicId, musicUrl, musicVolume, false)
        end
    end

    if isFireworkLauncher then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Feux Artifice',
            message = 'Feu d\'artifice lancé. Durée: ' .. math.floor((duration or FIREWORK_DURATION) / 1000) .. ' secondes.'
        })
    end

    CreateThread(function()
        local loopCount = 0
        while isFireworkActive do
            loopCount = loopCount + 1
            local timeNow = GetGameTimer()
            if timeNow >= fireworkDuration then
                break
            end

            local playerCoords = GetEntityCoords(PlayerPedId())
            local fireworkBudget = getFireworkBudget()
            local maxFireworks = FIREWORK_MAX_COUNT_BY_BUDGET[fireworkBudget]
            local fireworkClipDist = FIREWORK_CLIP_DIST_BY_BUDGET[fireworkBudget]

            refreshFireworkSpawners(playerCoords)

            local maxFireworksSpawn = math.ceil(maxFireworks / 3)

            for i = 1, maxFireworksSpawn do
                if #activeFireworks < maxFireworks then
                    local fireworkSpawner = fireworkSpawners[i]

                    if timeNow >= fireworkSpawner.nextSpawn then
                        local spawnCoords = getRandomCoords(fireworkSpawner.coords)
                        local preset = getRandomPreset()
                        local scale = 3.5 + math.random() * 1.5

                        if not HasNamedPtfxAssetLoaded(preset[1]) then
                            RequestNamedPtfxAsset(preset[1])
                            local loadAttempts = 0
                            while not HasNamedPtfxAssetLoaded(preset[1]) and loadAttempts < 20 do
                                loadAttempts = loadAttempts + 1
                                Wait(5)
                            end
                        end

                        local ptfx = 0
                        if HasNamedPtfxAssetLoaded(preset[1]) then
                            UseParticleFxAssetNextCall(preset[1])
                            ptfx = StartParticleFxLoopedAtCoord(
                                preset[2],
                                spawnCoords.x, spawnCoords.y, spawnCoords.z,
                                0.0, 0.0, 0.0,
                                scale,
                                false, false, false, false
                            )
                        end

                        if ptfx and ptfx > 0 then
                            activeFireworks[#activeFireworks + 1] = {
                                ptfx = ptfx,
                                spawnedAt = timeNow,
                                deleteAt = timeNow + FIREWORK_PARTICLE_LIFETIME
                            }
                            SetParticleFxLoopedFarClipDist(ptfx, fireworkClipDist)
                        end

                        fireworkSpawner.nextSpawn = timeNow + math.random(minMs, maxMs)
                    end
                end
            end

            -- Cleanup expired fireworks
            for i = #activeFireworks, 1, -1 do
                local activeFirework = activeFireworks[i]

                if timeNow >= activeFirework.deleteAt then
                    table.remove(activeFireworks, i)
                    StopParticleFxLooped(activeFirework.ptfx, false)
                end
            end

            Wait(0)
        end

        isFireworkActive = false

        -- Clean up remaining fireworks
        for i = #activeFireworks, 1, -1 do
            local activeFirework = activeFireworks[i]
            StopParticleFxLooped(activeFirework.ptfx, false)
        end

        -- Stop music if it was playing
        if currentMusicId and exports and exports.xsound then
            exports.xsound:Destroy(currentMusicId)
            currentMusicId = nil
        end

        -- Remove particle assets from memory
        for _, dict in ipairs({'scr_indep_fireworks', 'proj_indep_firework', 'proj_indep_firework_v2', 'proj_xmas_firework'}) do
            RemoveNamedPtfxAsset(dict)
        end

        if isFireworkLauncher then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Feux Artifice',
                message = 'Feu d\'artifice terminé.'
            })
        end
        isFireworkLauncher = false
    end)
end

RegisterNetEvent('vfw:staff:startFirework', function(duration, musicUrl, volume, centerCoords, launcher)
    startFirework(duration, musicUrl, volume, centerCoords, launcher)
end)

RegisterNetEvent('vfw:staff:stopFirework', function(launcher)
    isFireworkActive = false

    if currentMusicId and exports and exports.xsound then
        exports.xsound:Destroy(currentMusicId)
        currentMusicId = nil
    end

    for i = #activeFireworks, 1, -1 do
        StopParticleFxLooped(activeFireworks[i].ptfx, false)
    end
    activeFireworks = {}

    if launcher == true then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Feux Artifice',
            message = 'Feu d\'artifice arrêté.'
        })
    end
    isFireworkLauncher = false
end)


-- Export for direct use
exports('startFirework', startFirework)
exports('isFireworkActive', function() return isFireworkActive end)