local Inv = VFW.Inventory

local dirty = {}

local prefixDefaults = {
    ["veh:"] = { label = "Coffre du vehicule", maxWeight = 120, maxSlots = 40 },
    ["trunk:"] = { label = "Coffre du vehicule", maxWeight = 120, maxSlots = 40 },
    ["glovebox:"] = { label = "Boite a gants", maxWeight = 15, maxSlots = 6 },
    ["property:"] = { label = "Propriete", maxWeight = 600, maxSlots = 100 },
    ["motel:"] = { label = "Motel", maxWeight = 200, maxSlots = 50 },
    ["labo:"] = { label = "Laboratoire", maxWeight = 400, maxSlots = 60 },
    ["society:"] = { label = "Coffre de societe", maxWeight = 600, maxSlots = 100 },
    ["locker:"] = { label = "Casier", maxWeight = 120, maxSlots = 40 },
    ["chestbuilder:"] = { label = "Coffre", maxWeight = 400, maxSlots = 50 },
    ["deposit:"] = { label = "Depot", maxWeight = 1000, maxSlots = 100 },
    ["test:"] = { label = "Coffre de test", maxWeight = 200, maxSlots = 50 },
}

Inv.ChestOverrides = Inv.ChestOverrides or {}

function Inv.ChestDefaults(chestId)
    local override = Inv.ChestOverrides[chestId]
    if override then
        return override.label or "Coffre",
            tonumber(override.maxWeight) or Inv.DefaultChestMaxWeight,
            tonumber(override.maxSlots) or Inv.DefaultChestMaxSlots
    end

    for prefix, def in pairs(prefixDefaults) do
        if chestId:sub(1, #prefix) == prefix then
            return def.label, def.maxWeight, def.maxSlots
        end
    end

    return "Coffre", Inv.DefaultChestMaxWeight, Inv.DefaultChestMaxSlots
end

function Inv.ConfigureChest(chestId, options)
    if type(chestId) ~= "string" or type(options) ~= "table" then return false end
    Inv.ChestOverrides[chestId] = {
        label = options.label,
        maxWeight = tonumber(options.maxWeight),
        maxSlots = tonumber(options.maxSlots),
    }

    local chest = Inv.Chests[chestId]
    if chest then
        if options.label then chest.label = options.label end
        if tonumber(options.maxWeight) then chest.maxWeight = tonumber(options.maxWeight) end
        if tonumber(options.maxSlots) then chest.maxSlots = tonumber(options.maxSlots) end
        dirty[chestId] = true
    end
    return true
end

function Inv.ChestKey(chestId)
    if type(chestId) == "number" then return tostring(chestId) end
    if type(chestId) ~= "string" then return nil end
    if chestId == "" or #chestId > 120 then return nil end
    return chestId
end

function Inv.GetChest(chestId)
    chestId = Inv.ChestKey(chestId)
    if not chestId then return nil end

    local cached = Inv.Chests[chestId]
    if cached then return cached end

    local label, maxWeight, maxSlots = Inv.ChestDefaults(chestId)
    local row = MySQL.single.await("SELECT * FROM chests WHERE chest_id = ?", { chestId })

    local raced = Inv.Chests[chestId]
    if raced then return raced end

    local chest
    if row then
        chest = {
            id = chestId,
            label = row.label ~= "" and row.label or label,
            maxWeight = tonumber(row.max_weight) or maxWeight,
            maxSlots = tonumber(row.max_slots) or maxSlots,
            accessName = row.access_name,
            items = Inv.Normalize(VFW.DB.Decode(row.items, {}), tonumber(row.max_slots) or maxSlots),
        }
    else
        chest = {
            id = chestId,
            label = label,
            maxWeight = maxWeight,
            maxSlots = maxSlots,
            accessName = nil,
            items = {},
        }
        MySQL.insert("INSERT IGNORE INTO chests (chest_id, label, max_weight, max_slots, items) VALUES (?, ?, ?, ?, ?)", {
            chestId, label, maxWeight, maxSlots, VFW.DB.Encode({}),
        })
    end

    Inv.Chests[chestId] = chest
    return chest
end

function Inv.SaveChest(chestId)
    local chest = Inv.Chests[chestId]
    if not chest then return end
    MySQL.update("UPDATE chests SET label = ?, max_weight = ?, max_slots = ?, items = ? WHERE chest_id = ?", {
        chest.label, chest.maxWeight, chest.maxSlots, VFW.DB.Encode(Inv.Serialize(chest.items)), chestId,
    })
end

function Inv.MarkChestDirty(chestId)
    dirty[chestId] = true
end

function Inv.ChestPayload(chest)
    return Inv.Serialize(chest.items), Inv.ListWeight(chest.items)
end

function Inv.RefreshChestViewers(chestId, exceptSource)
    local chest = Inv.Chests[chestId]
    if not chest then return end
    local items, weight = Inv.ChestPayload(chest)
    Inv.Broadcast("chest", chestId, items, weight, exceptSource)
end

function Inv.LogChest(chestId, xPlayer, action, itemName, count, meta)
    MySQL.insert(
        "INSERT INTO chest_history (chest_id, citizenid, player_name, action, item_name, count, meta) VALUES (?, ?, ?, ?, ?, ?, ?)",
        {
            chestId,
            xPlayer and xPlayer.identifier or "unknown",
            xPlayer and xPlayer.name or "unknown",
            action,
            itemName,
            count,
            VFW.DB.Encode(meta or {}),
        }
    )
end

function Inv.ChestAddItem(chestId, name, count, meta)
    local chest = Inv.GetChest(chestId)
    if not chest then return 0 end
    local added = Inv.AddToList(chest.items, name, count, meta, chest.maxSlots)
    if added > 0 then
        dirty[chestId] = true
        Inv.RefreshChestViewers(chestId)
    end
    return added
end

function Inv.ChestRemoveItem(chestId, name, count)
    local chest = Inv.GetChest(chestId)
    if not chest then return 0 end
    local removed = Inv.RemoveByName(chest.items, name, count)
    if removed > 0 then
        dirty[chestId] = true
        Inv.RefreshChestViewers(chestId)
    end
    return removed
end

Inv.RegisterCallback("vfw:chest:get", function(source, chestId)
    local xPlayer = VFW.GetPlayerFromId(source)
    chestId = Inv.ChestKey(chestId)
    if not xPlayer or not chestId then return {}, 0, Inv.DefaultChestMaxWeight, "Coffre", Inv.DefaultChestMaxSlots end

    local chest = Inv.GetChest(chestId)
    if not chest then return {}, 0, Inv.DefaultChestMaxWeight, "Coffre", Inv.DefaultChestMaxSlots end

    Inv.SetViewer(source, "chest", chestId)

    local items, weight = Inv.ChestPayload(chest)
    return items, weight, chest.maxWeight, chest.label, chest.maxSlots
end)

Inv.RegisterCallback("vfw:chest:put-item", function(source, chestId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    chestId = Inv.ChestKey(chestId)

    if not chestId then
        return Inv.Payload(xPlayer)
    end

    if Inv.IsCuffed(source) then
        Inv.Toast(source, "Vous ne pouvez pas faire cette action en etant menotte")
        return Inv.Payload(xPlayer)
    end

    local chest = Inv.GetChest(chestId)
    if not chest then
        return Inv.Payload(xPlayer)
    end

    -- Inv.GetChest rend la main sur sa requete SQL : lire la liste avant laisserait
    -- travailler sur une table que Inv.PlayerList a deja remplacee entre-temps.
    local list = Inv.PlayerList(xPlayer)

    local entries = Inv.ParseInfo(info)
    local full = false
    local moved = 0

    for i = 1, #entries do
        local request = entries[i]
        local entry = Inv.FindSlot(list, request.slot)
        if entry then
            local quantity = request.quantity
            if quantity <= 0 or quantity > entry.count then quantity = entry.count end

            local unit = Inv.Weight(entry.name)
            local free = chest.maxWeight - Inv.ListWeight(chest.items)
            local allowed = quantity
            if unit > 0 then
                allowed = math.min(quantity, math.max(0, math.floor(free / unit)))
            end

            if allowed <= 0 then
                full = true
            else
                if allowed < quantity then full = true end
                local taken = Inv.RemoveFromSlot(list, request.slot, allowed)
                if taken then
                    local added = Inv.AddToList(chest.items, taken.name, taken.count, taken.meta, chest.maxSlots, request.targetSlot)
                    if added < taken.count then
                        full = true
                        Inv.AddToList(list, taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
                    end
                    if added > 0 then
                        moved = moved + added
                        Inv.LogChest(chestId, xPlayer, "put", taken.name, added, taken.meta)
                    end
                end
            end
        end
    end

    if full then
        TriggerClientEvent("inventory:chestFull", source)
    end

    if moved > 0 then
        dirty[chestId] = true
        Inv.RefreshChestViewers(chestId, source)
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterCallback("vfw:chest:take-item", function(source, chestId, info)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    chestId = Inv.ChestKey(chestId)

    if not chestId then
        return Inv.Payload(xPlayer)
    end

    local chest = Inv.GetChest(chestId)
    if not chest then
        return Inv.Payload(xPlayer)
    end

    -- Meme raison que dans put-item : la liste se lit apres la requete SQL du coffre.
    local list = Inv.PlayerList(xPlayer)

    local entries = Inv.ParseInfo(info)
    local tooHeavy = false
    local moved = 0

    for i = 1, #entries do
        local request = entries[i]
        local entry = Inv.FindSlot(chest.items, request.slot)
        if entry then
            local quantity = request.quantity
            if quantity <= 0 or quantity > entry.count then quantity = entry.count end

            local carryable = Inv.MaxCarryable(xPlayer, entry.name, quantity)
            if carryable <= 0 then
                tooHeavy = true
            else
                if carryable < quantity then tooHeavy = true end
                local taken = Inv.RemoveFromSlot(chest.items, request.slot, carryable)
                if taken then
                    local added = Inv.AddToList(list, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots, request.targetSlot)
                    if added < taken.count then
                        Inv.AddToList(chest.items, taken.name, taken.count - added, taken.meta, chest.maxSlots)
                    end
                    if added > 0 then
                        moved = moved + added
                        Inv.LogChest(chestId, xPlayer, "take", taken.name, added, taken.meta)
                    end
                end
            end
        end
    end

    if tooHeavy then
        Inv.Toast(source, "Vous ne pouvez pas porter autant.")
    end

    if moved > 0 then
        dirty[chestId] = true
        Inv.RefreshChestViewers(chestId, source)
    end

    return Inv.Payload(xPlayer)
end)

Inv.RegisterNet("vfw:chest:moveItem", function(chestId, fromSlot, toSlot)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    chestId = Inv.ChestKey(chestId)
    if not xPlayer or not chestId then return end
    if not tonumber(fromSlot) or not tonumber(toSlot) then return end

    local viewer = Inv.Viewers[source]
    if not viewer or viewer.kind ~= "chest" or viewer.id ~= chestId then return end

    local chest = Inv.GetChest(chestId)
    if not chest then return end

    if Inv.MoveInList(chest.items, fromSlot, toSlot, chest.maxSlots) then
        dirty[chestId] = true
        Inv.RefreshChestViewers(chestId)
    end
end)

Inv.RegisterNet("vfw:chest:close", function(chestId)
    local source = source
    chestId = Inv.ChestKey(chestId)
    if not chestId then
        Inv.ClearViewer(source, "chest")
        return
    end
    Inv.ClearViewer(source, "chest", chestId)
end)

Inv.RegisterNet("vfw:bag:close", function(bagUUID)
    local source = source
    if type(bagUUID) ~= "string" then return end
    Inv.ClearViewer(source, "bag", bagUUID)
end)

CreateThread(function()
    while true do
        Wait(10000)
        for chestId in pairs(dirty) do
            dirty[chestId] = nil
            local ok, err = pcall(Inv.SaveChest, chestId)
            if not ok then
                console.warn(("[inventory] sauvegarde du coffre %s impossible : %s"):format(chestId, tostring(err)))
            end
        end
    end
end)

local function flushChests()
    for chestId in pairs(dirty) do
        dirty[chestId] = nil
        pcall(Inv.SaveChest, chestId)
    end
end

AddEventHandler("txAdmin:events:serverShuttingDown", flushChests)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    flushChests()
end)
