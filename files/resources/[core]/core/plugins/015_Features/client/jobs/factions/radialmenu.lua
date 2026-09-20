---@meta _
---@diagnostic disable: duplicate-doc-field

local function getPoliceImg()
    return VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png")
end

local function policeNotif(subtitle, message)
    local jobLabel = (VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label) or "SASP"
    VFW.ShowNotification({
        type     = "JOB",
        title    = jobLabel,
        subtitle = subtitle,
        image    = getPoliceImg(),
        content  = message
    })
end

local radarActive = false
local radarLocked = false

-- Sabot (wheel clamp) utilities
local bootWheelBones = {
    { bone = "wheel_lf", index = 0, side = "left" },
    { bone = "wheel_rf", index = 1, side = "right" },
}

bootProps = bootProps or {} -- [vehicle] = propHandle (global for cross-file access)

local function GetClosestWheel(ped, vehicle)
    local playerCoords = GetEntityCoords(ped)
    local closestDist = 5.0  -- Correspond au rayon de détection du véhicule
    local closestWheel = nil

    for _, wheel in ipairs(bootWheelBones) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, wheel.bone)
        if boneIndex ~= -1 then
            local bonePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local dist = #(playerCoords - bonePos)
            if dist < closestDist then
                closestDist = dist
                closestWheel = wheel
            end
        end
    end

    return closestWheel
end

--- Désactive complètement le radar
local function StopRadar()
    radarActive = false
    radarLocked = false
    SendNUIMessage({ action = "nui:policeRadar:visible", data = false })
end

RegisterNuiCallback("nui:vehicleInfo:close", function(_, cb)
    cb({})
end)

RegisterNuiCallback("nui:policeRadar:close", function(_, cb)
    if radarActive then
        StopRadar()
    end
    cb({})
end)

RegisterNuiCallback("nui:policeRadar:setLock", function(data, cb)
    if data.locked then
        radarLocked = true
    else
        radarLocked = false
        -- Si on unlock hors véhicule, fermer le radar
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            StopRadar()
            policeNotif("Radar", "Radar désactivé")
        end
    end
    cb({})
end)

-- Touche E pour lock/unlock le radar (lock la vitesse la plus élevée)
CreateThread(function()
    while true do
        if radarActive then
            Wait(0)
            if VFW.Interact.JustPressed(0, 38) then -- 38 = E
                SendNUIMessage({ action = "nui:policeRadar:doLock" })
                Wait(300)
            end
        else
            Wait(500)
        end
    end
end)

local hose = false

--- ToggleHose
function ToggleHose()
    if VFW.PlayerData.job.onDuty then
        ExecuteCommand('hose')
        if hose == false then
            hose = true
            VFW.ShowNotification({
                type = 'VERT',
                content = "Les incendies sont activés"
            })
        else
            hose = false
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Les incendies sont désactivée"
            })
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Tu n'es pas en service"
        })
    end
end

local foam = false

--- ToggleFoam
function ToggleFoam()
    if VFW.PlayerData.job.onDuty then
        if hose == false then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "La lance n'est pas déployée"
            })
        else
            ExecuteCommand('foam')
            if foam == false then
                VFW.ShowNotification({
                    type = 'VERT',
                    content = "La mousse est activée"
                })
                foam = true
            else
                VFW.ShowNotification({
                    type = 'VERT',
                    content = "La mousse est désactivée"
                })
                foam = false
            end
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Tu n'es pas en service"
        })
    end
end

-- ============================================
-- ACTIONS VEHICULES (wrappers pour le radial menu)
-- ============================================

local function GetNearestVehicle(maxDist)
    maxDist = maxDist or 5.0
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicle, dist = VFW.Game.GetClosestVehicle(playerCoords)
    if vehicle and DoesEntityExist(vehicle) and dist <= maxDist then
        return vehicle
    end
    return nil
end

--- VehicleInfoAction — Affiche les infos du véhicule le plus proche dans une UI
function VehicleInfoAction()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Véhicule", "Tu n'es pas en service")
        return
    end

    local vehicle = GetNearestVehicle()
    if not vehicle then
        policeNotif("Véhicule", "Aucun véhicule à proximité")
        return
    end

    local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    local plate = VFW.Game.GetPlate(vehicle)
    local bodyHealth = math.round(GetVehicleBodyHealth(vehicle) / 10, 2)
    local engineHealth = math.round(GetVehicleEngineHealth(vehicle) / 10, 2)

    -- Récupérer le propriétaire via le callback serveur
    local ownerName = nil
    local firstname, lastname = TriggerServerCallback('core:jobs:server:getVeh', plate)
    if firstname and lastname then
        ownerName = firstname .. " " .. lastname
    end

    SendNUIMessage({
        action = "nui:vehicleInfo:show",
        data = {
            model = model,
            plate = plate,
            bodyHealth = bodyHealth,
            engineHealth = engineHealth,
            owner = ownerName,
        }
    })
end

--- VehiclePlateSearchAction — Recherche de plaque avec animation tablette + affichage NUI
function VehiclePlateSearchAction()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Véhicule", "Tu n'es pas en service")
        return
    end

    local vehicle = GetNearestVehicle()
    if not vehicle then
        policeNotif("Véhicule", "Aucun véhicule à proximité")
        return
    end

    local plate = VFW.Game.GetPlate(vehicle)

    -- Ouvrir le MDT sur l'onglet véhicules avec la plaque pré-remplie
    VFW.Nui.policePanel(true)
    SendNUIMessage({
        action = "nui:PolicePanel:searchPlate",
        data = plate
    })
end

--- VehicleUnlockAction — Déverrouille le véhicule le plus proche (crochetage)
function VehicleUnlockAction()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Véhicule", "Tu n'es pas en service")
        return
    end

    local vehicle = GetNearestVehicle()
    if not vehicle then
        policeNotif("Véhicule", "Aucun véhicule à proximité")
        return
    end

    -- Vérifier si déjà déverrouillé
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 0 or lockStatus == 1 then
        policeNotif("Véhicule", "Ce véhicule est déjà déverrouillé")
        return
    end

    -- Vérifier qu'il n'y a personne dedans
    local seat = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for i = -1, seat - 2 do
        if not IsVehicleSeatFree(vehicle, i) then
            policeNotif("Véhicule", "Il y a quelqu'un dans le véhicule")
            return
        end
    end

    local ped = PlayerPedId()

    -- Animation crochetage
    RequestAnimDict('missheistfbisetup1')
    while not HasAnimDictLoaded('missheistfbisetup1') do Wait(1) end
    TaskPlayAnim(ped, 'missheistfbisetup1', 'hassle_intro_loop_f', 8.0, -8.0, -1, 1, 0, false, false, false)

    local duration = VFW.Nui.ProgressBar("Crochetage en cours...", 10 * 1000)

    ClearPedTasks(ped)
    RemoveAnimDict('missheistfbisetup1')

    if duration then
        NetworkRequestControlOfEntity(vehicle)
        SetVehicleDoorsLocked(vehicle, 0)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        policeNotif("Véhicule", "Véhicule déverrouillé")
    end
end

-- ============================================
-- RADAR
-- ============================================

--- ToggleRadarAction — Active/désactive le radar de vitesse
function ToggleRadarAction()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Radar", "Tu n'es pas en service")
        return
    end

    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        policeNotif("Radar", "Tu dois être dans un véhicule")
        return
    end

    radarActive = not radarActive

    SendNUIMessage({
        action = "nui:policeRadar:visible",
        data = radarActive
    })

    if radarActive then
        radarLocked = false
        policeNotif("Radar", "Radar activé")

        local wasOutsideVehicle = false

        CreateThread(function()
            while radarActive do
                Wait(500)

                local ped = PlayerPedId()
                local inVehicle = IsPedInAnyVehicle(ped, false)

                -- Joueur sort du véhicule
                if not inVehicle then
                    if radarLocked then
                        -- Vitesse lockée : garder le radar ouvert (fermable via bouton X)
                        wasOutsideVehicle = true

                        -- Mode piéton : pas de scan, juste patrol = 0
                        SendNUIMessage({
                            action = "nui:policeRadar:data",
                            data = {
                                patrolSpeed = 0,
                                targetSpeed = -1,
                                targetPlate = "",
                                rearSpeed = -1,
                                rearPlate = "",
                            }
                        })
                    else
                        -- Pas de lock : fermer le radar
                        StopRadar()
                        policeNotif("Radar", "Radar désactivé")
                        break
                    end
                else
                    -- Joueur dans un véhicule
                    if wasOutsideVehicle then
                        wasOutsideVehicle = false
                    end

                    local vehicle = GetVehiclePedIsIn(ped, false)
                    local patrolSpeed = math.floor(GetEntitySpeed(vehicle) * 3.6)

                    local pCoords = GetEntityCoords(ped)
                    local forward = GetEntityForwardVector(ped)

                    -- Front target
                    local targetSpeed = 0
                    local targetPlate = ""
                    local hasTarget = false
                    local closestFront = 80.0

                    -- Rear target
                    local rearSpeed = 0
                    local rearPlate = ""
                    local hasRear = false
                    local closestRear = 60.0

                    for _, veh in ipairs(VFW.Game.GetVehicles()) do
                        if veh ~= vehicle and DoesEntityExist(veh) then
                            local vCoords = GetEntityCoords(veh)
                            local dist = #(pCoords - vCoords)
                            local dir = (vCoords - pCoords)
                            dir = vector3(dir.x, dir.y, 0.0)
                            local norm = #dir

                            if norm > 0.1 then
                                dir = dir / norm
                                local dot = forward.x * dir.x + forward.y * dir.y

                                -- Devant (~45°)
                                if dot > 0.7 and dist < closestFront then
                                    closestFront = dist
                                    targetSpeed = math.floor(GetEntitySpeed(veh) * 3.6)
                                    targetPlate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
                                    hasTarget = true
                                end

                                -- Derrière (~45°)
                                if dot < -0.7 and dist < closestRear then
                                    closestRear = dist
                                    rearSpeed = math.floor(GetEntitySpeed(veh) * 3.6)
                                    rearPlate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
                                    hasRear = true
                                end
                            end
                        end
                    end

                    SendNUIMessage({
                        action = "nui:policeRadar:data",
                        data = {
                            patrolSpeed = patrolSpeed,
                            targetSpeed = hasTarget and targetSpeed or -1,
                            targetPlate = hasTarget and targetPlate or "",
                            rearSpeed = hasRear and rearSpeed or -1,
                            rearPlate = hasRear and rearPlate or "",
                        }
                    })
                end
            end
        end)
    else
        StopRadar()
        policeNotif("Radar", "Radar désactivé")
    end
end

--- VehicleImpoundAction — Met en fourrière le véhicule le plus proche
function VehicleImpoundAction()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Fourrière", "Tu n'es pas en service")
        return
    end

    local vehicle = GetNearestVehicle()
    if not vehicle then
        policeNotif("Fourrière", "Aucun véhicule à proximité")
        return
    end

    VFW.Jobs.SetVehicleInFourriere(vehicle)
end

-- ============================================
-- SABOT (WHEEL CLAMP)
-- ============================================

--- VehicleBootToggleAction — Pose ou retire un sabot selon l'état du véhicule
function VehicleBootToggleAction()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Sabot", "Tu n'es pas en service")
        return
    end

    local vehicle = GetNearestVehicle()
    if not vehicle then
        policeNotif("Sabot", "Aucun véhicule à proximité")
        return
    end

    -- Passer le véhicule directement pour éviter un double GetNearestVehicle()
    if Entity(vehicle).state.hasBoot then
        VehicleUnbootAction(vehicle)
    else
        VehicleBootAction(vehicle)
    end
end

--- VehicleBootAction — Pose un sabot sur le véhicule le plus proche
--- @param vehicleParam number|nil Handle du véhicule (optionnel, détecté si nil)
function VehicleBootAction(vehicleParam)
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Sabot", "Tu n'es pas en service")
        return
    end

    local vehicle = vehicleParam or GetNearestVehicle()
    if not vehicle then
        policeNotif("Sabot", "Aucun véhicule à proximité")
        return
    end

    if Entity(vehicle).state.hasBoot then
        policeNotif("Sabot", "Ce véhicule a déjà un sabot")
        return
    end

    -- Le véhicule doit être à l'arrêt
    if GetEntitySpeed(vehicle) > 1.0 then
        policeNotif("Sabot", "Le véhicule doit être à l'arrêt")
        return
    end

    local ped = PlayerPedId()

    local closestWheel = GetClosestWheel(ped, vehicle)
    if not closestWheel then
        policeNotif("Sabot", "Rapproche-toi d'une roue")
        return
    end

    -- Vérifier/consommer l'item sabot côté serveur
    local hasItem = TriggerServerCallback('core:jobs:vehicle:useSabot')
    if not hasItem then
        policeNotif("Sabot", "Tu n'as pas de sabot")
        return
    end

    -- Orienter le ped face au flanc du véhicule (perpendiculaire)
    local vehHeading = GetEntityHeading(vehicle)
    local isLeft = closestWheel.side == "left"
    -- Côté gauche : le ped regarde vers la droite du véhicule (heading + 90)
    -- Côté droit : le ped regarde vers la gauche du véhicule (heading - 90)
    local pedHeading = isLeft and (vehHeading - 90.0) or (vehHeading + 90.0)
    SetEntityHeading(ped, pedHeading)
    Wait(100)

    -- Animation accroupi devant la roue
    local animDict = "mp_car_bomb"
    local animName = "car_bomb_mechanic"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    local duration = VFW.Nui.ProgressBar("Pose du sabot...", 8 * 1000)

    ClearPedTasks(ped)
    RemoveAnimDict(animDict)

    if duration then
        NetworkRequestControlOfEntity(vehicle)
        local controlAttempts = 0
        while not NetworkHasControlOfEntity(vehicle) and controlAttempts < 30 do
            Wait(100)
            controlAttempts = controlAttempts + 1
            NetworkRequestControlOfEntity(vehicle)
        end

        local propModel = joaat('prop_clamp')
        RequestModel(propModel)
        local modelTimeout = GetGameTimer() + 5000
        while not HasModelLoaded(propModel) and GetGameTimer() < modelTimeout do Wait(50) end

        local boneIndex = GetEntityBoneIndexByName(vehicle, closestWheel.bone)
        local netId = nil

        if HasModelLoaded(propModel) then
            local bonePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local prop = VFW.OneSync.CreateObject(propModel, bonePos)
            Wait(500)
            SetModelAsNoLongerNeeded(propModel)

            netId = ObjToNet(prop)
            SetNetworkIdExistsOnAllMachines(netId, true)
            NetworkSetNetworkIdDynamic(netId, true)

            -- Offset et rotation selon le côté de la roue
            local isLeft = closestWheel.side == "left"
            local xOff = isLeft and -0.20 or 0.20
            local yOff = 0.0
            local zOff = -0.05
            local rotX = 0.0
            local rotY = 0.0
            local rotZ = isLeft and 0.0 or 180.0
            AttachEntityToEntity(prop, vehicle, boneIndex, xOff, yOff, zOff, rotX, rotY, rotZ, 1, 1, 0, 1, 0, 1)

            bootProps[vehicle] = prop
        else
            policeNotif("Sabot", "Erreur : modèle 3D introuvable")
        end

        -- Immobiliser localement pour feedback immédiat
        SetVehicleUndriveable(vehicle, true)
        FreezeEntityPosition(vehicle, true)
        SetVehicleHandbrake(vehicle, true)

        -- Le serveur valide et écrit les state bags (empêche la manipulation côté client)
        if NetworkGetEntityIsNetworked(vehicle) then
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            TriggerServerEvent("core:jobs:vehicle:applyBoot", vehicleNetId, netId, closestWheel.bone)
        end

        policeNotif("Sabot", "Sabot posé sur le véhicule")
    else
        TriggerServerEvent('core:jobs:vehicle:returnSabot')
    end
end

--- VehicleUnbootAction — Retire le sabot du véhicule le plus proche
--- @param vehicleParam number|nil Handle du véhicule (optionnel, détecté si nil)
function VehicleUnbootAction(vehicleParam)
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Sabot", "Tu n'es pas en service")
        return
    end

    local vehicle = vehicleParam or GetNearestVehicle()
    if not vehicle then
        policeNotif("Sabot", "Aucun véhicule à proximité")
        return
    end

    local hasBoot = Entity(vehicle).state.hasBoot
    if not hasBoot then
        policeNotif("Sabot", "Ce véhicule n'a pas de sabot")
        return
    end

    -- Vérifier que le véhicule est bien immobilisé (confirmation supplémentaire)
    if not IsEntityPositionFrozen(vehicle) then
        policeNotif("Sabot", "Ce véhicule n'a pas de sabot")
        return
    end

    local ped = PlayerPedId()

    -- Orienter le ped face au flanc du véhicule (perpendiculaire)
    local wheelBone = Entity(vehicle).state.bootWheel
    if wheelBone then
        local isLeft = wheelBone == "wheel_lf" or wheelBone == "wheel_lr"
        local vehHeading = GetEntityHeading(vehicle)
        local pedHeading = isLeft and (vehHeading - 90.0) or (vehHeading + 90.0)
        SetEntityHeading(ped, pedHeading)
        Wait(100)
    end

    local animDict = "mp_car_bomb"
    local animName = "car_bomb_mechanic"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    local duration = VFW.Nui.ProgressBar("Retrait du sabot...", 6 * 1000)

    ClearPedTasks(ped)
    RemoveAnimDict(animDict)

    if duration then
        NetworkRequestControlOfEntity(vehicle)
        local controlAttempts = 0
        while not NetworkHasControlOfEntity(vehicle) and controlAttempts < 30 do
            Wait(100)
            controlAttempts = controlAttempts + 1
            NetworkRequestControlOfEntity(vehicle)
        end

        -- Supprimer le prop sabot (via netId ou cache local)
        local propNetId = Entity(vehicle).state.bootPropNet
        if propNetId then
            local propObj = NetToObj(propNetId)
            if DoesEntityExist(propObj) then
                DeleteEntity(propObj)
            end
        end
        if bootProps[vehicle] and DoesEntityExist(bootProps[vehicle]) then
            DeleteEntity(bootProps[vehicle])
        end
        bootProps[vehicle] = nil

        SetVehicleUndriveable(vehicle, false)
        FreezeEntityPosition(vehicle, false)
        SetVehicleHandbrake(vehicle, false)

        -- Le serveur efface les state bags
        if NetworkGetEntityIsNetworked(vehicle) then
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            TriggerServerEvent("core:jobs:vehicle:removeBoot", vehicleNetId)
        end

        TriggerServerEvent('core:jobs:vehicle:returnSabot')
        policeNotif("Sabot", "Sabot retiré du véhicule.")
    end
end

-- State bag handler : appliquer l'effet sabot quand un véhicule change d'état
AddStateBagChangeHandler('hasBoot', nil, function(bagName, _, value)
    local entity = GetEntityFromStateBagName(bagName)
    if not entity or not DoesEntityExist(entity) or not IsEntityAVehicle(entity) then return end

    if value then
        SetVehicleUndriveable(entity, true)
        FreezeEntityPosition(entity, true)
        SetVehicleHandbrake(entity, true)

        -- Recréer le prop si on ne l'a pas localement (autre joueur qui stream in ou respawn)
        local propNetId = Entity(entity).state.bootPropNet
        local wheelBone = Entity(entity).state.bootWheel
        if propNetId and not bootProps[entity] then
            local propObj = NetToObj(propNetId)
            if DoesEntityExist(propObj) then
                bootProps[entity] = propObj
            elseif wheelBone then
                -- Le prop n'existe pas encore localement, attendre qu'il arrive
                CreateThread(function()
                    local attempts = 0
                    while attempts < 50 do
                        Wait(100)
                        propObj = NetToObj(propNetId)
                        if DoesEntityExist(propObj) then
                            bootProps[entity] = propObj
                            return
                        end
                        attempts = attempts + 1
                    end
                end)
            end
        end
    else
        SetVehicleUndriveable(entity, false)
        FreezeEntityPosition(entity, false)
        SetVehicleHandbrake(entity, false)

        -- Supprimer le prop local
        if bootProps[entity] and DoesEntityExist(bootProps[entity]) then
            DeleteEntity(bootProps[entity])
        end
        bootProps[entity] = nil
    end
end)

-- Restaurer le sabot après respawn d'un véhicule depuis la BDD
RegisterNetEvent("core:jobs:vehicle:restoreBoot", function(vehicleNetId, wheelBone)
    CreateThread(function()
        -- Attendre que le véhicule soit streamé
        local vehicle = nil
        local attempts = 0
        while attempts < 100 do
            vehicle = NetToVeh(vehicleNetId)
            if vehicle and DoesEntityExist(vehicle) then break end
            Wait(50)
            attempts = attempts + 1
        end
        if not vehicle or not DoesEntityExist(vehicle) then return end
        if bootProps[vehicle] then return end -- déjà créé

        -- Immobiliser
        SetVehicleUndriveable(vehicle, true)
        FreezeEntityPosition(vehicle, true)
        SetVehicleHandbrake(vehicle, true)

        -- Créer le prop sabot
        local model = `prop_clamp`
        RequestModel(model)
        local waited = 0
        while not HasModelLoaded(model) and waited < 5000 do Wait(10) waited = waited + 10 end
        if not HasModelLoaded(model) then return end

        local boneIndex = GetEntityBoneIndexByName(vehicle, wheelBone)
        if boneIndex == -1 then SetModelAsNoLongerNeeded(model) return end

        local prop = VFW.OneSync.CreateObject(model, GetEntityCoords(vehicle))
        if not DoesEntityExist(prop) then SetModelAsNoLongerNeeded(model) return end

        local isLeft = wheelBone == "wheel_lf" or wheelBone == "wheel_lr"
        local xOff = isLeft and -0.20 or 0.20
        AttachEntityToEntity(prop, vehicle, boneIndex, xOff, 0.0, -0.05, 0.0, 0.0, isLeft and 0.0 or 180.0, 1, 1, 0, 1, 0, 1)
        bootProps[vehicle] = prop
        SetModelAsNoLongerNeeded(model)

        -- Sync le propNetId au serveur
        if NetworkGetEntityIsNetworked(prop) and NetworkGetEntityIsNetworked(vehicle) then
            local propNet = NetworkGetNetworkIdFromEntity(prop)
            local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
            TriggerServerEvent("core:jobs:vehicle:updateBootProp", vehNet, propNet)
        end
    end)
end)

-- Cleanup sabot quand un véhicule est supprimé (dv, fourrière, etc.)
RegisterNetEvent("core:jobs:vehicle:cleanupBoot", function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if vehicle and bootProps[vehicle] then
        if DoesEntityExist(bootProps[vehicle]) then
            DeleteEntity(bootProps[vehicle])
        end
        bootProps[vehicle] = nil
    end
    -- Aussi nettoyer les orphelins
    for veh, prop in pairs(bootProps) do
        if not DoesEntityExist(veh) then
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
            bootProps[veh] = nil
        end
    end
end)

-- Cleanup : supprimer les props sabots au stop de la resource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for vehicle, prop in pairs(bootProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    bootProps = {}
end)

--- ToggleBracelet — Pose/retire un bracelet sur le joueur ciblé
function ToggleBracelet()
    if not VFW.PlayerData.job.onDuty then
        policeNotif("Bracelet", "Tu n'es pas en service")
        return
    end

    Wait(150)
    local playerId = VFW.StartSelect(5.0, true)
    if not playerId then
        policeNotif("Bracelet", "Aucun citoyen sélectionné")
        return
    end

    TriggerServerEvent("core:jobs:setBracelet", GetPlayerServerId(playerId))
end
