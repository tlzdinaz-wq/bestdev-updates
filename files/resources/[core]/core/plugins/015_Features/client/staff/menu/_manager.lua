---@meta _
---@diagnostic disable: duplicate-doc-field

local VUI = exports["VUI"]

-- Configuration for custom banner
StaffMenu.Config = {
    -- Default banner URL from GitHub CDN
    defaultBanner = VFW.CDN.Get("banners/f5.png"),
    -- Custom banner URL (set to nil to use default)
    customBanner = nil -- Example: VFW.CDN.Get("banners/custom_admin.png")
}

-- Function to get the banner URL for VUI
function StaffMenu.GetBannerURL(customURL)
    -- Return custom URL if provided, otherwise use config custom, otherwise use default
    return customURL or StaffMenu.Config.customBanner or StaffMenu.Config.defaultBanner
end

StaffMenu.data = {
---@class playerList
    playerList = {},
---@class staffList
    staffList = {},
---@class offlinePlayerList
    offlinePlayerList = {},
---@class vehsList
    vehsList = { owned = {}, job = {}, faction = {} }
}

local PLAYER_LIST_TTL = 8000
local JOBS_TTL = 60000
local ORGS_TTL = 60000

function StaffMenu.FetchPlayerList(force)
    local now = GetGameTimer()
    if not force
        and type(StaffMenu.data.playerList) == "table"
        and next(StaffMenu.data.playerList)
        and StaffMenu._playerListAt
        and (now - StaffMenu._playerListAt) < PLAYER_LIST_TTL
    then
        return StaffMenu.data.playerList
    end

    if StaffMenu._playerListFetching then
        local t0 = GetGameTimer()
        while StaffMenu._playerListFetching and (GetGameTimer() - t0) < 8000 do
            Wait(0)
        end
        if not force and StaffMenu.data.playerList and next(StaffMenu.data.playerList) then
            return StaffMenu.data.playerList
        end
    end

    StaffMenu._playerListFetching = true
    local ok, list = pcall(TriggerServerCallback, "vfw:staff:getPlayerList")
    StaffMenu._playerListFetching = false
    StaffMenu.data.playerList = (ok and list) or {}
    StaffMenu._playerListAt = GetGameTimer()
    return StaffMenu.data.playerList
end

function StaffMenu.FetchJobs(force)
    local now = GetGameTimer()
    if not force
        and type(StaffMenu.data.jobsList) == "table"
        and next(StaffMenu.data.jobsList)
        and StaffMenu._jobsAt
        and (now - StaffMenu._jobsAt) < JOBS_TTL
    then
        return StaffMenu.data.jobsList
    end
    StaffMenu.data.jobsList = TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu._jobsAt = GetGameTimer()
    return StaffMenu.data.jobsList
end

function StaffMenu.FetchOrganizations(force)
    local now = GetGameTimer()
    if not force
        and type(StaffMenu.data.factionsList) == "table"
        and next(StaffMenu.data.factionsList)
        and StaffMenu._orgsAt
        and (now - StaffMenu._orgsAt) < ORGS_TTL
    then
        return StaffMenu.data.factionsList
    end
    StaffMenu.data.factionsList = TriggerServerCallback("core:staff:getOrganizations") or {}
    StaffMenu._orgsAt = GetGameTimer()
    return StaffMenu.data.factionsList
end

function StaffMenu.PlayerInfoFromRow(v)
    if type(v) ~= "table" then return {} end
    return {
        source = v.source,
        id = v.charId or v.id,
        charId = v.charId or v.id,
        uuid = v.uuid or v.id,
        pseudo = v.pseudo or v.playerName,
        playerName = v.playerName or v.pseudo,
        name = v.name,
        firstName = v.firstName,
        lastName = v.lastName,
        role = v.role,
        roleFormatted = v.roleFormatted or v.role,
        time = v.time,
        dateOfBirth = v.dateOfBirth or v.dateofbirth,
        height = v.height,
        sex = v.sex,
        job = v.job,
        jobName = v.jobName or v.job,
        jobFull = v.jobFull,
        grade = v.grade,
        crew = v.crew,
        faction = v.faction,
        factionName = v.factionName or v.crew,
        factionFull = v.factionFull,
        instance = v.instance,
        discord = v.discord,
        identifier = v.identifier,
        accountId = v.accountId,
        color = v.color,
        hasTig = v.hasTig,
        new = v.new,
        online = true,
    }
end

--- Prépare le menu joueur existant (sans le recréer ni spammer le serveur).
function StaffMenu.PreparePlayerMenu(source, parent, row, isAnimatorCtx)
    StaffMenu.animatorPlayerContext = isAnimatorCtx and true or false
    StaffMenu.data.selectedPlayer = source
    if StaffMenu._sanctionsFor ~= source then
        StaffMenu.data.sanctionsPlayerList = {}
        StaffMenu._sanctionsFor = nil
    end
    StaffMenu.data.warnsPlayerList = {}

    if type(row) == "table" then
        StaffMenu.data.playerInfo = StaffMenu.PlayerInfoFromRow(row)
        StaffMenu.data.playerInfo.source = StaffMenu.data.playerInfo.source or source
    else
        local info = TriggerServerCallback("vfw:staff:getPlayerInfo", source) or {}
        StaffMenu.data.playerInfo = StaffMenu.PlayerInfoFromRow(info)
        StaffMenu.data.playerInfo.source = StaffMenu.data.playerInfo.source or source
    end

    local info = StaffMenu.data.playerInfo or {}
    local title = string.format("%s [%d]", info.name or info.pseudo or "Joueur", tonumber(source) or 0)
    if StaffMenu.player and StaffMenu.player.SetTitle then
        StaffMenu.player.SetTitle(title)
    end
    if parent and StaffMenu.player then
        StaffMenu.player.parent = parent
    end
    return info
end
StaffMenu.adminChecked = false
local adminBanner = exports["core"]:GetVUIBanner("admin")
StaffMenu.main = VUI:CreateMenu("MENU ADMINISTRATION", adminBanner, true)
StaffMenu.reports = VUI:CreateSubMenu(StaffMenu.main, "REPORTS", adminBanner, true)
StaffMenu.report = VUI:CreateSubMenu(StaffMenu.reports, "REPORT", adminBanner, true)
StaffMenu.playersList = VUI:CreateSubMenu(StaffMenu.main, "LISTE DES JOUEURS", adminBanner, true)
StaffMenu.players = VUI:CreateSubMenu(StaffMenu.playersList, "JOUEURS EN LIGNE", adminBanner, true)
StaffMenu.player = VUI:CreateSubMenu(StaffMenu.players, "JOUEUR", adminBanner, true)
StaffMenu.playerLicense = VUI:CreateSubMenu(StaffMenu.player, "DONNER UN PERMIS", adminBanner, true)
StaffMenu.wipe = VUI:CreateSubMenu(StaffMenu.player, "WIPE", adminBanner, true)
StaffMenu.items = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES ITEMS", adminBanner, true)
StaffMenu.jobs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES JOBS", adminBanner, true)
StaffMenu.grades_jobs = VUI:CreateSubMenu(StaffMenu.jobs, "LISTE DES GRADES", adminBanner, true)
StaffMenu.factions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES FACTIONS", adminBanner, true)
StaffMenu.grades_factions = VUI:CreateSubMenu(StaffMenu.factions, "LISTE DES GRADES", adminBanner, true)
StaffMenu.factionMenu = VUI:CreateSubMenu(StaffMenu.builders, "GESTION FACTIONS", adminBanner, true)
StaffMenu.createFaction = VUI:CreateSubMenu(StaffMenu.factionMenu, "CREER UNE FACTION", adminBanner, true)
StaffMenu.createFactionBanner = VUI:CreateSubMenu(StaffMenu.createFaction, "BANNIÈRE", adminBanner, true)
StaffMenu.manageFactions = VUI:CreateSubMenu(StaffMenu.factionMenu, "GERER LES FACTIONS", adminBanner, true)
StaffMenu.manageFactionDetails = VUI:CreateSubMenu(StaffMenu.manageFactions, "DÉTAILS FACTION", adminBanner, true)
StaffMenu.manageFactionBanner = VUI:CreateSubMenu(StaffMenu.manageFactionDetails, "BANNIÈRE", adminBanner, true)
StaffMenu.manageFactionGrades = VUI:CreateSubMenu(StaffMenu.manageFactionDetails, "GRADES", adminBanner, true)
StaffMenu.manageGradeActions = VUI:CreateSubMenu(StaffMenu.manageFactionGrades, "ACTIONS GRADE", adminBanner, true)
StaffMenu.manageFactionMembers = VUI:CreateSubMenu(StaffMenu.manageFactionDetails, "MEMBRES", adminBanner, true)
StaffMenu.manageMemberActions = VUI:CreateSubMenu(StaffMenu.manageFactionMembers, "ACTIONS MEMBRE", adminBanner, true)
StaffMenu.manageFactionCharSelect = VUI:CreateSubMenu(StaffMenu.manageFactionMembers, "CHOISIR UN PERSONNAGE", adminBanner, true)
StaffMenu.vehs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES VÉHICULES", adminBanner, true)
StaffMenu.vehs_owned = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOUEUR", adminBanner, true)
StaffMenu.vehs_job = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOB", adminBanner, true)
StaffMenu.vehs_faction = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DE FACTION", adminBanner, true)
StaffMenu.vehicleActions = VUI:CreateSubMenu(StaffMenu.vehs_owned, "ACTIONS VÉHICULE", adminBanner, true)
StaffMenu.playerSanctions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES SANCTIONS", adminBanner, true)
StaffMenu.playerGiveItem = VUI:CreateSubMenu(StaffMenu.player, "DONNER UN ITEM", adminBanner, true)
StaffMenu.playerSetRank = VUI:CreateSubMenu(StaffMenu.player, "CHANGER LE RANG", adminBanner, true)
StaffMenu.staff = VUI:CreateSubMenu(StaffMenu.main, "STAFF", adminBanner, true)
StaffMenu.staffDetails = VUI:CreateSubMenu(StaffMenu.staff, "DÉTAILS STAFF", adminBanner, true)
StaffMenu.staffRoleChange = VUI:CreateSubMenu(StaffMenu.staffDetails, "CHANGER LE RÔLE", adminBanner, true)
StaffMenu.outils = VUI:CreateSubMenu(StaffMenu.main, "OUTILS DE MODÉRATION", adminBanner, true)
StaffMenu.staffRoleChangeOutils = VUI:CreateSubMenu(StaffMenu.outils, "CHANGER LE RÔLE", adminBanner, true)
StaffMenu.wipeConnected = VUI:CreateSubMenu(StaffMenu.outils, "WIPE", adminBanner, true)
StaffMenu.wipeOffline = VUI:CreateSubMenu(StaffMenu.outils, "WIPE OFFLINE", adminBanner, true)
StaffMenu.selectPlayerForJob = VUI:CreateSubMenu(StaffMenu.outils, "SÉLECTIONNER UN JOUEUR", adminBanner, true)
StaffMenu.selectPlayerForFaction = VUI:CreateSubMenu(StaffMenu.outils, "SÉLECTIONNER UN JOUEUR", adminBanner, true)
StaffMenu.offlinePlayers = VUI:CreateSubMenu(StaffMenu.outils, "JOUEURS HORS LIGNE", adminBanner, true)
StaffMenu.offlinePlayerActions = VUI:CreateSubMenu(StaffMenu.offlinePlayers, "ACTIONS JOUEUR", adminBanner, true)
StaffMenu.offlinePlayerJobs = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LE JOB", adminBanner, true)
StaffMenu.offlinePlayerJobGrades = VUI:CreateSubMenu(StaffMenu.offlinePlayerJobs, "CHOISIR LE GRADE", adminBanner, true)
StaffMenu.offlinePlayerFactions = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LA FACTION", adminBanner, true)
StaffMenu.offlinePlayerFactionGrades = VUI:CreateSubMenu(StaffMenu.offlinePlayerFactions, "CHOISIR LE GRADE", adminBanner, true)
StaffMenu.offlinePlayerRoleChange = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LE RÔLE", adminBanner, true)

-- Lists submenus (outils de modération)
StaffMenu.prisonList = VUI:CreateSubMenu(StaffMenu.outils, "JOUEURS EN PRISON", adminBanner, true)
StaffMenu.banListDirect = VUI:CreateSubMenu(StaffMenu.outils, "LISTE DES BANNISSEMENTS", adminBanner, true)
StaffMenu.banDetail = VUI:CreateSubMenu(StaffMenu.banListDirect, "DÉTAIL BAN", adminBanner, true)
StaffMenu.tigListMenu = VUI:CreateSubMenu(StaffMenu.outils, "LISTE DES TIG", adminBanner, true)
StaffMenu.tigWeaponsListMenu = VUI:CreateSubMenu(StaffMenu.outils, "LISTE DES TIG ARMES", adminBanner, true)
StaffMenu.kickListMenu = VUI:CreateSubMenu(StaffMenu.outils, "LISTE DES KICKS", adminBanner, true)
StaffMenu.warnListMenu = VUI:CreateSubMenu(StaffMenu.outils, "LISTE DES WARNS", adminBanner, true)
StaffMenu.removeLicense = VUI:CreateSubMenu(StaffMenu.outils, "RETIRER UN PERMIS", adminBanner, true)

-- Personal Actions submenu
StaffMenu.personalActions = VUI:CreateSubMenu(StaffMenu.main, "ACTIONS PERSONNELLES", adminBanner, true)
StaffMenu.personalTeleport = VUI:CreateSubMenu(StaffMenu.personalActions, "TÉLÉPORTATION", adminBanner, true)
StaffMenu.personalAppearance = VUI:CreateSubMenu(StaffMenu.personalActions, "APPARENCE", adminBanner, true)

-- Options Mode Staff submenu
StaffMenu.optionsStaff = VUI:CreateSubMenu(StaffMenu.main, "OPTIONS MODE STAFF", adminBanner, true)
StaffMenu.customTeleports = VUI:CreateSubMenu(StaffMenu.personalTeleport, "TÉLÉPORTATIONS CUSTOM", adminBanner, true)
StaffMenu.customTeleportOptions = VUI:CreateSubMenu(StaffMenu.customTeleports, "OPTIONS DU POINT", adminBanner, true)

-- Vehicle Management submenu (top-level)
StaffMenu.vehicleManagement = VUI:CreateSubMenu(StaffMenu.main, "GESTION VÉHICULE", adminBanner, true)
StaffMenu.deleteVehPlayer = VUI:CreateSubMenu(StaffMenu.vehicleManagement, "SUPPRIMER VÉH JOUEUR", adminBanner, true)
StaffMenu.deleteVehPlayerChars = VUI:CreateSubMenu(StaffMenu.deleteVehPlayer, "PERSONNAGES", adminBanner, true)
StaffMenu.deleteVehPlayerList = VUI:CreateSubMenu(StaffMenu.deleteVehPlayerChars, "VÉHICULES", adminBanner, true)

-- Animator submenus (when staff has both permissions)
StaffMenu.animator = VUI:CreateSubMenu(StaffMenu.main, "OUTILS ANIMATIONS", adminBanner, true)
StaffMenu.animatorReports = VUI:CreateSubMenu(StaffMenu.animator, "REPORTS ANIMATION", adminBanner, true)
StaffMenu.animatorReport = VUI:CreateSubMenu(StaffMenu.animatorReports, "REPORT ANIMATION", adminBanner, true)
StaffMenu.animatorOptions = VUI:CreateSubMenu(StaffMenu.animator, "OPTIONS ANIMATEUR", adminBanner, true)
StaffMenu.animatorAnnounce = VUI:CreateSubMenu(StaffMenu.animatorOptions, "ANNONCES", adminBanner, true)
StaffMenu.animatorActions = VUI:CreateSubMenu(StaffMenu.animator, "ACTIONS PERSONNELLES", adminBanner, true)
StaffMenu.animatorGiveItem = VUI:CreateSubMenu(StaffMenu.animator, "DONNER ITEM TEMPORAIRE", adminBanner, true)
StaffMenu.animatorGiveItemDuration = VUI:CreateSubMenu(StaffMenu.animatorGiveItem, "CHOISIR DURÉE", adminBanner, true)
StaffMenu.animatorVehicles = VUI:CreateSubMenu(StaffMenu.animator, "VÉHICULES", adminBanner, true)
StaffMenu.animatorVehicleCustom = VUI:CreateSubMenu(StaffMenu.animatorVehicles, ":wrench: CUSTOM VÉHICULE", adminBanner, true)
StaffMenu.animatorPedManagement = VUI:CreateSubMenu(StaffMenu.animator, "GESTION DES PEDS", adminBanner, true)
StaffMenu.animatorPedList = VUI:CreateSubMenu(StaffMenu.animatorPedManagement, "LISTE DES PEDS", adminBanner, true)


local animatorBanner = exports["core"]:GetVUIBanner("animator")
-- Animator standalone menu for F7 access (no parent = closes on back instead of returning to admin menu)
StaffMenu.animatorStandalone = VUI:CreateMenu("MENU ANIMATEUR", animatorBanner, true)

-- Animator standalone submenus (children of standalone menu for correct back navigation)
StaffMenu.animatorStandaloneReports = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "REPORTS ANIMATION", animatorBanner, true)
StaffMenu.animatorStandaloneReport = VUI:CreateSubMenu(StaffMenu.animatorStandaloneReports, "REPORT ANIMATION", animatorBanner, true)
StaffMenu.animatorStandaloneOptions = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "OPTIONS ANIMATEUR", animatorBanner, true)
StaffMenu.animatorStandaloneAnnounce = VUI:CreateSubMenu(StaffMenu.animatorStandaloneOptions, "ANNONCES", animatorBanner, true)
StaffMenu.animatorStandaloneActions = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "ACTIONS PERSONNELLES", animatorBanner, true)
StaffMenu.animatorStandaloneGiveItem = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "DONNER ITEM TEMPORAIRE", animatorBanner, true)
StaffMenu.animatorStandaloneGiveItemDuration = VUI:CreateSubMenu(StaffMenu.animatorStandaloneGiveItem, "CHOISIR DURÉE", animatorBanner, true)
StaffMenu.animatorStandaloneVehicles = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "VÉHICULES", animatorBanner, true)
StaffMenu.animatorStandaloneVehicleCustom = VUI:CreateSubMenu(StaffMenu.animatorStandaloneVehicles, ":wrench: CUSTOM VÉHICULE", animatorBanner, true)
StaffMenu.animatorStandalonePedManagement = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "GESTION DES PEDS", animatorBanner, true)
StaffMenu.animatorStandalonePedList = VUI:CreateSubMenu(StaffMenu.animatorStandalonePedManagement, "LISTE DES PEDS", animatorBanner, true)

-- SAMS Management submenus
StaffMenu.samsManagement = VUI:CreateSubMenu(StaffMenu.builders, "GESTION SAMS", adminBanner, true)
StaffMenu.samsAnnonces = VUI:CreateSubMenu(StaffMenu.samsManagement, "ANNONCES SAMS", adminBanner, true)
StaffMenu.samsAnnonceDetail = VUI:CreateSubMenu(StaffMenu.samsAnnonces, "DETAIL ANNONCE", adminBanner, true)
StaffMenu.samsRapports = VUI:CreateSubMenu(StaffMenu.samsManagement, "RAPPORTS SAMS", adminBanner, true)
StaffMenu.samsRapportDetail = VUI:CreateSubMenu(StaffMenu.samsRapports, "DETAIL RAPPORT", adminBanner, true)
StaffMenu.samsFactures = VUI:CreateSubMenu(StaffMenu.samsManagement, "FACTURES SAMS", adminBanner, true)
StaffMenu.samsFactureDetail = VUI:CreateSubMenu(StaffMenu.samsFactures, "DETAIL FACTURE", adminBanner, true)
StaffMenu.samsPerms = VUI:CreateSubMenu(StaffMenu.samsManagement, "PERMISSIONS SAMS", adminBanner, true)
StaffMenu.samsPermGrades = VUI:CreateSubMenu(StaffMenu.samsPerms, "GRADES DE L'HÔPITAL", adminBanner, true)
StaffMenu.samsPermDetail = VUI:CreateSubMenu(StaffMenu.samsPermGrades, "PERMISSIONS DU GRADE", adminBanner, true)

StaffMenu.global = VUI:CreateSubMenu(StaffMenu.main, "GESTION DE GLOBAL", adminBanner, true)
StaffMenu.builders = VUI:CreateSubMenu(StaffMenu.global, "BUILDERS", adminBanner, false)

StaffMenu.factionMenu.parent = StaffMenu.builders
StaffMenu.samsManagement.parent = StaffMenu.builders

StaffMenu.builderFarm = VUI:CreateSubMenu(StaffMenu.builders, "FARM", adminBanner, true)
StaffMenu.builderFarmOptions = VUI:CreateSubMenu(StaffMenu.builderFarm, "OPTIONS", adminBanner, true)

StaffMenu.builder_elevators = VUI:CreateSubMenu(StaffMenu.builders, "ASCENSEURS", adminBanner, true)
StaffMenu.CreateElevator = VUI:CreateSubMenu(StaffMenu.builder_elevators, "CRÉER UN ASCENSEUR", adminBanner, true)
StaffMenu.ManageCreationFloor = VUI:CreateSubMenu(StaffMenu.CreateElevator, "GÉRER L'ÉTAGE", adminBanner, true)
StaffMenu.ManageElevator = VUI:CreateSubMenu(StaffMenu.builder_elevators, "GÉRER L'ASCENSEUR", adminBanner, true)
StaffMenu.ManageFloor = VUI:CreateSubMenu(StaffMenu.ManageElevator, "GÉRER L'ÉTAGE", adminBanner, true)

StaffMenu.builderChest = VUI:CreateSubMenu(StaffMenu.builders, "Coffre", adminBanner, true)
StaffMenu.builderTeleport = VUI:CreateSubMenu(StaffMenu.builders, "TÉLÉPORTATION", adminBanner, true)
StaffMenu.CreateTeleport = VUI:CreateSubMenu(StaffMenu.builderTeleport, "CRÉER UN POINT", adminBanner, true)
StaffMenu.TeleportList = VUI:CreateSubMenu(StaffMenu.builderTeleport, "LISTE DES POINTS", adminBanner, true)
StaffMenu.TeleportManage = VUI:CreateSubMenu(StaffMenu.TeleportList, "GÉRER LE POINT", adminBanner, true)
StaffMenu.builderDeposit = VUI:CreateSubMenu(StaffMenu.builders, "DÉPÔTS", adminBanner, true)
StaffMenu.CreateDeposit = VUI:CreateSubMenu(StaffMenu.builderDeposit, "CRÉER UN DÉPÔT", adminBanner, true)
StaffMenu.DepositConsultJobs = VUI:CreateSubMenu(StaffMenu.CreateDeposit, "JOBS POLICE CONSULTABLES", adminBanner, true)
StaffMenu.DepositList = VUI:CreateSubMenu(StaffMenu.builderDeposit, "LISTE DES DÉPÔTS", adminBanner, true)
StaffMenu.DepositManage = VUI:CreateSubMenu(StaffMenu.DepositList, "GÉRER LE DÉPÔT", adminBanner, true)
StaffMenu.builderZoneSafe = VUI:CreateSubMenu(StaffMenu.builders, "ZONE SAFE", adminBanner, true)
StaffMenu.builderDJ = VUI:CreateSubMenu(StaffMenu.builders, "DJ", adminBanner, true)
StaffMenu.builderBlips = VUI:CreateSubMenu(StaffMenu.builders, "BLIPS", adminBanner, true)
StaffMenu.builderBraquage = VUI:CreateSubMenu(StaffMenu.builders, "BRAQUAGE", adminBanner, true)
StaffMenu.builderDoorlock = VUI:CreateSubMenu(StaffMenu.builders, "DOORLOCK", adminBanner, true)
StaffMenu.builderLocker = VUI:CreateSubMenu(StaffMenu.builders, "VESTIAIRES", adminBanner, true)
StaffMenu.builderSocietyLocker = VUI:CreateSubMenu(StaffMenu.builders, "CASIERS SOCIÉTÉ", adminBanner, true)
StaffMenu.builderCarRental = VUI:CreateSubMenu(StaffMenu.builders, "LOCATION DE VEHICULE", adminBanner, true)

StaffMenu.builderAmbientSound = VUI:CreateSubMenu(StaffMenu.builders, "SONS D'AMBIANCES", adminBanner, true)
StaffMenu.builderAmbientSoundCreate = VUI:CreateSubMenu(StaffMenu.builderAmbientSound, "CRÉER UNE ZONE SONORE", adminBanner, true)
StaffMenu.builderAmbientSoundList = VUI:CreateSubMenu(StaffMenu.builderAmbientSound, "LISTE DES ZONES SONORES", adminBanner, true)
StaffMenu.builderAmbientSoundManage = VUI:CreateSubMenu(StaffMenu.builderAmbientSoundList, "GÉRER LA ZONE SONORE", adminBanner, true)

StaffMenu.builderVoiceRestriction = VUI:CreateSubMenu(StaffMenu.builders, "RESTRICTION VOCALE", adminBanner, true)
StaffMenu.builderVoiceRestrictionCreate = VUI:CreateSubMenu(StaffMenu.builderVoiceRestriction, "CREER UNE ZONE", adminBanner, true)
StaffMenu.builderVoiceRestrictionList = VUI:CreateSubMenu(StaffMenu.builderVoiceRestriction, "LISTE DES ZONES", adminBanner, true)
StaffMenu.builderVoiceRestrictionManage = VUI:CreateSubMenu(StaffMenu.builderVoiceRestrictionList, "GERER LA ZONE", adminBanner, true)
StaffMenu.builderVoiceRestrictionBypass = VUI:CreateSubMenu(StaffMenu.builderVoiceRestrictionCreate, "BY-PASS JOBS", adminBanner, true)

-- Television Builder
StaffMenu.builderTelevision = VUI:CreateSubMenu(StaffMenu.builders, "GESTION TV", adminBanner, true)
StaffMenu.builderTelevisionAdd = VUI:CreateSubMenu(StaffMenu.builderTelevision, "AJOUTER UN MODELE TV", adminBanner, true)
StaffMenu.builderTelevisionEdit = VUI:CreateSubMenu(StaffMenu.builderTelevision, "MODIFIER UN MODELE TV", adminBanner, true)
StaffMenu.builderTelevisionTarget = VUI:CreateSubMenu(nil, "RENDER TARGET", adminBanner, true)

-- Recording Studios Builder
StaffMenu.builderStudio = VUI:CreateSubMenu(StaffMenu.builders, "STUDIOS D'ENREGISTREMENT", adminBanner, true)
StaffMenu.CreateStudio = VUI:CreateSubMenu(StaffMenu.builderStudio, "CREER UN STUDIO", adminBanner, true)
StaffMenu.ManageStudios = VUI:CreateSubMenu(StaffMenu.builderStudio, "GERER LES STUDIOS", adminBanner, true)
StaffMenu.StudioManage = VUI:CreateSubMenu(StaffMenu.ManageStudios, "GERER LE STUDIO", adminBanner, true)
StaffMenu.StudioSelectScope = VUI:CreateSubMenu(StaffMenu.CreateStudio, "TYPE D'ACCES", adminBanner, true)
StaffMenu.StudioSelectJob = VUI:CreateSubMenu(StaffMenu.StudioSelectScope, "SELECTIONNER UN JOB", adminBanner, true)
StaffMenu.StudioEditScope = VUI:CreateSubMenu(StaffMenu.StudioManage, "MODIFIER L'ACCES", adminBanner, true)
StaffMenu.StudioEditSelectJob = VUI:CreateSubMenu(StaffMenu.StudioEditScope, "SELECTIONNER UN JOB", adminBanner, true)

-- Chair Sit Config Builder
StaffMenu.builderChairs = VUI:CreateSubMenu(StaffMenu.builders, "CHAISES ASSISES", adminBanner, true)
StaffMenu.builderChairsEdit = VUI:CreateSubMenu(StaffMenu.builderChairs, "CONFIGURER CHAISE", adminBanner, true)
StaffMenu.builderChairsPreview = VUI:CreateSubMenu(StaffMenu.builderChairsEdit, "PREVIEW ANIMATION", adminBanner, true)

-- Object Freeze Builder
StaffMenu.builderObjectFreeze = VUI:CreateSubMenu(StaffMenu.builders, "FREEZE OBJETS", adminBanner, true)

-- Motel Builder
StaffMenu.builderMotel = VUI:CreateSubMenu(StaffMenu.builders, "GESTION MOTELS", adminBanner, true)
StaffMenu.motelCreate = VUI:CreateSubMenu(StaffMenu.builderMotel, "CRÉER UN MOTEL", adminBanner, true)
StaffMenu.motelManage = VUI:CreateSubMenu(StaffMenu.builderMotel, "GÉRER UN MOTEL", adminBanner, true)
StaffMenu.motelEdit = VUI:CreateSubMenu(StaffMenu.motelManage, "MODIFIER LE MOTEL", adminBanner, true)
StaffMenu.motelEditPricing = VUI:CreateSubMenu(StaffMenu.motelEdit, "TARIFS", adminBanner, true)
StaffMenu.motelEditChest = VUI:CreateSubMenu(StaffMenu.motelEdit, "COFFRES", adminBanner, true)
StaffMenu.motelEditPosition = VUI:CreateSubMenu(StaffMenu.motelEdit, "POSITION", adminBanner, true)
StaffMenu.motelRooms = VUI:CreateSubMenu(StaffMenu.motelEdit, "GÉRER LES CHAMBRES", adminBanner, true)
StaffMenu.motelAddRoom = VUI:CreateSubMenu(StaffMenu.motelRooms, "AJOUTER UNE CHAMBRE", adminBanner, true)
StaffMenu.motelRoomDetail = VUI:CreateSubMenu(StaffMenu.motelRooms, "DÉTAIL CHAMBRE", adminBanner, true)
StaffMenu.motelAssignPlayer = VUI:CreateSubMenu(StaffMenu.motelRoomDetail, "ATTRIBUER", adminBanner, true)
StaffMenu.motelRoomEdit = VUI:CreateSubMenu(StaffMenu.motelRoomDetail, "MODIFIER CHAMBRE", adminBanner, true)
StaffMenu.motelAddRoomPromos = VUI:CreateSubMenu(StaffMenu.motelAddRoom, "PROMOTIONS CHAMBRE", adminBanner, true)
StaffMenu.motelAddDoorActions = VUI:CreateSubMenu(StaffMenu.motelAddRoom, "ACTIONS PORTE", adminBanner, true)
StaffMenu.motelEditRoomPromos = VUI:CreateSubMenu(StaffMenu.motelRoomEdit, "PROMOTIONS CHAMBRE", adminBanner, true)
StaffMenu.motelEditDoorActions = VUI:CreateSubMenu(StaffMenu.motelRoomEdit, "ACTIONS PORTE", adminBanner, true)

-- Motel Logs (inside motel edit)
StaffMenu.motelLogs = VUI:CreateSubMenu(StaffMenu.motelEdit, "LOGS", adminBanner, true)

-- Gestion Bâtiments

StaffMenu.batiment = VUI:CreateSubMenu(StaffMenu.builders, "GESTION BÂTIMENTS", adminBanner, true)
StaffMenu.batimentEglises = VUI:CreateSubMenu(StaffMenu.batiment, "ÉGLISES", adminBanner, true)
StaffMenu.batimentMBA = VUI:CreateSubMenu(StaffMenu.batiment, "MAZE BANK ARENA", adminBanner, true)

-- Vehicle Sell Builder
StaffMenu.builderVehicleSell = VUI:CreateSubMenu(StaffMenu.builders, "VENTE VEHICULES", adminBanner, true)
StaffMenu.vehicleSellCreate = VUI:CreateSubMenu(StaffMenu.builderVehicleSell, "CREER LOCATION", adminBanner, true)
StaffMenu.vehicleSellList = VUI:CreateSubMenu(StaffMenu.builderVehicleSell, "GERER LOCATIONS", adminBanner, true)
StaffMenu.vehicleSellEdit = VUI:CreateSubMenu(StaffMenu.vehicleSellList, "MODIFIER LOCATION", adminBanner, true)
StaffMenu.vehicleSellParking = VUI:CreateSubMenu(StaffMenu.vehicleSellEdit, "EMPLACEMENTS PARKING", adminBanner, true)
StaffMenu.vehicleSellCreateParking = VUI:CreateSubMenu(StaffMenu.vehicleSellCreate, "EMPLACEMENTS PARKING", adminBanner, true)
StaffMenu.vehicleSellSettings = VUI:CreateSubMenu(StaffMenu.vehicleSellEdit, "PARAMETRES", adminBanner, true)

-- Vehicle Storage Builder
StaffMenu.builderVehicleStorage = VUI:CreateSubMenu(StaffMenu.builders, "STOCKAGE VEHICULES", adminBanner, true)
StaffMenu.vehicleStorageCreate = VUI:CreateSubMenu(StaffMenu.builderVehicleStorage, "AJOUTER VEHICULE", adminBanner, true)
StaffMenu.vehicleStorageList = VUI:CreateSubMenu(StaffMenu.builderVehicleStorage, "LISTE VEHICULES", adminBanner, true)
StaffMenu.vehicleStorageSearch = VUI:CreateSubMenu(StaffMenu.builderVehicleStorage, "RECHERCHER", adminBanner, true)
StaffMenu.vehicleStorageEdit = VUI:CreateSubMenu(StaffMenu.vehicleStorageList, "MODIFIER VEHICULE", adminBanner, true)

-- Custom Prices Builder
StaffMenu.builderCustomPrices = VUI:CreateSubMenu(StaffMenu.builders, "PRIX CUSTOM", adminBanner, true)
StaffMenu.customPricesBase = VUI:CreateSubMenu(StaffMenu.builderCustomPrices, "PRIX DE BASE", adminBanner, true)
StaffMenu.customPricesCategories = VUI:CreateSubMenu(StaffMenu.builderCustomPrices, "% PAR CATEGORIE", adminBanner, true)
StaffMenu.customPricesCategoryEdit = VUI:CreateSubMenu(StaffMenu.customPricesCategories, "MODIFIER CATEGORIE", adminBanner, true)
StaffMenu.customPricesModels = VUI:CreateSubMenu(StaffMenu.builderCustomPrices, "% PAR MODELE", adminBanner, true)
StaffMenu.customPricesModelEdit = VUI:CreateSubMenu(StaffMenu.customPricesModels, "MODIFIER MODELE", adminBanner, true)

-- Deleted Properties Builder
StaffMenu.builderDeletedProps = VUI:CreateSubMenu(StaffMenu.builders, "PROPRIÉTÉS SUPPRIMÉES", adminBanner, true)
StaffMenu.deletedPropDetails = VUI:CreateSubMenu(StaffMenu.builderDeletedProps, "DÉTAILS", adminBanner, true)
StaffMenu.deletedPropChestItems = VUI:CreateSubMenu(StaffMenu.deletedPropDetails, "CONTENU COFFRE", adminBanner, true)

-- Property Logs Builder
StaffMenu.builderPropertyLogs = VUI:CreateSubMenu(StaffMenu.builders, "LOGS PROPRIETES", adminBanner, true)
StaffMenu.propertyLogsProperties = VUI:CreateSubMenu(StaffMenu.builderPropertyLogs, "PROPRIETES AVEC LOGS", adminBanner, true)
StaffMenu.propertyLogsList = VUI:CreateSubMenu(StaffMenu.builderPropertyLogs, "LISTE DES LOGS", adminBanner, true)

-- Gouvernement Logs Builders
StaffMenu.builderGouvLogsActions = VUI:CreateSubMenu(StaffMenu.builderGouv, "LOGS ACTIONS", adminBanner, true)
StaffMenu.builderGouvLogsMDT = VUI:CreateSubMenu(StaffMenu.builderGouv, "LOGS MDT", adminBanner, true)

-- Staff Property Management (Outils de modération)
StaffMenu.builderProperties = VUI:CreateSubMenu(StaffMenu.outils, "GESTION PROPRIETES", adminBanner, true)
StaffMenu.builderPropertiesList = VUI:CreateSubMenu(StaffMenu.builderProperties, "LISTE PROPRIETES", adminBanner, true)

-- Dynasty Prices Builder
StaffMenu.builderDynastyPrices = VUI:CreateSubMenu(StaffMenu.builders, "GESTION DYNASTY", adminBanner, true)
StaffMenu.dynastyPricesCategory = VUI:CreateSubMenu(StaffMenu.builderDynastyPrices, "CATÉGORIE", adminBanner, true)
StaffMenu.dynastyPricesEdit = VUI:CreateSubMenu(StaffMenu.dynastyPricesCategory, "MODIFIER PROPRIÉTÉ", adminBanner, true)

-- LTD Items Builder
StaffMenu.builderLTDItems = VUI:CreateSubMenu(StaffMenu.builders, "GESTION ITEMS LTD", adminBanner, true)
StaffMenu.ltdItemEdit = VUI:CreateSubMenu(StaffMenu.builderLTDItems, "MODIFIER ITEM LTD", adminBanner, true)

-- PNJ Spawn Lines Builder (VFW.PNJ)
StaffMenu.builderPNJ = VUI:CreateSubMenu(StaffMenu.builders, "SPAWN PNJ", adminBanner, true)
StaffMenu.builderPNJManage = VUI:CreateSubMenu(StaffMenu.builderPNJ, "GÉRER LA LIGNE", adminBanner, true)

-- Legal Activities Builder
StaffMenu.builderLegalActivities = VUI:CreateSubMenu(StaffMenu.builders, "ACTIVITÉS LÉGALES", adminBanner, true)
StaffMenu.legalActFishing = VUI:CreateSubMenu(StaffMenu.builderLegalActivities, "PÊCHE", adminBanner, true)
StaffMenu.legalActHunting = VUI:CreateSubMenu(StaffMenu.builderLegalActivities, "CHASSE", adminBanner, true)
StaffMenu.legalActDiving = VUI:CreateSubMenu(StaffMenu.builderLegalActivities, "PLONGÉE", adminBanner, true)
StaffMenu.legalActSellerManage = VUI:CreateSubMenu(nil, "GÉRER LE VENDEUR", adminBanner, true)

StaffMenu.builderProps = VUI:CreateSubMenu(StaffMenu.builders, "PROPS", adminBanner, true)
StaffMenu.CreateProps = VUI:CreateSubMenu(StaffMenu.builderProps, "CRÉATION DE PROPS", adminBanner, true)
StaffMenu.CreateCategorySelection = VUI:CreateSubMenu(StaffMenu.CreateProps, "SÉLECTION CATÉGORIE", adminBanner, true)
StaffMenu.PropsList = VUI:CreateSubMenu(StaffMenu.builderProps, "LISTE DES PROPS", adminBanner, true)
StaffMenu.PropManage = VUI:CreateSubMenu(StaffMenu.PropsList, "GÉRER LE PROPS", adminBanner, true)
StaffMenu.EditProp = VUI:CreateSubMenu(StaffMenu.PropManage, "MODIFIER LE PROPS", adminBanner, true)
StaffMenu.CategorySelection = VUI:CreateSubMenu(StaffMenu.EditProp, "SÉLECTION CATÉGORIE", adminBanner, true)
StaffMenu.VipPropsList = VUI:CreateSubMenu(StaffMenu.builderProps, "PROPS VIP", adminBanner, true)
StaffMenu.VipPropsPlayer = VUI:CreateSubMenu(StaffMenu.VipPropsList, "PROPS DU JOUEUR", adminBanner, true)
StaffMenu.VipPropDetail = VUI:CreateSubMenu(StaffMenu.VipPropsPlayer, "DÉTAIL DU PROP", adminBanner, true)


-- Gas Station submenus
StaffMenu.gasStationMain = VUI:CreateSubMenu(StaffMenu.builders, "GÉRER LES STATIONS ESSENCE", adminBanner, true)
StaffMenu.gasStationBuilder = VUI:CreateSubMenu(StaffMenu.gasStationMain, "CRÉER UNE STATION", adminBanner, true)
StaffMenu.gasStationConfig = VUI:CreateSubMenu(StaffMenu.gasStationMain, "GÉRER LES STATIONS CRÉÉES", adminBanner, true)
StaffMenu.gasStationList = VUI:CreateSubMenu(StaffMenu.gasStationConfig, "LISTE DES STATIONS", adminBanner, true)
StaffMenu.gasStationDetails = VUI:CreateSubMenu(StaffMenu.gasStationList, "DÉTAILS DE LA STATION", adminBanner, true)

StaffMenu.builderLabo = VUI:CreateSubMenu(StaffMenu.builders, "LABORATOIRES", adminBanner, true)
StaffMenu.builderLaboCreate = VUI:CreateSubMenu(StaffMenu.builderLabo, "LABO", adminBanner, true)
StaffMenu.builderLaboHarvestList = VUI:CreateSubMenu(StaffMenu.builderLaboCreate, "POINTS DE RECOLTE", adminBanner, true)
StaffMenu.builderLaboHarvestCreate = VUI:CreateSubMenu(StaffMenu.builderLaboHarvestList, "RECOLTE", adminBanner, true)
StaffMenu.builderLaboTransformList = VUI:CreateSubMenu(StaffMenu.builderLaboCreate, "POINTS DE TRANSFO", adminBanner, true)
StaffMenu.builderLaboTransformCreate = VUI:CreateSubMenu(StaffMenu.builderLaboTransformList, "TRANSFORMATION", adminBanner, true)
StaffMenu.builderLaboAttackSlots = VUI:CreateSubMenu(StaffMenu.builderLaboCreate, "TRANCHES HORAIRES", adminBanner, true)
StaffMenu.builderLaboFaction = VUI:CreateSubMenu(StaffMenu.builderLaboCreate, "FACTION", adminBanner, true)
StaffMenu.builderLaboPlayerSelect = VUI:CreateSubMenu(StaffMenu.builderLaboFaction, "JOUEUR", adminBanner, true)
StaffMenu.builderLaboTemplatePicker = VUI:CreateSubMenu(StaffMenu.builderLaboCreate, "TEMPLATE", adminBanner, true)
StaffMenu.builderLaboManage = VUI:CreateSubMenu(StaffMenu.builderLabo, "GÉRER LABO", adminBanner, true)
StaffMenu.builderLaboTemplateList = VUI:CreateSubMenu(StaffMenu.builderLabo, "TEMPLATES", adminBanner, true)
StaffMenu.builderLaboTemplateManage = VUI:CreateSubMenu(StaffMenu.builderLaboTemplateList, "TEMPLATE", adminBanner, true)
StaffMenu.builderLaboTemplateHarvestList = VUI:CreateSubMenu(StaffMenu.builderLaboTemplateManage, "POINTS DE RÉCOLTE", adminBanner, true)
StaffMenu.builderLaboTemplateHarvestCreate = VUI:CreateSubMenu(StaffMenu.builderLaboTemplateHarvestList, "RÉCOLTE", adminBanner, true)
StaffMenu.builderLaboTemplateTransformList = VUI:CreateSubMenu(StaffMenu.builderLaboTemplateManage, "POINTS DE TRANSFO", adminBanner, true)
StaffMenu.builderLaboTemplateTransformCreate = VUI:CreateSubMenu(StaffMenu.builderLaboTemplateTransformList, "TRANSFORMATION", adminBanner, true)
StaffMenu.builderLaboAttackConfig = VUI:CreateSubMenu(StaffMenu.builderLabo, "CONFIG ATTAQUE", adminBanner, true)

StaffMenu.developers = VUI:CreateSubMenu(StaffMenu.global, "DÉVELOPPEURS", adminBanner, true)
StaffMenu.bypassCooldown = VUI:CreateSubMenu(StaffMenu.developers, "BYPASS COOLDOWN", adminBanner, true)
StaffMenu.cooldownCommandsMenu = VUI:CreateSubMenu(StaffMenu.bypassCooldown, "GESTION DES COMMANDES", adminBanner, true)
StaffMenu.cooldownEditMenu = VUI:CreateSubMenu(StaffMenu.cooldownCommandsMenu, "ÉDITER COMMANDE", adminBanner, true)
StaffMenu.inventoryRestore = VUI:CreateSubMenu(StaffMenu.developers, "RESTAURATION INVENTAIRE", adminBanner, true)
StaffMenu.inventoryRestoreDetail = VUI:CreateSubMenu(StaffMenu.inventoryRestore, "DÉTAIL SNAPSHOT", adminBanner, true)
StaffMenu.antibanMenu = VUI:CreateSubMenu(StaffMenu.developers, "ANTIBAN", adminBanner, true)
StaffMenu.resetSanctions = VUI:CreateSubMenu(StaffMenu.developers, "RESET SANCTIONS", adminBanner, true)
StaffMenu.resetSanctionsConfirm = VUI:CreateSubMenu(StaffMenu.resetSanctions, "CONFIRMER LE RESET", adminBanner, true)
StaffMenu.camera = VUI:CreateSubMenu(StaffMenu.developers, "CRÉATION DE CAM", adminBanner, true)
StaffMenu.weapon = VUI:CreateSubMenu(StaffMenu.developers, "COMPOSANTS D'ARMES", adminBanner, true)
StaffMenu.gestionItems = VUI:CreateSubMenu(StaffMenu.developers, "GESTION DES ITEMS", adminBanner, true)
StaffMenu.selectItem = VUI:CreateSubMenu(StaffMenu.gestionItems, "GESTION DES ITEMS", adminBanner, true)
StaffMenu.editGestionItem = VUI:CreateSubMenu(StaffMenu.gestionItems, "MODIFIER L'ITEM", adminBanner, true)
StaffMenu.createItem = VUI:CreateSubMenu(StaffMenu.gestionItems, "CRÉATION D'ITEMS", adminBanner, true)
StaffMenu.giveAllItems = VUI:CreateSubMenu(StaffMenu.developers, "DONNER ITEM À TOUS", adminBanner, true)
StaffMenu.potionsMenu = VUI:CreateSubMenu(StaffMenu.developers, "POTIONS", adminBanner, true)
StaffMenu.propPlacer = VUI:CreateSubMenu(StaffMenu.developers, "PROP PLACER", adminBanner, true)
StaffMenu.weightManagement = VUI:CreateSubMenu(StaffMenu.developers, "GESTION POIDS", adminBanner, true)
StaffMenu.weightDuration = VUI:CreateSubMenu(StaffMenu.weightManagement, "DURÉE DU POIDS", adminBanner, true)
StaffMenu.weightCharSelect = VUI:CreateSubMenu(StaffMenu.weightManagement, "CHOIX PERSONNAGE", adminBanner, true)

-- Map Coords (Dev only)
StaffMenu.mapCoords = VUI:CreateSubMenu(StaffMenu.developers, "LISTE DES MAPPINGS", adminBanner, true)
StaffMenu.createMapCoord = VUI:CreateSubMenu(StaffMenu.mapCoords, "AJOUTER UN MAPPING", adminBanner, true)
StaffMenu.manageMapCoords = VUI:CreateSubMenu(StaffMenu.mapCoords, "LISTE DES MAPPINGS", adminBanner, true)
StaffMenu.editMapCoord = VUI:CreateSubMenu(StaffMenu.manageMapCoords, "GÉRER LE MAPPING", adminBanner, true)

StaffMenu.starterPack = VUI:CreateSubMenu(StaffMenu.developers, "STARTER PACK", adminBanner, true)
StaffMenu.bagWeightBuilder = VUI:CreateSubMenu(StaffMenu.developers, "POIDS DES SACS", adminBanner, true)
StaffMenu.gpbPlatesBuilder = VUI:CreateSubMenu(StaffMenu.developers, "PLAQUES GPB", adminBanner, true)
StaffMenu.staffLogs = VUI:CreateSubMenu(StaffMenu.developers, "STAFF LOGS", adminBanner, true)
StaffMenu.staffLogsRecent = VUI:CreateSubMenu(StaffMenu.staffLogs, "LOGS RÉCENTS", adminBanner, true)
StaffMenu.staffLogsDetail = VUI:CreateSubMenu(StaffMenu.staffLogsRecent, "DÉTAIL DU LOG", adminBanner, true)
StaffMenu.staffLogsQueue = VUI:CreateSubMenu(StaffMenu.staffLogs, "FILE D'ATTENTE", adminBanner, true)
StaffMenu.staffLogsQueueDetail = VUI:CreateSubMenu(StaffMenu.staffLogsQueue, "DÉTAIL DU LOG", adminBanner, true)

-- Webhooks Logs (Dev only)
StaffMenu.webhookLogs = VUI:CreateSubMenu(StaffMenu.developers, "WEBHOOKS LOGS", adminBanner, true)
StaffMenu.webhookLogsEdit = VUI:CreateSubMenu(StaffMenu.webhookLogs, "WEBHOOK", adminBanner, true)

-- Phone Management (Dev only)
StaffMenu.gestionPhone = VUI:CreateSubMenu(StaffMenu.developers, "GESTION TÉLÉPHONE", adminBanner, true)
StaffMenu.gestionPhoneApps = VUI:CreateSubMenu(StaffMenu.gestionPhone, "APPLICATIONS", adminBanner, true)
StaffMenu.gestionPhoneCertifs = VUI:CreateSubMenu(StaffMenu.gestionPhoneApps, "CERTIFICATIONS", adminBanner, true)
StaffMenu.gestionPhoneHistory = VUI:CreateSubMenu(StaffMenu.gestionPhoneApps, "HISTORIQUE", adminBanner, true)

-- Vehicle Blacklist (Dev only)
StaffMenu.vehBlacklist = VUI:CreateSubMenu(StaffMenu.developers, "VEHICULE BLACKLIST", adminBanner, true)

-- Animation Manager (Dev only)
StaffMenu.animManager = VUI:CreateSubMenu(StaffMenu.developers, "ANIMATION MANAGER", adminBanner, true)
StaffMenu.animManagerList = VUI:CreateSubMenu(StaffMenu.animManager, "ANIMATIONS", adminBanner, true)
StaffMenu.animManagerEdit = VUI:CreateSubMenu(StaffMenu.animManagerList, "MODIFIER ANIMATION", adminBanner, true)
StaffMenu.animManagerCategory = VUI:CreateSubMenu(StaffMenu.animManagerEdit, "CHANGER CATÉGORIE", adminBanner, true)

StaffMenu.builderATM = VUI:CreateSubMenu(StaffMenu.builders, "BRAQUAGES ATM", adminBanner, true)
StaffMenu.ListCustomATMsMenu = VUI:CreateSubMenu(StaffMenu.builderATM, "LISTE DES ATM CUSTOMS", adminBanner, true)
StaffMenu.EditCustomATMMenu = VUI:CreateSubMenu(StaffMenu.ListCustomATMsMenu, "ÉDITER ATM", adminBanner, true)
StaffMenu.builderFleeca = VUI:CreateSubMenu(StaffMenu.builders, "BANQUES FLEECA", adminBanner, true)
StaffMenu.builderPacific = VUI:CreateSubMenu(StaffMenu.builders, "BANQUES PACIFIC", adminBanner, true)
StaffMenu.builderJewelry = VUI:CreateSubMenu(StaffMenu.builders, "BIJOUTERIE", adminBanner, true)

StaffMenu.builderDOJ = VUI:CreateSubMenu(StaffMenu.builders, "DOJ PERMISSIONS", adminBanner, true)
StaffMenu.builderDOJPerms = VUI:CreateSubMenu(StaffMenu.builderDOJ, "PERMISSIONS GRADE", adminBanner, true)
StaffMenu.builderFines = VUI:CreateSubMenu(StaffMenu.builders, "AMENDES POLICE", adminBanner, true)
StaffMenu.builderFinesAdd = VUI:CreateSubMenu(StaffMenu.builderFines, "AJOUTER UNE AMENDE", adminBanner, true)
StaffMenu.builderFinesEdit = VUI:CreateSubMenu(StaffMenu.builderFines, "MODIFIER AMENDE", adminBanner, true)
StaffMenu.builderSupermarket = VUI:CreateSubMenu(StaffMenu.builders, "SUPERETTE", adminBanner, true)
StaffMenu.builderFireworkCreate = VUI:CreateSubMenu(StaffMenu.builderFirework, "CRÉER UNE BOUTIQUE", adminBanner, true)
StaffMenu.builderFireworkManage = VUI:CreateSubMenu(StaffMenu.builderFirework, "GÉRER LES BOUTIQUES", adminBanner, true)
StaffMenu.builderFireworkEdit = VUI:CreateSubMenu(StaffMenu.builderFireworkManage, "ÉDITER BOUTIQUE", adminBanner, true)
StaffMenu.builderFireworkItems = VUI:CreateSubMenu(StaffMenu.builderFirework, "GÉRER LES ARTICLES", adminBanner, true)
StaffMenu.builderFireworkItemCreate = VUI:CreateSubMenu(StaffMenu.builderFireworkItems, "AJOUTER UN ARTICLE", adminBanner, true)
StaffMenu.builderFireworkItemEdit = VUI:CreateSubMenu(StaffMenu.builderFireworkItems, "ÉDITER ARTICLE", adminBanner, true)
StaffMenu.builderFireworkSettings = VUI:CreateSubMenu(StaffMenu.builderFirework, "PARAMÈTRES ÉCONOMIE", adminBanner, true)
-- Market Builder
StaffMenu.builderMarket = VUI:CreateSubMenu(StaffMenu.builders, "MARKET", adminBanner, true)
StaffMenu.builderMarketCreate = VUI:CreateSubMenu(StaffMenu.builderMarket, "+ AJOUTER UN JOB", adminBanner, true)
StaffMenu.builderMarketList = VUI:CreateSubMenu(StaffMenu.builderMarket, "LISTE DES JOBS", adminBanner, true)
StaffMenu.builderMarketEdit = VUI:CreateSubMenu(StaffMenu.builderMarketList, "ÉDITER JOB", adminBanner, true)
StaffMenu.builderMarketEditGrades = VUI:CreateSubMenu(StaffMenu.builderMarketEdit, "GRADES AUTORISÉS", adminBanner, true)
StaffMenu.builderMarketItems = VUI:CreateSubMenu(StaffMenu.builderMarketEdit, "ITEMS", adminBanner, true)
StaffMenu.builderMarketAddItem = VUI:CreateSubMenu(StaffMenu.builderMarketItems, "AJOUTER ITEM", adminBanner, true)
-- submenu used to configure price/category after picking from the browser
StaffMenu.builderMarketAddItemConfig = VUI:CreateSubMenu(StaffMenu.builderMarketAddItem, "CONFIGURATION ITEM", adminBanner, true)

StaffMenu.builderMarketEditItem = VUI:CreateSubMenu(StaffMenu.builderMarketItems, "ÉDITER ITEM", adminBanner, true)
StaffMenu.builderMarketDelivery = VUI:CreateSubMenu(StaffMenu.builderMarket, ":settings: CONFIGURATION MARKET", adminBanner, true)

-- Categories for Market (per-job categories)
StaffMenu.builderMarketCategories = VUI:CreateSubMenu(StaffMenu.builderMarketEdit, "CATEGORIES", adminBanner, true)
StaffMenu.builderMarketAddCategory = VUI:CreateSubMenu(StaffMenu.builderMarketCategories, "AJOUTER CATEGORIE", adminBanner, true)
StaffMenu.builderMarketEditCategory = VUI:CreateSubMenu(StaffMenu.builderMarketCategories, "MODIFIER CATEGORIE", adminBanner, true)
-- Picker used when adding/editing an item to choose a category
StaffMenu.builderMarketChooseCategory = VUI:CreateSubMenu(StaffMenu.builderMarketAddItem, "CHOISIR CATEGORIE", adminBanner, true)
-- Separate chooser attached to edit-item menu so it can be opened while editing
StaffMenu.builderMarketChooseCategoryEdit = VUI:CreateSubMenu(StaffMenu.builderMarketEditItem, "CHOISIR CATEGORIE", adminBanner, true)
-- Separate chooser for config menu to avoid closing to item list
StaffMenu.builderMarketChooseCategoryConfig = VUI:CreateSubMenu(StaffMenu.builderMarketAddItemConfig, "CHOISIR CATEGORIE", adminBanner, true)

StaffMenu.builderZombie = VUI:CreateSubMenu(StaffMenu.builders, "ZONES ZOMBIE", adminBanner, true)
StaffMenu.builderZombieList = VUI:CreateSubMenu(StaffMenu.builderZombie, "LISTE DES ZONES", adminBanner, true)
StaffMenu.builderZombieEdit = VUI:CreateSubMenu(StaffMenu.builderZombieList, "EDITER ZONE", adminBanner, true)

StaffMenu.builderGoFast = VUI:CreateSubMenu(StaffMenu.builders, "GO FAST", adminBanner, true)
StaffMenu.builderDrugDealing = VUI:CreateSubMenu(StaffMenu.builders, "VENTE DE DROGUE", adminBanner, true)
StaffMenu.builderBlackmarket = VUI:CreateSubMenu(StaffMenu.builders, "BLACK MARKET", adminBanner, true)
StaffMenu.builderWhitening = VUI:CreateSubMenu(StaffMenu.builders, "BLANCHIMENT", adminBanner, true)
StaffMenu.builderBurglary = VUI:CreateSubMenu(StaffMenu.builders, "CAMBRIOLAGES", adminBanner, true)
StaffMenu.CreateBurglaryHouse = VUI:CreateSubMenu(StaffMenu.builderBurglary, "CRÉER UNE MAISON", adminBanner, true)
StaffMenu.SelectIPL = VUI:CreateSubMenu(StaffMenu.CreateBurglaryHouse, "SÉLECTION INTÉRIEUR", adminBanner, true)
StaffMenu.PreviewIPLDetail = VUI:CreateSubMenu(StaffMenu.SelectIPL, "PRÉVISUALISATION", adminBanner, true)
StaffMenu.ExploreIPL = VUI:CreateSubMenu(StaffMenu.SelectIPL, "EXPLORER INTÉRIEUR", adminBanner, true)
StaffMenu.ListBurglaryHouses = VUI:CreateSubMenu(StaffMenu.builderBurglary, "LISTE DES MAISONS", adminBanner, true)
StaffMenu.EditBurglaryHouse = VUI:CreateSubMenu(StaffMenu.ListBurglaryHouses, "ÉDITER MAISON", adminBanner, true)
StaffMenu.BurglarySettings = VUI:CreateSubMenu(StaffMenu.builderBurglary, "PARAMÈTRES SYSTÈME", adminBanner, true)
StaffMenu.ManageBlackmarkets = VUI:CreateSubMenu(StaffMenu.builderBlackmarket, "GÉRER LES BLACK MARKETS", adminBanner, true)
StaffMenu.EditBlackmarket = VUI:CreateSubMenu(StaffMenu.ManageBlackmarkets, "MODIFIER BLACK MARKET", adminBanner, true)
StaffMenu.AddBlackmarketItem = VUI:CreateSubMenu(StaffMenu.builderBlackmarket, "AJOUTER UN ITEM", adminBanner, true)
StaffMenu.EditBlackmarketItem = VUI:CreateSubMenu(StaffMenu.EditBlackmarket, "MODIFIER ITEM", adminBanner, true)
StaffMenu.ManageGlobalItems = VUI:CreateSubMenu(StaffMenu.builderBlackmarket, "ITEMS GLOBAUX", adminBanner, true)
StaffMenu.AddGlobalItem = VUI:CreateSubMenu(StaffMenu.ManageGlobalItems, "AJOUTER ITEM GLOBAL", adminBanner, true)
StaffMenu.EditGlobalItem = VUI:CreateSubMenu(StaffMenu.ManageGlobalItems, "MODIFIER ITEM GLOBAL", adminBanner, true)
StaffMenu.ManageDeliveryPoints = VUI:CreateSubMenu(StaffMenu.EditBlackmarket, "POINTS DE LIVRAISON", adminBanner, true)
StaffMenu.EditDeliveryPoint = VUI:CreateSubMenu(StaffMenu.ManageDeliveryPoints, "MODIFIER POINT", adminBanner, true)

StaffMenu.ConfigJewelry = VUI:CreateSubMenu(StaffMenu.builderJewelry, "CONFIG BIJOUTERIE", adminBanner, true)
StaffMenu.JewelrySettings = VUI:CreateSubMenu(StaffMenu.builderJewelry, "PARAMÈTRES BIJOUTERIE", adminBanner, true)
StaffMenu.VitrinsList = VUI:CreateSubMenu(StaffMenu.ConfigJewelry, "LISTE VITRINES", adminBanner, true)
StaffMenu.VitrineActions = VUI:CreateSubMenu(StaffMenu.VitrinsList, "ACTIONS VITRINE", adminBanner, true)

-- Sous-menus GoFast
StaffMenu.GoFastSettings = VUI:CreateSubMenu(StaffMenu.builderGoFast, "PARAMÈTRES GLOBAUX", adminBanner, true)
StaffMenu.GoFastNPCs = VUI:CreateSubMenu(StaffMenu.builderGoFast, "GÉRER LES NPCs", adminBanner, true)
StaffMenu.GoFastEditNPC = VUI:CreateSubMenu(StaffMenu.GoFastNPCs, "ÉDITER NPC", adminBanner, true)
StaffMenu.GoFastDestinations = VUI:CreateSubMenu(StaffMenu.builderGoFast, "GÉRER LES DESTINATIONS", adminBanner, true)
StaffMenu.GoFastEditDestination = VUI:CreateSubMenu(StaffMenu.GoFastDestinations, "ÉDITER DESTINATION", adminBanner, true)
StaffMenu.GoFastVehicles = VUI:CreateSubMenu(StaffMenu.builderGoFast, "GÉRER LES VÉHICULES", adminBanner, true)
StaffMenu.GoFastEditVehicle = VUI:CreateSubMenu(StaffMenu.GoFastVehicles, "ÉDITER VÉHICULE", adminBanner, true)

StaffMenu.CreateDrugZone = VUI:CreateSubMenu(StaffMenu.builderDrugDealing, "CRÉER UNE ZONE", adminBanner, true)
StaffMenu.ManageDrugZones = VUI:CreateSubMenu(StaffMenu.builderDrugDealing, "GÉRER LES ZONES", adminBanner, true)
StaffMenu.EditDrugZone = VUI:CreateSubMenu(StaffMenu.ManageDrugZones, "ÉDITER ZONE", adminBanner, true)
StaffMenu.DrugDealingSettings = VUI:CreateSubMenu(StaffMenu.builderDrugDealing, "PARAMÈTRES GLOBAUX", adminBanner, true)
StaffMenu.DrugPriceSettings = VUI:CreateSubMenu(StaffMenu.builderDrugDealing, "PRIX DES DROGUES", adminBanner, true)
StaffMenu.EditDrugPrice = VUI:CreateSubMenu(StaffMenu.DrugPriceSettings, "ÉDITER PRIX", adminBanner, true)
StaffMenu.DrugStatistics = VUI:CreateSubMenu(StaffMenu.builderDrugDealing, "STATISTIQUES", adminBanner, true)

-- Radio 911 Builder
StaffMenu.builderRadio911 = VUI:CreateSubMenu(StaffMenu.builders, "RADIO 911", adminBanner, true)
StaffMenu.builderRadio911Add = VUI:CreateSubMenu(StaffMenu.builderRadio911, "AJOUTER UN JOB", adminBanner, true)

-- KOTH Builder
StaffMenu.builderKoth = VUI:CreateSubMenu(StaffMenu.builders, "KING OF THE HILL", adminBanner, true)
StaffMenu.builderKothCreate = VUI:CreateSubMenu(StaffMenu.builderKoth, "CRÉER ZONE KOTH", adminBanner, true)
StaffMenu.builderKothManage = VUI:CreateSubMenu(StaffMenu.builderKoth, "GÉRER ZONES KOTH", adminBanner, true)
StaffMenu.builderKothEdit = VUI:CreateSubMenu(StaffMenu.builderKothManage, "ÉDITER ZONE KOTH", adminBanner, true)
StaffMenu.builderKothHistory = VUI:CreateSubMenu(StaffMenu.builderKoth, "HISTORIQUE KOTH", adminBanner, true)
StaffMenu.builderKothHistoryDetail = VUI:CreateSubMenu(StaffMenu.builderKothHistory, "DÉTAIL KOTH", adminBanner, true)

-- Faction Territory Builder
StaffMenu.builderFactionTerritories = VUI:CreateSubMenu(StaffMenu.builders, "TERRITOIRES FACTIONS", adminBanner, true)
StaffMenu.CreateFactionTerritory = VUI:CreateSubMenu(StaffMenu.builderFactionTerritories, "CRÉER TERRITOIRE", adminBanner, true)
StaffMenu.ManageFactionTerritories = VUI:CreateSubMenu(StaffMenu.builderFactionTerritories, "GÉRER TERRITOIRES", adminBanner, true)
StaffMenu.EditFactionTerritory = VUI:CreateSubMenu(StaffMenu.ManageFactionTerritories, "ÉDITER TERRITOIRE", adminBanner, true)
StaffMenu.FactionTerritorySettings = VUI:CreateSubMenu(StaffMenu.builderFactionTerritories, "PARAMÈTRES", adminBanner, true)

-- Illegal Builder (Crafting/Harvesting)
StaffMenu.builderIllegal = VUI:CreateSubMenu(StaffMenu.builders, "ILLEGAL (CRAFT/RÉCOLTE)", adminBanner, true)
StaffMenu.illegalHarvestBuilder = VUI:CreateSubMenu(StaffMenu.builderIllegal, "SPOTS DE RÉCOLTE", adminBanner, true)
StaffMenu.illegalHarvestCreate = VUI:CreateSubMenu(StaffMenu.illegalHarvestBuilder, "CRÉER UN SPOT", adminBanner, true)
StaffMenu.illegalHarvestList = VUI:CreateSubMenu(StaffMenu.illegalHarvestBuilder, "LISTE DES SPOTS", adminBanner, true)
StaffMenu.illegalHarvestManage = VUI:CreateSubMenu(StaffMenu.illegalHarvestList, "GÉRER LE SPOT", adminBanner, true)
StaffMenu.illegalHarvestItemSelect = VUI:CreateSubMenu(StaffMenu.illegalHarvestCreate, "CHOISIR L'ITEM", adminBanner, true)
StaffMenu.illegalHarvestAnimSelect = VUI:CreateSubMenu(StaffMenu.illegalHarvestCreate, "CHOISIR L'ANIMATION", adminBanner, true)
StaffMenu.illegalHarvestFactionSelect = VUI:CreateSubMenu(StaffMenu.illegalHarvestCreate, "RESTRICTION FACTION", adminBanner, true)
StaffMenu.illegalHarvestGradeSelect = VUI:CreateSubMenu(StaffMenu.illegalHarvestFactionSelect, "GRADE MINIMUM", adminBanner, true)
StaffMenu.illegalStationBuilder = VUI:CreateSubMenu(StaffMenu.builderIllegal, "STATIONS DE CRAFT", adminBanner, true)
StaffMenu.illegalStationCreate = VUI:CreateSubMenu(StaffMenu.illegalStationBuilder, "CRÉER UNE STATION", adminBanner, true)
StaffMenu.illegalStationList = VUI:CreateSubMenu(StaffMenu.illegalStationBuilder, "LISTE DES STATIONS", adminBanner, true)
StaffMenu.illegalStationManage = VUI:CreateSubMenu(StaffMenu.illegalStationList, "GÉRER LA STATION", adminBanner, true)
StaffMenu.illegalStationRecipes = VUI:CreateSubMenu(StaffMenu.illegalStationManage, "RECETTES ASSIGNÉES", adminBanner, true)
StaffMenu.illegalStationCatDetail = VUI:CreateSubMenu(StaffMenu.illegalStationRecipes, "CATÉGORIE", adminBanner, true)
StaffMenu.illegalStationFactionSelect = VUI:CreateSubMenu(StaffMenu.illegalStationCreate, "RESTRICTION FACTION", adminBanner, true)
StaffMenu.illegalStationGradeSelect = VUI:CreateSubMenu(StaffMenu.illegalStationFactionSelect, "GRADE MINIMUM", adminBanner, true)
StaffMenu.illegalRecipeBuilder = VUI:CreateSubMenu(StaffMenu.builderIllegal, "RECETTES DE CRAFT", adminBanner, true)
StaffMenu.illegalRecipeCreate = VUI:CreateSubMenu(StaffMenu.illegalRecipeBuilder, "CRÉER UNE RECETTE", adminBanner, true)
StaffMenu.illegalRecipeList = VUI:CreateSubMenu(StaffMenu.illegalRecipeBuilder, "LISTE DES RECETTES", adminBanner, true)
StaffMenu.illegalRecipeManage = VUI:CreateSubMenu(StaffMenu.illegalRecipeList, "GÉRER LA RECETTE", adminBanner, true)
StaffMenu.illegalRecipeItemSelect = VUI:CreateSubMenu(StaffMenu.illegalRecipeCreate, "CHOISIR L'ITEM RÉSULTAT", adminBanner, true)
StaffMenu.illegalRecipeAnimSelect = VUI:CreateSubMenu(StaffMenu.illegalRecipeCreate, "CHOISIR L'ANIMATION", adminBanner, true)
StaffMenu.illegalRecipeIngredientSelect = VUI:CreateSubMenu(StaffMenu.illegalRecipeCreate, "AJOUTER COMPOSANT", adminBanner, true)
StaffMenu.illegalTransformBuilder = VUI:CreateSubMenu(StaffMenu.builderIllegal, "SPOTS DE TRANSFORMATION", adminBanner, true)
StaffMenu.illegalTransformCreate = VUI:CreateSubMenu(StaffMenu.illegalTransformBuilder, "CRÉER UN SPOT", adminBanner, true)
StaffMenu.illegalTransformList = VUI:CreateSubMenu(StaffMenu.illegalTransformBuilder, "LISTE DES SPOTS", adminBanner, true)
StaffMenu.illegalTransformManage = VUI:CreateSubMenu(StaffMenu.illegalTransformList, "GÉRER LE SPOT", adminBanner, true)
StaffMenu.illegalTransformInputSelect = VUI:CreateSubMenu(StaffMenu.illegalTransformCreate, "ITEM D'ENTRÉE", adminBanner, true)
StaffMenu.illegalTransformOutputSelect = VUI:CreateSubMenu(StaffMenu.illegalTransformCreate, "ITEM DE SORTIE", adminBanner, true)
StaffMenu.illegalTransformAnimSelect = VUI:CreateSubMenu(StaffMenu.illegalTransformCreate, "CHOISIR L'ANIMATION", adminBanner, true)
StaffMenu.illegalTransformFactionSelect = VUI:CreateSubMenu(StaffMenu.illegalTransformCreate, "RESTRICTION FACTION", adminBanner, true)
StaffMenu.illegalTransformGradeSelect = VUI:CreateSubMenu(StaffMenu.illegalTransformFactionSelect, "GRADE MINIMUM", adminBanner, true)

StaffMenu.builderDrug = VUI:CreateSubMenu(StaffMenu.builders, "DROGUES (PIPELINE)", adminBanner, true)
StaffMenu.drugCreate = VUI:CreateSubMenu(StaffMenu.builderDrug, "CRÉER UNE DROGUE", adminBanner, true)
StaffMenu.drugList = VUI:CreateSubMenu(StaffMenu.builderDrug, "LISTE DES DROGUES", adminBanner, true)
StaffMenu.drugItems = VUI:CreateSubMenu(StaffMenu.drugCreate, "ITEMS", adminBanner, true)
StaffMenu.drugHarvestList = VUI:CreateSubMenu(StaffMenu.drugCreate, "POINTS DE RÉCOLTE", adminBanner, true)
StaffMenu.drugHarvestSpotEdit = VUI:CreateSubMenu(StaffMenu.drugHarvestList, "CONFIGURER POINT", adminBanner, true)
StaffMenu.drugHarvestSpotManage = VUI:CreateSubMenu(StaffMenu.drugHarvestList, "GÉRER POINT", adminBanner, true)
StaffMenu.drugTransformList = VUI:CreateSubMenu(StaffMenu.drugCreate, "POINTS DE TRANSFORMATION", adminBanner, true)
StaffMenu.drugTransformSpotEdit = VUI:CreateSubMenu(StaffMenu.drugTransformList, "CONFIGURER POINT", adminBanner, true)
StaffMenu.drugTransformSpotManage = VUI:CreateSubMenu(StaffMenu.drugTransformList, "GÉRER POINT", adminBanner, true)
StaffMenu.drugHarvestAnim = VUI:CreateSubMenu(StaffMenu.drugHarvestSpotEdit, "ANIM RÉCOLTE", adminBanner, true)
StaffMenu.drugTransformAnim = VUI:CreateSubMenu(StaffMenu.drugTransformSpotEdit, "ANIM TRANSFORMATION", adminBanner, true)
StaffMenu.drugHarvestFaction = VUI:CreateSubMenu(StaffMenu.drugHarvestSpotEdit, "FACTION RÉCOLTE", adminBanner, true)
StaffMenu.drugTransformFaction = VUI:CreateSubMenu(StaffMenu.drugTransformSpotEdit, "FACTION TRANSFO", adminBanner, true)
StaffMenu.drugHarvestGrade = VUI:CreateSubMenu(StaffMenu.drugHarvestFaction, "GRADE MIN RÉCOLTE", adminBanner, true)
StaffMenu.drugTransformGrade = VUI:CreateSubMenu(StaffMenu.drugTransformFaction, "GRADE MIN TRANSFO", adminBanner, true)

-- Legal Builder (Crafting with job restrictions)
StaffMenu.builderLegal = VUI:CreateSubMenu(StaffMenu.builders, "LEGAL (CRAFT JOB)", adminBanner, true)
StaffMenu.legalStationBuilder = VUI:CreateSubMenu(StaffMenu.builderLegal, "STATIONS DE CRAFT", adminBanner, true)
StaffMenu.legalStationCreate = VUI:CreateSubMenu(StaffMenu.legalStationBuilder, "CRÉER UNE STATION", adminBanner, true)
StaffMenu.legalStationList = VUI:CreateSubMenu(StaffMenu.legalStationBuilder, "LISTE DES STATIONS", adminBanner, true)
StaffMenu.legalStationManage = VUI:CreateSubMenu(StaffMenu.legalStationList, "GÉRER LA STATION", adminBanner, true)
StaffMenu.legalStationRecipes = VUI:CreateSubMenu(StaffMenu.legalStationManage, "RECETTES ASSIGNÉES", adminBanner, true)
StaffMenu.legalStationJobSelect = VUI:CreateSubMenu(StaffMenu.legalStationCreate, "RESTRICTION JOB", adminBanner, true)
StaffMenu.legalStationAnimSelect = VUI:CreateSubMenu(StaffMenu.legalStationCreate, "ANIMATION DE CRAFT", adminBanner, true)
StaffMenu.legalStationGradeSelect = VUI:CreateSubMenu(StaffMenu.legalStationJobSelect, "GRADE MINIMUM", adminBanner, true)
StaffMenu.legalRecipeList = VUI:CreateSubMenu(StaffMenu.builderLegal, "RECETTES LÉGALES", adminBanner, true)
StaffMenu.legalRecipeCreate = VUI:CreateSubMenu(StaffMenu.legalRecipeList, "CRÉER UNE RECETTE", adminBanner, true)
StaffMenu.legalRecipeManage = VUI:CreateSubMenu(StaffMenu.legalRecipeList, "GÉRER LA RECETTE", adminBanner, true)
StaffMenu.legalRecipeItemSelect = VUI:CreateSubMenu(StaffMenu.legalRecipeCreate, "CHOISIR L'ITEM RÉSULTAT", adminBanner, true)
StaffMenu.legalRecipeAnimSelect = VUI:CreateSubMenu(StaffMenu.legalRecipeCreate, "CHOISIR L'ANIMATION", adminBanner, true)
StaffMenu.legalRecipeIngredientSelect = VUI:CreateSubMenu(StaffMenu.legalRecipeCreate, "AJOUTER COMPOSANT", adminBanner, true)

StaffMenu.builderScratchCard = VUI:CreateSubMenu(StaffMenu.builders, "TICKETS À GRATTER", adminBanner, true)

-- Boutique Payante Admin VUI Menus
StaffMenu.builderPaidShop = VUI:CreateSubMenu(StaffMenu.builders, "BOUTIQUE PAYANTE", adminBanner, true)
StaffMenu.paidShopItems = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "GÉRER LES ITEMS", adminBanner, true)
StaffMenu.paidShopItemCategory = VUI:CreateSubMenu(StaffMenu.paidShopItems, "CATÉGORIE", adminBanner, true)
StaffMenu.paidShopItemEdit = VUI:CreateSubMenu(StaffMenu.paidShopItemCategory, "MODIFIER ITEM", adminBanner, true)
StaffMenu.paidShopAddItem = VUI:CreateSubMenu(StaffMenu.paidShopItems, "AJOUTER ITEM", adminBanner, true)
StaffMenu.paidShopAddItemWeaponSelect = VUI:CreateSubMenu(StaffMenu.paidShopAddItem, "CHOISIR UNE ARME", adminBanner, true)
StaffMenu.paidShopAddItemItemSelect = VUI:CreateSubMenu(StaffMenu.paidShopAddItem, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.paidShopPackContent = VUI:CreateSubMenu(StaffMenu.paidShopAddItem, "CONTENU DU PACK", adminBanner, true)
StaffMenu.paidShopAddPackElement = VUI:CreateSubMenu(StaffMenu.paidShopPackContent, "AJOUTER ELEMENT", adminBanner, true)
StaffMenu.paidShopAddPackElementWeaponSelect = VUI:CreateSubMenu(StaffMenu.paidShopAddPackElement, "CHOISIR UNE ARME", adminBanner, true)
StaffMenu.paidShopAddPackElementItemSelect = VUI:CreateSubMenu(StaffMenu.paidShopAddPackElement, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.paidShopCrateItems = VUI:CreateSubMenu(StaffMenu.paidShopAddItem, "ITEMS POSSIBLES", adminBanner, true)
StaffMenu.paidShopAddCrateItem = VUI:CreateSubMenu(StaffMenu.paidShopCrateItems, "AJOUTER ITEM CAISSE", adminBanner, true)
StaffMenu.paidShopAddCrateItemWeaponSelect = VUI:CreateSubMenu(StaffMenu.paidShopAddCrateItem, "CHOISIR UNE ARME", adminBanner, true)
StaffMenu.paidShopAddCrateItemItemSelect = VUI:CreateSubMenu(StaffMenu.paidShopAddCrateItem, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.paidShopEditPackContent = VUI:CreateSubMenu(StaffMenu.paidShopItemEdit, "CONTENU DU PACK", adminBanner, true)
StaffMenu.paidShopEditAddPackElement = VUI:CreateSubMenu(StaffMenu.paidShopEditPackContent, "AJOUTER ELEMENT", adminBanner, true)
StaffMenu.paidShopEditAddPackElementWeaponSelect = VUI:CreateSubMenu(StaffMenu.paidShopEditAddPackElement, "CHOISIR UNE ARME", adminBanner, true)
StaffMenu.paidShopEditAddPackElementItemSelect = VUI:CreateSubMenu(StaffMenu.paidShopEditAddPackElement, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.paidShopEditCrateItems = VUI:CreateSubMenu(StaffMenu.paidShopItemEdit, "ITEMS POSSIBLES", adminBanner, true)
StaffMenu.paidShopEditAddCrateItem = VUI:CreateSubMenu(StaffMenu.paidShopEditCrateItems, "AJOUTER ITEM CAISSE", adminBanner, true)
StaffMenu.paidShopEditAddCrateItemWeaponSelect = VUI:CreateSubMenu(StaffMenu.paidShopEditAddCrateItem, "CHOISIR UNE ARME", adminBanner, true)
StaffMenu.paidShopEditAddCrateItemItemSelect = VUI:CreateSubMenu(StaffMenu.paidShopEditAddCrateItem, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.paidShopCoins = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "GÉRER LES COINS", adminBanner, true)
StaffMenu.paidShopGiveItem = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "DONNER UN ARTICLE", adminBanner, true)
StaffMenu.paidShopGiveCategory = VUI:CreateSubMenu(StaffMenu.paidShopGiveItem, "CHOISIR CATÉGORIE", adminBanner, true)
StaffMenu.paidShopGiveItemSelect = VUI:CreateSubMenu(StaffMenu.paidShopGiveCategory, "CHOISIR ITEM", adminBanner, true)
StaffMenu.paidShopDailyRewards = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "RÉCOMPENSES QUOTIDIENNES", adminBanner, true)
StaffMenu.paidShopDailyRewardAdd = VUI:CreateSubMenu(StaffMenu.paidShopDailyRewards, "AJOUTER RÉCOMPENSE", adminBanner, true)
StaffMenu.paidShopDailyRewardEdit = VUI:CreateSubMenu(StaffMenu.paidShopDailyRewards, "MODIFIER RÉCOMPENSE", adminBanner, true)
-- Streak quotidien 7 jours (ActivityRail) — 7 slots configurables (Jour 1..7)
StaffMenu.paidShopDailyStreak = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "BONUS QUOTIDIEN 7 JOURS", adminBanner, true)
StaffMenu.paidShopDailyStreakSlot = VUI:CreateSubMenu(StaffMenu.paidShopDailyStreak, "MODIFIER LE SLOT", adminBanner, true)
StaffMenu.paidShopDisplayedCases = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "CAISSES AFFICHÉES SCANNER", adminBanner, true)
StaffMenu.paidShopAddDisplayedCase = VUI:CreateSubMenu(StaffMenu.paidShopDisplayedCases, "AJOUTER UNE CAISSE", adminBanner, true)
StaffMenu.paidShopCategoryToggle = VUI:CreateSubMenu(StaffMenu.builderPaidShop, "ACTIVER / DÉSACTIVER CATÉGORIES", adminBanner, true)

-- Pour Moi pool management (sous paidShopItemCategory quand selectedCategory=='pour_moi')
StaffMenu.paidShopPourMoiAdd          = VUI:CreateSubMenu(StaffMenu.paidShopItemCategory, "AJOUTER ITEM POUR MOI", adminBanner, true)
StaffMenu.paidShopPourMoiSourceCat    = VUI:CreateSubMenu(StaffMenu.paidShopPourMoiAdd, "CHOISIR CATÉGORIE SOURCE", adminBanner, true)
StaffMenu.paidShopPourMoiSourceItem   = VUI:CreateSubMenu(StaffMenu.paidShopPourMoiSourceCat, "CHOISIR ITEM SOURCE", adminBanner, true)
StaffMenu.paidShopPourMoiRarity       = VUI:CreateSubMenu(StaffMenu.paidShopPourMoiAdd, "CHOISIR RARETÉ", adminBanner, true)
StaffMenu.paidShopPourMoiEdit         = VUI:CreateSubMenu(StaffMenu.paidShopItemCategory, "MODIFIER ITEM POUR MOI", adminBanner, true)
StaffMenu.paidShopPourMoiEditRarity   = VUI:CreateSubMenu(StaffMenu.paidShopPourMoiEdit, "MODIFIER RARETÉ", adminBanner, true)

-- AFK Shop Builder
StaffMenu.builderAFKShop = VUI:CreateSubMenu(StaffMenu.builders, "BOUTIQUE AFK", adminBanner, true)
StaffMenu.afkShopCaseList = VUI:CreateSubMenu(StaffMenu.builderAFKShop, "GERER LES CAISSES", adminBanner, true)
StaffMenu.afkShopCaseEdit = VUI:CreateSubMenu(StaffMenu.afkShopCaseList, "MODIFIER CAISSE", adminBanner, true)
StaffMenu.afkShopCasePrizes = VUI:CreateSubMenu(StaffMenu.afkShopCaseEdit, "LOTS DE LA CAISSE", adminBanner, true)
StaffMenu.afkShopAddCase = VUI:CreateSubMenu(StaffMenu.builderAFKShop, "CREER UNE CAISSE", adminBanner, true)
StaffMenu.afkShopAddCasePrizes = VUI:CreateSubMenu(StaffMenu.afkShopAddCase, "LOTS DE LA CAISSE", adminBanner, true)
StaffMenu.afkShopAddCaseAddPrize = VUI:CreateSubMenu(StaffMenu.afkShopAddCasePrizes, "AJOUTER UN LOT", adminBanner, true)
StaffMenu.afkShopAddPrize = VUI:CreateSubMenu(StaffMenu.afkShopCasePrizes, "AJOUTER UN LOT", adminBanner, true)
StaffMenu.afkShopEditPrize = VUI:CreateSubMenu(StaffMenu.afkShopCasePrizes, "MODIFIER LOT", adminBanner, true)
StaffMenu.afkShopPointsList = VUI:CreateSubMenu(StaffMenu.builderAFKShop, "POINTS AFK JOUEURS", adminBanner, true)
StaffMenu.afkShopPointsEdit = VUI:CreateSubMenu(StaffMenu.afkShopPointsList, "GERER POINTS JOUEUR", adminBanner, true)
StaffMenu.afkShopLogs = VUI:CreateSubMenu(StaffMenu.builderAFKShop, "LOGS ACHATS CAISSES", adminBanner, true)

-- Gestion VIP
StaffMenu.builderVIP = VUI:CreateSubMenu(StaffMenu.builders, "GESTION VIP", adminBanner, true)
StaffMenu.vipMonthlyVehicles = VUI:CreateSubMenu(StaffMenu.builderVIP, "VÉHICULES DU MOIS", adminBanner, true)
StaffMenu.vipMonthlyTier = VUI:CreateSubMenu(StaffMenu.vipMonthlyVehicles, "VÉHICULES TIER", adminBanner, true)
StaffMenu.vipMonthlyAdd = VUI:CreateSubMenu(StaffMenu.vipMonthlyVehicles, "AJOUTER VÉHICULE", adminBanner, true)
StaffMenu.vipPlayerAdd = VUI:CreateSubMenu(StaffMenu.builderVIP, "AJOUTER VIP", adminBanner, true)
StaffMenu.vipPlayerAddActions = VUI:CreateSubMenu(StaffMenu.vipPlayerAdd, "CHOISIR DUREE", adminBanner, true)
StaffMenu.vipPlayerList = VUI:CreateSubMenu(StaffMenu.builderVIP, "LISTE JOUEURS VIP", adminBanner, true)
StaffMenu.vipPlayerDetail = VUI:CreateSubMenu(StaffMenu.vipPlayerList, "DETAIL JOUEUR VIP", adminBanner, true)
StaffMenu.vipPlayerModify = VUI:CreateSubMenu(StaffMenu.vipPlayerDetail, "MODIFIER VIP", adminBanner, true)
StaffMenu.vipAdvantages = VUI:CreateSubMenu(StaffMenu.builderVIP, "VALEURS VIP PAR TIER", adminBanner, true)
StaffMenu.vipAdvantagesTier = VUI:CreateSubMenu(StaffMenu.vipAdvantages, "VALEURS VIP TIER", adminBanner, true)

StaffMenu.builderInterim = VUI:CreateSubMenu(StaffMenu.builders, "ECONOMIE INTERIM", adminBanner, true)
StaffMenu.builderInterimJob = VUI:CreateSubMenu(StaffMenu.builderInterim, "JOB INTERIM", adminBanner, true)

StaffMenu.propPlacer.OnClose(function()
    if PropPlacer then
        if PropPlacer.active then
            PropPlacer.Cleanup()
        else
        end
    else
    end
end)

StaffMenu.CreateSuperMarket = VUI:CreateSubMenu(StaffMenu.builderSupermarket, "CRÉATION DE SUPERETTE", adminBanner, true)
StaffMenu.ListSuperMarket = VUI:CreateSubMenu(StaffMenu.builderSupermarket, "LISTE DES SUPERETTES", adminBanner, true)
StaffMenu.EditSuperMarket = VUI:CreateSubMenu(StaffMenu.ListSuperMarket, "ÉDITION SUPERETTE", adminBanner, true)
StaffMenu.SupermarketSettings = VUI:CreateSubMenu(StaffMenu.builderSupermarket, "PARAMÈTRES GLOBAUX", adminBanner, true)
StaffMenu.SupermarketCatalog = VUI:CreateSubMenu(StaffMenu.builderSupermarket, "CATALOGUE LTD", adminBanner, true)
StaffMenu.EditCatalogItem = VUI:CreateSubMenu(StaffMenu.SupermarketCatalog, "ÉDITION ITEM", adminBanner, true)

StaffMenu.CreateFleecaBank = VUI:CreateSubMenu(StaffMenu.builderFleeca, "CRÉER UNE BANQUE FLEECA", adminBanner, true)
StaffMenu.CreateFleecaAccessPoints = VUI:CreateSubMenu(StaffMenu.CreateFleecaBank, "POINTS D'ACCÈS BANCAIRE", adminBanner, true)
StaffMenu.ListFleecaBank = VUI:CreateSubMenu(StaffMenu.builderFleeca, "LISTE DES BANQUES FLEECA", adminBanner, true)
StaffMenu.EditFleecaBank = VUI:CreateSubMenu(StaffMenu.ListFleecaBank, "MODIFIER BANQUE FLEECA", adminBanner, true)
StaffMenu.EditFleecaAccessPoints = VUI:CreateSubMenu(StaffMenu.EditFleecaBank, "POINTS D'ACCÈS BANCAIRE", adminBanner, true)
StaffMenu.FleecaSettings = VUI:CreateSubMenu(StaffMenu.builderFleeca, "PARAMÈTRES FLEECA", adminBanner, true)

StaffMenu.CreatePacificBank = VUI:CreateSubMenu(StaffMenu.builderPacific, "CRÉER UNE BANQUE PACIFIC", adminBanner, true)
StaffMenu.CreatePacificAccessPoints = VUI:CreateSubMenu(StaffMenu.CreatePacificBank, "POINTS D'ACCÈS BANCAIRE", adminBanner, true)
StaffMenu.ListPacificBank = VUI:CreateSubMenu(StaffMenu.builderPacific, "LISTE DES BANQUES PACIFIC", adminBanner, true)
StaffMenu.EditPacificBank = VUI:CreateSubMenu(StaffMenu.ListPacificBank, "MODIFIER BANQUE PACIFIC", adminBanner, true)
StaffMenu.PacificSettings = VUI:CreateSubMenu(StaffMenu.builderPacific, "PARAMÈTRES PACIFIC", adminBanner, true)
StaffMenu.PacificPositions = VUI:CreateSubMenu(StaffMenu.builderPacific, "CONFIGURER LES POSITIONS", adminBanner, true)
StaffMenu.PacificSmallSafes = VUI:CreateSubMenu(StaffMenu.PacificPositions, "PETITS COFFRES", adminBanner, true)
StaffMenu.PacificBigSafes = VUI:CreateSubMenu(StaffMenu.PacificPositions, "GRANDS COFFRES", adminBanner, true)
StaffMenu.PacificDoors = VUI:CreateSubMenu(StaffMenu.PacificPositions, "PORTES SÉCURISÉES", adminBanner, true)

StaffMenu.ConfigWhitening = VUI:CreateSubMenu(StaffMenu.builderWhitening, "GÉRER LES POINTS", adminBanner, true)
StaffMenu.WhiteningSettings = VUI:CreateSubMenu(StaffMenu.builderWhitening, "PARAMÈTRES GLOBAUX", adminBanner, true)
StaffMenu.EditWhiteningPoint = VUI:CreateSubMenu(StaffMenu.ConfigWhitening, "MODIFIER POINT", adminBanner, true)
StaffMenu.WhiteningGroupSelect = VUI:CreateSubMenu(StaffMenu.EditWhiteningPoint, "RESTRICTION GROUPE", adminBanner, true)
StaffMenu.CreateZoneSafe = VUI:CreateSubMenu(StaffMenu.builderZoneSafe, "CRÉATION DE ZONESAFE", adminBanner, true)
StaffMenu.ListZoneSafe = VUI:CreateSubMenu(StaffMenu.builderZoneSafe, "LISTE DES ZONESAFE", adminBanner, true)
StaffMenu.DisableActionsZoneSafe = VUI:CreateSubMenu(StaffMenu.CreateZoneSafe, "DÉSACTIVER DES ACTIONS", adminBanner, true)
StaffMenu.ByPassJobZoneSafe = VUI:CreateSubMenu(StaffMenu.CreateZoneSafe, "AJOUTER DES JOBS", adminBanner, true)
StaffMenu.ManageZoneSafe = VUI:CreateSubMenu(StaffMenu.ListZoneSafe, "GÉRER LA ZONE SAFE", adminBanner, true)

--- Chest Builder SubMenu

StaffMenu.CreateChest = VUI:CreateSubMenu(StaffMenu.builderChest, "CRÉATION DE COFFRES", adminBanner, true)
StaffMenu.ChestList = VUI:CreateSubMenu(StaffMenu.builderChest, "LISTE DES COFFRES", adminBanner, true)
StaffMenu.ChestManage = VUI:CreateSubMenu(StaffMenu.ChestList, "GÉRER LE COFFRE", adminBanner, true)
StaffMenu.ChestAccessType = VUI:CreateSubMenu(StaffMenu.CreateChest, "TYPE D'ACCÈS", adminBanner, true)
StaffMenu.ChestAccessJob = VUI:CreateSubMenu(StaffMenu.ChestAccessType, "CHOISIR UN JOB", adminBanner, true)
StaffMenu.ChestAccessFaction = VUI:CreateSubMenu(StaffMenu.ChestAccessType, "CHOISIR UNE FACTION", adminBanner, true)

--- Vehicle Tuning Builder SubMenu
StaffMenu.builderVehicleTuning = VUI:CreateSubMenu(StaffMenu.builders, "EXTRA VÉHICULE", adminBanner, true)
StaffMenu.CreateVehicleTuning = VUI:CreateSubMenu(StaffMenu.builderVehicleTuning, "CRÉATION D'UN POINT", adminBanner, true)
StaffMenu.VehicleTuningList = VUI:CreateSubMenu(StaffMenu.builderVehicleTuning, "LISTE DES POINTS", adminBanner, true)
StaffMenu.VehicleTuningManage = VUI:CreateSubMenu(StaffMenu.VehicleTuningList, "GÉRER LE POINT", adminBanner, true)
StaffMenu.VehicleTuningJobSelect = VUI:CreateSubMenu(StaffMenu.CreateVehicleTuning, "CHOISIR UN JOB", adminBanner, true)

--- Door Lock Management (ox_doorlock)
StaffMenu.OxDoorlockList = VUI:CreateSubMenu(StaffMenu.builderDoorlock, "LISTE DES PORTES", adminBanner, true)
StaffMenu.OxDoorlockManage = VUI:CreateSubMenu(StaffMenu.OxDoorlockList, "GÉRER LA PORTE", adminBanner, true)
StaffMenu.OxDoorlockAccessType = VUI:CreateSubMenu(StaffMenu.OxDoorlockManage, "TYPE D'ACCÈS", adminBanner, true)
StaffMenu.OxDoorlockAccessJob = VUI:CreateSubMenu(StaffMenu.OxDoorlockAccessType, "CHOISIR UN JOB", adminBanner, true)
StaffMenu.OxDoorlockAccessJobGrades = VUI:CreateSubMenu(StaffMenu.OxDoorlockAccessJob, "GRADE MINIMUM", adminBanner, true)
StaffMenu.OxDoorlockAccessFaction = VUI:CreateSubMenu(StaffMenu.OxDoorlockAccessType, "CHOISIR UNE FACTION", adminBanner, true)
StaffMenu.OxDoorlockAccessFactionGrades = VUI:CreateSubMenu(StaffMenu.OxDoorlockAccessFaction, "GRADE MINIMUM", adminBanner, true)

-- Platine DJ submenus
StaffMenu.CreatePlatine = VUI:CreateSubMenu(StaffMenu.builderDJ, "CRÉER UNE PLATINE", adminBanner, true)
StaffMenu.DeletePlatine = VUI:CreateSubMenu(StaffMenu.builderDJ, "GÉRER LES PLATINES", adminBanner, true)
StaffMenu.PlatineManage = VUI:CreateSubMenu(StaffMenu.DeletePlatine, "GÉRER LA PLATINE", adminBanner, true)
StaffMenu.PlatineSelectScope = VUI:CreateSubMenu(StaffMenu.CreatePlatine, "TYPE D'ACCÈS", adminBanner, true)
StaffMenu.PlatineSelectJob = VUI:CreateSubMenu(StaffMenu.PlatineSelectScope, "SÉLECTIONNER UN JOB", adminBanner, true)
-- Sous-menus pour l'édition du scope des platines existantes
StaffMenu.PlatineEditScope = VUI:CreateSubMenu(StaffMenu.PlatineManage, "MODIFIER L'ACCÈS", adminBanner, true)
StaffMenu.PlatineEditSelectJob = VUI:CreateSubMenu(StaffMenu.PlatineEditScope, "SÉLECTIONNER UN JOB", adminBanner, true)
StaffMenu.braquageCreation = VUI:CreateSubMenu(StaffMenu.builderBraquage, "CRÉATION", adminBanner, true)
StaffMenu.braquageModification = VUI:CreateSubMenu(StaffMenu.builderBraquage, "LISTE DES BRAQUAGES", adminBanner, true)
StaffMenu.braquageSuppression = VUI:CreateSubMenu(StaffMenu.builderBraquage, "SUPPRESSION", adminBanner, true)
StaffMenu.braquageModificationDetails = VUI:CreateSubMenu(StaffMenu.braquageModification, "DÉTAILS DU BRAQUAGE",
    adminBanner, true)

StaffMenu.createGarage = VUI:CreateSubMenu(StaffMenu.builders, "CRÉATION DE GARAGE", adminBanner, true)
StaffMenu.createGarageSociety = VUI:CreateSubMenu(StaffMenu.builders, "GARAGE SOCIÉTÉ", adminBanner, true)
StaffMenu.createGarageFaction = VUI:CreateSubMenu(StaffMenu.builders, "GARAGE FACTION", adminBanner, true)
StaffMenu.createGarageIllegal = VUI:CreateSubMenu(StaffMenu.builders, "GARAGE ILLÉGAL", adminBanner, true)
StaffMenu.builderPoliceGarage = VUI:CreateSubMenu(StaffMenu.builders, "GARAGE POLICE", adminBanner, true)
StaffMenu.vehicleLabelOverrides = VUI:CreateSubMenu(StaffMenu.builders, "LABELS VÉHICULES", adminBanner, true)
StaffMenu.vehicleLabelOverridesEdit = VUI:CreateSubMenu(StaffMenu.vehicleLabelOverrides, "LABEL VÉHICULE", adminBanner, true)
StaffMenu.builderCameras = VUI:CreateSubMenu(StaffMenu.builders, "CAMÉRAS POLICE", adminBanner, true)
StaffMenu.builderCamerasEdit = VUI:CreateSubMenu(StaffMenu.builderCameras, "MODIFIER LA CAMÉRA", adminBanner, true)

--- Shop Builder SubMenus
--StaffMenu.builderShops = VUI:CreateSubMenu(StaffMenu.builders, "MAGASINS", adminBanner, true)
--StaffMenu.builderShopCreate = VUI:CreateSubMenu(StaffMenu.builderShops, "CRÉER UN MAGASIN", adminBanner, true)
--StaffMenu.builderShopManage = VUI:CreateSubMenu(StaffMenu.builderShops, "GÉRER LES MAGASINS", adminBanner, true)
--StaffMenu.builderShopEdit = VUI:CreateSubMenu(StaffMenu.builderShopManage, "ÉDITER MAGASIN", adminBanner, true)

StaffMenu.builderShops = VUI:CreateSubMenu(StaffMenu.builders, "MAGASINS", adminBanner, true)

StaffMenu.builderFirework = VUI:CreateSubMenu(StaffMenu.builders, "GESTION FIREWORK", adminBanner, true)

StaffMenu.builderFireworkCreate.parent = StaffMenu.builderFirework
StaffMenu.builderFireworkManage.parent = StaffMenu.builderFirework
StaffMenu.builderFireworkItems.parent = StaffMenu.builderFirework
StaffMenu.builderFireworkSettings.parent = StaffMenu.builderFirework


--- Manage Clothes Price
StaffMenu.manageClothesPrice = VUI:CreateSubMenu(StaffMenu.builderShops, "MODIFIER LES PRIX", adminBanner, true)
StaffMenu.manageClothesPriceList = VUI:CreateSubMenu(StaffMenu.manageClothesPrice, "LISTE DES PRIX", adminBanner, true)

--- Clothes Blacklist SubMenus
StaffMenu.clothesBlacklist = VUI:CreateSubMenu(StaffMenu.builderShops, "BLACKLIST VETEMENTS", adminBanner, true)
StaffMenu.clothesBlacklistGender = VUI:CreateSubMenu(StaffMenu.clothesBlacklist, "GENRE", adminBanner, true)
StaffMenu.clothesBlacklistCategory = VUI:CreateSubMenu(StaffMenu.clothesBlacklistGender, "ARTICLES", adminBanner, true)

-- Clothing SubMenus
StaffMenu.builderClothing = VUI:CreateSubMenu(StaffMenu.builderShops, "VÊTEMENTS", adminBanner, true)
StaffMenu.builderClothingCreate = VUI:CreateSubMenu(StaffMenu.builderClothing, "CRÉER UN MAGASIN", adminBanner, true)
StaffMenu.builderClothingManage = VUI:CreateSubMenu(StaffMenu.builderClothing, "GÉRER LES MAGASINS", adminBanner, true)

-- Barber SubMenus
StaffMenu.builderBarber = VUI:CreateSubMenu(StaffMenu.builderShops, "BARBER", adminBanner, true)
StaffMenu.builderBarberCreate = VUI:CreateSubMenu(StaffMenu.builderBarber, "CRÉER UN SALON", adminBanner, true)
StaffMenu.builderBarberManage = VUI:CreateSubMenu(StaffMenu.builderBarber, "GÉRER LES SALONS", adminBanner, true)

-- Tattoo SubMenus
StaffMenu.builderTattoo = VUI:CreateSubMenu(StaffMenu.builderShops, "TATOUAGES", adminBanner, true)
StaffMenu.builderTattooCreate = VUI:CreateSubMenu(StaffMenu.builderTattoo, "CRÉER UN SALON", adminBanner, true)
StaffMenu.builderTattooManage = VUI:CreateSubMenu(StaffMenu.builderTattoo, "GÉRER LES SALONS", adminBanner, true)

-- Mask SubMenus
StaffMenu.builderMask = VUI:CreateSubMenu(StaffMenu.builderShops, "MASQUES", adminBanner, true)
StaffMenu.builderMaskCreate = VUI:CreateSubMenu(StaffMenu.builderMask, "CRÉER UN MAGASIN", adminBanner, true)
StaffMenu.builderMaskManage = VUI:CreateSubMenu(StaffMenu.builderMask, "GÉRER LES MAGASINS", adminBanner, true)

-- Shared edit menu (used by all shop types)
StaffMenu.builderShopEdit = VUI:CreateSubMenu(StaffMenu.builderClothingManage, "ÉDITER MAGASIN", adminBanner, true)

--- Gun Shop Builder SubMenus
StaffMenu.builderGunshops = VUI:CreateSubMenu(StaffMenu.builders, "ARMURERIES", adminBanner, true)
StaffMenu.builderGunshopCreate = VUI:CreateSubMenu(StaffMenu.builderGunshops, "CRÉER UNE ARMURERIE", adminBanner, true)
StaffMenu.builderGunshopManage = VUI:CreateSubMenu(StaffMenu.builderGunshops, "GÉRER LES ARMURERIES", adminBanner, true)
StaffMenu.builderGunshopEdit = VUI:CreateSubMenu(StaffMenu.builderGunshopManage, "ÉDITER ARMURERIE", adminBanner, true)
StaffMenu.builderGunshopItems = VUI:CreateSubMenu(StaffMenu.builderGunshops, "GÉRER LES ARTICLES", adminBanner, true)
StaffMenu.builderGunshopItemCreate = VUI:CreateSubMenu(StaffMenu.builderGunshopItems, "AJOUTER UN ARTICLE", adminBanner, true)
StaffMenu.builderGunshopItemEdit = VUI:CreateSubMenu(StaffMenu.builderGunshopItems, "ÉDITER ARTICLE", adminBanner, true)
StaffMenu.builderGunshopSettings = VUI:CreateSubMenu(StaffMenu.builderGunshops, "PARAMÈTRES", adminBanner, true)

--- Job Armory Builder SubMenus
StaffMenu.builderJobArmory = VUI:CreateSubMenu(StaffMenu.builders, "ARMURERIES JOB", adminBanner, true)
StaffMenu.builderJobArmoryCreate = VUI:CreateSubMenu(StaffMenu.builderJobArmory, "CREER UNE ARMURERIE", adminBanner, true)
StaffMenu.builderJobArmoryManage = VUI:CreateSubMenu(StaffMenu.builderJobArmory, "GERER LES ARMURERIES", adminBanner, true)
StaffMenu.builderJobArmoryEdit = VUI:CreateSubMenu(StaffMenu.builderJobArmoryManage, "EDITER ARMURERIE", adminBanner, true)
StaffMenu.builderJobArmoryWeapons = VUI:CreateSubMenu(StaffMenu.builderJobArmoryEdit, "ARMES DE L'ARMURERIE", adminBanner, true)
StaffMenu.builderJobArmoryWeaponAdd = VUI:CreateSubMenu(StaffMenu.builderJobArmoryWeapons, "AJOUTER UNE ARME", adminBanner, true)
StaffMenu.builderJobArmoryWeaponItemSelect = VUI:CreateSubMenu(StaffMenu.builderJobArmoryWeaponAdd, "SELECTION DE L'ARME", adminBanner, true)
StaffMenu.builderJobArmoryWeaponEdit = VUI:CreateSubMenu(StaffMenu.builderJobArmoryWeapons, "EDITER ARME", adminBanner, true)
StaffMenu.builderJobArmoryWeaponGrades = VUI:CreateSubMenu(StaffMenu.builderJobArmoryWeapons, "GRADES AUTORISES", adminBanner, true)
StaffMenu.builderJobArmoryJobs = VUI:CreateSubMenu(StaffMenu.builderJobArmoryCreate, "SELECTION DES JOBS", adminBanner, true)
StaffMenu.builderJobArmoryEditJobs = VUI:CreateSubMenu(StaffMenu.builderJobArmoryEdit, "SELECTION DES JOBS", adminBanner, true)
StaffMenu.builderJobArmoryWeaponJobSelect = VUI:CreateSubMenu(StaffMenu.builderJobArmoryWeaponAdd, "JOB POUR GRADES", adminBanner, true)
StaffMenu.builderJobArmoryWeaponJobSelectEdit = VUI:CreateSubMenu(StaffMenu.builderJobArmoryWeaponEdit, "JOB POUR GRADES", adminBanner, true)
StaffMenu.builderJobArmoryLogsJobSelect = VUI:CreateSubMenu(StaffMenu.builderJobArmoryEdit, "LOGS - SELECTION JOB", adminBanner, true)
StaffMenu.builderJobArmoryLogsGrades = VUI:CreateSubMenu(StaffMenu.builderJobArmoryLogsJobSelect, "LOGS - GRADES", adminBanner, true)

--- Job Equipment Builder SubMenus
StaffMenu.builderJobEquipment = VUI:CreateSubMenu(StaffMenu.builders, "ÉQUIPEMENTS JOB", adminBanner, true)
StaffMenu.builderJobEquipmentCreate = VUI:CreateSubMenu(StaffMenu.builderJobEquipment, "CRÉER UN ÉQUIPEMENT", adminBanner, true)
StaffMenu.builderJobEquipmentManage = VUI:CreateSubMenu(StaffMenu.builderJobEquipment, "GÉRER LES ÉQUIPEMENTS", adminBanner, true)
StaffMenu.builderJobEquipmentEdit = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentManage, "ÉDITER ÉQUIPEMENT", adminBanner, true)
StaffMenu.builderJobEquipmentItems = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentEdit, "ITEMS DE L'ÉQUIPEMENT", adminBanner, true)
StaffMenu.builderJobEquipmentItemAdd = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentItems, "AJOUTER UN ITEM", adminBanner, true)
StaffMenu.builderJobEquipmentItemEdit = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentItems, "ÉDITER ITEM", adminBanner, true)
StaffMenu.builderJobEquipmentItemGrades = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentItems, "GRADES AUTORISÉS", adminBanner, true)
StaffMenu.builderJobEquipmentJobs = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentCreate, "SÉLECTION DES JOBS", adminBanner, true)
StaffMenu.builderJobEquipmentEditJobs = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentEdit, "SÉLECTION DES JOBS", adminBanner, true)
StaffMenu.builderJobEquipmentItemSelect = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentItemAdd, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.builderJobEquipmentItemJobSelect = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentItemAdd, "JOB POUR GRADES", adminBanner, true)
StaffMenu.builderJobEquipmentItemJobSelectEdit = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentItemEdit, "JOB POUR GRADES", adminBanner, true)
StaffMenu.builderJobEquipmentLogsJobSelect = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentEdit, "LOGS - SÉLECTION JOB", adminBanner, true)
StaffMenu.builderJobEquipmentLogsGrades = VUI:CreateSubMenu(StaffMenu.builderJobEquipmentLogsJobSelect, "LOGS - GRADES", adminBanner, true)

--- Pharmacy Builder SubMenus
StaffMenu.builderPharmacy = VUI:CreateSubMenu(StaffMenu.builders, "PHARMACIES", adminBanner, true)
StaffMenu.builderPharmacyCreate = VUI:CreateSubMenu(StaffMenu.builderPharmacy, "CREER UNE PHARMACIE", adminBanner, true)
StaffMenu.builderPharmacyManage = VUI:CreateSubMenu(StaffMenu.builderPharmacy, "GERER LES PHARMACIES", adminBanner, true)
StaffMenu.builderPharmacyEdit = VUI:CreateSubMenu(StaffMenu.builderPharmacyManage, "EDITER PHARMACIE", adminBanner, true)
StaffMenu.builderPharmacyItems = VUI:CreateSubMenu(StaffMenu.builderPharmacy, "GERER LES ARTICLES", adminBanner, true)
StaffMenu.builderPharmacyItemCreate = VUI:CreateSubMenu(StaffMenu.builderPharmacyItems, "AJOUTER UN ARTICLE", adminBanner, true)
StaffMenu.builderPharmacyItemSelect = VUI:CreateSubMenu(StaffMenu.builderPharmacyItemCreate, "CHOISIR UN ITEM", adminBanner, true)
StaffMenu.builderPharmacyItemEdit = VUI:CreateSubMenu(StaffMenu.builderPharmacyItems, "EDITER ARTICLE", adminBanner, true)

StaffMenu.builderPochonShop = VUI:CreateSubMenu(StaffMenu.builders, "POCHON SHOP", adminBanner, true)

--- Hospital Builder SubMenus
StaffMenu.builderHospital = VUI:CreateSubMenu(StaffMenu.builders, "HÔPITAUX", adminBanner, true)
StaffMenu.builderHospitalCreate = VUI:CreateSubMenu(StaffMenu.builderHospital, "CRÉER UN HÔPITAL", adminBanner, true)
StaffMenu.builderHospitalManage = VUI:CreateSubMenu(StaffMenu.builderHospital, "GÉRER LES HÔPITAUX", adminBanner, true)
StaffMenu.builderHospitalEdit = VUI:CreateSubMenu(StaffMenu.builderHospitalManage, "ÉDITER HÔPITAL", adminBanner, true)
StaffMenu.builderHospitalSpawns = VUI:CreateSubMenu(StaffMenu.builderHospitalEdit, "POINTS DE SPAWN", adminBanner, true)
StaffMenu.builderHospitalSpawnEdit = VUI:CreateSubMenu(StaffMenu.builderHospitalSpawns, "SPAWN", adminBanner, true)

StaffMenu.builderVendingMachines = VUI:CreateSubMenu(StaffMenu.builders, "DISTRIBUTEURS", adminBanner, true)
StaffMenu.builderVendingMachineEdit = VUI:CreateSubMenu(StaffMenu.builderVendingMachines, "MODIFIER DISTRIBUTEUR", adminBanner, true)

StaffMenu.builderWeaponBack = VUI:CreateSubMenu(StaffMenu.builders, "ARMES DANS LE DOS", adminBanner, true)
StaffMenu.builderTireSlash = VUI:CreateSubMenu(StaffMenu.builders, "CREVER LES PNEUS", adminBanner, true)
StaffMenu.builderWeaponDamage = VUI:CreateSubMenu(StaffMenu.builders, "DEGATS DES ARMES", adminBanner, true)
StaffMenu.builderWeaponDamageDetail = VUI:CreateSubMenu(StaffMenu.builderWeaponDamage, "CONFIGURATION ARME", adminBanner, true)
StaffMenu.builderHostageWeapons = VUI:CreateSubMenu(StaffMenu.builders, "PRISE D'OTAGE", adminBanner, true)
StaffMenu.builderDriveby = VUI:CreateSubMenu(StaffMenu.builders, "DRIVE-BY", adminBanner, true)
StaffMenu.builderAirsoft = VUI:CreateSubMenu(StaffMenu.builders, "AIRSOFT", adminBanner, true)
StaffMenu.builderAirsoftDetail = VUI:CreateSubMenu(StaffMenu.builderAirsoft, "CONFIG AIRSOFT", adminBanner, true)

-- Bars Main (parent menu for bar management)
StaffMenu.builderBarsMain = VUI:CreateSubMenu(StaffMenu.builders, "GESTION BAR & RESTAURANTS", adminBanner, true)

-- Bar Cards Builder (child of builderBarsMain)
StaffMenu.builderBarCards = VUI:CreateSubMenu(StaffMenu.builderBarsMain, "CARTES BARS ET RESTAURANTS", adminBanner, true)
StaffMenu.builderBarCardsList = VUI:CreateSubMenu(StaffMenu.builderBarCards, "LISTE BARS / RESTAURANTS", adminBanner, true)
StaffMenu.builderBarCardsItems = VUI:CreateSubMenu(StaffMenu.builderBarCardsList, "ITEMS", adminBanner, true)
StaffMenu.builderBarCardsAdd = VUI:CreateSubMenu(StaffMenu.builderBarCardsItems, "AJOUTER ITEM", adminBanner, true)
StaffMenu.builderBarCardsPoints = VUI:CreateSubMenu(StaffMenu.builderBarCardsList, "POINTS CARTE", adminBanner, true)

-- Bar Points Builder (récolte, transformation, PNJ de vente - child of builderBarsMain)
StaffMenu.builderBarsPoints = VUI:CreateSubMenu(StaffMenu.builderBarsMain, "GESTION POINTS BARS", adminBanner, true)
StaffMenu.builderBarsPointsOptions = VUI:CreateSubMenu(StaffMenu.builderBarsPoints, "OPTIONS BAR", adminBanner, true)

-- Taxi Builder
StaffMenu.builderTaxi = VUI:CreateSubMenu(StaffMenu.builders, "GESTION TAXI", adminBanner, true)
StaffMenu.builderTaxiEdit = VUI:CreateSubMenu(StaffMenu.builderTaxi, "MODIFIER TAXI", adminBanner, true)

StaffMenu.builderBSDelivery = VUI:CreateSubMenu(StaffMenu.builders, "LIVRAISONS BURGERSHOT", adminBanner, true)
StaffMenu.builderBSDeliveryList = VUI:CreateSubMenu(StaffMenu.builderBSDelivery, "CLIENTS", adminBanner, true)
StaffMenu.builderBSDeliveryCreate = VUI:CreateSubMenu(StaffMenu.builderBSDeliveryList, "AJOUTER UN CLIENT", adminBanner, true)
StaffMenu.builderBSDeliveryEdit = VUI:CreateSubMenu(StaffMenu.builderBSDeliveryList, "MODIFIER CLIENT", adminBanner, true)
StaffMenu.builderBSDeliveryOrder = VUI:CreateSubMenu(StaffMenu.builderBSDeliveryEdit, "COMMANDE", adminBanner, true)
StaffMenu.builderBSDeliveryCreateOrder = VUI:CreateSubMenu(StaffMenu.builderBSDeliveryCreate, "COMMANDE", adminBanner, true)
StaffMenu.builderBSDeliveryConfig = VUI:CreateSubMenu(StaffMenu.builderBSDelivery, "CONFIGURATION", adminBanner, true)

StaffMenu.builderPizzeriaDelivery = VUI:CreateSubMenu(StaffMenu.builders, "LIVRAISONS PIZZERIA", adminBanner, true)
StaffMenu.builderPizzeriaDeliveryList = VUI:CreateSubMenu(StaffMenu.builderPizzeriaDelivery, "CLIENTS", adminBanner, true)
StaffMenu.builderPizzeriaDeliveryCreate = VUI:CreateSubMenu(StaffMenu.builderPizzeriaDeliveryList, "AJOUTER UN CLIENT", adminBanner, true)
StaffMenu.builderPizzeriaDeliveryEdit = VUI:CreateSubMenu(StaffMenu.builderPizzeriaDeliveryList, "MODIFIER CLIENT", adminBanner, true)
StaffMenu.builderPizzeriaDeliveryOrder = VUI:CreateSubMenu(StaffMenu.builderPizzeriaDeliveryEdit, "COMMANDE", adminBanner, true)
StaffMenu.builderPizzeriaDeliveryCreateOrder = VUI:CreateSubMenu(StaffMenu.builderPizzeriaDeliveryCreate, "COMMANDE", adminBanner, true)
StaffMenu.builderPizzeriaDeliveryConfig = VUI:CreateSubMenu(StaffMenu.builderPizzeriaDelivery, "CONFIGURATION", adminBanner, true)

StaffMenu.builderPearlsDelivery = VUI:CreateSubMenu(StaffMenu.builders, "LIVRAISONS PEARLS", adminBanner, true)
StaffMenu.builderPearlsDeliveryList = VUI:CreateSubMenu(StaffMenu.builderPearlsDelivery, "CLIENTS", adminBanner, true)
StaffMenu.builderPearlsDeliveryCreate = VUI:CreateSubMenu(StaffMenu.builderPearlsDeliveryList, "AJOUTER UN CLIENT", adminBanner, true)
StaffMenu.builderPearlsDeliveryEdit = VUI:CreateSubMenu(StaffMenu.builderPearlsDeliveryList, "MODIFIER CLIENT", adminBanner, true)
StaffMenu.builderPearlsDeliveryOrder = VUI:CreateSubMenu(StaffMenu.builderPearlsDeliveryEdit, "COMMANDE", adminBanner, true)
StaffMenu.builderPearlsDeliveryCreateOrder = VUI:CreateSubMenu(StaffMenu.builderPearlsDeliveryCreate, "COMMANDE", adminBanner, true)
StaffMenu.builderPearlsDeliveryConfig = VUI:CreateSubMenu(StaffMenu.builderPearlsDelivery, "CONFIGURATION", adminBanner, true)

StaffMenu.builderNoodleDelivery = VUI:CreateSubMenu(StaffMenu.builders, "LIVRAISONS NOODLE", adminBanner, true)
StaffMenu.builderNoodleDeliveryList = VUI:CreateSubMenu(StaffMenu.builderNoodleDelivery, "CLIENTS", adminBanner, true)
StaffMenu.builderNoodleDeliveryCreate = VUI:CreateSubMenu(StaffMenu.builderNoodleDeliveryList, "AJOUTER UN CLIENT", adminBanner, true)
StaffMenu.builderNoodleDeliveryEdit = VUI:CreateSubMenu(StaffMenu.builderNoodleDeliveryList, "MODIFIER CLIENT", adminBanner, true)
StaffMenu.builderNoodleDeliveryOrder = VUI:CreateSubMenu(StaffMenu.builderNoodleDeliveryEdit, "COMMANDE", adminBanner, true)
StaffMenu.builderNoodleDeliveryCreateOrder = VUI:CreateSubMenu(StaffMenu.builderNoodleDeliveryCreate, "COMMANDE", adminBanner, true)
StaffMenu.builderNoodleDeliveryConfig = VUI:CreateSubMenu(StaffMenu.builderNoodleDelivery, "CONFIGURATION", adminBanner, true)

StaffMenu.builderBeanCoffeeDelivery = VUI:CreateSubMenu(StaffMenu.builders, "LIVRAISONS BEAN COFFEE", adminBanner, true)
StaffMenu.builderBeanCoffeeDeliveryList = VUI:CreateSubMenu(StaffMenu.builderBeanCoffeeDelivery, "CLIENTS", adminBanner, true)
StaffMenu.builderBeanCoffeeDeliveryCreate = VUI:CreateSubMenu(StaffMenu.builderBeanCoffeeDeliveryList, "AJOUTER UN CLIENT", adminBanner, true)
StaffMenu.builderBeanCoffeeDeliveryEdit = VUI:CreateSubMenu(StaffMenu.builderBeanCoffeeDeliveryList, "MODIFIER CLIENT", adminBanner, true)
StaffMenu.builderBeanCoffeeDeliveryOrder = VUI:CreateSubMenu(StaffMenu.builderBeanCoffeeDeliveryEdit, "COMMANDE", adminBanner, true)
StaffMenu.builderBeanCoffeeDeliveryCreateOrder = VUI:CreateSubMenu(StaffMenu.builderBeanCoffeeDeliveryCreate, "COMMANDE", adminBanner, true)
StaffMenu.builderBeanCoffeeDeliveryConfig = VUI:CreateSubMenu(StaffMenu.builderBeanCoffeeDelivery, "CONFIGURATION", adminBanner, true)

StaffMenu.builderUwuCafeDelivery = VUI:CreateSubMenu(StaffMenu.builders, "LIVRAISONS UWU CAFE", adminBanner, true)
StaffMenu.builderUwuCafeDeliveryList = VUI:CreateSubMenu(StaffMenu.builderUwuCafeDelivery, "CLIENTS", adminBanner, true)
StaffMenu.builderUwuCafeDeliveryCreate = VUI:CreateSubMenu(StaffMenu.builderUwuCafeDeliveryList, "AJOUTER UN CLIENT", adminBanner, true)
StaffMenu.builderUwuCafeDeliveryEdit = VUI:CreateSubMenu(StaffMenu.builderUwuCafeDeliveryList, "MODIFIER CLIENT", adminBanner, true)
StaffMenu.builderUwuCafeDeliveryOrder = VUI:CreateSubMenu(StaffMenu.builderUwuCafeDeliveryEdit, "COMMANDE", adminBanner, true)
StaffMenu.builderUwuCafeDeliveryCreateOrder = VUI:CreateSubMenu(StaffMenu.builderUwuCafeDeliveryCreate, "COMMANDE", adminBanner, true)
StaffMenu.builderUwuCafeDeliveryConfig = VUI:CreateSubMenu(StaffMenu.builderUwuCafeDelivery, "CONFIGURATION", adminBanner, true)

-- Positions des stations de restaurant (Grill, Friteuse, Four, Table de préparation...)
StaffMenu.builderRestaurantStations = VUI:CreateSubMenu(StaffMenu.builders, "POSITIONS STATIONS RESTAURANTS", adminBanner, true)
StaffMenu.builderRestaurantStationsLoc = VUI:CreateSubMenu(StaffMenu.builderRestaurantStations, "EMPLACEMENTS", adminBanner, true)
StaffMenu.builderRestaurantStationsList = VUI:CreateSubMenu(StaffMenu.builderRestaurantStationsLoc, "STATIONS", adminBanner, true)
StaffMenu.builderRestaurantStationsCreate = VUI:CreateSubMenu(StaffMenu.builderRestaurantStationsList, "AJOUTER UNE STATION", adminBanner, true)
StaffMenu.builderRestaurantStationsDetail = VUI:CreateSubMenu(StaffMenu.builderRestaurantStationsList, "STATION", adminBanner, true)
StaffMenu.builderRestaurantStationsPoint = VUI:CreateSubMenu(StaffMenu.builderRestaurantStationsDetail, "POINT", adminBanner, true)

StaffMenu.events = VUI:CreateSubMenu(StaffMenu.animatorStandalone, "OUTILS D'EVENTS", animatorBanner, true)
StaffMenu.eventsIpl = VUI:CreateSubMenu(StaffMenu.events, "OUTILS D'EVENTS", animatorBanner, true)
StaffMenu.eventsTpIpl = VUI:CreateSubMenu(StaffMenu.events, "OUTILS D'EVENTS", animatorBanner, true)
StaffMenu.eventsGive = VUI:CreateSubMenu(StaffMenu.events, "OUTILS D'EVENTS", animatorBanner, true)
StaffMenu.eventsIplSelect = VUI:CreateSubMenu(StaffMenu.eventsIpl, "CRÉATION D'IPL", animatorBanner, true)

StaffMenu.specialEffects = VUI:CreateSubMenu(StaffMenu.global, "Event Special", adminBanner, true)
StaffMenu.earthquakeMenu = VUI:CreateSubMenu(StaffMenu.specialEffects, "SÉISME", adminBanner, true)
StaffMenu.fireworkMenu = VUI:CreateSubMenu(StaffMenu.specialEffects, "FEU D'ARTIFICE", adminBanner, true)
StaffMenu.fireMenu = VUI:CreateSubMenu(StaffMenu.specialEffects, "INCENDIE", adminBanner, true)

StaffMenu.propseditor = VUI:CreateSubMenu(StaffMenu.events, "GESTION DES PROPS", animatorBanner, true)
StaffMenu.propseditorCreate = VUI:CreateSubMenu(StaffMenu.propseditor, "PLACER UN OBJET", animatorBanner, true)
StaffMenu.propseditorCategories = VUI:CreateSubMenu(StaffMenu.propseditorCreate, "CATÉGORIES", animatorBanner, true)
StaffMenu.objectListPlaced = VUI:CreateSubMenu(StaffMenu.propseditor, "OBJETS PLACÉS", animatorBanner, true)
StaffMenu.objectPropOptions = VUI:CreateSubMenu(StaffMenu.objectListPlaced, "OPTIONS OBJET", animatorBanner, true)

StaffMenu.fireworkPresetsMenu = VUI:CreateSubMenu(StaffMenu.fireworkMenu, "PRESETS MUSICAUX", adminBanner, true)
StaffMenu.fireworkCustomMenu = VUI:CreateSubMenu(StaffMenu.fireworkMenu, "CONFIGURATION PERSONNALISÉE", adminBanner, true)
StaffMenu.fireworkYoutubeMenu = VUI:CreateSubMenu(StaffMenu.fireworkMenu, "MUSIQUE YOUTUBE", adminBanner, true)
StaffMenu.sanctions = VUI:CreateSubMenu(StaffMenu.outils, "SANCTIONS", adminBanner, true)
StaffMenu.bans = VUI:CreateSubMenu(StaffMenu.sanctions, "LISTE DES BANS", adminBanner, true)
StaffMenu.teleportations = VUI:CreateSubMenu(StaffMenu.outils, "TÉLÉPORTATIONS CUSTOM", adminBanner, true)
StaffMenu.vehicleExtra = VUI:CreateSubMenu(StaffMenu.outils, "GESTION VÉHICULES", adminBanner, true)
StaffMenu.vehicleExtraActions = VUI:CreateSubMenu(StaffMenu.vehicleExtra, "ACTIONS VÉHICULE", adminBanner, true)
StaffMenu.vehicleCustom = VUI:CreateSubMenu(StaffMenu.vehicleExtra, "CUSTOM VÉHICULE", adminBanner, true)
StaffMenu.vehicleCustomPerf = VUI:CreateSubMenu(StaffMenu.vehicleCustom, "PERFORMANCE", adminBanner, true)
StaffMenu.vehicleCustomAesthetic = VUI:CreateSubMenu(StaffMenu.vehicleCustom, "ESTHÉTIQUE", adminBanner, true)
StaffMenu.vehicleCustomColors = VUI:CreateSubMenu(StaffMenu.vehicleCustom, "COULEURS", adminBanner, true)
StaffMenu.vehicleCustomWheels = VUI:CreateSubMenu(StaffMenu.vehicleCustom, "ROUES", adminBanner, true)
StaffMenu.vehicleCustomLights = VUI:CreateSubMenu(StaffMenu.vehicleCustom, "ÉCLAIRAGE", adminBanner, true)
StaffMenu.vehicleCustomExtras = VUI:CreateSubMenu(StaffMenu.vehicleCustom, "EXTRAS & DIVERS", adminBanner, true)
StaffMenu.serverManagement = VUI:CreateSubMenu(StaffMenu.global, "GESTION SERVEUR", adminBanner, true)
StaffMenu.weapons = VUI:CreateSubMenu(StaffMenu.outils, "DONNER DES ARMES", adminBanner, true)
StaffMenu.weaponsList = VUI:CreateSubMenu(StaffMenu.weapons, "LISTE DES ARMES", adminBanner, true)
StaffMenu.giveLicense = VUI:CreateSubMenu(StaffMenu.outils, "DONNER UN PERMIS", adminBanner, true)
-- Props métier
StaffMenu.jobsPropsMain = VUI:CreateSubMenu(StaffMenu.outils, "GÉRER LES PROPS MÉTIER", adminBanner, true)
StaffMenu.jobsPropsJob  = VUI:CreateSubMenu(StaffMenu.jobsPropsMain, "PROPS DU MÉTIER", adminBanner, true)
StaffMenu.jobsPropsProp = VUI:CreateSubMenu(StaffMenu.jobsPropsJob, "DÉTAILS PROP", adminBanner, true)
-- Carlist (Liste des véhicules avec preview)
StaffMenu.carlistMain = VUI:CreateSubMenu(StaffMenu.developers, "LISTE DES VÉHICULES", adminBanner, true)
StaffMenu.carlistCat  = VUI:CreateSubMenu(StaffMenu.carlistMain, "CATÉGORIE", adminBanner, true)
StaffMenu.pedManagement = VUI:CreateSubMenu(StaffMenu.main, "GESTION DES PEDS", adminBanner, true)
StaffMenu.pedList = VUI:CreateSubMenu(StaffMenu.pedManagement, "LISTE DES PEDS", adminBanner, true)
StaffMenu.teleportPlaces = VUI:CreateSubMenu(StaffMenu.outils, "LIEUX DE TÉLÉPORTATION", adminBanner, true)
StaffMenu.teleportList = VUI:CreateSubMenu(StaffMenu.teleportPlaces, "LISTE DES LIEUX", adminBanner, true)
StaffMenu.permissions = VUI:CreateSubMenu(StaffMenu.global, "GESTION PERMISSIONS", adminBanner, true)
StaffMenu.editRole = VUI:CreateSubMenu(StaffMenu.permissions, "ÉDITER UN RÔLE", adminBanner, true)
StaffMenu.videoManagement = VUI:CreateSubMenu(StaffMenu.global, "GESTION VIDÉOS", adminBanner, true)

-- Journalist Selection submenu (under builders)
StaffMenu.journalisteSelect = VUI:CreateSubMenu(StaffMenu.builders, "GESTION JOURNALISTE", adminBanner, true)

-- Weazel Staff Management submenus
StaffMenu.weazelManage = VUI:CreateSubMenu(StaffMenu.journalisteSelect, "WEAZEL NEWS", adminBanner, true)
StaffMenu.weazelCreate = VUI:CreateSubMenu(StaffMenu.weazelManage, "CRÉER UNE ANNONCE", adminBanner, true)
StaffMenu.weazelProgrammed = VUI:CreateSubMenu(StaffMenu.weazelManage, "ANNONCES PROGRAMMÉES", adminBanner, true)
StaffMenu.weazelHistory = VUI:CreateSubMenu(StaffMenu.weazelManage, "HISTORIQUE", adminBanner, true)

-- LifeInvader Staff Management submenus
StaffMenu.lifeinvaderManage = VUI:CreateSubMenu(StaffMenu.journalisteSelect, "LIFEINVADER", adminBanner, true)
StaffMenu.lifeinvaderCreate = VUI:CreateSubMenu(StaffMenu.lifeinvaderManage, "CRÉER UNE ANNONCE", adminBanner, true)
StaffMenu.lifeinvaderProgrammed = VUI:CreateSubMenu(StaffMenu.lifeinvaderManage, "ANNONCES PROGRAMMÉES", adminBanner, true)
StaffMenu.lifeinvaderHistory = VUI:CreateSubMenu(StaffMenu.lifeinvaderManage, "HISTORIQUE", adminBanner, true)

StaffMenu.main.OnOpen(function()
    StaffMenu.menuContext = 'staff'
    StaffMenu.ResetPlayerSearchState()
    StaffMenu.BuildMainMenu()
    CreateThread(function()
        StaffMenu.FetchPlayerList(false)
    end)
end)

StaffMenu.main.OnClose(function()
    StaffMenu._previewSource = nil
end)

StaffMenu.videoManagement.OnOpen(function()
    StaffMenu.videoManagement.ClearItems()
    StaffMenu.BuildVideoManagementMenu()
end)

StaffMenu.journalisteSelect.OnOpen(function()
    -- Load society images for staff notifications (not loaded if player isn't a journalist employee)
    if lifeinvaderImage == "" then
        lifeinvaderImage = TriggerServerCallback("lifeinvader:getSocietyImage") or ""
  end
    if weazelImage == "" then
        weazelImage = TriggerServerCallback("weazel:getSocietyImage") or ""
  end
    StaffMenu.BuildJournalisteSelectMenu()
end)

StaffMenu.weazelManage.OnOpen(function()
    StaffMenu.BuildWeazelManageMenu()
end)

StaffMenu.weazelCreate.OnOpen(function()
    StaffMenu.BuildWeazelCreateMenu()
end)

StaffMenu.weazelProgrammed.OnOpen(function()
    StaffMenu.BuildWeazelProgrammedMenu()
end)

StaffMenu.weazelHistory.OnOpen(function()
    StaffMenu.BuildWeazelHistoryMenu()
end)

StaffMenu.lifeinvaderManage.OnOpen(function()
    StaffMenu.BuildLifeInvaderManageMenu()
end)

StaffMenu.lifeinvaderCreate.OnOpen(function()
    StaffMenu.BuildLifeInvaderCreateMenu()
end)

StaffMenu.lifeinvaderProgrammed.OnOpen(function()
    StaffMenu.BuildLifeInvaderProgrammedMenu()
end)

StaffMenu.lifeinvaderHistory.OnOpen(function()
    StaffMenu.BuildLifeInvaderHistoryMenu()
end)

StaffMenu.reports.OnOpen(function()
    StaffMenu.BuildReportsMenu()
end)

StaffMenu.reports.OnIndexChange(function(index, item)
    if not item or not item.props or not item.props.title then
        console.debug("StaffMenu.reports.OnIndexChange: item or item.props or item.props.title is nil")
        StaffMenu.main.CloseReportPreview()
        return
    end

    local reportId = tonumber(string.sub(item.props.title, 9))
    local report = nil

    for i = 1, #VFW.Reports do
        if VFW.Reports[i].id == reportId then
            report = VFW.Reports[i]
            break
        end
    end

    if not report then
        StaffMenu.main.CloseReportPreview()
        return
    end

    StaffMenu.main.ReportPreview(
        reportId,
        report.date,
        report.message,
        report.player and report.player.name or "Inconnu",
        tostring(report.player and report.player.source or "?"),
        report.player and report.player.id or "Inconnu",
        report.takenByName or nil
    )
end)

StaffMenu.reports.OnClose(function()
    StaffMenu.main.CloseReportPreview()
end)

StaffMenu.report.OnOpen(function()
    StaffMenu.BuildReportMenu()
end)

StaffMenu.builderChest.OnOpen(function()
    StaffMenu.BuildChestMenu()
end)


StaffMenu.builderProps.OnOpen(function()
    StaffMenu.BuildPropsMenu()
end)

StaffMenu.players.OnOpen(function()
    -- Don't reset if we have active search results (coming back from child menu)
    local hasActiveSearch = StaffMenu.playerQuery

    -- Flag posé par les boutons de pagination : skip le reset (sinon playerPage
    -- repart à 1 et "Page Suivante" ne fait jamais avancer).
    local skipReset = StaffMenu.skipPlayerReset
    StaffMenu.skipPlayerReset = nil

    if not hasActiveSearch and not skipReset then
        StaffMenu.ResetPlayerSearchState()
        StaffMenu.FetchPlayerList(false)
    elseif not StaffMenu.data.playerList or not next(StaffMenu.data.playerList) then
        StaffMenu.FetchPlayerList(false)
    end

    StaffMenu.BuildPlayersMenu()
end)

StaffMenu.players.OnIndexChange(function(index, item)
    local playerData = StaffMenu.playerIndexMap and StaffMenu.playerIndexMap[index]
    if not playerData then
        StaffMenu._previewSource = nil
        StaffMenu.players.PlayerPreview()
        return
    end

    if StaffMenu._previewSource == playerData.source then
        return
    end
    StaffMenu._previewSource = playerData.source

    local rpName = "Inconnu"
  if playerData.firstName and playerData.lastName then
        rpName = playerData.firstName .. " " .. playerData.lastName
    elseif playerData.name then
        rpName = playerData.name
    end

    local tigStatus = playerData.hasTig and ":dot-orange: EN TIG" or "Aucun"

  local previewData = {
        { type = "header", iconUrl = "people.png",   label = "",                  value = tostring(playerData.pseudo or "Sans pseudo") },
        { type = "body",   iconUrl = "people.png",   label = "ID Session",        value = tostring(playerData.source or "?") },
        { type = "body",   iconUrl = "data.png",     label = "UUID",              value = tostring(playerData.id or "?") },
        { type = "body",   iconUrl = "shield.png",   label = "Rôle",              value = tostring(playerData.role or "Joueur") },
        { type = "body",   iconUrl = "time.png",     label = "Temps de jeu",      value = tostring(playerData.time or "00:00:00") },
        { type = "body",   iconUrl = "people.png",   label = "Nom Prénom RP",     value = tostring(rpName) },
        { type = "body",   iconUrl = "time.png",     label = "Date de naissance", value = tostring(playerData.dateOfBirth or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Taille",            value = tostring(playerData.height or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Sexe",              value = tostring(playerData.sex or "Inconnu") },
        { type = "body",   iconUrl = "job.png",      label = "Job 1",             value = tostring(playerData.jobFull or "Civil") },
        { type = "body",   iconUrl = "crew.png",     label = "Job 2 (Faction)",   value = tostring(playerData.factionFull or "Civil") },
        { type = "body",   iconUrl = "time.png",     label = "TIG",               value = tigStatus },
    }

    local instanceValue = (playerData.instance and playerData.instance ~= 0) and (":dot-orange: " .. tostring(playerData.instance)) or "Aucune instance"
  table.insert(previewData, { type = "body", iconUrl = "data.png", label = "Instance", value = instanceValue })

    local discordValue = playerData.discord and tostring(playerData.discord) or "Non relié"

  local stats = {
        { "ID Discord", discordValue },
        { "Nombre de sanctions reçues", playerData.sanctionsCount or 0 },
    }

    StaffMenu.players.PlayerPreview(nil, playerData.color, previewData, stats)
end)

StaffMenu.players.OnClose(function()
    -- Ne pas vider la fiche ici : au clic joueur on enchaîne vers le menu JOUEUR
    -- et la fiche déjà affichée (OnIndexChange) doit rester. Elle est nettoyée
    -- à la sortie de la liste (playersList.OnOpen / OnClose).
end)

StaffMenu.player.OnOpen(function()
    local row = StaffMenu._pendingPlayerRow
    StaffMenu._pendingPlayerRow = nil
    if row then
        StaffMenu.PreparePlayerMenu(row.source, StaffMenu.players, row, StaffMenu.animatorPlayerContext)
    elseif StaffMenu.data.selectedPlayer then
        local info = StaffMenu.data.playerInfo
        if not info or info.source ~= StaffMenu.data.selectedPlayer then
            StaffMenu.PreparePlayerMenu(StaffMenu.data.selectedPlayer, StaffMenu.player.parent, nil, StaffMenu.animatorPlayerContext)
        else
            local title = string.format("%s [%d]", info.name or info.pseudo or "Joueur", tonumber(StaffMenu.data.selectedPlayer) or 0)
            if StaffMenu.player.SetTitle then StaffMenu.player.SetTitle(title) end
        end
    end
    StaffMenu.BuildPlayerMenu()
end)

StaffMenu.player.OnClose(function()
    StaffMenu._previewSource = nil
    StaffMenu.main.PlayerPreview()
end)

StaffMenu.wipeOffline.OnOpen(function()
    StaffMenu.BuildWipeOfflineMenu()
end)

-- Function to attach OnOpen callback to items menu
-- This must be called after every recreation of StaffMenu.items
function StaffMenu.AttachItemsMenuCallback()
    if StaffMenu.items and StaffMenu.items.OnOpen then
        StaffMenu.items.OnOpen(function()
            StaffMenu.BuildItemsMenu()
        end)
    end
end

StaffMenu.AttachItemsMenuCallback()

StaffMenu.jobs.OnOpen(function()
    StaffMenu.BuildJobsMenu()
end)

StaffMenu.grades_jobs.OnOpen(function()
    StaffMenu.BuildGradesJobsMenu()
end)

StaffMenu.factions.OnOpen(function()
    StaffMenu.BuildFactionsMenu()
end)

StaffMenu.grades_factions.OnOpen(function()
    StaffMenu.BuildGradesFactionsMenu()
end)

StaffMenu.factionMenu.OnOpen(function()
    StaffMenu.BuildFactionMenu()
end)

StaffMenu.createFaction.OnOpen(function()
    StaffMenu.BuildCreateFactionMenu()
end)

StaffMenu.createFactionBanner.OnOpen(function()
    StaffMenu.BuildCreateFactionBannerMenu()
end)

StaffMenu.manageFactions.OnOpen(function()
    StaffMenu.BuildManageFactionsMenu()
end)

StaffMenu.manageFactionDetails.OnOpen(function()
    StaffMenu.BuildManageFactionDetailsMenu()
end)

StaffMenu.manageFactionBanner.OnOpen(function()
    StaffMenu.BuildManageFactionBannerMenu()
end)

StaffMenu.manageFactionGrades.OnOpen(function()
    StaffMenu.BuildManageFactionGradesMenu()
end)

StaffMenu.manageGradeActions.OnOpen(function()
    StaffMenu.BuildManageGradeActionsMenu()
end)

StaffMenu.manageFactionMembers.OnOpen(function()
    StaffMenu.BuildManageFactionMembersMenu()
end)

StaffMenu.manageFactionMembers.OnClose(function()
    -- Sync memberCount so the details menu shows the right label on next OnOpen.
    -- Do NOT call manageFactionDetails.refresh() here: OnClose runs during
    -- manageFactionMembers.refresh() too, and refreshing the parent re-enters
    -- _closeInternal on the current menu (vui.lua:820) which loops back into
    -- this OnClose -> stack overflow / NUI flood -> client crash.
    local faction = StaffMenu.data.selectedManagedFaction
    local members = StaffMenu.data.managedFactionMembers
    if faction and members then
        faction.memberCount = #members
    end
end)

StaffMenu.manageMemberActions.OnOpen(function()
    StaffMenu.BuildManageMemberActionsMenu()
end)

StaffMenu.manageFactionCharSelect.OnOpen(function()
    StaffMenu.BuildManageFactionCharSelectMenu()
end)

StaffMenu.vehs.OnOpen(function()
    StaffMenu.BuildVehsMenu()
end)

StaffMenu.vehs_owned.OnOpen(function()
    StaffMenu.BuildVehsOwnedMenu()
end)

StaffMenu.vehs_job.OnOpen(function()
    StaffMenu.BuildVehsJobMenu()
end)

StaffMenu.CreateChest.OnOpen(function()
    StaffMenu.BuildCreateChestMenu()
end)

StaffMenu.ChestList.OnOpen(function()
    StaffMenu.BuildChestListMenu()
end)

StaffMenu.ChestManage.OnOpen(function()
    StaffMenu.BuildManageChestMenu()
end)

StaffMenu.builderTeleport.OnOpen(function()
    StaffMenu.BuildTeleportBuilderMenu()
end)

StaffMenu.CreateTeleport.OnOpen(function()
    StaffMenu.BuildCreateTeleportMenu()
end)

StaffMenu.TeleportList.OnOpen(function()
    StaffMenu.BuildTeleportBuilderListMenu()
end)

StaffMenu.TeleportManage.OnOpen(function()
    StaffMenu.BuildManageTeleportMenu()
end)

StaffMenu.builderDeposit.OnOpen(function()
    StaffMenu.BuildDepositBuilderMenu()
end)

StaffMenu.CreateDeposit.OnOpen(function()
    StaffMenu.BuildCreateDepositMenu()
end)

StaffMenu.DepositConsultJobs.OnOpen(function()
    StaffMenu.BuildDepositConsultJobsMenu()
end)

StaffMenu.DepositList.OnOpen(function()
    StaffMenu.BuildDepositListMenu()
end)

StaffMenu.DepositManage.OnOpen(function()
    StaffMenu.BuildManageDepositMenu()
end)

StaffMenu.ChestAccessType.OnOpen(function()
    StaffMenu.BuildChestAccessTypeMenu()
end)

StaffMenu.ChestAccessJob.OnOpen(function()
    StaffMenu.BuildChestAccessJobMenu()
end)

StaffMenu.ChestAccessFaction.OnOpen(function()
    StaffMenu.BuildChestAccessFactionMenu()
end)

StaffMenu.builderVehicleTuning.OnOpen(function()
    StaffMenu.builderVehicleTuning.ClearItems()
    StaffMenu.BuildVehicleTuningBuilderMenu()
end)

StaffMenu.CreateVehicleTuning.OnOpen(function()
    StaffMenu.CreateVehicleTuning.ClearItems()
    StaffMenu.BuildCreateVehicleTuningMenu()
end)

StaffMenu.VehicleTuningList.OnOpen(function()
    StaffMenu.VehicleTuningList.ClearItems()
    StaffMenu.BuildVehicleTuningListMenu()
end)

StaffMenu.VehicleTuningManage.OnOpen(function()
    StaffMenu.VehicleTuningManage.ClearItems()
    StaffMenu.BuildVehicleTuningManageMenu()
end)

StaffMenu.VehicleTuningJobSelect.OnOpen(function()
    StaffMenu.VehicleTuningJobSelect.ClearItems()
    StaffMenu.BuildVehicleTuningJobSelectMenu()
end)

StaffMenu.OxDoorlockList.OnOpen(function()
    StaffMenu.OxDoorlockList.ClearItems()
    StaffMenu.BuildOxDoorlockListMenu()
end)

StaffMenu.OxDoorlockManage.OnOpen(function()
    StaffMenu.OxDoorlockManage.ClearItems()
    StaffMenu.BuildOxDoorlockManageMenu()
end)

StaffMenu.OxDoorlockAccessType.OnOpen(function()
    StaffMenu.BuildOxDoorlockAccessTypeMenu()
end)

StaffMenu.OxDoorlockAccessJob.OnOpen(function()
    StaffMenu.BuildOxDoorlockAccessJobMenu()
end)

StaffMenu.OxDoorlockAccessJobGrades.OnOpen(function()
    StaffMenu.BuildOxDoorlockAccessJobGradesMenu()
end)

StaffMenu.OxDoorlockAccessFaction.OnOpen(function()
    StaffMenu.BuildOxDoorlockAccessFactionMenu()
end)

StaffMenu.OxDoorlockAccessFactionGrades.OnOpen(function()
    StaffMenu.BuildOxDoorlockAccessFactionGradesMenu()
end)

StaffMenu.vehs_faction.OnOpen(function()
    StaffMenu.BuildVehsFactionMenu()
end)

StaffMenu.vehicleActions.OnOpen(function()
    StaffMenu.BuildVehicleActionsMenu()
end)

StaffMenu.playerSanctions.OnOpen(function()
    StaffMenu.BuildPlayerSanctionsMenu()
end)

StaffMenu.playerLicense.OnOpen(function()
    StaffMenu.BuildPlayerLicenseMenu()
end)

StaffMenu.playerGiveItem.OnOpen(function()
    StaffMenu.playerGiveItem.ClearItems()
    StaffMenu.BuildPlayerGiveItemMenu()
end)

if StaffMenu.wipe then
    StaffMenu.wipe.OnOpen(function()
        StaffMenu.BuildWipeMenu()
    end)
end

if StaffMenu.playerSetRank then
    StaffMenu.playerSetRank.OnOpen(function()
        StaffMenu.BuildStaffRoleChangeMenu(StaffMenu.playerSetRank, "vfw:staff:setRankByLevel")
    end)
end

StaffMenu.selectPlayerForJob.OnOpen(function()
    StaffMenu.BuildSelectPlayerForJobMenu()
end)

StaffMenu.selectPlayerForFaction.OnOpen(function()
    StaffMenu.BuildSelectPlayerForFactionMenu()
end)

StaffMenu.offlinePlayers.OnOpen(function()
    if not StaffMenu.offlineSearchQuery then
        StaffMenu.ResetOfflineSearchState()
        StaffMenu.LoadAllOfflinePlayers()
    end
    StaffMenu.BuildOfflinePlayersMenu()
end)

StaffMenu.offlinePlayers.OnIndexChange(function(index, item)
    local playerData = StaffMenu.offlinePlayerIndexMap and StaffMenu.offlinePlayerIndexMap[index]
    if not playerData then
        StaffMenu.offlinePlayers.PlayerPreview()
        return
    end

    local rpName = "Inconnu"
  if playerData.firstName and playerData.lastName then
        rpName = playerData.firstName .. " " .. playerData.lastName
    elseif playerData.name then
        rpName = playerData.name
    end

    local statusText = playerData.isOnline and ":dot-green: EN LIGNE" or ":dot-red: HORS LIGNE"
  local tigStatus = playerData.hasTig and ":dot-orange: EN TIG" or "Aucun"
  local banStatus = playerData.isBanned and ":dot-red: BANNI" or "Non"

  local previewData = {
        { type = "header", iconUrl = "people.png",   label = "",                  value = tostring(playerData.pseudo or "Sans pseudo") },
        { type = "body",   iconUrl = "data.png",     label = "UUID",              value = tostring(playerData.id or "?") },
        { type = "body",   iconUrl = "shield.png",   label = "Rôle",              value = tostring(playerData.role or "Joueur") },
        { type = "body",   iconUrl = "time.png",     label = "Temps de jeu",      value = tostring(playerData.time or "00:00:00") },
        { type = "body",   iconUrl = "people.png",   label = "Nom Prénom RP",     value = tostring(rpName) },
        { type = "body",   iconUrl = "time.png",     label = "Date de naissance", value = tostring(playerData.dateOfBirth or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Taille",            value = tostring(playerData.height or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Sexe",              value = tostring(playerData.sex or "Inconnu") },
        { type = "body",   iconUrl = "job.png",      label = "Job 1",             value = tostring(playerData.jobFull or "Civil") },
        { type = "body",   iconUrl = "crew.png",     label = "Job 2 (Faction)",   value = tostring(playerData.factionFull or "Civil") },
        { type = "body",   iconUrl = "bank.png",     label = "Statut",            value = statusText },
        { type = "body",   iconUrl = "time.png",     label = "TIG",               value = tigStatus },
        { type = "body",   iconUrl = "blocked.png",  label = "Banni",             value = banStatus },
    }

    local discordValue = (playerData.discord or playerData.identifier) and tostring(playerData.discord or playerData.identifier) or "Non relié"

  local stats = {
        { "ID Discord", discordValue },
        { "Nombre de sanctions reçues", playerData.sanctionsCount or 0 },
    }

    StaffMenu.offlinePlayers.PlayerPreview(nil, playerData.color or 0xFFFFFF, previewData, stats)
end)

StaffMenu.offlinePlayers.OnClose(function()
    StaffMenu.offlinePlayers.PlayerPreview()
end)

StaffMenu.playerSanctions.OnIndexChange(function(index, item)
    if not item or not item.props or not item.props.subtitle then
        console.debug("StaffMenu.playerSanctions.OnIndexChange: item or item.props or item.props.subtitle is nil")
        StaffMenu.main.CloseSanctionPreview()
        return
    end

    local sanctionId = item.props.subtitle
    local sanction = nil

    for _, s in pairs(StaffMenu.data.sanctionsPlayerList or {}) do
        if s.id == sanctionId then
            sanction = s
            break
        end
    end

    if not sanction then
        StaffMenu.main.CloseSanctionPreview()
        return
    end

    -- Get sanction type info
    local typeLabels = {
        warn = "Avertissement",
        kick = "Expulsion",
        ban = "Bannissement",
        tig = "TIG",
        tigweapon = "TIG Arme"
  }

    local sanctionType = typeLabels[sanction.type] or sanction.type
    local sanctionRaison = sanction.reason or "Inconnu"
  local sanctionAt = sanction.issuedAtFormatted or sanction.at or "Inconnu"
  local sanctionBy = sanction.issuedBy or sanction.by or "Inconnu"
  local sanctionActive = sanction.active and "Actif" or "Inactif"
  local sanctionExtra = ""

  if sanction.type == "ban" then
        sanctionExtra = "Expire: " .. (sanction.expiresAtFormatted or sanction.expiresAt or "Permanent")
    elseif sanction.type == "tigweapon" then
        sanctionExtra = "Durée: " .. (sanction.duration or "?") .. " min | Expire: " .. (sanction.expiresAtFormatted or sanction.expiresAt or "?")
    elseif sanction.type == "tig" then
        sanctionExtra = "Tâches: " .. (sanction.tigTasksCompleted or 0) .. "/" .. (sanction.tigTasks or 0)
    end

    StaffMenu.main.SanctionPreview(sanctionId, sanctionType, sanctionRaison, sanctionAt, sanctionBy, sanctionActive, sanctionExtra)
end)

StaffMenu.playerSanctions.OnClose(function()
    StaffMenu.main.CloseSanctionPreview()
end)

StaffMenu.staff.OnOpen(function()
    StaffMenu.BuildStaffMenu()
end)

StaffMenu.staff.OnIndexChange(function(index, item)
    if not item or not item.props or not item.props.title or not item.props.rightLabel or not item.props.subtitle then
        StaffMenu.main.PlayerPreview()
        return
    end

    local playerPseudo = item.props.title
    local playerGrade = item.props.rightLabel
    local playerName = item.props.subtitle
    local player = nil

    for k, v in pairs(StaffMenu.data.staffList) do
        if v.pseudo == playerPseudo and v.grade == playerGrade and v.name == playerName then
            player = player
            break
        end
    end

    if not player then
        StaffMenu.main.PlayerPreview()
        return
    end
end)

StaffMenu.staff.OnClose(function()
    StaffMenu.main.PlayerPreview()
end)

StaffMenu.builderFarm.OnOpen(function()
    StaffMenu.BuildFarmMenu()
end)

StaffMenu.builderFarmOptions.OnOpen(function()
    StaffMenu.BuildFarmOptionsMenu()
end)

StaffMenu.outils.OnOpen(function()
    if VFW.SyncStaffAccess then VFW.SyncStaffAccess() end
    StaffMenu.outils.ClearItems()
    StaffMenu.BuildOutilsMenu()
end)

StaffMenu.global.OnOpen(function()
    StaffMenu.BuildGlobalMenu()

    -- Pre-fetch server stats en arrière-plan pour éviter le lag à l'ouverture du sous-menu
    Citizen.CreateThread(function()
        StaffMenu.cachedServerStats = TriggerServerCallback("vfw:staff:getServerStats") or {}
    end)
end)

StaffMenu.developers.OnOpen(function()
    StaffMenu.BuildDevelopersMenu()
end)

StaffMenu.webhookLogs.OnOpen(function()
    StaffMenu.BuildWebhookLogsMenu()
end)

StaffMenu.webhookLogsEdit.OnOpen(function()
    StaffMenu.BuildWebhookLogsEditMenu()
end)

StaffMenu.potionsMenu.OnOpen(function()
    StaffMenu.potionsMenu.ClearItems()
    StaffMenu.BuildPotionsMenu()
end)

StaffMenu.animManager.OnOpen(function()
    StaffMenu.BuildAnimManagerMenu()
end)

StaffMenu.animManagerList.OnOpen(function()
    StaffMenu.BuildAnimManagerListMenu()
end)

StaffMenu.animManagerEdit.OnOpen(function()
    StaffMenu.BuildAnimManagerEditMenu()
end)

StaffMenu.animManagerCategory.OnOpen(function()
    StaffMenu.BuildAnimManagerCategoryMenu()
end)

StaffMenu.weightManagement.OnOpen(function()
    StaffMenu.BuildWeightManagementMenu()
end)

StaffMenu.weightDuration.OnOpen(function()
    StaffMenu.BuildWeightDurationMenu()
end)

StaffMenu.weightCharSelect.OnOpen(function()
    StaffMenu.BuildWeightCharSelectMenu()
end)

StaffMenu.camera.OnOpen(function()
    StaffMenu.BuildCameraMenu()
end)

StaffMenu.gestionItems.OnOpen(function()
    StaffMenu.BuildGestionItemsMenu()
end)

StaffMenu.gestionPhone.OnOpen(function()
    if StaffMenu.BuildGestionPhoneMenu then
        StaffMenu.BuildGestionPhoneMenu()
    end
end)

StaffMenu.gestionPhoneApps.OnOpen(function()
    if StaffMenu.BuildGestionPhoneAppsMenu then
        StaffMenu.BuildGestionPhoneAppsMenu()
    end
end)

StaffMenu.gestionPhoneCertifs.OnOpen(function()
    if StaffMenu.BuildGestionPhoneCertifsMenu then
        StaffMenu.BuildGestionPhoneCertifsMenu()
    end
end)

StaffMenu.gestionPhoneHistory.OnOpen(function()
    if StaffMenu.BuildGestionPhoneHistoryMenu then
        StaffMenu.BuildGestionPhoneHistoryMenu()
    end
end)

StaffMenu.vehBlacklist.OnOpen(function()
    if StaffMenu.BuildVehicleBlacklistMenu then
        StaffMenu.BuildVehicleBlacklistMenu()
    end
end)

StaffMenu.selectItem.OnOpen(function()
    StaffMenu.BuildSelectItemMenu()
end)

StaffMenu.editGestionItem.OnOpen(function()
    StaffMenu.BuildEditGestionItemMenu()
end)

StaffMenu.createItem.OnOpen(function()
    StaffMenu.BuildCreateItemMenu()
end)

StaffMenu.builderZoneSafe.OnOpen(function()
    StaffMenu.BuildZoneSafeMenu()
end)

StaffMenu.builderDoorlock.OnOpen(function()
    StaffMenu.BuildDoorlockMenu()
end)

StaffMenu.builderDJ.OnOpen(function()
    StaffMenu.BuildDJMenu()
end)

StaffMenu.builderAmbientSound.OnOpen(function()
    StaffMenu.BuildAmbientSoundMenu()
end)

StaffMenu.builderBlips.OnOpen(function()
    StaffMenu.BuildBlipsMenu()
end)

StaffMenu.builderCarRental.OnOpen(function()
    StaffMenu.BuildVehicleRentalMenu()
end)


StaffMenu.builderLocker.OnOpen(function()
    StaffMenu.BuildLockerMenu()
end)

StaffMenu.builderSocietyLocker.OnOpen(function()
    StaffMenu.BuildSocietyLockerMenu()
end)

StaffMenu.builderBraquage.OnOpen(function()
    StaffMenu.BuildBraquageMenu()
end)

StaffMenu.builderSupermarket.OnOpen(function()
    StaffMenu.BuildSupermarketMenu()
end)

StaffMenu.builderATM.OnOpen(function()
    StaffMenu.BuildATMMenu()
end)

StaffMenu.builderATM.OnClose(function()
    -- Désactiver le mode admin ATM quand on quitte le menu
    exports["core"]:SetATMAdminMode(false)
end)

StaffMenu.ListCustomATMsMenu.OnOpen(function()
    StaffMenu.ListCustomATMs()
end)

StaffMenu.EditCustomATMMenu.OnOpen(function()
    StaffMenu.BuildEditCustomATMMenu()
end)

StaffMenu.builderFleeca.OnOpen(function()
    StaffMenu.BuildFleecaMenu()
end)

StaffMenu.builderPacific.OnOpen(function()
    StaffMenu.BuildPacificMenu()
end)

StaffMenu.builderWhitening.OnOpen(function()
    StaffMenu.BuildWhiteningMenu()
end)

StaffMenu.builderBlackmarket.OnOpen(function()
    StaffMenu.BuildBlackmarketMenu()
end)

StaffMenu.ManageBlackmarkets.OnOpen(function()
    StaffMenu.BuildManageBlackmarketsMenu()
end)

StaffMenu.EditBlackmarket.OnOpen(function()
    StaffMenu.BuildEditBlackmarketMenu()
end)

StaffMenu.AddBlackmarketItem.OnOpen(function()
    StaffMenu.BuildAddBlackmarketItemMenu()
end)

StaffMenu.EditBlackmarketItem.OnOpen(function()
    StaffMenu.BuildEditBlackmarketItemMenu()
end)

StaffMenu.ManageGlobalItems.OnOpen(function()
    StaffMenu.BuildManageGlobalItemsMenu()
end)

StaffMenu.AddGlobalItem.OnOpen(function()
    StaffMenu.BuildAddGlobalItemMenu()
end)

StaffMenu.EditGlobalItem.OnOpen(function()
    StaffMenu.BuildEditGlobalItemMenu()
end)

StaffMenu.ManageDeliveryPoints.OnOpen(function()
    StaffMenu.BuildManageDeliveryPointsMenu()
end)

StaffMenu.EditDeliveryPoint.OnOpen(function()
    StaffMenu.BuildEditDeliveryPointMenu()
end)

StaffMenu.builderJewelry.OnOpen(function()
    StaffMenu.BuildJewelryMenu()
end)

StaffMenu.ConfigJewelry.OnOpen(function()
    StaffMenu.BuildConfigJewelryMenu()
end)

StaffMenu.JewelrySettings.OnOpen(function()
    StaffMenu.BuildJewelrySettingsMenu()
end)

StaffMenu.VitrinsList.OnOpen(function()
    StaffMenu.BuildVitrinesListMenu()
end)

StaffMenu.VitrineActions.OnOpen(function()
    StaffMenu.BuildVitrineActionsMenu()
end)

StaffMenu.builderBurglary.OnOpen(function()
    StaffMenu.BuildBurglaryMenu()
end)

StaffMenu.CreateBurglaryHouse.OnOpen(function()
    StaffMenu.BuildCreateBurglaryHouseMenu()
end)

StaffMenu.SelectIPL.OnOpen(function()
    StaffMenu.BuildSelectIPLMenu()
end)

StaffMenu.PreviewIPLDetail.OnOpen(function()
    StaffMenu.BuildPreviewIPLDetailMenu()
end)

StaffMenu.ExploreIPL.OnOpen(function()
    StaffMenu.BuildExploreIPLMenu()
end)

StaffMenu.ListBurglaryHouses.OnOpen(function()
    StaffMenu.BuildListBurglaryHousesMenu()
end)

StaffMenu.EditBurglaryHouse.OnOpen(function()
    StaffMenu.BuildEditBurglaryHouseMenu()
end)

StaffMenu.BurglarySettings.OnOpen(function()
    StaffMenu.BuildBurglarySettingsMenu()
end)

StaffMenu.builderGoFast.OnOpen(function()
    StaffMenu.BuildGoFastMenu()
end)

-- Callbacks GoFast
StaffMenu.GoFastSettings.OnOpen(function()
    StaffMenu.BuildGoFastSettingsMenu()
end)

StaffMenu.GoFastNPCs.OnOpen(function()
    StaffMenu.BuildGoFastNPCsMenu()
end)

StaffMenu.GoFastEditNPC.OnOpen(function()
    StaffMenu.BuildGoFastEditNPCMenu()
end)

StaffMenu.GoFastDestinations.OnOpen(function()
    StaffMenu.BuildGoFastDestinationsMenu()
end)

StaffMenu.GoFastEditDestination.OnOpen(function()
    StaffMenu.BuildGoFastEditDestinationMenu()
end)

StaffMenu.GoFastVehicles.OnOpen(function()
    StaffMenu.BuildGoFastVehiclesMenu()
end)

StaffMenu.GoFastEditVehicle.OnOpen(function()
    StaffMenu.BuildGoFastEditVehicleMenu()
end)

StaffMenu.CreateZoneSafe.OnOpen(function()
    StaffMenu.BuildCreateZoneSafeMenu()
end)

StaffMenu.CreateSuperMarket.OnOpen(function()
    StaffMenu.BuildCreateSuperMarketMenu()
end)

StaffMenu.ListSuperMarket.OnOpen(function()
    StaffMenu.BuildListSuperMarketMenu()
end)

StaffMenu.EditSuperMarket.OnOpen(function()
    StaffMenu.BuildEditSuperMarketMenu()
end)

StaffMenu.SupermarketSettings.OnOpen(function()
    StaffMenu.BuildSupermarketSettings()
end)

StaffMenu.SupermarketCatalog.OnOpen(function()
    StaffMenu.BuildSupermarketCatalogMenu()
end)

StaffMenu.EditCatalogItem.OnOpen(function()
    StaffMenu.BuildEditCatalogItemMenu()
end)

StaffMenu.CreateFleecaBank.OnOpen(function()
    StaffMenu.BuildCreateFleecaBankMenu()
end)

StaffMenu.CreateFleecaAccessPoints.OnOpen(function()
    StaffMenu.BuildCreateFleecaAccessPointsMenu()
end)

StaffMenu.ListFleecaBank.OnOpen(function()
    StaffMenu.BuildListFleecaBankMenu()
end)

StaffMenu.EditFleecaBank.OnOpen(function()
    StaffMenu.BuildEditFleecaBankMenu()
end)

StaffMenu.EditFleecaAccessPoints.OnOpen(function()
    if selectedFleecaBank and selectedFleecaBank.id then
        local banks = TriggerServerCallback("core:fleeca:getBanks")
        if banks then
            for _, bank in ipairs(banks) do
                if bank.id == selectedFleecaBank.id then
                    selectedFleecaBank = bank
                    break
                end
            end
        end
    end
    StaffMenu.BuildEditFleecaAccessPointsMenu()
end)

StaffMenu.FleecaSettings.OnOpen(function()
    StaffMenu.BuildFleecaSettingsMenu()
end)

StaffMenu.CreatePacificBank.OnOpen(function()
    StaffMenu.BuildCreatePacificBankMenu()
end)

StaffMenu.CreatePacificAccessPoints.OnOpen(function()
    StaffMenu.BuildCreatePacificAccessPointsMenu()
end)

StaffMenu.ListPacificBank.OnOpen(function()
    StaffMenu.BuildListPacificBankMenu()
end)

StaffMenu.EditPacificBank.OnOpen(function()
    StaffMenu.BuildEditPacificBankMenu()
end)

StaffMenu.PacificSettings.OnOpen(function()
    StaffMenu.BuildPacificSettingsMenu()
end)

StaffMenu.PacificPositions.OnOpen(function()
    StaffMenu.BuildPacificPositionsMenu()
end)

StaffMenu.PacificSmallSafes.OnOpen(function()
    StaffMenu.BuildPacificSmallSafesMenu()
end)

StaffMenu.PacificBigSafes.OnOpen(function()
    StaffMenu.BuildPacificBigSafesMenu()
end)

StaffMenu.PacificDoors.OnOpen(function()
    StaffMenu.BuildPacificDoorsMenu()
end)

StaffMenu.ConfigWhitening.OnOpen(function()
    StaffMenu.BuildConfigWhiteningMenu()
end)

StaffMenu.WhiteningSettings.OnOpen(function()
    StaffMenu.BuildWhiteningSettings()
end)

StaffMenu.EditWhiteningPoint.OnOpen(function()
    StaffMenu.BuildEditWhiteningPointMenu()
end)

StaffMenu.WhiteningGroupSelect.OnOpen(function()
    StaffMenu.BuildWhiteningGroupSelectMenu()
end)

StaffMenu.ListZoneSafe.OnOpen(function()
    StaffMenu.BuildListZoneSafeMenu()
end)

StaffMenu.createGarage.OnOpen(function()
    StaffMenu.BuildCreateGarageMenu()
end)

StaffMenu.createGarageSociety.OnOpen(function()
    StaffMenu.BuildCreateGarageSociety()
end)

StaffMenu.createGarageFaction.OnOpen(function()
    StaffMenu.BuildCreateGarageFaction()
end)

StaffMenu.createGarageIllegal.OnOpen(function()
    StaffMenu.BuildCreateGarageIllegal()
end)

StaffMenu.builderPoliceGarage.OnOpen(function()
    StaffMenu.BuildPoliceGarageMenu()
end)

StaffMenu.vehicleLabelOverrides.OnOpen(function()
    StaffMenu.BuildVehicleLabelOverridesMenu()
end)

StaffMenu.vehicleLabelOverridesEdit.OnOpen(function()
    StaffMenu.BuildVehicleLabelOverrideEditMenu()
end)

StaffMenu.builderCameras.OnOpen(function()
    StaffMenu.BuildCamerasMenu()
end)

StaffMenu.builderCamerasEdit.OnOpen(function()
    StaffMenu.BuildCamerasEditMenu()
end)

StaffMenu.CreatePlatine.OnOpen(function()
    StaffMenu.BuildCreatePlatineMenu()
end)

StaffMenu.DeletePlatine.OnOpen(function()
    StaffMenu.BuildDeletePlatineMenu()
end)

StaffMenu.PlatineManage.OnOpen(function()
    StaffMenu.BuildPlatineManageMenu()
end)

StaffMenu.PlatineSelectScope.OnOpen(function()
    StaffMenu.BuildPlatineSelectScopeMenu()
end)

StaffMenu.PlatineSelectJob.OnOpen(function()
    StaffMenu.BuildPlatineSelectJobMenu()
end)

StaffMenu.PlatineEditScope.OnOpen(function()
    StaffMenu.BuildPlatineEditScopeMenu()
end)

StaffMenu.PlatineEditSelectJob.OnOpen(function()
    StaffMenu.BuildPlatineEditSelectJobMenu()
end)

-- Recording Studios Builder OnOpen
StaffMenu.builderStudio.OnOpen(function()
    StaffMenu.BuildStudioBuilderMenu()
end)

StaffMenu.CreateStudio.OnOpen(function()
    StaffMenu.BuildCreateStudioMenu()
end)

StaffMenu.ManageStudios.OnOpen(function()
    StaffMenu.BuildManageStudiosMenu()
end)

StaffMenu.StudioManage.OnOpen(function()
    StaffMenu.BuildStudioManageMenu()
end)

StaffMenu.StudioSelectScope.OnOpen(function()
    StaffMenu.BuildStudioSelectScopeMenu()
end)

StaffMenu.StudioSelectJob.OnOpen(function()
    StaffMenu.BuildStudioSelectJobMenu()
end)

StaffMenu.StudioEditScope.OnOpen(function()
    StaffMenu.BuildStudioEditScopeMenu()
end)

StaffMenu.StudioEditSelectJob.OnOpen(function()
    StaffMenu.BuildStudioEditSelectJobMenu()
end)

StaffMenu.braquageCreation.OnOpen(function()
    StaffMenu.BuildBraquageCreationMenu()
end)

StaffMenu.braquageModification.OnOpen(function()
    StaffMenu.BuildBraquageModificationMenu()
end)

StaffMenu.braquageSuppression.OnOpen(function()
    StaffMenu.BuildBraquageSuppressionMenu()
end)

StaffMenu.braquageModificationDetails.OnOpen(function()
    StaffMenu.BuildBraquageModificationDetailsMenu()
end)

StaffMenu.DisableActionsZoneSafe.OnOpen(function()
    StaffMenu.BuildListDisableActionsZoneSafe()
end)

StaffMenu.ManageZoneSafe.OnOpen(function()
    StaffMenu.BuildManageZoneSafeMenu()
end)

StaffMenu.ByPassJobZoneSafe.OnOpen(function()
    StaffMenu.BuildByPassJobZoneSafeMenu()
end)

StaffMenu.events.OnOpen(function()
    if StaffMenu.menuContext == 'animator' and StaffMenu._eventsParentMenu then
        StaffMenu.events.parent = StaffMenu._eventsParentMenu
    end
    StaffMenu.BuildEventsMenu()
end)

StaffMenu.specialEffects.OnOpen(function()
    StaffMenu.specialEffects.ClearItems()
    StaffMenu.BuildSpecialEventMenu()
end)

StaffMenu.eventsIpl.OnOpen(function()
    StaffMenu.BuildEventsIplMenu()
end)

StaffMenu.eventsTpIpl.OnOpen(function()
    StaffMenu.BuildEventsTpIplMenu()
end)

StaffMenu.eventsGive.OnOpen(function()
    StaffMenu.BuildEventsGiveMenu()
end)

StaffMenu.eventsIplSelect.OnOpen(function()
    StaffMenu.BuildEventsIplSelectMenu()
end)

StaffMenu.propseditor.OnOpen(function()
    if StaffMenu.menuContext == 'animator' and StaffMenu._eventsParentMenu then
        StaffMenu.events.parent = StaffMenu._eventsParentMenu
    end
    StaffMenu.BuildpropseditorMenu()
end)

StaffMenu.propseditor.OnClose(function()
    -- Nettoyer le preview si on quitte le menu principal
    if StaffMenu.CleanupEventPropsPreview then
        StaffMenu.CleanupEventPropsPreview()
    end
end)

StaffMenu.propseditorCreate.OnOpen(function()
    if StaffMenu.menuContext == 'animator' and StaffMenu._eventsParentMenu then
        StaffMenu.events.parent = StaffMenu._eventsParentMenu
    end
    StaffMenu.BuildPropsEditorCreateMenu()
end)

StaffMenu.propseditorCreate.OnClose(function()
    -- Ne pas nettoyer le preview car on peut revenir
end)

StaffMenu.propseditorCategories.OnOpen(function()
    StaffMenu.BuildPropsEditorCategoriesMenu()
end)

StaffMenu.fireworkMenu.OnOpen(function()
    StaffMenu.fireworkMenu.ClearItems()
    StaffMenu.BuildFireworkMenu()
end)

StaffMenu.earthquakeMenu.OnOpen(function()
    StaffMenu.earthquakeMenu.ClearItems()
    StaffMenu.BuildEarThquakeMenuMenu()
end)

StaffMenu.fireworkPresetsMenu.OnOpen(function()
    StaffMenu.fireworkPresetsMenu.ClearItems()
    StaffMenu.BuildFireworkPresetsMenu()
end)

StaffMenu.fireworkCustomMenu.OnOpen(function()
    StaffMenu.fireworkCustomMenu.ClearItems()
    StaffMenu.BuildFireworkCustomMenu()
end)

StaffMenu.fireworkYoutubeMenu.OnOpen(function()
    StaffMenu.fireworkYoutubeMenu.ClearItems()
    StaffMenu.BuildFireworkYoutubeMenu()
end)

StaffMenu.fireMenu.OnOpen(function()
    StaffMenu.fireMenu.ClearItems()
    StaffMenu.BuildFireMenu()
end)

StaffMenu.fireMenu.OnClose(function()
    StaffMenu.StopFireRangePreview()
end)

StaffMenu.builderFirework.OnOpen(function()
    StaffMenu.BuildFireworkBuilderMenu()
end)

StaffMenu.builderFireworkCreate.OnOpen(function()
    StaffMenu.BuildCreateFireworkShopMenu()
    if StaffMenu.data.firework.currentBuild.position then
        startMarkerThread()
    end
end)

StaffMenu.builderFireworkCreate.OnClose(function()
    stopMarkerThread()
end)

StaffMenu.builderFireworkManage.OnOpen(function()
    local shops = TriggerServerCallback('core:firework:getShops')
    StaffMenu.currentFireworkShops = shops or {}
    StaffMenu.BuildManageFireworkShopsMenu()
end)

StaffMenu.builderFireworkEdit.OnOpen(function()
    StaffMenu.BuildEditFireworkShopMenu()
end)

StaffMenu.builderFireworkItems.OnOpen(function()
    local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
    StaffMenu.currentFireworkItems = items or {}
    StaffMenu.BuildFireworkItemsMenu()
end)

StaffMenu.builderFireworkItemCreate.OnOpen(function()
    StaffMenu.BuildCreateFireworkItemMenu()
end)

StaffMenu.builderFireworkItemEdit.OnOpen(function()
    StaffMenu.BuildEditFireworkItemMenu()
end)

StaffMenu.builderFireworkSettings.OnOpen(function()
    StaffMenu.BuildFireworkSettingsMenu()
end)

StaffMenu.objectListPlaced.OnOpen(function()
    StaffMenu.BuildpropseditorObjectList()
end)

StaffMenu.objectPropOptions.OnOpen(function()
    StaffMenu.BuildObjectPropOptions()
end)

StaffMenu.sanctions.OnOpen(function()
    StaffMenu.BuildSanctionsMenu()
end)

StaffMenu.bans.OnOpen(function()
    StaffMenu.BuildBansMenu()
end)

StaffMenu.bans.OnIndexChange(function(index, item)
    if not item or not item.props or not item.props.subtitle then
        console.debug("StaffMenu.bans.OnIndexChange: item or item.props or item.props.subtitle is nil")
        StaffMenu.main.CloseBanPreview()
        return
    end

    local banId = item.props.subtitle
    local ban = nil

    for k, v in pairs(StaffMenu.data.banList) do
        if v.id == banId then
            ban = v
            break
        end
    end

    if not ban then
        StaffMenu.main.CloseBanPreview()
        return
    end

    local banRaison = ban.raison or "Inconnu"
  local banAt = ban.banDate or "Inconnu"
  local banExpiration = ban.expiration or "Jamais"
  local banIdentifiers = ban.ids or "Inconnu"

  StaffMenu.main.BanPreview(banId, banRaison, banAt, banExpiration, banIdentifiers)
end)

StaffMenu.bans.OnClose(function()
    StaffMenu.main.CloseBanPreview()
end)

StaffMenu.teleportations.OnOpen(function()
    StaffMenu.BuildTeleportationsMenu()
end)

StaffMenu.vehicleExtra.OnOpen(function()
    StaffMenu.BuildVehicleExtraMenu()
end)

StaffMenu.vehicleExtraActions.OnOpen(function()
    StaffMenu.BuildVehicleExtraActionsMenu()
end)

StaffMenu.serverManagement.OnOpen(function()
    StaffMenu.BuildServerManagementMenu()
end)

StaffMenu.serverManagement.OnClose(function()
    if StaffMenu.weatherPreviewActive then
        SetWeatherTypeNow(VFW.currentWeather)
        SetWeatherTypeNowPersist(VFW.currentWeather)
        StaffMenu.weatherPreviewActive = false
    end
end)

StaffMenu.weapons.OnOpen(function()
    StaffMenu.BuildWeaponsMenu()
end)

StaffMenu.weaponsList.OnOpen(function()
    StaffMenu.BuildWeaponsListMenu()
end)

StaffMenu.giveLicense.OnOpen(function()
    StaffMenu.BuildGiveLicenseMenu()
end)

StaffMenu.prisonList.OnOpen(function()
    StaffMenu.BuildPrisonListMenu()
end)

StaffMenu.banListDirect.OnOpen(function()
    StaffMenu.data.banList = TriggerServerCallback("core:ban:getbans") or {}
    StaffMenu.BuildBanListDirectMenu()
end)

StaffMenu.banDetail.OnOpen(function()
    StaffMenu.BuildBanDetailMenu()
end)

StaffMenu.tigListMenu.OnOpen(function()
    StaffMenu.BuildTigListMenu()
end)

StaffMenu.tigWeaponsListMenu.OnOpen(function()
    StaffMenu.BuildTigWeaponsListMenu()
end)

StaffMenu.kickListMenu.OnOpen(function()
    StaffMenu.BuildKickListMenu()
end)

StaffMenu.warnListMenu.OnOpen(function()
    StaffMenu.BuildWarnListMenu()
end)

StaffMenu.removeLicense.OnOpen(function()
    StaffMenu.BuildRemoveLicenseMenu()
end)

StaffMenu.pedManagement.OnOpen(function()
    StaffMenu.BuildPedManagementMenu()
end)

StaffMenu.pedList.OnOpen(function()
    StaffMenu.BuildPedListMenu()
end)

StaffMenu.teleportPlaces.OnOpen(function()
    StaffMenu.BuildTeleportPlacesMenu()
end)

StaffMenu.teleportList.OnOpen(function()
    StaffMenu.BuildTeleportListMenu()
end)

StaffMenu.vehicleManagement.OnOpen(function()
    if VFW.SyncStaffAccess then VFW.SyncStaffAccess() end
    StaffMenu.vehicleManagement.ClearItems()
    StaffMenu.BuildVehicleManagementMenu()
end)

StaffMenu.permissions.OnOpen(function()
    StaffMenu.BuildPermissionsMenu()
end)

StaffMenu.editRole.OnOpen(function()
    StaffMenu.BuildEditRoleMenu()
end)

StaffMenu.giveAllItems.OnOpen(function()
    StaffMenu.BuildGiveAllItemsMenu()
end)

StaffMenu.personalActions.OnOpen(function()
    if VFW.SyncStaffAccess then VFW.SyncStaffAccess() end
    StaffMenu.personalActions.ClearItems()
    StaffMenu.BuildPersonalActionsMenu()
end)

StaffMenu.personalTeleport.OnOpen(function()
    StaffMenu.BuildPersonalTeleportMenu()
end)

StaffMenu.personalAppearance.OnOpen(function()
    StaffMenu.BuildPersonalAppearanceMenu()
end)

-- Illegal Builder OnOpen callbacks
StaffMenu.builderIllegal.OnOpen(function()
    StaffMenu.BuildIllegalBuilderMenu()
end)

StaffMenu.illegalHarvestBuilder.OnOpen(function()
    StaffMenu.BuildIllegalHarvestBuilderMenu()
end)

StaffMenu.illegalHarvestCreate.OnOpen(function()
    StaffMenu.BuildIllegalHarvestCreateMenu()
end)

StaffMenu.illegalHarvestList.OnOpen(function()
    StaffMenu.BuildIllegalHarvestListMenu()
end)

StaffMenu.illegalHarvestManage.OnOpen(function()
    StaffMenu.BuildIllegalHarvestManageMenu()
end)

StaffMenu.illegalHarvestItemSelect.OnOpen(function()
    StaffMenu.BuildIllegalHarvestItemSelectMenu()
end)

StaffMenu.illegalHarvestAnimSelect.OnOpen(function()
    StaffMenu.BuildIllegalHarvestAnimSelectMenu()
end)

StaffMenu.illegalHarvestFactionSelect.OnOpen(function()
    StaffMenu.BuildIllegalHarvestFactionSelectMenu()
end)

StaffMenu.illegalHarvestGradeSelect.OnOpen(function()
    StaffMenu.BuildIllegalHarvestGradeSelectMenu()
end)

StaffMenu.illegalStationBuilder.OnOpen(function()
    StaffMenu.BuildIllegalStationBuilderMenu()
end)

StaffMenu.illegalStationCreate.OnOpen(function()
    StaffMenu.BuildIllegalStationCreateMenu()
end)

StaffMenu.illegalStationList.OnOpen(function()
    StaffMenu.BuildIllegalStationListMenu()
end)

StaffMenu.illegalStationManage.OnOpen(function()
    StaffMenu.BuildIllegalStationManageMenu()
end)

StaffMenu.illegalStationRecipes.OnOpen(function()
    StaffMenu.BuildIllegalStationRecipesMenu()
end)

StaffMenu.illegalStationCatDetail.OnOpen(function()
    StaffMenu.BuildIllegalStationCatDetailMenu()
end)

StaffMenu.illegalStationFactionSelect.OnOpen(function()
    StaffMenu.BuildIllegalStationFactionSelectMenu()
end)

StaffMenu.illegalStationGradeSelect.OnOpen(function()
    StaffMenu.BuildIllegalStationGradeSelectMenu()
end)

StaffMenu.illegalRecipeBuilder.OnOpen(function()
    StaffMenu.BuildIllegalRecipeBuilderMenu()
end)

StaffMenu.illegalRecipeCreate.OnOpen(function()
    StaffMenu.BuildIllegalRecipeCreateMenu()
end)

StaffMenu.illegalRecipeList.OnOpen(function()
    StaffMenu.BuildIllegalRecipeListMenu()
end)

StaffMenu.illegalRecipeManage.OnOpen(function()
    StaffMenu.BuildIllegalRecipeManageMenu()
end)

StaffMenu.illegalRecipeItemSelect.OnOpen(function()
    StaffMenu.BuildIllegalRecipeItemSelectMenu()
end)

StaffMenu.illegalRecipeAnimSelect.OnOpen(function()
    StaffMenu.BuildIllegalRecipeAnimSelectMenu()
end)

StaffMenu.illegalRecipeIngredientSelect.OnOpen(function()
    StaffMenu.BuildIllegalRecipeIngredientAddMenu()
end)

StaffMenu.illegalTransformBuilder.OnOpen(function()
    StaffMenu.BuildIllegalTransformBuilderMenu()
end)

StaffMenu.illegalTransformCreate.OnOpen(function()
    StaffMenu.BuildIllegalTransformCreateMenu()
end)

StaffMenu.illegalTransformList.OnOpen(function()
    StaffMenu.BuildIllegalTransformListMenu()
end)

StaffMenu.illegalTransformManage.OnOpen(function()
    StaffMenu.BuildIllegalTransformManageMenu()
end)

StaffMenu.illegalTransformInputSelect.OnOpen(function()
    StaffMenu.BuildIllegalTransformInputSelectMenu()
end)

StaffMenu.illegalTransformOutputSelect.OnOpen(function()
    StaffMenu.BuildIllegalTransformOutputSelectMenu()
end)

StaffMenu.illegalTransformAnimSelect.OnOpen(function()
    StaffMenu.BuildIllegalTransformAnimSelectMenu()
end)

StaffMenu.illegalTransformFactionSelect.OnOpen(function()
    StaffMenu.BuildIllegalTransformFactionSelectMenu()
end)

StaffMenu.illegalTransformGradeSelect.OnOpen(function()
    StaffMenu.BuildIllegalTransformGradeSelectMenu()
end)

StaffMenu.builderDrug.OnOpen(function()
    StaffMenu.BuildDrugBuilderMenu()
end)

StaffMenu.drugCreate.OnOpen(function()
    StaffMenu.BuildDrugCreateMenu()
end)

StaffMenu.drugList.OnOpen(function()
    StaffMenu.BuildDrugListMenu()
end)

StaffMenu.drugItems.OnOpen(function()
    StaffMenu.BuildDrugItemsMenu()
end)

StaffMenu.drugHarvestList.OnOpen(function()
    StaffMenu.BuildDrugHarvestListMenu()
end)

StaffMenu.drugHarvestSpotEdit.OnOpen(function()
    StaffMenu.BuildDrugHarvestSpotEditMenu()
end)

StaffMenu.drugHarvestSpotManage.OnOpen(function()
    StaffMenu.BuildDrugHarvestSpotManageMenu()
end)

StaffMenu.drugTransformList.OnOpen(function()
    StaffMenu.BuildDrugTransformListMenu()
end)

StaffMenu.drugTransformSpotEdit.OnOpen(function()
    StaffMenu.BuildDrugTransformSpotEditMenu()
end)

StaffMenu.drugTransformSpotManage.OnOpen(function()
    StaffMenu.BuildDrugTransformSpotManageMenu()
end)

StaffMenu.drugHarvestAnim.OnOpen(function()
    StaffMenu.BuildDrugHarvestAnimMenu()
end)

StaffMenu.drugTransformAnim.OnOpen(function()
    StaffMenu.BuildDrugTransformAnimMenu()
end)

StaffMenu.drugHarvestFaction.OnOpen(function()
    StaffMenu.BuildDrugHarvestFactionMenu()
end)

StaffMenu.drugTransformFaction.OnOpen(function()
    StaffMenu.BuildDrugTransformFactionMenu()
end)

StaffMenu.drugHarvestGrade.OnOpen(function()
    StaffMenu.BuildDrugHarvestGradeMenu()
end)

StaffMenu.drugTransformGrade.OnOpen(function()
    StaffMenu.BuildDrugTransformGradeMenu()
end)

-- Legal Builder OnOpen callbacks
StaffMenu.builderLegal.OnOpen(function()
    StaffMenu.BuildLegalBuilderMenu()
end)

StaffMenu.legalStationBuilder.OnOpen(function()
    StaffMenu.BuildLegalStationBuilderMenu()
end)

StaffMenu.legalStationCreate.OnOpen(function()
    StaffMenu.BuildLegalStationCreateMenu()
end)

StaffMenu.legalStationList.OnOpen(function()
    StaffMenu.BuildLegalStationListMenu()
end)

StaffMenu.legalStationManage.OnOpen(function()
    StaffMenu.BuildLegalStationManageMenu()
end)

StaffMenu.legalStationRecipes.OnOpen(function()
    StaffMenu.BuildLegalStationRecipesMenu()
end)

StaffMenu.legalStationJobSelect.OnOpen(function()
    StaffMenu.BuildLegalStationJobSelectMenu()
end)

StaffMenu.legalStationGradeSelect.OnOpen(function()
    StaffMenu.BuildLegalStationGradeSelectMenu()
end)

StaffMenu.legalStationAnimSelect.OnOpen(function()
    StaffMenu.BuildLegalStationAnimSelectMenu()
end)

StaffMenu.legalRecipeList.OnOpen(function()
    StaffMenu.BuildLegalRecipeListMenu()
end)

StaffMenu.legalRecipeCreate.OnOpen(function()
    StaffMenu.BuildLegalRecipeCreateMenu()
end)

StaffMenu.legalRecipeManage.OnOpen(function()
    StaffMenu.BuildLegalRecipeManageMenu()
end)

StaffMenu.legalRecipeItemSelect.OnOpen(function()
    StaffMenu.BuildLegalRecipeItemSelectMenu()
end)

StaffMenu.legalRecipeAnimSelect.OnOpen(function()
    StaffMenu.BuildLegalRecipeAnimSelectMenu()
end)

StaffMenu.legalRecipeIngredientSelect.OnOpen(function()
    StaffMenu.BuildLegalRecipeIngredientAddMenu()
end)

-- Market Delivery Configuration OnOpen callbacks
StaffMenu.builderMarketDelivery.OnOpen(function()
    StaffMenu.BuildMarketDeliveryMenu()
end)

-- SAMS Management OnOpen callbacks
StaffMenu.samsManagement.OnOpen(function()
    StaffMenu.BuildSamsManagementMenu()
end)

StaffMenu.samsAnnonces.OnOpen(function()
    StaffMenu.BuildSamsAnnoncesMenu()
end)

StaffMenu.samsAnnonceDetail.OnOpen(function()
    StaffMenu.BuildSamsAnnonceDetailMenu()
end)

StaffMenu.samsRapports.OnOpen(function()
    StaffMenu.BuildSamsRapportsMenu()
end)

StaffMenu.samsRapportDetail.OnOpen(function()
    StaffMenu.BuildSamsRapportDetailMenu()
end)

StaffMenu.samsFactures.OnOpen(function()
    StaffMenu.BuildSamsFacturesMenu()
end)

StaffMenu.samsFactureDetail.OnOpen(function()
    StaffMenu.BuildSamsFactureDetailMenu()
end)

StaffMenu.samsPerms.OnOpen(function()
    StaffMenu.BuildSamsPermsMenu()
end)

StaffMenu.samsPermGrades.OnOpen(function()
    StaffMenu.BuildSamsPermGradesMenu()
end)

StaffMenu.samsPermDetail.OnOpen(function()
    StaffMenu.BuildSamsPermDetailMenu()
end)

local function applyStaffModeSideEffects(enabled)
    local bypassOutfit = (VFW.StaffOutfitEnabled ~= true) or GetResourceKvpString("staff_bypass_outfit") == "true"
    TriggerServerEvent("vfw:staff:mode", enabled, bypassOutfit)

    if enabled then
        TriggerServerEvent("Admin:activeBlips", true)
        TriggerServerEvent("Admin:gamerTag", true)
        if VFW.AdminOverley then VFW.AdminOverley() end
        local hideHudPreference = GetResourceKvpString("staff_hide_web_hud") == "true"
        if not hideHudPreference then
            if ToggleStaffHUD then ToggleStaffHUD(true) end
            if initStaffHud then initStaffHud() end
        end
        return
    end

    TriggerServerEvent("Admin:activeBlips", false)
    TriggerServerEvent("Admin:gamerTag", false)
    if ToggleStaffHUD then ToggleStaffHUD(false) end
    if StaffMenu.ToggleVehicleSpeedTags then StaffMenu.ToggleVehicleSpeedTags(false) end
    if StaffMenu.CleanupPersonalState then StaffMenu.CleanupPersonalState() end
    if StaffMenu.animatorSettings then
        StaffMenu.animatorSettings.noclipActive = false
    end
end

--- .BuildMainMenu
function StaffMenu.BuildMainMenu()
    StaffMenu.main.ClearItems()

    StaffMenu.main.Checkbox("MODE ADMINISTRATION", "Active ce mode pour afficher les outils staff", false, StaffMenu.adminChecked, function(_checked)
        local enabled = _checked == true
        StaffMenu.adminChecked = enabled

        if not enabled and VFW.IsNoclipActive and VFW.IsNoclipActive() then
            pcall(VFW.ToggleNoclip)
        end

        pcall(applyStaffModeSideEffects, enabled)
        StaffMenu.main.refresh()
    end)

    if StaffMenu.adminChecked then
        local reportCount = VFW.Reports and #VFW.Reports or 0
        local reportLabel = reportCount > 0 and (":document: REPORTS (%d)"):format(reportCount) or ":document: REPORTS (0)"
        StaffMenu.main.Button(reportLabel, "Voir et gérer les reports en attente des joueurs", nil, "chevron", false, function()
            StaffMenu.reports.open()
        end)

        StaffMenu.main.Button(":users: LISTE DES JOUEURS", "Rechercher, voir et interagir avec les joueurs en ligne ou hors ligne", nil, "chevron", false, function()
        end, StaffMenu.playersList)

        StaffMenu.main.Button(":target: ACTIONS PERSONNELLES", "Téléportation, apparence, heal, kill et autres actions sur soi-même", nil, "chevron", false, function()
        end, StaffMenu.personalActions)

        StaffMenu.main.Button(":settings: OPTIONS MODE STAFF", "Configurer le HUD staff, la tenue, les notifications et autres préférences", nil, "chevron", false, function()
        end, StaffMenu.optionsStaff)

        StaffMenu.main.Button(":wrench: OUTILS DE MODÉRATION", "Sanctions, bans, warns, give item, annonces et gestion des joueurs", nil, "chevron", false, function()
        end, StaffMenu.outils)

        StaffMenu.main.Button(":car: GESTION VÉHICULE", "Spawn, suppression, réparation, customs et gestion des véhicules", nil, "chevron", false, function()
        end, StaffMenu.vehicleManagement)

        local hasShortcutSetjob = VFW.HasStaffPerm("setjob")
        local hasShortcutSpawnVeh = VFW.HasStaffPerm("spawn_veh") or VFW.HasStaffPerm("dev")
        if hasShortcutSetjob or hasShortcutSpawnVeh then
            StaffMenu.main.Separator(":bookmark: RACCOURCIS")
        end

        if hasShortcutSetjob then
            StaffMenu.main.Button(":briefcase: DÉFINIR LE MÉTIER", "Sélectionner un joueur, puis choisir un job et un grade", nil, "chevron", false, function()
                StaffMenu.data.playerListForJob = StaffMenu.FetchPlayerList(false) or {}
            end, StaffMenu.selectPlayerForJob)
        end

        if hasShortcutSpawnVeh then
            StaffMenu.main.Button(":car: SPAWN VÉHICULE (LISTE)", "Parcourir les véhicules par catégorie et spawn devant soi", nil, "chevron", false, function()
            end, StaffMenu.carlistMain)
        end

        if VFW.HasStaffPerm("menu_staff_ped") then
            StaffMenu.main.Button(":user: MENU PEDS STAFF", "Gérer et placer des peds staff sur la map", nil, "chevron", false, function()
            end, StaffMenu.pedManagement)
        end

        if VFW.HasStaffPerm("list_staff") then
            StaffMenu.main.Button(":police: LISTE DES MODÉRATEURS & STAFF", "Voir tous les membres du staff actifs et leur grade", nil, "chevron", false, function()
                StaffMenu.data.staffList = {}
                StaffMenu.data.staffList = TriggerServerCallback("vfw:staff:getAllStaffFromDB") or {}
            end, StaffMenu.staff)
        end

        if VFW.HasStaffPerm("gestion") then
            StaffMenu.main.Button(":settings: GESTION", "Accès aux outils de gestion avancée du serveur", nil, "chevron", false, function()
                StaffMenu.main.close()
                SetTimeout(50, function()
                    StaffMenu.OpenGestionHub()
                end)
            end)
        end
    else
        StaffMenu.main.Textbox(
            "L'utilisation des permissions est réservé exclusivement dans le cadre de la modération In Game. Une utilisation non autorisé entrainera un retrait des permissions de manière définitive. Active le MODE ADMINISTRATION pour accéder aux outils.",
            "Attention!")
    end
end

--- .BuildPlayersListMenu
StaffMenu.playersList.OnOpen(function()
    StaffMenu._previewSource = nil
    if StaffMenu.players and StaffMenu.players.PlayerPreview then
        StaffMenu.players.PlayerPreview()
    end
    StaffMenu.playersList.ClearItems()
    CreateThread(function()
        StaffMenu.FetchPlayerList(false)
    end)

    StaffMenu.playersList.Button(":search: RECHERCHER UN JOUEUR", "Recherche par ID, UUID, prénom, nom, faction ou job.\nEn ligne ou Hors ligne", nil, "search", false, function()
        local query = VFW.Nui.KeyboardInput(true, "Entrez un ID / UUID / Prénom / Nom / Faction / Job")
        if not query or query == "" then return end
        StaffMenu.playerQuery = query
        StaffMenu.FetchPlayerList(false)
        StaffMenu.players.open()
    end)

    StaffMenu.playersList.Button(":users: JOUEURS EN LIGNE", "Voir la liste complète des joueurs actuellement connectés", nil, "chevron", false, function()
        StaffMenu.playerQuery = nil
    end, StaffMenu.players)

    StaffMenu.playersList.Button(":user: JOUEURS HORS LIGNE", "Accéder aux profils des joueurs déconnectés pour sanction ou gestion", nil, "chevron", false, function()
    end, StaffMenu.offlinePlayers)
end)

--- .BuildOptionsStaffMenu
StaffMenu.optionsStaff.OnOpen(function()
    StaffMenu.optionsStaff.ClearItems()

    -- HUD Staff
    if VFW.HasStaffPerm("staff_menu") then
        local currentHudState = GetResourceKvpString("staff_hide_web_hud") ~= "true"
      StaffMenu.optionsStaff.Checkbox(":monitor: HUD STAFF", "Afficher ou masquer le HUD staff en temps réel à l'écran", false, currentHudState, function(_checked)
            SetResourceKvp("staff_hide_web_hud", _checked and "false" or "true")
            if _checked then
                if ToggleStaffHUD then ToggleStaffHUD(true) end
                if initStaffHud then initStaffHud() end
            else
                if ToggleStaffHUD then ToggleStaffHUD(false) end
            end
        end)

        local hudOffDutyState = GetResourceKvpString("staff_hud_offduty") == "true"
      StaffMenu.optionsStaff.Checkbox(":signal: HUD HORS-SERVICE", "Garder le HUD staff visible même hors service (utile en cas d'afflux de reports)", false, hudOffDutyState, function(_checked)
            SetResourceKvp("staff_hud_offduty", _checked and "true" or "false")
            if ApplyHudOffDutyPreference then ApplyHudOffDutyPreference() end
        end)
    end

    -- Tenue Staff (option masquée tant que la tenue est désactivée)
    if VFW.StaffOutfitEnabled and VFW.HasStaffPerm("bypass_staff_outfit") then
        local wearingStaffOutfit = GetResourceKvpString("staff_bypass_outfit") ~= "true"
      StaffMenu.optionsStaff.Checkbox(":user: TENUE STAFF", "Porter la tenue staff automatiquement en mode staff (désactiver pour garder votre tenue RP)", false, wearingStaffOutfit, function(_checked)
            if _checked then
                SetResourceKvp("staff_bypass_outfit", "false")
                TriggerEvent("vfw:staff:setStaffClothes", true)
            else
                SetResourceKvp("staff_bypass_outfit", "true")
                TriggerEvent("vfw:staff:setStaffClothes", false)
            end
        end)
    end

    -- Bypass Porte
    if VFW.HasStaffPerm("doorlock") then
        local doorBypassActive = GetResourceKvpString("staff_door_bypass") == "true"
      StaffMenu.optionsStaff.Checkbox(":door: BYPASS PORTE", "Permet d'ouvrir/fermer les portes ayant un doorlock.", false, doorBypassActive, function(_checked)
            SetResourceKvp("staff_door_bypass", _checked and "true" or "false")
            TriggerServerEvent("vfw:staff:setDoorBypass", _checked)
        end)
    end

    -- Shadow Trace
    if VFW.HasStaffPerm("spectate") then
        StaffMenu.optionsStaff.Checkbox(":skull: SHADOW TRACE", "Permet de voir un clone à l'emplacement des personnes ayant déconnecté d'il y a moins de 30 minutes pour connaître l'UUID des gens ayant déconnecté.", false, ShadowCloneActive or false, function(_checked)
            TriggerServerEvent("vfw:shadowClone:toggle")
        end)
    end

    -- Cacher son gamertag
    if VFW.HasStaffPerm("hide_gamertag") then
        StaffMenu.optionsStaff.Checkbox(":info: CACHER SON GAMERTAG", "Masquer votre gamertag au-dessus de votre tête pour les autres staffs", false, StaffMenu.outilsState and StaffMenu.outilsState.hideMyTag or false, function(_checked)
            if StaffMenu.outilsState then StaffMenu.outilsState.hideMyTag = _checked end
            TriggerServerEvent("Admin:hideMyTag", _checked)
        end)
    end

    -- Raison de mort
    if VFW.HasStaffPerm("show_death_reasons") then
        local deathReasonsEnabled = GetResourceKvpString("staff_show_death_reasons") == "true"
      StaffMenu.optionsStaff.Checkbox(":skull: RAISONS DE MORT", "Afficher la cause de mort des joueurs en temps réel sur votre écran", false, deathReasonsEnabled, function(_checked)
            SetResourceKvp("staff_show_death_reasons", _checked and "true" or "false")
            TriggerServerEvent("staff:toggleDeathReasons", _checked)
            exports.core:ToggleDeathReasons(_checked)
        end)
    end

    -- Vitesse des véhicules
    if VFW.HasStaffPerm("show_vehicle_speed") then
        StaffMenu.optionsStaff.Checkbox(":car: VITESSE DES VÉHICULES", "Afficher la vitesse des véhicules au-dessus d'eux", false, StaffMenu.vehicleSpeedTagsActive, function(_checked)
            SetResourceKvp("staff_vehicle_speed_tags", _checked and "true" or "false")
            StaffMenu.ToggleVehicleSpeedTags(_checked)
        end)
    end

    -- Masquer notifications staff
    if VFW.HasStaffPerm("staff_menu") then
        local okPref, staffNotifPref = pcall(GetResourceKvpString, "staff_notifications_hidden")
        if not okPref then
            DeleteResourceKvp("staff_notifications_hidden")
            staffNotifPref = nil
        end
        local staffNotifHidden = staffNotifPref == nil or staffNotifPref == "1"
      StaffMenu.optionsStaff.Checkbox(":bell: MASQUER NOTIF STAFF", "Masquer les notifications d'action staff et joueur importantes : création de personnage, register, sanction sur un joueur dans le chat.", false, staffNotifHidden, function(_checked)
            SetResourceKvp("staff_notifications_hidden", _checked and "1" or "0")
        end)

        local reportNotifHidden = GetResourceKvpInt("staff_report_notif_hidden") == 1
        StaffMenu.optionsStaff.Checkbox(":bell: MASQUER NOTIF REPORTS", "Masquer les notifications de nouveaux reports et prises en charge", false, reportNotifHidden, function(_checked)
            SetResourceKvpInt("staff_report_notif_hidden", _checked and 1 or 0)
        end)

        StaffMenu.optionsStaff.Checkbox(":search: INFO JOUEUR AU VISEUR", "Afficher les infos RP d'un joueur ciblé au viseur (pseudo, nom RP, société, faction). Raccourci : /hud", false, StaffMenu.playerInfoCrosshairActive or false, function(_checked)
            if StaffMenu.TogglePlayerInfoCrosshair then
                StaffMenu.TogglePlayerInfoCrosshair(_checked)
            end
        end)
    end

    if VFW.HasStaffPerm("staff_chat") then
        StaffMenu.optionsStaff.Button(":chat: MESSAGE CHAT STAFF", "Envoyer un message au chat staff. Commande rapide : /mstaff [message]", nil, nil, false, function()
            local input = VFW.Nui.KeyboardInput(true, "Message chat staff", "")
            if not input or input == "" then return end
            TriggerServerEvent("vfw:staff:sendChatMessage", input)
        end)
    end

    -- Annonces
    if VFW.HasStaffPerm("announce_serv") then
        StaffMenu.optionsStaff.Button(":megaphone: ANNONCE SERVEUR", "Envoyer une notification visible par tous les joueurs (ou en zone)", nil, "chevron", false, function()
            local annonce = VFW.Nui.KeyboardInput(true, "Contenu de l'annonce")
            annonce = stripColorCodes(annonce)
            if not annonce or annonce == "" then
                return
            end
            local radius = VFW.Nui.KeyboardInput(true, "Radius (0 = Global)", "0")
            local zone = tonumber(radius)
            if not radius or zone == nil or zone < 0 then
                return
            end

            if zone == 0 then
                TriggerServerEvent("vfw:staff:sendGlobalAnnouncement", annonce)
            else
                if zone < 1 then zone = 1 end
                if zone > 750 then zone = 750 end
                TriggerServerEvent("vfw:staff:sendZoneAnnouncement", zone, annonce)
            end
        end)
    end

    if VFW.HasStaffPerm("announce_modo") then
        StaffMenu.optionsStaff.Button(":megaphone: ANNONCE STAFF", "Envoyer une notification visible uniquement par les membres du staff", nil, "chevron", false, function()
            local annonce = VFW.Nui.KeyboardInput(true, "Contenu de l'annonce")
            annonce = stripColorCodes(annonce)
            if annonce and annonce ~= "" then
                TriggerServerEvent("core:vnotif:createAlert:staff", annonce)
            end
        end)
    end

    -- Custom Teleports
    StaffMenu.optionsStaff.Button(":pin: GÉRER MES TÉLÉPORTATIONS CUSTOM", "Sauvegarder et gérer vos points de téléportation personnalisés", nil, "chevron", false, function()
    end, StaffMenu.customTeleports)
end)

--- .AdminOverley
function VFW.AdminOverley()
    -- This function is now empty as the web HUD has been removed
    -- The native staff HUD handles the display now
end

--- .OpenStaffMenu
---@return any
function VFW.OpenStaffMenu()
    if VFW.SyncStaffAccess then
        VFW.SyncStaffAccess()
    end
    if not VFW.PlayerData or not VFW.HasStaffPerm("staff_menu") then
        console.debug("Vous n'avez pas la permission d'utiliser le menu staff.")
        return
    end

    StaffMenu.main.toggle()
end
