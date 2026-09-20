local MAX_PER_CALL = 64
local WINDOW_MS = 10000
local MAX_PER_WINDOW = 120

local budgets = {}

VFW.Entity = VFW.Entity or {}

local function consumeBudget(source, amount)
    local now = GetGameTimer()
    local budget = budgets[source]

    if not budget or now >= budget.resetAt then
        budget = { resetAt = now + WINDOW_MS, used = 0 }
        budgets[source] = budget
    end

    if budget.used + amount > MAX_PER_WINDOW then
        return false
    end

    budget.used = budget.used + amount
    return true
end

local function buildProtectedSet()
    local peds, vehicles = {}, {}

    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped and ped ~= 0 then
            peds[ped] = true

            local vehicle = GetVehiclePedIsIn(ped)
            if vehicle and vehicle ~= 0 then
                vehicles[vehicle] = true
            end
        end
    end

    return { peds = peds, vehicles = vehicles }
end

function VFW.Entity.DeleteByNetId(netId, protected)
    netId = tonumber(netId)
    if not netId or netId <= 0 then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end

    protected = protected or buildProtectedSet()

    if protected.peds[entity] then return false end
    if protected.vehicles[entity] then return false end

    DeleteEntity(entity)
    return true
end

function VFW.Entity.DeleteMany(netIds)
    local deleted = 0
    if type(netIds) ~= "table" then return deleted end

    local protected = buildProtectedSet()

    for i = 1, #netIds do
        if VFW.Entity.DeleteByNetId(netIds[i], protected) then
            deleted = deleted + 1
        end
    end

    return deleted
end

RegisterNetEvent("vfw:deleteEntity", function(netIds)
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(netIds) == "number" then
        netIds = { netIds }
    end

    if type(netIds) ~= "table" then return end

    local list, count = {}, 0
    for i = 1, #netIds do
        local netId = tonumber(netIds[i])
        if netId and netId > 0 then
            count = count + 1
            list[count] = netId
            if count >= MAX_PER_CALL then break end
        end
    end

    if count == 0 then return end

    if not xPlayer.hasPermission("clean_zone") and not consumeBudget(source, count) then
        console.warn(("[Entity] %s (%d) depasse le quota de suppression d'entites."):format(tostring(xPlayer.name), source))
        return
    end

    VFW.Entity.DeleteMany(list)
end)

AddEventHandler("playerDropped", function()
    local source = source
    budgets[source] = nil
end)
