TestServer = {}

TestServer.enabled = GetConvar("core_type", "FA") == "TEST"

TestServer.blockedCallbacks = {}
TestServer.blockedEvents = {}

function TestServer.IsBlockedCallback(name)
    if not TestServer.enabled then return false end
    return TestServer.blockedCallbacks[name] == true
end

function TestServer.IsBlockedEvent(name)
    if not TestServer.enabled then return false end
    return TestServer.blockedEvents[name] == true
end

function TestServer.NotifyBlocked(source)
    if not source or source == 0 then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF",
        variant = "WARNING",
        subtitle = "Serveur de test",
        message = "Cette action est désactivée sur le serveur de test.",
    })
end

function TestServer.Block(kind, ...)
    local target = kind == "callback" and TestServer.blockedCallbacks or TestServer.blockedEvents
    local names = { ... }
    for i = 1, #names do
        target[names[i]] = true
    end
end

if TestServer.enabled then
    console.init("TestServer", "Mode serveur de test ACTIF — les actions destructives sont neutralisées")
end
