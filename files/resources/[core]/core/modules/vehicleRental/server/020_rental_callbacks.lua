local Rental = VFW.Rental

RegisterServerCallback("core:vehicleRental:getActiveRental", function(source, iType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local rentalType = tonumber(iType)
    if not rentalType or rentalType < 1 or rentalType > 3 then return nil end

    local entry = Rental.FindActive(xPlayer.identifier, math.floor(rentalType))
    if not entry then return nil end

    return {
        sVehicleName = entry.sLabel ~= nil and entry.sLabel ~= "" and entry.sLabel or entry.sVehicleName,
        sPlate = entry.sPlate,
    }
end)

RegisterServerCallback("core:vehicleRental:getPlayerAccounts", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { cash = 0, bank = 0 } end

    local cash = xPlayer.getAccount("money")
    local bank = xPlayer.getAccount("bank")

    return {
        cash = cash and tonumber(cash.money) or 0,
        bank = bank and tonumber(bank.money) or 0,
    }
end)

RegisterServerCallback("core:vehicleRental:getVehicleConfig", function(source)
    return Rental.BuildCatalogPayload()
end)

RegisterServerCallback("core:getAllVehicleRental", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_vehicleRental") then return {} end

    local out = {}
    for _, point in pairs(Rental.points) do
        out[#out + 1] = Rental.Serialize(point)
    end
    return out
end)
