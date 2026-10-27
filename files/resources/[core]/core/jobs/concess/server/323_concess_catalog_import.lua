-- Catalogue des concessionnaires : import des voitures et motos de la base (avec leurs prix).
--
-- Les catégories (`concess_categories`) et les véhicules (`concess_vehicles`) viennent de la base de données ; sans elles,
-- un concessionnaire ouvre un catalogue vide (« Aucune catégorie de véhicule disponible ») et il fallait tout ajouter à la
-- main, véhicule par véhicule. La liste complète existe déjà dans plugins/015_Features/shared/catalogue_cardealer.lua :
-- elle est copiée en base une seule fois (catalogue vide au démarrage) ou à la demande (Gestion > Builders >
-- Concessionnaire > Gérer les véhicules > Importer le catalogue complet).
--
-- L'import n'écrase jamais : une catégorie ou un véhicule déjà présent garde son nom et son prix réglés par le staff.

VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Concess = VFW.Concess or {}

local JC = VFW.JobsCommon
local Concess = VFW.Concess

local CAR_TYPE <const> = 1 -- « voiture » (voitures et motos), voir les types du builder

--- Liste à plat { category, model, name, price }, sans doublon de modèle (la première source gagne), dans un ordre stable.
local function defaultEntries()
    local out, seen = {}, {}

    local function add(category, entry)
        if type(entry) ~= "table" then return end
        local model = type(entry.model) == "string" and entry.model:lower():gsub("^%s+", ""):gsub("%s+$", "") or nil
        local price = tonumber(entry.price)
        if not model or model == "" or #model > 64 or not price or price < 0 or seen[model] then return end
        seen[model] = true
        local name = type(entry.label) == "string" and entry.label ~= "" and entry.label or model
        out[#out + 1] = { category = category:lower():sub(1, 64), model = model, name = name:sub(1, 128), price = math.floor(price) }
    end

    local function addCategorised(tbl)
        if type(tbl) ~= "table" then return end
        local names = {}
        for category in pairs(tbl) do names[#names + 1] = category end
        table.sort(names)
        for _, category in ipairs(names) do
            for _, entry in ipairs(tbl[category]) do add(category, entry) end
        end
    end

    addCategorised(VFW.Cardealer and VFW.Cardealer.Vehicle)
    addCategorised(VFW.AmericanMotors and VFW.AmericanMotors.Vehicle)
    if VFW.Benefactor and type(VFW.Benefactor.Vehicle) == "table" then
        for _, entry in ipairs(VFW.Benefactor.Vehicle) do add("Benefactor", entry) end
    end
    return out
end

--- Copie le catalogue de la base dans les tables des concessionnaires. Renvoie le nombre de catégories et de véhicules ajoutés.
function Concess.ImportDefaultCatalog()
    local entries = defaultEntries()
    if #entries == 0 then return false, "Aucun catalogue de véhicules n'est disponible dans la base." end

    local categories, queries = {}, {}
    for _, e in ipairs(entries) do
        if not categories[e.category] then
            categories[e.category] = true
            queries[#queries + 1] = { query = "INSERT IGNORE INTO concess_categories (name, concess_type) VALUES (?, ?)", values = { e.category, CAR_TYPE } }
        end
    end
    for _, e in ipairs(entries) do
        queries[#queries + 1] = { query = "INSERT IGNORE INTO concess_vehicles (model, name, price, category) VALUES (?, ?, ?, ?)", values = { e.model, e.name, e.price, e.category } }
    end

    local before = { cats = #(select(1, Concess.LoadCatalog())), vehicles = 0 }
    for _ in pairs(select(2, Concess.LoadCatalog())) do before.vehicles = before.vehicles + 1 end

    local ok, err = pcall(MySQL.transaction.await, queries)
    if not ok or err == false then
        console.error("[concess] import du catalogue : " .. tostring(err))
        return false, "Écriture SQL impossible. Consultez la console du serveur."
    end

    local cats, vehicles = Concess.LoadCatalog()
    local after = { cats = #cats, vehicles = 0 }
    for _ in pairs(vehicles) do after.vehicles = after.vehicles + 1 end
    return true, { categories = after.cats - before.cats, vehicles = after.vehicles - before.vehicles, total = after.vehicles }
end

JC.Cb("core:concess:importCatalog", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return { success = false, error = "Permission manage_concess requise." } end

    local ok, result = Concess.ImportDefaultCatalog()
    if not ok then return { success = false, error = result } end

    TriggerEvent("vfw:logs:staff", source, "concess_import_catalog", result)
    return { success = true, categories = result.categories, vehicles = result.vehicles, total = result.total }
end)

-- Catalogue vide au démarrage (première installation) : importé tout de suite, le concessionnaire a un catalogue dès l'ouverture.
CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(6000) -- après Concess.Load / LoadCatalog (320_concess_store.lua)

    local _, vehicles = Concess.LoadCatalog()
    if next(vehicles) ~= nil then return end

    local ok, result = Concess.ImportDefaultCatalog()
    if ok then
        print(("^2[concess]^7 catalogue vide : %d véhicules et %d catégories importés avec leurs prix."):format(result.vehicles, result.categories))
    else
        print("^3[concess]^7 catalogue vide et import impossible : " .. tostring(result))
    end
end)
