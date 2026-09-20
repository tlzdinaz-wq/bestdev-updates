local Cl = VFW.Cloths

local BAG_ITEM = "clothes_bag"
local BAG_BASE_PRICE = 500
local PICKUP_DISTANCE = 6.0

local placed = {}
local loaded = false

local function validUuid(value)
    if type(value) ~= "string" then return nil end
    if value == "" or #value > 64 then return nil end
    if not value:match("^[%w_%-]+$") then return nil end
    return value
end

local function buildPlaced(row)
    return {
        bagUUID = row.bag_uuid,
        owner = tonumber(row.owner_char_id) or 0,
        coords = {
            x = tonumber(row.x) or 0.0,
            y = tonumber(row.y) or 0.0,
            z = tonumber(row.z) or 0.0,
        },
        rotation = tonumber(row.rotation) or 0.0,
        metadata = VFW.DB.Decode(row.metadata, {}),
        netId = tonumber(row.net_id) or 0,
    }
end

local function loadPlaced()
    local rows = MySQL.query.await("SELECT * FROM placed_clothes_bags") or {}
    local out = {}
    for i = 1, #rows do
        local entry = buildPlaced(rows[i])
        out[entry.bagUUID] = entry
    end
    placed = out
    loaded = true
    return placed
end

local function allPlaced()
    if not loaded then
        loadPlaced()
    end
    return placed
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 400 do
        Wait(250)
        tries = tries + 1
    end
    loadPlaced()
end)

local function payloadForClient()
    local out = {}
    for uuid, entry in pairs(allPlaced()) do
        out[uuid] = {
            coords = entry.coords,
            rotation = entry.rotation,
            metadata = entry.metadata,
            netId = entry.netId,
        }
    end
    return out
end

Cl.WaitInventory(function(Inv)
    Inv.RegisterUsableItem(BAG_ITEM, function(xPlayer, entry)
        local source = xPlayer.source
        if not Cl.RateLimit(source, "placebag", 3000) then return end

        local meta = entry.meta
        if type(meta) ~= "table" then meta = {} end

        if not validUuid(meta.bag_uuid) then
            meta.bag_uuid = "cb" .. Cl.Uuid():gsub("[^%w]", "")
            entry.meta = meta
            Inv.PushPlayer(xPlayer)
        end

        if allPlaced()[meta.bag_uuid] then
            Cl.Notify(source, "Ce sac est deja pose au sol.")
            return
        end

        TriggerClientEvent("core:placeClothesBag", source, meta)
    end)
end)

RegisterNetEvent("core:server:bagPlacedOnGround", function(coords, heading, metadata, netId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(coords) ~= "table" or type(metadata) ~= "table" then return end

    local uuid = validUuid(metadata.bag_uuid)
    if not uuid then return end
    if allPlaced()[uuid] then return end

    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return end

    local playerCoords = Cl.Coords(source)
    if playerCoords and Cl.Distance(playerCoords, { x = x, y = y, z = z }) > 12.0 then return end

    local entry, list = Cl.FindItemByMeta(xPlayer, BAG_ITEM, "bag_uuid", uuid)
    if entry then
        local Inv = VFW.Inventory
        Inv.RemoveFromSlot(list, entry.slot, 1)
        Inv.PushPlayer(xPlayer)
    elseif not Cl.RemoveItem(xPlayer, BAG_ITEM, 1) then
        return
    end

    local meta = Cl.SanitizeMetadata(metadata) or { bag_uuid = uuid }
    meta.bag_uuid = uuid

    local record = {
        bagUUID = uuid,
        owner = xPlayer.charId,
        coords = { x = x, y = y, z = z },
        rotation = tonumber(heading) or 0.0,
        metadata = meta,
        netId = Cl.Int(netId, 0),
    }

    allPlaced()[uuid] = record

    MySQL.query.await([[
        INSERT INTO placed_clothes_bags (bag_uuid, owner_char_id, x, y, z, rotation, metadata, net_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE x = VALUES(x), y = VALUES(y), z = VALUES(z),
            rotation = VALUES(rotation), metadata = VALUES(metadata), net_id = VALUES(net_id)
    ]], { uuid, xPlayer.charId, x, y, z, record.rotation, VFW.DB.Encode(meta), record.netId })

    MySQL.update("UPDATE character_outfits SET bag_uuid = ? WHERE char_id = ? AND bag_uuid IS NULL AND type = 'private'", {
        uuid, xPlayer.charId,
    })

    local players = VFW.GetPlayers()
    for i = 1, #players do
        if players[i] ~= source then
            TriggerClientEvent("core:client:syncPlacedBag", players[i], uuid, record.coords, record.rotation, meta, record.netId)
        end
    end
end)

RegisterServerCallback("core:server:getAllPlacedBags", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return payloadForClient()
end)

RegisterServerCallback("core:server:openPlacedBag", function(source, bagUUID)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, {} end

    local uuid = validUuid(bagUUID)
    if not uuid then return false, {} end

    local record = allPlaced()[uuid]
    if not record then return false, {} end

    local playerCoords = Cl.Coords(source)
    if playerCoords and Cl.Distance(playerCoords, record.coords) > PICKUP_DISTANCE then
        Cl.Notify(source, "Vous etes trop loin du sac.")
        return false, {}
    end

    return true, record.metadata or {}
end)

RegisterServerCallback("core:server:loadBagOutfits", function(source, bagUUID)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {}, false end

    local uuid = validUuid(bagUUID)
    if not uuid then return {}, false end

    local record = allPlaced()[uuid]
    if not record then return {}, false end

    local rows = MySQL.query.await("SELECT * FROM character_outfits WHERE bag_uuid = ? ORDER BY id ASC", { uuid }) or {}

    local out = {}
    for i = 1, #rows do
        out[i] = Cl.OutfitPayload(rows[i])
    end

    return out, record.owner == xPlayer.charId
end)

RegisterServerCallback("core:server:pickupPlacedBag", function(source, bagUUID)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local uuid = validUuid(bagUUID)
    if not uuid then return false, "Sac introuvable" end

    local record = allPlaced()[uuid]
    if not record then return false, "Sac introuvable" end

    local playerCoords = Cl.Coords(source)
    if playerCoords and Cl.Distance(playerCoords, record.coords) > PICKUP_DISTANCE then
        return false, "Vous etes trop loin du sac."
    end

    local meta = record.metadata or {}
    meta.bag_uuid = uuid

    allPlaced()[uuid] = nil

    if not Cl.GiveItem(xPlayer, BAG_ITEM, 1, meta) then
        allPlaced()[uuid] = record
        return false, "Inventaire plein."
    end

    MySQL.update("UPDATE character_outfits SET bag_uuid = NULL WHERE bag_uuid = ?", { uuid })
    MySQL.query.await("DELETE FROM placed_clothes_bags WHERE bag_uuid = ?", { uuid })

    TriggerClientEvent("core:client:removePlacedBag", -1, uuid)

    return true, "Sac recupere."
end)

RegisterServerCallback("core:server:equipBagOutfit", function(source, outfitId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, {}, 0 end

    local id = Cl.Int(outfitId, nil)
    if not id then return false, {}, 0 end

    local row = MySQL.single.await("SELECT * FROM character_outfits WHERE id = ? AND bag_uuid IS NOT NULL", { id })
    if not row then return false, {}, 0 end

    local record = allPlaced()[row.bag_uuid]
    if not record then return false, {}, 0 end

    local playerCoords = Cl.Coords(source)
    if playerCoords and Cl.Distance(playerCoords, record.coords) > PICKUP_DISTANCE then
        Cl.Notify(source, "Vous etes trop loin du sac.")
        return false, {}, 0
    end

    local claimed = MySQL.update.await([[
        UPDATE character_outfits SET quantity = quantity - 1
        WHERE id = ? AND bag_uuid IS NOT NULL AND quantity > 0
    ]], { row.id })
    if (tonumber(claimed) or 0) < 1 then return false, {}, 0 end

    local items = VFW.DB.Decode(row.outfit_data, {})
    if type(items) ~= "table" then items = {} end

    local skin = VFW.DB.Decode(row.raw_skin, {})
    if type(skin) == "table" and next(skin) ~= nil then
        Cl.MergeSkin(xPlayer, skin)
    else
        skin = Cl.SkinFromOutfitItems(Cl.SanitizeOutfitItems(items))
        Cl.MergeSkin(xPlayer, skin)
    end

    local quantity = (tonumber(row.quantity) or 1) - 1

    Cl.GiveItem(xPlayer, "outfit", 1, {
        renamed = row.name,
        sex = Cl.ShortSex(Cl.GenderOf(xPlayer)),
        clothesSlotType = "outfit",
        outfitId = row.id,
        skin = skin,
    })

    if quantity <= 0 then
        MySQL.query.await("DELETE FROM character_outfits WHERE id = ? AND quantity <= 0", { row.id })
        quantity = 0
    end

    return true, items, quantity
end)

RegisterServerCallback("core:server:removeOutfitFromBag", function(source, outfitId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = Cl.Int(outfitId, nil)
    if not id then return false, "Tenue introuvable" end

    local row = MySQL.single.await("SELECT * FROM character_outfits WHERE id = ? AND bag_uuid IS NOT NULL", { id })
    if not row then return false, "Tenue introuvable" end

    local record = allPlaced()[row.bag_uuid]
    if not record then return false, "Sac introuvable" end

    if record.owner ~= xPlayer.charId then
        return false, "Ce sac ne vous appartient pas."
    end

    local playerCoords = Cl.Coords(source)
    if playerCoords and Cl.Distance(playerCoords, record.coords) > PICKUP_DISTANCE then
        return false, "Vous etes trop loin du sac."
    end

    MySQL.update("UPDATE character_outfits SET bag_uuid = NULL WHERE id = ?", { row.id })
    return true, "Tenue retiree du sac."
end)

RegisterServerCallback("core:server:getBagPrice", function(source, shopId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return BAG_BASE_PRICE end

    local base = Cl.PriceOf(Cl.GenderOf(xPlayer), "bag")
    if base <= 0 then base = BAG_BASE_PRICE end

    return math.floor(base * Cl.ShopMultiplier(shopId))
end)

RegisterServerCallback("core:server:buyClothingBag", function(source, paymentMethod, shopId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not Cl.RateLimit(source, "buybag", 500) then return false end

    local base = Cl.PriceOf(Cl.GenderOf(xPlayer), "bag")
    if base <= 0 then base = BAG_BASE_PRICE end

    local price = math.floor(base * Cl.ShopMultiplier(shopId))
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, price, "clothes-bag") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    local meta = { bag_uuid = "cb" .. Cl.Uuid():gsub("[^%w]", "") }

    if not Cl.GiveItem(xPlayer, BAG_ITEM, 1, meta) then
        if price > 0 and not Cl.IsFreeSession(source) then
            xPlayer.addAccountMoney((method == "bank") and "bank" or "money", price, "clothes-bag-refund")
        end
        Cl.Notify(source, "Inventaire plein.")
        return false
    end

    return true
end)
