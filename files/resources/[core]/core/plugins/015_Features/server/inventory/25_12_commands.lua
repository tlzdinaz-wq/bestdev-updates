local Inv = VFW.Inventory

function Inv.GivePlayerItem(xPlayer, name, count, meta, notify)
    if not xPlayer or type(name) ~= "string" or not Inv.Exists(name) then return 0 end

    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return 0 end

    local added = Inv.AddToList(Inv.PlayerList(xPlayer), name, count, meta, Inv.PlayerMaxSlots)
    if added > 0 then
        Inv.PushPlayer(xPlayer)
        if notify ~= false then
            TriggerClientEvent("vfw:showItemNotification", xPlayer.source, name, added, 1)
        end
    end
    return added
end

function Inv.TakePlayerItem(xPlayer, name, count, notify)
    if not xPlayer or type(name) ~= "string" then return 0 end

    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return 0 end

    local removed = Inv.RemoveByName(Inv.PlayerList(xPlayer), name, count)
    if removed > 0 then
        Inv.PushPlayer(xPlayer)
        if notify ~= false then
            TriggerClientEvent("vfw:showItemNotification", xPlayer.source, name, removed, 0)
        end
    end
    return removed
end

function Inv.HasItem(xPlayer, name, count)
    if not xPlayer then return false end
    return Inv.CountByName(Inv.PlayerList(xPlayer), name) >= (tonumber(count) or 1)
end

local function resolveTarget(source, arg)
    if not arg or arg == "me" or arg == "moi" then
        return VFW.GetPlayerFromId(source)
    end
    local id = tonumber(arg)
    if not id then return nil end
    return VFW.GetPlayerFromId(id)
end

VFW.RegisterCommand("giveitem", "give_item", function(source, xPlayer, args)
    local target = resolveTarget(source, args[1])
    local itemName = args[2]
    local count = math.floor(tonumber(args[3]) or 1)

    if not target then
        if xPlayer then
            xPlayer.showNotification({ type = "ROUGE", content = "Joueur introuvable." })
        end
        return
    end

    if type(itemName) ~= "string" or not Inv.Exists(itemName) then
        if xPlayer then
            xPlayer.showNotification({ type = "ROUGE", content = "Item inconnu." })
        end
        return
    end

    if count <= 0 then count = 1 end
    if count > 1000 then count = 1000 end

    local added = Inv.GivePlayerItem(target, itemName, count, nil, true)

    if xPlayer then
        if added > 0 then
            xPlayer.showNotification({
                type = "VERT",
                content = ("%dx %s donne a %s"):format(added, itemName, target.name),
            })
        else
            xPlayer.showNotification({ type = "ROUGE", content = "Impossible de donner cet item." })
        end
    end
end, {
    help = "Donne un item a un joueur",
    allowConsole = true,
    params = {
        { name = "id", help = "id du joueur (me pour soi)" },
        { name = "item", help = "nom de l'item" },
        { name = "quantite", help = "quantite" },
    },
})

VFW.RegisterCommand("removeitem", "give_item", function(source, xPlayer, args)
    local target = resolveTarget(source, args[1])
    local itemName = args[2]
    local count = math.floor(tonumber(args[3]) or 1)

    if not target or type(itemName) ~= "string" then
        if xPlayer then
            xPlayer.showNotification({ type = "ROUGE", content = "Usage: /removeitem <id> <item> <quantite>" })
        end
        return
    end

    if count <= 0 then count = 1 end

    local removed = Inv.TakePlayerItem(target, itemName, count, true)

    if xPlayer then
        xPlayer.showNotification({
            type = removed > 0 and "VERT" or "ROUGE",
            content = ("%dx %s retire a %s"):format(removed, itemName, target.name),
        })
    end
end, {
    help = "Retire un item a un joueur",
    allowConsole = true,
    params = {
        { name = "id", help = "id du joueur (me pour soi)" },
        { name = "item", help = "nom de l'item" },
        { name = "quantite", help = "quantite" },
    },
})

VFW.RegisterCommand("clearinv", "give_item", function(source, xPlayer, args)
    local target = resolveTarget(source, args[1])
    if not target then
        if xPlayer then
            xPlayer.showNotification({ type = "ROUGE", content = "Joueur introuvable." })
        end
        return
    end

    target.inventory = {}
    Inv.PushPlayer(target)

    if xPlayer then
        xPlayer.showNotification({ type = "VERT", content = ("Inventaire de %s vide."):format(target.name) })
    end
end, {
    help = "Vide l'inventaire d'un joueur",
    params = { { name = "id", help = "id du joueur (me pour soi)" } },
})

VFW.RegisterCommand("testchest", "inventaire", function(source)
    TriggerClientEvent("vfw:openTestChest", source, "test:global")
end, {
    help = "Ouvre le coffre de test",
})

VFW.RegisterCommand("refreshinv", nil, function(source, xPlayer)
    if not xPlayer then return end
    Inv.LoadPlayer(xPlayer)
end, {
    help = "Recharge votre inventaire",
})
