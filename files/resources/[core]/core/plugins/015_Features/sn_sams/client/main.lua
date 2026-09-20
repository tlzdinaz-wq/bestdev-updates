---@meta _
---@diagnostic disable: duplicate-doc-field

local isMDTOpen = false
local isMDTMinimized = false
local mdtTabletProp = nil
local lastActionTime = 0
local ACTION_COOLDOWN = 2000 -- 2 secondes

-- Controles a desactiver quand le MDT est ouvert avec keepInput
-- (empeche tir, visee, rotation camera, melee, etc.)
local MDT_DISABLED_CONTROLS <const> = {
    1, 2,           -- Look LR / UD (camera mouse)
    24, 25,         -- Attack / Aim
    47,             -- Weapon
    58,             -- Throw grenade
    106,            -- VehicleMouseControlOverride
    140, 141, 142, 143, -- Melee attacks & block
    257,            -- Attack2
    263, 264,       -- Melee attack 1 & 2
}

--- Verifie si une action est autorisee (rate limiting)
---@return boolean
local function canPerformAction()
    -- Bypass pour les staff avec acces MDT complet
    if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
       and VFW.PlayerGlobalData.permissions["mdt_sams_staff"] then
        return true
    end
    local now = GetGameTimer()
    if now - lastActionTime < ACTION_COOLDOWN then
        return false
    end
    lastActionTime = now
    return true
end

-- ============================================================
-- Ouverture / Fermeture du MDT
-- ============================================================

--- Verifie si le MDT SAMS est ouvert
---@return boolean
function SN_SAMS.IsMDTOpen()
    return isMDTOpen
end

--- Ouvre le MDT SAMS
function SN_SAMS.OpenMDT()
    if isMDTOpen then return end
    if not SN_SAMS.IsOnDuty() then return end

    local data = TriggerServerCallback("sn_sams:openMDT")
    if not data then
        VFW.ShowNotification({ type = 'JOB', logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Erreur", content = "Impossible d'ouvrir le MDT." })
        return
    end

    isMDTOpen = true

    -- Envoyer les donnees de l'agent et ouvrir le MDT
    SendNUIMessage({
        action = "nui:sams:open",
        data = data.agent
    })

    -- Envoyer les stats
    SendNUIMessage({
        action = "nui:sams:stats",
        data = data.stats
    })

    -- Envoyer les datasets
    SendNUIMessage({ action = "nui:sams:setLogs", data = data.logs })
    SendNUIMessage({ action = "nui:sams:setReports", data = data.reports })
    SendNUIMessage({ action = "nui:sams:setAnnouncements", data = data.announcements })
    SendNUIMessage({ action = "nui:sams:setInvoices", data = data.invoices })
    SendNUIMessage({ action = "nui:sams:setTreatments", data = data.treatments })
    SendNUIMessage({ action = "nui:sams:setProcedures", data = data.procedures })
    SendNUIMessage({ action = "nui:sams:setDocuments", data = data.documents })
    SendNUIMessage({ action = "nui:sams:setMedecins", data = data.medecins })
    SendNUIMessage({ action = "nui:sams:setAlerts", data = data.alerts })
    SendNUIMessage({ action = "nui:sams:setZones", data = SN_SAMS.MuteZones or {} })

    -- Focus avec keepInput pour permettre le mouvement
    VFW.Nui.Focus(true, true)

    -- Boucle de desactivation des controles dangereux + minimize/restore (Espace)
    CreateThread(function()
        while isMDTOpen do
            if isMDTMinimized then
                Wait(0)
                -- Quand minimise, detecter Espace pour restaurer
                if IsControlJustPressed(0, 22) then -- Space
                    isMDTMinimized = false
                    VFW.Nui.Focus(true, true)
                    SendNUIMessage({
                        action = "nui:sams:restore",
                        data = {}
                    })
                end
            else
                Wait(0)
                for i = 1, #MDT_DISABLED_CONTROLS do
                    DisableControlAction(0, MDT_DISABLED_CONTROLS[i], true)
                end
            end
        end
    end)

    -- Prop tablette + animation
    CreateThread(function()
        if not isMDTOpen then return end

        local ped = PlayerPedId()
        local dict = "amb@world_human_seat_wall_tablet@female@base"
        local anim = "base"
        local propModel = "prop_cs_tablet"

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end

        RequestModel(propModel)
        while not HasModelLoaded(propModel) do Wait(10) end

        mdtTabletProp = CreateObject(GetHashKey(propModel), 0.0, 0.0, 0.0, false, true, false)
        AttachEntityToEntity(mdtTabletProp, ped, GetPedBoneIndex(ped, 28422),
            -0.01, 0.0, 0.0,
            0.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )

        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

        while isMDTOpen do
            if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Wait(500)
        end

        ClearPedTasks(ped)
        if mdtTabletProp and DoesEntityExist(mdtTabletProp) then
            DeleteEntity(mdtTabletProp)
            mdtTabletProp = nil
        end
    end)
end

--- Ouvre le MDT SAMS en mode Staff (sans vérification IsOnDuty, toutes perms)
function SN_SAMS.OpenMDTStaff()
    if isMDTOpen then return end

    local data = TriggerServerCallback("sn_sams:openMDTStaff")
    if not data then
        VFW.ShowNotification({ type = 'STAFF', subtitle = 'MDT SAMS', content = "Impossible d'ouvrir le MDT." })
        return
    end

    isMDTOpen = true

    SendNUIMessage({ action = "nui:sams:open",          data = data.agent })
    SendNUIMessage({ action = "nui:sams:stats",         data = data.stats })
    SendNUIMessage({ action = "nui:sams:setLogs",        data = data.logs })
    SendNUIMessage({ action = "nui:sams:setReports",     data = data.reports })
    SendNUIMessage({ action = "nui:sams:setAnnouncements", data = data.announcements })
    SendNUIMessage({ action = "nui:sams:setInvoices",    data = data.invoices })
    SendNUIMessage({ action = "nui:sams:setTreatments",  data = data.treatments })
    SendNUIMessage({ action = "nui:sams:setProcedures",  data = data.procedures })
    SendNUIMessage({ action = "nui:sams:setDocuments",   data = data.documents })
    SendNUIMessage({ action = "nui:sams:setMedecins",    data = data.medecins })
    SendNUIMessage({ action = "nui:sams:setAlerts",      data = data.alerts })
    SendNUIMessage({ action = "nui:sams:setZones",       data = SN_SAMS.MuteZones or {} })

    VFW.Nui.Focus(true, true)

    -- Boucle de désactivation des contrôles + minimize/restore (Espace)
    CreateThread(function()
        while isMDTOpen do
            if isMDTMinimized then
                Wait(0)
                if IsControlJustPressed(0, 22) then -- Space
                    isMDTMinimized = false
                    VFW.Nui.Focus(true, true)
                    SendNUIMessage({ action = "nui:sams:restore", data = {} })
                end
            else
                Wait(0)
                for i = 1, #MDT_DISABLED_CONTROLS do
                    DisableControlAction(0, MDT_DISABLED_CONTROLS[i], true)
                end
            end
        end
    end)

    -- Prop tablette + animation
    CreateThread(function()
        if not isMDTOpen then return end

        local ped = PlayerPedId()
        local dict = "amb@world_human_seat_wall_tablet@female@base"
        local anim = "base"
        local propModel = "prop_cs_tablet"

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end

        RequestModel(propModel)
        while not HasModelLoaded(propModel) do Wait(10) end

        mdtTabletProp = CreateObject(GetHashKey(propModel), 0.0, 0.0, 0.0, false, true, false)
        AttachEntityToEntity(mdtTabletProp, ped, GetPedBoneIndex(ped, 28422),
            -0.01, 0.0, 0.0,
            0.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )

        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

        while isMDTOpen do
            if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Wait(500)
        end

        ClearPedTasks(ped)
        if mdtTabletProp and DoesEntityExist(mdtTabletProp) then
            DeleteEntity(mdtTabletProp)
            mdtTabletProp = nil
        end
    end)
end

--- Ferme le MDT SAMS
function SN_SAMS.CloseMDT()
    if not isMDTOpen then return end

    isMDTOpen = false
    isMDTMinimized = false

    SendNUIMessage({
        action = "nui:sams:visible",
        data = { visible = false }
    })

    VFW.Nui.Focus(false)
    TriggerServerEvent("sn_sams:closeMDT")
end

-- ============================================================
-- Cleanup on resource stop
-- ============================================================
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not isMDTOpen then return end

    isMDTOpen = false
    isMDTMinimized = false
    VFW.Nui.Focus(false)
    if mdtTabletProp and DoesEntityExist(mdtTabletProp) then
        DeleteEntity(mdtTabletProp)
        mdtTabletProp = nil
    end
end)

-- ============================================================
-- NUI Callbacks
-- ============================================================

-- Fermeture du MDT
RegisterNUICallback("nui:sams:close", function(_, cb)
    SN_SAMS.CloseMDT()
    cb("ok")
end)

-- Pagination: charger plus d'items (logs/reports/announcements/invoices/procedures/documents)
RegisterNUICallback("nui:sams:loadMore", function(data, cb)
    local listType = data and data.listType
    local beforeId = data and data.beforeId
    local limit = data and data.limit
    if type(listType) ~= "string" then
        cb({})
        return
    end
    local items = TriggerServerCallback("sn_sams:loadMore", listType, beforeId, limit) or {}
    cb(items)
end)

-- Minimiser le MDT (garde l'animation/prop mais libere le NUI focus)
RegisterNUICallback("nui:sams:minimize", function(_, cb)
    if isMDTOpen and not isMDTMinimized then
        isMDTMinimized = true
        VFW.Nui.Focus(false)
        SendNUIMessage({
            action = "nui:sams:minimized",
            data = {}
        })
    end
    cb("ok")
end)

-- Focus sur un champ texte -> bloquer le mouvement pour eviter WASD pendant la saisie
RegisterNUICallback("nui:sams:inputFocus", function(_, cb)
    if isMDTOpen and not isMDTMinimized then
        SetNuiFocusKeepInput(false)
    end
    cb("ok")
end)

-- Perte de focus sur un champ texte -> reactiver le mouvement
RegisterNUICallback("nui:sams:inputBlur", function(_, cb)
    if isMDTOpen and not isMDTMinimized then
        SetNuiFocusKeepInput(true)
    end
    cb("ok")
end)

-- Toggle duty
RegisterNUICallback("nui:sams:toggleDuty", function(data, cb)
    TriggerServerEvent("vfw:changeDuty", data.onDuty)
    cb("ok")
end)

-- Prise en charge d'une alerte (ou acceptation d'un backup)
RegisterNUICallback("nui:sams:takeAlert", function(data, cb)
    if data.alertId then
        local alertId = tostring(data.alertId)
        if alertId:find("^backup_") then
            local backupId = tonumber(alertId:sub(8))
            if backupId then
                TriggerServerEvent("sn_sams:acceptBackup", backupId)
            end
        else
            TriggerServerEvent("sn_sams:takeAlert", data.alertId)
        end
    end
    cb("ok")
end)

-- Retrait de prise en charge d'une alerte
RegisterNUICallback("nui:sams:untakeAlert", function(data, cb)
    if data.alertId then
        TriggerServerEvent("sn_sams:untakeAlert", data.alertId)
    end
    cb("ok")
end)

-- Resolution d'une alerte
RegisterNUICallback("nui:sams:resolveAlert", function(data, cb)
    if data.alertId then
        local alertId = tostring(data.alertId)
        if alertId:find("^backup_") then
            local backupId = tonumber(alertId:sub(8))
            if backupId then
                TriggerServerEvent("sn_sams:resolveBackup", backupId)
            end
            return cb("ok")
        end
        TriggerServerEvent("sn_sams:resolveAlert", data.alertId)
    end
    cb("ok")
end)

-- Annulation de notre propre backup depuis le MDT
RegisterNUICallback("nui:sams:cancelBackup", function(data, cb)
    if data.backupId then
        local backupId = tonumber(data.backupId)
        if backupId then
            TriggerServerEvent("sn_sams:cancelBackup", backupId)
        end
    end
    cb("ok")
end)

-- Relocaliser le patient (met a jour le GPS)
RegisterNUICallback("nui:sams:relocateAlert", function(data, cb)
    if data.alertId then
        TriggerServerEvent("sn_sams:relocateAlert", data.alertId)
    end
    cb("ok")
end)

-- Recuperer un citoyen par identifier (pour lien profil depuis alerte)
RegisterNUICallback("nui:sams:getCitizenByIdentifier", function(data, cb)
    if data.identifier then
        local citizen = TriggerServerCallback("sn_sams:getCitizenByIdentifier", data.identifier)
        if citizen then
            SendNUIMessage({ action = "nui:sams:openCitizenProfile", data = citizen })
        end
    end
    cb("ok")
end)

-- Ajout de note medicale
RegisterNUICallback("nui:sams:addNote", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data.citizenId and data.note then
        TriggerServerEvent("sn_sams:addNote", data.citizenId, data.note)
    end
    cb("ok")
end)

-- Mise a jour du telephone d'un citoyen
RegisterNUICallback("nui:sams:updateCitizenPhone", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data.citizenId and data.phone ~= nil then
        TriggerServerEvent("sn_sams:updateCitizenPhone", data.citizenId, data.phone)
    end
    cb("ok")
end)

-- Suppression de note medicale
RegisterNUICallback("nui:sams:deleteNote", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data.citizenId and data.noteId then
        TriggerServerEvent("sn_sams:deleteNote", data.citizenId, data.noteId)
    end
    cb("ok")
end)

-- Soumission de rapport
RegisterNUICallback("nui:sams:submitReport", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:submitReport", data)
    end
    cb("ok")
end)

-- Soumission de document medical
RegisterNUICallback("nui:sams:submitDocument", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:submitDocument", data)
    end
    cb("ok")
end)

-- Suppression de document medical
RegisterNUICallback("nui:sams:deleteDocument", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.documentId then
        TriggerServerEvent("sn_sams:deleteDocument", data.documentId)
    end
    cb("ok")
end)

-- Impression papier d'un document medical
RegisterNUICallback("nui:sams:getDocumentPaper", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.documentId then
        TriggerServerEvent("sn_sams:giveDocumentPaper", data.documentId)
    end
    cb("ok")
end)

local paperDocumentOpen = false

-- Fermeture du visionneur de document papier
RegisterNUICallback("nui:sams:closePaperDocument", function(_, cb)
    paperDocumentOpen = false
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Ouverture du visionneur de document papier (depuis item use)
RegisterNetEvent("sn_sams:openPaperDocument", function(metaData)
    if not metaData then return end
    -- Fermer l'inventaire
    if VFW and VFW.CloseInventory then
        VFW.CloseInventory()
    else
        TriggerEvent("vfw:closeInventory")
        TriggerEvent("esx_inventoryhud:closeInventory")
    end
    Wait(150)
    SetNuiFocus(true, false)
    SendNUIMessage({
        action = "nui:sams:openPaperDocument",
        data = metaData
    })

    if paperDocumentOpen then return end
    paperDocumentOpen = true
    CreateThread(function()
        while paperDocumentOpen do
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 140, true) -- Melee light
            DisableControlAction(0, 141, true) -- Melee heavy
            DisableControlAction(0, 142, true) -- Melee alt
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 263, true) -- Melee attack 1
            DisableControlAction(0, 264, true) -- Melee attack 2
            DisableControlAction(0, 37, true)  -- Select weapon wheel
            DisableControlAction(0, 12, true)  -- Weapon wheel up/down
            DisableControlAction(0, 13, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            Wait(0)
        end
    end)
end)

-- Attribution PPA Leger depuis le MDT SAMS
RegisterNUICallback("nui:sams:grantPPALeger", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.citizenId then
        TriggerServerEvent("sn_sams:grantPPALeger", data.citizenId)
    end
    cb("ok")
end)

-- Verification du PPA Leger d'un citoyen (depuis le MDT)
RegisterNUICallback("nui:sams:checkPPALeger", function(data, cb)
    if not data or not data.citizenId then cb({ hasPPA = false }) return end
    local hasPPA = TriggerServerCallback("sn_sams:hasPPALeger", data.citizenId)
    cb({ citizenId = data.citizenId, hasPPA = hasPPA == true })
end)

-- Relais du status PPA Leger vers la NUI apres attribution
RegisterNetEvent("sn_sams:ppaLegerStatus", function(payload)
    SendNUIMessage({
        action = "nui:sams:ppaLegerStatus",
        data = payload or {}
    })
end)

-- Recherche de citoyens
RegisterNUICallback("nui:sams:searchCitizens", function(data, cb)
    if data.query and #data.query >= 2 then
        local citizens = TriggerServerCallback("sn_sams:searchCitizens", data.query)
        SendNUIMessage({
            action = "nui:sams:searchCitizensResult",
            data = citizens or {}
        })
    end
    cb("ok")
end)

-- Chargement initial de tous les citoyens
RegisterNUICallback("nui:sams:loadCitizens", function(data, cb)
    local payload = TriggerServerCallback("sn_sams:getAllCitizens", data or {})
    local citizens = payload and payload.items or {}
    SendNUIMessage({
        action = "nui:sams:searchCitizensResult",
        data = citizens or {}
    })
    SendNUIMessage({
        action = "nui:sams:citizensPaginationResult",
        data = {
            page = payload and payload.page or 1,
            totalPages = payload and payload.totalPages or 1,
        }
    })
    cb(payload or {
        items = citizens or {},
        page = 1,
        pageSize = 50,
        total = #(citizens or {}),
        totalPages = 1,
        hasPrev = false,
        hasNext = false
    })
end)

-- Chargement des notes d'un citoyen
RegisterNUICallback("nui:sams:getCitizenNotes", function(data, cb)
    if data.citizenId then
        local notes = TriggerServerCallback("sn_sams:getCitizenNotes", data.citizenId)
        SendNUIMessage({
            action = "nui:sams:citizenNotesResult",
            data = { citizenId = data.citizenId, notes = notes or {} }
        })
    end
    cb("ok")
end)

-- Rafraichissement de la liste du personnel
RegisterNUICallback("nui:sams:refreshPersonnel", function(_, cb)
    local personnel = TriggerServerCallback("sn_sams:getPersonnel")
    SendNUIMessage({
        action = "nui:sams:setMedecins",
        data = personnel or {}
    })
    cb("ok")
end)

-- Creation d'une annonce
RegisterNUICallback("nui:sams:createAnnouncement", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:createAnnouncement", data)
    end
    cb("ok")
end)

-- Modification d'une annonce
RegisterNUICallback("nui:sams:editAnnouncement", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:editAnnouncement", data)
    end
    cb("ok")
end)

-- Suppression d'une annonce
RegisterNUICallback("nui:sams:deleteAnnouncement", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.id then
        TriggerServerEvent("sn_sams:deleteAnnouncement", tonumber(data.id))
    end
    cb("ok")
end)

-- Joueurs proches (rayon 10m) pour facturation
RegisterNUICallback("nui:sams:getNearbyPlayers", function(_, cb)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearbyPlayers = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            if #(myCoords - targetCoords) <= 10.0 then
                local serverId = GetPlayerServerId(playerId)
                nearbyPlayers[#nearbyPlayers + 1] = { serverId = serverId }
            end
        end
    end

    local players = TriggerServerCallback("sn_sams:getNearbyPlayersInfo", nearbyPlayers)
    SendNUIMessage({
        action = "nui:sams:nearbyPlayersResult",
        data = players or {}
    })
    cb("ok")
end)

-- Recuperer les permissions par grade pour l'hopital du joueur
RegisterNUICallback("nui:sams:getGradePermissions", function(_, cb)
    local data = TriggerServerCallback("sn_sams:getGradePermissions")
    SendNUIMessage({
        action = "nui:sams:gradePermissionsResult",
        data = data
    })
    cb("ok")
end)

-- Mettre a jour les permissions d'un grade
RegisterNUICallback("nui:sams:updateGradePermissions", function(data, cb)
    if data and data.grade and data.permissions then
        TriggerServerEvent("sn_sams:updateGradePermissions", data.grade, data.permissions)
    end
    cb("ok")
end)

-- Suppression d'un rapport
RegisterNUICallback("nui:sams:deleteReport", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.reportId then
        TriggerServerEvent("sn_sams:deleteReport", tonumber(data.reportId))
    end
    cb("ok")
end)

-- Récupération des rapports supprimés
RegisterNUICallback("nui:sams:getDeletedReports", function(_, cb)
    local deletedReports = TriggerServerCallback("sn_sams:getDeletedReports")
    SendNUIMessage({
        action = "nui:sams:setDeletedReports",
        data = deletedReports or {}
    })
    cb("ok")
end)

-- Restauration d'un rapport
RegisterNUICallback("nui:sams:restoreReport", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.reportId then
        TriggerServerEvent("sn_sams:restoreReport", tonumber(data.reportId))
    end
    cb("ok")
end)

-- Modification d'un rapport
RegisterNUICallback("nui:sams:editReport", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data and data.reportId and data.field and data.value ~= nil then
        TriggerServerEvent("sn_sams:editReport", tonumber(data.reportId), data.field, data.value)
    end
    cb("ok")
end)

-- Creation d'une facture
RegisterNUICallback("nui:sams:createInvoice", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:createInvoice", data)
    end
    cb("ok")
end)

-- Annulation d'une facture
RegisterNUICallback("nui:sams:cancelInvoice", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:cancelInvoice", data)
    end
    cb("ok")
end)

-- Creation d'un soin
RegisterNUICallback("nui:sams:createTreatment", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:createTreatment", data)
    end
    cb("ok")
end)

-- Modification d'un soin
RegisterNUICallback("nui:sams:editTreatment", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:editTreatment", data)
    end
    cb("ok")
end)

-- Suppression d'un soin
RegisterNUICallback("nui:sams:deleteTreatment", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:deleteTreatment", data)
    end
    cb("ok")
end)

-- Creation d'une procedure
RegisterNUICallback("nui:sams:createProcedure", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:createProcedure", data)
    end
    cb("ok")
end)

-- Modification d'une procedure
RegisterNUICallback("nui:sams:editProcedure", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:editProcedure", data)
    end
    cb("ok")
end)

-- Suppression d'une procedure
RegisterNUICallback("nui:sams:deleteProcedure", function(data, cb)
    if not canPerformAction() then cb("cooldown") return end
    if data then
        TriggerServerEvent("sn_sams:deleteProcedure", data)
    end
    cb("ok")
end)

-- ============================================================
-- Events serveur -> client
-- ============================================================

-- Nouvelle alerte (calcul distance cote client, envoi au NUI si MDT ouvert)
RegisterNetEvent("sn_sams:newAlert", function(alert)
    if alert.coordinates then
        local playerCoords = GetEntityCoords(PlayerPedId())
        alert.distance = #(playerCoords - vector3(alert.coordinates.x, alert.coordinates.y, alert.coordinates.z)) / 1000.0
    end

    if isMDTOpen then
        SendNUIMessage({
            action = "nui:sams:addAlert",
            data = alert
        })
    end
end)

-- Mise a jour d'une alerte
RegisterNetEvent("sn_sams:updateAlert", function(alert)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:updateAlert",
        data = alert
    })
end)

-- Nouveau log
RegisterNetEvent("sn_sams:addLog", function(logEntry)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:addLog",
        data = logEntry
    })
end)

-- Mise a jour des stats
RegisterNetEvent("sn_sams:updateStats", function(stats)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:stats",
        data = stats
    })
end)

-- Liste medecins mise a jour
RegisterNetEvent("sn_sams:setMedecins", function(medecins)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:setMedecins",
        data = medecins
    })
end)

-- Note ajoutee
RegisterNetEvent("sn_sams:noteAdded", function(citizenId, note)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:noteAdded",
        data = { citizenId = citizenId, note = note }
    })
end)

-- Note supprimee
RegisterNetEvent("sn_sams:noteRemoved", function(citizenId, noteId)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:noteRemoved",
        data = { citizenId = citizenId, noteId = noteId }
    })
end)

-- Telephone citoyen mis a jour
RegisterNetEvent("sn_sams:citizenPhoneUpdated", function(citizenId, phone)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:citizenPhoneUpdated",
        data = { citizenId = citizenId, phone = phone }
    })
end)

-- Rapport ajoute
RegisterNetEvent("sn_sams:reportAdded", function(report)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:addReport",
        data = report
    })
end)

-- Document ajoute
RegisterNetEvent("sn_sams:documentAdded", function(doc)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:addDocument",
        data = doc
    })
end)

-- Document supprime
RegisterNetEvent("sn_sams:documentRemoved", function(docId)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:documentRemoved",
        data = docId
    })
end)

-- Rapport supprime
RegisterNetEvent("sn_sams:reportRemoved", function(reportId)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:reportRemoved",
        data = reportId
    })
end)

-- Rapport restaure
RegisterNetEvent("sn_sams:reportRestored", function(report)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:reportRestored",
        data = report
    })
end)

-- Rapport modifie
RegisterNetEvent("sn_sams:reportUpdated", function(updateData)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:reportUpdated",
        data = updateData
    })
end)

-- Annonce ajoutee
RegisterNetEvent("sn_sams:announcementAdded", function(announcement)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:addAnnouncement",
        data = announcement
    })
end)

-- Annonce modifiee
RegisterNetEvent("sn_sams:announcementUpdated", function(announcement)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:announcementUpdated",
        data = announcement
    })
end)

-- Annonce supprimee
RegisterNetEvent("sn_sams:announcementDeleted", function(data)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:announcementDeleted",
        data = data
    })
end)

-- Facture ajoutee
RegisterNetEvent("sn_sams:invoiceAdded", function(invoice)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:addInvoice",
        data = invoice
    })
end)

-- Facture mise a jour (paiement)
RegisterNetEvent("sn_sams:invoiceUpdated", function(data)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:updateInvoice",
        data = data
    })
end)

-- Soin ajoute
RegisterNetEvent("sn_sams:treatmentAdded", function(treatment)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:treatmentAdded",
        data = treatment
    })
end)

-- Soin modifie
RegisterNetEvent("sn_sams:treatmentUpdated", function(treatment)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:treatmentUpdated",
        data = treatment
    })
end)

-- Soin supprime
RegisterNetEvent("sn_sams:treatmentRemoved", function(treatmentId)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:treatmentRemoved",
        data = treatmentId
    })
end)

-- Procedure ajoutee
RegisterNetEvent("sn_sams:procedureAdded", function(procedure)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:procedureAdded",
        data = procedure
    })
end)

-- Procedure modifiee
RegisterNetEvent("sn_sams:procedureUpdated", function(procedure)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:procedureUpdated",
        data = procedure
    })
end)

-- Procedure supprimee
RegisterNetEvent("sn_sams:procedureRemoved", function(procedureId)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:procedureRemoved",
        data = procedureId
    })
end)

-- Permissions mises a jour en temps reel
RegisterNetEvent("sn_sams:permissionsUpdated", function(permissions)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:permissionsUpdated",
        data = permissions or {}
    })
end)

-- Permissions d'un grade mises a jour (vue manager)
RegisterNetEvent("sn_sams:gradePermissionsUpdated", function(payload)
    if not isMDTOpen then return end
    SendNUIMessage({
        action = "nui:sams:gradePermissionsUpdated",
        data = payload or {}
    })
end)

-- GPS vers une alerte
RegisterNetEvent("sn_sams:setGPS", function(coords)
    if coords then
        SetNewWaypoint(coords.x, coords.y)
    end
end)

-- ============================================================
-- Notification in-game pour alertes SAMS (visible sans MDT)
-- ============================================================
RegisterNetEvent("sn_sams:alertNotification", function(alert)
    if not alert then return end

    -- Filtrage zone mutee
    if alert.coordinates and SN_SAMS.IsInMutedZone and SN_SAMS.IsInMutedZone(alert.coordinates) then
        return
    end

    -- Resoudre le nom de rue
    local streetName = "Position inconnue"
    if alert.coordinates then
        local streetHash = GetStreetNameAtCoord(alert.coordinates.x, alert.coordinates.y, alert.coordinates.z)
        local resolved = GetStreetNameFromHashKey(streetHash)
        if resolved and resolved ~= "" then
            streetName = resolved
        end
    end

    -- Calculer la distance de trajet
    local distanceText = ""
    if alert.coordinates then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local dist = CalculateTravelDistanceBetweenPoints(
            playerCoords.x, playerCoords.y, playerCoords.z,
            alert.coordinates.x, alert.coordinates.y, alert.coordinates.z
        )
        if dist > 0 then
            distanceText = string.format("%.1f km", dist / 1000)
        end
    end

    -- Subtitle selon le type d'alerte
    local subtitle = "Appel"
    local descriptionText = "Un appel a été reçu."
    if alert.type == "mort" then
        subtitle = "Coma"
        descriptionText = "Une personne se trouve dans le coma."
    elseif alert.type == "urgence" then
        subtitle = "Urgence"
        descriptionText = "Une urgence médicale a été signalée."
    end

    -- Contenu: description + position (rue + distance)
    local locationText = streetName
    if distanceText ~= "" then
        locationText = locationText .. " (" .. distanceText .. ")"
    end
    local contentText = descriptionText .. "\nPosition : " .. locationText

    -- Notification in-game (type JOB) avec action accept/refuse
    VFW.ShowNotification({
        type = 'JOB',
        logo = SN_SAMS.Logo,
        title = "SAMS",
        subtitle = subtitle,
        content = contentText,
        duration = 15,
        action = function(accepted)
            if accepted then
                TriggerServerEvent("sn_sams:takeAlert", alert.id)
                if alert.coordinates then
                    SetNewWaypoint(alert.coordinates.x, alert.coordinates.y)
                end
            end
        end,
    })

    -- Son radio
    PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)

    -- Double son pour mort/urgence
    if alert.type == "mort" or alert.type == "urgence" then
        CreateThread(function()
            Wait(500)
            PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
        end)
    end
end)

-- ============================================================
-- Notification in-game lors d'un changement d'etat d'alerte
-- (visible meme MDT ferme: evite de se deplacer pour rien)
-- ============================================================
RegisterNetEvent("sn_sams:alertStateChanged", function(payload)
    if not payload or not payload.changeType then return end

    -- Filtrage zone mutee
    if payload.coordinates and SN_SAMS.IsInMutedZone and SN_SAMS.IsInMutedZone(payload.coordinates) then
        return
    end

    local subtitle, contentText
    local agentName = payload.agentName or "Un médecin"
    local desc = payload.description or "Appel"

    if payload.changeType == "taken" then
        subtitle = "Appel pris en charge"
        contentText = agentName .. " prend en charge l'appel.\n" .. desc
    elseif payload.changeType == "untaken" then
        subtitle = "Appel libéré"
        contentText = agentName .. " s'est retiré de l'appel.\n" .. desc
    elseif payload.changeType == "resolved" then
        subtitle = "Appel résolu"
        contentText = "Appel cloturé par " .. agentName .. ".\n" .. desc
    else
        return
    end

    VFW.ShowNotification({
        type = 'JOB',
        logo = SN_SAMS.Logo,
        title = "SAMS",
        subtitle = subtitle,
        content = contentText,
        duration = 8,
    })

    PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
end)

-- ============================================================
-- Notification in-game pour annonces SAMS
-- ============================================================
RegisterNetEvent("sn_sams:announcementNotification", function(data)
    if not data or not data.title then return end

    local subtitle = "Annonce"
    if data.priority == "urgent" then
        subtitle = "Annonce urgente"
    elseif data.priority == "important" then
        subtitle = "Annonce importante"
    end

    VFW.ShowNotification({
        type = 'JOB',
        logo = SN_SAMS.Logo,
        title = "SAMS",
        subtitle = subtitle,
        content = data.title .. "\nDe : " .. (data.author or "Inconnu"),
    })

    PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
end)

-- ============================================================
-- Backup blip system (flashing on map)
-- ============================================================
local backupBlips = {} -- { [backupId] = blipHandle }

local BACKUP_BLIP_COLORS = {
    [1] = 2,   -- Vert
    [2] = 5,   -- Jaune
    [3] = 1,   -- Rouge
}

local function CreateBackupBlip(backupId, coords, level, levelLabel, targetHospitalLabel)
    if backupBlips[backupId] then
        RemoveBlip(backupBlips[backupId])
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 153) -- Ambulance icon
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, BACKUP_BLIP_COLORS[level] or 1)
    SetBlipFlashes(blip, true)
    SetBlipFlashInterval(blip, 500)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    local label = "Backup " .. (levelLabel or ("Niveau " .. tostring(level))) .. " · " .. (targetHospitalLabel or "Global")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)

    backupBlips[backupId] = blip
end

local function RemoveBackupBlip(backupId)
    if backupBlips[backupId] then
        RemoveBlip(backupBlips[backupId])
        backupBlips[backupId] = nil
    end
end

-- ============================================================
-- Notification in-game pour demande de backup
-- ============================================================
RegisterNetEvent("sn_sams:backupRequest", function(data)
    if not data then return end

    local subtitle = "Backup " .. (data.levelLabel or "")
    local locationText = data.street or "Position inconnue"
    if data.distance then
        locationText = locationText .. " (" .. data.distance .. "m)"
    end

    local content = (data.requesterName or "Agent") .. " demande une backup"
    if data.targetHospitalLabel then
        content = content .. " (" .. data.targetHospitalLabel .. ")"
    end
    content = content .. "\n" .. locationText

    VFW.ShowNotification({
        type = 'JOB',
        logo = SN_SAMS.Logo,
        title = "SAMS",
        subtitle = subtitle,
        content = content,
        duration = 15,
        action = function(accepted)
            if accepted then
                TriggerServerEvent("sn_sams:acceptBackup", data.id)
                if data.coords then
                    SetNewWaypoint(data.coords.x, data.coords.y)
                end
            end
        end,
    })

    -- Créer le blip clignotant sur la map
    if data.coords and data.id then
        CreateBackupBlip(data.id, data.coords, data.level or 1, data.levelLabel, data.targetHospitalLabel)
    end

    PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
    CreateThread(function()
        Wait(500)
        PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
    end)
end)

-- ============================================================
-- Notification in-game pour annulation de backup
-- ============================================================
RegisterNetEvent("sn_sams:backupCancelled", function(backupId)
    RemoveBackupBlip(backupId)

    VFW.ShowNotification({
        type = 'JOB',
        logo = SN_SAMS.Logo,
        title = "SAMS",
        subtitle = "Backup annulé",
        content = "La demande de backup #" .. tostring(backupId) .. " a été annulée.",
    })

    PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
end)

-- ============================================================
-- Suppression du blip quand backup terminé (accepté/expiré/refusé)
-- ============================================================
RegisterNetEvent("sn_sams:backupEnded", function(backupId)
    RemoveBackupBlip(backupId)
end)

-- ============================================================
-- Utilisation medikit civil (item "medikit") - réanimation
-- ============================================================
RegisterNetEvent("sn_sams:useMedikit", function()
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas faire ça." })
        return
    end

    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closestPed, closestDist = nil, 3.0

    -- Chercher un joueur mort a proximite
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) then
                local isDead = IsPedDeadOrDying(targetPed, true) or (VFW.GetDeathCloneOwner and VFW.GetDeathCloneOwner(targetPed))
                if isDead then
                    local dist = #(myCoords - GetEntityCoords(targetPed))
                    if dist < closestDist then
                        closestPed = targetPed
                        closestDist = dist
                    end
                end
            end
        end
    end

    if not closestPed then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucune personne inconsciente à proximité." })
        return
    end

    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(closestPed))
    if not targetServerId or targetServerId == 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable." })
        return
    end

    TriggerServerEvent("sn_sams:civilRevive", targetServerId)
end)

-- ============================================================
-- Utilisation bandage civil (item "band")
-- ============================================================
local lastBandageUse = 0

RegisterNetEvent("sn_sams:useBandage", function()
    -- Cooldown: 5 min apres un tir, 5 min apres derniere utilisation
    if (VFW.LastFireTime ~= 0 and (GetGameTimer() - VFW.LastFireTime) < 600000)
        or (lastBandageUse ~= 0 and (GetGameTimer() - lastBandageUse) < 300000) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas utiliser ce soin pour le moment." })
        return
    end

    local animDict = "amb@medic@standing@kneel@base"
    local animName = "base"

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

    TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 1, 0, false, false, false)

    Wait(13000)

    ClearPedTasks(PlayerPedId())
    RemoveAnimDict(animDict)

    lastBandageUse = GetGameTimer()

    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped)
    local realHealth = maxHealth - 100
    local healAmount = math.floor(realHealth * 0.25)
    local maxAllowed = 100 + math.floor(realHealth * 0.75)
    local newHealth = math.min(GetEntityHealth(ped) + healAmount, maxAllowed)
    SetEntityHealth(ped, newHealth)

    TriggerServerEvent("core:removeItems", "band", 1)
end)

-- ============================================================
-- Job change: mettre a jour l'hopital de l'agent dans le MDT
-- ============================================================
RegisterNetEvent("vfw:setJob", function(newJob, lastJob)
    -- Mettre à jour l'hôpital dans le MDT si ouvert
    if isMDTOpen then
        local hospital = "pillbox"
        if newJob.name == "sams_pab" then hospital = "paleto" end
        SendNUIMessage({
            action = "nui:sams:updateAgentHospital",
            data = { hospital = hospital, grade = newJob.grade_label or newJob.label or "Agent" }
        })
    end

    -- Charger les blips de backup actives à la prise de service
    if newJob.onDuty and SN_SAMS.HasJob() then
        CreateThread(function()
            local activeBackups = TriggerServerCallback("sn_sams:getActiveBackups")
            if not activeBackups then return end
            for _, backup in ipairs(activeBackups) do
                if backup.coords and backup.id then
                    CreateBackupBlip(backup.id, backup.coords, backup.level or 1, backup.levelLabel, backup.targetHospitalLabel)
                end
            end
        end)
    elseif not newJob.onDuty then
        -- Fin de service : supprimer tous les blips backup
        for backupId in pairs(backupBlips) do
            RemoveBackupBlip(backupId)
        end
    end
end)

-- ============================================================
-- Initialisation
-- ============================================================
CreateThread(function()
    while not VFW.PlayerData.loaded do
        Wait(100)
    end

    console.init("SAMS", "Client initialized")
end)
