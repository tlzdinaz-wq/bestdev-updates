---
--- Job: Hen House Bar - Client
--- Type: Farm Job (Harvest → Process → Sell)
---

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
local dynamicHarvestPoints = nil
local dynamicProcessingPoints = nil
local dynamicHarvestAnim = nil
local dynamicProcessingAnim = nil
local dynamicSellingAnim = nil
local staticProps = {}

-- Props statiques a spawn (visibles par tous les joueurs)
local PropsToSpawn = {
    { model = "prop_ind_mech_01c", coords = vector4(939.74, -2172.50, 29.53, 180.0) },
}

local function SpawnStaticProps()
    for _, propData in ipairs(PropsToSpawn) do
        local model = GetHashKey(propData.model)

        RequestModel(model)
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do
            Wait(10)
        end

        if HasModelLoaded(model) then
            local prop = CreateObject(model, propData.coords.x, propData.coords.y, propData.coords.z, false, false, false)
            SetEntityHeading(prop, propData.coords.w)
            FreezeEntityPosition(prop, true)
            SetEntityCollision(prop, true, true)
            staticProps[#staticProps + 1] = prop
            SetModelAsNoLongerNeeded(model)
        end
    end
end

local function CleanupStaticProps()
    for _, prop in ipairs(staticProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    staticProps = {}
end

-- Spawn les props au demarrage
Citizen.CreateThread(function()
    Wait(1000)
    SpawnStaticProps()
end)

-- Cleanup quand la resource s'arrete
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupStaticProps()
end)

RegisterNetEvent("farm:henhouse:sellingPed", function(pos)
    if sellingPed then
        DeleteEntity(sellingPed)
        sellingPed = nil
    end
    if sellingBlip and DoesBlipExist(sellingBlip) then
        RemoveBlip(sellingBlip)
        sellingBlip = nil
    end

    if pos and pos.x ~= 0.0 then
        sellingPed = VFW.CreatePed(vector4(pos.x, pos.y, pos.z, pos.heading), "a_m_y_business_02")
        FreezeEntityPosition(sellingPed, false)
        Wait(5000)
        FreezeEntityPosition(sellingPed, true)

        local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or ""
        sellingBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipSprite(sellingBlip, 480)
        SetBlipDisplay(sellingBlip, 4)
        SetBlipScale(sellingBlip, 0.7)
        SetBlipColour(sellingBlip, 2)
        SetBlipAsShortRange(sellingBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(jobLabel .. " · Vente")
        EndTextCommandSetBlipName(sellingBlip)
    end
end)

RegisterNetEvent("farm:henhouse:syncZones", function(zones)
    if zones then
        dynamicHarvestPoints = zones.harvestPoints or nil
        dynamicProcessingPoints = zones.processingPoints or nil
        dynamicHarvestAnim = zones.animations and zones.animations.harvest or nil
        dynamicProcessingAnim = zones.animations and zones.animations.processing or nil
        dynamicSellingAnim = zones.animations and zones.animations.selling or nil
    else
        dynamicHarvestPoints = nil
        dynamicProcessingPoints = nil
        dynamicHarvestAnim = nil
        dynamicProcessingAnim = nil
        dynamicSellingAnim = nil
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

        local hasGoodJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == "henhouse"
        local isInVehicle = IsPedInAnyVehicle(ped, false)

        -- 1. LOGIQUE DE RECOLTE (Points)
        local harvestPoints = dynamicHarvestPoints or HenHouseBarConfig.harvest
        local nearestDist = math.huge
        for _, pt in ipairs(harvestPoints) do
            local d = #(pCoords - vector3(pt.x, pt.y, pt.z))
            if d < nearestDist then nearestDist = d end
        end

        if nearestDist <= 2.0 and hasGoodJob and not isInVehicle then
            wait = 0
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour recolter de l'orge")

            if VFW.Interact.JustReleased(0, 38) and not inHarvest then
                inHarvest = true
                local harvestAnim = dynamicHarvestAnim or { dict = "amb@world_human_gardener_plant@male@enter", name = "enter" }
                local dict = harvestAnim.dict
                local name = harvestAnim.name
                local flag = 49
                local delay = 3000

                loadAnimDict(dict)
                FreezeEntityPosition(ped, true)
                TaskPlayAnim(ped, dict, name, 3.0, -1.0, delay, flag, 0.0, false, false, false)

                local success = VFW.Nui.ProgressBar("Recolte de l'orge...", 3000)

                ClearPedTasksImmediately(ped)
                FreezeEntityPosition(ped, false)

                if success then
                    TriggerServerEvent("farm:henhouse:give", "harvest")
                end

                inHarvest = false
            end
        end

        -- 2. LOGIQUE DE TRANSFORMATION (Brassage)
        local processingPoints = dynamicProcessingPoints
        if not processingPoints or #processingPoints == 0 then
            processingPoints = {}
            for _, coord in pairs(HenHouseBarConfig.processing) do
                processingPoints[#processingPoints + 1] = { x = coord.x, y = coord.y, z = coord.z }
            end
        end

        for _, pt in ipairs(processingPoints) do
            local coords = vec3(pt.x, pt.y, pt.z)
            local dist = #(pCoords - coords)

            if dist < 2.0 and hasGoodJob and not isInVehicle then
                wait = 0

                if dist < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour brasser la bière")

                    if VFW.Interact.JustReleased(0, 38) then
                        for barley_type, _ in pairs(HenHouseBarConfig.items.process) do
                            local canProcess = TriggerServerCallback("farm:henhouse:canProcess", "process", barley_type)

                            if canProcess then
                                local procAnim = dynamicProcessingAnim or { dict = "amb@medic@standing@kneel@base", name = "base" }
                                local animDict = procAnim.dict
                                local animName = procAnim.name

                                local propCoords = vector3(coords.x, coords.y, coords.z)
                                TaskTurnPedToFaceCoord(ped, propCoords.x, propCoords.y, propCoords.z, 1000)
                                Wait(1000)

                                RequestAnimDict(animDict)
                                local timeout = 0
                                while not HasAnimDictLoaded(animDict) and timeout < 50 do
                                    Wait(50)
                                    timeout = timeout + 1
                                end

                                if HasAnimDictLoaded(animDict) then
                                    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                                end

                                local success = VFW.Nui.ProgressBar("BRASSAGE DE LA BIERE...", 5000)

                                ClearPedTasks(ped)
                                RemoveAnimDict(animDict)

                                if success then
                                    TriggerServerEvent("farm:henhouse:give", "process", barley_type)
                                end
                                break
                            else
                                ShowJobNotification(("Vous devez avoir au moins 3 %s."):format(VFW.Items[barley_type].label or barley_type), false)
                            end
                        end
                    end
                end
            end
        end

        -- 3. LOGIQUE DE VENTE (PNJ)
        if sellingPed and #(GetEntityCoords(sellingPed) - pCoords) < 2.5 and not isInVehicle then
            wait = 0
            if #(GetEntityCoords(sellingPed) - pCoords) < 1.5 then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre votre Bière.")
                if VFW.Interact.JustReleased(0, 38) and not inSelling then
                    local canSell = TriggerServerCallback("farm:henhouse:canProcess", "selling")
                    if canSell then
                        inSelling = true

                        Citizen.CreateThread(function()
                            local sellAnim = dynamicSellingAnim or { dict = "mp_common", name = "givetake1_a" }
                            local animDict = sellAnim.dict
                            local animName = sellAnim.name
                            RequestAnimDict(animDict)
                            while not HasAnimDictLoaded(animDict) do
                                Wait(50)
                            end

                            TaskTurnPedToFaceEntity(ped, sellingPed, 1000)
                            Wait(1000)
                            TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 5000, 0, 0, false, false, false)

                            local success = VFW.Nui.ProgressBar("Vente de bière...", 5000)

                            ClearPedTasks(ped)

                            if success then
                                TriggerServerEvent("farm:henhouse:selling")
                            else
                                ShowJobNotification("Vente annulee.", false)
                            end

                            inSelling = false
                        end)
                    else
                        ShowJobNotification("Vous n'avez plus de bière.", false)
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)
