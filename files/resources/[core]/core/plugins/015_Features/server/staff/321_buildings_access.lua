-- Builders > BÂTIMENTS & ACCÈS : la partie serveur de trois outils dont les menus s'ouvraient, enregistraient... et
-- n'avaient personne en face.
--
--   * TÉLÉPORTATIONS  (client/staff/menu/teleport_builder.lua + client/teleportBuilder/)
--   * ASCENSEURS      (client/staff/menu/builderElevators.lua + client/staff/gestion/gestion_elevators.lua)
--   * DÉPÔTS          (client/staff/menu/deposit_builder.lua) : création, modification, suppression et liste des jobs
--                     police ; le fonctionnement d'un dépôt (déposer, récupérer, consulter) est dans
--                     server/inventory/25_11_deposit.lua.
--
-- Sans ce fichier, « créer un point » répondait « Échec de l'enregistrement », rien ne se sauvegardait et aucun point
-- n'apparaissait en jeu : « après avoir ajouté les variables et les avoir appliquées, rien ne marche ».
-- Les points de téléportation et les ascenseurs ont chacun leur table, créée au démarrage.

local TELEPORT_PERMS = { "teleport_builder", "dev" }
local ELEVATOR_PERMS = { "builder_elevator", "dev" }
local DEPOSIT_PERMS = { "staff_menu", "dev" }

local TELEPORT_BUCKET_BASE = 300000   -- une instance par point : seau 300000 + id (les autres modules vivent plus bas)
local TELEPORT_REACH = 6.0
local MAX_LABEL = 100
local MAX_FLOORS = 40
local MAX_JOBS = 40
local MAX_GRADES = 40

local TELEPORT_TABLE_SQL = [[
    CREATE TABLE IF NOT EXISTS `teleport_points` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `label` VARCHAR(100) NOT NULL,
        `entry` LONGTEXT NOT NULL,
        `exit` LONGTEXT NOT NULL,
        `is_instance` TINYINT(1) NOT NULL DEFAULT 0,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    )
]]

local ELEVATOR_TABLE_SQL = [[
    CREATE TABLE IF NOT EXISTS `elevators` (
        `id` VARCHAR(64) NOT NULL,
        `floors` LONGTEXT NOT NULL,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    )
]]

local teleports = {}     -- [id] = { id, label, entry, exit, isInstance }
local elevators = {}     -- [id] = { floors = { { label, coords, whitelist? } } }
local loaded = false

-- ── outils communs ──

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end

local function allowed(source, permissions)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    for i = 1, #permissions do
        if xPlayer.hasPermission(permissions[i]) then return xPlayer end
    end
    return nil
end

--- Seul le passage d'un joueur est limité : un enregistrement du staff refusé en silence serait pire qu'une écriture de plus.
local function rateOk(source, key, ms)
    if Feat27 and Feat27.RateLimit then return Feat27.RateLimit(source, key, ms) end
    return true
end

local function tell(source, ok, subtitle, message)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.showNotification then return end
    xPlayer.showNotification({ type = "STAFF", variant = ok and "SUCCESS" or "ERROR", subtitle = subtitle, message = message })
end

--- Coupe à `max` caractères (la base compte en caractères) sans jamais couper une lettre accentuée en deux.
local function truncate(value, max)
    local length = utf8.len(value)
    if not length then return value:sub(1, max) end
    if length <= max then return value end
    return value:sub(1, utf8.offset(value, max + 1) - 1)
end

local function cleanText(value, max)
    if type(value) ~= "string" then return nil end
    value = value:gsub("%c", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if value == "" then return nil end
    return truncate(value, max)
end

--- Un champ d'une position reçue en table ou en vecteur (un vecteur refuse les champs qu'il n'a pas).
local function field(value, key)
    local ok, result = pcall(function() return value[key] end)
    if ok then return result end
    return nil
end

--- {x, y, z[, heading]} valide (nombres finis, dans la carte), sinon nil. Accepte une table ou un vector3/vector4 :
--- les positions envoyées par un client arrivent parfois en vecteur.
local function cleanCoords(value)
    local kind = type(value)
    if kind ~= "table" and kind ~= "vector3" and kind ~= "vector4" then return nil end

    local x, y, z = tonumber(field(value, "x")), tonumber(field(value, "y")), tonumber(field(value, "z"))
    if not (x and y and z) then return nil end
    for _, n in ipairs({ x, y, z }) do
        if n ~= n or math.abs(n) > 20000 then return nil end
    end

    local out = { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
    local heading = tonumber(field(value, "heading") or field(value, "h") or (kind == "vector4" and field(value, "w") or nil))
    if heading and heading == heading and math.abs(heading) < 100000 then
        out.heading = (heading % 360.0) + 0.0
    end
    return out
end

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- ═══════════════════════════════════════════════════════════════
-- TÉLÉPORTATIONS
-- ═══════════════════════════════════════════════════════════════

local function teleportList()
    local list = {}
    for _, point in pairs(teleports) do list[#list + 1] = copy(point) end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

--- Le point tel qu'il part à la base de données et aux joueurs, à partir de ce que le menu envoie.
local function teleportFromPayload(data, id)
    if type(data) ~= "table" then return nil, "Données invalides." end

    local label = cleanText(data.label, MAX_LABEL)
    if not label then return nil, "Le nom du point est obligatoire." end

    local entry, exit = cleanCoords(data.entry), cleanCoords(data.exit)
    if not entry then return nil, "La position d'entrée est invalide." end
    if not exit then return nil, "La position de sortie est invalide." end

    return {
        id = id,
        label = label,
        entry = entry,
        exit = exit,
        isInstance = data.isInstance == true,
    }
end

local function saveTeleport(source, point, isNew)
    if isNew then
        local ok, id = pcall(MySQL.insert.await, "INSERT INTO teleport_points (label, entry, `exit`, is_instance) VALUES (?, ?, ?, ?)", {
            point.label, json.encode(point.entry), json.encode(point.exit), point.isInstance and 1 or 0,
        })
        if not ok or not id then
            console.error("[téléportations] création impossible : " .. tostring(id))
            tell(source, false, "Builder Téléportation", "Écriture en base impossible (voir la console).")
            return nil
        end
        point.id = id
    else
        local ok, err = pcall(MySQL.update.await, "UPDATE teleport_points SET label = ?, entry = ?, `exit` = ?, is_instance = ? WHERE id = ?", {
            point.label, json.encode(point.entry), json.encode(point.exit), point.isInstance and 1 or 0, point.id,
        })
        if not ok then
            console.error("[téléportations] modification impossible : " .. tostring(err))
            tell(source, false, "Builder Téléportation", "Écriture en base impossible (voir la console).")
            return nil
        end
    end

    teleports[point.id] = point
    TriggerClientEvent("teleportBuilder:client:sync", -1, copy(point), isNew and "create" or "update")
    return point
end

RegisterServerCallback("teleportBuilder:getAllPoints", function()
    return teleportList()
end)

RegisterServerCallback("teleportBuilder:server:create", function(source, data)
    if not allowed(source, TELEPORT_PERMS) then return nil end

    local point, reason = teleportFromPayload(data, nil)
    if not point then
        tell(source, false, "Builder Téléportation", reason)
        return nil
    end

    return saveTeleport(source, point, true)
end)

RegisterServerCallback("teleportBuilder:server:update", function(source, data)
    if not allowed(source, TELEPORT_PERMS) then return nil end

    local id = type(data) == "table" and tonumber(data.id) or nil
    if not id or not teleports[id] then
        tell(source, false, "Builder Téléportation", "Ce point n'existe plus.")
        return nil
    end

    local point, reason = teleportFromPayload(data, id)
    if not point then
        tell(source, false, "Builder Téléportation", reason)
        return nil
    end

    return saveTeleport(source, point, false)
end)

RegisterNetEvent("teleportBuilder:server:delete", function(id)
    local source = source
    if not allowed(source, TELEPORT_PERMS) then return end

    id = tonumber(id)
    if not id or not teleports[id] then return end

    local ok, err = pcall(MySQL.update.await, "DELETE FROM teleport_points WHERE id = ?", { id })
    if not ok then
        console.error("[téléportations] suppression impossible : " .. tostring(err))
        tell(source, false, "Builder Téléportation", "Suppression en base impossible (voir la console).")
        return
    end

    teleports[id] = nil
    TriggerClientEvent("teleportBuilder:client:remove", -1, id)
end)

--- Passage d'un joueur : près de l'entrée il arrive à la sortie, près de la sortie il revient à l'entrée. La distance est
--- vérifiée ici (position réelle du joueur), pas sur la parole du client. En mode instance, l'arrivée à la sortie met le joueur
--- dans le seau du point (visible seulement de ceux qui y sont) et le retour à l'entrée le remet dans le monde.
RegisterNetEvent("teleportBuilder:server:interact", function(id)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not rateOk(source, "teleportBuilder:interact", 800) then return end

    local point = teleports[tonumber(id)]
    if not point then return end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end
    local here = GetEntityCoords(ped)
    local position = { x = here.x, y = here.y, z = here.z }

    local toEntry, toExit = distance(position, point.entry), distance(position, point.exit)
    if math.min(toEntry, toExit) > TELEPORT_REACH then return end

    local target
    if toEntry <= toExit then
        target = point.exit
        if point.isInstance then SetPlayerRoutingBucket(source, TELEPORT_BUCKET_BASE + point.id) end
    else
        target = point.entry
        if point.isInstance then SetPlayerRoutingBucket(source, 0) end
    end

    xPlayer.setCoords({ x = target.x, y = target.y, z = target.z, heading = target.heading })
end)

-- ═══════════════════════════════════════════════════════════════
-- ASCENSEURS
-- ═══════════════════════════════════════════════════════════════

--- Accès d'un étage : { jobs = { "police", ... }, gradesByJob = { police = { 0, 3, "boss" } } }, sinon libre.
local function cleanWhitelist(value)
    if type(value) ~= "table" or type(value.jobs) ~= "table" then return nil end

    local jobs, grades = {}, {}
    for i = 1, math.min(#value.jobs, MAX_JOBS) do
        local job = value.jobs[i]
        if type(job) == "string" and job:match("^[%w_%-%.]+$") and #job <= 60 and not grades[job] then
            jobs[#jobs + 1] = job

            local list = {}
            local source = type(value.gradesByJob) == "table" and value.gradesByJob[job] or nil
            if type(source) == "table" then
                for g = 1, math.min(#source, MAX_GRADES) do
                    local grade = source[g]
                    if type(grade) == "number" and grade == grade then
                        list[#list + 1] = grade
                    elseif type(grade) == "string" and #grade > 0 and #grade <= 40 then
                        list[#list + 1] = grade
                    end
                end
            end
            grades[job] = list
        end
    end

    if #jobs == 0 then return nil end
    return { jobs = jobs, gradesByJob = grades }
end

local function cleanFloors(value)
    if type(value) ~= "table" then return nil end

    local floors = {}
    for i = 1, math.min(#value, MAX_FLOORS) do
        local floor = value[i]
        if type(floor) == "table" then
            local coords = cleanCoords(floor.coords)
            if coords then
                floors[#floors + 1] = {
                    label = cleanText(floor.label, 80) or ("Étage " .. #floors + 1),
                    coords = coords,
                    whitelist = cleanWhitelist(floor.whitelist),
                }
            end
        end
    end

    if #floors == 0 then return nil end
    return floors
end

local function cleanElevatorId(value)
    if type(value) ~= "string" then return nil end
    value = value:lower()
    if not value:match("^[%w_]+$") or #value > 64 then return nil end
    return value
end

local function elevatorPayload()
    return copy(elevators)
end

local function saveElevator(id, floors)
    local ok, err = pcall(MySQL.query.await, [[
        INSERT INTO elevators (id, floors) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE floors = VALUES(floors)
    ]], { id, json.encode(floors) })

    if not ok then
        console.error("[ascenseurs] enregistrement impossible : " .. tostring(err))
        return false
    end

    elevators[id] = { floors = floors }
    return true
end

-- Création : le menu a déjà posé l'ascenseur chez son auteur ; tous les autres le reçoivent ici.
RegisterNetEvent("core:player:addElevator", function(id, floors)
    local source = source
    if not allowed(source, ELEVATOR_PERMS) then return end

    id = cleanElevatorId(id)
    floors = cleanFloors(floors)
    if not id then
        tell(source, false, "Ascenseurs", "Le nom de l'ascenseur est invalide (lettres, chiffres et _ seulement).")
        return
    end
    if not floors or #floors < 2 then
        tell(source, false, "Ascenseurs", "Un ascenseur demande au moins 2 étages valides.")
        return
    end
    if not saveElevator(id, floors) then
        tell(source, false, "Ascenseurs", "Écriture en base impossible (voir la console).")
        return
    end

    TriggerClientEvent("core:player:addElevator", -1, id, { floors = copy(floors) })
end)

RegisterNetEvent("core:player:updateElevatorFloors", function(id, floors)
    local source = source
    if not allowed(source, ELEVATOR_PERMS) then return end

    id = cleanElevatorId(id)
    floors = cleanFloors(floors)
    if not id or not elevators[id] or not floors then return end
    if not saveElevator(id, floors) then
        tell(source, false, "Ascenseurs", "Écriture en base impossible (voir la console).")
        return
    end

    TriggerClientEvent("core:player:updateElevatorFloors", -1, id, copy(floors))
end)

RegisterNetEvent("core:player:deleteElevator", function(id)
    local source = source
    if not allowed(source, ELEVATOR_PERMS) then return end

    id = cleanElevatorId(id)
    if not id or not elevators[id] then return end

    local ok, err = pcall(MySQL.update.await, "DELETE FROM elevators WHERE id = ?", { id })
    if not ok then
        console.error("[ascenseurs] suppression impossible : " .. tostring(err))
        tell(source, false, "Ascenseurs", "Suppression en base impossible (voir la console).")
        return
    end

    elevators[id] = nil
    TriggerClientEvent("core:player:removeElevator", -1, id)
end)

-- Chaque joueur demande les ascenseurs au chargement de son client (core:elevator:requestData).
RegisterNetEvent("core:elevator:requestData", function()
    local source = source
    TriggerClientEvent("core:player:receiveElevatorData", source, elevatorPayload())
end)

-- ═══════════════════════════════════════════════════════════════
-- DÉPÔTS : gestion depuis le builder (le fonctionnement est dans 25_11_deposit.lua)
-- ═══════════════════════════════════════════════════════════════

--- Jobs de police et de milice, tels que le menu les propose pour la consultation des dépôts.
local function lawJobs()
    local names = {}
    for _, list in ipairs({ PoliceJobsList, MiliceJobsList, LawEnforcementJobsList }) do
        if type(list) == "table" then
            for name, on in pairs(list) do
                if on then names[name] = true end
            end
        end
    end

    local out = {}
    for name in pairs(names) do
        local society = type(Society) == "table" and type(Society.minifiedList) == "table" and Society.minifiedList[name] or nil
        local job = VFW.Jobs and VFW.Jobs[name]
        out[#out + 1] = { name = name, label = (society and society.label) or (job and job.label) or name }
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end

local function cleanConsultJobs(value)
    local out, seen = {}, {}
    if type(value) == "table" then
        for i = 1, math.min(#value, MAX_JOBS) do
            local job = value[i]
            if type(job) == "string" and job:match("^[%w_%-%.]+$") and #job <= 60 and not seen[job] then
                seen[job] = true
                out[#out + 1] = job
            end
        end
    end
    return out
end

local function depositFromPayload(data)
    if type(data) ~= "table" then return nil, "Données invalides." end

    local label = cleanText(data.label, MAX_LABEL)
    if not label then return nil, "Le nom du dépôt est obligatoire." end

    local coords = cleanCoords(data.coords)
    if not coords then return nil, "La position du dépôt est invalide." end

    return { label = label, coords = { x = coords.x, y = coords.y, z = coords.z }, consultJobs = cleanConsultJobs(data.consultJobs) }
end

local function depositForClients(point)
    return {
        id = point.id,
        coords = { x = point.coords.x, y = point.coords.y, z = point.coords.z },
        label = point.label,
        consultJobs = copy(point.consultJobs or {}),
    }
end

RegisterServerCallback("depositBuilder:getPoliceJobs", function(source)
    if not allowed(source, DEPOSIT_PERMS) then return {} end
    return lawJobs()
end)

RegisterServerCallback("depositBuilder:server:create", function(source, data)
    if not allowed(source, DEPOSIT_PERMS) then return nil end
    if not DepositBuilderServer then return nil end

    local fields, reason = depositFromPayload(data)
    if not fields then
        tell(source, false, "Builder Dépôts", reason)
        return nil
    end

    local ok, id = pcall(MySQL.insert.await, [[
        INSERT INTO deposit_points (coords, label, access_name, manager_grade, max_weight, max_slots, consult_jobs)
        VALUES (?, ?, '', 0, 1000, 100, ?)
    ]], { json.encode(fields.coords), fields.label, json.encode(fields.consultJobs) })

    if not ok or not id then
        console.error("[dépôts] création impossible : " .. tostring(id))
        tell(source, false, "Builder Dépôts", "Écriture en base impossible (voir la console).")
        return nil
    end

    local point = {
        id = id,
        coords = fields.coords,
        label = fields.label,
        accessName = "",
        managerGrade = 0,
        maxWeight = 1000,
        maxSlots = 100,
        consultJobs = fields.consultJobs,
    }
    DepositBuilderServer.cache[id] = point
    TriggerClientEvent("depositBuilder:client:sync", -1, depositForClients(point))
    return depositForClients(point)
end)

RegisterServerCallback("depositBuilder:server:update", function(source, data)
    if not allowed(source, DEPOSIT_PERMS) then return nil end
    if not DepositBuilderServer then return nil end

    local id = type(data) == "table" and tonumber(data.id) or nil
    local point = id and DepositBuilderServer.Find(id) or nil
    if not point then
        tell(source, false, "Builder Dépôts", "Ce dépôt n'existe plus.")
        return nil
    end

    local fields, reason = depositFromPayload(data)
    if not fields then
        tell(source, false, "Builder Dépôts", reason)
        return nil
    end

    local ok, err = pcall(MySQL.update.await, "UPDATE deposit_points SET coords = ?, label = ?, consult_jobs = ? WHERE id = ?", {
        json.encode(fields.coords), fields.label, json.encode(fields.consultJobs), point.id,
    })
    if not ok then
        console.error("[dépôts] modification impossible : " .. tostring(err))
        tell(source, false, "Builder Dépôts", "Écriture en base impossible (voir la console).")
        return nil
    end

    point.coords, point.label, point.consultJobs = fields.coords, fields.label, fields.consultJobs
    TriggerClientEvent("depositBuilder:client:sync", -1, depositForClients(point))
    return depositForClients(point)
end)

-- Supprimer un point ne supprime pas ce que les joueurs y ont déposé : leurs coffres restent en base.
RegisterNetEvent("depositBuilder:server:delete", function(id)
    local source = source
    if not allowed(source, DEPOSIT_PERMS) or not DepositBuilderServer then return end

    local point = DepositBuilderServer.Find(id)
    if not point then return end

    local ok, err = pcall(MySQL.update.await, "DELETE FROM deposit_points WHERE id = ?", { point.id })
    if not ok then
        console.error("[dépôts] suppression impossible : " .. tostring(err))
        tell(source, false, "Builder Dépôts", "Suppression en base impossible (voir la console).")
        return
    end

    DepositBuilderServer.cache[point.id] = nil
    TriggerClientEvent("depositBuilder:client:remove", -1, point.id)
end)

-- ═══════════════════════════════════════════════════════════════
-- Démarrage et connexion des joueurs
-- ═══════════════════════════════════════════════════════════════

local function loadAll()
    local ok, rows = pcall(MySQL.query.await, "SELECT * FROM teleport_points")
    if ok and type(rows) == "table" then
        teleports = {}
        for i = 1, #rows do
            local row = rows[i]
            local entry, exit = cleanCoords(VFW.DB.Decode(row.entry, nil)), cleanCoords(VFW.DB.Decode(row["exit"], nil))
            if entry and exit then
                teleports[row.id] = {
                    id = row.id,
                    label = cleanText(row.label, MAX_LABEL) or ("Point " .. row.id),
                    entry = entry,
                    exit = exit,
                    isInstance = VFW.DB.IsSet(row.is_instance),
                }
            end
        end
    else
        console.warn("[téléportations] lecture impossible : " .. tostring(rows))
    end

    local okE, rowsE = pcall(MySQL.query.await, "SELECT * FROM elevators")
    if okE and type(rowsE) == "table" then
        elevators = {}
        for i = 1, #rowsE do
            local id = cleanElevatorId(rowsE[i].id)
            local floors = id and cleanFloors(VFW.DB.Decode(rowsE[i].floors, nil))
            if id and floors then elevators[id] = { floors = floors } end
        end
    else
        console.warn("[ascenseurs] lecture impossible : " .. tostring(rowsE))
    end

    loaded = true
end

CreateThread(function()
    while not VFW.Ready do Wait(250) end

    for _, sql in ipairs({ TELEPORT_TABLE_SQL, ELEVATOR_TABLE_SQL }) do
        local ok, err = pcall(MySQL.query.await, sql)
        if not ok then console.error("[bâtiments & accès] table impossible à créer : " .. tostring(err)) end
    end

    loadAll()

    TriggerClientEvent("teleportBuilder:client:init", -1, teleportList())
    TriggerClientEvent("core:player:receiveElevatorData", -1, elevatorPayload())
end)

AddEventHandler("vfw:characterLoaded", function(source)
    if not loaded then return end
    TriggerClientEvent("teleportBuilder:client:init", source, teleportList())
    TriggerClientEvent("core:player:receiveElevatorData", source, elevatorPayload())
end)
