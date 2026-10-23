VFW.Commands = {}

local registered = {}
local executors = {}

--- Une commande peut accepter plusieurs permissions : il suffit d en avoir une.
---
--- Certaines commandes existent en double dans la configuration — une entree pour
--- la commande, une autre pour le menu equivalent — et n en declaraient qu une.
--- Cocher la mauvaise ne donnait alors rien du tout.
---@param permission string|string[]|nil
---@param xPlayer table
---@return boolean
local function allowed(permission, xPlayer)
    if not permission or permission == "" then return true end

    if type(permission) == "table" then
        for i = 1, #permission do
            if xPlayer.hasPermission(permission[i]) then return true end
        end
        return false
    end

    return xPlayer.hasPermission(permission) == true
end

function VFW.RegisterCommand(name, permission, handler, options)
    options = options or {}

    registered[name] = {
        name = name,
        permission = permission,
        help = options.help or "",
        params = options.params or {},
    }

    local function execute(source, args, raw)
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

        if not allowed(permission, xPlayer) then
            xPlayer.showNotification({
                type = "STAFF",
                variant = "ERROR",
                subtitle = "Permissions",
                message = "Vous n'avez pas la permission d'utiliser cette commande.",
            })
            return
        end

        handler(source, xPlayer, args, raw)
    end
    executors[name] = execute
    RegisterCommand(name, execute, false)
end

-- Le chat personnalise transmet ici les commandes serveur. Ne jamais utiliser
-- ExecuteCommand cote serveur : il les executerait comme la console (source 0).

--- La commande existe-t-elle quelque part sur le serveur ?
---
--- Le pont ne connaissait que les commandes declarees par VFW.RegisterCommand. Toute
--- commande enregistree autrement — et il y en a — etait annoncee « inconnue » au
--- joueur, alors meme que le jeu la connait. Un message faux est plus trompeur que
--- pas de message du tout : on consulte le registre du jeu avant de se prononcer.
---@param name string
---@return boolean
local function knownToServer(name)
    local ok, list = pcall(GetRegisteredCommands)
    if not ok or type(list) ~= "table" then return false end

    for i = 1, #list do
        local entry = list[i]
        local entryName = type(entry) == "table" and entry.name or entry
        if type(entryName) == "string" and entryName:lower() == name then return true end
    end

    return false
end
RegisterNetEvent("vfw:command:run", function(name, args)
    local src = tonumber(source)
    if not src or src <= 0 then return end
    if type(name) ~= "string" or #name > 64 then return end
    name = name:lower()
    if not name:match("^[%w_:%-]+$") or type(args) ~= "table" or #args > 32 then return end

    local cleanArgs, length = {}, #name
    for i = 1, #args do
        if type(args[i]) ~= "string" or #args[i] > 512 then return end
        length = length + #args[i] + 1
        if length > 2048 then return end
        cleanArgs[i] = args[i]
    end

    local execute = executors[name]
    if not execute then
        -- Connue du jeu mais pas de VFW : elle a son propre chemin, on se tait.
        if not knownToServer(name) then
            TriggerClientEvent("chat:addMessage", src,
                { args = { "Commandes", "Commande inconnue : /" .. name } })
        end
        return
    end
    if VFW.CommandCooldownAllows and not VFW.CommandCooldownAllows(src, name) then return end

    local raw = name .. (#cleanArgs > 0 and (" " .. table.concat(cleanArgs, " ")) or "")
    local ok, err = pcall(execute, src, cleanArgs, raw)
    if not ok then
        console.error(("[commandes] /%s (joueur %s) : %s"):format(name, src, tostring(err)))
        TriggerClientEvent("chat:addMessage", src, { args = { "Commandes", "Erreur pendant /" .. name .. ". Consultez la console serveur." } })
    end
end)

function VFW.GetRegisteredCommands()
    return registered
end

local function buildSuggestionsFor(xPlayer)
    local out, n = {}, 0
    for _, cmd in pairs(registered) do
        if allowed(cmd.permission, xPlayer) then
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
