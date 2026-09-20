local carriedBy = {}
local carrying = {}
local cookies = {}
local active = true

local MAX_CARRY_DISTANCE = 6.0

local function breakPair(carrierSrc, notifyCarrier, notifyCarried)
    local targetSrc = carrying[carrierSrc]
    if not targetSrc then return false end

    carrying[carrierSrc] = nil
    if carriedBy[targetSrc] == carrierSrc then
        carriedBy[targetSrc] = nil
    end

    if notifyCarried and VFW.GetPlayerFromId(targetSrc) then
        TriggerClientEvent("CarryPeople:cl_stop", targetSrc)
    end

    if notifyCarrier and VFW.GetPlayerFromId(carrierSrc) then
        TriggerClientEvent("CarryPeople:cl_stop", carrierSrc)
    end

    return true
end

local function claim(eventName, handler)
    RegisterNetEvent(eventName)
    cookies[#cookies + 1] = AddEventHandler(eventName, handler)
end

claim("CarryPeople:sync", function(targetSrc)
    local source = source
    if not active then return end

    local target = Misc30.ToInt(targetSrc, 1)
    if not target or target == source then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if not Misc30.RateLimit(source, "carrySync", 750) then return end

    if carrying[source] then
        breakPair(source, false, true)
    end

    if carriedBy[target] and carriedBy[target] ~= source then return end
    if carrying[target] then return end
    if carriedBy[source] then return end

    if not Misc30.NearPlayers(source, target, MAX_CARRY_DISTANCE) then
        Misc30.Notify(source, "ROUGE", "Cette personne est trop loin.")
        return
    end

    carrying[source] = target
    carriedBy[target] = source

    TriggerClientEvent("CarryPeople:syncTarget", target, source)
end)

claim("CarryPeople:stop", function(targetSrc)
    local source = source
    if not active then return end

    local target = Misc30.ToInt(targetSrc, 1)
    if carrying[source] and (not target or carrying[source] == target) then
        breakPair(source, false, true)
        return
    end

    if target and carriedBy[target] == source then
        carrying[source] = target
        breakPair(source, false, true)
    end
end)

claim("CarryPeople:requestStop", function()
    local source = source
    if not active then return end

    local carrier = carriedBy[source]
    if not carrier then return end

    carriedBy[source] = nil
    if carrying[carrier] == source then
        carrying[carrier] = nil
    end

    if VFW.GetPlayerFromId(carrier) then
        TriggerClientEvent("CarryPeople:cl_stop", carrier)
    end
end)

claim("interaction:tackle", function(targetServerId)
    local source = source
    if not active then return end

    local target = Misc30.ToInt(targetServerId, 1)
    if not target or target == source then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if not Misc30.RateLimit(source, "tackle", 5000) then return end
    if not Misc30.NearPlayers(source, target, 4.0) then return end

    TriggerClientEvent("interaction:tackle:attacker", source, target)
    TriggerClientEvent("interaction:tackle:victim", target, source)
end)

CreateThread(function()
    Wait(0)

    if type(MiscB) ~= "table" then return end

    active = false
    for i = 1, #cookies do
        if cookies[i] then
            pcall(RemoveEventHandler, cookies[i])
        end
    end
    cookies = {}
end)

AddEventHandler("vfw:playerDropped", function(source)
    if carrying[source] then
        breakPair(source, false, true)
    end

    local carrier = carriedBy[source]
    if carrier then
        carriedBy[source] = nil
        if carrying[carrier] == source then
            carrying[carrier] = nil
        end
        if VFW.GetPlayerFromId(carrier) then
            TriggerClientEvent("CarryPeople:cl_stop", carrier)
        end
    end
end)

AddEventHandler("vfw:onPlayerDeath", function(source)
    local src = tonumber(source)
    if not src then return end
    if carrying[src] then
        breakPair(src, true, true)
    end
end)

function Misc30.IsCarrying(source)
    if not active then return false end
    return carrying[tonumber(source) or 0] ~= nil
end

function Misc30.IsCarried(source)
    if not active then return false end
    return carriedBy[tonumber(source) or 0] ~= nil
end
