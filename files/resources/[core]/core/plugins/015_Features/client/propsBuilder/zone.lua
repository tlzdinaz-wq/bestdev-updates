CreateThread(function()
    local sleep, distance

    while true do
        sleep = 750

        if not VFW.PlayerData.ped then
            goto continue
        end


        for i = 1, #PropsBuilder.cache.zone do
            local zone = PropsBuilder.cache.zone[i]

            distance = #(GetEntityCoords(VFW.PlayerData.ped) - zone.center)
            if distance <= zone.radius and not zone.playerinZone then
                TriggerServerEvent("propsBuilder:checkVersion", zone.id, zone.version)
                zone.playerinZone = true
            elseif distance <= zone.radius and zone.playerinZone then
                PropsBuilder:DrawProps(zone.id)
                sleep = 0
            elseif distance > zone.radius and zone.playerinZone then
                zone.playerinZone = false
                PropsBuilder:ClearProps(zone.id)
                TriggerServerEvent("propsBuilder:playerExitZone", zone.id)
            end

        end

        ::continue::
        Wait(sleep)
    end

end)

