local currentStorages <const> = {}


local societyStorageInit = false
function Society.initStorage()
    if societyStorageInit then return end
    societyStorageInit = true

    CreateThread(function()
        local interval = 500


        while true do
            interval = 500

            if (Society?.data?.storage) then
                local playerCoords = GetEntityCoords(PlayerPedId())
                for k, position in pairs(Society.data.storage) do
                    if VFW.PlayerData.job.onDuty and #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(position.x, position.y, position.z)) < 5 then
                        interval = 0
                        DrawMarker(25, position.x, position.y, position.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 255, 255,
                            255, false, true, 2, nil, nil, false)

                        if #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(position.x, position.y, position.z)) < 1.5 then
                            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le stockage")
                            if VFW.Interact.JustReleased(0, 51) then
                                local action = TriggerServerCallback("society:storage:open")

                                if action and action.open then
                                    VFW.Nui.BigMenu(false)
                                    VFW.OpenChest(action.id, "stockage", 50)
                                end
                            end
                        end
                    end
                end
            end

            Wait(interval)
        end
    end)

    return true
end

function Society.unloadStorage()

end
