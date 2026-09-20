--[[
    eve_bridge — configuration

    Le bridge fonctionne INTÉGRALEMENT HORS LIGNE. Le panel SaaS est facultatif :
    s'il n'est pas configuré (eve_panel_url vide), tout est servi depuis les
    ConVars core_brand_* déclarées dans server.cfg, et les webhooks Discord sont
    lus depuis les ConVars core_webhook_* — aucun appel réseau sortant.

    Si le panel est configuré, ses valeurs viennent se superposer aux locales.
]]

BridgeConfig = {}

BridgeConfig.PanelUrl   = GetConvar("eve_panel_url", "")
BridgeConfig.Slug       = GetConvar("eve_slug", "")
BridgeConfig.PanelToken = GetConvar("eve_panel_token", "")

BridgeConfig.RefreshInterval = 5 * 60000

-- Chemins relatifs au CDN (core_brand_cdn_base) ou URLs absolues http(s).
BridgeConfig.Assets = {
    logo             = GetConvar("core_brand_logo", "logo/logo.svg"),
    logoRed          = GetConvar("core_brand_logo_red", "logo/logo_red.svg"),
    background       = GetConvar("core_brand_background", "misc/background.png"),
    loadingScreen    = GetConvar("core_brand_loadingscreen", ""),
    banner           = GetConvar("core_brand_vui_banner", ""),
    notificationLogo = GetConvar("core_brand_notification_logo", "logo/logo.svg"),
}

-- Discord Rich Presence. core/plugins/000_framework/server/026_eve_branding.lua
-- retombe sur Config.DiscordActivity pour tout ce qui reste vide ici.
BridgeConfig.Discord = {
    appId          = GetConvar("core_discord_app_id", ""),
    statusText     = GetConvar("core_discord_status", ""),
    largeImage     = GetConvar("core_discord_large_image", ""),
    largeImageText = GetConvar("core_discord_large_text", ""),
    smallImage     = GetConvar("core_discord_small_image", ""),
    smallImageText = GetConvar("core_discord_small_text", ""),
}

-- Modèle d'UI ("EU"/"US") — même ConVar que core/config/locale.lua.
BridgeConfig.UiModel = GetConvar("core_menta_server", "EU")

--[[
    Webhooks Discord — 100% optionnels et 100% locaux.

    Une catégorie sans ConVar (ou vide) est simplement ignorée : postLog renvoie
    false, rien n'est envoyé, aucune erreur. Renseigner uniquement les catégories
    voulues dans server.cfg, p.ex. :
        set core_webhook_default "https://discord.com/api/webhooks/..."
        set core_webhook_staff   "https://discord.com/api/webhooks/..."

    ATTENTION : ceci est le journal du bridge. Le noyau a son PROPRE système de
    logs (VFW.GetLogWebhook / VFW.SendWebhook, configuré dans les tables `logs`
    de core/config) — les deux sont indépendants, ne pas les confondre.
]]
BridgeConfig.WebhookCategories = {
    "default",
    "staff",
    "connection",
    "money",
    "inventory",
    "vehicle",
    "job",
    "society",
    "anticheat",
    "death",
    "illegal",
    "shop",
}

BridgeConfig.Webhooks = {}

for i = 1, #BridgeConfig.WebhookCategories do
    local category = BridgeConfig.WebhookCategories[i]
    local url = GetConvar(("core_webhook_%s"):format(category), "")

    if url ~= "" then
        BridgeConfig.Webhooks[category] = url
    end
end
