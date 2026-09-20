local Inv = VFW.Inventory

function Inv.OpenTargetInventory(source, target)
    if type(target) ~= "table" then return false end
    TriggerClientEvent("vfw:inventoryGive", source, target)
    return true
end

function Inv.OpenChestFor(source, chestId, label, maxSlots)
    chestId = Inv.ChestKey(chestId)
    if not chestId then return false end

    local chest = Inv.GetChest(chestId)
    if not chest then return false end

    if label then chest.label = label end
    if tonumber(maxSlots) then chest.maxSlots = tonumber(maxSlots) end

    Inv.SetViewer(source, "chest", chestId)

    local items, weight = Inv.ChestPayload(chest)
    return Inv.OpenTargetInventory(source, {
        chestId = chestId,
        inventory = items,
        name = chest.label,
        maxWeight = chest.maxWeight,
        weight = weight,
        maxSlots = chest.maxSlots,
        search = false,
    })
end

function Inv.OpenBagFor(source, bagUUID)
    if type(bagUUID) ~= "string" or bagUUID == "" then return false end

    local bag = Inv.GetBag(bagUUID)
    if not bag then return false end

    Inv.SetViewer(source, "bag", bagUUID)

    return Inv.OpenTargetInventory(source, {
        bagUUID = bagUUID,
        inventory = Inv.Serialize(bag.items),
        name = "Sac",
        maxWeight = bag.capacity > 0 and bag.capacity or 30,
        weight = Inv.ListWeight(bag.items),
        maxSlots = bag.maxSlots,
        search = false,
    })
end

function Inv.BagAddItem(bagUUID, name, count, meta)
    local bag = Inv.GetBag(bagUUID)
    if not bag then return 0 end

    local added = Inv.AddToList(bag.items, name, count, meta, bag.maxSlots)
    if added > 0 then
        Inv.SaveBag(bagUUID)
        Inv.BroadcastBag(bagUUID, Inv.Serialize(bag.items), Inv.ListWeight(bag.items))
    end
    return added
end

function Inv.BagRemoveItem(bagUUID, name, count)
    local bag = Inv.GetBag(bagUUID)
    if not bag then return 0 end

    local removed = Inv.RemoveByName(bag.items, name, count)
    if removed > 0 then
        Inv.SaveBag(bagUUID)
        Inv.BroadcastBag(bagUUID, Inv.Serialize(bag.items), Inv.ListWeight(bag.items))
    end
    return removed
end

function Inv.ForceClothes(source, itemName, meta)
    if type(itemName) ~= "string" or type(meta) ~= "table" then return false end
    TriggerClientEvent("vfw:clothes", source, itemName, meta)
    return true
end

function Inv.PutWeaponOnBack(source, weaponName, weaponMeta)
    if type(weaponName) ~= "string" then return false end
    TriggerClientEvent("vfw:weapon:back", source, weaponName, weaponMeta or {})
    return true
end

function Inv.RemoveWeaponFromBack(source)
    TriggerClientEvent("vfw:weapon:removeFromBack", source)
    Inv.BackWeapons[source] = nil
    TriggerClientEvent("vfw:weapon:otherPlayerRemoveBackWeapon", -1, source)
    return true
end

function Inv.SetWeaponComponents(xPlayer, weaponId, components)
    if not xPlayer or type(components) ~= "table" then return false end

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindWeaponById(list, weaponId)
    if not entry then return false end

    entry.meta = entry.meta or {}
    entry.meta.components = components

    local current = Inv.Equipped[xPlayer.source]
    if current and current.weaponId == weaponId then
        current.components = components
        TriggerClientEvent("vfw:weapon:componentUpdated", xPlayer.source, weaponId, components)
    end

    Inv.PushPlayer(xPlayer)
    return true
end

function Inv.SetWeaponTint(xPlayer, weaponId, tintIndex)
    if not xPlayer then return false end

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindWeaponById(list, weaponId)
    if not entry then return false end

    entry.meta = entry.meta or {}
    entry.meta.tintIdx = math.floor(tonumber(tintIndex) or 0)

    local current = Inv.Equipped[xPlayer.source]
    if current and current.weaponId == weaponId then
        current.tint = entry.meta.tintIdx
        TriggerClientEvent("vfw:weapon:applyEquipComponents", xPlayer.source, current.hash, current.components, current.tint, tonumber(entry.meta.ammo) or 0)
    end

    Inv.PushPlayer(xPlayer)
    return true
end

exports("InventoryGiveItem", function(source, name, count, meta)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    return Inv.GivePlayerItem(xPlayer, name, count, meta, true)
end)

exports("InventoryRemoveItem", function(source, name, count)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    return Inv.TakePlayerItem(xPlayer, name, count, true)
end)

exports("InventoryHasItem", function(source, name, count)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return Inv.HasItem(xPlayer, name, count)
end)

exports("InventoryGetItems", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return Inv.Serialize(Inv.PlayerList(xPlayer))
end)

exports("ChestAddItem", function(chestId, name, count, meta)
    return Inv.ChestAddItem(chestId, name, count, meta)
end)

exports("ChestRemoveItem", function(chestId, name, count)
    return Inv.ChestRemoveItem(chestId, name, count)
end)
