---@meta _
---@diagnostic disable: duplicate-doc-field

local logsData = {
    logs = {},
    filters = {
        showKills = true,
        showConnections = true,
        showCommands = true,
        showChat = true,
        showTransactions = true,
        showVehicles = true,
        showWeapons = true,
        showTeleports = true
    },
    maxLogs = 100,
    autoScroll = true
}

-- Log types with colors
local logTypes = {
    kill = {icon = ":skull:", color = "red", label = "Kill"},
    connection = {icon = ":bolt:", color = "green", label = "Connection"},
    command = {icon = ":bolt:", color = "yellow", label = "Command"},
    chat = {icon = ":chat:", color = "blue", label = "Chat"},
    transaction = {icon = ":money:", color = "orange", label = "Transaction"},
    vehicle = {icon = ":car:", color = "purple", label = "Vehicle"},
    weapon = {icon = ":gun:", color = "red", label = "Weapon"},
    teleport = {icon = ":pin:", color = "cyan", label = "Teleport"},
    admin = {icon = ":warning:", color = "orange", label = "Admin Action"}
}

-- Receive logs from server
RegisterNetEvent("vfw:staff:receiveLog", function(logType, data)
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["view_logs"] then return end
    
    local log = {
        type = logType,
        data = data,
        timestamp = os.date("%H:%M:%S"),
        icon = logTypes[logType] and logTypes[logType].icon or ":edit:",
        color = logTypes[logType] and logTypes[logType].color or "white"
  }
    
    table.insert(logsData.logs, 1, log)
    
    -- Limit log history
    if #logsData.logs > logsData.maxLogs then
        table.remove(logsData.logs, #logsData.logs)
    end
end)

-- Build Action Logs Menu
function StaffMenu.BuildActionLogsMenu()
    StaffMenu.actionLogs.Separator("LOGS D'ACTIONS")
    
    -- Filter options
    StaffMenu.actionLogs.Separator("FILTRES")
    
    for filterName, enabled in pairs(logsData.filters) do
        local label = filterName:gsub("show", ""):gsub("^%l", string.upper)
        StaffMenu.actionLogs.Checkbox(label, nil, false, enabled, function(_checked)
            logsData.filters[filterName] = _checked
        end)
    end
    
    StaffMenu.actionLogs.Separator(nil)
    
    -- Auto-scroll toggle
    StaffMenu.actionLogs.Checkbox("AUTO-SCROLL", nil, false, logsData.autoScroll, function(_checked)
        logsData.autoScroll = _checked
    end)
    
    -- Clear logs
    StaffMenu.actionLogs.Button(":trash: EFFACER LES LOGS", "Supprimer tous les logs affichés dans ce menu (sans impact sur les logs Discord)", nil, "trash", false, function()
        logsData.logs = {}
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Logs Actions',
            message = "Logs effacés."
      })
    end)
    
    -- Export logs
    StaffMenu.actionLogs.Button(":save: EXPORTER LES LOGS", "Copier tous les logs dans le presse-papier au format texte", nil, "download", false, function()
        local exportText = "=== LOGS D'ACTIONS ===\n"
      for _, log in ipairs(logsData.logs) do
            exportText = exportText .. string.format("[%s] %s %s: %s\n", 
                log.timestamp, log.icon, log.type:upper(), json.encode(log.data))
        end
        
        -- This would normally save to file or clipboard
        VFW.Clipboard(exportText)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Logs Actions',
            message = "Logs exportés dans le presse-papier."
      })
    end)
    
    StaffMenu.actionLogs.Separator("LOGS RÉCENTS")
    
    -- Display filtered logs
    local displayedLogs = 0
    for _, log in ipairs(logsData.logs) do
        local shouldShow = false
        
        if log.type == "kill" and logsData.filters.showKills then shouldShow = true
        elseif log.type == "connection" and logsData.filters.showConnections then shouldShow = true
        elseif log.type == "command" and logsData.filters.showCommands then shouldShow = true
        elseif log.type == "chat" and logsData.filters.showChat then shouldShow = true
        elseif log.type == "transaction" and logsData.filters.showTransactions then shouldShow = true
        elseif log.type == "vehicle" and logsData.filters.showVehicles then shouldShow = true
        elseif log.type == "weapon" and logsData.filters.showWeapons then shouldShow = true
        elseif log.type == "teleport" and logsData.filters.showTeleports then shouldShow = true
        end
        
        if shouldShow then
            local title = string.format("[%s] %s %s", log.timestamp, log.icon, log.type:upper())
            local subtitle = type(log.data) == "table" and json.encode(log.data) or tostring(log.data)
            
            -- Truncate long subtitles
            if #subtitle > 50 then
                subtitle = subtitle:sub(1, 47) .. "..."
          end
            
            StaffMenu.actionLogs.Button(":edit: " .. title, subtitle, nil, nil, true, function() end)
            
            displayedLogs = displayedLogs + 1
            if displayedLogs >= 20 then break end -- Limit display
        end
    end
    
    if displayedLogs == 0 then
        StaffMenu.actionLogs.Separator("Aucun log à afficher")
    end
end

-- Log player actions
function LogPlayerAction(action, details)
    TriggerServerEvent("vfw:staff:logAction", action, details)
end

-- Monitor player actions
CreateThread(function()
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["monitor_players"] then return end
    
    local lastVehicle = nil
    local lastWeapon = nil
    local lastCoords = GetEntityCoords(PlayerPedId())
    
    while true do
        Wait(1000)
        
        local playerPed = PlayerPedId()
        local currentCoords = GetEntityCoords(playerPed)
        
        -- Monitor vehicle changes
        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        if currentVehicle ~= lastVehicle then
            if currentVehicle ~= 0 then
                LogPlayerAction("vehicle", {
                    action = "entered",
                    model = GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle)),
                    plate = GetVehicleNumberPlateText(currentVehicle)
                })
            elseif lastVehicle ~= 0 then
                LogPlayerAction("vehicle", {
                    action = "exited"
              })
            end
            lastVehicle = currentVehicle
        end
        
        -- Monitor weapon changes
        local currentWeapon = GetSelectedPedWeapon(playerPed)
        if currentWeapon ~= lastWeapon and currentWeapon ~= `WEAPON_UNARMED` then
            LogPlayerAction("weapon", {
                weapon = currentWeapon
            })
            lastWeapon = currentWeapon
        end
        
        -- Monitor teleports (large distance changes)
        local distance = #(currentCoords - lastCoords)
        if distance > 100.0 then
            LogPlayerAction("teleport", {
                from = lastCoords,
                to = currentCoords,
                distance = distance
            })
        end
        lastCoords = currentCoords
    end
end)