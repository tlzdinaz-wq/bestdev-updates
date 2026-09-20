local AmbientSounds = {}
local ActiveSounds = {}
local xSound = exports.xsound

local function IsPointInPolygon(points, x, y)
    if not points or #points < 3 then
        return false
    end

    local inZone = false
    local j = #points

    for i = 1, #points do
        local pi = points[i]
        local pj = points[j]

        if pi and pj then
            if ((pi.y < y and pj.y >= y) or (pj.y < y and pi.y >= y)) and (pi.x <= x or pj.x <= x) then
                if pi.x + (y - pi.y) / (pj.y - pi.y) * (pj.x - pi.x) < x then
                    inZone = not inZone
                end
            end
        end

        j = i
    end

    return inZone
end

local function GetMaxDistFromSource(zone)
    if not zone.sourcePosition or not zone.points or #zone.points == 0 then
        return 50.0
    end

    local sourceVec = vector3(zone.sourcePosition.x, zone.sourcePosition.y, zone.sourcePosition.z)
    local maxDist = 0.0

    for i = 1, #zone.points do
        local p = zone.points[i]
        local dist = #(sourceVec - vector3(p.x, p.y, p.z))
        if dist > maxDist then
            maxDist = dist
        end
    end

    return maxDist > 0 and maxDist or 50.0
end

RegisterNetEvent("core:ambientSound:sync", function(data)
    if type(data) ~= "table" then return end

    local newIds = {}
    for id, _ in pairs(data) do
        newIds[id] = true
    end

    for id, _ in pairs(ActiveSounds) do
        if not newIds[id] or (data[id] and not data[id].active) then
            local soundId = "ambient_" .. id
            if xSound:soundExists(soundId) then
                xSound:Destroy(soundId)
            end
            ActiveSounds[id] = nil
        end
    end

    AmbientSounds = data
end)

RegisterNetEvent("core:ambientSound:syncTimestamp", function(zoneId, elapsed)
    local soundId = "ambient_" .. zoneId
    if elapsed and elapsed > 0 then
        SetTimeout(500, function()
            if xSound:soundExists(soundId) then
                xSound:setTimeStamp(soundId, elapsed)
            end
        end)
    end
end)

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hasActiveZone = false

        for id, zone in pairs(AmbientSounds) do
            if zone.active and zone.points and #zone.points >= 3 and zone.sourcePosition and zone.url then
                local baseZ = zone.points[1].z
                local height = zone.height or 10.0
                local isInside = IsPointInPolygon(zone.points, playerCoords.x, playerCoords.y)
                    and playerCoords.z >= (baseZ - 5.0)
                    and playerCoords.z <= (baseZ + height + 5.0)

                local soundId = "ambient_" .. id

                if isInside then
                    hasActiveZone = true
                    local sourceVec = vector3(zone.sourcePosition.x, zone.sourcePosition.y, zone.sourcePosition.z)
                    local dist = #(playerCoords - sourceVec)
                    local maxDist = GetMaxDistFromSource(zone)
                    local falloff = zone.falloff or 1.0
                    local volumeRatio = math.max(0.0, 1.0 - (dist / maxDist) ^ falloff)
                    local finalVolume = (zone.volume / 100.0) * volumeRatio

                    if not ActiveSounds[id] then
                        xSound:PlayUrl(soundId, zone.url, finalVolume)
                        xSound:setSoundLoop(soundId, true)
                        ActiveSounds[id] = true

                        TriggerServerEvent("core:ambientSound:requestSync", id)
                    else
                        if xSound:soundExists(soundId) then
                            xSound:setVolume(soundId, finalVolume)
                        end
                    end
                else
                    if ActiveSounds[id] then
                        if xSound:soundExists(soundId) then
                            xSound:Destroy(soundId)
                        end
                        ActiveSounds[id] = nil
                    end
                end
            end
        end

        Wait(hasActiveZone and 250 or 1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for id, _ in pairs(ActiveSounds) do
        local soundId = "ambient_" .. id
        if xSound:soundExists(soundId) then
            xSound:Destroy(soundId)
        end
    end
    ActiveSounds = {}
end)
