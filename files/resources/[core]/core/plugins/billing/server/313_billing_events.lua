local Billing = VFW.Billing
local Bank = VFW.Bank

local MAX_TOTAL = 10000000
local MAX_REFUSALS = 3
local SEND_COOLDOWN = 1000

local lastSend = {}
local recuPending = {}

local function registerCallback(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[%s] callback '%s' deja enregistre : %s"):format("Billing", name, tostring(err)))
        return false
    end
    return true
end


local function notify(xPlayer, kind, message)
    if not xPlayer then return end
    xPlayer.showNotification({ type = kind, content = message })
end

local function distanceBetween(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function logInvoice(channel, title, description)
    if VFW.Logs and VFW.Logs.Send then
        VFW.Logs.Send(channel, { title = title, description = description })
    end
end

local function resolveInvoice(xPlayer, handle)
    local invoice = Billing.Get(handle)
    if not invoice then return nil end
    if invoice.targetIdentifier ~= xPlayer.identifier then return nil end
    return invoice
end

registerCallback("vfw:invoice:getName", function(source, targetServerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return "", "", "" end

    local targetId = tonumber(targetServerId)
    if not targetId then return "", "", "" end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return "", "", "" end

    local jobName = xPlayer.job and xPlayer.job.name or ""

    return target.name or "", Billing.SocietyImage(jobName), target.job and target.job.label or ""
end)

RegisterNetEvent("vfw:invoice:send", function(data, targetServerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local now = GetGameTimer()
    if lastSend[source] and (now - lastSend[source]) < SEND_COOLDOWN then return end
    lastSend[source] = now

    local targetId = tonumber(targetServerId)
    if not targetId then
        notify(xPlayer, "ROUGE", "Destinataire introuvable.")
        return
    end

    local target = VFW.GetPlayerFromId(targetId)
    if not target or target.source == source then
        notify(xPlayer, "ROUGE", "Destinataire introuvable.")
        return
    end

    if distanceBetween(xPlayer.getCoords(), target.getCoords()) > 15.0 then
        notify(xPlayer, "ROUGE", "Le destinataire est trop loin.")
        return
    end

    local jobName = xPlayer.job and xPlayer.job.name or ""
    if jobName == "" or jobName == "unemployed" then
        notify(xPlayer, "ROUGE", "Vous n'avez pas d'entreprise.")
        return
    end

    local billType = "invoice"
    if data.billType == "personal" or data.billType == "company" then
        billType = data.billType
    end

    if billType == "personal" and not Billing.HasSocietyPermission(xPlayer, "create_invoice") then
        notify(xPlayer, "ROUGE", "Vous n'avez pas la permission de facturer.")
        return
    end

    if billType == "company" and not Billing.HasSocietyPermission(xPlayer, "create_invoice_company") then
        notify(xPlayer, "ROUGE", "Vous n'avez pas la permission de facturer une entreprise.")
        return
    end

    if billType == "company" then
        local targetJob = target.job and target.job.name or ""
        if targetJob == "" or targetJob == "unemployed" then
            notify(xPlayer, "ROUGE", "Ce citoyen n'a pas d'entreprise.")
            return
        end
    end

    local items, computed = Billing.NormalizeItems(data.items)

    local total = Billing.Int(data.total, 1, MAX_TOTAL)
    if not total then
        notify(xPlayer, "ROUGE", "Ce montant de facture n'est pas valide.")
        return
    end

    if computed > 0 and total > computed then
        total = computed
    end

    local reduce = Billing.Int(data.reduce, 0, 100) or 0

    local invoice = Billing.Create({
        targetIdentifier = target.identifier,
        senderIdentifier = xPlayer.identifier,
        senderName = xPlayer.name or "",
        receiverName = target.name or "",
        receiverCompany = target.job and target.job.label or "",
        society = jobName,
        societyLabel = Bank.SocietyLabel(jobName),
        societyImage = Billing.SocietyImage(jobName),
        billType = billType,
        items = items,
        reduce = reduce,
        total = total,
        receiptSender = data.receiptSender and true or false,
        receiptReceiver = data.receiptReceiver and true or false,
    })

    if not invoice then
        notify(xPlayer, "ROUGE", "Impossible de creer la facture.")
        return
    end

    invoice.senderSource = source

    Billing.Push(target.source, invoice)

    notify(xPlayer, "VERT", ("Facture de %d$ envoyee a %s."):format(total, target.name or ""))

    logInvoice("general.facturation", "Facture emise",
        ("Emetteur : %s\nDestinataire : %s\nEntreprise : `%s`\nMontant : `%d`\nType : `%s`"):format(
            VFW.Logs.Describe(source), VFW.Logs.Describe(target.source), jobName, total, billType))
end)

RegisterNetEvent("vfw:invoice:payment", function(data, sender)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local invoice = resolveInvoice(xPlayer, sender)
    if not invoice then return end
    if invoice.status ~= "pending" and invoice.status ~= "later" then return end
    if invoice.paying then return end
    invoice.paying = true

    local method = "bank"
    if invoice.billType == "company" then
        method = "bank"
    elseif type(data) == "table" and data.method == "cash" then
        method = "cash"
    end

    local ok, err = Billing.DebitReceiver(xPlayer, invoice, method)
    if not ok then
        invoice.paying = nil
        notify(xPlayer, "ROUGE", err or "Paiement impossible.")

        logInvoice("general.facturationfail", "Facture impayee",
            ("Payeur : %s\nMontant : `%d`\nRaison : %s"):format(
                VFW.Logs.Describe(source), invoice.total or 0, tostring(err)))

        Billing.Push(source, invoice)
        return
    end

    Billing.CreditSender(invoice, invoice.total)
    Billing.SetStatus(invoice, "paid", method)

    if invoice.billingId then
        Billing.Update("UPDATE society_billings SET statut = 1 WHERE id = ?", { invoice.billingId })
    else
        Billing.RecordBilling(invoice, 1, "invoice")
    end

    notify(xPlayer, "VERT", ("Facture de %d$ payee."):format(invoice.total or 0))

    logInvoice("general.facturationreussie", "Facture payee",
        ("Payeur : %s\nEmetteur : `%s`\nEntreprise : `%s`\nMontant : `%d`\nMoyen : `%s`"):format(
            VFW.Logs.Describe(source), invoice.senderName or "", invoice.society or "",
            invoice.total or 0, method))

    local senderPlayer = VFW.GetPlayerFromIdentifier(invoice.senderIdentifier)

    if invoice.receiptSender and senderPlayer then
        TriggerClientEvent("vfw:invoice:open", senderPlayer.source, Billing.Receipt(invoice))
    end

    if invoice.receiptReceiver then
        if senderPlayer then
            recuPending[senderPlayer.source] = invoice.id
            TriggerClientEvent("vfw:invoice:sendRecu", senderPlayer.source)
        else
            TriggerClientEvent("vfw:invoice:open", source, Billing.Receipt(invoice))
        end
    end
end)

RegisterNetEvent("vfw:invoice:sendRecu", function(targetServerId, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local invoiceId = recuPending[source]
    if not invoiceId then return end
    recuPending[source] = nil

    local invoice = Billing.Get(invoiceId)
    if not invoice then return end
    if invoice.senderIdentifier ~= xPlayer.identifier then return end
    if invoice.status ~= "paid" then return end

    local target = VFW.GetPlayerFromIdentifier(invoice.targetIdentifier)
    if not target then return end

    local requestedId = tonumber(targetServerId)
    if requestedId and requestedId ~= target.source then return end

    if type(data) == "table" and data.reduce ~= nil then
        local reduce = Billing.Int(data.reduce, 0, 100)
        if reduce then invoice.reduce = reduce end
    end

    TriggerClientEvent("vfw:invoice:open", target.source, Billing.Receipt(invoice))
end)

RegisterNetEvent("vfw:invoice:payLater", function(sender)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local invoice = resolveInvoice(xPlayer, sender)
    if not invoice then return end
    if invoice.status ~= "pending" then return end

    if not Billing.CanPayLater(invoice.society) then
        invoice.refusals = (invoice.refusals or 0) + 1

        if invoice.refusals < MAX_REFUSALS then
            notify(xPlayer, "ROUGE", "Cette facture doit etre reglee immediatement.")
            Billing.Push(source, invoice)
            return
        end
    end

    Billing.SetStatus(invoice, "later")
    Billing.RecordBilling(invoice, 0, "invoice")

    notify(xPlayer, "ORANGE", ("Facture de %d$ mise en attente de paiement."):format(invoice.total or 0))

    local senderPlayer = VFW.GetPlayerFromIdentifier(invoice.senderIdentifier)
    if senderPlayer then
        senderPlayer.showNotification({
            type = "ORANGE",
            content = ("%s reglera la facture plus tard."):format(invoice.receiverName or "Le client"),
        })
    end

    logInvoice("general.facturation", "Facture reportee",
        ("Client : %s\nEntreprise : `%s`\nMontant : `%d`"):format(
            VFW.Logs.Describe(source), invoice.society or "", invoice.total or 0))
end)

RegisterNetEvent("vfw:invoice:reject", function(sender)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local invoice = resolveInvoice(xPlayer, sender)
    if not invoice then return end
    if invoice.status ~= "pending" then return end

    Billing.SetStatus(invoice, "rejected")

    notify(xPlayer, "ROUGE", "Vous avez refuse la facture.")

    local senderPlayer = VFW.GetPlayerFromIdentifier(invoice.senderIdentifier)
    if senderPlayer then
        senderPlayer.showNotification({
            type = "ROUGE",
            content = ("%s a refuse votre facture de %d$."):format(
                invoice.receiverName or "Le client", invoice.total or 0),
        })
    end

    logInvoice("general.facturationfail", "Facture refusee",
        ("Client : %s\nEntreprise : `%s`\nMontant : `%d`"):format(
            VFW.Logs.Describe(source), invoice.society or "", invoice.total or 0))
end)

AddEventHandler("playerDropped", function()
    local source = source
    lastSend[source] = nil
    recuPending[source] = nil
end)
