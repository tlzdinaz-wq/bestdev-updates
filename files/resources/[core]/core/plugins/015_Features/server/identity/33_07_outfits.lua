local Cl = VFW.Cloths

local MAX_OUTFITS = 60

local CATEGORY_TO_SKIN = {
    torso = { "torso_1", "torso_2" },
    torso2 = { "torso_1", "torso_2" },
    undershirt = { "tshirt_1", "tshirt_2" },
    arms = { "arms", "arms_2" },
    leg = { "pants_1", "pants_2" },
    shoes = { "shoes_1", "shoes_2" },
    accessory = { "chain_1", "chain_2" },
    bag = { "bags_1", "bags_2" },
    armor = { "bproof_1", "bproof_2" },
    decal = { "decals_1", "decals_2" },
    mask = { "mask_1", "mask_2" },
    hat = { "helmet_1", "helmet_2" },
    glasses = { "glasses_1", "glasses_2" },
    ear = { "ears_1", "ears_2" },
    watch = { "watches_1", "watches_2" },
    bracelet = { "bracelets_1", "bracelets_2" },
}

local SKIN_TO_CATEGORY = {
    { key = "torso_1", texture = "torso_2", category = "torso" },
    { key = "tshirt_1", texture = "tshirt_2", category = "undershirt" },
    { key = "arms", texture = "arms_2", category = "arms" },
    { key = "pants_1", texture = "pants_2", category = "leg" },
    { key = "shoes_1", texture = "shoes_2", category = "shoes" },
    { key = "chain_1", texture = "chain_2", category = "accessory" },
    { key = "bags_1", texture = "bags_2", category = "bag" },
    { key = "bproof_1", texture = "bproof_2", category = "armor" },
    { key = "decals_1", texture = "decals_2", category = "decal" },
    { key = "mask_1", texture = "mask_2", category = "mask" },
    { key = "helmet_1", texture = "helmet_2", category = "hat" },
    { key = "glasses_1", texture = "glasses_2", category = "glasses" },
    { key = "ears_1", texture = "ears_2", category = "ear" },
    { key = "watches_1", texture = "watches_2", category = "watch" },
    { key = "bracelets_1", texture = "bracelets_2", category = "bracelet" },
}

function Cl.SanitizeOutfitItems(items)
    if type(items) ~= "table" then return {} end

    local out = {}
    for i = 1, #items do
        local entry = items[i]
        if type(entry) == "table" and type(entry.category) == "string" and CATEGORY_TO_SKIN[entry.category] then
            out[#out + 1] = {
                category = entry.category,
                drawableId = Cl.Int(entry.drawableId, 0),
                variantId = math.max(Cl.Int(entry.variantId, 0), 0),
            }
        end
        if #out >= 40 then break end
    end
    return out
end

function Cl.SanitizeRawSkin(rawSkin)
    if type(rawSkin) ~= "table" then return {} end

    local keys = Cl.OutfitSkinKeys
    if type(keys) ~= "table" then return {} end

    local out = {}
    for i = 1, #keys do
        local key = keys[i]
        local value = tonumber(rawSkin[key])
        if value then
            out[key] = math.floor(value)
        end
    end
    return out
end

function Cl.OutfitPrice(gender, items)
    local total = 0
    for i = 1, #items do
        local item = items[i]
        if item.drawableId and item.drawableId > 0 then
            total = total + Cl.PriceOf(gender, item.category)
        end
    end
    return total
end

function Cl.OutfitItemsFromSkin(skin)
    local out = {}
    if type(skin) ~= "table" then return out end

    for i = 1, #SKIN_TO_CATEGORY do
        local mapping = SKIN_TO_CATEGORY[i]
        local value = tonumber(skin[mapping.key])
        if value then
            out[#out + 1] = {
                category = mapping.category,
                drawableId = math.floor(value),
                variantId = math.floor(tonumber(skin[mapping.texture]) or 0),
            }
        end
    end
    return out
end

function Cl.SkinFromOutfitItems(items)
    local skin = {}
    for i = 1, #items do
        local item = items[i]
        local slots = CATEGORY_TO_SKIN[item.category]
        if slots then
            skin[slots[1]] = item.drawableId
            skin[slots[2]] = item.variantId
        end
    end
    return skin
end

local function loadOutfitRow(xPlayer, outfitId)
    local id = Cl.Int(outfitId, nil)
    if not id then return nil end
    return MySQL.single.await("SELECT * FROM character_outfits WHERE id = ? AND char_id = ?", { id, xPlayer.charId })
end

function Cl.OutfitPayload(row)
    return {
        id = row.id,
        name = row.name,
        totalPrice = tonumber(row.total_price) or 0,
        quantity = tonumber(row.quantity) or 1,
        type = row.type,
        createdAt = row.created_at,
        outfitData = VFW.DB.Decode(row.outfit_data, {}),
    }
end

local function countOutfits(xPlayer)
    local row = MySQL.single.await("SELECT COUNT(*) AS total FROM character_outfits WHERE char_id = ?", { xPlayer.charId })
    return row and tonumber(row.total) or 0
end

RegisterServerCallback("core:server:getOutfitPrice", function(source, outfitItems)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 0 end

    local items = Cl.SanitizeOutfitItems(outfitItems)
    return Cl.OutfitPrice(Cl.GenderOf(xPlayer), items)
end)

RegisterServerCallback("core:server:checkOutfitName", function(source, name)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local clean = Cl.Str(name, 64)
    if not clean then return false end

    local row = MySQL.single.await(
        "SELECT id FROM character_outfits WHERE char_id = ? AND name = ?",
        { xPlayer.charId, clean }
    )
    return row ~= nil
end)

RegisterServerCallback("core:server:saveOutfit", function(source, outfitName, outfitItems, _totalPrice)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, 0 end
    if not Cl.RateLimit(source, "saveoutfit", 500) then return false, 0 end

    local name = Cl.Str(outfitName, 64) or "Ma Tenue"
    local items = Cl.SanitizeOutfitItems(outfitItems)
    if #items == 0 then return false, 0 end

    if countOutfits(xPlayer) >= MAX_OUTFITS then
        Cl.Notify(source, "Vous avez atteint la limite de tenues enregistrees.")
        return false, 0
    end

    local price = Cl.OutfitPrice(Cl.GenderOf(xPlayer), items)
    local rawSkin = Cl.SkinFromOutfitItems(items)

    local id = MySQL.insert.await([[
        INSERT INTO character_outfits (char_id, name, outfit_data, raw_skin, total_price, quantity, type)
        VALUES (?, ?, ?, ?, ?, 1, 'private')
    ]], { xPlayer.charId, name, VFW.DB.Encode(items), VFW.DB.Encode(rawSkin), price })

    if not id then return false, 0 end
    return true, id
end)

RegisterServerCallback("core:server:saveCurrentOutfit", function(source, outfitName, outfitItems, _totalPrice, paymentMethod, rawSkin)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, 0 end
    if not Cl.RateLimit(source, "savecurrentoutfit", 500) then return false, 0 end

    local name = Cl.Str(outfitName, 64) or "Ma Tenue"
    local items = Cl.SanitizeOutfitItems(outfitItems)
    if #items == 0 then return false, 0 end

    if countOutfits(xPlayer) >= MAX_OUTFITS then
        Cl.Notify(source, "Vous avez atteint la limite de tenues enregistrees.")
        return false, 0
    end

    local gender = Cl.GenderOf(xPlayer)
    local price = Cl.OutfitPrice(gender, items)
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, price, "outfit-save") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false, 0
    end

    local skin = Cl.SanitizeRawSkin(rawSkin)
    if next(skin) == nil then
        skin = Cl.SkinFromOutfitItems(items)
    end

    local id = MySQL.insert.await([[
        INSERT INTO character_outfits (char_id, name, outfit_data, raw_skin, total_price, quantity, type)
        VALUES (?, ?, ?, ?, ?, 1, 'private')
    ]], { xPlayer.charId, name, VFW.DB.Encode(items), VFW.DB.Encode(skin), price })

    if not id then return false, 0 end

    local meta = {
        renamed = name,
        sex = Cl.ShortSex(gender),
        clothesSlotType = "outfit",
        outfitId = id,
        skin = skin,
    }
    Cl.GiveItem(xPlayer, "outfit", 1, meta)

    return true, id
end)

RegisterServerCallback("core:server:loadOutfits", function(source, outfitType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local kind = Cl.Str(outfitType, 16) or "private"

    local rows = MySQL.query.await([[
        SELECT * FROM character_outfits
        WHERE char_id = ? AND type = ? AND bag_uuid IS NULL
        ORDER BY id ASC
    ]], { xPlayer.charId, kind }) or {}

    local out = {}
    for i = 1, #rows do
        out[i] = Cl.OutfitPayload(rows[i])
    end
    return out
end)

RegisterServerCallback("core:server:equipOutfit", function(source, outfitId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, {} end

    local row = loadOutfitRow(xPlayer, outfitId)
    if not row then return false, {} end

    local items = VFW.DB.Decode(row.outfit_data, {})
    if type(items) ~= "table" then items = {} end

    local skin = VFW.DB.Decode(row.raw_skin, {})
    if type(skin) == "table" and next(skin) ~= nil then
        Cl.MergeSkin(xPlayer, skin)
    else
        Cl.MergeSkin(xPlayer, Cl.SkinFromOutfitItems(Cl.SanitizeOutfitItems(items)))
    end

    return true, items
end)

RegisterServerCallback("core:server:deleteOutfit", function(source, outfitId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local row = loadOutfitRow(xPlayer, outfitId)
    if not row then return false end

    MySQL.query.await("DELETE FROM character_outfits WHERE id = ? AND char_id = ?", { row.id, xPlayer.charId })
    return true
end)

RegisterServerCallback("core:server:purchasePrivateOutfit", function(source, outfitId, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not Cl.RateLimit(source, "purchaseoutfit", 500) then return false end

    local row = loadOutfitRow(xPlayer, outfitId)
    if not row then return false end

    local gender = Cl.GenderOf(xPlayer)
    local items = Cl.SanitizeOutfitItems(VFW.DB.Decode(row.outfit_data, {}))
    local price = Cl.OutfitPrice(gender, items)
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, price, "outfit-purchase") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    local skin = VFW.DB.Decode(row.raw_skin, {})
    if type(skin) ~= "table" or next(skin) == nil then
        skin = Cl.SkinFromOutfitItems(items)
    end

    local meta = {
        renamed = row.name,
        sex = Cl.ShortSex(gender),
        clothesSlotType = "outfit",
        outfitId = row.id,
        skin = skin,
    }

    if not Cl.GiveItem(xPlayer, "outfit", 1, meta) then
        if price > 0 and not Cl.IsFreeSession(source) then
            xPlayer.addAccountMoney((method == "bank") and "bank" or "money", price, "outfit-refund")
        end
        Cl.Notify(source, "Inventaire plein.")
        return false
    end

    return true
end)

RegisterServerCallback("core:server:purchaseOutfitItem", function(source, outfitId, item, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(item) ~= "table" then return false end
    if not Cl.RateLimit(source, "purchaseoutfititem", 300) then return false end

    local row = loadOutfitRow(xPlayer, outfitId)
    if not row then return false end

    local category = Cl.Str(item.category, 32)
    if not category or not CATEGORY_TO_SKIN[category] then return false end

    local stored = Cl.SanitizeOutfitItems(VFW.DB.Decode(row.outfit_data, {}))
    local target
    for i = 1, #stored do
        if stored[i].category == category then
            target = stored[i]
            break
        end
    end

    if not target then return false end

    local gender = Cl.GenderOf(xPlayer)
    local price = Cl.PriceOf(gender, category)
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, price, "outfit-item") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    local slots = CATEGORY_TO_SKIN[category]
    Cl.MergeSkin(xPlayer, { [slots[1]] = target.drawableId, [slots[2]] = target.variantId })

    return true
end)
