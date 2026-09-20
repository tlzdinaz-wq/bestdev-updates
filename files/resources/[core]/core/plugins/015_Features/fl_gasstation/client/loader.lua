---@meta _
---@diagnostic disable: duplicate-doc-field

local GasStationBlips = {}

CreateThread(function()
    while not StaffMenu do
        Wait(100)
    end

    while not StaffMenu.gasStationBuilder or not StaffMenu.gasStationConfig do
        Wait(100)
    end
end)

CreateThread(function()
    Wait(1000)
    PumpInteraction.Start()
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('fl_gasstation:requestStationBlips')
end)

RegisterNetEvent('fl_gasstation:createBlip', function(station)
    local blip = AddBlipForCoord(station.blipCoords.x, station.blipCoords.y, station.blipCoords.z)
    SetBlipSprite(blip, GasStationConfig.BlipConfig.sprite)
    SetBlipColour(blip, GasStationConfig.BlipConfig.color)
    SetBlipScale(blip, GasStationConfig.BlipConfig.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Station Essence")
    EndTextCommandSetBlipName(blip)

    GasStationBlips[station.id] = blip
end)

RegisterNetEvent('fl_gasstation:deleteBlip', function(stationId)
    if GasStationBlips[stationId] then
        RemoveBlip(GasStationBlips[stationId])
        GasStationBlips[stationId] = nil
    end
end)

RegisterNetEvent('fl_gasstation:forceRefreshPumps', function()
    if PumpInteraction and PumpInteraction.ForceRefresh then
        PumpInteraction.ForceRefresh()
    end
end)
