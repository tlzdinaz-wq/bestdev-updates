MiscB = MiscB or {}

local registered = {}

function MiscB.Cb(name, handler)
    if type(name) ~= "string" or type(handler) ~= "function" then return false end
    if registered[name] then return false end
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[misc_b] callback refuse: %s (%s)"):format(name, tostring(err)))
        return false
    end
    registered[name] = true
    return true
end

function MiscB.Event(name, handler)
    if type(name) ~= "string" or type(handler) ~= "function" then return false end
    RegisterNetEvent(name, handler)
    return true
end

local function safeSql(fn, sql, params, fallback)
    if not fn then return fallback end
    local ok, res = pcall(fn, sql, params)
    if not ok then
        console.warn(("[misc_b] SQL: %s | %s"):format(tostring(res), tostring(sql)))
        return fallback
    end
    if res == nil then return fallback end
    return res
end

function MiscB.Query(sql, params)
    return safeSql(MySQL and MySQL.query and MySQL.query.await, sql, params, {})
end

function MiscB.Single(sql, params)
    return safeSql(MySQL and MySQL.single and MySQL.single.await, sql, params, nil)
end

function MiscB.Scalar(sql, params, fallback)
    local v = safeSql(MySQL and MySQL.scalar and MySQL.scalar.await, sql, params, fallback)
    if v == nil then return fallback end
    return v
end

function MiscB.Insert(sql, params)
    return safeSql(MySQL and MySQL.insert and MySQL.insert.await, sql, params, nil)
end

function MiscB.Update(sql, params)
    return safeSql(MySQL and MySQL.update and MySQL.update.await, sql, params, 0)
end

function MiscB.IsNumber(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function MiscB.ToInt(v, min, max)
    local n = tonumber(v)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    n = math.floor(n)
    if min and n < min then return nil end
    if max and n > max then return nil end
    return n
end

function MiscB.ToNum(v, fallback)
    local n = tonumber(v)
    if not n or n ~= n or n == math.huge or n == -math.huge then return fallback end
    return n + 0.0
end

function MiscB.Str(v, maxLen)
    if type(v) ~= "string" then return nil end
    local s = v
    if maxLen and #s > maxLen then s = s:sub(1, maxLen) end
    return s
end

function MiscB.Bool(v)
    return v == true or v == 1 or v == "true"
end

function MiscB.Table(v)
    if type(v) ~= "table" then return nil end
    return v
end

function MiscB.Vec3(v, fallback)
    if type(v) == "vector3" then return v end
    if type(v) == "vector4" then return vector3(v.x, v.y, v.z) end
    if type(v) == "table" and v.x and v.y and v.z then
        return vector3(MiscB.ToNum(v.x, 0.0), MiscB.ToNum(v.y, 0.0), MiscB.ToNum(v.z, 0.0))
    end
    if type(v) == "table" and v[1] and v[2] and v[3] then
        return vector3(MiscB.ToNum(v[1], 0.0), MiscB.ToNum(v[2], 0.0), MiscB.ToNum(v[3], 0.0))
    end
    return fallback
end

function MiscB.Plain(v, fallback)
    local c = MiscB.Vec3(v)
    if not c then return fallback end
    return { x = c.x, y = c.y, z = c.z }
end

function MiscB.PlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function MiscB.Dist(a, b)
    local va, vb = MiscB.Vec3(a), MiscB.Vec3(b)
    if not va or not vb then return 999999.0 end
    return #(va - vb)
end

function MiscB.Uuid()
    if VFW and VFW.GenerateUUID then
        local ok, id = pcall(VFW.GenerateUUID)
        if ok and id then return tostring(id) end
    end
    return ("%d%d%d"):format(os.time(), GetGameTimer(), math.random(100000, 999999))
end

local buckets = {}

function MiscB.Rate(source, key, delay)
    local src = tonumber(source) or 0
    local b = buckets[src]
    if not b then
        b = {}
        buckets[src] = b
    end
    local now = GetGameTimer()
    if b[key] and (now - b[key]) < (delay or 250) then return false end
    b[key] = now
    return true
end

AddEventHandler("vfw:playerDropped", function(source)
    buckets[tonumber(source) or 0] = nil
end)

function MiscB.Player(source)
    if not VFW or not VFW.GetPlayerFromId then return nil end
    return VFW.GetPlayerFromId(source)
end

function MiscB.Notify(source, content, ntype)
    if not VFW or not VFW.ShowNotification then return end
    VFW.ShowNotification(source, { type = ntype or "ROUGE", content = tostring(content or "") })
end

function MiscB.JobName(xPlayer)
    if not xPlayer or type(xPlayer.job) ~= "table" then return nil end
    return xPlayer.job.name
end

function MiscB.FactionName(xPlayer)
    if not xPlayer then return nil end
    if type(xPlayer.faction) == "table" then return xPlayer.faction.name end
    if type(xPlayer.faction) == "string" then return xPlayer.faction end
    return nil
end

function MiscB.HasJob(xPlayer, names)
    local job = MiscB.JobName(xPlayer)
    if not job then return false end
    if type(names) == "string" then return job == names end
    if type(names) ~= "table" then return false end
    for i = 1, #names do
        if names[i] == job then return true end
    end
    return false
end

function MiscB.IsPolice(xPlayer)
    if not xPlayer then return false end
    local job = MiscB.JobName(xPlayer)
    if not job then return false end
    if type(PoliceJobsList) == "table" and PoliceJobsList[job] then return true end
    local jobType = type(xPlayer.job) == "table" and xPlayer.job.type or nil
    if jobType == "police" then return true end
    return job == "police" or job == "usss"
end

function MiscB.IsLawEnforcement(xPlayer)
    if not xPlayer then return false end
    local job = MiscB.JobName(xPlayer)
    if not job then return false end
    if type(LawEnforcementJobsList) == "table" and LawEnforcementJobsList[job] then return true end
    local jobType = type(xPlayer.job) == "table" and xPlayer.job.type or nil
    if jobType == "police" or jobType == "milice" then return true end
    return MiscB.IsPolice(xPlayer)
end

function MiscB.GradeLevel(xPlayer)
    if not xPlayer or type(xPlayer.job) ~= "table" then return 0 end
    return tonumber(xPlayer.job.grade) or 0
end

function MiscB.IsBoss(xPlayer)
    if not xPlayer or type(xPlayer.job) ~= "table" then return false end
    if xPlayer.job.grade_is_boss then return true end
    return MiscB.GradeLevel(xPlayer) >= 98
end

function MiscB.OnDuty(xPlayer)
    if not xPlayer or type(xPlayer.job) ~= "table" then return false end
    return xPlayer.job.onDuty ~= false
end

function MiscB.CharName(xPlayer)
    if not xPlayer then return "Inconnu" end
    local first = xPlayer.firstName or ""
    local last = xPlayer.lastName or ""
    local full = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
    if full == "" then return xPlayer.name or "Inconnu" end
    return full
end

function MiscB.Broadcast(event, ...)
    TriggerClientEvent(event, -1, ...)
end

function MiscB.ToPlayers(list, event, ...)
    if type(list) ~= "table" then return end
    for i = 1, #list do
        local target = list[i]
        local src = type(target) == "table" and target.source or target
        if src then TriggerClientEvent(event, src, ...) end
    end
end

function MiscB.PlayersWithJobs(jobs)
    if VFW and VFW.GetPlayersWithJobs then
        local ok, res = pcall(VFW.GetPlayersWithJobs, jobs)
        if ok and type(res) == "table" then return res end
    end
    return {}
end

function MiscB.NearbyPlayers(source, radius)
    local coords = MiscB.PlayerCoords(source)
    if not coords then return {} end
    if VFW and VFW.GetPlayersInRadius then
        local ok, res = pcall(VFW.GetPlayersInRadius, coords, radius or 25.0)
        if ok and type(res) == "table" then return res end
    end
    return {}
end

MiscB.Ready = true
