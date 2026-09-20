local priceCache = {
    basePrices = {},
    categoryModifiers = {},
    categoryOverrides = {},
    modelModifiers = {},
    modelOverrides = {},
}

local hasPriceData = false
local tempProps = {}
local pendingInvoices = {}
local commandesByJob = {}

local INVOICE_TIMEOUT = 300

local function loadPrices()
    local base = VFW.Society.Query("SELECT * FROM custom_prices_base")
    if not base then return false end

    local prices = {}
    for i = 1, #base do
        local row = base[i]
        prices[row.mod_type] = {
            base_price = tonumber(row.base_price) or 0,
            price_per_level = tonumber(row.price_per_level) or 0,
        }
    end

    local categoryModifiers, categoryOverrides = {}, {}
    local categories = VFW.Society.Query("SELECT * FROM custom_prices_category") or {}
    for i = 1, #categories do
        local row = categories[i]
        categoryModifiers[row.category] = tonumber(row.modifier) or 0
        local overrides = VFW.DB.Decode(row.overrides, {})
        if type(overrides) == "table" then categoryOverrides[row.category] = overrides end
    end

    local modelModifiers, modelOverrides = {}, {}
    local models = VFW.Society.Query("SELECT * FROM custom_prices_model") or {}
    for i = 1, #models do
        local row = models[i]
        local key = tostring(row.model or ""):lower()
        modelModifiers[key] = tonumber(row.modifier) or 0
        local overrides = VFW.DB.Decode(row.overrides, {})
        if type(overrides) == "table" then modelOverrides[key] = overrides end
    end

    priceCache = {
        basePrices = prices,
        categoryModifiers = categoryModifiers,
        categoryOverrides = categoryOverrides,
        modelModifiers = modelModifiers,
        modelOverrides = modelOverrides,
    }

    hasPriceData = next(prices) ~= nil
    return hasPriceData
end

local function syncPrices(target)
    if not hasPriceData then return end
    TriggerClientEvent("customPrices:syncConfig", target or -1, priceCache)
end

VFW.Society.SyncCustomPrices = syncPrices

local function maxPriceFor(modType)
    local cfg = priceCache.basePrices[modType]
    local base = 1000
    if cfg then
        base = (cfg.base_price or 0) + (cfg.price_per_level or 0) * 4
    end
    if base < 1 then base = 1000 end
    return math.floor(base * 3)
end

local function computeTotal(modifications)
    local total = 0

    for i = 1, #modifications do
        local mod = modifications[i]
        if type(mod) == "table" and type(mod.type) == "string" then
            local declared = tonumber(mod.price) or 0
            if declared < 0 then declared = 0 end
            local cap = maxPriceFor(mod.type)
            if declared > cap then declared = cap end
            mod.price = math.floor(declared)
            total = total + mod.price
        end
    end

    return math.floor(total)
end

local function isCustomsJob(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.hasPermission("staff_menu") then return true end
    if not xPlayer.job.onDuty then return false end

    local society = VFW.Society.Get(xPlayer.job.name)
    if not society then return false end
    if society.type == "customs" or society.type == "mecano" then return true end
    if type(society.custom) == "table" and type(society.custom.customs) == "table" then return true end

    return false
end

local function distanceBetween(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function loadCommandes()
    local rows = VFW.Society.Query("SELECT * FROM mecano_commandes") or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        out[row.job] = out[row.job] or {}
        out[row.job][tostring(row.id)] = {
            id = row.id,
            plate = row.plate or "",
            name = row.name or "",
            props = VFW.DB.Decode(row.props, {}),
        }
    end

    commandesByJob = out
    return out
end

local function pushCommandes(jobName)
    local list = commandesByJob[jobName] or {}
    for src, xPlayer in pairs(VFW.Players) do
        if xPlayer.job and xPlayer.job.name == jobName then
            TriggerClientEvent("core:GetCommandeMecano", src, list)
        end
    end
end

function VFW.Society.AddCommandeMecano(jobName, plate, name, props)
    if type(jobName) ~= "string" or jobName == "" then return nil end
    if type(plate) ~= "string" then return nil end

    local id = VFW.Society.Insert([[
        INSERT INTO mecano_commandes (job, plate, name, props) VALUES (?, ?, ?, ?)
    ]], { jobName, plate:sub(1, 16), tostring(name or ""):sub(1, 120), VFW.DB.Encode(props or {}) })

    if not id then return nil end

    commandesByJob[jobName] = commandesByJob[jobName] or {}
    commandesByJob[jobName][tostring(id)] = {
        id = id,
        plate = plate:sub(1, 16),
        name = tostring(name or ""):sub(1, 120),
        props = props or {},
    }

    pushCommandes(jobName)
    return id
end

local function persistProps(plate, props)
    if type(plate) ~= "string" or plate == "" then return end
    if type(props) ~= "table" then return end

    VFW.Society.Update("UPDATE owned_vehicles SET props = ? WHERE plate = ?", { VFW.DB.Encode(props), plate:sub(1, 16) })
end

VFW.Society.PersistVehicleProps = persistProps

RegisterNetEvent("vehicleTuningBuilder:server:setTempProps", function(plate, props)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(plate) ~= "string" or plate == "" or #plate > 16 then return end
    if type(props) ~= "table" then return end

    tempProps[plate] = { props = props, owner = source, at = os.time() }
end)

function VFW.Society.GetTempProps(plate)
    local entry = tempProps[plate]
    if not entry then return nil end
    return entry.props
end

RegisterNetEvent("core:SetPropsVeh", function(plate, props)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(plate) ~= "string" or plate == "" or #plate > 16 then return end
    if type(props) ~= "table" then return end
    if not isCustomsJob(xPlayer) then return end

    persistProps(plate, props)
end)

RegisterNetEvent("core:vehicleCustoms:honkHorn", function(netId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(netId)
    if not id then return end

    local coords = xPlayer.getCoords()
    local nearby = VFW.GetPlayersInRadius(coords, 40.0)

    for i = 1, #nearby do
        TriggerClientEvent("core:vehicleCustoms:honkHornSync", nearby[i].source, math.floor(id))
    end
end)

RegisterNetEvent("core:removeCommandeMecano", function(key, jobName)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(jobName) ~= "string" or jobName == "" then return end
    if not xPlayer.hasPermission("staff_menu") and (not xPlayer.job or xPlayer.job.name ~= jobName) then return end

    local list = commandesByJob[jobName]
    if not list then return end

    local entry = list[key] or list[tostring(key)]
    if not entry then return end

    VFW.Society.Update("DELETE FROM mecano_commandes WHERE id = ? AND job = ?", { entry.id, jobName })

    list[key] = nil
    list[tostring(key)] = nil

    pushCommandes(jobName)
end)

VFW.Society.RegisterCallback("core:GetCommandeMecanoCb", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if type(jobName) ~= "string" or jobName == "" then return {} end
    if not xPlayer.hasPermission("staff_menu") and (not xPlayer.job or xPlayer.job.name ~= jobName) then return {} end

    return commandesByJob[jobName] or {}
end)

VFW.Society.RegisterCallback("society:customs:getNearbyPlayersNames", function(source, nearbyIds)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if type(nearbyIds) ~= "table" then return {} end

    local origin = xPlayer.getCoords()
    local out = {}

    for i = 1, #nearbyIds do
        local id = tonumber(nearbyIds[i])
        if id then
            local target = VFW.GetPlayerFromId(id)
            if target and target.source ~= xPlayer.source then
                if distanceBetween(origin, target.getCoords()) <= 25.0 then
                    out[#out + 1] = { id = target.source, name = target.name or target.playerName or "Inconnu" }
                end
            end
        end
    end

    return out
end)

local function finishInvoice(targetSource, accepted)
    local pending = pendingInvoices[targetSource]
    if not pending then return false end

    pendingInvoices[targetSource] = nil

    VFW.Society.Update("UPDATE society_customs_invoices SET status = ? WHERE id = ?", {
        accepted and "paid" or "rejected", pending.invoiceId or 0,
    })

    if accepted then
        persistProps(pending.plate, pending.vehicleProps)
        if VFW.Players[pending.mecano] then
            TriggerClientEvent("customs:invoicePaid", pending.mecano)
        end
    else
        if VFW.Players[pending.mecano] then
            TriggerClientEvent("customs:invoiceRejected", pending.mecano, pending.plate, pending.originalProps)
        end
    end

    return true
end

RegisterNetEvent("customs:createInvoice", function(targetServerId, payload)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local targetId = tonumber(targetServerId)
    if not targetId then return end

    local target = VFW.GetPlayerFromId(targetId)
    if not target or target.source == source then return end
    if type(payload) ~= "table" then return end
    if not isCustomsJob(xPlayer) then return end

    if distanceBetween(xPlayer.getCoords(), target.getCoords()) > 25.0 then
        xPlayer.showNotification({ type = "ROUGE", content = "Le client est trop loin." })
        return
    end

    if pendingInvoices[target.source] then
        xPlayer.showNotification({ type = "ROUGE", content = "Ce client a déjà une facture en attente." })
        return
    end

    local modifications = type(payload.modifications) == "table" and payload.modifications or {}
    local plate = type(payload.vehiclePlate) == "string" and payload.vehiclePlate:sub(1, 16) or ""
    local vehicleName = type(payload.vehicleName) == "string" and payload.vehicleName:sub(1, 120) or ""
    local vehicleProps = type(payload.vehicleProps) == "table" and payload.vehicleProps or {}
    local originalProps = type(payload.originalProps) == "table" and payload.originalProps or {}

    local total = computeTotal(modifications)
    local discount = tonumber(payload.discountPercent) or 0
    if discount < 0 then discount = 0 end
    if discount > 100 then discount = 100 end

    total = math.floor(total * (1 - discount / 100))

    if total <= 0 then
        xPlayer.showNotification({ type = "ROUGE", content = "Ce montant de facture n'est pas valide." })
        return
    end

    local items = {}
    for i = 1, #modifications do
        local mod = modifications[i]
        if type(mod) == "table" then
            items[#items + 1] = {
                name = tostring(mod.description or mod.type or "Modification"):sub(1, 120),
                price = mod.price or 0,
                quantity = 1,
            }
        end
    end

    local jobName = xPlayer.job and xPlayer.job.name or ""
    local society = VFW.Society.Get(jobName)

    local invoiceId = VFW.Society.Insert([[
        INSERT INTO society_customs_invoices
            (job, sender_id, target_id, plate, vehicle_name, total, status, vehicle_props, original_props)
        VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?)
    ]], {
        jobName, xPlayer.identifier or "", target.identifier or "", plate, vehicleName, total,
        VFW.DB.Encode(vehicleProps), VFW.DB.Encode(originalProps),
    })

    pendingInvoices[target.source] = {
        invoiceId = invoiceId,
        mecano = source,
        job = jobName,
        plate = plate,
        total = total,
        vehicleProps = vehicleProps,
        originalProps = originalProps,
        expires = os.time() + INVOICE_TIMEOUT,
    }

    local billing = VFW.Billing
    local billingInvoice = nil

    if billing and billing.Create and billing.Push then
        billingInvoice = billing.Create({
            targetIdentifier = target.identifier or "",
            senderIdentifier = xPlayer.identifier or "",
            senderName = xPlayer.name or xPlayer.playerName,
            receiverName = target.name or target.playerName,
            receiverCompany = target.job and target.job.label or "",
            society = jobName,
            societyLabel = VFW.Society.GetLabel(jobName),
            societyImage = society and society.image or "",
            billType = "customs",
            items = items,
            reduce = discount,
            total = total,
        })
    end

    if billingInvoice then
        billing.Push(target.source, billingInvoice)
    else
        TriggerClientEvent("nui:invoice:receive", target.source, {
            sender = xPlayer.name or xPlayer.playerName,
            receiver = target.name or target.playerName,
            receiverCompany = target.job and target.job.label or "",
            date = os.date("%d/%m/%Y %H:%M"),
            reduce = discount,
            items = items,
            societyName = VFW.Society.GetLabel(jobName),
            societyImage = society and society.image or "",
            billType = "customs",
            total = total,
        }, source)
    end

    SetTimeout(INVOICE_TIMEOUT * 1000, function()
        local pending = pendingInvoices[target.source]
        if pending and pending.invoiceId == invoiceId then
            finishInvoice(target.source, false)
        end
    end)
end)

RegisterNetEvent("vfw:invoice:payment")
AddEventHandler("vfw:invoice:payment", function()
    local source = source
    if pendingInvoices[source] then
        finishInvoice(source, true)
    end
end)

RegisterNetEvent("vfw:invoice:payLater")
AddEventHandler("vfw:invoice:payLater", function()
    local source = source
    if pendingInvoices[source] then
        finishInvoice(source, true)
    end
end)

RegisterNetEvent("vfw:invoice:reject")
AddEventHandler("vfw:invoice:reject", function()
    local source = source
    if pendingInvoices[source] then
        finishInvoice(source, false)
    end
end)

AddEventHandler("playerDropped", function()
    local source = source
    if pendingInvoices[source] then
        finishInvoice(source, false)
    end
    for plate, entry in pairs(tempProps) do
        if entry.owner == source then tempProps[plate] = nil end
    end
end)

AddEventHandler("vfw:playerLoaded", function(source)
    local target = source
    SetTimeout(3000, function()
        if not VFW.Players[target] then return end
        syncPrices(target)
        local xPlayer = VFW.GetPlayerFromId(target)
        if xPlayer and xPlayer.job then
            TriggerClientEvent("core:GetCommandeMecano", target, commandesByJob[xPlayer.job.name] or {})
        end
    end)
end)

AddEventHandler("vfw:setJob", function(source, job)
    if not job then return end
    TriggerClientEvent("core:GetCommandeMecano", source, commandesByJob[job.name] or {})
end)

MySQL.ready(function()
    loadPrices()
    loadCommandes()
end)
