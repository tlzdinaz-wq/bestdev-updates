local LEDGER = {
    warn = "sanction_warn",
    kick = "sanction_kick",
    ban = "sanction_ban",
    tig = "sanction_tig",
    tigweapon = "sanction_tigweapon",
}

local TYPE_OF_ACTION = {}
for kind, action in pairs(LEDGER) do TYPE_OF_ACTION[action] = kind end

local REASON_MIN = 2
local REASON_MAX = 200
local HISTORY_LIMIT = 200
local SCAN_LIMIT = 500
local OFFLINE_PER_PAGE = 25
local BAN_SWEEP_MS = 60000
local REPORT_MAX = 50
local REPORT_MIN_LEN = 4
local REPORT_MAX_LEN = 300
local TIG_MAX_TASKS = 300
local TIGWEAPON_MAX_MINUTES = 600
local BAN_MAX_HOURS = 8760
local BAN_MAX_DAYS = 365
local PENDING_WARN_TTL = 120

local function likeEscape(value)
    local text = tostring(value or "")
    text = text:gsub("([%%_\\])", "\\%1")
    return text
end

local function unixNow()
    return os.time()
end

local function humanDate(value)
    local unix = tonumber(value)
    if not unix or unix <= 0 then return nil end
    return os.date("%d/%m/%Y %H:%M", unix)
end

local function humanPlaytime(value)
    local total = math.floor(tonumber(value) or 0)
    if total < 0 then total = 0 end
    return ("%02d:%02d:%02d"):format(math.floor(total / 3600), math.floor((total % 3600) / 60), total % 60)
end

local function plural(count, one, many)
    if count <= 1 then return ("%d %s"):format(count, one) end
    return ("%d %s"):format(count, many)
end

local function trim(value)
    if type(value) ~= "string" then return nil end
    local text = value:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function cleanReason(value)
    local text = Staff29.Clean(value, REASON_MAX)
    text = trim(text)
    if not text or #text < REASON_MIN then return nil end
    return text
end

local function displayName(xPlayer)
    if not xPlayer then return "Système" end
    local text = trim(("%s %s"):format(xPlayer.firstName or "", xPlayer.lastName or ""))
    if not text or text == "" then return xPlayer.playerName or "Membre du staff" end
    return text
end

local function accountRowById(accountId)
    if accountId == nil or tostring(accountId) == "" then return nil end
    return Staff29.Single(
        "SELECT id, identifier, name, role, playtime, banned, last_seen FROM users WHERE id = ?",
        { tostring(accountId) })
end

local function accountRowByIdentifier(identifier)
    if type(identifier) ~= "string" or identifier == "" then return nil end
    local row = Staff29.Single(
        "SELECT id, identifier, name, role, playtime, banned, last_seen FROM users WHERE identifier = ?",
        { identifier })
    if row then return row end

    local accountId = Staff29.Scalar("SELECT account_id FROM characters WHERE identifier = ? LIMIT 1", { identifier })
    if accountId == nil or tostring(accountId) == "" then return nil end
    return accountRowById(accountId)
end

local function targetFromPlayer(xPlayer)
    return {
        source = xPlayer.source,
        accountId = xPlayer.accountId,
        identifier = xPlayer.identifier,
        charId = xPlayer.charId,
        name = displayName(xPlayer),
        pseudo = xPlayer.playerName,
        online = true,
    }
end

local function targetFromRow(row)
    return {
        source = nil,
        accountId = row.id,
        identifier = row.identifier,
        charId = nil,
        name = row.name or "Compte sans pseudo",
        pseudo = row.name,
        online = false,
    }
end

local function onlineByAccount(accountId)
    if accountId == nil or tostring(accountId) == "" then return nil end
    local wanted = tostring(accountId)
    for _, other in pairs(VFW.Players) do
        if tostring(other.accountId) == wanted then return other end
    end
    return nil
end

local function resolveBySession(sessionId)
    local src = Staff29.ToInt(sessionId, 1, 65535)
    if not src then return nil end
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return nil end
    return targetFromPlayer(xPlayer)
end

local function resolveByAccount(accountId)
    local xPlayer = onlineByAccount(accountId)
    if xPlayer then return targetFromPlayer(xPlayer) end
    local row = accountRowById(accountId)
    if not row then return nil end
    return targetFromRow(row)
end

local function resolveByIdentifier(identifier)
    local row = accountRowByIdentifier(identifier)
    if not row then return nil end
    local xPlayer = onlineByAccount(row.id)
    if xPlayer then return targetFromPlayer(xPlayer) end
    return targetFromRow(row)
end

local function ledgerFilter(accountId)
    return ("%%\"accountId\":\"%s\"%%"):format(likeEscape(accountId))
end

local function payloadMatchesAccount(payload, accountId)
    if type(payload) ~= "table" or accountId == nil or tostring(accountId) == "" then return false end
    return tostring(payload.accountId or "") == tostring(accountId)
end

local function ledgerInsert(staffSource, target, payload)
    return Staff29.Insert(
        "INSERT INTO logs_staff (source_id, char_id, action, payload) VALUES (?, ?, ?, ?)",
        {
            tonumber(staffSource) or 0,
            tonumber(target.charId) or 0,
            LEDGER[payload.type],
            Staff29.Encode(payload),
        })
end

local function ledgerRead(sanctionId)
    local id = Staff29.ToInt(sanctionId, 1, 2147483647)
    if not id then return nil end

    local row = Staff29.Single("SELECT id, action, payload FROM logs_staff WHERE id = ?", { id })
    if not row then return nil end

    local kind = TYPE_OF_ACTION[row.action]
    if not kind then return nil end

    local payload = Staff29.Decode(row.payload, nil)
    if type(payload) ~= "table" then return nil end

    payload.type = kind
    return id, payload
end

local function ledgerSave(sanctionId, payload)
    return Staff29.Update("UPDATE logs_staff SET payload = ? WHERE id = ?",
        { Staff29.Encode(payload), sanctionId })
end

local function ledgerDrop(sanctionId, action)
    return Staff29.Update("DELETE FROM logs_staff WHERE id = ? AND action = ?", { sanctionId, action })
end

local function isExpired(payload)
    local expires = tonumber(payload.expiresAt)
    if not expires or expires <= 0 then return false end
    return expires <= unixNow()
end

local function durationLabel(payload)
    if payload.type == "tig" then
        local tasks = tonumber(payload.tasks) or 0
        return plural(tasks, "tâche", "tâches")
    end

    if payload.type == "tigweapon" then
        local minutes = math.floor((tonumber(payload.durationSeconds) or 0) / 60)
        if minutes <= 0 then return "Permanent" end
        return plural(minutes, "minute", "minutes")
    end

    if payload.type ~= "ban" then return nil end

    local expires = tonumber(payload.expiresAt)
    if not expires or expires <= 0 then return "Permanent" end

    local unit = payload.durationUnit
    local amount = tonumber(payload.durationAmount) or 0
    if unit == "jours" then return plural(amount, "jour", "jours") end
    if unit == "heures" then return plural(amount, "heure", "heures") end

    local hours = math.floor(((tonumber(payload.durationSeconds) or 0) + 1799) / 3600)
    if hours <= 0 then return "Permanent" end
    return plural(hours, "heure", "heures")
end

local function toSanction(id, payload)
    if not LEDGER[payload.type] then return nil end

    local issuedAt = tonumber(payload.at) or 0
    local expiresAt = tonumber(payload.expiresAt)

    return {
        id = id,
        type = payload.type,
        active = payload.active and true or false,
        reason = payload.reason or "Aucun motif",
        issuedBy = payload.by or "Système",
        by = payload.by or "Système",
        issuedAt = issuedAt,
        issuedAtFormatted = humanDate(issuedAt) or "Date inconnue",
        at = humanDate(issuedAt) or "Date inconnue",
        duration = durationLabel(payload),
        expiresAt = expiresAt,
        expiresAtFormatted = humanDate(expiresAt),
        tigTasks = tonumber(payload.tasks),
        tigTasksCompleted = tonumber(payload.tasksCompleted),
        revokedBy = payload.revokedBy,
        revokedAt = tonumber(payload.revokedAt),
        completedAt = tonumber(payload.completedAt),
        targetName = payload.targetName,
    }
end

local function ledgerHistory(accountId)
    if accountId == nil or tostring(accountId) == "" then return {} end

    local rows = Staff29.Query(([[ 
        SELECT id, action, payload FROM logs_staff
        WHERE action IN (?, ?, ?, ?, ?)
        ORDER BY id DESC LIMIT %d
    ]]):format(SCAN_LIMIT), {
        LEDGER.warn, LEDGER.kick, LEDGER.ban, LEDGER.tig, LEDGER.tigweapon,
    })

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local kind = TYPE_OF_ACTION[row.action]
        local payload = Staff29.Decode(row.payload, nil)
        if kind and payloadMatchesAccount(payload, accountId) then
            payload.type = kind
            if payload.active and isExpired(payload) then
                payload.active = false
                payload.completedAt = payload.expiresAt
            end
            local entry = toSanction(row.id, payload)
            if entry then
                n = n + 1
                out[n] = entry
                if n >= HISTORY_LIMIT then break end
            end
        end
    end

    return out
end

local function activeSanctionOf(accountId, kind)
    if accountId == nil or tostring(accountId) == "" then return nil end

    local rows = Staff29.Query(([[ 
        SELECT id, payload FROM logs_staff
        WHERE action = ? AND payload LIKE '%%"active":true%%'
        ORDER BY id DESC LIMIT %d
    ]]):format(SCAN_LIMIT), { LEDGER[kind] })

    for i = 1, #rows do
        local payload = Staff29.Decode(rows[i].payload, nil)
        if payloadMatchesAccount(payload, accountId) and payload.active then
            payload.type = kind
            if not isExpired(payload) then
                return rows[i].id, payload
            end
        end
    end

    return nil
end

local function hasAnticheatBan(accountId)
    if accountId == nil or tostring(accountId) == "" then return false end
    local identifier = Staff29.Scalar("SELECT identifier FROM users WHERE id = ?", { tostring(accountId) })
    if type(identifier) ~= "string" or identifier == "" then return false end

    local count = Staff29.Scalar("SELECT COUNT(*) FROM anticheat_bans WHERE license = ?", { identifier }, 0)
    return (tonumber(count) or 0) > 0
end

local function refreshBanFlag(accountId)
    if accountId == nil or tostring(accountId) == "" then return nil end
    accountId = tostring(accountId)

    local activeId = activeSanctionOf(accountId, "ban")
    if activeId then
        Staff29.Update("UPDATE users SET banned = 1 WHERE id = ?", { accountId })
        return activeId
    end

    if hasAnticheatBan(accountId) then return nil end

    Staff29.Update("UPDATE users SET banned = 0 WHERE id = ?", { accountId })
    return nil
end

local function auditLog(staffSource, action, payload)
    TriggerEvent("vfw:logs:staff", staffSource, action, payload)
end

local function notifyTarget(target, variant, subtitle, message)
    if not target.source then return end
    Staff29.Notify(target.source, variant, subtitle, message)
end

local function applyWarn(target, payload)
    if not target.source then return end

    if payload.displayMode == "chat" then
        notifyTarget(target, "ERROR", "Avertissement",
            ("Vous avez reçu un avertissement du staff. Motif : %s"):format(payload.reason))
        return
    end

    TriggerClientEvent("vfw:warn:showPopup", target.source,
        "Vous avez reçu un avertissement du staff.", payload.reason)
end

local function applyKick(target, payload)
    if not target.source then return end
    DropPlayer(target.source, ("Vous avez été expulsé du serveur. Motif : %s"):format(payload.reason))
end

local function applyBan(target, payload)
    Staff29.Update("UPDATE users SET banned = 1 WHERE id = ?", { target.accountId })

    if not target.source then return end

    local expires = humanDate(payload.expiresAt)
    if expires then
        DropPlayer(target.source,
            ("Vous êtes banni de ce serveur jusqu'au %s. Motif : %s"):format(expires, payload.reason))
        return
    end

    DropPlayer(target.source, ("Vous êtes banni définitivement de ce serveur. Motif : %s"):format(payload.reason))
end

local function applyTigWeapon(target, payload)
    if not target.source then return end
    TriggerClientEvent("vfw:tigweapon:apply", target.source,
        tonumber(payload.durationSeconds) or 0, payload.reason)
    notifyTarget(target, "ERROR", "Sanctions",
        ("Vos armes vous sont retirées pour %s. Motif : %s"):format(durationLabel(payload), payload.reason))
end

local function applyTig(target, payload)
    notifyTarget(target, "ERROR", "Sanctions",
        ("Le staff vous a attribué %s. Motif : %s"):format(durationLabel(payload), payload.reason))

    if not target.source then return end

    TriggerClientEvent("vfw:tig:start", target.source, {
        total = tonumber(payload.tasks) or 0,
        completed = tonumber(payload.tasksCompleted) or 0,
        reason = payload.reason,
    })
end

local function commitSanction(staffSource, xStaff, target, payload)
    payload.accountId = target.accountId
    payload.identifier = target.identifier
    payload.charId = target.charId
    payload.targetName = target.name
    payload.by = displayName(xStaff)
    payload.byAccountId = xStaff and xStaff.accountId or nil
    payload.at = unixNow()

    local sanctionId = ledgerInsert(staffSource, target, payload)
    if not sanctionId then return nil end

    if payload.type == "warn" then
        applyWarn(target, payload)
    elseif payload.type == "kick" then
        applyKick(target, payload)
    elseif payload.type == "ban" then
        applyBan(target, payload)
    elseif payload.type == "tigweapon" then
        applyTigWeapon(target, payload)
    elseif payload.type == "tig" then
        applyTig(target, payload)
    end

    auditLog(staffSource, "staff_sanction_" .. payload.type, {
        sanctionId = sanctionId,
        target = target.accountId,
        targetName = target.name,
        targetIdentifier = target.identifier,
        reason = payload.reason,
        expiresAt = payload.expiresAt,
        tasks = payload.tasks,
    })

    return sanctionId
end

local function revokeSanction(staffSource, xStaff, sanctionId, allowedKinds, permissionByKind)
    local id, payload = ledgerRead(sanctionId)
    if not id then return false end
    if allowedKinds and not allowedKinds[payload.type] then return false end

    local permission = permissionByKind and permissionByKind[payload.type]
    if permission and not xStaff.hasPermission(permission) then
        Staff29.Notify(staffSource, "ERROR", "Sanctions", "Vous n'avez pas la permission requise.")
        return false
    end

    if not payload.active then return false end

    payload.active = false
    payload.revokedBy = displayName(xStaff)
    payload.revokedAt = unixNow()

    if ledgerSave(id, payload) == 0 then return false end

    local target = resolveByAccount(payload.accountId)

    if payload.type == "ban" then
        refreshBanFlag(payload.accountId)
    elseif payload.type == "tig" and target and target.source then
        TriggerClientEvent("vfw:tig:stop", target.source)
    elseif payload.type == "tigweapon" and target and target.source then
        TriggerClientEvent("vfw:tigweapon:remove", target.source)
    end

    if target and target.source then
        Staff29.Notify(target.source, "SUCCESS", "Sanctions", "Une sanction vous concernant a été levée.")
    end

    auditLog(staffSource, "staff_sanction_revoke", {
        sanctionId = id,
        kind = payload.type,
        target = payload.accountId,
        targetName = payload.targetName,
    })

    return true
end

local function sweepExpiredBans()
    local rows = Staff29.Query(([[
        SELECT id, payload FROM logs_staff
        WHERE action = ? AND payload LIKE '%%"active":true%%'
        ORDER BY id DESC LIMIT %d
    ]]):format(SCAN_LIMIT), { LEDGER.ban })

    local touched = {}
    for i = 1, #rows do
        local payload = Staff29.Decode(rows[i].payload, nil)
        if type(payload) == "table" and payload.active then
            payload.type = "ban"
            if isExpired(payload) then
                payload.active = false
                payload.completedAt = payload.expiresAt
                ledgerSave(rows[i].id, payload)
                if type(payload.accountId) == "string" then touched[payload.accountId] = true end
            end
        end
    end

    for accountId in pairs(touched) do
        refreshBanFlag(accountId)
    end
end

CreateThread(function()
    while not VFW.Ready do Wait(500) end
    while true do
        Wait(BAN_SWEEP_MS)
        local ok, err = pcall(sweepExpiredBans)
        if not ok then
            console.warn(("[sanctions] balayage des bans expirés : %s"):format(tostring(err)))
        end
    end
end)

Staff29.Cb("vfw:staff:getPlayerSanctions", function(source, sessionId, identifier, _discord)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end

    local target = resolveBySession(sessionId)
    if not target and Staff29.IsString(identifier, 80) then
        target = resolveByIdentifier(identifier)
    end
    if not target then return {} end

    return ledgerHistory(target.accountId)
end)

Staff29.Cb("vfw:staff:getSanctions", function(source, sessionId, accountId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end

    local target = resolveBySession(sessionId)
    if not target and Staff29.IsString(accountId, 64) then
        target = resolveByAccount(accountId)
    end
    if not target then return {} end

    return ledgerHistory(target.accountId)
end)

Staff29.Cb("vfw:staff:applySanction", function(source, data)
    local xPlayer = Staff29.Require(source, "sanctions")
    if not xPlayer then return false end
    if not Staff29.IsTable(data) then return false end
    if not Staff29.RateLimit(source, "applySanction", 1000) then return false end

    local kind = data.type
    if type(kind) ~= "string" or not LEDGER[kind] then return false end

    local reason = cleanReason(data.reason)
    if not reason then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return false
    end

    local target = resolveBySession(data.targetId)
    if not target and Staff29.IsString(data.globalId, 64) then
        target = resolveByAccount(data.globalId)
    end
    if not target then return false end

    -- Antiban (Gestion > Développeurs) : joueurs protégés contre kick / ban
    if (kind == "kick" or kind == "ban") and VFW.IsAntiban and VFW.IsAntiban(target.accountId) then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur est protégé (antiban) : kick et ban impossibles.")
        return false
    end

    local payload = { type = kind, reason = reason, active = true }

    if kind == "warn" then
        payload.active = false
        payload.displayMode = (data.displayMode == "chat") and "chat" or "visual"
    elseif kind == "kick" then
        payload.active = false
        if not target.source then
            Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'est pas connecté.")
            return false
        end
    elseif kind == "ban" then
        local unit = data.durationType
        if unit == "permanent" then
            payload.expiresAt = nil
        elseif unit == "hours" then
            local hours = Staff29.ToInt(data.duration, 1, BAN_MAX_HOURS)
            if not hours then return false end
            payload.durationUnit = "heures"
            payload.durationAmount = hours
            payload.durationSeconds = hours * 3600
            payload.expiresAt = unixNow() + payload.durationSeconds
        elseif unit == "days" then
            local days = Staff29.ToInt(data.duration, 1, BAN_MAX_DAYS)
            if not days then return false end
            payload.durationUnit = "jours"
            payload.durationAmount = days
            payload.durationSeconds = days * 86400
            payload.expiresAt = unixNow() + payload.durationSeconds
        else
            return false
        end
    elseif kind == "tig" then
        local tasks = Staff29.ToInt(data.tigTasks, 1, TIG_MAX_TASKS)
        if not tasks then return false end
        payload.tasks = tasks
        payload.tasksCompleted = 0
    elseif kind == "tigweapon" then
        local minutes = Staff29.ToInt(data.duration, 1, TIGWEAPON_MAX_MINUTES)
        if not minutes then return false end
        if not target.source then
            Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'est pas connecté.")
            return false
        end
        payload.durationSeconds = minutes * 60
        payload.expiresAt = unixNow() + payload.durationSeconds
    end

    return commitSanction(source, xPlayer, target, payload) ~= nil
end)

Staff29.Cb("vfw:staff:revokeSanction", function(source, sanctionId)
    local xPlayer = Staff29.Require(source, "sanctions")
    if not xPlayer then return false end

    return revokeSanction(source, xPlayer, sanctionId,
        { ban = true, tig = true, tigweapon = true },
        { ban = "ban", tig = "remove_tig" })
end)

Staff29.Cb("vfw:staff:revokeBan", function(source, sanctionId)
    local xPlayer = Staff29.Require(source, "ban")
    if not xPlayer then return false end
    return revokeSanction(source, xPlayer, sanctionId, { ban = true }, nil)
end)

Staff29.Cb("vfw:staff:revokeTIG", function(source, sanctionId)
    local xPlayer = Staff29.Require(source, "remove_tig")
    if not xPlayer then return false end
    return revokeSanction(source, xPlayer, sanctionId, { tig = true }, nil)
end)

Staff29.Cb("vfw:staff:removeWarn", function(source, sanctionId)
    local xPlayer = Staff29.Require(source, "modify_sanctions")
    if not xPlayer then return false end

    local id, payload = ledgerRead(sanctionId)
    if not id or payload.type ~= "warn" then return false end
    if ledgerDrop(id, LEDGER.warn) == 0 then return false end

    auditLog(source, "staff_sanction_delete", {
        sanctionId = id,
        kind = "warn",
        target = payload.accountId,
        targetName = payload.targetName,
        reason = payload.reason,
    })

    return true
end)

Staff29.Cb("vfw:staff:modifySanctionReason", function(source, sanctionId, sanctionType, newReason)
    local xPlayer = Staff29.Require(source, "modify_sanctions")
    if not xPlayer then return false end

    local reason = cleanReason(newReason)
    if not reason then return false end

    local id, payload = ledgerRead(sanctionId)
    if not id then return false end
    if type(sanctionType) == "string" and sanctionType ~= "" and payload.type ~= sanctionType then return false end
    if payload.reason == reason then return true end

    local previous = payload.reason
    payload.reason = reason
    if ledgerSave(id, payload) == 0 then return false end

    auditLog(source, "staff_sanction_reason", {
        sanctionId = id,
        kind = payload.type,
        target = payload.accountId,
        targetName = payload.targetName,
        before = previous,
        after = reason,
    })

    return true
end)

Staff29.Cb("vfw:staff:modifySanctionDuration", function(source, sanctionId, sanctionType, newDuration)
    local xPlayer = Staff29.Require(source, "modify_sanctions")
    if not xPlayer then return false end

    local id, payload = ledgerRead(sanctionId)
    if not id then return false end
    if type(sanctionType) == "string" and sanctionType ~= "" and payload.type ~= sanctionType then return false end
    if payload.type ~= "ban" and payload.type ~= "tig" and payload.type ~= "tigweapon" then return false end
    if not payload.active then return false end

    local target = resolveByAccount(payload.accountId)

    if payload.type == "tig" then
        local tasks = Staff29.ToInt(newDuration, 0, TIG_MAX_TASKS)
        if not tasks then return false end

        if tasks == 0 then
            payload.active = false
            payload.revokedBy = displayName(xPlayer)
            payload.revokedAt = unixNow()
            if target and target.source then TriggerClientEvent("vfw:tig:stop", target.source) end
        else
            payload.tasks = tasks
        end
    else
        local seconds = Staff29.ToInt(newDuration, -1, BAN_MAX_DAYS * 86400)
        if not seconds then return false end

        if seconds == -1 then
            payload.expiresAt = nil
            payload.durationUnit = nil
            payload.durationAmount = nil
            payload.durationSeconds = nil
            if payload.type == "tigweapon" then return false end
        elseif seconds == 0 then
            payload.active = false
            payload.revokedBy = displayName(xPlayer)
            payload.revokedAt = unixNow()
            if payload.type == "tigweapon" and target and target.source then
                TriggerClientEvent("vfw:tigweapon:remove", target.source)
            end
        else
            payload.durationSeconds = seconds
            payload.expiresAt = unixNow() + seconds
            payload.durationUnit = nil
            payload.durationAmount = nil
            if payload.type == "tigweapon" and target and target.source then
                TriggerClientEvent("vfw:tigweapon:apply", target.source, seconds, payload.reason)
            end
        end
    end

    if ledgerSave(id, payload) == 0 then return false end

    if payload.type == "ban" then
        refreshBanFlag(payload.accountId)
    end

    auditLog(source, "staff_sanction_duration", {
        sanctionId = id,
        kind = payload.type,
        target = payload.accountId,
        targetName = payload.targetName,
        expiresAt = payload.expiresAt,
        tasks = payload.tasks,
        active = payload.active,
    })

    return true
end)

RegisterNetEvent("vfw:staff:quickWarn", function(targetId, reason, showVisual)
    local source = source
    local xPlayer = Staff29.Require(source, "warn")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "quickWarn", 1000) then return end

    local cleaned = cleanReason(reason)
    if not cleaned then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then return end

    commitSanction(source, xPlayer, target, {
        type = "warn",
        reason = cleaned,
        active = false,
        displayMode = (showVisual == false) and "chat" or "visual",
    })
end)

RegisterNetEvent("vfw:staff:quickKick", function(targetId, reason)
    local source = source
    if Staff29.EventBlocked("vfw:staff:quickKick", source) then return end

    local xPlayer = Staff29.Require(source, "kick")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "quickKick", 1000) then return end

    local cleaned = cleanReason(reason)
    if not cleaned then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then return end

    commitSanction(source, xPlayer, target, { type = "kick", reason = cleaned, active = false })
end)

RegisterNetEvent("core:KickPlayer", function(targetId, reason)
    local source = source
    if Staff29.EventBlocked("core:KickPlayer", source) then return end

    local xPlayer = Staff29.Require(source, "kick")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "kickPlayer", 1000) then return end

    local cleaned = cleanReason(reason)
    if not cleaned then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then return end

    commitSanction(source, xPlayer, target, { type = "kick", reason = cleaned, active = false })
end)

local function banPayloadFrom(reason, time, banType)
    local payload = { type = "ban", reason = reason, active = true }

    if banType == "perm" then
        return payload
    end

    if banType == "heures" then
        local hours = Staff29.ToInt(time, 1, BAN_MAX_HOURS)
        if not hours then return nil end
        payload.durationUnit = "heures"
        payload.durationAmount = hours
        payload.durationSeconds = hours * 3600
        payload.expiresAt = unixNow() + payload.durationSeconds
        return payload
    end

    if banType == "jours" then
        local days = Staff29.ToInt(time, 1, BAN_MAX_DAYS)
        if not days then return nil end
        payload.durationUnit = "jours"
        payload.durationAmount = days
        payload.durationSeconds = days * 86400
        payload.expiresAt = unixNow() + payload.durationSeconds
        return payload
    end

    return nil
end

RegisterNetEvent("core:ban:banplayer", function(targetId, reason, time, _staffId, banType)
    local source = source
    if Staff29.EventBlocked("core:ban:banplayer", source) then return end

    local xPlayer = Staff29.Require(source, "ban")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "banPlayer", 1500) then return end

    local cleaned = cleanReason(reason)
    if not cleaned then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local payload = banPayloadFrom(cleaned, time, banType)
    if not payload then
        Staff29.Notify(source, "ERROR", "Sanctions", "Cette durée n'est pas valide.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then return end

    if commitSanction(source, xPlayer, target, payload) then
        Staff29.Notify(source, "SUCCESS", "Sanctions", ("%s est désormais banni."):format(target.name))
    end
end)

RegisterNetEvent("core:ban:banofflineplayer", function(accountId, reason, time, _staffId, banType)
    local source = source
    if Staff29.EventBlocked("core:ban:banofflineplayer", source) then return end

    local xPlayer = Staff29.Require(source, "ban_offline")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "banOffline", 1500) then return end
    if not Staff29.IsString(accountId, 64) then return end

    local cleaned = cleanReason(reason)
    if not cleaned then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local payload = banPayloadFrom(cleaned, time, banType)
    if not payload then
        Staff29.Notify(source, "ERROR", "Sanctions", "Cette durée n'est pas valide.")
        return
    end

    local target = resolveByAccount(accountId)
    if not target then return end

    if commitSanction(source, xPlayer, target, payload) then
        Staff29.Notify(source, "SUCCESS", "Sanctions", ("%s est désormais banni."):format(target.name))
    end
end)

RegisterNetEvent("core:ban:unbanplayer", function(banId)
    local source = source
    if Staff29.EventBlocked("core:ban:unbanplayer", source) then return end

    local xPlayer = Staff29.Require(source, "ban")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "unbanPlayer", 1000) then return end

    if revokeSanction(source, xPlayer, banId, { ban = true }, nil) then
        Staff29.Notify(source, "SUCCESS", "Sanctions", "Le bannissement a été levé.")
        return
    end

    Staff29.Notify(source, "ERROR", "Sanctions", "Ce bannissement est introuvable ou déjà levé.")
end)

RegisterNetEvent("vfw:admin:giveTIGOffline", function(accountId, amount, reason)
    local source = source
    local xPlayer = Staff29.Require(source, "give_tig")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "giveTigOffline", 1000) then return end
    if not Staff29.IsString(accountId, 64) then return end

    local tasks = Staff29.ToInt(amount, 1, TIG_MAX_TASKS)
    if not tasks then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce nombre n'est pas valide.")
        return
    end

    local cleaned = cleanReason(reason) or "Aucun motif"
    local target = resolveByAccount(accountId)
    if not target then return end

    if commitSanction(source, xPlayer, target, {
        type = "tig",
        reason = cleaned,
        active = true,
        tasks = tasks,
        tasksCompleted = 0,
    }) then
        Staff29.Notify(source, "SUCCESS", "Sanctions",
            ("%s a reçu %s."):format(target.name, plural(tasks, "tâche", "tâches")))
    end
end)

RegisterNetEvent("vfw:admin:giveTIG", function(targetId, amount, reason)
    local source = source
    local xPlayer = Staff29.Require(source, "give_tig")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "giveTig", 1000) then return end

    local targetSource = Staff29.ToInt(targetId, 1, 65535)
    local tasks = Staff29.ToInt(amount, 1, TIG_MAX_TASKS)
    if not targetSource or not tasks then
        Staff29.Notify(source, "ERROR", "Sanctions", "Utilisation : ID joueur et nombre de tâches valides requis.")
        return
    end

    local target = resolveBySession(targetSource)
    if not target then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'est pas connecté.")
        return
    end

    local cleaned = cleanReason(reason) or "Aucun motif"
    if commitSanction(source, xPlayer, target, {
        type = "tig",
        reason = cleaned,
        active = true,
        tasks = tasks,
        tasksCompleted = 0,
    }) then
        Staff29.Notify(source, "SUCCESS", "Sanctions",
            ("%s a reçu %s."):format(target.name, plural(tasks, "tâche", "tâches")))
    end
end)

RegisterNetEvent("vfw:admin:removeTIGOffline", function(accountId)
    local source = source
    local xPlayer = Staff29.Require(source, "remove_tig")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "removeTigOffline", 1000) then return end
    if not Staff29.IsString(accountId, 64) then return end

    local target = resolveByAccount(accountId)
    if not target then return end

    local sanctionId = activeSanctionOf(target.accountId, "tig")
    if not sanctionId then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'a aucune tâche en cours.")
        return
    end

    if revokeSanction(source, xPlayer, sanctionId, { tig = true }, nil) then
        Staff29.Notify(source, "SUCCESS", "Sanctions", ("Les tâches de %s ont été levées."):format(target.name))
    end
end)

RegisterNetEvent("vfw:admin:removeTIG", function(targetId)
    local source = source
    local xPlayer = Staff29.Require(source, "remove_tig")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "removeTig", 1000) then return end

    local targetSource = Staff29.ToInt(targetId, 1, 65535)
    if not targetSource then
        Staff29.Notify(source, "ERROR", "Sanctions", "ID joueur invalide.")
        return
    end

    local target = resolveBySession(targetSource)
    if not target then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'est pas connecté.")
        return
    end

    local sanctionId = activeSanctionOf(target.accountId, "tig")
    if not sanctionId then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'a aucune tâche en cours.")
        return
    end

    if revokeSanction(source, xPlayer, sanctionId, { tig = true }, nil) then
        Staff29.Notify(source, "SUCCESS", "Sanctions", ("Les tâches de %s ont été levées."):format(target.name))
    end
end)

RegisterNetEvent("vfw:tig:completeTask", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "tigCompleteTask", 3000) then return end

    local id, payload = activeSanctionOf(xPlayer.accountId, "tig")
    if not id then return end

    local total = tonumber(payload.tasks) or 0
    local done = (tonumber(payload.tasksCompleted) or 0) + 1
    if done > total then done = total end
    payload.tasksCompleted = done

    if done >= total then
        payload.active = false
        payload.completedAt = unixNow()
        ledgerSave(id, payload)
        TriggerClientEvent("vfw:tig:completed", source)
        Staff29.Notify(source, "SUCCESS", "Sanctions", "Vos travaux d'intérêt général sont terminés.")
        return
    end

    ledgerSave(id, payload)
    TriggerClientEvent("vfw:tig:updateProgress", source, done, total)
end)

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    if not xPlayer then return end

    VFW.SetTimeout(5000, function()
        if not VFW.GetPlayerFromId(source) then return end

        local id, payload = activeSanctionOf(xPlayer.accountId, "tig")
        if not id then return end

        TriggerClientEvent("vfw:tig:start", source, {
            total = tonumber(payload.tasks) or 0,
            completed = tonumber(payload.tasksCompleted) or 0,
            reason = payload.reason,
        })
    end)
end)

local pendingWarns = {}

RegisterNetEvent("vfw:staff:warn:execute", function(showVisual)
    local source = source
    local xPlayer = Staff29.Require(source, "warn")
    if not xPlayer then return end

    local pending = pendingWarns[source]
    pendingWarns[source] = nil
    if not pending then return end
    if (unixNow() - pending.at) > PENDING_WARN_TTL then return end

    local target = resolveBySession(pending.targetId)
    if not target then return end

    commitSanction(source, xPlayer, target, {
        type = "warn",
        reason = pending.reason,
        active = false,
        displayMode = (showVisual == false) and "chat" or "visual",
    })
end)

AddEventHandler("vfw:playerDropped", function(source)
    pendingWarns[source] = nil
end)

local function joinArgs(args, from)
    local parts, n = {}, 0
    for i = from, #args do
        n = n + 1
        parts[n] = tostring(args[i])
    end
    return table.concat(parts, " ")
end

VFW.RegisterCommand("warn", "warn", function(source, xPlayer, args)
    local targetId = Staff29.ToInt(args and args[1], 1, 65535)
    if not targetId then
        Staff29.Notify(source, "ERROR", "Avertissement", "Utilisation : /warn [ID] [motif]")
        return
    end

    local reason = cleanReason(joinArgs(args, 2))
    if not reason then
        Staff29.Notify(source, "ERROR", "Avertissement", "Le motif est trop court.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then
        Staff29.Notify(source, "ERROR", "Avertissement", "Ce joueur n'est pas connecté.")
        return
    end

    pendingWarns[source] = { targetId = targetId, reason = reason, at = unixNow() }
    TriggerClientEvent("vfw:staff:warn:chooseMode", source)
end, {
    help = "Donner un avertissement à un joueur connecté.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "motif", help = "Motif de l'avertissement" },
    },
})

VFW.RegisterCommand("tig", "give_tig", function(source, xPlayer, args)
    local targetId = Staff29.ToInt(args and args[1], 1, 65535)
    local tasks = Staff29.ToInt(args and args[2], 1, TIG_MAX_TASKS)
    if not targetId or not tasks then
        Staff29.Notify(source, "ERROR", "Sanctions", "Utilisation : /tig [ID] [nombre] [motif]")
        return
    end

    local reason = cleanReason(joinArgs(args, 3))
    if not reason then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'est pas connecté.")
        return
    end

    if commitSanction(source, xPlayer, target, {
        type = "tig",
        reason = reason,
        active = true,
        tasks = tasks,
        tasksCompleted = 0,
    }) then
        Staff29.Notify(source, "SUCCESS", "Sanctions",
            ("%s a reçu %s."):format(target.name, plural(tasks, "tâche", "tâches")))
    end
end, {
    help = "Attribuer des travaux d'intérêt général à un joueur connecté.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "nombre", help = "Nombre de tâches" },
        { name = "motif", help = "Motif de la sanction" },
    },
})

VFW.RegisterCommand("tigweapon", "give_tig", function(source, xPlayer, args)
    local targetId = Staff29.ToInt(args and args[1], 1, 65535)
    local minutes = Staff29.ToInt(args and args[2], 1, TIGWEAPON_MAX_MINUTES)
    if not targetId or not minutes then
        Staff29.Notify(source, "ERROR", "Sanctions", "Utilisation : /tigweapon [ID] [minutes] [motif]")
        return
    end

    local reason = cleanReason(joinArgs(args, 3))
    if not reason then
        Staff29.Notify(source, "ERROR", "Sanctions", "Le motif est trop court.")
        return
    end

    local target = resolveBySession(targetId)
    if not target then
        Staff29.Notify(source, "ERROR", "Sanctions", "Ce joueur n'est pas connecté.")
        return
    end

    if commitSanction(source, xPlayer, target, {
        type = "tigweapon",
        reason = reason,
        active = true,
        durationSeconds = minutes * 60,
        expiresAt = unixNow() + (minutes * 60),
    }) then
        Staff29.Notify(source, "SUCCESS", "Sanctions",
            ("Les armes de %s sont bloquées pour %s."):format(target.name, plural(minutes, "minute", "minutes")))
    end
end, {
    help = "Bloquer les armes d'un joueur connecté pendant une durée en minutes.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "minutes", help = "Durée en minutes" },
        { name = "motif", help = "Motif de la sanction" },
    },
})

local function charListOf(accountId, currentCharId)
    local rows = Staff29.Query([[
        SELECT id, firstname, lastname FROM characters
        WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot ASC
    ]], { accountId })

    local list, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        list[n] = {
            id = rows[i].id,
            name = trim(("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")),
            actual = currentCharId ~= nil and rows[i].id == currentCharId,
        }
    end

    return { charList = list }
end

Staff29.Cb("vfw:staff:getCharList", function(source, sessionId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("wipe") then return { charList = {} } end

    local target = resolveBySession(sessionId)
    if not target then return { charList = {} } end

    return charListOf(target.accountId, target.charId)
end)

Staff29.Cb("vfw:staff:getOfflineCharList", function(source, accountId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("wipe") then return { charList = {} } end
    if not Staff29.IsString(accountId, 64) then return { charList = {} } end

    local row = accountRowById(accountId)
    if not row then return { charList = {} } end

    return charListOf(row.id, nil)
end)

local function wipeCharacter(staffSource, xStaff, accountId, charId)
    local id = Staff29.ToInt(charId, 1, 2147483647)
    if not id then return false end

    local row = Staff29.Single([[
        SELECT id, account_id, identifier, firstname, lastname FROM characters
        WHERE id = ? AND account_id = ? AND deleted_at IS NULL
    ]], { id, accountId })
    if not row then return false end

    -- Suppression douce + identifiant archivé (« w<id>:license:… ») : l'identifiant
    -- « char<slot>:… » est unique, sans ça le joueur ne peut plus recréer un personnage
    -- dans ce slot (Duplicate entry uk_characters_identifier). Les tatouages suivent.
    local archived = VFW.ArchivedCharIdentifier and VFW.ArchivedCharIdentifier(id, row.identifier) or row.identifier
    if Staff29.Update("UPDATE characters SET deleted_at = ?, identifier = ? WHERE id = ? AND deleted_at IS NULL",
        { Staff29.Now(), archived, id }) == 0 then
        return false
    end
    if archived ~= row.identifier then
        Staff29.Update("UPDATE character_tattoos SET identifier = ? WHERE identifier = ?", { archived, row.identifier })
    end

    local owner = VFW.GetPlayerFromCharId(id)
    if owner then
        DropPlayer(owner.source, "Ce personnage a été réinitialisé par le staff. Reconnectez-vous pour continuer.")
    end

    auditLog(staffSource, "staff_wipe", {
        charId = id,
        target = accountId,
        targetName = trim(("%s %s"):format(row.firstname or "", row.lastname or "")),
        by = displayName(xStaff),
    })

    return true
end

RegisterNetEvent("vfw:staff:wipePlayer", function(sessionId, charId)
    local source = source
    if Staff29.EventBlocked("vfw:staff:wipePlayer", source) then return end

    local xPlayer = Staff29.Require(source, "wipe")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "wipePlayer", 1500) then return end

    local target = resolveBySession(sessionId)
    if not target then return end

    if wipeCharacter(source, xPlayer, target.accountId, charId) then
        Staff29.Notify(source, "SUCCESS", "Wipe Données", "Le personnage a été réinitialisé.")
        return
    end

    Staff29.Notify(source, "ERROR", "Wipe Données", "Ce personnage est introuvable.")
end)

RegisterNetEvent("vfw:staff:wipeOfflinePlayer", function(accountId, charId)
    local source = source
    if Staff29.EventBlocked("vfw:staff:wipeOfflinePlayer", source) then return end

    local xPlayer = Staff29.Require(source, "wipe")
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "wipeOffline", 1500) then return end
    if not Staff29.IsString(accountId, 64) then return end

    local row = accountRowById(accountId)
    if not row then return end

    if wipeCharacter(source, xPlayer, row.id, charId) then
        Staff29.Notify(source, "SUCCESS", "Wipe Données", "Le personnage a été réinitialisé.")
        return
    end

    Staff29.Notify(source, "ERROR", "Wipe Données", "Ce personnage est introuvable.")
end)

local function onlineAccountMap()
    local map = {}
    for src, other in pairs(VFW.Players) do
        if type(other.accountId) == "string" then map[other.accountId] = src end
    end
    return map
end

local function accountsWithActiveTig()
    local set = {}
    local rows = Staff29.Query(([[
        SELECT payload FROM logs_staff
        WHERE action = ? AND payload LIKE '%%"active":true%%'
        ORDER BY id DESC LIMIT %d
    ]]):format(SCAN_LIMIT), { LEDGER.tig })

    for i = 1, #rows do
        local payload = Staff29.Decode(rows[i].payload, nil)
        if type(payload) == "table" and payload.active and type(payload.accountId) == "string" then
            set[payload.accountId] = true
        end
    end

    return set
end

local function summariseAccount(row, online, tigSet)
    local src = online[row.id]
    return {
        id = row.id,
        pseudo = row.name or "Sans pseudo",
        identifier = row.identifier,
        discord = nil,
        role = row.role or "user",
        time = humanPlaytime(row.playtime),
        isOnline = src ~= nil,
        onlineSource = src,
        isBanned = tonumber(row.banned) == 1,
        hasTig = tigSet[row.id] == true,
        color = 0xFFFFFF,
    }
end

Staff29.Cb("vfw:staff:getAllOfflinePlayers", function(source, page)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("players_offline") then return {}, 0 end

    local pageNum = Staff29.ToInt(page, 1, 100000) or 1
    local offset = (pageNum - 1) * OFFLINE_PER_PAGE

    local total = Staff29.Scalar("SELECT COUNT(*) FROM users", {}, 0)
    local rows = Staff29.Query(([[
        SELECT id, identifier, name, role, playtime, banned FROM users
        ORDER BY last_seen IS NULL ASC, last_seen DESC, created_at DESC
        LIMIT %d OFFSET %d
    ]]):format(OFFLINE_PER_PAGE, offset), {})

    local online = onlineAccountMap()
    local tigSet = accountsWithActiveTig()

    local out, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        out[n] = summariseAccount(rows[i], online, tigSet)
    end

    return out, tonumber(total) or 0
end)

Staff29.Cb("vfw:staff:searchOfflinePlayers", function(source, query)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("players_offline") then return {} end

    local needle = trim(Staff29.Clean(query, 64))
    if not needle or #needle < 2 then return {} end

    local pattern = "%" .. likeEscape(needle) .. "%"

    local rows = Staff29.Query(([[
        SELECT id, identifier, name, role, playtime, banned FROM users
        WHERE id LIKE ? OR name LIKE ? OR identifier LIKE ?
        ORDER BY name ASC LIMIT %d
    ]]):format(OFFLINE_PER_PAGE), { pattern, pattern, pattern })

    local seen = {}
    local out, n = {}, 0
    local online = onlineAccountMap()
    local tigSet = accountsWithActiveTig()

    for i = 1, #rows do
        seen[rows[i].id] = true
        n = n + 1
        out[n] = summariseAccount(rows[i], online, tigSet)
    end

    if n < OFFLINE_PER_PAGE then
        local chars = Staff29.Query(([[
            SELECT DISTINCT account_id FROM characters
            WHERE deleted_at IS NULL AND (firstname LIKE ? OR lastname LIKE ?)
            LIMIT %d
        ]]):format(OFFLINE_PER_PAGE), { pattern, pattern })

        for i = 1, #chars do
            local accountId = chars[i].account_id
            if type(accountId) == "string" and not seen[accountId] and n < OFFLINE_PER_PAGE then
                local row = accountRowById(accountId)
                if row then
                    seen[accountId] = true
                    n = n + 1
                    out[n] = summariseAccount(row, online, tigSet)
                end
            end
        end
    end

    return out
end)

Staff29.Cb("vfw:staff:getOfflinePlayerChars", function(source, accountId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("players_offline") then return {} end
    if not Staff29.IsString(accountId, 64) then return {} end

    local rows = Staff29.Query([[
        SELECT id, firstname, lastname, dateofbirth FROM characters
        WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot ASC
    ]], { accountId })

    local out, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        out[n] = {
            id = rows[i].id,
            name = trim(("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")),
            dateOfBirth = rows[i].dateofbirth or "Non défini",
        }
    end

    return out
end)

Staff29.Cb("vfw:staff:getOfflinePlayerInfo", function(source, accountId, charId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("players_offline") then return nil end
    if not Staff29.IsString(accountId, 64) then return nil end

    local row = accountRowById(accountId)
    if not row then return nil end

    local online = onlineAccountMap()
    local info = summariseAccount(row, online, accountsWithActiveTig())

    local character
    local wanted = Staff29.ToInt(charId, 1, 2147483647)
    if wanted then
        character = Staff29.Single([[
            SELECT id, firstname, lastname, dateofbirth, height, sex, job, job_grade, faction
            FROM characters WHERE id = ? AND account_id = ? AND deleted_at IS NULL
        ]], { wanted, row.id })
    end

    if not character then
        character = Staff29.Single([[
            SELECT id, firstname, lastname, dateofbirth, height, sex, job, job_grade, faction
            FROM characters WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot ASC LIMIT 1
        ]], { row.id })
    end

    if character then
        info.charId = character.id
        info.firstName = character.firstname
        info.lastName = character.lastname
        info.name = trim(("%s %s"):format(character.firstname or "", character.lastname or ""))
        info.dateOfBirth = character.dateofbirth
        info.height = character.height
        info.sex = (character.sex == "f") and "Femme" or "Homme"

        local job = VFW.DB.BuildJob(character.job, character.job_grade)
        if type(job) == "table" then
            info.jobFull = ("%s - %s"):format(job.label or job.name or "Civil", job.grade_label or "")
        end

        if type(character.faction) == "string" and character.faction ~= "" then
            info.factionFull = character.faction
        end
    end

    local history = ledgerHistory(row.id)
    info.sanctionsCount = #history
    info.activeBanId = activeSanctionOf(row.id, "ban")

    return info
end)

local reports = {}
local reportSeq = 0

local function staffAudience()
    local out, n = {}, 0
    for src, other in pairs(VFW.Players) do
        if other.hasPermission("staff_menu") then
            n = n + 1
            out[n] = src
        end
    end
    return out
end

local function serialiseReport(entry, now)
    return {
        id = entry.id,
        date = entry.date,
        message = entry.message,
        timestamp = entry.timestamp,
        serverTime = now,
        takenBy = entry.takenBy,
        takenByName = entry.takenByName,
        player = {
            name = entry.player.name,
            source = entry.player.source,
            id = entry.player.accountId,
        },
    }
end

local function reportList()
    local now = unixNow()
    local out, n = {}, 0
    for i = 1, #reports do
        n = n + 1
        out[n] = serialiseReport(reports[i], now)
    end
    return out
end

local function pushReportList(target)
    local payload = reportList()
    if target then
        TriggerClientEvent("vfw:staff:reports", target, payload)
        return
    end

    local audience = staffAudience()
    for i = 1, #audience do
        TriggerClientEvent("vfw:staff:reports", audience[i], payload)
    end
end

local function broadcastReport(event, payload)
    local audience = staffAudience()
    for i = 1, #audience do
        TriggerClientEvent(event, audience[i], payload)
    end
end

local function findReportBySession(sessionId)
    local src = Staff29.ToInt(sessionId, 1, 65535)
    if not src then return nil end
    for i = 1, #reports do
        if reports[i].player.source == src then return i, reports[i] end
    end
    return nil
end

local function findReportById(reportId)
    local id = Staff29.ToInt(reportId, 1, 2147483647)
    if not id then return nil end
    for i = 1, #reports do
        if reports[i].id == id then return i, reports[i] end
    end
    return nil
end

local function removeReport(index)
    local entry = reports[index]
    if not entry then return end
    table.remove(reports, index)
    broadcastReport("vfw:staff:deleteReport", entry.id)
    -- Toujours renvoyer la liste (y compris vide) : le HUD staff ne doit pas rester à 1.
    pushReportList()
end

RegisterNetEvent("vfw:staff:requestReports", function()
    local src = source
    local xPlayer = Staff29.Require(src, "staff_menu")
    if not xPlayer then return end
    pushReportList(src)
end)

--- Ouvre un signalement pour un joueur (commande /report et formulaire Support du pause menu).
--- Retourne true, ou false + message d'erreur destiné au joueur.
local function submitReport(source, xPlayer, rawMessage)
    if not Staff29.RateLimit(source, "report", 30000) then
        return false, "Vous venez déjà d'envoyer un signalement."
    end

    local message = trim(Staff29.Clean(rawMessage, REPORT_MAX_LEN))
    if not message or #message < REPORT_MIN_LEN then
        return false, "Décrivez votre problème en quelques mots."
    end

    for i = 1, #reports do
        if reports[i].player.source == source then
            return false, "Votre précédent signalement est encore en attente."
        end
    end

    if #reports >= REPORT_MAX then
        return false, "Le staff est saturé, réessayez dans un moment."
    end

    reportSeq = reportSeq + 1
    local now = unixNow()
    local entry = {
        id = reportSeq,
        date = os.date("%d/%m/%Y %H:%M", now),
        message = message,
        timestamp = now,
        takenBy = nil,
        takenByName = nil,
        player = {
            name = displayName(xPlayer),
            source = source,
            accountId = xPlayer.accountId,
        },
    }
    reports[#reports + 1] = entry

    broadcastReport("vfw:staff:report", serialiseReport(entry, now))

    local audience = staffAudience()
    for i = 1, #audience do
        TriggerClientEvent("vfw:showNotification", audience[i], {
            type = "ADMIN_NEW_REPORT",
            variant = "INFO",
            subtitle = "Signalement",
            message = ("%s vient d'envoyer un signalement."):format(entry.player.name),
        })
    end

    auditLog(source, "staff_report_open", { reportId = entry.id, message = message })
    return true
end

VFW.RegisterCommand("report", "", function(source, xPlayer, args)
    local ok, err = submitReport(source, xPlayer, joinArgs(args, 1))
    if not ok then
        Staff29.Notify(source, "ERROR", "Signalement", err)
        return
    end
    Staff29.Notify(source, "SUCCESS", "Signalement", "Votre signalement a été transmis au staff.")
end, {
    help = "Envoyer un signalement au staff.",
    params = { { name = "message", help = "Description du problème" } },
})

-- Formulaire Support du pause menu : même circuit que /report.
Staff29.Cb("core:pausemenu:report", function(source, message)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, message = "Joueur introuvable." } end
    local ok, err = submitReport(source, xPlayer, type(message) == "string" and message or "")
    return {
        ok = ok == true,
        message = ok and "Votre signalement a été transmis au staff." or err,
    }
end)

RegisterNetEvent("vfw:staff:takeReport", function(sessionId)
    local source = source
    local xPlayer = Staff29.Require(source, "staff_menu")
    if not xPlayer then return end

    local index, entry = findReportBySession(sessionId)
    if not index then return end
    if entry.takenBy then
        Staff29.Notify(source, "ERROR", "Signalement", "Ce signalement est déjà pris en charge.")
        return
    end

    entry.takenBy = source
    entry.takenByName = displayName(xPlayer)

    broadcastReport("vfw:staff:updateReport", serialiseReport(entry, unixNow()))
    auditLog(source, "staff_report_take", { reportId = entry.id, target = entry.player.accountId })

    if VFW.GetPlayerFromId(entry.player.source) then
        Staff29.Notify(entry.player.source, "INFO", "Signalement", "Un membre du staff prend en charge votre demande.")
    end
end)

RegisterNetEvent("vfw:staff:abandonReport", function(sessionId)
    local source = source
    local xPlayer = Staff29.Require(source, "staff_menu")
    if not xPlayer then return end

    local index, entry = findReportBySession(sessionId)
    if not index then return end

    entry.takenBy = nil
    entry.takenByName = nil

    broadcastReport("vfw:staff:updateReport", serialiseReport(entry, unixNow()))
    auditLog(source, "staff_report_release", { reportId = entry.id, target = entry.player.accountId })
end)

RegisterNetEvent("vfw:staff:closeReport", function(sessionId, reportId)
    local source = source
    local xPlayer = Staff29.Require(source, "staff_menu")
    if not xPlayer then return end

    local index, entry = findReportBySession(sessionId)
    if not index then
        index, entry = findReportById(reportId or sessionId)
    end
    if not index then return end

    auditLog(source, "staff_report_close", { reportId = entry.id, target = entry.player.accountId })

    if VFW.GetPlayerFromId(entry.player.source) then
        Staff29.Notify(entry.player.source, "SUCCESS", "Signalement", "Votre signalement a été traité par le staff.")
    end

    removeReport(index)
end)

AddEventHandler("vfw:playerDropped", function(source)
    for i = #reports, 1, -1 do
        if reports[i].player.source == source then
            removeReport(i)
        end
    end
end)

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return end
    VFW.SetTimeout(2000, function()
        if not VFW.GetPlayerFromId(source) then return end
        pushReportList(source)
    end)
end)

CreateThread(function()
    while not VFW.Ready do Wait(500) end
    while true do
        Wait(60000)
        if #reports > 0 then
            pushReportList()
        end
    end
end)

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    console.init("Sanctions", "sanctions, reports et wipes branchés sur logs_staff")
end)
