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
