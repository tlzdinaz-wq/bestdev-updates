local VUI = exports["VUI"]

local banner = VFW.CDN.Get("banners/laboratoire.png")
local mgmtMenu = VUI:CreateMenu("Gestion du Labo", banner, true)
local factionListMenu = VUI:CreateSubMenu(mgmtMenu, "Accès factions", banner, true)
local addFactionMenu = VUI:CreateSubMenu(factionListMenu, "Ajouter une faction", banner, true)
local factionDetailMenu = VUI:CreateSubMenu(factionListMenu, "Détails faction", banner, true)
local memberListMenu = VUI:CreateSubMenu(mgmtMenu, "Membres faction", banner, true)
local memberDetailMenu = VUI:CreateSubMenu(memberListMenu, "Détails membre", banner, true)
local playerListMenu = VUI:CreateSubMenu(mgmtMenu, "Accès joueurs", banner, true)
local addPlayerMenu = VUI:CreateSubMenu(playerListMenu, "Ajouter un joueur", banner, true)
local playerDetailMenu = VUI:CreateSubMenu(playerListMenu, "Détails joueur", banner, true)
local statsMenu = VUI:CreateSubMenu(mgmtMenu, "Statistiques", banner, true)
local transferMenu = VUI:CreateSubMenu(mgmtMenu, "Transférer la propriété", banner, true)

local currentLaboId = nil

local function renderMainMenu()
    local accessList = TriggerServerCallback("labo:getAccessList", currentLaboId) or {}

    local factionCount = 0
    local playerCount = 0
    for _, access in ipairs(accessList) do
        if access.access_type == "faction" then
            factionCount = factionCount + 1
        elseif access.access_type == "player" then
            playerCount = playerCount + 1
        end
    end

    mgmtMenu.Button(":users: Accès factions", tostring(factionCount) .. (factionCount > 1 and " factions" or " faction"), nil, "chevron", false, function()
    end, factionListMenu)

    mgmtMenu.Button(":user: Membres faction", "Gérer les accès", nil, "chevron", false, function()
    end, memberListMenu)

    mgmtMenu.Button(":user: Accès joueurs externes", tostring(playerCount) .. (playerCount > 1 and " joueurs" or " joueur"), nil, "chevron", false, function()
    end, playerListMenu)

    mgmtMenu.Button(":chart: Statistiques", "Récoltes, transformations", nil, "chevron", false, function()
    end, statsMenu)

    mgmtMenu.Separator(":warning: Danger")

    mgmtMenu.Button(":refresh: Transférer la propriété", nil, nil, "arrow", false, function()
    end, transferMenu)
end

local function renderFactionListMenu()
    local accessList = TriggerServerCallback("labo:getAccessList", currentLaboId) or {}

    local factionAccesses = {}
    for _, access in ipairs(accessList) do
        if access.access_type == "faction" then
            table.insert(factionAccesses, access)
        end
    end

    for _, access in ipairs(factionAccesses) do
        local factionLabel = access.faction_label or access.faction_name
        local chestLabel = access.chest_access == 1 and ":box: Coffre: Oui" or ":box: Coffre: Non"

       local accessId = access.id
        factionListMenu.Button(":users: " .. factionLabel, chestLabel, nil, "chevron", false, function()
            factionDetailMenu.OnOpen(function()
                renderFactionDetail(accessId, factionLabel)
            end)
        end, factionDetailMenu)
    end

    if #factionAccesses == 0 then
        factionListMenu.Button("Aucune faction", nil, "0", nil, false, function() end)
    end

    factionListMenu.Separator("")

    factionListMenu.Button(":plus: Ajouter une faction", nil, nil, "arrow", false, function()
    end, addFactionMenu)
end

function renderFactionDetail(accessId, factionLabel)
    local accessList = TriggerServerCallback("labo:getAccessList", currentLaboId) or {}
    local access = nil
    for _, a in ipairs(accessList) do
        if a.id == accessId then
            access = a
            break
        end
    end
    if not access then return end

    local chestLabel = access.chest_access == 1 and "Oui" or "Non"

   factionDetailMenu.Button(":box: Accès coffre: " .. chestLabel, "Basculer l'accès", nil, nil, false, function()
        TriggerServerCallback("labo:toggleChestAccess", accessId)
        factionDetailMenu.refresh()
    end)

    factionDetailMenu.Button(":x: Retirer l'accès", nil, nil, "trash", false, function()
        local confirm = VFW.Nui.ChoiceInput(
            "Retirer " .. factionLabel,
            "Voulez-vous vraiment retirer l'accès de cette faction ?",
            {
                { label = "Confirmer", value = "yes" },
                { label = "Annuler", value = "no" }
            }
        )
        if confirm == "yes" then
            TriggerServerCallback("labo:removeAccess", accessId)
            exports["VUI"]:HandleBack()
            factionListMenu.refresh()
        end
    end)
end

local function renderMemberDetail(member)
    local chestLabel = member.chestAccess and "Oui" or "Non"
   local mgmtLabel = member.managementAccess and "Oui" or "Non"

   memberDetailMenu.Button(":box: Accès coffre: " .. chestLabel, nil, nil, nil, false, function()
        TriggerServerCallback("labo:toggleMemberPerm", currentLaboId, member.identifier, member.name, "chest")
        memberDetailMenu.refresh()
    end)

    memberDetailMenu.Button(":wrench: Accès gestion: " .. mgmtLabel, nil, nil, nil, false, function()
        TriggerServerCallback("labo:toggleMemberPerm", currentLaboId, member.identifier, member.name, "management")
        memberDetailMenu.refresh()
    end)
end

local function renderMemberListMenu()
    local members = TriggerServerCallback("labo:getFactionMembers", currentLaboId) or {}

    for _, member in ipairs(members) do
        local chestLabel = member.chestAccess and ":box:" or ""
       local mgmtLabel = member.managementAccess and ":wrench:" or ""
       local badges = chestLabel .. mgmtLabel
        local roleText = member.role or ("Grade " .. (member.grade or 0))
        local subtitle = (badges ~= "" and badges .. " " or "") .. roleText

        local m = member
        memberListMenu.Button(":user: " .. member.name, subtitle, nil, "chevron", false, function()
            memberDetailMenu.OnOpen(function()
                local freshMembers = TriggerServerCallback("labo:getFactionMembers", currentLaboId) or {}
                for _, fm in ipairs(freshMembers) do
                    if fm.identifier == m.identifier then
                        m = fm
                        break
                    end
                end
                renderMemberDetail(m)
            end)
        end, memberDetailMenu)
    end

    if #members == 0 then
        memberListMenu.Button("Aucun membre", nil, nil, nil, true, function() end)
    end
end

local function renderPlayerListMenu()
    local accessList = TriggerServerCallback("labo:getAccessList", currentLaboId) or {}

    local playerAccesses = {}
    for _, access in ipairs(accessList) do
        if access.access_type == "player" then
            table.insert(playerAccesses, access)
        end
    end

    for _, access in ipairs(playerAccesses) do
        local displayName = access.player_name or "Inconnu"
       local chestLabel = access.chest_access == 1 and ":box:" or ""
       local mgmtLabel = access.management_access == 1 and ":wrench:" or ""
       local badges = chestLabel .. mgmtLabel

        local accessId = access.id
        playerListMenu.Button(":user: " .. displayName, badges ~= "" and badges or nil, nil, "chevron", false, function()
            playerDetailMenu.OnOpen(function()
                renderPlayerDetail(accessId, displayName)
            end)
        end, playerDetailMenu)
    end

    if #playerAccesses == 0 then
        playerListMenu.Button("Aucun joueur externe", nil, nil, nil, true, function() end)
    end

    playerListMenu.Separator("")

    playerListMenu.Button(":plus: Ajouter un joueur à proximité", nil, nil, "arrow", false, function()
    end, addPlayerMenu)
end

function renderPlayerDetail(accessId, displayName)
    local accessList = TriggerServerCallback("labo:getAccessList", currentLaboId) or {}
    local access = nil
    for _, a in ipairs(accessList) do
        if a.id == accessId then
            access = a
            break
        end
    end
    if not access then return end

    local chestLabel = access.chest_access == 1 and "Oui" or "Non"
   local mgmtLabel = access.management_access == 1 and "Oui" or "Non"

   playerDetailMenu.Button(":box: Accès coffre: " .. chestLabel, "Basculer l'accès", nil, nil, false, function()
        TriggerServerCallback("labo:toggleChestAccess", accessId)
        playerDetailMenu.refresh()
    end)

    playerDetailMenu.Button(":wrench: Accès gestion: " .. mgmtLabel, "Basculer l'accès", nil, nil, false, function()
        TriggerServerCallback("labo:toggleManagementAccess", accessId)
        playerDetailMenu.refresh()
    end)

    playerDetailMenu.Button(":x: Retirer l'accès", nil, nil, "trash", false, function()
        local confirm = VFW.Nui.ChoiceInput(
            "Retirer " .. displayName,
            "Voulez-vous vraiment retirer l'accès de ce joueur ?",
            {
                { label = "Confirmer", value = "yes" },
                { label = "Annuler", value = "no" }
            }
        )
        if confirm == "yes" then
            TriggerServerCallback("labo:removeAccess", accessId)
            exports["VUI"]:HandleBack()
            playerListMenu.refresh()
        end
    end)
end

local function renderAddFactionMenu()
    local factions = TriggerServerCallback("labo:getFactions") or {}

    addFactionMenu.Separator(":users: Choisir une faction")

    for _, faction in ipairs(factions) do
        addFactionMenu.Button(":users: " .. faction.label, nil, nil, nil, false, function()
            local chestChoice = VFW.Nui.ChoiceInput(
                "Accès coffre",
                "Donner accès au coffre du labo ?",
                {
                    { label = "Oui", value = "yes" },
                    { label = "Non", value = "no" }
                }
            )
            if not chestChoice then return end

            local chestAccess = chestChoice == "yes"
           local success = TriggerServerCallback("labo:addFactionAccess", currentLaboId, faction.name, chestAccess)
            if success then
                VFW.ShowNotification({ type = "VERT", content = "Faction ajoutée" })
            else
                VFW.ShowNotification({ type = "ROUGE", content = "Impossible d'ajouter cette faction" })
            end
            exports["VUI"]:HandleBack()
            factionListMenu.refresh()
        end)
    end
end

local function renderAddPlayerMenu()
    local nearby = TriggerServerCallback("labo:getNearbyPlayers", currentLaboId) or {}

    addPlayerMenu.Separator("Le joueur doit être devant la porte du labo")

    if #nearby == 0 then
        addPlayerMenu.Button("Aucun joueur à proximité", nil, nil, nil, true, function() end)
    else
        for _, p in ipairs(nearby) do
            addPlayerMenu.Button(":user: " .. p.name, "ID: " .. p.serverId, nil, "arrow", false, function()
                local chestChoice = VFW.Nui.ChoiceInput(
                    "Accès coffre",
                    "Donner accès au coffre du labo à " .. p.name .. " ?",
                    {
                        { label = "Oui", value = "yes" },
                        { label = "Non", value = "no" }
                    }
                )
                if not chestChoice then return end

                local chestAccess = chestChoice == "yes"
               local success, reason = TriggerServerCallback("labo:addPlayerAccess", currentLaboId, p.serverId, chestAccess)
                if success then
                    VFW.ShowNotification({ type = "VERT", content = "Joueur ajouté" })
                else
                    VFW.ShowNotification({ type = "ROUGE", content = reason or "Joueur introuvable ou déjà ajouté" })
                end
                exports["VUI"]:HandleBack()
                playerListMenu.refresh()
            end)
        end
    end
end

local function renderTransferMenu()
    local factions = TriggerServerCallback("labo:getFactions") or {}
    local myFaction = VFW.PlayerData.faction and VFW.PlayerData.faction.name

    transferMenu.Separator(":trophy: Choisir la nouvelle faction")

    for _, faction in ipairs(factions) do
        if faction.name ~= myFaction then
        transferMenu.Button(":users: " .. faction.label, nil, nil, nil, false, function()
            local confirm = VFW.Nui.ChoiceInput(
                "Transférer à " .. faction.label,
                "Tous les accès seront supprimés et vous serez expulsé du labo. Continuer ?",
                {
                    { label = "Confirmer", value = "yes" },
                    { label = "Annuler", value = "no" }
                }
            )
            if confirm == "yes" then
                local success = TriggerServerCallback("labo:transferOwnership", currentLaboId, faction.name)
                if success then
                    VFW.ShowNotification({ type = "VERT", content = "Propriété transférée" })
                    mgmtMenu.close()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = "Impossible de transférer" })
                end
            end
        end)
        end
    end
end

local function getItemLabel(itemName)
    if not itemName then return "Inconnu" end
    local item = VFW.Items and VFW.Items[itemName]
    return item and item.label or itemName
end

local function renderStatsMenu()
    local stats = TriggerServerCallback("labo:getStats", currentLaboId)
    if not stats then
        statsMenu.Button("Impossible de charger les statistiques", nil, nil, nil, true, function() end)
        return
    end

    statsMenu.Separator(":leaf: Récoltes")
    statsMenu.Button("Total", nil, tostring(stats.harvestTotal), nil, false, function() end)
    statsMenu.Button("Dernières 24h", nil, tostring(stats.harvest24h), nil, false, function() end)

    statsMenu.Separator(":flask: Transformations")
    statsMenu.Button("Total", nil, tostring(stats.transformTotal), nil, false, function() end)
    statsMenu.Button("Dernières 24h", nil, tostring(stats.transform24h), nil, false, function() end)
end

mgmtMenu.OnOpen(function()
    renderMainMenu()
end)

factionListMenu.OnOpen(function()
    renderFactionListMenu()
end)

memberListMenu.OnOpen(function()
    renderMemberListMenu()
end)

playerListMenu.OnOpen(function()
    renderPlayerListMenu()
end)

addFactionMenu.OnOpen(function()
    renderAddFactionMenu()
end)

addPlayerMenu.OnOpen(function()
    renderAddPlayerMenu()
end)

transferMenu.OnOpen(function()
    renderTransferMenu()
end)

statsMenu.OnOpen(function()
    renderStatsMenu()
end)

AddEventHandler("labo:openManagement", function(laboId)
    currentLaboId = laboId
    mgmtMenu.open()
end)
