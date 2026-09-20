-- Branding (SaaS) : renvoie les couleurs de marque au NUI VUI.
-- Les ConVars `core_brand_color_*` sont définies par la ressource `core` avec
-- `setr` (répliquées), donc lisibles ici sans dépendance directe à `core`.
-- Défauts = charte EVE (#7263EE) -> aucun changement si non configuré.
RegisterNUICallback('vui:getBranding', function(_, cb)
    local name = GetConvar("core_brand_name", "EVE")
    cb({
        primary      = GetConvar("core_brand_color_primary", "#7263EE"),
        primaryLight = GetConvar("core_brand_color_primary_light", "#3db5ff"),
        primaryDark  = GetConvar("core_brand_color_primary_dark", "#1478c7"),
        name         = name,
        staffTitle   = name .. " Staff",
    })
end)

-- Mise à jour live des couleurs + nom de marque. `core` (branding_nui.lua)
-- déclenche cet event local ; on relaie au NUI VUI (accents CSS + titre overlay).
AddEventHandler('core:vui:setBranding', function(payload)
    if type(payload) ~= 'table' then return end
    SendNUIMessage({ action = 'vui:setBranding', data = payload })
end)

-- Déclenché quand l'utilisateur clique sur un item (Entrée ou clic souris).
-- Gère : checkbox, list, list2, slider, callback standard, et navigation submenu.
RegisterNUICallback('vui:menu:click', function(data, cb)
    cb()
    if not VUI_CurrentMenu then return end

    local item

    if VUI_CurrentMenu.isFiltered() then
        item = VUI_CurrentMenu.filterItems[data.index + 1]
    elseif VUI_CurrentMenu.visibleItems and #VUI_CurrentMenu.visibleItems > 0 then
        item = VUI_CurrentMenu.visibleItems[data.index + 1]
    else
        item = VUI_CurrentMenu.items[data.index + 1]
    end

    if not item then return end
    if item.type == "list2" then
        item.props.index = data.item.props.index + 1
        if item.onEnter then
            item.onEnter(item.props.index, item.props.items[item.props.index])
        end
        return
    elseif item.callback then
        if item.type == "checkbox" then
            item.props.checked = data.item.props.checked
            item.callback(item.props.checked)
            return
        elseif item.type == "list" then
            item.props.index = (data.item.props.index or 0) + 1
            item.callback(item.props.index, item.props.items[item.props.index])
            return
        elseif item.type == "slider" then
            item.props.value = data.item.props.value
            item.callback(item.props.value)
            return
        end

        if item.callback() == false then
            return
        end
    end

    if item.submenu then
        table.insert(VUI_MenuStack, { menu = VUI_CurrentMenu, savedIndex = VUI_CurrentMenu.index })
        VUI_CurrentMenu._closeInternal()
        VUI_CurrentMenu = item.submenu
        VUI_CurrentMenu.open()
    end
end)

-- Déclenché quand l'utilisateur utilise ◀▶ sur un item List2.
RegisterNUICallback('vui:menu:list2Change', function(data, cb)
    if not VUI_CurrentMenu then return end

    local item
    if VUI_CurrentMenu.isFiltered() then
        item = VUI_CurrentMenu.filterItems[data.index + 1]
    elseif VUI_CurrentMenu.visibleItems and #VUI_CurrentMenu.visibleItems > 0 then
        item = VUI_CurrentMenu.visibleItems[data.index + 1]
    else
        item = VUI_CurrentMenu.items[data.index + 1]
    end

    if item and item.type == "list2" and item.callback then
        item.props.index = data.item.props.index + 1
        item.callback(item.props.index, item.props.items[item.props.index])
    end

    cb()
end)

-- Déclenché quand le curseur change de position (↑↓).
-- Met à jour VUI_CurrentMenu.index et appelle OnIndexChange si défini.
RegisterNUICallback('vui:menu:indexChange', function(data, cb)
    if not VUI_CurrentMenu then return end
    if VUI_SoundEnabled == true then
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
    VUI_CurrentMenu.index = data.index + 1
    if VUI_CurrentMenu._idxChangeFn then
        local item
        if VUI_CurrentMenu.isFiltered() then
            item = VUI_CurrentMenu.filterItems[VUI_CurrentMenu.index]
        elseif VUI_CurrentMenu.visibleItems and #VUI_CurrentMenu.visibleItems > 0 then
            item = VUI_CurrentMenu.visibleItems[VUI_CurrentMenu.index]
        else
            item = VUI_CurrentMenu.items[VUI_CurrentMenu.index]
        end
        VUI_CurrentMenu._idxChangeFn(VUI_CurrentMenu.index, item)
    end
    cb()
end)

local focusState = false
-- Déclenché quand le NUI demande ou libère le focus clavier (ex: SearchInput actif).
RegisterNUICallback('vui:menu:focus', function(data, cb)
    if not VUI_CurrentMenu then return end
    if VUI_HubMode then
        cb()
        return
    end
    focusState = data.focus
    if focusState then
        SetNuiFocus(true, false)
    else
        SetNuiFocus(false, false)
    end
    cb()
end)

-- Déclenché quand l'utilisateur clique sur le bouton retour dans le NUI.
RegisterNUICallback('vui:menu:back', function(data, cb)
    VUI_HandleBack()
    cb()
end)

-- Déclenché par le SearchInput : reçoit la liste des items filtrés depuis le NUI
-- et reconstruit VUI_CurrentMenu.filterItems côté Lua pour synchronisation.
RegisterNUICallback("vui:menu:filteritems", function(data, cb)
    if VUI_CurrentMenu then
        VUI_CurrentMenu._isFiltered = true
        VUI_CurrentMenu.index = 1
        VUI_CurrentMenu.filterItems = {}
        -- Build a lookup set O(1) instead of nested O(n*m) loop
        local matchSet = {}
        for _, _item in ipairs(data.items) do
            local key = (_item.type or "") .. "|" .. (_item.props.title or "") .. "|" .. (_item.props.subtitle or "")
            matchSet[key] = true
        end
        for _, item in ipairs(VUI_CurrentMenu.items) do
            local key = (item.type or "") .. "|" .. (item.props.title or "") .. "|" .. (item.props.subtitle or "")
            if matchSet[key] then
                table.insert(VUI_CurrentMenu.filterItems, item)
            end
        end
    end
    cb()
end)

-- Déclenché quand le SearchInput est vidé : retire le filtre côté Lua.
RegisterNUICallback("vui:menu:unfilteritems", function(data, cb)
    if VUI_CurrentMenu then
        VUI_CurrentMenu._isFiltered = false
        VUI_CurrentMenu.filterItems = {}
    end
    cb()
end)

-- Color Picker callback for real-time color updates
RegisterNUICallback('vui:menu:colorPickerChange', function(data, cb)
    if VUI_ColorPickerCallbacks then
        local callback = VUI_ColorPickerCallbacks[data.type]
        if callback then
            callback(data.r, data.g, data.b)
        end
    end
    cb()
end)

-- Color Picker validation (Enter key) - closes picker and releases focus
RegisterNUICallback('vui:menu:colorPickerValidate', function(data, cb)
    if VUI_CurrentMenu and VUI_CurrentMenu.CloseColorPicker then
        VUI_CurrentMenu.CloseColorPicker()
    else
        -- Fallback: release NUI focus directly
        SendNUIMessage({ action = "vui:menu:closeColorPicker" })
        if not VUI_HubMode then
            SetNuiFocus(true, false)
        end
        VUI_ColorPickerCallbacks = nil
    end
    cb()
end)

-- Role Color Picker callback for real-time color updates (preview)
RegisterNUICallback('vui:menu:roleColorPickerChange', function(data, cb)
    if VUI_RoleColorPickerCallbacks then
        VUI_RoleColorPickerCallbacks.lastColor = { r = data.r, g = data.g, b = data.b }
        if VUI_RoleColorPickerCallbacks.onChange then
            VUI_RoleColorPickerCallbacks.onChange(data.r, data.g, data.b)
        end
    end
    cb()
end)

-- Role Color Picker validation (Enter key) - validates and closes picker
RegisterNUICallback('vui:menu:roleColorPickerValidate', function(data, cb)
    if VUI_RoleColorPickerCallbacks and VUI_RoleColorPickerCallbacks.onValidate then
        VUI_RoleColorPickerCallbacks.onValidate(data.r, data.g, data.b)
    end
    if VUI_CurrentMenu and VUI_CurrentMenu.CloseRoleColorPicker then
        VUI_CurrentMenu.CloseRoleColorPicker()
    else
        -- Fallback: release NUI focus directly
        SendNUIMessage({ action = "vui:menu:closeRoleColorPicker" })
        if not VUI_HubMode then
            SetNuiFocus(false, false)
        end
        VUI_RoleColorPickerCallbacks = nil
    end
    cb()
end)

-- Role Color Picker cancel (Escape key) - restores original color and closes picker
RegisterNUICallback('vui:menu:roleColorPickerCancel', function(data, cb)
    if VUI_RoleColorPickerCallbacks and VUI_RoleColorPickerCallbacks.onCancel then
        VUI_RoleColorPickerCallbacks.onCancel()
    end
    if VUI_CurrentMenu and VUI_CurrentMenu.CloseRoleColorPicker then
        VUI_CurrentMenu.CloseRoleColorPicker()
    else
        SendNUIMessage({ action = "vui:menu:closeRoleColorPicker" })
        if not VUI_HubMode then
            SetNuiFocus(false, false)
        end
        VUI_RoleColorPickerCallbacks = nil
    end
    cb()
end)
