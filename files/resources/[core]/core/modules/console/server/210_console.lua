local FLOOD_WINDOW = 10000
local FLOOD_LIMIT = 25
local SWEEP_INTERVAL = 60000

local floodCounters = {}

VFW.Console = VFW.Console or {}

local function playerLabel(src)
    local name = GetPlayerName(src)
    if name then
        return ("%s [%d]"):format(name, src)
    end
    return ("source %d"):format(src)
end

local function trackFlood(src, eventName)
    src = tonumber(src)
    if not src or src <= 0 then return end

    local now = GetGameTimer()
    local entry = floodCounters[src]

    if not entry or (now - entry.since) > FLOOD_WINDOW then
        entry = { since = now, count = 0, warned = false }
        floodCounters[src] = entry
    end

    entry.count = entry.count + 1

    if entry.count > FLOOD_LIMIT and not entry.warned then
        entry.warned = true
        console.warn(("[Console] %s a émis %d fois '%s' en moins de %d ms (flood suspecté)")
            :format(playerLabel(src), entry.count, eventName, FLOOD_WINDOW))
    end
end

RegisterNetEvent("log:debugLine", function()
    local source = source
    trackFlood(source, "log:debugLine")
end)

RegisterNetEvent("log:warning", function()
    local source = source
    trackFlood(source, "log:warning")
end)

RegisterNetEvent("qx:toggleDebug", function()
    local source = source
    if type(source) ~= "number" or source <= 0 then return end

    trackFlood(source, "qx:toggleDebug")

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("dev_tools") then
        console.warn(("[Console] %s a basculé le debug console SANS la permission 'dev_tools' (event shared non protégeable)")
            :format(playerLabel(source)))
    end
end)

function VFW.Console.SetLevel(level)
    level = tonumber(level)
    if not level or level < 0 or level > 4 then return false end
    console.setLevel(level)
    return true
end

function VFW.Console.GetLevel()
    return console.Level
end

function VFW.Console.SendToClient(target, message, ...)
    target = tonumber(target)
    if not target or target <= 0 then return false end
    if type(message) ~= "string" then message = tostring(message) end
    TriggerClientEvent("log:debugLine", target, message, ...)
    return true
end

function VFW.Console.WarnClient(target, message, ...)
    target = tonumber(target)
    if not target or target <= 0 then return false end
    if type(message) ~= "string" then message = tostring(message) end
    TriggerClientEvent("log:warning", target, message, ...)
    return true
end

function VFW.Console.BroadcastToClients(message, ...)
    if type(message) ~= "string" then message = tostring(message) end
    TriggerClientEvent("log:debugLine", -1, message, ...)
    return true
end

function VFW.Console.ToggleClientDebug(target)
    target = tonumber(target)
    if not target or target <= 0 then return false end
    if not VFW.GetPlayerFromId(target) and not GetPlayerName(target) then return false end
    TriggerClientEvent("qx:toggleDebug", target)
    return true
end

AddEventHandler("vfw:playerDropped", function(source)
    local src = tonumber(source)
    if src then floodCounters[src] = nil end
end)

CreateThread(function()
    while true do
        Wait(SWEEP_INTERVAL)
        local now = GetGameTimer()
        for src, entry in pairs(floodCounters) do
            if (now - entry.since) > (FLOOD_WINDOW * 3) then
                floodCounters[src] = nil
            end
        end
    end
end)

CreateThread(function()
    while type(VFW.RegisterCommand) ~= "function" do Wait(100) end

    VFW.RegisterCommand("consolelevel", "dev_tools", function(source, xPlayer, args)
        local level = tonumber(args and args[1])

        if not level then
            console.info(("[Console] Niveau courant : %d (0=off, 1=error/info, 2=warn, 3=success, 4=debug)")
                :format(console.Level))
            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "INFO",
                    subtitle = "Console",
                    message = ("Niveau de log courant : %d"):format(console.Level),
                })
            end
            return
        end

        if not VFW.Console.SetLevel(level) then
            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "ERROR",
                    subtitle = "Console",
                    message = "Ce niveau n'est pas valide : entrez un entier entre 0 et 4.",
                })
            else
                console.warn("[Console] Niveau invalide, attendu un entier entre 0 et 4.")
            end
            return
        end

        console.info(("[Console] Niveau de log serveur réglé sur %d"):format(console.Level))

        if xPlayer then
            xPlayer.showNotification({
                type = "STAFF",
                variant = "SUCCESS",
                subtitle = "Console",
                message = ("Niveau de log serveur réglé sur %d."):format(console.Level),
            })
        end
    end, {
        help = "Régler le niveau de log de la console serveur (0 à 4)",
        params = { { name = "niveau", help = "0=off, 1=error, 2=warn, 3=success, 4=debug" } },
        allowConsole = true,
    })

    VFW.RegisterCommand("clientdebug", "dev_tools", function(source, xPlayer, args)
        local target = tonumber(args and args[1]) or source

        if not VFW.Console.ToggleClientDebug(target) then
            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "ERROR",
                    subtitle = "Console",
                    message = "Joueur introuvable.",
                })
            else
                console.warn("[Console] Joueur introuvable.")
            end
            return
        end

        console.info(("[Console] Debug console basculé pour %s"):format(playerLabel(target)))

        if xPlayer then
            xPlayer.showNotification({
                type = "STAFF",
                variant = "SUCCESS",
                subtitle = "Console",
                message = ("Debug console basculé pour le joueur %d."):format(target),
            })
        end
    end, {
        help = "Basculer les logs de debug dans la console d'un joueur",
        params = { { name = "id", help = "ID serveur du joueur (défaut : vous)" } },
        allowConsole = true,
    })
end)

console.init("Console", "module serveur chargé")
