local Inv = VFW.Inventory

ChestBuilderServer = ChestBuilderServer or {}
ChestBuilderServer.cache = {}

local function chestIdFor(id)
    return ("chestbuilder:%s"):format(tostring(id))
end

local function rowToChest(row)
    local pin = tonumber(row.pincode) or 0
    return {
        id = row.id,
        coords = VFW.DB.Decode(row.coords, { x = 0.0, y = 0.0, z = 0.0 }),
        accessName = row.access_name or "",
        accessLabel = row.access_label or "",
        gradeMinPut = tonumber(row.grade_min_put) or 0,
        gradeMinTake = tonumber(row.grade_min_take) or 0,
        pincode = pin > 0 and pin or nil,
        maxWeight = tonumber(row.max_weight) or 400,
        maxSlots = tonumber(row.max_slots) or 50,
        label = row.label or "Coffre",
    }
end

function ChestBuilderServer.Load()
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

function ChestBuilderServer.CanAccess(xPlayer, chest)
    if not chest then return false end
    if not chest.accessName or chest.accessName == "" then return true end

    local belongs, grade = playerGroupGrade(xPlayer, chest.accessName)
    if not belongs then return false end

    local minGrade = math.min(chest.gradeMinPut or 0, chest.gradeMinTake or 0)
    return grade >= minGrade
end

function ChestBuilderServer.SendToPlayer(source)
    TriggerClientEvent("chestBuilder:client:getPlayerChests", source, { ChestBuilderServer.List() })
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
            map[tostring(chest.id)] = chest
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

    TriggerClientEvent("chestBuilder:client:syncNewChest", -1, chest)
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

    TriggerClientEvent("chestBuilder:client:updateChest", -1, chest)
    xPlayer.showNotification({ type = "VERT", content = "Pin code mis a jour." })
end, {
    help = "Modifie le pin code d'un coffre",
    params = {
        { name = "id", help = "identifiant du coffre" },
        { name = "pincode", help = "code (vide pour retirer)" },
    },
})

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
