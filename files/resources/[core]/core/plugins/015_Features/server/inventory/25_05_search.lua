local Inv = VFW.Inventory

local function canSearch(xPlayer, target)
    if not target then return false end
    if target.source == xPlayer.source then return false end

    if xPlayer.hasPermission("inventaire") then return true end

    local distance = Inv.Distance(Inv.PlayerCoords(xPlayer.source), Inv.PlayerCoords(target.source))
    return distance <= Inv.SearchDistance
end

Inv.RegisterCallback("vfw:search:get", function(source, targetServerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local targetId = tonumber(targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or not canSearch(xPlayer, target) then
        Inv.Toast(source, "Vous ne pouvez pas fouiller cette personne.")
        return {}
    end

    Inv.SetViewer(source, "search", target.source)

    local items = Inv.Serialize(Inv.PlayerList(target))
    return items
end)

Inv.RegisterCallback("vfw:search:take-item", function(source, targetServerId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    Inv.PlayerList(xPlayer)

    local targetId = tonumber(targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or not canSearch(xPlayer, target) then
        return Inv.Payload(xPlayer)
    end

    local targetList = Inv.PlayerList(target)
    local myList = Inv.PlayerList(xPlayer)
    local entries = Inv.ParseInfo(info)
    local moved, tooHeavy = 0, false

    for i = 1, #entries do
        local request = entries[i]
        local entry = Inv.FindSlot(targetList, request.slot)
        if entry then
            local quantity = request.quantity
            if quantity <= 0 or quantity > entry.count then quantity = entry.count end

            local carryable = Inv.MaxCarryable(xPlayer, entry.name, quantity)
            if carryable <= 0 then
                tooHeavy = true
            else
                if carryable < quantity then tooHeavy = true end
                local taken = Inv.RemoveFromSlot(targetList, request.slot, carryable)
                if taken then
                    local added = Inv.AddToList(myList, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots, request.targetSlot)
                    if added < taken.count then
                        Inv.AddToList(targetList, taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
                    end
                    moved = moved + added
                end
            end
        end
    end

    if tooHeavy then
        Inv.Toast(source, "Vous ne pouvez pas porter autant.")
    end

    if moved > 0 then
        Inv.PushPlayer(target)
        Inv.BroadcastSearch(target.source, Inv.Serialize(Inv.PlayerList(target)), 0)
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterCallback("vfw:search:put-item", function(source, targetServerId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    Inv.PlayerList(xPlayer)

    local targetId = tonumber(targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or not canSearch(xPlayer, target) then
        return Inv.Payload(xPlayer)
    end

    local targetList = Inv.PlayerList(target)
    local myList = Inv.PlayerList(xPlayer)
    local entries = Inv.ParseInfo(info)
    local moved, tooHeavy = 0, false

    for i = 1, #entries do
        local request = entries[i]
        local entry = Inv.FindSlot(myList, request.slot)
        if entry then
            local quantity = request.quantity
            if quantity <= 0 or quantity > entry.count then quantity = entry.count end

            local carryable = Inv.MaxCarryable(target, entry.name, quantity)
            if carryable <= 0 then
                tooHeavy = true
            else
                if carryable < quantity then tooHeavy = true end
                local taken = Inv.RemoveFromSlot(myList, request.slot, carryable)
                if taken then
                    local added = Inv.AddToList(targetList, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots, request.targetSlot)
                    if added < taken.count then
                        Inv.AddToList(myList, taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
                    end
                    moved = moved + added
                end
            end
        end
    end

    if tooHeavy then
        TriggerClientEvent("inventory:transferTooHeavy", source)
    end

    if moved > 0 then
        Inv.PushPlayer(target)
        Inv.BroadcastSearch(target.source, Inv.Serialize(Inv.PlayerList(target)), 0)
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterNet("vfw:search:close", function(targetServerId)
    local source = source
    local targetId = tonumber(targetServerId)
    if not targetId then
        Inv.ClearViewer(source, "search")
        return
    end

    Inv.ClearViewer(source, "search", targetId)

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return end

    TriggerClientEvent("vfw:staff:freezePlayer", targetId, false)
    TriggerClientEvent("vfw:search:closed", targetId, source)
end)

Inv.RegisterCallback("vfw:infiniteItems:take-item", function(source, itemName, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    Inv.PlayerList(xPlayer)

    if not xPlayer.hasPermission("give_item") then
        Inv.Toast(source, "Vous n'avez pas la permission.")
        return Inv.Payload(xPlayer)
    end

    if type(itemName) ~= "string" or not Inv.Exists(itemName) then
        return Inv.Payload(xPlayer)
    end

    local count = math.floor(tonumber(quantity) or 1)
    if count <= 0 then count = 1 end
    if count > 1000 then count = 1000 end

    Inv.AddToList(Inv.PlayerList(xPlayer), itemName, count, nil, Inv.PlayerMaxSlots)
    TriggerClientEvent("vfw:showItemNotification", source, itemName, count, 1)

    return Inv.Payload(xPlayer)
end)

Inv.RegisterCallback("vfw:itemPool:take-item", function(source, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    Inv.PlayerList(xPlayer)

    if not xPlayer.hasPermission("give_item") then
        Inv.Toast(source, "Vous n'avez pas la permission.")
        return Inv.Payload(xPlayer)
    end

    local entries = Inv.ParseInfo(info)
    local list = Inv.PlayerList(xPlayer)

    for i = 1, #entries do
        local request = entries[i]
        if request.name and Inv.Exists(request.name) then
            local count = request.quantity
            if count <= 0 then count = 1 end
            if count > 1000 then count = 1000 end
            Inv.AddToList(list, request.name, count, Inv.SanitizeMeta(request.meta), Inv.PlayerMaxSlots, request.targetSlot)
            TriggerClientEvent("vfw:showItemNotification", source, request.name, count, 1)
        end
    end

    return Inv.Payload(xPlayer)
end)

function Inv.BuildAllItemsList()
    local out = {}
    local slot = 0
    for name, def in pairs(VFW.Items or {}) do
        slot = slot + 1
        out[#out + 1] = {
            name = name,
            count = 1,
            slot = slot,
            position = slot,
            meta = {},
            label = def.label,
        }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    for i = 1, #out do
        out[i].slot = i
        out[i].position = i
    end
    return out
end

VFW.RegisterCommand("allitems", "give_item", function(source)
    TriggerClientEvent("vfw:openInfiniteItemsInventory", source, Inv.BuildAllItemsList())
end, {
    help = "Ouvre l'inventaire de tous les items (staff)",
})

VFW.RegisterCommand("itempool", "give_item", function(source)
    TriggerClientEvent("vfw:itemPool:open", source, Inv.BuildAllItemsList())
end, {
    help = "Ouvre le pool d'items (staff)",
})
