RegisterNetEvent('zonesafe:client:add', function(newZone)
    ZoneSafe:ReformatZones({newZone})
end)

RegisterNetEvent('zonesafe:client:remove', function(name)
    if not name then
        return
    end

    ZoneSafe:RemoveZone(name)
end)

RegisterNetEvent('zonesafe:client:update', function(oldName, newData)
    ZoneSafe:UpdateZone(oldName, newData)
end)

--- Liste complète envoyée par le serveur (joueur connecté pendant le démarrage, ou
--- rechargement). On repart de zéro pour ne pas empiler deux fois les mêmes zones.
RegisterNetEvent('zonesafe:client:sync', function(list)
    if type(list) ~= 'table' then
        return
    end

    for i = #ZoneSafe.cache, 1, -1 do
        ZoneSafe:RemoveZone(ZoneSafe.cache[i].name)
    end

    ZoneSafe:ReformatZones(list)
end)

--- Zone interdisant les armes : le serveur demande au joueur de rengainer.
RegisterNetEvent('zonesafe:client:holster', function()
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
end)
