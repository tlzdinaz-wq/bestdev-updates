---@meta _
---@diagnostic disable: duplicate-doc-field

StaffMenu.BuildGlobalMenu = function()
    local perms = VFW.PlayerGlobalData.permissions or {}

    if perms["gestion_perm"] then
        StaffMenu.global.Button(":lock: GESTION PERMISSIONS", "Gérer les rôles et les permissions des membres du staff", nil, "chevron", false, function()
        end, StaffMenu.permissions)
    end

    if perms["server_management"] then
        StaffMenu.global.Button(":settings: GESTION SERVEUR", "Météo, heure, freeze global, kick général et statistiques serveur", nil, "chevron", false, function()
        end, StaffMenu.serverManagement)
    end

    if perms["video_management"] then
        StaffMenu.global.Button(":film: GESTION VIDÉOS", "Gérer les vidéos et médias diffusés sur le serveur", nil, "chevron", false, function()
        end, StaffMenu.videoManagement)
    end

    if perms["dev"] then
        StaffMenu.global.Button(":monitor: DÉVELOPPEURS", "Outils réservés aux développeurs du serveur", nil, "chevron", false, function()
        end, StaffMenu.developers)
    end

    if perms["builder_menu"] then
        StaffMenu.global.Button(":building: BUILDERS", "Accéder aux outils de construction et de configuration de la map", nil, "chevron", false, function()
        end, StaffMenu.builders)
    end

    if perms["events"] then
        StaffMenu.global.Button(":sparkles: EVENTS SPÉCIAUX", "Déclencher des effets spéciaux et animations pour les événements", nil, "chevron", false, function()
        end, StaffMenu.specialEffects)
    end
end
