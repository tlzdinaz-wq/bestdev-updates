local Config = LTDDelivery.Config

local pickupBlip = nil
local deliveryBlip = nil
local boxBlip = nil
local vehicleBlip = nil
local carryingObject = nil
local lastInteraction = 0
local jobVehicle = nil

local deliveryNpc = nil
local deliveryNpcData = nil
local isInConversation = false
local conversationCamera = nil
local activeDeliveryNpcs = {}

local groundBoxes = {}

local BOX_ITEM = "ltd_box"
local NPC_DECOR = "ltd_delivery_npc"

local function MyServerId()
    return GetPlayerServerId(PlayerId())
end

CreateThread(function()
    if not DecorIsRegisteredAsType(NPC_DECOR, 2) then
        DecorRegister(NPC_DECOR, 2)
    end
end)

local function IsTaggedDeliveryNpc(ped)
    return DecorExistOn(ped, NPC_DECOR) and DecorGetBool(ped, NPC_DECOR)
end

local function GetAllowedVehicleModel()
    local m = LTDDelivery.GetMission()
    if m.active and m.vehicle then
        return m.vehicle
    end
    local boxMeta = nil
    if VFW.PlayerData and VFW.PlayerData.inventory then
        for _, item in pairs(VFW.PlayerData.inventory) do
            if item.name == BOX_ITEM and item.meta then
                boxMeta = item.meta
                break
            end
        end
    end
    if boxMeta and boxMeta.vehicleModel then
        return boxMeta.vehicleModel
    end
    return Config.DefaultVehicle
end

local function IsAllowedVehicle(veh)
    if not veh or veh == 0 then return false end
    local allowedModel = GetAllowedVehicleModel()
    if not allowedModel then return true end
    local vehModel = GetEntityModel(veh)
    return vehModel == joaat(string.lower(allowedModel))
end

local function GetBoxMetadata()
    if not VFW.PlayerData or not VFW.PlayerData.inventory then return nil end
    for _, item in pairs(VFW.PlayerData.inventory) do
        if item.name == BOX_ITEM and item.meta then
            return item.meta
        end
    end
    return nil
end

local function HasBoxItem()
    if not VFW.PlayerData or not VFW.PlayerData.inventory then return false end
    for _, item in pairs(VFW.PlayerData.inventory) do
        if item.name == BOX_ITEM and item.count and item.count >= 1 then
            return true
        end
    end
    return false
end

local function CanInteract()
    local now = GetGameTimer()
    if now - lastInteraction < 1000 then return false end
    lastInteraction = now
    return true
end

local function CreateBoxBlip(coords)
    if boxBlip then RemoveBlip(boxBlip) end
    boxBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(boxBlip, 478)
    SetBlipDisplay(boxBlip, 4)
    SetBlipScale(boxBlip, 0.5)
    SetBlipColour(boxBlip, 2)
    SetBlipRoute(boxBlip, true)
    SetBlipRouteColour(boxBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Carton de Livraison - LTD")
    EndTextCommandSetBlipName(boxBlip)
end

local function RemoveBoxBlip()
    if boxBlip then RemoveBlip(boxBlip) boxBlip = nil end
end

local function CreateDeliveryBlip(coords, npcName)
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(deliveryBlip, 480)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.5)
    SetBlipColour(deliveryBlip, 2)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    local blipName = (npcName or "Client") .. " - Livraison LTD"
    AddTextComponentString(blipName)
    EndTextCommandSetBlipName(deliveryBlip)
end

local function RemoveDeliveryBlip()
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
end

local function CreateVehicleBlip(veh)
    if vehicleBlip then RemoveBlip(vehicleBlip) end
    if not veh or veh == 0 then return end
    vehicleBlip = AddBlipForEntity(veh)
    SetBlipSprite(vehicleBlip, 326)
    SetBlipDisplay(vehicleBlip, 4)
    SetBlipScale(vehicleBlip, 0.5)
    SetBlipColour(vehicleBlip, 2)
    SetBlipRoute(vehicleBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Véhicule de Livraison - LTD")
    EndTextCommandSetBlipName(vehicleBlip)
end

local function RemoveVehicleBlip()
    if vehicleBlip then RemoveBlip(vehicleBlip) vehicleBlip = nil end
end

local function RemoveBlips()
    if pickupBlip then RemoveBlip(pickupBlip) pickupBlip = nil end
    RemoveDeliveryBlip()
    RemoveBoxBlip()
    RemoveVehicleBlip()
end

local function GetVehicleTrunkCoords(veh)
    local min, max = GetModelDimensions(GetEntityModel(veh))
    local offset = GetOffsetFromEntityInWorldCoords(veh, 0.0, min.y - 0.5, 0.0)
    return offset
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
        action = "fl_ltd:closeConversation"
    })
    VFW.Nui.Focus(false)
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

    if not isInConversation or not deliveryNpc or not DoesEntityExist(deliveryNpc) then
        isInConversation = false
        return
    end

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
    local hasBox = HasBoxItem()
    local boxMeta = hasBox and GetBoxMetadata() or nil
    local m = LTDDelivery.GetMission()
    local canDeliver = hasBox and (m.active or (boxMeta and boxMeta.missionOwner))

    local jobLabel = m.label or (boxMeta and boxMeta.jobLabel) or "LTD"

    SendNUIMessage({
        action = "fl_ltd:openConversation",
        data = {
            npcName = npcName,
            canDeliver = canDeliver,
            jobLabel = jobLabel
        }
    })
    VFW.Nui.Focus(true)
end

RegisterNUICallback("fl_ltd:conversationChoice", function(data, cb)
    if data.choice == "deliver" then
        EndConversation()
        DeliverBoxToNpc()
    else
        EndConversation()
    end
    cb({ success = true })
end)

local function ClearOwnerRefs(missionOwner)
    if missionOwner == MyServerId() then
        if isInConversation then
            EndConversation()
        end
        deliveryNpc = nil
        deliveryNpcData = nil
    end
end

local function NpcPlayReceiveAnimation(entry)
    local npc = entry and entry.ped
    if not npc or not DoesEntityExist(npc) then return end
    if entry.animationStarted then return end
    entry.animationStarted = true

    FreezeEntityPosition(npc, false)
    SetBlockingOfNonTemporaryEvents(npc, false)
    ClearPedTasksImmediately(npc)

    local boxModel = GetHashKey(Config.BoxProp)
    RequestModel(boxModel)
    local boxTimeout = 0
    while not HasModelLoaded(boxModel) and boxTimeout < 100 do
        Wait(10)
        boxTimeout = boxTimeout + 1
    end

    if HasModelLoaded(boxModel) then
        local npcBox = CreateObject(boxModel, 0.0, 0.0, 0.0, false, false, false)
        AttachEntityToEntity(npcBox, npc, GetPedBoneIndex(npc, 28422), -0.05, 0.0, -0.10, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(boxModel)
        entry.boxObject = npcBox
    end

    local animDict = Config.BoxAnim.dict
    local animName = Config.BoxAnim.name
    RequestAnimDict(animDict)
    local animTimeout = 0
    while not HasAnimDictLoaded(animDict) and animTimeout < 100 do
        Wait(10)
        animTimeout = animTimeout + 1
    end

    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(npc, animDict, animName, 8.0, 8.0, -1, 49, 0, false, false, false)
    end
end

local function RemoveLocalNpc(missionOwner)
    local entry = activeDeliveryNpcs[missionOwner]
    if not entry then return end

    if entry.boxObject and DoesEntityExist(entry.boxObject) then
        DeleteEntity(entry.boxObject)
    end
    entry.boxObject = nil

    if entry.ped and DoesEntityExist(entry.ped) then
        DeleteEntity(entry.ped)
    end
    entry.ped = nil
    entry.animationStarted = false

    ClearOwnerRefs(missionOwner)
end

local function EnsureLocalNpc(missionOwner)
    local entry = activeDeliveryNpcs[missionOwner]
    if not entry or not entry.data then return end
    if entry.ped and DoesEntityExist(entry.ped) then return end
    if entry.spawning then return end
    entry.spawning = true

    local data = entry.data
    local defaultModel = GetHashKey(Config.DefaultNpcModel)
    local model = GetHashKey(data.model or Config.DefaultNpcModel)

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
        entry.spawning = false
        return
    end

    local x = data.coords.x
    local y = data.coords.y
    local z = data.coords.z
    local heading = data.heading or 0.0

    local ped = CreatePed(4, model, x, y, z - 1.0, heading, false, true)
    SetModelAsNoLongerNeeded(model)
    entry.spawning = false

    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
    DecorSetBool(ped, NPC_DECOR, true)

    entry.ped = ped

    if missionOwner == MyServerId() then
        deliveryNpc = ped
        deliveryNpcData = {
            name = data.name or Config.DefaultNpcName,
            coords = vector3(x, y, z)
        }
    end

    if entry.receivedBox then
        NpcPlayReceiveAnimation(entry)
    end
end

local function RemoveAllLocalNpcs()
    for owner, _ in pairs(activeDeliveryNpcs) do
        RemoveLocalNpc(owner)
    end
end

RegisterNetEvent("fl_ltd:syncDeliveryNpc", function(missionOwner, data)
    if not missionOwner or not data then return end
    local entry = activeDeliveryNpcs[missionOwner]
    if not entry then
        entry = { data = data, receivedBox = false }
        activeDeliveryNpcs[missionOwner] = entry
    else
        entry.data = data
    end
end)

RegisterNetEvent("fl_ltd:unregisterDeliveryNpc", function(missionOwner)
    if not missionOwner then return end
    RemoveLocalNpc(missionOwner)
    activeDeliveryNpcs[missionOwner] = nil
end)

RegisterNetEvent("fl_ltd:deliveryNpcReceiveBox", function(missionOwner)
    if not missionOwner then return end
    local entry = activeDeliveryNpcs[missionOwner]
    if not entry then return end
    entry.receivedBox = true
    if missionOwner == MyServerId() then
        if isInConversation then EndConversation() end
        deliveryNpc = nil
        deliveryNpcData = nil
    end
    if entry.ped and DoesEntityExist(entry.ped) then
        NpcPlayReceiveAnimation(entry)
    end
end)

local function SpawnGroundBoxObject(missionOwner)
    local data = groundBoxes[missionOwner]
    if not data or not data.position then return end
    if data.object and DoesEntityExist(data.object) then return end
    if data.spawning then return end
    data.spawning = true

    local model = GetHashKey(Config.BoxProp)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        data.spawning = false
        return
    end

    local current = groundBoxes[missionOwner]
    if not current or current ~= data then
        data.spawning = false
        return
    end
    if data.object and DoesEntityExist(data.object) then
        data.spawning = false
        return
    end

    local obj = CreateObject(model, data.position.x, data.position.y, data.position.z, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)

    data.object = obj
    data.position = GetEntityCoords(obj)
    data.spawning = false
end

local function SetGroundBoxPosition(missionOwner, coords)
    if not missionOwner or not coords then return end
    if not coords.x or not coords.y or not coords.z then return end

    if not groundBoxes[missionOwner] then
        groundBoxes[missionOwner] = {}
    end
    local data = groundBoxes[missionOwner]
    data.position = vector3(coords.x, coords.y, coords.z)

    if data.object and DoesEntityExist(data.object) then
        DeleteEntity(data.object)
        data.object = nil
    end
end

local function RemoveGroundBox(missionOwner)
    if not missionOwner then return end
    local data = groundBoxes[missionOwner]
    if not data then return end
    if data.object and DoesEntityExist(data.object) then
        DeleteEntity(data.object)
    end
    groundBoxes[missionOwner] = nil

    if missionOwner == MyServerId() then
        RemoveBoxBlip()
    end
end

local function RemoveAllGroundBoxes()
    for owner, data in pairs(groundBoxes) do
        if data and data.object and DoesEntityExist(data.object) then
            DeleteEntity(data.object)
        end
    end
    groundBoxes = {}
    RemoveBoxBlip()
end

local function GetClosestGroundBoxOwner(coords, maxDist)
    local myId = MyServerId()
    local m = LTDDelivery.GetMission()

    if m.active and m.phase == "pickup" then
        local data = groundBoxes[myId]
        if data and data.position and #(coords - data.position) <= maxDist then
            return myId, data
        end
    end

    local closestOwner = nil
    local closestData = nil
    local closestDist = maxDist
    for owner, data in pairs(groundBoxes) do
        if data and data.position then
            local dist = #(coords - data.position)
            if dist < closestDist then
                closestDist = dist
                closestOwner = owner
                closestData = data
            end
        end
    end
    return closestOwner, closestData
end

local function AttachBoxToPlayer()
    if carryingObject and DoesEntityExist(carryingObject) then return end

    local ped = PlayerPedId()
    local model = GetHashKey(Config.BoxProp)

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    carryingObject = VFW.OneSync.CreateObject(model, GetEntityCoords(ped))
    AttachEntityToEntity(carryingObject, ped, GetPedBoneIndex(ped, 28422), -0.05, 0.0, -0.10, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)

    local dict = Config.BoxAnim.dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(ped, dict, Config.BoxAnim.name, 8.0, 8.0, -1, 49, 0, false, false, false)
end

local function DetachBoxFromPlayer()
    if carryingObject and DoesEntityExist(carryingObject) then
        DetachEntity(carryingObject, true, true)
        DeleteEntity(carryingObject)
        carryingObject = nil
    end
    ClearPedTasks(PlayerPedId())
end

local function EnsureBoxAnimation(ped)
    local dict = Config.BoxAnim.dict
    local anim = Config.BoxAnim.name
    if not IsEntityPlayingAnim(ped, dict, anim, 3) then
        if not HasAnimDictLoaded(dict) then
            RequestAnimDict(dict)
            local timeout = 0
            while not HasAnimDictLoaded(dict) and timeout < 50 do
                Wait(10)
                timeout = timeout + 1
            end
        end
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 49, 0, false, false, false)
        end
    end
end

local function PickupBoxFromGround()
    if not CanInteract() then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local missionOwner = GetClosestGroundBoxOwner(coords, 2.0)
    if not missionOwner then return end

    local success = TriggerServerCallback("fl_ltd:giveBoxItem", missionOwner)
    if success then
        RemoveGroundBox(missionOwner)

        local m = LTDDelivery.GetMission()
        if m.active and m.delivery then
            CreateDeliveryBlip(m.delivery, m.delivery.npcName)
        end

        VFW.ShowNotification({
            type = "JOB",
            title = m.label or "LTD",
            subtitle = "Information Livraison",
            content = "Colis de livraison récupéré. Livrez-le au point indiqué.",
            image = m.image
        })
    else
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Impossible de prendre le carton."
        })
    end
end

local function DropBoxOnGround()
    if not CanInteract() then return end
    if not HasBoxItem() then return end

    local boxMeta = GetBoxMetadata()
    local missionOwner = boxMeta and boxMeta.missionOwner or MyServerId()

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local dropPos = coords + forward * 1.0

    local success = TriggerServerCallback("fl_ltd:removeBoxItem", { x = dropPos.x, y = dropPos.y, z = dropPos.z })
    if success then
        DetachBoxFromPlayer()
        SetGroundBoxPosition(missionOwner, dropPos)
        SpawnGroundBoxObject(missionOwner)
        if missionOwner == MyServerId() then
            CreateBoxBlip(dropPos)
        end
        RemoveDeliveryBlip()

        local m = LTDDelivery.GetMission()
        VFW.ShowNotification({
            type = "JOB",
            title = m.label or "LTD",
            subtitle = "Information Livraison",
            content = "Carton posé au sol.",
            image = m.image
        })
    end
end

local function PutBoxInTrunk(vehicle)
    if not CanInteract() then return end
    if not HasBoxItem() then return end

    if not IsAllowedVehicle(vehicle) then
        local allowedModel = GetAllowedVehicleModel()
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous devez utiliser un véhicule de type " .. (allowedModel or "autorisé") .. "."
        })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local success = TriggerServerCallback("fl_ltd:putBoxInTrunk", plate)
    if success then
        DetachBoxFromPlayer()
        jobVehicle = vehicle
        CreateVehicleBlip(vehicle)
        RemoveBoxBlip()

        local m = LTDDelivery.GetMission()
        if m.active and m.delivery then
            CreateDeliveryBlip(m.delivery, m.delivery.npcName)
        end

        VFW.ShowNotification({
            type = "JOB",
            title = m.label or "LTD",
            subtitle = "Information Livraison",
            content = "Carton chargé dans le véhicule.",
            image = m.image
        })
    end
end

function DeliverBoxToNpc()
    if not HasBoxItem() then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous n'avez pas de carton à livrer."
        })
        return
    end

    local success, delivered, payment, image, isOwner, ownerConnected, jobLabel, tip = TriggerServerCallback("fl_ltd:deliverBox")
    if success then
        DetachBoxFromPlayer()
        deliveryNpc = nil
        deliveryNpcData = nil

        if isOwner then
            RemoveBlips()
            LTDDelivery.UpdateMission("waiting", nil, nil, delivered)

            SendNUIMessage({
                action = "fl_ltd:showMissionPopup",
                data = {
                    payment = payment,
                    image = image,
                    tip = tip
                }
            })
            VFW.Nui.Focus(true)
        else
            local tipMessage = ""
            if tip and tip > 0 then
                tipMessage = (" (+%s de pourboire)"):format(VFW.Math.FormatMoney(tip))
            end
            if ownerConnected then
                VFW.ShowNotification({
                    type = "JOB",
                    title = jobLabel or "LTD",
                    subtitle = "Information Livraison",
                    content = "Carton livré." .. tipMessage,
                    image = image
                })
            else
                VFW.ShowNotification({
                    type = "JOB",
                    title = jobLabel or "LTD",
                    subtitle = "Information Livraison",
                    content = "Carton livré. Le lanceur de mission n'est plus connecté." .. tipMessage,
                    image = image
                })
            end
        end
    else
        VFW.ShowNotification({
            type = "ROUGE",
            content = delivered or "Erreur lors de la livraison."
        })
    end
end

RegisterNetEvent("fl_ltd:deliveryComplete", function(delivered, payment, image, tip)
    RemoveBlips()
    deliveryNpc = nil
    deliveryNpcData = nil

    LTDDelivery.UpdateMission("waiting", nil, nil, delivered)

    SendNUIMessage({
        action = "fl_ltd:showMissionPopup",
        data = {
            payment = payment,
            image = image,
            tip = tip
        }
    })
    VFW.Nui.Focus(true)
end)

RegisterNetEvent("fl_ltd:missionCancelled", function(reason)
    RemoveBlips()
    RemoveGroundBox(MyServerId())
    DetachBoxFromPlayer()
    jobVehicle = nil

    LTDDelivery.ClearMission()

    VFW.ShowNotification({
        type = "ROUGE",
        content = reason or "Mission annulée."
    })
end)

RegisterNetEvent("fl_ltd:boxDropped", function(missionOwner, position)
    if not position or not missionOwner then return end
    SetGroundBoxPosition(missionOwner, position)
end)

RegisterNetEvent("fl_ltd:boxPickedUp", function(missionOwner)
    RemoveGroundBox(missionOwner)
end)

local function AcceptNextDelivery()
    local success, data = TriggerServerCallback("fl_ltd:nextDelivery")
    if success then
        RemoveBlips()
        RemoveGroundBox(MyServerId())
        LTDDelivery.UpdateMission("pickup", data.pickup, data.delivery, nil)

        local myId = MyServerId()
        SetGroundBoxPosition(myId, data.pickup)
        CreateBoxBlip(data.pickup)

        local m = LTDDelivery.GetMission()
        VFW.ShowNotification({
            type = "JOB",
            title = m.label or "LTD",
            subtitle = "Information Livraison",
            content = "Une nouvelle position a été transmise sur votre GPS. Rendez-vous au point indiqué pour récupérer la livraison.",
            image = m.image
        })
    end
end

AddEventHandler("fl_ltd:missionStarted", function(data)
    local myId = MyServerId()
    SetGroundBoxPosition(myId, data.pickup)
    jobVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    CreateBoxBlip(data.pickup)
end)

AddEventHandler("fl_ltd:missionEnded", function()
    RemoveBlips()
    RemoveGroundBox(MyServerId())
    DetachBoxFromPlayer()
    TriggerServerCallback("fl_ltd:removeBoxItem")
    jobVehicle = nil
    VFW.Nui.Focus(false)
end)

RegisterNUICallback("fl_ltd:acceptMission", function(_, cb)
    VFW.Nui.Focus(false)
    AcceptNextDelivery()
    cb({ success = true })
end)

RegisterNUICallback("fl_ltd:refuseMission", function(_, cb)
    VFW.Nui.Focus(false)
    LTDDelivery.EndMission()
    cb({ success = true })
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local hasBox = HasBoxItem()
        local inVehicle = IsPedInAnyVehicle(ped, false)

        if hasBox and not inVehicle then
            if not carryingObject or not DoesEntityExist(carryingObject) then
                AttachBoxToPlayer()
            else
                EnsureBoxAnimation(ped)
            end
        elseif not hasBox or inVehicle then
            if carryingObject and DoesEntityExist(carryingObject) then
                DetachBoxFromPlayer()
            end
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local spawnDist = Config.NpcSpawnDistance or 50.0
        local despawnDist = spawnDist + 20.0

        for owner, entry in pairs(activeDeliveryNpcs) do
            if entry.data and entry.data.coords then
                local npcVec = vector3(entry.data.coords.x, entry.data.coords.y, entry.data.coords.z)
                local dist = #(coords - npcVec)

                if dist < spawnDist then
                    if not entry.ped or not DoesEntityExist(entry.ped) then
                        CreateThread(function() EnsureLocalNpc(owner) end)
                    end
                elseif dist > despawnDist and not entry.receivedBox then
                    if entry.ped and DoesEntityExist(entry.ped) then
                        RemoveLocalNpc(owner)
                    end
                end
            end
        end

        Wait(2000)
    end
end)

local function GetInteractableNpc()
    local myId = MyServerId()
    local boxMeta = GetBoxMetadata()
    local missionOwner = boxMeta and boxMeta.missionOwner or nil
    if not missionOwner then
        local m = LTDDelivery.GetMission()
        if m.active and m.phase == "delivery" then
            missionOwner = myId
        end
    end
    if not missionOwner then return nil, nil, nil end

    local entry = activeDeliveryNpcs[missionOwner]
    if not entry or entry.receivedBox then return nil, nil, nil end
    if not entry.ped or not DoesEntityExist(entry.ped) then return nil, nil, nil end

    local name = (entry.data and entry.data.name) or Config.DefaultNpcName
    return entry.ped, name, missionOwner
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inVehicle = IsPedInAnyVehicle(ped, false)
        local hasBox = HasBoxItem()
        local sleep = 500

        local closestBoxDist = math.huge
        for owner, data in pairs(groundBoxes) do
            if data.position then
                local dist = #(coords - data.position)
                if dist < 100.0 and (not data.object or not DoesEntityExist(data.object)) then
                    SpawnGroundBoxObject(owner)
                end
                if dist < closestBoxDist then
                    closestBoxDist = dist
                end
            end
        end

        if closestBoxDist < 30.0 then
            sleep = 0

            if closestBoxDist < 2.0 and not inVehicle and not hasBox then
                local pickupOwner = GetClosestGroundBoxOwner(coords, 2.0)
                if pickupOwner then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récupérer le carton de livraison LTD")
                    if VFW.Interact.JustPressed(0, 38) then
                        PickupBoxFromGround()
                    end
                end
            end
        end

        local nearVehicle = nil
        local nearTrunk = false

        if not inVehicle then
            local vehicles = GetGamePool('CVehicle')
            for _, veh in ipairs(vehicles) do
                if DoesEntityExist(veh) and IsAllowedVehicle(veh) then
                    local trunkCoords = GetVehicleTrunkCoords(veh)
                    local dist = #(coords - trunkCoords)
                    if dist < 2.5 then
                        nearVehicle = veh
                        nearTrunk = true
                        break
                    end
                end
            end
        end

        local nearNpc = false
        if not isInConversation then
            local targetNpc, targetName, targetOwner = GetInteractableNpc()
            if targetNpc then
                local npcCoords = GetEntityCoords(targetNpc)
                local distToNpc = #(coords - npcCoords)
                if distToNpc < 2.5 and not inVehicle and IsPlayerInFrontOfNpc(targetNpc) then
                    nearNpc = true
                    sleep = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour parler au client")
                    if VFW.Interact.JustPressed(0, 38) then
                        deliveryNpc = targetNpc
                        deliveryNpcData = {
                            name = targetName,
                            coords = npcCoords
                        }
                        StartConversation()
                    end
                end
            end
        end

        if not nearNpc and hasBox and not inVehicle then
            sleep = 0

            if nearTrunk and nearVehicle then
                VFW.ShowHelpNotification("~INPUT_CONTEXT~ Charger le carton LTD dans le coffre~n~~INPUT_VEH_DUCK~ Poser le carton au sol")
                if VFW.Interact.JustPressed(0, 38) then
                    PutBoxInTrunk(nearVehicle)
                elseif IsControlJustPressed(0, 73) then
                    DropBoxOnGround()
                end
            else
                VFW.ShowHelpNotification("~INPUT_VEH_DUCK~ Poser le carton de livraison au sol")
                if IsControlJustPressed(0, 73) then
                    DropBoxOnGround()
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        RemoveBlips()
        RemoveAllGroundBoxes()
        RemoveAllLocalNpcs()
        DetachBoxFromPlayer()
        EndConversation()
    end
end)
