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