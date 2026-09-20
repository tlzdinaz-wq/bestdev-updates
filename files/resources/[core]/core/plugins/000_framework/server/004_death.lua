local KnockoutDuration = 30000

local Hospitals = {
    { x = 298.68, y = -584.63, z = 43.26, h = 78.0 },
    { x = 1151.20, y = -1529.62, z = 34.83, h = 0.0 },
    { x = -247.76, y = 6331.23, z = 32.42, h = 225.0 },
}

local function nearestHospital(coords)
    if type(coords) ~= "table" or not coords.x then return Hospitals[1] end

    local best, bestDist = Hospitals[1], math.huge
    for i = 1, #Hospitals do
        local h = Hospitals[i]
        local dx, dy, dz = h.x - coords.x, h.y - coords.y, h.z - (coords.z or 0)
        local dist = dx * dx + dy * dy + dz * dz
        if dist < bestDist then
            best, bestDist = h, dist
        end
    end
    return best
end

local function countEMS()
    local ems = VFW.GetPlayersInJobsOnDuty({ "ambulance", "sams", "ems" })
    return #ems
end

RegisterNetEvent("vfw:onPlayerDeath", function(reason, killerServerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.dead = true
    xPlayer.setMeta("health", 0)

    TriggerEvent("vfw:playerDeath", source, reason, killerServerId)
end)

RegisterNetEvent("vfw:onPlayerRevived", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.dead = false
    xPlayer.setMeta("health", 200)

    TriggerEvent("vfw:playerRevived", source)
end)

RegisterNetEvent("esx_ambulanceJob:playerNowDead", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.dead = true
    xPlayer.setMeta("health", 0)
end)

RegisterNetEvent("death:getEMSCount", function()
    local source = source
    TriggerClientEvent("death:receiveEMSCount", source, countEMS(), source)
end)

RegisterNetEvent("deathscreen:respawnPlayer", function(coords)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local spawn = nearestHospital(type(coords) == "table" and coords or xPlayer.getCoords())
    TriggerClientEvent("deathscreen:doRespawn", source, spawn)
end)

RegisterNetEvent("core:server:onPlayerRespawn", function(emsCount)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.dead = false
    xPlayer.setMeta("health", (tonumber(emsCount) or 0) > 0 and 100 or 200)

    TriggerEvent("vfw:playerRespawned", source, tonumber(emsCount) or 0)
end)

RegisterNetEvent("deathscreen:callEmergency", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local coords = xPlayer.getCoords()
    local ems = VFW.GetPlayersInJobsOnDuty({ "ambulance", "sams", "ems" })
    for i = 1, #ems do
        TriggerClientEvent("sn_sams:newCallAlert", ems[i].source, {
            type = "mort",
            coords = coords,
            msg = ("%s %s"):format(xPlayer.firstName, xPlayer.lastName),
        })
    end
end)

RegisterNetEvent("sn_sams:newCallAlert", function(payload)
    local source = source
    if type(payload) ~= "table" then return end

    local ems = VFW.GetPlayersInJobsOnDuty({ "ambulance", "sams", "ems" })
    for i = 1, #ems do
        TriggerClientEvent("sn_sams:newCallAlert", ems[i].source, payload)
    end
end)

RegisterNetEvent("death:deleteClone", function(netId)
    local source = source
    if type(netId) ~= "number" then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

RegisterNetEvent("vfw:startko", function(playerServerId)
    local source = source
    if tonumber(playerServerId) ~= source then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerClientEvent("vfw:startko", source, KnockoutDuration)
end)

RegisterNetEvent("vfw:logs:onPlayerDeath", function(data)
    local source = source
    if type(data) ~= "table" then return end

    TriggerEvent("vfw:logs:death", source, data)
end)

RegisterServerCallback("vip:getRespawnTime", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 600 end

    local tier = xPlayer.vipTier or 0
    if tier >= 3 or xPlayer.hasPermission("vip_gold") then return 60 end
    if tier >= 2 or xPlayer.hasPermission("vip_silver") then return 180 end
    if tier >= 1 or xPlayer.hasPermission("vip_bronze") then return 300 end
    return 600
end)

function VFW.RevivePlayer(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.revive()
end

RegisterNetEvent("core:staff:treatZone", function(reviveList, healList)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("zone_actions") then return end

    if type(reviveList) == "table" then
        for i = 1, #reviveList do
            local target = VFW.GetPlayerFromId(tonumber(reviveList[i]))
            if target then target.revive() end
        end
    end

    if type(healList) == "table" then
        for i = 1, #healList do
            local id = tonumber(healList[i])
            local target = VFW.GetPlayerFromId(id)
            if target then
                target.setMeta("health", 200)
                TriggerClientEvent("core:jobs:client:HealthPlayer", id, 200)
            end
        end
    end
end)

RegisterNetEvent("ac:reportAttachExploit", function(netId)
    local source = source
    if type(netId) ~= "number" then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    if GetEntityModel(entity) ~= 1336576410 then return end

    local owner = NetworkGetEntityOwner(entity)
    DeleteEntity(entity)

    console.warn(("[AC] prop d'exploit supprimé (netId %d, owner %s), signalé par %d"):format(netId, tostring(owner), source))
    TriggerEvent("vfw:ac:flag", owner, "attach_exploit")
    TriggerClientEvent("ac:reviveIfDead", source)
end)

RegisterNetEvent("ac:flagBlacklistedAnimation", function(dict, name)
    local source = source
    if type(dict) ~= "string" or type(name) ~= "string" then return end
    console.warn(("[AC] animation blacklistée %s/%s par %d"):format(dict, name, source))
    TriggerEvent("vfw:ac:flag", source, "blacklisted_animation")
end)

RegisterNetEvent("imASlut", function()
    local source = source
    console.warn(("[AC] canary anti-tamper déclenché par %d"):format(source))
    TriggerEvent("vfw:ac:flag", source, "resource_stop")
end)
