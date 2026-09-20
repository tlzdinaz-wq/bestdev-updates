local runActive, runId = false, nil
local blip, doorCircle, trunkCircle, trunkFollowThread
local lastTrunkPos
local configData = nil

local TRUNK_COOLDOWN_MS = 1200
local lastTrunkUse = 0
local currentDeliveryPoint = nil
local currentDeliveryHeading = 0.0
local deliveryMarkerThread = nil

local PlayerData


RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    VFW.ShowNotification({ type = t or "JAUNE", content = msg })
end

local function stopCarryingPizzaAnimation()
    local ped = PlayerPedId()

    for i = 0, GetNumberOfPedPropDrawables(ped, 0) do
        local obj = GetPedPropIndex(ped, i)
        if obj ~= -1 then
            ClearPedProp(ped, i)
        end
    end

    local count = 0
    for i = 0, 255 do
        local obj = GetClosestObjectOfType(GetEntityCoords(ped), 3.0, GetHashKey("prop_pizza_box_02"), false, false, false)
        if obj and obj ~= 0 and IsEntityAttachedToEntity(obj, ped) then
            DetachEntity(obj, true, true)
            DeleteObject(obj)
            DeleteEntity(obj)
            count = count + 1
            if count > 5 then
                break
            end
        else
            break
        end
    end

    ExecuteCommand("e c")
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

local function removeCircle(c)
    if c then
        RemoveInteractionCircle(c)
    end
end
local function removeBlip()
    if blip then
        RemoveBlip(blip)
        blip = nil
    end
end

local function trunkOnCooldown()
    return (GetGameTimer() - (lastTrunkUse or 0)) < TRUNK_COOLDOWN_MS
end
local function markTrunkUsed()
    lastTrunkUse = GetGameTimer()
end

local function getPlayerVehicle()
    local netId = TriggerServerCallback("interim:pizza:getVehicleNetId")
    if not netId then
        return nil
    end
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then
        return ent
    end
    return nil
end

function StartPizzaDelivery()
    if runActive then
        notify("ROUGE", "Tournée déjà en cours.")
        return false
    end

    local veh = getPlayerVehicle()
    if not veh or not DoesEntityExist(veh) then
        notify("ROUGE", "Vous devez sortir votre véhicule de livraison avant de commencer.")
        return false
    end

    local stock = TriggerServerCallback("interim:pizza:getStockCount") or 0
    if stock < 1 then
        notify("ROUGE", "Aucune pizza dans le coffre.")
        return false
    end

    local res = TriggerServerCallback("interim:pizza:startDeliveryRun", stock)
    if not res or not res.runId then
        notify("ROUGE", "Impossible de démarrer la tournée.")
        return false
    end

    runActive, runId = true, res.runId
    notify("VERT", ("Tournée démarrée (%d étapes)."):format(res.total or 0))

    if res.next then
        removeBlip()
        blip = AddBlipForCoord(res.next.x + 0.0, res.next.y + 0.0, res.next.z + 0.0)
        SetBlipScale(blip, 0.5)
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5)
        ensureDoorCircle(res.next)
    end

    ensureTrunkCircleFollow()
    return true
end

function IsDeliveryActive()
    return runActive or false
end

local ensureDeliveryMarker

local function createDoorCircle(currentDeliveryPoint, cfg)
    local npc = nil
    local knocking = false  -- true pendant les 2s d'attente avant spawn du NPC
    local doorColor = (configData and configData.interactionCircle and configData.interactionCircle.doorColor)
            or { r = 255, g = 140, b = 0, a = 120 }

    doorCircle = CreateInteractionCircle(
            currentDeliveryPoint,
            1.5,
            doorColor,
            "Appuyez sur ~INPUT_CONTEXT~ pour toquer à la porte",
            function()
                if npc and DoesEntityExist(npc) then
                    notify("JAUNE", "Le client est déjà à la porte, donnez-lui la pizza.")
                    return
                end
                if knocking then
                    notify("ROUGE", "Vous venez de toquer, attendez un instant.")
                    return
                end
                knocking = true
                notify("JAUNE", "Vous toquez à la porte...")

                exports.xsound:PlayUrlPos("door_knock", "https://cdn.pixabay.com/download/audio/2025/06/02/audio_25951885d0.mp3?filename=fast-knocking-on-door-352704.mp3", 0.3, currentDeliveryPoint, false)
                exports.xsound:Distance("door_knock", 10.0)

                SetTimeout(2000, function()
                    knocking = false
                    if exports.xsound:soundExists("door_knock") then
                        exports.xsound:Destroy("door_knock")
                    end

                    local distance = 0.3
                    local headingRad = math.rad(currentDeliveryHeading)
                    local offsetX = math.sin(headingRad) * distance
                    local offsetY = math.cos(headingRad) * distance
                    local pedPos = currentDeliveryPoint - vector3(offsetX, offsetY, 0.0)

                    local pedModel = cfg.possibleNPCS[math.random(#cfg.possibleNPCS)]
                    local pedHeading = currentDeliveryHeading

                    npc = SpawnNpcsInterimJobs(pedModel, pedPos, pedHeading, "Appuyez sur ~INPUT_CONTEXT~ pour donner la pizza", function()
                        if not isCarryingPizza then
                            notify("ROUGE", "Tu dois avoir une pizza dans les mains.")
                            return
                        end

                        local res = TriggerServerCallback("interim:pizza:validateDeliveryAtDoor", runId)
                        if not res then
                            notify("ROUGE", "Le client n'est pas prêt.")
                            return
                        end

                        isCarryingPizza = false
                        ExecuteCommand("cancelemote")
                        notify("VERT", "Vous avez donné la pizza au client.")

                        if res.done then
                            notify("VERT", ("Tournée terminée (%d/%d)."):format(res.delivered, res.total))
                            cleanupRun()

                            local cfg = TriggerServerCallback("interim:pizza:getConfig")
                            if cfg and cfg.PositionsPizza and cfg.PositionsPizza.startplace then
                                local startPos = cfg.PositionsPizza.startplace
                                SetNewWaypoint(startPos.x, startPos.y)
                            end
                        else
                            notify("VERT", ("Livraison %d/%d"):format(res.delivered, res.total))
                            if res.next then
                                removeBlip()
                                blip = AddBlipForCoord(res.next.x, res.next.y, res.next.z)
                                SetBlipScale(blip, 0.5)
                                SetBlipRoute(blip, true)
                                SetBlipRouteColour(blip, 5)
                                ensureDoorCircle(res.next)
                            end
                        end

                        CreateThread(function()
                            Wait(5000)
                            if npc and DoesEntityExist(npc) then
                                local alpha = 255
                                while alpha > 0 do
                                    alpha = alpha - 15
                                    if alpha < 0 then
                                        alpha = 0
                                    end
                                    if DoesEntityExist(npc) then
                                        SetEntityAlpha(npc, alpha, false)
                                    end
                                    Wait(30)
                                end
                                if DoesEntityExist(npc) then
                                    DeleteEntity(npc)
                                    npc = nil
                                end
                            end
                        end)
                    end)

                    if npc and DoesEntityExist(npc) then
                        SetEntityAlpha(npc, 0, false)
                        CreateThread(function()
                            local alpha = 0
                            while alpha < 255 do
                                alpha = alpha + 15
                                if alpha > 255 then
                                    alpha = 255
                                end
                                if DoesEntityExist(npc) then
                                    SetEntityAlpha(npc, alpha, false)
                                end
                                Wait(30)
                            end
                            if DoesEntityExist(npc) then
                                ResetEntityAlpha(npc)
                            end
                        end)
                    end

                    removeCircle(doorCircle)
                    doorCircle = nil
                end)
            end
    )
end

function ensureDoorCircle(nextPoint)
    removeCircle(doorCircle)
    doorCircle = nil

    if not runActive or not nextPoint then
        return
    end

    currentDeliveryPoint = vector3(nextPoint.x, nextPoint.y, nextPoint.z)
    currentDeliveryHeading = nextPoint.w or 0.0
    local cfg = TriggerServerCallback("interim:pizza:getConfig")

    if not configData then
        configData = TriggerServerCallback("interim:pizza:getConfig")
    end
    createDoorCircle(currentDeliveryPoint, cfg)
    ensureDeliveryMarker()
end

ensureDeliveryMarker = function()
    if deliveryMarkerThread then
        return
    end
    deliveryMarkerThread = true

    CreateThread(function()
        while runActive and currentDeliveryPoint do
            local ped = PlayerPedId()
            local pPos = GetEntityCoords(ped)
            local dist = #(pPos - currentDeliveryPoint)

            if dist < 50.0 then
                DrawMarker(
                        23,
                        currentDeliveryPoint.x, currentDeliveryPoint.y, currentDeliveryPoint.z + 0.01,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.4, 0.4, 0.4,
                        255, 140, 0, 80,
                        false, true, 2, false, nil, nil, false
                )
                Wait(0)
            else
                Wait(200)
            end
        end
        deliveryMarkerThread = nil
    end)
end

function ensureTrunkCircleFollow()


    removeCircle(trunkCircle);
    trunkCircle = nil
    if not runActive then
        return
    end

    local function createTrunkCircle(pos)
        local trunkColor = (configData and configData.interactionCircle and configData.interactionCircle.trunkColor)
                or { r = 255, g = 215, b = 0, a = 120 } -- Fallback or

        trunkCircle = CreateInteractionCircle(
                pos,
                1.5,
                trunkColor,
                "Appuyez sur ~INPUT_CONTEXT~ pour accéder au coffre",
                function()
                    if trunkOnCooldown() then
                        notify("JAUNE", "Patiente une seconde…")
                        return
                    end

                    local ped = PlayerPedId()
                    local veh = getPlayerVehicle()
                    if not veh or not DoesEntityExist(veh) then
                        return
                    end
                    if IsPedInAnyVehicle(ped, false) then
                        return
                    end
                    if GetEntitySpeed(veh) > 0.3 then
                        return
                    end

                    if isCarryingPizza then
                        local success = TriggerServerCallback("interim:pizza:depositToTrunk")
                        if success then
                            isCarryingPizza = false
                            ExecuteCommand("cancelemote")
                            notify("VERT", "Pizza déposée dans le coffre.")
                            markTrunkUsed()
                        else
                            notify("ROUGE", "Impossible de déposer la pizza.")
                        end
                    else
                        local success = TriggerServerCallback("interim:pizza:takeFromTrunk")
                        if success then
                            isCarryingPizza = true
                            ExecuteCommand("e c")
                            EmoteCommandStart("carrypizza", PlayerPedId())
                            notify("VERT", "Pizza prise dans le coffre.")
                            markTrunkUsed()
                        else
                            notify("ROUGE", "Coffre vide ou trop loin.")
                        end
                    end
                end
        )
    end

    local function placeTrunkCircleAt(pos)
        removeCircle(trunkCircle);
        trunkCircle = nil
        if not configData then
            configData = TriggerServerCallback("interim:pizza:getConfig")
        end
        createTrunkCircle(pos)
    end

    if trunkFollowThread then
        return
    end
    trunkFollowThread = true
    CreateThread(function()
        local hadCircle = false
        while runActive do
            local ped = PlayerPedId()
            local veh = getPlayerVehicle()

            local canShow = false
            local trunkPos = nil
            if veh and DoesEntityExist(veh) then
                if not IsPedInAnyVehicle(ped, false) and GetEntitySpeed(veh) <= 0.3 then
                    trunkPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -0.8, 0.0)

                    if currentDeliveryPoint then
                        local pPos = GetEntityCoords(ped)
                        local dist = #(pPos - currentDeliveryPoint)
                        if dist < 30.0 then
                            canShow = true
                        end
                    else
                        canShow = false
                    end
                end
            end

            if canShow and not trunkCircle then
                placeTrunkCircleAt(trunkPos)
                lastTrunkPos = trunkPos
                hadCircle = true
            elseif (not canShow) and trunkCircle then
                removeCircle(trunkCircle);
                trunkCircle = nil
                hadCircle = false
            elseif canShow and trunkCircle and lastTrunkPos and trunkPos and #(trunkPos - lastTrunkPos) > 0.3 then
                placeTrunkCircleAt(trunkPos)
                lastTrunkPos = trunkPos
            end

            if canShow and trunkPos then
                Wait(0)
            else
                Wait(100)
            end
        end
        trunkFollowThread = nil
    end)
end

function cleanupRun()
    runActive, runId = false, nil
    lastTrunkPos = nil
    trunkFollowThread = nil
    currentDeliveryPoint = nil
    currentDeliveryHeading = 0.0
    deliveryMarkerThread = nil

    if blip then
        SetBlipRoute(blip, false)
        RemoveBlip(blip)
        blip = nil
    end

    removeCircle(doorCircle);
    doorCircle = nil
    removeCircle(trunkCircle);
    trunkCircle = nil
end

local function safeStopCarryOnCancel()
    if isCarryingPizza then
        isCarryingPizza = false
        ExecuteCommand("cancelemote")
    end
end

function CancelPizzaDelivery(reason)
    if not runActive then
        notify("JAUNE", "Aucune tournée en cours.")
        return false
    end

    local ok = TriggerServerCallback("interim:pizza:cancelRun", tostring(reason or "user_cancel"))
    if not ok then
        notify("ROUGE", "Annulation refusée : délai d'attente non écoulé ou état incorrect.")
        return false
    end

    safeStopCarryOnCancel()
    cleanupRun()
    TriggerServerEvent("interim:firstwp:request")
    return true
end

RegisterNetEvent("interim:pizza:client:cancelled", function(payload)
    safeStopCarryOnCancel()
    cleanupRun()

    if payload and payload.start then
        SetNewWaypoint(payload.start.x, payload.start.y)
    else
        TriggerServerEvent("interim:firstwp:request")
    end

    if payload and payload.msg then
        notify("JAUNE", payload.msg)
    else
        notify("JAUNE", "Tournée annulée par le serveur.")
    end
end)
