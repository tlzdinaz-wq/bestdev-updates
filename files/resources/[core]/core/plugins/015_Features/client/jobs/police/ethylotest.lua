---@meta _
---@diagnostic disable: duplicate-doc-field

-- Ethylotest Client — Officer side (target selection + NUI device display)
-- Target side (popup to choose positive/negative + rate)

local POLICE_JOBS = PoliceJobsList
local GOUV_JOBS = { gouvernement = true }

-- Track NUI state for input control
local ethylotestNuiOpen = false

CreateThread(function()
    while true do
        if ethylotestNuiOpen then
            -- Disable camera/look controls so cursor stays usable
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack (prevent shooting)
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 37, true)  -- SelectWeapon (weapon wheel)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Officer: select target then start test
RegisterNetEvent("police:ethylotest:selectTarget", function()
    local job = VFW.PlayerData.job
    if not job or not job.onDuty then return end
    if not POLICE_JOBS[job.name] and not GOUV_JOBS[job.name] then return end

    VFW.CloseInventory()
    Wait(200)

    local playerId = VFW.StartSelect(5.0, true)
    if not playerId then return end

    local serverId = GetPlayerServerId(playerId)
    if not serverId or serverId <= 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Joueur introuvable." })
        return
    end

    ExecuteCommand("me effectue un test d'alcoolémie")
    TriggerServerEvent("police:ethylotest:startTest", serverId)
end)

-- Officer: show ethylotest device NUI
RegisterNetEvent("police:ethylotest:showDevice", function(state, rate)
    SendNUIMessage({
        action = "nui:ethylotest:showDevice",
        data = { state = state, rate = rate or 0 }
    })
    ethylotestNuiOpen = true
    VFW.Nui.Focus(true, true)
end)

-- Officer: close device NUI
RegisterNUICallback("ethylotest:closeDevice", function(_, cb)
    ethylotestNuiOpen = false
    VFW.Nui.Focus(false, false)
    cb("ok")
end)

-- Target: show popup to choose result
RegisterNetEvent("police:ethylotest:showPopup", function(agentName)
    SendNUIMessage({
        action = "nui:ethylotest:showPopup",
        data = { agentName = agentName }
    })
    ethylotestNuiOpen = true
    VFW.Nui.Focus(true, true)
end)

-- Target: dismiss popup (agent disconnected)
RegisterNetEvent("police:ethylotest:dismissPopup", function()
    SendNUIMessage({ action = "nui:ethylotest:dismissPopup", data = {} })
    ethylotestNuiOpen = false
    VFW.Nui.Focus(false, false)
end)

-- Target: respond to popup
RegisterNUICallback("ethylotest:respond", function(data, cb)
    ethylotestNuiOpen = false
    VFW.Nui.Focus(false, false)
    TriggerServerEvent("police:ethylotest:respond", data.isPositive, data.rate)
    cb("ok")
end)
