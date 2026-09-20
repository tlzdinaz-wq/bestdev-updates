local NPCData = {}
local CurrentMission = nil
local MissionVehicle = nil
local DeliveryNPC = nil
local DeliveryBlip = nil
local InVehicleCheck = false
local DespawnTimer = nil
local VehicleBlip = nil
local CarryingBox = false
local AmbientNotifThread = nil

-- Messages d'ambiance aléatoires pendant le Go Fast
local AmbientMessages = {
    { type = 'ILLEGAL', message = "📻 Radio: Unité mobile, on signale un véhicule suspect dans le secteur..." },
    { type = 'ILLEGAL', message = "📻 Radio: À toutes les unités, restez vigilants.." },
    { type = 'ILLEGAL', message = "⚠️ Tu as l'impression d'être suivi..." },
    { type = 'ILLEGAL', message = "⚠️ Une voiture de police vient de passer à côté..." },
    { type = 'ILLEGAL', message = "💨 Dépêche-toi, le temps presse !" },
    { type = 'ILLEGAL', message = "🚗 Continue comme ça, tu t'en sors bien." },
    { type = 'ILLEGAL', message = "📍 Tu te rapproches de la destination." },
    { type = 'ILLEGAL', message = "👀 Un témoin t'a peut-être repéré..." },
    { type = 'ILLEGAL', message = "🚨 Les flics ont été prévenus, fais attention !" },
    { type = 'ILLEGAL', message = "💰 Pense à l'argent qui t'attend à la livraison..." },
    { type = 'ILLEGAL', message = "📻 'Véhicule suspect signalé, patrouille en route...'" },
    { type = 'ILLEGAL', message = "⚠️ Tu sens la pression monter..." },
    { type = 'ILLEGAL', message = "🛣️ La route est dégagée, profites-en !" },
    { type = 'ILLEGAL', message = "👮 Un hélico passe au loin... Coïncidence ?" },
    { type = 'ILLEGAL', message = "⏰ Plus que quelques minutes, tiens bon !" }
}

-- Démarre le thread de notifications d'ambiance
local function StartAmbientNotifications()
    if AmbientNotifThread then return end

    AmbientNotifThread = CreateThread(function()
        -- Attendre un peu avant la première notification
        Wait(math.random(15000, 30000))

        while CurrentMission and CarryingBox do
            -- Afficher une notification aléatoire
            local msg = AmbientMessages[math.random(#AmbientMessages)]
            VFW.ShowNotification({
                type = msg.type,
                message = msg.message,
                content = msg.content
            })

            -- Attendre entre 20 et 45 secondes avant la prochaine
            Wait(math.random(20000, 45000))
        end

        AmbientNotifThread = nil
    end)
end

-- Arrête le thread de notifications d'ambiance
local function StopAmbientNotifications()
    AmbientNotifThread = nil
end

-- Timer UI supprimé (comme pour les braquages)

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

CreateThread(function()
    Wait(2000)
    local npcs = TriggerServerCallback("core:gofast:getNPCs") or {}
    for _, npc in ipairs(npcs) do
        NPCData[npc.region] = npc
    end
end)

local function SpawnNPC(position, model)
    local hash = GetHashKey(model or "g_m_y_mexgang_01")
    RequestModel(hash)

    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(hash) then return nil end

    -- Créer le PED au sol
    local ped = CreatePed(4, hash, position.x, position.y, position.z - 1.0, position.heading or 0.0, false, true)

    -- Attendre que le PED soit créé
    Wait(100)

    -- Placer le PED au sol
    PlaceObjectOnGroundProperly(ped)
    SetEntityCoordsNoOffset(ped, position.x, position.y, position.z, false, false, false)

    SetEntityAsMissionEntity(ped, true, true)
    SetPedCanRagdoll(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedFleeAttributes(ped, 0, 0)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(hash)

    return ped
end

local NorthNPC = nil
local SouthNPC = nil

CreateThread(function()
    while not NPCData.NORTH do
        Wait(1000)
    end

    if NPCData.NORTH and NPCData.NORTH.enabled then
        NorthNPC = SpawnNPC(NPCData.NORTH.position, NPCData.NORTH.model or "g_m_y_mexgang_01")
    end

    if NPCData.SOUTH and NPCData.SOUTH.enabled then
        SouthNPC = SpawnNPC(NPCData.SOUTH.position, NPCData.SOUTH.model or "g_m_y_mexgang_01")
    end
end)

-- Cache pour éviter de spammer les vérifications serveur
local lastCanStartCheck = {}
local canStartCache = {}
local CAN_START_CACHE_DURATION = 5000 -- 5 secondes de cache

local function CheckCanStartMission(region)
    local now = GetGameTimer()

    -- Utiliser le cache si récent
    if lastCanStartCheck[region] and (now - lastCanStartCheck[region]) < CAN_START_CACHE_DURATION then
        return canStartCache[region]
    end

    -- Sinon, vérifier côté serveur
    local result = TriggerServerCallback("core:gofast:canStartMission", region)
    lastCanStartCheck[region] = now
    canStartCache[region] = result

    return result
end

local function StartMission(region)
    if CurrentMission then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Vous avez déjà une mission en cours"
        })
        return
    end

    -- Vérifier les conditions côté serveur AVANT d'ouvrir le menu
    local canStartResult = TriggerServerCallback("core:gofast:canStartMission", region)
    if not canStartResult.canStart then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = canStartResult.reason or "Impossible de démarrer un Go Fast"
        })
        return
    end

    local categories = TriggerServerCallback("core:gofast:getVehicleCategories")
    if not categories or #categories == 0 then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Aucune catégorie de véhicule disponible"
        })
        return
    end

    -- Les catégories sont toujours actives (hardcodées côté serveur)
    local activeCategories = categories

    local npcId = region == "NORTH" and (NPCData.NORTH and NPCData.NORTH.id or 1) or (NPCData.SOUTH and NPCData.SOUTH.id or 2)

    SendNUIMessage({
        action = 'nui:gofast-menu:open',
        data = {
            npcId = npcId,
            region = region,
            categories = activeCategories
        }
    })
    VFW.Nui.Focus(true, false)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not CurrentMission then
            if NorthNPC and NPCData.NORTH and NPCData.NORTH.position then
                local npcCoords = vector3(NPCData.NORTH.position.x, NPCData.NORTH.position.y, NPCData.NORTH.position.z)
                local dist = #(playerCoords - npcCoords)

                if dist < 2.5 then
                    sleep = 0

                    -- Vérifier si le joueur peut lancer une mission (avec cache)
                    local canStartResult = CheckCanStartMission("NORTH")

                    if canStartResult and canStartResult.canStart then
                        ShowHelp("~INPUT_CONTEXT~ Lancer un Go Fast")
                    else
                        -- Afficher le message avec la raison du blocage
                        local reason = canStartResult and canStartResult.reason or "Indisponible"
                        ShowHelp("~r~Go Fast indisponible~s~\n" .. reason)
                    end

                    if VFW.Interact.JustPressed(0, 38) then
                        StartMission("NORTH")
                        Wait(500)
                    end
                end
            end

            if SouthNPC and NPCData.SOUTH and NPCData.SOUTH.position then
                local npcCoords = vector3(NPCData.SOUTH.position.x, NPCData.SOUTH.position.y, NPCData.SOUTH.position.z)
                local dist = #(playerCoords - npcCoords)

                if dist < 2.5 then
                    sleep = 0

                    -- Vérifier si le joueur peut lancer une mission (avec cache)
                    local canStartResult = CheckCanStartMission("SOUTH")

                    if canStartResult and canStartResult.canStart then
                        ShowHelp("~INPUT_CONTEXT~ Lancer un Go Fast")
                    else
                        -- Afficher le message avec la raison du blocage
                        local reason = canStartResult and canStartResult.reason or "Indisponible"
                        ShowHelp("~r~Go Fast indisponible~s~\n" .. reason)
                    end

                    if VFW.Interact.JustPressed(0, 38) then
                        StartMission("SOUTH")
                        Wait(500)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

local outsideVehicleWarned = false

CreateThread(function()
    while true do
        Wait(5000)

        if CurrentMission and MissionVehicle then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local inMissionVehicle = vehicle == MissionVehicle

            -- Considérer le joueur comme "présent" s'il est près du PNJ de livraison
            -- (ou de la position de destination quand le PNJ n'est pas encore
            -- spawné — lazy spawn déclenché par l'autre thread).
            local nearDeliveryNPC = false
            local playerCoords = GetEntityCoords(playerPed)
            if DeliveryNPC and DoesEntityExist(DeliveryNPC) then
                local npcCoords = GetEntityCoords(DeliveryNPC)
                nearDeliveryNPC = #(playerCoords - npcCoords) < 30.0
            elseif CurrentMission.deliveryPosition then
                local d = CurrentMission.deliveryPosition
                nearDeliveryNPC = #(playerCoords - vector3(d.x, d.y, d.z)) < 30.0
            end

            if inMissionVehicle or nearDeliveryNPC then
                outsideVehicleWarned = false
            elseif not outsideVehicleWarned and CarryingBox then
                outsideVehicleWarned = true
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Tu as 30 secondes pour remonter dans le véhicule sinon la mission sera annulée !"
                })
            end

            TriggerServerEvent("core:gofast:updateVehiclePresence", CurrentMission.missionId, inMissionVehicle or nearDeliveryNPC)
        end
    end
end)


RegisterNetEvent("core:gofast:missionStarted")
AddEventHandler("core:gofast:missionStarted", function(data)

    if not data then
        return
    end

    if not data.vehicleSpawn then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Erreur: Position du véhicule non définie"
        })
        return
    end

    if not data.vehicleModel then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Erreur: Modèle du véhicule non défini"
        })
        return
    end

    CurrentMission = {
        missionId = data.missionId,
        region = data.region,
        deliveryPosition = data.deliveryPosition,
        deliveryRegion = data.deliveryRegion,
        vehicleModel = data.vehicleModel,
        vehiclePlate = data.vehiclePlate,
        vehiclePrice = data.vehiclePrice,
        vehicleSpawn = data.vehicleSpawn,
        deliveryTimeout = data.deliveryTimeout or 1200 -- 20 minutes par défaut
    }

    local vehicleHash = GetHashKey(data.vehicleModel)
    local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(vehicleHash))
    if not vehicleLabel or vehicleLabel == "" or vehicleLabel == "NULL" then
        vehicleLabel = data.vehicleModel
    end

    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = string.format("Go Fast démarré ! Livrez le %s pour %s", vehicleLabel, VFW.Math.FormatMoney(data.vehiclePrice))
    })

    local playerPed = PlayerPedId()

    -- Récupérer le véhicule spawné côté serveur via netId
    if not data.vehicleNetId then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Erreur: Impossible de créer le véhicule"
        })
        CurrentMission = nil
        return
    end

    -- Attendre que l'entité soit disponible côté client
    local tries = 0
    while not NetworkDoesNetworkIdExist(data.vehicleNetId) and tries < 50 do
        Wait(100)
        tries = tries + 1
    end

    MissionVehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)

    if not MissionVehicle or MissionVehicle == 0 or not DoesEntityExist(MissionVehicle) then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Erreur: Impossible de récupérer le véhicule"
        })
        CurrentMission = nil
        return
    end

    -- Empêcher la migration réseau
    SetNetworkIdCanMigrate(data.vehicleNetId, false)
    SetNetworkIdExistsOnAllMachines(data.vehicleNetId, true)

    SetVehicleNumberPlateText(MissionVehicle, data.vehiclePlate)

    local soberColors = {0, 1, 2, 3, 4, 5, 111, 112, 113}
    local randomColor = soberColors[math.random(#soberColors)]
    SetVehicleColours(MissionVehicle, randomColor, randomColor)

    -- Déverrouiller le véhicule
    SetVehicleDoorsLocked(MissionVehicle, 0)
    SetVehicleDoorsLockedForAllPlayers(MissionVehicle, false)

    -- TP le joueur dans le véhicule
    TaskWarpPedIntoVehicle(playerPed, MissionVehicle, -1)

    -- Bloquer complètement le véhicule
    SetVehicleEngineOn(MissionVehicle, false, true, true)
    SetVehicleUndriveable(MissionVehicle, true)
    FreezeEntityPosition(MissionVehicle, true)

    -- NB : la `DeliveryNPC` est volontairement créée plus tard (lazy spawn),
    -- quand le joueur s'approche de la destination. La créer ici alors que
    -- le joueur est à plusieurs km plante PlaceObjectOnGroundProperly (zone
    -- non streamée) → le ped finit sous la map et le check de distance rate.

    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Attendez que la marchandise soit chargée..."
    })

    -- Animation du NPC de départ IMMÉDIATEMENT
    local startNPC = nil
    local startNPCPos = nil
    if CurrentMission.region == "NORTH" then
        startNPC = NorthNPC
        startNPCPos = NPCData.NORTH.position
    else
        startNPC = SouthNPC
        startNPCPos = NPCData.SOUTH.position
    end

    if startNPC and DoesEntityExist(startNPC) and startNPCPos then
        CreateThread(function()
            -- Dégeler le NPC
            FreezeEntityPosition(startNPC, false)
            SetBlockingOfNonTemporaryEvents(startNPC, false)
            SetPedCanRagdoll(startNPC, true)

            -- Charger le modèle de carton
            local boxModel = GetHashKey("prop_cs_cardbox_01")
            RequestModel(boxModel)
            while not HasModelLoaded(boxModel) do
                Wait(10)
            end

            -- Créer le carton et l'attacher au NPC (client-side only comme le PED)
            local box = CreateObject(boxModel, 0, 0, 0, false, false, false)
            AttachEntityToEntity(box, startNPC, GetPedBoneIndex(startNPC, 28422), 0.0, -0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

            -- Animation de porter le carton
            RequestAnimDict("anim@heists@box_carry@")
            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                Wait(10)
            end
            TaskPlayAnim(startNPC, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)

            Wait(1000)

            -- Position directement derrière le véhicule
            local vehPos = GetEntityCoords(MissionVehicle)
            local vehHeading = GetEntityHeading(MissionVehicle)

            -- Calculer la position derrière le véhicule (3 mètres en arrière)
            local backX = vehPos.x + math.sin(math.rad(vehHeading)) * 3.0
            local backY = vehPos.y - math.cos(math.rad(vehHeading)) * 3.0
            local backZ = vehPos.z

            -- Aller derrière le véhicule
            TaskGoToCoordAnyMeans(startNPC, backX, backY, backZ, 1.0, 0, 0, 786603, 0xbf800000)

            -- Attendre que le NPC arrive
            local timeout = 0
            while timeout < 10000 do
                local npcPos = GetEntityCoords(startNPC)
                local dist = #(npcPos - vector3(backX, backY, backZ))
                if dist < 2.5 then
                    break
                end
                Wait(100)
                timeout = timeout + 100
            end

            -- Orienter le NPC vers le véhicule
            local npcPos = GetEntityCoords(startNPC)
            local headingToVeh = GetHeadingFromVector_2d(vehPos.x - npcPos.x, vehPos.y - npcPos.y)
            SetEntityHeading(startNPC, headingToVeh)

            -- Animation de déposer le carton (coffre pas ouvert pour éviter sync réseau)
            Wait(1000)
            ClearPedTasks(startNPC)
            RequestAnimDict("mini@repair")
            while not HasAnimDictLoaded("mini@repair") do
                Wait(10)
            end
            TaskPlayAnim(startNPC, "mini@repair", "fixing_a_player", 8.0, -8.0, 3000, 1, 0, false, false, false)

            Wait(3000)

            -- Supprimer le carton
            DeleteEntity(box)

            Wait(500)

            -- Recongeler le NPC et le retéléporter immédiatement à sa position
            ClearPedTasks(startNPC)
            SetEntityCoordsNoOffset(startNPC, startNPCPos.x, startNPCPos.y, startNPCPos.z, false, false, false)
            SetEntityHeading(startNPC, startNPCPos.heading or 0.0)
            FreezeEntityPosition(startNPC, true)
            SetBlockingOfNonTemporaryEvents(startNPC, true)
            SetPedCanRagdoll(startNPC, false)

            -- Marquer que l'animation est terminée et ajouter l'item dans le coffre
            CarryingBox = true
            TriggerServerEvent("core:gofast:loadCargo", CurrentMission.missionId)

            -- Débloquer complètement le véhicule
            FreezeEntityPosition(MissionVehicle, false)
            SetVehicleEngineOn(MissionVehicle, false, false, false)
            SetVehicleUndriveable(MissionVehicle, false)
            SetVehicleDoorsLocked(MissionVehicle, 0) -- 0 = Unlocked
            SetVehicleDoorsLockedForAllPlayers(MissionVehicle, false)

            -- Créer le blip de livraison
            local deliveryPos = CurrentMission.deliveryPosition
            DeliveryBlip = AddBlipForCoord(deliveryPos.x, deliveryPos.y, deliveryPos.z)
            SetBlipSprite(DeliveryBlip, 1)
            SetBlipColour(DeliveryBlip, 5)
            SetBlipScale(DeliveryBlip, 0.5)
            SetBlipRoute(DeliveryBlip, true)
            SetBlipRouteColour(DeliveryBlip, 5)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Livraison Go Fast")
            EndTextCommandSetBlipName(DeliveryBlip)

            VFW.ShowNotification({
                type = 'ILLEGAL',
                message = string.format("Marchandise chargée ! Livrez-la pour %s", VFW.Math.FormatMoney(CurrentMission.vehiclePrice))
            })

            -- Démarrer les notifications d'ambiance
            StartAmbientNotifications()
        end)
    end
end)

--- Vérifie qu'un ped existe et n'est pas tombé sous la map / à un Z absurde.
local function IsDeliveryNPCValid(targetPos)
    if not DeliveryNPC or not DoesEntityExist(DeliveryNPC) then return false end
    local npcCoords = GetEntityCoords(DeliveryNPC)
    -- Si le ped est à plus de 5m verticalement de la cible, c'est qu'il est
    -- tombé sous la map ou s'est mal placé.
    if math.abs(npcCoords.z - targetPos.z) > 5.0 then return false end
    return true
end

CreateThread(function()
    while true do
        local sleep = 1000

        if CurrentMission and CurrentMission.deliveryPosition and CarryingBox then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local destPos = CurrentMission.deliveryPosition
            local targetVec = vector3(destPos.x, destPos.y, destPos.z)
            local dist = #(playerCoords - targetVec)

            -- Lazy spawn : créer le PNJ uniquement quand le joueur est à
            -- portée de streaming. Crée aussi un remplaçant si le ped existant
            -- est invalide (tombé sous la map, despawné, etc.).
            if dist < 150.0 and not IsDeliveryNPCValid(destPos) then
                if DeliveryNPC and DoesEntityExist(DeliveryNPC) then
                    DeleteEntity(DeliveryNPC)
                end
                DeliveryNPC = SpawnNPC(destPos, "g_m_y_mexgang_01")
            end

            if dist < 2.5 then
                sleep = 0
                ShowHelp("~INPUT_CONTEXT~ Livrer la marchandise")

                if VFW.Interact.JustPressed(0, 38) then
                    -- Garantir que le PNJ est en place (cas du joueur arrivant
                    -- très vite, avant le tick de lazy spawn).
                    if not IsDeliveryNPCValid(destPos) then
                        if DeliveryNPC and DoesEntityExist(DeliveryNPC) then
                            DeleteEntity(DeliveryNPC)
                        end
                        DeliveryNPC = SpawnNPC(destPos, "g_m_y_mexgang_01")
                    end

                    -- Animation du NPC qui va au coffre chercher le carton
                    local vehicle = MissionVehicle
                    if vehicle and DoesEntityExist(vehicle) and DeliveryNPC and DoesEntityExist(DeliveryNPC) then
                        -- Position directement derrière le véhicule
                        local vehPos = GetEntityCoords(vehicle)
                        local vehHeading = GetEntityHeading(vehicle)

                        -- Calculer la position derrière le véhicule (3 mètres en arrière)
                        local backX = vehPos.x + math.sin(math.rad(vehHeading)) * 3.0
                        local backY = vehPos.y - math.cos(math.rad(vehHeading)) * 3.0
                        local backZ = vehPos.z

                        -- Dégeler le NPC pour qu'il puisse bouger
                        FreezeEntityPosition(DeliveryNPC, false)
                        SetBlockingOfNonTemporaryEvents(DeliveryNPC, true)
                        SetPedCanRagdoll(DeliveryNPC, false)

                        -- Faire marcher le NPC vers le coffre
                        TaskGoToCoordAnyMeans(DeliveryNPC, backX, backY, backZ, 1.0, 0, 0, 786603, 0xbf800000)

                        -- Attendre que le NPC arrive
                        local timeout = 0
                        while timeout < 10000 do
                            local npcPos = GetEntityCoords(DeliveryNPC)
                            local dist = #(npcPos - vector3(backX, backY, backZ))
                            if dist < 1.5 then
                                break
                            end
                            Wait(100)
                            timeout = timeout + 100
                        end

                        -- Orienter le NPC vers le véhicule
                        local headingToVeh = GetHeadingFromVector_2d(vehPos.x - backX, vehPos.y - backY)
                        SetEntityHeading(DeliveryNPC, headingToVeh)

                        Wait(500)

                        -- Animation de prise d'objet (coffre pas ouvert pour éviter sync réseau)
                        RequestAnimDict("mini@repair")
                        while not HasAnimDictLoaded("mini@repair") do
                            Wait(10)
                        end
                        TaskPlayAnim(DeliveryNPC, "mini@repair", "fixing_a_player", 8.0, -8.0, 3000, 1, 0, false, false, false)

                        Wait(3000)

                        -- Charger le modèle de carton
                        local boxModel = GetHashKey("prop_cs_cardbox_01")
                        RequestModel(boxModel)
                        while not HasModelLoaded(boxModel) do
                            Wait(10)
                        end

                        -- Créer le carton et l'attacher au NPC (client-side only comme le PED)
                        local box = CreateObject(boxModel, 0, 0, 0, false, false, false)
                        AttachEntityToEntity(box, DeliveryNPC, GetPedBoneIndex(DeliveryNPC, 28422), 0.0, -0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

                        Wait(500)

                        -- Animation de porter le carton
                        ClearPedTasks(DeliveryNPC)
                        RequestAnimDict("anim@heists@box_carry@")
                        while not HasAnimDictLoaded("anim@heists@box_carry@") do
                            Wait(10)
                        end
                        TaskPlayAnim(DeliveryNPC, "anim@heists@box_carry@", "idle", 8.0, -8.0, 2000, 49, 0, false, false, false)

                        Wait(2000)

                        -- Supprimer le carton et faire un salut
                        DeleteEntity(box)
                        ClearPedTasks(DeliveryNPC)
                        RequestAnimDict("gestures@m@standing@casual")
                        while not HasAnimDictLoaded("gestures@m@standing@casual") do
                            Wait(10)
                        end
                        TaskPlayAnim(DeliveryNPC, "gestures@m@standing@casual", "gesture_hello", 8.0, -8.0, 2000, 0, 0, false, false, false)
                    end

                    Wait(500)
                    TriggerServerEvent("core:gofast:completeMission", CurrentMission.missionId)
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent("core:gofast:missionCompleted")
AddEventHandler("core:gofast:missionCompleted", function(despawnDelay)
    -- Arrêter les notifications
    StopAmbientNotifications()

    if DeliveryBlip then
        RemoveBlip(DeliveryBlip)
        DeliveryBlip = nil
    end

    -- Faire partir le NPC
    if DeliveryNPC and DoesEntityExist(DeliveryNPC) then
        local npcToDelete = DeliveryNPC
        DeliveryNPC = nil

        CreateThread(function()
            -- Dégeler le NPC pour qu'il puisse marcher
            FreezeEntityPosition(npcToDelete, false)
            SetBlockingOfNonTemporaryEvents(npcToDelete, false)

            Wait(500)

            -- Calculer un point de fuite (50m devant le NPC)
            local npcHeading = GetEntityHeading(npcToDelete)
            local npcPos = GetEntityCoords(npcToDelete)
            local escapeX = npcPos.x - math.sin(math.rad(npcHeading)) * 50.0
            local escapeY = npcPos.y + math.cos(math.rad(npcHeading)) * 50.0

            -- Faire marcher le NPC vers le point de fuite
            TaskGoStraightToCoord(npcToDelete, escapeX, escapeY, npcPos.z, 1.0, 35000, npcHeading, 0.5)

            -- Nettoyer après 30 secondes
            Wait(30000)

            if DoesEntityExist(npcToDelete) then
                DeleteEntity(npcToDelete)
            end
        end)
    end

    CurrentMission = nil
    CarryingBox = false

    DespawnTimer = GetGameTimer() + (despawnDelay * 1000)
end)

RegisterNetEvent("core:gofast:missionCanceled")
AddEventHandler("core:gofast:missionCanceled", function(reason)
    -- Arrêter les notifications
    StopAmbientNotifications()

    if DeliveryNPC then
        DeleteEntity(DeliveryNPC)
        DeliveryNPC = nil
    end

    if DeliveryBlip then
        RemoveBlip(DeliveryBlip)
        DeliveryBlip = nil
    end

    -- Si timeout ou véhicule abandonné, utiliser le despawn timer (comme fin de mission)
    if reason == "Temps écoulé" then
        if MissionVehicle and DoesEntityExist(MissionVehicle) then
            DoScreenFadeOut(500)
            Wait(600)
            DeleteEntity(MissionVehicle)
            MissionVehicle = nil
            DoScreenFadeIn(500)
        end
        DespawnTimer = nil
    elseif reason == "Véhicule abandonné" then
        -- Même comportement que la fin de mission : on récupère le véhicule après le délai
        DespawnTimer = GetGameTimer() + (600 * 1000)
    else
        -- Pour les autres raisons, laisser le véhicule pendant 10 minutes
        DespawnTimer = GetGameTimer() + (600 * 1000)
    end

    CurrentMission = nil
    CarryingBox = false
    outsideVehicleWarned = false
end)

CreateThread(function()
    while true do
        Wait(10000)

        if DespawnTimer and GetGameTimer() >= DespawnTimer and MissionVehicle then
            if DoesEntityExist(MissionVehicle) then
                -- Éjecter le joueur si il est dans le véhicule avant de le supprimer
                local playerPed = PlayerPedId()
                if GetVehiclePedIsIn(playerPed, false) == MissionVehicle then
                    TaskLeaveVehicle(playerPed, MissionVehicle, 16)
                    Wait(1500)
                end
                DeleteEntity(MissionVehicle)
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Le véhicule a été récupéré"
                })
            end
            MissionVehicle = nil
            DespawnTimer = nil
        end
    end
end)

RegisterNetEvent("core:gofast:reloadConfig")
AddEventHandler("core:gofast:reloadConfig", function()
    local npcs = TriggerServerCallback("core:gofast:getNPCs") or {}
    NPCData = {}
    for _, npc in ipairs(npcs) do
        NPCData[npc.region] = npc
    end

    -- Supprimer les anciens NPCs pour les respawner aux nouvelles positions
    if NorthNPC then
        DeleteEntity(NorthNPC)
        NorthNPC = nil
    end
    if SouthNPC then
        DeleteEntity(SouthNPC)
        SouthNPC = nil
    end

    -- Respawner aux nouvelles positions
    if NPCData.NORTH and NPCData.NORTH.enabled then
        NorthNPC = SpawnNPC(NPCData.NORTH.position, NPCData.NORTH.model or "g_m_y_mexgang_01")
    end

    if NPCData.SOUTH and NPCData.SOUTH.enabled then
        SouthNPC = SpawnNPC(NPCData.SOUTH.position, NPCData.SOUTH.model or "g_m_y_mexgang_01")
    end
end)

RegisterNUICallback("nui:gofast-menu:select", function(data, cb)
    VFW.Nui.Focus(false)

    if data.region and data.category then
        TriggerServerEvent("core:gofast:startMission", data.region, data.category)
    end

    cb("ok")
end)

RegisterNUICallback("nui:gofast-menu:close", function(data, cb)
    VFW.Nui.Focus(false)
    cb("ok")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if NorthNPC then DeleteEntity(NorthNPC) end
        if SouthNPC then DeleteEntity(SouthNPC) end
        if DeliveryNPC then DeleteEntity(DeliveryNPC) end
        if MissionVehicle then DeleteEntity(MissionVehicle) end
        if DeliveryBlip then RemoveBlip(DeliveryBlip) end
    end
end)
