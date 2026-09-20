local MARKER_TYPE = 27
local MARKER_DRAW_DISTANCE = 25.0
local MARKER_DRAW_DISTANCE_SQ = MARKER_DRAW_DISTANCE * MARKER_DRAW_DISTANCE
local INTERACT_DISTANCE = 2.0
local INTERACT_DISTANCE_SQ = INTERACT_DISTANCE * INTERACT_DISTANCE

CreateThread(function()
    while true do
        local sleep = 1000

        if not IsNuiFocused() and not IsPauseMenuActive() then
            local pc = GetEntityCoords(PlayerPedId())
            local nearestId, nearestDistSq
            local anyDrawn = false

            for i = 1, #DepositBuilder.cache do
                local point = DepositBuilder.cache[i]
                if point and point.coords then
                    local dx = pc.x - point.coords.x
                    local dy = pc.y - point.coords.y
                    local dz = pc.z - point.coords.z
                    local distSq = dx * dx + dy * dy + dz * dz

                    if distSq <= MARKER_DRAW_DISTANCE_SQ then
                        anyDrawn = true
                        sleep = 0
                        DrawMarker(MARKER_TYPE,
                            point.coords.x, point.coords.y, point.coords.z - 0.95,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.6, 0.6, 0.4,
                            120, 180, 255, 120,
                            false, false, 2, false, nil, nil, false)

                        if distSq <= INTERACT_DISTANCE_SQ then
                            if not nearestDistSq or distSq < nearestDistSq then
                                nearestId = point.id
                                nearestDistSq = distSq
                            end
                        end
                    end
                end
            end

            if nearestId then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour interagir avec le dépôt")
                if VFW.Interact.JustPressed(0, 38) then
                    TriggerServerEvent("depositBuilder:server:interact", nearestId)
                    Wait(500)
                end
            end

            if not anyDrawn then
                sleep = 1000
            end
        end

        Wait(sleep)
    end
end)
