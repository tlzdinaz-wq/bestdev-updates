local SAMS_PERM = "sams_management"
local HOSPITAL_JOBS = { pillbox = "sams_pib", paleto = "sams_pab" }
local PLATINE_STORE = "staff_dj_platines"
local TELEPORT_KEY = "staffCustomTeleports"
local TELEPORT_MAX = 50
local PLACEMENT_FULLSCREEN = 1
local PLACEMENT_TOPRIGHT = 2
local TARGET_PLAYER = 1
local TARGET_ZONE = 2
local TARGET_SERVER = 3
local BOOT_TIME = os.time()

local videoTargets = {}
local devWeight = {}
local platines = nil
local platineSeq = 0

local function samsApi()
    return Staff29 and Staff29.SAMS or nil
end

local function samsConfig()
    return SN_SAMS and SN_SAMS.Config or nil
end

local function permissionSet()
    local out = {}
    local cfg = samsConfig()
    local list = cfg and cfg.Permissions or {}
    for i = 1, #list do out[list[i]] = true end
    return out
end

local function bossGrades()
    local cfg = samsConfig()
    local list = cfg and cfg.BossGrades or { 99, 98 }
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    return out
end

local function isBoss(grade, list)
    for i = 1, #list do
        if list[i] == grade then return true end
    end
    return false
end

local function logStaff(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, action, payload or {})
end

local function toVec(value)
    local x, y, z
    if type(value) == "vector3" or type(value) == "vector4" then
        x, y, z = value.x, value.y, value.z
    elseif type(value) == "table" then
        x = tonumber(value.x or value[1])
        y = tonumber(value.y or value[2])
        z = tonumber(value.z or value[3])
    end
    if not x or not y or not z then return nil end
    if x ~= x or y ~= y or z ~= z then return nil end
    if math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 5000 then return nil end
    return { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
end

local function namesByIdentifier(identifiers)
    local out = {}
    local list, n, seen = {}, 0, {}
    for i = 1, #identifiers do
        local id = identifiers[i]
        if type(id) == "string" and id ~= "" and not seen[id] and n < 400 then
            seen[id] = true
            n = n + 1
            list[n] = id
        end
    end
    if n == 0 then return out end

    local marks = {}
    for i = 1, n do marks[i] = "?" end

    local rows = Staff29.Query(
        ("SELECT identifier, firstname, lastname FROM characters WHERE identifier IN (%s)"):format(
            table.concat(marks, ",")), list)

    for i = 1, #rows do
        out[rows[i].identifier] = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
    end
    return out
end

local function jobLabel(name, grade)
    local job = VFW.Jobs and VFW.Jobs[name]
    if not job then return "Civil" end
    local gradeData = job.grades and job.grades[tostring(grade)]
    if gradeData and gradeData.label then
        return ("%s - %s"):format(job.label or name, gradeData.label)
    end
    return job.label or name
end

local function durationText(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 0 then seconds = 0 end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return ("%dj %02dh %02dm"):format(days, hours, minutes)
    end
    return ("%02dh %02dm"):format(hours, minutes)
end

local function clockText(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 0 then seconds = 0 end
    return ("%02d:%02d:%02d"):format(
        math.floor(seconds / 3600), math.floor((seconds % 3600) / 60), seconds % 60)
end

local function discordOf(source)
    local identifiers = GetPlayerIdentifiers(source) or {}
    for i = 1, #identifiers do
        if identifiers[i]:sub(1, 8) == "discord:" then return identifiers[i]:sub(9) end
    end
    return nil
end

Staff29.Cb("vfw:staff:sams:getAnnouncements", function(source)
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return {} end

    local rows = Staff29.Query([[
        SELECT id, author, title, content, priority, hospital, created_at
        FROM sams_announcements ORDER BY id DESC LIMIT 200
    ]], {})

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            id = row.id,
            title = row.title or "",
            content = row.content or "",
            priority = row.priority or "normal",
            hospital = row.hospital or "pillbox",
            author = row.author or "Inconnu",
            timestamp = tostring(row.created_at or ""),
        }
    end
    return out
end)

Staff29.Cb("vfw:staff:sams:getReports", function(source)
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return {} end

    local rows = Staff29.Query([[
        SELECT id, author_identifier, citizen_identifier, title, content, hospital, deleted, created_at, updated_at
        FROM sams_reports ORDER BY id DESC LIMIT 200
    ]], {})

    local wanted, w = {}, 0
    for i = 1, #rows do
        w = w + 1
        wanted[w] = rows[i].citizen_identifier
        w = w + 1
        wanted[w] = rows[i].author_identifier
    end
    local names = namesByIdentifier(wanted)

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local deleted = tonumber(row.deleted) == 1
        out[i] = {
            id = row.id,
            hospital = row.hospital or "pillbox",
            citizenId = row.citizen_identifier or "",
            citizenName = names[row.citizen_identifier] or "Inconnu",
            createdBy = names[row.author_identifier] or "Inconnu",
            reason = row.title or "",
            description = row.content or "",
            timestamp = tostring(row.created_at or ""),
            deletedAt = deleted and tostring(row.updated_at or "") or nil,
        }
    end
    return out
end)

Staff29.Cb("vfw:staff:sams:getInvoices", function(source)
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return {} end

    local rows = Staff29.Query([[
        SELECT id, citizen_identifier, created_by, hospital, total, items, status, date
        FROM sams_invoices ORDER BY id DESC LIMIT 200
    ]], {})

    local wanted = {}
    for i = 1, #rows do wanted[i] = rows[i].citizen_identifier end
    local names = namesByIdentifier(wanted)

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local status = row.status or "unpaid"
        if status == "unpaid" then status = "pending" end
        out[i] = {
            id = row.id,
            citizenId = row.citizen_identifier or "",
            citizenName = names[row.citizen_identifier] or "Inconnu",
            createdBy = row.created_by or "Inconnu",
            hospital = row.hospital or "pillbox",
            total = tonumber(row.total) or 0,
            status = status,
            createdAt = tostring(row.date or ""),
            items = Staff29.Decode(row.items, {}) or {},
        }
    end
    return out
end)

RegisterNetEvent("vfw:staff:sams:permanentDeleteReport", function(reportId)
    local source = source
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return end

    local id = Staff29.ToInt(reportId, 1, 2147483647)
    if not id then return end
    if not Staff29.RateLimit(source, "staffSamsPurge", 1000) then return end

    local row = Staff29.Single("SELECT id, deleted FROM sams_reports WHERE id = ?", { id })
    if not row then
        Staff29.Notify(source, "ERROR", "SAMS", "Ce rapport est introuvable.")
        return
    end
    if tonumber(row.deleted) ~= 1 then
        Staff29.Notify(source, "ERROR", "SAMS", "Ce rapport doit d'abord être supprimé avant d'être effacé.")
        return
    end

    Staff29.Update("DELETE FROM sams_reports WHERE id = ?", { id })

    local api = samsApi()
    if api and api.Broadcast then api.Broadcast("sn_sams:reportRemoved", id) end

    logStaff(source, "sams_report_purge", { id = id })
    Staff29.Notify(source, "SUCCESS", "SAMS", "Le rapport a été effacé définitivement.")
end)

RegisterNetEvent("vfw:staff:sams:editInvoiceItems", function(invoiceId, items)
    local source = source
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return end

    local id = Staff29.ToInt(invoiceId, 1, 2147483647)
    if not id or not Staff29.IsTable(items) then return end
    if not Staff29.RateLimit(source, "staffSamsInvoice", 800) then return end

    local row = Staff29.Single("SELECT id, status FROM sams_invoices WHERE id = ?", { id })
    if not row then
        Staff29.Notify(source, "ERROR", "SAMS", "Cette facture est introuvable.")
        return
    end
    if row.status ~= "unpaid" then
        Staff29.Notify(source, "ERROR", "SAMS", "Seule une facture en attente peut être modifiée.")
        return
    end

    local clean, n, total = {}, 0, 0
    for i = 1, #items do
        local entry = items[i]
        if n >= 50 then break end
        if Staff29.IsTable(entry) then
            local label = Staff29.Clean(entry.label or entry.name, 80)
            local price = Staff29.ToInt(entry.price, 0, 10000000)
            local quantity = Staff29.ToInt(entry.quantity or entry.qty, 1, 1000)
            if label and price and quantity then
                n = n + 1
                clean[n] = { name = label, label = label, price = price, quantity = quantity }
                total = total + (price * quantity)
            end
        end
    end

    if n == 0 then
        Staff29.Notify(source, "ERROR", "SAMS", "Les articles envoyés ne sont pas valides.")
        return
    end
    if total > 10000000 then total = 10000000 end

    Staff29.Update("UPDATE sams_invoices SET items = ?, total = ? WHERE id = ?",
        { Staff29.Encode(clean), total, id })

    local api = samsApi()
    if api and api.Broadcast then
        api.Broadcast("sn_sams:invoiceUpdated", { id = id, total = total, items = Staff29.Encode(clean) })
    end

    logStaff(source, "sams_invoice_items", { id = id, total = total, count = n })
    Staff29.Notify(source, "SUCCESS", "SAMS", ("Facture mise à jour, nouveau montant : %d$."):format(total))
end)

Staff29.Cb("vfw:staff:sams:getGradePermissions", function(source, hospital)
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return {} end

    local job = type(hospital) == "string" and HOSPITAL_JOBS[hospital] or nil
    if not job then return {} end

    local rows = Staff29.Query(
        "SELECT grade, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC", { job })

    local grades = {}
    for i = 1, #rows do
        grades[i] = { grade = tonumber(rows[i].grade) or 0, label = rows[i].label or "" }
    end

    local stored = Staff29.Query(
        "SELECT grade, permissions FROM sams_grade_permissions WHERE hospital = ?", { hospital })

    local allowed = permissionSet()
    local permissions = {}
    for i = 1, #stored do
        local decoded = Staff29.Decode(stored[i].permissions, nil)
        local entry = {}
        if type(decoded) == "table" then
            for key, value in pairs(decoded) do
                if allowed[key] and value == true then entry[key] = true end
            end
        end
        permissions[tostring(stored[i].grade)] = entry
    end

    return { grades = grades, permissions = permissions, bossGrades = bossGrades() }
end)

RegisterNetEvent("vfw:staff:sams:updateGradePermissions", function(hospital, grade, perms)
    local source = source
    local xPlayer = Staff29.Require(source, SAMS_PERM)
    if not xPlayer then return end

    local job = type(hospital) == "string" and HOSPITAL_JOBS[hospital] or nil
    local level = Staff29.ToInt(grade, 0, 100)
    if not job or not level or not Staff29.IsTable(perms) then return end
    if not Staff29.RateLimit(source, "staffSamsPerms", 800) then return end

    if isBoss(level, bossGrades()) then
        Staff29.Notify(source, "ERROR", "SAMS", "Les responsables gardent toutes les permissions.")
        return
    end

    local exists = Staff29.Scalar(
        "SELECT COUNT(*) FROM job_grades WHERE job_name = ? AND grade = ?", { job, level }, 0)
    if (tonumber(exists) or 0) < 1 then
        Staff29.Notify(source, "ERROR", "SAMS", "Ce grade n'existe pas pour cet hôpital.")
        return
    end

    local allowed = permissionSet()
    local clean, n = {}, 0
    for key, value in pairs(perms) do
        if allowed[key] and value == true then
            clean[key] = true
            n = n + 1
        end
    end

    Staff29.Update([[
        INSERT INTO sams_grade_permissions (hospital, grade, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { hospital, tostring(level), Staff29.Encode(clean) })

    logStaff(source, "sams_grade_perms", { hospital = hospital, grade = level, count = n })
    Staff29.Notify(source, "SUCCESS", "SAMS",
        ("Permissions du grade %d enregistrées (%d accordées)."):format(level, n))
end)

local function savePlatines()
    local dense, n = {}, 0
    for _, record in pairs(platines) do
        n = n + 1
        dense[n] = record
    end

    Staff29.Update([[
        INSERT INTO variables (name, data) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data)
    ]], { PLATINE_STORE, Staff29.Encode(dense) })
end

local function readPlatine(id, entry)
    local position = toVec(entry.position)
    if not position then return nil end

    local scope = entry.scope == "job" and "job" or "public"
    local job = Staff29.Clean(entry.job, 60)
    if scope == "job" and not job then scope = "public" end

    return {
        id = id,
        name = Staff29.Clean(entry.name, 64) or ("Platine " .. tostring(id)),
        position = position,
        radius = Staff29.ToInt(entry.radius, 10, 500) or 50,
        floatingZ = tonumber(entry.floatingZ) or 0.5,
        scope = scope,
        job = scope == "job" and job or nil,
    }
end

local function loadPlatines()
    if platines then return platines end

    local row = Staff29.Single("SELECT data FROM variables WHERE name = ?", { PLATINE_STORE })
    if platines then return platines end

    local loaded = {}
    local decoded = row and Staff29.Decode(row.data, nil) or nil

    if type(decoded) == "table" then
        for key, entry in pairs(decoded) do
            local id = tonumber(key)
            if not id and Staff29.IsTable(entry) then id = tonumber(entry.id) end
            if id and Staff29.IsTable(entry) then
                local record = readPlatine(math.floor(id), entry)
                if record then
                    loaded[record.id] = record
                    if record.id > platineSeq then platineSeq = record.id end
                end
            end
        end
    end

    platines = loaded
    return platines
end

local function patchPlatine(record, patch)
    if patch.name ~= nil then
        local name = Staff29.Clean(patch.name, 64)
        if not name then return false end
        record.name = name
    end

    if patch.position ~= nil then
        local position = toVec(patch.position)
        if not position then return false end
        record.position = position
    end

    if patch.radius ~= nil then
        local radius = Staff29.ToInt(patch.radius, 10, 500)
        if not radius then return false end
        record.radius = radius
    end

    if patch.floatingZ ~= nil then
        local height = tonumber(patch.floatingZ)
        if not height or height ~= height or height < -5.0 or height > 10.0 then return false end
        record.floatingZ = height + 0.0
    end

    if patch.scope ~= nil then
        if patch.scope ~= "public" and patch.scope ~= "job" then return false end
        record.scope = patch.scope
        if patch.scope == "public" then record.job = nil end
    end

    if patch.job ~= nil then
        local job = Staff29.Clean(patch.job, 60)
        if not job or not (VFW.Jobs and VFW.Jobs[job]) then return false end
        record.job = job
    end

    if record.scope == "job" and not record.job then return false end
    return true
end

Staff29.Cb("vfw:staff:getAllPlatines", function(source)
    if not VFW.GetPlayerFromId(source) then return {} end
    return loadPlatines()
end)

RegisterNetEvent("vfw:staff:create:platine", function(data)
    local source = source
    local xPlayer = Staff29.Require(source, "builder_platine")
    if not xPlayer then return end
    if not Staff29.IsTable(data) then return end
    if not Staff29.RateLimit(source, "staffPlatineCreate", 1000) then return end

    loadPlatines()

    local name = Staff29.Clean(data.name, 64)
    local position = toVec(data.position)
    if not name or not position then
        Staff29.Notify(source, "ERROR", "Platines", "Les informations envoyées ne sont pas valides.")
        return
    end

    local count = 0
    for _ in pairs(platines) do count = count + 1 end
    if count >= 200 then
        Staff29.Notify(source, "ERROR", "Platines", "Le nombre maximum de platines est atteint.")
        return
    end

    platineSeq = platineSeq + 1
    local record = {
        id = platineSeq,
        name = name,
        position = position,
        radius = 50,
        floatingZ = 0.5,
        scope = "public",
        job = nil,
    }

    if not patchPlatine(record, {
            radius = data.radius,
            floatingZ = data.floatingZ,
            scope = data.scope,
            job = data.job,
        }) then
        platineSeq = platineSeq - 1
        Staff29.Notify(source, "ERROR", "Platines", "Les informations envoyées ne sont pas valides.")
        return
    end

    platines[record.id] = record
    savePlatines()

    TriggerClientEvent("core:createDJPlatines", -1, platines)
    logStaff(source, "dj_platine_create", { id = record.id, name = record.name, position = record.position })
end)

RegisterNetEvent("vfw:staff:update:platine", function(platineId, patch)
    local source = source
    local xPlayer = Staff29.Require(source, "builder_platine")
    if not xPlayer then return end

    local id = Staff29.ToInt(platineId, 1, 2147483647)
    if not id or not Staff29.IsTable(patch) then return end
    if not Staff29.RateLimit(source, "staffPlatineUpdate", 400) then return end

    loadPlatines()
    local record = platines[id]
    if not record then
        Staff29.Notify(source, "ERROR", "Platines", "Cette platine est introuvable.")
        return
    end

    local backup = {
        id = record.id, name = record.name, position = record.position,
        radius = record.radius, floatingZ = record.floatingZ, scope = record.scope, job = record.job,
    }

    if not patchPlatine(record, patch) then
        platines[id] = backup
        Staff29.Notify(source, "ERROR", "Platines", "Les informations envoyées ne sont pas valides.")
        return
    end

    savePlatines()

    TriggerClientEvent("core:updateDJPlatine", -1, id, record)
    logStaff(source, "dj_platine_update", { id = id, name = record.name })
end)

RegisterNetEvent("vfw:staff:delete:platine", function(platineId)
    local source = source
    local xPlayer = Staff29.Require(source, "builder_platine")
    if not xPlayer then return end

    local id = Staff29.ToInt(platineId, 1, 2147483647)
    if not id then return end
    if not Staff29.RateLimit(source, "staffPlatineDelete", 800) then return end

    loadPlatines()
    local record = platines[id]
    if not record then
        Staff29.Notify(source, "ERROR", "Platines", "Cette platine est introuvable.")
        return
    end

    platines[id] = nil
    savePlatines()

    TriggerClientEvent("core:deleteDJPlatine", -1, id)
    logStaff(source, "dj_platine_delete", { id = id, name = record.name })
end)

local function youtubeUrl(value)
    if type(value) ~= "string" then return nil end
    if #value < 8 or #value > 256 then return nil end
    if value:find("[%s\"'<>\\]") then return nil end

    local rest = value:gsub("^https?://", "")
    if rest:find("://") then return nil end
    rest = rest:gsub("^www%.", ""):gsub("^m%.", "")

    local id
    if rest:sub(1, 9) == "youtu.be/" then
        id = rest:match("^youtu%.be/([%w%-_]+)")
    elseif rest:sub(1, 12) == "youtube.com/" then
        id = rest:match("^youtube%.com/watch%?v=([%w%-_]+)")
            or rest:match("^youtube%.com/embed/([%w%-_]+)")
            or rest:match("^youtube%.com/shorts/([%w%-_]+)")
    end

    if not id or #id < 6 or #id > 24 then return nil end
    return ("https://www.youtube.com/watch?v=%s"):format(id)
end

RegisterNetEvent("vfw:staff:playVideo", function(videoLink, placementType, targetType, targetInfo)
    local source = source
    local xPlayer = Staff29.Require(source, "video_management")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffVideo", 3000) then return end

    local url = youtubeUrl(videoLink)
    if not url then
        Staff29.Notify(source, "ERROR", "Gestion Vidéos", "Ce lien n'est pas valide, utilisez YouTube uniquement.")
        return
    end

    local placement = Staff29.ToInt(placementType, PLACEMENT_FULLSCREEN, PLACEMENT_TOPRIGHT) or PLACEMENT_TOPRIGHT
    local kind = Staff29.ToInt(targetType, TARGET_PLAYER, TARGET_SERVER)
    if not kind then return end

    local targets, n = {}, 0

    if kind == TARGET_PLAYER then
        local targetId = Staff29.ToInt(targetInfo, 1, 65535)
        local xTarget = targetId and VFW.GetPlayerFromId(targetId) or nil
        if not xTarget then
            Staff29.Notify(source, "ERROR", "Gestion Vidéos", "Ce joueur n'est pas connecté.")
            return
        end
        if xTarget.source ~= source then
            n = n + 1
            targets[n] = xTarget.source
        end
    elseif kind == TARGET_ZONE then
        local radius = Staff29.ToInt(targetInfo, 1, 500)
        if not radius then
            Staff29.Notify(source, "ERROR", "Gestion Vidéos", "Ce rayon n'est pas valide.")
            return
        end
        local coords = xPlayer.getCoords()
        if not coords then return end
        local nearby = VFW.GetPlayersInRadius(coords, radius + 0.0)
        for i = 1, #nearby do
            if nearby[i].source ~= source then
                n = n + 1
                targets[n] = nearby[i].source
            end
        end
    else
        for src in pairs(VFW.Players) do
            if src ~= source then
                n = n + 1
                targets[n] = src
            end
        end
    end

    for i = 1, n do
        TriggerClientEvent("vfw:staff:startVideo", targets[i], url, placement, false)
    end
    TriggerClientEvent("vfw:staff:startVideo", source, url, placement, true)

    local watchers = {}
    for i = 1, n do watchers[targets[i]] = true end
    watchers[source] = true
    videoTargets[source] = watchers

    logStaff(source, "video_play", { url = url, placement = placement, target = kind, viewers = n + 1 })
end)

RegisterNetEvent("vfw:staff:stopVideo", function()
    local source = source
    local xPlayer = Staff29.Require(source, "video_management")
    if not xPlayer then return end

    local watchers = videoTargets[source]
    videoTargets[source] = nil

    if watchers then
        for src in pairs(watchers) do
            TriggerClientEvent("vfw:staff:stopVideoClient", src)
        end
    else
        TriggerClientEvent("vfw:staff:stopVideoClient", source)
    end

    logStaff(source, "video_stop", {})
end)

RegisterNetEvent("vfw:staff:stopVideoForAll", function()
    local source = source
    local xPlayer = Staff29.Require(source, "video_management")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffVideoStopAll", 1000) then return end

    videoTargets = {}
    TriggerClientEvent("vfw:staff:stopVideoClient", -1)

    logStaff(source, "video_stop_all", {})
end)

local function teleportsOf(xPlayer)
    local metadata = xPlayer.metadata
    if type(metadata) ~= "table" then
        metadata = {}
        xPlayer.metadata = metadata
    end

    local stored = metadata[TELEPORT_KEY]
    local list, n = {}, 0

    if type(stored) == "table" then
        for _, entry in pairs(stored) do
            if type(entry) == "table" then
                local id = Staff29.ToInt(entry.id, 1, 2147483647)
                local name = Staff29.Clean(entry.name, 64)
                local coords = toVec(entry.coords)
                if id and name and coords and n < TELEPORT_MAX then
                    n = n + 1
                    list[n] = { id = id, name = name, coords = coords }
                end
            end
        end
    end

    metadata[TELEPORT_KEY] = list
    return list, metadata
end

Staff29.Cb("vfw:staff:getCustomTeleports", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end

    local list = teleportsOf(xPlayer)
    local out = {}
    for i = 1, #list do
        out[list[i].id] = { id = list[i].id, name = list[i].name, coords = list[i].coords }
    end
    return out
end)

RegisterNetEvent("vfw:staff:createCustomTeleport", function(name, coords)
    local source = source
    local xPlayer = Staff29.Require(source, "staff_menu")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffTeleportCreate", 800) then return end

    local label = Staff29.Clean(name, 64)
    local position = toVec(coords)
    if not label or not position then
        Staff29.Notify(source, "ERROR", "Outils Staff", "Les informations envoyées ne sont pas valides.")
        return
    end

    local list, metadata = teleportsOf(xPlayer)

    if #list >= TELEPORT_MAX then
        Staff29.Notify(source, "ERROR", "Outils Staff", "Vous avez atteint le nombre maximum de points.")
        return
    end

    local nextId = 0
    for i = 1, #list do
        if list[i].id > nextId then nextId = list[i].id end
    end

    nextId = nextId + 1
    list[#list + 1] = { id = nextId, name = label, coords = position }

    xPlayer.setPlayerData("metadata", metadata)
    Staff29.Notify(source, "SUCCESS", "Outils Staff", ("Point enregistré : %s."):format(label))
end)

RegisterNetEvent("vfw:staff:deleteCustomTeleport", function(teleportId)
    local source = source
    local xPlayer = Staff29.Require(source, "staff_menu")
    if not xPlayer then return end

    local id = Staff29.ToInt(teleportId, 1, 2147483647)
    if not id then return end

    local list, metadata = teleportsOf(xPlayer)

    local index = nil
    for i = 1, #list do
        if list[i].id == id then
            index = i
            break
        end
    end
    if not index then return end

    table.remove(list, index)
    xPlayer.setPlayerData("metadata", metadata)
    Staff29.Notify(source, "INFO", "Outils Staff", "Le point a été supprimé.")
end)

local playerListCache, playerListCacheAt = nil, 0
local PLAYER_LIST_CACHE_SEC = 2

local function playtimeOf(target)
    local base = 0
    if target.globalData then
        base = tonumber(target.globalData.playtime) or 0
    end
    if target.sessionStart then
        base = base + math.max(0, os.time() - target.sessionStart)
    end
    return base
end

local function discordCached(src, target)
    if target.discordId then return target.discordId end
    local id = discordOf(src)
    target.discordId = id
    return id
end

Staff29.Cb("vfw:staff:getPlayerList", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end

    local now = os.time()
    if playerListCache and (now - playerListCacheAt) < PLAYER_LIST_CACHE_SEC then
        return playerListCache
    end

    local out, n = {}, 0
    for src, target in pairs(VFW.Players) do
        local global = target.globalData or {}
        local playtime = playtimeOf(target)

        n = n + 1
        out[n] = {
            source = src,
            id = target.uuid,
            uuid = target.uuid,
            charId = target.charId,
            identifier = target.identifier,
            accountId = target.accountId,
            pseudo = target.playerName,
            name = target.name,
            firstName = target.firstName,
            lastName = target.lastName,
            role = global.role or "user",
            time = clockText(playtime),
            new = playtime < 3600,
            dateOfBirth = target.dateofbirth,
            height = target.height,
            sex = target.sex,
            job = target.job and target.job.name or "unemployed",
            jobFull = jobLabel(target.job and target.job.name, target.job and target.job.grade),
            crew = target.faction ~= "" and target.faction or nil,
            factionFull = target.job2 and jobLabel(target.job2.name, target.job2.grade) or "Civil",
            instance = GetPlayerRoutingBucket(src) or 0,
            discord = discordCached(src, target),
        }
    end

    playerListCache = out
    playerListCacheAt = now
    return out
end)

Staff29.Cb("vfw:staff:getServerStats", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end

    local staffCount = 0
    for _, target in pairs(VFW.Players) do
        if target.hasPermission("staff_menu") then staffCount = staffCount + 1 end
    end

    local resources = 0
    for i = 0, GetNumResources() - 1 do
        if GetResourceState(GetResourceByFindIndex(i)) == "started" then
            resources = resources + 1
        end
    end

    return {
        players = VFW.GetPlayerCount(),
        staff = staffCount,
        resources = resources,
        uptime = durationText(os.time() - BOOT_TIME),
    }
end)

Staff29.Cb("vfw:staff:getAllStaffFromDB", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("list_staff") then return {} end

    local rows = Staff29.Query([[
        SELECT id, identifier, uuid, name, role FROM users
        WHERE role IS NOT NULL AND role <> '' AND role <> 'user'
        ORDER BY role ASC LIMIT 200
    ]], {})

    if #rows == 0 then return {} end

    local online = {}
    for src, target in pairs(VFW.Players) do
        online[target.accountId] = src
    end

    local marks, ids = {}, {}
    for i = 1, #rows do
        marks[i] = "?"
        ids[i] = rows[i].id
    end

    local chars = Staff29.Query(([[
        SELECT account_id, firstname, lastname FROM characters
        WHERE account_id IN (%s) AND deleted_at IS NULL ORDER BY char_slot ASC
    ]]):format(table.concat(marks, ",")), ids)

    local byAccount = {}
    for i = 1, #chars do
        local bucket = byAccount[chars[i].account_id]
        if not bucket then
            bucket = {}
            byAccount[chars[i].account_id] = bucket
        end
        bucket[#bucket + 1] = { firstname = chars[i].firstname or "", lastname = chars[i].lastname or "" }
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            globalId = tonumber(row.uuid) or 0,
            pseudo = row.name,
            role = row.role,
            online = online[row.id] ~= nil,
            source = online[row.id],
            characters = byAccount[row.id] or {},
        }
    end

    return out
end)

RegisterNetEvent("vfw:staff:toggleDevWeight", function(enabled)
    local source = source
    local xPlayer = Staff29.Require(source, "dev_tools")
    if not xPlayer then return end

    local active = enabled == true

    if active then
        if not devWeight[source] then
            devWeight[source] = {
                original = tonumber(xPlayer.maxWeight) or Config.MaxWeight,
                identifier = xPlayer.identifier,
            }
        end
        xPlayer.setMaxWeight(5000)
    else
        local saved = devWeight[source]
        devWeight[source] = nil
        xPlayer.setMaxWeight(saved and saved.original or Config.MaxWeight)
    end

    logStaff(source, "dev_weight", { enabled = active })
end)

AddEventHandler("playerDropped", function()
    local source = source

    videoTargets[source] = nil

    local saved = devWeight[source]
    if saved then
        devWeight[source] = nil
        local xPlayer = VFW.GetPlayerFromId(source)
        if xPlayer then xPlayer.maxWeight = saved.original end
        Staff29.Update("UPDATE characters SET max_weight = ? WHERE identifier = ?",
            { saved.original, saved.identifier })
    end
end)

Staff29.Cb("vfw:staff:applyPedScale", function(source, targetId, scale)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur staff introuvable." end
    if not (xPlayer.hasPermission("setped") or xPlayer.hasPermission("dev") or xPlayer.hasPermission("staff") or xPlayer.hasPermission("gestion")) then
        return false, "Permission refusée (setped / dev)."
    end

    local target = Staff29.ToInt(targetId, 1, 65535)
    if not target or not VFW.GetPlayerFromId(target) then
        return false, "Joueur cible introuvable."
    end

    local value = tonumber(scale)
    if not value or value ~= value then return false, "Taille invalide." end
    if value < 0.1 then value = 0.1 end
    if value > 2.0 then value = 2.0 end

    if not VFW.PedScale or not VFW.PedScale.Set then
        return false, "Système de taille indisponible."
    end

    local applied = math.abs(value - 1.0) < 0.001 and 1.0 or value
    local ran, result = pcall(VFW.PedScale.Set, target, applied)
    if not ran then
        console.error("[pedscale] " .. tostring(result))
        return false, "Erreur SQL ped_scales."
    end
    if not result then return false, "Impossible d'appliquer la taille." end

    logStaff(source, "ped_scale", { target = target, scale = applied })
    return true, ("%.2f"):format(applied)
end)

RegisterNetEvent("vfw:staff:resetPed", function()
    local source = source
    local xPlayer = Staff29.Require(source, "menu_anim")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffResetPed", 1000) then return end

    xPlayer.triggerEvent("vfw:staff:restorePed", nil)
    logStaff(source, "animator_reset_ped", {})
end)

RegisterNetEvent("vfw:staff:setAnimatorOutfit", function(enabled)
    local source = source
    local xPlayer = Staff29.Require(source, "menu_anim")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffAnimOutfit", 500) then return end

    local active = enabled == true
    xPlayer.triggerEvent("vfw:staff:setAnimatorClothes", active)
    logStaff(source, "animator_outfit", { enabled = active })
end)

RegisterNetEvent("vfw:staff:setDoorBypass", function(enabled)
    local source = source
    local xPlayer = Staff29.Require(source, "doorlock")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffDoorBypass", 500) then return end

    local active = enabled == true
    Player(source).state:set("staffDoorBypass", active, true)
    logStaff(source, "door_bypass", { enabled = active })
end)

RegisterNetEvent("vfw:staff:refreshServerData", function()
    local source = source
    local xPlayer = Staff29.Require(source, "staff_menu")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "staffRefreshServer", 2000) then return end

    if VFW.Environment and VFW.Environment.SyncTo then
        VFW.Environment.SyncTo(source)
    end
    TriggerEvent("vfw:sync:requestTime", source)
end)

RegisterNetEvent("vfw:staff:sendAnnouncement", function(message, kind)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local text = Staff29.Clean(message, 256)
    if not text or text == "" then return end
    if not Staff29.RateLimit(source, "staffAnnounce", 3000) then return end

    local scope = kind == "global" and "global" or "staff"
    local permission = scope == "global" and "announce_serv" or "announce_staff"

    if not xPlayer.hasPermission(permission) then
        Staff29.Notify(source, "ERROR", "Annonces", "Vous n'avez pas la permission requise.")
        return
    end

    if scope == "global" then
        TriggerClientEvent("vfw:staff:receiveAnnouncement", -1, text, scope, xPlayer.name)
    else
        for _, target in pairs(VFW.Players) do
            if target.hasPermission("staff_menu") then
                target.triggerEvent("vfw:staff:receiveAnnouncement", text, scope, xPlayer.name)
            end
        end
    end

    logStaff(source, "announce_" .. scope, { message = text })
end)
