---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- FACTION TERRITORIES BUILDER
-- Admin menu for creating and managing faction territories
-- ============================================

local FactionTerritoryBuilder = {}

-- Cache for territories and factions
local territoriesCache = {}
local factionsCache = {}
local selectedTerritory = nil
local polygonPoints = {}
local isDrawingPolygon = false

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function RefreshTerritories()
    territoriesCache = TriggerServerCallback("core:factionTerritories:getAll") or {}
end

local function RefreshFactions()
    factionsCache = TriggerServerCallback("core:factions:getOrganizations", "crew") or {}
end

local function FormatTimestamp(timestamp)
    if not timestamp or timestamp == 0 then
        return "N/A"
  end
    local diff = os.time() - timestamp
    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)

    if hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", mins)
    end
end

local function GetTimeRemaining(expiresAt)
    if not expiresAt or expiresAt == 0 then
        return "N/A"
  end
    local remaining = expiresAt - os.time()
    if remaining <= 0 then
        return "Expire"
  end

    local hours = math.floor(remaining / 3600)
    local mins = math.floor((remaining % 3600) / 60)

    return string.format("%dh %dm", hours, mins)
end

-- ============================================
-- POLYGON DRAWING SYSTEM
-- ============================================

local function StartPolygonDrawing()
    isDrawingPolygon = true
    polygonPoints = {}

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'INFO',
        subtitle = 'Builder',
        message = "Mode dessin polygone actif. Appuyez sur E pour ajouter un point, BACKSPACE pour annuler le dernier, ENTER pour terminer."
  })

    CreateThread(function()
        while isDrawingPolygon do
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Draw existing points
            for i, point in ipairs(polygonPoints) do
                -- Draw marker at point
                DrawMarker(28, point.x, point.y, point.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, nil, nil, false)

                -- Draw line to next point
                if i > 1 then
                    local prevPoint = polygonPoints[i - 1]
                    DrawLine(prevPoint.x, prevPoint.y, prevPoint.z, point.x, point.y, point.z, 0, 255, 0, 255)
                end
            end

            -- Draw line from last point to current position
            if #polygonPoints > 0 then
                local lastPoint = polygonPoints[#polygonPoints]
                DrawLine(lastPoint.x, lastPoint.y, lastPoint.z, coords.x, coords.y, coords.z, 0, 200, 0, 200)
            end

            -- Draw current position marker
            DrawMarker(28, coords.x, coords.y, coords.z - 1.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 255, 0, 150, false, true, 2, nil, nil, false)

            -- Close polygon preview (from last point to first)
            if #polygonPoints >= 3 then
                local firstPoint = polygonPoints[1]
                local lastPoint = polygonPoints[#polygonPoints]
                DrawLine(lastPoint.x, lastPoint.y, lastPoint.z, firstPoint.x, firstPoint.y, firstPoint.z, 0, 100, 255, 150)
            end

            -- Draw help text
            local helpText = string.format("Points: %d | [E] Ajouter point | [BACKSPACE] Annuler | [ENTER] Terminer | [ESC] Quitter", #polygonPoints)
            SetTextComponentFormat("STRING")
            AddTextComponentString(helpText)
            DisplayHelpTextFromStringLabel(0, false, true, -1)

            -- E to add point
            if VFW.Interact.JustPressed(0, 38) then -- E
                table.insert(polygonPoints, { x = coords.x, y = coords.y, z = coords.z })
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            end

            -- Backspace to remove last point
            if IsControlJustPressed(0, 177) then -- BACKSPACE
                if #polygonPoints > 0 then
                    table.remove(polygonPoints)
                    PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                end
            end

            -- Enter to confirm
            if IsControlJustPressed(0, 191) then -- ENTER
                if #polygonPoints >= 3 then
                    isDrawingPolygon = false
                    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", false)
                    return
                else
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Builder',
                        message = "Minimum 3 points requis pour un polygone."
                  })
                end
            end

            -- ESC to cancel
            if IsControlJustPressed(0, 200) then -- ESC
                isDrawingPolygon = false
                polygonPoints = {}
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'INFO',
                    subtitle = 'Builder',
                    message = "Dessin annulé."
              })
                return
            end
        end
    end)
end

local function WaitForPolygonComplete()
    while isDrawingPolygon do
        Wait(100)
    end
    return polygonPoints
end

-- ============================================
-- MAIN MENU
-- ============================================

function StaffMenu.BuildFactionTerritoriesMenu()
    RefreshTerritories()

    local territoryCount = #territoriesCache

    StaffMenu.builderFactionTerritories.Separator("GESTION DES TERRITOIRES")

    StaffMenu.builderFactionTerritories.Button(":plus: CREER UN TERRITOIRE", "Dessiner une nouvelle zone polygonale", nil, "chevron", false, function()
    end, StaffMenu.CreateFactionTerritory)

    StaffMenu.builderFactionTerritories.Button(":report: GÉRER LES TERRITOIRES", string.format(territoryCount > 1 and "%d territoires" or "%d territoire", territoryCount), nil, "chevron", false, function()
    end, StaffMenu.ManageFactionTerritories)

    StaffMenu.builderFactionTerritories.Button(":settings: PARAMÈTRES", "Configuration du système", nil, "chevron", false, function()
    end, StaffMenu.FactionTerritorySettings)

    StaffMenu.builderFactionTerritories.Separator("ACTIONS RAPIDES")

    StaffMenu.builderFactionTerritories.Button(":refresh: RECHARGER DEPUIS BDD", "Recharger les territoires", nil, "arrow", false, function()
        TriggerServerEvent("core:factionTerritories:reload")
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Builder',
            message = "Territoires rechargés."
      })
        Wait(500)
        RefreshTerritories()
        StaffMenu.builderFactionTerritories.refresh()
    end)
end

-- ============================================
-- CREATE TERRITORY MENU
-- ============================================

function StaffMenu.BuildCreateFactionTerritoryMenu()
    StaffMenu.CreateFactionTerritory.Separator("CREATION DE TERRITOIRE")

    StaffMenu.CreateFactionTerritory.Button(":map: DESSINER LE POLYGONE", "Définir la zone avec des points", nil, "arrow", false, function()
        StaffMenu.CreateFactionTerritory.close()

        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            subtitle = 'Builder',
            message = "Déplacez-vous et appuyez sur E pour poser des points. Minimum 3 points."
      })

        StartPolygonDrawing()
        local points = WaitForPolygonComplete()

        if points and #points >= 3 then
            -- Ask for name
            VFW.Nui.Focus(true)
            local name = VFW.Nui.KeyboardInput(true, "Nom du territoire", "")
            VFW.Nui.Focus(false)

            if name and name ~= "" then
                -- Convert points to 2D format for database
                local polygon = {}
                for _, p in ipairs(points) do
                    table.insert(polygon, { x = p.x, y = p.y })
                end

                TriggerServerEvent("core:factionTerritories:create", name, polygon)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Territoire '" .. name .. "' créé avec " .. #polygon .. " points."
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Builder',
                    message = "Création annulée : ce nom n'est pas valide."
              })
            end
        end

        polygonPoints = {}
    end)

    StaffMenu.CreateFactionTerritory.Separator("INSTRUCTIONS")

    StaffMenu.CreateFactionTerritory.Button(":info: COMMENT DESSINER", nil, nil, nil, true, function() end)
    StaffMenu.CreateFactionTerritory.Button(" 1. Appuyez sur E pour poser un point", nil, nil, nil, true, function() end)
    StaffMenu.CreateFactionTerritory.Button(" 2. Déplacez-vous et répétez", nil, nil, nil, true, function() end)
    StaffMenu.CreateFactionTerritory.Button(" 3. Minimum 3 points requis", nil, nil, nil, true, function() end)
    StaffMenu.CreateFactionTerritory.Button(" 4. ENTER pour confirmer", nil, nil, nil, true, function() end)
    StaffMenu.CreateFactionTerritory.Button(" 5. BACKSPACE pour annuler dernier point", nil, nil, nil, true, function() end)
end

-- ============================================
-- MANAGE TERRITORIES MENU
-- ============================================

function StaffMenu.BuildManageFactionTerritoriesMenu()
    RefreshTerritories()

    if #territoriesCache == 0 then
        StaffMenu.ManageFactionTerritories.Separator("AUCUN TERRITOIRE")
        StaffMenu.ManageFactionTerritories.Button("Aucun territoire configuré", nil, nil, nil, true, function() end)
        return
    end

    StaffMenu.ManageFactionTerritories.Separator("LISTE DES TERRITOIRES")

    for _, territory in ipairs(territoriesCache) do
        local ownerLabel = territory.owner or "Neutre"
      local statusIcon = territory.owner and ":dot-red:" or ":dot-grey:"
      local expiresLabel = territory.expires_at and GetTimeRemaining(territory.expires_at) or ""

      local description = string.format("Proprietaire: %s", ownerLabel)
        if expiresLabel ~= "" and expiresLabel ~= "N/A" then
            description = description .. " | Expire: " .. expiresLabel
        end

        StaffMenu.ManageFactionTerritories.Button(
            statusIcon .. " " .. territory.name,
            description,
            nil, "chevron", false,
            function()
                selectedTerritory = territory
            end,
            StaffMenu.EditFactionTerritory
        )
    end
end

-- ============================================
-- EDIT TERRITORY MENU
-- ============================================

function StaffMenu.BuildEditFactionTerritoryMenu()
    if not selectedTerritory then
        StaffMenu.EditFactionTerritory.close()
        StaffMenu.EditFactionTerritory.parent.open()
        return
    end

    RefreshFactions()

    local territory = selectedTerritory
    local ownerLabel = territory.owner or "Neutre"

  StaffMenu.EditFactionTerritory.Separator(territory.name:upper())

    -- Info
    StaffMenu.EditFactionTerritory.Button(":pin: ID: " .. territory.id, nil, nil, nil, true, function() end)
    StaffMenu.EditFactionTerritory.Button(":user: Proprietaire: " .. ownerLabel, nil, nil, nil, true, function() end)

    if territory.expires_at and territory.expires_at > 0 then
        StaffMenu.EditFactionTerritory.Button(":clock: Expire dans: " .. GetTimeRemaining(territory.expires_at), nil, nil, nil, true, function() end)
    end

    -- Sales info
    if territory.sales and next(territory.sales) then
        StaffMenu.EditFactionTerritory.Separator("VENTES PAR FACTION")
        for factionName, data in pairs(territory.sales) do
            StaffMenu.EditFactionTerritory.Button(
                " " .. factionName .. ": " .. (data.sales_count or 0) .. " ventes",
                nil, nil, nil, true, function() end
            )
        end
    end

    StaffMenu.EditFactionTerritory.Separator("ACTIONS")

    -- Rename
    StaffMenu.EditFactionTerritory.Button(":edit: RENOMMER", nil, nil, "arrow", false, function()
        VFW.Nui.Focus(true)
        local newName = VFW.Nui.KeyboardInput(true, "Nouveau nom", territory.name)
        VFW.Nui.Focus(false)

        if newName and newName ~= "" and newName ~= territory.name then
            TriggerServerEvent("core:factionTerritories:update", territory.id, { name = newName })
            Wait(500)
            RefreshTerritories()
            -- Find updated territory
            for _, t in ipairs(territoriesCache) do
                if t.id == territory.id then
                    selectedTerritory = t
                    break
                end
            end
            StaffMenu.EditFactionTerritory.refresh()
        end
    end)

    -- Set owner
    StaffMenu.EditFactionTerritory.Button(":trophy: DEFINIR PROPRIETAIRE", nil, nil, "arrow", false, function()
        local options = { { label = "Neutre (aucun)", value = nil } }

        for factionName, factionData in pairs(factionsCache) do
            table.insert(options, {
                label = factionData.label or factionName,
                value = factionName
            })
        end

        -- Simple selection using notifications for now
        VFW.Nui.Focus(true)
        local factionInput = VFW.Nui.KeyboardInput(true, "Nom de la faction (vide = neutre)", territory.owner or "")
        VFW.Nui.Focus(false)

        if factionInput == "" then
            factionInput = nil
        end

        TriggerServerEvent("core:factionTerritories:adminSetOwner", territory.id, factionInput)
        Wait(500)
        RefreshTerritories()
        for _, t in ipairs(territoriesCache) do
            if t.id == territory.id then
                selectedTerritory = t
                break
            end
        end
        StaffMenu.EditFactionTerritory.refresh()
    end)

    -- Teleport to territory center
    StaffMenu.EditFactionTerritory.Button(":pin: TELEPORTER AU CENTRE", nil, nil, "arrow", false, function()
        if territory.polygon and #territory.polygon > 0 then
            -- Calculate center
            local sumX, sumY = 0, 0
            for _, point in ipairs(territory.polygon) do
                sumX = sumX + point.x
                sumY = sumY + point.y
            end
            local centerX = sumX / #territory.polygon
            local centerY = sumY / #territory.polygon

            -- Get ground Z
            local found, groundZ = GetGroundZFor_3dCoord(centerX, centerY, 1000.0, false)
            if not found then groundZ = 50.0 end

            SetEntityCoords(PlayerPedId(), centerX, centerY, groundZ + 1.0, false, false, false, false)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Builder',
                message = "Téléporté au centre du territoire."
          })
        end
    end)

    -- Delete
    StaffMenu.EditFactionTerritory.Separator("DANGER")

    StaffMenu.EditFactionTerritory.Button(":trash: SUPPRIMER LE TERRITOIRE", "Action irréversible", nil, "arrow", false, function()
        -- Confirmation
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            subtitle = 'Builder',
            message = "Appuyez sur ENTER pour confirmer la suppression."
      })

        CreateThread(function()
            local timeout = 5000
            local startTime = GetGameTimer()

            while GetGameTimer() - startTime < timeout do
                Wait(0)
                if IsControlJustPressed(0, 191) then -- ENTER
                    TriggerServerEvent("core:factionTerritories:delete", territory.id)
                    Wait(500)
                    RefreshTerritories()
                    selectedTerritory = nil
                    StaffMenu.EditFactionTerritory.close()
                    StaffMenu.EditFactionTerritory.parent.open()
                    return
                end
                if IsControlJustPressed(0, 200) then -- ESC
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'INFO',
                        subtitle = 'Builder',
                        message = "Suppression annulée."
                  })
                    return
                end
            end
        end)
    end)
end

-- ============================================
-- SETTINGS MENU
-- ============================================

function StaffMenu.BuildFactionTerritorySettingsMenu()
    local settings = TriggerServerCallback("core:factionTerritories:getSettings") or {}

    StaffMenu.FactionTerritorySettings.Separator("CONFIGURATION")

    StaffMenu.FactionTerritorySettings.Checkbox(
        "SYSTÈME ACTIF",
        nil, false,
        settings.enabled == true,
        function(checked)
            -- Would need to add a server event for this
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Builder',
                message = "Modification du statut en base de données requise."
          })
        end
    )

    StaffMenu.FactionTerritorySettings.Separator("PARAMÈTRES")

    StaffMenu.FactionTerritorySettings.Button(
        ":chart: SEUIL DE CAPTURE",
        tostring(settings.salesThreshold or 50) .. " ventes",
        nil, nil, true, function() end
    )

    StaffMenu.FactionTerritorySettings.Button(
        ":clock: DUREE PROPRIETE",
        tostring(settings.ownershipDurationHours or 48) .. " heures",
        nil, nil, true, function() end
    )

    StaffMenu.FactionTerritorySettings.Button(
        ":money: BONUS PROPRIETAIRE",
        tostring(settings.ownerBonusPercent or 25) .. "%",
        nil, nil, true, function() end
    )

    StaffMenu.FactionTerritorySettings.Button(
        ":bell: CHANCE ALERTE",
        tostring(settings.alertChancePercent or 5) .. "%",
        nil, nil, true, function() end
    )

    StaffMenu.FactionTerritorySettings.Separator("INFORMATIONS")
    StaffMenu.FactionTerritorySettings.Button("Les paramètres sont modifiables", nil, nil, nil, true, function() end)
    StaffMenu.FactionTerritorySettings.Button("directement en base de données", nil, nil, nil, true, function() end)
    StaffMenu.FactionTerritorySettings.Button("(table: faction_territory_settings)", nil, nil, nil, true, function() end)
end

-- ============================================
-- MENU REGISTRATION
-- ============================================

StaffMenu.builderFactionTerritories.OnOpen(function()
    StaffMenu.BuildFactionTerritoriesMenu()
end)

StaffMenu.CreateFactionTerritory.OnOpen(function()
    StaffMenu.BuildCreateFactionTerritoryMenu()
end)

StaffMenu.ManageFactionTerritories.OnOpen(function()
    StaffMenu.BuildManageFactionTerritoriesMenu()
end)

StaffMenu.EditFactionTerritory.OnOpen(function()
    StaffMenu.BuildEditFactionTerritoryMenu()
end)

StaffMenu.FactionTerritorySettings.OnOpen(function()
    StaffMenu.BuildFactionTerritorySettingsMenu()
end)

-- ============================================
-- VISUALIZATION THREAD
-- Draw territories on map when in builder
-- ============================================

local showTerritoryMarkers = false

RegisterNetEvent("core:factionTerritories:refresh", function()
    if not showTerritoryMarkers then return end
    RefreshTerritories()
end)

-- Toggle territory visualization
RegisterCommand("toggleterritories", function()
    showTerritoryMarkers = not showTerritoryMarkers
    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'INFO',
        subtitle = 'Builder',
        message = showTerritoryMarkers and "Affichage des territoires activé." or "Affichage des territoires désactivé."
  })
end, false)

CreateThread(function()
    while true do
        local sleep = 1000

        if showTerritoryMarkers and #territoriesCache > 0 then
            sleep = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, territory in ipairs(territoriesCache) do
                if territory.polygon and #territory.polygon >= 3 then
                    -- Calculate center
                    local sumX, sumY = 0, 0
                    for _, point in ipairs(territory.polygon) do
                        sumX = sumX + point.x
                        sumY = sumY + point.y
                    end
                    local centerX = sumX / #territory.polygon
                    local centerY = sumY / #territory.polygon

                    local dist = #(playerCoords - vector3(centerX, centerY, playerCoords.z))

                    if dist < 500.0 then
                        -- Draw polygon lines
                        local color = territory.owner and { r = 255, g = 0, b = 0 } or { r = 100, g = 100, b = 100 }

                        for i = 1, #territory.polygon do
                            local p1 = territory.polygon[i]
                            local p2 = territory.polygon[(i % #territory.polygon) + 1]

                            DrawLine(
                                p1.x, p1.y, playerCoords.z,
                                p2.x, p2.y, playerCoords.z,
                                color.r, color.g, color.b, 200
                            )

                            -- Draw vertical lines at corners
                            DrawLine(
                                p1.x, p1.y, playerCoords.z - 5.0,
                                p1.x, p1.y, playerCoords.z + 20.0,
                                color.r, color.g, color.b, 100
                            )
                        end

                        -- Draw text at center if close enough
                        if dist < 150.0 then
                            local ownerText = territory.owner or "Neutre"
                          SetTextComponentFormat("STRING")
                            AddTextComponentString(territory.name .. " (" .. ownerText .. ")")
                            DisplayHelpTextFromStringLabel(0, false, true, -1)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

return FactionTerritoryBuilder
