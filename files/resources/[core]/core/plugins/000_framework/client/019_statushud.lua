---@meta _
---@diagnostic disable: duplicate-doc-field

local isStatusHUDVisible = false
local currentData = {
    playerInfo = {
        id = 0,
        firstName = "",
        lastName = "",
        age = 0
    },
    stats = {
        health = 100,
        armor = 0,
        hunger = 100,
        thirst = 100,
        stamina = 100
    },
    gameTime = {
        hours = 0,
        minutes = 0,
        day = 1,
        month = 1,
        year = 2024
    }
}

---@return table Minimap anchor data
local function getMinimapAnchor()
    if VFW.HudLayout and VFW.HudLayout.GetAnchor then
        return VFW.HudLayout.GetAnchor()
    end

    local safezone = GetSafeZoneSize()
    local res_x, res_y = GetActiveScreenResolution()
    local aspect_ratio = GetAspectRatio(0)

    local posX = -0.0045
    if tonumber(string.format("%.2f", aspect_ratio)) >= 2.3 then
        posX = -0.17
    end
    local posY = 0.012

    local mmWidth = 0.150
    local mmHeight = 0.188888

    local sz_offset = math.abs(safezone - 1.0) * 10
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0

    local Minimap = {}

    Minimap.width = mmWidth
    Minimap.height = mmHeight
    Minimap.left_x = (safezone_x * sz_offset) + posX
    Minimap.bottom_y = 1.0 - (safezone_y * sz_offset) - posY
    Minimap.right_x = Minimap.left_x + Minimap.width
    Minimap.top_y = Minimap.bottom_y - Minimap.height

    Minimap.width_px  = Minimap.width * res_x
    Minimap.height_px = Minimap.height * res_y
    Minimap.left_px   = Minimap.left_x * res_x
    Minimap.right_px  = Minimap.right_x * res_x
    Minimap.top_px    = Minimap.top_y * res_y
    Minimap.bottom_px = Minimap.bottom_y * res_y

    Minimap.res_x = res_x
    Minimap.res_y = res_y

    return Minimap
end

local function GetVuiPosition()
    local ok, pos = pcall(function()
        return exports["VUI"]:GetMenuPosition()
    end)
    return (ok and pos) or "left"
end

-- Forward VUI position to the HUD NUI (called on demand)
local function SendLogoPosition()
    SendNUIMessage({
        action = "nui:logo:position",
        data = { position = GetVuiPosition() }
    })
end

--- ShowStatusHUD
---@param show any
function ShowStatusHUD(show)
    isStatusHUDVisible = show

    if show then
        -- Send minimap position when showing HUD
        local minimapData = getMinimapAnchor()

        SendNUIMessage({
            action = 'nui:StatusHUD:position',
            data = minimapData
        })

        -- Sync VUI logo position
        SendLogoPosition()
    end

    SendNUIMessage({
        action = 'nui:StatusHUD:visible',
        data = show
    })
end

---Update StatusHUDData
---@param data table
function UpdateStatusHUDData(data)
    for k, v in pairs(data) do
        currentData[k] = v
    end

    SendNUIMessage({
        action = 'nui:StatusHUD:data',
        data = currentData
    })
end

RegisterNetEvent('statushud:updatePlayerInfo')
---@param playerInfo number|table Player ID or object
AddEventHandler('statushud:updatePlayerInfo', function(playerInfo)
    UpdateStatusHUDData({ playerInfo = playerInfo })

    ShowStatusHUD(true)
end)

RegisterNetEvent('statushud:updateStats')
---@param stats any
AddEventHandler('statushud:updateStats', function(stats)
    UpdateStatusHUDData({ stats = stats })
end)

RegisterNetEvent('statushud:updateTime')
---@param gameTime any
AddEventHandler('statushud:updateTime', function(gameTime)
    UpdateStatusHUDData({ gameTime = gameTime })
end)

RegisterNetEvent('vfw:updatePlayerData')
AddEventHandler('vfw:updatePlayerData', function(key, val)
    if key == "firstName" then
        currentData.playerInfo.firstName = val
        UpdateStatusHUDData({ playerInfo = currentData.playerInfo })
    elseif key == "lastName" then
        currentData.playerInfo.lastName = val
        UpdateStatusHUDData({ playerInfo = currentData.playerInfo })
    end
end)

RegisterNetEvent('statushud:show')
AddEventHandler('statushud:show', function()
    ShowStatusHUD(true)
end)

RegisterNetEvent('statushud:hide')
AddEventHandler('statushud:hide', function()
    ShowStatusHUD(false)
end)

-- React asks for logo position on mount
RegisterNUICallback("nui:logo:getPosition", function(_, cb)
    cb(GetVuiPosition())
end)

local hudTheme = GetResourceKvpString("hud_theme") or "neon"

RegisterNUICallback("nui:StatusHUD:getTheme", function(_, cb)
    cb(hudTheme)
end)

RegisterNetEvent("vfw:statusHUD:setTheme")
AddEventHandler("vfw:statusHUD:setTheme", function(theme)
    hudTheme = theme
    SetResourceKvp("hud_theme", theme)
    SendNUIMessage({
        action = "nui:StatusHUD:theme",
        data = theme
    })
end)

local hudHPStyle = GetResourceKvpString("hud_hp_style") or "default"

RegisterNUICallback("nui:StatusHUD:getHPStyle", function(_, cb)
    cb(hudHPStyle)
end)

RegisterNetEvent("vfw:statusHUD:setHPStyle")
AddEventHandler("vfw:statusHUD:setHPStyle", function(style)
    if style ~= "default" and style ~= "wide" then return end
    hudHPStyle = style
    SetResourceKvp("hud_hp_style", style)
    SendNUIMessage({
        action = "nui:StatusHUD:hpStyle",
        data = style
    })
end)

local DEFAULT_HUD_COLORS = {
    hunger = { r = 224, g = 184, b = 75 },
    thirst = { r = 90,  g = 167, b = 230 },
    oxygen = { r = 79,  g = 195, b = 247 },
}

local function rgbToHex(r, g, b)
    return string.format("#%02x%02x%02x", r, g, b)
end

local function loadHudColor(key)
    local stored = GetResourceKvpString("hud_color_" .. key)
    if stored then
        local r, g, b = stored:match("^(%d+),(%d+),(%d+)$")
        if r and g and b then
            return { r = tonumber(r), g = tonumber(g), b = tonumber(b) }
        end
    end
    return DEFAULT_HUD_COLORS[key]
end

local hudColors = {
    hunger = loadHudColor("hunger"),
    thirst = loadHudColor("thirst"),
    oxygen = loadHudColor("oxygen"),
}

local function buildHudColorsPayload()
    return {
        hunger = rgbToHex(hudColors.hunger.r, hudColors.hunger.g, hudColors.hunger.b),
        thirst = rgbToHex(hudColors.thirst.r, hudColors.thirst.g, hudColors.thirst.b),
        oxygen = rgbToHex(hudColors.oxygen.r, hudColors.oxygen.g, hudColors.oxygen.b),
    }
end

function GetHudColor(key)
    local c = hudColors[key]
    if c then return c.r, c.g, c.b end
end

RegisterNUICallback("nui:StatusHUD:getColors", function(_, cb)
    cb(buildHudColorsPayload())
end)

RegisterNetEvent("vfw:statusHUD:setColor")
AddEventHandler("vfw:statusHUD:setColor", function(key, r, g, b)
    if not hudColors[key] then return end
    hudColors[key] = { r = r, g = g, b = b }
    SetResourceKvp("hud_color_" .. key, ("%d,%d,%d"):format(r, g, b))
    SendNUIMessage({
        action = "nui:StatusHUD:colors",
        data = buildHudColorsPayload()
    })
end)

RegisterNetEvent("vfw:statusHUD:resetColors")
AddEventHandler("vfw:statusHUD:resetColors", function()
    for key, def in pairs(DEFAULT_HUD_COLORS) do
        hudColors[key] = { r = def.r, g = def.g, b = def.b }
        DeleteResourceKvp("hud_color_" .. key)
    end
    SendNUIMessage({
        action = "nui:StatusHUD:colors",
        data = buildHudColorsPayload()
    })
end)

-- Watch for VUI position changes (event + fallback poll)
local lastVuiPos = nil
local function applyLogoSide(pos)
    pos = pos or GetVuiPosition()
    if pos == lastVuiPos then return end
    lastVuiPos = pos
    SendNUIMessage({
        action = "nui:logo:position",
        data = { position = pos }
    })
end

AddEventHandler("vui:positionChanged", function(pos)
    applyLogoSide(pos)
end)

CreateThread(function()
    while true do
        Wait(1000)
        applyLogoSide(GetVuiPosition())
    end
end)

-- Thread to update minimap position when resolution changes
local lastResX, lastResY = 0, 0
CreateThread(function()
    while true do
        Wait(2000) -- Check every 2 seconds

        if isStatusHUDVisible then
            local res_x, res_y = GetActiveScreenResolution()
            if res_x ~= lastResX or res_y ~= lastResY then
                lastResX, lastResY = res_x, res_y
                local minimapData = getMinimapAnchor()
                SendNUIMessage({
                    action = 'nui:StatusHUD:position',
                    data = minimapData
                })
            end
        end
    end
end)

-- Thread rapide pour la vie/armure (sync avec le gamertag natif)
CreateThread(function()
    local lastHealth = -1
    local lastArmor = -1
    while true do
        Wait(100)
        if isStatusHUDVisible then
            local playerPed = PlayerPedId()
            local health = GetEntityHealth(playerPed)
            local armor = GetPedArmour(playerPed)
            if health ~= lastHealth or armor ~= lastArmor then
                lastHealth = health
                lastArmor = armor
                local healthPercent = math.max(0, math.min(100, ((health - 100) / 100) * 100))
                UpdateStatusHUDData({
                    stats = {
                        health = healthPercent,
                        armor = armor,
                        hunger = currentData.stats.hunger or 100,
                        thirst = currentData.stats.thirst or 100,
                        stamina = currentData.stats.stamina or 100
                    }
                })
            end
        end
    end
end)

-- Thread lent pour le reste (faim, soif, stamina, heure)
CreateThread(function()
    while true do
        Wait(1000)

        if not isStatusHUDVisible then
            goto continue
        end

        local playerPed = PlayerPedId()
        local health = GetEntityHealth(playerPed)
        local armor = GetPedArmour(playerPed)

        -- Recover the time of the game
        local hours = GetClockHours()
        local minutes = GetClockMinutes()
        local day = GetClockDayOfMonth()
        local month = GetClockMonth()
        local year = GetClockYear()

        -- Calculate health in percentage (100-200-> 0-100)
        local healthPercent = math.max(0, math.min(100, ((health - 100) / 100) * 100))
        local playerMeta = VFW.PlayerData.metadata

        -- Get hunger and thirst from VFW.PlayerData.metadata
        local hunger = playerMeta?.hunger or 100
        local thirst = playerMeta?.thirst or 100
        local stamina = GetPlayerStamina(PlayerId())

        UpdateStatusHUDData({
            stats = {
                health = healthPercent,
                armor = armor,
                hunger = hunger,
                thirst = thirst,
                stamina = stamina
            },
            gameTime = {
                hours = hours,
                minutes = minutes,
                day = day,
                month = month,
                year = year
            }
        })

        -- Update currentData for the damage thread
        currentData.stats.hunger = hunger
        currentData.stats.thirst = thirst
        currentData.stats.stamina = stamina

        :: continue ::
    end
end)

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerMeta = VFW.PlayerData?.metadata

        local hunger = playerMeta?.hunger or 100
        local thirst = playerMeta?.thirst or 100

        -- Check if player is in TIG (check if export exists first)
        local isInTIG = false
        if exports['core'] and exports['core'].IsPlayerInTIG then
            isInTIG = exports['core']:IsPlayerInTIG()
        end

        local isDead = (Death and Death.isDead) or (VFW.PlayerData and VFW.PlayerData.dead)

        if not isInTIG and not isDead and (hunger <= 0 or thirst <= 0) then
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
        else
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.0)
        end

        Wait(5000)
    end
end)

