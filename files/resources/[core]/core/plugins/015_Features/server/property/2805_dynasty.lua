local PS = VFW.PropertyServer

local BOSS_GRADE = 98
local CONTRACT_ITEM = "dynasty_contract"

local CATEGORY_LABELS = {
    ["Appartement"] = "Habitations",
    ["Garage"] = "Garages",
    ["Entrepot"] = "Entrepots",
}

PS.Prices = {}
PS.Contracts = {}

local function pricesPayload()
    local payload = {}
    for category, entries in pairs(PS.Prices) do
        payload[category] = {}
        for key, value in pairs(entries) do
            payload[category][key] = {
                enabled = value.enabled,
                sell = value.sell,
                rentEnabled = value.rentEnabled,
                rent = value.rent,
            }
        end
    end
    return payload
end

function PS.LoadPrices()
    local rows = MySQL.query.await("SELECT * FROM dynasty_prices") or {}
    PS.Prices = {}
    for i = 1, #rows do
        local category = rows[i].category
        PS.Prices[category] = PS.Prices[category] or {}
        PS.Prices[category][rows[i].property_key] = {
            sell = rows[i].sell or 0,
            rent = rows[i].rent or 0,
            enabled = rows[i].enabled == 1,
            rentEnabled = rows[i].rent_enabled == 1,
        }
    end
end

function PS.PushPrices(source)
    TriggerClientEvent("dynastyPrices:syncConfig", source or -1, pricesPayload())
end

function PS.GetPrice(category, propertyKey)
    local entries = PS.Prices[category]
    if not entries then return nil end
    return entries[propertyKey]
end

function PS.FindConfigProperty(category, nameOrId)
    if not Property then return nil end
    local group = Property[category]
    if type(group) ~= "table" or type(group.data) ~= "table" then return nil end
    for i = 1, #group.data do
        local entry = group.data[i]
        if entry.name == nameOrId or entry.id == nameOrId then
            return entry
        end
    end
    return nil
end

local function propertyListEntry(row, withPos)
    local entry = {
        id = row.id,
        name = row.name,
        type = row.type,
        ownerName = PS.OwnerDisplay(row),
        dynastySociety = row.dynasty_society,
        totalPrice = row.total_price or 0,
        rentPrice = row.rent_price or 0,
        rental = row.contract_type == "rent" and (row.rental_expire or 0) or 0,
        createdAt = row.created_at or 0,
    }
    if withPos then
        entry.pos = PS.PropertyPos(row)
    end
    return entry
end

RegisterServerCallback("dynasty:getNearbyPlayersInfo", function(source, serverIds)
    if type(serverIds) ~= "table" then return {} end

    local out = {}
    for i = 1, #serverIds do
        local sid = PS.ToInt(serverIds[i])
        local target = sid and VFW.GetPlayerFromId(sid) or nil
        if target then
            out[#out + 1] = {
                serverId = target.source,
                name = target.name,
                job = target.job and { label = target.job.label, name = target.job.name, grade = target.job.grade } or nil,
                crew = (target.faction and target.faction ~= "") and { label = target.faction, name = target.faction } or nil,
            }
        end
    end
    return out
end)

RegisterServerCallback("dynasty:getSocietyProperties", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local society = xPlayer.job and xPlayer.job.name or ""
    local rows = {}
    for _, row in pairs(PS.Properties) do
        if row.dynasty_society == society then
            rows[#rows + 1] = row
        end
    end

    local out = {}
    for i = 1, #rows do
        out[#out + 1] = propertyListEntry(rows[i], true)
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

RegisterServerCallback("staff:getAllProperties", function(source, search)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if not PS.IsStaff(xPlayer) then return {} end

    local query = nil
    if type(search) == "string" and search ~= "" then
        query = search:lower()
    end

    local rows = {}
    for _, row in pairs(PS.Properties) do
        rows[#rows + 1] = row
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local keep = true
        if query then
            local haystack = ("%s %s %s %s"):format(
                tostring(row.id),
                tostring(row.name or ""),
                tostring(row.type or ""),
                tostring(PS.OwnerDisplay(row))
            ):lower()
            keep = haystack:find(query, 1, true) ~= nil
        end
        if keep then
            out[#out + 1] = propertyListEntry(row, true)
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

RegisterServerCallback("staff:showAllPropertyBlips", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not PS.IsStaff(xPlayer) then return {} end

    local out = {}
    for id, row in pairs(PS.Properties) do
        out[id] = {
            pos = PS.PropertyPos(row),
            type = row.type,
            name = row.name,
        }
    end
    return out
end)

RegisterServerCallback("dynasty:deleteProperty", function(source, propertyId, isStaff)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local row = PS.GetProperty(propertyId)
    if not row then return { success = false, message = "Propriete introuvable." } end

    local staffMode = isStaff == true and PS.IsStaff(xPlayer)
    if not staffMode then
        local society = xPlayer.job and xPlayer.job.name or ""
        if row.dynasty_society ~= society or (xPlayer.job.grade or 0) < BOSS_GRADE then
            return { success = false, message = "Vous n'avez pas l'autorisation." }
        end
    end

    local kind, value = PS.ParseOwner(row.owner)
    if kind == "citizen" and (row.total_price or 0) > 0 then
        local owner = VFW.GetPlayerFromIdentifier(value)
        if owner then
            PS.GiveMoney(owner, row.total_price, "bank")
        end
    end

    PS.DeleteProperty(row.id, staffMode and "staff" or "dynasty", xPlayer.name)
    return { success = true, message = "Propriete supprimee." }
end)

RegisterServerCallback("dynasty:extendRental", function(source, propertyId, weeks)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local row = PS.GetProperty(propertyId)
    if not row then return { success = false, message = "Propriete introuvable." } end
    if row.contract_type ~= "rent" then return { success = false, message = "Cette propriete n'est pas louee." } end

    local nWeeks = PS.ToInt(weeks)
    if not nWeeks or nWeeks < 1 or nWeeks > 52 then
        return { success = false, message = "Ce nombre de semaines n'est pas valide." }
    end

    local staffMode = PS.IsStaff(xPlayer)
    local isSociety = row.dynasty_society == (xPlayer.job and xPlayer.job.name or "")
    if not staffMode and not isSociety and not PS.IsOwner(xPlayer, row) then
        return { success = false, message = "Vous n'avez pas l'autorisation." }
    end

    local total = (row.rent_price or 0) * nWeeks
    if not staffMode then
        if not PS.TakeMoney(xPlayer, total, "combined") then
            return { success = false, message = "Fonds insuffisants." }
        end
    end

    local base = math.max(row.rental_expire or 0, PS.Now())
    row.rental_expire = base + (nWeeks * 7 * 86400)
    MySQL.update("UPDATE properties SET rental_expire = ? WHERE id = ?", { row.rental_expire, row.id })
    PS.Log(row.id, "pay_rent", xPlayer, ("prolongation %d semaine(s)"):format(nWeeks))

    return { success = true, message = ("Location prolongee de %d semaine%s."):format(nWeeks, nWeeks > 1 and "s" or "") }
end)

RegisterServerCallback("dynastyPrices:updatePrice", function(source, propId, categoryId, sell, rent, rentEnabled, enabled)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, error = "Joueur introuvable." } end
    if not xPlayer.hasPermission("manage_dynasty_prices") and not PS.IsStaff(xPlayer) then
        return { success = false, error = "Permission refusee." }
    end

    local key = PS.SafeString(propId, 48)
    local category = PS.NormalizeCategory(categoryId)
    if not key or not category then
        return { success = false, error = "Ces parametres ne sont pas valides." }
    end

    local nSell = PS.ToInt(sell) or 0
    local nRent = PS.ToInt(rent) or 0
    if nSell < 0 then nSell = 0 end
    if nRent < 0 then nRent = 0 end

    local bRent = rentEnabled == true
    local bEnabled = enabled == true

    MySQL.update.await([[
        INSERT INTO dynasty_prices (category, property_key, sell, rent, enabled, rent_enabled)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE sell = VALUES(sell), rent = VALUES(rent), enabled = VALUES(enabled), rent_enabled = VALUES(rent_enabled)
    ]], { category, key, nSell, nRent, bEnabled and 1 or 0, bRent and 1 or 0 })

    PS.Prices[category] = PS.Prices[category] or {}
    PS.Prices[category][key] = { sell = nSell, rent = nRent, enabled = bEnabled, rentEnabled = bRent }

    PS.PushPrices(-1)
    return { success = true }
end)

local function cancelContract(contractId, status, notifyBuyer)
    local contract = PS.Contracts[contractId]
    if not contract then return nil end
    PS.Contracts[contractId] = nil
    MySQL.update("UPDATE dynasty_contracts SET status = ? WHERE id = ?", { status, contractId })
    if notifyBuyer then
        local buyer = VFW.GetPlayerFromIdentifier(contract.buyer_identifier)
        if buyer then
            TriggerClientEvent("dynastyContract:cancelled", buyer.source)
        end
    end
    return contract
end

RegisterServerCallback("dynasty:proposeContract", function(source, contractData)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable." end
    if type(contractData) ~= "table" then return false, "Les informations envoyees ne sont pas valides." end

    if not xPlayer.job or not xPlayer.job.onDuty then
        return false, "Vous devez etre en service."
    end

    local targetId = PS.ToInt(contractData.targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil
    if not target or target.source == source then
        return false, "Client introuvable."
    end

    local a, b = xPlayer.getCoords(), target.getCoords()
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    if (dx * dx + dy * dy + dz * dz) > 900.0 then
        return false, "Le client est trop loin."
    end

    local category = PS.NormalizeCategory(contractData.category)
    if not category then return false, "Cette categorie n'est pas valide." end

    local propertyName = PS.SafeString(contractData.propertyName, 64)
    if not propertyName then return false, "Ce bien immobilier n'est pas valide." end

    local config = PS.FindConfigProperty(category, propertyName)
    if not config then return false, "Bien immobilier introuvable." end

    local prices = PS.GetPrice(category, config.id)
    if not prices then return false, "Ce bien n'est pas au catalogue." end

    local contractType = contractData.contractType
    if contractType ~= "sale" and contractType ~= "rent" then
        contractType = "sale"
    end
    if contractType == "sale" and not prices.enabled then
        return false, "Ce bien n'est pas en vente."
    end
    if contractType == "rent" and not prices.rentEnabled then
        return false, "Ce bien n'est pas en location."
    end

    local ownerType = contractData.ownerType
    if ownerType ~= "citizen" and ownerType ~= "job" and ownerType ~= "crew" then
        ownerType = "citizen"
    end

    local ownerValue = target.identifier
    local groupLabel = nil
    if ownerType == "job" then
        if not target.job or target.job.name == "" or (target.job.grade or 0) < BOSS_GRADE then
            return false, "Le client n'est pas patron de sa societe."
        end
        ownerValue = target.job.name
        groupLabel = target.job.label
    elseif ownerType == "crew" then
        if not target.faction or target.faction == "" then
            return false, "Le client n'appartient a aucun groupe."
        end
        ownerValue = target.faction
        groupLabel = target.faction
    end

    local duration = PS.ToInt(contractData.duration) or 1
    if duration < 1 then duration = 1 end
    if duration > 52 then duration = 52 end
    if contractType == "sale" then duration = 1 end

    local pos = PS.ReadVec4(contractData.pos)
    if not pos then return false, "Cette position n'est pas valide." end

    local vehiclePos = PS.ReadVec4(contractData.vehiclePos)

    local capacity = PS.SafeString(contractData.capacity, 16) or "aucun"
    if category == "Garage" then
        local places = PS.ToInt(capacity) or PS.ToInt(config.maxPlaces)
        if not PS.IsValidMaxPlaces(places) then
            return false, "Cette capacite de garage n'est pas valide."
        end
        capacity = tostring(places)
    end

    local unitPrice = contractType == "rent" and prices.rent or prices.sell
    local price = contractType == "rent" and (prices.rent * duration) or prices.sell

    local now = PS.Now()
    local contractId = MySQL.insert.await([[
        INSERT INTO dynasty_contracts
        (agent_identifier, agent_name, agent_society, buyer_identifier, buyer_name, property_name, property_key,
         custom_name, category, category_label, capacity, contract_type, owner_type, owner_value, group_label,
         unit_price, duration, price, pos, vehicle_pos, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
    ]], {
        xPlayer.identifier, xPlayer.name, xPlayer.job and xPlayer.job.name or "",
        target.identifier, target.name,
        config.name, config.id,
        PS.SafeString(contractData.customName, 64),
        category, CATEGORY_LABELS[category] or category, capacity,
        contractType, ownerType, ownerValue, groupLabel,
        unitPrice, duration, price,
        PS.Encode(pos), vehiclePos and PS.Encode(vehiclePos) or nil,
        now,
    })

    if not contractId then
        return false, "Erreur lors de la creation du contrat."
    end

    PS.Contracts[contractId] = {
        id = contractId,
        agent_identifier = xPlayer.identifier,
        agent_name = xPlayer.name,
        agent_society = xPlayer.job and xPlayer.job.name or "",
        buyer_identifier = target.identifier,
        buyer_name = target.name,
        property_name = config.name,
        property_key = config.id,
        custom_name = PS.SafeString(contractData.customName, 64),
        category = category,
        category_label = CATEGORY_LABELS[category] or category,
        capacity = capacity,
        contract_type = contractType,
        owner_type = ownerType,
        owner_value = ownerValue,
        group_label = groupLabel,
        unit_price = unitPrice,
        duration = duration,
        price = price,
        pos = pos,
        vehicle_pos = vehiclePos,
        created_at = now,
    }

    TriggerClientEvent("dynastyContract:receiveOffer", target.source, {
        contractId = contractId,
        propertyName = config.name,
        categoryLabel = CATEGORY_LABELS[category] or category,
        contractType = contractType,
        unitPrice = unitPrice,
        duration = duration,
        price = price,
        ownerType = ownerType,
        groupLabel = groupLabel,
        agentName = xPlayer.name,
    })

    SetTimeout(120000, function()
        if PS.Contracts[contractId] then
            cancelContract(contractId, "expired", true)
        end
    end)

    return true, "Offre de contrat envoyee au client."
end)

RegisterNetEvent("dynastyContract:signed", function(contractId, paymentMethod)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local cid = PS.ToInt(contractId)
    if not cid then return end

    local contract = PS.Contracts[cid]
    if not contract or contract.buyer_identifier ~= xPlayer.identifier then return end

    local method = paymentMethod
    if method ~= "bank" and method ~= "cash" and method ~= "combined" then
        method = "bank"
    end

    if not PS.TakeMoney(xPlayer, contract.price, method) then
        xPlayer.showNotification({ type = "ROUGE", content = "Fonds insuffisants." })
        return
    end

    PS.Contracts[cid] = nil

    local now = PS.Now()
    local expiry = contract.contract_type == "rent" and (now + contract.duration * 7 * 86400) or 0
    local category = contract.category
    local maxPlaces = category == "Garage" and PS.ToInt(contract.capacity) or nil

    local propertyId = MySQL.insert.await([[
        INSERT INTO properties
        (name, property_name, property_key, type, category, owner, access, pos, vehicle_pos, max_places,
         deco, is_perquisitioned, contract_type, total_price, rent_price, rental_expire, dynasty_society, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 'fermer', ?, ?, ?, NULL, 0, ?, ?, ?, ?, ?, ?)
    ]], {
        contract.custom_name or contract.property_name,
        contract.property_name,
        contract.property_key,
        PS.CategoryToType(category),
        category,
        PS.MakeOwner(contract.owner_type, contract.owner_value),
        PS.Encode(contract.pos),
        contract.vehicle_pos and PS.Encode(contract.vehicle_pos) or nil,
        maxPlaces,
        contract.contract_type,
        contract.price,
        contract.contract_type == "rent" and contract.unit_price or 0,
        expiry,
        contract.agent_society,
        now,
    })

    if not propertyId then
        PS.GiveMoney(xPlayer, contract.price, "bank")
        xPlayer.showNotification({ type = "ROUGE", content = "Erreur lors de la creation de la propriete." })
        return
    end

    MySQL.update("UPDATE dynasty_contracts SET status = 'signed', property_id = ?, signed_date = ?, expiry_date = ? WHERE id = ?", {
        propertyId, now, expiry, cid,
    })

    local row = PS.RowFromSql({
        id = propertyId,
        name = contract.custom_name or contract.property_name,
        property_name = contract.property_name,
        property_key = contract.property_key,
        type = PS.CategoryToType(category),
        category = category,
        owner = PS.MakeOwner(contract.owner_type, contract.owner_value),
        access = "fermer",
        pos = PS.Encode(contract.pos),
        vehicle_pos = contract.vehicle_pos and PS.Encode(contract.vehicle_pos) or nil,
        max_places = maxPlaces,
        deco = nil,
        is_perquisitioned = 0,
        contract_type = contract.contract_type,
        total_price = contract.price,
        rent_price = contract.contract_type == "rent" and contract.unit_price or 0,
        rental_expire = expiry,
        dynasty_society = contract.agent_society,
        created_at = now,
    })
    PS.Properties[propertyId] = row
    PS.Access[propertyId] = PS.Access[propertyId] or {}
    PS.InvalidateManageCache(propertyId)

    TriggerClientEvent("vfw:loadProperty", -1, propertyId, PS.PropertyPos(row), row.type, row.vehicle_pos)
    PS.RefreshAllBlips()

    if VFW.Items[CONTRACT_ITEM] then
        xPlayer.addInventoryItem(CONTRACT_ITEM, 1, {
            propertyName = contract.property_name,
            categoryLabel = contract.category_label,
            contractType = contract.contract_type,
            unitPrice = contract.unit_price,
            duration = contract.duration,
            totalPrice = contract.price,
            expiryDate = expiry,
            buyerName = xPlayer.name,
            ownerType = contract.owner_type,
            groupLabel = contract.group_label,
            agentName = contract.agent_name,
            signedDate = now,
            propertyId = propertyId,
        })
    end

    TriggerClientEvent("dynastyContract:signedSuccess", source)
    xPlayer.showNotification({ type = "VERT", content = "Contrat signe." })

    local agent = VFW.GetPlayerFromIdentifier(contract.agent_identifier)
    if agent then
        agent.showNotification({ type = "VERT", content = ("%s a signe le contrat."):format(xPlayer.name) })
    end

    PS.Log(propertyId, "transfer", xPlayer, ("contrat #%d"):format(cid))
end)

RegisterNetEvent("dynastyContract:refused", function(contractId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local cid = PS.ToInt(contractId)
    if not cid then return end

    local contract = PS.Contracts[cid]
    if not contract or contract.buyer_identifier ~= xPlayer.identifier then return end

    cancelContract(cid, "refused", false)

    local agent = VFW.GetPlayerFromIdentifier(contract.agent_identifier)
    if agent then
        agent.showNotification({ type = "ROUGE", content = ("%s a refuse le contrat."):format(xPlayer.name) })
    end
end)

RegisterNetEvent("dynastyContract:expired", function(contractId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local cid = PS.ToInt(contractId)
    if not cid then return end

    local contract = PS.Contracts[cid]
    if not contract or contract.buyer_identifier ~= xPlayer.identifier then return end

    cancelContract(cid, "expired", false)

    local agent = VFW.GetPlayerFromIdentifier(contract.agent_identifier)
    if agent then
        agent.showNotification({ type = "ROUGE", content = "L'offre de contrat a expire." })
    end
end)

AddEventHandler("vfw:playerLoaded", function(source)
    PS.PushPrices(source)
end)

AddEventHandler("vfw:setDuty", function(source, onDuty)
    if onDuty == false then
        TriggerClientEvent("vfw:dynastyTablet:close", source)
    end
end)

MySQL.ready(function()
    PS.LoadPrices()
    MySQL.update("UPDATE dynasty_contracts SET status = 'expired' WHERE status = 'pending'")
end)

CreateThread(function()
    while true do
        Wait(300000)
        local now = PS.Now()
        local expired = {}
        for id, row in pairs(PS.Properties) do
            if row.contract_type == "rent" and (row.rental_expire or 0) > 0 and row.rental_expire < now then
                expired[#expired + 1] = id
            end
        end

        for i = 1, #expired do
            local row = PS.Properties[expired[i]]
            if row then
                local kind, value = PS.ParseOwner(row.owner)
                if kind == "citizen" then
                    local owner = VFW.GetPlayerFromIdentifier(value)
                    if owner then
                        owner.showNotification({ type = "ROUGE", content = ("Votre location %s a expire."):format(row.name) })
                    end
                end
                PS.DeleteProperty(expired[i], "rental_expired", nil)
            end
        end
    end
end)
