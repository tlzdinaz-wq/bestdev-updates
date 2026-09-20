local LOCKPICK_VEH_ITEM = "kit_de_crochetage_veh"
local CUFF_ITEMS = { "cordes", "handcuff" }
local UNCUFF_ITEMS = { "handcuff_key", "cordes", "handcuff" }
local MAX_ACTION_DISTANCE = 4.0

local FactionMenu = {
    unlockedVehicles = {},
}

local function IsCuffed(target)
    local state = Player(target).state
    if not state then return false end
    return state.isCuffed == true
end

local function FirstOwnedItem(xPlayer, list)
    for i = 1, #list do
        if xPlayer.haveItem(list[i], 1) then
            return list[i]
        end
    end
    return nil
end

local function DistanceBetween(source, target)
    local a = IL.Coords(source)
    local b = IL.Coords(target)
    if not a or not b then return 9999.0 end
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

IL.RegisterCallback("faction:menu:handcuff", function(source, targetServerId)
    local xPlayer = IL.Player(source)
    local targetId = IL.Int(targetServerId, nil)
    if not xPlayer or not targetId then return { success = false, message = "Cette cible n'est pas valide" } end
    if targetId == source then return { success = false, message = "Cette cible n'est pas valide" } end

    local xTarget = IL.Player(targetId)
    if not xTarget then return { success = false, message = "Cible introuvable" } end

    if DistanceBetween(source, targetId) > MAX_ACTION_DISTANCE then
        return { success = false, message = "Vous etes trop loin" }
    end

    if IsCuffed(targetId) then
        return { success = false, message = "La personne est deja attachee" }
    end

    if not FirstOwnedItem(xPlayer, CUFF_ITEMS) then
        return { success = false, message = "Il vous faut une corde ou des menottes" }
    end

    xTarget.handcuff()
    return { success = true, message = "Personne attachee" }
end)

IL.RegisterCallback("faction:menu:uncuff", function(source, targetServerId)
    local xPlayer = IL.Player(source)
    local targetId = IL.Int(targetServerId, nil)
    if not xPlayer or not targetId then return { success = false, message = "Cette cible n'est pas valide" } end

    local xTarget = IL.Player(targetId)
    if not xTarget then return { success = false, message = "Cible introuvable" } end

    if DistanceBetween(source, targetId) > MAX_ACTION_DISTANCE then
        return { success = false, message = "Vous etes trop loin" }
    end

    if not IsCuffed(targetId) then
        return { success = false, message = "La personne n'est pas attachee" }
    end

    if not FirstOwnedItem(xPlayer, UNCUFF_ITEMS) then
        return { success = false, message = "Il vous faut de quoi la detacher" }
    end

    xTarget.uncuff()
    return { success = true, message = "Personne detachee" }
end)

IL.RegisterCallback("faction:menu:canEscort", function(source, targetServerId)
    local targetId = IL.Int(targetServerId, nil)
    if not targetId then return false end
    if not IL.Player(targetId) then return false end
    if DistanceBetween(source, targetId) > MAX_ACTION_DISTANCE then return false end
    return IsCuffed(targetId)
end)

IL.RegisterCallback("vfw:faction:isPlayerCuffed", function(source, targetServerId)
    local targetId = IL.Int(targetServerId, nil)
    if not targetId then return false end
    if not IL.Player(targetId) then return false end
    return IsCuffed(targetId)
end)

IL.RegisterCallback("faction:menu:lockpick", function(source, netId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local id = IL.Int(netId, nil)
    if not id then return { success = false, message = "Ce vehicule n'est pas valide" } end

    if not xPlayer.haveItem(LOCKPICK_VEH_ITEM, 1) then
        return { success = false, message = "Vous n'avez pas de kit de crochetage vehicules" }
    end

    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return { success = false, message = "Vehicule introuvable" }
    end

    return { success = true, message = "" }
end)

IL.RegisterCallback("vfw:lockpickItem:hasItem", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false end
    return xPlayer.haveItem(LOCKPICK_VEH_ITEM, 1)
end)

local function HandleLockpickResult(source, netId, success)
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(netId, nil)
    if not id then return end

    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    if not xPlayer.haveItem(LOCKPICK_VEH_ITEM, 1) then return end

    local origin = IL.Coords(source)
    if not origin then return end
    local target = GetEntityCoords(entity)
    local dx, dy, dz = origin.x - target.x, origin.y - target.y, origin.z - target.z
    if math.sqrt(dx * dx + dy * dy + dz * dz) > 10.0 then return end

    if success then
        FactionMenu.unlockedVehicles[id] = { source = source, at = IL.Now() }
        local state = Entity(entity).state
        if state then
            state:set("lockpicked", true, true)
            state:set("doorsLocked", false, true)
        end
    else
        if math.random(1, 100) <= 25 then
            IL.TakeItem(xPlayer, LOCKPICK_VEH_ITEM, 1)
            IL.Notify(source, "ROUGE", "Votre kit de crochetage s'est casse.")
        end
        local coords = IL.Coords(source)
        if coords then
            IL.AlertPolice("core:police:vehicleAlarmAlert", { x = coords.x, y = coords.y, z = coords.z })
        end
    end
end

RegisterNetEvent("faction:menu:lockpickSuccess", function(netId)
    local source = source
    HandleLockpickResult(source, netId, true)
end)

RegisterNetEvent("faction:menu:lockpickFailed", function(netId)
    local source = source
    HandleLockpickResult(source, netId, false)
end)

RegisterNetEvent("vfw:lockpickItem:result", function(result, netId)
    local source = source
    if type(result) ~= "string" then return end
    HandleLockpickResult(source, netId, result == "success")
end)

CreateThread(function()
    while true do
        Wait(300000)
        local now = IL.Now()
        for netId, entry in pairs(FactionMenu.unlockedVehicles) do
            if now - entry.at > 3600 then
                FactionMenu.unlockedVehicles[netId] = nil
            end
        end
    end
end)

AddEventHandler("vfw:inventory:used", function(source, itemName)
    if itemName ~= LOCKPICK_VEH_ITEM then return end
    TriggerClientEvent("vfw:lockpickItem:start", source)
end)

RegisterNetEvent("vfw:lockpickItem:use", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if not xPlayer.haveItem(LOCKPICK_VEH_ITEM, 1) then return end
    TriggerClientEvent("vfw:lockpickItem:start", source)
end)
