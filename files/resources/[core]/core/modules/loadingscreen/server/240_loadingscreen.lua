VFW.LoadingScreen = VFW.LoadingScreen or {}

local function buildHandover()
    local panelUrl = GetConvar("eve_panel_url", "")
    local slug = GetConvar("eve_slug", "")

    local payload = {
        name = (VFW.BrandName and VFW.BrandName()) or (BRANDING and BRANDING.name) or "EVE",
        logo = BRANDING and BRANDING.logo or "",
        cdnBase = BRANDING and BRANDING.cdnBase or "",
        colors = BRANDING and BRANDING.colors or {},
        links = BRANDING and BRANDING.links or {},
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
