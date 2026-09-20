---@meta _
---@diagnostic disable: duplicate-doc-field

local DOJ_IMG = VFW.CDN.Get("entreprise/doj.png")

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

--- Open DOJ Panel
VFW.Nui.dojPanel = function(visible)
    if visible then
        local playerName = (VFW.PlayerData.firstName or "") .. " " .. (VFW.PlayerData.lastName or "")
        local playerGrade = VFW.PlayerData.job.grade_label or VFW.PlayerData.job.grade

        -- Vérifier si le joueur est staff
        local isStaff = false
        if VFW.staffMode then
            local myId = GetPlayerServerId(PlayerId())
            for _, sid in ipairs(VFW.staffMode) do
                if sid == myId then isStaff = true break end
            end
        end

        SendNUIMessage({
            action = "nui:DOJPanel:data",
            data = {
                job = VFW.PlayerData.job.name,
                jobLabel = VFW.PlayerData.job.label or VFW.PlayerData.job.name,
                playerGrade = playerGrade,
                playerName = playerName,
                playerMugshot = VFW.PlayerData.mugshot or "",
                logo = DOJ_IMG,
                isStaff = isStaff,
            }
        })
    end

    SendNUIMessage({
        action = "nui:DOJPanel:visible",
        data = visible
    })

    VFW.Nui.Focus(visible)
    isPanelOpen = visible

    -- Immediate prop/anim cleanup on close
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
                    if IsControlJustPressed(0, 22) then -- Space
                        isPanelMinimized = false
                        VFW.Nui.Focus(true)
                        SendNUIMessage({
                            action = "nui:DOJPanel:restore",
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

            if not isPanelOpen then
                SetModelAsNoLongerNeeded(GetHashKey(propModel))
                RemoveAnimDict(dict)
                return
            end

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

function OpenDOJPanel()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = "JOB", title = "Justice", subtitle = "Acces", image = DOJ_IMG, content = "Vous devez être en service" })
        return
    end

    if VFW.PlayerData.job.name ~= "doj" then
        return
    end

    VFW.Nui.dojPanel(true)
end

RegisterNuiCallback("nui:closeDOJPanel", function()
    VFW.Nui.dojPanel(false)
    isPanelOpen = false
    isPanelMinimized = false
end)

-- Minimiser la tablette
RegisterNuiCallback("nui:DOJPanel:minimize", function(_, cb)
    if isPanelOpen and not isPanelMinimized then
        isPanelMinimized = true
        VFW.Nui.Focus(false)
        SendNUIMessage({
            action = "nui:DOJPanel:minimized",
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
        if string.sub(data, 1, 1) == "{" or string.sub(data, 1, 1) == "[" then
            local success, decoded = pcall(json.decode, data)
            if success then
                return decoded
            else
                return data
            end
        else
            return data
        end
    end

    return data
end

-- NUI Callbacks for DOJ data

RegisterNuiCallback("doj:getPlayerPermissions", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("doj:getPlayerPermissions")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:getGradesPermissions", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("doj:getGradesPermissions")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:updateGradePermissions", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:updateGradePermissions", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("doj:getPoliceOfficers", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("doj:getPoliceOfficers")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:getDossierDetail", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:getDossierDetail", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:getDossiers", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:getDossiers", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:searchCitizens", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:searchCitizens", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:getWarrants", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:getWarrants", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:getAllWarrants", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("doj:getAllWarrants")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("doj:createWarrant", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:createWarrant", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("doj:updateWarrantStatus", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:updateWarrantStatus", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("doj:deleteWarrant", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:deleteWarrant", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("doj:updateDossier", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:updateDossier", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("doj:deleteDossier", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("doj:deleteDossier", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

