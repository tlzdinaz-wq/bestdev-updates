local PS = VFW.PropertyServer

local KEY_ITEM = "key_motel"
local STORAGE_DAYS = 7
local MAX_RENT_HOURS = 720

PS.Motels = {}
PS.Rooms = {}

local function normalizePromotions(value)
    local decoded = PS.Decode(value, nil)
    if type(decoded) ~= "table" then return nil end
    local out = {}
    local found = false
    for k, v in pairs(decoded) do
        local hours = PS.ToInt(k)
        local percent = PS.ToInt(v)
        if hours and percent and percent > 0 and percent <= 100 then
            out[hours] = percent
            found = true
        end
    end
    if not found then return nil end
    return out
end

local function encodePromotions(value)
    if type(value) ~= "table" then return nil end
    local out = {}
    local found = false
    for k, v in pairs(value) do
        local hours = PS.ToInt(k)
        local percent = PS.ToInt(v)
        if hours and percent and percent > 0 and percent <= 100 then
            out[tostring(hours)] = percent
            found = true
        end
    end
    if not found then return nil end
    return PS.Encode(out)
end

local function motelRow(row)
    return {
        id = row.id,
        name = row.name,
        pricePerHour = row.price_per_hour or 0,
        duplicateKeyPrice = row.duplicate_key_price or 0,
        npcModel = row.npc_model,
        npcCoords = PS.Decode(row.npc_coords, { x = 0.0, y = 0.0, z = 0.0, h = 0.0 }),
        blipEnabled = row.blip_enabled == 1,
        blipSprite = row.blip_sprite or 475,
        blipColor = row.blip_color or 5,
        chestMaxWeight = row.chest_max_weight or 50,
        chestMaxSlots = row.chest_max_slots or 20,
        promotions = normalizePromotions(row.promotions),
    }
end

local function roomRow(row)
    return {
        id = row.id,
        motelId = row.motel_id,
        roomNumber = row.room_number or 0,
        label = row.label,
        priceOverride = row.price_override,
        doorlockIds = PS.Decode(row.doorlock_ids, {}) or {},
        iconOffsets = PS.Decode(row.icon_offsets, nil),
        chestCoords = PS.Decode(row.chest_coords, nil),
        chestMaxWeight = row.chest_max_weight,
        chestMaxSlots = row.chest_max_slots,
        promotions = normalizePromotions(row.promotions),
    }
end

function PS.LoadMotels()
    local motels = MySQL.query.await("SELECT * FROM motels") or {}
    local rooms = MySQL.query.await("SELECT * FROM motel_rooms ORDER BY room_number") or {}

    PS.Motels = {}
    PS.Rooms = {}

    for i = 1, #motels do
        local m = motelRow(motels[i])
        m.rooms = {}
        PS.Motels[m.id] = m
    end

    for i = 1, #rooms do
        local r = roomRow(rooms[i])
        PS.Rooms[r.id] = r
        local motel = PS.Motels[r.motelId]
        if motel then
            motel.rooms[#motel.rooms + 1] = r
        end
    end
end

function PS.MotelLog(motelId, roomId, roomLabel, action, playerName, details)
    MySQL.insert("INSERT INTO motel_logs (motel_id, room_id, room_label, action, player_name, details, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        PS.ToInt(motelId) or 0,
        PS.ToInt(roomId),
        roomLabel,
        tostring(action):sub(1, 32),
        playerName,
        details and tostring(details):sub(1, 400) or nil,
        PS.Now(),
    })
end

local function roomPrice(room, motel)
    local base = PS.ToInt(room.priceOverride)
    if not base then base = motel.pricePerHour or 0 end
    return base
end

local function roomPromotions(room, motel)
    return room.promotions or motel.promotions
end

local function computeCost(room, motel, hours)
    local price = roomPrice(room, motel) * hours
    local promos = roomPromotions(room, motel)
    if promos then
        local best = 0
        for tierHours, percent in pairs(promos) do
            if hours >= tierHours and percent > best then
                best = percent
            end
        end
        if best > 0 then
            price = math.floor(price * (100 - best) / 100)
        end
    end
    if price < 0 then price = 0 end
    return price
end

local function getRental(roomId)
    return MySQL.single.await("SELECT * FROM motel_rentals WHERE room_id = ?", { roomId })
end

local function normalizeMethod(method)
    if method == "card" or method == "bank" then return "bank" end
    if method == "combined" then return "combined" end
    return "cash"
end

local rentLocks = {}

local function takeRentLock(roomId)
    local at = rentLocks[roomId]
    local now = GetGameTimer()
    if at and (now - at) < 10000 then return false end
    rentLocks[roomId] = now
    return true
end

local function motelBuildRooms(motel)
    local out = {}
    for i = 1, #motel.rooms do
        local room = motel.rooms[i]
        local rental = getRental(room.id)
        out[#out + 1] = {
            id = room.id,
            roomNumber = room.roomNumber,
            label = room.label,
            price = roomPrice(room, motel),
            promotions = roomPromotions(room, motel),
            available = rental == nil,
        }
    end
    return out
end

local function storedItemsFor(identifier)
    local rows = MySQL.query.await("SELECT * FROM motel_storage WHERE identifier = ? ORDER BY id", { identifier }) or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            id = rows[i].id,
            motelName = rows[i].motel_name,
            roomNumber = rows[i].room_number,
            itemCount = rows[i].item_count,
            expiresAt = rows[i].expires_at,
        }
    end
    return out
end

local function giveKey(xPlayer, room, pincode)
    if not VFW.Items[KEY_ITEM] then return false end
    return xPlayer.addInventoryItem(KEY_ITEM, 1, {
        pincode = pincode,
        doorlockIds = room.doorlockIds,
        roomId = room.id,
        roomNumber = room.roomNumber,
        label = room.label,
    }) and true or false
end

local function removeKeys(xPlayer, roomId)
    if not xPlayer or not xPlayer.inventory then return end
    local toRemove = 0
    for i = 1, #xPlayer.inventory do
        local item = xPlayer.inventory[i]
        if item.name == KEY_ITEM then
            local meta = item.metadata
            if type(meta) ~= "table" or meta.roomId == roomId then
                toRemove = toRemove + (item.count or 1)
            end
        end
    end
    if toRemove > 0 then
        xPlayer.removeInventoryItem(KEY_ITEM, toRemove)
    end
end

local function grabChestContents(roomId)
    local chestId = ("motel:%d"):format(roomId)
    local items = {}
    local ok, rows = pcall(function()
        return MySQL.query.await("SELECT name, count, meta FROM chest_items WHERE chest_id = ?", { chestId })
    end)
    if ok and type(rows) == "table" then
        for i = 1, #rows do
            items[#items + 1] = {
                name = rows[i].name,
                count = rows[i].count,
                meta = PS.Decode(rows[i].meta, nil),
            }
        end
        pcall(function()
            MySQL.update.await("DELETE FROM chest_items WHERE chest_id = ?", { chestId })
        end)
    end
    return items
end

local function archiveRoomContents(room, motel, identifier)
    local items = grabChestContents(room.id)
    if #items == 0 then return end
    MySQL.insert("INSERT INTO motel_storage (identifier, motel_id, motel_name, room_number, items, item_count, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        identifier,
        motel and motel.id or 0,
        motel and motel.name or nil,
        room.roomNumber,
        PS.Encode(items),
        #items,
        PS.Now() + (STORAGE_DAYS * 86400),
    })
end

local function endRental(room, motel, rental, reason)
    if not rental then return end
    MySQL.update.await("DELETE FROM motel_rentals WHERE room_id = ?", { room.id })

    local tenant = VFW.GetPlayerFromIdentifier(rental.identifier)
    if tenant then
        removeKeys(tenant, room.id)
    end

    archiveRoomContents(room, motel, rental.identifier)
    PS.MotelLog(motel and motel.id or 0, room.id, room.label, reason or "checkout", rental.player_name, nil)
end

function PS.BuildMotelList()
    local out = {}
    for _, motel in pairs(PS.Motels) do
        out[#out + 1] = {
            id = motel.id,
            name = motel.name,
            npcModel = motel.npcModel,
            npcCoords = motel.npcCoords,
            blipEnabled = motel.blipEnabled,
            blipSprite = motel.blipSprite,
            blipColor = motel.blipColor,
            pricePerHour = motel.pricePerHour,
            duplicateKeyPrice = motel.duplicateKeyPrice,
            chestMaxWeight = motel.chestMaxWeight,
            chestMaxSlots = motel.chestMaxSlots,
            promotions = motel.promotions,
            roomCount = #motel.rooms,
        }
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

RegisterServerCallback("motel:server:getAllMotels", function(source)
    return PS.BuildMotelList()
end)

RegisterServerCallback("motel:server:getMotelData", function(source, motelId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local motel = PS.Motels[PS.ToInt(motelId) or 0]
    if not motel then return nil end

    local myRental = nil
    local rentalRow = MySQL.single.await([[
        SELECT r.*, m.room_number, m.label FROM motel_rentals r
        INNER JOIN motel_rooms m ON m.id = r.room_id
        WHERE r.identifier = ? AND m.motel_id = ?
    ]], { xPlayer.identifier, motel.id })

    if rentalRow then
        myRental = {
            roomId = rentalRow.room_id,
            roomNumber = rentalRow.room_number,
            roomLabel = rentalRow.label,
        }
    end

    return {
        name = motel.name,
        pricePerHour = motel.pricePerHour,
        duplicateKeyPrice = motel.duplicateKeyPrice,
        promotions = motel.promotions,
        playerMoney = PS.GetBalance(xPlayer, "money"),
        playerBank = PS.GetBalance(xPlayer, "bank"),
        playerFirstName = xPlayer.firstName,
        playerLastName = xPlayer.lastName,
        rooms = motelBuildRooms(motel),
        myRental = myRental,
        storedItems = storedItemsFor(xPlayer.identifier),
    }
end)

RegisterServerCallback("motel:server:rentRoom", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    if not motel then return { success = false, message = "Motel introuvable." } end

    local hours = PS.ToInt(data.hours)
    if not hours or hours < 1 or hours > MAX_RENT_HOURS then
        return { success = false, message = "Cette duree n'est pas valide." }
    end

    if not takeRentLock(room.id) then
        return { success = false, message = "Cette chambre est deja louee." }
    end

    if getRental(room.id) then
        rentLocks[room.id] = nil
        return { success = false, message = "Cette chambre est deja louee." }
    end

    local existing = MySQL.single.await([[
        SELECT r.id FROM motel_rentals r
        INNER JOIN motel_rooms m ON m.id = r.room_id
        WHERE r.identifier = ? AND m.motel_id = ?
    ]], { xPlayer.identifier, motel.id })
    if existing then
        rentLocks[room.id] = nil
        return { success = false, message = "Vous louez deja une chambre dans ce motel." }
    end

    local cost = computeCost(room, motel, hours)
    if not PS.TakeMoney(xPlayer, cost, normalizeMethod(data.method)) then
        rentLocks[room.id] = nil
        return { success = false, message = "Fonds insuffisants." }
    end

    local now = PS.Now()
    local pincode = math.random(1000, 9999)

    MySQL.insert.await("INSERT INTO motel_rentals (room_id, motel_id, identifier, player_name, pincode, start_at, expire_at, total_duration_hours) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", {
        room.id, motel.id, xPlayer.identifier, xPlayer.name, pincode, now, now + (hours * 3600), hours,
    })
    rentLocks[room.id] = nil

    giveKey(xPlayer, room, pincode)
    PS.MotelLog(motel.id, room.id, room.label, "rent", xPlayer.name, ("%dh - %d"):format(hours, cost))
    TriggerClientEvent("motel:client:roomRented", -1, motel.id)

    return { success = true, message = ("Chambre %d louee pour %dh."):format(room.roomNumber, hours) }
end)

RegisterServerCallback("motel:server:extendRental", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    if not motel then return { success = false, message = "Motel introuvable." } end

    local hours = PS.ToInt(data.hours)
    if not hours or hours < 1 or hours > MAX_RENT_HOURS then
        return { success = false, message = "Cette duree n'est pas valide." }
    end

    local rental = getRental(room.id)
    if not rental or rental.identifier ~= xPlayer.identifier then
        return { success = false, message = "Vous ne louez pas cette chambre." }
    end

    local cost = computeCost(room, motel, hours)
    if not PS.TakeMoney(xPlayer, cost, normalizeMethod(data.method)) then
        return { success = false, message = "Fonds insuffisants." }
    end

    local base = math.max(rental.expire_at or 0, PS.Now())
    MySQL.update.await("UPDATE motel_rentals SET expire_at = ?, total_duration_hours = total_duration_hours + ? WHERE room_id = ?", {
        base + (hours * 3600), hours, room.id,
    })

    PS.MotelLog(motel.id, room.id, room.label, "extend", xPlayer.name, ("+%dh - %d"):format(hours, cost))
    TriggerClientEvent("motel:client:roomRented", -1, motel.id)

    return { success = true, message = ("Location prolongee de %dh."):format(hours) }
end)

RegisterServerCallback("motel:server:checkoutRoom", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    local rental = getRental(room.id)
    if not rental or rental.identifier ~= xPlayer.identifier then
        return { success = false, message = "Vous ne louez pas cette chambre." }
    end

    endRental(room, motel, rental, "checkout")
    TriggerClientEvent("motel:client:roomCheckedOut", -1, motel and motel.id or 0)

    return { success = true, message = "Chambre liberee." }
end)

RegisterServerCallback("motel:server:duplicateKey", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    if not motel then return { success = false, message = "Motel introuvable." } end

    local rental = getRental(room.id)
    if not rental or rental.identifier ~= xPlayer.identifier then
        return { success = false, message = "Vous ne louez pas cette chambre." }
    end

    local reason = PS.SafeString(data.reason, 200) or ""
    local cost = PS.ToInt(motel.duplicateKeyPrice) or 0

    if cost > 0 and not PS.TakeMoney(xPlayer, cost, normalizeMethod(data.method)) then
        return { success = false, message = "Fonds insuffisants." }
    end

    if not giveKey(xPlayer, room, rental.pincode) then
        return { success = false, message = "Impossible de creer le double." }
    end

    PS.MotelLog(motel.id, room.id, room.label, "duplicate_key", xPlayer.name, reason)
    return { success = true, message = "Double de cle remis." }
end)

RegisterServerCallback("motel:server:claimStorage", function(source, storageId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local sid = PS.ToInt(storageId)
    if not sid then return { success = false, message = "Ce stockage n'est pas valide." } end

    local row = MySQL.single.await("SELECT * FROM motel_storage WHERE id = ? AND identifier = ?", { sid, xPlayer.identifier })
    if not row then return { success = false, message = "Stockage introuvable." } end

    local items = PS.Decode(row.items, {}) or {}
    local rest = {}
    for i = 1, #items do
        local item = items[i]
        if item.name and VFW.Items[item.name] then
            if xPlayer.canCarryItem(item.name, item.count or 1) then
                xPlayer.addInventoryItem(item.name, item.count or 1, item.meta)
            else
                rest[#rest + 1] = item
            end
        end
    end

    if #rest > 0 then
        MySQL.update.await("UPDATE motel_storage SET items = ?, item_count = ? WHERE id = ?", { PS.Encode(rest), #rest, sid })
        return { success = false, message = "Inventaire plein, une partie des affaires reste stockee." }
    end

    MySQL.update.await("DELETE FROM motel_storage WHERE id = ?", { sid })
    return { success = true, message = "Affaires recuperees." }
end)

RegisterServerCallback("motel:server:openChest", function(source, roomId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local room = PS.Rooms[PS.ToInt(roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    local rental = getRental(room.id)
    if not rental then
        return { success = false, message = "Cette chambre n'est pas louee." }
    end

    local allowed = rental.identifier == xPlayer.identifier
    if not allowed and xPlayer.inventory then
        for i = 1, #xPlayer.inventory do
            local item = xPlayer.inventory[i]
            if item.name == KEY_ITEM and type(item.metadata) == "table" and item.metadata.pincode == rental.pincode then
                allowed = true
                break
            end
        end
    end
    if not allowed and PS.IsStaff(xPlayer) then
        allowed = true
    end

    if not allowed then
        return { success = false, message = "Vous n'avez pas les cles de cette chambre." }
    end

    return {
        success = true,
        chestId = ("motel:%d"):format(room.id),
        maxSlots = room.chestMaxSlots or (motel and motel.chestMaxSlots) or 20,
    }
end)

RegisterServerCallback("motel:server:getMotelDoorlockIds", function(source)
    local out = {}
    for _, room in pairs(PS.Rooms) do
        for i = 1, #room.doorlockIds do
            local dlId = PS.ToInt(room.doorlockIds[i])
            if dlId then
                local offset = room.iconOffsets and room.iconOffsets[tostring(dlId)] or nil
                out[#out + 1] = { id = dlId, iconOffset = offset }
            end
        end
    end
    return out
end)

RegisterServerCallback("motel:server:getRoomChests", function(source)
    local out = {}
    for _, room in pairs(PS.Rooms) do
        if room.chestCoords then
            out[#out + 1] = {
                roomId = room.id,
                motelId = room.motelId,
                roomNumber = room.roomNumber,
                chestCoords = room.chestCoords,
            }
        end
    end
    return out
end)

local function requireMotelAdmin(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission("motel_builder") and not PS.IsStaff(xPlayer) then return nil end
    return xPlayer
end

RegisterServerCallback("motel:server:getMotelDetails", function(source, motelId)
    if not requireMotelAdmin(source) then return nil end

    local motel = PS.Motels[PS.ToInt(motelId) or 0]
    if not motel then return nil end

    local rooms = {}
    local now = PS.Now()
    for i = 1, #motel.rooms do
        local room = motel.rooms[i]
        local rental = getRental(room.id)
        rooms[#rooms + 1] = {
            id = room.id,
            roomNumber = room.roomNumber,
            label = room.label,
            available = rental == nil,
            chestCoords = room.chestCoords,
            priceOverride = room.priceOverride,
            doorlockIds = room.doorlockIds,
            promotions = room.promotions,
            iconOffsets = room.iconOffsets,
            chestMaxWeight = room.chestMaxWeight,
            chestMaxSlots = room.chestMaxSlots,
            rental = rental and {
                playerName = rental.player_name,
                remainingSeconds = math.max(0, (rental.expire_at or 0) - now),
                totalDurationHours = rental.total_duration_hours or 0,
            } or nil,
        }
    end

    return { rooms = rooms }
end)

RegisterServerCallback("motel:server:admin:extendRoom", function(source, data)
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return { success = false, message = "Permission refusee." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local hours = PS.ToInt(data.hours)
    if not hours or hours < 1 or hours > MAX_RENT_HOURS then
        return { success = false, message = "Cette duree n'est pas valide." }
    end

    local rental = getRental(room.id)
    if not rental then return { success = false, message = "Cette chambre n'est pas louee." } end

    local base = math.max(rental.expire_at or 0, PS.Now())
    MySQL.update.await("UPDATE motel_rentals SET expire_at = ?, total_duration_hours = total_duration_hours + ? WHERE room_id = ?", {
        base + (hours * 3600), hours, room.id,
    })

    PS.MotelLog(room.motelId, room.id, room.label, "admin_extend", xPlayer.name, ("+%dh"):format(hours))
    TriggerClientEvent("motel:client:roomRented", -1, room.motelId)

    return { success = true, message = ("Location prolongee de %dh."):format(hours) }
end)

RegisterServerCallback("motel:server:admin:evictRoom", function(source, data)
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return { success = false, message = "Permission refusee." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    local rental = getRental(room.id)
    if not rental then return { success = false, message = "Cette chambre n'est pas louee." } end

    if data.refund == true and motel then
        local remaining = math.max(0, (rental.expire_at or 0) - PS.Now())
        local refund = math.floor((remaining / 3600) * roomPrice(room, motel))
        local tenant = VFW.GetPlayerFromIdentifier(rental.identifier)
        if tenant and refund > 0 then
            PS.GiveMoney(tenant, refund, "bank")
        end
    end

    endRental(room, motel, rental, "admin_evict")
    TriggerClientEvent("motel:client:roomCheckedOut", -1, room.motelId)

    return { success = true, message = ("%s a ete expulse."):format(rental.player_name or "Le locataire") }
end)

RegisterServerCallback("motel:server:admin:assignRoom", function(source, data)
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return { success = false, message = "Permission refusee." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    if not motel then return { success = false, message = "Motel introuvable." } end

    local hours = PS.ToInt(data.hours)
    if not hours or hours < 1 or hours > MAX_RENT_HOURS then
        return { success = false, message = "Cette duree n'est pas valide." }
    end

    local target = VFW.GetPlayerFromId(PS.ToInt(data.targetSource))
    if not target then return { success = false, message = "Joueur introuvable." } end

    if getRental(room.id) then
        return { success = false, message = "Cette chambre est deja louee." }
    end

    local now = PS.Now()
    local pincode = math.random(1000, 9999)

    MySQL.insert.await("INSERT INTO motel_rentals (room_id, motel_id, identifier, player_name, pincode, start_at, expire_at, total_duration_hours) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", {
        room.id, motel.id, target.identifier, target.name, pincode, now, now + (hours * 3600), hours,
    })

    giveKey(target, room, pincode)
    PS.MotelLog(motel.id, room.id, room.label, "admin_assign", xPlayer.name, target.name)
    TriggerClientEvent("motel:client:roomRented", -1, motel.id)

    return { success = true, message = ("Chambre attribuee a %s."):format(target.name) }
end)

RegisterServerCallback("motel:server:admin:updateRoom", function(source, data)
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return { success = false, message = "Permission refusee." } end
    if type(data) ~= "table" then return { success = false, message = "Les informations envoyees ne sont pas valides." } end

    local room = PS.Rooms[PS.ToInt(data.roomId) or 0]
    if not room then return { success = false, message = "Chambre introuvable." } end

    local motel = PS.Motels[room.motelId]
    if not motel then return { success = false, message = "Motel introuvable." } end

    room.label = PS.SafeString(data.label, 64) or room.label
    room.roomNumber = PS.ToInt(data.roomNumber) or room.roomNumber
    room.priceOverride = PS.ToInt(data.priceOverride)
    room.chestMaxWeight = PS.ToInt(data.chestMaxWeight)
    room.chestMaxSlots = PS.ToInt(data.chestMaxSlots)
    room.chestCoords = PS.ReadVec3(data.chestCoords)

    local doorlockIds = {}
    if type(data.doorlockIds) == "table" then
        for i = 1, #data.doorlockIds do
            local dlId = PS.ToInt(data.doorlockIds[i])
            if dlId then doorlockIds[#doorlockIds + 1] = dlId end
        end
    end
    room.doorlockIds = doorlockIds

    local iconOffsets = nil
    if type(data.iconOffsets) == "table" then
        iconOffsets = {}
        for key, value in pairs(data.iconOffsets) do
            local offset = PS.ReadVec3(value)
            local dlId = PS.ToInt(key)
            if offset and dlId then
                iconOffsets[tostring(dlId)] = offset
            end
        end
        if not next(iconOffsets) then iconOffsets = nil end
    end
    room.iconOffsets = iconOffsets

    if type(data.promotions) == "table" then
        room.promotions = normalizePromotions(PS.Encode(data.promotions))
    else
        room.promotions = nil
    end

    MySQL.update.await([[
        UPDATE motel_rooms SET room_number = ?, label = ?, price_override = ?, doorlock_ids = ?, icon_offsets = ?,
        chest_coords = ?, chest_max_weight = ?, chest_max_slots = ?, promotions = ? WHERE id = ?
    ]], {
        room.roomNumber, room.label, room.priceOverride,
        PS.Encode(room.doorlockIds),
        iconOffsets and PS.Encode(iconOffsets) or nil,
        room.chestCoords and PS.Encode(room.chestCoords) or nil,
        room.chestMaxWeight, room.chestMaxSlots,
        encodePromotions(room.promotions),
        room.id,
    })

    PS.MotelLog(motel.id, room.id, room.label, "admin_room_update", xPlayer.name, nil)

    TriggerClientEvent("motel:client:roomUpdated", -1, motel.id, {
        id = room.id,
        roomNumber = room.roomNumber,
        doorlockIds = room.doorlockIds,
        iconOffsets = room.iconOffsets,
        chestCoords = room.chestCoords,
    })

    return { success = true, message = "Chambre modifiee." }
end)

RegisterServerCallback("motel:server:staff:getMotelLogs", function(source, motelId)
    if not requireMotelAdmin(source) then return {} end

    local rows = MySQL.query.await("SELECT * FROM motel_logs WHERE motel_id = ? ORDER BY id DESC LIMIT 100", { PS.ToInt(motelId) or 0 }) or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            id = rows[i].id,
            action = rows[i].action,
            room_label = rows[i].room_label,
            player_name = rows[i].player_name,
            details = rows[i].details,
            created_at_formatted = PS.FormatDateTime(rows[i].created_at),
        }
    end
    return out
end)

RegisterServerCallback("motel:server:staff:deleteLog", function(source, logId)
    if not requireMotelAdmin(source) then return { success = false, message = "Permission refusee." } end
    local lid = PS.ToInt(logId)
    if not lid then return { success = false, message = "Cet enregistrement n'est pas valide." } end
    MySQL.update.await("DELETE FROM motel_logs WHERE id = ?", { lid })
    return { success = true, message = "Log supprime." }
end)

RegisterNetEvent("motel:server:admin:createMotel", function(data)
    local source = source
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local name = PS.SafeString(data.name, 64)
    local npcCoords = PS.ReadVec3(data.npcCoords)
    if not name or not npcCoords then return end
    npcCoords.h = PS.ToNumber(data.npcCoords.h) or PS.ToNumber(data.npcCoords.w) or 0.0

    local id = MySQL.insert.await([[
        INSERT INTO motels (name, price_per_hour, duplicate_key_price, npc_model, npc_coords, blip_enabled, blip_sprite, blip_color, chest_max_weight, chest_max_slots, promotions)
        VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?)
    ]], {
        name,
        PS.ToInt(data.pricePerHour) or 500,
        PS.ToInt(data.duplicateKeyPrice) or 0,
        PS.SafeString(data.npcModel, 48) or "s_f_y_shop_mid",
        PS.Encode(npcCoords),
        PS.ToInt(data.blipSprite) or 475,
        PS.ToInt(data.blipColor) or 5,
        PS.ToInt(data.chestMaxWeight) or 50,
        PS.ToInt(data.chestMaxSlots) or 20,
        encodePromotions(data.promotions),
    })

    if not id then return end

    PS.LoadMotels()
    local motel = PS.Motels[id]
    if motel then
        TriggerClientEvent("motel:client:motelCreated", -1, {
            id = motel.id,
            name = motel.name,
            npcModel = motel.npcModel,
            npcCoords = motel.npcCoords,
            blipEnabled = motel.blipEnabled,
            blipSprite = motel.blipSprite,
            blipColor = motel.blipColor,
            pricePerHour = motel.pricePerHour,
            duplicateKeyPrice = motel.duplicateKeyPrice,
            chestMaxWeight = motel.chestMaxWeight,
            chestMaxSlots = motel.chestMaxSlots,
            promotions = motel.promotions,
            roomCount = 0,
        })
    end

    PS.MotelLog(id, nil, nil, "admin_create", xPlayer.name, name)
end)

RegisterNetEvent("motel:server:admin:updateMotel", function(data)
    local source = source
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local motel = PS.Motels[PS.ToInt(data.id) or 0]
    if not motel then return end

    local npcCoords = PS.ReadVec3(data.npcCoords) or motel.npcCoords
    if type(data.npcCoords) == "table" then
        npcCoords.h = PS.ToNumber(data.npcCoords.h) or PS.ToNumber(data.npcCoords.w) or npcCoords.h or 0.0
    end

    MySQL.update.await([[
        UPDATE motels SET name = ?, price_per_hour = ?, duplicate_key_price = ?, npc_model = ?, npc_coords = ?,
        blip_enabled = ?, blip_sprite = ?, blip_color = ?, chest_max_weight = ?, chest_max_slots = ?, promotions = ?
        WHERE id = ?
    ]], {
        PS.SafeString(data.name, 64) or motel.name,
        PS.ToInt(data.pricePerHour) or motel.pricePerHour,
        PS.ToInt(data.duplicateKeyPrice) or 0,
        PS.SafeString(data.npcModel, 48) or motel.npcModel,
        PS.Encode(npcCoords),
        data.blipEnabled ~= false and 1 or 0,
        PS.ToInt(data.blipSprite) or motel.blipSprite,
        PS.ToInt(data.blipColor) or motel.blipColor,
        PS.ToInt(data.chestMaxWeight) or 50,
        PS.ToInt(data.chestMaxSlots) or 20,
        encodePromotions(data.promotions),
        motel.id,
    })

    PS.LoadMotels()
    local updated = PS.Motels[motel.id]
    if updated then
        TriggerClientEvent("motel:client:motelUpdated", -1, {
            id = updated.id,
            name = updated.name,
            npcModel = updated.npcModel,
            npcCoords = updated.npcCoords,
            blipEnabled = updated.blipEnabled,
            blipSprite = updated.blipSprite,
            blipColor = updated.blipColor,
            pricePerHour = updated.pricePerHour,
            duplicateKeyPrice = updated.duplicateKeyPrice,
            chestMaxWeight = updated.chestMaxWeight,
            chestMaxSlots = updated.chestMaxSlots,
            promotions = updated.promotions,
            roomCount = #updated.rooms,
        })
    end

    PS.MotelLog(motel.id, nil, nil, "admin_update", xPlayer.name, nil)
end)

RegisterNetEvent("motel:server:admin:deleteMotel", function(motelId)
    local source = source
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return end

    local motel = PS.Motels[PS.ToInt(motelId) or 0]
    if not motel then return end

    for i = 1, #motel.rooms do
        MySQL.update.await("DELETE FROM motel_rentals WHERE room_id = ?", { motel.rooms[i].id })
    end

    MySQL.update.await("DELETE FROM motel_rooms WHERE motel_id = ?", { motel.id })
    MySQL.update.await("DELETE FROM motels WHERE id = ?", { motel.id })

    PS.MotelLog(motel.id, nil, nil, "admin_delete", xPlayer.name, motel.name)
    PS.LoadMotels()
    TriggerClientEvent("motel:client:motelDeleted", -1, motel.id)
end)

RegisterNetEvent("motel:server:admin:addRoom", function(data)
    local source = source
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local motel = PS.Motels[PS.ToInt(data.motelId) or 0]
    if not motel then return end

    local roomNumber = PS.ToInt(data.roomNumber)
    local label = PS.SafeString(data.label, 64)
    if not roomNumber or not label then return end

    local doorlockIds = {}
    if type(data.doorlockIds) == "table" then
        for i = 1, #data.doorlockIds do
            local dlId = PS.ToInt(data.doorlockIds[i])
            if dlId then doorlockIds[#doorlockIds + 1] = dlId end
        end
    end

    if type(data.pendingDoors) == "table" then
        for i = 1, #data.pendingDoors do
            local door = data.pendingDoors[i]
            local coords = PS.ReadVec3(door and door.coords)
            local model = PS.ToInt(door and door.model)
            if coords and model then
                local newId = PS.CreateDoorlock(("Motel - %s"):format(label), 2.0, coords, {
                    { model = model, coords = coords, heading = PS.ToNumber(door.heading) or 0.0 },
                }, nil, nil)
                if newId then doorlockIds[#doorlockIds + 1] = newId end
            end
        end
    end

    local iconOffsets = nil
    if type(data.iconOffsets) == "table" then
        iconOffsets = {}
        for key, value in pairs(data.iconOffsets) do
            local offset = PS.ReadVec3(value)
            local dlId = PS.ToInt(key)
            if offset and dlId then
                iconOffsets[tostring(dlId)] = offset
            end
        end
        if not next(iconOffsets) then iconOffsets = nil end
    end

    local chestCoords = PS.ReadVec3(data.chestCoords)

    local roomId = MySQL.insert.await([[
        INSERT INTO motel_rooms (motel_id, room_number, label, price_override, doorlock_ids, icon_offsets, chest_coords, promotions)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        motel.id, roomNumber, label,
        PS.ToInt(data.priceOverride),
        PS.Encode(doorlockIds),
        iconOffsets and PS.Encode(iconOffsets) or nil,
        chestCoords and PS.Encode(chestCoords) or nil,
        encodePromotions(data.promotions),
    })

    if not roomId then return end

    PS.LoadMotels()
    PS.MotelLog(motel.id, roomId, label, "admin_room_add", xPlayer.name, nil)

    TriggerClientEvent("motel:client:roomAdded", -1, motel.id, {
        id = roomId,
        roomNumber = roomNumber,
        doorlockIds = doorlockIds,
        iconOffsets = iconOffsets,
        chestCoords = chestCoords,
    })
end)

RegisterNetEvent("motel:server:admin:removeRoom", function(roomId)
    local source = source
    local xPlayer = requireMotelAdmin(source)
    if not xPlayer then return end

    local room = PS.Rooms[PS.ToInt(roomId) or 0]
    if not room then return end

    local motel = PS.Motels[room.motelId]
    local rental = getRental(room.id)
    if rental then
        endRental(room, motel, rental, "admin_room_remove")
    end

    MySQL.update.await("DELETE FROM motel_rooms WHERE id = ?", { room.id })
    PS.MotelLog(room.motelId, room.id, room.label, "admin_room_remove", xPlayer.name, nil)

    local doorlockIds = room.doorlockIds
    PS.LoadMotels()
    TriggerClientEvent("motel:client:roomRemoved", -1, room.motelId, room.id, doorlockIds)
end)

CreateThread(function()
    while true do
        Wait(60000)
        local now = PS.Now()
        local expired = MySQL.query.await("SELECT * FROM motel_rentals WHERE expire_at > 0 AND expire_at < ?", { now }) or {}
        for i = 1, #expired do
            local room = PS.Rooms[expired[i].room_id]
            if room then
                local motel = PS.Motels[room.motelId]
                endRental(room, motel, expired[i], "expired")
                TriggerClientEvent("motel:client:rentalExpired", -1, room.motelId)
            else
                MySQL.update.await("DELETE FROM motel_rentals WHERE id = ?", { expired[i].id })
            end
        end

        MySQL.update("DELETE FROM motel_storage WHERE expires_at > 0 AND expires_at < ?", { now })
    end
end)

MySQL.ready(function()
    PS.LoadMotels()
end)
