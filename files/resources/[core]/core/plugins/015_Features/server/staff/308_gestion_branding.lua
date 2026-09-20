---@meta _
---@diagnostic disable: duplicate-doc-field

-- Hub Gestion > Serveur > Configuration serveur (nom, liens, couleur de marque)

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
    local defaults = VFW.Branding.Defaults and VFW.Branding.Defaults() or {}
    return {
        ok = true,
        name = built.displayName or "",
        colors = built.colors or {},
        links = built.links or {},
        overrides = {
            displayName = ov.displayName or "",
            website = ov.website or "",
            discord = ov.discord or "",
            hasColor = ov.colors ~= nil,
        },
        defaults = defaults,
    }
end

Staff29.Cb("gestionBranding:hubPanel", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    return panel()
end)

Staff29.Cb("gestionBranding:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) == "string" then
        local decodedOk, decoded = pcall(json.decode, data)
        data = decodedOk and decoded or nil
    end
    if type(data) ~= "table" then return fail("Données invalides.") end
    if not VFW.Branding or not VFW.Branding.SetConfig then
        return fail("Branding indisponible.")
    end
    local ok, err = VFW.Branding.SetConfig(data)
    if not ok then return fail(err) end
    local out = panel()
    out.message = data.reset and "Identité d’origine rétablie." or "Identité enregistrée dans branding_overrides.json."
    return out
end)
