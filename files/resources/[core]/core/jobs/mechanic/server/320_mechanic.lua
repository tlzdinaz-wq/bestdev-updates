VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Mechanic = VFW.Mechanic or {}

local JC = VFW.JobsCommon
local Mechanic = VFW.Mechanic

Mechanic.Items = {
    clean = "cleankit",
    body = "kitcarrosserie",
    engine = "repairkit",
}

Mechanic.FastRepairItem = "fastrepairkit"
Mechanic.FastRepairBonus = 250.0
Mechanic.FastRepairMax = 1000.0

local reserved = {}

local function itemFor(actionType)
    local action = JC.Str(actionType, 16)
    if not action then return nil end
    return Mechanic.Items[action], action
end

JC.Cb("mechanic:hasItem", function(source, actionType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local itemName = itemFor(actionType)
    if not itemName then return false end

    local has = JC.Count(xPlayer, itemName) >= 1
    if has then
        reserved[source] = { item = itemName, at = GetGameTimer() }
    end

    return has
end)

JC.Cb("mechanic:removeItem", function(source, actionType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local itemName, action = itemFor(actionType)
    if not itemName then return false end

    local slot = reserved[source]
    reserved[source] = nil

    if not slot or slot.item ~= itemName or (GetGameTimer() - slot.at) > 120000 then
        return false
    end

    if not JC.Throttle(source, "mechanic:consume", 1500) then return false end

    if not JC.Remove(xPlayer, itemName, 1) then return false end

    if VFW.Logs and VFW.Logs.Simple then
        VFW.Logs.Simple("job", "Mecano",
            ("%s a consomme %s (%s)"):format(JC.PlayerName(xPlayer), itemName, action))
    end

    return true
end)

AddEventHandler("playerDropped", function()
    local source = source
    reserved[source] = nil
end)

local function findVehicleByNetId(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    return entity
end

RegisterNetEvent("mechanic:fastRepair:apply", function(netId, newHealth)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = JC.Int(netId, 1)
    if not id then return end
    if newHealth ~= nil and type(newHealth) ~= "number" then return end

    if not JC.Throttle(source, "mechanic:fastrepair", 10000) then return end

    if JC.Count(xPlayer, Mechanic.FastRepairItem) < 1 then
        JC.Notify(source, "Vous n'avez pas de kit de reparation rapide.", true)
        return
    end

    local vehicle = findVehicleByNetId(id)
    if not vehicle then return end

    local coords = GetEntityCoords(vehicle)
    if JC.Dist(source, { x = coords.x, y = coords.y, z = coords.z }) > 12.0 then
        JC.Notify(source, "Vous etes trop loin du vehicule.", true)
        return
    end

    local current = GetVehicleEngineHealth(vehicle) or 0.0
    if current < 0.0 then current = 0.0 end

    local target = math.min(current + Mechanic.FastRepairBonus, Mechanic.FastRepairMax)
    if target <= current then
        JC.Notify(source, "Ce moteur est deja en bon etat.", true)
        return
    end

    if not JC.Remove(xPlayer, Mechanic.FastRepairItem, 1) then return end

    TriggerClientEvent("mechanic:fastRepair:applyToAll", -1, id, target)

    if VFW.Logs and VFW.Logs.Simple then
        VFW.Logs.Simple("job", "Mecano",
            ("%s a utilise un kit rapide (%d -> %d)"):format(JC.PlayerName(xPlayer), math.floor(current), math.floor(target)))
    end
end)

local function registerUsable(name, handler)
    local Inv = VFW.Inventory
    if not Inv or not Inv.RegisterUsableItem then return false end
    return Inv.RegisterUsableItem(name, handler)
end

CreateThread(function()
    Wait(0)

    for action, itemName in pairs(Mechanic.Items) do
        registerUsable(itemName, function(xPlayer)
            local src = xPlayer.source
            if not xPlayer.job or VFW.Jobs[xPlayer.job.name] == nil then
                JC.Notify(src, "Vous ne pouvez pas utiliser cet outil.", true)
                return
            end

            local jobType = VFW.Jobs[xPlayer.job.name].type
            if jobType ~= "mechanic" then
                JC.Notify(src, "Seuls les mecaniciens peuvent utiliser cet outil.", true)
                return
            end

            TriggerClientEvent("mechanic:useItem", src, action)
        end)
    end

    registerUsable(Mechanic.FastRepairItem, function(xPlayer)
        TriggerClientEvent("mechanic:useFastRepairKit", xPlayer.source)
    end)
end)

JC.EnsureJob("mechanic", "Mecanicien", "mechanic", {
    { grade = 0, name = "apprenti", label = "Apprenti", salary = 300, is_boss = 0 },
    { grade = 1, name = "mecanicien", label = "Mecanicien", salary = 500, is_boss = 0 },
    { grade = 2, name = "chef_atelier", label = "Chef d'atelier", salary = 750, is_boss = 0 },
    { grade = 3, name = "boss", label = "Patron", salary = 1100, is_boss = 1 },
})
