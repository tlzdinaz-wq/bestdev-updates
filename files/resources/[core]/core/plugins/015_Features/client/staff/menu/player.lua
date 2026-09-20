---@meta _
---@diagnostic disable: duplicate-doc-field

local playerStates = {}
local savedOriginalSkin = nil

---Get PlayerState
---@param playerId number|table Player ID or player object
---@return table|nil Player object
local function getPlayerState(playerId)
    if not playerId then return nil end

    if not playerStates[playerId] then
        playerStates[playerId] = {
            Spectate = false,
            Freeze = false,
            Return = false,
            indexBan = 1
        }
    end

    return playerStates[playerId]
end

-- Fonction globale pour reinitialiser l'etat spectate d'un joueur (appele depuis StaffMenu.StopSpectate)
function StaffMenu.ResetPlayerSpectate(playerId)
    if playerId and playerStates[playerId] then
        playerStates[playerId].Spectate = false
    end
    if StaffMenu.player and StaffMenu.player.refresh and StaffMenu.data.selectedPlayer then
        pcall(function() StaffMenu.player.refresh() end)
    end
end

--- .BuildPlayerMenu
function StaffMenu.BuildPlayerMenu()
    local player = getPlayerState(StaffMenu.data.selectedPlayer)
    local info = StaffMenu.data.playerInfo or {}
    local isAnimatorCtx = StaffMenu.animatorPlayerContext or false

    local rpName = "Inconnu"
  if info.firstName and info.lastName then
        rpName = info.firstName .. " " .. info.lastName
    elseif info.name then
        rpName = info.name
    end

    local tigStatus = info.hasTig and ":dot-orange: EN TIG" or "Aucun"
  local sanctionsCount = StaffMenu.data.sanctionsPlayerList and #StaffMenu.data.sanctionsPlayerList or 0

    local previewData = {
        { type = "header", iconUrl = "people.png",   label = "",                  value = tostring(info.pseudo or "Sans pseudo") },
        { type = "body",   iconUrl = "people.png",   label = "ID Session",        value = tostring(info.source or "?") },
        { type = "body",   iconUrl = "data.png",     label = "UUID",              value = tostring(info.uuid or info.id or "?") },
        { type = "body",   iconUrl = "shield.png",   label = "Rôle",              value = tostring(info.roleFormatted or info.role or "Joueur") },
        { type = "body",   iconUrl = "time.png",     label = "Temps de jeu",      value = tostring(info.time or "00:00:00") },
        { type = "body",   iconUrl = "people.png",   label = "Nom Prénom RP",     value = tostring(rpName) },
        { type = "body",   iconUrl = "time.png",     label = "Date de naissance", value = tostring(info.dateOfBirth or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Taille",            value = tostring(info.height or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Sexe",              value = tostring(info.sex or "Inconnu") },
        { type = "body",   iconUrl = "job.png",      label = "Job 1",             value = tostring(info.jobFull or "Civil") },
        { type = "body",   iconUrl = "crew.png",     label = "Job 2 (Faction)",   value = tostring(info.factionFull or "Civil") },
        { type = "body",   iconUrl = "time.png",     label = "TIG",               value = tigStatus },
    }

    local instanceValue = (info.instance and info.instance ~= 0) and (":dot-orange: " .. tostring(info.instance)) or "Aucune instance"
  table.insert(previewData, { type = "body", iconUrl = "data.png", label = "Instance", value = instanceValue })

    local discordValue = info.discord and tostring(info.discord) or "Non relié"
  local stats = {
        { "ID Discord", discordValue },
        { "Nombre de sanctions reçues", sanctionsCount },
    }

    local selectedPlayer = StaffMenu.data.selectedPlayer
    -- Si la fiche est déjà à l'écran (sélection dans la liste), ne pas la renvoyer.
    -- Sinon, l'envoyer APRÈS l'ouverture du menu (SetTimeout) pour ne pas bloquer le paint.
    if StaffMenu._previewSource ~= selectedPlayer then
        local color = info.color or 0xFFFFFF
        SetTimeout(0, function()
            if not StaffMenu.player or not StaffMenu.player.opened then return end
            if StaffMenu.data.selectedPlayer ~= selectedPlayer then return end
            StaffMenu.player.PlayerPreview(nil, color, previewData, stats)
            StaffMenu._previewSource = selectedPlayer
        end)
    end

    local perms = VFW.StaffPerms()
    local notifTitle = isAnimatorCtx and VFW.AnimatorTitle() or nil
    local notifSub = isAnimatorCtx and 'Mode Animateur' or 'Gestion Joueur'

    -- Smart separator helpers: suppress separators between empty sections.
    local _pendingSep = false
    local _anyContent = false
    local function _flushSep()
        if _pendingSep and _anyContent then
            StaffMenu.player.Separator(nil)
        end
        _pendingSep = false
    end
    local function P_Button(...) _flushSep(); _anyContent = true; StaffMenu.player.Button(...) end
    local function P_Checkbox(...) _flushSep(); _anyContent = true; StaffMenu.player.Checkbox(...) end
    local function P_List2(...) _flushSep(); _anyContent = true; StaffMenu.player.List2(...) end
    local function P_Sep() _pendingSep = true end

    -- ══════════════════════════════════
    -- COMMUNICATION & TÉLÉPORTATION
    -- ══════════════════════════════════
    if isAnimatorCtx or perms["announce_serv"] or perms["menu_anim"] or perms["staff_menu"] then
        P_Button(":document: ENVOYER UN MESSAGE", "Envoyer une notification privée au joueur sélectionné", nil, "chevron", false, function()
            local msg = VFW.Nui.KeyboardInput(true, "Message", "")
            if msg and msg ~= "" then
                TriggerServerEvent("core:vnotif:createAlert:player", msg, selectedPlayer, isAnimatorCtx)
            end
        end)
    end

    if isAnimatorCtx or perms["goto"] then
        P_Button(":arrow: GOTO", "Se téléporter directement sur le joueur", nil, "chevron", false, function()
            ExecuteCommand(("goto %s"):format(selectedPlayer))
        end)

        P_Button(":back: BRING", "Téléporter le joueur jusqu'à vous", nil, "chevron", false, function()
            ExecuteCommand(("bring %s"):format(selectedPlayer))
            player.Return = true
            StaffMenu.player.refresh()
        end)

        if player.Return then
            P_Button(":back: RETURN", "Renvoyer le joueur à sa position d'origine avant le bring", nil, "chevron", false, function()
                ExecuteCommand(("return %s"):format(selectedPlayer))
                player.Return = false
                StaffMenu.player.refresh()
            end)
        end

        P_Button(":pin: GPS POSITION", "Placer un waypoint GPS sur la position actuelle du joueur", nil, "arrow", false, function()
            local playerCoords = TriggerServerCallback("core:CoordsOfPlayer", selectedPlayer)
            if playerCoords then
                SetNewWaypoint(playerCoords.x, playerCoords.y)
                VFW.ShowNotification({ type = 'STAFF', title = notifTitle, variant = 'SUCCESS', subtitle = notifSub, message = "Waypoint défini." })
            end
        end)
    end

    if not isAnimatorCtx and perms["screenshot"] then
        P_Button(":camera: SCREEN ÉCRAN", "Prendre une capture d'écran du client du joueur à des fins de modération", nil, "chevron", false, function()
            TriggerServerEvent("vfw:staff:takeScreenshot", selectedPlayer, {
                name = info.name,
                visaId = info.id
            })
        end)
    end

    P_Sep()

    -- ══════════════════════════════════
    -- OBSERVATION & CONTRÔLE
    -- ══════════════════════════════════
    if isAnimatorCtx or perms["spectate"] then
        P_Checkbox(":eye: SPECTATE", "Observer le joueur en mode spectateur sans qu'il le sache (noclip requis)", false, player.Spectate, function(_checked)
            if _checked and not VFW.IsNoclipActive() then
                VFW.ShowNotification({ type = 'STAFF', title = notifTitle, variant = 'ERROR', subtitle = notifSub, message = "Vous devez être en noclip pour spectate." })
                player.Spectate = false
                StaffMenu.player.refresh()
                return
            end
            if _checked and selectedPlayer == GetPlayerServerId(PlayerId()) then
                VFW.ShowNotification({ type = 'STAFF', title = notifTitle, variant = 'ERROR', subtitle = notifSub, message = "Vous ne pouvez pas vous spectate vous-même." })
                player.Spectate = false
                StaffMenu.player.refresh()
                return
            end
            player.Spectate = _checked
            if _checked then
                if StaffMenu.SpectatePlayer then StaffMenu.SpectatePlayer(selectedPlayer)
                else TriggerServerEvent("core:StaffSpectate", selectedPlayer, true) end
            else
                if StaffMenu.StopSpectate then StaffMenu.StopSpectate()
                else TriggerServerEvent("core:StaffSpectate", selectedPlayer, false) end
            end
        end)
    end

    if isAnimatorCtx or perms["revive"] then
        P_Button(":dot-green: REVIVE", "Ranimer immédiatement le joueur s'il est mort ou KO", nil, "heart", false, function()
            TriggerServerEvent("vfw:staff:revivePlayer", selectedPlayer)
        end)
    end

    if isAnimatorCtx or perms["heal"] then
        P_Button(":heart: HEAL", "Restaurer tous les PV du joueur sans le ranimer", nil, "heart", false, function()
            TriggerServerEvent("vfw:staff:healPlayer", selectedPlayer)
        end)
    end

    if isAnimatorCtx or perms["freeze_player"] then
        P_Checkbox(" FREEZE / UNFREEZE", "Immobiliser ou libérer le joueur, il ne peut plus bouger tant que c'est actif", false, player.Freeze, function(_checked)
            player.Freeze = _checked
            TriggerServerEvent("core:FreezePlayer", selectedPlayer, _checked)
            VFW.ShowNotification({ type = 'STAFF', title = notifTitle, variant = _checked and 'SUCCESS' or 'INFO', subtitle = notifSub, message = _checked and "Joueur freezé." or "Joueur unfreezé." })
        end)
    end

    if isAnimatorCtx then return end

    P_Sep()

    -- ══════════════════════════════════
    -- INVENTAIRE
    -- ══════════════════════════════════
    if perms["voir_inventaire"] or perms["inventaire"] then
        P_Button(":box: VOIR L'INVENTAIRE", "Ouvrir l'inventaire du joueur en lecture seule", nil, "chevron", false, function()
            VFW.OpenShearchStaff(selectedPlayer)
        end)
    end

    if perms["prendre_inventaire"] or perms["inventaire"] then
        P_Button(":trash: PRENDRE DANS L'INVENTAIRE", "Ouvrir l'inventaire du joueur avec la possibilité de retirer des items", nil, "chevron", false, function()
            StaffMenu.player.close()
            Wait(150)
            VFW.OpenShearchStaff(selectedPlayer)
        end)
    end

    if perms["inventaire_cleaner"] or perms["inventaire"] then
        P_Button(":trash: INVENTAIRE CLEANER", "Nettoyer et réorganiser l'inventaire du joueur", nil, "chevron", false, function()
            StaffMenu.player.close()
            Wait(150)
            VFW.InventoryCleaner(selectedPlayer, info.name)
        end)
    end

    P_Sep()

    -- ══════════════════════════════════
    -- VÉHICULES & APPARENCE & DIVERS
    -- ══════════════════════════════════
    if perms["voir_inventaire"] or perms["inventaire"] then
        P_Button(":car: VOIR LES VÉHICULES", "Voir tous les véhicules possédés par le joueur (perso, métier, faction)", nil, "chevron", false, function()
            StaffMenu.data.vehsList = TriggerServerCallback("core:server:GetAllVehicle", selectedPlayer) or { owned = {}, job = {}, faction = {} }
            StaffMenu.data.vehsLookupMode = false
            StaffMenu.BuildVehsMenu()
            StaffMenu.vehs.open()
        end)
    end

    if perms["recup_apparence"] then
        P_Button(":briefcase: RÉCUPÉRER SON APPARENCE", "Prévisualiser l'apparence (skin) du joueur sur votre personnage", nil, "chevron", false, function()
            if savedOriginalSkin then
                TriggerEvent("skinchanger:loadSkin", savedOriginalSkin)
                savedOriginalSkin = nil
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = "Apparence originale restaurée." })
                return
            end
            local skin = TriggerServerCallback("vfw:staff:getSkin", selectedPlayer)
            if skin then
                savedOriginalSkin = TriggerServerCallback("vfw:staff:getSkin", GetPlayerServerId(PlayerId()))
                TriggerEvent("skinchanger:loadSkin", skin)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = "Apparence du joueur récupérée." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur', message = "Impossible de récupérer l'apparence." })
            end
        end)

        P_Button(":mask: APPLIQUER UNE APPARENCE", "Copier temporairement l'apparence d'un autre joueur sur ce joueur (réinitialisée à la prochaine connexion)", nil, "chevron", false, function()
            local sourceInput = VFW.Nui.KeyboardInput(true, "ID du joueur à copier", "")
            if not sourceInput or sourceInput == "" then return end
            local sourceId = tonumber(sourceInput)
            if not sourceId then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur', message = "Cet identifiant n'est pas valide." })
                return
            end
            if sourceId == selectedPlayer then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur', message = "Vous avez sélectionné deux fois le même joueur." })
                return
            end
            VFW.Nui.Focus(true)
            local confirm = VFW.Nui.ConfirmPopup("Confirmation", "Appliquer temporairement l'apparence du joueur " .. sourceId .. " sur " .. tostring(info.name) .. " ?\n\nL'apparence sera réinitialisée à la prochaine connexion du joueur.")
            VFW.Nui.Focus(false)
            if not confirm then return end
            local success = TriggerServerCallback("vfw:staff:applySkinToPlayer", sourceId, selectedPlayer)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = "Apparence appliquée temporairement." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur', message = "Impossible d'appliquer l'apparence." })
            end
        end)
    end

    if perms["setjob"] then
        P_Button(":briefcase: CHANGER LE MÉTIER", "Choisir un nouveau job et un grade pour le joueur", nil, "chevron", false, function()
            StaffMenu.FetchJobs(false)
        end, StaffMenu.jobs)
    end

    -- Changement de rang réservé aux Gérants Staff (niveau 5+)
    if (VFW.PlayerGlobalData.level or 0) >= 5 and StaffMenu.playerSetRank then
        P_Button(":mask: CHANGER LE RANG", "Modifier le rôle/rang du joueur (réservé Gérant Staff)", nil, "chevron", false, function()
            StaffMenu.data.roleChangeTarget = {
                globalId = info.id,
                identifier = info.identifier,
                role = info.role,
                displayName = info.pseudo or info.name or ("ID " .. tostring(selectedPlayer))
            }
        end, StaffMenu.playerSetRank)
    end

    if perms["give_permis"] then
        P_Button(":id: DONNER UN PERMIS", "Attribuer un permis manquant (voiture, moto, poids lourd) au joueur", nil, "chevron", false, function()
        end, StaffMenu.playerLicense)
    end

    if perms["give_item"] then
        P_Button(":gift: GIVE UN ITEM", "Donner un item au joueur en entrant son nom et la quantité. Commande : /giveitem [ID] [item] [qté]", nil, "chevron", false, function()
            StaffMenu.playerGiveItemData = StaffMenu.playerGiveItemData or {}
            StaffMenu.playerGiveItemData.targetId = selectedPlayer
            StaffMenu.playerGiveItemData.itemQuery = nil
            StaffMenu.playerGiveItemData.currentPage = 1
            StaffMenu.playerGiveItemData.selectedQuantity = 1
        end, StaffMenu.playerGiveItem)
    end

    P_Sep()

    -- ══════════════════════════════════
    -- SANCTIONS & MODÉRATION
    -- ══════════════════════════════════
    if perms["sanctions"] then
        local sanctionCount = StaffMenu.data.sanctionsPlayerList and #StaffMenu.data.sanctionsPlayerList or 0
        P_Button(":scales: CASIER DU JOUEUR", sanctionCount .. (sanctionCount > 1 and " sanctions" or " sanction"), nil, "arrow", false, function()

            StaffMenu.OpenSanctionsUI({
                id = info.id,
                source = selectedPlayer,
                name = info.name,
                identifier = info.identifier,
                discord = info.discord,
                online = true
            })
        end)
    end

    if perms["warn"] then
        P_Button(":warning: AVERTISSEMENT", "Envoyer un warn officiel au joueur avec un motif obligatoire. Commande : /warn [ID] [motif]", nil, "chevron", false, function()
            local reason = VFW.Nui.KeyboardInput(true, "Motif de l'avertissement", "")
            if not reason or reason == "" then return end
            ExecuteCommand(("warn %s %s"):format(selectedPlayer, reason))
        end)
    end

    if perms["give_tig"] then
        P_Button(":report: TIG", "Donner des travaux d'intérêt général au joueur. Commande : /tig [ID] [nb] [motif]", nil, "chevron", false, function()
            local tasks = VFW.Nui.KeyboardInput(true, "Nombre de tâches TIG", "")
            if not tasks or tasks == "" then return end
            local reason = VFW.Nui.KeyboardInput(true, "Motif du TIG", "")
            if not reason or reason == "" then return end
            ExecuteCommand(("tig %s %s %s"):format(selectedPlayer, tasks, reason))
        end)

        P_Button(":gun: TIG ARMES", "Confisquer les armes du joueur pour une durée en minutes. Commande : /tigweapon [ID] [minutes] [motif]", nil, "chevron", false, function()
            local duration = VFW.Nui.KeyboardInput(true, "Durée en minutes (max 600)", "")
            if not duration or duration == "" then return end
            local reason = VFW.Nui.KeyboardInput(true, "Motif du TIG armes", "")
            if not reason or reason == "" then return end
            ExecuteCommand(("tigweapon %s %s %s"):format(selectedPlayer, duration, reason))
        end)
    end

    if perms["kick"] then
        P_Button(":user: KICK", "Expulser le joueur du serveur avec une raison obligatoire", nil, "arrow", false, function()
            local reason = VFW.Nui.KeyboardInput(true, "Raison du kick")
            if reason and reason ~= "" then
                TriggerServerEvent("core:KickPlayer", selectedPlayer, reason)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = "Joueur expulsé." })
            end
        end)
    end

    if perms["ban"] then
        local banPresets = { "24h", "48h", "1 semaine", "Définitif", "Personnalisé" }
        P_List2(":hammer: BAN", "Bannir le joueur avec une durée prédéfinie ou personnalisée et une raison obligatoire", false, banPresets, player.indexBan, function(index)
            player.indexBan = index
        end, function(index, item)
            local reason = VFW.Nui.KeyboardInput(true, "Raison du bannissement", "")
            if not reason or reason == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur', message = "Vous devez entrer une raison." })
                return
            end
            local time, typeBan
            if item == "24h" then
                time = "24"
              typeBan = "heures"
          elseif item == "48h" then
                time = "48"
              typeBan = "heures"
          elseif item == "1 semaine" then
                time = "7"
              typeBan = "jours"
          elseif item == "Définitif" then
                time = 0
                typeBan = "perm"
          elseif item == "Personnalisé" then
                time = VFW.Nui.KeyboardInput(true, "Durée en heures", "")
                if not time or time == "" then return end
                typeBan = "heures"
          end
            TriggerServerEvent("core:ban:banplayer", selectedPlayer, reason, time, GetPlayerServerId(PlayerId()), typeBan)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = "Joueur banni." })
        end)
    end

    if perms["register"] then
        P_Button(":edit: REGISTER", "Enregistrer manuellement le joueur dans la base de données. Commande : /register [ID]", nil, "chevron", false, function()
            ExecuteCommand(("register %s"):format(selectedPlayer))
        end)
    end

    if perms["wipe"] then
        P_Button(":skull: WIPE", "Supprimer un ou plusieurs personnages du joueur, action irréversible", nil, "arrow", false, function()
            StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getCharList", selectedPlayer) or {}
            if not StaffMenu.data.charList or not StaffMenu.data.charList.charList or #StaffMenu.data.charList.charList == 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe', message = "Aucun personnage trouvé pour ce joueur." })
                return false
            end
            StaffMenu.wipe.ClearItems()
            for _, v in pairs(StaffMenu.data.charList.charList) do
                StaffMenu.wipe.Button(v.name, (v.actual and "Actuel" or "OFF"), v.id, "chevron", false, function()
                    local validations = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI'")
                    if string.lower(validations) == "oui" then
                        TriggerServerEvent("vfw:staff:wipePlayer", selectedPlayer, v.id)
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Wipe', message = "Vous venez de wipe le personnage." })
                        SetTimeout(500, function()
                            StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getCharList", selectedPlayer) or {}
                            if StaffMenu.data.charList and StaffMenu.data.charList.charList and #StaffMenu.data.charList.charList > 0 then
                                StaffMenu.wipe.refresh()
                            else
                                StaffMenu.wipe.close()
                            end
                        end)
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe', message = "Vous n'avez pas confirmé." })
                    end
                end)
            end
        end, StaffMenu.wipe)
    end
end

--- openPlayerOnAdminMenu
---@param id number|string
---@param isAnimatorCtx boolean|nil
---@return any
local function openPlayerOnAdminMenu(id, isAnimatorCtx)
    StaffMenu.animatorPlayerContext = isAnimatorCtx or false

    if id == nil then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur',
            message = "Impossible d'ouvrir le menu de ce joueur : son identifiant n'est pas valide."
      })
        return
    end

    local parentMenu = isAnimatorCtx and StaffMenu.animatorStandalone or StaffMenu.players
    local info = StaffMenu.PreparePlayerMenu(id, parentMenu, nil, isAnimatorCtx)
    if not info or not (info.source or info.identifier or info.id) then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur',
            message = "Impossible d'ouvrir le menu de ce joueur : ses données n'ont pas pu être chargées."
        })
        return
    end

    StaffMenu.player.open()
end

StaffMenu.OpenPlayerMenu = openPlayerOnAdminMenu

RegisterCommand("openplayer", function(source, args, rawCommand)
    if not VFW.PlayerData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["staff_menu"] then
        console.debug("Vous n'avez pas la permission d'utiliser le menu staff.")
        return
    end

    if not StaffMenu.adminChecked then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur',
            message = "Vous devez être en service pour utiliser cette commande."
      })
        return
    end

    openPlayerOnAdminMenu(tonumber(args[1]))
end, false)

-- ══════════════════════════════════
-- GIVE ITEM — sous-menu avec liste paginée
-- ══════════════════════════════════
local GIVE_ITEMS_PER_PAGE = 20

local restrictedItems = {
    potion_1 = true, potion_2 = true, potion_3 = true,
    potion_4 = true, potion_5 = true, potion_6 = true,
    potion_7 = true, potion_8 = true, potion_9 = true,
}

function StaffMenu.BuildPlayerGiveItemMenu()
    local menu = StaffMenu.playerGiveItem
    local data = StaffMenu.playerGiveItemData or {}

    -- Quantité
    local currentQty = data.selectedQuantity or 1
    menu.Button("QUANTITÉ", tostring(currentQty), nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité (1-1000)", tostring(currentQty))
        local qty = tonumber(input)
        if qty and qty >= 1 and qty <= 1000 then
            data.selectedQuantity = math.floor(qty)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Joueur', message = "Cette quantité n'est pas valide (1-1000)." })
        end
        menu.refresh()
    end)

    -- Recherche
    local firstLabel = data.itemQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = data.itemQuery == nil and "UN ITEM" or data.itemQuery

    menu.Button(firstLabel, lastLabel, nil, "search", false, function()
        if data.itemQuery ~= nil then
            data.itemQuery = nil
            data.currentPage = 1
            menu.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if query == nil or query == "" then return end

        data.itemQuery = query
        data.currentPage = 1
        menu.refresh()
    end)

    menu.Separator()

    -- Build filtered items list
    local filteredItems = {}
    for itemName, item in pairs(VFW.Items) do
        if not restrictedItems[itemName] and
           (not data.itemQuery or
           string.find(string.lower(itemName), string.lower(tostring(data.itemQuery))) or
           string.find(string.lower(item.label), string.lower(tostring(data.itemQuery)))) then
            table.insert(filteredItems, { name = itemName, data = item })
        end
    end

    table.sort(filteredItems, function(a, b)
        return a.data.label < b.data.label
    end)

    -- Pagination
    local totalItems = #filteredItems
    local totalPages = math.ceil(totalItems / GIVE_ITEMS_PER_PAGE)
    if totalPages == 0 then totalPages = 1 end

    data.currentPage = data.currentPage or 1
    if data.currentPage > totalPages then data.currentPage = totalPages end
    if data.currentPage < 1 then data.currentPage = 1 end

    local startIndex = (data.currentPage - 1) * GIVE_ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + GIVE_ITEMS_PER_PAGE - 1, totalItems)

    if totalPages > 1 then
        menu.Separator("Page " .. data.currentPage .. "/" .. totalPages, totalItems .. " items")

        if data.currentPage > 1 then
            menu.Button(":back: PAGE PRÉCÉDENTE", nil, nil, nil, false, function()
                data.currentPage = data.currentPage - 1
                menu.refresh()
            end)
        end
        if data.currentPage < totalPages then
            menu.Button("PAGE SUIVANTE :arrow:", nil, nil, nil, false, function()
                data.currentPage = data.currentPage + 1
                menu.refresh()
            end)
        end

        menu.Separator()
    end

    -- Items
    for i = startIndex, endIndex do
        local itemEntry = filteredItems[i]
        if itemEntry then
            local itemName = itemEntry.name
            local item = itemEntry.data

            menu.Button(item.label, itemName, item.weight .. " kg", "arrow", false, function()
                local qty = data.selectedQuantity or 1
                ExecuteCommand(("giveitem %s %s %s"):format(data.targetId, itemName, qty))
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = qty .. "x " .. item.label .. " donné." })
            end)
        end
    end

    if totalItems == 0 then
        menu.Separator("Aucun item", "trouvé")
    end
end

local licenseTypes = {
    { type = "car", label = "Permis Voiture" },
    { type = "motorcycle", label = "Permis Moto" },
    { type = "truck", label = "Permis Poids Lourd" },
}

local function normalizeLicenseMap(raw)
    if type(raw) ~= "table" then return {} end
    -- Déjà une map { car = true, ... }
    if raw.car ~= nil or raw.motorcycle ~= nil or raw.truck ~= nil then
        return {
            car = raw.car == true,
            motorcycle = raw.motorcycle == true,
            truck = raw.truck == true,
        }
    end
    -- Ancien format liste
    local out = {}
    for _, playerLic in ipairs(raw) do
        if type(playerLic) == "string" then
            out[playerLic] = true
        elseif type(playerLic) == "table" and type(playerLic.type) == "string" then
            out[playerLic.type] = true
        end
    end
    return out
end

function StaffMenu.FetchPlayerLicenses(targetSource, force)
    targetSource = tonumber(targetSource)
    if not targetSource then return {} end

    StaffMenu.data.licensesByPlayer = StaffMenu.data.licensesByPlayer or {}
    if not force and type(StaffMenu.data.licensesByPlayer[targetSource]) == "table" then
        return StaffMenu.data.licensesByPlayer[targetSource]
    end

    local ok, raw = pcall(TriggerServerCallback, "vfw:staff:getPlayerLicenses", targetSource)
    local map = normalizeLicenseMap(ok and raw or {})
    StaffMenu.data.licensesByPlayer[targetSource] = map
    return map
end

function StaffMenu.PrefetchPlayerLicenses(targetSource)
    targetSource = tonumber(targetSource)
    if not targetSource then return end
    CreateThread(function()
        StaffMenu.FetchPlayerLicenses(targetSource, true)
    end)
end

function StaffMenu.BuildPlayerLicenseMenu()
    local selectedPlayer = StaffMenu.data.selectedPlayer
    if not selectedPlayer then return end

    StaffMenu.data.licensesByPlayer = StaffMenu.data.licensesByPlayer or {}
    local licenses = StaffMenu.data.licensesByPlayer[selectedPlayer]
    -- Pas de wait serveur à l’ouverture : cache ou liste vide, puis sync en fond.
    if type(licenses) ~= "table" then
        licenses = {}
    end
    local hasAny = false

    for _, lic in ipairs(licenseTypes) do
        local alreadyHas = licenses[lic.type] == true
        local label = alreadyHas and (lic.label .. " :check:") or lic.label
        StaffMenu.playerLicense.Button(label, nil, nil, "arrow", alreadyHas, function()
            if alreadyHas then return end
            TriggerServerEvent("vfw:staff:giveLicense", selectedPlayer, lic.type)
            StaffMenu.data.licensesByPlayer = StaffMenu.data.licensesByPlayer or {}
            local cached = StaffMenu.data.licensesByPlayer[selectedPlayer] or {}
            cached[lic.type] = true
            StaffMenu.data.licensesByPlayer[selectedPlayer] = cached
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Joueur', message = "Permis " .. lic.label .. " attribué." })
            SetTimeout(200, function()
                if StaffMenu.playerLicense and StaffMenu.playerLicense.opened then
                    StaffMenu.playerLicense.refresh()
                end
            end)
        end)
        if not alreadyHas then hasAny = true end
    end

    if not hasAny then
        StaffMenu.playerLicense.Separator("Tous les permis sont attribués")
    end

    CreateThread(function()
        local fresh = StaffMenu.FetchPlayerLicenses(selectedPlayer, true)
        if StaffMenu.data.selectedPlayer ~= selectedPlayer then return end
        if not (StaffMenu.playerLicense and StaffMenu.playerLicense.opened) then return end
        local changed = false
        for _, lic in ipairs(licenseTypes) do
            if (licenses[lic.type] == true) ~= (fresh[lic.type] == true) then
                changed = true
                break
            end
        end
        if changed then
            StaffMenu.playerLicense.refresh()
        end
    end)
end
