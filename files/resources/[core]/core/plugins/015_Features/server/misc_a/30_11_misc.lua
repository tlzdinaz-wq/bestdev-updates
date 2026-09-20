VFW.Fire = VFW.Fire or {}
VFW.Airsoft = VFW.Airsoft or {}
VFW.Earthquake = VFW.Earthquake or {}

local activeFires = {}
local fireCounter = 0

function VFW.Fire.Start(data)
    if type(data) ~= "table" then return nil end

    local position = Misc30.Plain(data.position or data.coords)
    if not position then return nil end

    fireCounter = fireCounter + 1
    local fireId = ("fire_%d_%d"):format(os.time(), fireCounter)

    local payload = {
        position = position,
        flames = Misc30.ToInt(data.flames, 1, 60) or 15,
        spread = Misc30.ToInt(data.spread, 1, 60) or 15,
        info = type(data.info) == "table" and data.info or nil,
    }

    activeFires[fireId] = payload
    TriggerClientEvent("fire:sync", -1, fireId, payload)

    return fireId
end

function VFW.Fire.Stop(fireId)
    if not activeFires[fireId] then return false end
    activeFires[fireId] = nil
    TriggerClientEvent("fire:remove", -1, fireId)
    return true
end

function VFW.Fire.StopAll()
    activeFires = {}
    TriggerClientEvent("fire:removeAll", -1)
    return true
end

function VFW.Fire.GetAll()
    return activeFires
end

VFW.RegisterCommand("fire", "clean_zone", function(source, xPlayer, args)
    if not xPlayer then return end

    local action = args[1]
    if action == "stop" or action == "clear" then
        VFW.Fire.StopAll()
        Misc30.Notify(source, "VERT", "Incendies eteints.")
        return
    end

    local coords = xPlayer.getCoords(false)
    local fireId = VFW.Fire.Start({
        position = coords,
        flames = Misc30.ToInt(args[1], 1, 60) or 15,
        spread = Misc30.ToInt(args[2], 1, 60) or 15,
    })

    if fireId then
        Misc30.Notify(source, "VERT", ("Incendie cree (%s)."):format(fireId))
    end
end, {
    help = "Creer ou eteindre un incendie",
    params = {
        { name = "flammes", help = "Nombre de flammes, ou 'stop'" },
        { name = "rayon", help = "Rayon de propagation" },
    },
})

local earthquakeTimer = nil

function VFW.Earthquake.Start(options)
    options = type(options) == "table" and options or {}

    local payload = {
        force = Misc30.ToFloat(options.force, 0.1, 10.0) or 1.0,
        frequency = Misc30.ToFloat(options.frequency, 0.1, 100.0) or 10.0,
        direction = options.direction,
        seed = Misc30.ToInt(options.seed, 0) or math.random(1, 999999),
        duration = Misc30.ToInt(options.duration, 1000, 900000) or 30000,
        weather = Misc30.Clean(options.weather, 24, "THUNDER"),
        startTime = GetGameTimer(),
    }

    GlobalState.earthquake = payload

    TriggerClientEvent("vfw:earthquake:start", -1, payload.force, payload.frequency,
        payload.direction, payload.seed, payload.duration, payload.weather)

    if earthquakeTimer then earthquakeTimer = nil end
    local token = payload.seed
    earthquakeTimer = token

    SetTimeout(payload.duration, function()
        if earthquakeTimer ~= token then return end
        VFW.Earthquake.Stop()
    end)

    return payload
end

function VFW.Earthquake.Stop()
    earthquakeTimer = nil
    GlobalState.earthquake = nil
    TriggerClientEvent("vfw:earthquake:stop", -1)
    return true
end

VFW.RegisterCommand("earthquake", "gestion", function(source, xPlayer, args)
    if args[1] == "stop" then
        VFW.Earthquake.Stop()
        Misc30.Notify(source, "VERT", "Seisme arrete.")
        return
    end

    VFW.Earthquake.Start({
        force = Misc30.ToFloat(args[1], 0.1, 10.0) or 1.0,
        duration = (Misc30.ToInt(args[2], 1, 900) or 30) * 1000,
    })

    Misc30.Notify(source, "VERT", "Seisme declenche.")
end, {
    help = "Declencher un seisme",
    params = {
        { name = "force", help = "Force du seisme (0.1 a 10), ou 'stop'" },
        { name = "duree", help = "Duree en secondes" },
    },
    allowConsole = true,
})

RegisterNetEvent("hookah_smokes", function(pedNetId, x, y, z)
    local source = source

    local netId = Misc30.ToInt(pedNetId, 1)
    if not netId then return end

    local px = Misc30.ToFloat(x)
    local py = Misc30.ToFloat(y)
    local pz = Misc30.ToFloat(z)
    if not px or not py or not pz then return end

    if not VFW.GetPlayerFromId(source) then return end
    if not Misc30.RateLimit(source, "hookah", 1500) then return end

    local playerCoords = Misc30.PlayerCoords(source)
    if playerCoords and #(playerCoords - vector3(px, py, pz)) > 10.0 then return end

    local targets = Misc30.PlayersInRadius(vector3(px, py, pz), 40.0)
    for i = 1, #targets do
        TriggerClientEvent("c_hookah_smokes", targets[i], netId, px, py, pz)
    end
end)

RegisterNetEvent("core:sendtext", function(text)
    local source = source

    local message = Misc30.Clean(text, 256)
    if not message then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "sendtext", 2000) then return end

    local coords = Misc30.PlayerCoords(source)
    if not coords then return end

    local targets = Misc30.PlayersInRadius(coords, 25.0)
    for i = 1, #targets do
        TriggerClientEvent("3dme:shareDisplay", targets[i], message, source)
    end
end)

local airsoftHits = {}
local AIRSOFT_STUN_THRESHOLD = 6
local AIRSOFT_HIT_WINDOW = 12000

local function isAirsoftWeapon(weaponHash)
    if not VFW.GetWeaponFromHash then return false end
    local ok, weapon = pcall(VFW.GetWeaponFromHash, weaponHash)
    if not ok or type(weapon) ~= "table" or type(weapon.name) ~= "string" then return false end
    return weapon.name:upper():find("AIRSOFT", 1, true) ~= nil
end

function VFW.Airsoft.Hit(target)
    local src = tonumber(target)
    if not src or not VFW.GetPlayerFromId(src) then return false end

    local entry = airsoftHits[src]
    local now = GetGameTimer()

    if not entry or (now - entry.last) > AIRSOFT_HIT_WINDOW then
        entry = { count = 0, last = now }
        airsoftHits[src] = entry
    end

    entry.count = entry.count + 1
    entry.last = now

    if entry.count >= AIRSOFT_STUN_THRESHOLD then
        airsoftHits[src] = nil
        TriggerClientEvent("airsoft:stun", src)
        return true
    end

    TriggerClientEvent("airsoft:hit", src)
    return true
end

function VFW.Airsoft.Stun(target)
    local src = tonumber(target)
    if not src or not VFW.GetPlayerFromId(src) then return false end
    airsoftHits[src] = nil
    TriggerClientEvent("airsoft:stun", src)
    return true
end

AddEventHandler("weaponDamageEvent", function(sender, data)
    local shooter = tonumber(sender)
    if not shooter or type(data) ~= "table" then return end
    if not VFW.GetPlayerFromId(shooter) then return end
    if not isAirsoftWeapon(data.weaponType) then return end

    local targets = data.hitGlobalIds
    if type(targets) ~= "table" then return end

    for i = 1, #targets do
        local netId = tonumber(targets[i])
        if netId and netId ~= 0 then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                local victim = NetworkGetEntityOwner(entity)
                if victim and victim > 0 and VFW.GetPlayerFromId(victim) then
                    VFW.Airsoft.Hit(victim)
                end
            end
        end
    end
end)

VFW.RegisterCommand("f5", nil, function(source, xPlayer)
    if not xPlayer then return end
    xPlayer.triggerEvent("vfw:openPersonalMenu")
end, { help = "Ouvrir le menu personnel" })

VFW.RegisterCommand("cinema", nil, function(source, xPlayer)
    if not xPlayer then return end
    xPlayer.triggerEvent("vfw:toggleCinemaMode")
end, { help = "Activer ou desactiver le mode cinema" })

VFW.RegisterCommand("reloadhud", nil, function(source, xPlayer)
    if not xPlayer then return end
    xPlayer.triggerEvent("LoadHud")
end, { help = "Recharger le HUD" })

CreateThread(function()
    Wait(4000)

    local binocularItem = Misc30.FirstExistingItem({ "jumelle", "jumelles", "binoculars" })
    if binocularItem then
        Misc30.UsableItem(binocularItem, function(xPlayer)
            if not xPlayer then return end
            TriggerClientEvent("core:useBinocular", xPlayer.source)
        end)
    end

    local chichaItem = Misc30.FirstExistingItem({ "chicha", "shisha", "narguile", "hookah" })
    if chichaItem then
        Misc30.UsableItem(chichaItem, function(xPlayer)
            if not xPlayer then return end
            TriggerClientEvent("core:usechciha", xPlayer.source)
        end)
    end
end)

AddEventHandler("vfw:playerLoaded", function(source)
    SetTimeout(5000, function()
        if not VFW.GetPlayerFromId(source) then return end

        TriggerClientEvent("LoadHud", source)

        for fireId, payload in pairs(activeFires) do
            TriggerClientEvent("fire:sync", source, fireId, payload)
        end

        local quake = GlobalState.earthquake
        if type(quake) == "table" and quake.duration then
            local elapsed = GetGameTimer() - (quake.startTime or 0)
            local remaining = quake.duration - elapsed
            if remaining > 1000 then
                TriggerClientEvent("vfw:earthquake:start", source, quake.force, quake.frequency,
                    quake.direction, quake.seed, remaining, quake.weather)
            end
        end
    end)
end)

AddEventHandler("vfw:playerDropped", function(source)
    airsoftHits[source] = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    activeFires = {}
end)
