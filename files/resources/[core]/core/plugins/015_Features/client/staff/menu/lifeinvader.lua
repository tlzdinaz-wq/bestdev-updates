---@meta _
---@diagnostic disable: duplicate-doc-field

-- LifeInvader Staff Management Menu

local lifeinvaderCreateData = {
    title = "",
    content = "",
    format = "breaking",
    scheduled = false,
    scheduledTime = "",
}

local function LifeInvaderNotif(content, isError)
    VFW.ShowNotification({
        type = "JOB",
        title = "LifeInvader",
        subtitle = "Information",
        subtitleColor = isError and "#e03030" or "#7263EE",
        image = lifeinvaderImage or "",
        content = content,
    })
end

--- Build the main LifeInvader management menu
function StaffMenu.BuildLifeInvaderManageMenu()
    StaffMenu.lifeinvaderManage.Button(":edit: CRÉER UNE ANNONCE", nil, nil, "chevron", false, function()
        StaffMenu.ResetlifeinvaderCreateData()
    end, StaffMenu.lifeinvaderCreate)

    StaffMenu.lifeinvaderManage.Button(":report: ANNONCES PROGRAMMÉES", nil, nil, "chevron", false, function()
    end, StaffMenu.lifeinvaderProgrammed)

    StaffMenu.lifeinvaderManage.Button(":report: HISTORIQUE", nil, nil, "chevron", false, function()
    end, StaffMenu.lifeinvaderHistory)
end

--- Reset creation data (called on menu open, not on refresh)
function StaffMenu.ResetlifeinvaderCreateData()
    lifeinvaderCreateData = {
        title = "",
        content = "",
        format = "breaking",
        scheduled = false,
        scheduledTime = "",
    }
end

--- Build the create announcement menu
function StaffMenu.BuildLifeInvaderCreateMenu()
    -- Step 1: Title
    local titleDesc = lifeinvaderCreateData.title ~= "" and "Défini" or "Cliquez pour saisir"
  StaffMenu.lifeinvaderCreate.Button(":edit: TITRE", titleDesc, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Titre de l'annonce (max 30 caractères)", lifeinvaderCreateData.title)
        if input and input ~= "" then
            if string.len(input) > 30 then
                LifeInvaderNotif("Le titre ne peut pas dépasser 30 caractères.", true)
                return
            end
            lifeinvaderCreateData.title = input
            StaffMenu.lifeinvaderCreate.refresh()
        end
    end)

    -- Step 2: Content
    local contentDesc = lifeinvaderCreateData.content ~= "" and "Défini" or "Cliquez pour saisir"
  StaffMenu.lifeinvaderCreate.Button(":document: CONTENU", contentDesc, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Contenu de l'annonce (max 500 caractères)", lifeinvaderCreateData.content)
        if input and input ~= "" then
            if string.len(input) > 500 then
                LifeInvaderNotif("Le contenu ne peut pas dépasser 500 caractères.", true)
                return
            end
            lifeinvaderCreateData.content = input
            StaffMenu.lifeinvaderCreate.refresh()
        end
    end)

    -- Step 3: Format selector
    local formatOptions = { "BREAKING NEWS", "FLASH INFO" }
    local formatIndex = lifeinvaderCreateData.format == "flash" and 2 or 1
    StaffMenu.lifeinvaderCreate.List(":monitor: FORMAT", nil, false, formatOptions, formatIndex, function(index)
        lifeinvaderCreateData.format = index == 2 and "flash" or "breaking"
      StaffMenu.lifeinvaderCreate.refresh()
    end)

    -- Step 4: Schedule toggle
    local scheduleLabel = lifeinvaderCreateData.scheduled and ("OUI, à " .. lifeinvaderCreateData.scheduledTime) or "NON"
  StaffMenu.lifeinvaderCreate.Button(":clock: PROGRAMMER ?", scheduleLabel, nil, nil, false, function()
        if not lifeinvaderCreateData.scheduled then
            local input = VFW.Nui.KeyboardInput(true, "Heure de diffusion (HH:MM)", "")
            if input and input ~= "" then
                local hours, minutes = string.match(input, "^(%d%d):(%d%d)$")
                if not hours or not minutes then
                    LifeInvaderNotif("Ce format n'est pas valide. Utilisez HH:MM (ex: 14:30).", true)
                    return
                end
                local h = tonumber(hours)
                local m = tonumber(minutes)
                if h < 0 or h > 23 or m < 0 or m > 59 then
                    LifeInvaderNotif("Cette heure n'est pas valide. Heures : 00-23, minutes : 00-59.", true)
                    return
                end
                lifeinvaderCreateData.scheduled = true
                lifeinvaderCreateData.scheduledTime = input
            end
        else
            lifeinvaderCreateData.scheduled = false
            lifeinvaderCreateData.scheduledTime = ""
      end
        StaffMenu.lifeinvaderCreate.refresh()
    end)

    -- Preview
    StaffMenu.lifeinvaderCreate.Button(":eye: PRÉVISUALISER", "Voir le rendu de l'annonce", nil, nil, false, function()
        if lifeinvaderCreateData.title == "" and lifeinvaderCreateData.content == "" then
            LifeInvaderNotif("Veuillez remplir au moins le titre ou le contenu.", true)
            return
        end

        local subtitle = lifeinvaderCreateData.format == "flash" and "FLASH INFO" or "BREAKING NEWS"
      local subtitleColor = lifeinvaderCreateData.format == "flash" and "#e03030" or "#7263EE"
      local announceTitle = lifeinvaderCreateData.title ~= "" and lifeinvaderCreateData.title or "Sans titre"
      local content = announceTitle
        if lifeinvaderCreateData.content ~= "" then
            content = content .. "\n" .. lifeinvaderCreateData.content
        end

        VFW.ShowNotification({
            type = "JOB",
            title = "LifeInvader",
            subtitle = subtitle,
            subtitleColor = subtitleColor,
            image = lifeinvaderImage or "",
            content = content,
            duration = 10,
        })
    end)

    StaffMenu.lifeinvaderCreate.Separator(nil)

    -- Step 5: Confirm
    StaffMenu.lifeinvaderCreate.Button(":check: CONFIRMER L'ANNONCE", nil, nil, nil, false, function()
        if lifeinvaderCreateData.title == "" then
            LifeInvaderNotif("Veuillez saisir un titre.", true)
            return
        end
        if lifeinvaderCreateData.content == "" then
            LifeInvaderNotif("Veuillez saisir un contenu.", true)
            return
        end

        local data = {
            title = lifeinvaderCreateData.title,
            content = lifeinvaderCreateData.content,
            category = lifeinvaderCreateData.format == "breaking" and "breaking" or "flash",
            format = lifeinvaderCreateData.format,
            scheduledTime = (lifeinvaderCreateData.scheduled and lifeinvaderCreateData.scheduledTime ~= "") and lifeinvaderCreateData.scheduledTime or nil,
            buttons = {},
            media_url = "",
            media = "image",
            addToJT = false,
        }

        local insertId = TriggerServerCallback("staff:lifeinvader:createAnnouncement", data)
        if insertId then
            if data.scheduledTime then
                LifeInvaderNotif("Annonce programmée.", false)
            else
                LifeInvaderNotif("Annonce diffusée.", false)
            end

            StaffMenu.lifeinvaderCreate.close()
            StaffMenu.lifeinvaderManage.open()
        else
            LifeInvaderNotif("Erreur lors de la création de l'annonce.", true)
        end
    end)
end

--- Build the programmed announcements menu
function StaffMenu.BuildLifeInvaderProgrammedMenu()
    local announcements, _ = TriggerServerCallback("staff:lifeinvader:getAnnouncements")
    announcements = announcements or {}

    if #announcements == 0 then
        StaffMenu.lifeinvaderProgrammed.Textbox("Aucune annonce programmée ou en attente.", "Information")
        return
    end

    for _, announce in ipairs(announcements) do
        local statusLabel = announce.status == "scheduled" and ":clock: Programmée" or ":hourglass: En attente"
      local formatLabel = (announce.format or "breaking") == "flash" and "FLASH INFO" or "BREAKING NEWS"

      -- Afficher l'heure de diffusion prévue (depuis schedules) au lieu de created_at
        local timeLabel = ""
      if announce.schedules and #announce.schedules > 0 then
            local ts = tonumber(announce.schedules[1])
            if ts then
                local date = os.date("*t", math.floor(ts / 1000))
                timeLabel = string.format("%02d/%02d/%04d %02d:%02d", date.day, date.month, date.year, date.hour, date.min)
            end
        else
            timeLabel = announce.created_at_formatted or ""
      end

        local subtitle = statusLabel .. ", " .. formatLabel .. ", " .. timeLabel
        local contentPreview = announce.content or ""
      if #contentPreview > 80 then
            contentPreview = contentPreview:sub(1, 80) .. "..."
      end

        StaffMenu.lifeinvaderProgrammed.Textbox(announce.title or "Sans titre", subtitle)
        if contentPreview ~= "" then
            StaffMenu.lifeinvaderProgrammed.Textbox(contentPreview, "Contenu")
        end

        StaffMenu.lifeinvaderProgrammed.Button(":eye: Prévisualiser", nil, nil, nil, false, function()
            local sub = announce.format == "flash" and "FLASH INFO" or "BREAKING NEWS"
          local subColor = announce.format == "flash" and "#e03030" or "#7263EE"
          local announceTitle = announce.title or "Sans titre"
          local content = announceTitle
            if announce.content and announce.content ~= "" then
                content = content .. "\n" .. announce.content
            end

            VFW.ShowNotification({
                type = "JOB",
                title = "LifeInvader",
                subtitle = sub,
                subtitleColor = subColor,
                image = lifeinvaderImage or "",
                content = content,
                duration = 10,
            })
        end)

        StaffMenu.lifeinvaderProgrammed.Button(":trash: Supprimer", nil, nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer cette annonce", "")
            if confirm and string.upper(confirm) == "OUI" then
                local success = TriggerServerCallback("staff:lifeinvader:deleteAnnouncement", announce.id)
                if success then
                    LifeInvaderNotif("Annonce supprimée.", false)
                    StaffMenu.lifeinvaderProgrammed.refresh()
                else
                    LifeInvaderNotif("Erreur lors de la suppression.", true)
                end
            end
        end)

        StaffMenu.lifeinvaderProgrammed.Separator(nil)
    end
end

--- Build the history menu
function StaffMenu.BuildLifeInvaderHistoryMenu()
    local _, history = TriggerServerCallback("staff:lifeinvader:getAnnouncements")
    history = history or {}

    if #history == 0 then
        StaffMenu.lifeinvaderHistory.Textbox("Aucune annonce dans l'historique.", "Information")
        return
    end

    for _, announce in ipairs(history) do
        local authorLabel = announce.created_by and announce.created_by ~= "" and (", par " .. announce.created_by) or ""
      local subtitle = (announce.format or "breaking") .. ", " .. (announce.broadcasted_at_formatted or "N/A") .. authorLabel
        StaffMenu.lifeinvaderHistory.Button(announce.title or "Sans titre", subtitle, nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer de l'historique", "")
            if confirm and string.upper(confirm) == "OUI" then
                local success = TriggerServerCallback("staff:lifeinvader:deleteHistory", announce.id)
                if success then
                    LifeInvaderNotif("Entrée supprimée de l'historique.", false)
                    StaffMenu.lifeinvaderHistory.refresh()
                else
                    LifeInvaderNotif("Erreur lors de la suppression.", true)
                end
            end
        end)
    end
end
