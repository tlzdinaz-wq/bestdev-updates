---@meta _
---@diagnostic disable: duplicate-doc-field

---@class VFW
VFW = {}

-- Base CDN des assets — pilotée par le ConVar `core_brand_cdn_base` (voir config/branding.lua).
-- Fallback sur le littéral si BRANDING n'est pas chargé (sécurité).
VFW.CDN_BASE = (BRANDING and BRANDING.cdnBase) or "https://cfx-nui-core/interface/brand"

local LEGACY_BRAND_NAME = "EVE"

---Nom de marque du serveur (ConVar `core_brand_name`).
---@return string
function VFW.BrandName()
    return (BRANDING and BRANDING.name) or LEGACY_BRAND_NAME
end

---@return string
function VFW.StaffTitle()
    return VFW.BrandName() .. " Staff"
end

---@return string
function VFW.AnimatorTitle()
    return VFW.BrandName() .. " Animateur"
end

---@return string
function VFW.ReportTitle()
    return VFW.BrandName() .. " Report"
end

---@return string
function VFW.BoutiqueTitle()
    return VFW.BrandName() .. " Boutique"
end

---Remplace le nom legacy « EVE » par le nom de marque courant (ConVar `core_brand_name`).
---@param text string|nil
---@return string|nil
function VFW.NormalizeBrandText(text)
    if not text or type(text) ~= "string" then return text end
    if text:find(LEGACY_BRAND_NAME, 1, true) then
        return text:gsub(LEGACY_BRAND_NAME, VFW.BrandName())
    end
    return text
end

---Build a full CDN URL from a relative path.
---@param path string  Relative path (e.g. "misc/aucun.png", "mugshots/photo.png")
---@return string
function VFW.CdnUrl(path)
    if not path or path == "" then return VFW.CDN_BASE end
    if type(path) ~= "string" then return VFW.CDN_BASE end
    if path:match("^https?://") or path:match("^nui://") or path:match("^data:") then
        return path
    end
    if path:match("^r2%.fivemanage%.com/") or path:match("^[%w%-]+%.fivemanage%.com/") or path:match("^[%w%-]+%.fmfile%.com/") then
        return "https://" .. path
    end
    if path:sub(1, 1) == "/" then path = path:sub(2) end
    return VFW.CDN_BASE .. "/" .. path
end

local brandAssetExistsMemo = {}

---Le fichier existe-t-il dans `interface/brand/` (évite les 404 NUI transparents).
---@param rel string
---@return boolean
function VFW.BrandAssetExists(rel)
    if type(rel) ~= "string" or rel == "" then return false end
    rel = rel:gsub("^/+", "")
    local cached = brandAssetExistsMemo[rel]
    if cached ~= nil then return cached end
    local ok, data = pcall(LoadResourceFile, GetCurrentResourceName(), "interface/brand/" .. rel)
    local exists = ok and type(data) == "string"
    brandAssetExistsMemo[rel] = exists
    return exists
end

---@return string
function VFW.ItemPlaceholderUrl()
    return VFW.CdnUrl("items/placeholder.svg")
end

---@return string
function VFW.OutfitPlaceholderUrl()
    return VFW.CdnUrl("outfits_greenscreener/aucun.svg")
end

---Image d’un item : URL FiveManage/https telle quelle, sinon fichier local, sinon placeholder.
---@param name string
---@param def table|nil
---@return string
function VFW.ItemImageUrl(name, def)
    local raw
    if type(def) == "table" then
        if type(def.data) == "table" and type(def.data.image) == "string" and def.data.image ~= "" then
            raw = def.data.image
        elseif type(def.image) == "string" and def.image ~= "" then
            raw = def.image
        end
    end
    if type(raw) == "string" and raw ~= "" then
        if raw:match("^https?://") or raw:match("^nui://") or raw:match("^data:")
            or raw:match("^r2%.fivemanage%.com/") or raw:match("^[%w%-]+%.fivemanage%.com/")
            or raw:match("^[%w%-]+%.fmfile%.com/") then
            return VFW.CdnUrl(raw)
        end
        local rel = raw:gsub("^/+", ""):gsub("^assets/", "")
        if VFW.BrandAssetExists(rel) then
            return VFW.CdnUrl(rel)
        end
    end
    if type(name) == "string" and name ~= "" then
        local byName = ("items/%s.webp"):format(name)
        if VFW.BrandAssetExists(byName) then
            return VFW.CdnUrl(byName)
        end
    end
    return VFW.ItemPlaceholderUrl()
end

-- CDN namespace (shared part — server adds Upload/Delete/List in 023_cdn.lua)

---Le grade `niveau_6` a tous les droits, même si la table `permissions` est vide en base.
---@param role any
---@return boolean
function VFW.IsNiveau6Role(role)
    if role == nil then return false end
    if role == "niveau_6" then return true end
    if type(role) ~= "string" then return false end
    local n = role:lower():gsub("[%s%-]+", "_")
    return n == "niveau_6" or n == "niveau6"
end

---Map complète des droits staff (clés Config.Permissions + flags internes).
---@return table<string, boolean>
function VFW.BuildFullPermissions()
    local all = { dev = true, staff = true, admin = true }
    local source = (Config and Config.Permissions) or {}
    for key in pairs(source) do
        all[key] = true
    end
    return all
end

---Remplit `data.permissions` si le rôle est niveau 6.
---@param data table|nil
---@return table|nil
function VFW.HydrateNiveau6Permissions(data)
    if type(data) ~= "table" then return data end
    if not VFW.IsNiveau6Role(data.role or data.roleId) then return data end
    data.role = "niveau_6"
    local perms = data.permissions
    if type(perms) ~= "table" then
        data.permissions = VFW.BuildFullPermissions()
        return data
    end
    for key in pairs(VFW.BuildFullPermissions()) do
        perms[key] = true
    end
    data.permissions = perms
    return data
end

local function permGranted(value)
    return value == true or value == 1 or value == "true" or value == "1"
end

---Menu staff ouvert mais aucun outil flaggé (grade mal hydraté).
---@param perms table|nil
---@return boolean
function VFW.IsSparseStaffPerms(perms)
    if type(perms) ~= "table" then return false end
    if not (permGranted(perms.staff_menu) or permGranted(perms.menu_anim)) then
        return false
    end
    if permGranted(perms.noclip) or permGranted(perms.sanctions)
        or permGranted(perms.gestion) or permGranted(perms.heal)
        or permGranted(perms.give_item) or permGranted(perms.ban) then
        return false
    end
    local n = 0
    for _ in pairs(perms) do
        n = n + 1
        if n > 8 then return false end
    end
    return true
end

---Vérifie un droit staff côté client. `niveau_6` / `dev` / `admin` bypass toutes les clés.
---@param key string|nil
---@return boolean
function VFW.HasStaffPerm(key)
    if not key or key == "" then return true end
    local data = VFW.PlayerGlobalData
    if not data then return false end
    if VFW.IsNiveau6Role(data.role or data.roleId) then return true end
    local perms = data.permissions
    if type(perms) ~= "table" then return false end
    if permGranted(perms.dev) or permGranted(perms.admin) then return true end
    if VFW.IsSparseStaffPerms(perms) then return true end
    if permGranted(perms[key]) then return true end
    for k, v in pairs(perms) do
        if type(k) == "number" and v == key then return true end
    end
    return false
end

---Table réelle des droits. `niveau_6` / dev / admin / grade cassé = tout.
---@return table<string, boolean>
function VFW.StaffPerms()
    local data = VFW.PlayerGlobalData
    if not data then return {} end
    if VFW.IsNiveau6Role(data.role or data.roleId) then
        return VFW.BuildFullPermissions()
    end
    local src = data.permissions
    if type(src) ~= "table" then return {} end
    if permGranted(src.dev) or permGranted(src.admin) or VFW.IsSparseStaffPerms(src) then
        return VFW.BuildFullPermissions()
    end
    local out = {}
    for k, v in pairs(src) do
        if type(k) == "number" and type(v) == "string" then
            out[v] = true
        elseif permGranted(v) then
            out[k] = true
        end
    end
    return out
end

---Applique le snapshot renvoyé par `vfw:staff:syncMyAccess`.
---@param payload table|nil
function VFW.ApplyStaffAccess(payload)
    if type(payload) ~= "table" then return end
    VFW.PlayerGlobalData = VFW.PlayerGlobalData or {}
    if payload.role ~= nil then
        VFW.PlayerGlobalData.role = payload.role
    end
    if type(payload.permissions) == "table" then
        VFW.PlayerGlobalData.permissions = payload.permissions
    end
    VFW.HydrateNiveau6Permissions(VFW.PlayerGlobalData)
    if VFW.IsSparseStaffPerms(VFW.PlayerGlobalData.permissions) then
        VFW.PlayerGlobalData.permissions = VFW.BuildFullPermissions()
    end
end

VFW.CDN = VFW.CDN or {}

---Get a full CDN URL from a relative path (alias for VFW.CdnUrl).
---@param path string  Relative path (e.g. "items/bread.webp", "hud/notifications/100.webp")
---@return string
function VFW.CDN.Get(path)
    return VFW.CdnUrl(path)
end

exports("getSharedObject", function()
    return VFW
end)

-- Configuration du framework centralisée dans config/framework/config.lua
-- Les valeurs Config.* sont désormais définies avant ce fichier via shared_scripts.
