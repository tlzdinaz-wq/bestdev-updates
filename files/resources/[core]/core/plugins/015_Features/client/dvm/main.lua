---@meta _
---@diagnostic disable: duplicate-doc-field

-- DVM System - Client
local currentExam = nil
local examVehicle = nil
local instructorPed = nil
local instructorTablet = nil -- Tablet prop attached to instructor
local instructorVehicle = nil -- For motorcycle exams: instructor's following vehicle
local examBlips = {}
local isInExam = false
local currentCheckpoint = 1
local violations = {}
local totalViolations = 0  -- Cumulative violation count across all checkpoints
local examStartTime = 0

-- Variables for driving system
local speedViolationTimer = 0
local lastSpeed = 0
local indicatorUsed = false
local lastIndicatorTime = 0
local dvmNuiOpen = false
local lastVehicleHealth = nil
local redLightTimer = nil
local damageTimer = nil

-- Variables for return-to-school after exam failure
local isReturningToSchool = false
local schoolReturnBlip = nil
local hasFailedExam = false  -- Flag to prevent race condition between 5-mistake fail and route completion

-- Forward declarations
local showLicenseAchievement

-- French GTA-style comment pools with trashy humor
local InstructorComments = {
    examStart = {
        "Essayez de pas nous tuer tous les deux, d'accord ?",
        "J'aurais dû me déclarer malade aujourd'hui...",
        "Bon, on va voir si vous savez vraiment conduire ou pas.",
        "Je garde mon pied près du frein de secours, au cas où.",
        "Allez, montrez-moi que mes années d'expérience servent à quelque chose."
    },
    speeding = {
        "Eh doucement cowboy ! C'est pas le Dakar ici !",
        "C'est pas Fast & Furious ici, ralentissez !",
        "Vous voulez finir en photo sur un radar ?",
        "Ma mère conduit moins vite que ça, et elle a 85 ans !",
        "On a pas volé de voiture de police, vous êtes au courant ?"
    },
    harshBraking = {
        "Ma grand-mère freine mieux que ça, et elle est morte !",
        "Vous voulez me faire vomir sur le tableau de bord ?",
        "C'est mon cou que vous essayez de casser ?",
        "Le frein c'est pas un interrupteur, appuyez doucement !",
        "J'ai vu des accidents moins violents que votre freinage."
    },
    redLight = {
        "Le rouge c'est pas décoratif, ça veut dire STOP !",
        "Ah oui, le code de la route, ça vous dit quelque chose ?",
        "Vous avez vu le feu rouge ou vous êtes daltonien ?",
        "Bravo, vous venez de rater votre examen.",
        "Les feux c'est pas des suggestions, c'est la loi !"
    },
    goodDriving = {
        "Pas mal... pour un débutant.",
        "On dirait que vous savez conduire finalement.",
        "Continuez comme ça, vous allez peut-être réussir.",
        "Bien ! C'est la première fois que je dis ça aujourd'hui.",
        "Enfin quelqu'un qui sait ce qu'il fait !"
    },
    ambient = {
        "Je déteste ce boulot...",
        "Vivement la pause café...",
        "Pourquoi j'ai pas fait médecin comme ma mère voulait...",
        "J'ai vu des choses dans cette voiture... des choses horribles.",
        "Encore trois examens et je rentre chez moi.",
        "Mon dos me tue... ces sièges sont pourris.",
        "Je devrais demander une augmentation.",
        "La dernière personne a vomi dans cette voiture hier."
    },
    examFailed = {
        "Bon, on va dire que c'était un échauffement...",
        "Vous repasserez une autre fois, hein ?",
        "J'ai vu pire... mais pas souvent.",
        "Peut-être que la marche à pied c'est mieux pour vous ?",
        "On se revoit la semaine prochaine... malheureusement."
    },
    examPassed = {
        "Félicitations ! Maintenant essayez de pas tuer personne sur la route.",
        "Pas mal ! Vous êtes officiellement dangereux sur la route.",
        "Bon, vous avez réussi. Dieu nous protège tous.",
        "Bien joué ! J'ai même pas eu peur... enfin, presque pas.",
        "Vous avez votre permis ! Les routes ne seront plus jamais les mêmes."
    },
    leftVehicle = {
        "Où vous allez comme ça ?! C'est un examen !",
        "Génial, je suis seul maintenant. Merci beaucoup.",
        "Vous croyez que c'est GTA ? Revenez ici !",
        "Parfait, je vais me faire virer à cause de vous."
    },
    damage = {
        "Eh ! C'est pas votre voiture !",
        "Vous allez payer les réparations de votre poche !",
        "Bravo champion, vous venez d'emboutir la voiture d'examen.",
        "On est pas dans un jeu vidéo ici, faites attention !",
        "Sérieusement ? Vous avez pas vu l'obstacle ?"
    },
    tooManyMistakes = {
        "C'est bon, on retourne à l'auto-école. Vous avez fait trop d'erreurs.",
        "Stop ! Trop d'erreurs, l'examen est terminé. Retournons au centre.",
        "Non, non, non... Trop d'erreurs. On arrête tout, direction l'auto-école.",
        "Vous avez épuisé votre quota d'erreurs. Retour à la base.",
        "C'est fini pour aujourd'hui. Trop d'erreurs, on rentre."
    }
}

-- Forward declaration for functions used before they're defined
local instructorSpeak
local cleanupExam

-- Helper function to get random comment from a pool
---@param commentPool table
---@return string
local function getRandomComment(commentPool)
    if not commentPool or #commentPool == 0 then
        return "..."
    end
    return commentPool[math.random(#commentPool)]
end

-- Helper function to add a violation and check for exam failure
---@param violation table
local function addViolation(violation)
    table.insert(violations, violation)
    totalViolations = totalViolations + 1  -- Increment cumulative counter

    -- Send violation to server immediately (server is the authority)
    TriggerServerEvent("dvm:addViolation", violation)

    -- Update mistake counter UI
    SendNUIMessage({
        action = "dvm:mistakeCounter",
        data = {
            visible = true,
            mistakes = totalViolations  -- Use cumulative count instead of #violations
        }
    })

    -- Check if player has reached 5 mistakes (automatic failure)
    if totalViolations >= 5 then
        hasFailedExam = true
        isInExam = false  -- Stop monitoring loop immediately

        -- Play sound
        PlaySoundFrontend(-1, "CHECKPOINT_UNDER_THE_BRIDGE", "HUD_MINI_GAME_SOUNDSET", true)

        -- Show failure achievement
        showLicenseAchievement(currentExam.licenseType, false)

        -- Instructor speaks
        instructorSpeak(getRandomComment(InstructorComments.tooManyMistakes), 4000)

        -- Wait a bit for the message to sink in
        Wait(2000)

        -- Fadeout
        DoScreenFadeOut(1000)
        while not IsScreenFadedOut() do Wait(100) end

        -- Find nearest exam center
        local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
        local nearestCenter = nil
        local nearestDistance = math.huge
        for _, center in ipairs(Config.DVM.ExamCenters) do
            local distance = #(playerCoords - center.coords)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestCenter = center
            end
        end

        -- Teleport player to driving school
        if nearestCenter then
            SetEntityCoords(VFW.PlayerData.ped, nearestCenter.coords.x, nearestCenter.coords.y, nearestCenter.coords.z, false, false, false, true)
        end

        -- Cleanup exam (delete vehicle, instructor, etc.)
        cleanupExam()

        -- Notify server of failure (server already has all violations)
        TriggerServerCallback("dvm:finishDrivingExam")

        -- Fade in
        Wait(500)
        DoScreenFadeIn(1000)

        -- Show failure notification
        VFW.ShowNotification({
            type = 'error',
            content = "Vous avez échoué à l'examen de conduite",
            duration = 5
        })
    end
end

-- Functions to manage DVM NUI (Tablet Interface)
function VFW.OpenDVMNui()
    if dvmNuiOpen then return end

    dvmNuiOpen = true

    -- Hide HUD and activate NUI focus
    VFW.Nui.HudVisible(false, true)
    VFW.Nui.Focus(true, true)
    SetCursorLocation(0.5, 0.5)

    -- Send message to open tablet with visibility
    SendNUIMessage({
        action = "nui:dvm-tablet:visible",
        data = true
    })

    -- Send data separately
    SendNUIMessage({
        action = "nui:dvm-tablet:data",
        data = {
            licenseTypes = Config.DVM.LicenseTypes,
            examCenters = Config.DVM.ExamCenters,
            examCosts = Config.DVM.General.ExamCost,
            bribeConfig = Config.DVM.General.BribeSystem
        }
    })

    -- Thread to disable controls
    CreateThread(function()
        while dvmNuiOpen do
            -- Disable movement controls
            DisableControlAction(0, 1, true)  -- LookLeftRight
            DisableControlAction(0, 2, true)  -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 36, true) -- INPUT_DUCK
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 38, true) -- E (Context)
            DisableControlAction(0, 47, true) -- G (Detonate)
            DisableControlAction(0, 74, true) -- H (Headlight)

            -- Disable movement controls
            DisableControlAction(0, 30, true) -- A/D
            DisableControlAction(0, 31, true) -- S/W
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D

            -- Disable firing
            DisablePlayerFiring(PlayerId(), true)

            Wait(0)
        end
    end)
end

function VFW.CloseDVMNui()
    if not dvmNuiOpen then return end

    dvmNuiOpen = false

    -- Restore HUD and disable NUI focus
    VFW.Nui.HudVisible(true, true)
    VFW.Nui.Focus(false)

    -- Send message to close tablet
    SendNUIMessage({
        action = "nui:dvm-tablet:visible",
        data = false
    })
end

-- NUI Callbacks
RegisterNUICallback("dvm:close", function(data, cb)
    VFW.CloseDVMNui()
    cb({ success = true })
end)

RegisterNUICallback("dvm:finishCodeExam", function(data, cb)
    local result = TriggerServerCallback("dvm:finishCodeExam", data.answers)
    cb(result)
end)


RegisterNUICallback("dvm:showNotification", function(data, cb)
    -- Send notification back to NUI with high z-index display
    SendNUIMessage({
        action = "dvm:notification",
        data = {
            type = data.type, -- success, error, warning, info
            message = data.message
        }
    })

    cb({ success = true })
end)

RegisterNUICallback("dvm:attemptBribe", function(data, cb)
    local result = TriggerServerCallback("dvm:attemptBribe", data.examType, data.licenseType, data.score, data.paymentMethod)
    cb(result)
end)

-- Callback to play achievement sound
RegisterNUICallback("dvm:playAchievementSound", function(data, cb)
    local soundType = data.type or "success"

    if soundType == "success" then
        -- Play success sound (boss announcement sound)
        PlaySoundFrontend(-1, "Boss_Blipped", "GTAO_Magnate_Hunt_Boss_SoundSet", true)
    else
        -- Play failure sound (wasted-style sound)
        PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
    end

    cb("ok")
end)

-- Callback to manage typing state
RegisterNUICallback("dvm:setTyping", function(data, cb)
    local isTyping = data.value or false

    if isTyping then
        -- Disable even more controls when typing
        CreateThread(function()
            while dvmNuiOpen and isTyping do
                -- Disable all movement controls
                DisableControlAction(0, 30, true) -- A/D
                DisableControlAction(0, 31, true) -- S/W
                DisableControlAction(0, 32, true) -- W
                DisableControlAction(0, 33, true) -- S
                DisableControlAction(0, 34, true) -- A
                DisableControlAction(0, 35, true) -- D
                DisableControlAction(0, 36, true) -- LEFT CTRL

                -- Disable other controls
                DisableControlAction(0, 21, true) -- SHIFT (sprint)
                DisableControlAction(0, 22, true) -- SPACE (jump)
                DisableControlAction(0, 44, true) -- Q (cover)
                DisableControlAction(0, 38, true) -- E (context)

                Wait(0)
            end
        end)
    end

    cb({ success = true })
end)

---@description Cleanup the exam
---@return any
cleanupExam = function()
    if examVehicle and DoesEntityExist(examVehicle) then
        DeleteEntity(examVehicle)
        examVehicle = nil
    end

    if instructorVehicle and DoesEntityExist(instructorVehicle) then
        DeleteEntity(instructorVehicle)
        instructorVehicle = nil
    end

    if instructorTablet and DoesEntityExist(instructorTablet) then
        DeleteEntity(instructorTablet)
        instructorTablet = nil
    end

    if instructorPed and DoesEntityExist(instructorPed) then
        ClearPedTasksImmediately(instructorPed)
        DeleteEntity(instructorPed)
        instructorPed = nil
    end

    for _, blip in pairs(examBlips) do
        if DoesBlipExist(blip) then
            SetBlipRoute(blip, false)
            RemoveBlip(blip)
        end
    end
    examBlips = {}

    -- Clean up return-to-school waypoint if it exists
    if schoolReturnBlip and DoesBlipExist(schoolReturnBlip) then
        SetBlipRoute(schoolReturnBlip, false)
        RemoveBlip(schoolReturnBlip)
        schoolReturnBlip = nil
    end
    isReturningToSchool = false

    currentExam = nil
    isInExam = false
    currentCheckpoint = 1
    violations = {}
    totalViolations = 0  -- Reset cumulative counter
    hasFailedExam = false  -- Reset failure flag
    examStartTime = 0
    speedViolationTimer = 0
    lastSpeed = 0
    indicatorUsed = false
    lastIndicatorTime = 0
    lastVehicleHealth = nil
    redLightTimer = nil
    damageTimer = nil

    -- Hide mistake counter UI
    SendNUIMessage({
        action = "dvm:mistakeCounter",
        data = {
            visible = false
        }
    })

    -- Restore normal controls
    VFW.Nui.HudVisible(true, true)
end

---@description Create a checkpoint blip
---@param coords vector3
---@param isNext boolean
---@return number
local function createCheckpointBlip(coords, isNext)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, isNext and 1 or 4)
    SetBlipColour(blip, isNext and 5 or 2)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)

    -- Enable GPS route for next checkpoint
    if isNext then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5) -- Yellow route line
    end

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(isNext and "Prochain checkpoint" or "Checkpoint")
    EndTextCommandSetBlipName(blip)
    return blip
end

---@description Create a GPS waypoint to the driving school
---@return number
local function createDrivingSchoolWaypoint()
    -- Get the nearest exam center coordinates
    local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
    local nearestCenter = nil
    local nearestDistance = math.huge

    for _, center in ipairs(Config.DVM.ExamCenters) do
        local distance = #(playerCoords - center.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestCenter = center
        end
    end

    if nearestCenter then
        local coords = nearestCenter.coords
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 1) -- Default waypoint sprite
        SetBlipColour(blip, 5) -- Yellow color
        SetBlipScale(blip, 0.5)
        SetBlipAsShortRange(blip, false)
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5) -- Yellow route line

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Auto-école")
        EndTextCommandSetBlipName(blip)

        return blip
    end

    return nil
end

---@description Monitor player's return to driving school after failure
---@param examResult table The exam result data
---@return any
local function monitorReturnToSchool(examResult)
    CreateThread(function()
        -- Get the nearest exam center
        local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
        local nearestCenter = nil
        local nearestDistance = math.huge

        for _, center in ipairs(Config.DVM.ExamCenters) do
            local distance = #(playerCoords - center.coords)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestCenter = center
            end
        end

        if not nearestCenter then
            return
        end

        local schoolCoords = nearestCenter.coords

        while isReturningToSchool do
            local currentPlayerCoords = GetEntityCoords(VFW.PlayerData.ped)
            local distance = #(currentPlayerCoords - schoolCoords)

            -- Check if player is within 5 meters of the driving school
            if distance < 5.0 then
                -- Player reached the school
                isReturningToSchool = false

                -- Remove waypoint
                if schoolReturnBlip and DoesBlipExist(schoolReturnBlip) then
                    SetBlipRoute(schoolReturnBlip, false)
                    RemoveBlip(schoolReturnBlip)
                    schoolReturnBlip = nil
                end

                -- Clean up exam vehicle and instructor
                cleanupExam()

                -- Reopen DVM NUI with exam results
                Wait(500)
                VFW.OpenDVMNui()
                Wait(100)
                SendNUIMessage({
                    action = "dvm:drivingExamResult",
                    data = examResult
                })

                break
            end

            -- Check if player left the vehicle
            if examVehicle and DoesEntityExist(examVehicle) then
                local playerPed = VFW.PlayerData.ped
                local vehicle = GetVehiclePedIsIn(playerPed, false)

                if vehicle ~= examVehicle then
                    -- Player abandoned the vehicle
                    isReturningToSchool = false

                    -- Remove waypoint
                    if schoolReturnBlip and DoesBlipExist(schoolReturnBlip) then
                        SetBlipRoute(schoolReturnBlip, false)
                        RemoveBlip(schoolReturnBlip)
                        schoolReturnBlip = nil
                    end

                    -- Clean up exam vehicle and instructor without showing UI
                    cleanupExam()

                    break
                end
            end

            Wait(500) -- Check every 500ms
        end
    end)
end

---@description Spawn the exam vehicle
---@param model string
---@param coords vector3
---@param heading number
---@return number
local function spawnExamVehicle(model, coords, heading)
    local modelHash = joaat(model)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    -- Request collision BEFORE creating vehicle to ensure ground exists
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local collisionTimeout = GetGameTimer() + 3000 -- 3 second timeout
    while not HasCollisionLoadedAroundEntity(VFW.PlayerData.ped) and GetGameTimer() < collisionTimeout do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(100)
    end

    -- Now create the vehicle after collision is loaded
    local vehicle = VFW.OneSync.CreateVehicleRaw(modelHash, coords, heading)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleDoorsLocked(vehicle, 0)

    -- Configuration of the exam vehicle
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, 2, false) -- Moteur
    SetVehicleMod(vehicle, 12, 2, false) -- Freins
    SetVehicleMod(vehicle, 13, 2, false) -- Transmission
    SetVehicleWindowTint(vehicle, 1)

    -- Wait for collision around the newly spawned vehicle and place it on ground properly
    local vehicleTimeout = GetGameTimer() + 2000 -- 2 second timeout
    while not HasCollisionLoadedAroundEntity(vehicle) and GetGameTimer() < vehicleTimeout do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(100)
    end

    -- Now that collision is loaded, place vehicle on ground with multiple attempts
    SetVehicleOnGroundProperly(vehicle)
    Wait(50)
    SetVehicleOnGroundProperly(vehicle)

    SetModelAsNoLongerNeeded(modelHash)
    return vehicle
end

---@description Spawn the instructor
---@param model string
---@param coords vector3
---@param heading number
---@return number
local function spawnInstructor(model, coords, heading)
    local modelHash = joaat(model)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    local ped = VFW.OneSync.CreatePed(4, modelHash, coords, heading)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedCombatAttributes(ped, 17, 1)
    SetPedRandomComponentVariation(ped, true)

    -- Make the instructor enter the vehicle FIRST (before attaching tablet)
    if examVehicle and DoesEntityExist(examVehicle) then
        TaskWarpPedIntoVehicle(ped, examVehicle, 0) -- Siège passager
        Wait(100) -- Attendre que le ped soit bien dans le véhicule
    end

    -- Load clipboard animation (same as exam center monitor)
    local animDict = "amb@world_human_clipboard@male@idle_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    TaskPlayAnim(ped, animDict, "idle_a", 8.0, -8.0, -1, 49, 0, false, false, false) -- Flag 49 = upper body only + loop

    -- Attach tablet prop (same positioning as exam center monitor)
    local tabletProp = joaat("prop_cs_tablet")
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do
        Wait(100)
    end

    instructorTablet = CreateObject(tabletProp, 0.0, 0.0, 0.0, false, true, false)
    SetEntityAsMissionEntity(instructorTablet, true, true)
    -- Use same bone and offsets as exam center monitor (npcs.lua)
    AttachEntityToEntity(instructorTablet, ped, GetPedBoneIndex(ped, 0x8CBD),
        0.123, 0.074, 0.106,          -- offset X, Y, Z (same as monitor)
        -10.854, -46.517, -139.788,   -- rotation X, Y, Z (same as monitor)
        false, false, false, false, 0, true)
    SetModelAsNoLongerNeeded(tabletProp)

    SetModelAsNoLongerNeeded(modelHash)
    return ped
end

-- Function to make the instructor speak
---@description Make the instructor speak
---@param message string
---@param duration number
---@return any
instructorSpeak = function(message, duration)
    if not instructorPed or not DoesEntityExist(instructorPed) then return end

    duration = duration or 3000

    -- Animation of speaking
    TaskPlayAnim(instructorPed, "mp_facial", "mic_chatter", 8.0, -8.0, duration, 17, 0, false, false, false)

    -- Display the message using VFW notification system with instructor preset
    VFW.ShowNotification({
        type = 'DVM_INSTRUCTOR',
        content = message,
        duration = duration / 1000  -- Convert milliseconds to seconds
    })
end

---@description Check driving violations
---@return any
local function checkDrivingViolations()
    if not isInExam or not examVehicle or not DoesEntityExist(examVehicle) then
        return
    end

    local playerPed = VFW.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= examVehicle then
        return
    end

    local speed = GetEntitySpeed(vehicle) * 3.6 -- Conversion to km/h
    local checkpoint = currentExam.route.checkpoints[currentCheckpoint]

    if checkpoint then
        local speedLimit = checkpoint.speed or 50

        -- Check speed
        if speed > speedLimit + 10 then       -- Tolerance of 10 km/h
            speedViolationTimer = speedViolationTimer + 1
            if speedViolationTimer > 55 then -- ~1.8 seconds at 30 FPS
                addViolation({
                    type = "speed",
                    description = string.format("Excès de vitesse: %d km/h dans une zone limitée à %d km/h",
                        math.floor(speed), speedLimit),
                    penalty = 1,  -- 1 mistake
                    timestamp = GetGameTimer()
                })
                speedViolationTimer = 0
                -- Play violation warning sound
                PlaySoundFrontend(-1, "CHECKPOINT_UNDER_THE_BRIDGE", "HUD_MINI_GAME_SOUNDSET", true)
                instructorSpeak(getRandomComment(InstructorComments.speeding), 2000)
            end
        else
            speedViolationTimer = 0
        end

        -- Check indicators
        local isIndicatorLeft = GetVehicleIndicatorLights(vehicle) == 1 or GetVehicleIndicatorLights(vehicle) == 3
        local isIndicatorRight = GetVehicleIndicatorLights(vehicle) == 2 or GetVehicleIndicatorLights(vehicle) == 3

        if isIndicatorLeft or isIndicatorRight then
            indicatorUsed = true
            lastIndicatorTime = GetGameTimer()
        end

        -- Check harsh braking
        if lastSpeed > 0 and speed < lastSpeed - 20 and speed > 10 then
            addViolation({
                type = "harsh_braking",
                description = "Freinage trop brusque",
                penalty = 1,  -- 1 mistake
                timestamp = GetGameTimer()
            })
            -- Play violation warning sound
            PlaySoundFrontend(-1, "CHECKPOINT_UNDER_THE_BRIDGE", "HUD_MINI_GAME_SOUNDSET", true)
            instructorSpeak(getRandomComment(InstructorComments.harshBraking), 2000)
        end

        -- Check red light violations
        -- TODO: Red light detection disabled - GetTrafficLightState() does not exist as a FiveM native
        -- FiveM only provides IsVehicleStoppedAtTrafficLights() which is insufficient for detection
        -- Future implementation would require raycasting or traffic light prop detection
        --[[
        if speed > 5 then -- Only check if vehicle is moving
            local vehiclePos = GetEntityCoords(vehicle)
            local lightState = GetVehicleLightsState(vehicle)

            -- Check if vehicle is near traffic lights and if they're red
            -- Native returns: 0 = green/no light, 1 = yellow, 2 = red
            if IsVehicleStoppedAtTrafficLights(vehicle) == false then
                -- Get nearby traffic lights
                local trafficLight = GetClosestVehicleNodeWithHeading(vehiclePos.x, vehiclePos.y, vehiclePos.z, 1, 3.0, 0)
                if trafficLight then
                    local lightState = GetTrafficLightState()
                    if lightState == 1 or lightState == 2 then -- Yellow or Red
                        -- Check if we just passed through (timer to prevent spam)
                        if not redLightTimer or (GetGameTimer() - redLightTimer) > 5000 then
                            addViolation({
                                type = "red_light",
                                description = "Feu rouge ou orange grillé",
                                penalty = 1,  -- 1 mistake
                                timestamp = GetGameTimer()
                            })
                            redLightTimer = GetGameTimer()
                            PlaySoundFrontend(-1, "CHECKPOINT_UNDER_THE_BRIDGE", "HUD_MINI_GAME_SOUNDSET", true)
                            instructorSpeak(getRandomComment(InstructorComments.redLight), 3000)
                        end
                    end
                end
            end
        end
        ]]

        -- Check vehicle damage
        local currentHealth = GetVehicleBodyHealth(vehicle)
        if not lastVehicleHealth then
            lastVehicleHealth = currentHealth
        end

        if lastVehicleHealth - currentHealth > 5 then -- Damage threshold (lowered for better detection)
            -- Check if enough time passed since last damage violation (prevent spam)
            if not damageTimer or (GetGameTimer() - damageTimer) > 3000 then
                addViolation({
                    type = "damage",
                    description = string.format("Dégâts sur le véhicule (%.0f points de dégâts)", lastVehicleHealth - currentHealth),
                    penalty = 1,  -- 1 mistake
                    timestamp = GetGameTimer()
                })
                damageTimer = GetGameTimer()
                PlaySoundFrontend(-1, "CHECKPOINT_UNDER_THE_BRIDGE", "HUD_MINI_GAME_SOUNDSET", true)
                instructorSpeak(getRandomComment(InstructorComments.damage), 3000)
            end
            lastVehicleHealth = currentHealth
        end

        lastSpeed = speed
    end
end

---@description Check checkpoint progress
---@return any
local function checkCheckpointProgress()
    if not isInExam or not currentExam or not examVehicle then
        return
    end

    local playerPed = VFW.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= examVehicle then
        return
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    local checkpoint = currentExam.route.checkpoints[currentCheckpoint]

    if checkpoint then
        local distance = #(vehicleCoords - checkpoint.coords)

        if distance < 15.0 then
            -- Checkpoint reached
            currentCheckpoint = currentCheckpoint + 1

            -- Play checkpoint sound
            PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)

            -- Remove old blip and disable GPS route
            if examBlips[currentCheckpoint - 1] then
                SetBlipRoute(examBlips[currentCheckpoint - 1], false)
                RemoveBlip(examBlips[currentCheckpoint - 1])
                examBlips[currentCheckpoint - 1] = nil
            end

            -- Check if it's the last checkpoint
            if currentCheckpoint > #currentExam.route.checkpoints then
                -- Only finish normally if exam hasn't already failed due to 5 mistakes
                if not hasFailedExam then
                    -- IMMEDIATELY stop monitoring to prevent more violations
                    isInExam = false

                    -- FIRST validate with server BEFORE showing any animation
                    local result = TriggerServerCallback("dvm:finishDrivingExam")

                    if result and result.success then
                        if result.passed then
                            -- Server confirmed SUCCESS
                            showLicenseAchievement(currentExam.licenseType, true)
                            Wait(6000)
                            PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                            instructorSpeak(getRandomComment(InstructorComments.examPassed), 4000)
                            SendNUIMessage({
                                action = "dvm:drivingExamResult",
                                data = result
                            })
                            Wait(5000)
                            cleanupExam()
                        else
                            -- Server confirmed FAILURE (trop d'erreurs)
                            showLicenseAchievement(currentExam.licenseType, false)
                            Wait(6000)
                            PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
                            instructorSpeak(getRandomComment(InstructorComments.examFailed), 4000)
                            Wait(5000)
                            isReturningToSchool = true
                            schoolReturnBlip = createDrivingSchoolWaypoint()
                            VFW.ShowNotification({
                                type = 'warning',
                                content = "Retournez à l'auto-école pour voir vos résultats",
                                duration = 5
                            })
                            monitorReturnToSchool(result)
                        end
                    else
                        -- Server refused (exam not found after restart OR error)
                        VFW.ShowNotification({
                            type = 'error',
                            content = "Cet examen n'est pas valide. Veuillez recommencer.",
                            duration = 10
                        })
                        cleanupExam()
                    end
                end
                return
            end

            -- Create blip for next checkpoint
            local nextCheckpoint = currentExam.route.checkpoints[currentCheckpoint]
            if nextCheckpoint then
                examBlips[currentCheckpoint] = createCheckpointBlip(nextCheckpoint.coords, true)
            end

            -- Notify server of checkpoint progress (violations sent separately via dvm:addViolation)
            TriggerServerEvent("dvm:updateDrivingCheckpoint", currentCheckpoint)
            violations = {} -- Reset local violations for this segment
        end
    end
end

---@description Show achievement notification for exam result
---@param licenseType string
---@param passed boolean
---@return any
showLicenseAchievement = function(licenseType, passed)
    local achievementType = passed and "success" or "failure"

    -- Fetch player identity data for the card
    local identityData = TriggerServerCallback("identity:getData", GetPlayerServerId(PlayerId()))

    local firstname = identityData and identityData.firstName or "John"
    local lastname = identityData and identityData.lastName or "Doe"
    local birthdate = identityData and identityData.date_of_birth or "01/01/1990"
    local photo = identityData and identityData.photo or nil

    -- Fetch existing licenses to show which categories the player has
    local existingLicenses = TriggerServerCallback("dvm:getPlayerLicenses")

    -- Build the map of owned license categories
    local ownedCategories = {}
    if existingLicenses and existingLicenses.licenses then
        for _, license in ipairs(existingLicenses.licenses) do
            ownedCategories[license.license_type] = true
        end
    end

    -- If exam passed, add the new license type
    if passed then
        ownedCategories[licenseType] = true
    end

    -- Get real date from server (FiveM doesn't have os.date on client)
    local currentDate = TriggerServerCallback("dvm:getCurrentDate") or "Non disponible"

    -- Build card document data (without Score and Catégorie - using checkboxes instead)
    local documentData = {
        ["Nom"] = lastname,
        ["Prénom"] = firstname,
        ["Date de naissance"] = birthdate,
        ["Délivré le"] = currentDate
    }

    -- Show achievement UI with card data and license categories
    SendNUIMessage({
        action = "dvm:showAchievement",
        data = {
            licenseType = licenseType,
            type = achievementType,
            cardData = {
                cardType = "driver_license",
                cardLabel = "Permis de conduire",
                theme = "light",
                data = documentData,
                photoUrl = photo,
                licenseCategories = {
                    A = ownedCategories["motorcycle"] or false,
                    B = ownedCategories["car"] or false,
                    C = ownedCategories["truck"] or false
                }
            }
        }
    })
end

-- Test command for achievement display
--RegisterCommand("testdvmachievement", function(source, args)
--    local licenseType = args[1] or "car" -- car, motorcycle, truck
--    local passed = args[2] ~= "fail" -- default success, use "fail" for failure
--    showLicenseAchievement(licenseType, passed)
--end, false)

---@description Finish the driving exam
---@return any
function finishDrivingExam()
    if not isInExam then return end

    -- IMMEDIATELY stop the monitoring loop to prevent more violations
    isInExam = false

    -- Wait for the player to stop
    CreateThread(function()
        local waitTime = 0
        while waitTime < 10000 do -- 10 seconds max
            if examVehicle and DoesEntityExist(examVehicle) then
                local speed = GetEntitySpeed(examVehicle) * 3.6
                if speed < 1.0 then
                    break
                end
            end
            Wait(100)
            waitTime = waitTime + 100
        end

        -- Send results to server
        local result = TriggerServerCallback("dvm:finishDrivingExam", violations)

        if result and result.success then

            -- Play sound based on result
            if result.passed then
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                instructorSpeak(getRandomComment(InstructorComments.examPassed), 4000)

                -- Send result to NUI to display Results screen
                SendNUIMessage({
                    action = "dvm:drivingExamResult",
                    data = result
                })

                -- Clean up after 5 seconds for passed exams
                Wait(5000)
                cleanupExam()
            else
                -- Exam failed - set up return to driving school
                PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
                instructorSpeak(getRandomComment(InstructorComments.examFailed), 4000)

                -- Wait for instructor comment to finish
                Wait(5000)

                -- Set return to school flag
                isReturningToSchool = true

                -- Create GPS waypoint to driving school
                schoolReturnBlip = createDrivingSchoolWaypoint()

                -- Show notification to player
                VFW.ShowNotification({
                    type = 'warning',
                    content = "Retournez à l'auto-école pour voir vos résultats",
                    duration = 5
                })

                -- Start monitoring thread
                monitorReturnToSchool(result)
            end
        else
        end
    end)
end

-- Event to open the DVM menu
RegisterNetEvent("dvm:openMenu", function()
    -- Use the tablet opening function
    VFW.OpenDVMNui()
end)

-- Event to start the code exam
RegisterNUICallback("dvm:startCodeExam", function(data, cb)
    local result = TriggerServerCallback("dvm:startCodeExama", data.licenseType, data.paymentMethod)

    if result then
    else
    end
    cb(result)
    if result and result.success then
        -- NUI interface handles the code exam
        currentExam = {
            type = "code",
            licenseType = data.licenseType,
            questions = result.questions,
            timeLimit = result.timeLimit
        }
    end
end)

-- Variable to avoid double calls
local drivingExamInProgress = false

-- Event to start the driving exam
RegisterNUICallback("dvm:startDrivingExam", function(data, cb)

    if drivingExamInProgress then
        cb({ success = false, message = "Examen déjà en cours" })
        return
    end

    drivingExamInProgress = true

    -- Find the nearest exam center to pass its index to server
    local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
    local nearestCenterIndex = 1
    local nearestDistance = math.huge

    for index, center in ipairs(Config.DVM.ExamCenters) do
        local distance = #(playerCoords - center.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestCenterIndex = index
        end
    end


    local result = TriggerServerCallback("dvm:startDrivingExam", data.licenseType, nearestCenterIndex, data.paymentMethod)
    if result then
    else
    end
    cb(result)
    if result and result.success then
        -- Prepare the driving exam data (but don't spawn or start yet)
        currentExam = {
            type = "driving",
            licenseType = data.licenseType,
            route = result.route,
            vehicleModel = result.vehicleModel,
            instructorModel = result.instructorModel,
            timeLimit = result.timeLimit
        }
    end

    -- Reset the flag
    drivingExamInProgress = false
end)

-- New callback: Actually begin the driving exam (spawn vehicle, instructor, start exam)
RegisterNUICallback("dvm:beginDrivingExam", function(data, cb)

    if not currentExam or currentExam.type ~= "driving" then
        cb({ success = false, message = "Aucun examen préparé" })
        return
    end

    -- Close interface completely
    VFW.CloseDVMNui()

    -- Wait a bit for interface to close
    Wait(100)

    -- Find the nearest exam center
    local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
    local nearestCenter = nil
    local nearestDistance = math.huge

    for _, center in ipairs(Config.DVM.ExamCenters) do
        local distance = #(playerCoords - center.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestCenter = center
        end
    end

    if nearestCenter then
        local examArea = nearestCenter.examAreas[currentExam.licenseType]
        if examArea then
            -- Spawn the vehicle and instructor
            examVehicle = spawnExamVehicle(currentExam.vehicleModel, examArea.spawn, examArea.spawn.w)

            -- Wait for vehicle to be properly placed on ground
            Wait(300)
            SetVehicleOnGroundProperly(examVehicle)
            Wait(100)
            SetVehicleOnGroundProperly(examVehicle)
            Wait(100)

            -- Handle instructor spawning based on license type
            if currentExam.licenseType == "motorcycle" then
                -- For motorcycles: spawn instructor on a separate bike
                local licenseConfig = Config.DVM.LicenseTypes[currentExam.licenseType]
                local instructorVehicleModel = licenseConfig.instructorVehicle or "policeb"

                -- Spawn instructor motorcycle behind player motorcycle
                local spawnCoords = examArea.spawn
                local behindOffset = vector3(
                    spawnCoords.x - math.sin(math.rad(spawnCoords.w)) * 5.0,
                    spawnCoords.y - math.cos(math.rad(spawnCoords.w)) * 5.0,
                    spawnCoords.z
                )

                instructorVehicle = spawnExamVehicle(instructorVehicleModel, behindOffset, spawnCoords.w)
                Wait(200)

                -- Spawn instructor and put them on the instructor motorcycle
                local modelHash = joaat(currentExam.instructorModel)
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Wait(100)
                end

                instructorPed = VFW.OneSync.CreatePed(4, modelHash, behindOffset, spawnCoords.w)
                SetEntityAsMissionEntity(instructorPed, true, true)
                SetBlockingOfNonTemporaryEvents(instructorPed, true)
                SetPedFleeAttributes(instructorPed, 0, 0)
                SetPedCombatAttributes(instructorPed, 17, 1)

                Wait(100)
                TaskWarpPedIntoVehicle(instructorPed, instructorVehicle, -1) -- Driver seat
                Wait(100)

                -- Make instructor invincible (can't die, can't ragdoll, can't fall off)
                SetEntityInvincible(instructorPed, true)
                SetPedCanRagdoll(instructorPed, false)
                SetPedCanBeKnockedOffVehicle(instructorPed, 1) -- 1 = never knocked off
                SetPedConfigFlag(instructorPed, 32, false) -- Can't be pulled out of vehicle

                -- Make instructor vehicle indestructible
                SetEntityInvincible(instructorVehicle, true)
                SetVehicleCanBeVisiblyDamaged(instructorVehicle, false)
                SetEntityProofs(instructorVehicle, true, true, true, true, true, true, true, true)

                SetModelAsNoLongerNeeded(modelHash)
            else
                -- For cars and trucks: spawn instructor in passenger seat
                instructorPed = spawnInstructor(currentExam.instructorModel, examArea.instructor, examArea.instructor.w)
            end

            -- Make the player enter the vehicle
            TaskWarpPedIntoVehicle(VFW.PlayerData.ped, examVehicle, -1) -- Siège conducteur

            -- Start the exam state early so follow thread can begin
            isInExam = true

            -- If motorcycle with instructor vehicle, make instructor follow player
            if currentExam.licenseType == "motorcycle" and instructorVehicle and DoesEntityExist(instructorVehicle) then
                CreateThread(function()
                    Wait(1000) -- Give player time to get in vehicle and start moving
                    while isInExam and instructorVehicle and DoesEntityExist(instructorVehicle) and instructorPed and DoesEntityExist(instructorPed) do
                        local playerVehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                        if playerVehicle and DoesEntityExist(playerVehicle) then
                            -- Get player speed and calculate instructor speed dynamically
                            local playerSpeed = GetEntitySpeed(playerVehicle)
                            local distance = #(GetEntityCoords(instructorVehicle) - GetEntityCoords(playerVehicle))

                            -- Base speed is player speed + 5, with bonus if falling behind
                            local instructorSpeed = playerSpeed + 5.0
                            if distance > 15.0 then
                                instructorSpeed = instructorSpeed + (distance - 15.0) * 0.5 -- Accelerate more if far
                            end
                            instructorSpeed = math.max(instructorSpeed, 15.0) -- Minimum speed
                            instructorSpeed = math.min(instructorSpeed, 50.0) -- Maximum speed cap

                            -- Use TaskVehicleEscort with dynamic speed
                            -- Mode -1 = follow behind, noRoadsDistance 50 for better catching up
                            TaskVehicleEscort(instructorPed, instructorVehicle, playerVehicle, -1, instructorSpeed, 786603, 6.0, 0, 50.0)
                        end
                        Wait(500) -- Update more frequently for responsive speed adjustment
                    end
                end)
            end

                -- Create blip for first checkpoint only (prevents lag from multiple blips)
                examBlips[1] = createCheckpointBlip(currentExam.route.checkpoints[1].coords, true)

                -- Initialize exam state variables
                currentCheckpoint = 1
                examStartTime = GetGameTimer()

                -- Show mistake counter UI
                SendNUIMessage({
                    action = "dvm:mistakeCounter",
                    data = {
                        visible = true,
                        mistakes = 0
                    }
                })

                instructorSpeak(getRandomComment(InstructorComments.examStart), 5000)

                -- Start the verification threads
                CreateThread(function()
                    while isInExam do
                        checkDrivingViolations()
                        checkCheckpointProgress()

                        -- Exit if exam was cleaned up during checks
                        if not currentExam then break end

                        -- Check the timeout
                        if GetGameTimer() - examStartTime > currentExam.timeLimit then
                            table.insert(violations, {
                                type = "timeout",
                                description = "Temps d'examen dépassé",
                                penalty = 50,
                                timestamp = GetGameTimer()
                            })
                            finishDrivingExam()
                            break
                        end

                        Wait(100)
                    end
                end)

                -- Thread for checkpoint markers
                CreateThread(function()
                    while isInExam do
                        if not currentExam then break end
                        local checkpoint = currentExam.route.checkpoints[currentCheckpoint]
                        if checkpoint then
                            local coords = checkpoint.coords
                            DrawMarker(25, coords.x, coords.y, coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                5.0, 5.0, 0.5, 100, 200, 120, 120, false, true, 2, false, nil, nil, false)
                        end
                        Wait(0)
                    end
                end)

            -- Thread for ambient instructor comments (random sarcastic remarks)
            CreateThread(function()
                -- Wait a bit before first ambient comment
                Wait(15000) -- Wait 15 seconds after exam start

                while isInExam do
                    -- Random comment every 30-60 seconds
                    local randomDelay = math.random(30000, 60000)
                    Wait(randomDelay)

                    if isInExam then
                        instructorSpeak(getRandomComment(InstructorComments.ambient), 3000)
                    end
                end
            end)
        end
    end

    cb({ success = true })
end)

-- Event to cancel the exam
RegisterNUICallback("dvm:cancelExam", function(data, cb)
    TriggerServerEvent("dvm:cancelExam")
    cleanupExam()
    VFW.Nui.Focus(false)
    cb({ success = true })
end)


-- Event to get the player's licenses
RegisterNUICallback("dvm:getPlayerLicenses", function(data, cb)
    local result = TriggerServerCallback("dvm:getPlayerLicenses")
    cb(result)
end)

-- Event to get the exam history
RegisterNUICallback("dvm:getExamHistory", function(data, cb)
    local result = TriggerServerCallback("dvm:getExamHistory")
    cb(result)
end)

-- Clean up when disconnecting
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanupExam()
    end
end)

-- Cancel the exam if the player leaves the vehicle during the exam
CreateThread(function()
    while true do
        if isInExam and examVehicle then
            local playerPed = VFW.PlayerData.ped
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if vehicle ~= examVehicle then
                isInExam = false
                instructorSpeak(getRandomComment(InstructorComments.leftVehicle), 3000)

                TriggerServerEvent("dvm:cancelExam")

                VFW.ShowNotification({
                    type = 'error',
                    content = "Examen annulé : vous avez quitté le véhicule",
                    duration = 5
                })

                cleanupExam()
            end
        end
        Wait(1000)
    end
end)

-- Create the exam center blips
CreateThread(function()
    for _, center in ipairs(Config.DVM.ExamCenters) do
        -- Create the blip
        local blip = AddBlipForCoord(center.coords.x, center.coords.y, center.coords.z)
        SetBlipSprite(blip, center.blip.sprite)
        SetBlipColour(blip, center.blip.color)
        SetBlipScale(blip, center.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(center.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

