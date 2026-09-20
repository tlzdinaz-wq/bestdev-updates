---@meta _
---@diagnostic disable: duplicate-doc-field

FuelingAnimation = {}

local isPlayerFrozen = false
local animationActive = false
local animationThread = nil

function FuelingAnimation.Start()
    if animationActive then
        return
    end

    local playerPed = PlayerPedId()
    local animConfig = FuelingConfig.FuelingAnimation

    RequestAnimDict(animConfig.dict)
    while not HasAnimDictLoaded(animConfig.dict) do
        Wait(1)
    end

    FuelingAnimation.FreezePlayer(true)

    TaskPlayAnim(
        playerPed,
        animConfig.dict,
        animConfig.name,
        8.0,
        -8.0,
        -1,
        animConfig.flag,
        0.0,
        false, false, false
    )

    animationActive = true

    Wait(100)
    if PumpObject.IsAttached() then
        PumpObject.Detach()
        Wait(50)
        PumpObject.Attach()
    end

    animationThread = CreateThread(function()
        while animationActive do
            Wait(1000)

            local playerPed = PlayerPedId()

            if not IsEntityPlayingAnim(playerPed, animConfig.dict, animConfig.name, 3) then
                if animationActive then
                    TaskPlayAnim(
                        playerPed,
                        animConfig.dict,
                        animConfig.name,
                        8.0, -8.0, -1,
                        animConfig.flag,
                        0.0, false, false, false
                    )
                end
            end
        end
    end)
end

function FuelingAnimation.Stop()
    if not animationActive then
        return
    end

    local playerPed = PlayerPedId()
    local animConfig = FuelingConfig.FuelingAnimation

    StopAnimTask(playerPed, animConfig.dict, animConfig.name, 1.0)

    FuelingAnimation.FreezePlayer(false)

    animationActive = false
    if animationThread then
        animationThread = nil
    end
end

---@param freeze boolean
function FuelingAnimation.FreezePlayer(freeze)
    local playerPed = PlayerPedId()

    if freeze then
        FreezeEntityPosition(playerPed, true)
        SetPlayerControl(PlayerId(), false, 0)
        isPlayerFrozen = true

        CreateThread(function()
            while isPlayerFrozen do
                Wait(0)

                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 32, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 35, true)
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
                DisableControlAction(0, 36, true)
                DisableControlAction(0, 73, true)

                if IsDisabledControlJustPressed(0, 73) then
                    TriggerEvent('fl_gasstation:cancelFueling')
                    return
                end
            end
        end)
    else
        FreezeEntityPosition(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)
        isPlayerFrozen = false
    end
end

---@return boolean
function FuelingAnimation.IsPlayerFrozen()
    return isPlayerFrozen
end

---@return boolean
function FuelingAnimation.IsActive()
    return animationActive
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        FuelingAnimation.Stop()
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        if animationActive or isPlayerFrozen then
            local playerPed = PlayerPedId()

            if IsEntityDead(playerPed) then
                FuelingAnimation.Stop()
            end
        end
    end
end)
