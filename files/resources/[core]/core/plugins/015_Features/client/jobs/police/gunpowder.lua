-- ============================================================
-- Gunpowder Residue Tracking (client)
-- Detects when the local player fires a weapon and notifies the server.
-- ============================================================

local hasNotifiedShot = false

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedArmed(ped, 4) then
            -- 4 = firearm
            if IsPedShooting(ped) and not hasNotifiedShot then
                hasNotifiedShot = true
                TriggerServerEvent("police:gunpowder:playerFired")

                -- Cooldown avant de pouvoir re-notifier (evite le spam)
                SetTimeout(5000, function()
                    hasNotifiedShot = false
                end)
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ============================================================
-- Use kit: select player and run test
-- ============================================================
RegisterNetEvent("police:gunpowder:useKit", function()
    VFW.CloseInventory()

    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = "ERROR",
            content = "Réservé aux policiers en service.",
        })
        return
    end

    local selectedPlayer = VFW.StartSelect(3.0, true)
    if not selectedPlayer then
        VFW.ShowNotification({ type = "ROUGE", content = "Aucun citoyen sélectionné." })
        return
    end

    local targetServerId = GetPlayerServerId(selectedPlayer)
    if not targetServerId then
        return
    end

    ExecuteCommand("me effectue un test de poudre")
    TriggerServerEvent("police:gunpowder:test", targetServerId)
end)
