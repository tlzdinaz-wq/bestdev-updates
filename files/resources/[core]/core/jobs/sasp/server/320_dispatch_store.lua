VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Dispatch = VFW.Dispatch or {}

local JC = VFW.JobsCommon
local Dispatch = VFW.Dispatch

Dispatch.MaxCalls = 60
Dispatch.CallTTL = 1800000

local units = {}
local calls = {}
local assignments = {}
local groups = {}
local nextCallId = 1

function Dispatch.AllowedJobs()
    local out = {}
    if type(Config) == "table" and type(Config.AllowedJobs) == "table" then
        for jobName, enabled in pairs(Config.AllowedJobs) do
            if enabled then out[#out + 1] = jobName end
        end
    end
    if #out == 0 then
        out = { "police", "sheriff" }
    end
    return out
end

function Dispatch.IsAllowed(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    if type(Config) == "table" and type(Config.AllowedJobs) == "table" then
        if Config.AllowedJobs[xPlayer.job.name] then return true end
    end
    local job = VFW.Jobs and VFW.Jobs[xPlayer.job.name]
    return job ~= nil and job.type == "police"
end

function Dispatch.Recipients()
    local jobs = Dispatch.AllowedJobs()
    local out = {}
    local players = VFW.GetPlayers()

    for i = 1, #players do
        local xPlayer = VFW.GetPlayerFromId(players[i])
        if xPlayer and xPlayer.job then
            for j = 1, #jobs do
                if xPlayer.job.name == jobs[j] then
                    out[#out + 1] = players[i]
                    break
                end
            end
        end
    end

    return out
end

function Dispatch.Broadcast(eventName, ...)
    local targets = Dispatch.Recipients()
    for i = 1, #targets do
        TriggerClientEvent(eventName, targets[i], ...)
    end
end

function Dispatch.LoadUnits()
    local rows = JC.Query("SELECT identifier, unit_number, job, in_service, icon_type, group_code FROM dispatch_units")
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        if type(row.identifier) == "string" then
            out[row.identifier] = {
                identifier = row.identifier,
                unitNumber = row.unit_number or "",
                job = row.job or "",
                inService = false,
                iconType = row.icon_type or "",
                groupCode = row.group_code or "N/A",
            }
        end
    end

    units = out
    return units
end

function Dispatch.Unit(identifier)
    if type(identifier) ~= "string" then return nil end
    return units[identifier]
end

function Dispatch.EnsureUnit(xPlayer)
    if not xPlayer then return nil end
    local unit = units[xPlayer.identifier]
    if not unit then
        unit = {
            identifier = xPlayer.identifier,
            unitNumber = "",
            job = xPlayer.job and xPlayer.job.name or "",
            inService = false,
            iconType = "",
            groupCode = "N/A",
        }
        units[xPlayer.identifier] = unit
    end
    return unit
end

function Dispatch.SaveUnit(unit)
    if not unit then return end
    JC.Exec([[
        INSERT INTO dispatch_units (identifier, unit_number, job, in_service, icon_type, group_code)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE unit_number = VALUES(unit_number), job = VALUES(job),
            in_service = VALUES(in_service), icon_type = VALUES(icon_type), group_code = VALUES(group_code)
    ]], {
        unit.identifier,
        unit.unitNumber or "",
        unit.job or "",
        unit.inService and 1 or 0,
        unit.iconType or "",
        unit.groupCode or "N/A",
    })
end

function Dispatch.UnitList()
    local out = {}
    local players = VFW.GetPlayers()

    for i = 1, #players do
        local src = players[i]
        local xPlayer = VFW.GetPlayerFromId(src)
        if xPlayer and Dispatch.IsAllowed(xPlayer) then
            local unit = units[xPlayer.identifier]
            if unit and unit.inService then
                out[#out + 1] = {
                    id = src,
                    unitId = src,
                    serverId = src,
                    identifier = xPlayer.identifier,
                    unitNumber = unit.unitNumber or "",
                    matricule = unit.unitNumber or "",
                    name = JC.PlayerName(xPlayer),
                    job = xPlayer.job.name,
                    jobLabel = (type(Config) == "table" and type(Config.JobLabels) == "table"
                        and Config.JobLabels[xPlayer.job.name]) or xPlayer.job.label or xPlayer.job.name,
                    grade = xPlayer.job.grade_label or xPlayer.job.grade_name or "",
                    iconType = unit.iconType or "",
                    groupCode = unit.groupCode or "N/A",
                    inService = true,
                }
            end
        end
    end

    table.sort(out, function(a, b) return tostring(a.unitNumber) < tostring(b.unitNumber) end)
    return out
end

function Dispatch.PushUnits()
    local list = Dispatch.UnitList()
    Dispatch.Broadcast("dispatch:client:setUnits", list)
    return list
end

function Dispatch.LoadCalls()
    local rows = JC.Query([[
        SELECT id, type, category, level, job_name, unit_number, street, title, message,
               coords, style, blip_sprite, blip_color, blip_use_big, blip_big_sprite, blip_big_color, created_at
        FROM dispatch_calls ORDER BY id DESC LIMIT ?
    ]], { Dispatch.MaxCalls })

    local out = {}
    local maxId = 0

    for i = 1, #rows do
        local row = rows[i]
        local id = tonumber(row.id) or 0
        if id > maxId then maxId = id end

        out[id] = {
            id = id,
            alertId = id,
            type = row.type,
            category = row.category,
            level = JC.Int(row.level, 1, 3) or 1,
            code = JC.Int(row.level, 1, 3) or 1,
            icon = "fa-bell",
            jobName = row.job_name or "",
            unitNumber = row.unit_number or "",
            street = row.street or "",
            title = row.title or "",
            message = row.message or "",
            coords = JC.Decode(row.coords, { x = 0.0, y = 0.0, z = 0.0 }),
            style = JC.Decode(row.style, {}),
            blipSprite = JC.Int(row.blip_sprite) or 161,
            blipColor = JC.Int(row.blip_color) or 3,
            blipUseBig = row.blip_use_big == 1 or row.blip_use_big == true,
            blipBigSprite = JC.Int(row.blip_big_sprite) or 670,
            blipBigColor = JC.Int(row.blip_big_color) or 3,
            createdAt = tostring(row.created_at or ""),
        }
    end

    calls = out
    nextCallId = maxId + 1

    local assignRows = JC.Query("SELECT call_id, matricule, status FROM dispatch_call_assignments")
    local assign = {}
    for i = 1, #assignRows do
        local row = assignRows[i]
        local callId = tonumber(row.call_id)
        if callId and calls[callId] then
            assign[callId] = assign[callId] or {}
            assign[callId][#assign[callId] + 1] = {
                matricule = row.matricule,
                status = row.status or "assigned",
            }
        end
    end
    assignments = assign

    return calls
end

function Dispatch.Calls()
    local out = {}
    for _, call in pairs(calls) do
        out[#out + 1] = call
    end
    table.sort(out, function(a, b) return (a.id or 0) > (b.id or 0) end)
    return out
end

function Dispatch.Call(id)
    local wanted = JC.Int(id)
    if not wanted then return nil end
    return calls[wanted]
end

function Dispatch.Assignments()
    local out = {}
    for callId, list in pairs(assignments) do
        out[tostring(callId)] = list
    end
    return out
end

function Dispatch.CallAssignments(callId)
    return assignments[callId] or {}
end

function Dispatch.SetAssignment(callId, matricule, status)
    local id = JC.Int(callId)
    local unit = JC.Str(matricule, 16)
    if not id or not unit then return false end
    if status ~= "assigned" and status ~= "accepted" and status ~= "rejected" then
        status = "assigned"
    end

    assignments[id] = assignments[id] or {}
    local found = false
    for i = 1, #assignments[id] do
        if assignments[id][i].matricule == unit then
            assignments[id][i].status = status
            found = true
            break
        end
    end
    if not found then
        assignments[id][#assignments[id] + 1] = { matricule = unit, status = status }
    end

    JC.Exec([[
        INSERT INTO dispatch_call_assignments (call_id, matricule, status) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE status = VALUES(status)
    ]], { id, unit, status })

    return true
end

function Dispatch.StoreCall(payload)
    local id = JC.Insert([[
        INSERT INTO dispatch_calls (type, category, level, job_name, unit_number, street, title, message,
            coords, style, blip_sprite, blip_color, blip_use_big, blip_big_sprite, blip_big_color)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.type,
        payload.category,
        payload.level,
        payload.jobName,
        payload.unitNumber,
        payload.street,
        payload.title,
        payload.message,
        JC.Encode(payload.coords),
        JC.Encode(payload.style),
        payload.blipSprite,
        payload.blipColor,
        payload.blipUseBig and 1 or 0,
        payload.blipBigSprite,
        payload.blipBigColor,
    })

    if not id then
        id = nextCallId
        nextCallId = nextCallId + 1
    end

    payload.id = id
    payload.alertId = id
    calls[id] = payload

    local ids = {}
    for callId in pairs(calls) do ids[#ids + 1] = callId end
    if #ids > Dispatch.MaxCalls then
        table.sort(ids)
        for i = 1, #ids - Dispatch.MaxCalls do
            calls[ids[i]] = nil
            assignments[ids[i]] = nil
        end
    end

    return payload
end

function Dispatch.RemoveCall(id)
    local wanted = JC.Int(id)
    if not wanted then return false end

    calls[wanted] = nil
    assignments[wanted] = nil

    JC.Exec("DELETE FROM dispatch_call_assignments WHERE call_id = ?", { wanted })
    JC.Exec("DELETE FROM dispatch_calls WHERE id = ?", { wanted })
    return true
end

function Dispatch.ClearCalls()
    calls = {}
    assignments = {}
    JC.Exec("DELETE FROM dispatch_call_assignments", {})
    JC.Exec("DELETE FROM dispatch_calls", {})
end

function Dispatch.LoadGroups()
    local rows = JC.Query("SELECT job, groups FROM dispatch_groups")
    local out = {}
    for i = 1, #rows do
        out[rows[i].job] = JC.Decode(rows[i].groups, {})
    end
    groups = out
    return groups
end

function Dispatch.Groups(jobName)
    if type(jobName) ~= "string" then return {} end
    return groups[jobName] or {}
end

function Dispatch.SaveGroups(jobName, data)
    if type(jobName) ~= "string" or jobName == "" then return false end
    groups[jobName] = data
    JC.Exec([[
        INSERT INTO dispatch_groups (job, groups) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE groups = VALUES(groups)
    ]], { jobName, JC.Encode(data) or "{}" })
    return true
end

JC.Cb("dispatch:getUnitNumber", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return "" end

    local unit = Dispatch.Unit(xPlayer.identifier)
    return unit and unit.unitNumber or ""
end)

JC.Cb("dispatch:getUnits", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return {} end
    return Dispatch.UnitList()
end)

JC.Cb("dispatch:getNotifications", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then
        return { notifications = {}, assignments = {} }
    end
    return { notifications = Dispatch.Calls(), assignments = Dispatch.Assignments() }
end)

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(2000)
    Dispatch.LoadUnits()
    Dispatch.LoadCalls()
    Dispatch.LoadGroups()
end)
