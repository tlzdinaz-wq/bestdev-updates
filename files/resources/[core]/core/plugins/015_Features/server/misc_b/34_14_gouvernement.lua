local GOUV_JOBS = { "gouvernement", "gouvernement_cayo", "gouv", "mairie" }
local JUSTICE_JOBS = { "justice", "doj", "juge", "avocat" }

local function gouv(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not MiscB.HasJob(xPlayer, GOUV_JOBS) then return nil end
    return xPlayer
end

local function justice(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not MiscB.HasJob(xPlayer, JUSTICE_JOBS) then return nil end
    return xPlayer
end

local function gradePerms(jobName, grade)
    local row = MiscB.Single(
        "SELECT permissions FROM gouv_grade_permissions WHERE job_name = ? AND grade = ? LIMIT 1",
        { jobName, grade }
    )
    if not row then return {} end
    local decoded = VFW.DB.Decode(row.permissions, {})
    return type(decoded) == "table" and decoded or {}
end

local function employeePerms(identifier)
    local row = MiscB.Single(
        "SELECT permissions FROM gouv_employee_permissions WHERE identifier = ? LIMIT 1",
        { identifier }
    )
    if not row then return {} end
    local decoded = VFW.DB.Decode(row.permissions, {})
    return type(decoded) == "table" and decoded or {}
end

local function gradeLabelFor(jobName, grade)
    local job = VFW.Jobs and VFW.Jobs[jobName]
    local grades = job and job.grades
    local entry = grades and grades[tostring(tonumber(grade) or 0)]
    return (entry and entry.label) or tostring(grade or 0)
end

local function hasPerm(xPlayer, perm)
    if MiscB.IsBoss(xPlayer) then return true end
    local perms = employeePerms(xPlayer.identifier)
    if perms[perm] ~= nil then return perms[perm] == true end
    local grade = gradePerms(MiscB.JobName(xPlayer), MiscB.GradeLevel(xPlayer))
    return grade[perm] == true
end

MiscB.Cb("gouvernement:getPlayerPermissions", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local merged = gradePerms(MiscB.JobName(xPlayer), MiscB.GradeLevel(xPlayer))
    for key, value in pairs(employeePerms(xPlayer.identifier)) do merged[key] = value end
    merged.isBoss = MiscB.IsBoss(xPlayer)
    return merged
end)

MiscB.Cb("gouvernement:checkPerm", function(source, permission)
    local xPlayer = gouv(source)
    if not xPlayer then return false end
    local perm = MiscB.Str(permission, 64)
    if not perm then return false end
    return hasPerm(xPlayer, perm)
end)

MiscB.Cb("gouvernement:getGradesPermissions", function(source)
    local xPlayer = gouv(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    local rows = MiscB.Query(
        "SELECT grade, permissions FROM gouv_grade_permissions WHERE job_name = ? ORDER BY grade ASC",
        { MiscB.JobName(xPlayer) }
    )
    for i = 1, #rows do rows[i].permissions = VFW.DB.Decode(rows[i].permissions, {}) end
    return rows
end)

MiscB.Cb("gouvernement:updateGradePermissions", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local grade = MiscB.ToInt(data.grade or data.gradeId, 0, 99)
    if grade == nil or type(data.permissions) ~= "table" then return { success = false } end

    local jobName = MiscB.JobName(xPlayer)
    local perms = gradePerms(jobName, grade)
    for key, value in pairs(data.permissions) do perms[key] = value == true end

    MiscB.Update([[
        INSERT INTO gouv_grade_permissions (job_name, grade, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { jobName, grade, VFW.DB.Encode(perms) })
    return { success = true }
end)

MiscB.Cb("gouvernement:getEmployeesPermissions", function(source)
    local xPlayer = gouv(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.job_grade, p.permissions
        FROM characters c LEFT JOIN gouv_employee_permissions p ON p.identifier = c.identifier
        WHERE c.job = ? ORDER BY c.job_grade DESC LIMIT 200
    ]], { MiscB.JobName(xPlayer) })

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
        rows[i].permissions = VFW.DB.Decode(rows[i].permissions, {})
        rows[i].firstName = rows[i].firstname or ""
        rows[i].lastName = rows[i].lastname or ""
        rows[i].gradeLabel = gradeLabelFor(MiscB.JobName(xPlayer), rows[i].job_grade)
        rows[i].overrides = rows[i].permissions
    end
    return rows
end)

MiscB.Cb("gouvernement:setEmployeePermission", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local identifier = MiscB.Str(data.identifier, 80)
    if not identifier then return { success = false } end

    local name = MiscB.Str(data.permission or data.permissionName, 64)
    local action = MiscB.Str(data.action, 16)

    local perms
    if type(data.permissions) == "table" then
        perms = data.permissions
    elseif name then
        perms = employeePerms(identifier)
        if action == "reset" then
            perms[name] = nil
        elseif action == "revoke" then
            perms[name] = false
        elseif action == "grant" then
            perms[name] = true
        else
            perms[name] = data.value == true
        end
    else
        return { success = false }
    end

    MiscB.Update([[
        INSERT INTO gouv_employee_permissions (identifier, permissions) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { identifier, VFW.DB.Encode(perms) })
    return { success = true }
end)

MiscB.Cb("gouvernement:getGovernmentStaff", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT identifier, firstname, lastname, job, job_grade FROM characters
        WHERE job = ? ORDER BY job_grade DESC LIMIT 200
    ]], { MiscB.JobName(xPlayer) })

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
        rows[i].online = VFW.GetPlayerFromIdentifier(rows[i].identifier) ~= nil
    end
    return rows
end)

MiscB.Cb("gouvernement:getCitizens", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, p.phone, c.address, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        ORDER BY c.lastname ASC LIMIT 500
    ]], {})

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
    end
    return rows
end)

MiscB.Cb("gouvernement:getCitizenVehicles", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local identifier = type(data) == "table" and MiscB.Str(data.identifier or data.citizenId, 80) or MiscB.Str(data, 80)
    if not identifier then return {} end

    return MiscB.Query(
        "SELECT plate, vehName AS model, stored, pounded FROM owned_vehicles WHERE owner = ? LIMIT 200",
        { identifier }
    )
end)

MiscB.Cb("gouvernement:getCitizenProperties", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local identifier = type(data) == "table" and MiscB.Str(data.identifier or data.citizenId, 80) or MiscB.Str(data, 80)
    if not identifier then return {} end

    return MiscB.Query(
        "SELECT id, name, category, owner, total_price, rent_price FROM properties WHERE owner = ? LIMIT 200",
        { identifier }
    )
end)

MiscB.Cb("gouvernement:setCitizenPhone", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_citizens") then return false end
    if type(data) ~= "table" then return false end

    local identifier = MiscB.Str(data.identifier, 80)
    local phone = MiscB.Str(data.phone, 20)
    if not identifier or not phone then return false end

    MiscB.Update([[
        INSERT INTO character_phones (identifier, phone) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE phone = VALUES(phone)
    ]], { identifier, phone })
    return true
end)

MiscB.Cb("gouvernement:setCitizenAddress", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_citizens") then return false end
    if type(data) ~= "table" then return false end

    local identifier = MiscB.Str(data.identifier, 80)
    local address = MiscB.Str(data.address, 190)
    if not identifier or not address then return false end

    MiscB.Update("UPDATE characters SET address = ? WHERE identifier = ?", { address, identifier })

    local xTarget = VFW.GetPlayerFromIdentifier(identifier)
    if xTarget then xTarget.setPlayerData("address", address) end
    return true
end)

MiscB.Cb("gouvernement:updateCitizenLastName", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_citizens") then return false end
    if type(data) ~= "table" then return false end

    local identifier = MiscB.Str(data.identifier, 80)
    local lastName = MiscB.Str(data.lastname or data.lastName, 60)
    if not identifier or not lastName then return false end

    MiscB.Update("UPDATE characters SET lastname = ? WHERE identifier = ?", { lastName, identifier })

    local xTarget = VFW.GetPlayerFromIdentifier(identifier)
    if xTarget then
        xTarget.lastName = lastName
        xTarget.setPlayerData("lastName", lastName)
    end
    return true
end)

MiscB.Cb("gouvernement:getBankHistory", function(source, citizenId)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "view_bank") then return {} end

    local identifier = MiscB.Str(citizenId, 80)
    if type(citizenId) == "table" then identifier = MiscB.Str(citizenId.identifier, 80) end
    if not identifier then return {} end

    local iban = MiscB.Scalar(
        "SELECT iban FROM bank_ibans WHERE owner_type = 'player' AND owner_key = ? LIMIT 1",
        { identifier }, nil
    )
    if not iban then return {} end

    return MiscB.Query([[
        SELECT id, label, status, amount, value, positive, date FROM bank_transactions
        WHERE iban = ? ORDER BY id DESC LIMIT 100
    ]], { iban })
end)

MiscB.Cb("gouvernement:getSocieties", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT s.name, s.label, s.address, COALESCE(a.money, 0) AS money
        FROM societies s LEFT JOIN society_accounts a ON a.job_name = s.name
        ORDER BY s.label ASC LIMIT 300
    ]], {})
end)

MiscB.Cb("gouvernement:getCompanies", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT s.name, s.label, s.address, COALESCE(a.money, 0) AS money
        FROM societies s LEFT JOIN society_accounts a ON a.job_name = s.name
        ORDER BY s.label ASC LIMIT 300
    ]], {})
end)

MiscB.Cb("gouvernement:getSocietyMembers", function(source, societyName)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local name = MiscB.Str(societyName, 64)
    if type(societyName) == "table" then name = MiscB.Str(societyName.society or societyName.name, 64) end
    if not name then return {} end

    local rows = MiscB.Query([[
        SELECT identifier, firstname, lastname, job_grade FROM characters
        WHERE job = ? ORDER BY job_grade DESC LIMIT 300
    ]], { name })

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
    end
    return rows
end)

MiscB.Cb("gouvernement:getSocietyHistory", function(source, societyName)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local name = MiscB.Str(societyName, 64)
    if type(societyName) == "table" then name = MiscB.Str(societyName.society or societyName.name, 64) end
    if not name then return {} end

    local iban = MiscB.Scalar(
        "SELECT iban FROM bank_ibans WHERE owner_type = 'society' AND owner_key = ? LIMIT 1",
        { name }, nil
    )
    if not iban then return {} end

    return MiscB.Query([[
        SELECT id, label, status, amount, value, positive, date FROM bank_transactions
        WHERE iban = ? ORDER BY id DESC LIMIT 100
    ]], { iban })
end)

MiscB.Cb("gouvernement:getCompanyData", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return nil end

    local name = type(data) == "table" and MiscB.Str(data.company_name or data.companyName or data.name, 64) or MiscB.Str(data, 64)
    if not name then return nil end

    local row = MiscB.Single([[
        SELECT s.name, s.label, s.address, COALESCE(a.money, 0) AS money
        FROM societies s LEFT JOIN society_accounts a ON a.job_name = s.name
        WHERE s.name = ? LIMIT 1
    ]], { name })
    if not row then return nil end

    row.employees = MiscB.Scalar("SELECT COUNT(*) FROM characters WHERE job = ?", { name }, 0)
    return row
end)

MiscB.Cb("gouvernement:setCompanyAddress", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_companies") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.company_name or data.companyName, 64)
    local address = MiscB.Str(data.address, 190)
    if not name or not address then return false end

    MiscB.Update("UPDATE societies SET address = ? WHERE name = ?", { address, name })
    return true
end)

local function societyMoney(name)
    return MiscB.Scalar("SELECT money FROM society_accounts WHERE job_name = ? LIMIT 1", { name }, 0)
end

local function societyIban(name)
    return MiscB.Scalar(
        "SELECT iban FROM bank_ibans WHERE owner_type = 'society' AND owner_key = ? LIMIT 1",
        { name }, nil
    )
end

local function societyAdd(name, amount, reason)
    MiscB.Update([[
        INSERT INTO society_accounts (job_name, money) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE money = money + VALUES(money)
    ]], { name, amount })

    local iban = societyIban(name)
    if iban then
        MiscB.Insert([[
            INSERT INTO bank_transactions (iban, account_type, label, status, amount, value, positive, date)
            VALUES (?, 2, ?, ?, ?, ?, ?, NOW())
        ]], {
            iban,
            reason or "",
            amount >= 0 and "deposit" or "withdraw",
            tostring(amount),
            amount,
            amount >= 0 and 1 or 0,
        })
    end
end

MiscB.Cb("gouvernement:withdrawCompanyFunds", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_companies") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.company_name or data.companyName, 64)
    local amount = MiscB.ToInt(data.amount, 1, 100000000)
    if not name or not amount then return false end
    if societyMoney(name) < amount then return false end

    societyAdd(name, -amount, "retrait-gouvernement")
    xPlayer.addAccountMoney("bank", amount, "retrait-societe-" .. name)
    return true
end)

MiscB.Cb("gouvernement:depositCompanyFunds", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_companies") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.company_name or data.companyName, 64)
    local amount = MiscB.ToInt(data.amount, 1, 100000000)
    if not name or not amount then return false end

    local account = xPlayer.getAccount("bank")
    local balance = type(account) == "table" and (account.money or account.amount or 0) or (tonumber(account) or 0)
    if balance < amount then return false end

    xPlayer.removeAccountMoney("bank", amount, "depot-societe-" .. name)
    societyAdd(name, amount, "depot-gouvernement")
    return true
end)

MiscB.Cb("gouvernement:manageCompanyAccount", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_companies") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.company_name or data.companyName, 64)
    local amount = MiscB.ToInt(data.amount, -100000000, 100000000)
    if not name or not amount or amount == 0 then return false end

    if amount < 0 and societyMoney(name) < -amount then return false end

    societyAdd(name, amount, MiscB.Str(data.reason, 190) or "gestion-gouvernement")
    return true
end)

MiscB.Cb("gouvernement:withdrawFromSociety", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_companies") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.society or data.company_name, 64)
    local amount = MiscB.ToInt(data.amount, 1, 100000000)
    if not name or not amount then return false end
    if societyMoney(name) < amount then return false end

    societyAdd(name, -amount, "saisie-gouvernement")
    return true
end)

MiscB.Cb("gouvernement:getTaxSettings", function(source, societyName)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local name = MiscB.Str(societyName, 64)
    if type(societyName) == "table" then name = MiscB.Str(societyName.society or societyName.name, 64) end
    if not name then return {} end

    local row = MiscB.Single("SELECT rate, active FROM gouv_society_tax WHERE society = ? LIMIT 1", { name })
    if not row then return { rate = 0, active = false } end
    return { rate = row.rate, active = row.active == 1 }
end)

MiscB.Cb("gouvernement:setSocietyTax", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_taxes") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.society or data.company_name, 64)
    local rate = MiscB.ToNum(data.rate, nil)
    if not name or not rate or rate < 0 or rate > 100 then return false end

    MiscB.Update([[
        INSERT INTO gouv_society_tax (society, rate, active) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE rate = VALUES(rate), active = VALUES(active)
    ]], { name, rate, data.active ~= false and 1 or 0 })
    return true
end)

MiscB.Cb("gouvernement:getCompanyTaxes", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local name = type(data) == "table" and MiscB.Str(data.company_name or data.companyName, 64) or MiscB.Str(data, 64)
    if not name then
        return MiscB.Query("SELECT * FROM gouv_company_taxes ORDER BY id DESC LIMIT 200", {})
    end

    return MiscB.Query(
        "SELECT * FROM gouv_company_taxes WHERE society = ? ORDER BY id DESC LIMIT 100",
        { name }
    )
end)

MiscB.Cb("gouvernement:setCompanyTax", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_taxes") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.company_name or data.companyName or data.society, 64)
    local amount = MiscB.ToInt(data.amount, 0, 100000000)
    if not name or not amount then return false end

    local id = MiscB.ToInt(data.id, 1)
    if id then
        MiscB.Update("UPDATE gouv_company_taxes SET label = ?, amount = ?, period = ?, active = ? WHERE id = ?", {
            MiscB.Str(data.label, 120) or "Taxe",
            amount,
            MiscB.Str(data.period, 32) or "monthly",
            data.active ~= false and 1 or 0,
            id,
        })
        return true
    end

    MiscB.Insert([[
        INSERT INTO gouv_company_taxes (society, label, amount, period, active, created_at)
        VALUES (?, ?, ?, ?, ?, NOW())
    ]], {
        name,
        MiscB.Str(data.label, 120) or "Taxe",
        amount,
        MiscB.Str(data.period, 32) or "monthly",
        data.active ~= false and 1 or 0,
    })
    return true
end)

MiscB.Cb("gouvernement:deleteCompanyTax", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_taxes") then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("DELETE FROM gouv_company_taxes WHERE id = ?", { id })
    return true
end)

MiscB.Cb("gouvernement:deleteTax", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_taxes") then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("DELETE FROM gouv_company_taxes WHERE id = ?", { id })
    return true
end)

MiscB.Cb("gouvernement:collectCompanyTax", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer or not hasPerm(xPlayer, "manage_taxes") then return false end
    if type(data) ~= "table" then return false end

    local name = MiscB.Str(data.company_name or data.companyName, 64)
    if not name then return false end

    local taxes = MiscB.Query(
        "SELECT id, label, amount FROM gouv_company_taxes WHERE society = ? AND active = 1",
        { name }
    )

    local total = 0
    for i = 1, #taxes do total = total + (tonumber(taxes[i].amount) or 0) end
    if total <= 0 then return false end

    if societyMoney(name) < total then return false end

    societyAdd(name, -total, "taxe-gouvernement")

    for i = 1, #taxes do
        MiscB.Insert([[
            INSERT INTO gouv_tax_logs (society, label, amount, collected_by, created_at)
            VALUES (?, ?, ?, ?, NOW())
        ]], { name, taxes[i].label, taxes[i].amount, MiscB.CharName(xPlayer) })
    end

    return true
end)

MiscB.Cb("gouvernement:getTaxLogs", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local name = type(data) == "table" and MiscB.Str(data.company_name or data.companyName or data.society, 64) or MiscB.Str(data, 64)
    if name then
        return MiscB.Query(
            "SELECT * FROM gouv_tax_logs WHERE society = ? ORDER BY id DESC LIMIT 100",
            { name }
        )
    end
    return MiscB.Query("SELECT * FROM gouv_tax_logs ORDER BY id DESC LIMIT 200", {})
end)

MiscB.Cb("gouvernement:getConversation", function(source, companyName)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local name = MiscB.Str(companyName, 64)
    if type(companyName) == "table" then name = MiscB.Str(companyName.companyName or companyName.company, 64) end
    if not name then return {} end

    return MiscB.Query([[
        SELECT id, society, sender_name, message, from_gouv, is_read, created_at
        FROM gouv_liaison_messages WHERE society = ? ORDER BY id ASC LIMIT 200
    ]], { name })
end)

MiscB.Cb("gouvernement:sendMessage", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end
    if type(data) ~= "table" then return false end

    local target = MiscB.Str(data.targetJob or data.companyName, 64)
    local message = MiscB.Str(data.messageText or data.message, 1000)
    if not target or not message then return false end
    if not MiscB.Rate(source, "gouvmsg", 1000) then return false end

    local id = MiscB.Insert([[
        INSERT INTO gouv_liaison_messages (society, sender_identifier, sender_name, message, from_gouv, is_read)
        VALUES (?, ?, ?, ?, 1, 0)
    ]], { target, xPlayer.identifier, MiscB.CharName(xPlayer), message })

    local receivers = MiscB.PlayersWithJobs(target)
    for i = 1, #receivers do
        TriggerClientEvent("liaison:newMessage", receivers[i].source, {
            id = id, society = target, sender_name = MiscB.CharName(xPlayer),
            message = message, from_gouv = 1,
        })
    end

    return id ~= nil
end)

MiscB.Cb("gouvernement:deleteMessage", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.messageId or data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("DELETE FROM gouv_liaison_messages WHERE id = ?", { id })
    return true
end)

MiscB.Cb("gouvernement:clearConversation", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end

    local name = type(data) == "table" and MiscB.Str(data.companyName or data.company, 64) or MiscB.Str(data, 64)
    if not name then return false end

    MiscB.Update("DELETE FROM gouv_liaison_messages WHERE society = ?", { name })
    return true
end)

MiscB.Cb("gouvernement:getUnreadByCompany", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT society, COUNT(*) AS total FROM gouv_liaison_messages
        WHERE from_gouv = 0 AND is_read = 0 GROUP BY society
    ]], {})

    local out = {}
    for i = 1, #rows do out[rows[i].society] = rows[i].total end
    return out
end)

MiscB.Cb("gouvernement:markCompanyAsRead", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end

    local name = type(data) == "table" and MiscB.Str(data.companyName or data.company, 64) or MiscB.Str(data, 64)
    if not name then return false end

    MiscB.Update("UPDATE gouv_liaison_messages SET is_read = 1 WHERE society = ? AND from_gouv = 0", { name })
    return true
end)

MiscB.Cb("gouvernement:getAppointments", function(source)
    local xPlayer = gouv(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT id, citizen_identifier, citizen_name, phone, subject, note, status, staff_name, created_at
        FROM gouv_appointments ORDER BY id DESC LIMIT 200
    ]], {})
end)

RegisterNetEvent("gouvernement:addAppointment", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not MiscB.Rate(source, "appointment", 5000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    MiscB.Insert([[
        INSERT INTO gouv_appointments (citizen_identifier, citizen_name, phone, subject, note, status, created_at)
        VALUES (?, ?, ?, ?, '', 'pending', NOW())
    ]], {
        xPlayer.identifier,
        MiscB.CharName(xPlayer),
        MiscB.Str(data.phone, 20) or "",
        MiscB.Str(data.subject or data.reason, 190) or "",
    })

    VFW.ShowNotification(source, { type = "VERT", content = "Votre rendez-vous a ete enregistre." })
end)

MiscB.Cb("gouvernement:acceptAppointment", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("UPDATE gouv_appointments SET status = 'accepted', staff_name = ? WHERE id = ?",
        { MiscB.CharName(xPlayer), id })
    return true
end)

MiscB.Cb("gouvernement:deleteAppointment", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("DELETE FROM gouv_appointments WHERE id = ?", { id })
    return true
end)

MiscB.Cb("gouvernement:updateAppointmentNote", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end
    if type(data) ~= "table" then return false end

    local id = MiscB.ToInt(data.id, 1)
    local note = MiscB.Str(data.note, 2000)
    if not id or note == nil then return false end

    MiscB.Update("UPDATE gouv_appointments SET note = ? WHERE id = ?", { note, id })
    return true
end)

MiscB.Cb("gouvernement:sendAppointmentMessage", function(source, data)
    local xPlayer = gouv(source)
    if not xPlayer then return false end
    if type(data) ~= "table" then return false end

    local id = MiscB.ToInt(data.id, 1)
    local message = MiscB.Str(data.message, 1000)
    if not id or not message then return false end

    local row = MiscB.Single("SELECT citizen_identifier FROM gouv_appointments WHERE id = ? LIMIT 1", { id })
    if not row then return false end

    local xTarget = VFW.GetPlayerFromIdentifier(row.citizen_identifier)
    if xTarget then
        VFW.ShowNotification(xTarget.source, { type = "BLEU", content = "Mairie : " .. message })
    end

    MiscB.Update("UPDATE gouv_appointments SET note = CONCAT(COALESCE(note, ''), ?, '\n') WHERE id = ?",
        { message, id })
    return true
end)

local nameChangeRequests = {}

RegisterNetEvent("gouvernement:refuseNameChange", function()
    local source = source
    local xPlayer = gouv(source)
    if not xPlayer then return end

    local pending = nameChangeRequests[source]
    nameChangeRequests[source] = nil
    if not pending then return end

    local xTarget = VFW.GetPlayerFromIdentifier(pending.identifier)
    if xTarget then
        VFW.ShowNotification(xTarget.source, { type = "ROUGE", content = "Votre changement de nom a ete refuse." })
    end
end)

RegisterNetEvent("gouvernement:finalizeNameChange", function()
    local source = source
    local xPlayer = gouv(source)
    if not xPlayer then return end

    local pending = nameChangeRequests[source]
    nameChangeRequests[source] = nil
    if not pending then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Aucune demande en attente." })
        return
    end

    MiscB.Update("UPDATE characters SET firstname = ?, lastname = ? WHERE identifier = ?",
        { pending.firstName, pending.lastName, pending.identifier })

    local xTarget = VFW.GetPlayerFromIdentifier(pending.identifier)
    if xTarget then
        xTarget.firstName = pending.firstName
        xTarget.lastName = pending.lastName
        xTarget.setPlayerData("firstName", pending.firstName)
        xTarget.setPlayerData("lastName", pending.lastName)
        VFW.ShowNotification(xTarget.source, { type = "VERT", content = "Votre identite a ete mise a jour." })
    end

    VFW.ShowNotification(source, { type = "VERT", content = "Changement de nom valide." })
end)

RegisterNetEvent("gouvernement:requestNameChange", function(data)
    local source = source
    if type(data) ~= "table" then return end

    local xPlayer = gouv(source)
    if not xPlayer then return end

    local identifier = MiscB.Str(data.identifier, 80)
    local firstName = MiscB.Str(data.firstName or data.firstname, 60)
    local lastName = MiscB.Str(data.lastName or data.lastname, 60)
    if not identifier or not firstName or not lastName then return end

    nameChangeRequests[source] = { identifier = identifier, firstName = firstName, lastName = lastName }
    TriggerClientEvent("gouvernement:showNameChangeModal", source, nameChangeRequests[source])
end)

AddEventHandler("vfw:playerDropped", function(source)
    nameChangeRequests[source] = nil
end)

MiscB.Cb("discussion:getJobs", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    return MiscB.Query("SELECT name, label FROM jobs ORDER BY label ASC LIMIT 300", {})
end)

MiscB.Cb("discussion:getMessages", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local target = type(data) == "table" and MiscB.Str(data.job or data.targetJob, 64) or MiscB.Str(data, 64)
    local job = MiscB.JobName(xPlayer)
    if not target or not job then return {} end

    return MiscB.Query([[
        SELECT id, from_job, to_job, sender_name, message, is_read, created_at
        FROM gouv_discussions
        WHERE (from_job = ? AND to_job = ?) OR (from_job = ? AND to_job = ?)
        ORDER BY id ASC LIMIT 200
    ]], { job, target, target, job })
end)

MiscB.Cb("discussion:sendMessage", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(data) ~= "table" then return false end

    local target = MiscB.Str(data.job or data.targetJob, 64)
    local message = MiscB.Str(data.message or data.messageText, 1000)
    local job = MiscB.JobName(xPlayer)
    if not target or not message or not job then return false end
    if not MiscB.Rate(source, "discussion", 1000) then return false end

    local id = MiscB.Insert([[
        INSERT INTO gouv_discussions (from_job, to_job, sender_identifier, sender_name, message, is_read, created_at)
        VALUES (?, ?, ?, ?, ?, 0, NOW())
    ]], { job, target, xPlayer.identifier, MiscB.CharName(xPlayer), message })

    local receivers = MiscB.PlayersWithJobs(target)
    for i = 1, #receivers do
        TriggerClientEvent("discussion:newMessage", receivers[i].source, {
            id = id, from_job = job, to_job = target,
            sender_name = MiscB.CharName(xPlayer), message = message,
        })
    end

    return id ~= nil
end)

MiscB.Cb("discussion:markAsRead", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local job = MiscB.JobName(xPlayer)
    if not job then return false end

    local target = type(data) == "table" and MiscB.Str(data.job or data.targetJob, 64) or MiscB.Str(data, 64)
    if target then
        MiscB.Update("UPDATE gouv_discussions SET is_read = 1 WHERE to_job = ? AND from_job = ?", { job, target })
    else
        MiscB.Update("UPDATE gouv_discussions SET is_read = 1 WHERE to_job = ?", { job })
    end
    return true
end)

local function dojPerms(jobName, grade)
    local row = MiscB.Single(
        "SELECT permissions FROM doj_grade_permissions WHERE job_name = ? AND grade = ? LIMIT 1",
        { jobName, grade }
    )
    if not row then return {} end
    local decoded = VFW.DB.Decode(row.permissions, {})
    return type(decoded) == "table" and decoded or {}
end

MiscB.Cb("doj:getPlayerPermissions", function(source)
    local xPlayer = justice(source)
    if not xPlayer then return {} end
    local perms = dojPerms(MiscB.JobName(xPlayer), MiscB.GradeLevel(xPlayer))
    perms.isBoss = MiscB.IsBoss(xPlayer)
    return perms
end)

MiscB.Cb("doj:getGradesPermissions", function(source)
    local xPlayer = justice(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    local rows = MiscB.Query(
        "SELECT grade, permissions FROM doj_grade_permissions WHERE job_name = ? ORDER BY grade ASC",
        { MiscB.JobName(xPlayer) }
    )
    for i = 1, #rows do rows[i].permissions = VFW.DB.Decode(rows[i].permissions, {}) end
    return rows
end)

MiscB.Cb("doj:updateGradePermissions", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return false end
    if type(data) ~= "table" then return false end

    local grade = MiscB.ToInt(data.grade, 0, 99)
    if grade == nil or type(data.permissions) ~= "table" then return false end

    MiscB.Update([[
        INSERT INTO doj_grade_permissions (job_name, grade, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { MiscB.JobName(xPlayer), grade, VFW.DB.Encode(data.permissions) })
    return true
end)

MiscB.Cb("doj:getPoliceOfficers", function(source)
    local xPlayer = justice(source)
    if not xPlayer then return {} end

    local jobs = {}
    if type(LawEnforcementJobsList) == "table" then
        for name in pairs(LawEnforcementJobsList) do jobs[#jobs + 1] = name end
    end
    if #jobs == 0 then jobs = { "police" } end

    local placeholders = {}
    for i = 1, #jobs do placeholders[#placeholders + 1] = "?" end

    local rows = MiscB.Query(
        ("SELECT identifier, firstname, lastname, job, job_grade FROM characters WHERE job IN (%s) ORDER BY job ASC, job_grade DESC LIMIT 300"):format(table.concat(placeholders, ",")),
        jobs
    )
    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
    end
    return rows
end)

MiscB.Cb("doj:searchCitizens", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return {} end

    local term = type(data) == "table" and MiscB.Str(data.search or data.query, 64) or MiscB.Str(data, 64)
    if not term or term == "" then return {} end

    local like = "%" .. term .. "%"
    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, p.phone
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        WHERE c.firstname LIKE ? OR c.lastname LIKE ? OR CONCAT(c.firstname, ' ', c.lastname) LIKE ?
        ORDER BY c.lastname ASC LIMIT 100
    ]], { like, like, like })

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
    end
    return rows
end)

MiscB.Cb("doj:getDossiers", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT citizen_identifier, citizen_name, COUNT(*) AS total, MAX(created_at) AS last_at
        FROM police_records GROUP BY citizen_identifier, citizen_name
        ORDER BY last_at DESC LIMIT 200
    ]], {})
end)

MiscB.Cb("doj:getDossierDetail", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return {} end

    local identifier = type(data) == "table" and MiscB.Str(data.identifier or data.citizenIdentifier, 80) or MiscB.Str(data, 80)
    if not identifier then return {} end

    local rows = MiscB.Query([[
        SELECT id, record_type, title, content, data, author_name, created_at
        FROM police_records WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 300
    ]], { identifier })
    for i = 1, #rows do rows[i].data = VFW.DB.Decode(rows[i].data, {}) end

    return { identifier = identifier, records = rows }
end)

MiscB.Cb("doj:updateDossier", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return false end
    if type(data) ~= "table" then return false end

    local id = MiscB.ToInt(data.id or data.recordId, 1)
    if not id then return false end

    MiscB.Update("UPDATE police_records SET title = ?, content = ?, updated_at = NOW() WHERE id = ?", {
        MiscB.Str(data.title, 190) or "",
        MiscB.Str(data.content, 6000) or "",
        id,
    })
    return true
end)

MiscB.Cb("doj:deleteDossier", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.id or data.recordId, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("DELETE FROM police_records WHERE id = ?", { id })
    return true
end)

MiscB.Cb("doj:getWarrants", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return {} end

    local identifier = type(data) == "table" and MiscB.Str(data.identifier, 80) or nil
    if identifier then
        return MiscB.Query("SELECT * FROM police_warrants WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 100", { identifier })
    end
    return MiscB.Query("SELECT * FROM police_warrants ORDER BY id DESC LIMIT 200", {})
end)

MiscB.Cb("doj:getAllWarrants", function(source)
    local xPlayer = justice(source)
    if not xPlayer then return {} end
    return MiscB.Query("SELECT * FROM police_warrants ORDER BY id DESC LIMIT 300", {})
end)

MiscB.Cb("doj:createWarrant", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local identifier = MiscB.Str(data.identifier or data.citizenIdentifier, 80)
    if not identifier then return { success = false } end

    local citizen = MiscB.Single("SELECT firstname, lastname FROM characters WHERE identifier = ? LIMIT 1", { identifier })
    local id = MiscB.Insert([[
        INSERT INTO police_warrants (citizen_identifier, citizen_name, reason, status,
            author_identifier, author_name, job_name, created_at)
        VALUES (?, ?, ?, 'open', ?, ?, ?, NOW())
    ]], {
        identifier,
        citizen and ("%s %s"):format(citizen.firstname or "", citizen.lastname or "") or "",
        MiscB.Str(data.reason, 1000) or "",
        xPlayer.identifier, MiscB.CharName(xPlayer), MiscB.JobName(xPlayer) or "",
    })

    return { success = id ~= nil, id = id }
end)

MiscB.Cb("doj:updateWarrantStatus", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return false end
    if type(data) ~= "table" then return false end

    local id = MiscB.ToInt(data.id or data.warrantId, 1)
    local status = MiscB.Str(data.status, 24)
    if not id or not status then return false end
    if status ~= "open" and status ~= "closed" and status ~= "executed" and status ~= "cancelled" then
        return false
    end

    MiscB.Update("UPDATE police_warrants SET status = ?, updated_at = NOW() WHERE id = ?", { status, id })
    return true
end)

MiscB.Cb("doj:deleteWarrant", function(source, data)
    local xPlayer = justice(source)
    if not xPlayer then return false end

    local id = type(data) == "table" and MiscB.ToInt(data.id or data.warrantId, 1) or MiscB.ToInt(data, 1)
    if not id then return false end

    MiscB.Update("DELETE FROM police_warrants WHERE id = ?", { id })
    return true
end)
