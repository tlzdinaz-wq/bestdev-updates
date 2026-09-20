local function resolveTarget(source, arg)
    local id = tonumber(arg)
    if not id then return VFW.GetPlayerFromId(source) end
    return VFW.GetPlayerFromId(id)
end

local function deny(xPlayer, message)
    if not xPlayer then
        print("^1[staff]^7 " .. tostring(message))
        return
    end
    xPlayer.showNotification({
        type = "STAFF",
        variant = "ERROR",
        subtitle = "Staff",
        message = message,
    })
end

local function canRevive(xPlayer)
    return xPlayer and (xPlayer.hasPermission("revive") or xPlayer.hasPermission("menu_anim") or xPlayer.hasPermission("staff_menu"))
end

local function canHeal(xPlayer)
    return xPlayer and (xPlayer.hasPermission("heal") or xPlayer.hasPermission("menu_anim") or xPlayer.hasPermission("staff_menu"))
end

local function doRevive(source, xPlayer, targetArg)
    if source ~= 0 and not canRevive(xPlayer) then
        deny(xPlayer, "Vous n'avez pas la permission de revive.")
        return false
    end

    local target = resolveTarget(source, targetArg)
    if not target then
        deny(xPlayer, "Joueur introuvable.")
        return false
    end

    target.revive()
    TriggerEvent("vfw:logs:staff", source, "revive", { target = target.source, name = target.name })

    if xPlayer then
        xPlayer.showNotification({
            type = "STAFF",
            variant = "SUCCESS",
            subtitle = "Gestion Joueur",
            message = source == target.source
                and "Vous avez été réanimé."
                or ("%s a été réanimé."):format(target.name or ("#" .. target.source)),
        })
    else
        print(("[revive] %s (#%s) réanimé."):format(target.name or "?", target.source))
    end
    return true
end

local function doHeal(source, xPlayer, targetArg)
    if source ~= 0 and not canHeal(xPlayer) then
        deny(xPlayer, "Vous n'avez pas la permission de heal.")
        return false
    end

    local target = resolveTarget(source, targetArg)
    if not target then
        deny(xPlayer, "Joueur introuvable.")
        return false
    end

    target.setMeta("health", 200)
    TriggerClientEvent("vfw:healPlayer", target.source)
    TriggerEvent("vfw:logs:staff", source, "heal", { target = target.source, name = target.name })

    if xPlayer then
        xPlayer.showNotification({
            type = "STAFF",
            variant = "SUCCESS",
            subtitle = "Gestion Joueur",
            message = source == target.source
                and "Santé restaurée."
                or ("%s a été soigné."):format(target.name or ("#" .. target.source)),
        })
    else
        print(("[heal] %s (#%s) soigné."):format(target.name or "?", target.source))
    end
    return true
end

VFW.RegisterCommand("revive", "", function(source, xPlayer, args)
    doRevive(source, xPlayer, args and args[1])
end, {
    help = "Réanimer un joueur mort ou KO",
    params = { { name = "id", help = "ID du joueur (vide = soi-même)" } },
    allowConsole = true,
})

RegisterNetEvent("vfw:staff:revivePlayer", function(targetId)
    local src = source
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return end
    doRevive(src, xPlayer, targetId)
end)

VFW.RegisterCommand("heal", "", function(source, xPlayer, args)
    doHeal(source, xPlayer, args and args[1])
end, {
    help = "Soigner un joueur sans le ranimer",
    params = { { name = "id", help = "ID du joueur (vide = soi-même)" } },
    allowConsole = true,
})

RegisterNetEvent("vfw:staff:healPlayer", function(targetId)
    local src = source
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return end
    doHeal(src, xPlayer, targetId)
end)

VFW.RegisterCommand("tpm", "tp", function(source, xPlayer)
    if not xPlayer then return end
    TriggerClientEvent("vfw:tpm", source)
end, { help = "Se teleporter au marqueur GPS" })

VFW.RegisterCommand("kill", "kill", function(source, xPlayer, args)
    local target = resolveTarget(source, args and args[1])
    if not target then
        deny(xPlayer, "Joueur introuvable.")
        return
    end

    TriggerClientEvent("vfw:killPlayer", target.source, source)
    TriggerEvent("vfw:logs:staff", source, "kill", { target = target.source, name = target.name })

    if xPlayer then
        xPlayer.showNotification({
            type = "STAFF",
            variant = "SUCCESS",
            subtitle = "Gestion Joueur",
            message = ("%s a ete tue."):format(target.name or ("#" .. target.source)),
        })
    end
end, {
    help = "Tuer un joueur",
    params = { { name = "id", help = "ID du joueur (vide = soi-meme)" } },
})

VFW.RegisterCommand("ko", "ko", function(source, xPlayer, args)
    local target = resolveTarget(source, args and args[1])
    if not target then
        deny(xPlayer, "Joueur introuvable.")
        return
    end

    local duration = tonumber(args and args[2]) or 30000
    if duration < 1000 then duration = 1000 end
    if duration > 300000 then duration = 300000 end

    TriggerClientEvent("vfw:startko", target.source, duration)
    TriggerEvent("vfw:logs:staff", source, "ko", { target = target.source, duration = duration })
end, {
    help = "Mettre un joueur KO",
    params = {
        { name = "id", help = "ID du joueur (vide = soi-meme)" },
        { name = "duree", help = "Duree en ms (defaut 30000)" },
    },
})

VFW.RegisterCommand("repair", "repair", function(source, xPlayer, args)
    local target = resolveTarget(source, args and args[1])
    if not target then
        deny(xPlayer, "Joueur introuvable.")
        return
    end

    TriggerClientEvent("vfw:repairPedVehicle", target.source)
    TriggerEvent("vfw:logs:staff", source, "repair", { target = target.source })
end, {
    help = "Reparer le vehicule d'un joueur",
    params = { { name = "id", help = "ID du joueur (vide = soi-meme)" } },
})

VFW.RegisterCommand("upgrade", "upgrade", function(source, xPlayer, args)
    local target = resolveTarget(source, args and args[1])
    if not target then
        deny(xPlayer, "Joueur introuvable.")
        return
    end

    TriggerClientEvent("vfw:upgrade", target.source)
    TriggerEvent("vfw:logs:staff", source, "upgrade", { target = target.source })
end, {
    help = "Ameliorer le vehicule d'un joueur",
    params = { { name = "id", help = "ID du joueur (vide = soi-meme)" } },
})

VFW.RegisterCommand("setcarcolor", "setcarcolor", function(source, xPlayer, args)
    if not xPlayer then return end

    local color = args and args[1]
    if color == nil or color == "" then
        deny(xPlayer, "Utilisation : /setcarcolor [couleur]")
        return
    end

    TriggerClientEvent("vfw:setcarcolor", source, color)
    TriggerEvent("vfw:logs:staff", source, "setcarcolor", { color = color })
end, {
    help = "Changer la couleur du vehicule",
    params = { { name = "couleur", help = "Index de couleur GTA" } },
})

function VFW.LoadLightbarInCar(source, netId, plate)
    source = tonumber(source)
    netId = tonumber(netId)
    if not source or not netId or type(plate) ~= "string" then return false end
    TriggerClientEvent("vfw:loadLightbarInCar", source, netId, plate)
    return true
end

function VFW.RequestModel(source, model)
    if not tonumber(source) then return false end
    if type(model) ~= "string" and type(model) ~= "number" then return false end
    TriggerClientEvent("vfw:requestModel", source, model)
    return true
end

function VFW.KillPlayer(target, staffSource)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return false end
    TriggerClientEvent("vfw:killPlayer", xTarget.source, staffSource)
    return true
end

function VFW.StartKO(target, duration)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return false end
    TriggerClientEvent("vfw:startko", xTarget.source, tonumber(duration) or 30000)
    return true
end
