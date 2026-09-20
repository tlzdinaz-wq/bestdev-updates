---@meta _
---@diagnostic disable: duplicate-doc-field

-- Notifications périodiques (hub Gestion)

local STORE = "periodic_notifications"
local TYPES = {
    DEFAULT = true, ROUGE = true, VERT = true, JAUNE = true, ORANGE = true,
    BLEU = true, VIOLET = true, ROSE = true, GRIS = true, BLANC = true, NOIR = true,
}

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
        or xPlayer.hasPermission("server_management") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { success = false, ok = false, error = message or "Action impossible." }
end

local function loadList()
    local raw = VFW.Variables.GetVariable(STORE)
    if type(raw) ~= "table" then return {} end
    if raw[1] ~= nil or next(raw) == nil then return raw end
    local out = {}
    for _, row in pairs(raw) do
        if type(row) == "table" then out[#out + 1] = row end
    end
    table.sort(out, function(a, b) return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end)
    return out
end

local function saveList(list)
    VFW.Variables.SetVariable(STORE, list)
end

local function nextId(list)
    local maxId = 0
    for i = 1, #list do
        local id = tonumber(list[i].id) or 0
        if id > maxId then maxId = id end
    end
    return maxId + 1
end

local function findIndex(list, id)
    id = tonumber(id)
    if not id then return nil end
    for i = 1, #list do
        if tonumber(list[i].id) == id then return i end
    end
    return nil
end

local function payload(list)
    return { ok = true, success = true, notifications = list }
end

local function broadcast(row)
    if type(row) ~= "table" or type(row.message) ~= "string" or row.message == "" then return false end
    TriggerClientEvent("vfw:showNotification", -1, {
        type = row.type or "DEFAULT",
        subtitle = row.subtitle or "Notification",
        message = row.message,
        content = row.message,
    })
    return true
end

local function parseScheduled(dateStr, timeStr)
    if type(dateStr) ~= "string" or type(timeStr) ~= "string" then return nil end
    local y, mo, d = dateStr:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    local h, mi = timeStr:match("^(%d%d):(%d%d)")
    if not y then return nil end
    return os.time({
        year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h) or 0, min = tonumber(mi) or 0, sec = 0,
    }), ("%s %s:00"):format(dateStr, timeStr:sub(1, 5))
end

local function sanitize(data, existing)
    existing = existing or {}
    if type(data) ~= "table" then return nil, "Données invalides." end
    local message = Staff29.Clean(data.message or "", 500)
    if not message or message:gsub("%s", "") == "" then return nil, "Le message est obligatoire." end
    local ntype = Staff29.Clean(data.type or "DEFAULT", 20) or "DEFAULT"
    if not TYPES[ntype] then ntype = "DEFAULT" end
    local subtitle = Staff29.Clean(data.subtitle or "Notification", 80) or "Notification"
    local mode = data.mode
    if mode ~= "scheduled" and mode ~= "recurring" then mode = "immediate" end

    local row = {
        id = existing.id,
        type = ntype,
        subtitle = subtitle,
        message = message,
        mode = mode,
        last_sent = existing.last_sent or 0,
        sent = existing.sent == true,
        created_at = existing.created_at or os.date("%Y-%m-%d %H:%M:%S"),
    }

    if mode == "scheduled" then
        local ts, stamp = parseScheduled(data.scheduledDate, data.scheduledTime)
        if not ts and type(data.scheduled_at) == "string" then
            local datePart, timePart = data.scheduled_at:match("^(%d%d%d%d%-%d%d%-%d%d) (%d%d:%d%d)")
            ts, stamp = parseScheduled(datePart, timePart)
        end
        if not ts then return nil, "Date et heure de planification requises." end
        row.scheduled_at = stamp
        row.scheduled_ts = ts
        row.sent = false
    elseif mode == "recurring" then
        local minutes = tonumber(data.intervalMinutes or data.interval_minutes)
        minutes = math.floor(minutes or 0)
        if minutes < 1 or minutes > 10080 then return nil, "Intervalle entre 1 et 10080 minutes." end
        row.interval_minutes = minutes
    end

    return row
end

local function createRow(source, data)
    local row, err = sanitize(data, {})
    if not row then return fail(err) end
    if row.mode == "immediate" then
        broadcast(row)
        return { success = true, ok = true, immediate = true, notifications = loadList() }
    end
    local list = loadList()
    row.id = nextId(list)
    list[#list + 1] = row
    saveList(list)
    return payload(list)
end

local function updateRow(data)
    local list = loadList()
    local idx = findIndex(list, data and data.id)
    if not idx then return fail("Notification introuvable.") end
    local row, err = sanitize(data, list[idx])
    if not row then return fail(err) end
    row.id = list[idx].id
    if row.mode == "immediate" then
        broadcast(row)
        return { success = true, ok = true, immediate = true, notifications = list }
    end
    list[idx] = row
    saveList(list)
    return payload(list)
end

local function deleteRow(id)
    local list = loadList()
    local idx = findIndex(list, id)
    if not idx then return fail("Notification introuvable.") end
    table.remove(list, idx)
    saveList(list)
    return payload(list)
end

local function sendNow(id)
    local list = loadList()
    local idx = findIndex(list, id)
    if not idx then return fail("Notification introuvable.") end
    broadcast(list[idx])
    list[idx].last_sent = os.time()
    if list[idx].mode == "scheduled" then list[idx].sent = true end
    saveList(list)
    return payload(list)
end

Staff29.Cb("periodicNotifs:getAll", function(source)
    if not staffOk(source) then return {} end
    return loadList()
end)

Staff29.Cb("periodicNotifs:create", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    return createRow(source, data)
end)

Staff29.Cb("periodicNotifs:update", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    return updateRow(data)
end)

Staff29.Cb("periodicNotifs:delete", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    return deleteRow(id)
end)

Staff29.Cb("periodicNotifs:sendNow", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    return sendNow(id)
end)

Staff29.Cb("gestionNotifs:hubPanel", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    return payload(loadList())
end)

Staff29.Cb("gestionNotifs:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = data.action
    if action == "create" then return createRow(source, data)
    elseif action == "update" then return updateRow(data)
    elseif action == "delete" then return deleteRow(data.id)
    elseif action == "sendNow" then return sendNow(data.id)
    end
    return fail("Action inconnue.")
end)

CreateThread(function()
    while true do
        Wait(15000)
        local list = loadList()
        local now = os.time()
        local dirty = false
        for i = 1, #list do
            local row = list[i]
            if row.mode == "recurring" then
                local interval = (tonumber(row.interval_minutes) or 0) * 60
                local last = tonumber(row.last_sent) or 0
                if interval >= 60 and (last == 0 or (now - last) >= interval) then
                    if broadcast(row) then
                        row.last_sent = now
                        dirty = true
                    end
                end
            elseif row.mode == "scheduled" and row.sent ~= true then
                local ts = tonumber(row.scheduled_ts)
                if not ts and type(row.scheduled_at) == "string" then
                    local datePart, timePart = row.scheduled_at:match("^(%d%d%d%d%-%d%d%-%d%d) (%d%d:%d%d)")
                    ts = select(1, parseScheduled(datePart, timePart))
                    row.scheduled_ts = ts
                end
                if ts and now >= ts then
                    if broadcast(row) then
                        row.sent = true
                        row.last_sent = now
                        dirty = true
                    end
                end
            end
        end
        if dirty then saveList(list) end
    end
end)
