---@meta _
---@diagnostic disable: duplicate-doc-field

local isInPermis = false
local vehicleSchool = nil
local modelSchool = nil
local errorCount = 0
local checkpointIndex = 1
local checkpointBlip = nil
local points = 0
local engineHealthWarning = false
local pedSchool = nil
local licenseType = "PERMIS DE CONDUIRE"
local currentTime = 0
local timeLeft = 0

--- showText
---@param args table Arguments
local function showText(args)
    args.shadow = args.shadow or true
    args.font = args.font or 6
    args.size = args.size or 0.50
    args.posx = args.posx or 0.5
    args.posy = args.posy or 0.4
    args.msg = args.msg or ""

    SetTextFont(args.font)
    SetTextProportional(0)
    SetTextScale(args.size, args.size)
    if args.shadow == true then
        SetTextDropShadow(0, 0, 0, 0,255)
        SetTextEdge(1, 0, 0, 0, 255)
    end

    SetTextEntry("STRING")
    AddTextComponentString(args.msg)
    DrawText(args.posx, args.posy)
end

--- DrawSpecialText
---@param title any
---@param barPosition vector3|table Position
---@param addLeft any
local function DrawSpecialText(title, barPosition, addLeft)
    if not addLeft then
        addLeft = 0
    end

    RequestStreamedTextureDict("timerbars")
    if not HasStreamedTextureDictLoaded("timerbars") then
        return;
    end

    local x = 1.0 - (1.0 - GetSafeZoneSize()) * 0.5 - 0.180 / 2
    local y = 1.0 - (1.0 - GetSafeZoneSize()) * 0.5 - 0.045 / 2 - (barPosition - 1) * (0.045 + 0)
    DrawSprite("timerbars", "all_black_bg", x, y, 0.180, 0.045, 0.0, 255, 255, 255, 160)
    showText({msg = title, font = 0, size = 0.36, posx = 0.840, posy = y/1.014, shadow = false})
end

--- formatTime
---@param timeMs any
---@return any
local function formatTime(timeMs)
    local totalSeconds = math.floor(timeMs / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

--- EndExam
---@param success any
---@param message string
---@param licenseName string
local function EndExam(success, message, licenseName)
    isInPermis = false

    SetEntityCoords(VFW.PlayerData.ped, 229.02, 365.73, 105.01)
    SetEntityHeading(VFW.PlayerData.ped, 175.21)

    if vehicleSchool then
        VFW.Game.DeleteVehicle(vehicleSchool)
    end

    if checkpointBlip then
        RemoveBlip(checkpointBlip)
    end

    if pedSchool then
        DeleteEntity(pedSchool)
    end

    VFW.ShowNotification({
        type = 'DEFAULT',
        name = "MONITEUR",
        label = licenseType,
        labelColor = success and "#00c92b" or "#ff4141",
        mainColor = success and 'green' or 'rouge',
        logo = VFW.CDN.Get("hud/notifications/4.webp"),
        mainMessage = message,
        duration = 10,
    })

    if success then
        TriggerServerEvent("vfw:license:addLicense", GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)), licenseName)
    end
end

--- StartDrivingSchool
---@param typeDMV number Ped handle
---@return any
local function StartDrivingSchool(typeDMV)
    if isInPermis then
        return
    end

    isInPermis = true
    errorCount = 0
    checkpointIndex = 1
    currentTime = 0
    timeLeft = 0

    local checkpoints = VFW.DMVSchool.positionDMVExamen
    if typeDMV == "plane" then
        checkpoints = VFW.DMVSchool.positionPlaneExamen
    elseif typeDMV == "helicopter" then
        checkpoints = VFW.DMVSchool.positionHeliExamen
    elseif typeDMV == "boat" then
        checkpoints = VFW.DMVSchool.positionBoatExamen
    end

    local startTime = GetGameTimer()
    local maxTime = VFW.DMVSchool.maxTime or 600000
    local checkpointsPassed = 0
    local totalCheckpoints = #checkpoints
    local lastCheckpointTime = startTime
    local checkpointTimes = {}

    if typeDMV == "motorcycle" then
        modelSchool = "bati"
    elseif typeDMV == "truck" then
        modelSchool = "mule3"
    elseif typeDMV == "plane" then
        modelSchool = "velum"
    elseif typeDMV == "helicopter" then
        modelSchool = "frogger"
    elseif typeDMV == "boat" then
        modelSchool = "seashark"
    else
        modelSchool = "blista"
    end

    local spawnPos = VFW.DMVSchool.positionOutVehicle
    if typeDMV == "plane" or typeDMV == "helicopter" then
        spawnPos = VFW.DMVSchool.positionOutPlane
    elseif typeDMV == "boat" then
        spawnPos = VFW.DMVSchool.positionOutBoat
    end

    VFW.Game.SpawnVehicle(modelSchool, spawnPos, spawnPos.heading, function(vehicle)
        TaskWarpPedIntoVehicle(VFW.PlayerData.ped, vehicle, -1)
        vehicleSchool = vehicle

        if typeDMV == "plane" or typeDMV == "helicopter" then
            SetVehicleEngineOn(vehicle, true, true, false)
            SetHeliBladesFullSpeed(vehicle)
        end
    end)

    -- Le véhicule est spawné server-side (lockdown strict) : on attend qu'il existe.
    local vehTimeout = GetGameTimer() + 7000
    while (not vehicleSchool or not DoesEntityExist(vehicleSchool)) and GetGameTimer() < vehTimeout do
        Wait(50)
    end

    local pedStream = "a_m_m_skater_01"
    if typeDMV == "plane" or typeDMV == "helicopter" then
        pedStream = "s_m_m_pilot_01"
    elseif typeDMV == "boat" then
        pedStream = "s_m_y_uscg_01"
    end

    VFW.Streaming.RequestModel(pedStream)
    pedSchool = VFW.OneSync.CreatePedInsideVehicle(pedStream, vehicleSchool, 0, 26)
    Wait(50)
    SetEntityAsMissionEntity(pedSchool, true, true)
    SetBlockingOfNonTemporaryEvents(pedSchool, true)
    FreezeEntityPosition(pedSchool, true)
    SetEntityInvincible(pedSchool, true)

    VFW.ShowNotification({
        type = 'DEFAULT',
        name = "MONITEUR",
        label = licenseType,
        labelColor = "#10A8D1",
        logo = VFW.CDN.Get("hud/notifications/4.webp"),
        mainMessage = "Suis l'itinéraire en respectant les règles de sécurité.",
        duration = 10,
    })

    Wait(250)

    CreateThread(function()
        local firstCheckpointPos = checkpoints[checkpointIndex]
        if firstCheckpointPos then
            checkpointBlip = AddBlipForCoord(firstCheckpointPos.x, firstCheckpointPos.y, firstCheckpointPos.z)
            SetBlipSprite(checkpointBlip, 1)
            SetBlipColour(checkpointBlip, 2)
            SetBlipScale(checkpointBlip, 0.5)
            SetBlipRoute(checkpointBlip, true)
        end

        while isInPermis do
            currentTime = GetGameTimer() - startTime
            timeLeft = maxTime - currentTime

            Wait(1000)

            if not IsPedInVehicle(VFW.PlayerData.ped, vehicleSchool, false) then
                VFW.ShowNotification({
                    type = 'DEFAULT',
                    name = "MONITEUR",
                    label = licenseType,
                    labelColor = "#10A8D1",
                    logo = VFW.CDN.Get("hud/notifications/4.webp"),
                    mainMessage = "Vous avez quitté le véhicule, veuillez le rejoindre vous avez 10 secondes.",
                    duration = 10,
                })

                Wait(10000)

                if not IsPedInVehicle(VFW.PlayerData.ped, vehicleSchool, false) then
                    EndExam(false, "Trop de fautes, vous avez raté votre examen.")
                    break
                end
            end

            local engineHealth = VFW.Math.Round(GetVehicleEngineHealth(vehicleSchool), 1)
            if engineHealth < VFW.DMVSchool.engineHealthLimit and not engineHealthWarning then
                errorCount = errorCount + 3
                engineHealthWarning = true
                VFW.ShowNotification({
                    type = 'DEFAULT',
                    name = "MONITEUR",
                    label = licenseType,
                    labelColor = "#10A8D1",
                    logo = VFW.CDN.Get("hud/notifications/4.webp"),
                    mainMessage = "Attention, votre véhicule est endommagé !",
                    duration = 10,
                })

                if errorCount >= VFW.DMVSchool.maxErrorsCount then
                    EndExam(false, "Trop de fautes, vous avez raté votre examen.")
                    break
                end
            elseif engineHealth >= VFW.DMVSchool.engineHealthLimit then
                engineHealthWarning = false
            end

            local speed = GetEntitySpeed(vehicleSchool) * 3.6
            local speedLimit = VFW.DMVSchool.speedLimit
            if typeDMV == "plane" then
                speedLimit = 500
            elseif typeDMV == "helicopter" then
                speedLimit = 300
            elseif typeDMV == "boat" then
                speedLimit = 200
            end

            if speed > speedLimit then
                errorCount = errorCount + 1
                VFW.ShowNotification({
                    type = 'DEFAULT',
                    name = "MONITEUR",
                    label = licenseType,
                    labelColor = "#10A8D1",
                    logo = VFW.CDN.Get("hud/notifications/4.webp"),
                    mainMessage = "Attention, vous allez trop vite !",
                    duration = 10,
                })

                if errorCount >= VFW.DMVSchool.maxErrorsCount then
                    EndExam(false, "Trop de fautes, vous avez raté votre examen.")
                    break
                end

                Wait(2000)
            end

            if timeLeft <= 0 then
                EndExam(false, "Temps écoulé")
                break
            end

            checkpointsPassed = checkpointIndex - 1

            local playerPos = GetEntityCoords(VFW.PlayerData.ped)
            local nextCheckpointPos = checkpoints[checkpointIndex]
            local checkpointDistance = typeDMV == "plane" or typeDMV == "helicopter" and 100 or 10

            if nextCheckpointPos and #(playerPos - vector3(nextCheckpointPos.x, nextCheckpointPos.y, nextCheckpointPos.z)) < checkpointDistance then
                local checkpointTime = GetGameTimer() - lastCheckpointTime
                table.insert(checkpointTimes, checkpointTime)
                lastCheckpointTime = GetGameTimer()

                if checkpointBlip then
                    RemoveBlip(checkpointBlip)
                end

                checkpointIndex = checkpointIndex + 1

                if checkpointIndex > #checkpoints then
                    local licenseName = ({
                        ["car"] = "driver",
                        ["motorcycle"] = "moto",
                        ["truck"] = "camion",
                        ["plane"] = "avion",
                        ["helicopter"] = "helicoptere",
                        ["boat"] = "bateau"
                    })[typeDMV]

                    EndExam(true, "Félicitations tu as obtenu ton permis !", licenseName)
                    break
                end

                local pos = checkpoints[checkpointIndex]
                checkpointBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
                SetBlipSprite(checkpointBlip, 1)
                SetBlipColour(checkpointBlip, 2)
                SetBlipScale(checkpointBlip, 0.5)
                SetBlipRoute(checkpointBlip, true)
            end

            Wait(1000)
        end
    end)

    CreateThread(function()
        while isInPermis do
            DrawSpecialText("Position: " .. checkpointsPassed .. "/" .. totalCheckpoints, 1)
            DrawSpecialText("Temps: " .. formatTime(timeLeft), 2)
            DrawSpecialText("Erreur: " .. errorCount .. "/" .. VFW.DMVSchool.maxErrorsCount, 3)

            if typeDMV == "plane" or typeDMV == "helicopter" then
                local nextCheckpointPos = checkpoints[checkpointIndex]
                local nextCheckpointTarget = nil

                if checkpoints and #checkpoints > 0 then
                    if checkpointIndex + 1 <= #checkpoints then
                        nextCheckpointTarget = checkpoints[checkpointIndex + 1]
                    end
                end

                if nextCheckpointPos then
                    local checkpointCoords = vector3(nextCheckpointPos.x, nextCheckpointPos.y, nextCheckpointPos.z)
                    local playerPos = GetEntityCoords(VFW.PlayerData.ped)
                    local distance = #(playerPos - checkpointCoords)
                    local direction = (checkpointCoords - playerPos) / distance
                    local markerPos = playerPos + direction * math.min(10, distance/2)
                    markerPos = vector3(markerPos.x, markerPos.y, playerPos.z + 1.0)
                    local rotZ = 0.0
                    if nextCheckpointTarget then
                        local dir = vector2(
                                nextCheckpointTarget.x - nextCheckpointPos.x,
                                nextCheckpointTarget.y - nextCheckpointPos.y
                        )
                        rotZ = math.deg(math.atan2(dir.y, dir.x))
                    end

                    DrawMarker(
                            20, -- Type de marqueur
                            markerPos.x, markerPos.y, markerPos.z,
                            0.0, 0.0, 0.0, -- Direction (inutile ici)
                            -90.0, 0.0, rotZ, -- Rotation uniquement sur Z
                            2.0, 2.0, 2.0, -- Taille
                            0, 43, 255, 150,
                            false, true, 2, false, nil, nil, false
                    )
                end
            end

            Wait(0)
        end
    end)
end

RegisterNUICallback("nui:closeAutoecole", function(data, cb)
    VFW.Nui.DMVSchool(false)
    VFW.Nui.HudVisible(true)
    TriggerScreenblurFadeOut(1000)
    cb({})
end)

RegisterNUICallback("autoecole__callback", function(data, cb)
    if data.action == "sendQuestions" then
        local isCorrect = true

        for answerIndex, answerData in pairs(data.questions.answer) do
            local isSelected = answerData.selected
            local correctAnswerIndex = VFW.DMVSchool.goodAnswer[data.questions.picture]

            if isSelected and answerIndex ~= correctAnswerIndex then
                isCorrect = false
                break
            elseif not isSelected and answerIndex == correctAnswerIndex then
                isCorrect = false
                break
            end
        end

        if isCorrect then
            points = points + 1
        end
    end

    if data.action == "takeNote" then 
        if points >= 7 then
            TriggerServerEvent("vfw:license:addLicense", GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)), "dmvschool")
        end

        cb({
            action = "takeNote",
            note = points
        })
    end
end)

local defaultCategory = "car"
local lastCategory = "car"
local defaultIndex = {
    ["car"] = 0,
    ["motorcycle"] = 1,
    ["truck"] = 2,
    ["plane"] = 3,
    ["helicopter"] = 4,
    ["boat"] = 5,
}
local lastLicense = nil
local infos = {
    ["car"] = {
        primaryTitle = "PERMIS B",
        secondaryTitle = "VEHICULE",
        backgroundImg = "assets/catalogues/autoecole/carte.png",
        missions = {
            { title = "Compléter l'itinéraire dans le temps imparti." },
            { title = "Respecter la vitesse et le code de la route. (3 max)." },
            { title = "Provoquer un accident de la route est élimination." }
        },
        salary = 250,
        duration = 10,
    },

    ["motorcycle"] = {
        primaryTitle = "PERMIS A",
        secondaryTitle = "VEHICULE",
        backgroundImg = "assets/catalogues/autoecole/carte.png",
        missions = {
            { title = "Compléter l'itinéraire dans le temps imparti." },
            { title = "Respecter la vitesse et le code de la route. (3 max)." },
            { title = "Provoquer un accident de la route est élimination." }
        },
        salary = 250,
        duration = 20,
        members = "Code de la route",
    },

    ["truck"] = {
        primaryTitle = "PERMIS C",
        secondaryTitle = "VEHICULE",
        backgroundImg = "assets/catalogues/autoecole/carte.png",
        missions = {
            { title = "Compléter l'itinéraire dans le temps imparti." },
            { title = "Respecter la vitesse et le code de la route. (3 max)." },
            { title = "Provoquer un accident de la route est élimination." }
        },
        salary = 250,
        duration = 20,
        members = "Code de la route",
    },

    ["plane"] = {
        primaryTitle = "PERMIS AVION",
        secondaryTitle = "VEHICULE",
        backgroundImg = "assets/catalogues/autoecole/carte.png",
        missions = {
            { title = "Compléter l'itinéraire dans le temps imparti." },
            { title = "Respecter la vitesse et le code de la route. (3 max)." },
            { title = "Provoquer un accident de la route est élimination." }
        },
        salary = 250,
        duration = 20,
        members = "Code de la route",
    },

    ["helicopter"] = {
        primaryTitle = "PERMIS HELICO",
        secondaryTitle = "VEHICULE",
        backgroundImg = "assets/catalogues/autoecole/carte.png",
        missions = {
            { title = "Compléter l'itinéraire dans le temps imparti." },
            { title = "Respecter la vitesse et le code de la route. (3 max)." },
            { title = "Provoquer un accident de la route est élimination." }
        },
        salary = 250,
        duration = 20,
        members = "Code de la route",
    },

    ["boat"] = {
        primaryTitle = "PERMIS BATEAUX",
        secondaryTitle = "VEHICULE",
        backgroundImg = "assets/catalogues/autoecole/carte.png",
        missions = {
            { title = "Compléter l'itinéraire dans le temps imparti." },
            { title = "Respecter la vitesse et le code de la route. (3 max)." },
            { title = "Provoquer un accident de la route est élimination." }
        },
        salary = 250,
        duration = 20,
        members = "Code de la route",
    },
}
local cams = {
    ["car"] = {
        Fov = 40.1,
        Freeze = false,
        Vehicle = -344943009,
        DofStrength = 0.9,
        Dof = true,
        CamRot = { x = -2.37467098236084, y = -1.3340212490220438e-8, z = -93.3205337524414 },
        COH = { x = 185.54412841796876, y = 385.3547058105469, z = 108.2827377319336, w = 53.90113067626953 },
        CamCoords = { x = 180.85194396972657, y = 386.6180419921875, z = 108.16468048095703 },
        Transition = 0,
    },

    ["motorcycle"] = {
        Fov = 40.1,
        Freeze = false,
        Vehicle = -114291515,
        DofStrength = 0.9,
        Dof = true,
        CamRot = { x = -1.70537936687469, y = -0.0, z = -92.92687225341797 },
        COH = { x = 185.29945373535157, y = 383.9747314453125, z = 107.84832763671875, w = 52.88888931274414 },
        CamCoords = { x = 181.95469665527345, y = 384.5714111328125, z = 108.23438262939453 },
        Transition = 0,
    },

    ["truck"] = {
        Fov = 50.1,
        Freeze = false,
        Vehicle = -2052737935,
        DofStrength = 0.8,
        Dof = true,
        CamRot = { x = -0.59615439176559, y = -0.0, z = -84.26608276367188 },
        COH = { x = 189.33108520507813, y = 384.97210693359377, z = 108.50969696044922, w = 56.51948547363281 },
        CamCoords = { x = 181.86573791503907, y = 386.5255432128906, z = 108.95135498046875 },
        Transition = 0,
    },

    ["plane"] = {
        Fov = 50.1,
        Freeze = false,
        Vehicle = 1341619767,
        DofStrength = 0.8,
        Dof = true,
        CamRot = { x = 0.04450487345457, y = 0.0, z = -72.86406707763672 },
        COH = { x = -1428.9853515625, y = -2733.977783203125, z = 14.12737083435058, w = 75.77436828613281 },
        CamCoords = { x = -1435.7515869140626, y = -2734.798583984375, z = 13.88113498687744 },
        Transition = 0,
    },

    ["helicopter"] = {
        Fov = 50.1,
        Freeze = false,
        Vehicle = 2634305738,
        DofStrength = 0.8,
        Dof = true,
        CamRot = { x = 0.04450487345457, y = 0.0, z = -72.86406707763672 },
        COH = { x = -1428.9853515625, y = -2733.977783203125, z = 14.12737083435058, w = 75.77436828613281 },
        CamCoords = { x = -1435.7515869140626, y = -2734.798583984375, z = 13.88113498687744 },
        Transition = 0,
    },

    ["boat"] = {
        Invisible = true,
        Dof = true,
        DofStrength = 0.8,
        Fov = 40.1,
        CamRot = { x = 1.89224934577941, y = 5.336085706630911e-8, z = 162.79302978515626 },
        CamCoords = { x = -722.0592651367188, y = -1337.876953125, z = 0.8387638926506 },
        Freeze = false,
        Vehicle = -282946103,
        COH = { x = -725.3162841796875, y = -1343.5560302734376, z = 0.4372743666172, w = 313.937744140625 },
        Transition = 0,
    },
}
local vehicle = nil
local pedVehicle = nil

--- DmvSchool
---@param category any
---@return any
local function DmvSchool(category)
     local data = {
         style = {
             menuStyle = "tempjob",
             backgroundType = 1,
             bannerType = 1,
             gridType = 1,
             buyType = 0,
             bannerImg = "assets/catalogues/headers/header_dmv.png",
         },
         eventName = "dmvschool",
         showStats = { show = false },
         category = {
             show = true,
             defaultIndex = defaultIndex[category] or 0,
             items = {
                 --{ id = "car", label = "Permis voiture", image = "assets/catalogues/autoecole/voiture.png" },
                 --{ id = "motorcycle", label = "Permis moto", image = "assets/catalogues/autoecole/moto.png" },
                 --{ id = "truck", label = "Permis camion", image = "assets/catalogues/autoecole/Chasse.png" },
                 --{ id = "plane", label = "Permis avion", image = "assets/catalogues/autoecole/avion.png" },
                 --{ id = "helicopter", label = "Permis hélicoptère", image = "assets/catalogues/autoecole/hélicoptère.png" },
                 --{ id = "boat", label = "Permis bateaux", image = "assets/catalogues/autoecole/bateaux.png" },
             }
         },
         cameras = { show = false },
         nameContainer = { show = false },
         headCategory = {
             show = true,
             items = {{ label = "Permis de conduire", id = nil }}
         },
         color = { show = false },
---@class items
         items = {},
         interim = infos[category],
     }

    return data
end

--- spawnVeh
---@param category any
local function spawnVeh(category)
    if vehicle then
        if DoesEntityExist(vehicle) then
            VFW.Game.DeleteVehicle(vehicle)
        end
    end

    if pedVehicle then
        if DoesEntityExist(pedVehicle) then
            DeleteEntity(pedVehicle)
        end
    end

    if cams[category].Vehicle then
        VFW.Streaming.RequestModel(cams[category].Vehicle)
        vehicle = CreateVehicle(
                cams[category].Vehicle,
                cams[category].COH.x, cams[category].COH.y, cams[category].COH.z - 1.0,
                cams[category].COH.w,
                false, false
        )

        local pedStream = "a_m_m_skater_01"
        if category == "plane" or category == "helicopter" then
            pedStream = "s_m_m_pilot_01"
        elseif category == "boat" then
            pedStream = "s_m_y_uscg_01"
        end

        while not vehicle do Wait(100) end

        VFW.Streaming.RequestModel(pedStream)
        pedVehicle = CreatePedInsideVehicle(vehicle, 26, pedStream, 0, false, true)
        SetVehicleDoorsLocked(vehicle, 2)
        cEntity.Visual.AddEntityToException(vehicle)
    end
end

RegisterNuiCallback("nui:newgrandcatalogue:dmvschool:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    Wait(50)
    VFW.Nui.UpdateBigMenu(DmvSchool(lastCategory))
    ClearFocus()
    spawnVeh(lastCategory)
    SetFocusArea(cams[lastCategory].CamCoords.x, cams[lastCategory].CamCoords.y, cams[lastCategory].CamCoords.z)
    VFW.Cam:Update("dmvschool", cams[lastCategory])
end)

RegisterNuiCallback("nui:newgrandcatalogue:dmvschool:selectBuy", function(data)
    if not data then
        return
    end

    lastCategory = defaultCategory
    VFW.Nui.BigMenu(false)
    if vehicle then
        if DoesEntityExist(vehicle) then
            VFW.Game.DeleteVehicle(vehicle)
        end
    end

    if pedVehicle then
        if DoesEntityExist(pedVehicle) then
            DeleteEntity(pedVehicle)
        end
    end

    VFW.Nui.BigMenu(false)
    VFW.Cam:Destroy("dmvschool")
    ClearFocus()

    if data == "PERMIS B" then
        if not lastLicense.driver then
            StartDrivingSchool("car")
        else
            VFW.ShowNotification({
                type = 'DEFAULT',
                name = "MONITEUR",
                label = "CONDUITE",
                labelColor = "#10A8D1",
                logo = VFW.CDN.Get("hud/notifications/4.webp"),
                mainMessage = "Vous avez déjà le permis de conduire.",
                duration = 10,
            })
        end
    end

    --elseif data == "PERMIS A" then
    --    if not lastLicense.moto then
    --        StartDrivingSchool("motorcycle")
    --    else
    --        VFW.ShowNotification({
    --            type = 'DEFAULT',
    --            name = "MONITEUR",
    --            label = "CONDUITE",
    --            labelColor = "#10A8D1",
    --            logo = VFW.CDN.Get("hud/notifications/4.webp"),
    --            mainMessage = "Vous avez déjà le permis de conduire.",
    --            duration = 10,
    --        })
    --    end
    --elseif data == "PERMIS C" then
    --    if not lastLicense.camion then
    --        StartDrivingSchool("truck")
    --    else
    --        VFW.ShowNotification({
    --            type = 'DEFAULT',
    --            name = "MONITEUR",
    --            label = "CONDUITE",
    --            labelColor = "#10A8D1",
    --            logo = VFW.CDN.Get("hud/notifications/4.webp"),
    --            mainMessage = "Vous avez déjà le permis de conduire.",
    --            duration = 10,
    --        })
    --    end
    --elseif data == "PERMIS AVION" then
    --    if not lastLicense.avion then
    --        local coords = VFW.DMVSchool.positionOutPlane
    --        SetEntityCoords(VFW.PlayerData.ped, coords.x, coords.y, coords.z)
    --        SetEntityHeading(coords.w)
    --        StartDrivingSchool("plane")
    --    else
    --        VFW.ShowNotification({
    --            type = 'DEFAULT',
    --            name = "MONITEUR",
    --            label = "CONDUITE",
    --            labelColor = "#10A8D1",
    --            logo = VFW.CDN.Get("hud/notifications/4.webp"),
    --            mainMessage = "Vous avez déjà le permis de conduire.",
    --            duration = 10,
    --        })
    --    end
    --elseif data == "PERMIS HELICO" then
    --    if not lastLicense.helicoptere then
    --        local coords = VFW.DMVSchool.positionOutPlane
    --        SetEntityCoords(VFW.PlayerData.ped, coords.x, coords.y, coords.z)
    --        SetEntityHeading(coords.w)
    --        StartDrivingSchool("helicopter")
    --    else
    --        VFW.ShowNotification({
    --            type = 'DEFAULT',
    --            name = "MONITEUR",
    --            label = "CONDUITE",
    --            labelColor = "#10A8D1",
    --            logo = VFW.CDN.Get("hud/notifications/4.webp"),
    --            mainMessage = "Vous avez déjà le permis de conduire.",
    --            duration = 10,
    --        })
    --    end
    --elseif data == "PERMIS BATEAUX" then
    --    if not lastLicense.bateau then
    --        local coords = VFW.DMVSchool.positionOutBoat
    --        SetEntityCoords(VFW.PlayerData.ped, coords.x, coords.y, coords.z)
    --        SetEntityHeading(coords.w)
    --        StartDrivingSchool("boat")
    --    else
    --        VFW.ShowNotification({
    --            type = 'DEFAULT',
    --            name = "MONITEUR",
    --            label = "CONDUITE",
    --            labelColor = "#10A8D1",
    --            logo = VFW.CDN.Get("hud/notifications/4.webp"),
    --            mainMessage = "Vous avez déjà le permis de conduire.",
    --            duration = 10,
    --        })
    --    end
    --end

    Wait(250)

end)

RegisterNuiCallback("nui:newgrandcatalogue:dmvschool:close", function()
    lastCategory = defaultCategory
    if vehicle then
        if DoesEntityExist(vehicle) then
            VFW.Game.DeleteVehicle(vehicle)
        end
    end

    if pedVehicle then
        if DoesEntityExist(pedVehicle) then
            DeleteEntity(pedVehicle)
        end
    end

    VFW.Nui.BigMenu(false)
    VFW.Cam:Destroy("dmvschool")
    ClearFocus()

    Wait(250)

end)

--- AutoEcoleMenu
---@param checkAllLicense any
function AutoEcoleMenu(checkAllLicense)

    Wait(250)

    lastLicense = checkAllLicense
    VFW.Nui.BigMenu(true, DmvSchool(defaultCategory))
    spawnVeh(defaultCategory)
    SetFocusArea(cams[defaultCategory].CamCoords.x, cams[defaultCategory].CamCoords.y, cams[defaultCategory].CamCoords.z)
    VFW.Cam:Create("dmvschool", cams[defaultCategory])
end

local lastZone = nil
local lastPed = nil

---Delete Zone
---@return boolean Success status
local function removeZone()
    if lastZone then
        Worlds.Zone.Remove(lastZone)
        Worlds.Blips.Remove(lastZone)
        VFW.RemoveInteraction("dmvschool")
        lastZone = nil
    end

    if lastPed then
        DeleteEntity(lastPed)
        lastPed = nil
    end
end

---Load Zone
---@param checkLicense any
local function loadZone(checkLicense)
    if not checkLicense then
        --lastZone = VFW.CreateBlipAndPoint("dmvschool", vector3(226.34, 370.93, 105.11 + 0.75), "dmvschool", 269, 0, 0.8, "Auto-Ecole", "Auto-Ecole", "E", "Car",{
        --    onPress = function()
        --        TriggerScreenblurFadeIn(1000)
        --        VFW.Nui.HudVisible(false)
        --        VFW.Nui.DMVSchool(true)
        --    end
        --})
    else
        --lastPed = VFW.CreatePed(vector4(229.02, 365.73, 105.01, 175.21), "a_m_m_skater_01")
        --lastZone = VFW.CreateBlipAndPoint("dmvschool2", vector3(229.02, 365.73, 105.01 + 1.5), "dmvschool2", 269, 0, 0.8, "Auto-Ecole", "Auto-Ecole", "E", "Car",{
        --    onPress = function()
        --        local checkAllLicense = TriggerServerCallback("vfw:license:checkAllLicense", GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)))
        --        AutoEcoleMenu(checkAllLicense)
        --    end
        --})
    end
end

RegisterNetEvent("vfw:playerReady", function()
    removeZone()
    local checkLicense = TriggerServerCallback("vfw:license:checkLicense", GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)), "dmvschool")
    loadZone(checkLicense)
end)

RegisterNetEvent("vfw:license:load", function()
    removeZone()
    local checkLicense = TriggerServerCallback("vfw:license:checkLicense", GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)), "dmvschool")
    loadZone(checkLicense)
end)
