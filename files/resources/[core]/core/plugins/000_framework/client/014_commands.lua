---@meta _
---@diagnostic disable: duplicate-doc-field

-- Helper function to check permission and show notification if denied
local function CheckPermission(permission)
    if VFW.HasStaffPerm and VFW.HasStaffPerm(permission) then
        return true
    end
    if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and next(VFW.PlayerGlobalData.permissions) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas la permission d'utiliser cette commande."
        })
    end
    return false
end

-- Register all command suggestions at once (using VFW queue system to avoid race condition)
VFW.AddChatSuggestions({
    {name = '/id', help = 'Afficher votre UUID et ID serveur'},
    {name = '/idle', help = 'Activer/désactiver la caméra automatique AFK'},
    {name = '/nettoyer', help = 'Nettoyer votre personnage (sang, saleté, etc.)'},
    {name = '/annonce', help = 'Envoyer une annonce serveur globale (admin)', params = {{name = 'message', help = 'Message à annoncer'}}},
    {name = '/annoncestaff', help = 'Envoyer une annonce aux membres du staff', params = {{name = 'message', help = 'Message à annoncer'}}},
    {name = '/annoncezone', help = 'Envoyer une annonce dans une zone spécifique', params = {
        {name = 'radius', help = 'Rayon de la zone en mètres (1-750)'},
        {name = 'message', help = 'Message à envoyer'}
    }},
    {
        name = "/removegraffiti",
        help = "Supprimer les graffitis autour de vous"
    },
    {name = '/co', help = 'Copier vos coordonnées actuelles (x, y, z)'},
    {name = '/coh', help = 'Copier vos coordonnées avec heading (x, y, z, h)'},
    {name = '/setvoiceintent', help = 'Changer le mode audio (parole ou musique)', params = {{name = 'mode', help = 'speech ou music'}}},
    {name = '/vol', help = 'Régler le volume d\'écoute des autres joueurs (pma-voice)', params = {{name = 'volume', help = 'Volume de 0 à 100'}}},
    {name = '/xvol', help = 'Régler le volume des sons xSound (boombox, radios, médias)', params = {{name = 'volume', help = 'Volume de 0 à 100'}}},
    {name = '/cycleproximity', help = 'Changer la portée vocale (chuchotement/normal/cri) - F11'},
    {name = '/vsync', help = 'Resynchroniser le vocal mumble'},
    {name = '/cancelemote', help = 'Annuler l\'animation en cours'},
    {name = '/setwalkstyle', help = 'Changer votre style de marche', params = {{name = 'style', help = 'Nom du style de marche'}}},
    {name = '/resetwalkstyle', help = 'Réinitialiser votre style de marche par défaut'},
    {name = '/proper', help = 'Nettoyer votre personnage (sang, saleté)'},
    {name = '/relog', help = 'Retourner à la sélection de personnage'},
    {name = '/boutique', help = 'Ouvrir la boutique Coins'},
    {name = '/afkshop', help = 'Ouvrir la boutique de la zone AFK'},
    {name = '/voicestatus', help = 'Afficher l\'état de votre connexion vocale'},
    {name = '/msg', help = 'Envoyer un message staff à un joueur', params = {{name = 'id', help = 'ID du joueur'}, {name = 'message', help = 'Message à envoyer'}}},
})

local idle = false
_G.IdleCamEnabled = false

-- Command to display player UUID and server ID
-- Wait for VFW to be fully loaded before registering
CreateThread(function()
    while not VFW or not VFW.ShowNotification or not TriggerServerCallback do
        Wait(100)
    end

    RegisterCommand('id', function(source, args, showError)
        local serverId = GetPlayerServerId(PlayerId())
        local uuid = TriggerServerCallback("vfw:getPlayerUUID")

        if uuid and serverId then
            VFW.ShowNotification({
                type = 'BLEU',
                content = "UUID: " .. tostring(uuid) .. "\nID Serveur: " .. tostring(serverId)
            })
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Erreur lors de la récupération de vos informations"
            })
        end
    end)
end)

RegisterCommand('idle', function(source, args, showError)
    idle = not idle
    _G.IdleCamEnabled = idle
    DisableIdleCamera(not idle)
    VFW.ShowNotification({
        type = 'JAUNE',
        message = not idle and 'Vous avez désactivé la caméra AFK' or 'Vous avez activé la caméra AFK',
    })
end)

RegisterCommand('nettoyer', function(source, args, showError)
    ClearPedBloodDamage(VFW.PlayerData.ped)
    ResetPedVisibleDamage(VFW.PlayerData.ped)
    ClearPedLastWeaponDamage(VFW.PlayerData.ped)
    ClearPedEnvDirt(VFW.PlayerData.ped)
    ClearPedWetness(VFW.PlayerData.ped)
end)

RegisterCommand('msg', function(source, args, showError)
    if not VFW.HasStaffPerm("staff_menu") and not VFW.HasStaffPerm("menu_anim") then
        if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and next(VFW.PlayerGlobalData.permissions) then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas la permission d'utiliser cette commande."
            })
        end
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Utilisation: /msg [id] [message]"
        })
        return
    end

    -- Concatenate remaining args as message
    local msg = table.concat(args, " ", 2)
    if msg == "" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Utilisation: /msg [id] [message]"
        })
        return
    end

    local isAnim = (StaffMenu and StaffMenu.animatorModeEnabled) and true or false
    TriggerServerEvent("core:vnotif:createAlert:player", msg, targetId, isAnim)
end, false)

RegisterNetEvent("vfw:staff:msgResult", function(success, reason, targetName, targetId, senderType)
    if success then
        local isAnim = senderType == "animator"
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = isAnim and 'Mode Animateur' or 'Gestion Joueur',
            title = isAnim and VFW.AnimatorTitle() or nil,
            message = ("Message envoyé à %s (#%s)."):format(targetName or "?", targetId or "?")
        })
        return
    end

    local content = "Erreur lors de l'envoi du message."
    if reason == "perm" then
        content = "Vous n'avez pas la permission d'envoyer ce message."
    elseif reason == "notfound" then
        content = ("Le joueur #%s est introuvable ou déconnecté."):format(targetId or "?")
    end
    VFW.ShowNotification({ type = 'ROUGE', content = content })
end)

--- formatNumber
---@param num any
---@return any
local function formatNumber(num)
    return tonumber(string.format("%.2f", num))
end

RegisterCommand('co', function(source, args, showError)
    if not CheckPermission("staff_menu") then return end

    local coords = GetEntityCoords(PlayerPedId())
    local z = coords.z - 1

    VFW.Clipboard(formatNumber(coords.x)..", "..formatNumber(coords.y)..", "..formatNumber(z))
    VFW.ShowNotification({ type = 'VERT', content = "Coordonnées copiées dans le presse-papier." })
end)

RegisterCommand('coh', function(source, args, showError)
    if not CheckPermission("staff_menu") then return end

    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local z = coords.z - 1

    VFW.Clipboard(formatNumber(coords.x)..", "..formatNumber(coords.y)..", "..formatNumber(z)..", "..formatNumber(heading))
    VFW.ShowNotification({ type = 'VERT', content = "Coordonnées copiées dans le presse-papier." })
end)

-- Global server announcement command
RegisterCommand("annonce", function(source, args)
    if not CheckPermission("announce_serv") then return end

    local message = table.concat(args, " ")

    if not message or message == "" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce message n'est pas valide !"
        })
        return
    end

    -- Trigger server event for global announcement
    message = message:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
    TriggerServerEvent("vfw:staff:sendGlobalAnnouncement", message)
end)

RegisterCommand("annoncestaff", function(source, args)
    if not CheckPermission("announce_modo") then return end

    local message = table.concat(args, " ")

    if not message or message == "" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce message n'est pas valide !"
        })
        return
    end

    message = message:gsub("^%s+", ""):gsub("%s+$", "")
    TriggerServerEvent("core:vnotif:createAlert:staff", message)
end)

-- Zone announcement command (radius 0 now forbidden)
RegisterCommand("annoncezone", function(source, args)
    if not CheckPermission("announce_serv") then return end

    local radius = tonumber(args[1])
    local message = ""

    for i = 2, #args do
        message = message .. " " .. args[i]
    end

    if not radius then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce rayon n'est pas valide !"
        })
        return
    end

    if radius == 0 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Utilisez /annonce pour une annonce globale !"
        })
        return
    end

    if radius > 750 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Rayon trop grand !"
        })
        return
    end

    if not message or message == "" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce message n'est pas valide !"
        })
        return
    end

    -- Trigger server event to handle the zone announcement with styled UI
    message = message:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
    TriggerServerEvent("vfw:staff:sendZoneAnnouncement", radius, message)
end)
