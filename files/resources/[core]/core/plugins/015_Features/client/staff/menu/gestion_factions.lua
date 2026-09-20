---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["gestion_faction"] == true
end

local function Panel(name)
    local res = TriggerServerCallback("gestionFactions:hubPanel", name)
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les factions." }
    end
    return res
end

local function Fail(cb, result, fallback)
    cb({
        ok = false,
        error = (type(result) == "table" and (result.error or result.message)) or fallback or "Action impossible.",
    })
end

RegisterNuiCallback("gestion:factions:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les factions." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:factions:refresh", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel(data and data.name))
end)

RegisterNuiCallback("gestion:factions:detail", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel(data and data.name))
end)

RegisterNuiCallback("gestion:factions:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local ok = TriggerServerCallback(
        "core:staff:createFaction",
        payload.name, payload.label, payload.devise, payload.logo or payload.image, payload.color, payload.banner
    )
    if not ok then
        cb({ ok = false, error = "Impossible de créer cette faction. Vérifiez l'identifiant et le nom." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Factions", message = "Faction créée." })
    local name = tostring(payload.name or ""):lower():gsub("%s+", "_"):gsub("[^%w_]", "_")
    cb(Panel(name))
end)

RegisterNuiCallback("gestion:factions:updateField", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local ok = TriggerServerCallback("core:gestion-factions:updateField", payload.name, payload.field, payload.value)
    if not ok then
        cb({ ok = false, error = "Mise à jour impossible." })
        return
    end
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:setPosition", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local ok = TriggerServerCallback("core:gestion-factions:setPosition", payload.name, payload.key)
    if not ok then
        cb({ ok = false, error = "Position impossible à enregistrer." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Factions", message = "Position enregistrée." })
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:activate", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local name = data and data.name
    local ok = TriggerServerCallback("core:gestion-factions:activate", name)
    if not ok then
        cb({ ok = false, error = "Activez les 4 positions avant de démarrer la faction." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Factions", message = "Faction activée." })
    cb(Panel(name))
end)

RegisterNuiCallback("gestion:factions:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local name = data and data.name
    TriggerServerCallback("core:gestion-factions:delete", name)
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Factions", message = "Faction supprimée." })
    cb(Panel())
end)

RegisterNuiCallback("gestion:factions:addGrade", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local result = TriggerServerCallback("core:gestion-factions:addGrade", payload.name, payload.gradeName, payload.gradeLabel)
    if type(result) ~= "table" or result.success ~= true then
        Fail(cb, result, "Impossible d'ajouter ce grade.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Factions", message = "Grade ajouté." })
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:moveGrade", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local result = TriggerServerCallback("core:gestion-factions:moveGrade", payload.name, payload.level, payload.direction)
    if type(result) ~= "table" or result.success ~= true then
        Fail(cb, result, "Déplacement impossible.")
        return
    end
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:renameGrade", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local ok = TriggerServerCallback("core:gestion-factions:updateGradeLabel", payload.name, payload.level, payload.label)
    if not ok then
        cb({ ok = false, error = "Renommage impossible." })
        return
    end
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:deleteGrade", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local ok = TriggerServerCallback("core:gestion-factions:deleteGrade", payload.name, payload.level)
    if not ok then
        cb({ ok = false, error = "Suppression du grade impossible." })
        return
    end
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:addMemberById", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local result = TriggerServerCallback("core:gestion-factions:addMemberById", {
        faction = payload.name,
        serverId = payload.serverId,
    })
    if type(result) ~= "table" or result.state ~= true then
        Fail(cb, result, "Joueur non trouvé.")
        return
    end
    VFW.ShowNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Factions",
        message = "Membre ajouté: " .. (result.name or "Inconnu") .. ".",
    })
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:getChars", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("core:gestion-factions:getCharsByGlobalId", data and data.uuid)
    if type(result) ~= "table" or result.state ~= true then
        Fail(cb, result, "Aucun personnage trouvé.")
        return
    end
    cb({ ok = true, chars = result.chars or {} })
end)

RegisterNuiCallback("gestion:factions:addMember", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local result = TriggerServerCallback("core:gestion-factions:addMember", {
        faction = payload.name,
        identifier = payload.identifier,
    })
    if type(result) ~= "table" or result.state ~= true then
        Fail(cb, result, "Ajout impossible.")
        return
    end
    VFW.ShowNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Factions",
        message = "Membre ajouté: " .. (result.name or "Inconnu") .. ".",
    })
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:setMemberGrade", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local ok = TriggerServerCallback("core:gestion-factions:updateMemberGrade", payload.name, payload.identifier, payload.level)
    if not ok then
        cb({ ok = false, error = "Changement de grade impossible." })
        return
    end
    cb(Panel(payload.name))
end)

RegisterNuiCallback("gestion:factions:removeMember", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    TriggerServerCallback("core:gestion-factions:removeMember", payload.name, payload.identifier)
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Factions", message = "Membre retiré." })
    cb(Panel(payload.name))
end)
