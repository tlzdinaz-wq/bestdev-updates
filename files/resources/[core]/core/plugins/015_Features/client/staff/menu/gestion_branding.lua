---@meta _
---@diagnostic disable: duplicate-doc-field

local function HasManagementPermission()
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["server_management"] == true
        or perms["dev"] == true
        or perms["staff"] == true
        or perms["admin"] == true
end

local function Guard()
    return StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() and HasManagementPermission()
end

RegisterNuiCallback("gestion:branding:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de configurer le serveur." })
        return
    end
    local res = TriggerServerCallback("gestionBranding:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        cb({ ok = false, error = (type(res) == "table" and res.error) or "Impossible de charger la configuration." })
        return
    end
    cb(res)
end)

RegisterNuiCallback("gestion:branding:save", function(data, cb)
    -- The UI flushes its pending autosave while closing. The hub can already
    -- be closed here; permission checks remain enforced client- and server-side.
    if not HasManagementPermission() then cb({ ok = false, error = "Permission refusée." }) return end
    if type(data) == "string" then
        local ok, decoded = pcall(json.decode, data)
        data = ok and decoded or nil
    end
    local res = TriggerServerCallback("gestionBranding:save", data)
    if type(res) ~= "table" or res.ok ~= true then
        cb({
            ok = false,
            error = (type(res) == "table" and (res.error or res.message)) or "Enregistrement impossible.",
        })
        return
    end
    cb(res)
end)
