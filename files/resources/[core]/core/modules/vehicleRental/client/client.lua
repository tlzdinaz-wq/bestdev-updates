tVehicleRental = tVehicleRental or {}
tVehicleRental.List = {}

tVehicleRental.Blip = {
    [1] = {sprite = 304, color = 5, scale = 0.5, name = "Location de Véhicules"},
    [2] = {sprite = 404, color = 5, scale = 0.5, name = "Location de Bateaux"},
    [3] = {sprite = 736, color = 20, scale = 0.5, name = "Location de Véhicules (Cayo)"},
}
local iOpenId
local iOpenType
local iCurrentHelpType = nil

CreateThread(function()
    local iTime
    local iDist = 0

    while true do
        iTime = 750
        local bNearRental = false

        local playerCoords = GetEntityCoords(PlayerPedId())
        for i = 1, #tVehicleRental.List do
            local tRentalData <const> = tVehicleRental.List[i]
            if not tRentalData?.tPos then
                goto continue
            end

            local tPos <const> = tRentalData.tPos
            iDist = #(playerCoords - vec3(tPos.x, tPos.y, tPos.z))

            if iDist < 2.0 then
                iTime = 0
                bNearRental = true

                local iType <const> = tRentalData.iType
                local sText <const> = iType == 1 and "Voitures" or (iType == 2 and "Bateaux" or "Véhicules (Cayo)")
                local bPlaySound = iCurrentHelpType ~= iType
                iCurrentHelpType = iType

                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la location de " .. sText)

                if VFW.Interact.JustReleased(0, 38) then
                    tVehicleRental:OpenCarRentalMenu(tRentalData.iType)
                    iOpenId = tRentalData.iId
                    iOpenType = tRentalData.iType
                end
            end

            ::continue::
        end

        if not bNearRental then
            iCurrentHelpType = nil
        end

        Wait(iTime)
    end
end)

RegisterNetEvent("core:vehicleRental:Init", function(tRentalData, tVehicleConfig)
    tVehicleRental:DeleteAll()

    local tNewList = {}

    for iId, tData in pairs(tRentalData) do
        tData.iId = iId
        tNewList[#tNewList + 1] = tData
    end

    tVehicleRental.List = tNewList
    tVehicleRental:Init()

    tVehicleRental.tVehicleConfig = tVehicleConfig
end)

RegisterNetEvent("core:vehicleRental:Create", function(tRentalData, iId)
    tRentalData.iId = iId
    tVehicleRental.List[#tVehicleRental.List + 1] = tRentalData
    tVehicleRental:Create(tRentalData)
end)

RegisterNetEvent("core:vehicleRental:Update", function(tRentalData, iId)
    local tData <const>, iIndex <const> = tVehicleRental:GetRentalData(iId)
    if not tData then return end

    tVehicleRental:Delete(iId)

    tRentalData.iId = iId
    tVehicleRental.List[iIndex] = tRentalData
    tVehicleRental:Create(tRentalData)
end)

RegisterNetEvent("core:vehicleRental:Delete", function(iId)
    tVehicleRental:Delete(iId)
end)

RegisterNetEvent("core:vehicleRental:UpdateConfig", function(tVehicleConfig)
    tVehicleRental.tVehicleConfig = tVehicleConfig
end)

RegisterClientCallback("core:getClosestVehicle", function(tPos)
    local oVehicle <const> = GetClosestVehicle(tPos.x, tPos.y, tPos.z, 3.0, 0, 70)
    if not oVehicle then return false end

    return DoesEntityExist(oVehicle)
end)

RegisterNUICallback("nui:vehicleRental:close", function(_, cb)
    tVehicleRental:CloseNui()
    iOpenId = nil
    iOpenType = nil
    cb('ok')
end)

RegisterNUICallback("vehicleRental:return", function(_, cb)
    tVehicleRental:CloseNui()

    if iOpenType then
        TriggerServerEvent("core:vehicleRental:return", iOpenType)
    end

    iOpenId = nil
    iOpenType = nil
    cb('ok')
end)

RegisterNUICallback("vehicleRental:rent", function(tData, cb)
    tVehicleRental:CloseNui()

    TriggerServerEvent("core:vehicleRental:rent", tData, iOpenId)

    iOpenId = nil
    iOpenType = nil
    cb('ok')
end)

