local JUSTICE_NAMES = {
    justice = true,
    doj = true,
    juge = true,
    avocat = true,
}

local JUSTICE_TYPES = {
    doj = true,
    justice = true,
}

local DOJ_PERM_ORDER = {
    "doj_access",
    "view_complaints",
    "view_depositions",
    "view_traffic_tickets",
    "view_arrest_reports",
    "view_criminal_records",
    "view_fines",
    "view_warrants",
    "view_intervention_reports",
    "view_seizure_reports",
    "view_dossier_content",
    "search_citizens",
    "manage_warrants",
    "update_warrant_status",
    "view_police_officers",
    "edit_dossier",
    "delete_dossier",
}

local DOJ_PERM_LABELS = {
    doj_access = "Accès au panel DOJ",
    view_complaints = "Voir les plaintes",
    view_depositions = "Voir les dépositions",
    view_traffic_tickets = "Voir les PV routiers",
    view_arrest_reports = "Voir les rapports d'arrestation",
    view_criminal_records = "Voir les casiers judiciaires",
    view_fines = "Voir les amendes",
    view_warrants = "Voir les mandats",
    view_intervention_reports = "Voir les rapports d'intervention",
    view_seizure_reports = "Voir les rapports de saisie",
    view_dossier_content = "Voir le contenu détaillé des dossiers",
    search_citizens = "Recherche de citoyens",
    manage_warrants = "Gérer les mandats",
    update_warrant_status = "Exécuter ou annuler un mandat",
    view_police_officers = "Voir les agents police en service",
    edit_dossier = "Modifier un dossier",
    delete_dossier = "Supprimer un dossier",
}

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("manage_doj")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function catalog()
    local out = {}
    for i = 1, #DOJ_PERM_ORDER do
        local name = DOJ_PERM_ORDER[i]
        out[i] = { name = name, label = DOJ_PERM_LABELS[name] or name }
    end
    return out
end

local function isJusticeJob(name, def)
    if type(name) ~= "string" or name == "" then return false end
    if JUSTICE_NAMES[name] then return true end
    local jobType = type(def) == "table" and tostring(def.type or ""):lower() or ""
    return JUSTICE_TYPES[jobType] == true
end

local function sanitizePerms(raw)
    local out = {}
    if type(raw) ~= "table" then return out end
    for i = 1, #DOJ_PERM_ORDER do
        local name = DOJ_PERM_ORDER[i]
        if raw[name] == true then out[name] = true end
    end
    return out
end

local function loadStored(jobName)
    local map = {}
    local rows = MiscB.Query(
        "SELECT grade, permissions FROM doj_grade_permissions WHERE job_name = ?",
        { jobName }
    )
    for i = 1, #rows do
        local grade = tonumber(rows[i].grade)
        if grade then
            map[grade] = sanitizePerms(VFW.DB.Decode(rows[i].permissions, {}))
        end
    end
    return map
end

local function jobGrades(jobName, def)
    local out = {}
    local rows = MiscB.Query(
        "SELECT grade, name, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC",
        { jobName }
    )
    if #rows > 0 then
        for i = 1, #rows do
            out[#out + 1] = {
                grade = tonumber(rows[i].grade) or 0,
                name = rows[i].name or "",
                label = rows[i].label or rows[i].name or ("Grade " .. tostring(rows[i].grade)),
            }
        end
        return out
    end

    local grades = def and def.grades
    if type(grades) ~= "table" then return out end
    for _, entry in pairs(grades) do
        if type(entry) == "table" then
            local grade = tonumber(entry.grade) or 0
            out[#out + 1] = {
                grade = grade,
                name = entry.name or "",
                label = entry.label or entry.name or ("Grade " .. tostring(grade)),
            }
        end
    end
    table.sort(out, function(a, b) return a.grade < b.grade end)
    return out
end

local function justiceJobs()
    local found = {}
    local jobs = VFW.Jobs or {}
    for name, def in pairs(jobs) do
        if isJusticeJob(name, def) then
            found[name] = {
                name = name,
                label = (type(def) == "table" and def.label) or name,
                def = def,
            }
        end
    end

    local extra = MiscB.Query("SELECT name, label, type FROM jobs", {})
    for i = 1, #extra do
        local row = extra[i]
        local name = row.name
        if name and not found[name] and isJusticeJob(name, row) then
            found[name] = {
                name = name,
                label = row.label or name,
                def = jobs[name],
            }
        end
    end

    local list = {}
    for _, job in pairs(found) do
        list[#list + 1] = job
    end
    table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return list
end

local function payload()
    local jobs = {}
    local sourceJobs = justiceJobs()
    for i = 1, #sourceJobs do
        local job = sourceJobs[i]
        local stored = loadStored(job.name)
        local grades = jobGrades(job.name, job.def)
        local gradeRows = {}
        for g = 1, #grades do
            local entry = grades[g]
            gradeRows[g] = {
                grade = entry.grade,
                name = entry.name,
                label = entry.label,
                permissions = stored[entry.grade] or {},
            }
        end
        jobs[#jobs + 1] = {
            name = job.name,
            label = job.label,
            grades = gradeRows,
        }
    end
    return {
        ok = true,
        catalog = catalog(),
        jobs = jobs,
    }
end

MiscB.Cb("dojStaff:getPanel", function(source)
    if not staffOk(source) then return { ok = false } end
    return payload()
end)

MiscB.Cb("dojStaff:updateGrade", function(source, data)
    if not staffOk(source) then return { ok = false } end
    if type(data) ~= "table" then return { ok = false, error = "Cette demande n'a pas pu être traitée." } end
    if not MiscB.Rate(source, "doj_staff_save", 250) then
        return { ok = false, error = "Veuillez patienter un instant." }
    end

    local jobName = MiscB.Str(data.job or data.job_name, 60)
    local grade = MiscB.ToInt(data.grade, 0, 99)
    if not jobName or grade == nil then
        return { ok = false, error = "Job ou grade invalide." }
    end

    local allowed = false
    local listed = justiceJobs()
    for i = 1, #listed do
        if listed[i].name == jobName then
            allowed = true
            break
        end
    end
    if not allowed then
        return { ok = false, error = "Ce job n'appartient pas au DOJ." }
    end

    MiscB.Update([[
        INSERT INTO doj_grade_permissions (job_name, grade, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { jobName, grade, VFW.DB.Encode(sanitizePerms(data.permissions)) })

    return payload()
end)
