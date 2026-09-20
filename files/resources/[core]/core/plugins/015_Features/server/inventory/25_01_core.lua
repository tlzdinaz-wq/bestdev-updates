VFW.Inventory = VFW.Inventory or {}

local Inv = VFW.Inventory

Inv.PlayerMaxSlots = 100
Inv.DefaultChestMaxWeight = 200
Inv.DefaultChestMaxSlots = 50
Inv.PickupModel = joaat("prop_paper_bag_01")
Inv.PickupRadius = 12.0
Inv.PickupMaxWeight = 500
Inv.PickupMaxSlots = 100
Inv.SearchDistance = 6.0
Inv.GiveDistance = tonumber(Config and Config.DistanceGive) or 4.0

Inv.Chests = {}
Inv.Pickups = {}
Inv.Bags = {}
Inv.Viewers = {}
Inv.NearbyMap = {}

local claimedEvents = {}
local claimedCallbacks = {}

function Inv.RegisterNet(name, handler)
    if claimedEvents[name] then
        console.warn(("[inventory] event '%s' deja enregistre, second handler ignore"):format(name))
        return false
    end
    claimedEvents[name] = true
    RegisterNetEvent(name, handler)
    return true
end

function Inv.RegisterCallback(name, handler)
    if claimedCallbacks[name] then
        console.warn(("[inventory] callback '%s' deja enregistre localement"):format(name))
        return false
    end
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[inventory] callback '%s' refuse : %s"):format(name, tostring(err)))
        return false
    end
    claimedCallbacks[name] = true
    return true
end

function Inv.Def(name)
    if type(name) ~= "string" then return nil end
    return VFW.Items and VFW.Items[name] or nil
end

function Inv.Weight(name)
    local def = Inv.Def(name)
    return def and tonumber(def.weight) or 0
end

function Inv.TypeOf(name)
    local def = Inv.Def(name)
    return def and def.type or "items"
end

function Inv.IsWeapon(name)
    return Inv.TypeOf(name) == "weapons"
end

function Inv.Exists(name)
    return Inv.Def(name) ~= nil
end

local function canon(value)
    local kind = type(value)
    if kind ~= "table" then
        return kind .. ":" .. tostring(value)
    end
    local keys = {}
    for k in pairs(value) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for i = 1, #keys do
        parts[#parts + 1] = tostring(keys[i]) .. "=" .. canon(value[keys[i]])
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function Inv.MetaKey(meta)
    if type(meta) ~= "table" then return "nil" end
    if next(meta) == nil then return "nil" end
    return canon(meta)
end

function Inv.CopyMeta(meta)
    if type(meta) ~= "table" then return nil end
    local out = {}
    for k, v in pairs(meta) do
        if type(v) == "table" then
            out[k] = Inv.CopyMeta(v)
        else
            out[k] = v
        end
    end
    return out
end

function Inv.NewWeaponId()
    if VFW.GenerateUUID then
        return VFW.GenerateUUID()
    end
    return ("w%d%d"):format(os.time(), math.random(100000, 999999))
end

function Inv.SanitizeMeta(meta)
    if type(meta) ~= "table" then return nil end
    local out = {}
    local n = 0
    for k, v in pairs(meta) do
        local tk = type(k)
        local tv = type(v)
        if (tk == "string" or tk == "number") and (tv == "string" or tv == "number" or tv == "boolean" or tv == "table") then
            n = n + 1
            if n > 64 then break end
            if tv == "table" then
                out[k] = Inv.SanitizeMeta(v)
            elseif tv == "string" then
                out[k] = v:sub(1, 512)
            else
                out[k] = v
            end
        end
    end
    if next(out) == nil then return nil end
    return out
end

function Inv.Normalize(list, maxSlots)
    maxSlots = tonumber(maxSlots) or Inv.PlayerMaxSlots
    if type(list) ~= "table" then return {} end

    local withSlot, without = {}, {}

    for _, raw in pairs(list) do
        if type(raw) == "table" and type(raw.name) == "string" and raw.name ~= "" then
            local count = math.floor(tonumber(raw.count) or 0)
            if count > 0 then
                local meta = raw.meta
                if type(meta) ~= "table" then
                    meta = type(raw.metadata) == "table" and raw.metadata or nil
                end
                if meta and next(meta) == nil then meta = nil end

                local slot = tonumber(raw.slot)
                if slot then slot = math.floor(slot) end
                if slot and slot < 1 then slot = nil end

                local entry = { name = raw.name, count = count, slot = slot, meta = meta }

                if Inv.IsWeapon(entry.name) and entry.count > 1 then
                    for _ = 2, entry.count do
                        local clone = { name = entry.name, count = 1, slot = nil, meta = Inv.CopyMeta(entry.meta) }
                        if clone.meta then clone.meta.weaponId = Inv.NewWeaponId() end
                        without[#without + 1] = clone
                    end
                    entry.count = 1
                end

                if Inv.IsWeapon(entry.name) then
                    entry.meta = entry.meta or {}
                    if type(entry.meta.weaponId) ~= "string" or entry.meta.weaponId == "" then
                        entry.meta.weaponId = Inv.NewWeaponId()
                    end
                end

                if entry.slot then
                    withSlot[#withSlot + 1] = entry
                else
                    without[#without + 1] = entry
                end
            end
        end
    end

    table.sort(withSlot, function(a, b) return a.slot < b.slot end)

    local used = {}
    local out = {}

    for i = 1, #withSlot do
        local entry = withSlot[i]
        if used[entry.slot] then
            without[#without + 1] = entry
        else
            used[entry.slot] = true
            out[#out + 1] = entry
        end
    end

    local cursor = 1
    local ceiling = maxSlots + 400
    for i = 1, #without do
        while used[cursor] and cursor <= ceiling do
            cursor = cursor + 1
        end
        without[i].slot = cursor
        used[cursor] = true
        out[#out + 1] = without[i]
    end

    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

function Inv.Serialize(list)
    local out = {}
    if type(list) ~= "table" then return out end
    for i = 1, #list do
        local entry = list[i]
        out[i] = {
            name = entry.name,
            count = entry.count,
            slot = entry.slot,
            position = entry.slot,
            meta = entry.meta or {},
        }
    end
    return out
end

function Inv.ListWeight(list)
    local weight = 0
    if type(list) ~= "table" then return 0 end
    for i = 1, #list do
        weight = weight + (Inv.Weight(list[i].name) * list[i].count)
    end
    return weight
end

function Inv.FindSlot(list, slot)
    slot = tonumber(slot)
    if not slot then return nil end
    for i = 1, #list do
        if list[i].slot == slot then
            return list[i], i
        end
    end
    return nil
end

function Inv.FreeSlot(list, maxSlots)
    maxSlots = tonumber(maxSlots) or Inv.PlayerMaxSlots
    local used = {}
    for i = 1, #list do
        used[list[i].slot] = true
    end
    for slot = 1, maxSlots do
        if not used[slot] then return slot end
    end
    return nil
end

function Inv.AddToList(list, name, count, meta, maxSlots, targetSlot)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 or not Inv.Exists(name) then return 0 end

    meta = Inv.SanitizeMeta(meta)

    if Inv.IsWeapon(name) then
        local added = 0
        for _ = 1, count do
            local slot = targetSlot and not Inv.FindSlot(list, targetSlot) and targetSlot or Inv.FreeSlot(list, maxSlots)
            targetSlot = nil
            if not slot then break end
            local weaponMeta = Inv.CopyMeta(meta) or {}
            if type(weaponMeta.weaponId) ~= "string" or weaponMeta.weaponId == "" or added > 0 then
                weaponMeta.weaponId = Inv.NewWeaponId()
            end
            list[#list + 1] = { name = name, count = 1, slot = slot, meta = weaponMeta }
            added = added + 1
        end
        return added
    end

    local key = Inv.MetaKey(meta)

    if targetSlot then
        local target = Inv.FindSlot(list, targetSlot)
        if target then
            if target.name == name and Inv.MetaKey(target.meta) == key then
                target.count = target.count + count
                return count
            end
        else
            list[#list + 1] = { name = name, count = count, slot = targetSlot, meta = Inv.CopyMeta(meta) }
            return count
        end
    end

    for i = 1, #list do
        if list[i].name == name and Inv.MetaKey(list[i].meta) == key then
            list[i].count = list[i].count + count
            return count
        end
    end

    local slot = Inv.FreeSlot(list, maxSlots)
    if not slot then return 0 end

    list[#list + 1] = { name = name, count = count, slot = slot, meta = Inv.CopyMeta(meta) }
    return count
end

function Inv.RemoveFromSlot(list, slot, count)
    local entry, index = Inv.FindSlot(list, slot)
    if not entry then return nil end

    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return nil end
    if count > entry.count then count = entry.count end

    local taken = {
        name = entry.name,
        count = count,
        meta = Inv.CopyMeta(entry.meta),
    }

    entry.count = entry.count - count
    if entry.count <= 0 then
        table.remove(list, index)
    end

    return taken
end

function Inv.RemoveByName(list, name, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return 0 end

    local removed = 0
    for i = #list, 1, -1 do
        if list[i].name == name then
            local take = math.min(count - removed, list[i].count)
            list[i].count = list[i].count - take
            removed = removed + take
            if list[i].count <= 0 then
                table.remove(list, i)
            end
            if removed >= count then break end
        end
    end
    return removed
end

function Inv.CountByName(list, name)
    local total = 0
    for i = 1, #list do
        if list[i].name == name then
            total = total + list[i].count
        end
    end
    return total
end

function Inv.MoveInList(list, fromSlot, toSlot, maxSlots)
    fromSlot = tonumber(fromSlot)
    toSlot = tonumber(toSlot)
    if not fromSlot or not toSlot or fromSlot == toSlot then return false end
    if toSlot < 1 or toSlot > (tonumber(maxSlots) or Inv.PlayerMaxSlots) + 400 then return false end

    local source = Inv.FindSlot(list, fromSlot)
    if not source then return false end

    local target, targetIndex = Inv.FindSlot(list, toSlot)
    if not target then
        source.slot = toSlot
        return true
    end

    if target.name == source.name
        and not Inv.IsWeapon(source.name)
        and Inv.MetaKey(target.meta) == Inv.MetaKey(source.meta) then
        target.count = target.count + source.count
        local _, sourceIndex = Inv.FindSlot(list, fromSlot)
        if sourceIndex then table.remove(list, sourceIndex) end
        return true
    end

    if targetIndex then
        target.slot = fromSlot
    end
    source.slot = toSlot
    return true
end

function Inv.ParseInfo(info)
    local out = {}
    if type(info) ~= "table" then return out end

    local single = tonumber(info.slot)
    if single then
        out[1] = {
            slot = math.floor(single),
            quantity = math.floor(tonumber(info.quantity) or 0),
            targetSlot = tonumber(info.targetSlot) and math.floor(tonumber(info.targetSlot)) or nil,
            name = type(info.name) == "string" and info.name or nil,
            meta = type(info.meta) == "table" and info.meta or nil,
        }
        return out
    end

    for _, value in pairs(info) do
        if type(value) == "table" then
            local slot = tonumber(value.slot)
            if slot then
                out[#out + 1] = {
                    slot = math.floor(slot),
                    quantity = math.floor(tonumber(value.quantity) or 0),
                    targetSlot = tonumber(value.targetSlot) and math.floor(tonumber(value.targetSlot)) or nil,
                    name = type(value.name) == "string" and value.name or nil,
                    meta = type(value.meta) == "table" and value.meta or nil,
                }
            end
        end
        if #out >= 64 then break end
    end

    return out
end

function Inv.PlayerList(xPlayer)
    xPlayer.inventory = Inv.Normalize(xPlayer.inventory, Inv.PlayerMaxSlots)
    return xPlayer.inventory
end

function Inv.PlayerWeight(xPlayer)
    local weight = Inv.ListWeight(xPlayer.inventory)
    xPlayer.weight = weight
    return weight
end

function Inv.Payload(xPlayer)
    local list = Inv.PlayerList(xPlayer)
    return Inv.Serialize(list), Inv.PlayerWeight(xPlayer)
end

function Inv.PushPlayer(xPlayer)
    if not xPlayer then return end
    local items, weight = Inv.Payload(xPlayer)
    TriggerClientEvent("vfw:updateInventory", xPlayer.source, items, weight)
end

function Inv.LoadPlayer(xPlayer)
    if not xPlayer then return end
    local items, weight = Inv.Payload(xPlayer)
    TriggerClientEvent("vfw:loadInventory", xPlayer.source, items, weight)
end

function Inv.CanCarry(xPlayer, name, count)
    local maxWeight = tonumber(xPlayer.maxWeight) or Config.MaxWeight
    return (Inv.ListWeight(xPlayer.inventory) + (Inv.Weight(name) * count)) <= maxWeight
end

function Inv.MaxCarryable(xPlayer, name, count)
    local unit = Inv.Weight(name)
    if unit <= 0 then return count end
    local maxWeight = tonumber(xPlayer.maxWeight) or Config.MaxWeight
    local free = maxWeight - Inv.ListWeight(xPlayer.inventory)
    if free <= 0 then return 0 end
    local possible = math.floor(free / unit)
    if possible < 0 then possible = 0 end
    return math.min(count, possible)
end

function Inv.Toast(source, message)
    TriggerClientEvent("vfw:inventory:toast", source, message)
end

function Inv.SetViewer(source, kind, id)
    Inv.Viewers[source] = { kind = kind, id = id }
end

function Inv.ClearViewer(source, kind, id)
    local viewer = Inv.Viewers[source]
    if not viewer then return end
    if kind and viewer.kind ~= kind then return end
    if id and viewer.id ~= id then return end
    Inv.Viewers[source] = nil
end

function Inv.Broadcast(kind, id, items, weight, exceptSource)
    for source, viewer in pairs(Inv.Viewers) do
        if viewer.kind == kind and viewer.id == id and source ~= exceptSource then
            TriggerClientEvent("vfw:chest:update", source, items, weight)
        end
    end
end

function Inv.BroadcastBag(bagUUID, items, weight)
    for source, viewer in pairs(Inv.Viewers) do
        if viewer.kind == "bag" and viewer.id == bagUUID then
            TriggerClientEvent("vfw:bag:update", source, items, weight)
        end
    end
end

function Inv.BroadcastSearch(targetSource, items, weight)
    for source, viewer in pairs(Inv.Viewers) do
        if viewer.kind == "search" and viewer.id == targetSource then
            TriggerClientEvent("vfw:search:update", source, items, weight)
        end
    end
end

function Inv.PlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function Inv.Distance(a, b)
    if not a or not b then return 9999.0 end
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Inv.IsCuffed(source)
    local ok, state = pcall(function() return Player(source).state.isCuffed end)
    return ok and state == true
end

function Inv.EnrichItemTypes()
    local rows = MySQL.query.await("SELECT `name`, `type`, `premium`, `image` FROM items") or {}
    for i = 1, #rows do
        local def = VFW.Items[rows[i].name]
        if def then
            def.type = rows[i].type or "items"
            def.premium = rows[i].premium
            if def.image == nil then def.image = rows[i].image end
        end
    end
    for _, def in pairs(VFW.Items) do
        if type(def.type) ~= "string" or def.type == "" then
            def.type = "items"
        end
    end
end

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 60000 do
        Wait(200)
        waited = waited + 200
    end
    local ok, err = pcall(Inv.EnrichItemTypes)
    if not ok then
        console.warn(("[inventory] enrichissement des types d'items impossible : %s"):format(tostring(err)))
    else
        console.init("Inventory", "types d'items synchronises")
    end
end)

AddEventHandler("vfw:playerDropped", function(source)
    Inv.Viewers[source] = nil
    Inv.NearbyMap[source] = nil
end)

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    if not xPlayer then return end
    Inv.LoadPlayer(xPlayer)
end)

AddEventHandler("vfw:inventory:added", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer then Inv.PushPlayer(xPlayer) end
end)

AddEventHandler("vfw:inventory:removed", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer then Inv.PushPlayer(xPlayer) end
end)
