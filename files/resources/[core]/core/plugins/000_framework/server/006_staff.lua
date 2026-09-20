local crewCount = {}

RegisterNetEvent("vfw:staff:sendGlobalAnnouncement", function(message)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("announce_serv") then return end
    if type(message) ~= "string" or message == "" then return end

    TriggerClientEvent("core:vnotif:createAlert", -1, message:sub(1, 500), "")
end)

RegisterNetEvent("core:vnotif:createAlert:staff", function(message)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("announce_modo") then return end
    if type(message) ~= "string" or message == "" then return end

    for target, other in pairs(VFW.Players) do
        if other.hasPermission("staff_menu") then
            TriggerClientEvent("core:vnotif:createAlert", target, message:sub(1, 500), "")
        end
    end
end)

RegisterNetEvent("vfw:staff:sendZoneAnnouncement", function(radius, message)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("announce_serv") then return end

    radius = tonumber(radius) or 0
    if radius < 1 or radius > 750 then return end
    if type(message) ~= "string" or message == "" then return end

    local nearby = VFW.GetPlayersInRadius(xPlayer.getCoords(), radius)
    for i = 1, #nearby do
        TriggerClientEvent("core:vnotif:createAlert", nearby[i].source, message:sub(1, 500), "")
    end
end)

RegisterNetEvent("core:vnotif:createAlert:zone", function(targetId, message)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("announce_serv") then return end
    if type(message) ~= "string" then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then return end

    TriggerClientEvent("core:vnotif:createAlert", target.source, message:sub(1, 500), "")
end)

RegisterNetEvent("core:vnotif:createAlert:player", function(msg, targetId, isAnim)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local senderType = isAnim and "animator" or "staff"
    local permission = isAnim and "menu_anim" or "staff_menu"

    if not xPlayer.hasPermission(permission) then
        TriggerClientEvent("vfw:staff:msgResult", source, false, "perm", "", 0, senderType)
        return
    end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        TriggerClientEvent("vfw:staff:msgResult", source, false, "notfound", "", tonumber(targetId) or 0, senderType)
        return
    end

    TriggerClientEvent("core:vnotif:createAlert", target.source, tostring(msg):sub(1, 500), "")
    TriggerClientEvent("vfw:staff:msgResult", source, true, nil,
        ("%s %s"):format(target.firstName, target.lastName), target.source, senderType)
end)

RegisterNetEvent("vfw:showPlayerID", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    TriggerClientEvent("vfw:receivePlayerID", source, xPlayer.uuid, source)
end)

RegisterServerCallback("vfw:getPlayerUUID", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return xPlayer and xPlayer.uuid or ""
end)

RegisterServerCallback("vfw:getPlayerGlobalData", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer then return xPlayer.getGlobalData() end

    local account = VFW.GetPendingAccount(source)
    if not account then return {} end

    local payload = {
        id = account.id,
        uuid = account.uuid,
        permissions = account.permissions or {},
        vip_tier = account.vip_tier or 0,
        level = account.level or 0,
        spacecoins = account.spacecoins or 0,
        role = account.role or "user",
        roleId = account.role_id or 0,
    }
    if VFW.HydrateNiveau6Permissions then
        VFW.HydrateNiveau6Permissions(payload)
    end
    return payload
end)

RegisterNetEvent("vfw:stafflogs:tpm", function(from, to)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("tp") then return end
    if type(from) ~= "table" or type(to) ~= "table" then return end

    TriggerEvent("vfw:logs:staff", source, "tpm", { from = from, to = to })
end)

RegisterNetEvent("vfw:staff:updateVeh", function(props)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_custom") then return end
    if type(props) ~= "table" then return end

    TriggerEvent("vfw:vehicle:updateProperties", source, props)
end)

RegisterNetEvent("core:UpdateCrewCount", function(faction, isJoining)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(faction) ~= "string" then return end
    if xPlayer.faction ~= faction then return end

    if faction == "" or faction == "nocrew" then return end

    crewCount[faction] = (crewCount[faction] or 0) + (isJoining and 1 or -1)
    if crewCount[faction] < 0 then crewCount[faction] = 0 end

    GlobalState[("crewCount:%s"):format(faction)] = crewCount[faction]
end)

RegisterNetEvent("vfw:blips:create", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_blips") then return end
    if type(data) ~= "table" or type(data.positions) ~= "table" then return end

    local blips = VFW.Variables.GetVariable("custom_blips") or {}
    blips[#blips + 1] = data
    VFW.Variables.SetVariable("custom_blips", blips)

    TriggerClientEvent("vfw:blips:create", -1, data)
end)

AddEventHandler("vfw:characterLoaded", function(source)
    local blips = VFW.Variables.GetVariable("custom_blips") or {}
    for i = 1, #blips do
        TriggerClientEvent("vfw:blips:create", source, blips[i])
    end
end)

RegisterNetEvent("core:server:loadedLocation", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    TriggerEvent("vfw:player:locationLoaded", source)
end)

local function notifyStaffScreenshot(target, variant, message)
    TriggerClientEvent("vfw:showNotification", target, {
        type = "STAFF",
        variant = variant,
        subtitle = "Screenshot",
        message = message,
        content = message,
    })
end

RegisterNetEvent("vfw:staff:takeScreenshot", function(targetId, playerInfo)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("screenshot") then return end

    targetId = tonumber(targetId)
    if not targetId then return end

    local xTarget = VFW.GetPlayerFromId(targetId)
    if not xTarget then
        notifyStaffScreenshot(source, "ERROR", "Joueur introuvable.")
        return
    end

    if not (VFW.FiveManage and VFW.FiveManage.ApiKey and VFW.FiveManage.ApiKey()) then
        notifyStaffScreenshot(source, "ERROR",
            "FiveManage n'est pas configuré. Renseigne FIVEMANAGE_MEDIA_API_KEY dans server.cfg.")
        return
    end

    local info = {
        name = ("%s %s"):format(xTarget.firstName or "", xTarget.lastName or ""),
        visaId = (type(playerInfo) == "table" and tonumber(playerInfo.visaId)) or 0,
    }

    local answered = false

    local function fail(message)
        if answered then return end
        answered = true
        notifyStaffScreenshot(source, "ERROR", message)
    end

    SetTimeout(20000, function()
        fail("La capture n'a pas abouti dans le délai imparti.")
    end)

    local function screenshotsFolder()
        local folder = GetConvar("core_fivemanage_screenshots_path", "")
        if type(folder) == "string" and folder ~= "" then
            return folder:gsub("^/+", ""):gsub("/+$", "")
        end
        local root = GetConvar("core_fivemanage_path", "")
        if type(root) == "string" and root ~= "" then
            return (root:gsub("^/+", ""):gsub("/+$", "")) .. "/screenshots"
        end
        return "staff/screenshots"
    end

    exports["screenshot-basic"]:requestClientScreenshot(targetId, { encoding = "jpg", quality = 0.7 },
        function(err, data)
            if answered then return end

            if err or type(data) ~= "string" then
                fail("La capture a échoué.")
                return
            end

            CreateThread(function()
                if answered then return end

                local dataUrl = data
                if not dataUrl:match("^data:") then
                    dataUrl = "data:image/jpeg;base64," .. data
                end
                local filename = ("%s_%s.jpg"):format(targetId, os.time())
                local url = VFW.FiveManage.UploadBase64(dataUrl, filename, screenshotsFolder())

                if answered then return end
                if type(url) ~= "string" or url == "" then
                    fail("L'envoi FiveManage a échoué (voir la console serveur).")
                    return
                end

                answered = true
                TriggerClientEvent("vfw:staff:receiveScreen", source, url, info)
            end)
        end)
end)

local staffMode = {}

local function currentStaffModeList()
    local list, n = {}, 0
    for src in pairs(staffMode) do
        n = n + 1
        list[n] = src
    end
    return list
end

local function broadcastStaffMode()
    TriggerClientEvent("vfw:staff:syncStaffMode", -1, currentStaffModeList())
end

local function staffNotify(source, variant, subtitle, message)
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF",
        variant = variant,
        subtitle = subtitle,
        message = message,
    })
end

local function staffRadius(value, maximum)
    local radius = tonumber(value)
    if not radius or radius <= 0 then return nil end
    if radius > maximum then return maximum end
    return radius
end

local function staffVehicleByPlate(plate)
    if type(plate) ~= "string" then return nil end
    if not VFW.Vehicles or not VFW.Vehicles.FindEntityByPlate then return nil end

    local vehicle = VFW.Vehicles.FindEntityByPlate(plate)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    return vehicle
end

local function staffNormalizedPlate(plate)
    if not VFW.Vehicles or not VFW.Vehicles.NormalizePlate then return "" end
    return VFW.Vehicles.NormalizePlate(plate) or ""
end

RegisterNetEvent("vfw:staff:mode", function(enabled, bypassOutfit)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return end

    local active = enabled and true or false
    staffMode[source] = active or nil

    broadcastStaffMode()
    TriggerClientEvent("vfw:staff:modeChanged", source, active)

    if active then
        -- Tenue staff temporairement désactivée (ne plus forcer le costume).
    else
        TriggerClientEvent("vfw:staff:setStaffClothes", source, false)
        TriggerClientEvent("staff:onStaffModeExit", source)
    end

    TriggerEvent("vfw:logs:staff", source, "staff_mode", { enabled = active })
end)

AddEventHandler("playerDropped", function()
    local source = source
    if not staffMode[source] then return end

    staffMode[source] = nil
    broadcastStaffMode()
end)

RegisterNetEvent("vfw:staff:clearZone", function(radius)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("clean_zone") then return end

    local range = staffRadius(radius, 500)
    if not range then return end

    local coords = xPlayer.getCoords()
    if not coords then return end

    local zone = { x = coords.x, y = coords.y, z = coords.z }
    local nearby = VFW.GetPlayersInRadius(coords, range + 100)
    for i = 1, #nearby do
        TriggerClientEvent("vfw:clearZone", nearby[i].source, zone, range)
    end

    staffNotify(source, "SUCCESS", "Outils Staff",
        ("Nettoyage lancé dans un rayon de %d mètres."):format(math.floor(range)))
    TriggerEvent("vfw:logs:staff", source, "clear_zone", { radius = range, coords = zone })
end)

RegisterNetEvent("vfw:staff:reviveZone", function(radius)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("zone_actions") then return end

    local range = staffRadius(radius, 500)
    if not range then return end

    local nearby = VFW.GetPlayersInRadius(xPlayer.getCoords(), range)
    local revived = 0
    for i = 1, #nearby do
        if nearby[i].dead then
            nearby[i].revive()
            revived = revived + 1
        end
    end

    local message
    if revived == 0 then
        message = "Aucun joueur au sol dans ce rayon."
    elseif revived == 1 then
        message = "1 joueur réanimé."
    else
        message = ("%d joueurs réanimés."):format(revived)
    end

    staffNotify(source, revived > 0 and "SUCCESS" or "INFO", "Outils Staff", message)
    TriggerEvent("vfw:logs:staff", source, "revive_zone", { radius = range, count = revived })
end)

RegisterNetEvent("vfw:staff:selfFillNeeds", function(need)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("heal") and not xPlayer.hasPermission("menu_anim") then return end

    if need == "hunger" then
        VFW.SetStatus(source, 100, nil)
    elseif need == "thirst" then
        VFW.SetStatus(source, nil, 100)
    elseif need == "both" then
        VFW.SetStatus(source, 100, 100)
    end
end)

RegisterNetEvent("vfw:staff:spawnVehicle", function(model, posX, posY, posZ, heading)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("alt_spawn_vehicle") then return end
    if type(model) ~= "string" or model == "" or #model > 32 then return end

    local x, y, z = tonumber(posX), tonumber(posY), tonumber(posZ)
    if not x or not y or not z then return end
    if not Feat27 or not Feat27.SpawnVehicle then return end

    local hash = joaat(model)
    local vehicleType = VFW.GetVehicleType and VFW.GetVehicleType(hash, source) or "automobile"
    local netId = Feat27.SpawnVehicle(hash, { x = x, y = y, z = z }, tonumber(heading) or 0.0, vehicleType)

    if not netId then
        staffNotify(source, "ERROR", "Spawn véhicule", "Ce véhicule n'a pas pu apparaître.")
        return
    end

    staffNotify(source, "SUCCESS", "Spawn véhicule", "Le véhicule est apparu.")
    TriggerEvent("vfw:logs:staff", source, "spawn_vehicle", { model = model, coords = { x = x, y = y, z = z } })
end)

RegisterNetEvent("vfw:staff:bringVehicle", function(plate)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("bring_vehicle") then return end

    local vehicle = staffVehicleByPlate(plate)
    if not vehicle then
        staffNotify(source, "ERROR", "Véhicule", "Aucun véhicule sorti ne porte cette plaque.")
        return
    end

    local coords = xPlayer.getCoords(true)
    local heading = tonumber(coords.heading) or 0.0
    local radians = math.rad(heading)

    SetEntityCoords(vehicle,
        coords.x - math.sin(radians) * 3.5,
        coords.y + math.cos(radians) * 3.5,
        coords.z, false, false, false, false)
    SetEntityHeading(vehicle, heading)

    staffNotify(source, "SUCCESS", "Véhicule", "Le véhicule a été amené devant vous.")
    TriggerEvent("vfw:logs:staff", source, "bring_vehicle", { plate = staffNormalizedPlate(plate) })
end)

local function staffGoToVehicle(source, plate)
    local vehicle = staffVehicleByPlate(plate)
    if not vehicle then
        staffNotify(source, "ERROR", "Véhicule", "Aucun véhicule sorti ne porte cette plaque.")
        return
    end

    local coords = GetEntityCoords(vehicle)
    TriggerClientEvent("vfw:teleportTo", source, coords.x + 2.5, coords.y, coords.z)
    TriggerEvent("vfw:logs:staff", source, "goto_vehicle", { plate = staffNormalizedPlate(plate) })
end

RegisterNetEvent("vfw:staff:gotoVehicle", function(plate)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("goto_vehicle") then return end

    staffGoToVehicle(source, plate)
end)

RegisterNetEvent("vfw:staff:tpToVehicle", function(plate)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("staff_vehicle_tp") and not xPlayer.hasPermission("alt_teleport") then return end

    staffGoToVehicle(source, plate)
end)

local function staffChatBroadcast(source, message)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_chat") then return end
    if type(message) ~= "string" then return end

    local text = message:sub(1, 300)
    if text:gsub("%s", "") == "" then return end

    local globalData = xPlayer.getGlobalData()
    local rank = globalData and globalData.role
    if type(rank) ~= "string" or rank == "" then rank = "Staff" end

    for target, other in pairs(VFW.Players) do
        if other.hasPermission("staff_chat") then
            TriggerClientEvent("vfw:staff:receiveStaffMessage", target, xPlayer.name, text, rank, "cyan")
        end
    end

    TriggerEvent("vfw:logs:staff", source, "staff_chat", { message = text })
end

RegisterNetEvent("vfw:staff:sendStaffMessage", function(message)
    local source = source
    staffChatBroadcast(source, message)
end)

RegisterNetEvent("vfw:staff:sendChatMessage", function(message)
    local source = source
    staffChatBroadcast(source, message)
end)

local function canHubEnvironment(xPlayer, perm)
    if not xPlayer then return false end
    return xPlayer.hasPermission(perm) or xPlayer.hasPermission("server_management") or xPlayer.hasPermission("admin")
end

RegisterNetEvent("vfw:staff:setTime", function(hour, minute)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canHubEnvironment(xPlayer, "time") then return end

    local newHour = tonumber(hour)
    if not newHour then return end
    local newMinute = tonumber(minute) or 0

    TriggerEvent("vfw:environment:setTime", newHour, newMinute)
    TriggerEvent("vfw:logs:staff", source, "set_time", { hour = newHour, minute = newMinute })
end)

RegisterNetEvent("vfw:staff:setWeather", function(weather)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canHubEnvironment(xPlayer, "weather") then return end
    if type(weather) ~= "string" or weather == "" or #weather > 32 then return end

    TriggerEvent("vfw:environment:setWeather", weather)
    TriggerEvent("vfw:logs:staff", source, "set_weather", { weather = weather:upper() })
end)

RegisterNetEvent("vfw:staff:freezeTime", function(frozen)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canHubEnvironment(xPlayer, "freezetime") then return end

    local state = frozen and true or false
    TriggerEvent("vfw:environment:freezeTime", state)
    TriggerEvent("vfw:logs:staff", source, "freeze_time", { frozen = state })
end)

RegisterNetEvent("vfw:staff:freezeWeather", function(frozen)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canHubEnvironment(xPlayer, "freezeweather") then return end

    local state = frozen and true or false
    TriggerEvent("vfw:environment:freezeWeather", state)
    TriggerEvent("vfw:logs:staff", source, "freeze_weather", { frozen = state })
end)

local animatorMode = {}

local function currentAnimatorModeList()
    local list, n = {}, 0
    for src in pairs(animatorMode) do
        n = n + 1
        list[n] = src
    end
    return list
end

local function broadcastAnimatorMode()
    TriggerClientEvent("vfw:animator:syncAnimatorMode", -1, currentAnimatorModeList())
end

RegisterNetEvent("vfw:animator:mode", function(enabled)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("menu_anim") then return end

    local active = enabled and true or false
    animatorMode[source] = active or nil

    broadcastAnimatorMode()
    TriggerEvent("vfw:logs:staff", source, "animator_mode", { enabled = active })
end)

AddEventHandler("playerDropped", function()
    local source = source
    if not animatorMode[source] then return end

    animatorMode[source] = nil
    broadcastAnimatorMode()
end)

RegisterServerCallback("vfw:staff:getJobs", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end

    return VFW.Jobs or {}
end)
