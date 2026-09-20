-- ============================================
-- FACTION F6 MENU
-- ============================================

local VUI = exports["VUI"]
local defaultBanner = exports["core"]:GetVUIBanner("faction")

local menuInitialized = false

local FactionMenu = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function GetClosestPlayer(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = nil
    local closestDistance = maxDistance or 3.0

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)

            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = {
                    ped = targetPed,
                    serverId = GetPlayerServerId(playerId),
                    distance = distance
                }
            end
        end
    end

    return closestPlayer
end

local function GetClosestVehicle(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local maxDist = maxDistance or 5.0
    local closestVehicle = nil
    local closestDistance = maxDist

    local playerHeading = GetEntityHeading(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    local startCoords = playerCoords + vector3(0, 0, 0.5)
    local endCoords = startCoords + (forwardVector * maxDist)

    local rayHandle = StartShapeTestRay(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, 10, playerPed, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit and entityHit and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) then
        closestVehicle = entityHit
        closestDistance = #(playerCoords - GetEntityCoords(entityHit))
    end

    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) and not IsPedInVehicle(playerPed, veh, false) then
            local vehCoords = GetEntityCoords(veh)
            local distance = #(playerCoords - vehCoords)

            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = veh
            end
        end
    end

    return closestVehicle
end

local function IsPlayerInFaction()

    if not VFW or not VFW.PlayerData or not VFW.PlayerData.faction then
        return false
    end
    local faction = VFW.PlayerData.faction
    local result = faction and faction.name and faction.name ~= "nofaction" and faction.name ~= "nocrew"
    return result
end

local function CanAccessTablet()
    if not VFW or not VFW.PlayerData or not VFW.PlayerData.faction then
        return false
    end
    local faction = VFW.PlayerData.faction
    if not faction or faction.name == "nofaction" or faction.name == "nocrew" then
        return false
    end
    local result = TriggerServerCallback("core:faction-tablet:canAccessTablet")
    return result == true
end

-- ============================================
-- PLAYER ACTIONS
-- ============================================

local function DoHandcuff(targetServerId)
    local result = TriggerServerCallback("faction:menu:handcuff", targetServerId)
    if result and result.success then
        VFW.ShowNotification({ type = 'ILLEGAL', message = result.message or "Action effectuée" })
    else
        VFW.ShowNotification({ type = 'ILLEGAL', message = result and result.message or "Action impossible" })
    end
end

local function DoUncuff(targetServerId)
    local result = TriggerServerCallback("faction:menu:uncuff", targetServerId)
    if result and result.success then
        VFW.ShowNotification({ type = 'ILLEGAL', message = result.message or "Action effectuée" })
    else
        VFW.ShowNotification({ type = 'ILLEGAL', message = result and result.message or "Action impossible" })
    end
end

local function StartEscort(targetServerId, targetPed)
    if VFW.isEscorting then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Vous escortez déjà quelqu'un" })
        return
    end

    local canEscort = TriggerServerCallback("faction:menu:canEscort", targetServerId)
    if not canEscort then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "La personne doit être attachée pour l'escorter" })
        return
    end

    if VFW.Jobs.StartEscort(targetServerId, targetPed) then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Vous escortez la personne" })
    end
end

local function StopEscort()
    if not VFW.isEscorting then return end
    VFW.Jobs.StopEscort()
    VFW.ShowNotification({ type = 'ILLEGAL', message = "Escorte arrêtée" })
end

-- ============================================
-- VEHICLE ACTIONS
-- ============================================

local function DoLockpickVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Aucun véhicule à proximité" })
        return
    end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 0 or lockStatus == 1 then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Le véhicule est déjà déverrouillé" })
        return
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Ce véhicule n'est pas synchronisé" })
        return
    end
    local result = TriggerServerCallback("faction:menu:lockpick", NetworkGetNetworkIdFromEntity(vehicle))
    if not result or not result.success then
        VFW.ShowNotification({ type = 'ILLEGAL', message = result and result.message or "Vous n'avez pas de kit de crochetage véhicules" })
        return
    end

    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, vehicle, 1000)
    Wait(1000)

    VFW.Streaming.RequestAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(playerPed, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 8.0, -8.0, -1, 1, 0, false, false, false)

    VFW.ShowNotification({ type = 'ILLEGAL', message = "Utilise [A/D] et la souris pour crocheter" })

    local success = exports['s_lockpick']:startLockpick()

    ClearPedTasks(playerPed)
    RemoveAnimDict('veh@break_in@0h@p_m_one@')

    NetworkRequestControlOfEntity(vehicle)

    if success then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Véhicule crocheté" })
        if NetworkGetEntityIsNetworked(vehicle) then
            TriggerServerEvent("faction:menu:lockpickSuccess", NetworkGetNetworkIdFromEntity(vehicle))
        end
    else
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 4000)
        SetVehicleDoorsLocked(vehicle, 2)
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Crochetage raté, l'alarme s'est déclenchée" })
        if NetworkGetEntityIsNetworked(vehicle) then
            TriggerServerEvent("faction:menu:lockpickFailed", NetworkGetNetworkIdFromEntity(vehicle))
        end
    end
end

-- ============================================
-- MENU RENDERING
-- ============================================

local function RenderPlayerActionsMenu()
    if not FactionMenu.playerActions then return end

    FactionMenu.playerActions.Button("Attacher/Détacher", "Attacher ou détacher les mains du personnage", nil, nil, false, function()
        local closestPlayer = GetClosestPlayer(3.0)
        if not closestPlayer then
            VFW.ShowNotification({ type = 'ILLEGAL', message = "Aucune personne à proximité" })
            return
        end
        local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", closestPlayer.serverId) == true
        if isCuffed then
            DoUncuff(closestPlayer.serverId)
        else
            DoHandcuff(closestPlayer.serverId)
        end
    end)

    if not VFW.isEscorting then
        FactionMenu.playerActions.Button("Escorter", "Forcer un personnage attaché à vous suivre", nil, nil, false, function()
            local closestPlayer = GetClosestPlayer(3.0)
            if closestPlayer then
                StartEscort(closestPlayer.serverId, closestPlayer.ped)
            else
                VFW.ShowNotification({ type = 'ILLEGAL', message = "Aucune personne à proximité" })
            end
        end)
    else
        FactionMenu.playerActions.Button("Arrêter l'escorte", "Relâcher le personnage escorté", nil, nil, false, function()
            StopEscort()
        end)
    end

    FactionMenu.playerActions.Button("Fouiller", "Fouiller l'inventaire d'un personnage attaché", nil, nil, false, function()
        local closestPlayer = GetClosestPlayer(3.0)
        if not closestPlayer then
            VFW.ShowNotification({ type = 'ILLEGAL', message = "Aucune personne à proximité" })
            return
        end

        local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", closestPlayer.serverId)
        if not isCuffed then
            VFW.ShowNotification({ type = 'ILLEGAL', message = "La personne doit être attachée pour la fouiller" })
            return
        end

        FactionMenu.playerActions.close()
        VFW.OpenShearch(closestPlayer.serverId)
    end)
end

local function RenderVehicleActionsMenu()
    if not FactionMenu.vehicleActions then return end

    FactionMenu.vehicleActions.Button("Crocheter", "Crocheter le véhicule le plus proche", nil, nil, false, function()
        local closestVehicle = GetClosestVehicle(5.0)
        if closestVehicle then
            FactionMenu.vehicleActions.close()
            DoLockpickVehicle(closestVehicle)
        else
            VFW.ShowNotification({ type = 'ILLEGAL', message = "Aucun véhicule à proximité" })
        end
    end)
end

local function RenderMainMenu()
    if not FactionMenu.main then return end

    local faction = VFW.PlayerData and VFW.PlayerData.faction or nil

    FactionMenu.main.Separator("INFORMATIONS")

    FactionMenu.main.Title(
        "Faction : " .. (faction and faction.label or "Aucune")
    )

    FactionMenu.main.Title(
        "Grade : " .. (faction and faction.grade_label or "Aucun")
    )

    FactionMenu.main.Separator("ACTIONS")

    FactionMenu.main.Button("Actions Personnage", nil, nil, 'chevron', false, function()
    end, FactionMenu.playerActions)

    FactionMenu.main.Button("Actions Véhicule", nil, nil, 'chevron', false, function()
    end, FactionMenu.vehicleActions)

    FactionMenu.main.Button("Activer/Désactiver la vente de drogue", nil, nil, nil, false, function()
        FactionMenu.main.close()
        ExecuteCommand("drogue")
    end)

    if VFW.isEscorting then
        FactionMenu.main.Button("Arrêter l'escorte", nil, nil, nil, false, function()
            FactionMenu.main.close()
            StopEscort()
        end)
    end

    FactionMenu.main.Separator("TABLETTES")

    local canAccessTablet = CanAccessTablet()
    if canAccessTablet then
        FactionMenu.main.Button("Tablette Gestion", nil, nil, 'chevron', false, function()
            FactionMenu.main.close()
            if OpenFactionTablet then
                OpenFactionTablet()
            else
                VFW.ShowNotification({ type = 'ILLEGAL', message = "Tablette gestion non disponible" })
            end
        end)
    end

    FactionMenu.main.Button("Tablette Territoires", nil, nil, 'chevron', false, function()
        FactionMenu.main.close()
        ExecuteCommand("territories")
    end)
end

-- ============================================
-- MENU INITIALIZATION
-- ============================================

local function InitializeMenu()
    if menuInitialized then return true end

    if not VUI then
        print("[FACTION MENU] VUI not available")
        return false
    end

    local success, err = pcall(function()
        FactionMenu.main = VUI:CreateMenu("MENU FACTION", defaultBanner, true)
        FactionMenu.playerActions = VUI:CreateSubMenu(FactionMenu.main, "ACTIONS PERSONNAGE", defaultBanner, true)
        FactionMenu.vehicleActions = VUI:CreateSubMenu(FactionMenu.main, "ACTIONS VÉHICULE", defaultBanner, true)

        FactionMenu.main.OnOpen(function()
            local faction = VFW.PlayerData and VFW.PlayerData.faction
            local bannerToUse = defaultBanner
            if faction and faction.banner and faction.banner ~= "" then
                bannerToUse = faction.banner
            end
            FactionMenu.main.ChangeBanner(bannerToUse)
            if FactionMenu.playerActions and FactionMenu.playerActions.ChangeBanner then
                FactionMenu.playerActions.ChangeBanner(bannerToUse)
            end
            if FactionMenu.vehicleActions and FactionMenu.vehicleActions.ChangeBanner then
                FactionMenu.vehicleActions.ChangeBanner(bannerToUse)
            end
            RenderMainMenu()
        end)

        FactionMenu.playerActions.OnOpen(function()
            RenderPlayerActionsMenu()
        end)

        FactionMenu.vehicleActions.OnOpen(function()
            RenderVehicleActionsMenu()
        end)
    end)

    if not success then
        return false
    end

    menuInitialized = true
    return true
end

-- ============================================
-- KEY BINDING (F6)
-- ============================================

local function OpenFactionMenu()
    if not IsPlayerInFaction() then
        return
    end

    if not menuInitialized then
        if not InitializeMenu() then
            VFW.ShowNotification({ type = 'ILLEGAL', message = "Menu non disponible" })
            return
        end
    end

    if FactionMenu.main then
        FactionMenu.main.open()
    end
end

RegisterCommand("factionmenu", function()
    OpenFactionMenu()
end, false)

CreateThread(function()
    Wait(5000)
    InitializeMenu()
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('OpenFactionMenu', OpenFactionMenu)
