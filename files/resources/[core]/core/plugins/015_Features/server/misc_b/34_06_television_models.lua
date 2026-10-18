-- Televisions : les modeles configures par le builder (menu staff > Builder > TELEVISION).
--
-- `television:getModels` existait, mais rendait une liste ecrite en dur dans le code :
-- neuf modeles, sans reglage, identiques pour tout le monde. Les trois ecritures du
-- builder — ajouter, modifier, supprimer un modele — n'avaient aucun handler. Le menu
-- affichait « Modele ajoute » et rien n'etait enregistre.
--
-- Les modeles vivent maintenant dans la variable serveur `television_models`, comme
-- d'autres reglages de la base. La liste d'origine sert de depart au premier demarrage,
-- pour ne rien perdre de ce qui marchait.
--
-- A part : lire une video sur un ecran passe par la ressource externe `ptelevision`,
-- qui n'est pas fournie avec la base (voir server.cfg). Ce fichier ne decrit que les
-- modeles ; sans `ptelevision`, aucun ecran ne lira quoi que ce soit.

local VARIABLE <const> = "television_models"
local PERMISSION <const> = "builder_television"

local DEFAULTS <const> = {
    target = "tvscreen",
    scale = 0.085,
    offset_x = -1.02,
    offset_y = -0.055,
    offset_z = 1.04,
    range = 20.0,
    default_volume = 0.5,
    dui_width = 1280,
    dui_height = 720,
}

local SEED_MODELS <const> = {
    "prop_tv_flat_01", "prop_tv_flat_01b", "prop_tv_flat_02", "prop_tv_flat_03",
    "prop_tv_03", "prop_tv_06", "prop_tv_07", "v_res_tre_tv", "v_res_mtv",
}

local function builder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if xPlayer.hasPermission(PERMISSION)
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end

    return nil
end

---Un modele complet : ce que le builder envoie, borne, complete par les valeurs
---d'origine pour tout ce qui manque.
---@param payload table
---@return table|nil
local function normalize(payload)
    local model = MiscB.Str(payload.model, 60)
    if not model or model:gsub("%s", "") == "" then return nil end

    local function number(key, min, max)
        local value = tonumber(payload[key])
        if not value or value ~= value then return DEFAULTS[key] end
        if value < min then return min end
        if value > max then return max end
        return value
    end

    return {
        model = model,
        target = MiscB.Str(payload.target, 64) or DEFAULTS.target,
        scale = number("scale", 0.001, 10.0),
        offset_x = number("offset_x", -50.0, 50.0),
        offset_y = number("offset_y", -50.0, 50.0),
        offset_z = number("offset_z", -50.0, 50.0),
        range = number("range", 1.0, 200.0),
        default_volume = number("default_volume", 0.0, 1.0),
        dui_width = math.floor(number("dui_width", 64, 4096)),
        dui_height = math.floor(number("dui_height", 64, 4096)),
    }
end

local function loadModels()
    local stored = VFW.Variables and VFW.Variables.GetVariable
        and VFW.Variables.GetVariable(VARIABLE) or nil

    if type(stored) == "table" and #stored > 0 then return stored end

    -- Premier demarrage : on repart de la liste qui etait ecrite en dur.
    local seeded = {}
    for i = 1, #SEED_MODELS do
        seeded[i] = normalize({ model = SEED_MODELS[i] })
    end

    return seeded
end

local function saveModels(models)
    VFW.Variables.SetVariable(VARIABLE, models)

    -- La liste complete, pas un ajout : c'est le seul moyen qu'une suppression
    -- parvienne aussi aux joueurs deja connectes.
    TriggerClientEvent("core:television:modelsUpdated", -1, models)
end

---@param models table
---@param model string
---@return number|nil index
local function indexOf(models, model)
    for i = 1, #models do
        if models[i].model == model then return i end
    end
    return nil
end

MiscB.Cb("television:getModels", function(source)
    return loadModels()
end)

RegisterNetEvent("television:addModel", function(payload)
    local source = source
    if not builder(source) then return end

    local data = MiscB.Table(payload)
    if not data then return end

    local entry = normalize(data)
    if not entry then
        MiscB.Notify(source, "Ce modele n'est pas valide.", "ROUGE")
        return
    end

    local models = loadModels()
    if indexOf(models, entry.model) then
        MiscB.Notify(source, "Ce modele est deja dans la liste.", "ROUGE")
        return
    end

    models[#models + 1] = entry
    saveModels(models)
end)

RegisterNetEvent("television:updateModel", function(payload)
    local source = source
    if not builder(source) then return end

    local data = MiscB.Table(payload)
    if not data then return end

    local entry = normalize(data)
    if not entry then return end

    local models = loadModels()
    local index = indexOf(models, entry.model)

    -- Modifier un modele absent revient a l'ajouter : le menu ouvre la meme fiche
    -- dans les deux cas, et perdre le reglage parce que la liste a change entre-temps
    -- serait incomprehensible.
    models[index or (#models + 1)] = entry
    saveModels(models)
end)

RegisterNetEvent("television:deleteModel", function(model)
    local source = source
    if not builder(source) then return end

    local name = MiscB.Str(model, 60)
    if not name then return end

    local models = loadModels()
    local index = indexOf(models, name)
    if not index then return end

    table.remove(models, index)
    saveModels(models)
end)
