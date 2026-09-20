local VUI <const> = exports["VUI"]
local adminBanner <const> = exports["core"]:GetVUIBanner("admin")

StaffMenu.builderElections = VUI:CreateSubMenu(StaffMenu.builders, "VOTE", adminBanner, true)
StaffMenu.builderElectionCreate = VUI:CreateSubMenu(StaffMenu.builderElections, "CREER UN VOTE", adminBanner, true)
StaffMenu.builderElectionManage = VUI:CreateSubMenu(StaffMenu.builderElections, "GERER", adminBanner, true)
StaffMenu.builderElectionDetail = VUI:CreateSubMenu(StaffMenu.builderElectionManage, "DETAIL VOTE", adminBanner, true)
StaffMenu.builderElectionResults = VUI:CreateSubMenu(StaffMenu.builderElectionDetail, "RESULTATS", adminBanner, true)
StaffMenu.builderElectionPoints = VUI:CreateSubMenu(StaffMenu.builderElectionDetail, "POINTS DE VOTE", adminBanner, true)

local createData = {
    name = nil,
    description = nil,
    proposals = {},
    points = {},
    durationHours = nil,
}

local function ResetCreateData()
    createData = { name = nil, description = nil, proposals = {}, points = {}, durationHours = nil }
end

local selectedElectionId = nil
local cachedElections = nil
local LoadElectionZones

local function IsActiveFlag(val)
    if type(val) == "boolean" then return val end
    return tonumber(val) == 1
end

local function FormatTimeRemaining(remainingSeconds)
    if not remainingSeconds then return nil end
    local diff = tonumber(remainingSeconds)
    if not diff or diff <= 0 then return "Termine" end
    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)
    if hours > 0 then
        return hours .. "h " .. mins .. "min restantes"
  end
    return mins .. "min restantes"
end

StaffMenu.builderElections.OnOpen(function()
    StaffMenu.builderElections.ClearItems()
    cachedElections = nil

    StaffMenu.builderElections.Button(":plus: CRÉER UN VOTE", "Créer un nouveau scrutin", nil, "chevron", false, function()
        ResetCreateData()
    end, StaffMenu.builderElectionCreate)

    StaffMenu.builderElections.Button(":report: GÉRER LES VOTES", "Voir et gérer les votes existants", nil, "chevron", false, function() end, StaffMenu.builderElectionManage)
end)

StaffMenu.builderElectionCreate.OnOpen(function()
    StaffMenu.builderElectionCreate.ClearItems()

    StaffMenu.builderElectionCreate.Separator("Informations")

    StaffMenu.builderElectionCreate.Button(
        createData.name and (":check: Nom: " .. createData.name) or ":edit: DÉFINIR LE NOM",
        "Nom du vote",
        nil, "check", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du vote")
            if input and input ~= "" then
                createData.name = input
                StaffMenu.builderElectionCreate.refresh()
            end
        end
    )

    StaffMenu.builderElectionCreate.Button(
        createData.description and (":check: Description: " .. string.sub(createData.description, 1, 40) .. (string.len(createData.description) > 40 and "..." or "")) or ":edit: DÉFINIR LA DESCRIPTION",
        "Texte affiché aux votants",
        nil, "check", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Description/texte du vote")
            if input and input ~= "" then
                createData.description = input
                StaffMenu.builderElectionCreate.refresh()
            end
        end
    )

    StaffMenu.builderElectionCreate.Button(
        createData.durationHours and (":clock: Durée: " .. createData.durationHours .. "h") or ":clock: DÉFINIR LA DURÉE (optionnel)",
        "Nombre d'heures avant fermeture automatique (vide = illimité)",
        nil, "clock", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Durée en heures (ex: 24, 48, 72)")
            if input and input ~= "" then
                local hours = tonumber(input)
                if hours and hours > 0 then
                    createData.durationHours = hours
                else
                    VFW.ShowNotification({ type = "ROUGE", content = "Ce nombre d'heures n'est pas valide" })
                end
            else
                createData.durationHours = nil
            end
            StaffMenu.builderElectionCreate.refresh()
        end
    )

    StaffMenu.builderElectionCreate.Separator("Propositions (" .. #createData.proposals .. ")")

    StaffMenu.builderElectionCreate.Button(
        ":plus: AJOUTER UNE PROPOSITION",
        "Ajouter un choix de vote",
        nil, "check", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Texte de la proposition")
            if input and input ~= "" then
                createData.proposals[#createData.proposals + 1] = input
                StaffMenu.builderElectionCreate.refresh()
            end
        end
    )

    for i, proposal in ipairs(createData.proposals) do
        StaffMenu.builderElectionCreate.Button(
            "#" .. i .. " - " .. proposal,
            "Cliquer pour supprimer",
            nil, "trash", false,
            function()
                table.remove(createData.proposals, i)
                StaffMenu.builderElectionCreate.refresh()
            end
        )
    end

    StaffMenu.builderElectionCreate.Separator("Points de vote (" .. #createData.points .. ")")

    StaffMenu.builderElectionCreate.Button(
        ":pin: AJOUTER MA POSITION",
        "Ajouter un point de vote à ma position actuelle",
        nil, "check", false,
        function()
            local coords = GetEntityCoords(PlayerPedId())
            createData.points[#createData.points + 1] = { x = coords.x, y = coords.y, z = coords.z }
            VFW.ShowNotification({ type = "VERT", content = "Point de vote ajouté" })
            StaffMenu.builderElectionCreate.refresh()
        end
    )

    for i, point in ipairs(createData.points) do
        StaffMenu.builderElectionCreate.Button(
            "Point #" .. i .. " (" .. string.format("%.1f, %.1f, %.1f", point.x, point.y, point.z) .. ")",
            "Cliquer pour supprimer",
            nil, "trash", false,
            function()
                table.remove(createData.points, i)
                StaffMenu.builderElectionCreate.refresh()
            end
        )
    end

    StaffMenu.builderElectionCreate.Separator("Validation")

    local canCreate = createData.name and createData.description and #createData.proposals >= 2 and #createData.points >= 1
    StaffMenu.builderElectionCreate.Button(
        ":check: CONFIRMER LA CRÉATION",
        canCreate and "Créer le vote" or "Nom + description + min 2 propositions + min 1 point requis",
        nil, "check", not canCreate,
        function()
            if not canCreate then return end
            local result = TriggerServerCallback("elections:create", {
                name = createData.name,
                description = createData.description,
                proposals = createData.proposals,
                points = createData.points,
                durationHours = createData.durationHours,
            })
            if result and result.success then
                VFW.ShowNotification({ type = "VERT", content = "Vote créé" })
                ResetCreateData()
                LoadElectionZones()
                StaffMenu.builders.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = result and result.reason or "Erreur lors de la création" })
            end
        end
    )
end)

StaffMenu.builderElectionCreate.OnClose(function() end)

StaffMenu.builderElectionManage.OnOpen(function()
    StaffMenu.builderElectionManage.ClearItems()

    cachedElections = TriggerServerCallback("elections:getAll")
    if not cachedElections or #cachedElections == 0 then
        StaffMenu.builderElectionManage.Button("Aucun vote", "Aucun vote trouvé", nil, nil, false, function() end)
        return
    end

    for _, election in ipairs(cachedElections) do
        local status = IsActiveFlag(election.active) and ":dot-green:" or ":dot-red:"
      local timeInfo = FormatTimeRemaining(election.remainingSeconds)
        local desc = election.totalVotes .. (election.totalVotes > 1 and " votes - " or " vote - ") .. #election.points .. (#election.points > 1 and " points" or " point")
      if timeInfo then
            desc = desc .. " - " .. timeInfo
        elseif IsActiveFlag(election.active) and not election.ends_at then
            desc = desc .. " - Sans limite"
      end
        StaffMenu.builderElectionManage.Button(
            status .. " " .. election.name,
            desc,
            nil, "chevron", false,
            function()
                selectedElectionId = election.id
            end,
            StaffMenu.builderElectionDetail
        )
    end
end)

local function GetSelectedElection()
    if not cachedElections or not selectedElectionId then return nil end
    for _, e in ipairs(cachedElections) do
        if e.id == selectedElectionId then return e end
    end
    return nil
end

StaffMenu.builderElectionDetail.OnOpen(function()
    StaffMenu.builderElectionDetail.ClearItems()

    local election = GetSelectedElection()
    if not election then
        StaffMenu.builderElectionDetail.Button(":x: Erreur", "Vote introuvable", nil, nil, false, function() end)
        return
    end

    StaffMenu.builderElectionDetail.Separator(election.name)

    local timeInfo = FormatTimeRemaining(election.remainingSeconds)
    if timeInfo then
        StaffMenu.builderElectionDetail.Button(
            "Temps: " .. timeInfo,
            election.duration_hours and ("Durée: " .. election.duration_hours .. "h") or "",
            nil, "clock", true,
            function() end
        )
    elseif not election.ends_at and IsActiveFlag(election.active) then
        StaffMenu.builderElectionDetail.Button(
            "Durée: Sans limite de temps",
            "Pas de fermeture automatique",
            nil, "clock", true,
            function() end
        )
    end

    StaffMenu.builderElectionDetail.Button(
        ":chart: RÉSULTATS EN DIRECT",
        "Voir les votes en temps réel (" .. election.totalVotes .. " votes)",
        nil, "chevron", false,
        function() end,
        StaffMenu.builderElectionResults
    )

    StaffMenu.builderElectionDetail.Button(
        ":pin: POINTS DE VOTE (" .. #election.points .. ")",
        "Ajouter ou retirer des points de vote",
        nil, "chevron", false,
        function() end,
        StaffMenu.builderElectionPoints
    )

    if IsActiveFlag(election.active) then
        StaffMenu.builderElectionDetail.Button(
            "⏹ TERMINER MAINTENANT",
            "Fermer le scrutin immédiatement",
            nil, "lock", false,
            function()
                local confirm = VFW.Nui.ChoiceInput("Confirmation", "Terminer le vote \"" .. election.name .. "\" maintenant ?", {
                    { label = "Oui", value = "yes" },
                    { label = "Non", value = "no" },
                })
                if confirm == "yes" then
                    TriggerServerEvent("elections:endNow", election.id)
                    election.active = 0
                    StaffMenu.builderElectionDetail.refresh()
                end
            end
        )
    end

    StaffMenu.builderElectionDetail.Button(
        IsActiveFlag(election.active) and "⏸ DÉSACTIVER" or ":arrow: RÉACTIVER",
        IsActiveFlag(election.active) and "Mettre en pause le scrutin" or "Rouvrir le scrutin",
        nil, "check", false,
        function()
            TriggerServerEvent("elections:toggleActive", election.id, not IsActiveFlag(election.active))
            election.active = IsActiveFlag(election.active) and 0 or 1
            StaffMenu.builderElectionDetail.refresh()
        end
    )

    StaffMenu.builderElectionDetail.Button(
        ":trash: SUPPRIMER",
        "Supprimer définitivement ce vote",
        nil, "trash", false,
        function()
            local confirm = VFW.Nui.ChoiceInput("Confirmation", "Supprimer le vote \"" .. election.name .. "\" ?", {
                { label = "Oui", value = "yes" },
                { label = "Non", value = "no" },
            })
            if confirm == "yes" then
                TriggerServerCallback("elections:delete", election.id)
                selectedElectionId = nil
                VFW.ShowNotification({ type = "VERT", content = "Vote supprimé" })
                StaffMenu.builderElectionManage.open()
            end
        end
    )
end)

StaffMenu.builderElectionResults.OnOpen(function()
    StaffMenu.builderElectionResults.ClearItems()

    if not selectedElectionId then return end

    local results = TriggerServerCallback("elections:getResults", selectedElectionId)
    if not results then
        StaffMenu.builderElectionResults.Button("Erreur", "Impossible de charger les résultats", nil, nil, false, function() end)
        return
    end

    StaffMenu.builderElectionResults.Separator("Total: " .. results.totalVotes .. (results.totalVotes > 1 and " votes" or " vote"))

    for _, proposal in ipairs(results.proposals) do
        local count = proposal.vote_count or 0
        local pct = results.totalVotes > 0 and math.floor((count / results.totalVotes) * 100) or 0
        StaffMenu.builderElectionResults.Button(
            proposal.label,
            count .. (count > 1 and " votes - " or " vote - ") .. pct .. "%",
            nil, nil, false,
            function() end
        )
    end

    StaffMenu.builderElectionResults.Separator("")
    StaffMenu.builderElectionResults.Button(
        ":refresh: ACTUALISER",
        "Recharger les résultats",
        nil, "check", false,
        function()
            StaffMenu.builderElectionResults.refresh()
        end
    )
end)

StaffMenu.builderElectionPoints.OnOpen(function()
    StaffMenu.builderElectionPoints.ClearItems()

    local election = TriggerServerCallback("elections:getOne", selectedElectionId)
    if not election then return end

    StaffMenu.builderElectionPoints.Separator("Points de vote (" .. #election.points .. ")")

    StaffMenu.builderElectionPoints.Button(
        ":pin: AJOUTER MA POSITION",
        "Ajouter un point de vote à ma position",
        nil, "check", false,
        function()
            local coords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent("elections:addPoint", selectedElectionId, { x = coords.x, y = coords.y, z = coords.z })
            Wait(300)
            StaffMenu.builderElectionPoints.refresh()
        end
    )

    for i, point in ipairs(election.points) do
        StaffMenu.builderElectionPoints.Button(
            "Point #" .. i .. " (" .. string.format("%.1f, %.1f, %.1f", point.x, point.y, point.z) .. ")",
            "Cliquer pour supprimer ce point",
            nil, "trash", false,
            function()
                TriggerServerEvent("elections:removePoint", point.id)
                Wait(300)
                StaffMenu.builderElectionPoints.refresh()
            end
        )
    end
end)

local electionPoints = {}
local electionMarkerActive = false
local isVoteOpen = false

LoadElectionZones = function()
    electionMarkerActive = false
    electionPoints = {}

    local elections = TriggerServerCallback("elections:getActive")
    if not elections or #elections == 0 then return end

    for _, election in ipairs(elections) do
        for _, point in ipairs(election.points) do
            electionPoints[#electionPoints + 1] = {
                coords = vector3(point.x, point.y, point.z),
                electionId = election.id,
                name = election.name,
                description = election.description,
                proposals = election.proposals,
                endsAt = election.ends_at,
                remainingSeconds = election.remainingSeconds,
                loadedAt = GetGameTimer(),
            }
        end
    end

    if #electionPoints > 0 then
        electionMarkerActive = true
        CreateThread(function()
            while electionMarkerActive and #electionPoints > 0 do
                local sleep = 500
                local playerCoords = GetEntityCoords(PlayerPedId())
                local closestPoint = nil
                local closestDist = 999

                for _, pt in ipairs(electionPoints) do
                    local dist = #(playerCoords - pt.coords)
                    if dist < 30.0 then
                        sleep = 0
                        DrawMarker(25, pt.coords.x, pt.coords.y, pt.coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 114, 99, 238, 255, false, true, 2, false, nil, nil, false)
                        if dist < 2.0 and dist < closestDist then
                            closestDist = dist
                            closestPoint = pt
                        end
                    end
                end

                if closestPoint and not isVoteOpen then
                    VFW.ShowHelpNotification("Appuyez sur ~y~[E]~w~ pour voter")
                    if VFW.Interact.JustPressed(0, 38) then
                        isVoteOpen = true
                        local voteInfo = TriggerServerCallback("elections:hasVoted", closestPoint.electionId)
                        local elapsed = math.floor((GetGameTimer() - closestPoint.loadedAt) / 1000)
                        local remaining = closestPoint.remainingSeconds and math.max(0, closestPoint.remainingSeconds - elapsed) or nil
                        SendNUIMessage({
                            action = "nui:electionVote:open",
                            data = {
                                electionId = closestPoint.electionId,
                                name = closestPoint.name,
                                description = closestPoint.description,
                                proposals = closestPoint.proposals,
                                remainingSeconds = remaining,
                                hasVoted = voteInfo and voteInfo.voted or false,
                                votedProposalLabel = voteInfo and voteInfo.proposalLabel or nil,
                                votedProposalId = voteInfo and voteInfo.proposalId or nil,
                            }
                        })
                        VFW.Nui.Focus(true)
                    end
                end

                Wait(sleep)
            end
            electionMarkerActive = false
        end)
    end
end

RegisterNUICallback("electionVote:close", function(_, cb)
    VFW.Nui.Focus(false)
    isVoteOpen = false
    cb({})
end)

RegisterNUICallback("electionVote:vote", function(data, cb)
    if not data or not data.electionId or not data.proposalId then
        cb({ success = false })
        return
    end

    local result = TriggerServerCallback("elections:vote", data.electionId, data.proposalId)
    if result and result.success then
        VFW.ShowNotification({ type = "VERT", content = "Vote enregistré" })
    else
        VFW.ShowNotification({ type = "ROUGE", content = result and result.error or "Erreur lors du vote" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("electionVote:getResults", function(data, cb)
    if not data or not data.electionId then
        cb({})
        return
    end

    local results = TriggerServerCallback("elections:getResults", data.electionId)
    cb(results or {})
end)

RegisterNetEvent("elections:refresh")
AddEventHandler("elections:refresh", function()
    LoadElectionZones()
end)

RegisterNetEvent("vfw:playerLoaded")
AddEventHandler("vfw:playerLoaded", function()
    Wait(5000)
    LoadElectionZones()
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(5000)
    LoadElectionZones()
end)
