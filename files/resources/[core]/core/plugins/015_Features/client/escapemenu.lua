---@meta _
---@diagnostic disable: duplicate-doc-field

local statusMenu = false
local disabled = false

--- closeUI
---@return any
local function closeUI()
    if not statusMenu then
        return
    end

    statusMenu = false

    VFW.Nui.EscapeMenu(false)
    VFW.Nui.HudVisible(true)
end

VFW.CloseEscapeMenu = closeUI

local boutique = nil

CreateThread(function()
    while not boutique do
        boutique = VFW.GetCBoutique()

        Wait(0)
    end
end)

RegisterNuiCallback("nui:escape-menu:leave-boutique", function()
    boutique.DeleteCam()
    closeUI()
end)

RegisterNuiCallback("nui:escape-menu:close", function()
    closeUI()
    boutique.DeleteCam()
end)

RegisterNuiCallback("nui:boutique:get:vehicle:type", function(data, cb)
    console.debug("nui:boutique:get:vehicle:type", data)
    local vehicleData = TriggerServerCallback("boutique:getVehiclesByType", data)

    boutique.CreateCam(data)

    SendNUIMessage({
        action= "nui:boutique:sendVcoins",
        data = TriggerServerCallback("boutique:getMyVcoins")
    })

    console.debug("Vehicle data received:", json.encode(vehicleData, { indent = true }))

    if data == "vehicules" then
        console.debug("Sended vehicle data")

        SendNUIMessage({
            action = "nui:boutique:vehicule:"..data,
            data = vehicleData
        })
    elseif data == "air" then
        console.debug("Sended air vehicle data")

        SendNUIMessage({
            action = "nui:boutique:vehicule:"..data,
            data = vehicleData
        })
    else
        console.debug("Sended nautic vehicle data")

        SendNUIMessage({
            action = "nui:boutique:vehicule:"..data,
            data = vehicleData
        })
    end

    cb()
end)

--- .IsOpenEscapeMenu
---@return any
function VFW.IsOpenEscapeMenu()
    return statusMenu
end

RegisterNetEvent("vfw:openEscapeMenuBoutique", function()
    if not statusMenu and not IsPauseMenuActive() and not disabled then
        statusMenu = true

        TriggerScreenblurFadeIn(1000)

        VFW.Nui.HudVisible(false)

        -- Get player data for display
        local playerData = VFW.PlayerData
        local serverId = GetPlayerServerId(PlayerId())
        local playerName = playerData and (playerData.firstName or "Unknown") .. " " .. (playerData.lastName or "Name") or "Unknown Name"
        local playerCount = TriggerServerCallback("vfw:getPlayerCount") or 0

        VFW.Nui.EscapeMenu(true, {
            premium = true,
            premiumEndDate = 1709691273,
            credit = 1000,
            unique_id = "69",
            serverType = 'FA',
            shopPage = true,
            playerInfo = {
                serverId = serverId,
                playerName = playerName,
                playerCount = playerCount,
                serverName = VFW.BrandName()
            }
        })
    end
end)

-- Mise à jour du nombre de joueurs en temps réel
RegisterNetEvent("vfw:updatePlayerCount", function(count)
    SendNUIMessage({
        action = "nui:escape-menu:updatePlayerCount",
        data = count
    })
end)

--- .DisableEscapeMenu
---@param state any
function VFW.DisableEscapeMenu(state)
    disabled = state
end

function VFW.IsEscapeMenuDisabled()
    return disabled == true
end

-- DISABLED: Old boutique opening via F2 - Use /boutique or /paidshop instead
-- RegisterCommand("+openboutique", function()
--     TriggerEvent("vfw:openEscapeMenuBoutique")
-- end, false)