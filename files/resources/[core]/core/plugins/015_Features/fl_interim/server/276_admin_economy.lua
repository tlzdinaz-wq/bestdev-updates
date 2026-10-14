---@meta _
---@diagnostic disable: duplicate-doc-field

-- Économie intérim : points d'entrée du menu staff.
--
-- Le menu « ÉCONOMIE INTÉRIM » appelait `interim:admin:getEconomyConfig` et
-- `interim:admin:setPrice`. Aucun des deux n'avait jamais été écrit : le callback expirait,
-- le menu recevait nil et affichait « Impossible de charger les données ». Les gains des
-- quatre métiers intérim n'ont donc jamais été réglables en jeu.
--
-- Les montants vivent dans la configuration de chaque métier (`interim_job_config`, avec
-- repli sur les valeurs d'origine). On les lit et on les réécrit par là, sans toucher au
-- reste de la configuration.

local PERM <const> = "builder_interim_economy"

--- Les montants modifiables, métier par métier.
---
--- Chaque entrée dit où lire et où écrire : une clef simple pour un prix unique, ou la
--- liste des minerais pour le mineur, dont le prix est porté par chaque minerai.
local JOBS <const> = {
    { id = "lumberjack", label = "Bûcheron" },
    { id = "mineur", label = "Mineur" },
    { id = "pizza", label = "Livreur de pizzas" },
    { id = "routier", label = "Routier" },
}

local SIMPLE_PRICES <const> = {
    lumberjack = { { key = "sellPrice", label = "Vente d'une planche", default = 250 } },
    pizza = { { key = "payPerDelivery", label = "Paiement par livraison", default = 180 } },
    routier = { { key = "reward", label = "Paiement d'une livraison", default = 950 } },
}

local function itemLabel(name, fallback)
    local item = VFW.Items and VFW.Items[name]
    if item and type(item.label) == "string" and item.label ~= "" then return item.label end
    return fallback or name
end

--- Copie en profondeur.
---
--- `InterimServer.GetConfig` rend la table des valeurs d'origine quand rien n'est encore
--- enregistré : la modifier en place changerait les valeurs par défaut du serveur pour
--- toute sa durée de vie.
local function deepCopy(value)
    if type(value) ~= "table" then return value end

    local out = {}
    for k, v in pairs(value) do out[k] = deepCopy(v) end
    return out
end

local function priceRows(jobId, config)
    local rows = {}

    for _, entry in ipairs(SIMPLE_PRICES[jobId] or {}) do
        rows[#rows + 1] = {
            key = entry.key,
            label = entry.label,
            value = math.floor(tonumber(config[entry.key]) or entry.default),
        }
    end

    if jobId == "mineur" then
        for _, ore in ipairs(config.ores or {}) do
            if type(ore) == "table" and ore.clean then
                rows[#rows + 1] = {
                    key = "ores." .. ore.clean,
                    label = "Vente — " .. itemLabel(ore.clean),
                    value = math.floor(tonumber(ore.price) or 0),
                }
            end
        end
    end

    return rows
end

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(PERM)
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

RegisterServerCallback("interim:admin:getEconomyConfig", function(source)
    if not staffOk(source) then
        return { success = false, message = "Permission refusée." }
    end

    local jobs = {}
    for _, job in ipairs(JOBS) do
        local config = InterimServer.GetConfig(job.id) or {}
        jobs[#jobs + 1] = {
            id = job.id,
            label = job.label,
            items = priceRows(job.id, config),
        }
    end

    return {
        success = true,
        jobs = jobs,
        -- Aucun multiplicateur VIP sur les gains intérim dans la base : le menu n'affiche
        -- alors que le montant de base, ce qu'il sait faire.
        vipMultipliers = {},
    }
end)

RegisterServerCallback("interim:admin:setPrice", function(source, payload)
    if not staffOk(source) then
        return { success = false, message = "Permission refusée." }
    end
    if type(payload) ~= "table" then
        return { success = false, message = "Données invalides." }
    end

    local jobId = tostring(payload.jobId or "")
    local key = tostring(payload.key or "")
    local value = math.floor(tonumber(payload.value) or -1)

    if value < 0 or value > 10000000 then
        return { success = false, message = "Montant refusé." }
    end

    local known = false
    for _, job in ipairs(JOBS) do
        if job.id == jobId then known = true break end
    end
    if not known then
        return { success = false, message = "Métier inconnu." }
    end

    local config = deepCopy(InterimServer.GetConfig(jobId)) or {}

    local ore = key:match("^ores%.(.+)$")
    if ore then
        local found = false
        for _, entry in ipairs(config.ores or {}) do
            if type(entry) == "table" and entry.clean == ore then
                entry.price = value
                found = true
                break
            end
        end
        if not found then
            return { success = false, message = "Minerai inconnu." }
        end
    else
        local allowed = false
        for _, entry in ipairs(SIMPLE_PRICES[jobId] or {}) do
            if entry.key == key then allowed = true break end
        end
        if not allowed then
            return { success = false, message = "Montant inconnu pour ce métier." }
        end
        config[key] = value
    end

    if not InterimServer.SaveConfig(jobId, config) then
        return { success = false, message = "Enregistrement impossible." }
    end

    return { success = true }
end)
