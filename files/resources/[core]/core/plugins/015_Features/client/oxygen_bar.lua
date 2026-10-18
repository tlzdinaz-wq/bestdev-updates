-- Système de barre d'oxygène
VFW = VFW or {}
local isUnderwater = false
local oxygenLevel = 100.0
local hideOxygen = GetResourceKvpString("hide_oxygen") == "1"

function VFW.IsOxygenBarHidden()
    return hideOxygen
end

function VFW.SetOxygenBarHidden(hidden)
    hideOxygen = hidden == true
    SetResourceKvp("hide_oxygen", hideOxygen and "1" or "0")
    if hideOxygen or not isUnderwater then
        VFW.PushOxygenBar(false, 100)
    else
        VFW.PushOxygenBar(true, oxygenLevel)
    end
end

function VFW.PushOxygenBar(visible, percent)
    if hideOxygen then
        visible = false
    end
    SendNUIMessage({
        action = "nui:oxygenBar:update",
        data = {
            visible = visible == true,
            percent = percent
        }
    })
end

CreateThread(function()
    while true do
        Wait(100)

        local ped = VFW.PlayerData.ped
        if not ped or ped == 0 then
            goto continue
        end

        local wasUnderwater = isUnderwater
        isUnderwater = IsPedSwimmingUnderWater(ped)
        local diving = VFW.PlayerIsDiving and VFW.PlayerIsDiving()

        if hideOxygen then
            if isUnderwater and not wasUnderwater then
                VFW.PushOxygenBar(false, 100)
            end
        elseif isUnderwater and not diving then
            local maxOxygenTime = 10.0
            local oxygenTime = GetPlayerUnderwaterTimeRemaining(PlayerId())
            oxygenLevel = math.max(0, math.min(100, (oxygenTime / maxOxygenTime) * 100))
            VFW.PushOxygenBar(true, oxygenLevel)
        elseif wasUnderwater and not diving then
            VFW.PushOxygenBar(false, 100)
            oxygenLevel = 100.0
        end


        ::continue::
    end
end)
