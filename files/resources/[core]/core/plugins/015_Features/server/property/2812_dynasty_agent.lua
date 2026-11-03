-- Immobilier : prix du catalogue, et l'entrée de l'agent.
--
-- Deux choses empêchaient de créer la moindre maison, sur tous les serveurs.
--
-- 1. Le catalogue n'avait aucun prix. Les prix vivent dans la table
--    `dynasty_prices`, remplie uniquement à la main depuis Gestion > Gestion
--    Dynasty : à l'installation elle est vide, et la création refusait chaque
--    bien avec « Ce bien n'est pas au catalogue ». Il fallait saisir les
--    soixante-huit biens un par un avant que quoi que ce soit fonctionne.
--    Les prix ci-dessous servent de point de départ, écrits une seule fois et
--    seulement pour les biens qui n'en ont pas : ce qui est réglé dans Gestion
--    n'est jamais réécrit, et un bien remis à zéro le reste.
--
-- 2. Les agents n'avaient aucun moyen d'ouvrir la tablette en mode agent. Le
--    point d'interaction prévu pour eux est commenté depuis toujours et
--    appelle une fonction qui n'existe pas ; le catalogue des sociétés ouvre
--    la tablette en mode client ; et le seul appel en mode agent se trouve
--    dans le menu staff des prix. D'où « les gens qui ont le job ne peuvent
--    pas créer de maison » : ils voyaient le catalogue, jamais le formulaire.
--    La commande /immobilier ouvre la tablette du côté agent.

-- Comme les autres fichiers du dossier : `PS` n'est pas une variable globale,
-- chacun prend sa référence sur la table partagée.
local PS = VFW.PropertyServer

local JOBS <const> = { "dynasty", "dynasty8", "dynasty_8", "immobilier", "realestate", "realestateagent" }

-- Prix de départ, en dollars. La location est hebdomadaire (la durée d'un
-- contrat se compte en semaines, 52 au maximum).
local DEFAULT_SELL <const> = 150000

local APARTMENT_TIERS <const> = {
    { match = "motel", sell = 60000 },
    { match = "studio", sell = 90000 },
    { match = "grandappartement", sell = 260000 },
    { match = "appartement", sell = 160000 },
    { match = "duplex", sell = 340000 },
    { match = "penthouse", sell = 620000 },
    { match = "villa", sell = 900000 },
    { match = "manoir", sell = 1200000 },
}

local WAREHOUSE_TIERS <const> = {
    { match = "conteneur", sell = 70000 },
    { match = "morgue", sell = 90000 },
    { match = "petitstockage", sell = 110000 },
    { match = "petitentrepot", sell = 180000 },
    { match = "moyenentrepot", sell = 320000 },
    { match = "grandentrepot", sell = 560000 },
    { match = "bunker", sell = 950000 },
}

--- Le prix d'un bien d'après sa catégorie et sa fiche.
---@param category string
---@param entry table
---@return integer
local function defaultSell(category, entry)
    local key = tostring(entry.id or entry.name or ""):lower()

    if category == "Garage" then
        -- Un garage vaut ses places : de deux à trente-cinq selon les modèles.
        -- Les garages spéciaux (camion, bateau, avion, abandonné) portent 96 à 99
        -- comme marqueur et non comme capacité : les compter au tarif de la place
        -- les aurait mis à deux millions et demi.
        local places = tonumber(entry.maxPlaces) or 2
        if places >= 50 then return 300000 end
        if places < 1 then places = 1 end
        return 25000 * places
    end

    local tiers = category == "Entrepot" and WAREHOUSE_TIERS or APARTMENT_TIERS
    -- Du plus précis au plus large : « grandappartement » avant « appartement ».
    local best, bestLen = nil, -1
    for i = 1, #tiers do
        local tier = tiers[i]
        if key:find(tier.match, 1, true) and #tier.match > bestLen then
            best, bestLen = tier.sell, #tier.match
        end
    end

    return best or DEFAULT_SELL
end

--- Loyer hebdomadaire : deux pour cent du prix de vente, arrondi à la centaine.
---@param sell integer
---@return integer
local function defaultRent(sell)
    local rent = math.floor(sell / 50 / 100 + 0.5) * 100
    if rent < 500 then rent = 500 end
    return rent
end

--- Écrit les prix manquants du catalogue.
---
--- `INSERT IGNORE` sur la clé unique (catégorie, bien) : une ligne déjà
--- présente est laissée telle quelle, quelle que soit sa valeur.
local function seedPrices()
    if type(Property) ~= "table" then return 0 end

    local values, params, count = {}, {}, 0

    for category, group in pairs(Property) do
        if type(group) == "table" and type(group.data) == "table" then
            for i = 1, #group.data do
                local entry = group.data[i]
                local key = entry.id or entry.name
                if type(key) == "string" and key ~= "" then
                    local sell = defaultSell(category, entry)
                    values[#values + 1] = "(?, ?, ?, ?, 1, 1)"
                    params[#params + 1] = category
                    params[#params + 1] = key
                    params[#params + 1] = sell
                    params[#params + 1] = defaultRent(sell)
                    count = count + 1
                end
            end
        end
    end

    if count == 0 then return 0 end

    MySQL.insert.await(
        "INSERT IGNORE INTO dynasty_prices (category, property_key, sell, rent, enabled, rent_enabled) VALUES " ..
        table.concat(values, ", "),
        params
    )

    return count
end

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 60000 do
        Wait(200)
        waited = waited + 200
    end

    local ok, err = pcall(seedPrices)
    if not ok then
        console.warn(("[immobilier] prix du catalogue non verifies : %s"):format(tostring(err)))
        return
    end

    -- Relire : les lignes ajoutées doivent valoir pour la session en cours.
    pcall(PS.LoadPrices)

    local total = 0
    for _, entries in pairs(PS.Prices or {}) do
        for _ in pairs(entries) do total = total + 1 end
    end
    console.init("Immobilier", ("%d biens au catalogue"):format(total))
end)

--- L'agent immobilier, ou le staff qui en fait office.
---@param xPlayer table|nil
---@return boolean agent, boolean staff
local function agentOf(xPlayer)
    if not xPlayer then return false, false end

    local staff = PS.IsStaff(xPlayer)
    local job = xPlayer.job and xPlayer.job.name or ""
    for i = 1, #JOBS do
        if JOBS[i] == job then return true, staff end
    end

    return false, staff
end

VFW.RegisterCommand("immobilier", "", function(source, xPlayer)
    local agent, staff = agentOf(xPlayer)

    if not agent and not staff then
        VFW.ShowNotification(source, {
            type = "ROUGE",
            content = "Vous n'etes pas agent immobilier.",
        })
        return
    end

    -- Le staff ouvre la tablette sans prendre le metier ; un agent, lui, doit
    -- etre en service, comme pour le reste de son travail.
    if agent and not staff and not (xPlayer.job and xPlayer.job.onDuty) then
        VFW.ShowNotification(source, {
            type = "ROUGE",
            content = "Vous devez etre en service pour ouvrir la tablette.",
        })
        return
    end

    TriggerClientEvent("dynasty:openAgentTablet", source, staff and not agent)
end, {
    help = "Ouvrir la tablette immobiliere (agent Dynasty 8).",
})
