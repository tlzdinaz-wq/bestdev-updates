---@meta _
---@diagnostic disable: duplicate-doc-field

--- LeaveCrew
---@return any
function LeaveCrew()
    VFW.Nui.Radial(nil, false)
    if VFW.PlayerData.faction.name == "nofaction" then
        return
    end

    TriggerServerEvent("core:faction:leavemyCrew")
end

--- InviteCrew
---@return any
function InviteCrew()
    VFW.Nui.Radial(nil, false)
    if VFW.PlayerData.faction.name == "nocrew" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas de faction"
        })
        return
    end

    local canRecruit = VFW.GetMyCrewPermission("recruit")
    if canRecruit then
        local result = VFW.StartSelect(3.0, true)
        local idS = GetPlayerServerId(result)
        if result and idS then
            TriggerServerEvent("core:faction:invitePlayer", idS)
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas le droit de recruter"
        })
    end
end

---@param name string
---@param label string
---@param src any
---@param image string|nil
RegisterNetEvent("core:faction:invitePlayer", function(name, label, src, image)
    local choice = false
    VFW.ShowNotification({
        title = "CREW",
        mainMessage = label,
        type = "INVITE_NOTIFICATION",
        duration = 30,
        image = image
    })
    
    CreateThread(function()
        while not choice do
            Wait(0)
            if IsControlJustPressed(0, 246) then
                TriggerServerEvent("core:faction:acceptInvite", name, src)
                choice = true
                VFW.RemoveNotification()
            elseif IsControlJustPressed(0, 249) then
                choice = true
                VFW.RemoveNotification()
            end
        end
    end)
end)
