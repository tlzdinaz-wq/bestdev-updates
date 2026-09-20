-- Client: cl.lua

-- Debug control (client-side)
local DEBUG = false

local function dbgPrint(...)
    if not DEBUG then return end
    print(...)
end

local radioOpen = false
local currentFrequency = nil

-- Export function to check if radio is open (used by inventory to restore focus)
function VFW.IsRadioOpen()
    return radioOpen
end
local currentVolume = 50
local isTalking = false
local connectedPlayers = {}
local currentRadioType = nil -- 'public', 'police', etc.
local currentOffset = nil
local lastDictLoaded = nil
local radioSoundsMuted = false

-- Helper function to get the radio display name (nickname or fallback to RP name)
local function getRadioDisplayName()
    local nicknameData = LocalPlayer.state.radioNickname or {}
    if nicknameData.useNickname and nicknameData.nickname and nicknameData.nickname ~= "" then
        return nicknameData.nickname
    end
    if VFW.PlayerData and VFW.PlayerData.firstName and VFW.PlayerData.lastName then
        local name = VFW.PlayerData.firstName .. " " .. VFW.PlayerData.lastName
        if name ~= " " and name ~= "" then
            return name
        end
    end
    return "Inconnu"
end

-- Track if radio was used from inventory
local radioActivated = false
local radioActivatedType = nil -- 'public' or 'job'

-- Single F11 key for radio (requires radio item to be actively used)
RegisterKeyMapping('openRadio', 'Ouvrir la Radio', 'keyboard', 'F11')

RegisterCommand('openRadio', function()
    TryOpenRadio()
end, false)

-- Event triggered when radio is used from inventory
RegisterNetEvent("radio:activated")
AddEventHandler("radio:activated", function(radioType)
    radioActivated = true
    radioActivatedType = radioType

    -- Fermer l'inventaire avant d'ouvrir la radio
    if VFW.CloseInventory then
        VFW.CloseInventory()
    end

    -- Auto open radio when used from inventory
    TryOpenRadio()
end)

-- Event triggered when another item is used (deactivates radio)
AddEventHandler("radio:deactivate", function()
    if radioActivated then
        radioActivated = false
        radioActivatedType = nil
        pcall(function() exports['pma-voice']:setRadioChannel(0) end)
        -- Close radio UI if open
        if radioOpen then
            ToggleRadio()
        end
    end
end)

---@param item string
---@return boolean
local function HaveItem(item)
    item = item:lower()

    for _, entry in pairs(VFW.PlayerData.inventory or {}) do
        if entry.name and entry.name:lower() == item then
            return true
        end
    end

    return false
end


local radioPropConfig = {
    ["Épaule"] = {
        bone = 18905, -- mano izquierda
        offset = vector3(0.13, 0.04, 0.03),
        rotation = vector3(-99.0, 0.0, -45.0),
        useProp = false
    },
    ["Frontal"] = {
        bone = 57005, -- mano derecha
        offset = vector3(0.15, 0.03, -0.03),
        rotation = vector3(84.0, 0.0, 125.0),
        useProp = true
    },
    ["Oreille"] = {
        bone = 31086, -- mano derecha
        offset = vector3(0.01, -0.01, -0.07),
        rotation = vector3(91.0, 0.0, 108.0),
        useProp = true
    },
    ["Poitrine"] = {
        useProp = false -- sin prop
    }
}


local function getRadioPropModel(style)
    if style == "Oreille" then
        return `prop_connect`
    else
        return `prop_cs_walkie_talkie`
    end
end


function getRadioAnimationData()
    local dict = GetResourceKvpString("radioAnimDict") or "random@arrests"
    local anim = GetResourceKvpString("radioAnimName") or "generic_radio_chatter"

    local style = "Épaule"
    for name, data in pairs(radioPropConfig) do
        if name == "Épaule" and dict == "random@arrests" and anim == "generic_radio_chatter" then
            style = name
        elseif name == "Poitrine" and dict == "anim@cop_mic_pose_002" and anim == "chest_mic" then
            style = name
        elseif name == "Frontal" and dict == "anim@male@holding_radio" and anim == "holding_radio_clip" then
            style = name
        elseif name == "Oreille" and dict == "cellphone@" and anim == "cellphone_call_listen_base" then
            style = name
        end
    end

    local config = radioPropConfig[style] or radioPropConfig["Épaule"]

    return {
        dict = dict,
        anim = anim,
        bone = config.bone,
        offset = config.offset,
        rotation = config.rotation,
        useProp = config.useProp,
        style = style
    }
end




function ensureDictLoaded(dict)
    if lastDictLoaded ~= dict then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
        lastDictLoaded = dict
    end
end

function TryOpenRadio()

    -- If radio is already open, close it
    if radioOpen then
        ToggleRadio()
        return
    end

    -- Check if radio was activated from inventory
    if not radioActivated then
        return
    end

    local requestedType = radioActivatedType or "public"

    -- Disconnect only if player is switching type
    local isSameType = (requestedType == "public" and currentRadioType == "public") or
            (requestedType == "job" and currentRadioType ~= "public")

    if currentFrequency and currentRadioType and not isSameType then
        dbgPrint("[Radio] Disconnecting due to type change:", currentRadioType, "->", requestedType)
        pcall(function() exports['pma-voice']:setRadioChannel(0) end)
        TriggerServerEvent('radio:disconnect', currentFrequency, currentRadioType)
        currentFrequency = nil
        currentRadioType = nil
        SendNUIMessage({
            action = 'updateConnection',
            data = {
                connected = false,
                frequency = nil
            }
        })
        SendNUIMessage({
            action = 'updateRadioConnection',
            data = { connected = false }
        })

        local animData = getRadioAnimationData()
        if animData.style == "Oreille" and radioProp and DoesEntityExist(radioProp) then
            DeleteEntity(radioProp)
            radioProp = nil
            dbgPrint("🧹 Prop Oreille eliminado por cambio de tipo de radio")
        end
    end

    -- Server-side validation
    TriggerServerEvent("radio:checkItemForRadio", requestedType)
end


RegisterNetEvent("vfw:radio:notify")
AddEventHandler("vfw:radio:notify", function(message)
    VFW.ShowNotification({
        type = 'ROUGE',
        content = message
    })
end)

function ToggleRadio()
    radioOpen = not radioOpen
    dbgPrint('[Radio] ToggleRadio triggered. New state:', radioOpen and 'OUVERTE' or 'FERMÉE')

    local ped = PlayerPedId()

    if radioOpen then
        dbgPrint('[Radio] Requesting status from server...')
        VFW.Nui.newRadio(true)
        TriggerServerEvent('radio:requestStatus')

        -- 🎬 Animación fija y prop al abrir
        VFW.Streaming.RequestAnimDict('cellphone@')

        TriggerEvent("attachItemRadio", "radio01")

        TaskPlayAnim(ped, "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, 0, 0, 0)

        local model = `prop_cs_hand_radio`
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end

        if radioProp and DoesEntityExist(radioProp) then
            DeleteEntity(radioProp)
        end

        radioProp = CreateObject(model, 1.0, 1.0, 1.0, false, true, false)
        SetEntityAsMissionEntity(radioProp, true, true)
        SetModelAsNoLongerNeeded(model)

        AttachEntityToEntity(
                radioProp,
                ped,
                GetPedBoneIndex(ped, 57005),
                0.14, 0.01, -0.02,
                110.0, 120.0, -15.0,
                true, false, false, false, 2, true
        )

    else
        dbgPrint('[Radio] Closing radio UI.')
        VFW.Nui.newRadio(false)

        -- 🛑 Detener animación y eliminar prop
        StopAnimTask(ped, "cellphone@", "cellphone_text_read_base", 1.0)
        ClearPedTasks(ped)

        if radioProp and DoesEntityExist(radioProp) then
            DeleteEntity(radioProp)
            radioProp = nil
            dbgPrint("🧹 Prop radio eliminado al cerrar la radio")
        end

        -- NOTE: Do NOT deactivate radio when closing - user can reopen with F11
        -- Radio only deactivates when item is lost (checked in auto-disconnect thread)
    end
end


RegisterNUICallback('closeRadio', function(_, cb)
    ToggleRadio()
    cb('ok')
end)

RegisterNUICallback('connectToFrequency', function(data, cb)
    local frequency = tonumber(data.frequency)
    if not frequency or frequency < 1 then
        cb({ success = false, error = 'Invalid frequency' })
        return
    end

    if frequency % 1 ~= 0 then
        cb({ success = false, error = 'Only integer frequencies are allowed' })
        return
    end

    if not currentRadioType then
        cb({ success = false, error = 'You have not used a radio item.' })
        return
    end

    currentFrequency = frequency

    -- Offset basé sur le type de radio courant (cohérent avec le serveur)
    currentOffset = RadioConfig.GetOffset(currentRadioType)
    local channelWithOffset = currentFrequency + currentOffset
    pcall(function() exports['pma-voice']:setRadioChannel(channelWithOffset) end)
    TriggerServerEvent('radio:connectToFrequency', frequency, currentRadioType)
    cb({ success = true })
end)

RegisterNUICallback('disconnectFromRadio', function(_, cb)
    if currentFrequency then
        TriggerServerEvent('radio:disconnect', currentFrequency, currentRadioType)

        currentFrequency = nil
        pcall(function() exports['pma-voice']:setRadioChannel(0) end)
        SendNUIMessage({
            action = 'updateConnection',
            data = {
                connected = false,
                frequency = nil
            }
        })
    end

    local animData = getRadioAnimationData()
    if animData.style == "Oreille" and radioProp and DoesEntityExist(radioProp) then
        DeleteEntity(radioProp)
        radioProp = nil
        dbgPrint("🧹 Prop Oreille eliminado al desconectarse")
    end

    -- ✅ NUEVO: desactivar ícono de walkie-talkie
    SendNUIMessage({
        action = 'updateRadioConnection',
        data = { connected = false }
    })

    cb('ok')
end)


local RADIO_VOLUME_MULTIPLIER = 2.0 -- Multiplicateur pour booster le volume max

local function applyRadioVolume(vol)
    currentVolume = math.max(1, math.min(100, math.floor(vol)))
    local boostedVolume = currentVolume * RADIO_VOLUME_MULTIPLIER
    pcall(function() exports['pma-voice']:setRadioVolume(boostedVolume) end)
    dbgPrint("Radio volume applied:", currentVolume, "-> boosted:", boostedVolume)
end

RegisterNUICallback('applyVolume', function(data, cb)
    local volume = tonumber(data.volume)
    if volume then
        applyRadioVolume(volume)
    end
    cb('ok')
end)

RegisterNUICallback('setVolume', function(data, cb)
    local volume = tonumber(data.volume)
    if volume then
        applyRadioVolume(volume)
    end
    cb('ok')
end)

RegisterNUICallback('setNickname', function(data, cb)
    TriggerServerEvent('radio:setNickname', data.nickname, data.useNickname)
    LocalPlayer.state.radioNickname = {
        nickname = data.nickname,
        useNickname = data.useNickname
    }
    cb('ok')
end)


--NEW FUNCTIONS NUI CALLBACKS

RegisterNUICallback('toggleMuteSelf', function(data, cb)
    local mute = data.mute
    LocalPlayer.state.selfMuted = mute

    if mute and isTalking then
        isTalking = false
        TriggerServerEvent('radio:stopTalking', currentFrequency, currentRadioType)
        ClearPedTasks(PlayerPedId())

        if radioProp and DoesEntityExist(radioProp) then
            DeleteEntity(radioProp)
            radioProp = nil
        end

        local playerName = getRadioDisplayName()

        SendNUIMessage({
            action = 'playerTalking',
            data = {
                playerId = GetPlayerServerId(PlayerId()),
                playerName = playerName,
                talking = false
            }
        })

        dbgPrint("Muted while talking: stopTalking sent to server")
    end

    cb('ok')
end)


local isRadioMuted = false

RegisterNUICallback('toggleMuteAll', function(data, cb)
    local mute = data.mute
    if mute and not isRadioMuted then
        pcall(function() exports['pma-voice']:setRadioVolume(0) end)
        isRadioMuted = true
    elseif not mute and isRadioMuted then
        -- Restaurer le volume avec le multiplicateur
        applyRadioVolume(currentVolume)
        isRadioMuted = false
    end
    cb('ok')
end)

-- Callback pour gérer le focus overlay (quand souris survole les boutons)
RegisterNUICallback('radio:setOverlayFocus', function(data, cb)
    if currentFrequency and not radioOpen then
        VFW.Nui.Focus(data.focus, not data.focus)
    end
    cb('ok')
end)

-- Callback pour gérer le focus de l'input nickname dans la radio
RegisterNUICallback('radio:inputFocusLock', function(data, cb)
    if radioOpen then
        if data then
            -- Focus complet pour la saisie (clavier + souris)
            VFW.Nui.Focus(true)
        else
            VFW.Nui.Focus(true, true)
        end
    end
    cb('ok')
end)



RegisterNUICallback('radio:setMuteSounds', function(data, cb)
    radioSoundsMuted = data and data.muted == true
    LocalPlayer.state:set('radioSoundsMuted', radioSoundsMuted, false)
    cb('ok')
end)

RegisterNetEvent('radio:connectionSuccess')
AddEventHandler('radio:connectionSuccess', function(frequency, radioType, offset, members)
    currentFrequency = frequency
    currentRadioType = radioType
    currentOffset = offset or 0
    connectedPlayers = members

    -- Force pma-voice re-sync à chaque connectionSuccess. Le state Lua peut être
    -- correct côté radio_job sans que pma-voice route effectivement l'audio (cas
    -- typique : death/respawn, voice reset, restart pma-voice). Sans ce re-call,
    -- on perd l'audio jusqu'à reconnexion manuelle.
    local channelWithOffset = frequency + (offset or 0)
    pcall(function() exports['pma-voice']:setRadioChannel(channelWithOffset) end)

    local animData = getRadioAnimationData()
    if animData.style == "Oreille" and animData.useProp then
        local ped = PlayerPedId()
        local radioModel = getRadioPropModel(animData.style)
        RequestModel(radioModel)
        while not HasModelLoaded(radioModel) do Wait(10) end

        if radioProp and DoesEntityExist(radioProp) then
            DeleteEntity(radioProp)
        end

        radioProp = CreateObject(radioModel, 0.0, 0.0, 0.0, false, true, false)
        SetEntityAsMissionEntity(radioProp, true, true)
        SetModelAsNoLongerNeeded(radioModel)

        local boneIndex = GetPedBoneIndex(ped, animData.bone)
        AttachEntityToEntity(
                radioProp,
                ped,
                boneIndex,
                animData.offset.x, animData.offset.y, animData.offset.z,
                animData.rotation.x, animData.rotation.y, animData.rotation.z,
                true, true, false, true, 1, true
        )

        dbgPrint("📎 Prop Oreille creado al conectarse")
    end

    dbgPrint('[Radio] State restored from server:', frequency, radioType, 'Offset:', currentOffset)

    SendNUIMessage({
        radioChannel = frequency,
        radioEnabled = true,
        uiEnabled = true
    })

    VFW.Nui.newRadio(true, {
        connected = true,
        frequency = frequency,
        members = members
    })

    SendNUIMessage({
        action = 'updateConnection',
        data = {
            connected = true,
            frequency = frequency
        }
    })

    SendNUIMessage({
        action = 'updateMembers',
        data = members
    })

    -- ✅ NUEVO: activar ícono de walkie-talkie
    SendNUIMessage({
        action = 'updateRadioConnection',
        data = { connected = true }
    })
end)


RegisterNetEvent('radio:connectionDenied')
AddEventHandler('radio:connectionDenied', function(reason)
    currentFrequency = nil
    pcall(function() exports['pma-voice']:setRadioChannel(0) end)
    SendNUIMessage({
        action = 'connectionDenied',
        data = { reason = reason }
    })
    SendNUIMessage({
        action = 'updateRadioConnection',
        data = { connected = false }
    })
    SendNUIMessage({
        action = 'updateConnection',
        data = { connected = false, frequency = nil }
    })
end)

RegisterNetEvent('radio:updateMembers')
AddEventHandler('radio:updateMembers', function(members)
    connectedPlayers = members
    SendNUIMessage({
        action = 'updateMembers',
        data = members
    })
end)

RegisterNetEvent('radio:playerTalking')
AddEventHandler('radio:playerTalking', function(playerId, playerName, talking)
    SendNUIMessage({
        action = 'playerTalking',
        data = {
            playerId = playerId,
            playerName = playerName,
            talking = talking
        }
    })
end)

local radioProp = nil -- ← fuera del hilo

-- Avant chaque PTT, vérifier si la session existe toujours côté server.
-- Si pas, la recréer automatiquement (cas restart ressource ou désync)
local function EnsureServerSessionAlive()
    if not currentFrequency or not currentRadioType then return end
    -- On envoie un resync silencieux ; le server vérifie côté lui s'il est déjà tracké
    TriggerServerEvent('radio:resyncSession', currentFrequency, currentRadioType)
end

RegisterCommand('+radioTalkDown', function()
    if not currentFrequency or LocalPlayer.state.selfMuted then return end
    if not isTalking then
        isTalking = true
        -- Garde-fou : si la ressource server a redémarré, recrée la session avant de parler
        EnsureServerSessionAlive()
        TriggerServerEvent('radio:startTalking', currentFrequency, currentRadioType)
        if not radioSoundsMuted then PlaySoundFrontend(-1, "Beep_Green", "HUD_FRONTEND_DEFAULT_SOUNDSET", true) end

        local ped = PlayerPedId()
        local animData = getRadioAnimationData()

        if animData.style ~= "Oreille" then
            ensureDictLoaded(animData.dict)
        end

        if animData.useProp and animData.style ~= "Oreille" then
            local radioModel = getRadioPropModel(animData.style)
            RequestModel(radioModel)
            while not HasModelLoaded(radioModel) do Wait(10) end

            radioProp = CreateObject(radioModel, 0.0, 0.0, 0.0, false, true, false)
            SetEntityAsMissionEntity(radioProp, true, true)
            SetModelAsNoLongerNeeded(radioModel)

            local boneIndex = GetPedBoneIndex(ped, animData.bone)
            AttachEntityToEntity(
                    radioProp, ped, boneIndex,
                    animData.offset.x, animData.offset.y, animData.offset.z,
                    animData.rotation.x, animData.rotation.y, animData.rotation.z,
                    true, true, false, true, 1, true
            )
        end

        if animData.style ~= "Oreille" then
            TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end

        -- currentRadioType est "public" pour la radio publique, ou le nom du job (ex: "lspd")
        -- pour la radio job. On check donc l'inverse pour identifier l'item correct.
        local itemName = (currentRadioType == "public") and "radio_public" or "radio_job"

        if HaveItem(itemName) then
            local playerName = getRadioDisplayName()
            pcall(function() exports["pma-voice"]:setVoiceProperty("radioPressed", true) end)
            SendNUIMessage({
                action = 'updateVoiceMode', -- Esto activa el listener de tu StatusHUD
                data = {
                    isTalkingRadio = true, -- Prende el walkie-talkie
                    isTalking = false      -- Asegura que el micro normal esté apagado
                }
            })
            SendNUIMessage({
                action = 'playerTalking',
                data = {
                    playerId = GetPlayerServerId(PlayerId()),
                    playerName = playerName,
                    talking = true
                }
            })
        end

        dbgPrint("You are talking on radio")
    end
end, false)

-- Comando para terminar transmisión
-- Re-sync de la session radio si server a été restart pendant qu'on était connecté
RegisterNetEvent('radio:serverRestarted')
AddEventHandler('radio:serverRestarted', function()
    if currentFrequency and currentRadioType then
        dbgPrint("[Radio] Server restarted, resyncing session for", currentFrequency, currentRadioType)
        TriggerServerEvent('radio:resyncSession', currentFrequency, currentRadioType)
    end
end)

RegisterCommand('-radioTalkDown', function()
    if isTalking then
        isTalking = false
        if not radioSoundsMuted then PlaySoundFrontend(-1, "Beep_Red", "HUD_FRONTEND_DEFAULT_SOUNDSET", true) end
        TriggerServerEvent('radio:stopTalking', currentFrequency, currentRadioType)
        ClearPedTasks(PlayerPedId())

        if radioProp and DoesEntityExist(radioProp) then
            DeleteEntity(radioProp)
            radioProp = nil
        end

        local playerName = getRadioDisplayName()
        pcall(function() exports["pma-voice"]:setVoiceProperty("radioPressed", false) end)
        SendNUIMessage({
            action = 'updateVoiceMode',
            data = {
                isTalkingRadio = false, -- Apaga el walkie-talkie
                isTalking = false
            }
        })
        SendNUIMessage({
            action = 'playerTalking',
            data = {
                playerId = GetPlayerServerId(PlayerId()),
                playerName = playerName,
                talking = false
            }
        })

        dbgPrint("You stopped talking on radio")
    end
end, false)

-- 🔑 Mapear la tecla L a los comandos
RegisterKeyMapping('+radioTalkDown', 'Parler Radio', 'keyboard', 'l')

RegisterNetEvent("vfw:radio:openWithConfig")
AddEventHandler("vfw:radio:openWithConfig", function(data)

    if radioOpen then
        if currentRadioType == data.radioType then
            dbgPrint("[Radio] Already open with same type. Closing...")
            ToggleRadio()
            currentRadioType = nil
            currentOffset = nil
            return
        end

        dbgPrint("[Radio] Already open with another type:", currentRadioType, "-> blocking open of", data.radioType)
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous avez déjà une radio ouverte."
        })
        return
    end

    currentRadioType = data.radioType
    currentOffset = data.offset or 0

    SendNUIMessage({
        action = "setRadioShell",
        data = { shell = data.shell }
    })

    ToggleRadio()
    local nicknameData = LocalPlayer.state and LocalPlayer.state.radioNickname or {}
    if nicknameData.nickname and nicknameData.useNickname ~= nil then
        TriggerServerEvent('radio:setNickname', nicknameData.nickname, nicknameData.useNickname)
        dbgPrint("[Radio] Sending nickname to server:", nicknameData.nickname, "use:", nicknameData.useNickname)
    end
end)

RegisterCommand('voicestatus', function()
    local playerState = LocalPlayer.state
    local radioChannel = playerState.radioChannel or 0
    local callChannel = playerState.callChannel or 0
    local proximity = playerState.proximity or {}

    dbgPrint('=============================')
    dbgPrint('pma-voice status:')
    dbgPrint('Radio Channel: ' .. tostring(radioChannel))
    dbgPrint('Call Channel: ' .. tostring(callChannel))
    dbgPrint(('Voice Mode: %s (%sm)'):format(proximity.name or "N/A", proximity.distance or "N/A"))
    dbgPrint(('Current Radio Volume: %d'):format(currentVolume or -1))
    dbgPrint('=============================')
end)

Citizen.CreateThread(function()
    while true do
        if radioOpen then
            Wait(0)
            -- Bloquear cámara y acciones mientras la radio está abierta
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 106, true) -- Vehicle Mouse Attack
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 143, true)
        else
            Wait(250) -- reduce carga cuando la radio está cerrada
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if radioProp and DoesEntityExist(radioProp) then
        DeleteEntity(radioProp)
        radioProp = nil
    end
end)

------------------------------------------------------------------------
-- HEARTBEAT: re-sync periodique de la session radio pour éviter les
-- désyncs silencieuses avec pma-voice (cas observé : après ~10-15min
-- on s'entend plus alors que le client/serveur pensent être connectés).
-- On ré-applique le channel sur pma-voice et on ping le server pour
-- s'assurer que la session est encore trackée.
------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- toutes les 60s

        if currentFrequency and currentRadioType and currentOffset ~= nil then
            local expectedChannel = currentFrequency + (currentOffset or 0)
            local actualChannel = LocalPlayer.state.radioChannel or 0

            -- Ne re-call pma-voice que si désync détectée. Sinon le remove+add
            -- forcé glitcherait l'audio toutes les minutes pour les voisins.
            if actualChannel ~= expectedChannel then
                pcall(function() exports['pma-voice']:setRadioChannel(expectedChannel) end)
            end

            -- Ping idempotent côté serveur : si la session est encore trackée,
            -- early-return ; sinon le serveur la reconstruit.
            EnsureServerSessionAlive()
        end
    end
end)

------------------------------------------------------------------------
-- AUTO-DISCONNECT WHEN PLAYER NO LONGER HAS RADIO ITEM
------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Check every 5 seconds

        -- Solo comprobar si estamos conectados a una frecuencia
        if currentFrequency and currentRadioType then

            -- ✅ CORRECCIÓN: Buscar el ítem REAL que estás usando (public o job)
            local itemName = (currentRadioType == "public") and "radio_public" or "radio_job"
            local hasRadioItem = HaveItem(itemName)

            -- Si el jugador ya no tiene el ítem en el inventario
            if not hasRadioItem then
                dbgPrint("[Radio] Player no longer has radio item, disconnecting...")

                -- Desconectar del servidor
                TriggerServerEvent('radio:disconnect', currentFrequency, currentRadioType)

                -- ✅ SINCRONIZACIÓN CON EL HUD: Borrar la línea de radio
                pcall(function() exports['pma-voice']:setRadioChannel(0) end)

                -- Reset de variables
                currentFrequency = nil
                currentRadioType = nil
                radioActivated = false
                radioActivatedType = nil

                -- Cerrar la interfaz si estaba abierta
                if radioOpen then
                    ToggleRadio()
                end

                -- Actualizar el otro menú NUI
                SendNUIMessage({
                    action = 'updateConnection',
                    data = { connected = false, frequency = nil }
                })

                -- Limpiar el prop de la oreja
                local animData = getRadioAnimationData()
                if animData.style == "Oreille" and radioProp and DoesEntityExist(radioProp) then
                    DeleteEntity(radioProp)
                    radioProp = nil
                end

                -- Notificación
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Radio déconnectée (item manquant)"
                })
            end
        end
    end
end)

------------------------------------------------------------------------
-- HIDE HUD WHEN LB-PHONE IS OPEN
------------------------------------------------------------------------
local function syncPhoneOpenToNui(open)
    SendNUIMessage({
        action = 'nui:newRadio:phoneOpen',
        data = open and true or false
    })
end

AddStateBagChangeHandler('phoneOpen', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    syncPhoneOpenToNui(value)
end)

AddEventHandler('vfw:playerLoaded', function()
    Citizen.Wait(500)
    local state = LocalPlayer.state
    syncPhoneOpenToNui(state and state.phoneOpen)
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    local state = LocalPlayer.state
    syncPhoneOpenToNui(state and state.phoneOpen)
end)
