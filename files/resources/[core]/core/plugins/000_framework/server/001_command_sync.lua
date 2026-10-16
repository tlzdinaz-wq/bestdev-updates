VFW.Commands = {}

local registered = {}

function VFW.RegisterCommand(name, permission, handler, options)
    options = options or {}

    registered[name] = {
        name = name,
        permission = permission,
        help = options.help or "",
        params = options.params or {},
    }

    RegisterCommand(name, function(source, args, raw)
        source = tonumber(source) or 0

        if source == 0 then
            if options.allowConsole then
                handler(0, nil, args, raw)
            else
                console.warn(("La commande /%s ne peut pas être lancée depuis la console."):format(name))
            end
            return
        end

        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer then return end

        if permission and permission ~= "" and not xPlayer.hasPermission(permission) then
            xPlayer.showNotification({
                type = "STAFF",
                variant = "ERROR",
                subtitle = "Permissions",
                message = "Vous n'avez pas la permission d'utiliser cette commande.",
            })
            return
        end

        handler(source, xPlayer, args, raw)
    end, false)
end

function VFW.GetRegisteredCommands()
    return registered
end

local function buildSuggestionsFor(xPlayer)
    local out, n = {}, 0
    for _, cmd in pairs(registered) do
        if not cmd.permission or cmd.permission == "" or xPlayer.hasPermission(cmd.permission) then
            n = n + 1
            out[n] = { name = cmd.name, help = cmd.help, params = cmd.params }
        end
    end
    return out
end

RegisterNetEvent("vfw:command:clientReady", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)

    if not xPlayer then
        local tries = 0
        while not xPlayer and tries < 100 do
            Wait(100)
            xPlayer = VFW.GetPlayerFromId(source)
            tries = tries + 1
        end
        if not xPlayer then return end
    end

    TriggerClientEvent("vfw:command:verifiedBatch", source, buildSuggestionsFor(xPlayer))
end)

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    TriggerClientEvent("vfw:command:verifiedBatch", source, buildSuggestionsFor(xPlayer))
end)
