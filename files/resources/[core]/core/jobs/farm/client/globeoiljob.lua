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
local barrelData = {}
local MAX_BARRELS = 4
local availablePositions = {}
local usedPositions = {}
local processingProps = {}
local currentPtfx = nil

local function DeleteObjectProperly(object)
    if DoesEntityExist(object) then
        SetEntityAsMissionEntity(object, false, true)
        DeleteObject(object)
        DeleteEntity(object)
    end
end

-- Barrel spawning logic from user...
local function initializePositions()
    availablePositions = {}
    usedPositions = {}
    for k, v in pairs(GlobeOilConfig.harvest) do
        table.insert(availablePositions, { x = v.x, y = v.y, z = v.z, index = k })
    end
end

local function getRandomAvailablePosition()
    if #availablePositions == 0 then
        return nil
    end
    local randomIndex = math.random(1, #availablePositions)
    local position = availablePositions[randomIndex]
    table.remove(availablePositions, randomIndex)
    table.insert(usedPositions, position)
    return position
end

local function returnPositionToAvailable(position)
    for i, pos in ipairs(usedPositions) do
        if pos.index == position.index then
            table.remove(usedPositions, i)
            break
        end
    end
    table.insert(availablePositions, position)
end

local function spawnBarrel(position)
    local obj = GetHashKey(GlobeOilConfig.oilProps)
    RequestModel(obj)
    while not HasModelLoaded(obj) do
        Wait(10)
    end
    local createdObj = CreateObject(obj, position.x, position.y, position.z, false, false, false)
    SetEntityAsMissionEntity(createdObj, true, true)
    FreezeEntityPosition(createdObj, true)
    local blip = AddBlipForEntity(createdObj)
    SetBlipSprite(blip, 478)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(("%s · Ramassage de baril vide"):format(VFW.PlayerData and VFW.PlayerData.job.label or "Globe oil"))
    EndTextCommandSetBlipName(blip)
    table.insert(barrelData, { object = createdObj, blip = blip, position = position })
    SetModelAsNoLongerNeeded(obj)
end

local function spawnBarrils()
    for k, v in pairs(barrelData) do
        if DoesEntityExist(v.object) then
            DeleteObjectProperly(v.object)
        end
        if DoesBlipExist(v.blip) then
            RemoveBlip(v.blip)
        end
    end
    barrelData = {}
    initializePositions()
    for i = 1, math.min(MAX_BARRELS, #GlobeOilConfig.harvest) do
        local position = getRandomAvailablePosition()
        if position then
            spawnBarrel(position)
        end
    end
end

local function respawnBarrel()
    if #barrelData < MAX_BARRELS then
        local position = getRandomAvailablePosition()
        if position then
            spawnBarrel(position)
        end
    end
end

-- Processing Props (Robinets)
local function cleanupProcessingProps()
    for _, prop in pairs(processingProps) do
        if DoesEntityExist(prop) then
            DeleteObjectProperly(prop)
        end
    end
    processingProps = {}
end

local function spawnProcessingProps()
    cleanupProcessingProps()

    if not GlobeOilConfig.processingProps then
        return
    end

    local model = GetHashKey(GlobeOilConfig.processingPropModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    for i, propData in pairs(GlobeOilConfig.processingProps) do
        local prop = CreateObject(model, propData.coords.x, propData.coords.y, propData.coords.z, false, true, false)
        SetEntityRotation(prop, propData.rotation.x, propData.rotation.y, propData.rotation.z, 5, true)
        FreezeEntityPosition(prop, true)
        processingProps[i] = prop
    end

    SetModelAsNoLongerNeeded(model)
end

-- PTFX Functions
-- PTFX Functions avec position corrigée
local function startProcessingPtfx(processingIndex)
    local prop = processingProps[processingIndex]
    if not prop or not DoesEntityExist(prop) then
        return
    end

    Citizen.CreateThread(function()
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Citizen.Wait(10)
        end

        UseParticleFxAssetNextCall("core")

        -- Offsets ajustés pour que l'huile coule du robinet vers le bas
        -- x = légèrement en avant du robinet
        -- y = centré
        -- z = au niveau du bec du robinet (ajuste selon ton modèle)
        -- Rotation: 180° sur X pour faire couler vers le bas
        currentPtfx = StartParticleFxLoopedOnEntity(
                "veh_trailer_petrol_spray",
                prop,
                0.17, -- offset X (avant/arrière)
                0.0, -- offset Y (gauche/droite)
                1.20, -- offset Z (hauteur - négatif pour descendre)
                65.0, -- pitch - rotation X (180 = vers le bas)
                0.90, -- roll - rotation Y
                0.70, -- yaw - rotation Z
                0.3, -- scale (ajuste la taille du jet si besoin)
                false,
                false,
                false
        )
    end)
end

local function stopProcessingPtfx()
    if currentPtfx then
        StopParticleFxLooped(currentPtfx, false)
        currentPtfx = nil
    end
end

-- Proc

local processBlips = {}

-- Main Reset Event
RegisterNetEvent("farm:globeoil:sellingPed", function(pos)
    if sellingPed then
        DeleteObjectProperly(sellingPed)
        sellingPed = nil
    end
    if sellingBlip and DoesBlipExist(sellingBlip) then
        RemoveBlip(sellingBlip)
        sellingBlip = nil
    end

    for i = #processBlips, 1, -1 do
        if DoesBlipExist(processBlips[i]) then
            RemoveBlip(processBlips[i])
            table.remove(processBlips, i)
        end
    end

    for i = #barrelData, 1, -1 do
        if DoesEntityExist(barrelData[i].blip) then
            RemoveBlip(barrelData[i].blip)
        end
        if DoesEntityExist(barrelData[i].object) then
            DeleteObjectProperly(barrelData[i].object)
        end
    end

    cleanupProcessingProps()

    if pos and pos.x ~= 0.0 then
        spawnProcessingProps()
        sellingPed = VFW.CreatePed(vec4(pos.x, pos.y, pos.z, pos.heading), "a_m_y_business_02")

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

        for i = 1, #GlobeOilConfig.processing do
            local procCoords = GlobeOilConfig.processing[i]
            local blip = AddBlipForCoord(procCoords)
            SetBlipSprite(blip, 478)
            SetBlipColour(blip, 3)
            SetBlipScale(blip, 0.5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(("%s · Remplissage du baril"):format(VFW.PlayerData and VFW.PlayerData.job.label or "Globe oil"))
            EndTextCommandSetBlipName(blip)
            table.insert(processBlips, blip)
        end
        spawnBarrils()
    end


end)

local inHarvest = false

-- Main Thread
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local hasOilJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == "globeoil"

        -- Barrel Collection Logic
        if hasOilJob and not inHarvest then
            for i = #barrelData, 1, -1 do
                local barrelInfo = barrelData[i]
                if DoesEntityExist(barrelInfo.object) then
                    local coords = GetEntityCoords(barrelInfo.object)
                    local dist = #(pCoords - coords)
                    if dist < 2.0 then
                        wait = 0
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récupérer le baril vide")
                        if VFW.Interact.JustReleased(0, 38) then
                            if VFW.Interact.JustReleased(0, 38) then
                                inHarvest = true
                                local positionToReturn = barrelInfo.position
                                local barrelObject = barrelInfo.object

                                Citizen.CreateThread(function()
                                    local animDict = "veh@common@motorbike@low@ds"
                                    RequestAnimDict(animDict)
                                    while not HasAnimDictLoaded(animDict) do
                                        Wait(50)
                                    end

                                    TaskTurnPedToFaceEntity(ped, barrelObject, 1000)
                                    Wait(100) -- Small wait to allow turning

                                    TaskPlayAnim(ped, animDict, "pickup", 8.0, -8.0, 1000, 0, 0, false, false, false)

                                    local success = VFW.Nui.ProgressBar("Récupération...", 1000)

                                    ClearPedTasks(ped)

                                    if success then
                                        TriggerServerEvent("farm:globeoil:give", positionToReturn.index, "harvest", coords)
                                        if DoesBlipExist(barrelInfo.blip) then
                                            RemoveBlip(barrelInfo.blip)
                                        end
                                        DeleteObjectProperly(barrelInfo.object)
                                        returnPositionToAvailable(positionToReturn)
                                        table.remove(barrelData, i)
                                        SetTimeout(2000, respawnBarrel)
                                    else
                                        ShowJobNotification("Récupération annulée.", false)
                                    end

                                    inHarvest = false
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end

        -- Processing Logic
        if hasOilJob and not inHarvest then
            for i = 1, #GlobeOilConfig.processing do
                local procCoords = GlobeOilConfig.processing[i]
                local dist = #(vec3(pCoords.x, pCoords.y, pCoords.z) - vec3(procCoords.x , procCoords.y, procCoords.z))

                if dist < 2.5 then
                    wait = 0

                    DrawMarker(3, procCoords.x, procCoords.y, procCoords.z + 1.5, 0, 0, 0, 0, 180.0, 0, 1.0, 1.0, 1.0, 255, 130, 0, 100, false, true, 2, nil, nil, false)

                    if dist < 1.5 then
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour remplir votre baril")
                        if VFW.Interact.JustReleased(0, 38) then
                            local canProcess = TriggerServerCallback("farm:globeoil:canProcess", "processing")
                            if canProcess then
                                inHarvest = true

                                -- Spawn barrel for processing animation
                                local barrelModel = GetHashKey(GlobeOilConfig.oilProps)
                                RequestModel(barrelModel)
                                while not HasModelLoaded(barrelModel) do
                                    Wait(10)
                                end

                                local processingBarrel = CreateObject(barrelModel, procCoords.x, procCoords.y, procCoords.z, false, true, false)
                                SetEntityHeading(processingBarrel, procCoords.w)
                                PlaceObjectOnGroundProperly(processingBarrel)
                                FreezeEntityPosition(processingBarrel, true)


                                -- Start PTFX oil effect from tap
                                startProcessingPtfx(i)

                                local success = VFW.Nui.ProgressBar("Remplissage en cours...", 3000)

                                -- Cleanup
                                stopProcessingPtfx()
                                DeleteObjectProperly(processingBarrel)
                                SetModelAsNoLongerNeeded(barrelModel)

                                if success then
                                    TriggerServerEvent("farm:globeoil:give", i, "process")
                                end
                                SetTimeout(1000, function()
                                    inHarvest = false
                                end)

                            else
                                ShowJobNotification("Vous n'avez pas de barils vide à traiter.", false)
                            end
                        end

                    end
                end
            end
            if sellingPed and #(GetEntityCoords(sellingPed) - pCoords) < 2.5 then
                wait = 0
                if #(GetEntityCoords(sellingPed) - pCoords) < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre votre baril")
                    if VFW.Interact.JustReleased(0, 38) and not inSelling then
                        local canSell = TriggerServerCallback("farm:globeoil:canProcess", "selling")
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
                                    TriggerServerEvent("farm:globeoil:selling")
                                else
                                    ShowJobNotification("Vente annulée.", false)
                                end

                                inSelling = false
                            end)
                        else
                            ShowJobNotification("Vous n'avez rien à vendre.", false)
                        end
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)


-- Initial spawn on script start
