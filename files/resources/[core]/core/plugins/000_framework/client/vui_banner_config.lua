---@meta _
---@diagnostic disable: duplicate-doc-field

-- Centralized VUI Banner Configuration
-- This file provides a global banner URL that all VUI menus should use

VUI_BANNER_CONFIG = {
    -- Default banner URL from GitHub CDN
    default = VFW.CDN.Get("banners/default.png"),
    f5 = VFW.CDN.Get("banners/f5.png"),
    vip = VFW.CDN.Get("banners/vip.png"),
    -- Admin menu banner
    admin = VFW.CDN.Get("banners/admin.png"),
    animator = VFW.CDN.Get("banners/animateur.png"),
    metier = VFW.CDN.Get("banners/metier.png"),
    faction = VFW.CDN.Get("banners/faction.png"),
    vestiaire = VFW.CDN.Get("banners/vestiaire.png"),
    -- Interim jobs banners
    lumberjack = "nui://VUI/web/dist/assets/banners/lumberjack.webp",
    miner = "nui://VUI/web/dist/assets/banners/mining.webp",
    routier = "nui://VUI/web/dist/assets/banners/routier.webp",
    pizza = "nui://VUI/web/dist/assets/banners/livery.webp",
}

-- Export function for other scripts to get the banner
function GetVUIBanner(type)
    -- Bannière de marque (ConVar core_brand_vui_banner) : si définie, elle prime
    -- sur toutes les bannières par type (identité unifiée des menus VUI).
    if BRANDING and BRANDING.vuiBanner and BRANDING.vuiBanner ~= "" then
        return BRANDING.vuiBanner
    end
    type = type or "default"
    return VUI_BANNER_CONFIG[type] or VUI_BANNER_CONFIG.default
end

exports("GetVUIBanner", GetVUIBanner)

-- Précharger toutes les bannières dans le cache NUI dès le chargement
CreateThread(function()
    Wait(5000)
    local urls = {}
    for _, url in pairs(VUI_BANNER_CONFIG) do
        urls[#urls + 1] = url
    end
    -- Précharge aussi la bannière de marque (ConVar) si définie.
    if BRANDING and BRANDING.vuiBanner and BRANDING.vuiBanner ~= "" then
        urls[#urls + 1] = BRANDING.vuiBanner
    end
    SendNUIMessage({ action = "vui:menu:preloadBanners", data = urls })
end)