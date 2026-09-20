local openingCooldown = {}
local customCooldown = {}

local OPENING_COOLDOWN = 60
local CUSTOM_COOLDOWN = 600

local function stripColors(value)
    if type(value) ~= "string" then return "" end
    return value
end

local function sanitizeMediaUrl(value)
    if type(value) ~= "string" then return "" end
    local out = value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^[\"']", ""):gsub("[\"']$", "")
    if out == "" then return "" end
    if out:match("^r2%.fivemanage%.com/") or out:match("^[%w%-]+%.fivemanage%.com/") or out:match("^[%w%-]+%.fmfile%.com/") then
        out = "https://" .. out
    end
    if #out > 512 then out = out:sub(1, 512) end
    if out:match("^https?://") or out:match("^nui://") then return out end
    out = out:gsub("\\", "/"):gsub("^/+", ""):gsub("%.%./", "")
    return out
end

local function mediaUrl(path)
    if type(path) ~= "string" or path == "" then return "" end
    if VFW.CdnUrl then return VFW.CdnUrl(path) end
    return path
end

local function buildAnnounce(society, title, subtitle, titleColor, content)
    local logo = mediaUrl(society and society.image or "")
    local banner = mediaUrl(society and society.banner or "")
    return {
        type = "JOB",
        logo = logo,
        image = logo,
        banner = banner,
        title = title,
        titleColor = titleColor,
        subtitle = subtitle,
        subtitleColor = titleColor,
        content = content,
        duration = 12,
    }
end

local function canAnnounce(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    if not xPlayer.job.onDuty then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous devez être en service." })
        return false
    end

    if VFW.Society.IsBossGrade(xPlayer.job) then return true end

    local perms = xPlayer.job.permissions
    if type(perms) == "table" and (perms.announce == true or perms.announce == 1) then return true end

    local row = VFW.Society.Single(
        "SELECT enabled FROM society_grade_perms WHERE job_name = ? AND grade_name = ? AND perm_name = 'announce'",
        { xPlayer.job.name, xPlayer.job.grade_name }
    )
    if row and (row.enabled == 1 or row.enabled == true) then return true end

    xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas la permission d'annoncer." })
    return false
end

RegisterNetEvent("core:server:announceEntreprise:openingClosing", function(isOpening)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return end
    if type(isOpening) ~= "boolean" then return end
    if not canAnnounce(xPlayer) then return end

    local jobName = xPlayer.job.name
    local now = os.time()
    local last = openingCooldown[jobName]

    if last and (now - last) < OPENING_COOLDOWN then
        xPlayer.showNotification({
            type = "ROUGE",
            content = ("Veuillez patienter %d seconde%s."):format(OPENING_COOLDOWN - (now - last), (OPENING_COOLDOWN - (now - last)) > 1 and "s" or ""),
        })
        return
    end

    local society = VFW.Society.Get(jobName)
    local custom = society and society.custom or {}
    local message = isOpening and custom.openMessage or custom.closeMessage

    if type(message) ~= "string" or message == "" then
        message = isOpening
            and ("%s vient d'ouvrir ses portes."):format(VFW.Society.GetLabel(jobName))
            or ("%s vient de fermer ses portes."):format(VFW.Society.GetLabel(jobName))
    end

    openingCooldown[jobName] = now

    local subtitle = custom.announceSubtitle
    if type(subtitle) ~= "string" or subtitle == "" then
        subtitle = isOpening and "Ouverture" or "Fermeture"
    end

    TriggerClientEvent("vfw:showNotification", -1, buildAnnounce(
        society,
        VFW.Society.GetLabel(jobName),
        subtitle,
        type(custom.announceTitleColor) == "string" and custom.announceTitleColor or nil,
        stripColors(message)
    ))
end)

RegisterNetEvent("core:server:announceEntreprise:previewCustomMessage", function(previewText)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return end
    if type(previewText) ~= "string" then return end

    local jobName = xPlayer.job.name
    local society = VFW.Society.Get(jobName)
    local custom = society and society.custom or {}

    local subtitle = custom.customSubtitle
    if type(subtitle) ~= "string" or subtitle == "" then subtitle = "Annonce" end

    TriggerClientEvent("vfw:showNotification", source, buildAnnounce(
        society,
        VFW.Society.GetLabel(jobName),
        subtitle,
        type(custom.customTitleColor) == "string" and custom.customTitleColor or nil,
        stripColors(previewText:sub(1, 500))
    ))
end)

RegisterNetEvent("core:server:announceEntreprise:customMessage", function(message)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return end
    if type(message) ~= "string" or message == "" then return end
    if not canAnnounce(xPlayer) then return end

    local jobName = xPlayer.job.name
    local society = VFW.Society.Get(jobName)
    local custom = society and society.custom or {}

    if custom.allowCustomAnnouncement ~= true then
        xPlayer.showNotification({ type = "ROUGE", content = "Les annonces personnalisées sont désactivées." })
        return
    end

    local now = os.time()
    local last = customCooldown[jobName]

    if last and (now - last) < CUSTOM_COOLDOWN then
        xPlayer.showNotification({
            type = "ROUGE",
            content = ("Veuillez patienter %d seconde%s."):format(CUSTOM_COOLDOWN - (now - last), (CUSTOM_COOLDOWN - (now - last)) > 1 and "s" or ""),
        })
        return
    end

    customCooldown[jobName] = now

    local subtitle = custom.customSubtitle
    if type(subtitle) ~= "string" or subtitle == "" then subtitle = "Annonce" end

    TriggerClientEvent("vfw:showNotification", -1, buildAnnounce(
        society,
        VFW.Society.GetLabel(jobName),
        subtitle,
        type(custom.customTitleColor) == "string" and custom.customTitleColor or nil,
        stripColors(message:sub(1, 500))
    ))
end)

local function canEditAnnounces(xPlayer, jobName)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.name ~= jobName then return false end
    return VFW.Society.IsBossGrade(xPlayer.job)
end

local function sanitizeHex(value, fallback)
    if type(value) ~= "string" then return fallback end
    local hex = value:gsub("#", ""):upper()
    if hex:match("^%x%x%x%x%x%x$") then
        return "#" .. hex
    end
    return fallback
end

local function sanitizeText(value, maxLen)
    if type(value) ~= "string" then return nil end
    local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil end
    return trimmed:sub(1, maxLen or 255)
end

local function announcePayload(jobName)
    local society = VFW.Society.Get(jobName)
    local custom = society and type(society.custom) == "table" and society.custom or {}
    local allow = custom.allowCustomAnnouncement == true
    if not allow then
        local row = VFW.Society.Single("SELECT allow_custom_announcement FROM society_custom WHERE job_name = ?", { jobName })
        if row and (row.allow_custom_announcement == 1 or row.allow_custom_announcement == true) then
            allow = true
        end
    end

    return {
        company = VFW.Society.GetLabel(jobName),
        image = mediaUrl(society and society.image or ""),
        banner = mediaUrl(society and society.banner or ""),
        announceTitleColor = type(custom.announceTitleColor) == "string" and custom.announceTitleColor or "#FFFFFF",
        announceSubtitle = type(custom.announceSubtitle) == "string" and custom.announceSubtitle or "",
        openMessage = type(custom.openMessage) == "string" and custom.openMessage or "",
        closeMessage = type(custom.closeMessage) == "string" and custom.closeMessage or "",
        allowCustomAnnouncement = allow,
        customTitleColor = type(custom.customTitleColor) == "string" and custom.customTitleColor or "#FFFFFF",
        customSubtitle = type(custom.customSubtitle) == "string" and custom.customSubtitle or "",
    }
end

local function syncCustomAnnouncementFlag(jobName, allow)
    local flag = allow and 1 or 0
    local updated = VFW.Society.Update(
        "UPDATE society_custom SET allow_custom_announcement = ? WHERE job_name = ?",
        { flag, jobName }
    )
    if not updated or updated == 0 then
        pcall(function()
            VFW.Society.Update([[
                INSERT INTO society_custom (job_name, allow_custom_announcement)
                VALUES (?, ?)
            ]], { jobName, flag })
        end)
    end
end

VFW.Society.RegisterCallback("core:jobs:getAnnounces", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if type(jobName) ~= "string" or jobName == "" then
        jobName = xPlayer and xPlayer.job and xPlayer.job.name
    end
    if not xPlayer or not xPlayer.job or type(jobName) ~= "string" or jobName == "" then
        return nil
    end
    return announcePayload(jobName)
end)

VFW.Society.RegisterCallback("core:jobs:saveAnnounces", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then
        return false, "Entreprise introuvable."
    end

    local jobName = xPlayer.job.name
    if not canEditAnnounces(xPlayer, jobName) then
        return false, "Seul le patron peut créer les annonces."
    end
    if type(data) ~= "table" then
        return false, "Données invalides."
    end

    local society, resolvedName = VFW.Society.Ensure(jobName)
    jobName = resolvedName or jobName
    if not society then
        return false, "Entreprise introuvable."
    end

    local custom = VFW.Society.Copy(society.custom or {})
    custom.announceTitleColor = sanitizeHex(data.announceTitleColor, custom.announceTitleColor or "#FFFFFF")
    custom.customTitleColor = sanitizeHex(data.customTitleColor, custom.customTitleColor or "#FFFFFF")
    custom.announceSubtitle = sanitizeText(data.announceSubtitle, 80)
    custom.customSubtitle = sanitizeText(data.customSubtitle, 80)
    custom.openMessage = sanitizeText(data.openMessage, 500)
    custom.closeMessage = sanitizeText(data.closeMessage, 500)
    custom.allowCustomAnnouncement = data.allowCustomAnnouncement == true

    local image = sanitizeMediaUrl(data.image)
    local banner = sanitizeMediaUrl(data.banner)

    local encoded = VFW.DB.Encode(custom)
    local updated = VFW.Society.Update(
        "UPDATE societies SET custom = ?, image = ?, banner = ? WHERE name = ?",
        { encoded, image, banner, jobName }
    )
    if not updated or updated == 0 then
        VFW.Society.Update([[
            INSERT INTO societies (name, label, type, image, banner, custom)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                custom = VALUES(custom),
                image = VALUES(image),
                banner = VALUES(banner)
        ]], { jobName, society.label or jobName, society.type or "society", image, banner, encoded })
    end
    society.custom = custom
    society.image = image
    society.banner = banner
    VFW.Society.Reload(jobName)
    if VFW.Society.BroadcastToJob then
        VFW.Society.BroadcastToJob(jobName)
    end
    syncCustomAnnouncementFlag(jobName, custom.allowCustomAnnouncement)

    return true, "Annonces enregistrées.", announcePayload(jobName)
end)
