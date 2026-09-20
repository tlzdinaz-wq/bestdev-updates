local UWU_CAFE_LOGO = VFW.CDN.Get("entreprise/uwucafe.png")
local deliveryActive = false
local deliveryJobName = nil
local deliveryClientData = nil
local deliveryOrderItems = nil
local deliveryReward = nil
local deliveryDelivered = 0
local deliveryNpc = nil
local deliveryNpcData = nil
local deliveryBlip = nil
local deliveryVehicle = nil
local deliveryOutOfVehicleTime = nil
local isInConversation = false
local conversationCamera = nil
local lastInteraction = 0

local function CanInteract()
    local now = GetGameTimer()
    if now - lastInteraction < 1000 then return false end
    lastInteraction = now
    return true
end

local function CreateDeliveryBlip(coords, npcName)
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(deliveryBlip, 480)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.5)
    SetBlipColour(deliveryBlip, 1)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    local blipName = (npcName or "Client") .. " - Livraison UwU Cafe"
    AddTextComponentString(blipName)
    EndTextCommandSetBlipName(deliveryBlip)
end

local function RemoveDeliveryBlip()
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
end

local function EndConversation()
    isInConversation = false

    SetEntityVisible(PlayerPedId(), true, false)

    if conversationCamera then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(conversationCamera, false)
        DestroyCam(conversationCamera, false)
        conversationCamera = nil
    end

    SendNUIMessage({
        action = "uwu_cafe:delivery:closeConversation"
    })
    VFW.Nui.Focus(false)
end

local function RemoveDeliveryNpc()
    if isInConversation then
        EndConversation()
    end

    if deliveryNpc and DoesEntityExist(deliveryNpc) then
        DeleteEntity(deliveryNpc)
        deliveryNpc = nil
    end
    deliveryNpcData = nil
end

local function ShowDeliveryOrder()
    if not deliveryActive or not deliveryOrderItems then return end
    local name = (deliveryClientData and deliveryClientData.npcName) or (deliveryNpcData and deliveryNpcData.name) or "Client"
    SendNUIMessage({
        action = "delivery:showOrder",
        data = {
            jobLogo = UWU_CAFE_LOGO,
            jobLabel = "UWU Cafe",
            npcName = name,
            orderItems = deliveryOrderItems,
            reward = deliveryReward or 0
        }
    })
end

local function CleanupDelivery()
    RemoveDeliveryBlip()
    RemoveDeliveryNpc()
    SendNUIMessage({ action = "delivery:hideOrder" })
    deliveryActive = false
    deliveryJobName = nil
    deliveryClientData = nil
    deliveryOrderItems = nil
    deliveryReward = nil
    deliveryDelivered = 0
    deliveryVehicle = nil
    deliveryOutOfVehicleTime = nil
end

local function SpawnDeliveryNpc(clientData)
    if deliveryNpc and DoesEntityExist(deliveryNpc) then
        return
    end

    local defaultModel = GetHashKey(UwuCafeConfig.DeliveryDefaultModel)
    local modelName = clientData.npcModel or UwuCafeConfig.DeliveryDefaultModel
    local model = GetHashKey(modelName)

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        model = defaultModel
    end

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 500 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) and model ~= defaultModel and IsModelInCdimage(defaultModel) then
        model = defaultModel
        RequestModel(model)
        timeout = 0
        while not HasModelLoaded(model) and timeout < 500 do
            Wait(10)
            timeout = timeout + 1
        end
    end

    if not HasModelLoaded(model) then
        return
    end

    local heading = clientData.heading or 0.0
    local ped = CreatePed(4, model, clientData.x, clientData.y, clientData.z - 1.0, heading, false, true)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    deliveryNpc = ped
    SetEntityAsMissionEntity(deliveryNpc, true, true)
    SetEntityInvincible(deliveryNpc, true)
    SetBlockingOfNonTemporaryEvents(deliveryNpc, true)
    FreezeEntityPosition(deliveryNpc, true)
    TaskStartScenarioInPlace(deliveryNpc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    deliveryNpcData = {
        name = clientData.npcName or "Client",
        coords = vector3(clientData.x, clientData.y, clientData.z)
    }
end

local function IsPlayerInFrontOfNpc(npc)
    if not npc or not DoesEntityExist(npc) then return false end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local npcCoords = GetEntityCoords(npc)
    local npcHeading = GetEntityHeading(npc)

    local dirToPlayer = playerCoords - npcCoords
    local angleToPlayer = math.deg(math.atan(dirToPlayer.x, dirToPlayer.y))
    if angleToPlayer < 0 then angleToPlayer = angleToPlayer + 360 end

    local npcFacing = npcHeading
    if npcFacing < 0 then npcFacing = npcFacing + 360 end

    local angleDiff = math.abs(angleToPlayer - npcFacing)
    if angleDiff > 180 then angleDiff = 360 - angleDiff end

    return angleDiff < 90
end

local function StartConversation()
    if isInConversation then return end
    if not deliveryNpc or not DoesEntityExist(deliveryNpc) then return end

    isInConversation = true

    local ped = PlayerPedId()
    local npcCoords = GetEntityCoords(deliveryNpc)
    local npcForward = GetEntityForwardVector(deliveryNpc)

    local targetPos = vector3(
        npcCoords.x + npcForward.x * 1.2,
        npcCoords.y + npcForward.y * 1.2,
        npcCoords.z
    )

    TaskGoToCoordAnyMeans(ped, targetPos.x, targetPos.y, targetPos.z, 1.0, 0, false, 786603, 0xbf800000)

    local timeout = 0
    while timeout < 50 do
        Wait(100)
        timeout = timeout + 1
        local playerCoords = GetEntityCoords(ped)
        if #(playerCoords - targetPos) < 0.5 then
            break
        end
    end

    ClearPedTasks(ped)
    TaskTurnPedToFaceEntity(ped, deliveryNpc, 1000)
    Wait(1000)

    SetEntityVisible(ped, false, false)

    local headBone = GetPedBoneCoords(deliveryNpc, 31086, 0.0, 0.0, 0.0)

    local camCoords = vector3(
        headBone.x + npcForward.x * 1.0,
        headBone.y + npcForward.y * 1.0,
        headBone.z
    )

    conversationCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(conversationCamera, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(conversationCamera, headBone.x, headBone.y, headBone.z)
    SetCamActive(conversationCamera, true)
    RenderScriptCams(true, true, 500, true, true)

    local npcName = deliveryNpcData and deliveryNpcData.name or "Client"
    local canDeliver = TriggerServerCallback("uwu_cafe:delivery:checkItems")

    SendNUIMessage({
        action = "uwu_cafe:delivery:openConversation",
        data = {
            npcName = npcName,
            orderItems = deliveryOrderItems,
            canDeliver = canDeliver,
            reward = deliveryReward
        }
    })
    VFW.Nui.Focus(true)
end

local function HandleDeliveryResult(success, reward, tip, societyGain)
    if success then
        deliveryDelivered = deliveryDelivered + 1

        societyGain = societyGain or 0
        tip = tip or 0
        local employeeBase = (reward or 0) - tip
        local total = employeeBase + societyGain
        local msg = "Livraison effectuée ! Total : " .. VFW.Math.FormatMoney(total) .. " | Société : " .. VFW.Math.FormatMoney(societyGain) .. " | Toi : " .. VFW.Math.FormatMoney(employeeBase)
        if tip > 0 then
            msg = msg .. " + " .. VFW.Math.FormatMoney(tip) .. " de pourboire"
        end

        VFW.ShowNotification({
            type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
            image = UWU_CAFE_LOGO,
            content = msg
        })

        local delivered = deliveryDelivered
        local npc = deliveryNpc
        RemoveDeliveryBlip()
        deliveryActive = false
        deliveryJobName = nil
        deliveryClientData = nil
        deliveryOrderItems = nil
        deliveryReward = nil
        deliveryDelivered = 0
        deliveryVehicle = nil
        deliveryOutOfVehicleTime = nil
        deliveryNpc = nil
        deliveryNpcData = nil

        TriggerServerCallback("uwu_cafe:delivery:end")

        if npc and DoesEntityExist(npc) then
            SetTimeout(30000, function()
                if npc and DoesEntityExist(npc) then
                    DeleteEntity(npc)
                end
            end)
        end
    end
end

RegisterNUICallback("uwu_cafe:delivery:conversationChoice", function(data, cb)
    if data.choice == "deliver" then
        local success, reward, tipOrMissing, societyGain = TriggerServerCallback("uwu_cafe:delivery:deliver")
        if success then
            SendNUIMessage({
                action = "uwu_cafe:delivery:deliveryResult",
                data = { success = true, reward = reward, tip = tipOrMissing, societyGain = societyGain }
            })
            HandleDeliveryResult(true, reward, tipOrMissing, societyGain)
        else
            EndConversation()
            local missing = tipOrMissing
            if missing then
                local parts = {}
                for _, m in ipairs(missing) do
                    table.insert(parts, m.label .. " (" .. m.have .. "/" .. m.need .. ")")
                end
                VFW.ShowNotification({
                    type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
                    image = UWU_CAFE_LOGO,
                    content = "Il vous manque des items : " .. table.concat(parts, ", ")
                })
            else
                VFW.ShowNotification({
                    type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
                    image = UWU_CAFE_LOGO,
                    content = reward or "Une erreur est survenue lors de la livraison."
                })
            end
        end
    else
        EndConversation()
    end
    cb({ success = true })
end)

RegisterNUICallback("uwu_cafe:delivery:continueChoice", function(data, cb)
    EndConversation()

    if data.choice == "continue" then
        local success, result = TriggerServerCallback("uwu_cafe:delivery:next")
        if success then
            RemoveDeliveryBlip()
            RemoveDeliveryNpc()

            deliveryClientData = result.clientData
            deliveryOrderItems = result.orderItems
            deliveryReward = result.reward

            local coords = vector3(result.clientData.x, result.clientData.y, result.clientData.z)
            CreateDeliveryBlip(coords, result.npcName)

            ShowDeliveryOrder()

            local parts = {}
            for _, oi in ipairs(result.orderItems) do
                table.insert(parts, oi.count .. "x " .. oi.label)
            end
            VFW.ShowNotification({
                type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
                image = UWU_CAFE_LOGO,
                content = "Nouvelle livraison ! Commande : " .. table.concat(parts, ", ") .. " - Récompense : " .. VFW.Math.FormatMoney(result.reward)
            })
        else
            CleanupDelivery()
            VFW.ShowNotification({
                type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
                image = UWU_CAFE_LOGO,
                content = result or "Il n'y a plus de clients disponibles."
            })
        end
    else
        CleanupDelivery()
        TriggerServerCallback("uwu_cafe:delivery:end")
    end
    cb({ success = true })
end)

function UwuCafe_StartDelivery(jobName)
    if deliveryActive then
        VFW.ShowNotification({
            type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
            image = UWU_CAFE_LOGO,
            content = "Vous avez déjà une livraison en cours."
        })
        return
    end

    local loc = UwuCafeConfig.Locations[jobName]
    if loc then
        local refCoords = nil
        if loc.Machine and loc.Machine.slots then
            for _, slotData in pairs(loc.Machine.slots) do
                refCoords = slotData.pos
                break
            end
        end
        if refCoords then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - refCoords)
            local maxDist = UwuCafeConfig.DeliveryStartMaxDistance or 50.0
            if dist > maxDist then
                VFW.ShowNotification({
                    type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
                    image = UWU_CAFE_LOGO,
                    content = "Vous êtes trop loin du restaurant pour recevoir la livraison."
                })
                return
            end
        end
    end

    local requiredVehicles = UwuCafeConfig.DeliveryVehicleModels
    if requiredVehicles and #requiredVehicles > 0 then
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            VFW.ShowNotification({ type = "JOB", title = "UwU Cafe", subtitle = "Livraison", image = UWU_CAFE_LOGO,
                content = "Vous devez être dans un véhicule autorisé pour démarrer la livraison." })
            return
        end
        local vehicle = GetVehiclePedIsIn(ped, false)
        local currentModel = GetEntityModel(vehicle)
        local allowed = false
        for _, model in ipairs(requiredVehicles) do
            if currentModel == GetHashKey(model) then allowed = true break end
        end
        if not allowed then
            VFW.ShowNotification({ type = "JOB", title = "UwU Cafe", subtitle = "Livraison", image = UWU_CAFE_LOGO,
                content = "Vous devez être dans un véhicule autorisé (" .. table.concat(requiredVehicles, ", ") .. ")." })
            return
        end
    end

    local success, result = TriggerServerCallback("uwu_cafe:delivery:start", jobName)
    if not success then
        VFW.ShowNotification({
            type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
            image = UWU_CAFE_LOGO,
            content = result or "Impossible de démarrer la livraison."
        })
        return
    end

    deliveryActive = true
    deliveryJobName = jobName
    deliveryClientData = result.clientData
    deliveryOrderItems = result.orderItems
    deliveryReward = result.reward
    deliveryDelivered = 0

    if requiredVehicles and #requiredVehicles > 0 then
        deliveryVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    end

    local coords = vector3(result.clientData.x, result.clientData.y, result.clientData.z)
    CreateDeliveryBlip(coords, result.npcName)

    ShowDeliveryOrder()

    local parts = {}
    for _, oi in ipairs(result.orderItems) do
        table.insert(parts, oi.count .. "x " .. oi.label)
    end
    VFW.ShowNotification({
        type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
        image = UWU_CAFE_LOGO,
        content = "Nouvelle livraison ! Commande : " .. table.concat(parts, ", ") .. " - Récompense : " .. VFW.Math.FormatMoney(result.reward)
    })
end

function UwuCafe_EndDelivery()
    if not deliveryActive then return end
    local delivered = deliveryDelivered
    CleanupDelivery()
    TriggerServerCallback("uwu_cafe:delivery:end")
    VFW.ShowNotification({
        type = "JOB", title = "UwU Cafe", subtitle = "Livraison",
        image = UWU_CAFE_LOGO,
        content = "La livraison est terminée !"
    })
end

function UwuCafe_GetDeliveryState()
    return {
        active = deliveryActive,
        delivered = deliveryDelivered,
        jobName = deliveryJobName
    }
end

CreateThread(function()
    Wait(1500)

    local registry = exports["core"]:getJobMenuRegistry()
    if not registry then return end

    local jobNames = {}
    for jobName, _ in pairs(UwuCafeConfig.Locations) do
        table.insert(jobNames, jobName)
    end

    registry.register(jobNames, function(menu)
        local state = UwuCafe_GetDeliveryState()

        if not state.active then
            menu.Button(
                "Lancer une livraison",
                "Démarrer une mission de livraison UwU Cafe",
                nil,
                "arrow",
                false,
                function()
                    local jobName = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name
                    if jobName then
                        UwuCafe_StartDelivery(jobName)
                    end
                    menu.close()
                end
            )
        else
            menu.Separator("LIVRAISON EN COURS")

            menu.Button(
                "Voir la commande",
                "Afficher les détails de la commande en cours",
                nil,
                "search",
                false,
                function()
                    ShowDeliveryOrder()
                    menu.close()
                end
            )

            menu.Button(
                "Terminer la livraison",
                "Arrêter la mission de livraison",
                nil,
                "arrow",
                false,
                function()
                    UwuCafe_EndDelivery()
                    menu.refresh()
                end
            )
        end
    end, 50)
end)

RegisterNUICallback("bossPanel:clearUwuCafeLogs", function(data, cb)
    local deleted = TriggerServerCallback("uwu_cafe:delivery:clearLogs")
    if not deleted then
        VFW.ShowNotification({
            type = "JOB", title = "UwU Cafe", subtitle = "Administration",
            image = UWU_CAFE_LOGO,
            content = "Vous n'avez pas les permissions nécessaires."
        })
        cb(false)
        return
    end
    VFW.ShowNotification({
        type = "JOB", title = "UwU Cafe", subtitle = "Administration",
        image = UWU_CAFE_LOGO,
        content = "Les logs ont été supprimés."
    })
    cb(true)
end)

CreateThread(function()
    while true do
        local sleep = 500

        if deliveryActive and deliveryClientData then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local inVehicle = IsPedInAnyVehicle(ped, false)

            if deliveryVehicle then
                if DoesEntityExist(deliveryVehicle) then
                    local inDeliveryVehicle = (GetVehiclePedIsIn(ped, false) == deliveryVehicle)
                    if not inDeliveryVehicle then
                        if not deliveryOutOfVehicleTime then
                            deliveryOutOfVehicleTime = GetGameTimer()
                        end
                        local elapsed = GetGameTimer() - deliveryOutOfVehicleTime
                        if elapsed > 120000 then
                            VFW.ShowNotification({ type = "JOB", title = "UwU Cafe", subtitle = "Livraison", image = UWU_CAFE_LOGO,
                                content = "Livraison annulée ! Vous avez abandonné votre véhicule de livraison." })
                            CleanupDelivery()
                            TriggerServerCallback("uwu_cafe:delivery:end")
                        end
                    else
                        deliveryOutOfVehicleTime = nil
                    end
                else
                    if not deliveryOutOfVehicleTime then
                        deliveryOutOfVehicleTime = GetGameTimer()
                    end
                    local elapsed = GetGameTimer() - deliveryOutOfVehicleTime
                    if elapsed > 120000 then
                        VFW.ShowNotification({ type = "JOB", title = "UwU Cafe", subtitle = "Livraison", image = UWU_CAFE_LOGO,
                            content = "Livraison annulée ! Vous avez abandonné votre véhicule de livraison." })
                        CleanupDelivery()
                        TriggerServerCallback("uwu_cafe:delivery:end")
                    end
                end
            end

            if deliveryClientData then
                local clientVec = vector3(deliveryClientData.x, deliveryClientData.y, deliveryClientData.z)
                local distToClient = #(coords - clientVec)
                local spawnDist = UwuCafeConfig.DeliveryNpcSpawnDistance or 50.0

                if distToClient < spawnDist then
                    if not deliveryNpc or not DoesEntityExist(deliveryNpc) then
                        SpawnDeliveryNpc(deliveryClientData)
                    end
                else
                    if deliveryNpc and DoesEntityExist(deliveryNpc) then
                        RemoveDeliveryNpc()
                    end
                end

                if deliveryNpc and DoesEntityExist(deliveryNpc) and not isInConversation then
                    local npcCoords = GetEntityCoords(deliveryNpc)
                    local distToNpc = #(coords - npcCoords)
                    if distToNpc < 2.5 and not inVehicle and (distToNpc < 1.5 or IsPlayerInFrontOfNpc(deliveryNpc)) then
                        sleep = 0
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour parler au client")
                        if VFW.Interact.JustPressed(0, 38) then
                            if CanInteract() then
                                StartConversation()
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

local function OnJobChange()
    Wait(500)
    if deliveryActive then
        CleanupDelivery()
        TriggerServerCallback("uwu_cafe:delivery:end")
    end
end

RegisterNetEvent("vfw:setJob", OnJobChange)

RegisterNetEvent("vfw:client:changeDuty", function()
    Wait(200)
    if deliveryActive then
        if not VFW.PlayerData or not VFW.PlayerData.job or not VFW.PlayerData.job.onDuty then
            CleanupDelivery()
            TriggerServerCallback("uwu_cafe:delivery:end")
        end
    end
end)

RegisterNetEvent("vfw:playerLoaded", function()
    CleanupDelivery()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        CleanupDelivery()
    end
end)
