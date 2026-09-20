---@meta _
---@diagnostic disable: duplicate-doc-field

-- Hub Gestion > Serveur > Loading screen

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["server_management"] == true
        or perms["dev"] == true
        or perms["staff"] == true
        or perms["admin"] == true
end

RegisterNuiCallback("gestion:loadingscreen:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de configurer le loading screen." })
        return
    end
    local res = TriggerServerCallback("gestionLoadingScreen:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        cb({ ok = false, error = (type(res) == "table" and res.error) or "Impossible de charger la configuration." })
        return
    end
    cb(res)
end)

RegisterNuiCallback("gestion:loadingscreen:save", function(data, cb)
    if not Guard() then cb({ ok = false, error = "Permission refusée." }) return end
    if type(data) == "string" then
        local ok, decoded = pcall(json.decode, data)
        data = ok and decoded or nil
    end
    local res = TriggerServerCallback("gestionLoadingScreen:save", data)
    if type(res) ~= "table" or res.ok ~= true then
        cb({
            ok = false,
            error = (type(res) == "table" and (res.error or res.message)) or "Enregistrement impossible.",
        })
        return
    end
    cb(res)
end)
