MiscB.Cb("core:CheckInstance", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local bucket = GetPlayerRoutingBucket(source)
    if bucket and bucket ~= 0 then return false end
    return true
end)

MiscB.Cb("vfw:staff:getPlayerInfo", function(source, targetServerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission("staff_menu") then return nil end

    local target = tonumber(targetServerId)
    if not target then return nil end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return nil end

    local discord = xTarget.discordId
    if not discord then
        local identifiers = GetPlayerIdentifiers(target) or {}
        for i = 1, #identifiers do
            if identifiers[i]:sub(1, 8) == "discord:" then discord = identifiers[i]:sub(9) end
        end
        xTarget.discordId = discord
    end

    local playtime = 0
    if xTarget.globalData then
        playtime = tonumber(xTarget.globalData.playtime) or 0
    end
    if xTarget.sessionStart then
        playtime = playtime + math.max(0, os.time() - xTarget.sessionStart)
    end

    local job = xTarget.job
    local job2 = xTarget.job2
    local hours = math.floor(playtime / 3600)
    local minutes = math.floor((playtime % 3600) / 60)
    local seconds = playtime % 60

    return {
        id = xTarget.charId,
        charId = xTarget.charId,
        source = target,
        name = MiscB.CharName(xTarget),
        playerName = xTarget.playerName,
        pseudo = xTarget.playerName,
        firstName = xTarget.firstName,
        lastName = xTarget.lastName,
        identifier = xTarget.identifier,
        accountId = xTarget.accountId,
        discord = discord,
        job = MiscB.JobName(xTarget),
        jobName = job and job.name or "unemployed",
        jobFull = job and (job.label or job.name) or "Civil",
        grade = MiscB.GradeLevel(xTarget),
        faction = xTarget.faction,
        factionName = job2 and job2.name or nil,
        factionFull = job2 and (job2.label or job2.name) or "Civil",
        group = xTarget.group,
        vipTier = xTarget.vipTier,
        uuid = xTarget.uuid,
        dateOfBirth = xTarget.dateofbirth,
        height = xTarget.height,
        sex = xTarget.sex,
        instance = GetPlayerRoutingBucket(target) or 0,
        time = ("%02d:%02d:%02d"):format(hours, minutes, seconds),
        online = true,
    }
end)

MiscB.Cb("vfw:giveItemSpecific", function(source, targetServerId, itemName, count)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable." end

    local target = tonumber(targetServerId)
    local name = MiscB.Str(itemName, 64)
    local quantity = MiscB.ToInt(count, 1, 10000)
    if not target or not name or not quantity then return false, "Cette demande n'a pas pu être traitée." end
    if target == source then return false, "Cette cible n'est pas valide." end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return false, "Joueur introuvable." end
    if MiscB.Dist(xPlayer.getCoords(), xTarget.getCoords()) > 5.0 then
        return false, "La personne est trop loin."
    end
    if not MiscB.Rate(source, "giveitem", 500) then return false, "Trop rapide." end

    if not xPlayer.haveItem(name, quantity) then return false, "Vous n'avez pas assez de cet item." end
    if not xTarget.canCarryItem(name, quantity) then return false, "La personne ne peut pas porter autant." end

    if not xPlayer.removeInventoryItem(name, quantity) then return false, "Erreur d'inventaire." end
    xTarget.addInventoryItem(name, quantity)

    return true, xPlayer.inventory, xPlayer.getWeight()
end)

MiscB.Cb("vfw:giveMoneyType", function(source, targetServerId, moneyType, count)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, nil end

    local target = tonumber(targetServerId)
    local quantity = MiscB.ToInt(count, 1, 100000000)
    if not target or not quantity or target == source then return nil, nil end

    local account = "money"
    if moneyType == "dirty_money" or moneyType == "black_money" then account = "black_money" end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return nil, nil end
    if MiscB.Dist(xPlayer.getCoords(), xTarget.getCoords()) > 5.0 then return nil, nil end
    if not MiscB.Rate(source, "givemoney", 500) then return nil, nil end

    local current = xPlayer.getAccount(account)
    local balance = type(current) == "table" and (current.money or current.amount or 0) or (tonumber(current) or 0)
    if balance < quantity then return nil, nil end

    xPlayer.removeAccountMoney(account, quantity, "don-joueur")
    xTarget.addAccountMoney(account, quantity, "don-joueur")

    return xPlayer.inventory, xPlayer.getWeight()
end)

local CAYO_VISA_JOBS = { "gouvernement", "gouvernement_cayo", "gouv", "mairie", "milice", "milicecayo" }

local function cayoStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not MiscB.HasJob(xPlayer, CAYO_VISA_JOBS) then return nil end
    return xPlayer
end

local function visaRow(identifier)
    return MiscB.Single(
        "SELECT identifier, granted_by, granted_at, expires_at FROM cayo_visas WHERE identifier = ? LIMIT 1",
        { identifier }
    )
end

local function visaValid(row)
    if not row then return false end
    if row.expires_at == nil or row.expires_at == 0 then return true end
    return tonumber(row.expires_at) > os.time()
end

MiscB.Cb("cayo_visa:checkTarget", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { hasVisa = false } end
    if type(data) ~= "table" then return { hasVisa = false } end

    local target = tonumber(data.targetServerId)
    if not target then return { hasVisa = false } end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return { hasVisa = false } end

    return { hasVisa = visaValid(visaRow(xTarget.identifier)) }
end)

MiscB.Cb("cayo_visa:grant", function(source, data)
    local xPlayer = cayoStaff(source)
    if not xPlayer then return { success = false, message = "Vous n'avez pas les droits." } end
    if type(data) ~= "table" then return { success = false, message = "Cette demande n'a pas pu être traitée." } end

    local target = tonumber(data.targetServerId)
    if not target then return { success = false, message = "Cette cible n'est pas valide." } end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return { success = false, message = "Joueur introuvable." } end

    local duration = MiscB.ToInt(data.days, 1, 365) or 30
    local expires = os.time() + duration * 86400

    MiscB.Update([[
        INSERT INTO cayo_visas (identifier, granted_by, granted_at, expires_at)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE granted_by = VALUES(granted_by), granted_at = VALUES(granted_at), expires_at = VALUES(expires_at)
    ]], { xTarget.identifier, MiscB.CharName(xPlayer), os.time(), expires })

    xTarget.setMeta("cayoVisa", expires)
    VFW.ShowNotification(target, { type = "VERT", content = "Un visa pour Cayo Perico vous a ete delivre." })

    return { success = true, message = "Visa delivre." }
end)

MiscB.Cb("cayo_visa:revoke", function(source, data)
    local xPlayer = cayoStaff(source)
    if not xPlayer then return { success = false, message = "Vous n'avez pas les droits." } end
    if type(data) ~= "table" then return { success = false, message = "Cette demande n'a pas pu être traitée." } end

    local target = tonumber(data.targetServerId)
    if not target then return { success = false, message = "Cette cible n'est pas valide." } end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return { success = false, message = "Joueur introuvable." } end

    MiscB.Update("DELETE FROM cayo_visas WHERE identifier = ?", { xTarget.identifier })
    xTarget.setMeta("cayoVisa", 0)
    VFW.ShowNotification(target, { type = "ROUGE", content = "Votre visa pour Cayo Perico a ete retire." })

    return { success = true, message = "Visa retire." }
end)

MiscB.Cb("cayo_visa:milice:listVisaCitizens", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if not MiscB.HasJob(xPlayer, CAYO_VISA_JOBS) and not MiscB.IsLawEnforcement(xPlayer) then return {} end

    local rows = MiscB.Query([[
        SELECT v.identifier, v.granted_by, v.granted_at, v.expires_at, c.firstname, c.lastname
        FROM cayo_visas v LEFT JOIN characters c ON c.identifier = v.identifier
        ORDER BY v.expires_at DESC LIMIT 300
    ]], {})

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
        rows[i].active = visaValid(rows[i])
    end
    return rows
end)

MiscB.Cb("cayo_visa:milice:updateExpiration", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end
    if not MiscB.HasJob(xPlayer, CAYO_VISA_JOBS) and not MiscB.IsLawEnforcement(xPlayer) then
        return { success = false, message = "Vous n'avez pas les droits." }
    end
    if type(data) ~= "table" then return { success = false } end

    local identifier = MiscB.Str(data.identifier, 80)
    local days = MiscB.ToInt(data.days, 0, 3650)
    if not identifier or days == nil then return { success = false } end

    local expires = days > 0 and (os.time() + days * 86400) or 0
    MiscB.Update("UPDATE cayo_visas SET expires_at = ? WHERE identifier = ?", { expires, identifier })

    local xTarget = VFW.GetPlayerFromIdentifier(identifier)
    if xTarget then xTarget.setMeta("cayoVisa", expires) end

    return { success = true }
end)

local function dynastyAgent(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not MiscB.HasJob(xPlayer, { "dynasty", "dynasty8", "immobilier", "realestate" }) then return nil end
    return xPlayer
end

local function propertyRow(propertyId)
    local id = MiscB.ToInt(propertyId, 1)
    if not id then return nil end
    return MiscB.Single("SELECT * FROM properties WHERE id = ? LIMIT 1", { id })
end

MiscB.Cb("vfw:job:dynasty:getProperty", function(source, propertyId)
    local xPlayer = dynastyAgent(source)
    if not xPlayer then return nil end

    local row = propertyRow(propertyId)
    if not row then return nil end

    row.pos = VFW.DB.Decode(row.pos, {})
    row.vehicle_pos = VFW.DB.Decode(row.vehicle_pos, nil)
    row.deco = nil

    local owner = MiscB.Single(
        "SELECT firstname, lastname FROM characters WHERE identifier = ? LIMIT 1",
        { row.owner }
    )
    row.ownerName = owner and ("%s %s"):format(owner.firstname or "", owner.lastname or "") or nil
    return row
end)

MiscB.Cb("vfw:job:dynasty:coowner", function(source, propertyId)
    local xPlayer = dynastyAgent(source)
    if not xPlayer then return nil end

    local row = propertyRow(propertyId)
    if not row then return nil end

    local access = MiscB.Query([[
        SELECT a.id, a.identifier, c.firstname, c.lastname FROM property_access a
        LEFT JOIN characters c ON c.identifier = a.identifier
        WHERE a.property_id = ? LIMIT 100
    ]], { row.id })

    for i = 1, #access do
        access[i].name = ("%s %s"):format(access[i].firstname or "", access[i].lastname or "")
    end

    return { id = row.id, name = row.name, owner = row.owner, access = access }
end)

MiscB.Cb("vfw:job:dynasty:propertyUpdate", function(source, propertyId, data)
    local xPlayer = dynastyAgent(source)
    if not xPlayer then return false end

    local row = propertyRow(propertyId)
    if not row or type(data) ~= "table" then return false end

    MiscB.Update([[
        UPDATE properties SET name = ?, category = ?, contract_type = ?, total_price = ?, rent_price = ?, max_places = ?
        WHERE id = ?
    ]], {
        MiscB.Str(data.name, 64) or row.name,
        MiscB.Str(data.category, 16) or row.category,
        MiscB.Str(data.contract_type or data.contractType, 8) or row.contract_type,
        MiscB.ToInt(data.total_price or data.totalPrice or data.price, 0, 1000000000) or row.total_price,
        MiscB.ToInt(data.rent_price or data.rentPrice, 0, 1000000000) or row.rent_price,
        MiscB.ToInt(data.max_places or data.maxPlaces, 0, 100) or row.max_places,
        row.id,
    })

    return true
end)

RegisterNetEvent("vfw:job:dynasty:createProperty", function(data)
    local source = source
    if type(data) ~= "table" then return end

    local xPlayer = dynastyAgent(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "dynastycreate", 2000) then return end

    local pos = MiscB.Plain(data.pos or data.coords)
    if not pos then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Cette position n'est pas valide." })
        return
    end

    local id = MiscB.Insert([[
        INSERT INTO properties (name, property_name, property_key, type, category, owner, access, pos,
            vehicle_pos, max_places, contract_type, total_price, rent_price, dynasty_society, created_at)
        VALUES (?, ?, ?, ?, ?, '', 'fermer', ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        MiscB.Str(data.name, 64) or "Propriete",
        MiscB.Str(data.property_name or data.propertyName, 64) or ("prop_" .. os.time()),
        MiscB.Str(data.property_key or data.propertyKey, 48) or "",
        MiscB.Str(data.type, 16) or "Habitation",
        MiscB.Str(data.category, 16) or "Appartement",
        VFW.DB.Encode(pos),
        data.vehicle_pos and VFW.DB.Encode(MiscB.Plain(data.vehicle_pos)) or nil,
        MiscB.ToInt(data.max_places or data.maxPlaces, 0, 100) or 4,
        MiscB.Str(data.contract_type or data.contractType, 8) or "sale",
        MiscB.ToInt(data.total_price or data.totalPrice or data.price, 0, 1000000000) or 0,
        MiscB.ToInt(data.rent_price or data.rentPrice, 0, 1000000000) or 0,
        MiscB.JobName(xPlayer),
        os.time(),
    })

    if id then
        VFW.ShowNotification(source, { type = "VERT", content = "Propriete creee." })
        TriggerClientEvent("vfw:property:refresh", -1)
    end
end)

RegisterNetEvent("vfw:job:dynasty:deleteProperty", function(propertyId)
    local source = source
    local xPlayer = dynastyAgent(source)
    if not xPlayer then return end

    local row = propertyRow(propertyId)
    if not row then return end

    MiscB.Insert([[
        INSERT INTO properties_deleted (property_id, name, type, payload, delete_reason, deleted_by, deleted_at)
        VALUES (?, ?, ?, ?, 'dynasty', ?, ?)
    ]], { row.id, row.name, row.type or "", VFW.DB.Encode(row), MiscB.CharName(xPlayer), os.time() })

    MiscB.Update("DELETE FROM property_access WHERE property_id = ?", { row.id })
    MiscB.Update("DELETE FROM properties WHERE id = ?", { row.id })

    VFW.ShowNotification(source, { type = "VERT", content = "Propriete supprimee." })
    TriggerClientEvent("vfw:property:refresh", -1)
end)

RegisterNetEvent("vfw:job:dynasty:transfert", function(propertyId, targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end

    local xPlayer = dynastyAgent(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    local row = propertyRow(propertyId)
    if not row then return end

    MiscB.Update("UPDATE properties SET owner = ? WHERE id = ?", { xTarget.identifier, row.id })
    MiscB.Update("DELETE FROM property_access WHERE property_id = ?", { row.id })

    VFW.ShowNotification(source, { type = "VERT", content = "Propriete transferee." })
    VFW.ShowNotification(target, { type = "VERT", content = "Vous etes desormais proprietaire d'un bien." })
    TriggerClientEvent("vfw:property:refresh", -1)
end)

RegisterNetEvent("vfw:job:dynasty:giveKey", function(propertyId, targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end

    local xPlayer = dynastyAgent(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    local row = propertyRow(propertyId)
    if not row then return end

    MiscB.Update([[
        INSERT INTO property_access (property_id, identifier, hide_identity, granted_at)
        VALUES (?, ?, 0, ?)
        ON DUPLICATE KEY UPDATE granted_at = VALUES(granted_at)
    ]], { row.id, xTarget.identifier, os.time() })

    VFW.ShowNotification(source, { type = "VERT", content = "Cle remise." })
    VFW.ShowNotification(target, { type = "VERT", content = "Vous avez recu une cle de propriete." })
end)

RegisterNetEvent("vfw:job:dynasty:save", function(idProperty, id)
    local source = source
    local xPlayer = dynastyAgent(source)
    if not xPlayer then return end

    local row = propertyRow(idProperty)
    if not row then return end

    local accessId = MiscB.ToInt(id, 1)
    if accessId then
        MiscB.Update("DELETE FROM property_access WHERE id = ? AND property_id = ?", { accessId, row.id })
        VFW.ShowNotification(source, { type = "VERT", content = "Acces retire." })
        return
    end

    VFW.ShowNotification(source, { type = "VERT", content = "Propriete sauvegardee." })
end)
