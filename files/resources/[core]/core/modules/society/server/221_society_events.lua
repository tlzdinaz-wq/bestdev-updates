local STAFF_PERMISSION = "manage_jobs"

local function getStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission(STAFF_PERMISSION) then return nil end
    return xPlayer
end

local function cleanString(value, maxLength, fallback)
    if type(value) ~= "string" then return fallback end
    local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return fallback end
    return trimmed:sub(1, maxLength or 255)
end

local function cleanNumber(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

local function sanitizeVector(value)
    if type(value) ~= "table" then return {} end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return {} end
    return { x = x, y = y, z = z }
end

local function sanitizeBlip(value, fallbackName)
    if type(value) ~= "table" then value = {} end

    return {
        enabled = value.enabled and true or false,
        position = sanitizeVector(value.position),
        name = cleanString(value.name, 100, fallbackName or ""),
        sprite = math.floor(cleanNumber(value.sprite, 1)),
        color = math.floor(cleanNumber(value.color, 0)),
        scale = cleanNumber(value.scale, 0.5),
    }
end

local function sanitizeCustom(value)
    if type(value) ~= "table" then return {} end

    local out = {}
    for k, v in pairs(value) do
        if type(k) == "string" and k ~= "crafts" then
            local t = type(v)
            if t == "string" or t == "number" or t == "boolean" or t == "table" then
                out[k] = v
            end
        end
    end
    return out
end

local function jobNameIsValid(name)
    return type(name) == "string" and name ~= "" and name:match("^[%w_%-]+$") ~= nil and #name <= 60
end

local function rejectName(xPlayer)
    xPlayer.showNotification({
        type = "STAFF", variant = "ERROR", subtitle = "Builder",
        message = "Ce nom de métier n'est pas valide (lettres, chiffres, _ et - uniquement).",
    })
end

RegisterNetEvent("core:society:requestData", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    VFW.Society.SendData(source, xPlayer.job and xPlayer.job.name or "unemployed")
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    local target = source

    SetTimeout(2000, function()
        local player = VFW.GetPlayerFromId(target)
        if not player then return end
        VFW.Society.SendData(target, player.job and player.job.name or "unemployed")
    end)
end)

AddEventHandler("vfw:setJob", function(source, job)
    if not job then return end
    TriggerClientEvent("vfw:setJob", source, job)
    VFW.Society.SendData(source, job.name)
end)

AddEventHandler("vfw:setDuty", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    TriggerClientEvent("vfw:setJob", source, xPlayer.job)
end)

RegisterNetEvent("core:create:society", function(name, data)
    local source = source
    local xPlayer = getStaff(source)
    if not xPlayer then return end

    if not jobNameIsValid(name) then
        rejectName(xPlayer)
        return
    end
    if type(data) ~= "table" then return end

    if VFW.Society.Get(name) or VFW.Jobs[name] then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Builder",
            message = "Ce métier existe déjà.",
        })
        return
    end

    local label = cleanString(data.label, 120, name)
    local societyType = cleanString(data.type, 60, "job")
    local image = cleanString(data.image, 255, "")
    local banner = cleanString(data.banner, 255, "")
    local address = cleanString(data.address, 120, "")
    local blip = sanitizeBlip(data.blip, label)
    local management = sanitizeVector(data.management)
    local custom = sanitizeCustom(data.custom)

    VFW.Society.Update([[
        INSERT INTO jobs (name, label, type, whitelisted) VALUES (?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type)
    ]], { name, label, societyType })

    VFW.Society.Update([[
        INSERT INTO societies (name, label, type, image, banner, address, blip, management, storage, custom)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type), image = VALUES(image),
            banner = VALUES(banner), address = VALUES(address), blip = VALUES(blip),
            management = VALUES(management), custom = VALUES(custom)
    ]], {
        name, label, societyType, image, banner, address,
        VFW.DB.Encode(blip), VFW.DB.Encode(management), VFW.DB.Encode({}), VFW.DB.Encode(custom),
    })

    local grades = type(data.grades) == "table" and data.grades or {}
    local used = {}
    local normalized = {}

    for _, grade in pairs(grades) do
        if type(grade) == "table" and type(grade.name) == "string" then
            local number = tonumber(grade.grade)
            if not number then
                number = 0
                while used[number] do number = number + 1 end
            end
            number = math.floor(number)
            if not used[number] then
                used[number] = true
                normalized[#normalized + 1] = {
                    grade = number,
                    name = cleanString(grade.name, 60, "grade"),
                    label = cleanString(grade.label, 80, grade.name),
                    salary = math.floor(cleanNumber(grade.salary, 0)),
                    is_boss = (grade.is_boss == true or grade.is_boss == 1),
                }
            end
        end
    end

    if #normalized == 0 then
        normalized[1] = { grade = 0, name = "novice", label = "Novice", salary = 0, is_boss = false }
    end

    VFW.Society.SaveGrades(name, normalized)
    VFW.Society.RefreshJobs()
    VFW.Society.Reload(name)
    VFW.Society.BroadcastToJob(name)

    if custom.catalog then
        TriggerClientEvent("vfw:dynasty:catalogUpdated", -1)
    end
    if societyType == "concess" and VFW.Concess and VFW.Concess.Ensure then
        VFW.Concess.Ensure(name)
    end

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Builder",
        message = ("Métier %s créé."):format(label),
    })

    console.info(("[Society] %s a créé le métier %s"):format(xPlayer.name or source, name))
end)

RegisterNetEvent("core:modify:society", function(name, data)
    local source = source
    local xPlayer = getStaff(source)
    if not xPlayer then return end

    if not jobNameIsValid(name) then return end
    if type(data) ~= "table" then return end

    local previous = VFW.Society.Get(name)
    local label = cleanString(data.label, 120, previous and previous.label or name)
    local societyType = cleanString(data.type, 60, previous and previous.type or "job")
    local image = cleanString(data.image, 255, "")
    local banner = cleanString(data.banner, 255, "")
    local address = cleanString(data.address, 120, "")
    local blip = sanitizeBlip(data.blip, label)
    local management = sanitizeVector(data.management)
    local custom = sanitizeCustom(data.custom)

    local previousCatalog = previous and previous.custom and previous.custom.catalog or nil

    VFW.Society.Update([[
        INSERT INTO jobs (name, label, type, whitelisted) VALUES (?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type)
    ]], { name, label, societyType })

    VFW.Society.Update([[
        INSERT INTO societies (name, label, type, image, banner, address, blip, management, custom)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type), image = VALUES(image),
            banner = VALUES(banner), address = VALUES(address), blip = VALUES(blip),
            management = VALUES(management), custom = VALUES(custom)
    ]], {
        name, label, societyType, image, banner, address,
        VFW.DB.Encode(blip), VFW.DB.Encode(management), VFW.DB.Encode(custom),
    })

    VFW.Society.RefreshJobs()
    VFW.Society.Reload(name)
    VFW.Society.BroadcastToJob(name)

    if VFW.DB.Encode(previousCatalog or {}) ~= VFW.DB.Encode(custom.catalog or {}) then
        TriggerClientEvent("vfw:dynasty:catalogUpdated", -1)
    end
    if societyType == "concess" and VFW.Concess and VFW.Concess.Ensure then
        VFW.Concess.Ensure(name)
    end

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Builder",
        message = ("Métier %s modifié."):format(label),
    })
end)

RegisterNetEvent("core:delete:society", function(name)
    local source = source
    local xPlayer = getStaff(source)
    if not xPlayer then return end
    if not jobNameIsValid(name) then return end
    if name == "unemployed" then return end

    VFW.Society.Update("DELETE FROM societies WHERE name = ?", { name })
    VFW.Society.Update("DELETE FROM job_grades WHERE job_name = ?", { name })
    VFW.Society.Update("DELETE FROM society_doorbells WHERE job_name = ?", { name })
    VFW.Society.Update("DELETE FROM jobs WHERE name = ?", { name })
    VFW.Society.Update("UPDATE characters SET job = 'unemployed', job_grade = 0, job_duty = 0 WHERE job = ?", { name })

    VFW.Society.Remove(name)
    VFW.Society.LoadDoorbells()
    VFW.Society.RefreshJobs()

    for src, other in pairs(VFW.Players) do
        if other.job and other.job.name == name then
            other.setJob("unemployed", 0, false)
            VFW.Society.SendData(src, "unemployed")
        end
    end

    TriggerClientEvent("society:doorbell:refresh", -1)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Builder",
        message = ("Métier %s supprimé."):format(name),
    })

    console.info(("[Society] %s a supprimé le métier %s"):format(xPlayer.name or source, name))
end)

RegisterNetEvent("core:add:society:grade", function(jobName, grade)
    local source = source
    local xPlayer = getStaff(source)
    if not xPlayer then return end
    if not jobNameIsValid(jobName) then return end
    if type(grade) ~= "table" or type(grade.name) ~= "string" then return end

    local number = tonumber(grade.grade)
    if not number then
        number = VFW.Society.NextFreeGrade(jobName)
    end
    number = math.floor(number)
    if number < 0 or number > 99 then return end

    VFW.Society.SaveGrades(jobName, { {
        grade = number,
        name = cleanString(grade.name, 60, "grade"),
        label = cleanString(grade.label, 80, grade.name),
        salary = math.floor(cleanNumber(grade.salary, 0)),
        is_boss = (grade.is_boss == true or grade.is_boss == 1),
    } })

    VFW.Society.RefreshJobs()
    VFW.Society.BroadcastToJob(jobName)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Builder",
        message = ("Grade #%d ajouté."):format(number),
    })
end)

RegisterNetEvent("core:modify:society:grade", function(jobName, grade)
    local source = source
    local xPlayer = getStaff(source)
    if not xPlayer then return end
    if not jobNameIsValid(jobName) then return end
    if type(grade) ~= "table" or type(grade.name) ~= "string" then return end

    local number = tonumber(grade.grade)
    if not number then return end
    number = math.floor(number)
    if number < 0 or number > 99 then return end

    VFW.Society.SaveGrades(jobName, { {
        grade = number,
        name = cleanString(grade.name, 60, "grade"),
        label = cleanString(grade.label, 80, grade.name),
        salary = math.floor(cleanNumber(grade.salary, 0)),
        is_boss = (grade.is_boss == true or grade.is_boss == 1),
    } })

    VFW.Society.RefreshJobs()

    for src, other in pairs(VFW.Players) do
        if other.job and other.job.name == jobName then
            other.setJob(jobName, other.job.grade, other.job.onDuty)
            VFW.Society.SendData(src, jobName)
        end
    end

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Builder",
        message = ("Grade #%d modifié."):format(number),
    })
end)

RegisterNetEvent("core:delete:society:grade", function(jobName, grade)
    local source = source
    local xPlayer = getStaff(source)
    if not xPlayer then return end
    if not jobNameIsValid(jobName) then return end
    if type(grade) ~= "table" then return end

    local number = tonumber(grade.grade)
    if not number then return end
    number = math.floor(number)

    local row = VFW.Society.Single("SELECT is_boss FROM job_grades WHERE job_name = ? AND grade = ?", { jobName, number })
    if not row then return end

    if row.is_boss == 1 or row.is_boss == true then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Builder",
            message = "Impossible de supprimer un grade patron.",
        })
        return
    end

    VFW.Society.Update("DELETE FROM job_grades WHERE job_name = ? AND grade = ?", { jobName, number })
    VFW.Society.Update("UPDATE characters SET job_grade = 0 WHERE job = ? AND job_grade = ?", { jobName, number })
    VFW.Society.RefreshJobs()

    for src, other in pairs(VFW.Players) do
        if other.job and other.job.name == jobName and other.job.grade == number then
            other.setJob(jobName, 0, other.job.onDuty)
            VFW.Society.SendData(src, jobName)
        end
    end

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Builder",
        message = ("Grade #%d supprimé."):format(number),
    })
end)
