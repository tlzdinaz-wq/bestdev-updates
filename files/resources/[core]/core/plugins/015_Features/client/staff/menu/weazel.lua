---@meta _
---@diagnostic disable: duplicate-doc-field

-- Weazel Staff Management Menu

local weazelCreateData = {
    title = "",
    content = "",
    format = "breaking",
    scheduled = false,
    scheduledTime = "",
}

local function WeazelNotif(content, isError)
    VFW.ShowNotification({
        type = "JOB",
        title = "Weazel News",
        subtitle = "Information",
        subtitleColor = isError and "#e03030" or "#7263EE",
        image = weazelImage or "",
        content = content,
    })
end

--- Build the main Weazel management menu
function StaffMenu.BuildWeazelManageMenu()
    StaffMenu.weazelManage.Button(":edit: CRÉER UNE ANNONCE", nil, nil, "chevron", false, function()
        StaffMenu.ResetWeazelCreateData()
    end, StaffMenu.weazelCreate)

    StaffMenu.weazelManage.Button(":report: ANNONCES PROGRAMMÉES", nil, nil, "chevron", false, function()
    end, StaffMenu.weazelProgrammed)

    StaffMenu.weazelManage.Button(":report: HISTORIQUE", nil, nil, "chevron", false, function()
    end, StaffMenu.weazelHistory)
end

--- Reset creation data (called on menu open, not on refresh)
function StaffMenu.ResetWeazelCreateData()
    weazelCreateData = {
        title = "",
        content = "",
        format = "breaking",
        scheduled = false,
        scheduledTime = "",
    }
end

--- Build the create announcement menu
function StaffMenu.BuildWeazelCreateMenu()
    -- Step 1: Title
    local titleDesc = weazelCreateData.title ~= "" and "Défini" or "Cliquez pour saisir"
  StaffMenu.weazelCreate.Button(":edit: TITRE", titleDesc, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Titre de l'annonce (max 30 caractères)", weazelCreateData.title)
        if input and input ~= "" then
            if string.len(input) > 30 then
                WeazelNotif("Le titre ne peut pas dépasser 30 caractères.", true)
                return
            end
            weazelCreateData.title = input
            StaffMenu.weazelCreate.refresh()
        end
    end)

    -- Step 2: Content
    local contentDesc = weazelCreateData.content ~= "" and "Défini" or "Cliquez pour saisir"
  StaffMenu.weazelCreate.Button(":document: CONTENU", contentDesc, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Contenu de l'annonce (max 500 caractères)", weazelCreateData.content)
        if input and input ~= "" then
            if string.len(input) > 500 then
                WeazelNotif("Le contenu ne peut pas dépasser 500 caractères.", true)
                return
            end
            weazelCreateData.content = input
            StaffMenu.weazelCreate.refresh()
        end
    end)

    -- Step 3: Format selector
    local formatOptions = { "BREAKING NEWS", "FLASH INFO" }
    local formatIndex = weazelCreateData.format == "flash" and 2 or 1
    StaffMenu.weazelCreate.List(":monitor: FORMAT", nil, false, formatOptions, formatIndex, function(index)
        weazelCreateData.format = index == 2 and "flash" or "breaking"
      StaffMenu.weazelCreate.refresh()
    end)

    -- Step 4: Schedule toggle
    local scheduleLabel = weazelCreateData.scheduled and ("OUI, à " .. weazelCreateData.scheduledTime) or "NON"
  StaffMenu.weazelCreate.Button(":clock: PROGRAMMER ?", scheduleLabel, nil, nil, false, function()
        if not weazelCreateData.scheduled then
            local input = VFW.Nui.KeyboardInput(true, "Heure de diffusion (HH:MM)", "")
            if input and input ~= "" then
                local hours, minutes = string.match(input, "^(%d%d):(%d%d)$")
                if not hours or not minutes then
                    WeazelNotif("Ce format n'est pas valide. Utilisez HH:MM (ex: 14:30).", true)
                    return
                end
                local h = tonumber(hours)
                local m = tonumber(minutes)
                if h < 0 or h > 23 or m < 0 or m > 59 then
                    WeazelNotif("Cette heure n'est pas valide. Heures : 00-23, minutes : 00-59.", true)
                    return
                end
                weazelCreateData.scheduled = true
                weazelCreateData.scheduledTime = input
            end
        else
            weazelCreateData.scheduled = false
            weazelCreateData.scheduledTime = ""
      end
        StaffMenu.weazelCreate.refresh()
    end)

    -- Preview
    StaffMenu.weazelCreate.Button(":eye: PRÉVISUALISER", "Voir le rendu de l'annonce", nil, nil, false, function()
        if weazelCreateData.title == "" and weazelCreateData.content == "" then
            WeazelNotif("Veuillez remplir au moins le titre ou le contenu.", true)
            return
        end

        local subtitle = weazelCreateData.format == "flash" and "FLASH INFO" or "BREAKING NEWS"
      local subtitleColor = weazelCreateData.format == "flash" and "#e03030" or "#7263EE"
      local announceTitle = weazelCreateData.title ~= "" and weazelCreateData.title or "Sans titre"
      local content = announceTitle
        if weazelCreateData.content ~= "" then
            content = content .. "\n" .. weazelCreateData.content
        end

        VFW.ShowNotification({
            type = "JOB",
            title = "Weazel News",
            subtitle = subtitle,
            subtitleColor = subtitleColor,
            image = weazelImage or "",
            content = content,
            duration = 10,
        })
    end)

    StaffMenu.weazelCreate.Separator(nil)

    -- Step 5: Confirm
    StaffMenu.weazelCreate.Button(":check: CONFIRMER L'ANNONCE", nil, nil, nil, false, function()
        if weazelCreateData.title == "" then
            WeazelNotif("Veuillez saisir un titre.", true)
            return
        end
        if weazelCreateData.content == "" then
            WeazelNotif("Veuillez saisir un contenu.", true)
            return
        end

        local data = {
            title = weazelCreateData.title,
            content = weazelCreateData.content,
            category = weazelCreateData.format == "breaking" and "breaking" or "flash",
            format = weazelCreateData.format,
            scheduledTime = (weazelCreateData.scheduled and weazelCreateData.scheduledTime ~= "") and weazelCreateData.scheduledTime or nil,
            buttons = {},
            media_url = "",
            media = "image",
            addToJT = false,
        }

        local insertId = TriggerServerCallback("staff:weazel:createAnnouncement", data)
        if insertId then
            if data.scheduledTime then
                WeazelNotif("Annonce programmée.", false)
            else
                WeazelNotif("Annonce diffusée.", false)
            end

            StaffMenu.weazelCreate.close()
            StaffMenu.weazelManage.open()
        else
            WeazelNotif("Erreur lors de la création de l'annonce.", true)
        end
    end)
end

--- Build the programmed announcements menu
function StaffMenu.BuildWeazelProgrammedMenu()
    local announcements, _ = TriggerServerCallback("staff:weazel:getAnnouncements")
    announcements = announcements or {}

    if #announcements == 0 then
        StaffMenu.weazelProgrammed.Textbox("Aucune annonce programmée ou en attente.", "Information")
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

        StaffMenu.weazelProgrammed.Textbox(announce.title or "Sans titre", subtitle)
        if contentPreview ~= "" then
            StaffMenu.weazelProgrammed.Textbox(contentPreview, "Contenu")
        end

        StaffMenu.weazelProgrammed.Button(":eye: Prévisualiser", nil, nil, nil, false, function()
            local sub = announce.format == "flash" and "FLASH INFO" or "BREAKING NEWS"
          local subColor = announce.format == "flash" and "#e03030" or "#7263EE"
          local announceTitle = announce.title or "Sans titre"
          local content = announceTitle
            if announce.content and announce.content ~= "" then
                content = content .. "\n" .. announce.content
            end

            VFW.ShowNotification({
                type = "JOB",
                title = "Weazel News",
                subtitle = sub,
                subtitleColor = subColor,
                image = weazelImage or "",
                content = content,
                duration = 10,
            })
        end)

        StaffMenu.weazelProgrammed.Button(":trash: Supprimer", nil, nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer cette annonce", "")
            if confirm and string.upper(confirm) == "OUI" then
                local success = TriggerServerCallback("staff:weazel:deleteAnnouncement", announce.id)
                if success then
                    WeazelNotif("Annonce supprimée.", false)
                    StaffMenu.weazelProgrammed.refresh()
                else
                    WeazelNotif("Erreur lors de la suppression.", true)
                end
            end
        end)

        StaffMenu.weazelProgrammed.Separator(nil)
    end
end

--- Build the history menu
function StaffMenu.BuildWeazelHistoryMenu()
    local _, history = TriggerServerCallback("staff:weazel:getAnnouncements")
    history = history or {}

    if #history == 0 then
        StaffMenu.weazelHistory.Textbox("Aucune annonce dans l'historique.", "Information")
        return
    end

    for _, announce in ipairs(history) do
        local authorLabel = announce.created_by and announce.created_by ~= "" and (", par " .. announce.created_by) or ""
      local subtitle = (announce.format or "breaking") .. ", " .. (announce.broadcasted_at_formatted or "N/A") .. authorLabel
        StaffMenu.weazelHistory.Button(announce.title or "Sans titre", subtitle, nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer de l'historique", "")
            if confirm and string.upper(confirm) == "OUI" then
                local success = TriggerServerCallback("staff:weazel:deleteHistory", announce.id)
                if success then
                    WeazelNotif("Entrée supprimée de l'historique.", false)
                    StaffMenu.weazelHistory.refresh()
                else
                    WeazelNotif("Erreur lors de la suppression.", true)
                end
            end
        end)
    end
end
