---@meta _
---@diagnostic disable: duplicate-doc-field

-- Pont entre le menu « COFFRE » du staff et le module de coffres serveur.
--
-- Le menu (plugins/015_Features/client/staff/menu/chest_builder.lua) appelle trois points
-- d'entrée serveur : la liste des coffres, la création et la modification. Aucun des trois
-- n'avait été écrit — le bouton « Créer / modifier le coffre » n'envoyait donc son message
-- à personne, et la liste des coffres existants arrivait vide.
--
-- Seule la commande `/createchest` fonctionnait, mais elle ne permet ni de nommer le coffre,
-- ni d'en régler le poids, les emplacements ou l'historique.

local Inv = VFW.Inventory
local BUILDER_PERM = "chest_builder"

local function chestIdFor(id)
    return ("chestbuilder:%s"):format(tostring(id))
end

local function staff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission(BUILDER_PERM) then return nil end
    return xPlayer
end

--- Le menu propose un grade minimum pour consulter l'historique : la colonne n'existait pas.
local function ensureColumns()
    local ok, columns = pcall(MySQL.query.await, "SHOW COLUMNS FROM chest_builder")
    if not ok or type(columns) ~= "table" then return end

    for i = 1, #columns do
        if columns[i].Field == "grade_min_history" then return end
    end

    pcall(MySQL.update.await,
        "ALTER TABLE chest_builder ADD COLUMN `grade_min_history` INT(11) NOT NULL DEFAULT 0")
end

--- Normalise ce que le menu envoie.
---@param data table
---@return table|nil
local function sanitize(data)
    if type(data) ~= "table" then return nil end

    local coords = data.coords
    if type(coords) ~= "table" or not tonumber(coords.x) then return nil end

    local label = tostring(data.label or "Coffre")
    label = label:gsub("^%s+", ""):gsub("%s+$", "")
    if label == "" then label = "Coffre" end

    local accessName = tostring(data.accessName or "")
    local accessLabel = accessName

    if accessName ~= "" then
        local job = VFW.Jobs and VFW.Jobs[accessName]
        if type(job) == "table" and job.label then
            accessLabel = job.label
        end
    end

    local pincode = tonumber(data.pincode)
    if pincode and (pincode <= 0 or #tostring(math.floor(pincode)) > 9) then pincode = nil end

    return {
        label = label:sub(1, 100),
        accessName = accessName:sub(1, 60),
        accessLabel = accessLabel:sub(1, 100),
        coords = {
            x = tonumber(coords.x) + 0.0,
            y = tonumber(coords.y) + 0.0,
            z = tonumber(coords.z) + 0.0,
            floatingZ = tonumber(data.floatingZ) or tonumber(coords.floatingZ) or 0.5,
        },
        gradeMinPut = math.floor(tonumber(data.gradeMinPut) or 0),
        gradeMinTake = math.floor(tonumber(data.gradeMinTake) or 0),
        gradeMinHistory = math.floor(tonumber(data.gradeMinHistory) or 0),
        pincode = pincode and math.floor(pincode) or nil,
        maxWeight = math.max(1, math.floor(tonumber(data.maxWeight) or 400)),
        maxSlots = math.max(1, math.floor(tonumber(data.maxSlots) or 50)),
    }
end

local function applyToCache(id, chest)
    ChestBuilderServer.cache[id] = {
        id = id,
        coords = chest.coords,
        accessName = chest.accessName,
        accessLabel = chest.accessLabel,
        gradeMinPut = chest.gradeMinPut,
        gradeMinTake = chest.gradeMinTake,
        gradeMinHistory = chest.gradeMinHistory,
        pincode = chest.pincode,
        maxWeight = chest.maxWeight,
        maxSlots = chest.maxSlots,
        label = chest.label,
    }

    Inv.ConfigureChest(chestIdFor(id), {
        label = chest.label,
        maxWeight = chest.maxWeight,
        maxSlots = chest.maxSlots,
    })

    return ChestBuilderServer.cache[id]
end

RegisterServerCallback("chestBuilder:getAllChests", function(source)
    if not staff(source) then return {} end
    return ChestBuilderServer.List()
end)

RegisterNetEvent("chestBuilder:server:create", function(data)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local chest = sanitize(data)
    if not chest then
        xPlayer.showNotification({ type = "ROUGE", content = "Données du coffre invalides." })
        return
    end

    local id = MySQL.insert.await([[
        INSERT INTO chest_builder (coords, access_name, access_label, grade_min_put, grade_min_take,
            grade_min_history, pincode, max_weight, max_slots, label)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        VFW.DB.Encode(chest.coords),
        chest.accessName, chest.accessLabel,
        chest.gradeMinPut, chest.gradeMinTake, chest.gradeMinHistory,
        chest.pincode and tostring(chest.pincode) or nil,
        chest.maxWeight, chest.maxSlots, chest.label,
    })

    if not id then
        xPlayer.showNotification({ type = "ROUGE", content = "Création du coffre impossible." })
        return
    end

    local created = applyToCache(id, chest)
    TriggerClientEvent("chestBuilder:client:syncNewChest", -1, created)

    xPlayer.showNotification({ type = "VERT", content = ("Coffre « %s » créé."):format(chest.label) })
end)

RegisterNetEvent("chestBuilder:server:update", function(data)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local id = tonumber(data and data.id)
    if not id then return end

    local chest = sanitize(data)
    if not chest then
        xPlayer.showNotification({ type = "ROUGE", content = "Données du coffre invalides." })
        return
    end

    MySQL.update.await([[
        UPDATE chest_builder SET coords = ?, access_name = ?, access_label = ?, grade_min_put = ?,
            grade_min_take = ?, grade_min_history = ?, pincode = ?, max_weight = ?, max_slots = ?, label = ?
        WHERE id = ?
    ]], {
        VFW.DB.Encode(chest.coords),
        chest.accessName, chest.accessLabel,
        chest.gradeMinPut, chest.gradeMinTake, chest.gradeMinHistory,
        chest.pincode and tostring(chest.pincode) or nil,
        chest.maxWeight, chest.maxSlots, chest.label, id,
    })

    local updated = applyToCache(id, chest)
    TriggerClientEvent("chestBuilder:client:syncNewChest", -1, updated)

    xPlayer.showNotification({ type = "VERT", content = ("Coffre « %s » modifié."):format(chest.label) })
end)

RegisterNetEvent("chestBuilder:server:delete", function(chestId)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local id = tonumber(chestId)
    if not id or not ChestBuilderServer.cache[id] then
        xPlayer.showNotification({ type = "ROUGE", content = "Coffre introuvable." })
        return
    end

    MySQL.update.await("DELETE FROM chest_builder WHERE id = ?", { id })
    ChestBuilderServer.cache[id] = nil

    TriggerClientEvent("chestBuilder:client:deleteChest", -1, id)
    xPlayer.showNotification({ type = "VERT", content = ("Coffre #%d supprimé."):format(id) })
end)

RegisterNetEvent("chestBuilder:server:clear", function(chestId)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local id = tonumber(chestId)
    if not id or not ChestBuilderServer.cache[id] then return end

    local key = chestIdFor(id)
    local chest = Inv.GetChest(key)
    if not chest then return end

    chest.items = {}
    Inv.SaveChest(key)
    Inv.RefreshChestViewers(key)

    xPlayer.showNotification({ type = "VERT", content = ("Coffre #%d vidé."):format(id) })
end)

RegisterNetEvent("chestBuilder:server:deleteLogs", function(chestId)
    local source = source
    local xPlayer = staff(source)
    if not xPlayer then return end

    local id = tonumber(chestId)
    if not id then return end

    MySQL.update.await("DELETE FROM chest_history WHERE chest_id = ?", { chestIdFor(id) })
    xPlayer.showNotification({ type = "VERT", content = "Historique du coffre effacé." })
end)

MySQL.ready(function()
    pcall(ensureColumns)
end)
