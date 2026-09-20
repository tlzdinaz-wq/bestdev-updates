-- ========================================================================
-- AFK ZONE CLIENT
-- Handles AFK zone teleportation, confinement, and leaderboard NPCs
-- ========================================================================

local isInAFK = false
VFW_IsInAFK = false -- Global flag for status manager (prevent hunger/thirst loss in AFK)
local afkPoints = 0
local leaderboardNPCs = {}
local leaderboardData = {}  -- Store leaderboard data for DrawText3D
local podiumProp = nil
local exitNPC = nil
local confinementThread = nil
local afkIdleCamDisabled = false

-- ========================================================================
-- HELPER FUNCTIONS
-- ========================================================================

local function CanEnterAFK()
    local ped = PlayerPedId()

    -- Check if in vehicle
    if AFKConfig.Restrictions.noVehicle and IsPedInAnyVehicle(ped, false) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Impossible d'entrer en AFK dans un véhicule"
        })
        return false
    end

    -- Check if cuffed
    if AFKConfig.Restrictions.noCuffed then
        if LocalPlayer.state.isCuffed then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Impossible d'entrer en AFK en étant menotté"
            })
            return false
        end
    end

    -- Check if in safe zone (REQUIRED to enter AFK - Redside behavior)
    if AFKConfig.Restrictions.requireSafeZone then
        if not VFW.GetSafeZone or not VFW.GetSafeZone() then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous devez être en zone sécurisée pour entrer en AFK"
            })
            return false
        end
    end

    -- Check if dead/ragdoll
    if IsPedDeadOrDying(ped, false) or IsPedRagdoll(ped) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Impossible d'entrer en AFK dans cet état"
        })
        return false
    end

    return true
end

-- Draw 3D text function
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        SetTextScale(0.0, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Delete all leaderboard NPCs and podium
local function CleanupLeaderboardNPCs()
    for i, npc in pairs(leaderboardNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    leaderboardNPCs = {}
    leaderboardData = {}

    -- Cleanup podium
    if podiumProp and DoesEntityExist(podiumProp) then
        DeleteEntity(podiumProp)
        podiumProp = nil
    end
end

-- Cleanup exit NPC
local function CleanupExitNPC()
    if exitNPC and DoesEntityExist(exitNPC) then
        DeleteEntity(exitNPC)
        exitNPC = nil
    end
end

-- Spawn podium prop
local function SpawnPodium()
    if not AFKConfig.Leaderboard.podium then return end

    local podiumCfg = AFKConfig.Leaderboard.podium
    local model = GetHashKey(podiumCfg.model)

    VFW.Streaming.RequestModel(model)

    podiumProp = CreateObject(model, podiumCfg.position.x, podiumCfg.position.y, podiumCfg.position.z, false, false, false)
    SetEntityRotation(podiumProp, podiumCfg.rotation.x, podiumCfg.rotation.y, podiumCfg.rotation.z, 2, true)

    -- Placer le podium correctement au sol
    PlaceObjectOnGroundProperly(podiumProp)

    FreezeEntityPosition(podiumProp, true)
    SetEntityCollision(podiumProp, true, true)

    SetModelAsNoLongerNeeded(model)
end

-- Spawn exit NPC
local function SpawnExitNPC()
    if not AFKConfig.ExitNPC then return end

    local cfg = AFKConfig.ExitNPC
    local model = GetHashKey(cfg.model)

    VFW.Streaming.RequestModel(model)

    exitNPC = CreatePed(4, model, cfg.position.x, cfg.position.y, cfg.position.z, cfg.heading, false, true)

    if DoesEntityExist(exitNPC) then
        -- Attendre que le ped soit complètement chargé
        Wait(100)

        -- Obtenir la position Z correcte au sol
        local groundZ = cfg.position.z
        local found, z = GetGroundZFor_3dCoord(cfg.position.x, cfg.position.y, cfg.position.z + 2.0, false)
        if found then
            groundZ = z
        end

        -- Repositionner le ped au niveau du sol
        SetEntityCoords(exitNPC, cfg.position.x, cfg.position.y, groundZ, false, false, false, false)
        SetEntityHeading(exitNPC, cfg.heading)

        FreezeEntityPosition(exitNPC, true)
        SetEntityInvincible(exitNPC, true)
        SetBlockingOfNonTemporaryEvents(exitNPC, true)
        SetPedCanRagdoll(exitNPC, false)
        TaskStartScenarioInPlace(exitNPC, "WORLD_HUMAN_CLIPBOARD", 0, true)
    end

    SetModelAsNoLongerNeeded(model)
end

-- Spawn leaderboard NPCs on podium
local function SpawnLeaderboardNPCs(leaderboard)
    if not AFKConfig.Leaderboard.enabled then return end

    CleanupLeaderboardNPCs()

    -- Store leaderboard data for DrawText3D
    leaderboardData = leaderboard

    -- Spawn podium first
    SpawnPodium()

    -- Delay to let podium spawn and collision load
    Wait(500)

    for i, entry in ipairs(leaderboard) do
        local npcConfig = AFKConfig.Leaderboard.npcPositions[i]
        if npcConfig then
            local pos = npcConfig.position
            local heading = npcConfig.heading

            -- Parse skin data if available
            local skinData = nil
            if entry.skin then
                if type(entry.skin) == "string" then
                    skinData = json.decode(entry.skin)
                else
                    skinData = entry.skin
                end
            end

            CreateThread(function()
                local npc

                if skinData and skinData.sex ~= nil then
                    -- Use VFW.CreatePlayerClone for player skins
                    npc = VFW.CreatePlayerClone(skinData, {}, pos, heading)
                else
                    -- Use default NPC model
                    local model = GetHashKey(AFKConfig.Leaderboard.defaultModel)
                    VFW.Streaming.RequestModel(model)
                    npc = CreatePed(4, model, pos.x, pos.y, pos.z, heading, false, true)
                    SetModelAsNoLongerNeeded(model)
                end

                if DoesEntityExist(npc) then
                    -- Attendre que le ped soit complètement chargé
                    Wait(100)

                    -- Obtenir la position Z correcte au sol
                    local groundZ = pos.z
                    local found, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)
                    if found then
                        groundZ = z
                    end

                    -- Repositionner le ped au niveau du sol
                    SetEntityCoords(npc, pos.x, pos.y, groundZ, false, false, false, false)
                    SetEntityHeading(npc, heading)

                    -- Configure NPC
                    SetEntityInvincible(npc, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    FreezeEntityPosition(npc, true)
                    SetPedCanRagdoll(npc, false)

                    -- Play upper body animation based on rank
                    local rankAnimations = {
                        [1] = { dict = "anim@mp_player_intcelebrationmale@slow_clap", anim = "slow_clap" },      -- 1st: Slow clap celebration
                        [2] = { dict = "mp_player_int_upperthumbsup", anim = "mp_player_int_thumbs_up" },        -- 2nd: Thumbs up
                        [3] = { dict = "amb@world_human_hang_out_street@male_c@idle_a", anim = "idle_b" }        -- 3rd: Crossed arms
                    }
                    local animData = rankAnimations[i] or rankAnimations[3]

                    -- Load animation dictionary
                    RequestAnimDict(animData.dict)
                    local timeout = 0
                    while not HasAnimDictLoaded(animData.dict) and timeout < 50 do
                        Wait(10)
                        timeout = timeout + 1
                    end

                    -- Play animation (flag 49 = upper body only + loop)
                    if HasAnimDictLoaded(animData.dict) then
                        TaskPlayAnim(npc, animData.dict, animData.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
                    end

                    leaderboardNPCs[i] = npc
                end
            end)
        end
    end
end

-- Start confinement loop
local function StartConfinementLoop()
    if confinementThread then return end

    confinementThread = CreateThread(function()
        local afkPos = AFKConfig.Position.coords
        local boundaryRadius = AFKConfig.Position.boundaryRadius
        local exitNpcRadius = AFKConfig.ExitNPC and AFKConfig.ExitNPC.interactionRadius or 2.0
        local showingExitPrompt = false

        while isInAFK do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Check if player is too far from AFK zone
            local distance = #(coords - afkPos)
            if distance > boundaryRadius then
                -- Staff en noclip qui quitte la zone: sortie propre vers le
                -- point d'entrée plutôt que TP au centre (la cellule de
                -- confinement n'a aucun sens si le staff peut traverser).
                if VFW.IsNoclipActive and VFW.IsNoclipActive() then
                    TriggerServerEvent('core:afk:exit')
                else
                    SetEntityCoords(ped, afkPos.x, afkPos.y, afkPos.z, false, false, false, true)
                    SetEntityHeading(ped, AFKConfig.Position.heading)

                    VFW.ShowNotification({
                        type = 'ORANGE',
                        content = "Vous ne pouvez pas quitter la zone AFK"
                    })
                end
            end

            -- Check exit NPC interaction
            if exitNPC and DoesEntityExist(exitNPC) then
                local exitNpcCoords = GetEntityCoords(exitNPC)
                local distToExit = #(coords - exitNpcCoords)

                if distToExit < exitNpcRadius then
                    -- Show prompt
                    showingExitPrompt = true
                    DrawText3D(exitNpcCoords.x, exitNpcCoords.y, exitNpcCoords.z + 1.0, "~g~[E]~w~ Quitter la zone AFK")

                    if VFW.Interact.JustPressed(0, 38) then -- E key
                        TriggerServerEvent('core:afk:exit')
                    end
                else
                    showingExitPrompt = false
                end
            end

            -- Draw points above leaderboard NPCs
            for i, npc in pairs(leaderboardNPCs) do
                if DoesEntityExist(npc) and leaderboardData[i] then
                    local npcPos = GetEntityCoords(npc)
                    local pointsText = tostring(leaderboardData[i].points) .. " points"
                    local nameText = leaderboardData[i].name or "Joueur Inconnu"
                    DrawText3D(npcPos.x, npcPos.y, npcPos.z + 1.2, "~y~#" .. i .. "~w~ " .. nameText)
                    DrawText3D(npcPos.x, npcPos.y, npcPos.z + 1.0, "~g~" .. pointsText)
                end
            end

            Wait(0)
        end

        confinementThread = nil
    end)
end

-- Stop confinement loop
local function StopConfinementLoop()
    isInAFK = false
    VFW_IsInAFK = false
    -- Thread will exit on next iteration
end

-- ========================================================================
-- COMMANDS
-- ========================================================================

TriggerEvent('chat:addSuggestion', '/afk', 'Permet de rejoindre la Zone AFK [Requis : être en zone AFK].')
TriggerEvent('chat:addSuggestion', '/afkstatus', 'Voir le nombre de joueurs en zone AFK')
TriggerEvent('chat:addSuggestion', '/afkremove', 'Retirer un joueur de la zone AFK', {{ name = 'id', help = 'ID du joueur' }})
TriggerEvent('chat:addSuggestion', '/giveafkpoints', 'Donner des points AFK à un joueur', {{ name = 'id', help = 'ID du joueur' }, { name = 'montant', help = 'Nombre de points' }})

RegisterCommand('afk', function()
    if isInAFK then
        -- Cannot exit via command - must use NPC
        VFW.ShowNotification({
            type = 'ORANGE',
            content = "Utilisez le NPC pour quitter la zone AFK"
        })
        return
    end

    -- Check restrictions first
    if not CanEnterAFK() then
        return
    end

    -- Get current position and send to server
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    TriggerServerEvent('core:afk:enterWithPosition', coords, heading)
end, false)

-- ========================================================================
-- EVENTS
-- ========================================================================

-- Server triggers this when player should enter AFK
RegisterNetEvent('core:afk:triggerEnter', function()
    if isInAFK then return end

    -- Check restrictions
    if not CanEnterAFK() then
        return
    end

    -- Get current position and send to server
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    TriggerServerEvent('core:afk:enterWithPosition', coords, heading)
end)

-- Server triggers this when player should exit AFK (admin force exit only)
RegisterNetEvent('core:afk:triggerExit', function()
    if not isInAFK then return end
    TriggerServerEvent('core:afk:exit')
end)

-- Player successfully entered AFK zone
RegisterNetEvent('core:afk:entered', function(data)
    isInAFK = true
    VFW_IsInAFK = true
    afkPoints = data.points or 0

    local ped = PlayerPedId()
    local pos = data.position

    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)

    -- Load the Doomsday Facility interior (required for AFK zone)
    local iplName = "xm_x17dlc_int_placement_interior_33_x17dlc_int_02_milo_"
    RequestIpl(iplName)

    -- Small wait for IPL
    Wait(100)

    -- Get interior at target coords
    local interiorId = GetInteriorAtCoords(pos.x, pos.y, pos.z)

    if interiorId ~= 0 and interiorId ~= -1 then
        PinInteriorInMemory(interiorId)

        -- Wait for interior to be ready
        local timeout = 0
        while not IsInteriorReady(interiorId) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
    end

    -- Teleport to AFK zone
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    Wait(100)
    SetEntityHeading(ped, data.heading)

    -- Wait for position to settle
    Wait(500)

    -- Fade in
    DoScreenFadeIn(500)

    -- Spawn exit NPC
    SpawnExitNPC()

    -- Spawn leaderboard NPCs on podium
    if data.leaderboard then
        SpawnLeaderboardNPCs(data.leaderboard)
    end

    -- Désactiver la caméra idle automatiquement en zone AFK
    afkIdleCamDisabled = true
    DisableIdleCamera(true)
    CreateThread(function()
        while afkIdleCamDisabled do
            Wait(5000)
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()
        end
    end)

    -- Start confinement loop (also handles DrawText3D for points and exit NPC)
    StartConfinementLoop()

end)

-- Player exited AFK zone
RegisterNetEvent('core:afk:exited', function(data)
    StopConfinementLoop()
    isInAFK = false
    VFW_IsInAFK = false

    afkIdleCamDisabled = false

    -- Cleanup NPCs and podium
    CleanupLeaderboardNPCs()
    CleanupExitNPC()

    local ped = PlayerPedId()

    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)

    -- Teleport back to previous position
    if data.previousCoords then
        local coords = data.previousCoords
        if type(coords) == 'table' and not coords.x then
            coords = vector3(coords[1] or coords.x, coords[2] or coords.y, coords[3] or coords.z)
        end
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityHeading(ped, data.previousHeading or 0.0)
    end

    -- Wait for position to settle
    Wait(500)

    -- Fade in
    DoScreenFadeIn(500)

    if not data.forcedExit then
        afkPoints = data.totalPoints or 0
    end
end)

-- Points update from server
RegisterNetEvent('core:afk:updatePoints', function(totalPoints, pointsEarned)
    afkPoints = totalPoints

    -- Show notification for points earned
    VFW.ShowNotification({
        type = 'VERT',
        content = string.format("+%d point%s AFK (Total: %d)", pointsEarned, pointsEarned > 1 and "s" or "", totalPoints)
    })
end)

-- ========================================================================
-- CALLBACKS
-- ========================================================================

-- Note: Player position is sent directly via core:afk:enterWithPosition event

-- ========================================================================
-- EXPORTS
-- ========================================================================

exports('IsInAFKZone', function()
    return isInAFK
end)

exports('GetAFKPoints', function()
    return afkPoints
end)

-- ========================================================================
-- CLEANUP ON RESOURCE STOP
-- ========================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Cleanup NPCs and podium
    CleanupLeaderboardNPCs()
    CleanupExitNPC()
end)

-- ========================================================================
-- INITIALIZATION
-- ========================================================================

-- Disable idle camera globally by default (respects /idle command toggle)
_G.IdleCamEnabled = false
DisableIdleCamera(true)

CreateThread(function()
    while true do
        Wait(5000)
        if not _G.IdleCamEnabled then
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()
        end
    end
end)

