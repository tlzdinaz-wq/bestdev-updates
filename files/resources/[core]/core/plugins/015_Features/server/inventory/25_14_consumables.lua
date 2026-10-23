-- Fiches des aliments et des boissons : remise à niveau au démarrage.
--
-- Les items du catalogue sont créés avec une fiche vide : ni faim, ni soif, ni
-- catégorie. Le pain, l'eau et le café étaient donc livrés comme des objets
-- ordinaires et répondaient « item pas utilisable », alors que leurs valeurs
-- existaient depuis toujours ailleurs — dans `shared/consumables.lua` pour les
-- cent cinquante aliments et boissons du serveur, et dans la description du
-- catalogue (« Restaure 30% de soif ») pour les autres.
--
-- Ce fichier recopie ces valeurs dans la fiche de l'item, une fois, au premier
-- démarrage : elles deviennent visibles et modifiables dans Gestion > Items.
--
-- Ce qui a déjà une réponse n'est jamais touché : un item dont la fiche porte
-- une faim, une soif, une catégorie « consumable » ou l'interrupteur
-- « Consommable » est laissé tel quel, même s'il dit le contraire du catalogue.
-- Le deuxième démarrage ne modifie donc plus rien.
--
-- Les animations et les props ne sont pas recopiés : ils restent dans le
-- catalogue partagé, que l'usage de l'item consulte à chaque fois (voir
-- Inv.ConsumableData dans 25_01_core.lua). Une fiche modifiée depuis Gestion ne
-- les perd donc pas en route.

local Inv = VFW.Inventory

--- Champs recopiés dans la fiche : ceux que Gestion > Items sait afficher.
local STORED_FIELDS <const> = { "hunger", "thirst", "duration", "alcool" }

--- Une fiche qui répond déjà à la question ne doit pas être réécrite.
---@param def table
---@return boolean
local function alreadyAnswered(def)
    local data = type(def.data) == "table" and def.data or {}

    return data.consumable ~= nil
        or (tonumber(data.hunger) or 0) > 0
        or (tonumber(data.thirst) or 0) > 0
        or data.type == "consumable"
        or def.type == "food"
        or def.type == "drink"
end

--- La fiche mise à jour, ou nil s'il n'y a rien à y changer.
---@param name string
---@param def table
---@return table|nil
local function upgrade(name, def)
    if type(def) ~= "table" then return nil end
    if def.type == "weapons" or def.type == "clothes" or def.type == "outfit" then return nil end
    if alreadyAnswered(def) then return nil end

    local preset = Inv.ConsumablePreset(name, def)
    if not preset then return nil end

    local hunger = tonumber(preset.hunger) or 0
    local thirst = tonumber(preset.thirst) or 0
    if hunger <= 0 and thirst <= 0 then return nil end

    local data = {}
    for key, value in pairs(type(def.data) == "table" and def.data or {}) do
        data[key] = value
    end

    data.type = "consumable"
    for i = 1, #STORED_FIELDS do
        local key = STORED_FIELDS[i]
        if data[key] == nil and preset[key] ~= nil then
            data[key] = preset[key]
        end
    end

    return data
end

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 60000 do
        Wait(200)
        waited = waited + 200
    end

    local catalog = VFW.Items
    if type(catalog) ~= "table" or next(catalog) == nil then
        console.warn("[inventory] catalogue d'items vide : fiches des consommables non verifiees")
        return
    end

    local pending = {}
    for name, def in pairs(catalog) do
        local data = upgrade(name, def)
        if data then pending[#pending + 1] = { name = name, data = data } end
    end

    if #pending == 0 then return end

    local updated = 0
    for i = 1, #pending do
        local row = pending[i]
        local ok, err = pcall(function()
            return MySQL.update.await("UPDATE items SET `data` = ? WHERE `name` = ?", {
                json.encode(row.data),
                row.name,
            })
        end)

        if ok then
            -- Le catalogue en mémoire suit : les items deviennent consommables
            -- sans attendre un second démarrage.
            if catalog[row.name] then catalog[row.name].data = row.data end
            updated = updated + 1
        else
            console.warn(("[inventory] fiche de '%s' non mise a jour : %s"):format(row.name, tostring(err)))
        end

        -- Une fiche sur vingt-cinq, on rend la main : au premier démarrage la
        -- liste fait plus de cent items.
        if i % 25 == 0 then Wait(0) end
    end

    console.init("Inventory", ("%d aliments et boissons rendus consommables"):format(updated))
end)
