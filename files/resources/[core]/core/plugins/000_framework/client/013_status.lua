---@meta _
---@diagnostic disable: duplicate-doc-field

local StatusManager = {
    config = {
        thirstDecayRate = 1,
        thirstRunMultiplier = 2,
        hungerDecayRate = 1,
        hungerRunMultiplier = 2,
        criticalThresholds = { 25, 20, 15, 10, 5 },
        healthDamageInterval = 1000,
        statusUpdateInterval = 5 * 60000,
        alcoholDecayRate = 200,
        statusLossMultiplier = 1.5,
        drunkThresholds = {
            slight = 50000,
            moderate = 75000,
            severe = 100000
        }
    },

    state = {
        isHealthDamaging = false,
        healthDamageSource = nil, -- "hunger", "thirst" or "both"
        isAlreadyDrunk = false,
        drunkLevel = -1,
        alcohol = 0,
        shake = 0,
        lastPlayerPed = nil,
        lastRunningState = false,
        lastCheckTime = 0
    }
}

---Initialize ializePlayerMetadata
local function initializePlayerMetadata()
    if not VFW.PlayerData.metadata.thirst then
        VFW.PlayerData.metadata.thirst = 100
    end

    if not VFW.PlayerData.metadata.hunger then
        VFW.PlayerData.metadata.hunger = 100
    end
end

---Get PlayerPed
---@return table|nil Player object
local function getPlayerPed()
    local currentPed = VFW.PlayerData.ped
    if currentPed ~= StatusManager.state.lastPlayerPed then
        StatusManager.state.lastPlayerPed = currentPed
    end

    return StatusManager.state.lastPlayerPed
end

--- isPlayerRunning
---@return boolean
local function isPlayerRunning()
    local currentTime = GetGameTimer()
    if currentTime - StatusManager.state.lastCheckTime > 1000 then
        StatusManager.state.lastRunningState = IsPedRunning(PlayerPedId())
        StatusManager.state.lastCheckTime = currentTime
    end

    return StatusManager.state.lastRunningState
end

--- calculateStatusLoss
---@param baseRate any
---@param runMultiplier any
---@param isRunning any
---@return any
local function calculateStatusLoss(baseRate, runMultiplier, isRunning)
    local multiplier = StatusManager.config.statusLossMultiplier
    return isRunning and (baseRate * runMultiplier * multiplier) or (baseRate * multiplier)
end

--- applyStatusDecay
---@param metadata table
---@param statusType any
---@return any
local function applyStatusDecay(metadata, statusType)
    local currentValue = metadata[statusType]

    if currentValue <= 0 then
        return
    end

    local config = StatusManager.config
    local decayRate, runMultiplier

    if statusType == 'thirst' then
        decayRate = config.thirstDecayRate
        runMultiplier = config.thirstRunMultiplier
    else
        decayRate = config.hungerDecayRate
        runMultiplier = config.hungerRunMultiplier
    end

    local isRunning = isPlayerRunning()
    local loss = calculateStatusLoss(decayRate, runMultiplier, isRunning)
    metadata[statusType] = math.max(0, VFW.Math.Round(currentValue - loss))
end

--- checkCriticalThresholds
---@param metadata table
local function checkCriticalThresholds(metadata)
    local hunger = metadata.hunger
    local thirst = metadata.thirst
    local config = StatusManager.config

    for i = 1, #config.criticalThresholds do
        local threshold = config.criticalThresholds[i]

        if hunger == threshold then
            VFW.ShowNotification({ type = 'JAUNE', content = "Votre personnage a faim !" })
        end

        if thirst == threshold then
            VFW.ShowNotification({ type = 'JAUNE', content = "Votre personnage a soif !" })
        end
    end
end

---Handle HealthDamage
---@return any
local function handleHealthDamage()
    if StatusManager.state.isHealthDamaging then
        return
    end

    StatusManager.state.isHealthDamaging = true

    local thirst = VFW.PlayerData.metadata.thirst
    local hunger = VFW.PlayerData.metadata.hunger

    if hunger <= 0 and thirst <= 0 then
        StatusManager.state.healthDamageSource = "both"
    elseif hunger <= 0 then
        StatusManager.state.healthDamageSource = "hunger"
    else
        StatusManager.state.healthDamageSource = "thirst"
    end

    -- Expose to Death system (006_death loads before 013_status)
    VFW.StatusDamageSource = StatusManager.state.healthDamageSource

    while thirst <= 0 or hunger <= 0 do
        local ped = getPlayerPed()

        if not ped or GetEntityHealth(ped) <= 0 then
            -- Mort par faim/soif : SetEntityHealth ne déclenche pas CEventNetworkEntityDamage,
            -- donc on doit trigger manuellement le deathscreen
            if Death and not Death.isDead then
                TriggerEvent("vfw:onPlayerDeath")
                TriggerServerEvent("vfw:onPlayerDeath", "killed", nil)
            end
            break
        end

        local isInTIG = exports['core'] and exports['core'].IsPlayerInTIG and exports['core']:IsPlayerInTIG()
        local prisonData = VFW.PlayerData.metadata and VFW.PlayerData.metadata.prison
        local isInPrison = prisonData and prisonData.isPrisoned
        if not isInTIG and not isInPrison then
            if hunger <= 0 and thirst <= 0 then
                StatusManager.state.healthDamageSource = "both"
            elseif hunger <= 0 then
                StatusManager.state.healthDamageSource = "hunger"
            else
                StatusManager.state.healthDamageSource = "thirst"
            end
            VFW.StatusDamageSource = StatusManager.state.healthDamageSource

            SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
            local health = GetEntityHealth(ped)
            SetEntityHealth(ped, health - 2)
        end

        Wait(StatusManager.config.healthDamageInterval)

        if not VFW.PlayerData or not VFW.PlayerData.metadata then break end
        thirst = VFW.PlayerData.metadata.thirst
        hunger = VFW.PlayerData.metadata.hunger
    end

    SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
    StatusManager.state.isHealthDamaging = false
    StatusManager.state.healthDamageSource = nil
    local ped = getPlayerPed()
    local pedDead = ped and IsPedDeadOrDying(ped, true)
    if not pedDead then
        VFW.StatusDamageSource = nil
    end
end

---Update PlayerStatus
local function updatePlayerStatus()
    -- Don't decay hunger/thirst while in AFK zone
    if VFW_IsInAFK then
        return
    end

    -- Don't decay hunger/thirst while fishing
    if VFW_IsFishing then
        return
    end

    -- Don't decay hunger/thirst while in prison
    local prisonMeta = VFW.PlayerData.metadata and VFW.PlayerData.metadata.prison
    if prisonMeta and prisonMeta.isPrisoned then
        return
    end

    local metadata = VFW.PlayerData and VFW.PlayerData.metadata or { thirst = 100, hunger = 100 }
    local thirst = metadata and metadata.thirst
    local hunger = metadata and metadata.hunger

    if (thirst <= 0 or hunger <= 0) and not StatusManager.state.isHealthDamaging then
        CreateThread(handleHealthDamage)
    end

    applyStatusDecay(metadata, 'thirst')
    applyStatusDecay(metadata, 'hunger')
    checkCriticalThresholds(metadata)

    TriggerServerEvent("vfw:status:update", metadata.thirst, metadata.hunger)
end

local drunkAnimations = {
    [0] = "move_m@drunk@slightlydrunk",
    [1] = "move_m@drunk@moderatedrunk",
    [2] = "move_m@drunk@verydrunk"
}

local shakeLevels = { 1.0, 1.5, 2.0 }

--- applyDrunkAnimation
---@param level any
---@return any
local function applyDrunkAnimation(level)
    local animSet = drunkAnimations[level]
    if not animSet then
        return
    end

    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(0) end

    SetPedMovementClipset(PlayerPedId(), animSet, true)
    RemoveAnimSet(animSet)

    StatusManager.state.shake = shakeLevels[level] or 1.0
end

---Set DrunkEffects
---@param level any
---@param isStarting any
local function setDrunkEffects(level, isStarting)
    local playerPed = getPlayerPed()

    if isStarting then
        DoScreenFadeOut(800)
        Wait(1000)
    end

    applyDrunkAnimation(level)

    SetTimecycleModifier("spectator5")
    SetPedMotionBlur(playerPed, true)
    ShakeGameplayCam("DRUNK_SHAKE", StatusManager.state.shake)
    SetPedIsDrunk(playerPed, true)

    if isStarting then
        DoScreenFadeIn(800)
    end
end

--- clearDrunkEffects
local function clearDrunkEffects()
    CreateThread(function()
        local playerPed = getPlayerPed()

        DoScreenFadeOut(800)
        Wait(1000)

        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        ResetPedMovementClipset(playerPed, 0)
        SetPedIsDrunk(playerPed, false)
        SetPedMotionBlur(playerPed, false)

        DoScreenFadeIn(800)
    end)
end

---Update AlcoholStatus
local function updateAlcoholStatus()
    local config = StatusManager.config
    local state = StatusManager.state
    local alcohol = state.alcohol

    if alcohol > 0 then
        state.alcohol = math.max(0, alcohol - config.alcoholDecayRate)
    end

    local drunkThresholds = config.drunkThresholds

    if alcohol > drunkThresholds.slight then
        local level = 0
        if alcohol <= drunkThresholds.moderate then
            level = 0
        elseif alcohol <= drunkThresholds.severe then
            level = 1
        else
            level = 2
        end

        if level ~= state.drunkLevel then
            setDrunkEffects(level, not state.isAlreadyDrunk)
        end

        state.isAlreadyDrunk = true
        state.drunkLevel = level
    elseif alcohol <= drunkThresholds.slight and alcohol >= 25000 then
        local animSet = "move_m@drunk@slightlydrunk"
        RequestAnimSet(animSet)
        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        while not HasAnimSetLoaded(animSet) do Wait(0) end
        SetPedMovementClipset(PlayerPedId(), animSet, true)
        RemoveAnimSet(animSet)
        state.isAlreadyDrunk = true
    elseif alcohol <= 25000 then
        if state.isAlreadyDrunk then
            clearDrunkEffects()
        end

        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        state.isAlreadyDrunk = false
        state.drunkLevel = -1
    end
end

---Create ConsumableProp
---@param itemName string
---@return number|table|boolean Created object or success status
local function createConsumableProp(itemName)
    local itemData = VFW.Items[itemName].data
    local propHash = itemData.prop and joaat(itemData.prop) or joaat('prop_ld_flow_bottle')

    VFW.Streaming.RequestModel(propHash)
    local playerPed = VFW.PlayerData.ped
    local playerPos = GetEntityCoords(playerPed)
    local boneIndex = GetPedBoneIndex(playerPed, 18905)
    local prop = VFW.OneSync.CreateObject(propHash, vector3(playerPos.x, playerPos.y, playerPos.z + 0.2))

    local offX, offY, offZ = 0.12, 0.008, 0.03
    local rotX, rotY, rotZ = 72.0, 60.0, 160.0

    if itemData.prop == "ba_prop_club_water_bottle" or itemData.prop == "prop_ld_flow_bottle" then
        offY = -0.04
        offZ = -0.02
    end

    SetEntityCollision(prop, false, false)
    AttachEntityToEntity(prop, playerPed, boneIndex, offX, offY, offZ, rotX, rotY, rotZ, true, false, false, true, 1,
        true)

    return prop, propHash
end

---Get ConsumableAnimation
---@param itemName string
---@return string
local function getConsumableAnimation(itemName)
    local itemData = VFW.Items[itemName].data
    local isEating = itemData.anim == "eat"

    if isEating then
        return "mp_player_inteat@burger", "mp_player_int_eat_burger"
    else
        return "mp_player_intdrink", "loop_bottle"
    end
end

--- playConsumableAnimation
---@param itemName string
---@return any
local function playConsumableAnimation(itemName)
    local animDict, animName = getConsumableAnimation(itemName)

    VFW.Streaming.RequestAnimDict(animDict)
    TaskPlayAnim(VFW.PlayerData.ped, animDict, animName, 2.0, 2.0, 6000, 49, 0, 0, 0, 0)

    return animDict, animName
end

---Handle Consumable
---@param itemName string
---@return any
local function handleConsumable(itemName)
    local itemData = VFW.Items[itemName].data
    if itemData.drugs then
        return
    end

    local prop, propHash = createConsumableProp(itemName)
    local animDict, animName = playConsumableAnimation(itemName)

    Wait((GetAnimDuration(animDict, animName) * 1000) + 2200) -- 2200 ms: marge de sécurité

    DeleteObject(prop)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(propHash)

    if itemData.alcool then
        StatusManager.state.alcohol = StatusManager.state.alcohol + (itemData.thirst * 1000)
    end
end

CreateThread(function()
    while not VFW.IsPlayerLoaded() or VFW.PlayerData == nil do Wait(0) end

    initializePlayerMetadata()

    while true do
        Wait(StatusManager.config.statusUpdateInterval)
        updatePlayerStatus()
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        updateAlcoholStatus()
    end
end)

-- Items qui utilisent une emote dédiée au lieu de l'anim consommable standard
-- (le système default attache les props à un bone fixe avec un placement
--  unique qui ne convient pas pour tous les types de food/drink).
local ItemToEmote = {}

RegisterNetEvent("vfw:eat", function(itemName)
    local emote = ItemToEmote[itemName]
    if emote then
        if EmoteCommandStart then
            EmoteCommandStart(emote, PlayerPedId(), nil)
            TriggerServerEvent("vfw:newanim:sync", emote)
        else
            ExecuteCommand("e " .. emote)
        end
        return
    end
    handleConsumable(itemName)
end)

RegisterNetEvent("vfw:status:forceUpdate", function(thirst, hunger)
    VFW.PlayerData.metadata.thirst = thirst
    VFW.PlayerData.metadata.hunger = hunger
    if not StatusManager.state.isHealthDamaging then
        CreateThread(handleHealthDamage)
    end
end)

AddEventHandler("core:addAlcohol", function(amount)
    StatusManager.state.alcohol = StatusManager.state.alcohol + amount
end)
