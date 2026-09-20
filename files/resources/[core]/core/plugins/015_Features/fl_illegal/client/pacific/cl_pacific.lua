---@meta _
---@diagnostic disable: duplicate-doc-field

local NUMPAD_POSITION = vector3(246.253937, 226.849716, 98.651047)
local ENTRY_DOOR_POSITION = vector3(245.76, 226.85, 98.58)
local COMPUTER_POSITION = vector3(239.46, 231.66, 98.44)
local VAULT_NUMPAD_POSITION = vector3(234.82, 221.36, 97.68)
local VAULT_DOOR_POSITION = vector3(236.47, 217.05, 97.76)
local EMERGENCY_EXIT_POSITION = vector3(234.68, 228.54, 97.68)
local OUTSIDE_POSITION = vector3(271.0, 234.0, 106.28) -- Proche du PC Sécurité (en haut de la banque)
local PACIFIC_BANK_BLIP_POSITION = vector3(249.06, 222.89, 105.30) -- Position du blip banque sur la carte

-- Sortie de secours dans le coffre-fort (pour joueurs coincés hors braquage)
local VAULT_EMERGENCY_EXIT_POSITION = vector3(234.14, 217.07, 96.16) -- Dans le coffre
local VAULT_OUTSIDE_POSITION = vector3(271.0, 234.0, 106.28) -- Sortie extérieure (même que l'autre sortie)
local GOLD_CART_POSITION = vector3(225.83, 220.27, 97.15)
local GOLD_CART_HEADING = 91.49

-- ============================================
-- CONFIGURATION PC SECURITE
-- ============================================
local SECURITY_PC_CONFIG = {
    x = 263.60,
    y = 229.85,
    z = 106.36,
    heading = 285.44,
    emoteName = "type"  -- Emote de pianotage sur clavier
}

-- ============================================
-- CONFIGURATION ORDINATEUR CENTRAL
-- ============================================
local COMPUTER_CONFIG = {
    x = 239.72,
    y = 230.68,
    z = 98.44,
    heading = 115.0,
    emoteName = "type"  -- Emote pianotage clavier (comme PC Sécurité)
}

-- ============================================
-- CONFIGURATION COFFRE-FORT (VAULT)
-- ============================================
local VAULT_CONFIG = {
    x = 234.50,
    y = 220.80,
    z = 97.68,
    heading = 115.0,
    emoteName = "tablet"  -- Emote tablette
}

-- ============================================
-- CONFIGURATION NUMPAD D'ENTREE (TERMINAL)
-- ============================================
local ENTRY_NUMPAD_CONFIG = {
    x = 246.25,
    y = 226.20,
    z = 98.65,
    heading = 20.0,  -- Face au terminal
    emoteName = "tablet"  -- Emote tablette
}

local DOOR_1_POSITION = vector3(276.460388, 234.65506, 98.619179)
local DOOR_1_HEADING = 296.43

-- Configuration des petits coffres avec position de TP et heading
local SMALL_SAFES = {
    { pos = vector3(250.54, 233.25, 98.46), tpPos = vector3(250.54, 233.25, 98.46), heading = 114.0 },    -- 1 (H 114)
    { pos = vector3(248.20, 237.84, 98.46), tpPos = vector3(248.20, 237.84, 98.46), heading = 114.0 },    -- 2 (H 114)
    { pos = vector3(248.85, 240.53, 98.46), tpPos = vector3(248.85, 240.53, 98.46), heading = 24.0 },     -- 3 (H 24)
    { pos = vector3(251.45, 239.32, 98.46), tpPos = vector3(251.45, 239.32, 98.46), heading = 291.0 },    -- 4 (H 291)
    { pos = vector3(253.60, 234.67, 98.46), tpPos = vector3(253.60, 234.67, 98.46), heading = 291.0 },    -- 5 (H 291)
    { pos = vector3(260.81, 219.08, 98.46), tpPos = vector3(260.81, 219.08, 98.46), heading = 291.0 },    -- 6 (H 291)
    { pos = vector3(257.68, 217.70, 98.46), tpPos = vector3(257.68, 217.70, 98.46), heading = 114.0 },    -- 7 (H 114)
    { pos = vector3(263.17, 213.72, 98.46), tpPos = vector3(263.17, 213.72, 98.46), heading = 291.0 },    -- 8 (H 291)
    { pos = vector3(259.74, 212.57, 98.46), tpPos = vector3(259.74, 212.57, 98.46), heading = 114.0 },    -- 9 (H 114)
    { pos = vector3(262.02, 211.69, 98.46), tpPos = vector3(262.02, 211.69, 98.46), heading = 114.0 },    -- 10 (H 114)
    { pos = vector3(266.03, 240.16, 98.47), tpPos = vector3(266.03, 240.16, 98.47), heading = 114.0 },    -- 11 (H 114)
    { pos = vector3(269.10, 241.51, 98.47), tpPos = vector3(269.10, 241.51, 98.47), heading = 291.0 },    -- 12 (H 291)
    { pos = vector3(263.54, 245.37, 98.47), tpPos = vector3(263.54, 245.37, 98.47), heading = 114.0 },    -- 13 (H 114)
    { pos = vector3(266.95, 246.36, 98.47), tpPos = vector3(266.95, 246.36, 98.47), heading = 291.0 },    -- 14 (H 291)
    { pos = vector3(264.52, 247.48, 98.47), tpPos = vector3(264.52, 247.48, 98.47), heading = 24.0 },     -- 15 (H 24)
    { pos = vector3(275.91, 225.86, 98.47), tpPos = vector3(275.91, 225.86, 98.47), heading = 291.0 },    -- 16 (H 291)
    { pos = vector3(272.67, 224.38, 98.47), tpPos = vector3(272.67, 224.38, 98.47), heading = 114.0 },    -- 17 (H 114)
    { pos = vector3(278.02, 220.87, 98.47), tpPos = vector3(278.02, 220.87, 98.47), heading = 291.0 },    -- 18 (H 291)
    { pos = vector3(274.76, 219.75, 98.47), tpPos = vector3(274.76, 219.75, 98.47), heading = 114.0 },    -- 19 (H 114)
    { pos = vector3(277.25, 218.49, 98.47), tpPos = vector3(277.25, 218.49, 98.47), heading = 24.0 }      -- 20 (H 24)
}

-- Configuration des grands coffres avec position de TP et heading (face au mur circulaire du vault)
-- Le heading pointe VERS le coffre (joueur dos au centre du vault ~226, 215)
local BIG_SAFES = {
    { pos = vector3(230.68, 203.24, 97.15), tpPos = vector3(230.68, 203.24, 97.15), heading = 200.0 },  -- Coffre 1: Sud-Est
    { pos = vector3(226.18, 205.81, 97.15), tpPos = vector3(226.18, 205.81, 97.15), heading = 180.0 },  -- Coffre 2: Sud
    { pos = vector3(222.87, 209.67, 97.15), tpPos = vector3(222.87, 209.67, 97.15), heading = 150.0 },  -- Coffre 3: Sud-Ouest
    { pos = vector3(220.82, 216.52, 97.15), tpPos = vector3(220.82, 216.52, 97.15), heading = 110.0 },  -- Coffre 4: Ouest
    { pos = vector3(220.70, 222.01, 97.15), tpPos = vector3(220.70, 222.01, 97.15), heading = 70.0 },   -- Coffre 5: Nord-Ouest
    { pos = vector3(221.36, 224.18, 97.15), tpPos = vector3(221.36, 224.18, 97.15), heading = 50.0 }    -- Coffre 6: Nord-Ouest
}

local PACIFIC_DOORS = {
    {
        hash = GetHashKey("molo_pacificabanks_props_door4"),
        coords = vector3(245.76, 226.85, 98.58),
        id = 1
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door5"),
        coords = vector3(261.30, 215.35, 101.68),
        id = 2
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door2"),
        coords = vector3(252.98, 229.93, 98.61),
        id = 3
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door2"),
        coords = vector3(256.99, 221.82, 98.61),
        id = 4
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door2"),
        coords = vector3(268.55, 236.84, 98.61),
        id = 5
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door2"),
        coords = vector3(272.02, 228.49, 98.61),
        id = 6
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door5"),
        coords = vector3(238.22, 235.91, 98.54),
        id = 7
    },
    {
        hash = GetHashKey("molo_pacificabanks_props_door5"),
        coords = vector3(240.24, 236.81, 98.54),
        id = 8
    },
    -- Porte 1 (PC Sécurité) - Hash trouvé via /pacific:scan
    {
        hash = 1690019057,
        coords = vector3(276.46, 234.66, 98.62),
        id = 9
    }
}

local isEnteringCode = false
local isDrillingSafe = false
local lastInteractionAttempt = 0
local isEntryDoorUnlocked = false
local isComputerHacked = false
local isVaultDoorOpen = false
local isDoor1Unlocked = false
local isHackingSecurityPC = false
local isHackingComputer = false
local isHackingVault = false
local isCollectingGold = false
local goldCartLooted = false

local robberyBlip = nil
local bankBlip = nil  -- Blip permanent de la banque sur la carte
local drilledSmallSafesClient = {}
local drilledBigSafesClient = {}
local activeDrillingsClient = {} -- Track des perçages en cours par d'autres joueurs: activeDrillingsClient["small_1"] = playerId

-- Variable pour savoir si ce joueur est l'auteur du braquage
local isRobberyAuthor = false

-- Forward declarations pour le tutoriel
local StartPacificTutorial
local StopPacificTutorial

local PacificSettings = {
    InteractDistance = 2.0,
    SafeInteractDistance = 1.5,
    PoliceBlipDuration = 480000,
    Safe = {
        DrillTime = 30
    }
}

-- Types de hack disponibles pour le menu aléatoire
local HACK_TYPES = { 'firewall', 'memory', 'numbers', 'word', 'circuit', 'terminal' }
local isHackingEntryDoor = false

-- Timer unique pour le braquage
local robberyTimer = {
    active = false,
    endTime = 0
}

-- Timer pour garder les portes ouvertes (1 heure après le début du braquage)
local doorOpenTimer = {
    active = false,
    endTime = 0
}
local DOOR_OPEN_DURATION = 60 -- 60 minutes (1 heure)

-- ============================================
-- POSITIONS CONFIGURABLES (Builder Staff)
-- Toutes les positions déclarées ci-dessus sont des DÉFAUTS. Elles sont écrasées
-- par la configuration enregistrée via le Builder (event core:pacific:syncPositions).
-- Tant qu'aucune position n'est configurée, le braquage se comporte à l'identique.
-- ============================================
local function PacificVec3(p)
    return vector3((p.x or 0.0) + 0.0, (p.y or 0.0) + 0.0, (p.z or 0.0) + 0.0)
end

local function ApplyPacificPositions(cfg)
    if type(cfg) ~= "table" then return end

    -- Écrase les champs d'une config d'interaction ({x,y,z,heading}) en place
    local function applyInteraction(target, p)
        if type(p) ~= "table" then return end
        if p.x then target.x = p.x + 0.0 end
        if p.y then target.y = p.y + 0.0 end
        if p.z then target.z = p.z + 0.0 end
        if p.heading then target.heading = p.heading + 0.0 end
    end

    -- Positions d'interaction (téléport + emote)
    applyInteraction(SECURITY_PC_CONFIG, cfg.securityPC)
    applyInteraction(COMPUTER_CONFIG, cfg.computer)
    applyInteraction(VAULT_CONFIG, cfg.vault)
    applyInteraction(ENTRY_NUMPAD_CONFIG, cfg.entryNumpad)

    -- Positions vector3 + headings dédiés
    if type(cfg.door1) == "table" and cfg.door1.x then
        DOOR_1_POSITION = PacificVec3(cfg.door1)
        if cfg.door1.heading then DOOR_1_HEADING = cfg.door1.heading + 0.0 end
    end
    if type(cfg.goldCart) == "table" and cfg.goldCart.x then
        GOLD_CART_POSITION = PacificVec3(cfg.goldCart)
        if cfg.goldCart.heading then GOLD_CART_HEADING = cfg.goldCart.heading + 0.0 end
    end
    if type(cfg.blip) == "table" and cfg.blip.x then PACIFIC_BANK_BLIP_POSITION = PacificVec3(cfg.blip) end
    if type(cfg.numpadMarker) == "table" and cfg.numpadMarker.x then NUMPAD_POSITION = PacificVec3(cfg.numpadMarker) end
    if type(cfg.computerMarker) == "table" and cfg.computerMarker.x then COMPUTER_POSITION = PacificVec3(cfg.computerMarker) end
    if type(cfg.vaultNumpadMarker) == "table" and cfg.vaultNumpadMarker.x then VAULT_NUMPAD_POSITION = PacificVec3(cfg.vaultNumpadMarker) end
    if type(cfg.vaultDoorMarker) == "table" and cfg.vaultDoorMarker.x then VAULT_DOOR_POSITION = PacificVec3(cfg.vaultDoorMarker) end
    if type(cfg.entryDoorMarker) == "table" and cfg.entryDoorMarker.x then ENTRY_DOOR_POSITION = PacificVec3(cfg.entryDoorMarker) end

    -- Petits coffres (liste dynamique)
    if type(cfg.smallSafes) == "table" and #cfg.smallSafes > 0 then
        local t = {}
        for i, s in ipairs(cfg.smallSafes) do
            local v = PacificVec3(s)
            t[i] = { pos = v, tpPos = v, heading = (s.heading or 0.0) + 0.0 }
        end
        SMALL_SAFES = t
    end

    -- Grands coffres (liste dynamique)
    if type(cfg.bigSafes) == "table" and #cfg.bigSafes > 0 then
        local t = {}
        for i, s in ipairs(cfg.bigSafes) do
            local v = PacificVec3(s)
            t[i] = { pos = v, tpPos = v, heading = (s.heading or 0.0) + 0.0 }
        end
        BIG_SAFES = t
    end

    -- Portes sécurisées : on n'écrase que les coordonnées, en conservant le
    -- hash (modèle de porte) et l'id (utilisé par la logique DoorSystem).
    if type(cfg.doors) == "table" then
        for k, d in pairs(cfg.doors) do
            local idx = tonumber(k)
            if idx and PACIFIC_DOORS[idx] and type(d) == "table" and d.x then
                PACIFIC_DOORS[idx] = {
                    hash = PACIFIC_DOORS[idx].hash,
                    coords = PacificVec3(d),
                    id = PACIFIC_DOORS[idx].id
                }
            end
        end
    end
end

-- Fonction pour formater le temps restant
local function FormatTimeRemaining(seconds)
    if seconds <= 0 then return "00:00" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- Fonction pour démarrer le timer de braquage
local function StartRobberyTimer(durationMinutes)
    robberyTimer.active = true
    robberyTimer.endTime = GetGameTimer() + (durationMinutes * 60 * 1000)
end

-- Fonction pour arrêter le timer de braquage
local function StopRobberyTimer()
    robberyTimer.active = false
end

-- Fonction pour démarrer le timer des portes (1h)
local function StartDoorOpenTimer()
    doorOpenTimer.active = true
    doorOpenTimer.endTime = GetGameTimer() + (DOOR_OPEN_DURATION * 60 * 1000)
end

-- Fonction pour arrêter le timer des portes et les fermer
local function StopDoorOpenTimer()
    if doorOpenTimer.active then
        doorOpenTimer.active = false
        -- Fermer toutes les portes
        isDoor1Unlocked = false
        isEntryDoorUnlocked = false
        isComputerHacked = false
        isVaultDoorOpen = false
        -- Fermer la porte 1 (door system)
        DoorSystemSetDoorState(9, 1, false, false)
    end
end

-- Thread pour surveiller le timer des portes (1h)
CreateThread(function()
    while true do
        if doorOpenTimer.active then
            if GetGameTimer() >= doorOpenTimer.endTime then
                StopDoorOpenTimer()
            end
        end
        Wait(10000) -- Vérifier toutes les 10 secondes
    end
end)

-- Thread pour surveiller le timer du braquage (sans affichage)
CreateThread(function()
    while true do
        if robberyTimer.active then
            local remaining = math.max(0, (robberyTimer.endTime - GetGameTimer()) / 1000)

            if remaining <= 0 then
                robberyTimer.active = false
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    title = "BRAQUAGE TERMINE",
                    message = "Le temps est ecoule !"
                })
            end
        end

        Wait(1000)
    end
end)

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

local function UnlockEntryDoor()
    DoorSystemSetDoorState(1, 0, false, false)
    isEntryDoorUnlocked = true
    TriggerServerEvent("core:pacific:unlockEntryDoor")
    -- Notification envoyée par le serveur (évite les doublons)
end

-- ============================================
-- PORTE 1 (PC SECURITE) - ID = 9
-- ============================================

-- Fonction pour déverrouiller la Porte 1 via le PC Sécurité
local function UnlockDoor1()
    isDoor1Unlocked = true
    DoorSystemSetDoorState(9, 0, false, false) -- 0 = unlocked
    TriggerServerEvent("core:pacific:unlockDoor1")
    -- Notification envoyée par le serveur (évite les doublons)

    -- Marquer ce joueur comme auteur du braquage (pour les blips personnels)
    isRobberyAuthor = true

    -- Démarrer le timer des portes (1h)
    StartDoorOpenTimer()

    -- Démarrer le tutoriel après le hack du PC Sécurité
    SetTimeout(1000, function()
        StartPacificTutorial()
    end)
end

-- Fonction pour verrouiller la Porte 1
local function LockDoor1Client()
    isDoor1Unlocked = false
    DoorSystemSetDoorState(9, 1, false, false) -- 1 = locked
end

-- Event pour synchroniser l'état de la Porte 1
RegisterNetEvent("core:pacific:syncDoor1Unlock")
AddEventHandler("core:pacific:syncDoor1Unlock", function()
    isDoor1Unlocked = true
    DoorSystemSetDoorState(9, 0, false, false)
end)

RegisterNetEvent("core:pacific:syncDoor1Lock")
AddEventHandler("core:pacific:syncDoor1Lock", function()
    isDoor1Unlocked = false
    DoorSystemSetDoorState(9, 1, false, false)
end)

local function UnlockSafesDoor()
    DoorSystemSetDoorState(3, 0, false, false)
    DoorSystemSetDoorState(4, 0, false, false)
    DoorSystemSetDoorState(5, 0, false, false)
    DoorSystemSetDoorState(6, 0, false, false)
    isComputerHacked = true
    TriggerServerEvent("core:pacific:unlockComputer")
    -- Notification envoyée par le serveur (évite les doublons)

    -- Compléter l'étape du tutoriel
    if VFW.Tutorial.IsWaitingFor("pacific_hack_computer") then
        VFW.Tutorial.Complete("pacific_hack_computer")
    end
end

RegisterNetEvent("core:pacific:syncEntryDoor")
AddEventHandler("core:pacific:syncEntryDoor", function()
    DoorSystemSetDoorState(1, 0, false, false)
    isEntryDoorUnlocked = true
end)

RegisterNetEvent("core:pacific:syncComputer")
AddEventHandler("core:pacific:syncComputer", function()
    DoorSystemSetDoorState(3, 0, false, false)
    DoorSystemSetDoorState(4, 0, false, false)
    DoorSystemSetDoorState(5, 0, false, false)
    DoorSystemSetDoorState(6, 0, false, false)
    isComputerHacked = true
end)

-- Events pour le timer de braquage global
RegisterNetEvent("core:pacific:startRobberyTimer")
AddEventHandler("core:pacific:startRobberyTimer", function(duration)
    StartRobberyTimer(duration or 15)
end)

RegisterNetEvent("core:pacific:stopRobberyTimer")
AddEventHandler("core:pacific:stopRobberyTimer", function()
    StopRobberyTimer()

    -- Reset des états du braquage
    isEntryDoorUnlocked = false
    isComputerHacked = false
    isVaultDoorOpen = false
    isDoor1Unlocked = false
    isRobberyAuthor = false
    securityPCHackCompleted = false
    isHackingSecurityPC = false
    isEnteringCode = false
    isHackingEntryDoor = false
    isHackingComputer = false
    isHackingVault = false
    drilledSmallSafesClient = {}
    drilledBigSafesClient = {}
    goldCartLooted = false

    -- Arrêter le tutoriel si actif
    StopPacificTutorial()

    -- Verrouiller toutes les portes
    TriggerEvent("core:pacific:lockDoors")
end)

-- Variables pour le système PC Sécurité
local isAtSecurityPC = false
local savedPCPosition = nil
local savedPCHeading = nil

-- Variables pour le système Ordinateur Central
local isAtComputer = false
local savedComputerPosition = nil
local savedComputerHeading = nil

-- Variables pour le système Coffre-fort
local isAtVault = false
local savedVaultPosition = nil
local savedVaultHeading = nil

-- Variables pour le système Numpad d'entrée
local isAtEntryNumpad = false
local savedEntryNumpadPosition = nil
local savedEntryNumpadHeading = nil

-- Variables pour le système de perçage de coffres
local isAtDrillingSafe = false
local savedDrillingPosition = nil
local savedDrillingHeading = nil
local currentDrillingSafeConfig = nil

-- ============================================
-- SYSTÈME PC SÉCURITÉ AVEC EMOTE
-- TP + Emote "type" + Menu code + Hack
-- ============================================

--- Téléporte le joueur au PC et lance l'emote de typing
--- @param callback function Fonction appelée une fois en position avec l'emote
local function StartSecurityPCInteraction(callback)
    local ped = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedPCPosition = GetEntityCoords(ped)
    savedPCHeading = GetEntityHeading(ped)


    -- 1. Freeze le joueur + Fade out (400ms)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords exactes du PC
    SetEntityCoordsNoOffset(ped, SECURITY_PC_CONFIG.x, SECURITY_PC_CONFIG.y, SECURITY_PC_CONFIG.z, false, false, false)

    -- 4. SetEntityHeading (face au PC)
    SetEntityHeading(ped, SECURITY_PC_CONFIG.heading)

    Wait(100)

    -- 5. Lancer l'emote "type" via le système d'emotes du serveur
    EmoteCommandStart(SECURITY_PC_CONFIG.emoteName, ped, nil)

    -- 6. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 7. Marquer comme actif (le joueur peut bouger avec l'emote mais reste en interaction)
    isAtSecurityPC = true


    -- 8. Appeler le callback une fois prêt
    if callback then
        callback()
    end
end

--- Arrête l'interaction PC Sécurité et retourne à la position initiale
--- @param callback function Fonction appelée une fois terminé
local function StopSecurityPCInteraction(callback)
    local ped = PlayerPedId()


    -- Marquer comme inactif immédiatement
    isAtSecurityPC = false

    -- Fermer le menu NUI si encore ouvert
    SendNUIMessage({
        action = "nui:pacific:closeCodeInput"
    })
    VFW.Nui.Focus(false)

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
    isEnteringCode = false
    isHackingSecurityPC = false
    savedPCPosition = nil
    savedPCHeading = nil


    -- 7. Appeler le callback une fois terminé
    if callback then
        callback()
    end
end

--- Quitte complètement le PC + ferme le NUI + libère le serveur
local function ExitSecurityPCCompletely()
    -- Fermer le menu NUI si ouvert
    SendNUIMessage({
        action = "nui:pacific:closeCodeInput"
    })
    VFW.Nui.Focus(false)

    if isEnteringCode then
        isEnteringCode = false
        TriggerServerCallback("core:pacific:releaseNumpad", "securityPC")
    end

    -- Libérer le PC Sécurité côté serveur
    TriggerServerCallback("core:pacific:releaseSecurityPC")

    -- Quitter l'interaction
    StopSecurityPCInteraction()
end

-- Thread pour détecter la touche Backspace quand au PC
CreateThread(function()
    while true do
        local wait = 500

        if isAtSecurityPC and not isHackingSecurityPC then
            wait = 0
            -- Backspace (177) pour quitter (seulement si pas en train de hacker)
            if IsControlJustPressed(0, 177) then
                ExitSecurityPCCompletely()
            end
        end

        Wait(wait)
    end
end)

-- ============================================
-- COMMANDE DEBUG POUR TESTER LE PC
-- ============================================


-- ============================================
-- SYSTÈME ORDINATEUR CENTRAL AVEC EMOTE
-- TP + Emote "tablet" + Hack
-- ============================================

--- Téléporte le joueur à l'ordinateur et lance l'emote tablet
--- @param callback function Fonction appelée une fois en position avec l'emote
local function StartComputerInteraction(callback)
    local ped = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedComputerPosition = GetEntityCoords(ped)
    savedComputerHeading = GetEntityHeading(ped)


    -- 1. Freeze le joueur + Fade out (400ms)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords exactes de l'ordinateur
    SetEntityCoordsNoOffset(ped, COMPUTER_CONFIG.x, COMPUTER_CONFIG.y, COMPUTER_CONFIG.z, false, false, false)

    -- 4. SetEntityHeading (face à l'ordinateur)
    SetEntityHeading(ped, COMPUTER_CONFIG.heading)

    Wait(100)

    -- 5. Lancer l'emote "tablet" via le système d'emotes du serveur
    EmoteCommandStart(COMPUTER_CONFIG.emoteName, ped, nil)

    -- 6. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 7. Marquer comme actif
    isAtComputer = true


    -- 8. Appeler le callback une fois prêt
    if callback then
        callback()
    end
end

--- Arrête l'interaction Ordinateur et retourne à la position initiale
--- @param callback function Fonction appelée une fois terminé
local function StopComputerInteraction(callback)
    local ped = PlayerPedId()


    -- Marquer comme inactif immédiatement
    isAtComputer = false

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Annuler l'emote en cours
    EmoteCancel()
    ClearPedTasks(ped)

    -- 3. Retour à la position sauvegardée
    if savedComputerPosition then
        SetEntityCoordsNoOffset(ped, savedComputerPosition.x, savedComputerPosition.y, savedComputerPosition.z, false, false, false)
        if savedComputerHeading then
            SetEntityHeading(ped, savedComputerHeading)
        end
    end

    -- 4. S'assurer que le joueur peut bouger
    FreezeEntityPosition(ped, false)

    -- 5. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 6. Réinitialiser les variables
    isHackingComputer = false
    savedComputerPosition = nil
    savedComputerHeading = nil


    -- 7. Appeler le callback une fois terminé
    if callback then
        callback()
    end
end

-- ============================================
-- SYSTÈME COFFRE-FORT AVEC EMOTE
-- TP + Emote "tablet" + Hack
-- ============================================

--- Téléporte le joueur au coffre-fort et lance l'emote tablet
--- @param callback function Fonction appelée une fois en position avec l'emote
local function StartVaultInteraction(callback)
    local ped = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedVaultPosition = GetEntityCoords(ped)
    savedVaultHeading = GetEntityHeading(ped)


    -- 1. Freeze le joueur + Fade out (400ms)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords exactes du coffre-fort
    SetEntityCoordsNoOffset(ped, VAULT_CONFIG.x, VAULT_CONFIG.y, VAULT_CONFIG.z, false, false, false)

    -- 4. SetEntityHeading (face au numpad)
    SetEntityHeading(ped, VAULT_CONFIG.heading)

    Wait(100)

    -- 5. Lancer l'emote "tablet" via le système d'emotes du serveur
    EmoteCommandStart(VAULT_CONFIG.emoteName, ped, nil)

    -- 6. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 7. Marquer comme actif
    isAtVault = true


    -- 8. Appeler le callback une fois prêt
    if callback then
        callback()
    end
end

--- Arrête l'interaction Coffre-fort et retourne à la position initiale
--- @param callback function Fonction appelée une fois terminé
local function StopVaultInteraction(callback)
    local ped = PlayerPedId()


    -- Marquer comme inactif immédiatement
    isAtVault = false

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Annuler l'emote en cours
    EmoteCancel()
    ClearPedTasks(ped)

    -- 3. Retour à la position sauvegardée
    if savedVaultPosition then
        SetEntityCoordsNoOffset(ped, savedVaultPosition.x, savedVaultPosition.y, savedVaultPosition.z, false, false, false)
        if savedVaultHeading then
            SetEntityHeading(ped, savedVaultHeading)
        end
    end

    -- 4. S'assurer que le joueur peut bouger
    FreezeEntityPosition(ped, false)

    -- 5. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 6. Réinitialiser les variables
    isHackingVault = false
    savedVaultPosition = nil
    savedVaultHeading = nil


    -- 7. Appeler le callback une fois terminé
    if callback then
        callback()
    end
end

-- ============================================
-- SYSTÈME NUMPAD D'ENTREE AVEC EMOTE
-- TP + Emote "tablet" + Hack
-- ============================================

--- Téléporte le joueur au numpad d'entrée et lance l'emote tablet
--- @param callback function Fonction appelée une fois en position avec l'emote
local function StartEntryNumpadInteraction(callback)
    local ped = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedEntryNumpadPosition = GetEntityCoords(ped)
    savedEntryNumpadHeading = GetEntityHeading(ped)


    -- 1. Freeze le joueur + Fade out (400ms)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords exactes du numpad
    SetEntityCoordsNoOffset(ped, ENTRY_NUMPAD_CONFIG.x, ENTRY_NUMPAD_CONFIG.y, ENTRY_NUMPAD_CONFIG.z, false, false, false)

    -- 4. SetEntityHeading (face au terminal)
    SetEntityHeading(ped, ENTRY_NUMPAD_CONFIG.heading)

    Wait(100)

    -- 5. Lancer l'emote "tablet" via le système d'emotes du serveur
    EmoteCommandStart(ENTRY_NUMPAD_CONFIG.emoteName, ped, nil)

    -- 6. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 7. Marquer comme actif
    isAtEntryNumpad = true


    -- 8. Appeler le callback une fois prêt
    if callback then
        callback()
    end
end

--- Arrête l'interaction Numpad d'entrée et retourne à la position initiale
--- @param callback function Fonction appelée une fois terminé
local function StopEntryNumpadInteraction(callback)
    local ped = PlayerPedId()


    -- Marquer comme inactif immédiatement
    isAtEntryNumpad = false

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Annuler l'emote en cours
    EmoteCancel()
    ClearPedTasks(ped)

    -- 3. Retour à la position sauvegardée
    if savedEntryNumpadPosition then
        SetEntityCoordsNoOffset(ped, savedEntryNumpadPosition.x, savedEntryNumpadPosition.y, savedEntryNumpadPosition.z, false, false, false)
        if savedEntryNumpadHeading then
            SetEntityHeading(ped, savedEntryNumpadHeading)
        end
    end

    -- 4. S'assurer que le joueur peut bouger
    FreezeEntityPosition(ped, false)

    -- 5. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 6. Réinitialiser les variables
    isHackingEntryDoor = false
    savedEntryNumpadPosition = nil
    savedEntryNumpadHeading = nil


    -- 7. Appeler le callback une fois terminé
    if callback then
        callback()
    end
end

-- ============================================
-- SYSTÈME PERÇAGE DE COFFRES AVEC TP
-- TP + Animation perceuse
-- ============================================

--- Téléporte le joueur devant le coffre pour le perçage
--- @param safeConfig table Configuration du coffre (pos, tpPos, heading)
--- @param callback function Fonction appelée une fois en position
local function StartDrillingInteraction(safeConfig, callback)
    local ped = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedDrillingPosition = GetEntityCoords(ped)
    savedDrillingHeading = GetEntityHeading(ped)
    currentDrillingSafeConfig = safeConfig


    -- 1. Freeze le joueur + Fade out (400ms)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear toutes les tasks du ped
    ClearPedTasksImmediately(ped)

    -- 3. TP aux coords de perçage
    SetEntityCoordsNoOffset(ped, safeConfig.tpPos.x, safeConfig.tpPos.y, safeConfig.tpPos.z, false, false, false)

    -- 4. SetEntityHeading (face au coffre)
    SetEntityHeading(ped, safeConfig.heading)

    Wait(100)

    -- 5. Fade in
    DoScreenFadeIn(400)

    -- 6. Marquer comme actif
    isAtDrillingSafe = true


    -- 7. Appeler le callback une fois prêt
    if callback then
        callback()
    end
end

--- Arrête l'interaction de perçage et retourne à la position initiale
--- @param callback function Fonction appelée une fois terminé
local function StopDrillingInteraction(callback)
    local ped = PlayerPedId()


    -- Marquer comme inactif immédiatement
    isAtDrillingSafe = false

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. Clear tasks
    ClearPedTasks(ped)

    -- 3. Retour à la position sauvegardée
    if savedDrillingPosition then
        SetEntityCoordsNoOffset(ped, savedDrillingPosition.x, savedDrillingPosition.y, savedDrillingPosition.z, false, false, false)
        if savedDrillingHeading then
            SetEntityHeading(ped, savedDrillingHeading)
        end
    end

    -- 4. S'assurer que le joueur peut bouger
    FreezeEntityPosition(ped, false)

    -- 5. Fade in
    Wait(100)
    DoScreenFadeIn(400)

    -- 6. Réinitialiser les variables
    savedDrillingPosition = nil
    savedDrillingHeading = nil
    currentDrillingSafeConfig = nil


    -- 7. Appeler le callback une fois terminé
    if callback then
        callback()
    end
end

local securityPCHackCompleted = false  -- Flag pour empêcher le menu de réapparaître après hack réussi

local function StartBankCodeInput(codeType)
    if isEnteringCode then return end

    -- Pour le PC Sécurité, vérifier qu'on est toujours au PC
    if codeType == "securityPC" and not isAtSecurityPC then
        return
    end

    -- Si le hack du PC Sécurité a déjà été complété avec succès, ne pas rouvrir le menu
    if codeType == "securityPC" and securityPCHackCompleted then
        return
    end

    local canUse, reason = TriggerServerCallback("core:pacific:canUseNumpad", codeType)
    if not canUse then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Terminal déjà utilisé"
        })
        return
    end

    isEnteringCode = true

    -- Pour le PC Sécurité, l'emote "type" reste active automatiquement via EmoteCommandStart

    SendNUIMessage({
        action = "nui:pacific:openCodeInput",
        data = codeType
    })
    VFW.Nui.Focus(true)
end


RegisterNUICallback("submitCode", function(data, cb)
    isEnteringCode = false
    VFW.Nui.Focus(false)
    cb({ success = true })

    -- Fermer visuellement le menu NUI (SetNuiFocus ne cache pas l'UI)
    SendNUIMessage({
        action = "nui:pacific:closeCodeInput"
    })

    local codeType = data.codeType or "vault"
    local code = data.code

    if not code then
        TriggerServerCallback("core:pacific:releaseNumpad", codeType)
        -- Si on annule sur le PC Sécurité, se relever et libérer le PC
        if codeType == "securityPC" then
            TriggerServerCallback("core:pacific:releaseSecurityPC")
            StopSecurityPCInteraction()
        end
        return
    end

    local success = TriggerServerCallback("core:pacific:verifyCode", code)

    if success then
        -- Pour le PC Sécurité, on lance le hack pendant que le joueur reste assis
        if codeType == "securityPC" then
            -- Flag pour empêcher Backspace de quitter pendant le hack
            isHackingSecurityPC = true

            -- 3 hacks firewall enchaînés pour le PC Sécurité
            local totalHacks = 3
            local currentHack = 0

            local function DoNextSecurityPCHack()
                currentHack = currentHack + 1

                if currentHack > totalHacks then
                    -- Tous les hacks terminés avec succès
                    isHackingSecurityPC = false
                    TriggerServerCallback("core:pacific:releaseNumpad", codeType)

                    StopSecurityPCInteraction(function()
                        securityPCHackCompleted = true
                        UnlockDoor1()
                    end)
                    return
                end

                -- Notification de progression
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Firewall " .. currentHack .. "/" .. totalHacks
                })

                exports['core']:StartHacking('firewall', 'hard', 30, function(hackSuccess)
                    if hackSuccess then
                        -- Hack réussi, passer au suivant après une courte pause
                        Wait(500)
                        DoNextSecurityPCHack()
                    else
                        -- Échec : tout arrêter
                        isHackingSecurityPC = false
                        TriggerServerCallback("core:pacific:releaseNumpad", codeType)

                        StopSecurityPCInteraction(function()
                            TriggerServerCallback("core:pacific:releaseSecurityPC")
                            VFW.ShowNotification({
                                type = 'ILLEGAL',
                                message = "Piratage échoué au firewall " .. currentHack .. "/" .. totalHacks .. " !"
                            })
                        end)
                    end
                end)
            end

            -- Démarrer la chaîne de hacks
            DoNextSecurityPCHack()
        else
            -- Pour les autres types, comportement normal (pas d'assise)
            exports['core']:StartHacking('firewall', 'hard', 30, function(hackSuccess)
                TriggerServerCallback("core:pacific:releaseNumpad", codeType)

                if hackSuccess then
                    if codeType == "entry" then
                        UnlockEntryDoor()
                    elseif codeType == "computer" then
                        UnlockSafesDoor()
                    elseif codeType == "vault" then
                        TriggerServerEvent("core:pacific:openVault")
                        isVaultDoorOpen = true
                        -- Compléter l'étape du tutoriel
                        if VFW.Tutorial.IsWaitingFor("pacific_hack_vault") then
                            VFW.Tutorial.Complete("pacific_hack_vault")
                        end
                    end
                else
                    VFW.ShowNotification({
                        type = 'ILLEGAL',
                        message = "Hacking échoué !"
                    })
                end
            end)
        end
    else
        TriggerServerCallback("core:pacific:releaseNumpad", codeType)
        -- Si code incorrect sur PC Sécurité, se relever et libérer le PC
        if codeType == "securityPC" then
            TriggerServerCallback("core:pacific:releaseSecurityPC")
            StopSecurityPCInteraction()
        end
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Code incorrect !"
        })
    end
end)

RegisterNUICallback("closeCodeInput", function(data, cb)
    isEnteringCode = false
    VFW.Nui.Focus(false)
    cb({ success = true })

    -- Fermer visuellement le menu NUI (SetNuiFocus ne cache pas l'UI)
    SendNUIMessage({
        action = "nui:pacific:closeCodeInput"
    })

    local codeType = data.codeType or "entry"
    TriggerServerCallback("core:pacific:releaseNumpad", codeType)

    -- Si on ferme le code input sur le PC Sécurité, se relever et libérer le PC
    if codeType == "securityPC" then
        TriggerServerCallback("core:pacific:releaseSecurityPC")
        StopSecurityPCInteraction()
    end
end)

-- ============================================
-- MENU BANCAIRE (CIVILS)
-- ============================================

local function OpenBankingMenu()
    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "TODO: Ouvrir le menu bancaire"
    })
end

-- ============================================
-- COLLECTE LINGOTS D'OR
-- ============================================

-- Table de correspondance : item inventaire -> prop 3D
local BAG_ITEM_TO_PROP = {
    ["heist_bag"]   = "hei_p_m_bag_var22_arm_s",  -- Sac de braquage (défaut)
    ["lootbag"]     = "prop_cs_heist_bag_02",     -- Sac heist alternatif
    ["money_bag"]   = "prop_money_bag_01",        -- Sac d'argent
    ["dufflebag"]   = "prop_ld_bag_01",           -- Sac de sport noir
    ["backpack"]    = "p_michael_backpack_s",     -- Sac à dos
    ["clothes_bag"] = "prop_ld_bag_01",           -- Sac générique
    ["bag"]         = "prop_ld_bag_01",           -- Sac basique
}

-- Prop par défaut si l'item n'est pas dans la table
local DEFAULT_BAG_PROP = "hei_p_m_bag_var22_arm_s"

-- Table d'attachement : position et rotation spécifiques par prop
-- Chaque prop a son propre placement pour un rendu optimal
-- Configuration d'attachement unique pour tous les sacs
local UNIVERSAL_BAG_ATTACHMENT = {
    bone = 0x6F06,
    pos = {x = 0.029, y = 0.111, z = -0.341},
    rot = {x = 13.926, y = 7.022, z = 145.411}
}

local BAG_ATTACHMENTS = {
    ["prop_ld_bag_01"] = UNIVERSAL_BAG_ATTACHMENT,           -- Sac de sport noir
    ["hei_p_m_bag_var22_arm_s"] = UNIVERSAL_BAG_ATTACHMENT,  -- Sac de braquage (celui de base)
    ["prop_money_bag_01"] = UNIVERSAL_BAG_ATTACHMENT,        -- Sac d'argent
    ["p_michael_backpack_s"] = UNIVERSAL_BAG_ATTACHMENT,     -- Sac à dos
    ["prop_cs_heist_bag_02"] = UNIVERSAL_BAG_ATTACHMENT,     -- Sac heist
}

-- Attachement par défaut si le prop n'est pas dans la table
local DEFAULT_BAG_ATTACHMENT = UNIVERSAL_BAG_ATTACHMENT

-- Variables debug pour ajuster le placement du sac en temps réel
local debugBagOffset = { x = 0.12, y = 0.05, z = -0.05 }
local debugBagRot = { x = 130.0, y = -45.0, z = 90.0 }
local debugBagEntity = nil -- Référence au sac pour les commandes debug

-- Variable pour forcer un sac spécifique (définie ici pour être accessible)
local forcedBagItem = nil

--- Retourne le nom du prop correspondant à l'item sac
--- @param bagItem string Nom de l'item dans l'inventaire
--- @return string Nom du prop à spawn
local function GetBagPropFromItem(bagItem)
    -- Si un sac est forcé via /forcebag, l'utiliser en priorité
    if forcedBagItem and BAG_ITEM_TO_PROP[forcedBagItem] then
        return BAG_ITEM_TO_PROP[forcedBagItem]
    end

    if bagItem and BAG_ITEM_TO_PROP[bagItem] then
        return BAG_ITEM_TO_PROP[bagItem]
    end
    return DEFAULT_BAG_PROP
end

--- Retourne les paramètres d'attachement pour un prop donné
--- @param propName string Nom du prop
--- @return table Paramètres d'attachement (bone, pos, rot)
local function GetBagAttachment(propName)
    if propName and BAG_ATTACHMENTS[propName] then
        return BAG_ATTACHMENTS[propName]
    end
    return DEFAULT_BAG_ATTACHMENT
end

local function StartGoldCollection()
    if isCollectingGold or goldCartLooted then return end

    isCollectingGold = true

    local ped = PlayerPedId()
    local dict = "mini@repair"

    -- Sauvegarder la position actuelle
    local savedPos = GetEntityCoords(ped)
    local savedHeading = GetEntityHeading(ped)

    -- Position devant le chariot (reculé pour ne pas être dans le chariot)
    local tpPos = vector3(225.50, 220.27, 97.15)
    local tpHeading = 270.0

    -- 1. Fade out
    DoScreenFadeOut(400)
    Wait(450)

    -- 2. TP devant le chariot
    SetEntityCoordsNoOffset(ped, tpPos.x, tpPos.y, tpPos.z, false, false, false)
    SetEntityHeading(ped, tpHeading)
    FreezeEntityPosition(ped, true)

    Wait(100)

    -- 3. Fade in
    DoScreenFadeIn(400)
    Wait(400)

    -- Charger l'animation
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    VFW.ShowNotification({
        type = 'INFO',
        content = "Collecte des lingots en cours..."
    })

    -- Animation de ramassage (3 fois)
    for i = 1, 3 do
        if not isCollectingGold then break end
        TaskPlayAnim(ped, dict, "fixing_a_ped", 8.0, -8.0, 2000, 0, 0, false, false, false)
        Wait(2000)
    end

    -- Nettoyer
    ClearPedTasks(ped)
    RemoveAnimDict(dict)
    FreezeEntityPosition(ped, false)

    -- 4. Fade out pour retour
    DoScreenFadeOut(400)
    Wait(450)

    -- 5. Retour position initiale
    SetEntityCoordsNoOffset(ped, savedPos.x, savedPos.y, savedPos.z, false, false, false)
    SetEntityHeading(ped, savedHeading)

    Wait(100)

    -- 6. Fade in
    DoScreenFadeIn(400)

    if isCollectingGold then
        -- Succès - envoyer au serveur
        TriggerServerEvent("core:pacific:collectGold")
        goldCartLooted = true
    end

    isCollectingGold = false
end

-- ============================================
-- PERÇAGE DE COFFRES
-- ============================================

local function StartSafeDrilling(safeIndex, isSmallSafe, safeConfig)
    if isDrillingSafe or isAtDrillingSafe then return end

    if isSmallSafe and drilledSmallSafesClient[safeIndex] then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Ce coffre a déjà été percé"
        })
        return
    end

    if not isSmallSafe and drilledBigSafesClient[safeIndex] then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Ce coffre a déjà été percé"
        })
        return
    end

    local canDrill, reason = TriggerServerCallback("core:pacific:canDrillSafe", safeIndex, isSmallSafe or false)

    if not canDrill then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Impossible de percer ce coffre"
        })
        return
    end

    -- Démarrer l'interaction (TP + positionnement)
    StartDrillingInteraction(safeConfig, function()
        isDrillingSafe = true

        TriggerServerEvent("core:pacific:startDrill", safeIndex, isSmallSafe or false)

        -- Lancer le minigame de perçage
        StartPacificDrilling(safeConfig.pos, function(success)
            if success then
                -- Succès : quitter proprement puis valider
                StopDrillingInteraction(function()
                    TriggerServerEvent("core:pacific:completeDrill", safeIndex, isSmallSafe or false)
                    -- Notification envoyée par le serveur (évite les doublons)

                    if isSmallSafe then
                        drilledSmallSafesClient[safeIndex] = true
                    else
                        drilledBigSafesClient[safeIndex] = true
                    end
                    isDrillingSafe = false
                end)
            else
                -- Échec : quitter proprement puis notifier
                StopDrillingInteraction(function()
                    TriggerServerEvent("core:pacific:failDrill", safeIndex, isSmallSafe or false)
                    VFW.ShowNotification({
                        type = 'ILLEGAL',
                        message = "Perçage du coffre échoué !"
                    })
                    isDrillingSafe = false
                end)
            end
        end)
    end)
end

-- ============================================
-- MARQUEURS DES COFFRES
-- ============================================

CreateThread(function()
    while true do
        local wait = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        -- Marqueur terminal d'entrée (visible seulement si braquage en cours ET pas encore hacké)
        if isDoor1Unlocked and not isEntryDoorUnlocked then
            local distNumpad = #(playerCoords - NUMPAD_POSITION)
            if distNumpad < 50.0 then
                wait = 0
                DrawMarker(1,
                    NUMPAD_POSITION.x, NUMPAD_POSITION.y, NUMPAD_POSITION.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.5, 0.5, 0.1,
                    255, 165, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        -- Marqueur PC Sécurité (visible si porte 1 pas hackée)
        if not isDoor1Unlocked then
            local chairPos = vector3(SECURITY_PC_CONFIG.x, SECURITY_PC_CONFIG.y, SECURITY_PC_CONFIG.z)
            local distChair = #(playerCoords - chairPos)
            if distChair < 50.0 then
                wait = 0
                -- Z position ajustée pour être visible au sol
                DrawMarker(1,
                    SECURITY_PC_CONFIG.x, SECURITY_PC_CONFIG.y, SECURITY_PC_CONFIG.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.6, 0.6, 0.15,
                    255, 165, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        -- Marqueur ordinateur (visible après porte d'entrée ET avant hack ordinateur)
        if isEntryDoorUnlocked and not isComputerHacked then
            local distComputer = #(playerCoords - COMPUTER_POSITION)
            if distComputer < 50.0 then
                wait = 0
                DrawMarker(1,
                    COMPUTER_POSITION.x, COMPUTER_POSITION.y, COMPUTER_POSITION.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.5, 0.5, 0.1,
                    255, 165, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        -- Marqueur coffre-fort (visible après hack ordinateur ET avant ouverture coffre)
        if isComputerHacked and not isVaultDoorOpen then
            local distVaultNumpad = #(playerCoords - VAULT_NUMPAD_POSITION)
            if distVaultNumpad < 50.0 then
                wait = 0
                local _, groundZ = GetGroundZFor_3dCoord(VAULT_NUMPAD_POSITION.x, VAULT_NUMPAD_POSITION.y, VAULT_NUMPAD_POSITION.z, false)
                DrawMarker(1,
                    VAULT_NUMPAD_POSITION.x, VAULT_NUMPAD_POSITION.y, groundZ + 0.02,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.5, 0.5, 0.1,
                    255, 165, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        -- Petits coffres (visibles après hack ordinateur, TOUJOURS même après ouverture vault)
        if isComputerHacked then
            for safeIndex, safeConfig in ipairs(SMALL_SAFES) do
                local dist = #(playerCoords - safeConfig.pos)

                if dist < 50.0 then
                    wait = 0
                    if not drilledSmallSafesClient[safeIndex] then
                        DrawMarker(1,
                            safeConfig.pos.x, safeConfig.pos.y, safeConfig.pos.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.5, 0.5, 0.1,
                            255, 165, 0, 100,
                            false, true, 2, false, nil, nil, false
                        )
                    end
                end
            end
        end

        -- Grands coffres (visibles APRES ouverture du vault)
        if isVaultDoorOpen then
            for safeIndex, safeConfig in ipairs(BIG_SAFES) do
                local dist = #(playerCoords - safeConfig.pos)

                if dist < 50.0 then
                    wait = 0
                    if not drilledBigSafesClient[safeIndex] then
                        DrawMarker(1,
                            safeConfig.pos.x, safeConfig.pos.y, safeConfig.pos.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.5, 0.5, 0.1,
                            255, 165, 0, 100,
                            false, true, 2, false, nil, nil, false
                        )
                    end
                end
            end

            -- Chariot de lingots d'or (visible après ouverture du vault, si pas encore collecté)
            if not goldCartLooted then
                local distGold = #(playerCoords - GOLD_CART_POSITION)
                if distGold < 50.0 then
                    wait = 0
                    local _, groundZ = GetGroundZFor_3dCoord(GOLD_CART_POSITION.x, GOLD_CART_POSITION.y, GOLD_CART_POSITION.z, false)
                    DrawMarker(1,
                        GOLD_CART_POSITION.x, GOLD_CART_POSITION.y, groundZ + 0.02,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.6, 0.6, 0.15,
                        255, 215, 0, 150, -- Couleur or
                        false, true, 2, false, nil, nil, false
                    )
                end
            end

        end

        Wait(wait)
    end
end)

-- ============================================
-- INTERACTIONS
-- ============================================

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Interaction au numpad d'entrée (hack direct avec TP + emote tablet)
        -- Accessible UNIQUEMENT si le PC Sécurité a été hacké (braquage en cours)
        if isDoor1Unlocked and not isHackingEntryDoor and not isAtEntryNumpad and not isEntryDoorUnlocked then
            local distNumpad = #(playerCoords - NUMPAD_POSITION)
            if distNumpad < PacificSettings.InteractDistance then
                wait = 0
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour hacker le terminal")

                if VFW.Interact.JustPressed(0, 38) then
                    local currentTime = GetGameTimer()
                    if currentTime - lastInteractionAttempt > 2000 then
                        lastInteractionAttempt = currentTime

                        -- Vérifier les conditions côté serveur
                        local canHack, reason = TriggerServerCallback("core:pacific:canHackBank")

                        if not canHack then
                            VFW.ShowNotification({
                                type = 'ILLEGAL',
                                message = reason or "Impossible d'accéder au terminal"
                            })
                        else
                            -- Démarrer l'interaction (TP + emote tablet)
                            StartEntryNumpadInteraction(function()
                                -- Une fois en position, lancer le hack
                                isHackingEntryDoor = true
                                exports['core']:StartHacking('firewall', 'hard', 30, function(hackSuccess)
                                    isHackingEntryDoor = false
                                    if hackSuccess then
                                        -- Succès : quitter proprement puis débloquer
                                        StopEntryNumpadInteraction(function()
                                            UnlockEntryDoor()
                                        end)
                                    else
                                        -- Échec : quitter proprement puis notifier
                                        StopEntryNumpadInteraction(function()
                                            VFW.ShowNotification({
                                                type = 'ILLEGAL',
                                                message = "Hacking échoué !"
                                            })
                                        end)
                                    end
                                end)
                            end)
                        end
                    end
                end
            end
        end

        -- Interaction avec le PC Sécurité (code + hack) - Premier hack, nécessite le code
        if not isEnteringCode and not isDoor1Unlocked and not isAtSecurityPC then
            local chairPos = vector3(SECURITY_PC_CONFIG.x, SECURITY_PC_CONFIG.y, SECURITY_PC_CONFIG.z)
            local distChair = #(playerCoords - chairPos)
            if distChair < PacificSettings.InteractDistance then
                wait = 0
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour hacker le PC Sécurité")

                if VFW.Interact.JustPressed(0, 38) then
                    local currentTime = GetGameTimer()
                    if currentTime - lastInteractionAttempt > 2000 then
                        lastInteractionAttempt = currentTime

                        -- Vérifier les conditions côté serveur (police, cooldown)
                        local canHack, reason = TriggerServerCallback("core:pacific:canHackSecurityPC")

                        if not canHack then
                            VFW.ShowNotification({
                                type = 'ILLEGAL',
                                message = reason or "Impossible d'accéder au PC"
                            })
                        else
                            -- S'installer au PC puis lancer le code input
                            StartSecurityPCInteraction(function()
                                StartBankCodeInput("securityPC")
                            end)
                        end
                    end
                end
            end
        end

        -- Interaction avec l'ordinateur (hack direct, pas de code) - uniquement si porte ouverte
        if not isHackingComputer and not isAtComputer and isEntryDoorUnlocked and not isComputerHacked then
            local distComputer = #(playerCoords - COMPUTER_POSITION)
            if distComputer < PacificSettings.InteractDistance then
                wait = 0
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour hacker l'ordinateur")

                if VFW.Interact.JustPressed(0, 38) then
                    local currentTime = GetGameTimer()
                    if currentTime - lastInteractionAttempt > 2000 then
                        lastInteractionAttempt = currentTime

                        -- Démarrer l'interaction (TP + emote tablet)
                        StartComputerInteraction(function()
                            -- Une fois en position, lancer les 3 hacks firewall enchaînés
                            isHackingComputer = true

                            local totalHacks = 3
                            local currentHack = 0

                            local function DoNextComputerHack()
                                currentHack = currentHack + 1

                                if currentHack > totalHacks then
                                    -- Tous les hacks terminés avec succès
                                    isHackingComputer = false
                                    StopComputerInteraction(function()
                                        UnlockSafesDoor()
                                    end)
                                    return
                                end

                                -- Notification de progression
                                VFW.ShowNotification({
                                    type = 'ILLEGAL',
                                    message = "Firewall " .. currentHack .. "/" .. totalHacks
                                })

                                exports['core']:StartHacking('firewall', 'hard', 30, function(hackSuccess)
                                    if hackSuccess then
                                        -- Hack réussi, passer au suivant après une courte pause
                                        Wait(500)
                                        DoNextComputerHack()
                                    else
                                        -- Échec : tout arrêter
                                        isHackingComputer = false
                                        StopComputerInteraction(function()
                                            VFW.ShowNotification({
                                                type = 'ILLEGAL',
                                                message = "Piratage échoué au firewall " .. currentHack .. "/" .. totalHacks .. " !"
                                            })
                                        end)
                                    end
                                end)
                            end

                            -- Démarrer la chaîne de hacks
                            DoNextComputerHack()
                        end)
                    end
                end
            end
        end

        -- Interaction pour le coffre-fort (hack direct, pas de code) - uniquement si ordinateur hacké
        if not isHackingVault and not isAtVault and isComputerHacked and not isVaultDoorOpen then
            local distVaultNumpad = #(playerCoords - VAULT_NUMPAD_POSITION)
            if distVaultNumpad < PacificSettings.InteractDistance then
                wait = 0
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour hacker le coffre-fort")

                if VFW.Interact.JustPressed(0, 38) then
                    local currentTime = GetGameTimer()
                    if currentTime - lastInteractionAttempt > 2000 then
                        lastInteractionAttempt = currentTime

                        -- Démarrer l'interaction (TP + emote tablet)
                        StartVaultInteraction(function()
                            isHackingVault = true

                            local totalHacks = 8
                            local currentHack = 0

                            local function DoNextVaultHack()
                                currentHack = currentHack + 1

                                if currentHack > totalHacks then
                                    isHackingVault = false
                                    StopVaultInteraction(function()
                                        TriggerServerEvent("core:pacific:openVault")
                                        isVaultDoorOpen = true
                                        if VFW.Tutorial.IsWaitingFor("pacific_hack_vault") then
                                            VFW.Tutorial.Complete("pacific_hack_vault")
                                        end
                                    end)
                                    return
                                end

                                VFW.ShowNotification({
                                    type = 'ILLEGAL',
                                    message = "Firewall " .. currentHack .. "/" .. totalHacks
                                })

                                exports['core']:StartHacking('firewall', 'hard', 30, function(hackSuccess)
                                    if hackSuccess then
                                        Wait(500)
                                        DoNextVaultHack()
                                    else
                                        isHackingVault = false
                                        StopVaultInteraction(function()
                                            VFW.ShowNotification({
                                                type = 'ILLEGAL',
                                                message = "Piratage échoué au firewall " .. currentHack .. "/" .. totalHacks .. " !"
                                            })
                                        end)
                                    end
                                end)
                            end

                            DoNextVaultHack()
                        end)
                    end
                end
            end
        end

        -- Interactions pour percer les petits coffres (uniquement si ordinateur hacké)
        if not isEnteringCode and not isDrillingSafe and not isAtDrillingSafe and isComputerHacked then
            for safeIndex, safeConfig in ipairs(SMALL_SAFES) do
                local dist = #(playerCoords - safeConfig.pos)

                if dist < PacificSettings.SafeInteractDistance then
                    wait = 0

                    if not drilledSmallSafesClient[safeIndex] then
                        ShowHelp(string.format("Appuyez sur ~INPUT_CONTEXT~ pour percer le petit coffre #%d", safeIndex))

                        if VFW.Interact.JustPressed(0, 38) then
                            local currentTime = GetGameTimer()
                            if currentTime - lastInteractionAttempt > 2000 then
                                lastInteractionAttempt = currentTime
                                StartSafeDrilling(safeIndex, true, safeConfig)
                            end
                        end
                    else
                        ShowHelp("~r~Ce coffre a déjà été percé")
                    end
                end
            end
        end

        -- Interactions pour percer les grands coffres (uniquement si vault ouvert)
        if not isEnteringCode and not isDrillingSafe and not isAtDrillingSafe and isVaultDoorOpen then
            for safeIndex, safeConfig in ipairs(BIG_SAFES) do
                local dist = #(playerCoords - safeConfig.pos)

                if dist < PacificSettings.SafeInteractDistance then
                    wait = 0

                    if not drilledBigSafesClient[safeIndex] then
                        ShowHelp(string.format("Appuyez sur ~INPUT_CONTEXT~ pour percer le grand coffre #%d", safeIndex))

                        if VFW.Interact.JustPressed(0, 38) then
                            local currentTime = GetGameTimer()
                            if currentTime - lastInteractionAttempt > 2000 then
                                lastInteractionAttempt = currentTime
                                StartSafeDrilling(safeIndex, false, safeConfig)
                            end
                        end
                    else
                        ShowHelp("~r~Ce coffre a déjà été percé")
                    end
                end
            end
        end

        -- Interaction chariot de lingots d'or (uniquement si vault ouvert)
        if not isCollectingGold and not goldCartLooted and isVaultDoorOpen then
            local distGold = #(playerCoords - GOLD_CART_POSITION)
            if distGold < PacificSettings.SafeInteractDistance then
                wait = 0
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour collecter les ~y~lingots d'or")

                if VFW.Interact.JustPressed(0, 38) then
                    local currentTime = GetGameTimer()
                    if currentTime - lastInteractionAttempt > 2000 then
                        lastInteractionAttempt = currentTime
                        StartGoldCollection()
                    end
                end
            end
        end

        Wait(wait)
    end
end)

-- ============================================
-- BLIP POLICE (rayon réduit)
-- ============================================

RegisterNetEvent("core:pacific:createPoliceBlip")
AddEventHandler("core:pacific:createPoliceBlip", function(position)
    if IsPoliceJob(VFW.PlayerData.job.name) then
        local blip = AddBlipForCoord(position.x, position.y, position.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("10-90 - Braquage Pacific Standard Bank")
        EndTextCommandSetBlipName(blip)

        robberyBlip = blip

        SetTimeout(PacificSettings.PoliceBlipDuration, function()
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end)
    end
end)

-- ============================================
-- TUTORIEL BRAQUAGE PACIFIC
-- Guide le joueur à travers les étapes du braquage
-- ============================================

local pacificTutorialActive = false

--- Démarre le tutoriel du braquage Pacific
StartPacificTutorial = function()
    if pacificTutorialActive then
        return
    end

    -- Vérifier que VFW.Tutorial existe
    if not VFW or not VFW.Tutorial or not VFW.Tutorial.Start then
        return
    end

    pacificTutorialActive = true

    VFW.Tutorial.Start({
        id = "pacific_heist",
        title = "Braquage Pacific Standard",
        skippable = false,  -- Tutoriel persistant, ne peut pas être passé avec ESC
        force = true,  -- Toujours afficher même si déjà fait

        steps = {
            -- Étape 1: Introduction après PC Sécurité
            {
                type = "info",
                title = "Systèmes désactivés !",
                description = "Tu as hacké le PC de sécurité. Maintenant descends les escaliers pour accéder à la zone des coffres."
            },
            -- Étape 2: Aller à l'ordinateur (en bas des escaliers)
            {
                type = "location",
                title = "Ordinateur Central",
                description = "Descends les escaliers et rends-toi à l'ordinateur central pour débloquer l'accès aux coffres.",
                coords = COMPUTER_POSITION,
                radius = 3.0,
                blip = {
                    sprite = 521,
                    color = 17,
                    scale = 0.5
                }
            },
            -- Étape 3: Hacker l'ordinateur
            {
                type = "action",
                action = "pacific_hack_computer",
                title = "Hacker l'ordinateur",
                description = "Interagis avec l'ordinateur et réussis le minigame de hack."
            },
            -- Étape 6: Info sur les coffres
            {
                type = "tip",
                title = "Coffres disponibles",
                description = "Tu as maintenant accès aux petits coffres dans la banque et au coffre-fort principal. Utilise ta perceuse pour les ouvrir !"
            },
            -- Étape 7: Aller au coffre-fort
            {
                type = "location",
                title = "Coffre-fort",
                description = "Rends-toi au numpad du coffre-fort pour l'ouvrir.",
                coords = VAULT_NUMPAD_POSITION,
                radius = 3.0,
                blip = {
                    sprite = 440,
                    color = 1,
                    scale = 0.5
                }
            },
            -- Étape 8: Hacker le coffre-fort
            {
                type = "action",
                action = "pacific_hack_vault",
                title = "Ouvrir le coffre-fort",
                description = "Interagis avec le numpad et réussis le minigame pour ouvrir la porte du coffre-fort."
            },
            -- Étape 9: Info finale
            {
                type = "tip",
                title = "Le butin !",
                description = "Le coffre-fort est ouvert ! Récupère les lingots d'or sur le chariot et perce les grands coffres. Attention au temps restant !"
            },
            -- Étape 10: Conclusion
            {
                type = "info",
                title = "Bonne chance !",
                description = "Tu connais maintenant le déroulement du braquage. Récupère un maximum de butin avant la fin du timer !"
            }
        },

        onComplete = function()
            pacificTutorialActive = false
            VFW.ShowNotification({
                type = 'ILLEGAL',
                title = "Tutoriel terminé",
                message = "Tu maîtrises maintenant le braquage Pacific !"
            })
        end,

        onSkip = function()
            pacificTutorialActive = false
        end
    })
end

--- Arrête le tutoriel Pacific si actif
StopPacificTutorial = function()
    if pacificTutorialActive then
        VFW.Tutorial.End(true)  -- silent = true
        pacificTutorialActive = false
    end
end

-- ============================================
-- BLIP BANQUE PACIFIC (PERMANENT)
-- Toujours visible sur la carte
-- ============================================

local function SetupBankBlip()
    if bankBlip then
        if DoesBlipExist(bankBlip) then
            RemoveBlip(bankBlip)
        end
        bankBlip = nil
    end

    local blip = AddBlipForCoord(PACIFIC_BANK_BLIP_POSITION.x, PACIFIC_BANK_BLIP_POSITION.y, PACIFIC_BANK_BLIP_POSITION.z)
    SetBlipSprite(blip, 108)  -- Icône banque classique
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 5)    -- Jaune
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Banque Pacific")
    EndTextCommandSetBlipName(blip)
    bankBlip = blip
end

-- ============================================
-- SYSTÈME DE BLIPS PROGRESSIFS
-- PC Sécurité : visible par tous dans un rayon de 30m
-- Autres blips : visibles uniquement par l'auteur du braquage (rayon infini)
-- ============================================

-- Distance pour les blips visibles par tous (30m)
local HEIST_BLIP_DISTANCE = 30.0

-- Table des blips actifs
local heistBlips = {
    securityPC = nil,      -- Étape 1: PC Sécurité (visible par tous, rayon 30m)
    computer = nil,        -- Étape 2: Ordinateur (auteur seulement)
    smallSafes = {},       -- Étape 3: Petits coffres (tous à 30m après ordi hacké)
    vaultNumpad = nil,     -- Étape 4: Numpad coffre-fort (auteur seulement jusqu'à ouverture)
    bigSafes = {},         -- Étape 5: Grands coffres (tous à 30m après vault ouvert)
    goldCart = nil         -- Étape 6: Chariot d'or (tous à 30m après vault ouvert)
}

-- Positions des blips
local BLIP_POSITIONS = {
    securityPC = vector3(263.60, 229.85, 106.36),
    computer = COMPUTER_POSITION,
    vaultNumpad = VAULT_NUMPAD_POSITION,
    goldCart = GOLD_CART_POSITION
}

--- Crée un blip visible dans un rayon limité (pour PC Sécurité - visible par tous)
---@param position vector3 Position du blip
---@param sprite number Sprite du blip
---@param colour number Couleur du blip
---@param name string Nom du blip
---@param scale number|nil Scale du blip (défaut: 0.7)
---@return number blip Handle du blip créé
local function CreatePublicBlip(position, sprite, colour, name, scale)
    local blip = AddBlipForCoord(position.x, position.y, position.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale or 0.5)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, true)  -- Visible uniquement sur minimap (courte distance)
    SetBlipDisplay(blip, 2)          -- Affichage minimap uniquement
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

--- Crée un blip visible partout (pour l'auteur du braquage uniquement)
---@param position vector3 Position du blip
---@param sprite number Sprite du blip
---@param colour number Couleur du blip
---@param name string Nom du blip
---@param scale number|nil Scale du blip (défaut: 0.7)
---@return number blip Handle du blip créé
local function CreateAuthorBlip(position, sprite, colour, name, scale)
    local blip = AddBlipForCoord(position.x, position.y, position.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale or 0.5)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, false)  -- Visible partout (rayon infini)
    SetBlipDisplay(blip, 4)           -- Affichage sur carte ET minimap
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

--- Supprime un blip s'il existe
---@param blip number|nil Handle du blip
---@return nil
local function RemoveHeistBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    return nil
end

--- Supprime tous les blips du braquage
local function RemoveAllHeistBlips()
    heistBlips.securityPC = RemoveHeistBlip(heistBlips.securityPC)
    heistBlips.computer = RemoveHeistBlip(heistBlips.computer)
    heistBlips.vaultNumpad = RemoveHeistBlip(heistBlips.vaultNumpad)
    heistBlips.goldCart = RemoveHeistBlip(heistBlips.goldCart)

    -- Supprimer les blips des petits coffres
    for i, blip in pairs(heistBlips.smallSafes) do
        RemoveHeistBlip(blip)
        heistBlips.smallSafes[i] = nil
    end

    -- Supprimer les blips des grands coffres
    for i, blip in pairs(heistBlips.bigSafes) do
        RemoveHeistBlip(blip)
        heistBlips.bigSafes[i] = nil
    end
end

--- Gère les blips des petits coffres (visible par tous à 30m après ordi hacké)
--- @param playerCoords vector3 Position du joueur
local function UpdateSmallSafesBlips(playerCoords)
    for i, safeConfig in ipairs(SMALL_SAFES) do
        local distToSafe = #(playerCoords - safeConfig.pos)

        if not drilledSmallSafesClient[i] then
            -- Coffre non percé : créer le blip si à portée
            if distToSafe < HEIST_BLIP_DISTANCE then
                if not heistBlips.smallSafes[i] or not DoesBlipExist(heistBlips.smallSafes[i]) then
                    heistBlips.smallSafes[i] = CreatePublicBlip(safeConfig.pos, 618, 17, "Petit coffre", 0.6)
                end
            else
                -- Hors portée : supprimer le blip
                heistBlips.smallSafes[i] = RemoveHeistBlip(heistBlips.smallSafes[i])
            end
        else
            -- Coffre percé : supprimer le blip
            heistBlips.smallSafes[i] = RemoveHeistBlip(heistBlips.smallSafes[i])
        end
    end
end

--- Gère les blips des grands coffres (visible par tous à 30m après vault ouvert)
--- @param playerCoords vector3 Position du joueur
local function UpdateBigSafesBlips(playerCoords)
    for i, safeConfig in ipairs(BIG_SAFES) do
        local distToSafe = #(playerCoords - safeConfig.pos)

        if not drilledBigSafesClient[i] then
            -- Coffre non percé : créer le blip si à portée
            if distToSafe < HEIST_BLIP_DISTANCE then
                if not heistBlips.bigSafes[i] or not DoesBlipExist(heistBlips.bigSafes[i]) then
                    heistBlips.bigSafes[i] = CreatePublicBlip(safeConfig.pos, 618, 5, "Grand coffre", 0.7)
                end
            else
                -- Hors portée : supprimer le blip
                heistBlips.bigSafes[i] = RemoveHeistBlip(heistBlips.bigSafes[i])
            end
        else
            -- Coffre percé : supprimer le blip
            heistBlips.bigSafes[i] = RemoveHeistBlip(heistBlips.bigSafes[i])
        end
    end
end

--- Supprime les blips des petits coffres
local function RemoveSmallSafesBlips()
    for i, blip in pairs(heistBlips.smallSafes) do
        RemoveHeistBlip(blip)
        heistBlips.smallSafes[i] = nil
    end
end

--- Supprime les blips des grands coffres
local function RemoveBigSafesBlips()
    for i, blip in pairs(heistBlips.bigSafes) do
        RemoveHeistBlip(blip)
        heistBlips.bigSafes[i] = nil
    end
end

-- Thread principal pour gérer les blips progressifs
CreateThread(function()
    while true do
        local wait = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distToSecurityPC = #(playerCoords - BLIP_POSITIONS.securityPC)
        local distToVaultNumpad = #(playerCoords - BLIP_POSITIONS.vaultNumpad)
        local distToGoldCart = #(playerCoords - BLIP_POSITIONS.goldCart)

        -- =============================================
        -- ÉTAPE 1: PC Sécurité (premier hack)
        -- Visible par TOUS dans un rayon de 30m
        -- =============================================
        if not isDoor1Unlocked then
            if distToSecurityPC < HEIST_BLIP_DISTANCE then
                if not heistBlips.securityPC or not DoesBlipExist(heistBlips.securityPC) then
                    heistBlips.securityPC = CreatePublicBlip(BLIP_POSITIONS.securityPC, 521, 17, "PC Sécurité - Pacific Banque", 0.8)
                end
            else
                heistBlips.securityPC = RemoveHeistBlip(heistBlips.securityPC)
            end
            -- Supprimer les blips des étapes suivantes
            heistBlips.computer = RemoveHeistBlip(heistBlips.computer)
            heistBlips.vaultNumpad = RemoveHeistBlip(heistBlips.vaultNumpad)
            heistBlips.goldCart = RemoveHeistBlip(heistBlips.goldCart)
            RemoveSmallSafesBlips()
            RemoveBigSafesBlips()

        -- =============================================
        -- ÉTAPE 2: Ordinateur Central (après PC Sécurité hacké)
        -- Visible UNIQUEMENT par l'auteur (rayon infini)
        -- =============================================
        elseif isDoor1Unlocked and not isComputerHacked then
            -- Supprimer le blip PC Sécurité
            heistBlips.securityPC = RemoveHeistBlip(heistBlips.securityPC)

            if isRobberyAuthor then
                -- Auteur : blip ordinateur visible partout
                if not heistBlips.computer or not DoesBlipExist(heistBlips.computer) then
                    heistBlips.computer = CreateAuthorBlip(BLIP_POSITIONS.computer, 521, 17, "Ordinateur Central", 0.8)
                end
            else
                -- Pas l'auteur : pas de blip
                heistBlips.computer = RemoveHeistBlip(heistBlips.computer)
            end

            -- Supprimer les blips des étapes suivantes
            heistBlips.vaultNumpad = RemoveHeistBlip(heistBlips.vaultNumpad)
            heistBlips.goldCart = RemoveHeistBlip(heistBlips.goldCart)
            RemoveSmallSafesBlips()
            RemoveBigSafesBlips()

        -- =============================================
        -- ÉTAPE 3: Petits coffres + Coffre-fort (après ordinateur hacké)
        -- Petits coffres : visibles par TOUS à 30m
        -- Coffre-fort : visible UNIQUEMENT par l'auteur
        -- =============================================
        elseif isComputerHacked and not isVaultDoorOpen then
            heistBlips.securityPC = RemoveHeistBlip(heistBlips.securityPC)
            heistBlips.computer = RemoveHeistBlip(heistBlips.computer)

            -- Blips petits coffres : visibles par TOUS à 30m
            UpdateSmallSafesBlips(playerCoords)

            -- Blip coffre-fort : visible UNIQUEMENT par l'auteur (rayon infini)
            if isRobberyAuthor then
                if not heistBlips.vaultNumpad or not DoesBlipExist(heistBlips.vaultNumpad) then
                    heistBlips.vaultNumpad = CreateAuthorBlip(BLIP_POSITIONS.vaultNumpad, 440, 1, "Coffre-fort", 0.9)
                end
            else
                heistBlips.vaultNumpad = RemoveHeistBlip(heistBlips.vaultNumpad)
            end

            -- Supprimer les blips des étapes suivantes
            heistBlips.goldCart = RemoveHeistBlip(heistBlips.goldCart)
            RemoveBigSafesBlips()

        -- =============================================
        -- ÉTAPE 4: Vault ouvert - Tout visible par TOUS à 30m
        -- Petits coffres, grands coffres, chariot d'or
        -- =============================================
        elseif isVaultDoorOpen then
            heistBlips.securityPC = RemoveHeistBlip(heistBlips.securityPC)
            heistBlips.computer = RemoveHeistBlip(heistBlips.computer)
            heistBlips.vaultNumpad = RemoveHeistBlip(heistBlips.vaultNumpad)

            -- Blips petits coffres : visibles par TOUS à 30m
            UpdateSmallSafesBlips(playerCoords)

            -- Blips grands coffres : visibles par TOUS à 30m
            UpdateBigSafesBlips(playerCoords)

            -- Blip chariot d'or : visible par TOUS à 30m
            if not goldCartLooted then
                if distToGoldCart < HEIST_BLIP_DISTANCE then
                    if not heistBlips.goldCart or not DoesBlipExist(heistBlips.goldCart) then
                        heistBlips.goldCart = CreatePublicBlip(BLIP_POSITIONS.goldCart, 618, 5, "Lingots d'or", 0.9)
                    end
                else
                    heistBlips.goldCart = RemoveHeistBlip(heistBlips.goldCart)
                end
            else
                heistBlips.goldCart = RemoveHeistBlip(heistBlips.goldCart)
            end
        end

        Wait(wait)
    end
end)

-- ============================================
-- PORTE DU COFFRE (ANIMÉE)
-- ============================================

local doorOriginalStates = {}
local isDoorAnimating = false -- Empêche les animations simultanées

-- Configuration de l'animation de la porte
local VAULT_DOOR_CONFIG = {
    openDuration = 5000,   -- Durée d'ouverture en ms (5 secondes)
    closeDuration = 3000,  -- Durée de fermeture en ms (3 secondes)
    openAngle = 90.0,      -- Angle d'ouverture (degrés)
    useEasing = true,      -- Utiliser l'easing pour un effet réaliste
    playSound = true,      -- Jouer le son de la porte
}

--- Trouve la porte du coffre-fort
--- @return table Liste des entités de porte trouvées
local function FindVaultDoor()
    local doors = {}
    local objects = GetGamePool('CObject')
    local doorModel = GetHashKey("v_ilev_bk_vaultdoor")

    for _, obj in pairs(objects) do
        if GetEntityModel(obj) == doorModel then
            local objPos = GetEntityCoords(obj)
            local distance = #(VAULT_DOOR_POSITION - objPos)

            if distance < 2.0 then
                table.insert(doors, obj)

                -- Sauvegarder l'état original de la porte
                if not doorOriginalStates[obj] then
                    doorOriginalStates[obj] = {
                        heading = GetEntityHeading(obj),
                        coords = GetEntityCoords(obj),
                        rotation = GetEntityRotation(obj)
                    }
                end
            end
        end
    end

    return doors
end

--- Fonction d'easing (ease-out cubic) pour ralentir à la fin
--- @param t number Progression de 0 à 1
--- @return number Valeur easée de 0 à 1
local function EaseOutCubic(t)
    return 1 - math.pow(1 - t, 3)
end

--- Fonction d'easing (ease-in cubic) pour accélérer au début
--- @param t number Progression de 0 à 1
--- @return number Valeur easée de 0 à 1
local function EaseInCubic(t)
    return t * t * t
end

--- Normalise un angle entre 0 et 360
--- @param angle number L'angle à normaliser
--- @return number L'angle normalisé
local function NormalizeAngle(angle)
    while angle < 0 do angle = angle + 360 end
    while angle >= 360 do angle = angle - 360 end
    return angle
end

--- Interpole entre deux angles en prenant le chemin le plus court
--- @param from number Angle de départ
--- @param to number Angle d'arrivée
--- @param t number Progression de 0 à 1
--- @return number Angle interpolé
local function LerpAngle(from, to, t)
    local diff = to - from

    -- Prendre le chemin le plus court
    if diff > 180 then
        diff = diff - 360
    elseif diff < -180 then
        diff = diff + 360
    end

    return NormalizeAngle(from + diff * t)
end

--- Joue le son de la porte du coffre
--- @param isOpening boolean True si ouverture, false si fermeture
local function PlayVaultDoorSound(isOpening)
    if not VAULT_DOOR_CONFIG.playSound then return end

    local doors = FindVaultDoor()
    if #doors == 0 then return end

    local doorCoords = GetEntityCoords(doors[1])

    -- Sons natifs GTA pour portes lourdes/métalliques
    if isOpening then
        -- Son d'ouverture de porte lourde
        PlaySoundFromCoord(-1, "Door_Open", doorCoords.x, doorCoords.y, doorCoords.z, "DLC_HEIST_FLEECA_SOUNDSET", true, 50.0, false)
    else
        -- Son de fermeture de porte lourde
        PlaySoundFromCoord(-1, "Door_Close", doorCoords.x, doorCoords.y, doorCoords.z, "DLC_HEIST_FLEECA_SOUNDSET", true, 50.0, false)
    end
end

--- Anime la porte du coffre progressivement
--- @param door number Entité de la porte
--- @param isOpen boolean True pour ouvrir, false pour fermer
--- @param duration number Durée de l'animation en ms
--- @param callback function Fonction appelée à la fin (optionnel)
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

    -- Déterminer les angles de départ et d'arrivée
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

            -- Calculer la progression (0 à 1)
            local elapsed = GetGameTimer() - startTime
            local progress = elapsed / duration

            -- Appliquer l'easing si activé
            if VAULT_DOOR_CONFIG.useEasing then
                if isOpen then
                    -- Ease-out pour l'ouverture (ralentit à la fin)
                    progress = EaseOutCubic(progress)
                else
                    -- Ease-in pour la fermeture (accélère au début, impact à la fin)
                    progress = EaseInCubic(progress)
                end
            end

            -- Interpoler l'angle
            local currentHeading = LerpAngle(startHeading, targetHeading, progress)
            SetEntityHeading(door, currentHeading)

            Wait(0) -- Mise à jour chaque frame
        end

        -- S'assurer que la porte est exactement à la position finale
        if DoesEntityExist(door) then
            SetEntityHeading(door, targetHeading)
            FreezeEntityPosition(door, true)
        end

        if callback then callback() end
    end)
end

--- Change l'état de la porte (instantané ou animé)
--- @param door number Entité de la porte
--- @param isOpen boolean True pour ouvrir, false pour fermer
--- @param animated boolean True pour animation, false pour instantané
--- @param duration number Durée de l'animation en ms (optionnel)
--- @param callback function Fonction appelée à la fin (optionnel)
local function SetDoorState(door, isOpen, animated, duration, callback)
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
        -- Animation progressive
        local animDuration = duration or (isOpen and VAULT_DOOR_CONFIG.openDuration or VAULT_DOOR_CONFIG.closeDuration)
        AnimateDoorHeading(door, isOpen, animDuration, callback)
    else
        -- Changement instantané (ancien comportement)
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

--- Ouvre toutes les portes du coffre avec animation
--- @param duration number Durée de l'animation en ms (optionnel)
--- @param callback function Fonction appelée quand toutes les portes sont ouvertes (optionnel)
local function OpenVaultDoorAnimated(duration, callback)
    if isDoorAnimating then
        return
    end

    isDoorAnimating = true
    local doors = FindVaultDoor()

    if #doors == 0 then
        isDoorAnimating = false
        if callback then callback() end
        return
    end

    -- Jouer le son d'ouverture
    PlayVaultDoorSound(true)

    local doorsCompleted = 0
    local totalDoors = #doors

    for _, door in pairs(doors) do
        SetDoorState(door, true, true, duration, function()
            doorsCompleted = doorsCompleted + 1
            if doorsCompleted >= totalDoors then
                isDoorAnimating = false
                if callback then callback() end
            end
        end)
    end
end

--- Ferme toutes les portes du coffre avec animation
--- @param duration number Durée de l'animation en ms (optionnel)
--- @param callback function Fonction appelée quand toutes les portes sont fermées (optionnel)
local function CloseVaultDoorAnimated(duration, callback)
    if isDoorAnimating then
        return
    end

    isDoorAnimating = true
    local doors = FindVaultDoor()

    if #doors == 0 then
        isDoorAnimating = false
        if callback then callback() end
        return
    end

    -- Jouer le son de fermeture
    PlayVaultDoorSound(false)

    local doorsCompleted = 0
    local totalDoors = #doors

    for _, door in pairs(doors) do
        SetDoorState(door, false, true, duration, function()
            doorsCompleted = doorsCompleted + 1
            if doorsCompleted >= totalDoors then
                isDoorAnimating = false
                if callback then callback() end
            end
        end)
    end
end

-- Event d'ouverture de la porte du coffre (avec animation)
RegisterNetEvent("core:pacific:openVaultDoor")
AddEventHandler("core:pacific:openVaultDoor", function(duration)
    OpenVaultDoorAnimated(nil, function()
        isVaultDoorOpen = true
    end)
end)

-- Event de fermeture de la porte du coffre (avec animation)
RegisterNetEvent("core:pacific:closeVaultDoor")
AddEventHandler("core:pacific:closeVaultDoor", function()
    CloseVaultDoorAnimated(nil, function()
        isVaultDoorOpen = false
    end)
end)


-- ============================================
-- VERROUILLAGE DES PORTES
-- ============================================

local pacificDoorsRegistered = false

local function SetupPacificDoors()
    -- Enregistrer et verrouiller toutes les portes
    for _, door in ipairs(PACIFIC_DOORS) do
        AddDoorToSystem(door.id, door.hash, door.coords.x, door.coords.y, door.coords.z, false, false, false)
        DoorSystemSetDoorState(door.id, 1, false, false) -- 1 = locked
    end
    pacificDoorsRegistered = true
end

local function LockPacificDoors()
    for _, door in ipairs(PACIFIC_DOORS) do
        DoorSystemSetDoorState(door.id, 1, false, false) -- 1 = locked
    end
end

RegisterNetEvent("core:pacific:lockDoors")
AddEventHandler("core:pacific:lockDoors", function()
    LockPacificDoors()
    LockDoor1Client() -- Verrouiller aussi la Porte 1

    -- Reset complet des états du braquage
    isEntryDoorUnlocked = false
    isComputerHacked = false
    isVaultDoorOpen = false
    isDoor1Unlocked = false
    securityPCHackCompleted = false
    isRobberyAuthor = false
    isHackingSecurityPC = false
    isEnteringCode = false
    isHackingEntryDoor = false
    isHackingComputer = false
    isHackingVault = false

    -- Reset des coffres
    drilledSmallSafesClient = {}
    drilledBigSafesClient = {}
    goldCartLooted = false

    -- Reset des états d'interaction
    isAtSecurityPC = false
    isAtComputer = false
    isAtVault = false
    isAtEntryNumpad = false
    isAtDrillingSafe = false
    savedPCPosition = nil
    savedPCHeading = nil
    savedComputerPosition = nil
    savedComputerHeading = nil
    savedVaultPosition = nil
    savedVaultHeading = nil
    savedEntryNumpadPosition = nil
    savedEntryNumpadHeading = nil
    savedDrillingPosition = nil
    savedDrillingHeading = nil
    currentDrillingSafeConfig = nil

    -- Annuler les emotes en cours et libérer le joueur
    EmoteCancel()
    FreezeEntityPosition(PlayerPedId(), false)
    VFW.Nui.Focus(false)

    -- Reset des blips pour revenir à l'étape 1
    RemoveAllHeistBlips()

end)

RegisterNetEvent("core:pacific:resetSmallSafes")
AddEventHandler("core:pacific:resetSmallSafes", function()
    drilledSmallSafesClient = {}
    drilledBigSafesClient = {}
    goldCartLooted = false
    -- Reset des blips des coffres
    RemoveAllHeistBlips()
end)

RegisterNetEvent("core:pacific:smallSafeDrilled")
AddEventHandler("core:pacific:smallSafeDrilled", function(safeIndex)
    drilledSmallSafesClient[safeIndex] = true
end)

RegisterNetEvent("core:pacific:bigSafeDrilled")
AddEventHandler("core:pacific:bigSafeDrilled", function(safeIndex)
    drilledBigSafesClient[safeIndex] = true
end)

-- Sync de l'état de perçage (empêche 2 joueurs de percer le même coffre)
RegisterNetEvent("core:pacific:syncDrillingState")
AddEventHandler("core:pacific:syncDrillingState", function(safeIndex, isSmallSafe, isDrilling, playerId)
    local drillKey = (isSmallSafe and "small_" or "big_") .. safeIndex
    if isDrilling then
        activeDrillingsClient[drillKey] = playerId
    else
        activeDrillingsClient[drillKey] = nil
    end
end)

RegisterNetEvent("core:pacific:goldCollected")
AddEventHandler("core:pacific:goldCollected", function()
    goldCartLooted = true
end)

-- ============================================
-- INITIALISATION
-- ============================================

-- Applique en direct les positions configurées depuis le Builder Staff
RegisterNetEvent("core:pacific:syncPositions")
AddEventHandler("core:pacific:syncPositions", function(cfg)
    ApplyPacificPositions(cfg)

    -- Ré-enregistrer les portes avec leurs nouvelles coordonnées (si déjà en place)
    if pacificDoorsRegistered then
        for _, door in ipairs(PACIFIC_DOORS) do
            RemoveDoorFromSystem(door.id)
        end
        SetupPacificDoors()
    end

    -- Rafraîchir le blip de la banque (SetupBankBlip supprime l'ancien)
    SetupBankBlip()
end)

CreateThread(function()
    Wait(2000)
    -- Charger la config de positions AVANT d'enregistrer les portes/blip
    local cfg = TriggerServerCallback("core:pacific:getPositions")
    if cfg then ApplyPacificPositions(cfg) end
    SetupPacificDoors() -- Enregistrer et verrouiller les portes
    SetupBankBlip()     -- Créer le blip de la banque
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        local cfg = TriggerServerCallback("core:pacific:getPositions")
        if cfg then ApplyPacificPositions(cfg) end
        SetupPacificDoors()
        SetupBankBlip()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if robberyBlip and DoesBlipExist(robberyBlip) then
            RemoveBlip(robberyBlip)
        end
        if bankBlip and DoesBlipExist(bankBlip) then
            RemoveBlip(bankBlip)
        end
        -- Supprimer tous les blips du braquage
        RemoveAllHeistBlips()
    end
end)

