---@meta _
---@diagnostic disable: duplicate-doc-field

local isPanelOpen = false
local tabletProp = nil

local function splitAnnouncements(rows)
    local pending, history = {}, {}
    if type(rows) ~= "table" then return pending, history end

    for _, row in ipairs(rows) do
        if row.broadcasted == 1 or row.broadcasted == true then
            history[#history + 1] = row
        else
            pending[#pending + 1] = row
        end
    end

    return pending, history
end

--- Open Weazel News Panel (Régie TV)
VFW.Nui.WeazelNewsPanel = function(visible)
    if visible then
        local announcements, history = splitAnnouncements(TriggerServerCallback("weazel:getAnnouncements"))
        local societyImage = TriggerServerCallback("weazel:getSocietyImage") or ""
        weazelImage = societyImage

        local society = TriggerServerCallback("weazel:getSocietyCustom") or {}
        local weazelPerms = society.weazelPerms or { create = 0, edit = 0, schedule = 0, delete = 0 }

        SendNUIMessage({
            action = "nui:weazelNewsPanel:data",
            data = {
                job = VFW.PlayerData.job.name,
                announcements = announcements or {},
                history = history or {},
                weazelPerms = weazelPerms,
                playerGrade = VFW.PlayerData.job.grade,
                playerName = (VFW.PlayerData.firstName or "") .. " " .. (VFW.PlayerData.lastName or ""),
            }
        })
    end

    SendNUIMessage({
        action = "nui:weazelNewsPanel:visible",
        data = visible
    })

    VFW.Nui.Focus(visible)
    isPanelOpen = visible

    if visible then
        CreateThread(function()
            while isPanelOpen do
                DisableControlAction(0, 245, true) -- T (chat)
                Wait(0)
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

function OpenWeazelNewsPanel()
    VFW.Nui.WeazelNewsPanel(true)
end

RegisterNuiCallback("nui:closeWeazelNewsPanel", function()
    VFW.Nui.WeazelNewsPanel(false)
    isPanelOpen = false
    VFW.ClearPreview()
end)

-- Refresh panel data when announcements change (triggered by server)
RegisterNetEvent("weazel:refreshPanel")
AddEventHandler("weazel:refreshPanel", function()
    if not isPanelOpen then return end

    local announcements, history = splitAnnouncements(TriggerServerCallback("weazel:getAnnouncements"))
    SendNUIMessage({
        action = "nui:weazelNewsPanel:data",
        data = {
            job = VFW.PlayerData.job.name,
            announcements = announcements or {},
            history = history or {},
        }
    })
end)
