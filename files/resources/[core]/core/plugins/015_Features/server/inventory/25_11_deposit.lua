local Inv = VFW.Inventory

DepositBuilderServer = DepositBuilderServer or {}
DepositBuilderServer.cache = {}

local function depositChestId(pointId, citizenid)
    return ("deposit:%s:%s"):format(tostring(pointId), tostring(citizenid))
end

local function rowToPoint(row)
    return {
        id = row.id,
        coords = VFW.DB.Decode(row.coords, { x = 0.0, y = 0.0, z = 0.0 }),
        label = row.label or "Depot",
        accessName = row.access_name or "",
        managerGrade = tonumber(row.manager_grade) or 0,
        maxWeight = tonumber(row.max_weight) or 1000,
        maxSlots = tonumber(row.max_slots) or 100,
    }
end

function DepositBuilderServer.Load()
    local rows = MySQL.query.await("SELECT * FROM deposit_points") or {}
    DepositBuilderServer.cache = {}
    for i = 1, #rows do
        local point = rowToPoint(rows[i])
        DepositBuilderServer.cache[point.id] = point
    end
    console.init("DepositBuilder", ("%d points charges"):format(#rows))
end

function DepositBuilderServer.List()
    local out = {}
    for _, point in pairs(DepositBuilderServer.cache) do
        out[#out + 1] = {
            id = point.id,
            coords = { x = point.coords.x, y = point.coords.y, z = point.coords.z },
            label = point.label,
        }
    end
    return out
end

function DepositBuilderServer.Find(pointId)
    return DepositBuilderServer.cache[tonumber(pointId)] or DepositBuilderServer.cache[pointId]
end

function DepositBuilderServer.IsManager(xPlayer, point)
    if not point then return false end
    if xPlayer.hasPermission("builder") then return true end
    if point.accessName == "" then return false end

    local job = xPlayer.job
    if job and job.name == point.accessName then
        return (tonumber(job.grade) or 0) >= point.managerGrade
    end

    local job2 = xPlayer.job2
    if job2 and job2.name == point.accessName then
        return (tonumber(job2.grade) or 0) >= point.managerGrade
    end

    local faction = xPlayer.faction
    if type(faction) == "table" and faction.name == point.accessName then
        return (tonumber(faction.grade) or 0) >= point.managerGrade
    end

    return false
end

local function ensureEntry(pointId, xPlayer)
    local chestId = depositChestId(pointId, xPlayer.identifier)

    local row = MySQL.single.await("SELECT id FROM deposit_entries WHERE point_id = ? AND citizenid = ?", {
        pointId, xPlayer.identifier,
    })

    if not row then
        MySQL.insert.await(
            "INSERT INTO deposit_entries (point_id, citizenid, name, chest_id) VALUES (?, ?, ?, ?)",
            { pointId, xPlayer.identifier, xPlayer.name, chestId }
        )
    else
        MySQL.update("UPDATE deposit_entries SET name = ? WHERE point_id = ? AND citizenid = ?", {
            xPlayer.name, pointId, xPlayer.identifier,
        })
    end

    local point = DepositBuilderServer.Find(pointId)
    Inv.ConfigureChest(chestId, {
        label = point and (point.label .. " - depot") or "Depot",
        maxWeight = point and point.maxWeight or 1000,
        maxSlots = point and point.maxSlots or 100,
    })

    return chestId
end

Inv.RegisterCallback("depositBuilder:getAllPoints", function()
    return DepositBuilderServer.List()
end)

Inv.RegisterCallback("depositBuilder:getEntries", function(source, pointId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local point = DepositBuilderServer.Find(pointId)
    if not point or not DepositBuilderServer.IsManager(xPlayer, point) then return {} end

    local rows = MySQL.query.await("SELECT citizenid, name FROM deposit_entries WHERE point_id = ?", { point.id }) or {}

    local out = {}
    for i = 1, #rows do
        out[i] = { citizenid = rows[i].citizenid, name = rows[i].name }
    end
    return out
end)

Inv.RegisterNet("depositBuilder:server:interact", function(pointId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local point = DepositBuilderServer.Find(pointId)
    if not point then return end

    local coords = Inv.PlayerCoords(source)
    if coords and Inv.Distance(coords, point.coords) > 5.0 then return end

    if DepositBuilderServer.IsManager(xPlayer, point) then
        TriggerClientEvent("depositBuilder:client:openConsult", source, point.id, point.label)
    else
        TriggerClientEvent("depositBuilder:client:openMenu", source, point.id, point.label)
    end
end)

Inv.RegisterNet("depositBuilder:server:depositAll", function(pointId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local point = DepositBuilderServer.Find(pointId)
    if not point then return end

    local coords = Inv.PlayerCoords(source)
    if coords and Inv.Distance(coords, point.coords) > 5.0 then return end

    local chestId = ensureEntry(point.id, xPlayer)
    local chest = Inv.GetChest(chestId)
    if not chest then return end

    local list = Inv.PlayerList(xPlayer)
    local moved = 0

    for i = #list, 1, -1 do
        local entry = list[i]
        local taken = Inv.RemoveFromSlot(list, entry.slot, entry.count)
        if taken then
            local added = Inv.AddToList(chest.items, taken.name, taken.count, taken.meta, chest.maxSlots)
            if added < taken.count then
                Inv.AddToList(list, taken.name, taken.count - added, taken.meta, Inv.PlayerMaxSlots)
            end
            if added > 0 then
                moved = moved + added
                Inv.LogChest(chestId, xPlayer, "put", taken.name, added, taken.meta)
            end
        end
    end

    if moved > 0 then
        Inv.MarkChestDirty(chestId)
        Inv.RefreshChestViewers(chestId)
        Inv.PushPlayer(xPlayer)
        xPlayer.showNotification({ type = "VERT", content = ("%d objets deposes."):format(moved) })
    else
        xPlayer.showNotification({ type = "ORANGE", content = "Rien a deposer." })
    end
end)

Inv.RegisterNet("depositBuilder:server:withdrawAll", function(pointId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local point = DepositBuilderServer.Find(pointId)
    if not point then return end

    local coords = Inv.PlayerCoords(source)
    if coords and Inv.Distance(coords, point.coords) > 5.0 then return end

    local chestId = depositChestId(point.id, xPlayer.identifier)
    local chest = Inv.GetChest(chestId)
    if not chest then return end

    local list = Inv.PlayerList(xPlayer)
    local moved = 0
    local tooHeavy = false

    for i = #chest.items, 1, -1 do
        local entry = chest.items[i]
        local carryable = Inv.MaxCarryable(xPlayer, entry.name, entry.count)
        if carryable <= 0 then
            tooHeavy = true
        else
            if carryable < entry.count then tooHeavy = true end
            local taken = Inv.RemoveFromSlot(chest.items, entry.slot, carryable)
            if taken then
                local added = Inv.AddToList(list, taken.name, taken.count, taken.meta, Inv.PlayerMaxSlots)
                if added < taken.count then
                    Inv.AddToList(chest.items, taken.name, taken.count - added, taken.meta, chest.maxSlots)
                end
                if added > 0 then
                    moved = moved + added
                    Inv.LogChest(chestId, xPlayer, "take", taken.name, added, taken.meta)
                end
            end
        end
    end

    if tooHeavy then
        TriggerClientEvent("inventory:transferTooHeavy", source)
    end

    if moved > 0 then
        Inv.MarkChestDirty(chestId)
        Inv.RefreshChestViewers(chestId)
        Inv.PushPlayer(xPlayer)
    end
end)

Inv.RegisterNet("depositBuilder:server:openEntry", function(pointId, citizenid)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(citizenid) ~= "string" or citizenid == "" then return end

    local point = DepositBuilderServer.Find(pointId)
    if not point or not DepositBuilderServer.IsManager(xPlayer, point) then return end

    local chestId = depositChestId(point.id, citizenid)
    Inv.ConfigureChest(chestId, {
        label = point.label .. " - depot",
        maxWeight = point.maxWeight,
        maxSlots = point.maxSlots,
    })

    TriggerClientEvent("depositBuilder:client:openReadOnly", source, chestId)
end)

AddEventHandler("vfw:characterLoaded", function(source)
    CreateThread(function()
        Wait(2500)
        TriggerClientEvent("depositBuilder:client:init", source, DepositBuilderServer.List())
    end)
end)

VFW.RegisterCommand("createdeposit", "builder", function(source, xPlayer, args)
    local coords = Inv.PlayerCoords(source)
    if not coords then return end

    local label = args[1] or "Depot"
    local accessName = args[2] or ""
    local managerGrade = math.floor(tonumber(args[3]) or 0)

    local id = MySQL.insert.await([[
        INSERT INTO deposit_points (coords, label, access_name, manager_grade, max_weight, max_slots)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        VFW.DB.Encode({ x = coords.x, y = coords.y, z = coords.z }),
        label, accessName, managerGrade, 1000, 100,
    })

    if not id then
        xPlayer.showNotification({ type = "ROUGE", content = "Creation du point impossible." })
        return
    end

    local point = {
        id = id,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        label = label,
        accessName = accessName,
        managerGrade = managerGrade,
        maxWeight = 1000,
        maxSlots = 100,
    }

    DepositBuilderServer.cache[id] = point
    TriggerClientEvent("depositBuilder:client:sync", -1, {
        id = point.id,
        coords = point.coords,
        label = point.label,
    })

    xPlayer.showNotification({ type = "VERT", content = ("Point de depot #%s cree."):format(tostring(id)) })
end, {
    help = "Cree un point de depot a votre position",
    params = {
        { name = "label", help = "nom affiche" },
        { name = "acces", help = "job/faction gestionnaire" },
        { name = "grade", help = "grade minimum gestionnaire" },
    },
})

VFW.RegisterCommand("deletedeposit", "builder", function(source, xPlayer, args)
    local id = tonumber(args[1])
    if not id or not DepositBuilderServer.cache[id] then
        xPlayer.showNotification({ type = "ROUGE", content = "Point introuvable." })
        return
    end

    MySQL.update("DELETE FROM deposit_points WHERE id = ?", { id })
    DepositBuilderServer.cache[id] = nil

    TriggerClientEvent("depositBuilder:client:remove", -1, id)
    xPlayer.showNotification({ type = "VERT", content = ("Point #%d supprime."):format(id) })
end, {
    help = "Supprime un point de depot",
    params = { { name = "id", help = "identifiant du point" } },
})

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 60000 do
        Wait(200)
        waited = waited + 200
    end
    local ok, err = pcall(DepositBuilderServer.Load)
    if not ok then
        console.warn(("[depositBuilder] chargement impossible : %s"):format(tostring(err)))
    end
end)
