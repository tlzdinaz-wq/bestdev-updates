---@meta _
---@diagnostic disable: duplicate-doc-field

-- Store death reasons for nearby dead players
local nearbyDeadPlayers = {}

-- Feature enabled state
local showDeathReasons = false

-- Configuration
local config = {
    renderDistance = 50.0, -- Maximum distance to render death reasons
    textFont = 4, -- Font ID
    textScale = 0.5, -- Text scale
    textOffset = 0.5, -- Height offset above the body (below nametag)
}

--- Draw a single line of 3D text at specific coordinates
---@param coords vector3 World coordinates
---@param text string Text to display (single line, no ~n~)
---@param scale number Computed scale factor
local function drawTextLine(coords, text, scale)
    SetTextScale(0.0, config.textScale * scale)
    SetTextFont(config.textFont)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

--- Draw 3D text at specific coordinates, splitting lines to avoid the 99 char limit
---@param coords vector3 World coordinates
---@param text string Text to display (may contain ~n~ for newlines)
local function draw3dText(coords, text)
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)

    local scale = 200 / (GetGameplayCamFov() * dist)
    local lineHeight = config.textScale * scale * 0.12

    -- Split by ~n~ and draw each line at a different height
    local lines = {}
    for line in string.gmatch(text .. "~n~", "(.-)" .. "~n~") do
        if line ~= "" then
            lines[#lines + 1] = line
        end
    end

    for i, line in ipairs(lines) do
        local offset = (i - 1) * -lineHeight
        drawTextLine(coords + vector3(0.0, 0.0, offset), line, scale)
    end
end

--- Main rendering thread
CreateThread(function()
    while true do
        local waitTime = 1000 -- Default wait time when feature is disabled

        if showDeathReasons then
            waitTime = 0 -- No wait when rendering
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)

            -- Iterate through all dead players we know about
            for playerServerId, deathData in pairs(nearbyDeadPlayers) do
                local player = GetPlayerFromServerId(playerServerId)

                if player ~= -1 then
                    local targetPed = GetPlayerPed(player)

                    -- Only check if ped is valid, always render if in table
                    -- Server events handle all cleanup (revive, respawn, etc.)
                    if targetPed and targetPed ~= 0 then
                        local pedCoords = GetEntityCoords(targetPed)
                        local dist = #(myCoords - pedCoords)

                        -- Only render if within distance
                        if dist < config.renderDistance then
                            -- Position text above the body
                            local textCoords = pedCoords + vector3(0.0, 0.0, config.textOffset)
                            draw3dText(textCoords, deathData.deathReason)
                        end
                    end
                else
                    -- Player not found (disconnected?), remove from list
                    nearbyDeadPlayers[playerServerId] = nil
                end
            end
        end

        Wait(waitTime)
    end
end)

--- Load saved preference from ResourceKVP
local function loadSavedPreference()
    local saved = GetResourceKvpString("staff_show_death_reasons")
    if saved == "true" then
        showDeathReasons = true
        -- Notify server that feature is enabled (this also sends existing death data)
        TriggerServerEvent("staff:toggleDeathReasons", true)
    else
        showDeathReasons = false
    end
end

--- Toggle the death reason display
---@param enabled boolean Whether to enable or disable
function ToggleDeathReasons(enabled)
    showDeathReasons = enabled

    if not enabled then
        -- Clear all death reasons when disabled
        nearbyDeadPlayers = {}
    else
        -- Request current death data from server
        TriggerServerEvent("staff:requestAllDeathData")
    end
end

-- Event: Update death reason for a player
RegisterNetEvent("staff:updateDeathReason", function(victimServerId, deathData)
    if not showDeathReasons then return end

    nearbyDeadPlayers[victimServerId] = {
        coords = deathData.coords,
        deathReason = deathData.deathReason,
        timestamp = deathData.timestamp
    }
end)

-- Event: Remove death reason for a player
RegisterNetEvent("staff:removeDeathReason", function(victimServerId)
    if nearbyDeadPlayers[victimServerId] then
        nearbyDeadPlayers[victimServerId] = nil
    end
end)

-- Event: Clear all death reasons
RegisterNetEvent("staff:clearAllDeathReasons", function()
    nearbyDeadPlayers = {}
end)

-- Load preference on resource start
CreateThread(function()
    Wait(2000) -- Wait for framework to initialize
    loadSavedPreference()
end)

-- Server cleared our feature state because we left staff mode.
-- Hide visuals locally but keep the KVP preference so re-entry can restore it.
RegisterNetEvent("staff:onStaffModeExit", function()
    showDeathReasons = false
    nearbyDeadPlayers = {}
end)

-- Re-apply saved preference whenever we (re)enter staff mode, so server-side
-- state (staffWithFeatureEnabled) gets re-armed after a staff off/on cycle.
local wasInStaffModeForDeathReasons = false
RegisterNetEvent("vfw:staff:syncStaffMode", function(staffModeList)
    local myId = GetPlayerServerId(PlayerId())
    local isInStaffMode = false
    for _, staffId in ipairs(staffModeList or {}) do
        if staffId == myId then
            isInStaffMode = true
            break
        end
    end

    if isInStaffMode and not wasInStaffModeForDeathReasons then
        if GetResourceKvpString("staff_show_death_reasons") == "true" then
            showDeathReasons = true
            TriggerServerEvent("staff:toggleDeathReasons", true)
        end
    end
    wasInStaffModeForDeathReasons = isInStaffMode
end)

-- Export the toggle function for menu access
exports('ToggleDeathReasons', ToggleDeathReasons)
exports('IsDeathReasonsEnabled', function() return showDeathReasons end)
