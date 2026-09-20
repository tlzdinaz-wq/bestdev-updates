--[[
    reboot_core — serveur

    /rebootcore : arrête puis relance `core` et ses dépendants dans l'ordre.

    Réservé à la console et aux joueurs disposant de l'ACE RebootConfig.Ace.
    Déclarer dans server.cfg :
        add_ace group.admin command.rebootcore allow
]]

local rebooting = false

local function notify(target, message, color)
    TriggerClientEvent("chat:addMessage", target, {
        color = color or { 255, 165, 0 },
        multiline = true,
        args = { "reboot_core", message },
    })
end

---@param resource string
---@return boolean started, string state
local function restartOne(resource)
    local state = GetResourceState(resource)

    -- "missing" = pas sur le disque ; "unknown" = pas connue du serveur.
    if state == "missing" or state == "unknown" then
        return false, state
    end

    -- Une resource commentée dans server.cfg est "stopped" : la démarrer ici
    -- irait contre la configuration, on la saute.
    if state == "stopped" then
        return false, state
    end

    StopResource(resource)
    Wait(RebootConfig.DelayBetween)
    StartResource(resource)

    return true, state
end

---@param invoker string
---@return boolean ok, string? err
local function restartCascade(invoker)
    if rebooting then return false, "Un redémarrage est déjà en cours." end
    rebooting = true

    CreateThread(function()
        if RebootConfig.WarnPlayers then
            notify(-1, RebootConfig.WarnMessage)
        end

        local restarted, skipped = 0, 0

        for i = 1, #RebootConfig.Cascade do
            local resource = RebootConfig.Cascade[i]
            local ok, state = restartOne(resource)

            if ok then
                restarted = restarted + 1
                print(("[reboot_core] restart %s"):format(resource))

                -- core doit avoir rechargé items + jobs avant que ses
                -- consommateurs ne rappellent getSharedObject().
                if resource == "core" then
                    Wait(RebootConfig.CoreSettleDelay)
                else
                    Wait(RebootConfig.DelayBetween)
                end
            else
                skipped = skipped + 1
                print(("[reboot_core] ignorée : %s (état '%s')"):format(resource, state))
            end
        end

        print(("[reboot_core] cascade terminée — %d relancée(s), %d ignorée(s) — demandée par %s")
            :format(restarted, skipped, tostring(invoker)))

        rebooting = false
    end)

    return true
end

RegisterCommand(RebootConfig.Command, function(source)
    local invoker = "console"

    if source > 0 then
        if not IsPlayerAceAllowed(source, RebootConfig.Ace) then
            notify(source, "Permission refusée.", { 255, 0, 0 })
            return
        end

        invoker = ("%s (%d)"):format(GetPlayerName(source) or "?", source)
    end

    local ok, err = restartCascade(invoker)

    if not ok and source > 0 then
        notify(source, err, { 255, 0, 0 })
    elseif not ok then
        print(("[reboot_core] %s"):format(err))
    end
end, false)

exports("restartCascade", restartCascade)
exports("isRebooting", function() return rebooting end)
