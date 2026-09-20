local SAMS = {}

local mdtSubscribers = {}
local alerts = {}
local backups = {}
local backupSeq = 0
local alertSeq = 0

local function config()
    return SN_SAMS and SN_SAMS.Config or { Jobs = { "sams_pib", "sams_pab" }, Permissions = {}, BossGrades = { 99, 98 } }
end

function SAMS.Jobs()
    return config().Jobs or { "sams_pib", "sams_pab" }
end

function SAMS.HasJob(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local jobs = SAMS.Jobs()
    for i = 1, #jobs do
        if xPlayer.job.name == jobs[i] then return true end
    end
    return false
end

function SAMS.Hospital(xPlayer)
    if not xPlayer or not xPlayer.job then return "pillbox" end
    if xPlayer.job.name == "sams_pab" then return "paleto" end
    return "pillbox"
end

function SAMS.HospitalLabel(hospital)
    local hospitals = config().Hospitals or {}
    return hospitals[hospital] and hospitals[hospital].label or (hospital == "paleto" and "Paleto Bay" or "Pillbox Hill")
end

local function isBossGrade(grade)
    local list = config().BossGrades or {}
    for i = 1, #list do
        if list[i] == grade then return true end
    end
    return false
end

function SAMS.AllPermissions(value)
    local out = {}
    local list = config().Permissions or {}
    for i = 1, #list do out[list[i]] = value and true or false end
    return out
end

function SAMS.GetGradePermissions(hospital, grade)
    if isBossGrade(grade) then return SAMS.AllPermissions(true) end

    local row = Staff29.Single(
        "SELECT permissions FROM sams_grade_permissions WHERE hospital = ? AND grade = ?",
        { hospital, tostring(grade) })

    local perms = SAMS.AllPermissions(false)
    local decoded = row and Staff29.Decode(row.permissions, nil) or nil
    if type(decoded) == "table" then
        for key, value in pairs(decoded) do
            if perms[key] ~= nil then perms[key] = value == true end
        end
    end
    return perms
end

function SAMS.AgentPermissions(xPlayer, staffMode)
    if staffMode then return SAMS.AllPermissions(true) end
    if not xPlayer then return SAMS.AllPermissions(false) end
    if xPlayer.hasPermission("mdt_sams_staff") or xPlayer.hasPermission("sams_management") then
        return SAMS.AllPermissions(true)
    end
    return SAMS.GetGradePermissions(SAMS.Hospital(xPlayer), xPlayer.job.grade)
end

function SAMS.Can(xPlayer, permission)
    local perms = SAMS.AgentPermissions(xPlayer, false)
    return perms[permission] == true
end

function SAMS.Broadcast(event, ...)
    local agents = VFW.GetPlayersWithJobs(SAMS.Jobs())
    for i = 1, #agents do
        agents[i].triggerEvent(event, ...)
    end
    for src in pairs(mdtSubscribers) do
        local xPlayer = VFW.GetPlayerFromId(src)
        if xPlayer and not SAMS.HasJob(xPlayer) then
            xPlayer.triggerEvent(event, ...)
        end
    end
end

function SAMS.BroadcastOnDuty(event, ...)
    local agents = VFW.GetPlayersInJobsOnDuty(SAMS.Jobs())
    for i = 1, #agents do
        agents[i].triggerEvent(event, ...)
    end
end

local function fetchLogs(hospital, limit, beforeId)
    if beforeId then
        return Staff29.Query([[
            SELECT id, hospital, agent, action, details, created_at FROM sams_logs
            WHERE hospital = ? AND id < ? ORDER BY id DESC LIMIT ?
        ]], { hospital, beforeId, limit })
    end
    return Staff29.Query([[
        SELECT id, hospital, agent, action, details, created_at FROM sams_logs
        WHERE hospital = ? ORDER BY id DESC LIMIT ?
    ]], { hospital, limit })
end

local function fetchList(table_, hospital, limit, beforeId, extraWhere)
    local where = "hospital = ?"
    local params = { hospital }

    if extraWhere then where = where .. " AND " .. extraWhere end
    if beforeId then
        where = where .. " AND id < ?"
        params[#params + 1] = beforeId
    end
    params[#params + 1] = limit

    return Staff29.Query(("SELECT * FROM %s WHERE %s ORDER BY id DESC LIMIT ?"):format(table_, where), params)
end

local function activeAlerts()
    local out, n = {}, 0
    for _, alert in pairs(alerts) do
        n = n + 1
        out[n] = alert
    end
    table.sort(out, function(a, b) return (a.createdAt or 0) > (b.createdAt or 0) end)
    return out
end

local function fetchPersonnel()
    local jobs = SAMS.Jobs()
    local placeholders = {}
    for i = 1, #jobs do placeholders[i] = "?" end

    local rows = Staff29.Query(([[
        SELECT identifier, firstname, lastname, job, job_grade, job_duty, mugshot
        FROM characters WHERE job IN (%s) AND deleted_at IS NULL ORDER BY job_grade DESC
    ]]):format(table.concat(placeholders, ",")), jobs)

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local online = VFW.GetPlayerFromIdentifier(row.identifier)
        local job = VFW.Jobs[row.job]
        local gradeData = job and job.grades[tostring(row.job_grade)] or nil
        n = n + 1
        out[n] = {
            id = row.identifier,
            identifier = row.identifier,
            firstname = row.firstname or "",
            lastname = row.lastname or "",
            name = ("%s %s"):format(row.firstname or "", row.lastname or ""),
            hospital = row.job == "sams_pab" and "paleto" or "pillbox",
            grade = row.job_grade,
            gradeLabel = gradeData and gradeData.label or "Agent",
            onDuty = online and online.job.onDuty or (row.job_duty == 1),
            online = online ~= nil,
            mugshot = row.mugshot or "",
        }
    end
    return out
end

local function buildCitizen(row)
    if not row then return nil end
    local metadata = Staff29.Decode(row.metadata, {})
    local job = VFW.Jobs[row.job]
    return {
        id = row.identifier,
        identifier = row.identifier,
        citizenId = row.identifier,
        firstname = row.firstname or "",
        lastname = row.lastname or "",
        name = ("%s %s"):format(row.firstname or "", row.lastname or ""),
        dateofbirth = row.dateofbirth or "",
        sex = row.sex or "m",
        height = row.height or 0,
        phone = tostring(metadata.phone or metadata.phoneNumber or ""),
        mugshot = row.mugshot or "",
        job = row.job or "unemployed",
        jobLabel = job and job.label or "Sans emploi",
    }
end

local function fetchStats(hospital)
    return {
        reports = Staff29.Scalar("SELECT COUNT(*) FROM sams_reports WHERE hospital = ? AND deleted = 0",
            { hospital }, 0) or 0,
        invoices = Staff29.Scalar("SELECT COUNT(*) FROM sams_invoices WHERE hospital = ?", { hospital }, 0) or 0,
        unpaidInvoices = Staff29.Scalar(
            "SELECT COUNT(*) FROM sams_invoices WHERE hospital = ? AND status = 'unpaid'", { hospital }, 0) or 0,
        announcements = Staff29.Scalar("SELECT COUNT(*) FROM sams_announcements WHERE hospital = ?",
            { hospital }, 0) or 0,
        documents = Staff29.Scalar("SELECT COUNT(*) FROM sams_documents WHERE hospital = ?", { hospital }, 0) or 0,
        onDuty = #VFW.GetPlayersInJobsOnDuty(SAMS.Jobs()),
        alerts = #activeAlerts(),
    }
end

local function buildMDT(source, staffMode)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if not staffMode then
        if not SAMS.HasJob(xPlayer) then return nil end
        if not xPlayer.job.onDuty then return nil end
    end

    local hospital = SAMS.Hospital(xPlayer)
    local permissions = SAMS.AgentPermissions(xPlayer, staffMode)

    mdtSubscribers[source] = true

    return {
        agent = {
            identifier = xPlayer.identifier,
            name = xPlayer.name,
            firstname = xPlayer.firstName,
            lastname = xPlayer.lastName,
            hospital = hospital,
            hospitalLabel = SAMS.HospitalLabel(hospital),
            grade = xPlayer.job.grade,
            gradeLabel = xPlayer.job.grade_label or "Agent",
            mugshot = xPlayer.mugshot or "",
            onDuty = xPlayer.job.onDuty,
            staffMode = staffMode and true or false,
            permissions = permissions,
        },
        stats = fetchStats(hospital),
        logs = fetchLogs(hospital, 50, nil),
        reports = fetchList("sams_reports", hospital, 50, nil, "deleted = 0"),
        announcements = fetchList("sams_announcements", hospital, 50, nil, nil),
        invoices = fetchList("sams_invoices", hospital, 50, nil, nil),
        treatments = fetchList("sams_treatments", hospital, 100, nil, nil),
        procedures = fetchList("sams_procedures", hospital, 100, nil, nil),
        documents = fetchList("sams_documents", hospital, 50, nil, nil),
        medecins = fetchPersonnel(),
        alerts = activeAlerts(),
    }
end

Staff29.SAMS = SAMS

Staff29.Cb("sn_sams:openMDT", function(source)
    return buildMDT(source, false)
end)

Staff29.Cb("sn_sams:openMDTStaff", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("mdt_sams_staff") then return nil end
    return buildMDT(source, true)
end)

RegisterNetEvent("sn_sams:closeMDT", function()
    local source = source
    mdtSubscribers[source] = nil
end)

Staff29.Cb("sn_sams:loadMore", function(source, listType, beforeId, limit)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if not SAMS.HasJob(xPlayer) and not xPlayer.hasPermission("mdt_sams_staff") then return {} end
    if not Staff29.IsString(listType, 32) then return {} end

    local hospital = SAMS.Hospital(xPlayer)
    local max = Staff29.ToInt(limit, 1, 100) or 25
    local before = Staff29.ToInt(beforeId, 1, 2147483647)

    if listType == "logs" then return fetchLogs(hospital, max, before) end
    if listType == "reports" then return fetchList("sams_reports", hospital, max, before, "deleted = 0") end
    if listType == "announcements" then return fetchList("sams_announcements", hospital, max, before, nil) end
    if listType == "invoices" then return fetchList("sams_invoices", hospital, max, before, nil) end
    if listType == "procedures" then return fetchList("sams_procedures", hospital, max, before, nil) end
    if listType == "documents" then return fetchList("sams_documents", hospital, max, before, nil) end

    return {}
end)

Staff29.Cb("sn_sams:getCitizenByIdentifier", function(source, identifier)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return nil end
    if not Staff29.IsString(identifier, 80) then return nil end

    local row = Staff29.Single(
        "SELECT * FROM characters WHERE identifier = ? AND deleted_at IS NULL", { identifier })
    return buildCitizen(row)
end)

Staff29.Cb("sn_sams:searchCitizens", function(source, query)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return {} end
    if not Staff29.IsString(query, 60) or #query < 2 then return {} end

    local like = "%" .. query .. "%"
    local rows = Staff29.Query([[
        SELECT * FROM characters
        WHERE deleted_at IS NULL AND (firstname LIKE ? OR lastname LIKE ? OR identifier LIKE ?)
        ORDER BY lastname ASC LIMIT 50
    ]], { like, like, like })

    local out, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        out[n] = buildCitizen(rows[i])
    end
    return out
end)

Staff29.Cb("sn_sams:getAllCitizens", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then
        return { items = {}, page = 1, pageSize = 50, total = 0, totalPages = 1, hasPrev = false, hasNext = false }
    end

    data = Staff29.IsTable(data) and data or {}
    local page = Staff29.ToInt(data.page, 1, 100000) or 1
    local pageSize = Staff29.ToInt(data.pageSize, 1, 200) or 50
    local search = Staff29.IsString(data.search, 60) and ("%" .. data.search .. "%") or nil

    local total, rows

    if search then
        total = Staff29.Scalar([[
            SELECT COUNT(*) FROM characters
            WHERE deleted_at IS NULL AND (firstname LIKE ? OR lastname LIKE ? OR identifier LIKE ?)
        ]], { search, search, search }, 0) or 0
        rows = Staff29.Query([[
            SELECT * FROM characters
            WHERE deleted_at IS NULL AND (firstname LIKE ? OR lastname LIKE ? OR identifier LIKE ?)
            ORDER BY lastname ASC LIMIT ? OFFSET ?
        ]], { search, search, search, pageSize, (page - 1) * pageSize })
    else
        total = Staff29.Scalar("SELECT COUNT(*) FROM characters WHERE deleted_at IS NULL", {}, 0) or 0
        rows = Staff29.Query([[
            SELECT * FROM characters WHERE deleted_at IS NULL
            ORDER BY lastname ASC LIMIT ? OFFSET ?
        ]], { pageSize, (page - 1) * pageSize })
    end

    local items, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        items[n] = buildCitizen(rows[i])
    end

    total = tonumber(total) or 0
    local totalPages = math.max(1, math.ceil(total / pageSize))

    return {
        items = items,
        page = page,
        pageSize = pageSize,
        total = total,
        totalPages = totalPages,
        hasPrev = page > 1,
        hasNext = page < totalPages,
    }
end)

Staff29.Cb("sn_sams:getCitizenNotes", function(source, citizenId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return {} end
    if not Staff29.IsString(citizenId, 80) then return {} end

    return Staff29.Query([[
        SELECT id, citizen_identifier, author, note, created_at FROM sams_citizen_notes
        WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 100
    ]], { citizenId })
end)

Staff29.Cb("sn_sams:getPersonnel", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or (not SAMS.HasJob(xPlayer) and not xPlayer.hasPermission("mdt_sams_staff")) then return {} end
    return fetchPersonnel()
end)

Staff29.Cb("sn_sams:getNearbyPlayersInfo", function(source, players)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Staff29.IsTable(players) then return {} end

    local out, n = {}, 0
    for i = 1, #players do
        local entry = players[i]
        local sid = Staff29.IsTable(entry) and Staff29.ToInt(entry.serverId, 1, 1024) or nil
        if sid then
            local target = VFW.GetPlayerFromId(sid)
            if target then
                n = n + 1
                out[n] = {
                    id = target.identifier,
                    identifier = target.identifier,
                    serverId = sid,
                    firstname = target.firstName,
                    lastname = target.lastName,
                    name = target.name,
                    mugshot = target.mugshot or "",
                }
            end
        end
    end
    return out
end)

Staff29.Cb("sn_sams:getGradePermissions", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { grades = {}, permissions = {} } end
    if not SAMS.HasJob(xPlayer) and not xPlayer.hasPermission("mdt_sams_staff") then
        return { grades = {}, permissions = {} }
    end

    local hospital = SAMS.Hospital(xPlayer)
    local job = VFW.Jobs[xPlayer.job.name]
    local grades, n = {}, 0

    if job then
        for _, grade in pairs(job.grades) do
            n = n + 1
            grades[n] = {
                grade = grade.grade,
                name = grade.name,
                label = grade.label,
                permissions = SAMS.GetGradePermissions(hospital, grade.grade),
            }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
    end

    return {
        hospital = hospital,
        availablePermissions = config().Permissions or {},
        grades = grades,
    }
end)

RegisterNetEvent("sn_sams:updateGradePermissions", function(grade, permissions)
    local source = source
    if not Staff29.IsTable(permissions) then return end
    if grade == nil then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not SAMS.Can(xPlayer, "manage_permissions") and not xPlayer.hasPermission("mdt_sams_staff") then return end

    local hospital = SAMS.Hospital(xPlayer)
    local clean = SAMS.AllPermissions(false)
    for key, value in pairs(permissions) do
        if clean[key] ~= nil then clean[key] = value == true end
    end

    Staff29.Update([[
        INSERT INTO sams_grade_permissions (hospital, grade, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { hospital, tostring(grade), Staff29.Encode(clean) })

    SAMS.Broadcast("sn_sams:gradePermissionsUpdated", { hospital = hospital, grade = grade, permissions = clean })

    local agents = VFW.GetPlayersWithJobs(SAMS.Jobs())
    for i = 1, #agents do
        if tostring(agents[i].job.grade) == tostring(grade) and SAMS.Hospital(agents[i]) == hospital then
            agents[i].triggerEvent("sn_sams:permissionsUpdated", SAMS.AgentPermissions(agents[i], false))
        end
    end
end)

RegisterNetEvent("vfw:changeDuty", function(onDuty)
    local source = source
    if type(onDuty) ~= "boolean" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "changeDuty", 1000) then return end

    local previous = VFW.DeepCopy(xPlayer.job)
    xPlayer.setDuty(onDuty)

    xPlayer.triggerEvent("vfw:client:changeDuty", onDuty)
    xPlayer.triggerEvent("vfw:setJob", xPlayer.job, previous)

    Staff29.Insert([[
        INSERT INTO sams_logs (hospital, agent, action, details, created_at) VALUES (?, ?, ?, ?, ?)
    ]], { SAMS.Hospital(xPlayer), xPlayer.name, onDuty and "duty_on" or "duty_off", "", Staff29.Now() })

    if SAMS.HasJob(xPlayer) then
        SAMS.Broadcast("sn_sams:setMedecins", fetchPersonnel())
    end
end)

RegisterNetEvent("sn_sams:addNote", function(citizenId, note)
    local source = source
    if not Staff29.IsString(citizenId, 80) or not Staff29.IsString(note, 2000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "add_note") then return end
    if not Staff29.RateLimit(source, "samsAddNote", 1500) then return end

    local clean = Staff29.Clean(note, 2000)
    local id = Staff29.Insert([[
        INSERT INTO sams_citizen_notes (citizen_identifier, author, note, created_at) VALUES (?, ?, ?, ?)
    ]], { citizenId, xPlayer.name, clean, Staff29.Now() })

    SAMS.Broadcast("sn_sams:noteAdded", citizenId, {
        id = id,
        citizen_identifier = citizenId,
        author = xPlayer.name,
        note = clean,
        created_at = Staff29.Now(),
    })
end)

RegisterNetEvent("sn_sams:deleteNote", function(citizenId, noteId)
    local source = source
    if Staff29.EventBlocked("sn_sams:deleteNote", source) then return end
    if not Staff29.IsString(citizenId, 80) then return end

    local id = Staff29.ToInt(noteId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "delete_note") then return end

    Staff29.Update("DELETE FROM sams_citizen_notes WHERE id = ? AND citizen_identifier = ?", { id, citizenId })
    SAMS.Broadcast("sn_sams:noteRemoved", citizenId, id)
end)

RegisterNetEvent("sn_sams:updateCitizenPhone", function(citizenId, phone)
    local source = source
    if not Staff29.IsString(citizenId, 80) or type(phone) ~= "string" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return end

    local clean = Staff29.Clean(phone, 20) or ""
    local row = Staff29.Single("SELECT metadata FROM characters WHERE identifier = ?", { citizenId })
    if not row then return end

    local metadata = Staff29.Decode(row.metadata, {})
    metadata.phone = clean

    local online = VFW.GetPlayerFromIdentifier(citizenId)
    if online then
        online.setMeta("phone", clean)
    else
        Staff29.Update("UPDATE characters SET metadata = ? WHERE identifier = ?",
            { Staff29.Encode(metadata), citizenId })
    end

    SAMS.Broadcast("sn_sams:citizenPhoneUpdated", citizenId, clean)
end)

local function insertRecord(table_, columns, values)
    local marks = {}
    for i = 1, #values do marks[i] = "?" end
    return Staff29.Insert(
        ("INSERT INTO %s (%s) VALUES (%s)"):format(table_, table.concat(columns, ","), table.concat(marks, ",")),
        values)
end

RegisterNetEvent("sn_sams:submitReport", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "create_report") then return end
    if not Staff29.RateLimit(source, "samsReport", 2000) then return end

    local hospital = SAMS.Hospital(xPlayer)
    local title = Staff29.Clean(data.title, 160) or "Rapport"
    local content = Staff29.Clean(data.content or data.description, 8000) or ""
    local citizen = Staff29.IsString(data.citizenId, 80) and data.citizenId or
        (Staff29.IsString(data.citizen_identifier, 80) and data.citizen_identifier or "")

    local id = insertRecord("sams_reports",
        { "author_identifier", "citizen_identifier", "title", "content", "hospital", "deleted", "created_at", "updated_at" },
        { xPlayer.identifier, citizen, title, content, hospital, 0, Staff29.Now(), Staff29.Now() })

    SAMS.Broadcast("sn_sams:reportAdded", {
        id = id,
        author_identifier = xPlayer.identifier,
        author = xPlayer.name,
        citizen_identifier = citizen,
        title = title,
        content = content,
        hospital = hospital,
        created_at = Staff29.Now(),
    })
end)

local function samsDeleteReport(reportId)
    local source = source
    if Staff29.EventBlocked("sn_sams:deleteReport", source) then return end

    local id = Staff29.ToInt(reportId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "delete_report") then return end

    Staff29.Update("UPDATE sams_reports SET deleted = 1, updated_at = ? WHERE id = ?", { Staff29.Now(), id })
    SAMS.Broadcast("sn_sams:reportRemoved", id)
end

RegisterNetEvent("sn_sams:deleteReport", samsDeleteReport)

Staff29.Cb("sn_sams:getDeletedReports", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "delete_report") then return {} end
    return Staff29.Query([[
        SELECT * FROM sams_reports WHERE hospital = ? AND deleted = 1 ORDER BY id DESC LIMIT 100
    ]], { SAMS.Hospital(xPlayer) })
end)

local function samsRestoreReport(reportId)
    local source = source
    local id = Staff29.ToInt(reportId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "delete_report") then return end

    Staff29.Update("UPDATE sams_reports SET deleted = 0, updated_at = ? WHERE id = ?", { Staff29.Now(), id })
    local row = Staff29.Single("SELECT * FROM sams_reports WHERE id = ?", { id })
    SAMS.Broadcast("sn_sams:reportRestored", row or { id = id })
end

RegisterNetEvent("sn_sams:restoreReport", samsRestoreReport)

RegisterNetEvent("sn_sams:editReport", function(reportId, field, value)
    local source = source
    local id = Staff29.ToInt(reportId, 1, 2147483647)
    if not id or not Staff29.IsString(field, 32) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "edit_report") then return end

    local allowed = { title = true, content = true, citizen_identifier = true }
    if not allowed[field] then return end
    if type(value) ~= "string" and type(value) ~= "number" then return end

    local clean = Staff29.Clean(tostring(value), field == "content" and 8000 or 160) or ""
    Staff29.Update(("UPDATE sams_reports SET %s = ?, updated_at = ? WHERE id = ?"):format(field),
        { clean, Staff29.Now(), id })

    SAMS.Broadcast("sn_sams:reportUpdated", { id = id, field = field, value = clean })
end)

RegisterNetEvent("sn_sams:submitDocument", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "create_document") then return end
    if not Staff29.RateLimit(source, "samsDocument", 2000) then return end

    local hospital = SAMS.Hospital(xPlayer)
    local docType = Staff29.Clean(data.type, 60) or "document"
    local citizen = Staff29.IsString(data.citizenId, 80) and data.citizenId or ""

    local id = insertRecord("sams_documents",
        { "author_identifier", "citizen_identifier", "type", "content", "hospital", "created_at" },
        { xPlayer.identifier, citizen, docType, Staff29.Encode(data), hospital, Staff29.Now() })

    SAMS.Broadcast("sn_sams:documentAdded", {
        id = id,
        author_identifier = xPlayer.identifier,
        author = xPlayer.name,
        citizen_identifier = citizen,
        type = docType,
        content = data,
        hospital = hospital,
        created_at = Staff29.Now(),
    })
end)

RegisterNetEvent("sn_sams:deleteDocument", function(documentId)
    local source = source
    if Staff29.EventBlocked("sn_sams:deleteDocument", source) then return end

    local id = Staff29.ToInt(documentId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "create_document") then return end

    Staff29.Update("DELETE FROM sams_documents WHERE id = ?", { id })
    SAMS.Broadcast("sn_sams:documentRemoved", id)
end)

RegisterNetEvent("sn_sams:giveDocumentPaper", function(documentId)
    local source = source
    local id = Staff29.ToInt(documentId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return end

    local row = Staff29.Single("SELECT * FROM sams_documents WHERE id = ?", { id })
    if not row then return end

    local metadata = {
        documentId = id,
        type = row.type,
        content = Staff29.Decode(row.content, {}),
        hospital = row.hospital,
        createdAt = tostring(row.created_at or ""),
    }

    if VFW.Items and VFW.Items["sams_document"] then
        if not xPlayer.canCarryItem("sams_document", 1) then
            xPlayer.showNotification({
                type = "STAFF", variant = "ERROR", subtitle = "SAMS",
                message = "Votre inventaire est plein.",
            })
            return
        end
        xPlayer.addInventoryItem("sams_document", 1, metadata, true)
    else
        xPlayer.triggerEvent("sn_sams:openPaperDocument", metadata)
    end
end)

RegisterNetEvent("sn_sams:createAnnouncement", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "create_announcement") then return end
    if not Staff29.RateLimit(source, "samsAnnouncement", 3000) then return end

    local hospital = SAMS.Hospital(xPlayer)
    local title = Staff29.Clean(data.title, 160) or "Annonce"
    local content = Staff29.Clean(data.content, 8000) or ""
    local priority = data.priority
    if priority ~= "urgent" and priority ~= "important" then priority = "normal" end

    local id = insertRecord("sams_announcements",
        { "author", "title", "content", "priority", "hospital", "created_at", "updated_at" },
        { xPlayer.name, title, content, priority, hospital, Staff29.Now(), Staff29.Now() })

    local announcement = {
        id = id, author = xPlayer.name, title = title, content = content,
        priority = priority, hospital = hospital, created_at = Staff29.Now(),
    }

    SAMS.Broadcast("sn_sams:announcementAdded", announcement)
    SAMS.Broadcast("sn_sams:announcementNotification",
        { title = title, author = xPlayer.name, priority = priority })
end)

RegisterNetEvent("sn_sams:editAnnouncement", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local id = Staff29.ToInt(data.id, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "edit_announcement") then return end

    local title = Staff29.Clean(data.title, 160) or "Annonce"
    local content = Staff29.Clean(data.content, 8000) or ""
    local priority = data.priority
    if priority ~= "urgent" and priority ~= "important" then priority = "normal" end

    Staff29.Update([[
        UPDATE sams_announcements SET title = ?, content = ?, priority = ?, updated_at = ? WHERE id = ?
    ]], { title, content, priority, Staff29.Now(), id })

    local announcement = {
        id = id, author = xPlayer.name, title = title, content = content,
        priority = priority, hospital = SAMS.Hospital(xPlayer), updated_at = Staff29.Now(),
    }

    SAMS.Broadcast("sn_sams:announcementUpdated", announcement)
    SAMS.Broadcast("sn_sams:announcementNotification",
        { title = title, author = xPlayer.name, priority = priority })
end)

local function samsDeleteAnnouncement(announcementId)
    local source = source
    if Staff29.EventBlocked("sn_sams:deleteAnnouncement", source) then return end

    local id = Staff29.ToInt(announcementId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "delete_announcement") then return end

    Staff29.Update("DELETE FROM sams_announcements WHERE id = ?", { id })
    SAMS.Broadcast("sn_sams:announcementDeleted", { id = id })
end

RegisterNetEvent("sn_sams:deleteAnnouncement", samsDeleteAnnouncement)

RegisterNetEvent("sn_sams:createInvoice", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "create_invoice") then return end
    if not Staff29.RateLimit(source, "samsInvoice", 2000) then return end

    local citizen = Staff29.IsString(data.citizenId, 80) and data.citizenId or
        (Staff29.IsString(data.citizen_identifier, 80) and data.citizen_identifier or nil)
    if not citizen then return end

    local items = Staff29.IsTable(data.items) and data.items or {}
    local total = 0
    local cleanItems, n = {}, 0

    for i = 1, #items do
        local entry = items[i]
        if Staff29.IsTable(entry) then
            local quantity = Staff29.ToInt(entry.quantity, 1, 1000) or 1
            local price = Staff29.ToInt(entry.price, 0, 10000000) or 0
            n = n + 1
            cleanItems[n] = { name = Staff29.Clean(entry.name, 80) or "Soin", quantity = quantity }
            total = total + (price * quantity)
        end
    end

    if total <= 0 then
        total = Staff29.ToInt(data.total, 1, 10000000) or 0
    end
    if total <= 0 then return end

    local hospital = SAMS.Hospital(xPlayer)
    local id = insertRecord("sams_invoices",
        { "citizen_identifier", "created_by", "hospital", "total", "items", "status", "date" },
        { citizen, xPlayer.name, hospital, total, Staff29.Encode(cleanItems), "unpaid", Staff29.Now() })

    local invoice = {
        id = id, citizen_identifier = citizen, createdBy = xPlayer.name, created_by = xPlayer.name,
        hospital = hospital, total = total, items = Staff29.Encode(cleanItems),
        status = "unpaid", date = Staff29.Now(),
    }

    SAMS.Broadcast("sn_sams:invoiceAdded", invoice)

    local patient = VFW.GetPlayerFromIdentifier(citizen)
    if patient then
        patient.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Facture médicale",
            message = ("Vous avez reçu une facture de %d$ (%s)."):format(total, SAMS.HospitalLabel(hospital)),
        })
    end
end)

local function samsCancelInvoice(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local id = Staff29.ToInt(data.id or data.invoiceId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "cancel_invoice") then return end

    Staff29.Update("UPDATE sams_invoices SET status = 'cancelled' WHERE id = ?", { id })
    SAMS.Broadcast("sn_sams:invoiceUpdated", { id = id, status = "cancelled" })
end

RegisterNetEvent("sn_sams:cancelInvoice", samsCancelInvoice)

local function crudRecord(kind, table_, permissionCreate, permissionEdit, permissionDelete)
    RegisterNetEvent(("sn_sams:create%s"):format(kind), function(data)
        local source = source
        if not Staff29.IsTable(data) then return end

        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not SAMS.Can(xPlayer, permissionCreate) then return end

        local hospital = SAMS.Hospital(xPlayer)
        local name = Staff29.Clean(data.name, 120) or kind
        local description = Staff29.Clean(data.description, 4000) or ""
        local price = Staff29.ToInt(data.price, 0, 10000000) or 0

        local id
        if table_ == "sams_treatments" then
            id = insertRecord(table_, { "name", "description", "price", "hospital" },
                { name, description, price, hospital })
        else
            id = insertRecord(table_, { "name", "description", "hospital" }, { name, description, hospital })
        end

        SAMS.Broadcast(("sn_sams:%sAdded"):format(kind:lower()), {
            id = id, name = name, description = description, price = price, hospital = hospital,
        })
    end)

    RegisterNetEvent(("sn_sams:edit%s"):format(kind), function(data)
        local source = source
        if not Staff29.IsTable(data) then return end

        local id = Staff29.ToInt(data.id, 1, 2147483647)
        if not id then return end

        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not SAMS.Can(xPlayer, permissionEdit) then return end

        local name = Staff29.Clean(data.name, 120) or kind
        local description = Staff29.Clean(data.description, 4000) or ""
        local price = Staff29.ToInt(data.price, 0, 10000000) or 0

        if table_ == "sams_treatments" then
            Staff29.Update(("UPDATE %s SET name = ?, description = ?, price = ? WHERE id = ?"):format(table_),
                { name, description, price, id })
        else
            Staff29.Update(("UPDATE %s SET name = ?, description = ? WHERE id = ?"):format(table_),
                { name, description, id })
        end

        SAMS.Broadcast(("sn_sams:%sUpdated"):format(kind:lower()), {
            id = id, name = name, description = description, price = price,
        })
    end)

    RegisterNetEvent(("sn_sams:delete%s"):format(kind), function(data)
        local source = source
        if Staff29.EventBlocked(("sn_sams:delete%s"):format(kind), source) then return end

        local id
        if Staff29.IsTable(data) then
            id = Staff29.ToInt(data.id or data[kind:lower() .. "Id"], 1, 2147483647)
        else
            id = Staff29.ToInt(data, 1, 2147483647)
        end
        if not id then return end

        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not SAMS.Can(xPlayer, permissionDelete) then return end

        Staff29.Update(("DELETE FROM %s WHERE id = ?"):format(table_), { id })
        SAMS.Broadcast(("sn_sams:%sRemoved"):format(kind:lower()), id)
    end)
end

crudRecord("Treatment", "sams_treatments", "create_treatment", "edit_treatment", "delete_treatment")
crudRecord("Procedure", "sams_procedures", "create_procedure", "edit_procedure", "delete_procedure")

Staff29.Cb("sn_sams:hasPPALeger", function(source, citizenId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return false end
    if not Staff29.IsString(citizenId, 80) then return false end

    local count = Staff29.Scalar(
        "SELECT COUNT(*) FROM vip_ppa WHERE identifier = ? AND type = 'leger'", { citizenId }, 0) or 0
    return (tonumber(count) or 0) > 0
end)

RegisterNetEvent("sn_sams:grantPPALeger", function(citizenId)
    local source = source
    if not Staff29.IsString(citizenId, 80) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.Can(xPlayer, "manage_ppa") then return end
    if not Staff29.RateLimit(source, "samsPPA", 2000) then return end

    local ok, issued, until_ = Staff29.GrantPPA(citizenId, "leger", 30)
    if not ok then return end

    local target = VFW.GetPlayerFromIdentifier(citizenId)
    if target then
        target.addLicense("ppa_leger", "PPA Léger")
        target.showNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "PPA",
            message = "Votre PPA léger a été délivré.",
        })
    end

    xPlayer.triggerEvent("sn_sams:ppaLegerStatus", {
        citizenId = citizenId,
        hasPPA = true,
        issuedAt = issued,
        validUntil = until_,
    })

    Staff29.Insert([[
        INSERT INTO sams_logs (hospital, agent, action, details, created_at) VALUES (?, ?, ?, ?, ?)
    ]], { SAMS.Hospital(xPlayer), xPlayer.name, "grant_ppa_leger", citizenId, Staff29.Now() })
end)

function SAMS.CreateAlert(data)
    if type(data) ~= "table" then return nil end

    alertSeq = alertSeq + 1
    local id = alertSeq

    local alert = {
        id = id,
        type = data.type or "urgence",
        description = data.description or "Appel d'urgence",
        citizenIdentifier = data.citizenIdentifier,
        coordinates = Staff29.Vec(data.coordinates) or { x = 0.0, y = 0.0, z = 0.0 },
        state = "open",
        takenBy = nil,
        agentName = nil,
        createdAt = os.time(),
    }

    alerts[id] = alert

    alert.dbId = Staff29.Insert([[
        INSERT INTO sams_alerts (type, description, citizen_identifier, coordinates, state, created_at)
        VALUES (?, ?, ?, ?, 'open', ?)
    ]], { alert.type, alert.description, alert.citizenIdentifier or "",
          Staff29.Encode(alert.coordinates), Staff29.Now() })

    SAMS.BroadcastOnDuty("sn_sams:newAlert", alert)
    SAMS.BroadcastOnDuty("sn_sams:alertNotification", alert)

    return id
end

AddEventHandler("sn_sams:server:createAlert", function(data)
    SAMS.CreateAlert(data)
end)

local function changeAlertState(source, alertId, newState, changeType)
    local id = Staff29.ToInt(alertId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return end
    if not SAMS.Can(xPlayer, "take_alert") then return end

    local alert = alerts[id]
    if not alert then return end

    if newState == "taken" then
        if alert.state == "taken" and alert.takenBy ~= xPlayer.identifier then return end
        alert.state = "taken"
        alert.takenBy = xPlayer.identifier
        alert.agentName = xPlayer.name
    elseif newState == "open" then
        if alert.takenBy ~= xPlayer.identifier then return end
        alert.state = "open"
        alert.takenBy = nil
        alert.agentName = nil
    elseif newState == "resolved" then
        alert.state = "resolved"
        alerts[id] = nil
    end

    if alert.dbId then
        Staff29.Update([[
            UPDATE sams_alerts SET state = ?, taken_by = ?, resolved_at = ? WHERE id = ?
        ]], { newState, alert.takenBy or "", newState == "resolved" and Staff29.Now() or nil, alert.dbId })
    end

    SAMS.BroadcastOnDuty("sn_sams:updateAlert", alert)
    SAMS.BroadcastOnDuty("sn_sams:alertStateChanged", {
        changeType = changeType,
        agentName = xPlayer.name,
        description = alert.description,
        coordinates = alert.coordinates,
    })
end

RegisterNetEvent("sn_sams:takeAlert", function(alertId)
    local source = source
    changeAlertState(source, alertId, "taken", "taken")
end)

RegisterNetEvent("sn_sams:untakeAlert", function(alertId)
    local source = source
    changeAlertState(source, alertId, "open", "untaken")
end)

RegisterNetEvent("sn_sams:resolveAlert", function(alertId)
    local source = source
    changeAlertState(source, alertId, "resolved", "resolved")
end)

RegisterNetEvent("sn_sams:relocateAlert", function(alertId)
    local source = source
    local id = Staff29.ToInt(alertId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return end

    local alert = alerts[id]
    if not alert then return end

    if alert.citizenIdentifier then
        local patient = VFW.GetPlayerFromIdentifier(alert.citizenIdentifier)
        if patient then
            local coords = patient.getCoords()
            if coords then alert.coordinates = coords end
        end
    end

    xPlayer.triggerEvent("sn_sams:setGPS", { x = alert.coordinates.x, y = alert.coordinates.y })
    SAMS.BroadcastOnDuty("sn_sams:updateAlert", alert)
end)

local BACKUP_LEVEL_LABELS = { "Niveau 1", "Niveau 2", "Niveau 3" }
local BACKUP_TARGET_LABELS = { pillbox = "Pillbox", paleto = "Paleto" }
local BACKUP_TTL = 300000

local function endBackup(id, reason)
    local backup = backups[id]
    if not backup then return end
    backups[id] = nil

    Staff29.Update("UPDATE sams_backups SET state = ? WHERE id = ?", { reason, backup.dbId or 0 })
    SAMS.BroadcastOnDuty("sn_sams:backupEnded", id)

    local requester = VFW.GetPlayerFromId(backup.requesterSource)
    if requester then requester.triggerEvent("sn_sams:myBackupResolved", id) end
end

RegisterNetEvent("sn_sams:requestBackup", function(level, myHospital, street, targetHospital)
    local source = source

    local lvl = Staff29.ToInt(level, 1, 3)
    if not lvl then return end
    if myHospital ~= "pillbox" and myHospital ~= "paleto" then myHospital = "pillbox" end
    if targetHospital ~= nil and targetHospital ~= "pillbox" and targetHospital ~= "paleto" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) or not xPlayer.job.onDuty then return end
    if not Staff29.RateLimit(source, "samsBackup", 3000) then return end

    local cleanStreet = Staff29.Clean(street, 120) or "Position inconnue"
    local coords = xPlayer.getCoords() or { x = 0.0, y = 0.0, z = 0.0 }

    local existingId = nil
    for id, backup in pairs(backups) do
        if backup.requesterIdentifier == xPlayer.identifier
            and backup.level == lvl and backup.targetHospital == targetHospital then
            existingId = id
            break
        end
    end

    local id = existingId
    if not id then
        backupSeq = backupSeq + 1
        id = backupSeq
    end

    local hospitals = config().Hospitals or {}
    local hospitalCoords = hospitals[targetHospital or myHospital]
    local distance = 0
    if hospitalCoords and hospitalCoords.coords then
        local dx = coords.x - hospitalCoords.coords.x
        local dy = coords.y - hospitalCoords.coords.y
        distance = math.floor(math.sqrt(dx * dx + dy * dy))
    end

    local dbId = Staff29.Insert([[
        INSERT INTO sams_backups (level, requester_identifier, hospital, target_hospital, street, coords, state, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
    ]], { lvl, xPlayer.identifier, myHospital, targetHospital, cleanStreet,
          Staff29.Encode(coords), Staff29.Now() })

    backups[id] = {
        id = id,
        dbId = dbId,
        level = lvl,
        levelLabel = BACKUP_LEVEL_LABELS[lvl],
        requesterSource = source,
        requesterIdentifier = xPlayer.identifier,
        requesterName = xPlayer.name,
        hospital = myHospital,
        targetHospital = targetHospital,
        street = cleanStreet,
        coords = coords,
        createdAt = GetGameTimer(),
    }

    local payload = {
        id = id,
        level = lvl,
        levelLabel = BACKUP_LEVEL_LABELS[lvl],
        requesterName = xPlayer.name,
        street = cleanStreet,
        distance = distance,
        coords = coords,
        targetHospitalLabel = targetHospital and BACKUP_TARGET_LABELS[targetHospital] or nil,
    }

    local agents = VFW.GetPlayersInJobsOnDuty(SAMS.Jobs())
    for i = 1, #agents do
        local agent = agents[i]
        if agent.source ~= source then
            if not targetHospital or SAMS.Hospital(agent) == targetHospital then
                agent.triggerEvent("sn_sams:backupRequest", payload)
            end
        end
    end

    xPlayer.triggerEvent("sn_sams:myBackupCreated", id, BACKUP_LEVEL_LABELS[lvl], lvl, targetHospital)

    VFW.SetTimeout(BACKUP_TTL, function()
        if backups[id] then endBackup(id, "expired") end
    end)
end)

RegisterNetEvent("sn_sams:acceptBackup", function(backupId)
    local source = source
    local id = Staff29.ToInt(backupId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return end

    local backup = backups[id]
    if not backup then return end

    Staff29.Update("UPDATE sams_backups SET state = 'accepted', accepted_by = ? WHERE id = ?",
        { xPlayer.identifier, backup.dbId or 0 })

    backups[id] = nil
    SAMS.BroadcastOnDuty("sn_sams:backupEnded", id)

    local requester = VFW.GetPlayerFromId(backup.requesterSource)
    if requester then
        requester.triggerEvent("sn_sams:myBackupResolved", id)
        requester.showNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "Backup",
            message = ("%s prend votre demande de renfort."):format(xPlayer.name),
        })
    end
end)

RegisterNetEvent("sn_sams:resolveBackup", function(backupId)
    local source = source
    local id = Staff29.ToInt(backupId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return end

    endBackup(id, "accepted")
end)

RegisterNetEvent("sn_sams:cancelBackup", function(backupId)
    local source = source
    local id = Staff29.ToInt(backupId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local backup = backups[id]
    if not backup then return end
    if backup.requesterSource ~= source and not xPlayer.hasPermission("mdt_sams_staff") then return end

    backups[id] = nil
    Staff29.Update("UPDATE sams_backups SET state = 'cancelled' WHERE id = ?", { backup.dbId or 0 })

    SAMS.BroadcastOnDuty("sn_sams:backupCancelled", id)

    local requester = VFW.GetPlayerFromId(backup.requesterSource)
    if requester then requester.triggerEvent("sn_sams:myBackupResolved", id) end
end)

Staff29.Cb("sn_sams:getActiveBackups", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return {} end

    local hospital = SAMS.Hospital(xPlayer)
    local out, n = {}, 0

    for _, backup in pairs(backups) do
        if not backup.targetHospital or backup.targetHospital == hospital then
            n = n + 1
            out[n] = {
                id = backup.id,
                coords = backup.coords,
                level = backup.level,
                levelLabel = backup.levelLabel,
                targetHospitalLabel = backup.targetHospital and BACKUP_TARGET_LABELS[backup.targetHospital] or nil,
            }
        end
    end

    return out
end)

Staff29.Cb("sams:getDeathCause", function(source, targetServerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not SAMS.HasJob(xPlayer) then return { cause = "Inconnue", sourceText = "" } end

    local sid = Staff29.ToInt(targetServerId, 1, 1024)
    if not sid then return { cause = "Inconnue", sourceText = "" } end

    local target = VFW.GetPlayerFromId(sid)
    if not target then return { cause = "Inconnue", sourceText = "" } end

    local row = Staff29.Single(
        "SELECT cause, source_text FROM sams_death_causes WHERE identifier = ?", { target.identifier })

    if not row then return { cause = "Inconnue", sourceText = "" } end
    return { cause = row.cause or "Inconnue", sourceText = row.source_text or "" }
end)

function SAMS.SetDeathCause(identifier, cause, sourceText)
    if type(identifier) ~= "string" then return end
    Staff29.Update([[
        INSERT INTO sams_death_causes (identifier, cause, source_text, died_at) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE cause = VALUES(cause), source_text = VALUES(source_text), died_at = VALUES(died_at)
    ]], { identifier, tostring(cause or "Inconnue"):sub(1, 120), tostring(sourceText or ""):sub(1, 200), Staff29.Now() })
end

AddEventHandler("sn_sams:server:setDeathCause", function(identifier, cause, sourceText)
    SAMS.SetDeathCause(identifier, cause, sourceText)
end)

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    mdtSubscribers[source] = nil

    for id, backup in pairs(backups) do
        if backup.requesterSource == source then
            backups[id] = nil
            SAMS.BroadcastOnDuty("sn_sams:backupEnded", id)
        end
    end

    if xPlayer and SAMS.HasJob(xPlayer) then
        VFW.SetTimeout(500, function()
            SAMS.Broadcast("sn_sams:setMedecins", fetchPersonnel())
        end)
    end
end)

local function samsStaffAllowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return xPlayer ~= nil and xPlayer.hasPermission("sams_management")
end

RegisterNetEvent("vfw:staff:sams:deleteReport", function(reportId)
    local source = source
    if not samsStaffAllowed(source) then return end
    samsDeleteReport(reportId)
end)

RegisterNetEvent("vfw:staff:sams:restoreReport", function(reportId)
    local source = source
    if not samsStaffAllowed(source) then return end
    samsRestoreReport(reportId)
end)

RegisterNetEvent("vfw:staff:sams:deleteAnnouncement", function(announcementId)
    local source = source
    if not samsStaffAllowed(source) then return end
    samsDeleteAnnouncement(announcementId)
end)

RegisterNetEvent("vfw:staff:sams:cancelInvoice", function(invoiceId)
    local source = source
    if not samsStaffAllowed(source) then return end
    samsCancelInvoice({ id = invoiceId })
end)
