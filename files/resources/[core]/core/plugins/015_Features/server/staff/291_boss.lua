local BASE_PERMISSIONS = {
    "recruit", "promote", "accounting", "kick", "announce", "manage_permissions",
    "demote", "custom", "manage_chest", "view_logs", "manage_locker", "manage_services",
    "liaison_gouv", "gouvernement_tablet", "gouvernement_settings", "security_actions",
    "create_invoice", "create_invoice_company",
}

local RESTAURANT_CALLBACKS = {
    "burgershot:delivery:getLogs",
    "pizzeria:delivery:getLogs",
    "pearls:delivery:getLogs",
    "noodle:delivery:getLogs",
    "bean_coffee:delivery:getLogs",
    "uwu_cafe:delivery:getLogs",
}

local CONTRACT_TTL = 120000

local contracts = {}
local contractSeq = 0

local Boss = {}

function Boss.GetSocietyMoney(jobName)
    return Staff29.Scalar("SELECT money FROM society_accounts WHERE job_name = ?", { jobName }, 0) or 0
end

function Boss.SetSocietyMoney(jobName, money)
    money = math.floor(money)
    if money < 0 then money = 0 end
    Staff29.Update([[
        INSERT INTO society_accounts (job_name, money) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE money = VALUES(money)
    ]], { jobName, money })
    return money
end

function Boss.AddSocietyMoney(jobName, amount)
    return Boss.SetSocietyMoney(jobName, Boss.GetSocietyMoney(jobName) + amount)
end

function Boss.GetPermMatrix(jobName)
    local rows = Staff29.Query(
        "SELECT grade_name, perm_name, enabled FROM society_grade_perms WHERE job_name = ?", { jobName })
    local matrix = {}
    for i = 1, #rows do
        local row = rows[i]
        matrix[row.grade_name] = matrix[row.grade_name] or {}
        matrix[row.grade_name][row.perm_name] = row.enabled == 1
    end

    local job = VFW.Jobs[jobName]
    if job then
        for _, grade in pairs(job.grades) do
            matrix[grade.name] = matrix[grade.name] or {}
            for i = 1, #BASE_PERMISSIONS do
                local perm = BASE_PERMISSIONS[i]
                if matrix[grade.name][perm] == nil then
                    matrix[grade.name][perm] = grade.isBoss and true or false
                end
            end
        end
    end

    return matrix
end

function Boss.SetGradePerms(jobName, gradeName, perms)
    Staff29.Update("DELETE FROM society_grade_perms WHERE job_name = ? AND grade_name = ?", { jobName, gradeName })
    for i = 1, #BASE_PERMISSIONS do
        local perm = BASE_PERMISSIONS[i]
        Staff29.Update([[
            INSERT INTO society_grade_perms (job_name, grade_name, perm_name, enabled) VALUES (?, ?, ?, ?)
        ]], { jobName, gradeName, perm, perms[perm] and 1 or 0 })
    end
end

function Boss.HasBossPermission(xPlayer, jobName, permission)
    if not xPlayer then return false end
    if xPlayer.hasPermission("manage_jobs") then return true end

    local job = xPlayer.job
    if not job or job.name ~= jobName then
        if not (xPlayer.job2 and xPlayer.job2.name == jobName) then
            return false
        end
        job = xPlayer.job2
    end

    if job.grade_is_boss then return true end
    if not permission then return true end

    local matrix = Boss.GetPermMatrix(jobName)
    local gradePerms = matrix[job.grade_name]
    return gradePerms ~= nil and gradePerms[permission] == true
end

function Boss.GetCustom(jobName)
    local row = Staff29.Single("SELECT * FROM society_custom WHERE job_name = ?", { jobName })
    local emptyPerms = { create = 0, edit = 0, schedule = 0, delete = 0, broadcast = 0 }
    local society = VFW.Society.Get(jobName)
    local societyAllow = society and society.custom and society.custom.allowCustomAnnouncement == true
    if not row then
        return {
            image = "",
            allowCustomAnnouncement = societyAllow,
            weazelPerms = emptyPerms,
            lifeinvaderPerms = VFW.DeepCopy(emptyPerms),
        }
    end
    return {
        image = row.image or "",
        allowCustomAnnouncement = row.allow_custom_announcement == 1 or societyAllow,
        weazelPerms = Staff29.Decode(row.weazel_perms, VFW.DeepCopy(emptyPerms)),
        lifeinvaderPerms = Staff29.Decode(row.lifeinvader_perms, VFW.DeepCopy(emptyPerms)),
    }
end

function Boss.NotifyPanel(jobName)
    local players = VFW.GetPlayersWithJobs(jobName)
    for i = 1, #players do
        players[i].triggerEvent("core:jobs:updateBossPanel")
    end
end

function Boss.LockersOfJob(jobName)
    local rows = Staff29.Query("SELECT * FROM society_lockers WHERE job = ?", { jobName })
    if #rows == 0 then
        rows = Staff29.Query("SELECT * FROM society_lockers WHERE job_name = ?", { jobName })
    end
    return rows
end

function Boss.ArchiveLockers(jobName, identifier)
    local lockers = Staff29.Query(
        "SELECT * FROM society_locker_chests WHERE identifier = ?", { identifier })

    for i = 1, #lockers do
        local locker = lockers[i]
        Staff29.Insert([[
            INSERT INTO society_lockers_archived (locker_id, job, identifier, player_name, chest_id, archived_at)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { locker.locker_id or 0, jobName, identifier, locker.player_name or "",
              locker.chest_id or "", Staff29.Now() })
    end

    Staff29.Update("DELETE FROM society_locker_chests WHERE identifier = ?", { identifier })
end

Staff29.Boss = Boss

Staff29.Cb("core:jobs:getMembers", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return nil end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Boss.HasBossPermission(xPlayer, jobName, nil) then return nil end

    local rows = Staff29.Query([[
        SELECT identifier, firstname, lastname, job_grade, job_duty, mugshot, metadata, created_at
        FROM characters WHERE job = ? AND deleted_at IS NULL ORDER BY job_grade DESC
    ]], { jobName })

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local online = VFW.GetPlayerFromIdentifier(row.identifier)
        local metadata = Staff29.Decode(row.metadata, {})
        n = n + 1
        out[n] = {
            identifier = row.identifier,
            fname = row.firstname or "",
            lname = row.lastname or "",
            rank = (tonumber(row.job_grade) or 0) + 1,
            Information = {
                onDuty = online and online.job.onDuty or (row.job_duty == 1),
                mugshot = row.mugshot or "",
            },
            startDate = tostring(row.created_at or ""),
            phoneNumber = tostring(metadata.phone or metadata.phoneNumber or ""),
        }
    end

    return out
end)

Staff29.Cb("core:jobs:getMembersServices", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return {} end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Boss.HasBossPermission(xPlayer, jobName, nil) then return {} end

    local rows = Staff29.Query("SELECT * FROM society_services WHERE job_name = ?", { jobName })
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[row.identifier] = {
            time = tonumber(row.time) or 0,
            stopTime = tonumber(row.stop_time) or 0,
            totalWeek = tonumber(row.total_week) or 0,
            totalLastWeek = tonumber(row.total_last_week) or 0,
            timeInService = tonumber(row.time_in_service) or 0,
        }
    end
    return out
end)

Staff29.Cb("core:jobs:getJob", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then
        return { image = "", grades = {}, perms = {} }, { money = 0 }, {}, nil
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not Boss.HasBossPermission(xPlayer, jobName, nil) then
        return { image = "", grades = {}, perms = {} }, { money = 0 }, {}, nil
    end

    local custom = Boss.GetCustom(jobName)
    local job = VFW.Jobs[jobName]
    local grades, n = {}, 0

    if job then
        for _, grade in pairs(job.grades) do
            n = n + 1
            grades[n] = {
                name = grade.name,
                label = grade.label,
                grade = grade.grade,
                salary = grade.salary or 0,
                is_boss = grade.isBoss and 1 or 0,
            }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
    end

    local jobData = {
        image = custom.image,
        grades = grades,
        perms = Boss.GetPermMatrix(jobName),
    }

    local favRows = Staff29.Query("SELECT identifier FROM society_favorites WHERE job_name = ?", { jobName })
    local favorites, f = {}, 0
    for i = 1, #favRows do
        f = f + 1
        favorites[f] = favRows[i].identifier
    end

    return jobData,
        { money = Boss.GetSocietyMoney(jobName) },
        favorites,
        {
            allowCustomAnnouncement = custom.allowCustomAnnouncement,
            weazelPerms = custom.weazelPerms,
            lifeinvaderPerms = custom.lifeinvaderPerms,
        }
end)

Staff29.Cb("vfw:chest:getByGroup", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return {} end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Boss.HasBossPermission(xPlayer, jobName, nil) then return {} end

    local rows = Boss.LockersOfJob(jobName)
    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            chestId = row.chest_id or tostring(row.id),
            id = row.id,
            label = row.label or ("Coffre #" .. tostring(row.id)),
            job = jobName,
            maxWeight = row.max_weight,
            maxSlots = row.max_slots,
        }
    end
    return out
end)

Staff29.Cb("core:societyLockers:getByJob", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return {} end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Boss.HasBossPermission(xPlayer, jobName, nil) then return {} end

    local rows = Boss.LockersOfJob(jobName)
    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            id = row.id,
            job = jobName,
            job_name = jobName,
            label = row.label or ("Vestiaire #" .. tostring(row.id)),
            chest_id = row.chest_id,
            grade_min = row.grade_min,
        }
    end
    return out
end)

Staff29.Cb("core:farm:getLogs", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return false, {}, false end
    local job = VFW.Jobs[jobName]
    local isFarming = job ~= nil and job.type == "farm"
    local isTaxi = jobName:find("^taxi") ~= nil
    if not isFarming and not isTaxi then return false, {}, false end

    local logs = {}
    if isFarming and VFW.Farm and VFW.Farm.GetLogs then
        local ok, rows = pcall(VFW.Farm.GetLogs, jobName, 100)
        if ok and type(rows) == "table" then logs = rows end
    end

    return isFarming, logs, isTaxi
end)

Staff29.Cb("fl_ltd:getLogs", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return false, {} end
    return jobName:find("^ltd") ~= nil, {}
end)

for i = 1, #RESTAURANT_CALLBACKS do
    Staff29.Cb(RESTAURANT_CALLBACKS[i], function(source, jobName)
        if not Staff29.IsString(jobName, 60) then return false, {} end
        return true, {}
    end)
end

Staff29.Cb("liaison:getUnreadCount", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    return Staff29.Scalar(
        "SELECT COUNT(*) FROM society_billings WHERE job_name = ? AND statut = 0", { xPlayer.job.name }, 0) or 0
end)

local function buildBillings(jobName, page, pageSize)
    local offset = (page - 1) * pageSize
    local rows = Staff29.Query([[
        SELECT id, sender, receiver, date, total, base_cost, statut, type, items
        FROM society_billings WHERE job_name = ?
        ORDER BY id DESC LIMIT ? OFFSET ?
    ]], { jobName, pageSize, offset })

    local billings, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local items = row.items
        if type(items) ~= "string" or items == "" then items = "[]" end
        n = n + 1
        billings[n] = {
            id = row.id,
            sender = row.sender or "Unknown",
            receiver = row.receiver or "Unknown",
            date = tostring(row.date or ""),
            total = tonumber(row.total) or 0,
            base_cost = row.base_cost and tonumber(row.base_cost) or nil,
            statut = tonumber(row.statut) or 0,
            type = row.type or "invoice",
            items = items,
        }
    end

    local total = Staff29.Scalar("SELECT COUNT(*) FROM society_billings WHERE job_name = ?", { jobName }, 0) or 0
    return { billings = billings, total = total }
end

Staff29.Cb("core:jobs:getBillings", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { billings = {}, total = 0 } end

    local jobName = xPlayer.job.name
    local page, pageSize = 1, 10

    if Staff29.IsTable(data) then
        if Staff29.IsString(data.jobName, 60) then jobName = data.jobName end
        page = Staff29.ToInt(data.page, 1, 10000) or 1
        pageSize = Staff29.ToInt(data.pageSize, 1, 100) or 10
    end

    if not Boss.HasBossPermission(xPlayer, jobName, "accounting") then
        return { billings = {}, total = 0 }
    end

    return buildBillings(jobName, page, pageSize)
end)

Staff29.Cb("core:jobs:updateEmployee", function(source, employeeId, patch)
    if not Staff29.IsString(employeeId, 80) or not Staff29.IsTable(patch) then
        return false, "Les informations envoyées ne sont pas valides"
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable" end

    local jobName = xPlayer.job.name
    local target = Staff29.Single(
        "SELECT identifier, job, job_grade FROM characters WHERE identifier = ? AND deleted_at IS NULL", { employeeId })
    if not target or target.job ~= jobName then return false, "Employé introuvable" end

    if patch.isFavorite ~= nil then
        if patch.isFavorite then
            Staff29.Update([[
                INSERT IGNORE INTO society_favorites (job_name, identifier) VALUES (?, ?)
            ]], { jobName, employeeId })
        else
            Staff29.Update("DELETE FROM society_favorites WHERE job_name = ? AND identifier = ?",
                { jobName, employeeId })
        end
    end

    local newGrade = nil
    if patch.grade ~= nil then
        newGrade = Staff29.ToInt(patch.grade, 0, 100)
    elseif Staff29.IsTable(patch.role) and patch.role.grade ~= nil then
        newGrade = Staff29.ToInt(patch.role.grade, 0, 100)
    elseif patch.rank ~= nil then
        local rank = Staff29.ToInt(patch.rank, 1, 101)
        if rank then newGrade = rank - 1 end
    end

    if newGrade then
        local currentGrade = tonumber(target.job_grade) or 0
        local permission = newGrade > currentGrade and "promote" or "demote"
        if not Boss.HasBossPermission(xPlayer, jobName, permission) then
            return false, "Permission insuffisante"
        end

        local job = VFW.Jobs[jobName]
        if not job or not job.grades[tostring(newGrade)] then
            return false, "Grade inexistant"
        end

        local online = VFW.GetPlayerFromIdentifier(employeeId)
        if online then
            online.setJob(jobName, newGrade, online.job.onDuty)
            online.save()
        else
            Staff29.Update("UPDATE characters SET job_grade = ? WHERE identifier = ?", { newGrade, employeeId })
        end
    end

    Boss.NotifyPanel(jobName)
    return true, "Employé mis à jour"
end)

Staff29.Cb("core:jobs:deleteRole", function(source, role)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable" end

    local jobName = xPlayer.job.name
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_permissions") then
        return false, "Permission insuffisante"
    end

    local gradeName, gradeNumber
    if Staff29.IsTable(role) then
        gradeName = role.name
        gradeNumber = Staff29.ToInt(role.grade, 0, 100)
    elseif type(role) == "string" then
        gradeName = role
    end

    if not Staff29.IsString(gradeName, 60) then return false, "Ce rôle n'est pas valide" end

    local job = VFW.Jobs[jobName]
    local count = 0
    if job then for _ in pairs(job.grades) do count = count + 1 end end
    if count <= 1 then return false, "Impossible de supprimer le dernier grade" end

    local used = Staff29.Scalar(
        "SELECT COUNT(*) FROM characters WHERE job = ? AND job_grade = ? AND deleted_at IS NULL",
        { jobName, gradeNumber or -1 }, 0) or 0
    if used > 0 then return false, "Des employés occupent encore ce grade" end

    Staff29.Update("DELETE FROM job_grades WHERE job_name = ? AND name = ?", { jobName, gradeName })
    Staff29.Update("DELETE FROM society_grade_perms WHERE job_name = ? AND grade_name = ?", { jobName, gradeName })
    VFW.DB.LoadJobs()
    Boss.NotifyPanel(jobName)
    return true, "Rôle supprimé"
end)

Staff29.Cb("core:jobs:addRole", function(source, data)
    if not Staff29.IsTable(data) or not Staff29.IsTable(data.role) then return false, "Les informations envoyées ne sont pas valides" end

    local xPlayer = VFW.GetPlayerFromId(source)
    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or (xPlayer and xPlayer.job.name)
    if not jobName then return false, "Cette société n'est pas valide" end
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_permissions") then
        return false, "Permission insuffisante"
    end

    local role = data.role
    local name = Staff29.Clean(role.name, 60)
    local label = Staff29.Clean(role.label, 80) or name
    local grade = Staff29.ToInt(role.grade, 0, 100)
    local salary = Staff29.ToInt(role.salary, 0, 10000000) or 0

    if not name or name == "" or not grade then return false, "Ce rôle n'est pas valide" end

    local exists = Staff29.Scalar(
        "SELECT COUNT(*) FROM job_grades WHERE job_name = ? AND grade = ?", { jobName, grade }, 0) or 0
    if exists > 0 then return false, "Ce grade existe déjà" end

    Staff29.Insert([[
        INSERT INTO job_grades (job_name, grade, name, label, salary, is_boss, permissions)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { jobName, grade, name, label, salary, role.isBoss and 1 or 0, Staff29.Encode({}) })

    local perms = {}
    if Staff29.IsTable(role.permissions) then
        for i = 1, #role.permissions do
            local entry = role.permissions[i]
            if Staff29.IsTable(entry) and entry.name then perms[entry.name] = true end
        end
    end
    Boss.SetGradePerms(jobName, name, perms)

    VFW.DB.LoadJobs()
    Boss.NotifyPanel(jobName)
    return true, "Rôle créé"
end)

Staff29.Cb("core:jobs:updateRole", function(source, data)
    if not Staff29.IsTable(data) or not Staff29.IsTable(data.role) then return false, "Les informations envoyées ne sont pas valides" end

    local xPlayer = VFW.GetPlayerFromId(source)
    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or (xPlayer and xPlayer.job.name)
    if not jobName then return false, "Cette société n'est pas valide" end
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_permissions") then
        return false, "Permission insuffisante"
    end

    local role = data.role
    local name = Staff29.Clean(role.name, 60)
    if not name or name == "" then return false, "Ce rôle n'est pas valide" end

    local label = Staff29.Clean(role.label, 80) or name
    local salary = Staff29.ToInt(role.salary, 0, 10000000) or 0

    Staff29.Update([[
        UPDATE job_grades SET label = ?, salary = ? WHERE job_name = ? AND name = ?
    ]], { label, salary, jobName, name })

    local perms = {}
    if Staff29.IsTable(role.permissions) then
        for i = 1, #role.permissions do
            local entry = role.permissions[i]
            if Staff29.IsTable(entry) and entry.name then
                perms[entry.name] = entry.enabled ~= false
            elseif type(entry) == "string" then
                perms[entry] = true
            end
        end
        Boss.SetGradePerms(jobName, name, perms)
    end

    VFW.DB.LoadJobs()
    Boss.NotifyPanel(jobName)
    return true, "Rôle mis à jour"
end)

Staff29.Cb("core:jobs:reorderGrades", function(source, data)
    if not Staff29.IsTable(data) then return false, "Les informations envoyées ne sont pas valides" end

    local xPlayer = VFW.GetPlayerFromId(source)
    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or (xPlayer and xPlayer.job.name)
    local gradeA = Staff29.ToInt(data.gradeA, 0, 100)
    local gradeB = Staff29.ToInt(data.gradeB, 0, 100)

    if not jobName or not gradeA or not gradeB or gradeA == gradeB then return false, "Ces grades ne sont pas valides" end
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_permissions") then
        return false, "Permission insuffisante"
    end

    local temp = 999
    Staff29.Update("UPDATE job_grades SET grade = ? WHERE job_name = ? AND grade = ?", { temp, jobName, gradeA })
    Staff29.Update("UPDATE job_grades SET grade = ? WHERE job_name = ? AND grade = ?", { gradeA, jobName, gradeB })
    Staff29.Update("UPDATE job_grades SET grade = ? WHERE job_name = ? AND grade = ?", { gradeB, jobName, temp })

    Staff29.Update("UPDATE characters SET job_grade = ? WHERE job = ? AND job_grade = ?", { temp, jobName, gradeA })
    Staff29.Update("UPDATE characters SET job_grade = ? WHERE job = ? AND job_grade = ?", { gradeA, jobName, gradeB })
    Staff29.Update("UPDATE characters SET job_grade = ? WHERE job = ? AND job_grade = ?", { gradeB, jobName, temp })

    VFW.DB.LoadJobs()
    Boss.NotifyPanel(jobName)
    return true, "Grades réordonnés"
end)

Staff29.Cb("core:jobs:fireEmployee", function(source, employeeId)
    if not Staff29.IsString(employeeId, 80) then return false, "Cet employé n'est pas valide" end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable" end

    local jobName = xPlayer.job.name
    if not Boss.HasBossPermission(xPlayer, jobName, "kick") then return false, "Permission insuffisante" end
    if employeeId == xPlayer.identifier then return false, "Vous ne pouvez pas vous licencier" end

    local target = Staff29.Single(
        "SELECT identifier, job FROM characters WHERE identifier = ? AND deleted_at IS NULL", { employeeId })
    if not target or target.job ~= jobName then return false, "Employé introuvable" end

    Boss.ArchiveLockers(jobName, employeeId)
    Staff29.Update("DELETE FROM society_favorites WHERE job_name = ? AND identifier = ?", { jobName, employeeId })
    Staff29.Update("DELETE FROM society_services WHERE job_name = ? AND identifier = ?", { jobName, employeeId })

    local online = VFW.GetPlayerFromIdentifier(employeeId)
    if online then
        online.setJob("unemployed", 0, false)
        online.save()
        online.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Emploi",
            message = "Vous avez été licencié.",
        })
    else
        Staff29.Update(
            "UPDATE characters SET job = 'unemployed', job_grade = 0, job_duty = 0 WHERE identifier = ?", { employeeId })
    end

    Boss.NotifyPanel(jobName)
    return true, "Employé licencié"
end)

Staff29.Cb("core:boss:depositMoney", function(source, data)
    if not Staff29.IsTable(data) then return false, "Les informations envoyées ne sont pas valides", 0 end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable", 0 end

    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or xPlayer.job.name
    local amount = Staff29.ToInt(data.amount, 1, 999999999)
    if not amount then return false, "Ce montant n'est pas valide", Boss.GetSocietyMoney(jobName) end
    if not Boss.HasBossPermission(xPlayer, jobName, "accounting") then
        return false, "Permission insuffisante", Boss.GetSocietyMoney(jobName)
    end

    local account = xPlayer.getAccount("bank")
    if not account or account.money < amount then
        return false, "Fonds bancaires insuffisants", Boss.GetSocietyMoney(jobName)
    end

    xPlayer.removeAccountMoney("bank", amount, "society-deposit")
    local newBalance = Boss.AddSocietyMoney(jobName, amount)

    Staff29.Insert([[
        INSERT INTO society_billings (job_name, sender, receiver, target_identifier, date, total, statut, type, items)
        VALUES (?, ?, ?, ?, ?, ?, 1, 'deposit', ?)
    ]], { jobName, xPlayer.name, jobName, xPlayer.identifier, Staff29.Now(), amount, "[]" })

    Boss.NotifyPanel(jobName)
    return true, "Dépôt effectué", newBalance
end)

Staff29.Cb("core:boss:withdrawMoney", function(source, data)
    if not Staff29.IsTable(data) then return false, "Les informations envoyées ne sont pas valides", 0 end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable", 0 end

    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or xPlayer.job.name
    local amount = Staff29.ToInt(data.amount, 1, 999999999)
    local balance = Boss.GetSocietyMoney(jobName)

    if not amount then return false, "Ce montant n'est pas valide", balance end
    if not Boss.HasBossPermission(xPlayer, jobName, "accounting") then
        return false, "Permission insuffisante", balance
    end
    if balance < amount then return false, "Fonds de société insuffisants", balance end

    local newBalance = Boss.SetSocietyMoney(jobName, balance - amount)
    xPlayer.addAccountMoney("bank", amount, "society-withdraw")

    Staff29.Insert([[
        INSERT INTO society_billings (job_name, sender, receiver, target_identifier, date, total, statut, type, items)
        VALUES (?, ?, ?, ?, ?, ?, 1, 'withdraw', ?)
    ]], { jobName, jobName, xPlayer.name, xPlayer.identifier, Staff29.Now(), amount, "[]" })

    Boss.NotifyPanel(jobName)
    return true, "Retrait effectué", newBalance
end)

Staff29.Cb("boss:transferToEmployee", function(source, data)
    if not Staff29.IsTable(data) then return false, "Les informations envoyées ne sont pas valides", 0 end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable", 0 end

    local jobName = xPlayer.job.name
    local balance = Boss.GetSocietyMoney(jobName)
    local amount = Staff29.ToInt(data.amount, 1, 999999999)
    local targetIdentifier = data.targetIdentifier

    if not amount or not Staff29.IsString(targetIdentifier, 80) then
        return false, "Les informations envoyées ne sont pas valides", balance
    end
    if not Boss.HasBossPermission(xPlayer, jobName, "accounting") then
        return false, "Permission insuffisante", balance
    end
    if balance < amount then return false, "Fonds de société insuffisants", balance end

    local target = Staff29.Single(
        "SELECT identifier, job FROM characters WHERE identifier = ? AND deleted_at IS NULL", { targetIdentifier })
    if not target or target.job ~= jobName then return false, "Employé introuvable", balance end

    local newBalance = Boss.SetSocietyMoney(jobName, balance - amount)

    local online = VFW.GetPlayerFromIdentifier(targetIdentifier)
    if online then
        online.addAccountMoney("bank", amount, "society-transfer")
        online.showNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "Salaire",
            message = ("Vous avez reçu %d$ de %s."):format(amount, jobName),
        })
    else
        local row = Staff29.Single("SELECT accounts FROM characters WHERE identifier = ?", { targetIdentifier })
        local accounts = Staff29.Decode(row and row.accounts, {})
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
        Staff29.Update("UPDATE characters SET accounts = ? WHERE identifier = ?",
            { Staff29.Encode(accounts), targetIdentifier })
    end

    Staff29.Insert([[
        INSERT INTO society_billings (job_name, sender, receiver, target_identifier, date, total, statut, type, items)
        VALUES (?, ?, ?, ?, ?, ?, 1, 'withdraw', ?)
    ]], { jobName, jobName, tostring(data.targetName or targetIdentifier), targetIdentifier,
          Staff29.Now(), amount, "[]" })

    Boss.NotifyPanel(jobName)
    return true, "Transfert effectué", newBalance
end)

local function updateSocialPerm(source, data, column)
    if not Staff29.IsTable(data) then return false, "Les informations envoyées ne sont pas valides" end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable" end

    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or xPlayer.job.name
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_permissions") then
        return false, "Permission insuffisante"
    end

    local custom = Boss.GetCustom(jobName)
    local perms = column == "weazel_perms" and custom.weazelPerms or custom.lifeinvaderPerms
    local payload = Staff29.IsTable(data.perms) and data.perms or data

    for _, key in ipairs({ "create", "edit", "schedule", "delete", "broadcast" }) do
        if payload[key] ~= nil then
            perms[key] = (payload[key] == true or payload[key] == 1) and 1 or 0
        end
    end

    Staff29.Update(([[
        INSERT INTO society_custom (job_name, %s) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE %s = VALUES(%s)
    ]]):format(column, column, column), { jobName, Staff29.Encode(perms) })

    Boss.NotifyPanel(jobName)
    return true, "Permissions mises à jour"
end

Staff29.Cb("core:jobs:updateWeazelPerm", function(source, data)
    return updateSocialPerm(source, data, "weazel_perms")
end)

Staff29.Cb("core:jobs:updateLifeInvaderPerm", function(source, data)
    return updateSocialPerm(source, data, "lifeinvader_perms")
end)

Staff29.Cb("core:chest:getHistory", function(source, chestId)
    if chestId == nil then return {} end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if not Boss.HasBossPermission(xPlayer, xPlayer.job.name, "view_logs") then return {} end

    local rows = Staff29.Query(
        "SELECT * FROM chest_history WHERE chest_id = ? ORDER BY id DESC LIMIT 200", { tostring(chestId) })

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            id = row.id,
            chest_id = row.chest_id,
            identifier = row.identifier or row.citizenid or "",
            name = row.player_name or "",
            action = row.action or "",
            item = row.item or row.item_name or "",
            count = tonumber(row.count) or 0,
            date = tostring(row.date or row.created_at or ""),
        }
    end
    return out
end)

Staff29.Cb("core:societyLockers:getEmployeeLockers", function(source, lockerId)
    if lockerId == nil then return {} end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if not Boss.HasBossPermission(xPlayer, xPlayer.job.name, "manage_locker") then return {} end

    local id = tonumber(lockerId) or 0
    local rows = Staff29.Query("SELECT * FROM society_locker_chests WHERE locker_id = ?", { id })
    if #rows == 0 then
        rows = Staff29.Query("SELECT * FROM society_locker_employees WHERE locker_id = ?", { id })
    end
    return rows
end)

Staff29.Cb("core:societyLockers:getArchivedLockers", function(source, jobName)
    if not Staff29.IsString(jobName, 60) then return {} end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_locker") then return {} end

    local rows = Staff29.Query(
        "SELECT * FROM society_lockers_archived WHERE job = ? ORDER BY id DESC LIMIT 200", { jobName })
    if #rows == 0 then
        rows = Staff29.Query(
            "SELECT * FROM society_locker_archives WHERE job_name = ? ORDER BY archived_id DESC LIMIT 200",
            { jobName })
    end

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        row.archivedId = row.id or row.archived_id
        out[n] = row
    end
    return out
end)

Staff29.Cb("core:societyLockers:deleteArchivedLocker", function(source, archivedId)
    if archivedId == nil then return false, "Ce casier n'est pas valide" end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable" end
    if not Boss.HasBossPermission(xPlayer, xPlayer.job.name, "manage_locker") then
        return false, "Permission insuffisante"
    end

    local id = tonumber(archivedId) or 0
    Staff29.Update("DELETE FROM society_lockers_archived WHERE id = ?", { id })
    Staff29.Update("DELETE FROM society_locker_archives WHERE archived_id = ?", { id })
    return true, "Casier archivé supprimé"
end)

local function expireContract(contractId, silent)
    local contract = contracts[contractId]
    if not contract then return end
    contracts[contractId] = nil

    Staff29.Update("UPDATE employment_contracts SET status = 'expired' WHERE contract_id = ?", { contractId })

    if not silent then
        local target = VFW.GetPlayerFromId(contract.targetSource)
        if target then target.triggerEvent("contract:cancelled") end
    end
end

Staff29.Cb("boss:proposeContract", function(source, data)
    if not Staff29.IsTable(data) then return false, "Les informations envoyées ne sont pas valides" end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Ce joueur est introuvable" end

    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or xPlayer.job.name
    local targetServerId = Staff29.ToInt(data.targetServerId, 1, 1024)
    local role = data.role

    if not targetServerId or not Staff29.IsTable(role) then return false, "Les informations envoyées ne sont pas valides" end
    if not Boss.HasBossPermission(xPlayer, jobName, "recruit") then return false, "Permission insuffisante" end

    local target = VFW.GetPlayerFromId(targetServerId)
    if not target then return false, "Joueur cible introuvable" end
    if target.source == xPlayer.source then return false, "Cette cible n'est pas valide" end
    if not Staff29.Distance(source, targetServerId, 5.0) then return false, "Le joueur est trop loin" end

    local grade = Staff29.ToInt(role.grade, 0, 100)
    if not grade then return false, "Ce grade n'est pas valide" end

    local job = VFW.Jobs[jobName]
    if not job or not job.grades[tostring(grade)] then return false, "Grade inexistant" end

    for id, contract in pairs(contracts) do
        if contract.targetIdentifier == target.identifier then
            expireContract(id, true)
        end
    end

    contractSeq = contractSeq + 1
    local contractId = ("%d-%d"):format(os.time(), contractSeq)

    local gradeData = job.grades[tostring(grade)]
    local metadata = {
        contractId = contractId,
        companyLabel = Staff29.Clean(data.jobLabel, 80) or job.label,
        companyName = jobName,
        roleLabel = gradeData.label,
        roleName = gradeData.name,
        salary = gradeData.salary or 0,
        recruiterName = xPlayer.name,
        employeeName = target.name,
        date = Staff29.Now(),
    }

    contracts[contractId] = {
        contractId = contractId,
        jobName = jobName,
        grade = grade,
        recruiterSource = source,
        recruiterIdentifier = xPlayer.identifier,
        targetSource = target.source,
        targetIdentifier = target.identifier,
        metadata = metadata,
        createdAt = GetGameTimer(),
    }

    Staff29.Insert([[
        INSERT INTO employment_contracts
            (contract_id, job_name, role, recruiter_identifier, target_identifier, status, created_at, metadata)
        VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)
    ]], { contractId, jobName, Staff29.Encode(role), xPlayer.identifier, target.identifier,
          Staff29.Now(), Staff29.Encode(metadata) })

    target.triggerEvent("contract:receiveOffer", metadata)

    VFW.SetTimeout(CONTRACT_TTL, function()
        expireContract(contractId, false)
    end)

    return true, "Offre envoyée"
end)

RegisterNetEvent("contract:signed", function(contractId)
    local source = source
    if type(contractId) ~= "string" and type(contractId) ~= "number" then return end

    local contract = contracts[tostring(contractId)]
    if not contract then return end
    if contract.targetSource ~= source then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.identifier ~= contract.targetIdentifier then return end

    contracts[tostring(contractId)] = nil

    Staff29.Update("UPDATE employment_contracts SET status = 'signed' WHERE contract_id = ?", { tostring(contractId) })

    xPlayer.setJob(contract.jobName, contract.grade, false)
    xPlayer.save()

    xPlayer.triggerEvent("contract:signedSuccess", contract.metadata.companyLabel, contract.metadata.roleLabel)

    local recruiter = VFW.GetPlayerFromId(contract.recruiterSource)
    if recruiter then
        recruiter.triggerEvent("boss:closePanelAfterRecruit")
        recruiter.showNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "Recrutement",
            message = ("%s a signé le contrat."):format(xPlayer.name),
        })
    end

    if VFW.Items and VFW.Items["contract"] then
        xPlayer.addInventoryItem("contract", 1, contract.metadata, true)
    end

    Boss.NotifyPanel(contract.jobName)
end)

RegisterNetEvent("contract:refused", function(contractId)
    local source = source
    if type(contractId) ~= "string" and type(contractId) ~= "number" then return end

    local contract = contracts[tostring(contractId)]
    if not contract or contract.targetSource ~= source then return end

    contracts[tostring(contractId)] = nil
    Staff29.Update("UPDATE employment_contracts SET status = 'refused' WHERE contract_id = ?", { tostring(contractId) })

    local recruiter = VFW.GetPlayerFromId(contract.recruiterSource)
    if recruiter then
        recruiter.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Recrutement",
            message = "L'offre de contrat a été refusée.",
        })
    end
end)

RegisterNetEvent("contract:expired", function(contractId)
    local source = source
    if type(contractId) ~= "string" and type(contractId) ~= "number" then return end

    local contract = contracts[tostring(contractId)]
    if not contract or contract.targetSource ~= source then return end

    expireContract(tostring(contractId), true)

    local recruiter = VFW.GetPlayerFromId(contract.recruiterSource)
    if recruiter then
        recruiter.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Recrutement",
            message = "L'offre de contrat a expiré.",
        })
    end
end)

RegisterNetEvent("core:boss:updateChestAccess", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local jobName = Staff29.IsString(data.jobName, 60) and data.jobName or xPlayer.job.name
    if not Boss.HasBossPermission(xPlayer, jobName, "manage_chest") then return end

    local entries = Staff29.IsTable(data.access) and data.access or data
    for key, value in pairs(entries) do
        if type(key) == "string" and (type(value) == "boolean" or type(value) == "number") then
            Staff29.Update([[
                INSERT INTO society_chest_access (job_name, subject, allowed) VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE allowed = VALUES(allowed)
            ]], { jobName, key, (value == true or value == 1) and 1 or 0 })
        end
    end

    xPlayer.triggerEvent("core:jobs:updateBossPanel")
end)

AddEventHandler("vfw:playerDropped", function(source)
    for id, contract in pairs(contracts) do
        if contract.recruiterSource == source then
            local target = VFW.GetPlayerFromId(contract.targetSource)
            if target then target.triggerEvent("contract:cancelled") end
            contracts[id] = nil
            Staff29.Update("UPDATE employment_contracts SET status = 'expired' WHERE contract_id = ?", { id })
        elseif contract.targetSource == source then
            contracts[id] = nil
            Staff29.Update("UPDATE employment_contracts SET status = 'expired' WHERE contract_id = ?", { id })
        end
    end
end)
