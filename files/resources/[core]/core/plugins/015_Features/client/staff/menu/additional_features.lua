---@meta _
---@diagnostic disable: duplicate-doc-field

-- Additional staff features from YveltMenu
local additionalFeatures = {
    showCoords = false,
    spectateMode = false,
    isRandomSpectate = false,
    customTeleports = {}
}

-- ID unique pour les instructional buttons du spectate
local spectateButtonsId = generateUniqueID()

-- Show Coordinates Feature
function StaffMenu.EnableCoords(enabled)
    additionalFeatures.showCoords = enabled
    
    if enabled then
        CreateThread(function()
            while additionalFeatures.showCoords do
                Wait(0)
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local heading = GetEntityHeading(playerPed)
                
                local text = string.format("~g~X: ~s~%.2f ~g~Y: ~s~%.2f ~g~Z: ~s~%.2f ~g~H: ~s~%.2f", 
                    coords.x, coords.y, coords.z, heading)
                
                SetTextFont(0)
                SetTextProportional(1)
                SetTextScale(0.0, 0.35)
                SetTextColour(255, 255, 255, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextDropShadow()
                SetTextOutline()
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString(text)
                DrawText(0.5, 0.95)
            end
        end)
    end
end

-- Spectate Mode Feature (Enhanced)
function StaffMenu.SpectatePlayer(targetSource, isRandomSpectate)
    if not targetSource then return end

    -- Fermer le menu admin avant de passer en spectate
    if StaffMenu.main and StaffMenu.main.close then
        StaffMenu.main.close()
    end

    additionalFeatures.spectateMode = true
    additionalFeatures.spectateTarget = targetSource
    additionalFeatures.isRandomSpectate = isRandomSpectate or false
    additionalFeatures.wasNoclipActive = VFW.IsNoclipActive()

    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    if additionalFeatures.wasNoclipActive then
        VFW.StopNoclipSilent()
    end

    -- StopNoclipSilent re-makes the ped visible; immediately re-hide it so no
    -- frame exposes us at the original position before the spectate teleport.
    local localPed = PlayerPedId()
    SetEntityVisible(localPed, false, false)
    SetEntityCollision(localPed, false, false)
    FreezeEntityPosition(localPed, true)
    SetEntityInvincible(localPed, true)
    SetEveryoneIgnorePlayer(PlayerId(), true)

    TriggerServerEvent("core:StaffSpectate", targetSource, true)

    -- Afficher les instructional buttons selon le mode
    if isRandomSpectate then
        instructionalButtons[spectateButtonsId] = {
            { control = 73, label = "Quitter" },
            { control = 38, label = "Gérer le joueur" },
            { control = 24, label = "Joueur suivant" }
        }
    else
        instructionalButtons[spectateButtonsId] = {
            { control = 73, label = "Quitter" },
            { control = 38, label = "Gérer le joueur" }
        }
    end

    CreateThread(function()
        while additionalFeatures.spectateMode do
            Wait(0)

            if IsControlJustPressed(0, 73) then -- X - Quitter
                StaffMenu.StopSpectate()
            elseif VFW.Interact.JustPressed(0, 38) then -- E - Gérer le joueur
                StaffMenu.data.selectedPlayer = additionalFeatures.spectateTarget
                StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", additionalFeatures.spectateTarget) or {}

                -- Recreate the player menu with the player's name as title
                local playerTitle = string.format("%s [%d]", StaffMenu.data.playerInfo.name or "Unknown", additionalFeatures.spectateTarget)
                local adminBanner = exports["core"]:GetVUIBanner("admin")
                local VUI = exports["VUI"]

                StaffMenu.player = VUI:CreateSubMenu(StaffMenu.players, playerTitle, adminBanner, true)

                -- Re-attach child menus
                StaffMenu.wipe = VUI:CreateSubMenu(StaffMenu.player, "WIPE", adminBanner, true)
                StaffMenu.items = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES ITEMS", adminBanner, true)
                StaffMenu.AttachItemsMenuCallback()
                StaffMenu.jobs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES JOBS", adminBanner, true)
                StaffMenu.grades_jobs = VUI:CreateSubMenu(StaffMenu.jobs, "LISTE DES GRADES", adminBanner, true)
                StaffMenu.factions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES FACTIONS", adminBanner, true)
                StaffMenu.grades_factions = VUI:CreateSubMenu(StaffMenu.factions, "LISTE DES GRADES", adminBanner, true)
                StaffMenu.vehs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES VÉHICULES", adminBanner, true)
                StaffMenu.vehs_owned = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOUEUR", adminBanner, true)
                StaffMenu.vehs_job = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOB", adminBanner, true)
                StaffMenu.vehs_faction = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DE FACTION", adminBanner, true)
                StaffMenu.vehicleActions = VUI:CreateSubMenu(StaffMenu.vehs_owned, "ACTIONS VÉHICULE", adminBanner, true)
                StaffMenu.playerSanctions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES SANCTIONS", adminBanner, true)

                -- Re-attach OnOpen callbacks
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
                StaffMenu.vehs.OnOpen(function()
                    StaffMenu.BuildVehsMenu()
                end)

                StaffMenu.vehs_owned.OnOpen(function()
                    StaffMenu.BuildVehsOwnedMenu()
                end)

                StaffMenu.vehs_job.OnOpen(function()
                    StaffMenu.BuildVehsJobMenu()
                end)

                StaffMenu.vehs_faction.OnOpen(function()
                    StaffMenu.BuildVehsFactionMenu()
                end)
                StaffMenu.vehicleActions.OnOpen(function()
                    StaffMenu.BuildVehicleActionsMenu()
                end)
                StaffMenu.player.OnOpen(function()
                    StaffMenu.BuildPlayerMenu()
                end)

                StaffMenu.player.open()
            elseif additionalFeatures.isRandomSpectate and IsControlJustPressed(0, 24) then -- Clic gauche - Joueur suivant
                StaffMenu.SpectateNextRandom()
            end
        end
    end)
end

-- Fonction pour arrêter le spectate (peut être appelée de n'importe où)
function StaffMenu.StopSpectate()
    if not additionalFeatures.spectateMode then return end

    local spectateTarget = additionalFeatures.spectateTarget
    additionalFeatures.spectateMode = false

    -- Supprimer les instructional buttons
    instructionalButtons[spectateButtonsId] = nil

    -- Hide the transition behind a fade so we never appear at the target's
    -- coords during the round-trip back to noclip / normal state.
    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    if spectateTarget then
        TriggerServerEvent("core:StaffSpectate", spectateTarget, false)
    end

    StaffMenu._restoreNoclipAfterSpectate = additionalFeatures.wasNoclipActive or false

    if StaffMenu.ResetOutilsSpectate then
        StaffMenu.ResetOutilsSpectate()
    end
    if StaffMenu.ResetPlayerSpectate and spectateTarget then
        StaffMenu.ResetPlayerSpectate(spectateTarget)
    end

    additionalFeatures.spectateTarget = nil
    additionalFeatures.wasNoclipActive = nil
    additionalFeatures.isRandomSpectate = nil
end

-- Passer au joueur suivant en mode spectate aléatoire
function StaffMenu.SpectateNextRandom()
    if not additionalFeatures.spectateMode or not additionalFeatures.isRandomSpectate then return end

    local players = TriggerServerCallback("vfw:staff:getPlayerList") or {}
    local validPlayers = {}
    local selfId = GetPlayerServerId(PlayerId())
    local currentTarget = additionalFeatures.spectateTarget

    for _, player in pairs(players) do
        if player and player.source and player.source ~= selfId and player.source ~= currentTarget then
            table.insert(validPlayers, player)
        end
    end

    if #validPlayers == 0 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Outils Staff', message = "Aucun autre joueur disponible" })
        return
    end

    -- Switch direct vers le nouveau joueur sans passer par un stop intermédiaire.
    -- Un stop déclencherait le handler client de fin de spectate qui dégèle le ped
    -- et le téléporte aux coords de sortie de noclip (souvent en l'air) — résultat :
    -- chute pendant la transition. Le start serveur garde le ped figé/invisible et
    -- gère le routing bucket du nouveau target.
    local randomPlayer = validPlayers[math.random(1, #validPlayers)].source
    additionalFeatures.spectateTarget = randomPlayer
    StaffMenu.LastPlayerSource = randomPlayer
    TriggerServerEvent("core:StaffSpectate", randomPlayer, true)

    VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Outils Staff', message = "Spectate joueur ID: " .. randomPlayer .. "." })
end

-- Vérifie si le mode spectate est actif
function StaffMenu.IsSpectating()
    return additionalFeatures.spectateMode == true
end

-- Custom Teleportation System
function StaffMenu.CreateCustomTeleport()
    local name = VFW.Nui.KeyboardInput(true, "Nom de la téléportation")
    if not name or name == "" then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff',
            message = "Ce nom n'est pas valide"
      })
        return
    end
    
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent("vfw:staff:createCustomTeleport", name, coords)
    
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff',
        message = "Téléportation créée: " .. name
    })
end

function StaffMenu.LoadCustomTeleports()
    local teleports = TriggerServerCallback("vfw:staff:getCustomTeleports")
    if not teleports then
        teleports = {}
    end
    additionalFeatures.customTeleports = teleports
    return teleports
end

function StaffMenu.TeleportToCustom(teleportId)
    local teleport = additionalFeatures.customTeleports[teleportId]
    if teleport then
        StaffTeleportToCoords(teleport.coords.x, teleport.coords.y, teleport.coords.z)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff',
            message = "Téléporté à: " .. teleport.name
        })
    end
end

function StaffMenu.DeleteCustomTeleport(teleportId)
    TriggerServerEvent("vfw:staff:deleteCustomTeleport", teleportId)
    additionalFeatures.customTeleports[teleportId] = nil
    VFW.ShowNotification({
        type = 'STAFF', variant = 'INFO', subtitle = 'Outils Staff',
        message = "Téléportation supprimée"
  })
end

-- Vehicle Color Customization
function StaffMenu.SetVehicleColor(vehicle, r, g, b, isPrimary)
    if not DoesEntityExist(vehicle) then return end
    
    if isPrimary then
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
    else
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
    end
    
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff',
        message = "Couleur du véhicule modifiée"
  })
end

-- Return vehicle flip feature
function StaffMenu.FlipVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 70)
    
    if DoesEntityExist(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff',
            message = "Véhicule retourné"
      })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff',
            message = "Aucun véhicule proche"
      })
    end
end

-- Export features state
function StaffMenu.GetAdditionalFeaturesState()
    return additionalFeatures
end

-- Initialize
CreateThread(function()
    Wait(1000)
    if StaffMenu and StaffMenu.LoadCustomTeleports then
        StaffMenu.LoadCustomTeleports()
    end
end)