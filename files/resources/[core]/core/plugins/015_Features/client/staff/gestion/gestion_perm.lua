---@meta _
---@diagnostic disable: duplicate-doc-field

RegisterNuiCallback("nui:server-gestion-permission:rolesave", function(data)
    TriggerServerEvent("vfw:staff:saveRole", data)
end)

RegisterNuiCallback("nui:server-gestion-permission:askdiscord", function(data)
    local rolesList = {}
    local roles, discordList
    if type(data) == "string" then
        roles, discordList = TriggerServerCallback("vfw:staff:createRole", data)
    else
        roles, discordList = TriggerServerCallback("vfw:staff:createCopiedRole", data.discord, data.role)
    end

    for k, v in pairs(roles) do
        local color = 0
        local name = "Inconnu"

      for i = 1, #discordList do
            if discordList[i].id == k then
                color = discordList[i].color
                name = discordList[i].name
                break
            end
        end

        local permissions = {}

        for permission, _ in pairs(v.permissions) do
            permissions[#permissions + 1] = permission
        end

        rolesList[#rolesList + 1] = {
            id = k,
            label = name,
            power = v.level,
            permissions = permissions,
            color = color
        }
    end

    SendNUIMessage({
        action = "nui:server-gestion-permission:roles",
        data = rolesList
    })
end)

--- .SendPermGestionData
function VFW.SendPermGestionData()
    SendNUIMessage({
        action = "nui:server-gestion-permission:perms",
        data = Config.Permissions
    })
    
    local rolesList = {}
    local roles, discordList = TriggerServerCallback("vfw:staff:getRoles")

    for k, v in pairs(roles) do
        local color = 0
        local name = "Inconnu"

      for i = 1, #discordList do
            if discordList[i].id == k then
                console.debug("discordList[i].color", discordList[i].color)
                color = discordList[i].color
                name = discordList[i].name
                break
            end
        end

        local permissions = {}

        for permission, _ in pairs(v.permissions) do
            permissions[#permissions + 1] = permission
        end

        rolesList[#rolesList + 1] = {
            id = k,
            label = name,
            power = v.level,
            permissions = permissions,
            color = color
        }
    end

    SendNUIMessage({
        action = "nui:server-gestion-permission:roles",
        data = rolesList
    })
end