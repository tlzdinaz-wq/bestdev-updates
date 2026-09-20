-- ========================================================================
-- KOTH (King of the Hill) - Client
-- ========================================================================

local kothBlip = nil
local kothPulseBlip = nil
local kothRadiusBlip = nil
local kothZone = nil
local kothActive = false
local kothData = nil
local isInZone = false
local kothScoreboard = nil -- { scores = { {name, score}, ... }, endTime = epoch }
local kothScoreboardNuiVisible = false

local function SetBlipLabel(blip, name)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
end

-- ========================================================================
-- HELPERS
-- ========================================================================

local function IsFactionPlayer()
    return VFW.PlayerData and VFW.PlayerData.faction
        and VFW.PlayerData.faction.name
        and VFW.PlayerData.faction.name ~= ""
        and VFW.PlayerData.faction.name ~= "nofaction"
        and VFW.PlayerData.faction.name ~= "nocrew"
end

local function CleanupKoth()
    if kothBlip then
        RemoveBlip(kothBlip)
        kothBlip = nil
    end
    if kothPulseBlip then
        RemoveBlip(kothPulseBlip)
        kothPulseBlip = nil
    end
    if kothRadiusBlip then
        RemoveBlip(kothRadiusBlip)
        kothRadiusBlip = nil
    end
    if kothZone then
        kothZone:destroy()
        kothZone = nil
    end
    kothActive = false
    kothData = nil
    isInZone = false
    kothScoreboard = nil
    kothScoreboardNuiVisible = false
    SendNUIMessage({ action = "koth:scoreboard:hide" })
end

local function SetupKothVisuals(data)
    local coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    local cfg = KOTHConfig or {}
    local radius = tonumber(data.radius) or 50.0
    local label = "KOTH - " .. tostring(data.name or "zone")

    kothRadiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipHighDetail(kothRadiusBlip, true)
    SetBlipColour(kothRadiusBlip, cfg.blipColor or 46)
    SetBlipAlpha(kothRadiusBlip, 140)

    kothBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(kothBlip, cfg.blipSprite or 439)
    SetBlipDisplay(kothBlip, 4)
    SetBlipColour(kothBlip, cfg.blipColor or 46)
    SetBlipScale(kothBlip, cfg.blipScale or 1.2)
    SetBlipAsShortRange(kothBlip, false)
    SetBlipLabel(kothBlip, label)

    kothPulseBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(kothPulseBlip, 161)
    SetBlipDisplay(kothPulseBlip, 4)
    SetBlipColour(kothPulseBlip, cfg.blipColor or 46)
    SetBlipScale(kothPulseBlip, 2.0)
    SetBlipAsShortRange(kothPulseBlip, false)
    SetBlipLabel(kothPulseBlip, label)
    PulseBlip(kothPulseBlip)

    kothZone = CircleZone:Create(coords, radius, {
        name = "koth_zone",
        useZ = false,
    })

    kothZone:onPlayerInOut(function(inside)
        isInZone = inside
        -- Avertissement pour les joueurs non-faction qui entrent dans la zone
        if inside and not IsFactionPlayer() then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous êtes entré dans une zone de KOTH (activité illégale temporaire). Vous risquez d'être pris pour cible. A vos risques et périls.",
            })
        end
    end, 500)
end

-- ========================================================================
-- EVENTS
-- ========================================================================

RegisterNetEvent("koth:start")
AddEventHandler("koth:start", function(data)
    CleanupKoth()
    kothActive = true
    kothData = data
    SetupKothVisuals(data)
    VFW.ShowNotification({
        type = "ROUGE",
        content = "KOTH lancé : " .. tostring(data and data.name or "zone") .. ". La zone est marquée sur la carte.",
    })
end)

RegisterNetEvent("koth:end")
AddEventHandler("koth:end", function()
    CleanupKoth()
end)

RegisterNetEvent("koth:updateScoreboard")
AddEventHandler("koth:updateScoreboard", function(data)
    data.receivedAt = GetGameTimer()
    kothScoreboard = data
end)

-- ========================================================================
-- SCOREBOARD DRAWING HELPERS
-- ========================================================================

local function DrawText2D(text, x, y, scale, r, g, b, a, align, font, wrapRight)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 200)
    SetTextOutline()
    if align == "center" then
        SetTextCentre(true)
    elseif align == "right" and wrapRight then
        SetTextRightJustify(true)
        SetTextWrap(0.0, wrapRight)
    end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function FormatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return ("%02d:%02d"):format(m, s)
end

-- ========================================================================
-- ZONE MARKER + SCOREBOARD DRAW THREAD
-- ========================================================================

CreateThread(function()
    while true do
        if kothActive and kothData then
            local coords = vector3(kothData.coords.x, kothData.coords.y, kothData.coords.z)
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local dx = playerCoords.x - coords.x
            local dy = playerCoords.y - coords.y
            local dist2D = math.sqrt(dx * dx + dy * dy)
            local radius = tonumber(kothData.radius) or 50.0

            if dist2D < radius + 250.0 then
                local c = (KOTHConfig and KOTHConfig.zoneColor) or { r = 255, g = 0, b = 0, a = 80 }
                local diameter = radius * 2.0
                DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0,
                    diameter, diameter, diameter,
                    c.r, c.g, c.b, c.a, false, false, 2, false, nil, nil, false)
            end

            local isInZone2D = dist2D <= radius and IsFactionPlayer()
            if kothScoreboard and isInZone2D then
                if not kothScoreboardNuiVisible then
                    kothScoreboardNuiVisible = true
                end
                local serverRemaining = kothScoreboard.remainingSeconds or 0
                local receivedAt = kothScoreboard.receivedAt or GetGameTimer()
                local elapsed = (GetGameTimer() - receivedAt) / 1000
                local remaining = math.floor(serverRemaining - elapsed)
                if remaining < 0 then remaining = 0 end

                SendNUIMessage({
                    action = "koth:scoreboard:update",
                    data = {
                        scores = kothScoreboard.scores or {},
                        remainingSeconds = remaining,
                        zoneName = kothData.name or nil,
                    }
                })
            elseif kothScoreboardNuiVisible and not isInZone2D then
                kothScoreboardNuiVisible = false
                SendNUIMessage({ action = "koth:scoreboard:hide" })
            end

            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ========================================================================
-- REJOIN: Si le joueur se connecte pendant un KOTH actif
-- ========================================================================

CreateThread(function()
    -- Attendre que le joueur soit complètement chargé
    while not VFW.PlayerData do
        Wait(1000)
    end
    Wait(2000)

    local active = TriggerServerCallback("koth:getActive")
    if active then
        kothActive = true
        kothData = active
        SetupKothVisuals(active)
        if active.scoreboard then
            active.scoreboard.receivedAt = GetGameTimer()
            kothScoreboard = active.scoreboard
        end
    end
end)

-- Track death/alive state for KOTH scoring
AddEventHandler("vfw:onPlayerDeath", function()
    if kothActive then
        TriggerServerEvent("koth:playerDeath")
    end
end)

AddEventHandler("nui:deathscreen:hide", function()
    if kothActive then
        TriggerServerEvent("koth:playerAlive")
    end
end)

-- On faction change, refresh visuals
AddEventHandler("vfw:setFaction", function()
    if kothActive and kothData then
        -- Clean and re-setup (show/hide based on new job)
        if kothBlip then RemoveBlip(kothBlip) kothBlip = nil end
        if kothPulseBlip then RemoveBlip(kothPulseBlip) kothPulseBlip = nil end
        if kothRadiusBlip then RemoveBlip(kothRadiusBlip) kothRadiusBlip = nil end
        if kothZone then kothZone:destroy() kothZone = nil end
        SetupKothVisuals(kothData)
    end
end)
