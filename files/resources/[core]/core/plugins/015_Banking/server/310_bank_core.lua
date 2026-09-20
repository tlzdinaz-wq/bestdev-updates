VFW.Bank = VFW.Bank or {}

local Bank = VFW.Bank

local MAX_AMOUNT = 999999999
local TRANSACTION_LIMIT = 60

local VALID_STATUS = {
    withdraw = true,
    deposit = true,
    transfer = true,
    salary = true,
    purchase = true,
}

local reportedQueries = {}

local function reportError(query, err)
    if reportedQueries[query] then return end
    reportedQueries[query] = true
    console.error(("[Banking] SQL: %s"):format(tostring(err)))
end

local function sqlQuery(query, params)
    local ok, res = pcall(MySQL.query.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
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

Bank.Query = sqlQuery
Bank.Single = sqlSingle
Bank.Insert = sqlInsert
Bank.Update = sqlUpdate

function Bank.Now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function Bank.Amount(value)
    value = tonumber(value)
    if not value then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    value = math.floor(value)
    if value <= 0 or value > MAX_AMOUNT then return nil end
    return value
end

local ibanByOwner = {}
local ownerByIban = {}

local function ownerKeyOf(ownerType, ownerKey)
    return ("%s|%s"):format(ownerType, ownerKey)
end

local function cacheIban(ownerType, ownerKey, iban, label)
    local entry = { type = ownerType, key = ownerKey, iban = iban, label = label or "" }
    ibanByOwner[ownerKeyOf(ownerType, ownerKey)] = entry
    ownerByIban[iban] = entry
    return entry
end

function Bank.LoadIbans()
    local rows = sqlQuery("SELECT iban, owner_type, owner_key, label FROM bank_ibans") or {}
    ibanByOwner = {}
    ownerByIban = {}
    for i = 1, #rows do
        local row = rows[i]
        if type(row.iban) == "string" and type(row.owner_key) == "string" then
            cacheIban(row.owner_type or "player", row.owner_key, row.iban, row.label)
        end
    end
    return #rows
end

local function generateIban()
    for _ = 1, 60 do
        local buffer = { tostring(math.random(1, 9)) }
        for _ = 1, 7 do
            buffer[#buffer + 1] = tostring(math.random(0, 9))
        end
        local iban = table.concat(buffer)
        if not ownerByIban[iban] then
            local exists = sqlSingle("SELECT iban FROM bank_ibans WHERE iban = ?", { iban })
            if not exists then return iban end
        end
    end
    return nil
end

function Bank.EnsureIban(ownerType, ownerKey, label)
    if type(ownerType) ~= "string" or ownerType == "" then return "" end
    if type(ownerKey) ~= "string" or ownerKey == "" then return "" end

    label = type(label) == "string" and label:sub(1, 120) or ""

    local cached = ibanByOwner[ownerKeyOf(ownerType, ownerKey)]
    if cached then
        if label ~= "" and cached.label ~= label then
            cached.label = label
            sqlUpdate("UPDATE bank_ibans SET label = ? WHERE iban = ?", { label, cached.iban })
        end
        return cached.iban
    end

    local row = sqlSingle("SELECT iban, label FROM bank_ibans WHERE owner_type = ? AND owner_key = ?", {
        ownerType, ownerKey,
    })

    if row and type(row.iban) == "string" then
        return cacheIban(ownerType, ownerKey, row.iban, row.label or label).iban
    end

    local iban = generateIban()
    if not iban then
        console.error("[Banking] impossible de generer un IBAN unique")
        return ""
    end

    sqlInsert("INSERT INTO bank_ibans (iban, owner_type, owner_key, label, created_at) VALUES (?, ?, ?, ?, ?)", {
        iban, ownerType, ownerKey, label, Bank.Now(),
    })

    return cacheIban(ownerType, ownerKey, iban, label).iban
end

function Bank.PlayerIban(xPlayer)
    if not xPlayer or type(xPlayer.identifier) ~= "string" then return "" end
    return Bank.EnsureIban("player", xPlayer.identifier, xPlayer.name or xPlayer.playerName or "")
end

function Bank.SocietyLabel(jobName)
    if VFW.Society and VFW.Society.GetLabel then
        local ok, label = pcall(VFW.Society.GetLabel, jobName)
        if ok and type(label) == "string" and label ~= "" then return label end
    end
    local job = VFW.Jobs and VFW.Jobs[jobName]
    if job and type(job.label) == "string" and job.label ~= "" then return job.label end
    return jobName or ""
end

function Bank.SocietyIban(jobName)
    if type(jobName) ~= "string" or jobName == "" then return "" end
    return Bank.EnsureIban("society", jobName, Bank.SocietyLabel(jobName))
end

function Bank.ResolveIban(iban)
    if type(iban) ~= "string" then return nil end
    iban = iban:gsub("%D", "")
    if #iban ~= 8 then return nil end

    local cached = ownerByIban[iban]
    if cached then return cached end

    local row = sqlSingle("SELECT iban, owner_type, owner_key, label FROM bank_ibans WHERE iban = ?", { iban })
    if not row or type(row.owner_key) ~= "string" then return nil end

    return cacheIban(row.owner_type or "player", row.owner_key, row.iban, row.label)
end

function Bank.AddTransaction(iban, accountType, label, status, value, positive, sync)
    if type(iban) ~= "string" or iban == "" then return end

    value = math.floor(tonumber(value) or 0)
    if value < 0 then value = -value end
    if value == 0 then return end

    if not VALID_STATUS[status] then status = "purchase" end

    local amount = (positive and "~g~+" or "~r~-") .. tostring(value)
    local query = [[
        INSERT INTO bank_transactions (iban, account_type, label, `status`, amount, `value`, positive, `date`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    local params = {
        iban,
        tonumber(accountType) == 2 and 2 or 1,
        tostring(label or ""):sub(1, 160),
        status,
        amount,
        value,
        positive and 1 or 0,
        Bank.Now(),
    }

    if sync then
        sqlInsert(query, params)
    else
        MySQL.insert(query, params)
    end
end

function Bank.GetTransactions(iban, limit)
    if type(iban) ~= "string" or iban == "" then return {} end

    local rows = sqlQuery([[
        SELECT label, status, amount, positive, DATE_FORMAT(`date`, '%Y-%m-%d %H:%i:%s') AS date
        FROM bank_transactions
        WHERE iban = ?
        ORDER BY id DESC
        LIMIT ?
    ]], { iban, tonumber(limit) or TRANSACTION_LIMIT }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            label = tostring(row.label or ""),
            status = VALID_STATUS[row.status] and row.status or "purchase",
            amount = tostring(row.amount or "0"),
            date = tostring(row.date or Bank.Now()),
            positive = tonumber(row.positive) == 1,
        }
    end

    return out
end

function Bank.GetStats(iban)
    if type(iban) ~= "string" or iban == "" then return {} end

    local rows = sqlQuery([[
        SELECT DATE_FORMAT(`date`, '%Y-%m-%d') AS name,
               SUM(CASE WHEN positive = 1 THEN `value` ELSE 0 END) AS deposit,
               SUM(CASE WHEN positive = 0 THEN `value` ELSE 0 END) AS withdraw
        FROM bank_transactions
        WHERE iban = ?
        GROUP BY name
        ORDER BY name DESC
        LIMIT 7
    ]], { iban }) or {}

    local out = {}
    for i = #rows, 1, -1 do
        local row = rows[i]
        out[#out + 1] = {
            name = tostring(row.name or ""),
            deposit = math.floor(tonumber(row.deposit) or 0),
            withdraw = math.floor(tonumber(row.withdraw) or 0),
        }
    end

    return out
end

function Bank.GetSocietyMoney(jobName)
    if type(jobName) ~= "string" or jobName == "" then return 0 end
    local row = sqlSingle("SELECT money FROM society_accounts WHERE job_name = ?", { jobName })
    return math.floor(tonumber(row and row.money) or 0)
end

function Bank.SetSocietyMoney(jobName, money)
    if type(jobName) ~= "string" or jobName == "" then return 0 end
    money = math.floor(tonumber(money) or 0)
    if money < 0 then money = 0 end

    sqlUpdate([[
        INSERT INTO society_accounts (job_name, money) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE money = VALUES(money)
    ]], { jobName, money })

    return money
end

function Bank.AddSocietyMoney(jobName, amount)
    if type(jobName) ~= "string" or jobName == "" then return 0 end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return Bank.GetSocietyMoney(jobName) end

    sqlUpdate([[
        INSERT INTO society_accounts (job_name, money) VALUES (?, GREATEST(?, 0))
        ON DUPLICATE KEY UPDATE money = GREATEST(money + ?, 0)
    ]], { jobName, amount, amount })

    return Bank.GetSocietyMoney(jobName)
end

function Bank.TakeSocietyMoney(jobName, amount)
    if type(jobName) ~= "string" or jobName == "" then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local affected = sqlUpdate(
        "UPDATE society_accounts SET money = money - ? WHERE job_name = ? AND money >= ?",
        { amount, jobName, amount }
    )

    return (tonumber(affected) or 0) > 0
end

function Bank.GetCash(xPlayer)
    if not xPlayer then return 0 end

    local Inv = VFW.Inventory
    if Inv and Inv.PlayerList and Inv.CountByName then
        local ok, count = pcall(function()
            return Inv.CountByName(Inv.PlayerList(xPlayer), "money")
        end)
        if ok then return math.floor(tonumber(count) or 0) end
    end

    local item = xPlayer.getInventoryItem("money")
    return item and math.floor(tonumber(item.count) or 0) or 0
end

function Bank.GiveCash(xPlayer, amount)
    if not xPlayer then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local Inv = VFW.Inventory
    if Inv and Inv.PlayerList and Inv.AddToList then
        local ok, added = pcall(function()
            local list = Inv.PlayerList(xPlayer)
            local result = Inv.AddToList(list, "money", amount, nil, Inv.PlayerMaxSlots)
            if result > 0 and Inv.PushPlayer then Inv.PushPlayer(xPlayer) end
            return result
        end)
        if ok and (tonumber(added) or 0) > 0 then return true end
        if ok then return false end
    end

    return xPlayer.addInventoryItem("money", amount, nil, false) and true or false
end

function Bank.TakeCash(xPlayer, amount)
    if not xPlayer then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local Inv = VFW.Inventory
    if Inv and Inv.PlayerList and Inv.RemoveByName then
        local ok, removed = pcall(function()
            local list = Inv.PlayerList(xPlayer)
            if Inv.CountByName(list, "money") < amount then return 0 end
            local result = Inv.RemoveByName(list, "money", amount)
            if result > 0 and Inv.PushPlayer then Inv.PushPlayer(xPlayer) end
            return result
        end)
        if ok then return (tonumber(removed) or 0) >= amount end
    end

    return xPlayer.removeInventoryItem("money", amount, nil, false) and true or false
end

function Bank.GetBank(xPlayer)
    if not xPlayer then return 0 end
    local account = xPlayer.getAccount("bank")
    return math.floor(tonumber(account and account.money) or 0)
end

function Bank.CreditIdentifier(identifier, amount, reason)
    if type(identifier) ~= "string" or identifier == "" then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local target = VFW.GetPlayerFromIdentifier(identifier)
    if target then
        target.addAccountMoney("bank", amount, reason or "banking:transfer")
        return true
    end

    local row = sqlSingle("SELECT accounts FROM characters WHERE identifier = ?", { identifier })
    if not row then return false end

    target = VFW.GetPlayerFromIdentifier(identifier)
    if target then
        target.addAccountMoney("bank", amount, reason or "banking:transfer")
        return true
    end

    local accounts = VFW.DB.Decode(row.accounts, {})
    if type(accounts) ~= "table" then accounts = {} end

    local found = false
    for i = 1, #accounts do
        if accounts[i].name == "bank" then
            accounts[i].money = (tonumber(accounts[i].money) or 0) + amount
            found = true
            break
        end
    end

    if not found then
        accounts[#accounts + 1] = { name = "bank", money = amount, label = "Banque", round = true }
    end

    sqlUpdate("UPDATE characters SET accounts = ? WHERE identifier = ?", {
        VFW.DB.Encode(accounts), identifier,
    })

    return true
end

function Bank.SocietyJobName(xPlayer)
    if not xPlayer then return nil end
    local job = xPlayer.job
    if not job or type(job.name) ~= "string" or job.name == "" then return nil end
    if job.name == "unemployed" then return nil end
    return job.name
end

function Bank.CanManageSociety(xPlayer, jobName)
    if not xPlayer or type(jobName) ~= "string" or jobName == "" then return false end
    if xPlayer.hasPermission("manage_jobs") then return true end

    local boss = Staff29 and Staff29.Boss
    if boss and boss.HasBossPermission then
        local ok, allowed = pcall(boss.HasBossPermission, xPlayer, jobName, "accounting")
        if ok then return allowed == true end
    end

    local job = xPlayer.job
    if job and job.name == jobName and job.grade_is_boss then return true end
    if xPlayer.job2 and xPlayer.job2.name == jobName and xPlayer.job2.grade_is_boss then return true end

    return false
end

function Bank.Notify(xPlayer, kind, message)
    if not xPlayer then return end
    xPlayer.showNotification({ type = kind, content = message })
end

function Bank.Log(channel, title, description)
    if VFW.Logs and VFW.Logs.Send then
        VFW.Logs.Send(channel, { title = title, description = description })
    end
end

local lastBankBalance = {}

local function statusFromReason(reason, positive)
    reason = type(reason) == "string" and reason:lower() or ""

    if reason:find("paycheck", 1, true) or reason:find("salaire", 1, true) or reason:find("salary", 1, true) then
        return "salary"
    end
    if reason:find("transfer", 1, true) or reason:find("virement", 1, true) then
        return "transfer"
    end
    if reason:find("withdraw", 1, true) or reason:find("retrait", 1, true) then
        return "withdraw"
    end
    if reason:find("deposit", 1, true) or reason:find("depot", 1, true) then
        return "deposit"
    end

    return positive and "deposit" or "purchase"
end

local function labelFromReason(reason, positive)
    if type(reason) == "string" and reason ~= "" then
        return reason:sub(1, 120)
    end
    return positive and "Credit" or "Debit"
end

AddEventHandler("vfw:setAccountMoney", function(source, name, money, reason)
    if name ~= "bank" then return end
    if type(reason) == "string" and reason:sub(1, 8) == "banking:" then
        lastBankBalance[source] = math.floor(tonumber(money) or 0)
        return
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    money = math.floor(tonumber(money) or 0)
    local previous = lastBankBalance[source]
    lastBankBalance[source] = money

    if previous == nil then return end

    local delta = money - previous
    if delta == 0 then return end

    local positive = delta > 0
    local iban = Bank.PlayerIban(xPlayer)
    if iban == "" then return end

    Bank.AddTransaction(iban, 1, labelFromReason(reason, positive), statusFromReason(reason, positive),
        positive and delta or -delta, positive, false)
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    lastBankBalance[source] = Bank.GetBank(xPlayer)

    SetTimeout(4000, function()
        local player = VFW.GetPlayerFromId(source)
        if not player then return end
        Bank.PlayerIban(player)
    end)
end)

AddEventHandler("vfw:playerDropped", function(source)
    lastBankBalance[source] = nil
end)

exports("GetAccount", function(identifier)
    if type(identifier) ~= "string" then return nil end
    local iban = Bank.EnsureIban("player", identifier, "")
    if iban == "" then return nil end

    local player = VFW.GetPlayerFromIdentifier(identifier)
    if player then
        return { iban = iban, bank = Bank.GetBank(player), label = player.name or "" }
    end

    local row = sqlSingle("SELECT accounts, firstname, lastname FROM characters WHERE identifier = ?", { identifier })
    if not row then return { iban = iban, bank = 0, label = "" } end

    local accounts = VFW.DB.Decode(row.accounts, {})
    local money = 0
    if type(accounts) == "table" then
        for i = 1, #accounts do
            if accounts[i].name == "bank" then
                money = math.floor(tonumber(accounts[i].money) or 0)
                break
            end
        end
    end

    return { iban = iban, bank = money, label = ("%s %s"):format(row.firstname or "", row.lastname or "") }
end)

exports("GetSocietyAccount", function(jobName)
    if type(jobName) ~= "string" or jobName == "" then return nil end
    return {
        iban = Bank.SocietyIban(jobName),
        bank = Bank.GetSocietyMoney(jobName),
        label = Bank.SocietyLabel(jobName),
    }
end)

exports("AddBankTransaction", function(iban, label, status, amount, positive)
    Bank.AddTransaction(iban, 1, label, status, amount, positive and true or false, false)
    return true
end)

exports("ResolveIban", function(iban)
    local entry = Bank.ResolveIban(iban)
    if not entry then return nil end
    return { type = entry.type, ref = entry.key, label = entry.label, iban = entry.iban }
end)

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 60000 do
        Wait(250)
        waited = waited + 250
    end

    math.randomseed(os.time() + GetGameTimer())
    local count = Bank.LoadIbans() or 0
    console.init("Banking", ("%d IBAN charge(s)"):format(count))
end)
