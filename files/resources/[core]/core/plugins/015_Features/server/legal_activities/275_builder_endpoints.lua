---@meta _
---@diagnostic disable: duplicate-doc-field

-- Activites legales : points d'entree du builder staff.
--
-- Le menu « ACTIVITES LEGALES » appelait six callbacks ; un seul existait. Les fonctions
-- de travail etaient pourtant ecrites dans 270_sellers_config.lua — il manquait juste de
-- quoi les appeler. Deplacer un vendeur, le masquer, le supprimer, en ajouter un ou changer
-- un prix ne faisait donc rien : le menu attendait quinze secondes puis affichait « Erreur ».
--
-- Les prix, eux, n'avaient aucun endroit ou vivre : ils sont ecrits en dur dans trois
-- configs differentes selon l'activite (Config.fishing.fishes, Config.hunting.items,
-- Config.legalActivitiesSellers.diving.itemsToSell). On ajoute une table d'ecrasement, lue
-- par-dessus ces configs, pour qu'un prix regle en jeu survive au redemarrage sans toucher
-- aux fichiers.

local PRICE_TABLE <const> = "legal_activity_prices"

local priceCache = nil

local function ensureTable()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `activity`  VARCHAR(32) NOT NULL,
            `item_name` VARCHAR(64) NOT NULL,
            `price`     INT(11)     NOT NULL DEFAULT 0,
            PRIMARY KEY (`activity`, `item_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]]):format(PRICE_TABLE), {})
end

CreateThread(function()
    ensureTable()
end)

--- Prix regles en jeu, par activite puis par objet.
local function overrides()
    if priceCache then return priceCache end

    local rows = MySQL.query.await(("SELECT activity, item_name, price FROM `%s`"):format(PRICE_TABLE), {}) or {}
    priceCache = {}

    for i = 1, #rows do
        local row = rows[i]
        priceCache[row.activity] = priceCache[row.activity] or {}
        priceCache[row.activity][row.item_name] = tonumber(row.price) or 0
    end

    return priceCache
end

--- Prix effectif d'un objet : l'ecrasement s'il existe, sinon celui de la config.
---
--- Appele par les trois activites a chaque vente, d'ou le cache : une requete par
--- redemarrage, invalidee des qu'un prix change.
function LegalActivities.Price(activity, itemName, fallback)
    local byActivity = overrides()[activity]
    local price = byActivity and byActivity[itemName]
    if price then return price end
    return tonumber(fallback) or 0
end

--- Catalogue d'une activite, prix a jour, tel que le builder l'affiche.
---
--- Chaque activite range ses objets ailleurs : la peche dans Config.fishing.fishes, la
--- chasse dans Config.hunting.items, la plongee dans les itemsToSell du vendeur.
function LegalActivities.ItemsFor(activity)
    local raw = {}

    if activity == "fishing" then
        raw = (Config and Config.fishing and Config.fishing.fishes) or {}
    elseif activity == "hunting" then
        raw = (Config and Config.hunting and Config.hunting.items) or {}
    elseif activity == "diving" then
        local sellers = (Config and Config.legalActivitiesSellers) or {}
        raw = (sellers.diving and sellers.diving.itemsToSell) or {}
    end

    local out = {}
    for _, entry in pairs(raw) do
        if type(entry) == "table" and entry.name then
            out[#out + 1] = {
                name = entry.name,
                label = (Feat27 and Feat27.Inv and Feat27.Inv.Label and Feat27.Inv.Label(entry.name)) or entry.name,
                price = LegalActivities.Price(activity, entry.name, entry.price),
            }
        end
    end

    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

function LegalActivities.SetPrice(activity, itemName, price)
    if not LegalActivities.IsActivity(activity) then return false end
    if type(itemName) ~= "string" or itemName == "" then return false end

    local value = math.floor(tonumber(price) or -1)
    if value < 0 or value > 10000000 then return false end

    MySQL.query.await(([[
        INSERT INTO `%s` (`activity`, `item_name`, `price`) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE `price` = VALUES(`price`)
    ]]):format(PRICE_TABLE), { activity, itemName, value })

    priceCache = nil
    return true
end

--- Ajoute un vendeur a la suite des existants.
local function nextIndex(activity)
    local row = MySQL.single.await(
        "SELECT MAX(`seller_index`) AS last FROM legal_activity_sellers WHERE `activity` = ?", { activity })
    return (tonumber(row and row.last) or 0) + 1
end

-- ── Autorisation ────────────────────────────────────────────────────────────────────────

local function builder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("legal_activities_builder")
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

--- Position du joueur, pour les actions « a ta position ».
local function playerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end

    local coords = GetEntityCoords(ped)
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0,
        w = GetEntityHeading(ped) + 0.0,
    }
end

-- ── Points d'entree ─────────────────────────────────────────────────────────────────────

RegisterServerCallback("legalActivities:addSeller", function(source, activity)
    if not builder(source) then return { success = false, error = "Permission refusee." } end
    if not LegalActivities.IsActivity(activity) then return { success = false, error = "Activite inconnue." } end

    local pos = playerCoords(source)
    if not pos then return { success = false, error = "Position introuvable." } end

    -- Le modele reprend celui du premier vendeur de l'activite : un vendeur sans modele
    -- n'apparaitrait pas du tout.
    local existing = MySQL.single.await(
        "SELECT `model` FROM legal_activity_sellers WHERE `activity` = ? ORDER BY `seller_index` ASC LIMIT 1",
        { activity })
    pos.model = (existing and existing.model) or "ig_cletus"
    pos.visible = true

    local index = nextIndex(activity)
    if not LegalActivities.SetSellerPosition(activity, index, pos) then
        return { success = false, error = "Enregistrement impossible." }
    end

    return { success = true, index = index }
end)

RegisterServerCallback("legalActivities:updatePosition", function(source, activity, sellerIndex)
    if not builder(source) then return { success = false, error = "Permission refusee." } end

    local index = tonumber(sellerIndex)
    if not index then return { success = false, error = "Vendeur inconnu." } end

    local pos = playerCoords(source)
    if not pos then return { success = false, error = "Position introuvable." } end

    -- On garde le modele et la visibilite en place : seule la position bouge.
    local row = MySQL.single.await(
        "SELECT `model`, `visible` FROM legal_activity_sellers WHERE `activity` = ? AND `seller_index` = ?",
        { activity, index })
    if not row then return { success = false, error = "Vendeur introuvable." } end

    pos.model = row.model
    pos.visible = (row.visible == 1 or row.visible == true)

    if not LegalActivities.SetSellerPosition(activity, index, pos) then
        return { success = false, error = "Enregistrement impossible." }
    end

    return { success = true }
end)

RegisterServerCallback("legalActivities:toggleSellerVisibility", function(source, activity, sellerIndex, visible)
    if not builder(source) then return { success = false, error = "Permission refusee." } end

    if not LegalActivities.SetSellerVisibility(activity, sellerIndex, visible == true) then
        return { success = false, error = "Enregistrement impossible." }
    end

    return { success = true }
end)

RegisterServerCallback("legalActivities:deleteSeller", function(source, activity, sellerIndex)
    if not builder(source) then return { success = false, error = "Permission refusee." } end

    if not LegalActivities.DeleteSeller(activity, sellerIndex) then
        return { success = false, error = "Suppression impossible." }
    end

    return { success = true }
end)

RegisterServerCallback("legalActivities:updatePrice", function(source, activity, itemName, price)
    if not builder(source) then return { success = false, error = "Permission refusee." } end

    if not LegalActivities.SetPrice(activity, itemName, price) then
        return { success = false, error = "Prix refuse." }
    end

    return { success = true }
end)
