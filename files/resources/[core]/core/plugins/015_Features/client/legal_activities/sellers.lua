RegisterNetEvent("core:legal_activities:client:openShop", function(shopData)
    SendNUIMessage({
        action = "nui:shops:open",
        data = shopData
    })
    VFW.Nui.Focus(true)
end)

RegisterNUICallback("shops:close", function(data, cb)
    VFW.Nui.Focus(false)
    cb("ok")
end)

RegisterNUICallback("shops:sell:miner", function(data, cb)
    local result = TriggerServerCallback("core:legal_activities:server:sellItems", data.items)
    cb(result)
end)

CreateThread(function()
    for activityName, sellerData in pairs(Config.legalActivitiesSellers) do
        if sellerData.ped then
            -- Créer le blip
            local blip = AddBlipForCoord(sellerData.ped.position.x, sellerData.ped.position.y, sellerData.ped.position.z)
            SetBlipSprite(blip, 605)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 2)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(sellerData.label)
            EndTextCommandSetBlipName(blip)

            -- Ensure collision is loaded so the ped doesn't float
            RequestCollisionAtCoord(sellerData.ped.position.x, sellerData.ped.position.y, sellerData.ped.position.z)
            local colAttempts = 0
            while not HasCollisionLoadedAroundEntity(PlayerPedId()) and colAttempts < 20 do
                RequestCollisionAtCoord(sellerData.ped.position.x, sellerData.ped.position.y, sellerData.ped.position.z)
                Wait(50)
                colAttempts = colAttempts + 1
            end

            -- Créer le PED
            local ped <const> = cEntity.Manager:CreatePedLocal(
                sellerData.ped.model,
                vector3(sellerData.ped.position.x, sellerData.ped.position.y, sellerData.ped.position.z),
                sellerData.ped.position.w
            )
            local pedId <const> = ped:getEntityId()

            PlaceObjectOnGroundProperly(pedId)
            ped:setFreeze(true)
            SetEntityInvincible(pedId, true)
            SetBlockingOfNonTemporaryEvents(pedId, true)
            TaskStartScenarioInPlace(pedId, "WORLD_HUMAN_CLIPBOARD", 0, true)

            CreateThread(function()
                while true do
                    local playerPed <const> = PlayerPedId()
                    local playerCoords <const> = GetEntityCoords(playerPed)
                    local pedCoords <const> = GetEntityCoords(pedId)
                    local distance <const> = #(playerCoords - pedCoords)

                    if distance < 2.5 then
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre")

                        if VFW.Interact.JustPressed(0, 38) then
                            TriggerServerEvent("core:legal_activities:server:openSeller", activityName)
                        end
                    end

                    Wait(0)
                end
            end)
        end
    end
end)
