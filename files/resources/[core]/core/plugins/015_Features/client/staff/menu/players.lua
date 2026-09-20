---@meta _
---@diagnostic disable: duplicate-doc-field

StaffMenu.playerQuery = StaffMenu.playerQuery or nil
StaffMenu.playerIndexMap = StaffMenu.playerIndexMap or {}
StaffMenu.playerPage = StaffMenu.playerPage or 1
local PLAYERS_PER_PAGE = 25

function StaffMenu.ResetPlayerSearchState()
    StaffMenu.playerQuery = nil
    StaffMenu.playerIndexMap = {}
    StaffMenu.playerPage = 1
end

--- .BuildPlayersMenu
---@return any
function StaffMenu.BuildPlayersMenu()
    local playerQuery = StaffMenu.playerQuery
    local firstLabel = playerQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = playerQuery == nil and "UN JOUEUR EN LIGNE" or playerQuery

    StaffMenu.playerIndexMap = {}
    local currentIndex = 1

    StaffMenu.players.Button(firstLabel, lastLabel, nil, "search", false, function()
        if playerQuery ~= nil then
            StaffMenu.playerQuery = nil
            StaffMenu.playerPage = 1
            StaffMenu.data.playerList = {}
            StaffMenu.data.playerList = TriggerServerCallback("vfw:staff:getPlayerList") or {}
            StaffMenu.players.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Entrez un ID / Prénom / Nom / Faction / Job")
        if query == nil or query == "" then
            return
        end

        StaffMenu.playerQuery = query
        StaffMenu.playerPage = 1
        StaffMenu.players.refresh()
    end)
    currentIndex = currentIndex + 1

    StaffMenu.players.Separator(nil)
    currentIndex = currentIndex + 1

    if next(StaffMenu.data.playerList) then
        local sortedPlayers = {}

        for _, v in pairs(StaffMenu.data.playerList) do
            table.insert(sortedPlayers, v)
        end

        table.sort(sortedPlayers, function(a, b)
            return a.source < b.source
        end)

        local filtered = {}
        if playerQuery and playerQuery ~= "" then
            for _, v in ipairs(sortedPlayers) do
                local q = playerQuery
                local pseudoMatch = v.pseudo and string.find(string.lower(v.pseudo), string.lower(q))
                local nameMatch = v.name and string.find(string.lower(v.name), string.lower(q))
                local idMatch = v.id and string.find(tostring(v.id), q)
                local sourceMatch = v.source and string.find(tostring(v.source), q)
                local crewMatch = v.crew and string.find(string.lower(v.crew), string.lower(q))
                local jobMatch = v.job and string.find(string.lower(v.job), string.lower(q))
                if pseudoMatch or nameMatch or idMatch or sourceMatch or crewMatch or jobMatch then
                    table.insert(filtered, v)
                end
            end
        else
            filtered = sortedPlayers
        end

        local totalItems = #filtered
        local totalPages = math.max(math.ceil(totalItems / PLAYERS_PER_PAGE), 1)
        if StaffMenu.playerPage > totalPages then StaffMenu.playerPage = totalPages end
        if StaffMenu.playerPage < 1 then StaffMenu.playerPage = 1 end
        local startIdx = (StaffMenu.playerPage - 1) * PLAYERS_PER_PAGE + 1
        local endIdx = math.min(startIdx + PLAYERS_PER_PAGE - 1, totalItems)

        local header
        if playerQuery then
            header = string.format("~ %d résultats, page %d sur %d ~", totalItems, StaffMenu.playerPage, totalPages)
        else
            header = string.format("~ %d joueurs en ligne, page %d sur %d ~", totalItems, StaffMenu.playerPage, totalPages)
        end
        StaffMenu.players.Separator(header)
        currentIndex = currentIndex + 1

        if totalItems == 0 then
            StaffMenu.players.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function() end)
            currentIndex = currentIndex + 1
            return
        end

        for idx = startIdx, endIdx do
            local v = filtered[idx]
            do
                local new = v.new and "[NEW] " or ""
              local displayPseudo = v.pseudo or "No Pseudo"

              StaffMenu.playerIndexMap[currentIndex] = v
                currentIndex = currentIndex + 1

                StaffMenu.players.Button(new .. displayPseudo, v.name or "Unknown", nil, nil, false, function()
                    StaffMenu.players.PlayerPreview()
                    StaffMenu.animatorPlayerContext = false

                    StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", v.source) or {}
                    StaffMenu.data.selectedPlayer = v.source
                    StaffMenu.data.warnsPlayerList = TriggerServerCallback("core:warn:getwarnsbydiscord", v.discord) or
                        {}
                    StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                        v.source, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}

                    local playerTitle = string.format("%s [%d]", StaffMenu.data.playerInfo.name or "Unknown", v.source)
                    local adminBanner = exports["core"]:GetVUIBanner("admin")
                    local VUI = exports["VUI"]

                    StaffMenu.player = VUI:CreateSubMenu(StaffMenu.players, playerTitle, adminBanner, true)

                    StaffMenu.wipe = VUI:CreateSubMenu(StaffMenu.player, "WIPE", adminBanner, true)
                    StaffMenu.items = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES ITEMS", adminBanner, true)
                    StaffMenu.AttachItemsMenuCallback()
                    StaffMenu.jobs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES JOBS", adminBanner, true)
                    StaffMenu.grades_jobs = VUI:CreateSubMenu(StaffMenu.jobs, "LISTE DES GRADES", adminBanner, true)
                    StaffMenu.factions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES FACTIONS", adminBanner, true)
                    StaffMenu.grades_factions = VUI:CreateSubMenu(StaffMenu.factions, "LISTE DES GRADES", adminBanner, true)
                    StaffMenu.vehs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES VÉHICULES", adminBanner, true)
                    StaffMenu.vehs_owned = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOUEUR", adminBanner, true)
                    StaffMenu.vehs_job = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOB", adminBanner, true)
                    StaffMenu.vehs_faction = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DE FACTION", adminBanner, true)
                    StaffMenu.vehicleActions = VUI:CreateSubMenu(StaffMenu.vehs_owned, "ACTIONS VÉHICULE", adminBanner, true)
                    StaffMenu.playerSanctions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES SANCTIONS", adminBanner, true)
                    StaffMenu.playerLicense = VUI:CreateSubMenu(StaffMenu.player, "DONNER UN PERMIS", adminBanner, true)
                    StaffMenu.playerGiveItem = VUI:CreateSubMenu(StaffMenu.player, "DONNER UN ITEM", adminBanner, true)
                    StaffMenu.playerSetRank = VUI:CreateSubMenu(StaffMenu.player, "CHANGER LE RANG", adminBanner, true)

                    StaffMenu.jobs.OnOpen(function()
                        StaffMenu.BuildJobsMenu()
                    end)
                    StaffMenu.grades_jobs.OnOpen(function()
                        StaffMenu.BuildGradesJobsMenu()
                    end)
                    StaffMenu.factions.OnOpen(function()
                        StaffMenu.BuildFactionsMenu()
                    end)
                    StaffMenu.grades_factions.OnOpen(function()
                        StaffMenu.BuildGradesFactionsMenu()
                    end)
                    StaffMenu.vehs.OnOpen(function()
                        StaffMenu.BuildVehsMenu()
                    end)

                    StaffMenu.vehs_owned.OnOpen(function()
                        StaffMenu.BuildVehsOwnedMenu()
                    end)

                    StaffMenu.vehs_job.OnOpen(function()
                        StaffMenu.BuildVehsJobMenu()
                    end)

                    StaffMenu.vehs_faction.OnOpen(function()
                        StaffMenu.BuildVehsFactionMenu()
                    end)
                    StaffMenu.vehicleActions.OnOpen(function()
                        StaffMenu.BuildVehicleActionsMenu()
                    end)
                    StaffMenu.player.OnOpen(function()
                        StaffMenu.BuildPlayerMenu()
                    end)

                    StaffMenu.playerSanctions.OnOpen(function()
                        StaffMenu.BuildPlayerSanctionsMenu()
                    end)
                    StaffMenu.playerLicense.OnOpen(function()
                        StaffMenu.BuildPlayerLicenseMenu()
                    end)
                    StaffMenu.playerGiveItem.OnOpen(function()
                        StaffMenu.playerGiveItem.ClearItems()
                        StaffMenu.BuildPlayerGiveItemMenu()
                    end)
                    StaffMenu.playerSetRank.OnOpen(function()
                        StaffMenu.BuildStaffRoleChangeMenu(StaffMenu.playerSetRank, "vfw:staff:setRankByLevel")
                    end)

                    StaffMenu.player.open()
                end)
            end
        end

        if totalPages > 1 then
            StaffMenu.players.Separator(nil)
            currentIndex = currentIndex + 1
            if StaffMenu.playerPage > 1 then
                StaffMenu.players.Button(":back: PAGE PRÉCÉDENTE", ("Aller à la page %d sur %d"):format(StaffMenu.playerPage - 1, totalPages), nil, "arrow", false, function()
                    StaffMenu.playerPage = StaffMenu.playerPage - 1
                    StaffMenu.players.PlayerPreview()
                    -- skipPlayerReset : empêche l'OnOpen de re-reset playerPage à 1
                    -- lors du refresh (close + open). Sans ce flag, le clic ne fait rien.
                    StaffMenu.skipPlayerReset = true
                    StaffMenu.players.refresh(true)
                end)
                currentIndex = currentIndex + 1
            end
            if StaffMenu.playerPage < totalPages then
                StaffMenu.players.Button("PAGE SUIVANTE :arrow:", ("Aller à la page %d sur %d"):format(StaffMenu.playerPage + 1, totalPages), nil, "arrow", false, function()
                    StaffMenu.playerPage = StaffMenu.playerPage + 1
                    StaffMenu.players.PlayerPreview()
                    -- skipPlayerReset : empêche l'OnOpen de re-reset playerPage à 1
                    -- lors du refresh (close + open). Sans ce flag, le clic ne fait rien.
                    StaffMenu.skipPlayerReset = true
                    StaffMenu.players.refresh(true)
                end)
                currentIndex = currentIndex + 1
            end
        end
    end
end

