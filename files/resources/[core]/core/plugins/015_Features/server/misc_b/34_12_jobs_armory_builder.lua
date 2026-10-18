-- Armureries de job : cote serveur du builder (menu staff > Builder > ARMURERIES JOB).
--
-- Le menu client (client/staff/menu/builderJobArmory.lua) appelle douze points d'entree.
-- Aucun n'avait jamais ete ecrit. Seul le cote joueur existait : prendre et rendre une
-- arme, consulter les logs. Tout le reste tombait dans le vide.
--
-- Le symptome visible etait « aucun metier trouve » : la liste des jobs vient de
-- `core:jobArmory:getAllJobs`, qui n'existait pas. Le callback attendait quinze secondes,
-- rendait nil, et le menu affichait sa ligne de repli. Creer une armurerie, ajouter une
-- arme ou regler les grades ne marchait pas davantage, en silence cette fois : ce sont
-- des evenements, et un evenement sans handler ne proteste pas.
--
-- Trois colonnes manquaient aussi en base. Elles sont ajoutees au demarrage, comme le
-- font deja d'autres modules de la base.

local PERMISSION <const> = "builder_job_armory"

local function builder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if xPlayer.hasPermission(PERMISSION)
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- Schema
--
-- Le builder manipule trois notions que la table ne portait pas : le libelle lisible
-- d'une arme, les grades autorises par job, et l'ordre d'affichage. Les colonnes sont
-- ajoutees si elles manquent — `ADD COLUMN IF NOT EXISTS` n'existe pas sur MySQL, on
-- regarde donc le schema avant.
-- ═══════════════════════════════════════════════════════════════

local MISSING_COLUMNS <const> = {
    { table = "job_armories", column = "logs_allowed_grades", definition = "LONGTEXT NULL" },
    { table = "job_armory_weapons", column = "label", definition = "VARCHAR(100) NULL" },
    { table = "job_armory_weapons", column = "allowed_grades", definition = "LONGTEXT NULL" },
    { table = "job_armory_weapons", column = "display_order", definition = "INT NOT NULL DEFAULT 0" },
}

local function ensureColumns()
    for i = 1, #MISSING_COLUMNS do
        local entry = MISSING_COLUMNS[i]

        local exists = MiscB.Scalar([[
            SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
        ]], { entry.table, entry.column }, 0)

        if (tonumber(exists) or 0) == 0 then
            MiscB.Query(("ALTER TABLE `%s` ADD COLUMN `%s` %s")
                :format(entry.table, entry.column, entry.definition), {})
        end
    end
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end

    ensureColumns()
end)

-- ═══════════════════════════════════════════════════════════════
-- Grades
--
-- Le builder regle les acces par { [job] = { [grade] = max par joueur } }. Le cote
-- joueur, lui, lit deux colonnes simples : `min_grade` et `max_per_player`. On garde
-- les deux representations coherentes a chaque enregistrement plutot que de reecrire
-- la prise d'arme, qui fonctionne.
-- ═══════════════════════════════════════════════════════════════

---@param allowed table|nil
---@return table clean
local function cleanGrades(allowed)
    local out = {}
    if type(allowed) ~= "table" then return out end

    for jobName, grades in pairs(allowed) do
        if type(jobName) == "string" and type(grades) == "table" then
            local kept = {}

            for grade, maxPerPlayer in pairs(grades) do
                local level = MiscB.ToInt(grade, 0, 100)
                local maximum = MiscB.ToInt(maxPerPlayer, 1, 999)
                if level and maximum then kept[tostring(level)] = maximum end
            end

            if next(kept) then out[jobName] = kept end
        end
    end

    return out
end

---@param allowed table
---@return number minGrade, number maxPerPlayer
local function derivedLimits(allowed)
    local minGrade, maxPerPlayer = nil, 1

    for _, grades in pairs(allowed) do
        for grade, maximum in pairs(grades) do
            local level = tonumber(grade) or 0
            if not minGrade or level < minGrade then minGrade = level end
            if maximum > maxPerPlayer then maxPerPlayer = maximum end
        end
    end

    return minGrade or 0, maxPerPlayer
end

---@param itemName string
---@return string label
local function itemLabel(itemName)
    local definition = VFW.Items and VFW.Items[itemName]
    if type(definition) == "table" and type(definition.label) == "string" and definition.label ~= "" then
        return definition.label
    end
    return itemName
end

-- ═══════════════════════════════════════════════════════════════
-- Lectures
-- ═══════════════════════════════════════════════════════════════

MiscB.Cb("core:jobArmory:getAllJobs", function(source)
    if not builder(source) then return {} end

    local rows = MiscB.Query("SELECT `name`, `label` FROM `jobs` ORDER BY `label` ASC", {})
    local out = {}

    for i = 1, #rows do
        out[#out + 1] = { name = rows[i].name, label = rows[i].label or rows[i].name }
    end

    return out
end)

MiscB.Cb("core:jobArmory:getJobGrades", function(source, jobName)
    if not builder(source) then return {} end

    local name = MiscB.Str(jobName, 60)
    if not name then return {} end

    local rows = MiscB.Query(
        "SELECT `grade`, `label` FROM `job_grades` WHERE `job_name` = ? ORDER BY `grade` ASC", { name })
    local out = {}

    for i = 1, #rows do
        local grade = MiscB.ToInt(rows[i].grade, 0, 100)
        if grade then
            out[#out + 1] = { grade = grade, label = rows[i].label or ("Grade " .. grade) }
        end
    end

    return out
end)

MiscB.Cb("core:jobArmory:getArmories", function(source)
    if not builder(source) then return {} end

    -- Les libelles des metiers accompagnent l'armurerie : le menu les affiche sans
    -- pouvoir les redemander job par job.
    local labels = {}
    local jobRows = MiscB.Query("SELECT `name`, `label` FROM `jobs`", {})
    for i = 1, #jobRows do labels[jobRows[i].name] = jobRows[i].label or jobRows[i].name end

    local rows = MiscB.Query("SELECT * FROM job_armories ORDER BY `id` ASC", {})
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local jobs = VFW.DB.Decode(row.jobs, {})

        local jobLabels = {}
        for j = 1, #jobs do jobLabels[jobs[j]] = labels[jobs[j]] or jobs[j] end

        out[#out + 1] = {
            id = row.id,
            name = row.name,
            jobs = jobs,
            jobLabels = jobLabels,
            pos = VFW.DB.Decode(row.pos, nil),
            npcPos = VFW.DB.Decode(row.npc_pos, nil),
            npcModel = row.npc_model,
            blipEnabled = row.blip_enabled == 1 or row.blip_enabled == true,
            active = row.active == 1 or row.active == true,
            logsAllowedGrades = VFW.DB.Decode(row.logs_allowed_grades, {}),
        }
    end

    return out
end)

MiscB.Cb("core:jobArmory:getWeapons", function(source, armoryId)
    if not builder(source) then return {} end

    local id = MiscB.ToInt(armoryId, 1)
    if not id then return {} end

    local rows = MiscB.Query(
        "SELECT * FROM job_armory_weapons WHERE armory_id = ? ORDER BY display_order ASC, id ASC", { id })
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            item_name = row.item_name,
            label = row.label or itemLabel(row.item_name),
            max_stock = tonumber(row.max_stock) or 0,
            current_out = tonumber(row.current_out) or 0,
            allowed_grades = VFW.DB.Decode(row.allowed_grades, {}),
        }
    end

    return out
end)

-- ═══════════════════════════════════════════════════════════════
-- Armureries
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent("core:jobArmory:create", function(payload)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local data = MiscB.Table(payload)
    if not data then return end

    local name = MiscB.Str(data.name, 100)
    local jobs = MiscB.Table(data.jobs)
    local pos = MiscB.Table(data.pos)

    if not name or name:gsub("%s", "") == "" or not jobs or #jobs == 0 or not pos then
        MiscB.Notify(source, "Cette armurerie est incomplete : il faut un nom, un job et une position.", "ROUGE")
        return
    end

    -- Les deux colonnes du PNJ sont facultatives. Un nil au milieu de la liste de
    -- parametres la tronquerait — Lua ne sait pas dire ou s'arrete un tableau troue —
    -- alors on insere ce qui est obligatoire, puis on complete.
    local armoryId = MiscB.Insert([[
        INSERT INTO job_armories (name, jobs, pos, blip_enabled, active)
        VALUES (?, ?, ?, ?, 1)
    ]], {
        name,
        VFW.DB.Encode(jobs),
        VFW.DB.Encode(pos),
        data.blipEnabled and 1 or 0,
    })

    if armoryId then
        local npcPos = MiscB.Table(data.npcPos)
        if npcPos then
            MiscB.Update("UPDATE job_armories SET npc_pos = ? WHERE id = ?",
                { VFW.DB.Encode(npcPos), armoryId })
        end

        local npcModel = MiscB.Str(data.npcModel, 60)
        if npcModel and npcModel ~= "" then
            MiscB.Update("UPDATE job_armories SET npc_model = ? WHERE id = ?", { npcModel, armoryId })
        end
    end

    MiscB.ReloadArmories()
    MiscB.Notify(source, ("Armurerie « %s » creee."):format(name), "VERT")
end)

-- Chaque champ du menu correspond a une colonne. Ce qui n'est pas dans cette table
-- n'est pas modifiable : un nom de champ invente ne doit rien ecrire.
local ARMORY_FIELDS <const> = {
    pos = { column = "pos", kind = "json" },
    npcPos = { column = "npc_pos", kind = "json" },
    npcModel = { column = "npc_model", kind = "string" },
    jobs = { column = "jobs", kind = "json" },
    logsAllowedGrades = { column = "logs_allowed_grades", kind = "json" },
    blipEnabled = { column = "blip_enabled", kind = "bool" },
    active = { column = "active", kind = "bool" },
}

RegisterNetEvent("core:jobArmory:update", function(armoryId, field, value)
    local source = source
    if not builder(source) then return end

    local id = MiscB.ToInt(armoryId, 1)
    local key = MiscB.Str(field, 32)
    local definition = key and ARMORY_FIELDS[key] or nil
    if not id or not definition then return end

    local stored
    if definition.kind == "json" then
        local table_ = MiscB.Table(value)
        if not table_ then return end
        stored = VFW.DB.Encode(table_)
    elseif definition.kind == "bool" then
        stored = (value == true or value == 1) and 1 or 0
    else
        stored = MiscB.Str(value, 100)
        if not stored then return end
    end

    MiscB.Update(("UPDATE job_armories SET `%s` = ? WHERE id = ?"):format(definition.column), { stored, id })
    MiscB.ReloadArmories()
end)

RegisterNetEvent("core:jobArmory:delete", function(armoryId)
    local source = source
    if not builder(source) then return end

    local id = MiscB.ToInt(armoryId, 1)
    if not id then return end

    MiscB.Update("DELETE FROM job_armory_weapons WHERE armory_id = ?", { id })
    MiscB.Update("DELETE FROM job_armory_logs WHERE armory_id = ?", { id })
    MiscB.Update("DELETE FROM job_armories WHERE id = ?", { id })

    MiscB.ReloadArmories()
    MiscB.Notify(source, "Armurerie supprimee.", "VERT")
end)

RegisterNetEvent("core:jobArmory:clearLogs", function(armoryId)
    local source = source
    if not builder(source) then return end

    local id = MiscB.ToInt(armoryId, 1)
    if not id then return end

    MiscB.Update("DELETE FROM job_armory_logs WHERE armory_id = ?", { id })
    MiscB.Notify(source, "Historique vide.", "VERT")
end)

-- ═══════════════════════════════════════════════════════════════
-- Armes
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent("core:jobArmory:addWeapon", function(payload)
    local source = source
    if not builder(source) then return end

    local data = MiscB.Table(payload)
    if not data then return end

    local armoryId = MiscB.ToInt(data.armory_id, 1)
    local itemName = MiscB.Str(data.item_name, 64)
    local maxStock = MiscB.ToInt(data.max_stock, 1, 9999)

    if not armoryId or not itemName or not maxStock then
        MiscB.Notify(source, "Cette arme est incomplete.", "ROUGE")
        return
    end

    local allowed = cleanGrades(data.allowed_grades)
    local minGrade, maxPerPlayer = derivedLimits(allowed)

    local last = MiscB.Scalar(
        "SELECT MAX(display_order) FROM job_armory_weapons WHERE armory_id = ?", { armoryId }, 0)

    MiscB.Insert([[
        INSERT INTO job_armory_weapons
            (armory_id, item_name, label, allowed_grades, min_grade, max_stock, max_per_player, display_order)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        armoryId,
        itemName,
        itemLabel(itemName),
        VFW.DB.Encode(allowed),
        minGrade,
        maxStock,
        maxPerPlayer,
        (tonumber(last) or 0) + 1,
    })

    MiscB.Notify(source, ("« %s » ajoutee a l'armurerie."):format(itemLabel(itemName)), "VERT")
end)

RegisterNetEvent("core:jobArmory:updateWeapon", function(weaponId, field, value)
    local source = source
    if not builder(source) then return end

    local id = MiscB.ToInt(weaponId, 1)
    local key = MiscB.Str(field, 32)
    if not id or not key then return end

    if key == "max_stock" then
        local stock = MiscB.ToInt(value, 0, 9999)
        if not stock then return end
        MiscB.Update("UPDATE job_armory_weapons SET max_stock = ? WHERE id = ?", { stock, id })
        return
    end

    if key == "current_out" then
        local out = MiscB.ToInt(value, 0, 9999)
        if not out then return end
        MiscB.Update("UPDATE job_armory_weapons SET current_out = ? WHERE id = ?", { out, id })
        return
    end

    if key == "allowed_grades" then
        local allowed = cleanGrades(value)
        local minGrade, maxPerPlayer = derivedLimits(allowed)

        MiscB.Update([[
            UPDATE job_armory_weapons
            SET allowed_grades = ?, min_grade = ?, max_per_player = ?
            WHERE id = ?
        ]], { VFW.DB.Encode(allowed), minGrade, maxPerPlayer, id })
    end
end)

RegisterNetEvent("core:jobArmory:deleteWeapon", function(weaponId)
    local source = source
    if not builder(source) then return end

    local id = MiscB.ToInt(weaponId, 1)
    if not id then return end

    MiscB.Update("DELETE FROM job_armory_weapons WHERE id = ?", { id })
    MiscB.Notify(source, "Arme retiree.", "VERT")
end)

RegisterNetEvent("core:jobArmory:reorderWeapon", function(weaponId, direction)
    local source = source
    if not builder(source) then return end

    local id = MiscB.ToInt(weaponId, 1)
    local way = MiscB.Str(direction, 8)
    if not id or (way ~= "up" and way ~= "down") then return end

    local current = MiscB.Single(
        "SELECT id, armory_id, display_order FROM job_armory_weapons WHERE id = ?", { id })
    if not current then return end

    -- On echange la place avec la voisine immediate, dans le sens demande. L'ordre
    -- d'insertion sert d'arbitre quand deux armes portent le meme rang.
    local comparison = way == "up" and "<" or ">"
    local order = way == "up" and "DESC" or "ASC"

    local neighbour = MiscB.Single(([[
        SELECT id, display_order FROM job_armory_weapons
        WHERE armory_id = ?
          AND (display_order %s ? OR (display_order = ? AND id %s ?))
        ORDER BY display_order %s, id %s
        LIMIT 1
    ]]):format(comparison, comparison, order, order), {
        current.armory_id,
        current.display_order,
        current.display_order,
        id,
    })

    if not neighbour then return end

    MiscB.Update("UPDATE job_armory_weapons SET display_order = ? WHERE id = ?",
        { neighbour.display_order, current.id })
    MiscB.Update("UPDATE job_armory_weapons SET display_order = ? WHERE id = ?",
        { current.display_order, neighbour.id })
end)
