---@meta _
---@diagnostic disable: duplicate-doc-field

-- Sirènes/HUD « 4 boutons » (bas-droite) : versions US uniquement (menta serveur).
-- En FR, c'est le module de sirènes (modules/sirens) qui prend le relais.
if MENTA_SERVER ~= 'US' then return end

local config = {
    ---@class audioConfig
    ---@field audioName string
    ---@field audioRef? string the audioBank to use, if for example you use custom serverside sirens

    ---@class SirenConfigTable
    ---@field models? table<string, boolean>
    ---@field sirenModes table<number, audioConfig> the key is the siren mode
    ---@field horn? audioConfig

    controls = {
        policeLights = 'A',
        policeHorn   = 'E',
        sirenToggle  = 'G',
        sirenCycle   = 'R',
    },

    sirenShutOff = true,          -- Set to true if you want the siren to automatically shut off when the player exits the vehicle

    disableDamagedSirens = false, -- Set to true if you want to disable the damaged siren
    useEngineHealth = false,      -- Determine wether to use engine health over body health for siren damage
    damageThreshold = 300,        -- If the vehicle's health is below this value, the siren will be considered damaged

    ---@type table<number, SirenConfigTable>
    --- Configure what siren sounds to use for a specific model and siren mode
    sirens = {
        --base
        {
            sirenModes = {
                { audioName = 'VEHICLES_HORNS_SIREN_1' },
                { audioName = 'VEHICLES_HORNS_SIREN_2' },
                { audioName = 'VEHICLES_HORNS_POLICE_WARNING' },
            },

            horn = {
                audioName = 'SIRENS_AIRHORN'
            }
        },

        --fire
        {
            sirenModes = {
                { audioName = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01' },
                { audioName = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01' },
                { audioName = 'VEHICLES_HORNS_AMBULANCE_WARNING' }
            },

            horn = {
                audioName = 'VEHICLES_HORNS_FIRETRUCK_WARNING'
            },

            models = {
                [`FIRETRUK`] = true,
                [`ambulance`] = true,
            }
        },

        --unmarked
        {
            sirenModes = {
                { audioName = 'RESIDENT_VEHICLES_SIREN_WAIL_02' },
                { audioName = 'RESIDENT_VEHICLES_SIREN_QUICK_02' }
            },

            models = {
                [`fbi`] = true,
                [`fbi2`] = true,
                [`police4`] = true,
            }
        },

        --bikes
        {
            sirenModes = {
                { audioName = 'RESIDENT_VEHICLES_SIREN_WAIL_03' },
                { audioName = 'RESIDENT_VEHICLES_SIREN_QUICK_03' }
            },

            models = {
                [`policeb`] = true
            }
        },
    }
}

local sirenVehicles = {}
local hornVehicles = {}

--- waitFor
---@param cb function Callback function
---@param errMessage string
---@param timeout any
---@return any
local function waitFor(cb, errMessage, timeout)
    local value = cb()

    if value ~= nil then
        return value
    end

    if timeout or timeout == nil then
        if type(timeout) ~= 'number' then
            timeout = 1000
        end
    end

    local start = timeout and GetGameTimer()

    while value == nil do
        Wait(0)

        local elapsed = timeout and GetGameTimer() - start

        if elapsed and elapsed > timeout then
            return error(('%s (waited %.1fms)'):format(errMessage or 'failed to resolve callback', elapsed), 2)
        end

        value = cb()
    end

    return value
end

--- releaseSound
---@param veh any
---@param soundId number|string
---@param forced any
---@return any
local function releaseSound(veh, soundId, forced)
    if forced and (DoesEntityExist(veh) and not IsEntityDead(veh)) then
        return
    end

    StopSound(soundId)
    ReleaseSoundId(soundId)
    return true
end

--- isVehAllowed
---@return boolean
local function isVehAllowed()
    if not VFW.PlayerData.vehicle or not DoesEntityExist(VFW.PlayerData.vehicle) then
        return false
    end
    if VFW.PlayerData.seat ~= -1 or GetVehicleClass(VFW.PlayerData.vehicle) ~= 18 or IsPedInAnyHeli(PlayerPedId()) or IsPedInAnyPlane(PlayerPedId()) then
        return false
    end

    return true
end

local keybinds = {}

---Create Keybind
---@param name string
---@param description any
---@param defaultKey any
---@param onPressed any
---@param onReleased any
---@return number|table|boolean Created object or success status
local function createKeybind(name, description, defaultKey, onPressed, onReleased)
    keybinds[name] = {
        name = name,
        description = description,
        defaultKey = defaultKey,
        onPressed = onPressed,
        onReleased = onReleased,
        disabled = false
    }

    RegisterCommand('+'..name, function()
        if not keybinds[name].disabled and keybinds[name].onPressed then
            keybinds[name].onPressed()
        end

    end, false)

    RegisterCommand('-'..name, function()
        if not keybinds[name].disabled and keybinds[name].onReleased then
            keybinds[name].onReleased()
        end

    end, false)

    RegisterKeyMapping('+'..name, description, 'keyboard', defaultKey)
end

--- disableKeybind
---@param name string
---@param state any
local function disableKeybind(name, state)
    if keybinds[name] then
        keybinds[name].disabled = state
    end
end

CreateThread(function()
    while true do
        for veh, soundId in pairs(sirenVehicles) do
            if releaseSound(veh, soundId, true) then
                sirenVehicles[veh] = nil
            end
        end

        for veh, soundId in pairs(hornVehicles) do
            if releaseSound(veh, soundId, true) then
                hornVehicles[veh] = nil
            end
        end

        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        if VFW.PlayerData.seat == -1 and VFW.PlayerData.vehicle and DoesEntityExist(VFW.PlayerData.vehicle) then
            SetVehRadioStation(VFW.PlayerData.vehicle, 'OFF')
            SetVehicleRadioEnabled(VFW.PlayerData.vehicle, false)

            if NetworkGetEntityIsNetworked(VFW.PlayerData.vehicle) and not Entity(VFW.PlayerData.vehicle).state.stateEnsured then
                TriggerServerEvent('Renewed-Sirensync:server:SyncState', VehToNet(VFW.PlayerData.vehicle))
            end

            while VFW.PlayerData.seat == -1 and VFW.PlayerData.vehicle and DoesEntityExist(VFW.PlayerData.vehicle) and GetVehicleClass(VFW.PlayerData.vehicle) == 18 do
                DisableControlAction(0, 80, true)  -- R
                DisableControlAction(0, 81, true)  -- .
                DisableControlAction(0, 82, true)  -- ,
                DisableControlAction(0, 83, true)  -- =
                DisableControlAction(0, 84, true)  -- -
                DisableControlAction(0, 85, true)  -- Q
                DisableControlAction(0, 86, true)  -- E
                DisableControlAction(0, 172, true) -- Up arrow
                Wait(0)
            end
        end

        Wait(100)
    end
end)

CreateThread(function()
    local lastVehicle = nil

    while true do
        if VFW.PlayerData.vehicle ~= lastVehicle then
            if lastVehicle and DoesEntityExist(lastVehicle) and VFW.PlayerData.seat ~= -1 then
                local state = Entity(lastVehicle).state

                if not state.stateEnsured then
                    lastVehicle = VFW.PlayerData.vehicle
                    Wait(100)
                    goto continue
                end

                if config.sirenShutOff then
                    if state.sirenMode ~= 0 then
                        state:set('sirenMode', 0, true)
                    end
                end

                if state.horn then
                    state:set('horn', false, true)
                end
            end

            lastVehicle = VFW.PlayerData.vehicle
        end

        ::continue::

        Wait(500)
    end
end)

--- stateBagWrapper
---@param keyFilter any
---@param cb function Callback function
---@return boolean
local function stateBagWrapper(keyFilter, cb)
    return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value, _, replicated)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        if not netId then return end

        local ok, loaded = pcall(waitFor, function()
            if NetworkDoesEntityExistWithNetworkId(netId) then
                return true
            end
        end, 'Timeout while waiting for entity to exist', 5000)

        if not ok or not loaded then return end

        local entity = NetToVeh(netId)

        if entity and entity ~= 0 then
            local amOwner = NetworkGetEntityOwner(entity) == VFW.playerId

            if amOwner == replicated then
                cb(entity, value)
            end
        end
    end)
end

stateBagWrapper('lightsOn', function(veh, value)
    SetVehicleHasMutedSirens(veh, true)
    SetVehicleSiren(veh, value)
end)

-- Instructional buttons pour les véhicules emergency
local sirenInstructionalId = nil

CreateThread(function()
    local wasInEmergency = false

    while true do
        local inEmergency = VFW.PlayerData.seat == -1
            and VFW.PlayerData.vehicle
            and DoesEntityExist(VFW.PlayerData.vehicle)
            and GetVehicleClass(VFW.PlayerData.vehicle) == 18

        if inEmergency and not wasInEmergency then
            sirenInstructionalId = VFW.AddInstructionalButtons({
                { control = "A", label = "Gyrophares" },
                { control = 38, label = "Klaxon sirène" },
                { control = 47, label = "Sirène on/off" },
                { control = 45, label = "Changer sirène" },
            })
        elseif not inEmergency and wasInEmergency then
            if sirenInstructionalId then
                VFW.RemoveInstructionalButtons(sirenInstructionalId)
                sirenInstructionalId = nil
            end
        end

        wasInEmergency = inEmergency
        Wait(500)
    end
end)

createKeybind('policeLights', 'Gyrophares', config.controls.policeLights, function()
    if not isVehAllowed() then
        return
    end

    local state = Entity(VFW.PlayerData.vehicle).state

    if not state.stateEnsured then
        return
    end

    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

    local curMode = state.lightsOn
    state:set('lightsOn', not curMode, true)

    if not curMode or state.sirenMode == 0 then
        return
    end

    state:set('sirenMode', 0, true)
end)

local restoreSiren = 0
stateBagWrapper('horn', function(veh, value)
    local relHornId = hornVehicles[veh]

    if relHornId then
        if releaseSound(veh, relHornId) then
            hornVehicles[veh] = nil
        end
    end

    if not value then
        return
    end

    local soundId = GetSoundId()

    hornVehicles[veh] = soundId
    local vehModel = GetEntityModel(veh)
    local audioName = 'SIRENS_AIRHORN'
    local audioRef

    for i = 1, #config.sirens do
        local sirenConfig = config.sirens[i]

        if (not sirenConfig.models or sirenConfig.models[vehModel]) and sirenConfig.horn then
            audioName = sirenConfig.horn?.audioName or audioName
            audioRef = sirenConfig.horn?.audioRef or audioRef
        end
    end

    PlaySoundFromEntity(soundId, audioName, veh, audioRef or 0, false, 0)
end)

createKeybind('policeHorn', 'Klaxon sirène', config.controls.policeHorn, function()
    if not isVehAllowed() then
        return
    end

    local state = Entity(VFW.PlayerData.vehicle).state

    if not state.stateEnsured then
        return
    end

    if state.sirenMode == 0 then
        restoreSiren = state.sirenMode
        state:set('sirenMode', 0, true)
    end

    state:set('horn', not state.horn, true)
end, function()
    if not VFW.PlayerData.vehicle or GetVehicleClass(VFW.PlayerData.vehicle) ~= 18 then
        return
    end

    local state = Entity(VFW.PlayerData.vehicle).state

    SetTimeout(0, function()
        if state.horn then
            state:set('horn', false, true)
        end

        if state.lightsOn and state.sirenMode == 0 and restoreSiren > 0 then
            state:set('sirenMode', restoreSiren, true)
            restoreSiren = 0
        end
    end)
end)

stateBagWrapper('sirenMode', function(veh, soundMode)
    local usedSound = sirenVehicles[veh]

    if usedSound then
        if releaseSound(veh, usedSound) then
            sirenVehicles[veh] = nil
        end
    end

    if soundMode == 0 or not soundMode then
        return
    end

    local soundId = GetSoundId()
    sirenVehicles[veh] = soundId

    local audioName
    local audioRef

    if not config.disableDamagedSirens and (config.useEngineHealth and GetVehicleEngineHealth(VFW.PlayerData.vehicle) or GetVehicleBodyHealth(VFW.PlayerData.vehicle)) <= config.damageThreshold then
        audioName = 'PLAYER_FUCKED_SIREN'
    else
        local vehModel = GetEntityModel(veh)

        for i = 1, #config.sirens do
            local sirenConfig = config.sirens[i]
            if (not sirenConfig.models or sirenConfig.models[vehModel]) and sirenConfig.sirenModes[soundMode] then
                audioName = sirenConfig.sirenModes[soundMode]?.audioName or audioName
                audioRef = sirenConfig.sirenModes[soundMode]?.audioRef or audioRef
            end
        end
    end

    if not audioName then
        console.debug(('^1ERROR: No sound found for siren mode %d on vehicle model (hash) %s^7'):format(soundMode, GetEntityModel(veh)))
        return
    end

    PlaySoundFromEntity(soundId, audioName, veh, audioRef or 0, false, 0)
end)

createKeybind('sirenToggle', 'Sirène on/off', config.controls.sirenToggle, function()
    if not isVehAllowed() then
        return
    end

    local state = Entity(VFW.PlayerData.vehicle).state

    if not state.stateEnsured or not state.lightsOn or state.horn then
        return
    end

    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

    local newSiren = state.sirenMode > 0 and 0 or 1

    state:set('sirenMode', newSiren, true)
end)

local Rpressed = false
createKeybind('sirenCycle', 'Changer son sirène', config.controls.sirenCycle, function()
    if not isVehAllowed() then
        return
    end

    local state = Entity(VFW.PlayerData.vehicle).state

    if not state.stateEnsured then
        return
    end

    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

    if state.sirenMode == 0 and not Rpressed then
        local sirenMode = state.sirenMode > 0 and 0 or 1

        state:set('sirenMode', sirenMode, true)

        disableKeybind('sirenToggle', true)
        disableKeybind('policeLights', true)
        disableKeybind('policeHorn', true)

        Rpressed = true
    elseif state.sirenMode > 0 and state.lightsOn and not Rpressed then
        local newSiren = state.sirenMode + 1 > 3 and 1 or state.sirenMode + 1

        state:set('sirenMode', newSiren, true)
    end

end, function()
    if not Rpressed then
        return
    end

    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

    disableKeybind('sirenToggle', false)
    disableKeybind('policeLights', false)
    disableKeybind('policeHorn', false)

    if VFW.PlayerData.vehicle and DoesEntityExist(VFW.PlayerData.vehicle) then
        SetTimeout(0, function()
            if not VFW.PlayerData.vehicle or not DoesEntityExist(VFW.PlayerData.vehicle) then
                Rpressed = false
                return
            end
            local state = Entity(VFW.PlayerData.vehicle).state

            if state.sirenMode > 0 then
                state:set('sirenMode', 0, true)
            end

            Rpressed = false
        end)
    end
end)
