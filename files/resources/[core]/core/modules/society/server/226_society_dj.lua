local sounds = {}
local soundBySource = {}
local lastAction = {}

local DEFAULT_DISTANCE = 30.0
local MAX_DISTANCE = 120.0

local function extractUrl(data)
    if type(data) == "string" then return data end
    if type(data) == "table" then
        local candidate = data.url or data.link or data.value or data.src
        if type(candidate) == "string" then return candidate end
    end
    return nil
end

local function sanitizeCoords(coords, fallback)
    if type(coords) == "table" then
        local x, y, z = tonumber(coords.x or coords[1]), tonumber(coords.y or coords[2]), tonumber(coords.z or coords[3])
        if x and y and z then return { x = x, y = y, z = z } end
    end
    return fallback
end

local function throttled(source)
    local now = GetGameTimer()
    local last = lastAction[source]
    if last and (now - last) < 400 then return true end
    lastAction[source] = now
    return false
end

local function canUseDJ(xPlayer)
    if not xPlayer then return false end
    if xPlayer.hasPermission("staff_menu") then return true end
    if not xPlayer.job or not xPlayer.job.onDuty then return false end

    local society = VFW.Society.Get(xPlayer.job.name)
    if not society or type(society.custom) ~= "table" then return false end

    local points = society.custom.dj
    if type(points) ~= "table" then return false end

    local coords = xPlayer.getCoords()
    for _, point in pairs(points) do
        if type(point) == "table" and point.x then
            local dx = coords.x - (tonumber(point.x) or 0.0)
            local dy = coords.y - (tonumber(point.y) or 0.0)
            local dz = coords.z - (tonumber(point.z) or 0.0)
            if (dx * dx + dy * dy + dz * dz) <= 400.0 then return true end
        end
    end

    return false
end

local function resolveSound(source, soundId)
    if type(soundId) == "string" and sounds[soundId] then return soundId end
    local owned = soundBySource[source]
    if owned and sounds[owned] then return owned end
    return nil
end

local function listeners(sound)
    local radius = math.min((sound.dist or DEFAULT_DISTANCE) + 25.0, MAX_DISTANCE + 25.0)
    local players = VFW.GetPlayersInRadius(sound.coords, radius)
    local seen = {}
    local targets = {}

    for i = 1, #players do
        local src = players[i].source
        if not seen[src] then
            seen[src] = true
            targets[#targets + 1] = src
        end
    end

    if sound.owner and not seen[sound.owner] and VFW.Players[sound.owner] then
        targets[#targets + 1] = sound.owner
    end

    return targets
end

local function broadcast(sound, event, ...)
    local targets = listeners(sound)
    for i = 1, #targets do
        TriggerClientEvent(event, targets[i], ...)
    end
end

local function destroySound(soundId)
    local sound = sounds[soundId]
    if not sound then return end
    broadcast(sound, "core:dj:stop", soundId)
    if sound.owner and soundBySource[sound.owner] == soundId then
        soundBySource[sound.owner] = nil
    end
    sounds[soundId] = nil
end

RegisterNetEvent("core:dj:play", function(soundId, data, volume, coords, dist)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(soundId) ~= "string" or soundId == "" or #soundId > 64 then return end
    if throttled(source) then return end
    if not canUseDJ(xPlayer) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous ne pouvez pas utiliser la sono ici." })
        return
    end

    local url = extractUrl(data)
    if not url or #url > 512 then return end

    local vol = tonumber(volume) or 0.5
    if vol < 0.0 then vol = 0.0 end
    if vol > 1.0 then vol = 1.0 end

    local position = sanitizeCoords(coords, xPlayer.getCoords())
    local distance = tonumber(dist) or DEFAULT_DISTANCE
    if distance <= 0.0 then distance = DEFAULT_DISTANCE end
    if distance > MAX_DISTANCE then distance = MAX_DISTANCE end

    local previous = soundBySource[source]
    if previous then destroySound(previous) end

    local sound = {
        id = soundId,
        owner = source,
        url = url,
        volume = vol,
        coords = position,
        dist = distance,
        paused = false,
        resumeTime = 0,
        job = xPlayer.job and xPlayer.job.name or "",
    }

    sounds[soundId] = sound
    soundBySource[source] = soundId

    broadcast(sound, "core:dj:play", soundId, url, vol, position, distance)
end)

RegisterNetEvent("core:dj:stop", function(soundId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local resolved = resolveSound(source, soundId)
    if not resolved then return end

    local sound = sounds[resolved]
    if sound.owner ~= source and not xPlayer.hasPermission("staff_menu") then return end

    destroySound(resolved)
end)

RegisterNetEvent("core:dj:pause", function(soundId, currentTime)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local resolved = resolveSound(source, soundId)
    if not resolved then return end

    local sound = sounds[resolved]
    if sound.owner ~= source and not xPlayer.hasPermission("staff_menu") then return end

    if sound.paused then
        sound.paused = false
        broadcast(sound, "core:dj:resume", resolved, sound.resumeTime or 0)
    else
        sound.paused = true
        sound.resumeTime = tonumber(currentTime) or sound.resumeTime or 0
        if sound.resumeTime < 0 then sound.resumeTime = 0 end
        broadcast(sound, "core:dj:pause", resolved)
    end
end)

RegisterNetEvent("core:dj:volume", function(soundId, volume)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local resolved = resolveSound(source, soundId)
    if not resolved then return end

    local sound = sounds[resolved]
    if sound.owner ~= source and not xPlayer.hasPermission("staff_menu") then return end

    local vol = tonumber(volume)
    if not vol then return end
    if vol < 0 then vol = 0 end
    if vol > 100 then vol = 100 end

    sound.volume = vol / 100.0
    broadcast(sound, "core:dj:volume", resolved, vol)
end)

AddEventHandler("playerDropped", function()
    local source = source
    lastAction[source] = nil
    local owned = soundBySource[source]
    if owned then destroySound(owned) end
end)
