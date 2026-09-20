--[[
    Staff Notifications - Client Side
    Receives staff notifications and checks KVP preference before displaying
]]

-- Default = hidden. KVP string "0" = visible, "1"/nil = hidden.
local function isStaffNotifHidden()
    local ok, pref = pcall(GetResourceKvpString, "staff_notifications_hidden")
    if not ok then
        DeleteResourceKvp("staff_notifications_hidden")
        return true
    end
    if pref == nil then return true end
    return pref == "1"
end

-- Event to receive staff chat notifications from server
RegisterNetEvent("vfw:staff:chatNotification")
AddEventHandler("vfw:staff:chatNotification", function(template, message)
    if isStaffNotifHidden() then
        return
    end

    TriggerEvent('chat:addMessage', {
        template = template,
        args = { message }
    })
end)

exports('IsStaffNotificationHidden', isStaffNotifHidden)

exports('SetStaffNotificationHidden', function(hidden)
    SetResourceKvp("staff_notifications_hidden", hidden and "1" or "0")
end)
