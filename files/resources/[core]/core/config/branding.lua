---
--- SaaS Branding configuration.
--- Source unique de vérité pour l'identité du serveur, alimentée par des ConVars
--- (voir le bloc « SaaS Branding » dans env.cfg). Chargé en `shared` via
--- `config/*.lua` dans fxmanifest.lua, donc disponible côté client ET serveur,
--- AVANT les plugins. Ne pas coder l'identité en dur ailleurs : utiliser BRANDING.
---

---@class BrandingColors
---@field primary string       Accent principal de l'UI (hex)
---@field primaryLight string  Variante claire (hex)
---@field primaryDark string   Variante foncée (hex)
---@field legacy string        Ancien bleu d'identité (hex)
---@field secondary string     Couleur secondaire (panel EVE : colors.secondary)

---@class BrandingLinks
---@field website string   URL du site
---@field discord string   Invitation Discord
---@field tiktok string    URL TikTok ("" si absent)
---@field shop string      URL de la boutique externe ("" si absent)

---@class Branding
---@field name string          Nom de marque affiché
---@field website string       URL du site
---@field discord string       Invitation Discord
---@field cdnBase string       Base CDN des assets (sans slash final)
---@field logo string          Chemin du logo (relatif au CDN)
---@field logoRed string       Chemin du logo variante rouge (relatif au CDN)
---@field vuiBanner string     URL complète de la bannière des menus VUI ("" = défauts)
---@field colors BrandingColors
---@field links BrandingLinks  Liens externes (panel EVE : champ `links`)
BRANDING = {
    name    = GetConvar("core_brand_name", "EVE"),
    website = GetConvar("core_brand_website", "https://eve-rp.fr"),
    discord = GetConvar("core_discord_invite", "https://discord.gg/eve-rp"),
    cdnBase = GetConvar("core_brand_cdn_base", "https://cfx-nui-core/interface/brand"),
    logo    = GetConvar("core_brand_logo", "logo/logo.svg"),
    logoRed = GetConvar("core_brand_logo_red", "logo/logo_red.svg"),
    -- Bannière des menus VUI (URL complète). Vide => bannières par défaut par type.
    vuiBanner = GetConvar("core_brand_vui_banner", ""),
    colors  = {
        primary      = GetConvar("core_brand_color_primary", "#7263EE"),
        primaryLight = GetConvar("core_brand_color_primary_light", "#9B91F3"),
        primaryDark  = GetConvar("core_brand_color_primary_dark", "#40378A"),
        legacy       = GetConvar("core_brand_color_legacy", "#5A4FBB"),
        secondary    = GetConvar("core_brand_color_secondary", "#14122B"),
    },
    -- Liens externes. website/discord reprennent les ConVars existantes ;
    -- tiktok/shop n'ont pas de ConVar par défaut (alimentés par le panel).
    links = {
        website = GetConvar("core_brand_website", "https://eve-rp.fr"),
        discord = GetConvar("core_discord_invite", "https://discord.gg/eve-rp"),
        tiktok  = GetConvar("core_brand_tiktok", ""),
        shop    = GetConvar("core_brand_shop", ""),
    },
}

-- Normalise la base CDN : pas de slash final (les helpers ajoutent le séparateur).
if BRANDING.cdnBase:sub(-1) == "/" then
    BRANDING.cdnBase = BRANDING.cdnBase:sub(1, -2)
end
