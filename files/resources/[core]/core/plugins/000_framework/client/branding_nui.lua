---@meta _
---@diagnostic disable: duplicate-doc-field

-- Pont branding Lua -> NUI.
--
-- 1. L'UI React (App.tsx) et le loading screen appellent `nui:getBranding` au
--    boot pour récupérer l'identité du serveur (nom, couleurs, base CDN, logos).
-- 2. Le panel EVE peut surcharger ces valeurs à chaud : le serveur
--    (026_eve_branding.lua) pousse l'event 'core:branding:apply' depuis les
--    exports d'`eve_bridge`. On l'applique alors aux NUI ouvertes ET au
--    loading screen, sans reconnexion.
--
-- Source par défaut : BRANDING (config/branding.lua) alimenté par les ConVars
-- `core_brand_*`. Le panel ne fait que surcharger les slots qu'il fournit.

-- Assets du manifest panel qui n'ont pas d'équivalent direct dans BRANDING
-- (loading screen, musique, logo de notif, fond). Injectés dans `nui:getBranding`.
local liveAssets = {
    loadingScreen = nil,
    loadingScreenMusic = nil,
    notificationLogo = nil,
    background = nil,
}

-- Fusionne un payload panel dans BRANDING + le cache d'assets live.
local function mergePayload(payload)
    if type(payload) ~= 'table' then return end

    -- Mentalité serveur (devise/format) pilotée par le panel (`uiModel`). Met à
    -- jour LOCALE côté client pour les FormatMoney client ; le NUI est notifié
    -- via SendNUIMessage plus bas (data.locale).
    if type(payload.uiModel) == 'string' then
        ApplyMentaServer(payload.uiModel)
    end

    -- Nom de marque du panel (`displayName`) : alimente BRANDING.name, utilisé
    -- par VFW.BrandName()/NormalizeBrandText (notifications, menus, boutique).
    if type(payload.displayName) == 'string' and payload.displayName ~= '' then
        BRANDING.name = payload.displayName
    end

    if type(payload.logo) == 'string' and payload.logo ~= '' then
        BRANDING.logo = payload.logo
    end

    if type(payload.banner) == 'string' then
        BRANDING.vuiBanner = payload.banner
    end

    if type(payload.links) == 'table' then
        BRANDING.links = BRANDING.links or {}
        for _, k in ipairs({ 'website', 'discord', 'tiktok', 'shop' }) do
            local v = payload.links[k]
            if type(v) == 'string' and v ~= '' then
                BRANDING.links[k] = v
            end
        end
        -- website/discord ont aussi un champ direct dans BRANDING (rétro-compat).
        if BRANDING.links.website then BRANDING.website = BRANDING.links.website end
        if BRANDING.links.discord then BRANDING.discord = BRANDING.links.discord end
    end

    if type(payload.colors) == 'table' and payload.colors.primary then
        BRANDING.colors = BRANDING.colors or {}
        BRANDING.colors.primary = payload.colors.primary
        BRANDING.colors.secondary = payload.colors.secondary
        BRANDING.colors.primaryLight = payload.colors.primaryLight
        BRANDING.colors.primaryDark = payload.colors.primaryDark
        BRANDING.colors.legacy = payload.colors.legacy or payload.colors.primary
    end

    liveAssets.loadingScreen = payload.loadingScreen
    liveAssets.loadingScreenMusic = payload.loadingScreenMusic
    liveAssets.background = payload.background
    if type(payload.notificationLogo) == "string" and payload.notificationLogo ~= "" then
        liveAssets.notificationLogo = payload.notificationLogo
    elseif type(payload.logo) == "string" and payload.logo ~= "" then
        liveAssets.notificationLogo = payload.logo
    end
end

-- Renvoie BRANDING enrichi des assets live (copie superficielle).
local function buildBrandingResponse()
    local out = {}
    for k, v in pairs(BRANDING or {}) do
        out[k] = v
    end
    out.loadingScreen = liveAssets.loadingScreen
    out.loadingScreenMusic = liveAssets.loadingScreenMusic
    out.notificationLogo = liveAssets.notificationLogo
    out.background = liveAssets.background
    -- Bannière de marque (panel/ConVar `core_brand_vui_banner`) exposée sous la clé
    -- `banner` attendue par le NUI React (utils/branding.ts → getBrandBanner).
    out.banner = BRANDING.vuiBanner
    -- Locale (devise + format des nombres) selon MentaServer (config/locale.lua).
    -- Statique (non surchargeable par le panel) : le NUI formate les montants
    -- via `formatMoney` (interface/src/utils/math.ts) à partir de ces valeurs.
    out.mentaServer = MENTA_SERVER
    out.locale = LOCALE
    -- Source du manifest panel : permet au loading screen de fetch DIRECTEMENT
    -- (sans attendre le push serveur). ConVars `eve_panel_url` + `eve_slug`.
    local panelUrl = GetConvar('eve_panel_url', '')
    local slug = GetConvar('eve_slug', '')
    if panelUrl ~= '' and slug ~= '' then
        out.panelUrl = panelUrl
        out.slug = slug
        out.manifestUrl = panelUrl:gsub('/+$', '') .. '/api/branding/' .. slug
    end
    return out
end

-- Rafraîchit le bouton "Discord" de la présence Discord (Config.DiscordActivity)
-- avec le lien courant, quand le panel pousse un nouveau Discord.
local function refreshDiscordPresence()
    if type(Config) ~= 'table' or type(Config.DiscordActivity) ~= 'table' then return end
    local buttons = Config.DiscordActivity.buttons
    if type(buttons) ~= 'table' then return end
    for i = 1, #buttons do
        local btn = buttons[i]
        if type(btn) == 'table' and type(btn.label) == 'string' and btn.label:find('Discord') then
            btn.url = BRANDING.discord or btn.url
            pcall(SetDiscordRichPresenceAction, i - 1, btn.label, btn.url)
        end
    end
end

RegisterNuiCallback("nui:getBranding", function(_, cb)
    cb(buildBrandingResponse())
end)

-- Push panel -> NUI React (HUD, menus, etc.) + loading screen, à chaud.
RegisterNetEvent('core:branding:apply', function(payload)
    mergePayload(payload)

    SendNUIMessage({
        action = 'core:branding:apply',
        data = {
            name = BRANDING.name,
            logo = BRANDING.logo,
            cdnBase = BRANDING.cdnBase,
            colors = BRANDING.colors,
            banner = BRANDING.vuiBanner,
            links = BRANDING.links,
            loadingScreen = liveAssets.loadingScreen,
            loadingScreenMusic = liveAssets.loadingScreenMusic,
            notificationLogo = liveAssets.notificationLogo,
            background = liveAssets.background,
            -- Locale (devise + format) résolu depuis `uiModel` : le NUI React met
            -- à jour son helper formatMoney à chaud (interface/src/utils/branding.ts).
            mentaServer = MENTA_SERVER,
            locale = LOCALE,
        },
    })

    -- Le loading screen est une NUI séparée : il ne reçoit pas SendNUIMessage.
    -- On le met à jour via SendLoadingScreenMessage tant qu'il est affiché.
    local lsMsg = json.encode({
        eventName = 'setBranding',
        name = BRANDING.name,
        loadingScreen = liveAssets.loadingScreen,
        loadingScreenMusic = liveAssets.loadingScreenMusic,
        logo = BRANDING.logo,
        colors = BRANDING.colors,
        links = BRANDING.links,
    })
    pcall(SendLoadingScreenMessage, lsMsg)

    -- Relaie couleur + nom de marque à VUI : accents CSS et overlay « {Nom} Staff »
    -- sur les bannières (le PNG ne doit plus porter le nom en dur).
    TriggerEvent('core:vui:setBranding', {
        primary      = BRANDING.colors and BRANDING.colors.primary or nil,
        primaryLight = BRANDING.colors and BRANDING.colors.primaryLight or nil,
        primaryDark  = BRANDING.colors and BRANDING.colors.primaryDark or nil,
        name         = BRANDING.name,
        staffTitle   = (BRANDING.name or '') .. ' Staff',
        -- logo configuré (core_brand_logo / panel), en URL absolue : utilisé par le chat
        logo         = BRANDING.logo and VFW.CdnUrl(BRANDING.logo) or nil,
    })

    -- Bannière des menus VUI : mise à jour à chaud (menus déjà créés + menu ouvert).
    if type(BRANDING.vuiBanner) == 'string' then
        TriggerEvent('core:vui:setBanner', BRANDING.vuiBanner)
    end

    refreshDiscordPresence()
end)

-- Au (re)démarrage de la NUI core, on réclame l'état branding courant au serveur.
AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then
        TriggerServerEvent('core:branding:request')
    end
end)
