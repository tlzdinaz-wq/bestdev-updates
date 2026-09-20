---@meta _
---@diagnostic disable: duplicate-doc-field

local categoryLabels = {
    server = "Serveur",
    commands = "Commandes",
    vehicle = "Véhicule",
    player = "Joueur",
    gestion = "Gestion",
}

local permissionsData = {
    roles = {},
    discordRoles = {},
    selectedRole = nil,
    selectedPlayer = nil,
    allPermissions = Config.Permissions or {},
    categories = {},
    searchText = "",
    roleSearchText = "",
    permSearchText = "",
    showUnowned = false
}

-- Vérifie si le joueur est niveau_6 (bypass toutes les restrictions)
local function IsPlayerDev()
    local role = VFW.PlayerGlobalData and (VFW.PlayerGlobalData.role or VFW.PlayerGlobalData.roleId)
    return role == "niveau_6"
end

-- Vérifie si le joueur possède une permission (ou est dev)
local function PlayerCanGrantPerm(permName)
    if IsPlayerDev() then return true end
    return VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions[permName]
end

-- Organize permissions by category
local function OrganizePermissions()
    permissionsData.categories = {}
    for permName, permData in pairs(permissionsData.allPermissions) do
        local category = permData.category or "other"
      if not permissionsData.categories[category] then
            permissionsData.categories[category] = {}
        end
        table.insert(permissionsData.categories[category], {
            name = permName,
            label = permData.label,
            type = permData.type
        })
    end
end

-- Load roles from server
local function LoadRoles(preserveSelection)
    local currentSelectionId = nil
    if preserveSelection and permissionsData.selectedRole then
        currentSelectionId = permissionsData.selectedRole.id
    end
    
    -- Clear existing data
    permissionsData.roles = {}
    permissionsData.selectedRole = nil
    
    local roles, discordList = TriggerServerCallback("vfw:staff:getRoles")
    if not roles then
        return
    end
    
    permissionsData.discordRoles = discordList or {}
    
    -- Debug: print loaded roles
    local roleCount = 0
    for roleId, roleData in pairs(roles) do
        roleCount = roleCount + 1
        local roleName = roleData.name or roleId  -- Use the name from database, fallback to roleId
        local roleColor = roleData.color or "#FFFFFF" -- Use database color, default to white

        table.insert(permissionsData.roles, {
            id = roleId,
            name = roleName,
            level = roleData.level or 1,
            permissions = roleData.permissions or {},
            color = roleColor  -- Store color as string (hex format)
        })
    end

    -- Sort roles by level
    table.sort(permissionsData.roles, function(a, b)
        return a.level > b.level
    end)
    
    -- Restore selection if needed and role still exists
    if currentSelectionId then
        for _, role in ipairs(permissionsData.roles) do
            if role.id == currentSelectionId then
                permissionsData.selectedRole = role
                break
            end
        end
        -- If role was deleted, selectedRole remains nil
        -- selectedRole may have been deleted; remains nil
    end
end

-- Build main permissions menu
function StaffMenu.BuildPermissionsMenu()
    if not StaffMenu.permissions then return end
    
    -- Initialize permissions data
    OrganizePermissions()
    LoadRoles()

    StaffMenu.permissions.Button("CRÉER UN NOUVEAU RÔLE", "Créer un nouveau rôle avec ses permissions", nil, "chevron", false, function()
        local roleName = VFW.Nui.KeyboardInput(true, "Nom du rôle", "")
        if not roleName or roleName == "" then return end

        local roleLevel = VFW.Nui.KeyboardInput(true, "Niveau du rôle (0-100)", "1")
        roleLevel = tonumber(roleLevel)
        if not roleLevel then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Permissions', message = "Ce niveau n'est pas valide." })
            return
        end
        roleLevel = math.min(100, math.max(0, roleLevel))

        local success, newRoleId = TriggerServerCallback("vfw:staff:createRole", roleName, roleLevel)

        if success then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
                message = "Rôle créé: " .. roleName .. "."
          })

            Wait(100)
            LoadRoles()

            for _, role in ipairs(permissionsData.roles) do
                if role.id == newRoleId then
                    permissionsData.selectedRole = role
                    permissionsData.showUnowned = false
                    permissionsData.permSearchText = ""
                  break
                end
            end

            StaffMenu.permissions.close()
            Wait(100)
            StaffMenu.editRole.toggle()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Permissions',
                message = (newRoleId or "Erreur lors de la création du rôle") .. "."
          })
        end
    end)

    StaffMenu.permissions.Separator(nil)
    
    StaffMenu.permissions.Button("RAFRAÎCHIR LES DONNÉES", "Recharger tous les rôles et permissions depuis la base de données", nil, "chevron", false, function()
        -- Force server to reload roles from database first
        local success = TriggerServerCallback("vfw:staff:reloadRoles")
        if success then
            -- Now load the refreshed data
            LoadRoles()

            -- Refresh the menu to show updated roles
            StaffMenu.permissions.refresh()

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
                message = "Données rafraîchies depuis la base de données."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Permissions',
                message = "Erreur lors du rafraîchissement."
          })
        end
    end)
    
    StaffMenu.permissions.Button("SAUVEGARDER LES MODIFICATIONS", "Enregistrer toutes les modifications de permissions en base de données", nil, "chevron", false, function()
        local rolesToSave = {}
        for _, role in ipairs(permissionsData.roles) do
            table.insert(rolesToSave, {
                id = role.id,
                power = role.level,
                permissions = table.keys(role.permissions),
                color = role.color
            })
        end
        TriggerServerEvent("vfw:staff:saveRole", rolesToSave)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
            message = "Modifications sauvegardées."
      })
        -- Reload after save to sync with server
        Wait(200)
        LoadRoles()
    end)
    
    -- Display current roles
    StaffMenu.permissions.Separator("RÔLES ACTUELS")

    -- Search functionality for roles
    StaffMenu.permissions.Button(":search: RECHERCHER UN RÔLE", permissionsData.roleSearchText ~= "" and ("Recherche: " .. permissionsData.roleSearchText) or nil, nil, "chevron", false, function()
        local search = VFW.Nui.KeyboardInput(true, "Rechercher un rôle", permissionsData.roleSearchText)
        if search then
            permissionsData.roleSearchText = search
            StaffMenu.permissions.refresh()
        end
    end)

    if permissionsData.roleSearchText ~= "" then
        StaffMenu.permissions.Button(":x: EFFACER LA RECHERCHE", nil, nil, "chevron", false, function()
            permissionsData.roleSearchText = ""
          StaffMenu.permissions.refresh()
        end)
    end

    -- Filter roles based on search
    local displayRoles = {}
    if permissionsData.roleSearchText ~= "" then
        local searchLower = string.lower(permissionsData.roleSearchText)
        for _, role in ipairs(permissionsData.roles) do
            if string.find(string.lower(role.name), searchLower, 1, true) or
               string.find(string.lower(role.id), searchLower, 1, true) then
                table.insert(displayRoles, role)
            end
        end
    else
        displayRoles = permissionsData.roles
    end

    if #displayRoles > 0 then
        if permissionsData.roleSearchText ~= "" then
            StaffMenu.permissions.Separator(string.format(#displayRoles > 1 and "%d résultats trouvés" or "%d résultat trouvé", #displayRoles))
        end

        for _, role in ipairs(displayRoles) do
            local permCount = 0
            for _ in pairs(role.permissions) do
                permCount = permCount + 1
            end

            StaffMenu.permissions.Button(
                ":lock: " .. role.name,
                string.format("Niveau: %d | %d permissions", role.level, permCount),
                nil,
                "chevron",
                false,
                function()
                    permissionsData.selectedRole = role
                    permissionsData.showUnowned = false
                    permissionsData.permSearchText = ""
                  StaffMenu.permissions.close()
                    StaffMenu.editRole.toggle()
                end
            )
        end
    else
        if permissionsData.roleSearchText ~= "" then
            StaffMenu.permissions.Separator("Aucun rôle trouvé")
        else
            StaffMenu.permissions.Separator("Aucun rôle trouvé")
        end
    end
end

-- Build edit role menu
function StaffMenu.BuildEditRoleMenu()
    if not permissionsData.selectedRole then
        StaffMenu.editRole.Separator("Aucun rôle sélectionné")
        return
    end
    
    StaffMenu.editRole.Separator("ÉDITION: " .. permissionsData.selectedRole.name)
    
    StaffMenu.editRole.Button("NIVEAU DU RÔLE", "Actuel : " .. permissionsData.selectedRole.level, nil, "chevron", false, function()
        local newLevel = VFW.Nui.KeyboardInput(true, "Nouveau niveau (1-100)", tostring(permissionsData.selectedRole.level))
        if newLevel and tonumber(newLevel) then
            local level = math.min(100, math.max(1, tonumber(newLevel)))
            permissionsData.selectedRole.level = level
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
                message = "Niveau modifié : " .. level .. "."
          })
        end
    end)

    -- Color selector for role
    local currentColorDisplay = "Non défini"
  if permissionsData.selectedRole.color then
        local color = permissionsData.selectedRole.color
        -- Check if color is already a hex string
        if type(color) == "string" and color:match("^#%x%x%x%x%x%x$") then
            -- Convert hex to RGB for display
            local hex = color:gsub("#", "")
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            currentColorDisplay = string.format("RGB(%d, %d, %d)", r, g, b)
        elseif type(color) == "number" then
            -- Handle legacy number format
            local r = (color >> 16) & 0xFF
            local g = (color >> 8) & 0xFF
            local b = color & 0xFF
            currentColorDisplay = string.format("RGB(%d, %d, %d)", r, g, b)
        end
    end

    StaffMenu.editRole.Button("COULEUR DU RÔLE", currentColorDisplay, nil, "chevron", false, function()
        local currentHexColor = permissionsData.selectedRole.color or "#FFFFFF"
      -- Parse hex to RGB
        local hex = currentHexColor:gsub("#", "")
        local r = tonumber(hex:sub(1, 2), 16) or 255
        local g = tonumber(hex:sub(3, 4), 16) or 255
        local b = tonumber(hex:sub(5, 6), 16) or 255
        local previewPlayerId = GetPlayerServerId(PlayerId())  -- Preview on self

        StaffMenu.editRole.RoleColorPicker(r, g, b, "COULEUR DU ROLE",
            -- onChange: preview local (only if gamertags are active)
            function(newR, newG, newB)
                if VFW.IsGamerTagsActive() then
                    local previewHex = string.format("#%02X%02X%02X", newR, newG, newB)
                    VFW.PreviewGamerTagColor(previewPlayerId, previewHex)
                end
            end,
            -- onValidate: save the color
            function(finalR, finalG, finalB)
                permissionsData.selectedRole.color = string.format("#%02X%02X%02X", finalR, finalG, finalB)
                VFW.ClearGamerTagPreview()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
                    message = string.format("Couleur modifiée: RGB(%d,%d,%d).", finalR, finalG, finalB)
                })
                StaffMenu.editRole.refresh()
            end,
            -- onCancel: restore original
            function()
                VFW.ClearGamerTagPreview()
            end
        )
    end)
    
    StaffMenu.editRole.Button("SAUVEGARDER LES MODIFICATIONS", "Enregistrer les modifications de ce rôle et synchroniser avec le serveur", nil, "chevron", false, function()
        -- Save the current role's permissions
        local rolesToSave = {{
            id = permissionsData.selectedRole.id,
            power = permissionsData.selectedRole.level,
            permissions = table.keys(permissionsData.selectedRole.permissions),
            color = permissionsData.selectedRole.color
        }}
        TriggerServerEvent("vfw:staff:saveRole", rolesToSave)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
            message = "Modifications sauvegardées pour " .. permissionsData.selectedRole.name .. "."
      })
        -- Wait for server to save before reloading
        Wait(200)
        -- Reload roles to ensure sync with server
        LoadRoles(true) -- true to preserve selection
        -- Refresh menu to display updated colors
        StaffMenu.editRole.refresh()
    end)
    
    StaffMenu.editRole.Button("SUPPRIMER CE RÔLE", "Supprimer définitivement ce rôle et retirer ses permissions à tous les membres", nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer ce rôle", "")
        if confirm == "CONFIRMER" then
            local roleToDelete = permissionsData.selectedRole.id
            local roleName = permissionsData.selectedRole.name
            
            -- Send delete request to server
            TriggerServerEvent("vfw:staff:deleteRole", roleToDelete)
            
            -- Wait for server to process deletion
            Wait(1000)
            
            -- Force server to reload roles from database
            TriggerServerCallback("vfw:staff:reloadRoles")

            -- Clear the selected role before reloading
            permissionsData.selectedRole = nil
            permissionsData.showUnowned = false
            permissionsData.permSearchText = ""

            -- Reload roles from server to ensure we have the correct list
            LoadRoles()

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
                message = "Rôle supprimé: " .. roleName .. "."
          })

            -- Close the edit role menu
            StaffMenu.editRole.close()
            Wait(100)

            -- Return to permissions menu (the parent menu)
            StaffMenu.permissions.toggle()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Permissions',
                message = "Suppression annulée."
          })
        end
    end)

    StaffMenu.editRole.Separator("PERMISSIONS DÉTAILLÉES")

    StaffMenu.editRole.Button("TOUT SÉLECTIONNER", "Activer toutes les permissions que tu peux attribuer", nil, "check", false, function()
        for _, perms in pairs(permissionsData.categories) do
            for _, perm in ipairs(perms) do
                if PlayerCanGrantPerm(perm.name) then
                    permissionsData.selectedRole.permissions[perm.name] = true
                end
            end
        end
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
            message = "Toutes les permissions sélectionnées."
        })
        StaffMenu.editRole.refresh()
    end)

    StaffMenu.editRole.Button("TOUT DÉSELECTIONNER", "Retirer toutes les permissions que tu peux attribuer", nil, "chevron", false, function()
        local remove = {}
        for permName in pairs(permissionsData.selectedRole.permissions) do
            if PlayerCanGrantPerm(permName) then
                remove[#remove + 1] = permName
            end
        end
        for i = 1, #remove do
            permissionsData.selectedRole.permissions[remove[i]] = nil
        end
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Permissions',
            message = "Toutes les permissions désélectionnées."
        })
        StaffMenu.editRole.refresh()
    end)

    -- Search functionality for permissions
    StaffMenu.editRole.Button(":search: RECHERCHER UNE PERMISSION", permissionsData.permSearchText ~= "" and ("Recherche: " .. permissionsData.permSearchText) or nil, nil, "chevron", false, function()
        local search = VFW.Nui.KeyboardInput(true, "Rechercher une permission", permissionsData.permSearchText)
        if search then
            permissionsData.permSearchText = search
            permissionsData.showUnowned = false
            StaffMenu.editRole.refresh()
        end
    end)

    if permissionsData.permSearchText ~= "" then
        StaffMenu.editRole.Button(":x: EFFACER LA RECHERCHE", nil, nil, "chevron", false, function()
            permissionsData.permSearchText = ""
          StaffMenu.editRole.refresh()
        end)
    end

    -- Toggle: show only unowned permissions
    local unownedLabel = permissionsData.showUnowned and ":check: MASQUER LES PERMISSIONS MANQUANTES" or ":dot-red: PERMISSIONS MANQUANTES"
  local unownedSubtitle = permissionsData.showUnowned and "Retour à l'affichage complet" or "Afficher uniquement les permissions non attribuées"
  StaffMenu.editRole.Button(unownedLabel, unownedSubtitle, nil, "chevron", false, function()
        permissionsData.showUnowned = not permissionsData.showUnowned
        permissionsData.permSearchText = ""
      StaffMenu.editRole.refresh()
    end)

    -- Show permissions by category (filtered if search or unowned mode is active)
    if permissionsData.permSearchText ~= "" then
        local searchLower = string.lower(permissionsData.permSearchText)
        local foundCount = 0

        for category, perms in pairs(permissionsData.categories) do
            local categoryPerms = {}
            for _, perm in ipairs(perms) do
                if string.find(string.lower(perm.name), searchLower, 1, true) or
                   string.find(string.lower(perm.label), searchLower, 1, true) then
                    table.insert(categoryPerms, perm)
                    foundCount = foundCount + 1
                end
            end

            if #categoryPerms > 0 then
                StaffMenu.editRole.Separator(string.upper(categoryLabels[category] or category))
                for _, perm in ipairs(categoryPerms) do
                    local hasPermission = permissionsData.selectedRole.permissions[perm.name] ~= nil
                    local canGrant = PlayerCanGrantPerm(perm.name)

                    if canGrant then
                        StaffMenu.editRole.Checkbox(
                            perm.label,
                            perm.name,
                            false,
                            hasPermission,
                            function(checked)
                                if checked then
                                    permissionsData.selectedRole.permissions[perm.name] = true
                                else
                                    permissionsData.selectedRole.permissions[perm.name] = nil
                                end
                            end
                        )
                    elseif hasPermission then
                        StaffMenu.editRole.Checkbox(perm.label, perm.name .. " (verrouillé)", false, true, function() end)
                    end
                end
            end
        end

        if foundCount == 0 then
            StaffMenu.editRole.Separator("Aucune permission trouvée")
        else
            StaffMenu.editRole.Separator(string.format(foundCount > 1 and "%d permissions trouvées" or "%d permission trouvée", foundCount))
        end
    elseif permissionsData.showUnowned then
        local unownedCount = 0

        for category, perms in pairs(permissionsData.categories) do
            local categoryPerms = {}
            for _, perm in ipairs(perms) do
                if permissionsData.selectedRole.permissions[perm.name] == nil and PlayerCanGrantPerm(perm.name) then
                    table.insert(categoryPerms, perm)
                    unownedCount = unownedCount + 1
                end
            end

            if #categoryPerms > 0 then
                StaffMenu.editRole.Separator(string.upper(categoryLabels[category] or category))
                for _, perm in ipairs(categoryPerms) do
                    StaffMenu.editRole.Checkbox(
                        perm.label,
                        perm.name,
                        false,
                        false,
                        function(checked)
                            if checked then
                                permissionsData.selectedRole.permissions[perm.name] = true
                            else
                                permissionsData.selectedRole.permissions[perm.name] = nil
                            end
                            StaffMenu.editRole.refresh()
                        end
                    )
                end
            end
        end

        if unownedCount == 0 then
            StaffMenu.editRole.Separator(":check: Toutes les permissions sont attribuées")
        else
            StaffMenu.editRole.Separator(string.format(unownedCount > 1 and "%d permissions non attribuées" or "%d permission non attribuée", unownedCount))
        end
    else
        -- Show all permissions by category
        for category, perms in pairs(permissionsData.categories) do
            StaffMenu.editRole.Separator(string.upper(categoryLabels[category] or category))

            for _, perm in ipairs(perms) do
                local hasPermission = permissionsData.selectedRole.permissions[perm.name] ~= nil
                local canGrant = PlayerCanGrantPerm(perm.name)

                if canGrant then
                    StaffMenu.editRole.Checkbox(
                        perm.label,
                        perm.name,
                        false,
                        hasPermission,
                        function(checked)
                            if checked then
                                permissionsData.selectedRole.permissions[perm.name] = true
                            else
                                permissionsData.selectedRole.permissions[perm.name] = nil
                            end
                        end
                    )
                elseif hasPermission then
                    StaffMenu.editRole.Checkbox(perm.label, perm.name .. " (verrouillé)", false, true, function() end)
                end
            end
        end
    end
end

-- Setup permission preview handlers
CreateThread(function()
    -- Wait for StaffMenu to be initialized
    while not StaffMenu or not StaffMenu.editRole do
        Wait(100)
    end

    -- OnIndexChange handler for permission preview
    StaffMenu.editRole.OnIndexChange(function(index, item)
        -- Only show preview for checkbox items (permissions)
        if not item or item.type ~= "checkbox" then
            StaffMenu.main.ClosePermissionPreview()
            return
        end

        -- Get the permission name from the subtitle
        local permName = item.props and item.props.subtitle
        if not permName then
            StaffMenu.main.ClosePermissionPreview()
            return
        end

        -- Get the permission data
        local permData = permissionsData.allPermissions[permName]
        if permData then
            StaffMenu.main.PermissionPreview(
                permName,
                permData.label or permName,
                permData.description or "Aucune description disponible",
                permData.category or "other"
          )
        else
            StaffMenu.main.ClosePermissionPreview()
        end
    end)

    -- OnClose handler to close permission preview
    StaffMenu.editRole.OnClose(function()
        StaffMenu.main.ClosePermissionPreview()
    end)
end)

-- Initialize
CreateThread(function()
    Wait(1000)
    OrganizePermissions()
    LoadRoles()
end)

-- Helper function to get table keys (guard against redefinition)
if not table.keys then
    function table.keys(t)
        local keys = {}
        for k, _ in pairs(t) do
            table.insert(keys, k)
        end
        return keys
    end
end