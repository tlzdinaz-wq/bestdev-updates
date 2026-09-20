local PS = VFW.PropertyServer

local pendingBells = {}

local function canPerquisition(xPlayer)
    if not xPlayer then return false end
    if xPlayer.hasPermission("perquisition") then return true end
    return PS.IsStaff(xPlayer)
end

local function rentalDays(row)
    if not row or row.contract_type ~= "rent" then return 0 end
    local remaining = (row.rental_expire or 0) - PS.Now()
    if remaining <= 0 then return 0 end
    return math.ceil(remaining / 86400)
end

local function buildCoOwnerList(row)
    local list = PS.GetAccess(row.id)
    local out = {}
    for i = 1, #list do
        out[#out + 1] = {
            id = list[i].id,
            name = PS.GetCharacterName(list[i].identifier) or "Inconnu",
            face = PS.GetCharacterFace(list[i].identifier),
            hide = list[i].hide,
        }
    end
    return out
end

function PS.EnterProperty(source, row)
    if not row then return nil end
    local bucket = PS.PrepareBucket(row.id)
    SetPlayerRoutingBucket(source, bucket)
    PS.SetOccupant(source, row.id)
    local xPlayer = VFW.GetPlayerFromId(source)
    PS.Log(row.id, "enter", xPlayer, row.property_name)
    return PS.BuildEnterTable(row)
end

function PS.LeaveProperty(source, propertyId)
    local row = PS.GetProperty(propertyId)
    PS.ClearOccupant(source)
    SetPlayerRoutingBucket(source, 0)

    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer and row then
        local pos = PS.PropertyPos(row)
        xPlayer.setCoords({ x = pos.x, y = pos.y, z = pos.z + 0.5, heading = pos.w or 0.0 })
        PS.Log(row.id, "leave", xPlayer, row.property_name)
    end

    if row and not next(PS.Occupants[row.id] or {}) then
        PS.DespawnAllGarageVehicles(row.id)
    end
end

RegisterServerCallback("vfw:getProperty", function(source, id)
    local row = PS.GetProperty(id)
    if not row then return nil end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local canManage = PS.CanManageCached(source, row.id)
    local isLocked = true
    if canManage or row.is_perquisitioned or row.access == "ouvert" then
        isLocked = false
    end

    local ownerIdentifier = select(2, PS.ParseOwner(row.owner))

    return {
        name = row.name,
        owner = PS.OwnerDisplay(row),
        playerFace = PS.GetCharacterFace(ownerIdentifier),
        hideIdentity = not canManage,
        isLocked = isLocked,
        canPerqui = canPerquisition(xPlayer),
        isPerquisitioned = row.is_perquisitioned and true or false,
    }
end)

RegisterServerCallback("vfw:property:canManage", function(source, id)
    return PS.CanManageCached(source, id) and true or false
end)

RegisterServerCallback("vfw:property:enter", function(source, id)
    local row = PS.GetProperty(id)
    if not row then return nil end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local allowed = PS.CanManageCached(source, row.id) or row.access == "ouvert" or row.is_perquisitioned
    if not allowed then return nil end

    return PS.EnterProperty(source, row)
end)

RegisterServerCallback("vfw:property:perquis", function(source, id)
    local row = PS.GetProperty(id)
    if not row then return false, false end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not canPerquisition(xPlayer) then
        return false, false
    end

    return true, row.is_perquisitioned and true or false
end)

RegisterServerCallback("vfw:property:getGestion", function(source, id)
    local row = PS.GetProperty(id)
    if not row then return nil end
    if not PS.CanManageCached(source, row.id) then return nil end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local kind, value = PS.ParseOwner(row.owner)

    return {
        name = row.name,
        isRental = row.contract_type == "rent",
        rentalDays = rentalDays(row),
        rentPrice = row.rent_price or 0,
        isOwner = PS.IsOwner(xPlayer, row),
        ownerType = kind,
        owner = {
            name = PS.OwnerDisplay(row),
            face = (kind == "citizen") and PS.GetCharacterFace(value) or "",
        },
        coOwnerList = buildCoOwnerList(row),
    }
end)

RegisterServerCallback("vfw:property:get", function(source, id)
    local row = PS.GetProperty(id)
    if not row then return nil end
    if not PS.CanManageCached(source, row.id) then return nil end

    return {
        nameProperty = row.property_name,
        name = row.name,
        type = row.type,
        rental = rentalDays(row),
        access = row.access,
        coOwnerList = buildCoOwnerList(row),
    }
end)

RegisterServerCallback("vfw:property:payRent", function(source, id, weeks, paymentMethod)
    local row = PS.GetProperty(id)
    if not row then return false, "Propriete introuvable." end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable." end
    if not PS.CanManageCached(source, row.id) then return false, "Vous n'avez pas acces a cette propriete." end
    if row.contract_type ~= "rent" then return false, "Cette propriete n'est pas en location." end

    local nWeeks = PS.ToInt(weeks)
    if not nWeeks or nWeeks < 1 or nWeeks > 4 then
        return false, "Ce nombre de semaines n'est pas valide."
    end

    local method = paymentMethod
    if method ~= "bank" and method ~= "cash" and method ~= "combined" then
        method = "bank"
    end

    local total = (row.rent_price or 0) * nWeeks
    if total < 0 then total = 0 end

    if not PS.TakeMoney(xPlayer, total, method) then
        return false, "Fonds insuffisants."
    end

    local base = math.max(row.rental_expire or 0, PS.Now())
    row.rental_expire = base + (nWeeks * 7 * 86400)
    MySQL.update("UPDATE properties SET rental_expire = ? WHERE id = ?", { row.rental_expire, row.id })
    PS.Log(row.id, "pay_rent", xPlayer, ("%d semaine(s) - %d"):format(nWeeks, total))

    return true, rentalDays(row)
end)

RegisterServerCallback("dynasty:getPlayerName", function(source, serverId)
    local target = VFW.GetPlayerFromId(PS.ToInt(serverId))
    if not target then return nil end
    return target.name
end)

RegisterServerCallback("core:server:vestiaireCheckAccess", function(source, propertyName)
    local row = PS.GetProperty(propertyName)
    if row then
        return PS.CanManageCached(source, row.id) and true or false
    end

    if type(propertyName) ~= "string" then return false end
    for id, prop in pairs(PS.Properties) do
        if prop.property_name == propertyName or prop.name == propertyName then
            return PS.CanManageCached(source, id) and true or false
        end
    end
    return false
end)

RegisterNetEvent("vfw:property:giveAccess", function(targetServerId, propertyId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanManage(source, row.id) then return end

    local targetId = PS.ToInt(targetServerId)
    if not targetId then return end

    local target = VFW.GetPlayerFromId(targetId)
    if not target or target.source == source then return end

    local a, b = xPlayer.getCoords(), target.getCoords()
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    if (dx * dx + dy * dy + dz * dz) > 900.0 then
        xPlayer.showNotification({ type = "ROUGE", content = "La personne est trop loin." })
        return
    end

    if PS.IsOwner(target, row) or PS.HasKey(target, row) then
        xPlayer.showNotification({ type = "ROUGE", content = "Cette personne a deja acces." })
        return
    end

    MySQL.insert.await("INSERT IGNORE INTO property_access (property_id, identifier, hide_identity, granted_at) VALUES (?, ?, 0, ?)", {
        row.id, target.identifier, PS.Now(),
    })

    PS.LoadAccess(row.id)
    PS.InvalidateManageCache(row.id)
    PS.Log(row.id, "give_access", xPlayer, target.name)

    xPlayer.showNotification({ type = "VERT", content = ("Cle remise a %s."):format(target.name) })
    target.showNotification({ type = "VERT", content = ("Vous avez recu une cle : %s."):format(row.name) })
    PS.PushBlips(target.source)
end)

RegisterNetEvent("vfw:property:removeAccess", function(propertyId, accessId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanManage(source, row.id) then return end

    local aid = PS.ToInt(accessId)
    if not aid then return end

    local entry
    local list = PS.GetAccess(row.id)
    for i = 1, #list do
        if list[i].id == aid then
            entry = list[i]
            break
        end
    end
    if not entry then return end

    MySQL.update.await("DELETE FROM property_access WHERE id = ? AND property_id = ?", { aid, row.id })
    PS.LoadAccess(row.id)
    PS.InvalidateManageCache(row.id)
    PS.Log(row.id, "remove_access", xPlayer, entry.identifier)

    local removed = VFW.GetPlayerFromIdentifier(entry.identifier)
    if removed then
        removed.showNotification({ type = "ROUGE", content = ("Votre acces a %s a ete retire."):format(row.name) })
        PS.PushBlips(removed.source)
    end
end)

RegisterNetEvent("vfw:property:bell", function(propertyId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end

    if pendingBells[source] then return end

    local targets = {}
    local seen = {}
    for _, src in ipairs(PS.GetOccupants(row.id)) do
        if not seen[src] then
            seen[src] = true
            targets[#targets + 1] = src
        end
    end
    for _, other in pairs(VFW.Players) do
        if not seen[other.source] and other.source ~= source then
            if PS.IsOwner(other, row) or PS.HasKey(other, row) then
                seen[other.source] = true
                targets[#targets + 1] = other.source
            end
        end
    end

    if #targets == 0 then
        TriggerClientEvent("vfw:property:reject", source)
        return
    end

    pendingBells[source] = { propertyId = row.id, at = PS.Now() }

    for i = 1, #targets do
        TriggerClientEvent("vfw:property:bell", targets[i], row.id, source, row.name)
    end

    SetTimeout(30000, function()
        if pendingBells[source] then
            pendingBells[source] = nil
            TriggerClientEvent("vfw:property:reject", source)
        end
    end)
end)

RegisterNetEvent("vfw:property:accept", function(targetId, propertyId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanManage(source, row.id) then return end

    local ringer = PS.ToInt(targetId)
    if not ringer then return end

    local target = VFW.GetPlayerFromId(ringer)
    if not target then return end
    if not pendingBells[ringer] or pendingBells[ringer].propertyId ~= row.id then return end

    pendingBells[ringer] = nil

    local payload = PS.EnterProperty(ringer, row)
    TriggerClientEvent("vfw:property:accept", ringer, payload)
end)

RegisterNetEvent("vfw:property:reject", function(targetId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local ringer = PS.ToInt(targetId)
    if not ringer then return end
    if not pendingBells[ringer] then return end

    pendingBells[ringer] = nil
    TriggerClientEvent("vfw:property:reject", ringer)
end)

RegisterNetEvent("vfw:property:perquisition", function(propertyId, newState)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(newState) ~= "boolean" then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not canPerquisition(xPlayer) then return end

    row.is_perquisitioned = newState
    MySQL.update("UPDATE properties SET is_perquisitioned = ? WHERE id = ?", { newState and 1 or 0, row.id })
    PS.Log(row.id, "perquisition", xPlayer, newState and "ouverte" or "reverrouillee")

    xPlayer.showNotification({
        type = "VERT",
        content = newState and "La porte a ete forcee." or "La porte a ete reverrouillee.",
    })
end)

RegisterNetEvent("vfw:leaveProperty", function(propertyId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    PS.LeaveProperty(source, propertyId)
end)

RegisterNetEvent("vfw:property:save", function(propertyId, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanManage(source, row.id) then return end

    local newName = PS.SafeString(data.name, 64)
    if newName then
        row.name = newName
    end

    if PS.IsAccessMode(data.access) then
        row.access = data.access
    end

    MySQL.update("UPDATE properties SET name = ?, access = ? WHERE id = ?", { row.name, row.access, row.id })

    if type(data.deletedOwner) == "table" then
        for i = 1, #data.deletedOwner do
            local aid = PS.ToInt(data.deletedOwner[i])
            if aid then
                MySQL.update.await("DELETE FROM property_access WHERE id = ? AND property_id = ?", { aid, row.id })
            end
        end
        PS.LoadAccess(row.id)
        PS.InvalidateManageCache(row.id)
    end

    PS.Log(row.id, "edit", xPlayer, row.name)
    PS.RefreshAllBlips()
end)

VFW.RegisterCommand("forceleaveproperty", "forceleaveproperty", function(source, xPlayer, args)
    local targetId = PS.ToInt(args[1])
    if not targetId then return end
    local target = VFW.GetPlayerFromId(targetId)
    if not target then return end
    local propertyId = PS.PlayerProperty[target.source]
    if not propertyId then return end
    PS.LeaveProperty(target.source, propertyId)
end, {
    help = "Forcer un joueur a quitter une propriete",
    params = { { name = "id", help = "ID du joueur" } },
})

AddEventHandler("vfw:playerLoaded", function(source)
    PS.ClearOccupant(source)
    SetPlayerRoutingBucket(source, 0)
    PS.PushProperties(source)
    PS.PushBlips(source)
end)
