VFW.Fines = VFW.Fines or {}

local Fines = VFW.Fines
local Bank = VFW.Bank

local MAX_FINE = 5000000
local RESPONSE_DELAY = 31000

local reportedQueries = {}

local function reportError(query, err)
    if reportedQueries[query] then return end
    reportedQueries[query] = true
    console.error(("[Fines] SQL: %s"):format(tostring(err)))
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

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function toInt(value, min, max)
    value = tonumber(value)
    if not value then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    value = math.floor(value)
    if min and value < min then return nil end
    if max and value > max then return nil end
    return value
end

local function text(value, limit)
    if type(value) ~= "string" then return "" end
    return value:sub(1, limit or 128)
end

function Fines.GetType(fineId)
    fineId = toInt(fineId, 1, 100000)
    if not fineId then return nil end

    local list = Config and Config.FineTypes
    if type(list) ~= "table" then return nil end

    for i = 1, #list do
        if tonumber(list[i].id) == fineId then return list[i] end
    end

    return nil
end

local function toBilling(row)
    local target = VFW.GetPlayerFromIdentifier(row.target_identifier)

    local id = sqlInsert([[
        INSERT INTO society_billings
            (job_name, sender, receiver, target_identifier, `date`, total, statut, `type`, items)
        VALUES (?, ?, ?, ?, ?, ?, 0, 'amende', ?)
    ]], {
        row.job_name or "",
        row.officer_name or "Police",
        target and target.name or "",
        row.target_identifier or "",
        now(),
        tonumber(row.amount) or 0,
        VFW.DB.Encode({ { name = row.offense or "Amende", quantity = 1, price = tonumber(row.amount) or 0 } }),
    })

    if id then
        sqlUpdate("UPDATE police_fines SET billing_id = ? WHERE id = ?", { id, row.id })
    end

    return id
end

function Fines.MarkUnpaid(fineId)
    local row = sqlSingle("SELECT * FROM police_fines WHERE id = ?", { fineId })
    if not row or row.status ~= "pending" then return false end

    sqlUpdate("UPDATE police_fines SET status = 'unpaid' WHERE id = ?", { fineId })

    if not row.billing_id then
        toBilling(row)
    end

    local target = VFW.GetPlayerFromIdentifier(row.target_identifier)
    if target then
        target.showNotification({
            type = "ORANGE",
            content = ("Amende de %d$ mise en impayee."):format(tonumber(row.amount) or 0),
        })
    end

    return true
end

function Fines.Create(officer, targetSource, data)
    if type(data) ~= "table" then return nil end

    local target = VFW.GetPlayerFromId(tonumber(targetSource) or 0)
    if not target then return nil end

    local preset = Fines.GetType(data.fineId or data.id)

    local amount = toInt(data.amount, 1, MAX_FINE) or (preset and toInt(preset.amount, 1, MAX_FINE))
    if not amount then return nil end

    local offense = text(data.offense or data.label or (preset and preset.label), 128)
    if offense == "" then offense = "Infraction" end

    local category = text(data.category or (preset and preset.category), 64)
    local jobName = officer and officer.job and officer.job.name or ""

    local fineId = sqlInsert([[
        INSERT INTO police_fines
            (target_identifier, officer_identifier, officer_name, job_name, fine_id,
             offense, category, amount, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
    ]], {
        target.identifier,
        officer and officer.identifier or "",
        officer and officer.name or "Police",
        jobName,
        toInt(data.fineId or data.id, 0, 100000) or 0,
        offense,
        category,
        amount,
        now(),
    })

    if not fineId then return nil end

    TriggerClientEvent("police:fine:received", target.source, {
        billId = fineId,
        amount = amount,
        offense = offense,
        category = category,
    })

    if officer then
        officer.showNotification({
            type = "VERT",
            content = ("Amende de %d$ envoyee a %s."):format(amount, target.name or ""),
        })
    end

    SetTimeout(RESPONSE_DELAY, function()
        Fines.MarkUnpaid(fineId)
    end)

    return fineId
end

function Fines.Cancel(fineId, officer)
    fineId = toInt(fineId, 1, 2147483647)
    if not fineId then return false end

    local row = sqlSingle("SELECT * FROM police_fines WHERE id = ?", { fineId })
    if not row or row.status == "cancelled" or row.status == "paid" then return false end

    sqlUpdate("UPDATE police_fines SET status = 'cancelled', cancelled_at = ? WHERE id = ?", { now(), fineId })

    if row.billing_id then
        sqlUpdate("UPDATE society_billings SET statut = 2 WHERE id = ?", { row.billing_id })
    end

    local target = VFW.GetPlayerFromIdentifier(row.target_identifier)
    if target then
        TriggerClientEvent("police:fine:cancelled", target.source, {
            offense = row.offense or "",
            category = row.category or "",
            amount = tonumber(row.amount) or 0,
        })
    end

    if officer then
        officer.showNotification({ type = "VERT", content = "Amende annulee." })
    end

    return true
end

local function payFine(xPlayer, row)
    local amount = toInt(row.amount, 1, MAX_FINE)
    if not amount then return false, "Ce montant n'est pas valide." end

    if Bank.GetBank(xPlayer) >= amount then
        xPlayer.removeAccountMoney("bank", amount, "banking:amende")
        Bank.AddTransaction(Bank.PlayerIban(xPlayer), 1,
            ("Amende - %s"):format(row.offense or ""), "purchase", amount, false, true)
        return true
    end

    if Bank.GetCash(xPlayer) >= amount then
        if Bank.TakeCash(xPlayer, amount) then
            return true
        end
    end

    return false, "Fonds insuffisants."
end

RegisterNetEvent("police:fine:pay", function(billId, amount)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = toInt(billId, 1, 2147483647)
    if not id then return end
    if amount ~= nil and type(amount) ~= "number" and type(amount) ~= "string" then return end

    local row = sqlSingle("SELECT * FROM police_fines WHERE id = ?", { id })

    if row then
        if row.target_identifier ~= xPlayer.identifier then return end
        if row.status ~= "pending" and row.status ~= "unpaid" then return end

        local claimed = sqlUpdate([[
            UPDATE police_fines SET status = 'paid', paid_at = ?
            WHERE id = ? AND status IN ('pending', 'unpaid')
        ]], { now(), id })
        if (tonumber(claimed) or 0) <= 0 then return end

        local ok, err = payFine(xPlayer, row)
        if not ok then
            sqlUpdate("UPDATE police_fines SET status = ?, paid_at = NULL WHERE id = ?", { row.status, id })
            xPlayer.showNotification({ type = "ROUGE", content = err or "Paiement impossible." })
            Fines.MarkUnpaid(id)
            return
        end

        if row.billing_id then
            sqlUpdate("UPDATE society_billings SET statut = 1 WHERE id = ?", { row.billing_id })
        end

        local jobName = row.job_name or ""
        if jobName ~= "" then
            Bank.AddSocietyMoney(jobName, tonumber(row.amount) or 0)
            Bank.AddTransaction(Bank.SocietyIban(jobName), 2,
                ("Amende - %s"):format(xPlayer.name or ""), "deposit", tonumber(row.amount) or 0, true, true)
        end

        xPlayer.showNotification({
            type = "VERT",
            content = ("Amende de %d$ payee."):format(tonumber(row.amount) or 0),
        })
        return
    end

    local billing = sqlSingle([[
        SELECT id, job_name, total, statut, target_identifier, `type`
        FROM society_billings WHERE id = ?
    ]], { id })

    if not billing then return end
    if billing.target_identifier ~= xPlayer.identifier then return end
    if tonumber(billing.statut) ~= 0 then return end
    if billing.type ~= "amende" and billing.type ~= "fine" then return end

    local claimed = sqlUpdate("UPDATE society_billings SET statut = 1 WHERE id = ? AND statut = 0", { id })
    if (tonumber(claimed) or 0) <= 0 then return end

    local ok, err = payFine(xPlayer, { amount = billing.total, offense = "Amende" })
    if not ok then
        sqlUpdate("UPDATE society_billings SET statut = 0 WHERE id = ?", { id })
        xPlayer.showNotification({ type = "ROUGE", content = err or "Paiement impossible." })
        return
    end

    local jobName = billing.job_name or ""
    if jobName ~= "" then
        Bank.AddSocietyMoney(jobName, tonumber(billing.total) or 0)
        Bank.AddTransaction(Bank.SocietyIban(jobName), 2,
            ("Amende - %s"):format(xPlayer.name or ""), "deposit", tonumber(billing.total) or 0, true, true)
    end

    xPlayer.showNotification({
        type = "VERT",
        content = ("Amende de %d$ payee."):format(tonumber(billing.total) or 0),
    })
end)

VFW.Ppa = VFW.Ppa or {}

function VFW.Ppa.Set(identifier, granted, label, officer)
    if type(identifier) ~= "string" or identifier == "" then return false end

    label = text(label, 120)
    if label == "" then label = "PPA" end

    if granted then
        sqlUpdate([[
            INSERT INTO police_ppa (identifier, label, granted_by, granted_at) VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE label = VALUES(label), granted_by = VALUES(granted_by), granted_at = VALUES(granted_at)
        ]], { identifier, label, officer and officer.identifier or "", now() })
    else
        sqlUpdate("DELETE FROM police_ppa WHERE identifier = ?", { identifier })
    end

    local target = VFW.GetPlayerFromIdentifier(identifier)
    if target then
        if granted then
            target.addLicense("ppa", label)
        else
            target.removeLicense("ppa")
        end

        TriggerClientEvent("police:ppa:notify", target.source, {
            granted = granted and true or false,
            ppaLabel = label,
        })
    end

    return true
end

function VFW.Ppa.Has(identifier)
    if type(identifier) ~= "string" or identifier == "" then return false end
    local row = sqlSingle("SELECT identifier FROM police_ppa WHERE identifier = ?", { identifier })
    return row ~= nil
end

exports("CreateFine", function(officerSource, targetSource, data)
    local officer = VFW.GetPlayerFromId(tonumber(officerSource) or 0)
    return Fines.Create(officer, targetSource, data)
end)

exports("CancelFine", function(fineId, officerSource)
    local officer = VFW.GetPlayerFromId(tonumber(officerSource) or 0)
    return Fines.Cancel(fineId, officer)
end)

exports("SetPPA", function(identifier, granted, label, officerSource)
    local officer = VFW.GetPlayerFromId(tonumber(officerSource) or 0)
    return VFW.Ppa.Set(identifier, granted, label, officer)
end)
