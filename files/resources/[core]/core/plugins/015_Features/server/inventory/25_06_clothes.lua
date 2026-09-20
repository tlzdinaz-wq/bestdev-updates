local Inv = VFW.Inventory

Inv.BagBonus = Inv.BagBonus or {}

local PLATE_VALUES = {
    ["armor_plate_light"] = 30,
    ["armor_plate_medium"] = 60,
    ["armor_plate_heavy"] = 100,
}

local PLATE_LABELS = {
    ["armor_plate_light"] = "Plaque legere",
    ["armor_plate_medium"] = "Plaque moyenne",
    ["armor_plate_heavy"] = "Plaque lourde",
}

local VEST_TYPES = {
    ["gpb"] = true,
    ["kevlar"] = true,
}

local bagCategories = nil
local pendingSkinSave = {}

local function loadBagCategories()
    if bagCategories then return bagCategories end
    local rows = MySQL.query.await("SELECT * FROM bag_categories") or {}
    if bagCategories then return bagCategories end
    local loaded = {}
    for i = 1, #rows do
        local row = rows[i]
        local key = ("%s:%s"):format(tostring(row.drawable_id), tostring(row.sex or "m"))
        loaded[key] = {
            id = row.id,
            drawableId = tonumber(row.drawable_id) or 0,
            sex = row.sex or "m",
            capacity = tonumber(row.capacity) or 0,
            label = row.label or "Sac",
        }
    end
    bagCategories = loaded
    return bagCategories
end

--- Invalide le cache (Gestion > Développeurs > Poids des sacs)
function Inv.ReloadBagCategories()
    bagCategories = nil
end

function Inv.ResolveBagCapacity(drawableId, sex)
    local categories = loadBagCategories()
    local normalized = (sex == "w" or sex == "f" or sex == "female") and "w" or "m"
    local entry = categories[("%s:%s"):format(tostring(math.floor(tonumber(drawableId) or 0)), normalized)]
    if entry then return entry.capacity, entry end

    for _, value in pairs(categories) do
        if value.drawableId == (tonumber(drawableId) or 0) then
            return value.capacity, value
        end
    end

    return 0, nil
end

local function baseMaxWeight()
    return tonumber(Config.MaxWeight) or 5000
end

local function applyMaxWeight(xPlayer)
    local bonus = tonumber(Inv.BagBonus[xPlayer.source]) or 0
    if bonus < 0 then bonus = 0 end
    if bonus > 500 then bonus = 500 end
    xPlayer.setMaxWeight(baseMaxWeight() + bonus)
end

Inv.RegisterNet("vfw:bag:addWeightBonus", function(capacity, drawableId, sex)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local value = math.floor(tonumber(capacity) or 0)

    if value <= 0 then
        value = math.floor(Inv.ResolveBagCapacity(drawableId, type(sex) == "string" and sex or "m") or 0)
    end

    if value <= 0 then
        Inv.BagBonus[source] = 0
        applyMaxWeight(xPlayer)
        return
    end

    Inv.BagBonus[source] = value
    applyMaxWeight(xPlayer)
end)

Inv.RegisterNet("vfw:bag:removeWeightBonus", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    Inv.BagBonus[source] = 0
    applyMaxWeight(xPlayer)
end)

AddEventHandler("vfw:playerDropped", function(source)
    Inv.BagBonus[source] = nil
    pendingSkinSave[source] = nil
end)

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    Inv.BagBonus[source] = 0
    if xPlayer then
        applyMaxWeight(xPlayer)
    end
end)

Inv.RegisterNet("vfw:skin:save", function(skin)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(skin) ~= "table" then return end

    local clean = {}
    local count = 0
    for key, value in pairs(skin) do
        if type(key) == "string" and #key <= 40 then
            local kind = type(value)
            if kind == "number" or kind == "string" or kind == "boolean" then
                count = count + 1
                if count > 200 then break end
                clean[key] = value
            end
        end
    end

    if next(clean) == nil then return end

    xPlayer.skin = clean

    if pendingSkinSave[source] then return end
    pendingSkinSave[source] = true

    SetTimeout(2000, function()
        pendingSkinSave[source] = nil
        local player = VFW.GetPlayerFromId(source)
        if not player then return end
        MySQL.update("UPDATE characters SET skin = ? WHERE identifier = ?", {
            VFW.DB.Encode(player.skin), player.identifier,
        })
    end)
end)

local function findVest(list)
    local fallback = nil
    for i = 1, #list do
        local entry = list[i]
        local meta = entry.meta
        if meta and (VEST_TYPES[meta.type] or entry.name == "gpb") then
            if meta.equipped_bproof or meta._equippedSlot == entry.slot then
                return entry
            end
            if not fallback then fallback = entry end
        end
    end
    return fallback
end

local function totalPlateArmor(vest)
    if not vest or not vest.meta or type(vest.meta.plates) ~= "table" then return 0 end
    local total = 0
    for i = 1, #vest.meta.plates do
        total = total + (tonumber(vest.meta.plates[i].durability) or 0)
    end
    if total > 100 then total = 100 end
    return total
end

Inv.RegisterNet("vfw:gpb:markEquipped", function(equipped)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(equipped) ~= "boolean" then return end

    local list = Inv.PlayerList(xPlayer)
    local vest = findVest(list)
    if not vest then return end

    vest.meta = vest.meta or {}
    vest.meta.equipped_bproof = equipped or nil

    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterNet("vfw:bodyArmor:unequipped", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local list = Inv.PlayerList(xPlayer)
    local vest = findVest(list)

    local hasPlates = false
    if vest then
        vest.meta = vest.meta or {}
        vest.meta.equipped_bproof = nil
        hasPlates = totalPlateArmor(vest) > 0
    end

    TriggerClientEvent("vfw:armor:vestRemoved", source, hasPlates)
    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterNet("vfw:armor:equipPlate", function(slot, itemName, gpbDrawable, gpbSex)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(itemName) ~= "string" or not PLATE_VALUES[itemName] then
        TriggerClientEvent("vfw:armor:equipFailed", source, "Cette plaque n'est pas valide")
        return
    end

    -- Plaques interdites sur ce modèle de GPB (Gestion > Développeurs > Plaques GPB)
    if gpbDrawable ~= nil and VFW.GpbPlatesAllowed and not VFW.GpbPlatesAllowed(gpbSex, gpbDrawable) then
        TriggerClientEvent("vfw:armor:equipFailed", source, "Ce gilet n'accepte pas de plaques")
        return
    end

    local list = Inv.PlayerList(xPlayer)

    local plateEntry
    local wanted = tonumber(slot)
    if wanted then
        local candidate = Inv.FindSlot(list, wanted)
        if candidate and candidate.name == itemName then plateEntry = candidate end
    end

    if not plateEntry then
        for i = 1, #list do
            if list[i].name == itemName then
                plateEntry = list[i]
                break
            end
        end
    end

    if not plateEntry then
        TriggerClientEvent("vfw:armor:equipFailed", source, "Vous n'avez pas cette plaque")
        return
    end

    local vest = findVest(list)
    if not vest then
        TriggerClientEvent("vfw:armor:equipFailed", source, "Tu dois porter un gilet par balles")
        return
    end

    local current = totalPlateArmor(vest)
    if current >= 100 then
        TriggerClientEvent("vfw:armor:equipFailed", source, "Votre gilet est deja au maximum")
        return
    end

    local plateValue = PLATE_VALUES[itemName]
    local total = current + plateValue
    local surplus = 0
    if total > 100 then
        surplus = total - 100
        total = 100
    end

    if not Inv.RemoveFromSlot(list, plateEntry.slot, 1) then
        TriggerClientEvent("vfw:armor:equipFailed", source, "Plaque introuvable")
        return
    end

    vest.meta = vest.meta or {}
    if type(vest.meta.plates) ~= "table" then vest.meta.plates = {} end
    vest.meta.plates[#vest.meta.plates + 1] = {
        name = itemName,
        label = PLATE_LABELS[itemName],
        durability = plateValue - surplus,
    }

    TriggerClientEvent("vfw:armor:plateEquipped", source, {
        totalArmor = total,
        plateValue = plateValue,
        plateAdded = PLATE_LABELS[itemName],
        surplus = surplus,
    })

    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterCallback("vfw:clothes:markEquipped", function(source, itemName, clothesType, slot)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, 0 end

    local list = Inv.PlayerList(xPlayer)

    if type(itemName) ~= "string" then
        return Inv.Payload(xPlayer)
    end

    local wantedType = type(clothesType) == "string" and clothesType or itemName
    local target = tonumber(slot)

    for i = 1, #list do
        local entry = list[i]
        local meta = entry.meta
        local entryType = (meta and meta.type) or entry.name
        if entryType == wantedType or entry.name == itemName then
            if meta and meta._equippedSlot then
                meta._equippedSlot = nil
                if next(meta) == nil then entry.meta = nil end
            end
        end
    end

    if target then
        local entry = Inv.FindSlot(list, target)
        if entry and entry.name == itemName then
            entry.meta = entry.meta or {}
            entry.meta._equippedSlot = target
        end
    end

    return Inv.Payload(xPlayer)
end)

function Inv.GetBag(bagUUID)
    if type(bagUUID) ~= "string" or bagUUID == "" or #bagUUID > 64 then return nil end

    local cached = Inv.Bags[bagUUID]
    if cached then return cached end

    local row = MySQL.single.await("SELECT * FROM bags WHERE bag_uuid = ?", { bagUUID })

    local raced = Inv.Bags[bagUUID]
    if raced then return raced end

    local bag
    if row then
        bag = {
            uuid = bagUUID,
            categoryId = tonumber(row.category_id) or 0,
            owner = row.owner_citizenid,
            capacity = tonumber(row.capacity) or 0,
            drawableId = tonumber(row.drawable_id) or 0,
            maxSlots = tonumber(row.max_slots) or 30,
            items = Inv.Normalize(VFW.DB.Decode(row.items, {}), tonumber(row.max_slots) or 30),
        }
    else
        bag = {
            uuid = bagUUID,
            categoryId = 0,
            owner = nil,
            capacity = 0,
            drawableId = 0,
            maxSlots = 30,
            items = {},
        }
        MySQL.insert("INSERT IGNORE INTO bags (bag_uuid, category_id, owner_citizenid, capacity, drawable_id, max_slots, items) VALUES (?, ?, ?, ?, ?, ?, ?)", {
            bagUUID, 0, "", 0, 0, 30, VFW.DB.Encode({}),
        })
    end

    Inv.Bags[bagUUID] = bag
    return bag
end

function Inv.SaveBag(bagUUID)
    local bag = Inv.Bags[bagUUID]
    if not bag then return end
    MySQL.update("UPDATE bags SET items = ?, capacity = ?, drawable_id = ?, max_slots = ? WHERE bag_uuid = ?", {
        VFW.DB.Encode(Inv.Serialize(bag.items)), bag.capacity, bag.drawableId, bag.maxSlots, bagUUID,
    })
end

Inv.RegisterCallback("vfw:bag:getDrawableId", function(source, bagUUID)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(bagUUID) ~= "string" then return 0 end

    local bag = Inv.GetBag(bagUUID)
    if not bag then return 0 end

    if bag.drawableId and bag.drawableId > 0 then
        return bag.drawableId
    end

    if bag.categoryId and bag.categoryId > 0 then
        local row = MySQL.single.await("SELECT drawable_id FROM bag_categories WHERE id = ?", { bag.categoryId })
        if row and tonumber(row.drawable_id) then
            bag.drawableId = tonumber(row.drawable_id)
            return bag.drawableId
        end
    end

    return 0
end)

local function findEquippedBag(list)
    local fallback = nil
    for i = 1, #list do
        local meta = list[i].meta
        if meta and type(meta.bag_uuid) == "string" and meta.bag_uuid ~= "" then
            if meta._equippedSlot == list[i].slot then
                return meta.bag_uuid, list[i]
            end
            if not fallback then fallback = list[i] end
        end
    end
    if fallback then return fallback.meta.bag_uuid, fallback end
    return nil, nil
end

Inv.RegisterCallback("core:server:addOutfitToBag", function(source, itemMetadata)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    if type(itemMetadata) ~= "table" then
        return false, "Cette tenue n'est pas valide"
    end

    local list = Inv.PlayerList(xPlayer)
    local bagUUID = findEquippedBag(list)

    if not bagUUID then
        return false, "Vous ne portez pas de sac"
    end

    local bag = Inv.GetBag(bagUUID)
    if not bag then
        return false, "Sac introuvable"
    end

    if not Inv.Exists("outfit") then
        return false, "Item outfit inconnu"
    end

    local meta = Inv.SanitizeMeta(itemMetadata)
    local added = Inv.AddToList(bag.items, "outfit", 1, meta, bag.maxSlots)
    if added <= 0 then
        return false, "Le sac est plein"
    end

    Inv.SaveBag(bagUUID)
    Inv.BroadcastBag(bagUUID, Inv.Serialize(bag.items), Inv.ListWeight(bag.items))

    return true, "Tenue rangee dans le sac"
end)
