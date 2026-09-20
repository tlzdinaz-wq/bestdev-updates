-- Feature désactivée temporairement (exploit /rewards:reset + farm illimité)
-- Retirer ce return pour réactiver
do return end

local isNuiOpen = false

-- Open NUI panel with data from server
RegisterNetEvent('rewards:openNUI', function(data)
    if isNuiOpen then
        return
    end

    isNuiOpen = true
    VFW.Nui.Focus(true)

    SendNUIMessage({
        action = "nui:rewards:open",
        data = data
    })
end)

-- Update progress without reopening panel
RegisterNetEvent('rewards:updateProgress', function(data)
    SendNUIMessage({
        action = "nui:rewards:updateProgress",
        data = data
    })
end)

-- Update gifts list
RegisterNetEvent('rewards:updateGifts', function(data)
    SendNUIMessage({
        action = "nui:rewards:updateGifts",
        data = data
    })
end)

-- Close callback
RegisterNUICallback('nui:rewards:close', function(data, cb)
    isNuiOpen = false
    VFW.Nui.Focus(false)
    cb('ok')
end)

-- Vehicle preview callback
RegisterNUICallback('nui:rewards:previewVehicle', function(data, cb)
    local model = data.model
    if not model then
        cb('error')
        return
    end

    -- Spawn a preview vehicle near the player
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    -- Calculate spawn position in front of player
    local forwardX = playerCoords.x + (math.sin(math.rad(heading)) * 5.0)
    local forwardY = playerCoords.y + (math.cos(math.rad(heading)) * 5.0)
    local spawnCoords = vector3(forwardX, forwardY, playerCoords.z)

    -- Request and spawn vehicle
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)

    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if HasModelLoaded(modelHash) then
        local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, false, false)
        SetEntityAlpha(vehicle, 200, false) -- Make it slightly transparent
        FreezeEntityPosition(vehicle, true) -- Freeze it so it can't be moved

        -- Store vehicle for cleanup
        if not RewardsPreviewVehicle then
            RewardsPreviewVehicle = vehicle
        else
            -- Delete old preview vehicle
            if DoesEntityExist(RewardsPreviewVehicle) then
                DeleteEntity(RewardsPreviewVehicle)
            end
            RewardsPreviewVehicle = vehicle
        end

        -- Auto-delete after 30 seconds
        SetTimeout(30000, function()
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
        end)
    end

    SetModelAsNoLongerNeeded(modelHash)
    cb('ok')
end)

-- Claim gift callback
RegisterNUICallback('nui:rewards:claimGift', function(data, cb)
    local giftIndex = data.giftIndex
    local track = data.track or "regular"

    if giftIndex == nil then
        cb('error')
        return
    end

    -- Send claim request to server with both giftIndex and track
    TriggerServerEvent('rewards:claimGift', {
        giftIndex = giftIndex,
        track = track
    })

    cb('ok')
end)

-- Main command to open rewards panel
RegisterCommand(Rewards.PlayerCommand, function()
    TriggerServerEvent('rewards:openPanel')
end, false)

-- Alias command
if Rewards.PlayerCommandAlias then
    RegisterCommand(Rewards.PlayerCommandAlias, function()
        TriggerServerEvent('rewards:openPanel')
    end, false)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Close NUI if open
    if isNuiOpen then
        VFW.Nui.Focus(false)
        isNuiOpen = false
    end
end)
