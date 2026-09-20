VFW.Branding = VFW.Branding or {}

local PANEL_URL = GetConvar("eve_panel_url", "")
local PANEL_SLUG = GetConvar("eve_slug", "")
local REFRESH_INTERVAL = 600000

local manifest = {}

local function panelManifestUrl()
    if PANEL_URL == "" or PANEL_SLUG == "" then return nil end
    return ("%s/api/branding/%s"):format((PANEL_URL:gsub("/+$", "")), PANEL_SLUG)
end

local STORE = "global_branding"
local JSON_FILE = "config/branding_overrides.json"
local jsonCache = nil
local jsonFileExists = false
local migratedFromVariables = false
local DEFAULT_LOGO = GetConvar("core_brand_logo", "logo/logo.svg")
local DEFAULT_BANNER = GetConvar("core_brand_vui_banner", "")
local DEFAULT_NOTIF = GetConvar("core_brand_notification_logo", "logo/logo.svg")
local CFG_LOGO = (type(BRANDING) == "table" and type(BRANDING.logo) == "string" and BRANDING.logo) or DEFAULT_LOGO
local CFG_BANNER = (type(BRANDING) == "table" and type(BRANDING.vuiBanner) == "string" and BRANDING.vuiBanner) or DEFAULT_BANNER
local CFG_NAME = GetConvar("core_brand_name", (BRANDING and BRANDING.name) or "EVE")
local CFG_WEBSITE = GetConvar("core_brand_website", (BRANDING and BRANDING.website) or "")
local CFG_DISCORD = GetConvar("core_discord_invite", (BRANDING and BRANDING.discord) or "")
local CFG_PRIMARY = GetConvar("core_brand_color_primary", "#7263EE")
local CFG_LOADING = GetConvar("core_brand_loadingscreen", "")
local CFG_LOADING_MUSIC = GetConvar("core_brand_loadingscreen_music", "")

local function str(value, fallback)
    if type(value) == "string" and value ~= "" then return value end
    return fallback
end

local function firstUrl(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    return ""
end

local function resolveBrandUrl(path)
    if type(path) ~= "string" or path == "" then return "" end
    if VFW.CdnUrl then return VFW.CdnUrl(path) end
    return path
end

local function clampByte(n)
    n = math.floor((tonumber(n) or 0) + 0.5)
    if n < 0 then return 0 end
    if n > 255 then return 255 end
    return n
end

local function hexToRgb(hex)
    if type(hex) ~= "string" then return nil end
    local h = hex:gsub("%s+", ""):gsub("^#", "")
    if #h == 3 then
        h = h:sub(1, 1) .. h:sub(1, 1) .. h:sub(2, 2) .. h:sub(2, 2) .. h:sub(3, 3) .. h:sub(3, 3)
    end
    if not h:match("^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]$") then
        return nil
    end
    return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

local function rgbToHex(r, g, b)
    return string.format("#%02X%02X%02X", clampByte(r), clampByte(g), clampByte(b))
end

function VFW.Branding.NormalizeHex(raw)
    local r, g, b = hexToRgb(raw)
    if not r then return nil end
    return rgbToHex(r, g, b)
end

--- Une couleur primaire → palette complète (HUD, VUI, gestion, notifs).
function VFW.Branding.DeriveColors(hex)
    local r, g, b = hexToRgb(hex)
    if not r then return nil end
    local function mix(tr, tg, tb, t)
        return r + (tr - r) * t, g + (tg - g) * t, b + (tb - b) * t
    end
    local lr, lg, lb = mix(255, 255, 255, 0.32)
    local dr, dg, db = mix(0, 0, 0, 0.45)
    local er, eg, eb = mix(0, 0, 0, 0.22)
    local sr, sg, sb = mix(8, 8, 16, 0.88)
    return {
        primary = rgbToHex(r, g, b),
        primaryLight = rgbToHex(lr, lg, lb),
        primaryDark = rgbToHex(dr, dg, db),
        legacy = rgbToHex(er, eg, eb),
        secondary = rgbToHex(sr, sg, sb),
    }
end

local function readColors(raw)
    if type(raw) ~= "table" then return nil end
    local primary = VFW.Branding.NormalizeHex(raw.primary)
    if not primary then return nil end
    local derived = VFW.Branding.DeriveColors(primary)
    if type(raw.primaryLight) == "string" then derived.primaryLight = VFW.Branding.NormalizeHex(raw.primaryLight) or derived.primaryLight end
    if type(raw.primaryDark) == "string" then derived.primaryDark = VFW.Branding.NormalizeHex(raw.primaryDark) or derived.primaryDark end
    if type(raw.legacy) == "string" then derived.legacy = VFW.Branding.NormalizeHex(raw.legacy) or derived.legacy end
    if type(raw.secondary) == "string" then derived.secondary = VFW.Branding.NormalizeHex(raw.secondary) or derived.secondary end
    return derived
end

local DEFAULT_LOADING_SOCIAL_TITLE = "Rejoignez-nous"
local DEFAULT_LOADING_TICKER = {
    "BON JEU SUR NOTRE SERVEUR 🌹",
    "N'HÉSITEZ PAS À FAIRE UN TOUR SUR NOTRE BOUTIQUE ( F1 )",
    "LISEZ LE RÈGLEMENT POUR NE PAS PRENDRE DE SANCTION",
    "MERCI DE NOUS SOUTENIR CHAQUE JOUR ❤️",
}

local function normalizeTickerList(raw)
    local out = {}
    if type(raw) == "string" then
        for line in (raw .. "\n"):gmatch("(.-)\n") do
            local t = line:gsub("^%s+", ""):gsub("%s+$", "")
            if t ~= "" then
                out[#out + 1] = t:sub(1, 160)
            end
        end
    elseif type(raw) == "table" then
        for i = 1, math.min(#raw, 12) do
            local t = raw[i]
            if type(t) == "string" then
                t = t:gsub("^%s+", ""):gsub("%s+$", "")
                if t ~= "" then
                    out[#out + 1] = t:sub(1, 160)
                end
            end
        end
    end
    return out
end

local function snapshotOverrides(current)
    local colors = nil
    if type(current.colors) == "table" and type(current.colors.primary) == "string" then
        colors = {
            primary = current.colors.primary,
            primaryLight = current.colors.primaryLight,
            primaryDark = current.colors.primaryDark,
            legacy = current.colors.legacy,
            secondary = current.colors.secondary,
        }
    end
    return {
        logo = current.logo or "",
        banner = current.banner or "",
        displayName = current.displayName or "",
        website = current.website or "",
        discord = current.discord or "",
        tiktok = current.tiktok or "",
        shop = current.shop or "",
        loadingScreen = current.loadingScreen or "",
        loadingScreenMusic = current.loadingScreenMusic or "",
        loadingSocialTitle = current.loadingSocialTitle or "",
        loadingTicker = normalizeTickerList(current.loadingTicker),
        colors = colors,
    }
end

local function encodeOverridesJson(data)
    local function field(key, value, last)
        return string.format('  %s: %s%s', json.encode(key), json.encode(value or ""), last and "" or ",")
    end
    local tickerJson = json.encode(normalizeTickerList(data.loadingTicker))
    local lines = {
        "{",
        field("displayName", data.displayName),
        field("website", data.website),
        field("discord", data.discord),
        field("tiktok", data.tiktok),
        field("shop", data.shop),
        field("logo", data.logo),
        field("banner", data.banner),
        field("loadingScreen", data.loadingScreen),
        field("loadingScreenMusic", data.loadingScreenMusic),
        field("loadingSocialTitle", data.loadingSocialTitle),
        string.format('  "loadingTicker": %s,', tickerJson),
    }
    if type(data.colors) == "table" and data.colors.primary then
        table.insert(lines, '  "colors": {')
        table.insert(lines, string.format('    "primary": %s,', json.encode(data.colors.primary or "")))
        table.insert(lines, string.format('    "primaryLight": %s,', json.encode(data.colors.primaryLight or "")))
        table.insert(lines, string.format('    "primaryDark": %s,', json.encode(data.colors.primaryDark or "")))
        table.insert(lines, string.format('    "legacy": %s,', json.encode(data.colors.legacy or "")))
        table.insert(lines, string.format('    "secondary": %s', json.encode(data.colors.secondary or "")))
        table.insert(lines, "  }")
    else
        table.insert(lines, '  "colors": null')
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n") .. "\n"
end

local function writeOverridesFile(data)
    local body = encodeOverridesJson(data)
    local ok = SaveResourceFile(GetCurrentResourceName(), JSON_FILE, body, -1)
    if ok then
        jsonCache = data
        jsonFileExists = true
        return true
    end
    return false
end

local function loadOverridesFile()
    if jsonCache ~= nil then return jsonCache end
    local raw = LoadResourceFile(GetCurrentResourceName(), JSON_FILE)
    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            jsonFileExists = true
            jsonCache = decoded
            return jsonCache
        end
    end
    jsonCache = {}
    jsonFileExists = false
    return jsonCache
end

function VFW.Branding.GetOverrides()
    local raw = loadOverridesFile()
    if not jsonFileExists and not migratedFromVariables and VFW.Variables and VFW.Variables.GetVariable then
        local fromVar = VFW.Variables.GetVariable(STORE)
        if type(fromVar) == "table" and type(fromVar.displayName) == "string" and fromVar.displayName ~= "" then
            migratedFromVariables = true
            raw = fromVar
            writeOverridesFile(snapshotOverrides(fromVar))
        end
    end
    if type(raw) ~= "table" then
        raw = {}
    end
    local logo = type(raw.logo) == "string" and raw.logo or ""
    local banner = type(raw.banner) == "string" and raw.banner or ""
    if VFW.GestionImages and VFW.GestionImages.Get then
        local storedLogo = VFW.GestionImages.Get("global", "logo")
        local storedBanner = VFW.GestionImages.Get("global", "banner")
        if storedLogo ~= "" then logo = storedLogo end
        if storedBanner ~= "" then banner = storedBanner end
    end
    return {
        logo = logo,
        banner = banner,
        displayName = type(raw.displayName) == "string" and raw.displayName or "",
        website = type(raw.website) == "string" and raw.website or "",
        discord = type(raw.discord) == "string" and raw.discord or "",
        tiktok = type(raw.tiktok) == "string" and raw.tiktok or "",
        shop = type(raw.shop) == "string" and raw.shop or "",
        loadingScreen = type(raw.loadingScreen) == "string" and raw.loadingScreen or "",
        loadingScreenMusic = type(raw.loadingScreenMusic) == "string" and raw.loadingScreenMusic or "",
        loadingSocialTitle = type(raw.loadingSocialTitle) == "string" and raw.loadingSocialTitle or "",
        loadingTicker = normalizeTickerList(raw.loadingTicker),
        colors = readColors(raw.colors),
    }
end

local function persistOverrides(current)
    local payload = snapshotOverrides(current)
    if not writeOverridesFile(payload) then
        return false
    end
    if VFW.Variables and VFW.Variables.SetVariable then
        VFW.Variables.SetVariable(STORE, payload)
        CreateThread(function()
            if VFW.Variables.Flush then
                pcall(VFW.Variables.Flush, STORE)
            end
        end)
    end
    return true
end

function VFW.Branding.SetOverride(field, url)
    if field ~= "logo" and field ~= "banner" then return false, "Champ invalide." end
    local current = VFW.Branding.GetOverrides()
    current[field] = type(url) == "string" and url or ""
    if not persistOverrides(current) then
        return false, "Impossible d'écrire config/branding_overrides.json."
    end
    VFW.Branding.Push(-1)
    return true
end

function VFW.Branding.SetConfig(patch)
    if type(patch) ~= "table" then return false, "Données invalides." end
    local current = VFW.Branding.GetOverrides()
    if patch.reset == true then
        current.displayName = ""
        current.website = ""
        current.discord = ""
        current.tiktok = ""
        current.shop = ""
        current.colors = nil
    else
        if type(patch.displayName) == "string" then
            current.displayName = patch.displayName:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 32)
        end
        for _, key in ipairs({ "website", "discord", "tiktok", "shop" }) do
            if type(patch[key]) == "string" then
                current[key] = patch[key]:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 256)
            end
        end
        if patch.colors == false then
            current.colors = nil
        elseif type(patch.primary) == "string" or (type(patch.colors) == "table" and patch.colors.primary) then
            local hex = VFW.Branding.NormalizeHex(patch.primary or patch.colors.primary)
            if not hex then return false, "Couleur invalide." end
            current.colors = VFW.Branding.DeriveColors(hex)
        end
    end
    if not persistOverrides(current) then
        return false, "Impossible d'écrire config/branding_overrides.json."
    end
    VFW.Branding.Push(-1)
    return true
end

local function cleanMediaUrl(value, maxLen)
    if type(value) ~= "string" then return "" end
    local out = value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^['\"]+", ""):gsub("['\"]+$", "")
    return out:sub(1, maxLen or 1024)
end

--- Fond vidéo/image + musique + textes/liens du loading screen (persisté dans branding_overrides.json).
function VFW.Branding.SetLoadingScreen(patch)
    if type(patch) ~= "table" then return false, "Données invalides." end
    local current = VFW.Branding.GetOverrides()
    if patch.reset == true then
        current.loadingScreen = ""
        current.loadingScreenMusic = ""
        current.loadingSocialTitle = ""
        current.loadingTicker = {}
    else
        if patch.loadingScreen ~= nil then
            current.loadingScreen = cleanMediaUrl(patch.loadingScreen, 1024)
        end
        if patch.loadingScreenMusic ~= nil then
            current.loadingScreenMusic = cleanMediaUrl(patch.loadingScreenMusic, 1024)
        end
        if patch.loadingSocialTitle ~= nil then
            local title = type(patch.loadingSocialTitle) == "string" and patch.loadingSocialTitle or ""
            current.loadingSocialTitle = title:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 48)
        end
        if patch.loadingTicker ~= nil then
            current.loadingTicker = normalizeTickerList(patch.loadingTicker)
        end
        for _, key in ipairs({ "website", "discord", "tiktok", "shop" }) do
            if patch[key] ~= nil then
                current[key] = cleanMediaUrl(patch[key], 256)
            end
        end
    end
    if not persistOverrides(current) then
        return false, "Impossible d'écrire config/branding_overrides.json."
    end
    VFW.Branding.Push(-1)
    return true
end

function VFW.Branding.Defaults()
    return {
        displayName = CFG_NAME,
        website = CFG_WEBSITE,
        discord = CFG_DISCORD,
        colors = VFW.Branding.DeriveColors(CFG_PRIMARY) or { primary = CFG_PRIMARY },
    }
end

local function buildDiscord()
    local d = type(Config) == "table" and Config.DiscordActivity or nil
    local fromPanel = type(manifest.discord) == "table" and manifest.discord or {}

    return {
        appId = tonumber(fromPanel.appId) or (d and tonumber(d.appId)) or 0,
        statusText = str(fromPanel.statusText or fromPanel.presence, d and d.presence or ""),
        largeImage = str(fromPanel.largeImage, d and d.assetName or ""),
        largeImageText = str(fromPanel.largeImageText, d and d.assetText or ""),
        smallImage = str(fromPanel.smallImage, d and d.assetSmall or ""),
        smallImageText = str(fromPanel.smallImageText, d and d.assetSmallText or ""),
    }
end

function VFW.Branding.Build()
    local links = type(BRANDING.links) == "table" and BRANDING.links or {}
    local panelLinks = type(manifest.links) == "table" and manifest.links or {}
    local colors = type(BRANDING.colors) == "table" and BRANDING.colors or {}
    local panelColors = type(manifest.colors) == "table" and manifest.colors or {}
    local ov = VFW.Branding.GetOverrides()
    local logo = resolveBrandUrl(firstUrl(ov.logo, manifest.logo, CFG_LOGO, DEFAULT_LOGO))
    local banner = resolveBrandUrl(firstUrl(ov.banner, manifest.banner, CFG_BANNER, DEFAULT_BANNER))
    local notifLogo = resolveBrandUrl(firstUrl(ov.logo, manifest.notificationLogo, logo, DEFAULT_NOTIF))

    return {
        displayName = firstUrl(ov.displayName, manifest.displayName, BRANDING.name, CFG_NAME),
        logo = logo,
        banner = banner,
        links = {
            website = firstUrl(ov.website, panelLinks.website, links.website or BRANDING.website, CFG_WEBSITE),
            discord = firstUrl(ov.discord, panelLinks.discord, links.discord or BRANDING.discord, CFG_DISCORD),
            tiktok = firstUrl(ov.tiktok, panelLinks.tiktok, links.tiktok or ""),
            shop = firstUrl(ov.shop, panelLinks.shop, links.shop or ""),
        },
        colors = (function()
            if ov.colors then return ov.colors end
            local primary = firstUrl(panelColors.primary, colors.primary, CFG_PRIMARY)
            local derived = VFW.Branding.DeriveColors(primary) or { primary = primary }
            derived.secondary = firstUrl(panelColors.secondary, colors.secondary, derived.secondary)
            if colors.primaryLight then derived.primaryLight = colors.primaryLight end
            if colors.primaryDark then derived.primaryDark = colors.primaryDark end
            if colors.legacy then derived.legacy = colors.legacy end
            return derived
        end)(),
        uiModel = str(manifest.uiModel, MENTA_SERVER),
        loadingScreen = firstUrl(ov.loadingScreen, manifest.loadingScreen, CFG_LOADING),
        loadingScreenMusic = firstUrl(ov.loadingScreenMusic, manifest.loadingScreenMusic, CFG_LOADING_MUSIC),
        loadingSocialTitle = (function()
            local t = type(ov.loadingSocialTitle) == "string" and ov.loadingSocialTitle:gsub("^%s+", ""):gsub("%s+$", "") or ""
            if t ~= "" then return t end
            return DEFAULT_LOADING_SOCIAL_TITLE
        end)(),
        loadingTicker = (function()
            local list = normalizeTickerList(ov.loadingTicker)
            if #list > 0 then return list end
            return DEFAULT_LOADING_TICKER
        end)(),
        notificationLogo = notifLogo,
        background = manifest.background,
        discord = buildDiscord(),
    }
end

local function applyLocally(payload)
    if type(payload) ~= "table" then return end

    if type(payload.uiModel) == "string" and type(ApplyMentaServer) == "function" then
        pcall(ApplyMentaServer, payload.uiModel)
    end

    if type(payload.displayName) == "string" and payload.displayName ~= "" then
        BRANDING.name = payload.displayName
    end
    if type(payload.logo) == "string" then
        BRANDING.logo = payload.logo ~= "" and payload.logo or CFG_LOGO
    end
    if type(payload.banner) == "string" then
        BRANDING.vuiBanner = payload.banner
    end
    if type(payload.links) == "table" then
        BRANDING.links = BRANDING.links or {}
        for _, key in ipairs({ "website", "discord", "tiktok", "shop" }) do
            local v = payload.links[key]
            if type(v) == "string" and v ~= "" then
                BRANDING.links[key] = v
            end
        end
        if BRANDING.links.website then BRANDING.website = BRANDING.links.website end
        if BRANDING.links.discord then BRANDING.discord = BRANDING.links.discord end
    end
    if type(payload.colors) == "table" and type(payload.colors.primary) == "string" then
        BRANDING.colors = BRANDING.colors or {}
        BRANDING.colors.primary = payload.colors.primary
        BRANDING.colors.secondary = payload.colors.secondary
        BRANDING.colors.primaryLight = payload.colors.primaryLight
        BRANDING.colors.primaryDark = payload.colors.primaryDark
        BRANDING.colors.legacy = payload.colors.legacy or payload.colors.primary
    end

    pcall(SetConvarReplicated, "core_brand_name", BRANDING.name or CFG_NAME)
    if type(BRANDING.name) == "string" and BRANDING.name ~= "" then
        local safe = BRANDING.name:gsub("[\"'`\\]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if safe ~= "" then
            pcall(SetConvar, "sv_hostname", safe)
            pcall(SetConvar, "sv_projectName", safe)
            pcall(ExecuteCommand, ('sv_hostname "%s"'):format(safe))
            pcall(ExecuteCommand, ('sets sv_projectName "%s"'):format(safe))
        end
    end
    pcall(SetConvarReplicated, "core_brand_website", BRANDING.website or CFG_WEBSITE)
    pcall(SetConvarReplicated, "core_discord_invite", BRANDING.discord or CFG_DISCORD)
    if BRANDING.colors then
        pcall(SetConvarReplicated, "core_brand_color_primary", BRANDING.colors.primary or CFG_PRIMARY)
        if BRANDING.colors.primaryLight then pcall(SetConvarReplicated, "core_brand_color_primary_light", BRANDING.colors.primaryLight) end
        if BRANDING.colors.primaryDark then pcall(SetConvarReplicated, "core_brand_color_primary_dark", BRANDING.colors.primaryDark) end
        if BRANDING.colors.legacy then pcall(SetConvarReplicated, "core_brand_color_legacy", BRANDING.colors.legacy) end
        if BRANDING.colors.secondary then pcall(SetConvarReplicated, "core_brand_color_secondary", BRANDING.colors.secondary) end
    end
    pcall(SetConvarReplicated, "core_brand_logo", BRANDING.logo or DEFAULT_LOGO)
    pcall(SetConvarReplicated, "core_brand_notification_logo", payload.notificationLogo or BRANDING.logo or DEFAULT_NOTIF)
    pcall(SetConvarReplicated, "core_brand_vui_banner", BRANDING.vuiBanner or DEFAULT_BANNER)
    if type(payload.loadingScreen) == "string" then
        pcall(SetConvarReplicated, "core_brand_loadingscreen", payload.loadingScreen)
    end
    if type(payload.loadingScreenMusic) == "string" then
        pcall(SetConvarReplicated, "core_brand_loadingscreen_music", payload.loadingScreenMusic)
    end
    if type(payload.loadingSocialTitle) == "string" then
        pcall(SetConvarReplicated, "core_brand_loading_social_title", payload.loadingSocialTitle)
    end
    if type(payload.loadingTicker) == "table" then
        pcall(SetConvarReplicated, "core_brand_loading_ticker", json.encode(payload.loadingTicker))
    end
end

function VFW.Branding.Push(target)
    local payload = VFW.Branding.Build()
    applyLocally(payload)
    TriggerClientEvent("core:branding:apply", target or -1, payload)
    return payload
end

function VFW.Branding.SetManifest(data)
    if type(data) ~= "table" then return false end
    manifest = data
    VFW.Branding.Push(-1)
    return true
end

local function fetchFromBridge()
    local ok, result = pcall(function()
        return exports.eve_bridge:GetBrandingManifest()
    end)
    if ok and type(result) == "table" then return result end
    return nil
end

function VFW.Branding.Fetch(cb)
    local bridge = fetchFromBridge()
    if bridge then
        manifest = bridge
        if cb then cb(true) end
        return
    end

    local url = panelManifestUrl()
    if not url then
        if cb then cb(false) end
        return
    end

    PerformHttpRequest(url, function(status, body)
        if status >= 200 and status < 300 and type(body) == "string" and body ~= "" then
            local ok, decoded = pcall(json.decode, body)
            if ok and type(decoded) == "table" then
                manifest = decoded.branding or decoded.manifest or decoded
                if cb then cb(true) end
                return
            end
        end
        console.warn(("[branding] manifest panel indisponible (%s)"):format(tostring(status)))
        if cb then cb(false) end
    end, "GET", "", {
        ["Accept"] = "application/json",
        ["User-Agent"] = "VFW-Branding/1.0",
    })
end

function VFW.Branding.Refresh()
    VFW.Branding.Fetch(function()
        VFW.Branding.Push(-1)
    end)
end

RegisterNetEvent("core:branding:request", function()
    local source = source
    VFW.Branding.Push(source)
end)

AddEventHandler("core:branding:setManifest", function(data)
    VFW.Branding.SetManifest(data)
end)

VFW.RegisterCommand("refreshbranding", "staff_menu", function(source, xPlayer)
    VFW.Branding.Refresh()
    if xPlayer then
        xPlayer.showNotification({
            type = "STAFF",
            variant = "SUCCESS",
            subtitle = "Branding",
            message = "Manifest branding rafraichi.",
        })
    else
        console.info("Manifest branding rafraichi.")
    end
end, { help = "Recharger le branding depuis le panel", allowConsole = true })

CreateThread(function()
    applyLocally(VFW.Branding.Build())
    Wait(500)
    VFW.Branding.Push(-1)
    Wait(1500)
    VFW.Branding.Fetch(function(ok)
        applyLocally(VFW.Branding.Build())
        VFW.Branding.Push(-1)
        if ok then
            console.init("Branding", ("manifest panel charge (%s)"):format(BRANDING.name))
        else
            console.init("Branding", ("JSON / ConVars (%s)"):format(BRANDING.name))
        end
    end)

    if not panelManifestUrl() then return end

    while true do
        Wait(REFRESH_INTERVAL)
        VFW.Branding.Refresh()
    end
end)
