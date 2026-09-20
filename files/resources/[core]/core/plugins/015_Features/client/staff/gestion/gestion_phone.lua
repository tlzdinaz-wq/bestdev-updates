---@meta _
---@diagnostic disable: duplicate-doc-field

-- Liste des applications wipables. L'ordre conditionne l'affichage.
StaffMenu.PhoneApps = {
    { key = "all",                label = ":bolt: TOUT (toutes les apps)", desc = "Wipe complet du contenu lié à ce numéro" },
    { key = "messages",           label = ":chat: Messages (SMS)",         desc = "Supprime les messages et l'appartenance aux conversations" },
    { key = "mail",               label = ":document: Mail",                    desc = "Supprime les mails reçus et envoyés" },
    { key = "twitter",            label = ":leaf: DMs Twitter",           desc = "Consulter ou supprimer les DMs" },
    { key = "twitter_posts",      label = ":leaf: Tweets Twitter",        desc = "Consulter ou supprimer les tweets publiés" },
    { key = "instagram",          label = ":camera: DMs Instagram",         desc = "Consulter ou supprimer les DMs" },
    { key = "instagram_posts",    label = ":camera: Posts Instagram",       desc = "Consulter ou supprimer les posts publiés" },
    { key = "instagram_stories",  label = ":globe: Stories Instagram",     desc = "Consulter ou supprimer les stories" },
    { key = "tinder",             label = ":heart: Tinder",                  desc = "Supprime le compte, swipes, matches, messages" },
    { key = "notes",              label = ":edit: Notes",                   desc = "Supprime toutes les notes" },
    { key = "photos",             label = ":image: Galerie",                desc = "Supprime photos et albums" },
    { key = "contacts",           label = ":users: Contacts",                desc = "Supprime tous les contacts enregistrés" },
    { key = "calls",              label = ":chat: Historique d'appels",     desc = "Supprime l'historique d'appels" },
    { key = "voicemail",          label = ":music: Messagerie vocale",       desc = "Supprime les messages vocaux" },
}

StaffMenu.phoneSearchQuery = nil
StaffMenu.phoneCurrentPage = 1

--- .BuildGestionPhoneMenu
--- Liste paginée de tous les numéros attribués (tous joueurs confondus)
--- avec barre de recherche par numéro / prénom / nom RP.
function StaffMenu.BuildGestionPhoneMenu()
    local searchLabel = StaffMenu.phoneSearchQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.phoneSearchQuery == nil
        and "UN NUMÉRO, UN PRÉNOM OU UN NOM RP"
      or StaffMenu.phoneSearchQuery

    StaffMenu.gestionPhone.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.phoneSearchQuery ~= nil then
            StaffMenu.phoneSearchQuery = nil
            StaffMenu.phoneCurrentPage = 1
            StaffMenu.gestionPhone.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Recherche : numéro, prénom ou nom RP")
        if query == nil or query == "" then return end

        StaffMenu.phoneSearchQuery = query
        StaffMenu.phoneCurrentPage = 1
        StaffMenu.gestionPhone.refresh()
    end)

    local page = StaffMenu.phoneCurrentPage or 1
    local data = TriggerServerCallback(
        "vfw:staff:phone:listAllNumbers",
        page,
        StaffMenu.phoneSearchQuery
    ) or { items = {}, total = 0, pageSize = 20 }

    local total = data.total or 0
    local pageSize = data.pageSize or 20
    local maxPage = math.max(1, math.ceil(total / pageSize))
    if page > maxPage then
        page = maxPage
        StaffMenu.phoneCurrentPage = maxPage
    end

    if StaffMenu.phoneSearchQuery then
        StaffMenu.gestionPhone.Separator(("~ %d résultats, page %d sur %d ~"):format(total, page, maxPage))
    else
        StaffMenu.gestionPhone.Separator(("~ Numéros attribués, page %d sur %d, %d au total ~"):format(page, maxPage, total))
    end

    if #data.items == 0 then
        StaffMenu.gestionPhone.Separator(StaffMenu.phoneSearchQuery and "~ Aucun résultat ~" or "~ Aucun numéro ~")
        return
    end

    for _, phone in ipairs(data.items) do
        local title = (":chat: %s"):format(phone.phone_number)
        if phone.name and phone.name ~= "" then
            title = title .. ", " .. phone.name
        end
        if phone.uuid then
            title = title .. (", UUID #%s"):format(phone.uuid)
        end
        local subtitle = phone.phone_label and phone.phone_label ~= "" and phone.phone_label or "Voir les apps"
      StaffMenu.gestionPhone.Button(title, subtitle, nil, "chevron", false, function()
            StaffMenu.data.phoneTargetNumber = phone.phone_number
            StaffMenu.data.phoneTargetName = phone.name
        end, StaffMenu.gestionPhoneApps)
    end

    if maxPage > 1 then
        StaffMenu.gestionPhone.Separator(nil)
        if page > 1 then
            StaffMenu.gestionPhone.Button(":back: PAGE PRÉCÉDENTE", ("Page %d/%d"):format(page - 1, maxPage), nil, "arrow", false, function()
                StaffMenu.phoneCurrentPage = page - 1
                StaffMenu.gestionPhone.refresh()
            end)
        end
        if page < maxPage then
            StaffMenu.gestionPhone.Button("PAGE SUIVANTE :arrow:", ("Page %d/%d"):format(page + 1, maxPage), nil, "arrow", false, function()
                StaffMenu.phoneCurrentPage = page + 1
                StaffMenu.gestionPhone.refresh()
            end)
        end
    end
end

-- Apps qui supportent la consultation paginée. Les autres restent en wipe-confirm.
-- twitter / instagram listent les DMs ; twitter_posts / instagram_posts /
-- instagram_stories listent les contenus publiés. Le compte global reste nuke
-- via "Wipe complet".
StaffMenu.PhoneAppsWithHistory = {
    messages           = true,
    mail               = true,
    twitter            = true,
    twitter_posts      = true,
    instagram          = true,
    instagram_posts    = true,
    instagram_stories  = true,
    tinder             = true,
    notes              = true,
    photos             = true,
    contacts           = true,
    calls              = true,
    voicemail          = true,
}

--- .BuildGestionPhoneAppsMenu
--- Liste les apps : drill-down vers l'historique pour celles supportées, sinon
--- wipe direct avec confirmation.
function StaffMenu.BuildGestionPhoneAppsMenu()
    local phoneNumber = StaffMenu.data.phoneTargetNumber
    if not phoneNumber then
        StaffMenu.gestionPhoneApps.Button("Aucune cible", "Sélectionne un téléphone dans le menu précédent.", nil, nil, true, function() end)
        return
    end

    local ownerName = StaffMenu.data.phoneTargetName
    local header = ownerName and ownerName ~= ""
      and ("Numéro %s, %s"):format(phoneNumber, ownerName)
        or ("Cible: %s"):format(phoneNumber)
    StaffMenu.gestionPhoneApps.Separator(header)

    StaffMenu.gestionPhoneApps.Button(":trophy: GÉRER CERTIFICATIONS", "Basculer le badge vérifié sur Twitter, Instagram et TikTok", nil, "chevron", false, function() end, StaffMenu.gestionPhoneCertifs)

    StaffMenu.gestionPhoneApps.Separator("CONSULTATION & WIPE")

    for _, app in ipairs(StaffMenu.PhoneApps) do
        if app.key ~= "all" and StaffMenu.PhoneAppsWithHistory[app.key] then
            -- Drill into history menu for browse + per-item delete
            StaffMenu.gestionPhoneApps.Button(app.label, "Consulter ou supprimer", nil, "chevron", false, function()
                StaffMenu.data.phoneAppKey = app.key
                StaffMenu.data.phoneHistoryPage = 1
            end, StaffMenu.gestionPhoneHistory)
        else
            -- Wipe-confirm for apps without browse (and the "all" entry)
            StaffMenu.gestionPhoneApps.Button(app.label, app.desc, nil, "chevron", false, function()
                local confirm = VFW.Nui.KeyboardInput(true, ("Confirmer 'OUI' pour wipe %s"):format(app.label))
                if not confirm or string.lower(confirm) ~= "oui" then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Téléphone', message = "Annulé." })
                    return
                end
                TriggerServerEvent("vfw:staff:phone:wipeApp", phoneNumber, app.key)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Téléphone', message = ("Wipe demandé: %s"):format(app.label) })
            end)
        end
    end
end

--- .BuildGestionPhoneHistoryMenu
--- Affiche l'historique paginé de l'app sélectionnée et permet de supprimer
--- un message, la page courante, ou tout l'historique.
function StaffMenu.BuildGestionPhoneHistoryMenu()
    local phoneNumber = StaffMenu.data.phoneTargetNumber
    local appKey = StaffMenu.data.phoneAppKey
    local page = StaffMenu.data.phoneHistoryPage or 1
    if not phoneNumber or not appKey then
        StaffMenu.gestionPhoneHistory.Button("Aucune cible", "Sélectionne une app dans le menu précédent.", nil, nil, true, function() end)
        return
    end

    local result = TriggerServerCallback("vfw:staff:phone:getHistory", phoneNumber, appKey, page) or {}
    if not result.supported then
        StaffMenu.gestionPhoneHistory.Button("App non supportée", "La consultation n'est pas configurée pour cette app.", nil, nil, true, function() end)
        return
    end

    local total <const> = result.total or 0
    local pageSize <const> = result.pageSize or 10
    local maxPage <const> = math.max(1, math.ceil(total / pageSize))
    if page > maxPage then
        StaffMenu.data.phoneHistoryPage = maxPage
        page = maxPage
    end

    StaffMenu.gestionPhoneHistory.Separator(("%s, page %d sur %d, %d au total"):format(appKey, page, maxPage, total))

    if total == 0 or #result.items == 0 then
        StaffMenu.gestionPhoneHistory.Button("Aucune entrée", "L'historique est vide.", nil, nil, true, function() end)
        return
    end

    for _, item in ipairs(result.items) do
        local itemId <const> = item.id
        StaffMenu.gestionPhoneHistory.Button(item.label, "Cliquer pour supprimer ce message", nil, "trash", false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI' pour supprimer ce message")
            if not confirm or string.lower(confirm) ~= "oui" then return end
            TriggerServerEvent("vfw:staff:phone:deleteHistoryItems", phoneNumber, appKey, { itemId })
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Téléphone', message = "Message supprimé." })
            StaffMenu.gestionPhoneHistory.refresh()
        end)
    end

    StaffMenu.gestionPhoneHistory.Separator("NAVIGATION")
    if page > 1 then
        StaffMenu.gestionPhoneHistory.Button(":back: Page précédente", nil, nil, "arrow", false, function()
            StaffMenu.data.phoneHistoryPage = page - 1
            StaffMenu.gestionPhoneHistory.refresh()
        end)
    end
    if page < maxPage then
        StaffMenu.gestionPhoneHistory.Button("Page suivante :arrow:", nil, nil, "arrow", false, function()
            StaffMenu.data.phoneHistoryPage = page + 1
            StaffMenu.gestionPhoneHistory.refresh()
        end)
    end

    StaffMenu.gestionPhoneHistory.Separator("SUPPRESSION GROUPÉE")
    StaffMenu.gestionPhoneHistory.Button(":trash: Supprimer la page courante", (#result.items > 1 and "%d entrées" or "%d entrée"):format(#result.items), nil, "trash", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI' pour supprimer la page courante")
        if not confirm or string.lower(confirm) ~= "oui" then return end
        local ids = {}
        for _, it in ipairs(result.items) do ids[#ids + 1] = it.id end
        TriggerServerEvent("vfw:staff:phone:deleteHistoryItems", phoneNumber, appKey, ids)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Téléphone', message = (#ids > 1 and "%d entrées supprimées." or "%d entrée supprimée."):format(#ids) })
        StaffMenu.gestionPhoneHistory.refresh()
    end)

    StaffMenu.gestionPhoneHistory.Button(":bolt: Supprimer TOUT l'historique", ("Wipe complet de %s"):format(appKey), nil, "trash", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI' pour wipe complet")
        if not confirm or string.lower(confirm) ~= "oui" then return end
        TriggerServerEvent("vfw:staff:phone:wipeApp", phoneNumber, appKey)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Téléphone', message = "Wipe complet demandé." })
        StaffMenu.data.phoneHistoryPage = 1
        StaffMenu.gestionPhoneHistory.refresh()
    end)
end

local CERTIF_APP_LABEL = {
    twitter   = ":leaf: Twitter",
    instagram = ":camera: Instagram",
    tiktok    = ":music: TikTok",
}

--- .BuildGestionPhoneCertifsMenu
--- Liste les comptes social du numéro et permet de toggle leur certif.
function StaffMenu.BuildGestionPhoneCertifsMenu()
    local phoneNumber = StaffMenu.data.phoneTargetNumber
    if not phoneNumber then
        StaffMenu.gestionPhoneCertifs.Button("Aucune cible", "Sélectionne un téléphone dans le menu précédent.", nil, nil, true, function() end)
        return
    end

    local accounts = TriggerServerCallback("vfw:staff:phone:getCertifs", phoneNumber) or {}

    StaffMenu.gestionPhoneCertifs.Separator(("Cible: %s"):format(phoneNumber))

    if #accounts == 0 then
        StaffMenu.gestionPhoneCertifs.Button("Aucun compte", "Ce numéro n'a aucun compte social", nil, nil, true, function() end)
        return
    end

    for _, acc in ipairs(accounts) do
        local appLabel = CERTIF_APP_LABEL[acc.app] or acc.app
        local title = ("%s, @%s"):format(appLabel, acc.username)
        local isChecked = acc.verified == 1 or acc.verified == true
        StaffMenu.gestionPhoneCertifs.Checkbox(title, isChecked and "Vérifié :check:" or "Non vérifié", false, isChecked, function(_checked)
            TriggerServerEvent("vfw:staff:phone:setCertif", phoneNumber, acc.app, acc.username, _checked)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Gestion Téléphone',
                message = ("@%s sur %s : %s"):format(acc.username, appLabel, _checked and "certifié" or "décertifié")
            })
        end)
    end
end
