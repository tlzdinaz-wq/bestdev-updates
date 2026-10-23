local Inv = VFW.Inventory

ChestBuilderServer = ChestBuilderServer or {}
ChestBuilderServer.cache = {}

local function chestIdFor(id)
    return ("chestbuilder:%s"):format(tostring(id))
end

-- `grade_min_history` n'existe pas dans le schéma d'origine de `chest_builder` : la colonne est
-- ajoutée au chargement (voir ensureHistoryColumn) et cette variable dit si elle est là.
local hasHistoryColumn = false

local function rowToChest(row)
    local pin = tonumber(row.pincode) or 0
    local label = row.label or "Coffre"
    return {
        id = row.id,
        coords = VFW.DB.Decode(row.coords, { x = 0.0, y = 0.0, z = 0.0 }),
        accessName = row.access_name or "",
        accessLabel = row.access_label or "",
        gradeMinPut = tonumber(row.grade_min_put) or 0,
        gradeMinTake = tonumber(row.grade_min_take) or 0,
        gradeMinHistory = tonumber(row.grade_min_history),
        pincode = pin > 0 and pin or nil,
        maxWeight = tonumber(row.max_weight) or 400,
        maxSlots = tonumber(row.max_slots) or 50,
        label = label,
        -- Le menu staff lit `name`, le reste du code `label`.
        name = label,
    }
end

--- Ce qu'un client reçoit d'un coffre. Le code PIN ne part jamais : le client n'a besoin que de
--- savoir qu'il y en a un (pour demander la saisie) ; c'est le serveur qui le vérifie à l'ouverture.
--- Le menu staff reçoit le vrai code (`withPin`), sans quoi modifier un coffre l'effacerait.
---@param chest table
---@param withPin? boolean
---@return table
local function clientView(chest, withPin)
    local out = {}
    for k, v in pairs(chest) do out[k] = v end
    if not withPin then out.pincode = chest.pincode and true or nil end
    return out
end

--- Ajoute `grade_min_history` à `chest_builder` si elle manque. Lue dans information_schema plutôt
--- qu'un ALTER à chaque démarrage : sur MariaDB comme sur MySQL, un ALTER inutile reconstruit la table.
local function ensureHistoryColumn()
    local ok, rows = pcall(MySQL.query.await, [[
        SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'chest_builder' AND COLUMN_NAME = 'grade_min_history'
    ]])
    if not ok or type(rows) ~= "table" then return end

    if #rows == 0 then
        local added, err = pcall(MySQL.query.await,
            "ALTER TABLE chest_builder ADD COLUMN grade_min_history INT NULL DEFAULT NULL")
        if not added then
            console.warn(("[chestBuilder] colonne grade_min_history impossible à créer : %s"):format(tostring(err)))
            return
        end
    end

    hasHistoryColumn = true
end

function ChestBuilderServer.Load()
    ensureHistoryColumn()
    local rows = MySQL.query.await("SELECT * FROM chest_builder") or {}
    ChestBuilderServer.cache = {}

    for i = 1, #rows do
        local chest = rowToChest(rows[i])
        ChestBuilderServer.cache[chest.id] = chest
        Inv.ConfigureChest(chestIdFor(chest.id), {
            label = chest.label,
            maxWeight = chest.maxWeight,
            maxSlots = chest.maxSlots,
        })
    end

    console.init("ChestBuilder", ("%d coffres charges"):format(#rows))
end

function ChestBuilderServer.List()
    local out = {}
    for _, chest in pairs(ChestBuilderServer.cache) do
        out[#out + 1] = chest
    end
    return out
end

function ChestBuilderServer.Find(id)
    return ChestBuilderServer.cache[tonumber(id)] or ChestBuilderServer.cache[id]
end

local function playerGroupGrade(xPlayer, accessName)
    if not accessName or accessName == "" then return true, 999 end

    local job = xPlayer.job
    if job and job.name == accessName then
        return true, tonumber(job.grade) or 0
    end

    local job2 = xPlayer.job2
    if job2 and job2.name == accessName then
        return true, tonumber(job2.grade) or 0
    end

    local faction = xPlayer.faction
    if type(faction) == "table" and faction.name == accessName then
        return true, tonumber(faction.grade) or 0
    end
    if type(faction) == "string" and faction ~= "" and faction == accessName then
        return true, tonumber(job and job.grade) or 0
    end

    return false, 0
end

ChestBuilderServer.PlayerGrade = playerGroupGrade

function ChestBuilderServer.CanAccess(xPlayer, chest)
    if not chest then return false end
    if not chest.accessName or chest.accessName == "" then return true end

    local belongs, grade = playerGroupGrade(xPlayer, chest.accessName)
    if not belongs then return false end

    local minGrade = math.min(chest.gradeMinPut or 0, chest.gradeMinTake or 0)
    return grade >= minGrade
end

function ChestBuilderServer.SendToPlayer(source)
    local views = {}
    for _, chest in ipairs(ChestBuilderServer.List()) do views[#views + 1] = clientView(chest) end
    TriggerClientEvent("chestBuilder:client:getPlayerChests", source, { views })
end

Inv.RegisterNet("chestBuilder:server:openChest", function(id, pincode)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local chest = ChestBuilderServer.Find(id)
    if not chest then return end

    if not ChestBuilderServer.CanAccess(xPlayer, chest) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas acces a ce coffre." })
        return
    end

    if chest.pincode and chest.pincode > 0 then
        local given = tonumber(pincode)
        if not given or math.floor(given) ~= chest.pincode then
            xPlayer.showNotification({ type = "ROUGE", content = "Ce code PIN n'est pas valide" })
            return
        end
    end

    local coords = Inv.PlayerCoords(source)
    if coords and chest.coords then
        if Inv.Distance(coords, chest.coords) > 5.0 then
            xPlayer.showNotification({ type = "ROUGE", content = "Vous etes trop loin du coffre." })
            return
        end
    end

    Inv.ConfigureChest(chestIdFor(chest.id), {
        label = chest.label,
        maxWeight = chest.maxWeight,
        maxSlots = chest.maxSlots,
    })

    TriggerClientEvent("chestBuilder:client:openChest", source, chestIdFor(chest.id), chest.maxWeight)
end)

AddEventHandler("vfw:characterLoaded", function(source)
    CreateThread(function()
        Wait(3000)
        ChestBuilderServer.SendToPlayer(source)
    end)
end)

AddEventHandler("vfw:setJob", function(source, job, previous)
    if not job then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local map = {}
    for _, chest in pairs(ChestBuilderServer.cache) do
        if ChestBuilderServer.CanAccess(xPlayer, chest) then
            map[tostring(chest.id)] = clientView(chest)
        end
    end

    TriggerClientEvent("chestBuilder:client:syncOnGroupChange", source, map, previous and previous.name or "")
end)

VFW.RegisterCommand("createchest", "chest_builder", function(source, xPlayer, args)
    local coords = Inv.PlayerCoords(source)
    if not coords then return end

    local accessName = args[1] or ""
    local gradeMinPut = math.floor(tonumber(args[2]) or 0)
    local gradeMinTake = math.floor(tonumber(args[3]) or 0)
    local pincode = tonumber(args[4])

    if pincode then
        pincode = math.floor(pincode)
        if pincode <= 0 or #tostring(pincode) > 9 then pincode = nil end
    end

    local accessLabel = accessName
    if accessName ~= "" and VFW.Jobs[accessName] then
        accessLabel = VFW.Jobs[accessName].label
    end

    local id = MySQL.insert.await([[
        INSERT INTO chest_builder (coords, access_name, access_label, grade_min_put, grade_min_take, pincode, max_weight, max_slots, label)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        VFW.DB.Encode({ x = coords.x, y = coords.y, z = coords.z, floatingZ = 0.5 }),
        accessName, accessLabel, gradeMinPut, gradeMinTake, pincode or 0, 400, 50, "Coffre",
    })

    if not id then
        xPlayer.showNotification({ type = "ROUGE", content = "Creation du coffre impossible." })
        return
    end

    local chest = {
        id = id,
        name = "Coffre",
        coords = { x = coords.x, y = coords.y, z = coords.z, floatingZ = 0.5 },
        accessName = accessName,
        accessLabel = accessLabel,
        gradeMinPut = gradeMinPut,
        gradeMinTake = gradeMinTake,
        pincode = pincode,
        maxWeight = 400,
        maxSlots = 50,
        label = "Coffre",
    }

    ChestBuilderServer.cache[id] = chest
    Inv.ConfigureChest(chestIdFor(id), { label = chest.label, maxWeight = chest.maxWeight, maxSlots = chest.maxSlots })

    TriggerClientEvent("chestBuilder:client:syncNewChest", -1, clientView(chest))
    xPlayer.showNotification({ type = "VERT", content = ("Coffre #%s cree."):format(tostring(id)) })
end, {
    help = "Cree un coffre a votre position",
    params = {
        { name = "acces", help = "nom du job/faction (vide = public)" },
        { name = "gradeDepot", help = "grade minimum pour deposer" },
        { name = "gradeRetrait", help = "grade minimum pour retirer" },
        { name = "pincode", help = "code a 9 chiffres max (optionnel)" },
    },
})

VFW.RegisterCommand("deletechest", "chest_builder", function(source, xPlayer, args)
    local id = tonumber(args[1])
    if not id then
        xPlayer.showNotification({ type = "ROUGE", content = "Usage: /deletechest <id>" })
        return
    end

    if not ChestBuilderServer.cache[id] then
        xPlayer.showNotification({ type = "ROUGE", content = "Coffre introuvable." })
        return
    end

    MySQL.update("DELETE FROM chest_builder WHERE id = ?", { id })
    ChestBuilderServer.cache[id] = nil

    TriggerClientEvent("chestBuilder:client:deleteChest", -1, id)
    xPlayer.showNotification({ type = "VERT", content = ("Coffre #%d supprime."):format(id) })
end, {
    help = "Supprime un coffre du builder",
    params = { { name = "id", help = "identifiant du coffre" } },
})

VFW.RegisterCommand("editchestpin", "chest_builder", function(source, xPlayer, args)
    local id = tonumber(args[1])
    local pincode = tonumber(args[2])

    local chest = id and ChestBuilderServer.cache[id] or nil
    if not chest then
        xPlayer.showNotification({ type = "ROUGE", content = "Coffre introuvable." })
        return
    end

    if pincode then
        pincode = math.floor(pincode)
        if pincode <= 0 or #tostring(pincode) > 9 then pincode = nil end
    end

    chest.pincode = pincode
    MySQL.update("UPDATE chest_builder SET pincode = ? WHERE id = ?", { pincode or 0, id })

    TriggerClientEvent("chestBuilder:client:updateChest", -1, clientView(chest))
    xPlayer.showNotification({ type = "VERT", content = "Pin code mis a jour." })
end, {
    help = "Modifie le pin code d'un coffre",
    params = {
        { name = "id", help = "identifiant du coffre" },
        { name = "pincode", help = "code (vide pour retirer)" },
    },
})

-- ---------------------------------------------------------------------------
-- Menu staff (Builders > Coffres) : liste, création, modification, suppression.
--
-- Le menu (client/staff/menu/chest_builder.lua) appelait ces évènements depuis toujours, sans que
-- le serveur n'en écoute aucun : « Créer le coffre » ne faisait donc rien.
-- ---------------------------------------------------------------------------

local BUILDER_PERMISSION <const> = "chest_builder"
local DEFAULT_MAX_SLOTS <const> = 50   -- le client n'ouvre un coffre du builder qu'avec 50 emplacements

---@return table|nil xPlayer le joueur s'il a le droit de gérer les coffres
local function builderStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERMISSION) then return nil end
    return xPlayer
end

local function notify(xPlayer, kind, message)
    xPlayer.showNotification({ type = kind, content = message })
end

---@param value any
---@param max integer
---@return string|nil
local function cleanText(value, max)
    if type(value) ~= "string" then return nil end
    local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil end
    return trimmed:sub(1, max)
end

---@param value any
---@return number|nil x, number|nil y, number|nil z
local function readCoords(value)
    if type(value) ~= "table" and type(value) ~= "vector3" then return nil end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end
    return x + 0.0, y + 0.0, z + 0.0
end

--- Libellé affiché pour un accès : le métier, sinon la faction, sinon le nom tel quel.
---@param accessName string
---@return string
local function accessLabelFor(accessName)
    if accessName == "" then return "" end

    local job = VFW.Jobs and VFW.Jobs[accessName]
    if job and job.label then return job.label end

    local faction = VFW.Factions and VFW.Factions[accessName]
    if type(faction) == "table" and faction.label then return faction.label end

    return accessName
end

--- Valide ce que le menu envoie et le met au format d'un coffre du serveur.
---@param payload any
---@return table|nil chest
---@return string|nil reason
local function chestFromPayload(payload)
    if type(payload) ~= "table" then return nil, "Données invalides." end

    local label = cleanText(payload.label or payload.name, 100)
    if not label then return nil, "Le nom du coffre n'est pas valide." end

    local maxWeight = math.floor(tonumber(payload.maxWeight) or 0)
    if maxWeight <= 0 or maxWeight > 10000000 then return nil, "Le poids du coffre n'est pas valide." end

    local maxSlots = DEFAULT_MAX_SLOTS
    if payload.maxSlots ~= nil then
        maxSlots = math.floor(tonumber(payload.maxSlots) or DEFAULT_MAX_SLOTS)
        if maxSlots < 1 then maxSlots = 1 end
        if maxSlots > 500 then maxSlots = 500 end
    end

    local x, y, z = readCoords(payload.coords)
    if not x then return nil, "La position du coffre n'est pas valide." end

    local floatingZ = tonumber(payload.floatingZ) or 0.5
    if floatingZ < -10.0 then floatingZ = -10.0 end
    if floatingZ > 10.0 then floatingZ = 10.0 end

    local accessName = cleanText(payload.accessName, 60) or ""
    if accessName == "public" then accessName = "" end

    local function grade(value)
        local n = tonumber(value)
        if not n or n < 0 then return 0 end
        return math.min(math.floor(n), 99)
    end

    local gradeMinHistory = tonumber(payload.gradeMinHistory)
    if gradeMinHistory then gradeMinHistory = math.min(math.max(math.floor(gradeMinHistory), 0), 99) end

    local pincode = tonumber(payload.pincode)
    if pincode then
        pincode = math.floor(pincode)
        if pincode <= 0 or #tostring(pincode) > 9 then pincode = nil end
    end

    return {
        coords = { x = x, y = y, z = z, floatingZ = floatingZ },
        accessName = accessName,
        accessLabel = accessLabelFor(accessName),
        gradeMinPut = grade(payload.gradeMinPut),
        gradeMinTake = grade(payload.gradeMinTake),
        gradeMinHistory = gradeMinHistory,
        pincode = pincode,
        maxWeight = maxWeight,
        maxSlots = maxSlots,
        label = label,
        name = label,
    }
end

local function applyChestConfig(chest)
    Inv.ConfigureChest(chestIdFor(chest.id), {
        label = chest.label,
        maxWeight = chest.maxWeight,
        maxSlots = chest.maxSlots,
    })
end

--- Les coffres tels que le menu staff les liste (code PIN compris), par numéro.
Inv.RegisterCallback("chestBuilder:getAllChests", function(source)
    if not builderStaff(source) then return {} end

    local out = {}
    for _, chest in ipairs(ChestBuilderServer.List()) do out[#out + 1] = clientView(chest, true) end
    table.sort(out, function(a, b) return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end)
    return out
end)

Inv.RegisterNet("chestBuilder:server:create", function(payload)
    local source = source
    local xPlayer = builderStaff(source)
    if not xPlayer then return end

    local chest, reason = chestFromPayload(payload)
    if not chest then
        notify(xPlayer, "ROUGE", reason)
        return
    end

    local columns = "coords, access_name, access_label, grade_min_put, grade_min_take, pincode, max_weight, max_slots, label"
    local marks = "?, ?, ?, ?, ?, ?, ?, ?, ?"
    local params = {
        VFW.DB.Encode(chest.coords), chest.accessName, chest.accessLabel, chest.gradeMinPut, chest.gradeMinTake,
        chest.pincode or 0, chest.maxWeight, chest.maxSlots, chest.label,
    }
    if hasHistoryColumn then
        columns = columns .. ", grade_min_history"
        marks = marks .. ", ?"
        params[#params + 1] = chest.gradeMinHistory
    end

    local ok, id = pcall(MySQL.insert.await, ("INSERT INTO chest_builder (%s) VALUES (%s)"):format(columns, marks), params)
    if not ok or not id or id == 0 then
        console.error(("[chestBuilder] création impossible : %s"):format(tostring(id)))
        notify(xPlayer, "ROUGE", "Création du coffre impossible.")
        return
    end

    chest.id = tonumber(id)
    ChestBuilderServer.cache[chest.id] = chest
    applyChestConfig(chest)

    TriggerClientEvent("chestBuilder:client:syncNewChest", -1, clientView(chest))
    notify(xPlayer, "VERT", ("Coffre #%d créé."):format(chest.id))
    console.info(("[chestBuilder] %s a créé le coffre #%d (%s)"):format(xPlayer.name or source, chest.id, chest.label))
end)

Inv.RegisterNet("chestBuilder:server:update", function(payload)
    local source = source
    local xPlayer = builderStaff(source)
    if not xPlayer then return end

    local id = type(payload) == "table" and tonumber(payload.id) or nil
    if not id or not ChestBuilderServer.cache[id] then
        notify(xPlayer, "ROUGE", "Coffre introuvable.")
        return
    end

    local chest, reason = chestFromPayload(payload)
    if not chest then
        notify(xPlayer, "ROUGE", reason)
        return
    end
    chest.id = id

    local sets = "coords = ?, access_name = ?, access_label = ?, grade_min_put = ?, grade_min_take = ?, pincode = ?, max_weight = ?, max_slots = ?, label = ?"
    local params = {
        VFW.DB.Encode(chest.coords), chest.accessName, chest.accessLabel, chest.gradeMinPut, chest.gradeMinTake,
        chest.pincode or 0, chest.maxWeight, chest.maxSlots, chest.label,
    }
    if hasHistoryColumn then
        sets = sets .. ", grade_min_history = ?"
        params[#params + 1] = chest.gradeMinHistory
    end
    params[#params + 1] = id

    local ok, err = pcall(MySQL.update.await, ("UPDATE chest_builder SET %s WHERE id = ?"):format(sets), params)
    if not ok then
        console.error(("[chestBuilder] modification impossible : %s"):format(tostring(err)))
        notify(xPlayer, "ROUGE", "Modification du coffre impossible.")
        return
    end

    ChestBuilderServer.cache[id] = chest
    applyChestConfig(chest)

    TriggerClientEvent("chestBuilder:client:updateChest", -1, clientView(chest))
    notify(xPlayer, "VERT", ("Coffre #%d modifié."):format(id))
end)

Inv.RegisterNet("chestBuilder:server:delete", function(id)
    local source = source
    local xPlayer = builderStaff(source)
    if not xPlayer then return end

    id = tonumber(id)
    if not id or not ChestBuilderServer.cache[id] then
        notify(xPlayer, "ROUGE", "Coffre introuvable.")
        return
    end

    local key = chestIdFor(id)

    MySQL.update.await("DELETE FROM chest_builder WHERE id = ?", { id })
    -- Le contenu et l'historique partent avec le coffre : le numéro peut être réattribué plus tard
    -- (compteur auto-incrémenté relu au démarrage), et le nouveau coffre hériterait sinon des objets.
    MySQL.update.await("DELETE FROM chests WHERE chest_id = ?", { key })
    MySQL.update.await("DELETE FROM chest_history WHERE chest_id = ?", { key })

    ChestBuilderServer.cache[id] = nil
    Inv.Chests[key] = nil
    Inv.ChestOverrides[key] = nil

    TriggerClientEvent("chestBuilder:client:deleteChest", -1, id)
    notify(xPlayer, "VERT", ("Coffre #%d supprimé."):format(id))
    console.info(("[chestBuilder] %s a supprimé le coffre #%d"):format(xPlayer.name or source, id))
end)

Inv.RegisterNet("chestBuilder:server:clear", function(id)
    local source = source
    local xPlayer = builderStaff(source)
    if not xPlayer then return end

    id = tonumber(id)
    local chest = id and ChestBuilderServer.cache[id] or nil
    if not chest then
        notify(xPlayer, "ROUGE", "Coffre introuvable.")
        return
    end

    local key = chestIdFor(id)
    local stored = Inv.GetChest(key)
    if not stored then return end

    stored.items = {}
    Inv.SaveChest(key)
    Inv.RefreshChestViewers(key)

    notify(xPlayer, "VERT", ("Coffre #%d vidé."):format(id))
end)

Inv.RegisterNet("chestBuilder:server:deleteLogs", function(id)
    local source = source
    local xPlayer = builderStaff(source)
    if not xPlayer then return end

    id = tonumber(id)
    if not id or not ChestBuilderServer.cache[id] then
        notify(xPlayer, "ROUGE", "Coffre introuvable.")
        return
    end

    MySQL.update.await("DELETE FROM chest_history WHERE chest_id = ?", { chestIdFor(id) })
    notify(xPlayer, "VERT", ("Historique du coffre #%d supprimé."):format(id))
end)

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 60000 do
        Wait(200)
        waited = waited + 200
    end
    local ok, err = pcall(ChestBuilderServer.Load)
    if not ok then
        console.warn(("[chestBuilder] chargement impossible : %s"):format(tostring(err)))
    end
end)
