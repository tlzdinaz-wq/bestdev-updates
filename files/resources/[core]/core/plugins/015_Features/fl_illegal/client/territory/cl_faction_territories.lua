---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- FACTION TERRITORIES CLIENT
-- Client-side module for viewing faction territories
-- ============================================

local FactionTerritoriesClient = {}

-- Cache
local territoriesCache = {}
local isTabletOpen = false
local territoryTabletProp = nil

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

---Refresh territories from server
function FactionTerritoriesClient.RefreshTerritories()
    territoriesCache = TriggerServerCallback("core:factionTerritories:getAll") or {}
end

---Get all territories
function FactionTerritoriesClient.GetTerritories()
    return territoriesCache
end

---Get territory at player's position
function FactionTerritoriesClient.GetCurrentTerritory()
    return TriggerServerCallback("core:factionTerritories:getAtPosition")
end

---Get territories owned by player's faction
function FactionTerritoriesClient.GetMyTerritories()
    return TriggerServerCallback("core:factionTerritories:getMyTerritories")
end

-- ============================================
-- TABLET UI
-- ============================================

---Open the territories tablet
function FactionTerritoriesClient.OpenTablet()
    if isTabletOpen then return end

    -- Check if player has a faction
    local faction = VFW.PlayerData.faction
    if not faction or faction.name == "nocrew" then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Vous devez faire partie d'une faction"
        })
        return
    end

    isTabletOpen = true

    -- Refresh data
    FactionTerritoriesClient.RefreshTerritories()
    local myTerritories = FactionTerritoriesClient.GetMyTerritories()
    local settings = TriggerServerCallback("core:factionTerritories:getSettings") or {}

    -- Récupérer la couleur/label/name/id de notre faction depuis le serveur (source de vérité, comme la crewTablet)
    local myFactionData = TriggerServerCallback("core:factionTerritories:getMyFactionData")
    local myFactionColor = (myFactionData and myFactionData.color) or "#e53935"
    local myFactionLabel = (myFactionData and myFactionData.label) or faction.label
    local myFactionId = myFactionData and myFactionData.id

    -- Prepare data for NUI
    local data = {
        territories = territoriesCache,
        myTerritories = myTerritories,
        myFaction = myFactionId,       -- faction_id (int) for owner comparisons in React
        myFactionLabel = myFactionLabel,
        myFactionColor = myFactionColor,
        settings = settings
    }

    -- Send to NUI
    SendNUIMessage({
        action = "openFactionTerritories",
        data = data
    })

    VFW.Nui.Focus(true)

    -- Tablet prop + animation
    CreateThread(function()
        if not isTabletOpen then return end

        local ped = PlayerPedId()
        local dict = "amb@world_human_seat_wall_tablet@female@base"
        local anim = "base"
        local propModel = "prop_cs_tablet"

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end

        RequestModel(propModel)
        while not HasModelLoaded(propModel) do Wait(10) end

        territoryTabletProp = CreateObject(GetHashKey(propModel), 0.0, 0.0, 0.0, false, true, false)
        AttachEntityToEntity(territoryTabletProp, ped, GetPedBoneIndex(ped, 28422),
            -0.01, 0.0, 0.0,
            0.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )

        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

        while isTabletOpen do
            if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Wait(500)
        end

        ClearPedTasks(ped)
        if territoryTabletProp and DoesEntityExist(territoryTabletProp) then
            DeleteEntity(territoryTabletProp)
            territoryTabletProp = nil
        end
    end)
end

---Close the territories tablet
function FactionTerritoriesClient.CloseTablet()
    if not isTabletOpen then return end

    isTabletOpen = false

    SendNUIMessage({
        action = "closeFactionTerritories"
    })

    VFW.Nui.Focus(false)
end

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback("factionTerritories:close", function(_, cb)
    FactionTerritoriesClient.CloseTablet()
    cb({})
end)

RegisterNUICallback("factionTerritories:refresh", function(_, cb)
    FactionTerritoriesClient.RefreshTerritories()
    local myTerritories = FactionTerritoriesClient.GetMyTerritories()

    cb({
        territories = territoriesCache,
        myTerritories = myTerritories
    })
end)

RegisterNUICallback("factionTerritories:teleport", function(data, cb)
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
                type = 'ILLEGAL',
                message = "GPS defini vers " .. territory.name
            })
            break
        end
    end

    cb({})
end)

-- ============================================
-- EVENTS
-- ============================================

---Refresh event from server
RegisterNetEvent("core:factionTerritories:refresh", function()
    if not isTabletOpen then return end

    FactionTerritoriesClient.RefreshTerritories()
    local myTerritories = FactionTerritoriesClient.GetMyTerritories()
    local settings = TriggerServerCallback("core:factionTerritories:getSettings") or {}
    SendNUIMessage({
        action = "updateFactionTerritories",
        data = {
            territories = territoriesCache,
            myTerritories = myTerritories,
            settings = settings
        }
    })
end)

-- ============================================
-- COMMANDS & KEYBINDS
-- ============================================

RegisterCommand("territories", function()
    FactionTerritoriesClient.OpenTablet()
end, false)

-- Register in radial menu if available
CreateThread(function()
    Wait(5000)

    -- Try to add to faction radial menu
    if VFW.RadialMenu and VFW.RadialMenu.AddItem then
        -- This would need to be integrated with the existing faction radial menu
        -- For now, just use the /territories command
    end

    -- Initial load
    FactionTerritoriesClient.RefreshTerritories()
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetFactionTerritoriesClient', function()
    return FactionTerritoriesClient
end)

exports('OpenTerritoriesTablet', function()
    FactionTerritoriesClient.OpenTablet()
end)

exports('CloseTerritoriesTablet', function()
    FactionTerritoriesClient.CloseTablet()
end)

return FactionTerritoriesClient
