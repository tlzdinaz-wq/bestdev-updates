---@meta _
---@diagnostic disable: duplicate-doc-field

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
    local layout = VFW.UiLayout and VFW.UiLayout.Get and VFW.UiLayout.Get() or {
        hud = "vertical",
        menu = "vertical",
        notif = "vertical",
    }
    return {
        ok = true,
        hud = layout.hud,
        menu = layout.menu,
        notif = layout.notif,
    }
end

Staff29.Cb("gestionUiLayout:hubPanel", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    return panel()
end)

Staff29.Cb("gestionUiLayout:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) == "string" then
        local decodedOk, decoded = pcall(json.decode, data)
        data = decodedOk and decoded or nil
    end
    if type(data) ~= "table" then return fail("Données invalides.") end
    if not VFW.UiLayout or not VFW.UiLayout.Set then
        return fail("Orientation indisponible.")
    end
    local ok, err = VFW.UiLayout.Set(data)
    if not ok then return fail(err) end
    local out = panel()
    out.message = "Orientation enregistrée dans ui_layout.json. Tous les joueurs la reçoivent."
    return out
end)

Staff29.Cb("gestionUiLayout:savePositions", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) == "string" then
        local decodedOk, decoded = pcall(json.decode, data)
        data = decodedOk and decoded or nil
    end
    if type(data) ~= "table" then return fail("Données invalides.") end
    if not VFW.UiLayout or not VFW.UiLayout.SetPositions then
        return fail("Positions indisponibles.")
    end
    local ok, err = VFW.UiLayout.SetPositions(data.layout or data)
    if not ok then return fail(err) end
    return { ok = true, message = "Positions enregistrées pour tous les joueurs." }
end)
