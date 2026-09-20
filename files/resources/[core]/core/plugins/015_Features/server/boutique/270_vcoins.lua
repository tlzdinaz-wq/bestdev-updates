Feat27 = Feat27 or {}

Boutique = Boutique or {}

Boutique.VehicleExit = { x = -31.52, y = -1104.53, z = 26.42, heading = 158.0 }

local vehicleTrials = {}

local function decode(value, fallback)
    if VFW and VFW.DB and VFW.DB.Decode then
        return VFW.DB.Decode(value, fallback)
    end
    if type(value) == "table" then return value end
    if value == nil or value == "" then return fallback end
    local ok, res = pcall(json.decode, value)
    if ok and res ~= nil then return res end
    return fallback
end

function Boutique.GetVcoins(xPlayer)
    if not xPlayer then return 0 end
    local row = MySQL.single.await("SELECT `vcoins` FROM boutique_vcoins WHERE `identifier` = ?", { xPlayer.identifier })
    if row then return math.floor(tonumber(row.vcoins) or 0) end

    MySQL.insert.await("INSERT IGNORE INTO boutique_vcoins (`identifier`, `vcoins`) VALUES (?, 0)", { xPlayer.identifier })
    return 0
end

function Boutique.SetVcoins(xPlayer, amount)
    if not xPlayer then return 0 end
    local value = math.floor(tonumber(amount) or 0)
    if value < 0 then value = 0 end

    MySQL.query.await(
        "INSERT INTO boutique_vcoins (`identifier`, `vcoins`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `vcoins` = VALUES(`vcoins`)",
        { xPlayer.identifier, value }
    )
    return value
end

function Boutique.AddVcoins(xPlayer, amount)
    return Boutique.SetVcoins(xPlayer, Boutique.GetVcoins(xPlayer) + math.floor(tonumber(amount) or 0))
end

function Boutique.RemoveVcoins(xPlayer, amount)
    return Boutique.SetVcoins(xPlayer, Boutique.GetVcoins(xPlayer) - math.floor(tonumber(amount) or 0))
end

function Boutique.TakeVcoins(xPlayer, amount)
    if not xPlayer then return false, 0 end

    local value = math.floor(tonumber(amount) or 0)
    if value <= 0 then return true, Boutique.GetVcoins(xPlayer) end

    local affected = MySQL.update.await(
        "UPDATE boutique_vcoins SET `vcoins` = `vcoins` - ? WHERE `identifier` = ? AND `vcoins` >= ?",
        { value, xPlayer.identifier, value }
    )

    if (tonumber(affected) or 0) <= 0 then
        return false, Boutique.GetVcoins(xPlayer)
    end

    return true, Boutique.GetVcoins(xPlayer)
end

function Boutique.LogPurchase(identifier, kind, item, price)
    MySQL.insert("INSERT INTO boutique_purchases (`identifier`, `kind`, `item`, `price`) VALUES (?, ?, ?, ?)", {
        identifier, kind, item, price,
    })
end

RegisterServerCallback("boutique:getMyVcoins", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { vcoins = 0, balance = 0 } end

    local balance = Boutique.GetVcoins(xPlayer)
    return { vcoins = balance, balance = balance, coins = balance }
end)

RegisterServerCallback("boutique:pack:get", function(source)
    local rows = MySQL.query.await("SELECT * FROM boutique_packs ORDER BY `id` ASC") or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            packName = row.pack_name,
            label = row.label ~= "" and row.label or row.pack_name,
            price = math.floor(tonumber(row.price) or 0),
            content = decode(row.content, {}),
        }
    end
    return out
end)

RegisterServerCallback("boutique:get:weapons", function(source)
    local rows = MySQL.query.await("SELECT * FROM boutique_weapons ORDER BY `id` ASC") or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            weaponName = row.weapon_name,
            type = row.type or "inde",
            price = math.floor(tonumber(row.price) or 0),
            label = row.label ~= "" and row.label or row.weapon_name,
        }
    end
    return out
end)

RegisterServerCallback("boutique:trybuypack", function(source, packName, colors)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable.", balance = 0 }
    end

    if type(packName) ~= "string" or packName == "" then
        return { success = false, message = "Ce pack n'est pas valide.", balance = Boutique.GetVcoins(xPlayer) }
    end

    if not Feat27.RateLimit(source, "boutique:pack", 1200) then
        return { success = false, message = "Veuillez patienter.", balance = Boutique.GetVcoins(xPlayer) }
    end

    local row = MySQL.single.await("SELECT * FROM boutique_packs WHERE `pack_name` = ?", { packName })
    if not row then
        return { success = false, message = "Pack introuvable.", balance = Boutique.GetVcoins(xPlayer) }
    end

    local price = math.floor(tonumber(row.price) or 0)

    local paid, newBalance = Boutique.TakeVcoins(xPlayer, price)
    if not paid then
        return { success = false, message = "Solde de VCoins insuffisant.", balance = newBalance }
    end

    local content = decode(row.content, {})
    if type(content) ~= "table" then content = {} end

    for _, entry in pairs(content) do
        if type(entry) == "table" and type(entry.item) == "string" then
            Feat27.Inv.Give(xPlayer, entry.item, math.floor(tonumber(entry.count) or 1), nil, false)
        elseif type(entry) == "string" then
            Feat27.Inv.Give(xPlayer, entry, 1, nil, false)
        end
    end

    Boutique.LogPurchase(xPlayer.identifier, "pack", packName, price)

    return { success = true, message = "Pack acheté.", balance = newBalance }
end)

RegisterServerCallback("boutique:trybuyweapon", function(source, weaponName, components, weaponTint)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable.", balance = 0 }
    end

    if type(weaponName) ~= "string" or weaponName == "" then
        return { success = false, message = "Cette arme n'est pas valide.", balance = Boutique.GetVcoins(xPlayer) }
    end

    if not Feat27.RateLimit(source, "boutique:weapon", 1200) then
        return { success = false, message = "Veuillez patienter.", balance = Boutique.GetVcoins(xPlayer) }
    end

    local row = MySQL.single.await("SELECT * FROM boutique_weapons WHERE UPPER(`weapon_name`) = UPPER(?)", { weaponName })
    if not row then
        return { success = false, message = "Arme introuvable.", balance = Boutique.GetVcoins(xPlayer) }
    end

    local price = math.floor(tonumber(row.price) or 0)
    local name = row.weapon_name

    if xPlayer.hasWeapon(name) then
        return { success = false, message = "Vous possédez déjà cette arme.", balance = Boutique.GetVcoins(xPlayer) }
    end

    local paid, newBalance = Boutique.TakeVcoins(xPlayer, price)
    if not paid then
        return { success = false, message = "Solde de VCoins insuffisant.", balance = newBalance }
    end

    xPlayer.addWeapon(name, 0)

    if type(components) == "table" then
        for i = 1, #components do
            local component = components[i]
            local componentName = type(component) == "table" and component.name or component
            if type(componentName) == "string" then
                xPlayer.addWeaponComponent(name, componentName)
            end
        end
    end

    local tint = math.floor(tonumber(weaponTint) or 0)
    if tint > 0 then
        xPlayer.setWeaponTint(name, tint)
    end

    Boutique.LogPurchase(xPlayer.identifier, "weapon", name, price)

    return { success = true, message = "Arme achetée.", balance = newBalance }
end)

RegisterServerCallback("boutique:try:vehicle", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    vehicleTrials[source] = GetGameTimer() + 120000
    return true
end)

RegisterServerCallback("boutique:stop:vehicle", function(source)
    vehicleTrials[source] = nil
    return true
end)

RegisterServerCallback("boutique:buyVehicle", function(source, name, color, kind, vehicleProperties, makeName, perf)
    local exit = Boutique.VehicleExit

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable.", balance = 0, pos = exit, vehicle = 0 }
    end

    local balance = Boutique.GetVcoins(xPlayer)

    if type(name) ~= "string" or name == "" then
        return { success = false, message = "Ce véhicule n'est pas valide.", balance = balance, pos = exit, vehicle = 0 }
    end

    if not Feat27.RateLimit(source, "boutique:vehicle", 2000) then
        return { success = false, message = "Veuillez patienter.", balance = balance, pos = exit, vehicle = 0 }
    end

    local row = MySQL.single.await("SELECT * FROM boutique_packs WHERE `pack_name` = ?", { name })
    local price = row and math.floor(tonumber(row.price) or 0) or 0

    if price <= 0 then
        local item = PaidShop and PaidShop.FindItem and PaidShop.FindItem("vehicules", name) or nil
        price = item and math.floor(tonumber(item.price) or 0) or 0
    end

    if price <= 0 then
        return { success = false, message = "Ce véhicule n'est pas en vente.", balance = balance, pos = exit, vehicle = 0 }
    end

    local paid, newBalance = Boutique.TakeVcoins(xPlayer, price)
    if not paid then
        return { success = false, message = "Solde de VCoins insuffisant.", balance = newBalance, pos = exit, vehicle = 0 }
    end

    local props = type(vehicleProperties) == "table" and vehicleProperties or {}
    if type(color) == "table" then
        props.color1 = props.color1 or color
        props.customPrimaryColor = { tonumber(color.r) or 0, tonumber(color.g) or 0, tonumber(color.b) or 0 }
    end
    props.modEngine = math.floor(tonumber(perf) or 0)

    local plate = Feat27.Vehicles.GeneratePlate()
    local stored = Feat27.Vehicles.Store(xPlayer.identifier, name, props, plate, {
        kind = type(kind) == "string" and kind or "car",
    })

    if not stored then
        local refunded = Boutique.AddVcoins(xPlayer, price)
        return { success = false, message = "Impossible d'enregistrer le véhicule.", balance = refunded, pos = exit, vehicle = 0 }
    end

    local netId = Feat27.SpawnVehicle(name, exit, exit.heading)
    if not netId then
        Boutique.LogPurchase(xPlayer.identifier, "vehicle", name, price)
        return {
            success = true,
            message = "Véhicule acheté, il vous attend au garage.",
            balance = newBalance,
            pos = exit,
            vehicle = 0,
        }
    end

    local entity = Feat27.EntityFromNet(netId)
    if entity then
        SetVehicleNumberPlateText(entity, plate)
        Entity(entity).state:set("VehicleProperties", props, true)
        Entity(entity).state:set("OwnedVehicle", true, true)
    end

    Boutique.LogPurchase(xPlayer.identifier, "vehicle", name, price)

    return {
        success = true,
        message = "Achat réussi.",
        balance = newBalance,
        pos = { x = exit.x, y = exit.y, z = exit.z },
        vehicle = netId,
    }
end)

AddEventHandler("vfw:playerDropped", function(source)
    vehicleTrials[source] = nil
end)

CreateThread(function()
    Wait(4000)
    VFW.RegisterCommand("givevcoins", "givespacecoins", function(source, xPlayer, args)
        local targetId = tonumber(args[1])
        local amount = math.floor(tonumber(args[2]) or 0)

        if not targetId or amount <= 0 then
            Feat27.NotifyError(source, "Usage : /givevcoins [id] [montant]")
            return
        end

        local target = VFW.GetPlayerFromId(targetId)
        if not target then
            Feat27.NotifyError(source, "Joueur introuvable.")
            return
        end

        Boutique.AddVcoins(target, amount)
        Feat27.NotifyOk(source, ("%d VCoins donnés à %s."):format(amount, target.name or target.playerName))
        Feat27.NotifyOk(target.source, ("Vous avez reçu %d VCoins."):format(amount))
    end, {
        help = "Donner des VCoins à un joueur",
        params = {
            { name = "id", help = "ID serveur du joueur" },
            { name = "montant", help = "Nombre de VCoins" },
        },
    })
end)
