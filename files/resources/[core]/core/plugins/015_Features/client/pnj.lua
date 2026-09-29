-- Densité des PNJ et du trafic : gérée par plugins/015_Features/client/world_density.lua
-- (réglable en direct depuis Gestion > Serveur > Densité du monde). Ce fichier ne garde que
-- les évènements aléatoires, qui ne dépendent pas d'un multiplicateur de densité.
CreateThread(function()
    while true do
        SetRandomBoats(false)
        SetGarbageTrucks(false)
        SetRandomTrains(false)
        Wait(10000)
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
