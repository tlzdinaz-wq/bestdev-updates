local zones = {}
local active = nil
local deadPlayers = {}

local function cfg(key, fallback)
    if type(KOTHConfig) == "table" and KOTHConfig[key] ~= nil then return KOTHConfig[key] end
    return fallback
end

local function decodeHours(value)
    local decoded = VFW.DB.Decode(value, {})
    if type(decoded) ~= "table" then return {} end
    return decoded
end

local function loadZones()
    zones = {}
    local rows = MiscB.Query([[
        SELECT id, name, x, y, z, radius, duration, enabled, schedule_hours, schedule_start, schedule_finish
        FROM koth_zones ORDER BY id ASC
    ]], {})

    for i = 1, #rows do
        local row = rows[i]
        zones[#zones + 1] = {
            id = row.id,
            name = row.name,
            coords = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0 },
            x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0,
            radius = (row.radius or cfg("defaultRadius", 50.0)) + 0.0,
            duration = row.duration or cfg("defaultDuration", 15),
            enabled = row.enabled == 1 or row.enabled == true,
            scheduleHours = decodeHours(row.schedule_hours),
            scheduleRange = { start = row.schedule_start, finish = row.schedule_finish },
        }
    end
    return zones
end

local function findZone(id)
    for i = 1, #zones do
        if tostring(zones[i].id) == tostring(id) then return zones[i], i end
    end
    return nil
end

local function factionOf(xPlayer)
    local faction = MiscB.FactionName(xPlayer)
    if not faction or faction == "" or faction == "nofaction" or faction == "nocrew" then return nil end
    return faction
end

local function buildScoreboard()
    if not active then return nil end
    local list = {}
    for name, score in pairs(active.scores) do
        list[#list + 1] = { name = name, score = score }
    end
    table.sort(list, function(a, b) return a.score > b.score end)

    local remaining = math.floor((active.endsAt - os.time()))
    if remaining < 0 then remaining = 0 end

    return { scores = list, remainingSeconds = remaining }
end

local function pushScoreboard()
    if not active then return end
    active.scoreboard = buildScoreboard()
    TriggerClientEvent("koth:updateScoreboard", -1, active.scoreboard)
end

local function payload()
    if not active then return nil end
    return {
        id = active.id,
        name = active.name,
        coords = active.coords,
        radius = active.radius,
        endsAt = active.endsAt,
        scoreboard = active.scoreboard,
    }
end

local function stopKoth(recordWinner)
    if not active then return false end
    local finished = active
    active = nil
    deadPlayers = {}

    TriggerClientEvent("koth:end", -1)

    if recordWinner then
        local bestName, bestScore = nil, -1
        for name, score in pairs(finished.scores) do
            if score > bestScore then
                bestName, bestScore = name, score
            end
        end

        MiscB.Insert([[
            INSERT INTO koth_history (zone_id, zone_name, winner_faction, winner_score, started_at, ended_at)
            VALUES (?, ?, ?, ?, FROM_UNIXTIME(?), NOW())
        ]], { finished.id, finished.name, bestName, bestScore >= 0 and bestScore or 0, finished.startedAt })

        if bestName then
            TriggerEvent("koth:finished", finished.id, bestName, bestScore)
        end
    end

    return true
end

local function startKoth(zone)
    if active then return false end
    if not zone then return false end

    active = {
        id = zone.id,
        name = zone.name,
        coords = zone.coords,
        radius = zone.radius,
        startedAt = os.time(),
        endsAt = os.time() + (tonumber(zone.duration) or 15) * 60,
        scores = {},
        scoreboard = nil,
    }
    deadPlayers = {}
    active.scoreboard = buildScoreboard()

    TriggerClientEvent("koth:start", -1, payload())
    return true
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(3000)
    loadZones()
end)

CreateThread(function()
    Wait(10000)
    local tickInterval = math.max(1, tonumber(cfg("tickInterval", 10)) or 10)
    local pointsPerTick = tonumber(cfg("pointsPerTick", 1)) or 1

    while true do
        Wait(tickInterval * 1000)

        if active then
            if os.time() >= active.endsAt then
                stopKoth(true)
            else
                local center = vector3(active.coords.x, active.coords.y, active.coords.z)
                local inZone = VFW.GetPlayersInRadius(center, active.radius)

                for i = 1, #inZone do
                    local xPlayer = inZone[i]
                    if xPlayer and not deadPlayers[xPlayer.source] and not xPlayer.dead then
                        local faction = factionOf(xPlayer)
                        if faction then
                            active.scores[faction] = (active.scores[faction] or 0) + pointsPerTick
                        end
                    end
                end

                pushScoreboard()
            end
        end
    end
end)

CreateThread(function()
    Wait(15000)
    local lastKey = nil

    while true do
        Wait(30000)

        if not active then
            local hour = tonumber(os.date("%H"))
            local minute = tonumber(os.date("%M"))
            local key = ("%02d:%02d"):format(hour, minute)

            if key ~= lastKey then
                for i = 1, #zones do
                    local zone = zones[i]
                    if zone.enabled and type(zone.scheduleHours) == "table" then
                        for j = 1, #zone.scheduleHours do
                            if tostring(zone.scheduleHours[j]) == key then
                                lastKey = key
                                startKoth(zone)
                                break
                            end
                        end
                    end
                    if active then break end
                end
            end
        end
    end
end)

MiscB.Cb("koth:getActive", function(source)
    return payload()
end)

RegisterNetEvent("koth:playerDeath", function()
    local source = source
    if not active then return end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    deadPlayers[source] = true
end)

RegisterNetEvent("koth:playerAlive", function()
    local source = source
    deadPlayers[source] = nil
end)

AddEventHandler("vfw:playerDropped", function(source)
    deadPlayers[source] = nil
end)

AddEventHandler("vfw:playerLoaded", function(source)
    if not active then return end
    CreateThread(function()
        Wait(3000)
        TriggerClientEvent("koth:start", source, payload())
    end)
end)

local function staffOnly(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("builder_koth") or xPlayer.hasPermission("koth") or xPlayer.hasPermission("staff") or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

MiscB.Cb("koth:getZones", function(source)
    if not staffOnly(source) then return {} end
    return zones
end)

MiscB.Cb("koth:createZone", function(source, data)
    if not staffOnly(source) then return nil end
    if type(data) ~= "table" then return nil end

    local name = MiscB.Str(data.name, 64)
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not name or not x or not y or not z then return nil end

    local radius = MiscB.ToNum(data.radius, cfg("defaultRadius", 50.0))
    local duration = MiscB.ToInt(data.duration, 1, 720) or cfg("defaultDuration", 15)

    local id = MiscB.Insert([[
        INSERT INTO koth_zones (name, x, y, z, radius, duration, enabled, schedule_hours)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    ]], { name, x, y, z, radius, duration, VFW.DB.Encode(data.scheduleHours or {}) })

    loadZones()
    return id
end)

MiscB.Cb("koth:updateZone", function(source, zoneId, field, value)
    if not staffOnly(source) then return false end
    local zone = findZone(zoneId)
    if not zone then return false end

    if field == "enabled" then
        MiscB.Update("UPDATE koth_zones SET enabled = ? WHERE id = ?", { value and 1 or 0, zone.id })
    elseif field == "name" then
        local name = MiscB.Str(value, 64)
        if not name then return false end
        MiscB.Update("UPDATE koth_zones SET name = ? WHERE id = ?", { name, zone.id })
    elseif field == "radius" then
        local radius = MiscB.ToNum(value, nil)
        if not radius or radius <= 0 or radius > 1000 then return false end
        MiscB.Update("UPDATE koth_zones SET radius = ? WHERE id = ?", { radius, zone.id })
    elseif field == "duration" then
        local duration = MiscB.ToInt(value, 1, 720)
        if not duration then return false end
        MiscB.Update("UPDATE koth_zones SET duration = ? WHERE id = ?", { duration, zone.id })
    elseif field == "scheduleHours" then
        if type(value) ~= "table" then return false end
        MiscB.Update("UPDATE koth_zones SET schedule_hours = ? WHERE id = ?", { VFW.DB.Encode(value), zone.id })
    elseif field == "scheduleRange" then
        if type(value) ~= "table" then return false end
        MiscB.Update("UPDATE koth_zones SET schedule_start = ?, schedule_finish = ? WHERE id = ?",
            { MiscB.Str(value.start, 8), MiscB.Str(value.finish, 8), zone.id })
    else
        return false
    end

    loadZones()
    return true
end)

MiscB.Cb("koth:deleteZone", function(source, zoneId)
    if not staffOnly(source) then return false end
    local zone = findZone(zoneId)
    if not zone then return false end
    if active and active.id == zone.id then stopKoth(false) end

    MiscB.Update("DELETE FROM koth_zones WHERE id = ?", { zone.id })
    loadZones()
    return true
end)

MiscB.Cb("koth:forceStart", function(source, zoneId)
    if not staffOnly(source) then return false end
    local zone = findZone(zoneId)
    if not zone then return false end
    if active then return false end
    return startKoth(zone)
end)

MiscB.Cb("koth:forceStop", function(source)
    if not staffOnly(source) then return false end
    return stopKoth(false)
end)

MiscB.Cb("koth:forceStopWithWinner", function(source)
    if not staffOnly(source) then return false end
    return stopKoth(true)
end)

MiscB.Cb("koth:getHistory", function(source)
    if not staffOnly(source) then return {} end
    return MiscB.Query([[
        SELECT id, zone_id, zone_name, winner_faction, winner_score, started_at, ended_at
        FROM koth_history ORDER BY id DESC LIMIT 50
    ]], {})
end)

MiscB.Cb("koth:clearHistory", function(source)
    if not staffOnly(source) then return false end
    MiscB.Update("DELETE FROM koth_history", {})
    return true
end)
