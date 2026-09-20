---@meta _
---@diagnostic disable: duplicate-doc-field

local animatorHudVisible = false
local animReports = 0
local onlineAnimators = 0
local animatorsInService = 0
local animHudInitialized = false

-- Envoie les données actuelles à la NUI
local function UpdateAnimatorHudNUI()
    SendNUIMessage({
        action = "animatorHud:update",
        data = {
            visible = animatorHudVisible,
            animReports = animReports,
            onlineAnimators = onlineAnimators,
            animatorsInService = animatorsInService
        }
    })
end

-- Fonctions globales
_G.IsAnimatorHUDVisible = function()
    return animatorHudVisible
end

_G.ToggleAnimatorHUD = function(state)
    animatorHudVisible = state
    SendNUIMessage({
        action = "animatorHud:toggle",
        data = state
    })
    if state then
        UpdateAnimatorHudNUI()
    end
end

_G.initAnimatorHud = function()
    if animHudInitialized then return end
    animHudInitialized = true
    TriggerServerEvent("vfw:animator:requestHudData")
    UpdateAnimatorHudNUI()
end

-- Reçoit les données du serveur (animateurs en ligne + reports)
RegisterNetEvent("vfw:animator:hudData", function(data)
    if data.onlineAnimators ~= nil then onlineAnimators = data.onlineAnimators end
    if data.animReports ~= nil then animReports = data.animReports end
    if data.animatorsInService ~= nil then animatorsInService = data.animatorsInService end
    if animatorHudVisible then
        UpdateAnimatorHudNUI()
    end
end)

-- Met à jour le compteur de reports en temps réel
RegisterNetEvent("vfw:animator:report", function()
    animReports = animReports + 1
    if animatorHudVisible then UpdateAnimatorHudNUI() end
end)

RegisterNetEvent("vfw:animator:deleteReport", function()
    animReports = math.max(0, animReports - 1)
    if animatorHudVisible then UpdateAnimatorHudNUI() end
end)

-- Mise à jour périodique du nombre d'animateurs (toutes les 30s)
CreateThread(function()
    while true do
        Wait(30000)
        if animatorHudVisible then
            TriggerServerEvent("vfw:animator:requestHudData")
        end
    end
end)
