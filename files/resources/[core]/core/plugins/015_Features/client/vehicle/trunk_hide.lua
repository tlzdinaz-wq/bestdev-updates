-- Système pour se cacher dans le coffre d'un véhicule
local isInTrunk = false
local trunkVehicle = nil
local trunkBone = nil
local trunkLocked = false

local trunkButtonId = generateUniqueID(8)

local function HasPlayerInTrunk(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local players = GetActivePlayers()
    for i = 1, #players do
        local ped = GetPlayerPed(players[i])
        if ped and ped ~= 0 and DoesEntityExist(ped)
            and not IsPedInAnyVehicle(ped, false)
            and IsEntityAttachedToEntity(ped, vehicle) then
            return true
        end
    end

    return false
end

-- Fonction pour entrer dans le coffre

local function EnterTrunk(vehicle)
    if isInTrunk then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous êtes déjà dans un coffre"
        })
        return
    end

    local ped = VFW.PlayerData.ped
    if not DoesEntityExist(vehicle) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce véhicule n'est pas valide"
        })
        return
    end

    if HasPlayerInTrunk(vehicle) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Il y a déjà quelqu'un dans ce coffre"
        })
        return
    end

    -- Arreter la boucle d'animation de mort si le joueur est mort
    if Death and Death.isDead then
        Death.gettingRevived = true
    end

    SetVehicleDoorOpen(vehicle, 5, false, false)

    -- Attendre un peu pour l'animation d'ouverture
    Wait(500)

    -- Position du coffre
    local trunkBoneIndex = GetEntityBoneIndexByName(vehicle, "boot")
    local trunkPos = GetWorldPositionOfEntityBone(vehicle, trunkBoneIndex)

    instructionalButtons[trunkButtonId] = {{ label = "Sortir du coffre", control = 38 }}

    -- Téléporter le ped dans le coffre
    SetEntityCoords(ped, trunkPos.x, trunkPos.y, trunkPos.z, false, false, false, true)

    -- Attacher le ped au véhicule
    AttachEntityToEntity(ped, vehicle, trunkBoneIndex, 0.0, -0.5, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

    -- Rendre le ped invisible
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)

    ---- Activer l'écran noir
    --SendNUIMessage({
    --    action = "nui:blackScreen:toggle",
    --    data = {
    --        visible = true,
    --        text = "Vous êtes dans le coffre - Appuyez sur E pour sortir"
    --    }
    --})

    -- Notifier le serveur
    TriggerServerEvent('trunk:playerEnter', VehToNet(vehicle))

    -- Sauvegarder les données
    isInTrunk = true
    trunkVehicle = vehicle
    trunkBone = trunkBoneIndex


    -- Fermer le coffre
    Wait(500)
    SetVehicleDoorShut(vehicle, 5, false)

    -- Afficher notification
    VFW.ShowNotification({
        type = 'VERT',
        content = "Vous êtes maintenant caché dans le coffre"
    })
end

-- Fonction pour sortir du coffre
local function ExitTrunk(forced)
    if not isInTrunk or not trunkVehicle then
        return
    end

    instructionalButtons[trunkButtonId] = nil

    -- Si le coffre est verrouillé et ce n'est pas une sortie forcée, empêcher
    if trunkLocked and not forced then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le coffre est verrouillé ! Vous ne pouvez pas sortir."
        })
        return
    end

    -- Si le joueur est mort et ce n'est pas une sortie forcée, empêcher
    if VFW.PlayerData.dead and not forced then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas sortir dans votre état."
        })
        return
    end

    local ped = VFW.PlayerData.ped

    -- Ouvrir le coffre
    if DoesEntityExist(trunkVehicle) then
        SetVehicleDoorOpen(trunkVehicle, 5, false, false)
        Wait(500)
    end

    -- Détacher le ped
    DetachEntity(ped, true, true)

    local wasDead = VFW.PlayerData.dead or (Death and Death.isDead)

    -- Calculer la position cible (derrière le véhicule)
    local targetCoords, targetHeading
    if DoesEntityExist(trunkVehicle) then
        targetHeading = GetEntityHeading(trunkVehicle)
        targetCoords = GetOffsetFromEntityInWorldCoords(trunkVehicle, 0.0, -4.0, 0.0)
    else
        local pedCoords = GetEntityCoords(ped)
        targetCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0)
        targetHeading = GetEntityHeading(ped)
    end

    -- Teleporter le ped loin du vehicule
    SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)

    -- Restaurer la visibilite/collision (etait cache dans le coffre)
    SetEntityVisible(ped, true, true)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetEntityHeading(ped, targetHeading)

    if wasDead then
        -- Reprendre la boucle d'animation de mort
        Death.gettingRevived = false
    end

    -- Désactiver l'écran noir
    SendNUIMessage({
        action = "nui:blackScreen:toggle",
        data = {
            visible = false
        }
    })

    -- Notifier le serveur
    TriggerServerEvent('trunk:playerExit', trunkVehicle and DoesEntityExist(trunkVehicle) and VehToNet(trunkVehicle) or nil)

    -- Fermer le coffre
    if DoesEntityExist(trunkVehicle) then
        Wait(500)
        SetVehicleDoorShut(trunkVehicle, 5, false)
    end

    -- Reset les variables
    isInTrunk = false
    trunkVehicle = nil
    trunkBone = nil
    trunkLocked = false

    -- Afficher notification
    VFW.ShowNotification({
        type = 'VERT',
        content = "Vous êtes sorti du coffre"
    })
end

-- Thread pour gérer la sortie du coffre
CreateThread(function()
    while true do
        if isInTrunk then
            -- Désactiver tous les contrôles
            DisableAllControlActions(0)

            -- Activer uniquement E pour sortir
            EnableControlAction(0, 38, true) -- E
            EnableControlAction(0, 1, true) -- LookLeftRight
            EnableControlAction(0, 2, true) -- LookUpDown

            -- Vérifier si E est pressé
            if VFW.Interact.JustPressed(0, 38) then
                instructionalButtons[trunkButtonId] = nil
                ExitTrunk()
            end

            -- Vérifier si le véhicule existe toujours
            if not DoesEntityExist(trunkVehicle) then
                instructionalButtons[trunkButtonId] = nil
                ExitTrunk(true)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Event pour recevoir l'état verrouillé du coffre
RegisterNetEvent('trunk:setLocked')
AddEventHandler('trunk:setLocked', function(locked)
    trunkLocked = locked

    -- Mettre à jour le texte de l'écran noir
    if isInTrunk then
        local isDead = VFW.PlayerData.dead or (Death and Death.isDead) or false
        local text = locked and "Le coffre est verrouillé ! Impossible de sortir..." or "Vous êtes dans le coffre - Appuyez sur E pour sortir"
        SendNUIMessage({
            action = "nui:blackScreen:toggle",
            data = {
                visible = true,
                text = text,
                dead = isDead,
                timer = isDead and Death and Death.secLeft or nil
            }
        })

        -- Notification
        if locked then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Le coffre a été verrouillé !"
            })
        else
            VFW.ShowNotification({
                type = 'VERT',
                content = "Le coffre a été déverrouillé"
            })
        end
    end
end)

-- Event pour forcer la sortie du coffre (depuis l'extérieur)
RegisterNetEvent('trunk:forceExit')
AddEventHandler('trunk:forceExit', function()
    if isInTrunk then
        ExitTrunk(true) -- Sortie forcée, ignore le verrouillage
    end
end)

-- Event pour forcer quelqu'un à entrer dans le coffre (quand on le porte et le met dedans)
RegisterNetEvent('trunk:forcedEnter')
AddEventHandler('trunk:forcedEnter', function(vehicleNetId)
    if isInTrunk then
        return
    end

    -- Convertir le NetId en entity handle
    local vehicle = NetToVeh(vehicleNetId)

    if not DoesEntityExist(vehicle) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Véhicule introuvable"
        })
        return
    end

    local ped = VFW.PlayerData.ped

    -- Arreter la boucle d'animation de mort si le joueur est mort
    if Death and Death.isDead then
        Death.gettingRevived = true
    end

    -- Ouvrir le coffre
    SetVehicleDoorOpen(vehicle, 5, false, false)

    -- Attendre un peu pour l'animation d'ouverture
    Wait(500)

    -- Position du coffre
    local trunkBoneIndex = GetEntityBoneIndexByName(vehicle, "boot")
    local trunkPos = GetWorldPositionOfEntityBone(vehicle, trunkBoneIndex)

    -- Teleporter le ped dans le coffre
    SetEntityCoords(ped, trunkPos.x, trunkPos.y, trunkPos.z, false, false, false, true)

    -- Attacher le ped au vehicule
    AttachEntityToEntity(ped, vehicle, trunkBoneIndex, 0.0, -0.5, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

    -- Rendre le ped invisible
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)

    -- Determiner le texte selon l'etat du joueur
    local isDead = VFW.PlayerData.dead or (Death and Death.isDead) or false
    local blackscreenText = "Vous êtes dans le coffre - Appuyez sur E pour sortir"
    if isDead then
        blackscreenText = "Vous êtes dans le coffre"
    end

    -- Activer l'écran noir
    SendNUIMessage({
        action = "nui:blackScreen:toggle",
        data = {
            visible = true,
            text = blackscreenText,
            dead = isDead,
            timer = isDead and Death and Death.secLeft or nil
        }
    })

    -- Notifier le serveur
    TriggerServerEvent('trunk:playerEnter', vehicleNetId)

    -- Sauvegarder les données
    isInTrunk = true
    trunkVehicle = vehicle
    trunkBone = trunkBoneIndex

    -- Fermer le coffre
    Wait(500)
    SetVehicleDoorShut(vehicle, 5, false)

    -- Afficher notification
    VFW.ShowNotification({
        type = 'JAUNE',
        content = "Vous avez été mis dans le coffre"
    })
end)

-- Event pour détecter quand le joueur est réanimé
RegisterNetEvent("vfw:revivePlayer")
AddEventHandler("vfw:revivePlayer", function()
    -- Si le joueur est dans le coffre, mettre à jour le texte de l'écran noir
    if isInTrunk then
        local text = "Vous êtes dans le coffre - Appuyez sur E pour sortir"
        if trunkLocked then
            text = "Le coffre est verrouillé ! Impossible de sortir..."
        end

        SendNUIMessage({
            action = "nui:blackScreen:toggle",
            data = {
                visible = true,
                text = text,
                dead = false -- vient d'être réanimé
            }
        })
    end
end)

-- Export des fonctions
VFW.EnterTrunk = EnterTrunk
VFW.ExitTrunk = ExitTrunk
VFW.HasPlayerInTrunk = HasPlayerInTrunk
VFW.IsInTrunk = function() return isInTrunk end
VFW.GetTrunkVehicle = function() return trunkVehicle end
