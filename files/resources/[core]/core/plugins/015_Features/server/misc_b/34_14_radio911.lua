Radio911 = Radio911 or {}

local allowed = {}
local loaded = false

local function ensureTable()
    MiscB.Query([[
        CREATE TABLE IF NOT EXISTS radio911_jobs (
            job VARCHAR(64) NOT NULL,
            PRIMARY KEY (job)
        )
    ]], {})
end

local function loadAllowed()
    ensureTable()
    allowed = {}
    local rows = MiscB.Query("SELECT job FROM radio911_jobs ORDER BY job ASC", {})
    for i = 1, #rows do
        local name = tostring(rows[i].job or "")
        if name ~= "" then allowed[name] = true end
    end
    loaded = true
end

local function namesList()
    if not loaded then loadAllowed() end
    local list = {}
    for name in pairs(allowed) do
        list[#list + 1] = name
    end
    table.sort(list)
    return list
end

local function jobLabel(name)
    local jobs = VFW.Jobs or {}
    local def = jobs[name]
    if type(def) == "table" then return def.label or name end
    return name
end

local function catalog()
    local jobs = VFW.Jobs or {}
    local out = {}
    for name, def in pairs(jobs) do
        if type(name) == "string" and name ~= "" and not allowed[name] then
            out[#out + 1] = {
                name = name,
                label = (type(def) == "table" and def.label) or name,
            }
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function allowedRows()
    local list = namesList()
    local rows = {}
    for i = 1, #list do
        rows[#rows + 1] = { name = list[i], label = jobLabel(list[i]) }
    end
    return rows
end

local function payload()
    return {
        ok = true,
        allowed = allowedRows(),
        catalog = catalog(),
    }
end

local function cleanJob(raw)
    local name = tostring(raw or ""):lower():gsub("%s+", "")
    if name == "" or #name > 64 or not name:match("^[%w_%-]+$") then return nil end
    return name
end

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("builder_radio911")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

function Radio911.IsEmergencyFreq(freq)
    local n = tonumber(freq)
    if not n then return false end
    return math.floor(n + 0.0) == 911
end

function Radio911.CanJoin(xPlayer, freq, radioType)
    if not Radio911.IsEmergencyFreq(freq) then return true end
    if not loaded then loadAllowed() end
    if next(allowed) == nil then return true end
    if xPlayer and (xPlayer.hasPermission("staff") or xPlayer.hasPermission("admin") or xPlayer.hasPermission("builder_radio911")) then
        return true
    end
    if radioType ~= "job" then
        return false, "La fréquence 911 est réservée à la radio service."
    end
    local job = MiscB.JobName(xPlayer)
    if job and allowed[job] then return true end
    return false, "Ton job n'est pas autorisé sur la radio 911."
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(1500)
    loadAllowed()
end)

MiscB.Cb("radio911:getAllowedJobs", function(source)
    if not staffOk(source) then return {} end
    return namesList()
end)

MiscB.Cb("radio911:addJob", function(source, jobName)
    if not staffOk(source) then return false end
    local name = cleanJob(jobName)
    if not name then return false end
    if not loaded then loadAllowed() end
    if allowed[name] then return false end
    MiscB.Insert("INSERT INTO radio911_jobs (job) VALUES (?)", { name })
    allowed[name] = true
    return true
end)

MiscB.Cb("radio911:removeJob", function(source, jobName)
    if not staffOk(source) then return false end
    local name = cleanJob(jobName)
    if not name then return false end
    if not loaded then loadAllowed() end
    if not allowed[name] then return false end
    MiscB.Update("DELETE FROM radio911_jobs WHERE job = ?", { name })
    allowed[name] = nil
    return true
end)

MiscB.Cb("radio911:getPanel", function(source)
    if not staffOk(source) then return { ok = false } end
    if not loaded then loadAllowed() end
    return payload()
end)
