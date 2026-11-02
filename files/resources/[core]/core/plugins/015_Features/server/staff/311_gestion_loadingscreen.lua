---@meta _
---@diagnostic disable: duplicate-doc-field

-- Hub Gestion > Serveur > Loading screen (vidéo / image de fond + musique)

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
        or xPlayer.hasPermission("server_management") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { ok = false, error = message or "Action impossible." }
end

local function panel()
    local built = VFW.Branding.Build()
    local ov = VFW.Branding.GetOverrides()
    local links = built.links or {}
    return {
        ok = true,
        name = built.displayName or "",
        colors = built.colors or {},
        logo = built.logo or "",
        loadingScreen = built.loadingScreen or "",
        loadingScreenMusic = built.loadingScreenMusic or "",
        loadingSocialTitle = built.loadingSocialTitle or "",
        loadingTicker = built.loadingTicker or {},
        loadingOptions = built.loadingOptions,
        links = {
            website = links.website or "",
            discord = links.discord or "",
            tiktok = links.tiktok or "",
            shop = links.shop or "",
        },
        overrides = {
            loadingScreen = ov.loadingScreen or "",
            loadingScreenMusic = ov.loadingScreenMusic or "",
            loadingSocialTitle = ov.loadingSocialTitle or "",
            loadingTicker = ov.loadingTicker or {},
            website = ov.website or "",
            discord = ov.discord or "",
            tiktok = ov.tiktok or "",
            shop = ov.shop or "",
        },
        defaults = {
            loadingScreen = GetConvar("core_brand_loadingscreen", ""),
            loadingScreenMusic = GetConvar("core_brand_loadingscreen_music", ""),
        },
    }
end

Staff29.Cb("gestionLoadingScreen:hubPanel", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    return panel()
end)

Staff29.Cb("gestionLoadingScreen:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) == "string" then
        local decodedOk, decoded = pcall(json.decode, data)
        data = decodedOk and decoded or nil
    end
    if type(data) ~= "table" then return fail("Données invalides.") end
    if not VFW.Branding or not VFW.Branding.SetLoadingScreen then
        return fail("Branding indisponible.")
    end
    local ok, err = VFW.Branding.SetLoadingScreen(data)
    if not ok then return fail(err) end
    local out = panel()
    out.message = data.reset and "Loading screen d’origine rétabli." or "Loading screen enregistré dans branding_overrides.json."
    return out
end)

-- Équipe du loading screen : membres du staff du serveur (pseudo + grade et couleur du grade, réglés dans
-- Gestion > Permissions), du plus haut grade au plus bas. Le staff complète ensuite (photos) ou retire des lignes.
Staff29.Cb("gestionLoadingScreen:staffImport", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    local roles = VFW.Variables and VFW.Variables.GetVariable and VFW.Variables.GetVariable("staff_roles") or {}
    if type(roles) ~= "table" then roles = {} end
    local rows = Staff29.Query([[
        SELECT name, role FROM users WHERE role IS NOT NULL AND role <> '' AND role <> 'user' LIMIT 200
    ]], {}) or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local role = type(roles[row.role]) == "table" and roles[row.role] or {}
        out[#out + 1] = {
            name = tostring(row.name or "?"):sub(1, 40),
            grade = (type(role.name) == "string" and role.name ~= "") and role.name or tostring(row.role),
            color = type(role.color) == "string" and role.color or "",
            level = tonumber(role.level) or 0,
        }
    end
    table.sort(out, function(a, b)
        if a.level ~= b.level then return a.level > b.level end
        return a.name:lower() < b.name:lower()
    end)
    for i = 1, #out do out[i].level = nil end
    return { ok = true, staff = out }
end)
