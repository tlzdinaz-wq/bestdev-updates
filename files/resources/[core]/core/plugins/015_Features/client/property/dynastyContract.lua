---@meta _
---@diagnostic disable: duplicate-doc-field

--- Dynasty 8 Contract System - Client
--- Handles contract UI for the target player (buyer/renter)

local dynastyContractState = {
    pendingContract = nil,
    isSigning = false
}

-- NUI Callbacks

--- Handle contract signature
RegisterNUICallback("dynastyContract:sign", function(data, cb)
    if not dynastyContractState.pendingContract or dynastyContractState.isSigning then
        cb({ ok = false })
        return
    end

    dynastyContractState.isSigning = true

    -- Play signing animation
    local ped = PlayerPedId()

    RequestAnimDict("amb@world_human_clipboard@male@base")
    while not HasAnimDictLoaded("amb@world_human_clipboard@male@base") do
        Wait(10)
    end

    TaskPlayAnim(ped, "amb@world_human_clipboard@male@base", "base", 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Show progress bar for signing (3 seconds)
    local progressResult = VFW.Nui.ProgressBar("Signature du contrat...", 3000)

    ClearPedTasks(ped)

    if progressResult then
        -- Send to server
        TriggerServerEvent("dynastyContract:signed", dynastyContractState.pendingContract.contractId, data.paymentMethod or "bank")

        dynastyContractState.pendingContract = nil
        dynastyContractState.isSigning = false

        -- Close NUI
        SendNUIMessage({
            action = "dynastyContract:close"
        })

        cb({ ok = true })
    else
        dynastyContractState.isSigning = false
        cb({ ok = false })
    end
end)

--- Handle contract refusal
RegisterNUICallback("dynastyContract:refuse", function(data, cb)
    if not dynastyContractState.pendingContract then
        cb({ ok = false })
        return
    end

    TriggerServerEvent("dynastyContract:refused", dynastyContractState.pendingContract.contractId)

    dynastyContractState.pendingContract = nil

    SendNUIMessage({
        action = "dynastyContract:close"
    })

    cb({ ok = true })
end)

--- Handle contract expiration (client-side timeout)
RegisterNUICallback("dynastyContract:expired", function(_, cb)
    if dynastyContractState.pendingContract then
        TriggerServerEvent("dynastyContract:expired", dynastyContractState.pendingContract.contractId)
        dynastyContractState.pendingContract = nil
    end

    cb({ ok = true })
end)

--- Handle contract close
RegisterNUICallback("dynastyContract:close", function(_, cb)
    VFW.Nui.Focus(false, false)
    dynastyContractState.pendingContract = nil
    dynastyContractState.isSigning = false
    cb({ ok = true })
end)

-- Server Events

--- Receive contract offer
RegisterNetEvent("dynastyContract:receiveOffer", function(contractData)
    dynastyContractState.pendingContract = contractData
    dynastyContractState.isSigning = false

    -- Open NUI
    SendNUIMessage({
        action = "dynastyContract:offer",
        data = contractData
    })

    VFW.Nui.Focus(true, false)

    -- Play notification sound
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
end)

--- Contract signed successfully
RegisterNetEvent("dynastyContract:signedSuccess", function()
    SendNUIMessage({
        action = "dynastyContract:close"
    })

    VFW.Nui.Focus(false, false)
end)

--- View signed contract (from item usage)
local isReadingContract = false
RegisterNetEvent("dynastyContract:viewDocument", function(contractMetadata)
    -- Close inventory first
    VFW.OpenInventory()
    while VFW.StateInventory() do Wait(10) end
    Wait(200)

    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "dynastyContract:view",
        data = contractMetadata
    })

    isReadingContract = true
    CreateThread(function()
        while isReadingContract do
            Wait(0)
            DisableAllControlActions(0)
        end
    end)
end)

--- NUI Callback: Close view mode
RegisterNUICallback("dynastyContract:closeView", function(_, cb)
    VFW.Nui.Focus(false, false)
    isReadingContract = false
    cb({ ok = true })
end)

--- Contract cancelled by agent or expired server-side
RegisterNetEvent("dynastyContract:cancelled", function()
    VFW.ShowNotification({
        type = 'DYNASTY_INFO',
        content = "L'offre de contrat immobilier a été annulée."
    })

    dynastyContractState.pendingContract = nil

    SendNUIMessage({
        action = "dynastyContract:close"
    })

    VFW.Nui.Focus(false, false)
end)
