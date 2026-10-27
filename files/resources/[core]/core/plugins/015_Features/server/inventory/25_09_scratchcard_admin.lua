---@meta _
---@diagnostic disable: duplicate-doc-field

-- Tickets à gratter : points d'entrée du menu staff.
--
-- Le builder appelait `core:scratchcard:getConfig` à l'ouverture et `core:scratchcard:
-- saveConfig` à l'enregistrement. Ni l'un ni l'autre n'existait.
--
-- Pour l'ouverture, ça ne se voyait pas comme une panne mais comme une lenteur : le
-- callback restait en attente jusqu'à son délai d'expiration — quinze secondes — puis
-- rendait nil, et le menu se repliait sur ses valeurs écrites en dur. D'où le « gros délai
-- entre l'ouverture et les options qui s'affichent », suivi d'un écran qui semblait normal
-- mais ne montrait jamais la configuration réelle du serveur.
--
-- Pour l'enregistrement, c'était une panne franche et silencieuse : rien n'était écrit.
--
-- La configuration vit dans la variable serveur `scratchcard_config`, lue par le tirage
-- dans 25_08_items.lua.

local VARIABLE <const> = "scratchcard_config"
local PERM <const> = "builder_scratch_card"

local DEFAULT_TIERS <const> = {
    { amount = 500, probability = 30 },
    { amount = 1500, probability = 10 },
    { amount = 3000, probability = 2 },
    { amount = 10000, probability = 0.3 },
    { amount = 30000, probability = 0.02 },
    { amount = 50000, probability = 0.015 },
    { amount = 100000, probability = 0.01 },
    { amount = 500000, probability = 0.001 },
}

local function copyDefaults()
    local out = {}
    for i = 1, #DEFAULT_TIERS do
        out[i] = { amount = DEFAULT_TIERS[i].amount, probability = DEFAULT_TIERS[i].probability }
    end
    return out
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

RegisterServerCallback("core:scratchcard:getConfig", function(source)
    if not staffOk(source) then return nil end

    local stored = VFW.Variables and VFW.Variables.GetVariable
        and VFW.Variables.GetVariable(VARIABLE) or nil

    if type(stored) == "table" and type(stored.prizeTiers) == "table" and #stored.prizeTiers > 0 then
        return stored
    end

    return { prizeTiers = copyDefaults() }
end)

RegisterNetEvent("core:scratchcard:saveConfig", function(payload)
    local source = source
    local xPlayer = staffOk(source)
    if not xPlayer then return end

    if type(payload) ~= "table" or type(payload.prizeTiers) ~= "table" then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Tickets à gratter",
            message = "Configuration invalide : rien n'a été enregistré.",
        })
        return
    end

    -- On ne garde que des paliers exploitables par le tirage : un montant positif et une
    -- probabilité strictement positive. Le reste serait du bruit en base.
    local tiers, total = {}, 0.0
    for _, tier in ipairs(payload.prizeTiers) do
        local amount = math.floor(tonumber(tier.amount) or 0)
        local probability = tonumber(tier.probability) or 0

        if amount > 0 and probability > 0 and amount <= 100000000 then
            probability = math.min(probability, 100.0)
            tiers[#tiers + 1] = { amount = amount, probability = probability }
            total = total + probability
        end
    end

    if #tiers == 0 then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Tickets à gratter",
            message = "Aucun palier valide : il faut un montant et une probabilité positifs.",
        })
        return
    end

    -- Le tirage cumule les probabilités dans l'ordre : au-delà de 100 %, les derniers
    -- paliers ne sortiraient jamais. On enregistre quand même — c'est un choix de
    -- configuration — mais on prévient.
    if total > 100.0 then
        xPlayer.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Tickets à gratter",
            message = ("Le total atteint %.2f %% : les derniers paliers ne sortiront jamais."):format(total),
        })
    end

    VFW.Variables.SetVariable(VARIABLE, { prizeTiers = tiers })
    if VFW.Variables.Flush then VFW.Variables.Flush(VARIABLE) end
end)

-- ── Gestion > Tickets à gratter : le panneau du hub (montants et pourcentages de chaque palier) ──

local function gestionOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(PERM) or xPlayer.hasPermission("gestion") or xPlayer.hasPermission("server_management")
        or xPlayer.hasPermission("dev") or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function currentTiers()
    local stored = VFW.Variables and VFW.Variables.GetVariable and VFW.Variables.GetVariable(VARIABLE) or nil
    if type(stored) == "table" and type(stored.prizeTiers) == "table" and #stored.prizeTiers > 0 then
        local out = {}
        for i = 1, #stored.prizeTiers do
            out[i] = { amount = tonumber(stored.prizeTiers[i].amount) or 0, probability = tonumber(stored.prizeTiers[i].probability) or 0 }
        end
        return out
    end
    return copyDefaults()
end

RegisterServerCallback("gestion:scratch:get", function(source)
    if not gestionOk(source) then return { ok = false, error = "Permission requise." } end
    return { ok = true, tiers = currentTiers(), defaults = copyDefaults() }
end)

--- Enregistre les paliers { amount, probability } du panneau. Plus strict que l'ancien menu : le total ne doit
--- pas dépasser 100 % (le tirage cumule les probabilités dans l'ordre : au-delà, les derniers paliers ne
--- sortiraient jamais). Le reste jusqu'à 100 % est la chance de ne rien gagner.
RegisterServerCallback("gestion:scratch:save", function(source, tiers)
    if not gestionOk(source) then return { ok = false, error = "Permission requise." } end
    if type(tiers) ~= "table" then return { ok = false, error = "Configuration invalide." } end

    local clean, total = {}, 0.0
    for _, tier in ipairs(tiers) do
        local amount = math.floor(tonumber(type(tier) == "table" and tier.amount or nil) or 0)
        local probability = tonumber(type(tier) == "table" and tier.probability or nil) or 0
        if amount > 0 and probability > 0 then
            if amount > 100000000 then return { ok = false, error = "Un gain ne peut pas dépasser 100 000 000 $." } end
            if probability > 100 then return { ok = false, error = "Une probabilité ne peut pas dépasser 100 %." } end
            clean[#clean + 1] = { amount = amount, probability = math.floor(probability * 10000 + 0.5) / 10000 }
            total = total + probability
        end
        if #clean >= 30 then break end
    end

    if #clean == 0 then return { ok = false, error = "Il faut au moins un palier avec un montant et une probabilité positifs." } end
    if total > 100.0000001 then
        return { ok = false, error = ("Le total fait %.4f %% : il ne doit pas dépasser 100 %%."):format(total) }
    end

    VFW.Variables.SetVariable(VARIABLE, { prizeTiers = clean })
    if VFW.Variables.Flush then VFW.Variables.Flush(VARIABLE) end
    return { ok = true, tiers = clean, message = "Gains enregistrés : appliqués dès le prochain ticket." }
end)
