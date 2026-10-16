---@meta _
---@diagnostic disable: duplicate-doc-field

-- ═══════════════════════════════════════════════════════════════
-- URLs des images de vêtements.
-- Les images générées par le hub (Gestion → Images → Vêtements) sont
-- hébergées sur FiveManage ; le serveur tient la table drawable → URL
-- (vfw:server:getOutfitImages). VFW.OutfitImage() renvoie cette URL, sinon
-- la vignette aucun.svg — jamais un 404 NUI (icône cassée / fond transparent).
-- ═══════════════════════════════════════════════════════════════

local cache = nil
local loading = false

local FOLDER_ALIAS = {
    bag = "bags",
    kevlar = "armor",
    body_armor = "armor",
    necklace = "accessory",
    earring = "ear",
    earrings = "ear",
    arms = "torso",
}

local PROP_FOLDERS = {
    hat = true,
    glasses = true,
    ear = true,
    watch = true,
    bracelet = true,
}

local function fetchImages()
    if cache then return cache end
    if loading then
        local deadline = GetGameTimer() + 8000
        while loading and GetGameTimer() < deadline do Wait(50) end
        return cache or {}
    end
    loading = true
    local res = TriggerServerCallback("vfw:server:getOutfitImages")
    loading = false
    if type(res) == "table" then
        cache = res
        return cache
    end
    return {}
end

--- Table complète { sexe = { kind = { dossier = { ["<d>[_<t>].webp"] = url } } } }.
function VFW.OutfitImages()
    return fetchImages()
end

--- URL de l'image d'un vêtement.
---@param sex string "male" | "female"
---@param kind string "clothing" | "props"
---@param folder string torso2, leg, shoes, mask, accessory, hat, glasses, watch, ear, bracelet…
---@param drawable number
---@param texture number|nil 0 par défaut
---@return string
function VFW.OutfitImage(sex, kind, folder, drawable, texture)
    drawable = tonumber(drawable) or 0
    texture = tonumber(texture) or 0
    folder = tostring(folder or "")
    folder = FOLDER_ALIAS[folder] or folder
    if PROP_FOLDERS[folder] then
        kind = "props"
    elseif kind ~= "props" then
        kind = "clothing"
    end
    if sex ~= "female" then sex = "male" end
    local filename = texture == 0 and (drawable .. ".webp") or (drawable .. "_" .. texture .. ".webp")
    local images = fetchImages()
    local url = images[sex] and images[sex][kind] and images[sex][kind][folder] and images[sex][kind][folder][filename]
    if type(url) == "string" and url ~= "" then return url end
    if VFW.OutfitPlaceholderUrl then
        return VFW.OutfitPlaceholderUrl()
    end
    return VFW.CdnUrl("outfits_greenscreener/aucun.svg")
end

-- Le serveur prévient après une salve d'uploads : on relira la table au prochain besoin.
RegisterNetEvent("core:outfits:changed", function()
    cache = nil
end)

-- ═══════════════════════════════════════════════════════════════
-- Comptage vanilla + DLC + packs addon (collections GTA).
-- GetNumberOfPedDrawableVariations rate parfois les slots streamés :
-- on prend le max entre la native globale et l'index collection.
-- ═══════════════════════════════════════════════════════════════

local function collectionCount(ped)
    if not ped or not DoesEntityExist(ped) or not GetPedCollectionsCount then return 0 end
    local ok, n = pcall(GetPedCollectionsCount, ped)
    if ok and type(n) == "number" and n > 0 then return n end
    return 0
end

--- Nombre de drawables (vêtement ou prop) visibles sur ce ped.
---@param ped number
---@param kind string "clothing" | "props"
---@param index number componentId ou propId
---@return number
function VFW.PedDrawableCount(ped, kind, index)
    if not ped or not DoesEntityExist(ped) or index == nil then return 0 end
    local isProp = kind == "props"
    local n = 0
    if isProp then
        n = GetNumberOfPedPropDrawableVariations(ped, index) or 0
    else
        n = GetNumberOfPedDrawableVariations(ped, index) or 0
    end

    local cols = collectionCount(ped)
    if cols <= 0 then return n end

    local maxG = n
    for i = 0, cols - 1 do
        local okName, name = pcall(GetPedCollectionName, ped, i)
        if okName and name ~= nil then
            local localN = 0
            if isProp and GetNumberOfPedCollectionPropDrawableVariations then
                local ok, v = pcall(GetNumberOfPedCollectionPropDrawableVariations, ped, index, name)
                if ok then localN = tonumber(v) or 0 end
            elseif (not isProp) and GetNumberOfPedCollectionDrawableVariations then
                local ok, v = pcall(GetNumberOfPedCollectionDrawableVariations, ped, index, name)
                if ok then localN = tonumber(v) or 0 end
            end
            if localN > 0 then
                local g
                if isProp and GetPedPropGlobalIndexFromCollection then
                    local ok, v = pcall(GetPedPropGlobalIndexFromCollection, ped, index, name, localN - 1)
                    if ok then g = tonumber(v) end
                elseif (not isProp) and GetPedDrawableGlobalIndexFromCollection then
                    local ok, v = pcall(GetPedDrawableGlobalIndexFromCollection, ped, index, name, localN - 1)
                    if ok then g = tonumber(v) end
                end
                if g and g >= 0 then
                    maxG = math.max(maxG, g + 1)
                end
            end
        end
    end
    return maxG
end

--- Nombre de textures d'un drawable (1 si la native renvoie 0 — packs addon).
---@param ped number
---@param kind string "clothing" | "props"
---@param index number componentId ou propId
---@param drawable number
---@return number
function VFW.PedTextureCount(ped, kind, index, drawable)
    if not ped or not DoesEntityExist(ped) or index == nil then return 1 end
    drawable = tonumber(drawable) or 0
    local isProp = kind == "props"
    local numTex
    if isProp then
        numTex = GetNumberOfPedPropTextureVariations(ped, index, drawable)
    else
        numTex = GetNumberOfPedTextureVariations(ped, index, drawable)
    end
    if (not numTex or numTex <= 0) then
        local col, loc
        if isProp and GetPedCollectionNameFromProp and GetPedCollectionLocalIndexFromProp then
            local okC, c = pcall(GetPedCollectionNameFromProp, ped, index, drawable)
            local okL, l = pcall(GetPedCollectionLocalIndexFromProp, ped, index, drawable)
            if okC then col = c end
            if okL then loc = l end
            if col ~= nil and type(loc) == "number" and GetNumberOfPedCollectionPropTextureVariations then
                local okT, t = pcall(GetNumberOfPedCollectionPropTextureVariations, ped, index, col, loc)
                if okT then numTex = tonumber(t) or numTex end
            end
        elseif (not isProp) and GetPedCollectionNameFromDrawable and GetPedCollectionLocalIndexFromDrawable then
            local okC, c = pcall(GetPedCollectionNameFromDrawable, ped, index, drawable)
            local okL, l = pcall(GetPedCollectionLocalIndexFromDrawable, ped, index, drawable)
            if okC then col = c end
            if okL then loc = l end
            if col ~= nil and type(loc) == "number" and GetNumberOfPedCollectionTextureVariations then
                local okT, t = pcall(GetNumberOfPedCollectionTextureVariations, ped, index, col, loc)
                if okT then numTex = tonumber(t) or numTex end
            end
        end
    end
    return (numTex and numTex > 0) and numTex or 1
end
