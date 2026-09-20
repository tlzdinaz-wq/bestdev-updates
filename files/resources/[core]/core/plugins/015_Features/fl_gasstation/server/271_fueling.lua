Feat27 = Feat27 or {}

local sessions = {}
local validations = {}

local MAX_LITERS = 200.0
local PUMP_RADIUS = 12.0
local VEHICLE_RADIUS = 12.0

local function readLiters(data)
    local candidates = { data.liters, data.litres, data.amount, data.quantity, data.value }
    for i = 1, #candidates do
        local n = tonumber(candidates[i])
        if n and n > 0 then return n end
    end
    return nil
end

local function readPayment(data)
    local method = data.paymentMethod or data.payment or data.method or data.paymentType
    if method == "bank" or method == "card" or method == "carte" then return "bank" end
    return "cash"
end

local function fuelStatebag(netId, percent)
    local entity = Feat27.EntityFromNet(netId)
    if not entity then return false end
    local state = Entity(entity).state
    state:set("fuel", percent, true)
    state:set("VehicleFuel", percent, true)
    return true
end

RegisterNetEvent("fl_gasstation:validateFueling", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not Feat27.RateLimit(source, "gas:validate", 400) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local netId = tonumber(data.vehicleNetId)
    if not netId then
        TriggerClientEvent("fl_gasstation:fuelingValidated", source, { success = false, message = "Véhicule introuvable." })
        return
    end

    local vehicle = Feat27.EntityFromNet(netId)
    if not vehicle then
        TriggerClientEvent("fl_gasstation:fuelingValidated", source, { success = false, message = "Véhicule non synchronisé." })
        return
    end

    local playerCoords = Feat27.PlayerCoords(source)
    if not playerCoords then
        TriggerClientEvent("fl_gasstation:fuelingValidated", source, { success = false, message = "Position introuvable." })
        return
    end

    if #(playerCoords - GetEntityCoords(vehicle)) > VEHICLE_RADIUS then
        TriggerClientEvent("fl_gasstation:fuelingValidated", source, { success = false, message = "Vous êtes trop loin du véhicule." })
        return
    end

    local pump = GasStationServer.NearestPump(playerCoords, PUMP_RADIUS)
    if not pump then
        TriggerClientEvent("fl_gasstation:fuelingValidated", source, { success = false, message = "Aucune pompe à proximité." })
        return
    end

    local fuelLevel = tonumber(data.clientFuelLevel) or 0.0
    if fuelLevel < 0.0 then fuelLevel = 0.0 end
    if fuelLevel > 100.0 then fuelLevel = 100.0 end

    local maxFuel = tonumber(data.clientMaxFuel) or 65.0
    if maxFuel <= 0.0 or maxFuel > MAX_LITERS then maxFuel = 65.0 end

    validations[source] = {
        netId = netId,
        pump = pump,
        stationId = pump.stationId,
        fuelLevel = fuelLevel,
        maxFuel = maxFuel,
        at = GetGameTimer(),
    }

    TriggerClientEvent("fl_gasstation:fuelingValidated", source, {
        success = true,
        message = "Pompe prête.",
        vehicleData = {
            vehicle = { netId = netId },
            pumpCoords = { x = pump.coords.x, y = pump.coords.y, z = pump.coords.z },
            clientFuelLevel = fuelLevel,
            clientMaxFuel = maxFuel,
        },
    })
end)

RegisterNetEvent("fl_gasstation:purchaseFuel", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not Feat27.RateLimit(source, "gas:purchase", 600) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local function fail(message)
        TriggerClientEvent("fl_gasstation:purchaseComplete", source, { success = false, message = message })
    end

    local netId = tonumber(data.vehicleNetId)
    if not netId then return fail("Aucun véhicule validé.") end

    local validation = validations[source]
    if not validation or validation.netId ~= netId then
        return fail("Recommencez l'interaction avec la pompe.")
    end

    if sessions[source] then
        return fail("Un remplissage est déjà en cours.")
    end

    local vehicle = Feat27.EntityFromNet(netId)
    if not vehicle then return fail("Véhicule introuvable.") end

    local playerCoords = Feat27.PlayerCoords(source)
    if not playerCoords or #(playerCoords - GetEntityCoords(vehicle)) > VEHICLE_RADIUS then
        return fail("Vous êtes trop loin du véhicule.")
    end

    local missing = validation.maxFuel * (1.0 - (validation.fuelLevel / 100.0))
    if missing < 0.0 then missing = 0.0 end

    local liters = readLiters(data)
    if not liters then
        liters = missing
    end

    if liters <= 0.0 then return fail("Le réservoir est déjà plein.") end
    if liters > missing + 0.5 then liters = missing end
    if liters > MAX_LITERS then liters = MAX_LITERS end
    if liters <= 0.0 then return fail("Le réservoir est déjà plein.") end

    local price = GasStationServer.GetPrice()
    local cost = math.floor(liters * price + 0.5)
    if cost < 0 then cost = 0 end

    local method = readPayment(data)
    if method == "bank" then
        local bank = xPlayer.getAccount("bank")
        if not bank or bank.money < cost then return fail("Fonds bancaires insuffisants.") end
        xPlayer.removeAccountMoney("bank", cost, "station-essence")
    else
        if xPlayer.getMoney() < cost then return fail("Vous n'avez pas assez d'argent.") end
        xPlayer.removeAccountMoney("money", cost, "station-essence")
    end

    sessions[source] = {
        netId = netId,
        liters = liters,
        price = price,
        cost = cost,
        method = method,
        stationId = validation.stationId,
        startedAt = GetGameTimer(),
    }

    MySQL.insert("INSERT INTO gas_station_logs (`identifier`, `station_id`, `liters`, `amount`) VALUES (?, ?, ?, ?)", {
        xPlayer.identifier, validation.stationId, liters, cost,
    })

    TriggerClientEvent("fl_gasstation:startManualFueling", source, {
        success = true,
        message = ("%.1fL achetés pour %d$."):format(liters, cost),
        vehicleNetId = netId,
        liters = liters,
        pumpCoords = validation.pump and {
            x = validation.pump.coords.x,
            y = validation.pump.coords.y,
            z = validation.pump.coords.z,
        } or nil,
    })
end)

RegisterNetEvent("fl_gasstation:syncVehicleFuel", function(vehicleNetId, newFuelPercent)
    local source = source
    local netId = tonumber(vehicleNetId)
    local percent = tonumber(newFuelPercent)
    if not netId or not percent then return end
    if percent < 0.0 then percent = 0.0 end
    if percent > 100.0 then percent = 100.0 end

    if not Feat27.RateLimit(source, "gas:sync", 200) then return end

    local vehicle = Feat27.EntityFromNet(netId)
    if not vehicle then return end

    local playerCoords = Feat27.PlayerCoords(source)
    if not playerCoords or #(playerCoords - GetEntityCoords(vehicle)) > 25.0 then return end

    fuelStatebag(netId, percent)
    TriggerEvent("vfw:vehicle:fuelSynced", source, netId, percent)
end)

RegisterNetEvent("fl_gasstation:fuelingComplete", function(vehicleNetId)
    local source = source
    local netId = tonumber(vehicleNetId)
    if not netId then return end

    local session = sessions[source]
    if not session or session.netId ~= netId then return end
    sessions[source] = nil
    validations[source] = nil
end)

RegisterNetEvent("fl_gasstation:fuelingCancelled", function(vehicleNetId, unusedLiters)
    local source = source
    local netId = tonumber(vehicleNetId)
    if not netId then return end

    local session = sessions[source]
    if not session or session.netId ~= netId then return end

    local unused = tonumber(unusedLiters) or 0.0
    if unused < 0.0 then unused = 0.0 end
    if unused > session.liters then unused = session.liters end

    sessions[source] = nil
    validations[source] = nil

    local refund = math.floor(unused * session.price + 0.5)
    if refund > session.cost then refund = session.cost end
    if refund <= 0 then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.addAccountMoney(session.method == "bank" and "bank" or "money", refund, "station-essence-remboursement")
end)

AddEventHandler("vfw:playerDropped", function(source)
    sessions[source] = nil
    validations[source] = nil
end)

function Feat27.GasCancelFueling(source)
    sessions[source] = nil
    validations[source] = nil
    TriggerClientEvent("fl_gasstation:cancelFueling", source)
end
