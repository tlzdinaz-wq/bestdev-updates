---@meta _
---@diagnostic disable: duplicate-doc-field

-- Liste des IPL disponibles pour les cambriolages
-- :warning: IMPORTANT: Ne contient QUE les IPL avec coordonnées Z positives et fonctionnels
-- Les IPL avec coordonnées négatives (sous l'eau) ont été retirés
local AvailableIPLs = {
    -- Caravanes/Maisons
    {name = "trevor_trailer", displayName = "Caravane de Trevor", category = "Caravanes", previewPos = {x = 1973.2, y = 3816.0, z = 33.4}},
    {name = "floyd_apartment", displayName = "Appartement de Floyd", category = "Appartements", previewPos = {x = -1150.9, y = -1520.7, z = 10.6}},

    -- Appartements Haut Standing
    {name = "apa_v_mp_h_02_a", displayName = "Appartement Haut Standing A", category = "Appartements", previewPos = {x = -787.1, y = 315.8, z = 217.6}},
    {name = "apa_v_mp_h_02_b", displayName = "Appartement Haut Standing B", category = "Appartements", previewPos = {x = -774.0, y = 342.0, z = 196.6}},

    -- Appartements Moyen Standing
    {name = "apa_v_mp_h_02_c", displayName = "Appartement Moyen Standing A", category = "Appartements", previewPos = {x = -786.8, y = 315.5, z = 187.9}},
    {name = "apa_v_mp_h_01_a", displayName = "Appartement Moyen Standing B", category = "Appartements", previewPos = {x = -785.8, y = 316.0, z = 217.6}},
    {name = "apa_v_mp_h_01_b", displayName = "Appartement Moyen Standing C", category = "Appartements", previewPos = {x = -774.0, y = 342.0, z = 196.6}},
    {name = "apa_v_mp_h_01_c", displayName = "Appartement Moyen Standing D", category = "Appartements", previewPos = {x = -787.1, y = 315.5, z = 187.9}},

    -- Maisons Franklin
    {name = "lf_house_01", displayName = "Maison Franklin 1", category = "Maisons", previewPos = {x = 7.9, y = 538.7, z = 176.0}},
    {name = "lf_house_02", displayName = "Maison Franklin 2", category = "Maisons", previewPos = {x = -14.1, y = -1440.6, z = 31.1}}
}

-- Variable pour stocker l'IPL en cours de prévisualisation
local previewingIPL = ""

-- Variable pour stocker la position avant prévisualisation
local positionBeforePreview = nil

-- Variable pour stocker l'IPL sélectionné
local selectedIPL = ""

-- Variables pour les points de loot en prévisualisation
local previewLootPoints = {}
local showingLootPointMarkers = false
local previewLootBlips = {}

-- Fonction pour créer les blips des points de loot
local function CreatePreviewLootBlips()
    -- Supprimer les anciens blips
    for _, blip in pairs(previewLootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    previewLootBlips = {}

    -- Créer les nouveaux blips
    for i, point in ipairs(previewLootPoints) do
        if point and point.pos then
            local blip = AddBlipForCoord(point.pos.x, point.pos.y, point.pos.z)
            SetBlipSprite(blip, 618) -- Icône de coffre/loot
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 5) -- Jaune
            SetBlipAsShortRange(blip, false) -- Toujours visible
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(("Point de loot #%d"):format(i))
            EndTextCommandSetBlipName(blip)
            previewLootBlips[i] = blip
        end
    end
end

-- Fonction pour supprimer les blips de prévisualisation
local function RemovePreviewLootBlips()
    for _, blip in pairs(previewLootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    previewLootBlips = {}
end

-- Thread pour afficher les markers des points de loot pendant la prévisualisation
CreateThread(function()
    while true do
        local wait = 1000

        if showingLootPointMarkers and #previewLootPoints > 0 then
            wait = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            for i, point in ipairs(previewLootPoints) do
                if point and point.pos then
                    local pointPos = vector3(point.pos.x, point.pos.y, point.pos.z)
                    local dist = #(playerCoords - pointPos)

                    -- Afficher le marker cylindre jaune
                    DrawMarker(1,
                        point.pos.x, point.pos.y, point.pos.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.8, 0.8, 0.15,
                        255, 255, 0, 150,
                        false, true, 2, false, nil, nil, false
                    )

                    -- Afficher le texte 3D si proche
                    if dist < 15.0 then
                        local onScreen, _x, _y = World3dToScreen2d(point.pos.x, point.pos.y, point.pos.z + 0.5)
                        if onScreen then
                            SetTextScale(0.35, 0.35)
                            SetTextFont(4)
                            SetTextProportional(1)
                            SetTextColour(255, 255, 0, 255)
                            SetTextEntry("STRING")
                            SetTextCentre(true)
                            AddTextComponentString(("Point #%d"):format(i))
                            DrawText(_x, _y)
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

-- Les positions seront récupérées depuis cl_ipl.lua
local IPLTeleportPositions = {}

-- Récupérer les données IPL depuis cl_ipl.lua
local function GetIPLData(iplName)
    local iplManager = exports[GetCurrentResourceName()]:GetIPLManager()
    if iplManager then
        return iplManager.GetIPLData(iplName)
    end
    return nil
end

-- Récupérer les positions depuis la base de données (spawn positions des intérieurs)
local function GetIPLPositionFromDB(iplName)
    -- Chercher dans les intérieurs existants
    for _, interior in pairs(burglaryInteriors) do
        if interior.iplName == iplName and interior.spawnPos then
            return {
                x = interior.spawnPos.x,
                y = interior.spawnPos.y,
                z = interior.spawnPos.z
            }
        end
    end
    return nil
end

-- Trouver un IPL par son nom technique
local function GetIPLByName(iplName)
    for _, ipl in ipairs(AvailableIPLs) do
        if ipl.name == iplName then
            return ipl
        end
    end
    return nil
end

-- Fonction de téléportation vers l'IPL
local function TeleportToIPL(iplName)
    if iplName == "" then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
            message = "Aucun IPL sélectionné."
      })
        return
    end

    -- Charger l'IPL d'abord
    TriggerEvent("core:burglary:loadIPL", iplName)
    Wait(1000) -- Attendre que l'IPL se charge

    -- D'abord essayer la position de preview de l'IPL
    local ipl = GetIPLByName(iplName)
    local position = ipl and ipl.previewPos or nil

    -- Sinon essayer de récupérer la position depuis la base de données
    if not position then
        position = GetIPLPositionFromDB(iplName)
    end

    -- Si pas trouvé, utiliser les positions sauvegardées localement
    if not position then
        position = IPLTeleportPositions[iplName]
    end

    if not position then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Position inconnue pour cet IPL. Utilisez le mode exploration pour la définir."
      })
        return
    end

    -- Téléporter le joueur
    SetEntityCoords(PlayerPedId(), position.x, position.y, position.z, false, false, false, true)

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
        message = "Téléporté à l'IPL: " .. iplName .. "."
  })
end

-- Fonction de prévisualisation d'un IPL (charge, téléporte, mais ne sélectionne pas)
local function PreviewIPL(ipl)
    if not ipl or ipl.name == "" or ipl.name == "_default_" or not ipl.previewPos then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Cet intérieur n'a pas de prévisualisation disponible."
      })
        return
    end

    -- Si on prévisualise le même IPL, juste téléporter
    if previewingIPL == ipl.name then
        SetEntityCoords(PlayerPedId(), ipl.previewPos.x, ipl.previewPos.y, ipl.previewPos.z, false, false, false, true)
        return
    end

    -- Nettoyer les anciens loot points et blips avant le changement
    previewLootPoints = {}
    showingLootPointMarkers = false
    RemovePreviewLootBlips()

    -- Sauvegarder la position actuelle avant de prévisualiser (seulement si pas déjà en preview)
    if not positionBeforePreview then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        positionBeforePreview = {x = coords.x, y = coords.y, z = coords.z, h = heading}
    end

    -- Décharger l'IPL précédent si différent (sauf pour les intérieurs intégrés)
    if previewingIPL ~= "" and previewingIPL ~= "_default_" and not string.find(previewingIPL, "^_") then
        TriggerEvent("core:burglary:unloadIPL", previewingIPL)
        Wait(500) -- Attendre que l'IPL se décharge
    end

    -- Charger le nouvel IPL (sauf pour les intérieurs intégrés au jeu comme _lowend_apt)
    if not string.find(ipl.name, "^_") then
        TriggerEvent("core:burglary:loadIPL", ipl.name)
        Wait(1000) -- Attendre que l'IPL se charge
    end

    previewingIPL = ipl.name

    -- Téléporter à la position de preview
    SetEntityCoords(PlayerPedId(), ipl.previewPos.x, ipl.previewPos.y, ipl.previewPos.z, false, false, false, true)

    -- Récupérer et afficher les points de loot
    previewLootPoints = TriggerServerCallback("core:burglary:getLootPointsByIPL", ipl.name) or {}
    showingLootPointMarkers = #previewLootPoints > 0

    -- Créer les blips sur la map
    CreatePreviewLootBlips()

    local lootCount = #previewLootPoints
    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'INFO',
        subtitle = 'Builder',
        message = ("Prévisualisation: %s (%d points de loot)."):format(ipl.displayName, lootCount)
    })
end

-- Fonction pour arrêter la prévisualisation
local function StopPreview()
    -- Décharger l'IPL seulement si ce n'est pas un intérieur intégré (commençant par _)
    if previewingIPL ~= "" and not string.find(previewingIPL, "^_") then
        TriggerEvent("core:burglary:unloadIPL", previewingIPL)
    end
    previewingIPL = ""

  -- Nettoyer les points de loot et les blips
    previewLootPoints = {}
    showingLootPointMarkers = false
    RemovePreviewLootBlips()

    -- Téléporter le joueur à sa position d'origine
    if positionBeforePreview then
        local playerPed = PlayerPedId()
        SetEntityCoords(playerPed, positionBeforePreview.x, positionBeforePreview.y, positionBeforePreview.z, false, false, false, true)
        SetEntityHeading(playerPed, positionBeforePreview.h)
        positionBeforePreview = nil
    end
end

-- Zone Safe Builder Menu
function StaffMenu.BuildZoneSafeMenu()

    StaffMenu.builderZoneSafe.Button(":plus: CRÉER UNE ZONE SAFE", nil, nil, "chevron", false, function()
    end, StaffMenu.CreateZoneSafe)

    StaffMenu.builderZoneSafe.Button(":report: LISTE DES ZONES SAFE", nil, nil, "chevron", false, function()
    end, StaffMenu.ListZoneSafe)

    StaffMenu.builderZoneSafe.Button(":map: CARTE ZONES SAFE", "Voir les zones safe sur la carte interactive", nil, "chevron", false, function()
        exports['VUI']:CloseAll()
        SetTimeout(200, function()
            exports['core']:OpenSafeZoneTablet()
        end)
        return false
    end)
end

function StaffMenu.BuildChestMenu()
    StaffMenu.builderChest.Button(":plus: CRÉER UN COFFRE", nil, nil, "chevron", false, function()
        if resetChestData then resetChestData() end
    end, StaffMenu.CreateChest)

    StaffMenu.builderChest.Button(":report: LISTE DES COFFRES", nil, nil, "chevron", false, function()
    end, StaffMenu.ChestList)
end

local oxDoorlockData = {
    selectedDoor = nil,
    vfw_access = {}, -- Format: { {name = "police", grade = 2, type = "job"}, {name = "ballas", grade = 0, type = "faction"} }
    characters = {} -- Format: { 6, 12, 45 } (UUIDs / playerGlobal.id)
}

AddEventHandler('ox_doorlock:editorClosed', function()
    Wait(100)
    StaffMenu.builderDoorlock.open()
end)

function StaffMenu.BuildDoorlockMenu()
    StaffMenu.builderDoorlock.Button(":unlock: OUVRIR L'INTERFACE OX_DOORLOCK", "Créer / Modifier / Supprimer", nil, "arrow", false, function()
        StaffMenu.builderDoorlock.close()
        TriggerServerEvent('ox_doorlock:openEditor')
    end)

    StaffMenu.builderDoorlock.Button(":door: GÉRER LA PORTE LA PLUS PROCHE", "Ouvre l'éditeur pour cette porte", nil, "arrow", false, function()
        StaffMenu.builderDoorlock.close()
        TriggerServerEvent('ox_doorlock:openEditor', true)
    end)

    StaffMenu.builderDoorlock.Button(":report: GÉRER LES ACCÈS DES PORTES", "Jobs et factions", nil, "chevron", false, function()
    end, StaffMenu.OxDoorlockList)

    StaffMenu.builderDoorlock.Separator("RACCOURCIS")

    StaffMenu.builderDoorlock.Button(":lock: VERROUILLER / DÉVERROUILLER", "Toggle la porte proche", nil, "chevron", false, function()
        exports.ox_doorlock:useClosestDoor()
    end)
end

local OX_DOORLOCKS_PER_PAGE = 25
StaffMenu.oxDoorlockListPage = StaffMenu.oxDoorlockListPage or 1
StaffMenu.oxDoorlockListSearch = StaffMenu.oxDoorlockListSearch or nil

function StaffMenu.BuildOxDoorlockListMenu()
    local doors = lib.callback.await('ox_doorlock:getAllDoorsForBuilder', false)

    local searchLabel = StaffMenu.oxDoorlockListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.oxDoorlockListSearch == nil and "Nom de la porte" or StaffMenu.oxDoorlockListSearch
    StaffMenu.OxDoorlockList.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.oxDoorlockListSearch ~= nil then
            StaffMenu.oxDoorlockListSearch = nil
            StaffMenu.oxDoorlockListPage = 1
            StaffMenu.OxDoorlockList.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom de la porte")
        if query == nil or query == "" then return end
        StaffMenu.oxDoorlockListSearch = query
        StaffMenu.oxDoorlockListPage = 1
        StaffMenu.OxDoorlockList.refresh()
    end)

    if not doors or #doors == 0 then
        StaffMenu.OxDoorlockList.Button("AUCUNE PORTE", nil, nil, nil, true, function() end)
        return
    end

    table.sort(doors, function(a, b)
        return ((a.name or "") .. ""):lower() < ((b.name or "") .. ""):lower()
    end)

    local filtered = doors
    if StaffMenu.oxDoorlockListSearch and StaffMenu.oxDoorlockListSearch ~= "" then
        local q = StaffMenu.oxDoorlockListSearch:lower()
        filtered = {}
        for _, d in ipairs(doors) do
            if (d.name or ""):lower():find(q, 1, true)
                or tostring(d.id or ""):lower():find(q, 1, true) then
                table.insert(filtered, d)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / OX_DOORLOCKS_PER_PAGE), 1)
    if StaffMenu.oxDoorlockListPage > totalPages then StaffMenu.oxDoorlockListPage = totalPages end
    if StaffMenu.oxDoorlockListPage < 1 then StaffMenu.oxDoorlockListPage = 1 end
    local startIdx = (StaffMenu.oxDoorlockListPage - 1) * OX_DOORLOCKS_PER_PAGE + 1
    local endIdx = math.min(startIdx + OX_DOORLOCKS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.oxDoorlockListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format(":door: %d PORTES, page %d sur %d", totalItems, StaffMenu.oxDoorlockListPage, totalPages)
    end
    StaffMenu.OxDoorlockList.Separator(header)

    if totalItems == 0 then
        StaffMenu.OxDoorlockList.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local door = filtered[idx]
        local accessCount = door.vfw_access and #door.vfw_access or 0
        local charactersCount = door.characters and #door.characters or 0
        local subtitleParts = {}
        if accessCount > 0 then subtitleParts[#subtitleParts + 1] = accessCount .. " accès" end
        if charactersCount > 0 then subtitleParts[#subtitleParts + 1] = charactersCount .. " UUID" end
        local subtitle = #subtitleParts > 0 and table.concat(subtitleParts, " | ") or "Public"
      local stateIcon = door.state == 1 and ":lock:" or ":unlock:"

      StaffMenu.OxDoorlockList.Button(
            stateIcon .. " " .. (door.name or ("Porte #" .. door.id)),
            subtitle,
            nil,
            "chevron",
            false,
            function()
                oxDoorlockData.selectedDoor = door
                oxDoorlockData.vfw_access = door.vfw_access and table.clone(door.vfw_access) or {}
                oxDoorlockData.characters = door.characters and table.clone(door.characters) or {}
            end,
            StaffMenu.OxDoorlockManage
        )
    end

    if totalPages > 1 then
        StaffMenu.OxDoorlockList.Separator(nil)
        if StaffMenu.oxDoorlockListPage > 1 then
            StaffMenu.OxDoorlockList.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.oxDoorlockListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.oxDoorlockListPage = StaffMenu.oxDoorlockListPage - 1
                StaffMenu.OxDoorlockList.refresh()
            end)
        end
        if StaffMenu.oxDoorlockListPage < totalPages then
            StaffMenu.OxDoorlockList.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.oxDoorlockListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.oxDoorlockListPage = StaffMenu.oxDoorlockListPage + 1
                StaffMenu.OxDoorlockList.refresh()
            end)
        end
    end
end

function StaffMenu.BuildOxDoorlockManageMenu()
    if not oxDoorlockData.selectedDoor then
        StaffMenu.OxDoorlockManage.Button("AUCUNE PORTE SÉLECTIONNÉE", nil, nil, nil, true, function() end)
        return
    end

    local door = oxDoorlockData.selectedDoor

    StaffMenu.OxDoorlockManage.Separator("PORTE: " .. (door.name or ("Porte #" .. door.id)))

    StaffMenu.OxDoorlockManage.Button(":target: TÉLÉPORTATION", nil, nil, "chevron", false, function()
        if door.coords then
            SetEntityCoords(PlayerPedId(), door.coords.x, door.coords.y, door.coords.z + 1.0, false, false, false, false)
        end
    end)

    StaffMenu.OxDoorlockManage.Separator("GESTION DES ACCÈS")

    local accessCount = #oxDoorlockData.vfw_access

    StaffMenu.OxDoorlockManage.Button(":plus: AJOUTER UN ACCÈS", accessCount .. (accessCount > 1 and " accès configurés" or " accès configuré"), nil, "chevron", false, function()
    end, StaffMenu.OxDoorlockAccessType)

    if accessCount > 0 then
        StaffMenu.OxDoorlockManage.Separator("ACCÈS ACTUELS")

        for i, access in ipairs(oxDoorlockData.vfw_access) do
            local typeIcon = access.type == "job" and ":briefcase:" or ":skull:"
          local gradeText = access.grade > 0 and ("Grade " .. access.grade .. "+") or "Tous les grades"
          StaffMenu.OxDoorlockManage.Button(
                ":x: " .. typeIcon .. " " .. access.name,
                gradeText,
                nil,
                "chevron",
                false,
                function()
                    table.remove(oxDoorlockData.vfw_access, i)
                    StaffMenu.OxDoorlockManage.refresh()
                end
            )
        end
    end

    StaffMenu.OxDoorlockManage.Separator("ACCÈS PAR UUID (Personnages)")

    local charactersCount = #oxDoorlockData.characters

    StaffMenu.OxDoorlockManage.Button(":plus: AJOUTER UN UUID", charactersCount .. (charactersCount > 1 and " UUID configurés" or " UUID configuré"), nil, "chevron", false, function()
        local uuid = tonumber(VFW.Nui.KeyboardInput(true, "Entrer l'UUID du personnage"))
        if not uuid then
            return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cet UUID n'est pas valide." })
        end
        for _, existingUuid in ipairs(oxDoorlockData.characters) do
            if tonumber(existingUuid) == uuid then
                return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "UUID déjà ajouté." })
            end
        end
        oxDoorlockData.characters[#oxDoorlockData.characters + 1] = uuid
        StaffMenu.OxDoorlockManage.refresh()
    end)

    if charactersCount > 0 then
        for i, uuid in ipairs(oxDoorlockData.characters) do
            StaffMenu.OxDoorlockManage.Button(
                ":x: UUID: " .. tostring(uuid),
                "Cliquer pour supprimer",
                nil,
                "chevron",
                false,
                function()
                    table.remove(oxDoorlockData.characters, i)
                    StaffMenu.OxDoorlockManage.refresh()
                end
            )
        end
    end

    StaffMenu.OxDoorlockManage.Separator()

    StaffMenu.OxDoorlockManage.Button(":check: SAUVEGARDER", nil, nil, "check", false, function()
        TriggerServerEvent('ox_doorlock:updateVfwAccess', door.id, oxDoorlockData.vfw_access)
        TriggerServerEvent('ox_doorlock:updateCharacters', door.id, oxDoorlockData.characters)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Accès mis à jour." })
        StaffMenu.OxDoorlockManage.close()
        Wait(100)
        StaffMenu.OxDoorlockList.open()
    end)
end

function StaffMenu.BuildOxDoorlockAccessTypeMenu()
    StaffMenu.OxDoorlockAccessType.Button(":briefcase: JOB (Légal)", "Choisir un job", nil, "chevron", false, function()
    end, StaffMenu.OxDoorlockAccessJob)

    StaffMenu.OxDoorlockAccessType.Button(":skull: FACTION (Illégal)", "Choisir une faction", nil, "chevron", false, function()
    end, StaffMenu.OxDoorlockAccessFaction)
end

local function isAccessAdded(name, accessType)
    for _, access in ipairs(oxDoorlockData.vfw_access) do
        if access.name == name and access.type == accessType then
            return true
        end
    end
    return false
end

function StaffMenu.BuildOxDoorlockAccessJobMenu()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not next(jobs) then
        StaffMenu.OxDoorlockAccessJob.Button("AUCUN JOB", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isAdded = isAccessAdded(job.name, "job")
        StaffMenu.OxDoorlockAccessJob.Button(
            (isAdded and ":check: " or "") .. (job.label or job.name),
            job.name,
            nil,
            "chevron",
            false,
            function()
                StaffMenu.data.selectedOxDoorlockJob = job
            end,
            StaffMenu.OxDoorlockAccessJobGrades
        )
    end
end

function StaffMenu.BuildOxDoorlockAccessJobGradesMenu()
    local job = StaffMenu.data.selectedOxDoorlockJob
    if not job then return end

    local grades = job.grades or {}

    StaffMenu.OxDoorlockAccessJobGrades.Button(":check: TOUS LES GRADES", "Grade 0+", nil, "check", false, function()
        table.insert(oxDoorlockData.vfw_access, { name = job.name, grade = 0, type = "job" })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Accès ajouté: " .. (job.label or job.name) .. " (tous)." })
        StaffMenu.OxDoorlockAccessJobGrades.close()
        Wait(100)
        StaffMenu.OxDoorlockManage.open()
    end)

    StaffMenu.OxDoorlockAccessJobGrades.Separator("GRADES DISPONIBLES")

    local sortedGrades = {}
    for gradeKey, gradeData in pairs(grades) do
        table.insert(sortedGrades, { key = gradeKey, data = gradeData })
    end
    table.sort(sortedGrades, function(a, b) return (a.data.grade or 0) < (b.data.grade or 0) end)

    for _, gradeInfo in ipairs(sortedGrades) do
        local gradeData = gradeInfo.data
        local gradeNum = gradeData.grade or 0
        local gradeLabel = gradeData.label or ("Grade " .. gradeNum)

        StaffMenu.OxDoorlockAccessJobGrades.Button(
            gradeLabel,
            "Grade " .. gradeNum .. "+",
            nil,
            "chevron",
            false,
            function()
                table.insert(oxDoorlockData.vfw_access, { name = job.name, grade = gradeNum, type = "job" })
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Accès ajouté: " .. (job.label or job.name) .. " (" .. gradeLabel .. "+)." })
                StaffMenu.OxDoorlockAccessJobGrades.close()
                Wait(100)
                StaffMenu.OxDoorlockManage.open()
            end
        )
    end
end

function StaffMenu.BuildOxDoorlockAccessFactionMenu()
    local factions = TriggerServerCallback("core:gestion-factions:getAll") or {}

    if not factions or #factions == 0 then
        StaffMenu.OxDoorlockAccessFaction.Button("AUCUNE FACTION", nil, nil, nil, true, function() end)
        return
    end

    for _, faction in pairs(factions) do
        local isAdded = isAccessAdded(faction.name, "faction")
        StaffMenu.OxDoorlockAccessFaction.Button(
            (isAdded and ":check: " or "") .. (faction.label or faction.name),
            faction.name,
            nil,
            "chevron",
            false,
            function()
                StaffMenu.data.selectedOxDoorlockFaction = faction
                StaffMenu.data.selectedOxDoorlockFactionGrades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}
            end,
            StaffMenu.OxDoorlockAccessFactionGrades
        )
    end
end

function StaffMenu.BuildOxDoorlockAccessFactionGradesMenu()
    local faction = StaffMenu.data.selectedOxDoorlockFaction
    if not faction then return end

    local grades = StaffMenu.data.selectedOxDoorlockFactionGrades or {}

    StaffMenu.OxDoorlockAccessFactionGrades.Button(":check: TOUS LES GRADES", "Grade 0+", nil, "check", false, function()
        table.insert(oxDoorlockData.vfw_access, { name = faction.name, grade = 0, type = "faction" })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Accès ajouté: " .. (faction.label or faction.name) .. " (tous)." })
        StaffMenu.OxDoorlockAccessFactionGrades.close()
        Wait(100)
        StaffMenu.OxDoorlockManage.open()
    end)

    StaffMenu.OxDoorlockAccessFactionGrades.Separator("GRADES DISPONIBLES")

    local sortedGrades = {}
    for _, gradeData in pairs(grades) do
        table.insert(sortedGrades, gradeData)
    end
    table.sort(sortedGrades, function(a, b) return (a.grade or 0) < (b.grade or 0) end)

    for _, gradeData in ipairs(sortedGrades) do
        local gradeNum = gradeData.grade or 0
        local gradeLabel = gradeData.label or ("Grade " .. gradeNum)

        StaffMenu.OxDoorlockAccessFactionGrades.Button(
            gradeLabel,
            "Grade " .. gradeNum .. "+",
            nil,
            "chevron",
            false,
            function()
                table.insert(oxDoorlockData.vfw_access, { name = faction.name, grade = gradeNum, type = "faction" })
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Accès ajouté: " .. (faction.label or faction.name) .. " (" .. gradeLabel .. "+)." })
                StaffMenu.OxDoorlockAccessFactionGrades.close()
                Wait(100)
                StaffMenu.OxDoorlockManage.open()
            end
        )
    end
end

-- DJ Builder Menu
function StaffMenu.BuildDJMenu()
    StaffMenu.builderDJ.Separator("GESTION DES PLATINES DJ")

    StaffMenu.builderDJ.Button(":music: CRÉER UNE PLATINE", "Placer une platine DJ (prop)", nil, "chevron", not VFW.PlayerGlobalData.permissions["builder_platine"], function()
    end, StaffMenu.CreatePlatine)

    StaffMenu.builderDJ.Button(":trash: GÉRER LES PLATINES", "Modifier ou supprimer des platines", nil, "chevron", not VFW.PlayerGlobalData.permissions["builder_platine"], function()
    end, StaffMenu.DeletePlatine)
end

-- Supermarket Builder Menu
function StaffMenu.BuildSupermarketMenu()
    StaffMenu.builderSupermarket.Separator("GESTION DES SUPÉRETTES")

    StaffMenu.builderSupermarket.Button(":plus: CRÉER UNE SUPÉRETTE", "Ajouter une nouvelle supérette", nil, "chevron", false, function()
    end, StaffMenu.CreateSuperMarket)

    StaffMenu.builderSupermarket.Button(":box: LISTE DES SUPÉRETTES", "Gérer les supérettes existantes", nil, "chevron", false, function()
    end, StaffMenu.ListSuperMarket)

    StaffMenu.builderSupermarket.Separator("CONFIGURATION GLOBALE")

    StaffMenu.builderSupermarket.Button(":cart: CATALOGUE DES ITEMS", "Gérer les items vendus dans toutes les LTD", nil, "chevron", false, function()
    end, StaffMenu.SupermarketCatalog)

    StaffMenu.builderSupermarket.Button(":settings: PARAMÈTRES GLOBAUX", "Cooldowns, récompenses, etc.", nil, "chevron", false, function()
    end, StaffMenu.SupermarketSettings)

    StaffMenu.builderSupermarket.Button(":clock: RÉINITIALISER LES COOLDOWNS", "Réinitialise tous les temps d'attente", nil, "arrow", false, function()
        TriggerServerEvent('core:supermarket:resetCooldowns')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Cooldowns réinitialisés."
      })
    end)

    StaffMenu.builderSupermarket.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge les supérettes depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:supermarket:reloadFromDatabase')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Rechargement en cours."
      })
    end)
end

-- Market Builder
local marketSelected = {
    society = nil,
    items = {}
}



local marketNewItem = {
    name = "",
    label = "",
    price = 0,
    category = "",
    type = "item",
    item = ""
}

-- pagination for item chooser (used in add/edit menus)
local SPACE_MARKET_ITEMS_PER_PAGE = 20
local marketItemQuery = nil
local marketCurrentPage = 1

-- helper that renders an item search/list in the provided menu
local function buildMarketItemBrowser(menu, target)
    -- target is a table to populate; if nil we default to marketNewItem
    target = target or marketNewItem

    -- search button
    local firstLabel = marketItemQuery == nil and ":search: RECHERCHER" or ":search: RECHERCHER:"
  local lastLabel = marketItemQuery == nil and "UN ITEM" or marketItemQuery
    menu.Button(firstLabel, lastLabel, nil, "search", false, function()
        if marketItemQuery ~= nil then
            marketItemQuery = nil
            marketCurrentPage = 1
            menu.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label", "")
        if query == nil or query == "" then
            return
        end
        marketItemQuery = query
        marketCurrentPage = 1
        menu.refresh()
    end)

    menu.Separator()

    -- collect and filter items from global registry
    local filtered = {}
    for itemName, item in pairs(VFW.Items) do
        if not marketItemQuery or
           string.find(string.lower(itemName), string.lower(marketItemQuery), 1, true) or
           string.find(string.lower(item.label or ""), string.lower(marketItemQuery), 1, true) then
            table.insert(filtered, { name = itemName, data = item })
        end
    end

    table.sort(filtered, function(a, b)
        return a.data.label < b.data.label
    end)

    local total = #filtered
    local totalPages = math.max(1, math.ceil(total / SPACE_MARKET_ITEMS_PER_PAGE))
    if marketCurrentPage > totalPages then
        marketCurrentPage = totalPages
    end
    if marketCurrentPage < 1 then
        marketCurrentPage = 1
    end

    local startIndex = (marketCurrentPage - 1) * SPACE_MARKET_ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + SPACE_MARKET_ITEMS_PER_PAGE - 1, total)

    if totalPages > 1 then
        menu.Separator("Page " .. marketCurrentPage .. "/" .. totalPages, total .. " items")
        if marketCurrentPage > 1 then
            menu.Button(":back: PAGE PRÉCÉDENTE", nil, nil, nil, false, function()
                marketCurrentPage = marketCurrentPage - 1
                menu.refresh()
            end)
        end
        if marketCurrentPage < totalPages then
            menu.Button("PAGE SUIVANTE :arrow:", nil, nil, nil, false, function()
                marketCurrentPage = marketCurrentPage + 1
                menu.refresh()
            end)
        end
        menu.Separator()
    end

    for i = startIndex, endIndex do
        local entry = filtered[i]
        if entry then
            menu.Button(entry.data.label, entry.name, entry.data.weight and (entry.data.weight .. " kg") or "", "chevron", false, function()
                -- populate target table and exit browser
                target.item = entry.name
                target.name = entry.name
                target.label = entry.data.label or entry.name
                -- default price if available (some items define buyPrice)
                if entry.data.buyPrice then
                    target.price = entry.data.buyPrice
                end
                -- give user feedback and reset search (silenced)

                marketItemQuery = nil
                marketCurrentPage = 1
                menu.refresh()
                -- open configuration submenu so user can set price/category
                if StaffMenu.builderMarketAddItemConfig then
                    StaffMenu.builderMarketAddItemConfig.open()
                end
            end)
        end
    end

    if total == 0 then
        menu.Separator("Aucun item", "trouvé")
    end
end

function StaffMenu.BuildMarketMenu()
    StaffMenu.builderMarket.Separator("GESTION MARKET")

    StaffMenu.builderMarket.Button(":plus: ASSIGNER UN JOB", "Assigner un job existant au Market", nil, "chevron", false, function()
        -- Ouvre la liste des jobs existants pour assigner l'accès au Market
        StaffMenu.builderMarketCreate.open()
    end)

    StaffMenu.builderMarket.Button(":report: LISTE DES JOBS", "Gérer les jobs et leur boutique Market", nil, "chevron", false, function()
    end, StaffMenu.builderMarketList)

    StaffMenu.builderMarket.Button(":settings: CONFIGURATION MARKET", "Activer/désactiver le Market globalement et configurer les délais de livraison", nil, "chevron", false, function()
    end, StaffMenu.builderMarketDelivery)
end

function StaffMenu.BuildMarketListMenu()
    StaffMenu.builderMarketList.Button(":refresh: RAFRAÎCHIR", "Recharger la liste des jobs", nil, "arrow", false, function()
        StaffMenu.builderMarketList.refresh()
    end)

    StaffMenu.builderMarketList.Separator("JOBS MARKET")

    local jobs = TriggerServerCallback('spacemarket:get:jobs') or {}
    if not next(jobs) then
        StaffMenu.builderMarketList.Button("Aucun job configuré", "Utilisez '+ Assigner un job' pour en ajouter", nil, nil, true, function() end)
        return
    end

    local sorted = {}
    for name, info in pairs(jobs) do
        sorted[#sorted + 1] = { name = name, label = info.label or name, enabled = info.enabled }
    end
    table.sort(sorted, function(a, b) return a.label < b.label end)

    for _, entry in ipairs(sorted) do
        local icon = entry.enabled and ":check:" or ":x:"
      local desc = entry.enabled and "Market activé" or "Market désactivé"

      StaffMenu.builderMarketList.Button(icon .. " " .. entry.label, desc, nil, "chevron", false, function()
            local db = TriggerServerCallback('spacemarket:get:job', entry.name) or {}
            local soc = { custom = { spacemarket = {
                enabled = db.enabled or false,
                grades = db.allowed_grades or {},
                categories = db.categories or {},
                items = db.items or {},
            }}}
            soc.name = entry.name
            soc.label = entry.label
            marketSelected.society = soc
        end, StaffMenu.builderMarketEdit)
    end
end

function StaffMenu.BuildMarketCreateMenu()
    StaffMenu.builderMarketCreate.Separator("+ AJOUTER UN JOB")

    local allJobs = TriggerServerCallback('vfw:staff:getJobs') or {}
    local dbJobs = TriggerServerCallback('spacemarket:get:jobs') or {}

    local available = {}
    for name, data in pairs(allJobs) do
        if not dbJobs[name] then
            table.insert(available, { name = name, label = (data.label or name) })
        end
    end

    if #available == 0 then
        StaffMenu.builderMarketCreate.Button("Aucun job disponible", nil, nil, nil, true, function() end)
    else
        for _, j in ipairs(available) do
            StaffMenu.builderMarketCreate.Button((j.label or j.name), nil, nil, "chevron", false, function()
                local createData = { enabled = true, allowed_grades = VFW.Jobs and VFW.Jobs[j.name] and VFW.Jobs[j.name].grades or {} }
                TriggerServerEvent('spacemarket:create:job', j.name, createData)
                StaffMenu.builderMarketCreate.refresh()
                StaffMenu.builderMarketList.refresh()
            end)
        end
    end

    StaffMenu.builderMarketCreate.Separator()
    StaffMenu.builderMarketCreate.Button(":refresh: RAFRAÎCHIR", "Recharger la liste", nil, "arrow", false, function()
        StaffMenu.builderMarketCreate.refresh()
    end)
end

function StaffMenu.BuildEditMarketMenu()
    if not marketSelected.society then
        StaffMenu.builderMarketEdit.Button("Aucun job sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local soc = marketSelected.society
    soc.custom = soc.custom or {}
    soc.custom.spacemarket = soc.custom.spacemarket or { enabled = false, grades = {}, items = {} }

    StaffMenu.builderMarketEdit.Separator("JOB: " .. (soc.label or soc.name))

    StaffMenu.builderMarketEdit.Checkbox(":check: MARKET ACTIVÉ", "Activer la boutique pour ce job", false, soc.custom.spacemarket.enabled or false, function(value)
        soc.custom.spacemarket.enabled = value
        marketSelected.society = soc
        -- Sync to DB
        TriggerServerEvent('spacemarket:update:job', soc.name, { enabled = soc.custom.spacemarket.enabled, allowed_grades = soc.custom.spacemarket.grades or {} })
        StaffMenu.builderMarketEdit.refresh()
    end)

    local gradesDesc = "Aucun filtre (tous les grades)"
  if soc.custom.spacemarket.grades and next(soc.custom.spacemarket.grades) then
        local gradeList = {}
        for _, grade in ipairs(soc.custom.spacemarket.grades) do
            table.insert(gradeList, tostring(grade))
        end
        gradesDesc = table.concat(gradeList, ", ")
    end

    StaffMenu.builderMarketEdit.Button(":hash: GRADES AUTORISÉS", gradesDesc, nil, "chevron", false, function()
        if not soc or not soc.name then
            print("^1[GradesSelector] Error: soc or soc.name is nil^7")
            return
        end
        
        -- Get grades from server callback
        local jobData = TriggerServerCallback("core:jobs:getJob", soc.name)
        if not jobData or not jobData.grades then
            print("^1[GradesSelector] Error: jobData or grades not found from server^7")
            return
        end
        
        -- Convert grades to array format for React
        local gradesArray = {}
        for gradeKey, gradeData in pairs(jobData.grades) do
            table.insert(gradesArray, {
                grade = tonumber(gradeData.grade or gradeKey),
                name = gradeData.name,
                label = gradeData.label
            })
        end
        table.sort(gradesArray, function(a, b) return a.grade < b.grade end)
        
        -- Store reference for callbacks
        marketSelected.society = soc
        
        SendNUIMessage({
            action = "openMarketGrades",
            data = {
                job = soc.name,
                grades = gradesArray,
                selectedGrades = soc.custom and soc.custom.spacemarket and soc.custom.spacemarket.grades or {}
            }
        })
        VFW.Nui.Focus(true)
    end)

    StaffMenu.builderMarketEdit.Button(":folder: CATEGORIES", "Gérer les catégories de la boutique", nil, "chevron", false, function()
    end, StaffMenu.builderMarketCategories)

    StaffMenu.builderMarketEdit.Button(":box: ITEMS", "Gérer les items de la boutique", nil, "chevron", false, function()
    end, StaffMenu.builderMarketItems)

    StaffMenu.builderMarketEdit.Separator()
    StaffMenu.builderMarketEdit.Button(":check: SAUVEGARDER", nil, nil, "check", false, function()
        TriggerServerEvent('spacemarket:update:job', soc.name, {
            enabled = soc.custom.spacemarket.enabled,
            allowed_grades = soc.custom.spacemarket.grades or {}
        })

        StaffMenu.builderMarketEdit.close()
        StaffMenu.builderMarketList.refresh()
    end)

    StaffMenu.builderMarketEdit.Button(":trash: SUPPRIMER LE JOB", "Supprimer le job et sa boutique Market (irréversible)", nil, "trash", false, function()
        StaffMenu.builderMarketEdit.close()
        Wait(150)
        SetNuiFocus(true, true)
        local confirm = VFW.Nui.ConfirmPopup(":warning: Confirmation", "Supprimer le job " .. (soc.label or soc.name) .. " du Market ?")
        SetNuiFocus(false, false)
        if confirm then
            local success = TriggerServerCallback('spacemarket:delete:job', soc.name)
            if success then
                soc.custom = soc.custom or {}
                soc.custom.spacemarket = nil
                marketSelected.society = nil
            end
            Wait(100)
            StaffMenu.builderMarketList.refresh()
        else
            StaffMenu.builderMarketEdit.open()
        end
    end)
end

-- ==================== SPACE MARKET GRADES SELECTION ====================
-- Build menu for selecting authorized grades
function StaffMenu.BuildMarketEditGradesMenu()
    local data = StaffMenu.builderMarketEditGrades.data
    if not data or not data.socName then
        return
    end
    
    local soc = marketSelected.society
    if not soc or soc.name ~= data.socName then
        soc = TriggerServerCallback('core:get:societyData', data.socName) or {}
        marketSelected.society = soc
    end
    
    soc.custom = soc.custom or {}
    soc.custom.spacemarket = soc.custom.spacemarket or { enabled = false, grades = {}, items = {} }
    
    local selectedGrades = soc.custom.spacemarket.grades or {}
    local jobName = soc.name
    local jobData = VFW.Jobs[jobName]
    
    if not jobData or not jobData.grades then
        StaffMenu.builderMarketEditGrades.Button("Erreur: Job introuvable", nil, nil, nil, true, function() end)
        return
    end
    
    -- Convert grades to array and sort
    local gradesArray = {}
    for gradeNum, gradeData in pairs(jobData.grades) do
        table.insert(gradesArray, {
            grade = tonumber(gradeNum),
            name = gradeData.name,
            label = gradeData.label
        })
    end
    table.sort(gradesArray, function(a, b) return a.grade < b.grade end)
    
    StaffMenu.builderMarketEditGrades.Separator("GRADES: " .. (soc.label or soc.name))
    
    -- Select/Deselect All button
    local allSelected = #selectedGrades == #gradesArray and #gradesArray > 0
    StaffMenu.builderMarketEditGrades.Button(
        (allSelected and ":check: " or " ") .. "TOUS LES GRADES",
        #selectedGrades .. " / " .. #gradesArray .. " sélectionnés",
        nil,
        allSelected and "check" or "empty",
        false,
        function()
            if allSelected then
                soc.custom.spacemarket.grades = {}
            else
                soc.custom.spacemarket.grades = {}
                for _, grade in ipairs(gradesArray) do
                    table.insert(soc.custom.spacemarket.grades, grade.grade)
                end
            end
            marketSelected.society = soc
            TriggerServerEvent('spacemarket:update:job', soc.name, { 
                enabled = soc.custom.spacemarket.enabled, 
                allowed_grades = soc.custom.spacemarket.grades 
            })
            StaffMenu.builderMarketEditGrades.refresh()
        end
    )
    
    StaffMenu.builderMarketEditGrades.Separator()
    
    -- Individual grade checkboxes
    for _, gradeInfo in ipairs(gradesArray) do
        local isSelected = false
        for _, selectedGrade in ipairs(selectedGrades) do
            if selectedGrade == gradeInfo.grade then
                isSelected = true
                break
            end
        end
        
        local gradeLabel = (gradeInfo.label or "Grade " .. gradeInfo.grade)
        StaffMenu.builderMarketEditGrades.Button(
            (isSelected and ":check: " or " ") .. gradeLabel,
            "Grade #" .. gradeInfo.grade .. (isSelected and " (sélectionné)" or ""),
            nil,
            isSelected and "check" or "empty",
            false,
            function()
                local gradesList = soc.custom.spacemarket.grades or {}
                local index = nil
                for i, g in ipairs(gradesList) do
                    if g == gradeInfo.grade then
                        index = i
                        break
                    end
                end
                
                if index then
                    table.remove(gradesList, index)
                else
                    table.insert(gradesList, gradeInfo.grade)
                    table.sort(gradesList, function(a, b) return a < b end)
                end
                
                soc.custom.spacemarket.grades = gradesList
                marketSelected.society = soc
                TriggerServerEvent('spacemarket:update:job', soc.name, { 
                    enabled = soc.custom.spacemarket.enabled, 
                    allowed_grades = soc.custom.spacemarket.grades 
                })
                StaffMenu.builderMarketEditGrades.refresh()
            end
        )
    end
end

-- NUI Callback for saving grades via React component
RegisterNUICallback('saveMarketGrades', function(data, cb)
    if not marketSelected.society then
        cb({ success = false })
        return
    end

    local soc = marketSelected.society
    local selectedGrades = data.grades or {}

    table.sort(selectedGrades, function(a, b) return a < b end)

    soc.custom = soc.custom or {}
    soc.custom.spacemarket = soc.custom.spacemarket or {}
    soc.custom.spacemarket.grades = selectedGrades
    marketSelected.society = soc

    TriggerServerEvent('spacemarket:update:job', soc.name, {
        enabled = soc.custom.spacemarket.enabled,
        allowed_grades = selectedGrades
    })

    cb({ success = true })
end)

RegisterNUICallback('closeMarketGrades', function(data, cb)
    cb('ok')
    VFW.Nui.Focus(false)
    StaffMenu.builderMarketEdit.refresh()
end)

-- Categories management
local marketNewCategory = ""
local marketCategoryCallback = nil -- function(category) -> sets the category on target
local marketCategoryMenuContext = "add" -- "add" or "edit" - determines which parent to return to

function StaffMenu.BuildMarketCategoriesMenu()
    if not marketSelected.society then
        StaffMenu.builderMarketCategories.Button("Aucun job sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local soc = marketSelected.society
    soc.custom = soc.custom or {}
    soc.custom.spacemarket = soc.custom.spacemarket or { enabled = false, grades = {}, items = {}, categories = {} }

    StaffMenu.builderMarketCategories.Separator("CATEGORIES: " .. (soc.label or soc.name))
    StaffMenu.builderMarketCategories.Button(":plus: AJOUTER UNE CATÉGORIE", "Ajouter une nouvelle catégorie pour ce job", nil, "chevron", false, function()
        marketNewCategory = ""
  end, StaffMenu.builderMarketAddCategory)

    local cats = soc.custom.spacemarket.categories or {}
    if #cats == 0 then
        StaffMenu.builderMarketCategories.Button("Aucune catégorie", nil, nil, nil, true, function() end)
    else
        for i, c in ipairs(cats) do
            -- categories returned from server are tables { id, name }
            local displayName = (type(c) == 'table' and c.name) or tostring(c)
            StaffMenu.builderMarketCategories.Button(displayName, nil, nil, "chevron", false, function()
                if type(c) == 'table' then
                    StaffMenu.builderMarketEditCategory.data = { index = i, id = c.id, name = c.name, socName = soc.name }
                else
                    StaffMenu.builderMarketEditCategory.data = { index = i, name = c, socName = soc.name }
                end
            end, StaffMenu.builderMarketEditCategory)
        end
    end

    StaffMenu.builderMarketCategories.Separator()
    StaffMenu.builderMarketCategories.Button(":refresh: RAFRAÎCHIR", nil, nil, "arrow", false, function()
        StaffMenu.builderMarketCategories.refresh()
    end)
end

function StaffMenu.BuildMarketAddCategoryMenu()
    StaffMenu.builderMarketAddCategory.Separator("AJOUTER CATÉGORIE")
    StaffMenu.builderMarketAddCategory.Button(":edit: NOM", marketNewCategory ~= "" and marketNewCategory or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la catégorie", marketNewCategory)
        if input and input ~= "" then marketNewCategory = input end
        StaffMenu.builderMarketAddCategory.refresh()
    end)

    StaffMenu.builderMarketAddCategory.Button(":check: AJOUTER", nil, nil, "check", false, function()
        local soc = marketSelected.society
        if marketNewCategory and marketNewCategory ~= "" then
            TriggerServerEvent('spacemarket:add:category', soc.name, marketNewCategory)
            Wait(100)
            -- Refresh DB data and local society cache
            local dbData = TriggerServerCallback('spacemarket:get:job', soc.name) or {}
            soc.custom = soc.custom or {}
            soc.custom.spacemarket = soc.custom.spacemarket or {}
            soc.custom.spacemarket.categories = dbData.categories or {}

            StaffMenu.builderMarketAddCategory.close()
            StaffMenu.builderMarketCategories.refresh()
        else

        end
    end)
end

function StaffMenu.BuildMarketEditCategoryMenu()
    local data = StaffMenu.builderMarketEditCategory.data
    if not data or not data.name then
        StaffMenu.builderMarketEditCategory.Button("Erreur: Aucune catégorie sélectionnée", nil, nil, nil, true, function() end)
        return
    end

    local soc = TriggerServerCallback('core:get:societyData', data.socName) or {}
    soc.custom = soc.custom or {}
    soc.custom.spacemarket = soc.custom.spacemarket or { enabled = false, grades = {}, items = {}, categories = {} }

    local index = data.index
    local name = data.name
    local catId = data.id -- may be nil for legacy strings

    StaffMenu.builderMarketEditCategory.Separator("MODIFIER CATÉGORIE")
    StaffMenu.builderMarketEditCategory.Button(":edit: NOM", name, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la catégorie", name)
        if input and input ~= "" then
            name = input
            StaffMenu.builderMarketEditCategory.refresh()
        end
    end)

    StaffMenu.builderMarketEditCategory.Separator()
    StaffMenu.builderMarketEditCategory.Button(":check: SAUVEGARDER", nil, nil, "check", false, function()
        -- Update category name in DB (use id if available)
        if catId then
            TriggerServerEvent('spacemarket:update:category', soc.name, catId, name)
        else
            TriggerServerEvent('spacemarket:update:category', soc.name, data.name, name)
        end
        Wait(250)
        local dbData = TriggerServerCallback('spacemarket:get:job', soc.name) or {}
        soc.custom.spacemarket.categories = dbData.categories or {}

        StaffMenu.builderMarketEditCategory.close()
        StaffMenu.builderMarketCategories.refresh()
    end)

    StaffMenu.builderMarketEditCategory.Button(":trash: SUPPRIMER", nil, nil, "trash", false, function()
        StaffMenu.builderMarketEditCategory.close()
        Wait(150)
        SetNuiFocus(true, true)
        local confirm = VFW.Nui.ConfirmPopup(":warning: Confirmation", "Supprimer la catégorie '" .. name .. "' ?")
        SetNuiFocus(false, false)
        if confirm then
            -- Supprimer de la BDD
            if catId then
                TriggerServerCallback('spacemarket:delete:category', soc.name, catId)
            else
                TriggerServerCallback('spacemarket:delete:category', soc.name, data.name)
            end
            Wait(100)
            -- Re-fetch depuis la DB pour synchroniser le cache
            local dbData = TriggerServerCallback('spacemarket:get:job', soc.name) or {}
            if marketSelected.society then
                marketSelected.society.custom = marketSelected.society.custom or {}
                marketSelected.society.custom.spacemarket = marketSelected.society.custom.spacemarket or {}
                marketSelected.society.custom.spacemarket.categories = dbData.categories or {}
            end
            StaffMenu.builderMarketCategories.refresh()
        else
            StaffMenu.builderMarketEditCategory.open()
        end
    end)
end

function StaffMenu.BuildMarketChooseCategoryMenu(menu, parentMenu)
    if not menu then menu = StaffMenu.builderMarketChooseCategory end
    if not parentMenu then parentMenu = StaffMenu.builderMarketAddItem end

    if not marketSelected.society then
        menu.Button("Aucun job sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local soc = marketSelected.society
    if not soc or not soc.name then
        menu.Button("Aucun job sélectionné", nil, nil, nil, true, function() end)
        return
    end

    -- Fetch fresh categories from DB
    local db = TriggerServerCallback('spacemarket:get:job', soc.name) or {}
    local cats = db.categories or {}

    menu.Separator("CHOISIR CATÉGORIE: " .. (soc.label or soc.name))

    if #cats == 0 then
        menu.Button("Aucune catégorie disponible", nil, nil, nil, true, function() end)
    else
        for i, c in ipairs(cats) do
            local displayName = (type(c) == 'table' and c.name) or tostring(c)
            menu.Button(displayName, nil, nil, nil, false, function()
                if type(marketCategoryCallback) == 'function' then
                    if type(c) == 'table' then
                        marketCategoryCallback(c.name)
                    else
                        marketCategoryCallback(c)
                    end
                end
                marketCategoryCallback = nil
                -- Close the category selector and return to parent menu
                menu.close()
                parentMenu.open()
                parentMenu.refresh()
            end)
        end
    end
end

function StaffMenu.BuildMarketItemsMenu()
    if not marketSelected.society then
        StaffMenu.builderMarketItems.Button("Aucun job sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local soc = marketSelected.society
    soc.custom = soc.custom or {}
    soc.custom.spacemarket = soc.custom.spacemarket or { enabled = false, grades = {}, items = {} }

    StaffMenu.builderMarketItems.Separator("ITEMS: " .. (soc.label or soc.name))

    StaffMenu.builderMarketItems.Button(":plus: AJOUTER UN ITEM", "Ajouter un nouvel item à la boutique du job", nil, "chevron", false, function()
        marketNewItem = { name = "", label = "", price = 0, category = "", type = "item", item = "" }
        marketItemQuery = nil
        marketCurrentPage = 1
    end, StaffMenu.builderMarketAddItem)

    local items = soc.custom.spacemarket.items or {}
    if #items == 0 then
        StaffMenu.builderMarketItems.Button("Aucun item", nil, nil, nil, true, function() end)
    else
        for i, item in ipairs(items) do
            local displayLabel = (VFW.Items[item.item] and VFW.Items[item.item].label) or item.label or item.name or item.item
            StaffMenu.builderMarketItems.Button(displayLabel, VFW.Math.FormatMoney(item.price), nil, "chevron", false, function()
                StaffMenu.builderMarketEditItem.data = { index = i, item = item, socName = soc.name }
                marketItemQuery = nil
                marketCurrentPage = 1
            end, StaffMenu.builderMarketEditItem)
        end
    end

    StaffMenu.builderMarketItems.Separator()
    StaffMenu.builderMarketItems.Button(":refresh: RAFRAÎCHIR", nil, nil, "arrow", false, function()
        StaffMenu.builderMarketItems.refresh()
    end)
end

function StaffMenu.BuildMarketAddItemMenu()
    StaffMenu.builderMarketAddItem.Separator("AJOUT ITEM")
    -- allow choosing from global item list
    buildMarketItemBrowser(StaffMenu.builderMarketAddItem, marketNewItem)
    StaffMenu.builderMarketAddItem.Separator()
    StaffMenu.builderMarketAddItem.Textbox("Nom interne (ex: bread)", marketNewItem.item or "")
    StaffMenu.builderMarketAddItem.Button(":edit: NOM ITEM", marketNewItem.item ~= "" and marketNewItem.item or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom interne de l'item (ex: bread)", marketNewItem.item)
        if input and input ~= "" then marketNewItem.item = input end
        StaffMenu.builderMarketAddItem.refresh()
    end)

    StaffMenu.builderMarketAddItem.Button(":chat: LABEL", marketNewItem.label ~= "" and marketNewItem.label or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label affiché", marketNewItem.label)
        if input and input ~= "" then marketNewItem.label = input end
        StaffMenu.builderMarketAddItem.refresh()
    end)

    StaffMenu.builderMarketAddItem.Button(":money: PRIX", marketNewItem.price > 0 and VFW.Math.FormatMoney(marketNewItem.price) or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Prix (" .. LOCALE.currencySymbol .. ")", tostring(marketNewItem.price))
        if input and tonumber(input) then marketNewItem.price = tonumber(input) end
        StaffMenu.builderMarketAddItem.refresh()
    end)

    StaffMenu.builderMarketAddItem.Button(":folder: CATÉGORIE", marketNewItem.category ~= "" and marketNewItem.category or "Non défini", nil, "chevron", false, function()
        marketCategoryMenuContext = "add"
      marketCategoryCallback = function(c)
            marketNewItem.category = c
        end
        -- Open the category chooser menu
        StaffMenu.builderMarketChooseCategory.open()
    end)

    StaffMenu.builderMarketAddItem.Button(":check: AJOUTER L'ITEM", nil, nil, "check", false, function()
        local soc = marketSelected.society
        -- Send to server to insert in DB
        TriggerServerEvent('spacemarket:add:item', soc.name, marketNewItem)
        Wait(250)
        local dbData = TriggerServerCallback('spacemarket:get:job', soc.name) or {}
        soc.custom = soc.custom or {}
        soc.custom.spacemarket = soc.custom.spacemarket or {}
        soc.custom.spacemarket.items = dbData.items or {}

        StaffMenu.builderMarketAddItem.close()
        StaffMenu.builderMarketItems.refresh()
    end)
end

-- menu shown immediately after selecting an item from browser to fine-tune price/category
function StaffMenu.BuildMarketAddItemConfigMenu()
    local menu = StaffMenu.builderMarketAddItemConfig
    menu.Separator("CONFIGURATION ITEM")
    local displayLabel = marketNewItem.label or marketNewItem.item or "(aucun item)"
  menu.Title("Item", displayLabel)
    menu.Separator()

    menu.Button(":money: PRIX", marketNewItem.price and VFW.Math.FormatMoney(marketNewItem.price) or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Prix (" .. LOCALE.currencySymbol .. ")", tostring(marketNewItem.price or ""))
        local num = tonumber(input)
        if num then marketNewItem.price = num end
        menu.refresh()
    end)

    menu.Button(":folder: CATÉGORIE", marketNewItem.category ~= "" and marketNewItem.category or "Non défini", nil, "chevron", false, function()
        marketCategoryMenuContext = "add"
      marketCategoryCallback = function(c)
            marketNewItem.category = c
            menu.refresh()
        end
        StaffMenu.builderMarketChooseCategoryConfig.open()
    end)

    menu.Separator()
    menu.Button(":check: VALIDER & AJOUTER", nil, nil, "check", false, function()
        local soc = marketSelected.society
        if soc and soc.name then
            TriggerServerEvent('spacemarket:add:item', soc.name, marketNewItem)
            Wait(250)
            local dbData = TriggerServerCallback('spacemarket:get:job', soc.name) or {}
            soc.custom = soc.custom or {}
            soc.custom.spacemarket = soc.custom.spacemarket or {}
            soc.custom.spacemarket.items = dbData.items or {}

        end
        menu.close()
        StaffMenu.builderMarketAddItem.close()
        StaffMenu.builderMarketItems.refresh()
    end)
end

function StaffMenu.BuildMarketEditItemMenu()
    local data = StaffMenu.builderMarketEditItem.data
    if not data or not data.item then
        StaffMenu.builderMarketEditItem.Button("Erreur: Aucun item sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local socName = data.socName
    local index = data.index
    local item = data.item

    -- Ensure marketSelected.society is updated for category selection menu
    if not marketSelected.society or marketSelected.society.name ~= socName then
        marketSelected.society = TriggerServerCallback('core:get:societyData', socName) or {}
    end

    StaffMenu.builderMarketEditItem.Separator("ÉDITER ITEM")
    -- allow re-selecting the item from global list
    buildMarketItemBrowser(StaffMenu.builderMarketEditItem, item)
    StaffMenu.builderMarketEditItem.Separator()

    StaffMenu.builderMarketEditItem.Button(":chat: LABEL", item.label or item.item or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label affiché", item.label or item.item or "")
        if input then item.label = input end
        StaffMenu.builderMarketEditItem.refresh()
    end)

    StaffMenu.builderMarketEditItem.Button(":money: PRIX", VFW.Math.FormatMoney(item.price), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Prix (" .. LOCALE.currencySymbol .. ")", tostring(item.price))
        if input and tonumber(input) then item.price = tonumber(input) end
        StaffMenu.builderMarketEditItem.refresh()
    end)

    StaffMenu.builderMarketEditItem.Button(":folder: CATÉGORIE", item.category or "Non défini", nil, "chevron", false, function()
        marketCategoryMenuContext = "edit"
      marketCategoryCallback = function(c)
            item.category = c
        end
        -- Open the category chooser menu
        StaffMenu.builderMarketChooseCategory.open()
    end)

    StaffMenu.builderMarketEditItem.Separator()
    StaffMenu.builderMarketEditItem.Button(":check: SAUVEGARDER", nil, nil, "check", false, function()
        -- Update item in DB
        if item and item.id then
            TriggerServerEvent('spacemarket:update:item', item.id, item)
            Wait(250)
            local soc = TriggerServerCallback('core:get:societyData', socName) or {}
            local dbData = TriggerServerCallback('spacemarket:get:job', socName) or {}
            soc.custom = soc.custom or {}
            soc.custom.spacemarket = soc.custom.spacemarket or {}
            soc.custom.spacemarket.items = dbData.items or {}

            StaffMenu.builderMarketEditItem.close()
            StaffMenu.builderMarketItems.refresh()
        else
        end
    end)

    StaffMenu.builderMarketEditItem.Button(":trash: SUPPRIMER L'ITEM", nil, nil, "trash", false, function()
        if item and item.id then
            TriggerServerEvent('spacemarket:delete:item', item.id)
            Wait(250)
            local soc = TriggerServerCallback('core:get:societyData', socName) or {}
            local dbData = TriggerServerCallback('spacemarket:get:job', socName) or {}
            soc.custom = soc.custom or {}
            soc.custom.spacemarket = soc.custom.spacemarket or {}
            soc.custom.spacemarket.items = dbData.items or {}

            StaffMenu.builderMarketEditItem.close()
            StaffMenu.builderMarketItems.refresh()
        else
        end
    end)
end


-- Variables globales pour le menu de création
local supermarketData = {
    name = "",
    canRob = false, -- Par défaut non braquable
    active = true,
    blipEnabled = true,
    supermarketPos = nil,
    apuPos = nil,
    safePos = nil
}

-- Create Supermarket Menu
function StaffMenu.BuildCreateSuperMarketMenu()
    StaffMenu.CreateSuperMarket.Separator("CONFIGURATION SUPÉRETTE")

    -- Nom de la supérette
    StaffMenu.CreateSuperMarket.Button(":edit: NOM DE LA SUPÉRETTE", supermarketData.name ~= "" and supermarketData.name or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la supérette (ex: LTD Gasoline Davis)", supermarketData.name)
        if input and input ~= "" then
            supermarketData.name = input
            StaffMenu.CreateSuperMarket.refresh()
        end
    end)

    StaffMenu.CreateSuperMarket.Separator("OPTIONS")

    StaffMenu.CreateSuperMarket.Checkbox(":check: ACTIVE", nil, false, supermarketData.active, function(value)
        supermarketData.active = value
        StaffMenu.CreateSuperMarket.refresh()
    end)

    StaffMenu.CreateSuperMarket.Checkbox(":pin: BLIP SUR LA MAP", nil, false, supermarketData.blipEnabled, function(value)
        supermarketData.blipEnabled = value
        StaffMenu.CreateSuperMarket.refresh()
    end)

    -- Option braquable (si coché, demande position coffre en plus)
    StaffMenu.CreateSuperMarket.Checkbox(":gun: BRAQUABLE", "Si activé, nécessite position coffre", false, supermarketData.canRob, function(value)
        supermarketData.canRob = value
        if not value then
            -- Reset la position coffre si désactivé
            supermarketData.safePos = nil
        end
        StaffMenu.CreateSuperMarket.refresh()
    end)

    StaffMenu.CreateSuperMarket.Separator("POSITIONS")

    StaffMenu.CreateSuperMarket.Button(":pin: POSITION SUPÉRETTE + ZONE", supermarketData.supermarketPos and "Définie (rayon: 2m)" or "Non définie", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        supermarketData.supermarketPos = {x = pos.x, y = pos.y, z = pos.z}
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position de la supérette définie (zone de 2m)."
      })
        StaffMenu.CreateSuperMarket.refresh()
    end)

    -- Position APU toujours requise (braquable ou non)
    StaffMenu.CreateSuperMarket.Button(":user: POSITION APU", supermarketData.apuPos and "Définie" or "Non définie", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        supermarketData.apuPos = {x = pos.x, y = pos.y, z = pos.z, h = heading}
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position et orientation de l'APU définies."
      })
        StaffMenu.CreateSuperMarket.refresh()
    end)

    -- Position coffre seulement si braquable
    if supermarketData.canRob then
        StaffMenu.CreateSuperMarket.Button(":lock: POSITION COFFRE", supermarketData.safePos and "Définie" or "Non définie", nil, "arrow", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            supermarketData.safePos = {x = pos.x, y = pos.y, z = pos.z, h = heading}
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Position du coffre définie (direction enregistrée)."
          })
            StaffMenu.CreateSuperMarket.refresh()
        end)
    end

    StaffMenu.CreateSuperMarket.Separator("VALIDATION")

    StaffMenu.CreateSuperMarket.Button(":check: CRÉER LA SUPÉRETTE", "Valider la création", nil, "chevron", false, function()
        if supermarketData.name == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Veuillez entrer un nom."
          })
            return
        end

        if not supermarketData.supermarketPos then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Veuillez définir la position de la supérette."
          })
            return
        end

        -- APU position toujours requise
        if not supermarketData.apuPos then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Veuillez définir la position de l'APU."
          })
            return
        end

        -- Coffre position required for robbable stores
        if supermarketData.canRob and not supermarketData.safePos then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Veuillez définir la position du coffre."
          })
            return
        end

        -- Toujours type robbable maintenant (APU présent dans tous les cas)
        TriggerServerEvent("core:supermarket:createSupermarket", {
            name = supermarketData.name,
            pos = supermarketData.supermarketPos,
            apuPos = supermarketData.apuPos,
            safePos = supermarketData.canRob and supermarketData.safePos or nil,
            canRob = supermarketData.canRob,
            active = supermarketData.active,
            blipEnabled = supermarketData.blipEnabled,
            storeType = "robbable", -- Toujours robbable car APU présent
            zoneRadius = 2.0 -- Rayon fixé à 2m
        })

        -- Reset data
        supermarketData = {
            name = "",
            canRob = false,
            active = true,
            blipEnabled = true,
            supermarketPos = nil,
            apuPos = nil,
            safePos = nil
        }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Supérette créée."
      })

        StaffMenu.CreateSuperMarket.close()
    end)
end

-- Firework Shop Builder for Staff Menu

-- Initialize firework data in StaffMenu.data
if not StaffMenu.data.firework then
    StaffMenu.data.firework = {}
end

StaffMenu.data.firework.currentBuild = {
    name = "",
    position = nil,
    npcPosition = nil,
    npcModel = "mp_m_shopkeep_01",
    blipEnabled = true,
    active = true,
    isValid = false
}

StaffMenu.data.firework.currentItemBuild = {
    item_name = "",
    price = 0,
    category = "tous",
    stock = 0
}

local markerThread = nil
local isMarkersActive = false

local FIREWORK_CATEGORIES = {
    {value = "tous", label = "Tous"},
    {value = "petit", label = "Petit"},
    {value = "moyen", label = "Moyen"},
    {value = "grand", label = "Grand"}
}

local function getCategoryLabel(category)
    for _, cat in ipairs(FIREWORK_CATEGORIES) do
        if cat.value == category then
            return cat.label
        end
    end
    return category
end

local function validateFireworkBuild()
    StaffMenu.data.firework.currentBuild.isValid = StaffMenu.data.firework.currentBuild.name ~= "" and
            StaffMenu.data.firework.currentBuild.npcPosition ~= nil
    return StaffMenu.data.firework.currentBuild.isValid
end

local function validateItemBuild()
    return StaffMenu.data.firework.currentItemBuild.item_name ~= "" and
            StaffMenu.data.firework.currentItemBuild.price > 0 and
            StaffMenu.data.firework.currentItemBuild.category ~= ""
end

local function getCurrentPlayerPosition()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return nil
    end

    local coords = GetEntityCoords(playerPed)
    if not coords then
        return nil
    end

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = GetEntityHeading(playerPed)
    }
end

function stopMarkerThread()
    isMarkersActive = false
    markerThread = nil
end

function startMarkerThread()
    if isMarkersActive then
        return
    end

    isMarkersActive = true
    markerThread = CreateThread(function()
        while isMarkersActive do
            if StaffMenu.data.firework.currentBuild.position then
                local blipPos = StaffMenu.data.firework.currentBuild.position
                local coords = vector3(blipPos.x, blipPos.y, blipPos.z)

                DrawMarker(
                    1,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    255, 165, 0, 150,
                    false, true, 2, false, nil, nil, false
                )

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 165, 0, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("BLIP")
                    DrawText(screenX, screenY)
                end
            end

            if StaffMenu.data.firework.currentBuild.npcPosition then
                local npcPos = StaffMenu.data.firework.currentBuild.npcPosition
                local coords = vector3(npcPos.x, npcPos.y, npcPos.z)

                DrawMarker(
                    27,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 165, 0, 150,
                    false, true, 2, false, nil, nil, false
                )

                local text = "VENDEUR\n" .. StaffMenu.data.firework.currentBuild.name

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 165, 0, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString(text)
                    DrawText(screenX, screenY)
                end
            end

            Wait(0)
        end
    end)
end

local function resetFireworkBuild()
    stopMarkerThread()
    StaffMenu.data.firework.currentBuild = {
        name = "",
        position = nil,
        npcPosition = nil,
        npcModel = "mp_m_shopkeep_01",
        blipEnabled = true,
        active = true,
        isValid = false
    }
end

local function resetItemBuild()
    StaffMenu.data.firework.currentItemBuild = {
        item_name = "",
        price = 0,
        category = "tous",
        stock = 0
    }
end

local function setBlipPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        StaffMenu.data.firework.currentBuild.position = pos
        validateFireworkBuild()
        return true
    end
    return false
end

local function setNpcPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        StaffMenu.data.firework.currentBuild.npcPosition = pos
        validateFireworkBuild()
        return true
    end
    return false
end

local function finalizeFireworkCreation()
    if not validateFireworkBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
        return false
    end

    local shopData = {
        name = StaffMenu.data.firework.currentBuild.name,
        pos = StaffMenu.data.firework.currentBuild.position or StaffMenu.data.firework.currentBuild.npcPosition,
        npcPos = StaffMenu.data.firework.currentBuild.npcPosition,
        npcModel = StaffMenu.data.firework.currentBuild.npcModel,
        blipEnabled = StaffMenu.data.firework.currentBuild.blipEnabled,
        active = StaffMenu.data.firework.currentBuild.active
    }

    TriggerServerEvent('core:firework:createShop', shopData)
    resetFireworkBuild()
    return true
end

local function finalizeItemCreation()
    if not validateItemBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration d'article n'est pas valide."})
        return false
    end

    TriggerServerEvent('core:firework:addGlobalItem', StaffMenu.data.firework.currentItemBuild.item_name, StaffMenu.data.firework.currentItemBuild.price, StaffMenu.data.firework.currentItemBuild.category, StaffMenu.data.firework.currentItemBuild.stock)
    resetItemBuild()
    return true
end

function StaffMenu.BuildFireworkBuilderMenu()
    if not StaffMenu or not StaffMenu.builderFirework then
        return
    end

    StaffMenu.builderFirework.Button(':plus: CRÉER UNE BOUTIQUE', 'Créer une nouvelle boutique de feux d\'artifice',
            nil, 'chevron', false, function()
                resetFireworkBuild()
            end, StaffMenu.builderFireworkCreate)

    StaffMenu.builderFirework.Button(':report: GÉRER LES BOUTIQUES', 'Voir et gérer les boutiques existantes',
            nil, 'chevron', false, function()
                local shops = TriggerServerCallback('core:firework:getShops')
                StaffMenu.currentFireworkShops = shops or {}
            end, StaffMenu.builderFireworkManage)

    StaffMenu.builderFirework.Button(':sparkles: GÉRER LES ARTICLES', 'Gérer le catalogue global d\'articles',
            nil, 'chevron', false, function()
                local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
                StaffMenu.currentFireworkItems = items or {}
            end, StaffMenu.builderFireworkItems)

    StaffMenu.builderFirework.Button(':settings: PARAMÈTRES ÉCONOMIE', 'Multiplicateur prix, limites d\'achats',
            nil, 'chevron', false, function()
            end, StaffMenu.builderFireworkSettings)

    StaffMenu.builderFirework.Separator("ACTIONS")

    StaffMenu.builderFirework.Button(':refresh: RECHARGER DEPUIS BDD', 'Recharge depuis la base de données',
            nil, 'arrow', false, function()
                TriggerServerEvent('core:firework:reloadFromDatabase')
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                    message = "Rechargement en cours."
              })
            end)
end

function StaffMenu.BuildCreateFireworkShopMenu()
    if not StaffMenu or not StaffMenu.builderFireworkCreate then
        return
    end

    StaffMenu.builderFireworkCreate.Button(":edit: NOM: " .. (StaffMenu.data.firework.currentBuild.name ~= "" and StaffMenu.data.firework.currentBuild.name or "NON DÉFINI"),
            "Définir le nom de la boutique", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de la boutique", StaffMenu.data.firework.currentBuild.name)
                if result and result ~= "" then
                    StaffMenu.data.firework.currentBuild.name = result
                    validateFireworkBuild()
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                end
            end)

    local blipPositionText = StaffMenu.data.firework.currentBuild.position and
            string.format("X: %.2f Y: %.2f Z: %.2f", StaffMenu.data.firework.currentBuild.position.x,
                    StaffMenu.data.firework.currentBuild.position.y, StaffMenu.data.firework.currentBuild.position.z) or "NON DÉFINI"

  StaffMenu.builderFireworkCreate.Button(":pin: POSITION BLIP: " .. blipPositionText,
            "Définir la position du blip sur la carte", nil, "arrow", false,
            function()
                if setBlipPosition() then
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    local npcPositionText = StaffMenu.data.firework.currentBuild.npcPosition and
            string.format("X: %.2f Y: %.2f Z: %.2f", StaffMenu.data.firework.currentBuild.npcPosition.x,
                    StaffMenu.data.firework.currentBuild.npcPosition.y, StaffMenu.data.firework.currentBuild.npcPosition.z) or "NON DÉFINI"

  StaffMenu.builderFireworkCreate.Button(":user: POSITION VENDEUR: " .. npcPositionText,
            "Définir la position du vendeur (NPC)", nil, "arrow", false,
            function()
                if setNpcPosition() then
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    StaffMenu.builderFireworkCreate.Button(":mask: MODÈLE PNJ: " .. StaffMenu.data.firework.currentBuild.npcModel,
            "Définir le modèle du PNJ vendeur", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Modèle du PNJ (ex: mp_m_shopkeep_01)", StaffMenu.data.firework.currentBuild.npcModel)
                if result and result ~= "" then
                    StaffMenu.data.firework.currentBuild.npcModel = result
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkCreate.Button(":pin: BLIP: " .. (StaffMenu.data.firework.currentBuild.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
            "Activer ou désactiver le blip sur la carte", nil, "arrow", false,
            function()
                StaffMenu.data.firework.currentBuild.blipEnabled = not StaffMenu.data.firework.currentBuild.blipEnabled
                if StaffMenu.builderFireworkCreate.refresh then
                    StaffMenu.builderFireworkCreate.refresh()
                end
            end)

    StaffMenu.builderFireworkCreate.Separator(nil)

    local statusMessage = ""
  if not StaffMenu.data.firework.currentBuild.name or StaffMenu.data.firework.currentBuild.name == "" then
        statusMessage = "Nom de la boutique requis"
  elseif not StaffMenu.data.firework.currentBuild.npcPosition then
        statusMessage = "Position du vendeur requise"
  else
        statusMessage = "Configuration terminée"
  end

    StaffMenu.builderFireworkCreate.Button(":check: CRÉER LA BOUTIQUE", statusMessage,
            nil, "chevron", not StaffMenu.data.firework.currentBuild.isValid,
            function()
                finalizeFireworkCreation()
            end)
end

function StaffMenu.BuildManageFireworkShopsMenu()
    if not StaffMenu or not StaffMenu.builderFireworkManage then
        return
    end

    local shops = StaffMenu.currentFireworkShops or {}
    local hasShops = #shops > 0

    local separatorText = hasShops and 'BOUTIQUES EXISTANTES' or 'AUCUNE BOUTIQUE'
    StaffMenu.builderFireworkManage.Separator(separatorText)

    if hasShops then
        for _, shopData in ipairs(shops) do
            if shopData and shopData.name then
                local posText = shopData.pos and string.format("X: %.0f Y: %.0f Z: %.0f",
                        shopData.pos.x, shopData.pos.y, shopData.pos.z) or "Position inconnue"

              StaffMenu.builderFireworkManage.Button(":sparkles: " .. shopData.name .. " #" .. shopData.id,
                        posText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentFireworkShopId = shopData.id
                            StaffMenu.currentFireworkShopData = shopData
                        end, StaffMenu.builderFireworkEdit)
            end
        end
    end
end

function StaffMenu.BuildEditFireworkShopMenu()
    if not StaffMenu or not StaffMenu.builderFireworkEdit then
        return
    end

    local shopId = StaffMenu.currentFireworkShopId
    local shopData = StaffMenu.currentFireworkShopData

    if not shopId or not shopData then
        return
    end

    StaffMenu.builderFireworkEdit.Separator("BOUTIQUE #" .. shopId)
    StaffMenu.builderFireworkEdit.Button(":sparkles: NOM: " .. shopData.name,
            "Nom de la boutique", nil, "check", true, function() end)

    local blipPosText = shopData.pos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.pos.x, shopData.pos.y, shopData.pos.z) or "NON DÉFINI"

  StaffMenu.builderFireworkEdit.Button(":pin: POSITION BLIP: " .. blipPosText,
            "Modifier la position du blip", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('core:firework:updateShop', shopId, 'pos', pos)
                    shopData.pos = pos
                    if StaffMenu.builderFireworkEdit.refresh then
                        StaffMenu.builderFireworkEdit.refresh()
                    end
                end
            end)

    local npcPosText = shopData.npcPos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.npcPos.x, shopData.npcPos.y, shopData.npcPos.z) or "NON DÉFINI"

  StaffMenu.builderFireworkEdit.Button(":user: POSITION VENDEUR: " .. npcPosText,
            "Modifier la position du vendeur", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('core:firework:updateShop', shopId, 'npcPos', pos)
                    shopData.npcPos = pos
                    if StaffMenu.builderFireworkEdit.refresh then
                        StaffMenu.builderFireworkEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":mask: MODÈLE PNJ: " .. (shopData.npcModel or "mp_m_shopkeep_01"),
            "Modifier le modèle du PNJ", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Modèle du PNJ", shopData.npcModel or "mp_m_shopkeep_01")
                if result and result ~= "" then
                    TriggerServerEvent('core:firework:updateShop', shopId, 'npcModel', result)
                    shopData.npcModel = result
                    if StaffMenu.builderFireworkEdit.refresh then
                        StaffMenu.builderFireworkEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":check: ACTIVE: " .. (shopData.active and "OUI" or "NON"),
            "Activer ou désactiver la boutique", nil, "arrow", false,
            function()
                local newValue = not shopData.active
                TriggerServerEvent('core:firework:updateShop', shopId, 'active', newValue)
                shopData.active = newValue
                if StaffMenu.builderFireworkEdit.refresh then
                    StaffMenu.builderFireworkEdit.refresh()
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":pin: BLIP: " .. (shopData.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
            "Activer ou désactiver le blip", nil, "arrow", false,
            function()
                local newValue = not shopData.blipEnabled
                TriggerServerEvent('core:firework:updateShop', shopId, 'blipEnabled', newValue)
                shopData.blipEnabled = newValue
                if StaffMenu.builderFireworkEdit.refresh then
                    StaffMenu.builderFireworkEdit.refresh()
                end
            end)

    StaffMenu.builderFireworkEdit.Separator("ACTIONS")

    StaffMenu.builderFireworkEdit.Button(":pin: TÉLÉPORTER AU VENDEUR",
            "Se téléporter à la position du vendeur", nil, "arrow", false,
            function()
                local npcPos = shopData.npcPos or shopData.pos
                if npcPos then
                    SetEntityCoords(PlayerPedId(), npcPos.x, npcPos.y, npcPos.z, false, false, false, true)
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":trash: SUPPRIMER LA BOUTIQUE",
            "Supprimer définitivement cette boutique", nil, "chevron", false,
            function()
                TriggerServerEvent('core:firework:deleteShop', shopId)
                local shops = TriggerServerCallback('core:firework:getShops')
                StaffMenu.currentFireworkShops = shops or {}
            end)
end

function StaffMenu.BuildFireworkItemsMenu()
    if not StaffMenu or not StaffMenu.builderFireworkItems then
        return
    end

    StaffMenu.builderFireworkItems.Button(':plus: AJOUTER UN ARTICLE', 'Ajouter un nouvel article au catalogue',
            nil, 'chevron', false, function()
                resetItemBuild()
            end, StaffMenu.builderFireworkItemCreate)

    local items = StaffMenu.currentFireworkItems or {}
    local hasItems = #items > 0

    local separatorText = hasItems and 'ARTICLES EXISTANTS' or 'AUCUN ARTICLE'
    StaffMenu.builderFireworkItems.Separator(separatorText)

    if hasItems then
        for _, item in ipairs(items) do
            if item then
                local categoryLabel = getCategoryLabel(item.category)
                local priceText = string.format("%s | Stock: %d | %s", VFW.Math.FormatMoney(item.price), item.stock or 0, categoryLabel)
                local itemLabel = item.label or item.name
                local enabled = item.enabled == true or item.enabled == 1
                local statusIcon = enabled and ":check:" or ":ban:"
              local statusText = enabled and "" or " (DÉSACTIVÉ)"

              StaffMenu.builderFireworkItems.Button(statusIcon .. " " .. itemLabel .. statusText,
                        priceText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentFireworkItemId = item.id
                            StaffMenu.currentFireworkItemData = item
                        end, StaffMenu.builderFireworkItemEdit)
            end
        end
    end
end

function StaffMenu.BuildCreateFireworkItemMenu()
    if not StaffMenu or not StaffMenu.builderFireworkItemCreate then
        return
    end

    local itemLabel = StaffMenu.data.firework.currentItemBuild.item_name ~= "" and (VFW.Items[StaffMenu.data.firework.currentItemBuild.item_name] and VFW.Items[StaffMenu.data.firework.currentItemBuild.item_name].label or StaffMenu.data.firework.currentItemBuild.item_name) or "NON DÉFINI"

  StaffMenu.builderFireworkItemCreate.Button(":edit: ITEM: " .. itemLabel,
            "Nom technique de l'item", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de l'item", StaffMenu.data.firework.currentItemBuild.item_name)
                if result and result ~= "" then
                    StaffMenu.data.firework.currentItemBuild.item_name = result
                    if StaffMenu.builderFireworkItemCreate.refresh then
                        StaffMenu.builderFireworkItemCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkItemCreate.Button(":money: PRIX: " .. VFW.Math.FormatMoney(StaffMenu.data.firework.currentItemBuild.price),
            "Définir le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(StaffMenu.data.firework.currentItemBuild.price))
                if result and result ~= "" then
                    StaffMenu.data.firework.currentItemBuild.price = tonumber(result) or 0
                    if StaffMenu.builderFireworkItemCreate.refresh then
                        StaffMenu.builderFireworkItemCreate.refresh()
                    end
                end
            end)

    local categoryLabels = {}
    for _, cat in ipairs(FIREWORK_CATEGORIES) do
        table.insert(categoryLabels, cat.label)
    end

    local currentIndex = 1
    for i, cat in ipairs(FIREWORK_CATEGORIES) do
        if cat.value == StaffMenu.data.firework.currentItemBuild.category then
            currentIndex = i
            break
        end
    end

    StaffMenu.builderFireworkItemCreate.List("CATÉGORIE",
            "Sélectionner la catégorie de l'article", false, categoryLabels, currentIndex,
            function(index, item)
                StaffMenu.data.firework.currentItemBuild.category = FIREWORK_CATEGORIES[index].value
                if StaffMenu.builderFireworkItemCreate.refresh then
                    StaffMenu.builderFireworkItemCreate.refresh()
                end
            end)

    StaffMenu.builderFireworkItemCreate.Button(":box: STOCK INITIAL: " .. StaffMenu.data.firework.currentItemBuild.stock,
            "Définir le stock initial", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Stock initial", tostring(StaffMenu.data.firework.currentItemBuild.stock))
                if result and result ~= "" then
                    StaffMenu.data.firework.currentItemBuild.stock = tonumber(result) or 0
                    if StaffMenu.builderFireworkItemCreate.refresh then
                        StaffMenu.builderFireworkItemCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkItemCreate.Separator(nil)

    local statusMessage = ""
  if not StaffMenu.data.firework.currentItemBuild.item_name or StaffMenu.data.firework.currentItemBuild.item_name == "" then
        statusMessage = "Nom de l'article requis"
  elseif StaffMenu.data.firework.currentItemBuild.price <= 0 then
        statusMessage = "Prix valide requis"
  else
        statusMessage = "Configuration terminée"
  end

    StaffMenu.builderFireworkItemCreate.Button(":check: AJOUTER L'ARTICLE", statusMessage,
            nil, "chevron", not validateItemBuild(),
            function()
                if finalizeItemCreation() then
                    local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
                    StaffMenu.currentFireworkItems = items or {}
                end
            end)
end

function StaffMenu.BuildEditFireworkItemMenu()
    if not StaffMenu or not StaffMenu.builderFireworkItemEdit then
        return
    end

    local itemId = StaffMenu.currentFireworkItemId
    local itemData = StaffMenu.currentFireworkItemData

    if not itemId or not itemData then
        return
    end

    local itemLabel = itemData.label or itemData.name

    StaffMenu.builderFireworkItemEdit.Separator("ARTICLE #" .. itemId)
    StaffMenu.builderFireworkItemEdit.Button(":sparkles: NOM: " .. itemLabel,
            itemData.name, nil, "check", true, function() end)

    StaffMenu.builderFireworkItemEdit.Button(":money: PRIX: " .. VFW.Math.FormatMoney(itemData.price),
            "Modifier le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(itemData.price))
                if result and result ~= "" then
                    local newPrice = tonumber(result) or itemData.price
                    TriggerServerEvent('core:firework:updateGlobalItem', itemData.name, newPrice, nil, nil, nil)
                    itemData.price = newPrice
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                end
            end)

    local categoryLabel = getCategoryLabel(itemData.category)
    StaffMenu.builderFireworkItemEdit.Button(":folder: CATÉGORIE: " .. categoryLabel,
            "Catégorie de l'article", nil, "check", true, function() end)

    StaffMenu.builderFireworkItemEdit.Button(":box: STOCK: " .. (itemData.stock or 0),
            "Modifier le stock", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Stock", tostring(itemData.stock or 0))
                if result and result ~= "" then
                    local newStock = tonumber(result) or 0
                    TriggerServerEvent('core:firework:updateGlobalItem', itemData.name, nil, nil, nil, newStock)
                    itemData.stock = newStock
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkItemEdit.Separator("ACTIONS")

    if itemData.enabled then
        StaffMenu.builderFireworkItemEdit.Button(":ban: DÉSACTIVER L'ARTICLE",
                "Masquer cet article du catalogue (il ne sera plus visible en boutique)", nil, "chevron", false,
                function()
                    TriggerServerEvent('core:firework:removeGlobalItem', itemData.name)
                    itemData.enabled = false
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                end)
    else
        StaffMenu.builderFireworkItemEdit.Button(":check: ACTIVER L'ARTICLE",
                "Remettre cet article visible dans le catalogue", nil, "chevron", false,
                function()
                    TriggerServerEvent('core:firework:enableGlobalItem', itemData.name)
                    itemData.enabled = true
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                end)
    end
end

function StaffMenu.BuildFireworkSettingsMenu()
    if not StaffMenu or not StaffMenu.builderFireworkSettings then
        return
    end

    local settings = TriggerServerCallback('core:firework:getSettings') or {}

    StaffMenu.builderFireworkSettings.Separator("PARAMÈTRES ÉCONOMIE")

    StaffMenu.builderFireworkSettings.Button(":money: MULTIPLICATEUR PRIX: " .. (settings.basePriceMultiplier or 1.0),
            "Multiplicateur global appliqué aux prix", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Multiplicateur prix (ex: 1.0, 1.2)", tostring(settings.basePriceMultiplier or 1.0))
                if result and result ~= "" then
                    local multiplier = tonumber(result) or 1.0
                    TriggerServerEvent('core:firework:updateSettings', 'basePriceMultiplier', multiplier)
                    settings.basePriceMultiplier = multiplier
                    if StaffMenu.builderFireworkSettings.refresh then
                        StaffMenu.builderFireworkSettings.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkSettings.Button(":chart: LIMITE ACHATS/JOUR: " .. (settings.maxDailyPurchases or 0) .. (settings.maxDailyPurchases == 0 and " (illimité)" or ""),
            "Limite d'achats par joueur par 24h (0 = illimité)", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Limite d'achats/jour (0 = illimité)", tostring(settings.maxDailyPurchases or 0))
                if result and result ~= "" then
                    local limit = tonumber(result) or 0
                    TriggerServerEvent('core:firework:updateSettings', 'maxDailyPurchases', limit)
                    settings.maxDailyPurchases = limit
                    if StaffMenu.builderFireworkSettings.refresh then
                        StaffMenu.builderFireworkSettings.refresh()
                    end
                end
            end)
end

-- List Supermarket Menu
function StaffMenu.BuildListSuperMarketMenu()
    StaffMenu.ListSuperMarket.Separator("LISTE DES SUPÉRETTES")

    -- Get supermarkets from server
    local supermarkets = TriggerServerCallback("core:supermarket:getSupermarkets") or {}

    if #supermarkets == 0 then
        StaffMenu.ListSuperMarket.Button("Aucune supérette", nil, nil, nil, true, function() end)
    else
        for _, supermarket in ipairs(supermarkets) do
            local statusText = supermarket.active and "Active" or "Inactive"
          local typeText = supermarket.canRob and "Braquable" or "Non-Braquable"

          StaffMenu.ListSuperMarket.Button(
                supermarket.name,
                statusText .. " | " .. typeText,
                nil,
                "chevron",
                false,
                function()
                    -- Store selected supermarket for editing
                    StaffMenu.selectedSupermarket = supermarket
                end,
                StaffMenu.EditSuperMarket
            )
        end
    end

    StaffMenu.ListSuperMarket.Separator("ACTIONS")

    StaffMenu.ListSuperMarket.Button(":refresh: RAFRAÎCHIR", "Recharger la liste", nil, "arrow", false, function()
        StaffMenu.ListSuperMarket.refresh()
    end)
end

-- Edit Supermarket Menu
function StaffMenu.BuildEditSuperMarketMenu()
    if not StaffMenu.selectedSupermarket then
        StaffMenu.EditSuperMarket.Button("Erreur: Aucune supérette sélectionnée", nil, nil, nil, true, function() end)
        return
    end

    local supermarket = StaffMenu.selectedSupermarket

    StaffMenu.EditSuperMarket.Separator("ÉDITION: " .. supermarket.name)

    StaffMenu.EditSuperMarket.Button(":edit: RENOMMER", supermarket.name, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom", supermarket.name)
        if input and input ~= "" then
            supermarket.name = input
            TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "name", input)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Nom mis à jour."
          })
            StaffMenu.EditSuperMarket.refresh()
        end
    end)

    StaffMenu.EditSuperMarket.Checkbox(":check: ACTIVE", nil, false, supermarket.active, function(value)
        supermarket.active = value
        TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "active", value)
        VFW.ShowNotification({
            type = 'STAFF', variant = value and 'SUCCESS' or 'INFO', subtitle = 'Builder',
            message = value and "Supérette activée." or "Supérette désactivée."
      })
    end)

    StaffMenu.EditSuperMarket.Checkbox(":pin: BLIP", nil, false, supermarket.blipEnabled, function(value)
        supermarket.blipEnabled = value
        TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "blipEnabled", value)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = value and "Blip activé." or "Blip désactivé."
      })
    end)

    -- Braquable checkbox (ne change plus le type - tous les stores avec APU sont "robbable")
    StaffMenu.EditSuperMarket.Checkbox(":gun: BRAQUABLE", nil, false, supermarket.canRob, function(value)
        supermarket.canRob = value
        -- storeType reste toujours "robbable" car tous les stores ont un APU maintenant
        supermarket.storeType = "robbable"
      TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "canRob", value)
        TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "storeType", "robbable")
        TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "zoneRadius", 2.0) -- Fixer à 2m
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = value and "Braquage activé." or "Braquage désactivé."
      })
        StaffMenu.EditSuperMarket.refresh()
    end)

    StaffMenu.EditSuperMarket.Separator("POSITIONS")

    StaffMenu.EditSuperMarket.Button(":pin: SE TÉLÉPORTER", "Aller à la supérette", nil, "arrow", false, function()
        if supermarket.pos then
            SetEntityCoords(PlayerPedId(), supermarket.pos.x, supermarket.pos.y, supermarket.pos.z, false, false, false, true)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Téléporté à " .. supermarket.name .. "."
          })
        end
    end)

    StaffMenu.EditSuperMarket.Button(":pin: METTRE À JOUR POSITION", "Position actuelle", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        supermarket.pos = {x = pos.x, y = pos.y, z = pos.z}
        TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "pos", supermarket.pos)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position mise à jour."
      })
        StaffMenu.EditSuperMarket.refresh()
    end)

    StaffMenu.EditSuperMarket.Button(":user: POSITION APU", supermarket.apuPos and "Définie" or "Non définie", nil, "arrow", false, function()
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        supermarket.apuPos = {x = pos.x, y = pos.y, z = pos.z, h = heading}
        TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "apuPos", supermarket.apuPos)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position APU mise à jour."
      })
        StaffMenu.EditSuperMarket.refresh()
    end)

    -- Bouton pour modifier la position du coffre (seulement si braquable)
    if supermarket.canRob then
        StaffMenu.EditSuperMarket.Button(":lock: POSITION COFFRE", supermarket.safePos and "Définie" or "Non définie", nil, "arrow", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            supermarket.safePos = {x = pos.x, y = pos.y, z = pos.z, h = heading}
            TriggerServerEvent("core:supermarket:updateSupermarket", supermarket.id, "safePos", supermarket.safePos)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Position du coffre mise à jour (direction enregistrée)."
          })
            StaffMenu.EditSuperMarket.refresh()
        end)
    end

    StaffMenu.EditSuperMarket.Separator("DANGER")

    StaffMenu.EditSuperMarket.Button(":trash: SUPPRIMER", "Supprimer cette supérette", nil, nil, false, function()
        -- Double clic pour confirmer la suppression
        if not supermarket.confirmDelete then
            supermarket.confirmDelete = true
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Cliquez à nouveau pour confirmer la suppression."
          })
            -- Reset après 5 secondes
            SetTimeout(5000, function()
                supermarket.confirmDelete = false
            end)
        else
            -- Suppression confirmée
            TriggerServerEvent("core:supermarket:deleteSupermarket", supermarket.id)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Supérette supprimée."
          })
            StaffMenu.EditSuperMarket.close()
        end
    end)
end

-- Supermarket Settings Menu
function StaffMenu.BuildSupermarketSettings()
    -- Get current settings from server
    local settings = TriggerServerCallback("core:supermarket:getSettings") or {}

    StaffMenu.SupermarketSettings.Separator("LIMITES")

    StaffMenu.SupermarketSettings.Button(":clock: COOLDOWN GLOBAL", (settings.globalCooldown or 120) .. " minutes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown global entre braquages (minutes)", tostring((settings.globalCooldown or 120)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "globalCooldown", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Cooldown global mis à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)

    StaffMenu.SupermarketSettings.Button(":user: BRAQUAGES PAR JOUR", (settings.maxRobberiesPerDay or 2) .. " par joueur", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre max de braquages par joueur par 24h", tostring((settings.maxRobberiesPerDay or 2)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "maxRobberiesPerDay", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Limite de braquages par jour mise à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)

    StaffMenu.SupermarketSettings.Separator("RÉCOMPENSES")

    StaffMenu.SupermarketSettings.Button(":money: APU MIN", VFW.Math.FormatMoney(settings.apuRewardMin or 500), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Récompense minimum APU", tostring((settings.apuRewardMin or 500)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "apuRewardMin", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Récompense APU min mise à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)

    StaffMenu.SupermarketSettings.Button(":money: APU MAX", VFW.Math.FormatMoney(settings.apuRewardMax or 1500), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Récompense maximum APU", tostring((settings.apuRewardMax or 1500)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "apuRewardMax", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Récompense APU max mise à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)

    StaffMenu.SupermarketSettings.Button(":lock: COFFRE MIN", VFW.Math.FormatMoney(settings.safeRewardMin or 2000), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Récompense minimum coffre", tostring((settings.safeRewardMin or 2000)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "safeRewardMin", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Récompense coffre min mise à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)

    StaffMenu.SupermarketSettings.Button(":lock: COFFRE MAX", VFW.Math.FormatMoney(settings.safeRewardMax or 5000), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Récompense maximum coffre", tostring((settings.safeRewardMax or 5000)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "safeRewardMax", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Récompense coffre max mise à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)

    StaffMenu.SupermarketSettings.Separator("AUTRES")

    StaffMenu.SupermarketSettings.Button(":police: POLICE REQUISE", (settings.minPoliceRequired or 2) .. " policiers", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de policiers", tostring((settings.minPoliceRequired or 2)))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateSettings", "minPoliceRequired", tonumber(input))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Nombre de policiers requis mis à jour."
          })
            StaffMenu.SupermarketSettings.refresh()
        end
    end)
end

-- Supermarket Catalog Menu (Global items for all LTD stores)
function StaffMenu.BuildSupermarketCatalogMenu()
    StaffMenu.SupermarketCatalog.Separator("CATALOGUE GLOBAL LTD")

    -- Get items from server
    local items = TriggerServerCallback("core:supermarket:getGlobalItemsForBuilder") or {}

    if #items == 0 then
        StaffMenu.SupermarketCatalog.Button("Aucun item dans le catalogue", "Ajoutez des items ci-dessous", nil, nil, true, function() end)
    else
        for _, item in ipairs(items) do
            local categoryIcon = ":cart:"
          local categoryLabel = "Tous"
          if item.category == "nourriture" or item.category == "food" then
                categoryIcon = ":cart:"
              categoryLabel = "Nourriture"
          elseif item.category == "divers" or item.category == "drinks" or item.category == "other" then
                categoryIcon = ":box:"
              categoryLabel = "Divers"
          elseif item.category == "tous" then
                categoryIcon = ":cart:"
              categoryLabel = "Tous"
          end

            StaffMenu.SupermarketCatalog.Button(
                categoryIcon .. " " .. item.label,
                VFW.Math.FormatMoney(item.price) .. " | " .. categoryLabel,
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.selectedCatalogItem = item
                end,
                StaffMenu.EditCatalogItem
            )
        end
    end

    StaffMenu.SupermarketCatalog.Separator("ACTIONS")

    StaffMenu.SupermarketCatalog.Button(":plus: AJOUTER UN ITEM", "Ajouter un nouvel item au catalogue", nil, "arrow", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: bread, water, phone)", "")
        if itemName and itemName ~= "" then
            local price = VFW.Nui.KeyboardInput(true, "Prix de vente (" .. LOCALE.currencySymbol .. ")", "10")
            if price and tonumber(price) then
                local category = VFW.Nui.KeyboardInput(true, "Catégorie (tous, nourriture, divers) - vide = tous", "")
                if not category or category == "" then
                    category = "tous"
              end
                TriggerServerEvent("core:supermarket:addGlobalItem", itemName, tonumber(price), category)
                Wait(500)
                StaffMenu.SupermarketCatalog.refresh()
            end
        end
    end)

    StaffMenu.SupermarketCatalog.Button(":refresh: RAFRAÎCHIR", "Recharger le catalogue", nil, "arrow", false, function()
        StaffMenu.SupermarketCatalog.refresh()
    end)
end

-- Edit Catalog Item Menu
function StaffMenu.BuildEditCatalogItemMenu()
    if not StaffMenu.selectedCatalogItem then
        StaffMenu.EditCatalogItem.Button("Erreur: Aucun item sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local item = StaffMenu.selectedCatalogItem

    StaffMenu.EditCatalogItem.Separator("ÉDITION: " .. item.label)

    StaffMenu.EditCatalogItem.Button(":money: MODIFIER LE PRIX", VFW.Math.FormatMoney(item.price), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau prix (" .. LOCALE.currencySymbol .. ")", tostring(item.price))
        if input and tonumber(input) then
            TriggerServerEvent("core:supermarket:updateGlobalItem", item.name, tonumber(input), item.category, item.description)
            item.price = tonumber(input)
            Wait(300)
            StaffMenu.EditCatalogItem.refresh()
        end
    end)

    local categoryLabel = ":cart: Tous"
  if item.category == "nourriture" or item.category == "food" then
        categoryLabel = ":cart: Nourriture"
  elseif item.category == "divers" or item.category == "drinks" or item.category == "other" then
        categoryLabel = ":box: Divers"
  end
    StaffMenu.EditCatalogItem.Button(":folder: CATÉGORIE", categoryLabel, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Catégorie (tous, nourriture, divers)", item.category)
        if input and (input == "tous" or input == "nourriture" or input == "divers") then
            TriggerServerEvent("core:supermarket:updateGlobalItem", item.name, item.price, input, item.description)
            item.category = input
            Wait(300)
            StaffMenu.EditCatalogItem.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Cette catégorie n'est pas valide. Utilisez: tous, nourriture ou divers."
          })
        end
    end)

    local descLabel = item.description and item.description ~= "" and item.description or "Non définie"
  StaffMenu.EditCatalogItem.Button(":edit: DESCRIPTION", descLabel, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Description (max 255 caractères)", item.description or "")
        if input then
            TriggerServerEvent("core:supermarket:updateGlobalItem", item.name, item.price, item.category, input)
            item.description = input
            Wait(300)
            StaffMenu.EditCatalogItem.refresh()
        end
    end)

    StaffMenu.EditCatalogItem.Separator("DANGER")

    StaffMenu.EditCatalogItem.Button(":trash: RETIRER DU CATALOGUE", "Supprimer cet item", nil, nil, false, function()
        if not item.confirmDelete then
            item.confirmDelete = true
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Cliquez à nouveau pour confirmer la suppression."
          })
            SetTimeout(3000, function()
                if item then item.confirmDelete = false end
            end)
        else
            TriggerServerEvent("core:supermarket:removeGlobalItem", item.name)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Item retiré du catalogue."
          })
            StaffMenu.EditCatalogItem.close()
        end
    end)
end

-- Whitening Builder Menu (Point-based outdoor system)
local editingWhiteningPoint = nil -- Currently editing point data

function StaffMenu.BuildWhiteningMenu()
    StaffMenu.builderWhitening.Separator("BLANCHIMENT D'ARGENT")

    StaffMenu.builderWhitening.Button(":plus: CRÉER UN POINT", "Ajouter un nouveau point de traitement", nil, "arrow", false, function()
        VFW.Nui.Focus(true)
        local name = VFW.Nui.KeyboardInput(true, "Nom du point de traitement")
        VFW.Nui.Focus(false)

        if name and name ~= "" then
            local playerPed = PlayerPedId()
            local pos = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)

            TriggerServerEvent('core:whitening:createPoint', {
                name = name,
                pos = {
                    x = math.floor(pos.x * 100) / 100,
                    y = math.floor(pos.y * 100) / 100,
                    z = math.floor(pos.z * 100) / 100
                },
                groupRestriction = nil,
                active = true
            })
            Wait(200)
            StaffMenu.builderWhitening.refresh()
        end
    end)

    StaffMenu.builderWhitening.Button(":report: GÉRER LES POINTS", "Liste et gestion des points", nil, "chevron", false, function()
    end, StaffMenu.ConfigWhitening)

    StaffMenu.builderWhitening.Button(":wrench: PARAMÈTRES GLOBAUX", "Montant max, frais, délai, cooldown", nil, "chevron", false, function()
    end, StaffMenu.WhiteningSettings)

    StaffMenu.builderWhitening.Separator("ACTIONS")

    StaffMenu.builderWhitening.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge la config depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:whitening:reloadFromDatabase')
        Wait(100)
        StaffMenu.builderWhitening.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Rechargement en cours."
      })
    end)

    StaffMenu.builderWhitening.Button(":clock: RESET COOLDOWNS", "Réinitialise tous les cooldowns de blanchiment", nil, "arrow", false, function()
        TriggerServerEvent('core:whitening:resetCooldowns')
        Wait(100)
        StaffMenu.builderWhitening.refresh()
    end)
end

-- List and manage whitening points
function StaffMenu.BuildConfigWhiteningMenu()
    StaffMenu.ConfigWhitening.ClearItems()

    local points = TriggerServerCallback("core:whitening:getPoints") or {}

    StaffMenu.ConfigWhitening.Separator("POINTS DE TRAITEMENT")

    local count = 0
    for pointId, point in pairs(points) do
        count = count + 1
        local status = point.active and "Actif" or "Désactivé"
      local restriction = point.groupRestriction and point.groupRestriction ~= "" and (" [" .. point.groupRestriction .. "]") or " [Tous]"

      StaffMenu.ConfigWhitening.Button(
            point.name or ("Point #" .. pointId),
            status .. restriction,
            nil, "chevron", false,
            function()
                editingWhiteningPoint = point
            end,
            StaffMenu.EditWhiteningPoint
        )
    end

    if count == 0 then
        StaffMenu.ConfigWhitening.Button("Aucun point", "Créez un point depuis le menu principal", nil, "chevron", false, function() end)
    end
end

-- Edit a specific whitening point
function StaffMenu.BuildEditWhiteningPointMenu()
    StaffMenu.EditWhiteningPoint.ClearItems()

    if not editingWhiteningPoint then return end
    local point = editingWhiteningPoint

    StaffMenu.EditWhiteningPoint.Separator("MODIFIER: " .. (point.name or "Point"))

    StaffMenu.EditWhiteningPoint.Button(":edit: NOM", point.name or "Non défini", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Nom du point", point.name or "")
        VFW.Nui.Focus(false)

        if input and input ~= "" then
            point.name = input
            TriggerServerEvent('core:whitening:updatePoint', point)
            Wait(100)
            StaffMenu.EditWhiteningPoint.refresh()
        end
    end)

    StaffMenu.EditWhiteningPoint.Button(":pin: POSITION", "Définir à votre position actuelle", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        point.pos = {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100,
            h = math.floor(heading * 100) / 100
        }
        TriggerServerEvent('core:whitening:updatePoint', point)
        Wait(100)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Position mise à jour." })
        StaffMenu.EditWhiteningPoint.refresh()
    end)

    StaffMenu.EditWhiteningPoint.Button(":lock: RESTRICTION GROUPE", point.groupRestriction and point.groupRestriction ~= "" and point.groupRestriction or "Aucune (tous)", nil, "chevron", false, function()
        StaffMenu.data.editingWhiteningPointRef = point
    end, StaffMenu.WhiteningGroupSelect)

    StaffMenu.EditWhiteningPoint.Button(point.active and ":dot-green: ACTIF" or ":dot-red: DÉSACTIVÉ", "Cliquez pour basculer", nil, "arrow", false, function()
        point.active = not point.active
        TriggerServerEvent('core:whitening:updatePoint', point)
        Wait(100)
        StaffMenu.EditWhiteningPoint.refresh()
    end)

    StaffMenu.EditWhiteningPoint.Button(":pin: SE TÉLÉPORTER", "Aller à ce point", nil, "arrow", false, function()
        if point.pos then
            SetEntityCoords(PlayerPedId(), point.pos.x, point.pos.y, point.pos.z, false, false, false, true)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Téléporté au point." })
        end
    end)

    -- Overrides par point (vide = utilise le paramètre global)
    StaffMenu.EditWhiteningPoint.Separator("OVERRIDES (vide = global)")

    local ov = point.overrides or {}
    local globalSettings = TriggerServerCallback("core:whitening:getSettings") or {}

    local overrideFields = {
        { key = "maxDirtyMoney", icon = ":money:", label = "Montant max", suffix = LOCALE.currencySymbol, global = globalSettings.maxDirtyMoney or "50000", inputLabel = "Montant max (vide = global)" },
        { key = "feePercent", icon = ":money:", label = "Frais", suffix = "%", global = globalSettings.feePercent or "20", inputLabel = "Frais % (vide = global)" },
        { key = "timerSeconds", icon = ":clock:", label = "Durée", suffix = "s", global = globalSettings.timerSeconds or "300", inputLabel = "Durée en secondes (vide = global)" },
        { key = "playerCooldownHours", icon = ":clock:", label = "Cooldown", suffix = "h", global = globalSettings.playerCooldownHours or "24", inputLabel = "Cooldown en heures (vide = global)" },
    }

    for _, field in ipairs(overrideFields) do
        local currentVal = ov[field.key]
        local displayVal = currentVal and (tostring(currentVal) .. field.suffix) or ("Global (" .. tostring(field.global) .. field.suffix .. ")")

        StaffMenu.EditWhiteningPoint.Button(field.icon .. " " .. field.label, displayVal, nil, "chevron", false, function()
            VFW.Nui.Focus(true)
            local input = VFW.Nui.KeyboardInput(true, field.inputLabel, currentVal and tostring(currentVal) or "")
            VFW.Nui.Focus(false)

            if input == nil then return end
            if not point.overrides then point.overrides = {} end

            if input == "" then
                point.overrides[field.key] = nil
            else
                local num = tonumber(input)
                if not num then return end
                point.overrides[field.key] = num
            end

            TriggerServerEvent('core:whitening:updatePoint', point)
            Wait(100)
            StaffMenu.EditWhiteningPoint.refresh()
        end)
    end

    StaffMenu.EditWhiteningPoint.Separator("DANGER")

    StaffMenu.EditWhiteningPoint.Button(":trash: SUPPRIMER", "Supprimer ce point définitivement", nil, "arrow", false, function()
        TriggerServerEvent('core:whitening:deletePoint', point.id)
        editingWhiteningPoint = nil
        Wait(200)
        StaffMenu.EditWhiteningPoint.close()
        StaffMenu.EditWhiteningPoint.parent.open()
    end)
end

function StaffMenu.BuildWhiteningGroupSelectMenu()
    StaffMenu.WhiteningGroupSelect.ClearItems()

    local point = StaffMenu.data.editingWhiteningPointRef
    if not point then return end

    local factions = StaffMenu.data.factionsList or TriggerServerCallback("core:staff:getOrganizations") or {}
    StaffMenu.data.factionsList = factions

    -- Option pour retirer la restriction
    StaffMenu.WhiteningGroupSelect.Button(":x: AUCUNE (tous)", "Accessible à tous les joueurs", nil, "arrow", point.groupRestriction == nil or point.groupRestriction == "", function()
        point.groupRestriction = nil
        TriggerServerEvent('core:whitening:updatePoint', point)
        Wait(100)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Accessible à tous." })
        StaffMenu.WhiteningGroupSelect.close()
        StaffMenu.WhiteningGroupSelect.parent.open()
    end)

    StaffMenu.WhiteningGroupSelect.Separator("FACTIONS")

    -- Trier par label
    local sorted = {}
    for _, f in pairs(factions) do
        sorted[#sorted + 1] = f
    end
    table.sort(sorted, function(a, b) return (a.label or a.name) < (b.label or b.name) end)

    for _, f in ipairs(sorted) do
        local isSelected = point.groupRestriction == f.name
        StaffMenu.WhiteningGroupSelect.Button(
            (isSelected and ":check: " or "") .. (f.label or f.name),
            f.name,
            nil,
            "arrow",
            false,
            function()
                point.groupRestriction = f.name
                TriggerServerEvent('core:whitening:updatePoint', point)
                Wait(100)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Restreint à : " .. (f.label or f.name) })
                StaffMenu.WhiteningGroupSelect.close()
                StaffMenu.WhiteningGroupSelect.parent.open()
            end
        )
    end
end

local jewelryData = {
    computerPos = nil,
    displayCases = {}
}

local selectedVitrineIndex = nil

-- Modèles de vitrines bijouterie - MAPPING CUSTOM cfx-fm-jewelry
-- Structure: base (intact) → rob (après braquage)
-- Effet visuel: particules "scr_jewelheist/scr_jewel_cab_smash" + son "Glass_Smash"
local JEWELRY_VITRINE_MODELS = {
    -- Grandes vitrines comptoir (mapping custom cfx-fm-jewelry)
    { start = "fm_jewelry_cab_base_01", finish = "fm_jewelry_cab_rob_01", label = "Comptoir 1" },
    { start = "fm_jewelry_cab_base_02", finish = "fm_jewelry_cab_rob_02", label = "Comptoir 2" },
    { start = "fm_jewelry_cab_base_03", finish = "fm_jewelry_cab_rob_03", label = "Comptoir 3" },
    { start = "fm_jewelry_cab_base_04", finish = "fm_jewelry_cab_rob_04", label = "Comptoir 4" },
    -- Petites vitrines
    { start = "fm_jewelry_small_cab_base_01", finish = "fm_jewelry_small_cab_rob_01", label = "Petite 1" },
    { start = "fm_jewelry_small_cab_base_02", finish = "fm_jewelry_small_cab_rob_02", label = "Petite 2" },
    -- Vitrines murales
    { start = "fm_jewelry_wal_cab_base_01", finish = "fm_jewelry_wal_cab_rob_01", label = "Murale 1" },
    { start = "fm_jewelry_wal_cab_base_02", finish = "fm_jewelry_wal_cab_rob_02", label = "Murale 2" },
    { start = "fm_jewelry_wal_cab_base_03", finish = "fm_jewelry_wal_cab_rob_03", label = "Murale 3" },
}

-- Trouve la vitrine la plus proche du joueur
local function FindClosestJewelryVitrine()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestDist = 999.0
    local closestObj = nil
    local closestModel = nil
    local closestModelData = nil


    for _, modelData in ipairs(JEWELRY_VITRINE_MODELS) do
        local modelHash = GetHashKey(modelData.start)

        -- Essayer avec différents paramètres
        local obj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, modelHash, false, false, false)

        if obj and obj ~= 0 then
            local objCoords = GetEntityCoords(obj)
            local dist = #(playerCoords - objCoords)

            if dist < closestDist then
                closestDist = dist
                closestObj = obj
                closestModel = modelData.start
                closestModelData = modelData
            end
        end
    end

    -- Si rien trouvé, lister tous les objets proches pour debug
    if not closestObj then
        local handle, obj = FindFirstObject()
        local success = true
        local count = 0

        repeat
            local objCoords = GetEntityCoords(obj)
            local dist = #(playerCoords - objCoords)

            if dist < 5.0 then
                local model = GetEntityModel(obj)
                    --model, dist, objCoords.x, objCoords.y, objCoords.z))
                count = count + 1
            end

            success, obj = FindNextObject(handle)
        until not success or count > 20

        EndFindObject(handle)
    end

    return closestObj, closestModel, closestModelData, closestDist
end

-- Whitening Settings Menu (new point-based system)
function StaffMenu.BuildWhiteningSettings()
    StaffMenu.WhiteningSettings.ClearItems()

    local settings = TriggerServerCallback("core:whitening:getSettings") or {}

    StaffMenu.WhiteningSettings.Separator("PARAMÈTRES GLOBAUX")

    StaffMenu.WhiteningSettings.Button(":money: MONTANT MAX D'ARGENT SALE", VFW.Math.FormatMoney(settings.maxDirtyMoney or 50000), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant maximum d'argent sale", tostring(settings.maxDirtyMoney or 50000))
        if input and tonumber(input) then
            TriggerServerEvent("core:whitening:updateSettings", "maxDirtyMoney", tonumber(input))
            Wait(100)
            StaffMenu.WhiteningSettings.refresh()
        end
    end)

    StaffMenu.WhiteningSettings.Button(":money: FRAIS DE BLANCHIMENT", (settings.feePercent or 20) .. "%", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Pourcentage de frais (0-100)", tostring(settings.feePercent or 20))
        if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 100 then
            TriggerServerEvent("core:whitening:updateSettings", "feePercent", tonumber(input))
            Wait(100)
            StaffMenu.WhiteningSettings.refresh()
        end
    end)

    StaffMenu.WhiteningSettings.Button(":clock: DURÉE DU BLANCHIMENT", (settings.timerSeconds or 300) .. " secondes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée du blanchiment (secondes)", tostring(settings.timerSeconds or 300))
        if input and tonumber(input) and tonumber(input) > 0 then
            TriggerServerEvent("core:whitening:updateSettings", "timerSeconds", tonumber(input))
            Wait(100)
            StaffMenu.WhiteningSettings.refresh()
        end
    end)

    StaffMenu.WhiteningSettings.Separator("COOLDOWNS")

    StaffMenu.WhiteningSettings.Button(":clock: COOLDOWN JOUEUR", (settings.playerCooldownHours or 24) .. " heures", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown par joueur (heures)", tostring(settings.playerCooldownHours or 24))
        if input and tonumber(input) and tonumber(input) >= 0 then
            TriggerServerEvent("core:whitening:updateSettings", "playerCooldownHours", tonumber(input))
            Wait(100)
            StaffMenu.WhiteningSettings.refresh()
        end
    end)
end

local blackmarketItemData = {
    name = "",
    price = 0,
    category = "",
    maxQuantity = 100,
    marketId = nil
}

-- Black Market Builder Menu
function StaffMenu.BuildBlackmarketMenu()
    StaffMenu.builderBlackmarket.Button(":plus: CRÉER UN BLACK MARKET", "Ajouter un nouveau black market", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local name = VFW.Nui.KeyboardInput(true, "Nom du black market")
        VFW.Nui.Focus(false)

        if name and name ~= "" then
            local pos = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())

            local position = {
                x = math.floor(pos.x * 100) / 100,
                y = math.floor(pos.y * 100) / 100,
                z = math.floor((pos.z - 1.0) * 100) / 100,
                h = math.floor(heading * 100) / 100
            }

            TriggerServerEvent('core:blackmarket:createLocation', name, position)
            Wait(100)
            StaffMenu.builderBlackmarket.refresh()
        end
    end)


    StaffMenu.builderBlackmarket.Button(":report: GÉRER LES BLACK MARKETS", "Liste et gestion", nil, "chevron", false, function()
    end, StaffMenu.ManageBlackmarkets)

    StaffMenu.builderBlackmarket.Button(":globe: ITEMS GLOBAUX", "Items disponibles dans tous les black markets", nil, "chevron", false, function()
    end, StaffMenu.ManageGlobalItems)

    StaffMenu.builderBlackmarket.Button(":pin: SE TP AU PLUS PROCHE", "Téléportation au black market le plus proche", nil, "arrow", false, function()
        local locations = TriggerServerCallback("core:blackmarket:getLocations") or {}
        local playerPos = GetEntityCoords(PlayerPedId())
        local closestMarket = nil
        local closestDistance = math.huge

        for _, market in pairs(locations) do
            if market.active then
                local marketPos = vector3(market.position.x, market.position.y, market.position.z)
                local distance = #(playerPos - marketPos)
                if distance < closestDistance then
                    closestDistance = distance
                    closestMarket = market
                end
            end
        end

        if closestMarket then
            SetEntityCoords(PlayerPedId(), closestMarket.position.x, closestMarket.position.y, closestMarket.position.z, false, false, false, true)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Téléporté au black market : " .. closestMarket.name .. "."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Aucun black market actif trouvé."
          })
        end
    end)
end

--- .BuildAddBlackmarketItemMenu
-- Edit Black Market Item Menu
function StaffMenu.BuildEditBlackmarketItemMenu()
    local data = StaffMenu.EditBlackmarketItem.data
    if not data or not data.item then return end

    local item = data.item
    local marketId = data.marketId
    local label = data.label

    StaffMenu.EditBlackmarketItem.Separator("INFORMATIONS")

    StaffMenu.EditBlackmarketItem.Button(":box: ITEM: " .. label, item.item_name, nil, nil, false)

    StaffMenu.EditBlackmarketItem.Separator("MODIFICATION")

    -- Modifier le prix
    StaffMenu.EditBlackmarketItem.Button(":money: PRIX ACTUEL", VFW.Math.FormatMoney(item.price), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau prix (nombre entier)", tostring(item.price))
        if input then
            local newPrice = tonumber(input)
            if newPrice and newPrice > 0 then
                item.price = newPrice
                TriggerServerEvent('core:blackmarket:updateItemPrice', item.id, newPrice)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Prix modifié."
              })
                StaffMenu.EditBlackmarketItem.refresh()
                StaffMenu.EditBlackmarket.refresh()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                    message = "Ce prix n'est pas valide."
              })
            end
        end
    end)

    -- Modifier le type de transaction
    local transactionTypes = {"buy", "sell", "both"}
    local currentTypeIndex = 1
    for i, t in ipairs(transactionTypes) do
        if t == item.transaction_type then
            currentTypeIndex = i
            break
        end
    end

    StaffMenu.EditBlackmarketItem.List(":refresh: TYPE DE TRANSACTION", nil, false, transactionTypes, currentTypeIndex, function(index)
        local newType = transactionTypes[index]
        TriggerServerEvent('core:blackmarket:updateItemType', item.id, newType)
        item.transaction_type = newType
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Type de transaction modifié."
      })
        StaffMenu.EditBlackmarket.refresh()
    end)

    -- Modifier la catégorie
    StaffMenu.EditBlackmarketItem.Button(":tag: CATÉGORIE", item.category or "general", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle catégorie", item.category or "")
        if input and input ~= "" then
            item.category = input
            TriggerServerEvent('core:blackmarket:updateItemCategory', item.id, input)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Catégorie modifiée."
          })
            StaffMenu.EditBlackmarketItem.refresh()
            StaffMenu.EditBlackmarket.refresh()
        end
    end)

    -- Modifier la quantité max par commande
    local currentMax = tonumber(item.max_quantity) or 100
    StaffMenu.EditBlackmarketItem.Button(":chart: QUANTITÉ MAX PAR COMMANDE", tostring(currentMax), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle quantité max", tostring(currentMax))
        local parsed = tonumber(input)
        if parsed and parsed >= 1 then
            local newMax = math.floor(parsed)
            item.max_quantity = newMax
            TriggerServerEvent('core:blackmarket:updateItemMaxQuantity', item.id, newMax)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Quantité max modifiée."
          })
            StaffMenu.EditBlackmarketItem.refresh()
            StaffMenu.EditBlackmarket.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Cette quantité n'est pas valide."
          })
        end
    end)

    -- Activer/Désactiver
    local statusText = item.active == 1 and "Désactiver" or "Activer"
  local statusColor = item.active == 1 and ":dot-red:" or ":dot-green:"
  StaffMenu.EditBlackmarketItem.Button(statusColor .. " " .. statusText, "Changer le statut de l'item", nil, "arrow", false, function()
        TriggerServerEvent('core:blackmarket:toggleItemStatus', item.id)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Statut modifié."
      })
        StaffMenu.EditBlackmarketItem.refresh()
        StaffMenu.EditBlackmarket.refresh()
    end)

    StaffMenu.EditBlackmarketItem.Separator("ACTIONS")

    -- Supprimer l'item
    StaffMenu.EditBlackmarketItem.Button(":trash: SUPPRIMER L'ITEM", "Supprimer définitivement cet item", nil, "arrow", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez CONFIRMER pour supprimer cet item")
        if confirm == "CONFIRMER" then
            TriggerServerEvent('core:blackmarket:deleteItem', item.id)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Item supprimé."
          })
            StaffMenu.EditBlackmarketItem.close()
            StaffMenu.EditBlackmarketItem.parent.open()
        end
    end)
end

function StaffMenu.BuildAddBlackmarketItemMenu()
    if not blackmarketItemData.marketId then
        StaffMenu.AddBlackmarketItem.Button(":x: ERREUR", "Aucun black market sélectionné", nil, "arrow", true, function() end)
        return
    end

    StaffMenu.AddBlackmarketItem.Button(":box: Nom de l'item", "Définir le nom de l'item", blackmarketItemData.name ~= "" and blackmarketItemData.name or "Non défini", "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item", blackmarketItemData.name)
        if itemName and itemName ~= "" then
            blackmarketItemData.name = itemName
            StaffMenu.AddBlackmarketItem.refresh()
        end
    end)

    StaffMenu.AddBlackmarketItem.Button(":money: Prix", "Définir le prix de l'item", blackmarketItemData.price > 0 and (VFW.Math.FormatMoney(blackmarketItemData.price)) or "Non défini", "chevron", false, function()
        local price = VFW.Nui.KeyboardInput(true, "Prix de l'item", tostring(blackmarketItemData.price))
        if price and tonumber(price) and tonumber(price) > 0 then
            blackmarketItemData.price = tonumber(price)
            StaffMenu.AddBlackmarketItem.refresh()
        end
    end)

    StaffMenu.AddBlackmarketItem.Button(":tag: Catégorie", "Définir la catégorie de l'item", blackmarketItemData.category ~= "" and blackmarketItemData.category or "Non définie", "chevron", false, function()
        local category = VFW.Nui.KeyboardInput(true, "Catégorie de l'item", blackmarketItemData.category)
        if category and category ~= "" then
            blackmarketItemData.category = category
            StaffMenu.AddBlackmarketItem.refresh()
        end
    end)

    StaffMenu.AddBlackmarketItem.Button(":chart: Quantité max par commande", "Limite achetable/vendable par transaction", tostring(blackmarketItemData.maxQuantity or 100), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité max par commande", tostring(blackmarketItemData.maxQuantity or 100))
        local parsed = tonumber(input)
        if parsed and parsed >= 1 then
            blackmarketItemData.maxQuantity = math.floor(parsed)
            StaffMenu.AddBlackmarketItem.refresh()
        end
    end)

    StaffMenu.AddBlackmarketItem.Checkbox(":cart: Achetable", "Les joueurs peuvent acheter cet item", false, blackmarketItemData.canBuy, function(value)
        blackmarketItemData.canBuy = value
        StaffMenu.AddBlackmarketItem.refresh()
    end)

    StaffMenu.AddBlackmarketItem.Checkbox(":money: Vendable", "Les joueurs peuvent vendre cet item", false, blackmarketItemData.canSell, function(value)
        blackmarketItemData.canSell = value
        StaffMenu.AddBlackmarketItem.refresh()
    end)

    StaffMenu.AddBlackmarketItem.Separator(nil)

    StaffMenu.AddBlackmarketItem.Button(":check: Valider l'ajout", "Ajouter l'item a ce black market", nil, "check", false, function()
        -- Validation
        if blackmarketItemData.name == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "Nom d'item requis."
          })
            return
        end

        if blackmarketItemData.price <= 0 then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "Ce prix n'est pas valide."
          })
            return
        end

        if blackmarketItemData.category == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "Catégorie requise."
          })
            return
        end

        if not blackmarketItemData.canBuy and not blackmarketItemData.canSell then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "L'item doit être achetable ou vendable."
          })
            return
        end

        local transactionType = "buy"
      if blackmarketItemData.canBuy and blackmarketItemData.canSell then
            transactionType = "both"
      elseif blackmarketItemData.canSell then
            transactionType = "sell"
      end

        local itemData = {
            item_name = blackmarketItemData.name,
            price = blackmarketItemData.price,
            category = blackmarketItemData.category,
            transaction_type = transactionType,
            max_quantity = blackmarketItemData.maxQuantity or 100
        }

        TriggerServerEvent("core:blackmarket:addItem", blackmarketItemData.marketId, itemData)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode Builder',
            message = "Item ajouté au black market."
      })

        -- Reset data after success
        blackmarketItemData.name = ""
      blackmarketItemData.price = 0
        blackmarketItemData.category = ""
      blackmarketItemData.maxQuantity = 100
        blackmarketItemData.canBuy = true
        blackmarketItemData.canSell = false
        StaffMenu.AddBlackmarketItem.refresh()
    end)
end

-- Black Market Management Menu
function StaffMenu.BuildManageBlackmarketsMenu()
    local locations = TriggerServerCallback("core:blackmarket:getLocations") or {}

    StaffMenu.ManageBlackmarkets.Button(":refresh: ACTUALISER", "Recharger la liste", nil, "arrow", false, function()
        StaffMenu.ManageBlackmarkets.refresh()
    end)

    StaffMenu.ManageBlackmarkets.Separator("BLACK MARKETS")

    for marketId, market in pairs(locations) do
        local statusIcon = market.active and ":dot-green:" or ":dot-red:"
      local statusText = market.active and "Actif" or "Inactif"

      StaffMenu.ManageBlackmarkets.Button(statusIcon .. " " .. market.name, statusText, nil, "chevron", false, function()
            StaffMenu.EditBlackmarket.data = {marketId = marketId, market = market}
        end, StaffMenu.EditBlackmarket)
    end
end

-- Edit Black Market Menu
function StaffMenu.BuildEditBlackmarketMenu()
    local data = StaffMenu.EditBlackmarket.data
    local marketId = data.marketId
    local market = data.market

    StaffMenu.EditBlackmarket.Separator("ITEMS")

    StaffMenu.EditBlackmarket.Button(":plus: AJOUTER ITEM", "Ajouter un nouvel item au blackmarket", nil, "chevron", false, function()
        -- Reset data when opening submenu and set market context
        blackmarketItemData.name = ""
      blackmarketItemData.price = 0
        blackmarketItemData.category = ""
      blackmarketItemData.maxQuantity = 100
        blackmarketItemData.canBuy = true
        blackmarketItemData.canSell = false
        blackmarketItemData.marketId = marketId
    end, StaffMenu.AddBlackmarketItem)

    StaffMenu.EditBlackmarket.Separator("ITEMS EXISTANTS")

    local items = TriggerServerCallback("core:blackmarket:getItems", marketId) or {}
    for _, item in ipairs(items) do
        -- Récupérer le label depuis le framework
        local itemInfo = VFW.Items[item.item_name]
        local label = itemInfo and itemInfo.label or item.item_name
        -- Capture locale des variables pour la closure
        local capturedItem = item
        local capturedLabel = label
        local capturedMarketId = marketId
        local isGlobal = item.market_id == nil
        local displayLabel = isGlobal and (":globe: " .. label) or (":cart: " .. label)
        local description = "Prix: " .. VFW.Math.FormatMoney(item.price) .. " | Type: " .. item.transaction_type
        if isGlobal then
            description = description .. " | GLOBAL"
      end
        StaffMenu.EditBlackmarket.Button(displayLabel, description, nil, "chevron", false, function()
            StaffMenu.EditBlackmarketItem.data = {
                marketId = capturedMarketId,
                item = capturedItem,
                label = capturedLabel
            }
        end, StaffMenu.EditBlackmarketItem)
    end

    StaffMenu.EditBlackmarket.Separator("LIVRAISONS")

    StaffMenu.EditBlackmarket.Button(":box: POINTS DE LIVRAISON", "Gérer les points de livraison", nil, "chevron", false, function()
        StaffMenu.ManageDeliveryPoints.data = { marketId = marketId, market = market }
    end, StaffMenu.ManageDeliveryPoints)

    StaffMenu.EditBlackmarket.Separator("GESTION")

    StaffMenu.EditBlackmarket.Button(":pin: MODIFIER POSITION", "Définir nouvelle position", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())

        local position = {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor((pos.z - 1.0) * 100) / 100,
            h = math.floor(heading * 100) / 100
        }

        TriggerServerEvent('core:blackmarket:updateLocation', marketId, position)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position mise à jour."
      })
        Wait(100)
        StaffMenu.EditBlackmarket.refresh()
    end)

    StaffMenu.EditBlackmarket.Button(":pin: SE TP ICI", "Téléportation à ce black market", nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), market.position.x, market.position.y, market.position.z, false, false, false, true)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Téléporté au black market."
      })
    end)

    local statusAction = market.active and "DÉSACTIVER" or "ACTIVER"
  local statusIcon = market.active and ":dot-red:" or ":dot-green:"

  StaffMenu.EditBlackmarket.Button(statusIcon .. " " .. statusAction, "Changer le statut", nil, "arrow", false, function()
        TriggerServerEvent('core:blackmarket:toggleStatus', marketId)
        Wait(100)
        StaffMenu.EditBlackmarket.refresh()
    end)

    StaffMenu.EditBlackmarket.Button(":trash: SUPPRIMER", "Supprimer ce black market", nil, "arrow", false, function()
        TriggerServerEvent('core:blackmarket:deleteLocation', marketId)
        Wait(100)
        StaffMenu.EditBlackmarket.close()
        StaffMenu.EditBlackmarket.parent.open()
    end)
end

-- Global Items Data
local globalItemData = {
    name = "",
    price = 0,
    category = "",
    maxQuantity = 100,
    canBuy = true,
    canSell = false
}

-- Manage Global Items Menu (items available in ALL black markets)
function StaffMenu.BuildManageGlobalItemsMenu()
    StaffMenu.ManageGlobalItems.Button(":plus: AJOUTER UN ITEM GLOBAL", "Item disponible dans tous les black markets", nil, "chevron", false, function()
        -- Reset data when opening submenu
        globalItemData.name = ""
      globalItemData.price = 0
        globalItemData.category = ""
      globalItemData.maxQuantity = 100
        globalItemData.canBuy = true
        globalItemData.canSell = false
    end, StaffMenu.AddGlobalItem)

    StaffMenu.ManageGlobalItems.Button(":refresh: ACTUALISER", "Recharger la liste", nil, "arrow", false, function()
        StaffMenu.ManageGlobalItems.refresh()
    end)

    StaffMenu.ManageGlobalItems.Separator("ITEMS GLOBAUX")

    local items = TriggerServerCallback("core:blackmarket:getGlobalItems") or {}

    if #items == 0 then
        StaffMenu.ManageGlobalItems.Textbox("Aucun item global configuré", nil)
    else
        for _, item in ipairs(items) do
            local itemInfo = VFW.Items[item.item_name]
            local label = itemInfo and itemInfo.label or item.item_name
            local statusIcon = item.active == 1 and ":dot-green:" or ":dot-red:"

          StaffMenu.ManageGlobalItems.Button(statusIcon .. " " .. label, "Prix: " .. VFW.Math.FormatMoney(item.price) .. " | Type: " .. item.transaction_type .. " | Cat: " .. (item.category or "general"), nil, "chevron", false, function()
                StaffMenu.EditGlobalItem.data = {
                    item = item,
                    label = label
                }
            end, StaffMenu.EditGlobalItem)
        end
    end
end

-- Add Global Item Menu
function StaffMenu.BuildAddGlobalItemMenu()
    StaffMenu.AddGlobalItem.Button(":box: Nom de l'item", "Définir le nom de l'item", globalItemData.name ~= "" and globalItemData.name or "Non défini", "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item", globalItemData.name)
        if itemName and itemName ~= "" then
            globalItemData.name = itemName
            StaffMenu.AddGlobalItem.refresh()
        end
    end)

    StaffMenu.AddGlobalItem.Button(":money: Prix", "Définir le prix de l'item", globalItemData.price > 0 and (VFW.Math.FormatMoney(globalItemData.price)) or "Non défini", "chevron", false, function()
        local price = VFW.Nui.KeyboardInput(true, "Prix de l'item", tostring(globalItemData.price))
        if price and tonumber(price) and tonumber(price) > 0 then
            globalItemData.price = tonumber(price)
            StaffMenu.AddGlobalItem.refresh()
        end
    end)

    StaffMenu.AddGlobalItem.Button(":tag: Catégorie", "Définir la catégorie de l'item", globalItemData.category ~= "" and globalItemData.category or "Non définie", "chevron", false, function()
        local category = VFW.Nui.KeyboardInput(true, "Catégorie de l'item", globalItemData.category)
        if category and category ~= "" then
            globalItemData.category = category
            StaffMenu.AddGlobalItem.refresh()
        end
    end)

    StaffMenu.AddGlobalItem.Button(":chart: Quantité max par commande", "Limite achetable/vendable par transaction", tostring(globalItemData.maxQuantity or 100), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité max par commande", tostring(globalItemData.maxQuantity or 100))
        local parsed = tonumber(input)
        if parsed and parsed >= 1 then
            globalItemData.maxQuantity = math.floor(parsed)
            StaffMenu.AddGlobalItem.refresh()
        end
    end)

    StaffMenu.AddGlobalItem.Checkbox(":cart: Achetable", "Les joueurs peuvent acheter cet item", false, globalItemData.canBuy, function(value)
        globalItemData.canBuy = value
        StaffMenu.AddGlobalItem.refresh()
    end)

    StaffMenu.AddGlobalItem.Checkbox(":money: Vendable", "Les joueurs peuvent vendre cet item", false, globalItemData.canSell, function(value)
        globalItemData.canSell = value
        StaffMenu.AddGlobalItem.refresh()
    end)

    StaffMenu.AddGlobalItem.Separator(nil)

    StaffMenu.AddGlobalItem.Button(":check: Valider l'ajout", "Ajouter l'item dans tous les black markets", nil, "check", false, function()
        -- Validation
        if globalItemData.name == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "Nom d'item requis."
          })
            return
        end

        if globalItemData.price <= 0 then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "Ce prix n'est pas valide."
          })
            return
        end

        if globalItemData.category == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "Catégorie requise."
          })
            return
        end

        if not globalItemData.canBuy and not globalItemData.canSell then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Mode Builder',
                message = "L'item doit être achetable ou vendable."
          })
            return
        end

        local transactionType = "buy"
      if globalItemData.canBuy and globalItemData.canSell then
            transactionType = "both"
      elseif globalItemData.canSell then
            transactionType = "sell"
      end

        local itemData = {
            item_name = globalItemData.name,
            price = globalItemData.price,
            category = globalItemData.category,
            transaction_type = transactionType,
            max_quantity = globalItemData.maxQuantity or 100
        }

        TriggerServerEvent("core:blackmarket:addGlobalItem", itemData)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode Builder',
            message = "Item global ajouté (disponible dans tous les black markets)."
      })

        -- Reset data after success
        globalItemData.name = ""
      globalItemData.price = 0
        globalItemData.category = ""
      globalItemData.maxQuantity = 100
        globalItemData.canBuy = true
        globalItemData.canSell = false
        StaffMenu.AddGlobalItem.refresh()
    end)
end

-- Edit Global Item Menu
function StaffMenu.BuildEditGlobalItemMenu()
    local data = StaffMenu.EditGlobalItem.data
    if not data or not data.item then return end

    local item = data.item
    local label = data.label

    StaffMenu.EditGlobalItem.Separator("INFORMATIONS")

    StaffMenu.EditGlobalItem.Button(":box: ITEM: " .. label, item.item_name, nil, nil, false)
    StaffMenu.EditGlobalItem.Textbox(":globe: Item GLOBAL - disponible dans tous les black markets", nil)

    StaffMenu.EditGlobalItem.Separator("MODIFICATION")

    -- Modifier le prix
    StaffMenu.EditGlobalItem.Button(":money: PRIX ACTUEL", VFW.Math.FormatMoney(item.price), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau prix (nombre entier)", tostring(item.price))
        if input then
            local newPrice = tonumber(input)
            if newPrice and newPrice > 0 then
                TriggerServerEvent('core:blackmarket:updateItemPrice', item.id, newPrice)
                item.price = newPrice
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Prix modifié."
              })
                StaffMenu.EditGlobalItem.refresh()
                StaffMenu.ManageGlobalItems.refresh()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                    message = "Ce prix n'est pas valide."
              })
            end
        end
    end)

    -- Modifier le type de transaction
    local transactionTypes = {"buy", "sell", "both"}
    local currentTypeIndex = 1
    for i, t in ipairs(transactionTypes) do
        if t == item.transaction_type then
            currentTypeIndex = i
            break
        end
    end

    StaffMenu.EditGlobalItem.List(":refresh: TYPE DE TRANSACTION", nil, false, transactionTypes, currentTypeIndex, function(index)
        local newType = transactionTypes[index]
        TriggerServerEvent('core:blackmarket:updateItemType', item.id, newType)
        item.transaction_type = newType
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Type de transaction modifié."
      })
        StaffMenu.ManageGlobalItems.refresh()
    end)

    -- Modifier la catégorie
    StaffMenu.EditGlobalItem.Button(":tag: CATÉGORIE", item.category or "general", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle catégorie", item.category or "")
        if input and input ~= "" then
            TriggerServerEvent('core:blackmarket:updateItemCategory', item.id, input)
            item.category = input
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Catégorie modifiée."
          })
            StaffMenu.EditGlobalItem.refresh()
            StaffMenu.ManageGlobalItems.refresh()
        end
    end)

    -- Modifier la quantité max par commande
    local currentGlobalMax = tonumber(item.max_quantity) or 100
    StaffMenu.EditGlobalItem.Button(":chart: QUANTITÉ MAX PAR COMMANDE", tostring(currentGlobalMax), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle quantité max", tostring(currentGlobalMax))
        local parsed = tonumber(input)
        if parsed and parsed >= 1 then
            local newMax = math.floor(parsed)
            item.max_quantity = newMax
            TriggerServerEvent('core:blackmarket:updateItemMaxQuantity', item.id, newMax)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Quantité max modifiée."
          })
            StaffMenu.EditGlobalItem.refresh()
            StaffMenu.ManageGlobalItems.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Cette quantité n'est pas valide."
          })
        end
    end)

    -- Activer/Désactiver
    local statusText = item.active == 1 and "Désactiver" or "Activer"
  local statusColor = item.active == 1 and ":dot-red:" or ":dot-green:"
  StaffMenu.EditGlobalItem.Button(statusColor .. " " .. statusText, "Changer le statut de l'item", nil, "arrow", false, function()
        TriggerServerEvent('core:blackmarket:toggleItemStatus', item.id)
        item.active = item.active == 1 and 0 or 1
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Statut modifié."
      })
        StaffMenu.EditGlobalItem.refresh()
        StaffMenu.ManageGlobalItems.refresh()
    end)

    StaffMenu.EditGlobalItem.Separator("ACTIONS")

    -- Supprimer l'item
    StaffMenu.EditGlobalItem.Button(":trash: SUPPRIMER L'ITEM GLOBAL", "Supprimer définitivement cet item de tous les black markets", nil, "arrow", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez CONFIRMER pour supprimer cet item")
        if confirm == "CONFIRMER" then
            TriggerServerEvent('core:blackmarket:deleteItem', item.id)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Item global supprimé."
          })
            StaffMenu.EditGlobalItem.close()
            StaffMenu.EditGlobalItem.parent.open()
        end
    end)
end

local deliveryPreviewVeh = nil
local deliveryPreviewPed = nil
local deliveryPreviewBox = nil
local deliveryPreviewActive = false

local function CleanupDeliveryPreview()
    deliveryPreviewActive = false
    if deliveryPreviewBox and DoesEntityExist(deliveryPreviewBox) then
        DetachEntity(deliveryPreviewBox, true, true)
        DeleteEntity(deliveryPreviewBox)
    end
    if deliveryPreviewPed and DoesEntityExist(deliveryPreviewPed) then
        DeleteEntity(deliveryPreviewPed)
    end
    if deliveryPreviewVeh and DoesEntityExist(deliveryPreviewVeh) then
        DeleteEntity(deliveryPreviewVeh)
    end
    deliveryPreviewVeh = nil
    deliveryPreviewPed = nil
    deliveryPreviewBox = nil
end

local function SpawnDeliveryPreview(pos, heading)
    CleanupDeliveryPreview()

    local vehModel = joaat("speedo")
    RequestModel(vehModel)
    local t = GetGameTimer()
    while not HasModelLoaded(vehModel) and (GetGameTimer() - t) < 5000 do Wait(10) end
    if not HasModelLoaded(vehModel) then return false end

    local vehHeading = heading + 180.0
    deliveryPreviewVeh = CreateVehicle(vehModel, pos.x, pos.y, pos.z + 1.0, vehHeading, false, false)
    SetEntityAlpha(deliveryPreviewVeh, 200, false)
    SetVehicleColours(deliveryPreviewVeh, 0, 0)
    SetVehicleDoorOpen(deliveryPreviewVeh, 2, false, false)
    SetVehicleDoorOpen(deliveryPreviewVeh, 3, false, false)
    FreezeEntityPosition(deliveryPreviewVeh, true)
    SetEntityInvincible(deliveryPreviewVeh, true)
    SetEntityCollision(deliveryPreviewVeh, false, false)
    SetModelAsNoLongerNeeded(vehModel)

    local pedModel = joaat("s_m_y_dealer_01")
    RequestModel(pedModel)
    t = GetGameTimer()
    while not HasModelLoaded(pedModel) and (GetGameTimer() - t) < 3000 do Wait(10) end
    if not HasModelLoaded(pedModel) then
        deliveryPreviewActive = true
        return true
    end

    local rad = math.rad(vehHeading)
    local pedX = pos.x + math.sin(rad) * 3.5
    local pedY = pos.y - math.cos(rad) * 3.5

    RequestCollisionAtCoord(pedX, pedY, pos.z)
    Wait(100)

    deliveryPreviewPed = CreatePed(26, pedModel, pedX, pedY, pos.z, vehHeading + 180.0, false, false)
    SetEntityAlpha(deliveryPreviewPed, 200, false)
    SetEntityInvincible(deliveryPreviewPed, true)
    SetPedCanRagdoll(deliveryPreviewPed, false)
    SetBlockingOfNonTemporaryEvents(deliveryPreviewPed, true)
    FreezeEntityPosition(deliveryPreviewPed, true)
    SetEntityCollision(deliveryPreviewPed, false, false)
    SetModelAsNoLongerNeeded(pedModel)

    local boxModel = GetHashKey("prop_cs_cardbox_01")
    RequestModel(boxModel)
    t = GetGameTimer()
    while not HasModelLoaded(boxModel) and (GetGameTimer() - t) < 3000 do Wait(10) end
    if HasModelLoaded(boxModel) then
        deliveryPreviewBox = CreateObject(boxModel, 0.0, 0.0, 0.0, false, false, false)
        AttachEntityToEntity(deliveryPreviewBox, deliveryPreviewPed, GetPedBoneIndex(deliveryPreviewPed, 28422),
            -0.05, 0.0, -0.10, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(boxModel)

        RequestAnimDict("anim@heists@box_carry@")
        t = GetGameTimer()
        while not HasAnimDictLoaded("anim@heists@box_carry@") and (GetGameTimer() - t) < 3000 do Wait(10) end
        if HasAnimDictLoaded("anim@heists@box_carry@") then
            TaskPlayAnim(deliveryPreviewPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end

    deliveryPreviewActive = true
    return true
end

function StaffMenu.BuildManageDeliveryPointsMenu()
    local data = StaffMenu.ManageDeliveryPoints.data
    if not data then return end
    local marketId = data.marketId

    StaffMenu.ManageDeliveryPoints.Button("AJOUTER UN POINT", "Preview du Speedo + NPC à votre position", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        local position = {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor((pos.z - 1.0) * 100) / 100,
            h = math.floor(heading * 100) / 100
        }

        StaffMenu.ManageDeliveryPoints.close()
        Wait(300)

        SpawnDeliveryPreview(position, heading)

        while deliveryPreviewActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Confirmer | ~INPUT_CELLPHONE_CANCEL~ Annuler")
            if VFW.Interact.JustPressed(0, 38) then
                CleanupDeliveryPreview()
                TriggerServerEvent('core:blackmarket:createDeliveryPoint', marketId, position)
                Wait(200)
                StaffMenu.ManageDeliveryPoints.open()
                break
            end
            if IsControlJustPressed(0, 177) then
                CleanupDeliveryPreview()
                StaffMenu.ManageDeliveryPoints.open()
                break
            end
        end
    end)

    StaffMenu.ManageDeliveryPoints.Separator("POINTS EXISTANTS")

    local points = TriggerServerCallback("core:blackmarket:getDeliveryPoints", marketId) or {}

    for _, point in ipairs(points) do
        local pos = json.decode(point.position)
        local desc = string.format("X:%.1f Y:%.1f Z:%.1f", pos.x, pos.y, pos.z)

        local capturedPoint = point
        StaffMenu.ManageDeliveryPoints.Button("Point #" .. point.id, desc, nil, "chevron", false, function()
            StaffMenu.EditDeliveryPoint.data = { point = capturedPoint, marketId = marketId }
        end, StaffMenu.EditDeliveryPoint)
    end

    if #points == 0 then
        StaffMenu.ManageDeliveryPoints.Textbox("Aucun point de livraison configure", nil)
    end
end

function StaffMenu.BuildEditDeliveryPointMenu()
    local data = StaffMenu.EditDeliveryPoint.data
    if not data then return end
    local point = data.point
    local marketId = data.marketId
    local pos = json.decode(point.position)

    StaffMenu.EditDeliveryPoint.Separator("POINT #" .. point.id)

    StaffMenu.EditDeliveryPoint.Textbox(string.format("Position: X:%.1f Y:%.1f Z:%.1f", pos.x, pos.y, pos.z), nil)

    StaffMenu.EditDeliveryPoint.Button("PREVIEW", "Voir le Speedo + NPC à ce point", nil, "arrow", false, function()
        StaffMenu.EditDeliveryPoint.close()
        Wait(300)
        SpawnDeliveryPreview(pos, pos.h or 0.0)
        while deliveryPreviewActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CELLPHONE_CANCEL~ Fermer la preview")
            if IsControlJustPressed(0, 177) then
                CleanupDeliveryPreview()
                StaffMenu.EditDeliveryPoint.open()
                break
            end
        end
    end)

    StaffMenu.EditDeliveryPoint.Button("MODIFIER POSITION", "Définir à votre position actuelle avec preview", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        local position = {
            x = math.floor(playerPos.x * 100) / 100,
            y = math.floor(playerPos.y * 100) / 100,
            z = math.floor((playerPos.z - 1.0) * 100) / 100,
            h = math.floor(heading * 100) / 100
        }

        StaffMenu.EditDeliveryPoint.close()
        Wait(300)
        SpawnDeliveryPreview(position, heading)
        while deliveryPreviewActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Confirmer | ~INPUT_CELLPHONE_CANCEL~ Annuler")
            if VFW.Interact.JustPressed(0, 38) then
                CleanupDeliveryPreview()
                TriggerServerEvent('core:blackmarket:updateDeliveryPoint', point.id, position)
                Wait(200)
                StaffMenu.EditDeliveryPoint.open()
                break
            end
            if IsControlJustPressed(0, 177) then
                CleanupDeliveryPreview()
                StaffMenu.EditDeliveryPoint.open()
                break
            end
        end
    end)

    StaffMenu.EditDeliveryPoint.Button("SE TP ICI", "Téléportation à ce point", nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, true)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Téléporté au point de livraison #" .. point.id
        })
    end)

    StaffMenu.EditDeliveryPoint.Button("SUPPRIMER", "Supprimer ce point de livraison", nil, "trash", false, function()
        TriggerServerEvent('core:blackmarket:deleteDeliveryPoint', point.id)
        Wait(200)
        StaffMenu.EditDeliveryPoint.close()
        StaffMenu.EditDeliveryPoint.parent.open()
    end)
end

function StaffMenu.BuildJewelryMenu()
    StaffMenu.builderJewelry.Button(":settings: CONFIGURER LES POSITIONS", "Modifier les positions ordinateur et vitrines", nil, "chevron", false, function()
    end, StaffMenu.ConfigJewelry)

    StaffMenu.builderJewelry.Button(":wrench: PARAMÈTRES GLOBAUX", "Cooldowns, items, etc.", nil, "chevron", false, function()
    end, StaffMenu.JewelrySettings)

    StaffMenu.builderJewelry.Separator("ACTIONS")

    StaffMenu.builderJewelry.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge la config depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:jewelry:reloadFromDatabase')
        Wait(100)
        StaffMenu.builderJewelry.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Rechargement en cours."
      })
    end)

    StaffMenu.builderJewelry.Button(":pin: SE TP À LA BIJOUTERIE", "Téléportation à la bijouterie", nil, "arrow", false, function()
        local config = TriggerServerCallback("core:jewelry:getConfig") or {}
        if config.computerPos then
            SetEntityCoords(PlayerPedId(), config.computerPos.x, config.computerPos.y, config.computerPos.z, false, false, false, true)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Téléporté à la bijouterie."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Position ordinateur non configurée."
          })
        end
    end)

    StaffMenu.builderJewelry.Button(":wrench: RESTAURER VITRINES", "Réparer toutes les vitrines cassées", nil, "arrow", false, function()
        TriggerEvent('core:jewelry:restoreVitrines')
    end)
end

-- Jewelry Configuration Menu
function StaffMenu.BuildConfigJewelryMenu()
    local config = TriggerServerCallback("core:jewelry:getConfig") or {}
    local settings = TriggerServerCallback("core:jewelry:getSettings") or {}

    -- Mettre à jour jewelryData avec la config du serveur
    if config.computerPos then jewelryData.computerPos = config.computerPos end
    if config.displayCases then jewelryData.displayCases = config.displayCases end

    StaffMenu.ConfigJewelry.Button(":save: SAUVEGARDER", "Sauvegarder la configuration", nil, "arrow", false, function()
        if not jewelryData.computerPos then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Position ordinateur non définie."
          })
            return
        end

        if not jewelryData.displayCases or #jewelryData.displayCases == 0 then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Aucune vitrine configurée."
          })
            return
        end

        TriggerServerEvent("core:jewelry:updateConfig", {
            computerPos = jewelryData.computerPos,
            displayCases = jewelryData.displayCases
        })
        Wait(100)
        StaffMenu.ConfigJewelry.refresh()

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Configuration sauvegardée."
      })
    end)

    StaffMenu.ConfigJewelry.Separator("POSITIONS")

    StaffMenu.ConfigJewelry.Button(":monitor: POSITION ORDINATEUR", jewelryData.computerPos and "Définie" or "Non définie", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        jewelryData.computerPos = {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100,
            h = math.floor(heading * 100) / 100
        }

            -- Sauvegarder dans la base de données
            TriggerServerEvent("core:jewelry:updateConfig", {
                computerPos = jewelryData.computerPos,
                displayCases = jewelryData.displayCases
            })

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position ordinateur définie."
      })
        Wait(100)
        StaffMenu.ConfigJewelry.refresh()
    end)

    StaffMenu.ConfigJewelry.Separator("VITRINES (" .. (#jewelryData.displayCases or 0) .. ")")

    -- Bouton principal: Détection automatique de la vitrine la plus proche
    -- Sauvegarde la position de l'admin (où il est) + position de la vitrine pour le model swap
    StaffMenu.ConfigJewelry.Button(":target: AJOUTER VITRINE", "Détecte automatiquement la vitrine la plus proche", nil, "arrow", false, function()
        local closestObj, closestModel, closestModelData, closestDist = FindClosestJewelryVitrine()

        if closestObj and closestModelData then
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local playerHeading = GetEntityHeading(playerPed)
            local vitrinePos = GetEntityCoords(closestObj)

            -- Sauvegarder:
            -- x,y,z = position de l'ADMIN (marker + position joueur)
            -- vitrineX,Y,Z = position de la VITRINE (pour le model swap)
            local newCase = {
                x = math.floor(playerPos.x * 100) / 100,
                y = math.floor(playerPos.y * 100) / 100,
                z = math.floor(playerPos.z * 100) / 100,
                heading = math.floor(playerHeading * 100) / 100,
                vitrineX = math.floor(vitrinePos.x * 100) / 100,
                vitrineY = math.floor(vitrinePos.y * 100) / 100,
                vitrineZ = math.floor(vitrinePos.z * 100) / 100,
                model = closestModelData.start,
                modelFinish = closestModelData.finish,
                id = (#jewelryData.displayCases or 0) + 1
            }

            if not jewelryData.displayCases then
                jewelryData.displayCases = {}
            end

            table.insert(jewelryData.displayCases, newCase)

            TriggerServerEvent("core:jewelry:updateConfig", {
                computerPos = jewelryData.computerPos,
                displayCases = jewelryData.displayCases
            })

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = string.format("Vitrine %s ajoutée à ta position.", closestModelData.label)
            })
            Wait(100)
            StaffMenu.ConfigJewelry.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Aucune vitrine détectée à proximité. Approche-toi d'une vitrine."
          })
        end
    end)

    if jewelryData.displayCases and #jewelryData.displayCases > 0 then
        StaffMenu.ConfigJewelry.Button(":report: LISTE VITRINES", "Gérer les vitrines individuellement", nil, "chevron", false, function()
        end, StaffMenu.VitrinsList)
    end

    if jewelryData.displayCases and #jewelryData.displayCases > 0 then
        StaffMenu.ConfigJewelry.Button(":trash: SUPPRIMER DERNIÈRE VITRINE", "Supprimer la dernière vitrine ajoutée", nil, "arrow", false, function()
            table.remove(jewelryData.displayCases, #jewelryData.displayCases)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Dernière vitrine supprimée."
          })
            StaffMenu.ConfigJewelry.refresh()
        end)

        StaffMenu.ConfigJewelry.Button(":trash: VIDER TOUTES LES VITRINES", "Supprimer toutes les vitrines", nil, "arrow", false, function()
            jewelryData.displayCases = {}

            -- Sauvegarder dans la base de données
            TriggerServerEvent("core:jewelry:updateConfig", {
                computerPos = jewelryData.computerPos,
                displayCases = jewelryData.displayCases
            })

            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Toutes les vitrines supprimées."
          })
            Wait(100)
            StaffMenu.ConfigJewelry.refresh()
        end)
    end
end

-- Vitrines List Menu
function StaffMenu.BuildVitrinesListMenu()
    if not jewelryData.displayCases or #jewelryData.displayCases == 0 then
        StaffMenu.VitrinsList.Button(":x: AUCUNE VITRINE", "Aucune vitrine configurée", nil, "arrow", true, function() end)
        return
    end

    StaffMenu.VitrinsList.Separator("VITRINES (" .. #jewelryData.displayCases .. ")")

    for i, vitrine in ipairs(jewelryData.displayCases) do
        local modelLabel = vitrine.model and vitrine.model:gsub("des_jewel_", ""):gsub("_start", "") or "inconnu"
      local desc = string.format("Modèle: %s", modelLabel)
        StaffMenu.VitrinsList.Button(":dot-orange: VITRINE #" .. i, desc, nil, "chevron", false, function()
            -- Stocker l'index pour le sous-menu
            selectedVitrineIndex = i
        end, StaffMenu.VitrineActions)
    end
end

-- Vitrine Actions Menu
function StaffMenu.BuildVitrineActionsMenu()
    if not selectedVitrineIndex or not jewelryData.displayCases or not jewelryData.displayCases[selectedVitrineIndex] then
        StaffMenu.VitrineActions.Button(":x: ERREUR", "Vitrine introuvable", nil, "arrow", true, function() end)
        return
    end

    local vitrine = jewelryData.displayCases[selectedVitrineIndex]
    local coords = string.format("%.1f, %.1f, %.1f", vitrine.x, vitrine.y, vitrine.z)
    local modelLabel = vitrine.model and vitrine.model:gsub("des_jewel_", ""):gsub("_start", "") or "inconnu"

  StaffMenu.VitrineActions.Separator("VITRINE #" .. selectedVitrineIndex)
    StaffMenu.VitrineActions.Button(":pin: COORDONNÉES", coords, nil, "arrow", true, function() end)
    StaffMenu.VitrineActions.Button(":building: MODÈLE", modelLabel, nil, "arrow", true, function() end)
    if vitrine.heading then
        StaffMenu.VitrineActions.Button(":compass: HEADING", tostring(vitrine.heading) .. "°", nil, "arrow", true, function() end)
    end

    StaffMenu.VitrineActions.Button(":pin: SE TÉLÉPORTER", "Se téléporter à cette vitrine", nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), vitrine.x, vitrine.y, vitrine.z, false, false, false, true)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Téléporté à la vitrine #" .. selectedVitrineIndex .. "."
      })
    end)

    StaffMenu.VitrineActions.Button(":trash: SUPPRIMER", "Supprimer cette vitrine", nil, "arrow", false, function()
        table.remove(jewelryData.displayCases, selectedVitrineIndex)

        -- Sauvegarder dans la base de données
        TriggerServerEvent("core:jewelry:updateConfig", {
            computerPos = jewelryData.computerPos,
            displayCases = jewelryData.displayCases
        })

        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Vitrine #" .. selectedVitrineIndex .. " supprimée."
      })
        Wait(100)
        StaffMenu.VitrineActions.close()
        StaffMenu.VitrinsList.close()
        StaffMenu.ConfigJewelry.refresh()
    end)
end

-- Jewelry Settings Menu
function StaffMenu.BuildJewelrySettingsMenu()
    local settings = TriggerServerCallback("core:jewelry:getSettings") or {}

    StaffMenu.JewelrySettings.Separator("COOLDOWNS")

    StaffMenu.JewelrySettings.Button(":building: COOLDOWN MAGASIN", (settings.storeCooldownHours or 1) .. ((settings.storeCooldownHours or 1) > 1 and " heures" or " heure"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown magasin (heures)", tostring((settings.storeCooldownHours or 1)))
        if input and tonumber(input) and tonumber(input) >= 0.1 then
            TriggerServerEvent("core:jewelry:updateSettings", "storeCooldownHours", tonumber(input))
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Cooldown magasin mis à jour."
          })
        end
    end)

    StaffMenu.JewelrySettings.Button(":user: COOLDOWN JOUEUR", (settings.playerCooldownHours or 48) .. ((settings.playerCooldownHours or 48) > 1 and " heures" or " heure"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown joueur (heures)", tostring((settings.playerCooldownHours or 48)))
        if input and tonumber(input) and tonumber(input) >= 1 then
            TriggerServerEvent("core:jewelry:updateSettings", "playerCooldownHours", tonumber(input))
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Cooldown joueur mis à jour."
          })
        end
    end)

    StaffMenu.JewelrySettings.Button(":refresh: RESET COOLDOWNS", "Réinitialise tous les cooldowns (magasin + joueurs)", nil, "arrow", false, function()
        TriggerServerEvent("core:jewelry:resetAllCooldowns")
        Wait(150)
        StaffMenu.JewelrySettings.refresh()
    end)

    StaffMenu.JewelrySettings.Separator("LOOT")

    StaffMenu.JewelrySettings.Button(":chart: ITEMS MIN PAR VITRINE", (settings.minItemsPerCase or 1), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum d'items par vitrine", tostring((settings.minItemsPerCase or 1)))
        if input and tonumber(input) and tonumber(input) >= 1 and tonumber(input) <= 5 then
            TriggerServerEvent("core:jewelry:updateSettings", "minItemsPerCase", tonumber(input))
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Items minimum mis à jour."
          })
        end
    end)

    StaffMenu.JewelrySettings.Button(":chart: ITEMS MAX PAR VITRINE", (settings.maxItemsPerCase or 3), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre maximum d'items par vitrine", tostring((settings.maxItemsPerCase or 3)))
        if input and tonumber(input) and tonumber(input) >= 1 and tonumber(input) <= 5 then
            TriggerServerEvent("core:jewelry:updateSettings", "maxItemsPerCase", tonumber(input))
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Items maximum mis à jour."
          })
        end
    end)

    StaffMenu.JewelrySettings.Separator("SYSTÈME")

    StaffMenu.JewelrySettings.Button(":police: POLICIERS REQUIS", (settings.minPoliceCount or 2) .. ((settings.minPoliceCount or 2) > 1 and " policiers" or " policier"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de policiers requis", tostring((settings.minPoliceCount or 2)))
        if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 10 then
            TriggerServerEvent("core:jewelry:updateSettings", "minPoliceCount", tonumber(input))
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Nombre de policiers requis mis à jour."
          })
        end
    end)

    StaffMenu.JewelrySettings.Button(":siren: DURÉE BLIP POLICE", math.floor((settings.policeBlipDuration or 600) / 60) .. (math.floor((settings.policeBlipDuration or 600) / 60) > 1 and " minutes" or " minute"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée blip police (minutes)", tostring(math.floor((settings.policeBlipDuration or 600) / 60)))
        if input and tonumber(input) and tonumber(input) >= 1 and tonumber(input) <= 30 then
            TriggerServerEvent("core:jewelry:updateSettings", "policeBlipDuration", tonumber(input) * 60)
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Durée blip police mise à jour."
          })
        end
    end)

    StaffMenu.JewelrySettings.Button(":wrench: ITEM REQUIS", (settings.requiredItem or "jewelry_hacking_device"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item requis", tostring((settings.requiredItem or "jewelry_hacking_device")))
        if input and input ~= "" then
            TriggerServerEvent("core:jewelry:updateSettings", "requiredItem", input)
            Wait(100)
            StaffMenu.JewelrySettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Item requis mis à jour."
          })
        end
    end)
end

-- Variables globales pour la pêche illégale
local currentFishingZone = {
    name = "",
    center = nil,
    radius = 50.0,
    fish = {}
}

local selectedZoneId = nil
local selectedFishIndex = nil

-- Menu principal pêche illégale
function StaffMenu.BuildIllegalFishingMenu()
    StaffMenu.builderIllegalFishing.Separator("PÊCHE ILLÉGALE")

    StaffMenu.builderIllegalFishing.Button(":map: GESTION DES ZONES", "Créer et gérer les zones de pêche", nil, "chevron", false, function()
    end, StaffMenu.ConfigIllegalFishing)

    StaffMenu.builderIllegalFishing.Button(":settings: PARAMÈTRES GLOBAUX", "Modifier les paramètres du système", nil, "chevron", false, function()
    end, StaffMenu.IllegalFishingSettings)

    StaffMenu.builderIllegalFishing.Separator("ACTIONS")

    StaffMenu.builderIllegalFishing.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge la config depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:illegalfishing:reloadFromDatabase')
        Wait(100)
        StaffMenu.builderIllegalFishing.refresh()
    end)
end

-- Menu configuration zones
function StaffMenu.BuildConfigIllegalFishingMenu()
    local zones = TriggerServerCallback("core:illegalfishing:getZones") or {}

    StaffMenu.ConfigIllegalFishing.Separator("ZONES DE PÊCHE (" .. #zones .. ")")

    StaffMenu.ConfigIllegalFishing.Button(":plus: CRÉER NOUVELLE ZONE", "Créer une zone de pêche illégale", nil, "chevron", false, function()
        -- Reset des données
        currentFishingZone = {
            name = "",
            center = nil,
            radius = 50.0,
            fish = {}
        }
    end, StaffMenu.CreateFishingZone)

    if #zones > 0 then
        StaffMenu.ConfigIllegalFishing.Button(":folder: GÉRER LES ZONES", "Modifier ou supprimer des zones", nil, "chevron", false, function()
        end, StaffMenu.ManageFishingZones)
    end
end

-- Menu création zone
function StaffMenu.BuildCreateFishingZoneMenu()
    StaffMenu.CreateFishingZone.Separator("CRÉATION DE ZONE")

    StaffMenu.CreateFishingZone.Button(":pin: NOM DE LA ZONE", currentFishingZone.name ~= "" and currentFishingZone.name or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la zone de pêche", currentFishingZone.name)
        if input and input ~= "" then
            currentFishingZone.name = input
            StaffMenu.CreateFishingZone.refresh()
        end
    end)

    StaffMenu.CreateFishingZone.Button(":target: POSITION CENTRE", currentFishingZone.center and "Définie" or "Non définie", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        currentFishingZone.center = {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100
        }
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position centre définie."
      })
        StaffMenu.CreateFishingZone.refresh()
    end)

    StaffMenu.CreateFishingZone.Button(":ruler: RAYON", currentFishingZone.radius .. " mètres", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rayon de la zone (mètres)", tostring(currentFishingZone.radius))
        if input and tonumber(input) and tonumber(input) > 0 and tonumber(input) <= 200 then
            currentFishingZone.radius = tonumber(input)
            StaffMenu.CreateFishingZone.refresh()
        end
    end)

    StaffMenu.CreateFishingZone.Separator("POISSONS (" .. #currentFishingZone.fish .. ")")

    StaffMenu.CreateFishingZone.Button(":plus: AJOUTER POISSON", "Ajouter un type de poisson", nil, "arrow", false, function()
        local itemInput = VFW.Nui.KeyboardInput(true, "Nom de l'item poisson", "")
        if itemInput and itemInput ~= "" then
            local weightInput = VFW.Nui.KeyboardInput(true, "Poids de spawn (1-100)", "1")
            if weightInput and tonumber(weightInput) and tonumber(weightInput) >= 1 and tonumber(weightInput) <= 100 then
                table.insert(currentFishingZone.fish, {
                    item = itemInput,
                    weight = tonumber(weightInput)
                })
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Poisson ajouté: " .. itemInput .. "."
              })
                StaffMenu.CreateFishingZone.refresh()
            end
        end
    end)

    -- Afficher les poissons
    for i, fish in ipairs(currentFishingZone.fish) do
        StaffMenu.CreateFishingZone.Button(":leaf: " .. fish.item, "Poids: " .. fish.weight, nil, "arrow", false, function()
            table.remove(currentFishingZone.fish, i)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Poisson supprimé."
          })
            StaffMenu.CreateFishingZone.refresh()
        end)
    end

    StaffMenu.CreateFishingZone.Separator("VALIDATION")

    local canCreate = currentFishingZone.name ~= "" and currentFishingZone.center ~= nil and #currentFishingZone.fish > 0
    StaffMenu.CreateFishingZone.Button(":save: CRÉER LA ZONE", "Sauvegarder la zone", nil, "arrow", not canCreate, function()
        if canCreate then
            TriggerServerEvent('core:illegalfishing:createZone', currentFishingZone)
            Wait(100)
            StaffMenu.CreateFishingZone.close()
            StaffMenu.ConfigIllegalFishing.refresh()
        end
    end)
end

-- Menu gestion zones
function StaffMenu.BuildManageFishingZonesMenu()
    local zones = TriggerServerCallback("core:illegalfishing:getZones") or {}

    StaffMenu.ManageFishingZones.Separator("ZONES EXISTANTES (" .. #zones .. ")")

    for _, zone in ipairs(zones) do
        local fishCount = zone.fish and #zone.fish or 0
        StaffMenu.ManageFishingZones.Button(":map: " .. zone.name, fishCount .. (fishCount > 1 and " types de poisson" or " type de poisson"), nil, "chevron", false, function()
            selectedZoneId = zone.id
            currentFishingZone = {
                name = zone.name,
                center = zone.center,
                radius = zone.radius,
                fish = zone.fish or {}
            }
        end, StaffMenu.EditFishingZone)
    end
end

-- Menu édition zone
function StaffMenu.BuildEditFishingZoneMenu()
    if not selectedZoneId then
        StaffMenu.EditFishingZone.Button(":x: ERREUR", "Zone introuvable", nil, "arrow", true, function() end)
        return
    end

    StaffMenu.EditFishingZone.Separator("ÉDITION: " .. currentFishingZone.name)

    StaffMenu.EditFishingZone.Button(":pin: NOM DE LA ZONE", currentFishingZone.name, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la zone de pêche", currentFishingZone.name)
        if input and input ~= "" then
            currentFishingZone.name = input
            StaffMenu.EditFishingZone.refresh()
        end
    end)

    StaffMenu.EditFishingZone.Button(":ruler: RAYON", currentFishingZone.radius .. " mètres", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rayon de la zone (mètres)", tostring(currentFishingZone.radius))
        if input and tonumber(input) and tonumber(input) > 0 and tonumber(input) <= 200 then
            currentFishingZone.radius = tonumber(input)
            StaffMenu.EditFishingZone.refresh()
        end
    end)

    StaffMenu.EditFishingZone.Separator("POISSONS (" .. #currentFishingZone.fish .. ")")

    StaffMenu.EditFishingZone.Button(":plus: AJOUTER POISSON", "Ajouter un type de poisson", nil, "arrow", false, function()
        local itemInput = VFW.Nui.KeyboardInput(true, "Nom de l'item poisson", "")
        if itemInput and itemInput ~= "" then
            local weightInput = VFW.Nui.KeyboardInput(true, "Poids de spawn (1-100)", "1")
            if weightInput and tonumber(weightInput) and tonumber(weightInput) >= 1 and tonumber(weightInput) <= 100 then
                table.insert(currentFishingZone.fish, {
                    item = itemInput,
                    weight = tonumber(weightInput)
                })
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Poisson ajouté: " .. itemInput .. "."
              })
                StaffMenu.EditFishingZone.refresh()
            end
        end
    end)

    -- Afficher les poissons
    for i, fish in ipairs(currentFishingZone.fish) do
        StaffMenu.EditFishingZone.Button(":leaf: " .. fish.item, "Poids: " .. fish.weight, nil, "arrow", false, function()
            table.remove(currentFishingZone.fish, i)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Poisson supprimé."
          })
            StaffMenu.EditFishingZone.refresh()
        end)
    end

    StaffMenu.EditFishingZone.Separator("ACTIONS")

    StaffMenu.EditFishingZone.Button(":save: SAUVEGARDER", "Sauvegarder les modifications", nil, "arrow", false, function()
        TriggerServerEvent('core:illegalfishing:updateZone', selectedZoneId, currentFishingZone)
        Wait(100)
        StaffMenu.EditFishingZone.close()
        StaffMenu.ManageFishingZones.refresh()
    end)

    StaffMenu.EditFishingZone.Button(":trash: SUPPRIMER ZONE", "Supprimer définitivement", nil, "arrow", false, function()
        TriggerServerEvent('core:illegalfishing:deleteZone', selectedZoneId)
        Wait(100)
        StaffMenu.EditFishingZone.close()
        StaffMenu.ManageFishingZones.refresh()
    end)
end

-- Menu paramètres globaux
function StaffMenu.BuildIllegalFishingSettingsMenu()
    local settings = TriggerServerCallback("core:illegalfishing:getSettings") or {}

    StaffMenu.IllegalFishingSettings.Separator("SYSTÈME")

    StaffMenu.IllegalFishingSettings.Checkbox(":users: FACTION REQUISE", "Nécessite une faction pour pêcher et voir les zones", false, settings.needFaction == "true", function(value)
        TriggerServerEvent("core:illegalfishing:updateSettings", "needFaction", tostring(value))
        Wait(100)
        StaffMenu.IllegalFishingSettings.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = value and "Faction requise activée." or "Faction requise désactivée."
      })
    end)

    StaffMenu.IllegalFishingSettings.Separator("RÉCOLTE")

    StaffMenu.IllegalFishingSettings.Button(":chart: POISSONS MIN", (settings.minFishPerCatch or 2), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de poissons par pêche", tostring((settings.minFishPerCatch or 2)))
        if input and tonumber(input) and tonumber(input) >= 1 and tonumber(input) <= 10 then
            TriggerServerEvent("core:illegalfishing:updateSettings", "minFishPerCatch", tonumber(input))
            Wait(100)
            StaffMenu.IllegalFishingSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Poissons minimum mis à jour."
          })
        end
    end)

    StaffMenu.IllegalFishingSettings.Button(":chart: POISSONS MAX", (settings.maxFishPerCatch or 5), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre maximum de poissons par pêche", tostring((settings.maxFishPerCatch or 5)))
        if input and tonumber(input) and tonumber(input) >= 1 and tonumber(input) <= 20 then
            TriggerServerEvent("core:illegalfishing:updateSettings", "maxFishPerCatch", tonumber(input))
            Wait(100)
            StaffMenu.IllegalFishingSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Poissons maximum mis à jour."
          })
        end
    end)

    StaffMenu.IllegalFishingSettings.Separator("SYSTÈME")

    StaffMenu.IllegalFishingSettings.Button(":clock: DURÉE PÊCHE", (settings.fishingDuration or 30) .. " secondes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée de la pêche (secondes)", tostring((settings.fishingDuration or 30)))
        if input and tonumber(input) and tonumber(input) >= 10 and tonumber(input) <= 120 then
            TriggerServerEvent("core:illegalfishing:updateSettings", "fishingDuration", tonumber(input))
            Wait(100)
            StaffMenu.IllegalFishingSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Durée pêche mise à jour."
          })
        end
    end)

    StaffMenu.IllegalFishingSettings.Button(":siren: CHANCE POLICE", (settings.policeCallChance or 33) .. "%", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Chance d'alerter la police (%)", tostring((settings.policeCallChance or 33)))
        if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 100 then
            TriggerServerEvent("core:illegalfishing:updateSettings", "policeCallChance", tonumber(input))
            Wait(100)
            StaffMenu.IllegalFishingSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Chance police mise à jour."
          })
        end
    end)

    StaffMenu.IllegalFishingSettings.Button(":siren: DURÉE BLIP POLICE", math.floor((settings.policeBlipDuration or 300) / 60) .. (math.floor((settings.policeBlipDuration or 300) / 60) > 1 and " minutes" or " minute"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée blip police (minutes)", tostring(math.floor((settings.policeBlipDuration or 300) / 60)))
        if input and tonumber(input) and tonumber(input) >= 1 and tonumber(input) <= 30 then
            TriggerServerEvent("core:illegalfishing:updateSettings", "policeBlipDuration", tonumber(input) * 60)
            Wait(100)
            StaffMenu.IllegalFishingSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Durée blip police mise à jour."
          })
        end
    end)

    StaffMenu.IllegalFishingSettings.Button(":wrench: ITEM REQUIS", (settings.requiredItem or "illegal_fishing_net"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item requis", tostring((settings.requiredItem or "illegal_fishing_net")))
        if input and input ~= "" then
            TriggerServerEvent("core:illegalfishing:updateSettings", "requiredItem", input)
            Wait(100)
            StaffMenu.IllegalFishingSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Item requis mis à jour."
          })
        end
    end)
end

-- ========================
-- ATM ROBBERY BUILDER SYSTEM
-- ========================

-- ATM Builder Menu
function StaffMenu.BuildATMMenu()
    -- Activer le mode admin pour voir les zones ATM (cubes verts)
    exports["core"]:SetATMAdminMode(true)

    StaffMenu.builderATM.Separator("GESTION DES ATM")

    -- Toggle pour afficher/masquer les zones
    local adminMode = exports["core"]:IsATMAdminMode()
    StaffMenu.builderATM.Checkbox(":eye: AFFICHER LES ZONES ATM", "Affiche les cubes verts sur les ATM customs", false, adminMode, function(checked)
        exports["core"]:SetATMAdminMode(checked)
    end)

    -- Bouton pour ajouter un ATM à la position actuelle
    StaffMenu.builderATM.Button(":plus: AJOUTER UN ATM ICI", "Place-toi DEVANT l'ATM où les joueurs doivent être TP", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        local name = VFW.Nui.KeyboardInput(true, "Nom de l'ATM (optionnel)", "ATM Custom")
        if not name or name == "" then name = "ATM Custom" end

        print("[ATM Client] Envoi ajout ATM: " .. name .. " à " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)

        TriggerServerEvent("core:atm:addCustomPosition", {
            name = name,
            x = coords.x,
            y = coords.y,
            z = coords.z - 1.0,
            heading = heading
        })

        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Ajout de l'ATM en cours."
      })

        -- Attendre la synchronisation du serveur puis rafraîchir
        SetTimeout(800, function()
            StaffMenu.builderATM.refresh()
            -- Forcer aussi le refresh des zones visuelles
            exports["core"]:RefreshATMPositions()
        end)
    end)

    -- Liste des ATM customs
    StaffMenu.builderATM.Button(":report: LISTE DES ATM CUSTOMS", "Voir et gérer les ATM ajoutés", nil, "chevron", false, function()
    end, StaffMenu.ListCustomATMsMenu)

    StaffMenu.builderATM.Separator("CONFIGURATION BRAQUAGES ATM")

    -- Récupérer la config actuelle depuis le serveur
    local atmConfig = TriggerServerCallback("core:atm:getSettings") or {}

    StaffMenu.builderATM.Separator(":money: RÉCOMPENSES")

    StaffMenu.builderATM.Button(":money: ARGENT SALE MINIMUM", VFW.Math.FormatMoney(atmConfig.dirtyMin or 1200), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant minimum d'argent sale (" .. LOCALE.currencySymbol .. ")", tostring(atmConfig.dirtyMin or 1200))
        if input and tonumber(input) then
            TriggerServerEvent('core:atm:updateSettings', 'dirtyMin', tonumber(input))
            atmConfig.dirtyMin = tonumber(input)
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Argent sale minimum mis à jour: " .. VFW.Math.FormatMoney(input) .. "."
          })
        end
    end)

    StaffMenu.builderATM.Button(":money: ARGENT SALE MAXIMUM", VFW.Math.FormatMoney(atmConfig.dirtyMax or 1800), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant maximum d'argent sale (" .. LOCALE.currencySymbol .. ")", tostring(atmConfig.dirtyMax or 1800))
        if input and tonumber(input) then
            TriggerServerEvent('core:atm:updateSettings', 'dirtyMax', tonumber(input))
            atmConfig.dirtyMax = tonumber(input)
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Argent sale maximum mis à jour: " .. VFW.Math.FormatMoney(input) .. "."
          })
        end
    end)

    StaffMenu.builderATM.Separator(":clock: COOLDOWNS")

    StaffMenu.builderATM.Button(":clock: COOLDOWN PAR ATM", (atmConfig.globalCooldown or 3600) .. " secondes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown par ATM en secondes", tostring(atmConfig.globalCooldown or 3600))
        if input and tonumber(input) then
            TriggerServerEvent('core:atm:updateSettings', 'globalCooldown', tonumber(input))
            atmConfig.globalCooldown = tonumber(input)
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Cooldown par ATM mis à jour: " .. input .. " secondes."
          })
        end
    end)

    StaffMenu.builderATM.Button(":clock: COOLDOWN PAR JOUEUR", (atmConfig.playerCooldown or 1800) .. " secondes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown par joueur en secondes (ex: 1800 = 30min)", tostring(atmConfig.playerCooldown or 1800))
        if input and tonumber(input) then
            TriggerServerEvent('core:atm:updateSettings', 'playerCooldown', tonumber(input))
            atmConfig.playerCooldown = tonumber(input)
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Cooldown par joueur mis à jour: " .. input .. " secondes."
          })
        end
    end)

    StaffMenu.builderATM.Separator(":police: POLICE")

    StaffMenu.builderATM.Button(":police: POLICIERS REQUIS", tostring(atmConfig.minPoliceRequired or 2) .. ((atmConfig.minPoliceRequired or 2) > 1 and " policiers" or " policier"), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de policiers en service", tostring(atmConfig.minPoliceRequired or 2))
        if input and tonumber(input) then
            local value = math.max(0, math.floor(tonumber(input)))
            TriggerServerEvent('core:atm:updateSettings', 'minPoliceRequired', value)
            atmConfig.minPoliceRequired = value
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Policiers requis mis à jour: " .. value .. "."
          })
        end
    end)

    StaffMenu.builderATM.Button(":siren: CHANCE D'ALARME", tostring(atmConfig.alertChance or 100) .. "%", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Chance d'alerte police en % (0-100)", tostring(atmConfig.alertChance or 100))
        if input and tonumber(input) then
            local value = math.max(0, math.min(100, math.floor(tonumber(input))))
            TriggerServerEvent('core:atm:updateSettings', 'alertChance', value)
            atmConfig.alertChance = value
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Chance d'alarme mise à jour: " .. value .. "%."
          })
        end
    end)

    StaffMenu.builderATM.Separator(":gamepad: JACKPOT (Dysfonctionnement ATM)")

    StaffMenu.builderATM.Button(":gamepad: CHANCE DE JACKPOT", "1 sur " .. tostring(atmConfig.jackpotChance or 10), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "1 chance sur X (ex: 10 = 10%)", tostring(atmConfig.jackpotChance or 10))
        if input and tonumber(input) then
            local value = math.max(2, math.min(100, tonumber(input)))
            TriggerServerEvent('core:atm:updateSettings', 'jackpotChance', value)
            atmConfig.jackpotChance = value
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Chance de jackpot: 1 sur " .. value .. "."
          })
        end
    end)

    StaffMenu.builderATM.Button(":money: MULTIPLICATEUR JACKPOT", "x" .. tostring(atmConfig.jackpotMultiplier or 5), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Multiplicateur d'argent (ex: 5 = x5)", tostring(atmConfig.jackpotMultiplier or 5))
        if input and tonumber(input) then
            local value = math.max(2, math.min(20, tonumber(input)))
            TriggerServerEvent('core:atm:updateSettings', 'jackpotMultiplier', value)
            atmConfig.jackpotMultiplier = value
            StaffMenu.builderATM.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Multiplicateur jackpot: x" .. value .. "."
          })
        end
    end)

    StaffMenu.builderATM.Separator(":wrench: ACTIONS")

    StaffMenu.builderATM.Button(":clock: RÉINITIALISER LES COOLDOWNS", "Réinitialise tous les temps d'attente", nil, "arrow", false, function()
        TriggerServerEvent('core:atm:resetCooldowns')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Cooldowns ATM réinitialisés."
      })
    end)

    StaffMenu.builderATM.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge la configuration depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:atm:reloadSettings')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Rechargement de la configuration ATM en cours."
      })
        Wait(500)
        StaffMenu.builderATM.refresh()
    end)
end

-- Liste des ATM customs
function StaffMenu.ListCustomATMs()
    StaffMenu.ListCustomATMsMenu.Separator(":report: ATM CUSTOMS")

    local customATMs = TriggerServerCallback("core:atm:getCustomPositions") or {}

    if #customATMs == 0 then
        StaffMenu.ListCustomATMsMenu.Button("Aucun ATM custom", "Utilisez 'Ajouter un ATM ici' pour en créer", nil, nil, true, function() end)
    else
        for _, atm in ipairs(customATMs) do
            local atmName = atm.name or ("ATM #" .. atm.id)
            local coordsStr = string.format("%.1f, %.1f, %.1f", atm.x, atm.y, atm.z)

            StaffMenu.ListCustomATMsMenu.Button(":money: " .. atmName, coordsStr, nil, "chevron", false, function()
                StaffMenu.selectedATM = atm
            end, StaffMenu.EditCustomATMMenu)
        end
    end
end

-- Menu d'édition d'un ATM custom
function StaffMenu.BuildEditCustomATMMenu()
    local atm = StaffMenu.selectedATM
    if not atm then return end

    StaffMenu.EditCustomATMMenu.Separator(":money: " .. (atm.name or "ATM #" .. atm.id))

    -- Afficher les coordonnées actuelles
    local coordsStr = string.format("X: %.2f | Y: %.2f | Z: %.2f", atm.x or 0, atm.y or 0, atm.z or 0)
    local headingStr = string.format("%.1f°", atm.heading or 0)

    StaffMenu.EditCustomATMMenu.Button(":edit: RENOMMER", atm.name or "ATM Custom", nil, "chevron", false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nouveau nom de l'ATM", atm.name or "ATM Custom")
        if newName and newName ~= "" then
            TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "name", newName)
            atm.name = newName
            StaffMenu.selectedATM = atm
            Wait(300)
            StaffMenu.EditCustomATMMenu.refresh()
        end
    end)

    StaffMenu.EditCustomATMMenu.Separator(":pin: POSITION")

    StaffMenu.EditCustomATMMenu.Button(":pin: TÉLÉPORTER", "Se téléporter à cet ATM", nil, "arrow", false, function()
        TriggerServerEvent("core:atm:teleportToATM", atm.id)
    end)

    StaffMenu.EditCustomATMMenu.Button(":refresh: POSITION ACTUELLE", "Place-toi DEVANT l'ATM où les joueurs doivent être TP", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "x", coords.x)
        TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "y", coords.y)
        TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "z", coords.z - 1.0)
        TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "heading", heading)

        atm.x = coords.x
        atm.y = coords.y
        atm.z = coords.z - 1.0
        atm.heading = heading
        StaffMenu.selectedATM = atm

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position ATM mise à jour."
      })
        Wait(500)
        StaffMenu.EditCustomATMMenu.refresh()
    end)

    StaffMenu.EditCustomATMMenu.Separator(":wrench: AJUSTEMENTS FINS")

    -- Coordonnées X
    StaffMenu.EditCustomATMMenu.Button("↔ COORDONNÉE X", string.format("%.2f", atm.x or 0), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Coordonnée X", string.format("%.4f", atm.x or 0))
        if input and tonumber(input) then
            TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "x", tonumber(input))
            atm.x = tonumber(input)
            StaffMenu.selectedATM = atm
            Wait(300)
            StaffMenu.EditCustomATMMenu.refresh()
        end
    end)

    -- Coordonnées Y
    StaffMenu.EditCustomATMMenu.Button("↕ COORDONNÉE Y", string.format("%.2f", atm.y or 0), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Coordonnée Y", string.format("%.4f", atm.y or 0))
        if input and tonumber(input) then
            TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "y", tonumber(input))
            atm.y = tonumber(input)
            StaffMenu.selectedATM = atm
            Wait(300)
            StaffMenu.EditCustomATMMenu.refresh()
        end
    end)

    -- Coordonnées Z (hauteur)
    StaffMenu.EditCustomATMMenu.Button(":arrow: COORDONNÉE Z", string.format("%.2f", atm.z or 0), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Coordonnée Z (hauteur du sol)", string.format("%.4f", atm.z or 0))
        if input and tonumber(input) then
            TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "z", tonumber(input))
            atm.z = tonumber(input)
            StaffMenu.selectedATM = atm
            Wait(300)
            StaffMenu.EditCustomATMMenu.refresh()
        end
    end)

    -- Heading (orientation)
    StaffMenu.EditCustomATMMenu.Button(":compass: HEADING (Orientation)", headingStr, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Heading en degrés (0-360)", string.format("%.1f", atm.heading or 0))
        if input and tonumber(input) then
            local heading = tonumber(input) % 360
            TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "heading", heading)
            atm.heading = heading
            StaffMenu.selectedATM = atm
            Wait(300)
            StaffMenu.EditCustomATMMenu.refresh()
        end
    end)

    -- Boutons rapides pour le heading
    StaffMenu.EditCustomATMMenu.Button(":refresh: HEADING +45°", "Tourner la zone de 45°", nil, "arrow", false, function()
        local newHeading = ((atm.heading or 0) + 45) % 360
        TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "heading", newHeading)
        atm.heading = newHeading
        StaffMenu.selectedATM = atm
        Wait(300)
        StaffMenu.EditCustomATMMenu.refresh()
    end)

    StaffMenu.EditCustomATMMenu.Button(":refresh: HEADING -45°", "Tourner la zone de -45°", nil, "arrow", false, function()
        local newHeading = ((atm.heading or 0) - 45) % 360
        if newHeading < 0 then newHeading = newHeading + 360 end
        TriggerServerEvent("core:atm:updateCustomPosition", atm.id, "heading", newHeading)
        atm.heading = newHeading
        StaffMenu.selectedATM = atm
        Wait(300)
        StaffMenu.EditCustomATMMenu.refresh()
    end)

    StaffMenu.EditCustomATMMenu.Separator(":warning: DANGER")

    StaffMenu.EditCustomATMMenu.Button(":trash: SUPPRIMER CET ATM", "Supprime définitivement cet ATM", nil, "arrow", false, function()
        local atmId = atm.id
        local atmName = atm.name or ("ATM #" .. atmId)

        TriggerServerEvent("core:atm:deleteCustomPosition", atmId)

        -- Effacer la sélection
        StaffMenu.selectedATM = nil

        StaffMenu.EditCustomATMMenu.close()
        StaffMenu.ListCustomATMsMenu.open()

        -- Attendre la synchronisation du serveur puis rafraîchir la liste
        SetTimeout(500, function()
            -- Forcer le refresh de la liste
            if StaffMenu.ListCustomATMsMenu then
                StaffMenu.ListCustomATMsMenu.refresh()
            end
            -- Forcer aussi le refresh des zones visuelles
            exports["core"]:RefreshATMPositions()
        end)
    end)
end

-- ========================
-- FLEECA BANK BUILDER SYSTEM
-- ========================

-- Fleeca Builder Menu
function StaffMenu.BuildFleecaMenu()
    StaffMenu.builderFleeca.Separator("GESTION DES BANQUES FLEECA")

    StaffMenu.builderFleeca.Button(":plus: CRÉER UNE BANQUE FLEECA", "Ajouter une nouvelle banque Fleeca", nil, "chevron", false, function()
    end, StaffMenu.CreateFleecaBank)

    StaffMenu.builderFleeca.Button(":box: LISTE DES BANQUES FLEECA", "Gérer les banques existantes", nil, "chevron", false, function()
    end, StaffMenu.ListFleecaBank)

    StaffMenu.builderFleeca.Separator("CONFIGURATION GLOBALE")

    StaffMenu.builderFleeca.Button(":settings: PARAMÈTRES GLOBAUX", "Cooldowns, récompenses, etc.", nil, "chevron", false, function()
    end, StaffMenu.FleecaSettings)

    StaffMenu.builderFleeca.Button(":clock: RÉINITIALISER LES COOLDOWNS", "Réinitialise tous les temps d'attente", nil, "arrow", false, function()
        TriggerServerEvent('core:fleeca:resetCooldowns')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Cooldowns Fleeca réinitialisés."
      })
    end)

    StaffMenu.builderFleeca.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge les banques depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:fleeca:reloadFromDatabase')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Rechargement des banques Fleeca en cours."
      })
    end)
end

-- Variables globales pour le menu de création Fleeca
local fleecaData = {
    name = "",
    canRob = true,
    active = true,
    blipEnabled = true,
    bankPos = nil,
    accountAccessPositions = {},
    doorHackPos = nil,
    safePositions = {}
}
local selectedFleecaBank = nil

local function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = vector3(
        cameraCoord.x + direction.x * distance,
        cameraCoord.y + direction.y * distance,
        cameraCoord.z + direction.z * distance
    )
    local _, hit, coords, _, entity = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return hit, coords, entity
end

local function SelectDoorVisually()
    local selectionActive = true
    local currentEntity = nil
    local selectedEntity = nil
    local selectedCoords = nil

    CreateThread(function()
        while selectionActive do
            Wait(0)

            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Sélectionner la porte ~n~~INPUT_FRONTEND_RRIGHT~ Annuler")

            if currentEntity and currentEntity ~= selectedEntity then
                SetEntityDrawOutline(currentEntity, false)
            end

            local hit, coords, entity = RayCastGamePlayCamera(15.0)

            if DoesEntityExist(entity) then
                currentEntity = entity
                SetEntityDrawOutline(currentEntity, true)

                if VFW.Interact.JustPressed(0, 51) then
                    selectedEntity = entity
                    selectedCoords = GetEntityCoords(entity)
                    selectionActive = false
                end
            end

            if IsControlJustPressed(0, 194) then
                if currentEntity then
                    SetEntityDrawOutline(currentEntity, false)
                end
                selectionActive = false
            end
        end

        if currentEntity and not selectedEntity then
            SetEntityDrawOutline(currentEntity, false)
        end
        if selectedEntity then
            SetEntityDrawOutline(selectedEntity, false)
        end
    end)

    while selectionActive do
        Wait(100)
    end

    return selectedEntity, selectedCoords
end

-- Manage Fleeca Access Points Menu
function StaffMenu.BuildCreateFleecaAccessPointsMenu()
    StaffMenu.CreateFleecaAccessPoints.Separator("POINTS D'ACCÈS BANCAIRE (" .. #fleecaData.accountAccessPositions .. ")")

    -- Ajouter un nouveau point d'accès
    StaffMenu.CreateFleecaAccessPoints.Button(":plus: AJOUTER POINT D'ACCÈS", "À votre position actuelle", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        table.insert(fleecaData.accountAccessPositions, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        })

        StaffMenu.CreateFleecaAccessPoints.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Point d'accès ajouté (#" .. #fleecaData.accountAccessPositions .. ")."
      })
    end)

    if #fleecaData.accountAccessPositions > 0 then
        StaffMenu.CreateFleecaAccessPoints.Separator("POINTS EXISTANTS")

        for i, pos in ipairs(fleecaData.accountAccessPositions) do
            StaffMenu.CreateFleecaAccessPoints.Button(":pin: POINT #" .. i, string.format("X: %.1f Y: %.1f Z: %.1f", pos.x, pos.y, pos.z), nil, "arrow", false, function()
                table.remove(fleecaData.accountAccessPositions, i)
                StaffMenu.CreateFleecaAccessPoints.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                    message = "Point d'accès #" .. i .. " supprimé."
              })
            end)
        end

        StaffMenu.CreateFleecaAccessPoints.Separator("ACTIONS")

        StaffMenu.CreateFleecaAccessPoints.Button(":trash: SUPPRIMER TOUS", "Efface tous les points d'accès", nil, "arrow", false, function()
            fleecaData.accountAccessPositions = {}
            StaffMenu.CreateFleecaAccessPoints.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Tous les points d'accès supprimés."
          })
        end)
    end
end

function StaffMenu.BuildEditFleecaAccessPointsMenu()
    if not selectedFleecaBank then
        StaffMenu.EditFleecaAccessPoints.Button(":x: ERREUR", "Banque non sélectionnée", nil, "arrow", true, function() end)
        return
    end

    StaffMenu.EditFleecaAccessPoints.Separator("POINTS D'ACCÈS BANCAIRE (" .. #selectedFleecaBank.accountAccessPositions .. ")")

    StaffMenu.EditFleecaAccessPoints.Button(":plus: AJOUTER POINT D'ACCÈS", "À votre position actuelle", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        table.insert(selectedFleecaBank.accountAccessPositions, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        })

        TriggerServerEvent('core:fleeca:updateBank', selectedFleecaBank.id, 'accountAccessPositions', selectedFleecaBank.accountAccessPositions)
        StaffMenu.EditFleecaAccessPoints.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Point d'accès ajouté (#" .. #selectedFleecaBank.accountAccessPositions .. ")."
      })
    end)

    if #selectedFleecaBank.accountAccessPositions > 0 then
        StaffMenu.EditFleecaAccessPoints.Separator("POINTS EXISTANTS")

        for i, pos in ipairs(selectedFleecaBank.accountAccessPositions) do
            StaffMenu.EditFleecaAccessPoints.Button(":pin: POINT #" .. i, string.format("X: %.1f Y: %.1f Z: %.1f", pos.x, pos.y, pos.z), nil, "arrow", false, function()
                table.remove(selectedFleecaBank.accountAccessPositions, i)
                TriggerServerEvent('core:fleeca:updateBank', selectedFleecaBank.id, 'accountAccessPositions', selectedFleecaBank.accountAccessPositions)
                StaffMenu.EditFleecaAccessPoints.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                    message = "Point d'accès #" .. i .. " supprimé."
              })
            end)
        end

        StaffMenu.EditFleecaAccessPoints.Separator("ACTIONS")

        StaffMenu.EditFleecaAccessPoints.Button(":trash: SUPPRIMER TOUS", "Efface tous les points d'accès", nil, "arrow", false, function()
            selectedFleecaBank.accountAccessPositions = {}
            TriggerServerEvent('core:fleeca:updateBank', selectedFleecaBank.id, 'accountAccessPositions', selectedFleecaBank.accountAccessPositions)
            StaffMenu.EditFleecaAccessPoints.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Tous les points d'accès supprimés."
          })
        end)
    end
end

-- Create Fleeca Bank Menu
function StaffMenu.BuildCreateFleecaBankMenu()
    StaffMenu.CreateFleecaBank.Separator("CONFIGURATION BANQUE FLEECA")

    -- Nom de la banque
    StaffMenu.CreateFleecaBank.Button(":edit: NOM DE LA BANQUE", fleecaData.name ~= "" and fleecaData.name or "Non défini", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la banque (ex: Fleeca Bank - Downtown)", fleecaData.name)
        if input and input ~= "" then
            fleecaData.name = input
            StaffMenu.CreateFleecaBank.refresh()
        end
    end)

    StaffMenu.CreateFleecaBank.Separator("OPTIONS")

    StaffMenu.CreateFleecaBank.Checkbox(":check: ACTIVE", nil, false, fleecaData.active, function(value)
        fleecaData.active = value
        StaffMenu.CreateFleecaBank.refresh()
    end)

    StaffMenu.CreateFleecaBank.Checkbox(":gun: BRAQUABLE", nil, false, fleecaData.canRob, function(value)
        fleecaData.canRob = value
        StaffMenu.CreateFleecaBank.refresh()
    end)

    StaffMenu.CreateFleecaBank.Checkbox(":pin: BLIP SUR LA MAP", nil, false, fleecaData.blipEnabled, function(value)
        fleecaData.blipEnabled = value
        StaffMenu.CreateFleecaBank.refresh()
    end)

    StaffMenu.CreateFleecaBank.Separator("POSITIONS")

    -- Position principale de la banque
    StaffMenu.CreateFleecaBank.Button(":building: POSITION BANQUE", fleecaData.bankPos and "Définie" or "Non définie", nil, "chevron", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        fleecaData.bankPos = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
        StaffMenu.CreateFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position banque définie."
      })
    end)

    -- Points d'accès au compte bancaire
    StaffMenu.CreateFleecaBank.Button(":monitor: AJOUTER POINT D'ACCÈS", #fleecaData.accountAccessPositions .. (#fleecaData.accountAccessPositions > 1 and " définis" or " défini"), nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        table.insert(fleecaData.accountAccessPositions, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        })

        StaffMenu.CreateFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Point d'accès ajouté (#" .. #fleecaData.accountAccessPositions .. ")."
      })
    end)

    if #fleecaData.accountAccessPositions > 0 then
        StaffMenu.CreateFleecaBank.Button(":trash: SUPPRIMER DERNIER POINT", "Retirer le dernier point d'accès", nil, "arrow", false, function()
            table.remove(fleecaData.accountAccessPositions)
            StaffMenu.CreateFleecaBank.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Dernier point d'accès supprimé (" .. #fleecaData.accountAccessPositions .. (#fleecaData.accountAccessPositions > 1 and " restants)." or " restant).")
          })
        end)
    end

    StaffMenu.CreateFleecaBank.Button(":pin: POINT HACK PORTE", fleecaData.doorHackPos and "Défini" or "Pas défini", nil, "chevron", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        fleecaData.doorHackPos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        }
        StaffMenu.CreateFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position du hack de porte définie."
      })
    end)

    StaffMenu.CreateFleecaBank.Button(":target: POSITION PORTE COFFRE", fleecaData.vaultDoorPos and "Défini" or "Pas défini", nil, "chevron", false, function()
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            subtitle = 'Mode Builder',
            message = "Mode sélection activé - Visez la porte et appuyez sur E."
      })
        StaffMenu.CreateFleecaBank.close()

        local entity, coords = SelectDoorVisually()

        if coords and entity then
            fleecaData.vaultDoorPos = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                model = GetEntityModel(entity)
            }
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = string.format("Porte du coffre sélectionnée (%.2f, %.2f, %.2f) - Model: %d.", coords.x, coords.y, coords.z, GetEntityModel(entity))
            })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Sélection annulée."
          })
        end

        StaffMenu.CreateFleecaBank.open()
        StaffMenu.CreateFleecaBank.refresh()
    end)

    -- Sortie d'urgence supprimée (plus utilisée)

    StaffMenu.CreateFleecaBank.Separator("COFFRES (" .. #fleecaData.safePositions .. "/4)")

    -- Gestion des 4 coffres
    for i = 1, 4 do
        local hasPosition = fleecaData.safePositions[i] ~= nil
        StaffMenu.CreateFleecaBank.Button(":lock: COFFRE #" .. i, hasPosition and "Défini" or "Non défini", nil, "chevron", false, function()
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            fleecaData.safePositions[i] = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                h = heading
            }
            StaffMenu.CreateFleecaBank.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Position coffre #" .. i .. " définie."
          })
        end)
    end

    if #fleecaData.safePositions > 0 then
        StaffMenu.CreateFleecaBank.Button(":trash: SUPPRIMER DERNIER COFFRE", nil, nil, "arrow", false, function()
            table.remove(fleecaData.safePositions, #fleecaData.safePositions)
            StaffMenu.CreateFleecaBank.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Dernier coffre supprimé."
          })
        end)
    end

    StaffMenu.CreateFleecaBank.Separator("ACTIONS")

    -- Bouton de création
    local canCreate = fleecaData.name ~= "" and fleecaData.bankPos ~= nil and #fleecaData.accountAccessPositions > 0 and fleecaData.doorHackPos ~= nil
    StaffMenu.CreateFleecaBank.Button(":check: CRÉER LA BANQUE", canCreate and "Prêt à créer" or "Informations manquantes", nil, "arrow", not canCreate, function()
        if canCreate then
            local data = {
                name = fleecaData.name,
                pos = fleecaData.bankPos,
                accountAccessPositions = fleecaData.accountAccessPositions,
                doorHackPos = fleecaData.doorHackPos,
                vaultDoorPos = fleecaData.vaultDoorPos,
                safePositions = fleecaData.safePositions,
                canRob = fleecaData.canRob,
                active = fleecaData.active,
                blipEnabled = fleecaData.blipEnabled
            }

            TriggerServerEvent('core:fleeca:createBank', data)

            -- Reset data
            fleecaData = {
                name = "",
                canRob = true,
                active = true,
                blipEnabled = true,
                bankPos = nil,
                accountAccessPositions = {},
                doorHackPos = nil,
                safePositions = {}
            }

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Banque Fleeca créée."
          })

            StaffMenu.CreateFleecaBank.close()
            StaffMenu.builderFleeca.open()
        end
    end)

    StaffMenu.CreateFleecaBank.Button(":refresh: RÉINITIALISER", nil, nil, "arrow", false, function()
        fleecaData = {
            name = "",
            canRob = true,
            active = true,
            blipEnabled = true,
            bankPos = nil,
            accountAccessPositions = {},
            doorHackPos = nil,
            safePositions = {}
        }
        StaffMenu.CreateFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Données réinitialisées."
      })
    end)
end

-- List Fleeca Banks Menu
function StaffMenu.BuildListFleecaBankMenu()
    StaffMenu.ListFleecaBank.Separator("BANQUES FLEECA EXISTANTES")

    local banks = TriggerServerCallback("core:fleeca:getBanks")

    if banks and #banks > 0 then
        for _, bank in ipairs(banks) do
            local statusText = ""
          if bank.active and bank.canRob then
                statusText = "Actif/Braquable"
          elseif bank.active then
                statusText = "Actif seulement"
          else
                statusText = "Inactif"
          end

            StaffMenu.ListFleecaBank.Button(":building: " .. bank.name, statusText, nil, "chevron", false, function()
                selectedFleecaBank = bank
            end, StaffMenu.EditFleecaBank)
        end
    else
        StaffMenu.ListFleecaBank.Button("Aucune banque Fleeca", "Créez-en une d'abord", nil, nil, true, function()
        end)
    end
end

-- Edit Fleeca Bank Menu
function StaffMenu.BuildEditFleecaBankMenu()
    if not selectedFleecaBank then
        StaffMenu.EditFleecaBank.Button(":x: ERREUR", "Banque non sélectionnée", nil, "arrow", true, function() end)
        return
    end

    local bank = selectedFleecaBank
    StaffMenu.EditFleecaBank.Separator("MODIFIER: " .. bank.name)

    StaffMenu.EditFleecaBank.Button(":pin: Se téléporter", ("%.1f, %.1f, %.1f"):format(bank.pos.x, bank.pos.y, bank.pos.z), nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), bank.pos.x, bank.pos.y, bank.pos.z, false, false, false, false)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Téléporté à " .. bank.name
        })
    end)

    -- Informations de base
    StaffMenu.EditFleecaBank.Button(":edit: CHANGER LE NOM", bank.name, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom de la banque", bank.name)
        if input and input ~= "" then
            TriggerServerEvent('core:fleeca:updateBank', bank.id, 'name', input)
            bank.name = input
            StaffMenu.EditFleecaBank.refresh()
        end
    end)

    StaffMenu.EditFleecaBank.Separator("STATUT")

    StaffMenu.EditFleecaBank.Checkbox(":check: ACTIVE", nil, false, bank.active, function(value)
        TriggerServerEvent('core:fleeca:updateBank', bank.id, 'active', value)
        bank.active = value
        StaffMenu.EditFleecaBank.refresh()
    end)

    StaffMenu.EditFleecaBank.Checkbox(":gun: BRAQUABLE", nil, false, bank.canRob, function(value)
        TriggerServerEvent('core:fleeca:updateBank', bank.id, 'canRob', value)
        bank.canRob = value
        StaffMenu.EditFleecaBank.refresh()
    end)

    StaffMenu.EditFleecaBank.Checkbox(":pin: BLIP SUR LA MAP", nil, false, bank.blipEnabled, function(value)
        TriggerServerEvent('core:fleeca:updateBank', bank.id, 'blipEnabled', value)
        bank.blipEnabled = value
        StaffMenu.EditFleecaBank.refresh()
    end)

    StaffMenu.EditFleecaBank.Separator("POSITIONS")

    StaffMenu.EditFleecaBank.Button(":building: REPOSITIONNER BANQUE", "Nouvelle position", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local newPos = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
        TriggerServerEvent('core:fleeca:updateBank', bank.id, 'pos', newPos)
        bank.pos = newPos
        StaffMenu.EditFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position banque mise à jour."
      })
    end)

    StaffMenu.EditFleecaBank.Button(":monitor: AJOUTER POINT D'ACCÈS", #bank.accountAccessPositions .. (#bank.accountAccessPositions > 1 and " définis" or " défini"), nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        table.insert(bank.accountAccessPositions, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        })

        TriggerServerEvent('core:fleeca:updateBank', bank.id, 'accountAccessPositions', bank.accountAccessPositions)
        StaffMenu.EditFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Point d'accès ajouté (#" .. #bank.accountAccessPositions .. ")."
      })
    end)

    if #bank.accountAccessPositions > 0 then
        StaffMenu.EditFleecaBank.Button(":trash: SUPPRIMER DERNIER POINT", "Retirer le dernier point d'accès", nil, "arrow", false, function()
            table.remove(bank.accountAccessPositions)
            TriggerServerEvent('core:fleeca:updateBank', bank.id, 'accountAccessPositions', bank.accountAccessPositions)
            StaffMenu.EditFleecaBank.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Dernier point d'accès supprimé (" .. #bank.accountAccessPositions .. (#bank.accountAccessPositions > 1 and " restants)." or " restant).")
          })
        end)
    end

    StaffMenu.EditFleecaBank.Button(":pin: POINT HACK PORTE", bank.doorHackPos and "Défini" or "Pas défini", nil, "arrow", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local newPos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        }
        TriggerServerEvent('core:fleeca:updateBank', bank.id, 'doorHackPos', newPos)
        bank.doorHackPos = newPos
        StaffMenu.EditFleecaBank.refresh()
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position hack porte mise à jour."
      })
    end)

    StaffMenu.EditFleecaBank.Button(":target: POSITION PORTE COFFRE", bank.vaultDoorPos and "Défini" or "Pas défini", nil, "arrow", false, function()
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            subtitle = 'Mode Builder',
            message = "Mode sélection activé - Visez la porte et appuyez sur E."
      })
        StaffMenu.EditFleecaBank.close()

        local entity, coords = SelectDoorVisually()

        if coords and entity then
            local newPos = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                model = GetEntityModel(entity)
            }
            TriggerServerEvent('core:fleeca:updateBank', bank.id, 'vaultDoorPos', newPos)
            bank.vaultDoorPos = newPos
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = string.format("Porte du coffre sélectionnée (%.2f, %.2f, %.2f) - Model: %d.", coords.x, coords.y, coords.z, newPos.model)
            })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Sélection annulée."
          })
        end

        StaffMenu.EditFleecaBank.open()
        StaffMenu.EditFleecaBank.refresh()
    end)

    -- Sortie d'urgence supprimée (plus utilisée)

    if bank.safePositions then
        StaffMenu.EditFleecaBank.Separator("COFFRES (" .. #bank.safePositions .. "/4)")

        for i = 1, 4 do
            if bank.safePositions[i] then
                StaffMenu.EditFleecaBank.Button(":lock: COFFRE #" .. i, "Repositionner", nil, "arrow", false, function()
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed)
                    local heading = GetEntityHeading(playerPed)
                    bank.safePositions[i] = {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        h = heading
                    }
                    TriggerServerEvent('core:fleeca:updateBank', bank.id, 'safePositions', bank.safePositions)
                    StaffMenu.EditFleecaBank.refresh()
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                        message = "Position coffre #" .. i .. " mise à jour."
                  })
                end)
            else
                StaffMenu.EditFleecaBank.Button(":plus: AJOUTER COFFRE #" .. i, "Position actuelle", nil, "arrow", false, function()
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed)
                    local heading = GetEntityHeading(playerPed)
                    bank.safePositions[i] = {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        h = heading
                    }
                    TriggerServerEvent('core:fleeca:updateBank', bank.id, 'safePositions', bank.safePositions)
                    StaffMenu.EditFleecaBank.refresh()
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                        message = "Coffre #" .. i .. " ajouté."
                  })
                end)
            end
        end
    end

    StaffMenu.EditFleecaBank.Separator("ACTIONS DANGEREUSES")

    StaffMenu.EditFleecaBank.Button(":trash: SUPPRIMER LA BANQUE", "Attention: Action irréversible", nil, "arrow", false, function()
        -- Confirmation dialog
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer définitivement cette banque", "")
        if confirm == "CONFIRMER" then
            TriggerServerEvent('core:fleeca:deleteBank', bank.id)
            StaffMenu.EditFleecaBank.close()
            StaffMenu.ListFleecaBank.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Banque Fleeca supprimée."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Suppression annulée."
          })
        end
    end)
end

-- Fleeca Settings Menu
function StaffMenu.BuildFleecaSettingsMenu()
    StaffMenu.FleecaSettings.Separator("CONFIGURATION GLOBALE FLEECA")

    local settings = TriggerServerCallback("core:fleeca:getSettings")

    if settings then
        StaffMenu.FleecaSettings.Button(":clock: COOLDOWN GLOBAL", settings.globalCooldown .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Cooldown global en minutes (actuel: " .. settings.globalCooldown .. ")", tostring(settings.globalCooldown))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'globalCooldown', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Cooldown global mis à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Button(":user: COOLDOWN JOUEUR", settings.playerCooldown .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Cooldown joueur en minutes (actuel: " .. settings.playerCooldown .. ")", tostring(settings.playerCooldown))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'playerCooldown', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Cooldown joueur mis à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Button(":police: POLICE MINIMUM", settings.minPoliceRequired .. " policiers", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de policiers (actuel: " .. settings.minPoliceRequired .. ")", tostring(settings.minPoliceRequired))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'minPoliceRequired', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Police minimum mise à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Separator("RÉCOMPENSES")

        StaffMenu.FleecaSettings.Button(":money: RÉCOMPENSE MIN COFFRE", VFW.Math.FormatMoney(settings.safeRewardMin), nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense minimum par coffre (actuel: " .. settings.safeRewardMin .. ")", tostring(settings.safeRewardMin))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'safeRewardMin', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense minimum mise à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Button(":money: RÉCOMPENSE MAX COFFRE", VFW.Math.FormatMoney(settings.safeRewardMax), nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense maximum par coffre (actuel: " .. settings.safeRewardMax .. ")", tostring(settings.safeRewardMax))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'safeRewardMax', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense maximum mise à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Separator("ITEMS ET TEMPS")

        StaffMenu.FleecaSettings.Button(":monitor: ITEM USB REQUIS", settings.requiredUsbItem, nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nom de l'item USB (actuel: " .. settings.requiredUsbItem .. ")", settings.requiredUsbItem)
            if input and input ~= "" then
                TriggerServerEvent('core:fleeca:updateSettings', 'requiredUsbItem', input)
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Item USB mis à jour."
              })
            end
        end)

        -- Durée hack supprimée (géré par le mini-jeu)
        -- Durée perçage supprimée (géré par le mini-jeu)

        StaffMenu.FleecaSettings.Button(":siren: DURÉE BLIP POLICE", settings.policeBlipDuration .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Durée du blip police en minutes (actuel: " .. settings.policeBlipDuration .. ")", tostring(settings.policeBlipDuration))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'policeBlipDuration', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Durée blip police mise à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Separator("PORTE DE COFFRE-FORT")

        -- Modèle de porte supprimé (toujours le même)

        StaffMenu.FleecaSettings.Button(":clock: DURÉE OUVERTURE PORTE", settings.doorOpenDuration .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Durée d'ouverture de la porte en minutes (actuel: " .. settings.doorOpenDuration .. ")", tostring(settings.doorOpenDuration))
            if input and tonumber(input) then
                TriggerServerEvent('core:fleeca:updateSettings', 'doorOpenDuration', tonumber(input))
                Wait(500)
                StaffMenu.FleecaSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Durée d'ouverture de porte mise à jour."
              })
            end
        end)

        StaffMenu.FleecaSettings.Separator("ACTIONS")

        StaffMenu.FleecaSettings.Button(":refresh: RECHARGER DEPUIS BDD", nil, nil, "arrow", false, function()
            TriggerServerEvent('core:fleeca:reloadSettings')
            Wait(500)
            StaffMenu.FleecaSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Paramètres rechargés depuis la BDD."
          })
        end)
    end
end

-- ========================
-- PACIFIC BANK BUILDER SYSTEM
-- ========================

-- Pacific Builder Menu
function StaffMenu.BuildPacificMenu()
    StaffMenu.builderPacific.Separator("PACIFIC STANDARD BANK - CONFIGURATION")

    StaffMenu.builderPacific.Button(":pin: CONFIGURER LES POSITIONS", "PC sécurité, coffres, portes, interactions...", nil, "chevron", false, function()
    end, StaffMenu.PacificPositions)

    StaffMenu.builderPacific.Button(":settings: PARAMÈTRES GLOBAUX", "Cooldowns, récompenses, etc.", nil, "chevron", false, function()
    end, StaffMenu.PacificSettings)

    StaffMenu.builderPacific.Separator("ACTIONS RAPIDES")

    StaffMenu.builderPacific.Button(":clock: RESET TIMER DE BRAQUAGE", "Réinitialise le cooldown et le timer de 15min", nil, "arrow", false, function()
        TriggerServerEvent('core:pacific:resetTimer')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Timer Pacific réinitialisé."
      })
    end)

    StaffMenu.builderPacific.Button(":refresh: RECHARGER PARAMÈTRES", "Recharge depuis la base de données", nil, "arrow", false, function()
        TriggerServerEvent('core:pacific:requestSettings')
        Wait(500)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Paramètres rechargés."
      })
    end)
end

-- Pacific Settings Menu
local pacificSettingsCache = nil
function StaffMenu.BuildPacificSettingsMenu()
    StaffMenu.PacificSettings.Separator("CONFIGURATION PACIFIC STANDARD BANK")

    -- Utiliser le cache ou récupérer les settings
    if not pacificSettingsCache then
        pacificSettingsCache = TriggerServerCallback("core:pacific:getSettings")
    end
    local settings = pacificSettingsCache

    if settings then
        StaffMenu.PacificSettings.Button(":clock: COOLDOWN GLOBAL", settings.globalCooldown .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Cooldown global en minutes (actuel: " .. settings.globalCooldown .. ")", tostring(settings.globalCooldown))
            if input and tonumber(input) then
                TriggerServerEvent('core:pacific:updateSettings', 'globalCooldown', tonumber(input))
                pacificSettingsCache = nil -- Vider le cache après modification
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Cooldown global mis à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Button(":police: POLICE MINIMUM", settings.minPoliceRequired .. " policiers", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de policiers (actuel: " .. settings.minPoliceRequired .. ")", tostring(settings.minPoliceRequired))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'minPoliceRequired', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Police minimum mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Separator("GRANDS COFFRES (VAULT)")

        StaffMenu.PacificSettings.Button(":money: RÉCOMPENSE MIN GRAND COFFRE", settings.safeRewardMin .. "x dirty_money", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense minimum par grand coffre (actuel: " .. settings.safeRewardMin .. ")", tostring(settings.safeRewardMin))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'safeRewardMin', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense minimum mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Button(":money: RÉCOMPENSE MAX GRAND COFFRE", settings.safeRewardMax .. "x dirty_money", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense maximum par grand coffre (actuel: " .. settings.safeRewardMax .. ")", tostring(settings.safeRewardMax))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'safeRewardMax', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense maximum mise à jour."
              })
            end
        end)

        -- Durée perçage grand coffre supprimée (géré par le mini-jeu)

        StaffMenu.PacificSettings.Separator("PETITS COFFRES (SANS CODE)")

        StaffMenu.PacificSettings.Button(":money: RÉCOMPENSE MIN PETIT COFFRE", settings.smallSafeRewardMin .. "x dirty_money", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense minimum par petit coffre (actuel: " .. settings.smallSafeRewardMin .. ")", tostring(settings.smallSafeRewardMin))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'smallSafeRewardMin', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense minimum petit coffre mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Button(":money: RÉCOMPENSE MAX PETIT COFFRE", settings.smallSafeRewardMax .. "x dirty_money", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense maximum par petit coffre (actuel: " .. settings.smallSafeRewardMax .. ")", tostring(settings.smallSafeRewardMax))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'smallSafeRewardMax', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense maximum petit coffre mise à jour."
              })
            end
        end)

        -- Durée perçage petit coffre supprimée (géré par le mini-jeu)

        StaffMenu.PacificSettings.Separator("LINGOTS D'OR")

        StaffMenu.PacificSettings.Button(":trophy: RÉCOMPENSE MIN LINGOTS", settings.goldRewardMin .. "x gold_bar", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense minimum lingots d'or (actuel: " .. settings.goldRewardMin .. ")", tostring(settings.goldRewardMin))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'goldRewardMin', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense minimum lingots mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Button(":trophy: RÉCOMPENSE MAX LINGOTS", settings.goldRewardMax .. "x gold_bar", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Récompense maximum lingots d'or (actuel: " .. settings.goldRewardMax .. ")", tostring(settings.goldRewardMax))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'goldRewardMax', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Récompense maximum lingots mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Separator("SÉCURITÉ & TEMPS")

        StaffMenu.PacificSettings.Button(":lock: CODE D'ACCÈS", settings.accessCode, nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Code alphanumérique (actuel: " .. settings.accessCode .. ")", settings.accessCode)
            if input and input ~= "" and input:match("^[a-zA-Z0-9]+$") then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'accessCode', input)
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Code d'accès mis à jour: " .. input .. "."
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                    message = "Le code doit contenir uniquement des lettres et/ou des chiffres."
              })
            end
        end)

        StaffMenu.PacificSettings.Button(":siren: DURÉE BLIP POLICE", settings.policeBlipDuration .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Durée du blip police en minutes (actuel: " .. settings.policeBlipDuration .. ")", tostring(settings.policeBlipDuration))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'policeBlipDuration', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Durée blip police mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Button(":clock: DURÉE OUVERTURE PORTE VAULT", settings.doorOpenDuration .. " minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Durée d'ouverture de la porte vault en minutes (actuel: " .. settings.doorOpenDuration .. ")", tostring(settings.doorOpenDuration))
            if input and tonumber(input) then
                pacificSettingsCache = nil
                TriggerServerEvent('core:pacific:updateSettings', 'doorOpenDuration', tonumber(input))
                Wait(500)
                StaffMenu.PacificSettings.refresh()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Durée d'ouverture porte vault mise à jour."
              })
            end
        end)

        StaffMenu.PacificSettings.Separator("INFORMATIONS")

        StaffMenu.PacificSettings.Button(":info: SYSTÈME ACTUEL", "1 banque unique hardcodée", nil, nil, true, function() end)
        StaffMenu.PacificSettings.Button(":info: TIMER BRAQUAGE", "15min après premier code", nil, nil, true, function() end)
        StaffMenu.PacificSettings.Button(":info: PETITS COFFRES", "20 coffres sans accès code", nil, nil, true, function() end)
        StaffMenu.PacificSettings.Button(":info: GRANDS COFFRES", "6 coffres dans le vault", nil, nil, true, function() end)

        StaffMenu.PacificSettings.Separator("ACTIONS")

        StaffMenu.PacificSettings.Button(":refresh: RECHARGER DEPUIS BDD", nil, nil, "arrow", false, function()
            pacificSettingsCache = nil -- Vider le cache
            TriggerServerEvent('core:pacific:requestSettings')
            Wait(500)
            StaffMenu.PacificSettings.refresh()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Paramètres rechargés depuis la BDD."
          })
        end)
    end
end

-- ============================================
-- PACIFIC BANK - CONFIGURATION DES POSITIONS
-- ============================================

-- Cache local des positions (partagé entre les sous-menus)
local pacificPositionsCache = nil

-- Positions "uniques" configurables (une position, avec ou sans heading)
local PACIFIC_SINGLE_POSITIONS = {
    { key = "securityPC",        label = ":computer: PC SÉCURITÉ",              heading = true,  desc = "Poste de hack du PC de sécurité (Porte 1)" },
    { key = "computer",          label = ":computer: ORDINATEUR CENTRAL",       heading = true,  desc = "Hack ordinateur (déverrouille les petits coffres)" },
    { key = "vault",             label = ":lock: NUMPAD COFFRE PRINCIPAL",      heading = true,  desc = "Interaction du coffre-fort (vault)" },
    { key = "entryNumpad",       label = ":lock: NUMPAD ENTRÉE",                heading = true,  desc = "Terminal d'entrée du braquage" },
    { key = "door1",             label = ":door: PORTE PC SÉCURITÉ (POS)",      heading = true,  desc = "Position de la Porte 1 (PC sécurité)" },
    { key = "goldCart",          label = ":trophy: CHARIOT LINGOTS OR",         heading = true,  desc = "Point de collecte des lingots d'or" },
    { key = "blip",              label = ":pin: BLIP BANQUE (CARTE)",           heading = false, desc = "Position du blip de la banque sur la carte" },
    { key = "alarm",             label = ":siren: POSITION ALARME POLICE", heading = false, desc = "Point d'alerte de la police (serveur)" },
    { key = "numpadMarker",      label = ":target: MARKER NUMPAD ENTRÉE", heading = false, desc = "Marker visuel du numpad d'entrée" },
    { key = "computerMarker",    label = ":target: MARKER ORDINATEUR",    heading = false, desc = "Marker visuel de l'ordinateur" },
    { key = "vaultNumpadMarker", label = ":target: MARKER NUMPAD VAULT",  heading = false, desc = "Marker visuel du numpad du coffre-fort" },
    { key = "vaultDoorMarker",   label = ":target: MARKER PORTE VAULT",   heading = false, desc = "Marker visuel de la porte du coffre-fort" },
    { key = "entryDoorMarker",   label = ":target: MARKER PORTE ENTRÉE",  heading = false, desc = "Marker visuel de la porte d'entrée" },
}

-- Libellés des 9 portes (l'index = l'id DoorSystem attendu par la logique, ne pas réordonner)
local PACIFIC_DOOR_LABELS = {
    "Porte entrée principale",
    "Porte salle des coffres",
    "Porte couloir (3)",
    "Porte couloir (4)",
    "Porte couloir (5)",
    "Porte couloir (6)",
    "Porte couloir (7)",
    "Porte couloir (8)",
    "Porte PC Sécurité",
}

local function FormatPacificPos(p)
    if type(p) ~= "table" or not p.x then return "Défaut (non configuré)" end
    local base = string.format("%.2f, %.2f, %.2f", p.x, p.y, p.z)
    if p.heading then base = base .. " | H " .. string.format("%.1f", p.heading) end
    return base
end

local function GetPacificPlayerPos(withHeading)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local pos = {
        x = math.floor(c.x * 1000) / 1000,
        y = math.floor(c.y * 1000) / 1000,
        z = math.floor(c.z * 1000) / 1000,
    }
    if withHeading then
        pos.heading = math.floor(GetEntityHeading(ped) * 100) / 100
    end
    return pos
end

local function LoadPacificPositions()
    if not pacificPositionsCache then
        pacificPositionsCache = TriggerServerCallback("core:pacific:getPositions") or {}
    end
    return pacificPositionsCache
end

local function SavePacificPositions()
    -- Sauvegarde immédiate (le serveur persiste + resynchronise tous les clients)
    TriggerServerEvent("core:pacific:updatePositions", pacificPositionsCache)
end

function StaffMenu.BuildPacificPositionsMenu()
    StaffMenu.PacificPositions.ClearItems()
    local pos = LoadPacificPositions()

    StaffMenu.PacificPositions.Separator("POSITIONS D'INTERACTION")
    for _, def in ipairs(PACIFIC_SINGLE_POSITIONS) do
        StaffMenu.PacificPositions.Button(def.label, def.desc .. ". Cliquez pour enregistrer votre position actuelle", FormatPacificPos(pos[def.key]), "chevron", false, function()
            pos[def.key] = GetPacificPlayerPos(def.heading)
            SavePacificPositions()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Pacific', message = "Position enregistrée." })
            StaffMenu.PacificPositions.refresh()
        end)
    end

    StaffMenu.PacificPositions.Separator("COFFRES & PORTES")
    StaffMenu.PacificPositions.Button(":safe: PETITS COFFRES", "Positions des petits coffres", "(" .. (pos.smallSafes and #pos.smallSafes or 0) .. ")", "chevron", false, function()
    end, StaffMenu.PacificSmallSafes)
    StaffMenu.PacificPositions.Button(":safe: GRANDS COFFRES", "Positions des grands coffres (vault)", "(" .. (pos.bigSafes and #pos.bigSafes or 0) .. ")", "chevron", false, function()
    end, StaffMenu.PacificBigSafes)
    StaffMenu.PacificPositions.Button(":door: PORTES SÉCURISÉES", "Coordonnées des 9 portes", nil, "chevron", false, function()
    end, StaffMenu.PacificDoors)

    StaffMenu.PacificPositions.Separator("ACTIONS")
    StaffMenu.PacificPositions.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge les positions enregistrées", nil, "arrow", false, function()
        pacificPositionsCache = nil
        TriggerServerEvent("core:pacific:reloadPositions")
        Wait(400)
        StaffMenu.PacificPositions.refresh()
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Builder Pacific', message = "Positions rechargées." })
    end)
end

local function BuildPacificSafeListMenu(menu, listKey)
    menu.ClearItems()
    local pos = LoadPacificPositions()
    pos[listKey] = pos[listKey] or {}

    menu.Separator("COFFRES (" .. #pos[listKey] .. ")")
    menu.Button(":plus: AJOUTER MA POSITION", "Ajoute un coffre à ta position/heading actuels", nil, "chevron", false, function()
        table.insert(pos[listKey], GetPacificPlayerPos(true))
        SavePacificPositions()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Pacific', message = "Coffre ajouté (#" .. #pos[listKey] .. ")." })
        menu.refresh()
    end)
    menu.Button(":minus: RETIRER LE DERNIER", "Supprime le dernier coffre ajouté", nil, "arrow", false, function()
        if #pos[listKey] > 0 then
            table.remove(pos[listKey])
            SavePacificPositions()
            menu.refresh()
        end
    end)
    menu.Button(":trash: TOUT VIDER", "Réinitialise la liste (positions par défaut au restart)", nil, "arrow", false, function()
        pos[listKey] = {}
        SavePacificPositions()
        menu.refresh()
    end)

    menu.Separator("LISTE")
    for i, s in ipairs(pos[listKey]) do
        menu.Button("Coffre #" .. i, FormatPacificPos(s), nil, nil, true, function() end)
    end
end

function StaffMenu.BuildPacificSmallSafesMenu()
    BuildPacificSafeListMenu(StaffMenu.PacificSmallSafes, "smallSafes")
end

function StaffMenu.BuildPacificBigSafesMenu()
    BuildPacificSafeListMenu(StaffMenu.PacificBigSafes, "bigSafes")
end

function StaffMenu.BuildPacificDoorsMenu()
    StaffMenu.PacificDoors.ClearItems()
    local pos = LoadPacificPositions()
    pos.doors = pos.doors or {}

    StaffMenu.PacificDoors.Separator("PORTES SÉCURISÉES (coordonnées)")
    for i, label in ipairs(PACIFIC_DOOR_LABELS) do
        local cur = pos.doors[tostring(i)] or pos.doors[i]
        StaffMenu.PacificDoors.Button(":door: " .. label, "[Clic] enregistre ta position pour cette porte", FormatPacificPos(cur), "chevron", false, function()
            pos.doors[tostring(i)] = GetPacificPlayerPos(false)
            SavePacificPositions()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Pacific', message = label .. " enregistrée." })
            StaffMenu.PacificDoors.refresh()
        end)
    end

    StaffMenu.PacificDoors.Separator("ACTIONS")
    StaffMenu.PacificDoors.Button(":trash: RÉINITIALISER LES PORTES", "Revient aux coordonnées par défaut (au restart)", nil, "arrow", false, function()
        pos.doors = {}
        SavePacificPositions()
        StaffMenu.PacificDoors.refresh()
    end)
end

-- ===========================================
-- BURGLARY SYSTEM BUILDER
-- ===========================================

local burglaryData = {
    name = "",
    interiorId = 1,
    active = true,
    blipEnabled = false
}

local burglaryHouses = {}
local burglaryInteriors = {}
local burglarySettings = {}

-- Load burglary data (synchronous)
local function LoadBurglaryData()
    local houses = TriggerServerCallback("core:burglary:getHouses")
    local interiors = TriggerServerCallback("core:burglary:getInteriors")
    local settings = TriggerServerCallback("core:burglary:getSettings")

    if houses then burglaryHouses = houses end
    if interiors then burglaryInteriors = interiors end
    if settings then burglarySettings = settings end
end

-- Burglary Builder Main Menu
function StaffMenu.BuildBurglaryMenu()
    StaffMenu.builderBurglary.ClearItems()
    LoadBurglaryData()

    StaffMenu.builderBurglary.Separator("GESTION DES MAISONS")

    StaffMenu.builderBurglary.Button(":plus: CRÉER UNE MAISON", "Créer une nouvelle maison cambriolable", nil, "chevron", false, function()
    end, StaffMenu.CreateBurglaryHouse)

    StaffMenu.builderBurglary.Button(":report: LISTE DES MAISONS", "Gérer les maisons existantes", nil, "chevron", false, function()
    end, StaffMenu.ListBurglaryHouses)

    StaffMenu.builderBurglary.Separator("CONFIGURATION")

    StaffMenu.builderBurglary.Button(":settings: PARAMÈTRES SYSTÈME", "Configuration globale du système", nil, "chevron", false, function()
    end, StaffMenu.BurglarySettings)

    StaffMenu.builderBurglary.Button(":refresh: RESET COOLDOWNS", "Réinitialiser tous les cooldowns", nil, "arrow", false, function()
        TriggerServerEvent('core:burglary:resetCooldowns')
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Cooldowns réinitialisés."
      })
    end)
end

-- Create Burglary House Menu
function StaffMenu.BuildCreateBurglaryHouseMenu()
    StaffMenu.CreateBurglaryHouse.Separator("CRÉATION D'UNE MAISON")

    -- House name
    StaffMenu.CreateBurglaryHouse.Button(":edit: NOM DE LA MAISON", burglaryData.name ~= "" and burglaryData.name or "Non défini", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la maison (ex: Villa Rockford)", burglaryData.name)
        if input and input ~= "" then
            burglaryData.name = input
            StaffMenu.CreateBurglaryHouse.refresh()
        end
    end)

    -- Position (current position)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    StaffMenu.CreateBurglaryHouse.Button(":pin: POSITION D'ENTRÉE", string.format("X: %.2f, Y: %.2f, Z: %.2f", coords.x, coords.y, coords.z), "Position actuelle du joueur", "arrow", false, function()
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            subtitle = 'Builder',
            message = "Position définie à votre emplacement actuel."
      })
    end)

    -- Sélection d'intérieur
    local selectedIplData = GetIPLByName(selectedIPL)
    local selectedDisplayName = selectedIplData and selectedIplData.displayName or "Aucun"
  StaffMenu.CreateBurglaryHouse.Button(":home: INTÉRIEUR",
        selectedIPL ~= "" and selectedDisplayName or "Aucun intérieur sélectionné",
        "Cliquer pour choisir un intérieur",
        "chevron", false, function()
        end, StaffMenu.SelectIPL)

    -- Settings
    StaffMenu.CreateBurglaryHouse.Checkbox(":check: MAISON ACTIVE", "La maison sera accessible aux joueurs", false, burglaryData.active, function(checked)
        burglaryData.active = checked
    end)

    StaffMenu.CreateBurglaryHouse.Checkbox(":pin: BLIP VISIBLE", "Afficher un blip sur la carte", false, burglaryData.blipEnabled, function(checked)
        burglaryData.blipEnabled = checked
    end)

    StaffMenu.CreateBurglaryHouse.Separator("ACTIONS")

    -- Create button
    local canCreate = burglaryData.name ~= "" and selectedIPL ~= ""
  StaffMenu.CreateBurglaryHouse.Button(":check: CRÉER LA MAISON", nil, nil, "arrow", not canCreate, function()
        if not canCreate then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Veuillez remplir tous les champs obligatoires."
          })
            return
        end

        local houseData = {
            name = burglaryData.name,
            entryPos = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                h = heading
            },
            selectedIPL = selectedIPL, -- Utiliser l'IPL sélectionné au lieu de interiorId
            active = burglaryData.active,
            blipEnabled = burglaryData.blipEnabled
        }

        TriggerServerEvent('core:burglary:createHouse', houseData)

        -- Attendre que le serveur crée la maison puis recharger les données
        Wait(500)
        LoadBurglaryData()

        -- Reset form
        burglaryData = {
            name = "",
            active = true,
            blipEnabled = false
        }
        selectedIPL = "" -- Réinitialiser aussi l'IPL sélectionné

        StaffMenu.CreateBurglaryHouse.refresh()

        -- Rafraîchir aussi la liste si elle existe
        if StaffMenu.ListBurglaryHouses and StaffMenu.ListBurglaryHouses.refresh then
            StaffMenu.ListBurglaryHouses.refresh()
        end
    end)

    StaffMenu.CreateBurglaryHouse.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StaffMenu.builderBurglary.refresh()
    end)
end

-- List Burglary Houses Menu
function StaffMenu.BuildListBurglaryHousesMenu()
    LoadBurglaryData()

    StaffMenu.ListBurglaryHouses.Separator("MAISONS CAMBRIOLABLES")

    if next(burglaryHouses) == nil then
        StaffMenu.ListBurglaryHouses.Button(":x: AUCUNE MAISON TROUVÉE", "Créez d'abord une maison", nil, "arrow", true, function() end)
    else
        for id, house in pairs(burglaryHouses) do
            local status = house.active and ":dot-green: ACTIVE" or ":dot-red: INACTIVE"
          local blipStatus = house.blipEnabled and " :pin:" or ""

          StaffMenu.ListBurglaryHouses.Button(
                house.name .. " " .. status .. blipStatus,
                string.format("ID: %s | Intérieur: %s", tostring(id), tostring(house.interiorId or "Non défini")),
                nil, "chevron", false,
                function()
                    StaffMenu.selectedBurglaryHouse = id
                end,
                StaffMenu.EditBurglaryHouse
            )
        end
    end

    StaffMenu.ListBurglaryHouses.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StaffMenu.builderBurglary.refresh()
    end)
end

-- Edit Burglary House Menu
function StaffMenu.BuildEditBurglaryHouseMenu()
    local houseId = StaffMenu.selectedBurglaryHouse
    local house = burglaryHouses[houseId]

    if not house then
        StaffMenu.EditBurglaryHouse.Button(":x: MAISON INTROUVABLE", nil, nil, "arrow", true, function() end)
        return
    end

    StaffMenu.EditBurglaryHouse.Separator("ÉDITION: " .. house.name)

    -- Edit name
    StaffMenu.EditBurglaryHouse.Button(":edit: MODIFIER LE NOM", house.name, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom de la maison", house.name)
        if input and input ~= "" and input ~= house.name then
            TriggerServerEvent('core:burglary:updateHouse', houseId, 'name', input)
            Wait(500)
            LoadBurglaryData()
            StaffMenu.EditBurglaryHouse.refresh()
        end
    end)

    -- Teleport to house
    StaffMenu.EditBurglaryHouse.Button(":pin: SE TÉLÉPORTER",
        string.format("X: %.1f, Y: %.1f, Z: %.1f", house.entryPos.x, house.entryPos.y, house.entryPos.z),
        nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), house.entryPos.x, house.entryPos.y, house.entryPos.z)
        SetEntityHeading(PlayerPedId(), house.entryPos.h or 0.0)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Téléporté à la maison " .. house.name .. "."
      })
    end)

    -- Update position
    StaffMenu.EditBurglaryHouse.Button(":target: METTRE À JOUR LA POSITION", "Position actuelle du joueur", nil, "arrow", false, function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local newPos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        }

        TriggerServerEvent('core:burglary:updateHouse', houseId, 'entryPos', newPos)
        Wait(500)
        LoadBurglaryData()
        StaffMenu.EditBurglaryHouse.refresh()
    end)

    -- Toggle active
    StaffMenu.EditBurglaryHouse.Checkbox(":check: MAISON ACTIVE", "La maison sera accessible aux joueurs", false, house.active, function(checked)
        TriggerServerEvent('core:burglary:updateHouse', houseId, 'active', checked)
    end)

    -- Toggle blip
    StaffMenu.EditBurglaryHouse.Checkbox(":pin: BLIP VISIBLE", "Afficher un blip sur la carte", false, house.blipEnabled, function(checked)
        TriggerServerEvent('core:burglary:updateHouse', houseId, 'blipEnabled', checked)
    end)

    StaffMenu.EditBurglaryHouse.Separator("ACTIONS DANGEREUSES")

    -- Delete house (double-clic pour confirmer)
    StaffMenu.EditBurglaryHouse.Button(":trash: SUPPRIMER LA MAISON", ":warning: Cliquez 2 fois pour confirmer", nil, "arrow", false, function()
        if not house.confirmDelete then
            house.confirmDelete = true
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Cliquez à nouveau pour confirmer la suppression."
          })
            SetTimeout(5000, function()
                if house then house.confirmDelete = false end
            end)
        else
            TriggerServerEvent('core:burglary:deleteHouse', houseId)
            Wait(500)
            LoadBurglaryData()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Maison supprimée."
          })
            StaffMenu.EditBurglaryHouse.close()
            Wait(100)
            StaffMenu.ListBurglaryHouses.open()
        end
    end)

    StaffMenu.EditBurglaryHouse.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StaffMenu.ListBurglaryHouses.refresh()
    end)
end

-- List Burglary Interiors Menu

-- Burglary Settings Menu
function StaffMenu.BuildBurglarySettingsMenu()
    LoadBurglaryData()

    if not burglarySettings or not burglarySettings.robbery_duration then
        StaffMenu.BurglarySettings.Separator(":hourglass: CHARGEMENT...")
        StaffMenu.BurglarySettings.Button(":refresh: RAFRAÎCHIR", "Cliquez pour recharger les données", nil, "arrow", false, function()
            LoadBurglaryData()
            Wait(500)
            StaffMenu.BurglarySettings.refresh()
        end)
        return
    end

    StaffMenu.BurglarySettings.Separator("PARAMÈTRES DU SYSTÈME")

    -- Robbery duration
    StaffMenu.BurglarySettings.Button(":clock: DURÉE CAMBRIOLAGE", (burglarySettings.robbery_duration or 300) .. " secondes", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée en secondes", tostring(burglarySettings.robbery_duration))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'robbery_duration', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    -- Post-robbery duration
    local postRobberyDuration = burglarySettings.post_robbery_duration or 300
    local postMinutes = math.floor(postRobberyDuration / 60)
    local postSeconds = postRobberyDuration % 60
    local postText = postMinutes > 0 and (postMinutes .. " min " .. postSeconds .. "s") or (postSeconds .. " secondes")

    StaffMenu.BurglarySettings.Button(":door: DURÉE POST-CAMBRIOLAGE", postText, "Temps où la maison reste 'cambriolée' après le braquage", "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée en secondes", tostring(postRobberyDuration))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'post_robbery_duration', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    -- Cooldown duration
    local cooldownMinutes = math.floor((burglarySettings.cooldown_duration or 7200) / 60)

    StaffMenu.BurglarySettings.Button(":clock: COOLDOWN", cooldownMinutes .. " min", "Temps avant de pouvoir re-cambrioler la même maison", "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown en minutes", tostring(cooldownMinutes))
        if input and tonumber(input) then
            local newCooldown = tonumber(input) * 60
            TriggerServerEvent('core:burglary:updateSettings', 'cooldown_duration', newCooldown)

            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Builder',
                message = string.format("Cooldown configuré: %d min.", tonumber(input))
            })

            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    -- Min police required
    StaffMenu.BurglarySettings.Button(":police: POLICE MINIMUM", tostring(burglarySettings.min_police_required or 2), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de policiers", tostring(burglarySettings.min_police_required))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'min_police_required', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    StaffMenu.BurglarySettings.Separator("GESTION DES POINTS DE LOOT")

    StaffMenu.BurglarySettings.Button(":box: POINTS MIN", tostring(burglarySettings.min_loot_points or 1), "Minimum de points de loot par cambriolage", "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum de points de loot", tostring(burglarySettings.min_loot_points or 1))
        if input and tonumber(input) and tonumber(input) > 0 then
            TriggerServerEvent('core:burglary:updateSettings', 'min_loot_points', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    StaffMenu.BurglarySettings.Button(":box: POINTS MAX", tostring(burglarySettings.max_loot_points or 5), "Maximum de points de loot par cambriolage", "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre maximum de points de loot", tostring(burglarySettings.max_loot_points or 5))
        if input and tonumber(input) and tonumber(input) > 0 then
            TriggerServerEvent('core:burglary:updateSettings', 'max_loot_points', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    -- Money rewards
    StaffMenu.BurglarySettings.Button(":money: ARGENT MIN", VFW.Math.FormatMoney(burglarySettings.dirty_money_min or 500), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant minimum d'argent sale", tostring(burglarySettings.dirty_money_min))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'dirty_money_min', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    StaffMenu.BurglarySettings.Button(":money: ARGENT MAX", VFW.Math.FormatMoney(burglarySettings.dirty_money_max or 2000), nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant maximum d'argent sale", tostring(burglarySettings.dirty_money_max))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'dirty_money_max', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    -- Police alert delay
    StaffMenu.BurglarySettings.Button(":siren: DÉLAI ALERTE POLICE", (burglarySettings.police_alert_delay or 30) .. " secondes", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Délai avant alerte police (secondes)", tostring(burglarySettings.police_alert_delay))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'police_alert_delay', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    -- Daily limit per player
    local dailyLimit = tonumber(burglarySettings.daily_limit_per_player) or 0
    local dailyLimitLabel = (dailyLimit <= 0) and "Illimité" or (dailyLimit .. " / jour")
    StaffMenu.BurglarySettings.Button(":calendar: LIMITE PAR JOUEUR", dailyLimitLabel, "Nombre max de cambriolages par joueur par jour (0 = illimité)", "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Limite quotidienne par joueur (0 = illimité)", tostring(dailyLimit))
        if input and tonumber(input) then
            TriggerServerEvent('core:burglary:updateSettings', 'daily_limit_per_player', tonumber(input))
            Wait(500)
            LoadBurglaryData()
            StaffMenu.BurglarySettings.refresh()
        end
    end)

    StaffMenu.BurglarySettings.Separator("ACTIONS")

    StaffMenu.BurglarySettings.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StaffMenu.builderBurglary.refresh()
    end)
end

-- Select IPL Menu
function StaffMenu.BuildSelectIPLMenu()
    -- Afficher l'IPL sélectionné en haut
    if selectedIPL ~= "" then
        local selectedIplData = GetIPLByName(selectedIPL)
        local displayName = selectedIplData and selectedIplData.displayName or selectedIPL
        StaffMenu.SelectIPL.Separator(":check: SÉLECTIONNÉ: " .. displayName)
    else
        StaffMenu.SelectIPL.Separator("SÉLECTION D'INTÉRIEUR")
    end

    -- Grouper les IPL par catégorie avec un ordre spécifique
    local categoryOrder = {"Appartements", "Maisons", "Bureaux", "Entrepôts", "Bunkers", "Standard"}
    local categories = {}

    for _, ipl in ipairs(AvailableIPLs) do
        local category = ipl.category
        if not categories[category] then
            categories[category] = {}
        end
        table.insert(categories[category], ipl)
    end

    -- Afficher par catégorie dans l'ordre défini
    for _, categoryName in ipairs(categoryOrder) do
        local ipls = categories[categoryName]
        if ipls and #ipls > 0 then
            StaffMenu.SelectIPL.Separator(":home: " .. categoryName)

            for _, ipl in ipairs(ipls) do
                local isSelected = selectedIPL == ipl.name
                local isPreviewing = previewingIPL == ipl.name

                -- Icône de statut
                local statusIcon = ""
              if isSelected then
                    statusIcon = ":check: "
              elseif isPreviewing then
                    statusIcon = ":eye: "
              end

                local buttonText = statusIcon .. ipl.displayName
                local hasPreview = ipl.previewPos ~= nil
                local previewText = hasPreview and "Cliquer pour sélectionner" or "Cliquer pour sélectionner"

              -- Bouton principal - clic = sélectionner directement
                StaffMenu.SelectIPL.Button(buttonText, previewText, nil, "arrow", false, function()
                    -- Sélectionner cet IPL directement
                    selectedIPL = ipl.name

                    -- Stocker aussi pour d'éventuelles prévisualisations
                    StaffMenu.currentPreviewIPL = ipl

                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                        message = "Sélectionné: " .. ipl.displayName .. "."
                  })

                    -- Rafraîchir les menus
                    StaffMenu.SelectIPL.refresh()
                    if StaffMenu.CreateBurglaryHouse and StaffMenu.CreateBurglaryHouse.refresh then
                        StaffMenu.CreateBurglaryHouse.refresh()
                    end
                end)
            end
        end
    end

    StaffMenu.SelectIPL.Separator("ACTIONS")

    -- Bouton de prévisualisation rapide si pas d'IPL sélectionné
    if selectedIPL == "" and previewingIPL == "" then
        StaffMenu.SelectIPL.Button(":eye: PRÉVISUALISER UN INTÉRIEUR", "Voir un intérieur sans le sélectionner", nil, "arrow", false, function()
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Builder',
                message = "Cliquez sur un intérieur puis 'Prévisualiser' pour le voir."
          })
        end)
    end

    -- Arrêter la prévisualisation
    if previewingIPL ~= "" and previewingIPL ~= selectedIPL then
        local previewIplData = GetIPLByName(previewingIPL)
        local previewName = previewIplData and previewIplData.displayName or previewingIPL
        StaffMenu.SelectIPL.Button(" ARRÊTER PRÉVISUALISATION", "Actuellement: " .. previewName, nil, "arrow", false, function()
            StopPreview()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Prévisualisation arrêtée."
          })
            StaffMenu.SelectIPL.refresh()
        end)
    end

    -- Désélectionner
    if selectedIPL ~= "" then
        StaffMenu.SelectIPL.Button(":x: DÉSÉLECTIONNER", "Retirer la sélection actuelle", nil, "arrow", false, function()
            -- Décharger l'IPL actuel (sauf si c'est le défaut)
            if selectedIPL ~= "" and selectedIPL ~= "_default_" then
                TriggerEvent("core:burglary:unloadIPL", selectedIPL)
            end
            StopPreview()

            selectedIPL = ""
          VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Sélection supprimée."
          })

            -- Rafraîchir les menus
            StaffMenu.SelectIPL.refresh()
            if StaffMenu.CreateBurglaryHouse and StaffMenu.CreateBurglaryHouse.refresh then
                StaffMenu.CreateBurglaryHouse.refresh()
            end
        end)

        StaffMenu.SelectIPL.Button(":rocket: SE TÉLÉPORTER", "Aller à l'intérieur sélectionné", nil, "arrow", false, function()
            TeleportToIPL(selectedIPL)
        end)

        StaffMenu.SelectIPL.Button(":map: EXPLORER", "Mode exploration pour ajuster les positions", nil, "chevron", false, function()
        end, StaffMenu.ExploreIPL)
    end

    StaffMenu.SelectIPL.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StopPreview()
        if StaffMenu.CreateBurglaryHouse then
            StaffMenu.CreateBurglaryHouse.refresh()
        end
    end)
end

-- Preview IPL Detail Menu (sous-menu pour prévisualiser un IPL spécifique)
function StaffMenu.BuildPreviewIPLDetailMenu()
    local ipl = StaffMenu.currentPreviewIPL

    if not ipl then
        StaffMenu.PreviewIPLDetail.Button(":x: ERREUR", "Aucun intérieur à prévisualiser", nil, "arrow", true, function() end)
        return
    end

    local isSelected = selectedIPL == ipl.name
    local isPreviewing = previewingIPL == ipl.name

    StaffMenu.PreviewIPLDetail.Separator(":pin: " .. ipl.displayName)

    -- Statut actuel
    if isSelected then
        StaffMenu.PreviewIPLDetail.Button(":check: STATUT", "Cet intérieur est sélectionné", nil, "arrow", true, function() end)
    elseif isPreviewing then
        StaffMenu.PreviewIPLDetail.Button(":eye: STATUT", "Prévisualisation en cours", nil, "arrow", true, function() end)
    end

    StaffMenu.PreviewIPLDetail.Separator("ACTIONS")

    -- Prévisualiser (téléporter dedans)
    StaffMenu.PreviewIPLDetail.Button(":eye: PRÉVISUALISER", "Charger et se téléporter dans cet intérieur", nil, "arrow", false, function()
        PreviewIPL(ipl)
        StaffMenu.PreviewIPLDetail.refresh()
        StaffMenu.SelectIPL.refresh()
    end)

    -- Sélectionner
    if not isSelected then
        StaffMenu.PreviewIPLDetail.Button(":check: SÉLECTIONNER", "Choisir cet intérieur pour la maison", nil, "arrow", false, function()
            selectedIPL = ipl.name
            StopPreview()

            if ipl.name ~= "" and ipl.name ~= "_default_" then
                TriggerEvent("core:burglary:loadIPL", ipl.name)
            end

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Sélectionné: " .. ipl.displayName .. "."
          })

            StaffMenu.PreviewIPLDetail.refresh()
            StaffMenu.SelectIPL.refresh()
            if StaffMenu.CreateBurglaryHouse and StaffMenu.CreateBurglaryHouse.refresh then
                StaffMenu.CreateBurglaryHouse.refresh()
            end
        end)
    end

    -- Sélectionner ET se téléporter
    local canTeleport = ipl.previewPos ~= nil
    StaffMenu.PreviewIPLDetail.Button(":check::eye: SÉLECTIONNER + TP", canTeleport and "Sélectionner et se téléporter dedans" or "Pas de prévisualisation disponible", nil, "arrow", not canTeleport, function()
        selectedIPL = ipl.name
        StopPreview()

        if ipl.name ~= "" and ipl.name ~= "_default_" then
            TriggerEvent("core:burglary:loadIPL", ipl.name)
        end

        -- Téléporter
        if ipl.previewPos then
            Wait(500)
            SetEntityCoords(PlayerPedId(), ipl.previewPos.x, ipl.previewPos.y, ipl.previewPos.z, false, false, false, true)
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Sélectionné et téléporté: " .. ipl.displayName .. "."
      })

        StaffMenu.PreviewIPLDetail.refresh()
        StaffMenu.SelectIPL.refresh()
        if StaffMenu.CreateBurglaryHouse and StaffMenu.CreateBurglaryHouse.refresh then
            StaffMenu.CreateBurglaryHouse.refresh()
        end
    end)

    StaffMenu.PreviewIPLDetail.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StaffMenu.SelectIPL.refresh()
    end)
end

-- Explore IPL Menu
function StaffMenu.BuildExploreIPLMenu()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local exploreIplData = GetIPLByName(selectedIPL)
    local exploreDisplayName = exploreIplData and exploreIplData.displayName or selectedIPL
    StaffMenu.ExploreIPL.Separator("EXPLORATION: " .. exploreDisplayName)

    -- Affichage des coordonnées actuelles
    StaffMenu.ExploreIPL.Button(":map: COORDONNÉES ACTUELLES",
        string.format("X: %.2f, Y: %.2f, Z: %.2f, H: %.2f", coords.x, coords.y, coords.z, heading),
        "Copier en appuyant sur le bouton", "arrow", false, function()
            -- Copier les coordonnées dans le presse-papiers
            local coordsText = string.format("x = %.2f, y = %.2f, z = %.2f, h = %.2f", coords.x, coords.y, coords.z, heading)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = "Coordonnées copiées: " .. coordsText .. "."
          })
        end)

    StaffMenu.ExploreIPL.Separator("OUTILS DE NAVIGATION")

    -- Téléportation rapide par coordonnées
    StaffMenu.ExploreIPL.Button(":target: TP PAR COORDONNÉES", "Saisir X, Y, Z pour se téléporter", nil, "arrow", false, function()
        local x = VFW.Nui.KeyboardInput(true, "Coordonnée X", tostring(coords.x))
        if not x or x == "" then return end

        local y = VFW.Nui.KeyboardInput(true, "Coordonnée Y", tostring(coords.y))
        if not y or y == "" then return end

        local z = VFW.Nui.KeyboardInput(true, "Coordonnée Z", tostring(coords.z))
        if not z or z == "" then return end

        local newX, newY, newZ = tonumber(x), tonumber(y), tonumber(z)
        if newX and newY and newZ then
            SetEntityCoords(playerPed, newX, newY, newZ, false, false, false, true)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                message = string.format("Téléporté vers %.2f, %.2f, %.2f.", newX, newY, newZ)
            })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                message = "Ces coordonnées ne sont pas valides."
          })
        end
    end)

    -- Déplacement fin
    StaffMenu.ExploreIPL.Button(":arrow: MONTER (+1 Z)", "Monte de 1 unité", nil, "arrow", false, function()
        local newCoords = coords + vector3(0, 0, 1)
        SetEntityCoords(playerPed, newCoords.x, newCoords.y, newCoords.z, false, false, false, true)
        StaffMenu.ExploreIPL.refresh()
    end)

    StaffMenu.ExploreIPL.Button(":arrow: DESCENDRE (-1 Z)", "Descend de 1 unité", nil, "arrow", false, function()
        local newCoords = coords + vector3(0, 0, -1)
        SetEntityCoords(playerPed, newCoords.x, newCoords.y, newCoords.z, false, false, false, true)
        StaffMenu.ExploreIPL.refresh()
    end)

    StaffMenu.ExploreIPL.Separator("GESTION DE L'INTÉRIEUR")

    -- Recharger IPL (seulement si ce n'est pas le défaut)
    local canReload = selectedIPL ~= "" and selectedIPL ~= "_default_"
  local selectedIplDataExplore = GetIPLByName(selectedIPL)
    local displayNameExplore = selectedIplDataExplore and selectedIplDataExplore.displayName or selectedIPL

    StaffMenu.ExploreIPL.Button(":refresh: RECHARGER INTÉRIEUR", canReload and "Recharger l'intérieur actuel" or "Pas d'intérieur à recharger", nil, "arrow", not canReload, function()
        TriggerEvent("core:burglary:unloadIPL", selectedIPL)
        Wait(500)
        TriggerEvent("core:burglary:loadIPL", selectedIPL)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Intérieur rechargé: " .. displayNameExplore .. "."
      })
    end)

    -- Sauvegarder la position comme nouvelle position de téléportation
    StaffMenu.ExploreIPL.Button(":save: SAUVEGARDER CETTE POSITION", "Définir comme nouvelle position de TP", nil, "arrow", false, function()
        -- Mettre à jour la position dans la table
        IPLTeleportPositions[selectedIPL] = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = string.format("Position sauvegardée pour %s: %.2f, %.2f, %.2f.", selectedIPL, coords.x, coords.y, coords.z)
        })

        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            subtitle = 'Builder',
            message = "La nouvelle position sera utilisée pour les prochaines téléportations."
      })
    end)

    StaffMenu.ExploreIPL.Separator("INFORMATIONS IPL")

    -- Afficher les infos de l'IPL depuis cl_ipl.lua
    local iplData = GetIPLData(selectedIPL)
    if iplData then
        StaffMenu.ExploreIPL.Button(":edit: INFO IPL",
            string.format("Nom: %s | Catégorie: %s", iplData.name or "Inconnu", iplData.category or "Inconnue"),
            "Informations depuis cl_ipl.lua", "arrow", true, function() end)
    end

    StaffMenu.ExploreIPL.Button(":back: RETOUR", nil, nil, "arrow", false, function()
        StaffMenu.SelectIPL.refresh()
    end)
end

local gofastNPCData = {
    name = "",
    region = "NORTH",
    position = nil,
    model = "g_m_y_mexgang_01",
    heading = 0.0,
    active = true
}

-- Variables pour édition GoFast
local selectedGoFastDestination = nil
local selectedGoFastNPC = nil
local selectedGoFastVehicle = nil

-- Menu principal GoFast (simplifié comme Pacific/Fleeca)
function StaffMenu.BuildGoFastMenu()
    StaffMenu.builderGoFast.Separator("GO FAST - CONFIGURATION")

    StaffMenu.builderGoFast.Button(":settings: PARAMÈTRES GLOBAUX", "Cooldowns, police, etc.", nil, "chevron", false, function()
    end, StaffMenu.GoFastSettings)

    StaffMenu.builderGoFast.Button(":pin: GÉRER LES NPCs", "NPCs de départ Nord/Sud", nil, "chevron", false, function()
    end, StaffMenu.GoFastNPCs)

    StaffMenu.builderGoFast.Button(":target: GÉRER LES DESTINATIONS", "Points de livraison", nil, "chevron", false, function()
    end, StaffMenu.GoFastDestinations)

    StaffMenu.builderGoFast.Button(":car: GÉRER LES VÉHICULES", "Modèles et récompenses", nil, "chevron", false, function()
    end, StaffMenu.GoFastVehicles)

    StaffMenu.builderGoFast.Separator("ACTIONS RAPIDES")

    StaffMenu.builderGoFast.Button(":clock: RESET COOLDOWNS", "Réinitialise tous les temps d'attente", nil, "arrow", false, function()
        TriggerServerEvent('core:gofast:resetCooldowns')
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Cooldowns réinitialisés." })
    end)

    StaffMenu.builderGoFast.Button(":refresh: RECHARGER DEPUIS BDD", "Recharge NPCs et destinations", nil, "arrow", false, function()
        TriggerServerEvent('core:gofast:reloadFromDatabase')
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Builder', message = "Rechargement en cours." })
    end)
end

-- Sous-menu paramètres globaux
function StaffMenu.BuildGoFastSettingsMenu()
    StaffMenu.GoFastSettings.Separator("PARAMÈTRES GO FAST")

    local settings = TriggerServerCallback("core:gofast:getSettings") or {}

    StaffMenu.GoFastSettings.Button(":police: POLICIERS MINIMUM", tostring(settings.min_police_required or 2) .. " policiers", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre de policiers minimum", tostring(settings.min_police_required or 2))
        if input and tonumber(input) and tonumber(input) >= 0 then
            TriggerServerEvent("core:gofast:updateSettings", "min_police_required", tonumber(input))
            Wait(300)
            StaffMenu.GoFastSettings.refresh()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Policiers minimum mis à jour." })
        end
    end)

    StaffMenu.GoFastSettings.Button(":clock: COOLDOWN JOUEUR", (settings.cooldown_duration or 30) .. " minutes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Cooldown joueur (minutes)", tostring(settings.cooldown_duration or 30))
        if input and tonumber(input) and tonumber(input) >= 1 then
            TriggerServerEvent("core:gofast:updateSettings", "cooldown_duration", tonumber(input))
            Wait(300)
            StaffMenu.GoFastSettings.refresh()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Cooldown mis à jour." })
        end
    end)

    StaffMenu.GoFastSettings.Button(":clock: DÉLAI DE LIVRAISON", math.floor((settings.delivery_timeout or 300) / 60) .. " minutes", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Délai de livraison (minutes)", tostring(math.floor((settings.delivery_timeout or 300) / 60)))
        if input and tonumber(input) and tonumber(input) >= 1 then
            TriggerServerEvent("core:gofast:updateSettings", "delivery_timeout", tonumber(input) * 60)
            Wait(300)
            StaffMenu.GoFastSettings.refresh()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Délai mis à jour." })
        end
    end)
end

-- Sous-menu NPCs
function StaffMenu.BuildGoFastNPCsMenu()
    StaffMenu.GoFastNPCs.Separator("NPCs DE DÉPART")

    local npcs = TriggerServerCallback("core:gofast:getNPCs") or {}

    for _, npc in ipairs(npcs) do
        local region = npc.region == "NORTH" and "NORD" or "SUD"
      local status = npc.enabled and ":check:" or ":x:"
      StaffMenu.GoFastNPCs.Button(status .. " NPC " .. region, nil, nil, "chevron", false, function()
            selectedGoFastNPC = npc
        end, StaffMenu.GoFastEditNPC)
    end

    if #npcs == 0 then
        StaffMenu.GoFastNPCs.Button("Aucun NPC configuré", nil, nil, "arrow", true, function() end)
    end
end

-- Sous-menu édition NPC
function StaffMenu.BuildGoFastEditNPCMenu()
    if not selectedGoFastNPC then
        StaffMenu.GoFastEditNPC.Button("Erreur: aucun NPC", nil, nil, "arrow", true, function() end)
        return
    end

    local npc = selectedGoFastNPC
    local region = npc.region == "NORTH" and "NORD" or "SUD"

  StaffMenu.GoFastEditNPC.Separator("NPC " .. region)

    StaffMenu.GoFastEditNPC.Button(":chart: STATUT", npc.enabled and "Actif" or "Inactif", nil, "arrow", true, function() end)
    StaffMenu.GoFastEditNPC.Button(":pin: POSITION", string.format("%.0f, %.0f, %.0f", npc.position.x, npc.position.y, npc.position.z), nil, "arrow", true, function() end)

    if npc.vehicleSpawn then
        StaffMenu.GoFastEditNPC.Button(":car: SPAWN VÉHICULE", string.format("%.0f, %.0f, %.0f", npc.vehicleSpawn.x, npc.vehicleSpawn.y, npc.vehicleSpawn.z), nil, "arrow", true, function() end)
    end

    StaffMenu.GoFastEditNPC.Separator("ACTIONS")

    StaffMenu.GoFastEditNPC.Button(":pin: TP AU NPC", nil, nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), npc.position.x, npc.position.y, npc.position.z, false, false, false, true)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "TP au NPC " .. region .. "." })
    end)

    StaffMenu.GoFastEditNPC.Button(":wrench: MODIFIER POSITION NPC", "Ma position actuelle", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        TriggerServerEvent('core:gofast:updateNPC', npc.region, "position", {
            x = math.floor(pos.x * 100) / 100, y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100, heading = math.floor(heading * 100) / 100
        })
        selectedGoFastNPC.position = { x = pos.x, y = pos.y, z = pos.z }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Position NPC mise à jour." })
        Wait(500)
        StaffMenu.GoFastEditNPC.refresh()
    end)

    if npc.vehicleSpawn then
        StaffMenu.GoFastEditNPC.Button(":car: TP AU SPAWN VÉHICULE", nil, nil, "arrow", false, function()
            SetEntityCoords(PlayerPedId(), npc.vehicleSpawn.x, npc.vehicleSpawn.y, npc.vehicleSpawn.z, false, false, false, true)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "TP au spawn véhicule " .. region .. "." })
        end)
    end

    StaffMenu.GoFastEditNPC.Button(":wrench: MODIFIER SPAWN VÉHICULE", "Ma position actuelle", nil, "arrow", false, function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local pos, heading
        if veh and veh ~= 0 then
            pos = GetEntityCoords(veh)
            heading = GetEntityHeading(veh)
        else
            pos = GetEntityCoords(ped)
            heading = GetEntityHeading(ped)
            local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
            if found then
                pos = vector3(pos.x, pos.y, groundZ)
            end
        end
        TriggerServerEvent('core:gofast:updateNPC', npc.region, "vehicle_spawn", {
            x = math.floor(pos.x * 100) / 100, y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100, heading = math.floor(heading * 100) / 100
        })
        selectedGoFastNPC.vehicleSpawn = { x = pos.x, y = pos.y, z = pos.z, heading = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Spawn véhicule mis à jour." })
        Wait(500)
        StaffMenu.GoFastEditNPC.refresh()
    end)

    StaffMenu.GoFastEditNPC.Button(npc.enabled and ":x: DÉSACTIVER NPC" or ":check: ACTIVER NPC", nil, nil, "arrow", false, function()
        TriggerServerEvent('core:gofast:updateNPC', npc.region, "enabled", not npc.enabled)
        selectedGoFastNPC.enabled = not npc.enabled
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "NPC " .. (not npc.enabled and "activé" or "désactivé") .. "." })
        Wait(500)
        StaffMenu.GoFastEditNPC.refresh()
    end)
end

-- Sous-menu destinations (liste)
function StaffMenu.BuildGoFastDestinationsMenu()
    local destinations = TriggerServerCallback("core:gofast:getDestinations") or {}

    -- Compter par région
    local northCount, southCount = 0, 0
    for _, dest in ipairs(destinations) do
        if dest.region == "NORTH" then northCount = northCount + 1 else southCount = southCount + 1 end
    end

    StaffMenu.GoFastDestinations.Separator("DESTINATIONS NORD (" .. northCount .. ")")

    for _, dest in ipairs(destinations) do
        if dest.region == "NORTH" then
            local status = dest.active and ":check:" or ":x:"
          StaffMenu.GoFastDestinations.Button(status .. " " .. dest.name, string.format("%.0f, %.0f", dest.position.x, dest.position.y), nil, "chevron", false, function()
                selectedGoFastDestination = dest
            end, StaffMenu.GoFastEditDestination)
        end
    end

    StaffMenu.GoFastDestinations.Button(":plus: CRÉER DESTINATION NORD", "À ma position", nil, "arrow", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom de la destination", "")
        if name and name ~= "" then
            local pos = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('core:gofast:createDestination', {
                name = name, region = "NORTH",
                position = { x = math.floor(pos.x * 100) / 100, y = math.floor(pos.y * 100) / 100, z = math.floor(pos.z * 100) / 100 },
                active = true
            })
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Destination NORD créée." })
            Wait(500)
            StaffMenu.GoFastDestinations.refresh()
        end
    end)

    StaffMenu.GoFastDestinations.Separator("DESTINATIONS SUD (" .. southCount .. ")")

    for _, dest in ipairs(destinations) do
        if dest.region == "SOUTH" then
            local status = dest.active and ":check:" or ":x:"
          StaffMenu.GoFastDestinations.Button(status .. " " .. dest.name, string.format("%.0f, %.0f", dest.position.x, dest.position.y), nil, "chevron", false, function()
                selectedGoFastDestination = dest
            end, StaffMenu.GoFastEditDestination)
        end
    end

    StaffMenu.GoFastDestinations.Button(":plus: CRÉER DESTINATION SUD", "À ma position", nil, "arrow", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom de la destination", "")
        if name and name ~= "" then
            local pos = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('core:gofast:createDestination', {
                name = name, region = "SOUTH",
                position = { x = math.floor(pos.x * 100) / 100, y = math.floor(pos.y * 100) / 100, z = math.floor(pos.z * 100) / 100 },
                active = true
            })
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Destination SUD créée." })
            Wait(500)
            StaffMenu.GoFastDestinations.refresh()
        end
    end)
end

-- Sous-menu édition destination
function StaffMenu.BuildGoFastEditDestinationMenu()
    if not selectedGoFastDestination then
        StaffMenu.GoFastEditDestination.Button("Erreur: aucune destination", nil, nil, "arrow", true, function() end)
        return
    end

    local dest = selectedGoFastDestination
    local region = dest.region == "NORTH" and "NORD" or "SUD"

  StaffMenu.GoFastEditDestination.Separator(dest.name .. " (" .. region .. ")")

    StaffMenu.GoFastEditDestination.Button(":chart: STATUT", dest.active and "Actif" or "Inactif", nil, "arrow", true, function() end)
    StaffMenu.GoFastEditDestination.Button(":pin: POSITION", string.format("%.1f, %.1f, %.1f", dest.position.x, dest.position.y, dest.position.z), nil, "arrow", true, function() end)

    StaffMenu.GoFastEditDestination.Separator("ACTIONS")

    StaffMenu.GoFastEditDestination.Button(":pin: TÉLÉPORTER", nil, nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), dest.position.x, dest.position.y, dest.position.z, false, false, false, true)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "TP à " .. dest.name .. "." })
    end)

    StaffMenu.GoFastEditDestination.Button(":wrench: MODIFIER POSITION", "Ma position actuelle", nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('core:gofast:updateDestination', dest.id, "position", {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100
        })
        selectedGoFastDestination.position = { x = pos.x, y = pos.y, z = pos.z }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Position mise à jour." })
        Wait(500)
        StaffMenu.GoFastEditDestination.refresh()
    end)

    StaffMenu.GoFastEditDestination.Button(dest.active and ":x: DÉSACTIVER" or ":check: ACTIVER", nil, nil, "arrow", false, function()
        TriggerServerEvent('core:gofast:updateDestination', dest.id, "active", not dest.active)
        selectedGoFastDestination.active = not dest.active
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Destination " .. (not dest.active and "activée" or "désactivée") .. "." })
        Wait(500)
        StaffMenu.GoFastEditDestination.refresh()
    end)

    StaffMenu.GoFastEditDestination.Button(":trash: SUPPRIMER", "Suppression définitive", nil, "arrow", false, function()
        TriggerServerEvent('core:gofast:deleteDestination', dest.id)
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Builder', message = "Destination '" .. dest.name .. "' supprimée." })
        selectedGoFastDestination = nil
    end)
end

-- Sous-menu véhicules GoFast (liste)
function StaffMenu.BuildGoFastVehiclesMenu()
    local vehicles = TriggerServerCallback("core:gofast:getVehicles") or {}

    StaffMenu.GoFastVehicles.Separator("VÉHICULES GOFAST")

    for _, vehicle in ipairs(vehicles) do
        local status = (vehicle.active == 1 or vehicle.active == true) and ":check:" or ":x:"
      local priceText = string.format("%s - %s", VFW.Math.FormatMoney(vehicle.price), vehicle.model)
        StaffMenu.GoFastVehicles.Button(status .. " " .. vehicle.name, priceText, nil, "chevron", false, function()
            selectedGoFastVehicle = vehicle
        end, StaffMenu.GoFastEditVehicle)
    end

    if #vehicles == 0 then
        StaffMenu.GoFastVehicles.Button("Aucun véhicule configuré", nil, nil, "arrow", true, function() end)
    end

    StaffMenu.GoFastVehicles.Separator("ACTIONS")

    StaffMenu.GoFastVehicles.Button(":plus: CRÉER UN VÉHICULE", nil, nil, "arrow", false, function()
        -- Input category
        local category = VFW.Nui.KeyboardInput(true, "Identifiant unique (ex: super)", "")
        if not category or category == "" then return end

        -- Input name
        local name = VFW.Nui.KeyboardInput(true, "Nom affiché", "")
        if not name or name == "" then return end

        -- Input model
        local model = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (spawn name)", "")
        if not model or model == "" then return end

        -- Input price
        local price = VFW.Nui.KeyboardInput(true, "Récompense (" .. LOCALE.currencySymbol .. ")", "15000")
        if not price or not tonumber(price) then return end

        TriggerServerEvent("core:gofast:createVehicle", {
            category = category,
            name = name,
            model = model,
            price = tonumber(price)
        })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Véhicule créé." })
        Wait(500)
        StaffMenu.GoFastVehicles.refresh()
    end)
end

-- Sous-menu édition véhicule GoFast
function StaffMenu.BuildGoFastEditVehicleMenu()
    if not selectedGoFastVehicle then
        StaffMenu.GoFastEditVehicle.Button("Erreur: aucun véhicule", nil, nil, "arrow", true, function() end)
        return
    end

    local vehicle = selectedGoFastVehicle
    local isActive = vehicle.active == 1 or vehicle.active == true

    StaffMenu.GoFastEditVehicle.Separator(vehicle.name)

    -- Infos
    StaffMenu.GoFastEditVehicle.Button(":chart: STATUT", isActive and "Actif" or "Inactif", nil, "arrow", true, function() end)
    StaffMenu.GoFastEditVehicle.Button(":tag: CATÉGORIE", vehicle.category, nil, "arrow", true, function() end)
    StaffMenu.GoFastEditVehicle.Button(":car: MODÈLE", vehicle.model, nil, "arrow", true, function() end)
    StaffMenu.GoFastEditVehicle.Button(":money: RÉCOMPENSE", VFW.Math.FormatMoney(vehicle.price), nil, "arrow", true, function() end)
    StaffMenu.GoFastEditVehicle.Button(":edit: DESCRIPTION", (vehicle.description and vehicle.description ~= "") and vehicle.description or "Non définie", nil, "arrow", true, function() end)

    StaffMenu.GoFastEditVehicle.Separator("MODIFICATIONS")

    -- Modifier nom
    StaffMenu.GoFastEditVehicle.Button(":wrench: MODIFIER NOM", nil, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom", vehicle.name)
        if input and input ~= "" then
            TriggerServerEvent("core:gofast:updateVehicle", vehicle.id, "name", input)
            selectedGoFastVehicle.name = input
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Nom mis à jour." })
            Wait(300)
            StaffMenu.GoFastEditVehicle.refresh()
        end
    end)

    -- Modifier modèle
    StaffMenu.GoFastEditVehicle.Button(":wrench: MODIFIER MODÈLE", nil, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau modèle (spawn name)", vehicle.model)
        if input and input ~= "" then
            TriggerServerEvent("core:gofast:updateVehicle", vehicle.id, "model", input)
            selectedGoFastVehicle.model = input
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Modèle mis à jour." })
            Wait(300)
            StaffMenu.GoFastEditVehicle.refresh()
        end
    end)

    -- Modifier prix (récompense)
    StaffMenu.GoFastEditVehicle.Button(":wrench: MODIFIER RÉCOMPENSE", nil, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle récompense (" .. LOCALE.currencySymbol .. ")", tostring(vehicle.price))
        if input and tonumber(input) then
            TriggerServerEvent("core:gofast:updateVehicle", vehicle.id, "price", tonumber(input))
            selectedGoFastVehicle.price = tonumber(input)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Récompense mise à jour." })
            Wait(300)
            StaffMenu.GoFastEditVehicle.refresh()
        end
    end)

    -- Modifier description
    StaffMenu.GoFastEditVehicle.Button(":wrench: MODIFIER DESCRIPTION", nil, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Description du véhicule", vehicle.description or "")
        if input then
            TriggerServerEvent("core:gofast:updateVehicle", vehicle.id, "description", input)
            selectedGoFastVehicle.description = input
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Description mise à jour." })
            Wait(300)
            StaffMenu.GoFastEditVehicle.refresh()
        end
    end)

    -- Toggle actif
    StaffMenu.GoFastEditVehicle.Button(isActive and ":x: DÉSACTIVER" or ":check: ACTIVER", nil, nil, "arrow", false, function()
        local newStatus = isActive and 0 or 1
        TriggerServerEvent("core:gofast:updateVehicle", vehicle.id, "active", newStatus)
        selectedGoFastVehicle.active = newStatus
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Statut mis à jour." })
        Wait(300)
        StaffMenu.GoFastEditVehicle.refresh()
    end)

    -- Supprimer
    StaffMenu.GoFastEditVehicle.Button(":trash: SUPPRIMER", "Suppression définitive", nil, "arrow", false, function()
        TriggerServerEvent("core:gofast:deleteVehicle", vehicle.id)
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Builder', message = "Véhicule supprimé." })
        selectedGoFastVehicle = nil
    end)
end

local drugZones = {}
local drugSettings = {}
local drugPrices = {}
local selectedZone = nil
local selectedDrugType = nil
local selectedDrugData = nil
local drugZoneCreationData = {
    name = "",
    radius = 500,
    position = nil
}

function StaffMenu.BuildDrugDealingMenu()
    StaffMenu.builderDrugDealing.Separator("GESTION DES ZONES")

    StaffMenu.builderDrugDealing.Button(":map: CARTE INTERACTIVE", "Créer, modifier et supprimer les zones de vente sur la carte", nil, "chevron", false, function()
        exports['VUI']:CloseAll()
        SetTimeout(200, function()
            exports['core']:OpenDrugDealingTablet()
        end)
        return false
    end)

    StaffMenu.builderDrugDealing.Separator("CONFIGURATION")

    StaffMenu.builderDrugDealing.Button(":settings: PARAMÈTRES GLOBAUX", "Cooldowns, probabilités, distances, police", nil, "chevron", false, function()
    end, StaffMenu.DrugDealingSettings)

    StaffMenu.builderDrugDealing.Separator("OUTILS")

    StaffMenu.builderDrugDealing.Button(":refresh: RECHARGER CONFIG", "Recharge les paramètres depuis la BDD", nil, "arrow", false, function()
        TriggerServerEvent("core:drugdealing:admin:reload")
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Configuration rechargée depuis la base de données."
      })
    end)

    StaffMenu.builderDrugDealing.Button(":chart: STATISTIQUES", "Statistiques du jour (reset chaque 24h)", nil, "chevron", false, function()
    end, StaffMenu.DrugStatistics)
end

function StaffMenu.BuildCreateDrugZoneMenu()
    StaffMenu.CreateDrugZone.Separator("CRÉATION DE ZONE DE VENTE")

    -- Nom de la zone
    StaffMenu.CreateDrugZone.Button(":edit: NOM DE LA ZONE", drugZoneCreationData.name ~= "" and drugZoneCreationData.name or "Non défini", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Nom de la zone", drugZoneCreationData.name)
        VFW.Nui.Focus(false)
        if input and input ~= "" then
            drugZoneCreationData.name = input
            StaffMenu.CreateDrugZone.refresh()
        end
    end)

    -- Rayon de la zone
    StaffMenu.CreateDrugZone.Button(":ruler: RAYON", drugZoneCreationData.radius .. "m", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Rayon en mètres", tostring(drugZoneCreationData.radius))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) > 0 then
            drugZoneCreationData.radius = tonumber(input)
            StaffMenu.CreateDrugZone.refresh()
        end
    end)

    -- Position de la zone
    local positionText = drugZoneCreationData.position and string.format("%.1f, %.1f, %.1f", drugZoneCreationData.position.x, drugZoneCreationData.position.y, drugZoneCreationData.position.z) or "Non défini"
  StaffMenu.CreateDrugZone.Button(":pin: POSITION", positionText, nil, "arrow", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        drugZoneCreationData.position = {
            x = math.floor(pos.x * 100) / 100,
            y = math.floor(pos.y * 100) / 100,
            z = math.floor(pos.z * 100) / 100
        }
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
            message = "Position définie: " .. positionText .. "."
      })
        StaffMenu.CreateDrugZone.refresh()
    end)

    StaffMenu.CreateDrugZone.Separator("ACTIONS")

    -- Créer la zone
    local canCreate = drugZoneCreationData.name ~= "" and drugZoneCreationData.position
    StaffMenu.CreateDrugZone.Button(":check: CRÉER LA ZONE", nil, nil, "arrow", not canCreate, function()
        if canCreate then
            TriggerServerEvent("core:drugdealing:admin:createZone", {
                name = drugZoneCreationData.name,
                zoneType = "allowed",
                shape = "circle",
                center = drugZoneCreationData.position,
                radius = drugZoneCreationData.radius
            })
            -- Reset des données
            drugZoneCreationData = {
                name = "",
                radius = 500,
                position = nil
            }
            -- Recharger les zones depuis le serveur
            SetTimeout(500, function()
                TriggerServerEvent("core:drugdealing:admin:getZones")
            end)
            StaffMenu.CreateDrugZone.refresh()
        end
    end)

    -- Reset des données
    StaffMenu.CreateDrugZone.Button(":refresh: RESET", "Effacer toutes les données", nil, "arrow", false, function()
        drugZoneCreationData = {
            name = "",
            radius = 500,
            position = nil
        }
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Données effacées."
      })
        StaffMenu.CreateDrugZone.refresh()
    end)
end

function StaffMenu.BuildManageDrugZonesMenu()
    if not drugZones then return end

    StaffMenu.ManageDrugZones.Separator("ZONES DE VENTE")

    local zoneCount = 0
    -- drugZones a la structure {allowed = {}, restricted = {}}
    if drugZones.allowed then
        for _, zone in ipairs(drugZones.allowed) do
            zoneCount = zoneCount + 1
            local statusIcon = zone.active and ":dot-green:" or ":dot-red:"
          local label = string.format("%s %s", statusIcon, zone.name)
            local desc = string.format("Rayon: %dm", math.floor(zone.radius or 0))
            StaffMenu.ManageDrugZones.Button(label, desc, nil, "chevron", false, function()
                selectedZone = zone
                StaffMenu.EditDrugZone.refresh()
            end, StaffMenu.EditDrugZone)
        end
    end

    if zoneCount == 0 then
        StaffMenu.ManageDrugZones.Button(":x: Aucune zone", "Créez-en une !", nil, nil, false, function() end)
    end
end

function StaffMenu.BuildEditDrugZoneMenu()
    if not selectedZone then return end

    StaffMenu.EditDrugZone.Separator("MODIFIER: " .. selectedZone.name)

    StaffMenu.EditDrugZone.Button(":edit: MODIFIER NOM", selectedZone.name, nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom", selectedZone.name)
        VFW.Nui.Focus(false)
        if input and input ~= "" then
            TriggerServerEvent("core:drugdealing:admin:updateZone", selectedZone.id, "name", input)
        end
    end)

    StaffMenu.EditDrugZone.Button(":ruler: MODIFIER RAYON", math.floor(selectedZone.radius or 0) .. "m", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Nouveau rayon (mètres)", tostring(math.floor(selectedZone.radius or 0)))
        VFW.Nui.Focus(false)
        if input and tonumber(input) then
            TriggerServerEvent("core:drugdealing:admin:updateZone", selectedZone.id, "radius", tonumber(input))
        end
    end)

    local statusLabel = selectedZone.active and ":dot-green: ACTIVE" or ":dot-red: INACTIVE"
  StaffMenu.EditDrugZone.Button(":refresh: STATUT", statusLabel, nil, "arrow", false, function()
        local newStatus = not selectedZone.active
        TriggerServerEvent("core:drugdealing:admin:updateZone", selectedZone.id, "active", newStatus and 1 or 0)
        selectedZone.active = newStatus
        StaffMenu.EditDrugZone.refresh()
    end)

    StaffMenu.EditDrugZone.Separator("DANGER")

    StaffMenu.EditDrugZone.Button(":trash: SUPPRIMER ZONE", "Action irréversible", nil, "arrow", false, function()
        TriggerServerEvent("core:drugdealing:admin:deleteZone", selectedZone.id)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Zone '" .. selectedZone.name .. "' supprimée."
      })
        selectedZone = nil
        -- Recharger les zones
        Wait(500)
        TriggerServerEvent("core:drugdealing:admin:getZones")
    end)
end

function StaffMenu.BuildDrugDealingSettingsMenu()
    if not drugSettings then return end

    StaffMenu.DrugDealingSettings.Separator("SYSTÈME")

    local systemStatus = drugSettings.system_enabled == 1 and ":dot-green: ACTIVÉ" or ":dot-red: DÉSACTIVÉ"
  StaffMenu.DrugDealingSettings.Button(":refresh: SYSTÈME", systemStatus, nil, "arrow", false, function()
        local newValue = drugSettings.system_enabled == 1 and 0 or 1
        TriggerServerEvent("core:drugdealing:admin:updateSetting", "system_enabled", newValue)
        drugSettings.system_enabled = newValue
        StaffMenu.DrugDealingSettings.refresh()
    end)

    StaffMenu.DrugDealingSettings.Separator("NPCs")

    StaffMenu.DrugDealingSettings.Button(":ruler: DISTANCE MIN", (drugSettings.npc_spawn_distance_min or 40) .. "m", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Distance min spawn NPC (metres)", tostring(drugSettings.npc_spawn_distance_min or 40))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 10 and tonumber(input) <= 200 then
            TriggerServerEvent("core:drugdealing:admin:updateSetting", "npc_spawn_distance_min", tonumber(input))
            drugSettings.npc_spawn_distance_min = tonumber(input)
            StaffMenu.DrugDealingSettings.refresh()
        end
    end)

    StaffMenu.DrugDealingSettings.Button(":ruler: DISTANCE MAX", (drugSettings.npc_spawn_distance_max or 80) .. "m", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Distance max spawn NPC (metres)", tostring(drugSettings.npc_spawn_distance_max or 80))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 20 and tonumber(input) <= 500 then
            TriggerServerEvent("core:drugdealing:admin:updateSetting", "npc_spawn_distance_max", tonumber(input))
            drugSettings.npc_spawn_distance_max = tonumber(input)
            StaffMenu.DrugDealingSettings.refresh()
        end
    end)

    StaffMenu.DrugDealingSettings.Button(":clock: DÉLAI NPC", (drugSettings.npc_despawn_timeout or 300) .. "s", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Délai de disparition du NPC (secondes)", tostring(drugSettings.npc_despawn_timeout or 300))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 60 and tonumber(input) <= 600 then
            TriggerServerEvent("core:drugdealing:admin:updateSetting", "npc_despawn_timeout", tonumber(input))
            drugSettings.npc_despawn_timeout = tonumber(input)
            StaffMenu.DrugDealingSettings.refresh()
        end
    end)

    StaffMenu.DrugDealingSettings.Separator("VENTES")

    StaffMenu.DrugDealingSettings.Button(":hourglass: COOLDOWN", (drugSettings.sale_cooldown or 30) .. "s", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Cooldown entre ventes (secondes)", tostring(drugSettings.sale_cooldown or 30))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 300 then
            TriggerServerEvent("core:drugdealing:admin:updateSetting", "sale_cooldown", tonumber(input))
            drugSettings.sale_cooldown = tonumber(input)
            StaffMenu.DrugDealingSettings.refresh()
        end
    end)

    StaffMenu.DrugDealingSettings.Separator("POLICE")

    StaffMenu.DrugDealingSettings.Button(":siren: CHANCE ALERTE", (drugSettings.police_alert_chance or 10) .. "%", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Chance alerte police (%)", tostring(drugSettings.police_alert_chance or 10))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 100 then
            TriggerServerEvent("core:drugdealing:admin:updateSetting", "police_alert_chance", tonumber(input))
            drugSettings.police_alert_chance = tonumber(input)
            StaffMenu.DrugDealingSettings.refresh()
        end
    end)

    StaffMenu.DrugDealingSettings.Button(":police: POLICE MIN", tostring(drugSettings.min_police_required or 0), nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Policiers minimum requis", tostring(drugSettings.min_police_required or 0))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 10 then
            TriggerServerEvent("core:drugdealing:admin:updateSetting", "min_police_required", tonumber(input))
            drugSettings.min_police_required = tonumber(input)
            StaffMenu.DrugDealingSettings.refresh()
        end
    end)
end

function StaffMenu.BuildDrugPriceSettingsMenu()
    if not drugPrices then return end

    StaffMenu.DrugPriceSettings.Separator("PRIX DES DROGUES")

    local drugLabels = {
        fentanyl = ":flask: FENTANYL",
        weed = ":leaf: WEED",
        cocaine = ":sparkles: COCAÏNE",
        meth = ":flask: METH",
        extasy = ":flask: EXTASY"
  }

    for drugType, priceData in pairs(drugPrices) do
        local label = drugLabels[drugType] or drugType:upper()
        local price = priceData.pricePerUnit or priceData.priceMin or 0
        local priceInfo = string.format("%s | x%d-%d", VFW.Math.FormatMoney(price), priceData.minQuantity, priceData.maxQuantity)

        StaffMenu.DrugPriceSettings.Button(label, priceInfo, nil, "chevron", false, function()
            selectedDrugType = drugType
            selectedDrugData = priceData
            StaffMenu.EditDrugPrice.refresh()
        end, StaffMenu.EditDrugPrice)
    end
end

function StaffMenu.BuildEditDrugPriceMenu()
    if not selectedDrugType or not selectedDrugData then return end

    local drugLabels = {
        fentanyl = ":flask: FENTANYL",
        weed = ":leaf: WEED",
        cocaine = ":sparkles: COCAÏNE",
        meth = ":flask: METH",
        extasy = ":flask: EXTASY"
  }

    local label = drugLabels[selectedDrugType] or selectedDrugType:upper()
    StaffMenu.EditDrugPrice.Separator(label)

    StaffMenu.EditDrugPrice.Button(":money: PRIX PAR UNITÉ", VFW.Math.FormatMoney(selectedDrugData.pricePerUnit or selectedDrugData.priceMin or 0), nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local currentPrice = selectedDrugData.pricePerUnit or selectedDrugData.priceMin or 0
        local input = VFW.Nui.KeyboardInput(true, "Prix par unité que le NPC paie", tostring(currentPrice))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) > 0 then
            selectedDrugData.pricePerUnit = tonumber(input)
            TriggerServerEvent("core:drugdealing:admin:updateDrugPrice", selectedDrugType, selectedDrugData)
            StaffMenu.EditDrugPrice.refresh()
        end
    end)

    StaffMenu.EditDrugPrice.Button(":box: QTÉ MIN NPC", tostring(selectedDrugData.minQuantity), "Quantité minimum que le NPC achète", "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Quantité minimum que le NPC achète", tostring(selectedDrugData.minQuantity))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) >= 1 then
            selectedDrugData.minQuantity = tonumber(input)
            TriggerServerEvent("core:drugdealing:admin:updateDrugPrice", selectedDrugType, selectedDrugData)
            StaffMenu.EditDrugPrice.refresh()
        end
    end)

    StaffMenu.EditDrugPrice.Button(":box: QTÉ MAX NPC", tostring(selectedDrugData.maxQuantity), "Quantité maximum que le NPC achète", "chevron", false, function()
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "Quantité maximum que le NPC achète", tostring(selectedDrugData.maxQuantity))
        VFW.Nui.Focus(false)
        if input and tonumber(input) and tonumber(input) > selectedDrugData.minQuantity then
            selectedDrugData.maxQuantity = tonumber(input)
            TriggerServerEvent("core:drugdealing:admin:updateDrugPrice", selectedDrugType, selectedDrugData)
            StaffMenu.EditDrugPrice.refresh()
        end
    end)
end

RegisterNetEvent("core:drugdealing:admin:zonesData")
AddEventHandler("core:drugdealing:admin:zonesData", function(zones)
    drugZones = zones
end)

RegisterNetEvent("core:drugdealing:admin:settingsData")
AddEventHandler("core:drugdealing:admin:settingsData", function(settings, prices)
    print("[DRUG-ADMIN-CLIENT] Received settings and prices from server")
    print("[DRUG-ADMIN-CLIENT] Settings: " .. json.encode(settings or {}))
    print("[DRUG-ADMIN-CLIENT] Prices: " .. json.encode(prices or {}))
    drugSettings = settings
    drugPrices = prices
    StaffMenu.DrugDealingSettings.refresh()
    StaffMenu.DrugPriceSettings.refresh()
end)

StaffMenu.builderDrugDealing.OnOpen(function()
    StaffMenu.BuildDrugDealingMenu()
end)

StaffMenu.CreateDrugZone.OnOpen(function()
    StaffMenu.BuildCreateDrugZoneMenu()
end)

StaffMenu.ManageDrugZones.OnOpen(function()
    StaffMenu.BuildManageDrugZonesMenu()
end)

StaffMenu.EditDrugZone.OnOpen(function()
    StaffMenu.BuildEditDrugZoneMenu()
end)

StaffMenu.DrugDealingSettings.OnOpen(function()
    -- Load data synchronously before building menu
    local data = TriggerServerCallback("core:drugdealing:admin:getSettingsSync")
    if data then
        drugSettings = data.settings
        drugPrices = data.prices
    end
    StaffMenu.BuildDrugDealingSettingsMenu()
end)

StaffMenu.DrugPriceSettings.OnOpen(function()
    -- Load data synchronously before building menu
    local data = TriggerServerCallback("core:drugdealing:admin:getSettingsSync")
    if data then
        drugSettings = data.settings
        drugPrices = data.prices
    end
    StaffMenu.BuildDrugPriceSettingsMenu()
end)

StaffMenu.EditDrugPrice.OnOpen(function()
    StaffMenu.BuildEditDrugPriceMenu()
end)

local drugStatsData = nil

function StaffMenu.BuildDrugStatisticsMenu()
    StaffMenu.DrugStatistics.ClearItems()

    if not drugStatsData then
        StaffMenu.DrugStatistics.Separator("ERREUR")
        StaffMenu.DrugStatistics.Button("Impossible de charger les statistiques", "Le serveur n'a pas répondu.", nil, "empty", true, function() end)
        StaffMenu.DrugStatistics.Separator("")
        StaffMenu.DrugStatistics.Button("Réessayer", nil, nil, "arrow", false, function()
            drugStatsData = TriggerServerCallback("core:drugdealing:admin:getStatisticsSync")
            StaffMenu.BuildDrugStatisticsMenu()
            StaffMenu.DrugStatistics.refresh()
        end)
        return
    end

    local totals = drugStatsData.totals or { total_sales = 0, total_revenue = 0, total_quantity = 0, total_alerts = 0 }

    StaffMenu.DrugStatistics.Separator("STATISTIQUES DU JOUR")

    StaffMenu.DrugStatistics.Button("Ventes totales", tostring(totals.total_sales or 0), nil, "empty", true, function() end)
    StaffMenu.DrugStatistics.Button("Quantité totale vendue", tostring(totals.total_quantity or 0), nil, "empty", true, function() end)
    StaffMenu.DrugStatistics.Button("Revenu total", VFW.Math.FormatMoney(totals.total_revenue or 0), nil, "empty", true, function() end)
    StaffMenu.DrugStatistics.Button("Alertes police", tostring(totals.total_alerts or 0), nil, "empty", true, function() end)

    if drugStatsData.statistics and #drugStatsData.statistics > 0 then
        StaffMenu.DrugStatistics.Separator("PAR TYPE DE DROGUE")

        for _, stat in ipairs(drugStatsData.statistics) do
            local info = string.format("%d ventes | %s | %d alertes", stat.sales_count or 0, VFW.Math.FormatMoney(stat.total_revenue or 0), stat.police_alerts or 0)
            StaffMenu.DrugStatistics.Button(tostring(stat.drug_type), info, nil, "empty", true, function() end)
        end
    end

    if drugStatsData.recentSales and #drugStatsData.recentSales > 0 then
        StaffMenu.DrugStatistics.Separator("DERNIERES VENTES")

        for _, sale in ipairs(drugStatsData.recentSales) do
            local alertIcon = sale.police_alerted == 1 and " [POLICE]" or ""
          local info = string.format("%dx %s | %s%s", sale.quantity or 0, sale.drug_type or "?", VFW.Math.FormatMoney(sale.total_price or 0), alertIcon)
            StaffMenu.DrugStatistics.Button(tostring(sale.player_name or "Inconnu"), info, nil, "empty", true, function() end)
        end
    end

    StaffMenu.DrugStatistics.Separator("")

    StaffMenu.DrugStatistics.Button("Rafraichir", nil, nil, "arrow", false, function()
        drugStatsData = TriggerServerCallback("core:drugdealing:admin:getStatisticsSync")
        StaffMenu.BuildDrugStatisticsMenu()
        StaffMenu.DrugStatistics.refresh()
    end)
end

StaffMenu.DrugStatistics.OnOpen(function()
    drugStatsData = TriggerServerCallback("core:drugdealing:admin:getStatisticsSync")
    StaffMenu.BuildDrugStatisticsMenu()
end)

-- ============================================
-- VISUALISATION DES ZONES SUR LA MAP
-- ============================================

local zoneVisualizationActive = false
local zoneBlips = {}
local zoneMarkers = {}

RegisterNetEvent("core:drugdealing:admin:showZonesOnMap")
AddEventHandler("core:drugdealing:admin:showZonesOnMap", function()
    if not drugZones then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
            message = "Aucune zone chargée."
      })
        return
    end

    -- Si déjà actif, nettoyer
    if zoneVisualizationActive then
        for _, blip in ipairs(zoneBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        zoneBlips = {}
        zoneMarkers = {}
        zoneVisualizationActive = false
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Visualisation des zones désactivée."
      })
        return
    end

    -- Créer les blips et markers pour chaque zone
    local zoneCount = 0

    -- Zones autorisées (allowed)
    if drugZones.allowed then
        for _, zone in ipairs(drugZones.allowed) do
            if zone.shape == "circle" and zone.center then
                zoneCount = zoneCount + 1

                -- Créer un blip
                local blip = AddBlipForRadius(zone.center.x, zone.center.y, zone.center.z, zone.radius + 0.0)
                SetBlipColour(blip, zone.active and 2 or 1) -- Vert si actif, Rouge si inactif
                SetBlipAlpha(blip, 128)

                -- Créer un blip central
                local centerBlip = AddBlipForCoord(zone.center.x, zone.center.y, zone.center.z)
                SetBlipSprite(centerBlip, 501) -- Icône de zone
                SetBlipColour(centerBlip, zone.active and 2 or 1)
                SetBlipScale(centerBlip, 0.5)
                SetBlipAsShortRange(centerBlip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(string.format("%s %s", zone.active and ":dot-green:" or ":dot-red:", zone.name))
                EndTextCommandSetBlipName(centerBlip)

                table.insert(zoneBlips, blip)
                table.insert(zoneBlips, centerBlip)

                -- Stocker les données pour le rendu
                table.insert(zoneMarkers, {
                    center = zone.center,
                    radius = zone.radius,
                    active = zone.active,
                    name = zone.name
                })
            end
        end
    end

    -- Zones restreintes (restricted)
    if drugZones.restricted then
        for _, zone in ipairs(drugZones.restricted) do
            if zone.shape == "circle" and zone.center then
                zoneCount = zoneCount + 1

                -- Créer un blip
                local blip = AddBlipForRadius(zone.center.x, zone.center.y, zone.center.z, zone.radius + 0.0)
                SetBlipColour(blip, 1) -- Rouge pour restricted
                SetBlipAlpha(blip, 128)

                -- Créer un blip central
                local centerBlip = AddBlipForCoord(zone.center.x, zone.center.y, zone.center.z)
                SetBlipSprite(centerBlip, 484) -- Icône d'interdiction
                SetBlipColour(centerBlip, 1)
                SetBlipScale(centerBlip, 0.5)
                SetBlipAsShortRange(centerBlip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(string.format(":ban: %s", zone.name))
                EndTextCommandSetBlipName(centerBlip)

                table.insert(zoneBlips, blip)
                table.insert(zoneBlips, centerBlip)

                table.insert(zoneMarkers, {
                    center = zone.center,
                    radius = zone.radius,
                    active = zone.active,
                    name = zone.name,
                    restricted = true
                })
            end
        end
    end

    if zoneCount == 0 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
            message = "Aucune zone à afficher."
      })
        return
    end

    zoneVisualizationActive = true

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
        message = string.format(zoneCount > 1 and "Visualisation de %d zones activée pour 30 secondes." or "Visualisation de %d zone activée pour 30 secondes.", zoneCount)
    })

    -- Désactiver automatiquement après 30 secondes
    SetTimeout(30000, function()
        if zoneVisualizationActive then
            for _, blip in ipairs(zoneBlips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            zoneBlips = {}
            zoneMarkers = {}
            zoneVisualizationActive = false
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                message = "Visualisation des zones terminée."
          })
        end
    end)
end)

-- Thread pour afficher les cercles au sol
CreateThread(function()
    while true do
        local sleep = 500

        if zoneVisualizationActive and #zoneMarkers > 0 then
            sleep = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, marker in ipairs(zoneMarkers) do
                local distance = #(playerCoords - vector3(marker.center.x, marker.center.y, marker.center.z))

                -- Afficher seulement si le joueur est proche (moins de 500m)
                if distance < 500.0 then
                    local color = marker.restricted and {r = 255, g = 0, b = 0} or (marker.active and {r = 0, g = 255, b = 0} or {r = 255, g = 165, b = 0})

                    -- Dessiner un cercle au sol
                    DrawMarker(
                        1, -- Type cylindre
                        marker.center.x, marker.center.y, marker.center.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        marker.radius * 2.0, marker.radius * 2.0, 2.0,
                        color.r, color.g, color.b, 50,
                        false, true, 2, false, nil, nil, false
                    )

                    -- Texte 3D au centre de la zone
                    if distance < 100.0 then
                        local statusText = marker.restricted and ":ban: ZONE RESTREINTE" or (marker.active and ":dot-green: ZONE ACTIVE" or ":dot-red: ZONE INACTIVE")
                        DrawText3DZone(marker.center.x, marker.center.y, marker.center.z + 10.0,
                            string.format("~o~%s~s~\n%s\nRayon: %.0fm", marker.name, statusText, marker.radius))
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function DrawText3DZone(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scaleX = scale * fov
    local scaleY = scale * fov

    if onScreen then
        SetTextScale(0.0 * scaleX, 0.4 * scaleY)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextDropshadow(1, 1, 1, 1, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Market OnOpen registrations
if StaffMenu.builderMarket and StaffMenu.builderMarket.OnOpen then StaffMenu.builderMarket.OnOpen(function() StaffMenu.BuildMarketMenu() end) end
if StaffMenu.builderMarketList and StaffMenu.builderMarketList.OnOpen then StaffMenu.builderMarketList.OnOpen(function() StaffMenu.BuildMarketListMenu() end) end
if StaffMenu.builderMarketCreate and StaffMenu.builderMarketCreate.OnOpen then StaffMenu.builderMarketCreate.OnOpen(function() StaffMenu.BuildMarketCreateMenu() end) end
if StaffMenu.builderMarketEdit and StaffMenu.builderMarketEdit.OnOpen then StaffMenu.builderMarketEdit.OnOpen(function() StaffMenu.BuildEditMarketMenu() end) end
if StaffMenu.builderMarketEditGrades and StaffMenu.builderMarketEditGrades.OnOpen then StaffMenu.builderMarketEditGrades.OnOpen(function() StaffMenu.BuildMarketEditGradesMenu() end) end
if StaffMenu.builderMarketItems and StaffMenu.builderMarketItems.OnOpen then StaffMenu.builderMarketItems.OnOpen(function() StaffMenu.BuildMarketItemsMenu() end) end
if StaffMenu.builderMarketAddItem and StaffMenu.builderMarketAddItem.OnOpen then StaffMenu.builderMarketAddItem.OnOpen(function()
    StaffMenu.BuildMarketAddItemMenu()
end) end
if StaffMenu.builderMarketEditItem and StaffMenu.builderMarketEditItem.OnOpen then StaffMenu.builderMarketEditItem.OnOpen(function()
    StaffMenu.BuildMarketEditItemMenu()
end) end
if StaffMenu.builderMarketCategories and StaffMenu.builderMarketCategories.OnOpen then StaffMenu.builderMarketCategories.OnOpen(function() StaffMenu.BuildMarketCategoriesMenu() end) end
if StaffMenu.builderMarketAddCategory and StaffMenu.builderMarketAddCategory.OnOpen then StaffMenu.builderMarketAddCategory.OnOpen(function() StaffMenu.BuildMarketAddCategoryMenu() end) end
if StaffMenu.builderMarketEditCategory and StaffMenu.builderMarketEditCategory.OnOpen then StaffMenu.builderMarketEditCategory.OnOpen(function() StaffMenu.BuildMarketEditCategoryMenu() end) end
if StaffMenu.builderMarketChooseCategory and StaffMenu.builderMarketChooseCategory.OnOpen then StaffMenu.builderMarketChooseCategory.OnOpen(function() StaffMenu.BuildMarketChooseCategoryMenu(StaffMenu.builderMarketChooseCategory, StaffMenu.builderMarketAddItem) end) end
if StaffMenu.builderMarketChooseCategoryEdit and StaffMenu.builderMarketChooseCategoryEdit.OnOpen then StaffMenu.builderMarketChooseCategoryEdit.OnOpen(function() StaffMenu.BuildMarketChooseCategoryMenu(StaffMenu.builderMarketChooseCategoryEdit, StaffMenu.builderMarketEditItem) end) end
if StaffMenu.builderMarketChooseCategoryConfig and StaffMenu.builderMarketChooseCategoryConfig.OnOpen then StaffMenu.builderMarketChooseCategoryConfig.OnOpen(function() StaffMenu.BuildMarketChooseCategoryMenu(StaffMenu.builderMarketChooseCategoryConfig, StaffMenu.builderMarketAddItemConfig) end) end

if StaffMenu.builderMarketAddItemConfig and StaffMenu.builderMarketAddItemConfig.OnOpen then
    StaffMenu.builderMarketAddItemConfig.OnOpen(function()
        StaffMenu.BuildMarketAddItemConfigMenu()
    end)
end

-- Scratch Card Builder
local scratchCardConfig = nil

local function FormatProbability(value)
    local v = value or 0
    if v <= 0 then return "0%" end
    local pct
    if v >= 1 then
        pct = string.format("%.2f%%", v)
    elseif v >= 0.1 then
        pct = string.format("%.2f%%", v)
    elseif v >= 0.01 then
        pct = string.format("%.3f%%", v)
    elseif v >= 0.001 then
        pct = string.format("%.4f%%", v)
    else
        pct = string.format("%.5f%%", v)
    end
    if v < 1 then
        local oneIn = math.floor(100 / v + 0.5)
        local s = tostring(oneIn)
        local formatted = s:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^%s+", "")
        pct = pct .. " (1 sur " .. formatted .. ")"
  end
    return pct
end

function StaffMenu.BuildScratchCardMenu()
    StaffMenu.builderScratchCard.Separator("PROBABILITÉS DE GAIN")

    local prizeTiers = {
        { amount = 500, label = VFW.Math.FormatMoney(500) },
        { amount = 1500, label = VFW.Math.FormatMoney(1500) },
        { amount = 3000, label = VFW.Math.FormatMoney(3000) },
        { amount = 10000, label = VFW.Math.FormatMoney(10000) },
        { amount = 30000, label = VFW.Math.FormatMoney(30000) },
        { amount = 50000, label = VFW.Math.FormatMoney(50000) },
        { amount = 100000, label = VFW.Math.FormatMoney(100000) },
        { amount = 500000, label = VFW.Math.FormatMoney(500000) },
    }

    local totalWinProb = 0
    for _, tier in ipairs(scratchCardConfig.prizeTiers or {}) do
        totalWinProb = totalWinProb + (tier.probability or 0)
    end
    local lossProb = math.max(0, 100 - totalWinProb)

    for i, tier in ipairs(prizeTiers) do
        local currentProb = 0
        for _, configTier in ipairs(scratchCardConfig.prizeTiers or {}) do
            if configTier.amount == tier.amount then
                currentProb = configTier.probability
                break
            end
        end

        StaffMenu.builderScratchCard.Button(":money: " .. tier.label, "Probabilité: " .. FormatProbability(currentProb), nil, "arrow", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Probabilité pour " .. tier.label .. " (Ex: 5.5)", tostring(currentProb))
            if input and input ~= "" then
                local newProb = tonumber(input)
                if newProb and newProb >= 0 and newProb <= 100 then
                    for j, configTier in ipairs(scratchCardConfig.prizeTiers) do
                        if configTier.amount == tier.amount then
                            scratchCardConfig.prizeTiers[j].probability = newProb
                            break
                        end
                    end
                    StaffMenu.builderScratchCard.refresh()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette valeur n'est pas valide (0-100)." })
                end
            end
        end)
    end

    StaffMenu.builderScratchCard.Separator("RÉSUMÉ")

    StaffMenu.builderScratchCard.Button(":chart: Probabilité de perte", FormatProbability(lossProb), nil, nil, true, function() end)
    StaffMenu.builderScratchCard.Button(":chart: Probabilité de gain", FormatProbability(totalWinProb), nil, nil, true, function() end)

    StaffMenu.builderScratchCard.Separator("ACTIONS")

    StaffMenu.builderScratchCard.Button(":save: SAUVEGARDER", "Enregistrer la configuration", nil, "arrow", false, function()
        TriggerServerEvent("core:scratchcard:saveConfig", scratchCardConfig)
        Citizen.Wait(150)
        local fresh = TriggerServerCallback("core:scratchcard:getConfig")
        if fresh and fresh.prizeTiers then
            scratchCardConfig = fresh
        end
        StaffMenu.builderScratchCard.refresh()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Configuration sauvegardée et rechargée depuis la BDD." })
    end)

    StaffMenu.builderScratchCard.Button(":refresh: RECHARGER", "Recharger depuis la BDD", nil, "arrow", false, function()
        local fresh = TriggerServerCallback("core:scratchcard:getConfig")
        if fresh and fresh.prizeTiers then
            scratchCardConfig = fresh
        end
        StaffMenu.builderScratchCard.refresh()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Configuration rechargée." })
    end)
end

StaffMenu.builderScratchCard.OnOpen(function()
    scratchCardConfig = TriggerServerCallback("core:scratchcard:getConfig")
    if not scratchCardConfig or not scratchCardConfig.prizeTiers then
        scratchCardConfig = {
            prizeTiers = {
                { amount = 500, probability = 30 },
                { amount = 1500, probability = 10 },
                { amount = 3000, probability = 2 },
                { amount = 10000, probability = 0.3 },
                { amount = 30000, probability = 0.02 },
                { amount = 50000, probability = 0.015 },
                { amount = 100000, probability = 0.01 },
                { amount = 500000, probability = 0.008 },
            }
        }
    end
    StaffMenu.BuildScratchCardMenu()
end)

-- ========================================================================
-- DOJ PERMISSIONS BUILDER
-- ========================================================================

local DOJ_PERM_LABELS = {
    doj_access = "Accès au panel DOJ",
    view_complaints = "Voir les plaintes",
    view_depositions = "Voir les dépositions",
    view_traffic_tickets = "Voir les PV routiers",
    view_arrest_reports = "Voir les rapports d'arrestation",
    view_criminal_records = "Voir les casiers judiciaires",
    view_fines = "Voir les amendes",
    view_warrants = "Voir les mandats",
    view_intervention_reports = "Voir les rapports d'intervention",
    view_seizure_reports = "Voir les rapports de saisie",
    view_dossier_content = "Voir le contenu détaillé des dossiers",
    search_citizens = "Recherche de citoyens",
    manage_warrants = "Gérer les mandats",
    update_warrant_status = "Exécuter ou annuler un mandat",
    view_police_officers = "Voir les agents police en service",
    edit_dossier = "Modifier un dossier",
    delete_dossier = "Supprimer un dossier",
}

local DOJ_PERM_ORDER = {
    "doj_access",
    "view_complaints",
    "view_depositions",
    "view_traffic_tickets",
    "view_arrest_reports",
    "view_criminal_records",
    "view_fines",
    "view_warrants",
    "view_intervention_reports",
    "view_seizure_reports",
    "view_dossier_content",
    "search_citizens",
    "manage_warrants",
    "update_warrant_status",
    "view_police_officers",
    "edit_dossier",
    "delete_dossier",
}

local function DojGradeLabel(grade)
    if type(grade) ~= "table" then return "Grade" end
    return grade.label or ("Grade " .. tostring(grade.grade))
end

StaffMenu.builderDOJ._selectedGrade = nil
StaffMenu.builderDOJ._gradesCache = nil

StaffMenu.builderDOJ.OnOpen(function()
    StaffMenu.builderDOJ.ClearItems()
    StaffMenu.builderDOJ._selectedGrade = nil

    StaffMenu.builderDOJ.Separator("PERMISSIONS DOJ")

    local grades = StaffMenu.builderDOJ._gradesCache or TriggerServerCallback("doj:getGradesPermissions")
    StaffMenu.builderDOJ._gradesCache = grades

    if not grades or #grades == 0 then
        StaffMenu.builderDOJ.Button("Aucun grade trouvé", "Le job DOJ n'existe pas ou n'a pas de grades", nil, nil, false, function() end)
        return
    end

    for _, grade in ipairs(grades) do
        if type(grade.permissions) ~= "table" then grade.permissions = {} end
        local enabledCount = 0
        for _, permName in ipairs(DOJ_PERM_ORDER) do
            if grade.permissions[permName] then enabledCount = enabledCount + 1 end
        end
        local desc = enabledCount .. "/" .. #DOJ_PERM_ORDER .. " permissions"

      StaffMenu.builderDOJ.Button(
            DojGradeLabel(grade),
            desc,
            nil, "chevron", false,
            function()
                StaffMenu.builderDOJ._selectedGrade = grade
            end,
            StaffMenu.builderDOJPerms
        )
    end
end)

StaffMenu.builderDOJPerms.OnOpen(function()
    StaffMenu.builderDOJPerms.ClearItems()

    local selectedGrade = StaffMenu.builderDOJ._selectedGrade
    if not selectedGrade then return end

    if type(selectedGrade.permissions) ~= "table" then selectedGrade.permissions = {} end

    StaffMenu.builderDOJPerms.Separator("GRADE: " .. DojGradeLabel(selectedGrade))

    for _, permName in ipairs(DOJ_PERM_ORDER) do
        local label = DOJ_PERM_LABELS[permName] or permName
        StaffMenu.builderDOJPerms.Checkbox(
            label, nil, false, selectedGrade.permissions[permName] and true or false,
            function(checked)
                selectedGrade.permissions[permName] = checked and true or nil
                local payload = {}
                for _, name in ipairs(DOJ_PERM_ORDER) do
                    if selectedGrade.permissions[name] then payload[name] = true end
                end
                TriggerServerCallback("doj:updateGradePermissions", {
                    grade = selectedGrade.grade,
                    permissions = payload
                })
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'DOJ',
                    message = label .. ": " .. (checked and "activé" or "désactivé")
                })
            end
        )
    end
end)

-- ========================================================================
-- AMENDES POLICE BUILDER
-- ========================================================================

local FINE_CATEGORIES = {
    { id = "contravention", label = "Contravention" },
    { id = "minor", label = "Délit Mineur" },
    { id = "major", label = "Délit Majeur" },
    { id = "crime", label = "Crime" },
    { id = "custom", label = "Personnalisé" },
}

local selectedFineType = nil

StaffMenu.builderFines.OnOpen(function()
    StaffMenu.builderFines.ClearItems()
    StaffMenu.builderFines.Separator("AMENDES POLICE")

    local fineTypes = TriggerServerCallback("police:getFineTypes")
    if not fineTypes then fineTypes = {} end

    StaffMenu.builderFines.Button("Ajouter une amende", nil, nil, "chevron", false, function()
    end, StaffMenu.builderFinesAdd)

    StaffMenu.builderFines.Separator("LISTE DES AMENDES")

    -- Collecter les catégories connues
    local knownCats = {}
    for _, cat in ipairs(FINE_CATEGORIES) do
        if cat.id ~= "custom" then
            knownCats[cat.id] = true
        end
    end

    -- Afficher les catégories prédéfinies
    for _, cat in ipairs(FINE_CATEGORIES) do
        if cat.id ~= "custom" then
            local catFines = {}
            for _, ft in ipairs(fineTypes) do
                if ft.category == cat.id then
                    catFines[#catFines + 1] = ft
                end
            end

            if #catFines > 0 then
                StaffMenu.builderFines.Separator(cat.label .. " (" .. #catFines .. ")")

                for _, ft in ipairs(catFines) do
                    StaffMenu.builderFines.Button(
                        ft.label,
                        VFW.Math.FormatMoney(ft.amount),
                        nil, "chevron", false,
                        function()
                            selectedFineType = ft
                        end, StaffMenu.builderFinesEdit
                    )
                end
            end
        end
    end

    -- Afficher les catégories personnalisées
    local customCats = {}
    for _, ft in ipairs(fineTypes) do
        if not knownCats[ft.category] then
            if not customCats[ft.category] then
                customCats[ft.category] = {}
            end
            customCats[ft.category][#customCats[ft.category] + 1] = ft
        end
    end

    for catName, catFines in pairs(customCats) do
        StaffMenu.builderFines.Separator(catName:sub(1,1):upper() .. catName:sub(2) .. " (" .. #catFines .. ")")

        for _, ft in ipairs(catFines) do
            StaffMenu.builderFines.Button(
                ft.label,
                VFW.Math.FormatMoney(ft.amount),
                nil, "chevron", false,
                function()
                    selectedFineType = ft
                end, StaffMenu.builderFinesEdit
            )
        end
    end
end)

StaffMenu.builderFinesEdit.OnOpen(function()
    StaffMenu.builderFinesEdit.ClearItems()
    if not selectedFineType then return end

    local ft = selectedFineType
    local catLabel = "Inconnu"
  for _, c in ipairs(FINE_CATEGORIES) do
        if c.id == ft.category then catLabel = c.label break end
    end

    StaffMenu.builderFinesEdit.Separator(ft.label .. " (" .. VFW.Math.FormatMoney(ft.amount) .. ")")

    StaffMenu.builderFinesEdit.Button("Modifier le nom", ft.label, nil, "chevron", false, function()
        local newLabel = VFW.Nui.KeyboardInput(true, "Nouveau nom", ft.label)
        if newLabel and newLabel ~= "" then
            TriggerServerCallback("police:updateFineType", { id = ft.id, label = newLabel, category = ft.category, amount = ft.amount })
            ft.label = newLabel
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Amendes', message = "Nom modifié" })
        end
        StaffMenu.builderFinesEdit.refresh()
    end)

    StaffMenu.builderFinesEdit.Button("Modifier le montant", VFW.Math.FormatMoney(ft.amount), nil, "chevron", false, function()
        local newAmount = VFW.Nui.KeyboardInput(true, "Nouveau montant (" .. LOCALE.currencySymbol .. ")", tostring(ft.amount))
        if newAmount and tonumber(newAmount) then
            TriggerServerCallback("police:updateFineType", { id = ft.id, label = ft.label, category = ft.category, amount = tonumber(newAmount) })
            ft.amount = tonumber(newAmount)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Amendes', message = "Montant modifié" })
        end
        StaffMenu.builderFinesEdit.refresh()
    end)

    local editCatLabels = {}
    local editCatIds = {}
    local editCurrentIndex = 1
    for i, cat in ipairs(FINE_CATEGORIES) do
        editCatLabels[i] = cat.label
        editCatIds[i] = cat.id
        if cat.id == ft.category then editCurrentIndex = i end
    end

    StaffMenu.builderFinesEdit.List("Catégorie", catLabel, false, editCatLabels,
        editCurrentIndex,
        function(index)
            local cats = editCatIds
            local newCat = cats[index]
            TriggerServerCallback("police:updateFineType", { id = ft.id, label = ft.label, category = newCat, amount = ft.amount })
            ft.category = newCat
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Amendes', message = "Catégorie modifiée" })
        end
    )

    StaffMenu.builderFinesEdit.Separator("")

    StaffMenu.builderFinesEdit.Button("Supprimer", nil, nil, "arrow", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer", "")
        if confirm and string.lower(confirm) == "oui" then
            TriggerServerCallback("police:deleteFineType", { id = ft.id })
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Amendes', message = "Amende supprimée" })
            StaffMenu.builderFines.open()
        else
            VFW.ShowNotification({ type = 'ORANGE', content = "Suppression annulée" })
        end
    end)
end)

-- Submenu ajout amende
local newFineCategoryId = "contravention"
local newFineCustomCategory = ""

StaffMenu.builderFinesAdd.OnOpen(function()
    StaffMenu.builderFinesAdd.ClearItems()
    StaffMenu.builderFinesAdd.Separator("NOUVELLE AMENDE")

    -- Catégorie (liste)
    local catLabels = {}
    local catIds = {}
    local currentIndex = 1
    for i, cat in ipairs(FINE_CATEGORIES) do
        catLabels[i] = cat.label
        catIds[i] = cat.id
        if cat.id == newFineCategoryId then currentIndex = i end
    end

    StaffMenu.builderFinesAdd.List("Catégorie", nil, false, catLabels, currentIndex, function(index)
        newFineCategoryId = catIds[index]
        if newFineCategoryId == "custom" then
            newFineCustomCategory = ""
      end
        StaffMenu.builderFinesAdd.refresh()
    end)

    -- Nom de la catégorie personnalisée
    if newFineCategoryId == "custom" then
        StaffMenu.builderFinesAdd.Button("Nom de la catégorie", newFineCustomCategory ~= "" and newFineCustomCategory or "Non défini", nil, "chevron", false, function()
            local name = VFW.Nui.KeyboardInput(true, "Nom de la catégorie personnalisée", newFineCustomCategory)
            if name and name ~= "" then
                newFineCustomCategory = name
                StaffMenu.builderFinesAdd.refresh()
            end
        end)
    end

    -- Label
    StaffMenu.builderFinesAdd.Button("Nom de l'infraction", nil, nil, "chevron", false, function()
        local label = VFW.Nui.KeyboardInput(true, "Nom de l'infraction", "")
        if not label or label == "" then return end

        local amountStr = VFW.Nui.KeyboardInput(true, "Montant par défaut (" .. LOCALE.currencySymbol .. ")", "500")
        if not amountStr or tonumber(amountStr) == nil then return end

        local finalCategory = newFineCategoryId
        if finalCategory == "custom" then
            if newFineCustomCategory == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Amendes', message = "Veuillez définir le nom de la catégorie personnalisée" })
                return
            end
            finalCategory = string.lower(newFineCustomCategory)
        end

        local result = TriggerServerCallback("police:addFineType", {
            label = label,
            category = finalCategory,
            amount = tonumber(amountStr)
        })

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Amendes', message = "Amende ajoutée : " .. label })
            StaffMenu.builderFinesAdd.close()
            Wait(100)
            StaffMenu.builderFines.refresh()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Erreur lors de l'ajout" })
        end
    end)
end)
