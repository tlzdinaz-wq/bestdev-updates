---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- ADMIN FACTION TERRITORIES CLIENT
-- Client-side module for managing faction territories (staff)
-- ============================================

local AdminFactionTerritoriesClient = {}

-- Cache
local territoriesCache = {}
local factionsCache = {}
local isTabletOpen = false
local pendingTerritoryName = nil
local pendingDisplayNumber = nil
local pendingDisplayColor = nil

-- Polygon drawing state
local isDrawingPolygon = false
local polygonPoints = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

---Refresh territories from server
function AdminFactionTerritoriesClient.RefreshTerritories()
    territoriesCache = TriggerServerCallback("core:factionTerritories:getAll") or {}
end

---Refresh factions from server (with SQL id for territory ownership)
function AdminFactionTerritoriesClient.RefreshFactions()
    factionsCache = TriggerServerCallback("core:factionTerritories:getFactions") or {}
end

-- ============================================
-- POLYGON DRAWING SYSTEM
-- ============================================

local function StartPolygonDrawing(territoryName, displayNumber, displayColor)
    isDrawingPolygon = true
    polygonPoints = {}
    pendingTerritoryName = territoryName
    pendingDisplayNumber = displayNumber
    pendingDisplayColor = displayColor

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'WARNING',
        subtitle = 'Gestion Territoires',
        message = "Mode dessin polygone actif. E = ajouter un point, BACKSPACE = annuler, ENTER = terminer."
    })

    CreateThread(function()
        while isDrawingPolygon do
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Draw existing points
            for i, point in ipairs(polygonPoints) do
                -- Draw marker at point
                DrawMarker(28, point.x, point.y, point.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 99, 102, 241, 100, false, true, 2, nil, nil, false)

                -- Draw line to next point
                if i > 1 then
                    local prevPoint = polygonPoints[i - 1]
                    DrawLine(prevPoint.x, prevPoint.y, prevPoint.z, point.x, point.y, point.z, 99, 102, 241, 255)
                end
            end

            -- Draw line from last point to current position
            if #polygonPoints > 0 then
                local lastPoint = polygonPoints[#polygonPoints]
                DrawLine(lastPoint.x, lastPoint.y, lastPoint.z, coords.x, coords.y, coords.z, 99, 102, 241, 200)
            end

            -- Draw current position marker
            DrawMarker(28, coords.x, coords.y, coords.z - 1.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 255, 0, 150, false, true, 2, nil, nil, false)

            -- Close polygon preview (from last point to first)
            if #polygonPoints >= 3 then
                local firstPoint = polygonPoints[1]
                local lastPoint = polygonPoints[#polygonPoints]
                DrawLine(lastPoint.x, lastPoint.y, lastPoint.z, firstPoint.x, firstPoint.y, firstPoint.z, 99, 102, 241, 150)
            end

            -- Draw help text
            local helpText = string.format("Points: %d | [E] Ajouter | [BACKSPACE] Annuler | [ENTER] Terminer | [ESC] Quitter", #polygonPoints)
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

                    -- Convert to 2D polygon
                    local polygon = {}
                    for _, p in ipairs(polygonPoints) do
                        table.insert(polygon, { x = p.x, y = p.y })
                    end

                    -- Create the territory
                    TriggerServerEvent("core:factionTerritories:create", pendingTerritoryName, polygon, pendingDisplayNumber, pendingDisplayColor)

                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'SUCCESS',
                        subtitle = 'Gestion Territoires',
                        message = "Territoire '" .. pendingTerritoryName .. "' créé avec " .. #polygon .. " points."
                    })

                    -- Re-open the tablet
                    Wait(500)
                    AdminFactionTerritoriesClient.OpenTablet()
                    return
                else
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Gestion Territoires',
                        message = "Minimum 3 points requis pour créer un polygone."
                    })
                end
            end

            -- ESC to cancel
            if IsControlJustPressed(0, 200) then -- ESC
                isDrawingPolygon = false
                polygonPoints = {}
                pendingTerritoryName = nil
                pendingDisplayNumber = nil
                pendingDisplayColor = nil
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'WARNING',
                    subtitle = 'Gestion Territoires',
                    message = "Dessin du polygone annulé."
                })

                -- Re-open the tablet
                Wait(100)
                AdminFactionTerritoriesClient.OpenTablet()
                return
            end
        end
    end)
end

-- ============================================
-- TABLET UI
-- ============================================

---Open the admin territories tablet
function AdminFactionTerritoriesClient.OpenTablet()
    if isTabletOpen then return end
    if isDrawingPolygon then return end

    -- Permission check
    if not VFW.PlayerGlobalData.permissions["territory_builder"] then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'Gestion Territoires',
            message = "Vous n'avez pas la permission d'accéder à ce menu."
        })
        return
    end

    isTabletOpen = true

    -- Refresh data
    AdminFactionTerritoriesClient.RefreshTerritories()
    AdminFactionTerritoriesClient.RefreshFactions()
    local settings = TriggerServerCallback("core:factionTerritories:getSettings") or {}

    -- Prepare data for NUI
    local data = {
        territories = territoriesCache,
        factions = factionsCache,
        settings = settings
    }

    -- Send to NUI
    SendNUIMessage({
        action = "openAdminFactionTerritories",
        data = data
    })

    VFW.Nui.Focus(true)
end

---Close the admin territories tablet
function AdminFactionTerritoriesClient.CloseTablet()
    if not isTabletOpen then return end

    isTabletOpen = false

    SendNUIMessage({
        action = "closeAdminFactionTerritories"
    })

    VFW.Nui.Focus(false)
end

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback("adminFactionTerritories:close", function(_, cb)
    AdminFactionTerritoriesClient.CloseTablet()
    cb({})
end)

RegisterNUICallback("adminFactionTerritories:refresh", function(_, cb)
    AdminFactionTerritoriesClient.RefreshTerritories()

    cb({
        territories = territoriesCache
    })
end)

RegisterNUICallback("adminFactionTerritories:startDrawPolygon", function(data, cb)
    local name = data.name
    if not name or name == "" then
        cb({ success = false })
        return
    end

    -- Validation chiffre/couleur (optionnels)
    local displayNumber = nil
    if data.displayNumber ~= nil and data.displayNumber ~= "" then
        local n = tonumber(data.displayNumber)
        if n and n >= 0 and n <= 999 then
            displayNumber = n
        end
    end

    local displayColor = nil
    if type(data.displayColor) == "string" and data.displayColor:match("^#%x%x%x%x%x%x$") then
        displayColor = data.displayColor
    end

    -- Close the tablet to draw
    AdminFactionTerritoriesClient.CloseTablet()

    -- Start drawing
    Wait(100)
    StartPolygonDrawing(name, displayNumber, displayColor)

    cb({ success = true })
end)

RegisterNUICallback("adminFactionTerritories:delete", function(data, cb)
    local territoryId = data.territoryId
    if not territoryId then
        cb({ success = false })
        return
    end

    TriggerServerEvent("core:factionTerritories:delete", territoryId)
    Wait(300)
    AdminFactionTerritoriesClient.RefreshTerritories()

    cb({ success = true })
end)

RegisterNUICallback("adminFactionTerritories:update", function(data, cb)
    local territoryId = data.territoryId
    local name = data.name
    local owner = data.owner

    if not territoryId then
        cb({ success = false })
        return
    end

    -- Update champs principaux (nom + chiffre + couleur) en un seul event
    local updateData = {}
    if name and name ~= "" then
        updateData.name = name
    end

    if data.displayNumber ~= nil then
        if data.displayNumber == "" or data.displayNumber == false then
            updateData.display_number = false -- signale suppression
        else
            local n = tonumber(data.displayNumber)
            if n and n >= 0 and n <= 999 then
                updateData.display_number = n
            end
        end
    end

    if data.displayColor ~= nil then
        if data.displayColor == "" or data.displayColor == false then
            updateData.display_color = false
        elseif type(data.displayColor) == "string" and data.displayColor:match("^#%x%x%x%x%x%x$") then
            updateData.display_color = data.displayColor
        end
    end

    if next(updateData) ~= nil then
        TriggerServerEvent("core:factionTerritories:update", territoryId, updateData)
    end

    -- Update owner
    TriggerServerEvent("core:factionTerritories:adminSetOwner", territoryId, owner)

    Wait(300)
    AdminFactionTerritoriesClient.RefreshTerritories()

    cb({ success = true })
end)

RegisterNUICallback("adminFactionTerritories:createFromMap", function(data, cb)
    local name = data.name
    local polygon = data.polygon

    if not name or name == "" or not polygon or #polygon < 3 then
        cb({ success = false })
        return
    end

    -- Optionnels
    local displayNumber = nil
    if data.displayNumber ~= nil and data.displayNumber ~= "" then
        local n = tonumber(data.displayNumber)
        if n and n >= 0 and n <= 999 then
            displayNumber = n
        end
    end

    local displayColor = nil
    if type(data.displayColor) == "string" and data.displayColor:match("^#%x%x%x%x%x%x$") then
        displayColor = data.displayColor
    end

    -- Create territory with polygon from UI
    TriggerServerEvent("core:factionTerritories:create", name, polygon, displayNumber, displayColor)

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'SUCCESS',
        subtitle = 'Gestion Territoires',
        message = "Territoire '" .. name .. "' créé avec " .. #polygon .. " points."
    })

    Wait(500)
    AdminFactionTerritoriesClient.RefreshTerritories()

    cb({ success = true })
end)

RegisterNUICallback("adminFactionTerritories:teleport", function(data, cb)
    local territoryId = data.territoryId

    for _, territory in ipairs(territoriesCache) do
        if territory.id == territoryId and territory.polygon then
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

            -- Teleport
            SetEntityCoords(PlayerPedId(), centerX, centerY, groundZ + 1.0, false, false, false, false)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Gestion Territoires',
                message = "Téléporté au centre de " .. territory.name .. "."
            })
            break
        end
    end

    cb({})
end)

RegisterNUICallback("adminFactionTerritories:setGPS", function(data, cb)
    local territoryId = data.territoryId

    for _, territory in ipairs(territoriesCache) do
        if territory.id == territoryId and territory.polygon then
            -- Calculate center
            local sumX, sumY = 0, 0
            for _, point in ipairs(territory.polygon) do
                sumX = sumX + point.x
                sumY = sumY + point.y
            end
            local centerX = sumX / #territory.polygon
            local centerY = sumY / #territory.polygon

            -- Set waypoint
            SetNewWaypoint(centerX, centerY)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Gestion Territoires',
                message = "GPS défini vers " .. territory.name .. "."
            })
            break
        end
    end

    cb({})
end)

RegisterNUICallback("adminFactionTerritories:saveSettings", function(data, cb)
    if not data then
        cb({ success = false })
        return
    end

    -- Send settings to server
    TriggerServerEvent("core:factionTerritories:saveSettings", {
        enabled = data.enabled,
        salesThreshold = data.salesThreshold,
        ownershipDurationHours = data.ownershipDurationHours,
        ownerBonusPercent = data.ownerBonusPercent,
        alertChancePercent = data.alertChancePercent
    })

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'SUCCESS',
        subtitle = 'Gestion Territoires',
        message = "Paramètres sauvegardés."
    })

    cb({ success = true })
end)

-- ============================================
-- EVENTS
-- ============================================

---Refresh event from server
RegisterNetEvent("core:factionTerritories:refresh", function()
    if not isTabletOpen then return end

    AdminFactionTerritoriesClient.RefreshTerritories()
    AdminFactionTerritoriesClient.RefreshFactions()
    local settings = TriggerServerCallback("core:factionTerritories:getSettings") or {}
    SendNUIMessage({
        action = "updateAdminFactionTerritories",
        data = {
            territories = territoriesCache,
            factions = factionsCache,
            settings = settings
        }
    })
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('OpenAdminTerritoriesTablet', function()
    AdminFactionTerritoriesClient.OpenTablet()
end)

exports('CloseAdminTerritoriesTablet', function()
    AdminFactionTerritoriesClient.CloseTablet()
end)

return AdminFactionTerritoriesClient
