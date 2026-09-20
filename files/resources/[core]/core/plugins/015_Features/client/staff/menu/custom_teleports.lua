---@meta _
---@diagnostic disable: duplicate-doc-field

local KVP_KEY = "staff_custom_teleports"
local KVP_PRESETS_KEY = "staff_preset_teleports_disabled"
local selectedTeleportIndex = nil

-- Lieux prédéfinis partagés
local PRESET_LOCATIONS = {
    { label = "Place des Cubes",  x = 223.38, y = -861.43,  z = 29.12 },
    { label = "Parking Central",  x = -349.26, y = -875.02,  z = 30.32 },
    { label = "Hôpital LS",       x = 297.58,  y = -584.87,  z = 43.26 },
    { label = "Hôpital Paleto",   x = -248.49, y = 6331.64,  z = 32.43 },
}

local function GetCustomTeleports()
    local data = GetResourceKvpString(KVP_KEY)
    if not data or data == "" then return {} end
    return json.decode(data) or {}
end

local function SaveCustomTeleports(teleports)
    SetResourceKvp(KVP_KEY, json.encode(teleports))
end

local function GetDisabledPresets()
    local data = GetResourceKvpString(KVP_PRESETS_KEY)
    if not data or data == "" then return {} end
    return json.decode(data) or {}
end

local function SaveDisabledPresets(disabled)
    SetResourceKvp(KVP_PRESETS_KEY, json.encode(disabled))
end

function StaffMenu.IsPresetEnabled(label)
    local disabled = GetDisabledPresets()
    for _, v in ipairs(disabled) do
        if v == label then return false end
    end
    return true
end

function StaffMenu.GetPresetLocations()
    return PRESET_LOCATIONS
end

-- ===== MENU PRINCIPAL =====
StaffMenu.customTeleports.OnOpen(function()
    local banner = StaffMenu.menuContext == 'animator' and exports["core"]:GetVUIBanner("animator") or exports["core"]:GetVUIBanner("admin")
    StaffMenu.customTeleports.ChangeBanner(banner)
    StaffMenu.customTeleports.ClearItems()
    StaffMenu.customTeleports.Separator(":pin: MES TÉLÉPORTATIONS CUSTOM")

    -- Sauvegarder position actuelle
    StaffMenu.customTeleports.Button(":plus: SAUVEGARDER POSITION ACTUELLE", "Enregistrer votre position actuelle comme point de téléportation", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom du point", "")
        if not name or name == "" then return end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local teleports = GetCustomTeleports()
        table.insert(teleports, {
            name = name,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            heading = heading,
        })
        SaveCustomTeleports(teleports)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléports Custom',
            message = 'Point "' .. name .. '" sauvegardé.'
        })

        StaffMenu.customTeleports.refresh()
    end)

    -- Points custom sauvegardés
    local teleports = GetCustomTeleports()

    if #teleports == 0 then
        StaffMenu.customTeleports.Separator("Aucun point sauvegardé")
    else
        StaffMenu.customTeleports.Separator(#teleports .. (#teleports > 1 and " POINTS SAUVEGARDÉS" or " POINT SAUVEGARDÉ"))

        for i, tp in ipairs(teleports) do
            local subtitle = string.format("X: %.2f  Y: %.2f  Z: %.2f", tp.coords.x, tp.coords.y, tp.coords.z)
            StaffMenu.customTeleports.Button(":globe: " .. tp.name, subtitle, nil, "chevron", false, function()
                selectedTeleportIndex = i
            end, StaffMenu.customTeleportOptions)
        end
    end

    -- Lieux prédéfinis (activation/désactivation)
    StaffMenu.customTeleports.Separator(":pin: LIEUX PRÉDÉFINIS")

    local disabled = GetDisabledPresets()
    local disabledSet = {}
    for _, v in ipairs(disabled) do disabledSet[v] = true end

    for _, loc in ipairs(PRESET_LOCATIONS) do
        local isEnabled = not disabledSet[loc.label]
        StaffMenu.customTeleports.Checkbox(":pin: " .. loc.label, nil, false, isEnabled, function(checked)
            local updated = GetDisabledPresets()
            if checked then
                -- Retirer de la liste disabled
                for j = #updated, 1, -1 do
                    if updated[j] == loc.label then
                        table.remove(updated, j)
                    end
                end
            else
                -- Ajouter à la liste disabled
                table.insert(updated, loc.label)
            end
            SaveDisabledPresets(updated)
        end)
    end
end)

-- ===== SOUS-MENU OPTIONS DU POINT =====
StaffMenu.customTeleportOptions.OnOpen(function()
    local banner = StaffMenu.menuContext == 'animator' and exports["core"]:GetVUIBanner("animator") or exports["core"]:GetVUIBanner("admin")
    StaffMenu.customTeleportOptions.ChangeBanner(banner)
    StaffMenu.customTeleportOptions.ClearItems()

    local teleports = GetCustomTeleports()
    local i = selectedTeleportIndex
    if not i or not teleports[i] then return end
    local tp = teleports[i]

    StaffMenu.customTeleportOptions.Separator(":pin: " .. tp.name)

    -- Téléporter
    StaffMenu.customTeleportOptions.Button(":rocket: SE TÉLÉPORTER", string.format("X: %.2f  Y: %.2f  Z: %.2f", tp.coords.x, tp.coords.y, tp.coords.z), nil, nil, false, function()
        StaffTeleportToCoords(tp.coords.x, tp.coords.y, tp.coords.z, tp.heading)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléports Custom',
            message = "Téléporté à : " .. tp.name
        })
    end)

    -- Renommer
    StaffMenu.customTeleportOptions.Button(":edit: RENOMMER", "Modifier le nom de ce point de téléportation", nil, nil, false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nouveau nom", "")
        if not newName or newName == "" then return end

        local updated = GetCustomTeleports()
        if not updated[i] then return end
        updated[i].name = newName
        SaveCustomTeleports(updated)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléports Custom',
            message = 'Point renommé en "' .. newName .. '".'
        })

        StaffMenu.customTeleportOptions.refresh()
    end)

    -- Supprimer
    StaffMenu.customTeleportOptions.Button(":trash: SUPPRIMER", "Supprimer définitivement ce point de téléportation", nil, nil, false, function()
        local updated = GetCustomTeleports()
        local name = updated[i] and updated[i].name or "?"
      table.remove(updated, i)
        SaveCustomTeleports(updated)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Téléports Custom',
            message = 'Point "' .. name .. '" supprimé.'
        })

        selectedTeleportIndex = nil
        exports.VUI:HandleBack()
    end)
end)

-- ===== INJECTION DANS LE MENU TÉLÉPORTATION =====
function StaffMenu.BuildCustomTeleportLocations()
    -- Lieux prédéfinis activés
    local anyPreset = false
    for _, loc in ipairs(PRESET_LOCATIONS) do
        if StaffMenu.IsPresetEnabled(loc.label) then
            if not anyPreset then
                StaffMenu.personalTeleport.Separator(":pin: LIEUX PRÉDÉFINIS")
                anyPreset = true
            end
            StaffMenu.personalTeleport.Button(":pin: " .. loc.label, nil, nil, "arrow", false, function()
                SetEntityCoords(PlayerPedId(), loc.x, loc.y, loc.z, false, false, false, false)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléportation', message = "Téléporté à " .. loc.label .. "." })
            end)
        end
    end

    -- Points custom
    local teleports = GetCustomTeleports()
    if #teleports == 0 then return end

    StaffMenu.personalTeleport.Separator(":pin: MES POINTS CUSTOM")

    for _, tp in ipairs(teleports) do
        StaffMenu.personalTeleport.Button(":globe: " .. tp.name, string.format("X: %.2f  Y: %.2f  Z: %.2f", tp.coords.x, tp.coords.y, tp.coords.z), nil, "arrow", false, function()
            StaffTeleportToCoords(tp.coords.x, tp.coords.y, tp.coords.z, tp.heading)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléportation',
                message = "Téléporté à : " .. tp.name
            })
        end)
    end

    StaffMenu.personalTeleport.Separator(nil)
    StaffMenu.personalTeleport.Button(":trash: GÉRER MES POINTS", "Renommer ou supprimer vos points de téléportation custom", nil, "chevron", false, function()
    end, StaffMenu.customTeleports)
end
