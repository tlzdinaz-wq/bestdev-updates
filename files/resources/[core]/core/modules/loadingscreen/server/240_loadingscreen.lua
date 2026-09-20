VFW.LoadingScreen = VFW.LoadingScreen or {}

local function buildHandover()
    local panelUrl = GetConvar("eve_panel_url", "")
    local slug = GetConvar("eve_slug", "")
    local built = (VFW.Branding and VFW.Branding.Build) and VFW.Branding.Build() or {}

    local payload = {
        name = built.displayName or (VFW.BrandName and VFW.BrandName()) or (BRANDING and BRANDING.name) or "EVE",
        logo = built.logo or (BRANDING and BRANDING.logo) or "",
        cdnBase = BRANDING and BRANDING.cdnBase or "",
        colors = built.colors or (BRANDING and BRANDING.colors) or {},
        links = built.links or (BRANDING and BRANDING.links) or {},
        loadingScreen = built.loadingScreen or "",
        loadingScreenMusic = built.loadingScreenMusic or "",
        loadingSocialTitle = built.loadingSocialTitle or "",
        loadingTicker = built.loadingTicker or {},
        mentaServer = MENTA_SERVER,
    }

    if panelUrl ~= "" and slug ~= "" then
        payload.panelUrl = panelUrl
        payload.slug = slug
        payload.manifestUrl = panelUrl:gsub("/+$", "") .. "/api/branding/" .. slug
    end

    return payload
end

function VFW.LoadingScreen.GetHandoverData()
    return buildHandover()
end
