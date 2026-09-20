local bossPanelModule = {
    isOpen = false,
    announceContext = nil,
}

local function playerCanEditAnnounces()
    local job = VFW.PlayerData and VFW.PlayerData.job
    if not job then return false end
    if job.grade_is_boss == true or job.grade_is_boss == 1 or job.grade_is_boss == "1" then return true end
    local gradeNum = tonumber(job.grade)
    if gradeNum == 98 or gradeNum == 99 then return true end

    local name = string.lower(tostring(job.grade_name or ""))
    local label = string.lower(tostring(job.grade_label or ""))
    if name == "boss" or name == "patron" or name == "owner" or name == "pdg" then return true end
    if label:find("patron", 1, true) or label:find("boss", 1, true) or label == "pdg" then return true end

    if bossPanelModule.isOpen then return true end
    return false
end

local function attachAnnounceTab()
    if not bossPanelModule.announceContext then
        SendNUIMessage({ action = "bossAnnounces:close" })
        return
    end
    SendNUIMessage({
        action = "bossAnnounces:attach",
        data = bossPanelModule.announceContext,
    })
end

local RESTAURANT_MAPPING = {
    burgershot = { getLogsCallback = "burgershot:delivery:getLogs", clearCallback = "bossPanel:clearBurgerShotLogs" },
    pizzeria = { getLogsCallback = "pizzeria:delivery:getLogs", clearCallback = "bossPanel:clearPizzeriaLogs" },
    pearls = { getLogsCallback = "pearls:delivery:getLogs", clearCallback = "bossPanel:clearPearlsLogs" },
    noodle = { getLogsCallback = "noodle:delivery:getLogs", clearCallback = "bossPanel:clearNoodleLogs" },
    bean_coffee = { getLogsCallback = "bean_coffee:delivery:getLogs", clearCallback = "bossPanel:clearBeanCoffeeLogs" },
    uwu_cafe = { getLogsCallback = "uwu_cafe:delivery:getLogs", clearCallback = "bossPanel:clearUwuCafeLogs" },
}

local function getRestaurantConfig(jobName)
    for prefix, config in pairs(RESTAURANT_MAPPING) do
        if string.find(jobName, "^" .. prefix) then
            return config
        end
    end
    return nil
end

local BASE_PERMISSIONS = {
    { name = "recruit", label = "Recruter" },
    { name = "promote", label = "Promouvoir" },
    { name = "accounting", label = "Comptabilité" },
    { name = "kick", label = "Virer" },
    { name = "announce", label = "Annonce" },
    { name = "manage_permissions", label = "Gérer les permissions" },
    { name = "demote", label = "Rétrograder" },
    { name = "custom", label = "Personnalisé", requireCustomAnnounce = true },
    { name = "manage_chest", label = "Gérer les coffres" },
    { name = "view_logs", label = "Voir les logs"},
    { name = "manage_locker", label = "Gérer les casiers", requiresLockers = true },
    { name = "manage_services", label = "Gérer les services" },
    -- Gouvernement specific permissions
    { name = "liaison_gouv", label = "Liaison Gouv" },
    { name = "gouvernement_tablet", label = "Tablette Gouvernement", jobOnly = "gouvernement" },
    { name = "gouvernement_settings", label = "Paramètres Gouvernement", jobOnly = "gouvernement" },
    { name = "security_actions", label = "Actions de sécurité", jobOnly = "gouvernement" },
    { name = "create_invoice", label = "Créer une facture", jobOnly = "gouvernement" },
    { name = "create_invoice_company", label = "Facture entreprise", jobOnly = "gouvernement" }
}

local function getGradeFromRank(grades, rank)
    for _, grade in pairs(grades) do
        if grade.grade == rank then
            return grade
        end
    end
    return nil
end

local function getBasePermissionByName(name)
    for _, perm in ipairs(BASE_PERMISSIONS) do
        if perm.name == name then
            return perm
        end
    end
    return nil
end

local formatDescription = function(items)
    local desc = ""
    for i = 1, #items do
        desc = desc .. items[i].name .. "\n"
    end
    return desc
end

function bossPanelModule.openBossPanel()

    local playerData = VFW.PlayerData
    local job = playerData.job


    -- Get employees from server

    local employees = TriggerServerCallback("core:jobs:getMembers", job.name)


    local employeesServices = TriggerServerCallback("core:jobs:getMembersServices", job.name)

    local jobData, societyData, membersFavoris, customData = TriggerServerCallback("core:jobs:getJob", job.name)

    local chests = TriggerServerCallback("vfw:chest:getByGroup", job.name) or {}

    local lockers = TriggerServerCallback("core:societyLockers:getByJob", job.name)

    local isFarmingJob, farmingLogs, isTaxiJob = TriggerServerCallback("core:farm:getLogs", job.name)

    local isLTDJob, ltdLogs = TriggerServerCallback("fl_ltd:getLogs", job.name)

    local restaurantConfig = getRestaurantConfig(job.name)
    local restaurantLogs = nil
    if restaurantConfig then
        local _, logs = TriggerServerCallback(restaurantConfig.getLogsCallback, job.name)
        restaurantLogs = logs
    end

    if employees == nil then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Erreur lors de la récupération des employés. Veuillez réessayer plus tard."
        })
        return
    end

    local formattedEmployees = {}
    local playerIdCounter = 1

    -- Format job roles/grades
    local roles = {}
    local permissions = {}


    -- Create roles with permissions

    for _, roleData in pairs(jobData.grades) do

        local rolePermissions = {}

        local isBossOrCopatron = roleData.is_boss == 1 or roleData.is_boss == true

        if isBossOrCopatron then
            -- Boss/copatron: grant all available permissions (matches UI visual behavior)
            for _, perm in ipairs(BASE_PERMISSIONS) do
                if (not perm.jobOnly or perm.jobOnly == job.name)
                    and (not perm.requireCustomAnnounce or (customData and customData.allowCustomAnnouncement)) then
                    rolePermissions[#rolePermissions + 1] = {
                        name = perm.name,
                        label = perm.label
                    }
                end
            end
        else
            local gradeJobData = jobData.perms[roleData.name]
            if gradeJobData then
                for perm, isEnable in pairs(gradeJobData) do
                    local basePerm = getBasePermissionByName(perm)
                    if basePerm and isEnable then
                        rolePermissions[#rolePermissions + 1] = {
                            name = perm,
                            label = basePerm.label
                        }
                    end
                end
            end
        end

        table.insert(roles, {
            name = roleData.name,
            label = roleData.label,
            grade = roleData.grade,
            salary = roleData.salary,
            isBoss = isBossOrCopatron,
            permissions = rolePermissions
        })
    end

    table.sort(roles, function(a, b)
        return a.grade < b.grade
    end)

    local getCurrentPermissionOfRole = function(name)
        for _, role in ipairs(roles) do
            if role.name == name then
                return role.permissions or {}
            end
        end
        return {}
    end

    local currentPlayer = nil

    if employees then
        for _, employee in ipairs(employees) do

            local jobGradeInfo = getGradeFromRank(jobData.grades, employee.rank - 1)

            if jobGradeInfo then
                -- Check if employee is in favorites
                local isFavorite = false
                if membersFavoris then
                    for _, favId in ipairs(membersFavoris) do
                        if favId == employee.identifier then
                            isFavorite = true
                            break
                        end
                    end
                end

                local isBossGrade = jobGradeInfo.is_boss == 1 or jobGradeInfo.is_boss == true

                local employeeData = {
                    id = employee.identifier,
                    firstname = employee.fname,
                    lastname = employee.lname,

                    onDuty = employee.Information.onDuty,
                    mugshot = employee.Information.mugshot,
                    role = {
                        name = jobGradeInfo.name or "",
                        label = jobGradeInfo.label or "",
                        salary = jobGradeInfo.salary or 0,
                        grade = jobGradeInfo.grade or 0,
                        isBoss = isBossGrade,
                        permissions = getCurrentPermissionOfRole(jobGradeInfo.name) or {}
                    },
                    serviceStart = employeesServices[employee.identifier] and employeesServices[employee.identifier]
                                                                                                        .time or 0,
                    serviceStop = employeesServices[employee.identifier] and
                            employeesServices[employee.identifier].stopTime or 0,
                    totalWeek = employeesServices[employee.identifier] and
                            employeesServices[employee.identifier].totalWeek or 0,
                    totalLastWeek = employeesServices[employee.identifier] and
                            employeesServices[employee.identifier].totalLastWeek or 0,
                    timeInService = employeesServices[employee.identifier] and
                            employeesServices[employee.identifier].timeInService or 0,
                    isFavorite = isFavorite,
                    startDate = employee.startDate,
                    phoneNumber = employee.phoneNumber or "",
                }

                table.insert(formattedEmployees, employeeData)
                playerIdCounter = playerIdCounter + 1

                if employee.identifier == playerData.identifier then
                    currentPlayer = employeeData
                end
            end
        end
    end

    -- All available permissions (filter by jobOnly, requireCustomAnnounce, requiresLockers)
    local hasLockers = lockers and #lockers > 0
    permissions = {}
    for _, perm in ipairs(BASE_PERMISSIONS) do
        if (not perm.jobOnly or perm.jobOnly == job.name)
            and (not perm.requireCustomAnnounce or (customData and customData.allowCustomAnnouncement))
            and (not perm.requiresLockers or hasLockers) then
            permissions[#permissions + 1] = { name = perm.name, label = perm.label }
        end
    end

    -- Create dummy data for invoices
    local invoices = TriggerServerCallback("core:jobs:getBillings")

    local items = {}

    for _, invoice in ipairs(invoices.billings or {}) do
        items[#items + 1] = {
            id = invoice.id,
            issuedBy = invoice.sender or "Unknown",
            issuedTo = invoice.receiver or "Unknown",
            date = invoice.date,
            amount = invoice.total or 0,
            baseCost = invoice.base_cost, -- coût pièces côté mécano (nil pour autres factures)
            status = invoice.type == "deposit" and "received" or invoice.type == "withdraw" and "paid" or invoice.statut == 2 and "paid later" or invoice.statut == 1 and "paid" or "unpaid",
            description = formatDescription(json.decode(invoice.items)),
            type = invoice.type
        }
    end

    -- Create dummy data for revenue and expenses (array of numbers for charts)
    local revenue = { 1500, 2300, 1800, 2500, 3000, 2800, 3200 }
    local expenses = { 800, 1200, 900, 1100, 1500, 1300, 1600 }

    local liaisonUnreadCount = TriggerServerCallback("liaison:getUnreadCount") or 0

    local data = {
        company = {
            label = job.label or "",
            name = job.name or "",
            image = jobData.image or "",
            employees = formattedEmployees,
            roles = roles,
            permissions = permissions,
            invoices = items or {},
            balance = societyData.money,
            revenue = revenue,
            expenses = expenses,
            chests = chests,
            lockers = lockers or {},
            farming = isFarmingJob and {logs = farmingLogs, isFarmingJob = isFarmingJob, isTaxiJob = isTaxiJob or false} or {},
            weazelPerms = customData and customData.weazelPerms or {create = 0, edit = 0, schedule = 0, delete = 0, broadcast = 0},
            lifeinvaderPerms = customData and customData.lifeinvaderPerms or {create = 0, edit = 0, schedule = 0, delete = 0, broadcast = 0},
            ltd = isLTDJob and {logs = ltdLogs, isLTDJob = isLTDJob} or {},
            restaurant = restaurantConfig and {logs = restaurantLogs or {}, isRestaurantJob = true, clearCallback = restaurantConfig.clearCallback} or {}
        },
        player = currentPlayer,
        liaisonUnreadCount = liaisonUnreadCount,
    }
    VFW.Nui.HudVisible(false)

    SendNUIMessage({
        action = "bossPanel:open",
        data = data
    })

    bossPanelModule.isOpen = true

    local announces = TriggerServerCallback("core:jobs:getAnnounces", job.name)
    if type(announces) ~= "table" then
        announces = {
            company = job.label or "",
            image = (jobData and jobData.image) or "",
            banner = (jobData and jobData.banner) or "",
            announceTitleColor = "#FFFFFF",
            announceSubtitle = "",
            openMessage = "",
            closeMessage = "",
            allowCustomAnnouncement = false,
            customTitleColor = "#FFFFFF",
            customSubtitle = "",
        }
    end
    announces.company = announces.company or job.label or ""
    announces.image = announces.image or (jobData and jobData.image) or ""
    announces.banner = announces.banner or (jobData and jobData.banner) or ""
    bossPanelModule.announceContext = announces
    attachAnnounceTab()

    VFW.Nui.Focus(true, false)

    CreateThread(function()
        if not bossPanelModule.isOpen then
            return
        end

        local plyPed = PlayerPedId()
        local dict = "amb@world_human_seat_wall_tablet@female@base"
        local anim = "base"
        local propModel = "prop_cs_tablet"
        local boneIndex = 28422

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end

        RequestModel(propModel)
        while not HasModelLoaded(propModel) do
            Wait(10)
        end

        local tabletProp = CreateObject(GetHashKey(propModel), 0.0, 0.0, 0.0, false, true, false)

        AttachEntityToEntity(tabletProp, plyPed, GetPedBoneIndex(plyPed, boneIndex),
                -0.01, 0.0, 0.0, -- Position relative
                0.0, 0.0, 0.0, -- Rotation
                true, true, false, true, 1, true
        )

        TaskPlayAnim(plyPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

        while bossPanelModule.isOpen do
            if not IsEntityPlayingAnim(plyPed, dict, anim, 3) then
                TaskPlayAnim(plyPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Wait(500)
        end

        ClearPedTasks(plyPed)
        if DoesEntityExist(tabletProp) then
            DeleteEntity(tabletProp)
        end
    end)
end

function bossPanelModule.closeBossPanel()
    VFW.Nui.Focus(false, false)
    VFW.Nui.HudVisible(true)

    bossPanelModule.isOpen = false
    bossPanelModule.announceContext = nil
    SendNUIMessage({ action = "bossAnnounces:close" })
end

-- Close boss panel when duty changes and sync client state
RegisterNetEvent("vfw:client:changeDuty", function(state)
    -- Synchroniser l'état du service côté client
    if VFW.PlayerData and VFW.PlayerData.job then
        VFW.PlayerData.job.onDuty = state
    end
    if Society and Society.data then
        Society.data.service = state
    end

    if bossPanelModule.isOpen then
        bossPanelModule.closeBossPanel()
        SendNUIMessage({
            action = "bossPanel:close"
        })
    end
end)

-- Close boss panel after successful recruitment
RegisterNetEvent("boss:closePanelAfterRecruit", function()
    if bossPanelModule.isOpen then
        bossPanelModule.closeBossPanel()
        SendNUIMessage({
            action = "bossPanel:close"
        })
    end

    -- Play success animation for recruiter
    local ped = PlayerPedId()
    RequestAnimDict("mp_player_int_upperthumbsup")
    while not HasAnimDictLoaded("mp_player_int_upperthumbsup") do
        Wait(10)
    end
    TaskPlayAnim(ped, "mp_player_int_upperthumbsup", "mp_player_int_thumbs_up", 8.0, -8.0, 2000, 48, 0, false, false,
            false)
end)

-- NUI CALLBACKS

RegisterNUICallback("bossPanel:close", function(_, cb)
    bossPanelModule.closeBossPanel()
    cb({})
end)

RegisterNUICallback("bossPanel:announces:open", function(_, cb)
    if not bossPanelModule.isOpen then
        cb({ ok = false, error = "Panel fermé." })
        return
    end

    local announces = bossPanelModule.announceContext
    if type(announces) ~= "table" then
        local jobName = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name
        announces = TriggerServerCallback("core:jobs:getAnnounces", jobName)
    end
    if type(announces) ~= "table" then
        local job = VFW.PlayerData and VFW.PlayerData.job
        announces = {
            company = job and job.label or "",
            image = "",
            banner = "",
            announceTitleColor = "#FFFFFF",
            announceSubtitle = "",
            openMessage = "",
            closeMessage = "",
            allowCustomAnnouncement = false,
            customTitleColor = "#FFFFFF",
            customSubtitle = "",
        }
    end

    SendNUIMessage({
        action = "bossAnnounces:open",
        data = announces,
    })
    cb({ ok = true, announces = announces })
end)

RegisterNUICallback("bossPanel:announces:hide", function(_, cb)
    if bossPanelModule.isOpen then
        attachAnnounceTab()
    else
        SendNUIMessage({ action = "bossAnnounces:close" })
    end
    cb({ ok = true })
end)

RegisterNUICallback("bossPanel:announces:save", function(data, cb)
    if not bossPanelModule.isOpen then
        cb({ ok = false, error = "Panel fermé." })
        return
    end

    local ok, message, announces = TriggerServerCallback("core:jobs:saveAnnounces", data or {})
    if not ok then
        cb({ ok = false, error = message or "Enregistrement impossible." })
        return
    end

    if type(announces) == "table" then
        bossPanelModule.announceContext = announces
        SendNUIMessage({
            action = "bossAnnounces:open",
            data = announces,
        })
    end
    cb({ ok = true, message = message, announces = announces })
end)



-- Get invoices with pagination
RegisterNUICallback("boss:getInvoices", function(data, cb)
    local page = data.page or 1
    local pageSize = data.pageSize or 10

    -- Server call to get invoices
    local playerData = VFW.PlayerData
    local invoices = TriggerServerCallback("core:jobs:getBillings", {
        jobName = playerData.job.name,
        page = page,
        pageSize = pageSize
    })

    local items = {}

    for _, invoice in ipairs(invoices.billings or {}) do
        items[#items + 1] = {
            id = invoice.id,
            issuedBy = invoice.sender or "Unknown",
            issuedTo = invoice.receiver or "Unknown",
            date = invoice.date,
            amount = invoice.total or 0,
            baseCost = invoice.base_cost, -- coût pièces côté mécano (nil pour autres factures)
            status = invoice.type == "deposit" and "received" or invoice.type == "withdraw" and "paid" or invoice.statut == 2 and "paid later" or invoice.statut == 1 and "paid" or "unpaid",
            description = formatDescription(json.decode(invoice.items)),
            type = invoice.type
        }
    end

    if invoices then
        cb({
            items = items or {},
            total = invoices.total or 0
        })
    else
        cb({
            items = {},
            total = 0
        })
    end
end)

-- Update employee
RegisterNUICallback("bossPanel:updateEmployee", function(data, cb)
    local employeeId = data.employeeId
    local patch = data.patch

    if not employeeId or not patch then
        cb({
            ok = false,
            message = "Données manquantes"
        })
        return
    end

    local result, message = TriggerServerCallback("core:jobs:updateEmployee", employeeId, patch)

    cb({
        ok = result,
        message = message
    })
end)

RegisterNUICallback("bossPanel:deleteRole", function(data, cb)
    local result, message = TriggerServerCallback("core:jobs:deleteRole", data.role)

    cb({
        ok = result,
        message = message
    })
end)

RegisterNUICallback("bossPanel:addRole", function(data, cb)
    local role = data.role

    if not role then
        cb({
            ok = false,
            message = "Données du rôle manquantes"
        })
        return
    end

    local playerData = VFW.PlayerData
    local result, message = TriggerServerCallback("core:jobs:addRole", {
        jobName = playerData.job.name,
        role = role
    })

    cb({
        ok = result,
        message = message
    })
end)

RegisterNUICallback("bossPanel:updateRole", function(data, cb)
    local role = data.role

    if not role then
        cb({
            ok = false,
            message = "Données du rôle manquantes"
        })
        return
    end

    -- Server call to update role
    local playerData = VFW.PlayerData
    local result, message = TriggerServerCallback("core:jobs:updateRole", {
        jobName = playerData.job.name,
        role = role
    })

    cb({
        ok = result,
        message = message
    })
end)

RegisterNUICallback("bossPanel:reorderGrades", function(data, cb)
    local gradeA = data.gradeA
    local gradeB = data.gradeB

    if gradeA == nil or gradeB == nil then
        cb({
            ok = false,
            message = "Grades manquants"
        })
        return
    end

    local playerData = VFW.PlayerData
    local result, message = TriggerServerCallback("core:jobs:reorderGrades", {
        jobName = playerData.job.name,
        gradeA = gradeA,
        gradeB = gradeB
    })

    cb({
        ok = result,
        message = message
    })
end)

RegisterNUICallback("bossPanel:fireEmployee", function(data, cb)
    local employee = data.employee

    if not employee then
        cb({
            ok = false,
            message = "Données de l'employé manquantes"
        })
        return
    end

    -- Server call to fire employee
    local playerData = VFW.PlayerData
    local result, message = TriggerServerCallback("core:jobs:fireEmployee", employee.id)

    if result then
        cb({
            ok = true,
            message = "Employé licencié"
        })
    else
        cb({
            ok = false,
            message = message and message or "Erreur lors du licenciement de l'employé"
        })
    end
end)

RegisterNetEvent("core:jobs:updateBossPanel", function()
    if not bossPanelModule.isOpen then
        return
    end

    bossPanelModule.openBossPanel()
end)

-- Bank management callbacks
RegisterNUICallback("boss:depositMoney", function(data, cb)
    local amount = data.amount
    local jobName = data.jobName

    if not amount or amount <= 0 then
        cb({
            success = false,
            message = "Ce montant n'est pas valide"
        })
        return
    end

    -- Server call to deposit money
    local result, message, newBalance = TriggerServerCallback("core:boss:depositMoney", {
        amount = amount,
        jobName = jobName
    })

    if result then
        ---- Update the UI with the new balance
        --SendNUIMessage({
        --    action = "bossPanel:updateBalance",
        --    data = {
        --        balance = newBalance
        --    }
        --})

        cb({
            success = true,
            message = "Dépôt effectué"
        })
    else
        cb({
            success = false,
            message = message or "Erreur lors du dépôt"
        })
    end
end)

RegisterNUICallback("boss:withdrawMoney", function(data, cb)
    local amount = data.amount
    local jobName = data.jobName

    if not amount or amount <= 0 then
        cb({
            success = false,
            message = "Ce montant n'est pas valide"
        })
        return
    end

    -- Server call to withdraw money
    local result, message, newBalance = TriggerServerCallback("core:boss:withdrawMoney", {
        amount = amount,
        jobName = jobName
    })

    if result then
        -- Update the UI with the new balance
        --SendNUIMessage({
        --    action = "bossPanel:updateBalance",
        --    data = {
        --        balance = newBalance
        --    }
        --})

        cb({
            success = true,
            message = "Retrait effectué"
        })
    else
        cb({
            success = false,
            message = message or "Erreur lors du retrait"
        })
    end
end)

RegisterNUICallback("boss:transferToEmployee", function(data, cb)
    local targetIdentifier = data.targetIdentifier
    local amount = data.amount
    local targetName = data.targetName

    if not targetIdentifier or not amount or amount <= 0 then
        cb({
            success = false,
            message = "Les informations envoyées ne sont pas valides"
        })
        return
    end

    local result, message, newBalance = TriggerServerCallback("boss:transferToEmployee", {
        targetIdentifier = targetIdentifier,
        amount = amount,
        targetName = targetName
    })

    if result then
        cb({
            success = true,
            message = "Transfert effectué",
            newBalance = newBalance
        })
    else
        cb({
            success = false,
            message = message or "Erreur lors du transfert"
        })
    end
end)

RegisterNUICallback("bossPanel:updateChestAccess", function(data, cb)
    TriggerServerEvent("core:boss:updateChestAccess", data)
end)

RegisterNUICallback("bossPanel:updateWeazelPerm", function(data, cb)
    local result, message = TriggerServerCallback("core:jobs:updateWeazelPerm", data)
    cb({ ok = result, message = message })
end)

RegisterNUICallback("bossPanel:updateLifeInvaderPerm", function(data, cb)
    local result, message = TriggerServerCallback("core:jobs:updateLifeInvaderPerm", data)
    cb({ ok = result, message = message })
end)

RegisterNUICallback("nui:chest:history", function(data, cb)
    local history = TriggerServerCallback("core:chest:getHistory", data.chestId)
    cb({
        history = history
    })
end)

-- Callback pour récupérer les casiers des employés d'un casier spécifique
RegisterNUICallback("bossPanel:getLockerEmployees", function(data, cb)
    local lockerId = data.lockerId
    if not lockerId then
        cb({ employeeLockers = {} })
        return
    end

    local employeeLockers = TriggerServerCallback("core:societyLockers:getEmployeeLockers", lockerId)
    cb({
        employeeLockers = employeeLockers or {}
    })
end)

-- Callback pour récupérer l'historique d'un casier d'employé
RegisterNUICallback("bossPanel:getLockerHistory", function(data, cb)
    local chestId = data.chestId
    if not chestId then
        cb({ history = {} })
        return
    end

    local history = TriggerServerCallback("core:chest:getHistory", chestId)
    cb({
        history = history or {}
    })
end)

-- Callback pour récupérer les casiers archivés (employés virés)
RegisterNUICallback("bossPanel:getArchivedLockers", function(data, cb)
    local jobName = data.jobName
    if not jobName then
        cb({ archivedLockers = {} })
        return
    end

    local archivedLockers = TriggerServerCallback("core:societyLockers:getArchivedLockers", jobName)
    cb({
        archivedLockers = archivedLockers or {}
    })
end)

-- Callback pour supprimer un casier archivé
RegisterNUICallback("bossPanel:deleteArchivedLocker", function(data, cb)
    local archivedId = data.archivedId
    if not archivedId then
        cb({ success = false })
        return
    end

    local success, message = TriggerServerCallback("core:societyLockers:deleteArchivedLocker", archivedId)
    cb({
        success = success,
        message = message
    })
end)

-- Recruit player
RegisterNUICallback("bossPanel:recruitPlayer", function(data, cb)
    local role = data.role

    if not role then
        cb({
            ok = false,
            message = "Données du rôle manquantes"
        })
        return
    end

    -- Get closest player
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestPlayerId, closestPed, closestCoords = VFW.Game.GetClosestPlayer(coords, 2.0)

    if not closestPlayerId then
        cb({
            ok = false,
            message = "Aucun joueur à proximité (< 2m)"
        })
        return
    end

    local targetServerId = GetPlayerServerId(closestPlayerId)

    -- Play clipboard animation for recruiter
    RequestAnimDict("amb@world_human_clipboard@male@base")
    while not HasAnimDictLoaded("amb@world_human_clipboard@male@base") do
        Wait(10)
    end

    TaskPlayAnim(ped, "amb@world_human_clipboard@male@base", "base", 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Send to server
    local playerData = VFW.PlayerData
    local result, message = TriggerServerCallback("boss:proposeContract", {
        targetServerId = targetServerId,
        role = role,
        jobName = playerData.job.name,
        jobLabel = playerData.job.label
    })

    -- Stop animation after a bit
    Wait(2000)
    ClearPedTasks(ped)

    if result then
        SendNUIMessage({ action = "bossPanel:close" })
        bossPanelModule.closeBossPanel()

        cb({
            ok = true,
            message = "Offre de contrat envoyée"
        })
    else
        cb({
            ok = false,
            message = message or "Erreur lors de l'envoi de l'offre"
        })
    end
end)

-- Theme customization callbacks
VFW.BossPanel = bossPanelModule
