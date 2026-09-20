Feat27 = Feat27 or {}

local POLICE_JOBS = { "police", "lspd", "bcso", "sasp", "sheriff", "fib", "usss" }

local function policeTargets()
    local targets = {}
    if not VFW or not VFW.GetPlayers then return targets end

    local players = VFW.GetPlayersWithJobs(POLICE_JOBS)
    for i = 1, #players do
        targets[#targets + 1] = players[i].source
    end
    return targets
end

function Feat27.CreatePoliceBlip(blipData, targetsOverride)
    if type(blipData) ~= "table" then return false end

    local position = Feat27.Plain(blipData.position or blipData.coords)
    if not position then return false end

    local payload = {
        position = position,
        sprite = tonumber(blipData.sprite) or 161,
        color = tonumber(blipData.color) or 1,
        scale = tonumber(blipData.scale) or 0.5,
        label = tostring(blipData.label or "Zone d'intérêt"),
        duration = tonumber(blipData.duration) or 5,
    }

    local targets = targetsOverride or policeTargets()
    if targets == -1 then
        TriggerClientEvent("core:legal:createPoliceBlip", -1, payload)
        return true
    end

    for i = 1, #targets do
        TriggerClientEvent("core:legal:createPoliceBlip", targets[i], payload)
    end
    return true
end

function Feat27.RemoveAllPoliceBlips(target)
    TriggerClientEvent("core:legal:removeAllBlips", target or -1)
    return true
end

AddEventHandler("core:legal:server:policeAlert", function(blipData, targets)
    Feat27.CreatePoliceBlip(blipData, targets)
end)

AddEventHandler("core:legal:server:clearPoliceBlips", function(target)
    Feat27.RemoveAllPoliceBlips(target)
end)

exports("createPoliceBlip", function(blipData, targets)
    return Feat27.CreatePoliceBlip(blipData, targets)
end)

exports("removeAllPoliceBlips", function(target)
    return Feat27.RemoveAllPoliceBlips(target)
end)

CreateThread(function()
    Wait(2000)
    VFW.RegisterCommand("policeblip", "gestion", function(source, xPlayer, args)
        local coords = xPlayer.getCoords(false)
        Feat27.CreatePoliceBlip({
            position = coords,
            label = args[1] and table.concat(args, " ") or "Alerte",
            duration = 5,
        })
        Feat27.NotifyOk(source, "Alerte diffusée aux forces de l'ordre.")
    end, {
        help = "Poser un blip d'alerte police à votre position",
        params = { { name = "label", help = "Libellé du blip" } },
    })

    VFW.RegisterCommand("clearpoliceblips", "gestion", function(source)
        Feat27.RemoveAllPoliceBlips()
        Feat27.NotifyOk(source, "Blips d'alerte supprimés.")
    end, { help = "Supprimer tous les blips d'alerte police" })
end)
