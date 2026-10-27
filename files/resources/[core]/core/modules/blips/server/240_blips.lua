local blipsList = {}
local loaded = false
local nextId = 1
local JSON_FILE = "config/custom_blips.json"

VFW.Blips = VFW.Blips or {}

local function toBlipData(row)
    return {
        position = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0 },
        label = row.label,
        sprite = row.sprite or 1,
        color = row.color or 0,
        scale = (row.scale or 0.5) + 0.0,
    }
end

local function sanitize(data)
    if type(data) ~= "table" then return nil end

    local position = data.position or data.positions or data.coords
    if type(position) ~= "table" then return nil end

    local x, y, z = tonumber(position.x), tonumber(position.y), tonumber(position.z)
    if not x or not y or not z then return nil end

    local label = data.label or data.nom or data.name
    if type(label) ~= "string" or label == "" then return nil end

    local sprite = math.floor(tonumber(data.sprite) or 1)
    local color = math.floor(tonumber(data.color or data.couleur) or 0)
    local scale = tonumber(data.scale or data.taille) or 0.5

    if sprite < 0 then sprite = 1 end
    if color < 0 then color = 0 end
    if scale <= 0.0 then scale = 0.5 end
    if scale > 3.0 then scale = 3.0 end

    return {
        position = { x = x, y = y, z = z },
        label = label:sub(1, 64),
        sprite = sprite,
        color = color,
        scale = scale + 0.0,
    }
end

function VFW.Blips.GetAll()
    return blipsList
end

function VFW.Blips.Get(blipId)
    return blipsList[tostring(blipId)]
end

function VFW.Blips.SyncTo(source)
    source = tonumber(source)
    if not source or source <= 0 then return end
    TriggerClientEvent("blips:retrieve:list", source, blipsList)
end

function VFW.Blips.SyncAll()
    TriggerClientEvent("blips:retrieve:list", -1, blipsList)
end

local function ensureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `blips` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(64) NOT NULL,
            `sprite` INT NOT NULL DEFAULT 1,
            `color` INT NOT NULL DEFAULT 0,
            `scale` FLOAT NOT NULL DEFAULT 0.8,
            `x` DOUBLE NOT NULL,
            `y` DOUBLE NOT NULL,
            `z` DOUBLE NOT NULL,
            `created_by` VARCHAR(80) NOT NULL DEFAULT '',
            PRIMARY KEY (`id`)
        )
    ]])
end

local IMPORTED_FLAG <const> = "blips_file_imported"

local function saveJson()
    local body = json.encode({ nextId = nextId, blips = blipsList })
    return SaveResourceFile(GetCurrentResourceName(), JSON_FILE, body, -1) == true
end

function VFW.Blips.Create(data, createdBy)
    local blipData = sanitize(data)
    if not blipData then return nil end

    local key = tostring(nextId)
    nextId = nextId + 1
    blipsList[key] = blipData
    saveJson()

    pcall(function()
        ensureTable()
        MySQL.insert.await(
            "INSERT INTO `blips` (`id`, `label`, `sprite`, `color`, `scale`, `x`, `y`, `z`, `created_by`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            {
                tonumber(key),
                blipData.label,
                blipData.sprite,
                blipData.color,
                blipData.scale,
                blipData.position.x,
                blipData.position.y,
                blipData.position.z,
                type(createdBy) == "string" and createdBy:sub(1, 80) or "",
            }
        )
    end)

    TriggerClientEvent("blips:add:list", -1, key, blipData)
    TriggerEvent("vfw:blips:created", key, blipData)

    return key
end

function VFW.Blips.Update(blipId, data)
    local key = tostring(blipId)
    local current = blipsList[key]
    if not current then return false end

    local merged = {
        position = current.position,
        label = current.label,
        sprite = current.sprite,
        color = current.color,
        scale = current.scale,
    }

    if type(data) == "table" then
        local incoming = sanitize({
            position = data.position or data.positions or data.coords or current.position,
            label = data.label or data.nom or data.name or current.label,
            sprite = data.sprite or current.sprite,
            color = data.color or data.couleur or current.color,
            scale = data.scale or data.taille or current.scale,
        })
        if not incoming then return false end
        merged = incoming
    end

    pcall(function()
        MySQL.update.await(
            "UPDATE `blips` SET `label` = ?, `sprite` = ?, `color` = ?, `scale` = ?, `x` = ?, `y` = ?, `z` = ? WHERE `id` = ?",
            {
                merged.label,
                merged.sprite,
                merged.color,
                merged.scale,
                merged.position.x,
                merged.position.y,
                merged.position.z,
                tonumber(blipId),
            }
        )
    end)

    blipsList[key] = merged
    saveJson()

    TriggerClientEvent("blips:update:list", -1, key, merged)
    TriggerEvent("vfw:blips:updated", key, merged)

    return true
end

function VFW.Blips.Remove(blipId)
    local key = tostring(blipId)
    if not blipsList[key] then return false end

    pcall(function()
        MySQL.update.await("DELETE FROM `blips` WHERE `id` = ?", { tonumber(blipId) })
    end)

    blipsList[key] = nil
    saveJson()

    TriggerClientEvent("blips:remove:list", -1, key)
    TriggerEvent("vfw:blips:removed", key)

    return true
end

local function insertBlipRow(id, blipData, createdBy)
    return MySQL.insert.await(
        "INSERT INTO `blips` (`id`, `label`, `sprite`, `color`, `scale`, `x`, `y`, `z`, `created_by`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        { id, blipData.label, blipData.sprite, blipData.color, blipData.scale, blipData.position.x, blipData.position.y, blipData.position.z, createdBy or "" }
    )
end

--- La base fait foi.
---
--- Avant, les blips etaient lus dans config/custom_blips.json PUIS completes par la base, et
--- un blip cree n'arrivait jamais en base (voir ensureTable plus haut) : tout reposait sur le
--- fichier, qui disparait quand le dossier `core` est remplace en entier.
---
--- Maintenant la base est lue en premier ; le fichier est repris UNE SEULE FOIS, pour les
--- serveurs dont les blips n'existent que dedans : ceux qui manquent en base y sont ajoutes,
--- puis la base seule decide. Un fichier arrive plus tard avec une mise a jour est ignore.
local function importFile()
    local flagged = VFW.Variables and VFW.Variables.GetVariable and VFW.Variables.GetVariable(IMPORTED_FLAG)
    if type(flagged) == "table" and flagged.done == true then return 0 end
    if not (VFW.Variables and VFW.Variables.Loaded == true) then return 0 end

    local fromFile = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), JSON_FILE)
    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" and type(decoded.blips) == "table" then fromFile = decoded.blips end
    end

    local added = 0
    for key, stored in pairs(fromFile) do
        local blipData = sanitize(stored)
        local id = tonumber(key)
        if blipData and id and not blipsList[tostring(id)] then
            local ok = pcall(insertBlipRow, id, blipData, "import")
            if ok then
                blipsList[tostring(id)] = blipData
                if id >= nextId then nextId = id + 1 end
                added = added + 1
            end
        end
    end

    VFW.Variables.SetVariable(IMPORTED_FLAG, { done = true })
    if VFW.Variables.Flush then pcall(VFW.Variables.Flush, IMPORTED_FLAG) end
    return added
end

local function load()
    local ok, rows = pcall(function()
        ensureTable()
        return MySQL.query.await("SELECT * FROM `blips`") or {}
    end)
    rows = (ok and rows) or {}

    blipsList = {}
    for i = 1, #rows do
        local key = tostring(rows[i].id)
        blipsList[key] = toBlipData(rows[i])
        local n = tonumber(key)
        if n and n >= nextId then nextId = n + 1 end
    end

    loaded = true
    console.init("Blips", ("%d blips serveur charges"):format(#rows))
    if not ok then return end

    -- Reprise du fichier : il faut que les variables soient lues pour savoir si c'est deja fait.
    local waited = 0
    while not (VFW.Variables and VFW.Variables.Loaded == true) and waited < 120 do
        Wait(250)
        waited = waited + 1
    end
    local imported = importFile()
    if imported > 0 then
        console.init("Blips", ("%d blips repris de config/custom_blips.json et enregistres en base"):format(imported))
        VFW.Blips.SyncAll()
    end
    saveJson()
end

AddEventHandler("vfw:characterLoaded", function(source)
    if not loaded then return end
    VFW.Blips.SyncTo(source)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    if not loaded then return end
    VFW.Blips.SyncTo(source)
end)

RegisterNetEvent("blips:request:list", function()
    if not loaded then return end
    VFW.Blips.SyncTo(source)
end)

AddEventHandler("vfw:blips:register", function(data, createdBy)
    VFW.Blips.Create(data, createdBy)
end)

local function staffPlayer(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission then return nil end
    if xPlayer.hasPermission("manage_blips")
        or xPlayer.hasPermission("builder_menu")
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
        or xPlayer.hasPermission("staff_menu") then
        return xPlayer
    end
    return nil
end

local function publicList()
    local out = {}
    for id, blip in pairs(blipsList) do
        out[#out + 1] = {
            id = tonumber(id),
            label = blip.label,
            sprite = blip.sprite,
            color = blip.color,
            scale = blip.scale,
            position = blip.position,
            active = true,
            whitelistType = "global",
            whitelistValues = {},
        }
    end
    table.sort(out, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return out
end

RegisterServerCallback("core:createBlip", function(source, data)
    local xPlayer = staffPlayer(source)
    if not xPlayer then
        return { ok = false, error = "Permission refusée." }
    end
    if type(data) ~= "table" then
        return { ok = false, error = "Données invalides." }
    end
    local key = VFW.Blips.Create(data, xPlayer.identifier)
    if not key then
        return { ok = false, error = "Nom ou position manquant." }
    end
    return { ok = true, id = key, blip = blipsList[key] }
end)

RegisterNetEvent("core:updateBlip", function(blipId, data)
    local xPlayer = staffPlayer(source)
    if not xPlayer then return end
    local ok = VFW.Blips.Update(blipId, data)
    xPlayer.showNotification({
        type = "STAFF",
        variant = ok and "SUCCESS" or "ERROR",
        subtitle = "Blips",
        message = ok and "Blip mis à jour." or "Blip introuvable.",
    })
end)

RegisterNetEvent("core:deleteBlip", function(blipId)
    local xPlayer = staffPlayer(source)
    if not xPlayer then return end
    local ok = VFW.Blips.Remove(blipId)
    xPlayer.showNotification({
        type = "STAFF",
        variant = ok and "SUCCESS" or "ERROR",
        subtitle = "Blips",
        message = ok and "Blip supprimé." or "Blip introuvable.",
    })
end)

RegisterNetEvent("core:toggleBlip", function(blipId, active)
    local xPlayer = staffPlayer(source)
    if not xPlayer then return end
    if active == false then
        TriggerClientEvent("blips:remove:list", -1, tostring(blipId))
    else
        local blip = VFW.Blips.Get(blipId)
        if blip then
            TriggerClientEvent("blips:add:list", -1, tostring(blipId), blip)
        end
    end
end)

RegisterServerCallback("core:getAllBlips", function(source)
    if not staffPlayer(source) then return {} end
    return publicList()
end)

RegisterServerCallback("core:blips:getAllJobs", function(source)
    if not staffPlayer(source) then return {} end
    local ok, rows = pcall(function()
        return MySQL.query.await("SELECT name, label FROM jobs ORDER BY label ASC")
    end)
    return (ok and rows) or {}
end)

RegisterServerCallback("core:blips:getAllFactions", function(source)
    if not staffPlayer(source) then return {} end
    local ok, rows = pcall(function()
        return MySQL.query.await("SELECT name, label FROM factions ORDER BY label ASC")
    end)
    return (ok and rows) or {}
end)

MySQL.ready(function()
    local ok, err = pcall(load)
    if not ok then
        console.error(("[Blips] chargement impossible : %s"):format(tostring(err)))
        loaded = true
    end
end)

CreateThread(function()
    local tries = 0
    while not VFW.RegisterCommand and tries < 200 do
        Wait(250)
        tries = tries + 1
    end
    if not VFW.RegisterCommand then return end

    Wait(1000)

    local existing = VFW.GetRegisteredCommands and VFW.GetRegisteredCommands() or {}

    if not existing["blipadd"] then
        VFW.RegisterCommand("blipadd", "manage_blips", function(source, xPlayer, args)
            if not xPlayer then return end

            local label = table.concat(args, " ", 4)
            local coords = xPlayer.getCoords(false)

            local key = VFW.Blips.Create({
                position = coords,
                label = label,
                sprite = tonumber(args[1]),
                color = tonumber(args[2]),
                scale = tonumber(args[3]),
            }, xPlayer.identifier)

            xPlayer.showNotification({
                type = "STAFF",
                variant = key and "SUCCESS" or "ERROR",
                subtitle = "Blips",
                message = key and ("Blip #%s cree."):format(key) or "Usage : /blipadd <sprite> <couleur> <taille> <nom>",
            })
        end, {
            help = "Cree un blip serveur persistant a votre position.",
            params = {
                { name = "sprite", help = "Identifiant du sprite" },
                { name = "couleur", help = "Identifiant de couleur" },
                { name = "taille", help = "Echelle (0.1 - 3.0)" },
                { name = "nom", help = "Nom affiche" },
            },
        })
    end

    if not existing["blipdel"] then
        VFW.RegisterCommand("blipdel", "manage_blips", function(source, xPlayer, args)
            if not xPlayer then return end

            local blipId = tonumber(args[1])
            local removed = blipId and VFW.Blips.Remove(blipId) or false

            xPlayer.showNotification({
                type = "STAFF",
                variant = removed and "SUCCESS" or "ERROR",
                subtitle = "Blips",
                message = removed and ("Blip #%d supprime."):format(blipId) or "Blip introuvable.",
            })
        end, {
            help = "Supprime un blip serveur persistant.",
            params = { { name = "id", help = "Identifiant du blip" } },
        })
    end

    if not existing["bliplist"] then
        VFW.RegisterCommand("bliplist", "manage_blips", function(source, xPlayer)
            local count = 0
            for key, blip in pairs(blipsList) do
                count = count + 1
                console.info(("[Blips] #%s %s sprite=%d couleur=%d taille=%.2f (%.2f, %.2f, %.2f)"):format(
                    key, blip.label, blip.sprite, blip.color, blip.scale,
                    blip.position.x, blip.position.y, blip.position.z))
            end

            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "INFO",
                    subtitle = "Blips",
                    message = ("%d blips serveur (details en console)."):format(count),
                })
            end
        end, { help = "Liste les blips serveur persistants.", allowConsole = true })
    end
end)
