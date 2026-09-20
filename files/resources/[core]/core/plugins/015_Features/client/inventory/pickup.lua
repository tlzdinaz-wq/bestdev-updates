---@meta _
---@diagnostic disable: duplicate-doc-field

local pickups = {}

VFW.ContextAddButton("object", ":eye: Voir le contenu", function(object)
    return NetworkGetEntityIsNetworked(object) and (pickups[NetworkGetNetworkIdFromEntity(object)] ~= nil)
end, function(object)
    if not NetworkGetEntityIsNetworked(object) then return end
    local pickupId = pickups[NetworkGetNetworkIdFromEntity(object)]
    local inventory, weight, maxWeight, name = TriggerServerCallback("vfw:pickup:get", pickupId)

    Wait(250)

    VFW.OpenInventory({
        pickupId = pickupId,
        inventory = inventory,
        name = name,
        maxWeight = maxWeight,
        weight = weight,
        search = false,
    })
end)

VFW.ContextAddButton("object", ":box: Récupérer", function(object)
    return NetworkGetEntityIsNetworked(object) and (pickups[NetworkGetNetworkIdFromEntity(object)] ~= nil)
end, function(object)
    if not NetworkGetEntityIsNetworked(object) then return end
    local pickupId = pickups[NetworkGetNetworkIdFromEntity(object)]
    local inventory, weight, maxWeight, name = TriggerServerCallback("vfw:pickup:get", pickupId)

    TriggerServerEvent("vfw:pickup:take",pickupId, inventory)

end)
---@param pickups any
RegisterNetEvent("vfw:pickup:load", function(pickups)
    pickups = pickups
end)

---@param networkId any
---@param chestId any
RegisterNetEvent("vfw:pickup:register", function(networkId, chestId)
    pickups[networkId] = chestId
end)

---@param networkId any
---@param oldEntity any
RegisterNetEvent("vfw:pickup:changeProps", function(networkId, oldEntity)
    pickups[networkId] = pickups[oldEntity]
    pickups[oldEntity] = nil
end)

---@param pickupId any
---@param networkId number|nil Network id of the pickup prop (for client-side fallback delete)
RegisterNetEvent("vfw:pickup:unregister", function(pickupId, networkId)
    -- Always clear the local mapping, even when the entity isn't currently
    -- streamed to this client. Otherwise the context menu keeps offering
    -- "Récupérer" on an orphan prop and the take callback hits a nil chest.
    if networkId then
        pickups[networkId] = nil

        -- Server-side DeleteEntity can silently fail on networked props once a
        -- client has taken ownership. Retry the local delete in a loop until
        -- the entity is actually gone (or we give up after ~4s).
        if NetworkDoesNetworkIdExist(networkId) then
            CreateThread(function()
                local attempts = 0
                while attempts < 40 do
                    if not NetworkDoesNetworkIdExist(networkId) then return end
                    local entity = NetworkGetEntityFromNetworkId(networkId)
                    if entity == 0 or not DoesEntityExist(entity) then return end

                    NetworkRequestControlOfEntity(entity)
                    if NetworkHasControlOfEntity(entity) then
                        SetEntityAsMissionEntity(entity, true, true)
                        DeleteEntity(entity)
                        if not DoesEntityExist(entity) then return end
                    end
                    Wait(100)
                    attempts = attempts + 1
                end
            end)
        end
    end

    if VFW.StateInventory() and VFW.PlayerData.target and VFW.PlayerData.target.pickupId == pickupId then
        VFW.PlayerData.target = nil
        VFW.LoadInventories()
    end
end)



RegisterNetEvent("vfw:playDropAnim", function()
    local playerPed = PlayerPedId()

    RequestAnimDict("random@domestic")
    while not HasAnimDictLoaded("random@domestic") do
        Wait(10)
    end

    TaskPlayAnim(playerPed, "random@domestic", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)

    Wait(1000)

    ClearPedTasks(playerPed)
end)