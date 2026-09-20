VFW.RegisteredCallbacks = VFW.RegisteredCallbacks or {}

local nativeRegister = RegisterServerCallback

function RegisterServerCallback(eventName, handlerFn)
    if type(eventName) ~= "string" or eventName == "" then
        console.error(("[Callbacks] nom de callback invalide (%s)"):format(type(eventName)))
        return false
    end

    if type(handlerFn) ~= "function" then
        console.error(("[Callbacks] handler invalide pour '%s' (%s)"):format(eventName, type(handlerFn)))
        return false
    end

    if VFW.RegisteredCallbacks[eventName] then
        console.error(("[Callbacks] doublon ignoré : '%s' est déjà enregistré"):format(eventName))
        return false
    end

    local ok, err = pcall(nativeRegister, eventName, handlerFn)
    if not ok then
        console.error(("[Callbacks] enregistrement refusé pour '%s' : %s"):format(eventName, tostring(err)))
        return false
    end

    VFW.RegisteredCallbacks[eventName] = true
    return true
end

function VFW.HasServerCallback(eventName)
    if type(eventName) ~= "string" then return false end
    return VFW.RegisteredCallbacks[eventName] == true
end

function VFW.RegisterServerCallbackSafe(eventName, handlerFn)
    return RegisterServerCallback(eventName, handlerFn)
end

function VFW.GetServerCallbacks()
    local out, n = {}, 0
    for name in pairs(VFW.RegisteredCallbacks) do
        n = n + 1
        out[n] = name
    end
    table.sort(out)
    return out
end

function VFW.TriggerClientCallbackSafe(source, eventName, ...)
    source = tonumber(source)
    if not source or source <= 0 then return nil end
    if type(eventName) ~= "string" or eventName == "" then return nil end
    if not GetPlayerName(source) then return nil end

    local ok, result = pcall(TriggerClientCallback, source, eventName, ...)
    if not ok then
        console.warn(("[Callbacks] TriggerClientCallback '%s' a échoué : %s"):format(eventName, tostring(result)))
        return nil
    end

    return result
end

function VFW.TriggerClientCallbackAsync(source, eventName, cb, ...)
    local args = table.pack(...)

    CreateThread(function()
        local result = VFW.TriggerClientCallbackSafe(source, eventName, table.unpack(args, 1, args.n))
        if type(cb) == "function" then
            local ok, err = pcall(cb, result)
            if not ok then
                console.error(("[Callbacks] callback asynchrone '%s' en erreur : %s"):format(eventName, tostring(err)))
            end
        end
    end)
end

CreateThread(function()
    while type(VFW.RegisterCommand) ~= "function" do Wait(100) end

    VFW.RegisterCommand("callbacks", "dev_tools", function(_, _, _)
        local list = VFW.GetServerCallbacks()
        console.info(("[Callbacks] %d callbacks serveur enregistrés après la garde"):format(#list))
        for i = 1, #list do
            console.info(("  - %s"):format(list[i]))
        end
    end, {
        help = "Lister les callbacks serveur enregistrés (console)",
        params = {},
        allowConsole = true,
    })
end)

console.init("Callbacks", "garde anti-doublon active")
