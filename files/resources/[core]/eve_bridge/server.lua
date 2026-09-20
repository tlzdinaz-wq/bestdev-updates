--[[
    eve_bridge — serveur

    Rôle : source unique du branding (URLs CDN, couleurs, liens, Discord RP) pour
    toutes les resources, + journal Discord facultatif.

    HORS LIGNE PAR DÉFAUT. Le panel SaaS n'est jamais requis : si eve_panel_url
    ou eve_slug est vide, aucun appel réseau n'est fait et tout vient des
    ConVars. Quand le panel répond, ses champs écrasent les champs locaux.

    Consommateur principal :
      core/plugins/000_framework/server/026_eve_branding.lua
        -> exports.eve_bridge:GetBrandingManifest()
      Cet export DOIT renvoyer la forme « manifest » attendue par
      VFW.Branding.Build() : displayName, logo, banner, links{}, colors{},
      uiModel, loadingScreen, loadingScreenMusic, notificationLogo, background,
      discord{appId, statusText, largeImage, largeImageText, smallImage,
      smallImageText}. Tout champ nil/"" est complété par core depuis BRANDING.
]]

local ready = false
local branding = nil
local webhooks = {}

for category, url in pairs(BridgeConfig.Webhooks) do
    webhooks[category] = url
end

local function cdnBase()
    local base = GetConvar("core_brand_cdn_base", "https://cfx-nui-core/interface/brand")
    if base:sub(-1) == "/" then base = base:sub(1, -2) end
    return base
end

local function assetUrl(path)
    if type(path) ~= "string" or path == "" then return "" end
    if path:match("^https?://") then return path end
    if path:sub(1, 1) == "/" then path = path:sub(2) end
    return cdnBase() .. "/" .. path
end

local function buildBranding()
    return {
        name = GetConvar("core_brand_name", "EVE"),
        displayName = GetConvar("core_brand_name", "EVE"),
        cdnBase = cdnBase(),
        logo = assetUrl(BridgeConfig.Assets.logo),
        logoRed = assetUrl(BridgeConfig.Assets.logoRed),
        background = assetUrl(BridgeConfig.Assets.background),
        loadingScreen = assetUrl(BridgeConfig.Assets.loadingScreen),
        banner = assetUrl(BridgeConfig.Assets.banner),
        notificationLogo = assetUrl(BridgeConfig.Assets.notificationLogo),
        uiModel = BridgeConfig.UiModel,
        colors = {
            primary = GetConvar("core_brand_color_primary", "#7263EE"),
            primaryLight = GetConvar("core_brand_color_primary_light", "#9B91F3"),
            primaryDark = GetConvar("core_brand_color_primary_dark", "#40378A"),
            legacy = GetConvar("core_brand_color_legacy", "#5A4FBB"),
            secondary = GetConvar("core_brand_color_secondary", "#14122B"),
        },
        links = {
            -- NOTE : core/config/branding.lua ligne 51 lit GetConvar("   ", ...)
            -- (nom de ConVar = des espaces) et ne verra donc jamais
            -- core_brand_website. C'est ce manifest qui répare le lien « site ».
            website = GetConvar("core_brand_website", "https://eve-rp.fr"),
            discord = GetConvar("core_discord_invite", "https://discord.gg/eve-rp"),
            tiktok = GetConvar("core_brand_tiktok", ""),
            shop = GetConvar("core_brand_shop", ""),
        },
        discord = {
            appId = tonumber(BridgeConfig.Discord.appId) or 0,
            statusText = BridgeConfig.Discord.statusText,
            largeImage = BridgeConfig.Discord.largeImage,
            largeImageText = BridgeConfig.Discord.largeImageText,
            smallImage = BridgeConfig.Discord.smallImage,
            smallImageText = BridgeConfig.Discord.smallImageText,
        },
    }
end

---Appelle le panel. Court-circuité (cb(nil) immédiat) si le panel n'est pas
---configuré : c'est ce qui garantit le fonctionnement hors ligne.
local function fetchPanel(path, cb)
    if BridgeConfig.PanelUrl == "" or BridgeConfig.Slug == "" then
        cb(nil)
        return
    end

    local url = ("%s/api/servers/%s/%s"):format((BridgeConfig.PanelUrl:gsub("/+$", "")), BridgeConfig.Slug, path)
    local headers = { ["Content-Type"] = "application/json" }

    if BridgeConfig.PanelToken ~= "" then
        headers["Authorization"] = "Bearer " .. BridgeConfig.PanelToken
    end

    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or not body or body == "" then
            cb(nil)
            return
        end

        local ok, decoded = pcall(json.decode, body)
        cb(ok and decoded or nil)
    end, "GET", "", headers)
end

---Fusion par clé de premier niveau, sauf pour les sous-tables connues
---(colors/links/discord) fusionnées champ à champ pour qu'un panel partiel
---n'efface pas les valeurs locales.
local function mergeRemote(target, remote)
    for k, v in pairs(remote) do
        if type(v) == "table" and type(target[k]) == "table" then
            for sk, sv in pairs(v) do
                if sv ~= nil and sv ~= "" then target[k][sk] = sv end
            end
        elseif v ~= nil and v ~= "" then
            target[k] = v
        end
    end
end

function RefreshBranding()
    branding = buildBranding()

    if BridgeConfig.PanelUrl == "" or BridgeConfig.Slug == "" then
        ready = true
        return branding
    end

    fetchPanel("branding", function(remote)
        if type(remote) == "table" then
            mergeRemote(branding, remote.branding or remote.manifest or remote)
        end
        ready = true
    end)

    return branding
end

function RefreshWebhooks()
    -- Repart toujours des ConVars locales : le panel complète, il ne remplace pas.
    local merged = {}
    for category, url in pairs(BridgeConfig.Webhooks) do
        merged[category] = url
    end
    webhooks = merged

    fetchPanel("webhooks", function(remote)
        if type(remote) == "table" then
            for category, url in pairs(remote) do
                if type(url) == "string" and url ~= "" then
                    webhooks[category] = url
                end
            end
        end
    end)

    return webhooks
end

function GetBranding()          return branding or buildBranding() end
function GetColors()            return GetBranding().colors end
function GetLogo()              return GetBranding().logo end
function GetBackground()        return GetBranding().background end
function GetLoadingScreen()     return GetBranding().loadingScreen end
function GetBanner()            return GetBranding().banner end
function GetNotificationLogo()  return GetBranding().notificationLogo end
function GetAsset(path)         return assetUrl(path) end
function IsReady()              return ready end
function LogsReady()            return next(webhooks) ~= nil end

---Forme « manifest » consommée par VFW.Branding.Build() dans core.
---Nom exact appelé par core : exports.eve_bridge:GetBrandingManifest()
---@return table
function GetBrandingManifest()
    local b = GetBranding()

    return {
        displayName = b.displayName,
        logo = b.logo,
        banner = b.banner,
        background = b.background,
        notificationLogo = b.notificationLogo,
        loadingScreen = b.loadingScreen,
        loadingScreenMusic = b.loadingScreenMusic,
        uiModel = b.uiModel,
        links = {
            website = b.links.website,
            discord = b.links.discord,
            tiktok = b.links.tiktok,
            shop = b.links.shop,
        },
        colors = {
            primary = b.colors.primary,
            secondary = b.colors.secondary,
        },
        discord = b.discord,
    }
end

local function embedColor()
    local hex = (GetColors().primary or "#7263EE"):gsub("#", "")
    return tonumber(hex, 16) or 3901635
end

---@param category string  clé de BridgeConfig.WebhookCategories
---@param content string
---@param extra? table     tableau de champs d'embed Discord
---@return boolean         false si la catégorie n'a aucun webhook configuré
function PostLog(category, content, extra)
    local hook = webhooks[category] or webhooks.default

    if type(hook) ~= "string" or hook == "" then return false end

    local payload = {
        username = GetConvar("core_brand_name", "EVE"),
        avatar_url = GetLogo(),
        embeds = { {
            title = tostring(category),
            description = tostring(content),
            color = embedColor(),
            footer = { text = os.date("%Y-%m-%d %H:%M:%S") },
            fields = type(extra) == "table" and extra or nil,
        } },
    }

    local ok, encoded = pcall(json.encode, payload)
    if not ok then return false end

    PerformHttpRequest(hook, function() end, "POST", encoded, { ["Content-Type"] = "application/json" })
    return true
end

---@param url string
---@param payload table
---@return boolean
function PostCustomLog(url, payload)
    if type(url) ~= "string" or url == "" then return false end

    local ok, encoded = pcall(json.encode, payload or {})
    if not ok then return false end

    PerformHttpRequest(url, function() end, "POST", encoded, { ["Content-Type"] = "application/json" })
    return true
end

exports("getLogo", GetLogo)
exports("getBackground", GetBackground)
exports("getLoadingScreen", GetLoadingScreen)
exports("getBanner", GetBanner)
exports("getNotificationLogo", GetNotificationLogo)
exports("getAsset", GetAsset)
exports("getColors", GetColors)
exports("getBranding", GetBranding)
exports("getBrandingManifest", GetBrandingManifest)
-- core appelle la variante PascalCase ; on expose les deux orthographes.
exports("GetBrandingManifest", GetBrandingManifest)
exports("refreshBranding", RefreshBranding)
exports("isReady", IsReady)
exports("refreshWebhooks", RefreshWebhooks)
exports("logsReady", LogsReady)
exports("postLog", PostLog)
exports("postCustomLog", PostCustomLog)

CreateThread(function()
    RefreshBranding()
    RefreshWebhooks()

    -- Pas de boucle de rafraîchissement sans panel : rien ne changerait, les
    -- ConVars sont figées pour la durée du process.
    if BridgeConfig.PanelUrl == "" or BridgeConfig.Slug == "" then return end

    while true do
        Wait(BridgeConfig.RefreshInterval)
        RefreshBranding()
        RefreshWebhooks()
    end
end)
