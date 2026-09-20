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
            StaffMenu.data.playerList = StaffMenu.FetchPlayerList(true) or {}
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
                    -- Zéro yield ici : le sous-menu s'ouvre tout de suite.
                    -- Préparation + build dans player.OnOpen (données déjà en cache).
                    StaffMenu._pendingPlayerRow = v
                    StaffMenu.animatorPlayerContext = false
                    StaffMenu.data.selectedPlayer = v.source
                end, StaffMenu.player)
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

