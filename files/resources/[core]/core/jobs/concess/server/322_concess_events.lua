VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Concess = VFW.Concess or {}

local JC = VFW.JobsCommon
local Concess = VFW.Concess

local activeTests = {}

local function findSpawnPoint(entry)
    local candidates = {}
    for i = 1, #(entry.spawn or {}) do candidates[#candidates + 1] = entry.spawn[i] end
    for i = 1, #(entry.catalog or {}) do candidates[#candidates + 1] = entry.catalog[i] end
    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

Concess.FindSpawnPoint = findSpawnPoint

local function sanitizeColor(color)
    if type(color) ~= "table" then return nil end
    local r = JC.Int(color.r, 0, 255)
    local g = JC.Int(color.g, 0, 255)
    local b = JC.Int(color.b, 0, 255)
    if not r or not g or not b then return nil end
    return { r = r, g = g, b = b }
end

RegisterNetEvent("core:concess:buyVehicle", function(concessId, model, price, paymentMethod, vehicleLabel, color)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = Concess.Get(concessId)
    if not entry then return end

    local modelName = JC.Str(model, 64)
    if not modelName then return end
    modelName = modelName:lower()

    local vehicle = Concess.Vehicle(modelName)
    if not vehicle then
        JC.Notify(source, "Ce vehicule n'est pas au catalogue.", true)
        return
    end

    if not JC.Throttle(source, "concess:buy", 3000) then return end

    if entry.catalog and #entry.catalog > 0 and not JC.NearAny(source, entry.catalog, 60.0) then
        JC.Notify(source, "Vous n'etes pas au concessionnaire.", true)
        return
    end

    local finalPrice = vehicle.price
    local method = JC.Str(paymentMethod, 16)
    if method ~= "cash" and method ~= "money" then method = "bank" end

    local accountName = (method == "bank") and "bank" or "money"
    local account = xPlayer.getAccount(accountName)
    if not account or (tonumber(account.money) or 0) < finalPrice then
        JC.Notify(source, "Fonds insuffisants.", true)
        return
    end

    local spawnPoint = findSpawnPoint(entry)
    if not spawnPoint then
        JC.Notify(source, "Aucun point de sortie disponible.", true)
        return
    end

    local plate = Concess.GeneratePlate()
    local label = JC.Str(vehicleLabel, 96) or vehicle.name or modelName
    local paint = sanitizeColor(color)

    if not Concess.StoreVehicle(xPlayer, modelName, label, plate, paint) then
        JC.Notify(source, "Erreur lors de l'enregistrement du vehicule.", true)
        return
    end

    xPlayer.removeAccountMoney(accountName, finalPrice, ("Achat vehicule %s"):format(modelName))

    if VFW.Vehicles and VFW.Vehicles.Spawn then
        local props = { plate = plate }
        if paint then
            props.customPrimaryColor = { paint.r, paint.g, paint.b }
            props.customSecondaryColor = { paint.r, paint.g, paint.b }
        end
        local spawned = VFW.Vehicles.Spawn(source, modelName, spawnPoint, spawnPoint.h or 0.0, props)
        if spawned and DoesEntityExist(spawned) then
            pcall(SetVehicleNumberPlateText, spawned, plate)
        end
    end

    TriggerClientEvent("core:concess:showVehicleGps", source, spawnPoint.x, spawnPoint.y, spawnPoint.z, plate)

    Concess.Log(entry.id, "sale", ("Vente %s (%s)"):format(label, plate), JC.PlayerName(xPlayer), finalPrice)

    if entry.job ~= "" then
        JC.AddSocietyMoney(entry.job, math.floor(finalPrice * 0.15), "concess-vente")
    end

    JC.Notify(source, ("Vehicule achete pour %d$. Plaque : %s"):format(finalPrice, plate), false)
    TriggerClientEvent("concess:stockUpdated", -1, entry.id)
end)

RegisterNetEvent("core:concess:buyForStock", function(concessId, model, price, name)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = Concess.Get(concessId)
    if not entry then return end

    if not Concess.IsEmployee(xPlayer, entry) and not Concess.CanBuild(xPlayer) then
        JC.Notify(source, "Vous n'etes pas employe de ce concessionnaire.", true)
        return
    end

    local modelName = JC.Str(model, 64)
    if not modelName then return end
    modelName = modelName:lower()

    local vehicle = Concess.Vehicle(modelName)
    if not vehicle then return end

    if not JC.Throttle(source, "concess:stock", 1500) then return end

    local cost = math.floor(vehicle.price * Concess.StockBuyRatio)
    if cost < 1 then cost = 1 end

    if not JC.RemoveSocietyMoney(entry.job, cost) then
        JC.Notify(source, "Fonds de la societe insuffisants.", true)
        return
    end

    local label = JC.Str(name, 128) or vehicle.name or modelName
    Concess.AddStock(entry.id, modelName, label, 1)
    Concess.Log(entry.id, "purchase", ("Achat usine %s"):format(label), JC.PlayerName(xPlayer), cost)

    TriggerClientEvent("concess:stockUpdated", -1, entry.id)
    JC.Notify(source, ("%s ajoute au stock pour %d$."):format(label, cost), false)
end)

RegisterNetEvent("core:concess:returnFromStock", function(concessId, model)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = Concess.Get(concessId)
    if not entry then return end

    if not Concess.IsEmployee(xPlayer, entry) and not Concess.CanBuild(xPlayer) then return end

    local modelName = JC.Str(model, 64)
    if not modelName then return end
    modelName = modelName:lower()

    if not JC.Throttle(source, "concess:stock", 1500) then return end

    local row = Concess.StockRow(entry.id, modelName)
    if not row or (JC.Int(row.quantity, 0) or 0) <= 0 then return end
    if row.in_test == 1 or row.in_test == true then
        JC.Notify(source, "Ce vehicule est en essai.", true)
        return
    end

    if not Concess.AddStock(entry.id, modelName, row.name, -1) then return end

    local vehicle = Concess.Vehicle(modelName)
    local base = vehicle and vehicle.price or 0
    local refund = math.floor(base * Concess.StockBuyRatio * Concess.StockRefundRatio)

    if refund > 0 then
        JC.AddSocietyMoney(entry.job, refund, "concess-retour-stock")
    end

    Concess.Log(entry.id, "purchase", ("Retour usine %s"):format(row.name or modelName), JC.PlayerName(xPlayer), refund)
    TriggerClientEvent("concess:stockUpdated", -1, entry.id)
    JC.Notify(source, ("Vehicule renvoye, %d$ recuperes."):format(refund), false)
end)

local function clearTest(source, notifyEvent)
    local test = activeTests[source]
    if not test then return end
    activeTests[source] = nil

    if test.entity and DoesEntityExist(test.entity) then
        DeleteEntity(test.entity)
    end

    Concess.SetInTest(test.concessId, test.model, false)
    TriggerClientEvent("concess:stockUpdated", -1, test.concessId)

    if notifyEvent then
        TriggerClientEvent(notifyEvent, source)
    end
end

Concess.ClearTest = clearTest

RegisterNetEvent("core:concess:startTest", function(concessId, model)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = Concess.Get(concessId)
    if not entry then return end

    if not Concess.IsEmployee(xPlayer, entry) and not Concess.CanBuild(xPlayer) then return end

    local modelName = JC.Str(model, 64)
    if not modelName then return end
    modelName = modelName:lower()

    if not JC.Throttle(source, "concess:test", 3000) then return end

    if activeTests[source] then
        JC.Notify(source, "Vous avez deja un vehicule d'essai.", true)
        return
    end

    local row = Concess.StockRow(entry.id, modelName)
    if not row or (JC.Int(row.quantity, 0) or 0) <= 0 then
        JC.Notify(source, "Ce vehicule n'est pas en stock.", true)
        return
    end
    if row.in_test == 1 or row.in_test == true then
        JC.Notify(source, "Ce vehicule est deja en essai.", true)
        return
    end

    local spawnPoint = findSpawnPoint(entry)
    if not spawnPoint then
        JC.Notify(source, "Aucun point de sortie disponible.", true)
        return
    end

    if not VFW.Vehicles or not VFW.Vehicles.Spawn then
        JC.Notify(source, "Systeme vehicule indisponible.", true)
        return
    end

    local plate = ("ESSAI%02d"):format(math.random(0, 99))
    local vehicleEntity, netId = VFW.Vehicles.Spawn(source, modelName, spawnPoint, spawnPoint.h or 0.0, { plate = plate })

    if not vehicleEntity or not DoesEntityExist(vehicleEntity) or not netId then
        JC.Notify(source, "Impossible de sortir le vehicule d'essai.", true)
        return
    end

    pcall(SetVehicleNumberPlateText, vehicleEntity, plate)
    Concess.SetInTest(entry.id, modelName, true)

    activeTests[source] = {
        entity = vehicleEntity,
        netId = netId,
        plate = plate,
        model = modelName,
        concessId = entry.id,
        expires = GetGameTimer() + Concess.TestDuration,
    }

    TriggerClientEvent("concess:testVehicleSpawned", source, netId, plate, entry.id)
    TriggerClientEvent("concess:stockUpdated", -1, entry.id)
end)

RegisterNetEvent("core:concess:stopTest", function(concessId, model)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local test = activeTests[source]
    if not test then return end

    local wantedId = JC.Int(concessId)
    if wantedId and wantedId ~= test.concessId then return end

    clearTest(source, "concess:testVehicleDeleted")
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = GetGameTimer()
        for src, test in pairs(activeTests) do
            if now >= (test.expires or 0) then
                clearTest(src, "concess:testExpired")
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local source = source
    clearTest(source, nil)
end)

RegisterNetEvent("core:concess:sellFromStock", function(concessId, model, targetPlayerId, vehicleLabel, color, discountPercent)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = Concess.Get(concessId)
    if not entry then return end

    if not Concess.IsEmployee(xPlayer, entry) and not Concess.CanBuild(xPlayer) then
        JC.Notify(source, "Vous n'etes pas employe de ce concessionnaire.", true)
        return
    end

    local modelName = JC.Str(model, 64)
    if not modelName then return end
    modelName = modelName:lower()

    local targetId = JC.Int(targetPlayerId, 1)
    if not targetId or targetId == source then return end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then
        JC.Notify(source, "Client introuvable.", true)
        return
    end

    if JC.DistPlayers(source, targetId) > 12.0 then
        JC.Notify(source, "Le client est trop loin.", true)
        return
    end

    if not JC.Throttle(source, "concess:sell", 3000) then return end

    local vehicle = Concess.Vehicle(modelName)
    if not vehicle then return end

    local row = Concess.StockRow(entry.id, modelName)
    if not row or (JC.Int(row.quantity, 0) or 0) <= 0 then
        JC.Notify(source, "Ce vehicule n'est pas en stock.", true)
        return
    end

    local discount = JC.Int(discountPercent, 0, 50) or 0
    local finalPrice = math.floor(vehicle.price * (100 - discount) / 100)
    if finalPrice < 0 then finalPrice = 0 end

    local account = target.getAccount("bank")
    if not account or (tonumber(account.money) or 0) < finalPrice then
        JC.Notify(source, "Le client n'a pas assez d'argent en banque.", true)
        JC.Notify(targetId, "Vous n'avez pas assez d'argent en banque.", true)
        return
    end

    local spawnPoint = findSpawnPoint(entry)
    if not spawnPoint then
        JC.Notify(source, "Aucun point de sortie disponible.", true)
        return
    end

    local plate = Concess.GeneratePlate()
    local label = JC.Str(vehicleLabel, 96) or vehicle.name or modelName
    local paint = sanitizeColor(color)

    if not Concess.StoreVehicle(target, modelName, label, plate, paint) then
        JC.Notify(source, "Erreur lors de l'enregistrement du vehicule.", true)
        return
    end

    target.removeAccountMoney("bank", finalPrice, ("Achat vehicule %s"):format(modelName))
    Concess.AddStock(entry.id, modelName, row.name, -1)

    if entry.job ~= "" then
        JC.AddSocietyMoney(entry.job, finalPrice, "concess-vente-stock")
    end

    if VFW.Vehicles and VFW.Vehicles.Spawn then
        local props = { plate = plate }
        if paint then
            props.customPrimaryColor = { paint.r, paint.g, paint.b }
            props.customSecondaryColor = { paint.r, paint.g, paint.b }
        end
        local spawned = VFW.Vehicles.Spawn(targetId, modelName, spawnPoint, spawnPoint.h or 0.0, props)
        if spawned and DoesEntityExist(spawned) then
            pcall(SetVehicleNumberPlateText, spawned, plate)
        end
    end

    TriggerClientEvent("core:concess:showVehicleGps", targetId, spawnPoint.x, spawnPoint.y, spawnPoint.z, plate)

    Concess.Log(entry.id, "sale",
        ("Vente %s a %s (%s)"):format(label, JC.PlayerName(target), plate), JC.PlayerName(xPlayer), finalPrice)

    TriggerClientEvent("concess:stockUpdated", -1, entry.id)
    JC.Notify(source, ("Vehicule vendu %d$."):format(finalPrice), false)
    JC.Notify(targetId, ("Vous avez achete un vehicule pour %d$. Plaque : %s"):format(finalPrice, plate), false)
end)

local function showcaseGuard(source, concessId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, nil end

    local entry = Concess.Get(concessId)
    if not entry and xPlayer.job then
        entry = Concess.Ensure(xPlayer.job.name) or Concess.GetByJob(xPlayer.job.name)
    end
    if not entry then return nil, nil end

    if not Concess.IsEmployee(xPlayer, entry) and not Concess.CanBuild(xPlayer) then return nil, nil end
    return xPlayer, entry
end

RegisterNetEvent("core:concess:updateShowcase", function(concessId, index, model)
    local source = source
    local _, entry = showcaseGuard(source, concessId)
    if not entry then return end

    local idx = JC.Int(index, 1)
    if not idx or not entry.showcase[idx] then return end

    local modelName = JC.Str(model, 64)
    if not modelName then return end

    entry.showcase[idx].model = modelName:lower()
    Concess.Persist(entry)
    Concess.Broadcast(entry)
end)

RegisterNetEvent("core:concess:updateShowcaseColor", function(concessId, index, color)
    local source = source
    local _, entry = showcaseGuard(source, concessId)
    if not entry then return end

    local idx = JC.Int(index, 1)
    if not idx or not entry.showcase[idx] then return end

    local paint = sanitizeColor(color)
    if not paint then return end

    entry.showcase[idx].color = paint
    Concess.Persist(entry)
    Concess.Broadcast(entry)
end)

RegisterNetEvent("core:concess:updateShowcaseRotate", function(concessId, index, rotate)
    local source = source
    local _, entry = showcaseGuard(source, concessId)
    if not entry then return end

    local idx = JC.Int(index, 1)
    if not idx or not entry.showcase[idx] then return end

    entry.showcase[idx].rotate = rotate == true
    Concess.Persist(entry)
    Concess.Broadcast(entry)
end)

RegisterNetEvent("core:concess:removeShowcasePoint", function(concessId, index)
    local source = source
    local _, entry = showcaseGuard(source, concessId)
    if not entry then return end

    local idx = JC.Int(index, 1)
    if not idx or not entry.showcase[idx] then return end

    table.remove(entry.showcase, idx)
    Concess.Persist(entry)
    Concess.Broadcast(entry)
end)

RegisterNetEvent("core:concess:addShowcasePoint", function(concessId, point)
    local source = source
    local _, entry = showcaseGuard(source, concessId)
    if not entry then
        JC.Notify(source, "Concessionnaire introuvable.", true)
        return
    end

    if type(point) ~= "table" then return end
    local coords = JC.Vec4(point)
    if not coords then
        JC.Notify(source, "Position d'exposition invalide.", true)
        return
    end

    local modelName = JC.Str(point.model, 64)
    if not modelName then
        JC.Notify(source, "Modele de vehicule invalide.", true)
        return
    end

    entry.showcase = entry.showcase or {}
    if #entry.showcase >= 60 then
        JC.Notify(source, "Nombre maximum de points d'exposition atteint.", true)
        return
    end

    coords.model = modelName:lower()
    coords.rotate = point.rotate == true
    entry.showcase[#entry.showcase + 1] = coords

    Concess.Persist(entry)
    Concess.Broadcast(entry)
    JC.Notify(source, ("Vehicule d'exposition place : %s"):format(modelName), false)
end)

RegisterNetEvent("core:concess:giveKeyDuplicate", function(targetPlayerId, plate)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return end

    local entry = Concess.Ensure(xPlayer.job.name)
    if not entry then
        JC.Notify(source, "Vous n'etes pas employe d'un concessionnaire.", true)
        return
    end

    local targetId = JC.Int(targetPlayerId, 1)
    if not targetId or targetId == source then return end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return end

    if JC.DistPlayers(source, targetId) > 12.0 then
        JC.Notify(source, "Le client est trop loin.", true)
        return
    end

    local plateName = JC.Str(plate, 12)
    if not plateName then return end

    if not JC.Throttle(source, "concess:keys", 2000) then return end

    local row = JC.Single("SELECT plate, owner FROM owned_vehicles WHERE plate = ?", { plateName })
    if not row then
        JC.Notify(source, "Vehicule introuvable.", true)
        return
    end

    if row.owner ~= target.identifier then
        JC.Notify(source, "Ce vehicule n'appartient pas a ce client.", true)
        return
    end

    JC.Exec([[
        INSERT IGNORE INTO concess_key_duplicates (plate, identifier, granted_by, concess_id)
        VALUES (?, ?, ?, ?)
    ]], { plateName, target.identifier, xPlayer.identifier, entry.id })

    Concess.Log(entry.id, "sale", ("Double de cles %s"):format(plateName), JC.PlayerName(xPlayer), 0)

    JC.Notify(source, ("Double de cles remis pour %s."):format(plateName), false)
    JC.Notify(targetId, ("Vous avez recu un double de cles pour %s."):format(plateName), false)
end)

function Concess.HasKeyDuplicate(plate, identifier)
    if type(plate) ~= "string" or type(identifier) ~= "string" then return false end
    local row = JC.Single(
        "SELECT plate FROM concess_key_duplicates WHERE plate = ? AND identifier = ?",
        { plate, identifier })
    return row ~= nil
end

exports("hasVehicleKeyDuplicate", function(plate, identifier)
    return Concess.HasKeyDuplicate(plate, identifier)
end)

RegisterNetEvent("core:concess:create", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end
    if type(data) ~= "table" then return end

    local name = JC.Str(data.name, 128)
    if not name then return end

    local automatic = JC.Bool(data.automatic)
    local job = JC.Str(data.job, 64) or ""
    if not automatic and job == "" then return end

    local concessType = JC.Int(data.concessType, 1, 3) or 1

    local catalog = {}
    if type(data.catalog) == "table" then
        for i = 1, #data.catalog do
            local point = JC.Vec4(data.catalog[i])
            if point then catalog[#catalog + 1] = point end
        end
    end
    if #catalog == 0 then return end

    local preview, spawn = {}, {}
    if type(data.preview) == "table" then
        for i = 1, #data.preview do
            local point = JC.Vec4(data.preview[i])
            if point then preview[#preview + 1] = point end
        end
    end
    if type(data.spawn) == "table" then
        for i = 1, #data.spawn do
            local point = JC.Vec4(data.spawn[i])
            if point then spawn[#spawn + 1] = point end
        end
    end

    local showcase = Concess.DecodeShowcase(data.showcase or {})

    local insertId = JC.Insert([[
        INSERT INTO concess (name, job, concess_type, automatic, ped_model, catalog, preview, spawn, showcase)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        name,
        job,
        concessType,
        automatic and 1 or 0,
        JC.Str(data.pedModel, 64) or Concess.DefaultPed,
        JC.Encode(catalog),
        JC.Encode(preview),
        JC.Encode(spawn),
        JC.Encode(showcase),
    })

    if not insertId then return end

    Concess.Load()
    local entry = Concess.Get(insertId)
    if entry then
        TriggerClientEvent("concess:created", -1, Concess.Payload(entry))
    end
end)

RegisterNetEvent("core:concess:update", function(id, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end
    if type(data) ~= "table" then return end

    local entry = Concess.Get(id)
    if not entry then return end

    entry.name = JC.Str(data.name, 128) or entry.name
    entry.job = JC.Str(data.job, 64) or ""
    entry.concessType = JC.Int(data.concessType, 1, 3) or entry.concessType
    entry.automatic = JC.Bool(data.automatic)
    entry.pedModel = JC.Str(data.pedModel, 64) or entry.pedModel

    if type(data.catalog) == "table" then
        local catalog = {}
        for i = 1, #data.catalog do
            local point = JC.Vec4(data.catalog[i])
            if point then catalog[#catalog + 1] = point end
        end
        if #catalog > 0 then entry.catalog = catalog end
    end

    if type(data.preview) == "table" then
        local preview = {}
        for i = 1, #data.preview do
            local point = JC.Vec4(data.preview[i])
            if point then preview[#preview + 1] = point end
        end
        entry.preview = preview
    end

    if type(data.spawn) == "table" then
        local spawn = {}
        for i = 1, #data.spawn do
            local point = JC.Vec4(data.spawn[i])
            if point then spawn[#spawn + 1] = point end
        end
        entry.spawn = spawn
    end

    if type(data.showcase) == "table" then
        entry.showcase = Concess.DecodeShowcase(data.showcase)
    end

    Concess.Persist(entry)
    Concess.Load()
    Concess.Broadcast(Concess.Get(entry.id))
end)

RegisterNetEvent("core:concess:delete", function(id)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end

    local entry = Concess.Get(id)
    if not entry then return end

    JC.Exec("DELETE FROM concess WHERE id = ?", { entry.id })
    JC.Exec("DELETE FROM concess_stock WHERE concess_id = ?", { entry.id })
    JC.Exec("DELETE FROM concess_logs WHERE concess_id = ?", { entry.id })

    Concess.Load()
    TriggerClientEvent("concess:deleted", -1, entry.id)
end)

RegisterNetEvent("core:concess:createCategory", function(name, concessType)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end

    local categoryName = JC.Str(name, 64)
    if not categoryName then return end

    local catType = JC.Int(concessType, 1, 3) or 1

    JC.Exec([[
        INSERT INTO concess_categories (name, concess_type) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE concess_type = VALUES(concess_type)
    ]], { categoryName:lower(), catType })

    Concess.LoadCatalog()
end)

RegisterNetEvent("core:concess:deleteCategory", function(name)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end

    local categoryName = JC.Str(name, 64)
    if not categoryName then return end

    JC.Exec("DELETE FROM concess_vehicles WHERE category = ?", { categoryName:lower() })
    JC.Exec("DELETE FROM concess_categories WHERE name = ?", { categoryName:lower() })

    Concess.LoadCatalog()
end)

RegisterNetEvent("core:concess:addVehicle", function(model, name, category, price)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end

    local modelName = JC.Str(model, 64)
    local label = JC.Str(name, 128)
    local categoryName = JC.Str(category, 64)
    local value = JC.Int(price, 0, 1000000000) or 0

    if not modelName or not label or not categoryName then return end
    if not Concess.CategoryType(categoryName:lower()) then return end

    JC.Exec([[
        INSERT INTO concess_vehicles (model, name, price, category) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), price = VALUES(price), category = VALUES(category)
    ]], { modelName:lower(), label, value, categoryName:lower() })

    Concess.LoadCatalog()
end)

RegisterNetEvent("core:concess:updateVehicle", function(model, name, price, category)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end

    local modelName = JC.Str(model, 64)
    if not modelName then return end

    local existing = Concess.Vehicle(modelName)
    if not existing then return end

    local label = JC.Str(name, 128) or existing.name
    local value = JC.Int(price, 0, 1000000000) or existing.price
    local categoryName = JC.Str(category, 64) or existing.category

    JC.Exec("UPDATE concess_vehicles SET name = ?, price = ?, category = ? WHERE model = ?",
        { label, value, categoryName:lower(), modelName:lower() })

    Concess.LoadCatalog()
end)

RegisterNetEvent("core:concess:deleteVehicle", function(model)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return end

    local modelName = JC.Str(model, 64)
    if not modelName then return end

    JC.Exec("DELETE FROM concess_vehicles WHERE model = ?", { modelName:lower() })
    JC.Exec("DELETE FROM concess_stock WHERE model = ?", { modelName:lower() })

    Concess.LoadCatalog()
end)
