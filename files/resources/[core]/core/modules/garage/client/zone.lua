local vehicleType <const> = { "voiture/moto", "bateaux", "avion" }

-- Marker pour les garages faction
local function DrawFactionGarageMarker(coords)
    DrawMarker(
            23,
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            1.0, 1.0, 1.0,
            255, 0, 0, 255,
            false, false, 2, true, nil, false
    )
end

CreateThread(function()
    local sleep
    local playerCoords, distanceToSpawn, distanceToDelete
    local snapshot = {}

    while true do
        sleep = 1000
        playerCoords = GetEntityCoords(PlayerPedId())

        for i = #snapshot, 1, -1 do
            snapshot[i] = nil
        end
        for _, garage in pairs(Garage.list) do
            snapshot[#snapshot + 1] = garage
        end

        for i = 1, #snapshot do
            local garage = snapshot[i]

            if not garage._spawnVec then
                garage._spawnVec = vector3(garage.position.x, garage.position.y, garage.position.z)
                garage._deleteVec = vector3(garage.deletePosition.x, garage.deletePosition.y, garage.deletePosition.z)
            end

            distanceToSpawn = #(playerCoords - garage._spawnVec)
            distanceToDelete = #(playerCoords - garage._deleteVec)

            -- Vérification d'accès pour les garages society
            if garage.type == "society" and garage.access and garage.access.name then
                if not VFW.PlayerData.job or garage.access.name ~= VFW.PlayerData.job.name then
                    goto skip
                end
            end

            -- Vérification d'accès pour les garages faction
            if garage.type == "faction" and garage.access and garage.access.name then
                if not VFW.PlayerData.faction or garage.access.name ~= VFW.PlayerData.faction.name then
                    goto skip
                end
            end

            -- Dessiner le marker pour les garages faction (pas de ped)
            if garage.type == "faction" then
                if distanceToSpawn < 15.0 then
                    sleep = 0
                    DrawFactionGarageMarker(garage._spawnVec)
                end
            end

            if distanceToSpawn > 2.0 then
                goto continue
            end

            sleep = 0

            if not Garage.isOpen then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder au garage")
            end

            if VFW.Interact.JustPressed(0, 51) and not Garage.isOpen then
                Garage.currentGarage = garage
                Garage:Open()
            end

            :: continue ::

            if distanceToDelete > 15.0 then
                goto skip
            end

            sleep = 0

            Garage:DrawMarker(garage._deleteVec, vehicleType[tonumber(garage.vehType)] or vehicleType[1])

            local interactRange = tonumber(garage.vehType) == 3 and 8.0 or 2.5
            if distanceToDelete > interactRange then
                goto skip
            end

            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ranger son véhicule")

            if VFW.Interact.JustPressed(0, 51) then
                local vehicle <const> = GetVehiclePedIsIn(PlayerPedId(), false)
                TriggerServerEvent("garage:storeVehicle", garage.id, vehicle and VFW.Game.GetVehicleProperties(vehicle))
            end

            :: skip ::
        end
        Wait(sleep)
    end
end)
