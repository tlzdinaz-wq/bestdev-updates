-- Zones zombie : la moitié serveur, qui n'avait jamais été écrite.
--
-- Le builder (client/staff/menu/builderZombie.lua) et la carte de dessin
-- (client/zombie/cl_zombieTablet.lua) appelaient zombie:getZones, zombie:createZone,
-- zombie:saveZone et zombie:deleteZone sans que personne ne réponde : chaque appel
-- attendait les quinze secondes du délai des callbacks avant de rendre nil. D'où la carte
-- qui « apparaît en retard » et où rien ne s'enregistre.
--
-- Le spawner (client/zombie/cl_zombieSpawner.lua) parlait lui aussi dans le vide :
-- enterZone, exitZone, canSpawnBatch, spawnFailedBatch, zombiesRemovedBatch et loot.
-- Aucun zombie n'est jamais apparu.
--
-- Ce fichier tient les deux bouts :
--   · les zones en base (table `zombie_zones`), créées, modifiées, supprimées par le staff ;
--   · le compte des zombies vivants par zone, et le choix du joueur qui les fait apparaître.
--
-- Pourquoi un propriétaire par zone : les zombies sont des peds locaux. Si tous les joueurs
-- présents spawnaient, la zone en aurait autant de fois que de joueurs. Un seul joueur de la
-- zone les crée, et c'est le serveur qui plafonne le total à `max_zombies`.

local PERMISSIONS <const> = { "builder_zombie", "dev" }

local MAX_NAME <const> = 60
local MAX_POINTS <const> = 64
local MAX_ZOMBIES <const> = 999
local MAX_LOOT <const> = 5000
local MAX_ZONES <const> = 100

local TABLE_SQL <const> = [[
    CREATE TABLE IF NOT EXISTS `zombie_zones` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(60) NOT NULL,
        `polygon` LONGTEXT NOT NULL,
        `max_zombies` INT NOT NULL DEFAULT 10,
        `loot_min` INT NOT NULL DEFAULT 50,
        `loot_max` INT NOT NULL DEFAULT 150,
        `active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    )
]]

local zones = {}      -- [id] = { id, name, polygon, max_zombies, loot_min, loot_max, active }
local loaded = false

local inZone = {}     -- [zoneId] = { [source] = true }
local owner = {}      -- [zoneId] = source qui fait apparaître les zombies
local alive = {}      -- [zoneId] = nombre de zombies vivants annoncés

-- ── mise en forme ────────────────────────────────────────────────────────

local function cleanName(value)
    local name = MiscB.Str(value, MAX_NAME)
    if not name then return nil end
    name = name:gsub("%c", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name
end

--- Un polygone : au moins trois sommets, deux coordonnées chacun. Tout le reste est écarté.
local function cleanPolygon(value)
    if type(value) ~= "table" then return nil end
    local out = {}
    for i = 1, #value do
        if #out >= MAX_POINTS then break end
        local point = value[i]
        if type(point) == "table" then
            local x = MiscB.ToNum(point.x, nil)
            local y = MiscB.ToNum(point.y, nil)
            if x and y then out[#out + 1] = { x = x + 0.0, y = y + 0.0 } end
        end
    end
    if #out < 3 then return nil end
    return out
end

--- Ce que voient les clients : jamais la table interne, pour qu'une modification locale
--- ne se propage pas d'un joueur à l'autre.
local function snapshot(zone)
    local points = {}
    for i = 1, #zone.polygon do
        points[i] = { x = zone.polygon[i].x, y = zone.polygon[i].y }
    end
    return {
        id = zone.id,
        name = zone.name,
        polygon = points,
        max_zombies = zone.max_zombies,
        loot_min = zone.loot_min,
        loot_max = zone.loot_max,
        active = zone.active,
    }
end

--- Liste triée par identifiant : le builder l'affiche telle quelle.
local function snapshotAll()
    local list = {}
    for _, zone in pairs(zones) do list[#list + 1] = snapshot(zone) end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function allowed(source)
    local xPlayer = MiscB.Player(source)
    if not xPlayer then return nil end
    for i = 1, #PERMISSIONS do
        if xPlayer.hasPermission(PERMISSIONS[i]) then return xPlayer end
    end
    return nil
end

-- ── propriétaire et comptage ─────────────────────────────────────────────

--- Désigne celui qui fera apparaître les zombies de la zone, ou retire le rôle si elle est vide.
local function reassign(zoneId)
    local members = inZone[zoneId]
    local current = owner[zoneId]

    if current and members and members[current] then return end

    if current then
        TriggerClientEvent("zombie:setOwner", current, zoneId, false)
        owner[zoneId] = nil
    end

    local next_ = nil
    if members then
        for source in pairs(members) do next_ = source break end
    end

    if not next_ then
        -- Plus personne : les zombies du joueur parti ont disparu avec lui.
        alive[zoneId] = 0
        return
    end

    owner[zoneId] = next_
    TriggerClientEvent("zombie:setOwner", next_, zoneId, true)
end

local function leaveZone(source, zoneId)
    local members = inZone[zoneId]
    if not members or not members[source] then return end

    members[source] = nil
    if next(members) == nil then inZone[zoneId] = nil end

    if owner[zoneId] == source then
        -- Les peds étaient à lui : ils s'en vont avec lui.
        alive[zoneId] = 0
        owner[zoneId] = nil
        TriggerClientEvent("zombie:setOwner", source, zoneId, false)
        TriggerClientEvent("zombie:clearZone", source, zoneId)
    end

    reassign(zoneId)
end

local function leaveAll(source)
    for zoneId, members in pairs(inZone) do
        if members[source] then leaveZone(source, zoneId) end
    end
end

-- ── base de données ──────────────────────────────────────────────────────

local function loadAll()
    local rows = MiscB.Query("SELECT * FROM zombie_zones")
    local list = {}

    for i = 1, #rows do
        local row = rows[i]
        local id = MiscB.ToInt(row.id, 1, nil)
        local polygon = cleanPolygon(VFW.DB.Decode(row.polygon, nil))
        local name = cleanName(row.name)
        if id and polygon and name then
            list[id] = {
                id = id,
                name = name,
                polygon = polygon,
                max_zombies = MiscB.ToInt(row.max_zombies, 1, MAX_ZOMBIES) or 10,
                loot_min = MiscB.ToInt(row.loot_min, 0, MAX_LOOT) or ZombieConfig.LootDefaultMin,
                loot_max = MiscB.ToInt(row.loot_max, 0, MAX_LOOT) or ZombieConfig.LootDefaultMax,
                -- TINYINT(1) : selon la version d'oxmysql, un booléen ou un nombre.
                active = VFW.DB.IsSet(row.active),
            }
        end
    end

    zones = list
    loaded = true
    return true
end

CreateThread(function()
    while not VFW.Ready do Wait(250) end

    local ok, err = pcall(MySQL.query.await, TABLE_SQL)
    if not ok then
        console.error("[zombie] table zombie_zones impossible à créer : " .. tostring(err))
        return
    end

    loadAll()
    TriggerClientEvent("zombie:syncZones", -1, snapshotAll())

    local count = 0
    for _ in pairs(zones) do count = count + 1 end
    console.init("Zombie", ("%d zone%s chargée%s"):format(count, count > 1 and "s" or "", count > 1 and "s" or ""))
end)

-- Un joueur qui arrive reçoit les zones sans avoir à les demander.
AddEventHandler("vfw:characterLoaded", function(source)
    if loaded then TriggerClientEvent("zombie:syncZones", source, snapshotAll()) end
end)

AddEventHandler("vfw:playerDropped", function(source)
    leaveAll(tonumber(source) or 0)
end)

-- ── le builder ───────────────────────────────────────────────────────────

MiscB.Cb("zombie:getZones", function(source)
    if not allowed(source) then return {} end
    return snapshotAll()
end)

MiscB.Cb("zombie:createZone", function(source, data)
    if not allowed(source) then return { success = false, error = "Permission refusée." } end
    if not MiscB.Rate(source, "zombie:create", 700) then return { success = false, error = "Trop rapide." } end
    if type(data) ~= "table" then return { success = false, error = "Données invalides." } end

    local count = 0
    for _ in pairs(zones) do count = count + 1 end
    if count >= MAX_ZONES then return { success = false, error = "Trop de zones (" .. MAX_ZONES .. ")." } end

    local name = cleanName(data.name)
    if not name then return { success = false, error = "Nom manquant." } end

    local polygon = cleanPolygon(data.polygon)
    if not polygon then return { success = false, error = "Il faut au moins trois points." } end

    local maxZombies = MiscB.ToInt(data.max_zombies, 1, MAX_ZOMBIES) or 10

    local id = MiscB.Insert(
        "INSERT INTO zombie_zones (name, polygon, max_zombies, loot_min, loot_max, active) VALUES (?, ?, ?, ?, ?, ?)",
        { name, json.encode(polygon), maxZombies, ZombieConfig.LootDefaultMin, ZombieConfig.LootDefaultMax, 1 }
    )
    if not id then return { success = false, error = "Écriture en base impossible." } end

    zones[id] = {
        id = id,
        name = name,
        polygon = polygon,
        max_zombies = maxZombies,
        loot_min = ZombieConfig.LootDefaultMin,
        loot_max = ZombieConfig.LootDefaultMax,
        active = true,
    }

    TriggerClientEvent("zombie:syncZoneUpdate", -1, snapshot(zones[id]))
    -- Ceux qui sont déjà dedans n'y « entreront » jamais : il faut leur faire revérifier.
    TriggerClientEvent("zombie:recheckZone", -1, id)

    return { success = true, id = id }
end)

MiscB.Cb("zombie:saveZone", function(source, zoneId, data)
    if not allowed(source) then return { success = false, error = "Permission refusée." } end
    if not MiscB.Rate(source, "zombie:save", 400) then return { success = false, error = "Trop rapide." } end

    local id = MiscB.ToInt(zoneId, 1, nil)
    local zone = id and zones[id]
    if not zone then return { success = false, error = "Zone introuvable." } end
    if type(data) ~= "table" then return { success = false, error = "Données invalides." } end

    local maxZombies = MiscB.ToInt(data.max_zombies, 1, MAX_ZOMBIES) or zone.max_zombies
    local lootMin = MiscB.ToInt(data.loot_min, 0, MAX_LOOT) or zone.loot_min
    local lootMax = MiscB.ToInt(data.loot_max, 0, MAX_LOOT) or zone.loot_max
    if lootMin > lootMax then lootMin, lootMax = lootMax, lootMin end
    local active = data.active == true

    local ok = MiscB.Update(
        "UPDATE zombie_zones SET max_zombies = ?, loot_min = ?, loot_max = ?, active = ? WHERE id = ?",
        { maxZombies, lootMin, lootMax, active and 1 or 0, id }
    )
    if ok == nil then return { success = false, error = "Écriture en base impossible." } end

    local wasActive = zone.active
    zone.max_zombies = maxZombies
    zone.loot_min = lootMin
    zone.loot_max = lootMax
    zone.active = active

    TriggerClientEvent("zombie:syncZoneUpdate", -1, snapshot(zone))

    if not active and wasActive then
        -- Zone éteinte : on retire les zombies déjà là plutôt que d'attendre qu'ils s'effacent.
        alive[id] = 0
        local holder = owner[id]
        if holder then
            TriggerClientEvent("zombie:setOwner", holder, id, false)
            TriggerClientEvent("zombie:clearZone", holder, id)
            owner[id] = nil
        end
    elseif active and not wasActive then
        TriggerClientEvent("zombie:recheckZone", -1, id)
    end

    return { success = true }
end)

MiscB.Cb("zombie:deleteZone", function(source, zoneId)
    if not allowed(source) then return { success = false, error = "Permission refusée." } end
    if not MiscB.Rate(source, "zombie:delete", 700) then return { success = false, error = "Trop rapide." } end

    local id = MiscB.ToInt(zoneId, 1, nil)
    if not id or not zones[id] then return { success = false, error = "Zone introuvable." } end

    local ok = MiscB.Update("DELETE FROM zombie_zones WHERE id = ?", { id })
    if ok == nil then return { success = false, error = "Suppression en base impossible." } end

    local holder = owner[id]
    if holder then TriggerClientEvent("zombie:clearZone", holder, id) end

    zones[id] = nil
    inZone[id] = nil
    owner[id] = nil
    alive[id] = nil

    TriggerClientEvent("zombie:syncZoneDelete", -1, id)
    return { success = true }
end)

-- ── la vie de la zone ────────────────────────────────────────────────────

MiscB.Event("zombie:enterZone", function(zoneId)
    local source = source
    local id = MiscB.ToInt(zoneId, 1, nil)
    local zone = id and zones[id]
    if not zone or not zone.active then return end
    if not MiscB.Player(source) then return end

    inZone[id] = inZone[id] or {}
    if inZone[id][source] then return end
    inZone[id][source] = true

    reassign(id)
end)

MiscB.Event("zombie:exitZone", function(zoneId)
    local source = source
    local id = MiscB.ToInt(zoneId, 1, nil)
    if not id then return end
    leaveZone(source, id)
end)

--- Le propriétaire demande à poser des zombies : une entrée par zombie voulu.
--- On rend la même liste, écourtée à ce que la zone peut encore accueillir.
MiscB.Cb("zombie:canSpawnBatch", function(source, zoneIds)
    if type(zoneIds) ~= "table" then return {} end
    if not MiscB.Player(source) then return {} end

    local granted = {}
    local takenThisCall = {}

    for i = 1, #zoneIds do
        local id = MiscB.ToInt(zoneIds[i], 1, nil)
        local zone = id and zones[id]

        -- Seul le propriétaire de la zone fait apparaître ses zombies : sinon chaque joueur
        -- présent poserait sa propre horde et la zone en aurait autant de fois.
        if zone and zone.active and owner[id] == source then
            local current = (alive[id] or 0) + (takenThisCall[id] or 0)
            if current < zone.max_zombies then
                takenThisCall[id] = (takenThisCall[id] or 0) + 1
                granted[#granted + 1] = id
            end
        end
    end

    for id, count in pairs(takenThisCall) do
        alive[id] = (alive[id] or 0) + count
    end

    return granted
end)

--- Le client n'a pas trouvé de place pour certains : on rend les jetons.
MiscB.Event("zombie:spawnFailedBatch", function(zoneIds)
    local source = source
    if type(zoneIds) ~= "table" then return end

    for i = 1, #zoneIds do
        local id = MiscB.ToInt(zoneIds[i], 1, nil)
        if id and owner[id] == source and alive[id] then
            alive[id] = math.max(0, alive[id] - 1)
        end
    end
end)

--- Zombies morts ou trop loin, retirés chez le client : { [zoneId] = nombre }.
MiscB.Event("zombie:zombiesRemovedBatch", function(removed)
    local source = source
    if type(removed) ~= "table" then return end

    for zoneId, count in pairs(removed) do
        local id = MiscB.ToInt(zoneId, 1, nil)
        local n = MiscB.ToInt(count, 1, 1000)
        if id and n and owner[id] == source and alive[id] then
            alive[id] = math.max(0, alive[id] - n)
        end
    end
end)

--- Fouille d'un cadavre : de l'argent sale, dans la fourchette de la zone.
MiscB.Event("zombie:loot", function(zoneId)
    local source = source
    local id = MiscB.ToInt(zoneId, 1, nil)
    local zone = id and zones[id]
    if not zone then return end

    -- La fouille dure trois secondes chez le client ; une demande plus rapide n'est pas une fouille.
    if not MiscB.Rate(source, "zombie:loot", 2000) then return end

    local xPlayer = MiscB.Player(source)
    if not xPlayer then return end

    local low = math.min(zone.loot_min, zone.loot_max)
    local high = math.max(zone.loot_min, zone.loot_max)
    local amount = low >= high and low or math.random(low, high)

    if amount > 0 then
        xPlayer.addAccountMoney("black_money", amount, "fouille d'un zombie")
    end

    TriggerClientEvent("zombie:lootResult", source, amount)
end)
