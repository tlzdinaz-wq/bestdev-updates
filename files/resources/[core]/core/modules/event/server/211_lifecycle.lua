local announced = {}
local FALLBACK_DELAY = 20000

local function announcePlayerLoaded(src)
    src = tonumber(src)
    if not src or src <= 0 then return false end
    if announced[src] then return false end
    if not GetPlayerName(src) then return false end

    announced[src] = true
    TriggerEvent("core:playerloaded", src)

    return true
end

function VFW.AnnouncePlayerLoaded(source)
    return announcePlayerLoaded(source)
end

function VFW.IsPlayerAnnounced(source)
    source = tonumber(source)
    if not source then return false end
    return announced[source] == true
end

AddEventHandler("vfw:playerLoaded", function(source)
    announcePlayerLoaded(source)
end)

AddEventHandler("vfw:characterLoaded", function(source)
    local src = tonumber(source)
    if not src then return end

    SetTimeout(FALLBACK_DELAY, function()
        if announced[src] then return end
        if not VFW.GetPlayerFromId(src) then return end
        if announcePlayerLoaded(src) then
            console.warn(("[Lifecycle] 'core:playerloaded' émis en secours pour %d (vfw:onPlayerLoaded jamais reçu)"):format(src))
        end
    end)
end)

AddEventHandler("vfw:playerDropped", function(source)
    local src = tonumber(source)
    if src then announced[src] = nil end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    announced = {}
end)

console.init("Lifecycle", "relais 'core:playerloaded' actif")
