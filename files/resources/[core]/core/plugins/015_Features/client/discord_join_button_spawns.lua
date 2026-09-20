--[[
    Discord Join Button - Points de spawn
    Utilise la même méthode que les cambriolages (direct NUI)
]]

local SpawnPoints = {
    { x = -248.50, y = -314.03, z = 21.66 },  -- Centre ville
    { x = -512.98, y = 6640.65, z = 4.64 }    -- Paleto , ,
}

local INTERACTION_RADIUS = 5.0
-- Fallback si BRANDING/panel indisponible. Le lien réel est lu dynamiquement
-- au clic (BRANDING.discord, alimenté par le panel EVE).
local DISCORD_URL = "https://discord.gg/eve-rp"

-- État de l'interaction
local floatingInteractionShown = false
local currentSpawnId = nil

local function ShowFloatingInteraction(spawnId, worldPos)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.3)

    if not onScreen then
        if floatingInteractionShown then
            SendNUIMessage({
                action = "floatingInteraction:hide"
            })
            floatingInteractionShown = false
            currentSpawnId = nil
        end
        return
    end

    local data = {
        id = "discord_spawn_" .. tostring(spawnId),
        title = "BIENVENUE EN VILLE",
        subtitle = "N'hésite pas à rejoindre notre communauté !",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Rejoindre le Discord", key = "E", icon = "discord" }
        }
    }

    if floatingInteractionShown and currentSpawnId == spawnId then
        SendNUIMessage({
            action = "floatingInteraction:update",
            data = data
        })
    else
        SendNUIMessage({
            action = "floatingInteraction:show",
            data = data
        })
        floatingInteractionShown = true
        currentSpawnId = spawnId
    end
end

local function HideFloatingInteraction()
    if floatingInteractionShown then
        SendNUIMessage({
            action = "floatingInteraction:hide"
        })
        floatingInteractionShown = false
        currentSpawnId = nil
    end
end

local function GetClosestSpawn()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closest = nil
    local closestDist = 999999.0

    for i, pos in ipairs(SpawnPoints) do
        local dist = #(playerCoords - vector3(pos.x, pos.y, pos.z))
        if dist < closestDist then
            closest = i
            closestDist = dist
        end
    end

    return closest, closestDist
end

CreateThread(function()
    while true do
        local wait = 1000
        local closestId, closestDist = GetClosestSpawn()

        if closestId and closestDist < INTERACTION_RADIUS then
            wait = 0
            local pos = SpawnPoints[closestId]
            ShowFloatingInteraction(closestId, vector3(pos.x, pos.y, pos.z + 0.3))

            -- Touche E pour ouvrir le Discord
            if VFW.Interact.JustPressed(0, 38) then
                HideFloatingInteraction()
                Web.OpenUrl((BRANDING and BRANDING.discord) or DISCORD_URL)
            end
        else
            HideFloatingInteraction()
        end

        Wait(wait)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        HideFloatingInteraction()
    end
end)
