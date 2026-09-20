local function registerCallback(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[Society] Callback '%s' déjà enregistré ailleurs: %s"):format(name, tostring(err)))
    end
end

VFW.Society.RegisterCallback = registerCallback

local function isStaff(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission("manage_jobs")
        or xPlayer.hasPermission("staff_menu")
        or xPlayer.hasPermission("manage_concess")
        or xPlayer.hasPermission("builder_taxi")
end

VFW.Society.IsStaff = isStaff

local function isBossGrade(job)
    if not job then return false end
    if job.grade_is_boss == true or job.grade_is_boss == 1 or job.grade_is_boss == "1" then return true end
    if job.isBoss == true or job.is_boss == true or job.is_boss == 1 then return true end
    local gradeNum = tonumber(job.grade)
    if gradeNum == 98 or gradeNum == 99 then return true end

    local name = string.lower(tostring(job.grade_name or ""))
    local label = string.lower(tostring(job.grade_label or ""))
    if name == "boss" or name == "patron" or name == "owner" or name == "pdg" then return true end
    if label:find("patron", 1, true) or label:find("boss", 1, true) or label == "pdg" then return true end

    local def = VFW.Jobs and VFW.Jobs[job.name]
    local grades = def and def.grades
    if type(grades) ~= "table" then return false end

    local gradeData = grades[tostring(gradeNum or job.grade or "")]
    if type(gradeData) == "table" then
        if gradeData.isBoss == true or gradeData.is_boss == true or gradeData.is_boss == 1 or gradeData.is_boss == "1" then
            return true
        end
        local gName = string.lower(tostring(gradeData.name or ""))
        local gLabel = string.lower(tostring(gradeData.label or ""))
        if gName == "boss" or gName == "patron" or gName == "owner" or gName == "pdg" then return true end
        if gLabel:find("patron", 1, true) or gLabel:find("boss", 1, true) then return true end
    end

    if gradeNum then
        local maxGrade = gradeNum
        for _, grade in pairs(grades) do
            local n = tonumber(grade.grade) or 0
            if n > maxGrade then maxGrade = n end
        end
        if gradeNum == maxGrade then return true end
    end

    return false
end

VFW.Society.IsBossGrade = isBossGrade

local function buildGradeList(jobName)
    local job = VFW.Jobs[jobName]
    local grades, perms = {}, {}

    if job and type(job.grades) == "table" then
        for _, grade in pairs(job.grades) do
            grades[#grades + 1] = {
                grade = grade.grade,
                name = grade.name,
                label = grade.label,
                salary = grade.salary,
                is_boss = grade.isBoss and 1 or 0,
            }
            perms[grade.name] = grade.permissions or {}
        end
    end

    table.sort(grades, function(a, b) return a.grade < b.grade end)

    return grades, perms
end

registerCallback("core:get:societies", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not isStaff(xPlayer) then return {} end

    local out = {}
    for name, society in pairs(VFW.Society.GetAll()) do
        out[name] = {
            name = name,
            label = society.label or name,
            type = society.type or "job",
            image = society.image or "",
            banner = society.banner or "",
            address = society.address or "",
        }
    end

    for name, job in pairs(VFW.Jobs) do
        if not out[name] then
            out[name] = {
                name = name,
                label = job.label or name,
                type = job.type or "job",
                image = "",
                banner = "",
                address = "",
            }
        end
    end

    return out
end)

registerCallback("core:get:societyData", function(source, name)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return VFW.Society.BuildPayload(nil) end
    if type(name) ~= "string" then return VFW.Society.BuildPayload(nil) end

    if not isStaff(xPlayer) and (not xPlayer.job or xPlayer.job.name ~= name) then
        return VFW.Society.BuildPayload(nil)
    end

    return VFW.Society.BuildPayload(name)
end)

registerCallback("core:get:societyImage", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return "" end
    return VFW.Society.GetImage(xPlayer.job.name)
end)

registerCallback("core:jobs:getJob", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if type(jobName) ~= "string" or jobName == "" then return nil end

    if not isStaff(xPlayer) and (not xPlayer.job or xPlayer.job.name ~= jobName) then return nil end

    local society = VFW.Society.Get(jobName)
    local grades, perms = buildGradeList(jobName)

    local jobData = {
        name = jobName,
        label = VFW.Society.GetLabel(jobName),
        image = society and society.image or "",
        banner = society and society.banner or "",
        grades = grades,
        perms = perms,
    }

    local money = 0
    local row = VFW.Society.Single("SELECT money FROM society_accounts WHERE job_name = ?", { jobName })
    if row and row.money then
        money = tonumber(row.money) or 0
    else
        local alt = VFW.Society.Single("SELECT bank FROM society_accounts WHERE society = ?", { jobName })
        if alt and alt.bank then money = tonumber(alt.bank) or 0 end
    end

    local societyData = {
        name = jobName,
        label = jobData.label,
        money = money,
    }

    local favoris = {}
    local favRows = VFW.Society.Query("SELECT identifier FROM society_favorites WHERE job_name = ?", { jobName })
    if favRows then
        for i = 1, #favRows do
            favoris[#favoris + 1] = favRows[i].identifier
        end
    end

    local customData = society and VFW.Society.Copy(society.custom) or {}
    if type(customData) ~= "table" then customData = {} end

    return jobData, societyData, favoris, customData
end)

registerCallback("core:jobs:getJobData", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if type(jobName) ~= "string" then return nil end

    local society = VFW.Society.Get(jobName)
    if not society then
        return { name = jobName, label = VFW.Society.GetLabel(jobName), custom = {} }
    end

    return {
        name = society.name,
        label = society.label,
        type = society.type,
        image = society.image,
        banner = society.banner,
        custom = VFW.Society.Copy(society.custom) or {},
    }
end)

registerCallback("vfw:dynasty:getCatalogPoints", function()
    local out = {}

    for name, society in pairs(VFW.Society.GetAll()) do
        if society.type == "dynasty" and type(society.custom) == "table" then
            local points = society.custom.catalog
            if type(points) == "table" then
                for _, point in pairs(points) do
                    if type(point) == "table" then
                        local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
                        if x and y and z then
                            out[#out + 1] = {
                                x = x + 0.0,
                                y = y + 0.0,
                                z = z + 0.0,
                                h = tonumber(point.h) or 0.0,
                                society = name,
                            }
                        end
                    end
                end
            end
        end
    end

    return out
end)

registerCallback("core:jobs:hasPermission", function(source, jobName, permission)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return false end
    if type(jobName) ~= "string" or type(permission) ~= "string" then return false end
    if xPlayer.job.name ~= jobName then return false end

    if isBossGrade(xPlayer.job) then return true end

    local perms = xPlayer.job.permissions
    if type(perms) ~= "table" then return false end
    if perms[permission] == true or perms[permission] == 1 then return true end

    local row = VFW.Society.Single(
        "SELECT enabled FROM society_grade_perms WHERE job_name = ? AND grade_name = ? AND perm_name = ?",
        { jobName, xPlayer.job.grade_name, permission }
    )

    return row ~= nil and (row.enabled == 1 or row.enabled == true)
end)

registerCallback("society:storage:open", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return { open = false } end

    local jobName = xPlayer.job.name
    local society = VFW.Society.Get(jobName)
    if not society then return { open = false } end

    if type(society.storage) ~= "table" or not next(society.storage) then return { open = false } end
    if not xPlayer.job.onDuty then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous devez être en service." })
        return { open = false }
    end

    local chestId = ("society:%s:storage"):format(jobName)
    local maxWeight = tonumber(society.custom and society.custom.storageMaxWeight) or 500000
    local maxSlots = tonumber(society.custom and society.custom.storageMaxSlots) or 50

    VFW.Society.EnsureChest(chestId, ("%s - Stockage"):format(society.label or jobName), maxWeight, maxSlots, jobName)

    return { open = true, id = chestId }
end)

registerCallback("society:doorbell:getAll", function()
    local out = {}
    local list = VFW.Society.GetAllDoorbells()

    for i = 1, #list do
        local db = list[i]
        out[i] = {
            id = db.id,
            jobName = db.jobName,
            x = db.x,
            y = db.y,
            z = db.z,
            message = db.message,
            callerMessage = db.callerMessage,
        }
    end

    return out
end)

local function doorbellPayload(jobName)
    local out = {}
    local list = VFW.Society.GetDoorbells(jobName)

    for i = 1, #list do
        local db = list[i]
        out[i] = {
            id = db.id,
            jobName = db.jobName,
            x = db.x,
            y = db.y,
            z = db.z,
            message = db.message,
            callerMessage = db.callerMessage,
        }
    end

    return out
end

registerCallback("society:doorbell:add", function(source, jobName, x, y, z, message, callerMessage)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_jobs") then return false end
    if type(jobName) ~= "string" or jobName == "" then return false end

    local px, py, pz = tonumber(x), tonumber(y), tonumber(z)
    if not px or not py or not pz then return false end
    if type(message) ~= "string" or message == "" then return false end
    if type(callerMessage) ~= "string" or callerMessage == "" then
        callerMessage = "Votre sonnerie a bien été envoyée."
    end

    VFW.Society.Insert([[
        INSERT INTO society_doorbells (job_name, x, y, z, message, caller_message)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { jobName, px, py, pz, message:sub(1, 255), callerMessage:sub(1, 255) })

    VFW.Society.LoadDoorbells()
    TriggerClientEvent("society:doorbell:refresh", -1)

    return doorbellPayload(jobName)
end)

registerCallback("society:doorbell:update", function(source, jobName, id, message, callerMessage)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_jobs") then return false end
    if type(jobName) ~= "string" or jobName == "" then return false end

    local doorbellId = tonumber(id)
    if not doorbellId then return false end
    if type(message) ~= "string" or message == "" then return false end
    if type(callerMessage) ~= "string" or callerMessage == "" then
        callerMessage = "Votre sonnerie a bien été envoyée."
    end

    VFW.Society.Update([[
        UPDATE society_doorbells SET message = ?, caller_message = ? WHERE id = ? AND job_name = ?
    ]], { message:sub(1, 255), callerMessage:sub(1, 255), math.floor(doorbellId), jobName })

    VFW.Society.LoadDoorbells()
    TriggerClientEvent("society:doorbell:refresh", -1)

    return doorbellPayload(jobName)
end)

registerCallback("society:doorbell:delete", function(source, jobName, id)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_jobs") then return false end
    if type(jobName) ~= "string" or jobName == "" then return false end

    local doorbellId = tonumber(id)
    if not doorbellId then return false end

    VFW.Society.Update("DELETE FROM society_doorbells WHERE id = ? AND job_name = ?", { math.floor(doorbellId), jobName })

    VFW.Society.LoadDoorbells()
    TriggerClientEvent("society:doorbell:refresh", -1)

    return doorbellPayload(jobName)
end)
