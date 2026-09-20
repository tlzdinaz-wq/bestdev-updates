VFW.JobsCommon = VFW.JobsCommon or {}

local JC = VFW.JobsCommon

local reported = {}

local function report(scope, query, err)
    local key = scope .. "|" .. tostring(query)
    if reported[key] then return end
    reported[key] = true
    console.error(("[Jobs] SQL (%s): %s"):format(scope, tostring(err)))
end

function JC.Query(query, params)
    local ok, res = pcall(MySQL.query.await, query, params)
    if not ok then
        report("query", query, res)
        return {}
    end
    return res or {}
end

function JC.Single(query, params)
    local ok, res = pcall(MySQL.single.await, query, params)
    if not ok then
        report("single", query, res)
        return nil
    end
    return res
end

function JC.Scalar(query, params, fallback)
    local ok, res = pcall(MySQL.scalar.await, query, params)
    if not ok then
        report("scalar", query, res)
        return fallback
    end
    if res == nil then return fallback end
    return res
end

function JC.Insert(query, params)
    local ok, res = pcall(MySQL.insert.await, query, params)
    if not ok then
        report("insert", query, res)
        return nil
    end
    return res
end

function JC.Exec(query, params)
    local ok, res = pcall(MySQL.update.await, query, params)
    if not ok then
        report("exec", query, res)
        return 0
    end
    return res or 0
end

function JC.Cb(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[Jobs] Callback '%s' deja enregistre ailleurs: %s"):format(name, tostring(err)))
        return false
    end
    return true
end

function JC.Str(value, maxLength)
    if type(value) ~= "string" then return nil end
    local clean = value:gsub("%z", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then return nil end
    if maxLength and #clean > maxLength then clean = clean:sub(1, maxLength) end
    return clean
end

function JC.Int(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    n = math.floor(n)
    if min and n < min then return nil end
    if max and n > max then return nil end
    return n
end

function JC.Num(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    if min and n < min then return nil end
    if max and n > max then return nil end
    return n + 0.0
end

function JC.Bool(value)
    return value == true or value == 1 or value == "1"
end

function JC.Vec(value)
    local kind = type(value)
    if kind ~= "table" and kind ~= "vector3" and kind ~= "vector4" then return nil end
    local x = JC.Num(value.x)
    local y = JC.Num(value.y)
    local z = JC.Num(value.z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

function JC.Vec4(value)
    local v = JC.Vec(value)
    if not v then return nil end
    if type(value) == "vector4" then
        v.h = JC.Num(value.w) or 0.0
        return v
    end
    if type(value) == "table" then
        v.h = JC.Num(value.h) or JC.Num(value.heading) or 0.0
        return v
    end
    v.h = 0.0
    return v
end

function JC.Encode(value)
    local ok, res = pcall(json.encode, value)
    if not ok then return nil end
    return res
end

function JC.Decode(value, fallback)
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return fallback end
    local ok, res = pcall(json.decode, value)
    if not ok or type(res) ~= "table" then return fallback end
    return res
end

function JC.Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = JC.Copy(v)
    end
    return out
end

local function inv()
    return VFW.Inventory
end

function JC.Count(xPlayer, name)
    if not xPlayer or type(name) ~= "string" then return 0 end
    local I = inv()
    if I and I.CountByName and I.PlayerList then
        return I.CountByName(I.PlayerList(xPlayer), name) or 0
    end
    local item = xPlayer.getInventoryItem(name)
    return item and item.count or 0
end

function JC.CanCarry(xPlayer, name, count)
    if not xPlayer or type(name) ~= "string" then return false end
    count = JC.Int(count, 1) or 1
    local I = inv()
    if I and I.MaxCarryable then
        return (I.MaxCarryable(xPlayer, name, count) or 0) >= count
    end
    return xPlayer.canCarryItem(name, count)
end

function JC.Sync(xPlayer)
    local I = inv()
    if I and I.PushPlayer then I.PushPlayer(xPlayer) end
end

function JC.Add(xPlayer, name, count, meta)
    if not xPlayer or type(name) ~= "string" then return false end
    count = JC.Int(count, 1) or 1

    local I = inv()
    if I and I.AddToList and I.PlayerList then
        if not I.Exists(name) then
            console.warn(("[Jobs] item inconnu a l'ajout: %s"):format(name))
            return false
        end
        if (I.MaxCarryable(xPlayer, name, count) or 0) < count then return false end
        local list = I.PlayerList(xPlayer)
        local added = I.AddToList(list, name, count, meta, I.PlayerMaxSlots)
        if not added or added <= 0 then return false end
        I.PushPlayer(xPlayer)
        TriggerEvent("vfw:inventory:added", xPlayer.source, name, added)
        return true
    end

    return xPlayer.addInventoryItem(name, count, meta) == true
end

function JC.Remove(xPlayer, name, count)
    if not xPlayer or type(name) ~= "string" then return false end
    count = JC.Int(count, 1) or 1

    local I = inv()
    if I and I.RemoveByName and I.PlayerList then
        local list = I.PlayerList(xPlayer)
        if (I.CountByName(list, name) or 0) < count then return false end
        local removed = I.RemoveByName(list, name, count)
        if not removed or removed < count then return false end
        I.PushPlayer(xPlayer)
        TriggerEvent("vfw:inventory:removed", xPlayer.source, name, removed)
        return true
    end

    return xPlayer.removeInventoryItem(name, count) == true
end

function JC.RemoveSlot(xPlayer, slot, name)
    if not xPlayer then return false end
    local wanted = JC.Int(slot)
    local I = inv()
    if not I or not I.PlayerList or not wanted then
        if name then return JC.Remove(xPlayer, name, 1) end
        return false
    end

    local list = I.PlayerList(xPlayer)
    local entry = I.FindSlot(list, wanted)
    if not entry or (name and entry.name ~= name) then
        if name then return JC.Remove(xPlayer, name, 1) end
        return false
    end

    local taken = I.RemoveFromSlot(list, wanted, 1)
    if not taken then return false end
    I.PushPlayer(xPlayer)
    TriggerEvent("vfw:inventory:removed", xPlayer.source, entry.name, 1)
    return true
end

function JC.ItemLabel(name)
    local def = VFW.Items and VFW.Items[name]
    if def and type(def.label) == "string" and def.label ~= "" then return def.label end
    return name
end

function JC.Notify(source, content, isError, title, subtitle)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.showNotification({
        type = isError and "ROUGE" or "JOB",
        title = title or (xPlayer.job and xPlayer.job.label) or "Information",
        subtitle = subtitle or "Information",
        content = content,
    })
end

function JC.PlayerName(xPlayer)
    if not xPlayer then return "Inconnu" end
    local first = xPlayer.firstName
    local last = xPlayer.lastName
    if type(first) == "string" and first ~= "" then
        if type(last) == "string" and last ~= "" then
            return first .. " " .. last
        end
        return first
    end
    if type(xPlayer.name) == "string" and xPlayer.name ~= "" then return xPlayer.name end
    return xPlayer.playerName or "Inconnu"
end

function JC.IsBoss(xPlayer, jobName)
    if not xPlayer or not xPlayer.job then return false end
    if jobName and xPlayer.job.name ~= jobName then return false end
    if xPlayer.job.grade_is_boss == true or xPlayer.job.grade_is_boss == 1 then return true end
    local grade = tonumber(xPlayer.job.grade) or 0
    return grade >= 98
end

function JC.IsStaff(xPlayer, permission)
    if not xPlayer then return false end
    if permission and xPlayer.hasPermission(permission) then return true end
    return xPlayer.hasPermission("staff_menu")
        or xPlayer.hasPermission("manage_jobs")
        or xPlayer.hasPermission("builder")
        or xPlayer.hasPermission("builder_menu")
end

function JC.HasJob(xPlayer, jobName, requireDuty)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.name ~= jobName then return false end
    if requireDuty and xPlayer.job.onDuty ~= true then return false end
    return true
end

function JC.Coords(source)
    local ok, ped = pcall(GetPlayerPed, source)
    if not ok or not ped or ped == 0 then return nil end
    local ok2, coords = pcall(GetEntityCoords, ped)
    if not ok2 or not coords then return nil end
    return coords
end

function JC.Dist(source, point)
    local coords = JC.Coords(source)
    if not coords or not point then return math.huge end
    local px = tonumber(point.x)
    local py = tonumber(point.y)
    local pz = tonumber(point.z)
    if not px or not py or not pz then return math.huge end
    local dx = coords.x - px
    local dy = coords.y - py
    local dz = coords.z - pz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function JC.DistPlayers(a, b)
    local ca = JC.Coords(a)
    local cb = JC.Coords(b)
    if not ca or not cb then return math.huge end
    local dx = ca.x - cb.x
    local dy = ca.y - cb.y
    local dz = ca.z - cb.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function JC.NearAny(source, points, radius)
    if type(points) ~= "table" then return false end
    radius = radius or 4.0
    for i = 1, #points do
        if JC.Dist(source, points[i]) <= radius then return true, i end
    end
    for _, point in pairs(points) do
        if type(point) == "table" and JC.Dist(source, point) <= radius then return true end
    end
    return false
end

local throttles = {}

function JC.Throttle(source, key, delay)
    local bucket = throttles[source]
    if not bucket then
        bucket = {}
        throttles[source] = bucket
    end
    local now = GetGameTimer()
    local last = bucket[key]
    if last and (now - last) < (delay or 1000) then return false end
    bucket[key] = now
    return true
end

AddEventHandler("playerDropped", function()
    local source = source
    throttles[source] = nil
end)

function JC.AddSocietyMoney(jobName, amount, reason)
    local value = JC.Int(amount, 1)
    if not value or type(jobName) ~= "string" or jobName == "" then return false end

    if Staff29 and Staff29.Boss and Staff29.Boss.AddSocietyMoney then
        Staff29.Boss.AddSocietyMoney(jobName, value)
        if VFW.Logs and VFW.Logs.Simple then
            VFW.Logs.Simple("society", "Compte societe", ("%s +%d$ (%s)"):format(jobName, value, reason or "job"))
        end
        return true
    end

    JC.Exec([[
        INSERT INTO society_accounts (job_name, money) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE money = money + VALUES(money)
    ]], { jobName, value })

    if VFW.Logs and VFW.Logs.Simple then
        VFW.Logs.Simple("society", "Compte societe", ("%s +%d$ (%s)"):format(jobName, value, reason or "job"))
    end
    return true
end

function JC.GetSocietyMoney(jobName)
    if type(jobName) ~= "string" or jobName == "" then return 0 end
    return tonumber(JC.Scalar("SELECT money FROM society_accounts WHERE job_name = ?", { jobName }, 0)) or 0
end

function JC.RemoveSocietyMoney(jobName, amount)
    local value = JC.Int(amount, 1)
    if not value or type(jobName) ~= "string" or jobName == "" then return false end
    local balance = JC.GetSocietyMoney(jobName)
    if balance < value then return false end
    if Staff29 and Staff29.Boss and Staff29.Boss.SetSocietyMoney then
        Staff29.Boss.SetSocietyMoney(jobName, balance - value)
        return true
    end
    JC.Exec([[
        INSERT INTO society_accounts (job_name, money) VALUES (?, 0)
        ON DUPLICATE KEY UPDATE money = money - ?
    ]], { jobName, value })
    return true
end

function JC.SocietyInfo(jobName)
    local label = jobName or ""
    local image = ""

    if VFW.Society then
        if VFW.Society.GetLabel then label = VFW.Society.GetLabel(jobName) or label end
        if VFW.Society.GetImage then image = VFW.Society.GetImage(jobName) or "" end
    end

    if (label == "" or label == jobName) and VFW.Jobs and VFW.Jobs[jobName] then
        label = VFW.Jobs[jobName].label or label
    end

    return {
        image = image,
        label = label ~= "" and label or (jobName or "Information"),
        jobLabel = label ~= "" and label or (jobName or "Information"),
    }
end

local pendingJobs = {}

function JC.EnsureJob(name, label, jobType, grades)
    if type(name) ~= "string" or name == "" then return end
    pendingJobs[#pendingJobs + 1] = {
        name = name,
        label = label or name,
        type = jobType or "job",
        grades = grades,
    }
end

local DEFAULT_GRADES = {
    { grade = 0, name = "employe", label = "Employe", salary = 250, is_boss = 0 },
    { grade = 1, name = "confirme", label = "Confirme", salary = 400, is_boss = 0 },
    { grade = 2, name = "responsable", label = "Responsable", salary = 600, is_boss = 0 },
    { grade = 3, name = "boss", label = "Patron", salary = 900, is_boss = 1 },
}

JC.DefaultGrades = DEFAULT_GRADES

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(1500)

    local created = 0
    for i = 1, #pendingJobs do
        local job = pendingJobs[i]
        if not VFW.Jobs[job.name] then
            JC.Exec("INSERT IGNORE INTO jobs (name, label, type, whitelisted) VALUES (?, ?, ?, 1)",
                { job.name, job.label, job.type })

            local grades = job.grades or DEFAULT_GRADES
            for g = 1, #grades do
                local grade = grades[g]
                JC.Exec([[
                    INSERT IGNORE INTO job_grades (job_name, grade, name, label, salary, is_boss)
                    VALUES (?, ?, ?, ?, ?, ?)
                ]], { job.name, grade.grade, grade.name, grade.label, grade.salary, grade.is_boss })
            end
            created = created + 1
        end
    end

    if created > 0 then
        if VFW.DB and VFW.DB.LoadJobs then VFW.DB.LoadJobs() end
        if VFW.Society and VFW.Society.RefreshJobs then VFW.Society.RefreshJobs() end
        console.info(("[Jobs] %d metier(s) manquant(s) cree(s) en base."):format(created))
    end

    JC.JobsSeeded = true
end)

console.init("Jobs", "Helpers communs charges.")
