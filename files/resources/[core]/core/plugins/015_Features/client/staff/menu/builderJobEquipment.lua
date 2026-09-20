local currentBuild = {
    name = "",
    jobs = {},
    position = nil,
    npcPosition = nil,
    npcModel = "s_m_y_armymech_01",
    blipEnabled = true,
    isValid = false
}

local currentItemBuild = {
    item_name = "",
    allowed_grades = {},
    max_stock = 1
}

local markerThread = nil
local isMarkersActive = false
local markerGeneration = 0
local cachedAllJobs = nil

local EQUIP_ITEMS_PER_PAGE = 20
local equipItemQuery = nil
local equipItemCurrentPage = 1

local function validateBuild()
    currentBuild.isValid = currentBuild.name ~= "" and #currentBuild.jobs > 0 and (currentBuild.npcPosition ~= nil or currentBuild.position ~= nil)
    return currentBuild.isValid
end

local function validateItemBuild()
    return currentItemBuild.item_name ~= "" and
            currentItemBuild.max_stock > 0
end

local function getCurrentPlayerPosition()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return nil end
    local coords = GetEntityCoords(playerPed)
    if not coords then return nil end
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = GetEntityHeading(playerPed)
    }
end

local function stopMarkerThread()
    isMarkersActive = false
    markerGeneration = markerGeneration + 1
    markerThread = nil
end

local function startMarkerThread()
    if isMarkersActive then return end
    isMarkersActive = true
    markerGeneration = markerGeneration + 1
    local generation = markerGeneration
    markerThread = CreateThread(function()
        while isMarkersActive and generation == markerGeneration do
            if currentBuild.position then
                local pos = currentBuild.position
                DrawMarker(1, pos.x, pos.y, pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0, 0, 200, 100, 150, false, true, 2, false, nil, nil, false)
                local onScreen, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(0, 200, 100, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("BLIP")
                    DrawText(sx, sy)
                end
            end
            if currentBuild.npcPosition then
                local pos = currentBuild.npcPosition
                DrawMarker(27, pos.x, pos.y, pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0, 0, 200, 100, 150, false, true, 2, false, nil, nil, false)
                local onScreen, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(0, 200, 100, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("NPC\n" .. currentBuild.name)
                    DrawText(sx, sy)
                end
            end
            Wait(0)
        end
    end)
end

local function resetBuild()
    stopMarkerThread()
    currentBuild = {
        name = "",
        jobs = {},
        position = nil,
        npcPosition = nil,
        npcModel = "s_m_y_armymech_01",
        blipEnabled = true,
        isValid = false
    }
end

local function resetItemBuild()
    currentItemBuild = {
        item_name = "",
        allowed_grades = {},
        max_stock = 1
    }
end

local function isJobInList(jobs, jobName)
    for _, j in ipairs(jobs) do
        if j == jobName then return true end
    end
    return false
end

local function toggleJobInList(jobs, jobName)
    for i, j in ipairs(jobs) do
        if j == jobName then
            table.remove(jobs, i)
            return jobs
        end
    end
    jobs[#jobs + 1] = jobName
    return jobs
end

local function isGradeInList(allowedGrades, jobName, grade)
    local jobGrades = allowedGrades[jobName]
    if not jobGrades or type(jobGrades) ~= "table" then return false end
    return jobGrades[tostring(grade)] ~= nil
end

local function getGradeMax(allowedGrades, jobName, grade)
    local jobGrades = allowedGrades[jobName]
    if not jobGrades or type(jobGrades) ~= "table" then return nil end
    return jobGrades[tostring(grade)]
end

local function toggleGradeInList(allowedGrades, jobName, grade)
    if not allowedGrades[jobName] then
        allowedGrades[jobName] = {}
    end
    local key = tostring(grade)
    if allowedGrades[jobName][key] then
        allowedGrades[jobName][key] = nil
        if not next(allowedGrades[jobName]) then
            allowedGrades[jobName] = nil
        end
    else
        allowedGrades[jobName][key] = 1
    end
    return allowedGrades
end

local function setGradeMax(allowedGrades, jobName, grade, max)
    if not allowedGrades[jobName] then
        allowedGrades[jobName] = {}
    end
    allowedGrades[jobName][tostring(grade)] = math.max(1, tonumber(max) or 1)
    return allowedGrades
end

local function countTotalGrades(allowedGrades)
    local total = 0
    if type(allowedGrades) ~= "table" then return 0 end
    for _, grades in pairs(allowedGrades) do
        if type(grades) == "table" then
            for _ in pairs(grades) do
                total = total + 1
            end
        end
    end
    return total
end

function StaffMenu.BuildJobEquipmentMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipment then return end

    StaffMenu.builderJobEquipment.Button("CRÉER UN ÉQUIPEMENT", "Créer un nouveau point d'équipement job",
        nil, "chevron", false, function()
            resetBuild()
        end, StaffMenu.builderJobEquipmentCreate)

    StaffMenu.builderJobEquipment.Button("GÉRER LES ÉQUIPEMENTS", "Voir et gérer les équipements existants",
        nil, "chevron", false, function()
            local equipments = TriggerServerCallback("core:jobEquipment:getEquipments")
            StaffMenu.currentJobEquipments = equipments or {}
        end, StaffMenu.builderJobEquipmentManage)
end

function StaffMenu.BuildJobEquipmentCreateMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentCreate then return end

    StaffMenu.builderJobEquipmentCreate.Button("NOM: " .. (currentBuild.name ~= "" and currentBuild.name or "NON DÉFINI"),
        "Définir le nom de l'équipement", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Nom de l'équipement", currentBuild.name)
            if result and result ~= "" then
                currentBuild.name = result
                validateBuild()
                if StaffMenu.builderJobEquipmentCreate.refresh then
                    StaffMenu.builderJobEquipmentCreate.refresh()
                end
            end
        end)

    local jobCount = #currentBuild.jobs
    StaffMenu.builderJobEquipmentCreate.Button(
        "JOBS: " .. (jobCount > 0 and (jobCount .. " sélectionné" .. (jobCount > 1 and "s" or "")) or "NON DÉFINI"),
        "Sélectionner les jobs liés à cet équipement",
        nil, "chevron", false,
        function()
            if not cachedAllJobs then
                cachedAllJobs = TriggerServerCallback("core:jobEquipment:getAllJobs") or {}
            end
        end,
        StaffMenu.builderJobEquipmentJobs
    )

    local blipText = currentBuild.position and
        string.format("X: %.2f Y: %.2f Z: %.2f", currentBuild.position.x, currentBuild.position.y, currentBuild.position.z) or "NON DÉFINI"

  StaffMenu.builderJobEquipmentCreate.Button("POSITION BLIP: " .. blipText,
        "Définir la position du blip", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                currentBuild.position = pos
                validateBuild()
                startMarkerThread()
                if StaffMenu.builderJobEquipmentCreate.refresh then
                    StaffMenu.builderJobEquipmentCreate.refresh()
                end
            end
        end)

    local npcText = currentBuild.npcPosition and
        string.format("X: %.2f Y: %.2f Z: %.2f", currentBuild.npcPosition.x, currentBuild.npcPosition.y, currentBuild.npcPosition.z) or "NON DÉFINI"

  StaffMenu.builderJobEquipmentCreate.Button("POSITION NPC: " .. npcText,
        "Optionnel - sans NPC un marqueur sera affiché", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                currentBuild.npcPosition = pos
                validateBuild()
                startMarkerThread()
                if StaffMenu.builderJobEquipmentCreate.refresh then
                    StaffMenu.builderJobEquipmentCreate.refresh()
                end
            end
        end)

    StaffMenu.builderJobEquipmentCreate.Button("MODÈLE NPC: " .. (currentBuild.npcModel or "s_m_y_armymech_01"),
        "Modèle du PED vendeur", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Modèle du PED (ex: s_m_y_armymech_01)", currentBuild.npcModel or "")
            if result and result ~= "" then
                currentBuild.npcModel = result
                if StaffMenu.builderJobEquipmentCreate.refresh then
                    StaffMenu.builderJobEquipmentCreate.refresh()
                end
            end
        end)

    StaffMenu.builderJobEquipmentCreate.Button("BLIP: " .. (currentBuild.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
        "Activer ou désactiver le blip", nil, "arrow", false,
        function()
            currentBuild.blipEnabled = not currentBuild.blipEnabled
            if StaffMenu.builderJobEquipmentCreate.refresh then
                StaffMenu.builderJobEquipmentCreate.refresh()
            end
        end)

    StaffMenu.builderJobEquipmentCreate.Separator(nil)

    local statusMsg = ""
  if currentBuild.name == "" then
        statusMsg = "Nom requis"
  elseif #currentBuild.jobs == 0 then
        statusMsg = "Au moins un job requis"
  elseif not currentBuild.npcPosition and not currentBuild.position then
        statusMsg = "Position blip ou NPC requise"
  else
        statusMsg = "Configuration terminée"
  end

    StaffMenu.builderJobEquipmentCreate.Button("CRÉER L'ÉQUIPEMENT", statusMsg,
        nil, "chevron", not currentBuild.isValid,
        function()
            if not validateBuild() then
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
                return
            end
            TriggerServerEvent("core:jobEquipment:create", {
                name = currentBuild.name,
                jobs = currentBuild.jobs,
                pos = currentBuild.position or currentBuild.npcPosition,
                npcPos = currentBuild.npcPosition,
                npcModel = currentBuild.npcModel,
                blipEnabled = currentBuild.blipEnabled
            })
            resetBuild()
            StaffMenu.builderJobEquipmentCreate.close()
            StaffMenu.builderJobEquipmentCreate.parent.open()
        end)
end

function StaffMenu.BuildJobEquipmentJobsMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentJobs then return end

    StaffMenu.builderJobEquipmentJobs.Separator("SÉLECTION DES JOBS")

    if not cachedAllJobs or #cachedAllJobs == 0 then
        StaffMenu.builderJobEquipmentJobs.Button("Aucun job trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, job in ipairs(cachedAllJobs) do
        local selected = isJobInList(currentBuild.jobs, job.name)
        StaffMenu.builderJobEquipmentJobs.Button(
            job.label,
            job.name,
            nil,
            selected and "check" or "empty",
            false,
            function()
                toggleJobInList(currentBuild.jobs, job.name)
                validateBuild()
                if StaffMenu.builderJobEquipmentJobs.refresh then
                    StaffMenu.builderJobEquipmentJobs.refresh()
                end
            end
        )
    end
end

function StaffMenu.BuildJobEquipmentManageMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentManage then return end

    local equipments = StaffMenu.currentJobEquipments or {}
    local has = #equipments > 0

    StaffMenu.builderJobEquipmentManage.Separator(has and "ÉQUIPEMENTS EXISTANTS" or "AUCUN ÉQUIPEMENT")

    if has then
        for _, data in ipairs(equipments) do
            if data and data.name then
                local posText = data.pos and string.format("X: %.0f Y: %.0f Z: %.0f", data.pos.x, data.pos.y, data.pos.z) or "Position inconnue"
              StaffMenu.builderJobEquipmentManage.Button(data.name .. " #" .. data.id,
                    posText, nil, "chevron", false,
                    function()
                        StaffMenu.currentJobEquipmentId = data.id
                        StaffMenu.currentJobEquipmentData = data
                    end, StaffMenu.builderJobEquipmentEdit)
            end
        end
    end
end

function StaffMenu.BuildJobEquipmentEditMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentEdit then return end

    local id = StaffMenu.currentJobEquipmentId
    local data = StaffMenu.currentJobEquipmentData
    if not id or not data then return end

    StaffMenu.builderJobEquipmentEdit.Separator("ÉQUIPEMENT #" .. id)

    StaffMenu.builderJobEquipmentEdit.Button("NOM: " .. data.name,
        "Nom de l'équipement", nil, "check", true, function() end)

    local jobs = data.jobs or {}
    local jobCount = #jobs
    StaffMenu.builderJobEquipmentEdit.Button(
        "JOBS: " .. (jobCount > 0 and (jobCount .. " sélectionné" .. (jobCount > 1 and "s" or "")) or "NON DÉFINI"),
        "Modifier les jobs liés à cet équipement",
        nil, "chevron", false,
        function()
            if not cachedAllJobs then
                cachedAllJobs = TriggerServerCallback("core:jobEquipment:getAllJobs") or {}
            end
        end,
        StaffMenu.builderJobEquipmentEditJobs
    )

    local blipText = data.pos and string.format("X: %.2f Y: %.2f Z: %.2f", data.pos.x, data.pos.y, data.pos.z) or "NON DÉFINI"
  StaffMenu.builderJobEquipmentEdit.Button("POSITION BLIP: " .. blipText,
        "Modifier la position du blip", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                TriggerServerEvent("core:jobEquipment:update", id, "pos", pos)
                data.pos = pos
                if StaffMenu.builderJobEquipmentEdit.refresh then
                    StaffMenu.builderJobEquipmentEdit.refresh()
                end
            end
        end)

    local npcText = data.npcPos and string.format("X: %.2f Y: %.2f Z: %.2f", data.npcPos.x, data.npcPos.y, data.npcPos.z) or "NON DÉFINI"
  StaffMenu.builderJobEquipmentEdit.Button("POSITION NPC: " .. npcText,
        "Modifier la position du vendeur", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                TriggerServerEvent("core:jobEquipment:update", id, "npcPos", pos)
                data.npcPos = pos
                if StaffMenu.builderJobEquipmentEdit.refresh then
                    StaffMenu.builderJobEquipmentEdit.refresh()
                end
            end
        end)

    StaffMenu.builderJobEquipmentEdit.Button("MODÈLE NPC: " .. (data.npcModel or "s_m_y_armymech_01"),
        "Modifier le modèle du PED vendeur", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Modèle du PED", data.npcModel or "s_m_y_armymech_01")
            if result and result ~= "" then
                TriggerServerEvent("core:jobEquipment:update", id, "npcModel", result)
                data.npcModel = result
                if StaffMenu.builderJobEquipmentEdit.refresh then
                    StaffMenu.builderJobEquipmentEdit.refresh()
                end
            end
        end)

    StaffMenu.builderJobEquipmentEdit.Button("ACTIVÉ: " .. (data.active and "OUI" or "NON"),
        "Activer ou désactiver l'équipement", nil, "arrow", false,
        function()
            local newVal = not data.active
            TriggerServerEvent("core:jobEquipment:update", id, "active", newVal)
            data.active = newVal
            if StaffMenu.builderJobEquipmentEdit.refresh then
                StaffMenu.builderJobEquipmentEdit.refresh()
            end
        end)

    StaffMenu.builderJobEquipmentEdit.Button("BLIP: " .. (data.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
        "Activer ou désactiver le blip", nil, "arrow", false,
        function()
            local newVal = not data.blipEnabled
            TriggerServerEvent("core:jobEquipment:update", id, "blipEnabled", newVal)
            data.blipEnabled = newVal
            if StaffMenu.builderJobEquipmentEdit.refresh then
                StaffMenu.builderJobEquipmentEdit.refresh()
            end
        end)

    if not data.logsAllowedGrades then data.logsAllowedGrades = {} end
    local logsGradesCount = countTotalGrades(data.logsAllowedGrades)
    local logsDesc = logsGradesCount > 0
        and (logsGradesCount .. " grade" .. (logsGradesCount > 1 and "s" or "") .. " autorisé" .. (logsGradesCount > 1 and "s" or ""))
        or "Tous les grades (aucune restriction)"
  StaffMenu.builderJobEquipmentEdit.Button("ACCÈS HISTORIQUE: " .. (logsGradesCount > 0 and logsGradesCount or "TOUS"),
        logsDesc, nil, "chevron", false,
        function() end,
        StaffMenu.builderJobEquipmentLogsJobSelect)

    StaffMenu.builderJobEquipmentEdit.Separator("GESTION")

    StaffMenu.builderJobEquipmentEdit.Button("GÉRER LES ITEMS", "Ajouter, modifier ou supprimer des items",
        nil, "chevron", false, function()
            StaffMenu.currentJobEquipmentItemsId = id
            local items = TriggerServerCallback("core:jobEquipment:getItems", id)
            StaffMenu.currentJobEquipmentItemsList = items or {}
        end, StaffMenu.builderJobEquipmentItems)

    StaffMenu.builderJobEquipmentEdit.Button("CLEAR HISTORIQUE",
        "Supprimer tous les logs de cet équipement", nil, "trash", false,
        function()
            TriggerServerEvent("core:jobEquipment:clearLogs", id)
        end)

    StaffMenu.builderJobEquipmentEdit.Button("TÉLÉPORTER AU NPC",
        "Se téléporter à la position du vendeur", nil, "arrow", false,
        function()
            local npcPos = data.npcPos or data.pos
            if npcPos then
                SetEntityCoords(PlayerPedId(), npcPos.x, npcPos.y, npcPos.z, false, false, false, true)
            end
        end)

    StaffMenu.builderJobEquipmentEdit.Button("SUPPRIMER L'ÉQUIPEMENT",
        "Supprimer définitivement cet équipement", nil, "trash", false,
        function()
            TriggerServerEvent("core:jobEquipment:delete", id)
            local equipments = TriggerServerCallback("core:jobEquipment:getEquipments")
            StaffMenu.currentJobEquipments = equipments or {}
            exports["VUI"]:HandleBack()
        end)
end

function StaffMenu.BuildJobEquipmentEditJobsMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentEditJobs then return end

    local data = StaffMenu.currentJobEquipmentData
    local id = StaffMenu.currentJobEquipmentId
    if not data or not id then return end

    if not data.jobs then data.jobs = {} end

    StaffMenu.builderJobEquipmentEditJobs.Separator("SÉLECTION DES JOBS")

    if not cachedAllJobs or #cachedAllJobs == 0 then
        StaffMenu.builderJobEquipmentEditJobs.Button("Aucun job trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, job in ipairs(cachedAllJobs) do
        local selected = isJobInList(data.jobs, job.name)
        StaffMenu.builderJobEquipmentEditJobs.Button(
            job.label,
            job.name,
            nil,
            selected and "check" or "empty",
            false,
            function()
                toggleJobInList(data.jobs, job.name)
                TriggerServerEvent("core:jobEquipment:update", id, "jobs", data.jobs)
                if StaffMenu.builderJobEquipmentEditJobs.refresh then
                    StaffMenu.builderJobEquipmentEditJobs.refresh()
                end
            end
        )
    end
end

function StaffMenu.BuildJobEquipmentItemsMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItems then return end

    local equipmentId = StaffMenu.currentJobEquipmentItemsId

    StaffMenu.builderJobEquipmentItems.Button("AJOUTER UN ITEM", "Ajouter un item à cet équipement",
        nil, "chevron", false, function()
            resetItemBuild()
            currentItemBuild.equipment_id = equipmentId
        end, StaffMenu.builderJobEquipmentItemAdd)

    local items = StaffMenu.currentJobEquipmentItemsList or {}
    local has = #items > 0

    StaffMenu.builderJobEquipmentItems.Separator(has and "ITEMS CONFIGURÉS" or "AUCUN ITEM")

    if has then
        for _, item in ipairs(items) do
            local gradesCount = countTotalGrades(item.allowed_grades or {})
            local desc = string.format("Grades: %d | Stock: %d/%d | Sortis: %d",
                gradesCount, item.max_stock - item.current_out, item.max_stock, item.current_out)
            StaffMenu.builderJobEquipmentItems.Button(item.label,
                desc, nil, "chevron", false,
                function()
                    StaffMenu.currentJobEquipmentItemId = item.id
                    StaffMenu.currentJobEquipmentItemData = item
                end, StaffMenu.builderJobEquipmentItemEdit)
        end
    end
end

function StaffMenu.BuildJobEquipmentItemAddMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItemAdd then return end

    local equipmentId = StaffMenu.currentJobEquipmentItemsId
    local itemLabel = currentItemBuild.item_name ~= "" and
        (VFW.Items[currentItemBuild.item_name] and VFW.Items[currentItemBuild.item_name].label or currentItemBuild.item_name) or "NON DÉFINI"

  StaffMenu.builderJobEquipmentItemAdd.Button("ITEM: " .. itemLabel,
        currentItemBuild.item_name ~= "" and currentItemBuild.item_name or "Sélectionner un item", nil, "chevron", false,
        function()
            equipItemQuery = nil
            equipItemCurrentPage = 1
        end, StaffMenu.builderJobEquipmentItemSelect)

    local gradesCount = countTotalGrades(currentItemBuild.allowed_grades)
    StaffMenu.builderJobEquipmentItemAdd.Button("GRADES AUTORISÉS: " .. gradesCount,
        "Sélectionner un job puis ses grades", nil, "chevron", false,
        function()
            StaffMenu.currentJobEquipmentGradesMode = "add"
      end, StaffMenu.builderJobEquipmentItemJobSelect)

    StaffMenu.builderJobEquipmentItemAdd.Button("STOCK MAX: " .. currentItemBuild.max_stock,
        "Nombre maximum d'items sortis simultanément", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Stock max", tostring(currentItemBuild.max_stock))
            if result and result ~= "" then
                currentItemBuild.max_stock = math.max(1, tonumber(result) or 1)
                if StaffMenu.builderJobEquipmentItemAdd.refresh then
                    StaffMenu.builderJobEquipmentItemAdd.refresh()
                end
            end
        end)

    StaffMenu.builderJobEquipmentItemAdd.Separator(nil)

    local statusMsg = ""
  if currentItemBuild.item_name == "" then
        statusMsg = "Item requis"
  else
        statusMsg = "Prêt à ajouter"
  end

    StaffMenu.builderJobEquipmentItemAdd.Button("AJOUTER L'ITEM", statusMsg,
        nil, "chevron", not validateItemBuild(),
        function()
            if not validateItemBuild() then
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
                return
            end
            TriggerServerEvent("core:jobEquipment:addItem", {
                equipment_id = equipmentId,
                item_name = currentItemBuild.item_name,
                allowed_grades = currentItemBuild.allowed_grades,
                max_stock = currentItemBuild.max_stock
            })
            resetItemBuild()
            Wait(500)
            local items = TriggerServerCallback("core:jobEquipment:getItems", equipmentId)
            StaffMenu.currentJobEquipmentItemsList = items or {}
            exports["VUI"]:HandleBack()
        end)
end

function StaffMenu.BuildJobEquipmentItemSelectMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItemSelect then return end

    local menu = StaffMenu.builderJobEquipmentItemSelect

    local firstLabel = equipItemQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = equipItemQuery == nil and "" or equipItemQuery
    menu.Button(firstLabel, lastLabel, nil, "search", false, function()
        if equipItemQuery ~= nil then
            equipItemQuery = nil
            equipItemCurrentPage = 1
            menu.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Nom ou label de l'item", "")
        if query == nil or query == "" then
            return
        end
        equipItemQuery = query
        equipItemCurrentPage = 1
        menu.refresh()
    end)

    menu.Separator()

    local filtered = {}
    for itemName, item in pairs(VFW.Items) do
        if not equipItemQuery or
           string.find(string.lower(itemName), string.lower(equipItemQuery), 1, true) or
           string.find(string.lower(item.label or ""), string.lower(equipItemQuery), 1, true) then
            table.insert(filtered, { name = itemName, data = item })
        end
    end

    table.sort(filtered, function(a, b)
        return (a.data.label or a.name) < (b.data.label or b.name)
    end)

    local total = #filtered
    local totalPages = math.max(1, math.ceil(total / EQUIP_ITEMS_PER_PAGE))
    if equipItemCurrentPage > totalPages then
        equipItemCurrentPage = totalPages
    end
    if equipItemCurrentPage < 1 then
        equipItemCurrentPage = 1
    end

    local startIndex = (equipItemCurrentPage - 1) * EQUIP_ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + EQUIP_ITEMS_PER_PAGE - 1, total)

    menu.Separator("Page " .. equipItemCurrentPage .. "/" .. totalPages, total .. " items")

    if equipItemCurrentPage > 1 then
        menu.Button("PAGE PRECEDENTE", nil, nil, "arrow", false, function()
            equipItemCurrentPage = equipItemCurrentPage - 1
            menu.refresh()
        end)
    end
    if equipItemCurrentPage < totalPages then
        menu.Button("PAGE SUIVANTE", nil, nil, "arrow", false, function()
            equipItemCurrentPage = equipItemCurrentPage + 1
            menu.refresh()
        end)
    end

    if totalPages > 1 then
        menu.Separator()
    end

    for i = startIndex, endIndex do
        local entry = filtered[i]
        if entry then
            local weightText = entry.data.weight and (entry.data.weight .. " kg") or ""
          menu.Button(entry.data.label or entry.name, entry.name, weightText, "chevron", false, function()
                currentItemBuild.item_name = entry.name
                equipItemQuery = nil
                equipItemCurrentPage = 1
                exports["VUI"]:HandleBack()
            end)
        end
    end

    if total == 0 then
        menu.Separator("Aucun item", "trouve")
    end
end

function StaffMenu.BuildJobEquipmentItemEditMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItemEdit then return end

    local itemId = StaffMenu.currentJobEquipmentItemId
    local item = StaffMenu.currentJobEquipmentItemData
    if not itemId or not item then return end

    StaffMenu.builderJobEquipmentItemEdit.Separator("ITEM #" .. itemId)

    StaffMenu.builderJobEquipmentItemEdit.Button("ITEM: " .. item.label,
        item.item_name, nil, "check", true, function() end)

    local gradesCount = countTotalGrades(item.allowed_grades or {})
    StaffMenu.builderJobEquipmentItemEdit.Button("GRADES AUTORISÉS: " .. gradesCount,
        "Sélectionner un job puis ses grades", nil, "chevron", false,
        function()
            StaffMenu.currentJobEquipmentGradesMode = "edit"
      end, StaffMenu.builderJobEquipmentItemJobSelectEdit)

    StaffMenu.builderJobEquipmentItemEdit.Button("STOCK MAX: " .. item.max_stock,
        "Modifier le stock maximum", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Stock max", tostring(item.max_stock))
            if result and result ~= "" then
                local newStock = math.max(1, tonumber(result) or item.max_stock)
                TriggerServerEvent("core:jobEquipment:updateItem", itemId, "max_stock", newStock)
                item.max_stock = newStock
                if StaffMenu.builderJobEquipmentItemEdit.refresh then
                    StaffMenu.builderJobEquipmentItemEdit.refresh()
                end
            end
        end)

    StaffMenu.builderJobEquipmentItemEdit.Button("SORTIS: " .. item.current_out .. "/" .. item.max_stock,
        "Reset le compteur de sorties", nil, "arrow", false,
        function()
            TriggerServerEvent("core:jobEquipment:updateItem", itemId, "current_out", 0)
            item.current_out = 0
            if StaffMenu.builderJobEquipmentItemEdit.refresh then
                StaffMenu.builderJobEquipmentItemEdit.refresh()
            end
        end)

    StaffMenu.builderJobEquipmentItemEdit.Separator("ORDRE D'AFFICHAGE")

    local equipmentId = StaffMenu.currentJobEquipmentItemsId
    local itemsList = StaffMenu.currentJobEquipmentItemsList or {}
    local currentIdx = 0
    for i, entry in ipairs(itemsList) do
        if entry.id == itemId then currentIdx = i break end
    end
    local total = #itemsList
    local canUp = currentIdx > 1
    local canDown = currentIdx > 0 and currentIdx < total

    StaffMenu.builderJobEquipmentItemEdit.Button("MONTER",
        canUp and ("Position " .. currentIdx .. "/" .. total .. " -> " .. (currentIdx - 1) .. "/" .. total) or "Déjà en première position",
        nil, "arrow", not canUp,
        function()
            if not canUp then return end
            TriggerServerEvent("core:jobEquipment:reorderItem", itemId, "up")
            Wait(250)
            local items = TriggerServerCallback("core:jobEquipment:getItems", equipmentId)
            StaffMenu.currentJobEquipmentItemsList = items or {}
            if StaffMenu.builderJobEquipmentItemEdit.refresh then
                StaffMenu.builderJobEquipmentItemEdit.refresh()
            end
        end)

    StaffMenu.builderJobEquipmentItemEdit.Button("DESCENDRE",
        canDown and ("Position " .. currentIdx .. "/" .. total .. " -> " .. (currentIdx + 1) .. "/" .. total) or "Déjà en dernière position",
        nil, "arrow", not canDown,
        function()
            if not canDown then return end
            TriggerServerEvent("core:jobEquipment:reorderItem", itemId, "down")
            Wait(250)
            local items = TriggerServerCallback("core:jobEquipment:getItems", equipmentId)
            StaffMenu.currentJobEquipmentItemsList = items or {}
            if StaffMenu.builderJobEquipmentItemEdit.refresh then
                StaffMenu.builderJobEquipmentItemEdit.refresh()
            end
        end)

    StaffMenu.builderJobEquipmentItemEdit.Separator("ACTIONS")

    StaffMenu.builderJobEquipmentItemEdit.Button("SUPPRIMER L'ITEM",
        "Supprimer définitivement cet item", nil, "trash", false,
        function()
            TriggerServerEvent("core:jobEquipment:deleteItem", itemId)
            Wait(500)
            local equipmentId = StaffMenu.currentJobEquipmentItemsId
            local items = TriggerServerCallback("core:jobEquipment:getItems", equipmentId)
            StaffMenu.currentJobEquipmentItemsList = items or {}
            exports["VUI"]:HandleBack()
        end)
end

function StaffMenu.BuildJobEquipmentItemJobSelectMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItemJobSelect then return end

    local equipmentData = StaffMenu.currentJobEquipmentData
    if not equipmentData or not equipmentData.jobs then return end

    StaffMenu.builderJobEquipmentItemJobSelect.Separator("SÉLECTIONNER UN JOB")

    local allowedGrades = currentItemBuild.allowed_grades

    for _, jobName in ipairs(equipmentData.jobs) do
        local jobLabel = equipmentData.jobLabels and equipmentData.jobLabels[jobName] or jobName
        local jobGrades = allowedGrades[jobName]
        local gradesCount = 0
        if jobGrades and type(jobGrades) == "table" then
            for _ in pairs(jobGrades) do gradesCount = gradesCount + 1 end
        end
        StaffMenu.builderJobEquipmentItemJobSelect.Button(
            jobLabel,
            gradesCount .. " grade" .. (gradesCount > 1 and "s" or "") .. " autorisé" .. (gradesCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                StaffMenu.currentJobEquipmentSelectedJobForGrades = jobName
                local grades = TriggerServerCallback("core:jobEquipment:getJobGrades", jobName)
                StaffMenu.currentJobEquipmentJobGrades = grades or {}
            end,
            StaffMenu.builderJobEquipmentItemGrades
        )
    end
end

function StaffMenu.BuildJobEquipmentItemJobSelectEditMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItemJobSelectEdit then return end

    local equipmentData = StaffMenu.currentJobEquipmentData
    if not equipmentData or not equipmentData.jobs then return end

    StaffMenu.builderJobEquipmentItemJobSelectEdit.Separator("SÉLECTIONNER UN JOB")

    local item = StaffMenu.currentJobEquipmentItemData
    local allowedGrades = item and item.allowed_grades or {}

    for _, jobName in ipairs(equipmentData.jobs) do
        local jobLabel = equipmentData.jobLabels and equipmentData.jobLabels[jobName] or jobName
        local jobGrades = allowedGrades[jobName]
        local gradesCount = 0
        if jobGrades and type(jobGrades) == "table" then
            for _ in pairs(jobGrades) do gradesCount = gradesCount + 1 end
        end
        StaffMenu.builderJobEquipmentItemJobSelectEdit.Button(
            jobLabel,
            gradesCount .. " grade" .. (gradesCount > 1 and "s" or "") .. " autorisé" .. (gradesCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                StaffMenu.currentJobEquipmentSelectedJobForGrades = jobName
                local grades = TriggerServerCallback("core:jobEquipment:getJobGrades", jobName)
                StaffMenu.currentJobEquipmentJobGrades = grades or {}
            end,
            StaffMenu.builderJobEquipmentItemGrades
        )
    end
end

function StaffMenu.BuildJobEquipmentItemGradesMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentItemGrades then return end

    local grades = StaffMenu.currentJobEquipmentJobGrades or {}
    local mode = StaffMenu.currentJobEquipmentGradesMode or "add"
  local selectedJob = StaffMenu.currentJobEquipmentSelectedJobForGrades

    if not selectedJob then return end

    local allowedGrades
    if mode == "edit" then
        local item = StaffMenu.currentJobEquipmentItemData
        allowedGrades = item and item.allowed_grades or {}
    else
        allowedGrades = currentItemBuild.allowed_grades
    end

    local jobLabel = selectedJob
    local equipmentData = StaffMenu.currentJobEquipmentData
    if equipmentData and equipmentData.jobLabels then
        jobLabel = equipmentData.jobLabels[selectedJob] or selectedJob
    end

    StaffMenu.builderJobEquipmentItemGrades.Separator("GRADES - " .. jobLabel)

    if #grades == 0 then
        StaffMenu.builderJobEquipmentItemGrades.Button("Aucun grade trouvé",
            "Vérifiez que le job est valide", nil, "empty", true, function() end)
        return
    end

    for _, gradeInfo in ipairs(grades) do
        local allowed = isGradeInList(allowedGrades, selectedJob, gradeInfo.grade)
        local currentMax = getGradeMax(allowedGrades, selectedJob, gradeInfo.grade)
        local desc = allowed and ("Max par joueur: " .. currentMax) or "Grade " .. gradeInfo.grade
        StaffMenu.builderJobEquipmentItemGrades.Button(
            gradeInfo.label,
            desc,
            nil,
            allowed and "check" or "empty",
            false,
            function()
                if allowed then
                    local result = VFW.Nui.KeyboardInput(true, "Max par joueur (0 pour retirer)", tostring(currentMax))
                    if result then
                        local newMax = tonumber(result)
                        if not newMax or newMax <= 0 then
                            toggleGradeInList(allowedGrades, selectedJob, gradeInfo.grade)
                        else
                            setGradeMax(allowedGrades, selectedJob, gradeInfo.grade, newMax)
                        end
                    end
                else
                    toggleGradeInList(allowedGrades, selectedJob, gradeInfo.grade)
                end

                if mode == "edit" then
                    local item = StaffMenu.currentJobEquipmentItemData
                    if item then
                        item.allowed_grades = allowedGrades
                        TriggerServerEvent("core:jobEquipment:updateItem", item.id, "allowed_grades", allowedGrades)
                    end
                else
                    currentItemBuild.allowed_grades = allowedGrades
                end

                if StaffMenu.builderJobEquipmentItemGrades.refresh then
                    StaffMenu.builderJobEquipmentItemGrades.refresh()
                end
            end
        )
    end
end

function StaffMenu.BuildJobEquipmentLogsJobSelectMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentLogsJobSelect then return end

    local data = StaffMenu.currentJobEquipmentData
    local id = StaffMenu.currentJobEquipmentId
    if not data or not id then return end

    if not data.logsAllowedGrades then data.logsAllowedGrades = {} end

    StaffMenu.builderJobEquipmentLogsJobSelect.Separator("ACCÈS HISTORIQUE PAR GRADE")

    StaffMenu.builderJobEquipmentLogsJobSelect.Button("RÉINITIALISER",
        "Supprimer toutes les restrictions (tous les grades pourront voir)", nil, "trash", false,
        function()
            data.logsAllowedGrades = {}
            TriggerServerEvent("core:jobEquipment:update", id, "logsAllowedGrades", {})
            if StaffMenu.builderJobEquipmentLogsJobSelect.refresh then
                StaffMenu.builderJobEquipmentLogsJobSelect.refresh()
            end
        end)

    StaffMenu.builderJobEquipmentLogsJobSelect.Separator("SÉLECTIONNER UN JOB")

    local jobs = data.jobs or {}
    if #jobs == 0 then
        StaffMenu.builderJobEquipmentLogsJobSelect.Button("Aucun job configuré", nil, nil, "empty", true, function() end)
        return
    end

    for _, jobName in ipairs(jobs) do
        local jobLabel = data.jobLabels and data.jobLabels[jobName] or jobName
        local jobGrades = data.logsAllowedGrades[jobName]
        local gradesCount = 0
        if jobGrades and type(jobGrades) == "table" then
            for _ in pairs(jobGrades) do gradesCount = gradesCount + 1 end
        end
        StaffMenu.builderJobEquipmentLogsJobSelect.Button(
            jobLabel,
            gradesCount .. " grade" .. (gradesCount > 1 and "s" or "") .. " autorisé" .. (gradesCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                StaffMenu.currentJobEquipmentLogsSelectedJob = jobName
                local grades = TriggerServerCallback("core:jobEquipment:getJobGrades", jobName)
                StaffMenu.currentJobEquipmentLogsJobGrades = grades or {}
            end,
            StaffMenu.builderJobEquipmentLogsGrades
        )
    end
end

function StaffMenu.BuildJobEquipmentLogsGradesMenu()
    if not StaffMenu or not StaffMenu.builderJobEquipmentLogsGrades then return end

    local data = StaffMenu.currentJobEquipmentData
    local id = StaffMenu.currentJobEquipmentId
    local selectedJob = StaffMenu.currentJobEquipmentLogsSelectedJob
    local grades = StaffMenu.currentJobEquipmentLogsJobGrades or {}
    if not data or not id or not selectedJob then return end

    if not data.logsAllowedGrades then data.logsAllowedGrades = {} end

    local jobLabel = data.jobLabels and data.jobLabels[selectedJob] or selectedJob
    StaffMenu.builderJobEquipmentLogsGrades.Separator("GRADES LOGS - " .. jobLabel)

    if #grades == 0 then
        StaffMenu.builderJobEquipmentLogsGrades.Button("Aucun grade trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, gradeInfo in ipairs(grades) do
        local allowed = isGradeInList(data.logsAllowedGrades, selectedJob, gradeInfo.grade)
        StaffMenu.builderJobEquipmentLogsGrades.Button(
            gradeInfo.label,
            "Grade " .. gradeInfo.grade,
            nil,
            allowed and "check" or "empty",
            false,
            function()
                toggleGradeInList(data.logsAllowedGrades, selectedJob, gradeInfo.grade)
                TriggerServerEvent("core:jobEquipment:update", id, "logsAllowedGrades", data.logsAllowedGrades)
                if StaffMenu.builderJobEquipmentLogsGrades.refresh then
                    StaffMenu.builderJobEquipmentLogsGrades.refresh()
                end
            end
        )
    end
end

if StaffMenu and StaffMenu.builderJobEquipment and StaffMenu.builderJobEquipment.OnOpen then
    StaffMenu.builderJobEquipment.OnOpen(function()
        StaffMenu.BuildJobEquipmentMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentCreate then
    if StaffMenu.builderJobEquipmentCreate.OnOpen then
        StaffMenu.builderJobEquipmentCreate.OnOpen(function()
            StaffMenu.BuildJobEquipmentCreateMenu()
            if currentBuild.position or currentBuild.npcPosition then
                startMarkerThread()
            end
        end)
    end
    if StaffMenu.builderJobEquipmentCreate.OnClose then
        StaffMenu.builderJobEquipmentCreate.OnClose(function()
            stopMarkerThread()
        end)
    end
end

if StaffMenu and StaffMenu.builderJobEquipmentJobs and StaffMenu.builderJobEquipmentJobs.OnOpen then
    StaffMenu.builderJobEquipmentJobs.OnOpen(function()
        if not cachedAllJobs then
            cachedAllJobs = TriggerServerCallback("core:jobEquipment:getAllJobs") or {}
        end
        StaffMenu.BuildJobEquipmentJobsMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentManage and StaffMenu.builderJobEquipmentManage.OnOpen then
    StaffMenu.builderJobEquipmentManage.OnOpen(function()
        local equipments = TriggerServerCallback("core:jobEquipment:getEquipments")
        StaffMenu.currentJobEquipments = equipments or {}
        StaffMenu.BuildJobEquipmentManageMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentEdit and StaffMenu.builderJobEquipmentEdit.OnOpen then
    StaffMenu.builderJobEquipmentEdit.OnOpen(function()
        StaffMenu.BuildJobEquipmentEditMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentEditJobs and StaffMenu.builderJobEquipmentEditJobs.OnOpen then
    StaffMenu.builderJobEquipmentEditJobs.OnOpen(function()
        if not cachedAllJobs then
            cachedAllJobs = TriggerServerCallback("core:jobEquipment:getAllJobs") or {}
        end
        StaffMenu.BuildJobEquipmentEditJobsMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItems and StaffMenu.builderJobEquipmentItems.OnOpen then
    StaffMenu.builderJobEquipmentItems.OnOpen(function()
        local equipmentId = StaffMenu.currentJobEquipmentItemsId
        if equipmentId then
            local items = TriggerServerCallback("core:jobEquipment:getItems", equipmentId)
            StaffMenu.currentJobEquipmentItemsList = items or {}
        end
        StaffMenu.BuildJobEquipmentItemsMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItemAdd and StaffMenu.builderJobEquipmentItemAdd.OnOpen then
    StaffMenu.builderJobEquipmentItemAdd.OnOpen(function()
        StaffMenu.BuildJobEquipmentItemAddMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItemSelect and StaffMenu.builderJobEquipmentItemSelect.OnOpen then
    StaffMenu.builderJobEquipmentItemSelect.OnOpen(function()
        StaffMenu.BuildJobEquipmentItemSelectMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItemEdit and StaffMenu.builderJobEquipmentItemEdit.OnOpen then
    StaffMenu.builderJobEquipmentItemEdit.OnOpen(function()
        StaffMenu.BuildJobEquipmentItemEditMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItemJobSelect and StaffMenu.builderJobEquipmentItemJobSelect.OnOpen then
    StaffMenu.builderJobEquipmentItemJobSelect.OnOpen(function()
        StaffMenu.BuildJobEquipmentItemJobSelectMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItemJobSelectEdit and StaffMenu.builderJobEquipmentItemJobSelectEdit.OnOpen then
    StaffMenu.builderJobEquipmentItemJobSelectEdit.OnOpen(function()
        StaffMenu.BuildJobEquipmentItemJobSelectEditMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentItemGrades and StaffMenu.builderJobEquipmentItemGrades.OnOpen then
    StaffMenu.builderJobEquipmentItemGrades.OnOpen(function()
        local selectedJob = StaffMenu.currentJobEquipmentSelectedJobForGrades
        if selectedJob then
            local grades = TriggerServerCallback("core:jobEquipment:getJobGrades", selectedJob)
            StaffMenu.currentJobEquipmentJobGrades = grades or {}
        end
        StaffMenu.BuildJobEquipmentItemGradesMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentLogsJobSelect and StaffMenu.builderJobEquipmentLogsJobSelect.OnOpen then
    StaffMenu.builderJobEquipmentLogsJobSelect.OnOpen(function()
        StaffMenu.BuildJobEquipmentLogsJobSelectMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobEquipmentLogsGrades and StaffMenu.builderJobEquipmentLogsGrades.OnOpen then
    StaffMenu.builderJobEquipmentLogsGrades.OnOpen(function()
        local selectedJob = StaffMenu.currentJobEquipmentLogsSelectedJob
        if selectedJob then
            local grades = TriggerServerCallback("core:jobEquipment:getJobGrades", selectedJob)
            StaffMenu.currentJobEquipmentLogsJobGrades = grades or {}
        end
        StaffMenu.BuildJobEquipmentLogsGradesMenu()
    end)
end
