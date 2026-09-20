local jewelryConfig = nil
local jewelrySettings = {}
local hackingInProgress = false
local otherPlayerHacking = nil -- Track si un autre joueur est en train de hacker
local robberyInProgress = false
local robberyTimeLimit = 0
local robbedCases = {}
local displayCaseBlips = {}
local computerBlip = nil
local policeBlip = nil
local jewelryMapBlip = nil
local showingComputerBlip = false

-- ============================================
-- CONFIGURATION PC BIJOUTERIE (comme Pacific)
-- ============================================
local JEWELRY_PC_CONFIG = {
    x = 0.0,        -- À définir via admin
    y = 0.0,
    z = 0.0,
    heading = 0.0,
    emoteName = "type"  -- Emote de pianotage sur clavier
}

-- Variables pour l'interaction PC
local isAtJewelryPC = false
local savedPCPosition = nil
local savedPCHeading = nil

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

-- Obtient la position de la vitrine (vitrineX/Y/Z si disponible, sinon x/y/z)
local function GetVitrinePosition(caseData)
    if caseData.vitrineX and caseData.vitrineY and caseData.vitrineZ then
        return vector3(caseData.vitrineX, caseData.vitrineY, caseData.vitrineZ)
    else
        return vector3(caseData.x, caseData.y, caseData.z)
    end
end

-- Applique le model swap pour une vitrine cassée (sans effet visuel)
local function ApplyBrokenVitrineVisual(caseData)
    if not caseData or not caseData.model or not caseData.modelFinish then return end

    local pos = GetVitrinePosition(caseData)
    local startModel = GetHashKey(caseData.model)
    local endModel = GetHashKey(caseData.modelFinish)

    -- Appliquer le model swap silencieusement (pas d'effet de particules)
    CreateModelSwap(pos.x, pos.y, pos.z, 1.5, startModel, endModel, true)

    -- Stocker aussi dans activeModelSwaps pour pouvoir restaurer plus tard
    table.insert(activeModelSwaps, {
        pos = pos,
        startModel = startModel,
        endModel = endModel
    })

end

RegisterNetEvent('core:jewelry:syncRobbedCases', function(globalRobbedCases)
    -- Attendre que la config soit chargée
    if not jewelryConfig or not jewelryConfig.displayCases then
        Citizen.SetTimeout(1000, function()
            if jewelryConfig and jewelryConfig.displayCases then
                TriggerEvent('core:jewelry:syncRobbedCases', globalRobbedCases)
            end
        end)
        return
    end

    for caseIndex, isRobbed in pairs(globalRobbedCases) do
        if isRobbed and not robbedCases[caseIndex] then
            robbedCases[caseIndex] = true

            -- Supprimer le blip de cette vitrine si elle existe
            if displayCaseBlips[caseIndex] then
                RemoveBlip(displayCaseBlips[caseIndex])
                displayCaseBlips[caseIndex] = nil
            end

            -- Appliquer le visuel de vitrine cassée
            local caseData = jewelryConfig.displayCases[caseIndex]
            if caseData then
                ApplyBrokenVitrineVisual(caseData)
            end
        end
    end

    -- Si globalRobbedCases est vide (reset), réinitialiser les vitrines locales et restaurer les visuels
    if next(globalRobbedCases) == nil then
        robbedCases = {}
        -- RestoreAllVitrines sera appelé par un event séparé
    end
end)

-- NOUVEAU: Synchronisation de l'état global du braquage (multi-joueurs)
RegisterNetEvent('core:jewelry:syncRobberyState', function(active, endTime)
    robberyInProgress = active
    if active and endTime then
        robberyTimeLimit = endTime
        ShowDisplayCaseBlips()
    else
        robberyTimeLimit = 0
        ClearDisplayCaseBlips()
    end
end)

-- NOUVEAU: Synchronisation de l'état du hack (empêche 2 joueurs de hacker en même temps)
RegisterNetEvent('core:jewelry:syncHackingState', function(isHacking, playerId)
    if isHacking then
        otherPlayerHacking = playerId
    else
        otherPlayerHacking = nil
    end
end)

RegisterNetEvent('core:jewelry:configUpdated', function(config)
    jewelryConfig = config
    SetupJewelryLocation()
end)

RegisterNetEvent('core:jewelry:settingsUpdated', function(settings)
    jewelrySettings = settings
    CheckMapBlipStatus()
end)

RegisterNetEvent('core:jewelry:configReloaded', function(config, settings)
    jewelryConfig = config
    jewelrySettings = settings
    SetupJewelryLocation()
    CheckMapBlipStatus()
end)

function SetupJewelryLocation()
    if not jewelryConfig then return end

    ClearJewelryBlips()

    if robberyInProgress then
        ShowDisplayCaseBlips()
    end
end

function ShowDisplayCaseBlips()
    if not jewelryConfig or not jewelryConfig.displayCases then return end

    ClearDisplayCaseBlips()

    for i, casePos in ipairs(jewelryConfig.displayCases) do
        local blip = AddBlipForCoord(casePos.x, casePos.y, casePos.z)
        SetBlipSprite(blip, 617)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 46)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Vitrine - Bijouterie")
        EndTextCommandSetBlipName(blip)
        table.insert(displayCaseBlips, blip)
    end
end

function ClearDisplayCaseBlips()
    for _, blip in ipairs(displayCaseBlips) do
        RemoveBlip(blip)
    end
    displayCaseBlips = {}
end

function ClearJewelryBlips()
    if computerBlip then
        RemoveBlip(computerBlip)
        computerBlip = nil
        showingComputerBlip = false
    end

    ClearDisplayCaseBlips()
end

-- Durée du braquage bijouterie (10 minutes)
local JEWELRY_ROBBERY_DURATION = 10 * 60

-- ============================================
-- SYSTÈME PC BIJOUTERIE AVEC EMOTE
-- TP + Emote "type" + 5 Hack Firewall enchaînés
-- ============================================

--- Téléporte le joueur au PC et lance l'emote de typing
--- @param callback function Fonction appelée une fois en position avec l'emote
local function StartJewelryPCInteraction(callback)
    local ped = PlayerPedId()

    -- Vérifier que la position du PC est configurée
    if not jewelryConfig or not jewelryConfig.computerPos then
        -- print("^1[Jewelry:PC] Position PC non configurée!^0")
        if callback then callback() end
        return
    end

    -- Utiliser la position du PC
    local pcConfig = jewelryConfig.computerPos
    -- Le heading est stocké dans computerPos.h par le builder
    local heading = jewelryConfig.computerPos.h or jewelryConfig.computerHeading or 0.0

    -- Sauvegarder la position actuelle du joueur
    savedPCPosition = GetEntityCoords(ped)
    savedPCHeading = GetEntityHeading(ped)

    -- print("^3[Jewelry:PC] Début interaction PC Bijouterie^0")

    -- 1. Freeze le joueur + Fade out (400ms)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords exactes du PC
    SetEntityCoordsNoOffset(ped, pcConfig.x, pcConfig.y, pcConfig.z, false, false, false)

    -- 4. SetEntityHeading (face au PC)
    SetEntityHeading(ped, heading)

    Wait(100)

    -- 5. Lancer l'emote "type" via le système d'emotes du serveur
    EmoteCommandStart(JEWELRY_PC_CONFIG.emoteName, ped, nil)

    -- 6. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 7. Marquer comme actif
    isAtJewelryPC = true

    -- print("^2[Jewelry:PC] Joueur en position avec emote 'type'^0")

    -- 8. Appeler le callback une fois prêt
    if callback then
        callback()
    end
end

--- Arrête l'interaction PC Bijouterie et retourne à la position initiale
--- @param callback function Fonction appelée une fois terminé
local function StopJewelryPCInteraction(callback)
    local ped = PlayerPedId()

    -- print("^3[Jewelry:PC] Fin interaction PC Bijouterie...^0")

    -- Marquer comme inactif immédiatement
    isAtJewelryPC = false

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Annuler l'emote en cours
    EmoteCancel()
    ClearPedTasks(ped)

    -- 3. Retour à la position sauvegardée
    if savedPCPosition then
        SetEntityCoordsNoOffset(ped, savedPCPosition.x, savedPCPosition.y, savedPCPosition.z, false, false, false)
        if savedPCHeading then
            SetEntityHeading(ped, savedPCHeading)
        end
    end

    -- 4. S'assurer que le joueur peut bouger
    FreezeEntityPosition(ped, false)

    -- 5. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 6. Réinitialiser les variables
    hackingInProgress = false
    savedPCPosition = nil
    savedPCHeading = nil

    -- print("^2[Jewelry:PC] Joueur retourné à sa position^0")

    -- 7. Appeler le callback une fois terminé
    if callback then
        callback()
    end
end

--- Quitte complètement le PC + libère le serveur
local function ExitJewelryPCCompletely()
    -- Libérer le lock côté serveur
    TriggerServerEvent('core:jewelry:failHack')

    -- Quitter l'interaction
    StopJewelryPCInteraction()
end

-- Thread pour détecter la touche Backspace quand au PC
CreateThread(function()
    while true do
        local wait = 500

        if isAtJewelryPC and not hackingInProgress then
            wait = 0
            -- Backspace (177) pour quitter (seulement si pas en train de hacker)
            if IsControlJustPressed(0, 177) then
                ExitJewelryPCCompletely()
            end
        end

        Wait(wait)
    end
end)

function StartComputerHack()
    if hackingInProgress or robberyInProgress then return end

    local hasDevice = TriggerServerCallback("core:jewelry:hasHackingDevice")
    if not hasDevice then
        VFW.ShowNotification({ type = "ILLEGAL", message = "Il vous faut un dispositif de piratage pour bijouterie" })
        return
    end

    local requirements = TriggerServerCallback("core:jewelry:checkRobberyRequirements")
    if not requirements.canRob then
        VFW.ShowNotification({ type = "ILLEGAL", message = requirements.reason })
        return
    end

    hackingInProgress = true

    -- Notifier le serveur qu'on commence le hack (lock pour autres joueurs)
    TriggerServerEvent('core:jewelry:startHack')

    -- Démarrer l'interaction TP + emote (comme Pacific)
    StartJewelryPCInteraction(function()
        -- Une fois en position, lancer les 5 hacks firewall enchaînés
        local totalHacks = 5
        local currentHack = 0

        local function DoNextHack()
            currentHack = currentHack + 1

            if currentHack > totalHacks then
                -- Tous les hacks réussis !
                VFW.ShowNotification({ type = "ILLEGAL", message = "Piratage réussi ! Vous avez 10 minutes pour casser les vitrines" })
                robberyInProgress = true
                robberyTimeLimit = GetGameTimer() + (JEWELRY_ROBBERY_DURATION * 1000)
                ShowDisplayCaseBlips()
                TriggerServerEvent('core:jewelry:hackSuccess')

                -- Quitter le PC avec animation
                StopJewelryPCInteraction(function()
                    hackingInProgress = false
                end)

                Citizen.CreateThread(function()
                    Citizen.Wait(5000) -- 5 secondes de délai avant l'alerte
                    TriggerServerEvent('core:jewelry:triggerPoliceAlert')
                end)
                return
            end

            -- Afficher la progression
            VFW.ShowNotification({
                type = "INFO",
                content = "Firewall " .. currentHack .. "/" .. totalHacks
            })

            -- Lancer le hack firewall (hard)
            exports['core']:StartHacking('firewall', 'hard', 30, function(hackSuccess)
                if hackSuccess then
                    -- Passer au hack suivant
                    DoNextHack()
                else
                    -- Hack échoué
                    VFW.ShowNotification({
                        type = "ILLEGAL",
                        message = "Piratage échoué au firewall " .. currentHack .. "/" .. totalHacks .. " !"
                    })
                    TriggerServerEvent('core:jewelry:failHack')
                    TriggerServerEvent('core:jewelry:hackFailed')

                    -- Quitter le PC avec animation
                    StopJewelryPCInteraction(function()
                        hackingInProgress = false
                    end)
                end
            end)
        end

        -- Démarrer le premier hack
        DoNextHack()
    end)
end

-- ============================================
-- SYSTÈME DE VITRINES AVEC EFFET DE VERRE BRISÉ
-- Mapping custom: cfx-fm-jewelry
-- Utilise les effets de particules natifs GTA V
-- ============================================

-- Table pour tracker les model swaps actifs (pour restauration)
local activeModelSwaps = {}

-- Prop utilisé pour le braquage
local SMASH_PROP = "prop_tool_hammer"  -- Marteau pour casser les vitrines

-- Variable pour tracker le prop actif
local currentProp = nil

-- Attache un prop à la main du joueur
local function AttachPropToHand(propModel, boneIndex)
    local playerPed = PlayerPedId()

    -- Supprimer l'ancien prop si existe
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end

    -- Charger le modèle du prop
    local propHash = GetHashKey(propModel)
    RequestModel(propHash)
    local timeout = 0
    while not HasModelLoaded(propHash) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(propHash) then
        return nil
    end

    -- Créer et attacher le prop
    local coords = GetEntityCoords(playerPed)
    local prop = VFW.OneSync.CreateObject(propHash, coords)

    -- Bone index: 57005 = main droite, 18905 = main gauche
    local bone = boneIndex or 57005

    -- Offsets pour le marteau (ajuster selon le prop)
    local xOff, yOff, zOff = 0.0, 0.0, 0.0
    local xRot, yRot, zRot = 0.0, 0.0, 0.0

    if propModel == "prop_tool_hammer" then
        -- Offsets pour que le marteau soit bien tenu (manche dans la main, tête dans le prolongement du bras)
        xOff, yOff, zOff = 0.12, 0.0, 0.0
        xRot, yRot, zRot = 90.0, 0.0, 0.0
    elseif propModel == "prop_cs_heist_bag_02" then
        xOff, yOff, zOff = 0.0, -0.05, 0.0
        xRot, yRot, zRot = 0.0, 0.0, 0.0
    end

    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, bone),
        xOff, yOff, zOff,
        xRot, yRot, zRot,
        true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(propHash)
    currentProp = prop

    return prop
end

-- Supprime le prop actif
local function RemoveCurrentProp()
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end
end

-- Joue l'effet de particules de bris de verre (effet natif GTA V)
local function PlayGlassBreakEffect(pos, heading)
    -- Charger l'asset de particules du heist bijouterie
    local ptfxAsset = "scr_jewelheist"
    RequestNamedPtfxAsset(ptfxAsset)

    local timeout = 0
    while not HasNamedPtfxAssetLoaded(ptfxAsset) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    if not HasNamedPtfxAssetLoaded(ptfxAsset) then
        return false
    end

    -- Calculer la position de l'effet (légèrement en avant de la vitrine, au niveau du verre)
    local effectZ = pos.z + 0.8  -- Hauteur du verre sur les vitrines

    -- Utiliser l'effet de bris de vitrine natif (non-looped pour un effet instantané)
    UseParticleFxAssetNextCall(ptfxAsset)
    local effect = StartParticleFxNonLoopedAtCoord(
        "scr_jewel_cab_smash",  -- Effet de bris de vitrine
        pos.x, pos.y, effectZ,
        0.0, 0.0, heading or 0.0,
        2.0,  -- Scale augmenté pour plus de visibilité
        false, false, false
    )

    -- Jouer le son de verre brisé
    PlaySoundFromCoord(-1, "Glass_Smash", pos.x, pos.y, pos.z, "DLC_HEIST_FLEECA_SOUNDSET", false, 50.0, false)

    -- Deuxième effet pour plus d'impact
    Citizen.SetTimeout(100, function()
        if HasNamedPtfxAssetLoaded(ptfxAsset) then
            UseParticleFxAssetNextCall(ptfxAsset)
            StartParticleFxNonLoopedAtCoord(
                "scr_jewel_cab_smash",
                pos.x, pos.y, effectZ + 0.2,
                0.0, 0.0, (heading or 0.0) + 45.0,
                1.5,
                false, false, false
            )
        end
    end)

    -- Nettoyer l'asset après utilisation
    Citizen.SetTimeout(1000, function()
        RemoveNamedPtfxAsset(ptfxAsset)
    end)

    return true
end

-- Casse la vitrine en utilisant CreateModelSwap (swap IPL natif)
local function BreakVitrine(caseData)
    if not caseData.model or not caseData.modelFinish then
        return
    end

    -- Utiliser la position de la vitrine (vitrineX/Y/Z si disponible)
    local vitrinePos = GetVitrinePosition(caseData)
    local startModel = GetHashKey(caseData.model)
    local endModel = GetHashKey(caseData.modelFinish)
    local heading = caseData.heading or 0.0


    -- Jouer l'effet de particules de bris de verre + son à la position de la vitrine
    PlayGlassBreakEffect(vitrinePos, heading)

    -- Utiliser CreateModelSwap pour remplacer le modèle sur le mapping
    -- Cette native remplace l'objet IPL directement (visible localement)
    CreateModelSwap(
        vitrinePos.x, vitrinePos.y, vitrinePos.z,  -- Position de la vitrine
        1.5,                   -- Rayon légèrement plus grand pour cibler
        startModel,            -- Modèle original (intact)
        endModel,              -- Modèle de remplacement (cassé)
        true                   -- Survivre au reload de map
    )

    -- Stocker le swap pour pouvoir le restaurer plus tard
    table.insert(activeModelSwaps, {
        pos = vitrinePos,
        startModel = startModel,
        endModel = endModel
    })

end

-- Restaure toutes les vitrines à leur état original
local function RestoreAllVitrines()

    for _, swap in ipairs(activeModelSwaps) do
        -- Supprimer le model swap (remet le modèle original)
        RemoveModelSwap(
            swap.pos.x, swap.pos.y, swap.pos.z,
            1.5,  -- Même rayon que CreateModelSwap
            swap.startModel,
            swap.endModel,
            true
        )
    end

    -- Vider la table
    activeModelSwaps = {}
end

-- Event réseau pour synchroniser le bris de vitrine à tous les joueurs
RegisterNetEvent('core:jewelry:syncBreakVitrine', function(caseData)
    BreakVitrine(caseData)
end)

-- Event réseau pour synchroniser la restauration des vitrines
RegisterNetEvent('core:jewelry:syncRestoreVitrines', function()
    RestoreAllVitrines()
end)

function RobDisplayCase(caseIndex)
    if not robberyInProgress then
        return
    end

    if robbedCases[caseIndex] then
        return
    end

    local playerPed = PlayerPedId()
    local caseData = jewelryConfig.displayCases[caseIndex]
    local casePos = vector3(caseData.x, caseData.y, caseData.z)

    robbedCases[caseIndex] = true

    if displayCaseBlips[caseIndex] then
        RemoveBlip(displayCaseBlips[caseIndex])
        displayCaseBlips[caseIndex] = nil
    end

    -- Orienter le joueur avec le heading sauvegardé par l'admin
    -- (le joueur est déjà à la bonne position car il est au marker)
    if caseData.heading then
        SetEntityHeading(playerPed, caseData.heading)
        Citizen.Wait(100)
    end

    -- Empêcher le joueur de bouger pendant l'animation
    FreezeEntityPosition(playerPed, true)

    -- Attacher le marteau à la main droite
    AttachPropToHand(SMASH_PROP, 57005)

    -- Charger les dictionnaires d'animation
    RequestAnimDict("missheist_jewel")
    local timeout = 0
    while not HasAnimDictLoaded("missheist_jewel") and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    -- Animation de cassage de vitre avec le marteau
    TaskPlayAnim(playerPed, "missheist_jewel", "smash_case", 8.0, 1.0, 2500, 0, 0, false, false, false)
    VFW.ShowNotification({ type = "ILLEGAL", message = "Vous cassez la vitrine..." })

    -- Attendre le moment de l'impact (quand le marteau frappe)
    Citizen.Wait(800)

    -- Casser la vitrine visuellement au moment de l'impact
    BreakVitrine(caseData)
    TriggerServerEvent('core:jewelry:breakVitrine', caseData)

    -- Attendre la fin de l'animation de cassage
    Citizen.Wait(1700)

    -- Retirer le marteau
    RemoveCurrentProp()

    -- Animation de ramassage des bijoux (sans props)
    RequestAnimDict("anim@heists@ornate_bank@grab_cash")
    timeout = 0
    while not HasAnimDictLoaded("anim@heists@ornate_bank@grab_cash") and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    TaskPlayAnim(playerPed, "anim@heists@ornate_bank@grab_cash", "grab", 8.0, 1.0, 10000, 1, 0, false, false, false)
    VFW.ShowNotification({ type = "ILLEGAL", message = "Vous ramassez les bijoux..." })
    Citizen.Wait(10000)

    -- Libérer le joueur
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)

    -- Envoyer au serveur
    TriggerServerEvent('core:jewelry:robCase', caseIndex)

    -- Afficher le nombre de vitrines restantes
    local totalCases = #jewelryConfig.displayCases
    local robbedCount = 0
    for _ in pairs(robbedCases) do
        robbedCount = robbedCount + 1
    end
    local remaining = totalCases - robbedCount

    if remaining > 0 then
        VFW.ShowNotification({ type = "ILLEGAL", message = string.format("Vitrine cassée ! Il reste %d vitrine%s à cambrioler", remaining, remaining > 1 and "s" or "") })
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = "Toutes les vitrines ont été cambriolées !" })
    end
end

Citizen.CreateThread(function()
    while true do
        if jewelryConfig then
            local sleep = 500
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if jewelryConfig.computerPos then
                local distance = #(playerCoords - vector3(jewelryConfig.computerPos.x, jewelryConfig.computerPos.y, jewelryConfig.computerPos.z))

                -- Blip visible uniquement à 25m
                if distance < 25.0 and not showingComputerBlip then
                    computerBlip = AddBlipForCoord(jewelryConfig.computerPos.x, jewelryConfig.computerPos.y, jewelryConfig.computerPos.z)
                    SetBlipSprite(computerBlip, 521)
                    SetBlipDisplay(computerBlip, 4)
                    SetBlipScale(computerBlip, 0.5)
                    SetBlipColour(computerBlip, 5)
                    SetBlipAsShortRange(computerBlip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Ordinateur - Bijouterie")
                    EndTextCommandSetBlipName(computerBlip)
                    showingComputerBlip = true
                elseif distance >= 25.0 and showingComputerBlip then
                    RemoveBlip(computerBlip)
                    computerBlip = nil
                    showingComputerBlip = false
                end

                if distance < 1.0 then
                    sleep = 0
                    DrawMarker(1, jewelryConfig.computerPos.x, jewelryConfig.computerPos.y, jewelryConfig.computerPos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.1, 0, 150, 255, 200, false, true, 2, false, nil, nil, false)
                    ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour pirater l'ordinateur")

                    if VFW.Interact.JustReleased(0, 38) and not hackingInProgress then -- E
                        StartComputerHack()
                    end
                end
            end

            if robberyInProgress and jewelryConfig.displayCases then
                for i, casePos in ipairs(jewelryConfig.displayCases) do
                    local distance = #(playerCoords - vector3(casePos.x, casePos.y, casePos.z))

                    if distance < 1.0 and not robbedCases[i] then
                        sleep = 0
                        ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour casser la vitrine")

                        if VFW.Interact.JustReleased(0, 38) then -- E
                            RobDisplayCase(i)
                        end
                    end
                end
            end

            Citizen.Wait(sleep)
        else
            Citizen.Wait(1000)
        end
    end
end)


RegisterNetEvent('onClientResourceStart')
AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Citizen.Wait(1000)
        TriggerServerEvent('core:jewelry:requestConfig')
        -- Charger l'état des vitrines cassées
        local globalRobbedCases = TriggerServerCallback("core:jewelry:getRobbedCases")
        if globalRobbedCases then
            robbedCases = globalRobbedCases
        end
        -- NOUVEAU: Charger l'état du braquage en cours
        local robberyState = TriggerServerCallback("core:jewelry:getRobberyState")
        if robberyState and robberyState.active then
            robberyInProgress = true
            robberyTimeLimit = robberyState.endTime
            ShowDisplayCaseBlips()
        end
    end
end)

AddEventHandler('playerSpawned', function()
    Citizen.Wait(2000)
    TriggerServerEvent('core:jewelry:requestConfig')
    -- Charger l'état des vitrines cassées
    local globalRobbedCases = TriggerServerCallback("core:jewelry:getRobbedCases")
    if globalRobbedCases then
        robbedCases = globalRobbedCases
    end
    -- NOUVEAU: Charger l'état du braquage en cours
    local robberyState = TriggerServerCallback("core:jewelry:getRobberyState")
    if robberyState and robberyState.active then
        robberyInProgress = true
        robberyTimeLimit = robberyState.endTime
        ShowDisplayCaseBlips()
    end
end)

Citizen.CreateThread(function()
    Wait(3000)
    CheckMapBlipStatus()
end)

-- Fonction de nettoyage commune pour fin de braquage
local function CleanupRobbery()
    robberyInProgress = false
    robberyTimeLimit = 0
    robbedCases = {}
    ClearDisplayCaseBlips()

    -- Nettoyer les props et libérer le joueur
    RemoveCurrentProp()
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
end

RegisterNetEvent('core:jewelry:robberyFinished', function()
    CleanupRobbery()
    -- Les vitrines seront restaurées par le serveur après un délai
end)

RegisterNetEvent('core:jewelry:robberyExpired', function()
    CleanupRobbery()
    VFW.ShowNotification({ type = "ILLEGAL", message = "Temps écoulé ! Le braquage est terminé" })
    -- Les vitrines seront restaurées par le serveur après un délai
end)

-- Event pour forcer la restauration des vitrines (admin ou fin de braquage)
RegisterNetEvent('core:jewelry:restoreVitrines', function()
    RestoreAllVitrines()
    VFW.ShowNotification({ type = "ILLEGAL", message = "Vitrines restaurées" })
end)

local policeBlipRadius = nil

RegisterNetEvent('core:jewelry:createPoliceBlip', function(coords)
    if policeBlip then
        RemoveBlip(policeBlip)
    end
    if policeBlipRadius then
        RemoveBlip(policeBlipRadius)
    end

    policeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(policeBlip, 161)
    SetBlipDisplay(policeBlip, 4)
    SetBlipScale(policeBlip, 0.5)
    SetBlipColour(policeBlip, 1)
    SetBlipAsShortRange(policeBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("10.41 - Braquage bijouterie")
    EndTextCommandSetBlipName(policeBlip)

    -- Ajouter un radius de 15m autour du blip
    policeBlipRadius = AddBlipForRadius(coords.x, coords.y, coords.z, 15.0)
    SetBlipHighDetail(policeBlipRadius, true)
    SetBlipColour(policeBlipRadius, 1)
    SetBlipAlpha(policeBlipRadius, 128)

    local blipDuration = tonumber(jewelrySettings.policeBlipDuration) or 600
    Citizen.CreateThread(function()
        Citizen.Wait(blipDuration * 1000)
        if policeBlip then
            RemoveBlip(policeBlip)
            policeBlip = nil
        end
        if policeBlipRadius then
            RemoveBlip(policeBlipRadius)
            policeBlipRadius = nil
        end
    end)
end)

function CheckMapBlipStatus()
    if not jewelrySettings or not jewelrySettings.mapBlipPosition or jewelrySettings.mapBlipPosition == "" then
        if jewelryMapBlip then
            RemoveBlip(jewelryMapBlip)
            jewelryMapBlip = nil
        end
        return
    end

    local pos = json.decode(jewelrySettings.mapBlipPosition)
    if pos and pos.x and pos.y and pos.z then
        if jewelryMapBlip then
            RemoveBlip(jewelryMapBlip)
        end

        jewelryMapBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipSprite(jewelryMapBlip, 617)
        SetBlipDisplay(jewelryMapBlip, 4)
        SetBlipScale(jewelryMapBlip, 0.5)
        SetBlipColour(jewelryMapBlip, 46)
        SetBlipAsShortRange(jewelryMapBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bijouterie")
        EndTextCommandSetBlipName(jewelryMapBlip)
    end
end

RegisterNetEvent('core:jewelry:setMapLocation', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    local position = {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }

    TriggerServerEvent('core:jewelry:updateSettings', 'mapBlipPosition', json.encode(position))
    VFW.ShowNotification({ type = "ILLEGAL", message = "Position bijouterie définie sur la carte" })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        -- Nettoyer les props et libérer le joueur
        RemoveCurrentProp()
        local playerPed = PlayerPedId()
        FreezeEntityPosition(playerPed, false)
        ClearPedTasks(playerPed)

        -- Nettoyer les blips
        ClearJewelryBlips()
        if policeBlip then
            RemoveBlip(policeBlip)
        end
        if policeBlipRadius then
            RemoveBlip(policeBlipRadius)
        end
        if jewelryMapBlip then
            RemoveBlip(jewelryMapBlip)
        end

        -- Restaurer les vitrines
        RestoreAllVitrines()
    end
end)

-- ============================================
-- COMMANDES ADMIN POUR CONFIGURATION PC
-- ============================================

