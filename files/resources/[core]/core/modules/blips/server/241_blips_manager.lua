---@meta _
---@diagnostic disable: duplicate-doc-field

-- Pont entre le menu « BLIPS » du staff et le module de blips serveur.
--
-- Le menu (plugins/015_Features/client/staff/menu/blips.lua) appelle sept points d'entrée
-- serveur — liste, création, modification, suppression, activation, et les listes de jobs et
-- de factions pour la whitelist. Aucun d'eux n'avait été écrit : la liste des blips arrivait
-- donc toujours vide, et les boutons Modifier et Supprimer ne faisaient rien.
--
-- Le menu gère aussi deux notions absentes de la table d'origine, `active` et la whitelist
-- (global / job / faction) : les colonnes sont ajoutées ici au démarrage.

local MANAGE_PERM = "manage_blips"

local function sqlQuery(query, params)
    local ok, result = pcall(MySQL.query.await, query, params or {})
    if not ok then
        console.error(("[Blips] requête échouée : %s"):format(tostring(result)))
        return nil
    end
    return result
end

local function sqlExec(query, params)
    local ok, result = pcall(MySQL.update.await, query, params or {})
    if not ok then
        console.error(("[Blips] requête échouée : %s"):format(tostring(result)))
        return nil
    end
    return result
end

--- Colonnes ajoutées par le menu de gestion. Absentes de la table d'origine.
local function ensureColumns()
    local columns = sqlQuery("SHOW COLUMNS FROM blips") or {}
    local present = {}
    for i = 1, #columns do present[columns[i].Field] = true end

    if not present.active then
        sqlExec("ALTER TABLE blips ADD COLUMN `active` TINYINT(1) NOT NULL DEFAULT 1")
    end
    if not present.whitelist_type then
        sqlExec("ALTER TABLE blips ADD COLUMN `whitelist_type` VARCHAR(16) NOT NULL DEFAULT 'global'")
    end
    if not present.whitelist_values then
        sqlExec("ALTER TABLE blips ADD COLUMN `whitelist_values` LONGTEXT DEFAULT NULL")
    end
end

local function staff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission(MANAGE_PERM) then return nil end
    return xPlayer
end

local function decodeList(raw)
    if type(raw) ~= "string" or raw == "" then return {} end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then return decoded end
    return {}
end

local WL_TYPES = { global = true, job = true, faction = true }

local function wlType(value)
    if type(value) == "number" then
        return ({ "global", "job", "faction" })[value] or "global"
    end
    if type(value) == "string" and WL_TYPES[value] then return value end
    return "global"
end

--- Tous les blips, dans la forme attendue par le menu.
---@return table[]
local function allBlips()
    local rows = sqlQuery([[
        SELECT id, label, sprite, color, scale, x, y, z, active, whitelist_type, whitelist_values
        FROM blips ORDER BY id ASC
    ]]) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            id = row.id,
            label = row.label,
            sprite = row.sprite,
            color = row.color,
            scale = (row.scale or 0.5) + 0.0,
            position = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0 },
            active = tonumber(row.active) ~= 0,
            whitelistType = row.whitelist_type or "global",
            whitelistValues = decodeList(row.whitelist_values),
        }
    end

    return out
end

--- Renvoie à chaque joueur les blips qui le concernent (actifs + whitelist).
function VFW.Blips.SyncManaged(target)
    local rows = allBlips()

    local function visibleFor(xPlayer)
        local list = {}

        for i = 1, #rows do
            local blip = rows[i]
            local show = blip.active

            if show and blip.whitelistType == "job" then
                local jobName = xPlayer and xPlayer.job and xPlayer.job.name
                show = jobName ~= nil and #blip.whitelistValues > 0
                    and (function()
                        for _, value in ipairs(blip.whitelistValues) do
                            if value == jobName then return true end
                        end
                        return false
                    end)()
            elseif show and blip.whitelistType == "faction" then
                local faction = xPlayer and xPlayer.job2 and xPlayer.job2.name
                show = faction ~= nil and #blip.whitelistValues > 0
                    and (function()
                        for _, value in ipairs(blip.whitelistValues) do
                            if value == faction then return true end
                        end
                        return false
                    end)()
            end

            if show then
                list[tostring(blip.id)] = {
                    position = blip.position,
                    label = blip.label,
                    sprite = blip.sprite,
                    color = blip.color,
                    scale = blip.scale,
                }
            end
        end

        return list
    end

    if target then
        local xPlayer = VFW.GetPlayerFromId(target)
        TriggerClientEvent("blips:retrieve:list", target, visibleFor(xPlayer))
        return
    end

    for src, xPlayer in pairs(VFW.Players) do
        TriggerClientEvent("blips:retrieve:list", src, visibleFor(xPlayer))
    end
end

-- ── Points d'entrée du menu ────────────────────────────────────────────────────────────

RegisterServerCallback("core:getAllBlips", function(source)
    if not staff(source) then return {} end
    return allBlips()
end)

RegisterServerCallback("core:blips:getAllJobs", function(source)
    if not staff(source) then return {} end

    local out = {}
    for name, job in pairs(VFW.Jobs or {}) do
        if type(job) == "table" and job.name == name and name ~= "unemployed" then
            out[#out + 1] = { name = name, label = job.label or name }
        end
    end

    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)

RegisterServerCallback("core:blips:getAllFactions", function(source)
    if not staff(source) then return {} end

    local rows = sqlQuery("SELECT name, label FROM factions ORDER BY label ASC") or {}
    local out = {}
    for i = 1, #rows do
        out[i] = { name = rows[i].name, label = rows[i].label or rows[i].name }
    end
    return out
end)

RegisterNetEvent("core:createBlip", function(data)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer or type(data) ~= "table" then return end

    local position = data.position or data.coords
    if type(position) ~= "table" or not tonumber(position.x) then return end

    local id = sqlExec([[
        INSERT INTO blips (label, sprite, color, scale, x, y, z, created_by, active, whitelist_type, whitelist_values)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    ]], {
        tostring(data.label or "Blip"):sub(1, 100),
        math.floor(tonumber(data.sprite) or 1),
        math.floor(tonumber(data.color) or 0),
        (tonumber(data.scale) or 0.8) + 0.0,
        tonumber(position.x) + 0.0,
        tonumber(position.y) + 0.0,
        tonumber(position.z) + 0.0,
        xPlayer.identifier,
        wlType(data.whitelistType),
        json.encode(type(data.whitelistValues) == "table" and data.whitelistValues or {}),
    })

    VFW.Blips.SyncManaged()

    xPlayer.showNotification({
        type = "STAFF", variant = id and "SUCCESS" or "ERROR", subtitle = "Blips",
        message = id and "Blip créé." or "Création impossible.",
    })
end)

RegisterNetEvent("core:updateBlip", function(blipId, data)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer or type(data) ~= "table" then return end

    local id = tonumber(blipId)
    if not id then return end

    local position = data.position or data.coords
    if type(position) ~= "table" or not tonumber(position.x) then return end

    sqlExec([[
        UPDATE blips SET label = ?, sprite = ?, color = ?, scale = ?, x = ?, y = ?, z = ?,
            whitelist_type = ?, whitelist_values = ?
        WHERE id = ?
    ]], {
        tostring(data.label or "Blip"):sub(1, 100),
        math.floor(tonumber(data.sprite) or 1),
        math.floor(tonumber(data.color) or 0),
        (tonumber(data.scale) or 0.8) + 0.0,
        tonumber(position.x) + 0.0,
        tonumber(position.y) + 0.0,
        tonumber(position.z) + 0.0,
        wlType(data.whitelistType),
        json.encode(type(data.whitelistValues) == "table" and data.whitelistValues or {}),
        id,
    })

    VFW.Blips.SyncManaged()

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Blips", message = "Blip modifié.",
    })
end)

RegisterNetEvent("core:deleteBlip", function(blipId)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local id = tonumber(blipId)
    if not id then return end

    sqlExec("DELETE FROM blips WHERE id = ?", { id })
    VFW.Blips.SyncManaged()

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Blips", message = "Blip supprimé.",
    })
end)

RegisterNetEvent("core:toggleBlip", function(blipId, active)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local id = tonumber(blipId)
    if not id then return end

    sqlExec("UPDATE blips SET active = ? WHERE id = ?", { active and 1 or 0, id })
    VFW.Blips.SyncManaged()
end)

-- ── Chargement ─────────────────────────────────────────────────────────────────────────

-- Blips de ville livrés avec la base. Ils étaient créés en dur côté client
-- (plugins/015_Features/client/point_interaction.lua) : impossibles à déplacer, à renommer
-- ou à retirer depuis le menu. On les sème une seule fois dans la table, après quoi ils
-- deviennent des blips ordinaires, modifiables et supprimables comme les autres.
local CITY_BLIPS = {
    { -805.83, -1354.64, 4.18, 404, 47, "HeliWave" },
    { -296.41, -106.34, 46.05, 267, 1, "Pawnshop" },
    { -1096.03, -837.89, 18.33, 60, 0, "LSPD VP" },
    { 440.13, -982.43, 29.69, 60, 0, "LSPD MR" },
    { 1816.87, 3672.44, 33.71, 137, 0, "LSSD Sandy" },
    { -466.32, 7086.44, 21.38, 137, 0, "LSSD Paleto" },
    { 344.26, -587.68, 27.78, 61, 0, "SAMS Pillbox" },
    { -509.52, 7364.57, 11.84, 61, 0, "SAMS Paleto" },
    { 2542.17, -381.82, 91.99, 419, 0, "USSS" },
    { -1039.92, -1400.68, 4.08, 436, 1, "LSFD" },
    { -429.58, 7071.68, 20.68, 436, 1, "LSFD Paleto" },
    { -552.28, -191.53, 37.22, 419, 0, "Gouvernement" },
    { 232.75, -418.38, 47.1, 419, 0, "DOJ" },
    { -719.4, -1325.9, 0.6, 356, 3, "Garage Bateaux" },
}

local SEED_MARK = "base_city"

local function seedCityBlips()
    local existing = sqlQuery("SELECT COUNT(*) AS total FROM blips WHERE created_by = ?", { SEED_MARK })
    if existing and existing[1] and tonumber(existing[1].total) and tonumber(existing[1].total) > 0 then
        return 0
    end

    -- Déjà semés puis supprimés par le staff : on ne les remet pas.
    local flag = sqlQuery("SELECT data FROM variables WHERE name = ?", { "blips_city_seeded" })
    if flag and flag[1] then return 0 end

    for i = 1, #CITY_BLIPS do
        local blip = CITY_BLIPS[i]
        sqlExec([[
            INSERT INTO blips (label, sprite, color, scale, x, y, z, created_by, active, whitelist_type, whitelist_values)
            VALUES (?, ?, ?, 0.8, ?, ?, ?, ?, 1, 'global', '[]')
        ]], { blip[6], blip[4], blip[5], blip[1], blip[2], blip[3], SEED_MARK })
    end

    sqlExec("INSERT INTO variables (name, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)",
        { "blips_city_seeded", "1" })

    return #CITY_BLIPS
end

MySQL.ready(function()
    local ok, err = pcall(ensureColumns)
    if not ok then
        console.error(("[Blips] colonnes de gestion non ajoutées : %s"):format(tostring(err)))
        return
    end

    local seeded = 0
    local seedOk, seedErr = pcall(function() seeded = seedCityBlips() end)
    if not seedOk then
        console.warn(("[Blips] blips de ville non semés : %s"):format(tostring(seedErr)))
    elseif seeded > 0 then
        console.info(("[Blips] %d blips de ville repris en base (modifiables depuis le menu)."):format(seeded))
    end

    console.init("Blips", "gestion staff prête")
end)

AddEventHandler("vfw:characterLoaded", function(source)
    SetTimeout(1500, function() VFW.Blips.SyncManaged(source) end)
end)
