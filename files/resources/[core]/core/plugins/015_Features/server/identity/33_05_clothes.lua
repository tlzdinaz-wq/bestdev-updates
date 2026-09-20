local Cl = VFW.Cloths

local ITEM_NAMES = {
    top = true,
    bottom = true,
    shoe = true,
    hat = true,
    accessory = true,
}

local ACCESSORY_TYPES = {
    mask = "mask",
    glasses = "glasses",
    bag = "bag",
    watch = "watch",
    necklace = "necklace",
    earring = "earring",
    bracelet = "bracelet",
    kevlar = "kevlar",
    nails = "nails",
    piercing = "piercing",
    ring = "necklace",
}

local BAN_KEYS = {
    top = "BanTop",
    undershirt = "BanSous",
    shirt = "BanSous",
    arms = "BanArm",
    bottom = "BanLeg",
    shoe = "BanShoes",
    hat = "BanHat",
    mask = "BanMasque",
    glasses = "BanGlases",
    bag = "BanBag",
    necklace = "BanCou",
    kevlar = "BanKevlar",
    watch = "BanWatch",
    earring = "BanEarring",
    bracelet = "BanBracelet",
}

local OUTFIT_BAN_SLOTS = {
    { key = "torso_1", ban = "BanTop" },
    { key = "tshirt_1", ban = "BanSous" },
    { key = "arms", ban = "BanArm" },
    { key = "pants_1", ban = "BanLeg" },
    { key = "shoes_1", ban = "BanShoes" },
    { key = "helmet_1", ban = "BanHat" },
    { key = "mask_1", ban = "BanMasque" },
    { key = "glasses_1", ban = "BanGlases" },
    { key = "bags_1", ban = "BanBag" },
    { key = "chain_1", ban = "BanCou" },
    { key = "bproof_1", ban = "BanKevlar" },
    { key = "watches_1", ban = "BanWatch" },
    { key = "ears_1", ban = "BanEarring" },
    { key = "bracelets_1", ban = "BanBracelet" },
}

local VANGELICO_KEYS = {
    watch = "BanMontre",
    necklace = "BanColier",
    bracelet = "BanBracelet",
    earring = "BanBouclesOreilles",
    ring = "BanBague",
}

local SKIN_SLOTS = {
    bottom = { "pants_1", "pants_2" },
    shoe = { "shoes_1", "shoes_2" },
    hat = { "helmet_1", "helmet_2" },
    glasses = { "glasses_1", "glasses_2" },
    bag = { "bags_1", "bags_2" },
    necklace = { "chain_1", "chain_2" },
    watch = { "watches_1", "watches_2" },
    mask = { "mask_1", "mask_2" },
    bracelet = { "bracelets_1", "bracelets_2" },
    earring = { "ears_1", "ears_2" },
    piercing = { "decals_1", "decals_2" },
    nails = { "decals_1", "decals_2" },
    decals = { "decals_1", "decals_2" },
    kevlar = { "bproof_1", "bproof_2" },
    top = { "torso_1", "torso_2" },
    shirt = { "tshirt_1", "tshirt_2" },
    undershirt = { "tshirt_1", "tshirt_2" },
    arms = { "arms", "arms_2" },
}

local OUTFIT_SKIN_KEYS = {
    "tshirt_1", "tshirt_2", "torso_1", "torso_2", "arms", "arms_2",
    "pants_1", "pants_2", "shoes_1", "shoes_2", "helmet_1", "helmet_2",
    "glasses_1", "glasses_2", "bags_1", "bags_2", "chain_1", "chain_2",
    "decals_1", "decals_2", "bracelets_1", "bracelets_2", "watches_1", "watches_2",
    "ears_1", "ears_2", "mask_1", "mask_2", "bproof_1", "bproof_2",
}

local function resolveCategory(itemName, metadata)
    if itemName == "accessory" then
        local kind = type(metadata) == "table" and metadata.type or nil
        return ACCESSORY_TYPES[kind] or "accessory"
    end
    if itemName == "top" then
        return "top"
    end
    return itemName
end

function Cl.SanitizeMetadata(metadata)
    if type(metadata) ~= "table" then return nil end

    local out = {}
    local count = 0
    for key, value in pairs(metadata) do
        if type(key) == "string" and #key <= 40 then
            local kind = type(value)
            count = count + 1
            if count > 48 then break end
            if kind == "number" or kind == "boolean" then
                out[key] = value
            elseif kind == "string" then
                out[key] = value:sub(1, 96)
            elseif kind == "table" and key == "skin" then
                local skin = {}
                for skinKey, skinValue in pairs(value) do
                    if type(skinKey) == "string" and #skinKey <= 40 and type(skinValue) == "number" then
                        skin[skinKey] = math.floor(skinValue)
                    end
                end
                if next(skin) ~= nil then out.skin = skin end
            end
        end
    end

    if next(out) == nil then return nil end
    return out
end

local function bannedDrawable(gender, itemName, metadata)
    local kind = metadata.type
    local key

    if itemName == "accessory" then
        key = BAN_KEYS[kind]
    elseif itemName == "top" then
        key = (kind == "undershirt") and BAN_KEYS.undershirt or BAN_KEYS.top
    else
        key = BAN_KEYS[itemName]
    end

    if not key then return false end

    local drawable
    if type(metadata.skin) == "table" then
        if key == "BanTop" then
            drawable = metadata.skin.torso_1
        elseif key == "BanSous" then
            drawable = metadata.skin.tshirt_1
        end
    end
    if drawable == nil then
        drawable = metadata.id
    end
    if drawable == nil then return false end

    return Cl.IsBanned(gender, key, drawable)
end

function Cl.ApplySkinFromMetadata(xPlayer, itemName, metadata)
    if type(metadata.skin) == "table" then
        Cl.MergeSkin(xPlayer, metadata.skin)
        return
    end

    local kind = metadata.clothesSlotType or metadata.type or itemName
    local slots = SKIN_SLOTS[kind] or SKIN_SLOTS[itemName]
    if not slots then return end

    local patch = {}
    patch[slots[1]] = Cl.Int(metadata.id, 0)
    patch[slots[2]] = math.max(Cl.Int(metadata.var, 0), 0)
    Cl.MergeSkin(xPlayer, patch)
end

function Cl.OutfitPriceFromSkin(gender, skin)
    if type(skin) ~= "table" then return 0 end

    local mapping = {
        { key = "torso_1", category = "top" },
        { key = "tshirt_1", category = "top" },
        { key = "pants_1", category = "bottom" },
        { key = "shoes_1", category = "shoe" },
        { key = "chain_1", category = "necklace" },
        { key = "bags_1", category = "bag" },
        { key = "bproof_1", category = "kevlar" },
        { key = "decals_1", category = "decals" },
        { key = "mask_1", category = "mask" },
        { key = "helmet_1", category = "hat" },
        { key = "glasses_1", category = "glasses" },
        { key = "ears_1", category = "earring" },
        { key = "watches_1", category = "watch" },
        { key = "bracelets_1", category = "bracelet" },
    }

    local total = 0
    for i = 1, #mapping do
        local value = tonumber(skin[mapping[i].key])
        if value and value > 0 then
            total = total + Cl.PriceOf(gender, mapping[i].category)
        end
    end
    return total
end

RegisterServerCallback("core:server:buyClothe", function(source, itemName, metadata, _unused, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    if type(itemName) ~= "string" or not ITEM_NAMES[itemName] then
        Cl.Notify(source, "Article non reconnu.")
        return false
    end

    local meta = Cl.SanitizeMetadata(metadata)
    if not meta then
        Cl.Notify(source, "Article non reconnu.")
        return false
    end

    if not Cl.RateLimit(source, "buyclothe", 200) then return false end

    local gender = Cl.GenderOf(xPlayer)
    if bannedDrawable(gender, itemName, meta) then
        Cl.Notify(source, "Cet article n'est pas disponible a la vente.")
        return false
    end

    local method = (paymentMethod == "bank") and "bank" or "cash"
    local category = resolveCategory(itemName, meta)
    local price = Cl.PriceOf(gender, category)

    if not Cl.Charge(xPlayer, method, price, "clothes-" .. category) then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    meta.sex = meta.sex or Cl.ShortSex(gender)

    if meta.type == "bag" then
        local Inv = VFW.Inventory
        local capacity = 0
        if Inv and Inv.ResolveBagCapacity then
            capacity = tonumber(Inv.ResolveBagCapacity(meta.id, meta.sex)) or 0
        end
        if capacity > 0 then
            meta.bag_capacity = capacity
        end
        if type(meta.bag_uuid) ~= "string" or meta.bag_uuid == "" then
            meta.bag_uuid = Cl.Uuid()
        end
    end

    if not Cl.GiveItem(xPlayer, itemName, 1, meta) then
        if price > 0 and not Cl.IsFreeSession(source) then
            xPlayer.addAccountMoney((method == "bank") and "bank" or "money", price, "clothes-refund")
        end
        Cl.Notify(source, "Inventaire plein.")
        return false
    end

    Cl.ApplySkinFromMetadata(xPlayer, itemName, meta)

    return { success = true }
end)

RegisterServerCallback("core:server:buyVangelico", function(source, itemName, metadata)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    if itemName ~= "accessory" then return false end

    local meta = Cl.SanitizeMetadata(metadata)
    if not meta or type(meta.type) ~= "string" then return false end

    local banKey = VANGELICO_KEYS[meta.type]
    if not banKey then return false end

    if not Cl.RateLimit(source, "buyvangelico", 200) then return false end

    local gender = Cl.GenderOf(xPlayer)
    if Cl.IsVangelicoBanned(gender, banKey, meta.id) then
        Cl.Notify(source, "Ce bijou n'est pas disponible a la vente.")
        return false
    end

    local category = ACCESSORY_TYPES[meta.type] or "accessory"
    local price = Cl.PriceOf(gender, category)

    if not Cl.Charge(xPlayer, "cash", price, "vangelico-" .. category) then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    meta.sex = meta.sex or Cl.ShortSex(gender)

    if not Cl.GiveItem(xPlayer, "accessory", 1, meta) then
        if price > 0 and not Cl.IsFreeSession(source) then
            xPlayer.addAccountMoney("money", price, "vangelico-refund")
        end
        Cl.Notify(source, "Inventaire plein.")
        return false
    end

    Cl.ApplySkinFromMetadata(xPlayer, "accessory", meta)
    return true
end)

RegisterServerCallback("core:server:buyOutfit", function(source, metadata, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local meta = Cl.SanitizeMetadata(metadata)
    if not meta or type(meta.skin) ~= "table" then return false end

    if not Cl.RateLimit(source, "buyoutfit", 500) then return false end

    local gender = Cl.GenderOf(xPlayer)

    for i = 1, #OUTFIT_BAN_SLOTS do
        local slot = OUTFIT_BAN_SLOTS[i]
        local drawable = tonumber(meta.skin[slot.key])
        if drawable and Cl.IsBanned(gender, slot.ban, drawable) then
            Cl.Notify(source, "Cette tenue contient un article qui n'est pas disponible a la vente.")
            return false
        end
    end

    local price = Cl.OutfitPriceFromSkin(gender, meta.skin)
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, price, "outfit") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    meta.renamed = Cl.Str(meta.renamed, 32) or "Tenue"
    meta.clothesSlotType = "outfit"
    meta.sex = meta.sex or Cl.ShortSex(gender)

    if not Cl.GiveItem(xPlayer, "outfit", 1, meta) then
        if price > 0 and not Cl.IsFreeSession(source) then
            xPlayer.addAccountMoney((method == "bank") and "bank" or "money", price, "outfit-refund")
        end
        Cl.Notify(source, "Inventaire plein.")
        return false
    end

    return true
end)

RegisterServerCallback("core:server:hasClothingBag", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return Cl.CountItem(xPlayer, "clothes_bag") > 0
end)

RegisterNetEvent("core:server:applyFreeArms", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(data) ~= "table" then return end
    if not Cl.RateLimit(source, "freearms", 500) then return end

    local gender = Cl.GenderOf(xPlayer)
    local meta = {
        id = Cl.Int(data.id, 0),
        var = math.max(Cl.Int(data.var, 0), 0),
        sex = (data.sex == "w" or data.sex == "f") and "w" or Cl.ShortSex(gender),
        renamed = "Bras",
        type = "arms",
        clothesSlotType = "arms",
    }

    if Cl.IsBanned(gender, "BanArm", meta.id) then return end

    Cl.RemoveItem(xPlayer, "arms", Cl.CountItem(xPlayer, "arms"))
    Cl.GiveItem(xPlayer, "arms", 1, meta)
end)

RegisterNetEvent("core:staff:clearFreeSkinSession", function()
    local source = source
    Cl.FreeSkin[source] = nil
end)

VFW.RegisterCommand("skin", "staff_skin", function(source, xPlayer, args)
    local targetId = Cl.Int(args and args[1], source)
    local target = VFW.GetPlayerFromId(targetId)

    if not target then
        Cl.Notify(source, "Joueur introuvable.")
        return
    end

    Cl.FreeSkin[target.source] = true
    TriggerClientEvent("core:staff:openFreeSkin", target.source)
    Cl.Notify(source, "Magasin gratuit ouvert pour " .. target.name .. ".", "VERT")
end, {
    help = "Ouvrir un magasin de vetements gratuit pour un joueur",
    params = { { name = "id", help = "ID du joueur (soi-meme par defaut)" } },
})

Cl.OutfitSkinKeys = OUTFIT_SKIN_KEYS
