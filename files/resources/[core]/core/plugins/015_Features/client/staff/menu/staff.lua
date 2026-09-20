---@meta _
---@diagnostic disable: duplicate-doc-field

local staffQuery = nil
local selectedStaff = nil

-- Lit la liste des rôles publiée par le serveur via GlobalState.staffRolesList
-- (cf. server/staff/main.lua → PublishRolesGlobalState).
local function getRolesList()
    return GlobalState.staffRolesList or {}
end

local function getRoleLabel(roleId)
    local list = getRolesList()
    return (list[roleId] and list[roleId].name) or roleId or "Inconnu"
end

--- .BuildStaffMenu
---@return any
function StaffMenu.BuildStaffMenu()
    local firstLabel = staffQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = staffQuery == nil and "UN STAFF" or staffQuery

    StaffMenu.staff.Button(firstLabel, lastLabel, nil, "search", false, function()
        if staffQuery ~= nil then
            staffQuery = nil
            StaffMenu.data.staffList = TriggerServerCallback("vfw:staff:getAllStaffFromDB") or {}
            StaffMenu.staff.refresh()
            return
        end

        staffQuery = VFW.Nui.KeyboardInput(true, "Entrez un rôle / Prénom / Nom")
        if staffQuery == nil or staffQuery == "" then
            return
        end

        StaffMenu.staff.refresh()
    end)

    StaffMenu.staff.Separator(nil)

    if next(StaffMenu.data.staffList) then
        for _, staff in ipairs(StaffMenu.data.staffList) do
            local displayName = staff.pseudo and (staff.pseudo .. " : " .. staff.globalId) or ("UUID: " .. staff.globalId)

            local roleLabel = getRoleLabel(staff.role)
            local statusLabel = staff.online and "En ligne" or "Hors ligne"
          local statusIcon = staff.online and "check" or nil

            local matchesQuery = true
            if staffQuery then
                local query = string.lower(staffQuery)
                local matchRole = string.find(string.lower(roleLabel), query)
                local matchName = string.find(string.lower(displayName), query)
                local matchId = string.find(tostring(staff.globalId), staffQuery)
                matchesQuery = matchRole or matchName or matchId
            end

            if matchesQuery then
                local rpNames = ""
              if staff.characters and #staff.characters > 0 then
                    local names = {}
                    for _, char in ipairs(staff.characters) do
                        table.insert(names, (char.firstname or "Inconnu") .. " " .. (char.lastname or ""))
                    end
                    rpNames = " • " .. table.concat(names, " / ")
                end
                local subtitle = string.format("[%s] UUID: %d - %s%s", roleLabel, staff.globalId, statusLabel, rpNames)

                StaffMenu.staff.Button(displayName, subtitle, nil, statusIcon, false, function()
                    selectedStaff = staff
                    StaffMenu.staffDetails.open()
                end)
            end
        end
    else
        StaffMenu.staff.Textbox("Aucun staff trouvé", "Info")
    end
end

--- .BuildStaffDetailsMenu
function StaffMenu.BuildStaffDetailsMenu()
    if not selectedStaff then
        StaffMenu.staffDetails.Textbox("Aucun staff sélectionné", "Erreur")
        return
    end

    local roleLabel = getRoleLabel(selectedStaff.role)

    -- Header: Bouton désactivé avec rôle + statut
    local statusLine = "UUID: " .. selectedStaff.globalId
    if selectedStaff.online and selectedStaff.source then
        statusLine = statusLine .. " • En ligne (ID: " .. selectedStaff.source .. ")"
  else
        statusLine = statusLine .. " • Hors ligne"
  end
    StaffMenu.staffDetails.Button(":police: " .. roleLabel, statusLine, nil, nil, false, function() end)

    -- Liste des personnages
    StaffMenu.staffDetails.Separator("PERSONNAGES")
    if selectedStaff.characters and #selectedStaff.characters > 0 then
        for _, char in ipairs(selectedStaff.characters) do
            local charName = (char.firstname or "Inconnu") .. " " .. (char.lastname or "")
            StaffMenu.staffDetails.Textbox(charName, nil)
        end
    else
        StaffMenu.staffDetails.Textbox("Aucun personnage", nil)
    end

    StaffMenu.staffDetails.Separator(nil)

    local hasPermission = VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["gestion_role"]
    if hasPermission then
        StaffMenu.staffDetails.Button(":mask: CHANGER LE RÔLE", roleLabel, nil, "chevron", false, function()
            local displayName = selectedStaff.pseudo or ("UUID: " .. selectedStaff.globalId)

            StaffMenu.data.roleChangeTarget = {
                globalId = selectedStaff.globalId,
                identifier = selectedStaff.identifier,
                role = selectedStaff.role,
                displayName = displayName
            }
            StaffMenu.staffRoleChange.open()
        end)
    end

    -- Si le joueur est en ligne, proposer d'ouvrir le menu joueur standard
    if selectedStaff.online and selectedStaff.source then
        StaffMenu.staffDetails.Button(":report: MENU JOUEUR COMPLET", "Ouvrir le menu joueur complet pour ce membre du staff en ligne", nil, "chevron", false, function()
            StaffMenu.PreparePlayerMenu(selectedStaff.source, StaffMenu.staffDetails, nil, false)
            StaffMenu.player.open()
        end)
    end
end

--- .BuildStaffRoleChangeMenu
--- Utilise StaffMenu.data.roleChangeTarget pour afficher le menu de changement de rôle
--- Cette fonction est appelée depuis le menu staff et depuis les outils de modération
function StaffMenu.BuildStaffRoleChangeMenu(menu, eventName)
    menu = menu or StaffMenu.staffRoleChange
    eventName = eventName or "vfw:staff:setPlayerRoleByIdentifier"
    local target = StaffMenu.data.roleChangeTarget
    if not target then
        menu.Textbox("Aucun joueur sélectionné", "Erreur")
        return
    end

    local myLevel = VFW.PlayerGlobalData.level or 0
    local currentRole = target.role or "user"
  local displayName = target.displayName or ("UUID: " .. (target.globalId or "?"))

    menu.Separator(":user: " .. displayName)
    menu.Separator("Rôle actuel: " .. getRoleLabel(currentRole))
    menu.Separator(nil)

    -- Liste des rôles disponibles (lue depuis GlobalState, triée par niveau croissant)
    local roles = {}
    for id, r in pairs(getRolesList()) do
        roles[#roles + 1] = { id = id, name = r.name or id, level = r.level or 0 }
    end
    table.sort(roles, function(a, b) return a.level < b.level end)

    for _, role in ipairs(roles) do
        local isCurrentRole = role.id == currentRole
        local canAssign = role.level <= myLevel
        local subtitle = "Niveau " .. role.level

        if isCurrentRole then
            subtitle = subtitle .. " (Actuel)"
      end

        menu.Button(role.name, subtitle, nil, isCurrentRole and "check" or "arrow", not canAssign, function()
            if isCurrentRole then
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Menu Staff', message = "Ce joueur a déjà ce rôle." })
                return
            end

            -- Utiliser l'identifier pour le changement (fonctionne même offline)
            TriggerServerEvent(eventName, target.identifier, role.id)
            -- Mettre à jour le rôle localement
            target.role = role.id
            menu.close()
        end)
    end
end

-- Enregistrer les handlers OnOpen
StaffMenu.staffDetails.OnOpen(function()
    StaffMenu.BuildStaffDetailsMenu()
end)

StaffMenu.staffRoleChange.OnOpen(function()
    StaffMenu.BuildStaffRoleChangeMenu(StaffMenu.staffRoleChange)
end)

StaffMenu.staffRoleChangeOutils.OnOpen(function()
    StaffMenu.BuildStaffRoleChangeMenu(StaffMenu.staffRoleChangeOutils)
end)

-- Handler pour mettre a jour le statut en ligne des staffs en temps reel
RegisterNetEvent("vfw:staff:staffOnlineUpdate", function(identifier, isOnline, playerSource)
    -- Mettre a jour la liste des staffs si elle existe
    if StaffMenu.data.staffList and #StaffMenu.data.staffList > 0 then
        for _, staff in ipairs(StaffMenu.data.staffList) do
            if staff.identifier == identifier then
                staff.online = isOnline
                staff.source = isOnline and playerSource or nil
                break
            end
        end

        -- Mettre a jour selectedStaff si c'est le meme staff
        if selectedStaff and selectedStaff.identifier == identifier then
            selectedStaff.online = isOnline
            selectedStaff.source = isOnline and playerSource or nil
        end

        -- Rafraichir le menu staff s'il est ouvert
        if StaffMenu.staff.opened then
            StaffMenu.staff.refresh()
        end

        -- Rafraichir le menu details staff s'il est ouvert
        if StaffMenu.staffDetails.opened then
            StaffMenu.staffDetails.refresh()
        end
    end
end)
