CreateThread(function()
    ZoneSafe:SyncSafeZone()

    local sleep = 1000

    while not VFW.PlayerData?.job do
        Wait(300)
    end

    while true do
        sleep = 1000

        local playerCoords = GetEntityCoords(PlayerPedId())
        local playerX, playerY = playerCoords.x, playerCoords.y

        for i = 1, #ZoneSafe.cache do
            local zone = ZoneSafe.cache[i]

            if not zone.center then
                zone.center = ZoneSafe:GetPolygonCenter(zone.points)
                zone.radius = ZoneSafe:GetPolygonRadius(zone.points, zone.center)
            end

            local distToCenter = #(vector2(playerX, playerY) - vector2(zone.center.x, zone.center.y))

            if distToCenter > zone.radius + 10 then
                ZoneSafe:ExitedZone(zone)
                goto continue
            end

            if not ZoneSafe:IsPointInPolygon(zone.points, playerX, playerY) then
                ZoneSafe:ExitedZone(zone)
                goto continue
            end

            sleep = 0

            ZoneSafe:EnteredOnZone(zone)

            if ZoneSafe:GetPlayerJobIsByPass(zone.bypassJob) then
                goto continue
            end

            ZoneSafe:ApplyDisabledAction(zone.actionDisabled)

            ::continue::
        end

        Wait(sleep)
    end
end)
