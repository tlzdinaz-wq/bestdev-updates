CreateThread(function()
    local sleep = 1000
    local playerCoords
    local point
    local entryDist, exitDist
    local nearestId, nearestType, nearestDist

    while true do
        sleep = 1000

        if IsNuiFocused() or IsPauseMenuActive() then
            Wait(sleep)
            goto continue
        end

        playerCoords = GetEntityCoords(PlayerPedId())
        nearestId = nil
        nearestType = nil
        nearestDist = 3.0

        for i = 1, #TeleportBuilder.cache do
            point = TeleportBuilder.cache[i]

            if point and point.entry and point.exit then
                entryDist = #(playerCoords - vector3(point.entry.x, point.entry.y, point.entry.z))
                exitDist = #(playerCoords - vector3(point.exit.x, point.exit.y, point.exit.z))

                if entryDist < nearestDist then
                    nearestDist = entryDist
                    nearestId = point.id
                    nearestType = "entry"
                end

                if exitDist < nearestDist then
                    nearestDist = exitDist
                    nearestId = point.id
                    nearestType = "exit"
                end
            end
        end

        if nearestId then
            sleep = 0
            VFW.ShowHelpNotification(nearestType == "entry" and "Appuyez sur ~INPUT_CONTEXT~ pour entrer" or "Appuyez sur ~INPUT_CONTEXT~ pour sortir")

            if VFW.Interact.JustPressed(0, 38) then
                TriggerServerEvent("teleportBuilder:server:interact", nearestId)
                Wait(500)
            end
        end

        Wait(sleep)
        ::continue::
    end
end)
