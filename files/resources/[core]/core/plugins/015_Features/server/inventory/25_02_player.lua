local Inv = VFW.Inventory

Inv.UseHandlers = Inv.UseHandlers or {}

local function payload(xPlayer)
    return Inv.Payload(xPlayer)
end

function Inv.RefreshPlayerTargets(xPlayer)
    local viewer = Inv.Viewers[xPlayer.source]
    if not viewer then return end
    if viewer.kind == "chest" and Inv.RefreshChestViewers then
        Inv.RefreshChestViewers(viewer.id)
    elseif viewer.kind == "pickup" and Inv.RefreshPickupViewers then
        Inv.RefreshPickupViewers(viewer.id)
    end
end

Inv.RegisterCallback("vfw:moveItem", function(source, slotStart, slotEnd)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local list = Inv.PlayerList(xPlayer)
    local from = tonumber(slotStart)
    local to = tonumber(slotEnd)

    if from and to then
        Inv.MoveInList(list, from, to, Inv.PlayerMaxSlots)
    end

    return payload(xPlayer)
end)

Inv.RegisterCallback("vfw:splitItem", function(source, position, _, split)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local list = Inv.PlayerList(xPlayer)
    local slot = tonumber(position)
    local amount = math.floor(tonumber(split) or 0)

    if not slot or amount <= 0 then
        return payload(xPlayer)
    end

    local entry = Inv.FindSlot(list, slot)
    if not entry or amount >= entry.count then
        return payload(xPlayer)
    end

    if Inv.IsWeapon(entry.name) then
        return payload(xPlayer)
    end

    local free = Inv.FreeSlot(list, Inv.PlayerMaxSlots)
    if not free then
        Inv.Toast(source, "Aucun emplacement libre")
        return payload(xPlayer)
    end

    entry.count = entry.count - amount
    list[#list + 1] = {
        name = entry.name,
        count = amount,
        slot = free,
        meta = Inv.CopyMeta(entry.meta),
    }

    return payload(xPlayer)
end)

Inv.RegisterCallback("vfw:renameItem", function(source, position, _, name)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local list = Inv.PlayerList(xPlayer)
    local slot = tonumber(position)

    if not slot or type(name) ~= "string" then
        return payload(xPlayer)
    end

    local entry = Inv.FindSlot(list, slot)
    if not entry or entry.name == "money" then
        return payload(xPlayer)
    end

    local clean = name:gsub("[%c]", ""):sub(1, 32)
    entry.meta = entry.meta or {}

    if clean == "" then
        entry.meta.renamed = nil
        if next(entry.meta) == nil then entry.meta = nil end
    else
        entry.meta.renamed = clean
    end

    return payload(xPlayer)
end)

Inv.RegisterCallback("vfw:useItem", function(source, name, meta, slot)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local list = Inv.PlayerList(xPlayer)

    if type(name) ~= "string" or not Inv.Exists(name) then
        return payload(xPlayer)
    end

    if Inv.IsCuffed(source) then
        Inv.Toast(source, "Vous ne pouvez pas faire cette action en etant menotte")
        return payload(xPlayer)
    end

    local prison = xPlayer.getMeta("prison")
    if type(prison) == "table" and prison.isPrisoned then
        Inv.Toast(source, "Vous ne pouvez pas faire cette action en prison")
        return payload(xPlayer)
    end

    local entry
    local wanted = tonumber(slot)
    if wanted then
        local candidate = Inv.FindSlot(list, wanted)
        if candidate and candidate.name == name then entry = candidate end
    end

    if not entry and type(meta) == "table" and next(meta) ~= nil then
        local key = Inv.MetaKey(Inv.SanitizeMeta(meta))
        for i = 1, #list do
            if list[i].name == name and Inv.MetaKey(list[i].meta) == key then
                entry = list[i]
                break
            end
        end
    end

    if not entry then
        for i = 1, #list do
            if list[i].name == name then
                entry = list[i]
                break
            end
        end
    end

    if not entry then
        return payload(xPlayer)
    end

    local itemMeta = entry.meta or {}
    if type(itemMeta.identifier) == "string" and itemMeta.identifier ~= "" and itemMeta.identifier ~= xPlayer.identifier then
        Inv.Toast(source, "Cet objet appartient a quelqu'un d'autre.")
        return payload(xPlayer)
    end

    local def = Inv.Def(name)

    if Inv.IsWeapon(name) then
        if Inv.EquipWeapon then
            Inv.EquipWeapon(xPlayer, entry)
        end
        return payload(xPlayer)
    end

    local handler = Inv.UseHandlers[name]
    if handler then
        local ok, err = pcall(handler, xPlayer, entry, def)
        if not ok then
            console.warn(("[inventory] usage de '%s' en erreur : %s"):format(name, tostring(err)))
        end
        return payload(xPlayer)
    end

    local data = def and def.data or {}
    local isConsumable = (tonumber(data.hunger) or 0) > 0
        or (tonumber(data.thirst) or 0) > 0
        or def.type == "food"
        or def.type == "drink"

    if isConsumable then
        local removed = Inv.RemoveFromSlot(list, entry.slot, 1)
        if not removed then
            return payload(xPlayer)
        end

        if VFW.AddStatus then
            VFW.AddStatus(source, tonumber(data.hunger) or 0, tonumber(data.thirst) or 0)
        end

        TriggerClientEvent("core:UseConsumable", source, name, data)
        return payload(xPlayer)
    end

    if def and def.usable then
        TriggerEvent("vfw:inventory:itemUsed", source, name, entry.slot, Inv.CopyMeta(entry.meta))
        return payload(xPlayer)
    end

    local inventory, weight = payload(xPlayer)
    return inventory, weight, true
end)

function Inv.RegisterUsableItem(name, handler)
    if type(name) ~= "string" or type(handler) ~= "function" then return false end
    Inv.UseHandlers[name] = handler
    return true
end

local function transferBetweenPlayers(fromPlayer, toPlayer, info)
    local fromList = Inv.PlayerList(fromPlayer)
    local toList = Inv.PlayerList(toPlayer)
    local entries = Inv.ParseInfo(info)
    local moved = 0
    local tooHeavy = false

    for i = 1, #entries do
        local request = entries[i]
        local entry = Inv.FindSlot(fromList, request.slot)
        if entry then
            local quantity = request.quantity
            if quantity <= 0 or quantity > entry.count then quantity = entry.count end

            local carryable = Inv.MaxCarryable(toPlayer, entry.name, quantity)
            if carryable <= 0 then
                tooHeavy = true
            else
                if carryable < quantity then tooHeavy = true end
                local taken = Inv.RemoveFromSlot(fromList, request.slot, carryable)
                if taken then
                    local added = Inv.AddToList(toList, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots, request.targetSlot)
                    if added < taken.count then
                        Inv.AddToList(fromList, taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
                    end
                    moved = moved + added
                end
            end
        end
    end

    return moved, tooHeavy
end

Inv.RegisterCallback("vfw:giveItem", function(source, targetServerId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local targetId = tonumber(targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or target.source == source then
        return payload(xPlayer)
    end

    if Inv.IsCuffed(source) then
        Inv.Toast(source, "Vous ne pouvez pas faire cette action en etant menotte")
        return payload(xPlayer)
    end

    local distance = Inv.Distance(Inv.PlayerCoords(source), Inv.PlayerCoords(target.source))
    if distance > Inv.GiveDistance then
        Inv.Toast(source, "Vous etes trop loin de cette personne.")
        return payload(xPlayer)
    end

    local moved, tooHeavy = transferBetweenPlayers(xPlayer, target, info)

    if tooHeavy then
        TriggerClientEvent("inventory:transferTooHeavy", source)
    end

    if moved > 0 then
        Inv.PushPlayer(target)
        TriggerClientEvent("vfw:playDropAnim", source)
        TriggerClientEvent("vfw:playDropAnim", target.source)
    end

    return payload(xPlayer)
end)

Inv.RegisterCallback("vfw:giveMoney", function(source, targetServerId, amount)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local targetId = tonumber(targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil
    local value = math.floor(tonumber(amount) or 0)

    if not target or target.source == source or value <= 0 then
        return payload(xPlayer)
    end

    if Inv.IsCuffed(source) then
        return payload(xPlayer)
    end

    local distance = Inv.Distance(Inv.PlayerCoords(source), Inv.PlayerCoords(target.source))
    if distance > Inv.GiveDistance then
        Inv.Toast(source, "Vous etes trop loin de cette personne.")
        return payload(xPlayer)
    end

    local list = Inv.PlayerList(xPlayer)
    if Inv.CountByName(list, "money") < value then
        Inv.Toast(source, "Vous n'avez pas assez d'argent.")
        return payload(xPlayer)
    end

    local carryable = Inv.MaxCarryable(target, "money", value)
    if carryable < value then
        TriggerClientEvent("inventory:transferTooHeavy", source)
        if carryable <= 0 then
            return payload(xPlayer)
        end
        value = carryable
    end

    Inv.RemoveByName(list, "money", value)
    Inv.AddToList(Inv.PlayerList(target), "money", value, nil, Inv.PlayerMaxSlots)

    Inv.PushPlayer(target)
    TriggerClientEvent("vfw:showItemNotification", target.source, "money", value, 1)

    return payload(xPlayer)
end)

