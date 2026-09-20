local RECORD_TYPES = {
    traffic_ticket = true,
    arrest_report = true,
    criminal_record = true,
    complaint = true,
    deposition = true,
    intervention_report = true,
    seizure_report = true,
}

local function officer(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not MiscB.IsLawEnforcement(xPlayer) then return nil end
    return xPlayer
end

local function officerOrJustice(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if MiscB.IsLawEnforcement(xPlayer) then return xPlayer end
    if MiscB.HasJob(xPlayer, { "justice", "doj", "gouvernement" }) then return xPlayer end
    return nil
end

local function citizenIdentifier(data)
    if type(data) ~= "table" then return nil end
    local id = data.identifier or data.citizenIdentifier or data.citizen_identifier or data.targetIdentifier
    if type(id) ~= "string" or #id > 80 then return nil end
    return id
end

local function jobPermissions(jobName, grade)
    local row = MiscB.Single(
        "SELECT permissions FROM police_grade_permissions WHERE job_name = ? AND grade = ? LIMIT 1",
        { jobName, grade }
    )
    if not row then return {} end
    local decoded = VFW.DB.Decode(row.permissions, {})
    if type(decoded) ~= "table" then return {} end
    return decoded
end

MiscB.Cb("police:getPlayerPermissions", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end
    return jobPermissions(MiscB.JobName(xPlayer), MiscB.GradeLevel(xPlayer))
end)

MiscB.Cb("police:getGradesPermissions", function(source)
    local xPlayer = officer(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    local rows = MiscB.Query(
        "SELECT grade, permissions FROM police_grade_permissions WHERE job_name = ? ORDER BY grade ASC",
        { MiscB.JobName(xPlayer) }
    )
    for i = 1, #rows do
        rows[i].permissions = VFW.DB.Decode(rows[i].permissions, {})
    end
    return rows
end)

MiscB.Cb("police:updateGradePermissions", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local grade = MiscB.ToInt(data.grade or data.gradeId, 0, 99)
    if grade == nil or type(data.permissions) ~= "table" then return { success = false } end

    local jobName = MiscB.JobName(xPlayer)
    local perms = jobPermissions(jobName, grade)
    for key, value in pairs(data.permissions) do perms[key] = value == true end

    MiscB.Update([[
        INSERT INTO police_grade_permissions (job_name, grade, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { jobName, grade, VFW.DB.Encode(perms) })

    return { success = true }
end)

MiscB.Cb("vfw:server:getMugshot", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return "" end
    return xPlayer.mugshot or ""
end)

local function citizenRow(row)
    return {
        identifier = row.identifier,
        firstname = row.firstname,
        lastname = row.lastname,
        name = ("%s %s"):format(row.firstname or "", row.lastname or ""),
        dateofbirth = row.dateofbirth,
        sex = row.sex,
        height = row.height,
        phone = row.phone,
        address = row.address,
        mugshot = row.mugshot,
        job = row.job,
    }
end

MiscB.Cb("police:getAllCitizens", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local limit = 200
    if type(data) == "table" and MiscB.ToInt(data.limit, 1, 500) then
        limit = MiscB.ToInt(data.limit, 1, 500)
    end

    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, c.height,
               p.phone, c.address, c.mugshot, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        ORDER BY c.lastname ASC, c.firstname ASC LIMIT ]] .. limit, {})

    local out = {}
    for i = 1, #rows do out[#out + 1] = citizenRow(rows[i]) end
    return out
end)

MiscB.Cb("police:searchCitizens", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local term = type(data) == "table" and MiscB.Str(data.search or data.query or data.name, 64) or MiscB.Str(data, 64)
    if not term or term == "" then return {} end

    local like = "%" .. term .. "%"
    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, c.height,
               p.phone, c.address, c.mugshot, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        WHERE c.firstname LIKE ? OR c.lastname LIKE ? OR CONCAT(c.firstname, ' ', c.lastname) LIKE ? OR p.phone LIKE ?
        ORDER BY c.lastname ASC LIMIT 100
    ]], { like, like, like, like })

    local out = {}
    for i = 1, #rows do out[#out + 1] = citizenRow(rows[i]) end
    return out
end)

MiscB.Cb("police:getCitizenProfile", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local identifier = citizenIdentifier(data)
    if not identifier then return {} end

    local row = MiscB.Single([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, c.height,
               p.phone, c.address, c.mugshot, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        WHERE c.identifier = ? LIMIT 1
    ]], { identifier })
    if not row then return {} end

    local profile = citizenRow(row)
    profile.vehicles = MiscB.Query(
        "SELECT plate, vehName AS model, stored, pounded FROM owned_vehicles WHERE owner = ? LIMIT 100",
        { identifier }
    )
    profile.fines = MiscB.Query(
        "SELECT id, offense, amount, status, created_at FROM police_fines WHERE target_identifier = ? ORDER BY id DESC LIMIT 50",
        { identifier }
    )
    profile.records = MiscB.Query([[
        SELECT id, record_type, title, author_name, created_at FROM police_records
        WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 100
    ]], { identifier })
    profile.ppa = MiscB.Single("SELECT identifier FROM police_ppa WHERE identifier = ? LIMIT 1", { identifier }) ~= nil

    return profile
end)

MiscB.Cb("police:searchVehicles", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local term = type(data) == "table" and MiscB.Str(data.search or data.plate or data.query, 32) or MiscB.Str(data, 32)
    if not term or term == "" then return {} end

    local like = "%" .. term .. "%"
    return MiscB.Query([[
        SELECT v.plate, v.vehName AS model, v.stored, v.pounded, c.firstname, c.lastname, v.owner AS identifier
        FROM owned_vehicles v LEFT JOIN characters c ON c.identifier = v.owner
        WHERE v.plate LIKE ? OR c.firstname LIKE ? OR c.lastname LIKE ?
        ORDER BY v.plate ASC LIMIT 100
    ]], { like, like, like })
end)

MiscB.Cb("police:checkCitizenIdentifier", function(source, serverId, identifier)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return false end

    local target = tonumber(serverId)
    local ident = MiscB.Str(identifier, 80)
    if not target or not ident then return false end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return false end
    return xTarget.identifier == ident
end)

MiscB.Cb("police:resolveMatricule", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return nil end

    local matricule = type(data) == "table" and MiscB.Str(data.matricule, 32) or MiscB.Str(data, 32)
    if not matricule then return nil end

    local row = MiscB.Single([[
        SELECT m.identifier, m.matricule, m.job_name, c.firstname, c.lastname
        FROM police_matricules m LEFT JOIN characters c ON c.identifier = m.identifier
        WHERE m.matricule = ? LIMIT 1
    ]], { matricule })
    if not row then return nil end

    return {
        identifier = row.identifier,
        matricule = row.matricule,
        job = row.job_name,
        name = ("%s %s"):format(row.firstname or "", row.lastname or ""),
    }
end)

MiscB.Cb("police:getOfficers", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local job = MiscB.JobName(xPlayer)
    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.job, c.job_grade, m.matricule
        FROM characters c LEFT JOIN police_matricules m ON m.identifier = c.identifier
        WHERE c.job = ? ORDER BY c.job_grade DESC LIMIT 300
    ]], { job })

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
        rows[i].online = VFW.GetPlayerFromIdentifier(rows[i].identifier) ~= nil
    end
    return rows
end)

MiscB.Cb("police:getMagistrates", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT identifier, firstname, lastname, job, job_grade FROM characters
        WHERE job IN ('justice', 'doj', 'juge', 'avocat') ORDER BY job_grade DESC LIMIT 100
    ]], {})

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
    end
    return rows
end)

local function insertRecord(xPlayer, recordType, data)
    local identifier = citizenIdentifier(data)
    if not identifier then return nil end

    local citizen = MiscB.Single("SELECT firstname, lastname FROM characters WHERE identifier = ? LIMIT 1", { identifier })
    local citizenName = citizen and ("%s %s"):format(citizen.firstname or "", citizen.lastname or "") or ""

    return MiscB.Insert([[
        INSERT INTO police_records (record_type, citizen_identifier, citizen_name, author_identifier,
            author_name, job_name, title, content, data, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        recordType, identifier, citizenName,
        xPlayer.identifier, MiscB.CharName(xPlayer), MiscB.JobName(xPlayer) or "",
        MiscB.Str(data.title, 190) or "",
        MiscB.Str(data.content or data.description or data.text, 6000) or "",
        VFW.DB.Encode(data),
    })
end

local function fetchRecords(recordType, identifier)
    local rows = MiscB.Query([[
        SELECT id, record_type, citizen_identifier, citizen_name, author_identifier, author_name,
               job_name, title, content, data, created_at
        FROM police_records WHERE record_type = ? AND citizen_identifier = ?
        ORDER BY id DESC LIMIT 200
    ]], { recordType, identifier })

    for i = 1, #rows do
        rows[i].data = VFW.DB.Decode(rows[i].data, {})
    end
    return rows
end

local RECORD_CALLBACKS = {
    { get = "police:getCitizenTrafficTickets", create = "police:createTrafficTicket", type = "traffic_ticket" },
    { get = "police:getCitizenArrestReports", create = "police:createArrestReport", type = "arrest_report" },
    { get = "police:getCitizenCriminalRecords", create = "police:createCriminalRecord", type = "criminal_record" },
    { get = "police:getCitizenComplaints", create = "police:createComplaint", type = "complaint" },
    { get = "police:getCitizenDepositions", create = "police:createDeposition", type = "deposition" },
    { get = "police:getCitizenInterventionReports", create = "police:createInterventionReport", type = "intervention_report" },
    { get = "police:getCitizenSeizureReports", create = "police:createSeizureReport", type = "seizure_report" },
}

for _, entry in ipairs(RECORD_CALLBACKS) do
    MiscB.Cb(entry.get, function(source, data)
        local xPlayer = officerOrJustice(source)
        if not xPlayer then return {} end
        local identifier = citizenIdentifier(data)
        if not identifier then return {} end
        return fetchRecords(entry.type, identifier)
    end)

    MiscB.Cb(entry.create, function(source, data)
        local xPlayer = officerOrJustice(source)
        if not xPlayer then return { success = false } end
        if type(data) ~= "table" then return { success = false } end

        local id = insertRecord(xPlayer, entry.type, data)
        if not id then return { success = false, message = "Citoyen introuvable." } end
        return { success = true, id = id }
    end)
end

MiscB.Cb("police:createCriminalRecordBatch", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local list = type(data.records) == "table" and data.records or data
    local created = 0
    for i = 1, #list do
        if type(list[i]) == "table" then
            if list[i].identifier == nil then list[i].identifier = citizenIdentifier(data) end
            if insertRecord(xPlayer, "criminal_record", list[i]) then created = created + 1 end
        end
    end

    return { success = created > 0, created = created }
end)

MiscB.Cb("police:getAuthoredCounts", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local identifier = (type(data) == "table" and MiscB.Str(data.identifier, 80)) or xPlayer.identifier
    local rows = MiscB.Query([[
        SELECT record_type, COUNT(*) AS total FROM police_records
        WHERE author_identifier = ? GROUP BY record_type
    ]], { identifier })

    local out = {}
    for i = 1, #rows do out[rows[i].record_type] = rows[i].total end
    return out
end)

MiscB.Cb("police:getAuthoredRecords", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local identifier = (type(data) == "table" and MiscB.Str(data.identifier, 80)) or xPlayer.identifier
    local recordType = type(data) == "table" and MiscB.Str(data.recordType or data.type, 48) or nil

    local rows
    if recordType and RECORD_TYPES[recordType] then
        rows = MiscB.Query([[
            SELECT id, record_type, citizen_identifier, citizen_name, title, content, created_at
            FROM police_records WHERE author_identifier = ? AND record_type = ?
            ORDER BY id DESC LIMIT 200
        ]], { identifier, recordType })
    else
        rows = MiscB.Query([[
            SELECT id, record_type, citizen_identifier, citizen_name, title, content, created_at
            FROM police_records WHERE author_identifier = ? ORDER BY id DESC LIMIT 200
        ]], { identifier })
    end
    return rows
end)

MiscB.Cb("police:deleteRecord", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id or data.recordId, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    local row = MiscB.Single("SELECT author_identifier FROM police_records WHERE id = ? LIMIT 1", { id })
    if not row then return { success = false } end
    if row.author_identifier ~= xPlayer.identifier and not MiscB.IsBoss(xPlayer) then
        return { success = false, message = "Vous ne pouvez pas supprimer ce document." }
    end

    MiscB.Update("DELETE FROM police_records WHERE id = ?", { id })
    return { success = true }
end)

MiscB.Cb("police:editRecord", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local id = MiscB.ToInt(data.id or data.recordId, 1)
    if not id then return { success = false } end

    local row = MiscB.Single("SELECT author_identifier FROM police_records WHERE id = ? LIMIT 1", { id })
    if not row then return { success = false } end
    if row.author_identifier ~= xPlayer.identifier and not MiscB.IsBoss(xPlayer) then
        return { success = false, message = "Vous ne pouvez pas modifier ce document." }
    end

    MiscB.Update([[
        UPDATE police_records SET title = ?, content = ?, data = ?, updated_at = NOW() WHERE id = ?
    ]], {
        MiscB.Str(data.title, 190) or "",
        MiscB.Str(data.content or data.description, 6000) or "",
        VFW.DB.Encode(data),
        id,
    })

    return { success = true }
end)

MiscB.Cb("police:getDossiers", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT citizen_identifier, citizen_name, COUNT(*) AS total, MAX(created_at) AS last_at
        FROM police_records GROUP BY citizen_identifier, citizen_name
        ORDER BY last_at DESC LIMIT 200
    ]], {})
end)

MiscB.Cb("police:getDossierDetail", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local identifier = citizenIdentifier(data)
    if not identifier then return {} end

    local rows = MiscB.Query([[
        SELECT id, record_type, title, content, data, author_name, created_at
        FROM police_records WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 300
    ]], { identifier })

    for i = 1, #rows do rows[i].data = VFW.DB.Decode(rows[i].data, {}) end
    return { identifier = identifier, records = rows }
end)

MiscB.Cb("police:getDcpQuota", function(source)
    local xPlayer = officer(source)
    if not xPlayer then return { current = 0, quota = 0 } end

    local total = MiscB.Scalar([[
        SELECT COUNT(*) FROM police_records
        WHERE author_identifier = ? AND WEEK(created_at) = WEEK(NOW()) AND YEAR(created_at) = YEAR(NOW())
    ]], { xPlayer.identifier }, 0)

    return { current = total, quota = 10 }
end)

MiscB.Cb("police:getMdtLogs", function(source)
    local xPlayer = officer(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    return MiscB.Query([[
        SELECT id, identifier, player_name, job_name, action, details, created_at
        FROM police_mdt_logs ORDER BY id DESC LIMIT 200
    ]], {})
end)

MiscB.Cb("police:getDashboard", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local job = MiscB.JobName(xPlayer)
    local onlineOfficers = 0
    local players = MiscB.PlayersWithJobs(job)
    for i = 1, #players do
        if MiscB.OnDuty(players[i]) then onlineOfficers = onlineOfficers + 1 end
    end

    return {
        onlineOfficers = onlineOfficers,
        totalRecords = MiscB.Scalar("SELECT COUNT(*) FROM police_records", {}, 0),
        openWarrants = MiscB.Scalar("SELECT COUNT(*) FROM police_warrants WHERE status = 'open'", {}, 0),
        pendingFines = MiscB.Scalar("SELECT COUNT(*) FROM police_fines WHERE status = 'pending'", {}, 0),
        announcements = MiscB.Query([[
            SELECT id, title, content, author_name, created_at FROM police_announcements
            WHERE job_name = ? ORDER BY id DESC LIMIT 20
        ]], { job }),
        wantedNotices = MiscB.Query([[
            SELECT id, citizen_identifier, citizen_name, reason, created_at FROM police_wanted_notices
            ORDER BY id DESC LIMIT 20
        ]], {}),
        wantedVehicles = MiscB.Query([[
            SELECT id, plate, reason, created_at FROM police_wanted_vehicles ORDER BY id DESC LIMIT 20
        ]], {}),
    }
end)

MiscB.Cb("police:addAnnouncement", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local title = MiscB.Str(data.title, 190)
    local content = MiscB.Str(data.content or data.message, 4000)
    if not title or not content then return { success = false } end

    local id = MiscB.Insert([[
        INSERT INTO police_announcements (job_name, title, content, author_identifier, author_name, created_at)
        VALUES (?, ?, ?, ?, ?, NOW())
    ]], { MiscB.JobName(xPlayer) or "", title, content, xPlayer.identifier, MiscB.CharName(xPlayer) })

    return { success = id ~= nil, id = id }
end)

MiscB.Cb("police:removeAnnouncement", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    MiscB.Update("DELETE FROM police_announcements WHERE id = ? AND job_name = ?", { id, MiscB.JobName(xPlayer) })
    return { success = true }
end)

MiscB.Cb("police:addWantedNotice", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end

    local identifier = citizenIdentifier(data)
    if not identifier then return { success = false } end

    local citizen = MiscB.Single("SELECT firstname, lastname FROM characters WHERE identifier = ? LIMIT 1", { identifier })
    local id = MiscB.Insert([[
        INSERT INTO police_wanted_notices (citizen_identifier, citizen_name, reason, author_identifier, author_name, created_at)
        VALUES (?, ?, ?, ?, ?, NOW())
    ]], {
        identifier,
        citizen and ("%s %s"):format(citizen.firstname or "", citizen.lastname or "") or "",
        MiscB.Str(data.reason, 500) or "",
        xPlayer.identifier, MiscB.CharName(xPlayer),
    })

    return { success = id ~= nil, id = id }
end)

MiscB.Cb("police:removeWantedNotice", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    MiscB.Update("DELETE FROM police_wanted_notices WHERE id = ?", { id })
    return { success = true }
end)

MiscB.Cb("police:addWantedVehicle", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local plate = MiscB.Str(data.plate, 12)
    if not plate then return { success = false } end

    local id = MiscB.Insert([[
        INSERT INTO police_wanted_vehicles (plate, reason, author_identifier, author_name, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { plate, MiscB.Str(data.reason, 500) or "", xPlayer.identifier, MiscB.CharName(xPlayer) })

    return { success = id ~= nil, id = id }
end)

MiscB.Cb("police:removeWantedVehicle", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    MiscB.Update("DELETE FROM police_wanted_vehicles WHERE id = ?", { id })
    return { success = true }
end)

MiscB.Cb("police:getWarrants", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local identifier = citizenIdentifier(data)
    if identifier then
        return MiscB.Query([[
            SELECT * FROM police_warrants WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 100
        ]], { identifier })
    end

    return MiscB.Query("SELECT * FROM police_warrants ORDER BY id DESC LIMIT 200", {})
end)

MiscB.Cb("police:getAllWarrants", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end
    return MiscB.Query("SELECT * FROM police_warrants ORDER BY id DESC LIMIT 300", {})
end)

MiscB.Cb("police:createWarrant", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end

    local identifier = citizenIdentifier(data)
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

MiscB.Cb("police:updateWarrantStatus", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local id = MiscB.ToInt(data.id or data.warrantId, 1)
    local status = MiscB.Str(data.status, 24)
    if not id or not status then return { success = false } end
    if status ~= "open" and status ~= "closed" and status ~= "executed" and status ~= "cancelled" then
        return { success = false }
    end

    MiscB.Update("UPDATE police_warrants SET status = ?, updated_at = NOW() WHERE id = ?", { status, id })
    return { success = true }
end)

MiscB.Cb("police:getFineTypes", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end
    if PoliceFineTypes and PoliceFineTypes.List then
        return PoliceFineTypes.List()
    end
    if type(Config) == "table" and type(Config.FineTypes) == "table" then
        return Config.FineTypes
    end
    return {}
end)

local function fineById(fineId)
    if PoliceFineTypes and PoliceFineTypes.Get then
        return PoliceFineTypes.Get(fineId)
    end
    if type(Config) ~= "table" or type(Config.FineTypes) ~= "table" then return nil end
    for i = 1, #Config.FineTypes do
        if tonumber(Config.FineTypes[i].id) == tonumber(fineId) then return Config.FineTypes[i] end
    end
    return nil
end

local function createFine(xPlayer, targetIdentifier, fine, amountOverride)
    local amount = MiscB.ToInt(amountOverride, 1, 10000000) or tonumber(fine and fine.amount) or 0
    if amount <= 0 then return nil end

    return MiscB.Insert([[
        INSERT INTO police_fines (target_identifier, officer_identifier, officer_name, job_name,
            fine_id, offense, category, amount, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
    ]], {
        targetIdentifier, xPlayer.identifier, MiscB.CharName(xPlayer), MiscB.JobName(xPlayer) or "",
        fine and fine.id or 0,
        fine and fine.label or "Amende",
        fine and fine.category or "",
        amount,
    })
end

MiscB.Cb("police:createFine", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer then return { success = false } end

    local identifier = citizenIdentifier(data)
    if not identifier then return { success = false } end

    local fine = fineById(type(data) == "table" and data.fineId or nil)
    local id = createFine(xPlayer, identifier, fine, type(data) == "table" and data.amount or nil)
    if not id then return { success = false } end

    local xTarget = VFW.GetPlayerFromIdentifier(identifier)
    if xTarget then
        VFW.ShowNotification(xTarget.source, { type = "ROUGE", content = "Vous avez recu une amende." })
    end

    return { success = true, id = id }
end)

RegisterNetEvent("police:createFineFromMenu", function(targetServerId, fineId)
    local source = source
    local target = tonumber(targetServerId)
    local id = tonumber(fineId)
    if not target or not id then return end
    if not MiscB.Rate(source, "fine", 1200) then return end

    local xPlayer = officer(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    local fine = fineById(id)
    if not fine then return end

    if not createFine(xPlayer, xTarget.identifier, fine, nil) then return end

    VFW.ShowNotification(source, { type = "VERT", content = ("Amende de %d$ emise."):format(fine.amount) })
    VFW.ShowNotification(target, { type = "ROUGE", content = ("Amende recue : %s (%d$)"):format(fine.label, fine.amount) })
end)

MiscB.Cb("police:getCitizenFines", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local identifier = citizenIdentifier(data)
    if not identifier then return {} end

    return MiscB.Query([[
        SELECT id, offense, category, amount, status, officer_name, created_at
        FROM police_fines WHERE target_identifier = ? ORDER BY id DESC LIMIT 200
    ]], { identifier })
end)

MiscB.Cb("police:cancelFine", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id or data.fineId, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    MiscB.Update("UPDATE police_fines SET status = 'cancelled', cancelled_at = NOW() WHERE id = ?", { id })
    return { success = true }
end)

MiscB.Cb("police:togglePPA", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer then return { success = false } end

    local identifier = citizenIdentifier(data)
    if not identifier then return { success = false } end

    local existing = MiscB.Single("SELECT identifier FROM police_ppa WHERE identifier = ? LIMIT 1", { identifier })
    if existing then
        MiscB.Update("DELETE FROM police_ppa WHERE identifier = ?", { identifier })
        return { success = true, granted = false }
    end

    MiscB.Update([[
        INSERT INTO police_ppa (identifier, label, granted_by, granted_at) VALUES (?, 'PPA', ?, NOW())
    ]], { identifier, xPlayer.identifier })

    return { success = true, granted = true }
end)

MiscB.Cb("police:searchItems", function(source, data)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local term = type(data) == "table" and MiscB.Str(data.search or data.query or data.name, 64) or MiscB.Str(data, 64)
    if not term or term == "" then return {} end

    local out = {}
    local lowered = term:lower()
    if type(VFW.Items) == "table" then
        for name, def in pairs(VFW.Items) do
            local label = (type(def) == "table" and def.label) or name
            if name:lower():find(lowered, 1, true) or tostring(label):lower():find(lowered, 1, true) then
                out[#out + 1] = { name = name, label = label }
                if #out >= 100 then break end
            end
        end
    end
    return out
end)

MiscB.Cb("police:getImpoundedVehicles", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT v.plate, v.vehName AS model, c.firstname, c.lastname
        FROM owned_vehicles v LEFT JOIN characters c ON c.identifier = v.owner
        WHERE v.pounded = 1 ORDER BY v.plate ASC LIMIT 200
    ]], {})
end)

local cameras = nil

local function loadCameras()
    if cameras then return cameras end
    cameras = MiscB.Query("SELECT id, label, x, y, z, rx, ry, rz, job_name FROM police_cameras", {})
    return cameras
end

MiscB.Cb("police:getAllCameras", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end
    return loadCameras()
end)

MiscB.Cb("police:getCameraCount", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return 0 end
    return #loadCameras()
end)

MiscB.Cb("police:placeCamera", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local id = MiscB.Insert([[
        INSERT INTO police_cameras (label, x, y, z, rx, ry, rz, job_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        MiscB.Str(data.label, 96) or "Camera",
        MiscB.ToNum(data.x, 0.0), MiscB.ToNum(data.y, 0.0), MiscB.ToNum(data.z, 0.0),
        MiscB.ToNum(data.rx, 0.0), MiscB.ToNum(data.ry, 0.0), MiscB.ToNum(data.rz, 0.0),
        MiscB.JobName(xPlayer) or "",
    })
    if not id then return { success = false } end

    cameras = nil
    TriggerClientEvent("police:cameras:spawn", -1, {
        id = id,
        label = MiscB.Str(data.label, 96) or "Camera",
        x = MiscB.ToNum(data.x, 0.0), y = MiscB.ToNum(data.y, 0.0), z = MiscB.ToNum(data.z, 0.0),
        rx = MiscB.ToNum(data.rx, 0.0), ry = MiscB.ToNum(data.ry, 0.0), rz = MiscB.ToNum(data.rz, 0.0),
    })
    return { success = true, id = id }
end)

MiscB.Cb("police:deleteCamera", function(source, data)
    local xPlayer = officer(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id or data.cameraId, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    MiscB.Update("DELETE FROM police_cameras WHERE id = ?", { id })
    cameras = nil
    TriggerClientEvent("police:cameras:remove", -1, id)
    return { success = true }
end)

MiscB.Cb("police:bodycam:getRecording", function(source, recordingId)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return nil end

    local id = MiscB.ToInt(recordingId, 1)
    if not id then return nil end

    local row = MiscB.Single("SELECT * FROM police_bodycam_recordings WHERE id = ? LIMIT 1", { id })
    if not row then return nil end
    row.data = VFW.DB.Decode(row.data, {})
    return row
end)

MiscB.Cb("police:fingerprintScanner:scan", function(source, targetServerId)
    local xPlayer = officer(source)
    if not xPlayer then return nil end

    local target = tonumber(targetServerId)
    if not target then return nil end

    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return nil end

    MiscB.Insert([[
        INSERT INTO police_fingerprint_scans (officer_identifier, officer_name, citizen_identifier, citizen_name, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { xPlayer.identifier, MiscB.CharName(xPlayer), xTarget.identifier, MiscB.CharName(xTarget) })

    return {
        success = true,
        identifier = xTarget.identifier,
        firstName = xTarget.firstName,
        lastName = xTarget.lastName,
        name = MiscB.CharName(xTarget),
        dateofbirth = xTarget.dateofbirth,
        sex = xTarget.sex,
        mugshot = xTarget.mugshot,
    }
end)

MiscB.Cb("police:fingerprintScanner:getHistory", function(source)
    local xPlayer = officer(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT id, officer_name, citizen_identifier, citizen_name, created_at
        FROM police_fingerprint_scans ORDER BY id DESC LIMIT 100
    ]], {})
end)

local prisoners = {}
local ethyloRequests = {}

MiscB.Cb("police:getPrisoners", function(source)
    local xPlayer = officerOrJustice(source)
    if not xPlayer then return {} end

    local out = {}
    for identifier, data in pairs(prisoners) do
        local xTarget = VFW.GetPlayerFromIdentifier(identifier)
        out[#out + 1] = {
            identifier = identifier,
            serverId = xTarget and xTarget.source or nil,
            name = xTarget and MiscB.CharName(xTarget) or data.name,
            minutes = data.minutes,
            remaining = math.max(0, data.minutes - math.floor((os.time() - data.startedAt) / 60)),
            escaped = data.escaped == true,
            online = xTarget ~= nil,
        }
    end
    return out
end)

RegisterNetEvent("police:releasePrisoner", function(targetId)
    local source = source
    local target = tonumber(targetId)
    if not target then return end

    local xPlayer = officerOrJustice(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    prisoners[xTarget.identifier] = nil
    xTarget.setMeta("jail", 0)
    TriggerClientEvent("police:prison:release", target)
end)

RegisterNetEvent("police:reduceSentence", function(targetId, minutes)
    local source = source
    local target = tonumber(targetId)
    local amount = MiscB.ToInt(minutes, 1, 100000)
    if not target or not amount then return end

    local xPlayer = officerOrJustice(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    local data = prisoners[xTarget.identifier]
    if not data then return end

    data.minutes = math.max(0, data.minutes - amount)
    xTarget.setMeta("jail", data.minutes)

    if data.minutes <= 0 then
        prisoners[xTarget.identifier] = nil
        TriggerClientEvent("police:prison:release", target)
        return
    end

    TriggerClientEvent("police:prison:updateTimer", target, data.minutes)
end)

RegisterNetEvent("police:prison:saveSkin", function(skin)
    local source = source
    if type(skin) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    MiscB.Update([[
        INSERT INTO police_prison_skins (identifier, skin, created_at) VALUES (?, ?, NOW())
        ON DUPLICATE KEY UPDATE skin = VALUES(skin), created_at = NOW()
    ]], { xPlayer.identifier, VFW.DB.Encode(skin) })
end)

RegisterNetEvent("police:prison:escaped", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local data = prisoners[xPlayer.identifier]
    if data then data.escaped = true end

    local officers = MiscB.PlayersWithJobs(GetPoliceJobsArray and GetPoliceJobsArray() or { "police" })
    for i = 1, #officers do
        VFW.ShowNotification(officers[i].source, {
            type = "ROUGE",
            content = ("Evasion signalee : %s"):format(MiscB.CharName(xPlayer)),
        })
    end

    TriggerClientEvent("police:prison:resetEscape", source)
end)

RegisterNetEvent("police:prison:clothesClaimed", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = MiscB.Single("SELECT skin FROM police_prison_skins WHERE identifier = ? LIMIT 1", { xPlayer.identifier })
    if not row then return end

    MiscB.Update("DELETE FROM police_prison_skins WHERE identifier = ?", { xPlayer.identifier })
    TriggerClientEvent("vfw:skin:apply", source, VFW.DB.Decode(row.skin, {}))
end)

RegisterNetEvent("police:gunpowder:playerFired", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.setMeta("gunpowder", os.time())
end)

RegisterNetEvent("police:gunpowder:test", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end
    if not MiscB.Rate(source, "gunpowder", 2000) then return end

    local xPlayer = officer(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if not xPlayer.haveItem("gsr_kit", 1) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de kit de test." })
        return
    end
    xPlayer.removeInventoryItem("gsr_kit", 1)

    local last = tonumber(xTarget.getMeta and xTarget.getMeta("gunpowder")) or 0
    local positive = last > 0 and (os.time() - last) < 1800

    TriggerClientEvent("police:gunpowder:result", source, positive, target)
    VFW.ShowNotification(source, {
        type = positive and "ROUGE" or "VERT",
        content = positive and "Test positif : traces de poudre." or "Test negatif.",
    })
end)

RegisterNetEvent("police:ethylotest:startTest", function(serverId)
    local source = source
    local target = tonumber(serverId)
    if not target then return end
    if not MiscB.Rate(source, "ethylo", 2000) then return end

    local xPlayer = officer(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    TriggerClientEvent("police:ethylotest:showPopup", target, MiscB.CharName(xPlayer))
    ethyloRequests[target] = source
end)

RegisterNetEvent("police:ethylotest:respond", function(isPositive, rate)
    local source = source
    local agent = ethyloRequests[source]
    ethyloRequests[source] = nil
    if not agent or not VFW.GetPlayerFromId(agent) then return end

    TriggerClientEvent("police:ethylotest:showDevice", agent, isPositive == true, MiscB.ToNum(rate, 0.0))
end)

local alerts = {}
local alertSeq = 0
local units = {}
local unitSeq = 0
local playerUnits = {}

local function alertPayload(alert)
    return {
        id = alert.id,
        title = alert.title,
        message = alert.message,
        code = alert.code,
        job = alert.job,
        x = alert.x, y = alert.y, z = alert.z,
        district = alert.district,
        time = alert.time,
        status = alert.status,
        assigned = alert.assigned,
        author = alert.author,
    }
end

local function broadcastAlert(alert, event)
    local receivers = MiscB.PlayersWithJobs(alert.job)
    for i = 1, #receivers do
        if MiscB.OnDuty(receivers[i]) then
            TriggerClientEvent(event, receivers[i].source, alertPayload(alert))
        end
    end
end

local function createAlert(source, data, jobOverride)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    alertSeq = alertSeq + 1
    local alert = {
        id = alertSeq,
        title = MiscB.Str(data.title, 190) or "Alerte",
        message = MiscB.Str(data.message or data.description, 1000) or "",
        code = MiscB.Str(data.code, 32),
        job = jobOverride or MiscB.Str(data.job, 64) or MiscB.JobName(xPlayer) or "police",
        x = MiscB.ToNum(data.x, 0.0),
        y = MiscB.ToNum(data.y, 0.0),
        z = MiscB.ToNum(data.z, 0.0),
        district = MiscB.Str(data.district, 96),
        time = os.time(),
        status = "open",
        assigned = {},
        author = MiscB.CharName(xPlayer),
    }
    alerts[alert.id] = alert

    MiscB.Insert([[
        INSERT INTO police_dispatch_alerts (job_name, title, message, code, x, y, z, district, author_name, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], { alert.job, alert.title, alert.message, alert.code, alert.x, alert.y, alert.z, alert.district, alert.author })

    broadcastAlert(alert, "police:dispatch:incoming")
    return alert
end

RegisterNetEvent("police:dispatch:create", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not MiscB.Rate(source, "dispatchcreate", 1000) then return end
    createAlert(source, data, nil)
end)

RegisterNetEvent("usss:dispatch:create", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not MiscB.Rate(source, "dispatchcreate", 1000) then return end
    createAlert(source, data, "usss")
end)

RegisterNetEvent("dispatch:server:requestBackup", function(level)
    local source = source
    local lvl = MiscB.ToInt(level, 0, 10) or 1
    if not MiscB.Rate(source, "backup", 5000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local coords = xPlayer.getCoords()
    createAlert(source, {
        title = ("DEMANDE DE RENFORT NIVEAU %d"):format(lvl),
        message = ("%s demande des renforts."):format(MiscB.CharName(xPlayer)),
        code = "BACKUP",
        x = coords.x, y = coords.y, z = coords.z,
    }, nil)
end)

RegisterNetEvent("police:dispatch:accept", function(alertId)
    local source = source
    local id = MiscB.ToInt(alertId, 1)
    if not id then return end

    local xPlayer = officer(source)
    local alert = id and alerts[id] or nil
    if not xPlayer or not alert then return end

    alert.assigned[tostring(source)] = MiscB.CharName(xPlayer)
    alert.status = "assigned"
    broadcastAlert(alert, "police:dispatch:alertUpdated")
end)

RegisterNetEvent("police:dispatch:assignAll", function(alertId)
    local source = source
    local id = MiscB.ToInt(alertId, 1)
    if not id then return end

    local xPlayer = officer(source)
    local alert = id and alerts[id] or nil
    if not xPlayer or not alert then return end

    local receivers = MiscB.PlayersWithJobs(alert.job)
    for i = 1, #receivers do
        if MiscB.OnDuty(receivers[i]) then
            alert.assigned[tostring(receivers[i].source)] = MiscB.CharName(receivers[i])
        end
    end
    alert.status = "assigned"
    broadcastAlert(alert, "police:dispatch:alertUpdated")
end)

RegisterNetEvent("police:dispatch:resend", function(alertId)
    local source = source
    local id = MiscB.ToInt(alertId, 1)
    if not id then return end

    local xPlayer = officer(source)
    local alert = id and alerts[id] or nil
    if not xPlayer or not alert then return end

    broadcastAlert(alert, "police:dispatch:incoming")
end)

RegisterNetEvent("police:dispatch:close", function(alertId)
    local source = source
    local id = MiscB.ToInt(alertId, 1)
    if not id then return end

    local xPlayer = officer(source)
    local alert = id and alerts[id] or nil
    if not xPlayer or not alert then return end

    alert.status = "closed"
    broadcastAlert(alert, "police:dispatch:alertUpdated")
    alerts[id] = nil
end)

MiscB.Cb("police:dispatch:getActiveAlerts", function(source)
    local xPlayer = officer(source)
    if not xPlayer then return {} end

    local job = MiscB.JobName(xPlayer)
    local out = {}
    for _, alert in pairs(alerts) do
        if alert.job == job then out[#out + 1] = alertPayload(alert) end
    end
    table.sort(out, function(a, b) return (a.time or 0) > (b.time or 0) end)
    return out
end)

MiscB.Cb("police:dispatch:getHistory", function(source)
    local xPlayer = officer(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT id, title, message, code, x, y, z, district, author_name, created_at
        FROM police_dispatch_alerts WHERE job_name = ? ORDER BY id DESC LIMIT 100
    ]], { MiscB.JobName(xPlayer) })
end)

local function unitsPayload(xPlayer)
    local job = MiscB.JobName(xPlayer)
    local out = {}
    for id, unit in pairs(units) do
        if unit.job == job then
            local members = {}
            for src, name in pairs(unit.members) do
                members[#members + 1] = { serverId = tonumber(src), name = name }
            end
            out[#out + 1] = { id = id, name = unit.name, members = members }
        end
    end

    local row = MiscB.Single("SELECT matricule FROM police_matricules WHERE identifier = ? LIMIT 1", { xPlayer.identifier })

    return {
        matricule = row and row.matricule or nil,
        units = out,
        myUnitId = playerUnits[xPlayer.source],
    }
end

local function broadcastUnits(job)
    local receivers = MiscB.PlayersWithJobs(job)
    for i = 1, #receivers do
        TriggerClientEvent("police:units:updated", receivers[i].source, unitsPayload(receivers[i]))
        TriggerClientEvent("usss:units:updated", receivers[i].source, unitsPayload(receivers[i]))
    end
end

MiscB.Cb("police:units:getData", function(source)
    local xPlayer = officer(source)
    if not xPlayer then return { matricule = nil, units = {}, myUnitId = nil } end
    return unitsPayload(xPlayer)
end)

MiscB.Cb("usss:units:getData", function(source)
    local xPlayer = officer(source)
    if not xPlayer then return { matricule = nil, units = {}, myUnitId = nil } end
    return unitsPayload(xPlayer)
end)

local function createUnit(source, data)
    local xPlayer = officer(source)
    if not xPlayer or type(data) ~= "table" then return end

    local name = MiscB.Str(data.name, 64)
    if not name then return end

    unitSeq = unitSeq + 1
    units[unitSeq] = {
        job = MiscB.JobName(xPlayer),
        name = name,
        members = { [tostring(source)] = MiscB.CharName(xPlayer) },
    }
    playerUnits[source] = unitSeq
    broadcastUnits(MiscB.JobName(xPlayer))
end

local function joinUnit(source, data)
    local xPlayer = officer(source)
    if not xPlayer or type(data) ~= "table" then return end

    local id = MiscB.ToInt(data.unitId, 1)
    local unit = id and units[id] or nil
    if not unit or unit.job ~= MiscB.JobName(xPlayer) then return end

    if playerUnits[source] and units[playerUnits[source]] then
        units[playerUnits[source]].members[tostring(source)] = nil
    end

    unit.members[tostring(source)] = MiscB.CharName(xPlayer)
    playerUnits[source] = id
    broadcastUnits(unit.job)
end

local function leaveUnit(source)
    local id = playerUnits[source]
    if not id then return end

    local unit = units[id]
    playerUnits[source] = nil
    if not unit then return end

    unit.members[tostring(source)] = nil
    if next(unit.members) == nil then units[id] = nil end
    broadcastUnits(unit.job)
end

local function changeMatricule(source, data)
    local xPlayer = officer(source)
    if not xPlayer or type(data) ~= "table" then return end

    local matricule = MiscB.Str(data.matricule, 16)
    if not matricule then return end

    MiscB.Update([[
        INSERT INTO police_matricules (identifier, job_name, matricule) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE matricule = VALUES(matricule), job_name = VALUES(job_name)
    ]], { xPlayer.identifier, MiscB.JobName(xPlayer) or "", matricule })

    broadcastUnits(MiscB.JobName(xPlayer))
end

RegisterNetEvent("police:units:createUnit", function(data)
    local source = source
    createUnit(source, data)
end)

RegisterNetEvent("police:units:joinUnit", function(data)
    local source = source
    joinUnit(source, data)
end)

RegisterNetEvent("police:units:leaveUnit", function()
    local source = source
    leaveUnit(source)
end)

RegisterNetEvent("police:units:changeMatricule", function(data)
    local source = source
    changeMatricule(source, data)
end)

RegisterNetEvent("usss:units:createUnit", function(data)
    local source = source
    createUnit(source, data)
end)

RegisterNetEvent("usss:units:joinUnit", function(data)
    local source = source
    joinUnit(source, data)
end)

RegisterNetEvent("usss:units:leaveUnit", function()
    local source = source
    leaveUnit(source)
end)

RegisterNetEvent("usss:units:changeMatricule", function(data)
    local source = source
    changeMatricule(source, data)
end)

AddEventHandler("vfw:playerDropped", function(source)
    leaveUnit(source)
    ethyloRequests[source] = nil
end)
