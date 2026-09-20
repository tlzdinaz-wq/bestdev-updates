-- ====================================================================
-- Phase-locked emote sync
-- --------------------------------------------------------------------
-- All clients track every player's emote in `phaseTracked` keyed by
-- server id. Each entry stores the server-stamped startedAt + duration.
-- A periodic thread converts that to a local-clock target via
-- `serverClockOffset` and applies SetEntityAnimCurrentTime to keep every
-- ped phase-locked to the same server-clock origin, regardless of how
-- many observers there are or who copied who.
-- ====================================================================

phaseTracked = phaseTracked or {}
-- localGameTimer + serverClockOffset == server GetGameTimer()
serverClockOffset = serverClockOffset or 0
local clockSamples = 0

local function updateServerClockOffset(serverNow)
    local sample = serverNow - GetGameTimer()
    if clockSamples == 0 then
        serverClockOffset = sample
    else
        -- Lightweight EMA so a single laggy packet doesn't skew the clock.
        serverClockOffset = math.floor(serverClockOffset * 0.8 + sample * 0.2)
    end
    clockSamples = clockSamples + 1
end

RegisterNetEvent("vfw:newanim:phaseBroadcast", function(src, animDict, animName, startedAt, duration, serverNow)
    if type(src) ~= "number" or type(animDict) ~= "string" or type(animName) ~= "string" then
        return
    end
    updateServerClockOffset(serverNow)
    phaseTracked[src] = {
        animDict = animDict,
        animName = animName,
        startedAt = startedAt,
        duration = duration,
    }
end)

RegisterNetEvent("vfw:newanim:phaseClear", function(src)
    if phaseTracked[src] then
        phaseTracked[src] = nil
    end
end)

-- Periodic phase-lock loop. Every tick we look at every tracked emote,
-- find the corresponding ped, and if it's playing the expected anim we
-- override its current time with the phase derived from the shared
-- server clock. This is what keeps every viewer's view of every player
-- synchronized to the same beat.
CreateThread(function()
    while true do
        Wait(500)
        if next(phaseTracked) ~= nil then
            local serverNow = GetGameTimer() + serverClockOffset
            for src, entry in pairs(phaseTracked) do
                local elapsed = serverNow - entry.startedAt
                if elapsed >= 0 and entry.duration > 0 then
                    local phase = (elapsed % entry.duration) / entry.duration
                    if phase < 0 then phase = 0 end
                    if phase > 1 then phase = 1 end
                    local plyId = GetPlayerFromServerId(src)
                    if plyId ~= -1 then
                        local ped = GetPlayerPed(plyId)
                        if ped and ped ~= 0 and DoesEntityExist(ped) then
                            if IsEntityPlayingAnim(ped, entry.animDict, entry.animName, 3) then
                                SetEntityAnimCurrentTime(ped, entry.animDict, entry.animName, phase)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Pull the current phase snapshot when joining so already-running emotes
-- are immediately phase-locked instead of waiting for the next broadcast.
CreateThread(function()
    while not (VFW and VFW.PlayerData and VFW.PlayerData.ped) do
        Wait(500)
    end
    Wait(2000)
    local snapshot = TriggerServerCallback("vfw:newanim:phaseSnapshot")
    if snapshot and snapshot.entries then
        updateServerClockOffset(snapshot.serverNow)
        for _, entry in ipairs(snapshot.entries) do
            phaseTracked[entry.src] = {
                animDict = entry.animDict,
                animName = entry.animName,
                startedAt = entry.startedAt,
                duration = entry.duration,
            }
        end
    end
end)

RegisterNetEvent("vfw:newanim:forceCancel")
AddEventHandler("vfw:newanim:forceCancel", function()
    -- Server cleanup for props
    TriggerServerEvent("vfw:newanim:deleteAllProps")

    -- Reset shared emote tracking
    targetPlayerId = nil

    -- Stopper le carry AVANT EmoteCancel pour eviter la course :
    -- ClearPedTasks (dans EmoteCancel) tue la TaskPlayAnim du carry,
    -- la boucle carry.lua la reapplique a la frame suivante alors que
    -- le ped sort d'un scenario sit -> fenetre de clip-floor.
    if (VFW.IsCarrying and VFW.IsCarrying()) or (VFW.IsBeingCarried and VFW.IsBeingCarried()) then
        if VFW.StopCarrying then
            VFW.StopCarrying()
        end
    end

    -- EmoteCancel handles detach + cleanup + ClearPedTasks
    EmoteCancel()
end)

---@param ask any
---@param askName string
---@param emote any
--RegisterNetEvent("vfw:newanim:askShared", function(ask, askName, emote)
--    local choice = false
--    VFW.ShowNotification({
--        title = "ANIMATION  ",
--        mainMessage = askName .. " : " .. emote,
--        type = "INVITE_NOTIFICATION",
--        duration = 30
--    })
--    CreateThread(function()
--        while not choice do
--            Wait(0)
--            if IsControlJustPressed(0, 246) then
--                TriggerServerEvent("vfw:newanim:acceptShared", ask, emote)
--                choice = true
--                VFW.RemoveNotification()
--            elseif IsControlJustPressed(0, 249) then
--                TriggerServerEvent("vfw:newanim:refuseShared", ask)
--                choice = true
--                VFW.RemoveNotification()
--            end
--        end
--    end)
--end)
---@param ask any
---@param askName string
---@param emote any
RegisterNetEvent("vfw:newanim:askShared", function(ask, askName, emote)
    local choice = false

    -- Buscamos el nombre real (Label) en la tabla de configuraciones
    local displayLabel = emote -- Por defecto el nombre técnico
    if RP.Shared[emote] and RP.Shared[emote][3] then
        displayLabel = RP.Shared[emote][3] -- Normalmente el índice [3] es el Label en dpEmotes/RP
    end

    VFW.ShowNotification({
        title = "ANIMATION",
        -- Ahora usamos displayLabel en lugar de emote
        mainMessage = askName .. " : " .. displayLabel,
        type = "INVITE_NOTIFICATION",
        duration = 30
    })

    CreateThread(function()
        while not choice do
            Wait(0)
            if IsControlJustPressed(0, 246) then -- Y
                TriggerServerEvent("vfw:newanim:acceptShared", ask, emote)
                choice = true
                VFW.RemoveNotification()
            elseif IsControlJustPressed(0, 249) then -- N
                TriggerServerEvent("vfw:newanim:refuseShared", ask)
                choice = true
                VFW.RemoveNotification()
            end
        end
    end)
end)

-- Version améliorée pour le context menu
---@param askerId number Server ID du demandeur
---@param askerName string Nom du demandeur
---@param emote string Nom technique de l'emote
---@param displayName string Nom affiché de l'emote
RegisterNetEvent("vfw:newanim:askSharedContext", function(askerId, askerName, emote, displayName)
    local choice = false
    local timeout = 30 -- secondes

    VFW.ShowNotification({
        title = "🤝 DEMANDE D'ANIMATION",
        mainMessage = askerName .. " veut faire : " .. displayName,
        secondaryMessage = "[Y] Accepter  •  [N] Refuser",
        type = "INVITE_NOTIFICATION",
        duration = timeout
    })

    CreateThread(function()
        local startTime = GetGameTimer()
        while not choice do
            Wait(0)

            -- Timeout après 30 secondes
            if GetGameTimer() - startTime > timeout * 1000 then
                VFW.RemoveNotification()
                TriggerServerEvent("vfw:newanim:refuseShared", askerId)
                VFW.ShowNotification({ type = 'ORANGE', content = "Demande d'animation expirée" })
                break
            end

            if IsControlJustPressed(0, 246) then -- Y
                TriggerServerEvent("vfw:newanim:acceptShared", askerId, emote)
                choice = true
                VFW.RemoveNotification()
                VFW.ShowNotification({ type = 'VERT', content = "Animation acceptée !" })
            elseif IsControlJustPressed(0, 249) then -- N
                TriggerServerEvent("vfw:newanim:refuseShared", askerId)
                choice = true
                VFW.RemoveNotification()
                VFW.ShowNotification({ type = 'ROUGE', content = "Animation refusée" })
            end
        end
    end)
end)

RegisterNetEvent("nSyncPlayEmote")
---@param emote any
---@param player number|table Player ID or object
AddEventHandler("nSyncPlayEmote", function(emote, player)
    targetPlayerId = player

    if RP.Shared[emote] ~= nil then
        local animData = RP.Shared[emote]
        local targetEmoteName = animData[4]
        local targetAnim = targetEmoteName and RP.Shared[targetEmoteName]
        local dataToPlay = targetAnim or animData

        -- Pre-load anim dict (yields here are OK, acceptor stays in place)
        RequestAnimDict(dataToPlay[1])
        local timeout = 0
        while not HasAnimDictLoaded(dataToPlay[1]) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end

        -- Detach if previously in an Attachto emote (no Wait, no ClearPedTasks)
        local ply = VFW.PlayerData.ped
        if IsEntityAttached(ply) then
            DetachEntity(ply, true, false)
        end

        if targetAnim and targetAnim.AnimationOptions and targetAnim.AnimationOptions.Attachto then
            -- Attachto: attach to source ped, then play
            local plyServerId = GetPlayerFromServerId(player)
            local pedInFront = GetPlayerPed(plyServerId)

            local bone = targetAnim.AnimationOptions.bone or -1
            local xPos = targetAnim.AnimationOptions.xPos or 0.0
            local yPos = targetAnim.AnimationOptions.yPos or 0.0
            local zPos = targetAnim.AnimationOptions.zPos or 0.0
            local xRot = targetAnim.AnimationOptions.xRot or 0.0
            local yRot = targetAnim.AnimationOptions.yRot or 0.0
            local zRot = targetAnim.AnimationOptions.zRot or 0.0

            AttachEntityToEntity(ply, pedInFront, GetPedBoneIndex(pedInFront, bone),
                    xPos, yPos, zPos, xRot, yRot, zRot,
                    false, false, false, true, 1, true)
        end

        -- Play immediately (dict pre-loaded, skipStop = no ClearPedTasks)
        PlayAnimation(VFW.PlayerData.ped, dataToPlay, true)
        return
    elseif RP.Dances[emote] ~= nil then
        PlayAnimation(VFW.PlayerData.ped, RP.Dances[emote])
        return
    else
        console.debug("nSyncPlayEmote : Emote not found")
    end
end)

RegisterNetEvent("nSyncPlayEmoteSource")
---@param emote any
---@param player number|table Player ID or object
AddEventHandler("nSyncPlayEmoteSource", function(emote, player)
    local ply = VFW.PlayerData.ped
    local plyServerId = GetPlayerFromServerId(player)
    local pedInFront = GetPlayerPed(plyServerId)
    local AnimationOptions = RP.Shared[emote] and RP.Shared[emote].AnimationOptions

    -- Pre-load anim dict (yields here are OK, not positioned yet)
    if RP.Shared[emote] then
        local animDict = RP.Shared[emote][1]
        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
    end

    -- Detach if previously in an Attachto emote (no Wait, no ClearPedTasks)
    if IsEntityAttached(ply) then
        DetachEntity(ply, true, false)
    end

    if AnimationOptions and AnimationOptions.Attachto then
        -- Attachto: attach to target ped, then play (attachment handles positioning)
        local bone = AnimationOptions.bone or -1
        local xPos = AnimationOptions.xPos or 0.0
        local yPos = AnimationOptions.yPos or 0.0
        local zPos = AnimationOptions.zPos or 0.0
        local xRot = AnimationOptions.xRot or 0.0
        local yRot = AnimationOptions.yRot or 0.0
        local zRot = AnimationOptions.zRot or 0.0
        AttachEntityToEntity(ply, pedInFront, GetPedBoneIndex(pedInFront, bone),
                xPos, yPos, zPos, xRot, yRot, zRot,
                false, false, false, true, 1, true)
        targetPlayerId = player
        PlayAnimation(ply, RP.Shared[emote], true)

    elseif RP.Shared[emote] ~= nil then
        -- SyncOffset: position ped then play immediately (dict pre-loaded, no drift)
        local SyncOffsetFront = (AnimationOptions and AnimationOptions.SyncOffsetFront) or 1.0
        local SyncOffsetSide = (AnimationOptions and AnimationOptions.SyncOffsetSide) or 0.0
        local SyncOffsetHeight = (AnimationOptions and AnimationOptions.SyncOffsetHeight) or 0.0
        local SyncOffsetHeading = (AnimationOptions and AnimationOptions.SyncOffsetHeading) or 180.1

        local coords = GetOffsetFromEntityInWorldCoords(pedInFront, SyncOffsetSide, SyncOffsetFront, SyncOffsetHeight)
        local heading = GetEntityHeading(pedInFront)

        SetEntityHeading(ply, heading - SyncOffsetHeading)
        SetEntityCoordsNoOffset(ply, coords.x, coords.y, coords.z, false, false, false)

        targetPlayerId = player
        PlayAnimation(ply, RP.Shared[emote], true)

    elseif RP.Dances[emote] ~= nil then
        targetPlayerId = player
        PlayAnimation(ply, RP.Dances[emote])
    end
end)