---@meta _
---@diagnostic disable: duplicate-doc-field

local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/default.png")

-- Create submenus for permission management
StaffMenu.permissionManagement = nil
StaffMenu.permissionRoles = nil
StaffMenu.permissionIndividual = nil

-- Available roles (will be populated from server)
local availableRoles = {}
local availablePermissions = {}
local playerPermissions = {}
local selectedRole = 1

-- Permission categories for better organization
local permissionCategories = {
    ["Staff de base"] = {
        "staff_menu",
        "noclip",
        "godmod_invisible",
        "spectate"
  },
    ["Modération"] = {
        "kick",
        "ban",
        "warn",
        "freeze_player",
        "goto",
        "ko",
        "mute"
  },
    ["Gestion Joueur"] = {
        "heal",
        "revive",
        "setjob",
        "setjob2",
        "give_item",
        "inventaire",
        "recup_apparence",
        "staff_skin"
  },
    ["Administration"] = {
        "gestion_perm",
        "wipe",
        "list_staff",
        "gestion_faction",
        "manage_jobs",
        "sams_management",
        "sanctions",
        "modify_sanctions"
  },
    ["Développement"] = {
        "dev",
        "addcarcustom",
        "addvehplayer",
        "weather",
        "time",
        "devcontextmenu"
  },
    ["Animation"] = {
        "menu_anim",
        "anim_chat",
        "menu_event",
        "events"
  },
    ["Builder"] = {
        "builder",
        "builder_menu",
        "builder_elevator",
        "zonesafe_builder",
        "doorlock_builder",
        "builder_platine",
        "builder_supermarket",
        "builder_firework",
        "props_builder",
        "freeze_objects",
        "perm_batiment",
        "graffiti",
        "builder_taxi",
        "builder_studio",
        "builder_television",
        "builder_cameras",
        "builder_journaliste",
        "builder_legal_craft",
        "builder_scratch_card",
        "builder_atm",
        "builder_fleeca",
        "builder_pacific",
        "builder_jewelry",
        "builder_burglary",
        "builder_gofast",
        "builder_drug_pipeline",
        "builder_drug_dealing",
        "builder_blackmarket",
        "builder_whitening",
        "builder_fines",
        "manage_doj",
        "manage_police_zones",
        "builder_radio911",
        "builder_zombie",
        "builder_spacemarket",
        "builder_gas_station",
        "builder_gouv",
        "builder_elections",
        "builder_driveby",
        "builder_farm",
        "builder_koth"
  }
}

-- Function to open permission management for a player
function StaffMenu.OpenPermissionManagement(playerId, playerName)
    -- Create menus if they don't exist
    if not StaffMenu.permissionManagement then
        StaffMenu.permissionManagement = VUI:CreateSubMenu(StaffMenu.player, "GESTION DES PERMISSIONS", defaultBanner, true)
        StaffMenu.permissionRoles = VUI:CreateSubMenu(StaffMenu.permissionManagement, "ATTRIBUER UN RÔLE", defaultBanner, true)
        StaffMenu.permissionIndividual = VUI:CreateSubMenu(StaffMenu.permissionManagement, "PERMISSIONS INDIVIDUELLES", defaultBanner, true)
    end

    -- Get available roles from server
    availableRoles = TriggerServerCallback("vfw:staff:getAvailableRoles") or {}

    -- Get player's current permissions
    playerPermissions = TriggerServerCallback("vfw:staff:getPlayerPermissions", playerId) or {}

    -- Build the main permission menu
    StaffMenu.permissionManagement.open()

    StaffMenu.permissionManagement.Separator(":user: " .. playerName)
    StaffMenu.permissionManagement.Separator("Permissions actuelles: " .. table.count(playerPermissions))

    -- Role assignment button
    StaffMenu.permissionManagement.Button(":users: ATTRIBUER UN RÔLE PRÉDÉFINI", nil, nil, "chevron", false, function()
        BuildRolesMenu(playerId, playerName)
    end, StaffMenu.permissionRoles)

    -- Individual permissions button
    StaffMenu.permissionManagement.Button(":key: GÉRER LES PERMISSIONS INDIVIDUELLES", nil, nil, "chevron", false, function()
        BuildIndividualPermissionsMenu(playerId, playerName)
    end, StaffMenu.permissionIndividual)

    -- Quick actions
    StaffMenu.permissionManagement.Separator(":bolt: ACTIONS RAPIDES")

    -- Add common role presets
    StaffMenu.permissionManagement.Button(":plus: DONNER PERMISSIONS NIVEAU 2", nil, nil, "arrow", false, function()
        local confirm = VFW.Nui.ConfirmPopup("Confirmation", "Voulez-vous donner les permissions de niveau 2 à " .. playerName .. " ?")
        if confirm then
            TriggerServerEvent("vfw:staff:assignPresetRole", playerId, "niveau_2")
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Permissions Joueur',
                message = "Permissions de niveau 2 attribuées"
          })
        end
    end)

    StaffMenu.permissionManagement.Button(":plus: DONNER PERMISSIONS ANIMATEUR", nil, nil, "arrow", false, function()
        local confirm = VFW.Nui.ConfirmPopup("Confirmation", "Voulez-vous donner les permissions d'animateur à " .. playerName .. " ?")
        if confirm then
            TriggerServerEvent("vfw:staff:assignPresetRole", playerId, "animator")
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Permissions Joueur',
                message = "Permissions d'animateur attribuées"
          })
        end
    end)

    StaffMenu.permissionManagement.Button(":trash: RETIRER TOUTES LES PERMISSIONS", nil, nil, "arrow", false, function()
        local confirm = VFW.Nui.ConfirmPopup(":warning: Confirmation", "Voulez-vous vraiment retirer TOUTES les permissions de " .. playerName .. " ?")
        if confirm then
            TriggerServerEvent("vfw:staff:removeAllPlayerPermissions", playerId)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Permissions Joueur',
                message = "Toutes les permissions retirées"
          })
            StaffMenu.permissionManagement.close()
        end
    end)
end

-- Build roles menu
function BuildRolesMenu(playerId, playerName)
    StaffMenu.permissionRoles.ClearItems()

    StaffMenu.permissionRoles.Separator(":user: " .. playerName)
    StaffMenu.permissionRoles.Separator("RÔLES DISPONIBLES")

    -- List predefined roles (permissions loaded from DB on assign)
    local roles = {
        {id = "user", name = "Utilisateur"},
        {id = "animator", name = "Animateur"},
        {id = "niveau_1", name = "Niveau 1"},
        {id = "niveau_2", name = "Niveau 2"},
        {id = "niveau_3", name = "Niveau 3"},
        {id = "niveau_4", name = "Niveau 4"},
        {id = "niveau_5", name = "Niveau 5"},
    }

    for _, role in ipairs(roles) do
        StaffMenu.permissionRoles.Button(role.name, "Rôle prédéfini", nil, "arrow", false, function()
            local confirm = VFW.Nui.ConfirmPopup("Confirmation", "Attribuer le rôle " .. role.name .. " à " .. playerName .. " ?\n\nCela remplacera ses permissions actuelles.")
            if confirm then
                TriggerServerEvent("vfw:staff:assignFullRole", playerId, role.id)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Permissions Joueur',
                    message = "Rôle " .. role.name .. " attribué"
              })
                StaffMenu.permissionRoles.close()
            end
        end)
    end
end

-- Build individual permissions menu
function BuildIndividualPermissionsMenu(playerId, playerName)
    StaffMenu.permissionIndividual.ClearItems()

    StaffMenu.permissionIndividual.Separator(":user: " .. playerName)

    -- Display permissions by category
    for categoryName, permissions in pairs(permissionCategories) do
        StaffMenu.permissionIndividual.Separator(categoryName)

        for _, permission in ipairs(permissions) do
            local hasPermission = playerPermissions[permission] == true

            StaffMenu.permissionIndividual.Checkbox(
                permission:upper():gsub("_", " "),
                nil,
                false,
                hasPermission,
                function(checked)
                    -- Update permission on server
                    TriggerServerEvent("vfw:staff:setPlayerPermission", playerId, permission, checked)

                    -- Update local cache
                    if checked then
                        playerPermissions[permission] = true
                    else
                        playerPermissions[permission] = nil
                    end

                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = checked and 'SUCCESS' or 'INFO',
                        subtitle = 'Permissions Joueur',
                        message = "Permission " .. permission .. (checked and " accordée." or " retirée.")
                    })
                end
            )
        end
    end

    -- Add custom permission input
    StaffMenu.permissionIndividual.Separator(":plus: PERMISSION PERSONNALISÉE")
    StaffMenu.permissionIndividual.Button("AJOUTER UNE PERMISSION", nil, nil, "arrow", false, function()
        local permName = VFW.Nui.KeyboardInput(true, "Nom de la permission", "")
        if permName and permName ~= "" then
            TriggerServerEvent("vfw:staff:setPlayerPermission", playerId, permName, true)
            playerPermissions[permName] = true
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Permissions Joueur',
                message = "Permission " .. permName .. " ajoutée"
          })
            -- Refresh menu
            BuildIndividualPermissionsMenu(playerId, playerName)
        end
    end)
end