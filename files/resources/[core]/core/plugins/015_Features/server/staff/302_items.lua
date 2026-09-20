local Inv = VFW.Inventory

local PERM_WEIGHT = "dev_tools"
local PERM_GIVE_ITEM = "give_item"
local PERM_ITEMS = "gestion_items"
local PERM_WEAPON = "give_weapon"
local PERM_INVENTORY = "inventaire"

local ITEM_GIVE_MAX = 1000
local MONEY_GIVE_ALL_MAX = 100000
local WEAPON_AMMO_MAX = 999
local WEAPON_BURST_MAX = 200
local WEAPON_BURST_WINDOW = 10000
local WEAPON_LOG_DELAY = 1500
local WEIGHT_MIN = 1
local WEIGHT_MAX = 100000
local WEIGHT_DAYS_MAX = 365
local CLEAN_ENTRIES_MAX = 100
local ITEM_WEIGHT_MAX = 100000
local ITEM_NAME_MAX = 60
local ITEM_LABEL_MAX = 80
local ITEM_TYPE_MAX = 20
local ITEM_IMAGE_MAX = 512
local ITEM_DESC_MAX = 1000
local GIVE_ALL_COOLDOWN = 5000

local WEIGHT_STORE = "staff_weights"
local MONEY_ITEM = "money"

local PROTECTED_ITEMS = {
    [MONEY_ITEM] = true,
}

local RAW_TO_INVENTORY = {
    weapon = "weapons",
    consumable = "food",
    drink = "food",
    objects = "items",
    gpb = "items",
    ammo = "items",
    drugs = "items",
    component = "items",
    tint = "items",
    misc = "items",
}

local ITEM_DATA_KEYS = {
    type = "string",
    description = "string",
    image = "string",
    effect = "string",
    ammoType = "string",
    anim = "string",
    prop = "string",
    drop = "string",
    buyPrice = "number",
    hunger = "number",
    thirst = "number",
    duration = "number",
    expiration = "number",
    alcool = "boolean",
    drugs = "boolean",
    droppable = "boolean",
}

local sessionWeights = {}
local weaponBurst = {}
local weaponLogs = {}

local function registerNet(name, handler)
    if Inv and Inv.RegisterNet then
        return Inv.RegisterNet(name, handler)
    end
    RegisterNetEvent(name, handler)
    return true
end

local function registerCallback(name, handler)
    if Inv and Inv.RegisterCallback then
        return Inv.RegisterCallback(name, handler)
    end
    return Staff29.Cb(name, handler)
end

local function logStaff(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, action, payload)
end

local function baseWeight()
    return math.floor(tonumber(Config.MaxWeight) or 24)
end

local function weightStore()
    local store = VFW.Variables.GetVariable(WEIGHT_STORE)
    if type(store) ~= "table" then store = {} end
    return store
end

local function saveWeightStore(store)
    VFW.Variables.SetVariable(WEIGHT_STORE, store)
end

local function persistCharacterWeight(identifier, weight)
    Staff29.Update("UPDATE characters SET max_weight = ? WHERE identifier = ?", { weight, identifier })
end

local function applyLiveWeight(identifier, weight)
    local target = VFW.GetPlayerFromIdentifier(identifier)
    if target then
        target.setMaxWeight(weight)
    end
    return target
end

local function characterRow(identifier)
    if type(identifier) ~= "string" or identifier == "" then return nil end
    return Staff29.Single(
        "SELECT identifier, char_slot, firstname, lastname, max_weight FROM characters WHERE identifier = ? AND deleted_at IS NULL",
        { identifier })
end

local function characterName(row)
    if not row then return "Inconnu" end
    local full = ("%s %s"):format(row.firstname or "", row.lastname or "")
    full = full:match("^%s*(.-)%s*$") or ""
    if full == "" then return "Inconnu" end
    return full
end

local function remainingText(entry)
    if entry.durationType == "session" then return "en cours" end
    if entry.durationType == "permanent" then return "sans expiration" end

    local left = (tonumber(entry.expiresAt) or 0) - os.time()
    if left <= 0 then return "expire" end
    if left < 3600 then return "moins d'une heure" end

    if left < 86400 then
        local hours = math.floor(left / 3600)
        if hours > 1 then return ("il reste %d heures"):format(hours) end
        return "il reste 1 heure"
    end

    local days = math.ceil(left / 86400)
    if days > 1 then return ("il reste %d jours"):format(days) end
    return "il reste 1 jour"
end

local function revokeStored(store, identifier, entry)
    local base = math.floor(tonumber(entry and entry.base) or baseWeight())
    persistCharacterWeight(identifier, base)
    applyLiveWeight(identifier, base)
    store[identifier] = nil
    return base
end

local function revokeSession(identifier)
    local entry = sessionWeights[identifier]
    if not entry then return nil end
    local base = math.floor(tonumber(entry.base) or baseWeight())
    sessionWeights[identifier] = nil
    persistCharacterWeight(identifier, base)
    applyLiveWeight(identifier, base)
    return base
end

local function sanitizeItemData(data)
    local out = {}
    if type(data) ~= "table" then return out end

    for key, kind in pairs(ITEM_DATA_KEYS) do
        local value = data[key]
        if value ~= nil then
            if kind == "number" then
                local number = tonumber(value)
                if number and number == number then
                    out[key] = number
                end
            elseif kind == "boolean" then
                out[key] = (value == true or value == 1 or value == "1")
            else
                local maxLen = key == "image" and ITEM_IMAGE_MAX or 255
                local clean = Staff29.Clean(tostring(value), maxLen)
                if clean and clean ~= "" then
                    if key == "image" then
                        if clean:match("^r2%.fivemanage%.com/") or clean:match("^[%w%-]+%.fivemanage%.com/") or clean:match("^[%w%-]+%.fmfile%.com/") then
                            clean = "https://" .. clean
                        end
                    end
                    out[key] = clean
                end
            end
        end
    end

    return out
end

local function inventoryType(rawType, fallback)
    if type(rawType) ~= "string" or rawType == "" then return fallback end
    local mapped = RAW_TO_INVENTORY[rawType]
    if mapped then return mapped end
    return rawType:sub(1, ITEM_TYPE_MAX)
end

local function itemNameOk(name)
    if type(name) ~= "string" then return false end
    if #name < 1 or #name > ITEM_NAME_MAX then return false end
    return name:match("^[a-z0-9_]+$") ~= nil
end

local function broadcastCatalog()
    TriggerClientEvent("vfw:loadItems", -1, VFW.Items)
end

local function resolveWeaponItem(model)
    if type(model) ~= "string" or model == "" or #model > ITEM_NAME_MAX then return nil end
    local lower = model:lower()
    if not Inv.Exists(lower) then return nil end
    if not Inv.IsWeapon(lower) then return nil end
    return lower:upper()
end

local function weaponBurstOk(source)
    local now = GetGameTimer()
    local bucket = weaponBurst[source]

    if not bucket or (now - bucket.startedAt) > WEAPON_BURST_WINDOW then
        bucket = { startedAt = now, count = 0 }
        weaponBurst[source] = bucket
    end

    if bucket.count >= WEAPON_BURST_MAX then return false end
    bucket.count = bucket.count + 1
    return true
end

local function queueWeaponLog(source, targetId, weapon, ammo, infinite)
    local key = ("%d:%d"):format(source, targetId)
    local pending = weaponLogs[key]

    if pending then
        pending.count = pending.count + 1
        if #pending.weapons < 40 then
            pending.weapons[#pending.weapons + 1] = weapon
        end
        pending.ammo = ammo
        pending.infinite = infinite
        return
    end

    weaponLogs[key] = { count = 1, weapons = { weapon }, ammo = ammo, infinite = infinite }

    VFW.SetTimeout(WEAPON_LOG_DELAY, function()
        local entry = weaponLogs[key]
        weaponLogs[key] = nil
        if not entry then return end

        logStaff(source, "items_weapon_give", {
            target = targetId,
            count = entry.count,
            weapons = entry.weapons,
            ammo = entry.ammo,
            infinite = entry.infinite,
        })
    end)
end

registerCallback("vfw:staff:getPlayerCharacters", function(source, playerId)
    local xPlayer = Staff29.Require(source, PERM_WEIGHT)
    if not xPlayer then return {} end

    local target = VFW.GetPlayerFromId(tonumber(playerId))
    if not target then return {} end

    local rows = Staff29.Query(
        "SELECT identifier, char_slot, firstname, lastname FROM characters WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot",
        { target.accountId })

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            identifier = row.identifier,
            slot = tonumber(row.char_slot) or 1,
            name = characterName(row),
        }
    end

    return out
end)

registerCallback("vfw:staff:getModifiedWeights", function(source)
    local xPlayer = Staff29.Require(source, PERM_WEIGHT)
    if not xPlayer then return {} end

    local store = weightStore()
    local dirty = false
    local out = {}

    for identifier, entry in pairs(store) do
        if type(entry) == "table" then
            if entry.durationType == "days" and (tonumber(entry.expiresAt) or 0) <= os.time() then
                revokeStored(store, identifier, entry)
                dirty = true
            else
                local online = VFW.GetPlayerFromIdentifier(identifier)
                out[#out + 1] = {
                    id = online and online.source or nil,
                    identifier = identifier,
                    name = entry.name or characterName(characterRow(identifier)),
                    weight = math.floor(tonumber(entry.weight) or 0),
                    durationType = entry.durationType,
                    remainingText = remainingText(entry),
                    online = online ~= nil,
                }
            end
        end
    end

    for identifier, entry in pairs(sessionWeights) do
        local online = VFW.GetPlayerFromIdentifier(identifier)
        out[#out + 1] = {
            id = online and online.source or nil,
            identifier = identifier,
            name = entry.name or "Inconnu",
            weight = math.floor(tonumber(entry.weight) or 0),
            durationType = "session",
            remainingText = "en cours",
            online = online ~= nil,
        }
    end

    if dirty then
        saveWeightStore(store)
    end

    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end)

registerNet("vfw:staff:setPlayerWeight", function(targetId, weight, durationType, numDays, characterIdentifier)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_WEIGHT)
    if not xPlayer then return end

    local value = Staff29.ToInt(weight, WEIGHT_MIN, WEIGHT_MAX)
    if not value then
        Staff29.Notify(source, "ERROR", "Gestion Poids", "Ce poids n'est pas valide.")
        return
    end

    if durationType ~= "session" and durationType ~= "days" and durationType ~= "permanent" then
        Staff29.Notify(source, "ERROR", "Gestion Poids", "Cette durée n'est pas valide.")
        return
    end

    local days
    if durationType == "days" then
        days = Staff29.ToInt(numDays, 1, WEIGHT_DAYS_MAX)
        if not days then
            Staff29.Notify(source, "ERROR", "Gestion Poids", "Ce nombre de jours n'est pas valide.")
            return
        end
    end

    local identifier = characterIdentifier
    if type(identifier) ~= "string" or identifier == "" then
        local target = VFW.GetPlayerFromId(tonumber(targetId))
        identifier = target and target.identifier or nil
    end

    local row = characterRow(identifier)
    if not row then
        Staff29.Notify(source, "ERROR", "Gestion Poids", "Ce personnage est introuvable.")
        return
    end

    local store = weightStore()
    local previous = store[identifier]
    local base = math.floor(tonumber(previous and previous.base)
        or tonumber(sessionWeights[identifier] and sessionWeights[identifier].base)
        or baseWeight())

    local name = characterName(row)

    if durationType == "session" and not VFW.GetPlayerFromIdentifier(identifier) then
        Staff29.Notify(source, "ERROR", "Gestion Poids",
            "Ce personnage n'est pas connecté, choisissez une durée en jours ou un poids permanent.")
        return
    end

    sessionWeights[identifier] = nil
    store[identifier] = nil

    if durationType == "session" then
        sessionWeights[identifier] = { weight = value, base = base, name = name }
        persistCharacterWeight(identifier, base)
    else
        store[identifier] = {
            weight = value,
            base = base,
            name = name,
            durationType = durationType,
            expiresAt = days and (os.time() + (days * 86400)) or nil,
            grantedBy = source,
            grantedAt = os.time(),
        }
        persistCharacterWeight(identifier, value)
    end

    saveWeightStore(store)
    applyLiveWeight(identifier, value)

    logStaff(source, "weight_set", {
        identifier = identifier,
        name = name,
        weight = value,
        base = base,
        duration = durationType,
        days = days,
        target = tonumber(targetId),
    })
end)

registerNet("vfw:staff:resetPlayerWeight", function(playerId, identifier)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_WEIGHT)
    if not xPlayer then return end

    local key = identifier
    if type(key) ~= "string" or key == "" then
        local target = VFW.GetPlayerFromId(tonumber(playerId))
        key = target and target.identifier or nil
    end

    if type(key) ~= "string" or key == "" then
        Staff29.Notify(source, "ERROR", "Gestion Poids", "Ce personnage est introuvable.")
        return
    end

    local store = weightStore()
    local restored

    if sessionWeights[key] then
        restored = revokeSession(key)
    end

    if store[key] then
        restored = revokeStored(store, key, store[key])
        saveWeightStore(store)
    end

    if not restored then
        Staff29.Notify(source, "INFO", "Gestion Poids", "Ce personnage n'a aucun poids modifié.")
        return
    end

    logStaff(source, "weight_reset", {
        identifier = key,
        restored = restored,
        target = tonumber(playerId),
    })
end)

registerNet("vfw:staff:giveItem", function(targetId, itemName, count)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_GIVE_ITEM)
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        Staff29.Notify(source, "ERROR", "Gestion Items", "Ce joueur n'est pas connecté.")
        return
    end

    if type(itemName) ~= "string" or not Inv.Exists(itemName) then
        Staff29.Notify(source, "ERROR", "Gestion Items", "Cet objet n'existe pas.")
        return
    end

    local amount = Staff29.ToInt(count, 1, ITEM_GIVE_MAX)
    if not amount then
        Staff29.Notify(source, "ERROR", "Gestion Items", ("La quantité doit être comprise entre 1 et %d."):format(ITEM_GIVE_MAX))
        return
    end

    local added = Inv.GivePlayerItem(target, itemName, amount, nil, true)
    if added <= 0 then
        Staff29.Notify(source, "ERROR", "Gestion Items", "L'inventaire de ce joueur est plein.")
        return
    end

    logStaff(source, "items_give", {
        target = target.source,
        identifier = target.identifier,
        name = target.name,
        item = itemName,
        asked = amount,
        given = added,
    })
end)

registerNet("vfw:staff:giveItemToAll", function(itemName, quantity)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_ITEMS)
    if not xPlayer then return end

    if not Staff29.RateLimit(source, "staff:giveItemToAll", GIVE_ALL_COOLDOWN) then
        Staff29.Notify(source, "ERROR", "Distribution Items", "Patientez avant une nouvelle distribution.")
        return
    end

    if type(itemName) ~= "string" or not Inv.Exists(itemName) then
        Staff29.Notify(source, "ERROR", "Distribution Items", "Cet objet n'existe pas.")
        return
    end

    local ceiling = itemName == MONEY_ITEM and MONEY_GIVE_ALL_MAX or ITEM_GIVE_MAX
    local amount = Staff29.ToInt(quantity, 1, ceiling)
    if not amount then
        Staff29.Notify(source, "ERROR", "Distribution Items", ("La quantité doit être comprise entre 1 et %d."):format(ceiling))
        return
    end

    local players = VFW.GetExtendedPlayers()
    local served = 0
    local delivered = 0

    for i = 1, #players do
        local target = players[i]
        local added = Inv.GivePlayerItem(target, itemName, amount, nil, true)
        if added > 0 then
            served = served + 1
            delivered = delivered + added
        end
    end

    Staff29.Notify(source, served > 0 and "SUCCESS" or "ERROR", "Distribution Items",
        served > 0 and ("Distribution effectuée pour %d joueurs."):format(served) or "Aucun joueur n'a pu recevoir cet objet.")

    logStaff(source, "items_give_all", {
        item = itemName,
        amount = amount,
        players = #players,
        served = served,
        delivered = delivered,
    })
end)

registerNet("vfw:staff:giveWeapon", function(targetId, weaponModel, ammo, infiniteAmmo)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_WEAPON)
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        Staff29.Notify(source, "ERROR", "Gestion Armes", "Ce joueur n'est pas connecté.")
        return
    end

    local model = resolveWeaponItem(weaponModel)
    if not model then
        Staff29.Notify(source, "ERROR", "Gestion Armes", "Cette arme n'existe pas.")
        return
    end

    if not weaponBurstOk(source) then
        Staff29.Notify(source, "ERROR", "Gestion Armes", "Trop d'armes distribuées, patientez un instant.")
        return
    end

    local rounds = Staff29.ToInt(ammo, 0, WEAPON_AMMO_MAX) or 0
    local infinite = infiniteAmmo == true

    TriggerClientEvent("vfw:staff:receiveWeapon", target.source, model, rounds, infinite)
    queueWeaponLog(source, target.source, model, rounds, infinite)
end)

registerNet("vfw:staff:removeAllWeapons", function(targetId)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_WEAPON)
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        Staff29.Notify(source, "ERROR", "Gestion Armes", "Ce joueur n'est pas connecté.")
        return
    end

    if Inv.Equipped and Inv.Equipped[target.source] and Inv.UnequipWeapon then
        Inv.UnequipWeapon(target, false)
    end

    TriggerClientEvent("vfw:staff:removeWeapons", target.source)

    logStaff(source, "items_weapon_clear", {
        target = target.source,
        identifier = target.identifier,
        name = target.name,
    })
end)

registerNet("vfw:staff:createItem", function(name, label, weight, data, premium, perm)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_ITEMS)
    if not xPlayer then return end

    if not itemNameOk(name) then
        Staff29.Notify(source, "ERROR", "Items", "Ce nom d'objet n'est pas valide.")
        return
    end

    local cleanLabel = Staff29.Clean(label, ITEM_LABEL_MAX)
    if not cleanLabel or cleanLabel == "" then
        Staff29.Notify(source, "ERROR", "Items", "Le nom affiché est obligatoire.")
        return
    end

    local cleanWeight = Staff29.ToInt(weight, 0, ITEM_WEIGHT_MAX)
    if not cleanWeight then
        Staff29.Notify(source, "ERROR", "Items", "Ce poids n'est pas valide.")
        return
    end

    if VFW.Items[name] or Staff29.Scalar("SELECT name FROM items WHERE name = ?", { name }) then
        Staff29.Notify(source, "ERROR", "Items", "Un objet porte déjà ce nom.")
        return
    end

    local cleanData = sanitizeItemData(data)
    local itemType = inventoryType(cleanData.type, "items")
    local image = Staff29.Clean(cleanData.image, ITEM_IMAGE_MAX) or ""
    local description = Staff29.Clean(cleanData.description, ITEM_DESC_MAX) or ""
    local isPremium = premium == true
    local isPerm = perm == true

    local inserted = Staff29.Update([[
        INSERT INTO items (name, label, type, weight, premium, perm, image, description, data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        name, cleanLabel, itemType, cleanWeight,
        isPremium and 1 or 0, isPerm and 1 or 0,
        image, description, Staff29.Encode(cleanData),
    })

    if not inserted or inserted <= 0 then
        Staff29.Notify(source, "ERROR", "Items", "L'enregistrement de cet objet a échoué.")
        return
    end

    local def = {
        name = name,
        label = cleanLabel,
        type = itemType,
        weight = cleanWeight,
        rare = false,
        canRemove = true,
        usable = false,
        premium = isPremium,
        perm = isPerm,
        image = image ~= "" and image or ("items/%s.webp"):format(name),
        description = description,
        data = cleanData,
    }

    VFW.Items[name] = def
    TriggerClientEvent("vfw:createItem", -1, name, def)

    Staff29.Notify(source, "SUCCESS", "Items", ("L'objet %s est enregistré."):format(cleanLabel))

    logStaff(source, "items_create", {
        item = name,
        label = cleanLabel,
        type = itemType,
        weight = cleanWeight,
        premium = isPremium,
        perm = isPerm,
    })
end)

registerNet("vfw:staff:saveItem", function(name, edit)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_ITEMS)
    if not xPlayer then return end

    local current = type(name) == "string" and VFW.Items[name] or nil
    if not current or type(edit) ~= "table" then
        TriggerClientEvent("vfw:staff:saveItem:response", source, false)
        return
    end

    local cleanLabel = Staff29.Clean(edit.label, ITEM_LABEL_MAX)
    local cleanWeight = Staff29.ToInt(edit.weight, 0, ITEM_WEIGHT_MAX)

    if not cleanLabel or cleanLabel == "" or not cleanWeight then
        TriggerClientEvent("vfw:staff:saveItem:response", source, false)
        return
    end

    local cleanData = sanitizeItemData(edit.data)
    local itemType = inventoryType(cleanData.type, current.type or "items")
    local image = Staff29.Clean(cleanData.image, ITEM_IMAGE_MAX) or ""
    local description = Staff29.Clean(cleanData.description, ITEM_DESC_MAX)
    local isPremium = edit.premium == true
    local isPerm = edit.perm == true

    local updated
    if description and description ~= "" then
        updated = Staff29.Update([[
            UPDATE items SET label = ?, type = ?, weight = ?, premium = ?, perm = ?, image = ?, description = ?, data = ?
            WHERE name = ?
        ]], {
            cleanLabel, itemType, cleanWeight, isPremium and 1 or 0, isPerm and 1 or 0,
            image, description, Staff29.Encode(cleanData), name,
        })
    else
        updated = Staff29.Update([[
            UPDATE items SET label = ?, type = ?, weight = ?, premium = ?, perm = ?, image = ?, data = ?
            WHERE name = ?
        ]], {
            cleanLabel, itemType, cleanWeight, isPremium and 1 or 0, isPerm and 1 or 0,
            image, Staff29.Encode(cleanData), name,
        })
        description = current.description
    end

    if not updated or updated <= 0 then
        TriggerClientEvent("vfw:staff:saveItem:response", source, false)
        return
    end

    local def = {
        name = name,
        label = cleanLabel,
        type = itemType,
        weight = cleanWeight,
        rare = current.rare,
        canRemove = current.canRemove,
        usable = current.usable,
        premium = isPremium,
        perm = isPerm,
        image = image ~= "" and image or ("items/%s.webp"):format(name),
        description = description,
        data = cleanData,
    }

    VFW.Items[name] = def
    TriggerClientEvent("vfw:items:update", -1, name, def)
    TriggerClientEvent("vfw:staff:saveItem:response", source, true)

    logStaff(source, "items_update", {
        item = name,
        label = cleanLabel,
        type = itemType,
        weight = cleanWeight,
        premium = isPremium,
        perm = isPerm,
    })
end)

registerNet("vfw:staff:deleteItem", function(name)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_ITEMS)
    if not xPlayer then return end

    if type(name) ~= "string" or not VFW.Items[name] then
        Staff29.Notify(source, "ERROR", "Items", "Cet objet n'existe pas.")
        return
    end

    if PROTECTED_ITEMS[name] then
        Staff29.Notify(source, "ERROR", "Items", "Cet objet est indispensable au serveur et ne peut pas être supprimé.")
        return
    end

    local removed = Staff29.Update("DELETE FROM items WHERE name = ?", { name })
    if not removed or removed <= 0 then
        Staff29.Notify(source, "ERROR", "Items", "La suppression de cet objet a échoué.")
        return
    end

    local holders = 0
    local players = VFW.GetExtendedPlayers()
    for i = 1, #players do
        if Inv.CountByName(Inv.PlayerList(players[i]), name) > 0 then
            holders = holders + 1
        end
    end

    VFW.Items[name] = nil
    broadcastCatalog()

    Staff29.Notify(source, "SUCCESS", "Items", ("L'objet %s est supprimé."):format(name))

    logStaff(source, "items_delete", {
        item = name,
        holdersOnline = holders,
    })
end)

registerCallback("vfw:staff:getInventory", function(source, playerId)
    local xPlayer = Staff29.Require(source, PERM_INVENTORY)
    if not xPlayer then return {} end

    local wanted = playerId
    if type(wanted) == "table" then
        wanted = wanted.source or wanted.id
    end

    local target = VFW.GetPlayerFromId(tonumber(wanted))
    if not target then return {} end

    local list = Inv.PlayerList(target)
    local out = {}

    for i = 1, #list do
        local entry = list[i]
        local def = Inv.Def(entry.name)
        if def then
            out[#out + 1] = {
                name = entry.name,
                count = entry.count,
                slot = entry.slot,
                position = entry.slot,
                premium = def.premium and true or false,
                meta = entry.meta or {},
            }
        end
    end

    return out
end)

registerNet("vfw:staff:deteleItems", function(targetId, items)
    local source = source
    local xPlayer = Staff29.Require(source, PERM_INVENTORY)
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        Staff29.Notify(source, "ERROR", "Inventaire", "Ce joueur n'est pas connecté.")
        return
    end

    if type(items) ~= "table" then return end

    local list = Inv.PlayerList(target)
    local removedList = {}
    local processed = 0

    for _, raw in pairs(items) do
        if processed >= CLEAN_ENTRIES_MAX then break end
        if type(raw) == "table" then
            processed = processed + 1

            local slot = Staff29.ToInt(raw.position, 1, Inv.PlayerMaxSlots + 400)
            local amount = Staff29.ToInt(raw.count, 1)
            local entry = slot and Inv.FindSlot(list, slot) or nil

            if entry and amount and type(raw.name) == "string" and entry.name == raw.name then
                local taken = Inv.RemoveFromSlot(list, slot, amount)
                if taken then
                    removedList[#removedList + 1] = { name = taken.name, count = taken.count, slot = slot }
                end
            end
        end
    end

    if #removedList == 0 then
        Staff29.Notify(source, "INFO", "Inventaire", "Aucun objet n'a été retiré.")
        return
    end

    Inv.PushPlayer(target)

    Staff29.Notify(source, "SUCCESS", "Inventaire", ("%d objets retirés de l'inventaire."):format(#removedList))

    logStaff(source, "items_clean", {
        target = target.source,
        identifier = target.identifier,
        name = target.name,
        removed = removedList,
    })
end)

AddEventHandler("vfw:characterLoaded", function(_, xPlayer)
    if not xPlayer or not xPlayer.identifier then return end

    local store = weightStore()
    local entry = store[xPlayer.identifier]
    if type(entry) ~= "table" then return end

    if entry.durationType == "days" and (tonumber(entry.expiresAt) or 0) <= os.time() then
        revokeStored(store, xPlayer.identifier, entry)
        saveWeightStore(store)
        return
    end

    local value = Staff29.ToInt(entry.weight, WEIGHT_MIN, WEIGHT_MAX)
    if value then
        xPlayer.setMaxWeight(value)
    end
end)

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    weaponBurst[source] = nil

    if not xPlayer or not xPlayer.identifier then return end
    revokeSession(xPlayer.identifier)
end)
