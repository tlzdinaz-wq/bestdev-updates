local GOUV_IMG = VFW.CDN.Get("entreprise/gouvernement.png")

local function gouvNotif(subtitle, content)
    VFW.ShowNotification({ type = "JOB", title = "Gouvernement", subtitle = subtitle, image = GOUV_IMG, content = content })
end

-- Ouvre la tablette gouvernementale avec toutes les permissions pour le staff
RegisterNetEvent("gouv:openTablet")
AddEventHandler("gouv:openTablet", function()
    -- Surcharge temporaire des permissions pour le staff
    local oldPermissions = VFW.PlayerData.job.permissions
    VFW.PlayerData.job.permissions = { all = true, staff = true, superadmin = true }
    -- Ouvre le panel gouvernemental en mode staff
    OpenGouvernementPanel(true)
    -- Restaure les permissions d'origine après 2 secondes (pour éviter les abus)
    CreateThread(function()
        Wait(2000)
        VFW.PlayerData.job.permissions = oldPermissions
    end)
end)

---@meta _
---@diagnostic disable: duplicate-doc-field

local isPanelOpen = false
local isPanelMinimized = false
local tabletProp = nil

-- Cleanup prop si la resource restart
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
    ClearPedTasks(PlayerPedId())
end)

local function toPermissionList(map)
    local list = {}
    if type(map) ~= "table" then return list end
    for name, enabled in pairs(map) do
        list[#list + 1] = { name = name, enabled = enabled == true }
    end
    return list
end

--- Open Gouvernement Panel (Tablette Taxes)
VFW.Nui.gouvernementPanel = function(visible, isStaff)
    if visible then
        local societies = TriggerServerCallback("gouvernement:getSocieties")
        local playerPermissions = TriggerServerCallback("gouvernement:getPlayerPermissions")

        local gouvLogo = GOUV_IMG

        local playerName = (VFW.PlayerData.firstName or "") .. " " .. (VFW.PlayerData.lastName or "")
        local playerGrade
        if isStaff then
            playerGrade = "Staff"
        else
            playerGrade = VFW.PlayerData.job.grade_label or VFW.PlayerData.job.grade
        end

        SendNUIMessage({
            action = "nui:GouvernementPanel:data",
            data = {
                job = VFW.PlayerData.job.name,
                societies = societies or {},
                playerGrade = playerGrade,
                playerName = playerName,
                playerMugshot = VFW.PlayerData.mugshot or "",
                permissions = toPermissionList(playerPermissions),
                logo = gouvLogo,
            }
        })
    end

    SendNUIMessage({
        action = "nui:GouvernementPanel:visible",
        data = visible
    })

    VFW.Nui.Focus(visible)
    isPanelOpen = visible

    -- Immediate prop/anim cleanup on close (don't rely solely on thread)
    if not visible then
        isPanelMinimized = false
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        if tabletProp and DoesEntityExist(tabletProp) then
            DeleteEntity(tabletProp)
            tabletProp = nil
        end
    end

    if visible then
        -- Boucle de desactivation des controles + minimize/restore (Espace)
        CreateThread(function()
            while isPanelOpen do
                if isPanelMinimized then
                    Wait(0)
                    -- Quand minimise, detecter Espace pour restaurer
                    if IsControlJustPressed(0, 22) then -- Space
                        isPanelMinimized = false
                        VFW.Nui.Focus(true)
                        SendNUIMessage({
                            action = "nui:GouvernementPanel:restore",
                            data = {}
                        })
                    end
                else
                    Wait(0)
                    DisableControlAction(0, 245, true) -- T (chat)
                end
            end
        end)

        -- Tablet prop + animation
        CreateThread(function()
            if not isPanelOpen then return end

            local ped = PlayerPedId()
            local dict = "amb@world_human_seat_wall_tablet@female@base"
            local anim = "base"
            local propModel = "prop_cs_tablet"

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do Wait(10) end

            RequestModel(propModel)
            while not HasModelLoaded(propModel) do Wait(10) end

            -- Si le panel a ete ferme pendant le chargement des assets, abort
            if not isPanelOpen then
                SetModelAsNoLongerNeeded(GetHashKey(propModel))
                RemoveAnimDict(dict)
                return
            end

            -- Supprimer l'ancien prop si un refresh en a cree un nouveau
            if tabletProp and DoesEntityExist(tabletProp) then
                DeleteEntity(tabletProp)
                tabletProp = nil
            end

            tabletProp = CreateObject(GetHashKey(propModel), 0.0, 0.0, 0.0, false, true, false)
            AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422),
                -0.01, 0.0, 0.0,
                0.0, 0.0, 0.0,
                true, true, false, true, 1, true
            )

            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

            while isPanelOpen do
                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
                Wait(500)
            end

            ClearPedTasks(ped)
            if tabletProp and DoesEntityExist(tabletProp) then
                DeleteEntity(tabletProp)
                tabletProp = nil
            end
        end)
    end
end

function OpenGouvernementPanel(isStaff)
    -- Vérifier la permission gouvernement_tablet avant d'ouvrir
    local hasTabletPerm = TriggerServerCallback("gouvernement:checkPerm", "gouvernement_tablet")

    if not hasTabletPerm then
        gouvNotif("Accès", "Vous n'avez pas accès à la tablette gouvernementale.")
        return
    end

    VFW.Nui.gouvernementPanel(true, isStaff)
end

RegisterNuiCallback("nui:closeGouvernementPanel", function()
    VFW.Nui.gouvernementPanel(false)
    isPanelOpen = false
    isPanelMinimized = false
    VFW.ClearPreview()
end)

-- Minimiser la tablette (garde l'animation/prop mais libere le NUI focus)
RegisterNuiCallback("nui:GouvernementPanel:minimize", function(_, cb)
    if isPanelOpen and not isPanelMinimized then
        isPanelMinimized = true
        VFW.Nui.Focus(false)
        SendNUIMessage({
            action = "nui:GouvernementPanel:minimized",
            data = {}
        })
    end
    cb("ok")
end)

-- Helper function to ensure data is decoded from JSON if needed
local function ensureDecoded(data)
    if data == nil or data == json.null then
        return nil
    end
    
    if type(data) == "string" then
        -- Only try to decode if it looks like JSON (starts with { or [)
        if string.sub(data, 1, 1) == "{" or string.sub(data, 1, 1) == "[" then
            local success, decoded = pcall(json.decode, data)
            if success then 
                return decoded 
            else
                return data
            end
        else
            -- It's a plain string, return as-is
            return data
        end
    end
    
    return data
end

-- NUI Callbacks for tax data retrieval
RegisterNuiCallback("gouvernement:getSocieties", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getSocieties")
        cb(response or {})
    end)
end)

RegisterNuiCallback("gouvernement:getSocietyMembers", function(data, cb)
    data = ensureDecoded(data)
    
    if not data or data == "" then
        cb({})
        return
    end
    
    -- data should be the societyName string
    local societyName = data
    
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getSocietyMembers", societyName)
        cb(response or {})
    end)
end)

RegisterNuiCallback("gouvernement:getSocietyHistory", function(data, cb)
    data = ensureDecoded(data)
    
    if not data or data == "" then
        cb({})
        return
    end
    
    -- data should be the societyName string
    local societyName = data
    
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getSocietyHistory", societyName)
        cb(response or {})
    end)
end)

RegisterNuiCallback("gouvernement:getTaxSettings", function(data, cb)
    data = ensureDecoded(data)
    
    if not data or data == "" then
        cb({})
        return
    end
    
    -- data should be the societyName string
    local societyName = data
    
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getTaxSettings", societyName)
        cb(response or {})
    end)
end)

RegisterNuiCallback("gouvernement:setSocietyTax", function(data, cb)
    data = ensureDecoded(data)
    
    pcall(function()
        local response = TriggerServerCallback("gouvernement:setSocietyTax", data)
        cb(response or { success = false, message = "Erreur du serveur" })
    end)
end)

-- Set company address
RegisterNuiCallback("gouvernement:setCompanyAddress", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:setCompanyAddress", data)
        cb(response or false)
    end)
end)

-- Get company data (balance + taxes)
RegisterNuiCallback("gouvernement:getCompanyData", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:getCompanyData", data)
        cb(response or { balance = 0, taxes = {} })
    end)
end)

-- Withdraw funds from company
RegisterNuiCallback("gouvernement:withdrawCompanyFunds", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:withdrawCompanyFunds", data)
        cb(response or false)
    end)
end)

-- Deposit funds to company
RegisterNuiCallback("gouvernement:depositCompanyFunds", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:depositCompanyFunds", data)
        cb(response or false)
    end)
end)

-- Get company taxes
RegisterNuiCallback("gouvernement:getCompanyTaxes", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local companyName = data and data.company_name
        if not companyName then
            cb({})
            return
        end
        local response = TriggerServerCallback("gouvernement:getCompanyTaxes", { company_name = companyName })
        cb(response or {})
    end)
    if not ok then
        print("[Gouvernement] Error in getCompanyTaxes: " .. tostring(err))
        cb({})
    end
end)

-- Collect company tax
RegisterNuiCallback("gouvernement:collectCompanyTax", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        if not data or not data.company_name then
            cb(false)
            return
        end
        local response = TriggerServerCallback("gouvernement:collectCompanyTax", { company_name = data.company_name })
        cb(response or false)
    end)
    if not ok then
        print("[Gouvernement] Error in collectCompanyTax: " .. tostring(err))
        cb(false)
    end
end)

-- Set company tax
RegisterNuiCallback("gouvernement:setCompanyTax", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:setCompanyTax", data)
        cb(response or false)
    end)
    if not ok then
        print("[Gouvernement] Error in setCompanyTax: " .. tostring(err))
        cb(false)
    end
end)

-- Delete company tax
RegisterNuiCallback("gouvernement:deleteCompanyTax", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:deleteCompanyTax", data)
        cb(response or false)
    end)
    if not ok then
        print("[Gouvernement] Error in deleteCompanyTax: " .. tostring(err))
        cb(false)
    end
end)

-- Get tax logs for a company
RegisterNuiCallback("gouvernement:getTaxLogs", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:getTaxLogs", data)
        cb(response or {})
    end)
    if not ok then
        print("[Gouvernement] Error in getTaxLogs: " .. tostring(err))
        cb({})
    end
end)

-- Get citizen vehicles
RegisterNuiCallback("gouvernement:getCitizenVehicles", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:getCitizenVehicles", data)
        if response then
            for _, v in ipairs(response) do
                local hash = joaat(v.model)
                local make = GetMakeNameFromVehicleModel(hash) or ""
                local name = GetLabelText(GetDisplayNameFromVehicleModel(hash)) or v.model
                v.model = (make ~= "" and make ~= "NULL" and name ~= "NULL") and (make .. " " .. name) or (name ~= "NULL" and name or v.model)
            end
        end
        cb(response or {})
    end)
end)

-- Get all citizens
RegisterNuiCallback("gouvernement:getCitizens", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getCitizens")
        cb(response or {})
    end)
end)

-- Get citizen properties
RegisterNuiCallback("gouvernement:getCitizenProperties", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:getCitizenProperties", data)
        cb(response or {})
    end)
end)

-- Update citizen phone
RegisterNuiCallback("gouvernement:setCitizenPhone", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:setCitizenPhone", data)
        cb(response or false)
    end)
end)

-- Update citizen address
RegisterNuiCallback("gouvernement:setCitizenAddress", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:setCitizenAddress", data)
        cb(response or false)
    end)
end)

-- Update citizen last name
RegisterNuiCallback("gouvernement:updateCitizenLastName", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:updateCitizenLastName", data)
        cb(response or { success = false, message = "Action impossible pour le moment" })
    end)
end)

RegisterNuiCallback("gouvernement:getBankHistory", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        
        -- Extract citizenId from object if needed
        local citizenId = data
        if type(data) == 'table' and data.citizenId then
            citizenId = data.citizenId
        end
        
        local response = TriggerServerCallback("gouvernement:getBankHistory", citizenId)
        cb(response or {})
    end)
end)

RegisterNuiCallback("gouvernement:withdrawFromSociety", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:withdrawFromSociety", data)
        cb(response or { success = false, message = "Action impossible pour le moment" })
        -- Refresh the panel UI client-side when operation succeeded
        if response and response.success then
            TriggerEvent("gouvernement:refreshPanel")
        end
    end)
end)

RegisterNuiCallback("gouvernement:manageCompanyAccount", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:manageCompanyAccount", data)
        cb(response or { success = false, message = "Action impossible pour le moment" })
        -- Refresh the panel UI client-side when operation succeeded
        if response and response.success then
            TriggerEvent("gouvernement:refreshPanel")
        end
    end)
end)

RegisterNuiCallback("gouvernement:deleteTax", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:deleteTax", data)
        cb(response or { success = false, message = "Action impossible pour le moment" })
    end)
end)

-- Get all appointments
RegisterNuiCallback("gouvernement:getAppointments", function(data, cb)
    local ok, response = pcall(function()
        return TriggerServerCallback("gouvernement:getAppointments")
    end)
    if ok then
        cb(response or {})
    else
        print("[GOUV] Error getAppointments: " .. tostring(response))
        cb({})
    end
end)

-- Get government staff
RegisterNuiCallback("gouvernement:getGovernmentStaff", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getGovernmentStaff")
        cb(response or {})
    end)
end)

-- Delete appointment
RegisterNuiCallback("gouvernement:deleteAppointment", function(data, cb)
    local ok, response = pcall(function()
        data = ensureDecoded(data)
        if not data then return false end
        return TriggerServerCallback("gouvernement:deleteAppointment", data)
    end)
    cb(ok and response or false)
end)

-- Accept appointment
RegisterNuiCallback("gouvernement:acceptAppointment", function(data, cb)
    local ok, response = pcall(function()
        data = ensureDecoded(data)
        if not data or not data.appointmentId then return false end
        return TriggerServerCallback("gouvernement:acceptAppointment", data)
    end)
    cb(ok and response or false)
end)

-- Update appointment note
RegisterNuiCallback("gouvernement:updateAppointmentNote", function(data, cb)
    local ok, response = pcall(function()
        data = ensureDecoded(data)
        if not data or not data.appointmentId then return false end
        return TriggerServerCallback("gouvernement:updateAppointmentNote", data)
    end)
    cb(ok and response or false)
end)

-- Send appointment message
RegisterNuiCallback("gouvernement:sendAppointmentMessage", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        
        if not data or not data.appointmentId or not data.message then
            cb(false)
            return
        end
        
        local response = TriggerServerCallback("gouvernement:sendAppointmentMessage", data)
        cb(response or false)
    end)
end)

-- Get companies for chat
RegisterNuiCallback("gouvernement:getCompanies", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getCompanies")
        cb(response or {})
    end)
end)

-- Get conversation with a company
RegisterNuiCallback("gouvernement:getConversation", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local companyName = data
        if type(data) == "table" and data.companyName then
            companyName = data.companyName
        end
        local response = TriggerServerCallback("gouvernement:getConversation", companyName)
        cb(response or {})
    end)
end)

-- Send message to a company
RegisterNuiCallback("gouvernement:sendMessage", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local targetJob = data and (data.targetJob or data.receiverJob)
        local messageText = data and (data.messageText or data.message)
        if not targetJob or not messageText then
            cb(false)
            return
        end
        local response = TriggerServerCallback("gouvernement:sendMessage", { targetJob = targetJob, messageText = messageText })
        cb(response or false)
    end)
end)

-- Delete a single message from a conversation
RegisterNuiCallback("gouvernement:deleteMessage", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        if not data or not data.messageId then
            cb(false)
            return
        end
        local response = TriggerServerCallback("gouvernement:deleteMessage", { messageId = data.messageId })
        cb(response or false)
    end)
    if not ok then
        cb(false)
    end
end)

-- Clear all messages in a conversation
RegisterNuiCallback("gouvernement:clearConversation", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        if not data or not data.companyName then
            cb(false)
            return
        end
        local response = TriggerServerCallback("gouvernement:clearConversation", { companyName = data.companyName })
        cb(response or false)
    end)
    if not ok then
        cb(false)
    end
end)

RegisterNuiCallback("gouvernement:getUnreadByCompany", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getUnreadByCompany")
        cb(response or {})
    end)
end)

RegisterNuiCallback("gouvernement:markCompanyAsRead", function(data, cb)
    pcall(function()
        data = ensureDecoded(data)
        local companyName = type(data) == 'table' and data.companyName or data
        if not companyName then
            cb(false)
            return
        end
        local response = TriggerServerCallback("gouvernement:markCompanyAsRead", { companyName = companyName })
        cb(response or false)
    end)
end)

-- ============================================================================
-- GOUVERNEMENT PERMISSIONS MANAGEMENT (Settings tab)
-- ============================================================================

-- Get grades with their permissions
RegisterNuiCallback("gouvernement:getGradesPermissions", function(data, cb)
    pcall(function()
        local response = TriggerServerCallback("gouvernement:getGradesPermissions")
        cb(response or {})
    end)
end)

-- Update grade permissions
RegisterNuiCallback("gouvernement:updateGradePermissions", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:updateGradePermissions", data)
        cb(response or { success = false, message = "Action impossible pour le moment" })
    end)
    if not ok then
        cb({ success = false, message = "Action impossible pour le moment" })
    end
end)

-- Get employees with their permission overrides
RegisterNuiCallback("gouvernement:getEmployeesPermissions", function(data, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("gouvernement:getEmployeesPermissions")
        cb(response or {})
    end)
    if not ok then
        print("[Gouv] getEmployeesPermissions error: " .. tostring(err))
        cb({})
    end
end)

-- Set/reset employee permission override
RegisterNuiCallback("gouvernement:setEmployeePermission", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("gouvernement:setEmployeePermission", data)
        cb(response or { success = false, message = "Action impossible pour le moment" })
    end)
    if not ok then
        cb({ success = false, message = "Action impossible pour le moment" })
    end
end)

-- Refresh panel data when needed
RegisterNetEvent("gouvernement:refreshPanel")
AddEventHandler("gouvernement:refreshPanel", function()
    if not isPanelOpen then return end
    VFW.Nui.gouvernementPanel(true)
end)
-- Handle name change confirmation request
RegisterNetEvent("gouvernement:showNameChangeModal")
AddEventHandler("gouvernement:showNameChangeModal", function(data)
    -- Send event to NUI to show modal
    SendNuiMessage(json.encode({
        type = "gouvernement:showNameChangeModal",
        payload = data
    }))
    VFW.Nui.Focus(true)
end)

-- Handle name change confirmation from NUI
RegisterNuiCallback("gouvernement:confirmNameChange", function(data, cb)
    VFW.Nui.Focus(false)
    if not data.accepted then
        TriggerServerEvent("gouvernement:refuseNameChange")
        cb(true)
        return
    end

    -- If accepted, trigger server event to finalize the name change
    TriggerServerEvent("gouvernement:finalizeNameChange")
    cb(true)
end)