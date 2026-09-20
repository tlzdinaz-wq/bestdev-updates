VFW.Billing = VFW.Billing or {}

local Billing = VFW.Billing
local Bank = VFW.Bank

local MAX_ITEMS = 40
local MAX_TOTAL = 10000000
local INVOICE_TTL = 1800

local PAY_LATER_JOBS = {
    ambulance = true,
    mecano = true,
}

local reportedQueries = {}

local function reportError(query, err)
    if reportedQueries[query] then return end
    reportedQueries[query] = true
    console.error(("[Billing] SQL: %s"):format(tostring(err)))
end

local function sqlSingle(query, params)
    local ok, res = pcall(MySQL.single.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlInsert(query, params)
    local ok, res = pcall(MySQL.insert.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlUpdate(query, params)
    local ok, res = pcall(MySQL.update.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

Billing.Single = sqlSingle
Billing.Insert = sqlInsert
Billing.Update = sqlUpdate

Billing.Cache = {}

function Billing.Now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function Billing.Text(value, limit)
    if type(value) ~= "string" then return "" end
    return value:sub(1, limit or 120)
end

function Billing.Int(value, min, max)
    value = tonumber(value)
    if not value then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    value = math.floor(value)
    if min and value < min then return nil end
    if max and value > max then return nil end
    return value
end

function Billing.NormalizeItems(raw)
    local items, computed = {}, 0
    if type(raw) ~= "table" then return items, computed end

    for i = 1, #raw do
        if #items >= MAX_ITEMS then break end
        local entry = raw[i]
        if type(entry) == "table" then
            local name = Billing.Text(entry.name or entry.label, 120)
            if name ~= "" then
                local quantity = Billing.Int(entry.quantity or entry.count, 1, 9999) or 1
                local price = Billing.Int(entry.price, 0, MAX_TOTAL) or 0
                items[#items + 1] = { name = name, quantity = quantity, price = price }
                computed = computed + (price * quantity)
            end
        end
    end

    return items, computed
end

function Billing.IsPoliceLike(jobName)
    if type(jobName) ~= "string" or jobName == "" then return false end

    if IsPoliceJob and IsPoliceJob(jobName) then return true end
    if IsLawEnforcementJob and IsLawEnforcementJob(jobName) then return true end

    if VFW.Society and VFW.Society.Get then
        local society = VFW.Society.Get(jobName)
        if type(society) == "table" and (society.type == "police" or society.type == "milice") then
            return true
        end
    end

    local job = VFW.Jobs and VFW.Jobs[jobName]
    if job and (job.type == "police" or job.type == "milice") then return true end

    return false
end

function Billing.CanPayLater(jobName)
    if type(jobName) ~= "string" or jobName == "" then return false end
    if PAY_LATER_JOBS[jobName] then return true end
    return Billing.IsPoliceLike(jobName)
end

function Billing.SocietyName(jobName)
    if Billing.CanPayLater(jobName) then return jobName end
    if Bank and Bank.SocietyLabel then return Bank.SocietyLabel(jobName) end
    return jobName
end

function Billing.SocietyImage(jobName)
    if type(jobName) ~= "string" or jobName == "" then return "" end
    if VFW.Society and VFW.Society.GetImage then
        local ok, image = pcall(VFW.Society.GetImage, jobName)
        if ok and type(image) == "string" then return image end
    end
    return ""
end

function Billing.HasSocietyPermission(xPlayer, permission)
    if not xPlayer then return false end
    if xPlayer.hasPermission("manage_jobs") then return true end

    local jobName = xPlayer.job and xPlayer.job.name
    if type(jobName) ~= "string" or jobName == "" then return false end

    local boss = Staff29 and Staff29.Boss
    if boss and boss.HasBossPermission then
        local ok, allowed = pcall(boss.HasBossPermission, xPlayer, jobName, permission)
        if ok then return allowed == true end
    end

    return xPlayer.job and xPlayer.job.grade_is_boss and true or false
end

function Billing.Store(invoice)
    Billing.Cache[invoice.id] = invoice
    return invoice
end

function Billing.Get(invoiceId)
    invoiceId = Billing.Int(invoiceId, 1, 2147483647)
    if not invoiceId then return nil end

    local cached = Billing.Cache[invoiceId]
    if cached then return cached end

    local row = sqlSingle("SELECT * FROM billing_invoices WHERE id = ?", { invoiceId })
    if not row then return nil end

    local invoice = {
        id = row.id,
        billingId = row.billing_id,
        targetIdentifier = row.target_identifier or "",
        senderIdentifier = row.sender_identifier or "",
        senderName = row.sender_name or "",
        receiverName = row.receiver_name or "",
        receiverCompany = row.receiver_company or "",
        society = row.society or "",
        societyLabel = row.society_label or "",
        societyImage = row.society_image or "",
        billType = row.bill_type or "invoice",
        items = VFW.DB.Decode(row.items, {}),
        reduce = tonumber(row.reduce) or 0,
        total = tonumber(row.total) or 0,
        status = row.status or "pending",
        receiptSender = tonumber(row.receipt_sender) == 1,
        receiptReceiver = tonumber(row.receipt_receiver) == 1,
        createdAt = os.time(),
        refusals = 0,
    }

    return Billing.Store(invoice)
end

function Billing.Create(payload)
    local items = type(payload.items) == "table" and payload.items or {}

    local id = sqlInsert([[
        INSERT INTO billing_invoices
            (target_identifier, sender_identifier, sender_name, receiver_name, receiver_company,
             society, society_label, society_image, bill_type, items, reduce, total, status,
             receipt_sender, receipt_receiver, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)
    ]], {
        payload.targetIdentifier or "",
        payload.senderIdentifier or "",
        payload.senderName or "",
        payload.receiverName or "",
        payload.receiverCompany or "",
        payload.society or "",
        payload.societyLabel or "",
        payload.societyImage or "",
        payload.billType or "invoice",
        VFW.DB.Encode(items),
        payload.reduce or 0,
        payload.total or 0,
        payload.receiptSender and 1 or 0,
        payload.receiptReceiver and 1 or 0,
        Billing.Now(),
    })

    if not id then return nil end

    local invoice = {
        id = id,
        billingId = nil,
        targetIdentifier = payload.targetIdentifier or "",
        senderIdentifier = payload.senderIdentifier or "",
        senderName = payload.senderName or "",
        receiverName = payload.receiverName or "",
        receiverCompany = payload.receiverCompany or "",
        society = payload.society or "",
        societyLabel = payload.societyLabel or "",
        societyImage = payload.societyImage or "",
        billType = payload.billType or "invoice",
        items = items,
        reduce = payload.reduce or 0,
        total = payload.total or 0,
        status = "pending",
        receiptSender = payload.receiptSender and true or false,
        receiptReceiver = payload.receiptReceiver and true or false,
        createdAt = os.time(),
        refusals = 0,
    }

    return Billing.Store(invoice)
end

function Billing.SetStatus(invoice, status, method)
    invoice.status = status

    if status == "paid" then
        sqlUpdate("UPDATE billing_invoices SET status = ?, payment_method = ?, paid_at = ? WHERE id = ?", {
            status, type(method) == "string" and method or "bank", Billing.Now(), invoice.id,
        })
    else
        sqlUpdate("UPDATE billing_invoices SET status = ? WHERE id = ?", { status, invoice.id })
    end
end

function Billing.RecordBilling(invoice, statut, kind)
    local id = sqlInsert([[
        INSERT INTO society_billings
            (job_name, sender, receiver, target_identifier, `date`, total, statut, `type`, items)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        invoice.society or "",
        invoice.senderName or "",
        invoice.receiverName or "",
        invoice.targetIdentifier or "",
        Billing.Now(),
        invoice.total or 0,
        statut or 0,
        kind or "invoice",
        VFW.DB.Encode(invoice.items or {}),
    })

    if id then
        invoice.billingId = id
        sqlUpdate("UPDATE billing_invoices SET billing_id = ? WHERE id = ?", { id, invoice.id })
    end

    return id
end

function Billing.Payload(invoice)
    return {
        sender = invoice.senderName or "",
        receiver = invoice.receiverName or "",
        receiverCompany = invoice.receiverCompany or "",
        date = os.date("%d/%m/%Y %H:%M"),
        reduce = invoice.reduce or 0,
        items = invoice.items or {},
        societyName = invoice.societyName or Billing.SocietyName(invoice.society),
        societyImage = invoice.societyImage or "",
        billType = invoice.billType,
        total = invoice.total or 0,
    }
end

function Billing.Push(targetSource, invoice)
    TriggerClientEvent("nui:invoice:receive", targetSource, Billing.Payload(invoice), invoice.id)
end

function Billing.Receipt(invoice)
    local items = {}
    local source = invoice.items or {}

    for i = 1, #source do
        items[i] = {
            name = source[i].name,
            quantity = source[i].quantity or 1,
            price = source[i].price or 0,
        }
    end

    return {
        title = "Recu",
        sender = invoice.senderName or "",
        receiver = invoice.receiverName or "",
        date = os.date("%d/%m/%Y %H:%M"),
        items = items,
        reduce = invoice.reduce or 0,
        total = invoice.total or 0,
        societyName = invoice.societyLabel ~= "" and invoice.societyLabel or Billing.SocietyName(invoice.society),
    }
end

function Billing.CreditSender(invoice, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local jobName = invoice.society or ""

    if jobName ~= "" and jobName ~= "unemployed" then
        Bank.AddSocietyMoney(jobName, amount)
        Bank.AddTransaction(Bank.SocietyIban(jobName), 2,
            ("Facture - %s"):format(invoice.receiverName or ""), "deposit", amount, true, true)

        local sender = VFW.GetPlayerFromIdentifier(invoice.senderIdentifier)
        if sender then
            sender.showNotification({
                type = "VERT",
                content = ("Facture de %d$ payee par %s."):format(amount, invoice.receiverName or "le client"),
            })
        end
        return
    end

    if invoice.senderIdentifier ~= "" then
        Bank.CreditIdentifier(invoice.senderIdentifier, amount, "banking:facture")
        local iban = Bank.EnsureIban("player", invoice.senderIdentifier, invoice.senderName or "")
        Bank.AddTransaction(iban, 1, ("Facture - %s"):format(invoice.receiverName or ""), "deposit", amount, true, true)
    end
end

function Billing.DebitReceiver(xPlayer, invoice, method)
    local amount = math.floor(tonumber(invoice.total) or 0)
    if amount <= 0 then return false, "Ce montant n'est pas valide." end

    if invoice.billType == "company" then
        local jobName = xPlayer.job and xPlayer.job.name
        if type(jobName) ~= "string" or jobName == "" or jobName == "unemployed" then
            return false, "Vous n'avez pas d'entreprise pour payer cette facture."
        end

        if not Bank.CanManageSociety(xPlayer, jobName) then
            return false, "Vous n'avez pas acces au compte de l'entreprise."
        end

        if not Bank.TakeSocietyMoney(jobName, amount) then
            return false, "Fonds insuffisants sur le compte de l'entreprise."
        end

        Bank.AddTransaction(Bank.SocietyIban(jobName), 2,
            ("Facture - %s"):format(invoice.senderName or ""), "purchase", amount, false, true)
        return true
    end

    if method == "cash" then
        if not Bank.TakeCash(xPlayer, amount) then
            return false, "Vous n'avez pas assez d'argent liquide."
        end
        return true
    end

    if Bank.GetBank(xPlayer) < amount then
        return false, "Fonds insuffisants sur votre compte."
    end

    xPlayer.removeAccountMoney("bank", amount, "banking:facture")
    Bank.AddTransaction(Bank.PlayerIban(xPlayer), 1,
        ("Facture - %s"):format(invoice.senderName or ""), "purchase", amount, false, true)
    return true
end

function Billing.Purge()
    local now = os.time()
    for id, invoice in pairs(Billing.Cache) do
        if invoice.status ~= "pending" and (now - (invoice.createdAt or now)) > INVOICE_TTL then
            Billing.Cache[id] = nil
        elseif (now - (invoice.createdAt or now)) > (INVOICE_TTL * 4) then
            Billing.Cache[id] = nil
        end
    end
end

CreateThread(function()
    while true do
        Wait(300000)
        Billing.Purge()
    end
end)

exports("CreateInvoice", function(targetIdentifier, senderIdentifier, society, items, total, billType)
    if type(targetIdentifier) ~= "string" or targetIdentifier == "" then return nil end

    local normalized = Billing.NormalizeItems(items)
    local amount = Billing.Int(total, 1, MAX_TOTAL)
    if not amount then return nil end

    local sender = VFW.GetPlayerFromIdentifier(senderIdentifier)
    local jobName = type(society) == "string" and society or ""

    local invoice = Billing.Create({
        targetIdentifier = targetIdentifier,
        senderIdentifier = type(senderIdentifier) == "string" and senderIdentifier or "",
        senderName = sender and sender.name or (Bank.SocietyLabel(jobName)),
        receiverName = "",
        receiverCompany = "",
        society = jobName,
        societyLabel = Bank.SocietyLabel(jobName),
        societyImage = Billing.SocietyImage(jobName),
        billType = type(billType) == "string" and billType or "invoice",
        items = normalized,
        reduce = 0,
        total = amount,
        receiptSender = false,
        receiptReceiver = false,
    })

    if not invoice then return nil end

    local target = VFW.GetPlayerFromIdentifier(targetIdentifier)
    if target then
        invoice.receiverName = target.name or ""
        invoice.receiverCompany = target.job and target.job.label or ""
        Billing.Push(target.source, invoice)
    else
        Billing.RecordBilling(invoice, 0, "invoice")
        Billing.SetStatus(invoice, "later")
    end

    return invoice.id
end)
