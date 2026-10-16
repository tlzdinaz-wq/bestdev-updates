---@meta _
---@diagnostic disable: duplicate-doc-field

-- Armureries de job : côté serveur du builder.
--
-- Le côté joueur existait (prendre / rendre une arme, stocks, logs), mais sur les douze
-- points d'entrée appelés par le menu staff, un seul était écrit. Créer une armurerie,
-- la modifier, la supprimer, y ajouter une arme, lister les armureries, lire les jobs ou
-- les grades : rien n'était branché. Le menu envoyait dans le vide et la liste restait
-- vide, d'où « impossible de créer une armurerie ».
--
-- Trois colonnes attendues par le menu n'existaient pas non plus dans la base : le libellé
-- d'une arme, les grades autorisés par job, et les grades autorisés à lire les logs. Elles
-- sont ajoutées au démarrage si besoin.
--
-- `min_grade` et `max_per_player` restent renseignées : ce sont elles que lit le côté
-- joueur (34_11_jobs_common.lua). On les déduit des grades autorisés.

local PERM = "builder_job_armory"

local function encode(value)
    if VFW and VFW.DB and VFW.DB.Encode then return VFW.DB.Encode(value) end
    return json.encode(value or {})
end

local function decode(value, fallback)
    if type(value) == "table" then return value end
    if VFW and VFW.DB and VFW.DB.Decode then return VFW.DB.Decode(value, fallback) end
    if type(value) ~= "string" or value == "" then return fallback end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

---@param source number
---@return table|nil
local function builder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if not xPlayer.hasPermission(PERM) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Armureries",
            message = "Vous n'avez pas la permission de gérer les armureries.",
        })
        return nil
    end

    return xPlayer
end

--- Ajoute une colonne si elle manque, sans toucher aux données existantes.
---@param table_ string
---@param column string
---@param definition string
local function ensureColumn(table_, column, definition)
    local exists = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { table_, column })

    if (tonumber(exists) or 0) > 0 then return end

    MySQL.update.await(("ALTER TABLE `%s` ADD COLUMN `%s` %s"):format(table_, column, definition))
end

local function ensureColumns()
    ensureColumn("job_armories", "logs_allowed_grades", "LONGTEXT DEFAULT NULL")
    ensureColumn("job_armory_weapons", "label", "VARCHAR(100) DEFAULT NULL")
    ensureColumn("job_armory_weapons", "allowed_grades", "LONGTEXT DEFAULT NULL")
    ensureColumn("job_armory_weapons", "sort_order", "INT(11) NOT NULL DEFAULT 0")

    -- Les armes déjà en base ont toutes un ordre à zéro : sans ce rattrapage, monter ou
    -- descendre une arme n'aurait aucun effet (elles seraient toutes à égalité).
    MySQL.update.await("UPDATE job_armory_weapons SET sort_order = id WHERE sort_order = 0")
end

--- Prévient le reste du serveur et les joueurs qu'une armurerie a changé.
local function reload()
    TriggerEvent("core:jobArmory:reload")
end

--- Libellés des jobs liés, affichés par le menu (data.jobLabels).
---@param jobs table
---@return table
local function jobLabels(jobs)
    local labels = {}

    for i = 1, #jobs do
        local name = jobs[i]
        local job = VFW.Jobs and VFW.Jobs[name]
        labels[name] = (type(job) == "table" and job.label) or name
    end

    return labels
end

---@param row table
---@return table
local function armoryFromRow(row)
    local jobs = decode(row.jobs, {})

    return {
        id = row.id,
        name = row.name,
        jobs = jobs,
        jobLabels = jobLabels(jobs),
        pos = decode(row.pos, nil),
        npcPos = decode(row.npc_pos, nil),
        npcModel = row.npc_model,
        blipEnabled = row.blip_enabled == 1,
        active = row.active == 1,
        logsAllowedGrades = decode(row.logs_allowed_grades, {}),
    }
end

--- Le côté joueur raisonne en grade minimum et en maximum par joueur ; le builder, lui,
--- raisonne en grades autorisés par job. On traduit l'un vers l'autre pour que les deux
--- lectures restent cohérentes.
---@param allowedGrades table
---@return number minGrade, number maxPerPlayer
local function gradeBounds(allowedGrades)
    local minGrade, maxPerPlayer = nil, 1

    for _, grades in pairs(allowedGrades or {}) do
        if type(grades) == "table" then
            for grade, max in pairs(grades) do
                local level = tonumber(grade)
                if level and (not minGrade or level < minGrade) then minGrade = level end

                local count = tonumber(max) or 1
                if count > maxPerPlayer then maxPerPlayer = count end
            end
        end
    end

    return minGrade or 0, maxPerPlayer
end

---@param itemName string
---@return string
local function itemLabel(itemName)
    local item = VFW.Items and VFW.Items[itemName]
    if type(item) == "table" and type(item.label) == "string" and item.label ~= "" then
        return item.label
    end
    return itemName
end

-- ── Lectures ────────────────────────────────────────────────────────────────────────────

RegisterServerCallback("core:jobArmory:getArmories", function(source)
    if not builder(source) then return {} end

    local rows = MySQL.query.await("SELECT * FROM job_armories ORDER BY id ASC") or {}

    local out = {}
    for i = 1, #rows do
        out[i] = armoryFromRow(rows[i])
    end
    return out
end)

RegisterServerCallback("core:jobArmory:getAllJobs", function(source)
    if not builder(source) then return {} end

    local out = {}
    for name, job in pairs(VFW.Jobs or {}) do
        -- Les grades d'un métier sont stockés dans la même table que le métier lui-même :
        -- on ne garde que les vraies lignes de métier.
        if type(job) == "table" and job.name == name and job.grades ~= nil then
            out[#out + 1] = { name = name, label = job.label or name }
        end
    end

    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)

RegisterServerCallback("core:jobArmory:getJobGrades", function(source, jobName)
    if not builder(source) then return {} end

    local job = VFW.Jobs and VFW.Jobs[tostring(jobName or "")]
    if type(job) ~= "table" or type(job.grades) ~= "table" then return {} end

    local out = {}
    for _, grade in pairs(job.grades) do
        if type(grade) == "table" then
            local level = tonumber(grade.grade)
            if level then
                out[#out + 1] = { grade = level, label = grade.label or ("Grade " .. level) }
            end
        end
    end

    table.sort(out, function(a, b) return a.grade < b.grade end)
    return out
end)

RegisterServerCallback("core:jobArmory:getWeapons", function(source, armoryId)
    if not builder(source) then return {} end

    local id = tonumber(armoryId)
    if not id then return {} end

    local rows = MySQL.query.await(
        "SELECT * FROM job_armory_weapons WHERE armory_id = ? ORDER BY sort_order ASC, id ASC", { id }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            id = row.id,
            armory_id = row.armory_id,
            item_name = row.item_name,
            label = row.label ~= nil and row.label ~= "" and row.label or itemLabel(row.item_name),
            max_stock = tonumber(row.max_stock) or 0,
            current_out = tonumber(row.current_out) or 0,
            allowed_grades = decode(row.allowed_grades, {}),
        }
    end
    return out
end)

-- ── Armureries ──────────────────────────────────────────────────────────────────────────

RegisterNetEvent("core:jobArmory:create", function(payload)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    if type(payload) ~= "table" then return end

    local name = tostring(payload.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local jobs = type(payload.jobs) == "table" and payload.jobs or {}
    local pos = type(payload.pos) == "table" and payload.pos or nil

    if name == "" or #jobs == 0 or not pos then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Armureries",
            message = "Il faut un nom, au moins un job et une position.",
        })
        return
    end

    -- Colonnes posées une par une : un `nil` au milieu d'un tableau de paramètres en
    -- tronque la longueur, et la requête partirait avec des valeurs décalées.
    local columns = { "name", "jobs", "pos", "blip_enabled", "active" }
    local params = { name:sub(1, 100), encode(jobs), encode(pos), payload.blipEnabled and 1 or 0, 1 }

    if type(payload.npcPos) == "table" then
        columns[#columns + 1] = "npc_pos"
        params[#params + 1] = encode(payload.npcPos)
    end

    if type(payload.npcModel) == "string" and payload.npcModel ~= "" then
        columns[#columns + 1] = "npc_model"
        params[#params + 1] = payload.npcModel:sub(1, 60)
    end

    local marks = {}
    for i = 1, #columns do
        columns[i] = ("`%s`"):format(columns[i])
        marks[i] = "?"
    end

    local id = MySQL.insert.await(
        ("INSERT INTO job_armories (%s) VALUES (%s)")
            :format(table.concat(columns, ", "), table.concat(marks, ", ")),
        params
    )

    if not id then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Armureries",
            message = "Création impossible.",
        })
        return
    end

    reload()

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Armureries",
        message = ("Armurerie « %s » créée (#%d)."):format(name, id),
    })
end)

--- Le menu modifie un champ à la fois : `pos`, `npcPos`, `npcModel`, `jobs`, `blipEnabled`,
--- `active` ou `logsAllowedGrades`.
RegisterNetEvent("core:jobArmory:update", function(armoryId, field, value)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local id = tonumber(armoryId)
    if not id then return end

    local column, param

    if field == "pos" or field == "npcPos" then
        if type(value) ~= "table" then return end
        column = field == "pos" and "pos" or "npc_pos"
        param = encode(value)
    elseif field == "npcModel" then
        column, param = "npc_model", tostring(value or ""):sub(1, 60)
    elseif field == "jobs" then
        if type(value) ~= "table" then return end
        column, param = "jobs", encode(value)
    elseif field == "logsAllowedGrades" then
        if type(value) ~= "table" then return end
        column, param = "logs_allowed_grades", encode(value)
    elseif field == "blipEnabled" then
        column, param = "blip_enabled", (value and value ~= 0) and 1 or 0
    elseif field == "active" then
        column, param = "active", (value and value ~= 0) and 1 or 0
    else
        return
    end

    MySQL.update.await(("UPDATE job_armories SET `%s` = ? WHERE id = ?"):format(column), { param, id })
    reload()
end)

RegisterNetEvent("core:jobArmory:delete", function(armoryId)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local id = tonumber(armoryId)
    if not id then return end

    MySQL.update.await("DELETE FROM job_armory_weapons WHERE armory_id = ?", { id })
    MySQL.update.await("DELETE FROM job_armory_logs WHERE armory_id = ?", { id })
    MySQL.update.await("DELETE FROM job_armories WHERE id = ?", { id })

    reload()

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Armureries",
        message = ("Armurerie #%d supprimée."):format(id),
    })
end)

RegisterNetEvent("core:jobArmory:clearLogs", function(armoryId)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local id = tonumber(armoryId)
    if not id then return end

    MySQL.update.await("DELETE FROM job_armory_logs WHERE armory_id = ?", { id })

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Armureries",
        message = "Historique effacé.",
    })
end)

-- ── Armes ───────────────────────────────────────────────────────────────────────────────

RegisterNetEvent("core:jobArmory:addWeapon", function(payload)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    if type(payload) ~= "table" then return end

    local armoryId = tonumber(payload.armory_id)
    local itemName = tostring(payload.item_name or "")
    local maxStock = math.max(0, math.floor(tonumber(payload.max_stock) or 0))
    local allowedGrades = type(payload.allowed_grades) == "table" and payload.allowed_grades or {}

    if not armoryId or itemName == "" then return end

    local minGrade, maxPerPlayer = gradeBounds(allowedGrades)

    local nextOrder = MySQL.scalar.await(
        "SELECT COALESCE(MAX(sort_order), 0) + 1 FROM job_armory_weapons WHERE armory_id = ?", { armoryId })

    MySQL.insert.await([[
        INSERT INTO job_armory_weapons
            (armory_id, item_name, label, min_grade, max_stock, max_per_player, current_out,
             allowed_grades, sort_order)
        VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)
    ]], {
        armoryId, itemName:sub(1, 64), itemLabel(itemName):sub(1, 100),
        minGrade, maxStock, maxPerPlayer, encode(allowedGrades), tonumber(nextOrder) or 1,
    })

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Armureries",
        message = ("%s ajouté à l'armurerie."):format(itemLabel(itemName)),
    })
end)

RegisterNetEvent("core:jobArmory:updateWeapon", function(weaponId, field, value)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local id = tonumber(weaponId)
    if not id then return end

    if field == "max_stock" then
        MySQL.update.await("UPDATE job_armory_weapons SET max_stock = ? WHERE id = ?",
            { math.max(0, math.floor(tonumber(value) or 0)), id })
        return
    end

    if field == "current_out" then
        MySQL.update.await("UPDATE job_armory_weapons SET current_out = ? WHERE id = ?",
            { math.max(0, math.floor(tonumber(value) or 0)), id })
        return
    end

    if field == "allowed_grades" then
        if type(value) ~= "table" then return end
        local minGrade, maxPerPlayer = gradeBounds(value)
        MySQL.update.await([[
            UPDATE job_armory_weapons SET allowed_grades = ?, min_grade = ?, max_per_player = ?
            WHERE id = ?
        ]], { encode(value), minGrade, maxPerPlayer, id })
    end
end)

RegisterNetEvent("core:jobArmory:deleteWeapon", function(weaponId)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local id = tonumber(weaponId)
    if not id then return end

    MySQL.update.await("DELETE FROM job_armory_weapons WHERE id = ?", { id })

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Armureries",
        message = "Arme retirée de l'armurerie.",
    })
end)

--- Échange la place de l'arme avec sa voisine : c'est l'ordre d'affichage côté joueur.
RegisterNetEvent("core:jobArmory:reorderWeapon", function(weaponId, direction)
    local source = source
    if not builder(source) then return end

    local id = tonumber(weaponId)
    if not id then return end

    local row = MySQL.single.await("SELECT * FROM job_armory_weapons WHERE id = ? LIMIT 1", { id })
    if not row then return end

    local up = direction == "up"
    local neighbour = MySQL.single.await(([[
        SELECT * FROM job_armory_weapons
        WHERE armory_id = ? AND (sort_order %s ? OR (sort_order = ? AND id %s ?))
        ORDER BY sort_order %s, id %s LIMIT 1
    ]]):format(up and "<" or ">", up and "<" or ">", up and "DESC" or "ASC", up and "DESC" or "ASC"),
        { row.armory_id, row.sort_order, row.sort_order, row.id })

    if not neighbour then return end

    MySQL.update.await("UPDATE job_armory_weapons SET sort_order = ? WHERE id = ?",
        { neighbour.sort_order, row.id })
    MySQL.update.await("UPDATE job_armory_weapons SET sort_order = ? WHERE id = ?",
        { row.sort_order, neighbour.id })
end)

MySQL.ready(function()
    local ok, err = pcall(ensureColumns)
    if not ok then
        console.error("[armureries] colonnes manquantes : " .. tostring(err))
    end
end)
