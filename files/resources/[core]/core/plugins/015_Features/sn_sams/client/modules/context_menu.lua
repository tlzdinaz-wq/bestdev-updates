---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Context Menu SAMS - Menu dédié pour les jobs SAMS/LSFD
-- ============================================================

local function IsOtherPlayer(ped)
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then
        return false
    end
    if ped == PlayerPedId() then
        return false
    end
    local isPlayer = NetworkGetPlayerIndexFromPed(ped)
    if isPlayer then
        local targetServerId = GetPlayerServerId(isPlayer)
        local myServerId = GetPlayerServerId(PlayerId())
        if targetServerId == myServerId then
            return false
        end
    end
    return true
end

local function GetPlayerServerIdFromPed(ped)
    local playerId = NetworkGetPlayerIndexFromPed(ped)
    if playerId and playerId ~= -1 then
        return GetPlayerServerId(playerId)
    end
    return nil
end

-- Ouvre le MDT sur le formulaire de facture pre-rempli avec le citizen_identifier
-- du joueur cible (et non son server ID, sinon createInvoice ne notifie jamais le patient).
local function openInvoiceForPed(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if not serverId then return end

    local resolved = TriggerServerCallback("sn_sams:getNearbyPlayersInfo", { { serverId = serverId } })
    local target = resolved and resolved[1] or nil

    SN_SAMS.OpenMDT()

    -- Peuple la liste deroulante NUI avec le patient cible
    SendNUIMessage({
        action = "nui:sams:nearbyPlayersResult",
        data = target and { target } or {}
    })

    -- Ouvre l'onglet "Factures" en mode creation, presaisi sur l'identifier resolu
    SendNUIMessage({
        action = "nui:sams:openInvoice",
        data = { citizenId = target and target.id or nil }
    })
end

local function canShowSamsMenu(ped)
    if (Death and Death.isDead) or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not SN_SAMS.IsOnDuty() then
        return false
    end
    if not IsOtherPlayer(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 1.5
end

-- ============================================================
-- Conditions specifiques: coma / vivant
-- ============================================================
local function canShowSamsComaMenu(ped)
    if (Death and Death.isDead) or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not SN_SAMS.IsOnDuty() then
        return false
    end
    if not DoesEntityExist(ped) or ped == PlayerPedId() then
        return false
    end
    if not IsPedDeadOrDying(ped, true) and not (VFW.GetDeathCloneOwner and VFW.GetDeathCloneOwner(ped)) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 1.5
end

local function canShowSamsAliveMenu(ped)
    if not canShowSamsMenu(ped) then return false end
    return not IsPedDeadOrDying(ped, true) and not (VFW.GetDeathCloneOwner and VFW.GetDeathCloneOwner(ped))
end

-- ============================================================
-- Menu SAMS: Joueur dans le coma
-- ============================================================
local samsComaMenu = VFW.ContextAddSubmenu("ped", " Action SAMS", canShowSamsComaMenu, { color = { 44, 135, 255 } }, nil, { order = 1 })

local isInspecting = false

VFW.ContextAddButton("ped", ":search: Inspecter", function(ped)
    if isInspecting then return false end
    return canShowSamsComaMenu(ped)
end, function(ped)
    if isInspecting then return end
    isInspecting = true

    local playerPed = PlayerPedId()
    local animDict = "amb@medic@standing@kneel@base"
   local animName = "base"

   RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 5000, 1, 0, false, false, false)
    Wait(5000)
    ClearPedTasks(playerPed)
    RemoveAnimDict(animDict)

    -- Determiner la cause de mort via le serveur (les données locales ne sont pas fiables sur un death clone)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    local causeText = "Inconnue"

   if targetServerId then
        local deathData = TriggerServerCallback("sams:getDeathCause", targetServerId)
        if deathData then
            causeText = deathData.cause or deathData.sourceText or "Inconnue"
       end
    end

    VFW.ShowNotification({ type = "JOB", logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Inspection", content = "Cause : " .. causeText })
    isInspecting = false
end, {}, samsComaMenu)

VFW.ContextAddButton("ped", ":heart: Réanimation", canShowSamsComaMenu, function(ped)
    local targetId = GetPlayerServerIdFromPed(ped)
    if not targetId then return end
    TriggerServerEvent("sn_sams:healPlayer", targetId, "revive")
end, {}, samsComaMenu)

VFW.ContextAddButton("ped", " Porter", canShowSamsComaMenu, function(ped)
    VFW.CarryPeople(ped)
end, {}, samsComaMenu)

VFW.ContextAddButton("ped", ":edit: Faire une facture", canShowSamsComaMenu, function(ped)
    openInvoiceForPed(ped)
end, {}, samsComaMenu)

-- ============================================================
-- Menu SAMS: Joueur vivant
-- ============================================================
local samsMenu = VFW.ContextAddSubmenu("ped", " Action SAMS", canShowSamsAliveMenu, { color = { 44, 135, 255 } }, nil, { order = 1 })

VFW.ContextAddButton("ped", " Effectuer soins légers", canShowSamsAliveMenu, function(ped)
    local targetId = GetPlayerServerIdFromPed(ped)
    if not targetId then return end
    TriggerServerEvent("sn_sams:healPlayer", targetId, "light")
end, {}, samsMenu)

VFW.ContextAddButton("ped", ":flask: Effectuer soins importants", canShowSamsAliveMenu, function(ped)
    local targetId = GetPlayerServerIdFromPed(ped)
    if not targetId then return end
    TriggerServerEvent("sn_sams:healPlayer", targetId, "heavy")
end, {}, samsMenu)

VFW.ContextAddButton("ped", " Porter", canShowSamsAliveMenu, function(ped)
    VFW.CarryPeople(ped)
end, {}, samsMenu)

VFW.ContextAddButton("ped", ":edit: Faire une facture", canShowSamsAliveMenu, function(ped)
    openInvoiceForPed(ped)
end, {}, samsMenu)

-- ============================================================
-- Backup: Context menu sur soi-même
-- ============================================================
local function canShowBackupMenu(ped)
    if (Death and Death.isDead) or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not SN_SAMS.IsOnDuty() then
        return false
    end
    return ped == PlayerPedId()
end

local function canShowBackupPillbox(ped)
    return canShowBackupMenu(ped) and VFW.PlayerData.job.name == "sams_pib"
end

local function canShowBackupPaleto(ped)
    return canShowBackupMenu(ped) and VFW.PlayerData.job.name == "sams_pab"
end

local function getMyHospital()
    local jobName = VFW.PlayerData.job.name
    if jobName == "sams_pib" then return "pillbox" end
    if jobName == "sams_pab" then return "paleto" end
    return "pillbox"
end

local function getMyStreet()
    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    if streetHash and streetHash ~= 0 then
        return GetStreetNameFromHashKey(streetHash)
    end
    return "Position inconnue"
end

local BACKUP_LEVEL_LABELS = { "Niveau 1", "Niveau 2", "Niveau 3" }
local BACKUP_TARGET_LABELS = { pillbox = "Pillbox", paleto = "Paleto" }

-- Backups actives du joueur courant : { [backupId] = { id, levelLabel, targetHospital } }
local myActiveBackups = {}

local function requestBackup(level, targetHospital)
    TriggerServerEvent("sn_sams:requestBackup", level, getMyHospital(), getMyStreet(), targetHospital)
end

-- Confirmation serveur : backup créée ou relancée (même id si reset)
RegisterNetEvent("sn_sams:myBackupCreated", function(backupId, levelLabel, level, targetHospital)
    myActiveBackups[backupId] = { id = backupId, level = level, levelLabel = levelLabel, targetHospital = targetHospital }
    local label = targetHospital and ("Backup " .. (BACKUP_TARGET_LABELS[targetHospital] or targetHospital)) or "Backup Globale"
   ExecuteCommand("me effectue une demande de renfort de " .. BACKUP_LEVEL_LABELS[level] .. " (" .. label .. ")")
end)

-- Effacement d'une backup spécifique (acceptée, refusée, expirée, annulée)
RegisterNetEvent("sn_sams:myBackupResolved", function(backupId)
    if backupId then
        myActiveBackups[backupId] = nil
    else
        -- Fallback : vider toutes (déconnexion, etc.)
        myActiveBackups = {}
    end
end)

local backupMenu = VFW.ContextAddSubmenu("ped", ":siren: Demander une backup", canShowBackupMenu, { color = { 255, 60, 60 } }, nil)

-- Backup global (tous les SAMS)
local backupGlobalMenu = VFW.ContextAddSubmenu("ped", ":globe: Backup Globale", canShowBackupMenu, {}, backupMenu)

VFW.ContextAddButton("ped", ":dot-green: Niveau 1", canShowBackupMenu, function()
    requestBackup(1)
end, {}, backupGlobalMenu)

VFW.ContextAddButton("ped", ":dot-yellow: Niveau 2", canShowBackupMenu, function()
    requestBackup(2)
end, {}, backupGlobalMenu)

VFW.ContextAddButton("ped", ":dot-red: Niveau 3", canShowBackupMenu, function()
    requestBackup(3)
end, {}, backupGlobalMenu)

-- Backup Pillbox (uniquement les agents Pillbox)
local backupPillboxMenu = VFW.ContextAddSubmenu("ped", ":hospital: Backup Pillbox", canShowBackupPillbox, {}, backupMenu)

VFW.ContextAddButton("ped", ":dot-green: Niveau 1", canShowBackupPillbox, function()
    requestBackup(1, "pillbox")
end, {}, backupPillboxMenu)

VFW.ContextAddButton("ped", ":dot-yellow: Niveau 2", canShowBackupPillbox, function()
    requestBackup(2, "pillbox")
end, {}, backupPillboxMenu)

VFW.ContextAddButton("ped", ":dot-red: Niveau 3", canShowBackupPillbox, function()
    requestBackup(3, "pillbox")
end, {}, backupPillboxMenu)

-- Backup Paleto (uniquement les agents Paleto)
local backupPaletoMenu = VFW.ContextAddSubmenu("ped", " Backup Paleto", canShowBackupPaleto, {}, backupMenu)

VFW.ContextAddButton("ped", ":dot-green: Niveau 1", canShowBackupPaleto, function()
    requestBackup(1, "paleto")
end, {}, backupPaletoMenu)

VFW.ContextAddButton("ped", ":dot-yellow: Niveau 2", canShowBackupPaleto, function()
    requestBackup(2, "paleto")
end, {}, backupPaletoMenu)

VFW.ContextAddButton("ped", ":dot-red: Niveau 3", canShowBackupPaleto, function()
    requestBackup(3, "paleto")
end, {}, backupPaletoMenu)

-- Annuler une backup active
local function canShowCancelBackup(ped)
    if not canShowBackupMenu(ped) then return false end
    for _ in pairs(myActiveBackups) do return true end
    return false
end

local cancelBackupMenu = VFW.ContextAddSubmenu("ped", ":x: Annuler une backup", canShowCancelBackup, { color = { 200, 50, 50 } }, backupMenu)

local LEVEL_ICONS = { ":dot-green:", ":dot-yellow:", ":dot-red:" }

-- 9 slots fixes (3 niveaux × 3 types) — chacun visible seulement si la backup correspondante est active
local CANCEL_SLOTS = {
    { level = 1, targetHospital = nil,       label = ":dot-green: Niveau 1 · Globale" },
    { level = 2, targetHospital = nil,       label = ":dot-yellow: Niveau 2 · Globale" },
    { level = 3, targetHospital = nil,       label = ":dot-red: Niveau 3 · Globale" },
    { level = 1, targetHospital = "pillbox", label = ":dot-green: Niveau 1 · Pillbox" },
    { level = 2, targetHospital = "pillbox", label = ":dot-yellow: Niveau 2 · Pillbox" },
    { level = 3, targetHospital = "pillbox", label = ":dot-red: Niveau 3 · Pillbox" },
    { level = 1, targetHospital = "paleto",  label = ":dot-green: Niveau 1 · Paleto"  },
    { level = 2, targetHospital = "paleto",  label = ":dot-yellow: Niveau 2 · Paleto"  },
    { level = 3, targetHospital = "paleto",  label = ":dot-red: Niveau 3 · Paleto"  },
}

for _, slot in ipairs(CANCEL_SLOTS) do
    local slotLevel     = slot.level
    local slotTarget    = slot.targetHospital
    local slotLabel     = slot.label

    VFW.ContextAddButton("ped", slotLabel, function(ped)
        if not canShowBackupMenu(ped) then return false end
        for _, b in pairs(myActiveBackups) do
            if b.level == slotLevel and b.targetHospital == slotTarget then
                return true
            end
        end
        return false
    end, function()
        for id, b in pairs(myActiveBackups) do
            if b.level == slotLevel and b.targetHospital == slotTarget then
                TriggerServerEvent("sn_sams:cancelBackup", id)
                -- myActiveBackups is cleared server-side via sn_sams:myBackupResolved
                return
            end
        end
    end, {}, cancelBackupMenu)
end

-- ============================================================
-- Event client: Appliquer les soins
-- ============================================================
RegisterNetEvent("sn_sams:applyHeal", function(healAmount)
    local ped = PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local newHealth = math.min(currentHealth + healAmount, maxHealth)
    SetEntityHealth(ped, newHealth)
end)

-- ============================================================
-- Event client: Animation de soin (joué par le soignant)
-- ============================================================
RegisterNetEvent("sn_sams:playHealAnim", function(duration)
    local ped = PlayerPedId()
    local animDict = "amb@medic@standing@kneel@base"
   local animName = "base"

   RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    FreezeEntityPosition(ped, true)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, duration, 1, 0, false, false, false)
    Wait(duration)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)
end)

-- ============================================================
-- Animation CPR: helper local
-- ============================================================
local function PlayAnimOn(ped, dict, anim, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(1) end
    TaskPlayAnim(ped, dict, anim, 2.0, 2.0, -1, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end

-- Flag global pour bloquer les actions pendant le CPR (utilise par handsup.lua)
SN_SAMS = SN_SAMS or {}
SN_SAMS.cprActive = false

-- ============================================================
-- Event client: Animation CPR cote PATIENT (joue sur le vrai ped)
-- Adapte de l'ancien systeme core:jobs:client:reviveanimrevived
-- ============================================================
RegisterNetEvent("sn_sams:reviveAnimPatient", function(medicServerId)
    local ped = PlayerPedId()
    if not ped or not DoesEntityExist(ped) then return end

    -- Empecher la boucle d'animation de mort de override le CPR
    Death.gettingRevived = true

    -- Fermer immediatement le NUI de mort (l'etat sera finalise par vfw:revivePlayer apres l'anim)
    VFW.Nui.deathScreen(false)
    TriggerScreenblurFadeOut(800)
    VFW.Nui.HudVisible(true)

    -- Stopper l'anim de mort en cours pour eviter qu'elle override le CPR
    ClearPedTasksImmediately(ped)

    -- Recuperer le ped du medecin (avec retry si pas encore networked)
    local medicPed
    for _ = 1, 10 do
        local medicPlayerId = GetPlayerFromServerId(medicServerId)
        if medicPlayerId and medicPlayerId ~= -1 then
            medicPed = GetPlayerPed(medicPlayerId)
            if medicPed and medicPed ~= 0 and DoesEntityExist(medicPed) then break end
        end
        medicPed = nil
        Wait(100)
    end

    -- Si le medecin n'est toujours pas accessible, on joue le CPR sans repositionnement
    if medicPed and DoesEntityExist(medicPed) then
        local coords = GetOffsetFromEntityInWorldCoords(medicPed, 0.0, 0.95, 0.0)
        local medicHeading = GetEntityHeading(medicPed)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, medicHeading - 270.0)
    end

    -- Bloquer les actions pendant le CPR (X, accroupir, etc.)
    SN_SAMS.cprActive = true

    -- Jouer char_b (patient recoit le CPR) - retry borne pour eviter une boucle infinie
    local introStarted = false
    for _ = 1, 20 do
        PlayAnimOn(ped, "mini@cpr@char_b@cpr_def", "cpr_intro", 1)
        Wait(100)
        if IsEntityPlayingAnim(ped, "mini@cpr@char_b@cpr_def", "cpr_intro", 1) then
            introStarted = true
            break
        end
    end

    -- Declencher l'animation du medecin (meme si l'intro n'a pas demarre, le revive est gere par le serveur)
    TriggerServerEvent("sn_sams:reviveAnimMedic", medicServerId)

    if introStarted then
        Wait(15800 - 900)
        for i = 1, 15 do
            Wait(900)
            PlayAnimOn(ped, "mini@cpr@char_b@cpr_str", "cpr_pumpchest", 1)
        end

        PlayAnimOn(ped, "mini@cpr@char_b@cpr_str", "cpr_success", 1)
        Wait(5000)
    else
        -- Fallback: garder le ped immobile pendant le timer serveur sans freeze visible
        Wait(28000)
    end

    SN_SAMS.cprActive = false
    ClearPedTasks(ped)

    -- Signaler au serveur la fin de l'anim pour revive immediat
    TriggerServerEvent("sn_sams:cprAnimDone")
end)

-- ============================================================
-- Event client: Animation CPR cote MEDECIN (char_a)
-- Adapte de l'ancien systeme core:jobs:client:reviveanimreviver
-- ============================================================
RegisterNetEvent("sn_sams:reviveAnimMedic", function()
    local ped = PlayerPedId()

    -- Bloquer les actions pendant le CPR
    SN_SAMS.cprActive = true

    PlayAnimOn(ped, "mini@cpr@char_a@cpr_def", "cpr_intro", 1)
    Wait(15800 - 900)
    for i = 1, 15 do
        Wait(900)
        PlayAnimOn(ped, "mini@cpr@char_a@cpr_str", "cpr_pumpchest", 1)
    end

    PlayAnimOn(ped, "mini@cpr@char_a@cpr_str", "cpr_success", 1)
    Wait(5000)
    SN_SAMS.cprActive = false
    ClearPedTasks(ped)
end)
