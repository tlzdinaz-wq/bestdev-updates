VFW.Society = VFW.Society or {}

Society = Society or {}
Society.minifiedList = Society.minifiedList or {}

local societies = {}
local doorbellsByJob = {}
local doorbellsAll = {}
local recipesByJob = {}

local reportedQueries = {}

local function reportError(query, err)
    if reportedQueries[query] then return end
    reportedQueries[query] = true
    console.error(("[Society] SQL: %s"):format(tostring(err)))
end

local function sqlQuery(query, params)
    local ok, res = pcall(MySQL.query.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlSingle(query, params)
    local ok, res = pcall(MySQL.single.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlInsert(query, params)
    local ok, res = pcall(MySQL.insert.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlUpdate(query, params)
    local ok, res = pcall(MySQL.update.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

VFW.Society.Query = sqlQuery
VFW.Society.Single = sqlSingle
VFW.Society.Insert = sqlInsert
VFW.Society.Update = sqlUpdate

local function asTable(value)
    local decoded = VFW.DB.Decode(value, nil)
    if type(decoded) ~= "table" then return {} end
    return decoded
end

local function numberOr(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy(v)
    end
    return out
end

VFW.Society.Copy = copy

local function buildCrafts(name, custom)
    local points = custom.harvestPoints
    if type(points) ~= "table" then return end

    local list = recipesByJob[name]
    if type(list) ~= "table" or #list == 0 then return end

    local crafts = {}
    for k, point in pairs(points) do
        if type(point) == "table" and point.x then
            crafts[k] = {
                position = { x = numberOr(point.x, 0.0), y = numberOr(point.y, 0.0), z = numberOr(point.z, 0.0) },
                items = copy(list),
            }
        end
    end

    if next(crafts) then
        custom.crafts = crafts
    end
end

local function normalize(row)
    local blip = asTable(row.blip)
    if type(blip.position) ~= "table" then blip.position = {} end
    blip.enabled = blip.enabled and true or false
    blip.sprite = numberOr(blip.sprite, 1)
    blip.color = numberOr(blip.color, 0)
    blip.scale = numberOr(blip.scale, 0.5)
    blip.name = tostring(blip.name or row.label or row.name)

    local management = asTable(row.management)
    local storage = asTable(row.storage)
    local custom = asTable(row.custom)

    if not next(storage) and type(custom.storage) == "table" then
        storage = custom.storage
    end

    local society = {
        name = row.name,
        label = row.label ~= nil and row.label ~= "" and row.label or row.name,
        type = row.type or "job",
        image = row.image or "",
        banner = row.banner or "",
        address = row.address or "",
        blip = blip,
        management = management,
        storage = storage,
        custom = custom,
    }

    buildCrafts(society.name, custom)

    return society
end

local function rebuildMinified()
    local minified = {}
    for name, society in pairs(societies) do
        minified[name] = { name = name, label = society.label, type = society.type }
    end
    Society.minifiedList = minified

    if BuildPoliceJobsList then
        pcall(BuildPoliceJobsList)
    end
end

function VFW.Society.LoadRecipes()
    local rows = sqlQuery("SELECT * FROM society_craft_recipes") or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local ingredients = VFW.DB.Decode(row.ingredients, {})
        if type(ingredients) ~= "table" then ingredients = {} end

        local recipe = {}
        for _, ing in pairs(ingredients) do
            if type(ing) == "table" and type(ing.name) == "string" then
                local def = VFW.Items[ing.name]
                recipe[#recipe + 1] = {
                    name = ing.name,
                    label = def and def.label or ing.name,
                    amount = numberOr(ing.count or ing.amount, 1),
                    count = numberOr(ing.count or ing.amount, 1),
                }
            end
        end

        if #recipe > 0 then
            local def = VFW.Items[row.item]
            out[row.job_name] = out[row.job_name] or {}
            local list = out[row.job_name]
            list[#list + 1] = {
                name = row.item,
                label = row.label ~= "" and row.label or (def and def.label or row.item),
                image = def and def.image or nil,
                amount = numberOr(row.quantity, 1),
                time = numberOr(row.craft_time, 5000),
                recipe = recipe,
            }
        end
    end

    recipesByJob = out
    return out
end

function VFW.Society.GetRecipes(jobName)
    return recipesByJob[jobName]
end

function VFW.Society.GetRecipe(jobName, itemName)
    local list = recipesByJob[jobName]
    if type(list) ~= "table" then return nil end
    for i = 1, #list do
        if list[i].name == itemName then return list[i] end
    end
    return nil
end

function VFW.Society.LoadDoorbells()
    local rows = sqlQuery("SELECT * FROM society_doorbells ORDER BY id ASC") or {}
    local byJob, all = {}, {}

    for i = 1, #rows do
        local row = rows[i]
        local entry = {
            id = row.id,
            jobName = row.job_name,
            x = numberOr(row.x, 0.0),
            y = numberOr(row.y, 0.0),
            z = numberOr(row.z, 0.0),
            message = row.message or "",
            callerMessage = row.caller_message or "",
        }
        all[#all + 1] = entry
        byJob[row.job_name] = byJob[row.job_name] or {}
        local list = byJob[row.job_name]
        list[#list + 1] = entry
    end

    doorbellsByJob = byJob
    doorbellsAll = all
    return all
end

function VFW.Society.GetAllDoorbells()
    return doorbellsAll
end

function VFW.Society.GetDoorbells(jobName)
    local list = doorbellsByJob[jobName]
    if type(list) ~= "table" then return {} end
    return list
end

function VFW.Society.GetDoorbell(jobName, id)
    local list = VFW.Society.GetDoorbells(jobName)
    for i = 1, #list do
        if list[i].id == id then return list[i] end
    end
    return nil
end

function VFW.Society.LoadSocieties()
    pcall(function()
        sqlQuery("ALTER TABLE societies MODIFY COLUMN `image` VARCHAR(512) DEFAULT NULL")
    end)
    pcall(function()
        sqlQuery("ALTER TABLE societies MODIFY COLUMN `banner` VARCHAR(512) DEFAULT NULL")
    end)

    local rows = sqlQuery("SELECT * FROM societies") or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        if type(row.name) == "string" and row.name ~= "" then
            out[row.name] = normalize(row)
        end
    end

    societies = out
    rebuildMinified()
    console.init("Society", ("%d sociétés chargées"):format(#rows))
    return out
end

function VFW.Society.Get(name)
    if type(name) ~= "string" then return nil end
    return societies[name]
end

function VFW.Society.Ensure(name)
    if type(name) ~= "string" or name == "" then return nil, name end

    local existing = societies[name]
    if existing then return existing, name end

    local resolved = name
    local lower = name:lower()
    for socName, soc in pairs(societies) do
        if type(socName) == "string" and socName:lower() == lower then
            return soc, socName
        end
    end

    local job = VFW.Jobs and VFW.Jobs[name]
    if not job and VFW.Jobs then
        for jobName, def in pairs(VFW.Jobs) do
            if type(jobName) == "string" and jobName:lower() == lower then
                job = def
                resolved = jobName
                break
            end
        end
    end

    local label = (job and job.label) or name
    local jobType = (job and job.type) or "society"
    sqlUpdate([[
        INSERT INTO societies (name, label, type, image, banner, address, blip, management, storage, custom)
        VALUES (?, ?, ?, '', '', '', '{}', '{}', '{}', '{}')
        ON DUPLICATE KEY UPDATE label = IF(label IS NULL OR label = '', VALUES(label), label)
    ]], { resolved, label, jobType })

    local reloaded = VFW.Society.Reload(resolved)
    if reloaded then return reloaded, resolved end

    local created = normalize({
        name = resolved,
        label = label,
        type = jobType,
        image = "",
        banner = "",
        address = "",
        blip = "{}",
        management = "{}",
        storage = "{}",
        custom = "{}",
    })
    societies[resolved] = created
    rebuildMinified()
    return created, resolved
end

function VFW.Society.GetAll()
    return societies
end

function VFW.Society.GetImage(name)
    local society = societies[name]
    if not society then return "" end
    return society.image or ""
end

function VFW.Society.GetLabel(name)
    local society = societies[name]
    if society and society.label then return society.label end
    local job = VFW.Jobs[name]
    if job and job.label then return job.label end
    return name or "Entreprise"
end

function VFW.Society.Reload(name)
    if type(name) ~= "string" then return nil end

    local row = sqlSingle("SELECT * FROM societies WHERE name = ?", { name })
    if not row then
        societies[name] = nil
        rebuildMinified()
        return nil
    end

    societies[name] = normalize(row)
    rebuildMinified()
    return societies[name]
end

function VFW.Society.Remove(name)
    societies[name] = nil
    doorbellsByJob[name] = nil
    rebuildMinified()
end

function VFW.Society.BuildPayload(name)
    local society = societies[name]

    if not society then
        return {
            name = name or "",
            label = VFW.Society.GetLabel(name),
            type = "job",
            image = "",
            banner = "",
            address = "",
            blip = { enabled = false, position = {}, name = "", sprite = 1, color = 0, scale = 0.5 },
            management = {},
            storage = {},
            custom = {},
            doorbells = {},
        }
    end

    local payload = copy(society)
    payload.doorbells = copy(VFW.Society.GetDoorbells(name))

    if type(payload.blip) ~= "table" then payload.blip = {} end
    if type(payload.blip.position) ~= "table" then payload.blip.position = {} end
    if type(payload.management) ~= "table" then payload.management = {} end
    if type(payload.custom) ~= "table" then payload.custom = {} end
    if type(payload.storage) ~= "table" then payload.storage = {} end

    return payload
end

function VFW.Society.SendData(source, jobName)
    local target = tonumber(source)
    if not target then return end

    local payload = VFW.Society.BuildPayload(jobName)
    payload.service = false

    TriggerClientEvent("core:retrieve:societyData", target, payload)
end

function VFW.Society.BroadcastToJob(jobName)
    if type(jobName) ~= "string" then return end

    for src, xPlayer in pairs(VFW.Players) do
        if xPlayer.job and xPlayer.job.name == jobName then
            VFW.Society.SendData(src, jobName)
        end
    end
end

function VFW.Society.SaveGrades(jobName, grades)
    if type(grades) ~= "table" then return end

    for _, grade in pairs(grades) do
        if type(grade) == "table" and type(grade.name) == "string" then
            local number = math.floor(numberOr(grade.grade, 0))
            sqlUpdate([[
                INSERT INTO job_grades (job_name, grade, name, label, salary, is_boss)
                VALUES (?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE name = VALUES(name), label = VALUES(label),
                    salary = VALUES(salary), is_boss = VALUES(is_boss)
            ]], {
                jobName, number, grade.name,
                tostring(grade.label or grade.name),
                math.floor(numberOr(grade.salary, 0)),
                (grade.is_boss == true or grade.is_boss == 1) and 1 or 0,
            })
        end
    end
end

function VFW.Society.NextFreeGrade(jobName)
    local row = sqlSingle("SELECT MAX(grade) AS maxGrade FROM job_grades WHERE job_name = ? AND grade < 98", { jobName })
    local maxGrade = row and numberOr(row.maxGrade, -1) or -1
    if maxGrade < 0 then return 0 end
    return math.floor(maxGrade) + 1
end

local ensuredChests = {}

function VFW.Society.EnsureChest(chestId, label, maxWeight, maxSlots, owner)
    if type(chestId) ~= "string" or chestId == "" then return false end
    if ensuredChests[chestId] then return true end

    local statements = {
        {
            query = [[
                INSERT INTO chests (chest_id, name, label, max_weight, max_slots, owner)
                VALUES (?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE label = VALUES(label), max_weight = VALUES(max_weight), max_slots = VALUES(max_slots)
            ]],
            params = { chestId, label, label, maxWeight, maxSlots, owner or "" },
        },
        {
            query = [[
                INSERT INTO chests (chest_id, name, max_weight, max_slots, owner)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE name = VALUES(name), max_weight = VALUES(max_weight), max_slots = VALUES(max_slots)
            ]],
            params = { chestId, label, maxWeight, maxSlots, owner or "" },
        },
        {
            query = "INSERT IGNORE INTO chests (chest_id, name, max_weight, max_slots) VALUES (?, ?, ?, ?)",
            params = { chestId, label, maxWeight, maxSlots },
        },
    }

    for i = 1, #statements do
        local ok = pcall(MySQL.update.await, statements[i].query, statements[i].params)
        if ok then
            ensuredChests[chestId] = true
            return true
        end
    end

    console.warn(("[Society] Impossible de créer le coffre '%s' (table chests absente ?)"):format(chestId))
    return false
end

function VFW.Society.RefreshJobs()
    local ok, err = pcall(VFW.DB.LoadJobs)
    if not ok then
        console.error(("[Society] Rechargement des métiers impossible: %s"):format(tostring(err)))
    end
end

MySQL.ready(function()
    VFW.Society.LoadRecipes()
    VFW.Society.LoadDoorbells()
    VFW.Society.LoadSocieties()
end)
