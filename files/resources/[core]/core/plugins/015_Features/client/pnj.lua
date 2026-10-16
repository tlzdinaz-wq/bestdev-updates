CreateThread(function()
    while true do
        Wait(0)

        -- Désactive les PNJ civils
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)

        -- Désactive les véhicules PNJ
        SetVehicleDensityMultiplierThisFrame(0.0)
        SetRandomVehicleDensityMultiplierThisFrame(0.0)
        SetParkedVehicleDensityMultiplierThisFrame(0.0)

        -- Désactive les événements aléatoires (ambulance, police, etc.)
        SetRandomBoats(false)
        SetGarbageTrucks(false)
        SetRandomTrains(false)
    end
end)

-- Supprime les peds déjà spawn au lancement
CreateThread(function()
    Wait(5000)
    for ped in EnumeratePeds() do
        if not IsPedAPlayer(ped) then
            DeleteEntity(ped)
        end
    end
end)

-- Fonction pour parcourir les peds
function EnumeratePeds()
    return coroutine.wrap(function()
        local handle, ped = FindFirstPed()
        if not handle or handle == -1 then
            EndFindPed(handle)
            return
        end

        local success
        repeat
            coroutine.yield(ped)
            success, ped = FindNextPed(handle)
        until not success

        EndFindPed(handle)
    end)
end
