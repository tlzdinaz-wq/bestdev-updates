local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/metier.png")

local main = VUI:CreateMenu("Menu Métier", defaultBanner, true)
local announceSubMenu = VUI:CreateSubMenu(main, "Annonces", defaultBanner, true)
local backupSubMenu = VUI:CreateSubMenu(actionsSubMenu, "Demande de Backup", defaultBanner, true)
local invoiceSubMenu = VUI:CreateSubMenu(main, "Factures", defaultBanner, true)
local farmLocationsSubMenu = VUI:CreateSubMenu(main, "Points d'intérêt", defaultBanner, true)
local journalistToolsSubMenu = VUI:CreateSubMenu(main, "Outils Journaliste", defaultBanner, true)
-- Libellé selon la mentalité serveur (config/locale.lua) : FR = "Secours", US = "EMS".
local samsActionsSubMenu = VUI:CreateSubMenu(main, MENTA_SERVER == "FR" and "Actions Secours" or "Actions EMS", defaultBanner, true)
local samsBackupSubMenu = VUI:CreateSubMenu(samsActionsSubMenu, "Demande de BackUp", defaultBanner, true)
local samsBackupGlobalSubMenu = VUI:CreateSubMenu(samsBackupSubMenu, "Backup Global", defaultBanner, true)
local samsBackupOtherSubMenu = VUI:CreateSubMenu(samsBackupSubMenu, "Backup", defaultBanner, true)
local gouvActionsSubMenu = VUI:CreateSubMenu(main, "Actions de sécurité", defaultBanner, true)
local gouvInvoiceSubMenu = VUI:CreateSubMenu(main, "Factures", defaultBanner, true)
local policeActionsSubMenu = VUI:CreateSubMenu(main, "Actions Citoyen", defaultBanner, true)
local policeToolsSubMenu = VUI:CreateSubMenu(main, "Outils Police", defaultBanner, true)
local policeK9SubMenu = VUI:CreateSubMenu(policeToolsSubMenu, "K9", defaultBanner, true)
local policeVehicleSubMenu = VUI:CreateSubMenu(main, "Actions Véhicules", defaultBanner, true)

-- USSS submenus (same actions but filtered)
local usssActionsSubMenu = VUI:CreateSubMenu(main, "Actions Citoyen", defaultBanner, true)
local usssToolsSubMenu = VUI:CreateSubMenu(main, "Outils USSS", defaultBanner, true)
local usssK9SubMenu = VUI:CreateSubMenu(usssToolsSubMenu, "K9", defaultBanner, true)
local usssVehicleSubMenu = VUI:CreateSubMenu(main, "Actions Véhicules", defaultBanner, true)

-- Table des sous-menus pour mise à jour dynamique du banner
local allSubMenus = {
    announceSubMenu, backupSubMenu, invoiceSubMenu, farmLocationsSubMenu,
    journalistToolsSubMenu, samsActionsSubMenu, samsBackupSubMenu,
    samsBackupGlobalSubMenu, samsBackupOtherSubMenu, gouvActionsSubMenu,
    gouvInvoiceSubMenu, policeActionsSubMenu, policeToolsSubMenu,
    policeK9SubMenu, policeVehicleSubMenu, usssActionsSubMenu,
    usssToolsSubMenu, usssK9SubMenu, usssVehicleSubMenu
}

---@class JobMenuRegistry
---@field builders table<string, fun(menu: table, subMenus: table)[]>
---@field subMenus table<string, table<string, table>>
---@field typeBuilders table<string, fun(menu: table, subMenus: table)[]>
local JobMenuRegistry = {
    builders = {},
    subMenus = {},
    typeBuilders = {},
    typeSubMenus = {}
}

--- Register a menu builder for a specific job or multiple jobs
---@param jobNames string|string[] The job name(s) (e.g., "mecano" or {"mecano", "mecano2", "bennys"})
---@param builder fun(menu: table, subMenus: table) Function that adds items to the menu
---@param priority? number Optional priority (lower = earlier in menu, default 50)
function JobMenuRegistry.register(jobNames, builder, priority)
    -- Normalize to array
    local jobs = type(jobNames) == "table" and jobNames or { jobNames }

    for _, jobName in ipairs(jobs) do
        if not JobMenuRegistry.builders[jobName] then
            JobMenuRegistry.builders[jobName] = {}
        end

        table.insert(JobMenuRegistry.builders[jobName], {
            fn = builder,
            priority = priority or 50
        })

        -- Sort by priority
        table.sort(JobMenuRegistry.builders[jobName], function(a, b)
            return a.priority < b.priority
        end)
    end
end

--- Register a menu builder for all jobs of a specific society type
---@param societyType string The society type (e.g., "ltd", "farm", "mechanic")
---@param builder fun(menu: table, subMenus: table) Function that adds items to the menu
---@param priority? number Optional priority (lower = earlier in menu, default 50)
function JobMenuRegistry.registerByType(societyType, builder, priority)
    if not JobMenuRegistry.typeBuilders[societyType] then
        JobMenuRegistry.typeBuilders[societyType] = {}
    end

    table.insert(JobMenuRegistry.typeBuilders[societyType], {
        fn = builder,
        priority = priority or 50
    })

    -- Sort by priority
    table.sort(JobMenuRegistry.typeBuilders[societyType], function(a, b)
        return a.priority < b.priority
    end)
end

--- Create a submenu for a specific job or multiple jobs
---@param jobNames string|string[] The job name(s)
---@param subMenuId string Unique identifier for the submenu
---@param title string Title of the submenu
---@param banner? string Optional custom banner
---@return table The created submenu
function JobMenuRegistry.createSubMenu(jobNames, subMenuId, title, banner)
    -- Normalize to array
    local jobs = type(jobNames) == "table" and jobNames or { jobNames }

    local subMenu = VUI:CreateSubMenu(main, title, banner or defaultBanner, true)

    -- Register the submenu for all specified jobs
    for _, jobName in ipairs(jobs) do
        if not JobMenuRegistry.subMenus[jobName] then
            JobMenuRegistry.subMenus[jobName] = {}
        end
        JobMenuRegistry.subMenus[jobName][subMenuId] = subMenu
    end

    return subMenu
end

--- Get a submenu for a job
---@param jobName string The job name
---@param subMenuId string The submenu identifier
---@return table|nil The submenu or nil if not found
function JobMenuRegistry.getSubMenu(jobName, subMenuId)
    if JobMenuRegistry.subMenus[jobName] then
        return JobMenuRegistry.subMenus[jobName][subMenuId]
    end
    return nil
end

--- Get all submenus for a job
---@param jobName string The job name
---@return table<string, table> The submenus table
function JobMenuRegistry.getSubMenus(jobName)
    return JobMenuRegistry.subMenus[jobName] or {}
end

--- Create a submenu for all jobs of a specific society type
---@param societyType string The society type (e.g., "mechanic", "concess")
---@param subMenuId string Unique identifier for the submenu
---@param title string Title of the submenu
---@param banner? string Optional custom banner
---@return table The created submenu
function JobMenuRegistry.createSubMenuByType(societyType, subMenuId, title, banner)
    local subMenu = VUI:CreateSubMenu(main, title, banner or defaultBanner, true)

    if not JobMenuRegistry.typeSubMenus[societyType] then
        JobMenuRegistry.typeSubMenus[societyType] = {}
    end
    JobMenuRegistry.typeSubMenus[societyType][subMenuId] = subMenu

    return subMenu
end

--- Get all type-based submenus for a society type
---@param societyType string The society type
---@return table<string, table> The submenus table
function JobMenuRegistry.getTypeSubMenus(societyType)
    return JobMenuRegistry.typeSubMenus[societyType] or {}
end

--- Build job-specific menu items
---@param jobName string The current job name
local function buildJobSpecificMenu(jobName)
    local subMenus = JobMenuRegistry.getSubMenus(jobName)

    -- Build job-specific builders
    local builders = JobMenuRegistry.builders[jobName]
    if builders then
        for _, builderData in ipairs(builders) do
            builderData.fn(main, subMenus)
        end
    end

    -- Build type-specific builders based on society type (fallback to job type)
    local societyType = (Society.data and Society.data.type) or (VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.type)
    if societyType then
        local typeSubMenus = JobMenuRegistry.getTypeSubMenus(societyType)
        local mergedSubMenus = {}
        for k, v in pairs(subMenus) do mergedSubMenus[k] = v end
        for k, v in pairs(typeSubMenus) do mergedSubMenus[k] = v end

        local typeBuilders = JobMenuRegistry.typeBuilders[societyType]
        if typeBuilders then
            for _, builderData in ipairs(typeBuilders) do
                builderData.fn(main, mergedSubMenus)
            end
        end
    end
end

-- Export the registry for other resources to use
exports("getJobMenuRegistry", function()
    return JobMenuRegistry
end)

-- Also export convenience functions
exports("registerJobMenu", function(jobName, builder, priority)
    JobMenuRegistry.register(jobName, builder, priority)
end)

exports("createJobSubMenu", function(jobName, subMenuId, title, banner)
    return JobMenuRegistry.createSubMenu(jobName, subMenuId, title, banner)
end)

-- Farm job configs mapping
local FarmConfigs = {
    ["tabac"] = function()
        return TabacConfig
    end,
    ["vigneron"] = function()
        return VigneronConfig
    end,
    ["globeoil"] = function()
        return GlobeOilConfig
    end,
    ["cbdshop"] = function()
        return CbdShopConfig
    end,
    ["unicorn"] = function()
        return UnicornBarConfig
    end,
    ["yellowjack"] = function()
        return YellowJackBarConfig
    end,
    ["asgard"] = function()
        return AsgardBarConfig
    end,
    ["irishpub"] = function()
        return IrishPubBarConfig
    end,
    ["henhouse"] = function()
        return HenHouseBarConfig
    end,
    ["billard"] = function()
        return BillardBarConfig
    end,
    ["cayo_lagoon"] = function()
        return CayoLagoonBarConfig
    end,
}

-- Labels for farm location types
local FarmLocationLabels = {
    plants = "🌿 Zone de Récolte",
    harvest = "🌿 Zone de Récolte",
    processing = "⚙️ Zone de Traitement",
    packaging = "📦 Zone d'Emballage",
    selling = "💰 Point de Vente"
}

-- Set a waypoint to the given coordinates
local function setWaypoint(coords)
    if not coords then
        return
    end

    local x, y, z
    if type(coords) == "vector3" or type(coords) == "vector4" then
        x, y, z = coords.x, coords.y, coords.z
    elseif type(coords) == "table" then
        x, y, z = coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]
    end

    if x and y then
        SetNewWaypoint(x + 0.0, y + 0.0)
        local societyImage = TriggerServerCallback("core:get:societyImage")
        VFW.ShowNotification({ type = 'JOB', image = societyImage, title = VFW.PlayerData and VFW.PlayerData.job.label, subtitle = "Information GPS", content = "Les coordonnées de votre GPS ont été mises à jour." })
    end
end

-- Get the first coordinate from a location config
local function getFirstCoord(locationData)
    if not locationData then
        return nil
    end

    -- If it's a direct vector
    if type(locationData) == "vector3" or type(locationData) == "vector4" then
        return locationData
    end

    -- If it's a table
    if type(locationData) == "table" then
        -- Check if it's an array of vectors
        if locationData[1] then
            return locationData[1]
        end
        -- Check if it's a keyed table (like processing in vigneron)
        for _, coord in pairs(locationData) do
            if type(coord) == "vector3" or type(coord) == "vector4" then
                return coord
            elseif type(coord) == "table" and (coord.x or coord[1]) then
                return coord
            end
        end
    end

    return nil
end

local function renderAnnounceMenu()
    announceSubMenu.Button("Annonce ouverture", "Cooldown: 1 minute", nil, "chevron", false, function()
        TriggerServerEvent("core:server:announceEntreprise:openingClosing", true)
        announceSubMenu.close()
    end)

    announceSubMenu.Button("Annonce fermeture", "Cooldown: 1 minute", nil, "chevron", false, function()
        TriggerServerEvent("core:server:announceEntreprise:openingClosing", false)
        announceSubMenu.close()
    end)

    local jobData = TriggerServerCallback("core:jobs:getJobData", VFW.PlayerData.job.name)
    if jobData and jobData.custom and jobData.custom.allowCustomAnnouncement then
        announceSubMenu.Button("Annonce personnalisée", "Cooldown: 10 minutes, supporte les couleurs", nil, "chevron", false,
                function()
                    local message = VFW.Nui.ColorTextEditor(true, "Annonce personnalisée", "", function(previewText)
                        TriggerServerEvent("core:server:announceEntreprise:previewCustomMessage", previewText)
                    end)
                    if message and message ~= "" then
                        TriggerServerEvent("core:server:announceEntreprise:customMessage", message)
                        announceSubMenu.close()
                    end
                end)
    end
end

announceSubMenu.OnOpen(function()
    renderAnnounceMenu()
end)

local function renderBackupMenu()
    backupSubMenu.Button("Backup 1", "", nil, "chevron", false, function()
        TriggerServerEvent("dispatch:server:requestBackup", 1)
        VFW.ShowNotification({ type = 'BLEU', content = "Backup 1 demandé" })
        backupSubMenu.close()
    end)

    backupSubMenu.Button("Backup 2", "", nil, "chevron", false, function()
        TriggerServerEvent("dispatch:server:requestBackup", 2)
        VFW.ShowNotification({ type = 'BLEU', content = "Backup 2 demandé" })
        backupSubMenu.close()
    end)

    backupSubMenu.Button("Backup 3", "", nil, "chevron", false, function()
        TriggerServerEvent("dispatch:server:requestBackup", 3)
        VFW.ShowNotification({ type = 'BLEU', content = "Backup 3 demandé" })
        backupSubMenu.close()
    end)
end

backupSubMenu.OnOpen(function()
    renderBackupMenu()
end)

local function renderInvoiceMenu()
    invoiceSubMenu.Button("Créer une facture", "", nil, "chevron", false, function()
        TriggerEvent("vfw:radial:open:invoice")
        invoiceSubMenu.close()
    end)

    local POLICE_JOBS_FINE = PoliceJobsList
    if VFW.PlayerData and VFW.PlayerData.job and POLICE_JOBS_FINE[VFW.PlayerData.job.name] then
        invoiceSubMenu.Button("Créer une amende", "Sélectionnez un citoyen à proximité", nil, "chevron", false, function()
            invoiceSubMenu.close()
            Wait(200)
            local selectedPlayer = VFW.StartSelect(5.0, true)
            if not selectedPlayer then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun citoyen sélectionné" })
                return
            end
            local targetServerId = GetPlayerServerId(selectedPlayer)
            TriggerEvent("police:openFineMenu", targetServerId)
        end)
    end
end

invoiceSubMenu.OnOpen(function()
    renderInvoiceMenu()
end)

local function renderFarmLocationsMenu()
    local jobName = VFW.PlayerData.job.name
    local configGetter = FarmConfigs[jobName]

    if not configGetter then
        farmLocationsSubMenu.Button("Aucun point disponible", "Ce métier n'a pas de configuration", nil, nil, true)
        return
    end

    local config = configGetter()
    if not config then
        farmLocationsSubMenu.Button("Aucun point disponible", "Configuration non trouvée", nil, nil, true)
        return
    end

    -- Add harvest/plants button (dynamic from DB, fallback to static config)
    local harvestCoord = TriggerServerCallback("core:farm:getHarvestCoords", jobName)
    if not harvestCoord then
        local harvestData = config.harvest or config.plants
        if harvestData then
            harvestCoord = getFirstCoord(harvestData)
        end
    end
    if harvestCoord then
        farmLocationsSubMenu.Button(FarmLocationLabels.harvest or "Zone de Récolte", "Marquer sur le GPS", nil, "chevron", false, function()
            setWaypoint(harvestCoord)
            farmLocationsSubMenu.close()
        end)
    end

    -- Add processing button (dynamic from DB, fallback to static config)
    local processingCoord = TriggerServerCallback("core:farm:getProcessingCoords", jobName)
    if not processingCoord and config.processing then
        processingCoord = getFirstCoord(config.processing)
    end
    if processingCoord then
        farmLocationsSubMenu.Button(FarmLocationLabels.processing or "Zone de Traitement", "Marquer sur le GPS", nil, "chevron", false, function()
            setWaypoint(processingCoord)
            farmLocationsSubMenu.close()
        end)
    end

    -- Add packaging button (if exists)
    if config.packaging then
        local coord = getFirstCoord(config.packaging)
        if coord then
            farmLocationsSubMenu.Button(FarmLocationLabels.packaging or "Zone d'Emballage", "Marquer sur le GPS", nil, "chevron", false, function()
                setWaypoint(coord)
                farmLocationsSubMenu.close()
            end)
        end
    end

    -- Add selling point button (from FarmingData)
    local sellingCoords = TriggerServerCallback("core:farm:getSellingCoords", jobName)
    if sellingCoords then
        farmLocationsSubMenu.Button(FarmLocationLabels.selling or "Point de Vente", "Marquer sur le GPS", nil, "chevron", false, function()
            setWaypoint(sellingCoords)
            farmLocationsSubMenu.close()
        end)
    end
end

farmLocationsSubMenu.OnOpen(function()
    renderFarmLocationsMenu()
end)

-- ============================================================
-- SAMS EMS: Fonctions utilitaires
-- ============================================================
local function getSamsHospital()
    if SN_SAMS and SN_SAMS.Config and SN_SAMS.Config.Hospitals then
        local coords = GetEntityCoords(PlayerPedId())
        local closest = "pillbox"
        local closestDist = math.huge
        for name, hospital in pairs(SN_SAMS.Config.Hospitals) do
            local dist = #(coords - hospital.coords)
            if dist < closestDist then
                closestDist = dist
                closest = name
            end
        end
        return closest
    end
    local jobName = VFW.PlayerData.job.name
    if jobName == "sams_pib" then return "pillbox" end
    if jobName == "sams_pab" then return "paleto" end
    return "pillbox"
end

local function getSamsStreet()
    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    if streetHash and streetHash ~= 0 then
        return GetStreetNameFromHashKey(streetHash)
    end
    return "Position inconnue"
end

local function getClosestAlivePlayer(maxDist)
    local closestId, closestPed = VFW.Game.GetClosestPlayer(GetEntityCoords(PlayerPedId()), maxDist)
    if not closestPed then return nil, nil end
    if IsPedDeadOrDying(closestPed, true) then return nil, nil end
    return GetPlayerServerId(closestId), closestPed
end

local function getClosestComaPlayer(maxDist)
    local myCoords = GetEntityCoords(PlayerPedId())
    local closestDist = maxDist
    local closestServerId = nil

    -- Chercher parmi les vrais peds joueurs (mort natif)
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < closestDist and IsPedDeadOrDying(ped, true) then
                closestDist = dist
                closestServerId = GetPlayerServerId(playerId)
            end
        end
    end

    -- Chercher parmi les death clones (système de coma custom)
    -- GetActivePlayers() suffit : le clone est networked, son owner est dans les joueurs actifs
    local mySrc = GetPlayerServerId(PlayerId())
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local serverId = GetPlayerServerId(playerId)
            -- Le clone est networked depuis le client du joueur mort, on le retrouve via son ped réseau
            local ped = GetPlayerPed(playerId)
            -- Si le vrai ped est invisible/alpha 0, le joueur est probablement en coma custom
            -- On cherche son clone via le state bag Player
            local cloneNetId = Player(playerId).state.deathCloneNetId
            if cloneNetId then
                local clone = NetworkGetEntityFromNetworkId(cloneNetId)
                if clone and clone ~= 0 and DoesEntityExist(clone) then
                    local dist = #(myCoords - GetEntityCoords(clone))
                    if dist < closestDist then
                        closestDist = dist
                        closestServerId = serverId
                    end
                end
            end
        end
    end

    return closestServerId
end

local function getClosestComaPlayerWithPed(maxDist)
    local myCoords = GetEntityCoords(PlayerPedId())
    local closestDist = maxDist
    local closestServerId = nil
    local closestPed = nil

    -- Chercher parmi les vrais peds joueurs (mort natif)
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < closestDist and IsPedDeadOrDying(ped, true) then
                closestDist = dist
                closestServerId = GetPlayerServerId(playerId)
                closestPed = ped
            end
        end
    end

    -- Chercher parmi les death clones (système de coma custom)
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local cloneNetId = Player(playerId).state.deathCloneNetId
            if cloneNetId then
                local clone = NetworkGetEntityFromNetworkId(cloneNetId)
                if clone and clone ~= 0 and DoesEntityExist(clone) then
                    local dist = #(myCoords - GetEntityCoords(clone))
                    if dist < closestDist then
                        closestDist = dist
                        closestServerId = GetPlayerServerId(playerId)
                        closestPed = GetPlayerPed(playerId)
                    end
                end
            end
        end
    end

    return closestServerId, closestPed
end

-- ============================================================
-- SAMS EMS: Rendu sous-menu Actions EMS
-- ============================================================
local function renderSamsActionsMenu()
    samsActionsSubMenu.Button("Soigner légèrement", "Soins de base sur un citoyen proche", nil, "chevron", false, function()
        local targetId = getClosestAlivePlayer(3.0)
        if not targetId then
            VFW.ShowNotification({ type = "JOB", logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Soins", content = "Il n'y a aucune personne proche de vous" })
            return
        end
        samsActionsSubMenu.close()
        TriggerServerEvent("sn_sams:healPlayer", targetId, "light")
    end)

    samsActionsSubMenu.Button("Soigner important", "Soins avancés sur un citoyen proche", nil, "chevron", false, function()
        local targetId = getClosestAlivePlayer(3.0)
        if not targetId then
            VFW.ShowNotification({ type = "JOB", logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Soins", content = "Il n'y a aucune personne proche de vous" })
            return
        end
        samsActionsSubMenu.close()
        TriggerServerEvent("sn_sams:healPlayer", targetId, "heavy")
    end)

    samsActionsSubMenu.Button("Inspecter une personne", "Examiner les blessures d'un citoyen dans le coma", nil, "chevron", false, function()
        local _, targetPed = getClosestComaPlayerWithPed(3.0)
        if not targetPed then
            VFW.ShowNotification({ type = "JOB", logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Inspection", content = "Il n'y a personne dans le coma proche de vous" })
            return
        end
        samsActionsSubMenu.close()

        local playerPed = PlayerPedId()
        local animDict = "amb@medic@standing@kneel@base"
        local animName = "base"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Wait(10) end
        TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 5000, 1, 0, false, false, false)
        Wait(5000)
        ClearPedTasks(playerPed)
        RemoveAnimDict(animDict)

        VFW.Jobs.IdentificationComa(targetPed)
    end)

    samsActionsSubMenu.Button("Réanimer", "Réanimer un citoyen dans le coma", nil, "chevron", false, function()
        local targetId = getClosestComaPlayer(3.0)
        if not targetId then
            VFW.ShowNotification({ type = "JOB", logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Réanimation", content = "Il n'y a personne dans le coma à proximité" })
            return
        end
        samsActionsSubMenu.close()
        TriggerServerEvent("sn_sams:healPlayer", targetId, "revive")
    end)

    samsActionsSubMenu.Button("Ouvrir le menu IRM", "Accéder à l'interface de l'IRM pour réaliser un scanner", nil, "chevron", false, function()
        samsActionsSubMenu.close()
        ExecuteCommand("menuirm")
    end)

    samsActionsSubMenu.Button("Ouvrir le menu Radio", "Accéder à l'interface radio du SAMS", nil, "chevron", false, function()
        samsActionsSubMenu.close()
        ExecuteCommand("menuradio")
    end)

    samsActionsSubMenu.Button("Demande de BackUp", "Appeler des renforts", nil, "chevron", false, function()
    end, samsBackupSubMenu)
end

-- ============================================================
-- Gouvernement: Sous-menu Actions de sécurité
-- ============================================================
local gouvIsProcessing = false
local GOUV_IMG = VFW.CDN.Get("entreprise/gouvernement.png")

local function gouvNotifClient(subtitle, content)
    VFW.ShowNotification({ type = "JOB", title = "Gouvernement", subtitle = subtitle, image = GOUV_IMG, content = content })
end

local function getGouvClosestPlayerServerId(maxDistance)
    local myCoords = GetEntityCoords(PlayerPedId())
    local players = GetActivePlayers()
    local closestDist = maxDistance or 5.0
    local closestServerId = nil

    for i = 1, #players do
        local playerId = players[i]
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < closestDist then
                closestDist = dist
                closestServerId = GetPlayerServerId(playerId)
            end
        end
    end

    return closestServerId
end

local function getGouvClosestVehicle(maxDistance)
    local coords = GetEntityCoords(PlayerPedId())
    local closestVeh = nil
    local closestDist = maxDistance or 10.0
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist < closestDist then
                closestDist = dist
                closestVeh = vehicle
            end
        end
    end
    return closestVeh
end

gouvActionsSubMenu.OnOpen(function()
    gouvActionsSubMenu.ClearItems()

    gouvActionsSubMenu.Button(
        "Menotter / Démenotter",
        "Menottez ou démenottez un citoyen proche",
        nil, "arrow", false,
        function()
            if gouvIsProcessing then return end
            local targetServerId = getGouvClosestPlayerServerId(2.0)
            if not targetServerId then
                gouvNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            gouvIsProcessing = true
            TriggerServerEvent("gouvernement:toggleHandcuff", targetServerId)
            SetTimeout(2000, function() gouvIsProcessing = false end)
        end
    )

    gouvActionsSubMenu.Button(
        "Escorter",
        "Escortez ou relâchez un citoyen menotté",
        nil, "arrow", false,
        function()
            local targetServerId = getGouvClosestPlayerServerId(2.0)
            if not targetServerId then
                gouvNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            TriggerServerEvent("gouvernement:escort", targetServerId)
        end
    )

    gouvActionsSubMenu.Button(
        "Mettre / Sortir du véhicule",
        "Placez ou sortez un citoyen menotté d'un véhicule",
        nil, "arrow", false,
        function()
            local targetServerId = getGouvClosestPlayerServerId(2.0)
            if not targetServerId then
                gouvNotifClient("Action", "Aucun citoyen à proximité")
                return
            end

            local targetPlayerId = GetPlayerFromServerId(targetServerId)
            local targetPed = targetPlayerId and GetPlayerPed(targetPlayerId)

            if targetPed and DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                -- Cible dans un véhicule → la sortir
                TriggerServerEvent("gouvernement:removeFromVehicle", targetServerId)
            else
                -- Cible hors véhicule → la mettre dedans
                local vehicle = getGouvClosestVehicle(10.0)
                if not vehicle then
                    gouvNotifClient("Véhicule", "Aucun véhicule à proximité")
                    return
                end
                if NetworkGetEntityIsNetworked(vehicle) then
                    TriggerServerEvent("gouvernement:putInVehicle", targetServerId, NetworkGetNetworkIdFromEntity(vehicle))
                end
            end
        end
    )

    gouvActionsSubMenu.Button(
        "Fouiller",
        "Fouillez l'inventaire d'un citoyen",
        nil, "arrow", false,
        function()
            local targetServerId = getGouvClosestPlayerServerId(2.0)
            if not targetServerId then
                gouvNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            TriggerServerEvent("gouvernement:search", targetServerId)
        end
    )
end)

gouvInvoiceSubMenu.OnOpen(function()
    gouvInvoiceSubMenu.ClearItems()

    local hasInvoicePerm = TriggerServerCallback("gouvernement:checkPerm", "create_invoice")
    local hasInvoiceCompanyPerm = TriggerServerCallback("gouvernement:checkPerm", "create_invoice_company")

    if hasInvoicePerm then
        gouvInvoiceSubMenu.Button(
            "Facture citoyen",
            "Le citoyen paie de son compte personnel",
            nil, "arrow", false,
            function()
                TriggerEvent("vfw:radial:open:invoice", nil, "personal")
                gouvInvoiceSubMenu.close()
            end
        )
    end

    if hasInvoiceCompanyPerm then
        gouvInvoiceSubMenu.Button(
            "Facture entreprise",
            "L'entreprise du citoyen paie la facture",
            nil, "arrow", false,
            function()
                TriggerEvent("vfw:radial:open:invoice", nil, "company")
                gouvInvoiceSubMenu.close()
            end
        )
    end
end)

-- ============================================================
-- POLICE (LSPD / LSSD): Helper functions
-- ============================================================
local policeIsProcessing = false
local function getPoliceImg()
    return VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png")
end

local function policeNotifClient(subtitle, content)
    VFW.ShowNotification({ type = "JOB", title = VFW.PlayerData.job.label or "sasp", subtitle = subtitle, image = getPoliceImg(), content = content })
end

local function getPoliceClosestPlayerServerId(maxDistance)
    local myCoords = GetEntityCoords(PlayerPedId())
    local players = GetActivePlayers()
    local closestDist = maxDistance or 5.0
    local closestServerId = nil

    for i = 1, #players do
        local playerId = players[i]
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < closestDist then
                closestDist = dist
                closestServerId = GetPlayerServerId(playerId)
            end
        end
    end

    return closestServerId
end

local function getPoliceClosestVehicle(maxDistance)
    local coords = GetEntityCoords(PlayerPedId())
    local closestVeh = nil
    local closestDist = maxDistance or 10.0
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist < closestDist then
                closestDist = dist
                closestVeh = vehicle
            end
        end
    end
    return closestVeh
end

-- ============================================================
-- POLICE: Sous-menu Actions
-- ============================================================
policeActionsSubMenu.OnOpen(function()
    policeActionsSubMenu.ClearItems()
    policeIsProcessing = false -- Reset au cas où une action précédente aurait bloqué l'état

    policeActionsSubMenu.Button(
        "Menotter / Démenotter",
        "Menottez ou démenottez un citoyen proche",
        nil, "arrow", false,
        function()
            if policeIsProcessing then return end
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then
                policeNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            policeIsProcessing = true
            TriggerServerEvent("police:toggleHandcuff", targetServerId)
            SetTimeout(2000, function() policeIsProcessing = false end)
        end
    )

    policeActionsSubMenu.Button(
        "Escorter",
        "Escortez ou relâchez un citoyen menotté",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then
                policeNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            TriggerServerEvent("police:escort", targetServerId)
        end
    )

    policeActionsSubMenu.Button(
        "Mettre / Sortir du véhicule",
        "Placez ou sortez un citoyen menotté d'un véhicule",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then
                policeNotifClient("Action", "Aucun citoyen à proximité")
                return
            end

            local targetPlayerId = GetPlayerFromServerId(targetServerId)
            local targetPed = targetPlayerId and GetPlayerPed(targetPlayerId)

            if targetPed and DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                -- Cible dans un véhicule → la sortir
                TriggerServerEvent("police:removeFromVehicle", targetServerId)
            else
                -- Cible hors véhicule → la mettre dedans
                local vehicle = getPoliceClosestVehicle(10.0)
                if not vehicle then
                    policeNotifClient("Véhicule", "Aucun véhicule à proximité")
                    return
                end
                if NetworkGetEntityIsNetworked(vehicle) then
                    TriggerServerEvent("police:putInVehicle", targetServerId, NetworkGetNetworkIdFromEntity(vehicle))
                end
            end
        end
    )

    policeActionsSubMenu.Button(
        "Fouiller",
        "Fouillez l'inventaire d'un citoyen",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then
                policeNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            TriggerServerEvent("police:search", targetServerId)
        end
    )

    policeActionsSubMenu.Button(
        "Bracelet électronique",
        "Posez ou retirez un bracelet électronique",
        nil, "arrow", false,
        function()
            if policeIsProcessing then return end
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then
                policeNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            policeIsProcessing = true
            policeActionsSubMenu.close()
            -- Vérifier côté serveur avant de jouer l'animation
            local canProceed = TriggerServerCallback("police:canToggleBracelet", targetServerId)
            if not canProceed then
                policeIsProcessing = false
                return
            end
            -- Animation accroupi pendant la pose
            local ped = PlayerPedId()
            RequestAnimDict("amb@medic@standing@kneel@base")
            local t = 0
            while not HasAnimDictLoaded("amb@medic@standing@kneel@base") and t < 3000 do Wait(10) t = t + 10 end
            TaskPlayAnim(ped, "amb@medic@standing@kneel@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
            SetTimeout(2500, function()
                ClearPedTasks(ped)
                TriggerServerEvent("police:toggleBracelet", targetServerId)
                policeIsProcessing = false
            end)
        end
    )

    policeActionsSubMenu.Button(
        "Test de poudre",
        "Effectuer un test de résidus de poudre (nécessite un kit)",
        nil, "arrow", false,
        function()
            if policeIsProcessing then return end

            -- Vérifier l'item côté serveur
            local check = TriggerServerCallback("police:gunpowder:checkKit")
            if not check or not check.ok then
                if check and check.reason == "no_item" then
                    policeNotifClient("Test de poudre", "Vous n'avez pas de kit test de poudre")
                end
                return
            end



            local playerId = VFW.StartSelect(5.0, true)
            if not playerId then
                policeNotifClient("Test de poudre", "Aucun citoyen à proximité")
                return
            end

            local targetServerId = GetPlayerServerId(playerId)
            if not targetServerId or targetServerId <= 0 then
                policeNotifClient("Action", "Joueur introuvable")
                return
            end

            policeIsProcessing = true

            ExecuteCommand("me effectue un test de poudre")

            -- Progress bar (5 secondes)
            local success = VFW.Nui.ProgressBar("Analyse de résidus de poudre...", 5000)

            if success then
                TriggerServerEvent("police:gunpowder:test", targetServerId)
            end

            SetTimeout(1000, function() policeIsProcessing = false end)
        end
    )

    policeActionsSubMenu.Button(
        "Emprisonner",
        "Envoyez un citoyen menotté en prison",
        nil, "arrow", false,
        function()
            if policeIsProcessing then return end


            local playerId = VFW.StartSelect(5.0, true)
            if not playerId then
                policeNotifClient("Action", "Aucun citoyen à proximité")
                return
            end
            local targetServerId = GetPlayerServerId(playerId)
            if not targetServerId or targetServerId <= 0 then
                policeNotifClient("Action", "Joueur introuvable")
                return
            end
            local duration = VFW.Nui.KeyboardInput(true, "Durée de la peine (30 ou 60 min, max 60)", "", nil, { numberOnly = true, maxValue = 60 })
            if not duration or duration == "" then return end
            duration = tonumber(duration)
            if not duration or duration <= 0 or duration > 60 then
                policeNotifClient("Prison", "Cette durée n'est pas valide (max 60 minutes)")
                return
            end
            local reason = VFW.Nui.KeyboardInput(true, "Motif de l'emprisonnement", "", nil, { maxLength = 200 })
            if not reason or reason == "" then
                policeNotifClient("Prison", "Vous devez indiquer un motif")
                return
            end
            policeIsProcessing = true
            TriggerServerEvent("police:sendToPrison", targetServerId, duration, reason)
            SetTimeout(3000, function() policeIsProcessing = false end)
        end
    )

    policeActionsSubMenu.Button(
        "Vérifier l'identité",
        "Scanner les empreintes d'un citoyen menotté",
        nil, "arrow", false,
        function()
            if policeIsProcessing then return end

            local hasScanner = false
            if VFW.PlayerData and VFW.PlayerData.inventory then
                for _, item in ipairs(VFW.PlayerData.inventory) do
                    if item.name == "fingerprint_scanner" and item.count > 0 then
                        hasScanner = true
                        break
                    end
                end
            end

            if not hasScanner then
                policeNotifClient("Identité", "Vous n'avez pas de lecteur d'empreinte")
                return
            end


            Wait(200)
            local playerId = VFW.StartSelect(5.0, true)
            if not playerId then
                policeNotifClient("Identité", "Aucun citoyen à proximité")
                return
            end

            local serverId = GetPlayerServerId(playerId)
            if not serverId or serverId <= 0 then
                policeNotifClient("Identité", "Joueur introuvable")
                return
            end
            local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", serverId)
            if not isCuffed then
                policeNotifClient("Identité", "La personne doit être menottée")
                return
            end
            SendNUIMessage({
                action = "nui:fingerprintScanner:show",
                data = { targetServerId = serverId }
            })
            VFW.Nui.Focus(true, false)
        end
    )

end)

-- ============================================================
-- POLICE: Sous-menu Outils
-- ============================================================
policeToolsSubMenu.OnOpen(function()
    policeToolsSubMenu.ClearItems()

    local jobName = VFW.PlayerData.job.name

    policeToolsSubMenu.Button(
        "K9",
        "Gérer le chien K9",
        nil, "arrow", false,
        function() end,
        policeK9SubMenu
    )

    policeToolsSubMenu.Button(
        "Zones de circulation",
        "Gérer les zones de limitation de vitesse",
        nil, "arrow", false,
        function()
            policeToolsSubMenu.close()
            OpenCerculationenu()
        end
    )

    policeToolsSubMenu.Button(
        "Dispatch",
        "Raccourci configurable (L par défaut)",
        nil, "arrow", false,
        function()
            -- Don't close the VUI menu — dispatch floats alongside it
            _G._dispatchOpenedFromF4 = true
            ExecuteCommand("openDispatchPanel")
        end
    )

    policeToolsSubMenu.Button(
        "Objets",
        "Poser des objets de terrain (cônes, barrières...)",
        nil, "arrow", false,
        function()
            policeToolsSubMenu.close()
            ExecuteCommand("openJobPropsMenu")
        end
    )

end)

-- ============================================================
-- POLICE: Sous-menu K9
-- ============================================================
policeK9SubMenu.OnOpen(function()
    policeK9SubMenu.ClearItems()
    BuildK9Items(policeK9SubMenu)
end)

-- ============================================================
-- POLICE: Sous-menu Actions Véhicules
-- ============================================================
policeVehicleSubMenu.OnOpen(function()
    policeVehicleSubMenu.ClearItems()

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        policeVehicleSubMenu.Button(
            "Radar",
            "Activer/désactiver le radar de vitesse (en véhicule)",
            nil, "arrow", false,
            function()
                ToggleRadarAction()
                policeVehicleSubMenu.close()
            end
        )
    end

    policeVehicleSubMenu.Button(
        "Recherche de plaque",
        "Rechercher le propriétaire",
        nil, "arrow", false,
        function()
            policeVehicleSubMenu.close()
            CreateThread(function()
                VehiclePlateSearchAction()
            end)
        end
    )

    policeVehicleSubMenu.Button(
        "Fourrière",
        "Mettre en fourrière le véhicule proche",
        nil, "arrow", false,
        function()
            CreateThread(function()
                VehicleImpoundAction()
            end)
        end
    )

    policeVehicleSubMenu.Button(
        "Sabot",
        "Poser ou retirer un sabot sur le véhicule proche",
        nil, "arrow", false,
        function()
            CreateThread(function()
                VehicleBootToggleAction()
            end)
        end
    )

    policeVehicleSubMenu.Button(
        "Crocheter",
        "Crocheter le véhicule proche (non fonctionnel si déjà ouvert)",
        nil, "arrow", false,
        function()
            CreateThread(function()
                VehicleUnlockAction()
            end)
        end
    )
end)

-- ============================================================
-- USSS: Actions Citoyen (sans bracelet, test poudre, emprisonner)
-- ============================================================
usssActionsSubMenu.OnOpen(function()
    usssActionsSubMenu.ClearItems()

    usssActionsSubMenu.Button(
        "Menotter / Démenotter", "Menottez ou démenottez un citoyen proche",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then policeNotifClient("Action", "Aucun citoyen à proximité") return end
            TriggerServerEvent("police:toggleHandcuff", targetServerId)
        end
    )

    usssActionsSubMenu.Button(
        "Escorter", "Escortez ou relâchez un citoyen menotté",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then policeNotifClient("Action", "Aucun citoyen à proximité") return end
            TriggerServerEvent("police:escort", targetServerId)
        end
    )

    usssActionsSubMenu.Button(
        "Mettre / Sortir du véhicule", "Placez ou sortez un citoyen menotté d'un véhicule",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then policeNotifClient("Action", "Aucun citoyen à proximité") return end
            local targetPlayerId = GetPlayerFromServerId(targetServerId)
            local targetPed = targetPlayerId and GetPlayerPed(targetPlayerId)
            if targetPed and DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                TriggerServerEvent("police:removeFromVehicle", targetServerId)
            else
                local vehicle = getPoliceClosestVehicle(10.0)
                if not vehicle then policeNotifClient("Véhicule", "Aucun véhicule à proximité") return end
                if NetworkGetEntityIsNetworked(vehicle) then
                    TriggerServerEvent("police:putInVehicle", targetServerId, NetworkGetNetworkIdFromEntity(vehicle))
                end
            end
        end
    )

    usssActionsSubMenu.Button(
        "Fouiller", "Fouillez l'inventaire d'un citoyen",
        nil, "arrow", false,
        function()
            local targetServerId = getPoliceClosestPlayerServerId(2.0)
            if not targetServerId then policeNotifClient("Action", "Aucun citoyen à proximité") return end
            TriggerServerEvent("police:search", targetServerId)
        end
    )

    usssActionsSubMenu.Button(
        "Vérifier l'identité", "Scanner les empreintes d'un citoyen menotté",
        nil, "arrow", false,
        function()
            local hasScanner = false
            if VFW.PlayerData and VFW.PlayerData.inventory then
                for _, item in ipairs(VFW.PlayerData.inventory) do
                    if item.name == "fingerprint_scanner" and item.count > 0 then hasScanner = true break end
                end
            end
            if not hasScanner then policeNotifClient("Identité", "Vous n'avez pas de lecteur d'empreintes") return end

            local playerId = VFW.StartSelect(5.0, true)
            if not playerId then
                policeNotifClient("Identité", "Aucun citoyen à proximité")
                return
            end
            local targetServerId = GetPlayerServerId(playerId)
            if not targetServerId or targetServerId <= 0 then return end
            local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", targetServerId)
            if not isCuffed then policeNotifClient("Identité", "La personne doit être menottée") return end
            SendNUIMessage({ action = "nui:fingerprintScanner:show", data = { targetServerId = targetServerId } })
            VFW.Nui.Focus(true, false)
        end
    )
end)

-- ============================================================
-- USSS: Actions Véhicules (sans sabot)
-- ============================================================
usssVehicleSubMenu.OnOpen(function()
    usssVehicleSubMenu.ClearItems()

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        usssVehicleSubMenu.Button(
            "Radar", "Activer/désactiver le radar de vitesse (en véhicule)",
            nil, "arrow", false,
            function() ToggleRadarAction() usssVehicleSubMenu.close() end
        )
    end

    usssVehicleSubMenu.Button(
        "Fourrière", "Mettre en fourrière le véhicule proche",
        nil, "arrow", false,
        function()
            CreateThread(function() VehicleImpoundAction() end)
        end
    )

    usssVehicleSubMenu.Button(
        "Crocheter", "Crocheter le véhicule proche",
        nil, "arrow", false,
        function()
            CreateThread(function() VehicleUnlockAction() end)
        end
    )
end)

-- ============================================================
-- USSS: Outils (sans dispatch)
-- ============================================================
usssToolsSubMenu.OnOpen(function()
    usssToolsSubMenu.ClearItems()

    usssToolsSubMenu.Button(
        "K9", "Gérer le chien K9",
        nil, "arrow", false,
        function() end,
        usssK9SubMenu
    )

    usssToolsSubMenu.Button(
        "Zones de circulation", "Gérer les zones de limitation de vitesse",
        nil, "arrow", false,
        function() usssToolsSubMenu.close() OpenCerculationenu() end
    )

    usssToolsSubMenu.Button(
        "Objets", "Poser des objets de terrain (cônes, barrières...)",
        nil, "arrow", false,
        function() usssToolsSubMenu.close() ExecuteCommand("openJobPropsMenu") end
    )
end)

-- ============================================================
-- USSS: Sous-menu K9
-- ============================================================
usssK9SubMenu.OnOpen(function()
    usssK9SubMenu.ClearItems()
    BuildK9Items(usssK9SubMenu)
end)

samsActionsSubMenu.OnOpen(function()
    renderSamsActionsMenu()
end)

-- ============================================================
-- SAMS EMS: Rendu sous-menu Backup
-- ============================================================
local function renderSamsBackupMenu()
    local hospital = getSamsHospital()
    local otherHospital = hospital == "pillbox" and "paleto" or "pillbox"
    local otherLabel = hospital == "pillbox" and "Paleto" or "Pillbox"

    samsBackupSubMenu.Button("🌐 Backup Global", "Tous les SAMS", nil, "chevron", false, function()
    end, samsBackupGlobalSubMenu)

    samsBackupSubMenu.Button("🏥 Backup " .. otherLabel, "Renfort depuis " .. otherLabel, nil, "chevron", false, function()
    end, samsBackupOtherSubMenu)
end

samsBackupSubMenu.OnOpen(function()
    renderSamsBackupMenu()
end)

-- Backup Global: Niveaux 1, 2, 3
samsBackupGlobalSubMenu.OnOpen(function()
    local hospital = getSamsHospital()
    local street = getSamsStreet()

    samsBackupGlobalSubMenu.Button("BackUp niveau 1", "Routine", nil, "chevron", false, function()
        TriggerServerEvent("sn_sams:requestBackup", 1, hospital, street)
        samsBackupGlobalSubMenu.close()
    end)

    samsBackupGlobalSubMenu.Button("BackUp niveau 2", "Prioritaire", nil, "chevron", false, function()
        TriggerServerEvent("sn_sams:requestBackup", 2, hospital, street)
        samsBackupGlobalSubMenu.close()
    end)

    samsBackupGlobalSubMenu.Button("BackUp niveau 3", "Critique", nil, "chevron", false, function()
        TriggerServerEvent("sn_sams:requestBackup", 3, hospital, street)
        samsBackupGlobalSubMenu.close()
    end)
end)

-- Backup Autre hôpital: Niveaux 1, 2, 3
samsBackupOtherSubMenu.OnOpen(function()
    local hospital = getSamsHospital()
    local street = getSamsStreet()
    local otherHospital = hospital == "pillbox" and "paleto" or "pillbox"

    samsBackupOtherSubMenu.Button("BackUp niveau 1", "Routine", nil, "chevron", false, function()
        TriggerServerEvent("sn_sams:requestBackup", 1, hospital, street, otherHospital)
        samsBackupOtherSubMenu.close()
    end)

    samsBackupOtherSubMenu.Button("BackUp niveau 2", "Prioritaire", nil, "chevron", false, function()
        TriggerServerEvent("sn_sams:requestBackup", 2, hospital, street, otherHospital)
        samsBackupOtherSubMenu.close()
    end)

    samsBackupOtherSubMenu.Button("BackUp niveau 3", "Critique", nil, "chevron", false, function()
        TriggerServerEvent("sn_sams:requestBackup", 3, hospital, street, otherHospital)
        samsBackupOtherSubMenu.close()
    end)
end)

-- (Duplicate gouvernement submenu removed — handled in the block above at line ~621)

local function renderJobMenu()
    local jobName = VFW.PlayerData.job.name

    main.Checkbox("Prise de service", "", false, Society.data.service or false, function(checked)
        Society.data.service = checked
        VFW.ChangeDuty(checked)
        main.refresh()
    end)

    if VFW.PlayerData.job.onDuty then
        main.Title("Métier : " .. VFW.PlayerData.job.label)
        main.Title("Grade : " .. VFW.PlayerData.job.grade_label)

        -- Check if player has announce permission
        local hasAnnouncePermission = TriggerServerCallback("core:jobs:hasPermission", jobName, "announce")

        if hasAnnouncePermission then
            main.Button("Annonces", "", nil, "chevron", false, function()
            end, announceSubMenu)
        end

        -- Invoices Button (EMS jobs open MDT instead)
        if jobName == "sams_pib" or jobName == "sams_pab" then
            main.Button("Faire une Facture", "Ouvre le MDT Médical", nil, "chevron", false, function()
                main.close()
                SN_SAMS.OpenMDT()
                SetTimeout(300, function()
                    SendNUIMessage({ action = "nui:sams:openInvoice", data = {} })
                end)
            end)
        elseif jobName == "gouvernement" then
            local hasInvoicePerm = TriggerServerCallback("gouvernement:checkPerm", "create_invoice")
            local hasInvoiceCompanyPerm = TriggerServerCallback("gouvernement:checkPerm", "create_invoice_company")

            if hasInvoicePerm or hasInvoiceCompanyPerm then
                main.Button("Faire une Facture", "Facturer un citoyen ou une entreprise", nil, "chevron", false, function()
                end, gouvInvoiceSubMenu)
            end
        else
            local POLICE_JOBS_INVOICE = PoliceJobsList
            local invoiceLabel = POLICE_JOBS_INVOICE[jobName] and "Factures et amendes" or "Faire une Facture"
            main.Button(invoiceLabel, "", nil, "chevron", false, function()
            end, invoiceSubMenu)
        end

        -- Business card
        main.Button("Montrer ma carte entreprise", VFW.PlayerData.job.label .. " - " .. VFW.PlayerData.job.grade_label, nil, "chevron", false, function()
            main.close()
            TriggerEvent("menuf5:showDocumentToPlayer", "job")
        end)

        -- Farm locations button (only for farm jobs)
        if FarmConfigs[jobName] then
            main.Button("Points d'intérêt", "Récolte, Traitement, Vente...", nil, "chevron", false, function()
            end, farmLocationsSubMenu)
        end

        -- Build job-specific menu items from registry
        buildJobSpecificMenu(jobName)

        -- Weazel News specific buttons
        if VFW.PlayerData.job.name == "weazelnews" then
            main.Separator("Weazel News")

            main.Button("Outils Journaliste", "Caméra, micro, perche", nil, "chevron", false, function()
            end, journalistToolsSubMenu)

            main.Button("Ouvrir la gestion du journal", "Régie Weazel News", nil, "chevron", false, function()
                OpenWeazelNewsPanel()
                main.close()
            end)
        end

        -- LifeInvader specific buttons
        if VFW.PlayerData.job.name == "lifeinvader" then
            main.Separator("LifeInvader")

            main.Button("Outils Journaliste", "Caméra, micro, perche", nil, "chevron", false, function()
            end, journalistToolsSubMenu)

            main.Button("Ouvrir la gestion du journal", "Régie LifeInvader", nil, "chevron", false, function()
                OpenlifeinvaderPanel()
                main.close()
            end)
        end

        -- SAMS MDT
        if VFW.PlayerData.job.name == "sams_pib" or VFW.PlayerData.job.name == "sams_pab" then
            main.Button(MENTA_SERVER == "FR" and "Actions Secours" or "Actions EMS", "Soigner, inspecter, réanimer, backup", nil, "chevron", false, function()
            end, samsActionsSubMenu)

            main.Button("Ouvrir le MDT", "Gestion des alertes, rapports et dossiers", nil, "chevron", false, function()
                main.close()
                SN_SAMS.OpenMDT()
            end)
        end

        -- Gouvernement specific buttons
        if VFW.PlayerData.job.name == "gouvernement" or VFW.PlayerData.job.name == "gouvernement_cayo" then
            local hasSecurityPerm = TriggerServerCallback("gouvernement:checkPerm", "security_actions")
            local hasTabletPerm = TriggerServerCallback("gouvernement:checkPerm", "gouvernement_tablet")

            if hasSecurityPerm or hasTabletPerm then
                main.Separator("Gouvernement")
            end

            if hasSecurityPerm then
                main.Button("Actions de sécurité", "Menottes, escorte, fouille", nil, "chevron", false, function()
                end, gouvActionsSubMenu)
            end

            if hasTabletPerm then
                main.Button("Tablette Gouvernement", "Gestion Gouvernemental", nil, "chevron", false, function()
                    OpenGouvernementPanel()
                    main.close()
                end)
            end
        end

        -- DOJ (Department of Justice) specific buttons
        if VFW.PlayerData.job.name == "doj" then
            main.Separator("Justice")

            main.Button("Ouvrir le MDT", "Dossiers, mandats judiciaires", nil, "chevron", false, function()
                OpenDOJPanel()
                main.close()
            end)
        end

        -- Police specific buttons (all police jobs)
        if IsPoliceJob(VFW.PlayerData.job.name) then
            main.Separator("Police")

            local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)

            if inVehicle then
                main.Button("Actions Véhicules", "Radar, info, plaque, fourrière", nil, "chevron", false, function()
                end, policeVehicleSubMenu)

                main.Button("Actions Citoyen", "Menottes, escorte, fouille", nil, "chevron", false, function()
                end, policeActionsSubMenu)
            else
                main.Button("Actions Citoyen", "Menottes, escorte, fouille", nil, "chevron", false, function()
                end, policeActionsSubMenu)

                main.Button("Actions Véhicules", "Plaque, fourrière, sabot", nil, "chevron", false, function()
                end, policeVehicleSubMenu)
            end

            main.Button("Outils", "Bouclier, dispatch, objets, caméras", nil, "chevron", false, function()
            end, policeToolsSubMenu)

            main.Button("Ouvrir le MDT", "Terminal de données police", nil, "chevron", false, function()
                OpenPolicePanel()
                main.close()
            end)
        end

        -- Milice specific buttons (MDT only, actions are job-specific)
        if VFW.PlayerData.job.name == "cayomilice" then
            main.Separator("Milice Cayo")

            main.Button("Ouvrir le MDT", "Terminal de la Milice de Cayo", nil, "chevron", false, function()
                OpenPolicePanel()
                main.close()
            end)
        end

        -- USSS specific buttons
        if VFW.PlayerData.job.name and string.lower(VFW.PlayerData.job.name):find("usss") then
            main.Separator("USSS")

            local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)

            if inVehicle then
                main.Button("Actions Véhicules", "Radar, info, plaque, fourrière", nil, "chevron", false, function()
                end, usssVehicleSubMenu)

                main.Button("Actions Citoyen", "Menottes, escorte, fouille", nil, "chevron", false, function()
                end, usssActionsSubMenu)
            else
                main.Button("Actions Citoyen", "Menottes, escorte, fouille", nil, "chevron", false, function()
                end, usssActionsSubMenu)

                main.Button("Actions Véhicules", "Plaque, fourrière", nil, "chevron", false, function()
                end, usssVehicleSubMenu)
            end

            main.Button("Outils", "K9, zones circulation, objets", nil, "chevron", false, function()
            end, usssToolsSubMenu)

            main.Button("Ouvrir le MDT", "Terminal de données USSS", nil, "chevron", false, function()
                OpenUSSSPanel()
                main.close()
            end)
        end

        -- Boss panel at the end
        main.Button("Accès à la tablette", "", nil, "chevron", false, function()
            VFW.BossPanel.openBossPanel()
            main.close()
        end) 
    end
end

journalistToolsSubMenu.OnOpen(function()
    local jobName = VFW.PlayerData.job.name

    if jobName == "weazelnews" then
        journalistToolsSubMenu.Button("Sortir la caméra", "Caméra épaule avec zoom", nil, "chevron", false, function()
            ToggleCamWeazel()
            journalistToolsSubMenu.close()
        end)

        journalistToolsSubMenu.Button("Sortir le micro", "Micro de reporter", nil, "chevron", false, function()
            ToggleMicrophoneWeazel()
            journalistToolsSubMenu.close()
        end)

        journalistToolsSubMenu.Button("Sortir la perche", "Perche de prise de son", nil, "chevron", false, function()
            ToggleBigMicroWeazel()
            journalistToolsSubMenu.close()
        end)
    elseif jobName == "lifeinvader" then
        journalistToolsSubMenu.Button("Sortir la caméra", "Caméra épaule avec zoom", nil, "chevron", false, function()
            ToggleCamLifeInvader()
            journalistToolsSubMenu.close()
        end)

        journalistToolsSubMenu.Button("Sortir le micro", "Micro de reporter", nil, "chevron", false, function()
            ToggleMicrophoneLifeInvader()
            journalistToolsSubMenu.close()
        end)

        journalistToolsSubMenu.Button("Sortir la perche", "Perche de prise de son", nil, "chevron", false, function()
            ToggleBigMicroLifeInvader()
            journalistToolsSubMenu.close()
        end)
    end
end)

main.OnOpen(function()
    if VFW and VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name then
        -- Utiliser la bannière custom de la société si elle existe
        local bannerToUse = defaultBanner
        if Society.data and Society.data.banner and Society.data.banner ~= "" then
            bannerToUse = Society.data.banner
        end
        main.ChangeBanner(bannerToUse)
        -- Sous-menus statiques
        for _, subMenu in ipairs(allSubMenus) do
            if subMenu and subMenu.ChangeBanner then
                subMenu.ChangeBanner(bannerToUse)
            end
        end
        -- Sous-menus dynamiques (créés via JobMenuRegistry)
        local jobName = VFW.PlayerData.job.name
        for _, sm in pairs(JobMenuRegistry.getSubMenus(jobName)) do
            if sm and sm.ChangeBanner then
                sm.ChangeBanner(bannerToUse)
            end
        end
        local societyType = Society.data and Society.data.type or nil
        if societyType and JobMenuRegistry.typeSubMenus[societyType] then
            for _, sm in pairs(JobMenuRegistry.typeSubMenus[societyType]) do
                if sm and sm.ChangeBanner then
                    sm.ChangeBanner(bannerToUse)
                end
            end
        end
        renderJobMenu()
    end
end)

-- Auto-refresh menu when player enters/exits a vehicle or changes vehicle
CreateThread(function()
    local lastInVehicle = false
    local lastVehicleModel = 0
    local alwaysShowTypes = { separator = true, textbox = true, imagebox = true, title = true }

    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local inVeh = veh ~= 0
        local vehModel = inVeh and GetEntityModel(veh) or 0

        if main.opened and (inVeh ~= lastInVehicle or vehModel ~= lastVehicleModel) then
            -- Seamless refresh: rebuild items and send vui:menu directly (no close/open cycle)
            local savedIndex = main.index
            main.ClearItems()

            local ok, err = pcall(main._openFn)
            if ok and main.opened then
                local _items = {}
                main.visibleItems = {}
                for _, item in ipairs(main.items) do
                    if not item.props.disabled or alwaysShowTypes[item.type] then
                        _items[#_items + 1] = { type = item.type, props = item.props }
                        main.visibleItems[#main.visibleItems + 1] = item
                    end
                end

                main.index = math.min(savedIndex, math.max(1, #_items))

                SendNUIMessage({
                    action = "vui:menu",
                    data = {
                        title = main.title,
                        banner = main.banner,
                        index = main.index - 1,
                        helpButtons = main._helpButtons,
                        items = _items
                    }
                })
            elseif not ok then
                print(("[JobMenu] Auto-refresh error: %s"):format(tostring(err)))
            end
        end

        lastInVehicle = inVeh
        lastVehicleModel = vehModel
        Wait(main.opened and 300 or 1000)
    end
end)

RegisterKeyMapping("+OpenJobMenu", "Ouvrir le menu métier", "keyboard", "F4")
RegisterCommand("+OpenJobMenu", function()
    if Death.isDead or VFW.PlayerData.dead then
        return
    end

    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le menu métier est désactivé pendant les TIG"
        })
        return
    end

    if VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name ~= "unemployed" then
        main.SetTitle("Menu " .. (VFW.PlayerData.job.label or "Métier"))
        main.open()
    end
end)
