---@meta _
---@diagnostic disable: duplicate-doc-field

-- Appliquer la réparation carrosserie sur un véhicule
local function ApplyBodyworkRepair(vehicle, engineHealth)
    if not DoesEntityExist(vehicle) then
        return
    end

    SetVehicleFixed(vehicle)
    Wait(0)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, engineHealth)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleUndriveable(vehicle, false)

    for i = 0, 7 do
        FixVehicleWindow(vehicle, i)
    end

    for i = 0, 5 do
        SetVehicleDoorShut(vehicle, i, false)
    end

    Wait(100)

    -- Mettre à jour le statebag VehicleProperties pour que le système ne ré-applique pas les dommages
    if NetworkGetEntityOwner(vehicle) == PlayerId() then
        local props = VFW.Game.GetVehicleProperties(vehicle)
        if props then
            Entity(vehicle).state:set("VehicleProperties", props, true)
        end
    end
end

-- Réception réparation carrosserie relayée par le serveur (pour les autres clients)
RegisterNetEvent("core:mechanic:repairBodywork:apply", function(netId, engineHealth)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    ApplyBodyworkRepair(vehicle, engineHealth)
end)

-- Réception réparation moteur relayée par le serveur
RegisterNetEvent("core:mechanic:repairEngine:apply", function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleUndriveable(vehicle, false)
    if NetworkGetEntityOwner(vehicle) == PlayerId() then
        local props = VFW.Game.GetVehicleProperties(vehicle)
        if props then
            Entity(vehicle).state:set("VehicleProperties", props, true)
        end
    end
end)

-- Réception nettoyage véhicule relayé par le serveur
RegisterNetEvent("core:mechanic:cleanVehicle:apply", function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    SetVehicleDirtLevel(vehicle, 0.0)
end)

--- RepairVehicle
function RepairVehicle()
    local closestVehicle, distance = VFW.Game.GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

    if VFW.PlayerData.job.onDuty then
        if distance < 5 then
            local hasItem = TriggerServerCallback("core:mechanic:hasRepairKit")
    
            if hasItem then
                TaskStartScenarioInPlace(VFW.PlayerData.ped, "PROP_HUMAN_BUM_BIN", 0, true)
                FreezeEntityPosition(VFW.PlayerData.ped, true)
                local duration = VFW.Nui.ProgressBar("Réparation en cours...", 10000, true)
                FreezeEntityPosition(VFW.PlayerData.ped, false)

                if duration then
                    local netId = VehToNet(closestVehicle)
                    TriggerServerEvent("core:mechanic:repairEngine", netId)
                    ClearPedTasksImmediately(VFW.PlayerData.ped)

                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Reparation terminée !"
                    })
                end
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous n'avez pas de kit de réparation !"
                })
            end
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Aucun véhicule à proximité !"
            })
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
    end
end

--- CleanVehicle
function CleanVehicle()
    local closestVehicle, distance = VFW.Game.GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous devez être en service pour accéder à cette fonctionnalité." })
        return
    end

    if distance >= 5 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule à proximité !" })
        return
    end

    local hasItem = TriggerServerCallback("core:mechanic:hasCleanKit")
    if not hasItem then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas de kit de nettoyage !" })
        return
    end

    local ped = VFW.PlayerData.ped
    local animDict = "timetable@floyd@clean_kitchen@base"
    local spongeModel = `prop_sponge_01`

    RequestAnimDict(animDict)
    local animTimeout = 0
    while not HasAnimDictLoaded(animDict) and animTimeout < 1000 do
        Wait(10)
        animTimeout = animTimeout + 10
    end

    RequestModel(spongeModel)
    local modelTimeout = 0
    while not HasModelLoaded(spongeModel) and modelTimeout < 1000 do
        Wait(10)
        modelTimeout = modelTimeout + 10
    end

    local pedCoords = GetEntityCoords(ped)
    local sponge = CreateObject(spongeModel, pedCoords.x, pedCoords.y, pedCoords.z, false, true, false)
    AttachEntityToEntity(sponge, ped, GetPedBoneIndex(ped, 57005),
        0.15, 0.0, -0.01, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(spongeModel)

    TaskPlayAnim(ped, animDict, "base", 8.0, -8.0, -1, 49, 0.0, false, false, false)

    local duration = VFW.Nui.ProgressBar("Nettoyage en cours...", 10000, true)

    StopAnimTask(ped, animDict, "base", 1.0)
    ClearPedTasks(ped)
    if DoesEntityExist(sponge) then
        DetachEntity(sponge, false, false)
        DeleteEntity(sponge)
    end
    RemoveAnimDict(animDict)

    if not duration then
        return
    end

    local netId = VehToNet(closestVehicle)
    TriggerServerEvent("core:mechanic:cleanVehicle", netId)

    VFW.ShowNotification({ type = 'VERT', content = "Nettoyage terminé !" })
end

--- RepairCarroserieVehicle
function RepairCarroserieVehicle()
    local closestVehicle, distance = VFW.Game.GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

    if VFW.PlayerData.job.onDuty then
        if distance < 5 then
            local getEngine = GetVehicleEngineHealth(closestVehicle)
            local hasItem = TriggerServerCallback("core:mechanic:hasCarroserieKit")

            if hasItem then
                local ped = VFW.PlayerData.ped
                local netId = NetworkGetNetworkIdFromEntity(closestVehicle)
                TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true)
                FreezeEntityPosition(ped, true)
                local duration = VFW.Nui.ProgressBar("Réparation en cours...", 10000, true)
                FreezeEntityPosition(ped, false)

                if duration then
                    -- Retrouver le véhicule par netId au cas où le handle a changé
                    local veh = NetworkGetEntityFromNetworkId(netId)
                    if not DoesEntityExist(veh) then
                        veh = closestVehicle
                    end

                    -- Réparation directe
                    ApplyBodyworkRepair(veh, getEngine)

                    -- Sync les autres clients
                    TriggerServerEvent("core:mechanic:repairBodywork", netId, getEngine)

                    ClearPedTasksImmediately(ped)

                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Reparation terminée !"
                    })
                end
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous n'avez pas de kit de carrosserie !"
                })
            end
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Aucun véhicule à proximité !"
            })
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
    end
end

--- CrochetVehicle
function CrochetVehicle()
    local closestVehicle, distance = VFW.Game.GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

    if VFW.PlayerData.job.onDuty then
        if distance < 5 then
            local hasItem = TriggerServerCallback("core:mechanic:hasCrochetageKit")

            if hasItem then
                TaskStartScenarioInPlace(VFW.PlayerData.ped, "WORLD_HUMAN_WELDING", 0, true)
                local duration = VFW.Nui.ProgressBar("Crochetage en cours...", 10000)

                if duration then
                    SetVehicleDoorsLocked(closestVehicle, 1)
                    ClearPedTasksImmediately(VFW.PlayerData.ped)

                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Crochetage terminé !"
                    })
                end
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous n'avez pas de kit de crochetage !"
                })
            end
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Aucun véhicule à proximité !"
            })
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
    end
end

--- PoundVehicle
function PoundVehicle()
    local closestVehicle, distance = VFW.Game.GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

    if VFW.PlayerData.job.onDuty then
        if distance < 5 then
            local ped = VFW.PlayerData.ped
            local dict = "amb@world_human_clipboard@male@idle_a"
            local anim = "idle_c"
            local propModel = `p_amb_clipboard_01`

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do Wait(0) end
            RequestModel(propModel)
            while not HasModelLoaded(propModel) do Wait(0) end

            local prop = CreateObject(propModel, 0.0, 0.0, 0.0, false, false, false)
            AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 36029), 0.16, 0.08, 0.03, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)

            FreezeEntityPosition(ped, true)
            local duration = VFW.Nui.ProgressBar("Mise en fourrière en cours...", 10000, true)
            FreezeEntityPosition(ped, false)

            ClearPedTasksImmediately(ped)
            if DoesEntityExist(prop) then
                DeleteObject(prop)
            end
            SetModelAsNoLongerNeeded(propModel)
            RemoveAnimDict(dict)

            if duration then
                TriggerServerEvent("vfw:vehicle:keyTemporarly:remove", nil, VFW.Math.Trim(GetVehicleNumberPlateText(closestVehicle)))
                TriggerServerEvent("vfw:mechanic:impound", VFW.Math.Trim(GetVehicleNumberPlateText(closestVehicle)))
                VFW.Game.DeleteVehicle(closestVehicle)

                VFW.ShowNotification({
                    type = 'VERT',
                    content = "Véhicule mis en fourrière !"
                })
            end
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Aucun véhicule à proximité !"
            })
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
    end
end

RegisterNetEvent("vfw:mechanic:useRepairKit", function()
    local closestVehicle, distance = VFW.Game.GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

    if distance < 5 then
        local ped = VFW.PlayerData.ped
        TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true)
        FreezeEntityPosition(ped, true)
        local duration = VFW.Nui.ProgressBar("Réparation en cours...", 10000, true)
        FreezeEntityPosition(ped, false)

        if duration then
            local netId = VehToNet(closestVehicle)
            TriggerServerEvent("core:mechanic:repairEngine", netId)
            ClearPedTasksImmediately(ped)

            VFW.ShowNotification({
                type = 'VERT',
                content = "Reparation terminée !"
            })
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Aucun véhicule à proximité !"
        })
    end
end)

local BoucleActive = false
local PlateauPosHaut = 3.8
local PlateauPosBas = 8.1
local Rope
local ModelCrochet = `prop_rope_hook_01`
local Crochet
local TowRope
local PreviousLength = 0
local ClosestTow
local MaxLengthRope = 19.0
local VehAttachee = {}
local Notif = {}
local me = PlayerPedId()

RegisterNetEvent('core:VehAttachee')
---@param list any
AddEventHandler('core:VehAttachee', function(list)
    VehAttachee = list
end)

local Key = {
    Plateau_dep = false,
    Plateau_treuil = false
}
-- RegisterKeyMapping('Plateau_dep', 'Dépanneuse plateau~', 'keyboard', 'j')
-- RegisterKeyMapping('Plateau_treuil', 'Dépanneuse treuil~', 'keyboard', 'h')

RegisterCommand('Plateau_dep', function()
    Key['Plateau_dep'] = true
end)

RegisterCommand('Plateau_treuil', function()
    Key['Plateau_treuil'] = true
end)

CreateThread(function()
    local veh, plateau, vehTow = nil, nil
    local BoucleLent = 1000
    local BoucleRapide = 5
    local TempsBoucle = BoucleRapide
    local MovePlateau = {distance = 4.8,rotation = 13}
    local vitesse = {deplacement = 0.015,rotation = .5}
    local HelpMessage = {}

    TriggerServerEvent('core:GetVehAttachee')
    while true do
---@class HelpMessage
        HelpMessage = {}
        TempsBoucle = BoucleLent
        me = PlayerPedId()
        if IsPedInAnyVehicle(me,false) then
            DisableControlAction(0,60,true)
            if IsPedInModel(me,`flatbed3`) then
                if GetEntitySpeed(me) < 0.5 then
                    TempsBoucle = BoucleRapide
                    veh = GetVehiclePedIsIn(me,true)
                    pos = GetEntityCoords(veh)
                    local BodyBone = GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'bodyshell'))
                    local PlateauBone = GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'misc_a'))
                    local libelle = "remonter le plateau"
                    if Vdist(BodyBone,PlateauBone) < PlateauPosHaut then
                        libelle = "descendre le plateau"
                    end

                    table.insert(HelpMessage,'Pressez ~INPUT_6BBAD9AD~ pour '..libelle )
                    if Key['Plateau_dep'] then
                        if Rope then
                            --TriggerEvent('hud:NotifColor','Vous devez ranger le crochet avant de bouger le plateau',6)
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                -- duration = 5, -- In seconds, default:  4
                                content = "Vous devez ranger le crochet avant de bouger le plateau"
                            })
                        else
                            if Vdist(BodyBone,PlateauBone) < PlateauPosHaut then
                                --Descendre le plateau
                                while Vdist(BodyBone,PlateauBone) < PlateauPosBas and IsPedInAnyVehicle(me,false) do
                                    SetControlNormal(1,60,-0.3)
                                    BodyBone = GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'bodyshell'))
                                    PlateauBone = GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'misc_a'))
                                    Wait(0)
                                end

                                FreezeEntityPosition(veh,true)
                            else
                                --Monter le plateau
                                FreezeEntityPosition(veh,false)
                                while Vdist(BodyBone,PlateauBone) > 3.8 and IsPedInAnyVehicle(me,false) do
                                    SetControlNormal(1,60,0.3)
                                    BodyBone = GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'bodyshell'))
                                    PlateauBone = GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'misc_a'))
                                    Wait(0)
                                end
                            end
                        end

                        Key['Plateau_dep'] = false
                    end
                end
            end
        else
            local ClosestVeh = GetClosestVehicleFromPlayer(2.5)
            if ClosestVeh ~= 0 then
                if IsVehicleModel(ClosestVeh,`flatbed3`) then
                    ClosestTow = ClosestVeh
                    local RopePosition = GetWorldPositionOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'misc_s'))
                    RopePosition = vector3(RopePosition.x,RopePosition.y,RopePosition.z -1.0)
                    CoordPlayer = GetEntityCoords(me)
                    if Vdist(CoordPlayer,RopePosition) <= 1.5 then
                        TempsBoucle = BoucleRapide
                        if Rope and IsEntityAttachedToEntity(Crochet,me) then
                            TempsBoucle = BoucleRapide
                            table.insert(HelpMessage,'Pressez ~INPUT_CONTEXT~ pour ranger le cable')
                            if VFW.Interact.JustPressed(1, 51) then
                                local BodyBone = GetWorldPositionOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'bodyshell'))
                                local PlateauBone = GetWorldPositionOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'misc_a'))
                                if Vdist(BodyBone,PlateauBone) < PlateauPosBas then
                                    FreezeEntityPosition(ClosestTow,false)
                                end

                                TaskPlayAnim(me, "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
                                Wait(800)
                                RopeUnloadTextures()
                                DeleteRope(Rope)
                                DeleteEntity(Crochet)
                                Rope = nil
                                Crochet = nil
                            end
                        else
                            table.insert(HelpMessage,'Pressez ~INPUT_CONTEXT~ pour prendre le cable')
                            if VFW.Interact.JustPressed(1, 51) then
                                FreezeEntityPosition(ClosestTow,true)
                                RequestModel(ModelCrochet)
                                while not HasModelLoaded(ModelCrochet) do
                                    Wait(1)
                                end

                                TriggerSWEvent("TREFSDFD5156FD", "IOAPP", 5000)
                                while not HasAnimDictLoaded('pickup_object') do
                                    RequestAnimDict('pickup_object')
                                    Wait(0)
                                end

                                TaskPlayAnim(me, "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
                                Wait(800)
                                Crochet = CreateObject(ModelCrochet, 1.0, 1.0, 1.0, 0, 1, 0)
                                while not DoesEntityExist(Crochet) do
                                    Wait(0)
                                end

                                SetEntityCollision(Crochet,false,true)
                                AttachEntityToEntity(Crochet, me, GetPedBoneIndex(me, 28422), 0.08, 0.0, -0.04, -90.0, 0.0, 180.0, 1, 1, 0, 0, 2, 1)
                                local HandPos =  GetOffsetFromEntityInWorldCoords(Crochet,0.0,0.0,0.13)
                                local OriginRope = GetOriginCableTow(ClosestTow)
                                local length = #(HandPos-OriginRope)
                                if length < 1 then
                                    length = 1.0
                                end

                                RopeLoadTextures()
                                Rope = AddRope(OriginRope.x, OriginRope.y, OriginRope.z, 0.0, 0.0, 0.0, MaxLengthRope, 4, length, 0.05, 1.0, 0, 0, 0, true, 0, 0)
                                AttachEntitiesToRope(Rope, Crochet, ClosestTow, HandPos.x, HandPos.y, HandPos.z, OriginRope.x, OriginRope.y, OriginRope.z, length, false, false,   GetPedBoneIndex(me, 28422),GetEntityBoneIndexByName(ClosestTow,'misc_b'))
                                ActivatePhysics(Rope)
                                SetModelAsNoLongerNeeded(ModelCrochet)
                                Wait(5)
                                StartRopeUnwindingFront(Rope)
                            end
                        end
                    else
                        if NearRoue(ClosestTow) then
                            TempsBoucle = BoucleRapide
                            local BodyBone = GetWorldPositionOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'bodyshell'))
                            local PlateauBone = GetWorldPositionOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'misc_a'))
                            if Vdist(BodyBone,PlateauBone) > PlateauPosBas then
                                TempsBoucle = BoucleRapide
                                CoordPlayer = GetEntityCoords(me)
                                local AttachedCar = NetworkGetEntityIsNetworked(ClosestTow) and VehAttachee[NetworkGetNetworkIdFromEntity(ClosestTow)] or nil
                                if AttachedCar ~= nil then
                                    AttachedCar = NetworkGetEntityFromNetworkId(AttachedCar)
                                end

                                local libelle = "décrocher le véhicule"
                                if not DoesEntityExist(AttachedCar) then
                                    AttachedCar = 0
                                    libelle = "accrocher le véhicule"
                                end

                                table.insert(HelpMessage,'Pressez ~INPUT_CONTEXT~ pour '..libelle)
                                if VFW.Interact.JustPressed(1, 51) then
                                    --Attachage du véhicule
                                    if AttachedCar > 0 then
                                        DetachEntity(AttachedCar,true,true)
                                        --TriggerEvent('hud:NotifColor',"Véhicule décroché",141)
                                        VFW.ShowNotification({
                                            type = 'VERT',
                                            -- duration = 5, -- In seconds, default:  4
                                            content = "Le véhicule est décroché."
                                        })
                                        if NetworkGetEntityIsNetworked(ClosestTow) then
                                            local closestTowNetId = NetworkGetNetworkIdFromEntity(ClosestTow)
                                            TriggerServerEvent('core:DeleteVehAttachee', closestTowNetId)
                                            VehAttachee[closestTowNetId] = nil
                                        end
                                    else
                                        if Crochet then
                                            DeleteRope(Rope)
                                            DeleteEntity(Crochet)
                                            RopeUnloadTextures()
                                            Rope = nil
                                            Crochet = nil
                                        end

                                        --Accroche
                                        local NewCoord = GetOffsetFromEntityInWorldCoords(ClosestTow,0.0,-7.0,1.0)
                                        local TowedCar = GetVehicleInCoord(NewCoord,3.0)
                                        if TowedCar == ClosestTow then
                                            --TriggerEvent('hud:NotifColor','Aucun véhicule sur le plateau',6)
                                            VFW.ShowNotification({
                                                type = 'JAUNE',
                                                -- duration = 5, -- In seconds, default:  4
                                                content = "Aucun véhicule sur le plateau"
                                            })
                                        else
                                            local CoordsBone = GetWorldPositionOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'misc_s'))
                                            local Rotation = GetWorldRotationOfEntityBone(ClosestTow,GetEntityBoneIndexByName(ClosestTow,'misc_s'))
                                            local CoordsCar = GetWorldPositionOfEntityBone(TowedCar,GetEntityBoneIndexByName(TowedCar,'bodyshell'))
                                            local hauteur = CoordsBone.z - CoordsCar.z
                                            local Longueur = #(CoordsCar-CoordsBone)
                                            local alpha = math.sin(hauteur/Longueur)
                                            local beta = alpha - math.rad(1.0*Rotation.x)
                                            local z = math.sin(beta)*Longueur + 0.25
                                            local y = math.cos(beta)*Longueur
                                            AttachEntityToEntity(TowedCar, ClosestTow,GetEntityBoneIndexByName(ClosestTow,'misc_s'),0.0, -y,-z, 0, 0, 0, true, false, true, true, 0, true)
                                            --TriggerEvent('hud:NotifColor',"",141)
                                            VFW.ShowNotification({
                                                type = 'VERT',
                                                -- duration = 5, -- In seconds, default:  4
                                                content = "Le véhicule est accroché."
                                            })
                                            if NetworkGetEntityIsNetworked(ClosestTow) and NetworkGetEntityIsNetworked(TowedCar) then
                                                local closestTowNetId = NetworkGetNetworkIdFromEntity(ClosestTow)
                                                local towedCarNetId = NetworkGetNetworkIdFromEntity(TowedCar)
                                                TriggerServerEvent('core:AddVehAttachee', closestTowNetId, towedCarNetId)
                                                VehAttachee[closestTowNetId] = towedCarNetId
                                            end
                                        end
                                    end
                                end
                            end

                            if Rope and not IsEntityAttachedToEntity(Crochet,me) then
                                table.insert(HelpMessage,'Maintenez ~INPUT_72A49F59~ pour enrouler le treuil')
                                if Key['Plateau_treuil'] then
                                    local length = RopeGetDistanceBetweenEnds(Rope)
                                    StartRopeWinding(Rope)
                                    RopeForceLength(Rope,length)
                                    --TriggerServerEvent('InteractSound:PlayFromCoord',GetOriginCableTow(ClosestTow),5.0,'treuil_start', 0.3)
                                    Wait(100)
                                    --TriggerServerEvent('InteractSound:PlayFromCoord',GetOriginCableTow(ClosestTow),5.0,'treuil_loop', 0.3)
                                    local StartSound = GetGameTimer()

                                    while IsControlPressed(1,74) do
                                        Wait(0)
                                        if StartSound+1500<GetGameTimer() then
                                            --TriggerServerEvent('InteractSound:PlayFromCoord',GetOriginCableTow(ClosestTow),5.0,'treuil_loop', 0.3)
                                            StartSound = GetGameTimer()
                                        end
                                    end

                                    --TriggerServerEvent('InteractSound:PlayFromCoord',GetOriginCableTow(ClosestTow),5.0,'treuil_end', 0.3)
                                    StopRopeWinding(Rope)
                                    Key['Plateau_treuil'] = false
                                end
                            end
                        end
                    end
                elseif Rope and IsEntityAttachedToEntity(Crochet,me) then
                    table.insert(HelpMessage,'Pressez ~INPUT_CONTEXT~ pour accrocher le crochet au véhicule')
                    if VFW.Interact.JustPressed(1, 51) then
                        local Dimension = GetModelDimensions(ClosestVeh)
                        TaskPlayAnim(me, "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
                        Wait(800)
                        local ClosestBone = GetClosestBoneVeh(ClosestVeh)
                        DetachEntity(Crochet)
                        AttachEntityToEntity(Crochet, ClosestVeh, ClosestBone, -0.1, 0.0, -0.05, 90.0, 180.0, 0.0, 1, 1, 0, 0, 2, 1)
                        local OriginRope = GetOriginCableTow(ClosestTow)
                        local CarPos = GetWorldPositionOfEntityBone(ClosestVeh,ClosestBone)
                        local length = #(OriginRope - CarPos)
                        AttachEntitiesToRope(Rope, ClosestVeh, ClosestTow, CarPos.x,CarPos.y,CarPos.z, OriginRope.x, OriginRope.y, OriginRope.z, length, false, false,  ClosestBone,GetEntityBoneIndexByName(ClosestTow,'misc_b'))
                        ActivatePhysics(Rope)
                    end
                end
            end

            if Rope then
                TempsBoucle = BoucleRapide
                if IsEntityAttachedToEntity(Crochet,me) then
                    if RopeGetDistanceBetweenEnds(Rope) > MaxLengthRope + 1.0 then
                        --TriggerEvent('hud:NotifColor','Cable déroulé au maximum',6)
                        VFW.ShowNotification({
                            type = 'ROUGE',
                            -- duration = 5, -- In seconds, default:  4
                            content = "Le treuil est déroulé au maximum."
                        })
                        DetachEntity(Crochet)
                    end

                    table.insert(HelpMessage,'Pressez ~INPUT_72A49F59~ pour lacher le crochet')
                    if Key['Plateau_treuil'] then
                        DetachEntity(Crochet)
                        Key['Plateau_treuil'] = false
                    end
                else
                    if Vdist(GetEntityCoords(Crochet),CoordPlayer) < 2.0 then
                        table.insert(HelpMessage,'Pressez ~INPUT_72A49F59~ pour reprendre le crochet')
                        if Key['Plateau_treuil'] then
                            TaskPlayAnim(me, "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
                            Wait(800)
                            AttachEntityToEntity(Crochet, me, GetPedBoneIndex(me, 28422), 0.08, 0.0, -0.04, -90.0, 0.0, 180.0, 1, 1, 0, 0, 2, 1)
                            local HandPos = GetOffsetFromEntityInWorldCoords(Crochet,0.0,0.0,0.13)
                            local OriginRope = GetOriginCableTow(ClosestTow)
                            local length = #(HandPos-OriginRope)
                            if length < 1 then
                                length = 1.0
                            end

                            AttachEntitiesToRope(Rope, Crochet, ClosestTow, HandPos.x, HandPos.y, HandPos.z, OriginRope.x, OriginRope.y, OriginRope.z, length, false, false,   GetPedBoneIndex(me, 28422),GetEntityBoneIndexByName(ClosestTow,'misc_b'))
                            Key['Plateau_treuil'] = false
                        end
                    end
                end
            end
        end

        if HelpMessage[1] ~= nil then
            DisplayHelp(HelpMessage)
        end

        Wait(TempsBoucle)
    end
end)

---Get VehicleInCoord
---@param coord any
---@param taille any
---@return number|nil Vehicle handle
function GetVehicleInCoord(coord,taille)
    local rayHandle = Citizen.InvokeNative(0x28579D1B8F8AAC80,coord.x, coord.y, coord.z -.5, coord.x, coord.y, coord.z +.5, taille, 10, PlayerPedId(), 0)
    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

---Get ClosestVehicleFromPlayer
---@param distance any
---@return table|nil Player object
function GetClosestVehicleFromPlayer(distance)
    local coordA = GetEntityCoords(me, 1)
    local coordB = GetOffsetFromEntityInWorldCoords(me, 0.0, distance, 0.0)
    local rayHandle = Citizen.InvokeNative(0x28579D1B8F8AAC80,coordA.x, coordA.y, coordA.z, coordB.x, coordB.y, coordB.z, distance/2, 10, me, 0)
    local a, b, c, d, vehicle = GetRaycastResult(rayHandle)

    if(GetEntityType(vehicle) == 2) then
        return vehicle
    else
        return 0
    end
end

---Get ClosestBoneVeh
---@param veh any
function GetClosestBoneVeh(veh)
    listbones = {'neon_f','bumper_f','neon_l','neon_r','neon_b','bumper_r','engine'}
    local dist
    local ClosBone
    CoordPlayer = GetEntityCoords(me)
    for _,bone in pairs (listbones) do
        if GetEntityBoneIndexByName(veh,bone) ~= -1 then
            local Calculdist = Vdist(CoordPlayer,GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,bone)))
            if ClosBone == nil then
                ClosBone = bone
                dist = Calculdist
            else
                if dist > Calculdist then
                    ClosBone = bone
                    dist = Calculdist
                end
            end
        end
    end

    return GetEntityBoneIndexByName(veh,ClosBone)
end

--- NearRoue
---@param veh any
---@return boolean
function NearRoue(veh)
    if Vdist(CoordPlayer, GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'wheel_lr'))) < 2.0 then
        return true
    end

    if Vdist(CoordPlayer, GetWorldPositionOfEntityBone(veh,GetEntityBoneIndexByName(veh,'wheel_rr'))) < 2.0 then
        return true
    end

    return false
end

---Get OriginCableTow
---@param tow any
---@return any
function GetOriginCableTow(tow)
    local OriginRope = GetWorldPositionOfEntityBone(tow,GetEntityBoneIndexByName(tow,'misc_b'))
    local distance = 0.3
    local heading = GetEntityHeading(tow)
    local rad = math.pi/2+math.rad(heading + 90)
    local OriginRope = vector3(
            OriginRope.x+distance*math.cos(rad),
            OriginRope.y+distance*math.sin(rad),
            OriginRope.z +0.3
    )
    return OriginRope
end

--- DisplayHelp
---@param strs any
function DisplayHelp(strs)
    local texte = ""
    if type(strs) == 'table' then
        for i, str in pairs(strs) do
            if i > 1 then
                texte = texte .. "~n~"
            end
            texte = texte .. str
        end
    else
        texte = strs
    end
    VFW.ShowHelpNotification(texte)
end

RegisterNetEvent('hud:NotifColor')
---@param txt any
---@param color any
AddEventHandler('hud:NotifColor', function(txt,color)
    txt=tostring(txt)
    length = string.len(txt)
    local Type = "STRING"
    if length <= 90 then
        Type = "STRING"
    elseif length <= 90 * 2 then
        Type = "THREESTRINGS"
    elseif length <= 90 * 3 then
        Type = "THREESTRINGS"
    end

    SetNotificationTextEntry(Type)
    Citizen.InvokeNative(0x92F0DA1E27DB96DC , color)
    AddTextComponentString(txt)
    local Notification = DrawNotification(false, false)
    table.insert(Notif,Notification)
end)

RegisterNetEvent('InteractSound:PlayFromCoord_CL')
---@param coord any
---@param maxDistance any
---@param soundFile any
---@param soundVolume any
AddEventHandler('InteractSound:PlayFromCoord_CL',function(coord,maxDistance,soundFile,soundVolume)
    local CoordJoueur = GetEntityCoords(PlayerPedId())
    local distance = Vdist(coord.x,coord.y,coord.z,CoordJoueur.x,CoordJoueur.y,CoordJoueur.z)
    if distance < maxDistance then
        local Volume = (1-distance/maxDistance)*soundVolume
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = Volume
        })
    end
end)

-- ============================================
-- TCGUARDOW PLATEAU (FLATBED)
-- ============================================

--- Get the closest tcguardow near the player
---@param maxDistance number Maximum distance
---@return number|nil tcguardow entity or nil
function GetClosestTcguardow(maxDistance)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool('CVehicle')
    local closest, closestDist = nil, maxDistance + 1

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) and IsVehicleModel(veh, `tcguardow`) then
            local dist = #(playerCoords - GetEntityCoords(veh))
            if dist < closestDist then
                closest = veh
                closestDist = dist
            end
        end
    end

    if closestDist <= maxDistance then
        return closest
    end
    return nil
end

--- Check if a vehicle is already loaded on a tcguardow
---@param tcguardow number The tcguardow entity
---@return number|nil The loaded vehicle entity or nil
function GetVehicleOnTcguardow(tcguardow)
    -- Primary check: server-synced VehAttachee table
    if NetworkGetEntityIsNetworked(tcguardow) then
        local netId = NetworkGetNetworkIdFromEntity(tcguardow)
        local attachedNetId = VehAttachee[netId]
        if attachedNetId then
            local attached = NetworkGetEntityFromNetworkId(attachedNetId)
            if DoesEntityExist(attached) and IsEntityAttachedToEntity(attached, tcguardow) then
                return attached
            end
        end
    end

    -- Fallback: scan nearby vehicles physically attached to the tcguardow.
    -- Covers cases where VehAttachee is stale (server desync, brutal disconnect, late join)
    -- or the tcguardow is not networked yet.
    local tcCoords = GetEntityCoords(tcguardow)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if veh ~= tcguardow and DoesEntityExist(veh) and IsEntityAttachedToEntity(veh, tcguardow) then
            return veh
        end
    end

    return nil
end

--- Load a vehicle onto the tcguardow plateau
---@param targetVehicle number Vehicle to load
---@param tcguardow number|nil The tcguardow (auto-detect if nil)
function LoadVehicleOnTcguardow(targetVehicle, tcguardow)
    local playerPed = PlayerPedId()

    if not targetVehicle or not DoesEntityExist(targetVehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    -- Find tcguardow if not provided
    if not tcguardow then
        tcguardow = GetClosestTcguardow(10.0)
    end

    if not tcguardow or not DoesEntityExist(tcguardow) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun plateau (tcguardow) à proximité" })
        return
    end

    -- Can't load the tcguardow onto itself
    if targetVehicle == tcguardow then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas charger ce véhicule" })
        return
    end

    -- Check if already loaded
    if GetVehicleOnTcguardow(tcguardow) then
        VFW.ShowNotification({ type = 'ORANGE', content = "Un véhicule est déjà chargé sur le plateau" })
        return
    end

    -- Check no one is in the target vehicle
    if GetPedInVehicleSeat(targetVehicle, -1) ~= 0 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Un conducteur est dans le véhicule" })
        return
    end

    -- Turn player to face the vehicle
    TaskTurnPedToFaceEntity(playerPed, targetVehicle, 1000)
    Wait(1000)

    -- Play animation
    local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
    end
    TaskPlayAnim(playerPed, animDict, "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Progress bar
    local success = VFW.Nui.ProgressBar("Chargement du véhicule...", 8000)
    ClearPedTasks(playerPed)

    if not success then
        VFW.ShowNotification({ type = 'ROUGE', content = "Chargement annulé" })
        return
    end

    if not DoesEntityExist(targetVehicle) or not DoesEntityExist(tcguardow) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    -- Ensure both entities are networked so attach replicates to other clients
    if not NetworkGetEntityIsNetworked(targetVehicle) then
        NetworkRegisterEntityAsNetworked(targetVehicle)
    end
    if not NetworkGetEntityIsNetworked(tcguardow) then
        NetworkRegisterEntityAsNetworked(tcguardow)
    end

    -- Request control of the vehicle so AttachEntityToEntity actually sticks for other clients
    NetworkRequestControlOfEntity(targetVehicle)
    local tries = 0
    while not NetworkHasControlOfEntity(targetVehicle) and tries < 20 do
        Wait(50)
        NetworkRequestControlOfEntity(targetVehicle)
        tries = tries + 1
    end

    -- Attach the vehicle on top of the plateau bed
    -- The bed is in the rear half, lower than the cabin
    local tcMin, tcMax = GetModelDimensions(GetEntityModel(tcguardow))
    local bedY = (tcMin.y + tcMax.y) / 2 - 2.0 -- centered more towards rear
    local bedZ = 0.4 -- approximate bed height from vehicle origin

    AttachEntityToEntity(targetVehicle, tcguardow, 0, 0.0, bedY, bedZ, 0.0, 0.0, 0.0, true, false, true, true, 0, true)

    -- Sync via server
    if NetworkGetEntityIsNetworked(tcguardow) and NetworkGetEntityIsNetworked(targetVehicle) then
        local tcguardowNetId = NetworkGetNetworkIdFromEntity(tcguardow)
        local vehicleNetId = NetworkGetNetworkIdFromEntity(targetVehicle)
        TriggerServerEvent('core:AddVehAttachee', tcguardowNetId, vehicleNetId)
        VehAttachee[tcguardowNetId] = vehicleNetId
    end

    VFW.ShowNotification({ type = 'VERT', content = "Véhicule chargé sur le plateau" })
end

--- Unload a vehicle from the tcguardow plateau
---@param tcguardow number|nil The tcguardow (auto-detect if nil)
function UnloadVehicleFromTcguardow(tcguardow)
    local playerPed = PlayerPedId()

    -- Find tcguardow if not provided
    if not tcguardow then
        tcguardow = GetClosestTcguardow(10.0)
    end

    if not tcguardow or not DoesEntityExist(tcguardow) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun plateau (tcguardow) à proximité" })
        return
    end

    local loadedVehicle = GetVehicleOnTcguardow(tcguardow)
    if not loadedVehicle then
        VFW.ShowNotification({ type = 'ORANGE', content = "Aucun véhicule sur le plateau" })
        return
    end

    -- Turn player to face the tcguardow
    TaskTurnPedToFaceEntity(playerPed, tcguardow, 1000)
    Wait(1000)

    -- Play animation
    local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
    end
    TaskPlayAnim(playerPed, animDict, "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Progress bar
    local success = VFW.Nui.ProgressBar("Déchargement du véhicule...", 5000)
    ClearPedTasks(playerPed)

    if not success then
        VFW.ShowNotification({ type = 'ROUGE', content = "Déchargement annulé" })
        return
    end

    if not DoesEntityExist(loadedVehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    -- Request control of the loaded vehicle so detach/teleport replicates to other clients
    if NetworkGetEntityIsNetworked(loadedVehicle) then
        NetworkRequestControlOfEntity(loadedVehicle)
        local tries = 0
        while not NetworkHasControlOfEntity(loadedVehicle) and tries < 20 do
            Wait(50)
            NetworkRequestControlOfEntity(loadedVehicle)
            tries = tries + 1
        end
    end

    -- Detach the vehicle
    DetachEntity(loadedVehicle, true, true)

    -- Place it on the ground behind the tcguardow
    local tcCoords = GetEntityCoords(tcguardow)
    local forward = GetEntityForwardVector(tcguardow)
    local dropPos = tcCoords - forward * 10.0
    local groundZ = tcCoords.z

    -- Get ground Z
    local found, z = GetGroundZFor_3dCoord(dropPos.x, dropPos.y, dropPos.z + 5.0, false)
    if found then
        groundZ = z
    end

    SetEntityCoords(loadedVehicle, dropPos.x, dropPos.y, groundZ + 0.5, false, false, false, false)
    SetEntityHeading(loadedVehicle, GetEntityHeading(tcguardow))
    PlaceObjectOnGroundProperly(loadedVehicle)
    SetVehicleOnGroundProperly(loadedVehicle)

    -- Sync via server
    if NetworkGetEntityIsNetworked(tcguardow) then
        local tcguardowNetId = NetworkGetNetworkIdFromEntity(tcguardow)
        TriggerServerEvent('core:DeleteVehAttachee', tcguardowNetId)
        VehAttachee[tcguardowNetId] = nil
    elseif NetworkGetEntityIsNetworked(loadedVehicle) then
        -- Fallback cleanup: walk the local VehAttachee table and remove any stale entry pointing to this vehicle
        local loadedNetId = NetworkGetNetworkIdFromEntity(loadedVehicle)
        for tcNetId, vehNetId in pairs(VehAttachee) do
            if vehNetId == loadedNetId then
                TriggerServerEvent('core:DeleteVehAttachee', tcNetId)
                VehAttachee[tcNetId] = nil
            end
        end
    end

    VFW.ShowNotification({ type = 'VERT', content = "Véhicule déchargé du plateau" })
end

-- ============================================
-- GUIZTOW TUTORIAL
-- ============================================
AddEventHandler("vfw:enteredVehicle", function(vehicle, plate, seat)
    if seat ~= -1 then return end
    if GetEntityModel(vehicle) ~= joaat("guiztow") then return end

    VFW.Tutorial.Start({
        id = "guiztow_tutorial",
        title = "Dépanneuse",
        skippable = true,
        steps = {
            {
                type = "info",
                title = "Bienvenue dans la dépanneuse",
                description = "Ce véhicule fonctionne comme la dépanneuse classique de GTA.\n\nAppuyez sur E pour continuer ou ECHAP pour passer.",
                icon = "truck",
            },
            {
                type = "info",
                title = "Accrocher un véhicule",
                description = "Approchez l'arrière de la dépanneuse d'un véhicule.\nReculez doucement jusqu'à ce que le crochet soit proche du véhicule cible.\n\nLe véhicule s'accrochera automatiquement quand il sera assez proche.",
                icon = "link",
            },
            {
                type = "info",
                title = "Soulever le véhicule",
                description = "Une fois accroché, maintenez la touche SHIFT pour soulever le véhicule avec le bras hydraulique.\n\nUtilisez CTRL pour le redescendre.",
                icon = "arrow-up",
            },
            {
                type = "info",
                title = "Transporter et décrocher",
                description = "Conduisez prudemment jusqu'à destination.\nPour décrocher le véhicule, appuyez sur la touche H (par défaut).\n\nCette touche est modifiable dans Paramètres > Config des touches > Véhicule > Phare siège spécial.\n\nAssurez-vous d'être à l'arrêt avant de décrocher.",
                icon = "check",
            },
        },
    })
end)

-- ============================================
-- TCGUARDOW TUTORIAL
-- ============================================
AddEventHandler("vfw:enteredVehicle", function(vehicle, plate, seat)
    if seat ~= -1 then return end
    if GetEntityModel(vehicle) ~= joaat("tcguardow") then return end

    VFW.Tutorial.Start({
        id = "tcguardow_tutorial",
        title = "Plateau Dépanneuse",
        skippable = true,
        steps = {
            {
                type = "info",
                title = "Bienvenue dans le plateau",
                description = "Ce véhicule est un plateau permettant de transporter des véhicules.\n\nAppuyez sur E pour continuer ou ECHAP pour passer.",
                icon = "truck",
            },
            {
                type = "info",
                title = "Charger un véhicule",
                description = "Pour charger un véhicule sur le plateau :\n\n1. Sortez du véhicule\n2. Approchez-vous du véhicule à charger\n3. Utilisez le menu job ou le menu contextuel\n4. Sélectionnez 'Charger sur le plateau'",
                icon = "package",
            },
            {
                type = "info",
                title = "Décharger un véhicule",
                description = "Pour décharger le véhicule :\n\n1. Arrêtez-vous et sortez du plateau\n2. Utilisez le menu job ou le menu contextuel\n3. Sélectionnez 'Décharger du plateau'\n\nLe véhicule sera déposé derrière le plateau.",
                icon = "check",
            },
        },
    })
end)
