---@meta _
---@diagnostic disable: duplicate-doc-field

-- =====================================================================
-- Scam Computer — Client (adapté au framework VFW)
-- Fait le pont entre le NUI (iframe React "ScamComputer") et le serveur.
-- =====================================================================

local display = false

local function SetDisplay(state)
    if display == state then return end
    display = state

    VFW.Nui.Focus(state, false)
    SendNUIMessage({
        action = "scamComputer:visible",
        data = { status = state }
    })

    local ped = PlayerPedId()

    if state then
        TriggerServerEvent("scamComputer:loadData")

        local dict = ScamConfig.Animation.dict
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
        TaskPlayAnim(ped, dict, ScamConfig.Animation.name, 8.0, -8.0, -1, 50, 0, false, false, false)
    else
        ClearPedTasks(ped)
        RemoveAnimDict(ScamConfig.Animation.dict)
    end
end

-- Ouverture / fermeture depuis l'item (serveur)
RegisterNetEvent("scamComputer:open", function()
    SetDisplay(not display)
end)

-- Données envoyées par le serveur → transmises au NUI
RegisterNetEvent("scamComputer:receiveData", function(data)
    if not data then return end
    SendNUIMessage({
        action = "scamComputer:loadData",
        data = {
            balance = data.balance,
            scams = data.activeScams,
            transactions = data.transactions,
            currentLeads = data.currentLeads,
            usedLeadIds = data.usedLeadIds,
            lastLeadsGenerationTime = data.lastLeadsGenerationTime,
        }
    })
end)

-- ---------------------------------------------------------------------
-- Callbacks NUI (émis par l'iframe via https://core/scamComputer:*)
-- ---------------------------------------------------------------------
RegisterNUICallback("scamComputer:close", function(_, cb)
    SetDisplay(false)
    cb("ok")
end)

RegisterNUICallback("scamComputer:saveData", function(data, cb)
    TriggerServerEvent("scamComputer:saveData", data)
    cb("ok")
end)

RegisterNUICallback("scamComputer:withdraw", function(data, cb)
    TriggerServerEvent("scamComputer:withdraw", data and data.amount or 0)
    cb("ok")
end)

-- ---------------------------------------------------------------------
-- Désactive les contrôles gênants tant que le terminal est ouvert
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        local sleep = 500
        if display then
            sleep = 0
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true)  -- Enter
            DisableControlAction(0, 322, true) -- ESC (géré par le NUI)
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
        end
        Wait(sleep)
    end
end)

-- Nettoyage si la ressource s'arrête pendant l'utilisation
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() and display then
        display = false
        VFW.Nui.Focus(false, false)
        ClearPedTasks(PlayerPedId())
    end
end)
