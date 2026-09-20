---@meta _
---@diagnostic disable: duplicate-doc-field

StaffMenu.offlineSearchQuery = nil
StaffMenu.offlinePlayersList = {}
StaffMenu.offlinePlayerIndexMap = {}
StaffMenu.selectedOfflinePlayer = nil
StaffMenu.offlineCurrentPage = 1
StaffMenu.offlineTotalCount = 0
StaffMenu.offlinePerPage = 25

local banTypeIndex = 1
local banTypes = { "Jours", "Heures", "Perm" }

function StaffMenu.ResetOfflineSearchState()
    StaffMenu.offlineSearchQuery = nil
    StaffMenu.offlinePlayersList = {}
    StaffMenu.offlinePlayerIndexMap = {}
    StaffMenu.selectedOfflinePlayer = nil
    StaffMenu.offlineCurrentPage = 1
    StaffMenu.offlineTotalCount = 0
end

function StaffMenu.RefreshOfflinePlayerData()
    if not StaffMenu.selectedOfflinePlayer then return end

    local playerId = StaffMenu.selectedOfflinePlayer.id

    CreateThread(function()
        local updatedPlayer = TriggerServerCallback("vfw:staff:getOfflinePlayerInfo", playerId)

        if updatedPlayer then
            StaffMenu.selectedOfflinePlayer = updatedPlayer
            StaffMenu.data.offlineSanctionsList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                updatedPlayer.onlineSource,
                updatedPlayer.identifier,
                updatedPlayer.discord) or {}

            if StaffMenu.offlinePlayerActions then
                StaffMenu._isRefreshingOffline = true
                StaffMenu.offlinePlayerActions.refresh()
                StaffMenu._isRefreshingOffline = false
            end

            SendNUIMessage({
                action = "staff:sanctions:update",
                data = StaffMenu.data.offlineSanctionsList
            })
        end
    end)
end

local function showOfflinePlayerPreview(playerData)
    if not playerData then
        StaffMenu.offlinePlayers.PlayerPreview()
        return
    end

    local statusText = playerData.isOnline and ":dot-green: EN LIGNE" or ":dot-red: HORS LIGNE"
  local tigStatus = playerData.hasTig and ":dot-orange: EN TIG" or "Aucun"
  local banStatus = playerData.isBanned and ":dot-red: BANNI" or "Non"
  local banIdText = playerData.activeBanId and tostring(playerData.activeBanId) or "-"

  local previewData = {
        { type = "header", iconUrl = "people.png",  label = "",             value = tostring(playerData.pseudo or "Sans pseudo") },
        { type = "body",   iconUrl = "data.png",    label = "UUID",         value = tostring(playerData.id or "?") },
        { type = "body",   iconUrl = "shield.png",  label = "Rôle",         value = tostring(playerData.role or "Joueur") },
        { type = "body",   iconUrl = "time.png",    label = "Temps de jeu", value = tostring(playerData.time or "00:00:00") },
        { type = "body",   iconUrl = "bank.png",    label = "Statut",       value = statusText },
        { type = "body",   iconUrl = "time.png",    label = "TIG",          value = tigStatus },
        { type = "body",   iconUrl = "blocked.png", label = "Banni",        value = banStatus },
        { type = "body",   iconUrl = "data.png",    label = "ID Ban",       value = banIdText },
    }

    local discordValue = playerData.discord and tostring(playerData.discord) or "Non relié"

  local stats = {
        { "ID Discord", discordValue },
        { "Nombre de sanctions reçues", playerData.sanctionsCount or 0 },
    }

    StaffMenu.offlinePlayers.PlayerPreview(nil, playerData.color or 0xFFFFFF, previewData, stats)
end

function StaffMenu.LoadAllOfflinePlayers(page)
    page = page or StaffMenu.offlineCurrentPage or 1
    StaffMenu.offlineCurrentPage = page
    local players, totalCount = TriggerServerCallback("vfw:staff:getAllOfflinePlayers", page)
    StaffMenu.offlinePlayersList = players or {}
    StaffMenu.offlineTotalCount = totalCount or 0
end

function StaffMenu.BuildOfflinePlayersMenu()
    StaffMenu.offlinePlayers.ClearItems()
    StaffMenu.offlinePlayerIndexMap = {}
    local currentIndex = 1

    local offlineSearchQuery = StaffMenu.offlineSearchQuery
    local searchLabel = offlineSearchQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = offlineSearchQuery == nil and "UN JOUEUR (UID / Pseudo / Nom)" or offlineSearchQuery

    StaffMenu.offlinePlayers.Button(searchLabel, searchValue, nil, "search", false, function()
        if offlineSearchQuery ~= nil then
            StaffMenu.offlineSearchQuery = nil
            StaffMenu.offlineCurrentPage = 1
            StaffMenu.LoadAllOfflinePlayers(1)
            StaffMenu.offlinePlayers.PlayerPreview()
            StaffMenu.offlinePlayers.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Recherche : UID, pseudo ou nom RP")
        if query == nil or query == "" then
            return
        end

        StaffMenu.offlineSearchQuery = query
        StaffMenu.offlineCurrentPage = 1
        StaffMenu.offlinePlayersList = TriggerServerCallback("vfw:staff:searchOfflinePlayers", query) or {}
        StaffMenu.offlinePlayers.refresh()
    end)
    currentIndex = currentIndex + 1

    StaffMenu.offlinePlayers.Separator(nil)
    currentIndex = currentIndex + 1

    local displayList = {}
    for _, player in ipairs(StaffMenu.offlinePlayersList or {}) do
        if not player.isOnline then
            table.insert(displayList, player)
        end
    end

    local totalPages = math.ceil(StaffMenu.offlineTotalCount / StaffMenu.offlinePerPage)
    if totalPages < 1 then totalPages = 1 end
    local currentPage = StaffMenu.offlineCurrentPage or 1

    if StaffMenu.offlineSearchQuery then
        local listTitle = "~ Résultats (" .. #displayList .. ") ~"
      if #displayList > 0 then
            StaffMenu.offlinePlayers.Separator(listTitle)
            currentIndex = currentIndex + 1
        end
    else
        local listTitle = "~ Joueurs Hors Ligne - Page " .. currentPage .. "/" .. totalPages .. " (" .. StaffMenu.offlineTotalCount .. " total) ~"
      StaffMenu.offlinePlayers.Separator(listTitle)
        currentIndex = currentIndex + 1
    end

    if #displayList > 0 then
        for _, player in ipairs(displayList) do
            local tigIcon = player.hasTig and "[TIG] " or ""
          local banIcon = player.isBanned and "[BAN] " or ""
          local displayName = banIcon .. tigIcon .. (player.pseudo or "Sans pseudo")

            StaffMenu.offlinePlayerIndexMap[currentIndex] = player
            currentIndex = currentIndex + 1

            StaffMenu.offlinePlayers.Button(displayName, "UUID #" .. player.id, nil, "chevron", false, function()
                StaffMenu.offlinePlayers.PlayerPreview()

                local chars = TriggerServerCallback("vfw:staff:getOfflinePlayerChars", player.id) or {}

                if #chars <= 1 then
                    StaffMenu._OpenOfflinePlayerActions(player, #chars == 1 and chars[1].id or nil)
                else
                    local adminBanner = exports["core"]:GetVUIBanner("admin")
                    local VUI = exports["VUI"]
                    StaffMenu.offlineCharSelect = VUI:CreateSubMenu(StaffMenu.offlinePlayers, "CHOISIR UN PERSONNAGE", adminBanner, true)

                    StaffMenu.offlineCharSelect.OnOpen(function()
                        StaffMenu.offlineCharSelect.ClearItems()
                        StaffMenu.offlineCharSelect.Separator(":user: PERSONNAGES DE " .. (player.pseudo or "ce compte"))
                        for _, char in ipairs(chars) do
                            StaffMenu.offlineCharSelect.Button(char.name, char.dateOfBirth, nil, "chevron", false, function()
                                StaffMenu._OpenOfflinePlayerActions(player, char.id)
                            end)
                        end
                    end)

                    if VUI_CurrentMenu and VUI_CurrentMenu.opened then
                        table.insert(VUI_MenuStack, { menu = VUI_CurrentMenu, savedIndex = VUI_CurrentMenu.index })
                        VUI_CurrentMenu._closeInternal()
                    end
                    VUI_CurrentMenu = StaffMenu.offlineCharSelect
                    StaffMenu.offlineCharSelect.open()
                end
            end)
        end

        if not StaffMenu.offlineSearchQuery and totalPages > 1 then
            StaffMenu.offlinePlayers.Separator(nil)
            currentIndex = currentIndex + 1

            if currentPage > 1 then
                StaffMenu.offlinePlayers.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (currentPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                    StaffMenu.LoadAllOfflinePlayers(currentPage - 1)
                    StaffMenu.offlinePlayers.PlayerPreview()
                    StaffMenu.BuildOfflinePlayersMenu()
                    if StaffMenu.offlinePlayers.opened then
                        StaffMenu.offlinePlayers.refresh()
                    end
                end)
                currentIndex = currentIndex + 1
            end

            if currentPage < totalPages then
                StaffMenu.offlinePlayers.Button("PAGE SUIVANTE :arrow:", "Page " .. (currentPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                    StaffMenu.LoadAllOfflinePlayers(currentPage + 1)
                    StaffMenu.offlinePlayers.PlayerPreview()
                    StaffMenu.BuildOfflinePlayersMenu()
                    if StaffMenu.offlinePlayers.opened then
                        StaffMenu.offlinePlayers.refresh()
                    end
                end)
                currentIndex = currentIndex + 1
            end
        end
    elseif StaffMenu.offlineSearchQuery then
        StaffMenu.offlinePlayers.Separator("~ Aucun résultat ~")
    else
        StaffMenu.offlinePlayers.Separator("~ Aucun joueur ~")
    end
end

function StaffMenu._OpenOfflinePlayerActions(player, charId)
    StaffMenu.selectedOfflinePlayer = TriggerServerCallback("vfw:staff:getOfflinePlayerInfo", player.id, charId)

    if not StaffMenu.selectedOfflinePlayer then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Joueurs Hors Ligne',
            message = "Impossible de récupérer les informations du joueur."
      })
        return
    end

    StaffMenu.data.offlineSanctionsList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
        StaffMenu.selectedOfflinePlayer.onlineSource,
        StaffMenu.selectedOfflinePlayer.identifier,
        StaffMenu.selectedOfflinePlayer.discord) or {}

    local adminBanner = exports["core"]:GetVUIBanner("admin")
    local VUI = exports["VUI"]
    local playerTitle = string.format("%s [UUID: %d]", StaffMenu.selectedOfflinePlayer.pseudo or "Inconnu", StaffMenu.selectedOfflinePlayer.id)

    StaffMenu.offlinePlayerActions = VUI:CreateSubMenu(StaffMenu.offlinePlayers, playerTitle, adminBanner, true)
    StaffMenu.offlinePlayerJobs = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LE JOB", adminBanner, true)
    StaffMenu.offlinePlayerJobGrades = VUI:CreateSubMenu(StaffMenu.offlinePlayerJobs, "CHOISIR LE GRADE", adminBanner, true)
    StaffMenu.offlinePlayerFactions = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LA FACTION", adminBanner, true)
    StaffMenu.offlinePlayerFactionGrades = VUI:CreateSubMenu(StaffMenu.offlinePlayerFactions, "CHOISIR LE GRADE", adminBanner, true)
    StaffMenu.offlinePlayerRoleChange = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LE RÔLE", adminBanner, true)
    StaffMenu.offlinePlayerSetRank = VUI:CreateSubMenu(StaffMenu.offlinePlayerActions, "CHANGER LE RANG", adminBanner, true)

    StaffMenu.offlinePlayerActions.OnOpen(function()
        StaffMenu.BuildOfflinePlayerActionsMenu()
    end)

    StaffMenu.offlinePlayerJobs.OnOpen(function()
        StaffMenu.BuildOfflinePlayerJobsMenu()
    end)

    StaffMenu.offlinePlayerJobGrades.OnOpen(function()
        StaffMenu.BuildOfflinePlayerJobGradesMenu()
    end)

    StaffMenu.offlinePlayerFactions.OnOpen(function()
        StaffMenu.BuildOfflinePlayerFactionsMenu()
    end)

    StaffMenu.offlinePlayerFactionGrades.OnOpen(function()
        StaffMenu.BuildOfflinePlayerFactionGradesMenu()
    end)

    StaffMenu.offlinePlayerRoleChange.OnOpen(function()
        StaffMenu.BuildOfflinePlayerRoleChangeMenu()
    end)

    StaffMenu.offlinePlayerSetRank.OnOpen(function()
        StaffMenu.BuildStaffRoleChangeMenu(StaffMenu.offlinePlayerSetRank, "vfw:staff:setRankByLevel")
    end)

    if VUI_CurrentMenu and VUI_CurrentMenu.opened then
        table.insert(VUI_MenuStack, { menu = VUI_CurrentMenu, savedIndex = VUI_CurrentMenu.index })
        VUI_CurrentMenu._closeInternal()
    end
    VUI_CurrentMenu = StaffMenu.offlinePlayerActions
    StaffMenu.offlinePlayerActions.open()
end

function StaffMenu.BuildOfflinePlayerActionsMenu()
    local player = StaffMenu.selectedOfflinePlayer
    if not player then return end

    local perms = VFW.StaffPerms()
    local statusText = player.isOnline and ":dot-green: EN LIGNE" or ":dot-red: HORS LIGNE"
  local tigStatus = player.hasTig and ":dot-orange: EN TIG" or "Aucun"
  local banStatus = player.isBanned and ":dot-red: BANNI" or "Non"
  local banIdText = player.activeBanId and tostring(player.activeBanId) or "-"

  local rpName = "Inconnu"
  if player.firstName and player.lastName then
        rpName = player.firstName .. " " .. player.lastName
    elseif player.name then
        rpName = player.name
    end

    local sanctionsCount = StaffMenu.data.offlineSanctionsList and #StaffMenu.data.offlineSanctionsList or 0

    local previewData = {
        { type = "header", iconUrl = "people.png",   label = "",                  value = tostring(player.pseudo or "Sans pseudo") },
        { type = "body",   iconUrl = "data.png",     label = "UUID",              value = tostring(player.id or "?") },
        { type = "body",   iconUrl = "shield.png",   label = "Rôle",              value = tostring(player.role or "Joueur") },
        { type = "body",   iconUrl = "time.png",     label = "Temps de jeu",      value = tostring(player.time or "00:00:00") },
        { type = "body",   iconUrl = "people.png",   label = "Nom Prénom RP",     value = tostring(rpName) },
        { type = "body",   iconUrl = "time.png",     label = "Date de naissance", value = tostring(player.dateOfBirth or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Taille",            value = tostring(player.height or "Non défini") },
        { type = "body",   iconUrl = "people.png",   label = "Sexe",              value = tostring(player.sex or "Inconnu") },
        { type = "body",   iconUrl = "job.png",      label = "Job 1",             value = tostring(player.jobFull or "Civil") },
        { type = "body",   iconUrl = "crew.png",     label = "Job 2 (Faction)",   value = tostring(player.factionFull or "Civil") },
        { type = "body",   iconUrl = "bank.png",     label = "Statut",            value = statusText },
        { type = "body",   iconUrl = "time.png",     label = "TIG",               value = tigStatus },
        { type = "body",   iconUrl = "blocked.png",  label = "Banni",             value = banStatus },
        { type = "body",   iconUrl = "data.png",     label = "ID Ban",            value = banIdText },
    }

    local discordValue = player.discord and tostring(player.discord) or "Non relié"

  local stats = {
        { "ID Discord", discordValue },
        { "Nombre de sanctions reçues", sanctionsCount },
    }

    StaffMenu.offlinePlayerActions.PlayerPreview(nil, player.color or 0xFFFFFF, previewData, stats)

    StaffMenu.offlinePlayerActions.Separator(":scales: SANCTIONS")

    StaffMenu.offlinePlayerActions.Button(":report: VOIR LES SANCTIONS", nil, nil, "chevron", false, function()
        local sanctionsData = TriggerServerCallback("vfw:staff:getPlayerSanctions", player.onlineSource, player.identifier, player.discord) or {}
        StaffMenu.data.sanctionsPlayerList = sanctionsData
        StaffMenu.data.selectedOfflinePlayerForSanctions = player

        VFW.Nui.Visible(true)
        SendNUIMessage({
            action = "staff:sanctions:open",
            data = {
                visible = true,
                targetPlayer = {
                    id = player.id,
                    source = player.onlineSource or 0,
                    name = player.name or "Inconnu",
                    identifier = player.identifier,
                    discord = player.discord,
                    online = player.isOnline or false
                },
                sanctions = sanctionsData,
                permissions = {
                    sanctions = perms["sanctions"] or false,
                    modify_sanctions = perms["modify_sanctions"] or false
                }
            }
        })
        VFW.Nui.Focus(true, false)
    end)

    if perms["ban_offline"] then
        StaffMenu.offlinePlayerActions.List2(":hammer: BANNIR", nil, false, banTypes, banTypeIndex, function(index)
            banTypeIndex = index
        end, function(index, item)
            local time
            local typeBan

            local reason = VFW.Nui.KeyboardInput(true, "Raison du ban", "")
            if not reason or reason == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions', message = "Vous devez entrer une raison." })
                return
            end

            if item == "Jours" then
                time = VFW.Nui.KeyboardInput(true, "Nombre de jours", "")
                typeBan = "jours"
          elseif item == "Heures" then
                time = VFW.Nui.KeyboardInput(true, "Nombre d'heures", "")
                typeBan = "heures"
          elseif item == "Perm" then
                time = 0
                typeBan = "perm"
          end

            if time ~= nil and time ~= "" then
                TriggerServerEvent("core:ban:banofflineplayer", player.id, reason, time, GetPlayerServerId(PlayerId()), typeBan)
                SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
            end
        end)
    end

    if perms["ban"] then
        StaffMenu.offlinePlayerActions.Button(":check: UNBAN", nil, nil, "chevron", false, function()
            local banId = VFW.Nui.KeyboardInput(true, "ID du ban à retirer")
            if banId and banId ~= "" then
                TriggerServerEvent("core:ban:unbanplayer", banId)
                SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
            end
        end)
    end

    if perms["give_tig"] then
        StaffMenu.offlinePlayerActions.Button(":hammer: DONNER DES TIG", nil, nil, "chevron", false, function()
            local amount = VFW.Nui.KeyboardInput(true, "Nombre de TIG (1-300)", "")
            if not amount or not tonumber(amount) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions', message = "Ce nombre n'est pas valide." })
                return
            end

            amount = tonumber(amount)
            if amount < 1 or amount > 300 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions', message = "Le nombre de TIG doit être entre 1 et 300." })
                return
            end

            local reason = VFW.Nui.KeyboardInput(true, "Raison des TIG", "")
            if not reason or reason == "" then
                reason = "Aucune raison spécifiée"
          end

            TriggerServerEvent("vfw:admin:giveTIGOffline", player.id, amount, reason)
            SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
        end)
    end

    if perms["remove_tig"] then
        StaffMenu.offlinePlayerActions.Button(":unlock: RETIRER LES TIG", nil, nil, "chevron", false, function()
            TriggerServerEvent("vfw:admin:removeTIGOffline", player.id)
            SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
        end)
    end

    if perms["wipe"] then
        StaffMenu.offlinePlayerActions.Button(":trash: WIPE OFFLINE", nil, nil, "chevron", false, function()
            StaffMenu.data.selectedGlobalId = player.id
            StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getOfflineCharList", player.id)

            if not StaffMenu.data.charList or not StaffMenu.data.charList.charList or #StaffMenu.data.charList.charList == 0 then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe',
                    message = "Aucun personnage trouvé pour ce joueur."
              })
                return
            end

            StaffMenu.wipeOffline.open()
        end)
    end

    if perms["gestion_role"] or perms["setjob"] or perms["setjob2"] or (VFW.PlayerGlobalData.level or 0) >= 5 then
        StaffMenu.offlinePlayerActions.Separator(":mask: GESTION")
    end

    if perms["gestion_role"] then
        StaffMenu.offlinePlayerActions.Button(":mask: CHANGER LE RÔLE", "Rôle actuel: " .. (player.role or "Joueur"), nil, "chevron", false, function()
            StaffMenu.data.roleChangeTarget = player
        end, StaffMenu.offlinePlayerRoleChange)
    end

    if perms["setjob"] then
        StaffMenu.offlinePlayerActions.Button(":briefcase: CHANGER LE JOB", "Job actuel: " .. (player.jobFull or "Civil"), nil, "chevron", false, function()
            StaffMenu.data.jobsList = TriggerServerCallback("vfw:staff:getJobs") or {}
        end, StaffMenu.offlinePlayerJobs)
    end

    -- Changement de rang réservé aux Gérants Staff (niveau 5+)
    if (VFW.PlayerGlobalData.level or 0) >= 5 and StaffMenu.offlinePlayerSetRank then
        StaffMenu.offlinePlayerActions.Button(":mask: CHANGER LE RANG", "Rang actuel: " .. (player.role or "Joueur"), nil, "chevron", false, function()
            StaffMenu.data.roleChangeTarget = {
                globalId = player.id,
                identifier = player.identifier,
                role = player.role,
                displayName = player.pseudo or ("UUID: " .. tostring(player.id))
            }
        end, StaffMenu.offlinePlayerSetRank)
    end

    if perms["setjob2"] then
        StaffMenu.offlinePlayerActions.Button(":flag: CHANGER LA FACTION", "Faction actuelle: " .. (player.factionFull or "Civil"), nil, "chevron", false, function()
            StaffMenu.data.factionsList = TriggerServerCallback("core:staff:getOrganizations") or {}
        end, StaffMenu.offlinePlayerFactions)
    end
end

function StaffMenu.BuildOfflinePlayerJobsMenu()
    local player = StaffMenu.selectedOfflinePlayer
    if not player then return end

    local jobs = StaffMenu.data.jobsList or {}

    StaffMenu.offlinePlayerJobs.Separator(":briefcase: CHOISIR UN JOB")

    for jobName, jobData in pairs(jobs) do
        local isCurrentJob = player.job == jobData.label
        local label = isCurrentJob and (jobData.label .. " :check:") or jobData.label

        StaffMenu.offlinePlayerJobs.Button(label, nil, nil, "chevron", isCurrentJob, function()
            StaffMenu.data.selectedJobName = jobName
            StaffMenu.data.selectedJobData = jobData
        end, StaffMenu.offlinePlayerJobGrades)
    end
end

function StaffMenu.BuildOfflinePlayerJobGradesMenu()
    local player = StaffMenu.selectedOfflinePlayer
    local jobName = StaffMenu.data.selectedJobName
    local jobData = StaffMenu.data.selectedJobData

    if not player or not jobName or not jobData then return end

    StaffMenu.offlinePlayerJobGrades.Separator(":chart: CHOISIR UN GRADE")

    for gradeId, gradeData in pairs(jobData.grades or {}) do
        StaffMenu.offlinePlayerJobGrades.Button(gradeData.label or gradeData.name, "Grade " .. gradeId, nil, "arrow", false, function()
            TriggerServerEvent("vfw:staff:setJobOffline", player.id, jobName, tonumber(gradeId))
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Hors Ligne', message = "Job changé: " .. (jobData.label or jobName) .. " - " .. (gradeData.label or gradeData.name) })
            StaffMenu.offlinePlayerJobGrades.close()
            StaffMenu.offlinePlayerJobs.close()
            SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
        end)
    end
end

function StaffMenu.BuildOfflinePlayerFactionsMenu()
    local player = StaffMenu.selectedOfflinePlayer
    if not player then return end

    local factions = StaffMenu.data.factionsList or {}

    StaffMenu.offlinePlayerFactions.Separator(":flag: CHOISIR UNE FACTION")

    StaffMenu.offlinePlayerFactions.Button("Aucune faction", "Retirer de la faction", nil, "arrow", false, function()
        TriggerServerEvent("vfw:staff:setFactionOffline", player.id, "nocrew", 0)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Hors Ligne', message = "Faction retirée." })
        StaffMenu.offlinePlayerFactions.close()
        SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
    end)

    for _, factionData in pairs(factions) do
        local isCurrentFaction = player.faction == factionData.label
        local label = isCurrentFaction and (factionData.label .. " :check:") or factionData.label

        StaffMenu.offlinePlayerFactions.Button(label, nil, nil, "chevron", false, function()
            StaffMenu.data.selectedFactionName = factionData.name
            StaffMenu.data.selectedFactionData = factionData
        end, StaffMenu.offlinePlayerFactionGrades)
    end
end

function StaffMenu.BuildOfflinePlayerFactionGradesMenu()
    local player = StaffMenu.selectedOfflinePlayer
    local factionName = StaffMenu.data.selectedFactionName
    local factionData = StaffMenu.data.selectedFactionData

    if not player or not factionName or not factionData then return end

    StaffMenu.offlinePlayerFactionGrades.Separator(":chart: CHOISIR UN GRADE")

    local grades = factionData.grades or {}

    for gradeId, gradeData in pairs(grades) do
        StaffMenu.offlinePlayerFactionGrades.Button(gradeData.label or gradeData.name, "Grade " .. gradeId, nil, "arrow", false, function()
            TriggerServerEvent("vfw:staff:setFactionOffline", player.id, factionName, tonumber(gradeId))
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Hors Ligne', message = "Faction changée: " .. (factionData.label or factionName) .. " - " .. (gradeData.label or gradeData.name) })
            StaffMenu.offlinePlayerFactionGrades.close()
            StaffMenu.offlinePlayerFactions.close()
            SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
        end)
    end
end

function StaffMenu.BuildOfflinePlayerRoleChangeMenu()
    local player = StaffMenu.selectedOfflinePlayer
    if not player then return end

    local roles, discordList = TriggerServerCallback("vfw:staff:getRoles")
    roles = roles or {}
    discordList = discordList or {}

    StaffMenu.offlinePlayerRoleChange.Separator(":mask: CHOISIR UN RÔLE")

    local rolesList = {}
    for roleId, roleData in pairs(roles) do
        local roleName = roleId
        for i = 1, #discordList do
            if discordList[i].id == roleId then
                roleName = discordList[i].name
                break
            end
        end
        table.insert(rolesList, {
            id = roleId,
            label = roleName,
            level = roleData.level or 0
        })
    end

    table.sort(rolesList, function(a, b)
        return (a.level or 0) < (b.level or 0)
    end)

    for _, roleData in ipairs(rolesList) do
        local isCurrentRole = player.role == roleData.id
        local label = isCurrentRole and (roleData.label .. " :check:") or roleData.label

        StaffMenu.offlinePlayerRoleChange.Button(label, "", nil, "arrow", false, function()
            TriggerServerEvent("vfw:staff:setRoleOffline", player.id, roleData.id)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Hors Ligne', message = "Rôle changé: " .. roleData.label })
            StaffMenu.offlinePlayerRoleChange.close()
            SetTimeout(500, StaffMenu.RefreshOfflinePlayerData)
        end)
    end
end
