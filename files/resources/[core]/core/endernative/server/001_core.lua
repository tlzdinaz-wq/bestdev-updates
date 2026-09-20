VFW.Players = {}
VFW.PlayersByIdentifier = {}
VFW.PlayersByCharId = {}
VFW.Items = {}
VFW.Jobs = {}
VFW.Factions = {}
VFW.Ready = false

local Config = Config

function VFW.GetConfig()
    return Config
end

function VFW.GetPlayerFromId(source)
    return VFW.Players[tonumber(source)]
end

function VFW.GetPlayerFromIdentifier(identifier)
    return VFW.PlayersByIdentifier[identifier]
end

function VFW.GetPlayerFromCharId(charId)
    return VFW.PlayersByCharId[tonumber(charId)]
end

function VFW.GetPlayers()
    local out, n = {}, 0
    for src in pairs(VFW.Players) do
        n = n + 1
        out[n] = src
    end
    return out
end

function VFW.GetExtendedPlayers(key, val)
    local out, n = {}, 0
    for _, xPlayer in pairs(VFW.Players) do
        if key then
            if key == "job" and xPlayer.job.name == val then
                n = n + 1
                out[n] = xPlayer
            elseif key == "faction" and xPlayer.faction and xPlayer.faction.name == val then
                n = n + 1
                out[n] = xPlayer
            elseif xPlayer[key] == val then
                n = n + 1
                out[n] = xPlayer
            end
        else
            n = n + 1
            out[n] = xPlayer
        end
    end
    return out
end

function VFW.GetPlayersWithJobs(jobs)
    local wanted = {}
    if type(jobs) == "string" then
        wanted[jobs] = true
    else
        for i = 1, #jobs do
            wanted[jobs[i]] = true
        end
    end

    local out, n = {}, 0
    for _, xPlayer in pairs(VFW.Players) do
        if wanted[xPlayer.job.name] or (xPlayer.faction and wanted[xPlayer.faction.name]) then
            n = n + 1
            out[n] = xPlayer
        end
    end
    return out
end

function VFW.GetPlayersInJobsOnDuty(jobs)
    local players = VFW.GetPlayersWithJobs(jobs)
    local out, n = {}, 0
    for i = 1, #players do
        if players[i].job.onDuty then
            n = n + 1
            out[n] = players[i]
        end
    end
    return out
end

function VFW.GetPlayerCount()
    local n = 0
    for _ in pairs(VFW.Players) do n = n + 1 end
    return n
end

function VFW.GetIdentifiers(source)
    local ids = {}
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        local kind, value = id:match("^(%w+):(.+)$")
        if kind then
            ids[kind] = value
            ids[#ids + 1] = id
        end
    end
    return ids
end

function VFW.GetIdentifier(source)
    local license = GetPlayerIdentifierByType(source, "license")
    return license
end

function VFW.GetCharIdentifier(source, slot)
    local license = VFW.GetIdentifier(source)
    if not license then return nil end
    return ("%s%d:%s"):format(Config.Multicharacter.Prefix, slot, license)
end

function VFW.ParseCharIdentifier(identifier)
    local slot, license = identifier:match("^" .. Config.Multicharacter.Prefix .. "(%d+):(.+)$")
    return tonumber(slot), license
end

function VFW.GetPlayersInRadius(coords, radius)
    local out, n = {}, 0
    local rsq = radius * radius
    for src, xPlayer in pairs(VFW.Players) do
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local pc = GetEntityCoords(ped)
            local dx, dy, dz = pc.x - coords.x, pc.y - coords.y, pc.z - coords.z
            if (dx * dx + dy * dy + dz * dz) <= rsq then
                n = n + 1
                out[n] = xPlayer
            end
        end
    end
    return out
end

function VFW.ShowNotification(source, data)
    TriggerClientEvent("vfw:showNotification", source, data)
end

function VFW.ShowHelpNotification(source, msg, thisFrame, beep, duration)
    TriggerClientEvent("vfw:showHelpNotification", source, msg, thisFrame, beep, duration)
end

function VFW.HasPermission(source, permission)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission(permission)
end

function VFW.SetGlobalPlayerCount()
    GlobalState.playerCount = VFW.GetPlayerCount()
end

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    GlobalState.playerCount = 0
    if GlobalState.AntiAttachEnabled == nil then
        GlobalState.AntiAttachEnabled = true
    end
end)
