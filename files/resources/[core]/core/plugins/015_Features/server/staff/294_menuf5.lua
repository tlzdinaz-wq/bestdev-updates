local weaponStyles = {}
local holsterStyles = {}
local streamerMuters = {}
local parachuteState = {}
local pendingSales = {}
local documentViewers = {}

local SAMS_JOBS = { "sams_pib", "sams_pab" }

local function findWeaponItem(xPlayer, weaponId)
    if weaponId == nil then return nil end
    local key = tostring(weaponId)
    for i = 1, #xPlayer.inventory do
        local item = xPlayer.inventory[i]
        local meta = item.metadata or item.meta
        if type(meta) == "table" and meta.weaponId ~= nil and tostring(meta.weaponId) == key then
            return item, meta
        end
    end
    return nil
end

local function pushWeaponStyles(source)
    local payload = {}
    for src, animSet in pairs(weaponStyles) do
        if src ~= source then payload[tostring(src)] = animSet end
    end
    TriggerClientEvent("vfw:weaponStyle:syncAll", source, payload)
end

local function getPlaytime(xPlayer)
    if not xPlayer then return 0 end
    local value = Staff29.Scalar("SELECT playtime FROM users WHERE id = ?", { xPlayer.accountId }, 0)
    return tonumber(value) or 0
end

local function buildNewPlayersList()
    local ids, n = {}, 0
    local players = VFW.GetExtendedPlayers()
    for i = 1, #players do
        local xPlayer = players[i]
        if getPlaytime(xPlayer) < 3600 then
            n = n + 1
            ids[n] = xPlayer.source
        end
    end
    return ids
end

local function refreshStreamerLists()
    local list = buildNewPlayersList()
    for src in pairs(streamerMuters) do
        if VFW.Players[src] then
            local filtered, n = {}, 0
            for i = 1, #list do
                if list[i] ~= src then
                    n = n + 1
                    filtered[n] = list[i]
                end
            end
            TriggerClientEvent("vfw:streamer:newPlayersList", src, filtered)
        else
            streamerMuters[src] = nil
        end
    end
end

Staff29.Cb("core:factionTerritories:getPublic", function(source)
    local rows = Staff29.Query("SELECT * FROM faction_territories ORDER BY id ASC")

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local owner = row.owner_crew or row.owner
        n = n + 1
        out[n] = {
            id = row.id,
            name = row.name or "",
            polygon = Staff29.Decode(row.polygon, {}),
            display_number = tonumber(row.display_number) or n,
            display_color = row.display_color or "#FFFFFF",
            isOwned = owner ~= nil and owner ~= "" and owner ~= 0,
        }
    end

    return out
end)

RegisterNetEvent("vfw:showDocumentToPlayer", function(targetId, documentType, documentData, cardType, cardLabel, photoUrl, licenseCategories)
    local source = source

    local target = Staff29.ToInt(targetId, 1, 1024)
    if not target then return end
    if not Staff29.IsString(documentType, 40) then return end
    if not Staff29.IsTable(documentData) then return end
    if not Staff29.IsString(cardType, 40) then return end
    if type(cardLabel) ~= "string" then return end
    if photoUrl ~= nil and type(photoUrl) ~= "string" then return end
    if licenseCategories ~= nil and type(licenseCategories) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not Staff29.Distance(source, target, 6.0) then return end
    if not Staff29.RateLimit(source, "showDocument", 1000) then return end

    documentViewers[source] = target
    xTarget.triggerEvent("vfw:displayDocument", documentType, documentData, cardType,
        cardLabel, photoUrl, licenseCategories)
end)

RegisterNetEvent("vfw:stopShowingDocument", function(targetId)
    local source = source

    local target = Staff29.ToInt(targetId, 1, 1024)
    if not target then return end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return end
    if documentViewers[source] ~= target then return end

    documentViewers[source] = nil
    xTarget.triggerEvent("vfw:dismissDocument")
end)

local DVM_TYPES = {
    car = "car", voiture = "car", b = "car", drive = "car",
    motorcycle = "motorcycle", moto = "motorcycle", a = "motorcycle",
    truck = "truck", poids_lourd = "truck", c = "truck",
}

Staff29.Cb("identity:getData", function(source, serverId, documentType)
    local sid = Staff29.ToInt(serverId, 1, 1024) or source
    local target = VFW.GetPlayerFromId(sid)
    if not target then return nil end

    if documentType == "cayo_visa" then
        local visa = target.getMeta("cayo_visa")
        if type(visa) ~= "table" then return nil end
        return {
            issued_date = tostring(visa.issued_date or visa.issuedAt or ""),
            visa_number = tostring(visa.visa_number or visa.number or "CAYO-00000"),
        }
    end

    return {
        firstName = target.firstName,
        lastName = target.lastName,
        date_of_birth = target.dateofbirth,
        sex = target.sex,
        height = target.height,
        photo = target.mugshot or "",
    }
end)

Staff29.Cb("vfw:license:checkAllLicense", function(source, serverId)
    local sid = Staff29.ToInt(serverId, 1, 1024) or source
    local target = VFW.GetPlayerFromId(sid)
    if not target then return {} end

    local out = {}
    for i = 1, #target.licenses do
        local license = target.licenses[i]
        if license and license.type then out[license.type] = true end
    end

    local ppa = Staff29.Query("SELECT type FROM vip_ppa WHERE identifier = ?", { target.identifier })
    for i = 1, #ppa do
        out["ppa_" .. tostring(ppa[i].type)] = true
    end

    if type(target.getMeta("cayo_visa")) == "table" then out.cayo_visa = true end

    return out
end)

Staff29.Cb("dvm:getPlayerLicensesForDocument", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local out, n = {}, 0
    for i = 1, #xPlayer.licenses do
        local license = xPlayer.licenses[i]
        local kind = license and license.type and DVM_TYPES[tostring(license.type):lower()] or nil
        if kind then
            n = n + 1
            out[n] = {
                license_type = kind,
                obtained_date_formatted = tostring(license.obtainedAt or license.date or "Non disponible"),
            }
        end
    end
    return out
end)

Staff29.Cb("garage:getAllPlayerVehicles", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = Staff29.Query([[
        SELECT plate, vehName, label, stored FROM owned_vehicles WHERE owner = ?
    ]], { xPlayer.identifier })

    local out, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        out[n] = {
            plate = rows[i].plate,
            model = rows[i].vehName,
            vehName = rows[i].vehName,
            label = rows[i].label,
            stored = rows[i].stored == 1,
        }
    end
    return out
end)

Staff29.Cb("vfw:vehicle:resolvePlayerNames", function(source, serverIds)
    if not Staff29.IsTable(serverIds) then return {} end

    local out = {}
    for i = 1, #serverIds do
        local sid = Staff29.ToInt(serverIds[i], 1, 1024)
        if sid then
            local target = VFW.GetPlayerFromId(sid)
            if target then
                out[tostring(sid)] = target.firstName or target.name or "Inconnu"
            end
        end
    end
    return out
end)

RegisterNetEvent("vfw:vehicle:proposeSale", function(targetServerId, plate, price, vehicleLabel)
    local source = source

    local target = Staff29.ToInt(targetServerId, 1, 1024)
    local amount = Staff29.ToInt(price, 1, 9999999)
    if not target or not amount then return end
    if not Staff29.IsString(plate, 12) then return end
    if vehicleLabel ~= nil and type(vehicleLabel) ~= "string" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget or xPlayer.source == xTarget.source then return end
    if not Staff29.Distance(source, target, 8.0) then return end
    if not Staff29.RateLimit(source, "proposeSale", 3000) then return end

    local row = Staff29.Single("SELECT plate, owner, stored, vehName FROM owned_vehicles WHERE plate = ?", { plate })
    if not row or row.owner ~= xPlayer.identifier then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Vente",
            message = "Ce véhicule ne vous appartient pas.",
        })
        return
    end

    if pendingSales[target] then
        xPlayer.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Vente",
            message = "Ce joueur a déjà une offre en cours.",
        })
        return
    end

    local label = Staff29.Clean(vehicleLabel, 96) or row.vehName or plate

    local offer = {
        sellerSource = source,
        sellerIdentifier = xPlayer.identifier,
        plate = plate,
        price = amount,
        label = label,
        createdAt = GetGameTimer(),
    }
    pendingSales[target] = offer

    xTarget.triggerEvent("vfw:vehicle:receiveSaleOffer", {
        sellerName = xPlayer.name,
        vehicleLabel = label,
        plate = plate,
        price = amount,
    })

    VFW.SetTimeout(60000, function()
        if pendingSales[target] == offer then
            pendingSales[target] = nil
        end
    end)
end)

RegisterNetEvent("vfw:vehicle:respondSale", function(accepted, paymentMethod)
    local source = source

    local offer = pendingSales[source]
    if not offer then return end
    pendingSales[source] = nil

    local buyer = VFW.GetPlayerFromId(source)
    local seller = VFW.GetPlayerFromId(offer.sellerSource)

    if accepted ~= true then
        if seller then
            seller.triggerEvent("vfw:vehicle:saleResult", false, "L'offre a été refusée.")
        end
        return
    end

    if paymentMethod ~= "cash" and paymentMethod ~= "bank" then
        if buyer then buyer.triggerEvent("vfw:vehicle:saleResult", false, "Ce moyen de paiement n'est pas valide.") end
        return
    end

    if not buyer or not seller then
        if buyer then buyer.triggerEvent("vfw:vehicle:saleResult", false, "Le vendeur n'est plus disponible.") end
        return
    end

    local row = Staff29.Single("SELECT plate, owner, stored FROM owned_vehicles WHERE plate = ?", { offer.plate })
    if not row or row.owner ~= offer.sellerIdentifier then
        buyer.triggerEvent("vfw:vehicle:saleResult", false, "Le véhicule n'est plus disponible.")
        seller.triggerEvent("vfw:vehicle:saleResult", false, "Le véhicule n'est plus disponible.")
        return
    end

    local accountName = paymentMethod == "cash" and "money" or "bank"
    local account = buyer.getAccount(accountName)

    if not account or account.money < offer.price then
        buyer.triggerEvent("vfw:vehicle:saleResult", false, "Fonds insuffisants.")
        seller.triggerEvent("vfw:vehicle:saleResult", false, "L'acheteur n'a pas les fonds nécessaires.")
        return
    end

    buyer.removeAccountMoney(accountName, offer.price, "vehicle-purchase")
    seller.addAccountMoney("bank", offer.price, "vehicle-sale")

    Staff29.Update("UPDATE owned_vehicles SET owner = ? WHERE plate = ?", { buyer.identifier, offer.plate })

    buyer.triggerEvent("vfw:vehicle:saleResult", true,
        ("Vous avez acheté %s (%s)."):format(offer.label, offer.plate))
    seller.triggerEvent("vfw:vehicle:saleResult", true,
        ("Vous avez vendu %s (%s)."):format(offer.label, offer.plate))
end)

RegisterNetEvent("vfw:weaponStyle:set", function(animSet)
    local source = source
    if not Staff29.IsString(animSet, 64) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "weaponStyle", 500) then return end

    weaponStyles[source] = animSet
    xPlayer.setMeta("weaponAimStyle", animSet)

    for src in pairs(VFW.Players) do
        if src ~= source then
            TriggerClientEvent("vfw:weaponStyle:sync", src, source, animSet)
        end
    end
end)

RegisterNetEvent("fb:character:setHolsterAnim", function(value)
    local source = source
    if value ~= nil and type(value) ~= "string" then return end
    if type(value) == "string" and #value > 64 then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    holsterStyles[source] = value
    xPlayer.setMeta("holsterAnim", value)
end)

Staff29.Cb("vfw:getInvoices", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = Staff29.Query([[
        SELECT id, job_name, sender, date, total, items
        FROM society_billings
        WHERE target_identifier = ? AND statut = 0 AND type NOT IN ('deposit','withdraw')
        ORDER BY id DESC LIMIT 100
    ]], { xPlayer.identifier })

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local job = VFW.Jobs[row.job_name]
        local items = row.items
        if type(items) ~= "string" or items == "" then items = "[]" end
        n = n + 1
        out[n] = {
            id = row.id,
            society = row.job_name,
            societyLabel = job and job.label or row.job_name,
            sender = row.sender or "Inconnu",
            total = tonumber(row.total) or 0,
            date = tostring(row.date or ""),
            items = items,
        }
    end
    return out
end)

Staff29.Cb("vfw:getSamsInvoices", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = Staff29.Query([[
        SELECT id, hospital, created_by, total, items, date
        FROM sams_invoices
        WHERE citizen_identifier = ? AND status = 'unpaid'
        ORDER BY id DESC LIMIT 100
    ]], { xPlayer.identifier })

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local items = row.items
        if type(items) ~= "string" or items == "" then items = "[]" end
        n = n + 1
        out[n] = {
            id = row.id,
            hospital = row.hospital or "pillbox",
            createdBy = row.created_by or "SAMS",
            total = tonumber(row.total) or 0,
            date = tostring(row.date or ""),
            items = items,
        }
    end
    return out
end)

local function payFrom(xPlayer, method, amount)
    local accountName = method == "cash" and "money" or "bank"
    local account = xPlayer.getAccount(accountName)
    if not account or account.money < amount then return false end
    xPlayer.removeAccountMoney(accountName, amount, "invoice-payment")
    return true
end

RegisterNetEvent("vfw:invoice:pay", function(invoiceId, method)
    local source = source

    local id = Staff29.ToInt(invoiceId, 1, 2147483647)
    if not id or (method ~= "cash" and method ~= "bank") then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "payInvoice", 1000) then return end

    local row = Staff29.Single([[
        SELECT id, job_name, total, statut, target_identifier FROM society_billings WHERE id = ?
    ]], { id })

    if not row or row.target_identifier ~= xPlayer.identifier or tonumber(row.statut) ~= 0 then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Facture",
            message = "Cette facture n'est plus disponible.",
        })
        return
    end

    local amount = tonumber(row.total) or 0
    if not payFrom(xPlayer, method, amount) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Facture",
            message = "Fonds insuffisants.",
        })
        return
    end

    Staff29.Update("UPDATE society_billings SET statut = 1 WHERE id = ?", { id })
    Staff29.Boss.AddSocietyMoney(row.job_name, amount)
    Staff29.Boss.NotifyPanel(row.job_name)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Facture",
        message = ("Facture de %d$ payée."):format(amount),
    })
end)

RegisterNetEvent("vfw:samsInvoice:pay", function(invoiceId, method)
    local source = source

    local id = Staff29.ToInt(invoiceId, 1, 2147483647)
    if not id or (method ~= "cash" and method ~= "bank") then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "paySamsInvoice", 1000) then return end

    local row = Staff29.Single([[
        SELECT id, hospital, total, status, citizen_identifier FROM sams_invoices WHERE id = ?
    ]], { id })

    if not row or row.citizen_identifier ~= xPlayer.identifier or row.status ~= "unpaid" then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Facture",
            message = "Cette facture n'est plus disponible.",
        })
        return
    end

    local amount = tonumber(row.total) or 0
    if not payFrom(xPlayer, method, amount) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Facture",
            message = "Fonds insuffisants.",
        })
        return
    end

    Staff29.Update("UPDATE sams_invoices SET status = 'paid' WHERE id = ?", { id })

    local society = row.hospital == "paleto" and "sams_pab" or "sams_pib"
    Staff29.Boss.AddSocietyMoney(society, amount)

    local agents = VFW.GetPlayersWithJobs(SAMS_JOBS)
    for i = 1, #agents do
        agents[i].triggerEvent("sn_sams:invoiceUpdated", {
            id = id,
            status = "paid",
            total = amount,
            hospital = row.hospital,
        })
    end

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Facture médicale",
        message = ("Facture de %d$ payée."):format(amount),
    })
end)

RegisterNetEvent("vfw:weapon:addComponent", function(weaponId, componentHash)
    local source = source
    if weaponId == nil then return end
    if type(componentHash) ~= "string" and type(componentHash) ~= "number" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "weaponComponent", 400) then return end

    local item, meta = findWeaponItem(xPlayer, weaponId)
    if not item or not meta then return end

    local itemName = GetItemFromHash and GetItemFromHash(componentHash) or nil
    if not itemName then return end
    if not xPlayer.haveItem(itemName, 1) then return end

    meta.components = type(meta.components) == "table" and meta.components or {}
    for i = 1, #meta.components do
        if meta.components[i] == componentHash then return end
    end

    xPlayer.removeInventoryItem(itemName, 1, nil, true)
    meta.components[#meta.components + 1] = componentHash

    item.metadata = meta
    item.meta = meta
    xPlayer.setPlayerData("inventory", xPlayer.inventory)
    xPlayer.triggerEvent("vfw:weapon:componentUpdated", weaponId, meta.components)
end)

RegisterNetEvent("vfw:weapon:removeComponent", function(weaponId, componentHash)
    local source = source
    if weaponId == nil then return end
    if type(componentHash) ~= "string" and type(componentHash) ~= "number" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "weaponComponent", 400) then return end

    local item, meta = findWeaponItem(xPlayer, weaponId)
    if not item or not meta or type(meta.components) ~= "table" then return end

    local index = nil
    for i = 1, #meta.components do
        if meta.components[i] == componentHash then
            index = i
            break
        end
    end
    if not index then return end

    local itemName = GetItemFromHash and GetItemFromHash(componentHash) or nil
    if itemName and not xPlayer.canCarryItem(itemName, 1) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Arme",
            message = "Votre inventaire est plein.",
        })
        return
    end

    table.remove(meta.components, index)
    if itemName then xPlayer.addInventoryItem(itemName, 1, nil, true) end

    item.metadata = meta
    item.meta = meta
    xPlayer.setPlayerData("inventory", xPlayer.inventory)
    xPlayer.triggerEvent("vfw:weapon:componentUpdated", weaponId, meta.components)
end)

RegisterNetEvent("vfw:streamer:muteNewPlayers", function(enabled)
    local source = source
    if type(enabled) ~= "boolean" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "streamerMute", 2000) then return end

    if enabled then
        streamerMuters[source] = true
    else
        streamerMuters[source] = nil
        TriggerClientEvent("vfw:streamer:newPlayersList", source, {})
        return
    end

    refreshStreamerLists()
end)

function Staff29.SetParachute(source, state)
    if state then
        parachuteState[source] = true
    else
        parachuteState[source] = nil
    end
    TriggerClientEvent("vfw:parachute:setState", source, state and true or false)
end

RegisterNetEvent("vfw:parachute:regive", function()
    local source = source
    if not parachuteState[source] then return end
    if not VFW.GetPlayerFromId(source) then return end
    if not Staff29.RateLimit(source, "parachuteRegive", 2000) then return end
    TriggerClientEvent("vfw:parachute:give", source)
end)

VFW.RegisterCommand("openf5", "gestion", function(source, xPlayer, args)
    local targetId = tonumber(args and args[1]) or source
    local target = VFW.GetPlayerFromId(targetId)
    if not target then
        Staff29.Notify(source, "ERROR", "Menu F5", "Joueur introuvable.")
        return
    end

    target.triggerEvent("vfw:openPersonalMenu")
    Staff29.Notify(source, "SUCCESS", "Menu F5", ("Menu ouvert pour %s."):format(target.name))
end, {
    help = "Ouvrir le menu personnel (F5) d'un joueur.",
    params = { { name = "id", help = "ID serveur (soi-même par défaut)" } },
})

VFW.RegisterCommand("parachute", "give_weapon", function(source, xPlayer, args)
    local targetId = tonumber(args and args[1]) or source
    local target = VFW.GetPlayerFromId(targetId)
    if not target then
        Staff29.Notify(source, "ERROR", "Parachute", "Joueur introuvable.")
        return
    end

    local state = not parachuteState[target.source]
    if args and args[2] ~= nil then
        state = args[2] == "1" or args[2] == "true" or args[2] == "on"
    end

    Staff29.SetParachute(target.source, state)
    Staff29.Notify(source, "SUCCESS", "Parachute",
        ("Parachute %s pour %s."):format(state and "activé" or "désactivé", target.name))
end, {
    help = "Activer/désactiver le parachute d'un joueur.",
    params = {
        { name = "id", help = "ID serveur (soi-même par défaut)" },
        { name = "etat", help = "1 ou 0 (bascule par défaut)" },
    },
})

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end

    local saved = xPlayer.getMeta("weaponAimStyle")
    if type(saved) == "string" and saved ~= "" then
        weaponStyles[source] = saved
        for src in pairs(VFW.Players) do
            if src ~= source then
                TriggerClientEvent("vfw:weaponStyle:sync", src, source, saved)
            end
        end
    end

    pushWeaponStyles(source)
    refreshStreamerLists()
end)

AddEventHandler("vfw:playerDropped", function(source)
    weaponStyles[source] = nil
    holsterStyles[source] = nil
    streamerMuters[source] = nil
    parachuteState[source] = nil
    documentViewers[source] = nil
    pendingSales[source] = nil

    for buyer, offer in pairs(pendingSales) do
        if offer.sellerSource == source then
            pendingSales[buyer] = nil
        end
    end

    refreshStreamerLists()
end)
