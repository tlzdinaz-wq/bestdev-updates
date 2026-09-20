VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Concess = VFW.Concess or {}

local JC = VFW.JobsCommon
local Concess = VFW.Concess

local concessList = {}
local categoryList = {}
local vehicleList = {}

-- Miroir fichier des points (survit aux reboot même si la table SQL est vide / reset).
local POINTS_FILE <const> = "config/concess_points.json"

Concess.DefaultPed = "a_m_y_business_01"
Concess.TestDuration = 300000
Concess.StockRefundRatio = 0.75
Concess.StockBuyRatio = 0.5

local function decodePoints(value, withHeading)
    local decoded = JC.Decode(value, nil)
    if type(decoded) ~= "table" then return {} end

    local out = {}
    for i = 1, #decoded do
        local raw = decoded[i]
        local point = withHeading and JC.Vec4(raw) or JC.Vec(raw)
        if point then
            if withHeading then
                point.h = point.h or 0.0
            end
            out[#out + 1] = point
        end
    end
    return out
end

local function decodeShowcase(value)
    local decoded = JC.Decode(value, nil)
    if type(decoded) ~= "table" then return {} end

    local out = {}
    local function push(raw)
        if type(raw) ~= "table" then return end
        local point = JC.Vec4(raw)
        if not point then return end
        local model = JC.Str(raw.model, 64)
        if not model then return end
        point.model = model:lower()
        point.rotate = raw.rotate == true or raw.rotate == 1 or raw.rotate == "1"
        if type(raw.color) == "table" then
            local r = JC.Int(raw.color.r, 0, 255)
            local g = JC.Int(raw.color.g, 0, 255)
            local b = JC.Int(raw.color.b, 0, 255)
            if r and g and b then
                point.color = { r = r, g = g, b = b }
            end
        end
        out[#out + 1] = point
    end

    if decoded[1] ~= nil then
        for i = 1, #decoded do
            push(decoded[i])
        end
    else
        for _, raw in pairs(decoded) do
            push(raw)
        end
    end
    return out
end

Concess.DecodePoints = decodePoints
Concess.DecodeShowcase = decodeShowcase

local function normalize(row)
    return {
        id = tonumber(row.id),
        name = row.name or "",
        job = row.job or "",
        concessType = JC.Int(row.concess_type, 1, 3) or 1,
        automatic = row.automatic == 1 or row.automatic == true,
        pedModel = JC.Str(row.ped_model, 64) or Concess.DefaultPed,
        catalog = decodePoints(row.catalog, true),
        preview = decodePoints(row.preview, true),
        spawn = decodePoints(row.spawn, true),
        showcase = decodeShowcase(row.showcase),
    }
end

Concess.Normalize = normalize

local function serializeEntry(entry)
    return {
        id = entry.id,
        name = entry.name,
        job = entry.job,
        concessType = entry.concessType,
        automatic = entry.automatic == true,
        pedModel = entry.pedModel,
        catalog = entry.catalog or {},
        preview = entry.preview or {},
        spawn = entry.spawn or {},
        showcase = entry.showcase or {},
    }
end

function Concess.SavePointsFile()
    local list = {}
    for _, entry in pairs(concessList) do
        if entry and entry.id then
            list[#list + 1] = serializeEntry(entry)
        end
    end
    table.sort(list, function(a, b) return (a.id or 0) < (b.id or 0) end)
    local body = json.encode({ version = 1, updatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"), entries = list })
    local ok = SaveResourceFile(GetCurrentResourceName(), POINTS_FILE, body, -1)
    if not ok then
        print("^1[concess]^7 impossible d'écrire " .. POINTS_FILE)
    end
    return ok == true
end

local function loadPointsFile()
    local raw = LoadResourceFile(GetCurrentResourceName(), POINTS_FILE)
    if type(raw) ~= "string" or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then return nil end
    local entries = decoded.entries or decoded
    if type(entries) ~= "table" then return nil end
    local out = {}
    for i = 1, #entries do
        local row = entries[i]
        if type(row) == "table" then
            local entry = normalize({
                id = row.id,
                name = row.name,
                job = row.job,
                concess_type = row.concessType or row.concess_type,
                automatic = row.automatic and 1 or 0,
                ped_model = row.pedModel or row.ped_model,
                catalog = row.catalog,
                preview = row.preview,
                spawn = row.spawn,
                showcase = row.showcase,
            })
            if entry.id then out[entry.id] = entry end
        end
    end
    return out
end

local function restoreEntryToDb(entry)
    if not entry or not entry.id then return end
    local exists = JC.Scalar("SELECT id FROM concess WHERE id = ?", { entry.id }, nil)
    if exists then
        Concess.Persist(entry)
        return
    end
    JC.Insert([[
        INSERT INTO concess (id, name, job, concess_type, automatic, ped_model, catalog, preview, spawn, showcase)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        entry.id,
        entry.name,
        entry.job or "",
        entry.concessType or 1,
        entry.automatic and 1 or 0,
        entry.pedModel or Concess.DefaultPed,
        JC.Encode(entry.catalog) or "[]",
        JC.Encode(entry.preview) or "[]",
        JC.Encode(entry.spawn) or "[]",
        JC.Encode(entry.showcase) or "[]",
    })
end

function Concess.Load()
    local rows = JC.Query("SELECT * FROM concess ORDER BY id ASC")
    local out = {}
    for i = 1, #rows do
        local entry = normalize(rows[i])
        if entry.id then out[entry.id] = entry end
    end

    -- Fichier JSON : complète / restaure les points manquants après reboot
    local fromFile = loadPointsFile()
    if fromFile then
        local dbCount = 0
        for _ in pairs(out) do dbCount = dbCount + 1 end
        if dbCount == 0 then
            for id, entry in pairs(fromFile) do
                out[id] = entry
                restoreEntryToDb(entry)
            end
            if next(fromFile) then
                print("^2[concess]^7 points restaurés depuis " .. POINTS_FILE)
            end
        else
            -- DB présente : le fichier prime sur les coords (catalog/preview/spawn/showcase)
            for id, fileEntry in pairs(fromFile) do
                local dbEntry = out[id]
                if dbEntry then
                    dbEntry.catalog = fileEntry.catalog
                    dbEntry.preview = fileEntry.preview
                    dbEntry.spawn = fileEntry.spawn
                    dbEntry.showcase = fileEntry.showcase
                    if fileEntry.name and fileEntry.name ~= "" then dbEntry.name = fileEntry.name end
                    if fileEntry.job ~= nil then dbEntry.job = fileEntry.job end
                    if fileEntry.concessType then dbEntry.concessType = fileEntry.concessType end
                    if fileEntry.automatic ~= nil then dbEntry.automatic = fileEntry.automatic end
                    if fileEntry.pedModel then dbEntry.pedModel = fileEntry.pedModel end
                else
                    out[id] = fileEntry
                    restoreEntryToDb(fileEntry)
                end
            end
        end
    end

    concessList = out
    Concess.SavePointsFile()
    return concessList
end

function Concess.LoadCatalog()
    local catRows = JC.Query("SELECT name, concess_type FROM concess_categories ORDER BY name ASC")
    local cats = {}
    for i = 1, #catRows do
        local name = JC.Str(catRows[i].name, 64)
        if name then
            cats[#cats + 1] = { name = name:lower(), concess_type = JC.Int(catRows[i].concess_type, 1, 3) or 1 }
        end
    end
    categoryList = cats

    local vehRows = JC.Query("SELECT model, name, price, category FROM concess_vehicles ORDER BY name ASC")
    local vehicles = {}
    for i = 1, #vehRows do
        local model = JC.Str(vehRows[i].model, 64)
        if model then
            vehicles[model:lower()] = {
                model = model:lower(),
                name = vehRows[i].name or model,
                price = JC.Int(vehRows[i].price, 0) or 0,
                category = (JC.Str(vehRows[i].category, 64) or ""):lower(),
            }
        end
    end
    vehicleList = vehicles

    return categoryList, vehicleList
end

function Concess.Get(id)
    local wanted = JC.Int(id)
    if not wanted then return nil end
    return concessList[wanted]
end

function Concess.GetAll()
    return concessList
end

local function lookupByJob(jobName)
    if type(jobName) ~= "string" or jobName == "" then return nil, jobName end
    for _, entry in pairs(concessList) do
        if entry.job == jobName then
            return entry, jobName
        end
    end
    local lower = jobName:lower()
    for _, entry in pairs(concessList) do
        if type(entry.job) == "string" and entry.job:lower() == lower then
            return entry, entry.job
        end
    end
    return nil, jobName
end

function Concess.GetByJob(jobName)
    local entry = lookupByJob(jobName)
    return entry
end

function Concess.Ensure(jobName)
    if type(jobName) ~= "string" or jobName == "" then return nil end

    local existing, resolved = lookupByJob(jobName)
    if existing then return existing, resolved end

    local society = VFW.Society and VFW.Society.Get and VFW.Society.Get(jobName)
    if not society and VFW.Society and VFW.Society.Ensure then
        society, resolved = VFW.Society.Ensure(jobName)
        jobName = resolved or jobName
        existing = lookupByJob(jobName)
        if existing then return existing, jobName end
    end

    local job = VFW.Jobs and VFW.Jobs[jobName]
    if not job and VFW.Jobs then
        local lower = jobName:lower()
        for name, def in pairs(VFW.Jobs) do
            if type(name) == "string" and name:lower() == lower then
                job = def
                jobName = name
                break
            end
        end
    end

    local societyType = (society and society.type) or (job and job.type) or ""
    if societyType ~= "concess" then return nil, jobName end

    local custom = (society and type(society.custom) == "table" and society.custom) or {}
    local catalog = decodePoints(custom.catalog, true)
    local preview = decodePoints(custom.preview, true)
    local spawn = decodePoints(custom.spawn, true)
    local showcase = decodeShowcase(custom.showcase or {})
    local label = (society and society.label) or (job and job.label) or jobName
    local concessType = JC.Int(custom.concessType, 1, 3) or 1
    local automatic = custom.automatic == true
    local pedModel = JC.Str(custom.pedModel, 64) or Concess.DefaultPed

    local insertId = JC.Insert([[
        INSERT INTO concess (name, job, concess_type, automatic, ped_model, catalog, preview, spawn, showcase)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        label,
        jobName,
        concessType,
        automatic and 1 or 0,
        pedModel,
        JC.Encode(catalog) or "[]",
        JC.Encode(preview) or "[]",
        JC.Encode(spawn) or "[]",
        JC.Encode(showcase) or "[]",
    })
    if not insertId then return nil, jobName end

    Concess.Load()
    local created = Concess.Get(insertId) or lookupByJob(jobName)
    if created then
        Concess.Broadcast(created)
    end
    return created, jobName
end

function Concess.Categories(concessType)
    local wanted = JC.Int(concessType, 1, 3)
    local out = {}
    for i = 1, #categoryList do
        if not wanted or categoryList[i].concess_type == wanted then
            out[#out + 1] = categoryList[i].name
        end
    end
    return out
end

function Concess.CategoriesWithType()
    local out = {}
    for i = 1, #categoryList do
        out[i] = { name = categoryList[i].name, concess_type = categoryList[i].concess_type }
    end
    return out
end

function Concess.CategoryType(categoryName)
    for i = 1, #categoryList do
        if categoryList[i].name == categoryName then return categoryList[i].concess_type end
    end
    return nil
end

function Concess.Vehicle(model)
    if type(model) ~= "string" then return nil end
    return vehicleList[model:lower()]
end

function Concess.VehiclesByCategory(categoryName, concessType)
    local wantedCat = JC.Str(categoryName, 64)
    local wantedType = JC.Int(concessType, 1, 3)

    if wantedCat then
        wantedCat = wantedCat:lower()
        local out = {}
        for model, data in pairs(vehicleList) do
            if data.category == wantedCat then out[model] = data end
        end
        return out
    end

    local out = {}
    for _, data in pairs(vehicleList) do
        local catType = Concess.CategoryType(data.category)
        if not wantedType or catType == wantedType then
            out[data.category] = out[data.category] or {}
            out[data.category][#out[data.category] + 1] = data
        end
    end
    return out
end

function Concess.Stock(concessId)
    local id = JC.Int(concessId)
    if not id then return {} end

    local rows = JC.Query([[
        SELECT model, name, quantity, in_test FROM concess_stock
        WHERE concess_id = ? AND quantity > 0 ORDER BY name ASC
    ]], { id })

    local out = {}
    for i = 1, #rows do
        out[i] = {
            model = rows[i].model,
            name = rows[i].name or rows[i].model,
            quantity = JC.Int(rows[i].quantity, 0) or 0,
            inTest = rows[i].in_test == 1 or rows[i].in_test == true,
        }
    end
    return out
end

function Concess.StockRow(concessId, model)
    local id = JC.Int(concessId)
    local name = JC.Str(model, 64)
    if not id or not name then return nil end
    return JC.Single(
        "SELECT id, model, name, quantity, in_test FROM concess_stock WHERE concess_id = ? AND model = ?",
        { id, name:lower() })
end

function Concess.AddStock(concessId, model, label, delta)
    local id = JC.Int(concessId)
    local name = JC.Str(model, 64)
    if not id or not name then return false end
    name = name:lower()

    local step = JC.Int(delta) or 0
    if step == 0 then return false end

    if step > 0 then
        JC.Exec([[
            INSERT INTO concess_stock (concess_id, model, name, quantity)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity), name = VALUES(name)
        ]], { id, name, label or name, step })
        return true
    end

    local row = Concess.StockRow(id, name)
    if not row or (JC.Int(row.quantity, 0) or 0) < -step then return false end

    local affected = JC.Exec(
        "UPDATE concess_stock SET quantity = quantity - ? WHERE concess_id = ? AND model = ? AND quantity >= ?",
        { -step, id, name, -step })
    return (tonumber(affected) or 0) > 0
end

function Concess.SetInTest(concessId, model, value)
    local id = JC.Int(concessId)
    local name = JC.Str(model, 64)
    if not id or not name then return false end
    JC.Exec("UPDATE concess_stock SET in_test = ? WHERE concess_id = ? AND model = ?",
        { value and 1 or 0, id, name:lower() })
    return true
end

function Concess.Log(concessId, logType, description, playerName, amount)
    local id = JC.Int(concessId)
    if not id then return end
    if logType ~= "sale" and logType ~= "purchase" then logType = "sale" end

    JC.Exec([[
        INSERT INTO concess_logs (concess_id, type, description, player, amount)
        VALUES (?, ?, ?, ?, ?)
    ]], { id, logType, tostring(description or ""):sub(1, 255), tostring(playerName or ""):sub(1, 128), JC.Int(amount, 0) or 0 })
end

function Concess.Logs(concessId, limit)
    local id = JC.Int(concessId)
    if not id then return {} end
    limit = JC.Int(limit, 1, 200) or 60

    local rows = JC.Query([[
        SELECT type, description, player, amount, date FROM concess_logs
        WHERE concess_id = ? ORDER BY id DESC LIMIT ?
    ]], { id, limit })

    local out = {}
    for i = 1, #rows do
        out[i] = {
            type = rows[i].type,
            description = rows[i].description or "",
            player = rows[i].player or "",
            amount = JC.Int(rows[i].amount, 0) or 0,
            date = tostring(rows[i].date or ""),
        }
    end
    return out
end

function Concess.Payload(entry)
    if not entry then return nil end
    return {
        id = entry.id,
        name = entry.name,
        job = entry.job,
        concessType = entry.concessType,
        automatic = entry.automatic,
        pedModel = entry.pedModel,
        catalog = entry.catalog,
        preview = entry.preview,
        spawn = entry.spawn,
        showcase = entry.showcase,
    }
end

function Concess.Persist(entry)
    if not entry or not entry.id then return end
    JC.Exec([[
        UPDATE concess SET name = ?, job = ?, concess_type = ?, automatic = ?, ped_model = ?,
            catalog = ?, preview = ?, spawn = ?, showcase = ?
        WHERE id = ?
    ]], {
        entry.name,
        entry.job,
        entry.concessType,
        entry.automatic and 1 or 0,
        entry.pedModel,
        JC.Encode(entry.catalog),
        JC.Encode(entry.preview),
        JC.Encode(entry.spawn),
        JC.Encode(entry.showcase),
        entry.id,
    })
    -- garder le miroir mémoire + fichier à jour
    concessList[entry.id] = entry
    Concess.SavePointsFile()
end

function Concess.Broadcast(entry)
    if not entry then return end
    TriggerClientEvent("concess:updated", -1, Concess.Payload(entry))
end

local BUILDER_PERMISSIONS = { "manage_concess", "builder_menu", "builder", "manage_jobs", "staff_menu" }

function Concess.CanBuild(xPlayer)
    if not xPlayer then return false end
    for i = 1, #BUILDER_PERMISSIONS do
        if xPlayer.hasPermission(BUILDER_PERMISSIONS[i]) then return true end
    end
    return false
end

function Concess.IsEmployee(xPlayer, entry)
    if not xPlayer or not xPlayer.job or not entry then return false end
    if type(entry.job) ~= "string" or entry.job == "" then return false end
    return xPlayer.job.name == entry.job or string.lower(tostring(xPlayer.job.name or "")) == entry.job:lower()
end

function Concess.IsEmployeeOnDuty(xPlayer, entry)
    if not Concess.IsEmployee(xPlayer, entry) then return false end
    return xPlayer.job.onDuty == true
end

local dutyCache = {}

function Concess.EmployeesOnDuty(jobName)
    if type(jobName) ~= "string" or jobName == "" then return false end

    local now = GetGameTimer()
    local cached = dutyCache[jobName]
    if cached and (now - cached.at) < 5000 then return cached.value end

    local value = false
    local players = VFW.GetPlayers()
    for i = 1, #players do
        local xPlayer = VFW.GetPlayerFromId(players[i])
        if xPlayer and xPlayer.job and xPlayer.job.name == jobName and xPlayer.job.onDuty then
            value = true
            break
        end
    end

    dutyCache[jobName] = { at = now, value = value }
    return value
end

function Concess.InvalidateDuty(jobName)
    if jobName then
        dutyCache[jobName] = nil
    else
        dutyCache = {}
    end
end

function Concess.GeneratePlate()
    if VFW.Vehicles and VFW.Vehicles.GeneratePlate then
        return VFW.Vehicles.GeneratePlate()
    end

    for _ = 1, 40 do
        local letters = ""
        for _ = 1, 3 do
            letters = letters .. string.char(math.random(65, 90))
        end
        local plate = ("%s %03d"):format(letters, math.random(0, 999))
        local exists = JC.Scalar("SELECT plate FROM owned_vehicles WHERE plate = ?", { plate }, nil)
        if not exists then return plate end
    end

    return ("C%07d"):format(math.random(0, 9999999))
end

function Concess.StoreVehicle(xPlayer, model, label, plate, color)
    if not xPlayer then return false end

    local props = { plate = plate, model = joaat(model) }
    if type(color) == "table" then
        props.color1 = 0
        props.color2 = 0
        props.customPrimaryColor = { color.r, color.g, color.b }
        props.customSecondaryColor = { color.r, color.g, color.b }
    end

    local ok = pcall(MySQL.insert.await, [[
        INSERT INTO owned_vehicles (plate, owner, owner_charid, vehName, model, label, props, stored, garage_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, NULL)
    ]], {
        plate,
        xPlayer.identifier,
        xPlayer.charId,
        model,
        model,
        label or model,
        JC.Encode(props),
    })

    return ok == true
end

JC.EnsureJob("concess", "Concessionnaire", "concess", nil)

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(2000)
    Concess.Load()
    Concess.LoadCatalog()
end)

AddEventHandler("vfw:setDuty", function(playerSource)
    local src = playerSource
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return end

    local jobName = xPlayer.job.name
    Concess.InvalidateDuty(jobName)

    if Concess.GetByJob(jobName) then
        TriggerClientEvent("concess:refreshEmployeeStatus", -1, jobName)
    end
end)

AddEventHandler("vfw:setJob", function(_, job, previous)
    Concess.InvalidateDuty()

    if type(job) == "table" and Concess.GetByJob(job.name) then
        TriggerClientEvent("concess:refreshEmployeeStatus", -1, job.name)
    end
    if type(previous) == "table" and Concess.GetByJob(previous.name) then
        TriggerClientEvent("concess:refreshEmployeeStatus", -1, previous.name)
    end
end)

AddEventHandler("vfw:playerDropped", function()
    Concess.InvalidateDuty()
end)
