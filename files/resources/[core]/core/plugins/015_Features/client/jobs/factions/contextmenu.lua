---@meta _
---@diagnostic disable: duplicate-doc-field

-- Ranger l'arme de la cible avant menottage
RegisterNetEvent('vfw:handcuff:holsterWeapon', function()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon and weapon ~= `WEAPON_UNARMED` then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        LastWeaponId = nil
    end
end)

-- ============================================
-- ESCORT SYSTEM (state global partagé entre F6 et context menu)
-- ============================================

VFW.isEscorting = false
VFW.escortedServerId = nil
VFW.escortedPed = nil

--- Démarrer une escorte
---@param targetServerId number Server ID de la cible
---@param targetPed number Ped handle de la cible
function VFW.Jobs.StartEscort(targetServerId, targetPed)
    if VFW.isEscorting then return false end

    VFW.isEscorting = true
    VFW.escortedServerId = targetServerId
    VFW.escortedPed = targetPed

    TriggerServerEvent("vfw:faction:escort:start", targetServerId)

    CreateThread(function()
        while VFW.isEscorting and VFW.escortedPed and DoesEntityExist(VFW.escortedPed) do
            Wait(250)
            if not VFW.isEscorting or not VFW.escortedPed or not DoesEntityExist(VFW.escortedPed) then
                return
            end
            DisableControlAction(0, 21, true) -- Sprint

            local myCoords = GetEntityCoords(PlayerPedId())
            local targetCoords = GetEntityCoords(VFW.escortedPed)

            if #(myCoords - targetCoords) > 5.0 then
                VFW.Jobs.StopEscort()
                VFW.ShowNotification({ type = 'ROUGE', content = "Escorte annulée - personne trop loin" })
                return
            end
        end
    end)

    return true
end

--- Arrêter l'escorte en cours
function VFW.Jobs.StopEscort()
    if not VFW.isEscorting then return end

    if VFW.escortedServerId then
        TriggerServerEvent("vfw:faction:escort:stop", VFW.escortedServerId)
    end

    VFW.isEscorting = false
    VFW.escortedServerId = nil
    VFW.escortedPed = nil
end

-- Handler côté cible : attach/detach le ped escorté au ped escorteur
RegisterNetEvent("core:escort:attached", function(isEscorted, escorterSource)
    local playerPed = PlayerPedId()

    if isEscorted then
        local escorterPed = escorterSource and GetPlayerPed(GetPlayerFromServerId(escorterSource))

        if escorterPed and DoesEntityExist(escorterPed) then
            AttachEntityToEntity(playerPed, escorterPed, 11816, 0.54, 0.44, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

            RequestAnimDict("mp_arresting")
            local waited = 0
            while not HasAnimDictLoaded("mp_arresting") and waited < 5000 do
                Wait(10)
                waited = waited + 10
            end

            if HasAnimDictLoaded("mp_arresting") then
                TaskPlayAnim(playerPed, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
            end
        end
    else
        DetachEntity(playerPed, true, false)
        ClearPedTasks(playerPed)
    end
end)

---Get VFW.Jobs.PatientIdentityCard
---@param entity any
---@return any
function VFW.Jobs.GetPatientIdentityCard(entity)
    if entity then
        local player = NetworkGetPlayerIndexFromPed(entity)
        local sID = GetPlayerServerId(player)
        local identity = TriggerServerCallback('core:server:jobs:GetPatientIdentity', sID)
        if not identity then
            return
        end

        return VFW.ShowNotification({
            type = 'JAUNE',
            duration = 10,
            content = "Nom : " .. identity.prenom .. "\nPrénom : " .. identity.nom .. "\nAge : " .. identity.age .. "\nSexe: " .. identity.sexe
        })
    end

    VFW.ShowNotification({ type = 'ROUGE', content = "Aucune personne à proximité" })
end

local vehicleThieft = nil

--- .Jobs.HookVehicle
---@param vehicle number|table Vehicle handle or object
---@return any
function VFW.Jobs.HookVehicle(vehicle)
    CreateThread(function()
        vehicleThieft = nil

        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        if lockStatus == 0 or lockStatus == 1 then
            VFW.ShowNotification({
                type = 'JAUNE',
                content = "Le véhicule est déjà déverrouillé."
            })
            return
        end

        local seat = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))

        for i = -1, seat - 2 do
            if not IsVehicleSeatFree(vehicle, i) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Il y a quelqu'un dans le véhicule."
                })
                return
            end
        end

        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        RequestAnimDict('missheistfbisetup1')

        while not HasAnimDictLoaded('missheistfbisetup1') do
            Wait(0)
        end

        TaskPlayAnim(PlayerPedId(), 'missheistfbisetup1' , 'hassle_intro_loop_f' ,8.0, -8.0, -1, 1, 0, false, false, false)

        local duration = VFW.Nui.ProgressBar("Crochetage en cours...", 10 * 1000)

        RemoveAnimDict("missheistfbisetup1")
        if duration then
            ClearPedTasks(VFW.PlayerData.ped)
            NetworkRequestControlOfEntity(vehicle)
            SetVehicleDoorsLocked(vehicle, 0)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
            SetVehicleUndriveable(vehicle, true)
            VFW.ShowNotification({
                type = 'JOB',
                logo = VFW.CDN.Get("entreprise/" .. VFW.PlayerData.job.name .. ".png"),
                title = VFW.PlayerData.job.label,
                content = "Vous avez crocheté le véhicule"
            })
        end
    end)
end

--- .Jobs.InfoVeh
---@param vehicle number|table Vehicle handle or object
---@return any
function VFW.Jobs.InfoVeh(vehicle)
    return VFW.ShowNotification({
        type = 'JAUNE',
        duration = 8,
        content = "Véhicule : ~s".. GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) .. "~c\n"
                .. "Plaque : ~s".. VFW.Game.GetPlate(vehicle) .. "~c\n"
                .. "Carrosserie : ~s".. math.round(GetVehicleBodyHealth(vehicle) / 10, 2) .."~c%\n"
                .. "État moteur : ~s".. math.round(GetVehicleEngineHealth(vehicle) / 10, 2) .."~c%\n"
                .. "Essence : ~s".. math.round(VehicleFuel and VehicleFuel.Get(vehicle) or GetVehicleFuelLevel(vehicle), 2) .."~c%"
    })
end

---Get VFW.Jobs.VehiclePlate
---@param vehicle number|table Vehicle handle or object
---@return any
function VFW.Jobs.GetVehiclePlate(vehicle)
    local plate = VFW.Game.GetPlate(vehicle)
    if not plate then
        return
    end

    local firstname, lastname = TriggerServerCallback('core:jobs:server:getVeh', plate)
    if not firstname or not lastname then
        return
    end

    return VFW.ShowNotification({
        type = 'JAUNE',
        duration = 8,
        content = "Propriétaire : ~s~" .. firstname .. " " .. lastname
    })
end

---Set VFW.Jobs.VehicleInFourriere
---@param vehicle number|table Vehicle handle or object
function VFW.Jobs.SetVehicleInFourriere(vehicle)
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
    local duration = VFW.Nui.ProgressBar("Mise en fourrière...", 7 * 1000, true)
    FreezeEntityPosition(ped, false)

    ClearPedTasksImmediately(ped)
    if DoesEntityExist(prop) then
        DeleteObject(prop)
    end
    SetModelAsNoLongerNeeded(propModel)
    RemoveAnimDict(dict)

    if duration then
        local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
        local netId = VehToNet(vehicle)
        TriggerServerEvent("vfw:vehicle:keyTemporarly:remove", nil, plate)
        TriggerServerEvent("vfw:mechanic:impound", plate)
        TriggerServerEvent("core:deletesyncItem", netId)
    end
end

--- PlayAnim
---@param animDict any
---@param animName string
---@param duration any
local function PlayAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end

    TaskPlayAnim(VFW.PlayerData.ped, animDict, animName, 8.0, -8.0, duration, 0, 0, false, false, false)
    Wait(duration)
    RemoveAnimDict(animDict)
end

--- .Jobs.HealthPatient
---@param closestPlayer number|table Player ID or player object
function VFW.Jobs.HealthPatient(closestPlayer)
    local globalTarget =  GetPlayerServerId(NetworkGetPlayerIndexFromPed(closestPlayer))
    local health = GetEntityHealth(closestPlayer)
    local haveKitHealth = TriggerServerCallback("core:jobs:server:haveKit", "health")

    if health > 0 then
        if haveKitHealth then
            PlayAnim("amb@medic@standing@kneel@base", "base", 5000)
            ClearPedTasks(VFW.PlayerData.ped)
            TriggerServerEvent('core:jobs:server:HealthPlayer', globalTarget)
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas de bandage"
            })
        end
    end
end

--- .Jobs.RevivePatient
---@param closestPlayer number|table Player ID or player object
function VFW.Jobs.RevivePatient(closestPlayer)
    local players = NetworkGetPlayerIndexFromPed(closestPlayer)
    local playerheading = GetEntityHeading(VFW.PlayerData.ped)
    local coords = GetEntityCoords(VFW.PlayerData.ped)
    local playerlocation = GetEntityForwardVector(VFW.PlayerData.ped)
    local haveKitRevive = TriggerServerCallback("core:jobs:server:haveKit", "revive")

    if haveKitRevive then
        TriggerServerEvent('core:jobs:server:RevivePlayer', GetPlayerServerId(players))
        TriggerServerEvent("core:jobs:server:reviveanimrevived", GetPlayerServerId(players), playerheading, coords, playerlocation)
    else
        VFW.ShowNotification({
            type = 'JOB',
            logo = VFW.CDN.Get("job/sams/sams_logo.png"),
            title = "SAMS",
            subtitle = "Equipement manquant",
            content = "Vous n'avez pas de kit de reanimation."
        })
    end
end

--- .Jobs.IdentificationComa
---@param entity any
function VFW.Jobs.IdentificationComa(entity)
    local exist, lastBone = GetPedLastDamageBone(entity)
    local cause, what_cause = GetPedCauseOfDeath(entity), GetPedSourceOfDeath(entity)

    if IsEntityAPed(what_cause) then
        what_cause = "avoir des traces de combat"
    elseif IsEntityAVehicle(what_cause) then
        what_cause = "être écrasé par un véhicule"
    elseif IsEntityAnObject(what_cause) then
        what_cause = "s'être pris un objet"
    end

    what_cause = type(what_cause) == "string" and what_cause or "Non-Identifiée"

    local weaponInfo = ""

    if IsWeaponValid(cause) then
        local weaponHash = cause
        cause = Death.GetDeathType[GetWeaponDamageType(cause)] or "Non-Identifiée"

        if Death.deatCause[weaponHash] then
            local deathType, weaponName = Death.deatCause[weaponHash][1], Death.deatCause[weaponHash][2]
            weaponInfo = string.format(" (arme: %s - type: %s)", weaponName, deathType)
        else
            weaponInfo = " (arme non identifiée)"
        end
    elseif IsModelInCdimage(cause) then
        cause = "Véhicule"
        weaponInfo = " (cause: collision avec véhicule)"
    end

    cause = type(cause) == "string" and cause or "Mêlée"
    local boneName = "Dos"

    if exist and lastBone then
        for k, v in pairs(Death.GetBonesType) do
            if Death:GetValueWithTable(v, lastBone) then
                boneName = k
                break
            end
        end
    end

    VFW.ShowNotification({
        type = 'VERT',
        duration = 15,
        content = string.format("la personne semble %s au niveau du %s part %s", what_cause, string.lower(boneName), weaponInfo),
    })
end

