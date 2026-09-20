---@meta _
---@diagnostic disable: duplicate-doc-field

local isHackingBank = false
local isDrillingSafe = false
local currentBank = nil
local robberyBlips = {}
local lastInteractionAttempt = 0
local drilledSafes = {}
local hackingBanks = {}
local drillingBanks = {}
local openVaultDoors = {} -- Track which vault doors are currently open
local activeRobberies = {} -- Track des braquages en cours par banque

local FleecaBanks = {}
local bankBlips = {}
local hackPointBlips = {}  -- Blips pour les points de hack (visibles à 5m)
local safeBlips = {}  -- Blips pour les coffres (visibles à 5m quand actifs)

-- Variables pour sauvegarder la position avant TP (comme Pacific)
local savedHackPosition = nil
local savedHackHeading = nil
local isAtHackPosition = false

-- Durées en secondes
local ROBBERY_DURATION = 10 * 60  -- 10 minutes pour le braquage (coffres accessibles)
local DOOR_OPEN_DURATION = 30 * 60  -- 30 minutes pour la porte ouverte

local FleecaSettings = {
    InteractDistance = 1.0,
    SafeInteractDistance = 1.0,
    BankAccessDistance = 2.0,  -- Distance pour accéder au compte bancaire (comme superettes)
    PoliceBlipDuration = 480000,
    Hack = {
        MiniGameLevels = 2,
        MiniGameLives = 3,
        MiniGameMinutes = 1,
        Duration = 60,
        EmoteName = "tablet"  -- Emote tablette pour le hack (comme Pacific)
    },
    Safe = {
        DrillTime = 30
    }
}

-- ============================================
-- TIMER INTERNE POUR LE BRAQUAGE (sans affichage NUI)
-- ============================================

-- Thread pour gérer le timer du braquage d'une banque
local function StartRobberyTimerThread(bankId)
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + (ROBBERY_DURATION * 1000)

        activeRobberies[bankId] = {
            startTime = startTime,
            endTime = endTime
        }

        while activeRobberies[bankId] do
            Citizen.Wait(1000)

            local currentTime = GetGameTimer()
            local timeLeft = math.floor((endTime - currentTime) / 1000)

            if timeLeft <= 0 then
                -- Temps écoulé - reset du braquage (mais pas de la porte)
                activeRobberies[bankId] = nil

                -- Reset des coffres pour cette banque
                if drilledSafes[bankId] then
                    drilledSafes[bankId] = nil
                end

                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Temps écoulé ! Les coffres ne sont plus accessibles."
                })

                TriggerServerEvent('core:fleeca:robberyTimeout', bankId)
                return
            end
        end
    end)
end

-- ============================================
-- ANIMATION DE PORTE DU COFFRE (comme Pacific)
-- ============================================

local doorOriginalStates = {}
local isDoorAnimating = false

-- Configuration de l'animation de la porte
local VAULT_DOOR_CONFIG = {
    openDuration = 5000,   -- Durée d'ouverture en ms (5 secondes)
    closeDuration = 3000,  -- Durée de fermeture en ms (3 secondes)
    openAngle = 90.0,      -- Angle d'ouverture (degrés)
    useEasing = true,      -- Utiliser l'easing pour un effet réaliste
    playSound = true,      -- Jouer le son de la porte
}

-- Fonction d'easing (ease-out cubic) pour ralentir à la fin
local function EaseOutCubic(t)
    return 1 - math.pow(1 - t, 3)
end

-- Fonction d'easing (ease-in cubic) pour accélérer au début
local function EaseInCubic(t)
    return t * t * t
end

-- Normalise un angle entre 0 et 360
local function NormalizeAngle(angle)
    while angle < 0 do angle = angle + 360 end
    while angle >= 360 do angle = angle - 360 end
    return angle
end

-- Interpole entre deux angles (prend le chemin le plus court)
local function LerpAngle(from, to, t)
    local diff = to - from
    if diff > 180 then
        diff = diff - 360
    elseif diff < -180 then
        diff = diff + 360
    end
    return NormalizeAngle(from + diff * t)
end

-- Trouve la porte du coffre-fort d'une banque Fleeca
local function FindFleecaVaultDoor(bank)
    if not bank or not bank.vaultDoorPos then return nil end

    local doorModel = bank.vaultDoorPos.model
    if not doorModel then return nil end
    if type(doorModel) == "string" then
        doorModel = GetHashKey(doorModel)
    end

    local doorPos = vector3(bank.vaultDoorPos.x, bank.vaultDoorPos.y, bank.vaultDoorPos.z)
    local objects = GetGamePool('CObject')

    for _, obj in pairs(objects) do
        if GetEntityModel(obj) == doorModel then
            local objPos = GetEntityCoords(obj)
            local distance = #(doorPos - objPos)

            if distance < 3.0 then
                -- Sauvegarder l'état original de la porte
                if not doorOriginalStates[obj] then
                    doorOriginalStates[obj] = {
                        heading = GetEntityHeading(obj),
                        coords = GetEntityCoords(obj),
                        rotation = GetEntityRotation(obj)
                    }
                end
                return obj
            end
        end
    end

    return nil
end

-- Joue le son de la porte du coffre
local function PlayVaultDoorSound(bank, isOpening)
    if not VAULT_DOOR_CONFIG.playSound then return end
    if not bank or not bank.vaultDoorPos then return end

    local doorPos = vector3(bank.vaultDoorPos.x, bank.vaultDoorPos.y, bank.vaultDoorPos.z)

    if isOpening then
        PlaySoundFromCoord(-1, "Door_Open", doorPos.x, doorPos.y, doorPos.z, "DLC_HEIST_FLEECA_SOUNDSET", true, 50.0, false)
    else
        PlaySoundFromCoord(-1, "Door_Close", doorPos.x, doorPos.y, doorPos.z, "DLC_HEIST_FLEECA_SOUNDSET", true, 50.0, false)
    end
end

-- Anime la porte du coffre progressivement
local function AnimateDoorHeading(door, isOpen, duration, callback)
    if not DoesEntityExist(door) then
        if callback then callback() end
        return
    end

    -- Sauvegarder l'état original si pas encore fait
    if not doorOriginalStates[door] then
        doorOriginalStates[door] = {
            heading = GetEntityHeading(door),
            coords = GetEntityCoords(door),
            rotation = GetEntityRotation(door)
        }
    end

    local originalHeading = doorOriginalStates[door].heading
    local openHeading = NormalizeAngle(originalHeading - VAULT_DOOR_CONFIG.openAngle)

    local startHeading = GetEntityHeading(door)
    local targetHeading = isOpen and openHeading or originalHeading

    -- Si déjà à la position cible, ne rien faire
    if math.abs(NormalizeAngle(startHeading - targetHeading)) < 1.0 then
        if callback then callback() end
        return
    end

    -- Débloquer la porte pour l'animation
    FreezeEntityPosition(door, false)

    -- Lancer l'animation dans un thread
    CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + duration

        while GetGameTimer() < endTime do
            if not DoesEntityExist(door) then break end

            local elapsed = GetGameTimer() - startTime
            local progress = elapsed / duration

            -- Appliquer l'easing si activé
            if VAULT_DOOR_CONFIG.useEasing then
                if isOpen then
                    progress = EaseOutCubic(progress)
                else
                    progress = EaseInCubic(progress)
                end
            end

            local currentHeading = LerpAngle(startHeading, targetHeading, progress)
            SetEntityHeading(door, currentHeading)

            Wait(0)
        end

        -- S'assurer que la porte est exactement à la position finale
        if DoesEntityExist(door) then
            SetEntityHeading(door, targetHeading)
            FreezeEntityPosition(door, true)
        end

        if callback then callback() end
    end)
end

-- Change l'état de la porte (instantané ou animé)
local function SetFleecaDoorState(door, isOpen, animated, duration, callback)
    if not DoesEntityExist(door) then
        if callback then callback() end
        return
    end

    -- Sauvegarder l'état original si pas encore fait
    if not doorOriginalStates[door] then
        doorOriginalStates[door] = {
            heading = GetEntityHeading(door),
            coords = GetEntityCoords(door),
            rotation = GetEntityRotation(door)
        }
    end

    if animated then
        local animDuration = duration or (isOpen and VAULT_DOOR_CONFIG.openDuration or VAULT_DOOR_CONFIG.closeDuration)
        AnimateDoorHeading(door, isOpen, animDuration, callback)
    else
        FreezeEntityPosition(door, false)

        if isOpen then
            local newHeading = NormalizeAngle(doorOriginalStates[door].heading - VAULT_DOOR_CONFIG.openAngle)
            SetEntityHeading(door, newHeading)
        else
            SetEntityHeading(door, doorOriginalStates[door].heading)
        end

        FreezeEntityPosition(door, true)

        if callback then callback() end
    end
end

-- Ouvre la porte du coffre avec animation
local function OpenVaultDoorAnimated(bank, duration, callback)
    if isDoorAnimating then
        return
    end

    local door = FindFleecaVaultDoor(bank)
    if not door then
        if callback then callback() end
        return
    end

    isDoorAnimating = true
    PlayVaultDoorSound(bank, true)

    SetFleecaDoorState(door, true, true, duration, function()
        isDoorAnimating = false
        if callback then callback() end
    end)
end

-- Ferme la porte du coffre avec animation
local function CloseVaultDoorAnimated(bank, duration, callback)
    if isDoorAnimating then
        return
    end

    local door = FindFleecaVaultDoor(bank)
    if not door then
        if callback then callback() end
        return
    end

    isDoorAnimating = true
    PlayVaultDoorSound(bank, false)

    SetFleecaDoorState(door, false, true, duration, function()
        isDoorAnimating = false
        if callback then callback() end
    end)
end

-- ============================================

function GetFleecaBanks()
    return FleecaBanks
end

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function GetClosestBank()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, bank in pairs(FleecaBanks) do
        if bank.active and bank.canRob then
            local dist = #(coords - vector3(bank.pos.x, bank.pos.y, bank.pos.z))
            if dist < closestDist then
                closest = id
                closestDist = dist
            end
        end
    end

    return closest, closestDist
end

-- Fonction pour démarrer l'interaction de hack (TP + emote)
local function StartHackInteraction(bank)
    local ped = PlayerPedId()

    -- Sauvegarder la position actuelle
    savedHackPosition = GetEntityCoords(ped)
    savedHackHeading = GetEntityHeading(ped)

    -- 1. Freeze le joueur + Fade out
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords du hack (position de la porte)
    local hackPos = bank.doorHackPos
    SetEntityCoordsNoOffset(ped, hackPos.x, hackPos.y, hackPos.z, false, false, false)

    -- 4. SetEntityHeading (face à la porte - utiliser heading du doorHackPos si défini)
    local heading = hackPos.h or hackPos.heading or 0.0
    SetEntityHeading(ped, heading)

    Wait(100)

    -- 5. Lancer l'animation tablet (même animation que /e tablet)
    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    local animName = "base"
    local animFlag = 1 | 8 | 16 | 32 | 1048576 -- Loop + upper body

    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 8.0, -4.0, -1, animFlag, 0, false, false, false)
    end

    -- 6. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    isAtHackPosition = true
end

-- Fonction pour arrêter l'interaction de hack et retourner à la position initiale
local function StopHackInteraction()
    local ped = PlayerPedId()

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Arrêter l'emote (with safety check)
    if EmoteCancel and type(EmoteCancel) == "function" then
        pcall(EmoteCancel)
    end
    ClearPedTasks(ped)

    -- 3. Retour à la position sauvegardée
    if savedHackPosition then
        SetEntityCoordsNoOffset(ped, savedHackPosition.x, savedHackPosition.y, savedHackPosition.z, false, false, false)
        if savedHackHeading then
            SetEntityHeading(ped, savedHackHeading)
        end
    end

    -- 4. S'assurer que le joueur peut bouger
    FreezeEntityPosition(ped, false)

    -- 5. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- Reset des variables
    isAtHackPosition = false
    savedHackPosition = nil
    savedHackHeading = nil
end

local function StartBankHack(bankId)
    if isHackingBank then
        return
    end

    local canHack, reason = TriggerServerCallback("core:fleeca:canHackBank", bankId)

    if not canHack then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Impossible de pirater maintenant"
        })
        return
    end

    local bank = FleecaBanks[bankId]
    if not bank then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Cette banque n'est pas valide"
        })
        return
    end

    isHackingBank = true
    currentBank = bankId

    TriggerServerEvent("core:fleeca:startHack", bankId)

    -- Démarrer l'interaction (TP + emote tablette)
    StartHackInteraction(bank)

    -- 6 hacks firewall d'affilée
    local totalHacks = 6
    local currentHack = 0
    local allSuccess = true


    local function DoNextHack()
        currentHack = currentHack + 1

        if currentHack > totalHacks then
            -- Tous les hacks terminés avec succès
            local ped = PlayerPedId()

            DoScreenFadeOut(400)
            Wait(450)

            EmoteCancel()
            ClearPedTasks(ped)
            ClearPedTasksImmediately(ped)

            if savedHackPosition then
                SetEntityCoordsNoOffset(ped, savedHackPosition.x, savedHackPosition.y, savedHackPosition.z, false, false, false)
                if savedHackHeading then
                    SetEntityHeading(ped, savedHackHeading)
                end
            end

            FreezeEntityPosition(ped, false)

            Wait(100)
            DoScreenFadeIn(400)

            isAtHackPosition = false
            savedHackPosition = nil
            savedHackHeading = nil

            -- Hack réussi - envoyer au serveur pour ouvrir la porte
            TriggerServerEvent("core:fleeca:completeHack", bankId)

            VFW.ShowNotification({
                type = 'ILLEGAL',
                message = "Porte de la salle des coffres piratée ! Vous avez 10 minutes pour les coffres."
            })

            -- Démarrer le thread de gestion du timer (sans affichage)
            StartRobberyTimerThread(bankId)

            isHackingBank = false
            currentBank = nil
            return
        end

        -- Notification de progression
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Firewall " .. currentHack .. "/" .. totalHacks
        })


        StartHacking('firewall', 'hard', nil, function(success)

            if success then
                -- Hack réussi, passer au suivant
                Wait(500) -- Petite pause entre les hacks
                DoNextHack()
            else
                -- Hack échoué - tout arrêter
                local ped = PlayerPedId()

                DoScreenFadeOut(400)
                Wait(450)

                EmoteCancel()
                ClearPedTasks(ped)
                ClearPedTasksImmediately(ped)

                if savedHackPosition then
                    SetEntityCoordsNoOffset(ped, savedHackPosition.x, savedHackPosition.y, savedHackPosition.z, false, false, false)
                    if savedHackHeading then
                        SetEntityHeading(ped, savedHackHeading)
                    end
                end

                FreezeEntityPosition(ped, false)

                Wait(100)
                DoScreenFadeIn(400)

                isAtHackPosition = false
                savedHackPosition = nil
                savedHackHeading = nil

                TriggerServerEvent("core:fleeca:failHack", bankId)

                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Piratage échoué au firewall " .. currentHack .. "/" .. totalHacks .. " !"
                })

                isHackingBank = false
                currentBank = nil
            end
        end)
    end

    -- Démarrer la chaîne de hacks
    DoNextHack()
end

local function OpenBankingMenu(bankId)
    -- Utiliser le système centralisé de banking.lua
    -- Cela permet la fermeture avec Escape et une gestion cohérente
    Web.Banking(true)
end

local function StartSafeDrilling(bankId, safeIndex)
    if isDrillingSafe then return end

    local canDrill, reason = TriggerServerCallback("core:fleeca:canDrillSafe", bankId, safeIndex)

    if not canDrill then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Impossible de percer ce coffre maintenant"
        })
        return
    end

    local bank = FleecaBanks[bankId]
    if not bank or not bank.safePositions or not bank.safePositions[safeIndex] then
        return
    end

    isDrillingSafe = true
    currentBank = bankId

    TriggerServerEvent("core:fleeca:startDrill", bankId, safeIndex)

    local safePos = bank.safePositions[safeIndex]

    StartFleecaDrilling(safePos, function(success)
        if success then
            TriggerServerEvent("core:fleeca:completeDrill", bankId, safeIndex)

            -- Mark safe as drilled ONLY on success
            if not drilledSafes[bankId] then
                drilledSafes[bankId] = {}
            end
            drilledSafes[bankId][safeIndex] = true
        else
            -- Don't mark as drilled on failure - allow retry
            TriggerServerEvent("core:fleeca:failDrill", bankId, safeIndex)

            VFW.ShowNotification({
                type = 'ILLEGAL',
                message = "Perçage échoué ! Vous pouvez réessayer."
            })
        end
        isDrillingSafe = false
        currentBank = nil
    end)
end

CreateThread(function()
    Wait(1000)
    TriggerServerEvent("core:fleeca:requestBanksList")
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local minDist = 999999.0 -- Track minimum distance for adaptive wait
        local needsMarkerDraw = false -- Track if we need to draw markers (requires Wait(0))

        for id, bank in pairs(FleecaBanks) do
            if bank.active then
                if bank.canRob and bank.doorHackPos then
                    local isBeingHacked = hackingBanks[id] and hackingBanks[id].isHacking
                    local isDoorOpen = openVaultDoors[id] -- Check if door is already open
                    local hackPos = vector3(bank.doorHackPos.x, bank.doorHackPos.y, bank.doorHackPos.z)
                    local dist = #(playerCoords - hackPos)

                    -- Track minimum distance
                    if dist < minDist then minDist = dist end

                    -- Blip de hack désactivé (pas de blip sur la map pour le point de hack)
                    -- Le marker 3D reste visible à 50m
                    if not isBeingHacked and not isDoorOpen then
                        -- Marker toujours visible à 50m
                        if dist < 50.0 then
                            needsMarkerDraw = true
                            DrawMarker(1,
                                bank.doorHackPos.x, bank.doorHackPos.y, bank.doorHackPos.z - 1.0,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                0.5, 0.5, 0.1,
                                255, 0, 0, 100,
                                false, true, 2, false, nil, nil, false
                            )
                        end
                    end
                end

                -- Points d'accès bancaire : pas de marker visible (zone de 2m comme superettes)
                -- La détection se fait dans le thread d'interaction plus bas

                -- Afficher les coffres UNIQUEMENT si le braquage est en cours (timer actif)
                if bank.canRob and bank.safePositions and activeRobberies[id] then
                    for safeIndex, safePos in ipairs(bank.safePositions) do
                        if not (drilledSafes[id] and drilledSafes[id][safeIndex]) then
                            local isBeingDrilled = drillingBanks[id] and drillingBanks[id].isDrilling and drillingBanks[id].safeIndex == safeIndex
                            if not isBeingDrilled then
                                local safePosVec = vector3(safePos.x, safePos.y, safePos.z)
                                local dist = #(playerCoords - safePosVec)

                                -- Blip coffre visible à 5m quand actif
                                local safeBlipKey = id .. "_" .. safeIndex
                                if dist < 5.0 then
                                    if not safeBlips[safeBlipKey] then
                                        local blip = AddBlipForCoord(safePos.x, safePos.y, safePos.z)
                                        SetBlipSprite(blip, 500) -- Safe icon
                                        SetBlipDisplay(blip, 4)
                                        SetBlipScale(blip, 0.5)
                                        SetBlipColour(blip, 2) -- Vert
                                        SetBlipAsShortRange(blip, true)
                                        BeginTextCommandSetBlipName("STRING")
                                        AddTextComponentString("Coffre #" .. safeIndex)
                                        EndTextCommandSetBlipName(blip)
                                        safeBlips[safeBlipKey] = blip
                                    end
                                else
                                    if safeBlips[safeBlipKey] then
                                        RemoveBlip(safeBlips[safeBlipKey])
                                        safeBlips[safeBlipKey] = nil
                                    end
                                end

                                -- Markers supprimés (blips suffisent)
                            else
                                -- Coffre en cours de perçage, supprimer le blip
                                local safeBlipKey = id .. "_" .. safeIndex
                                if safeBlips[safeBlipKey] then
                                    RemoveBlip(safeBlips[safeBlipKey])
                                    safeBlips[safeBlipKey] = nil
                                end
                            end
                        else
                            -- Coffre déjà percé, supprimer le blip
                            local safeBlipKey = id .. "_" .. safeIndex
                            if safeBlips[safeBlipKey] then
                                RemoveBlip(safeBlips[safeBlipKey])
                                safeBlips[safeBlipKey] = nil
                            end
                        end
                    end
                else
                    -- Braquage pas actif, supprimer tous les blips de coffres pour cette banque
                    if bank.safePositions then
                        for safeIndex, _ in ipairs(bank.safePositions) do
                            local safeBlipKey = id .. "_" .. safeIndex
                            if safeBlips[safeBlipKey] then
                                RemoveBlip(safeBlips[safeBlipKey])
                                safeBlips[safeBlipKey] = nil
                            end
                        end
                    end
                end
            end
        end

        -- Adaptive wait: only run at 60fps if we need to draw markers
        -- Otherwise, use longer wait based on distance to nearest bank
        if needsMarkerDraw then
            Wait(0)
        elseif minDist < 100.0 then
            Wait(100) -- Check every 100ms when somewhat close
        else
            Wait(500) -- Check every 500ms when far away
        end
    end
end)

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not isHackingBank and not isDrillingSafe then
            for id, bank in pairs(FleecaBanks) do
                if bank.active and bank.canRob and bank.doorHackPos then
                    local isBeingHacked = hackingBanks[id] and hackingBanks[id].isHacking
                    local isDoorOpen = openVaultDoors[id] -- Check if door is already open
                    if not isBeingHacked and not isDoorOpen then
                        local hackPos = vector3(bank.doorHackPos.x, bank.doorHackPos.y, bank.doorHackPos.z)
                        local dist = #(playerCoords - hackPos)

                        if dist < FleecaSettings.InteractDistance then
                            wait = 0
                            ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour pirater la porte de la salle des coffres")

                            if VFW.Interact.JustPressed(0, 38) then -- E key
                                local currentTime = GetGameTimer()
                                if currentTime - lastInteractionAttempt > 2000 then -- 2 second cooldown
                                    lastInteractionAttempt = currentTime
                                    StartBankHack(id)
                                end
                            end
                        end
                    end
                end
            end
        end

        if not isHackingBank and not isDrillingSafe then
            for id, bank in pairs(FleecaBanks) do
                if bank.active and bank.accountAccessPositions then
                    for accessIndex, accessPos in ipairs(bank.accountAccessPositions) do
                        local accessPosVec = vector3(accessPos.x, accessPos.y, accessPos.z)
                        local dist = #(playerCoords - accessPosVec)

                        if dist < FleecaSettings.BankAccessDistance then
                            wait = 0
                            ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour accéder à votre compte bancaire")

                            if VFW.Interact.JustPressed(0, 38) then -- E key
                                local currentTime = GetGameTimer()
                                if currentTime - lastInteractionAttempt > 500 then -- 500ms cooldown
                                    lastInteractionAttempt = currentTime
                                    OpenBankingMenu(id)
                                end
                            end
                        end
                    end
                end
            end
        end

        if not isHackingBank and not isDrillingSafe then
            for id, bank in pairs(FleecaBanks) do
                -- Interaction coffres UNIQUEMENT si braquage en cours (timer actif)
                if bank.active and bank.canRob and bank.safePositions and activeRobberies[id] then
                    for safeIndex, safePos in ipairs(bank.safePositions) do
                        if not (drilledSafes[id] and drilledSafes[id][safeIndex]) then
                            local isBeingDrilled = drillingBanks[id] and drillingBanks[id].isDrilling and drillingBanks[id].safeIndex == safeIndex
                            if not isBeingDrilled then
                                local safePosVec = vector3(safePos.x, safePos.y, safePos.z)
                                local dist = #(playerCoords - safePosVec)

                                if dist < FleecaSettings.SafeInteractDistance then
                                    wait = 0
                                    ShowHelp(string.format("Appuyez sur ~INPUT_CONTEXT~ pour percer le coffre #%d", safeIndex))

                                    if VFW.Interact.JustPressed(0, 38) then
                                        local currentTime = GetGameTimer()
                                        if currentTime - lastInteractionAttempt > 2000 then
                                            lastInteractionAttempt = currentTime
                                            StartSafeDrilling(id, safeIndex)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Sortie de secours supprimée (plus utilisée)

        Wait(wait)
    end
end)

RegisterNetEvent("core:fleeca:syncDrilledSafe")
AddEventHandler("core:fleeca:syncDrilledSafe", function(bankId, safeIndex)
    if not drilledSafes[bankId] then
        drilledSafes[bankId] = {}
    end
    drilledSafes[bankId][safeIndex] = true
end)

-- NOUVEAU: Sync de l'état du braquage pour multi-joueurs
RegisterNetEvent("core:fleeca:syncRobberyState")
AddEventHandler("core:fleeca:syncRobberyState", function(bankId, isActive, endTime)
    if isActive and endTime then
        activeRobberies[bankId] = {
            startTime = GetGameTimer(),
            endTime = endTime
        }
    else
        activeRobberies[bankId] = nil
        -- Reset des coffres locaux
        if drilledSafes[bankId] then
            drilledSafes[bankId] = nil
        end
    end
end)

-- Handler pour le sync du timeout de braquage (10 min écoulées)
RegisterNetEvent("core:fleeca:robberyTimeoutSync")
AddEventHandler("core:fleeca:robberyTimeoutSync", function(bankId)
    -- Reset les coffres locaux
    if drilledSafes[bankId] then
        drilledSafes[bankId] = nil
    end

    -- Reset le braquage actif
    if activeRobberies[bankId] then
        activeRobberies[bankId] = nil
    end
end)

RegisterNetEvent("core:fleeca:syncHackingState")
AddEventHandler("core:fleeca:syncHackingState", function(bankId, isHacking, playerId)
    if isHacking then
        hackingBanks[bankId] = {
            isHacking = true,
            playerId = playerId
        }
    else
        hackingBanks[bankId] = nil
    end
end)

RegisterNetEvent("core:fleeca:syncDrillingState")
AddEventHandler("core:fleeca:syncDrillingState", function(bankId, safeIndex, isDrilling, playerId)
    if isDrilling then
        drillingBanks[bankId] = {
            isDrilling = true,
            safeIndex = safeIndex,
            playerId = playerId
        }
    else
        drillingBanks[bankId] = nil
    end
end)

RegisterNetEvent("core:fleeca:createPoliceBlip")
AddEventHandler("core:fleeca:createPoliceBlip", function(bankId)
    if IsPoliceJob(VFW.PlayerData.job.name) then
        local bank = FleecaBanks[bankId]
        if bank then
            local blip = AddBlipForCoord(bank.pos.x, bank.pos.y, bank.pos.z)
            SetBlipSprite(blip, 161)
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 1)
            SetBlipAsShortRange(blip, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("10.40 - Braquage Banque Fleeca")
            EndTextCommandSetBlipName(blip)

            table.insert(robberyBlips, blip)

            SetTimeout(FleecaSettings.PoliceBlipDuration, function()
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end)
        end
    end
end)

local function CleanupBank(id)
    if bankBlips[id] then
        if DoesBlipExist(bankBlips[id]) then
            RemoveBlip(bankBlips[id])
        end
        bankBlips[id] = nil
    end
end

-- Fonction pour recréer tous les blips Fleeca
-- Le stack automatique de GTA V fonctionne quand les blips ont le même sprite ET le même nom
local function RefreshAllFleecaBlips()
    -- Supprimer tous les blips existants
    for id, blip in pairs(bankBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    bankBlips = {}

    -- Créer les blips pour chaque banque active avec blip activé
    for id, bank in pairs(FleecaBanks) do
        if bank.active and bank.blipEnabled then
            local blip = AddBlipForCoord(bank.pos.x, bank.pos.y, bank.pos.z)
            SetBlipSprite(blip, 108) -- Bank icon
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 2) -- Vert
            SetBlipAsShortRange(blip, true)
            -- Même nom pour tous = GTA gère le stack automatiquement (1/X, 2/X, etc.)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Banque Fleeca")
            EndTextCommandSetBlipName(blip)

            bankBlips[id] = blip
        end
    end
end

local function SetupBank(id, bank)
    -- Ne plus créer de blip individuel ici
    -- La création se fait via RefreshAllFleecaBlips pour avoir la numérotation correcte
    CleanupBank(id)
end

local fleecaDoors = {}
local doorIdCounter = 2000

local function SetupFleecaDoors()
    for id, bank in pairs(FleecaBanks) do
        if bank.vaultDoorPos then
            local doorModel = bank.vaultDoorPos.model
            local doorId = doorIdCounter + id

            AddDoorToSystem(doorId, doorModel, bank.vaultDoorPos.x, bank.vaultDoorPos.y, bank.vaultDoorPos.z, false, false, false)
            DoorSystemSetDoorState(doorId, 1, false, false)

            fleecaDoors[id] = doorId
        end
    end
end

-- Fonction pour nettoyer tous les blips de hack point (appelé lors de la sync des banques)
local function CleanupAllHackPointBlips()
    for id, blip in pairs(hackPointBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    hackPointBlips = {}
end

-- Fonction pour nettoyer tous les blips de coffres
local function CleanupAllSafeBlips()
    for key, blip in pairs(safeBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    safeBlips = {}
end

RegisterNetEvent("core:fleeca:syncBanks")
AddEventHandler("core:fleeca:syncBanks", function(banks)
    -- Nettoyer TOUS les blips de hack point avant de sync (pour éviter les blips orphelins)
    CleanupAllHackPointBlips()

    -- Nettoyer aussi les blips de coffres
    CleanupAllSafeBlips()

    FleecaBanks = banks

    -- Rafraîchir tous les blips avec la numérotation correcte
    RefreshAllFleecaBlips()

    SetupFleecaDoors()
end)

RegisterNetEvent("core:fleeca:requestBanksList")
AddEventHandler("core:fleeca:requestBanksList", function()
end)

RegisterNetEvent("core:fleeca:openVaultDoor")
AddEventHandler("core:fleeca:openVaultDoor", function(bankId, doorPosition, doorModel)
    if not doorPosition or not doorModel then return end

    local bank = FleecaBanks[bankId]

    if not fleecaDoors[bankId] then
        local doorId = doorIdCounter + bankId

        AddDoorToSystem(doorId, doorModel, doorPosition.x, doorPosition.y, doorPosition.z, false, false, false)
        fleecaDoors[bankId] = doorId
    end

    -- Utiliser DoorSystem pour déverrouiller (permet à la porte de bouger)
    DoorSystemSetDoorState(fleecaDoors[bankId], 0, false, false)

    -- Ouvrir la porte avec animation (comme Pacific)
    if bank then
        OpenVaultDoorAnimated(bank, nil, function()
            -- print("^2[Fleeca] Porte du coffre ouverte avec animation^0")
        end)
    end

    -- Mark door as open to hide interaction
    openVaultDoors[bankId] = true
end)

RegisterNetEvent("core:fleeca:closeVaultDoor")
AddEventHandler("core:fleeca:closeVaultDoor", function(bankId, doorPosition, doorModel)
    if not doorPosition or not doorModel then return end

    local bank = FleecaBanks[bankId]

    if not fleecaDoors[bankId] then
        local doorId = doorIdCounter + bankId

        AddDoorToSystem(doorId, doorModel, doorPosition.x, doorPosition.y, doorPosition.z, false, false, false)
        fleecaDoors[bankId] = doorId
    end

    -- Fermer la porte avec animation (comme Pacific)
    if bank then
        CloseVaultDoorAnimated(bank, nil, function()
            -- print("^2[Fleeca] Porte du coffre fermée avec animation^0")
            -- Verrouiller après l'animation
            DoorSystemSetDoorState(fleecaDoors[bankId], 1, false, false)
        end)
    else
        DoorSystemSetDoorState(fleecaDoors[bankId], 1, false, false)
    end

    if drilledSafes[bankId] then
        drilledSafes[bankId] = nil
    end

    hackingBanks[bankId] = nil
    drillingBanks[bankId] = nil

    -- Mark door as closed to show interaction again
    openVaultDoors[bankId] = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in ipairs(robberyBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        for id, blip in pairs(bankBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        -- Nettoyer les blips de hack point
        for id, blip in pairs(hackPointBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        -- Nettoyer les blips de coffres
        for key, blip in pairs(safeBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        TriggerServerEvent("core:fleeca:requestBanksList")
    end
end)