---@meta _
---@diagnostic disable: duplicate-doc-field

local isTabletOpen = false
local currentFactionData = nil

--- OpenFactionTablet - Opens the faction management tablet
function OpenFactionTablet()
    if isTabletOpen then
        return
    end

    local faction = VFW.PlayerData.faction
    if not faction or faction.name == "nocrew" then
        VFW.ShowNotification({ type = "ILLEGAL", message = "Vous n'êtes pas dans une faction" })
        return
    end

    isTabletOpen = true

    -- Show tablet with login animation
    SendNUIMessage({
        action = "nui:faction-tablet:visible",
        data = true
    })

    VFW.Nui.Focus(true)
    VFW.Nui.HudVisible(false)
    VFW.DisableEscapeMenu(true)

    -- Enregistrer ce joueur comme viewer actif
    TriggerServerCallback("core:faction-tablet:registerViewer")

    -- Fetch faction data from server
    local factionData = TriggerServerCallback("core:faction-tablet:getData")

    if factionData then
        currentFactionData = factionData
        SendNUIMessage({
            action = "nui:faction-tablet:data",
            data = factionData
        })
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = "Vous n'avez pas accès à la tablette faction" })
        CloseFactionTablet()
    end
end

--- CloseFactionTablet - Closes the faction management tablet
function CloseFactionTablet()
    isTabletOpen = false
    currentFactionData = nil

    SendNUIMessage({
        action = "nui:faction-tablet:visible",
        data = false
    })

    VFW.Nui.Focus(false)
    VFW.Nui.HudVisible(true)
    VFW.DisableEscapeMenu(false)

    -- Désenregistrer ce joueur des viewers actifs
    TriggerServerCallback("core:faction-tablet:unregisterViewer")
end

--- NUI Callback: Close tablet
RegisterNUICallback("nui:faction-tablet:close", function(_, cb)
    CloseFactionTablet()
    cb("ok")
end)

--- NUI Callback: Recruit a player (sends recruitment request)
RegisterNUICallback("nui:faction-tablet:recruit", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:recruit", {
        targetSource = data.targetSource,
        targetPermId = data.targetPermId,
        gradeId = data.gradeId
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Demande de recrutement envoyée" })
        -- Don't refresh data - member not added yet, waiting for target to accept
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors du recrutement" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Promote a member
RegisterNUICallback("nui:faction-tablet:promote", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:promote", {
        permId = data.permId
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Membre promu" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la promotion" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Demote a member
RegisterNUICallback("nui:faction-tablet:demote", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:demote", {
        permId = data.permId
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Membre rétrogradé" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la rétrogradation" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Kick a member
RegisterNUICallback("nui:faction-tablet:kick", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:kick", {
        permId = data.permId
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Membre expulsé" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de l'expulsion" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Set member grade directly
RegisterNUICallback("nui:faction-tablet:setGrade", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:setGrade", {
        permId = data.permId,
        gradeLevel = data.gradeLevel
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Grade modifié" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors du changement de grade" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Update chest config
RegisterNUICallback("nui:faction-tablet:updateChestConfig", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:updateChestConfig", {
        minGradeDeposit = data.minGradeDeposit,
        minGradeWithdraw = data.minGradeWithdraw,
        minGradeHistory = data.minGradeHistory
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Configuration du coffre mise à jour" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la mise à jour" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Update chest access (like bossPanel)
RegisterNUICallback("nui:faction-tablet:updateChestAccess", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:updateChestAccess", {
        id = data.id,
        type = data.type,
        newGrade = data.newGrade
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Accès du coffre mis à jour" })
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la mise à jour" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Get nearby players for recruitment
RegisterNUICallback("nui:faction-tablet:getNearbyPlayers", function(_, cb)
    local nearbyPlayers = TriggerServerCallback("core:faction-tablet:getNearbyPlayers")
    cb(nearbyPlayers or {})
end)

--- NUI Callback: Refresh tablet data
RegisterNUICallback("nui:faction-tablet:refresh", function(_, cb)
    if not isTabletOpen then
        cb({ success = false })
        return
    end

    local factionData = TriggerServerCallback("core:faction-tablet:getData")

    if factionData then
        currentFactionData = factionData
        SendNUIMessage({
            action = "nui:faction-tablet:data",
            data = factionData
        })
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

--- NUI Callback: Get chest history filtered by chest ID
RegisterNUICallback("nui:faction-tablet:getChestHistory", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, history = {} })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:getChestHistory", {
        chestId = data.chestId or "all",
        limit = data.limit or 50
    })

    cb(result or { success = false, history = {} })
end)

--- NUI Callback: Set waypoint to chest location
RegisterNUICallback("nui:faction-tablet:setChestWaypoint", function(data, cb)
    if data.coords and data.coords.x and data.coords.y then
        SetNewWaypoint(data.coords.x, data.coords.y)
        VFW.ShowNotification({ type = "ILLEGAL", message = "Point GPS ajouté" })
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

--- NUI Callback: Update grade permissions
RegisterNUICallback("nui:faction-tablet:updateGradePermissions", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local success, result = pcall(function()
        return TriggerServerCallback("core:faction-tablet:updateGradePermissions", {
            gradeId = data.gradeId,
            permissions = data.permissions
        })
    end)

    if not success then
        VFW.ShowNotification({ type = "ILLEGAL", message = "Action impossible pour le moment" })
        cb({ success = false, message = "Action impossible pour le moment" })
        return
    end

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Permissions mises à jour" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la mise à jour des permissions" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Create a new grade
RegisterNUICallback("nui:faction-tablet:createGrade", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:createGrade", {
        name = data.name,
        level = data.level
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Grade créé" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la création du grade" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Delete a grade
RegisterNUICallback("nui:faction-tablet:deleteGrade", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:deleteGrade", {
        gradeLevel = data.gradeLevel
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Grade supprimé" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la suppression du grade" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Rename a grade
RegisterNUICallback("nui:faction-tablet:renameGrade", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:renameGrade", {
        gradeLevel = data.gradeLevel,
        newName = data.newName
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Grade renommé" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors du renommage du grade" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Swap grade levels (drag and drop reordering)
RegisterNUICallback("nui:faction-tablet:swapGradeLevels", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("nui:faction-tablet:swapGradeLevels", {
        grade1Id = data.grade1Id,
        grade1NewLevel = data.grade1NewLevel,
        grade2Id = data.grade2Id,
        grade2NewLevel = data.grade2NewLevel
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Grades réorganisés" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la réorganisation des grades" })
    end

    cb(result or { success = false })
end)

--- NUI Callback: Update faction motto/devise
RegisterNUICallback("nui:faction-tablet:updateMotto", function(data, cb)
    if not isTabletOpen then
        cb({ success = false, message = "Tablette fermée" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:updateMotto", {
        motto = data.motto
    })

    if result and result.success then
        VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Devise mise à jour" })
        RefreshFactionTabletData()
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur lors de la mise à jour de la devise" })
    end

    cb(result or { success = false })
end)

--- Refresh faction tablet data
function RefreshFactionTabletData()
    if not isTabletOpen then
        return
    end

    local factionData = TriggerServerCallback("core:faction-tablet:getData")

    if factionData then
        currentFactionData = factionData
        SendNUIMessage({
            action = "nui:faction-tablet:data",
            data = factionData
        })
    end
end

--- Event: Update faction tablet data (from server)
RegisterNetEvent("core:faction-tablet:updateData", function(data)
    if isTabletOpen and data then
        currentFactionData = data
        SendNUIMessage({
            action = "nui:faction-tablet:data",
            data = data
        })
    end
end)

--- Event: Force close tablet
RegisterNetEvent("core:faction-tablet:forceClose", function()
    if isTabletOpen then
        CloseFactionTablet()
        VFW.ShowNotification({ type = "ILLEGAL", message = "La tablette a été fermée" })
    end
end)

-- Pending invitation data
local pendingInvitation = nil
local invitationPromptActive = false

--- Event: Recruitment request received
RegisterNetEvent("core:faction-tablet:recruitmentRequest", function(data)
    if not data or not data.requestId then return end

    -- Store the pending invitation
    pendingInvitation = {
        requestId = data.requestId,
        recruiterName = data.recruiterName or "Quelqu'un",
        factionLabel = data.factionLabel or "une faction",
        factionColor = data.factionColor or "#e53935",
        factionLogo = data.factionLogo or "",
        gradeName = data.gradeName or "membre"
    }

    -- Directly show the invitation popup (Y to accept, N to decline)
    OpenInvitationConfirmation()
end)

--- Open the invitation confirmation UI (Pure HUD - no focus)
function OpenInvitationConfirmation()
    if not pendingInvitation then return end

    SendNUIMessage({
        action = "nui:faction-tablet:showInvitation",
        data = pendingInvitation
    })

    -- Pure HUD mode: no focus at all, just display
    -- Y/N keys are handled via game key bindings below
end

--- Close the invitation confirmation UI
function CloseInvitationConfirmation()
    SendNUIMessage({
        action = "nui:faction-tablet:hideInvitation",
        data = {}
    })
end

-- Handle Y/N keys for invitation via game thread
CreateThread(function()
    while true do
        if pendingInvitation then
            Wait(0)
            if IsControlJustPressed(0, 246) then -- Y
                local result = TriggerServerCallback("core:faction-tablet:respondRecruitment", {
                    requestId = pendingInvitation.requestId,
                    accepted = true
                })
                if result and result.success then
                    VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Vous avez rejoint la faction" })
                else
                    VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur" })
                end
                pendingInvitation = nil
                CloseInvitationConfirmation()
            elseif IsControlJustPressed(0, 249) then -- N
                TriggerServerCallback("core:faction-tablet:respondRecruitment", {
                    requestId = pendingInvitation.requestId,
                    accepted = false
                })
                VFW.ShowNotification({ type = "ILLEGAL", message = "Vous avez refusé l'invitation" })
                pendingInvitation = nil
                CloseInvitationConfirmation()
            end
        else
            Wait(500)
        end
    end
end)

--- NUI Callback: Respond to invitation
RegisterNUICallback("nui:faction-tablet:respondInvitation", function(data, cb)
    if not pendingInvitation then
        cb({ success = false, message = "Aucune invitation en attente" })
        return
    end

    local result = TriggerServerCallback("core:faction-tablet:respondRecruitment", {
        requestId = pendingInvitation.requestId,
        accepted = data.accepted
    })

    if data.accepted then
        if result and result.success then
            VFW.ShowNotification({ type = "ILLEGAL", message = result.message or "Vous avez rejoint la faction" })
        else
            VFW.ShowNotification({ type = "ILLEGAL", message = result and result.message or "Erreur" })
        end
    else
        VFW.ShowNotification({ type = "ILLEGAL", message = "Vous avez refusé l'invitation" })
    end

    -- Clear the pending invitation
    pendingInvitation = nil

    -- Close the UI
    CloseInvitationConfirmation()

    cb({ success = true })
end)

--- NUI Callback: Close invitation UI (escape pressed)
RegisterNUICallback("nui:faction-tablet:closeInvitation", function(_, cb)
    CloseInvitationConfirmation()
    cb("ok")
end)

--- Test data for development
local function getTestFactionData()
    return {
        factionId = "testfaction",
        factionName = "Test Faction",
        factionDesc = "La rue c'est nous",
        factionColor = "#e53935",
        factionInitials = "TF",
        factionMotto = "On lâche rien",
        myGrade = {
            id = 1,
            name = "Chef",
            level = 1,
            permissions = {
                canAccessTablet = true,
                canRecruit = true,
                canKick = true,
                canPromote = true,
                canDemote = true,
                canManageChest = true,
                canManageGrades = true
            },
            color = "#e53935"
        },
        myPermId = "test:111",
        grades = {
            { id = 1, name = "Chef", level = 1, permissions = { canAccessTablet = true, canRecruit = true, canKick = true, canPromote = true, canDemote = true, canManageChest = true, canManageGrades = true }, color = "#e53935" },
            { id = 2, name = "Sous-Chef", level = 2, permissions = { canAccessTablet = true, canRecruit = true, canKick = true, canPromote = true, canDemote = true, canManageChest = true, canManageGrades = true }, color = "#e53935" },
            { id = 3, name = "Bras Droit", level = 3, permissions = { canAccessTablet = true, canRecruit = true, canKick = false, canPromote = true, canDemote = false, canManageChest = false, canManageGrades = false }, color = "#e53935" },
            { id = 4, name = "Soldat", level = 4, permissions = { canAccessTablet = true, canRecruit = true, canKick = false, canPromote = false, canDemote = false, canManageChest = false, canManageGrades = false }, color = "#e53935" },
            { id = 5, name = "Membre", level = 5, permissions = { canAccessTablet = false, canRecruit = false, canKick = false, canPromote = false, canDemote = false, canManageChest = false, canManageGrades = false }, color = "#e53935" },
            { id = 6, name = "Recrue", level = 6, permissions = { canAccessTablet = false, canRecruit = false, canKick = false, canPromote = false, canDemote = false, canManageChest = false, canManageGrades = false }, color = "#e53935" }
        },
        members = {
            { odid = "test:111", permId = "test:111", name = "Jean Dupont", gradeId = 1, gradeName = "Chef", gradeLevel = 1, joinedAt = "01/01/2024", lastSeen = nil, isOnline = true },
            { odid = "test:222", permId = "test:222", name = "Marie Martin", gradeId = 2, gradeName = "Sous-Chef", gradeLevel = 2, joinedAt = "15/01/2024", lastSeen = nil, isOnline = true },
            { odid = "test:333", permId = "test:333", name = "Pierre Bernard", gradeId = 3, gradeName = "Bras Droit", gradeLevel = 3, joinedAt = "20/01/2024", lastSeen = "10/12/2024 14:30", isOnline = false },
            { odid = "test:444", permId = "test:444", name = "Sophie Petit", gradeId = 4, gradeName = "Soldat", gradeLevel = 4, joinedAt = "01/02/2024", lastSeen = nil, isOnline = true },
            { odid = "test:555", permId = "test:555", name = "Lucas Moreau", gradeId = 5, gradeName = "Membre", gradeLevel = 5, joinedAt = "10/02/2024", lastSeen = "09/12/2024 18:00", isOnline = false },
            { odid = "test:666", permId = "test:666", name = "Emma Leroy", gradeId = 6, gradeName = "Recrue", gradeLevel = 6, joinedAt = "01/03/2024", lastSeen = nil, isOnline = true }
        },
        chestConfig = {
            minGradeDeposit = 6,
            minGradeWithdraw = 2,
            minGradeHistory = 3
        },
        chests = {
            { id = "testfaction_main", accessName = "testfaction", name = "Coffre Principal", gradeMinTake = 2, gradeMinPut = 6, gradeMinHistory = 3, maxWeight = 500000, weight = 125000 },
            { id = "testfaction_armes", accessName = "testfaction", name = "Armurerie", gradeMinTake = 1, gradeMinPut = 3, gradeMinHistory = 2, maxWeight = 200000, weight = 78000 },
            { id = "testfaction_drogue", accessName = "testfaction", name = "Stock Drogue", gradeMinTake = 2, gradeMinPut = 4, gradeMinHistory = 2, maxWeight = 300000, weight = 245000 }
        },
        chestHistory = {
            { id = 1, memberName = "Jean Dupont", memberId = "test:111", action = "deposit", itemName = "Cocaine", quantity = 50, date = "2024-12-10 14:30:00" },
            { id = 2, memberName = "Marie Martin", memberId = "test:222", action = "withdraw", itemName = "AK-47", quantity = 2, date = "2024-12-10 12:00:00" },
            { id = 3, memberName = "Pierre Bernard", memberId = "test:333", action = "deposit", itemName = "Weed", quantity = 100, date = "2024-12-09 18:45:00" },
            { id = 4, memberName = "Sophie Petit", memberId = "test:444", action = "deposit", itemName = "Dirty Money", quantity = 50000, date = "2024-12-08 20:15:00" }
        },
        recruitablePlayers = {
            { source = 10, name = "John Doe", permId = "discord:123456789" },
            { source = 15, name = "Jane Smith", permId = "discord:987654321" },
            { source = 22, name = "Bob Wilson", permId = "discord:456789123" }
        }
    }
end

--- OpenFactionTabletTest - Opens the tablet with test data
function OpenFactionTabletTest()
    if isTabletOpen then
        return
    end

    isTabletOpen = true

    SendNUIMessage({
        action = "nui:faction-tablet:visible",
        data = true
    })

    VFW.Nui.Focus(true)
    VFW.Nui.HudVisible(false)
    VFW.DisableEscapeMenu(true)

    local testData = getTestFactionData()
    currentFactionData = testData

    SendNUIMessage({
        action = "nui:faction-tablet:data",
        data = testData
    })
end

--- Command to open faction tablet
RegisterCommand("factiontablet", function()
    local faction = VFW.PlayerData.faction
    if not faction or faction.name == "nocrew" or faction.name == "nofaction" then
        VFW.ShowNotification({ type = "ILLEGAL", message = "Vous n'êtes pas dans une faction" })
        return
    end
    OpenFactionTablet()
end, false)
