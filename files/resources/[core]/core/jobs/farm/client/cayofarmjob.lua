local function ShowJobNotification(content, isError)
    local societyImage = TriggerServerCallback("core:get:societyImage")
    local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or "Information"
    local notifType = isError and 'ROUGE' or 'JOB'
    VFW.ShowNotification({
        type = notifType,
        image = societyImage,
        title = jobLabel,
        subtitle = "Information",
        content = content
    })
end

local sellingPed = nil
local sellingBlip = nil

RegisterNetEvent("farm:cayofarm:sellingPed", function(pos)
    if sellingPed then
        DeleteEntity(sellingPed)
        sellingPed = nil
    end
    if sellingBlip and DoesBlipExist(sellingBlip) then
        RemoveBlip(sellingBlip)
        sellingBlip = nil
    end

    if pos and pos.x ~= 0.0 then
        sellingPed = VFW.CreatePed(vector4(pos.x, pos.y, pos.z, pos.heading), "a_m_y_beach_01")
        FreezeEntityPosition(sellingPed, false)
        Wait(5000)
        FreezeEntityPosition(sellingPed, true)

        local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or ""
        sellingBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipSprite(sellingBlip, 480)
        SetBlipDisplay(sellingBlip, 4)
        SetBlipScale(sellingBlip, 0.6)
        SetBlipColour(sellingBlip, 2)
        SetBlipAsShortRange(sellingBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(jobLabel .. " · Vente")
        EndTextCommandSetBlipName(sellingBlip)
    end
end)

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local deadline = GetGameTimer() + 5000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
            Wait(10)
        end
    end
end

local inHarvest = false
local inSelling = false
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        local hasGoodJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == "cayofarm"

        for i = 1, #CayoFarmConfig.harvest do
            local harvestCoords = CayoFarmConfig.harvest[i]
            local dist = #(pCoords - harvestCoords)

            if dist < 2.0 and hasGoodJob then
                wait = 0

                if dist < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récolter")

                    if VFW.Interact.JustReleased(0, 38) and not inHarvest then
                        inHarvest = true
                        local dict = "amb@world_human_gardener_plant@male@enter"
                        local name = "enter"
                        local flag = 49
                        local delay = 5000

                        loadAnimDict(dict)
                        TaskPlayAnim(ped, dict, name, 3.0, -1.0, delay, flag, 0.0, false, false, false)

                        local success = VFW.Nui.ProgressBar("Récolte des mangues...", 5000)
                        FreezeEntityPosition(PlayerPedId(), true)

                        if success then
                            ClearPedTasksImmediately(ped)
                            TriggerServerEvent("farm:cayofarm:give", i, "harvest")
                        end
                        FreezeEntityPosition(PlayerPedId(), false)

                        inHarvest = false
                    end
                end
            end
        end

        for fruit_type, coords in pairs(CayoFarmConfig.processing) do
            local dist = #(pCoords - vec3(coords.x, coords.y, coords.z))

            if dist < 2.0 and hasGoodJob then
                wait = 0
                DrawMarker(25, coords.x, coords.y, coords.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 0, 255, 200, false, false, 2, nil, nil, false)

                if dist < 1.5 then
                    VFW.ShowHelpNotification(("Appuyez sur ~INPUT_CONTEXT~ pour presser les mangues en %s"):format(VFW.Items[CayoFarmConfig.items.process[fruit_type]].label:lower()))

                    if VFW.Interact.JustReleased(0, 38) then
                        local canProcess = TriggerServerCallback("farm:cayofarm:canProcess", "process", fruit_type)

                        if canProcess then
                            local animDict = "anim@amb@business@coc@coc_unpack_cut@"
                            local animName = "fullcut_cycle_v6_cokecutter"

                            RequestAnimDict(animDict)
                            local timeout = 0
                            while not HasAnimDictLoaded(animDict) and timeout < 50 do
                                Wait(50)
                                timeout = timeout + 1
                            end

                            if HasAnimDictLoaded(animDict) then
                                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                            end

                            local success = VFW.Nui.ProgressBar("Pressage des mangues...", 5000)

                            ClearPedTasks(ped)
                            RemoveAnimDict(animDict)

                            if success then
                                TriggerServerEvent("farm:cayofarm:give", fruit_type, "process")
                            end
                        else
                            ShowJobNotification(("Vous devez avoir au moins 5 %s."):format(VFW.Items[fruit_type].label or fruit_type), false)
                        end
                    end
                end
            end
        end

        if sellingPed and #(GetEntityCoords(sellingPed) - pCoords) < 2.5 then
            wait = 0
            if #(GetEntityCoords(sellingPed) - pCoords) < 1.5 then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre votre jus de mangue")
                if VFW.Interact.JustReleased(0, 38) and not inSelling then
                    local canSell = TriggerServerCallback("farm:cayofarm:canProcess", "selling")
                    if canSell then
                        inSelling = true

                        Citizen.CreateThread(function()
                            local animDict = "mp_common"
                            RequestAnimDict(animDict)
                            while not HasAnimDictLoaded(animDict) do
                                Wait(50)
                            end

                            TaskTurnPedToFaceEntity(ped, sellingPed, 5000)
                            TaskPlayAnim(ped, animDict, "givetake1_a", 8.0, -8.0, 5000, 0, 0, false, false, false)

                            local success = VFW.Nui.ProgressBar("Vente...", 5000)

                            ClearPedTasks(ped)

                            if success then
                                TriggerServerEvent("farm:cayofarm:selling")
                            else
                                ShowJobNotification("Vente annulée.", false)
                            end

                            inSelling = false
                        end)
                    else
                        ShowJobNotification("Vous n'avez plus de jus de mangue.", false)
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)
