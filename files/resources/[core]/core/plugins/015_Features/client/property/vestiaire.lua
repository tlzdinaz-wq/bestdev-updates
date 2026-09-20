---@meta _
---@diagnostic disable: duplicate-doc-field

local activeProperty = nil

local skinToShop = {
    { skinKey = "torso_1",     skinTexture = "torso_2",     category = "torso" },
    { skinKey = "tshirt_1",    skinTexture = "tshirt_2",    category = "undershirt" },
    { skinKey = "arms",        skinTexture = "arms_2",      category = "arms" },
    { skinKey = "pants_1",     skinTexture = "pants_2",     category = "leg" },
    { skinKey = "shoes_1",     skinTexture = "shoes_2",     category = "shoes" },
    { skinKey = "chain_1",     skinTexture = "chain_2",     category = "accessory" },
    { skinKey = "bags_1",      skinTexture = "bags_2",      category = "bag" },
    { skinKey = "bproof_1",    skinTexture = "bproof_2",    category = "armor" },
    { skinKey = "decals_1",    skinTexture = "decals_2",    category = "decal" },
    { skinKey = "mask_1",      skinTexture = "mask_2",      category = "mask" },
    { skinKey = "helmet_1",    skinTexture = "helmet_2",    category = "hat" },
    { skinKey = "glasses_1",   skinTexture = "glasses_2",   category = "glasses" },
    { skinKey = "ears_1",      skinTexture = "ears_2",      category = "ear" },
    { skinKey = "watches_1",   skinTexture = "watches_2",   category = "watch" },
    { skinKey = "bracelets_1", skinTexture = "bracelets_2", category = "bracelet" },
}

local function buildOutfitItemsFromSkin(skin)
    local items = {}
    for _, m in ipairs(skinToShop) do
        if skin[m.skinKey] then
            items[#items + 1] = {
                category = m.category,
                drawableId = skin[m.skinKey],
                variantId = skin[m.skinTexture] or 0,
            }
        end
    end
    return items
end

local function buildRawSkin(skin)
    return {
        tshirt_1    = skin.tshirt_1,    tshirt_2    = skin.tshirt_2,
        torso_1     = skin.torso_1,     torso_2     = skin.torso_2,
        arms        = skin.arms,        arms_2      = skin.arms_2,
        pants_1     = skin.pants_1,     pants_2     = skin.pants_2,
        shoes_1     = skin.shoes_1,     shoes_2     = skin.shoes_2,
        helmet_1    = skin.helmet_1,    helmet_2    = skin.helmet_2,
        glasses_1   = skin.glasses_1,   glasses_2   = skin.glasses_2,
        bags_1      = skin.bags_1,      bags_2      = skin.bags_2,
        chain_1     = skin.chain_1,     chain_2     = skin.chain_2,
        decals_1    = skin.decals_1,    decals_2    = skin.decals_2,
        bracelets_1 = skin.bracelets_1, bracelets_2 = skin.bracelets_2,
        watches_1   = skin.watches_1,   watches_2   = skin.watches_2,
        ears_1      = skin.ears_1,      ears_2      = skin.ears_2,
        mask_1      = skin.mask_1,      mask_2      = skin.mask_2,
        bproof_1    = skin.bproof_1,    bproof_2    = skin.bproof_2,
    }
end

local function getPropertyLabel(propertyName)
    if not Property or not propertyName then return propertyName end
    for _, group in pairs(Property) do
        if group.data then
            for i = 1, #group.data do
                if group.data[i].name == propertyName then
                    return group.data[i].name or propertyName
                end
            end
        end
    end
    return propertyName
end

local function loadOutfitsAndAccounts()
    local outfits = TriggerServerCallback("core:server:loadOutfits", "private") or {}
    local accounts = TriggerServerCallback("core:server:getClothesPlayerAccounts") or { cash = 0, bank = 0 }
    return outfits, accounts
end

--- Open the property vestiaire (wardrobe) UI for a given property name.
---@param propertyName string
function VFW.OpenPropertyVestiaire(propertyName)
    if not propertyName or propertyName == "" then return end

    local allowed = TriggerServerCallback("core:server:vestiaireCheckAccess", propertyName)
    if not allowed then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas accès à ce vestiaire." })
        return
    end

    activeProperty = propertyName

    local outfits, accounts = loadOutfitsAndAccounts()

    SendNUIMessage({ action = "nui:inventory:visible", data = false })
    VFW.Nui.Focus(true)

    SendNUIMessage({
        action = "propertyVestiaire:open",
        data = {
            propertyName = propertyName,
            propertyLabel = getPropertyLabel(propertyName),
            outfits = outfits,
            playerMoney = accounts.cash or 0,
            playerBank = accounts.bank or 0,
        }
    })
end

RegisterNUICallback("propertyVestiaire:close", function(_, cb)
    activeProperty = nil
    VFW.Nui.Focus(false)
    cb({})
end)

RegisterNUICallback("propertyVestiaire:reload", function(_, cb)
    if not activeProperty then cb({ outfits = {} }); return end
    local outfits, accounts = loadOutfitsAndAccounts()
    cb({
        outfits = outfits,
        playerMoney = accounts.cash or 0,
        playerBank = accounts.bank or 0,
    })
end)

RegisterNUICallback("propertyVestiaire:checkOutfitName", function(data, cb)
    local exists = TriggerServerCallback("core:server:checkOutfitName", data.name)
    cb(exists == true)
end)

RegisterNUICallback("propertyVestiaire:getOutfitPrice", function(_, cb)
    local skin = GetPlayerCurrentSkin()
    if not skin then cb(0); return end
    local items = buildOutfitItemsFromSkin(skin)
    local price = TriggerServerCallback("core:server:getOutfitPrice", items)
    cb(price or 0)
end)

RegisterNUICallback("propertyVestiaire:saveCurrentOutfit", function(data, cb)
    if not activeProperty then cb(false); return end

    local skin = GetPlayerCurrentSkin()
    if not skin then cb(false); return end

    local items = buildOutfitItemsFromSkin(skin)
    if #items == 0 then cb(false); return end

    local rawSkin = buildRawSkin(skin)
    local outfitName = data.outfitName or "Ma Tenue"
    local paymentMethod = data.paymentMethod or 'cash'
    local totalPrice = data.totalPrice or 0

    local success = TriggerServerCallback(
        "core:server:saveCurrentOutfit",
        outfitName, items, totalPrice, paymentMethod, rawSkin
    )

    if success then
        VFW.LoadInventories()
    end
    cb(success == true)
end)

RegisterNUICallback("propertyVestiaire:purchaseOutfit", function(data, cb)
    if not activeProperty then cb(false); return end
    local outfitId = data.outfitId
    local paymentMethod = data.paymentMethod or 'cash'

    local success = TriggerServerCallback("core:server:purchasePrivateOutfit", outfitId, paymentMethod)

    if success then
        VFW.LoadInventories()
    end
    cb(success == true)
end)

RegisterNUICallback("propertyVestiaire:deleteOutfit", function(data, cb)
    if not activeProperty then cb(false); return end
    local success = TriggerServerCallback("core:server:deleteOutfit", data.outfitId)
    cb(success == true)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if activeProperty then
        activeProperty = nil
        VFW.Nui.Focus(false)
    end
end)
