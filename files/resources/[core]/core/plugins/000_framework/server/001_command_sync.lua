VFW.Commands = {}

local registered = {}

function VFW.RegisterCommand(name, permission, handler, options)
    options = options or {}

    registered[name] = {
        name = name,
        permission = permission,
        help = options.help or "",
        params = options.params or {},
        handler = handler,
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

-- ── Pont chat / menu → commandes serveur ────────────────────────────────────────────────
-- Le chat exécute ce que le joueur tape avec ExecuteCommand, côté client : les commandes
-- enregistrées ici vivent sur le serveur et n'étaient donc jamais atteintes (/goto, /bring,
-- /return, /report, /revive…). Le client envoie le nom + les arguments, on rejoue le handler
-- avec la bonne source et la même vérification de permission qu'en console.
local runCooldown = {}

RegisterNetEvent("vfw:command:run", function(name, args)
    local source = source
    if type(name) ~= "string" then return end

    name = name:lower():gsub("^/", ""):gsub("[^%w_]", "")
    if name == "" or #name > 32 then return end

    local now = GetGameTimer()
    if runCooldown[source] and (now - runCooldown[source]) < 150 then return end
    runCooldown[source] = now

    local cmd = registered[name]
    if not cmd or type(cmd.handler) ~= "function" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if cmd.permission and cmd.permission ~= "" and not xPlayer.hasPermission(cmd.permission) then
        xPlayer.showNotification({
            type = "STAFF",
            variant = "ERROR",
            subtitle = "Permissions",
            message = "Vous n'avez pas la permission d'utiliser cette commande.",
        })
        return
    end

    local safeArgs = {}
    if type(args) == "table" then
        for i = 1, math.min(#args, 16) do
            local value = args[i]
            if type(value) == "string" or type(value) == "number" then
                safeArgs[#safeArgs + 1] = tostring(value):sub(1, 128)
            end
        end
    end

    local ok, err = pcall(cmd.handler, source, xPlayer, safeArgs, name .. " " .. table.concat(safeArgs, " "))
    if not ok then
        console.error(("[commande] /%s a échoué : %s"):format(name, tostring(err)))
    end
end)

AddEventHandler("playerDropped", function()
    runCooldown[source] = nil
end)

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
