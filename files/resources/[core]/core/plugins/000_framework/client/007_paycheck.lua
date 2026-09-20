---@meta _
---@diagnostic disable: duplicate-doc-field

-- Signale au serveur que le joueur est actif quand il appuie sur la touche
-- d'interaction (E). Le serveur reset alors la position de référence du
-- check AFK pour ne pas retirer le joueur de son service.
local lastActivitySent = 0
local ACTIVITY_THROTTLE_MS = 60000

CreateThread(function()
    while true do
        Wait(0)
        if VFW.Interact.JustPressed(0, 38) or VFW.Interact.JustPressed(0, 51) then
            local now = GetGameTimer()
            if now - lastActivitySent >= ACTIVITY_THROTTLE_MS then
                lastActivitySent = now
                TriggerServerEvent('vfw:paycheck:activity')
            end
        end
    end
end)
