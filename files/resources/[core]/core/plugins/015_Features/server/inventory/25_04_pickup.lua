local Inv = VFW.Inventory

local pickupCounter = 0
local PICKUP_LIFETIME = 20 * 60 * 1000
local MERGE_DISTANCE = 1.2

local function newPickupId()
    pickupCounter = pickupCounter + 1
    return ("pickup:%d:%d"):format(os.time(), pickupCounter)
end

function Inv.PickupPayload(pickup)
    return Inv.Serialize(pickup.items), Inv.ListWeight(pickup.items)
end

function Inv.RefreshPickupViewers(pickupId, exceptSource)
    local pickup = Inv.Pickups[pickupId]
    if not pickup then return end
    local items, weight = Inv.PickupPayload(pickup)
    Inv.Broadcast("pickup", pickupId, items, weight, exceptSource)
end

local function refreshNearbyFor(coords)
    for source in pairs(VFW.Players) do
        local playerCoords = Inv.PlayerCoords(source)
        if playerCoords and Inv.Distance(playerCoords, coords) <= Inv.PickupRadius + 6.0 then
            TriggerClientEvent("vfw:nearbyPickups:refresh", source)
        end
    end
end

function Inv.DestroyPickup(pickupId)
    local pickup = Inv.Pickups[pickupId]
    if not pickup then return end

    Inv.Pickups[pickupId] = nil

    for source, viewer in pairs(Inv.Viewers) do
        if viewer.kind == "pickup" and viewer.id == pickupId then
            Inv.Viewers[source] = nil
        end
    end

    TriggerClientEvent("vfw:pickup:unregister", -1, pickupId, pickup.netId)

    if pickup.entity and DoesEntityExist(pickup.entity) then
        DeleteEntity(pickup.entity)
    end

    refreshNearbyFor(pickup.coords)
end

local function spawnPickupProp(pickup)
    local object = CreateObject(Inv.PickupModel, pickup.coords.x, pickup.coords.y, pickup.coords.z - 0.95, true, true, false)

    local tries = 0
    while not DoesEntityExist(object) and tries < 60 do
        Wait(10)
        tries = tries + 1
    end

    if not DoesEntityExist(object) then return false end

    pcall(SetEntityOrphanMode, object, 2)
    pcall(FreezeEntityPosition, object, true)

    pickup.entity = object
    pickup.netId = NetworkGetNetworkIdFromEntity(object)

    TriggerClientEvent("vfw:pickup:register", -1, pickup.netId, pickup.id)
    return true
end

function Inv.FindNearbyPickup(coords)
    for pickupId, pickup in pairs(Inv.Pickups) do
        if Inv.Distance(pickup.coords, coords) <= MERGE_DISTANCE then
            return pickupId, pickup
        end
    end
    return nil
end

function Inv.CreatePickup(coords, label)
    local pickupId = newPickupId()
    local pickup = {
        id = pickupId,
        items = {},
        coords = { x = coords.x, y = coords.y, z = coords.z },
        label = label or "Objets au sol",
        createdAt = GetGameTimer(),
    }

    Inv.Pickups[pickupId] = pickup

    if not spawnPickupProp(pickup) then
        Inv.Pickups[pickupId] = nil
        return nil
    end

    return pickupId, pickup
end

function Inv.DropToGround(coords, name, count, meta, label)
    local pickupId, pickup = Inv.FindNearbyPickup(coords)
    if not pickup then
        pickupId, pickup = Inv.CreatePickup(coords, label)
    end
    if not pickup then return 0 end

    local added = Inv.AddToList(pickup.items, name, count, meta, Inv.PickupMaxSlots)
    pickup.createdAt = GetGameTimer()

    if added > 0 then
        Inv.RefreshPickupViewers(pickupId)
        refreshNearbyFor(pickup.coords)
    end

    return added, pickupId
end

Inv.RegisterCallback("vfw:dropItem", function(source, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    if Inv.IsCuffed(source) then
        Inv.Toast(source, "Vous ne pouvez pas faire cette action en etant menotte")
        return Inv.Payload(xPlayer)
    end

    local prison = xPlayer.getMeta("prison")
    if type(prison) == "table" and prison.isPrisoned then
        Inv.Toast(source, "Vous ne pouvez pas faire cette action en prison")
        return Inv.Payload(xPlayer)
    end

    local coords = Inv.PlayerCoords(source)
    if not coords then
        return Inv.Payload(xPlayer)
    end

    local entries = Inv.ParseInfo(info)
    local dropped = 0

    for i = 1, #entries do
        -- Inv.DropToGround rend la main le temps de faire apparaitre le prop : la liste
        -- se relit a chaque tour, sinon les tours suivants ecrivent dans une table morte.
        local list = Inv.PlayerList(xPlayer)
        local request = entries[i]
        local entry = Inv.FindSlot(list, request.slot)
        if entry then
            local def = Inv.Def(entry.name)
            if def and def.canRemove == false then
                Inv.Toast(source, "Cet objet ne peut pas etre jete.")
            else
                local quantity = request.quantity
                if quantity <= 0 or quantity > entry.count then quantity = entry.count end

                local taken = Inv.RemoveFromSlot(list, request.slot, quantity)
                if taken then
                    local added = Inv.DropToGround(coords, taken.name, taken.count, taken.meta)
                    if added < taken.count then
                        Inv.AddToList(Inv.PlayerList(xPlayer), taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
                    end
                    dropped = dropped + added
                end
            end
        end
    end

    if dropped > 0 then
        TriggerClientEvent("vfw:playDropAnim", source)
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterCallback("vfw:pickup:get", function(source, pickupId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(pickupId) ~= "string" then return {}, 0, Inv.PickupMaxWeight, "Objets au sol" end

    local pickup = Inv.Pickups[pickupId]
    if not pickup then return {}, 0, Inv.PickupMaxWeight, "Objets au sol" end

    Inv.SetViewer(source, "pickup", pickupId)

    local items, weight = Inv.PickupPayload(pickup)
    return items, weight, Inv.PickupMaxWeight, pickup.label
end)

Inv.RegisterCallback("vfw:pickup:getNearby", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {}, 0, Inv.PickupMaxWeight, "Autour de moi" end

    local coords = Inv.PlayerCoords(source)
    if not coords then return {}, 0, Inv.PickupMaxWeight, "Autour de moi" end

    local aggregate = {}
    local map = {}
    local slot = 0

    for pickupId, pickup in pairs(Inv.Pickups) do
        if Inv.Distance(pickup.coords, coords) <= Inv.PickupRadius then
            for i = 1, #pickup.items do
                slot = slot + 1
                local entry = pickup.items[i]
                aggregate[#aggregate + 1] = {
                    name = entry.name,
                    count = entry.count,
                    slot = slot,
                    position = slot,
                    meta = entry.meta or {},
                }
                map[slot] = { pickupId = pickupId, slot = entry.slot }
            end
        end
    end

    Inv.NearbyMap[source] = map

    return aggregate, Inv.ListWeight(aggregate), Inv.PickupMaxWeight, "Autour de moi"
end)

Inv.RegisterCallback("vfw:pickup:put-item", function(source, pickupId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local list = Inv.PlayerList(xPlayer)

    if type(pickupId) ~= "string" then return Inv.Payload(xPlayer) end
    if Inv.IsCuffed(source) then return Inv.Payload(xPlayer) end

    local pickup = Inv.Pickups[pickupId]
    if not pickup then return Inv.Payload(xPlayer) end

    local coords = Inv.PlayerCoords(source)
    if not coords or Inv.Distance(coords, pickup.coords) > Inv.PickupRadius then
        Inv.Toast(source, "Vous etes trop loin.")
        return Inv.Payload(xPlayer)
    end

    local entries = Inv.ParseInfo(info)
    local moved = 0

    for i = 1, #entries do
        local request = entries[i]
        local entry = Inv.FindSlot(list, request.slot)
        if entry then
            local quantity = request.quantity
            if quantity <= 0 or quantity > entry.count then quantity = entry.count end

            local taken = Inv.RemoveFromSlot(list, request.slot, quantity)
            if taken then
                local added = Inv.AddToList(pickup.items, taken.name, taken.count, taken.meta, Inv.PickupMaxSlots, request.targetSlot)
                if added < taken.count then
                    Inv.AddToList(list, taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
                end
                moved = moved + added
            end
        end
    end

    if moved > 0 then
        pickup.createdAt = GetGameTimer()
        Inv.RefreshPickupViewers(pickupId, source)
        refreshNearbyFor(pickup.coords)
    end

    return Inv.Payload(xPlayer)
end)

local function takeFromPickup(xPlayer, pickup, request)
    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindSlot(pickup.items, request.slot)
    if not entry then return 0, false end

    local quantity = request.quantity
    if quantity <= 0 or quantity > entry.count then quantity = entry.count end

    local carryable = Inv.MaxCarryable(xPlayer, entry.name, quantity)
    if carryable <= 0 then return 0, true end

    local tooHeavy = carryable < quantity
    local taken = Inv.RemoveFromSlot(pickup.items, request.slot, carryable)
    if not taken then return 0, tooHeavy end

    local added = Inv.AddToList(list, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots, request.targetSlot)
    if added < taken.count then
        Inv.AddToList(pickup.items, taken.name, taken.count - added, taken.meta, Inv.PickupMaxSlots)
    end

    return added, tooHeavy
end

Inv.RegisterCallback("vfw:pickup:take-item", function(source, pickupId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    Inv.PlayerList(xPlayer)

    if type(pickupId) ~= "string" then return Inv.Payload(xPlayer) end

    local pickup = Inv.Pickups[pickupId]
    if not pickup then return Inv.Payload(xPlayer) end

    local coords = Inv.PlayerCoords(source)
    if not coords or Inv.Distance(coords, pickup.coords) > Inv.PickupRadius then
        Inv.Toast(source, "Vous etes trop loin.")
        return Inv.Payload(xPlayer)
    end

    local entries = Inv.ParseInfo(info)
    local moved, tooHeavy = 0, false

    for i = 1, #entries do
        local added, heavy = takeFromPickup(xPlayer, pickup, entries[i])
        moved = moved + added
        if heavy then tooHeavy = true end
    end

    if tooHeavy then
        Inv.Toast(source, "Vous ne pouvez pas porter autant.")
    end

    if moved > 0 then
        if #pickup.items == 0 then
            Inv.DestroyPickup(pickupId)
        else
            Inv.RefreshPickupViewers(pickupId, source)
            refreshNearbyFor(pickup.coords)
        end
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterCallback("vfw:pickup:takeFromNearby", function(source, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    Inv.PlayerList(xPlayer)

    local map = Inv.NearbyMap[source]
    if not map then return Inv.Payload(xPlayer) end

    local coords = Inv.PlayerCoords(source)
    if not coords then return Inv.Payload(xPlayer) end

    local entries = Inv.ParseInfo(info)
    local touched = {}
    local moved, tooHeavy = 0, false
    local outOfRange = false

    for i = 1, #entries do
        local request = entries[i]
        local resolved = map[request.slot]
        if resolved then
            local pickup = Inv.Pickups[resolved.pickupId]
            if pickup and Inv.Distance(coords, pickup.coords) > Inv.PickupRadius then
                -- La carte du menu date de vfw:pickup:getNearby et ne perime jamais :
                -- sans ce controle elle sert a vider un tas depuis l'autre bout de la carte.
                outOfRange = true
            elseif pickup then
                local added, heavy = takeFromPickup(xPlayer, pickup, {
                    slot = resolved.slot,
                    quantity = request.quantity,
                    targetSlot = request.targetSlot,
                })
                moved = moved + added
                if heavy then tooHeavy = true end
                touched[resolved.pickupId] = true
            end
        end
    end

    if outOfRange then
        Inv.Toast(source, "Vous etes trop loin.")
    end

    if tooHeavy then
        Inv.Toast(source, "Vous ne pouvez pas porter autant.")
    end

    for pickupId in pairs(touched) do
        local pickup = Inv.Pickups[pickupId]
        if pickup and #pickup.items == 0 then
            Inv.DestroyPickup(pickupId)
        elseif pickup then
            Inv.RefreshPickupViewers(pickupId)
            refreshNearbyFor(pickup.coords)
        end
    end

    if moved > 0 then
        TriggerClientEvent("vfw:nearbyPickups:refresh", source)
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterNet("vfw:pickup:take", function(pickupId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(pickupId) ~= "string" then return end

    local pickup = Inv.Pickups[pickupId]
    if not pickup then return end

    local coords = Inv.PlayerCoords(source)
    if not coords or Inv.Distance(coords, pickup.coords) > Inv.PickupRadius then
        Inv.Toast(source, "Vous etes trop loin.")
        return
    end

    local list = Inv.PlayerList(xPlayer)
    local tooHeavy = false

    for i = #pickup.items, 1, -1 do
        local entry = pickup.items[i]
        local carryable = Inv.MaxCarryable(xPlayer, entry.name, entry.count)
        if carryable <= 0 then
            tooHeavy = true
        else
            if carryable < entry.count then tooHeavy = true end
            local taken = Inv.RemoveFromSlot(pickup.items, entry.slot, carryable)
            if taken then
                local added = Inv.AddToList(list, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots)
                if added < taken.count then
                    Inv.AddToList(pickup.items, taken.name, taken.count - added, taken.meta, Inv.PickupMaxSlots)
                end
            end
        end
    end

    if tooHeavy then
        Inv.Toast(source, "Vous ne pouvez pas porter autant.")
    end

    Inv.PushPlayer(xPlayer)

    if #pickup.items == 0 then
        Inv.DestroyPickup(pickupId)
    else
        Inv.RefreshPickupViewers(pickupId)
        refreshNearbyFor(pickup.coords)
    end
end)

Inv.RegisterNet("vfw:pickup:moveItem", function(pickupId, fromSlot, toSlot)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(pickupId) ~= "string" then return end
    if not tonumber(fromSlot) or not tonumber(toSlot) then return end

    local viewer = Inv.Viewers[source]
    if not viewer or viewer.kind ~= "pickup" or viewer.id ~= pickupId then return end

    local pickup = Inv.Pickups[pickupId]
    if not pickup then return end

    if Inv.MoveInList(pickup.items, fromSlot, toSlot, Inv.PickupMaxSlots) then
        Inv.RefreshPickupViewers(pickupId)
    end
end)

Inv.RegisterNet("vfw:pickup:close", function(pickupId)
    local source = source
    if type(pickupId) ~= "string" then return end
    Inv.ClearViewer(source, "pickup", pickupId)
end)

AddEventHandler("vfw:characterLoaded", function(source)
    CreateThread(function()
        Wait(4000)
        for pickupId, pickup in pairs(Inv.Pickups) do
            if pickup.netId then
                TriggerClientEvent("vfw:pickup:register", source, pickup.netId, pickupId)
            end
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(60000)
        local now = GetGameTimer()
        local ids = {}
        for pickupId in pairs(Inv.Pickups) do
            ids[#ids + 1] = pickupId
        end
        for i = 1, #ids do
            local pickupId = ids[i]
            local pickup = Inv.Pickups[pickupId]
            if pickup then
                if #pickup.items == 0 or (now - pickup.createdAt) > PICKUP_LIFETIME then
                    Inv.DestroyPickup(pickupId)
                elseif pickup.entity and not DoesEntityExist(pickup.entity) then
                    local previousNetId = pickup.netId
                    if spawnPickupProp(pickup) then
                        TriggerClientEvent("vfw:pickup:changeProps", -1, pickup.netId, previousNetId)
                    end
                end
            end
        end
    end
end)
