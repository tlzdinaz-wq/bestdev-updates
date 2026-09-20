---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["dev"] == true or perms["gestion_items"] == true or perms["staff"] == true or perms["server_management"] == true
end

local function Panel(tab)
    local res = TriggerServerCallback("gestionImages:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les images." }
    end
    res.tab = tab or res.tab or "marque"
    if StaffMenu.GetImageVehicleLists then
        local vehicles, vanillaVehicles, addonVehicles = StaffMenu.GetImageVehicleLists()
        res.vehicles = vehicles or {}
        res.vanillaVehicles = vanillaVehicles or {}
        res.addonVehicles = addonVehicles or {}
    else
        res.vehicles = res.vehicles or {}
        res.vanillaVehicles = res.vanillaVehicles or {}
        res.addonVehicles = res.addonVehicles or {}
    end
    res.outfits = res.outfits or {}
    return res
end

local function Fail(cb, result, fallback)
    cb({
        ok = false,
        error = (type(result) == "table" and (result.error or result.message)) or fallback or "Action impossible.",
    })
end

local function runImagesNui(cb, fn)
    CreateThread(function()
        local res = fn()
        if type(res) ~= "table" then
            cb({ ok = false, error = "Réponse invalide." })
            return
        end
        cb(res)
    end)
end

RegisterNuiCallback("gestion:images:open", function(data, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les images." })
        return
    end
    runImagesNui(cb, function()
        return Panel(data and data.tab)
    end)
end)

RegisterNuiCallback("gestion:images:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    runImagesNui(cb, Panel)
end)

RegisterNuiCallback("gestion:images:save", function(data, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les images." })
        return
    end
    runImagesNui(cb, function()
        local result = TriggerServerCallback("gestionImages:save", data)
        if type(result) ~= "table" or result.ok ~= true then
            return {
                ok = false,
                error = (type(result) == "table" and (result.error or result.message)) or "Enregistrement impossible.",
            }
        end
        return result
    end)
end)

RegisterNuiCallback("gestion:images:outfits", function(_, cb)
    if not Guard() then cb({ ok = false, outfits = {} }) return end
    if not VFW.Staff_BuildOutfitsList then
        cb({ ok = true, outfits = {} })
        return
    end
    local manifest = TriggerServerCallback("vfw:server:getOutfitsManifest") or {}
    local outfits = VFW.Staff_BuildOutfitsList(manifest) or {}
    cb({ ok = true, outfits = outfits })
end)

RegisterNuiCallback("gestion:images:redoMugshots", function(data, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les images." })
        return
    end
    if not StaffMenu.RedoMugshotsForChars then
        cb({ ok = false, error = "Capture mugshot indisponible." })
        return
    end
    local raw = data and data.charIds
    local ids = {}
    if type(raw) == "table" then
        for i = 1, #raw do
            local id = tonumber(raw[i])
            if id then ids[#ids + 1] = id end
        end
    elseif tonumber(data and data.charId) then
        ids[1] = tonumber(data.charId)
    end
    if #ids == 0 then
        cb({ ok = false, error = "Aucun personnage sélectionné." })
        return
    end
    local ok = StaffMenu.RedoMugshotsForChars(ids)
    if not ok then
        cb({ ok = false, error = "Une capture est déjà en cours." })
        return
    end
    cb({ ok = true })
end)
