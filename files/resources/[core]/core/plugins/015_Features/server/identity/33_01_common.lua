VFW.Cloths = VFW.Cloths or {}

local Cl = VFW.Cloths

Cl.FreeSkin = {}
Cl.Rate = {}

local CLOTHING_ITEM_NAMES = {
    top = true,
    bottom = true,
    shoe = true,
    hat = true,
    accessory = true,
    outfit = true,
    clothes_bag = true,
    arms = true,
}

Cl.Categories = {
    { key = "top",           label = "Haut",                price = 250 },
    { key = "bottom",        label = "Pantalon",            price = 200 },
    { key = "shoe",          label = "Chaussures",          price = 150 },
    { key = "hat",           label = "Chapeau",             price = 120 },
    { key = "accessory",     label = "Accessoire",          price = 150 },
    { key = "mask",          label = "Masque",              price = 100 },
    { key = "beard",         label = "Barbe",               price = 40 },
    { key = "hair",          label = "Coupe de cheveux",    price = 60 },
    { key = "tattoo",        label = "Tatouage",            price = 150 },
    { key = "sheNails",      label = "Ongles SheNails",     price = 80 },
    { key = "piercing",      label = "Piercing",            price = 80 },
    { key = "nails",         label = "Ongles",              price = 80 },
    { key = "PilositeTorse", label = "Pilosite du torse",   price = 50 },
    { key = "Blush",         label = "Blush",               price = 30 },
    { key = "RougeLevre",    label = "Rouge a levres",      price = 30 },
    { key = "Maquillage",    label = "Maquillage",          price = 30 },
    { key = "decals",        label = "Decalcomanie",        price = 80 },
    { key = "bag",           label = "Sac",                 price = 300 },
    { key = "glasses",       label = "Lunettes",            price = 120 },
    { key = "watch",         label = "Montre",              price = 500 },
    { key = "necklace",      label = "Collier",             price = 500 },
    { key = "earring",       label = "Boucle d'oreille",    price = 300 },
    { key = "bracelet",      label = "Bracelet",            price = 300 },
    { key = "kevlar",        label = "Gilet pare-balles",   price = 400 },
}

Cl.Genders = { "Homme", "Femme" }

local ALIAS = {
    torso = "top",
    torso2 = "top",
    undershirt = "top",
    shirt = "top",
    arms = "top",
    leg = "bottom",
    pants = "bottom",
    shoes = "shoe",
    helmet = "hat",
    armor = "kevlar",
    body_armor = "kevlar",
    gpb = "kevlar",
    decal = "decals",
    ear = "earring",
    ears = "earring",
    chain = "necklace",
    ring = "necklace",
    outfit = "top",
}

function Cl.ResolvePriceName(category)
    if type(category) ~= "string" then return nil end
    return ALIAS[category] or category
end

function Cl.NormalizeGender(value)
    if value == "Femme" or value == "w" or value == "f" or value == "F" or value == 1 or value == "1" then
        return "Femme"
    end
    return "Homme"
end

function Cl.GenderOf(xPlayer)
    if not xPlayer then return "Homme" end
    local skin = xPlayer.skin
    if type(skin) == "table" and skin.sex ~= nil then
        return (tonumber(skin.sex) == 1) and "Femme" or "Homme"
    end
    return Cl.NormalizeGender(xPlayer.sex)
end

function Cl.ShortSex(gender)
    return gender == "Femme" and "w" or "m"
end

function Cl.RateLimit(source, key, delay)
    local now = GetGameTimer()
    local bucket = Cl.Rate[source]
    if not bucket then
        bucket = {}
        Cl.Rate[source] = bucket
    end
    if bucket[key] and now < bucket[key] then
        return false
    end
    bucket[key] = now + (delay or 1000)
    return true
end

function Cl.Notify(source, message, kind)
    VFW.ShowNotification(source, { type = kind or "ROUGE", content = tostring(message) })
end

function Cl.Int(value, fallback)
    local n = tonumber(value)
    if not n then return fallback end
    n = math.floor(n)
    if n ~= n then return fallback end
    return n
end

function Cl.Str(value, maxLength)
    if type(value) ~= "string" then return nil end
    if value == "" then return nil end
    return value:sub(1, maxLength or 64)
end

function Cl.IsFreeSession(source)
    return Cl.FreeSkin[source] == true
end

function Cl.Balance(xPlayer, method)
    local name = (method == "bank") and "bank" or "money"
    local account = xPlayer.getAccount(name)
    return account and (tonumber(account.money) or 0) or 0
end

function Cl.Charge(xPlayer, method, amount, reason)
    amount = Cl.Int(amount, 0)
    if amount <= 0 then return true end
    if Cl.IsFreeSession(xPlayer.source) then return true end

    local name = (method == "bank") and "bank" or "money"
    local account = xPlayer.getAccount(name)
    if not account or (tonumber(account.money) or 0) < amount then
        return false
    end

    xPlayer.removeAccountMoney(name, amount, reason or "clothes")
    return true
end

function Cl.Inv()
    return VFW.Inventory
end

function Cl.MaxSlotsForItem(name)
    local Inv = VFW.Inventory
    if not Inv then return nil end

    local maxSlots = tonumber(Inv.PlayerMaxSlots) or 100
    local def = Inv.Def and Inv.Def(name) or nil
    local itemType = def and def.type or nil

    if itemType == "clothes" or itemType == "outfit" or CLOTHING_ITEM_NAMES[name] then
        return maxSlots + 400
    end

    return maxSlots
end

function Cl.GiveItem(xPlayer, name, count, meta)
    count = Cl.Int(count, 1)
    if count <= 0 then return false end

    local Inv = VFW.Inventory
    if Inv and Inv.PlayerList then
        if not Inv.Exists(name) then return false end
        local list = Inv.PlayerList(xPlayer)
        local added = Inv.AddToList(list, name, count, meta, Cl.MaxSlotsForItem(name))
        if added <= 0 then return false end
        Inv.PushPlayer(xPlayer)
        return true
    end

    return xPlayer.addInventoryItem(name, count, meta) and true or false
end

function Cl.CountItem(xPlayer, name)
    local Inv = VFW.Inventory
    if Inv and Inv.PlayerList then
        return Inv.CountByName(Inv.PlayerList(xPlayer), name)
    end
    local item = xPlayer.getInventoryItem(name)
    return item and item.count or 0
end

function Cl.FindItemByMeta(xPlayer, name, key, value)
    local Inv = VFW.Inventory
    if not Inv or not Inv.PlayerList then return nil end
    local list = Inv.PlayerList(xPlayer)
    for i = 1, #list do
        local entry = list[i]
        if entry.name == name and entry.meta and entry.meta[key] == value then
            return entry, list
        end
    end
    return nil, list
end

function Cl.RemoveItem(xPlayer, name, count)
    count = Cl.Int(count, 1)
    local Inv = VFW.Inventory
    if Inv and Inv.PlayerList then
        local list = Inv.PlayerList(xPlayer)
        local removed = Inv.RemoveByName(list, name, count)
        if removed <= 0 then return false end
        Inv.PushPlayer(xPlayer)
        return true
    end
    return xPlayer.removeInventoryItem(name, count) and true or false
end

function Cl.RemoveItemSlot(xPlayer, slot, count)
    local Inv = VFW.Inventory
    if not Inv or not Inv.PlayerList then return false end
    local list = Inv.PlayerList(xPlayer)
    local taken = Inv.RemoveFromSlot(list, slot, Cl.Int(count, 1))
    if not taken then return false end
    Inv.PushPlayer(xPlayer)
    return true
end

function Cl.SaveSkin(xPlayer, skin)
    if type(skin) ~= "table" then return false end

    local clean = {}
    local count = 0
    for key, value in pairs(skin) do
        if type(key) == "string" and #key <= 40 then
            local kind = type(value)
            if kind == "number" or kind == "string" or kind == "boolean" then
                count = count + 1
                if count > 200 then break end
                clean[key] = value
            end
        end
    end

    if next(clean) == nil then return false end

    xPlayer.skin = clean
    MySQL.update("UPDATE characters SET skin = ? WHERE identifier = ?", {
        VFW.DB.Encode(clean), xPlayer.identifier,
    })
    return true
end

function Cl.MergeSkin(xPlayer, patch)
    if type(patch) ~= "table" then return false end
    local skin = type(xPlayer.skin) == "table" and xPlayer.skin or {}
    for key, value in pairs(patch) do
        if type(key) == "string" and (type(value) == "number" or type(value) == "string") then
            skin[key] = value
        end
    end
    return Cl.SaveSkin(xPlayer, skin)
end

function Cl.Uuid()
    if VFW.GenerateUUID then
        return VFW.GenerateUUID()
    end
    return ("%d%d"):format(os.time(), math.random(100000, 999999))
end

function Cl.Coords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function Cl.Distance(a, b)
    if not a or not b then return 9999.0 end
    local dx = (a.x or 0.0) - (b.x or 0.0)
    local dy = (a.y or 0.0) - (b.y or 0.0)
    local dz = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Cl.WaitInventory(callback)
    CreateThread(function()
        local tries = 0
        while (not VFW.Inventory or not VFW.Inventory.RegisterUsableItem) and tries < 200 do
            Wait(250)
            tries = tries + 1
        end
        if VFW.Inventory and VFW.Inventory.RegisterUsableItem then
            callback(VFW.Inventory)
        else
            console.warn("[cloths] module inventaire introuvable, items non enregistres")
        end
    end)
end

AddEventHandler("playerDropped", function()
    local source = source
    Cl.FreeSkin[source] = nil
    Cl.Rate[source] = nil
end)
