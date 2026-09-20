local isHarvestingActive = false

-- Exports pour d'autres scripts
exports('isHarvesting', function()
    return isHarvestingActive
end)

exports('getCurrentHarvestingSpot', function()
    return exports['fl_illegal']:getCurrentSpot()
end)

exports('isNearHarvestingSpot', function()
    return exports['fl_illegal']:isNearSpot()
end)


-- Event pour démarrer une récolte
RegisterNetEvent('illegalHarvesting:startHarvestProgress', function(data)
    isHarvestingActive = true
end)

-- Event pour terminer une récolte
RegisterNetEvent('illegalHarvesting:harvestComplete', function()
    isHarvestingActive = false
end)

-- Event pour annuler une récolte
RegisterNetEvent('illegalHarvesting:cancelHarvest', function()
    isHarvestingActive = false
end)

