-- Configuration des chaises : pour chaque modèle d'objet, les animations d'assise permises, les places (une
-- par personne sur un canapé ou un banc) et le gel du prop. Le staff la règle depuis Builders > CHAISES ASSISES
-- (client/staff/menu/builderChairs.lua) ; chaque joueur la reçoit à la connexion et à chaque changement
-- (événement chairConfig:sync) et la pousse dans object_context_menu.lua.
--
-- Ce fichier manquait : le menu appelait chairConfig:save, chairConfig:delete et chairConfig:getAll sans que
-- personne ne réponde, d'où « Erreur : inconnue » à chaque sauvegarde et aucune chaise jamais configurée.
-- (La réservation d'une place, chairSlot:claim / chairSlot:release, est dans misc_b/34_06_misc_direct.lua.)

local PERMISSIONS = { "manage_chairs", "dev" }

local TABLE_SQL = [[
    CREATE TABLE IF NOT EXISTS `chair_config` (
        `model_hash` BIGINT NOT NULL,
        `archetype_name` VARCHAR(100) NOT NULL DEFAULT '',
        `z_adjust` FLOAT NOT NULL DEFAULT 0,
        `allowed_anims` LONGTEXT NULL,
        `sit_position` LONGTEXT NULL,
        `frozen` TINYINT(1) NOT NULL DEFAULT 0,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`model_hash`)
    )
]]

-- Clés d'animation connues (les mêmes que builderChairs.lua et object_context_menu.lua) : tout le reste est ignoré.
local ANIM_KEYS = {
    "normale", "focus", "Pensif", "Brasdecôté", "Brascroisés", "Regardantenbas",
    "allonge", "allongecote", "allongesurdos", "fetale",
}

local MAX_SLOTS = 12
local MAX_OFFSET = 10.0
local MAX_Z_ADJUST = 5.0
local MAX_NAME = 100

local configs = {}   -- [model_hash] = { archetype_name, z_adjust, allowed_anims, sit_position, frozen }
local loaded = false

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end

--- Ce que reçoivent les joueurs : la table complète, indexée par le hash numérique du modèle.
local function snapshot()
    return copy(configs)
end

local function broadcast()
    TriggerClientEvent("chairConfig:sync", -1, snapshot())
end

local function allowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    for i = 1, #PERMISSIONS do
        if xPlayer.hasPermission(PERMISSIONS[i]) then return xPlayer end
    end
    return nil
end

local function rateOk(source, key, ms)
    if Feat27 and Feat27.RateLimit then return Feat27.RateLimit(source, key, ms) end
    return true
end

-- ── nettoyage de ce que le client envoie ──

local function cleanHash(value)
    local n = tonumber(value)
    if not n or n ~= math.floor(n) then return nil end
    if n < -2147483648 or n > 4294967295 then return nil end
    return math.floor(n)
end

local function cleanName(value)
    if type(value) ~= "string" then return "" end
    value = value:gsub("%c", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return value:sub(1, MAX_NAME)
end

local function cleanNumber(value, limit)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    if n > limit then n = limit elseif n < -limit then n = -limit end
    return n + 0.0
end

--- Animations permises : seulement les clés connues, valeur vraie. Rien (ou n'importe quoi) = toutes permises.
local function cleanAnims(value)
    local out, count = {}, 0
    if type(value) == "table" then
        for i = 1, #ANIM_KEYS do
            if value[ANIM_KEYS[i]] == true then
                out[ANIM_KEYS[i]] = true
                count = count + 1
            end
        end
    end
    if count == 0 then
        for i = 1, #ANIM_KEYS do out[ANIM_KEYS[i]] = true end
    end
    return out
end

--- Places : liste de décalages {x, y, z, h} par rapport au prop. Un objet unique {x=…} (ancien format) devient une liste.
local function cleanSlots(value)
    if type(value) ~= "table" then return nil end
    if value.x ~= nil then value = { value } end

    local out = {}
    for i = 1, #value do
        local slot = value[i]
        if #out >= MAX_SLOTS then break end
        if type(slot) == "table" then
            local x = cleanNumber(slot.x, MAX_OFFSET)
            local y = cleanNumber(slot.y, MAX_OFFSET)
            local z = cleanNumber(slot.z, MAX_OFFSET)
            local h = cleanNumber(slot.h, 3600.0)
            if x and y and z then
                out[#out + 1] = { x = x, y = y, z = z, h = h or 0.0 }
            end
        end
    end

    if #out == 0 then return nil end
    return out
end

-- ── base de données ──

local function loadAll()
    local ok, rows = pcall(MySQL.query.await, "SELECT * FROM chair_config")
    if not ok or type(rows) ~= "table" then
        console.warn("[chaises] lecture de chair_config impossible : " .. tostring(rows))
        return false
    end

    local list = {}
    for i = 1, #rows do
        local row = rows[i]
        local hash = cleanHash(row.model_hash)
        if hash then
            local anims = VFW.DB.Decode(row.allowed_anims, nil)
            local slots = VFW.DB.Decode(row.sit_position, nil)
            list[hash] = {
                archetype_name = cleanName(row.archetype_name),
                z_adjust = tonumber(row.z_adjust) or 0.0,
                allowed_anims = cleanAnims(anims),
                sit_position = cleanSlots(slots),
                frozen = VFW.DB.IsSet(row.frozen),
            }
        end
    end

    configs = list
    loaded = true
    return true
end

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    local ok, err = pcall(MySQL.query.await, TABLE_SQL)
    if not ok then
        console.error("[chaises] table chair_config impossible à créer : " .. tostring(err))
        return
    end
    if loadAll() then broadcast() end
end)

-- ── callbacks ──

RegisterServerCallback("chairConfig:getAll", function()
    return snapshot()
end)

RegisterServerCallback("chairConfig:save", function(source, data)
    if not allowed(source) then return { success = false, error = "Permission refusée." } end
    if type(data) ~= "table" then return { success = false, error = "Données invalides." } end
    if not rateOk(source, "chairConfig:save", 500) then return { success = false, error = "Trop rapide, réessayez." } end

    local hash = cleanHash(data.model_hash)
    if not hash then return { success = false, error = "Aucune chaise sélectionnée." } end

    local entry = {
        archetype_name = cleanName(data.archetype_name),
        z_adjust = cleanNumber(data.z_adjust, MAX_Z_ADJUST) or 0.0,
        allowed_anims = cleanAnims(data.allowed_anims),
        sit_position = cleanSlots(data.sit_position),
        frozen = data.frozen == true,
    }

    local ok, err = pcall(MySQL.query.await, [[
        INSERT INTO chair_config (model_hash, archetype_name, z_adjust, allowed_anims, sit_position, frozen)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            archetype_name = VALUES(archetype_name), z_adjust = VALUES(z_adjust),
            allowed_anims = VALUES(allowed_anims), sit_position = VALUES(sit_position), frozen = VALUES(frozen)
    ]], {
        hash,
        entry.archetype_name,
        entry.z_adjust,
        json.encode(entry.allowed_anims),
        -- jamais nil dans la liste des paramètres (un trou fausserait sa longueur) : « [] » = aucune place
        entry.sit_position and json.encode(entry.sit_position) or "[]",
        entry.frozen and 1 or 0,
    })

    if not ok then
        console.error("[chaises] sauvegarde impossible : " .. tostring(err))
        return { success = false, error = "Écriture en base impossible (voir la console)." }
    end

    configs[hash] = entry
    broadcast()
    return { success = true }
end)

RegisterServerCallback("chairConfig:delete", function(source, modelHash)
    if not allowed(source) then return { success = false, error = "Permission refusée." } end
    if not rateOk(source, "chairConfig:save", 500) then return { success = false, error = "Trop rapide, réessayez." } end

    local hash = cleanHash(modelHash)
    if not hash then return { success = false, error = "Aucune chaise sélectionnée." } end

    local ok, err = pcall(MySQL.query.await, "DELETE FROM chair_config WHERE model_hash = ?", { hash })
    if not ok then
        console.error("[chaises] suppression impossible : " .. tostring(err))
        return { success = false, error = "Suppression en base impossible (voir la console)." }
    end

    configs[hash] = nil
    broadcast()
    return { success = true }
end)

-- Un joueur qui se connecte reçoit la configuration sans attendre sa demande (qui peut arriver avant le chargement).
AddEventHandler("vfw:characterLoaded", function(source)
    if loaded then TriggerClientEvent("chairConfig:sync", source, snapshot()) end
end)
