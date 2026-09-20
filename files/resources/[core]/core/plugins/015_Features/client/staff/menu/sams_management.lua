---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Staff SAMS Management - Client Side
-- Permission: sams_management
-- ============================================================

-- Local state
StaffMenu.samsData = {
    announcements = {},
    reports = {},
    invoices = {},
    personnel = {},
    selectedAnnouncement = nil,
    selectedReport = nil,
    selectedInvoice = nil,
    selectedHospital = nil,       -- "pillbox" | "paleto"
  selectedHospitalLabel = nil,
    selectedGrade = nil,          -- number
    selectedGradeLabel = nil,
    hospitalGrades = {},          -- [{ grade, label }]
    gradePermissionsMap = {},     -- { [gradeStr] = perms }
    bossGrades = { 99, 98 },
    gradePermissions = {},        -- working copy for the selected grade
}

-- ============================================================
-- MAIN MENU
-- ============================================================

function StaffMenu.BuildSamsManagementMenu()
    -- Bouton MDT Staff (uniquement si la permission mdt_sams_staff est accordée)
    if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["mdt_sams_staff"] then
        StaffMenu.samsManagement.Button(":monitor: MDT STAFF", "Ouvrir le MDT SAMS avec accès complet (toutes permissions)", nil, "chevron", false, function()
            SN_SAMS.OpenMDTStaff()
        end)
        StaffMenu.samsManagement.Separator(nil)
    end

    StaffMenu.samsManagement.Button(":megaphone: ANNONCES", "Consulter et supprimer les annonces SAMS", nil, "chevron", false, function()
    end, StaffMenu.samsAnnonces)

    StaffMenu.samsManagement.Button(":report: RAPPORTS", "Consulter, modifier et supprimer les rapports", nil, "chevron", false, function()
    end, StaffMenu.samsRapports)

    StaffMenu.samsManagement.Button(":money: FACTURES", "Consulter, modifier et annuler les factures", nil, "chevron", false, function()
    end, StaffMenu.samsFactures)

    StaffMenu.samsManagement.Button(":users: PERSONNEL & PERMISSIONS", "Gérer les permissions des agents SAMS", nil, "chevron", false, function()
    end, StaffMenu.samsPerms)
end

-- ============================================================
-- ANNONCES
-- ============================================================

function StaffMenu.BuildSamsAnnoncesMenu()
    StaffMenu.samsData.announcements = TriggerServerCallback("vfw:staff:sams:getAnnouncements") or {}

    local announcements = StaffMenu.samsData.announcements

    if #announcements == 0 then
        StaffMenu.samsAnnonces.Textbox("Aucune annonce trouvée.", "Information")
        return
    end

    for _, ann in ipairs(announcements) do
        local priorityLabel = ""
      if ann.priority == "urgent" then priorityLabel = "[URGENT] " end
        if ann.priority == "important" then priorityLabel = "[IMPORTANT] " end

        local label = priorityLabel .. "" .. (ann.title or "Sans titre")
        local desc = (ann.hospital or "all") .. " | " .. (ann.author or "Inconnu") .. " | " .. (ann.timestamp or "")

        StaffMenu.samsAnnonces.Button(label, desc, nil, "chevron", false, function()
            StaffMenu.samsData.selectedAnnouncement = ann
        end, StaffMenu.samsAnnonceDetail)
    end
end

function StaffMenu.BuildSamsAnnonceDetailMenu()
    local ann = StaffMenu.samsData.selectedAnnouncement
    if not ann then return end

    local priorityLabels = { urgent = "Urgent", important = "Important", normal = "Normal" }
    local priorityDisplay = priorityLabels[ann.priority] or ann.priority or "Normal"
  local hospitalDisplay = ann.hospital == "paleto" and "Paleto Bay" or (ann.hospital == "all" and "Tous" or "Pillbox Hill")

    StaffMenu.samsAnnonceDetail.Button("Titre: " .. (ann.title or "Sans titre"), nil, nil, nil, false, function() end)
    StaffMenu.samsAnnonceDetail.Button("Priorite: " .. priorityDisplay, nil, nil, nil, false, function() end)
    StaffMenu.samsAnnonceDetail.Button("Hopital: " .. hospitalDisplay, nil, nil, nil, false, function() end)
    StaffMenu.samsAnnonceDetail.Button("Auteur: " .. (ann.author or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.samsAnnonceDetail.Button("Date: " .. (ann.timestamp or "N/A"), nil, nil, nil, false, function() end)

    if ann.content and ann.content ~= "" then
        StaffMenu.samsAnnonceDetail.Separator("Contenu")
        StaffMenu.samsAnnonceDetail.Button(ann.content, nil, nil, nil, false, function() end)
    end

    StaffMenu.samsAnnonceDetail.Separator(nil)

    StaffMenu.samsAnnonceDetail.Button(":trash: SUPPRIMER L'ANNONCE", "Action irréversible", nil, nil, false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer la suppression", "")
        if confirm and confirm:lower() == "oui" then
            TriggerServerEvent("vfw:staff:sams:deleteAnnouncement", tonumber(ann.id))
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                message = "Annonce #" .. ann.id .. " supprimée."
          })
            StaffMenu.samsAnnonces.open()
        end
    end)
end

-- ============================================================
-- RAPPORTS
-- ============================================================

function StaffMenu.BuildSamsRapportsMenu()
    StaffMenu.samsData.reports = TriggerServerCallback("vfw:staff:sams:getReports") or {}

    local reports = StaffMenu.samsData.reports

    if #reports == 0 then
        StaffMenu.samsRapports.Textbox("Aucun rapport trouvé.", "Information")
        return
    end

    for _, report in ipairs(reports) do
        local typeLabel = report.type == "operation" and "[OP]" or "[INT]"
      local deletedTag = report.deletedAt and " [SUPPRIME]" or ""
      local label = typeLabel .. " " .. (report.citizenName or "Inconnu") .. deletedTag
        local desc = (report.hospital or "") .. " | " .. (report.createdBy or "Inconnu") .. " | " .. (report.timestamp or "")

        StaffMenu.samsRapports.Button(label, desc, nil, "chevron", false, function()
            StaffMenu.samsData.selectedReport = report
        end, StaffMenu.samsRapportDetail)
    end
end

function StaffMenu.BuildSamsRapportDetailMenu()
    local report = StaffMenu.samsData.selectedReport
    if not report then return end

    local typeDisplay = report.type == "operation" and "Operation" or "Intervention"
  local hospitalDisplay = report.hospital == "paleto" and "Paleto Bay" or "Pillbox Hill"

  StaffMenu.samsRapportDetail.Button("Type: " .. typeDisplay, nil, nil, nil, false, function() end)
    StaffMenu.samsRapportDetail.Button("Patient: " .. (report.citizenName or "Inconnu"), report.citizenId or "", nil, nil, false, function() end)
    StaffMenu.samsRapportDetail.Button("Raison: " .. (report.reason or "N/A"), nil, nil, nil, false, function() end)
    if report.reasonDetail and report.reasonDetail ~= "" then
        StaffMenu.samsRapportDetail.Button("Detail: " .. report.reasonDetail, nil, nil, nil, false, function() end)
    end
    StaffMenu.samsRapportDetail.Button("Lieu: " .. (report.location or "N/A"), nil, nil, nil, false, function() end)
    StaffMenu.samsRapportDetail.Button("Hopital: " .. hospitalDisplay, nil, nil, nil, false, function() end)
    StaffMenu.samsRapportDetail.Button("Auteur: " .. (report.createdBy or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.samsRapportDetail.Button("Date: " .. (report.timestamp or "N/A"), nil, nil, nil, false, function() end)

    if report.deletedAt then
        StaffMenu.samsRapportDetail.Separator("Suppression")
        StaffMenu.samsRapportDetail.Button("Supprime par: " .. (report.deletedBy or "Inconnu"), nil, nil, nil, false, function() end)
    end

    if report.description and report.description ~= "" then
        StaffMenu.samsRapportDetail.Separator("Description")
        StaffMenu.samsRapportDetail.Button(report.description, nil, nil, nil, false, function() end)
    end

    if report.recommendations and report.recommendations ~= "" then
        StaffMenu.samsRapportDetail.Separator("Recommandations")
        StaffMenu.samsRapportDetail.Button(report.recommendations, nil, nil, nil, false, function() end)
    end

    if report.prescriptions and report.prescriptions ~= "" then
        StaffMenu.samsRapportDetail.Separator("Prescriptions")
        StaffMenu.samsRapportDetail.Button(report.prescriptions, nil, nil, nil, false, function() end)
    end

    StaffMenu.samsRapportDetail.Separator(nil)

    -- Edit buttons
    StaffMenu.samsRapportDetail.Button(":edit: Modifier la description", nil, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle description", report.description or "")
        if input and input ~= "" then
            TriggerServerEvent("vfw:staff:sams:editReport", tonumber(report.id), "description", input)
            report.description = input
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                message = "Description mise a jour."
          })
            StaffMenu.samsRapportDetail.refresh()
        end
    end)

    StaffMenu.samsRapportDetail.Button(":edit: Modifier les recommandations", nil, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelles recommandations", report.recommendations or "")
        if input and input ~= "" then
            TriggerServerEvent("vfw:staff:sams:editReport", tonumber(report.id), "recommendations", input)
            report.recommendations = input
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                message = "Recommandations mises a jour."
          })
            StaffMenu.samsRapportDetail.refresh()
        end
    end)

    StaffMenu.samsRapportDetail.Button(":flask: Modifier les prescriptions", nil, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelles prescriptions", report.prescriptions or "")
        if input and input ~= "" then
            TriggerServerEvent("vfw:staff:sams:editReport", tonumber(report.id), "prescriptions", input)
            report.prescriptions = input
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                message = "Prescriptions mises a jour."
          })
            StaffMenu.samsRapportDetail.refresh()
        end
    end)

    StaffMenu.samsRapportDetail.Button(":pin: Modifier le lieu", nil, nil, nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau lieu", report.location or "")
        if input and input ~= "" then
            TriggerServerEvent("vfw:staff:sams:editReport", tonumber(report.id), "location", input)
            report.location = input
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                message = "Lieu mis à jour."
          })
            StaffMenu.samsRapportDetail.refresh()
        end
    end)

    StaffMenu.samsRapportDetail.Separator(nil)

    if report.deletedAt then
        -- Rapport deja supprime (soft delete) -> Restaurer ou Supprimer definitivement
        StaffMenu.samsRapportDetail.Button(":refresh: RESTAURER LE RAPPORT", "Annuler la suppression", nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour restaurer le rapport", "")
            if confirm and confirm:lower() == "oui" then
                TriggerServerEvent("vfw:staff:sams:restoreReport", tonumber(report.id))
                report.deletedAt = nil
                report.deletedBy = nil
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                    message = "Rapport #" .. report.id .. " restaure."
              })
                StaffMenu.samsRapports.open()
            end
        end)

        StaffMenu.samsRapportDetail.Button(":ban: SUPPRIMER DEFINITIVEMENT", "Suppression irreversible, aucune restauration possible", nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'SUPPRIMER' en majuscules pour confirmer", "")
            if confirm and confirm == "SUPPRIMER" then
                TriggerServerEvent("vfw:staff:sams:permanentDeleteReport", tonumber(report.id))
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                    message = "Rapport #" .. report.id .. " définitivement supprimé."
              })
                StaffMenu.samsRapports.open()
            end
        end)
    else
        -- Rapport actif -> Supprimer (soft delete)
        StaffMenu.samsRapportDetail.Button(":trash: SUPPRIMER LE RAPPORT", "Le rapport pourra être restauré", nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer la suppression", "")
            if confirm and confirm:lower() == "oui" then
                TriggerServerEvent("vfw:staff:sams:deleteReport", tonumber(report.id))
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                    message = "Rapport #" .. report.id .. " supprimé."
              })
                StaffMenu.samsRapports.open()
            end
        end)
    end
end

-- ============================================================
-- FACTURES
-- ============================================================

function StaffMenu.BuildSamsFacturesMenu()
    StaffMenu.samsData.invoices = TriggerServerCallback("vfw:staff:sams:getInvoices") or {}

    local invoices = StaffMenu.samsData.invoices

    if #invoices == 0 then
        StaffMenu.samsFactures.Textbox("Aucune facture trouvée.", "Information")
        return
    end

    for _, inv in ipairs(invoices) do
        local statusLabel = "[PAYEE]"
      if inv.status == "pending" then statusLabel = "[EN ATTENTE]" end
        if inv.status == "cancelled" then statusLabel = "[ANNULEE]" end

        local label = statusLabel .. " " .. (inv.citizenName or "Inconnu") .. " - " .. VFW.Math.FormatMoney(inv.total or 0)
        local desc = "#" .. (inv.id or "?") .. " | " .. (inv.hospital or "") .. " | " .. (inv.createdAt or "")

        StaffMenu.samsFactures.Button(label, desc, nil, "chevron", false, function()
            StaffMenu.samsData.selectedInvoice = inv
        end, StaffMenu.samsFactureDetail)
    end
end

function StaffMenu.BuildSamsFactureDetailMenu()
    local inv = StaffMenu.samsData.selectedInvoice
    if not inv then return end

    local statusLabels = { pending = "En attente", paid = "Payee", cancelled = "Annulee" }
    local statusDisplay = statusLabels[inv.status] or inv.status or "N/A"
  local hospitalDisplay = inv.hospital == "paleto" and "Paleto Bay" or "Pillbox Hill"

  StaffMenu.samsFactureDetail.Button("Facture #" .. (inv.id or "N/A"), "Identifiant de la facture", nil, nil, false, function() end)
    StaffMenu.samsFactureDetail.Button("Patient: " .. (inv.citizenName or "Inconnu"), inv.citizenId or "", nil, nil, false, function() end)
    -- Calculate total from items
    local function recalcTotal()
        local total = 0
        if inv.items and type(inv.items) == "table" then
            for _, item in ipairs(inv.items) do
                local price = tonumber(item.price) or 0
                local qty = tonumber(item.quantity) or tonumber(item.qty) or 1
                total = total + (price * qty)
            end
        end
        return total
    end

    StaffMenu.samsFactureDetail.Button("Montant total: " .. VFW.Math.FormatMoney(inv.total or 0), "Calcule automatiquement depuis les articles", nil, nil, false, function() end)
    StaffMenu.samsFactureDetail.Button("Statut: " .. statusDisplay, nil, nil, nil, false, function() end)
    StaffMenu.samsFactureDetail.Button("Hopital: " .. hospitalDisplay, nil, nil, nil, false, function() end)
    StaffMenu.samsFactureDetail.Button("Cree par: " .. (inv.createdBy or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.samsFactureDetail.Button("Date: " .. (inv.createdAt or "N/A"), nil, nil, nil, false, function() end)

    if inv.items and type(inv.items) == "table" and #inv.items > 0 then
        StaffMenu.samsFactureDetail.Separator("Articles" .. (inv.status == "pending" and " (cliquez pour modifier)" or ""))
        for i, item in ipairs(inv.items) do
            local itemLabel = item.label or item.name or "Item"
          local itemPrice = tonumber(item.price) or 0
            local itemQty = tonumber(item.quantity) or tonumber(item.qty) or 1
            local lineTotal = itemPrice * itemQty
            local desc = "Prix unitaire : " .. VFW.Math.FormatMoney(itemPrice) .. " | Quantité : " .. tostring(itemQty) .. " | Total : " .. VFW.Math.FormatMoney(lineTotal)

            if inv.status == "pending" then
                StaffMenu.samsFactureDetail.Button(itemLabel .. " x" .. tostring(itemQty), desc, nil, nil, false, function()
                    -- Edit unit price
                    local inputPrice = VFW.Nui.KeyboardInput(true, "Prix unitaire pour " .. itemLabel, tostring(itemPrice))
                    if not inputPrice then return end
                    local newPrice = tonumber(inputPrice)
                    if not newPrice or newPrice < 0 then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SAMS', message = "Ce prix n'est pas valide." })
                        return
                    end

                    -- Edit quantity
                    local inputQty = VFW.Nui.KeyboardInput(true, "Quantité pour " .. itemLabel, tostring(itemQty))
                    if not inputQty then return end
                    local newQty = tonumber(inputQty)
                    if not newQty or newQty < 1 then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SAMS', message = "Cette quantité n'est pas valide (min 1)." })
                        return
                    end

                    -- Update local data
                    inv.items[i].price = newPrice
                    inv.items[i].quantity = newQty
                    inv.total = recalcTotal()

                    -- Send to server
                    TriggerServerEvent("vfw:staff:sams:editInvoiceItems", tonumber(inv.id), inv.items)

                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                        message = itemLabel .. ": " .. VFW.Math.FormatMoney(newPrice) .. " x" .. tostring(newQty) .. " | Nouveau total: " .. VFW.Math.FormatMoney(inv.total)
                    })
                    StaffMenu.samsFactureDetail.refresh()
                end)
            else
                StaffMenu.samsFactureDetail.Button(itemLabel .. " x" .. tostring(itemQty), desc, nil, nil, false, function() end)
            end
        end
    end

    StaffMenu.samsFactureDetail.Separator(nil)

    -- Only show action buttons for pending invoices
    if inv.status == "pending" then
        StaffMenu.samsFactureDetail.Button(":x: ANNULER LA FACTURE", "Passe le statut a 'annulee'", nil, nil, false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer l'annulation", "")
            if confirm and confirm:lower() == "oui" then
                TriggerServerEvent("vfw:staff:sams:cancelInvoice", tonumber(inv.id))
                inv.status = "cancelled"
              VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
                    message = "Facture #" .. inv.id .. " annulee."
              })
                StaffMenu.samsFactures.open()
            end
        end)
    end
end

-- ============================================================
-- PERSONNEL & PERMISSIONS
-- ============================================================

local HOSPITAL_LABELS = {
    pillbox = "Pillbox Hill",
    paleto  = "Paleto Bay",
}

local PERM_GROUPS = {
    { label = ":megaphone: Annonces",     keys = { "create_announcement", "edit_announcement", "delete_announcement" } },
    { label = ":report: Rapports",     keys = { "create_report", "edit_report", "delete_report" } },
    { label = ":money: Factures",     keys = { "create_invoice", "cancel_invoice" } },
    { label = ":edit: Notes",        keys = { "add_note", "delete_note" } },
    { label = ":siren: Alertes",      keys = { "take_alert" } },
    { label = ":flask: Soins",        keys = { "create_treatment", "edit_treatment", "delete_treatment" } },
    { label = ":document: Procédures",   keys = { "create_procedure", "edit_procedure", "delete_procedure" } },
    { label = ":report: Documents",    keys = { "create_document" } },
    { label = ":info: PPA",          keys = { "manage_ppa" } },
    { label = ":hospital: Pharmacie",    keys = { "pharmacy_buy_sams_items", "pharmacy_society_payment" } },
    { label = ":key: Administration", keys = { "manage_permissions" } },
}

local PERM_LABELS = {
    create_announcement = "Créer une annonce",
    edit_announcement   = "Modifier une annonce",
    delete_announcement = "Supprimer une annonce",
    create_report       = "Créer un rapport",
    edit_report         = "Modifier un rapport",
    delete_report       = "Supprimer un rapport",
    create_invoice      = "Créer une facture",
    cancel_invoice      = "Annuler une facture",
    add_note            = "Ajouter une note",
    delete_note         = "Supprimer une note",
    take_alert          = "Prendre en charge une alerte",
    create_treatment    = "Créer un soin",
    edit_treatment      = "Modifier un soin",
    delete_treatment    = "Supprimer un soin",
    create_procedure    = "Créer une procédure",
    edit_procedure      = "Modifier une procédure",
    delete_procedure    = "Supprimer une procédure",
    create_document     = "Créer un document",
    manage_ppa          = "Gérer les PPA",
    pharmacy_buy_sams_items  = "Acheter des items SAMS",
    pharmacy_society_payment = "Paiement via société",
    manage_permissions  = "Gérer les permissions",
}

local function isBossGrade(grade, bossGrades)
    for _, g in ipairs(bossGrades or {}) do
        if g == grade then return true end
    end
    return false
end

local function loadHospitalGrades(hospital)
    local data = TriggerServerCallback("vfw:staff:sams:getGradePermissions", hospital) or {}
    StaffMenu.samsData.selectedHospital = hospital
    StaffMenu.samsData.selectedHospitalLabel = HOSPITAL_LABELS[hospital] or hospital
    StaffMenu.samsData.hospitalGrades = data.grades or {}
    StaffMenu.samsData.gradePermissionsMap = data.permissions or {}
    StaffMenu.samsData.bossGrades = data.bossGrades or { 99, 98 }
end

function StaffMenu.BuildSamsPermsMenu()
    StaffMenu.samsPerms.Textbox("Choisir l'hôpital pour gérer les permissions par grade.", "Information")

    StaffMenu.samsPerms.Button(":hospital: Pillbox Hill", "Gérer les grades de Pillbox (sams_pib)", nil, "chevron", false, function()
        loadHospitalGrades("pillbox")
    end, StaffMenu.samsPermGrades)

    StaffMenu.samsPerms.Button(":hospital: Paleto Bay", "Gérer les grades de Paleto (sams_pab)", nil, "chevron", false, function()
        loadHospitalGrades("paleto")
    end, StaffMenu.samsPermGrades)
end

function StaffMenu.BuildSamsPermGradesMenu()
    local hospital = StaffMenu.samsData.selectedHospital
    if not hospital then return end
    local grades = StaffMenu.samsData.hospitalGrades or {}
    local bossGrades = StaffMenu.samsData.bossGrades or { 99, 98 }

    StaffMenu.samsPermGrades.Button("Hôpital: " .. (StaffMenu.samsData.selectedHospitalLabel or hospital), nil, nil, nil, false, function() end)
    StaffMenu.samsPermGrades.Separator(nil)

    if #grades == 0 then
        StaffMenu.samsPermGrades.Textbox("Aucun grade trouvé dans job_grades pour cet hôpital.", "Information")
        return
    end

    for _, g in ipairs(grades) do
        local isBoss = isBossGrade(g.grade, bossGrades)
        local label = "Grade " .. tostring(g.grade) .. " - " .. (g.label or "")
        local desc
        if isBoss then
            desc = "Responsable - toutes les permissions (non modifiable)"
      else
            local perms = StaffMenu.samsData.gradePermissionsMap[tostring(g.grade)] or {}
            local count = 0
            for _ in pairs(perms) do count = count + 1 end
            desc = count .. (count > 1 and " permissions accordées" or " permission accordée")
      end

        StaffMenu.samsPermGrades.Button(label, desc, nil, isBoss and nil or "chevron", isBoss, function()
            if isBoss then return end
            StaffMenu.samsData.selectedGrade = g.grade
            StaffMenu.samsData.selectedGradeLabel = g.label or ("Grade " .. tostring(g.grade))
            local src = StaffMenu.samsData.gradePermissionsMap[tostring(g.grade)] or {}
            local copy = {}
            for k, v in pairs(src) do copy[k] = v end
            StaffMenu.samsData.gradePermissions = copy
        end, isBoss and nil or StaffMenu.samsPermDetail)
    end
end

function StaffMenu.BuildSamsPermDetailMenu()
    local hospital = StaffMenu.samsData.selectedHospital
    local grade = StaffMenu.samsData.selectedGrade
    if not hospital or not grade then return end
    local perms = StaffMenu.samsData.gradePermissions or {}

    StaffMenu.samsPermDetail.Button("Hôpital: " .. (StaffMenu.samsData.selectedHospitalLabel or hospital), nil, nil, nil, false, function() end)
    StaffMenu.samsPermDetail.Button("Grade " .. tostring(grade) .. " - " .. (StaffMenu.samsData.selectedGradeLabel or ""), nil, nil, nil, false, function() end)

    for _, group in ipairs(PERM_GROUPS) do
        StaffMenu.samsPermDetail.Separator(group.label)
        for _, key in ipairs(group.keys) do
            local label = PERM_LABELS[key] or key
            StaffMenu.samsPermDetail.Checkbox(label, nil, false, perms[key] == true, function(checked)
                perms[key] = checked and true or nil
            end)
        end
    end

    StaffMenu.samsPermDetail.Separator(nil)

    StaffMenu.samsPermDetail.Button(":save: ENREGISTRER LES PERMISSIONS", nil, nil, nil, false, function()
        TriggerServerEvent("vfw:staff:sams:updateGradePermissions", hospital, grade, perms)
        -- Refresh local cache so the grades menu reflects the change
        local saved = {}
        for k, v in pairs(perms) do if v == true then saved[k] = true end end
        StaffMenu.samsData.gradePermissionsMap[tostring(grade)] = saved
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'SAMS',
            message = "Permissions du grade " .. tostring(grade) .. " mises à jour."
      })
    end)
end
