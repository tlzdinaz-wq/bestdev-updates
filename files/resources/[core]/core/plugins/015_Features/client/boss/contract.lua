-- Employment Contract System - Client
local contractState = {
    pendingContract = nil,
    isSigning = false
}

-- NUI Callbacks

-- Handle contract signature
RegisterNUICallback("contract:sign", function(data, cb)
    if not contractState.pendingContract or contractState.isSigning then
        cb({ ok = false })
        return
    end

    contractState.isSigning = true

    -- Play signing animation
    local ped = PlayerPedId()

    -- Request anim dict
    RequestAnimDict("amb@world_human_clipboard@male@base")
    while not HasAnimDictLoaded("amb@world_human_clipboard@male@base") do
        Wait(10)
    end

    -- Play clipboard animation
    TaskPlayAnim(ped, "amb@world_human_clipboard@male@base", "base", 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Show progress bar for signing (3 seconds)
    local progressResult = VFW.Nui.ProgressBar("Signature du contrat...", 3000)

    ClearPedTasks(ped)

    if progressResult then
        -- Send to server
        TriggerServerEvent("contract:signed", contractState.pendingContract.contractId)

        contractState.pendingContract = nil
        contractState.isSigning = false

        -- Close NUI
        SendNUIMessage({
            action = "contract:close"
        })

        cb({ ok = true })
    else
        contractState.isSigning = false
        cb({ ok = false })
    end
end)

-- Handle contract refusal
RegisterNUICallback("contract:refuse", function(data, cb)
    if not contractState.pendingContract then
        cb({ ok = false })
        return
    end

    TriggerServerEvent("contract:refused", contractState.pendingContract.contractId)

    contractState.pendingContract = nil

    SendNUIMessage({
        action = "contract:close"
    })

    cb({ ok = true })
end)

-- Handle contract expiration (client-side timeout)
RegisterNUICallback("contract:expired", function(_, cb)
    if contractState.pendingContract then
        TriggerServerEvent("contract:expired", contractState.pendingContract.contractId)
        contractState.pendingContract = nil
    end

    cb({ ok = true })
end)

-- Handle contract close
local isReading = false
RegisterNUICallback("contract:close", function(_, cb)
    VFW.Nui.Focus(false, false)
    contractState.pendingContract = nil
    contractState.isSigning = false
    isReading = false
    cb({ ok = true })
end)

-- Server Events

-- Receive contract offer
RegisterNetEvent("contract:receiveOffer", function(contractData)
    contractState.pendingContract = contractData
    contractState.isSigning = false

    -- Open NUI
    SendNUIMessage({
        action = "contract:offer",
        data = contractData
    })

    VFW.Nui.Focus(true, false)

    -- Play notification sound
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
end)

-- Contract signed successfully
RegisterNetEvent("contract:signedSuccess", function(companyLabel, roleLabel)
    VFW.ShowNotification({
        type = 'VERT',
        content = ("Vous avez signé un contrat avec %s en tant que %s !"):format(companyLabel, roleLabel)
    })

    SendNUIMessage({
        action = "contract:close"
    })

    VFW.Nui.Focus(false, false)
end)
-- Contract cancelled by recruiter
RegisterNetEvent("contract:cancelled", function()
    VFW.ShowNotification({
        type = 'ORANGE',
        content = "L'offre de contrat a été annulée par le recruteur."
    })

    contractState.pendingContract = nil

    SendNUIMessage({
        action = "contract:close"
    })

    VFW.Nui.Focus(false, false)


end)

-- View signed contract (from item usage)


RegisterNetEvent("contract:viewDocument", function(contractMetadata)
    -- Gestion fermeture inventaire
    VFW.OpenInventory()
    while VFW.StateInventory() do Wait(10) end
    Wait(200) -- Délai court

    -- 1. Focus NUI
    VFW.Nui.Focus(true, false)

    -- 2. Envoi des données au JS
    SendNUIMessage({
        action = "contract:view",
        data = contractMetadata
    })

    -- 3. VERROUILLAGE TOTAL DU JOUEUR
    isReading = true

    CreateThread(function()
        while isReading do
            Wait(0)
            -- Désactive TOUTES les actions (Mouvement, Combat, Conduite)
            DisableAllControlActions(0)

            -- Si tu veux quand même autoriser la souris pour cliquer dans l'UI (normalement géré par SetNuiFocus, mais au cas où)
            -- EnableControlAction(0, 13, true) -- Mouse X
            -- EnableControlAction(0, 12, true) -- Mouse Y

            -- Bloque spécifiquement la caméra et le tir pour être sûr
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee
        end
    end)
end)