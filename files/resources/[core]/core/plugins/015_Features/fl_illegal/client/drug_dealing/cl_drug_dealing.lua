VFW.AddChatSuggestion('/' .. Config.DrugDealing.ToggleCommand, 'Activer/Désactiver la vente de drogue')

local DrugDealing = {}
local PlayerSession = {
    enabled = false,
    npcs = {},
    currentMenu = nil,
    isInSale = false,
    blips = {},
    lastInteractionAttempt = 0 -- Anti-spam pour éviter les doubles appels
}

local KeyBinds = {
    interaction = 38 -- Touche E
}

local showUI = false
local uiData = {}

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

local NotificationTypes = {
    success = 'VERT',
    error = 'ROUGE',
    info = 'ILLEGAL'
}

local function ShowNotification(message, type)
    VFW.ShowNotification({
        type = NotificationTypes[type] or 'ILLEGAL',
        message = message
    })
end

local function GetPlayerCoords()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return vector3(coords.x, coords.y, coords.z)
end

local function IsPlayerOnFoot()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle == 0
end

local function GetClosestNPC()
    local playerCoords = GetPlayerCoords()
    local closestNPC = nil
    local closestDistance = Config.DrugDealing.NPCInteractionDistance
    local myServerId = GetPlayerServerId(PlayerId())

    for npcId, npcData in pairs(PlayerSession.npcs) do
        local isMyNPC = npcData.owner == myServerId
        local canInteract = not npcData.interacted and not npcData.interacting

        if isMyNPC and canInteract and npcData.netId and NetworkDoesNetworkIdExist(npcData.netId) then
            local entity = NetworkGetEntityFromNetworkId(npcData.netId)
            if entity ~= 0 and DoesEntityExist(entity) then
                npcData.entity = entity
                local npcCoords = GetEntityCoords(entity)
                local distance = #(playerCoords - npcCoords)

                if distance < closestDistance then
                    closestDistance = distance
                    closestNPC = {id = npcId, data = npcData, distance = distance}
                end
            end
        end
    end

    return closestNPC
end

local function GetCurrentZone()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    return GetNameOfZone(coords.x, coords.y, coords.z)
end

function DrugDealing.ToggleSystem()
    local newState = not PlayerSession.enabled
    local zoneName = GetCurrentZone()

    TriggerServerEvent("core:drugdealing:toggleSystem", newState, zoneName)
end

RegisterNetEvent("core:drugdealing:requestToggleWithZone")
AddEventHandler("core:drugdealing:requestToggleWithZone", function(newState)
    local zoneName = GetCurrentZone()
    TriggerServerEvent("core:drugdealing:toggleSystem", newState, zoneName)
end)

RegisterNetEvent("core:drugdealing:sendNotification")
AddEventHandler("core:drugdealing:sendNotification", function(notification)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({
            type = notification.type,
            content = notification.text
        })
    else
        --print("[DRUG DEALING] " .. notification.text)
    end
end)

-- Thread désactivé: on garde le client même si le joueur sort du territoire
-- Le joueur peut se déplacer librement avec son client actif
-- CreateThread(function()
--     while true do
--         Wait(3000)
--         if PlayerSession.enabled then
--             local playerCoords = GetEntityCoords(PlayerPedId())
--             TriggerServerEvent("core:drugdealing:checkZone", playerCoords.x, playerCoords.y, playerCoords.z)
--         end
--     end
-- end)

-- Event pour synchroniser l'état du système avec le client
RegisterNetEvent("core:drugdealing:setEnabled")
AddEventHandler("core:drugdealing:setEnabled", function(enabled)
    PlayerSession.enabled = enabled
end)

-- Filtre node identique a fl_taxi (IsValidTaxiNode)
local DRUG_HIGHWAY_BIT <const> = 64
local DRUG_BAD_NODE_FLAGS <const> = { [11] = true, [15] = true }

local function IsValidDrugNode(x, y, z, allowRural)
    local success, density, flags = GetVehicleNodeProperties(x, y, z)
    if not success then return false end
    if not allowRural and density < 1 then return false end
    if flags & DRUG_HIGHWAY_BIT ~= 0 then return false end
    if DRUG_BAD_NODE_FLAGS[flags] then return false end
    return true
end

-- Copie exacte de fl_taxi FindRandomPickupNode, centree sur le joueur
local function FindRandomDrugSidewalkPoint(playerCoords, zoneRadius, minDistance)
    for attempt = 1, 30 do
        -- Point aleatoire dans le radius (distribution uniforme avec sqrt) - identique fl_taxi
        local angle = math.random() * 2 * math.pi
        local dist = math.sqrt(math.random()) * zoneRadius
        local x = playerCoords.x + math.cos(angle) * dist
        local y = playerCoords.y + math.sin(angle) * dist

        -- Trouver la route pavee la plus proche puis se placer sur le bord
        local nodeFound, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(x, y, playerCoords.z, 0, 3.0, 0)
        local found = false
        local safeCoords = nil

        if nodeFound and nodePos and nodePos.x ~= 0.0 then
            local sideFound, sidePos = GetRoadSidePointWithHeading(nodePos.x, nodePos.y, nodePos.z, nodeHeading)
            if sideFound and sidePos and sidePos.x ~= 0.0 then
                local headingRad = math.rad(nodeHeading)
                local perpX = -math.cos(headingRad)
                local perpY = math.sin(headingRad)
                local dirX = sidePos.x - nodePos.x
                local dirY = sidePos.y - nodePos.y
                local dot = dirX * perpX + dirY * perpY
                local sign = dot >= 0 and 1 or -1

                -- Scan progressif jusqu'a sortir de la chaussee (gere les routes larges)
                -- + verif que le sol est au niveau du trottoir (pas un toit, balcon, etc)
                for offset = 3.0, 12.0, 1.0 do
                    local cx = sidePos.x + perpX * offset * sign
                    local cy = sidePos.y + perpY * offset * sign
                    -- Force la collision a se charger a cette position (sinon GetGroundZ retourne 0/faux)
                    RequestCollisionAtCoord(cx, cy, sidePos.z)
                    local waitDeadline = GetGameTimer() + 250
                    local groundOk, gz = GetGroundZFor_3dCoord_2(cx, cy, sidePos.z + 5.0, false)
                    while (not groundOk or gz <= 0.5) and GetGameTimer() < waitDeadline do
                        Wait(10)
                        RequestCollisionAtCoord(cx, cy, sidePos.z)
                        groundOk, gz = GetGroundZFor_3dCoord_2(cx, cy, sidePos.z + 5.0, false)
                    end
                    if groundOk and gz > 0.5 and not IsPointOnRoad(cx, cy, gz, 0) then
                        local zAtSidewalkLevel = math.abs(gz - sidePos.z) <= 2.0
                        if zAtSidewalkLevel then
                            safeCoords = vector3(cx, cy, gz)
                            found = true
                            break
                        end
                    end
                end
            end
        end

        if found and safeCoords and safeCoords.x ~= 0.0 and safeCoords.y ~= 0.0 then
            local pos = vector3(safeCoords.x, safeCoords.y, safeCoords.z)
            local distFromCenter = #(vector2(pos.x, pos.y) - vector2(playerCoords.x, playerCoords.y))
            if distFromCenter <= zoneRadius then
                local distFromPlayer = #(vector2(playerCoords.x, playerCoords.y) - vector2(pos.x, pos.y))
                if distFromPlayer >= minDistance and IsValidDrugNode(pos.x, pos.y, pos.z, true) then
                    return pos, nodeHeading
                end
            end
        end
    end
    return nil
end

RegisterNetEvent("core:drugdealing:findSidewalkSpawn")
AddEventHandler("core:drugdealing:findSidewalkSpawn", function(distanceMin, distanceMax)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local minDistance = distanceMin or 200.0
    -- Cap a 400m: au-dela, la collision n'est pas streamee donc GetGroundZ est non fiable (spawn en l'air)
    local zoneRadius = math.min(distanceMax or 400.0, 400.0)

    -- Collecter jusqu'a 10 candidats pour laisser le serveur choisir (territoire + anti-respawn)
    local validPositions = {}
    local seen = {}
    for collect = 1, 10 do
        local pos, nodeHeading = FindRandomDrugSidewalkPoint(playerCoords, zoneRadius, minDistance)
        if not pos then break end

        local key = string.format("%.0f_%.0f", pos.x / 5, pos.y / 5)
        if not seen[key] then
            seen[key] = true
            local pedHeading = (nodeHeading or 0.0) + 90.0
            local groundZ = pos.z
            RequestCollisionAtCoord(pos.x, pos.y, pos.z)
            local foundGround, gz = GetGroundZFor_3dCoord_2(pos.x, pos.y, pos.z + 10.0, false)
            if foundGround and gz > 0.5 then groundZ = gz end

            validPositions[#validPositions + 1] = {
                x = pos.x,
                y = pos.y,
                z = groundZ,
                heading = pedHeading,
                score = math.abs(groundZ - playerCoords.z),
                heightDiff = math.abs(groundZ - playerCoords.z),
            }
        end
    end

    if #validPositions == 0 then
        TriggerServerEvent("core:drugdealing:spawnFailed", "no_valid_position")
        return
    end

    table.sort(validPositions, function(a, b) return a.score < b.score end)
    TriggerServerEvent("core:drugdealing:validateAndSpawn", validPositions)
end)

function DrugDealing.UpdateSessionData(data)
    PlayerSession.enabled = data.enabled
    PlayerSession.totalSales = data.totalSales or 0
    PlayerSession.totalEarnings = data.totalEarnings or 0
    PlayerSession.cooldownRemaining = data.cooldownRemaining or 0
end

-- Demande la network ownership et attend qu'elle soit obtenue (max 2s)
local function RequestControlAndWait(entity, timeoutMs)
    if not entity or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end

    NetworkRequestControlOfEntity(entity)
    local deadline = GetGameTimer() + (timeoutMs or 2000)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
    end
    return NetworkHasControlOfEntity(entity)
end

-- Applique les flags d'invincibilité/freeze/scenario au ped networked
-- Doit être appelé par le client qui a la network ownership (généralement l'owner de la vente)
local function ConfigureNetworkedDrugPed(npc)
    if not npc or not DoesEntityExist(npc) then return end

    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedFleeAttributes(npc, 0, 0)
    SetPedCombatAttributes(npc, 17, true)
    SetPedDiesWhenInjured(npc, false)
    SetPedCanPlayAmbientAnims(npc, true)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetPedCanBeTargetted(npc, false)
    SetPedRelationshipGroupHash(npc, GetHashKey("CIVMALE"))
    SetPedKeepTask(npc, true)
    SetPedCanRagdoll(npc, false)
    SetPedRagdollOnCollision(npc, false)
    SetEntityProofs(npc, true, true, true, true, true, true, true, true)

    TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
end

-- Attend que l'entité netId soit streamée localement, puis exécute callback
-- Utilise un thread non-bloquant car le streaming dépend de la distance joueur<->ped
local function WaitForNetworkedEntity(netId, onReady)
    CreateThread(function()
        local timeout = GetGameTimer() + 30000 -- 30s max d'attente
        while GetGameTimer() < timeout do
            if NetworkDoesNetworkIdExist(netId) then
                local entity = NetworkGetEntityFromNetworkId(netId)
                if entity ~= 0 and DoesEntityExist(entity) then
                    onReady(entity)
                    return
                end
            end
            Wait(500)
        end
    end)
end

function DrugDealing.SpawnNPC(npcId, netId, ownerId)
    if PlayerSession.npcs[npcId] then
        DrugDealing.DespawnNPC(npcId)
    end

    local isOwner = (ownerId == GetPlayerServerId(PlayerId()))

    PlayerSession.npcs[npcId] = {
        entity = 0,
        netId = netId,
        spawnTime = GetGameTimer(),
        interacted = false,
        gpsObjectiveId = nil,
        owner = ownerId
    }

    -- Le streaming GTA matérialise l'entité quand le joueur s'approche
    -- On attend qu'elle soit dispo localement pour la configurer
    WaitForNetworkedEntity(netId, function(entity)
        local npcData = PlayerSession.npcs[npcId]
        if not npcData or npcData.netId ~= netId then return end

        npcData.entity = entity

        -- Owner configure le ped (network ownership l'autorise généralement)
        -- Les flags de scenario/freeze/invincible se propagent via la sync FiveM
        if isOwner then
            RequestControlAndWait(entity)
            -- Force la collision a se charger autour du ped avant PlaceObjectOnGround
            -- sinon le ped reste suspendu en l'air (collision pas streamee a distance)
            local px, py, pz = table.unpack(GetEntityCoords(entity))
            RequestCollisionAtCoord(px, py, pz)
            local deadline = GetGameTimer() + 1000
            while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < deadline do
                Wait(20)
            end
            PlaceObjectOnGroundProperly(entity)
            ConfigureNetworkedDrugPed(entity)

            -- GPS Mission system pour le propriétaire uniquement
            local gpsObjectiveId = "drug_client_" .. npcId
            exports["core"]:SetGPSEntityObjective(gpsObjectiveId, entity, {
                sprite = 140,
                label = "Client",
                color = 2,
                routeColor = 2,
                scale = 0.5,
                sound = false
            })
            npcData.gpsObjectiveId = gpsObjectiveId
        end
    end)

    if isOwner then
        ShowNotification("~g~Client potentiel repéré.\nSuivez le tracé GPS.~s~", "success")
    end
end

function DrugDealing.DespawnNPC(npcId)
    local npcData = PlayerSession.npcs[npcId]
    if not npcData then return end

    -- Supprimer l'objectif GPS via le nouveau système
    if npcData.gpsObjectiveId then
        exports["core"]:RemoveGPSObjective(npcData.gpsObjectiveId, false)
    end

    -- Pas de DeleteEntity ici: c'est le serveur qui supprime le ped networked
    -- (sinon on aurait des suppressions concurrentes par tous les clients)

    local wasMine = npcData.owner == GetPlayerServerId(PlayerId())

    PlayerSession.npcs[npcId] = nil

    if PlayerSession.enabled and wasMine then
        ShowNotification("~o~Client parti.\nUn nouveau va bientôt arriver.~s~", "info")
    end
end

-- ============================================
-- FONCTION HELPER: Faire partir un NPC proprement
-- Utilise TaskWanderStandard avec NavMesh pour éviter les murs
-- ============================================
function DrugDealing.MakeNPCLeave(npcPed, npcId, despawnDelay)
    if not npcPed or not DoesEntityExist(npcPed) then return end

    despawnDelay = despawnDelay or 20000

    -- Acquérir la network ownership pour que les mutations se propagent à tous les clients
    RequestControlAndWait(npcPed)

    -- Configurer la navigation pour éviter les obstacles
    SetBlockingOfNonTemporaryEvents(npcPed, false)
    SetPedPathCanUseClimbovers(npcPed, true)
    SetPedPathCanUseLadders(npcPed, true)
    SetPedPathAvoidFire(npcPed, true)
    SetPedPathPreferToAvoidWater(npcPed, true)

    -- Dégeler et rendre vulnérable
    FreezeEntityPosition(npcPed, false)
    SetEntityInvincible(npcPed, false)
    ClearPedTasks(npcPed)

    -- Marche aléatoire utilisant le NavMesh (évite les murs naturellement)
    TaskWanderStandard(npcPed, 10.0, 10)
    SetPedKeepTask(npcPed, true)

    -- Cleanup local après le délai (le ped networked est supprimé par le serveur via timer)
    SetTimeout(despawnDelay, function()
        if npcId then
            DrugDealing.DespawnNPC(npcId)
        end
    end)
end

function DrugDealing.StartSaleInteraction(npcId)

    -- Vérifier si le joueur est dans un véhicule
    if not IsPlayerOnFoot() then
        VFW.ShowNotification({
            type = "ILLEGAL",
            message = "J'entends rien. Descends de ta caisse."
        })
        return
    end

    -- Anti-spam: éviter les doubles appels rapides
    local currentTime = GetGameTimer()
    if currentTime - PlayerSession.lastInteractionAttempt < 1000 then
        return
    end
    PlayerSession.lastInteractionAttempt = currentTime

    if PlayerSession.isInSale then
        return
    end

    local npcData = PlayerSession.npcs[npcId]
    if not npcData or not npcData.netId or not NetworkDoesNetworkIdExist(npcData.netId) then
        return
    end
    local entity = NetworkGetEntityFromNetworkId(npcData.netId)
    if entity == 0 or not DoesEntityExist(entity) then
        return
    end
    npcData.entity = entity

    PlayerSession.isInSale = true
    PlayerSession.pendingNpcId = npcId

    -- Marquer le NPC comme en cours d'interaction
    npcData.interacting = true

    -- Timeout de sécurité: reset isInSale après 15 secondes si pas de réponse
    SetTimeout(15000, function()
        if PlayerSession.isInSale and PlayerSession.pendingNpcId == npcId then
            PlayerSession.isInSale = false
            PlayerSession.pendingNpcId = nil
            if npcData then
                npcData.interacting = false
            end
            ShowNotification("Erreur de connexion, réessayez.", "error")
        end
    end)

    -- Demander au serveur de traiter la vente automatique
    -- Le serveur va: vérifier les drogues, 25% refus/police, ou vente auto
    TriggerServerEvent("core:drugdealing:startAutoSale", npcId)
end

-- Fonction helper pour attacher un prop à la main d'un ped
local function AttachPropToHand(ped, propModel, isRightHand)
    local propHash = GetHashKey(propModel)
    RequestModel(propHash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(propHash) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(propHash) then
        --print("[DRUG PROP] Failed to load model: " .. propModel)
        return nil
    end

    local prop = CreateObject(propHash, 0.0, 0.0, 0.0, false, true, false)
    if not DoesEntityExist(prop) then
        --print("[DRUG PROP] Failed to create prop: " .. propModel)
        return nil
    end

    -- Config pour l'attachement du sachet (prop_cs_coke_bag - plus petit)
    local offset = vector3(0.0, 0.04, 0.02)
    local rotation = vector3(0.0, 0.0, 0.0)
    local boneTag = 0x6F06 -- Main droite (IK_R_Hand = 28422)

    -- Pour la main gauche, utiliser le bone gauche et inverser l'offset X
    if not isRightHand then
        boneTag = 0xFE7B -- IK_L_Hand (18905)
        offset = vector3(-offset.x, offset.y, offset.z) -- Inverser X pour la main gauche
    end

    local boneIndex = GetPedBoneIndex(ped, boneTag)

    AttachEntityToEntity(
        prop,
        ped,
        boneIndex,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, 0, true
    )

    SetModelAsNoLongerNeeded(propHash)

    return prop
end

-- Fonction pour supprimer un prop proprement
local function DeleteProp(prop)
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end
end

-- Event pour jouer l'animation de vente automatique
RegisterNetEvent("core:drugdealing:playAutoSaleAnimation")
AddEventHandler("core:drugdealing:playAutoSaleAnimation", function(npcId)

    local npcData = PlayerSession.npcs[npcId]
    if not npcData or not npcData.entity or not DoesEntityExist(npcData.entity) then
        return
    end

    local playerPed = PlayerPedId()
    local npcPed = npcData.entity

    -- Créer un thread pour l'animation (non-bloquant)
    CreateThread(function()
        RequestControlAndWait(npcPed)

        -- Faire tourner le PNJ face au joueur (forcer le heading immédiatement)
        local playerCoords = GetEntityCoords(playerPed)
        local npcCoords = GetEntityCoords(npcPed)
        local headingToPlayer = GetHeadingFromVector_2d(playerCoords.x - npcCoords.x, playerCoords.y - npcCoords.y)
        SetEntityHeading(npcPed, headingToPlayer)

        -- Faire tourner le joueur face au PNJ
        TaskTurnPedToFaceEntity(playerPed, npcPed, 1000)
        Wait(500)

        -- Charger les animations
        local dealDict = "mp_common"
        local playerAnim = "givetake1_a" -- Joueur donne
        local npcAnim = "givetake1_b" -- NPC reçoit et donne argent

        RequestAnimDict(dealDict)
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded(dealDict) and GetGameTimer() < timeout do
            Wait(10)
        end

        if HasAnimDictLoaded(dealDict) and DoesEntityExist(npcPed) then
            -- Attacher les props AVANT l'animation
            -- Joueur: petit sachet dans la main droite
            local drugProp = AttachPropToHand(playerPed, "prop_cs_coke_bag", true)
            -- NPC: liasse de billets dans la main droite
            local moneyProp = AttachPropToHand(npcPed, "prop_anim_cash_pile_01", true)

            --print(string.format("[DRUG PROP] Props attached - Drug: %s, Money: %s",
                --tostring(drugProp), tostring(moneyProp)))

            -- Jouer les animations synchronisées
            TaskPlayAnim(playerPed, dealDict, playerAnim, 8.0, -8.0, 3000, 50, 0, false, false, false)
            TaskPlayAnim(npcPed, dealDict, npcAnim, 8.0, -8.0, 3000, 50, 0, false, false, false)

            -- Attendre la fin de l'animation puis supprimer les props
            Wait(3000)

            DeleteProp(drugProp)
            DeleteProp(moneyProp)

            --print("[DRUG PROP] Props cleaned up after animation")
        end
    end)
end)

-- Event quand le PNJ refuse la vente (appelle la police)
RegisterNetEvent("core:drugdealing:npcRefusedSale")
AddEventHandler("core:drugdealing:npcRefusedSale", function(npcId, callsPolice)

    PlayerSession.isInSale = false
    PlayerSession.pendingNpcId = nil

    local npcData = PlayerSession.npcs[npcId]
    if not npcData or not npcData.entity or not DoesEntityExist(npcData.entity) then
        return
    end

    local npcPed = npcData.entity
    npcData.interacting = false
    npcData.interacted = true

    -- Supprimer l'objectif GPS via le nouveau système
    if npcData.gpsObjectiveId then
        exports["core"]:RemoveGPSObjective(npcData.gpsObjectiveId, false)
        npcData.gpsObjectiveId = nil
    end

    CreateThread(function()
        RequestControlAndWait(npcPed)

        -- Dégeler le NPC et enlever les protections
        FreezeEntityPosition(npcPed, false)
        SetEntityInvincible(npcPed, false)
        SetPedCanRagdoll(npcPed, true)
        SetPedCanRagdollFromPlayerImpact(npcPed, true)
        SetPedRagdollOnCollision(npcPed, true)
        SetEntityProofs(npcPed, false, false, false, false, false, false, false, false)
        SetPedCanBeTargetted(npcPed, true)
        ClearPedTasks(npcPed)

        -- Animation de refus (geste "non" de la main)
        RequestAnimDict("gestures@m@standing@casual")
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded("gestures@m@standing@casual") and GetGameTimer() < timeout do
            Wait(10)
        end

        if DoesEntityExist(npcPed) and HasAnimDictLoaded("gestures@m@standing@casual") then
            TaskPlayAnim(npcPed, "gestures@m@standing@casual", "gesture_no_way", 8.0, -8.0, 2000, 49, 0, false, false, false)
            Wait(2000)
        end

        if callsPolice then
            -- Animation d'appel téléphonique
            RequestAnimDict("cellphone@")
            timeout = GetGameTimer() + 3000
            while not HasAnimDictLoaded("cellphone@") and GetGameTimer() < timeout do
                Wait(10)
            end

            if DoesEntityExist(npcPed) and HasAnimDictLoaded("cellphone@") then
                TaskPlayAnim(npcPed, "cellphone@", "cellphone_call_listen_base", 8.0, 8.0, 4000, 1, 0, false, false, false)
                Wait(4000)
            end
        end

        -- Le NPC part en marchant (utilise NavMesh pour éviter les murs)
        if DoesEntityExist(npcPed) then
            DrugDealing.MakeNPCLeave(npcPed, npcId, 20000)
        end
    end)
end)

-- Recevoir le résultat de la vente du serveur
RegisterNetEvent("core:drugdealing:saleResult")
AddEventHandler("core:drugdealing:saleResult", function(npcId, success, saleData)

    PlayerSession.isInSale = false
    PlayerSession.pendingNpcId = nil
    PlayerSession.pendingSaleNpcId = nil
    PlayerSession.pendingSaleDrugType = nil

    local npcData = PlayerSession.npcs[npcId]
    if not npcData then
    end

    if success and saleData then

        -- Marquer le NPC comme ayant interagi (non-interactible)
        if npcData then
            npcData.interacted = true
            npcData.interacting = false
        end

        -- La notification est déjà envoyée par le serveur (sv_drug_dealing.lua)
        -- Pas besoin d'en envoyer une autre ici
    else
        if npcData then
            npcData.interacting = false
        end
    end
end)

function DrugDealing.UpdateUI()
    if not showUI then return end

    local sessionData = TriggerServerCallback("core:drugdealing:getSessionData")
    if sessionData then
        DrugDealing.UpdateSessionData(sessionData)
    end

    local closestNPC = GetClosestNPC()

    uiData = {
        enabled = PlayerSession.enabled,
        canInteract = closestNPC ~= nil and not PlayerSession.isInSale,
        npcDistance = closestNPC and closestNPC.distance or 999,
        totalSales = PlayerSession.totalSales,
        totalEarnings = PlayerSession.totalEarnings,
        cooldownRemaining = PlayerSession.cooldownRemaining,
        activeNPCs = 0
    }

    for _, _ in pairs(PlayerSession.npcs) do
        uiData.activeNPCs = uiData.activeNPCs + 1
    end

    SendNUIMessage({
        action = "updateDrugDealing",
        data = uiData
    })
end

function DrugDealing.ToggleUI()
    showUI = not showUI

    if showUI then
        VFW.Nui.Focus(true)
        DrugDealing.UpdateUI()
    else
        VFW.Nui.Focus(false)
    end

    SendNUIMessage({
        action = "toggleDrugDealingUI",
        show = showUI
    })
end

function DrugDealing.OpenAdminMenu()
    local hasPermission = TriggerServerCallback("core:drugdealing:admin:hasPermission")
    if not hasPermission then
        ShowNotification("Accès refusé.", "error")
        return
    end

    TriggerServerEvent("core:drugdealing:admin:getSettings")
    TriggerServerEvent("core:drugdealing:admin:getZones")
    TriggerServerEvent("core:drugdealing:admin:getStatistics", "today")

    SendNUIMessage({
        action = "openAdminMenu"
    })

    VFW.Nui.Focus(true)
end

RegisterNetEvent("core:drugdealing:spawnNPC")
AddEventHandler("core:drugdealing:spawnNPC", function(npcId, netId, ownerId)
    DrugDealing.SpawnNPC(npcId, netId, ownerId)
end)

RegisterNetEvent("core:drugdealing:despawnNPC")
AddEventHandler("core:drugdealing:despawnNPC", function(npcId)
    DrugDealing.DespawnNPC(npcId)
end)

RegisterNetEvent("core:drugdealing:npcLeaving")
AddEventHandler("core:drugdealing:npcLeaving", function(npcId)

    local npcData = PlayerSession.npcs[npcId]
    if not npcData then
        return
    end

    if not npcData.entity or not DoesEntityExist(npcData.entity) then
        return
    end

    local npcPed = npcData.entity

    -- Marquer comme ayant interagi
    npcData.interacted = true

    -- Supprimer l'objectif GPS via le nouveau système + son de succès
    if npcData.gpsObjectiveId then
        -- Son désactivé
        exports["core"]:RemoveGPSObjective(npcData.gpsObjectiveId, false)
        npcData.gpsObjectiveId = nil
    end

    -- Lancer le départ dans un thread séparé
    local currentNpcId = npcId
    CreateThread(function()
        RequestControlAndWait(npcPed)

        -- Dégeler le NPC et enlever les protections pour qu'il puisse partir
        FreezeEntityPosition(npcPed, false)
        SetEntityInvincible(npcPed, false)
        SetPedCanRagdoll(npcPed, true)
        SetPedCanRagdollFromPlayerImpact(npcPed, true)
        SetPedRagdollOnCollision(npcPed, true)
        SetEntityProofs(npcPed, false, false, false, false, false, false, false, false)
        SetPedCanBeTargetted(npcPed, true)
        ClearPedTasks(npcPed)

        -- Animation de "ok/merci"
        RequestAnimDict("gestures@m@standing@casual")
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded("gestures@m@standing@casual") and GetGameTimer() < timeout do
            Wait(10)
        end

        if DoesEntityExist(npcPed) and HasAnimDictLoaded("gestures@m@standing@casual") then
            TaskPlayAnim(npcPed, "gestures@m@standing@casual", "gesture_bye_soft", 8.0, -8.0, 1500, 49, 0, false, false, false)
            Wait(1500)
        end

        if not DoesEntityExist(npcPed) then
            return
        end

        -- Le NPC part en marchant (utilise NavMesh pour éviter les murs)
        DrugDealing.MakeNPCLeave(npcPed, currentNpcId, 25000)
    end)
end)

RegisterNetEvent("core:drugdealing:npcRefusal")
AddEventHandler("core:drugdealing:npcRefusal", function(npcId)
    local npcData = PlayerSession.npcs[npcId]
    if not npcData or not npcData.entity or not DoesEntityExist(npcData.entity) then
        return
    end

    local npcPed = npcData.entity
    RequestControlAndWait(npcPed)

    -- Enlever les protections
    FreezeEntityPosition(npcPed, false)
    SetEntityInvincible(npcPed, false)
    SetPedCanRagdoll(npcPed, true)
    SetPedCanRagdollFromPlayerImpact(npcPed, true)
    SetPedRagdollOnCollision(npcPed, true)
    SetEntityProofs(npcPed, false, false, false, false, false, false, false, false)
    SetPedCanBeTargetted(npcPed, true)
    ClearPedTasks(npcPed)

    -- 50% de chance d'appeler les flics
    local shouldCallPolice = math.random(1, 2) == 1

    if shouldCallPolice then
        -- Animation d'appel téléphonique
        RequestAnimDict("cellphone@")
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded("cellphone@") and GetGameTimer() < timeout do
            Wait(10)
        end

        if HasAnimDictLoaded("cellphone@") then
            TaskPlayAnim(npcPed, "cellphone@", "cellphone_call_listen_base", 8.0, 8.0, 3000, 1, 0, false, false, false)
        end

        -- Après 3 secondes, il part (utilise NavMesh pour éviter les murs)
        SetTimeout(3000, function()
            if DoesEntityExist(npcPed) then
                DrugDealing.MakeNPCLeave(npcPed, npcId, 20000)
            end
        end)
    else
        -- Part directement (utilise NavMesh pour éviter les murs)
        DrugDealing.MakeNPCLeave(npcPed, npcId, 20000)
    end
end)

RegisterNetEvent("core:drugdealing:openAdminMenu")
AddEventHandler("core:drugdealing:openAdminMenu", function()
    DrugDealing.OpenAdminMenu()
end)

RegisterNetEvent("core:drugdealing:admin:settingsData")
AddEventHandler("core:drugdealing:admin:settingsData", function(settings, prices)
    SendNUIMessage({
        action = "updateAdminSettings",
        settings = settings,
        prices = prices
    })
end)

RegisterNetEvent("core:drugdealing:admin:zonesData")
AddEventHandler("core:drugdealing:admin:zonesData", function(zones)
    SendNUIMessage({
        action = "updateAdminZones",
        zones = zones
    })
end)

RegisterNetEvent("core:drugdealing:admin:statisticsData")
AddEventHandler("core:drugdealing:admin:statisticsData", function(statistics, recentSales)
    SendNUIMessage({
        action = "updateAdminStatistics",
        statistics = statistics,
        recentSales = recentSales
    })
end)

RegisterNUICallback("toggleSystem", function(data, cb)
    DrugDealing.ToggleSystem()
    cb("ok")
end)

RegisterNUICallback("closeUI", function(data, cb)
    showUI = false
    VFW.Nui.Focus(false)
    cb("ok")
end)

RegisterNUICallback("adminUpdateSetting", function(data, cb)
    TriggerServerEvent("core:drugdealing:admin:updateSetting", data.key, data.value)
    cb("ok")
end)

-- Thread "Vente active" supprimé - le tracé GPS sur la minimap suffit

CreateThread(function()
    while true do
        local sleep = 1000
        local myServerId = GetPlayerServerId(PlayerId())

        -- Compter les NPCs qui m'appartiennent
        local myNpcCount = 0
        for npcId, npcData in pairs(PlayerSession.npcs) do
            if npcData.owner == myServerId then
                myNpcCount = myNpcCount + 1
            end
        end

        -- Si j'ai des NPCs OU que le système est enabled, réduire le sleep
        if PlayerSession.enabled or myNpcCount > 0 then
            sleep = 100

            -- Vérifier la mort des NPCs (seulement mes NPCs)
            -- L'entité peut s'être (re)streamée depuis le spawn: re-résoudre via netId
            for npcId, npcData in pairs(PlayerSession.npcs) do
                if npcData.owner == myServerId and npcData.netId then
                    if NetworkDoesNetworkIdExist(npcData.netId) then
                        local entity = NetworkGetEntityFromNetworkId(npcData.netId)
                        if entity ~= 0 and DoesEntityExist(entity) then
                            npcData.entity = entity
                            if IsPedDeadOrDying(entity, true) then
                                TriggerServerEvent("core:drugdealing:npcKilled", npcId)
                                DrugDealing.DespawnNPC(npcId)
                            end
                        end
                    end
                end
            end

            -- Chercher le NPC le plus proche (GetClosestNPC vérifie déjà l'owner)
            local closestNPC = GetClosestNPC()

            -- Permettre interaction si NPC proche (sans marker visuel)
            if closestNPC and not PlayerSession.isInSale then
                sleep = 0

                -- Afficher le bon message selon si le joueur est à pied ou en voiture
                if IsPlayerOnFoot() then
                    ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour vendre de la drogue")
                else
                    ShowHelp("~r~Descends de ta voiture pour vendre~s~")
                end

                if IsControlJustPressed(0, KeyBinds.interaction) then
                        --closestNPC.id, tostring(PlayerSession.enabled)))
                    DrugDealing.StartSaleInteraction(closestNPC.id)
                end
            end
        end

        if showUI and GetGameTimer() % 2000 < 100 then
            DrugDealing.UpdateUI()
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(5000)
    local npcs = TriggerServerCallback("core:drugdealing:getAllNPCs")
    if npcs then
        for npcId, npcData in pairs(npcs) do
            if npcData.netId then
                DrugDealing.SpawnNPC(npcId, npcData.netId, npcData.owner)
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for npcId, _ in pairs(PlayerSession.npcs) do
        DrugDealing.DespawnNPC(npcId)
    end

    if showUI then
        VFW.Nui.Focus(false)
    end
end)

exports("ToggleDrugDealing", DrugDealing.ToggleSystem)
exports("GetPlayerDrugSession", function() return PlayerSession end)
