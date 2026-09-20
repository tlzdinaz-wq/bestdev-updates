---@meta _
---@diagnostic disable: duplicate-doc-field

local teleportData = {
    id = nil,
    label = nil,
    entry = nil,
    exit = nil,
    isInstance = false,
    isUpdate = false
}

local function resetTeleportData()
    teleportData = {
        id = nil,
        label = nil,
        entry = nil,
        exit = nil,
        isInstance = false,
        isUpdate = false
    }
end

local function closeTeleportCreator(goToList)
    resetTeleportData()
    StaffMenu.CreateTeleport.close()

    if goToList then
        StaffMenu.TeleportList.open()
    else
        StaffMenu.builderTeleport.open()
    end
end

local function checkValidTeleportData()
    if not teleportData.label or not teleportData.entry or not teleportData.exit then
        return false
    end
    return true
end

local function getPlayerCoordsWithHeading()
    local ped <const> = PlayerPedId()
    local coords <const> = GetEntityCoords(ped)
    local heading <const> = GetEntityHeading(ped)

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading
    }
end

local function formatCoords(coords)
    if not coords then return "Non défini" end
    return ("%.1f, %.1f, %.1f"):format(coords.x, coords.y, coords.z)
end

function StaffMenu.BuildCreateTeleportMenu()
    StaffMenu.CreateTeleport.ClearItems()

    StaffMenu.CreateTeleport.Separator(teleportData.isUpdate and "MODIFIER UN POINT" or "CRÉER UN POINT")

    StaffMenu.CreateTeleport.Button("NOM DU POINT", nil, teleportData.label or "Non défini", "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du point de téléportation")

        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Téléportation',
                message = "Ce nom n'est pas valide"
          })
        end

        teleportData.label = name
        StaffMenu.CreateTeleport.refresh()
    end)

    StaffMenu.CreateTeleport.Separator("POSITIONS")

    StaffMenu.CreateTeleport.Button(":pin: POSITION D'ENTRÉE", "Utilise ta position actuelle", formatCoords(teleportData.entry), "chevron", false, function()
        teleportData.entry = getPlayerCoordsWithHeading()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Téléportation', message = "Position d'entrée enregistrée" })
        StaffMenu.CreateTeleport.refresh()
    end)

    StaffMenu.CreateTeleport.Button(":pin: POSITION DE SORTIE", "Utilise ta position actuelle", formatCoords(teleportData.exit), "chevron", false, function()
        teleportData.exit = getPlayerCoordsWithHeading()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Téléportation', message = "Position de sortie enregistrée" })
        StaffMenu.CreateTeleport.refresh()
    end)

    StaffMenu.CreateTeleport.Separator("OPTIONS")

    StaffMenu.CreateTeleport.Button(
        "MODE INSTANCE",
        "Téléporte dans un bucket partagé par groupe",
        teleportData.isInstance and "Activé" or "Désactivé",
        teleportData.isInstance and "check" or "chevron",
        false,
        function()
            teleportData.isInstance = not teleportData.isInstance
            StaffMenu.CreateTeleport.refresh()
        end
    )

    StaffMenu.CreateTeleport.Separator()

    StaffMenu.CreateTeleport.Button(teleportData.isUpdate and ":check: MODIFIER LE POINT" or ":check: CRÉER LE POINT", nil, nil, "chevron", false, function()
        if not checkValidTeleportData() then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Téléportation',
                message = "Ces données ne sont pas valides. Nom, position d'entrée et de sortie obligatoires."
          })
        end

        local isUpdate <const> = teleportData.isUpdate
        local payload <const> = {
            id = teleportData.id,
            label = teleportData.label,
            entry = teleportData.entry,
            exit = teleportData.exit,
            isInstance = teleportData.isInstance
        }

        local result <const> = TriggerServerCallback(
            isUpdate and "teleportBuilder:server:update" or "teleportBuilder:server:create",
            payload
        )

        if not result then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Téléportation',
                message = "Échec de l'enregistrement. Vérifie tes permissions."
          })
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Téléportation',
            message = isUpdate and ("Point « " .. result.label .. " » modifié") or ("Point « " .. result.label .. " » créé")
        })

        closeTeleportCreator(true)
    end)

    StaffMenu.CreateTeleport.Button(":x: Annuler", nil, nil, "chevron", false, function()
        closeTeleportCreator(false)
    end)
end

local currentTeleport
local TELEPORTS_PER_PAGE = 25
StaffMenu.teleportListPage = StaffMenu.teleportListPage or 1
StaffMenu.teleportListSearch = StaffMenu.teleportListSearch or nil

function StaffMenu.BuildTeleportBuilderMenu()
    StaffMenu.builderTeleport.ClearItems()

    StaffMenu.builderTeleport.Button(":plus: CRÉER UN POINT", "Créer un nouveau point de téléportation", nil, "chevron", false, function()
        resetTeleportData()
    end, StaffMenu.CreateTeleport)

    StaffMenu.builderTeleport.Button(":report: LISTE DES POINTS", "Gérer les points existants", nil, "chevron", false, function()
    end, StaffMenu.TeleportList)
end

local function getCachedPoints()
    local list = {}
    local cache = TeleportBuilder and TeleportBuilder.cache or {}
    for i = 1, #cache do
        list[#list + 1] = cache[i]
    end
    return list
end

function StaffMenu.BuildTeleportBuilderListMenu()
    StaffMenu.TeleportList.ClearItems()

    local points = getCachedPoints()

    local searchLabel = StaffMenu.teleportListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.teleportListSearch == nil and "Nom du point" or StaffMenu.teleportListSearch
    StaffMenu.TeleportList.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.teleportListSearch ~= nil then
            StaffMenu.teleportListSearch = nil
            StaffMenu.teleportListPage = 1
            StaffMenu.TeleportList.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du point")
        if query == nil or query == "" then return end
        StaffMenu.teleportListSearch = query
        StaffMenu.teleportListPage = 1
        StaffMenu.TeleportList.refresh()
    end)

    if not points or #points == 0 then
        StaffMenu.TeleportList.Separator(nil)
        StaffMenu.TeleportList.Button("AUCUN POINT", nil, nil, nil, false, function() end)
        return
    end

    table.sort(points, function(a, b)
        return (a.label or ""):lower() < (b.label or ""):lower()
    end)

    local filtered = points
    if StaffMenu.teleportListSearch and StaffMenu.teleportListSearch ~= "" then
        local q = StaffMenu.teleportListSearch:lower()
        filtered = {}
        for _, p in ipairs(points) do
            if (p.label or ""):lower():find(q, 1, true) then
                filtered[#filtered + 1] = p
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / TELEPORTS_PER_PAGE), 1)
    if StaffMenu.teleportListPage > totalPages then StaffMenu.teleportListPage = totalPages end
    if StaffMenu.teleportListPage < 1 then StaffMenu.teleportListPage = 1 end
    local startIdx = (StaffMenu.teleportListPage - 1) * TELEPORTS_PER_PAGE + 1
    local endIdx = math.min(startIdx + TELEPORTS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.teleportListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d points, page %d sur %d", totalItems, StaffMenu.teleportListPage, totalPages)
    end
    StaffMenu.TeleportList.Separator(header)

    if totalItems == 0 then
        StaffMenu.TeleportList.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local point = filtered[idx]
        local icon = point.isInstance and ":lock:" or ":compass:"
      local sub = point.isInstance and "Mode instance (bucket)" or "TP simple"

      StaffMenu.TeleportList.Button(icon .. " " .. (point.label or "Sans nom"), sub, nil, "chevron", false, function()
            currentTeleport = point
        end, StaffMenu.TeleportManage)
    end

    if totalPages > 1 then
        StaffMenu.TeleportList.Separator(nil)
        if StaffMenu.teleportListPage > 1 then
            StaffMenu.TeleportList.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.teleportListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.teleportListPage = StaffMenu.teleportListPage - 1
                StaffMenu.TeleportList.refresh()
            end)
        end
        if StaffMenu.teleportListPage < totalPages then
            StaffMenu.TeleportList.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.teleportListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.teleportListPage = StaffMenu.teleportListPage + 1
                StaffMenu.TeleportList.refresh()
            end)
        end
    end
end

function StaffMenu.BuildManageTeleportMenu()
    StaffMenu.TeleportManage.ClearItems()

    if not currentTeleport then
        StaffMenu.TeleportManage.Button("AUCUN POINT SÉLECTIONNÉ", nil, nil, nil, false, function() end)
        return
    end

    StaffMenu.TeleportManage.Separator(currentTeleport.label or "Point")

    StaffMenu.TeleportManage.Button(":target: TÉLÉPORTER À L'ENTRÉE", nil, nil, "chevron", false, function()
        if not currentTeleport.entry then
            return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Téléportation', message = "Aucune position d'entrée" })
        end
        SetEntityCoords(PlayerPedId(), currentTeleport.entry.x, currentTeleport.entry.y, currentTeleport.entry.z + 1.0, false, false, false, false)
    end)

    StaffMenu.TeleportManage.Button(":target: TÉLÉPORTER À LA SORTIE", nil, nil, "chevron", false, function()
        if not currentTeleport.exit then
            return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Téléportation', message = "Aucune position de sortie" })
        end
        SetEntityCoords(PlayerPedId(), currentTeleport.exit.x, currentTeleport.exit.y, currentTeleport.exit.z + 1.0, false, false, false, false)
    end)

    StaffMenu.TeleportManage.Button(":monitor: MODIFIER LE POINT", nil, nil, "chevron", false, function()
        teleportData = {
            id = currentTeleport.id,
            label = currentTeleport.label,
            entry = currentTeleport.entry,
            exit = currentTeleport.exit,
            isInstance = currentTeleport.isInstance == true,
            isUpdate = true
        }
    end, StaffMenu.CreateTeleport)

    StaffMenu.TeleportManage.Button(":trash: SUPPRIMER LE POINT", nil, nil, "chevron", false, function()
        TriggerServerEvent("teleportBuilder:server:delete", currentTeleport.id)
        currentTeleport = nil
        StaffMenu.TeleportManage.close()
        StaffMenu.TeleportList.open()
    end)
end
