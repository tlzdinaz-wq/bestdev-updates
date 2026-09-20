local PS = VFW.PropertyServer

local TYPE_TO_INDEX = {
    ["Habitation"] = 1,
    ["Garage"] = 2,
    ["Stockage"] = 3,
}

local function requireDeletedAdmin(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission("manage_deleted_properties") and not PS.IsStaff(xPlayer) then return nil end
    return xPlayer
end

local function requireLogsAdmin(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission("view_property_logs") and not PS.IsStaff(xPlayer) then return nil end
    return xPlayer
end

RegisterServerCallback("staff:getDeletedProperties", function(source)
    if not requireDeletedAdmin(source) then return {} end

    local rows = MySQL.query.await("SELECT * FROM properties_deleted ORDER BY id DESC LIMIT 200") or {}
    local out = {}

    for i = 1, #rows do
        local items = PS.Decode(rows[i].chest_data, {}) or {}
        local totalWeight = 0
        for j = 1, #items do
            local def = VFW.Items[items[j].name]
            local weight = items[j].weight or (def and def.weight) or 0
            totalWeight = totalWeight + (weight * (items[j].count or 1))
        end

        out[#out + 1] = {
            id = rows[i].id,
            property_id = rows[i].property_id,
            name = rows[i].name,
            type = TYPE_TO_INDEX[rows[i].type] or rows[i].type,
            chest_data = rows[i].chest_data,
            chest_totalWeight = totalWeight,
            chest_maxWeight = rows[i].chest_max_weight or 0,
            delete_reason = rows[i].delete_reason,
            deleted_at_formatted = PS.FormatDateTime(rows[i].deleted_at),
        }
    end

    return out
end)

RegisterServerCallback("staff:restoreProperty", function(source, archiveId)
    local xPlayer = requireDeletedAdmin(source)
    if not xPlayer then return { success = false, message = "Permission refusee." } end

    local aid = PS.ToInt(archiveId)
    if not aid then return { success = false, message = "Cette archive n'est pas valide." } end

    local row = MySQL.single.await("SELECT * FROM properties_deleted WHERE id = ?", { aid })
    if not row then return { success = false, message = "Archive introuvable." } end

    local payload = PS.Decode(row.payload, nil)
    if type(payload) ~= "table" then return { success = false, message = "Donnees corrompues." } end

    local newId = MySQL.insert.await([[
        INSERT INTO properties
        (name, property_name, property_key, type, category, owner, access, pos, vehicle_pos, max_places,
         deco, is_perquisitioned, contract_type, total_price, rent_price, rental_expire, dynasty_society, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.name or "Propriete",
        payload.property_name or "",
        payload.property_key or "",
        payload.type or "Habitation",
        payload.category or "Appartement",
        payload.owner or "",
        PS.IsAccessMode(payload.access) and payload.access or "fermer",
        PS.Encode(payload.pos or { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }),
        payload.vehicle_pos and PS.Encode(payload.vehicle_pos) or nil,
        payload.max_places,
        payload.deco and PS.Encode(payload.deco) or nil,
        payload.contract_type or "sale",
        payload.total_price or 0,
        payload.rent_price or 0,
        payload.rental_expire or 0,
        payload.dynasty_society,
        payload.created_at or PS.Now(),
    })

    if not newId then return { success = false, message = "Echec de la restauration." } end

    local items = PS.Decode(row.chest_data, {}) or {}
    if #items > 0 then
        pcall(function()
            for i = 1, #items do
                MySQL.insert.await("INSERT INTO chest_items (chest_id, slot, name, count, meta) VALUES (?, ?, ?, ?, ?)", {
                    ("property:%d"):format(newId), i, items[i].name, items[i].count or 1, nil,
                })
            end
        end)
    end

    MySQL.update.await("DELETE FROM properties_deleted WHERE id = ?", { aid })

    PS.LoadProperties()
    local restored = PS.Properties[newId]
    if restored then
        TriggerClientEvent("vfw:loadProperty", -1, newId, PS.PropertyPos(restored), restored.type, restored.vehicle_pos)
    end
    PS.RefreshAllBlips()

    return { success = true, message = ("Propriete restauree (#%d)."):format(newId) }
end)

RegisterServerCallback("staff:permanentDeleteProperty", function(source, archiveId)
    local xPlayer = requireDeletedAdmin(source)
    if not xPlayer then return { success = false, message = "Permission refusee." } end

    local aid = PS.ToInt(archiveId)
    if not aid then return { success = false, message = "Cette archive n'est pas valide." } end

    MySQL.update.await("DELETE FROM properties_deleted WHERE id = ?", { aid })
    return { success = true, message = "Archive supprimee definitivement." }
end)

RegisterServerCallback("staff:getPropertyLogs", function(source, propertyId)
    if not requireLogsAdmin(source) then return {} end

    local pid = PS.ToInt(propertyId)
    if not pid then return {} end

    local rows = MySQL.query.await("SELECT * FROM property_logs WHERE property_id = ? ORDER BY id DESC LIMIT 200", { pid }) or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            id = rows[i].id,
            action = rows[i].action,
            player_name = rows[i].player_name,
            details = rows[i].details,
            created_at_formatted = PS.FormatDateTime(rows[i].created_at),
        }
    end
    return out
end)

RegisterServerCallback("staff:getPropertiesWithLogs", function(source)
    if not requireLogsAdmin(source) then return {} end

    local rows = MySQL.query.await([[
        SELECT property_id, MAX(property_name) AS property_name, COUNT(*) AS log_count, MAX(created_at) AS last_activity
        FROM property_logs GROUP BY property_id ORDER BY last_activity DESC LIMIT 200
    ]]) or {}

    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            property_id = rows[i].property_id,
            property_name = rows[i].property_name,
            log_count = rows[i].log_count,
            last_activity_formatted = PS.FormatDateTime(rows[i].last_activity),
        }
    end
    return out
end)

VFW.RegisterCommand("tpproperty", "manage_property", function(source, xPlayer, args)
    local pid = PS.ToInt(args[1])
    if not pid then return end

    local row = PS.GetProperty(pid)
    if not row then
        xPlayer.showNotification({ type = "ROUGE", content = "Propriete introuvable." })
        return
    end

    local config = PS.GetPropertyConfig(row)
    if config and config.leave then
        local okHeading, heading = pcall(function() return config.leave.w end)
        xPlayer.setCoords({
            x = config.leave.x,
            y = config.leave.y,
            z = config.leave.z,
            heading = (okHeading and PS.ToNumber(heading)) or 0.0,
        })
    end

    local payload = PS.EnterProperty(source, row)
    TriggerClientEvent("vfw:property:forceEnter", source, row.id, payload)
end, {
    help = "Se teleporter dans une propriete",
    params = { { name = "id", help = "ID de la propriete" } },
})

VFW.RegisterCommand("propertyinfo", "manage_property", function(source, xPlayer, args)
    local pid = PS.ToInt(args[1])
    if not pid then return end
    local row = PS.GetProperty(pid)
    if not row then
        xPlayer.showNotification({ type = "ROUGE", content = "Propriete introuvable." })
        return
    end
    xPlayer.showNotification({
        type = "STAFF",
        variant = "INFO",
        subtitle = "Propriete #" .. pid,
        message = ("%s - %s - %s"):format(row.name, row.type, PS.OwnerDisplay(row)),
    })
end, {
    help = "Informations sur une propriete",
    params = { { name = "id", help = "ID de la propriete" } },
})
