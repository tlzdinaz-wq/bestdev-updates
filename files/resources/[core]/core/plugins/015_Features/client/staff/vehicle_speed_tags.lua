---@meta _
---@diagnostic disable: duplicate-doc-field

local vehicleSpeedTagsActive = false

StaffMenu.vehicleSpeedTagsActive = false

function StaffMenu.IsVehicleSpeedTagsActive()
    return vehicleSpeedTagsActive
end

function StaffMenu.ToggleVehicleSpeedTags(state)
    vehicleSpeedTagsActive = state
    StaffMenu.vehicleSpeedTagsActive = state

    if vehicleSpeedTagsActive then
        CreateThread(function()
            while vehicleSpeedTagsActive do
                local myPed = PlayerPedId()
                local myCoords = GetEntityCoords(myPed, false)
                local activePlayers = GetActivePlayers()

                for i = 1, #activePlayers do
                    local playerId = activePlayers[i]
                    local playerPed = GetPlayerPed(playerId)

                    if playerPed ~= myPed and DoesEntityExist(playerPed) then
                        local playerCoords = GetEntityCoords(playerPed, false)
                        local dist = #(myCoords - playerCoords)

                        if dist < 200.0 then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)

                            if vehicle ~= 0 then
                                local speedMs = GetEntitySpeed(vehicle)
                                local speedKmh = math.ceil(speedMs * 3.6)

                                if speedKmh > 0 then
                                    local pedCoords = GetEntityCoords(playerPed, false)
                                    local zOffset = 1.3

                                    local r, g, b = 255, 255, 255
                                    if speedKmh > 200 then
                                        r, g, b = 231, 76, 60
                                    elseif speedKmh > 130 then
                                        r, g, b = 243, 156, 18
                                    elseif speedKmh > 80 then
                                        r, g, b = 255, 255, 255
                                    else
                                        r, g, b = 46, 204, 113
                                    end

                                    local px, py, pz = table.unpack(GetGameplayCamCoords())
                                    local camDist = #(vector3(px, py, pz) - vector3(pedCoords.x, pedCoords.y, pedCoords.z))
                                    local scale = (1 / camDist) * 20
                                    local fov = (1 / GetGameplayCamFov()) * 100
                                    scale = scale * fov

                                    SetTextScale(0.35 * scale, 0.35 * scale)
                                    SetTextFont(4)
                                    SetTextProportional(1)
                                    SetTextColour(r, g, b, 255)
                                    SetTextDropshadow(1, 1, 1, 1, 255)
                                    SetTextEdge(2, 0, 0, 0, 200)
                                    SetTextDropShadow()
                                    SetTextOutline()
                                    SetTextEntry("STRING")
                                    SetTextCentre(1)
                                    AddTextComponentString(tostring(speedKmh) .. " km/h")
                                    SetDrawOrigin(pedCoords.x, pedCoords.y, pedCoords.z + zOffset, 0)
                                    DrawText(0.0, 0.0)
                                    ClearDrawOrigin()
                                end
                            end
                        end
                    end
                end

                Wait(0)
            end
        end)
    end
end
