local currentBuild = {
    name = "",
    jobs = {},
    position = nil,
    npcPosition = nil,
    npcModel = "s_m_y_armymech_01",
    blipEnabled = true,
    isValid = false
}

local currentWeaponBuild = {
    item_name = "",
    allowed_grades = {},
    max_stock = 1
}

local markerThread = nil
local isMarkersActive = false
local markerGeneration = 0
local cachedAllJobs = nil

local function validateBuild()
    currentBuild.isValid = currentBuild.name ~= "" and #currentBuild.jobs > 0 and (currentBuild.npcPosition ~= nil or currentBuild.position ~= nil)
    return currentBuild.isValid
end

local function validateWeaponBuild()
    return currentWeaponBuild.item_name ~= "" and
            currentWeaponBuild.max_stock > 0
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
                    1.5, 1.5, 1.0, 0, 100, 255, 150, false, true, 2, false, nil, nil, false)
                local onScreen, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(0, 100, 255, 215)
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
                    2.0, 2.0, 1.0, 0, 100, 255, 150, false, true, 2, false, nil, nil, false)
                local onScreen, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(0, 100, 255, 215)
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

local function resetWeaponBuild()
    currentWeaponBuild = {
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

function StaffMenu.BuildJobArmoryMenu()
    if not StaffMenu or not StaffMenu.builderJobArmory then return end

    StaffMenu.builderJobArmory.Button("CRÉER UNE ARMURERIE", "Créer une nouvelle armurerie job",
        nil, "chevron", false, function()
            resetBuild()
        end, StaffMenu.builderJobArmoryCreate)

    StaffMenu.builderJobArmory.Button("GÉRER LES ARMURERIES", "Voir et gérer les armureries existantes",
        nil, "chevron", false, function()
            local armories = TriggerServerCallback("core:jobArmory:getArmories")
            StaffMenu.currentJobArmories = armories or {}
        end, StaffMenu.builderJobArmoryManage)
end

function StaffMenu.BuildJobArmoryCreateMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryCreate then return end

    StaffMenu.builderJobArmoryCreate.Button("NOM: " .. (currentBuild.name ~= "" and currentBuild.name or "NON DÉFINI"),
        "Définir le nom de l'armurerie", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Nom de l'armurerie", currentBuild.name)
            if result and result ~= "" then
                currentBuild.name = result
                validateBuild()
                if StaffMenu.builderJobArmoryCreate.refresh then
                    StaffMenu.builderJobArmoryCreate.refresh()
                end
            end
        end)

    local jobCount = #currentBuild.jobs
    StaffMenu.builderJobArmoryCreate.Button(
        "JOBS: " .. (jobCount > 0 and (jobCount .. " sélectionné" .. (jobCount > 1 and "s" or "")) or "NON DÉFINI"),
        "Sélectionner les jobs liés à cette armurerie",
        nil, "chevron", false,
        function()
            if not cachedAllJobs then
                cachedAllJobs = TriggerServerCallback("core:jobArmory:getAllJobs") or {}
            end
        end,
        StaffMenu.builderJobArmoryJobs
    )

    local blipText = currentBuild.position and
        string.format("X: %.2f Y: %.2f Z: %.2f", currentBuild.position.x, currentBuild.position.y, currentBuild.position.z) or "NON DÉFINI"

  StaffMenu.builderJobArmoryCreate.Button("POSITION BLIP: " .. blipText,
        "Définir la position du blip", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                currentBuild.position = pos
                validateBuild()
                startMarkerThread()
                if StaffMenu.builderJobArmoryCreate.refresh then
                    StaffMenu.builderJobArmoryCreate.refresh()
                end
            end
        end)

    local npcText = currentBuild.npcPosition and
        string.format("X: %.2f Y: %.2f Z: %.2f", currentBuild.npcPosition.x, currentBuild.npcPosition.y, currentBuild.npcPosition.z) or "NON DÉFINI"

  StaffMenu.builderJobArmoryCreate.Button("POSITION NPC: " .. npcText,
        "Optionnel - sans NPC un marqueur sera affiché", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                currentBuild.npcPosition = pos
                validateBuild()
                startMarkerThread()
                if StaffMenu.builderJobArmoryCreate.refresh then
                    StaffMenu.builderJobArmoryCreate.refresh()
                end
            end
        end)

    StaffMenu.builderJobArmoryCreate.Button("MODÈLE NPC: " .. (currentBuild.npcModel or "s_m_y_armymech_01"),
        "Modèle du PED vendeur", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Modèle du PED (ex: s_m_y_armymech_01)", currentBuild.npcModel or "")
            if result and result ~= "" then
                currentBuild.npcModel = result
                if StaffMenu.builderJobArmoryCreate.refresh then
                    StaffMenu.builderJobArmoryCreate.refresh()
                end
            end
        end)

    StaffMenu.builderJobArmoryCreate.Button("BLIP: " .. (currentBuild.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
        "Activer ou désactiver le blip", nil, "arrow", false,
        function()
            currentBuild.blipEnabled = not currentBuild.blipEnabled
            if StaffMenu.builderJobArmoryCreate.refresh then
                StaffMenu.builderJobArmoryCreate.refresh()
            end
        end)

    StaffMenu.builderJobArmoryCreate.Separator(nil)

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

    StaffMenu.builderJobArmoryCreate.Button("CRÉER L'ARMURERIE", statusMsg,
        nil, "chevron", not currentBuild.isValid,
        function()
            if not validateBuild() then
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
                return
            end
            TriggerServerEvent("core:jobArmory:create", {
                name = currentBuild.name,
                jobs = currentBuild.jobs,
                pos = currentBuild.position or currentBuild.npcPosition,
                npcPos = currentBuild.npcPosition,
                npcModel = currentBuild.npcModel,
                blipEnabled = currentBuild.blipEnabled
            })
            resetBuild()
            StaffMenu.builderJobArmoryCreate.close()
            StaffMenu.builderJobArmoryCreate.parent.open()
        end)
end

function StaffMenu.BuildJobArmoryJobsMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryJobs then return end

    StaffMenu.builderJobArmoryJobs.Separator("SÉLECTION DES JOBS")

    if not cachedAllJobs or #cachedAllJobs == 0 then
        StaffMenu.builderJobArmoryJobs.Button("Aucun job trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, job in ipairs(cachedAllJobs) do
        local selected = isJobInList(currentBuild.jobs, job.name)
        StaffMenu.builderJobArmoryJobs.Button(
            job.label,
            job.name,
            nil,
            selected and "check" or "empty",
            false,
            function()
                toggleJobInList(currentBuild.jobs, job.name)
                validateBuild()
                if StaffMenu.builderJobArmoryJobs.refresh then
                    StaffMenu.builderJobArmoryJobs.refresh()
                end
            end
        )
    end
end

function StaffMenu.BuildJobArmoryManageMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryManage then return end

    local armories = StaffMenu.currentJobArmories or {}
    local has = #armories > 0

    StaffMenu.builderJobArmoryManage.Separator(has and "ARMURERIES EXISTANTES" or "AUCUNE ARMURERIE")

    if has then
        for _, data in ipairs(armories) do
            if data and data.name then
                local posText = data.pos and string.format("X: %.0f Y: %.0f Z: %.0f", data.pos.x, data.pos.y, data.pos.z) or "Position inconnue"
              StaffMenu.builderJobArmoryManage.Button(data.name .. " #" .. data.id,
                    posText, nil, "chevron", false,
                    function()
                        StaffMenu.currentJobArmoryId = data.id
                        StaffMenu.currentJobArmoryData = data
                    end, StaffMenu.builderJobArmoryEdit)
            end
        end
    end
end

function StaffMenu.BuildJobArmoryEditMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryEdit then return end

    local id = StaffMenu.currentJobArmoryId
    local data = StaffMenu.currentJobArmoryData
    if not id or not data then return end

    StaffMenu.builderJobArmoryEdit.Separator("ARMURERIE #" .. id)

    StaffMenu.builderJobArmoryEdit.Button("NOM: " .. data.name,
        "Nom de l'armurerie", nil, "check", true, function() end)

    local jobs = data.jobs or {}
    local jobCount = #jobs
    StaffMenu.builderJobArmoryEdit.Button(
        "JOBS: " .. (jobCount > 0 and (jobCount .. " sélectionné" .. (jobCount > 1 and "s" or "")) or "NON DÉFINI"),
        "Modifier les jobs liés à cette armurerie",
        nil, "chevron", false,
        function()
            if not cachedAllJobs then
                cachedAllJobs = TriggerServerCallback("core:jobArmory:getAllJobs") or {}
            end
        end,
        StaffMenu.builderJobArmoryEditJobs
    )

    local blipText = data.pos and string.format("X: %.2f Y: %.2f Z: %.2f", data.pos.x, data.pos.y, data.pos.z) or "NON DÉFINI"
  StaffMenu.builderJobArmoryEdit.Button("POSITION BLIP: " .. blipText,
        "Modifier la position du blip", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                TriggerServerEvent("core:jobArmory:update", id, "pos", pos)
                data.pos = pos
                if StaffMenu.builderJobArmoryEdit.refresh then
                    StaffMenu.builderJobArmoryEdit.refresh()
                end
            end
        end)

    local npcText = data.npcPos and string.format("X: %.2f Y: %.2f Z: %.2f", data.npcPos.x, data.npcPos.y, data.npcPos.z) or "NON DÉFINI"
  StaffMenu.builderJobArmoryEdit.Button("POSITION NPC: " .. npcText,
        "Modifier la position du vendeur", nil, "arrow", false,
        function()
            local pos = getCurrentPlayerPosition()
            if pos then
                TriggerServerEvent("core:jobArmory:update", id, "npcPos", pos)
                data.npcPos = pos
                if StaffMenu.builderJobArmoryEdit.refresh then
                    StaffMenu.builderJobArmoryEdit.refresh()
                end
            end
        end)

    StaffMenu.builderJobArmoryEdit.Button("MODÈLE NPC: " .. (data.npcModel or "s_m_y_armymech_01"),
        "Modifier le modèle du PED vendeur", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Modèle du PED", data.npcModel or "s_m_y_armymech_01")
            if result and result ~= "" then
                TriggerServerEvent("core:jobArmory:update", id, "npcModel", result)
                data.npcModel = result
                if StaffMenu.builderJobArmoryEdit.refresh then
                    StaffMenu.builderJobArmoryEdit.refresh()
                end
            end
        end)

    StaffMenu.builderJobArmoryEdit.Button("ACTIVÉ: " .. (data.active and "OUI" or "NON"),
        "Activer ou désactiver l'armurerie", nil, "arrow", false,
        function()
            local newVal = not data.active
            TriggerServerEvent("core:jobArmory:update", id, "active", newVal)
            data.active = newVal
            if StaffMenu.builderJobArmoryEdit.refresh then
                StaffMenu.builderJobArmoryEdit.refresh()
            end
        end)

    StaffMenu.builderJobArmoryEdit.Button("BLIP: " .. (data.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
        "Activer ou désactiver le blip", nil, "arrow", false,
        function()
            local newVal = not data.blipEnabled
            TriggerServerEvent("core:jobArmory:update", id, "blipEnabled", newVal)
            data.blipEnabled = newVal
            if StaffMenu.builderJobArmoryEdit.refresh then
                StaffMenu.builderJobArmoryEdit.refresh()
            end
        end)

    if not data.logsAllowedGrades then data.logsAllowedGrades = {} end
    local logsGradesCount = countTotalGrades(data.logsAllowedGrades)
    local logsDesc = logsGradesCount > 0
        and (logsGradesCount .. " grade" .. (logsGradesCount > 1 and "s" or "") .. " autorisé" .. (logsGradesCount > 1 and "s" or ""))
        or "Tous les grades (aucune restriction)"
  StaffMenu.builderJobArmoryEdit.Button("ACCÈS HISTORIQUE: " .. (logsGradesCount > 0 and logsGradesCount or "TOUS"),
        logsDesc, nil, "chevron", false,
        function() end,
        StaffMenu.builderJobArmoryLogsJobSelect)

    StaffMenu.builderJobArmoryEdit.Separator("GESTION")

    StaffMenu.builderJobArmoryEdit.Button("GÉRER LES ARMES", "Ajouter, modifier ou supprimer des armes",
        nil, "chevron", false, function()
            StaffMenu.currentJobArmoryWeaponsId = id
            local weapons = TriggerServerCallback("core:jobArmory:getWeapons", id)
            StaffMenu.currentJobArmoryWeaponsList = weapons or {}
        end, StaffMenu.builderJobArmoryWeapons)

    StaffMenu.builderJobArmoryEdit.Button("CLEAR HISTORIQUE",
        "Supprimer tous les logs de cette armurerie", nil, "trash", false,
        function()
            TriggerServerEvent("core:jobArmory:clearLogs", id)
        end)

    StaffMenu.builderJobArmoryEdit.Button("TÉLÉPORTER AU NPC",
        "Se téléporter à la position du vendeur", nil, "arrow", false,
        function()
            local npcPos = data.npcPos or data.pos
            if npcPos then
                SetEntityCoords(PlayerPedId(), npcPos.x, npcPos.y, npcPos.z, false, false, false, true)
            end
        end)

    StaffMenu.builderJobArmoryEdit.Button("SUPPRIMER L'ARMURERIE",
        "Supprimer définitivement cette armurerie", nil, "trash", false,
        function()
            TriggerServerEvent("core:jobArmory:delete", id)
            Wait(500)
            local armories = TriggerServerCallback("core:jobArmory:getArmories")
            StaffMenu.currentJobArmories = armories or {}
            StaffMenu.builderJobArmoryEdit.close()
            StaffMenu.builderJobArmoryEdit.parent.open()
        end)
end

function StaffMenu.BuildJobArmoryEditJobsMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryEditJobs then return end

    local data = StaffMenu.currentJobArmoryData
    local id = StaffMenu.currentJobArmoryId
    if not data or not id then return end

    if not data.jobs then data.jobs = {} end

    StaffMenu.builderJobArmoryEditJobs.Separator("SÉLECTION DES JOBS")

    if not cachedAllJobs or #cachedAllJobs == 0 then
        StaffMenu.builderJobArmoryEditJobs.Button("Aucun job trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, job in ipairs(cachedAllJobs) do
        local selected = isJobInList(data.jobs, job.name)
        StaffMenu.builderJobArmoryEditJobs.Button(
            job.label,
            job.name,
            nil,
            selected and "check" or "empty",
            false,
            function()
                toggleJobInList(data.jobs, job.name)
                TriggerServerEvent("core:jobArmory:update", id, "jobs", data.jobs)
                if StaffMenu.builderJobArmoryEditJobs.refresh then
                    StaffMenu.builderJobArmoryEditJobs.refresh()
                end
            end
        )
    end
end

function StaffMenu.BuildJobArmoryWeaponsMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeapons then return end

    local armoryId = StaffMenu.currentJobArmoryWeaponsId

    StaffMenu.builderJobArmoryWeapons.Button("AJOUTER UNE ARME", "Ajouter une arme à cette armurerie",
        nil, "chevron", false, function()
            resetWeaponBuild()
            currentWeaponBuild.armory_id = armoryId
        end, StaffMenu.builderJobArmoryWeaponAdd)

    local weapons = StaffMenu.currentJobArmoryWeaponsList or {}
    local has = #weapons > 0

    StaffMenu.builderJobArmoryWeapons.Separator(has and "ARMES CONFIGURÉES" or "AUCUNE ARME")

    if has then
        for _, w in ipairs(weapons) do
            local gradesCount = countTotalGrades(w.allowed_grades or {})
            local desc = string.format("Grades: %d | Stock: %d/%d | Sortis: %d",
                gradesCount, w.max_stock - w.current_out, w.max_stock, w.current_out)
            StaffMenu.builderJobArmoryWeapons.Button(w.label,
                desc, nil, "chevron", false,
                function()
                    StaffMenu.currentJobArmoryWeaponId = w.id
                    StaffMenu.currentJobArmoryWeaponData = w
                end, StaffMenu.builderJobArmoryWeaponEdit)
        end
    end
end

function StaffMenu.BuildJobArmoryWeaponAddMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeaponAdd then return end

    local armoryId = StaffMenu.currentJobArmoryWeaponsId
    local itemLabel = currentWeaponBuild.item_name ~= "" and
        (VFW.Items[currentWeaponBuild.item_name] and VFW.Items[currentWeaponBuild.item_name].label or currentWeaponBuild.item_name) or "NON DÉFINI"

  StaffMenu.builderJobArmoryWeaponAdd.Button("ITEM: " .. itemLabel,
        "Sélectionner l'arme dans la liste", nil, "chevron", false,
        function() end,
        StaffMenu.builderJobArmoryWeaponItemSelect)

    local gradesCount = countTotalGrades(currentWeaponBuild.allowed_grades)
    StaffMenu.builderJobArmoryWeaponAdd.Button("GRADES AUTORISÉS: " .. gradesCount,
        "Sélectionner un job puis ses grades", nil, "chevron", false,
        function()
            StaffMenu.currentJobArmoryGradesMode = "add"
      end, StaffMenu.builderJobArmoryWeaponJobSelect)

    StaffMenu.builderJobArmoryWeaponAdd.Button("STOCK MAX: " .. currentWeaponBuild.max_stock,
        "Nombre maximum d'armes sorties simultanément", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Stock max", tostring(currentWeaponBuild.max_stock))
            if result and result ~= "" then
                currentWeaponBuild.max_stock = math.max(1, tonumber(result) or 1)
                if StaffMenu.builderJobArmoryWeaponAdd.refresh then
                    StaffMenu.builderJobArmoryWeaponAdd.refresh()
                end
            end
        end)

    StaffMenu.builderJobArmoryWeaponAdd.Separator(nil)

    local statusMsg = ""
  if currentWeaponBuild.item_name == "" then
        statusMsg = "Item requis"
  else
        statusMsg = "Prêt à ajouter"
  end

    StaffMenu.builderJobArmoryWeaponAdd.Button("AJOUTER L'ARME", statusMsg,
        nil, "chevron", not validateWeaponBuild(),
        function()
            if not validateWeaponBuild() then
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
                return
            end
            TriggerServerEvent("core:jobArmory:addWeapon", {
                armory_id = armoryId,
                item_name = currentWeaponBuild.item_name,
                allowed_grades = currentWeaponBuild.allowed_grades,
                max_stock = currentWeaponBuild.max_stock
            })
            resetWeaponBuild()
            Wait(500)
            local weapons = TriggerServerCallback("core:jobArmory:getWeapons", armoryId)
            StaffMenu.currentJobArmoryWeaponsList = weapons or {}
            StaffMenu.builderJobArmoryWeaponAdd.close()
            StaffMenu.builderJobArmoryWeaponAdd.parent.open()
        end)
end

local weaponSearchText = ""

local function getWeaponCategory(name)
    local upper = string.upper(name)
    if string.find(upper, "PISTOL") or string.find(upper, "REVOLVER") or string.find(upper, "STUNGUN") or string.find(upper, "STUNROD") then
        return "PISTOLETS"
  end
    if string.find(upper, "SHOTGUN") or string.find(upper, "MUSKET") then
        return "SHOTGUNS"
  end
    if string.find(upper, "SMG") or upper == "WEAPON_COMBATPDW" or upper == "WEAPON_MACHINEPISTOL" or upper == "WEAPON_MINISMG" or upper == "WEAPON_TECPISTOL" then
        return "SMG"
  end
    if string.find(upper, "SNIPER") or string.find(upper, "MARKSMAN") or string.find(upper, "PRECISION") then
        return "SNIPERS"
  end
    if upper == "WEAPON_MG" or upper == "WEAPON_COMBATMG" or upper == "WEAPON_COMBATMG_MK2" or upper == "WEAPON_GUSENBERG" then
        return "MITRAILLEUSES"
  end
    if string.find(upper, "LAUNCHER") or string.find(upper, "MINIGUN") or string.find(upper, "RPG") or string.find(upper, "RAILGUN") or string.find(upper, "FIREWORK") then
        return "LOURDES"
  end
    if string.find(upper, "RIFLE") then
        return "FUSILS D'ASSAUT"
  end
    if string.find(upper, "GRENADE") or string.find(upper, "MOLOTOV") or string.find(upper, "BZGAS") or string.find(upper, "SMOKEGRENADE") or string.find(upper, "FLARE") or string.find(upper, "PROXMINE") or string.find(upper, "STICKYBOMB") or string.find(upper, "BALL") or string.find(upper, "SNOWBALL") or string.find(upper, "PIPEBOMB") then
        return "LANCABLES"
  end
    return "AUTRES"
end

local weaponCategoryOrder = {
    "PISTOLETS",
    "SMG",
    "FUSILS D'ASSAUT",
    "SHOTGUNS",
    "SNIPERS",
    "MITRAILLEUSES",
    "LOURDES",
    "LANCABLES",
    "AUTRES",
}

function StaffMenu.BuildJobArmoryWeaponItemSelectMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeaponItemSelect then return end

    local Button = StaffMenu.builderJobArmoryWeaponItemSelect.Button
    local Separator = StaffMenu.builderJobArmoryWeaponItemSelect.Separator

    Separator("RECHERCHE")

    Button("Rechercher une arme", weaponSearchText ~= "" and ("Recherche : " .. weaponSearchText) or nil,
        nil, "search", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Rechercher une arme", weaponSearchText)
            if input then
                weaponSearchText = input
                if StaffMenu.builderJobArmoryWeaponItemSelect.refresh then
                    StaffMenu.builderJobArmoryWeaponItemSelect.refresh()
                end
            end
        end)

    if weaponSearchText ~= "" then
        Button("Effacer la recherche", nil, nil, "trash", false, function()
            weaponSearchText = ""
          if StaffMenu.builderJobArmoryWeaponItemSelect.refresh then
                StaffMenu.builderJobArmoryWeaponItemSelect.refresh()
            end
        end)
    end

    local categorized = {}
    for _, cat in ipairs(weaponCategoryOrder) do
        categorized[cat] = {}
    end

    for itemName, item in pairs(VFW.Items) do
        if item.type == "weapons" then
            local cat = getWeaponCategory(itemName)
            if not categorized[cat] then categorized[cat] = {} end
            table.insert(categorized[cat], { name = itemName, label = item.label or itemName })
        end
    end

    for _, cat in ipairs(weaponCategoryOrder) do
        table.sort(categorized[cat], function(a, b) return a.label < b.label end)
    end

    local searchLower = weaponSearchText ~= "" and string.lower(weaponSearchText) or nil
    local selectedName = currentWeaponBuild.item_name

    for _, cat in ipairs(weaponCategoryOrder) do
        local list = categorized[cat] or {}
        local filtered = list
        if searchLower then
            filtered = {}
            for _, w in ipairs(list) do
                if string.find(string.lower(w.label), searchLower, 1, true) or string.find(string.lower(w.name), searchLower, 1, true) then
                    table.insert(filtered, w)
                end
            end
        end

        if #filtered > 0 then
            Separator(cat)
            for _, w in ipairs(filtered) do
                local isSelected = selectedName == w.name
                Button(w.label, w.name, nil, isSelected and "check" or "empty", false, function()
                    currentWeaponBuild.item_name = w.name
                    StaffMenu.builderJobArmoryWeaponItemSelect.close()
                    StaffMenu.builderJobArmoryWeaponItemSelect.parent.open()
                end)
            end
        end
    end
end

function StaffMenu.BuildJobArmoryWeaponEditMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeaponEdit then return end

    local weaponId = StaffMenu.currentJobArmoryWeaponId
    local w = StaffMenu.currentJobArmoryWeaponData
    if not weaponId or not w then return end

    StaffMenu.builderJobArmoryWeaponEdit.Separator("ARME #" .. weaponId)

    StaffMenu.builderJobArmoryWeaponEdit.Button("ITEM: " .. w.label,
        w.item_name, nil, "check", true, function() end)

    local gradesCount = countTotalGrades(w.allowed_grades or {})
    StaffMenu.builderJobArmoryWeaponEdit.Button("GRADES AUTORISÉS: " .. gradesCount,
        "Sélectionner un job puis ses grades", nil, "chevron", false,
        function()
            StaffMenu.currentJobArmoryGradesMode = "edit"
      end, StaffMenu.builderJobArmoryWeaponJobSelectEdit)

    StaffMenu.builderJobArmoryWeaponEdit.Button("STOCK MAX: " .. w.max_stock,
        "Modifier le stock maximum", nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Stock max", tostring(w.max_stock))
            if result and result ~= "" then
                local newStock = math.max(1, tonumber(result) or w.max_stock)
                TriggerServerEvent("core:jobArmory:updateWeapon", weaponId, "max_stock", newStock)
                w.max_stock = newStock
                if StaffMenu.builderJobArmoryWeaponEdit.refresh then
                    StaffMenu.builderJobArmoryWeaponEdit.refresh()
                end
            end
        end)

    StaffMenu.builderJobArmoryWeaponEdit.Button("SORTIS: " .. w.current_out .. "/" .. w.max_stock,
        "Reset le compteur de sorties", nil, "arrow", false,
        function()
            TriggerServerEvent("core:jobArmory:updateWeapon", weaponId, "current_out", 0)
            w.current_out = 0
            if StaffMenu.builderJobArmoryWeaponEdit.refresh then
                StaffMenu.builderJobArmoryWeaponEdit.refresh()
            end
        end)

    StaffMenu.builderJobArmoryWeaponEdit.Separator("ORDRE D'AFFICHAGE")

    local armoryId = StaffMenu.currentJobArmoryWeaponsId
    local weaponsList = StaffMenu.currentJobArmoryWeaponsList or {}
    local currentIdx = 0
    for i, entry in ipairs(weaponsList) do
        if entry.id == weaponId then currentIdx = i break end
    end
    local total = #weaponsList
    local canUp = currentIdx > 1
    local canDown = currentIdx > 0 and currentIdx < total

    StaffMenu.builderJobArmoryWeaponEdit.Button("MONTER",
        canUp and ("Position " .. currentIdx .. "/" .. total .. " -> " .. (currentIdx - 1) .. "/" .. total) or "Déjà en première position",
        nil, "arrow", not canUp,
        function()
            if not canUp then return end
            TriggerServerEvent("core:jobArmory:reorderWeapon", weaponId, "up")
            Wait(250)
            local weapons = TriggerServerCallback("core:jobArmory:getWeapons", armoryId)
            StaffMenu.currentJobArmoryWeaponsList = weapons or {}
            if StaffMenu.builderJobArmoryWeaponEdit.refresh then
                StaffMenu.builderJobArmoryWeaponEdit.refresh()
            end
        end)

    StaffMenu.builderJobArmoryWeaponEdit.Button("DESCENDRE",
        canDown and ("Position " .. currentIdx .. "/" .. total .. " -> " .. (currentIdx + 1) .. "/" .. total) or "Déjà en dernière position",
        nil, "arrow", not canDown,
        function()
            if not canDown then return end
            TriggerServerEvent("core:jobArmory:reorderWeapon", weaponId, "down")
            Wait(250)
            local weapons = TriggerServerCallback("core:jobArmory:getWeapons", armoryId)
            StaffMenu.currentJobArmoryWeaponsList = weapons or {}
            if StaffMenu.builderJobArmoryWeaponEdit.refresh then
                StaffMenu.builderJobArmoryWeaponEdit.refresh()
            end
        end)

    StaffMenu.builderJobArmoryWeaponEdit.Separator("ACTIONS")

    StaffMenu.builderJobArmoryWeaponEdit.Button("SUPPRIMER L'ARME",
        "Supprimer définitivement cette arme", nil, "trash", false,
        function()
            TriggerServerEvent("core:jobArmory:deleteWeapon", weaponId)
            Wait(500)
            local armoryId = StaffMenu.currentJobArmoryWeaponsId
            local weapons = TriggerServerCallback("core:jobArmory:getWeapons", armoryId)
            StaffMenu.currentJobArmoryWeaponsList = weapons or {}
            StaffMenu.builderJobArmoryWeaponEdit.close()
            StaffMenu.builderJobArmoryWeaponEdit.parent.open()
        end)
end

function StaffMenu.BuildJobArmoryWeaponJobSelectMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeaponJobSelect then return end

    local armoryData = StaffMenu.currentJobArmoryData
    if not armoryData or not armoryData.jobs then return end

    StaffMenu.builderJobArmoryWeaponJobSelect.Separator("SÉLECTIONNER UN JOB")

    local allowedGrades = currentWeaponBuild.allowed_grades

    for _, jobName in ipairs(armoryData.jobs) do
        local jobLabel = armoryData.jobLabels and armoryData.jobLabels[jobName] or jobName
        local jobGrades = allowedGrades[jobName]
        local gradesCount = 0
        if jobGrades and type(jobGrades) == "table" then
            for _ in pairs(jobGrades) do gradesCount = gradesCount + 1 end
        end
        StaffMenu.builderJobArmoryWeaponJobSelect.Button(
            jobLabel,
            gradesCount .. " grade" .. (gradesCount > 1 and "s" or "") .. " autorisé" .. (gradesCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                StaffMenu.currentJobArmorySelectedJobForGrades = jobName
                local grades = TriggerServerCallback("core:jobArmory:getJobGrades", jobName)
                StaffMenu.currentJobArmoryJobGrades = grades or {}
            end,
            StaffMenu.builderJobArmoryWeaponGrades
        )
    end
end

function StaffMenu.BuildJobArmoryWeaponJobSelectEditMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeaponJobSelectEdit then return end

    local armoryData = StaffMenu.currentJobArmoryData
    if not armoryData or not armoryData.jobs then return end

    StaffMenu.builderJobArmoryWeaponJobSelectEdit.Separator("SÉLECTIONNER UN JOB")

    local w = StaffMenu.currentJobArmoryWeaponData
    local allowedGrades = w and w.allowed_grades or {}

    for _, jobName in ipairs(armoryData.jobs) do
        local jobLabel = armoryData.jobLabels and armoryData.jobLabels[jobName] or jobName
        local jobGrades = allowedGrades[jobName]
        local gradesCount = 0
        if jobGrades and type(jobGrades) == "table" then
            for _ in pairs(jobGrades) do gradesCount = gradesCount + 1 end
        end
        StaffMenu.builderJobArmoryWeaponJobSelectEdit.Button(
            jobLabel,
            gradesCount .. " grade" .. (gradesCount > 1 and "s" or "") .. " autorisé" .. (gradesCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                StaffMenu.currentJobArmorySelectedJobForGrades = jobName
                local grades = TriggerServerCallback("core:jobArmory:getJobGrades", jobName)
                StaffMenu.currentJobArmoryJobGrades = grades or {}
            end,
            StaffMenu.builderJobArmoryWeaponGrades
        )
    end
end

function StaffMenu.BuildJobArmoryWeaponGradesMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryWeaponGrades then return end

    local grades = StaffMenu.currentJobArmoryJobGrades or {}
    local mode = StaffMenu.currentJobArmoryGradesMode or "add"
  local selectedJob = StaffMenu.currentJobArmorySelectedJobForGrades

    if not selectedJob then return end

    local allowedGrades
    if mode == "edit" then
        local w = StaffMenu.currentJobArmoryWeaponData
        allowedGrades = w and w.allowed_grades or {}
    else
        allowedGrades = currentWeaponBuild.allowed_grades
    end

    local jobLabel = selectedJob
    local armoryData = StaffMenu.currentJobArmoryData
    if armoryData and armoryData.jobLabels then
        jobLabel = armoryData.jobLabels[selectedJob] or selectedJob
    end

    StaffMenu.builderJobArmoryWeaponGrades.Separator("GRADES - " .. jobLabel)

    if #grades == 0 then
        StaffMenu.builderJobArmoryWeaponGrades.Button("Aucun grade trouvé",
            "Vérifiez que le job est valide", nil, "empty", true, function() end)
        return
    end

    for _, gradeInfo in ipairs(grades) do
        local allowed = isGradeInList(allowedGrades, selectedJob, gradeInfo.grade)
        local currentMax = getGradeMax(allowedGrades, selectedJob, gradeInfo.grade)
        local desc = allowed and ("Max par joueur: " .. currentMax) or "Grade " .. gradeInfo.grade
        StaffMenu.builderJobArmoryWeaponGrades.Button(
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
                    local w = StaffMenu.currentJobArmoryWeaponData
                    if w then
                        w.allowed_grades = allowedGrades
                        TriggerServerEvent("core:jobArmory:updateWeapon", w.id, "allowed_grades", allowedGrades)
                    end
                else
                    currentWeaponBuild.allowed_grades = allowedGrades
                end

                if StaffMenu.builderJobArmoryWeaponGrades.refresh then
                    StaffMenu.builderJobArmoryWeaponGrades.refresh()
                end
            end
        )
    end
end

if StaffMenu and StaffMenu.builderJobArmory and StaffMenu.builderJobArmory.OnOpen then
    StaffMenu.builderJobArmory.OnOpen(function()
        StaffMenu.BuildJobArmoryMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryCreate then
    if StaffMenu.builderJobArmoryCreate.OnOpen then
        StaffMenu.builderJobArmoryCreate.OnOpen(function()
            StaffMenu.BuildJobArmoryCreateMenu()
            if currentBuild.position or currentBuild.npcPosition then
                startMarkerThread()
            end
        end)
    end
    if StaffMenu.builderJobArmoryCreate.OnClose then
        StaffMenu.builderJobArmoryCreate.OnClose(function()
            stopMarkerThread()
        end)
    end
end

if StaffMenu and StaffMenu.builderJobArmoryJobs and StaffMenu.builderJobArmoryJobs.OnOpen then
    StaffMenu.builderJobArmoryJobs.OnOpen(function()
        if not cachedAllJobs then
            cachedAllJobs = TriggerServerCallback("core:jobArmory:getAllJobs") or {}
        end
        StaffMenu.BuildJobArmoryJobsMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryManage and StaffMenu.builderJobArmoryManage.OnOpen then
    StaffMenu.builderJobArmoryManage.OnOpen(function()
        local armories = TriggerServerCallback("core:jobArmory:getArmories")
        StaffMenu.currentJobArmories = armories or {}
        StaffMenu.BuildJobArmoryManageMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryEdit and StaffMenu.builderJobArmoryEdit.OnOpen then
    StaffMenu.builderJobArmoryEdit.OnOpen(function()
        StaffMenu.BuildJobArmoryEditMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryEditJobs and StaffMenu.builderJobArmoryEditJobs.OnOpen then
    StaffMenu.builderJobArmoryEditJobs.OnOpen(function()
        if not cachedAllJobs then
            cachedAllJobs = TriggerServerCallback("core:jobArmory:getAllJobs") or {}
        end
        StaffMenu.BuildJobArmoryEditJobsMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeapons and StaffMenu.builderJobArmoryWeapons.OnOpen then
    StaffMenu.builderJobArmoryWeapons.OnOpen(function()
        local armoryId = StaffMenu.currentJobArmoryWeaponsId
        if armoryId then
            local weapons = TriggerServerCallback("core:jobArmory:getWeapons", armoryId)
            StaffMenu.currentJobArmoryWeaponsList = weapons or {}
        end
        StaffMenu.BuildJobArmoryWeaponsMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeaponAdd and StaffMenu.builderJobArmoryWeaponAdd.OnOpen then
    StaffMenu.builderJobArmoryWeaponAdd.OnOpen(function()
        StaffMenu.BuildJobArmoryWeaponAddMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeaponEdit and StaffMenu.builderJobArmoryWeaponEdit.OnOpen then
    StaffMenu.builderJobArmoryWeaponEdit.OnOpen(function()
        StaffMenu.BuildJobArmoryWeaponEditMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeaponItemSelect and StaffMenu.builderJobArmoryWeaponItemSelect.OnOpen then
    StaffMenu.builderJobArmoryWeaponItemSelect.OnOpen(function()
        StaffMenu.BuildJobArmoryWeaponItemSelectMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeaponJobSelect and StaffMenu.builderJobArmoryWeaponJobSelect.OnOpen then
    StaffMenu.builderJobArmoryWeaponJobSelect.OnOpen(function()
        StaffMenu.BuildJobArmoryWeaponJobSelectMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeaponJobSelectEdit and StaffMenu.builderJobArmoryWeaponJobSelectEdit.OnOpen then
    StaffMenu.builderJobArmoryWeaponJobSelectEdit.OnOpen(function()
        StaffMenu.BuildJobArmoryWeaponJobSelectEditMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryWeaponGrades and StaffMenu.builderJobArmoryWeaponGrades.OnOpen then
    StaffMenu.builderJobArmoryWeaponGrades.OnOpen(function()
        local selectedJob = StaffMenu.currentJobArmorySelectedJobForGrades
        if selectedJob then
            local grades = TriggerServerCallback("core:jobArmory:getJobGrades", selectedJob)
            StaffMenu.currentJobArmoryJobGrades = grades or {}
        end
        StaffMenu.BuildJobArmoryWeaponGradesMenu()
    end)
end

function StaffMenu.BuildJobArmoryLogsJobSelectMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryLogsJobSelect then return end

    local data = StaffMenu.currentJobArmoryData
    local id = StaffMenu.currentJobArmoryId
    if not data or not id then return end

    if not data.logsAllowedGrades then data.logsAllowedGrades = {} end

    StaffMenu.builderJobArmoryLogsJobSelect.Separator("ACCÈS HISTORIQUE PAR GRADE")

    StaffMenu.builderJobArmoryLogsJobSelect.Button("RÉINITIALISER",
        "Supprimer toutes les restrictions (tous les grades pourront voir)", nil, "trash", false,
        function()
            data.logsAllowedGrades = {}
            TriggerServerEvent("core:jobArmory:update", id, "logsAllowedGrades", {})
            if StaffMenu.builderJobArmoryLogsJobSelect.refresh then
                StaffMenu.builderJobArmoryLogsJobSelect.refresh()
            end
        end)

    StaffMenu.builderJobArmoryLogsJobSelect.Separator("SÉLECTIONNER UN JOB")

    local jobs = data.jobs or {}
    if #jobs == 0 then
        StaffMenu.builderJobArmoryLogsJobSelect.Button("Aucun job configuré", nil, nil, "empty", true, function() end)
        return
    end

    for _, jobName in ipairs(jobs) do
        local jobLabel = data.jobLabels and data.jobLabels[jobName] or jobName
        local jobGrades = data.logsAllowedGrades[jobName]
        local gradesCount = 0
        if jobGrades and type(jobGrades) == "table" then
            for _ in pairs(jobGrades) do gradesCount = gradesCount + 1 end
        end
        StaffMenu.builderJobArmoryLogsJobSelect.Button(
            jobLabel,
            gradesCount .. " grade" .. (gradesCount > 1 and "s" or "") .. " autorisé" .. (gradesCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                StaffMenu.currentJobArmoryLogsSelectedJob = jobName
                local grades = TriggerServerCallback("core:jobArmory:getJobGrades", jobName)
                StaffMenu.currentJobArmoryLogsJobGrades = grades or {}
            end,
            StaffMenu.builderJobArmoryLogsGrades
        )
    end
end

function StaffMenu.BuildJobArmoryLogsGradesMenu()
    if not StaffMenu or not StaffMenu.builderJobArmoryLogsGrades then return end

    local data = StaffMenu.currentJobArmoryData
    local id = StaffMenu.currentJobArmoryId
    local selectedJob = StaffMenu.currentJobArmoryLogsSelectedJob
    local grades = StaffMenu.currentJobArmoryLogsJobGrades or {}
    if not data or not id or not selectedJob then return end

    if not data.logsAllowedGrades then data.logsAllowedGrades = {} end

    local jobLabel = data.jobLabels and data.jobLabels[selectedJob] or selectedJob
    StaffMenu.builderJobArmoryLogsGrades.Separator("GRADES LOGS - " .. jobLabel)

    if #grades == 0 then
        StaffMenu.builderJobArmoryLogsGrades.Button("Aucun grade trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, gradeInfo in ipairs(grades) do
        local allowed = isGradeInList(data.logsAllowedGrades, selectedJob, gradeInfo.grade)
        StaffMenu.builderJobArmoryLogsGrades.Button(
            gradeInfo.label,
            "Grade " .. gradeInfo.grade,
            nil,
            allowed and "check" or "empty",
            false,
            function()
                toggleGradeInList(data.logsAllowedGrades, selectedJob, gradeInfo.grade)
                TriggerServerEvent("core:jobArmory:update", id, "logsAllowedGrades", data.logsAllowedGrades)
                if StaffMenu.builderJobArmoryLogsGrades.refresh then
                    StaffMenu.builderJobArmoryLogsGrades.refresh()
                end
            end
        )
    end
end

if StaffMenu and StaffMenu.builderJobArmoryLogsJobSelect and StaffMenu.builderJobArmoryLogsJobSelect.OnOpen then
    StaffMenu.builderJobArmoryLogsJobSelect.OnOpen(function()
        StaffMenu.BuildJobArmoryLogsJobSelectMenu()
    end)
end

if StaffMenu and StaffMenu.builderJobArmoryLogsGrades and StaffMenu.builderJobArmoryLogsGrades.OnOpen then
    StaffMenu.builderJobArmoryLogsGrades.OnOpen(function()
        local selectedJob = StaffMenu.currentJobArmoryLogsSelectedJob
        if selectedJob then
            local grades = TriggerServerCallback("core:jobArmory:getJobGrades", selectedJob)
            StaffMenu.currentJobArmoryLogsJobGrades = grades or {}
        end
        StaffMenu.BuildJobArmoryLogsGradesMenu()
    end)
end
