---@meta _
---@diagnostic disable: duplicate-doc-field

local GOUV_IMG = VFW.CDN.Get("entreprise/gouvernement.png")

local function gouvNotif(subtitle, content)
    VFW.ShowNotification({ type = "JOB", title = "Gouvernement", subtitle = subtitle, image = GOUV_IMG, content = content })
end

local function RequestAnimDictTimeout(dict, timeout)
    RequestAnimDict(dict)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited < (timeout or 5000) do
        Wait(10)
        waited = waited + 10
    end
    return HasAnimDictLoaded(dict)
end

RegisterNetEvent("core:loadjob:gouvernement", function()
end)

-- Security actions menu is now handled in modules/society/client/menu.lua

--- Retourne l'index de porte correspondant à un siège
--- Pour les véhicules 2 portes, les sièges arrière utilisent les portes avant
local function GetDoorForSeat(vehicle, seat)
    if seat == -1 then return 0 end
    local doorIndex = seat + 1
    local numDoors = GetNumberOfVehicleDoors(vehicle)
    if numDoors <= 2 and doorIndex >= 2 then
        doorIndex = doorIndex - 2
    end
    return doorIndex
end

--- Retourne l'index du siège occupé par un ped dans un véhicule
local function GetPedSeatIndex(ped, vehicle)
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    for i = -1, maxSeats - 1 do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            return i
        end
    end
    return -1
end

--- Détermine le côté du véhicule où se trouve un ped (gauche = true, droite = false)
local function IsOnLeftSide(vehicle, ped)
    local vehPos = GetEntityCoords(vehicle)
    local pedPos = GetEntityCoords(ped)
    -- Utiliser GetEntityRightVector pour obtenir le vrai vecteur droite du véhicule
    local _, right, _ = GetEntityMatrix(vehicle)
    local dx = pedPos.x - vehPos.x
    local dy = pedPos.y - vehPos.y
    local dot = dx * right.x + dy * right.y
    return dot < 0 -- négatif = côté gauche
end

-- Put in vehicle event (received by the TARGET player)
RegisterNetEvent("gouvernement:putInVehicle", function(vehicleNetId, agentServerId)
    local vehicle = NetToVeh(vehicleNetId)

    -- Wait for entity to stream in if needed
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        local timeout = 0
        while (not vehicle or vehicle == 0 or not DoesEntityExist(vehicle)) and timeout < 10 do
            Wait(100)
            vehicle = NetToVeh(vehicleNetId)
            timeout = timeout + 1
        end
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    end

    local playerPed = PlayerPedId()

    -- Clear tasks and detach to avoid conflicts with handcuff animation
    ClearPedTasks(playerPed)
    DetachEntity(playerPed, true, false)
    Wait(100)

    -- Déterminer de quel côté l'agent se trouve
    local agentPed = GetPlayerPed(GetPlayerFromServerId(agentServerId))
    local agentOnLeft = agentPed and DoesEntityExist(agentPed) and IsOnLeftSide(vehicle, agentPed)

    -- Find a free back seat, prioritizing the agent's side
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    local seat = nil

    if maxSeats >= 3 then
        -- Siège 1 = arrière gauche, Siège 2 = arrière droit
        if agentOnLeft then
            -- Agent à gauche → prioriser siège 1 (gauche), puis 2 (droite), puis autres
            if IsVehicleSeatFree(vehicle, 1) then seat = 1
            elseif IsVehicleSeatFree(vehicle, 2) then seat = 2 end
        else
            -- Agent à droite → prioriser siège 2 (droite), puis 1 (gauche), puis autres
            if IsVehicleSeatFree(vehicle, 2) then seat = 2
            elseif IsVehicleSeatFree(vehicle, 1) then seat = 1 end
        end
        -- Sièges arrière supplémentaires (3+)
        if not seat then
            for i = 3, maxSeats - 1 do
                if IsVehicleSeatFree(vehicle, i) then
                    seat = i
                    break
                end
            end
        end
    else
        -- Véhicule sans sièges arrière séparés gauche/droite
        for i = 1, maxSeats - 1 do
            if IsVehicleSeatFree(vehicle, i) then
                seat = i
                break
            end
        end
    end

    -- Fallback: front passenger
    if not seat and IsVehicleSeatFree(vehicle, 0) then
        seat = 0
    end

    if seat then
        -- Wait for agent to open the door
        Wait(900)

        -- Placer dans le véhicule
        SetPedIntoVehicle(playerPed, vehicle, seat)
    else
        gouvNotif("Véhicule", "Aucune place disponible dans le véhicule.")
    end
end)

-- Door animation event (received by the AGENT who owns the vehicle)
RegisterNetEvent("gouvernement:putInVehicle:door", function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local agentPed = PlayerPedId()
    local agentOnLeft = IsOnLeftSide(vehicle, agentPed)

    -- Same seat logic as target to open the correct door
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    local seat = nil

    if maxSeats >= 3 then
        if agentOnLeft then
            if IsVehicleSeatFree(vehicle, 1) then seat = 1
            elseif IsVehicleSeatFree(vehicle, 2) then seat = 2 end
        else
            if IsVehicleSeatFree(vehicle, 2) then seat = 2
            elseif IsVehicleSeatFree(vehicle, 1) then seat = 1 end
        end
        if not seat then
            for i = 3, maxSeats - 1 do
                if IsVehicleSeatFree(vehicle, i) then
                    seat = i
                    break
                end
            end
        end
    else
        for i = 1, maxSeats - 1 do
            if IsVehicleSeatFree(vehicle, i) then
                seat = i
                break
            end
        end
    end

    if not seat and IsVehicleSeatFree(vehicle, 0) then
        seat = 0
    end

    if seat then
        local doorIndex = GetDoorForSeat(vehicle, seat)
        SetVehicleDoorOpen(vehicle, doorIndex, false, false)
        -- Keep door open long enough for target to enter (900ms wait + seat animation)
        Wait(2500)
        SetVehicleDoorShut(vehicle, doorIndex, false)
    end
end)

-- Remove from vehicle event (received by the TARGET player)
RegisterNetEvent("gouvernement:removeFromVehicle", function(agentServerId)
    local playerPed = PlayerPedId()

    if not IsPedInAnyVehicle(playerPed, false) then return end

    local vehicle = GetVehiclePedIsIn(playerPed, false)

    -- Wait for agent to open the door
    Wait(700)

    -- Sortir du véhicule
    ClearPedTasks(playerPed)
    TaskLeaveVehicle(playerPed, vehicle, 16)
    Wait(800)

    -- Attacher en escorte à l'agent
    local agentPed = agentServerId and GetPlayerPed(GetPlayerFromServerId(agentServerId))
    if agentPed and DoesEntityExist(agentPed) then
        AttachEntityToEntity(playerPed, agentPed, 11816, 0.54, 0.44, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        if RequestAnimDictTimeout("mp_arresting", 5000) then
            TaskPlayAnim(playerPed, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end
end)

-- Door animation for remove (received by the AGENT)
RegisterNetEvent("gouvernement:removeFromVehicle:door", function(targetServerId)
    local targetPlayerId = GetPlayerFromServerId(targetServerId)
    if not targetPlayerId then return end

    local targetPed = GetPlayerPed(targetPlayerId)
    if not targetPed or not DoesEntityExist(targetPed) then return end
    if not IsPedInAnyVehicle(targetPed, false) then return end

    local vehicle = GetVehiclePedIsIn(targetPed, false)
    local seat = GetPedSeatIndex(targetPed, vehicle)
    local doorIndex = GetDoorForSeat(vehicle, seat)

    SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    Wait(2000)
    SetVehicleDoorShut(vehicle, doorIndex, false)
end)

-- Search animation received by the TARGET (non-cuffed)
RegisterNetEvent("gouvernement:clearSearchAnim", function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
end)

-- Show search consent popup to the target
local searchConsentOrigin = "gouvernement"

RegisterNetEvent("gouvernement:showSearchConsent", function(agentName, origin)
    searchConsentOrigin = origin or "gouvernement"

    -- Close all open UIs before showing the popup
    VFW.CloseInventory()
    VFW.ForceClosePhone()

    SendNUIMessage({
        action = "nui:searchConsent:show",
        data = { agentName = agentName }
    })
    VFW.Nui.Focus(true, false)
end)

-- NUI callback for search consent response
RegisterNUICallback("searchConsent:respond", function(data, cb)
    VFW.Nui.Focus(false)
    local event = searchConsentOrigin == "police"
        and "police:searchConsentResponse"
        or "gouvernement:searchConsentResponse"
    TriggerServerEvent(event, data.accepted)
    searchConsentOrigin = "gouvernement"
    cb("ok")
end)

-- Dismiss search consent popup (e.g. agent disconnected)
RegisterNetEvent("gouvernement:dismissSearchConsent", function()
    SendNUIMessage({ action = "nui:searchConsent:hide" })
    VFW.Nui.Focus(false)
end)

-- Freeze target for search (received by the TARGET when consent is accepted)
RegisterNetEvent("gouvernement:freezeForSearch", function(agentServerId)
    local playerPed = PlayerPedId()
    local agentPed = agentServerId and GetPlayerPed(GetPlayerFromServerId(agentServerId))

    -- Face the agent
    if agentPed and DoesEntityExist(agentPed) then
        local agentCoords = GetEntityCoords(agentPed)
        local myCoords = GetEntityCoords(playerPed)
        local heading = GetHeadingFromVector_2d(agentCoords.x - myCoords.x, agentCoords.y - myCoords.y)
        SetEntityHeading(playerPed, heading)
    end

    -- Freeze + play search animation
    FreezeEntityPosition(playerPed, true)

    if RequestAnimDictTimeout("missfam5_yoga", 5000) then
        TaskPlayAnim(playerPed, "missfam5_yoga", "a2_pose", 8.0, -8.0, -1, 49, 0, false, false, false)
    end
end)

RegisterNetEvent("gouvernement:playSearchAnim", function(agentServerId)
    local playerPed = PlayerPedId()
    local agentPed = agentServerId and GetPlayerPed(GetPlayerFromServerId(agentServerId))

    if agentPed and DoesEntityExist(agentPed) then
        local agentCoords = GetEntityCoords(agentPed)
        local myCoords = GetEntityCoords(playerPed)
        local heading = GetHeadingFromVector_2d(agentCoords.x - myCoords.x, agentCoords.y - myCoords.y)
        SetEntityHeading(playerPed, heading)
    end

    if RequestAnimDictTimeout("missfam5_yoga", 5000) then
        TaskPlayAnim(playerPed, "missfam5_yoga", "a2_pose", 8.0, -8.0, -1, 49, 0, false, false, false)
    end
end)

-- Search event
RegisterNetEvent("gouvernement:startSearch", function(targetId, isCuffed, targetName)
    if isCuffed then
        -- Cible menottée : fouille directe sans animation
        -- On envoie directement à core:sendtext (bypass /me qui préfixe "La personne ")
        -- Nom RP retiré : on reste anonyme côté agent
        TriggerServerEvent("core:sendtext", "L'agent fouille l'individu")
        VFW.OpenShearchGouv(targetId)
    else
        -- Cible non menottée : animation duo puis ouverture inventaire
        local targetPlayerId = GetPlayerFromServerId(targetId)
        local playerPed = PlayerPedId()

        if not targetPlayerId then
            VFW.OpenShearchGouv(targetId)
            return
        end

        local targetPed = GetPlayerPed(targetPlayerId)

        if not targetPed or not DoesEntityExist(targetPed) then
            VFW.OpenShearchGouv(targetId)
            return
        end

        -- Positionner face à face
        local myCoords = GetEntityCoords(playerPed)
        local targetCoords = GetEntityCoords(targetPed)
        local heading = GetHeadingFromVector_2d(targetCoords.x - myCoords.x, targetCoords.y - myCoords.y)
        SetEntityHeading(playerPed, heading)

        -- Freeze l'agent pendant la fouille
        FreezeEntityPosition(playerPed, true)

        -- Jouer l'animation de fouille sur l'agent
        if RequestAnimDictTimeout("custom@police", 5000) then
            TaskPlayAnim(playerPed, "custom@police", "police", 8.0, -8.0, -1, 49, 0, false, false, false)
        end

        -- Ouvrir l'inventaire après un court délai
        Wait(1500)
        VFW.OpenShearchGouv(targetId)

        -- Wait for inventory to close, then unfreeze agent and clear target anim
        CreateThread(function()
            while VFW.StateInventory() do
                Wait(200)
            end
            ClearPedTasks(PlayerPedId())
            FreezeEntityPosition(PlayerPedId(), false)
            TriggerServerEvent("gouvernement:searchDone", targetId)
        end)
    end
end)
